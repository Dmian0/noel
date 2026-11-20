import AppKit
import QuartzCore
import Darwin

/// Manages click-through transparent overlay windows for falling snow and top holiday lights.
final class ScreenEffectsManager {
    static let shared = ScreenEffectsManager()

    private var snowEntries: [CGDirectDisplayID: (window: NSWindow, view: SnowOverlayView)] = [:]
    private var lightsEntries: [CGDirectDisplayID: (window: NSWindow, view: LightsOverlayView)] = [:]
    private var santaEntries: [CGDirectDisplayID: (window: NSWindow, view: SantaSleighOverlayView)] = [:]
    private var santaTimer: Timer?

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
        if state.isEffectsPausedForCall {
            updateSnow(enabled: false, intensity: state.snowIntensity, screenMode: state.screenTargetMode, layerMode: state.snowLayerMode)
            updateLights(enabled: false, pattern: state.lightsPattern, palette: state.lightsPalette, style: state.lightsStyle, screenMode: state.screenTargetMode)
            updateSantaSchedule(frequency: .off, screenMode: state.screenTargetMode)
            return
        }

        updateSnow(enabled: state.isSnowing, intensity: state.snowIntensity, screenMode: state.screenTargetMode, layerMode: state.snowLayerMode)
        updateLights(enabled: state.showTopLights, pattern: state.lightsPattern, palette: state.lightsPalette, style: state.lightsStyle, screenMode: state.screenTargetMode)
        updateSantaSchedule(frequency: state.santaFrequency, screenMode: state.screenTargetMode)
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

    private func updateSnow(enabled: Bool, intensity: Double, screenMode: ScreenTargetMode, layerMode: SnowLayerMode) {
        if !enabled {
            for (_, entry) in snowEntries {
                entry.view.stop()
                entry.window.orderOut(nil)
            }
            snowEntries.removeAll()
            malloc_zone_pressure_relief(nil, 0)
            return
        }

        let targets = targetScreens(for: screenMode)
        let activeIDs = Set(targets.map { $0.id })

        for (id, entry) in snowEntries where !activeIDs.contains(id) {
            entry.view.stop()
            entry.window.orderOut(nil)
            snowEntries.removeValue(forKey: id)
        }

        let targetLevel: NSWindow.Level = (layerMode == .desktopOnly)
            ? NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
            : .floating

        for (id, screen) in targets {
            let frame = screen.frame
            if let entry = snowEntries[id] {
                entry.window.level = targetLevel
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
                win.colorSpace = .sRGB
                win.depthLimit = .twentyfourBitRGB
                win.isOpaque = false
                win.backgroundColor = .clear
                win.hasShadow = false
                win.ignoresMouseEvents = true
                win.level = targetLevel
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

    private func updateLights(enabled: Bool, pattern: LightsPattern, palette: LightsPalette, style: IconStyle, screenMode: ScreenTargetMode) {
        if !enabled {
            for (_, entry) in lightsEntries {
                entry.view.stop()
                entry.window.orderOut(nil)
            }
            lightsEntries.removeAll()
            malloc_zone_pressure_relief(nil, 0)
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
                entry.view.palette = palette
                entry.view.lightsStyle = style
                entry.view.start()
                entry.window.orderFrontRegardless()
            } else {
                let win = NSWindow(
                    contentRect: frame,
                    styleMask: [.borderless],
                    backing: .buffered,
                    defer: false
                )
                win.colorSpace = .sRGB
                win.depthLimit = .twentyfourBitRGB
                win.isOpaque = false
                win.backgroundColor = .clear
                win.hasShadow = false
                win.ignoresMouseEvents = true
                win.level = .floating
                win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]

                let view = LightsOverlayView(frame: NSRect(origin: .zero, size: frame.size))
                win.contentView = view
                view.pattern = pattern
                view.palette = palette
                view.lightsStyle = style
                view.start()
                win.orderFrontRegardless()

                lightsEntries[id] = (window: win, view: view)
            }
        }
    }

    // MARK: - Santa Sleigh Overlay

    private func updateSantaSchedule(frequency: SantaFrequency, screenMode: ScreenTargetMode) {
        santaTimer?.invalidate()
        santaTimer = nil

        let targets = targetScreens(for: screenMode)
        let activeIDs = Set(targets.map { $0.id })
        for (id, entry) in santaEntries where !activeIDs.contains(id) {
            entry.view.stop()
            entry.window.orderOut(nil)
            santaEntries.removeValue(forKey: id)
        }

        guard let interval = frequency.intervalSeconds else {
            for (_, entry) in santaEntries {
                entry.view.stop()
                entry.window.orderOut(nil)
            }
            santaEntries.removeAll()
            return
        }

        let t = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.triggerSantaFlightNow()
        }
        RunLoop.main.add(t, forMode: .common)
        santaTimer = t
    }

