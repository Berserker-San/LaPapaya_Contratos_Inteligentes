# Historia de Usuario — Integración de Papayos en Blockchain

**Proyecto:** La Papaya — Río Cali Transparente  
**Fecha:** Mayo 2026  
**Contexto:** La plataforma ya cuenta con 600 usuarios registrados, cada uno con un perfil que incluye saldo de **papayos** (moneda interna), divididos en dos categorías: papayos negros (residuos no aprovechables) y papayos blancos (residuos aprovechables).

---

## Historia de Usuario

### HU-01 — Registro de papayos en blockchain

| Campo | Descripción |
|---|---|
| **Usuario** | Reciclador o residente registrado en la plataforma de La Papaya |
| **Necesidad** | Quiero que mis papayos queden registrados de forma transparente e inmutable, para que nadie pueda modificar mi saldo sin mi conocimiento y pueda demostrar mi contribución ambiental |
| **Funcionalidad** | Un contrato inteligente que represente los papayos como tokens on-chain, diferenciando entre papayos negros y blancos, vinculado al perfil existente del usuario en la plataforma |

**Criterios de aceptación:**
- El usuario puede consultar su saldo de papayos negros y blancos en cualquier momento desde la blockchain.
- Solo actores autorizados (La Papaya como operador) pueden acreditar papayos a un usuario.
- Cada acreditación queda registrada con timestamp, tipo de residuo y cantidad.
- El saldo es visible públicamente pero solo modificable por el operador autorizado.

---

### HU-02 — Acreditación de papayos por entrega de residuos

| Campo | Descripción |
|---|---|
| **Usuario** | Reciclador del barrio La Isla que entrega material en un punto de recolección |
| **Necesidad** | Quiero recibir papayos automáticamente cuando entrego residuos, sin depender de que alguien lo registre manualmente en una planilla que podría perderse o alterarse |
| **Funcionalidad** | Cuando La Papaya registra una entrega de residuos (kg de material aprovechable o no aprovechable), el contrato acredita automáticamente los papayos correspondientes al perfil del reciclador |

**Criterios de aceptación:**
- La Papaya registra: dirección del reciclador, kg entregados, tipo de residuo (aprovechable / no aprovechable).
- El contrato calcula y acredita papayos blancos si el residuo es aprovechable, papayos negros si no lo es.
- Se emite un evento on-chain con todos los datos de la transacción.
- El reciclador puede ver el historial completo de sus entregas.

---

### HU-03 — Uso de papayos como incentivo o canje

| Campo | Descripción |
|---|---|
| **Usuario** | Residente con saldo acumulado de papayos |
| **Necesidad** | Quiero poder usar mis papayos para acceder a beneficios (vales de comida, kits ambientales, capacitaciones), de forma que el canje quede registrado y no pueda usarse dos veces |
| **Funcionalidad** | Un mecanismo de canje en el contrato que descuenta papayos del saldo del usuario y registra el beneficio obtenido, evitando doble gasto |

**Criterios de aceptación:**
- El usuario solo puede canjear si tiene saldo suficiente.
- El canje descuenta el saldo y registra: tipo de beneficio, cantidad de papayos usados, fecha.
- No es posible canjear el mismo saldo dos veces.
- La Papaya puede consultar el historial de canjes para logística.

---

## Historia de Test

### HT-01 — Verificación de acreditación correcta de papayos

**Objetivo:** Confirmar que el contrato acredita el tipo correcto de papayos según el residuo entregado.

**Precondiciones:**
- Contrato desplegado en Remix VM.
- Usuario registrado con saldo inicial en cero.
- La Papaya tiene el rol de operador autorizado.

**Casos de prueba:**

