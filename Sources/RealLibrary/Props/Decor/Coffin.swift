import simd
import Foundation

/// Six-sided lacquered mahogany coffin, 2.0 m long and 0.62 m across the shoulders: tapered hexagonal plan,
/// plinth moulding, beveled two-step lid, brass bar handles on wood rails (three per long side, one per end)
/// and a brass cross plate on the lid. Long axis along X, head at -X. Origin at the base centre.
public struct Coffin: RealAsset {
    public static let id = "coffin"
    public static let summary = "Six-sided lacquered mahogany coffin, 2.0 m long: beveled stepped lid, plinth, brass bar handles on wood rails, brass cross plate."
    public static let tags = ["prop", "decor", "wood", "brass", "gothic", "funeral"]
    public static let budget = 12_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 25, distance: 1.1, studio: true)

    public var wood: MaterialKey = "wood.mahogany"
    public var brass: MaterialKey = "metal.brass"
    public var length: Float = 2.0
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        _ = seed
        var levels: [Model] = []
        let L = length / 2
        // Plan outline (x along length, y = lateral): head, shoulders, foot.
        let hex: [V2] = [V2(-L, -0.17), V2(-L * 0.55, -0.31), V2(L, -0.14), V2(L, 0.14), V2(-L * 0.55, 0.31), V2(-L, 0.17)]
        let plan = Shape2D.rounded(hex, radius: 0.012, segments: 2)
        let tilt = simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))   // extrude Z -> up, outline y -> -Z
        let bodyH: Float = 0.46, plinthH: Float = 0.05, lidH: Float = 0.045, capH: Float = 0.035
        for l in 0..<2 {
            var m = Model(name: Self.id)
            let bs = l == 0 ? 3 : 1
            func slab(_ o: [V2], h: Float, y: Float, bevel: Float, mat: MaterialKey) {
                m.add(Prim.extrude(o, depth: h, bevel: bevel, bevelSegments: bs, material: mat),
                      Xform(translation: V3(0, y + h / 2, 0), rotation: tilt))
            }
            slab(Shape2D.offset(plan, 0.014), h: plinthH, y: 0, bevel: 0.014, mat: wood)
            slab(plan, h: bodyH, y: plinthH * 0.6, bevel: 0.012, mat: wood)
            let lidY = plinthH * 0.6 + bodyH - 0.005
            slab(Shape2D.offset(plan, 0.016), h: lidH, y: lidY, bevel: 0.018, mat: wood)
            slab(Shape2D.offset(plan, -0.07), h: capH, y: lidY + lidH - 0.006, bevel: 0.016, mat: wood)
            // Brass inlay line around the lid step and a cross plate on the raised cap.
            let capTop = lidY + lidH - 0.006 + capH
            m.add(Prim.roundedBox(V3(0.30, 0.0035, 0.036), radius: 0.0012, bevelSegments: 2, material: brass), Xform(translation: V3(-L * 0.42, capTop + 0.0008, 0)))
            m.add(Prim.roundedBox(V3(0.036, 0.0035, 0.20), radius: 0.0012, bevelSegments: 2, material: brass), Xform(translation: V3(-L * 0.42 - 0.04, capTop + 0.0008, 0)))
            // Handles: bar on a wood rail, mounted on the side faces. Outline y maps to world -z.
            let cx = hex.reduce(V2.zero, +) / Float(hex.count)
            let hy = plinthH * 0.6 + bodyH * 0.58
            func handle(_ a: V2, _ b: V2, fractions: [Float], barLen: Float) {
                let e = b - a, len = simd_length(e), u2 = e / len
                var n2 = V2(u2.y, -u2.x)
                if simd_dot(n2, ((a + b) / 2) - cx) < 0 { n2 = -n2 }
                let u = V3(u2.x, 0, -u2.y), n = V3(n2.x, 0, -n2.y)
                let outQ = simd_quatf(from: V3(0, 1, 0), to: n)
                for f in fractions {
                    let c2 = a + e * f
                    let c = V3(c2.x, hy, -c2.y)
                    let yaw = atan2(-u.z, u.x)
                    m.add(Prim.roundedBox(V3(barLen + 0.07, 0.05, 0.018), radius: 0.005, bevelSegments: bs, material: wood),
                          Xform(translation: c + n * 0.006, rotation: simd_quatf(angle: yaw, axis: V3(0, 1, 0))))
                    let hw = barLen / 2
                    let path = catmull([c + n * 0.014 + u * -hw, c + n * 0.034 + u * -hw * 0.96, c + n * 0.044 + u * -hw * 0.55,
                                        c + n * 0.046, c + n * 0.044 + u * hw * 0.55, c + n * 0.034 + u * hw * 0.96, c + n * 0.014 + u * hw],
                                       per: l == 0 ? 4 : 2)
                    m.add(Prim.tube(path, radii: path.map { _ in 0.0075 }, sides: l == 0 ? 16 : 8, seamTile: 0.04, material: brass))
                    for s in [Float(-1), 1] {
                        m.add(Prim.cylinder(radius: 0.0125, height: 0.012, bevel: 0.003, segments: l == 0 ? 24 : 12, bevelSegments: 2, material: brass),
                              Xform(translation: c + n * 0.014 + u * (s * hw), rotation: outQ))
                    }
                }
            }
            handle(hex[1], hex[2], fractions: [0.26, 0.5, 0.74], barLen: 0.17)
            handle(hex[4], hex[3], fractions: [0.26, 0.5, 0.74], barLen: 0.17)
            handle(hex[2], hex[3], fractions: [0.5], barLen: 0.12)
            handle(hex[5], hex[0], fractions: [0.5], barLen: 0.12)
            groundAO(&m, height: 0.12, floor: 0.7)
            levels.append(m)
        }
        return LODModel(levels: levels, switchDistances: [6])
    }
}
