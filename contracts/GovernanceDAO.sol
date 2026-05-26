// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IGovernanceDAO.sol";

/**
 * @title GovernanceDAO
 * @notice Contrato de gobernanza participativa para el prototipo "Río Cali Transparente".
 *         Gestiona actores (Autoridad, Comunidad, Academia, Sector Privado), propuestas
 *         y votaciones mediante roles de AccessControl de OpenZeppelin v5.
 * @dev Implementa IGovernanceDAO para interoperabilidad con FinancialTraceability.
 */
contract GovernanceDAO is AccessControl, IGovernanceDAO {

    // ─────────────────────────────────────────────────────────────────────────
    // Roles (Task 4.2)
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Rol de administrador — equivale a DEFAULT_ADMIN_ROLE de AccessControl.
    bytes32 public constant ADMIN_ROLE = DEFAULT_ADMIN_ROLE;

    /// @notice Rol para actores de tipo Autoridad (entidades reguladoras ambientales).
    bytes32 public constant AUTORIDAD_ROLE = keccak256("AUTORIDAD_ROLE");

    /// @notice Rol para actores de tipo Comunidad (organizaciones comunitarias locales).
    bytes32 public constant COMUNIDAD_ROLE = keccak256("COMUNIDAD_ROLE");

    /// @notice Rol para actores de tipo Academia (instituciones académicas o científicas).
    bytes32 public constant ACADEMIA_ROLE = keccak256("ACADEMIA_ROLE");

    /// @notice Rol para actores de tipo Sector Privado (empresas o entidades privadas).
    bytes32 public constant SECTOR_PRIVADO_ROLE = keccak256("SECTOR_PRIVADO_ROLE");

    // ─────────────────────────────────────────────────────────────────────────
    // Enums (Task 4.3)
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Tipos de actor de gobernanza.
    enum ActorType {
        Autoridad,      // 0
        Comunidad,      // 1
        Academia,       // 2
        SectorPrivado   // 3
    }

    /// @notice Tipos de propuesta soportados por el DAO.
    enum ProposalType {
        IncidentValidation,         // 0 — Validación técnica de incidente
        DisbursementAuthorization,  // 1 — Autorización de desembolso
        ProjectPrioritization,      // 2 — Priorización de proyectos
        StrategicDecision           // 3 — Decisión estratégica
    }

    /// @notice Estados posibles de una propuesta.
    enum ProposalStatus {
        Active,     // 0 — En período de votación
        Approved,   // 1 — Aprobada (votesFor > votesAgainst al finalizar)
        Rejected    // 2 — Rechazada
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Structs (Task 4.4)
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Representa una propuesta de gobernanza.
    struct Proposal {
        uint256        id;
        ProposalType   proposalType;
        string         description;
        address        proposer;
        uint256        votingDeadline;   // block.timestamp + votingDuration
        uint256        votesFor;
        uint256        votesAgainst;
        ProposalStatus status;
        bool           finalized;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // State variables / Mappings
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Almacena todas las propuestas indexadas por su ID.
    mapping(uint256 => Proposal) public proposals;

    /// @notice Registra si un actor ya votó en una propuesta específica.
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    /// @notice Indica si una dirección está registrada como actor de gobernanza.
    mapping(address => bool) public isRegisteredActor;

    /// @notice Contador de propuestas creadas (también sirve como próximo ID).
    uint256 public proposalCount;

    // ─────────────────────────────────────────────────────────────────────────
    // Eventos (Requirement 9.1, 9.2, 9.3)
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Emitido cuando el Admin registra un nuevo actor de gobernanza.
    event ActorRegistered(address indexed actor, ActorType actorType);

    /// @notice Emitido cuando un actor registrado crea una nueva propuesta.
    event ProposalCreated(
        uint256 indexed proposalId,
        ProposalType    proposalType,
        address indexed proposer,
        uint256         votingDeadline
    );

    /// @notice Emitido cuando un actor registrado emite su voto.
    event VoteCast(
        uint256 indexed proposalId,
        address indexed voter,
        bool            inFavor
    );

    /// @notice Emitido cuando una propuesta es finalizada con su resultado.
    event ProposalFinalized(
        uint256 indexed proposalId,
        ProposalStatus  result,
        uint256         votesFor,
        uint256         votesAgainst
    );

    // ─────────────────────────────────────────────────────────────────────────
    // Constructor
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Despliega el contrato y asigna el rol de Admin al deployer.
     * @dev Requirement 1.4: GovernanceDAO se despliega con el deployer como Admin
     *      y sin propuestas activas.
     */
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Task 4.5 — registerActor
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Registra una dirección como actor de gobernanza y le asigna el rol
     *         correspondiente según su tipo.
     * @dev Solo el Admin puede llamar esta función (Requirement 5.1, 5.2, 10.1).
     * @param actor    Dirección del actor a registrar.
     * @param actorType Tipo de actor (Autoridad, Comunidad, Academia, SectorPrivado).
     */
    function registerActor(address actor, ActorType actorType)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(actor != address(0), "GovernanceDAO: actor es address(0)");

        // Asignar el rol bytes32 correspondiente al tipo de actor
        if (actorType == ActorType.Autoridad) {
            _grantRole(AUTORIDAD_ROLE, actor);
        } else if (actorType == ActorType.Comunidad) {
            _grantRole(COMUNIDAD_ROLE, actor);
        } else if (actorType == ActorType.Academia) {
            _grantRole(ACADEMIA_ROLE, actor);
        } else {
            // ActorType.SectorPrivado
            _grantRole(SECTOR_PRIVADO_ROLE, actor);
        }

        isRegisteredActor[actor] = true;

        emit ActorRegistered(actor, actorType);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Task 4.6 — createProposal
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Crea una nueva propuesta de gobernanza.
     * @dev Solo actores registrados pueden crear propuestas (Requirement 5.3, 5.4).
     * @param proposalType   Tipo de propuesta.
     * @param description    Descripción textual de la propuesta.
     * @param votingDuration Duración del período de votación en segundos.
     * @return proposalId    Identificador único de la propuesta creada.
     */
    function createProposal(
        ProposalType proposalType,
        string calldata description,
        uint256 votingDuration
    )
        external
        returns (uint256 proposalId)
    {
        require(
            isRegisteredActor[msg.sender],
            "GovernanceDAO: solo actores registrados pueden crear propuestas"
        );
        require(votingDuration > 0, "GovernanceDAO: duracion de votacion debe ser mayor a 0");
        require(bytes(description).length > 0, "GovernanceDAO: descripcion no puede estar vacia");

        proposalCount++;
        proposalId = proposalCount;

        uint256 deadline = block.timestamp + votingDuration;

        proposals[proposalId] = Proposal({
            id:             proposalId,
            proposalType:   proposalType,
            description:    description,
            proposer:       msg.sender,
            votingDeadline: deadline,
            votesFor:       0,
            votesAgainst:   0,
            status:         ProposalStatus.Active,
            finalized:      false
        });

        emit ProposalCreated(proposalId, proposalType, msg.sender, deadline);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Task 4.7 — castVote
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Emite un voto en una propuesta activa.
     * @dev Requirement 5.5, 5.6: cada actor registrado puede votar exactamente una vez
     *      mientras la propuesta esté activa y dentro del período de votación.
     * @param proposalId ID de la propuesta a votar.
     * @param inFavor    true = voto a favor, false = voto en contra.
     */
    function castVote(uint256 proposalId, bool inFavor) external {
        require(
            isRegisteredActor[msg.sender],
            "GovernanceDAO: solo actores registrados pueden votar"
        );
        require(
            proposalId > 0 && proposalId <= proposalCount,
            "GovernanceDAO: propuesta no existe"
        );

        Proposal storage proposal = proposals[proposalId];

        require(
            proposal.status == ProposalStatus.Active,
            "GovernanceDAO: la propuesta no esta activa"
        );
        require(
            block.timestamp <= proposal.votingDeadline,
            "GovernanceDAO: el periodo de votacion ha expirado"
        );
        require(
            !hasVoted[proposalId][msg.sender],
            "GovernanceDAO: el actor ya voto en esta propuesta"
        );

        hasVoted[proposalId][msg.sender] = true;

        if (inFavor) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit VoteCast(proposalId, msg.sender, inFavor);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Task 4.8 — finalizeProposal
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Finaliza una propuesta cuyo período de votación ha expirado.
     * @dev Cualquier dirección puede llamar esta función (Requirement 5.7, 5.8).
     *      Resultado: Approved si votesFor > votesAgainst, Rejected en caso contrario.
     * @param proposalId ID de la propuesta a finalizar.
     */
    function finalizeProposal(uint256 proposalId) external {
        require(
            proposalId > 0 && proposalId <= proposalCount,
            "GovernanceDAO: propuesta no existe"
        );

        Proposal storage proposal = proposals[proposalId];

        require(
            !proposal.finalized,
            "GovernanceDAO: la propuesta ya fue finalizada"
        );
        require(
            block.timestamp > proposal.votingDeadline,
            "GovernanceDAO: el periodo de votacion aun no ha expirado"
        );

        // Mayoría simple: más votos a favor que en contra → Aprobada
        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.status = ProposalStatus.Approved;
        } else {
            proposal.status = ProposalStatus.Rejected;
        }

        proposal.finalized = true;

        emit ProposalFinalized(
            proposalId,
            proposal.status,
            proposal.votesFor,
            proposal.votesAgainst
        );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Task 4.9 — isProposalApproved (IGovernanceDAO)
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Indica si una propuesta fue aprobada y finalizada.
     * @dev Consumida por FinancialTraceability a través de IGovernanceDAO
     *      (Requirement 5.9, 8.2, 8.3).
     * @param proposalId ID de la propuesta a consultar.
     * @return true si la propuesta está finalizada y con estado Approved.
     */
    function isProposalApproved(uint256 proposalId)
        external
        view
        override
        returns (bool)
    {
        return
            proposals[proposalId].status == ProposalStatus.Approved &&
            proposals[proposalId].finalized;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Task 4.10 — getProposal (IGovernanceDAO)
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Retorna todos los datos de una propuesta dado su ID.
     * @dev Retorna proposalType y status como uint8 para compatibilidad con
     *      IGovernanceDAO (Requirement 5.9, 8.2).
     * @param proposalId ID de la propuesta a consultar.
     * @return id            Identificador de la propuesta.
     * @return proposalType  Tipo de propuesta como uint8.
     * @return description   Descripción textual.
     * @return proposer      Dirección del creador.
     * @return votingDeadline Timestamp de fin del período de votación.
     * @return votesFor      Número de votos a favor.
     * @return votesAgainst  Número de votos en contra.
     * @return status        Estado de la propuesta como uint8.
     * @return finalized     true si la propuesta ya fue finalizada.
     */
    function getProposal(uint256 proposalId)
        external
        view
        override
        returns (
            uint256 id,
            uint8   proposalType,
            string memory description,
            address proposer,
            uint256 votingDeadline,
            uint256 votesFor,
            uint256 votesAgainst,
            uint8   status,
            bool    finalized
        )
    {
        Proposal storage p = proposals[proposalId];
        return (
            p.id,
            uint8(p.proposalType),
            p.description,
            p.proposer,
            p.votingDeadline,
            p.votesFor,
            p.votesAgainst,
            uint8(p.status),
            p.finalized
        );
    }
}
