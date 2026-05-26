# Prompt para Google AI Studio

Quiero que construyas un prototipo funcional de interfaz web para LaPapaya, inspirado visualmente en las imágenes adjuntas.

No generes imágenes. No uses IA generativa de imágenes. Crea una interfaz web interactiva tipo dashboard usando código.

## Objetivo general

Crear un dashboard para inversionistas y empresas interesadas en aportar a proyectos socioambientales de LaPapaya, específicamente al proyecto "Río Cali Transparente".

El dashboard debe permitir que una empresa vea:

1. Qué tipo de convocatoria puede seleccionar:
   - COCREA (165% de la renta)
   - Obras por Impuestos (50% de la renta)

2. Cómo su aporte podría impactar de forma estimada su carga tributaria o sus obligaciones de renta.

3. Qué impacto ambiental y social genera su inversión.

4. Cómo la inversión se conecta con un sistema blockchain de trazabilidad, gobernanza, monitoreo ambiental e impacto climático.

5. Cómo el aporte de empresas ayuda a que personas, emprendedores y comunidades puedan crecer y conectar oportunidades.

Este prototipo debe usar datos simulados. No debe usar información tributaria real ni prometer beneficios fiscales reales. Debe dejar claro que los cálculos son estimaciones para demo.

---

## Estilo visual de referencia

Usa las imágenes adjuntas como referencia visual.

La interfaz debe mantener una estética cercana a LaPapaya:

- Fondo general blanco.
- Contenedores blancos con bordes redondeados.
- Botones principales en naranja.
- Detalles verdes para impacto ambiental.
- Detalles morados para elementos Web3 o blockchain.
- Tipografía limpia, amigable y moderna.
- Header superior fijo similar al de las capturas:
  - Logo LaPapaya a la izquierda.
  - Menú superior con opciones: "Dashboard", "Impacto", "Blockchain", "Configuración".
  - Botón amarillo o naranja: "Conectar billetera".
  - Botón naranja: "Salir".
- Diseño centrado, con máximo ancho de aproximadamente 1200px.
- Cards amplias y limpias.
- Usar emojis pequeños como apoyo visual, como en la interfaz actual.

No copiar exactamente la interfaz, pero sí conservar su lenguaje visual.

---

## Stack esperado

Genera un prototipo en React.

Preferiblemente usa:

- React con componentes funcionales.
- CSS simple o Tailwind CSS.
- Datos quemados o simulados en el frontend.
- Sin backend.
- Sin conexión real a blockchain.
- Sin conexión real a billetera.
- Sin APIs externas.
- Todo debe poder correr como una maqueta funcional.

El resultado debe incluir:

- Código completo.
- Componentes organizados.
- Estado local para simular los cálculos.
- Datos simulados.
- Interacciones básicas.
- Comentarios breves en el código donde sea necesario.

---

## Estructura del dashboard

La pantalla principal debe llamarse:

# Dashboard de Inversión Socioambiental

Subtítulo:

"Simula tu aporte, estima beneficios tributarios y visualiza el impacto ambiental, social y económico de tu inversión."

La interfaz debe dividirse en dos grandes zonas:

## 1. Panel izquierdo: selección de convocatoria y calculadora

Crear un panel lateral izquierdo con el título:

"Calculadora de aporte"

Debe incluir:

### Selector de convocatoria

Un selector visual con dos opciones:

1. COCREA en la Renta(165%)
2. Obras por Impuestos en la Renta (50%)

Cuando el usuario seleccione una opción, debe cambiar la descripción del mecanismo.

Para COCREA mostrar algo como:

"Modelo de aporte orientado a proyectos creativos, culturales y de innovación social. En esta demo, el beneficio se calcula con una tasa configurable y simulada."

Para Obras por Impuestos mostrar algo como:

"Modelo en el que una empresa puede dirigir parte de sus obligaciones tributarias hacia proyectos de impacto. En esta demo, el cálculo es estimado y no tiene validez legal."

Importante:
No afirmar porcentajes reales. Usar variables simuladas configurables.

### Inputs de la calculadora

Incluir campos:

