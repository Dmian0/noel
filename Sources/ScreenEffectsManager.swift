import AppKit

/// Manages click-through transparent overlay windows for falling snow and top holiday lights.
final class ScreenEffectsManager {
    static let shared = ScreenEffectsManager()

    private var snowEntries: [CGDirectDisplayID: (window: NSWindow, view: SnowOverlayView)] = [:]
    private var lightsEntries: [CGDirectDisplayID: (window: NSWindow, view: LightsOverlayView)] = [:]

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func screensChanged() {
        syncWithState()
    }

    func syncWithState() {
        let state = AppState.shared
        updateSnow(enabled: state.isSnowing, intensity: state.snowIntensity, screenMode: state.screenTargetMode)
        updateLights(enabled: state.showTopLights, pattern: state.lightsPattern, screenMode: state.screenTargetMode)
    }

    private func targetScreens(for mode: ScreenTargetMode) -> [(id: CGDirectDisplayID, screen: NSScreen)] {
        let screens: [NSScreen]
        switch mode {
        case .allScreens:
            screens = NSScreen.screens
        case .mainOnly:
            if let first = NSScreen.screens.first ?? NSScreen.main {
                screens = [first]
            } else {
                screens = []
            }
        }

        var result: [(id: CGDirectDisplayID, screen: NSScreen)] = []
        for screen in screens {
            if let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID {
                result.append((id: id, screen: screen))
            } else if screen == NSScreen.main {
                result.append((id: CGMainDisplayID(), screen: screen))
            }
        }
        return result
    }

    // MARK: - Snow Overlay

    private func updateSnow(enabled: Bool, intensity: Double, screenMode: ScreenTargetMode) {
        if !enabled {
            for (_, entry) in snowEntries {
                entry.view.stop()
                entry.window.orderOut(nil)
            }
            snowEntries.removeAll()
            return
        }

        let targets = targetScreens(for: screenMode)
        let activeIDs = Set(targets.map { $0.id })

        for (id, entry) in snowEntries where !activeIDs.contains(id) {
            entry.view.stop()
            entry.window.orderOut(nil)
            snowEntries.removeValue(forKey: id)
        }

        for (id, screen) in targets {
            let frame = screen.frame
            if let entry = snowEntries[id] {
                entry.window.setFrame(frame, display: true)
                entry.view.frame = NSRect(origin: .zero, size: frame.size)
                entry.view.setIntensity(intensity)
                entry.view.start()
                entry.window.orderFrontRegardless()
            } else {
                let win = NSWindow(
                    contentRect: frame,
                    styleMask: [.borderless],
                    backing: .buffered,
                    defer: false
                )
                win.isOpaque = false
                win.backgroundColor = .clear
                win.hasShadow = false
                win.ignoresMouseEvents = true
                win.level = .floating
                win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]

                let view = SnowOverlayView(frame: NSRect(origin: .zero, size: frame.size))
                win.contentView = view
                view.setIntensity(intensity)
                view.start()
                win.orderFrontRegardless()

                snowEntries[id] = (window: win, view: view)
            }
        }
    }

    // MARK: - Top Lights Garland Overlay

    private func updateLights(enabled: Bool, pattern: LightsPattern, screenMode: ScreenTargetMode) {
        if !enabled {
            for (_, entry) in lightsEntries {
                entry.view.stop()
                entry.window.orderOut(nil)
            }
            lightsEntries.removeAll()
            return
        }

        let targets = targetScreens(for: screenMode)
        let activeIDs = Set(targets.map { $0.id })

        for (id, entry) in lightsEntries where !activeIDs.contains(id) {
            entry.view.stop()
            entry.window.orderOut(nil)
            lightsEntries.removeValue(forKey: id)
        }

        let garlandHeight: CGFloat = 34.0
        for (id, screen) in targets {
            let menuBarHeight = max(screen.frame.maxY - screen.visibleFrame.maxY, NSStatusBar.system.thickness)
            let garlandY = screen.frame.maxY - menuBarHeight - garlandHeight
            let frame = NSRect(x: screen.frame.minX, y: garlandY, width: screen.frame.width, height: garlandHeight)

            if let entry = lightsEntries[id] {
                entry.window.setFrame(frame, display: true)
                entry.view.frame = NSRect(origin: .zero, size: frame.size)
                entry.view.pattern = pattern
                entry.view.start()
                entry.window.orderFrontRegardless()
            } else {
                let win = NSWindow(
                    contentRect: frame,
                    styleMask: [.borderless],
                    backing: .buffered,
                    defer: false
                )
                win.isOpaque = false
                win.backgroundColor = .clear
                win.hasShadow = false
                win.ignoresMouseEvents = true
                win.level = .floating
                win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]

                let view = LightsOverlayView(frame: NSRect(origin: .zero, size: frame.size))
                win.contentView = view
                view.pattern = pattern
                view.start()
                win.orderFrontRegardless()

                lightsEntries[id] = (window: win, view: view)
            }
        }
    }
}

