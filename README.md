## Nueva partida · 0.4.1

Menú simplificado y selección animada de Neris antes de entrar en la mazmorra.
[Detalles y pruebas](docs/character-selection.md).

# Abyss of Tears

**0.4.0 — Fases 0 y 1:** referencia estable protegida, doce habitaciones por piso,
tienda, llaves, secretos, trampas y Custodio; Neris conserva su equipo y tiene
un rostro más adorable. [Guía de exploración y resultados](docs/phase1-exploration.md).

**0.3.1 — Menú cinematográfico:** introducción de 6,5 s que puedes omitir,
Neris animado y reacciones a los botones. Los modos anteriores están en
**Otros modos**. [Guía del nuevo menú y funciones pendientes](docs/update-0.3.1-menu.md).

**0.3.0 — Reliquias del faro:** catorce objetos físicos, cofres, inventario,
combate combinado, ilustraciones originales y diagnóstico opcional.
[Contenido y controles de esta entrega](docs/update-0.3-relics.md).

**0.2.1:** mazmorra de tres pisos, ocho habitaciones por piso y minimapa.
[Cómo recorrerla y qué sigue pendiente](docs/update-0.2.1-floors.md).

**0.2 — Entrega A:** veinte enemigos y una incursión de cinco oleadas.
Consulta [contenido, límites y pruebas](docs/update-0.2-A.md).

Prototipo original de acción 2D para Android: **la cámara de las mareas**.
Eres Neris, guardián de un faro hundido. Purifica las seis sombras del sello
sin perder toda tu vida. No requiere Internet para jugar.

## Primera entrega: fase 1

- Godot **4.6.3 estable**, GDScript, Compatibility / OpenGL ES 3.
- Android ARM64, horizontal, resolución lógica 960 × 540, objetivo 60 FPS.
- Joystick de ocho direcciones y cuatro botones de ataque independientes.
- Multitáctil por identificador de dedo: moverse y disparar simultáneamente.
- Personaje con animación, colisiones, vida e invulnerabilidad temporal.
- Tres enemigos originales: erizo doliente (perseguidor), urna de sal
  (tirador con aviso visual) y raya del eco (veloz).
- Una habitación con obstáculos, proyectiles con alcance y presupuesto máximo,
  recompensas en óbolos, victoria, derrota y reinicio.
- Menús táctiles, pausa, créditos y opciones gráficas Bajo / Medio / Alto.
- Tamaño y opacidad de controles configurables; ajustes guardados en `user://`.
- Arte dibujado por código e icono SVG originales. No hay recursos externos
  que el usuario deba crear, descargar o instalar.

Los tres perfiles reducen decoración y partículas. No hay luces dinámicas,
plugins ni dependencias de ejecución externas. La simulación usa tiempo delta
y físicas a 60 Hz; el rendimiento real del ZTE 8050 queda por medir.

## Estado verificable

Repositorio: https://github.com/sresquizofrenico/AbyssOfTears

Pull request de entrega: https://github.com/sresquizofrenico/AbyssOfTears/pull/1

El proyecto y los scripts de validación/exportación se han ejecutado en el
entorno de desarrollo. Consulta [los resultados locales](docs/validation-results.md).
Para confirmar cada compilación de GitHub, abre
[Actions](https://github.com/sresquizofrenico/AbyssOfTears/actions) y comprueba
que **Build Android Debug APK** termine en verde y tenga el artefacto
**AbyssOfTears-Android-Debug**. La compilación también se ejecuta al abrir o
actualizar el pull request; no hace falta fusionarlo para descargar ese APK.

La instalación y el multitáctil físico en el ZTE están pendientes. Las pruebas
automatizadas inyectan eventos táctiles en Godot; no sustituyen las pruebas de
pantalla real ni miden los FPS del teléfono.

## Solo necesitas tu teléfono

No instales Godot, Android Studio, Termux ni herramientas de compilación.

1. Abre [el repositorio](https://github.com/sresquizofrenico/AbyssOfTears)
   en el navegador e inicia sesión en GitHub.
2. Pulsa **Actions** y abre la ejecución **Build Android Debug APK** que
   corresponda al pull request o a la versión que quieras probar.
3. Espera a que termine en verde y abre esa ejecución.
4. En **Artifacts**, descarga **AbyssOfTears-Android-Debug**.
5. Abre el ZIP con Archivos de Android y extrae **AbyssOfTears-debug.apk**.
6. Pulsa el APK. Si Android lo pide, autoriza instalar aplicaciones desde
   esa fuente y vuelve al archivo para instalarlo.

Una vez incorporados los workflows a `main`, también puedes seleccionar
**Build Android Debug APK → Run workflow** para compilar manualmente.

Debes iniciar sesión en GitHub para descargar artefactos. Si no aparecen los
botones, activa «Sitio para ordenadores» en el navegador del teléfono. Los
artefactos se conservan 14 días; puedes volver a ejecutar el workflow.

Cada ejecución usa una clave de depuración nueva. Para instalar una compilación
posterior puede ser necesario desinstalar la anterior; esto elimina sus ajustes.
No se necesita una clave de producción ni configurar secretos.

Más detalles en [compilación Android](docs/android-build.md) y
[pruebas en el teléfono](docs/phone-checklist.md).

## Organización y ampliación

`scenes/main.tscn` inicia el juego. `scripts/core/game.gd` coordina estados y
combate; personaje, enemigos, proyectiles, controles y guardado tienen scripts
independientes. `ActorStats` centraliza las estadísticas y acota las mejoras.
Las escenas usan cuerpos de colisión reales y se construye la interfaz desde
GDScript. Los directorios reservados a jefes, objetos y generación se usarán
cuando se implementen esos sistemas; no se cargan escenas vacías.

Siguiente fase: habitaciones conectadas, generador con semilla y accesibilidad,
recompensas, objetos, un jefe y minimapa. Después: contenido, personajes,
sinergias y optimización medida. No hay todavía guardado de partidas,
continuación, música, objetos equipables, jefes ni mazmorras procedurales.

## Para mantenimiento por Codex / desarrolladores

Estas acciones se realizan en el entorno de Codex o en GitHub Actions,
**nunca en una terminal del teléfono**:

```sh
python3 tools/install_godot.py --android
python3 tools/validate.py
python3 tools/export_android.py
```

El último script requiere `ANDROID_HOME`, `JAVA_HOME` y
`GODOT_ANDROID_KEYSTORE_DEBUG_PATH`. El workflow los configura automáticamente.
En escritorio, WASD mueve al personaje y las flechas disparan; Escape pausa.

Código y arte originales: [MIT](LICENSE). Godot y sus componentes conservan
sus licencias, incluidas en `assets/licenses` y accesibles en Créditos.
