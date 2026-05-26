# Design Document — Río Cali Transparente

## Overview

Prototipo funcional de gobernanza ambiental basada en blockchain para el Río Cali. El sistema se compone de 5 contratos Solidity (`^0.8.24`) + 2 interfaces, desplegables en Remix IDE con VM local. No utiliza datos reales, oráculos externos ni fondos reales.

---

## 1. Arquitectura del sistema

```
┌─────────────────────────────────────────────────────────────────┐
│                        REMIX IDE (VM local)                     │
│                                                                 │
│  ┌──────────────────┐        ┌──────────────────────────────┐  │
│  │  MockCOPToken    │◄───────│     FinancialTraceability    │  │
│  │  (ERC20+Ownable) │        │  (Ownable+ReentrancyGuard)   │  │
│  └──────────────────┘        │  usa IGovernanceDAO          │  │
│                               └──────────┬───────────────────┘  │
│                                          │ IGovernanceDAO        │
│  ┌──────────────────────────────────┐    │                       │
│  │         GovernanceDAO            │◄───┘                       │
│  │         (AccessControl)          │                            │
│  └──────────────────────────────────┘                            │
│                                                                  │
│  ┌──────────────────────────────────┐                            │
│  │     EnvironmentalMonitoring      │◄──── IEnvironmentalMonit. │
│  │         (AccessControl)          │                            │
│  └──────────────────────────────────┘                            │
│           ▲                                                      │
│           │ IEnvironmentalMonitoring                             │
│  ┌────────┴─────────────────────────┐                            │
│  │       SustainabilityClimate      │                            │
│  │           (Ownable)              │                            │
│  └──────────────────────────────────┘                            │
└─────────────────────────────────────────────────────────────────┘
```

### Orden de despliegue

1. `MockCOPToken` — sin dependencias
2. `GovernanceDAO` — sin dependencias
3. `EnvironmentalMonitoring` — sin dependencias
4. `FinancialTraceability(mockCOPToken, governanceDAO)`
5. `SustainabilityClimate(environmentalMonitoring)`

---

## 2. Decisiones de diseño clave

| Decisión | Justificación |
|---|---|
| Enteros escalados ×100 | Solidity no tiene decimales nativos. pH 7.25 → `725`, O₂ 4.80 → `480`. |
| Roles como `bytes32` constantes | Patrón estándar de OpenZeppelin AccessControl. Permite `hasRole()` eficiente. |
| `ReentrancyGuard` en FinancialTraceability | Protege transferencias ERC20 de ataques de reentrada. |
| Interfaces `IEnvironmentalMonitoring` / `IGovernanceDAO` | Desacopla contratos consumidores de implementaciones concretas. |
| IDs numéricos auto-incrementales | `uint256` simple para propuestas, solicitudes de desembolso y alertas. Evita colisiones. |
| Doble condición de desembolso | Garantiza que ningún fondo se libere sin validación ambiental + aprobación DAO. |
| `block.timestamp` para períodos de votación | Suficiente para prototipo en VM local. No apto para producción. |

---

## 3. Diseño de contratos

### 3.1 MockCOPToken

**Herencia:** `ERC20`, `Ownable`

**Propósito:** Token ERC20 que simula pesos colombianos ficticios (mCOP).

```solidity
// Constantes
string public constant NAME    = "Colombian Peso Mock";
string public constant SYMBOL  = "mCOP";

// Constructor
constructor(uint256 initialSupply)
    ERC20(NAME, SYMBOL)
    Ownable(msg.sender)
// Mintea initialSupply al deployer

// Funciones
function mint(address to, uint256 amount) external onlyOwner
// Acuña tokens. Emite Transfer(address(0), to, amount) vía ERC20.
```

**Eventos heredados de ERC20:** `Transfer`, `Approval`

---

### 3.2 EnvironmentalMonitoring

**Herencia:** `AccessControl`

**Roles:**
```solidity
bytes32 public constant ADMIN_ROLE         = DEFAULT_ADMIN_ROLE;
bytes32 public constant SENSOR_ORACLE_ROLE = keccak256("SENSOR_ORACLE_ROLE");
```

**Structs:**
```solidity
struct Station {
    string  stationId;
    string  name;
    int256  latitude;   // escalado ×1e6, ej: 3.451 → 3451000
    int256  longitude;  // escalado ×1e6
    bool    active;
}

struct Thresholds {
    uint256 phMin;          uint256 phMax;
    uint256 doMin;          uint256 doMax;   // oxígeno disuelto
    uint256 tempMin;        uint256 tempMax;
    uint256 conductMin;     uint256 conductMax;
    uint256 turbidMin;      uint256 turbidMax;
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
```

