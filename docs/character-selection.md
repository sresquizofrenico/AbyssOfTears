# Nueva partida · 0.4.1

El menú principal contiene Nueva partida, Opciones y Salir. Continuar se oculta:
la versión actual guarda opciones, pero todavía no guarda una partida completa.
No se ofrece una carga de partida que no existe.

Nueva partida abre directamente la selección de Neris. Es el único personaje
implementado, disponible desde el inicio, por lo que no aparecen flechas. La
pantalla usa arte original ampliado, animación de reposo, iconos y estadísticas
obtenidas del mismo `CharacterCatalog.initial_stats` que inicializa al jugador:
6 de vida, 1 de daño, velocidad 185 y 4,17 disparos por segundo (intervalo 0,24 s).
Su ataque existente dispara en cuatro direcciones; no se añade una habilidad
especial nueva. Comienza sin reliquias. COMENZAR reproduce una reacción de 0,42 s
y abre la habitación inicial de la mazmorra existente de tres pisos.

La navegación reutilizable admite entradas bloqueadas: silueta, requisito y
botón desactivado. El catálogo real no añade personajes ficticios. Las pruebas
inyectan una entrada bloqueada temporal y comprueban flechas en ambos sentidos,
bloqueo de inicio y validación adicional en el coordinador de la partida.

Créditos y modos de prueba siguen disponibles en Opciones. Se conservan las
semillas, las doce habitaciones por piso, veinte enemigos normales, el Custodio,
las catorce reliquias, controles multitáctiles y configuración guardada.

## Verificación

- Validación previa de 0.4.0 completada sin fallos antes de los cambios.
- Importación, arranque y siete suites de pruebas ejecutadas automáticamente.
- Suite de selección: 41 comprobaciones, incluidas inicio por interfaz,
  tamaños 960×540, 1280×540 y 960×600, límites de paneles, bloqueo de personajes,
  estadísticas reales, cancelación y reinicio sin mejoras heredadas.
- Suite de menú adaptada a la navegación solicitada, conservando pruebas de
  introducción, omisión, animaciones, gráficos y respuesta de botones.
- Capturas reales del renderizador Compatibility/Mesa revisadas para menú,
  selección y opciones. No son capturas del teléfono ni mediciones de FPS.

Pendiente en ZTE 8050: instalar el APK de Actions, pulsar Nueva partida,
comprobar textos y zonas seguras, volver, comenzar, moverse y disparar a la vez,
pausar, guardar opciones y repetir. No se ha probado Continuar porque el sistema
de continuación de partidas todavía no está implementado.
