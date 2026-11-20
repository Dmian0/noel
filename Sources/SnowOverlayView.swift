import AppKit
import QuartzCore
import Darwin

/// GPU-backed click-through overlay view providing interactive snow particles,
/// blizzard atmospheric effects, interactive snowbanks, and snowball physics
/// using pure lightweight CALayers to eliminate backing store allocations.
final class SnowOverlayView: NSView {

    private struct Snowflake {
        var x: CGFloat
        var y: CGFloat
        var vx: CGFloat
        var radius: CGFloat
        var speedY: CGFloat
        var driftPhase: Double
        var driftSpeed: Double
        var driftAmp: CGFloat
        var opacity: CGFloat
        var isCrystal: Bool
        var depthLayer: Int // 0 = fondo lejano fino, 1 = plano medio, 2 = primer plano grande y rapido
    }

    private struct SnowSprayParticle {
        var x: CGFloat
        var y: CGFloat
        var vx: CGFloat
        var vy: CGFloat
        var radius: CGFloat
        var opacity: CGFloat
        var age: Double
        var maxAge: Double
    }

    private struct HeldSnowball {
        var x: CGFloat
        var y: CGFloat
        var radius: CGFloat
    }

    private struct FlyingSnowball {
        var x: CGFloat
        var y: CGFloat
        var vx: CGFloat
        var vy: CGFloat
        var radius: CGFloat
        var isFromElf: Bool = false
        var age: Double = 0.0
    }

    private struct LandedGift {
        var x: CGFloat
        var age: Double
        var maxAge: Double
        var style: IconStyle
    }

    private enum ElfPose: Int, CaseIterable {
        case walk0 = 0
        case walk1 = 1
        case dig = 2
        case plow = 3
        case carryGift = 4
        case knockedDown = 5
        case throwBall = 6
    }

    private enum ElfBehaviorState {
        case patrolling
        case shoveling
        case rescuingSanta
        case fetchingGift
        case buildingSnowman(targetX: CGFloat)
        case knockedDown
        case throwingCounterBall
    }

    private struct SnowElf {
        var x: CGFloat
        var facingRight: Bool
        var behavior: ElfBehaviorState
        var stateTimer: Double
        var targetX: CGFloat
        var animTime: Double
        var carryingGift: Bool
        var buildCooldown: Double
    }

    private struct Snowman {
        var x: CGFloat
        var stage: Int // 1 = base, 2 = base + torso, 3 = completo
        var buildProgress: Double
    }

    // MARK: - Static Tiny Cached Textures (< 65 KB total)

