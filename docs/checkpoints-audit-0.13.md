# Auditoría inicial 0.13 · puertas y continuación

Referencia: e724ced (0.12.0), etiqueta reference/0.12.0-before-checkpoints, rama fix/0.13-door-checkpoints.

| Sistema auditado | Estado al comenzar |
| --- | --- |
| Entrada a habitaciones | Error confirmado: `start_game()` fuerza (480,390), `travel_to()` no transmite dirección |
| Progreso, diario, desbloqueos | Implementados con formato v4 y escrituras temporales; pruebas existentes |
| Expedición en curso y CONTINUAR | No implementados; no confundir con el progreso permanente |
| Personajes | Veinte reales, incluidos los nueve Vínculos y Shader. No hay 32 personajes |
| Pisos y jefes | Tres pisos reales y tres jefes; doce son una propuesta pendiente |
| Tiendas, cofres y recogida | Ruta común de entrega y protección contra duplicación existente; se comprobará al cargar |
| Arte | SVG original y animación por transformaciones; no existen sprites anime finales en cuatro direcciones |
| Audio, opciones, tacto | Existentes; se conservan |
| Android | Godot 4.6.3, Compatibility, ARM64, CI de validación/exportación/publicación |

La entrega prioriza transición y persistencia de la campaña. Los desafíos independientes mantienen su progreso permanente y se reintentan desde su inicio. La modalidad pública conserva personajes originales. Las referencias de anime se documentan como fichas privadas, sin imágenes oficiales ni alias activados en APK público.

## Resultado de la entrega

| Área | Resultado comprobado |
| --- | --- |
| Puertas | Corregidas en cuatro direcciones, `Marker2D` interior por conexión, traza origen/destino/ID/direcciones, posición segura, orientación interior, protección 0.8 s y fundido 0.24 s |
| Expedición | Nuevo snapshot v1 separado del progreso v4; vida, estadísticas, objetos, dinero, llaves, RNG, recargas, estados, enemigos, jefes, proyectiles, impactos ya consumidos, peligros, cofres, máquinas y sala/piso |
| Persistencia | JSON con checksum, esquema validado, temporal y reemplazo atómico, respaldo, trabajador de disco y cola coalescida. Al terminar/morir se invalidan principal y respaldo |
| CONTINUAR | Solo con snapshot compatible; restaura en pausa, conserva daño y recompensas, reposiciona con seguridad si el punto guardado es peligroso |
| Momento de guardado | Inicio/cambio de sala, fin de combate, bajas, recogidas, compras/cofres, daño y habilidades; además cada cinco segundos y al perder foco/pausar/salir/al menú. Antes de descender se espera el guardado correcto |
| Progreso permanente | Se conserva v4, desbloqueos, diario y desafíos. IDs estables de enemigos evitan contar una baja de nuevo al recuperar una partida |
| Opciones | Audio y gráficos se guardan al dejar de mover controles; personaje elegido y respaldo de configuración añadidos |
| Respaldo portátil | AOT5 incluye progreso y expedición, importa AOT1–AOT4. No es guardado en la nube y una versión vieja no lee AOT5 |
| Arte y personajes | Veinte conservados, nueve vistas traseras SVG nuevas, tres murales de suelo, giros y animación ligera; arte final anime completo pendiente |
| Referencias | Nueve fichas textuales privadas, nombres originales solo mediante argumento del editor de escritorio. Excluidas del APK, sin sprites oficiales |
| Yura | Evasión inicial breve, registro de ataques reales y una evitación fatal durante Visión con recarga de 90 s, serializada |
| Campaña de doce pisos | Pendiente; tres pisos y sus jefes conservados |

## Evidencia de pruebas

`python3 tools/validate.py`: 26 ejecuciones de suites Godot (incluye los modos público/privado por separado) y 14 pruebas Python del publicador correctas. Cada suite usa datos de usuario aislados para que una partida guardada por otra suite no altere su menú.

- `checkpoint_tests.gd`: 3.054 comprobaciones. Direcciones sobre doce semillas y tres pisos, marcadores, navegación real a comercio/tesoro/secretos/jefes, retorno, compra y cofre persistentes, combate serializable, RNG, corrupción, error de escritura y muerte.
- `durability_tests.gd`: 139 comprobaciones. Los veinte héroes, vida/recargas/objetos, peligros, jefe derrotado sin reaparición, descensos, suspensión, guardado periódico, CONTINUAR con eventos táctiles, configuración y copia portátil AOT5.
- `presentation_tests.gd`: 51 comprobaciones en cada modo. Alias solo en editor privado, catálogo original intacto, codec de vectores/Unicode y rechazo silencioso de datos inválidos.
- Regresiones de menús, compras, cofres, economía, diario, arqueología, habilidades, controles y audio existentes ejecutadas. Las pruebas de selección se actualizan para confirmar antes de reemplazar una expedición.
- Durabilidad ejecutada también con Compatibility/OpenGL en Mesa de escritorio. Capturas reales en `docs/previews/*0.13.png`, no capturas del teléfono ni renders de referencia.

El punto de partida 0.12.0 cuenta con CI público correcto (ejecución 40531923674). La primera corrida local de referencia se interrumpió durante la edición; no se declara una nueva corrida completa de baseline. La regresión completa de la entrega sí se ejecutó después.

## Límites

No se han medido FPS ni memoria física en el ZTE. Una terminación sin aviso puede perder los últimos segundos no escritos; la carga usa el último snapshot íntegro o su respaldo. Las pruebas independientes conservan logros, pero se reintentan desde su inicio: CONTINUAR corresponde a la campaña de tres pisos. No hay sincronización entre dispositivos.

La restauración puede mover al personaje a un punto cercano libre y concede 0.65 s de protección; no restaura vida ni recargas. Los efectos puramente decorativos de daño/fundido no se serializan. Guardar grandes cantidades de datos o fallos de almacenamiento se informa; el guardado normal de disco ocurre en un trabajador, con espera únicamente en límites de ciclo de vida/descenso.

Antes de actualizar o reinstalar, conservar el código fuera del dispositivo de instalación. Las firmas de depuración de CI siguen siendo efímeras. No se anuncia un APK final de 100 MB ni arte anime definitivo.
