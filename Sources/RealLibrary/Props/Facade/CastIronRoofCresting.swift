import simd
import Foundation

/// Second Empire cast iron roof cresting, 2.4 x 0.5 x 0.08 m: six 0.4 m panels between seven cast standards on bolted shoes,
/// each panel a pierced circle with a fleur-de-lis, C-scrolls and tie bars, joined by a bottom rail and a beaded top rail.
/// Gilt spear finials top the standards and gilt urns the corner standards. Black paint flakes to bare iron and rust on the
/// shoes and rails. Sits on y = 0 (the ridge).
public struct CastIronRoofCresting: RealAsset {
    public static let id = "cast-iron-roof-cresting"
    public static let summary = "Second Empire cast iron roof cresting, 2.4 m run: base rail, pierced scroll panels, fleur-de-lis, spear finials, corner urns, bolted joints."
    public static let tags = ["prop", "architecture", "facade", "roof", "metal", "ornament"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 8, distance: 2.0)

    /// Run length in meters.
    public var length: Float = 2.4
    /// Black painted cast iron.
    public var paint: MaterialKey = "metal.painted:20262A"
    /// Bare cast iron where the paint has flaked.
    public var bare: MaterialKey = "metal.cast-iron"
    public var rust: MaterialKey = "metal.rust"
    public var gilt: MaterialKey = "metal.gold-leaf"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = length, n = 6, x0 = -L / 2 + 0.048, pitch = (L - 0.096) / 6
        let railY: Float = 0.085, topY: Float = 0.34

        func spiral(_ cx: Float, _ cy: Float, r0: Float, r1: Float, a0: Float, turn: Float, flip: Float, wire: Float, steps: Int = 9) {
            var pts: [V3] = []
            for k in 0...steps {
                let t = Float(k) / Float(steps)
                let a = a0 + flip * t * turn
                let r = r0 + (r1 - r0) * t
                pts.append(V3(cx + r * cos(a), cy + r * sin(a), 0))
            }
            m.add(Prim.tube(pts, radii: Array(repeating: wire, count: pts.count), sides: 5, seamTile: 0.1, material: paint, capEnd: true))
        }

        // Rails.
        FA.box(&m, V3(L - 0.09, 0.03, 0.02), V3(0, railY, 0), paint, r: 0.004)
        FA.rod(&m, V3(x0, topY, 0), V3(-x0, topY, 0), r: 0.0085, paint, sides: 8)

        // Standards: cast shoe on two bolts, round shaft with collar, then a spear or an urn.
        let shoe: [V2] = [V2(-0.048, 0), V2(0.048, 0), V2(0.036, 0.052), V2(-0.036, 0.052)]
        for i in 0...n {
            let x = x0 + Float(i) * pitch
            let corner = i == 0 || i == n
            m.add(Prim.extrude(shoe, depth: 0.064, bevel: 0.004, bevelSegments: 1, material: i % 3 == 1 ? bare : paint), Xform(translation: V3(x, 0, 0)))
            hexBolt(&m, at: V3(x, 0.026, 0.032), normal: V3(0, 0, 1), size: 0.012, material: rust)
            for s: Float in [-1] {
                rivet(&m, at: V3(x, 0.026, s * 0.032), normal: V3(0, 0, s), radius: 0.008, segments: 6, material: rust)
            }
            let r: Float = corner ? 0.014 : 0.0105
            FA.rod(&m, V3(x, 0.05, 0), V3(x, topY + 0.02, 0), r: r, paint, sides: 8)
            m.add(Prim.torus(major: r + 0.003, minor: 0.004, segments: 12, sides: 5, material: paint), Xform(translation: V3(x, topY - 0.03, 0)))
            m.add(Prim.torus(major: r + 0.003, minor: 0.004, segments: 12, sides: 5, material: paint), Xform(translation: V3(x, railY, 0)))
            for s: Float in [-1, 1] { rivet(&m, at: V3(x, railY, s * (r + 0.001)), normal: V3(0, 0, s), radius: 0.006, segments: 6, material: rust) }
            if corner {
                m.add(Prim.lathe([V2(0, 0), V2(0.03, 0), V2(0.03, 0.01), V2(0.018, 0.02), V2(0.016, 0.034), V2(0.034, 0.06), V2(0.04, 0.08), V2(0.03, 0.108), V2(0.012, 0.124), V2(0, 0.14)],
                                 segments: 14, seamTile: 0.1, material: gilt), Xform(translation: V3(x, topY + 0.02, 0)))
                m.add(Prim.torus(major: 0.032, minor: 0.005, segments: 14, sides: 5, material: paint), Xform(translation: V3(x, topY + 0.02, 0)))
            } else {
                // Spear: cast leaf with a gilt point, collar and gilt ball.
                let leaf: [V2] = [V2(0, 0), V2(0.012, 0.02), V2(0.024, 0.05), V2(0.012, 0.085), V2(0, 0.12), V2(-0.012, 0.085), V2(-0.024, 0.05), V2(-0.012, 0.02)]
                m.add(Prim.extrude(leaf, depth: 0.014, bevel: 0.0018, bevelSegments: 1, material: paint), Xform(translation: V3(x, topY + 0.02, 0)))
                let tip: [V2] = [V2(0, 0.082), V2(0.0105, 0.07), V2(0.0085, 0.09), V2(0, 0.12)]
                m.add(Prim.extrude([V2(0, 0.118), V2(0.0115, 0.088), V2(0.0, 0.074), V2(-0.0115, 0.088)], depth: 0.0165, bevel: 0.0012, bevelSegments: 1, material: gilt),
                      Xform(translation: V3(x, topY + 0.02, 0)))
                _ = tip
                FC.bead(&m, r: 0.011, at: V3(x, topY + 0.018, 0), gilt, sub: 3)
            }
        }

