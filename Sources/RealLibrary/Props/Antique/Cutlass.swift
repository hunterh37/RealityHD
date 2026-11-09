import simd
import Foundation

/// Naval cutlass, 0.86 m overall: single-edged curved steel blade with a fuller and a clipped point, stamped brass
/// cup guard (0.12 x 0.08 m ellipse) with a knuckle bow, black wire-wrapped leather grip with brass ferrules and a
/// turned brass pommel. Lies flat with the blade curving toward -X. Origin at the midpoint of the length, pommel at -Z, point at +Z, base y = 0.
/// Anchors: `grip.center`, `guard`, `blade.tip`, `pommel`.
public struct Cutlass: RealAsset {
    public static let id = "cutlass"
    public static let summary = "Naval cutlass, 0.86 m: curved steel blade with fuller, brass cup guard and knuckle bow, wrapped leather grip, brass pommel."
    public static let tags = ["prop", "antique", "metal", "leather", "handheld"]
    public static let budget = 12_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 60, elevation: 50, distance: 1.1, studio: true)

    /// Blade steel.
    public var steel: MaterialKey = "metal.hammer-polished"
    /// Guard, ferrules and pommel.
    public var brass: MaterialKey = "metal.brass-aged"
    /// Grip wrap.
    public var wrap: MaterialKey = "leather.black"
    public init() {}

    public var anchors: [String: Xform] {
        [
            "grip.center": Xform(translation: V3(0, 0.04, -0.3475)),
            "guard": Xform(translation: V3(0, 0.04, -0.2725)),
            "blade.tip": Xform(translation: V3(-0.04, 0.04, 0.4275)),
            "pommel": Xform(translation: V3(0, 0.04, -0.4325)),
        ]
    }

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let cy: Float = 0.04
        let toZ = simd_quatf(degrees: 90, axis: V3(1, 0, 0))   // lathe +Y -> +Z
        // Pommel: turned brass cap.
        m.add(Prim.lathe([V2(0, 0), V2(0.010, 0.0015), V2(0.0185, 0.008), V2(0.0215, 0.016), V2(0.019, 0.024), V2(0.0125, 0.0305), V2(0.011, 0.034), V2(0, 0.034)],
                         segments: 64, seamTile: 0.02, material: brass), Xform(translation: V3(0, cy, 0), rotation: toZ))
        // Grip: 0.034 to 0.150, ribbed wire-wrap profile, with ferrule collars.
        var gp: [V2] = [V2(0, 0.034)]
        let n = 56
        for i in 0...n {
            let t = Float(i) / Float(n), y = 0.034 + 0.116 * t
            let swell = 0.0125 + 0.0025 * sin(t * .pi)
            let rib = 0.0007 * (0.5 + 0.5 * sin(t * 2 * .pi * 15))
            gp.append(V2(swell + rib, y))
        }
        gp.append(V2(0, 0.150))
        m.add(Prim.lathe(gp, segments: 48, seamTile: 0.03, material: wrap), Xform(translation: V3(0, cy, 0), rotation: toZ))
        for (y0, y1) in [(Float(0.031), Float(0.040)), (0.144, 0.153)] {
            m.add(Prim.lathe([V2(0.0125, y0), V2(0.0165, y0 + 0.001), V2(0.0165, y1 - 0.001), V2(0.0125, y1)], segments: 48, seamTile: 0.03, material: brass), Xform(translation: V3(0, cy, 0), rotation: toZ))
        }
        // Cup guard: dished bowl, elliptical 0.12 x 0.08.
        var cup = Prim.lathe([V2(0.010, 0.152), V2(0.030, 0.150), V2(0.050, 0.146), V2(0.060, 0.1425), V2(0.0605, 0.1405), V2(0.052, 0.1385),
                              V2(0.036, 0.1405), V2(0.020, 0.1445), V2(0.011, 0.1475), V2(0.010, 0.1495)].map { V2($0.x, $0.y) }, segments: 64, seamTile: 0.03, material: brass)
        cup.deform { V3($0.x, $0.y, $0.z * 0.667) }
        // Bowl opens toward the blade side: flip y about the guard plane to put the dish toward the grip.
        m.add(cup, Xform(translation: V3(0, cy, 0), rotation: toZ))
        // Knuckle bow: arches from the pommel collar to the guard rim along the top.
        let bow = catmull([V3(0, 0.054, 0.028), V3(0, 0.072, 0.050), V3(0, 0.078, 0.090), V3(0, 0.077, 0.128), V3(0, 0.073, 0.146)], per: 6)
        m.add(Prim.tube(bow, radii: bow.map { _ in 0.0034 }, sides: 48, seamTile: 0.02, material: brass))
        // Blade: curved sweep, tapering to a clipped point.
        let len: Float = 0.865 - 0.17, bn = 36
        var path: [V3] = [], sc: [Float] = []
        for i in 0...bn {
            let t = Float(i) / Float(bn)
            path.append(V3(-0.04 * t * t, cy, 0.17 + len * t))
            sc.append(t < 0.92 ? 1 - 0.08 * t : lerp(0.93, 0.06, pow((t - 0.92) / 0.08, 0.8)))
        }
        // Profile: x thickness (up axis = +Y), y width in the blade plane. Spine on -y, edge on +y, fuller groove on the flat.
        let prof: [V2] = [V2(-0.0030, -0.016), V2(0.0030, -0.016), V2(0.0036, -0.012), V2(0.0026, -0.006), V2(0.0018, -0.001), V2(0.0030, 0.004),
                          V2(0.0020, 0.012), V2(0.0003, 0.0165), V2(-0.0003, 0.0165), V2(-0.0020, 0.012), V2(-0.0030, 0.004), V2(-0.0018, -0.001),
                          V2(-0.0026, -0.006), V2(-0.0036, -0.012)]
        m.add(Prim.sweep(prof, along: path, up: V3(0, 1, 0), scales: sc, caps: true, material: steel))
        // Ricasso block.
        m.add(Prim.roundedBox(V3(0.010, 0.010, 0.020), radius: 0.002, bevelSegments: 2, material: brass), Xform(translation: V3(0, cy, 0.17)))
        return LODModel(m.transformed(Xform(translation: V3(0, 0, -0.4325))))
    }
}
