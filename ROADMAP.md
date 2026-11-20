# Noël — Roadmap de Mejoras por Fases

Hoja de ruta de nuevas funciones planificadas a partir de `v1.0.1` para implementar de manera incremental fase por fase.

## Resumen de Fases

| Fase | Nombre | Archivos principales | Estado |
| :--- | :--- | :--- | :--- |
| Fase 1 | El Trineo de Santa Claus | `ScreenEffectsManager.swift`, `AudioManager.swift`, `AppState.swift`, `PopoverContentView.swift` | Completada |
| Fase 2 | Nevada Blizzard Mejorada, Física con el Cursor y Nivel de Capa | `ScreenEffectsManager.swift`, `AppState.swift`, `PopoverContentView.swift` | Completada |
| Fase 3 | Paletas de Luces, Modo Audio-Reactivo y Viento Invernal | `ScreenEffectsManager.swift`, `AudioManager.swift`, `AppState.swift`, `PopoverContentView.swift` | Completada |
| Fase 4 | Comodidad en el Día a Día | `main.swift`, `AppState.swift`, `PopoverContentView.swift` | Completada |
| Fase 5 | Restauracion de Luces Superiores (Sin Hielos) y Derribo Fisico de Santa hasta la Nieve | `ScreenEffectsManager.swift`, `SantaSleighOverlayView.swift`, `SnowOverlayView.swift` | Completada |
| Fase 6 | Monitos Limpiadores de Nieve (Duendes con Pala y Quitanieves) y Rescate de Santa | `SnowOverlayView.swift`, `ScreenEffectsManager.swift`, `AppState.swift`, `PopoverContentView.swift` | Completada |
| Fase 7 | Batalla de Bolas de Nieve con los Monitos y Construccion de Munecos de Nieve | `SnowOverlayView.swift`, `ScreenEffectsManager.swift` | Completada |

---

## Fase 1: El Trineo de Santa Claus
**Objetivo:** Añadir apariciones periódicas (e invocación manual) de Santa Claus y su trineo volando por toda la pantalla con 4 trayectorias variadas, soltando regalos con paracaídas e interactuando con bolas de nieve.

- [x] **Vuelo por toda la pantalla con 4 trayectorias y soporte multipantalla (`ScreenEffectsManager.swift`, `SantaSleighOverlayView.swift`):** Vuelo completo a lo largo y alto de la pantalla con 4 trayectorias orgánicas (`diagonalClimb`, `panoramicWave`, `centerDive`, `sweepingArc`), inclinación física y ventana transparente *click-through*, respetando el modo de pantallas activas (`Todas` / `Principal`).
- [x] **Arte sincronizado con el estilo visual (`ScreenEffectsManager.swift`, `SantaSleighRenderer.swift`):** Renderizado dual acorde a `IconStyle` (`Color 3D` vectorial o `Pixel Art` de 8 bits), mostrando a Santa en el trineo, renos con animación de galope y a Rudolph al frente con nariz roja luminosa (`NSGradient`).
- [x] **Estela dorada, regalos con paracaídas e impacto de bolas de nieve (`SantaSleighOverlayView.swift`):** Rastro de partículas doradas que caen y se desvanecen lentamente detrás del trineo, caída de regalo con paracaídas y desprendimiento de regalo extra con estallido de destellos al recibir un impacto de bola de nieve (`handleSnowballImpact`).
- [x] **Cascabeles procedurales con paneo estéreo (`AudioManager.swift`):** Síntesis en tiempo real de un tintineo sutil de cascabeles lejanos con paneo izquierdo-a-derecho (o viceversa según dirección del vuelo), sin archivos de audio externos.
- [x] **Controles y persistencia (`AppState.swift`, `PopoverContentView.swift`):** Selector de frecuencia (`Desactivado`, `Ocasional`, `Frecuente`) y botón rápido **«Probar vuelo» / «Invocar a Santa»** en el popover.

---

## Fase 2: Nevada Blizzard Mejorada, Física con el Cursor y Nivel de Capa
**Objetivo:** Diferenciar visualmente la intensidad máxima de nevada con capas de profundidad sin manchas estáticas en esquinas, quitanieves interactivo en el borde inferior y posibilidad de tomar y lanzar bolas de nieve contra luces y Santa.