// MARK: - Snow View

private final class SnowOverlayView: NSView {
    private struct Snowflake {
        var x: CGFloat
        var y: CGFloat
        var radius: CGFloat
        var speedY: CGFloat
        var driftPhase: Double
        var driftSpeed: Double
        var driftAmp: CGFloat
        var opacity: CGFloat
        var isCrystal: Bool
    }

    private var flakes: [Snowflake] = []
    private var timer: Timer?
    private var targetCount: Int = 100
    private var currentIntensity: Double = 0.6
    private var time: Double = 0

    override var isOpaque: Bool { false }

    func setIntensity(_ intensity: Double) {
        currentIntensity = intensity
        if intensity <= 0.4 {
            targetCount = 42
        } else if intensity <= 0.75 {
            targetCount = 100
        } else {
            targetCount = 260
        }
        adjustFlakeCount()
    }

    func start() {
        adjustFlakeCount()
        guard timer == nil else { return }
        let t = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.step()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func adjustFlakeCount() {
        let w = max(bounds.width, 800)
        let h = max(bounds.height, 600)
        while flakes.count < targetCount {
            flakes.append(makeFlake(width: w, height: h, randomY: true))
        }
        if flakes.count > targetCount {
            flakes.removeLast(flakes.count - targetCount)
        }
    }

    private func makeFlake(width: CGFloat, height: CGFloat, randomY: Bool) -> Snowflake {
        let radius = CGFloat.random(in: 1.6...4.6)
        return Snowflake(
            x: CGFloat.random(in: 0...width),
            y: randomY ? CGFloat.random(in: 0...height) : height + CGFloat.random(in: 4...24),
            radius: radius,
            speedY: CGFloat.random(in: 0.75...2.35) * (0.65 + radius * 0.14),
            driftPhase: Double.random(in: 0...(2 * .pi)),
            driftSpeed: Double.random(in: 0.8...2.1),
            driftAmp: CGFloat.random(in: 0.25...0.95),
            opacity: CGFloat.random(in: 0.42...0.88),
            isCrystal: radius > 3.6 && Int.random(in: 0...3) == 0
        )
    }

    private func step() {
        let w = bounds.width
        let h = bounds.height
        guard w > 0, h > 0 else { return }

        time += 1.0 / 30.0

        let speedMult: CGFloat
        let windGust: CGFloat
        if currentIntensity <= 0.4 {
            speedMult = 0.70
            windGust = 0.0
        } else if currentIntensity <= 0.75 {
            speedMult = 1.05
            windGust = 0.15
        } else {
            speedMult = 2.25
            windGust = CGFloat(2.2 + 1.4 * sin(time * 1.3))
        }

        for i in 0..<flakes.count {
            flakes[i].y -= flakes[i].speedY * speedMult
            flakes[i].x += windGust + CGFloat(sin(time * flakes[i].driftSpeed + flakes[i].driftPhase)) * flakes[i].driftAmp * (currentIntensity > 0.75 ? 1.6 : 1.0)

            if flakes[i].y < -10 {
                flakes[i] = makeFlake(width: w, height: h, randomY: false)
            }
            if flakes[i].x < -10 { flakes[i].x = w + 5 }
            if flakes[i].x > w + 10 { flakes[i].x = -5 }
        }
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill()
        dirtyRect.fill()

        for flake in flakes {
            if flake.isCrystal {
                drawCrystalFlake(flake)
            } else {
                NSColor.white.withAlphaComponent(flake.opacity).setFill()
                let rect = NSRect(
                    x: flake.x - flake.radius,
                    y: flake.y - flake.radius,
                    width: flake.radius * 2,
                    height: flake.radius * 2
                )
                NSBezierPath(ovalIn: rect).fill()
            }
        }
    }

    private func drawCrystalFlake(_ flake: Snowflake) {
        let path = NSBezierPath()
        let r = flake.radius * 1.25
        for arm in 0..<3 {
            let angle = CGFloat(arm) * (.pi / 3.0)
            let dx = cos(angle) * r
            let dy = sin(angle) * r
            path.move(to: NSPoint(x: flake.x - dx, y: flake.y - dy))
            path.line(to: NSPoint(x: flake.x + dx, y: flake.y + dy))
        }
        path.lineWidth = 1.0
        path.lineCapStyle = .round
        NSColor.white.withAlphaComponent(flake.opacity * 0.92).setStroke()
        path.stroke()
    }
}

// MARK: - Top Lights View

private final class LightsOverlayView: NSView {
    var pattern: LightsPattern = .twinkle
    private var timer: Timer?
    private var time: Double = 0

