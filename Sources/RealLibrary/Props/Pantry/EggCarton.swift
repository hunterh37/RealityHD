import simd
import Foundation

/// Egg carton: everyday pantry, moulded pulp. Twelve-cup tray, 30 x 10 cm, with thin-walled conical cups,
/// a flange frame, five tall cone separators between cups and a hinged lid propped open 62 degrees with a
/// latch tab, ribbed top panel and an ink date stamp. Two eggs (one white, one brown) sit in cups, one
/// empty cup holds a damp stain and a shell shard.
public struct EggCarton: RealAsset {
    public static let id = "egg-carton"
    public static let summary = "Moulded pulp egg carton with 12 cups, cone separators and latched lid, two eggs inside."
    public static let tags = ["prop", "interior", "pantry", "paper"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 32, distance: 0.82, studio: true)

    /// Tray pulp.
    public var tray: MaterialKey = "paper.sheet:B9AE98"
    /// Lid pulp, a shade darker.
    public var lid: MaterialKey = "paper.sheet:A89D88"
    /// Water-stained pulp.
    public var stain: MaterialKey = "paper.sheet:8F8470"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let rimY: Float = 0.0365
        let cup: [V2] = [V2(0, 0.0), V2(0.008, 0.0), V2(0.0105, 0.002), V2(0.0135, 0.014), V2(0.0175, 0.028), V2(0.0215, 0.0345), V2(0.0224, 0.0365),
                         V2(0.0208, 0.0364), V2(0.0165, 0.028), V2(0.0122, 0.014), V2(0.0096, 0.004), V2(0, 0.0032)]
        for i in 0..<6 { for j in 0..<2 {
            let x = (Float(i) - 2.5) * 0.05, z = (Float(j) - 0.5) * 0.05
            var c = Prim.lathe(cup, segments: 14, seamTile: 0.08, material: ((i == 3 && j == 0) || (i == 0 && j == 1) || (i == 5 && j == 0)) ? stain : ((i + j) % 3 == 0 ? "paper.sheet:AEA38D" : tray))
            c.recomputeNormals()
            m.add(c, Xform(translation: V3(x, 0, z), rotation: simd_quatf(degrees: Float(i * 40 + j * 70), axis: .up)))
        }}
        // Flange frame and cross strips between cups.
        let fy = rimY - 0.0006
        for sz: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(0.3, 0.0012, 0.006), radius: 0.0004, bevelSegments: 1, material: tray), Xform(translation: V3(0, fy, sz * 0.047)))
        }
        for sx: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(0.006, 0.0012, 0.1), radius: 0.0004, bevelSegments: 1, material: tray), Xform(translation: V3(sx * 0.147, fy, 0)))
        }
        m.add(Prim.roundedBox(V3(0.3, 0.0012, 0.0045), radius: 0.0004, bevelSegments: 1, material: tray), Xform(translation: V3(0, fy, 0)))
        for k in 1...5 {
            m.add(Prim.roundedBox(V3(0.0048, 0.0012, 0.1), radius: 0.0004, bevelSegments: 1, material: tray), Xform(translation: V3((Float(k) - 3) * 0.05, fy, 0)))
        }
        // Cone separators at the cup junctions, with a rolled tip.
        let post: [V2] = [V2(0, 0.02), V2(0.0112, 0.02), V2(0.0105, 0.03), V2(0.0078, 0.04), V2(0.005, 0.0475), V2(0.0032, 0.0518), V2(0.0015, 0.0535), V2(0, 0.0538)]
        for k in 1...5 {
            m.add(Prim.lathe(post, segments: 10, seamTile: 0.08, material: tray), Xform(translation: V3((Float(k) - 3) * 0.05, 0, 0)))
        }
        // Hinge strip and hinged lid.
        m.add(Prim.roundedBox(V3(0.3, 0.0013, 0.007), radius: 0.0004, bevelSegments: 1, material: lid), Xform(translation: V3(0, rimY + 0.0003, -0.0485)))
        var lidM = Model(name: "lid")
        lidM.add(Prim.roundedBox(V3(0.3, 0.0016, 0.1), radius: 0.0006, bevelSegments: 1, material: lid), Xform(translation: V3(0, 0.0168, 0.05)))
        for sz: Float in [0, 1] {
            lidM.add(Prim.roundedBox(V3(0.3, 0.0165, 0.0014), radius: 0.0004, bevelSegments: 1, material: lid), Xform(translation: V3(0, 0.0085, sz * 0.0993 + 0.0007)))
        }
        for sx: Float in [-1, 1] {
            lidM.add(Prim.roundedBox(V3(0.0014, 0.0165, 0.1), radius: 0.0004, bevelSegments: 1, material: lid), Xform(translation: V3(sx * 0.1493, 0.0085, 0.05)))
        }
        lidM.add(Prim.roundedBox(V3(0.2, 0.0008, 0.056), radius: 0.0003, bevelSegments: 1, material: tray), Xform(translation: V3(0, 0.0178, 0.05)))
        for k in 0..<5 {
            lidM.add(Prim.roundedBox(V3(0.2, 0.0006, 0.0016), radius: 0.0002, bevelSegments: 1, material: lid), Xform(translation: V3(0, 0.0185, 0.03 + Float(k) * 0.01)))
        }
        // Latch tab on the front and ink date stamp.
        lidM.add(Prim.roundedBox(V3(0.022, 0.016, 0.0016), radius: 0.0005, bevelSegments: 1, material: lid), Xform(translation: V3(0, 0.003, 0.1008)))
        var x: Float = -0.045
        for _ in 0..<7 {
            let w = rng.float(0.002...0.004)
            lidM.add(Prim.roundedBox(V3(w, 0.0004, rng.float(0.004...0.007)), radius: 0.0001, bevelSegments: 1, material: "paper.sheet:3A3F66"),
                     Xform(translation: V3(x, 0.0185, 0.085), rotation: simd_quatf(degrees: rng.float(-10...10), axis: .up)))
            x += 0.0065
        }
        for k in 0..<12 {
            lidM.add(Prim.roundedBox(V3(rng.float(0.006...0.02), 0.0017, 0.0022), radius: 0.0005, bevelSegments: 1, material: "paper.sheet:CFC5AE"),
                     Xform(translation: V3(rng.float(-0.14...0.14), 0.0168, 0.0993 + 0.0013), rotation: simd_quatf(degrees: rng.float(-8...8), axis: .up)))
        }
        for k in 0..<5 {
            lidM.add(Prim.roundedBox(V3(0.012, 0.0006, 0.009), radius: 0.0002, bevelSegments: 1, material: stain),
                     Xform(translation: V3(rng.float(-0.12...0.12), 0.0188, rng.float(0.015...0.04)), rotation: simd_quatf(degrees: rng.float(0...180), axis: .up)))
        }
        m.add(lidM, Xform(translation: V3(0, rimY, -0.05), rotation: simd_quatf(degrees: -62, axis: V3(1, 0, 0))))
        // Eggs, pointed end down.
        for (i, j, key) in [(1, 0, "food.egg-shell"), (4, 1, "food.egg-shell:C99C6E")] as [(Int, Int, MaterialKey)] {
            var prof: [V2] = []
            for s in 0...16 {
                let t = Float(s) / 16
                let r = s == 0 || s == 16 ? 0 : 0.0214 * pow(sin(Float.pi * t), 0.6) * (0.85 + 0.3 * t)
                prof.append(V2(r, t * 0.057))
            }
            var e = Prim.lathe(prof, segments: 16, seamTile: 0.05, material: key)
            e.recomputeNormals()
            m.add(e, Xform(translation: V3((Float(i) - 2.5) * 0.05, 0.0042, (Float(j) - 0.5) * 0.05), rotation: simd_quatf(degrees: rng.float(-3...3), axis: V3(1, 0, 1))))
        }
        // Shell shard in the stained cup.
        var shard = Prim.superellipsoid(V3(0.009, 0.0008, 0.006), exponent: 3, subdivisions: 3, material: "food.egg-shell")
        shard.deform { p in V3(p.x, p.y + 0.0025 * p.x * p.x * 400, p.z) }
        m.add(shard, Xform(translation: V3(0.0, 0.005, -0.025), rotation: simd_quatf(degrees: 25, axis: .up)).translatedBy(V3(0.025, 0, 0)))
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(0, -b.min.y, 0)))
        groundAO(&m, height: 0.03, floor: 0.7)
        return LODModel(m)
    }
}

private extension Xform {
    func translatedBy(_ v: V3) -> Xform { var x = self; x.translation += v; return x }
}
