# Río Cali Transparente

**Prototipo blockchain de gobernanza ambiental para el Río Cali, La Papaya.**

Este proyecto demuestra cómo la tecnología blockchain puede usarse para registrar lecturas ambientales de sensores IoT simulados, gestionar propuestas de gobernanza participativa, controlar desembolsos de fondos con doble condición de validación y emitir claims de impacto climático verificables en cadena.

---

## Descargo de responsabilidad

> ⚠️ **Importante:** este es un prototipo simulado desarrollado exclusivamente para fines educativos y de demostración técnica.

| Aspecto | Alcance del prototipo |
|---|---|
| Datos ambientales | Las lecturas de sensores son valores ficticios ingresados manualmente. |
| Sensores | No existe conexión con dispositivos IoT físicos ni oráculos externos. |
| Fondos | El token `mCOP` (`MockCOPToken`) no representa dinero real ni tiene valor económico. |
| Claims climáticos | Los claims emitidos no constituyen créditos de carbono verificados ni tienen validez bajo estándares como Verra VCS o Gold Standard. |
| Red de despliegue | Usar únicamente en Remix IDE con VM local. No desplegar en mainnet ni en redes públicas. |

---

## Estructura de archivos

```text
contracts/
├── interfaces/
│   ├── IEnvironmentalMonitoring.sol   # Interfaz para consumo externo del monitoreo
│   └── IGovernanceDAO.sol             # Interfaz para consumo externo del DAO
├── MockCOPToken.sol                   # Token ERC20 simulado (mCOP)
├── EnvironmentalMonitoring.sol        # Registro de estaciones y lecturas de sensores
├── GovernanceDAO.sol                  # Gobernanza participativa con votaciones
├── FinancialTraceability.sol          # Vault de fondos con desembolso condicionado
└── SustainabilityClimate.sol          # Claims de impacto climático
README.md
```

---

## Requisitos previos

| Requisito | Detalle |
|---|---|
| Remix IDE | Abrir en el navegador: <https://remix.ethereum.org> |
| Compilador Solidity | Versión `0.8.24` o superior en el panel **Solidity Compiler** |
| OpenZeppelin Contracts | Versión 5, necesaria para `ERC20`, `Ownable`, `AccessControl`, `ReentrancyGuard` e `IERC20` |

---

## Importar OpenZeppelin en Remix

Los contratos usan imports con el path `@openzeppelin/contracts/...`. Para que Remix los resuelva correctamente, usa uno de los siguientes métodos.

### Método A: plugin npm de Remix, recomendado

1. Abre el panel **Plugin Manager** en Remix.
2. Busca **npm** y activa el plugin **npm Package Manager**.
3. En el panel npm, escribe `@openzeppelin/contracts` y haz clic en **Install**.
4. Remix descargará los contratos de OpenZeppelin v5 y resolverá los imports.

### Método B: URL directa de GitHub, alternativa

Si el plugin npm no está disponible, reemplaza los imports en cada contrato por la URL directa de GitHub:

```solidity
// En lugar de:
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Usar:
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.0/contracts/token/ERC20/ERC20.sol";
```

---

## Orden de despliegue

Despliega los contratos en este orden exacto, ya que algunos dependen de contratos desplegados previamente.

| Paso | Contrato | Constructor | Resultado esperado |
|---:|---|---|---|
| 1 | `MockCOPToken` | `initialSupply = 70000000` | El deployer recibe `70,000,000 mCOP`. Copia la dirección del contrato. |
| 2 | `GovernanceDAO` | Sin parámetros | El deployer queda como Admin del DAO. Copia la dirección del contrato. |
| 3 | `EnvironmentalMonitoring` | Sin parámetros | El deployer queda como Admin del monitoreo. Copia la dirección del contrato. |
| 4 | `FinancialTraceability` | `mockCOPToken`, `governanceDAO`, `environmentalMonitoring` | El vault queda configurado con las referencias de los contratos dependientes. |
| 5 | `SustainabilityClimate` | `environmentalMonitoring` | El contrato de claims climáticos queda vinculado al monitoreo ambiental. |

### Parámetros para `FinancialTraceability`

| Parámetro | Valor |
|---|---|
| `mockCOPToken` | Dirección de `MockCOPToken` |
| `governanceDAO` | Dirección de `GovernanceDAO` |
| `environmentalMonitoring` | Dirección de `EnvironmentalMonitoring` |

### Parámetro para `SustainabilityClimate`

| Parámetro | Valor |
|---|---|
| `environmentalMonitoring` | Dirección de `EnvironmentalMonitoring` |

