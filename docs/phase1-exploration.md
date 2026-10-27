# Fase 1 — Exploración 0.4.0

## Entrar desde el teléfono

**Otros modos → Mazmorra · 3 pisos** conserva los tres biomas y su progresión.
Cada piso mantiene las ocho salas del generador anterior y añade cuatro ramas:
tienda, evento, secreto y Custodio. Son doce habitaciones, no un reemplazo del
sistema existente. Nueva partida, Incursión y Prueba de reliquias siguen disponibles.

**Otros modos → Elegir semilla** permite escribir un número de 0 a 2147483647.
La semilla se muestra en pausa y en Puertas. Reproduce distribución, ofertas y
recompensas de esta versión; el combate depende también de tus acciones y tiempos.
No se promete que una actualización futura conserve exactamente la misma distribución.

## Salas y acciones

| Sala / elemento | Funcionamiento |
| --- | --- |
| Inicio | Llave física garantizada en un pedestal |
| Combate | Enemigos anteriores, barril rompible y, en algunas salas de pisos posteriores, trampa anunciada |
| Tesoro | Reliquia física, conservando el sistema de recogida e inventario |
| Tienda | Dos reliquias y una llave en pedestales; abre Puertas → Ver tienda para comprar |
| Evento | Palanca que revela un secreto y fuente de curación de un uso |
| Secreto | Oculto en mapa/puertas hasta revelarlo; entrada opcional de una llave y cofre de rareza alta |
| Custodio | Guardián real con barra de vida, dos fases y tres patrones |
| Salida | Encuentro de dificultad creciente; descender exige limpiar la sala y derrotar al Custodio |
| Barril | Recibe daño de proyectiles, deja un objeto físico y conserva el estado destruido |
| Trampa | Avisa 0,8 s y se activa durante 0,45 s de un ciclo de 2,8 s; se congela al pausar |
| Cofre cerrado | Consume una llave una sola vez; después se abre y permite recoger su contenido |

Las compras requieren dinero, nunca se cobran por acercarse. Una oferta pagada
queda disponible sobre el pedestal sin cobrar de nuevo. La llave cuesta cuatro
óbolos; las reliquias cuestan 6 + 3 × rareza. Si ya tienes el máximo de copias,
la compra se desactiva. Stock y pagos permanecen al volver a la habitación.

Los secretos también se descubren disparando a la grieta de una pared adyacente
tras despejar la sala. Sus cerraduras y cofres son opcionales: ninguna llave ni
compra es necesaria para alcanzar al jefe o completar el piso. Cada ampliación
se conecta a la red original de salas sin convertir un secreto en paso obligatorio.

Llaves, ofertas, cofres, fuentes, barriles, recompensas y habitaciones despejadas
conservan estado durante la run. No se añade todavía guardado de runs entre
cierres de aplicación; se mantiene el guardado de ajustes existente.

## Custodio de la Marea

Una nueva criatura original protege cada piso. Usa una escena y un controlador
propios, compartiendo daño, quemadura y ralentización con los enemigos existentes.

- Abanico apuntado: tres disparos; cinco durante la segunda fase.
- Anillo con refugio: deja un arco seguro de 1,1 radianes, señalado en verde.
- Descarga: zona en la posición del jugador con aviso previo antes del daño.

Anuncia el patrón durante 0,75 s. Cambia de fase al 50% de vida, modifica presión
y cadencia y entrega una reliquia de rareza al menos rara. Los veinte enemigos
normales y sus comportamientos se conservan. Este Custodio no equivale a completar
las cinco élites, tres minijefes y tres jefes de la Fase 4: ese contenido sigue pendiente.

## Neris más adorable

Los SVG del protagonista conservan capucha, peinado, gema, ropa, brazos, piernas,
linterna y silueta. Se suaviza el contorno facial y se añaden ojos más grandes,
brillos, mejillas y sonrisa. Las ilustraciones compartidas actualizan el menú,
el personaje y su eco sin cambiar colisiones, estadísticas ni controles.

## Protección, validación y límites

Referencia recuperable: `reference/0.3.1-before-exploration`, commit
`a1e737427285cc97d559b0c179404447afa5ddd7`. Rama nueva `phase1/exploration-0.4`.
La Fase 0 se documenta por separado en `phase0-baseline.md`.

Pruebas locales ejecutadas: 38 de base, 68 de enemigos, 11.981 de pisos,
80 de reliquias, 144 de menú y 19.203 de exploración. La nueva batería comprueba
300 configuraciones ampliadas, rutas sin secretos, puertas simétricas, semillas,
objetos accesibles, llaves, pagos, cofres, fuentes, barriles, trampas, patrones,
daño elemental y finalización programática de los tres pisos. También se ejecutó
con renderizado OpenGL y se revisaron capturas reales del menú, tienda, evento y jefe.

Se conserva el límite de 16 enemigos, 96 proyectiles y 10 zonas. Los nuevos props
son como máximo dos por sala; solo la sala activa instancia nodos y colisiones.
Los perfiles gráficos conservan las señales esenciales de trampas y jefe.
La generación anterior de ocho habitaciones sigue disponible en la API para
compatibilidad y pruebas; el modo Mazmorra usa la ampliación.

Los antiguos tests de descenso ahora verifican su bloqueo y simulan la condición
de jefe derrotado antes de continuar. La nueva batería comprueba por separado
la derrota del jefe a través de daño y señales reales; no se elimina la prueba
de progresión de tres pisos.

## Ensayo de CPU comparable, no medición Android

Se ejecutó `tools/physics_benchmark.gd` con Godot 4.6.3 headless en la referencia
y en esta versión, secuencialmente en el mismo entorno: cinco muestras de
720 pasos, 120 pasos de calentamiento, 16 enemigos y reposición hasta 96 proyectiles.
Se mide el guion de proyectiles y enemigos; no incluye renderizado ni todas
las cargas de una habitación nueva. Los scripts y geometrías de referencia
se extrajeron de la etiqueta sin modificarla.

| Versión | Mediana ms/paso | Rango de cinco muestras |
| --- | ---: | ---: |
| Referencia 0.3.1 | 0,3158 | 0,2754–0,3881 |
| Nueva 0.4.0 | 0,3032 | 0,2657–0,5104 |

La dispersión se solapa y el host es compartido. No se concluye una mejora de FPS,
ni se extrapolan estos valores al ZTE. El diagnóstico opcional y la sala de carga
siguen disponibles para comparar en el dispositivo. El usuario reporta estabilidad
previa en ZTE; la nueva versión necesita pruebas físicas propias.

## Pendiente después de esta fase

Completar 40 objetos (hay 14), activos con recarga, más combinaciones, élites y
jefes distintos, audio, progresión persistente y continuación de runs. No se
publica en tiendas ni se añaden claves de producción. El APK de Actions sigue
siendo de depuración; cambiar su firma puede exigir desinstalar la versión
anterior, lo que borra los ajustes locales.
