# Río Cali Transparente

Prototipo blockchain de gobernanza ambiental para el Río Cali — La Papaya.

Este proyecto demuestra cómo la tecnología blockchain puede usarse para registrar lecturas ambientales de sensores IoT simulados, gestionar propuestas de gobernanza participativa, controlar desembolsos de fondos con doble condición de validación, y emitir claims de impacto climático verificables en cadena.

---

> ⚠️ **DESCARGO DE RESPONSABILIDAD**
>
> Este es un **prototipo simulado** desarrollado exclusivamente para fines educativos y de demostración técnica.
>
> - **Sin datos reales:** Las lecturas de sensores son valores ficticios ingresados manualmente.
> - **Sin sensores reales:** No existe conexión con dispositivos IoT físicos ni oráculos externos.
> - **Sin fondos reales:** El token `mCOP` (MockCOPToken) no representa dinero real ni tiene valor económico.
> - **Sin certificación VCS:** Los claims climáticos emitidos no constituyen créditos de carbono verificados ni tienen validez bajo ningún estándar internacional (Verra VCS, Gold Standard, etc.).
> - **Solo para Remix IDE con VM local:** No desplegar en mainnet ni en ninguna red pública.

---

## Estructura de archivos

```
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

- **Remix IDE** en el navegador: [https://remix.ethereum.org](https://remix.ethereum.org)
- **Compilador Solidity:** versión `0.8.24` o superior (seleccionar en el panel "Solidity Compiler")
- **OpenZeppelin Contracts v5:** necesario para `ERC20`, `Ownable`, `AccessControl`, `ReentrancyGuard`, `IERC20`

---

## Cómo importar OpenZeppelin en Remix

Los contratos usan el path `@openzeppelin/contracts/...`. Para que Remix resuelva estos imports, sigue uno de estos métodos:

### Método A — Plugin npm de Remix (recomendado)

1. En Remix, abre el panel **Plugin Manager** (ícono de enchufe en la barra lateral izquierda).
2. Busca **"npm"** y activa el plugin **"npm Package Manager"**.
3. En el panel npm que aparece, escribe `@openzeppelin/contracts` y haz clic en **Install**.
4. Remix descargará automáticamente los contratos de OpenZeppelin v5 y resolverá los imports.

### Método B — URL de GitHub (alternativa)

Si el plugin npm no está disponible, reemplaza los imports en cada contrato usando la URL directa de GitHub:

```solidity
// En lugar de:
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Usar:
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.0/contracts/token/ERC20/ERC20.sol";
```

---

## Orden de despliegue

Despliega los contratos en este orden exacto. Cada contrato depende de los anteriores.

### Paso 1 — MockCOPToken

- **Archivo:** `contracts/MockCOPToken.sol`
- **Parámetro del constructor:**
  - `initialSupply` = `70000000`
- **Acción:** Selecciona la cuenta 1 (deployer) en el panel "Deploy & Run". Ingresa `70000000` en el campo `initialSupply` y haz clic en **Deploy**.
- **Resultado:** El deployer recibe 70,000,000 mCOP. Copia la dirección del contrato desplegado.

---

### Paso 2 — GovernanceDAO

- **Archivo:** `contracts/GovernanceDAO.sol`
- **Parámetros del constructor:** ninguno
- **Acción:** Haz clic en **Deploy** sin parámetros.
- **Resultado:** El deployer queda como Admin del DAO. Copia la dirección del contrato desplegado.

---

### Paso 3 — EnvironmentalMonitoring

- **Archivo:** `contracts/EnvironmentalMonitoring.sol`
- **Parámetros del constructor:** ninguno
- **Acción:** Haz clic en **Deploy** sin parámetros.
- **Resultado:** El deployer queda como Admin del monitoreo. Copia la dirección del contrato desplegado.

---

### Paso 4 — FinancialTraceability

- **Archivo:** `contracts/FinancialTraceability.sol`
- **Parámetros del constructor:**
  - `mockCOPToken` = `<dirección de MockCOPToken>`
  - `governanceDAO` = `<dirección de GovernanceDAO>`
  - `environmentalMonitoring` = `<dirección de EnvironmentalMonitoring>`
- **Acción:** Ingresa las tres direcciones copiadas en los pasos anteriores y haz clic en **Deploy**.
- **Resultado:** El vault queda configurado con las referencias a los tres contratos dependientes.

---

### Paso 5 — SustainabilityClimate

- **Archivo:** `contracts/SustainabilityClimate.sol`
- **Parámetro del constructor:**
  - `environmentalMonitoring` = `<dirección de EnvironmentalMonitoring>`
- **Acción:** Ingresa la dirección de `EnvironmentalMonitoring` y haz clic en **Deploy**.
- **Resultado:** El contrato de claims climáticos queda vinculado al monitoreo ambiental.

---

## Flujo de prueba completo (14 pasos)

Una vez desplegados los 5 contratos, sigue este flujo para probar el sistema de extremo a extremo.

> **Convención de cuentas en Remix VM:**
> - **Cuenta 1** = deployer / owner (seleccionada por defecto al desplegar)
> - **Cuenta 2**, **Cuenta 3**, **Cuenta 4** = actores adicionales disponibles en el selector "Account"

---

### Paso 1 — Mintear tokens a aportantes simulados

- **Cuenta activa:** Cuenta 1 (owner)
- **Contrato:** `MockCOPToken`
- **Función:** `mint`
- **Parámetros:**
  - `to` = `<dirección de Cuenta 1>`
  - `amount` = `70000000`
- **Resultado esperado:** La cuenta 1 recibe 70,000,000 mCOP adicionales. Evento `Transfer` emitido desde `address(0)`.

---

### Paso 2 — Registrar actores DAO (Autoridad)

- **Cuenta activa:** Cuenta 1 (Admin)
- **Contrato:** `GovernanceDAO`
- **Función:** `registerActor`
- **Repetir 3 veces** (una por cada cuenta):

  | Llamada | `actor`              | `actorType` |
  |---------|----------------------|-------------|
  | 1       | `<dirección Cuenta 2>` | `0` (Autoridad) |
  | 2       | `<dirección Cuenta 3>` | `0` (Autoridad) |
  | 3       | `<dirección Cuenta 4>` | `0` (Autoridad) |

- **Resultado esperado:** 3 eventos `ActorRegistered` emitidos. Las cuentas 2, 3 y 4 quedan habilitadas para votar y crear propuestas.

---

### Paso 3 — Registrar estación "La Isla"

- **Cuenta activa:** Cuenta 1 (Admin)
- **Contrato:** `EnvironmentalMonitoring`
- **Función:** `registerStation`
- **Parámetros:**
  - `stationId` = `"la-isla"`
  - `name` = `"La Isla"`
  - `latitude` = `3451000`
  - `longitude` = `-76520000`
- **Resultado esperado:** Evento `StationRegistered` con los datos de la estación.

---

### Paso 4 — Configurar umbrales para "La Isla"

- **Cuenta activa:** Cuenta 1 (Admin)
- **Contrato:** `EnvironmentalMonitoring`
- **Función:** `setThresholds`
- **Parámetros:**

  | Parámetro    | Valor    | Equivale a (×100) |
  |--------------|----------|-------------------|
  | `stationId`  | `"la-isla"` | —              |
  | `phMin`      | `650`    | pH 6.50           |
  | `phMax`      | `850`    | pH 8.50           |
  | `doMin`      | `500`    | O₂ 5.00 mg/L      |
  | `doMax`      | `1200`   | O₂ 12.00 mg/L     |
  | `tempMin`    | `1500`   | 15.00 °C          |
  | `tempMax`    | `3000`   | 30.00 °C          |
  | `conductMin` | `10000`  | 100.00 µS/cm      |
  | `conductMax` | `100000` | 1000.00 µS/cm     |
  | `turbidMin`  | `0`      | 0 NTU             |
  | `turbidMax`  | `10000`  | 100.00 NTU        |

- **Resultado esperado:** Evento `ThresholdsUpdated` con todos los umbrales configurados.

---

### Paso 5 — Otorgar rol SENSOR_ORACLE a Cuenta 2

- **Cuenta activa:** Cuenta 1 (Admin)
- **Contrato:** `EnvironmentalMonitoring`
- **Función:** `grantSensorOracle`
- **Parámetros:**
  - `account` = `<dirección Cuenta 2>`
- **Resultado esperado:** Evento `RoleGranted` de AccessControl. La Cuenta 2 puede ahora enviar lecturas de sensores.

---

### Paso 6 — Registrar lectura crítica simulada (O₂ bajo)

- **Cuenta activa:** Cuenta 2 (SENSOR_ORACLE)
- **Contrato:** `EnvironmentalMonitoring`
- **Función:** `recordReading`
- **Parámetros:**

  | Parámetro         | Valor                                                                | Equivale a       |
  |-------------------|----------------------------------------------------------------------|------------------|
  | `stationId`       | `"la-isla"`                                                          | —                |
  | `timestamp`       | `1700000000`                                                         | Unix timestamp   |
  | `ph`              | `725`                                                                | pH 7.25          |
  | `dissolvedOxygen` | `480`                                                                | O₂ 4.80 mg/L     |
  | `temperature`     | `2630`                                                               | 26.30 °C         |
  | `conductivity`    | `45000`                                                              | 450.00 µS/cm     |
  | `turbidity`       | `3500`                                                               | 35.00 NTU        |
  | `evidenceHash`    | `0x0000000000000000000000000000000000000000000000000000000000000001` | Hash simulado    |

- **Resultado esperado:**
  - Evento `ReadingRecorded` con todos los valores de la lectura.
  - Evento `AlertTriggered` porque `dissolvedOxygen = 480 < doMin = 500`.
    - `variable` = `"dissolvedOxygen"`
    - `value` = `480`
    - `alertId` = `0` (primer alertId, índice 0-based)

---

### Paso 7 — Crear propuesta DAO para validar incidente

- **Cuenta activa:** Cuenta 2 (actor registrado)
- **Contrato:** `GovernanceDAO`
- **Función:** `createProposal`
- **Parámetros:**
  - `proposalType` = `1` (DisbursementAuthorization)
  - `description` = `"Autorizar desembolso para mitigacion La Isla"`
  - `votingDuration` = `60` (60 segundos)
- **Resultado esperado:** Evento `ProposalCreated` con `proposalId = 1`.

---

### Paso 8 — Votar la propuesta (3 actores)

- **Función:** `castVote` en `GovernanceDAO`
- **Parámetros para cada llamada:** `proposalId = 1`, `inFavor = true`
- **Repetir con cada cuenta:**

  | Cuenta activa | Acción                        |
  |---------------|-------------------------------|
  | Cuenta 2      | `castVote(1, true)`           |
  | Cuenta 3      | `castVote(1, true)`           |
  | Cuenta 4      | `castVote(1, true)`           |

- **Resultado esperado:** 3 eventos `VoteCast` con `inFavor = true`.

---

### Paso 9 — Finalizar propuesta

> ⏱️ Debes esperar al menos 60 segundos desde la creación de la propuesta, o avanzar el tiempo en la VM de Remix usando el campo "Block timestamp" en el panel de configuración.

- **Cuenta activa:** cualquiera (la función es pública)
- **Contrato:** `GovernanceDAO`
- **Función:** `finalizeProposal`
- **Parámetros:**
  - `proposalId` = `1`
- **Resultado esperado:** Evento `ProposalFinalized` con:
  - `result` = `1` (Approved)
  - `votesFor` = `3`
  - `votesAgainst` = `0`

---

### Paso 10 — Crear rubro de gasto

- **Cuenta activa:** Cuenta 1 (owner)
- **Contrato:** `FinancialTraceability`
- **Función:** `createBudgetItem`
- **Parámetros:**
  - `name` = `"Monitoreo"`
  - `description` = `"Equipos de monitoreo La Isla"`
  - `allocatedAmount` = `15000000`
- **Resultado esperado:** Evento `BudgetItemCreated` con `itemId = 1`.

---

### Paso 11 — Depositar fondos en el vault

Este paso requiere dos transacciones: primero aprobar el gasto, luego depositar.

**Transacción A — Aprobar gasto:**
- **Cuenta activa:** Cuenta 1 (owner)
- **Contrato:** `MockCOPToken`
- **Función:** `approve`
- **Parámetros:**
  - `spender` = `<dirección de FinancialTraceability>`
  - `amount` = `70000000`
- **Resultado esperado:** Evento `Approval` de ERC20.

**Transacción B — Depositar:**
- **Cuenta activa:** Cuenta 1 (owner)
- **Contrato:** `FinancialTraceability`
- **Función:** `deposit`
- **Parámetros:**
  - `amount` = `70000000`
- **Resultado esperado:** Evento `FundsDeposited` con `newVaultBalance = 70000000`.

---

### Paso 12 — Crear solicitud de desembolso

- **Cuenta activa:** Cuenta 1 (owner)
- **Contrato:** `FinancialTraceability`
- **Función:** `requestDisbursement`
- **Parámetros:**
  - `budgetItemId` = `1`
  - `amount` = `5000000`
  - `beneficiary` = `<dirección Cuenta 3>`
  - `justification` = `"Mitigacion incidente La Isla"`
  - `alertId` = `0`
  - `proposalId` = `1`
- **Resultado esperado:** Evento `DisbursementRequested` con `disbursementId = 1`.

---

### Paso 13 — Ejecutar desembolso

- **Cuenta activa:** Cuenta 1 (owner)
- **Contrato:** `FinancialTraceability`
- **Función:** `executeDisbursement`
- **Parámetros:**
  - `disbursementId` = `1`
- **Resultado esperado:** Evento `DisbursementExecuted` con:
  - `disbursementId` = `1`
  - `beneficiary` = `<dirección Cuenta 3>`
  - `amount` = `5000000`
  - `alertId` = `0`
  - `proposalId` = `1`
- La Cuenta 3 recibe 5,000,000 mCOP. El vault queda con 65,000,000 mCOP.

> El contrato verifica internamente dos condiciones antes de transferir:
> 1. `isAlertValid(0)` → `true` (alertId 0 existe porque `alertCount = 1`)
> 2. `isProposalApproved(1)` → `true` (propuesta finalizada con Approved)

---

### Paso 14 — Registrar intervención y emitir claim climático

Este paso registra la mejora ambiental post-intervención y emite el claim de impacto climático.

**14a — Registrar baseline en FinancialTraceability** *(opcional, para trazabilidad)*
- **Contrato:** `FinancialTraceability`
- **Función:** `registerBaseline` *(si está disponible en la implementación)*
- **Parámetros:** `stationId = "la-isla"`, `variable = "dissolvedOxygen"`, `value = 480`

**14b — Registrar baseline en SustainabilityClimate:**
- **Cuenta activa:** Cuenta 1 (owner)
- **Contrato:** `SustainabilityClimate`
- **Función:** `registerBaseline`
- **Parámetros:**
  - `stationId` = `"la-isla"`
  - `variable` = `"dissolvedOxygen"`
  - `value` = `480`
- **Resultado esperado:** Evento `BaselineRegistered`.

**14c — Registrar outcome post-intervención:**
- **Contrato:** `SustainabilityClimate`
- **Función:** `registerOutcome`
- **Parámetros:**
  - `stationId` = `"la-isla"`
  - `variable` = `"dissolvedOxygen"`
  - `value` = `620`
- **Resultado esperado:** Evento `OutcomeRegistered`.

**14d — Emitir claim climático:**
- **Contrato:** `SustainabilityClimate`
- **Función:** `emitClimateImpactClaim`
- **Parámetros:**
  - `stationId` = `"la-isla"`
  - `variable` = `"dissolvedOxygen"`
- **Resultado esperado:** Evento `ClimateImpactClaimCreated` con:
  - `baselineValue` = `480`
  - `outcomeValue` = `620`
  - `improvementPct` = `29`

> **Cálculo:** `((620 - 480) × 100) / 480 = 14000 / 480 = 29` (aritmética entera en Solidity)

---

## Cómo verificar eventos en Remix

Después de cada transacción, los eventos emitidos aparecen en la consola de Remix:

1. **Ejecuta la transacción** haciendo clic en el botón de la función en el panel "Deployed Contracts".
2. **Observa la consola** en la parte inferior de Remix. Aparecerá un bloque verde (transacción exitosa) o rojo (revert).
3. **Expande el resultado** haciendo clic en la flecha `▶` junto al hash de la transacción.
4. **Busca la sección `logs`** dentro del resultado expandido. Cada entrada corresponde a un evento emitido.
5. **Lee los parámetros decodificados:** Remix muestra el nombre del evento y cada parámetro con su valor. Los parámetros marcados como `indexed` en el contrato aparecen en el campo `topics`; los no-indexed aparecen en `data`.

**Ejemplo de salida en consola para `AlertTriggered`:**
```
logs: [
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
```

> Los parámetros `indexed` permiten filtrar eventos eficientemente en exploradores de bloques como Etherscan. En Remix VM, todos los eventos son visibles directamente en la consola sin necesidad de filtros.

---

## Nota de descargo final

Este prototipo fue desarrollado con fines exclusivamente educativos y de demostración técnica para el proyecto La Papaya — Río Cali.

- Los datos ambientales son **simulados** y no provienen de sensores reales.
- El token `mCOP` **no tiene valor económico** ni representa pesos colombianos reales.
- Los claims climáticos emitidos **no constituyen créditos de carbono** bajo ningún estándar de certificación (Verra VCS, Gold Standard, Plan Vivo, etc.).
- **No desplegar en mainnet** ni en ninguna red pública con fondos reales.
- El uso de `block.timestamp` para períodos de votación es adecuado para prototipo en VM local, pero no es seguro para producción.

Para una implementación en producción se requeriría: auditoría de seguridad, oráculos certificados, integración con sistemas de identidad, cumplimiento regulatorio ambiental colombiano, y certificación por un organismo acreditado. 
 