- [x] **Contraste real en modo `Nevada (Blizzard)` y quitanieves interactivo (`ScreenEffectsManager.swift`):** Ráfagas diagonales con copos en 3 capas de profundidad sin manchas estáticas en esquinas, acumulación progresiva de nieve sobre el borde inferior y quitanieves interactivo que despeja la acumulación al pasar el cursor.
- [x] **Física interactiva con el mouse y lanzamiento de bolas de nieve (`ScreenEffectsManager.swift`):** Lectura eficiente de `NSEvent.mouseLocation` en el ciclo de animación para apartar copos, balancear las bombillas de la guirnalda y permitir tomar bolas de nieve acumuladas para lanzarlas contra las luces o contra el trineo de Santa.
- [x] **Selector de capa de renderizado (`AppState.swift`, `ScreenEffectsManager.swift`, `PopoverContentView.swift`):** Opción **`Sobre todo` | `Solo escritorio`** para elegir si la nieve cae encima de las ventanas abiertas (`.floating`) o únicamente sobre el fondo de pantalla detrás de las ventanas (`CGWindowLevelForKey(.desktopIconWindow)`).
- [x] **Manto de nieve continuo Camaleón y selectores independientes de estilo (`ScreenEffectsManager.swift`, `PopoverContentView.swift`):** Manto de nieve acumulada en franja de 44 pt sin costuras verticales entre columnas con optimización de memoria (~0.35 MB de RAM con dirty rendering) y selectores independientes 3D vs Pixel Art para copos y base.

---

## Fase 3: Paletas de Luces, Modo Audio-Reactivo y Viento Invernal
**Objetivo:** Enriquecer las guirnaldas luminosas con 5 paletas de color y carámbanos interactivos, añadir el patrón audio-reactivo y ambientar con viento invernal procedural en estéreo.

- [x] **Paletas de color para la guirnalda superior y carámbanos interactivos (`AppState.swift`, `ScreenEffectsManager.swift`, `PopoverContentView.swift`):** Selección entre 5 paletas de color (*Clásica Multicolor*, *Blanco Cálido*, *Bastón de Caramelo*, *Hielo Nórdico* y *Pino Dorado*) con selector visual de puntos de color en el popover, carámbanos interactivos en el cable que se rompen al tacto y sobrecarga luminosa temporal por impacto de bolas de nieve.
- [x] **Patrón luminoso `Ritmo` (`Audio-Reactivo`) (`AudioManager.swift`, `ScreenEffectsManager.swift`, `PopoverContentView.swift`):** Cuarto patrón de iluminación audio-reactivo de doble banda (medición de nivel espectral en tiempo real en `AVAudioPlayer` para música integrada y pulso rítmico sincronizado con la reproducción activa en Spotify / Apple Music).
- [x] **Viento invernal procedural en estéreo (`AudioManager.swift`, `PopoverContentView.swift`):** Síntesis procedural de ruido rosa filtrado en tiempo real con fluctuación de ráfagas y paneo binaural, control de volumen propio independiente mediante slider en el popover y auto-activación coordinada al seleccionar nevada Blizzard.
- [x] **Selector independiente 3D vs Pixel Art para luces superiores (`PopoverContentView.swift`, `ScreenEffectsManager.swift`):** Selector dedicado 3D / Pixel Art en la sección de luces que permite combinar bombillas vectoriales o retro libremente con la nieve.

---

## Fase 4: Comodidad en el Día a Día
**Objetivo:** Facilitar el uso continuo durante llamadas de trabajo o reuniones y permitir el arranque automático con macOS.

- [x] **Modo rápido «Pantalla Compartida / En Llamada» (`main.swift`, `AppState.swift`, `PopoverContentView.swift`):** Atajo **`Option + Clic`** sobre el icono de la barra de menú, botón dedicado con icono de ojo en la cabecera del popover y banner interactivo de reanudación para ocultar o reanudar al instante todos los efectos de pantalla (nieve, luces y trineo) sin perder la configuración activa de cada uno.
- [x] **Iniciar al encender la Mac (`Launch at Login`) (`AppState.swift`, `PopoverContentView.swift`):** Interruptor nativo basado en `SMAppService` (macOS 13+) en los ajustes del popover para abrir Noël automáticamente al iniciar sesión en macOS.

