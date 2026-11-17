import AppKit

/// Renders Santa Claus in his sleigh pulled by three reindeer, including Rudolph with his glowing nose.
/// Supports both smooth 3D vector style and retro 8-bit pixel art style.
enum SantaSleighRenderer {

    static func draw(style: IconStyle, elapsed: Double, in ctx: CGContext) {
        let previousContext = NSGraphicsContext.current
        let gContext = NSGraphicsContext(cgContext: ctx, flipped: false)
        NSGraphicsContext.current = gContext
        defer { NSGraphicsContext.current = previousContext }

        switch style {
        case .colorful:
            drawColorful(elapsed: elapsed, in: ctx)
        case .pixelArt:
            drawPixelArt(elapsed: elapsed, in: ctx)
        }
    }

    // MARK: - Colorful 3D Vector Rendering

    private static func drawColorful(elapsed: Double, in ctx: CGContext) {
        NSGraphicsContext.current?.shouldAntialias = true
        ctx.setShouldAntialias(true)

        let gold = NSColor(calibratedRed: 0.831, green: 0.686, blue: 0.216, alpha: 1.0)
        let crimson = NSColor(calibratedRed: 0.722, green: 0.259, blue: 0.216, alpha: 1.0)
        let warmBrown = NSColor(calibratedRed: 0.55, green: 0.33, blue: 0.18, alpha: 1.0)
        let darkBrown = NSColor(calibratedRed: 0.38, green: 0.22, blue: 0.12, alpha: 1.0)
        let rosySkin = NSColor(calibratedRed: 0.98, green: 0.80, blue: 0.72, alpha: 1.0)
        let white = NSColor(calibratedWhite: 0.98, alpha: 1.0)
        let rudolphRed = NSColor(calibratedRed: 1.0, green: 0.231, blue: 0.188, alpha: 1.0)

        // 1. Gold runner (patin curvado)
        let runner = NSBezierPath()
        runner.move(to: NSPoint(x: -74, y: -5))
        runner.curve(to: NSPoint(x: -64, y: -9), controlPoint1: NSPoint(x: -72, y: -8), controlPoint2: NSPoint(x: -68, y: -9))
        runner.line(to: NSPoint(x: -22, y: -9))
        runner.curve(to: NSPoint(x: -13, y: -2), controlPoint1: NSPoint(x: -17, y: -9), controlPoint2: NSPoint(x: -13, y: -6))
        runner.lineWidth = 2.2
        gold.setStroke()
        runner.stroke()

        // Two vertical struts
        let strut1 = NSBezierPath()
        strut1.move(to: NSPoint(x: -56, y: -9))
        strut1.line(to: NSPoint(x: -56, y: -2))
        strut1.lineWidth = 1.8
        strut1.stroke()

        let strut2 = NSBezierPath()
        strut2.move(to: NSPoint(x: -28, y: -9))
        strut2.line(to: NSPoint(x: -28, y: -2))
        strut2.lineWidth = 1.8
        strut2.stroke()

        // 2. Toy sack in rear
        let sackRect = NSRect(x: -64, y: -2, width: 22, height: 18)
        warmBrown.setFill()
        NSBezierPath(ovalIn: sackRect).fill()
        let sackHighlight = NSRect(x: -60, y: 5, width: 13, height: 9)
        NSColor.white.withAlphaComponent(0.22).setFill()
        NSBezierPath(ovalIn: sackHighlight).fill()

        // 3. Santa Claus
        let santaBody = NSBezierPath(roundedRect: NSRect(x: -48, y: 0, width: 16, height: 14), xRadius: 4, yRadius: 4)
        crimson.setFill()
        santaBody.fill()

        let collarRect = NSRect(x: -45, y: 11, width: 11, height: 3.5)
        white.setFill()
        NSBezierPath(roundedRect: collarRect, xRadius: 1.5, yRadius: 1.5).fill()

        let headRect = NSRect(x: -42, y: 13, width: 9, height: 9)
        rosySkin.setFill()
        NSBezierPath(ovalIn: headRect).fill()

        let beard = NSBezierPath()
        beard.move(to: NSPoint(x: -35, y: 15))
        beard.curve(to: NSPoint(x: -47, y: 8), controlPoint1: NSPoint(x: -38, y: 11), controlPoint2: NSPoint(x: -44, y: 8))
        beard.curve(to: NSPoint(x: -41, y: 14), controlPoint1: NSPoint(x: -45, y: 12), controlPoint2: NSPoint(x: -43, y: 14))
        beard.close()
        white.setFill()
        beard.fill()

        let wave = CGFloat(sin(elapsed * 5.0))
        let arm = NSBezierPath()
        arm.move(to: NSPoint(x: -38, y: 7))
        let handX = -32.0 + wave * 2.5
        let handY = 16.0 + wave * 3.5
        arm.line(to: NSPoint(x: handX, y: handY))
        arm.lineWidth = 3.2
        crimson.setStroke()
        arm.stroke()

        white.setFill()
        NSBezierPath(ovalIn: NSRect(x: handX - 1.5, y: handY - 1.5, width: 3.5, height: 3.5)).fill()
        rosySkin.setFill()
        NSBezierPath(ovalIn: NSRect(x: handX - 0.5, y: handY + 0.5, width: 2.8, height: 2.8)).fill()

        let hat = NSBezierPath()
        hat.move(to: NSPoint(x: -43, y: 20))
        hat.curve(to: NSPoint(x: -54, y: 17), controlPoint1: NSPoint(x: -48, y: 23), controlPoint2: NSPoint(x: -52, y: 21))
        hat.line(to: NSPoint(x: -40, y: 18))
        hat.close()
        crimson.setFill()
        hat.fill()
        white.setFill()
        NSBezierPath(ovalIn: NSRect(x: -56, y: 15.5, width: 4.2, height: 4.2)).fill()

        // 4. Crimson sleigh body with gold trim
        let sleighBody = NSBezierPath()
        sleighBody.move(to: NSPoint(x: -69, y: 13))
        sleighBody.curve(to: NSPoint(x: -66, y: -2), controlPoint1: NSPoint(x: -71, y: 6), controlPoint2: NSPoint(x: -68, y: 0))
        sleighBody.line(to: NSPoint(x: -19, y: -2))
        sleighBody.curve(to: NSPoint(x: -15, y: 9), controlPoint1: NSPoint(x: -16, y: 1), controlPoint2: NSPoint(x: -15, y: 5))
        sleighBody.curve(to: NSPoint(x: -33, y: 2), controlPoint1: NSPoint(x: -20, y: 5), controlPoint2: NSPoint(x: -27, y: 2))
        sleighBody.curve(to: NSPoint(x: -69, y: 13), controlPoint1: NSPoint(x: -46, y: 2), controlPoint2: NSPoint(x: -61, y: 9))
        sleighBody.close()
        crimson.setFill()
        sleighBody.fill()

        let goldTrim = NSBezierPath()
        goldTrim.move(to: NSPoint(x: -69, y: 13))
        goldTrim.curve(to: NSPoint(x: -33, y: 2), controlPoint1: NSPoint(x: -61, y: 9), controlPoint2: NSPoint(x: -46, y: 2))
        goldTrim.curve(to: NSPoint(x: -15, y: 9), controlPoint1: NSPoint(x: -27, y: 2), controlPoint2: NSPoint(x: -20, y: 5))
        goldTrim.lineWidth = 1.4
        gold.setStroke()
        goldTrim.stroke()

        // 5. Reindeer and collars
        let reindeersX: [CGFloat] = [18.0, 52.0, 86.0]
        var collarPositions: [NSPoint] = []

        for (idx, rx) in reindeersX.enumerated() {
            let gallop = CGFloat(sin(elapsed * 13.0 + Double(idx) * 0.9))
            let bounce = CGFloat(cos(elapsed * 13.0 + Double(idx) * 0.9) * 1.6)
            let cy = bounce

            let rearHinge = NSPoint(x: rx - 7, y: cy - 1)
            let frontHinge = NSPoint(x: rx + 7, y: cy - 1)

            let legPath = NSBezierPath()
            legPath.lineWidth = 1.8
            warmBrown.setStroke()

            legPath.move(to: rearHinge)
            legPath.line(to: NSPoint(x: rx - 9.0 - gallop * 5.0, y: cy - 11))
            legPath.move(to: NSPoint(x: rearHinge.x + 2, y: rearHinge.y))
            legPath.line(to: NSPoint(x: rx - 6.0 + gallop * 4.0, y: cy - 10))

            legPath.move(to: frontHinge)
            legPath.line(to: NSPoint(x: rx + 10.0 + gallop * 5.0, y: cy - 11))
            legPath.move(to: NSPoint(x: frontHinge.x - 2, y: frontHinge.y))
            legPath.line(to: NSPoint(x: rx + 8.0 - gallop * 4.0, y: cy - 10))
            legPath.stroke()

            let bodyRect = NSRect(x: rx - 10, y: cy - 2, width: 20, height: 11)
            warmBrown.setFill()
            NSBezierPath(roundedRect: bodyRect, xRadius: 4, yRadius: 4).fill()

            white.setFill()
            NSBezierPath(ovalIn: NSRect(x: rx - 11.5, y: cy + 3.5, width: 3.5, height: 3.0)).fill()

            let neck = NSBezierPath()
            neck.move(to: NSPoint(x: rx + 5, y: cy + 3))
            neck.line(to: NSPoint(x: rx + 11, y: cy + 13))
            neck.line(to: NSPoint(x: rx + 8, y: cy + 13))
            neck.line(to: NSPoint(x: rx + 2, y: cy + 5))
            neck.close()
            neck.fill()

            let headRect = NSRect(x: rx + 8, y: cy + 10.5, width: 9.5, height: 6.0)
            NSBezierPath(roundedRect: headRect, xRadius: 2.5, yRadius: 2.5).fill()

            NSBezierPath(ovalIn: NSRect(x: rx + 8.5, y: cy + 15.0, width: 2.5, height: 3.5)).fill()

            let antlers = NSBezierPath()
            antlers.move(to: NSPoint(x: rx + 10.5, y: cy + 15.5))
            antlers.line(to: NSPoint(x: rx + 7.5, y: cy + 23.0))
            antlers.move(to: NSPoint(x: rx + 9.0, y: cy + 19.5))
            antlers.line(to: NSPoint(x: rx + 5.5, y: cy + 21.0))
            antlers.move(to: NSPoint(x: rx + 8.2, y: cy + 21.0))
            antlers.line(to: NSPoint(x: rx + 11.5, y: cy + 22.5))
            antlers.lineWidth = 1.3
            darkBrown.setStroke()
            antlers.stroke()

            let collarPoint = NSPoint(x: rx + 7.0, y: cy + 7.5)
            collarPositions.append(collarPoint)
            crimson.setFill()
            NSBezierPath(roundedRect: NSRect(x: rx + 5.5, y: cy + 6.5, width: 3.5, height: 2.2), xRadius: 1, yRadius: 1).fill()

            // Rudolph's glowing nose
            if idx == 2 {
                let noseCenter = NSPoint(x: rx + 17.5, y: cy + 13.0)
                let haloRect = NSRect(x: noseCenter.x - 7.5, y: noseCenter.y - 7.5, width: 15.0, height: 15.0)
                if let gradient = NSGradient(colors: [
                    rudolphRed.withAlphaComponent(0.65),
                    rudolphRed.withAlphaComponent(0.0)
                ]) {
                    gradient.draw(in: NSBezierPath(ovalIn: haloRect), relativeCenterPosition: .zero)
                }

                rudolphRed.setFill()
                NSBezierPath(ovalIn: NSRect(x: noseCenter.x - 2.0, y: noseCenter.y - 2.0, width: 4.0, height: 4.0)).fill()

                white.withAlphaComponent(0.85).setFill()
                NSBezierPath(ovalIn: NSRect(x: noseCenter.x + 0.3, y: noseCenter.y + 0.5, width: 1.2, height: 1.2)).fill()
            }
        }

        // 6. Golden reins in catenary curve
        if collarPositions.count == 3 {
            let reins = NSBezierPath()
            reins.move(to: NSPoint(x: -18, y: 8))
            reins.curve(to: collarPositions[0],
                        controlPoint1: NSPoint(x: -3, y: 3),
                        controlPoint2: NSPoint(x: 10, y: 4))
            reins.curve(to: collarPositions[1],
                        controlPoint1: NSPoint(x: collarPositions[0].x + 12, y: 4),
                        controlPoint2: NSPoint(x: collarPositions[1].x - 12, y: 5))
            reins.curve(to: collarPositions[2],
                        controlPoint1: NSPoint(x: collarPositions[1].x + 12, y: 5),
                        controlPoint2: NSPoint(x: collarPositions[2].x - 12, y: 6))
            reins.lineWidth = 1.2
            gold.withAlphaComponent(0.85).setStroke()
            reins.stroke()
        }
    }