**Mappings:**
```solidity
mapping(string => Station)       public stations;
mapping(string => Thresholds)    public thresholds;
mapping(string => SensorReading[]) public readings;
mapping(string => bool)          public stationExists;
// alertId → stationId (para que FinancialTraceability valide alertas)
mapping(uint256 => string)       public alertStation;
uint256 public alertCount;
```

**Eventos:**
```solidity
event StationRegistered(indexed string stationId, string name, int256 latitude, int256 longitude);
event ThresholdsUpdated(indexed string stationId, uint256 phMin, uint256 phMax, uint256 doMin, uint256 doMax, uint256 tempMin, uint256 tempMax, uint256 conductMin, uint256 conductMax, uint256 turbidMin, uint256 turbidMax);
event ReadingRecorded(indexed string stationId, uint256 indexed timestamp, uint256 ph, uint256 dissolvedOxygen, uint256 temperature, uint256 conductivity, uint256 turbidity);
event AlertTriggered(indexed string stationId, indexed uint256 alertId, string variable, uint256 value, uint256 timestamp);
```

**Funciones públicas:**
```solidity
function registerStation(string calldata stationId, string calldata name, int256 latitude, int256 longitude) external onlyRole(ADMIN_ROLE)
function setThresholds(string calldata stationId, uint256 phMin, uint256 phMax, uint256 doMin, uint256 doMax, uint256 tempMin, uint256 tempMax, uint256 conductMin, uint256 conductMax, uint256 turbidMin, uint256 turbidMax) external onlyRole(ADMIN_ROLE)
function recordReading(string calldata stationId, uint256 timestamp, uint256 ph, uint256 dissolvedOxygen, uint256 temperature, uint256 conductivity, uint256 turbidity, bytes32 evidenceHash) external onlyRole(SENSOR_ORACLE_ROLE)
function getStation(string calldata stationId) external view returns (Station memory)
function getThresholds(string calldata stationId) external view returns (Thresholds memory)
function getReadingsCount(string calldata stationId) external view returns (uint256)
function isAlertValid(uint256 alertId) external view returns (bool)   // consumida por FinancialTraceability vía interfaz
function grantSensorOracle(address account) external onlyRole(ADMIN_ROLE)
```

---

### 3.3 GovernanceDAO

**Herencia:** `AccessControl`

**Roles:**
```solidity
bytes32 public constant ADMIN_ROLE        = DEFAULT_ADMIN_ROLE;
bytes32 public constant AUTORIDAD_ROLE    = keccak256("AUTORIDAD_ROLE");
bytes32 public constant COMUNIDAD_ROLE    = keccak256("COMUNIDAD_ROLE");
bytes32 public constant ACADEMIA_ROLE     = keccak256("ACADEMIA_ROLE");
bytes32 public constant SECTOR_PRIVADO_ROLE = keccak256("SECTOR_PRIVADO_ROLE");
```

**Enums:**
```solidity
enum ActorType    { Autoridad, Comunidad, Academia, SectorPrivado }
enum ProposalType { IncidentValidation, DisbursementAuthorization, ProjectPrioritization, StrategicDecision }
enum ProposalStatus { Active, Approved, Rejected }
```

**Structs:**
```solidity
struct Proposal {
    uint256        id;
    ProposalType   proposalType;
    string         description;
    address        proposer;
    uint256        votingDeadline;   // block.timestamp + duration
    uint256        votesFor;
    uint256        votesAgainst;
    ProposalStatus status;
    bool           finalized;
}
```

**Mappings:**
```solidity
mapping(uint256 => Proposal)              public proposals;
mapping(uint256 => mapping(address => bool)) public hasVoted;
mapping(address => bool)                  public isRegisteredActor;
uint256 public proposalCount;
```

**Eventos:**
```solidity
event ActorRegistered(indexed address actor, ActorType actorType);
event ProposalCreated(indexed uint256 proposalId, ProposalType proposalType, indexed address proposer, uint256 votingDeadline);
event VoteCast(indexed uint256 proposalId, indexed address voter, bool inFavor);
event ProposalFinalized(indexed uint256 proposalId, ProposalStatus result, uint256 votesFor, uint256 votesAgainst);
```

