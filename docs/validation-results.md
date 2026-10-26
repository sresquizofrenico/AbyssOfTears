# Resultados verificados — fase 1

Fecha UTC: 2026-10-26 16:56.

## Ejecutado en el entorno de Codex

| Comprobación | Resultado |
| --- | --- |
| Descarga del editor y plantillas oficiales; SHA-256 | Correcto, Godot 4.6.3 estable |
| Importación, scripts, referencias y escena principal | Correcto |
| Arranque de escena principal en headless | Correcto |
| Pruebas de comportamiento en headless | **38 comprobaciones, 0 fallos** |
| Mismas pruebas con OpenGL Compatibility / Mesa llvmpipe | **38 comprobaciones, 0 fallos** |
| Capturas de menú, habitación y opciones | Generadas y revisadas |
| Sintaxis de workflows, actionlint 1.7.12 | Correcto |
| Exportación con Temurin 17.0.21+9 y build-tools 36.0.0 | Correcto |
| ZIP del APK, manifiesto, bibliotecas y tamaño | Correcto |
| Firma comprobada con apksigner | **v2 y v3 válidas** |
| Paquete / ABI | `org.abyssoftears.game` / `arm64-v8a` |
| Android mínimo / objetivo | API **24** / API **36** |
| Permiso de Internet | Ausente |
| Licencias del motor dentro del APK | Presentes |
| Archivos de tests/herramientas dentro del APK | Excluidos |

APK: `build/AbyssOfTears-debug.apk`, **27,728,688 bytes**.

SHA-256:

```text
420672b6b1ee99f96663e8d8781d34776470551c01ab5dbd700085f61f312a61
```

Las pruebas cubren recuperación de JSON dañado, guardado y recarga, límites de
estadísticas, menús y créditos, movimiento y ataque con dedos simultáneos,
normalización diagonal, orden de liberación de dedos, pausa, cadencia,
invulnerabilidad, barra de vida, colisiones de paredes y proyectiles, alcance,
recompensas, victoria, derrota, reinicio, pérdida de foco, límite de proyectiles,
pantallas anchas y controles al tamaño máximo. También se ejercitaron los tres
perfiles gráficos. Las capturas proceden de Godot renderizando el proyecto;
no son una simulación dibujada aparte.

El servidor gráfico virtual avisa que no permite cambiar V-Sync. Esto no impide
las pruebas y no mide el rendimiento del teléfono. Se utilizó software Mesa
para renderizar; no se afirma equivalencia con la GPU del ZTE.

## Pendiente, no confirmado

- Publicación del proyecto y commit en un repositorio de GitHub accesible.
- Ejecución real de ambos workflows y artefacto alojado en GitHub Actions.
- Instalación del APK en el ZTE 8050, pantalla táctil física y Android 13.
- Medición de FPS, memoria, consumo y temperatura en el teléfono.

Por tanto, el prototipo está implementado y exportado localmente, pero los
criterios completos de entrega de la fase 1 siguen pendientes de GitHub y de
las pruebas del dispositivo. No existe un enlace real a una ejecución de Actions.

## Reproducir en el entorno de desarrollo

`python3 tools/validate.py` ejecuta las comprobaciones headless. La exportación
se hace con `python3 tools/export_android.py` y las variables documentadas en
`android-build.md`. Estos comandos son para Codex y el runner, no para el teléfono.

![Habitación del prototipo](images/gameplay.png)
