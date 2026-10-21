import simd
import Foundation

/// Power cord C19: IEC C19 to C20 server PDU cord, black rubber jacket, matte molded ends, small white rating label. Parts: black rubber jacket, molded C19 connector with slot face, molded C20 plug with pin face, strain reliefs, white rating label.
public struct PowerCordC19: RealAsset {
    public static let id = "power-cord-c19"
    public static let summary = "IEC C19-to-C20 power cord, 1.5 m, black rubber jacket in a loose curve with molded connectors, strain reliefs and a rating label."
    public static let tags = ["prop", "handheld"]
    public static let budget = 2000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.06, 0.03, 1.5)
    /// Cord jacket radius in meters (10.5 mm outer diameter).
    public var cordRadius: Float = 0.0053
    /// Sideways swing of the S curve in meters.
    public var swing: Float = 0.0255
    /// Jacket material.
    public var jacket: MaterialKey = "rubber:111111"
    /// Molded connector material.
    public var molded: MaterialKey = "plastic.matte:151515"
    /// Label stock.
    public var labelStock: MaterialKey = "plastic.matte:F2F2F2"
    /// Contact blades.
    public var blade: MaterialKey = "metal.steel"
    public init() {}

    /// Cord centerline x offset at z (zero at both ends, so connectors sit straight).
    func xAt(_ z: Float) -> Float {
        let u = (z + size.z / 2) / size.z
        let env = sin(.pi * min(max(u, 0), 1))
        return swing * sin(2 * .pi * 1.5 * u) * min(1, env * 3)
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let half = size.z / 2
        let bodyL: Float = 0.05, bodyW: Float = 0.034, bodyH: Float = size.y
        let cy = bodyH / 2
        let r = cordRadius
        func box(_ s: V3, _ c: V3, r rr: Float = 0.0015, mat: MaterialKey) {
            m.add(Prim.roundedBox(s, radius: min(rr, min(s.x, min(s.y, s.z)) * 0.4), bevelSegments: 1, material: mat), Xform(translation: c))
        }
        // Jacket: lifts from the floor to connector height over the last 8 cm, flaring into strain reliefs.
        var ctrl: [V3] = []
        let step: Float = 0.1
        var z = -half + bodyL * 0.8
        while z < half - bodyL * 0.8 {
            ctrl.append(V3(xAt(z), 0, z)); z += step
        }
        ctrl.append(V3(0, 0, half - bodyL * 0.8))
        let pts = catmull(ctrl, per: 2)
        var path: [V3] = [], radii: [Float] = []
        for p in pts {
            let d = min(p.z + half, half - p.z) - bodyL * 0.8   // distance from the strain-relief start
            let lift = max(0, 1 - d / 0.07)
            let relief = max(0, 1 - d / 0.045)
            path.append(V3(p.x, r + (cy - r) * lift * lift, p.z))
            radii.append(r * (1 + 0.55 * relief * relief))
        }
        m.add(Prim.tube(path, radii: radii, sides: 8, seamTile: 0.02, material: jacket))
        // Connector bodies with grip ribs and a shoulder where the strain relief enters.
        for e: Float in [-1, 1] {
            let zc = e * (half - bodyL / 2 - (e > 0 ? 0.012 : 0))
            box(V3(bodyW, bodyH, bodyL), V3(0, cy, zc), r: 0.0035, mat: molded)
            box(V3(bodyW + 0.004, bodyH, 0.008), V3(0, cy, zc - e * (bodyL / 2 - 0.004)), r: 0.002, mat: molded)
            for k in 0..<4 {
                let rz = zc - e * (0.004 + Float(k) * 0.0065)
                for sx: Float in [-1, 1] { m.add(cuboid(V3(0.0012, bodyH * 0.6, 0.0028), material: molded), Xform(translation: V3(sx * (bodyW / 2 + 0.0004), cy, rz))) }
            }
        }
        // C19 (female) at -z: shroud lip, dark recessed face, three rectangular slots.
        let fz = -half
        let lip: Float = 0.0025
        m.add(cuboid(V3(bodyW, lip, 0.006), material: molded), Xform(translation: V3(0, bodyH - lip / 2, fz + 0.003)))
        m.add(cuboid(V3(bodyW, lip, 0.006), material: molded), Xform(translation: V3(0, lip / 2, fz + 0.003)))
        for sx: Float in [-1, 1] { m.add(cuboid(V3(lip, bodyH, 0.006), material: molded), Xform(translation: V3(sx * (bodyW / 2 - lip / 2), cy, fz + 0.003))) }
        m.add(cuboid(V3(bodyW - 2 * lip, bodyH - 2 * lip, 0.0008), material: "plastic.matte:060606"), Xform(translation: V3(0, cy, fz + 0.0064)))
        for (sx, sy, w, h) in [(-0.0095 as Float, 0.0055 as Float, 0.0085 as Float, 0.0018 as Float), (0.0095, 0.0055, 0.0085, 0.0018), (0, -0.005, 0.0018, 0.0085)] {
            m.add(cuboid(V3(w, h, 0.0006), material: "plastic.matte:000000"), Xform(translation: V3(sx, cy + sy, fz + 0.0069)))
            // Visible contact inside each slot.
            m.add(cuboid(V3(w * 0.8, h * 0.45, 0.0004), material: blade), Xform(translation: V3(sx, cy + sy, fz + 0.0073)))
        }
        // C20 (male) at +z: face plate and three flat blades.
        let pz = half
        box(V3(bodyW - 0.004, bodyH - 0.004, 0.0035), V3(0, cy, pz - 0.0135), r: 0.001, mat: molded)
        for (sx, sy, w, h) in [(-0.0095 as Float, 0.0055 as Float, 0.0085 as Float, 0.0016 as Float), (0.0095, 0.0055, 0.0085, 0.0016), (0, -0.005, 0.0016, 0.0085)] {
            m.add(cuboid(V3(w, h, 0.0115), material: blade), Xform(translation: V3(sx, cy + sy, pz - 0.006)))
        }
        // Rating label: white flag wrapped over the jacket with printed lines.
        let lz: Float = 0.31
        let lx = xAt(lz)
        box(V3(0.016, 0.0012, 0.034), V3(lx, 2 * r + 0.0004, lz), r: 0.0004, mat: labelStock)
        for k in 0..<4 {
            let w: Float = k == 0 ? 0.011 : 0.008 + 0.002 * Float(rng.next() % 3)
            m.add(cuboid(V3(w, 0.0003, 0.0020), material: "plastic.matte:111214"), Xform(translation: V3(lx - 0.002, 2 * r + 0.0012, lz - 0.012 + Float(k) * 0.0075)))
        }
        // Wear: grey drag scuffs on the jacket, a mold parting line and flash on each connector, label fold tab.
        for k in 0..<5 {
            let sz = -half + 0.25 + Float(rng.next() % 1000) / 1000 * (size.z - 0.5)
            let len = 0.012 + Float(rng.next() % 30) / 1000
            m.add(cuboid(V3(0.0016, 0.0003, len), material: "plastic.matte:4A4B4C"), Xform(translation: V3(xAt(sz) + Float(k % 2) * 0.002, 2 * r - 0.0004, sz)))
        }
        for e: Float in [-1, 1] {
            let zc = e * (half - bodyL / 2 - (e > 0 ? 0.012 : 0))
            m.add(cuboid(V3(bodyW + 0.0006, 0.0006, bodyL * 0.7), material: "plastic.matte:2A2A2B"), Xform(translation: V3(0, cy, zc + e * 0.004)))
            m.add(cuboid(V3(0.008, 0.0004, 0.006), material: "plastic.matte:3A3A3B"), Xform(translation: V3(0.006, bodyH + 0.0002, zc)))
        }
        m.add(cuboid(V3(0.016, 0.0006, 0.007), material: labelStock), Xform(translation: V3(lx, r + 0.0004, lz + 0.0205)))
        groundAO(&m)
        return LODModel(m)
    }
}
