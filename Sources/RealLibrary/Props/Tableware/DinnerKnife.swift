import simd
import Foundation

/// Stainless dinner knife, 23 cm: a rounded wedge blade (thick spine, thin honed edge, rounded tip) joined to a
/// bolster collar and a thick oval handle with a swollen end. The handle is fingerprint smudged, the blade carries
/// fine scratches and a dishwasher rust fleck beside the bolster.
public struct DinnerKnife: RealAsset {
    public static let id = "dinner-knife"
    public static let summary = "Stainless dinner knife, 23 cm: rounded wedge blade, bolster, oval handle, smudged finish, scratches and a rust fleck."
    public static let tags = ["prop", "interior", "tableware", "metal", "handheld"]
    public static let budget = 8000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 40, studio: true)

    /// Blade steel.
    public var blade: MaterialKey = "metal.stainless"
    /// Handle steel with fingerprint smudges.
    public var handle: MaterialKey = "metal.stainless-smudged"
    /// Scratch lines.
    public var polish: MaterialKey = "metal.mirror-polish"
    public init() {}

    static let len: Float = 0.23

    func level(detail: Bool) -> Model {
        var rng = SeededRNG(seed: 91)
        var m = Model(name: Self.id)
        let c = Self.len / 2
        // Handle: thick oval plate with rounded edges, swelling toward the end.
        func hw(_ s: Float) -> Float {
            if s < 0.026 { return 0.0098 * sqrt(max(0, 1 - pow((0.026 - s) / 0.026, 2))) }
            return 0.0098 - 0.0034 * DD1GWare.smooth(0.040, 0.118, s)
        }
        let hOut = DD1GWare.blank(hw, from: 0, to: 0.118, step: 0.004).map { V2($0.x, $0.y - c) }
        var h = DD1GWare.plate(hOut, thick: 0.0098, bevel: 0.0040, material: handle)
        h.deform { p in V3(p.x, p.y + 0.0049, p.z) }
        m.add(h)
        // Raised ridge down the handle and water spots.
        let ridge = DD1GWare.blank({ s in 0.0010 * sin(.pi * (s - 0.026) / 0.080) }, from: 0.026, to: 0.106, step: 0.004).map { V2($0.x, $0.y - c) }
        var rs = DD1GWare.plate(DD1GWare.densify(ridge, max: 0.004), thick: 0.0006, bevel: 0.00025, material: polish)
        rs.deform { p in V3(p.x, p.y + 0.0099, p.z) }
        m.add(rs)
        for _ in 0..<(detail ? 8 : 0) {
            let s = rng.float(0.032...0.100)
            m.add(Prim.cylinder(radius: rng.float(0.0006...0.0013), height: 0.0001, bevel: 0.00005, segments: 8, material: polish),
                  Xform(translation: V3(rng.float(-0.0035...0.0035), 0.0099, s - c)))
        }
        // Bolster collar.
        m.add(Prim.roundedBox(V3(0.0130, 0.0074, 0.0160), radius: 0.0026, bevelSegments: 2, material: "metal.stainless"),
              Xform(translation: V3(0, 0.0037, 0.1195 - c)))
        // Blade: spine on +X, belly curving to a rounded tip; wedge section thinning toward the edge.
        let edge: [V2] = [V2(0.0060, 0.2270), V2(0.0035, 0.2300), V2(-0.0010, 0.2275), V2(-0.0060, 0.2185), V2(-0.0095, 0.2000),
                          V2(-0.0105, 0.1700), V2(-0.0098, 0.1400), V2(-0.0080, 0.1250), V2(-0.0065, 0.1120)]
        let bOut = DD1GWare.densify([V2(0.0065, 0.1120), V2(0.0065, 0.2200)] + edge, max: 0.006).map { V2($0.x, $0.y - c) }
        var b = DD1GWare.plate(bOut, thick: 0.0030, bevel: 0.0010, material: blade)
        b.deform { p in
            // Wedge: full thickness at the spine (x = +0.0065), 35% at the edge.
            let k = 0.35 + 0.65 * DD1GWare.smooth(-0.0105, 0.0065, p.x)
            return V3(p.x, p.y * k + 0.0015, p.z)
        }
        m.add(b)
        // Honed edge: a thin polished bevel strip along the cutting edge.
        let ed = edge.filter { $0.y >= 0.1200 && $0.y < 0.2295 }.reversed()
        let honed = DD1GWare.densify(ed.map { V2($0.x + 0.0016, $0.y - c) } + ed.reversed().map { V2($0.x, $0.y - c) }, max: 0.006)
        var hs = DD1GWare.plate(honed, thick: 0.0003, bevel: 0.0001, material: polish)
        hs.deform { p in
            let k = 0.35 + 0.65 * DD1GWare.smooth(-0.0105, 0.0065, p.x)
            return V3(p.x, 0.0015 * k + 0.0015 + 0.00015, p.z)
        }
        m.add(hs)
        // Dried yolk smear near the tip and a cluster of rust specks.
        m.add(DD1GWare.blob(V3(0.0058, 0.00028, 0.0130), exponent: 3, subdivisions: 3, material: "food.egg-curd:E4D6A4"),
              Xform(translation: V3(-0.0006, 0.0031, 0.2000 - c), rotation: simd_quatf(degrees: 8, axis: V3(0, 1, 0))))
        // Hairline scratches on the blade.
        for _ in 0..<(detail ? 9 : 0) {
            let s = rng.float(0.135...0.205), x = rng.float(-0.006...0.004)
            m.add(Prim.roundedBox(V3(0.0003, 0.00012, rng.float(0.008...0.026)), radius: 0.00005, bevelSegments: 1, material: polish),
                  Xform(translation: V3(x, 0.00315, s - c), rotation: simd_quatf(degrees: rng.float(-6...6), axis: V3(0, 1, 0))))
        }
        // Rust fleck beside the bolster.
        for (dx, ds, r) in [(Float(-0.0030), Float(0.1340), Float(0.0019)), (-0.0052, 0.1385, 0.0011), (0.0005, 0.1410, 0.0013), (-0.0018, 0.1295, 0.0008)] {
            m.add(Prim.cylinder(radius: r, height: 0.00012, bevel: 0.00005, segments: 10, material: "metal.rust-grime"),
                  Xform(translation: V3(dx, 0.00305, ds - c)))
        }
        m.add(Prim.cylinder(radius: 0.0006, height: 0.00012, bevel: 0.00005, segments: 8, material: "metal.rust-grime"),
              Xform(translation: V3(-0.0010, 0.00305, 0.1385 - c)))
        DD1GWare.plant(&m)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        _ = seed
        return LODModel(levels: [level(detail: true), level(detail: false)], switchDistances: [1.5])
    }
}
