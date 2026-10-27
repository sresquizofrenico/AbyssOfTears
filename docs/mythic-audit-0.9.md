# Auditoría antes de la expansión 0.9

Referencia conservada: `reference/0.8.0-before-mythic-expansion` (`7d664fc`). Rama aislada: `expansion/0.9-shader-and-relics`.

| Sistema inspeccionado | Estado antes de modificar |
|---|---|
| Personajes, estadísticas, selección | Implementados y verificados en 0.8: diez entradas, catálogo compartido, bloqueo real, siluetas y barras. |
| Activas de diez personajes | Implementadas y verificadas; valores y recargas todavía corresponden a 0.8. |
| Pasivas solicitadas | Parciales: Solen quema; los demás no tienen todavía las nuevas pasivas. |
| Desbloqueos | Persistentes, versionados, deduplicados y con respaldo; Orin requiere un minijefe inexistente, Vex veinte descubrimientos frente a catorce disponibles. |
| Shader y Determinación | No implementados. La imagen del personaje no está disponible; solo se dispone de la descripción textual del usuario. |
| Objetos | Catorce reales, no cuarenta: daño, vida, movimiento, cadencia, multitiro, fuego, hielo, electricidad, perforación, rebote, orbital, espejo y escudo. |
| Rarezas | Cinco niveles de objetos; aún no hay clasificación independiente de personajes ni nivel Mítico. |
| Tienda/cofres/recogida/inventario | Implementados y cubiertos por suites: compra atómica, posiciones seguras, estados de cofre y efectos reales. |
| Sinergias | Modificadores de proyectil combinables y límites de 96 proyectiles; no existe todavía un intérprete modular de efectos para cien entradas. |
| Recompensas/economía | Tablas JSON por piso y fuente, cinco rarezas, monedas limitadas y precios progresivos; solo tres pisos jugables. |
| Élite/minijefe/jefes distintos | No implementados: veinte enemigos normales y un Custodio reutilizado en tres pisos. No se pueden falsificar los requisitos míticos contando ese jefe como tres diferentes. |
| Guardado | Ajustes y progreso permanente; no hay continuación de una partida en curso. No se eliminarán archivos anteriores. |
| Android/CI | Godot 4.6.3, ARM64, Compatibility, firma de depuración, pruebas y artefacto. Referencia verde: Actions 40443478513. |
| Prueba física ZTE 8050 | No verificable en este entorno. |

Las funciones que falten se entregarán con pruebas y estado explícito, sin convertir entradas de catálogo en supuestas mecánicas terminadas.
