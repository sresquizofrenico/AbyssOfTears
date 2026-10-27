# Auditoría de personajes — referencia 0.7.0

Referencia recuperable: `reference/0.7.0-before-characters` (`b9f6b44`). Rama: `characters/0.8-roster-and-unlocks`.

Inspección previa: `project.godot`, escena principal y coordinador, catálogo de personajes, selección, jugador y estadísticas, combate/proyectiles, enemigos/jefe, inventario y recogida/compra/cofres, generador y habitaciones, controles/HUD, ajustes, exportación y ambos workflows. Las doce suites y la importación de la referencia se ejecutaron sin errores (`tools/validate.py`).

| Sistema en 0.7.0 | Clasificación y evidencia |
|---|---|
| Selección y navegación | Implementada y verificada por `selection_tests`: un solo personaje real. |
| Personajes bloqueados | Parcial: solo existe una entrada ficticia en pruebas; no hay nueve personajes ocultos. Es la causa de que no aparezcan. |
| Personajes | Neris es el único implementado. Los otros nueve no existen. Se conserva su ID `neris` para El Errante. |
| Estadísticas | Implementadas y verificadas: `ActorStats`, catálogo compartido con la vista previa y modificadores del inventario. |
| Habilidad activa de personaje | No implementada; disparos y efectos de catorce reliquias sí existen. |
| Guardado | Ajustes versionados en `user://settings.json`; no hay partidas continuables ni desbloqueos permanentes. No se elimina ese archivo. |
| Arte y animación | Neris ilustrado por partes; estados de caminar, disparar, daño/recogida/final. Falta el arte de nueve protagonistas. |
| Enemigos/pisos | Veinte enemigos, tres pisos, doce habitaciones por piso, un Custodio. No existen minijefes distintos. |
| Objetos/tiendas/cofres | Catorce objetos, transacciones y cofres con estados y pruebas; economía configurable 0.7.0. |
| Android y CI | Preset ARM64, Godot 4.6.3 y plantillas fijados, SDK/Java, firma de depuración y upload-artifact; referencia verde: ejecución 40420002640. |
| Rendimiento táctil físico | No verificable en este entorno; las entradas sintéticas y el renderizador de escritorio no son un ZTE 8050. |

Dos condiciones solicitadas no son alcanzables con el contenido de referencia: descubrir veinte objetos (hay catorce) y derrotar un minijefe (no existe). No se falsificarán esos contadores ni se considerará un enemigo normal un minijefe. Se documentará su estado hasta incorporar ese contenido.

El mínimo de 100 MB se comprobará sobre el APK exportado. El aumento de contenido debe tener uso real: no se incluirán relleno, copias ni texturas sobredimensionadas para forzarlo.
