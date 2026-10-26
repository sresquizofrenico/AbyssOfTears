# Publicar el prototipo en GitHub desde Android

El APK local está verificado. Descargarlo desde el entorno temporal ha agotado
el tiempo de lectura; la entrega prevista será un artefacto de GitHub Actions.

## Bloqueo comprobado

La cuenta reconocida es `sresquizofrenico`. La credencial disponible permite
ver `opencut-classic`, que corresponde a otro proyecto. No se han publicado
archivos del juego allí ni se han cambiado sus contenidos.

Se intentó crear el repositorio público `sresquizofrenico/AbyssOfTears` mediante
GitHub CLI y se recibió **HTTP 403: Resource not accessible by integration**.
La integración no permite crear repositorios con esta credencial. No se trata
de un fallo del APK ni de una ejecución fallida de Actions.

## Acciones necesarias en el teléfono

1. Abre https://github.com/new e inicia sesión en `sresquizofrenico`.
2. En **Repository name**, escribe **AbyssOfTears**.
3. Selecciona **Public** y activa **Add a README file**. Deja sin añadir otra
   licencia ni gitignore: Codex ya ha preparado esos archivos.
4. Pulsa **Create repository** y copia el enlace que aparece en el navegador.
5. En Codex, abre el selector de repositorios y pulsa **Configure repositories**
   si el repositorio nuevo no aparece. En la autorización de GitHub, elige
   **Only select repositories**, añade **AbyssOfTears** y pulsa **Save**.
6. Si no aparece ese acceso, abre https://github.com/settings/installations,
   pulsa **Configure** en la integración utilizada por Codex y añade el nuevo
   repositorio a **Repository access**. Si ya tiene **All repositories**, no
   necesitas cambiarlo. El nombre exacto de la integración depende de cuál
   hayas conectado.
7. Facilita el enlace del repositorio en esta conversación para que Codex
   compruebe el acceso y publique el proyecto.

No compartas contraseñas ni tokens. No necesitas descargar ni subir el APK,
editar código, usar una terminal ni instalar Godot.

## Qué hará Codex después

Con acceso de escritura al repositorio, Codex publicará el proyecto en una rama,
abrirá un pull request y revisará la compilación automática. El workflow Android
se ejecuta en pull requests, cambios a `main`/`master` y manualmente. El APK se
sube mediante `actions/upload-artifact` como **AbyssOfTears-Android-Debug**.

Codex proporcionará el enlace de la ejecución únicamente cuando esta exista y
confirmará el resultado y el artefacto. La presencia de los YAML por sí sola no
demuestra que GitHub haya ejecutado la compilación.

Una vez generado: **Actions → ejecución correcta → Artifacts →
AbyssOfTears-Android-Debug**. Extrae el ZIP en Archivos de Android e instala
**AbyssOfTears-debug.apk**.
