import AppKit
import SwiftUI
import QuartzCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var animationTimer: Timer?

    private var phase: Double = 0.0
    private var twinklePhase: Double = 0.0

    private var lastToolTipUpdate: TimeInterval = 0
    private var lastCountdownText: String = ""
    private var lastThemeMode: AppThemeMode? = nil
    private var lastRenderedCharacter: CharacterType? = nil
    private var lastRenderedStyle: IconStyle? = nil
    private var lastRenderedIsPlaying: Bool? = nil
    private var lastRenderedPausedForCall: Bool? = nil
    private var idleRenderTickCounter: Int = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        // App de barra de menú sin icono en el Dock
        NSApp.setActivationPolicy(.accessory)

        // Configurar el ítem en la barra de estado del sistema
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = self
            button.action = #selector(statusBarClicked(_:))
            button.imagePosition = .imageLeading
        }

        // Configurar popover desplegable con auto-ajuste dinámico de tamaño (macOS 13+)
        popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        let hostingController = NSHostingController(
            rootView: PopoverContentView()
                .environmentObject(AppState.shared)
                .environmentObject(AudioManager.shared)
        )
        hostingController.sizingOptions = [.preferredContentSize]
        popover.contentViewController = hostingController
        syncPopoverAppearance()

        // Sincronizar efectos de pantalla (nieve flotante y luces navideñas superiores)
        ScreenEffectsManager.shared.syncWithState()

        // Iniciar timer de animación a 20 FPS (0.05s)
        startAnimationTimer()
    }

    private func syncPopoverAppearance() {
        guard let popover = self.popover else { return }
        switch AppState.shared.themeMode {
        case .dark:
            popover.appearance = NSAppearance(named: .darkAqua)
        case .light:
            popover.appearance = NSAppearance(named: .aqua)
        case .system:
            popover.appearance = nil
        }
    }

    private func startAnimationTimer() {
        updateStatusBar()

        let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            let isPlaying = AudioManager.shared.isPlaying
            let shouldRotate = (AppState.shared.animationMode == .always) || isPlaying

            if shouldRotate {
                self.phase += 0.14
                if self.phase >= 2.0 * .pi * 1000.0 {
                    self.phase -= 2.0 * .pi * 1000.0
                }
            }

            self.twinklePhase += 0.08
            if self.twinklePhase >= 2.0 * .pi * 1000.0 {
                self.twinklePhase -= 2.0 * .pi * 1000.0
            }

            self.updateStatusBar()
        }

        // Modo .common para que la animación continúe mientras se arrastra una ventana o menú
        RunLoop.main.add(timer, forMode: .common)
        self.animationTimer = timer
    }

    private func updateStatusBar() {
        autoreleasepool {
            guard let button = statusItem?.button else { return }

            let currentCharacter = AppState.shared.selectedCharacter
            let currentStyle = AppState.shared.iconStyle
            let isPlaying = AudioManager.shared.isPlaying
            let isPausedForCall = AppState.shared.isEffectsPausedForCall
            let shouldRotate = (AppState.shared.animationMode == .always) || isPlaying

            let pauseChanged = (isPausedForCall != lastRenderedPausedForCall)
            let stateChanged = (currentCharacter != lastRenderedCharacter)
                || (currentStyle != lastRenderedStyle)
                || (isPlaying != lastRenderedIsPlaying)
                || pauseChanged

            button.alphaValue = isPausedForCall ? 0.55 : 1.0

            let shouldRender: Bool
            if shouldRotate || stateChanged {
                shouldRender = true
            } else {
                shouldRender = (idleRenderTickCounter % 3 == 0)
                idleRenderTickCounter += 1
            }

            if shouldRender {
                button.image = StatusBarIconRenderer.render(
                    character: currentCharacter,
                    style: currentStyle,
                    phase: phase,
                    twinklePhase: twinklePhase,
                    isPlaying: isPlaying,
                    isRotating: shouldRotate,
                    size: NSSize(width: 22, height: 22)
                )
                lastRenderedCharacter = currentCharacter
                lastRenderedStyle = currentStyle
            }

            let newTitle: String
            if AppState.shared.showCountdownInMenuBar {
                let countdown = AppState.shared.countdownShortText().lowercased()
                newTitle = " " + countdown
                lastCountdownText = countdown
            } else {
                newTitle = ""
                lastCountdownText = ""
            }

            if button.title != newTitle {
                button.title = newTitle
                if !newTitle.isEmpty {
                    button.font = NSFont.monospacedDigitSystemFont(ofSize: 11.5, weight: .medium)
                }
            }

            let currentTheme = AppState.shared.themeMode
            if lastThemeMode != currentTheme {
                syncPopoverAppearance()
                lastThemeMode = currentTheme
            }

            let now = CACurrentMediaTime()
            let playingChanged = (isPlaying != lastRenderedIsPlaying)
            if button.toolTip == nil || playingChanged || pauseChanged || (now - lastToolTipUpdate >= 2.0) {
                button.toolTip = buildToolTip(isPlaying: isPlaying)
                lastToolTipUpdate = now
            }

            lastRenderedIsPlaying = isPlaying
            lastRenderedPausedForCall = isPausedForCall
        }
    }

    private func buildToolTip(isPlaying: Bool) -> String {
        var lines: [String] = []
        let isEN = AppState.shared.language == .en

        // Línea 1: Título de la app y cuenta atrás limpia
        lines.append("\(AppState.shared.appTitle) — \(AppState.shared.countdownLongText())")

        if AppState.shared.isEffectsPausedForCall {
            lines.append(isEN ? "Screen effects paused (Meeting Mode)" : "Efectos en pausa (Modo Llamada)")
        }

        // Línea 2: Estado de música
        let trackTitle = AudioManager.shared.displayTrackTitle
        if AudioManager.shared.musicProvider == .noel && AudioManager.shared.currentTrack == nil {
            lines.append(trackTitle)
        } else {
            let status = isPlaying ? (isEN ? "Playing" : "Reproduciendo") : (isEN ? "Paused" : "En pausa")
            lines.append("\(status): \(trackTitle)")
        }

        // Línea 3: Instrucciones limpias
        lines.append(isEN ? "Left: Panel · Right: Play · Opt+Click: Pause effects" : "Clic izq: Panel · Clic der: Play · Opt+Clic: Pausar efectos")

        return lines.joined(separator: "\n")
    }

    @objc private func statusBarClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        let isRightClick = event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true
        let isOptionClick = event?.modifierFlags.contains(.option) == true

        if isOptionClick && !isRightClick {
            if popover.isShown {
                popover.performClose(sender)
            }
            AppState.shared.toggleEffectsPausedForCall()
            updateStatusBar()
            return
        }

        if isRightClick {
            if popover.isShown {
                popover.performClose(sender)
            }
            AudioManager.shared.togglePlayPause()
            updateStatusBar()
        } else {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                syncPopoverAppearance()
                NSApp.activate(ignoringOtherApps: true)
                popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

// Punto de entrada de la aplicación
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
