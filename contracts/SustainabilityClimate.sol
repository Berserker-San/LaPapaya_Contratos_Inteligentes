// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IEnvironmentalMonitoring.sol";

/**
 * @title SustainabilityClimate
 * @notice Conecta resultados ambientales con indicadores de sostenibilidad y emite
 *         claims climáticos verificables para el prototipo "Río Cali Transparente".
 *
 * @dev AVISO: Este contrato NO emite créditos de carbono reales ni afirma certificación
 *      VCS. El evento ClimateImpactClaimCreated es exclusivamente una simulación para
 *      demostrar la lógica de trazabilidad en Remix IDE con VM local.
 *
 * Hereda de Ownable (OpenZeppelin v5). Todas las funciones de escritura están
 * restringidas al owner (deployer).
 */
contract SustainabilityClimate is Ownable {
    // -------------------------------------------------------------------------
    // Estado
    // -------------------------------------------------------------------------

    /// @notice Dirección del contrato EnvironmentalMonitoring (vía interfaz).
    address private immutable envMonitoring;

    // -------------------------------------------------------------------------
    // Structs
    // -------------------------------------------------------------------------

    /**
     * @notice Registro ambiental que almacena la línea base y el resultado
     *         post-intervención para un par (stationId, variable).
     */
    struct EnvironmentalRecord {
        uint256 baselineValue; // Lectura_Escalada ×100 (ej: pH 7.25 → 725)
        uint256 outcomeValue;  // Lectura_Escalada ×100
        bool    hasBaseline;
        bool    hasOutcome;
    }

    // -------------------------------------------------------------------------
    // Mappings
    // -------------------------------------------------------------------------

    /**
     * @notice Almacena registros ambientales indexados por
     *         keccak256(abi.encodePacked(stationId, variable)).
     */
    mapping(bytes32 => EnvironmentalRecord) public records;

    // -------------------------------------------------------------------------
    // Eventos
    // -------------------------------------------------------------------------

    /**
     * @notice Emitido cuando se registra una línea base.
     * @dev Los parámetros string indexed se almacenan como keccak256 del string,
     *      lo que permite filtrado eficiente en el log de Remix IDE.
     */
    event BaselineRegistered(
        string indexed stationId,
        string indexed variable,
        uint256 baselineValue
    );

    /**
     * @notice Emitido cuando se registra un resultado post-intervención.
     */
    event OutcomeRegistered(
        string indexed stationId,
        string indexed variable,
        uint256 outcomeValue
    );

    /**
     * @notice Emitido cuando se crea un claim climático con el porcentaje de mejora.
     * @dev improvementPct puede ser negativo si el outcome es peor que el baseline.
     */
    event ClimateImpactClaimCreated(
        string indexed stationId,
        string indexed variable,
        uint256 baselineValue,
        uint256 outcomeValue,
        int256  improvementPct
    );

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    /**
     * @param environmentalMonitoring Dirección del contrato EnvironmentalMonitoring.
     *        No puede ser address(0).
     */
    constructor(address environmentalMonitoring) Ownable(msg.sender) {
        require(
            environmentalMonitoring != address(0),
            "SustainabilityClimate: direccion de monitoreo invalida"
        );
        envMonitoring = environmentalMonitoring;
    }

    // -------------------------------------------------------------------------
    // Funciones internas de utilidad
    // -------------------------------------------------------------------------

    /**
     * @dev Calcula la clave del mapping para un par (stationId, variable).
     */
    function _recordKey(
        string calldata stationId,
        string calldata variable
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(stationId, variable));
    }

    // -------------------------------------------------------------------------
    // Funciones públicas de escritura
    // -------------------------------------------------------------------------

    /**
     * @notice Registra la línea base ambiental para una estación y variable.
     * @param stationId Identificador de la estación de monitoreo.
     * @param variable  Nombre de la variable ambiental (ej: "dissolvedOxygen").
     * @param value     Valor escalado ×100 (ej: pH 7.25 → 725).
     */
    function registerBaseline(
        string calldata stationId,
        string calldata variable,
        uint256 value
    ) external onlyOwner {
        bytes32 key = _recordKey(stationId, variable);
        records[key].baselineValue = value;
        records[key].hasBaseline   = true;

        emit BaselineRegistered(stationId, variable, value);
    }

    /**
     * @notice Registra el resultado post-intervención para una estación y variable.
     * @param stationId Identificador de la estación de monitoreo.
     * @param variable  Nombre de la variable ambiental.
     * @param value     Valor escalado ×100.
     */
    function registerOutcome(
        string calldata stationId,
        string calldata variable,
        uint256 value
    ) external onlyOwner {
        bytes32 key = _recordKey(stationId, variable);
        records[key].outcomeValue = value;
        records[key].hasOutcome   = true;

        emit OutcomeRegistered(stationId, variable, value);
    }

    /**
     * @notice Calcula el porcentaje de mejora y emite un claim climático.
     * @dev Requiere que tanto la línea base como el outcome estén registrados y
     *      que el baseline sea mayor que cero.
     *
     *      Fórmula: improvement = ((outcome - baseline) * 100) / baseline
     *      Un valor positivo indica mejora; negativo indica degradación.
     *
     * @param stationId Identificador de la estación de monitoreo.
     * @param variable  Nombre de la variable ambiental.
     */
    function emitClimateImpactClaim(
        string calldata stationId,
        string calldata variable
    ) external onlyOwner {
        bytes32 key = _recordKey(stationId, variable);
        EnvironmentalRecord storage record = records[key];

        require(
            record.hasBaseline,
            "SustainabilityClimate: linea base no registrada"
        );
        require(
            record.hasOutcome,
            "SustainabilityClimate: resultado post-intervencion no registrado"
        );
        require(
            record.baselineValue > 0,
            "SustainabilityClimate: baseline no puede ser cero"
        );

        int256 improvement = (
            (int256(record.outcomeValue) - int256(record.baselineValue)) * 100
        ) / int256(record.baselineValue);

        emit ClimateImpactClaimCreated(
            stationId,
            variable,
            record.baselineValue,
            record.outcomeValue,
            improvement
        );
    }

    // -------------------------------------------------------------------------
    // Funciones públicas de consulta
    // -------------------------------------------------------------------------

    /**
     * @notice Retorna la línea base, el outcome y el porcentaje de mejora calculado
     *         para una estación y variable dados.
     *
     * Casos de retorno:
     *  - Sin baseline ni outcome → (0, 0, 0)
     *  - Solo baseline           → (baselineValue, 0, 0)
     *  - Ambos y baseline > 0    → (baselineValue, outcomeValue, improvementPct)
     *  - Ambos y baseline == 0   → (0, outcomeValue, 0)
     *
     * @param stationId Identificador de la estación de monitoreo.
     * @param variable  Nombre de la variable ambiental.
     * @return baseline       Valor de línea base escalado ×100.
     * @return outcome        Valor de resultado post-intervención escalado ×100.
     * @return improvementPct Porcentaje de mejora (puede ser negativo).
     */
    function getRecord(
        string calldata stationId,
        string calldata variable
    ) external view returns (uint256 baseline, uint256 outcome, int256 improvementPct) {
        bytes32 key = _recordKey(stationId, variable);
        EnvironmentalRecord storage record = records[key];

        // Sin datos registrados
        if (!record.hasBaseline && !record.hasOutcome) {
            return (0, 0, 0);
        }

        // Solo baseline, sin outcome
        if (record.hasBaseline && !record.hasOutcome) {
            return (record.baselineValue, 0, 0);
        }

        // Ambos registrados
        if (record.hasBaseline && record.hasOutcome) {
            if (record.baselineValue == 0) {
                // Baseline cero: no se puede calcular porcentaje
                return (0, record.outcomeValue, 0);
            }
            int256 pct = (
                (int256(record.outcomeValue) - int256(record.baselineValue)) * 100
            ) / int256(record.baselineValue);
            return (record.baselineValue, record.outcomeValue, pct);
        }

        // Solo outcome sin baseline (caso inusual pero posible)
        return (0, record.outcomeValue, 0);
    }
}
