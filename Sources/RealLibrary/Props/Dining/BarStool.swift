import simd
import Foundation

/// Counter stool, 42 x 78 x 42 cm with the seat at 66 cm: a round padded leather seat with piping and a
/// stitched top, a steel seat pan and cross brace, four splayed tubular legs, a welded footrest ring, a low
/// curved back band on two posts and rubber glides.
public struct BarStool: RealAsset {
    public static let id = "bar-stool"
    public static let summary = "Counter stool, seat 66 cm: padded round seat, four splayed steel legs, footrest ring, low curved back."
    public static let tags = ["prop", "floorplan", "dining", "furniture", "metal", "leather", "interior"]
    public static let budget = 4300
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 14, distance: 1.0, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.42, 0.78, 0.42)
    /// Seat height in meters.
    public var seatHeight: Float = 0.66
    /// Frame steel.
    public var steel: MaterialKey = "metal.enamel:202124"
    /// Seat and back leather.
    public var leather: MaterialKey = "leather.tan"
    /// Bright hardware.
    public var chrome: MaterialKey = "metal.stainless-smudged"
    /// Glide rubber.
    public var rubber: MaterialKey = "plastic.black"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [4])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let seatH = seatHeight, padT: Float = 0.055, padR: Float = 0.185
        let legTube: Float = 0.0125, rBot: Float = size.x / 2 - legTube, rTop: Float = 0.135, yTop = seatH - padT - 0.012
        let seg = detail ? 14 : 8
        // Padded seat: rounded-rim cylinder (planar top UVs).
        m.add(Prim.cylinder(radius: padR, height: padT, bevel: 0.017, segments: detail ? 36 : 20, bevelSegments: 3, material: leather),
              Xform(translation: V3(0, seatH - padT, 0)))
        if detail {
            // Centre button with a pleat ring.
            m.add(Prim.superellipsoid(V3(0.026, 0.012, 0.026), exponent: 2.2, subdivisions: 3, material: leather), Xform(translation: V3(0, seatH - 0.0005, 0)))
            for k in 0..<8 {
                let a = Float(k) / 8 * 2 * .pi
                m.add(Prim.tube([V3(cos(a) * 0.012, seatH + 0.0005, sin(a) * 0.012), V3(cos(a) * 0.07, seatH + 0.0005, sin(a) * 0.07)],
                                radii: [0.0022, 0.0022], sides: 3, seamTile: 0.01, material: leather, capEnd: false))
            }
            // Seat piping and top stitching.
            let ringPts = (0..<40).map { k -> V3 in let a = Float(k) / 40 * 2 * .pi; return V3(cos(a) * (padR - 0.004), seatH - 0.014, sin(a) * (padR - 0.004)) }
            m.add(Prim.sweep(Shape2D.circle(0.0035, segments: 5), along: ringPts, closedPath: true, caps: false, material: leather))
            let st = (0...48).map { k -> V3 in let a = Float(k) / 48 * 2 * .pi; return V3(cos(a) * (padR - 0.025), seatH + 0.0005 + 0.002, sin(a) * (padR - 0.025)) }
            m.add(stitches(along: st, normal: { _ in .up }, pitch: 0.012, thread: 0.0008, material: leather))
        }
        // Seat pan, hub and cross brace.
        m.add(Prim.cylinder(radius: padR - 0.012, height: 0.012, bevel: 0.002, segments: seg + 10, bevelSegments: 1, material: steel),
              Xform(translation: V3(0, seatH - padT - 0.012, 0)))
        for a in [0, Float.pi / 2] {
            let d = V3(cos(a), 0, sin(a))
            m.add(Prim.sweep(Shape2D.circle(0.007, segments: 6), along: [d * -rTop, d * rTop].map { $0 + V3(0, yTop + 0.003, 0) }, caps: true, material: steel))
        }
        // Four splayed legs on the axes.
        for k in 0..<4 {
            let a = Float(k) * .pi / 2
            let d = V3(cos(a), 0, sin(a))
            let top = d * rTop + V3(0, yTop, 0), bot = d * rBot
            m.add(Prim.tube([bot + V3(0, 0.008, 0), top], radii: [legTube, legTube * 0.92], sides: seg, seamTile: 0.1, material: steel, capEnd: true))
            m.add(Prim.cylinder(radius: 0.016, height: 0.01, bevel: 0.002, segments: 10, bevelSegments: 1, material: rubber), Xform(translation: bot))
            if detail {
                // Weld bead where the leg meets the pan.
                m.add(Prim.superellipsoid(V3(0.034, 0.012, 0.034), exponent: 2.4, subdivisions: 2, material: chrome), Xform(translation: top - V3(0, 0.002, 0) - d * 0.003))
            }
        }
        // Footrest ring through the legs.
        let fy: Float = 0.24
        let fr = rBot + (rTop - rBot) * ((fy - 0.008) / (yTop - 0.008))
        let ring = (0..<(detail ? 40 : 24)).map { k -> V3 in let a = Float(k) / Float(detail ? 40 : 24) * 2 * .pi; return V3(cos(a) * fr, fy, sin(a) * fr) }
        m.add(Prim.sweep(Shape2D.circle(0.0095, segments: 8), along: ring, closedPath: true, caps: false, material: chrome))
        // Low curved back: two posts and a padded band behind the sitter (-Z).
        let bandY = seatH + 0.085, bandR: Float = 0.175
        let arcPts = (0...16).map { k -> V3 in
            let a = Float.pi * (1.0 + (-60.0 + 120.0 * Float(k) / 16) / 180.0 + 0.5) - Float.pi * 0.5 * 0 // centred on -Z
            _ = a
            let ang = (-30.0 + (60.0 * Double(k) / 16)) * Double.pi / 180
            let sinA = Float(sin(ang)), cosA = Float(cos(ang))
            return V3(sinA * bandR * 1.7, bandY, -cosA * bandR)
        }
        m.add(Prim.sweep(Shape2D.roundedRect(0.075, 0.022, radius: 0.009, segments: 3), along: arcPts, up: V3(0, 1, 0), caps: true, material: leather))
        for s: Float in [-1, 1] {
            let x = s * 0.105, zp = -sqrt(max(0, padR * padR - x * x)) * 0.9
            m.add(Prim.tube([V3(x, seatH - padT, zp), V3(x * 1.05, bandY - 0.03, zp - 0.0), V3(x * 1.08, bandY, -bandR * 0.93)],
                            radii: [0.0075, 0.0075, 0.0075], sides: 8, seamTile: 0.1, material: steel, capEnd: true))
        }
        groundAO(&m, height: 0.12, floor: 0.5)
        _ = rng.float()
        return m
    }
}
