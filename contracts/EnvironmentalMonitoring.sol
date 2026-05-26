// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IEnvironmentalMonitoring.sol";

/**
 * @title EnvironmentalMonitoring
 * @notice Gestiona estaciones de monitoreo ambiental y lecturas de sensores IoT simulados
 *         para el prototipo "Río Cali Transparente".
 * @dev Todos los valores de variables ambientales son enteros escalados ×100
 *      (ej: pH 7.25 → 725, O₂ 4.80 → 480).
 */
contract EnvironmentalMonitoring is AccessControl, IEnvironmentalMonitoring {

    // ─────────────────────────────────────────────────────────────────────────
    // Roles
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Rol de administrador — equivale a DEFAULT_ADMIN_ROLE de OpenZeppelin.
    bytes32 public constant ADMIN_ROLE = DEFAULT_ADMIN_ROLE;

    /// @notice Rol que autoriza el envío de lecturas de sensores.
    bytes32 public constant SENSOR_ORACLE_ROLE = keccak256("SENSOR_ORACLE_ROLE");

    // ─────────────────────────────────────────────────────────────────────────
    // Structs
    // ─────────────────────────────────────────────────────────────────────────

    struct Station {
        string  stationId;
        string  name;
        int256  latitude;   // escalado ×1e6, ej: 3.451 → 3451000
        int256  longitude;  // escalado ×1e6
        bool    active;
    }

    struct Thresholds {
        uint256 phMin;
        uint256 phMax;
        uint256 doMin;       // oxígeno disuelto mínimo
        uint256 doMax;       // oxígeno disuelto máximo
        uint256 tempMin;
        uint256 tempMax;
        uint256 conductMin;
        uint256 conductMax;
        uint256 turbidMin;
        uint256 turbidMax;
    }

    struct SensorReading {
        string  stationId;
        uint256 timestamp;
        uint256 ph;
        uint256 dissolvedOxygen;
        uint256 temperature;
        uint256 conductivity;
        uint256 turbidity;
        bytes32 evidenceHash;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // State
    // ─────────────────────────────────────────────────────────────────────────

    mapping(string => Station)          public stations;
    mapping(string => Thresholds)       public thresholds;
    mapping(string => SensorReading[])  public readings;
    mapping(string => bool)             public stationExists;

    /// @notice Mapea alertId → stationId para que contratos externos validen alertas.
    mapping(uint256 => string)          public alertStation;

    /// @notice Contador global de alertas emitidas (también es el próximo alertId).
    uint256 public alertCount;

    // ─────────────────────────────────────────────────────────────────────────
    // Events
    // ─────────────────────────────────────────────────────────────────────────

    event StationRegistered(
        string indexed stationId,
        string name,
        int256 latitude,
        int256 longitude
    );

    event ThresholdsUpdated(
        string indexed stationId,
        uint256 phMin,
        uint256 phMax,
        uint256 doMin,
        uint256 doMax,
        uint256 tempMin,
        uint256 tempMax,
        uint256 conductMin,
        uint256 conductMax,
        uint256 turbidMin,
        uint256 turbidMax
    );

    event ReadingRecorded(
        string  indexed stationId,
        uint256 indexed timestamp,
        uint256 ph,
        uint256 dissolvedOxygen,
        uint256 temperature,
        uint256 conductivity,
        uint256 turbidity
    );

    event AlertTriggered(
        string  indexed stationId,
        uint256 indexed alertId,
        string  variable,
        uint256 value,
        uint256 timestamp
    );

    // ─────────────────────────────────────────────────────────────────────────
    // Constructor
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Despliega el contrato y asigna DEFAULT_ADMIN_ROLE al deployer.
     */
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Admin functions
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Registra una nueva estación de monitoreo.
     * @param stationId  Identificador único de la estación (string).
     * @param name       Nombre descriptivo de la estación.
     * @param latitude   Latitud escalada ×1e6.
     * @param longitude  Longitud escalada ×1e6.
     */
    function registerStation(
        string calldata stationId,
        string calldata name,
        int256 latitude,
        int256 longitude
    ) external onlyRole(ADMIN_ROLE) {
        require(!stationExists[stationId], "EnvironmentalMonitoring: estacion ya existe");

        stations[stationId] = Station({
            stationId: stationId,
            name:      name,
            latitude:  latitude,
            longitude: longitude,
            active:    true
        });
        stationExists[stationId] = true;

        emit StationRegistered(stationId, name, latitude, longitude);
    }

    /**
     * @notice Configura los umbrales de alerta para cada variable ambiental de una estación.
     * @dev    Todos los valores son enteros escalados ×100. Requiere min < max para cada par.
     */
    function setThresholds(
        string calldata stationId,
        uint256 phMin,
        uint256 phMax,
        uint256 doMin,
        uint256 doMax,
        uint256 tempMin,
        uint256 tempMax,
        uint256 conductMin,
        uint256 conductMax,
        uint256 turbidMin,
        uint256 turbidMax
    ) external onlyRole(ADMIN_ROLE) {
        require(phMin      < phMax,      "EnvironmentalMonitoring: phMin debe ser menor que phMax");
        require(doMin      < doMax,      "EnvironmentalMonitoring: doMin debe ser menor que doMax");
        require(tempMin    < tempMax,    "EnvironmentalMonitoring: tempMin debe ser menor que tempMax");
        require(conductMin < conductMax, "EnvironmentalMonitoring: conductMin debe ser menor que conductMax");
        require(turbidMin  < turbidMax,  "EnvironmentalMonitoring: turbidMin debe ser menor que turbidMax");

        thresholds[stationId] = Thresholds({
            phMin:      phMin,
            phMax:      phMax,
            doMin:      doMin,
            doMax:      doMax,
            tempMin:    tempMin,
            tempMax:    tempMax,
            conductMin: conductMin,
            conductMax: conductMax,
            turbidMin:  turbidMin,
            turbidMax:  turbidMax
        });

        emit ThresholdsUpdated(
            stationId,
            phMin, phMax,
            doMin, doMax,
            tempMin, tempMax,
            conductMin, conductMax,
            turbidMin, turbidMax
        );
    }

    /**
     * @notice Otorga el rol SENSOR_ORACLE_ROLE a una dirección.
     * @param account Dirección que recibirá el rol.
     */
    function grantSensorOracle(address account) external onlyRole(ADMIN_ROLE) {
        grantRole(SENSOR_ORACLE_ROLE, account);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Oracle functions
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Registra una lectura de sensor para una estación existente.
     * @dev    Compara cada variable contra los umbrales configurados y emite
     *         AlertTriggered por cada variable que supere su rango.
     * @param stationId       Identificador de la estación.
     * @param timestamp       Timestamp Unix de la lectura.
     * @param ph              pH escalado ×100 (ej: 725 = 7.25).
     * @param dissolvedOxygen Oxígeno disuelto escalado ×100.
     * @param temperature     Temperatura escalada ×100.
     * @param conductivity    Conductividad escalada ×100.
     * @param turbidity       Turbidez escalada ×100.
     * @param evidenceHash    Hash de evidencia IPFS u otro sistema externo.
     */
    function recordReading(
        string  calldata stationId,
        uint256 timestamp,
        uint256 ph,
        uint256 dissolvedOxygen,
        uint256 temperature,
        uint256 conductivity,
        uint256 turbidity,
        bytes32 evidenceHash
    ) external onlyRole(SENSOR_ORACLE_ROLE) {
        require(stationExists[stationId], "EnvironmentalMonitoring: estacion no registrada");

        // Almacenar lectura
        readings[stationId].push(SensorReading({
            stationId:       stationId,
            timestamp:       timestamp,
            ph:              ph,
            dissolvedOxygen: dissolvedOxygen,
            temperature:     temperature,
            conductivity:    conductivity,
            turbidity:       turbidity,
            evidenceHash:    evidenceHash
        }));

        emit ReadingRecorded(stationId, timestamp, ph, dissolvedOxygen, temperature, conductivity, turbidity);

        // Comparar contra umbrales y emitir alertas
        Thresholds storage t = thresholds[stationId];

        if (ph < t.phMin || ph > t.phMax) {
            _triggerAlert(stationId, "ph", ph, timestamp);
        }
        if (dissolvedOxygen < t.doMin || dissolvedOxygen > t.doMax) {
            _triggerAlert(stationId, "dissolvedOxygen", dissolvedOxygen, timestamp);
        }
        if (temperature < t.tempMin || temperature > t.tempMax) {
            _triggerAlert(stationId, "temperature", temperature, timestamp);
        }
        if (conductivity < t.conductMin || conductivity > t.conductMax) {
            _triggerAlert(stationId, "conductivity", conductivity, timestamp);
        }
        if (turbidity < t.turbidMin || turbidity > t.turbidMax) {
            _triggerAlert(stationId, "turbidity", turbidity, timestamp);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // View functions
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @notice Retorna los datos de una estación dado su identificador.
     * @dev    Retorna campos individuales (no el struct) para compatibilidad con IEnvironmentalMonitoring.
     */
    function getStation(string calldata stationId)
        external
        view
        override
        returns (
            string memory stationId_,
            string memory name,
            int256  latitude,
            int256  longitude,
            bool    active
        )
    {
        Station storage s = stations[stationId];
        return (s.stationId, s.name, s.latitude, s.longitude, s.active);
    }

    /**
     * @notice Retorna los umbrales configurados para una estación.
     */
    function getThresholds(string calldata stationId)
        external
        view
        returns (Thresholds memory)
    {
        return thresholds[stationId];
    }

    /**
     * @notice Retorna el número de lecturas almacenadas para una estación.
     */
    function getReadingsCount(string calldata stationId)
        external
        view
        returns (uint256)
    {
        return readings[stationId].length;
    }

    /**
     * @notice Verifica si una alerta existe dado su ID.
     * @dev    Consumida por FinancialTraceability vía IEnvironmentalMonitoring.
     * @param alertId ID de la alerta a verificar.
     * @return true si la alerta existe (alertId < alertCount).
     */
    function isAlertValid(uint256 alertId)
        external
        view
        override
        returns (bool)
    {
        return alertId < alertCount;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Internal helpers
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * @dev Registra una alerta y emite el evento AlertTriggered.
     */
    function _triggerAlert(
        string memory stationId,
        string memory variable,
        uint256 value,
        uint256 timestamp
    ) internal {
        uint256 alertId = alertCount;
        alertStation[alertId] = stationId;
        alertCount++;

        emit AlertTriggered(stationId, alertId, variable, value, timestamp);
    }
}