    private let bulbPalette: [NSColor] = [
        NSColor(calibratedRed: 1.00, green: 0.22, blue: 0.22, alpha: 1.0), // Red
        NSColor(calibratedRed: 1.00, green: 0.80, blue: 0.16, alpha: 1.0), // Warm Gold
        NSColor(calibratedRed: 0.18, green: 0.86, blue: 0.36, alpha: 1.0), // Emerald
        NSColor(calibratedRed: 0.24, green: 0.72, blue: 1.00, alpha: 1.0), // Ice Blue
        NSColor(calibratedRed: 1.00, green: 0.94, blue: 0.76, alpha: 1.0)  // Warm White
    ]

    override var isOpaque: Bool { false }

    func start() {
        guard timer == nil else { return }
        let t = Timer(timeInterval: 1.0 / 20.0, repeats: true) { [weak self] _ in
            self?.time += 0.05
            self?.needsDisplay = true
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill()
        dirtyRect.fill()

        let w = bounds.width
        let h = bounds.height
        guard w > 20, h > 10 else { return }

        let spacing: CGFloat = 42.0
        let count = Int(w / spacing) + 2

        // 1. Dark pine wire festooned along the top
        let wire = NSBezierPath()
        wire.lineWidth = 1.6
        wire.move(to: NSPoint(x: 0, y: h - 2))
        for i in 0..<count {
            let xStart = CGFloat(i) * spacing
            let xEnd = xStart + spacing
            let xMid = (xStart + xEnd) * 0.5
            wire.curve(
                to: NSPoint(x: xEnd, y: h - 2),
                controlPoint1: NSPoint(x: xMid - spacing * 0.2, y: h - 11),
                controlPoint2: NSPoint(x: xMid + spacing * 0.2, y: h - 11)
            )
        }
        NSColor(calibratedRed: 0.08, green: 0.24, blue: 0.12, alpha: 0.88).setStroke()
        wire.stroke()

        // 2. Bulbs hanging at each festoon midpoint
        for i in 0..<count {
            let x = CGFloat(i) * spacing + spacing * 0.5
            if x > w + 12 { break }

            let baseColor = (pattern == .warmSteady)
                ? NSColor(calibratedRed: 1.0, green: 0.86, blue: 0.52, alpha: 1.0)
                : bulbPalette[i % bulbPalette.count]

            let brightness: Double
            switch pattern {
            case .twinkle:
                brightness = 0.45 + 0.55 * abs(sin(time * 2.2 + Double(i) * 1.15))
            case .wave:
                brightness = 0.30 + 0.70 * (0.5 + 0.5 * sin(time * 3.8 - Double(i) * 0.55))
            case .warmSteady:
                brightness = 0.78 + 0.16 * sin(time * 1.2 + Double(i) * 0.4)
            }

            let socketTopY = h - 7.5
            // Socket
            NSColor(calibratedRed: 0.12, green: 0.22, blue: 0.14, alpha: 0.95).setFill()
            NSBezierPath(roundedRect: NSRect(x: x - 2.0, y: socketTopY - 3.5, width: 4.0, height: 4.0), xRadius: 0.8, yRadius: 0.8).fill()

            let bulbCenterY = socketTopY - 7.8
            let glowRadius: CGFloat = 11.5 * CGFloat(0.7 + 0.35 * brightness)
            let glowRect = NSRect(
                x: x - glowRadius,
                y: bulbCenterY - glowRadius,
                width: glowRadius * 2,
                height: glowRadius * 2
            )

            if let gradient = NSGradient(colors: [
                baseColor.withAlphaComponent(CGFloat(0.55 * brightness)),
                baseColor.withAlphaComponent(0.0)
            ]) {
                gradient.draw(in: NSBezierPath(ovalIn: glowRect), relativeCenterPosition: .zero)
            }

            // Bulb glass
            let bulbRect = NSRect(x: x - 3.1, y: bulbCenterY - 4.3, width: 6.2, height: 8.6)
            baseColor.withAlphaComponent(CGFloat(0.55 + 0.45 * brightness)).setFill()
            NSBezierPath(ovalIn: bulbRect).fill()

            // Bright filament core
            NSColor.white.withAlphaComponent(CGFloat(0.55 * brightness)).setFill()
            NSBezierPath(ovalIn: NSRect(x: x - 1.3, y: bulbCenterY - 1.8, width: 2.6, height: 3.6)).fill()
        }
    }
}
