# Guía visual y modalidades · 0.13

## Modalidad publicable

Es la única habilitada en Android. Conserva veinte personajes originales y los IDs de 0.12. No se renombra a nadie con una identidad de anime en el APK. Los nueve Vínculos son Lyra, Kairon, Nami, Yura, Aria, Beren, Celine, Dalia y Elora.

Dirección: ilustración 2D caricaturesca, proporción de unas tres cabezas, contorno azul tinta #192634, borde exterior de 7 unidades sobre lienzo 384×512, sombras suaves pintadas, acentos mágicos legibles. Nada de fotografías, modelos humanos ni render 3D. Mantener contraste con proyectiles hostiles cálidos y ataques aliados turquesa. Los perfiles bajos conservan el cuerpo ilustrado.

## Fichas privadas

`private/reference_cards.json` contiene nueve fichas de texto con nombre, referencia visual y función. No contiene ilustraciones oficiales ni un paquete de personajes licenciados. Solo una compilación de escritorio del editor iniciada con el argumento de usuario `--private-reference` puede mostrar esos alias de referencia. Los sprites siguen siendo los originales provisionales: no se afirma que exista un rediseño final reconocible de personajes oficiales.

Ejemplo interno de desarrollo: `godot --path . -- --private-reference`. No es un requisito para el usuario Android. El código exige el motor de editor y excluye Android incluso si se fuerza el argumento. La carpeta se excluye del preset público; el exportador rechaza cualquier entrada `assets/private/` dentro del APK.

| Referencia privada | Ficha y mecánica | Identidad pública independiente |
| --- | --- | --- |
| Ichika Nakano | Cabello rosado corto; ilusión y distracción | Aria: pelo coral ondulado, abrigo de exploración claro y broche propio |
| Nino Nakano | Cabello rosado, accesorios laterales; ataques rápidos y elementos | Beren: pelo cobrizo, trenzas, chaqueta granate y estela de fuego |
| Miku Nakano | Pelo castaño rojizo, auriculares; análisis y precisión | Celine: coleta baja, cuaderno táctico, indumentaria de exploradora azul |
| Yotsuba Nakano | Pelo naranja y cinta verde; movilidad | Dalia: coleta alta, ropa deportiva de expedición, protección de salto |
| Itsuki Nakano | Pelo rojizo largo y estrellas; defensa y contraataque | Elora: abrigo crema, bufanda violeta, horquillas geométricas |
| Yuno Gasai | Pelo rosa largo y estética escolar; visión, evasión y predicción | Yura: ropa urbana negra/violeta y brazalete de predicción, sin uniforme escolar |
| Riko | Exploración y cartografía | Lyra: pelo cobrizo, sombrero azul, brújula y mochila de mapas |
| Reg | Energía, resistencia, mecanismos y rayo | Kairon: brazos de bronce, abrigo corto y núcleo tecnológico propio |
| Nanachi | Peligros, antídotos, criaturas y esporas | Nami: cabello crema con motivos de hoja, abrigo musgo y accesorios micológicos |

Los nombres de las referencias se usan como fichas comparativas, no como licencia de publicación. No se incluyen recortes de las imágenes del historial.

## Recursos creados y límites

Nueve SVG traseros nuevos, uno por Vínculo, con siluetas, prendas y accesorios originales. El render elige frente/espalda y proyecta o refleja el cuerpo en giros laterales. La dirección de movimiento actualiza la orientación si no se está apuntando. La selección y el combate comparten recursos; las colisiones no cambian. Es animación por partes, no cuatro secuencias completas dibujadas fotograma a fotograma.

Tres murales de suelo originales y económicos se superponen a los pisos existentes: sellos de sal, raíces y vetas de cristal. Se conservan obstáculos, rutas, amenazas y mapas. Son una mejora integrada sobre la base vectorial, no escenarios finales completos.

Para arte final faltan, en los veinte personajes: retratos expresivos dedicados, perfiles de cabeza independientes izquierda/derecha y secuencias ilustradas completas de caminar, ataque, habilidad, daño, derrota y desbloqueo. La guía de producción exige una hoja por personaje, pruebas de lectura a 48–64 px y atlas por personaje cargado bajo demanda. No se debe sustituir el motor de combate por escenas decorativas.

## Doce pisos previstos, tres existentes

Esta entrega mejora Cripta de Sal, Jardines Hundidos y Falla de Cristal. La campaña de doce pisos sigue siendo un diseño pendiente. Preservar como guía futura los temas: jardines, criptas, ceniza, bosque, forja, lago, relojes, máscaras, tormentas, eclipse, olvido y corazón del abismo. Su arte, música, navegación, enemigos y jefes no se marcan como implementados por existir esta guía.
