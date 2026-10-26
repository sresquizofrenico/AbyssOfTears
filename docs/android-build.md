# Compilar y descargar desde Android

## Qué configura Codex

El proyecto debe quedar en la raíz del repositorio: `project.godot` y `.github`
deben estar al mismo nivel. No debe quedar dentro de otra carpeta `AbyssOfTears`.
Los workflows se ejecutan sobre `main` o `master`; también se pueden lanzar
manualmente una vez incorporados a la rama predeterminada.

- `Validate Godot project`: importación, integridad de referencias,
  escena principal, arranque y pruebas de comportamiento. Se ejecuta además en PR.
- `Build Android Debug APK`: instalación de herramientas, validación, exportación,
  comprobación de firma y empaquetado ARM64, y subida del APK como artefacto.

No se necesitan secretos, tokens añadidos ni permisos de escritura. Los jobs
usan `contents: read`. El repositorio público evita depender de la cuota privada
de minutos de Actions, sujeto a las condiciones vigentes de GitHub.

## Herramientas verificadas

- Runner `ubuntu-24.04`.
- Godot **4.6.3-stable**, editor Linux x86_64 y plantillas **4.6.3.stable**.
  Descargas oficiales verificadas por SHA-256 en `tools/install_godot.py`.
- Java Temurin **17.0.21+9**, configurado por `actions/setup-java`.
- Android command-line tools **19.0**, archivo oficial
  `commandlinetools-linux-13114758_latest.zip`; pese al sufijo del nombre,
  la descarga está fijada por identificador y SHA-256.
- SDK platform **36**, build-tools **36.0.0**, platform-tools.
- APK estándar mediante plantilla precompilada: no usa Gradle, NDK ni CMake.

La documentación de la rama Godot 4.6 enumera herramientas antiguas para algunos
componentes; el código de exportación de **4.6.3-stable** establece target SDK 36.
Se contrastaron ambos y se usa build-tools 36 para coincidir con la plantilla.
El mínimo Android lo determina la plantilla y se comprueba que sea <= 33.
También se verifica ARM64 y ausencia del permiso INTERNET.

Referencias oficiales:

- https://github.com/godotengine/godot/releases/tag/4.6.3-stable
- https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_android.html
- https://github.com/godotengine/godot/blob/4.6.3-stable/platform/android/export/export_plugin.cpp
- https://dl.google.com/android/repository/repository2-1.xml

Las opciones `--headless`, `--import`, `--quit-after` y `--export-debug` se
comprobaron con `godot --help` de la versión fijada. Se utiliza
`godot --headless --path <proyecto> --export-debug Android <archivo.apk>`.

## Firma y configuración

El workflow genera una clave RSA de depuración efímera en `RUNNER_TEMP`, alias
`androiddebugkey`, contraseña estándar de depuración `android`. Solo se sube el
APK, nunca la clave. Las contraseñas de depuración son públicas por diseño;
esto no configura una firma de producción.

El script establece los ajustes de editor Android y Java en el directorio de
configuración de Godot del runner. Las variables
`GODOT_ANDROID_KEYSTORE_DEBUG_PATH`, `GODOT_ANDROID_KEYSTORE_DEBUG_USER` y
`GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD` son las admitidas por Godot.
El workflow acepta las licencias oficiales del SDK para instalar herramientas.

No necesitas crear variables ni secretos desde GitHub. Si Actions está
deshabilitado, entra en **Settings → Actions → General**, permite GitHub Actions
y las acciones oficiales `actions/checkout`, `actions/setup-java` y
`actions/upload-artifact`. Una política de organización puede requerir que su
administrador habilite estas acciones.

## Descargar en el ZTE 8050

1. Abre tu repositorio en GitHub e inicia sesión.
2. Pulsa **Actions → Build Android Debug APK → Run workflow → Run workflow**.
3. Espera el resultado verde y abre la ejecución.
4. Baja a **Artifacts** y pulsa **AbyssOfTears-Android-Debug**.
5. Descarga y extrae el ZIP en Archivos.
6. Pulsa **AbyssOfTears-debug.apk** y permite instalar desde esa fuente si Android
   lo solicita. No necesitas activar depuración USB ni opciones de desarrollador.
7. Abre el juego y sigue la lista de pruebas del teléfono.

Si una actualización muestra conflicto de firma, desinstala primero la versión
anterior. Las claves nuevas de cada ejecución no sirven para actualizar una
instalación con otra firma. La desinstalación borra los ajustes locales.

## Si falla

Abre el paso rojo y consulta su registro. La validación trata como errores los
mensajes de GDScript y recursos incluso si Godot devuelve código cero.
Un fallo de descarga no demuestra un fallo del juego: vuelve a ejecutar el job.
Un workflow rojo no produce una entrega confirmada; no se debe instalar un
archivo de una ejecución anterior creyendo que corresponde a la fallida.

Los artefactos caducan tras 14 días; vuelve a ejecutar el workflow para regenerar
el APK. Si se agota alguna cuota o una política bloquea Actions, no contrates un
servicio: revisa la configuración del repositorio y comunica el mensaje a Codex.
