# Informe técnico 0.14

Referencia: 785d312 (0.13.0). Recuperación: reference/0.13.0-before-selection. Rama: fix/0.14-selection-and-private-roster.

## Causas corregidas

- `character_selection.gd` normalizaba `(sin(t)*0.5,0.4)`, cruzando constantemente el umbral de frente/perfil. Ahora el vector apunta al frente con variación horizontal pequeña.
- Las poses de brazo se cambiaban mediante booleanos. `MenuCharacter.update_pose()` interpola un peso que usan `IllustratedNeris` y `BondArt`; el combate conserva sus llamadas anteriores.
- La navegación y COMENZAR podían escribir simultáneamente la posición del personaje. Ahora se cancela el Tween previo al iniciar.
- Shader tenía grandes óvalos oscuros y pequeños reflejos, con poco contraste a escala de combate. Se añade blanco de ojo, iris, pupila y brillo sin cambiar la silueta ni los atributos originales.

## Archivos principales

`scripts/ui/character_selection.gd`, `menu_character.gd`, `illustrated_neris.gd`, `bond_art.gd`; tres SVG de Shader; `tests/selection_polish_tests.gd`; `tools/validate.py` y `tools/export_android.py`.

El soporte genérico opcional se separa en `guest_roster.gd`, `guest_rules.gd` y `guest_art.gd`. Guarda la identidad de catálogo independiente del comportamiento reutilizado. El paquete externo se carga una vez, comparte atlas y no duplica diccionarios por fotograma. Los personajes originales no se sustituyen.

`player.gd`, `game.gd`, `pickup.gd` y `bonds_arena.gd` integran los modificadores solo cuando hay una identidad del paquete privado. Los estados nuevos llevan prefijo `guest_`; los checkpoints antiguos reciben valores predeterminados al cargar. La exportación pública excluye el paquete y rechaza también su bandera y texturas importadas.

## Evidencia

27 ejecuciones Godot y 14 tests Python correctos. Selección pulida: 2.010 comprobaciones. Se conservan las regresiones de puertas, continuación, economía, recogida, habilidades, diario y controles. Capturas públicas en docs/previews; las capturas de los personajes del prototipo se conservan en el repositorio privado.

Se preparó un paquete privado con nueve IDs adicionales y 108 comprobaciones de habilidades, sprites, guardado y carga. El usuario creó el repositorio privado porque la integración rechazó crear repositorios nuevos; se verificó su visibilidad antes de escribir. Su workflow exige visibilidad privada y usa una base pública fijada por etiqueta, sin reconstruir el juego.

Pendientes: pruebas físicas en ZTE, arte de animación final, doce pisos y mínimo anterior de 100 MB. Los APK son de prueba y sus tamaños se miden sobre archivos exportados, nunca se rellenan.
