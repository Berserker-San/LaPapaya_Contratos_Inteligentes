# Implementation Plan

## Overview

Plan de implementación para el prototipo "Río Cali Transparente": 5 contratos Solidity + 2 interfaces + README, desplegables en Remix IDE con VM local. Las tareas siguen el orden de dependencias entre contratos: interfaces primero, luego contratos base, luego contratos que dependen de ellos.

## Tasks

- [x] 1. Crear interfaces Solidity
  - [x] 1.1 Crear `contracts/interfaces/IGovernanceDAO.sol` con firma `isProposalApproved(uint256)` y `getProposal(uint256)`
  - [x] 1.2 Crear `contracts/interfaces/IEnvironmentalMonitoring.sol` con firmas `isAlertValid(uint256)` y `getStation(string)`
  - **Requirements:** 8.1, 8.2, 8.5

- [x] 2. Implementar MockCOPToken
  - [x] 2.1 Crear `contracts/MockCOPToken.sol`
  - [x] 2.2 Heredar de `ERC20` y `Ownable` de OpenZeppelin v5
  - [x] 2.3 Constructor recibe `uint256 initialSupply` y mintea al deployer
  - [x] 2.4 Implementar `mint(address to, uint256 amount) external onlyOwner`
  - [x] 2.5 Verificar que compila sin errores en Remix con `^0.8.24`
  - **Requirements:** 1.2, 2.1, 2.2, 2.3, 2.4, 2.5, 10.2

- [x] 3. Implementar EnvironmentalMonitoring
  - [x] 3.1 Crear `contracts/EnvironmentalMonitoring.sol`
  - [x] 3.2 Heredar de `AccessControl`; definir `ADMIN_ROLE` y `SENSOR_ORACLE_ROLE` como constantes `bytes32`
  - [x] 3.3 Definir structs `Station`, `Thresholds`, `SensorReading`
  - [x] 3.4 Implementar `registerStation(stationId, name, latitude, longitude)` con validación de duplicado
  - [x] 3.5 Implementar `setThresholds(stationId, ...)` con validación min < max
  - [x] 3.6 Implementar `recordReading(stationId, timestamp, ph, do, temp, cond, turb, evidenceHash)` con rol `SENSOR_ORACLE_ROLE`
  - [x] 3.7 Lógica de comparación contra umbrales: emitir `AlertTriggered` si alguna variable supera su umbral; registrar alerta en `alertStation` mapping con `alertCount++`
  - [x] 3.8 Implementar `isAlertValid(uint256 alertId) external view returns (bool)` para consumo por interfaz
  - [x] 3.9 Implementar `getStation`, `getThresholds`, `getReadingsCount`
  - [x] 3.10 Implementar `grantSensorOracle(address)` restringido a `ADMIN_ROLE`
  - [x] 3.11 Emitir todos los eventos: `StationRegistered`, `ThresholdsUpdated`, `ReadingRecorded`, `AlertTriggered`
  - **Requirements:** 1.3, 3.1, 3.2, 3.3, 3.4, 3.5, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 8.1, 9.1, 9.2, 9.3, 10.1, 10.4, 10.5

- [x] 4. Implementar GovernanceDAO
  - [x] 4.1 Crear `contracts/GovernanceDAO.sol`
  - [x] 4.2 Heredar de `AccessControl`; definir roles `AUTORIDAD_ROLE`, `COMUNIDAD_ROLE`, `ACADEMIA_ROLE`, `SECTOR_PRIVADO_ROLE`
  - [x] 4.3 Definir enums `ActorType`, `ProposalType`, `ProposalStatus`
  - [x] 4.4 Definir struct `Proposal` con todos los campos del diseño
  - [x] 4.5 Implementar `registerActor(address, ActorType)` restringido a `ADMIN_ROLE`; asignar rol correspondiente; emitir `ActorRegistered`
  - [x] 4.6 Implementar `createProposal(ProposalType, description, votingDuration)` accesible a actores registrados; emitir `ProposalCreated`
  - [x] 4.7 Implementar `castVote(proposalId, inFavor)`: validar propuesta activa, período vigente, voto único por actor; emitir `VoteCast`
  - [x] 4.8 Implementar `finalizeProposal(proposalId)`: validar período expirado, calcular resultado (mayoría simple), actualizar estado; emitir `ProposalFinalized`
  - [x] 4.9 Implementar `isProposalApproved(uint256) external view returns (bool)` para consumo por interfaz
  - [x] 4.10 Implementar `getProposal(uint256)` para consulta
  - **Requirements:** 1.4, 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9, 8.2, 9.1, 9.2, 9.3, 10.1, 10.4, 10.5

