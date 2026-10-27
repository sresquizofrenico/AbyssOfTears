# Auditoría previa a la actualización 0.7

Base inspeccionada: 0.6.0, commit `68a7a91`. Rama independiente
`balance/0.7-economy-and-loot`. Las once suites de la base pasan antes de cambiar
código. El APK anterior compiló y verificó su firma en Actions 40416733427.
Esta auditoría distingue pruebas automatizadas de pruebas físicas Android.

| Sistema / rutas | Clasificación antes de esta entrega | Evidencia y límite |
| --- | --- | --- |
| `project.godot`, `scenes/main.tscn`, `scripts/core/game.gd` | Implementada y verificada | Arranque real, menú y modos; Godot 4.6.3 Compatibility, 960×540 |
| `scripts/player/player.gd`, `scripts/characters/character_catalog.gd` | Parcialmente implementada | Solo Neris jugable; catálogo, animación y estadísticas reales. No existen diez personajes ni sus activas |
| `scripts/combat/projectile.gd`, `scripts/core/stats.gd` | Implementada y verificada para efectos actuales | Movimiento, daño, vida, cadencia, alcance, rebote, perforación, fuego/hielo/electricidad; veneno y otros efectos pendientes |
| `scripts/enemies/catalog.gd`, `enemy.gd`, `hazard.gd` | Implementada y verificada para 20 tipos | Comportamientos distintos. Navegación alrededor de todas las coberturas no es un sistema completo de caminos |
| `scripts/bosses/tide_warden.gd` | Parcialmente implementada | Un Custodio con fases y patrones; no hay cinco élites, tres minijefes y tres jefes distintos |
| `scripts/generation/floor_layout.gd`, `room_blueprint.gd`, `room_content.gd` | Parcialmente implementada | Tres pisos, semillas, grafo de 12 salas, doce distribuciones interiores y validación. No 40 variantes ni formas exteriores L/T/cruz; cantidad de salas fija |
| `scripts/items/catalog.gd`, `inventory.gd` | Parcialmente implementada | 14 reliquias funcionales, rarezas y sinergias limitadas; no 40 objetos ni activas/malditos |
| `scripts/items/pickup.gd`, `scripts/ui/pickup_interaction.gd` | Implementada y verificada automáticamente | Proximidad, animación, entrega confirmada, botón táctil, referencias y duplicados. Son Node2D con distancia, no Area2D: no hay señales de entrada o máscaras de área que reconectar |
| `game.gd`: compra y `RoomContent`: tiendas | Implementada y verificada automáticamente, balance con errores | Compra local/menú, saldo reservado y reversión, entrega inmediata. Precios fijos por rareza, sin progresión por piso |
| `pickup.gd`: cofres | Parcialmente implementada | Apertura, llave opcional, animación y entrega única. Falta catálogo de ocho cofres y persistencia entre sesiones |
| Monedas: `on_enemy_defeated`, `reward_room`, `activate_prop`, `collect_relic` | Implementada, pero con errores de balance y guardas incompletas | Cada muerte suma dinero; también 2–5+piso por sala, barril de dinero +5, duplicados +3. Invocaciones pueden prolongar ingresos y callback repetido de muerte carece de guarda propia |
| Rarezas: `RelicCatalog.roll`, secreto y jefe | Implementada, pero con errores de balance | Pesos por objeto en lugar de por rareza. Secreto garantiza épico/legendario cada piso; jefe fuerza raro o mejor. No reproduce las probabilidades solicitadas |
| `scripts/ui/compact_hud.gd`, menú y selección | Implementada y verificada para contenido actual | Valores reales, iconos, barra izquierda, preferencias; sin crítico o activas ficticios |
| `scripts/saving/settings.gd` | Parcialmente implementada | Opciones con validación y archivo temporal; no guardado completo de partida, monedas, desbloqueos, logros o continuación |
| `assets/illustrated`, sprites/relics | Parcialmente implementada | Dirección artística ilustrada original y muestra integrada; resto del arte pendiente |
| Audio | No implementada | Menú lo identifica como pendiente |
| `export_presets.cfg`, `tools/export_android.py`, workflows | Implementada y verificada | APK ARM64 offline firmado, SDK/Java/Godot fijados, importación y upload-artifact; nueva compilación se comprobará tras los cambios |
| Tacto/FPS/memoria en ZTE de esta actualización | No verificable en este entorno | Tests de eventos y render real Mesa disponibles; no se ejecuta físicamente en el teléfono |

## Hallazgos que motivan esta entrega

No se ha reproducido un fallo general nuevo que impida recoger o comprar en
la base: pasan sus pruebas de proximidad, botones, cofres, entrega, límites y
saldo. No se afirma por ello haber descartado todos los fallos físicos del ZTE.
Se conservan estas implementaciones y se añade rareza a la información del producto.

La inflación sí tiene causas directas en el código: recompensas garantizadas por
cada muerte, sumadas a varias fuentes garantizadas adicionales. No se necesita
un error de guardado para explicarla; además no existe guardado de partida que
pudiera duplicar dinero entre sesiones. Se eliminarán los pagos garantizados
ordinarios y la posibilidad de cobrar varias veces la misma muerte.

La actualización inicial se centra en estos problemas prioritarios, tablas
configurables activas de economía/botín/tienda, protección contra duplicados y
simulación. No se intentan completar decenas de objetos, personajes y salas en
un cambio que haría más difícil revisar las correcciones.
