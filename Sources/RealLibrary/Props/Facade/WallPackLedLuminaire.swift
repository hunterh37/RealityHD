import simd
import Foundation

/// LED wall pack: architectural facade customizer, Commercial. Die-cast aluminum housing with a finned heat sink
/// on top, forward-throw prismatic lens in a gasketed bezel on eight screws, hooded visor, wall plate on four
/// bolts and a threaded conduit knockout plug. Bronze powder coat has chalked and the fins collect dust.
public struct WallPackLedLuminaire: RealAsset {
    public static let id = "wall-pack-led-luminaire"
    public static let summary = "Commercial LED wall pack, 0.35 m: finned die cast housing, visor and prismatic lens."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 18, distance: 1.1)

    /// Housing powder coat.
    public var coat: MaterialKey = "metal.painted:4A4338"
    /// Lens.
    public var lens: MaterialKey = "glass.polycarbonate"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 0.35, H: Float = 0.2
        let steel: MaterialKey = "metal.screw-zinc", cast: MaterialKey = "metal.diecast", grime: MaterialKey = "metal.rust-grime"
        // Wall plate with gasket, four bolts, knockout plug on the underside.
        FA.box(&m, V3(W - 0.01, H - 0.01, 0.006), V3(0, H / 2, 0.003), coat, r: 0.002)
        FA.box(&m, V3(W - 0.03, H - 0.03, 0.003), V3(0, H / 2, 0.0075), "rubber.seal", r: 0.001)
        for sx: Float in [-1, 1] { for sy: Float in [-1, 1] { FSV.bolt(&m, at: V3(sx * (W / 2 - 0.016), H / 2 + sy * (H / 2 - 0.016), 0.006), normal: FA.Z, size: 0.011, material: steel) } }
        // Main housing: flat back, deep hood over the lens, extruded along X.
        let prof: [V2] = [V2(0.006, 0.012), V2(0.006, H - 0.012), V2(0.02, H), V2(0.188, H), V2(0.2, H - 0.01), V2(0.2, 0.172), V2(0.138, 0.168), V2(0.138, 0.034), V2(0.122, 0.012), V2(0.02, 0.0)]
        FA.run(&m, prof, length: W - 0.02, at: V3(0, 0, 0), coat, bevel: 0.0025)
        // Cheek blocks at each end and a drip lip along the hood edge.
        for s: Float in [-1, 1] { FA.box(&m, V3(0.012, H - 0.02, 0.13), V3(s * (W / 2 - 0.012), H / 2, 0.072), coat, r: 0.004) }
        FA.box(&m, V3(W - 0.03, 0.005, 0.006), V3(0, H - 0.0225, 0.2 - 0.003), coat, r: 0.0015)
        // Heat-sink fins on top, running front to back.
        let n = 15
        for i in 0..<n {
            let x = -W / 2 + 0.034 + Float(i) * (W - 0.068) / Float(n - 1)
            FA.box(&m, V3(0.0032, 0.008, 0.15), V3(x, H + 0.002, 0.1), cast, r: 0.0008)
        }
        // Lens bezel on the front face under the hood, tilted down: frame, gasket, prismatic lens, ridges, screws.
        let nose = V3(0, 0.1, 0.143), q = FA.q(10, FA.X)
        let nz = q.act(FA.Z), ny = q.act(FA.Y)
        FA.box(&m, V3(0.318, 0.12, 0.014), nose + nz * 0.0, coat, r: 0.003, rot: q)
        FA.box(&m, V3(0.292, 0.094, 0.004), nose + nz * 0.0085, "rubber.seal", r: 0.0006, rot: q)
        FA.box(&m, V3(0.284, 0.086, 0.006), nose + nz * 0.0105, lens, r: 0.001, rot: q)
        for k in 0..<18 {
            FA.box(&m, V3(0.282, 0.0016, 0.0016), nose + nz * 0.0148 + ny * (-0.038 + Float(k) * 0.0045), lens, r: 0.0004, rot: q)
        }
        for k in 0..<4 { for s: Float in [-1, 1] {
            FSV.screw(&m, at: nose + nz * 0.007 + ny * (s * 0.053) + V3(-0.14 + Float(k) * 0.093, 0, 0), normal: nz, r: 0.0034, steel)
        } }
        // Bracket ribs under the hood.
        for s: Float in [-1, 1] { FA.box(&m, V3(0.006, 0.016, 0.06), V3(s * 0.15, 0.176, 0.168), coat, r: 0.0015) }
        // Conduit knockout plug and photo-control window.
        m.add(Prim.cylinder(radius: 0.014, height: 0.012, bevel: 0.0015, segments: 16, bevelSegments: 1, material: cast), Xform(translation: V3(0.08, 0.0, 0.032)))
        FSV.cyl(&m, V3(-0.07, 0.02, 0.03), V3(-0.07, 0.012, 0.03), r: 0.006, cast, bevel: 0.001, segments: 10)
        // Wear: chalk bloom on the visor, dust in the fins, drips under the bolts.
        FA.box(&m, V3(0.12, 0.0015, 0.05), V3(0.05, H + 0.0008, 0.17), "metal.painted:8C8578", r: 0.0003)
        FA.box(&m, V3(W - 0.07, 0.0016, 0.06), V3(0, H + 0.0008, 0.04), "metal.painted:5A5448", r: 0.0003)
        for sx: Float in [-1, 1] {
            FSV.streak(&m, at: V3(sx * (W / 2 - 0.016), 0.016 - 0.004, 0.0075), w: 0.004, h: 0.01, "metal.painted:2E2A24")
        }
        for _ in 0..<3 { FSV.streak(&m, at: V3(rng.float(-0.14...0.14), 0.168, 0.2 - 0.001), w: 0.006, h: rng.float(0.01...0.03), "metal.painted:2E2A24") }
        return LODModel(FC.seatY(m))
    }
}
