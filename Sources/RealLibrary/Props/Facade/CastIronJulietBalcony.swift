import simd
import Foundation

/// French Colonial cast-iron Juliet balcony: moulded top rail swept along a bowed plan, turned cast
/// balusters, cast rosette medallions, fleur-de-lis finials on the end posts, bolted wall plates.
/// Wall plane at z = 0.
public struct CastIronJulietBalcony: RealAsset {
    public static let id = "cast-iron-juliet-balcony"
    public static let summary = "Cast-iron Juliet balcony rail, 1.4 m: bowed panel with cast scroll medallions, balusters, fleur-de-lis finials, wall plates."
    public static let tags = ["prop", "architecture", "facade", "trim", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 10, distance: 2.2)

    /// Overall width between post axes plus post, meters.
    public var width: Float = 1.4
    public var height: Float = 1.02
    /// Bow of the panel off the wall plane, meters.
    public var bow: Float = 0.26
    public var iron: MaterialKey = "metal.cast-iron"
    public var ironWorn: MaterialKey = "metal.cast-iron-worn"
    public var rust: MaterialKey = "metal.rust"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let H = height, hw: Float = width / 2 - 0.06, B = bow
        /// Plan curve: ends sit on the wall, the middle bows out, flat-ish across the front.
        func bz(_ x: Float) -> Float {
            let u = min(1, abs(x) / hw)
            return 0.035 + (B - 0.035) * (1 - powf(u, 3))
        }
        func slopeDeg(_ x: Float) -> Float { atan2(bz(x + 0.01) - bz(x - 0.01), 0.02) * 180 / .pi }
        let xs: [Float] = (0...24).map { -hw + Float($0) / 24 * 2 * hw }
        // Moulded top rail: flat cap with rolled edges, profile x = up, y = across.
        let railProfile = Shape2D.rounded([V2(-0.018, -0.03), V2(0.018, -0.03), V2(0.018, 0.03), V2(-0.018, 0.03)], radius: 0.012, segments: 3)
        m.add(Prim.sweep(railProfile, along: xs.map { V3($0, H - 0.02, bz($0)) }, up: FA.Y, material: ironWorn))
        // Under-rail bead below the cap.
        FA.path(&m, xs.map { V3($0, H - 0.058, bz($0)) }, r: 0.009, iron, sides: 8)
        // Bottom rail, mid rail and a lower scroll rail.
        let botProfile = Shape2D.rounded([V2(-0.025, -0.02), V2(0.025, -0.02), V2(0.025, 0.02), V2(-0.025, 0.02)], radius: 0.008, segments: 2)
        m.add(Prim.sweep(botProfile, along: xs.map { V3($0, 0.075, bz($0)) }, up: FA.Y, material: iron))
        FA.path(&m, xs.map { V3($0, H * 0.6, bz($0)) }, r: 0.0065, iron, sides: 8)
        // Rust bloom where water sits on the bottom rail near one end.
        FA.box(&m, V3(0.16, 0.012, 0.045), V3(-hw + 0.2, 0.097, bz(-hw + 0.2)), rust, r: 0.003)
        // Turned cast balusters between the rails: collar feet, vase swell, collar heads, two tiers.
        func baluster(_ len: Float) -> [V2] {
            var pts: [V2] = [V2(0, 0), V2(0.012, 0), V2(0.012, 0.014), V2(0.008, 0.02)]
            for k in 0...4 {
                let t = Float(k) / 4
                pts.append(V2(0.008 + 0.0062 * powf(sinf(t * .pi), 2), 0.02 + (len - 0.04) * t))
            }
            pts += [V2(0.008, len - 0.02), V2(0.012, len - 0.014), V2(0.012, len), V2(0, len)]
            return pts
        }
        let tiers: [(Float, Float)] = [(0.095, 0.66 - 0.095 - 0.006), (0.666, H - 0.058 - 0.666 - 0.006)]
        let pitch: Float = 0.125
        let count = Int((2 * hw - 0.16) / pitch)
        for i in 0...count {
            let x = -Float(count) * pitch / 2 + Float(i) * pitch
            let z = bz(x)
            for (y0, len) in tiers {
                m.add(Prim.lathe(baluster(len), segments: 7, seamTile: 0.05, material: iron),
                      Xform(translation: V3(x, y0, z)).jittered(&rng))
            }
        }
        // Cast medallions in alternate bays: ring, eight-petal rosette, bolt-through boss.
        for i in 0..<count {
            guard i % 2 == 0 else { continue }
            let x = -Float(count) * pitch / 2 + (Float(i) + 0.5) * pitch
            let z = bz(x), sl = slopeDeg(x)
            var med = Model(name: "med")
            med.add(Prim.torus(major: 0.047, minor: 0.007, segments: 20, sides: 6, material: iron),
                    Xform(rotation: FA.q(90, FA.X)))
            m.add(Prim.lathe([V2(0, 0), V2(0.03, 0), V2(0.03, 0.004), V2(0.012, 0.01), V2(0.011, 0.016), V2(0.006, 0.02), V2(0, 0.021)],
                             segments: 16, seamTile: 0.05, material: ironWorn), Xform(translation: V3(0, 0, -0.004), rotation: FA.q(90, FA.X)))
            for k in 0..<4 {
                let a = Float(k) / 4 * 2 * .pi + .pi / 4
                m.add(Prim.extrude(Shape2D.circle(0.016, ry: 0.007, segments: 6), depth: 0.006, bevel: 0.0015, bevelSegments: 1, material: iron),
                      Xform(translation: V3(cos(a) * 0.027, sin(a) * 0.027, 0.0), rotation: FA.q(a * 180 / .pi, FA.Z)))
            }
            m.add(med.transformed(Xform(translation: V3(x, H * 0.4 + 0.03, z + 0.012), rotation: FA.q(-sl, FA.Y))))
        }
        // Cast scroll spandrels: opposed C-scrolls in every bay above the mid rail, bolted to the balusters.
        for i in 0..<count {
            let xm = -Float(count) * pitch / 2 + (Float(i) + 0.5) * pitch
            for sgn: Float in [-1, 1] {
                var pts: [V3] = []
                for k in 0...9 {
                    let t = Float(k) / 9, a = t * 1.9 * .pi, r = 0.026 * (1 - t * 0.7)
                    let lx = sgn * 0.026 + (-sgn) * r * cosf(a) * (-1)
                    let x = xm + lx
                    pts.append(V3(x, H * 0.83 + r * sinf(a), bz(x) + 0.012))
                }
                FA.path(&m, pts, r: 0.0035, iron, sides: 5)
            }
        }
        // Cast base shoes under the posts and rail ends.
        // End posts: turned shaft, collars, urn, fleur-de-lis finial.
        let post: [V2] = [V2(0, 0), V2(0.026, 0), V2(0.026, 0.02), V2(0.019, 0.03), V2(0.017, 0.05), V2(0.017, H - 0.2), V2(0.024, H - 0.19),
                          V2(0.024, H - 0.17), V2(0.017, H - 0.16), V2(0.028, H - 0.12), V2(0.03, H - 0.09), V2(0.02, H - 0.05),
                          V2(0.012, H - 0.04), V2(0.012, H - 0.03), V2(0, H - 0.03)]
        for e: Float in [-1, 1] {
            let px = e * (width / 2 - 0.04)
            FA.box(&m, V3(0.075, 0.03, 0.075), V3(px, 0.015, 0.04), ironWorn, r: 0.005)
            m.add(Prim.lathe(post, segments: 16, seamTile: 0.05, material: iron), Xform(translation: V3(px, 0, 0.04)))
            // Fleur-de-lis: centre petal, two curled side petals, binding band.
            let c = V3(px, H - 0.01, 0.04)
            m.add(Prim.superellipsoid(V3(0.016, 0.07, 0.014), exponent: 2, subdivisions: 3, material: iron), Xform(translation: c + V3(0, 0.03, 0)))
            for s: Float in [-1, 1] {
                m.add(Prim.superellipsoid(V3(0.014, 0.05, 0.012), exponent: 2, subdivisions: 3, material: iron),
                      Xform(translation: c + V3(s * 0.017, 0.012, 0), rotation: FA.q(-s * 38, FA.Z)))
            }
            FA.cylX(&m, r: 0.009, h: 0.02, at: c + V3(-0.01, -0.002, 0), ironWorn, bevel: 0.0015, segments: 10)
            // Wall plate with four bolts.
            FA.box(&m, V3(0.08, 0.26, 0.014), V3(px, 0.4, 0.007), iron, r: 0.003)
            FA.box(&m, V3(0.08, 0.26, 0.014), V3(px, H - 0.3, 0.007), iron, r: 0.003)
            for y in [0.3, 0.5, H - 0.4, H - 0.2] as [Float] {
                hexBolt(&m, at: V3(px + (y.truncatingRemainder(dividingBy: 0.4) > 0.2 ? 0.026 : -0.026), y, 0.014), normal: FA.Z, size: 0.016, material: rust)
            }
            // Stand-off arm from plate to post.
            FA.rod(&m, V3(px, 0.4, 0.014), V3(px, 0.4, 0.04), r: 0.012, ironWorn, sides: 8)
        }
        groundAO(&m, height: 0.12, floor: 0.75)
        return LODModel(FC.place(m))
    }
}
