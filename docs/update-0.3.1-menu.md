# 0.3.1 — El guardián del faro: menú cinematográfico

## Qué se ve al abrir

Introducción de 6,5 segundos: oscuridad, iluminación azul gradual, entrada de
Neris caminando, mirada, criatura de sombra, proyectil luminoso y disolución en
partículas. El título y los botones aparecen gradualmente al final. Un toque,
una pulsación de ratón o una tecla permiten omitirla. La pulsación que omite
no selecciona accidentalmente un botón; hay una breve protección de entrada.
La introducción se reproduce una vez por apertura de la aplicación, no cada
vez que vuelves al menú durante esa sesión.

Después, Neris alterna caminar, observar, practicar ataques, esquivar una sombra,
descansar y mirar un cristal flotante. Movimiento y mirada se interpolan. La
habitación utiliza los recursos originales del juego, sombras dibujadas y
brillos azul/violeta, sin luces dinámicas ni física de combate.

## Botones reales y funciones pendientes

- **Nueva partida:** Neris corre hacia la puerta. En 0,45 s se inicia el combate
  original. La reacción no bloquea la interfaz más tiempo ni permite duplicar
  acciones con pulsaciones simultáneas.
- **Continuar · Sin partida:** desactivado. El juego guarda ajustes, pero aún no
  tiene un formato de guardado compatible de runs; no se simula una carga.
- **Personajes · Próximamente:** desactivado. No hay sistema de selección todavía.
- **Colección · Próximamente:** desactivado. No hay registro persistente de hallazgos.
- **Opciones:** Neris mira el objeto flotante y se abre la configuración tras
  0,18 s. Siguen disponibles gráficos, controles y diagnóstico. Se indica que
  el audio todavía no está implementado.
- **Créditos:** mira hacia el título y se muestran las licencias existentes.
- **Otros modos:** conserva Mazmorra · 3 pisos, Incursión de enemigos y Prueba
  de reliquias, que antes ocupaban botones individuales en el menú principal.
- **Salir:** cierra mediante SceneTree.quit en las plataformas que lo permiten;
  se desactiva si se exporta para navegador. El cierre real de Android queda
  pendiente de prueba física. La acción de salida sí se verifica automáticamente.

Android Atrás deja de cerrar automáticamente la aplicación: se conserva la
lógica de pausa/reanudación durante el juego. Durante la introducción permite
omitirla; en créditos y selección de modos vuelve al inicio.

## Arquitectura y rendimiento

`scenes/ui/main_menu.tscn` contiene un controlador de interfaz independiente.
`menu_intro.gd` define la línea temporal. `menu_character.tscn` dibuja a Neris
con el torso original y extremidades animadas. `menu_backdrop.gd` solo controla
la escena decorativa y sus efectos. No instancia AbyssPlayer/AbyssEnemy ni
accede a estadísticas, inventarios o archivos de guardado.

La escena de menú envía acciones al coordinador del juego; las pantallas de
combate, objetos, pisos, pausa y opciones conservan sus controladores existentes.
Las transiciones pendientes se cancelan al retirar la escena del árbol. La
escena decorativa deja de procesarse al iniciar una partida. Menú e introducción
se suspenden al perder foco o al pasar la aplicación a segundo plano.

- Partículas ambientales fijas: Bajo 4, Medio 10, Alto 18.
- Disolución de sombra: 6 partículas en Bajo, 12 en Medio/Alto; sin acumulación.
- Como máximo un protagonista y una criatura decorativa; los proyectiles son
  dibujos analíticos reutilizados, sin nodos que se acumulen.
- Recursos SVG/Texture2D compartidos con el juego; ninguna dependencia externa.
- Un Tween breve por botón como máximo para sus cambios de selección/pulsación.
- No se actualiza la interfaz de introducción continuamente una vez terminada.

## Android y comprobaciones

Panel de botones separado del área del personaje, con objetivos táctiles de
al menos 44 unidades lógicas. Ajuste a 960 × 540, 1280 × 540 y 960 × 600.
En Android se consulta la zona segura para ajustar los márgenes; esta llamada
es específica de Android y su resultado debe comprobarse en el ZTE.

Ejecutadas localmente las pruebas previas y **144 nuevas comprobaciones** del
menú: inicio oscuro, duración/fases, omisión táctil, protección frente a selección
accidental, funciones desactivadas, tamaños/solapamiento, despacho real de GUI,
opciones, créditos, reacciones, acciones ambientales, perfiles, arranque de
partida, modos existentes y salida mediante señal. Se revisaron capturas reales
OpenGL de la entrada, el ataque y los menús normal y ancho.

El rendimiento y tacto reales en el ZTE 8050, la zona segura y el cierre de la
actividad Android permanecen pendientes de prueba física. No se prometen FPS
medidos en el teléfono. GitHub Actions vuelve a validar antes de generar el APK
0.3.1 ARM64, versionCode 5.
