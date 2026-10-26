import simd
import Foundation

/// Historic cast iron bollard: architectural facade customizer, Victorian. Moulded base ring, fluted shaft,
/// raised lettering band, shoulder collar and a domed cap with a button; paint chipped to rust at the foot.
public struct BollardCastIronHistoric: RealAsset {
    public static let id = "bollard-cast-iron-historic"
    public static let summary = "Historic cast iron bollard 0.9 m: moulded base, fluted shaft with a raised lettering band, shoulder collar and domed cap."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 12, distance: 2.0)

    /// Painted upper casting.
    public var paint: MaterialKey = "metal.wrought-iron"
    /// Weathered lower casting.
    public var castIron: MaterialKey = "metal.cast-iron-street"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let lower: [V2] = [V2(0, 0), V2(0.122, 0), V2(0.122, 0.02), V2(0.112, 0.03), V2(0.119, 0.04), V2(0.119, 0.055), V2(0.105, 0.066), V2(0.098, 0.09),
                           V2(0.096, 0.2), V2(0.095, 0.35), V2(0, 0.35)]
        FE.turnDisp(&m, lower, castIron, segments: 80) { p in
            if p.y < 0.1 { return 0 }
            let a = atan2(p.z, p.x)
            return -0.004 * (0.5 + 0.5 * cos(12 * a)) * min(1, (p.y - 0.1) / 0.03)
        }
        let upper: [V2] = [V2(0, 0.35), V2(0.095, 0.35), V2(0.095, 0.5), V2(0.1, 0.505), V2(0.112, 0.515), V2(0.114, 0.53), V2(0.114, 0.6), V2(0.112, 0.615), V2(0.1, 0.625),
                           V2(0.096, 0.64), V2(0.096, 0.69), V2(0.108, 0.7), V2(0.115, 0.715), V2(0.108, 0.73), V2(0.1, 0.74), V2(0.099, 0.76), V2(0.094, 0.79), V2(0.08, 0.83),
                           V2(0.058, 0.86), V2(0.03, 0.88), V2(0.02, 0.885), V2(0.022, 0.892), V2(0.014, 0.9), V2(0, 0.9)]
        FE.turnDisp(&m, upper, paint, segments: 80) { p in
            if p.y > 0.5 || p.y < 0.36 { return 0 }
            let a = atan2(p.z, p.x)
            return -0.004 * (0.5 + 0.5 * cos(12 * a)) * min(1, (0.5 - p.y) / 0.03)
        }
        // Raised lettering band: block capitals cast on the wide band, with letter width and height varying.
        let n = 22
        for k in 0..<n {
            let a = Float(k) / Float(n) * 2 * .pi
            let w = rng.float(0.011...0.018)
            FA.box(&m, V3(w, rng.float(0.032...0.04), 0.0045), V3(0.1145 * cos(a), 0.565, 0.1145 * sin(a)), paint, r: 0.0008, rot: FA.q(-a * 180 / .pi + 90, FA.Y))
        }
        // Rust weeping from the band edges, the shoulder and the lifting boss, as thin vertical streaks.
        for k in 0..<16 {
            let a = rng.float(0...(2 * .pi))
            let tops: [(Float, Float)] = [(0.53, 0.1135), (0.505, 0.099), (0.7, 0.109), (0.64, 0.0965)]
            let (top, r) = tops[k % 4]
            let hgt = rng.float(0.03...0.11)
            FA.box(&m, V3(rng.float(0.007...0.016), hgt, 0.0012), V3((r + 0.0004) * cos(a), top - hgt / 2, (r + 0.0004) * sin(a)), "metal.rust", r: 0.0004, rot: FA.q(-a * 180 / .pi + 90, FA.Y))
        }
        // Bare-iron chips on the base ring edge.
        for _ in 0..<6 {
            let a = rng.float(0...(2 * .pi))
            FA.box(&m, V3(rng.float(0.012...0.024), 0.006, 0.004), V3(0.1195 * cos(a), 0.06, 0.1195 * sin(a)), "metal.cast-iron-street", r: 0.001, rot: FA.q(-a * 180 / .pi + 90, FA.Y))
        }
        // Rope-lay bolt heads: four anchor bolts at the base flange are hidden; show a lifting eye boss on the cap.
        FA.box(&m, V3(0.02, 0.012, 0.02), V3(0, 0.903, 0), castIron, r: 0.003)
        FE.stain(&m, V3(0, 0.0205, 0), w: 0.24, d: 0.24, "metal.rust")
        m = FE.seat(m)
        groundAO(&m, height: 0.1, floor: 0.6)
        return LODModel(m)
    }
}