**Funciones públicas:**
```solidity
function registerActor(address actor, ActorType actorType) external onlyRole(ADMIN_ROLE)
function createProposal(ProposalType proposalType, string calldata description, uint256 votingDuration) external returns (uint256 proposalId)
function castVote(uint256 proposalId, bool inFavor) external
function finalizeProposal(uint256 proposalId) external
function getProposal(uint256 proposalId) external view returns (Proposal memory)
function isProposalApproved(uint256 proposalId) external view returns (bool)  // consumida por FinancialTraceability vía interfaz
```

---

### 3.4 FinancialTraceability

**Herencia:** `Ownable`, `ReentrancyGuard`

**Dependencias:** `IGovernanceDAO`, `IERC20` (MockCOPToken)

**Enums:**
```solidity
enum DisbursementStatus { Pending, Executed, Cancelled }
```

**Structs:**
```solidity
struct BudgetItem {
    uint256 id;
    string  name;
    string  description;
    uint256 allocatedAmount;
    uint256 spentAmount;
}

struct DisbursementRequest {
    uint256           id;
    uint256           budgetItemId;
    uint256           amount;
    address           beneficiary;
    string            justification;
    uint256           alertId;       // ID de alerta ambiental validada
    uint256           proposalId;    // ID de propuesta DAO aprobada
    DisbursementStatus status;
}
```

**Mappings:**
```solidity
mapping(uint256 => BudgetItem)          public budgetItems;
mapping(uint256 => DisbursementRequest) public disbursements;
uint256 public budgetItemCount;
uint256 public disbursementCount;
uint256 public constant TOTAL_BUDGET = 70_000_000;
```

**Eventos:**
```solidity
event BudgetItemCreated(indexed uint256 itemId, string name, uint256 allocatedAmount);
event FundsDeposited(indexed address depositor, uint256 amount, uint256 newVaultBalance);
event DisbursementRequested(indexed uint256 disbursementId, indexed uint256 budgetItemId, address beneficiary, uint256 amount);
event DisbursementExecuted(indexed uint256 disbursementId, indexed address beneficiary, uint256 amount, uint256 alertId, uint256 proposalId);
```

**Funciones públicas:**
```solidity
function createBudgetItem(string calldata name, string calldata description, uint256 allocatedAmount) external onlyOwner
function deposit(uint256 amount) external nonReentrant
function requestDisbursement(uint256 budgetItemId, uint256 amount, address beneficiary, string calldata justification, uint256 alertId, uint256 proposalId) external onlyOwner
function executeDisbursement(uint256 disbursementId) external onlyOwner nonReentrant
function getVaultBalance() external view returns (uint256)
function getDisbursement(uint256 disbursementId) external view returns (DisbursementRequest memory)
```

**Lógica de doble condición en `executeDisbursement`:**
```
require(IEnvironmentalMonitoring(envMonitoring).isAlertValid(req.alertId), "Alerta ambiental no valida");
require(IGovernanceDAO(governanceDAO).isProposalApproved(req.proposalId), "Propuesta DAO no aprobada");
require(token.balanceOf(address(this)) >= req.amount, "Saldo insuficiente");
token.transfer(req.beneficiary, req.amount);
```

> Nota: `FinancialTraceability` también necesita la dirección de `EnvironmentalMonitoring` para validar alertas. Se pasa como parámetro adicional del constructor o mediante función `setEnvironmentalMonitoring(address)`.

---

### 3.5 SustainabilityClimate

**Herencia:** `Ownable`

**Dependencias:** `IEnvironmentalMonitoring`

**Structs:**
```solidity
struct EnvironmentalRecord {
    uint256 baselineValue;   // Lectura_Escalada ×100
    uint256 outcomeValue;    // Lectura_Escalada ×100
    bool    hasBaseline;
    bool    hasOutcome;
}
```

**Mappings:**
```solidity
// key: keccak256(abi.encodePacked(stationId, variable))
mapping(bytes32 => EnvironmentalRecord) public records;
```

**Eventos:**
```solidity
event BaselineRegistered(indexed string stationId, indexed string variable, uint256 baselineValue);
event OutcomeRegistered(indexed string stationId, indexed string variable, uint256 outcomeValue);
event ClimateImpactClaimCreated(indexed string stationId, indexed string variable, uint256 baselineValue, uint256 outcomeValue, int256 improvementPct);
```

**Funciones públicas:**
```solidity
function registerBaseline(string calldata stationId, string calldata variable, uint256 value) external onlyOwner
function registerOutcome(string calldata stationId, string calldata variable, uint256 value) external onlyOwner
function emitClimateImpactClaim(string calldata stationId, string calldata variable) external onlyOwner
function getRecord(string calldata stationId, string calldata variable) external view returns (uint256 baseline, uint256 outcome, int256 improvementPct)
```