- Obligación estimada de renta de la empresa
- Monto que desea aportar
- Año de inversión
- Tipo de empresa
  - Pyme
  - Mediana empresa
  - Gran empresa
- Sector
  - Tecnología
  - Industria
  - Servicios
  - Agro
  - Energía
  - Otro

### Variables simuladas

Usar estas tasas simuladas internas para la demo:

- COCREA: beneficio estimado del 165% del aporte
- Obras por Impuestos: beneficio estimado del 50% del aporte

Aclarar visualmente:

"Valores simulados para fines de prototipo. No constituyen asesoría tributaria."

### Resultados de la calculadora

Mostrar cards con:

- Aporte propuesto
- Beneficio tributario estimado
- Obligación de renta antes del aporte
- Obligación estimada después del aporte
- Aporte neto percibido
- Porcentaje de la obligación que podría ser compensado de forma simulada
-CO2 Capturado
-Indices de calidad de agua mejorados
-Empleabilidad
-Formación
-Restauración de Habitantes de Calle
- Residuos Aprovechados

Agregar un botón:

"Simular impacto"

Al hacer clic, debe actualizar el estado del río y los indicadores del dashboard.

---

## 2. Panel principal: impacto y río 

El panel central debe mostrar varias secciones.

---

# Sección A: Resumen ejecutivo para inversionistas

Crear cards superiores con métricas resumidas:

1. Aporte simulado
2. Ahorro tributario estimado
3. Mejora ambiental proyectada
4. Personas beneficiadas
5. Alertas ambientales atendidas

Ejemplo de datos simulados:

- Personas beneficiadas: 320
- Emprendedores conectados: 24
- Comunidades impactadas: 3
- Estaciones de monitoreo: 3
- Alertas atendidas: 5
- Trazabilidad: 100%

---

# Sección B: Estado actual del Río Cali

Crear una card grande llamada:

"Estado simulado del Río Cali"

Debe mostrar indicadores ambientales con barras, badges o gauges simples:

- pH
- Oxígeno disuelto
- Temperatura
- Conductividad
- Turbidez
- Índice de Calidad del Agua, ICA

Usar datos iniciales simulados:

- pH: 7.2
- Oxígeno disuelto: 4.6 mg/L
- Temperatura: 26.4 °C
- Conductividad: 780 µS/cm
- Turbidez: 42 NTU
- ICA: 58 de 100
- Estado: "En observación"

Si el usuario hace una simulación de aporte, actualizar los valores de forma proporcional al monto aportado.

Ejemplo:
Mientras mayor sea el aporte, mejoran los indicadores hasta cierto límite.

Valores máximos después de intervención:

- pH: 7.1
- Oxígeno disuelto: hasta 6.8 mg/L
- Temperatura: baja hasta 24.8 °C
- Conductividad: baja hasta 520 µS/cm
- Turbidez: baja hasta 18 NTU
- ICA: sube hasta 82 de 100
- Estado: "Mejorando"

Mostrar un texto narrativo:

"Con este aporte, el sistema proyecta una mejora en la capacidad de monitoreo, respuesta comunitaria e intervención ambiental del tramo priorizado."

---

# Sección C: Simulación antes y después

Crear una sección comparativa:

"Antes de la inversión" vs "Después de la inversión"

Antes:

- Monitoreo fragmentado
- Datos ambientales dispersos
- Baja participación ciudadana
- Trazabilidad financiera limitada
- Intervenciones reactivas

Después:

- Sensores IoT simulados registrando datos
- Alertas ambientales en blockchain
- DAO validando decisiones
- Desembolsos condicionados a evidencia
- Medición de impacto climático

Usar tarjetas comparativas, no tablas muy densas.

---

# Sección D: Impacto social

Crear una card llamada:

"Impacto social y conexión de oportunidades"

Debe conectar con esta necesidad de usuario:

"Necesito apoyo para crecer y conectar oportunidades"

Mostrar indicadores:

- Emprendedores conectados
- Organizaciones aliadas
- Comunidades participantes
- Jóvenes o estudiantes vinculados
- Proyectos priorizados por la comunidad

Incluir una pequeña sección tipo "coincidencias de oportunidades", inspirada en la interfaz actual de LaPapaya:

Ejemplo:

- Empresa aporta a monitoreo ambiental
- Comunidad propone intervención
- Academia valida datos
- Emprendedor ofrece solución tecnológica
- Inversor recibe trazabilidad e impacto verificable

Mostrar una frase:

"Cada aporte no solo financia una intervención ambiental, también activa una red de colaboración entre empresas, comunidad, academia y emprendedores."

---

# Sección E: Módulo Trazabilidad Financiera

Crear una sección llamada:

"Trazabilidad financiera del aporte"

Debe mostrar los cuatro contratos inteligentes del prototipo como cards conectadas.

## Contrato 1: EnvironmentalMonitoring

Título visible:
"Monitoreo ambiental"

Descripción:
"Registra lecturas simuladas de sensores IoT del río y genera alertas cuando una variable supera los umbrales definidos."

Mostrar datos simulados:

- Última lectura: Oxígeno disuelto 4.6 mg/L
- Estado: Alerta generada
- Hash simulado: 0xA91...F23
- Timestamp simulado

## Contrato 2: GovernanceDAO

Título visible:
"Gobernanza participativa"

Descripción:
"Autoridades, comunidad, academia y sector privado votan propuestas para validar incidentes y priorizar intervenciones."

Mostrar datos simulados:

- Propuesta activa: Validar intervención en tramo La Isla
- Votos a favor: 7
- Votos en contra: 1
- Estado: Aprobada

## Contrato 3: FinancialTraceability

Título visible:
"Trazabilidad financiera"

Descripción:
"Bloquea o libera fondos simulados según dos condiciones: evidencia ambiental validada y aprobación de la DAO."

Mostrar estado tipo checklist:

- Alerta ambiental validada: Sí
- Propuesta DAO aprobada: Sí
- Desembolso autorizado: Sí
- Valor liberado: según aporte simulado

## Contrato 4: SustainabilityClimate

Título visible:
"Impacto climático"

Descripción:
"Compara el estado ambiental antes y después de una intervención y genera un registro verificable de mejora."

Mostrar datos simulados:

- Línea base ICA: 58
- ICA posterior proyectado: calculado por la simulación
- Mejora estimada: porcentaje
- Claim climático simulado: creado

Agregar un bloque visual de estado:

"Registro verificable en cadena"

Con un hash simulado:

0xR10CALI...2025

---

# Sección F: Flujo del sistema

Crear una sección tipo timeline horizontal o vertical con el flujo:

1. Empresa selecciona convocatoria
2. Empresa simula aporte
3. El sistema estima beneficio tributario
4. Contrato de monitoreo registra alerta ambiental
5. DAO valida la intervención
6. Contrato financiero libera fondos simulados
7. Se ejecuta intervención ambiental
8. Contrato climático registra mejora
9. Inversionista visualiza impacto y trazabilidad

Debe verse claro, moderno y fácil de explicar en un pitch.

---

# Sección G: Distribución del aporte

Crear una visualización simple con barras o cards, no usar librerías complejas si no es necesario.

Distribuir el aporte simulado así:

- 35% Monitoreo ambiental
- 25% Tecnología blockchain e interfaz
- 20% Intervención comunitaria
- 15% Operación y mantenimiento
- 5% Auditoría y gestión

Mostrar montos calculados automáticamente según el aporte ingresado.

---

# Sección H: Mensaje final para el inversionista

Crear una card destacada al final:

"Tu aporte se convierte en evidencia, acción e impacto"

Texto:

"Con Río Cali Transparente, LaPapaya permite que las empresas no solo aporten recursos, sino que puedan visualizar cómo esos recursos se transforman en monitoreo ambiental, decisiones colectivas, desembolsos auditables y mejoras verificables para el río y su comunidad."

Botón principal:

"Descargar reporte simulado"

El botón no debe descargar realmente nada. Al hacer clic, mostrar un mensaje o alerta:

"Reporte simulado generado para demo."

---

## Reglas funcionales

El prototipo debe tener interactividad real en frontend:

1. Cambiar entre COCREA y Obras por Impuestos.
2. Ingresar obligación de renta.
3. Ingresar monto del aporte.
4. Calcular beneficio tributario estimado.
5. Calcular obligación estimada después del beneficio.
6. Simular mejora del río según el monto aportado.
7. Actualizar indicadores ambientales.
8. Actualizar distribución del aporte.
9. Actualizar cards de blockchain.
10. Mostrar advertencia de que todo es una simulación.

---

## Fórmulas simuladas

Usa estas fórmulas para la demo:

beneficioEstimado = aporte * tasaConvocatoria

obligacionDespues = max(obligacionRenta - beneficioEstimado, 0)

aporteNetoPercibido = aporte - beneficioEstimado

porcentajeCompensado = min((beneficioEstimado / obligacionRenta) * 100, 100)

factorImpacto = min(aporte / 70000000, 1)

ICA posterior = 58 + factorImpacto * 24

Oxígeno disuelto posterior = 4.6 + factorImpacto * 2.2

Turbidez posterior = 42 - factorImpacto * 24

Conductividad posterior = 780 - factorImpacto * 260

Temperatura posterior = 26.4 - factorImpacto * 1.6

pH posterior = 7.2 - factorImpacto * 0.1

personasBeneficiadas = 120 + factorImpacto * 880

emprendedoresConectados = 8 + factorImpacto * 42

alertasAtendidas = 1 + factorImpacto * 9

Redondear valores para que se vean bien en pantalla.

---

## Datos iniciales sugeridos

Usar estos valores por defecto:

- Convocatoria: Obras por Impuestos
- Obligación estimada de renta: 120000000
- Aporte inicial: 30000000
- Año: 2025
- Tipo de empresa: Gran empresa
- Sector: Tecnología

---

## Cuidado con el lenguaje legal y financiero

No usar frases como:

- "Ahorro garantizado"
- "Beneficio real"
- "Certificación oficial"
- "Crédito fiscal asegurado"
- "Reducción legal garantizada"

Usar siempre:

- "Estimado"
- "Simulado"
- "Proyección"
- "Demo"
- "Valor referencial"
- "No constituye asesoría tributaria"

Agregar un pequeño disclaimer visible:

"Este dashboard es una simulación para prototipo. Los valores tributarios, ambientales y blockchain son demostrativos y deben ser validados con asesores legales, tributarios, ambientales y técnicos antes de cualquier implementación real."

---

## Requisitos de diseño

El prototipo debe verse como una app real, no como un wireframe.

Debe incluir:

- Header superior.
- Sidebar o panel izquierdo.
- Cards.
- Badges de estado.
- Barras de progreso.
- Indicadores numéricos grandes.
- Sección de impacto ambiental.
- Sección de impacto social.
- Sección blockchain.
- Timeline de flujo.
- Botones interactivos.
- Responsive básico para escritorio y móvil.

Mantener una estética similar a las capturas:

- Logo LaPapaya arriba a la izquierda.
- Botones redondeados.
- Cards blancas.
- Sombras suaves.
- Botón principal naranja.
- Estados positivos en verde.
- Estados blockchain en morado.
- Fondo gris claro.

---

## Textos clave que deben aparecer en la interfaz

Incluir estas frases en algún lugar del dashboard:

"Necesito apoyo para crecer y conectar oportunidades."

"Cada aporte activa una red de colaboración entre empresas, comunidad, academia y emprendedores."

"Ningún peso se mueve sin evidencia ambiental verificada y aprobación colectiva."

"Río Cali Transparente convierte la gestión ambiental en un proceso auditable, participativo y condicionado a evidencia."

"Tu aporte se convierte en evidencia, acción e impacto."

---

## Resultado esperado

Entrega el código del prototipo completo.

Debe ser una sola app lista para copiar y ejecutar.

Incluye:

1. Código React completo.
2. CSS o clases Tailwind necesarias.
3. Datos simulados.
4. Explicación breve de cómo ejecutar.
5. Una nota final explicando qué partes son simuladas.

No generes imágenes.
No uses APIs reales.
No conectes billeteras reales.
No uses fondos reales.
No conectes contratos reales.
Todo debe ser una maqueta funcional para pitch y validación temprana.