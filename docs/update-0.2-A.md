# 0.2 — Entrega A: enemigos

Esta entrega amplía el juego existente. El botón Nueva partida conserva la
habitación del prototipo; Incursión 0.2 ofrece cinco oleadas de cuatro especies,
con un punto de curación entre oleadas y victoria al terminar la quinta.
Pausa, controles multitáctiles, ajustes y derrota siguen disponibles.

El catálogo `scripts/enemies/catalog.gd` contiene veinte definiciones con ID,
nombre, vida, daño, resistencia, velocidad, intervalo, recompensa, silueta y
oleada mínima. La escena compartida conserva los cuerpos de colisión existentes.

| Enemigo | Diferencia funcional |
| --- | --- |
| Sombra Errante | Persecución lenta |
| Espina Veloz | Persecución con zigzag |
| Ojo del Vacío | Disparo apuntado y retirada |
| Larva Umbría | Cohesión hacia otras larvas |
| Centinela Roto | Inmóvil, dispara solo a menos de 300 unidades |
| Espectro Fugaz | Cruza pilares, permanece dentro de la arena |
| Escarabajo Blindado | Reduce 70% del daño frontal |
| Baba Corrosiva | Deja ácido temporal |
| Tejedor Oscuro | Obstáculos sólidos temporales que bloquean disparos |
| Murciélago Carmesí | Vuelo oscilante no dirigido constantemente al jugador |
| Invocador de Sombras | Invoca larvas debilitadas |
| Guardián Prismático | Cuatro disparos cardinales |
| Devorador de Luz | Oscurece una región durante tres segundos, debajo de la UI |
| Cazador Espectral | Señala un destino y salta a él |
| Núcleo Inestable | Explosión de muerte anunciada con 0,8 s de margen |
| Duplicador | Crea una única copia debilitada, incapaz de duplicarse |
| Parásito Arcano | Zona que reduce velocidad 30% y la restaura al desaparecer |
| Vigía del Abismo | Anillos giratorios de ocho proyectiles |
| Coloso Fragmentado | Resistencia y división en dos larvas al morir |
| Portador de Tormentas | Zona eléctrica anunciada antes de infligir daño |

Las zonas dañinas avisan 0,8 segundos antes de activarse. Máximos: 16 enemigos,
96 proyectiles y 10 zonas. Las invocaciones respetan estos límites y el veneno
estadístico del parásito no se acumula. Los proyectiles consultan solo la lista
acotada de zonas para las colisiones con paredes temporales. Las zonas se
congelan durante la pausa y el modificador se restaura al eliminar su nodo.

Validación local: 38 comprobaciones de regresión y 68 de enemigos, sin fallos.
La compilación de GitHub debe comprobarse en la ejecución del PR de esta entrega.
Quedan pendientes pruebas físicas de rendimiento y tacto en el ZTE 8050.

Esta entrega no incluye todavía los 40 objetos, combinaciones, élites,
minijefes ni jefes: corresponden a B, C y D. La arquitectura de objetos se
implementará junto a sus efectos funcionales en B, evitando catálogos sin uso.
