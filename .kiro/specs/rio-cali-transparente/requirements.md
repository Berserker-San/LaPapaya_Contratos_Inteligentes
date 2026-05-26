# Requirements Document

## Introduction

"Río Cali Transparente" es un prototipo funcional de gobernanza ambiental basada en blockchain para el Río Cali, desarrollado como parte del proyecto La Papaya. El sistema simula el ciclo completo de monitoreo ambiental, gobernanza participativa, trazabilidad financiera y reporte de impacto climático mediante 5 contratos Solidity desplegables en Remix IDE con VM local.

El prototipo NO utiliza datos reales, sensores reales, oráculos externos, ni fondos reales. Su propósito es demostrar la viabilidad técnica y la trazabilidad de decisiones ambientales y financieras sobre una cadena de bloques pública.

## Glossary

- **System**: El conjunto de contratos Solidity que conforman el prototipo "Río Cali Transparente".
- **MockCOPToken**: Contrato ERC20 que simula pesos colombianos ficticios (COP) para pruebas.
- **EnvironmentalMonitoring**: Contrato que gestiona estaciones de monitoreo y lecturas de sensores IoT simulados.
- **GovernanceDAO**: Contrato de gobernanza participativa con múltiples tipos de actores y propuestas.
- **FinancialTraceability**: Contrato vault que gestiona fondos COP simulados y controla desembolsos condicionados.
- **SustainabilityClimate**: Contrato que conecta resultados ambientales con indicadores de sostenibilidad y emite claims climáticos.
- **IEnvironmentalMonitoring**: Interfaz Solidity que define el contrato público de EnvironmentalMonitoring.
- **IGovernanceDAO**: Interfaz Solidity que define el contrato público de GovernanceDAO.
- **Sensor_Oracle**: Rol de control de acceso (AccessControl de OpenZeppelin) que autoriza el envío de lecturas de sensores.
- **Admin**: Rol de administrador con permisos de configuración en todos los contratos.
- **Autoridad**: Actor de gobernanza que representa entidades reguladoras ambientales.
- **Comunidad**: Actor de gobernanza que representa organizaciones comunitarias locales.
- **Academia**: Actor de gobernanza que representa instituciones académicas o científicas.
- **Sector_Privado**: Actor de gobernanza que representa empresas o entidades privadas.
- **Propuesta**: Solicitud formal de decisión registrada en GovernanceDAO.
- **Desembolso**: Transferencia de tokens MockCOPToken desde el vault de FinancialTraceability.
- **Evento_Ambiental**: Alerta generada por EnvironmentalMonitoring cuando una lectura supera umbrales definidos.
- **Claim_Climático**: Registro de mejora ambiental emitido por SustainabilityClimate.
- **Lectura_Escalada**: Valor entero que representa un número decimal multiplicado por 100 (ej: pH 7.25 → 725).
- **Umbral**: Valor límite de una variable ambiental que, al superarse, activa una alerta.
- **Rubro**: Categoría de gasto dentro del presupuesto de FinancialTraceability.
- **Línea_Base**: Conjunto de indicadores ambientales medidos antes de una intervención.
- **Remix_IDE**: Entorno de desarrollo integrado en navegador para Solidity, usado con VM local.
- **OpenZeppelin**: Biblioteca de contratos Solidity auditados (AccessControl, Ownable, ReentrancyGuard, ERC20).

---

## Requirements

### Requirement 1: Despliegue e inicialización del sistema

**User Story:** Como administrador del prototipo, quiero desplegar todos los contratos en Remix IDE con VM local, para que el sistema quede operativo con datos simulados listos para pruebas.

#### Acceptance Criteria

1. THE System SHALL compilar sin errores con el compilador Solidity versión `^0.8.24` en Remix IDE.
2. THE MockCOPToken SHALL desplegarse con un suministro inicial configurable de tokens COP simulados asignados al deployer.
3. THE EnvironmentalMonitoring SHALL desplegarse con la dirección del deployer como Admin y sin estaciones registradas.
4. THE GovernanceDAO SHALL desplegarse con la dirección del deployer como Admin y sin propuestas activas.
5. THE FinancialTraceability SHALL desplegarse recibiendo la dirección de MockCOPToken y la dirección de GovernanceDAO como parámetros del constructor.
6. THE SustainabilityClimate SHALL desplegarse recibiendo la dirección de EnvironmentalMonitoring como parámetro del constructor.
7. WHEN todos los contratos son desplegados, THE System SHALL permitir que el Admin configure las referencias cruzadas entre contratos mediante funciones de inicialización.

