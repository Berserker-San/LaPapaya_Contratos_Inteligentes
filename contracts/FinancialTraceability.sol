// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IGovernanceDAO.sol";
import "./interfaces/IEnvironmentalMonitoring.sol";

/// @title FinancialTraceability
/// @notice Vault de trazabilidad financiera para el prototipo "Río Cali Transparente".
///         Gestiona fondos MockCOPToken y controla desembolsos condicionados a validación
///         ambiental (IEnvironmentalMonitoring) y aprobación de gobernanza (IGovernanceDAO).
/// @dev Hereda Ownable y ReentrancyGuard de OpenZeppelin v5.
///      Solo para uso en prototipo — NO representa fondos reales.
contract FinancialTraceability is Ownable, ReentrancyGuard {

    // ─────────────────────────────────────────────────────────────────────────
    // Constantes
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Presupuesto total del sistema en unidades de MockCOPToken.
    uint256 public constant TOTAL_BUDGET = 70_000_000;

    // ─────────────────────────────────────────────────────────────────────────
    // Enums
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Estado de una solicitud de desembolso.
    enum DisbursementStatus { Pending, Executed, Cancelled }

    // ─────────────────────────────────────────────────────────────────────────
    // Structs
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Rubro de gasto dentro del presupuesto.
    struct BudgetItem {
        uint256 id;
        string  name;
        string  description;
        uint256 allocatedAmount;
        uint256 spentAmount;
    }

    /// @notice Solicitud de desembolso de fondos del vault.
    struct DisbursementRequest {
        uint256            id;
        uint256            budgetItemId;
        uint256            amount;
        address            beneficiary;
        string             justification;
        uint256            alertId;     // ID de alerta ambiental validada
        uint256            proposalId;  // ID de propuesta DAO aprobada
        DisbursementStatus status;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Variables de estado
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Dirección del token MockCOPToken (IERC20).
    IERC20 private immutable token;

    /// @notice Dirección del contrato GovernanceDAO (vía interfaz).
    address private immutable governanceDAO;

    /// @notice Dirección del contrato EnvironmentalMonitoring (vía interfaz).
    address private immutable envMonitoring;

    /// @notice Contador de rubros creados (también sirve como próximo ID).
    uint256 public budgetItemCount;

    /// @notice Contador de solicitudes de desembolso (también sirve como próximo ID).
    uint256 public disbursementCount;

    /// @notice Rubros de gasto indexados por ID (1-based).
    mapping(uint256 => BudgetItem) public budgetItems;

    /// @notice Solicitudes de desembolso indexadas por ID (1-based).
    mapping(uint256 => DisbursementRequest) public disbursements;

    // ─────────────────────────────────────────────────────────────────────────
    // Eventos
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Emitido cuando se crea un nuevo rubro de gasto.
    event BudgetItemCreated(uint256 indexed itemId, string name, uint256 allocatedAmount);

    /// @notice Emitido cuando se depositan fondos en el vault.
    event FundsDeposited(address indexed depositor, uint256 amount, uint256 newVaultBalance);

    /// @notice Emitido cuando se registra una solicitud de desembolso.
    event DisbursementRequested(
        uint256 indexed disbursementId,
        uint256 indexed budgetItemId,
        address beneficiary,
        uint256 amount
    );

    /// @notice Emitido cuando se ejecuta exitosamente un desembolso.
    event DisbursementExecuted(
        uint256 indexed disbursementId,
        address indexed beneficiary,
        uint256 amount,
        uint256 alertId,
        uint256 proposalId
    );

    // ─────────────────────────────────────────────────────────────────────────
    // Constructor
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Despliega el vault con las referencias a los contratos dependientes.
    /// @param mockCOPToken Dirección del contrato MockCOPToken (ERC20).
    /// @param _governanceDAO Dirección del contrato GovernanceDAO.
    /// @param _environmentalMonitoring Dirección del contrato EnvironmentalMonitoring.
    constructor(
        address mockCOPToken,
        address _governanceDAO,
        address _environmentalMonitoring
    ) Ownable(msg.sender) {
        require(mockCOPToken != address(0),          "FinancialTraceability: token es direccion cero");
        require(_governanceDAO != address(0),        "FinancialTraceability: governanceDAO es direccion cero");
        require(_environmentalMonitoring != address(0), "FinancialTraceability: envMonitoring es direccion cero");

        token         = IERC20(mockCOPToken);
        governanceDAO = _governanceDAO;
        envMonitoring = _environmentalMonitoring;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Funciones de administración de rubros
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Crea un nuevo rubro de gasto en el presupuesto.
    /// @dev Solo el owner puede llamar esta función.
    /// @param name Nombre del rubro.
    /// @param description Descripción del rubro.
    /// @param allocatedAmount Monto asignado al rubro en unidades de MockCOPToken.
    function createBudgetItem(
        string calldata name,
        string calldata description,
        uint256 allocatedAmount
    ) external onlyOwner {
        require(bytes(name).length > 0,  "FinancialTraceability: nombre vacio");
        require(allocatedAmount > 0,     "FinancialTraceability: monto debe ser mayor a cero");

        budgetItemCount++;
        uint256 newId = budgetItemCount;

        budgetItems[newId] = BudgetItem({
            id:              newId,
            name:            name,
            description:     description,
            allocatedAmount: allocatedAmount,
            spentAmount:     0
        });

        emit BudgetItemCreated(newId, name, allocatedAmount);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Funciones de depósito
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Deposita tokens MockCOPToken en el vault.
    /// @dev El caller debe haber llamado `approve(address(this), amount)` en MockCOPToken
    ///      antes de invocar esta función. Protegida con nonReentrant.
    /// @param amount Cantidad de tokens a depositar.
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "FinancialTraceability: monto debe ser mayor a cero");

        require(
            token.transferFrom(msg.sender, address(this), amount),
            "FinancialTraceability: transferencia fallida"
        );

        uint256 newBalance = token.balanceOf(address(this));
        emit FundsDeposited(msg.sender, amount, newBalance);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Funciones de solicitud y ejecución de desembolsos
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Registra una solicitud de desembolso con estado Pendiente.
    /// @dev Solo el owner puede crear solicitudes.
    /// @param budgetItemId ID del rubro de gasto asociado.
    /// @param amount Monto a desembolsar en unidades de MockCOPToken.
    /// @param beneficiary Dirección receptora de los fondos.
    /// @param justification Justificación textual del desembolso.
    /// @param alertId ID de la alerta ambiental validada asociada.
    /// @param proposalId ID de la propuesta DAO aprobada asociada.
    function requestDisbursement(
        uint256 budgetItemId,
        uint256 amount,
        address beneficiary,
        string calldata justification,
        uint256 alertId,
        uint256 proposalId
    ) external onlyOwner {
        require(budgetItemId > 0 && budgetItemId <= budgetItemCount,
            "FinancialTraceability: rubro no existe");
        require(amount > 0,
            "FinancialTraceability: monto debe ser mayor a cero");
        require(beneficiary != address(0),
            "FinancialTraceability: beneficiario es direccion cero");
        require(bytes(justification).length > 0,
            "FinancialTraceability: justificacion vacia");

        disbursementCount++;
        uint256 newId = disbursementCount;

        disbursements[newId] = DisbursementRequest({
            id:            newId,
            budgetItemId:  budgetItemId,
            amount:        amount,
            beneficiary:   beneficiary,
            justification: justification,
            alertId:       alertId,
            proposalId:    proposalId,
            status:        DisbursementStatus.Pending
        });

        emit DisbursementRequested(newId, budgetItemId, beneficiary, amount);
    }

    /// @notice Ejecuta un desembolso pendiente si se cumplen ambas condiciones:
    ///         (A) la alerta ambiental es válida y (B) la propuesta DAO está aprobada.
    /// @dev Solo el owner puede ejecutar desembolsos. Protegida con nonReentrant.
    /// @param disbursementId ID de la solicitud de desembolso a ejecutar.
    function executeDisbursement(uint256 disbursementId) external onlyOwner nonReentrant {
        require(disbursementId > 0 && disbursementId <= disbursementCount,
            "FinancialTraceability: desembolso no existe");

        DisbursementRequest storage req = disbursements[disbursementId];

        require(req.status == DisbursementStatus.Pending,
            "FinancialTraceability: desembolso no esta pendiente");

        // Condición A: alerta ambiental válida
        require(
            IEnvironmentalMonitoring(envMonitoring).isAlertValid(req.alertId),
            "FinancialTraceability: alerta ambiental no valida"
        );

        // Condición B: propuesta DAO aprobada
        require(
            IGovernanceDAO(governanceDAO).isProposalApproved(req.proposalId),
            "FinancialTraceability: propuesta DAO no aprobada"
        );

        // Verificar saldo suficiente en el vault
        require(
            token.balanceOf(address(this)) >= req.amount,
            "FinancialTraceability: saldo insuficiente en vault"
        );

        // Actualizar estado antes de transferir (checks-effects-interactions)
        req.status = DisbursementStatus.Executed;
        budgetItems[req.budgetItemId].spentAmount += req.amount;

        // Transferir tokens al beneficiario
        require(
            token.transfer(req.beneficiary, req.amount),
            "FinancialTraceability: transferencia al beneficiario fallida"
        );

        emit DisbursementExecuted(
            disbursementId,
            req.beneficiary,
            req.amount,
            req.alertId,
            req.proposalId
        );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Funciones de consulta
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Retorna el saldo actual de MockCOPToken en el vault.
    /// @return Saldo del vault en unidades de MockCOPToken.
    function getVaultBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /// @notice Retorna los datos completos de una solicitud de desembolso.
    /// @param disbursementId ID de la solicitud a consultar.
    /// @return Struct DisbursementRequest con todos los campos de la solicitud.
    function getDisbursement(uint256 disbursementId)
        external
        view
        returns (DisbursementRequest memory)
    {
        require(disbursementId > 0 && disbursementId <= disbursementCount,
            "FinancialTraceability: desembolso no existe");
        return disbursements[disbursementId];
    }
}