---

## Fase 5: Restauracion de Luces Superiores (Sin Hielos) y Derribo Fisico de Santa hasta la Nieve
**Objetivo:** Devolver un aspecto limpio, calido y luminoso a la guirnalda superior eliminando los pedazos de hielo y agregando un halo radial difuminado real, y anadir fisica completa de derribo para que Santa aterrice en el manto de nieve inferior y suelte regalos interactivos.

- [x] **Guirnalda luminosa limpia con halo radial difuminado real (`ScreenEffectsManager.swift`):** Eliminacion total de los carambanos, esquirlas de hielo y linea de escarcha sobre el cable; reemplazo de los circulos planos de borde duro por texturas de halo radial suave (`CGGradient`) en modo `Color 3D` y halo escalonado retro en `Pixel Art`, con casquillo metalico y reflejo especular en cada bombilla.
- [x] **Derribo fisico de Santa hasta el banco de nieve inferior (`SantaSleighOverlayView.swift`, `SnowOverlayView.swift`, `ScreenEffectsManager.swift`):** Al impactar a Santa con una bola de nieve, el trineo pierde estabilidad, cae en parabola echando chispas y aterriza de emergencia sobre la nieve acumulada abajo, excavando un crater fisico en el manto de nieve, levantando una nube de nieve y quedando aturdido con estrellas giratorias durante unos segundos antes de reincorporarse y despegar.
- [x] **Regalos posados sobre el manto de nieve e interactivos con el cursor (`SantaSleighOverlayView.swift`, `SnowOverlayView.swift`):** Los regalos que caen en paracaidas (o se sueltan al derribar a Santa) se posan fisicamente sobre la curva del banco de nieve inferior y pueden abrirse al pasar el cursor por encima con un estallido de particulas.

---

## Fase 6: Monitos Limpiadores de Nieve (Duendes con Pala y Quitanieves) y Rescate de Santa
**Objetivo:** Poblar el manto de nieve inferior con duendes trabajadores que limpian la nieve acumulada en tiempo real y asisten al trineo de Santa si cae derribado.

- [x] **Cuadrilla de monitos limpiadores en el banco de nieve (`SnowOverlayView.swift`, `AppState.swift`, `PopoverContentView.swift`):** Duendes navidenos animados (con selector `No`, `1`, `Equipo` y estilo `3D | PX`) que caminan sobre la nieve acumulada paleando los monticulos reales (`driftBins`) y sacando un quitanieves ancho durante tormentas `Blizzard`.
- [x] **Operativo de rescate a Santa y recoleccion de regalos (`SnowOverlayView.swift`, `SantaSleighOverlayView.swift`):** Cuando Santa cae derribado en la nieve, los monitos corren hacia el trineo para desenterrarlo y empujarlo para que despegue mas rapido; tambien recogen los regalos posados en la nieve que el usuario no haya abierto.

---

## Fase 7: Batalla de Bolas de Nieve con los Monitos y Construccion de Munecos de Nieve
**Objetivo:** Hacer interactivos a los duendes limpiadores mediante una batalla amistosa de bolas de nieve y construccion autonoma de munecos de nieve en el borde inferior.

- [x] **Reaccion a bolazos y contraataque hacia el cursor del mouse (`SnowOverlayView.swift`):** Si el usuario golpea a un monito con una bola de nieve, este cae sentado en la nieve, se sacude y lanza una bolita de nieve de regreso en direccion a la posicion actual del cursor del mouse (o hacia arriba).
- [x] **Construccion de munecos de nieve destructibles (`SnowOverlayView.swift`):** Cuando hay suficiente nieve acumulada en las esquinas, los monitos arman un muneco de nieve (en `Color 3D` o `Pixel Art`) que adorna la base hasta que el usuario lo derriba de un bolazo.