| ID | Acción | Datos de entrada | Resultado esperado |
|---|---|---|---|
| T-01 | Registrar entrega de residuo aprovechable | reciclador: Cuenta 2, kg: 10, tipo: blanco | Saldo papayos blancos de Cuenta 2 = 10 (o factor × 10). Evento `PapayosAcreditados` emitido. |
| T-02 | Registrar entrega de residuo no aprovechable | reciclador: Cuenta 2, kg: 5, tipo: negro | Saldo papayos negros de Cuenta 2 = 5 (o factor × 5). Evento `PapayosAcreditados` emitido. |
| T-03 | Intentar acreditar desde cuenta no autorizada | Cuenta 3 (sin rol operador) llama a `acreditarPapayos` | Transacción revertida con mensaje "Solo operador autorizado". |
| T-04 | Registrar entrega con kg = 0 | kg: 0 | Transacción revertida con mensaje "Cantidad invalida". |
| T-05 | Consultar saldo después de múltiples entregas | 3 entregas blancas de 10 kg cada una | Saldo papayos blancos = 30 (o 30 × factor). |

**Cómo ejecutar en Remix:**
1. Desplegar el contrato con Cuenta 1 (admin / La Papaya).
2. Registrar Cuenta 2 como usuario.
3. Ejecutar cada caso con los parámetros indicados.
4. Verificar en la consola de Remix que los eventos emitidos coinciden con el resultado esperado.
5. Llamar a `saldoPapayos(Cuenta2)` y confirmar los valores.

---

### HT-02 — Verificación de canje sin doble gasto

**Objetivo:** Confirmar que un usuario no puede canjear más papayos de los que tiene.

| ID | Acción | Datos de entrada | Resultado esperado |
|---|---|---|---|
| T-06 | Canjear con saldo suficiente | usuario: Cuenta 2, papayos: 5, beneficio: "vale_comida" | Saldo se reduce en 5. Evento `PapayosCanjeados` emitido. |
| T-07 | Canjear con saldo insuficiente | usuario: Cuenta 2, papayos: 1000 (más del saldo) | Transacción revertida con "Saldo insuficiente". |
| T-08 | Canjear exactamente el saldo disponible | usuario: Cuenta 2, papayos: saldo exacto | Saldo queda en 0. Transacción exitosa. |
| T-09 | Intentar canjear con saldo en 0 | usuario: Cuenta 2, papayos: 1 | Transacción revertida con "Saldo insuficiente". |

---

### HT-03 — Verificación de trazabilidad del historial

**Objetivo:** Confirmar que cada acreditación y canje queda registrado con todos sus datos.

| ID | Acción | Resultado esperado |
|---|---|---|
| T-10 | Consultar historial de entregas de Cuenta 2 | Lista con timestamp, kg, tipo de residuo y papayos acreditados por cada entrega. |
| T-11 | Consultar historial de canjes de Cuenta 2 | Lista con timestamp, tipo de beneficio y papayos descontados. |
| T-12 | Verificar que los eventos en Remix coinciden con el historial | Los `logs` en la consola de Remix muestran exactamente los mismos datos que las funciones de consulta. |

---

## Historia de Validación

### HV-01 — Validación con usuarios reales de la plataforma

**Objetivo:** Confirmar que la lógica del contrato refleja fielmente el comportamiento esperado por los 600 usuarios actuales de la plataforma.

**Escenario de validación:**

> Un reciclador del barrio La Isla lleva 3 meses usando la plataforma web de La Papaya. Tiene acumulados 120 papayos blancos y 40 papayos negros. Quiere canjear 50 papayos blancos por un kit ambiental.

**Pasos de validación:**

1. **Migración de saldo existente**
   - La Papaya (operador) acredita on-chain el saldo histórico del usuario: 120 papayos blancos + 40 papayos negros.
   - Se verifica que `saldoPapayosBlanco(usuario) == 120` y `saldoPapayosNegro(usuario) == 40`.
   - Criterio: los saldos coinciden exactamente con los registros de la plataforma web actual.

2. **Canje de papayos blancos**
   - El usuario solicita canjear 50 papayos blancos por "kit_ambiental".
   - La Papaya ejecuta el canje en el contrato.
   - Se verifica que `saldoPapayosBlanco(usuario) == 70` y el evento `PapayosCanjeados` fue emitido.
   - Criterio: el saldo se reduce correctamente y el canje queda registrado.