---

## Flujo de prueba completo

Una vez desplegados los 5 contratos, sigue este flujo para probar el sistema de extremo a extremo.

> **Convención de cuentas en Remix VM**
>
> - **Cuenta 1:** deployer / owner, seleccionada por defecto al desplegar.
> - **Cuenta 2:** sensor oracle y actor DAO.
> - **Cuenta 3:** actor DAO y beneficiario del desembolso.
> - **Cuenta 4:** actor DAO.

---

### 1. Mintear tokens a aportantes simulados

| Campo | Valor |
|---|---|
| Cuenta activa | Cuenta 1, owner |
| Contrato | `MockCOPToken` |
| Función | `mint` |
| `to` | Dirección de Cuenta 1 |
| `amount` | `70000000` |

**Resultado esperado:** la Cuenta 1 recibe `70,000,000 mCOP` adicionales. Se emite el evento `Transfer` desde `address(0)`.

---

### 2. Registrar actores DAO como autoridad

| Campo | Valor |
|---|---|
| Cuenta activa | Cuenta 1, Admin |
| Contrato | `GovernanceDAO` |
| Función | `registerActor` |

| Llamada | `actor` | `actorType` |
|---:|---|---|
| 1 | Dirección de Cuenta 2 | `0` (Autoridad) |
| 2 | Dirección de Cuenta 3 | `0` (Autoridad) |
| 3 | Dirección de Cuenta 4 | `0` (Autoridad) |

**Resultado esperado:** se emiten 3 eventos `ActorRegistered`. Las cuentas 2, 3 y 4 quedan habilitadas para votar y crear propuestas.

---

### 3. Registrar estación La Isla

| Campo | Valor |
|---|---|
| Cuenta activa | Cuenta 1, Admin |
| Contrato | `EnvironmentalMonitoring` |
| Función | `registerStation` |
| `stationId` | `"la-isla"` |
| `name` | `"La Isla"` |
| `latitude` | `3451000` |
| `longitude` | `-76520000` |

**Resultado esperado:** se emite el evento `StationRegistered` con los datos de la estación.

---

### 4. Configurar umbrales para La Isla

| Campo | Valor |
|---|---|
| Cuenta activa | Cuenta 1, Admin |
| Contrato | `EnvironmentalMonitoring` |
| Función | `setThresholds` |

| Parámetro | Valor | Equivale a |
|---|---:|---|
| `stationId` | `"la-isla"` | Estación La Isla |
| `phMin` | `650` | pH 6.50 |
| `phMax` | `850` | pH 8.50 |
| `doMin` | `500` | O₂ 5.00 mg/L |
| `doMax` | `1200` | O₂ 12.00 mg/L |
| `tempMin` | `1500` | 15.00 °C |
| `tempMax` | `3000` | 30.00 °C |
| `conductMin` | `10000` | 100.00 µS/cm |
| `conductMax` | `100000` | 1000.00 µS/cm |
| `turbidMin` | `0` | 0 NTU |
| `turbidMax` | `10000` | 100.00 NTU |

**Resultado esperado:** se emite el evento `ThresholdsUpdated` con todos los umbrales configurados.

---

### 5. Otorgar rol `SENSOR_ORACLE` a Cuenta 2

| Campo | Valor |
|---|---|
| Cuenta activa | Cuenta 1, Admin |
| Contrato | `EnvironmentalMonitoring` |
| Función | `grantSensorOracle` |
| `account` | Dirección de Cuenta 2 |

**Resultado esperado:** se emite el evento `RoleGranted` de `AccessControl`. La Cuenta 2 queda habilitada para enviar lecturas de sensores.

---

### 6. Registrar lectura crítica simulada, O₂ bajo

| Campo | Valor |
|---|---|
| Cuenta activa | Cuenta 2, `SENSOR_ORACLE` |
| Contrato | `EnvironmentalMonitoring` |
| Función | `recordReading` |

| Parámetro | Valor | Equivale a |
|---|---:|---|
| `stationId` | `"la-isla"` | Estación La Isla |
| `timestamp` | `1700000000` | Unix timestamp |
| `ph` | `725` | pH 7.25 |
| `dissolvedOxygen` | `480` | O₂ 4.80 mg/L |
| `temperature` | `2630` | 26.30 °C |
| `conductivity` | `45000` | 450.00 µS/cm |
| `turbidity` | `3500` | 35.00 NTU |
| `evidenceHash` | `0x0000000000000000000000000000000000000000000000000000000000000001` | Hash simulado |