    // MARK: - Pixel Art 8-bit Rendering

    private static func drawPixelArt(elapsed: Double, in ctx: CGContext) {
        NSGraphicsContext.current?.shouldAntialias = false
        ctx.setShouldAntialias(false)

        func putBlock(_ gx: Int, _ gy: Int, _ color: NSColor) {
            color.setFill()
            NSRect(x: CGFloat(gx) * 3.0, y: CGFloat(gy) * 3.0, width: 3.0, height: 3.0).fill()
        }

        let gold = NSColor(calibratedRed: 0.831, green: 0.686, blue: 0.216, alpha: 1.0)
        let crimson = NSColor(calibratedRed: 0.722, green: 0.259, blue: 0.216, alpha: 1.0)
        let sackBrown = NSColor(calibratedRed: 0.48, green: 0.30, blue: 0.16, alpha: 1.0)
        let deerBrown = NSColor(calibratedRed: 0.55, green: 0.33, blue: 0.18, alpha: 1.0)
        let antlersColor = NSColor(calibratedRed: 0.38, green: 0.22, blue: 0.12, alpha: 1.0)
        let skin = NSColor(calibratedRed: 0.98, green: 0.80, blue: 0.72, alpha: 1.0)
        let white = NSColor(calibratedWhite: 0.96, alpha: 1.0)
        let rudolphRed = NSColor(calibratedRed: 1.0, green: 0.231, blue: 0.188, alpha: 1.0)
        let rudolphHalo = rudolphRed.withAlphaComponent(0.35)

        // 1. Gold runner
        for gx in -24...(-6) {
            putBlock(gx, -3, gold)
        }
        putBlock(-5, -2, gold)
        putBlock(-5, -1, gold)
        putBlock(-20, -2, gold)
        putBlock(-10, -2, gold)

        // 2. Toy sack
        for gx in -22...(-17) {
            for gy in 1...3 {
                putBlock(gx, gy, sackBrown)
            }
        }
        putBlock(-20, 4, sackBrown)
        putBlock(-19, 4, sackBrown)

        // 3. Sleigh crimson body & gold trim
        for gx in -23...(-7) {
            putBlock(gx, -1, crimson)
            putBlock(gx, 0, crimson)
        }
        putBlock(-24, 0, crimson)
        putBlock(-24, 1, crimson)
        putBlock(-23, 1, crimson)
        putBlock(-23, 2, crimson)
        putBlock(-22, 2, crimson)
        putBlock(-7, 1, crimson)
        putBlock(-6, 1, crimson)
        putBlock(-6, 2, crimson)

        putBlock(-24, 2, gold)
        putBlock(-23, 3, gold)
        putBlock(-22, 3, gold)
        for gx in -12...(-8) {
            putBlock(gx, 0, gold)
        }
        putBlock(-6, 3, gold)
        putBlock(-5, 2, gold)

        // 4. Santa with beard and red hat
        for gx in -16...(-13) {
            putBlock(gx, 1, crimson)
            putBlock(gx, 2, crimson)
        }
        putBlock(-17, 2, white)
        putBlock(-16, 2, white)
        putBlock(-15, 2, white)
        putBlock(-14, 2, white)

        putBlock(-14, 3, skin)
        putBlock(-13, 3, skin)

        putBlock(-15, 4, crimson)
        putBlock(-14, 4, crimson)
        putBlock(-16, 4, crimson)
        putBlock(-17, 3, white)

        // 5. Golden reins in pixels
        let reinsPixels: [(Int, Int)] = [
            (-5, 1), (-3, 1), (-1, 1), (1, 1), (3, 1), (5, 2),
            (9, 2), (12, 2), (15, 2), (18, 2),
            (21, 2), (24, 2), (27, 2)
        ]
        for p in reinsPixels {
            putBlock(p.0, p.1, gold)
        }

        // 6. 3 Pixelated Reindeer
        let reindeersBX = [6, 17, 28]
        let legFrame = Int(elapsed * 8.0) % 2

        for (idx, bx) in reindeersBX.enumerated() {
            for gx in bx...(bx + 4) {
                putBlock(gx, 0, deerBrown)
                putBlock(gx, 1, deerBrown)
            }
            putBlock(bx - 1, 1, white)

            putBlock(bx + 3, 2, deerBrown)
            putBlock(bx + 4, 2, deerBrown)
            putBlock(bx + 4, 3, deerBrown)
            putBlock(bx + 5, 3, deerBrown)

            putBlock(bx + 3, 4, antlersColor)
            putBlock(bx + 3, 5, antlersColor)
            putBlock(bx + 2, 5, antlersColor)
            putBlock(bx + 4, 5, antlersColor)

            if (legFrame + idx) % 2 == 0 {
                putBlock(bx + 4, -1, deerBrown)
                putBlock(bx + 5, -2, deerBrown)
                putBlock(bx, -1, deerBrown)
                putBlock(bx - 1, -2, deerBrown)
            } else {
                putBlock(bx + 4, -1, deerBrown)
                putBlock(bx + 3, -2, deerBrown)
                putBlock(bx + 1, -1, deerBrown)
                putBlock(bx + 2, -2, deerBrown)
            }

            putBlock(bx + 3, 2, gold)

            if idx == 2 {
                putBlock(bx + 6, 3, rudolphRed)
                putBlock(bx + 6, 4, rudolphHalo)
                putBlock(bx + 6, 2, rudolphHalo)
                putBlock(bx + 5, 3, rudolphHalo)
                putBlock(bx + 7, 3, rudolphHalo)
            }
        }
    }
}
