import AppKit

/// Renders animated colorful 3D and Pixel Art icons for the macOS menu bar and popover preview.
enum StatusBarIconRenderer {

    static func render(
        character: CharacterType,
        style: IconStyle,
        phase: Double,
        twinklePhase: Double,
        isPlaying: Bool,
        isRotating: Bool,
        size: NSSize = NSSize(width: 22, height: 22)
    ) -> NSImage {
        let effectivePhase = isRotating ? phase : 0.35
        let image = NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            ctx.saveGState()
            ctx.scaleBy(x: rect.width / 22.0, y: rect.height / 22.0)

            switch style {
            case .colorful:
                NSGraphicsContext.current?.shouldAntialias = true
                drawColorful(
                    character: character,
                    phase: effectivePhase,
                    twinklePhase: twinklePhase,
                    isPlaying: isPlaying,
                    in: ctx
                )
            case .pixelArt:
                NSGraphicsContext.current?.shouldAntialias = false
                drawPixelArt(
                    character: character,
                    phase: effectivePhase,
                    twinklePhase: twinklePhase,
                    isPlaying: isPlaying
                )
            }

            ctx.restoreGState()
            return true
        }
        image.isTemplate = false
        return image
    }

    // MARK: - Colorful 3D Vector Rendering (22x22 logical canvas)

    private static func drawColorful(
        character: CharacterType,
        phase: Double,
        twinklePhase: Double,
        isPlaying: Bool,
        in ctx: CGContext
    ) {
        switch character {
        case .tree:
            drawColorfulTree(phase: phase, twinklePhase: twinklePhase, isPlaying: isPlaying)
        case .snowman:
            drawColorfulSnowman(phase: phase, twinklePhase: twinklePhase)
        case .reindeer:
            drawColorfulReindeer(phase: phase, twinklePhase: twinklePhase)
        case .santa:
            drawColorfulSantaHat(phase: phase, twinklePhase: twinklePhase)
        case .hotCocoa:
            drawColorfulHotCocoa(phase: phase, twinklePhase: twinklePhase)
        }
    }

    private static func drawColorfulTree(phase: Double, twinklePhase: Double, isPlaying: Bool) {
        // 1. Trunk
        let trunkRect = NSRect(x: 9.3, y: 1.5, width: 3.4, height: 3.0)
        NSColor(calibratedRed: 0.48, green: 0.28, blue: 0.14, alpha: 1.0).setFill()
        NSBezierPath(roundedRect: trunkRect, xRadius: 0.8, yRadius: 0.8).fill()

        // 2. Tree foliage tiers (bottom to top)
        struct Tier {
            let bottomY: CGFloat
            let topY: CGFloat
            let halfWidth: CGFloat
            let color: NSColor
            let shadeColor: NSColor
        }

        let tiers: [Tier] = [
            Tier(
                bottomY: 4.0, topY: 11.2, halfWidth: 8.2,
                color: NSColor(calibratedRed: 0.08, green: 0.56, blue: 0.25, alpha: 1.0),
                shadeColor: NSColor(calibratedRed: 0.04, green: 0.40, blue: 0.16, alpha: 1.0)
            ),
            Tier(
                bottomY: 8.4, topY: 14.8, halfWidth: 6.4,
                color: NSColor(calibratedRed: 0.11, green: 0.65, blue: 0.30, alpha: 1.0),
                shadeColor: NSColor(calibratedRed: 0.06, green: 0.47, blue: 0.20, alpha: 1.0)
            ),
            Tier(
                bottomY: 12.4, topY: 18.2, halfWidth: 4.3,
                color: NSColor(calibratedRed: 0.15, green: 0.74, blue: 0.35, alpha: 1.0),
                shadeColor: NSColor(calibratedRed: 0.09, green: 0.54, blue: 0.24, alpha: 1.0)
            )
        ]

        // Subtle 3D ridge sway as the tree rotates
        let ridgeShift = CGFloat(sin(phase) * 1.4)

        for tier in tiers {
            let path = NSBezierPath()
            path.move(to: NSPoint(x: 11.0, y: tier.topY))
            path.line(to: NSPoint(x: 11.0 - tier.halfWidth, y: tier.bottomY))
            path.curve(
                to: NSPoint(x: 11.0 + tier.halfWidth, y: tier.bottomY),
                controlPoint1: NSPoint(x: 11.0 - tier.halfWidth * 0.35, y: tier.bottomY - 1.0),
                controlPoint2: NSPoint(x: 11.0 + tier.halfWidth * 0.35, y: tier.bottomY - 1.0)
            )
            path.close()
            tier.color.setFill()
            path.fill()

            // Rotating 3D facet highlight/shadow triangle
            let facet = NSBezierPath()
            facet.move(to: NSPoint(x: 11.0, y: tier.topY))
            facet.line(to: NSPoint(x: 11.0 + ridgeShift, y: tier.bottomY - 0.5))
            facet.line(to: NSPoint(x: 11.0 + tier.halfWidth, y: tier.bottomY))
            facet.close()
            tier.shadeColor.withAlphaComponent(0.52).setFill()
            facet.fill()

            // Crisp soft outline so it pops on light and dark menu bars
            NSColor(calibratedRed: 0.03, green: 0.26, blue: 0.10, alpha: 0.55).setStroke()
            path.lineWidth = 0.6
            path.stroke()
        }

        // 3. Rotating 3D golden garland curves across the cone
        drawGarlandSweep(phase: phase, yBase: 6.5, halfWidth: 6.1)
        drawGarlandSweep(phase: phase + 1.8, yBase: 10.6, halfWidth: 4.4)

        // 4. 3D Cylindrical Ornaments orbiting around the tree cone
        struct OrnamentDef {
            let y: CGFloat
            let coneRadius: CGFloat
            let angleOffset: Double
            let radius: CGFloat
            let color: NSColor
        }

        let ornamentDefs: [OrnamentDef] = [
            OrnamentDef(y: 5.5, coneRadius: 6.7, angleOffset: 0.0, radius: 1.35, color: NSColor(calibratedRed: 0.96, green: 0.22, blue: 0.24, alpha: 1.0)),
            OrnamentDef(y: 5.8, coneRadius: 6.5, angleOffset: 2.1, radius: 1.30, color: NSColor(calibratedRed: 1.00, green: 0.80, blue: 0.16, alpha: 1.0)),
            OrnamentDef(y: 5.4, coneRadius: 6.8, angleOffset: 4.2, radius: 1.30, color: NSColor(calibratedRed: 0.24, green: 0.76, blue: 1.00, alpha: 1.0)),
            OrnamentDef(y: 9.2, coneRadius: 5.0, angleOffset: 1.0, radius: 1.20, color: NSColor(calibratedRed: 1.00, green: 0.34, blue: 0.66, alpha: 1.0)),
            OrnamentDef(y: 9.6, coneRadius: 4.8, angleOffset: 3.2, radius: 1.20, color: NSColor(calibratedRed: 1.00, green: 0.84, blue: 0.22, alpha: 1.0)),
            OrnamentDef(y: 9.0, coneRadius: 5.1, angleOffset: 5.2, radius: 1.20, color: NSColor(calibratedRed: 0.96, green: 0.22, blue: 0.24, alpha: 1.0)),
            OrnamentDef(y: 13.2, coneRadius: 3.1, angleOffset: 0.5, radius: 1.05, color: NSColor(calibratedRed: 0.30, green: 0.86, blue: 1.00, alpha: 1.0)),
            OrnamentDef(y: 13.6, coneRadius: 2.9, angleOffset: 2.6, radius: 1.05, color: NSColor(calibratedRed: 0.98, green: 0.26, blue: 0.28, alpha: 1.0)),
            OrnamentDef(y: 13.1, coneRadius: 3.2, angleOffset: 4.7, radius: 1.05, color: NSColor(calibratedRed: 1.00, green: 0.86, blue: 0.28, alpha: 1.0))
        ]

        struct ProjectedOrnament {
            let x: CGFloat
            let y: CGFloat
            let depth: Double
            let radius: CGFloat
            let color: NSColor
            let twinkleIndex: Double
        }

        let projected = ornamentDefs.enumerated().map { idx, def -> ProjectedOrnament in
            let theta = def.angleOffset + phase
            let x = 11.0 + def.coneRadius * CGFloat(cos(theta))
            let depth = sin(theta) // +1 front, -1 back
            let yBob = def.y - CGFloat(depth * 0.45) // subtle perspective arc
            return ProjectedOrnament(
                x: x,
                y: yBob,
                depth: depth,
                radius: def.radius,
                color: def.color,
                twinkleIndex: Double(idx)
            )
        }.sorted { $0.depth < $1.depth }

        for item in projected {
            // Hide ornaments well behind the back of the tree
            if item.depth < -0.25 { continue }

            let twinkle = 0.78 + 0.22 * sin(twinklePhase * 2.1 + item.twinkleIndex * 1.4)
            let depthAlpha = item.depth < 0 ? CGFloat((item.depth + 0.25) / 0.25) * 0.65 + 0.25 : 1.0
            let r = item.radius * (0.82 + 0.22 * CGFloat(max(0, item.depth)))

            // Warm subtle glow when playing or twinkling
            if isPlaying || twinkle > 0.88 {
                let glowRect = NSRect(x: item.x - r * 1.6, y: item.y - r * 1.6, width: r * 3.2, height: r * 3.2)
                item.color.withAlphaComponent(0.32 * CGFloat(twinkle) * depthAlpha).setFill()
                NSBezierPath(ovalIn: glowRect).fill()
            }

            let ballRect = NSRect(x: item.x - r, y: item.y - r, width: r * 2, height: r * 2)
            item.color.withAlphaComponent(depthAlpha).setFill()
            NSBezierPath(ovalIn: ballRect).fill()

            // Specular highlight
            let glintRect = NSRect(x: item.x - r * 0.45, y: item.y + r * 0.15, width: r * 0.55, height: r * 0.55)
            NSColor.white.withAlphaComponent(0.82 * depthAlpha).setFill()
            NSBezierPath(ovalIn: glintRect).fill()
        }

        // 5. Spinning Top Star
        let starCenter = NSPoint(x: 11.0, y: 19.3)
        let starWidthScale = CGFloat(max(0.26, abs(cos(phase))))
        let starGlow = 0.75 + 0.25 * sin(twinklePhase * 3.0)

        let haloRect = NSRect(x: starCenter.x - 3.3, y: starCenter.y - 3.3, width: 6.6, height: 6.6)
        NSColor(calibratedRed: 1.0, green: 0.88, blue: 0.25, alpha: 0.32 * CGFloat(starGlow)).setFill()
        NSBezierPath(ovalIn: haloRect).fill()

        let starPath = createStarPath(center: starCenter, outerRadius: 2.5, innerRadius: 1.05, xScale: starWidthScale)
        NSColor(calibratedRed: 1.0, green: 0.84, blue: 0.14, alpha: 1.0).setFill()
        starPath.fill()
        NSColor(calibratedRed: 0.92, green: 0.62, blue: 0.04, alpha: 0.85).setStroke()
        starPath.lineWidth = 0.55
        starPath.stroke()
    }

    private static func drawGarlandSweep(phase: Double, yBase: CGFloat, halfWidth: CGFloat) {
        let garland = NSBezierPath()
        var started = false
        for step in 0...16 {
            let t = Double(step) / 16.0
            let angle = -0.35 + t * (.pi + 0.7) // front arc
            let shifted = angle + (phase.truncatingRemainder(dividingBy: 2 * .pi))
            let x = 11.0 + halfWidth * CGFloat(cos(angle))
            let y = yBase + CGFloat(sin(angle * 2.0 + shifted * 0.35)) * 0.85 - CGFloat(sin(angle)) * 0.8
            let pt = NSPoint(x: x, y: y)
            if !started {
                garland.move(to: pt)
                started = true
            } else {
                garland.line(to: pt)
            }
        }
        NSColor(calibratedRed: 1.0, green: 0.86, blue: 0.30, alpha: 0.72).setStroke()
        garland.lineWidth = 0.95
        garland.lineCapStyle = .round
        garland.stroke()
    }

    private static func createStarPath(center: NSPoint, outerRadius: CGFloat, innerRadius: CGFloat, xScale: CGFloat) -> NSBezierPath {
        let path = NSBezierPath()
        let points = 5
        for i in 0..<(points * 2) {
            let radius = (i % 2 == 0) ? outerRadius : innerRadius
            let angle = (Double(i) * .pi / Double(points)) + (.pi / 2.0)
            let x = center.x + radius * CGFloat(cos(angle)) * xScale
            let y = center.y + radius * CGFloat(sin(angle))
            if i == 0 {
                path.move(to: NSPoint(x: x, y: y))
            } else {
                path.line(to: NSPoint(x: x, y: y))
            }
        }
        path.close()
        return path
    }

    // MARK: - Other Colorful Characters

    private static func drawColorfulSnowman(phase: Double, twinklePhase: Double) {
        let sway = CGFloat(sin(phase) * 1.1)

        // Body (bottom snowball)
        let bottomRect = NSRect(x: 5.5 + sway * 0.25, y: 1.5, width: 11.0, height: 9.2)
        NSColor(calibratedWhite: 0.98, alpha: 1.0).setFill()
        NSBezierPath(ovalIn: bottomRect).fill()
        NSColor(calibratedRed: 0.65, green: 0.82, blue: 0.96, alpha: 0.8).setStroke()
        let bottomBorder = NSBezierPath(ovalIn: bottomRect)
        bottomBorder.lineWidth = 0.8
        bottomBorder.stroke()

        // Head
        let headRect = NSRect(x: 6.8 + sway * 0.65, y: 9.2, width: 8.4, height: 7.8)
        NSColor(calibratedWhite: 0.99, alpha: 1.0).setFill()
        NSBezierPath(ovalIn: headRect).fill()
        NSColor(calibratedRed: 0.65, green: 0.82, blue: 0.96, alpha: 0.8).setStroke()
        let headBorder = NSBezierPath(ovalIn: headRect)
        headBorder.lineWidth = 0.8
        headBorder.stroke()

        // Scarf
        let scarfRect = NSRect(x: 7.4 + sway * 0.5, y: 8.6, width: 7.2, height: 2.0)
        NSColor(calibratedRed: 0.90, green: 0.16, blue: 0.18, alpha: 1.0).setFill()
        NSBezierPath(roundedRect: scarfRect, xRadius: 0.8, yRadius: 0.8).fill()

        // Scarf tail swaying
        let tail = NSBezierPath()
        tail.move(to: NSPoint(x: 12.6 + sway * 0.5, y: 9.3))
        tail.line(to: NSPoint(x: 15.2 + sway * 1.4, y: 6.2))
        tail.line(to: NSPoint(x: 13.4 + sway * 1.2, y: 5.7))
        tail.close()
        tail.fill()

        // Eyes & buttons
        NSColor(calibratedWhite: 0.15, alpha: 1.0).setFill()
        NSBezierPath(ovalIn: NSRect(x: 9.3 + sway * 0.65, y: 13.5, width: 1.2, height: 1.2)).fill()
        NSBezierPath(ovalIn: NSRect(x: 11.7 + sway * 0.65, y: 13.5, width: 1.2, height: 1.2)).fill()
        NSBezierPath(ovalIn: NSRect(x: 10.4 + sway * 0.3, y: 6.0, width: 1.2, height: 1.2)).fill()
        NSBezierPath(ovalIn: NSRect(x: 10.4 + sway * 0.25, y: 3.8, width: 1.2, height: 1.2)).fill()

        // Carrot nose
        let nose = NSBezierPath()
        nose.move(to: NSPoint(x: 11.0 + sway * 0.7, y: 12.8))
        nose.line(to: NSPoint(x: 14.2 + sway * 0.85, y: 12.1))
        nose.line(to: NSPoint(x: 11.0 + sway * 0.7, y: 11.6))
        nose.close()
        NSColor(calibratedRed: 1.0, green: 0.52, blue: 0.08, alpha: 1.0).setFill()
        nose.fill()

        // Top hat
        let brimRect = NSRect(x: 6.5 + sway * 0.75, y: 16.2, width: 9.0, height: 1.5)
        let crownRect = NSRect(x: 8.0 + sway * 0.85, y: 17.2, width: 6.0, height: 3.6)
        NSColor(calibratedWhite: 0.16, alpha: 1.0).setFill()
        NSBezierPath(roundedRect: brimRect, xRadius: 0.6, yRadius: 0.6).fill()
        NSBezierPath(roundedRect: crownRect, xRadius: 0.7, yRadius: 0.7).fill()

        let hatBand = NSRect(x: 8.0 + sway * 0.85, y: 17.3, width: 6.0, height: 1.0)
        let bandPulse = 0.8 + 0.2 * sin(twinklePhase * 2.0)
        NSColor(calibratedRed: 0.92, green: 0.18, blue: 0.20, alpha: CGFloat(bandPulse)).setFill()
        NSBezierPath(rect: hatBand).fill()
    }

    private static func drawColorfulReindeer(phase: Double, twinklePhase: Double) {
        let bob = CGFloat(sin(phase) * 0.8)
        let tilt = CGFloat(cos(phase) * 0.6)

        // Antlers
        let antlerColor = NSColor(calibratedRed: 0.85, green: 0.66, blue: 0.42, alpha: 1.0)
        antlerColor.setStroke()
        let leftAntler = NSBezierPath()
        leftAntler.lineWidth = 1.6
        leftAntler.lineCapStyle = .round
        leftAntler.move(to: NSPoint(x: 8.2, y: 13.8 + bob))
        leftAntler.line(to: NSPoint(x: 5.5 + tilt, y: 18.8 + bob))
        leftAntler.move(to: NSPoint(x: 6.8 + tilt * 0.5, y: 16.4 + bob))
        leftAntler.line(to: NSPoint(x: 4.0 + tilt, y: 16.8 + bob))
        leftAntler.move(to: NSPoint(x: 6.4 + tilt * 0.5, y: 17.4 + bob))
        leftAntler.line(to: NSPoint(x: 7.4 + tilt, y: 19.6 + bob))
        leftAntler.stroke()

        let rightAntler = NSBezierPath()
        rightAntler.lineWidth = 1.6
        rightAntler.lineCapStyle = .round
        rightAntler.move(to: NSPoint(x: 13.8, y: 13.8 + bob))
        rightAntler.line(to: NSPoint(x: 16.5 + tilt, y: 18.8 + bob))
        rightAntler.move(to: NSPoint(x: 15.2 + tilt * 0.5, y: 16.4 + bob))
        rightAntler.line(to: NSPoint(x: 18.0 + tilt, y: 16.8 + bob))
        rightAntler.move(to: NSPoint(x: 15.6 + tilt * 0.5, y: 17.4 + bob))
        rightAntler.line(to: NSPoint(x: 14.6 + tilt, y: 19.6 + bob))
        rightAntler.stroke()

        // Ears
        let earColor = NSColor(calibratedRed: 0.56, green: 0.34, blue: 0.16, alpha: 1.0)
        earColor.setFill()
        NSBezierPath(ovalIn: NSRect(x: 3.8, y: 11.2 + bob, width: 3.4, height: 2.2)).fill()
        NSBezierPath(ovalIn: NSRect(x: 14.8, y: 11.2 + bob, width: 3.4, height: 2.2)).fill()

        // Head
        let headRect = NSRect(x: 5.5, y: 3.2 + bob, width: 11.0, height: 11.8)
        NSColor(calibratedRed: 0.64, green: 0.39, blue: 0.20, alpha: 1.0).setFill()
        NSBezierPath(ovalIn: headRect).fill()

        // Tan muzzle
        let muzzleRect = NSRect(x: 7.0, y: 3.4 + bob, width: 8.0, height: 5.5)
        NSColor(calibratedRed: 0.87, green: 0.70, blue: 0.52, alpha: 1.0).setFill()
        NSBezierPath(ovalIn: muzzleRect).fill()

        // Eyes
        NSColor(calibratedWhite: 0.12, alpha: 1.0).setFill()
        NSBezierPath(ovalIn: NSRect(x: 8.0, y: 10.2 + bob, width: 1.5, height: 1.8)).fill()
        NSBezierPath(ovalIn: NSRect(x: 12.5, y: 10.2 + bob, width: 1.5, height: 1.8)).fill()

        // Glowing Rudolph Nose
        let noseGlow = 0.55 + 0.45 * sin(phase * 1.5 + twinklePhase * 2.0)
        let glowRect = NSRect(x: 8.3, y: 4.5 + bob, width: 5.4, height: 5.4)
        NSColor(calibratedRed: 1.0, green: 0.12, blue: 0.12, alpha: CGFloat(0.45 * noseGlow)).setFill()
        NSBezierPath(ovalIn: glowRect).fill()

        let noseRect = NSRect(x: 9.3, y: 5.5 + bob, width: 3.4, height: 3.2)
        NSColor(calibratedRed: 0.98, green: 0.14, blue: 0.14, alpha: 1.0).setFill()
        NSBezierPath(ovalIn: noseRect).fill()

        NSColor.white.withAlphaComponent(0.85).setFill()
        NSBezierPath(ovalIn: NSRect(x: 10.0, y: 7.4 + bob, width: 1.0, height: 0.9)).fill()
    }

    private static func drawColorfulSantaHat(phase: Double, twinklePhase: Double) {
        let sway = CGFloat(sin(phase) * 1.8)
        let pomY = 12.2 + CGFloat(cos(phase) * 0.9)

        // Red hat body
        let hat = NSBezierPath()
        hat.move(to: NSPoint(x: 3.2, y: 5.8))
        hat.curve(
            to: NSPoint(x: 15.8 + sway, y: pomY),
            controlPoint1: NSPoint(x: 5.5, y: 16.5),
            controlPoint2: NSPoint(x: 11.5, y: 19.2)
        )
        hat.curve(
            to: NSPoint(x: 17.5, y: 5.8),
            controlPoint1: NSPoint(x: 16.5 + sway * 0.4, y: 10.5),
            controlPoint2: NSPoint(x: 17.5, y: 7.8)
        )
        hat.close()
        NSColor(calibratedRed: 0.88, green: 0.14, blue: 0.16, alpha: 1.0).setFill()
        hat.fill()

        // White fluffy brim
        let brimRect = NSRect(x: 2.2, y: 3.2, width: 16.2, height: 4.2)
        NSColor(calibratedWhite: 0.98, alpha: 1.0).setFill()
        NSBezierPath(roundedRect: brimRect, xRadius: 2.0, yRadius: 2.0).fill()
        NSColor(calibratedRed: 0.78, green: 0.84, blue: 0.90, alpha: 0.85).setStroke()
        let brimBorder = NSBezierPath(roundedRect: brimRect, xRadius: 2.0, yRadius: 2.0)
        brimBorder.lineWidth = 0.7
        brimBorder.stroke()

        // Bobbing pom-pom
        let pomRect = NSRect(x: 14.8 + sway, y: pomY - 1.8, width: 4.4, height: 4.4)
        NSColor(calibratedWhite: 0.99, alpha: 1.0).setFill()
        NSBezierPath(ovalIn: pomRect).fill()
        NSColor(calibratedRed: 0.78, green: 0.84, blue: 0.90, alpha: 0.85).setStroke()
        let pomBorder = NSBezierPath(ovalIn: pomRect)
        pomBorder.lineWidth = 0.65
        pomBorder.stroke()

        // Twinkling sparkle near hat
        let alpha = CGFloat(0.4 + 0.6 * abs(sin(twinklePhase * 2.2)))
        NSColor(calibratedRed: 1.0, green: 0.88, blue: 0.30, alpha: alpha).setFill()
        createStarPath(center: NSPoint(x: 4.5, y: 16.8), outerRadius: 1.8, innerRadius: 0.7, xScale: 1.0).fill()
    }

    private static func drawColorfulHotCocoa(phase: Double, twinklePhase: Double) {
        // Handle
        let handle = NSBezierPath(ovalIn: NSRect(x: 14.0, y: 4.2, width: 5.0, height: 6.2))
        handle.lineWidth = 2.0
        NSColor(calibratedRed: 0.85, green: 0.16, blue: 0.18, alpha: 1.0).setStroke()
        handle.stroke()

        // Mug body
        let mugRect = NSRect(x: 4.0, y: 2.2, width: 11.6, height: 10.6)
        NSColor(calibratedRed: 0.90, green: 0.18, blue: 0.20, alpha: 1.0).setFill()
        NSBezierPath(roundedRect: mugRect, xRadius: 2.0, yRadius: 2.0).fill()

        // White festive stripe on mug
        NSColor.white.withAlphaComponent(0.92).setFill()
        NSBezierPath(rect: NSRect(x: 4.0, y: 6.2, width: 11.6, height: 1.5)).fill()

        // Cocoa top
        let topRect = NSRect(x: 4.0, y: 11.0, width: 11.6, height: 3.0)
        NSColor(calibratedRed: 0.36, green: 0.20, blue: 0.10, alpha: 1.0).setFill()
        NSBezierPath(ovalIn: topRect).fill()

        // Mini marshmallows
        NSColor(calibratedWhite: 0.98, alpha: 1.0).setFill()
        NSBezierPath(roundedRect: NSRect(x: 6.3, y: 11.9, width: 2.0, height: 1.4), xRadius: 0.4, yRadius: 0.4).fill()
        NSBezierPath(roundedRect: NSRect(x: 9.6, y: 12.1, width: 2.0, height: 1.4), xRadius: 0.4, yRadius: 0.4).fill()
        NSBezierPath(roundedRect: NSRect(x: 12.1, y: 11.7, width: 1.7, height: 1.3), xRadius: 0.4, yRadius: 0.4).fill()

        // Rising animated steam wisps
        for i in 0..<3 {
            let offset = Double(i) * 2.1
            let xBase: CGFloat = 6.8 + CGFloat(i) * 3.0
            let progress = ((phase + twinklePhase + offset).truncatingRemainder(dividingBy: 2.0 * .pi)) / (2.0 * .pi)
            let yStart: CGFloat = 14.5 + CGFloat(progress * 2.5)
            let alpha = CGFloat(sin(progress * .pi) * 0.78)

            let steam = NSBezierPath()
            steam.lineWidth = 1.25
            steam.lineCapStyle = .round
            let wave1 = CGFloat(sin(phase * 1.5 + offset) * 1.0)
            let wave2 = CGFloat(cos(phase * 1.5 + offset) * 1.0)
            steam.move(to: NSPoint(x: xBase, y: yStart))
            steam.curve(
                to: NSPoint(x: xBase + wave2, y: yStart + 4.4),
                controlPoint1: NSPoint(x: xBase + wave1, y: yStart + 1.5),
                controlPoint2: NSPoint(x: xBase - wave1, y: yStart + 3.0)
            )
            NSColor.white.withAlphaComponent(max(0.1, alpha)).setStroke()
            steam.stroke()
        }
    }

    // MARK: - Pixel Art 8-bit Rendering (11x11 grid of 2x2pt blocks)

    private static func putPixel(_ x: Int, _ yFromBottom: Int, _ color: NSColor) {
        guard x >= 0, x < 11, yFromBottom >= 0, yFromBottom < 11 else { return }
        color.setFill()
        NSRect(x: CGFloat(x) * 2.0, y: CGFloat(yFromBottom) * 2.0, width: 2.0, height: 2.0).fill()
    }

    private static func drawPixelArt(
        character: CharacterType,
        phase: Double,
        twinklePhase: Double,
        isPlaying: Bool
    ) {
        let frame = Int((phase / (2.0 * .pi)) * 8.0) % 8
        let blink = Int((twinklePhase / 0.8)) % 2 == 0

        switch character {
        case .tree:
            let green1 = NSColor(calibratedRed: 0.08, green: 0.62, blue: 0.25, alpha: 1.0)
            let green2 = NSColor(calibratedRed: 0.14, green: 0.76, blue: 0.34, alpha: 1.0)
            let brown = NSColor(calibratedRed: 0.50, green: 0.28, blue: 0.12, alpha: 1.0)
            let gold = NSColor(calibratedRed: 1.0, green: 0.85, blue: 0.15, alpha: 1.0)
            let red = NSColor(calibratedRed: 0.96, green: 0.20, blue: 0.22, alpha: 1.0)
            let cyan = NSColor(calibratedRed: 0.26, green: 0.82, blue: 1.0, alpha: 1.0)

            // Trunk
            putPixel(5, 0, brown)
            putPixel(5, 1, brown)

            // Tree rows (row -> halfWidth)
            let rows: [(y: Int, hw: Int)] = [
                (2, 4), (3, 3), (4, 3), (5, 2), (6, 2), (7, 1), (8, 1)
            ]
            for row in rows {
                for dx in -row.hw...row.hw {
                    let x = 5 + dx
                    let shade = ((dx + frame) % 3 == 0) ? green2 : green1
                    putPixel(x, row.y, shade)
                }
            }

            // Rotating pixel ornaments across the rows
            let shiftBottom = (frame % 7) - 3
            putPixel(max(2, min(8, 5 + shiftBottom)), 2, red)
            putPixel(max(2, min(8, 5 - shiftBottom)), 3, cyan)
            let shiftMid = ((frame + 2) % 5) - 2
            putPixel(max(3, min(7, 5 + shiftMid)), 5, gold)
            putPixel(max(3, min(7, 5 - shiftMid)), 6, red)
            let shiftTop = (frame % 3) - 1
            putPixel(5 + shiftTop, 7, cyan)

            // Top star (twinkles)
            putPixel(5, 9, gold)
            if isPlaying || blink {
                putPixel(5, 10, gold)
            }

        case .snowman:
            let white = NSColor(calibratedWhite: 0.98, alpha: 1.0)
            let black = NSColor(calibratedWhite: 0.16, alpha: 1.0)
            let red = NSColor(calibratedRed: 0.92, green: 0.18, blue: 0.20, alpha: 1.0)
            let orange = NSColor(calibratedRed: 1.0, green: 0.52, blue: 0.08, alpha: 1.0)
            let sway = (frame % 4 == 1) ? 1 : (frame % 4 == 3 ? -1 : 0)

            // Bottom ball
            for y in 1...4 {
                let hw = (y == 1 || y == 4) ? 2 : 3
                for dx in -hw...hw { putPixel(5 + dx, y, white) }
            }
            // Scarf
            for dx in -2...2 { putPixel(5 + dx, 5, red) }
            putPixel(7 + max(0, sway), 4, red)

            // Head
            for y in 6...8 {
                for dx in -2...2 { putPixel(5 + dx, y, white) }
            }
            putPixel(4, 7, black)
            putPixel(6, 7, black)
            putPixel(5 + sway, 6, orange)

            // Hat
            for dx in -2...2 { putPixel(5 + dx, 9, black) }
            for dx in -1...1 { putPixel(5 + dx, 10, black) }

        case .reindeer:
            let brown = NSColor(calibratedRed: 0.62, green: 0.38, blue: 0.18, alpha: 1.0)
            let tan = NSColor(calibratedRed: 0.88, green: 0.72, blue: 0.52, alpha: 1.0)
            let black = NSColor(calibratedWhite: 0.14, alpha: 1.0)
            let red = NSColor(calibratedRed: 1.0, green: 0.15, blue: 0.15, alpha: 1.0)
            let brightRed = NSColor(calibratedRed: 1.0, green: 0.45, blue: 0.45, alpha: 1.0)

            // Antlers
            putPixel(2, 9, tan); putPixel(3, 8, tan); putPixel(2, 10, tan); putPixel(4, 9, tan)
            putPixel(8, 9, tan); putPixel(7, 8, tan); putPixel(8, 10, tan); putPixel(6, 9, tan)

            // Face
            for y in 2...7 {
                for x in 3...7 { putPixel(x, y, brown) }
            }
            for x in 4...6 { putPixel(x, 2, tan); putPixel(x, 3, tan) }
            putPixel(4, 6, black); putPixel(6, 6, black)
            putPixel(5, 3, (frame % 2 == 0) ? brightRed : red)

        case .santa:
            let red = NSColor(calibratedRed: 0.90, green: 0.14, blue: 0.16, alpha: 1.0)
            let white = NSColor(calibratedWhite: 0.98, alpha: 1.0)
            let sway = (frame % 4 == 1) ? 1 : (frame % 4 == 3 ? -1 : 0)

            for x in 1...8 { putPixel(x, 2, white); putPixel(x, 3, white) }
            for x in 2...7 { putPixel(x, 4, red); putPixel(x, 5, red) }
            for x in 3...7 { putPixel(x, 6, red) }
            for x in 4...7 { putPixel(x, 7, red) }
            putPixel(6 + sway, 8, red); putPixel(7 + sway, 8, red)
            putPixel(8 + sway, 7, white); putPixel(9 + sway, 7, white)

        case .hotCocoa:
            let red = NSColor(calibratedRed: 0.90, green: 0.18, blue: 0.20, alpha: 1.0)
            let white = NSColor(calibratedWhite: 0.98, alpha: 1.0)
            let cocoa = NSColor(calibratedRed: 0.36, green: 0.20, blue: 0.10, alpha: 1.0)
            let steam = NSColor.white.withAlphaComponent(0.85)

            for y in 1...5 {
                for x in 2...7 { putPixel(x, y, red) }
            }
            for x in 2...7 { putPixel(x, 3, white) }
            putPixel(8, 2, red); putPixel(9, 3, red); putPixel(9, 4, red); putPixel(8, 5, red)
            for x in 3...6 { putPixel(x, 5, cocoa) }
            putPixel(4, 5, white)

            let step = frame % 3
            putPixel(3 + (step % 2), 7 + step, steam)
            putPixel(6 - (step % 2), 8 + ((step + 1) % 3), steam)
        }
    }
}
