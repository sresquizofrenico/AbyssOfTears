# Auditoría y entrega · Vínculos 0.12.0

Referencia estable: 0.11.0, commit 4e78a582ea65ba80a0d0188e7ebc9cc0667cbd72. Rama: expansion/0.12-nine-heroes-and-codes; etiqueta de recuperación reference/0.11.0-before-nine-heroes.

## Estado comprobado

| Sistema | Estado y evidencia |
| --- | --- |
| Once héroes anteriores, cien objetos, tiendas y cofres | Conservados; regresiones ejecutadas |
| Nueve héroes de Vínculos | Implementados; estadísticas, activas/pasivas, selección y bloqueo probados |
| Código ABISMO-TOTAL | Implementado; entrada táctil, persistencia, repetición y fallo de escritura probados |
| Desbloqueos naturales compuestos | Implementados; progreso validado, conjuntos deduplicados y migración v1–v3 a v4 |
| Talleres, antídotos, Futuro, Teatro, circuitos, táctica, resistencia, familia | Implementados; victorias y fallos automatizados, capturas reales de Godot |
| Arte | SVG y animación procedural originales integrados; acabado definitivo pendiente |
| Campaña | Tres pisos existentes conservados, recursos opcionales integrados; doce pisos pendientes |
| Música | Sistema existente conservado; pistas exclusivas de los desafíos pendientes |
| Android | Exportación local ARM64 firmada y verificada; consultar Actions de esta publicación para CI |
| Rendimiento físico y tacto del ZTE | No verificables en este entorno; eventos táctiles automatizados no sustituyen el teléfono |
| APK mínimo 100 MB | Pendiente; tamaño real local 32,228,550 bytes sin relleno |

## Arquitectura

- `bond_catalog.gd`: definiciones añadidas al catálogo existente sin cambiar los IDs antiguos.
- `nine_bonds.gd`: estado y componentes de habilidades con límites y continuidad entre salas.
- `bond_progress.gd` / `progress.gd`: condiciones compuestas, evidencia única, escrituras atómicas, desbloqueo universal separado de logros.
- `bonds_arena.gd` / `bond_pickup.gd`: actividades y recursos mediante la ruta común de recogida, estaciones opcionales y progreso persistente.
- `bond_art.gd`: render reutilizable y carga perezosa de cuerpos; estilos compartidos.
- `touch_button.gd`: propietario táctil, cancelación fuera del botón y arrastre de listas.

Se mantienen los topes de enemigos, proyectiles y peligros. Campos nuevos limitados a ocho, sombras y familiares sin recursión; no se carga todo el arte a máxima resolución. Las máquinas no son obligatorias para llegar al jefe. Las recompensas de pruebas no simulan finales de campaña.

## Pruebas ejecutadas

`python3 tools/validate.py`: 22 suites de Godot y 14 pruebas Python correctas. Suites nuevas: `nine_bonds_tests.gd` (343 comprobaciones) y `bond_edge_tests.gd` (30). Suite de Vínculos ejecutada además con render Compatibility/Mesa; capturas de selección, códigos, ingeniería y familia en `docs/previews` tomadas del juego, no del ZTE.

`python3 tools/export_android.py`: firma, ARM64, recursos, permisos y tamaño verificados localmente. La publicación pública solo se etiqueta tras el éxito de CI. Copia de progreso previa recomendada por firma efímera; AOT4 no es legible en versiones antiguas.

Próxima entrega recomendada: pruebas físicas Android y ajustes derivados; después arte y música exclusivos. No ampliar a otra campaña antes de corregir cualquier regresión reportada en el teléfono.
