import simd
import Foundation

/// Hanging basket bracket, Victorian: cast iron wall plate with acorn finial and coach screws, 14 x 28 mm arm,
/// concave diagonal strut, two C-scroll volutes and a curled arm terminal, S-hook and three galvanised hangers to a
/// 360 mm wire basket (meridian ribs, five hoops, rolled rim) lined with coir, planted with pelargoniums and ivy.
public struct HangingBasketBracket: RealAsset {
    public static let id = "hanging-basket-bracket"
    public static let summary = "Victorian cast iron scroll bracket with a coir-lined wire hanging basket of pelargoniums and trailing ivy."
    public static let tags = ["prop", "architecture", "facade", "metal", "decor"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 12, distance: 1.4)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.45, 0.70, 0.40)
    /// Painted cast iron.
    public var iron: MaterialKey = "metal.wrought-iron"
    /// Wire basket and hangers.
    public var wire: MaterialKey = "metal.galvanized-aged"
    /// Coir liner.
    public var coir: MaterialKey = "fabric.burlap"
    /// Bloom color.
    public var bloom: MaterialKey = "flower.petal:C4202A"
    public init() {}

    /// Spiral polyline in the YZ plane (x = 0), centre (cz, cy), radius r0 to r1, `turns` turns from angle a0 (degrees).
    func spiral(_ cz: Float, _ cy: Float, _ r0: Float, _ r1: Float, a0: Float, turns: Float, dir: Float = 1, n: Int = 18) -> [V3] {
        (0...n).map { i in
            let u = Float(i) / Float(n), a = (a0 + dir * u * turns * 360) * .pi / 180, r = r0 + (r1 - r0) * u
            return V3(0, cy + r * sin(a), cz + r * cos(a))
        }
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let armY: Float = 0.60, cz: Float = 0.22, cy: Float = 0.30, R: Float = 0.18
        // Wall plate 50 x 8 mm, bevelled, with acorn finial and two coach screws.
        FA.box(&m, V3(0.05, 0.34, 0.008), V3(0, 0.53, 0.004), iron, r: 0.002)
        m.add(Prim.lathe([V2(0, 0), V2(0.012, 0), V2(0.014, 0.004), V2(0.012, 0.012), V2(0.011, 0.02), V2(0.004, 0.03), V2(0, 0.032)], segments: 12, seamTile: 0.1, material: iron),
              Xform(translation: V3(0, 0.665, 0.008)))
        FA.ball(&m, r: 0.011, at: V3(0, 0.682, 0.008), iron)
        for y: Float in [0.42, 0.64] {
            hexBolt(&m, at: V3(0, y, 0.008), normal: FA.Z, size: 0.016, material: "metal.rust")
        }
        // Arm: profile (z out, y up) 28 mm deep, top bead, extruded 14 mm wide.
        FA.side(&m, [V2(0.008, armY - 0.014), V2(0.262, armY - 0.014), V2(0.262, armY + 0.014), V2(0.008, armY + 0.014)], thick: 0.014, at: .zero, iron, bevel: 0.002)
        // Diagonal strut: concave S-curve from the plate to the arm, round 14 mm bar.
        let strut = catmull([V3(0, 0.395, 0.012), V3(0, 0.425, 0.06), V3(0, 0.475, 0.115), V3(0, 0.53, 0.17), V3(0, armY - 0.016, 0.222)], per: 6)
        m.add(Prim.tube(strut, radii: strut.indices.map { 0.0075 - 0.002 * Float($0) / Float(strut.count) }, sides: 10, seamTile: 0.1, material: iron, capEnd: true))
        // Volutes: C-scroll under the arm and a curled terminal at its tip.
        for dir: Float in [1] {
            m.add(Prim.tube(spiral(0.1, 0.545, 0.048, 0.008, a0: 90, turns: 1.3, dir: dir), radii: Array(repeating: 0.0048, count: 19), sides: 8, seamTile: 0.1, material: iron, capEnd: true))
        }
        m.add(Prim.tube(spiral(0.2, 0.468, 0.03, 0.007, a0: -90, turns: 1.2, dir: -1, n: 16), radii: Array(repeating: 0.0042, count: 17), sides: 8, seamTile: 0.1, material: iron, capEnd: true))
        m.add(Prim.tube(spiral(0.262, armY - 0.03, 0.03, 0.006, a0: 90, turns: 1.1, dir: 1, n: 16), radii: Array(repeating: 0.0045, count: 17), sides: 8, seamTile: 0.1, material: iron, capEnd: true))
        // Collars (cast bosses) where the strut and scrolls meet the arm and plate.
        for (z, y) in [(Float(0.012), Float(0.395)), (0.222, armY - 0.016)] {
            FA.ball(&m, r: 0.0105, at: V3(0, y, z), iron)
        }
        // Wear: rust runs below each coach screw, chipped paint on the arm soffit and strut shoulder.
        for y: Float in [0.42, 0.64] {
            FA.box(&m, V3(0.006, rng.float(0.05...0.09), 0.0005), V3(rng.float(-0.006...0.006), y - 0.04, 0.0085), "metal.rust", r: 0.0002)
        }
        for z in [0.05, 0.12, 0.2] as [Float] {
            FA.box(&m, V3(0.012, 0.0006, rng.float(0.015...0.03)), V3(0, armY - 0.0145, z), "metal.rust", r: 0.0002)
        }
        // S-hook, ring and three galvanised hangers to the basket rim.
        m.add(Prim.tube(catmull([V3(0, armY - 0.014, cz), V3(0, armY - 0.034, cz), V3(0.012, armY - 0.048, cz), V3(0, armY - 0.062, cz), V3(-0.006, armY - 0.05, cz)], per: 4),
                        radii: Array(repeating: 0.0032, count: 17), sides: 8, seamTile: 0.1, material: iron, capEnd: true))
        let ringY = armY - 0.07
        m.add(Prim.torus(major: 0.016, minor: 0.0028, segments: 18, sides: 6, material: wire), Xform(translation: V3(0, ringY, cz), rotation: FA.q(90, FA.X)))
        for k in 0..<3 {
            let a = Float(k) * 120 * .pi / 180 + 0.5
            let top = V3(0.016 * sin(a), ringY, cz + 0.016 * cos(a)), rim = V3(R * sin(a), cy + 0.012, cz + R * cos(a))
            m.add(Prim.tube([top, rim], radii: [0.0018, 0.0018], sides: 5, seamTile: 0.1, material: wire, capEnd: true))
        }
        // Wire basket: 16 meridian ribs, 4 hoops, rolled rim.
        for k in 0..<16 {
            let a = Float(k) / 16 * 2 * .pi
            var pts: [V3] = []
            for i in 0...8 {
                let t = Float(i) / 8 * (.pi / 2 * 0.98)
                pts.append(V3(R * cos(t) * sin(a), cy + 0.012 - R * 0.88 * sin(t), cz + R * cos(t) * cos(a)))
            }
            m.add(Prim.tube(pts, radii: Array(repeating: 0.0022, count: 9), sides: 5, seamTile: 0.1, material: wire, capEnd: true))
        }
        for i in 1...4 {
            let t = Float(i) / 5 * (.pi / 2)
            m.add(Prim.torus(major: R * cos(t), minor: 0.0022, segments: 22, sides: 5, material: wire),
                  Xform(translation: V3(0, cy + 0.012 - R * 0.88 * sin(t), cz)))
        }
        m.add(Prim.torus(major: R, minor: 0.0042, segments: 28, sides: 6, material: wire), Xform(translation: V3(0, cy + 0.012, cz)))
        // Coir liner (hemispherical shell slightly inside the wire) and potting soil.
        var prof: [V2] = []
        for i in 0...8 {
            let t = Float(i) / 8 * (.pi / 2)
            prof.append(V2((R - 0.004) * cos(t) * 0.99, cy + 0.012 - (R - 0.004) * 0.88 * sin(t)))
        }
        m.add(Prim.lathe(prof.reversed(), segments: 24, seamTile: 0.06, material: coir), Xform(translation: V3(0, 0, cz)))
        m.add(Prim.lathe([V2(0, cy - 0.01), V2(R - 0.012, cy - 0.01), V2(R - 0.008, cy + 0.008), V2(0, cy + 0.012)].reversed(), segments: 24, seamTile: 0.1, material: "soil.potting"), Xform(translation: V3(0, 0, cz)))
        // Planting: pelargonium leaf cards and blooms, ivy trailing over the rim.
        for k in 0..<12 {
            let a = Float(k) / 12 * 360 + rng.float(-10...10), r = rng.float(0.05...0.15)
            FC.leafCard(&m, "leaf.rose", at: V3(r * sin(a * .pi / 180), cy + 0.01, cz + r * cos(a * .pi / 180)), width: 0.12, height: rng.float(0.1...0.15),
                        spin: rng.float(-20...20), tilt: rng.float(-35...(-10)), yaw: a)
        }
        let tones: [MaterialKey] = [bloom, "flower.petal:D9435B", "flower.petal:E27A8C", "flower.petal:B3162A"]
        for k in 0..<9 {
            let a = Float(k) / 9 * 2 * .pi + rng.float(-0.2...0.2), r = rng.float(0.03...0.13)
            let c = V3(r * sin(a), cy + 0.1 + rng.float(0...0.05), cz + r * cos(a))
            for j in 0..<5 {
                m.add(ShrubKit.floretBall(center: c + V3(rng.float(-0.022...0.022), rng.float(-0.012...0.012), rng.float(-0.022...0.022)), radius: rng.float(0.011...0.016),
                                          up: FA.Y, subdivisions: 2, seed: rng.float(0...40), material: tones[(k + j) % tones.count]))
            }
        }
        for k in 0..<10 {
            let a = Float(k) / 10 * 360 + rng.float(-12...12)
            let p = V3((R + 0.01) * sin(a * .pi / 180), cy + 0.02, cz + (R + 0.01) * cos(a * .pi / 180))
            FC.leafCard(&m, "leaf.boxwood", at: p, width: 0.09, height: rng.float(0.15...0.27), spin: 180, tilt: rng.float(-12...(-4)), yaw: a)
        }
        groundAO(&m, height: 0.3, floor: 0.75)
        return LODModel(FC.fit(m, size))
    }
}
