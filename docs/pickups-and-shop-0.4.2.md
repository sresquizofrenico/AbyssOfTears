# Entrega A · Recogida y compras · 0.4.2

Esta entrega corrige las interacciones existentes antes de ampliar economía o
personajes. Referencia anterior: `9ba90b2` (0.4.1); rama independiente
`fix/0.4.2-pickups-and-shop`. No cambia precios, rarezas, ingresos ni personajes.

## Investigación y causas comprobadas

Los coleccionables son `Node2D` y utilizan distancia al jugador, no `Area2D` ni
señales `body_entered`/`area_entered`. No había máscaras de áreas desactivadas que
pudieran arreglarse añadiendo una señal. El jugador conserva su círculo de radio
13, capa 2 y máscara 1; paredes, columnas y barriles tienen capa 1. Los pedestales
son dibujos sin collider.

Se reprodujo en 0.4.1 lo siguiente con una tienda real y la semilla 12345:

- Estando junto al producto, con dinero suficiente y estado `playing`,
  `buy_offer(0)` devolvía falso. Solo se podía comprar abriendo Puertas → Ver
  tienda; no existía un botón contextual para el producto físico.
- Desde ese menú, pagar devolvía verdadero, pero `collected` y la posesión del
  objeto seguían en falso. La compra solo retiraba el precio y exigía volver
  a acercarse al pedestal. El jugador podía salir sin recibir el objeto.
- Las compras sin dinero estaban desactivadas y no explicaban el motivo.
- `claim()` marcaba el diccionario como recogido antes de emitir una señal sin
  confirmación de entrega. Una prueba con un ID inválido demostró que podía
  consumirlo incluso con errores al aplicar su efecto.
- El radio automático era 30 px respecto al origen del pedestal, mientras el
  icono flotaba por encima. La colocación solo comprobaba columnas, sin tener
  en cuenta otros premios, barriles o paredes temporales.
- Los tónicos con vida completa esperan deliberadamente; antes no mostraban
  esa explicación. Las cerraduras también requerían llaves sin botón local.

Los fallos anteriores de tienda y entrega se reprodujeron en el entorno. No se
ha identificado ni medido un fallo específico del controlador Android del ZTE;
esa comprobación física sigue pendiente.

## Corrección

Todos los premios dinámicos usan `spawn_pickup`, el mismo callback de entrega
validado y una búsqueda acotada de posición libre. Se comprueban paredes,
columnas, elementos ambientales, otros pedestales y proximidad a puertas. Los
elementos de la habitación se crean antes de colocar sus premios. Las paredes
del Tejedor se reubican cuando bloquearían un premio; su ataque se conserva.

La recogida automática usa posiciones globales y radio 44. Solo se marca
`collected` después de que el coordinador acepte y aplique la recompensa.
Se rechazan duplicados, IDs inválidos, referencias de otra habitación y estados
inactivos. Tónicos con vida completa y llaves al máximo no se pierden.
Las reliquias gratuitas al máximo mantienen la conversión existente de +3 monedas.

Al acercarse a un producto aparece un panel con icono, nombre, descripción,
precio y COMPRAR. No exige abrir el menú de puertas. El botón sigue activo sin
fondos para explicar «MONEDAS INSUFICIENTES». Se reserva el saldo, se entrega el
objeto y se retira una sola vez. Si falla la entrega, se restaura el saldo y el
producto. Una llamada reentrante no puede gastar otra vez el mismo dinero.
La tienda anterior en Puertas también entrega inmediatamente.

Los cofres muestran ABRIR COFRE y su coste de llave cuando corresponde. Mantienen
la apertura por proximidad. La apertura se anima; después se puede recoger su
premio. La cerradura y la recompensa se consumen una sola vez. El panel aparece
entre ambos controles táctiles, se oculta durante la pausa y respeta el rango.

## Pruebas

`tools/validate.py` ejecuta ocho suites, incluyendo
`tests/pickup_interaction_tests.gd` (50 comprobaciones): movimiento con un dedo
mientras se dispara con otro, recogida automática, aplicación de estadísticas,
tónicos, compras baratas/caras/sin fondos, saldo exacto, entrega inmediata,
rechazo de duplicados y compras reentrantes, reversión al fallar la entrega,
tienda antigua, apertura con y sin llave, premios de tesoro y jefe, posiciones
libres, paredes del Tejedor, pausa y tres tamaños de pantalla.

La suite de interacción también se ejecuta con Compatibility/OpenGL Mesa.
Se revisaron capturas reales del motor del panel de compra, el mensaje de fondos
insuficientes y el cofre. Estos resultados no prueban FPS ni instalación en ZTE.

El guardado de opciones no cambia; sus pruebas de escritura, lectura y archivo
dañado siguen ejecutándose. Las compras y cofres permanecen en los diccionarios
de habitación durante la partida; no reaparecen al volver. Todavía no existe
un guardado completo de partida para cerrar la app y continuar después.
No se afirma haber probado compras entre personajes: solo Neris está implementado.

## Prueba en Android

1. Instalar el APK 0.4.2 descargado de GitHub Actions.
2. Iniciar Nueva partida → Neris → COMENZAR.
3. Recoger la llave inicial acercándose; abrir un cofre con y sin llave.
4. Acercarse a un producto: comprobar nombre, descripción y COMPRAR.
5. Sin fondos, pulsar y comprobar el mensaje y el saldo intacto.
6. Con fondos, pulsar varias veces: un cobro, un objeto, efecto e inventario.
7. Salir y volver a la habitación: el producto vendido no debe reaparecer.
8. Recoger un tesoro, un premio de jefe y un tónico después de recibir daño.
9. Moverse y disparar simultáneamente; pausar y reanudar cerca de un cofre.

Próxima entrega: precios progresivos y simulaciones de ingresos/compras. Rarezas,
cofres por categoría y los diez personajes se desarrollarán en entregas posteriores.
