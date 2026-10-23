import simd
import Foundation

/// Aluminum aerofoil blade: an extruded NACA-style sunshade section tilted down toward the outside, with
/// screw-channel grooves, riveted end caps, and three cast outrigger brackets on bolted wall plates that
/// clamp the blade root. Wall plane at z = 0, blade projects toward +Z.
public struct AluminumAerofoilBlade: RealAsset {
    public static let id = "aluminum-aerofoil-blade"
    public static let summary = "Contemporary extruded aluminum aerofoil sunshade blade 2.4 m: tilted section, end caps, wall outrigger brackets and clamp plates."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 8_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 14, distance: 2.3)

    /// Blade length, chord (m), thickness ratio and tilt (degrees, trailing edge down).
    public var length: Float = 2.4
    public var chord: Float = 0.5
    public var thickness: Float = 0.2
    public var tilt: Float = 24
    public var skin: MaterialKey = "metal.anodized:B9A27C"
    public var skinWorn: MaterialKey = "metal.anodized-worn:B09A76"
    public var steel: MaterialKey = "metal.stainless"
    public init() {}

    /// Symmetric aerofoil section (x out from the wall, y up), rotated by the tilt and offset by `root`.
    private func section(_ c: Float, _ tr: Float, _ tilt: Float, _ root: Float, _ grow: Float = 0) -> [V2] {
        let n = 18
        func yt(_ x: Float) -> Float {
            5 * tr * (0.2969 * sqrt(x) - 0.1260 * x - 0.3516 * x * x + 0.2843 * x * x * x - 0.1036 * x * x * x * x)
        }
        let a = -tilt * .pi / 180
        func rot(_ x: Float, _ y: Float) -> V2 {
            V2(root + (x * c) * cos(a) - y * c * sin(a), (x * c) * sin(a) + y * c * cos(a))
        }
        var top: [V2] = [], bot: [V2] = []
        for i in 0...n {
            let b = Float(i) / Float(n)
            let x = 0.5 * (1 - cos(b * .pi))     // cosine spacing, dense at the leading edge
            let y = yt(x) + grow
            top.append(rot(x, y))
            if i > 0 && i < n { bot.append(rot(x, -y)) }
        }
        return top + bot.reversed()
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = length, c = chord
        let root: Float = 0.045
        let prof = section(c, thickness, tilt, root)
        FA.run(&m, prof, length: L - 0.024, at: .zero, skin, bevel: 0.0012)
        // End caps: slightly larger riveted plates in the worn finish.
        for s: Float in [-1, 1] {
            m.add(Prim.extrude(section(c, thickness, tilt, root, 0.003), depth: 0.012, bevel: 0.0015, bevelSegments: 1, material: skinWorn),
                  Xform(translation: V3(s * (L / 2 - 0.006), 0, 0), rotation: FA.q(-90, FA.Y)))
            for (px, py) in [(0.12, 0.0), (0.28, 0.0), (0.44, 0.0)] as [(Float, Float)] {
                let a = -tilt * .pi / 180
                let p = V3(s * (L / 2 + 0.0005), px * c * sin(a) + py, root + px * c * cos(a))
                FA.cylX(&m, r: 0.0036, h: 0.003 * s, at: p, steel, bevel: 0.0008, segments: 8)
            }
        }
        // Screw channels: two dark grooves along the underside, and silvered streaks on the top surface.
        let a = -tilt * .pi / 180
        for px in [0.34, 0.52] as [Float] {
            let x = px
            let th = 5 * thickness * (0.2969 * sqrt(x) - 0.1260 * x - 0.3516 * x * x + 0.2843 * x * x * x - 0.1036 * x * x * x * x)
            let p = V3(0, x * c * sin(a) - th * c * cos(a), root + x * c * cos(a) + th * c * sin(a))
            FA.box(&m, V3(L - 0.06, 0.003, 0.003), p, "metal.parkerized", r: 0.0006, rot: FA.q(-tilt, FA.X))
        }
        for _ in 0..<7 {
            let x = rng.float(0.2...0.7)
            let th = 5 * thickness * (0.2969 * sqrt(x) - 0.1260 * x - 0.3516 * x * x + 0.2843 * x * x * x - 0.1036 * x * x * x * x)
            let p = V3(rng.float(-L / 2 + 0.1...L / 2 - 0.1), x * c * sin(a) + th * c * cos(a) + 0.0003, root + x * c * cos(a) - th * c * sin(a))
            FA.box(&m, V3(rng.float(0.02...0.05), 0.0006, rng.float(0.06...0.16)), p, "metal.galvanized-aged", r: 0.0002, rot: FA.q(-tilt, FA.X))
        }
        // Outrigger brackets: wall plate, bolted, with a gusseted arm into a clamp saddle under the blade root.
        for x in [-L / 2 + 0.14, 0, L / 2 - 0.14] as [Float] {
            let yc: Float = 0.0
            FA.box(&m, V3(0.11, 0.2, 0.012), V3(x, yc, 0.006), "metal.anodized-black", r: 0.002)
            for (bx, by) in [(-0.035, 0.075), (0.035, 0.075), (-0.035, -0.075), (0.035, -0.075)] as [(Float, Float)] {
                FA.cylZ(&m, r: 0.0085, h: 0.006, at: V3(x + bx, yc + by, 0.011), steel, bevel: 0.0012, segments: 6)
            }
            FA.box(&m, V3(0.034, 0.05, 0.062), V3(x, yc - 0.01, 0.043), "metal.anodized-black", r: 0.004)
            // Clamp strap over the blade top with two cap screws.
            let tx: Float = 0.30
            let th = 5 * thickness * (0.2969 * sqrt(tx) - 0.1260 * tx - 0.3516 * tx * tx + 0.2843 * tx * tx * tx - 0.1036 * tx * tx * tx * tx)
            let sp = V3(x, tx * c * sin(a) + th * c * cos(a) + 0.002, root + tx * c * cos(a) - th * c * sin(a))
            FA.box(&m, V3(0.05, 0.004, 0.14), sp, "metal.anodized-black", r: 0.001, rot: FA.q(-tilt, FA.X))
            for e in [-1, 1] as [Float] {
                FC.bead(&m, r: 0.0065, at: sp + V3(0, 0.003, e * 0.04 * cos(a)), steel, sub: 3)
            }
            FA.box(&m, V3(0.008, 0.07, 0.07), V3(x - 0.02, yc - 0.0, 0.05), "metal.anodized-black", r: 0.003)
            FA.box(&m, V3(0.008, 0.07, 0.07), V3(x + 0.02, yc - 0.0, 0.05), "metal.anodized-black", r: 0.003)
            // Clamp pin through the blade root.
            FA.cylX(&m, r: 0.0065, h: 0.052, at: V3(x - 0.026, yc, 0.06), steel, bevel: 0.001, segments: 10)
        }
        _ = rng.float()
        groundAO(&m, height: 0.1, floor: 0.85)
        return LODModel(FC.place(m))
    }
}
