# Publicación preparada para GitHub

Repositorio: https://github.com/sresquizofrenico/AbyssOfTears

Rama local de entrega: `delivery/android-apk`, basada en el README inicial de
`main`. El historial del prototipo está preparado sin modificar las mecánicas.

El repositorio existe y se puede leer, pero el envío por Git y la creación de
rama mediante la API han recibido **HTTP 403: Resource not accessible by
integration**. La cuenta es propietaria del repositorio; la autorización que
recibe esta sesión no permite crear referencias ni publicar los archivos.
No se ha creado todavía el pull request ni una ejecución de Actions.

Antes de continuar, revisa la autorización de la integración en
https://github.com/settings/installations: configura la integración usada por
Codex, incluye `AbyssOfTears` y guarda. Si GitHub muestra una actualización de
permisos solicitados, revísala para permitir publicar contenidos/workflows y
operar Actions. Si el repositorio ya está incluido, renueva la conexión de
GitHub en Codex. No basta con que tu cuenta tenga permisos de administrador.

Una vez autorizada la escritura, el pull request permitirá revisar la entrega
y obtener el APK antes de fusionar.

## Descargar desde Android

1. Abre https://github.com/sresquizofrenico/AbyssOfTears/actions e inicia sesión.
2. Abre la ejecución **Build Android Debug APK** de la rama `delivery/android-apk`.
3. Espera a que termine en verde. Si falla, no hay una entrega confirmada;
   comunica a Codex el primer paso rojo.
4. En **Artifacts**, pulsa **AbyssOfTears-Android-Debug**.
5. Extrae el ZIP en Archivos de Android e instala **AbyssOfTears-debug.apk**.
6. Autoriza instalar aplicaciones desde esa fuente si Android lo solicita.

Si la pantalla del navegador oculta los controles, activa «Sitio para
ordenadores». No es necesario instalar herramientas de desarrollo ni utilizar
una computadora. Los artefactos caducan tras 14 días.

## Ejecuciones y permisos

El workflow compila en pull requests, actualizaciones de `main`/`master` y
manualmente. La ejecución manual requiere que el workflow ya exista en la rama
predeterminada. Mientras el PR siga abierto, un cambio en su rama vuelve a
compilar automáticamente.

La creación inicial del repositorio mediante la integración recibió HTTP 403.
El usuario creó el repositorio desde Android y habilitó su acceso. Este bloqueo
inicial no implica un fallo del juego ni del APK.

El job usa permisos `contents: read` y una firma efímera de depuración.
`actions/upload-artifact` sube exclusivamente `build/AbyssOfTears-debug.apk`.
No necesitas añadir secretos ni compartir contraseñas o tokens.
