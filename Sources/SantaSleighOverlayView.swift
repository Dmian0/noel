import AppKit
import QuartzCore
import Darwin

// MARK: - Santa Sleigh Overlay View
final class SantaSleighOverlayView: NSView {
    override var isOpaque: Bool { false }
    override var isFlipped: Bool { false }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        wantsLayer = true
        guard let root = layer else { return }
        root.contentsScale = 1.0
        if sleighLayer.superlayer == nil {
            sleighLayer.bounds = CGRect(x: 0, y: 0, width: 240, height: 80)
            sleighLayer.anchorPoint = CGPoint(x: 100.0 / 240.0, y: 32.0 / 80.0)
            sleighLayer.actions = Self.noAnimActions
            sleighLayer.isHidden = true
            root.addSublayer(sleighLayer)
        }
    }

    // MARK: - Static Assets & Actions
    private static let noAnimActions: [String: CAAction] = [
        "position": NSNull(),
        "bounds": NSNull(),
        "opacity": NSNull(),
        "contents": NSNull(),
        "hidden": NSNull(),
        "transform": NSNull()
    ]

    private static func createSparkleImage() -> CGImage? {
        let size = 12
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

        let s: CGFloat = 5.0
        let mid = CGFloat(size) * 0.5
        ctx.setFillColor(red: 1.0, green: 0.94, blue: 0.65, alpha: 1.0)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: mid, y: mid + s))
        ctx.addLine(to: CGPoint(x: mid + s * 0.28, y: mid))
        ctx.addLine(to: CGPoint(x: mid + s, y: mid))
        ctx.addLine(to: CGPoint(x: mid + s * 0.28, y: mid - s * 0.28))
        ctx.addLine(to: CGPoint(x: mid, y: mid - s))
        ctx.addLine(to: CGPoint(x: mid - s * 0.28, y: mid))
        ctx.addLine(to: CGPoint(x: mid - s, y: mid))
        ctx.addLine(to: CGPoint(x: mid - s * 0.28, y: mid + s * 0.28))
        ctx.closePath()
        ctx.fillPath()
        return ctx.makeImage()
    }

    private static func createDotImage() -> CGImage? {
        let size = 10
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

        ctx.setFillColor(red: 0.95, green: 0.82, blue: 0.32, alpha: 1.0)
        ctx.fillEllipse(in: CGRect(x: 1, y: 1, width: 8, height: 8))
        return ctx.makeImage()
    }

    private static func createGiftImage(pixelArt: Bool) -> CGImage? {
        let w = 32
        let h = 40
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: w * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        let gx: CGFloat = 16.0
        let gy: CGFloat = 12.0

        ctx.setStrokeColor(red: 0.94, green: 0.90, blue: 0.82, alpha: 0.85)
        ctx.setLineWidth(0.8)
        ctx.strokeLineSegments(between: [
            CGPoint(x: gx - 10, y: gy + 14), CGPoint(x: gx - 4, y: gy + 6),
            CGPoint(x: gx + 10, y: gy + 14), CGPoint(x: gx + 4, y: gy + 6)
        ])

        ctx.setFillColor(red: 0.96, green: 0.94, blue: 0.90, alpha: 1.0)
        if pixelArt {
            for (dy, width) in [(14, 20), (16, 18), (18, 14), (20, 10), (22, 6)] {
                ctx.fill(CGRect(x: gx - CGFloat(width) * 0.5, y: gy + CGFloat(dy), width: CGFloat(width), height: 2))
            }
        } else {
            ctx.beginPath()
            ctx.addArc(center: CGPoint(x: gx, y: gy + 14), radius: 10.5, startAngle: 0, endAngle: .pi, clockwise: false)
            ctx.closePath()
            ctx.fillPath()
        }

        let box = CGRect(x: gx - 6, y: gy - 6, width: 12, height: 12)
        ctx.setFillColor(red: 0.72, green: 0.18, blue: 0.18, alpha: 1.0)
        if pixelArt {
            ctx.fill(box)
        } else {
            ctx.addPath(CGPath(roundedRect: box, cornerWidth: 1.5, cornerHeight: 1.5, transform: nil))
            ctx.fillPath()
        }

        ctx.setFillColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 1.0)
        ctx.fill(CGRect(x: gx - 6, y: gy - 1, width: 12, height: 2))
        ctx.fill(CGRect(x: gx - 1, y: gy - 6, width: 2, height: 12))
        ctx.fill(CGRect(x: gx - 2.5, y: gy + 5, width: 5, height: 2))

        return ctx.makeImage()
    }

    private static let goldSparkleImage: CGImage? = createSparkleImage()
    private static let goldDotImage: CGImage? = createDotImage()
    private static let giftColorfulImage: CGImage? = createGiftImage(pixelArt: false)
    private static let giftPixelImage: CGImage? = createGiftImage(pixelArt: true)

    // MARK: - Internal Types
    private enum FlightState {
        case cruising
        case crashing
        case grounded
        case recovering
    }

    private struct StardustParticle {
        var x, y, vx, vy: CGFloat
        var age, maxAge: Double
        var size: CGFloat
        var twinklePhase: Double
        var isSparkle, isGold: Bool
    }

    private struct GiftDrop {
        var baseX, y, vy: CGFloat
        var age: Double
    }

    private enum FlightTrajectory: CaseIterable {
        case diagonalClimb, panoramicWave, centerDive, sweepingArc
    }

    // MARK: - Layers & State
    private let sleighLayer = CALayer()
    private var particleLayers: [CALayer] = []
    private var giftLayers: [CALayer] = []

    private var timer: Timer?
    private var leftToRight: Bool = true
    private var hasDroppedGift: Bool = false
    private var style: IconStyle = .colorful
    private var trajectory: FlightTrajectory = .panoramicWave
    private var onComplete: (() -> Void)?
    private var elapsed: Double = 0.0
    private let flightDuration: Double = 5.4
    private let totalDuration: Double = 6.2
    private var particles: [StardustParticle] = []
    private var giftDrops: [GiftDrop] = []

    private var flightState: FlightState = .cruising
    private var caravanX: CGFloat = 0
    private var caravanY: CGFloat = 0
    private var crashVX: CGFloat = 0
    private var crashVY: CGFloat = 0
    private var crashAngle: CGFloat = 0
    private var groundedTimer: Double = 0

    // MARK: - Public API
    var groundedSantaLocalX: CGFloat? {
        flightState == .grounded ? caravanX : nil
    }

    func assistSantaRecovery(amount: Double) {
        guard flightState == .grounded else { return }
        groundedTimer += amount
        if Int.random(in: 0...2) == 0 {
            particles.append(StardustParticle(
                x: caravanX + CGFloat.random(in: (-22)...22),
                y: caravanY + CGFloat.random(in: 4...22),
                vx: CGFloat.random(in: (-25)...25),
                vy: CGFloat.random(in: 18...48),
                age: 0.0,
                maxAge: 0.45,
                size: 3.4,
                twinklePhase: Double.random(in: 0...(.pi * 2)),
                isSparkle: true,
                isGold: true
            ))
        }
    }

    func startFlight(leftToRight: Bool, style: IconStyle, onComplete: @escaping () -> Void) {
        stop()
        self.leftToRight = leftToRight
        self.style = style
        self.trajectory = FlightTrajectory.allCases.randomElement() ?? .panoramicWave
        self.onComplete = onComplete
        self.elapsed = 0.0
        self.particles.removeAll()
        self.giftDrops.removeAll()
        self.hasDroppedGift = false
        self.flightState = .cruising
        self.caravanX = 0
        self.caravanY = 0
        self.crashVX = 0
        self.crashVY = 0
        self.crashAngle = 0
        self.groundedTimer = 0

        let t = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)
        self.timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        particles.removeAll()
        giftDrops.removeAll()
        hasDroppedGift = false
        elapsed = 0.0
        onComplete = nil
        flightState = .cruising
        caravanX = 0
        caravanY = 0
        crashVX = 0
        crashVY = 0
        crashAngle = 0
        groundedTimer = 0

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        sleighLayer.contents = nil
        sleighLayer.isHidden = true
        for l in particleLayers { l.isHidden = true }
        for l in giftLayers { l.isHidden = true }
        CATransaction.commit()

        malloc_zone_pressure_relief(nil, 0)
    }

    func handleSnowballImpact(at screenPoint: NSPoint) -> Bool {
        guard timer != nil, (flightState == .cruising || flightState == .recovering), let win = window else { return false }
        let pt = win.convertPoint(fromScreen: screenPoint)

        let targetX = caravanX
        let targetY = caravanY
        guard hypot(pt.x - targetX, pt.y - targetY) <= 82.0 else { return false }

        for _ in 0..<28 {
            let angle = Double.random(in: 0...(.pi * 2))
            let speed = CGFloat.random(in: 30...95)
            particles.append(StardustParticle(
                x: targetX + CGFloat.random(in: (-12)...12),
                y: targetY + CGFloat.random(in: (-10)...10),
                vx: CGFloat(cos(angle)) * speed,
                vy: CGFloat(sin(angle)) * speed,
                age: 0.0,
                maxAge: Double.random(in: 0.70...1.05),
                size: CGFloat.random(in: 2.8...5.5),
                twinklePhase: Double.random(in: 0...(.pi * 2)),
                isSparkle: true,
                isGold: Bool.random()
            ))
        }

        giftDrops.append(GiftDrop(baseX: targetX - 26.0, y: targetY - 6.0, vy: 56.0, age: 0.0))
        giftDrops.append(GiftDrop(baseX: targetX, y: targetY - 6.0, vy: 64.0, age: 0.0))
        giftDrops.append(GiftDrop(baseX: targetX + 26.0, y: targetY - 6.0, vy: 52.0, age: 0.0))

        flightState = .crashing
        let dir: CGFloat = leftToRight ? 1.0 : -1.0
        crashVX = dir * 110.0
        crashVY = 50.0
        crashAngle = 0.0
        return true
    }

    // MARK: - Trajectory Math
    private func yForProgress(_ p: Double, elapsed t: Double) -> CGFloat {
        let h = bounds.height > 0 ? bounds.height : 800.0
        switch trajectory {
        case .diagonalClimb:
            return h * (0.18 + 0.66 * CGFloat(p)) + CGFloat(sin(p * .pi * 2.0) * 35.0 + sin(t * 3.2) * 5.0)
        case .panoramicWave:
            return h * 0.50 + CGFloat(sin(p * .pi * 2.2 - 0.4) * (Double(h) * 0.28) + sin(t * 3.2) * 5.0)
        case .centerDive:
            return h * 0.78 - CGFloat(sin(p * .pi) * (Double(h) * 0.52)) + CGFloat(sin(t * 3.2) * 5.0)
        case .sweepingArc:
            return h * 0.28 + CGFloat(sin(p * .pi) * (Double(h) * 0.52) + cos(p * .pi * 3.0) * 28.0)
        }
    }

    private func computeTiltAngle(progress: Double, startX: CGFloat, endX: CGFloat) -> CGFloat {
        let pNext = min(1.0, progress + 0.01)
        let dy = yForProgress(pNext, elapsed: elapsed + 0.01) - yForProgress(progress, elapsed: elapsed)
        let dx = abs(endX - startX) * 0.01
        let rawAngle = atan2(dy, dx)
        return max(-0.30, min(0.30, rawAngle))
    }

    // MARK: - Animation Loop
    private func tick() {
        let dt = 1.0 / 30.0
        elapsed += dt
        let w = bounds.width > 0 ? bounds.width : 1200.0
        let h = bounds.height > 0 ? bounds.height : 800.0
        let startX = leftToRight ? -150.0 : w + 150.0
        let endX = leftToRight ? w + 150.0 : -150.0
        var currentAngle: CGFloat = 0.0

        switch flightState {
        case .cruising:
            let progress = min(1.0, elapsed / flightDuration)
            caravanX = startX + (endX - startX) * CGFloat(progress)
            caravanY = yForProgress(progress, elapsed: elapsed)
            currentAngle = computeTiltAngle(progress: progress, startX: startX, endX: endX)

            if elapsed < flightDuration {
                let dir: CGFloat = leftToRight ? 1.0 : -1.0
                spawnParticle(x: caravanX - dir * CGFloat.random(in: 40...72), y: caravanY + CGFloat.random(in: (-8)...14), dir: dir)
                spawnParticle(x: caravanX + dir * CGFloat.random(in: (-20)...24), y: caravanY + CGFloat.random(in: (-14)...2), dir: dir)
            }

            if progress >= 0.42 && !hasDroppedGift {
                hasDroppedGift = true
                let dir: CGFloat = leftToRight ? 1.0 : -1.0
                giftDrops.append(GiftDrop(baseX: caravanX - dir * 42.0, y: caravanY - 8.0, vy: 62.0, age: 0.0))
            }

        case .crashing:
            let dir: CGFloat = leftToRight ? 1.0 : -1.0
            caravanX += crashVX * CGFloat(dt)
            caravanY += crashVY * CGFloat(dt)
            crashVY -= 360.0 * CGFloat(dt)
            crashVX *= 0.985

            let minX: CGFloat = 75.0
            let maxX: CGFloat = max(75.0, w - 75.0)
            if caravanX < minX {
                caravanX = minX
                crashVX = -crashVX * 0.5
            } else if caravanX > maxX {
                caravanX = maxX
                crashVX = -crashVX * 0.5
            }

            crashAngle = max(-0.78, crashAngle - 1.85 * CGFloat(dt)) + CGFloat(sin(elapsed * 20.0)) * 0.05
            currentAngle = crashAngle
            spawnParticle(x: caravanX, y: caravanY + 6.0, dir: dir)

            if caravanY <= 24.0 {
                caravanY = 22.0
                flightState = .grounded
                groundedTimer = 0.0
                crashAngle = -0.24
                currentAngle = crashAngle
                ScreenEffectsManager.shared.handleSantaCrashLanding(onWindow: window, atLocalX: caravanX)
            }

        case .grounded:
            groundedTimer += dt
            caravanY = 22.0 + CGFloat(sin(groundedTimer * 7.5)) * 1.0
            crashAngle = -0.22 + CGFloat(sin(groundedTimer * 5.0)) * 0.05
            currentAngle = crashAngle

            if Int(groundedTimer * 30.0) % 2 == 0 {
                let starAngle = groundedTimer * 6.5
                particles.append(StardustParticle(
                    x: caravanX + CGFloat(cos(starAngle)) * 22.0,
                    y: caravanY + 26.0 + CGFloat(sin(starAngle)) * 6.0,
                    vx: 0,
                    vy: 8.0,
                    age: 0.0,
                    maxAge: 0.35,
                    size: 3.6,
                    twinklePhase: 0.0,
                    isSparkle: true,
                    isGold: true
                ))
            }

            if groundedTimer >= 3.2 {
                flightState = .recovering
                let dir: CGFloat = leftToRight ? 1.0 : -1.0
                crashVX = dir * 185.0
                crashVY = 135.0
            }

        case .recovering:
            let dir: CGFloat = leftToRight ? 1.0 : -1.0
            caravanX += crashVX * CGFloat(dt)
            caravanY += crashVY * CGFloat(dt)
            crashVY += 55.0 * CGFloat(dt)
            crashAngle = 0.28
            currentAngle = crashAngle
            spawnParticle(x: caravanX - dir * 35.0, y: caravanY - 4.0, dir: dir)
        }

        // Update stardust particles
        for i in (0..<particles.count).reversed() {
            particles[i].x += particles[i].vx * CGFloat(dt)
            particles[i].y += particles[i].vy * CGFloat(dt)
            particles[i].age += dt
            if particles[i].age >= particles[i].maxAge {
                particles.remove(at: i)
            }
        }

        // Update falling gifts
        for i in (0..<giftDrops.count).reversed() {
            giftDrops[i].age += dt
            giftDrops[i].y -= giftDrops[i].vy * CGFloat(dt)
            if giftDrops[i].y <= 16.0 {
                let sway = CGFloat(sin(giftDrops[i].age * 4.0)) * 6.0
                ScreenEffectsManager.shared.handleGiftLandedOnSnow(onWindow: window, atLocalX: giftDrops[i].baseX + sway, style: style)
                giftDrops.remove(at: i)
            }
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let shouldRenderSleigh = (flightState == .cruising && elapsed <= flightDuration) ||
            flightState == .crashing ||
            flightState == .grounded ||
            (flightState == .recovering && caravanX >= -180.0 && caravanX <= w + 180.0 && caravanY <= h + 140.0)

        if shouldRenderSleigh {
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            if let ctx = CGContext(
                data: nil,
                width: 480,
                height: 160,
                bitsPerComponent: 8,
                bytesPerRow: 480 * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) {
                ctx.scaleBy(x: 2.0, y: 2.0)
                ctx.translateBy(x: 100.0, y: 32.0)
                SantaSleighRenderer.draw(style: style, elapsed: elapsed, in: ctx)
                sleighLayer.contents = ctx.makeImage()
            }
            sleighLayer.position = CGPoint(x: caravanX, y: caravanY)
            var t = CATransform3DIdentity
            t = CATransform3DScale(t, leftToRight ? 1.0 : -1.0, 1.0, 1.0)
            t = CATransform3DRotate(t, currentAngle, 0, 0, 1)
            sleighLayer.transform = t
            sleighLayer.isHidden = false
        } else {
            sleighLayer.contents = nil
            sleighLayer.isHidden = true
        }

        if let root = layer {
            while particleLayers.count < particles.count {
                let l = CALayer()
                l.actions = Self.noAnimActions
                root.insertSublayer(l, below: sleighLayer)
                particleLayers.append(l)
            }

            for i in 0..<particles.count {
                let p = particles[i]
                let life = max(0.0, 1.0 - (p.age / p.maxAge))
                let alpha = Float(life * (0.55 + 0.45 * sin(p.twinklePhase + p.age * 14.0)))
                let l = particleLayers[i]
                if alpha <= 0.02 {
                    l.isHidden = true
                } else {
                    l.isHidden = false
                    l.contents = p.isSparkle ? Self.goldSparkleImage : Self.goldDotImage
                    let s = p.size * CGFloat(life)
                    l.bounds = CGRect(x: 0, y: 0, width: s * 2.4, height: s * 2.4)
                    l.position = CGPoint(x: p.x, y: p.y)
                    l.opacity = alpha
                }
            }
            for i in particles.count..<particleLayers.count {
                particleLayers[i].isHidden = true
            }

            while giftLayers.count < giftDrops.count {
                let l = CALayer()
                l.actions = Self.noAnimActions
                l.bounds = CGRect(x: 0, y: 0, width: 32, height: 40)
                l.anchorPoint = CGPoint(x: 16.0 / 32.0, y: 12.0 / 40.0)
                root.insertSublayer(l, below: sleighLayer)
                giftLayers.append(l)
            }

            for i in 0..<giftDrops.count {
                let gift = giftDrops[i]
                let sway = CGFloat(sin(gift.age * 4.0)) * 6.0
                let gx = (style == .pixelArt) ? floor(gift.baseX + sway) : (gift.baseX + sway)
                let gy = (style == .pixelArt) ? floor(gift.y) : gift.y
                let alpha = gy < 28.0 ? max(0.0, gy / 28.0) : 1.0
                let l = giftLayers[i]
                if alpha <= 0.02 {
                    l.isHidden = true
                } else {
                    l.isHidden = false
                    l.contents = (style == .pixelArt) ? Self.giftPixelImage : Self.giftColorfulImage
                    l.position = CGPoint(x: gx, y: gy)
                    l.opacity = Float(alpha)
                }
            }
            for i in giftDrops.count..<giftLayers.count {
                giftLayers[i].isHidden = true
            }
        }

        CATransaction.commit()

        let isFinished: Bool
        switch flightState {
        case .cruising:
            isFinished = elapsed >= totalDuration && (giftDrops.isEmpty || elapsed >= 14.0)
        case .crashing, .grounded:
            isFinished = false
        case .recovering:
            isFinished = (caravanX < -180.0 || caravanX > w + 180.0 || caravanY > h + 140.0) && giftDrops.isEmpty
        }

        if isFinished {
            let finish = onComplete
            stop()
            finish?()
        }
    }

    private func spawnParticle(x: CGFloat, y: CGFloat, dir: CGFloat) {
        particles.append(StardustParticle(
            x: x + CGFloat.random(in: (-4)...4), y: y + CGFloat.random(in: (-4)...4),
            vx: -dir * CGFloat.random(in: 12...28), vy: CGFloat.random(in: (-20)...(-6)),
            age: 0.0, maxAge: Double.random(in: 0.75...0.95),
            size: CGFloat.random(in: 2.2...4.4), twinklePhase: Double.random(in: 0...(.pi * 2)),
            isSparkle: Bool.random(), isGold: Bool.random()
        ))
    }
}
