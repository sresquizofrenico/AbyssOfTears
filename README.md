# Abyss of Tears

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

El proyecto y los scripts de validación/exportación existen y se ejecutan en
el entorno de desarrollo. Consulta [los resultados](docs/validation-results.md).
Los workflows están preparados; **no se han ejecutado en GitHub**, porque aún
no hay un repositorio remoto conectado. No existe enlace a un artefacto de
Actions. Un APK generado en el entorno no equivale a una ejecución de Actions.

No se da por finalizada la entrega completa hasta comprobar Actions y el
artefacto. La instalación y el multitáctil físico en el ZTE también están
pendientes. Las pruebas automatizadas inyectan eventos táctiles en Godot;
no sustituyen las pruebas de pantalla real.

## Solo necesitas tu teléfono

No instales Godot, Android Studio, Termux ni herramientas de compilación.

1. Abre GitHub en el navegador y crea un repositorio público vacío llamado
   `AbyssOfTears` (sin README inicial).
2. Conecta ese repositorio a Codex y facilita su enlace. Codex podrá incorporar
   este proyecto; no necesitas copiar ni editar código manualmente.
3. Cuando los archivos estén incorporados a `main`, abre **Actions**.
4. Selecciona **Build Android Debug APK** y pulsa **Run workflow**.
5. Espera a que termine en verde y abre esa ejecución.
6. En **Artifacts**, descarga **AbyssOfTears-Android-Debug**.
7. Abre el ZIP con Archivos de Android y extrae **AbyssOfTears-debug.apk**.
8. Pulsa el APK. Si Android lo pide, autoriza instalar aplicaciones desde
   esa fuente y vuelve al archivo para instalarlo.

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
