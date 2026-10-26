import simd
import Foundation

/// Cattle guard grate: architectural facade customizer, Rural. Parts: pipe rails, end frames, concrete footings, wing rails, weld beads, support beams, pit.
public struct CattleGuardGrate: RealAsset {
    public static let id = "cattle-guard-grate"
    public static let summary = "Rural cattle guard, welded steel pipe rails spanning a pit on concrete footings."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(3.0, 0.2, 2.4)
    public init() {}

    /// Galvanised pipe rails (aged).
    public var pipe: MaterialKey = "metal.galvanized-aged"
    /// Oxidised rails, mixed in at random.
    public var rusted: MaterialKey = "metal.rust"
    /// Polished wheel tracks on the rail crowns.
    public var polished: MaterialKey = "metal.steel"
    /// Concrete footings and wing curbs.
    public var concrete: MaterialKey = "concrete.rough"
    /// Pit floor seen between the rails.
    public var pitFloor: MaterialKey = "asphalt.worn"
    /// Rail pitch across the travel direction, meters.
    public var pitch: Float = 0.15

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y, D = size.z
        let r: Float = 0.05, railY = H - r                     // 100 mm pipe, crown at H
        let bx: Float = W / 2 - 0.3                             // support beam centre x
        // Pit floor between the footings, dark so the gaps read as depth.
        FGate.slab(&m, V3(2 * bx - 0.2, D - 0.1, 0.01), V3(0, 0.005, 0), pitFloor, rot: FA.q(-90, FA.X))
        for sx in [-1, 1] as [Float] {
            // Concrete footing under each support beam, chamfered and with a spalled corner.
            FA.box(&m, V3(0.34, 0.05, D), V3(sx * bx, 0.025, 0), concrete, r: 0.006)
            FA.box(&m, V3(0.1, 0.02, 0.14), V3(sx * (bx + 0.12), 0.045, -D / 2 + 0.08), "concrete.smooth", r: 0.004, rot: FA.q(14, FA.Y))
            // Hollow-section steel beam along Z with end plates and bolted stiffeners.
            FA.box(&m, V3(0.16, 0.05, D - 0.06), V3(sx * bx, 0.075, 0), "metal.rust-grime", r: 0.003)
            for ez in [-1, 1] as [Float] {
                FA.box(&m, V3(0.18, 0.06, 0.01), V3(sx * bx, 0.08, ez * (D / 2 - 0.025)), "metal.galvanized-aged", r: 0.002)
                for bxo in [-0.06, 0.06] as [Float] { FGate.slab(&m, V3(0.014, 0.014, 0.004), V3(sx * bx + bxo, 0.094, ez * (D / 2 - 0.02)), "metal.steel") }
            }
            // Anchor plates and nuts into the footing.
            for z in [-D / 3, 0, D / 3] as [Float] {
                FA.box(&m, V3(0.22, 0.008, 0.06), V3(sx * bx, 0.054, z), "metal.galvanized-aged", r: 0.002)
            }
        }
        // Pipe rails across the travel direction, welded to both beams; 15 rails at 150 mm pitch.
        let n = Int((D - 0.1) / pitch)
        let z0 = -Float(n - 1) * pitch / 2
        for k in 0..<n {
            var rr = rng.fork(k)
            let z = z0 + Float(k) * pitch
            let mat = rr.chance(0.2) ? rusted : pipe
            FA.cylX(&m, r: r, h: W - 0.26, at: V3(-W / 2 + 0.13, railY, z), mat, bevel: 0.004, segments: 14)
            // Weld beads where each rail meets the beams.
            for sx in [-1, 1] as [Float] {
                FA.box(&m, V3(0.06, 0.02, 0.03), V3(sx * bx - 0.07, 0.108, z), "metal.rust-grime", r: 0.004)
                FA.box(&m, V3(0.06, 0.02, 0.03), V3(sx * bx + 0.07, 0.108, z), "metal.rust-grime", r: 0.004)
            }
            // Polished wheel tracks on the crown, stronger on the leading rails.
            if rr.chance(0.85) {
                for sx in [-1, 1] as [Float] {
                    FGate.slab(&m, V3(0.5, 0.036, 0.0015), V3(sx * 0.62, H - 0.0012, z), polished, rot: FA.q(-90, FA.X))
                }
            }
        }
        // Wing walls: cast concrete cheek walls at both ends, flush with the rail crowns, with steel angle caps,
        // bearing seats under the rail ends and a hairline crack.
        for sx in [-1, 1] as [Float] {
            FA.box(&m, V3(0.12, H - 0.004, D), V3(sx * (W / 2 - 0.06), (H - 0.004) / 2, 0), concrete, r: 0.005)
            FA.box(&m, V3(0.13, 0.012, D), V3(sx * (W / 2 - 0.06), H - 0.002, 0), "metal.galvanized-aged", r: 0.002)
            FA.box(&m, V3(0.004, 0.012, D), V3(sx * (W / 2 - 0.12), H - 0.01, 0), "metal.galvanized-aged", r: 0.001)
            FGate.slab(&m, V3(0.003, 0.09, 0.003), V3(sx * (W / 2 - 0.0015), 0.1, 0.6), "metal.rust-grime", rot: FA.q(8, FA.Z))
            FGate.slab(&m, V3(0.003, 0.09, 0.003), V3(sx * (W / 2 - 0.0015), 0.1, -0.8), "metal.rust-grime", rot: FA.q(-6, FA.Z))
            // Rust bleed from the angle cap down the wall.
            for z in [-0.9, -0.2, 0.5, 0.95] as [Float] {
                FGate.slab(&m, V3(0.002, 0.06 + abs(z) * 0.03, 0.02), V3(sx * (W / 2 - 0.0005), H - 0.07, z), "metal.rust-grime")
            }
        }
        // Grit and dried mud tracked onto the rails.
        for k in 0..<7 {
            var rr = rng.fork(60 + k)
            FGate.slab(&m, V3(rr.float(0.1...0.3), rr.float(0.04...0.1), 0.0015), V3(rr.float(-W / 2 + 0.3...W / 2 - 0.3), H - 0.0008, rr.float(-D / 2 + 0.2...D / 2 - 0.2)), "concrete.smooth", rot: FA.q(-90, FA.X))
        }
        groundAO(&m, height: 0.1, floor: 0.5)
        return LODModel(FC.place(m))
    }
}
