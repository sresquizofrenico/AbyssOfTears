# 0.2.1 — Tres pisos conectados

Nueva opción **Mazmorra · 3 pisos**. Conserva Nueva partida e Incursión 0.2.

- Cripta de Sal, Jardines Hundidos y Falla de Cristal, con colores distintos.
- Ocho habitaciones por piso: inicio seguro, tesoro, salida defendida y combates.
- Grafo aleatorio reproducible por semilla, puertas bidireccionales y salida
  situada entre las habitaciones más alejadas del inicio.
- Minimapa que revela lo visitado y las habitaciones adyacentes.
- Puertas bloqueadas durante el combate. Al limpiar, acercarse al marcador
  verde permite cruzar; el botón **Puertas / Piso** ofrece navegación táctil.
- La sala de salida contiene un encuentro más numeroso. Al despejarla, pulsa
  **Puertas / Piso → Descender**. La tercera salida termina la partida.
- Vida, estadísticas y monedas persisten entre habitaciones y pisos.
- Volver a una sala despejada no regenera enemigos ni recompensas.
- Recompensas de monedas variables según semilla y piso. El tesoro concede
  +0,25 daño y +1 vida máxima, curando un punto; solo una vez por piso.
- El número y la resistencia de enemigos aumentan con el piso. Las especies
  avanzadas se introducen progresivamente, usando el catálogo de veinte tipos.
- Reiniciar una mazmorra comienza otra desde el primer piso y sin monedas.

No hay todavía jefes principales en las salidas: son encuentros de enemigos.
Los 40 objetos, rarezas, combinaciones, élites, minijefes y jefes siguen pendientes.
Los tesoros actuales son mejoras básicas, no el catálogo de objetos solicitado.
No existe guardado de la mazmorra entre cierres de la aplicación; se conserva
el guardado de ajustes que ya tenía el prototipo.

Validación local ejecutada: 38 comprobaciones originales, 68 de enemigos y
11.977 de pisos. Estas últimas incluyen 200 semillas en cada uno de los tres
pisos, accesibilidad, enlaces simétricos, determinismo, conservación de vida y
monedas, recompensas únicas, transición de pisos y victoria/reinicio. Se han
revisado capturas OpenGL reales de la habitación y de la navegación táctil.

El rendimiento y la instalación física en el ZTE siguen pendientes de medición.
El workflow Android debe confirmar el APK del commit de esta entrega.