---

### Requirement 2: Token ERC20 simulado (MockCOPToken)

**User Story:** Como participante del prototipo, quiero un token ERC20 que represente pesos colombianos ficticios, para que las transacciones financieras simuladas sean trazables en la blockchain.

#### Acceptance Criteria

1. THE MockCOPToken SHALL implementar el estándar ERC20 de OpenZeppelin con nombre "Colombian Peso Mock" y símbolo "mCOP".
2. THE MockCOPToken SHALL permitir al Admin acuñar (mint) tokens adicionales hacia cualquier dirección.
3. WHEN el Admin llama a la función de mint, THE MockCOPToken SHALL emitir el evento estándar `Transfer` de ERC20 con la dirección cero como origen.
4. THE MockCOPToken SHALL permitir a cualquier titular de tokens aprobar (approve) y transferir (transfer) tokens según el estándar ERC20.
5. IF una transferencia excede el saldo disponible del remitente, THEN THE MockCOPToken SHALL revertir la transacción con un mensaje de error descriptivo.

---

### Requirement 3: Registro y gestión de estaciones de monitoreo

**User Story:** Como administrador ambiental, quiero registrar estaciones de monitoreo en el Río Cali, para que el sistema pueda asociar lecturas de sensores a ubicaciones geográficas específicas.

#### Acceptance Criteria

1. WHEN el Admin llama a la función de registro de estación con un identificador único y metadatos de ubicación, THE EnvironmentalMonitoring SHALL registrar la estación y emitir un evento `StationRegistered`.
2. IF se intenta registrar una estación con un identificador ya existente, THEN THE EnvironmentalMonitoring SHALL revertir la transacción con un mensaje de error descriptivo.
3. THE EnvironmentalMonitoring SHALL permitir al Admin configurar umbrales (mínimo y máximo) para cada variable ambiental (pH, oxígeno disuelto, temperatura, conductividad, turbidez) por estación.
4. WHEN los umbrales son configurados, THE EnvironmentalMonitoring SHALL emitir un evento `ThresholdsUpdated` con el identificador de estación y los nuevos valores.
5. THE EnvironmentalMonitoring SHALL exponer una función de consulta que retorne los datos de una estación dado su identificador.

---

### Requirement 4: Recepción y validación de lecturas de sensores IoT simulados

**User Story:** Como oráculo de sensores simulado, quiero enviar lecturas de variables ambientales al contrato, para que el sistema registre y valide los datos en la blockchain.

#### Acceptance Criteria

1. WHEN una dirección con rol Sensor_Oracle llama a la función de registro de lectura con identificador de estación, timestamp y valores escalados de pH, oxígeno disuelto, temperatura, conductividad y turbidez, THE EnvironmentalMonitoring SHALL almacenar la lectura y emitir un evento `ReadingRecorded`.
2. IF una dirección sin rol Sensor_Oracle intenta registrar una lectura, THEN THE EnvironmentalMonitoring SHALL revertir la transacción con un mensaje de error de acceso denegado.
3. IF una estación no está registrada y se intenta enviar una lectura, THEN THE EnvironmentalMonitoring SHALL revertir la transacción con un mensaje de error descriptivo.
4. THE EnvironmentalMonitoring SHALL representar todos los valores de variables ambientales como enteros escalados por 100 (Lectura_Escalada), donde el valor 725 representa 7.25.
5. WHEN una lectura es almacenada, THE EnvironmentalMonitoring SHALL comparar cada variable contra los umbrales configurados para esa estación.
6. WHEN al menos una variable de una lectura supera su umbral configurado, THE EnvironmentalMonitoring SHALL emitir un evento `AlertTriggered` con el identificador de estación, la variable afectada y el valor registrado.

---

### Requirement 5: Gobernanza participativa con múltiples actores (GovernanceDAO)

**User Story:** Como actor de gobernanza (Autoridad, Comunidad, Academia o Sector Privado), quiero crear y votar propuestas, para que las decisiones sobre el Río Cali sean tomadas de forma transparente y participativa.

#### Acceptance Criteria

