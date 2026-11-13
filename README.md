# Noël

> Reproductor navideño artesanal para la barra superior de macOS.  
> An artisanal Christmas menu bar companion for macOS.

---

[Español](#español) | [English](#english)

---

<a name="español"></a>
## Español

**Noël** es una aplicación ligera y elegante para la barra de menú de macOS que transforma tu escritorio durante las fiestas. Incluye melodías navideñas clásicas estilo caja de música sintetizadas en tiempo real, efectos ambientales de chimenea, iconos giratorios 3D y Pixel Art, nieve interactiva y guirnaldas de luces superiores.

### Características

- **Iconos animados en la barra de menú:** 5 personajes (Pinito, Muñeco, Reno, Santa, Chocolate) en estilos 3D Color y Pixel Art con rotación dinámica y destellos.
- **Música navideña integrada:** Canciones tradicionales sintetizadas (Jingle Bells, We Wish You a Merry Christmas, Silent Night, Deck the Halls, Carol of the Bells).
- **Música personalizada:** Carga cualquier carpeta con tus archivos de audio MP3, M4A, WAV o FLAC.
- **Ambiente de chimenea:** Sonido relajante de leña crepitante generado por síntesis de audio procedural.
- **Efectos de pantalla transparentes:** Nevada suave sobre tu pantalla y guirnalda de luces festivas festoneada en el borde superior.
- **Cuenta regresiva festiva:** Días y horas restantes hasta Navidad, con opción de mostrar el contador directamente en la barra de menú.
- **Temas y tipografía:** Modos Pino Dark, Crema Light y Auto/Sistema, con fuentes Typewriter u Optima.
- **Bilingüe:** Alterna entre Español e Inglés en cualquier momento.

### Instalación rápida (1 comando)

#### Opción 1: Con Homebrew (recomendada)
```bash
brew install --cask Dmian0/noel/noel
```

#### Opción 2: Desde terminal con curl
```bash
curl -fsSL https://raw.githubusercontent.com/Dmian0/noel/main/install.sh | bash
```

### Uso rápido

- **Clic izquierdo en el icono:** Abre o cierra el panel festivo compacto.
- **Clic derecho en el icono:** Reproduce o pausa la música al instante.
- **Agregar tu música:** En el panel, presiona *Elegir carpeta con mis MP3* para vincular tu biblioteca local.

### Compilar desde código fuente

Requisitos: macOS 13.0 (Ventura) o posterior y Xcode Command Line Tools.

```bash
git clone https://github.com/Dmian0/noel.git
cd noel
./build_app.sh
```

El script compila el binario en modo release, genera el bundle `Noel.app`, lo firma ad-hoc y crea el paquete de distribución `Noel.zip`.

---

<a name="english"></a>
## English

**Noël** is a lightweight, elegant macOS menu bar player designed to bring warm holiday spirit to your desktop. Featuring real-time synthesized music-box melodies, cozy fireplace ambiance, 3D rotating and Pixel Art status icons, interactive falling snow, and top festoon lights.

### Features

- **Animated Menu Bar Icons:** 5 characters (Tree, Snowman, Reindeer, Santa, Cocoa) in 3D Color and Pixel Art styles with dynamic spinning and twinkle.
- **Built-in Music Box Tunes:** Procedurally synthesized holiday classics (Jingle Bells, We Wish You a Merry Christmas, Silent Night, Deck the Halls, Carol of the Bells).
- **Custom Music Support:** Point to any folder containing your personal MP3, M4A, WAV, or FLAC files.
- **Cozy Fireplace Ambiance:** Warm crackling hearth audio generated through real-time procedural audio synthesis.
- **Click-Through Screen Overlays:** Gentle falling snow and illuminated holiday garland lights along the top edge of your screen.
- **Christmas Countdown:** Days and hours remaining until Christmas, optionally displayed in your menu bar.
- **Themes & Typography:** Pine Dark, Cream Light, and Auto/System themes, styled in Typewriter or Optima fonts.
- **Bilingual:** Switch seamlessly between English and Spanish.

### Quick Install (1 command)

#### Option 1: Using Homebrew (recommended)
```bash
brew install --cask Dmian0/noel/noel
```

#### Option 2: Via terminal curl script
```bash
curl -fsSL https://raw.githubusercontent.com/Dmian0/noel/main/install.sh | bash
```

### Quick Controls

- **Left-click on icon:** Open or close the compact holiday panel.
- **Right-click on icon:** Toggle play/pause instantly.
- **Add your own songs:** Click *Choose custom music folder* in the panel to link your audio collection.

### Build from Source

Requirements: macOS 13.0 (Ventura) or newer and Xcode Command Line Tools.

```bash
git clone https://github.com/Dmian0/noel.git
cd noel
./build_app.sh
```

The script compiles the project in release mode, packages `Noel.app`, applies ad-hoc codesigning, and generates `Noel.zip` ready for distribution.

---

### License

MIT License. Designed with care for the holiday season.
