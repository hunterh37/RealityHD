import simd
import Foundation

/// Bed of wild celery (Vallisneria americana), ~1.2 m across: 3 to 6 rosettes of 12 to 22 ribbon leaves,
/// 0.5 to 1.1 m long and 6 to 12 mm wide, rising from the silt and streaming downstream (+X) in the current.
/// Leaves sway with the shader wind. 2 LODs.
public struct EelgrassBed: RealAsset {
    public static let id = "eelgrass-bed"
    public static let summary = "Wild celery bed, ~1.2 m: rosettes of long ribbon leaves rising from the riverbed and streaming downstream, 2 LODs."
    public static let tags = ["nature", "plant", "grass", "water", "river"]
    public static let budget = 6_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 18, distance: 1.0)

    public var radius: Float = 0.6
    public var rosettes: ClosedRange<Int> = 4...6
    public var leaves: ClosedRange<Int> = 16...24
    public var height: Float = 0.9
    /// How far the current lays the leaves over toward +X (0 upright, 1 nearly flat at the tips).
    public var streaming: Float = 0.8
    public var material: MaterialKey = "grass.eelgrass"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let phase = rng.float(0...6.28)
        var m0 = Model(name: Self.id), m1 = Model(name: Self.id)
        let n = rng.int(rosettes)
        let h = height * rng.vary(1, 0.12)
        let lay = streaming
        func stream(_ s: inout Surface) {
            s.deform { p in
                let t = max(0, p.y) / max(h, 0.1)
                let bend = lay * t * t
                return V3(p.x + h * bend * 0.9, p.y * (1 - 0.45 * bend), p.z + 0.06 * sin(p.y * 7 + p.x * 3))
            }
        }
        for k in 0..<n {
            let c = k == 0 ? V2.zero : rng.inDisc(radius: radius * 0.75)
            var t = PlantKit.Tuft()
            t.count = rng.int(leaves); t.height = h * rng.float(0.7...1.1); t.heightRange = 0.55...1
            t.radius = 0.07; t.width = 0.012...0.022
            t.lean = 0.02...0.15; t.splay = 0.2; t.curl = 0.0...0.25; t.twist = 1.4
            var r0 = rng.fork(k + 1), r1 = rng.fork(k + 1)
            t.segments = 5
            var s0 = PlantKit.tuft(t, at: V3(c.x, 0, c.y), rng: &r0, material: material, phase: phase)
            t.segments = 3
            var s1 = PlantKit.tuft(t, at: V3(c.x, 0, c.y), rng: &r1, material: material, phase: phase)
            stream(&s0); stream(&s1)
            m0.add(s0); m1.add(s1)
        }
        PlantKit.finish(&m0); PlantKit.finish(&m1)
        return LODModel(levels: [m0, m1], switchDistances: [12])
    }
}
