import simd
import Foundation

/// Milk jug: half-gallon blow-moulded HDPE jug, 10 cm square body with superellipse corners, 25 cm tall
/// with a hollow handle on the right shoulder. Grip ribs above the base and below the shoulder, a recessed
/// front label panel carrying a printed gloss label (invented brand CLOVA), a push-up base with a pinch-off
/// seam, a support ledge on the neck, and a knurled snap cap over a ribbed tamper band. Milk fills the jug
/// to the shoulder and shows through the translucent plastic. A dent sits low on the front.
public struct MilkJug: RealAsset {
    public static let id = "milk-jug"
    public static let summary = "Half-gallon HDPE milk jug: hollow handle, grip ribs, printed label, knurled cap, milk fill."
    public static let tags = ["prop", "interior", "pantry", "plastic"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 18, distance: 1.1, studio: true)

    /// Translucent jug plastic.
    public var hdpe: MaterialKey = "pkg.hdpe-milk"
    /// Milk seen through the wall.
    public var milk: MaterialKey = "plastic.matte:F5F4EE"
    /// Cap and tamper band.
    public var capKey: MaterialKey = "plastic.matte:1F5BB5"
    /// Printed front label (brand field tint).
    public var label: MaterialKey = "pkg.carton-gloss:2A62B8"
    /// Wordmark ink.
    public var ink: MaterialKey = "paper.sheet:173E86"
    /// Half width of the square body.
    public var half: Float = 0.05
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, hi: true), make(seed: seed, hi: false)], switchDistances: [4])
    }

    func make(seed: UInt64, hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let segs = hi ? 56 : 28, a = half, n: Float = 3.6
        typealias K = GroceryKit
        // Section half width per height: base roll, two grip grooves low, straight walls, two grooves high, shoulder dome.
        var prof: [(Float, Float, Float)] = [(0.0045, 0.012, 2.2), (0.0035, 0.026, 2.6), (0.0006, 0.04, 3.2), (0.0, 0.0445, 3.4),
                                             (0.003, 0.049, 3.6), (0.009, a, n)]
        for g: Float in [0.024, 0.036] { prof += [(g - 0.003, a, n), (g, a - 0.0018, n), (g + 0.003, a, n)] }
        prof += [(0.041, a, n), (0.08, a, n), (0.12, a, n), (0.166, a, n)]
        for g: Float in [0.172, 0.182] { prof += [(g - 0.003, a, n), (g, a - 0.0018, n), (g + 0.003, a, n)] }
        prof += [(0.19, a * 0.985, 3.4), (0.198, a * 0.93, 3.0), (0.205, a * 0.8, 2.6), (0.211, a * 0.6, 2.2), (0.2155, 0.0225, 2.0), (0.2175, 0.0215, 2.0)]
        if !hi { prof = prof.enumerated().filter { $0.offset % 2 == 0 || $0.offset == prof.count - 1 }.map(\.element) }
        let rings = prof.map { K.seRing($0.1, $0.1, $0.2, y: $0.0, segs: segs) }
        var body = Prim.loft(rings, capStart: true, material: hdpe)
        // Recessed label panel front and back, a dent low on the front, faint flow lines.
        func panel(_ p: V3) -> Float {
            let fx = 1 - smoothstep(0.039, 0.043, abs(p.x)), fy = smoothstep(0.042, 0.046, p.y) * (1 - smoothstep(0.163, 0.167, p.y))
            return fx * fy * (abs(p.z) > 0.03 ? 1 : 0)
        }
        body.displace { p, nn in
            let dent = -0.0016 * exp(-(pow(p.x + 0.018, 2) + pow(p.y - 0.03, 2)) / 0.00012) * (nn.z > 0.5 ? 1 : 0)
            return -0.0011 * panel(p) + dent + 0.00008 * sin(p.y * 900 + sin(p.x * 60) * 3)
        }
        m.add(body)
        // Milk up to the shoulder; the empty headspace reads lighter.
        let fill = [(0.006, 0.042), (0.012, a - 0.0035), (0.193, a * 0.95)].map { K.seRing($0.1, $0.1, n, y: $0.0, segs: 24) }
        m.add(Prim.loft(fill, capStart: true, capEnd: true, material: milk))
        // Pinch-off seam across the push-up base.
        m.add(Prim.roundedBox(V3(0.02, 0.0012, 0.0018), radius: 0.0005, bevelSegments: 1, material: hdpe), Xform(translation: V3(0, 0.0048, 0)))
        // Neck: support ledge, threads hidden by the cap.
        m.add(Prim.lathe([V2(0.0212, 0.217), V2(0.0242, 0.2178), V2(0.0244, 0.2196), V2(0.0212, 0.2202), V2(0.0198, 0.2205), V2(0.0198, 0.223)],
                         segments: segs, seamTile: 0.05, material: hdpe))
        // Tamper band with bridge slots, then the knurled cap.
        var band = Prim.lathe([V2(0.0204, 0.2204), V2(0.0212, 0.2204), V2(0.0212, 0.2236), V2(0.0204, 0.2238)], segments: hi ? 72 : 24, seamTile: 0.05, material: capKey)
        if hi { band.displace { p, nn in abs(nn.y) > 0.5 ? 0 : -0.0003 * smoothstep(0.85, 0.95, cos(atan2(p.z, p.x) * 12)) } }
        m.add(band)
        m.add(K.knurledCap(r: 0.0212, h: 0.0215, y0: 0.2242, ribs: hi ? 40 : 14, depth: 0.0005, capKey))
        // Hollow handle: a rounded-rect tube from the shoulder out and down into the upper wall.
        let path = catmull([V3(0.03, 0.208, 0), V3(0.052, 0.214, 0), V3(0.078, 0.209, 0), V3(0.093, 0.192, 0), V3(0.094, 0.165, 0),
                            V3(0.082, 0.137, 0), V3(0.062, 0.122, 0), V3(0.044, 0.118, 0)], per: hi ? 5 : 2)
        let sec = Shape2D.roundedRect(0.019, 0.0125, radius: 0.0055, segments: hi ? 3 : 1)
        m.add(Prim.sweep(sec, along: path, up: V3(0, 0, 1), material: hdpe))
        // Printed label in the recess: one design, uniform scale (0.08 x 0.1176 m = tile 0.19 x 0.279).
        let lw: Float = 0.08, lh: Float = 0.1176, ly: Float = 0.046
        func fz(_ x: Float) -> Float { a * pow(max(0, 1 - pow(abs(x / a), n)), 1 / n) - 0.0011 + 0.00045 }
        m.add(K.sheet(cols: 20, rows: 2, uSpan: 0.19, vSpan: 0.19 * 1.47, label) { s, t in
            let x = -lw / 2 + s * lw
            return V3(x, ly + t * lh, fz(x))
        })
        if hi {
            // Mould web where the handle meets the body and grip bumps under the fingers.
            m.add(Prim.superellipsoid(V3(0.02, 0.016, 0.017), exponent: 2.4, subdivisions: 5, material: hdpe), Xform(translation: V3(0.046, 0.12, 0)))
            for k in 0..<4 {
                let p = path[min(path.count - 1, 14 + k * 3)]
                m.add(Prim.superellipsoid(V3(0.004, 0.003, 0.013), exponent: 2.6, subdivisions: 3, material: hdpe),
                      Xform(translation: p + V3(-0.005, 0, 0)))
            }
            // Wordmark on the logo pill (design 0.70, 0.85) and the product line below it.
            K.printSmooth(&m, "CLOVA", height: 0.0085, at: V3(-lw / 2 + 0.7 * lw, ly + 0.815 * lh, fz(0.016) + 0.0004), ink, maxWidth: 0.031, weight: 1.25)
            K.printSmooth(&m, "WHOLE MILK", height: 0.005, at: V3(-lw / 2 + 0.69 * lw, ly + 0.705 * lh, fz(0.016) + 0.0004), ink, maxWidth: 0.034, weight: 1.1)
            // Inkjet date code on the shoulder.
            K.printSmooth(&m, "EXP 11 24", height: 0.0032, at: V3(0, 0.1905, a * 0.985 + 0.0003), "paper.sheet:2A2A2E",
                          rot: simd_quatf(angle: -0.25, axis: V3(1, 0, 0)), maxWidth: 0.03, weight: 0.8)
        }
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y, 0)))
        groundAO(&m, height: 0.04, floor: 0.7)
        _ = seed
        return m
    }
}
