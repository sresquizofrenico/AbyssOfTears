# Los nueve vínculos — auditoría y primera entrega

Referencia estable: 0.10.0, `dc7b21f21bf0f75001009cccb0da223057d9027a`.
Rama: `expansion/0.11-abyss-journal`. Recuperación: `reference/0.10.0-before-bonds`.

## Estado real de partida

- Godot 4.6.3, GDScript, Compatibility, Android ARM64, 960×540 horizontal.
- Once personajes funcionales: Neris/El Errante, Nyra, Kael, Lumi, Vex, Orin, Eira, Solen, Mira, Nox y Shader Mítico. No existe Darian ni los otros once viajeros de la expansión previa; no se anuncian 23 o 32 personajes.
- Tres pisos: Cripta de Sal, Jardines Hundidos y Falla de Cristal. Doce salas conectadas por piso, generación por semilla y doce distribuciones interiores. La campaña de doce pisos sigue pendiente.
- Veinte enemigos normales, rangos élite/minijefe y tres jefes con patrones propios y dos fases. Se conservan los IDs.
- Cien objetos con efectos, compras transaccionales, cofres y recogida común. Economía configurable por piso y fuente de recompensa.
- Controles multitáctiles con modo zurdo, joystick flotante y práctica; pausa, menú sencillo y selección con bloqueados.
- Trece bucles musicales originales y once efectos; volúmenes separados, suspensión por foco y carga limitada.
- Progreso permanente v2 con respaldo y códigos AOT1/AOT2. No existe guardado de una expedición en curso.
- La versión pública 0.10.0 y su APK de 31.838.661 bytes se conservan. La validación de referencia ejecutada pasó 18 suites Godot y 13 pruebas Python.

La imagen adjunta se utiliza como referencia temática y de organización. No se incorpora al juego ni se recortan sus personajes. Su rótulo «32 personajes» no describe el código existente. Los nueve personajes nuevos se integrarán después de sus mecánicas y desafíos, según el orden solicitado.

## Etapas 1–2: Diario del Abismo

- Diario accesible desde **Opciones → Diario y créditos → Diario del Abismo** y **Pausa → Diario del Abismo**. El menú principal conserva Nueva partida, Opciones y Salir; Continuar no aparece porque no hay una expedición guardada compatible.
- Registra pisos visitados, salas especiales, criaturas observadas, jefes encontrados, objetos realmente recogidos, rutas secretas, mapas completos y desafíos efectivamente terminados.
- Encontrar un jefe no equivale a derrotarlo. Observar una criatura tampoco incrementa el contador de bajas. Ver un pedestal no registra el objeto hasta aceptar su recogida.
- El mapa completo exige visitar todas las salas, incluida la secreta. Cada identidad de piso cuenta una vez; repetir semillas no multiplica mapas completos. Las rutas secretas son únicas por piso, semilla y coordenadas de entrada.
- Las criaturas invocadas durante el combate pasan por el mismo registro. Las observaciones se agrupan y los duplicados no escriben de nuevo el archivo.
- Menú y laboratorios no conceden hallazgos. Consultar el diario pausa el mundo y libera los dedos de los controles; al volver conserva vida, dinero, objetos y recarga.
- Paginación de cuatro entradas; no se instancian cien fichas ni se cargan recursos de personajes futuros. Botones grandes, desplazamiento táctil y salida con Atrás/Escape.
- El apartado de máquinas está desactivado y marcado como próximo: no hay reparaciones ficticias ni una mecánica presentada como funcional.

## Guardado y migración

Se amplía el mismo administrador `Progress` a formato 3, sin crear un guardado paralelo. Lee los formatos 1 y 2; conserva objetos, desbloqueos, contadores, eventos y jefes conocidos. Los IDs antiguos de jefes derrotados son evidencia para el diario. Los totales agregados de bajas o pisos no permiten identificar especies ni mapas y no se convierten en descubrimientos inventados.

Los códigos nuevos AOT3 incluyen el diario. La importación acepta AOT1/AOT2/AOT3 y combina conjuntos sin retroceder logros nuevos. Una importación antigua no borra el diario actual. Hay validación de tipos, IDs y límites de 256 entradas por categoría, recuperación desde `.bak`, escritura temporal y devolución en memoria si falla el guardado. Una versión antigua del APK no puede leer un archivo v3; antes de actualizar se debe conservar el código de respaldo anterior, y el respaldo AOT3 se usa con 0.11 o posterior.