**Resultado esperado:**

- Se emite el evento `ReadingRecorded` con todos los valores de la lectura.
- Se emite el evento `AlertTriggered` porque `dissolvedOxygen = 480` es menor que `doMin = 500`.

| Campo del evento | Valor esperado |
|---|---|
| `variable` | `"dissolvedOxygen"` |
| `value` | `480` |
| `alertId` | `0` |

---

### 7. Crear propuesta DAO para validar incidente

| Campo | Valor |
|---|---|
| Cuenta activa | Cuenta 2, actor registrado |
| Contrato | `GovernanceDAO` |
| Función | `createProposal` |
| `proposalType` | `1` (`DisbursementAuthorization`) |
| `description` | `"Autorizar desembolso para mitigacion La Isla"` |
| `votingDuration` | `60` |

**Resultado esperado:** se emite el evento `ProposalCreated` con `proposalId = 1`.

---

### 8. Votar la propuesta con 3 actores

| Campo | Valor |
|---|---|
| Contrato | `GovernanceDAO` |
| Función | `castVote` |
| Parámetros | `proposalId = 1`, `inFavor = true` |

| Cuenta activa | Acción |
|---|---|
| Cuenta 2 | `castVote(1, true)` |
| Cuenta 3 | `castVote(1, true)` |
| Cuenta 4 | `castVote(1, true)` |

**Resultado esperado:** se emiten 3 eventos `VoteCast` con `inFavor = true`.

---

### 9. Finalizar propuesta

> ⏱️ Espera al menos 60 segundos desde la creación de la propuesta o avanza el tiempo en la VM de Remix usando el campo **Block timestamp** del panel de configuración.

| Campo | Valor |
|---|---|
| Cuenta activa | Cualquiera, la función es pública |
| Contrato | `GovernanceDAO` |
| Función | `finalizeProposal` |
| `proposalId` | `1` |

**Resultado esperado:** se emite el evento `ProposalFinalized` con los siguientes valores:

| Campo | Valor |
|---|---:|
| `result` | `1` (`Approved`) |
| `votesFor` | `3` |
| `votesAgainst` | `0` |

---

### 10. Crear rubro de gasto

| Campo | Valor |
|---|---|
| Cuenta activa | Cuenta 1, owner |
| Contrato | `FinancialTraceability` |
| Función | `createBudgetItem` |
| `name` | `"Monitoreo"` |
| `description` | `"Equipos de monitoreo La Isla"` |
| `allocatedAmount` | `15000000` |

**Resultado esperado:** se emite el evento `BudgetItemCreated` con `itemId = 1`.

---

### 11. Depositar fondos en el vault

Este paso requiere dos transacciones: primero aprobar el gasto y luego depositar.

#### Transacción A: aprobar gasto

| Campo | Valor |
|---|---|
| Cuenta activa | Cuenta 1, owner |
| Contrato | `MockCOPToken` |
| Función | `approve` |
| `spender` | Dirección de `FinancialTraceability` |
| `amount` | `70000000` |

**Resultado esperado:** se emite el evento `Approval` de ERC20.

#### Transacción B: depositar

| Campo | Valor |
|---|---|
| Cuenta activa | Cuenta 1, owner |
| Contrato | `FinancialTraceability` |
| Función | `deposit` |
| `amount` | `70000000` |

**Resultado esperado:** se emite el evento `FundsDeposited` con `newVaultBalance = 70000000`.

---

### 12. Crear solicitud de desembolso

| Campo | Valor |
|---|---|
| Cuenta activa | Cuenta 1, owner |
| Contrato | `FinancialTraceability` |
| Función | `requestDisbursement` |
| `budgetItemId` | `1` |
| `amount` | `5000000` |
| `beneficiary` | Dirección de Cuenta 3 |
| `justification` | `"Mitigacion incidente La Isla"` |
| `alertId` | `0` |
| `proposalId` | `1` |

**Resultado esperado:** se emite el evento `DisbursementRequested` con `disbursementId = 1`.

---

### 13. Ejecutar desembolso

| Campo | Valor |
|---|---|
| Cuenta activa | Cuenta 1, owner |
| Contrato | `FinancialTraceability` |
| Función | `executeDisbursement` |
| `disbursementId` | `1` |

**Resultado esperado:** se emite el evento `DisbursementExecuted` con los siguientes valores:

| Campo | Valor |
|---|---|
| `disbursementId` | `1` |
| `beneficiary` | Dirección de Cuenta 3 |
| `amount` | `5000000` |
| `alertId` | `0` |
| `proposalId` | `1` |