**Cálculo de mejora:**
```solidity
// Aritmética entera con signo para capturar degradación
int256 improvement = ((int256(outcome) - int256(baseline)) * 100) / int256(baseline);
```

---

## 4. Interfaces

### 4.1 IGovernanceDAO

Consumida por `FinancialTraceability`.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IGovernanceDAO {
    function isProposalApproved(uint256 proposalId) external view returns (bool);
    function getProposal(uint256 proposalId) external view returns (
        uint256 id,
        uint8   proposalType,
        string memory description,
        address proposer,
        uint256 votingDeadline,
        uint256 votesFor,
        uint256 votesAgainst,
        uint8   status,
        bool    finalized
    );
}
```

### 4.2 IEnvironmentalMonitoring

Consumida por `SustainabilityClimate` y `FinancialTraceability`.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IEnvironmentalMonitoring {
    function isAlertValid(uint256 alertId) external view returns (bool);
    function getStation(string calldata stationId) external view returns (
        string memory stationId_,
        string memory name,
        int256  latitude,
        int256  longitude,
        bool    active
    );
}
```

---

## 5. Flujo de datos completo

```
[Admin]
  │
  ├─1─► registerStation("la-isla", ...) → EnvironmentalMonitoring
  │       └─ emit StationRegistered
  │
  ├─2─► setThresholds("la-isla", ...) → EnvironmentalMonitoring
  │       └─ emit ThresholdsUpdated
  │
[SensorOracle]
  │
  ├─3─► recordReading("la-isla", ts, ph=725, do=480, ...) → EnvironmentalMonitoring
  │       ├─ emit ReadingRecorded
  │       └─ do=480 < doMin=500 → emit AlertTriggered(alertId=1)
  │
[Actor DAO]
  │
  ├─4─► createProposal(DisbursementAuthorization, "Mitigación La Isla", 3600) → GovernanceDAO
  │       └─ emit ProposalCreated(proposalId=1)
  │
  ├─5─► castVote(1, true) × N actores → GovernanceDAO
  │       └─ emit VoteCast × N
  │
  ├─6─► finalizeProposal(1) → GovernanceDAO
  │       └─ emit ProposalFinalized(1, Approved, votesFor, votesAgainst)
  │
[Admin]
  │
  ├─7─► deposit(70_000_000) → FinancialTraceability
  │       └─ emit FundsDeposited
  │
  ├─8─► requestDisbursement(budgetItemId=1, amount, beneficiary, justif, alertId=1, proposalId=1)
  │       └─ emit DisbursementRequested(disbursementId=1)
  │
  ├─9─► executeDisbursement(1) → FinancialTraceability
  │       ├─ isAlertValid(1) ✓ via IEnvironmentalMonitoring
  │       ├─ isProposalApproved(1) ✓ via IGovernanceDAO
  │       ├─ token.transfer(beneficiary, amount)
  │       └─ emit DisbursementExecuted
  │
  ├─10─► registerBaseline("la-isla", "dissolvedOxygen", 480) → SustainabilityClimate
  │        └─ emit BaselineRegistered
  │
  ├─11─► registerOutcome("la-isla", "dissolvedOxygen", 620) → SustainabilityClimate
  │        └─ emit OutcomeRegistered
  │
  └─12─► emitClimateImpactClaim("la-isla", "dissolvedOxygen") → SustainabilityClimate
           ├─ improvement = ((620-480)*100)/480 = 29%
           └─ emit ClimateImpactClaimCreated("la-isla", "dissolvedOxygen", 480, 620, 29)
```

---

## 6. Estructura de archivos

```
contracts/
├── interfaces/
│   ├── IEnvironmentalMonitoring.sol
│   └── IGovernanceDAO.sol
├── MockCOPToken.sol
├── EnvironmentalMonitoring.sol
├── GovernanceDAO.sol
├── FinancialTraceability.sol
└── SustainabilityClimate.sol
README.md
```

---

## 7. Dependencias OpenZeppelin

Todos los contratos importan desde `@openzeppelin/contracts` vía npm o la URL de Remix:

```
https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.0/contracts/
```

| Contrato | OZ imports |
|---|---|
| MockCOPToken | `token/ERC20/ERC20.sol`, `access/Ownable.sol` |
| EnvironmentalMonitoring | `access/AccessControl.sol` |
| GovernanceDAO | `access/AccessControl.sol` |
| FinancialTraceability | `access/Ownable.sol`, `utils/ReentrancyGuard.sol`, `token/ERC20/IERC20.sol` |
| SustainabilityClimate | `access/Ownable.sol` |