- [x] 5. Implementar FinancialTraceability
  - [x] 5.1 Crear `contracts/FinancialTraceability.sol`
  - [x] 5.2 Heredar de `Ownable` y `ReentrancyGuard`; importar `IGovernanceDAO`, `IEnvironmentalMonitoring`, `IERC20`
  - [x] 5.3 Constructor recibe `address mockCOPToken`, `address governanceDAO`, `address environmentalMonitoring`; validar que no sean `address(0)`
  - [x] 5.4 Definir `TOTAL_BUDGET = 70_000_000` como constante
  - [x] 5.5 Implementar `createBudgetItem(name, description, allocatedAmount)` restringido a owner; emitir `BudgetItemCreated`
  - [x] 5.6 Implementar `deposit(uint256 amount) nonReentrant`: transferir tokens del caller al vault; emitir `FundsDeposited`
  - [x] 5.7 Implementar `requestDisbursement(budgetItemId, amount, beneficiary, justification, alertId, proposalId)` restringido a owner; emitir `DisbursementRequested`
  - [x] 5.8 Implementar `executeDisbursement(disbursementId) nonReentrant`: verificar doble condición (alerta válida + propuesta aprobada), verificar saldo, transferir tokens; emitir `DisbursementExecuted`
  - [x] 5.9 Implementar `getVaultBalance()` y `getDisbursement(uint256)`
  - **Requirements:** 1.5, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 6.9, 6.10, 8.3, 9.1, 9.2, 9.3, 10.3, 10.4

- [x] 6. Implementar SustainabilityClimate
  - [x] 6.1 Crear `contracts/SustainabilityClimate.sol`
  - [x] 6.2 Heredar de `Ownable`; importar `IEnvironmentalMonitoring`
  - [x] 6.3 Constructor recibe `address environmentalMonitoring`; validar que no sea `address(0)`
  - [x] 6.4 Definir struct `EnvironmentalRecord` y mapping `records` con clave `bytes32` (hash de stationId + variable)
  - [x] 6.5 Implementar `registerBaseline(stationId, variable, value)` restringido a owner; emitir `BaselineRegistered`
  - [x] 6.6 Implementar `registerOutcome(stationId, variable, value)` restringido a owner; emitir `OutcomeRegistered`
  - [x] 6.7 Implementar `emitClimateImpactClaim(stationId, variable)`: validar que existen baseline y outcome; calcular `improvement = ((int256(outcome) - int256(baseline)) * 100) / int256(baseline)`; revertir si baseline == 0; emitir `ClimateImpactClaimCreated`
  - [x] 6.8 Implementar `getRecord(stationId, variable)` retornando baseline, outcome e improvementPct
  - **Requirements:** 1.6, 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 8.4, 9.1, 9.2, 9.3

- [x] 7. Crear README.md con guía de despliegue en Remix
  - [x] 7.1 Documentar orden de despliegue de los 5 contratos con parámetros de constructor
  - [x] 7.2 Documentar flujo de prueba completo de 14 pasos (desde mintear tokens hasta emitir claim climático)
  - [x] 7.3 Incluir valores de ejemplo para cada llamada (stationId, lecturas escaladas, montos, duraciones)
  - [x] 7.4 Documentar cómo verificar eventos en el log de transacciones de Remix
  - [x] 7.5 Incluir nota de descargo: prototipo simulado, sin datos reales ni certificación VCS
  - **Requirements:** 1.1, 1.7

## Task Dependency Graph

```json
{
  "waves": [
    {
      "wave": 1,
      "tasks": [1],
      "description": "Interfaces Solidity — sin dependencias"
    },
    {
      "wave": 2,
      "tasks": [2, 3, 4],
      "description": "Contratos base — dependen de interfaces (Task 1)"
    },
    {
      "wave": 3,
      "tasks": [5, 6],
      "description": "Contratos compuestos — dependen de Tasks 1, 2, 3, 4"
    },
    {
      "wave": 4,
      "tasks": [7],
      "description": "README — depende de todos los contratos (Tasks 1–6)"
    }
  ]
}
```

## Notes

- Todos los contratos usan `pragma solidity ^0.8.24`
- Los imports de OpenZeppelin usan el path `@openzeppelin/contracts/...` (compatible con Remix IDE vía npm plugin o URL de GitHub v5.0.0)
- Los valores de variables ambientales son enteros escalados ×100 (pH 7.25 → 725)
- No se usan datos reales, oráculos externos ni fondos reales
- El prototipo es exclusivamente para Remix IDE con VM local
