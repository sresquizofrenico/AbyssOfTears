# Arquitectura de la fase 1

## Estados y escenas

`scenes/main.tscn` instancia `game.gd`. Sus estados son menú, partida, pausa,
opciones, créditos, victoria y derrota. El mundo se elimina al abandonar o
reiniciar una partida; no se acumulan enemigos, proyectiles ni controles.
El CanvasLayer de interfaz se conserva. Al pausar se desactiva el procesamiento
del mundo y se limpian todos los dedos; perder foco también pausa.

La habitación construye sus paredes y pilares como StaticBody2D. El personaje
y los enemigos son CharacterBody2D con capas separadas: escenario 1, jugador 2,
enemigos 4. El contacto con enemigos inflige daño por distancia; el escenario
se resuelve con `move_and_slide()`.

El espacio jugable se mantiene en 960 × 540 y se centra en pantallas más anchas.
La interfaz usa el viewport lógico expandido, con controles anclados a los lados.
Se evita depender de píxeles físicos o de la densidad del dispositivo.

## Interfaces de ampliación

- `ActorStats`: vida, daño, velocidad, cadencia, alcance, velocidad de proyectil,
  defensa, suerte y probabilidad de efectos. `modify(Dictionary)` admite solo
  campos numéricos conocidos y limita valores; los modificadores de objetos se
  integrarán aquí en la fase 2.
- Jugador: señales `shot(origin, direction, stats)`, `health_changed` y `died`.
  El intervalo de ataque se expresa en segundos, el alcance en unidades lógicas.
- Enemigo: tipo exportado, objetivo, daño y señales `shot` / `defeated`.
  Los tipos comparten presentación y ciclo de vida; los futuros jefes tendrán
  controladores específicos en vez de añadir todas sus fases a este script.
- Proyectil: dirección, velocidad, daño, alcance restante y facción. Se mueve
  con delta y comprueba el trayecto con muestras de hasta 5 unidades para evitar
  atravesar pilares o enemigos. Presupuesto global: 96. Se elimina al impactar,
  agotar alcance o salir del mundo. No hay proyectiles infinitos.
- Controles: un dedo de movimiento y diccionario de dedos de ataque. El último
  botón sostenido elige una dirección cardinal; al soltarlo se recupera otro
  sostenido. Un dedo no puede controlar a la vez joystick y ataque.
- Ajustes: JSON versión 1 en `user://settings.json`, validación de tipos y rangos,
  recuperación de datos dañados y escritura temporal con renombrado. Todavía no
  existe formato de guardado de partidas ni botón Continuar.

## Rendimiento y recursos

La habitación se vuelve a dibujar continuamente solo en Alto. Bajo elimina
ondas decorativas, halos y partículas de muerte. Medio limita partículas;
Alto permite más y anima ondas. Las señales de ataque del tirador permanecen en
todos los perfiles porque forman parte de la jugabilidad.

No hay texturas descargadas, shaders costosos ni partículas sin límite.
El arte usa dibujo 2D e icono SVG. La configuración y los recursos viven dentro
del APK; no se solicita permiso de Internet. Créditos incluye las licencias
del motor y sus componentes.

## Límites deliberados

Esta entrega valida una habitación y tres tipos de enemigos. No hay todavía
arquitectura completa de inventario, serialización de runs, generación de pisos,
centenares de objetos ni promesa de 60 FPS sin medir en el teléfono.
La siguiente fase debe mantener primero las pruebas actuales, después añadir
un grafo conectado de 6–12 habitaciones, semillas reproducibles y pruebas de
accesibilidad antes de ampliar el contenido.
