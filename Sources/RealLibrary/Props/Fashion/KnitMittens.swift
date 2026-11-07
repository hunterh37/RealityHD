import simd
import Foundation

/// Pair of chunky knit wool mittens, about 0.24 m long each: cream ribbed cuffs, red knit bodies with two cream
/// bands, side thumbs. They lie crossed on the floor, the right one draped over the left. Origin at the base centre.
public struct KnitMittens: RealAsset {
    public static let id = "knit-mittens"
    public static let summary = "Pair of chunky red and cream knit wool mittens, 0.24 m each: ribbed cuffs, thumbs, lying crossed."
    public static let tags = ["prop", "fashion", "winter", "wool", "knit"]
    public static let budget = 10_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 45, distance: 0.55, studio: true)

    public var red: MaterialKey = "fabric.wool:A3201A"
    public var cream: MaterialKey = "fabric.wool:E3DCCB"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        _ = seed
        var levels: [Model] = []
        let flat: Float = 0.55
        for l in 0..<2 {
            let sides = l == 0 ? 36 : 16
            let per = l == 0 ? 4 : 2
            // Body radius table (z, r), smoothed.
            let table = catmull([V3(0.058, 0.0375, 0), V3(0.075, 0.0425, 0), V3(0.105, 0.0495, 0), V3(0.145, 0.0505, 0),
                                 V3(0.185, 0.0465, 0), V3(0.213, 0.0365, 0), V3(0.230, 0.0215, 0), V3(0.238, 0.0100, 0)], per: per)
            func radius(_ z: Float) -> Float {
                guard let i = table.firstIndex(where: { $0.x >= z }), i > 0 else { return table[0].y }
                let a = table[i - 1], b = table[i]
                return a.y + (b.y - a.y) * (z - a.x) / max(1e-5, b.x - a.x)
            }
            let knit: (Float, Float) -> Float = { t, v in 1 + 0.028 * cos(t * 2 * .pi * 26) * (0.55 + 0.45 * cos(v * 2 * .pi / 0.0085)) }
            let rib: (Float, Float) -> Float = { t, _ in 1 + 0.07 * cos(t * 2 * .pi * 20) }
            func mitten(side: Float, zShift: Float) -> Model {
                var m = Model(name: "mitten")
                let cuffN = l == 0 ? 8 : 3
                let cz = (0...cuffN).map { 0.0 + 0.062 * Float($0) / Float(cuffN) }
                let cuff = cz.map { V3(0, 0, $0 + zShift) }
                m.add(Prim.tube(cuff, radii: cz.map { 0.0355 + 0.002 * $0 / 0.062 }, sides: sides, seamTile: 0.1, material: cream,
                                capEnd: false, rippling: rib))
                let bodyZ = table.map(\.x)
                m.add(Prim.tube(bodyZ.map { V3(0, 0, $0 + zShift) }, radii: table.map(\.y), sides: sides, seamTile: 0.1, material: red,
                                rippling: knit))
                for (z0, z1) in [(Float(0.098), Float(0.112)), (0.124, 0.131)] {
                    let zs = (0...4).map { z0 + (z1 - z0) * Float($0) / 4 }
                    m.add(Prim.tube(zs.map { V3(0, 0, $0 + zShift) }, radii: zs.map { radius($0) + 0.0016 }, sides: sides, seamTile: 0.1,
                                    material: cream, capEnd: false, rippling: knit))
                }
                let th = catmull([V3(side * 0.034, 0, 0.092), V3(side * 0.052, 0, 0.108), V3(side * 0.066, 0, 0.130),
                                  V3(side * 0.070, 0, 0.150), V3(side * 0.069, 0, 0.166)], per: l == 0 ? 4 : 2)
                let tr = th.indices.map { i -> Float in 0.0215 - 0.0105 * smoothstep(0, 1, Float(i) / Float(th.count - 1)) }
                m.add(Prim.tube(th.map { $0 + V3(0, 0, zShift) }, radii: tr, sides: max(12, sides * 2 / 3), seamTile: 0.08,
                                material: red, rippling: knit))
                return m.transformed(Xform(scale: V3(1, flat, 1)))
            }
            let yaw = Float(22) * .pi / 180
            var m = Model(name: Self.id)
            // Left mitten, centred on the origin.
            m.add(mitten(side: 1, zShift: -0.12), Xform(rotation: simd_quatf(angle: yaw, axis: V3(0, 1, 0))))
            // Right mitten crossed over it: yawed the other way, draped over the first at the crossing.
            var b = mitten(side: -1, zShift: -0.12).transformed(Xform(rotation: simd_quatf(angle: -yaw, axis: V3(0, 1, 0))))
            for i in b.surfaces.indices {
                b.surfaces[i].deform { p in
                    let d = simd_length(V2(p.x, p.z))
                    return V3(p.x, p.y + 0.052 * exp(-pow(d / 0.075, 2)), p.z)
                }
            }
            m.add(b)
            let bb = m.bounds
            levels.append(m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2))))
        }
        return LODModel(levels: levels, switchDistances: [3])
    }
}