    func triggerSantaFlightNow() {
        guard !AppState.shared.isEffectsPausedForCall else { return }
        let targets = targetScreens(for: AppState.shared.screenTargetMode)
        guard !targets.isEmpty else { return }

        let leftToRight = Bool.random()
        let style = AppState.shared.iconStyle
        AudioManager.shared.playSleighBells(leftToRight: leftToRight)

        for (id, screen) in targets {
            let frame = screen.frame

            let entry: (window: NSWindow, view: SantaSleighOverlayView)
            if let existing = santaEntries[id] {
                existing.window.setFrame(frame, display: true)
                existing.view.frame = NSRect(origin: .zero, size: frame.size)
                entry = existing
            } else {
                let win = NSWindow(
                    contentRect: frame,
                    styleMask: [.borderless],
                    backing: .buffered,
                    defer: false
                )
                win.colorSpace = .sRGB
                win.depthLimit = .twentyfourBitRGB
                win.isReleasedWhenClosed = false
                win.isOpaque = false
                win.backgroundColor = .clear
                win.hasShadow = false
                win.ignoresMouseEvents = true
                win.level = .floating
                win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]

                let view = SantaSleighOverlayView(frame: NSRect(origin: .zero, size: frame.size))
                view.wantsLayer = true
                view.layer?.contentsScale = 1.0
                win.contentView = view
                entry = (window: win, view: view)
                santaEntries[id] = entry
            }

            entry.window.orderFrontRegardless()
            entry.view.startFlight(leftToRight: leftToRight, style: style) { [weak self] in
                guard let self = self else { return }
                if let active = self.santaEntries.removeValue(forKey: id) {
                    active.view.stop()
                    active.window.orderOut(nil)
                    active.window.close()
                    malloc_zone_pressure_relief(nil, 0)
                }
            }
        }
    }

    func handleSnowballImpact(atScreenPoint screenPt: NSPoint) -> Bool {
        for (_, entry) in lightsEntries {
            let localPt = entry.window.convertPoint(fromScreen: screenPt)
            if localPt.x >= 0 && localPt.x <= entry.view.bounds.width && localPt.y >= -24 && localPt.y <= entry.view.bounds.height + 20 {
                entry.view.applySnowballImpulse(atX: localPt.x)
                return true
            }
        }
        for (_, entry) in santaEntries {
            if entry.view.handleSnowballImpact(at: screenPt) {
                return true
            }
        }
        return false
    }

    func handleSantaCrashLanding(onWindow santaWindow: NSWindow?, atLocalX localX: CGFloat) {
        for (_, entry) in snowEntries {
            if santaWindow == nil || abs(entry.window.frame.origin.x - (santaWindow?.frame.origin.x ?? 0)) < 10 {
                entry.view.receiveSantaCrash(atLocalX: localX)
            }
        }
    }

    func handleGiftLandedOnSnow(onWindow santaWindow: NSWindow?, atLocalX localX: CGFloat, style: IconStyle) {
        for (_, entry) in snowEntries {
            if santaWindow == nil || abs(entry.window.frame.origin.x - (santaWindow?.frame.origin.x ?? 0)) < 10 {
                entry.view.addLandedGift(atLocalX: localX, style: style)
            }
        }
    }

    func groundedSantaX(onWindow snowWindow: NSWindow?) -> CGFloat? {
        for (_, entry) in santaEntries {
            if snowWindow == nil || abs(entry.window.frame.origin.x - (snowWindow?.frame.origin.x ?? 0)) < 10 {
                if let x = entry.view.groundedSantaLocalX {
                    return x
                }
            }
        }
        return nil
    }

    func assistGroundedSanta(onWindow snowWindow: NSWindow?, amount: Double) {
        for (_, entry) in santaEntries {
            if snowWindow == nil || abs(entry.window.frame.origin.x - (snowWindow?.frame.origin.x ?? 0)) < 10 {
                entry.view.assistSantaRecovery(amount: amount)
            }
        }
    }
}