El respaldo incluye progreso permanente, no una expedición activa ni la configuración. La firma debug de Actions sigue siendo efímera; guardar el código fuera del juego antes de reinstalar.

## Pendiente de la expansión

Reparación de máquinas, antídotos/contaminación, predicción temporal, Teatro de los Ecos, carreras/circuitos, tácticas/resistencia y Constelación Familiar se incorporarán por etapas verificadas. Los nueve nuevos personajes no se presentan como implementados ni se desbloquean con contadores de enemigos genéricos. Lyra necesita evidencia de mapas, rutas y hallazgos, no un desbloqueo automático por abrir el diario.

La imagen aporta nombres de los pisos 9–12, pero no sus patrones y reglas completos; no sustituye las especificaciones jugables pendientes de la campaña anterior. Las pruebas físicas de FPS, memoria, tacto y escucha en ZTE siguen pendientes. El mínimo previo de 100 MB continúa pendiente; no se añade relleno.

## Etapa 3: reliquias de arqueología

Doce vestigios originales se distribuyen por los tres pisos actuales, cuatro de cada identidad, en cofres de salas especiales y secretas. El catálogo `data/archaeology.json` contiene historia, rareza, piso, fuentes, icono, efecto y pesos configurables (7/3/1 para común/poco común/raro). El generador respeta la semilla y filtra los hallazgos ya conocidos. Si se agota el catálogo del piso, no rellena el cofre con duplicados.

Los cuatro usos se reparten entre las piezas:

- Historia: desbloquea una entrada narrativa persistente.
- Pista: marca una entrada secreta del piso; no abre su cerradura ni la cuenta como visitada.
- Llave: recupera una llave, hasta el límite del recurso, una sola vez por pieza entre partidas.
- Mapa: revela habitaciones a dos conexiones del hallazgo; no las visita ni concede un mapa completo.

Se reutilizan la clase y transacción de recogida existentes mediante `ArchaeologyPickup`, sin una segunda lógica de proximidad/cofres. La adquisición guarda el hallazgo antes de otorgar su utilidad; si falla, la recompensa permanece disponible. Una pieza duplicada que ya estuviera preparada se retira sin volver a conceder llaves o efectos. No se introducen monedas ni aumentos de daño. Las doce piezas tienen iconos SVG originales y un apartado propio del diario; **no se cuentan como doce mejoras de combate nuevas**, ni sustituyen los cien objetos anteriores.

Los primeros hallazgos de los Jardines Hundidos se alcanzan en el piso 2 actual; no se reordena la campaña para coincidir artificialmente con la imagen. Todos los personajes existentes pueden encontrarlos. Esto prepara evidencia para desbloqueos futuros, pero no desbloquea a Lyra todavía: su implementación corresponde a la etapa de personajes.

## Verificación de esta entrega

- Referencia: 18 suites Godot y 13 pruebas Python superadas.
- Diario antes de arqueología: validación de 19 suites y 122 comprobaciones específicas superadas; commit de recuperación `5f18c19`.
- Con arqueología: 20 suites Godot y 14 pruebas Python superadas; diario 128 comprobaciones, arqueología 328. Se conservan las pruebas de movimiento, tacto, inventario, compras, cofres, enemigos, jefes, economía y audio.
- Las pruebas de exploración ahora verifican por separado el objeto de combate anterior y el nuevo cofre arqueológico, incluida la protección contra volver a cobrar sus recompensas.
- Primera exportación local ARM64 0.11.0/código 17: 31.919.883 bytes. Referencia pública 0.10.0: 31.838.661 bytes (+81.222 bytes; +0,26%). Firma, permisos, JSON y los doce iconos importados comprobados dentro del APK, además de los 24 recursos de audio.
- Son resultados del entorno y del runner; no demuestran FPS ni pruebas físicas en ZTE. El mínimo de 100 MB sigue pendiente.

Siguiente etapa: reparación de máquinas para cualquier personaje, componentes con IDs únicos, estados persistentes y comprobaciones contra consumo duplicado. Después seguirán los desafíos ambientales y de predicción antes de anunciar personajes jugables nuevos.

El diario también pasó sus 128 comprobaciones con el renderizador Compatibility/Mesa de escritorio. Las capturas de `docs/previews/archaeology-*-0.11.png` proceden de ese renderizador, no del teléfono ni de la imagen de referencia.
