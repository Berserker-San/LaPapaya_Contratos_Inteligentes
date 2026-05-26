# Smart contracts.pdf — Guía de lectura

**Fecha del documento:** 1 de abril de 2026  
**Origen:** Documento de trabajo del emprendedor / equipo La Papaya  
**Contexto:** Bootcamp Lanzatech — Proyecto "Río Cali Transparente"

---

## ¿Qué es este documento?

Es el documento base de diseño que el emprendedor entregó al equipo técnico. Contiene la visión completa del sistema blockchain para la recuperación del Río Cali, organizada en **4 objetivos de proyecto** trabajados por dos grupos, junto con el **código Solidity preliminar** de cada contrato.

No es código de producción — es el punto de partida conceptual desde el cual se construyó el prototipo que está en la carpeta `contracts/` de este repositorio.

---

## Estructura del documento

### Objetivos del proyecto (4 en total)

| # | Nombre | Grupo | Símbolo |
|---|--------|-------|---------|
| 1 | Monitoreo y denuncias ambientales | Grupo 1 | ☼ $ |
| 2 | Articulación y control de recursos financieros | Grupo 1 | $ |
| 3 | Gobernanza colaborativa mediante DAO | Grupo 2 | ☺ $ |
| 4 | Reducción de CO₂ y generación de bonos de carbono | Grupo 2 | ☺ |

---

## Los contratos del documento

### Contrato 1 — `RioCaliPOMCA`
**Objetivo:** 1 y 2 (monitoreo + trazabilidad financiera)

Un contrato monolítico que integra todo en un solo archivo. Organizado en tres bloques conceptuales marcados con colores:

- **Azul — Objetivos del contrato:** array de strings con los objetivos del POMCA (Plan de Ordenación y Manejo de Cuencas).
- **Rojo — Variables cualitativas:** struct `BasinActionPlan` con diagnóstico de cuenca, plan de acción, participación comunitaria, modelo de gobernanza, etc. También incluye `FundingRecord` para registrar contratos de obra con origen de fondos, contratista, interventores, % de avance y ROI ambiental.
- **Verde — Variables cuantitativas:** puntos de monitoreo (`MonitoringPoint`) y mediciones de agua (`WaterMeasurement`) con variables ICA_IDEAM, OD, pH, DQO, conductividad y SST.
- **DAO y denuncias:** propuestas, votación y registro de denuncias ambientales.
- **CO₂ y bonos de carbono:** registro de reducciones de CO₂ con metodología y evidencia.

```
Variables de agua monitoreadas:
- ICA_IDEAM (índice de calidad)
- OD — Oxígeno disuelto (%)
- pH × 100
- DQO (mg/L)
- CE — Conductividad eléctrica (µS/cm)
- SST — Sólidos suspendidos totales (mg/L)
```

---

### Contrato 2 — `RioCali2050DAO`
**Objetivo:** 3 (gobernanza colaborativa)

DAO comunitaria con foco en el barrio La Isla. Características principales:

- **Roles:** `admin` y `laPapaya` (ONG operadora).
- **Membresía y tokens de participación:** cada miembro verificado recibe tokens de gobernanza. Los recicladores ganan tokens por kg de material recuperado.
- **Tesorería en ETH:** el contrato recibe ETH directamente (`receive()`). Los fondos solo se liberan si una propuesta es aprobada.
- **Votación ponderada por tokens:** el peso del voto es proporcional al saldo de tokens del votante.
- **Quórum mínimo del 51%:** una propuesta no se puede ejecutar si no alcanza quórum.
- **Programa de reciclaje:** La Papaya registra kg reciclados → se emiten tokens de incentivo automáticamente (`factorIncentivo = 10 tokens/kg`).

---

### Contrato 3 — `RioCali2050ClimateDAO`
**Objetivo:** 4 (CO₂ y bonos de carbono)

Es la versión más completa. Extiende `RioCali2050DAO` agregando el módulo climático:

- **Roles adicionales:** `climateAdmin` (registra CO₂e) y `esOraculoAmbiental` (La Papaya, estudiantes de Maestría, aliados técnicos).
- **Indicadores ambientales:** registro on-chain de variables de agua, suelo, movilidad y residuos con sus umbrales de referencia.
- **Umbrales configurables:** tabla de valores buenos/malos para DBO, DQO, SST, turbidez, conductividad, OD, pH, temperatura, nitrógeno, fósforo, índice biótico, cobertura vegetal, kg reciclados, etc.
- **Registro de CO₂e:** el `climateAdmin` registra reducciones de CO₂ equivalente calculadas off-chain con metodología IPCC.
- **Token RCC (RioCaliCarbon):** `1 RCC = 1 kg CO₂e reducido`. Se emite automáticamente al registrar CO₂e. Beneficiarios: recicladores, residentes de La Isla, proyectos comunitarios.

```
Factores de conversión CO₂e usados:
- Plástico reciclado: 1.5–3 kg CO₂e/kg
- Metal reciclado: 4–10 kg CO₂e/kg
- Árbol adulto: 20–30 kg CO₂e/año
- Coche evitado: 0.25 kg CO₂e/km
```

---

## Relación con los contratos del repositorio (`contracts/`)

El documento PDF es el **antecedente conceptual** del prototipo. Los contratos en `contracts/` son una **refactorización más robusta y modular** de las mismas ideas. Esta tabla muestra la correspondencia:

| Contrato en el PDF | Contrato en `contracts/` | Qué mejoró |
|---|---|---|
| `RioCaliPOMCA` (bloque verde) | `EnvironmentalMonitoring.sol` | Separado en contrato propio. Agrega roles con AccessControl, umbrales por estación, alertas automáticas con ID, y hash de evidencia IPFS. |
| `RioCaliPOMCA` (bloque rojo/financiero) | `FinancialTraceability.sol` | Separado en contrato propio. Agrega vault ERC20 (mCOP), doble condición alerta+DAO para desembolsar, y protección ReentrancyGuard. |
| `RioCali2050DAO` / `RioCali2050ClimateDAO` (gobernanza) | `GovernanceDAO.sol` | Tipos de actor más granulares (Autoridad, Comunidad, Academia, SectorPrivado). Votación simple (1 actor = 1 voto) en lugar de ponderada por tokens. Finalización explícita de propuestas. |
| `RioCali2050ClimateDAO` (módulo climático) | `SustainabilityClimate.sol` | Separado en contrato propio. Foco en baseline vs. outcome con cálculo de % de mejora on-chain. |
| Token implícito en `RioCali2050ClimateDAO` (RCC) | `MockCOPToken.sol` | En el prototipo se usa un token ERC20 estándar (mCOP) para simular fondos. El token RCC climático es una extensión futura. |

### Diferencias de diseño clave

**PDF → contratos del repositorio:**

1. **Monolítico → modular.** El PDF tiene 1–2 contratos grandes. El repositorio los separa en 5 contratos especializados con interfaces (`IGovernanceDAO`, `IEnvironmentalMonitoring`) para que se comuniquen entre sí.

2. **ETH nativo → token ERC20.** El PDF usa ETH directamente en la tesorería. El repositorio usa `MockCOPToken` (mCOP) para simular pesos colombianos, lo que es más representativo del caso de uso real.

3. **Votación ponderada → votación simple.** El PDF pondera votos por saldo de tokens. El repositorio usa 1 actor = 1 voto, más adecuado para gobernanza institucional (autoridades, academia, comunidad).

4. **Quórum 51% → mayoría simple.** El repositorio simplifica la condición de aprobación para el prototipo educativo.

5. **CO₂e off-chain → claim on-chain verificable.** El PDF registra el CO₂e calculado externamente. El repositorio agrega el cálculo del porcentaje de mejora directamente en el contrato `SustainabilityClimate`.

---

## Actores del sistema (según el documento)

| Actor | Rol en el sistema |
|---|---|
| **ONG La Papaya** | Operador territorial principal. Registra reciclaje, valida acciones comunitarias, es oráculo ambiental por defecto. |
| **Barrio La Isla** | Comunidad ribereña prioritaria. Participación en DAO, cuotas mínimas de tokens. |
| **Recicladores locales** | Ganan tokens RCC por kg de material recuperado. |
| **Universidad Icesi / Maestría en Sostenibilidad** | Oráculos técnicos. Registran indicadores ambientales validados. |
| **CVC / Alcaldía / EMCALI** | Instituciones públicas. Autoridades ambientales. |
| **Sector privado** | Financiamiento y tecnología. |
| **climateAdmin** | Rol técnico que registra CO₂e calculado con metodología IPCC. |

---

## Estimaciones financieras del documento

El documento incluye supuestos de financiamiento para el proyecto real:

- Empresas privadas: **1.000 millones COP**
- Fondos de cooperación internacional: **1.000 millones COP**
- Contribuciones ciudadanas: **500 millones COP**
- Venta de bonos de carbono (mercado no regulado): **~3 millones USD/año** (600.000 ton CO₂ estimadas en toda la ruta)
- Venta de bonos de carbono (mercado certificado): **~12 millones USD/año**

> ⚠️ Estas cifras son proyecciones del emprendedor para el caso real. El prototipo en este repositorio usa `mCOP` ficticio y no representa dinero real.

---

## Hoja de ruta del proyecto (según el documento)

| Fase | Duración | Actividades clave |
|---|---|---|
| **Fase 1** — Diseño social y legal | 0–6 meses | Talleres con comunidad La Isla, Icesi, La Papaya. Estatutos y arquitectura de tokens. |
| **Fase 2** — MVP de la DAO | 6–12 meses | Despliegue DAO, emisión piloto de tokens, primeras campañas de reciclaje, 2–3 proyectos iniciales. |
| **Fase 3** — Escalamiento | 12–36 meses | Más barrios y actores, sensores reales, oráculos, token ambiental conectado a resultados. |

---

## Nota sobre el código en el PDF

El código Solidity del PDF tiene algunas diferencias respecto al repositorio:

- Usa `pragma solidity ^0.8.20` (el repositorio usa `^0.8.24`).
- El contrato `RioCali2050ClimateDAO` tiene un error tipográfico en la línea `mapping(uint256 => RegistroCO2> public registrosCO2;` (el `>` debería ser `)`). No compilaría tal cual.
- No usa OpenZeppelin — implementa control de acceso manualmente con `modifier`. El repositorio usa `AccessControl`, `Ownable` y `ReentrancyGuard` de OpenZeppelin v5 para mayor seguridad.
- No tiene interfaces separadas. El repositorio define `IGovernanceDAO` e `IEnvironmentalMonitoring` para desacoplar los contratos.

El código del PDF es un **borrador conceptual válido** para entender la lógica del negocio. Los contratos del repositorio son la versión lista para demostrar en Remix IDE.