// MARK: - Top Lights View

private final class LightsOverlayView: NSView {
    var pattern: LightsPattern = .twinkle
    var palette: LightsPalette = .classic
    var lightsStyle: IconStyle = .colorful
    private var lastWireStyle: IconStyle = .colorful
    private var timer: Timer?
    private var time: Double = 0
    private var bulbAngles: [CGFloat] = []
    private var bulbVelocities: [CGFloat] = []
    private var bulbFlashes: [CGFloat] = []
    private var audioBass: Double = 0.25
    private var audioTreble: Double = 0.25
    private var audioActive: Bool = false
    private var lastMouseX: CGFloat?
    private var lastWireWidth: CGFloat = -1

    private let wireLayer = CAShapeLayer()

    private static let noAnimActions: [String: CAAction] = [
        "position": NSNull(),
        "bounds": NSNull(),
        "opacity": NSNull(),
        "contents": NSNull(),
        "hidden": NSNull(),
        "transform": NSNull(),
        "backgroundColor": NSNull(),
        "path": NSNull()
    ]

    private static var glowImageCache: [String: CGImage] = [:]

    private static func glowImage(for color: NSColor, pixelArt: Bool, key: String) -> CGImage? {
        if let cached = glowImageCache[key] {
            return cached
        }
        let size = 44
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: size * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        let rgb = color.usingColorSpace(.deviceRGB) ?? color
        var r: CGFloat = 1, g: CGFloat = 1, b: CGFloat = 1, a: CGFloat = 1
        rgb.getRed(&r, green: &g, blue: &b, alpha: &a)

        let mid = CGFloat(size) * 0.5
        if pixelArt {
            ctx.setShouldAntialias(false)
            let rings: [(CGFloat, CGFloat)] = [
                (18.0, 0.10),
                (13.0, 0.22),
                (9.0, 0.42),
                (5.0, 0.78)
            ]
            for (rad, alpha) in rings {
                ctx.setFillColor(red: r, green: g, blue: b, alpha: alpha)
                let step: CGFloat = 2.0
                var py: CGFloat = mid - rad
                while py < mid + rad {
                    var px: CGFloat = mid - rad
                    while px < mid + rad {
                        let dx = (px + 1.0) - mid
                        let dy = (py + 1.0) - mid
                        if hypot(dx, dy) <= rad {
                            ctx.fill(CGRect(x: px, y: py, width: step, height: step))
                        }
                        px += step
                    }
                    py += step
                }
            }
        } else {
            let colors = [
                CGColor(colorSpace: colorSpace, components: [r, g, b, 0.92])!,
                CGColor(colorSpace: colorSpace, components: [r, g, b, 0.46])!,
                CGColor(colorSpace: colorSpace, components: [r, g, b, 0.14])!,
                CGColor(colorSpace: colorSpace, components: [r, g, b, 0.0])!
            ] as CFArray
            let locations: [CGFloat] = [0.0, 0.32, 0.68, 1.0]
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
                let center = CGPoint(x: mid, y: mid)
                ctx.drawRadialGradient(
                    gradient,
                    startCenter: center,
                    startRadius: 0,
                    endCenter: center,
                    endRadius: mid,
                    options: []
                )
            }
        }