1. THE GovernanceDAO SHALL soportar cuatro tipos de actores: Autoridad, Comunidad, Academia y Sector_Privado, gestionados mediante roles de AccessControl de OpenZeppelin.
2. WHEN el Admin registra una dirección con un tipo de actor, THE GovernanceDAO SHALL asignar el rol correspondiente y emitir un evento `ActorRegistered`.
3. THE GovernanceDAO SHALL soportar cuatro tipos de propuesta: validación técnica de incidente, autorización de desembolso, priorización de proyectos y decisión estratégica.
4. WHEN un actor registrado crea una propuesta con tipo, descripción y duración de votación, THE GovernanceDAO SHALL registrar la propuesta con estado "Activa" y emitir un evento `ProposalCreated` con un identificador único.
5. WHILE una propuesta está en estado "Activa" y dentro del período de votación, THE GovernanceDAO SHALL permitir a cada actor registrado emitir exactamente un voto (a favor o en contra).
6. IF un actor intenta votar más de una vez en la misma propuesta, THEN THE GovernanceDAO SHALL revertir la transacción con un mensaje de error descriptivo.
7. WHEN el período de votación de una propuesta expira, THE GovernanceDAO SHALL permitir llamar a una función de finalización que calcule el resultado y actualice el estado a "Aprobada" o "Rechazada".
8. WHEN una propuesta es finalizada, THE GovernanceDAO SHALL emitir un evento `ProposalFinalized` con el identificador, el resultado y el conteo de votos a favor y en contra.
9. THE GovernanceDAO SHALL exponer una función de consulta que retorne el estado y resultado de una propuesta dado su identificador.

---

### Requirement 6: Trazabilidad financiera con desembolsos condicionados (FinancialTraceability)

**User Story:** Como aportante o administrador financiero, quiero que los fondos COP simulados sean gestionados con trazabilidad completa y que los desembolsos solo ocurran cuando se cumplan condiciones ambientales y de gobernanza, para garantizar la transparencia del uso de recursos.

#### Acceptance Criteria

1. THE FinancialTraceability SHALL gestionar un presupuesto total de 70.000.000 unidades de MockCOPToken distribuido en rubros de gasto configurables por el Admin.
2. WHEN el Admin configura un rubro con nombre, descripción y monto asignado, THE FinancialTraceability SHALL registrar el rubro y emitir un evento `BudgetItemCreated`.
3. WHEN un aportante simulado transfiere MockCOPToken al vault mediante la función de depósito, THE FinancialTraceability SHALL registrar el aporte y emitir un evento `FundsDeposited` con la dirección del aportante y el monto.
4. WHEN un actor autorizado crea una solicitud de desembolso con rubro, monto, beneficiario y justificación, THE FinancialTraceability SHALL registrar la solicitud con estado "Pendiente" y emitir un evento `DisbursementRequested`.
5. THE FinancialTraceability SHALL bloquear la ejecución de cualquier desembolso hasta que se cumplan simultáneamente dos condiciones: (A) existe un Evento_Ambiental validado asociado al rubro, y (B) una propuesta de tipo "autorización de desembolso" en GovernanceDAO ha sido aprobada para esa solicitud.
6. WHEN ambas condiciones de desembolso se cumplen y un actor autorizado ejecuta el desembolso, THE FinancialTraceability SHALL transferir los tokens MockCOPToken al beneficiario y emitir un evento `DisbursementExecuted` con el monto, beneficiario e identificadores de condición.
7. IF el vault no tiene saldo suficiente de MockCOPToken para cubrir un desembolso, THEN THE FinancialTraceability SHALL revertir la transacción con un mensaje de error descriptivo.
8. IF se intenta ejecutar un desembolso sin que ambas condiciones estén cumplidas, THEN THE FinancialTraceability SHALL revertir la transacción con un mensaje de error descriptivo.
9. THE FinancialTraceability SHALL implementar ReentrancyGuard de OpenZeppelin en todas las funciones que transfieran tokens.
10. THE FinancialTraceability SHALL exponer una función de consulta que retorne el saldo actual del vault y el estado de cada solicitud de desembolso.

---

### Requirement 7: Indicadores de sostenibilidad y claims climáticos (SustainabilityClimate)

**User Story:** Como investigador o reportero de impacto, quiero que el sistema calcule mejoras ambientales y emita claims climáticos verificables, para que los resultados de las intervenciones en el Río Cali sean trazables y auditables.

#### Acceptance Criteria

