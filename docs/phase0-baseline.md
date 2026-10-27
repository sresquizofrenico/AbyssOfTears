# Fase 0 — Referencia protegida antes de explorar

Referencia: `a1e737427285cc97d559b0c179404447afa5ddd7` (0.3.1).
Etiqueta de recuperación: `reference/0.3.1-before-exploration`.
Rama de mejoras: `phase1/exploration-0.4`. No se modifica `main` ni se fusionan PR.

Se inspeccionaron escenas, scripts, catálogo, recursos, dependencias y workflows.
La escena principal es `scenes/main.tscn`; Godot es 4.6.3 con Compatibility.
Los scripts de exportación comprueban importación, errores, ABI ARM64, permiso
INTERNET ausente, tamaño del APK y firma v2/v3.

La referencia conserva veinte enemigos normales, tres pisos de ocho habitaciones,
14 reliquias físicas, cofres, estadísticas, combate compuesto, controles
multitáctiles, menú cinematográfico y guardado versionado de ajustes. No hay
continuación de runs, logros, colección persistente, selección de personajes ni
audio. No se asumen implementados los cuarenta objetos de fases posteriores.

Validación repetida antes de modificar: 38 comprobaciones originales, 68 de
enemigos, 11.977 de pisos, 80 de reliquias y 144 del menú, sin fallos.
`git fsck --full` no mostró corrupción; el árbol colgante es un resto no referenciado
de operaciones Git anteriores, no un archivo del juego ni un defecto del proyecto.

Compilación de la referencia comprobada en GitHub:
https://github.com/sresquizofrenico/AbyssOfTears/actions/runs/40381106892
Estado success, SHA de cabecera igual a la referencia y artefacto generado.

El usuario reporta pruebas físicas, estabilidad y optimización en ZTE 8050.
Ese reporte se conserva como tal. En el entorno no hay un ZTE conectado ni un
registro comparable de FPS/memoria; no se infieren cifras ni mejoras medidas.

Para recuperar, Codex puede abrir una rama desde la etiqueta indicada y generar
otro APK con los workflows existentes, sin usar terminal en el teléfono.
