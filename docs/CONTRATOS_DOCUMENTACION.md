# Documentación Técnica de Contratos — Río Cali Transparente

**Versión:** 1.0  
**Solidity:** `^0.8.24`  
**Framework:** OpenZeppelin Contracts v5  
**Entorno:** Remix IDE con VM local

---

## Índice

1. [Arquitectura general](#1-arquitectura-general)
2. [MockCOPToken](#2-mockcoptoken)
3. [EnvironmentalMonitoring](#3-environmentalmonitoring)
4. [GovernanceDAO](#4-governancedao)
5. [FinancialTraceability](#5-financialtraceability)
6. [SustainabilityClimate](#6-sustainabilityclimate)
7. [Interfaces](#7-interfaces)
8. [Flujo completo del sistema](#8-flujo-completo-del-sistema)
9. [Convención de escalado de valores](#9-convención-de-escalado-de-valores)
10. [Errores comunes y sus causas](#10-errores-comunes-y-sus-causas)

---

## 1. Arquitectura general

El sistema está compuesto por **5 contratos** y **2 interfaces**. Cada contrato tiene una responsabilidad única y se comunican entre sí a través de las interfaces.

```
MockCOPToken  ←──────────────────────────────────────────┐
     ↑                                                    │ transfiere tokens
     │ aprueba gasto (approve)                            │
     │                                                FinancialTraceability
GovernanceDAO ──── isProposalApproved() ───────────────→ │
                                                          │
EnvironmentalMonitoring ── isAlertValid() ─────────────→ │
     ↑
     │ lee datos
SustainabilityClimate
```

**Dependencias en el constructor de `FinancialTraceability`:**
- Necesita la dirección de `MockCOPToken`
- Necesita la dirección de `GovernanceDAO`
- Necesita la dirección de `EnvironmentalMonitoring`

**Dependencia en el constructor de `SustainabilityClimate`:**
- Necesita la dirección de `EnvironmentalMonitoring`

**Orden de despliegue obligatorio:**
1. `MockCOPToken`
2. `GovernanceDAO`
3. `EnvironmentalMonitoring`
4. `FinancialTraceability` (requiere las 3 anteriores)
5. `SustainabilityClimate` (requiere `EnvironmentalMonitoring`)

---

## 2. MockCOPToken

**Archivo:** `contracts/MockCOPToken.sol`  
**Hereda de:** `ERC20`, `Ownable` (OpenZeppelin v5)  
**Propósito:** Token ERC20 ficticio que simula pesos colombianos (mCOP). Es la moneda del sistema. No representa dinero real.

### Variables de estado heredadas (ERC20)

| Variable | Tipo | Descripción |
|---|---|---|
| `name` | `string` | `"Colombian Peso Mock"` |
| `symbol` | `string` | `"mCOP"` |
| `decimals` | `uint8` | `18` (por defecto ERC20) |
| `totalSupply` | `uint256` | Total de tokens en circulación |
| `balanceOf[addr]` | `mapping` | Saldo de cada dirección |
| `allowance[owner][spender]` | `mapping` | Cuánto puede gastar `spender` en nombre de `owner` |

### Constructor

```solidity
constructor(uint256 initialSupply)
```

| Parámetro | Descripción |
|---|---|
| `initialSupply` | Cantidad de mCOP acuñados al deployer al momento del despliegue. Usar `70000000`. |

### Funciones

#### `mint(address to, uint256 amount)`
- **Acceso:** Solo `owner`
- **Qué hace:** Crea nuevos tokens y los envía a `to`.
- **Validaciones:** `to != address(0)`, `amount > 0`
- **Evento emitido:** `Transfer(address(0), to, amount)` (heredado de ERC20)

#### `approve(address spender, uint256 amount)` *(heredada de ERC20)*
- **Acceso:** Cualquier holder
- **Qué hace:** Autoriza a `spender` a gastar hasta `amount` tokens del caller.
- **Uso en el sistema:** El owner debe llamar `approve(FinancialTraceability_address, amount)` antes de llamar `deposit()`.
- **Evento emitido:** `Approval(owner, spender, amount)`

#### `transfer` / `transferFrom` *(heredadas de ERC20)*
- Usadas internamente por `FinancialTraceability` para mover fondos.

### Eventos

| Evento | Cuándo se emite |
|---|---|
| `Transfer(address from, address to, uint256 value)` | En cada mint o transferencia |
| `Approval(address owner, address spender, uint256 value)` | En cada `approve` |

---

## 3. EnvironmentalMonitoring

**Archivo:** `contracts/EnvironmentalMonitoring.sol`  
**Hereda de:** `AccessControl` (OpenZeppelin v5), `IEnvironmentalMonitoring`  
**Propósito:** Registra estaciones de monitoreo del Río Cali, almacena lecturas de sensores IoT simulados, compara valores contra umbrales y dispara alertas automáticas cuando una variable sale de rango.

### Roles

| Constante | Valor | Quién lo tiene | Qué puede hacer |
|---|---|---|---|
| `ADMIN_ROLE` | `DEFAULT_ADMIN_ROLE` (bytes32 cero) | Deployer | Registrar estaciones, configurar umbrales, otorgar roles |
| `SENSOR_ORACLE_ROLE` | `keccak256("SENSOR_ORACLE_ROLE")` | Cuentas autorizadas por admin | Enviar lecturas de sensores |

### Structs

#### `Station`
Representa una estación física de monitoreo.

| Campo | Tipo | Descripción |
|---|---|---|
| `stationId` | `string` | Identificador único (ej: `"la-isla"`) |
| `name` | `string` | Nombre descriptivo (ej: `"La Isla"`) |
| `latitude` | `int256` | Latitud escalada ×1e6 (ej: 3.451° → `3451000`) |
| `longitude` | `int256` | Longitud escalada ×1e6 (ej: -76.52° → `-76520000`) |
| `active` | `bool` | `true` si la estación está operativa |

#### `Thresholds`
Define los rangos normales para cada variable ambiental de una estación. Todos los valores están escalados ×100.

| Campo | Tipo | Ejemplo | Equivale a |
|---|---|---|---|
| `phMin` | `uint256` | `650` | pH 6.50 |
| `phMax` | `uint256` | `850` | pH 8.50 |
| `doMin` | `uint256` | `500` | O₂ 5.00 mg/L |
| `doMax` | `uint256` | `1200` | O₂ 12.00 mg/L |
| `tempMin` | `uint256` | `1500` | 15.00 °C |
| `tempMax` | `uint256` | `3000` | 30.00 °C |
| `conductMin` | `uint256` | `10000` | 100.00 µS/cm |
| `conductMax` | `uint256` | `100000` | 1000.00 µS/cm |
| `turbidMin` | `uint256` | `0` | 0 NTU |
| `turbidMax` | `uint256` | `10000` | 100.00 NTU |

#### `SensorReading`
Una lectura completa de sensor almacenada en el historial.

| Campo | Tipo | Descripción |
|---|---|---|
| `stationId` | `string` | ID de la estación |
| `timestamp` | `uint256` | Timestamp Unix de la lectura |
| `ph` | `uint256` | pH ×100 |
| `dissolvedOxygen` | `uint256` | Oxígeno disuelto ×100 |
| `temperature` | `uint256` | Temperatura ×100 |
| `conductivity` | `uint256` | Conductividad ×100 |
| `turbidity` | `uint256` | Turbidez ×100 |
| `evidenceHash` | `bytes32` | Hash de evidencia (IPFS u otro sistema externo) |

### Variables de estado

| Variable | Tipo | Descripción |
|---|---|---|
| `stations` | `mapping(string => Station)` | Estaciones indexadas por `stationId` |
| `thresholds` | `mapping(string => Thresholds)` | Umbrales por estación |
| `readings` | `mapping(string => SensorReading[])` | Historial de lecturas por estación |
| `stationExists` | `mapping(string => bool)` | Evita registrar la misma estación dos veces |
| `alertStation` | `mapping(uint256 => string)` | Mapea `alertId` → `stationId` |
| `alertCount` | `uint256` | Contador global de alertas (también es el próximo `alertId`) |

### Funciones de administración

#### `registerStation(stationId, name, latitude, longitude)`
- **Acceso:** `ADMIN_ROLE`
- **Qué hace:** Registra una nueva estación. La marca como `active = true`.
- **Validación:** La estación no debe existir previamente.
- **Evento:** `StationRegistered`

#### `setThresholds(stationId, phMin, phMax, doMin, doMax, tempMin, tempMax, conductMin, conductMax, turbidMin, turbidMax)`
- **Acceso:** `ADMIN_ROLE`
- **Qué hace:** Configura los 10 umbrales de alerta para una estación.
- **Validaciones:** Para cada par, `min < max`.
- **Evento:** `ThresholdsUpdated`

#### `grantSensorOracle(address account)`
- **Acceso:** `ADMIN_ROLE`
- **Qué hace:** Otorga `SENSOR_ORACLE_ROLE` a una dirección para que pueda enviar lecturas.

### Funciones de oráculo

#### `recordReading(stationId, timestamp, ph, dissolvedOxygen, temperature, conductivity, turbidity, evidenceHash)`
- **Acceso:** `SENSOR_ORACLE_ROLE`
- **Qué hace:**
  1. Almacena la lectura en `readings[stationId]`.
  2. Emite `ReadingRecorded`.
  3. Compara cada variable contra sus umbrales.
  4. Por cada variable fuera de rango, llama a `_triggerAlert()` internamente.
- **Validación:** La estación debe existir.
- **Eventos:** `ReadingRecorded` + `AlertTriggered` (uno por cada variable fuera de rango)

### Funciones de consulta

| Función | Retorna | Descripción |
|---|---|---|
| `getStation(stationId)` | 5 campos del struct | Datos de la estación |
| `getThresholds(stationId)` | `Thresholds` struct | Umbrales configurados |
| `getReadingsCount(stationId)` | `uint256` | Número de lecturas almacenadas |
| `isAlertValid(alertId)` | `bool` | `true` si `alertId < alertCount`. Consumida por `FinancialTraceability`. |

### Eventos

| Evento | Parámetros clave | Cuándo |
|---|---|---|
| `StationRegistered` | `stationId`, `name`, `latitude`, `longitude` | Al registrar estación |
| `ThresholdsUpdated` | `stationId` + 10 valores | Al configurar umbrales |
| `ReadingRecorded` | `stationId`, `timestamp`, 5 variables | Al registrar lectura |
| `AlertTriggered` | `stationId`, `alertId`, `variable`, `value`, `timestamp` | Por cada variable fuera de rango |

### Lógica interna de alertas

```
recordReading() recibe lectura
        ↓
Almacena SensorReading en readings[stationId]
        ↓
Emite ReadingRecorded
        ↓
Compara ph contra [phMin, phMax]  → fuera de rango → _triggerAlert("ph", ...)
Compara dissolvedOxygen contra [doMin, doMax]      → _triggerAlert("dissolvedOxygen", ...)
Compara temperature contra [tempMin, tempMax]      → _triggerAlert("temperature", ...)
Compara conductivity contra [conductMin, conductMax] → _triggerAlert("conductivity", ...)
Compara turbidity contra [turbidMin, turbidMax]    → _triggerAlert("turbidity", ...)

_triggerAlert():
  alertId = alertCount (actual)
  alertStation[alertId] = stationId
  alertCount++
  emit AlertTriggered(...)
```

Una sola lectura puede generar **hasta 5 alertas** (una por variable). Cada alerta tiene un `alertId` único e incremental.

---

## 4. GovernanceDAO

**Archivo:** `contracts/GovernanceDAO.sol`  
**Hereda de:** `AccessControl` (OpenZeppelin v5), `IGovernanceDAO`  
**Propósito:** Sistema de gobernanza participativa. Gestiona actores de distintos sectores, permite crear propuestas y votar. Las propuestas aprobadas habilitan desembolsos en `FinancialTraceability`.

### Roles

| Constante | Valor | Descripción |
|---|---|---|
| `ADMIN_ROLE` | `DEFAULT_ADMIN_ROLE` | Administrador. Registra actores. |
| `AUTORIDAD_ROLE` | `keccak256("AUTORIDAD_ROLE")` | Entidades reguladoras ambientales (CVC, Alcaldía) |
| `COMUNIDAD_ROLE` | `keccak256("COMUNIDAD_ROLE")` | Organizaciones comunitarias (barrio La Isla) |
| `ACADEMIA_ROLE` | `keccak256("ACADEMIA_ROLE")` | Instituciones académicas (Icesi, Maestría) |
| `SECTOR_PRIVADO_ROLE` | `keccak256("SECTOR_PRIVADO_ROLE")` | Empresas privadas |

### Enums

#### `ActorType`
Usado al registrar un actor para asignarle el rol correcto.

| Valor | Número | Rol asignado |
|---|---|---|
| `Autoridad` | `0` | `AUTORIDAD_ROLE` |
| `Comunidad` | `1` | `COMUNIDAD_ROLE` |
| `Academia` | `2` | `ACADEMIA_ROLE` |
| `SectorPrivado` | `3` | `SECTOR_PRIVADO_ROLE` |

#### `ProposalType`
Categoriza el propósito de una propuesta.

| Valor | Número | Descripción |
|---|---|---|
| `IncidentValidation` | `0` | Validación técnica de un incidente ambiental |
| `DisbursementAuthorization` | `1` | Autorización de desembolso de fondos |
| `ProjectPrioritization` | `2` | Priorización de proyectos |
| `StrategicDecision` | `3` | Decisión estratégica general |

#### `ProposalStatus`
Estado actual de una propuesta.

| Valor | Número | Descripción |
|---|---|---|
| `Active` | `0` | En período de votación |
| `Approved` | `1` | Aprobada (más votos a favor que en contra) |
| `Rejected` | `2` | Rechazada |

### Struct `Proposal`

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | `uint256` | Identificador único (1-based) |
| `proposalType` | `ProposalType` | Tipo de propuesta |
| `description` | `string` | Texto descriptivo |
| `proposer` | `address` | Quien creó la propuesta |
| `votingDeadline` | `uint256` | `block.timestamp + votingDuration` al momento de creación |
| `votesFor` | `uint256` | Contador de votos a favor |
| `votesAgainst` | `uint256` | Contador de votos en contra |
| `status` | `ProposalStatus` | Estado actual |
| `finalized` | `bool` | `true` después de llamar `finalizeProposal()` |

### Variables de estado

| Variable | Tipo | Descripción |
|---|---|---|
| `proposals` | `mapping(uint256 => Proposal)` | Propuestas indexadas por ID |
| `hasVoted` | `mapping(uint256 => mapping(address => bool))` | Evita votar dos veces en la misma propuesta |
| `isRegisteredActor` | `mapping(address => bool)` | Indica si una dirección puede crear propuestas y votar |
| `proposalCount` | `uint256` | Contador de propuestas (también es el próximo ID) |

### Funciones

#### `registerActor(address actor, ActorType actorType)`
- **Acceso:** `ADMIN_ROLE`
- **Qué hace:** Registra una dirección como actor de gobernanza y le asigna el rol correspondiente. Activa `isRegisteredActor[actor] = true`.
- **Validación:** `actor != address(0)`
- **Evento:** `ActorRegistered(actor, actorType)`

#### `createProposal(ProposalType proposalType, string description, uint256 votingDuration)`
- **Acceso:** Cualquier `isRegisteredActor`
- **Qué hace:** Crea una propuesta con estado `Active`. El deadline es `block.timestamp + votingDuration`.
- **Validaciones:** `votingDuration > 0`, `description` no vacía.
- **Retorna:** `proposalId` (uint256)
- **Evento:** `ProposalCreated(proposalId, proposalType, proposer, votingDeadline)`

#### `castVote(uint256 proposalId, bool inFavor)`
- **Acceso:** Cualquier `isRegisteredActor`
- **Qué hace:** Registra un voto. Cada actor puede votar exactamente una vez por propuesta.
- **Validaciones:** Propuesta existe, está `Active`, no ha expirado el deadline, el actor no ha votado antes.
- **Evento:** `VoteCast(proposalId, voter, inFavor)`

#### `finalizeProposal(uint256 proposalId)`
- **Acceso:** Cualquier dirección (función pública)
- **Qué hace:** Cierra la votación y determina el resultado. `Approved` si `votesFor > votesAgainst`, `Rejected` en caso contrario.
- **Validaciones:** Propuesta no finalizada, `block.timestamp > votingDeadline`.
- **Evento:** `ProposalFinalized(proposalId, result, votesFor, votesAgainst)`

#### `isProposalApproved(uint256 proposalId)` *(IGovernanceDAO)*
- **Acceso:** Lectura pública. Consumida por `FinancialTraceability`.
- **Retorna:** `true` solo si `status == Approved && finalized == true`.

#### `getProposal(uint256 proposalId)` *(IGovernanceDAO)*
- **Retorna:** Todos los campos del struct `Proposal`. `proposalType` y `status` se devuelven como `uint8`.

### Eventos

| Evento | Cuándo |
|---|---|
| `ActorRegistered(actor, actorType)` | Al registrar un actor |
| `ProposalCreated(proposalId, proposalType, proposer, votingDeadline)` | Al crear propuesta |
| `VoteCast(proposalId, voter, inFavor)` | Al votar |
| `ProposalFinalized(proposalId, result, votesFor, votesAgainst)` | Al finalizar propuesta |

### Flujo de una propuesta

```
registerActor() × N actores
        ↓
createProposal() → status: Active, finalized: false
        ↓
castVote() × cada actor (dentro del deadline)
        ↓
[esperar que expire votingDeadline]
        ↓
finalizeProposal()
  → votesFor > votesAgainst → status: Approved, finalized: true
  → votesFor ≤ votesAgainst → status: Rejected, finalized: true
        ↓
isProposalApproved() → true (si Approved)
  → habilita executeDisbursement() en FinancialTraceability
```

---

## 5. FinancialTraceability

**Archivo:** `contracts/FinancialTraceability.sol`  
**Hereda de:** `Ownable`, `ReentrancyGuard` (OpenZeppelin v5)  
**Propósito:** Vault (caja fuerte) que custodia los tokens mCOP del proyecto. Controla los desembolsos con una doble condición: debe existir una alerta ambiental válida **y** una propuesta DAO aprobada. Ningún fondo sale sin ambas condiciones cumplidas.

### Constantes

| Constante | Valor | Descripción |
|---|---|---|
| `TOTAL_BUDGET` | `70_000_000` | Presupuesto total del sistema en unidades mCOP |

### Enum `DisbursementStatus`

| Valor | Número | Descripción |
|---|---|---|
| `Pending` | `0` | Solicitud creada, aún no ejecutada |
| `Executed` | `1` | Fondos transferidos al beneficiario |
| `Cancelled` | `2` | Cancelada (no implementado en funciones actuales) |

### Structs

#### `BudgetItem` — Rubro de gasto

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | `uint256` | Identificador (1-based) |
| `name` | `string` | Nombre del rubro (ej: `"Monitoreo"`) |
| `description` | `string` | Descripción del rubro |
| `allocatedAmount` | `uint256` | Monto asignado en mCOP |
| `spentAmount` | `uint256` | Monto ya desembolsado. Se incrementa al ejecutar desembolsos. |

#### `DisbursementRequest` — Solicitud de desembolso

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | `uint256` | Identificador (1-based) |
| `budgetItemId` | `uint256` | Rubro al que se carga el gasto |
| `amount` | `uint256` | Monto a transferir en mCOP |
| `beneficiary` | `address` | Dirección que recibirá los fondos |
| `justification` | `string` | Texto justificando el desembolso |
| `alertId` | `uint256` | ID de la alerta ambiental que motiva el desembolso |
| `proposalId` | `uint256` | ID de la propuesta DAO que lo autoriza |
| `status` | `DisbursementStatus` | Estado actual de la solicitud |

### Variables de estado

| Variable | Tipo | Descripción |
|---|---|---|
| `token` | `IERC20` (immutable) | Referencia al contrato MockCOPToken |
| `governanceDAO` | `address` (immutable) | Referencia al contrato GovernanceDAO |
| `envMonitoring` | `address` (immutable) | Referencia al contrato EnvironmentalMonitoring |
| `budgetItemCount` | `uint256` | Contador de rubros (próximo ID) |
| `disbursementCount` | `uint256` | Contador de solicitudes (próximo ID) |
| `budgetItems` | `mapping(uint256 => BudgetItem)` | Rubros indexados por ID |
| `disbursements` | `mapping(uint256 => DisbursementRequest)` | Solicitudes indexadas por ID |

### Constructor

```solidity
constructor(address mockCOPToken, address _governanceDAO, address _environmentalMonitoring)
```

Recibe las tres direcciones de contratos dependientes. Todas deben ser distintas de `address(0)`.

### Funciones

#### `createBudgetItem(string name, string description, uint256 allocatedAmount)`
- **Acceso:** Solo `owner`
- **Qué hace:** Crea un rubro de gasto con `spentAmount = 0`.
- **Validaciones:** `name` no vacío, `allocatedAmount > 0`.
- **Evento:** `BudgetItemCreated(itemId, name, allocatedAmount)`

#### `deposit(uint256 amount)`
- **Acceso:** Cualquiera (pero en la práctica el owner)
- **Protección:** `nonReentrant`
- **Qué hace:** Transfiere `amount` mCOP desde el caller al vault usando `transferFrom`.
- **Prerequisito:** El caller debe haber llamado `approve(FinancialTraceability_address, amount)` en `MockCOPToken` antes.
- **Evento:** `FundsDeposited(depositor, amount, newVaultBalance)`

#### `requestDisbursement(budgetItemId, amount, beneficiary, justification, alertId, proposalId)`
- **Acceso:** Solo `owner`
- **Qué hace:** Crea una solicitud de desembolso con estado `Pending`. No transfiere fondos todavía.
- **Validaciones:** Rubro existe, `amount > 0`, `beneficiary != address(0)`, `justification` no vacía.
- **Evento:** `DisbursementRequested(disbursementId, budgetItemId, beneficiary, amount)`

#### `executeDisbursement(uint256 disbursementId)`
- **Acceso:** Solo `owner`
- **Protección:** `nonReentrant`
- **Qué hace:** Verifica las dos condiciones y transfiere los fondos.
- **Condición A:** `IEnvironmentalMonitoring(envMonitoring).isAlertValid(req.alertId)` → `true`
- **Condición B:** `IGovernanceDAO(governanceDAO).isProposalApproved(req.proposalId)` → `true`
- **Patrón de seguridad:** Checks → Effects → Interactions (actualiza estado antes de transferir)
- **Evento:** `DisbursementExecuted(disbursementId, beneficiary, amount, alertId, proposalId)`

#### `getVaultBalance()`
- **Retorna:** Saldo actual de mCOP en el vault.

#### `getDisbursement(uint256 disbursementId)`
- **Retorna:** Struct `DisbursementRequest` completo.

### Eventos

| Evento | Cuándo |
|---|---|
| `BudgetItemCreated(itemId, name, allocatedAmount)` | Al crear rubro |
| `FundsDeposited(depositor, amount, newVaultBalance)` | Al depositar |
| `DisbursementRequested(disbursementId, budgetItemId, beneficiary, amount)` | Al crear solicitud |
| `DisbursementExecuted(disbursementId, beneficiary, amount, alertId, proposalId)` | Al ejecutar desembolso |

### Flujo de un desembolso

```
[Prerequisito] approve(vault_address, amount) en MockCOPToken
        ↓
deposit(amount) → fondos entran al vault
        ↓
createBudgetItem("Monitoreo", ..., 15000000)
        ↓
requestDisbursement(budgetItemId, amount, beneficiary, justification, alertId, proposalId)
  → status: Pending
        ↓
executeDisbursement(disbursementId)
  → isAlertValid(alertId)?  ✅ (alertId < alertCount en EnvironmentalMonitoring)
  → isProposalApproved(proposalId)? ✅ (status==Approved && finalized en GovernanceDAO)
  → saldo vault >= amount? ✅
  → status = Executed
  → budgetItems[budgetItemId].spentAmount += amount
  → token.transfer(beneficiary, amount) ✅
```

---

## 6. SustainabilityClimate

**Archivo:** `contracts/SustainabilityClimate.sol`  
**Hereda de:** `Ownable` (OpenZeppelin v5)  
**Propósito:** Mide el impacto ambiental de las intervenciones. Compara el estado del río antes (baseline) y después (outcome) de una acción, calcula el porcentaje de mejora y emite un "claim" climático verificable on-chain.

> ⚠️ Los claims emitidos son simulaciones educativas. No constituyen créditos de carbono certificados bajo ningún estándar (Verra VCS, Gold Standard, etc.).

### Variables de estado

| Variable | Tipo | Descripción |
|---|---|---|
| `envMonitoring` | `address` (immutable) | Referencia al contrato EnvironmentalMonitoring |
| `records` | `mapping(bytes32 => EnvironmentalRecord)` | Registros indexados por `keccak256(stationId + variable)` |

### Struct `EnvironmentalRecord`

Almacena el par baseline/outcome para una combinación de estación y variable ambiental.

| Campo | Tipo | Descripción |
|---|---|---|
| `baselineValue` | `uint256` | Valor antes de la intervención (escalado ×100) |
| `outcomeValue` | `uint256` | Valor después de la intervención (escalado ×100) |
| `hasBaseline` | `bool` | `true` si el baseline fue registrado |
| `hasOutcome` | `bool` | `true` si el outcome fue registrado |

### Clave del mapping

Los registros se indexan con:
```solidity
bytes32 key = keccak256(abi.encodePacked(stationId, variable));
```
Esto permite almacenar múltiples variables por estación sin colisiones. Ejemplo:
- `keccak256("la-isla" + "dissolvedOxygen")` → clave única para O₂ en La Isla
- `keccak256("la-isla" + "ph")` → clave única para pH en La Isla

### Funciones

#### `registerBaseline(string stationId, string variable, uint256 value)`
- **Acceso:** Solo `owner`
- **Qué hace:** Registra el valor de referencia (estado del río antes de intervenir). Activa `hasBaseline = true`.
- **Evento:** `BaselineRegistered(stationId, variable, baselineValue)`

#### `registerOutcome(string stationId, string variable, uint256 value)`
- **Acceso:** Solo `owner`
- **Qué hace:** Registra el valor post-intervención. Activa `hasOutcome = true`.
- **Evento:** `OutcomeRegistered(stationId, variable, outcomeValue)`

#### `emitClimateImpactClaim(string stationId, string variable)`
- **Acceso:** Solo `owner`
- **Qué hace:** Calcula el porcentaje de mejora y emite el claim.
- **Validaciones:** Debe existir baseline y outcome. `baselineValue > 0`.
- **Fórmula:**
  ```
  improvementPct = ((outcomeValue - baselineValue) × 100) / baselineValue
  ```
  Valor positivo = mejora. Valor negativo = degradación.
- **Evento:** `ClimateImpactClaimCreated(stationId, variable, baselineValue, outcomeValue, improvementPct)`

#### `getRecord(string stationId, string variable)`
- **Retorna:** `(baseline, outcome, improvementPct)`
- **Casos de retorno:**

| Situación | baseline | outcome | improvementPct |
|---|---|---|---|
| Sin datos | `0` | `0` | `0` |
| Solo baseline | `baselineValue` | `0` | `0` |
| Ambos, baseline > 0 | `baselineValue` | `outcomeValue` | calculado |
| Ambos, baseline = 0 | `0` | `outcomeValue` | `0` |

### Eventos

| Evento | Cuándo |
|---|---|
| `BaselineRegistered(stationId, variable, baselineValue)` | Al registrar baseline |
| `OutcomeRegistered(stationId, variable, outcomeValue)` | Al registrar outcome |
| `ClimateImpactClaimCreated(stationId, variable, baselineValue, outcomeValue, improvementPct)` | Al emitir claim |

### Ejemplo de cálculo

```
Estación: "la-isla"
Variable: "dissolvedOxygen"

Baseline: 480  (O₂ = 4.80 mg/L — valor crítico, por debajo del umbral)
Outcome:  620  (O₂ = 6.20 mg/L — después de la intervención)

improvementPct = ((620 - 480) × 100) / 480
               = (140 × 100) / 480
               = 14000 / 480
               = 29  (aritmética entera en Solidity)
```

El claim dice: "el oxígeno disuelto mejoró un 29% en La Isla".

---

## 7. Interfaces

Las interfaces definen los métodos que un contrato expone para ser consumido por otros contratos, sin revelar la implementación interna.

### `IEnvironmentalMonitoring`

**Archivo:** `contracts/interfaces/IEnvironmentalMonitoring.sol`  
**Consumida por:** `FinancialTraceability`, `SustainabilityClimate`

```solidity
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

| Función | Uso |
|---|---|
| `isAlertValid(alertId)` | `FinancialTraceability` la llama en `executeDisbursement()` para verificar que la alerta existe |
| `getStation(stationId)` | Disponible para consultas externas |

### `IGovernanceDAO`

**Archivo:** `contracts/interfaces/IGovernanceDAO.sol`  
**Consumida por:** `FinancialTraceability`

```solidity
interface IGovernanceDAO {
    function isProposalApproved(uint256 proposalId) external view returns (bool);
    function getProposal(uint256 proposalId) external view returns (...);
}
```

| Función | Uso |
|---|---|
| `isProposalApproved(proposalId)` | `FinancialTraceability` la llama en `executeDisbursement()` para verificar que la propuesta fue aprobada |
| `getProposal(proposalId)` | Disponible para consultas externas |

---

## 8. Flujo completo del sistema

Este es el recorrido de extremo a extremo que conecta los 5 contratos.

```
FASE 1 — CONFIGURACIÓN INICIAL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MockCOPToken.mint(owner, 70_000_000)
    → owner tiene 70M mCOP

GovernanceDAO.registerActor(cuenta2, Autoridad)
GovernanceDAO.registerActor(cuenta3, Autoridad)
GovernanceDAO.registerActor(cuenta4, Autoridad)
    → 3 actores habilitados para votar

EnvironmentalMonitoring.registerStation("la-isla", "La Isla", lat, lon)
EnvironmentalMonitoring.setThresholds("la-isla", phMin, phMax, doMin, ...)
EnvironmentalMonitoring.grantSensorOracle(cuenta2)
    → estación configurada con umbrales y oráculo autorizado


FASE 2 — DETECCIÓN DEL PROBLEMA AMBIENTAL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[cuenta2 como SENSOR_ORACLE]
EnvironmentalMonitoring.recordReading("la-isla", timestamp, ph=725, do=480, ...)
    → ReadingRecorded emitido
    → do=480 < doMin=500 → AlertTriggered(alertId=0, "dissolvedOxygen", 480)
    → alertCount = 1


FASE 3 — GOBERNANZA: PROPUESTA Y VOTACIÓN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[cuenta2]
GovernanceDAO.createProposal(DisbursementAuthorization, "Autorizar desembolso...", 60)
    → proposalId = 1, deadline = now + 60s

[cuenta2, cuenta3, cuenta4]
GovernanceDAO.castVote(1, true) × 3
    → votesFor = 3, votesAgainst = 0

[esperar 60 segundos]
GovernanceDAO.finalizeProposal(1)
    → status = Approved, finalized = true


FASE 4 — DESEMBOLSO CONDICIONADO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[owner]
MockCOPToken.approve(FinancialTraceability_address, 70_000_000)
FinancialTraceability.deposit(70_000_000)
    → vault tiene 70M mCOP

FinancialTraceability.createBudgetItem("Monitoreo", "Equipos La Isla", 15_000_000)
    → itemId = 1

FinancialTraceability.requestDisbursement(1, 5_000_000, cuenta3, "Mitigacion...", alertId=0, proposalId=1)
    → disbursementId = 1, status = Pending

FinancialTraceability.executeDisbursement(1)
    → isAlertValid(0)? → alertCount=1 → 0 < 1 → ✅
    → isProposalApproved(1)? → Approved && finalized → ✅
    → vault >= 5M? → ✅
    → status = Executed
    → cuenta3 recibe 5M mCOP
    → vault queda con 65M mCOP


FASE 5 — MEDICIÓN DE IMPACTO CLIMÁTICO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SustainabilityClimate.registerBaseline("la-isla", "dissolvedOxygen", 480)
    → hasBaseline = true

SustainabilityClimate.registerOutcome("la-isla", "dissolvedOxygen", 620)
    → hasOutcome = true

SustainabilityClimate.emitClimateImpactClaim("la-isla", "dissolvedOxygen")
    → improvementPct = ((620-480)×100)/480 = 29
    → ClimateImpactClaimCreated emitido
```

---

## 9. Convención de escalado de valores

Solidity no maneja decimales. Para representar valores con precisión, todos los valores ambientales se multiplican por 100 antes de almacenarse.

| Variable | Unidad real | Factor | Ejemplo real | Valor en contrato |
|---|---|---|---|---|
| pH | adimensional | ×100 | 7.25 | `725` |
| Oxígeno disuelto | mg/L | ×100 | 4.80 | `480` |
| Temperatura | °C | ×100 | 26.30 | `2630` |
| Conductividad | µS/cm | ×100 | 450.00 | `45000` |
| Turbidez | NTU | ×100 | 35.00 | `3500` |
| Latitud | grados | ×1e6 | 3.451° | `3451000` |
| Longitud | grados | ×1e6 | -76.52° | `-76520000` |

**Regla práctica:** para convertir un valor real al formato del contrato, multiplica por 100. Para leer un valor del contrato, divide por 100.

---

## 10. Errores comunes y sus causas

| Mensaje de error | Contrato | Causa |
|---|---|---|
| `"estacion ya existe"` | EnvironmentalMonitoring | Se intentó registrar una estación con un ID ya usado |
| `"phMin debe ser menor que phMax"` | EnvironmentalMonitoring | Los umbrales están invertidos |
| `"estacion no registrada"` | EnvironmentalMonitoring | Se intentó registrar una lectura en una estación que no existe |
| `"Solo actores registrados pueden crear propuestas"` | GovernanceDAO | La cuenta no fue registrada con `registerActor()` |
| `"el periodo de votacion ha expirado"` | GovernanceDAO | Se intentó votar después del deadline |
| `"el actor ya voto en esta propuesta"` | GovernanceDAO | La misma cuenta intentó votar dos veces |
| `"el periodo de votacion aun no ha expirado"` | GovernanceDAO | Se intentó finalizar antes del deadline |
| `"la propuesta ya fue finalizada"` | GovernanceDAO | Se llamó `finalizeProposal()` dos veces |
| `"transferencia fallida"` | FinancialTraceability | No se llamó `approve()` antes de `deposit()`, o el saldo es insuficiente |
| `"alerta ambiental no valida"` | FinancialTraceability | El `alertId` no existe (no se ha generado esa alerta) |
| `"propuesta DAO no aprobada"` | FinancialTraceability | La propuesta no fue finalizada o fue rechazada |
| `"saldo insuficiente en vault"` | FinancialTraceability | El vault no tiene suficientes mCOP para el desembolso |
| `"desembolso no esta pendiente"` | FinancialTraceability | Se intentó ejecutar un desembolso ya ejecutado |
| `"linea base no registrada"` | SustainabilityClimate | Se llamó `emitClimateImpactClaim()` sin registrar baseline primero |
| `"resultado post-intervencion no registrado"` | SustainabilityClimate | Se llamó `emitClimateImpactClaim()` sin registrar outcome primero |
| `"baseline no puede ser cero"` | SustainabilityClimate | El valor de baseline es 0, no se puede calcular porcentaje |