1. WHEN el Admin registra una Línea_Base con identificador de estación, variable ambiental y valor de referencia escalado, THE SustainabilityClimate SHALL almacenar la línea base y emitir un evento `BaselineRegistered`.
2. WHEN el Admin registra un resultado post-intervención con identificador de estación, variable ambiental y valor escalado, THE SustainabilityClimate SHALL almacenar el resultado y emitir un evento `OutcomeRegistered`.
3. WHEN tanto la Línea_Base como el resultado post-intervención están registrados para una estación y variable, THE SustainabilityClimate SHALL calcular el porcentaje de mejora como `((resultado - línea_base) * 100) / línea_base` usando aritmética entera.
4. WHEN el Admin solicita la emisión de un Claim_Climático para una estación y variable con mejora calculada, THE SustainabilityClimate SHALL emitir un evento `ClimateImpactClaimCreated` con identificador de estación, variable, valor de línea base, valor de resultado y porcentaje de mejora calculado.
5. IF se intenta emitir un Claim_Climático sin que existan tanto la Línea_Base como el resultado post-intervención registrados, THEN THE SustainabilityClimate SHALL revertir la transacción con un mensaje de error descriptivo.
6. THE SustainabilityClimate SHALL exponer una función de consulta que retorne la Línea_Base, el resultado y el porcentaje de mejora calculado para una estación y variable dados.

---

### Requirement 8: Interfaces Solidity para interoperabilidad

**User Story:** Como desarrollador del prototipo, quiero interfaces Solidity bien definidas para EnvironmentalMonitoring y GovernanceDAO, para que FinancialTraceability y SustainabilityClimate puedan interactuar con ellos de forma desacoplada y extensible.

#### Acceptance Criteria

1. THE IEnvironmentalMonitoring SHALL declarar las firmas de todas las funciones públicas de EnvironmentalMonitoring que sean consumidas por otros contratos del sistema.
2. THE IGovernanceDAO SHALL declarar las firmas de todas las funciones públicas de GovernanceDAO que sean consumidas por otros contratos del sistema.
3. THE FinancialTraceability SHALL referenciar GovernanceDAO exclusivamente a través de IGovernanceDAO.
4. THE SustainabilityClimate SHALL referenciar EnvironmentalMonitoring exclusivamente a través de IEnvironmentalMonitoring.
5. THE System SHALL compilar correctamente cuando IEnvironmentalMonitoring e IGovernanceDAO son las únicas referencias entre contratos dependientes.

---

### Requirement 9: Trazabilidad mediante eventos en todos los contratos

**User Story:** Como auditor o desarrollador, quiero que todas las acciones relevantes del sistema emitan eventos Solidity, para que el historial completo de operaciones sea consultable desde el log de transacciones de Remix IDE.

#### Acceptance Criteria

1. THE System SHALL emitir eventos Solidity para cada acción de estado relevante en todos los contratos: registro, actualización, votación, desembolso, alerta y claim.
2. THE System SHALL incluir en cada evento los parámetros mínimos necesarios para identificar unívocamente la acción: identificadores, direcciones involucradas, valores y timestamps cuando aplique.
3. THE System SHALL declarar todos los eventos con al menos un parámetro `indexed` para facilitar el filtrado en el log de Remix IDE.

---

### Requirement 10: Seguridad y control de acceso

**User Story:** Como administrador del prototipo, quiero que todas las funciones sensibles estén protegidas por roles de AccessControl, para que solo los actores autorizados puedan ejecutar operaciones críticas.

#### Acceptance Criteria

1. THE System SHALL usar AccessControl de OpenZeppelin para gestionar roles en EnvironmentalMonitoring y GovernanceDAO.
2. THE MockCOPToken SHALL usar Ownable de OpenZeppelin para restringir la función de mint al propietario del contrato.
3. THE FinancialTraceability SHALL usar ReentrancyGuard de OpenZeppelin en todas las funciones que ejecuten transferencias de tokens.
4. IF una dirección sin el rol requerido intenta ejecutar una función protegida en cualquier contrato del System, THEN THE System SHALL revertir la transacción con el mensaje de error estándar de AccessControl de OpenZeppelin.
5. THE System SHALL definir constantes `bytes32` para cada rol (ej: `SENSOR_ORACLE_ROLE`, `ADMIN_ROLE`) en los contratos que los utilicen.