        if let img = ctx.makeImage() {
            glowImageCache[key] = img
            return img
        }
        return nil
    }

    private final class BulbLayers {
        let glowLayer = CALayer()
        let dropWireLayer = CALayer()
        let socketLayer = CALayer()
        let bulbLayer = CALayer()
        let filamentLayer = CALayer()
        let specularLayer = CALayer()

        init(root: CALayer, actions: [String: CAAction]) {
            glowLayer.actions = actions
            dropWireLayer.actions = actions
            socketLayer.actions = actions
            bulbLayer.actions = actions
            filamentLayer.actions = actions
            specularLayer.actions = actions

            socketLayer.bounds = CGRect(x: 0, y: 0, width: 4.0, height: 4.0)
            socketLayer.cornerRadius = 0.8
            socketLayer.backgroundColor = NSColor(calibratedRed: 0.11, green: 0.22, blue: 0.13, alpha: 0.95).cgColor
            socketLayer.borderWidth = 0.6
            socketLayer.borderColor = NSColor(calibratedRed: 0.72, green: 0.58, blue: 0.24, alpha: 0.75).cgColor

            dropWireLayer.bounds = CGRect(x: 0, y: 0, width: 1.0, height: 8.2)
            dropWireLayer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
            dropWireLayer.backgroundColor = NSColor(calibratedRed: 0.08, green: 0.24, blue: 0.12, alpha: 0.88).cgColor

            bulbLayer.bounds = CGRect(x: 0, y: 0, width: 6.2, height: 8.6)
            bulbLayer.cornerRadius = 3.1

            filamentLayer.bounds = CGRect(x: 0, y: 0, width: 2.6, height: 3.6)
            filamentLayer.cornerRadius = 1.3
            filamentLayer.backgroundColor = NSColor.white.cgColor

            specularLayer.bounds = CGRect(x: 0, y: 0, width: 1.8, height: 2.4)
            specularLayer.cornerRadius = 0.9
            specularLayer.backgroundColor = NSColor.white.cgColor
            specularLayer.opacity = 0.65

            root.addSublayer(glowLayer)
            root.addSublayer(dropWireLayer)
            root.addSublayer(socketLayer)
            root.addSublayer(bulbLayer)
            root.addSublayer(filamentLayer)
            root.addSublayer(specularLayer)
        }

        func setHidden(_ hidden: Bool) {
            glowLayer.isHidden = hidden
            dropWireLayer.isHidden = hidden
            socketLayer.isHidden = hidden
            bulbLayer.isHidden = hidden
            filamentLayer.isHidden = hidden
            specularLayer.isHidden = hidden
        }
    }

    private var bulbLayerPool: [BulbLayers] = []

    override var isOpaque: Bool { false }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layerContentsRedrawPolicy = .onSetNeedsDisplay
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layerContentsRedrawPolicy = .onSetNeedsDisplay
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        wantsLayer = true
        guard let root = layer else { return }
        root.contentsScale = 1.0
        if wireLayer.superlayer == nil {
            wireLayer.actions = Self.noAnimActions
            wireLayer.fillColor = nil
            wireLayer.strokeColor = NSColor(calibratedRed: 0.08, green: 0.24, blue: 0.12, alpha: 0.88).cgColor
            wireLayer.lineWidth = 1.6
            root.addSublayer(wireLayer)
        }
    }

    func start() {
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
        bulbAngles.removeAll()
        bulbVelocities.removeAll()
        bulbFlashes.removeAll()
        lastMouseX = nil
        lastWireWidth = -1
        lastWireStyle = .colorful

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        wireLayer.path = nil
        for b in bulbLayerPool { b.setHidden(true) }
        CATransaction.commit()

        malloc_zone_pressure_relief(nil, 0)
    }

    func applySnowballImpulse(atX hitX: CGFloat) {
        let count = bulbVelocities.count
        for i in 0..<count {
            let bulbRestX = CGFloat(i) * 42.0 + 21.0
            let dist = abs(hitX - bulbRestX)
            if dist < 95.0 {
                let dir: CGFloat = (bulbRestX >= hitX) ? 1.0 : -1.0
                let strength = (1.0 - dist / 95.0) * 0.48
                bulbVelocities[i] += dir * strength + CGFloat.random(in: (-0.12)...0.12)
                if i < bulbFlashes.count {
                    bulbFlashes[i] = min(1.0, max(bulbFlashes[i], (1.0 - dist / 95.0) * 1.15))
                }
            }
        }
    }

    private func colors(for palette: LightsPalette) -> [NSColor] {
        switch palette {
        case .classic:
            return [
                NSColor(calibratedRed: 1.00, green: 0.22, blue: 0.22, alpha: 1.0), // Rojo
                NSColor(calibratedRed: 1.00, green: 0.80, blue: 0.16, alpha: 1.0), // Dorado Calido
                NSColor(calibratedRed: 0.18, green: 0.86, blue: 0.36, alpha: 1.0), // Esmeralda
                NSColor(calibratedRed: 0.24, green: 0.72, blue: 1.00, alpha: 1.0), // Azul Hielo
                NSColor(calibratedRed: 1.00, green: 0.94, blue: 0.76, alpha: 1.0)  // Blanco Calido
            ]
        case .warm:
            return [
                NSColor(calibratedRed: 1.00, green: 0.78, blue: 0.32, alpha: 1.0), // Ambar Calido
                NSColor(calibratedRed: 1.00, green: 0.86, blue: 0.52, alpha: 1.0), // Oro Viejo
                NSColor(calibratedRed: 1.00, green: 0.95, blue: 0.80, alpha: 1.0)  // Blanco Incandescente
            ]
        case .candyCane:
            return [
                NSColor(calibratedRed: 0.96, green: 0.14, blue: 0.20, alpha: 1.0), // Rojo Carmesi
                NSColor(calibratedRed: 0.98, green: 0.98, blue: 1.00, alpha: 1.0), // Blanco Nieve
                NSColor(calibratedRed: 1.00, green: 0.30, blue: 0.36, alpha: 1.0), // Rojo Menta
                NSColor(calibratedRed: 0.98, green: 0.98, blue: 1.00, alpha: 1.0)  // Blanco Nieve
            ]
        case .nordicIce:
            return [
                NSColor(calibratedRed: 0.20, green: 0.62, blue: 0.98, alpha: 1.0), // Azul Artico
                NSColor(calibratedRed: 0.48, green: 0.88, blue: 1.00, alpha: 1.0), // Cian Glaciar
                NSColor(calibratedRed: 0.92, green: 0.98, blue: 1.00, alpha: 1.0), // Blanco Escarcha
                NSColor(calibratedRed: 0.35, green: 0.76, blue: 1.00, alpha: 1.0)  // Azul Cielo
            ]
        case .pineGold:
            return [
                NSColor(calibratedRed: 0.14, green: 0.68, blue: 0.36, alpha: 1.0), // Verde Pino
                NSColor(calibratedRed: 0.95, green: 0.78, blue: 0.24, alpha: 1.0), // Oro Laton
                NSColor(calibratedRed: 1.00, green: 0.92, blue: 0.70, alpha: 1.0), // Champan
                NSColor(calibratedRed: 0.10, green: 0.52, blue: 0.28, alpha: 1.0)  // Esmeralda Bosque
            ]
        }
    }

    private func step() {
        time += 1.0 / 30.0

        let count = Int(max(bounds.width, 800) / 42.0) + 2
        if bulbAngles.count != count {
            bulbAngles = Array(repeating: 0, count: count)
            bulbVelocities = Array(repeating: 0, count: count)
        }
        if bulbFlashes.count != count {
            bulbFlashes = Array(repeating: 0, count: count)
        }

        let mousePt = window?.convertPoint(fromScreen: NSEvent.mouseLocation)
        if let mp = mousePt {
            let mouseDX = mp.x - (lastMouseX ?? mp.x)
            lastMouseX = mp.x

            if mp.y >= -15 && mp.y <= bounds.height + 15 {
                let impulse = max(-0.22, min(0.22, mouseDX * 0.015))
                for i in 0..<count {
                    let bulbRestX = CGFloat(i) * 42.0 + 21.0
                    if abs(mp.x - bulbRestX) < 32.0 {
                        bulbVelocities[i] += impulse
                    }
                }
            }
        } else {
            lastMouseX = nil
        }

        for i in 0..<count {
            bulbVelocities[i] = (bulbVelocities[i] - 0.18 * bulbAngles[i]) * 0.88
            bulbAngles[i] = max(-0.65, min(0.65, bulbAngles[i] + bulbVelocities[i]))
            bulbFlashes[i] *= 0.88
        }

        if pattern == .rhythm {
            let levels = AudioManager.shared.currentAudioLevels(at: time)
            audioBass = levels.bass
            audioTreble = levels.treble
            audioActive = levels.isActive

            if audioActive && audioBass > 0.70 {
                let bassImpulse = CGFloat((audioBass - 0.70) * 0.08)
                for i in 0..<count {
                    let dir: CGFloat = (i % 2 == 0) ? 1.0 : -1.0
                    bulbVelocities[i] += dir * bassImpulse
                }
            }
        } else {
            audioActive = false
        }

        guard let root = layer else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let w = bounds.width
        let h = bounds.height
        if (abs(lastWireWidth - w) > 0.5 || lastWireStyle != lightsStyle) && w > 20 && h > 10 {
            lastWireWidth = w
            lastWireStyle = lightsStyle
            let spacing: CGFloat = 42.0
            let festoonCount = Int(w / spacing) + 2

            let wirePath = CGMutablePath()

            if lightsStyle == .pixelArt {
                wirePath.move(to: CGPoint(x: 0, y: h - 2))
                for i in 0..<festoonCount {
                    let xStart = CGFloat(i) * spacing
                    var currYWire = h - 2

                    for stepIdx in 0..<14 {
                        let t = (Double(stepIdx) + 0.5) / 14.0
                        let dip = sin(t * .pi) * 7.0
                        let dipRounded = CGFloat(round(dip / 3.0) * 3.0)
                        let nextX = xStart + CGFloat(stepIdx + 1) * 3.0
                        let nextYWire = (h - 2) - dipRounded

                        wirePath.addLine(to: CGPoint(x: nextX, y: currYWire))
                        wirePath.addLine(to: CGPoint(x: nextX, y: nextYWire))
                        currYWire = nextYWire
                    }
                    wirePath.addLine(to: CGPoint(x: xStart + spacing, y: h - 2))
                }
            } else {
                wirePath.move(to: CGPoint(x: 0, y: h - 2))
                for i in 0..<festoonCount {
                    let xStart = CGFloat(i) * spacing
                    let xEnd = xStart + spacing
                    let xMid = (xStart + xEnd) * 0.5
                    wirePath.addCurve(
                        to: CGPoint(x: xEnd, y: h - 2),
                        control1: CGPoint(x: xMid - spacing * 0.2, y: h - 11),
                        control2: CGPoint(x: xMid + spacing * 0.2, y: h - 11)
                    )
                }
            }
            wireLayer.path = wirePath
        }

        let spacing: CGFloat = 42.0
        let activePalette = colors(for: palette)

        while bulbLayerPool.count < count {
            bulbLayerPool.append(BulbLayers(root: root, actions: Self.noAnimActions))
        }

        let socketTopY = h - 7.5
        for i in 0..<count {
            let x = CGFloat(i) * spacing + spacing * 0.5
            if x > w + 12 {
                bulbLayerPool[i].setHidden(true)
                continue
            }

            let baseColor = activePalette[i % activePalette.count]

            let brightness: Double
            switch pattern {
            case .twinkle:
                brightness = 0.45 + 0.55 * abs(sin(time * 2.2 + Double(i) * 1.15))
            case .wave:
                brightness = 0.30 + 0.70 * (0.5 + 0.5 * sin(time * 3.8 - Double(i) * 0.55))
            case .warmSteady:
                brightness = 0.78 + 0.16 * sin(time * 1.2 + Double(i) * 0.4)
            case .rhythm:
                let centerDistRatio = abs(Double(x - w * 0.5) / Double(max(w * 0.5, 1.0)))
                if i % 2 == 0 {
                    let waveComponent = 0.5 + 0.5 * sin(time * 7.5 - centerDistRatio * 4.5)
                    brightness = 0.30 + 0.70 * (audioActive ? (0.65 * audioBass + 0.35 * waveComponent) : waveComponent)
                } else {
                    let flashComponent = abs(sin(time * 12.0 + Double(i) * 0.9))
                    brightness = 0.30 + 0.70 * (audioActive ? (0.65 * audioTreble + 0.35 * flashComponent) : flashComponent)
                }
            }

            let flash = i < bulbFlashes.count ? Double(bulbFlashes[i]) : 0.0
            let totalBrightness = min(1.55, brightness + flash * 0.65)

            let angle = i < bulbAngles.count ? bulbAngles[i] : 0
            let bulbX = x + sin(angle) * 8.5
            let bulbCenterY = socketTopY - cos(angle) * 7.8

            let bulb = bulbLayerPool[i]
            bulb.setHidden(false)

            bulb.socketLayer.position = CGPoint(x: x, y: socketTopY - 1.5)

            bulb.dropWireLayer.position = CGPoint(x: x, y: socketTopY - 2.0)
            bulb.dropWireLayer.transform = CATransform3DMakeRotation(angle, 0, 0, 1)

            let colorIndex = i % activePalette.count
            let glowKey = "\(palette.rawValue)-\(colorIndex)-\(lightsStyle == .pixelArt ? "px" : "3d")"
            bulb.glowLayer.contents = Self.glowImage(for: baseColor, pixelArt: lightsStyle == .pixelArt, key: glowKey)
            bulb.glowLayer.magnificationFilter = (lightsStyle == .pixelArt) ? .nearest : .linear
            let glowDiameter = 30.0 * CGFloat(0.75 + 0.32 * totalBrightness)
            bulb.glowLayer.bounds = CGRect(x: 0, y: 0, width: glowDiameter, height: glowDiameter)
            bulb.glowLayer.position = CGPoint(x: bulbX, y: bulbCenterY)
            bulb.glowLayer.opacity = Float(min(0.98, 0.52 + 0.46 * totalBrightness))

            bulb.bulbLayer.position = CGPoint(x: bulbX, y: bulbCenterY)
            bulb.bulbLayer.backgroundColor = baseColor.cgColor
            bulb.bulbLayer.opacity = Float(min(1.0, 0.55 + 0.45 * totalBrightness))

            let filamentAlpha = Float(min(1.0, 0.55 * totalBrightness + flash * 0.35))
            bulb.filamentLayer.position = CGPoint(x: bulbX, y: bulbCenterY)
            bulb.filamentLayer.opacity = filamentAlpha

            bulb.specularLayer.position = CGPoint(x: bulbX - 1.3, y: bulbCenterY + 1.6)
            bulb.specularLayer.opacity = Float(min(0.72, 0.35 + 0.30 * totalBrightness))

            if lightsStyle == .pixelArt {
                bulb.socketLayer.cornerRadius = 0
                bulb.dropWireLayer.bounds = CGRect(x: 0, y: 0, width: 2.0, height: 8.2)
                bulb.bulbLayer.bounds = CGRect(x: 0, y: 0, width: 7.0, height: 9.0)
                bulb.bulbLayer.cornerRadius = 1.0
                bulb.filamentLayer.bounds = CGRect(x: 0, y: 0, width: 3.0, height: 3.0)
                bulb.filamentLayer.cornerRadius = 0
                bulb.specularLayer.bounds = CGRect(x: 0, y: 0, width: 1.8, height: 2.0)
                bulb.specularLayer.cornerRadius = 0
            } else {
                bulb.socketLayer.cornerRadius = 0.8
                bulb.dropWireLayer.bounds = CGRect(x: 0, y: 0, width: 1.0, height: 8.2)
                bulb.bulbLayer.bounds = CGRect(x: 0, y: 0, width: 6.2, height: 8.6)
                bulb.bulbLayer.cornerRadius = 3.1
                bulb.filamentLayer.bounds = CGRect(x: 0, y: 0, width: 2.6, height: 3.6)
                bulb.filamentLayer.cornerRadius = 1.3
                bulb.specularLayer.bounds = CGRect(x: 0, y: 0, width: 1.8, height: 2.4)
                bulb.specularLayer.cornerRadius = 0.9
            }
        }

        for i in count..<bulbLayerPool.count {
            bulbLayerPool[i].setHidden(true)
        }

        CATransaction.commit()
    }
}
