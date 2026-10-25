import simd
import Foundation

/// Box gutter hopper head: architectural facade customizer, Victorian, cast lead hopper head. Parts: flared hopper box, embossed front panel, dated rib band, overflow slot, downspout outlet, wall brackets, rivet seams, gutter spigot.
public struct BoxGutterHopperHead: RealAsset {
    public static let id = "box-gutter-hopper-head"
    public static let summary = "Victorian box gutter hopper head, 0.4 x 0.3 x 0.4 m: flared riveted sheet-metal box with embossed panel and outlet."
    public static let tags = ["prop", "architecture", "facade", "metal", "trim"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.4, 0.3, 0.4)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.galvanized-aged metal.brass-aged metal.rust-grime metal.screw-zinc stone.limestone-sooted. Gate: realityhd gate box-gutter-hopper-head. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        let gal: MaterialKey = "metal.galvanized-aged", brass: MaterialKey = "metal.brass-aged"
        let rust: MaterialKey = "metal.rust-grime", zinc: MaterialKey = "metal.screw-zinc"
        let th: Float = 0.004, tilt: Float = 36.87
        func fp(_ t: Float, _ off: Float = 0) -> V3 {   // point on the sloped front plate, offset along its normal
            V3(0, 0.3 - 0.2 * t + 0.6 * off, 0.2 - 0.15 * t + 0.8 * off)
        }
        let fq = FA.q(tilt, FA.X)
        // Back plate, side plates, sloped front, floor.
        FA.box(&m, V3(0.4, 0.2, th), V3(0, 0.2, -0.198), gal, r: 0.001)
        for s: Float in [-1, 1] {
            let pts: [V2] = [V2(-0.2, 0.1), V2(0.05, 0.1), V2(0.2, 0.3), V2(-0.2, 0.3)]
            m.add(Prim.extrude(pts, depth: th, bevel: 0.001, bevelSegments: 1, material: gal),
                  Xform(translation: V3(s * 0.198 - th / 2, 0, 0), rotation: FA.q(-90, FA.Y) * FA.q(0, FA.X)).jittered(&rng))
        }
        FA.box(&m, V3(0.396, 0.25, th), fp(0.5), gal, r: 0.001, rot: fq)
        FA.box(&m, V3(0.396, th, 0.25), V3(0, 0.098, -0.075), gal, r: 0.001)
        // Rolled top rim with folded corners.
        FA.box(&m, V3(0.4, 0.012, 0.012), V3(0, 0.302, 0.2), gal, r: 0.004)
        FA.box(&m, V3(0.4, 0.012, 0.012), V3(0, 0.302, -0.2), gal, r: 0.004)
        for s: Float in [-1, 1] {
            FA.box(&m, V3(0.012, 0.012, 0.4), V3(s * 0.2, 0.302, 0), gal, r: 0.004)
        }
        // Embossed front panel: frame, rosette and dated rib band.
        FA.box(&m, V3(0.28, 0.012, 0.004), fp(0.18, 0.004), brass, r: 0.001, rot: fq)
        FA.box(&m, V3(0.28, 0.012, 0.004), fp(0.82, 0.004), brass, r: 0.001, rot: fq)
        for s: Float in [-1, 1] {
            FA.box(&m, V3(0.012, 0.15, 0.004), V3(s * 0.14, fp(0.5).y + 0.6 * 0.004, fp(0.5).z + 0.8 * 0.004), brass, r: 0.001, rot: fq)
            FA.box(&m, V3(0.008, 0.2, 0.004), V3(s * 0.185, fp(0.5).y + 0.6 * 0.003, fp(0.5).z + 0.8 * 0.003), gal, r: 0.001, rot: fq)
        }
        m.add(Prim.cylinder(radius: 0.035, height: 0.006, bevel: 0.0015, segments: 24, bevelSegments: 2, material: brass),
              Xform(translation: fp(0.5, 0.004), rotation: fq * FA.q(90, FA.X)))
        m.add(Prim.cylinder(radius: 0.015, height: 0.008, bevel: 0.002, segments: 16, bevelSegments: 2, material: gal),
              Xform(translation: fp(0.5, 0.007), rotation: fq * FA.q(90, FA.X)))
        // Rivet rows along the plate seams.
        for s: Float in [-1, 1] {
            for i in 0..<9 {
                let t = 0.08 + Float(i) * 0.105
                m.add(Prim.cylinder(radius: 0.0032, height: 0.003, bevel: 0.0008, segments: 8, bevelSegments: 1, material: i == 4 && s > 0 ? rust : zinc),
                      Xform(translation: fp(t, 0.002) + V3(s * 0.19, 0, 0), rotation: fq * FA.q(90, FA.X)))
            }
        }
        // Overflow slot on the right side plate.
        FA.box(&m, V3(0.006, 0.02, 0.12), V3(0.2, 0.25, -0.03), rust, r: 0.002)
        // Downspout outlet with brass collar, strap and drip stain.
        m.add(Prim.cylinder(radius: 0.045, height: 0.1, bevel: 0.002, segments: 24, bevelSegments: 1, material: gal),
              Xform(translation: V3(0, 0.05, -0.075)))
        for y: Float in [0.082, 0.02] {
            m.add(Prim.cylinder(radius: 0.05, height: 0.01, bevel: 0.002, segments: 24, bevelSegments: 2, material: brass),
                  Xform(translation: V3(0, y, -0.075)))
        }
        FA.box(&m, V3(0.04, 0.09, 0.0015), fp(0.86, 0.0045), rust, r: 0.0005, rot: fq)
        // Wall brackets.
        for s: Float in [-1, 1] {
            FA.box(&m, V3(0.03, 0.14, 0.012), V3(s * 0.14, 0.2, -0.212), "metal.galvanized-aged", r: 0.003)
            FA.box(&m, V3(0.03, 0.012, 0.05), V3(s * 0.14, 0.126, -0.19), "metal.galvanized-aged", r: 0.003)
            for y: Float in [0.15, 0.25] {
                m.add(Prim.cylinder(radius: 0.005, height: 0.004, bevel: 0.001, segments: 8, bevelSegments: 1, material: zinc),
                      Xform(translation: V3(s * 0.14, y, -0.219), rotation: FA.q(90, FA.X)))
            }
        }
        // Soot run on the back and a worn patch.
        FA.box(&m, V3(0.1, 0.1, 0.002), V3(0.08, 0.2, -0.2), "stone.limestone-sooted", r: 0.0005)
        let bb0 = m.bounds
        m = m.transformed(Xform(translation: V3(0, -bb0.min.y, 0)))
        groundAO(&m)
        return LODModel(m)
    }
}