3. **Intento de doble canje**
   - Se intenta ejecutar el mismo canje nuevamente.
   - Criterio: la transacción revierte. El saldo no cambia.

4. **Auditoría pública**
   - Cualquier persona (sin rol especial) puede consultar el historial de entregas y canjes del usuario.
   - Criterio: la información es pública, transparente y no puede ser alterada retroactivamente.

---

### HV-02 — Validación de consistencia entre plataforma web y blockchain

**Objetivo:** Garantizar que los papayos on-chain y los papayos en la plataforma web siempre estén sincronizados.

| Criterio | Cómo validar | Resultado esperado |
|---|---|---|
| Saldo on-chain = saldo en plataforma web | Comparar `saldoPapayos()` del contrato con el perfil del usuario en la app | Valores idénticos para los 600 usuarios |
| Cada acreditación tiene su evento on-chain | Revisar logs del contrato para cada registro de entrega | 1 evento `PapayosAcreditados` por cada entrega registrada |
| No existen acreditaciones sin respaldo físico | Cruzar registros on-chain con planillas de recolección de La Papaya | Cero discrepancias |
| Los canjes no superan el saldo disponible | Revisar historial de canjes vs. historial de acreditaciones | Saldo nunca negativo en ningún usuario |

---

### HV-03 — Validación de roles y permisos

**Objetivo:** Confirmar que solo los actores correctos pueden modificar saldos.

| Intento | Actor | Resultado esperado |
|---|---|---|
| Acreditar papayos | La Papaya (operador autorizado) | ✅ Exitoso |
| Acreditar papayos | Usuario común (sin rol) | ❌ Revertido |
| Acreditar papayos | Admin del contrato (sin rol operador) | ❌ Revertido (si el diseño lo separa) |
| Canjear papayos | La Papaya en nombre del usuario | ✅ Exitoso |
| Modificar factor de incentivo | Solo admin | ✅ Exitoso |
| Modificar factor de incentivo | La Papaya sin rol admin | ❌ Revertido |

---

## Relación con los contratos existentes del repositorio

Esta historia de usuario extiende la lógica ya implementada en el repositorio. La correspondencia es:

| Elemento de la HU | Contrato relacionado | Qué agregar o adaptar |
|---|---|---|
| Token papayos (blanco/negro) | `MockCOPToken.sol` | Crear un nuevo contrato `PapayoToken.sol` con dos balances por usuario (blanco y negro), o dos instancias del token ERC20. |
| Acreditación por entrega de residuos | `FinancialTraceability.sol` → `registrarReciclaje` del PDF | Agregar función `acreditarPapayos(usuario, kg, tipo)` restringida al operador La Papaya. |
| Historial de entregas | `EnvironmentalMonitoring.sol` → `recordReading` | El registro de entregas puede vincularse a una lectura ambiental (evidencia de la acción). |
| Canje de papayos | Nuevo módulo | Función `canjearPapayos(usuario, cantidad, tipoBeneficio)` con validación de saldo. |
| Gobernanza sobre reglas de canje | `GovernanceDAO.sol` | Las reglas del programa de incentivos (factor de conversión, tipos de beneficio) pueden votarse en el DAO. |

---

## Próximos pasos sugeridos

1. **Definir el factor de conversión:** ¿cuántos papayos se acreditan por kg de residuo? (El PDF del emprendedor usa 10 tokens/kg como punto de partida).
2. **Decidir si papayos blancos y negros son fungibles entre sí** o si se mantienen como saldos separados que no se pueden mezclar.
3. **Diseñar la migración:** cómo se trasladan los saldos de los 600 usuarios actuales de la plataforma web al contrato on-chain.
4. **Definir el catálogo de beneficios canjeables** y sus costos en papayos.
5. **Implementar `PapayoToken.sol`** como extensión del sistema actual y probarlo con el flujo de 14 pasos del README principal.