    private static func makeContext(width: Int, height: Int) -> CGContext? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        return CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        )
    }

    // MARK: Vector / 3D Smooth Textures

    private static let normalFlakeImage: CGImage? = {
        guard let ctx = makeContext(width: 16, height: 16) else { return nil }
        let center = CGPoint(x: 8, y: 8)
        let colors = [
            NSColor.white.cgColor,
            NSColor.white.withAlphaComponent(0.95).cgColor,
            NSColor.white.withAlphaComponent(0.0).cgColor
        ] as CFArray
        let locations: [CGFloat] = [0.0, 0.7, 1.0]
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) {
            ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: 7.5, options: .drawsAfterEndLocation)
        }
        return ctx.makeImage()
    }()

    private static let bokehFlakeImage: CGImage? = {
        guard let ctx = makeContext(width: 32, height: 32) else { return nil }
        let center = CGPoint(x: 16, y: 16)
        let colors = [
            NSColor.white.withAlphaComponent(0.95).cgColor,
            NSColor.white.withAlphaComponent(0.40).cgColor,
            NSColor.white.withAlphaComponent(0.0).cgColor
        ] as CFArray
        let locations: [CGFloat] = [0.0, 0.45, 1.0]
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) {
            ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: 15.0, options: .drawsAfterEndLocation)
        }
        return ctx.makeImage()
    }()

    private static let crystalFlakeImage: CGImage? = {
        guard let ctx = makeContext(width: 24, height: 24) else { return nil }
        ctx.setStrokeColor(NSColor.white.cgColor)
        ctx.setLineWidth(1.6)
        ctx.setLineCap(.round)
        let center = CGPoint(x: 12, y: 12)
        let r: CGFloat = 9.5
        for arm in 0..<3 {
            let angle = CGFloat(arm) * (.pi / 3.0)
            let dx = cos(angle) * r
            let dy = sin(angle) * r
            ctx.move(to: CGPoint(x: center.x - dx, y: center.y - dy))
            ctx.addLine(to: CGPoint(x: center.x + dx, y: center.y + dy))
        }
        ctx.strokePath()
        return ctx.makeImage()
    }()

    private static let snowballImage: CGImage? = {
        guard let ctx = makeContext(width: 32, height: 32) else { return nil }
        let center = CGPoint(x: 16, y: 16)
        let radius: CGFloat = 14.5

        let shadowColor = NSColor(calibratedRed: 0.80, green: 0.90, blue: 1.0, alpha: 0.95).cgColor
        let highlightColor = NSColor.white.cgColor
        let colors = [highlightColor, shadowColor] as CFArray
        let locations: [CGFloat] = [0.0, 1.0]

        ctx.saveGState()
        ctx.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        ctx.clip()

        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) {
            let startPt = CGPoint(x: 10, y: 22)
            let endPt = CGPoint(x: 22, y: 10)
            ctx.drawLinearGradient(gradient, start: startPt, end: endPt, options: [])
        }

        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fillEllipse(in: CGRect(x: 9, y: 19, width: 4.5, height: 4.5))
        ctx.restoreGState()

        return ctx.makeImage()
    }()

    // MARK: Retro / 8-Bit Pixel Art Textures

    private static let pixelNormalFlakeImage: CGImage? = {
        guard let ctx = makeContext(width: 16, height: 16) else { return nil }
        ctx.setShouldAntialias(false)
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fill(CGRect(x: 5, y: 5, width: 6, height: 6))
        ctx.fill(CGRect(x: 7, y: 11, width: 2, height: 2))
        ctx.fill(CGRect(x: 7, y: 3, width: 2, height: 2))
        ctx.fill(CGRect(x: 3, y: 7, width: 2, height: 2))
        ctx.fill(CGRect(x: 11, y: 7, width: 2, height: 2))
        return ctx.makeImage()
    }()

    private static let pixelBokehFlakeImage: CGImage? = {
        guard let ctx = makeContext(width: 24, height: 24) else { return nil }
        ctx.setShouldAntialias(false)
        ctx.setFillColor(NSColor.white.withAlphaComponent(0.45).cgColor)
        ctx.fill(CGRect(x: 9, y: 16, width: 6, height: 3))
        ctx.fill(CGRect(x: 9, y: 5, width: 6, height: 3))
        ctx.fill(CGRect(x: 5, y: 9, width: 3, height: 6))
        ctx.fill(CGRect(x: 16, y: 9, width: 3, height: 6))
        ctx.fill(CGRect(x: 6, y: 15, width: 2, height: 2))
        ctx.fill(CGRect(x: 16, y: 15, width: 2, height: 2))
        ctx.fill(CGRect(x: 6, y: 7, width: 2, height: 2))
        ctx.fill(CGRect(x: 16, y: 7, width: 2, height: 2))
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fill(CGRect(x: 8, y: 8, width: 8, height: 8))
        return ctx.makeImage()
    }()

    private static let pixelCrystalFlakeImage: CGImage? = {
        guard let ctx = makeContext(width: 24, height: 24) else { return nil }
        ctx.setShouldAntialias(false)
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fill(CGRect(x: 11, y: 3, width: 2, height: 18))
        ctx.fill(CGRect(x: 3, y: 11, width: 18, height: 2))
        ctx.fill(CGRect(x: 8, y: 14, width: 2, height: 2))
        ctx.fill(CGRect(x: 14, y: 14, width: 2, height: 2))
        ctx.fill(CGRect(x: 8, y: 8, width: 2, height: 2))
        ctx.fill(CGRect(x: 14, y: 8, width: 2, height: 2))
        return ctx.makeImage()
    }()

    private static let pixelSnowballImage: CGImage? = {
        guard let ctx = makeContext(width: 24, height: 24) else { return nil }
        ctx.setShouldAntialias(false)
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fill(CGRect(x: 6, y: 18, width: 12, height: 3))
        ctx.fill(CGRect(x: 3, y: 6, width: 18, height: 12))
        ctx.fill(CGRect(x: 6, y: 3, width: 12, height: 3))

        let iceBlue = NSColor(calibratedRed: 0.76, green: 0.88, blue: 1.0, alpha: 0.95).cgColor
        ctx.setFillColor(iceBlue)
        ctx.fill(CGRect(x: 6, y: 3, width: 12, height: 3))
        ctx.fill(CGRect(x: 15, y: 6, width: 6, height: 3))
        ctx.fill(CGRect(x: 18, y: 9, width: 3, height: 6))

        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fill(CGRect(x: 6, y: 15, width: 3, height: 3))
        return ctx.makeImage()
    }()

    // MARK: Landed Gifts Textures

    private static func createLandedGiftImage(pixelArt: Bool) -> CGImage? {
        let size = 18
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

        if pixelArt {
            ctx.setShouldAntialias(false)
            ctx.setFillColor(red: 0.85, green: 0.18, blue: 0.20, alpha: 1.0)
            ctx.fill(CGRect(x: 3, y: 1, width: 12, height: 12))

            ctx.setFillColor(red: 0.95, green: 0.80, blue: 0.22, alpha: 1.0)
            ctx.fill(CGRect(x: 8, y: 1, width: 2, height: 12))
            ctx.fill(CGRect(x: 3, y: 6, width: 12, height: 2))

            ctx.fill(CGRect(x: 5, y: 13, width: 3, height: 2))
            ctx.fill(CGRect(x: 10, y: 13, width: 3, height: 2))
            ctx.fill(CGRect(x: 7, y: 13, width: 4, height: 3))
        } else {
            ctx.setShouldAntialias(true)
            ctx.setFillColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.18)
            ctx.fillEllipse(in: CGRect(x: 2, y: 0, width: 14, height: 3))

            let box = CGRect(x: 3, y: 1, width: 12, height: 12)
            ctx.setFillColor(red: 0.80, green: 0.16, blue: 0.18, alpha: 1.0)
            ctx.addPath(CGPath(roundedRect: box, cornerWidth: 1.5, cornerHeight: 1.5, transform: nil))
            ctx.fillPath()

            ctx.setFillColor(red: 0.95, green: 0.80, blue: 0.24, alpha: 1.0)
            ctx.fill(CGRect(x: 8, y: 1, width: 2, height: 12))
            ctx.fill(CGRect(x: 3, y: 6, width: 12, height: 2))

            ctx.fillEllipse(in: CGRect(x: 4.5, y: 12.5, width: 4.5, height: 3.5))
            ctx.fillEllipse(in: CGRect(x: 9.0, y: 12.5, width: 4.5, height: 3.5))
            ctx.setFillColor(red: 1.0, green: 0.88, blue: 0.35, alpha: 1.0)
            ctx.fillEllipse(in: CGRect(x: 7.5, y: 12.0, width: 3.0, height: 3.0))
        }
        return ctx.makeImage()
    }

    private static let landedGift3DImage: CGImage? = createLandedGiftImage(pixelArt: false)
    private static let landedGiftPixelImage: CGImage? = createLandedGiftImage(pixelArt: true)

    // MARK: - Elf & Snowman Textures

    private static func createElfImage(pose: ElfPose, pixelArt: Bool) -> CGImage? {
        let w = 24
        let h = 28
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

        ctx.setShouldAntialias(!pixelArt)

        let isDown = (pose == .knockedDown)

        let bootColor = NSColor(calibratedRed: 0.18, green: 0.14, blue: 0.12, alpha: 1.0).cgColor
        let legColor = NSColor(calibratedRed: 0.85, green: 0.18, blue: 0.20, alpha: 1.0).cgColor
        let tunicColor = NSColor(calibratedRed: 0.14, green: 0.62, blue: 0.28, alpha: 1.0).cgColor
        let beltColor = NSColor(calibratedRed: 0.12, green: 0.12, blue: 0.12, alpha: 1.0).cgColor
        let buckleColor = NSColor(calibratedRed: 0.95, green: 0.80, blue: 0.22, alpha: 1.0).cgColor
        let skinColor = NSColor(calibratedRed: 0.98, green: 0.80, blue: 0.72, alpha: 1.0).cgColor
        let hatColor = NSColor(calibratedRed: 0.85, green: 0.18, blue: 0.20, alpha: 1.0).cgColor
        let whiteColor = NSColor.white.cgColor
        let shovelWood = NSColor(calibratedRed: 0.55, green: 0.35, blue: 0.18, alpha: 1.0).cgColor
        let shovelBlade = NSColor(calibratedRed: 0.82, green: 0.86, blue: 0.90, alpha: 1.0).cgColor

        if isDown {
            ctx.setFillColor(bootColor)
            ctx.fill(CGRect(x: 13, y: 2, width: 6, height: 4))
            ctx.setFillColor(legColor)
            ctx.fill(CGRect(x: 10, y: 2, width: 4, height: 4))

            ctx.setFillColor(tunicColor)
            ctx.fill(CGRect(x: 4, y: 3, width: 8, height: 8))

            ctx.setFillColor(beltColor)
            ctx.fill(CGRect(x: 4, y: 5, width: 8, height: 2))
            ctx.setFillColor(buckleColor)
            ctx.fill(CGRect(x: 7, y: 5, width: 2, height: 2))

            ctx.setFillColor(skinColor)
            ctx.fill(CGRect(x: 5, y: 11, width: 7, height: 6))
            ctx.setFillColor(bootColor)
            ctx.fill(CGRect(x: 8, y: 13, width: 1.5, height: 1.5))

            ctx.setFillColor(hatColor)
            ctx.fill(CGRect(x: 4, y: 16, width: 7, height: 4))
            ctx.fill(CGRect(x: 2, y: 18, width: 4, height: 3))
            ctx.setFillColor(whiteColor)
            ctx.fill(CGRect(x: 1, y: 19, width: 2.5, height: 2.5))

            ctx.setFillColor(buckleColor)
            ctx.fill(CGRect(x: 4, y: 23, width: 2.5, height: 2.5))
            ctx.fill(CGRect(x: 10, y: 24, width: 2.5, height: 2.5))
        } else {
            let isWalk1 = (pose == .walk1)
            let isDig = (pose == .dig)
            let isPlow = (pose == .plow)
            let isCarry = (pose == .carryGift)
            let isThrow = (pose == .throwBall)

            let bodyOffX: CGFloat = isDig ? 2.0 : 0.0
            let bodyOffY: CGFloat = isDig ? -1.5 : 0.0

            ctx.setFillColor(bootColor)
            if isWalk1 {
                ctx.fill(CGRect(x: 8 + bodyOffX, y: 1, width: 3.5, height: 3))
                ctx.fill(CGRect(x: 12 + bodyOffX, y: 2, width: 3.5, height: 3))
            } else {
                ctx.fill(CGRect(x: 7 + bodyOffX, y: 2, width: 3.5, height: 3))
                ctx.fill(CGRect(x: 13 + bodyOffX, y: 1, width: 3.5, height: 3))
            }

            ctx.setFillColor(legColor)
            ctx.fill(CGRect(x: 8 + bodyOffX, y: 4, width: 2.5, height: 4))
            ctx.fill(CGRect(x: 12 + bodyOffX, y: 4, width: 2.5, height: 4))

            ctx.setFillColor(tunicColor)
            ctx.fill(CGRect(x: 6 + bodyOffX, y: 8 + bodyOffY, width: 10, height: 8))

            ctx.setFillColor(beltColor)
            ctx.fill(CGRect(x: 6 + bodyOffX, y: 9 + bodyOffY, width: 10, height: 2))
            ctx.setFillColor(buckleColor)
            ctx.fill(CGRect(x: 10 + bodyOffX, y: 9 + bodyOffY, width: 2.5, height: 2))

            ctx.setFillColor(hatColor)
            ctx.fill(CGRect(x: 7 + bodyOffX, y: 15 + bodyOffY, width: 8, height: 2))

            ctx.setFillColor(skinColor)
            ctx.fill(CGRect(x: 7 + bodyOffX, y: 16 + bodyOffY, width: 8, height: 6))
            ctx.setFillColor(bootColor)
            ctx.fill(CGRect(x: 12 + bodyOffX, y: 18 + bodyOffY, width: 1.5, height: 1.5))

            ctx.setFillColor(hatColor)
            ctx.fill(CGRect(x: 6 + bodyOffX, y: 21 + bodyOffY, width: 9, height: 4))
            ctx.fill(CGRect(x: 4 + bodyOffX, y: 24 + bodyOffY, width: 6, height: 3))
            ctx.setFillColor(whiteColor)
            ctx.fill(CGRect(x: 2 + bodyOffX, y: 25 + bodyOffY, width: 3, height: 3))

            if isDig {
                ctx.setFillColor(shovelWood)
                ctx.fill(CGRect(x: 13, y: 6, width: 2, height: 9))
                ctx.setFillColor(shovelBlade)
                ctx.fill(CGRect(x: 14, y: 1, width: 6, height: 6))
            } else if isPlow {
                ctx.setFillColor(hatColor)
                ctx.fill(CGRect(x: 16, y: 1, width: 7, height: 11))
                ctx.setFillColor(buckleColor)
                ctx.fill(CGRect(x: 22, y: 1, width: 2, height: 11))
                ctx.setFillColor(shovelWood)
                ctx.fill(CGRect(x: 13, y: 8, width: 4, height: 2))
            } else if isCarry {
                let giftBox = CGRect(x: 14, y: 9, width: 8, height: 8)
                ctx.setFillColor(hatColor)
                ctx.fill(giftBox)
                ctx.setFillColor(buckleColor)
                ctx.fill(CGRect(x: 17, y: 9, width: 2, height: 8))
                ctx.fill(CGRect(x: 14, y: 12, width: 8, height: 2))
            } else if isThrow {
                ctx.setFillColor(skinColor)
                ctx.fill(CGRect(x: 12, y: 14, width: 4, height: 5))
                ctx.setFillColor(whiteColor)
                ctx.fill(CGRect(x: 15, y: 18, width: 5.5, height: 5.5))
            } else {
                ctx.setFillColor(shovelWood)
                ctx.fill(CGRect(x: 14, y: 6, width: 2, height: 10))
                ctx.setFillColor(shovelBlade)
                ctx.fill(CGRect(x: 15, y: 4, width: 5, height: 5))
            }
        }

        return ctx.makeImage()
    }

    private static func createSnowmanImage(stage: Int, pixelArt: Bool) -> CGImage? {
        let w = 26
        let h = 34
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

        ctx.setShouldAntialias(!pixelArt)

        let whiteColor = NSColor.white.cgColor
        let shadowColor = NSColor(calibratedRed: 0.82, green: 0.90, blue: 0.98, alpha: 0.95).cgColor
        let coalColor = NSColor(calibratedRed: 0.15, green: 0.15, blue: 0.15, alpha: 1.0).cgColor
        let carrotColor = NSColor(calibratedRed: 1.0, green: 0.48, blue: 0.10, alpha: 1.0).cgColor
        let scarfColor = NSColor(calibratedRed: 0.88, green: 0.16, blue: 0.18, alpha: 1.0).cgColor
        let twigColor = NSColor(calibratedRed: 0.48, green: 0.30, blue: 0.16, alpha: 1.0).cgColor

        ctx.setFillColor(shadowColor)
        ctx.fillEllipse(in: CGRect(x: 4, y: 2, width: 18, height: 16))
        ctx.setFillColor(whiteColor)
        ctx.fillEllipse(in: CGRect(x: 4.5, y: 3.5, width: 17, height: 14.5))

        if stage >= 2 {
            ctx.setFillColor(shadowColor)
            ctx.fillEllipse(in: CGRect(x: 6, y: 13, width: 14, height: 13))
            ctx.setFillColor(whiteColor)
            ctx.fillEllipse(in: CGRect(x: 6.5, y: 14.2, width: 13, height: 11.8))

            ctx.setFillColor(coalColor)
            ctx.fillEllipse(in: CGRect(x: 12, y: 19, width: 2.2, height: 2.2))
            ctx.fillEllipse(in: CGRect(x: 12, y: 15.5, width: 2.2, height: 2.2))
        }

        if stage >= 3 {
            ctx.setFillColor(twigColor)
            ctx.fill(CGRect(x: 2, y: 18, width: 5, height: 2))
            ctx.fill(CGRect(x: 19, y: 18, width: 5, height: 2))

            ctx.setFillColor(shadowColor)
            ctx.fillEllipse(in: CGRect(x: 8, y: 21, width: 10, height: 9))
            ctx.setFillColor(whiteColor)
            ctx.fillEllipse(in: CGRect(x: 8.5, y: 21.8, width: 9, height: 8.2))

            ctx.setFillColor(scarfColor)
            ctx.fill(CGRect(x: 7, y: 21.5, width: 12, height: 3))
            ctx.fill(CGRect(x: 15, y: 17, width: 3, height: 5.5))

            ctx.setFillColor(coalColor)
            ctx.fillEllipse(in: CGRect(x: 10.5, y: 26, width: 1.8, height: 1.8))
            ctx.fillEllipse(in: CGRect(x: 14.5, y: 26, width: 1.8, height: 1.8))

            ctx.setFillColor(carrotColor)
            ctx.fill(CGRect(x: 13, y: 24, width: 5, height: 2))

            ctx.setFillColor(coalColor)
            ctx.fill(CGRect(x: 6.5, y: 28.5, width: 13, height: 2))
            ctx.fill(CGRect(x: 9, y: 30.5, width: 8, height: 3.5))
            ctx.setFillColor(scarfColor)
            ctx.fill(CGRect(x: 9, y: 30.5, width: 8, height: 1.2))
        }

        return ctx.makeImage()
    }

    private static let elf3DImages: [ElfPose: CGImage] = {
        var dict: [ElfPose: CGImage] = [:]
        for pose in ElfPose.allCases {
            if let img = createElfImage(pose: pose, pixelArt: false) {
                dict[pose] = img
            }
        }
        return dict
    }()

    private static let elfPixelImages: [ElfPose: CGImage] = {
        var dict: [ElfPose: CGImage] = [:]
        for pose in ElfPose.allCases {
            if let img = createElfImage(pose: pose, pixelArt: true) {
                dict[pose] = img
            }
        }
        return dict
    }()

    private static func elfImage(pose: ElfPose, pixelArt: Bool) -> CGImage? {
        return pixelArt ? elfPixelImages[pose] : elf3DImages[pose]
    }

    private static let snowman3DImages: [Int: CGImage] = {
        var dict: [Int: CGImage] = [:]
        for s in 1...3 {
            if let img = createSnowmanImage(stage: s, pixelArt: false) {
                dict[s] = img
            }
        }
        return dict
    }()

    private static let snowmanPixelImages: [Int: CGImage] = {
        var dict: [Int: CGImage] = [:]
        for s in 1...3 {
            if let img = createSnowmanImage(stage: s, pixelArt: true) {
                dict[s] = img
            }
        }
        return dict
    }()

    private static func snowmanImage(stage: Int, pixelArt: Bool) -> CGImage? {
        let s = max(1, min(3, stage))
        return pixelArt ? snowmanPixelImages[s] : snowman3DImages[s]
    }

    // MARK: Gradients for Snowbank

    private static let backSnowGradient: CGGradient? = {
        let colors = [
            NSColor(calibratedRed: 110.0 / 255.0, green: 155.0 / 255.0, blue: 190.0 / 255.0, alpha: 0.85).cgColor,
            NSColor(calibratedRed: 152.0 / 255.0, green: 192.0 / 255.0, blue: 222.0 / 255.0, alpha: 0.75).cgColor
        ] as CFArray
        let locations: [CGFloat] = [0.0, 1.0]
        return CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations)
    }()

    private static let frontSnowGradient: CGGradient? = {
        let colors = [
            NSColor(calibratedRed: 215.0 / 255.0, green: 235.0 / 255.0, blue: 250.0 / 255.0, alpha: 0.94).cgColor,
            NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.99).cgColor
        ] as CFArray
        let locations: [CGFloat] = [0.0, 1.0]
        return CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations)
    }()

    private static let noAnimActions: [String: CAAction] = [
        "position": NSNull(),
        "bounds": NSNull(),
        "opacity": NSNull(),
        "contents": NSNull(),
        "hidden": NSNull(),
        "transform": NSNull()
    ]

    // MARK: - Permanent Sublayer Pools (Zero CAShapeLayers)

    private var streakLayers: [CALayer] = []
    private let driftStripLayer = CALayer()
    private var aimDotLayers: [CALayer] = []
    private let heldBallLayer = CALayer()

    // MARK: - Reusable Dynamic Layer Pools

    private var flakeLayers: [CALayer] = []
    private var sprayLayers: [CALayer] = []
    private var flyingBallLayers: [CALayer] = []
    private var landedGiftLayers: [CALayer] = []
    private var elfLayers: [CALayer] = []
    private var snowmanLayers: [CALayer] = []

    // MARK: - Simulation State

    private let numBins = 128
    private var driftRenderTick: Int = 0
    private var lastRenderedSnowbankStyle: IconStyle?
    private var flakes: [Snowflake] = []
    private var sprayParticles: [SnowSprayParticle] = []
    private var heldSnowball: HeldSnowball?
    private var flyingSnowballs: [FlyingSnowball] = []
    private var landedGifts: [LandedGift] = []
    private var snowElves: [SnowElf] = []
    private var snowmen: [Snowman] = []
    private var timer: Timer?
    private var targetCount: Int = 100
    private var currentIntensity: Double = 0.6
    private var time: Double = 0
    private var lastMousePt: NSPoint?
    private var wasMouseDown: Bool = false
    private var throwVX: CGFloat = 0
    private var throwVY: CGFloat = 0
    private var driftBins: [CGFloat] = Array(repeating: 0, count: 128)
    private var hasSetupLayers = false

    override var isOpaque: Bool { false }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    // MARK: - Initializers

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayersIfNeeded()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayersIfNeeded()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        setupLayersIfNeeded()
    }

    private func ensureStaticLayerPools() {
        guard let rootLayer = self.layer else { return }

        if streakLayers.isEmpty {
            for _ in 0..<14 {
                let l = CALayer()
                l.actions = Self.noAnimActions
                l.backgroundColor = NSColor.white.withAlphaComponent(0.18).cgColor
                l.bounds = CGRect(x: 0, y: 0, width: 36.0, height: 1.2)
                l.transform = CATransform3DMakeRotation(-0.66, 0, 0, 1)
                l.zPosition = 0
                l.isHidden = true
                rootLayer.addSublayer(l)
                streakLayers.append(l)
            }
        }

        if aimDotLayers.isEmpty {
            for _ in 0..<16 {
                let l = CALayer()
                l.actions = Self.noAnimActions
                l.contents = Self.normalFlakeImage
                l.bounds = CGRect(x: 0, y: 0, width: 4.5, height: 4.5)
                l.opacity = 0.72
                l.zPosition = 10
                l.isHidden = true
                rootLayer.addSublayer(l)
                aimDotLayers.append(l)
            }
        }
    }

    private func setupLayersIfNeeded() {
        wantsLayer = true
        guard let rootLayer = self.layer else { return }
        rootLayer.masksToBounds = true
        guard !hasSetupLayers else { return }
        hasSetupLayers = true

        ensureStaticLayerPools()

        driftStripLayer.actions = Self.noAnimActions
        driftStripLayer.anchorPoint = CGPoint(x: 0.0, y: 0.0)
        driftStripLayer.position = CGPoint(x: 0.0, y: 0.0)
        driftStripLayer.zPosition = 1
        rootLayer.addSublayer(driftStripLayer)

        heldBallLayer.actions = Self.noAnimActions
        heldBallLayer.contents = Self.snowballImage
        heldBallLayer.isHidden = true
        heldBallLayer.zPosition = 11
        rootLayer.addSublayer(heldBallLayer)
    }

    // MARK: - Public Controls & External Impacts

    func setIntensity(_ intensity: Double) {
        currentIntensity = intensity
        if intensity <= 0.4 {
            targetCount = 42
        } else if intensity <= 0.75 {
            targetCount = 100
        } else {
            targetCount = 300
        }
        adjustFlakeCount()
    }

    func start() {
        setupLayersIfNeeded()
        ensureStaticLayerPools()
        if driftBins.allSatisfy({ $0 <= 0.1 }) {
            for i in 0..<numBins {
                let t = Double(i) / Double(numBins - 1)
                let w1 = sin(t * .pi * 4.2 + 0.4)
                let w2 = sin(t * .pi * 8.6 + 1.2) * 0.45
                let w3 = sin(t * .pi * 14.0) * 0.22
                let factor = 0.65 + 0.35 * (w1 + w2 + w3)
                driftBins[i] = max(7.0, CGFloat(18.0 * abs(factor)))
            }
        }
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
        driftBins = Array(repeating: 0, count: numBins)
        sprayParticles.removeAll()
        flyingSnowballs.removeAll()
        landedGifts.removeAll()
        snowElves.removeAll()
        snowmen.removeAll()
        heldSnowball = nil
        lastMousePt = nil
        wasMouseDown = false
        lastRenderedSnowbankStyle = nil

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for l in flakeLayers { l.removeFromSuperlayer() }
        flakeLayers.removeAll()
        for l in sprayLayers { l.removeFromSuperlayer() }
        sprayLayers.removeAll()
        for l in flyingBallLayers { l.removeFromSuperlayer() }
        flyingBallLayers.removeAll()
        for l in landedGiftLayers { l.removeFromSuperlayer() }
        landedGiftLayers.removeAll()
        for l in elfLayers { l.removeFromSuperlayer() }
        elfLayers.removeAll()
        for l in snowmanLayers { l.removeFromSuperlayer() }
        snowmanLayers.removeAll()
        for l in streakLayers { l.removeFromSuperlayer() }
        streakLayers.removeAll()
        for l in aimDotLayers { l.removeFromSuperlayer() }
        aimDotLayers.removeAll()
        heldBallLayer.isHidden = true
        driftStripLayer.contents = nil
        CATransaction.commit()

        malloc_zone_pressure_relief(nil, 0)
    }

    func receiveSantaCrash(atLocalX x: CGFloat) {
        let w = max(bounds.width, 1.0)
        for i in 0..<numBins {
            let binX = (CGFloat(i) / CGFloat(numBins - 1)) * w
            let dist = abs(binX - x)
            if dist < 32.0 {
                driftBins[i] = min(driftBins[i], max(3.0, driftBins[i] * 0.25))
            } else if dist < 60.0 {
                driftBins[i] = min(40.0, driftBins[i] + 7.5 * (1.0 - (dist - 32.0) / 28.0))
            }
        }
        explodeBall(at: NSPoint(x: x, y: 16.0), count: 38)
    }

    func addLandedGift(atLocalX x: CGFloat, style: IconStyle) {
        let clampedX = max(18.0, min(max(18.0, bounds.width - 18.0), x))
        if landedGifts.count >= 8 {
            landedGifts.removeFirst()
        }
        landedGifts.append(LandedGift(x: clampedX, age: 0.0, maxAge: 10.0, style: style))
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
        let roll = Double.random(in: 0...1)
        let depthLayer: Int
        let radius: CGFloat
        let opacity: CGFloat

        if currentIntensity > 0.75 {
            if roll < 0.45 {
                depthLayer = 0
                radius = CGFloat.random(in: 1.2...2.2)
                opacity = CGFloat.random(in: 0.30...0.52)
            } else if roll < 0.80 {
                depthLayer = 1
                radius = CGFloat.random(in: 2.4...4.2)
                opacity = CGFloat.random(in: 0.55...0.85)
            } else {
                depthLayer = 2
                radius = CGFloat.random(in: 4.8...7.2)
                opacity = CGFloat.random(in: 0.65...0.90)
            }
        } else {
            if roll < 0.50 {
                depthLayer = 0
                radius = CGFloat.random(in: 1.2...2.4)
                opacity = CGFloat.random(in: 0.35...0.55)
            } else {
                depthLayer = 1
                radius = CGFloat.random(in: 2.4...4.4)
                opacity = CGFloat.random(in: 0.55...0.85)
            }
        }

        return Snowflake(
            x: CGFloat.random(in: 0...width),
            y: randomY ? CGFloat.random(in: 0...height) : height + CGFloat.random(in: 4...24),
            vx: 0,
            radius: radius,
            speedY: CGFloat.random(in: 0.75...2.35) * (0.65 + radius * 0.14),
            driftPhase: Double.random(in: 0...(2 * .pi)),
            driftSpeed: Double.random(in: 0.8...2.1),
            driftAmp: CGFloat.random(in: 0.25...0.95),
            opacity: opacity,
            isCrystal: radius > 3.6 && Int.random(in: 0...3) == 0,
            depthLayer: depthLayer
        )
    }

    private func nearestLandedGift(forElfAt x: CGFloat, excludingElfIdx elfIdx: Int) -> (Int, LandedGift)? {
        guard !landedGifts.isEmpty else { return nil }
        var bestIdx: Int?
        var bestDist: CGFloat = .greatestFiniteMagnitude

        for (gIdx, gift) in landedGifts.enumerated() {
            guard gift.age > 1.8 else { continue }
            let alreadyTargeted = snowElves.enumerated().contains { (idx, other) in
                idx != elfIdx && abs(other.targetX - gift.x) < 16.0
            }
            if alreadyTargeted { continue }

            let dist = abs(gift.x - x)
            if dist < bestDist {
                bestDist = dist
                bestIdx = gIdx
            }
        }

        if let idx = bestIdx {
            return (idx, landedGifts[idx])
        }
        return nil
    }

    private func poseForElf(_ elf: SnowElf) -> ElfPose {
        switch elf.behavior {
        case .knockedDown:
            return .knockedDown
        case .throwingCounterBall:
            return .throwBall
        case .rescuingSanta, .shoveling:
            return .dig
        case .fetchingGift, .buildingSnowman:
            if elf.carryingGift { return .carryGift }
            return (Int(elf.animTime * 8.0) % 2 == 0) ? .walk0 : .walk1
        case .patrolling:
            if elf.carryingGift { return .carryGift }
            if currentIntensity > 0.75 { return .plow }
            return (Int(elf.animTime * 8.0) % 2 == 0) ? .walk0 : .walk1
        }
    }

    private func step() {
        let w = bounds.width
        let h = bounds.height
        guard w > 0, h > 0 else { return }

        time += 1.0 / 30.0
        let dt = 1.0 / 30.0

        let rawMousePt = window?.convertPoint(fromScreen: NSEvent.mouseLocation)
        let mouseInside = (rawMousePt != nil && bounds.contains(rawMousePt!))
        let mouseDX: CGFloat = (rawMousePt != nil && lastMousePt != nil) ? (rawMousePt!.x - lastMousePt!.x) : 0
        let mouseDY: CGFloat = (rawMousePt != nil && lastMousePt != nil) ? (rawMousePt!.y - lastMousePt!.y) : 0
        lastMousePt = rawMousePt
        let isMouseDown = (NSEvent.pressedMouseButtons & 1) != 0

        let binW = max(1.0, w / CGFloat(numBins))
        let mouseBin = min(numBins - 1, max(0, Int((rawMousePt?.x ?? 0) / binW)))
        let bankH = driftBins[mouseBin]
        let maxH: CGFloat = currentIntensity > 0.75 ? 36.0 : 20.0

        // Sincronizar monitos con AppState.shared.snowElvesMode.count
        let targetElves = AppState.shared.snowElvesMode.count
        if snowElves.count < targetElves {
            while snowElves.count < targetElves {
                let idx = snowElves.count
                let spawnX = w * CGFloat(idx + 1) / CGFloat(targetElves + 1)
                let targetX = CGFloat.random(in: 50...max(60, w - 50))
                snowElves.append(SnowElf(
                    x: spawnX,
                    facingRight: Bool.random(),
                    behavior: .patrolling,
                    stateTimer: 0.0,
                    targetX: targetX,
                    animTime: Double(idx) * 0.4,
                    carryingGift: false,
                    buildCooldown: Double(idx) * 3.0 + 4.0
                ))
            }
        } else if snowElves.count > targetElves {
            snowElves.removeLast(snowElves.count - targetElves)
        }

        // Suavizado continuo de difusion entre bins contiguos
        var smoothed = driftBins
        for i in 1..<(numBins - 1) {
            let avg = (driftBins[i - 1] + driftBins[i + 1]) * 0.5
            smoothed[i] = driftBins[i] * 0.92 + avg * 0.08
        }
        driftBins = smoothed

        // 3. Quitanieves en el manto inferior (mouseInside) con campana gaussiana
        if mouseInside, let mp = rawMousePt {
            if !isMouseDown && mp.y <= bankH + 18.0 && abs(mouseDX) > 0.8 {
                let radiusBins = max(2, Int(32.0 / binW))
                let centerBin = mouseBin
                let minB = max(0, centerBin - radiusBins)
                let maxB = min(numBins - 1, centerBin + radiusBins)
                var totalCarved: CGFloat = 0

                for b in minB...maxB {
                    let distRatio = CGFloat(abs(b - centerBin)) / CGFloat(radiusBins)
                    let bell = cos(distRatio * (.pi * 0.5))
                    let carved = min(driftBins[b] * 0.35, 2.6) * bell
                    if carved > 0.05 {
                        driftBins[b] = max(1.0, driftBins[b] - carved)
                        totalCarved += carved
                    }
                }

                let shoulderDist = radiusBins + 1
                let leftShoulder = centerBin - shoulderDist
                let rightShoulder = centerBin + shoulderDist
                let shoulderShare = (totalCarved * 0.30) * 0.5
                if leftShoulder >= 0 {
                    driftBins[leftShoulder] = min(maxH, driftBins[leftShoulder] + shoulderShare)
                }
                if rightShoulder < numBins {
                    driftBins[rightShoulder] = min(maxH, driftBins[rightShoulder] + shoulderShare)
                }

                for _ in 0..<5 {
                    let sprayVX = max(-8.0, min(8.0, mouseDX * 0.25)) + CGFloat.random(in: (-2.5)...2.5)
                    let sprayVY = CGFloat.random(in: 3.5...9.5)
                    sprayParticles.append(SnowSprayParticle(
                        x: mp.x + CGFloat.random(in: (-4.0)...4.0),
                        y: mp.y + CGFloat.random(in: 0.0...4.0),
                        vx: sprayVX,
                        vy: sprayVY,
                        radius: CGFloat.random(in: 1.5...3.2),
                        opacity: CGFloat.random(in: 0.6...0.9),
                        age: 0,
                        maxAge: Double.random(in: 0.4...0.8)
                    ))
                }
            }
        }

        // 4. Agarrar y lanzar bola de nieve
        if mouseInside, let mp = rawMousePt {
            if isMouseDown && heldSnowball == nil && mp.y <= bankH + 42.0 {
                heldSnowball = HeldSnowball(x: mp.x, y: mp.y, radius: 7.5)
                driftBins[mouseBin] = max(1.0, driftBins[mouseBin] - 2.2)
                throwVX = mouseDX
                throwVY = mouseDY
            }
        }

        if isMouseDown, let held = heldSnowball, let mp = rawMousePt {
            heldSnowball?.x = max(8.0, min(w - 8.0, mp.x))
            heldSnowball?.y = max(8.0, min(h - 8.0, mp.y))
            if mp.y <= bankH + 20.0 {
                heldSnowball?.radius = min(13.0, held.radius + 0.15)
            }
            throwVX = 0.6 * throwVX + 0.4 * mouseDX
            throwVY = 0.6 * throwVY + 0.4 * mouseDY
        }

        if !isMouseDown, let held = heldSnowball {
            let vx = max(-28.0, min(28.0, throwVX * 1.35))
            let vy = max(5.0, min(30.0, throwVY * 1.35 + 4.0))
            flyingSnowballs.append(FlyingSnowball(x: held.x, y: held.y, vx: vx, vy: vy, radius: held.radius, isFromElf: false, age: 0.0))
            heldSnowball = nil
        }
        wasMouseDown = isMouseDown

        // 5. Fisica de bolas volando (flyingSnowballs) y colisiones
        var remainingBalls: [FlyingSnowball] = []
        for var ball in flyingSnowballs {
            ball.age += dt
            ball.x += ball.vx
            ball.y += ball.vy
            ball.vy -= ball.isFromElf ? 0.32 : 0.55

            sprayParticles.append(SnowSprayParticle(
                x: ball.x + CGFloat.random(in: (-2.0)...2.0),
                y: ball.y + CGFloat.random(in: (-2.0)...2.0),
                vx: ball.vx * 0.12 + CGFloat.random(in: (-1.0)...1.0),
                vy: ball.vy * 0.12 + CGFloat.random(in: (-1.0)...1.0),
                radius: CGFloat.random(in: 1.5...2.8),
                opacity: 0.75,
                age: 0,
                maxAge: 0.35
            ))

            var didHitTarget = false

            if !ball.isFromElf {
                // Target 1: Sleigh
                if let win = window {
                    let screenPt = win.convertPoint(toScreen: NSPoint(x: ball.x, y: ball.y))
                    if ScreenEffectsManager.shared.handleSnowballImpact(atScreenPoint: screenPt) {
                        didHitTarget = true
                        explodeBall(at: NSPoint(x: ball.x, y: ball.y), count: 24)
                    }
                }

                // Target 2: SnowElves
                if !didHitTarget {
                    for eIdx in 0..<snowElves.count {
                        let elfX = snowElves[eIdx].x
                        let elfBin = min(numBins - 1, max(0, Int((elfX / max(1.0, w)) * CGFloat(numBins))))
                        let elfBankY = driftBins[elfBin]
                        if hypot(ball.x - elfX, ball.y - (elfBankY + 12.0)) < 22.0 {
                            snowElves[eIdx].behavior = .knockedDown
                            snowElves[eIdx].stateTimer = 0.0
                            snowElves[eIdx].carryingGift = false
                            explodeBall(at: NSPoint(x: ball.x, y: ball.y), count: 22)
                            didHitTarget = true
                            break
                        }
                    }
                }

                // Target 3: Snowmen
                if !didHitTarget {
                    for sIdx in (0..<snowmen.count).reversed() {
                        let smX = snowmen[sIdx].x
                        let smBin = min(numBins - 1, max(0, Int((smX / max(1.0, w)) * CGFloat(numBins))))
                        let smBankY = driftBins[smBin]
                        if hypot(ball.x - smX, ball.y - (smBankY + 14.0)) < 22.0 {
                            driftBins[smBin] = min(maxH, driftBins[smBin] + 3.0)
                            snowmen.remove(at: sIdx)
                            explodeBall(at: NSPoint(x: ball.x, y: ball.y), count: 32)
                            didHitTarget = true
                            break
                        }
                    }
                }
            } else {
                // Ball thrown by elf
                if mouseInside, let mp = rawMousePt, ball.age >= 0.15, hypot(ball.x - mp.x, ball.y - mp.y) <= 24.0 {
                    explodeBall(at: NSPoint(x: ball.x, y: ball.y), count: 22)
                    for fIdx in 0..<flakes.count {
                        let fdx = flakes[fIdx].x - mp.x
                        let fdy = flakes[fIdx].y - mp.y
                        let fdist = hypot(fdx, fdy)
                        if fdist < 60.0 {
                            flakes[fIdx].vx += (fdx / max(8.0, fdist)) * 4.0
                            flakes[fIdx].y += (fdy / max(8.0, fdist)) * 2.0
                        }
                    }
                    didHitTarget = true
                }

                if !didHitTarget && ball.age >= 0.25, let win = window {
                    let screenPt = win.convertPoint(toScreen: NSPoint(x: ball.x, y: ball.y))
                    if ScreenEffectsManager.shared.handleSnowballImpact(atScreenPoint: screenPt) {
                        didHitTarget = true
                        explodeBall(at: NSPoint(x: ball.x, y: ball.y), count: 24)
                    }
                }
            }

            if didHitTarget { continue }

            let ballBin = min(numBins - 1, max(0, Int(ball.x / binW)))
            let bankAtBall = driftBins[ballBin]
            let canHitGround = !ball.isFromElf || ball.age >= 0.35

            if ball.x < 6 || ball.x > w - 6 || ball.y > h - 6 || (canHitGround && ball.y <= bankAtBall) {
                if canHitGround && ball.y <= bankAtBall {
                    driftBins[ballBin] = min(maxH, driftBins[ballBin] + 2.2)
                }
                explodeBall(at: NSPoint(x: ball.x, y: ball.y), count: 20)
            } else {
                remainingBalls.append(ball)
            }
        }
        flyingSnowballs = remainingBalls

        // 6. Actualizacion de particulas de spray (sprayParticles)
        var remainingSpray: [SnowSprayParticle] = []
        for var p in sprayParticles {
            p.x += p.vx
            p.y += p.vy
            p.vy -= 0.42
            p.age += 1.0 / 30.0

            let pBin = min(numBins - 1, max(0, Int(p.x / binW)))
            if p.y <= driftBins[pBin] && p.vy < 0 {
                driftBins[pBin] = min(maxH, driftBins[pBin] + 0.18)
                continue
            }
            if p.age >= p.maxAge {
                continue
            }
            remainingSpray.append(p)
        }
        sprayParticles = remainingSpray

        // 7. Actualizacion de regalos posados en el manto
        var remainingGifts: [LandedGift] = []
        for var gift in landedGifts {
            gift.age += 1.0 / 30.0
            let giftBin = min(numBins - 1, max(0, Int((gift.x / max(1.0, w)) * CGFloat(numBins))))
            let giftY = driftBins[giftBin] + 6.0

            if mouseInside && heldSnowball == nil, let mp = rawMousePt, hypot(mp.x - gift.x, mp.y - giftY) < 26.0 {
                explodeBall(at: NSPoint(x: gift.x, y: giftY + 4.0), count: 16)
                continue
            }

            if gift.age < gift.maxAge {
                remainingGifts.append(gift)
            }
        }
        landedGifts = remainingGifts

        // 8. Maquina de estados de los Monitos de Nieve (Fases 6 y 7)
        let groundedSantaX = ScreenEffectsManager.shared.groundedSantaX(onWindow: window)

        for i in 0..<snowElves.count {
            snowElves[i].stateTimer += dt
            snowElves[i].animTime += dt
            snowElves[i].buildCooldown = max(0, snowElves[i].buildCooldown - dt)

            let isBusyKO: Bool
            switch snowElves[i].behavior {
            case .knockedDown, .throwingCounterBall:
                isBusyKO = true
            default:
                isBusyKO = false
            }

            let elfBin = min(numBins - 1, max(0, Int((snowElves[i].x / max(1.0, w)) * CGFloat(numBins))))
            let elfBankY = driftBins[elfBin]

            if !isBusyKO {
                // Prioridad 1: Rescate a Santa caido
                if let sx = groundedSantaX {
                    let stationX = max(30.0, min(w - 30.0, sx + (i == 0 ? -18.0 : (i == 1 ? 18.0 : -30.0))))
                    snowElves[i].behavior = .rescuingSanta
                    snowElves[i].targetX = stationX
                    let diff = stationX - snowElves[i].x
                    snowElves[i].facingRight = diff >= 0
                    if abs(diff) > 18.0 {
                        let step = min(abs(diff), 2.3)
                        snowElves[i].x += (diff > 0 ? 1.0 : -1.0) * step
                    } else {
                        snowElves[i].facingRight = sx >= snowElves[i].x
                        let minB = max(0, elfBin - 1)
                        let maxB = min(numBins - 1, elfBin + 1)
                        for b in minB...maxB {
                            if driftBins[b] > 5.0 {
                                driftBins[b] = max(5.0, driftBins[b] - 0.12)
                            }
                        }
                        if Int(snowElves[i].animTime * 30.0) % 5 == 0 {
                            sprayParticles.append(SnowSprayParticle(
                                x: snowElves[i].x + (snowElves[i].facingRight ? 8.0 : -8.0),
                                y: elfBankY + 8.0,
                                vx: (snowElves[i].facingRight ? 1.0 : -1.0) * CGFloat.random(in: 2.0...6.0),
                                vy: CGFloat.random(in: 3.5...7.5),
                                radius: 2.0,
                                opacity: 0.8,
                                age: 0,
                                maxAge: 0.4
                            ))
                        }
                        ScreenEffectsManager.shared.assistGroundedSanta(onWindow: window, amount: 0.042)
                    }
                } else if !snowElves[i].carryingGift, let (giftIdx, gift) = nearestLandedGift(forElfAt: snowElves[i].x, excludingElfIdx: i) {
                    // Prioridad 2: Recoger regalo posado
                    snowElves[i].behavior = .fetchingGift
                    snowElves[i].targetX = gift.x
                    let diff = gift.x - snowElves[i].x
                    snowElves[i].facingRight = diff >= 0
                    if abs(diff) > 14.0 {
                        let step = min(abs(diff), 1.45)
                        snowElves[i].x += (diff > 0 ? 1.0 : -1.0) * step
                    } else {
                        snowElves[i].carryingGift = true
                        if giftIdx < landedGifts.count {
                            landedGifts.remove(at: giftIdx)
                        }
                        snowElves[i].targetX = (snowElves[i].x < w * 0.5) ? 38.0 : max(38.0, w - 38.0)
                        snowElves[i].behavior = .patrolling
                        snowElves[i].stateTimer = 0.0
                    }
                }
            }

            switch snowElves[i].behavior {
            case .knockedDown:
                if snowElves[i].stateTimer >= 1.15 {
                    snowElves[i].behavior = .throwingCounterBall
                    snowElves[i].stateTimer = 0.0
                }

            case .throwingCounterBall:
                if let mp = rawMousePt {
                    snowElves[i].facingRight = mp.x >= snowElves[i].x
                }
                let prevT = snowElves[i].stateTimer - dt
                if prevT < 0.24 && snowElves[i].stateTimer >= 0.24 {
                    let elfHandX = snowElves[i].x + (snowElves[i].facingRight ? 8.0 : -8.0)
                    let elfHandY = elfBankY + 16.0
                    let vx: CGFloat
                    let vy: CGFloat
                    if let mp = rawMousePt, mp.y > 40.0 {
                        let tAir: CGFloat = 36.0
                        vx = max(-18.0, min(18.0, (mp.x - elfHandX) / tAir))
                        vy = max(8.0, min(24.0, (mp.y - elfHandY) / tAir + 0.32 * 0.5 * tAir))
                    } else {
                        vx = CGFloat.random(in: (-5.5)...5.5)
                        vy = CGFloat.random(in: 13.5...18.5)
                    }
                    flyingSnowballs.append(FlyingSnowball(
                        x: elfHandX,
                        y: elfHandY,
                        vx: vx,
                        vy: vy,
                        radius: 5.0,
                        isFromElf: true,
                        age: 0.0
                    ))
                }
                if snowElves[i].stateTimer >= 0.55 {
                    snowElves[i].behavior = .patrolling
                    snowElves[i].targetX = CGFloat.random(in: 50...max(60, w - 50))
                    snowElves[i].stateTimer = 0.0
                }

            case .patrolling:
                if groundedSantaX == nil {
                    let diff = snowElves[i].targetX - snowElves[i].x
                    snowElves[i].facingRight = diff >= 0
                    let moveSpeed: CGFloat = (currentIntensity > 0.75) ? 1.65 : 1.25
                    if abs(diff) > 10.0 {
                        let step = min(abs(diff), moveSpeed)
                        snowElves[i].x += (diff > 0 ? 1.0 : -1.0) * step
                        if currentIntensity > 0.75 && !snowElves[i].carryingGift {
                            if driftBins[elfBin] > 7.5 {
                                driftBins[elfBin] = max(5.0, driftBins[elfBin] - 0.18)
                            }
                            if Int(snowElves[i].animTime * 30.0) % 6 == 0 {
                                let plowDir: CGFloat = snowElves[i].facingRight ? 1.0 : -1.0
                                sprayParticles.append(SnowSprayParticle(
                                    x: snowElves[i].x + plowDir * 10.0,
                                    y: elfBankY + 4.0,
                                    vx: plowDir * CGFloat.random(in: 2.0...5.0),
                                    vy: CGFloat.random(in: 2.0...5.5),
                                    radius: 1.8,
                                    opacity: 0.7,
                                    age: 0,
                                    maxAge: 0.35
                                ))
                            }
                        }
                    } else {
                        if snowElves[i].carryingGift {
                            explodeBall(at: NSPoint(x: snowElves[i].x, y: elfBankY + 10.0), count: 10)
                            snowElves[i].carryingGift = false
                        }

                        var didStartSnowman = false
                        if snowmen.count < 2 && snowElves[i].buildCooldown <= 0 {
                            let leftCandidate = CGFloat.random(in: 70...min(160, max(75, w * 0.3)))
                            let rightCandidate = CGFloat.random(in: max(180, w - 160)...max(190, w - 70))
                            let candidates = [leftCandidate, rightCandidate]
                            for cX in candidates {
                                let cBin = min(numBins - 1, max(0, Int((cX / max(1.0, w)) * CGFloat(numBins))))
                                if driftBins[cBin] >= 10.5 && !snowmen.contains(where: { abs($0.x - cX) < 120.0 }) {
                                    snowElves[i].behavior = .buildingSnowman(targetX: cX)
                                    snowElves[i].stateTimer = 0.0
                                    didStartSnowman = true
                                    break
                                }
                            }
                        }

                        if !didStartSnowman {
                            if driftBins[elfBin] > 9.0 {
                                snowElves[i].behavior = .shoveling
                                snowElves[i].stateTimer = 0.0
                            } else {
                                var highestBin = 0
                                var highestH: CGFloat = 0
                                for b in 10..<(numBins - 10) {
                                    if driftBins[b] > highestH {
                                        highestH = driftBins[b]
                                        highestBin = b
                                    }
                                }
                                let nextX = (highestH > 9.0 && Bool.random()) ?
                                    (CGFloat(highestBin) / CGFloat(numBins - 1)) * w :
                                    CGFloat.random(in: 50...max(60, w - 50))
                                snowElves[i].targetX = nextX
                            }
                        }
                    }
                }

            case .shoveling:
                let minB = max(0, elfBin - 1)
                let maxB = min(numBins - 1, elfBin + 1)
                for b in minB...maxB {
                    driftBins[b] = max(5.5, driftBins[b] - 0.22)
                }
                if Int(snowElves[i].animTime * 30.0) % 4 == 0 {
                    let sprayDir: CGFloat = snowElves[i].facingRight ? -1.0 : 1.0
                    sprayParticles.append(SnowSprayParticle(
                        x: snowElves[i].x + sprayDir * 6.0,
                        y: elfBankY + 6.0,
                        vx: sprayDir * CGFloat.random(in: 2.0...5.5),
                        vy: CGFloat.random(in: 3.5...7.5),
                        radius: 2.0,
                        opacity: 0.75,
                        age: 0,
                        maxAge: 0.38
                    ))
                }
                if driftBins[elfBin] <= 6.0 || snowElves[i].stateTimer >= 1.8 {
                    snowElves[i].behavior = .patrolling
                    snowElves[i].targetX = CGFloat.random(in: 50...max(60, w - 50))
                    snowElves[i].stateTimer = 0.0
                }

            case .rescuingSanta:
                if groundedSantaX == nil {
                    snowElves[i].behavior = .patrolling
                    snowElves[i].targetX = CGFloat.random(in: 50...max(60, w - 50))
                    snowElves[i].stateTimer = 0.0
                }

            case .fetchingGift:
                if landedGifts.isEmpty && !snowElves[i].carryingGift {
                    snowElves[i].behavior = .patrolling
                    snowElves[i].targetX = CGFloat.random(in: 50...max(60, w - 50))
                    snowElves[i].stateTimer = 0.0
                }

            case .buildingSnowman(let buildX):
                let diff = buildX - snowElves[i].x
                snowElves[i].facingRight = diff >= 0
                if abs(diff) > 14.0 {
                    let step = min(abs(diff), 1.35)
                    snowElves[i].x += (diff > 0 ? 1.0 : -1.0) * step
                } else {
                    let smIdx = snowmen.firstIndex(where: { abs($0.x - buildX) < 20.0 })
                    if let idx = smIdx {
                        snowmen[idx].buildProgress += dt / 2.6
                        if snowmen[idx].buildProgress < 0.33 {
                            snowmen[idx].stage = 1
                        } else if snowmen[idx].buildProgress < 0.75 {
                            snowmen[idx].stage = 2
                        } else {
                            snowmen[idx].stage = 3
                        }
                        let smBin = min(numBins - 1, max(0, Int((buildX / max(1.0, w)) * CGFloat(numBins))))
                        if driftBins[smBin] > 4.5 {
                            driftBins[smBin] = max(4.5, driftBins[smBin] - 0.05)
                        }
                        if snowmen[idx].buildProgress >= 1.0 {
                            snowmen[idx].stage = 3
                            snowElves[i].buildCooldown = 14.0
                            snowElves[i].behavior = .patrolling
                            snowElves[i].targetX = CGFloat.random(in: 50...max(60, w - 50))
                            snowElves[i].stateTimer = 0.0
                        }
                    } else if snowmen.count < 2 {
                        snowmen.append(Snowman(x: buildX, stage: 1, buildProgress: 0.0))
                    } else {
                        snowElves[i].behavior = .patrolling
                        snowElves[i].stateTimer = 0.0
                    }
                }
            }
        }

        // 9. Copos cayendo y rafagas Blizzard
        let speedMult: CGFloat
        let windGust: CGFloat
        if currentIntensity <= 0.4 {
            speedMult = 0.70
            windGust = 0.0
        } else if currentIntensity <= 0.75 {
            speedMult = 1.05
            windGust = 0.15
        } else {
            speedMult = 2.65
            windGust = CGFloat(5.2 + 3.0 * sin(time * 1.5) + 1.5 * cos(time * 2.7))
        }

        let stepAdd: CGFloat = currentIntensity > 0.75 ? 0.35 : 0.10

        for i in 0..<flakes.count {
            let layerMult: CGFloat
            switch flakes[i].depthLayer {
            case 2: layerMult = 1.45
            case 0: layerMult = 0.70
            default: layerMult = 1.00
            }

            flakes[i].y -= flakes[i].speedY * speedMult * layerMult
            flakes[i].x += windGust + CGFloat(sin(time * flakes[i].driftSpeed + flakes[i].driftPhase)) * flakes[i].driftAmp * (currentIntensity > 0.75 ? 1.6 : 1.0)

            if mouseInside && heldSnowball == nil, let mp = rawMousePt {
                let dx = flakes[i].x - mp.x
                let dy = flakes[i].y - mp.y
                let dist = hypot(dx, dy)
                if dist < 85.0 {
                    flakes[i].vx += (dx / max(12.0, dist)) * 1.8 + max(-3.5, min(3.5, mouseDX * 0.12))
                    flakes[i].y += (dy / max(12.0, dist)) * 0.9
                }
            }

            flakes[i].x += flakes[i].vx
            flakes[i].vx *= 0.90

            let flakeBin = min(numBins - 1, max(0, Int((flakes[i].x / max(1.0, w)) * CGFloat(numBins))))
            let bankAtFlake = driftBins[flakeBin]
            if flakes[i].y <= bankAtFlake + 1.0 {
                driftBins[flakeBin] = min(maxH, driftBins[flakeBin] + stepAdd)
                if flakeBin > 0 {
                    driftBins[flakeBin - 1] = min(maxH, driftBins[flakeBin - 1] + stepAdd * 0.3)
                }
                if flakeBin < numBins - 1 {
                    driftBins[flakeBin + 1] = min(maxH, driftBins[flakeBin + 1] + stepAdd * 0.3)
                }
                flakes[i] = makeFlake(width: w, height: h, randomY: false)
            }

            if flakes[i].x < -10 { flakes[i].x = w + 5 }
            if flakes[i].x > w + 10 { flakes[i].x = -5 }
        }

        updateRenderLayers(width: w, height: h)
    }

    private func explodeBall(at pt: NSPoint, count: Int) {
        for _ in 0..<count {
            let vx = CGFloat.random(in: (-8.0)...8.0)
            let vy = CGFloat.random(in: (-3.0)...9.0)
            sprayParticles.append(SnowSprayParticle(
                x: pt.x + CGFloat.random(in: (-2.0)...2.0),
                y: pt.y + CGFloat.random(in: (-2.0)...2.0),
                vx: vx,
                vy: vy,
                radius: CGFloat.random(in: 1.8...3.8),
                opacity: CGFloat.random(in: 0.7...0.95),
                age: 0,
                maxAge: Double.random(in: 0.4...0.9)
            ))
        }
    }

    // MARK: - GPU CALayer Updates (Zero CAShapeLayers and Zero Full-Screen Buffers)

    private func updateRenderLayers(width w: CGFloat, height h: CGFloat) {
        guard let rootLayer = self.layer else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        // 1. Blizzard subtle diagonal wind streaks (pool fijo de 14 CALayers)
        if currentIntensity > 0.75 {
            for k in 0..<min(14, streakLayers.count) {
                let tOffset = (time * 220.0 + Double(k) * (Double(w) / 14.0))
                let streakX = CGFloat(tOffset.truncatingRemainder(dividingBy: Double(w + 120.0))) - 60.0
                let streakY = CGFloat((Double(k * 89) + time * 45.0).truncatingRemainder(dividingBy: Double(max(100.0, h - 90.0)))) + 40.0
                let layer = streakLayers[k]
                layer.position = CGPoint(x: streakX + 14.0, y: streakY - 11.0)
                layer.isHidden = false
            }
        } else {
            for layer in streakLayers {
                layer.isHidden = true
            }
        }

        // 2. Manto de nieve inferior acotado en una sola franja bitmap (15 FPS o cambio de estilo)
        let currentBankStyle = AppState.shared.snowbankStyle
        driftRenderTick += 1
        if driftRenderTick % 2 == 1 || driftStripLayer.contents == nil || lastRenderedSnowbankStyle != currentBankStyle {
            lastRenderedSnowbankStyle = currentBankStyle
            updateDriftStripLayer(width: w, style: currentBankStyle)
        }

        let isPixelFlakes = (AppState.shared.snowflakesStyle == .pixelArt)
        let isPixelElves = (AppState.shared.snowElvesStyle == .pixelArt)

        // 3. Falling snowflakes layer pool
        while flakeLayers.count < flakes.count {
            let l = CALayer()
            l.actions = Self.noAnimActions
            rootLayer.addSublayer(l)
            flakeLayers.append(l)
        }
        for i in 0..<flakeLayers.count {
            if i < flakes.count {
                let flake = flakes[i]
                let layer = flakeLayers[i]
                layer.isHidden = false

                let diameter: CGFloat
                let image: CGImage?
                if flake.isCrystal {
                    diameter = flake.radius * 2.5
                    image = isPixelFlakes ? Self.pixelCrystalFlakeImage : Self.crystalFlakeImage
                } else if flake.depthLayer == 2 {
                    diameter = flake.radius * 3.0
                    image = isPixelFlakes ? Self.pixelBokehFlakeImage : Self.bokehFlakeImage
                } else {
                    diameter = flake.radius * 2.0
                    image = isPixelFlakes ? Self.pixelNormalFlakeImage : Self.normalFlakeImage
                }

                layer.contents = image
                layer.magnificationFilter = isPixelFlakes ? .nearest : .linear
                layer.bounds = CGRect(x: 0, y: 0, width: diameter, height: diameter)
                if isPixelFlakes {
                    layer.position = CGPoint(
                        x: round(flake.x / 2.0) * 2.0,
                        y: round(flake.y / 2.0) * 2.0
                    )
                } else {
                    layer.position = CGPoint(x: flake.x, y: flake.y)
                }
                layer.opacity = Float(flake.opacity)
                layer.zPosition = (flake.depthLayer == 2) ? 4 : 2
            } else {
                flakeLayers[i].isHidden = true
            }
        }

        // 4. Particulas de spray layer pool
        while sprayLayers.count < sprayParticles.count {
            let l = CALayer()
            l.actions = Self.noAnimActions
            l.zPosition = 3
            rootLayer.addSublayer(l)
            sprayLayers.append(l)
        }
        for i in 0..<sprayLayers.count {
            if i < sprayParticles.count {
                let p = sprayParticles[i]
                let layer = sprayLayers[i]
                layer.isHidden = false
                layer.contents = isPixelFlakes ? Self.pixelNormalFlakeImage : Self.normalFlakeImage
                layer.magnificationFilter = isPixelFlakes ? .nearest : .linear
                let pAlpha = p.opacity * CGFloat(max(0.0, 1.0 - p.age / p.maxAge))
                let d = p.radius * 2.0
                layer.bounds = CGRect(x: 0, y: 0, width: d, height: d)
                layer.position = CGPoint(x: p.x, y: p.y)
                layer.opacity = Float(pAlpha)
            } else {
                sprayLayers[i].isHidden = true
            }
        }

        // 5. Bolas de nieve en vuelo layer pool
        while flyingBallLayers.count < flyingSnowballs.count {
            let l = CALayer()
            l.actions = Self.noAnimActions
            l.zPosition = 5
            rootLayer.addSublayer(l)
            flyingBallLayers.append(l)
        }
        for i in 0..<flyingBallLayers.count {
            if i < flyingSnowballs.count {
                let ball = flyingSnowballs[i]
                let layer = flyingBallLayers[i]
                layer.isHidden = false
                layer.contents = isPixelFlakes ? Self.pixelSnowballImage : Self.snowballImage
                layer.magnificationFilter = isPixelFlakes ? .nearest : .linear
                let d = ball.radius * 2.0
                layer.bounds = CGRect(x: 0, y: 0, width: d, height: d)
                layer.position = CGPoint(x: ball.x, y: ball.y)
                layer.opacity = 1.0
            } else {
                flyingBallLayers[i].isHidden = true
            }
        }

        // 6. Bola de nieve sostenida y arco de punteria (pool fijo de 16 CALayers)
        if let held = heldSnowball {
            heldBallLayer.isHidden = false
            heldBallLayer.contents = isPixelFlakes ? Self.pixelSnowballImage : Self.snowballImage
            heldBallLayer.magnificationFilter = isPixelFlakes ? .nearest : .linear
            let d = held.radius * 2.0
            heldBallLayer.bounds = CGRect(x: 0, y: 0, width: d, height: d)
            heldBallLayer.position = CGPoint(x: held.x, y: held.y)

            let initVX = throwVX * 1.35
            let initVY = max(5.0, throwVY * 1.35 + 4.0)
            var px = held.x
            var py = held.y
            let pvx = initVX
            var pvy = initVY

            for k in 0..<min(16, aimDotLayers.count) {
                px += pvx
                py += pvy
                pvy -= 0.55
                let layer = aimDotLayers[k]
                layer.contents = isPixelFlakes ? Self.pixelNormalFlakeImage : Self.normalFlakeImage
                layer.magnificationFilter = isPixelFlakes ? .nearest : .linear
                if py < 0 || px < 0 || px > w {
                    layer.isHidden = true
                } else {
                    layer.position = CGPoint(x: px, y: py)
                    layer.isHidden = false
                }
            }
        } else {
            heldBallLayer.isHidden = true
            for layer in aimDotLayers {
                layer.isHidden = true
            }
        }

        // 7. Regalos posados sobre el manto inferior layer pool
        while landedGiftLayers.count < landedGifts.count {
            let l = CALayer()
            l.actions = Self.noAnimActions
            l.zPosition = 4
            l.bounds = CGRect(x: 0, y: 0, width: 18, height: 18)
            l.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            rootLayer.addSublayer(l)
            landedGiftLayers.append(l)
        }

        for i in 0..<landedGiftLayers.count {
            if i < landedGifts.count {
                let gift = landedGifts[i]
                let layer = landedGiftLayers[i]
                layer.isHidden = false
                layer.contents = (gift.style == .pixelArt) ? Self.landedGiftPixelImage : Self.landedGift3DImage
                layer.magnificationFilter = (gift.style == .pixelArt) ? .nearest : .linear
                let giftBin = min(numBins - 1, max(0, Int((gift.x / max(1.0, w)) * CGFloat(numBins))))
                let giftY = driftBins[giftBin] + 6.0
                layer.position = CGPoint(x: gift.x, y: giftY)
                let fade = (gift.maxAge - gift.age) < 1.0 ? max(0.0, gift.maxAge - gift.age) : 1.0
                layer.opacity = Float(fade)
            } else {
                landedGiftLayers[i].isHidden = true
            }
        }

        // 8. Munecos de nieve layer pool
        while snowmanLayers.count < snowmen.count {
            let l = CALayer()
            l.actions = Self.noAnimActions
            l.zPosition = 3.5
            l.bounds = CGRect(x: 0, y: 0, width: 26, height: 34)
            l.anchorPoint = CGPoint(x: 0.5, y: 0.1)
            rootLayer.addSublayer(l)
            snowmanLayers.append(l)
        }

        for i in 0..<snowmanLayers.count {
            if i < snowmen.count {
                let sm = snowmen[i]
                let layer = snowmanLayers[i]
                layer.isHidden = false
                layer.contents = Self.snowmanImage(stage: sm.stage, pixelArt: isPixelElves)
                layer.magnificationFilter = isPixelElves ? .nearest : .linear
                let smBin = min(numBins - 1, max(0, Int((sm.x / max(1.0, w)) * CGFloat(numBins))))
                let smY = driftBins[smBin] - 1.0
                layer.position = CGPoint(x: sm.x, y: smY)
                layer.opacity = 1.0
            } else {
                snowmanLayers[i].isHidden = true
            }
        }

        // 9. Monitos limpiadores layer pool
        while elfLayers.count < snowElves.count {
            let l = CALayer()
            l.actions = Self.noAnimActions
            l.zPosition = 4.5
            l.bounds = CGRect(x: 0, y: 0, width: 24, height: 28)
            l.anchorPoint = CGPoint(x: 0.5, y: 0.08)
            rootLayer.addSublayer(l)
            elfLayers.append(l)
        }

        for i in 0..<elfLayers.count {
            if i < snowElves.count {
                let elf = snowElves[i]
                let layer = elfLayers[i]
                layer.isHidden = false
                let pose = poseForElf(elf)
                layer.contents = Self.elfImage(pose: pose, pixelArt: isPixelElves)
                layer.magnificationFilter = isPixelElves ? .nearest : .linear
                let elfBin = min(numBins - 1, max(0, Int((elf.x / max(1.0, w)) * CGFloat(numBins))))
                let elfY = max(2.0, driftBins[elfBin] - 2.0)
                layer.position = CGPoint(x: elf.x, y: elfY)
                layer.transform = CATransform3DMakeScale(elf.facingRight ? 1.0 : -1.0, 1.0, 1.0)
                layer.opacity = 1.0
            } else {
                elfLayers[i].isHidden = true
            }
        }

        CATransaction.commit()
    }

    // MARK: - Opcion 4 «Camaleon»: Franja Bitmap Bounded (3D Doble Capa o Pixel Art Continuo)

    private func updateDriftStripLayer(width w: CGFloat, style: IconStyle) {
        let stripH = 44
        let stripW = max(64, Int(ceil(w)))
        driftStripLayer.bounds = CGRect(x: 0, y: 0, width: w, height: CGFloat(stripH))

        guard let ctx = Self.makeContext(width: stripW, height: stripH) else { return }

        if style == .colorful {
            // Modo Color 3D: Doble Capa Esponjosa + Escarcha
            var backPts: [CGPoint] = []
            backPts.reserveCapacity(numBins)
            for i in 0..<numBins {
                let x = (CGFloat(i) / CGFloat(numBins - 1)) * CGFloat(stripW)
                let y = min(CGFloat(stripH - 2), driftBins[i] + 4.5 + 2.5 * CGFloat(sin(Double(i) * 0.18 + 1.2)))
                backPts.append(CGPoint(x: x, y: y))
            }

            // 1. Capa trasera (sombra glaciar)
            let backPath = CGMutablePath()
            backPath.move(to: CGPoint(x: 0, y: 0))
            backPath.addLine(to: backPts[0])
            for i in 0..<(numBins - 1) {
                let p0 = backPts[i]
                let p1 = backPts[i + 1]
                let mid = CGPoint(x: (p0.x + p1.x) * 0.5, y: (p0.y + p1.y) * 0.5)
                backPath.addQuadCurve(to: mid, control: p0)
            }
            backPath.addQuadCurve(to: backPts[numBins - 1], control: backPts[numBins - 2])
            backPath.addLine(to: CGPoint(x: CGFloat(stripW), y: 0))
            backPath.closeSubpath()

            if let backGrad = Self.backSnowGradient {
                ctx.saveGState()
                ctx.addPath(backPath)
                ctx.clip()
                ctx.drawLinearGradient(backGrad, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: 38), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
                ctx.restoreGState()
            }

            // 2. Capa frontal (nieve blanca cremosa)
            var frontPts: [CGPoint] = []
            frontPts.reserveCapacity(numBins)
            for i in 0..<numBins {
                let x = (CGFloat(i) / CGFloat(numBins - 1)) * CGFloat(stripW)
                let y = min(CGFloat(stripH - 4), driftBins[i])
                frontPts.append(CGPoint(x: x, y: y))
            }

            let frontPath = CGMutablePath()
            let frontRimPath = CGMutablePath()

            frontPath.move(to: CGPoint(x: 0, y: 0))
            frontPath.addLine(to: frontPts[0])
            frontRimPath.move(to: frontPts[0])

            for i in 0..<(numBins - 1) {
                let p0 = frontPts[i]
                let p1 = frontPts[i + 1]
                let mid = CGPoint(x: (p0.x + p1.x) * 0.5, y: (p0.y + p1.y) * 0.5)
                frontPath.addQuadCurve(to: mid, control: p0)
                frontRimPath.addQuadCurve(to: mid, control: p0)
            }
            frontPath.addQuadCurve(to: frontPts[numBins - 1], control: frontPts[numBins - 2])
            frontRimPath.addQuadCurve(to: frontPts[numBins - 1], control: frontPts[numBins - 2])

            frontPath.addLine(to: CGPoint(x: CGFloat(stripW), y: 0))
            frontPath.closeSubpath()

            if let frontGrad = Self.frontSnowGradient {
                ctx.saveGState()
                ctx.addPath(frontPath)
                ctx.clip()
                ctx.drawLinearGradient(frontGrad, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: 32), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
                ctx.restoreGState()
            }

            // 3. Ribete superior blanco brillante
            ctx.saveGState()
            ctx.setStrokeColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.96)
            ctx.setLineWidth(1.5)
            ctx.setLineCap(.round)
            ctx.addPath(frontRimPath)
            ctx.strokePath()
            ctx.restoreGState()

            // 4. Destellos de escarcha en la cresta
            for i in stride(from: 6, to: numBins - 6, by: 7) {
                let twinkle = sin(time * 4.0 + Double(i) * 1.7)
                if twinkle > 0.4 {
                    let x = (CGFloat(i) / CGFloat(numBins - 1)) * CGFloat(stripW)
                    let y = frontPts[i].y - 1.0
                    let r = CGFloat(twinkle - 0.4) * 3.0
                    let starPath = CGMutablePath()
                    starPath.move(to: CGPoint(x: x - r, y: y))
                    starPath.addLine(to: CGPoint(x: x + r, y: y))
                    starPath.move(to: CGPoint(x: x, y: y - r))
                    starPath.addLine(to: CGPoint(x: x, y: y + r))

                    ctx.saveGState()
                    ctx.setStrokeColor(red: 1.0, green: 1.0, blue: 1.0, alpha: CGFloat(min(1.0, (twinkle - 0.4) * 1.8)))
                    ctx.setLineWidth(1.0)
                    ctx.setLineCap(.round)
                    ctx.addPath(starPath)
                    ctx.strokePath()
                    ctx.restoreGState()
                }
            }
        } else {
            // Modo Pixel Art 8-Bit Continuo Sin Costuras
            ctx.setShouldAntialias(false)
            let stepPx: CGFloat = 4.0
            let cols = max(1, Int(ceil(CGFloat(stripW) / stepPx)))

            for c in 0..<cols {
                let px = CGFloat(c) * stepPx
                let binIdx = min(numBins - 1, Int((Double(c) / Double(cols)) * Double(numBins)))
                let snappedH = min(CGFloat(stripH - 2), max(4.0, floor(driftBins[binIdx] / stepPx) * stepPx))

                // 1) Sombra inferior celeste (0.588, 0.714, 0.820, 0.95)
                ctx.setFillColor(red: 0.588, green: 0.714, blue: 0.820, alpha: 0.95)
                ctx.fill(CGRect(x: px, y: 0, width: stepPx, height: snappedH))

                // 2) Cuerpo artico (0.878, 0.941, 0.988, 0.98)
                if snappedH > stepPx * 2 {
                    ctx.setFillColor(red: 0.878, green: 0.941, blue: 0.988, alpha: 0.98)
                    ctx.fill(CGRect(x: px, y: stepPx * 2, width: stepPx, height: snappedH - stepPx * 2))
                }

                // 3) Cresta blanca brillante (1.0, 1.0, 1.0, 1.0)
                ctx.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                ctx.fill(CGRect(x: px, y: max(0, snappedH - 3.0), width: stepPx, height: min(3.0, snappedH)))
            }
        }

        driftStripLayer.contents = ctx.makeImage()
    }
}