        // Panels: pierced circle with fleur-de-lis, flanking C-scrolls, tie bars to the standards.
        for i in 0..<n {
            let cx = x0 + (Float(i) + 0.5) * pitch
            let cy: Float = 0.215
            m.add(Prim.torus(major: 0.075, minor: 0.0065, segments: 16, sides: 5, material: paint), Xform(translation: V3(cx, cy, 0), rotation: FA.q(90, FA.X)))
            FA.rod(&m, V3(cx, railY, 0), V3(cx, cy + 0.06, 0), r: 0.0055, paint, sides: 6)
            let petal: [V2] = [V2(0, 0), V2(0.016, 0.02), V2(0.02, 0.045), V2(0.008, 0.07), V2(0, 0.085), V2(-0.008, 0.07), V2(-0.02, 0.045), V2(-0.016, 0.02)]
            m.add(Prim.extrude(petal, depth: 0.012, bevel: 0.0015, bevelSegments: 1, material: paint), Xform(translation: V3(cx, cy - 0.01, 0)))
            for s: Float in [-1, 1] {
                spiral(cx + s * 0.034, cy + 0.005, r0: 0.03, r1: 0.011, a0: s > 0 ? Float.pi * 1.1 : -Float.pi * 0.1, turn: 1.45 * .pi, flip: s > 0 ? -1 : 1, wire: 0.0042)
                // Tie bar from the ring to the standard, with a bead.
                FA.rod(&m, V3(cx + s * 0.075, cy, 0), V3(cx + s * (pitch / 2 - 0.008), cy, 0), r: 0.0048, paint, sides: 6)
                FC.bead(&m, r: 0.0085, at: V3(cx + s * 0.135, cy, 0), paint, sub: 2)
                // Bottom C-scroll climbing from the rail.
                spiral(cx + s * 0.15, railY + 0.075, r0: 0.04, r1: 0.012, a0: s > 0 ? -Float.pi * 0.5 : Float.pi * 1.5, turn: 1.5 * .pi, flip: s > 0 ? 1 : -1, wire: 0.0045)
                // Top C-scroll hanging from the top rail.
                spiral(cx + s * 0.12, topY - 0.055, r0: 0.04, r1: 0.012, a0: s > 0 ? Float.pi * 0.5 : Float.pi * 0.5, turn: 1.4 * .pi, flip: s > 0 ? 1 : -1, wire: 0.0042)
            }
            // Panel bolts through the rail.
            for s: Float in [-1, 1] { rivet(&m, at: V3(cx + s * 0.1, railY, 0.0105), normal: FA.Z, radius: 0.0055, segments: 6, material: rust) }
        }

        // Wear: rust bloom on the shoes and rail, flaked paint exposing bare iron on the rail and shafts.
        for _ in 0..<26 {
            let onShoe = rng.chance(0.5)
            let x = onShoe ? x0 + Float(rng.int(0...n)) * pitch + rng.float(-0.02...0.02) : rng.float(x0...(-x0))
            let s: Float = rng.chance(0.5) ? 1 : -1
            if onShoe {
                FO8.slab(&m, rng.float(0.012...0.026), rng.float(0.01...0.022), 0.002, V3(x, rng.float(0.012...0.04), s * 0.0335), rust, bevel: 0.0005)
            } else {
                FO8.slab(&m, rng.float(0.015...0.05), rng.float(0.006...0.022), 0.002, V3(x, railY + rng.float(-0.005...0.005), s * 0.0115), rng.chance(0.5) ? bare : rust, bevel: 0.0005)
            }
        }

        groundAO(&m, height: 0.06, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
