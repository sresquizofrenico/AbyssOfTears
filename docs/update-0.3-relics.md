# 0.3.0 — Reliquias visibles e identidad del faro

## Jugar desde Android

- **Nueva partida** conserva el combate original y añade un pedestal de Cristal
  de Ruptura en el centro-sur de la habitación.
- **Mazmorra · 3 pisos** conserva los ocho cuartos por piso. Los tesoros contienen
  una reliquia física; los combates pueden entregar un pedestal o cofre.
- **Prueba de reliquias** coloca los catorce objetos sobre pedestales o dentro
  de cofres, con un blanco inmóvil que no inflige daño. Recórrelos con el joystick.
- Acércate: el cofre se abre, luego su contenido puede recogerse por proximidad.
  No necesitas abrir inventario ni tocar un botón pequeño.
- **Pausa → Reliquias** muestra iconos, acumulaciones, nombres, rarezas,
  descripciones y estadísticas. Pausa detiene también recogidas y efectos.

La recogida eleva y desvanece el icono, aplica el efecto una sola vez y muestra
nombre/descripción/icono durante 2,8 segundos. Las reliquias se conservan entre
salas y pisos; las recogidas no reaparecen al revisitar. Reiniciar las elimina.
No se ha añadido guardado de runs entre cierres: se mantiene el guardado de ajustes.

## Catorce efectos funcionales

| Reliquia | Efecto y acumulación máxima |
| --- | --- |
| Cristal de Ruptura | +0,35 daño; 3 copias |
| Doble Eco | Dos proyectiles paralelos; 1 |
| Corazón Ígneo | Quemadura durante 3 s, pulsos de 0,3 cada 0,6 s; 1 |
| Lágrima Glacial | Velocidad de enemigos reducida 40% durante 2 s; 1 |
| Núcleo Eléctrico | Cada tercer impacto salta a otro enemigo a menos de 150 unidades, con 60% de daño; 1 |
| Fragmento del Vacío | Atraviesa un enemigo; cada objetivo se daña una vez por proyectil; 1 |
| Esfera de Rebote | Un rebote contra paredes/pilares/obstáculos temporales; 1 |
| Corona de Espinas | Dos proyectiles oblicuos adicionales; 1 |
| Guardián Orbital | Esfera que gira y destruye proyectiles enemigos cercanos; 1 |
| Espejo Fragmentado | Eco visible que dispara durante 3 s de cada ciclo de 10 s; 1 |
| Escudo Lunar | Bloquea un impacto, con recarga de 8 s; 1 |
| Corazón de Cristal | +1 vida máxima y cura un punto; 2 |
| Botas Espectrales | +20 velocidad; 2 |
| Reloj Fracturado | -0,03 s de intervalo entre disparos; 2 |

Los modificadores se componen al crear el proyectil. Doble Eco, Corona y Espejo
producen como máximo doce disparos por ataque y respetan el presupuesto global
de 96. Cada uno conserva fuego, hielo, electricidad, perforación y rebote.
La electricidad no crea proyectiles ni vuelve a invocar impactos elementales:
no hay cadenas recursivas. Quemadura y hielo se renuevan, no acumulan instancias.
Una reliquia por encima de su límite se convierte en tres óbolos.

El catálogo usa IDs, categoría, descripción, rareza, icono, modificadores y
límites. No se afirma que existan los cuarenta objetos del plan anterior:
esta entrega incorpora catorce con implementación real.

## Aparición y cofres

`RelicCatalog.DROP_SETTINGS` configura 45% de recompensa adicional al limpiar un
combate y 50% de cofres frente a pedestales. Cada tesoro garantiza un objeto.
Un cofre contiene una reliquia (50%), cinco monedas (30%) o un tónico de curación
(20%). El tónico cura hasta dos puntos y no se recoge automáticamente con vida
completa. La sala de prueba garantiza los catorce objetos, sin sorteos.

Cinco rarezas: común, poco común, raro, épico y legendario. Los pesos base por
objeto son 50/28/14/6/2; pisos posteriores aumentan moderadamente los pesos de
rarezas altas. El sorteo usa la semilla del piso y habitación. Posiciones
corregidas evitan paredes y pilares. Los cofres abiertos y recogidos conservan
su estado durante la run. No hay jefes todavía: sus recompensas quedan pendientes.

## Arte y animación

Se incluyen SVG originales para Neris, los veinte enemigos, catorce iconos,
cofre, pedestal, monedas, tónico, columnas, puertas y suelo de piedra.
Los enemigos muestran anatomía y equipamiento según su comportamiento: insectos
blindados, ojo, larvas, murciélago, araña, urna, invocador, cristal y espectros.
Las colisiones conservan su geometría anterior.

Neris tiene torso/rostro ilustrados, brazos y piernas animados por dibujo,
linterna, reposo, caminar, disparar, daño, recogida y transiciones de victoria y
derrota. El menú reproduce una escena independiente de Neris y un invocador;
no utiliza ni modifica los datos de la partida.

La interfaz incluye iconos y panel de inventario desplazable. Las animaciones
de muerte de enemigos y las descargas usan efectos con presupuesto acotado.
Las capturas revisadas provienen de Godot con OpenGL/Mesa en el entorno, no del ZTE.

## Rendimiento y diagnóstico

- Conserva Compatibility, ARM64, 960 × 540 y perfiles Bajo/Medio/Alto.
- Sin luces dinámicas ni shaders nuevos. Brillos y sombras simulados; Bajo
  reduce decoración sin modificar daño, colisiones ni señales de peligro.
- Texturas importadas compartidas/caché; sin nodos para cada detalle anatómico.
- El suelo se dibuja con una textura repetida en vez de más de cien rectángulos.
- Lista de objetivos copiada una vez por fotograma, no por muestra de trayectoria.
- Cohesión de larvas consulta solo la lista de enemigos, no todos los nodos.
- Máximos: 16 enemigos, 96 proyectiles, 10 zonas y 8 descargas visibles.
- No se introduce pooling sin una medición que justifique su complejidad;
  los proyectiles siguen teniendo alcance y eliminación acotados.

**Opciones → Diagnóstico FPS** activa FPS, enemigos, proyectiles, partículas/FX
y tiempo de física. Se actualiza dos veces por segundo y guarda la preferencia.
**Pausa → Prueba de carga (nueva)** sustituye la run por una sala con los
presupuestos máximos de enemigos y disparos. No es un benchmark automático ni
una medida del ZTE. No se prometen 60 FPS sin medirlos en ese dispositivo.

## Validación

Ejecutadas localmente: 38 comprobaciones originales, 68 de enemigos, 11.977 de
pisos y 80 de reliquias. Se verifican recogida por proximidad, apertura de cofre,
consumo único, pesos de rareza, límites, composición, quemadura, ralentización,
cadena eléctrica, rebote real, perforación, escudo, orbital, persistencia entre
salas, reinicio, monedas, curación y presupuestos de la prueba de carga.

Importación, rutas, scripts y pruebas se vuelven a ejecutar en GitHub Actions
antes de exportar el APK 0.3.0, versionCode 4. Instalación, tacto físico y
rendimiento en Android siguen pendientes de comprobación en el ZTE 8050.