La Cuenta 3 recibe `5,000,000 mCOP`. El vault queda con `65,000,000 mCOP`.

El contrato verifica internamente estas dos condiciones antes de transferir:

1. `isAlertValid(0)` retorna `true`, porque `alertId = 0` existe y `alertCount = 1`.
2. `isProposalApproved(1)` retorna `true`, porque la propuesta fue finalizada como `Approved`.

---

### 14. Registrar intervención y emitir claim climático

Este paso registra la mejora ambiental posterior a la intervención y emite el claim de impacto climático.

#### 14a. Registrar baseline en `FinancialTraceability`, opcional

| Campo | Valor |
|---|---|
| Contrato | `FinancialTraceability` |
| Función | `registerBaseline`, si está disponible en la implementación |
| `stationId` | `"la-isla"` |
| `variable` | `"dissolvedOxygen"` |
| `value` | `480` |

#### 14b. Registrar baseline en `SustainabilityClimate`

| Campo | Valor |
|---|---|
| Cuenta activa | Cuenta 1, owner |
| Contrato | `SustainabilityClimate` |
| Función | `registerBaseline` |
| `stationId` | `"la-isla"` |
| `variable` | `"dissolvedOxygen"` |
| `value` | `480` |

**Resultado esperado:** se emite el evento `BaselineRegistered`.

#### 14c. Registrar outcome posterior a la intervención

| Campo | Valor |
|---|---|
| Contrato | `SustainabilityClimate` |
| Función | `registerOutcome` |
| `stationId` | `"la-isla"` |
| `variable` | `"dissolvedOxygen"` |
| `value` | `620` |

**Resultado esperado:** se emite el evento `OutcomeRegistered`.

#### 14d. Emitir claim climático

| Campo | Valor |
|---|---|
| Contrato | `SustainabilityClimate` |
| Función | `emitClimateImpactClaim` |
| `stationId` | `"la-isla"` |
| `variable` | `"dissolvedOxygen"` |

**Resultado esperado:** se emite el evento `ClimateImpactClaimCreated` con los siguientes valores:

| Campo | Valor |
|---|---:|
| `baselineValue` | `480` |
| `outcomeValue` | `620` |
| `improvementPct` | `29` |

**Cálculo:**

```text
((620 - 480) * 100) / 480 = 14000 / 480 = 29
```

> Solidity usa aritmética entera en este caso, por eso el resultado queda truncado a `29`.

---

## Verificar eventos en Remix

Después de cada transacción, los eventos emitidos aparecen en la consola de Remix.

1. Ejecuta la transacción haciendo clic en el botón de la función en el panel **Deployed Contracts**.
2. Observa la consola en la parte inferior de Remix. Verás un bloque verde si la transacción fue exitosa o rojo si hubo revert.
3. Expande el resultado haciendo clic en la flecha junto al hash de la transacción.
4. Busca la sección `logs` dentro del resultado expandido.
5. Lee los parámetros decodificados. Remix muestra el nombre del evento y cada parámetro con su valor.

> Los parámetros marcados como `indexed` en el contrato aparecen en `topics`. Los parámetros no indexados aparecen en `data`.

### Ejemplo de salida para `AlertTriggered`

```json
{
  "logs": [
    {
      "event": "AlertTriggered",
      "args": {
        "stationId": "la-isla",
        "alertId": "0",
        "variable": "dissolvedOxygen",
        "value": "480",
        "timestamp": "1700000000"
      }
    }
  ]
}
```

En Remix VM, todos los eventos son visibles directamente en la consola sin necesidad de filtros. En exploradores como Etherscan, los parámetros `indexed` permiten filtrar eventos de forma eficiente.

---

## Nota final

Este prototipo fue desarrollado con fines exclusivamente educativos y de demostración técnica para el proyecto **La Papaya, Río Cali**.

- Los datos ambientales son simulados y no provienen de sensores reales.
- El token `mCOP` no tiene valor económico ni representa pesos colombianos reales.
- Los claims climáticos emitidos no constituyen créditos de carbono bajo estándares de certificación como Verra VCS, Gold Standard o Plan Vivo.
- No desplegar en mainnet ni en ninguna red pública con fondos reales.
- El uso de `block.timestamp` para períodos de votación es adecuado para un prototipo en VM local, pero no es seguro para producción.

Para una implementación en producción se requeriría auditoría de seguridad, oráculos certificados, integración con sistemas de identidad, cumplimiento regulatorio ambiental colombiano y certificación por un organismo acreditado.
