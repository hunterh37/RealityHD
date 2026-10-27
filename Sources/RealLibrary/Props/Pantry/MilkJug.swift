import simd
import Foundation

/// Milk jug: everyday pantry, HDPE plastic. Blow-moulded jug 10 cm square and 25 cm tall with a handle
/// loop on one shoulder, ribbed panels near the base and top of the body, a blue shrink sleeve with a white
/// drop badge, mould parting lines on both sides, a pinch-off seam under the base, a tamper ring and a
/// ribbed screw cap. A small dent and scuff marks sit low on the front.
public struct MilkJug: RealAsset {
    public static let id = "milk-jug"
    public static let summary = "HDPE milk jug with handle, ribbed panels, tamper ring cap and base seam."
    public static let tags = ["prop", "interior", "pantry", "plastic"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 18, distance: 1.1, studio: true)

    /// Jug plastic.
    public var hdpe: MaterialKey = "plastic.matte:EDEDE6"
    /// Sleeve and cap.
    public var blue: MaterialKey = "plastic.matte:2B5FA8"
    /// Scuffed plastic.
    public var scuff: MaterialKey = "plastic.matte:D2D2C8"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let segs = 36
        func ring(_ y: Float, _ r: Float, _ ex: Float) -> [V3] { Prim.ring(DD1IPantry.superSection(r, r, ex: ex, segs: segs), y: y) }
        var rings: [[V3]] = [ring(0.0, 0.043, 3.0), ring(0.003, 0.0485, 3.4), ring(0.008, 0.0502, 3.6)]
        for (y, r) in [(0.02, 0.0502), (0.0245, 0.0484), (0.029, 0.0502), (0.035, 0.0502), (0.0395, 0.0484), (0.044, 0.0502), (0.12, 0.0502),
                       (0.1505, 0.0502), (0.155, 0.0484), (0.1595, 0.0502), (0.172, 0.0502), (0.176, 0.0484), (0.18, 0.0502)] as [(Float, Float)] {
            rings.append(ring(y, r, 3.6))
        }
        rings += [ring(0.19, 0.0488, 3.1), ring(0.2, 0.041, 2.6), ring(0.209, 0.031, 2.2), ring(0.2155, 0.0245, 2.0), ring(0.2195, 0.0236, 2.0)]
        var body = Prim.loft(rings, capStart: true, material: hdpe)
        // A low dent on the front and fine surface texture.
        body.displace { p, n in
            let dent = -0.0017 * exp(-(pow(p.x - 0.012, 2) + pow(p.y - 0.032, 2)) / 0.00018) * (n.z > 0.4 ? 1 : 0)
            return dent + 0.00018 * sin(p.x * 330 + p.y * 120) * sin(p.z * 280 + p.y * 90)
        }
        m.add(body)
        // Blue shrink sleeve and white drop badge.
        var sleeve = Prim.loft([ring(0.058, 0.0507, 3.6), ring(0.146, 0.0507, 3.6)], material: blue)
        sleeve.recomputeNormals()
        m.add(sleeve)
        m.add(Prim.extrude(Shape2D.circle(0.016, ry: 0.021, segments: 24), depth: 0.0007, bevel: 0.0002, bevelSegments: 1, material: "plastic.matte:F4F4EF"),
              Xform(translation: V3(0, 0.102, 0.0507)))
        for (i, w) in ([0.04, 0.03] as [Float]).enumerated() {
            m.add(Prim.roundedBox(V3(w, 0.0045, 0.0007), radius: 0.0002, bevelSegments: 1, material: "plastic.matte:F4F4EF"),
                  Xform(translation: V3(0, 0.07 - Float(i) * 0.0085, 0.0507)))
        }
        // Grime band at the base and fainter yellowing on the shoulder.
        var grime = Prim.loft([ring(0.003, 0.0509, 3.6), ring(0.0185, 0.0509, 3.6)], material: "plastic.matte:C7C3B0")
        grime.recomputeNormals()
        m.add(grime)
        var yellow = Prim.loft([ring(0.1805, 0.0506, 3.6), ring(0.19, 0.049, 3.1), ring(0.2, 0.0415, 2.6)], material: "plastic.matte:E4DFC4")
        yellow.recomputeNormals()
        m.add(yellow)
        for _ in 0..<8 {
            m.add(Prim.roundedBox(V3(rng.float(0.01...0.03), 0.0005, 0.0008), radius: 0.0002, bevelSegments: 1, material: "plastic.matte:6F95CE"),
                  Xform(translation: V3(rng.float(-0.03...0.03), rng.float(0.065...0.14), 0.0509), rotation: simd_quatf(degrees: rng.float(-35...35), axis: V3(0, 0, 1))))
        }
        // Mould parting lines and base pinch-off seam.
        for sx: Float in [-1, 1] {
            m.add(Prim.tube([V3(sx * 0.0506, 0.012, 0), V3(sx * 0.0506, 0.1, 0), V3(sx * 0.0506, 0.182, 0)], radii: [0.0005, 0.0005, 0.0005], sides: 4, seamTile: 0.01,
                            material: "plastic.matte:DADAD0"))
        }
        m.add(Prim.roundedBox(V3(0.082, 0.0016, 0.0035), radius: 0.0006, bevelSegments: 1, material: scuff), Xform(translation: V3(0, 0.0004, 0)))
        // Neck, tamper ring and cap.
        let neck: [V2] = [V2(0.0236, 0.2185), V2(0.0222, 0.2205), V2(0.0222, 0.2262), V2(0.0235, 0.2272), V2(0.0222, 0.2282), V2(0.0222, 0.231)]
        m.add(Prim.lathe(neck, segments: 28, seamTile: 0.05, material: hdpe))
        let tamper: [V2] = [V2(0.0243, 0.2225), V2(0.0258, 0.2228), V2(0.0258, 0.2268), V2(0.0243, 0.2271), V2(0.0243, 0.2225)]
        m.add(Prim.lathe(tamper, segments: 32, seamTile: 0.05, material: blue))
        for k in 0..<5 {
            let a = Float(k) / 5 * 2 * .pi
            m.add(Prim.roundedBox(V3(0.0014, 0.0034, 0.0042), radius: 0.0003, bevelSegments: 1, material: blue),
                  Xform(translation: V3(0.0236 * cos(a), 0.2273, 0.0236 * sin(a)), rotation: simd_quatf(degrees: -a * 180 / .pi, axis: .up)))
        }
        let capP: [V2] = [V2(0, 0.2495), V2(0.0215, 0.2495), V2(0.0245, 0.2485), V2(0.0255, 0.2465), V2(0.0255, 0.2285), V2(0.0245, 0.2272), V2(0.0242, 0.2272), V2(0.0232, 0.2285), V2(0, 0.2285)]
        var cap = Prim.lathe(capP, segments: 48, seamTile: 0.05, material: blue)
        cap.displace { p, n in abs(n.y) > 0.6 ? 0 : 0.0004 * sin(atan2(p.z, p.x) * 30) }
        m.add(cap)
        // Handle: loop from the shoulder to the upper body.
        let hp = catmull([V3(0.041, 0.2, 0), V3(0.062, 0.222, 0), V3(0.0835, 0.218, 0), V3(0.0915, 0.198, 0), V3(0.0875, 0.17, 0), V3(0.072, 0.153, 0), V3(0.048, 0.1495, 0)], per: 6)
        m.add(Prim.tube(hp, radii: hp.indices.map { i in 0.0068 - 0.0006 * sin(Float.pi * Float(i) / Float(hp.count - 1)) }, sides: 10, seamTile: 0.05, material: hdpe))
        // Scuffs on the lower front.
        for _ in 0..<6 {
            m.add(Prim.roundedBox(V3(rng.float(0.006...0.02), 0.0005, 0.0008), radius: 0.0002, bevelSegments: 1, material: scuff),
                  Xform(translation: V3(rng.float(-0.03...0.03), rng.float(0.014...0.05), 0.0503), rotation: simd_quatf(degrees: rng.float(-30...30), axis: V3(0, 0, 1))))
        }
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y, 0)))
        groundAO(&m, height: 0.04, floor: 0.7)
        return LODModel(m)
    }
}
