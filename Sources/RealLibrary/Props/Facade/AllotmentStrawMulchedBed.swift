import simd
import Foundation

/// English allotment raised bed, 2 x 2 m: four treated softwood edging boards (22 x 150 mm) on square
/// corner and mid pegs with galvanised nails, filled with tilled soil heaped to a low crown and mulched
/// with loose wheat straw: a matted straw layer with gaps showing soil, hundreds of individual kinked
/// stalks on top and a few blown over the boards onto the trodden verge.
public struct AllotmentStrawMulchedBed: RealAsset {
    public static let id = "allotment-straw-mulched-bed"
    public static let summary = "Allotment bed 2 x 2 m: soil heaped inside softwood edging boards, mulched with loose wheat straw stalks, corner stakes nailed."
    public static let tags = ["prop", "architecture", "facade", "ground", "wood"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 2.6, studio: true)

    /// Tile size in meters (x, max height, z).
    public var size = V3(2.0, 0.2, 2.0)
    /// Board inset from the tile edge (m).
    public var inset: Float = 0.06
    /// Board top height (m).
    public var boardTop: Float = 0.178
    /// Soil crown height (m).
    public var soilTop: Float = 0.145
    /// Number of loose straw stalks.
    public var stalks: Int = 150
    /// Straw material.
    public var straw: MaterialKey = "straw.hay"
    /// Soil material.
    public var soil: MaterialKey = "soil.potting"
    /// Verge material.
    public var verge: MaterialKey = "ground.dirt"
    /// Board material.
    public var wood: MaterialKey = "wood.weathered:6E6A4E"
    /// Nail material.
    public var nail: MaterialKey = "metal.galvanized-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(rng.int(0...50_000))
        let w = size.x, d = size.z
        let hx = w / 2 - inset, hz = d / 2 - inset
        var m = Model(name: Self.id)
        // Trodden verge around the bed.
        GK.field(&m, w: w, d: d, edge: 0.025, segments: 20, verge) { p in 0.004 * Noise.fbm(V3(p.x * 4, 0, p.y * 4), octaves: 2, seed: sd) }
        // Bed soil: crowned, tilled ridges along X.
        func soilH(_ p: V2) -> Float {
            let e = min(hx - abs(p.x), hz - abs(p.y))
            let k = max(0, min(1, e / 0.15))
            return soilTop - 0.03 + 0.03 * k + 0.006 * sin(p.y * 28) * k + 0.008 * Noise.fbm(V3(p.x * 4, 0, p.y * 4), octaves: 3, seed: sd + 1)
        }
        var bed = Prim.terrain(size: V2(2 * hx - 0.026, 2 * hz - 0.026), segments: 32, material: soil) { soilH($0) }
        bed.uvs = bed.positions.map { V2($0.x, $0.z) }; bed.computeTangents()
        m.add(bed)
        // Matted straw layer: a sheet that rises above the soil where the straw lies thick and sinks
        // under it in thin spots, so bare soil shows through in soft-edged gaps.
        func strawH(_ p: V2) -> Float {
            let nz = Noise.fbm(V3(p.x * 3.5, 0, p.y * 3.5), octaves: 3, seed: sd + 4)
            return soilH(p) + 0.03 * (nz + 0.15) + 0.004 * Noise.fbm(V3(p.x * 20, 0, p.y * 20), octaves: 2, seed: sd + 5)
        }
        var mat = Prim.terrain(size: V2(2 * hx - 0.04, 2 * hz - 0.04), segments: 30, material: straw) { strawH($0) }
        mat.uvs = mat.positions.map { V2($0.x, $0.z) }; mat.computeTangents()
        m.add(mat)
        // Loose stalks lying on the mat; a few blown onto the verge.
        var st = Surface(material: straw)
        for k in 0..<stalks {
            var r = rng.fork(100 + k)
            let blown = k < 14
            let q = blown ? V2(r.float(-0.8...0.8), (r.chance(0.5) ? 1 : -1) * r.float((hz + 0.03)...(hz + 0.04)))
                          : V2(r.float(-hx + 0.13...hx - 0.13), r.float(-hz + 0.13...hz - 0.13))
            let y = blown ? 0.027 : max(soilH(q), strawH(q)) + 0.003 + r.float(0...0.012)
            st.append(PBK.stalk(at: V3(q.x, y, q.y), length: blown ? r.float(0.04...0.07) : r.float(0.08...0.2), yaw: blown ? r.float(-0.25...0.25) + (r.chance(0.5) ? 0 : .pi) : r.float(0...(2 * .pi)), pitch: r.float(-0.08...0.12), rng: &r, material: straw))
        }
        st.computeTangents()
        m.add(st)
        // Edging boards: X boards run full length, Z boards butt between them; pegs inside corners and mid-span.
        let t: Float = 0.022, bh: Float = 0.15
        var r0 = rng.fork(7)
        PBK.edging(&m, V2(-hx, -hz), V2(hx, -hz), top: boardTop, height: bh, thick: t, pegSide: 1, pegEvery: 0.9, wood: wood, nail: nail, rng: &r0)
        PBK.edging(&m, V2(hx, hz), V2(-hx, hz), top: boardTop, height: bh, thick: t, pegSide: 1, pegEvery: 0.9, wood: wood, nail: nail, rng: &r0)
        PBK.edging(&m, V2(-hx, hz - t), V2(-hx, -hz + t), top: boardTop, height: bh, thick: t, pegSide: 1, pegEvery: 1.6, wood: wood, nail: nail, rng: &r0)
        PBK.edging(&m, V2(hx, -hz + t), V2(hx, hz - t), top: boardTop, height: bh, thick: t, pegSide: 1, pegEvery: 1.6, wood: wood, nail: nail, rng: &r0)
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2)))
        groundAO(&m, height: 0.06, floor: 0.6)
        var lite = Model(name: Self.id + "-lite")
        GK.field(&lite, w: w, d: d, edge: 0.025, segments: 8, verge) { _ in 0 }
        lite.add(Prim.terrain(size: V2(2 * hx, 2 * hz), segments: 10, material: straw) { soilH($0) + 0.01 })
        for s: Float in [-1, 1] {
            GK.box(&lite, V3(0, boardTop - bh / 2, s * hz), V3(2 * hx, bh, t), wood)
            GK.box(&lite, V3(s * hx, boardTop - bh / 2, 0), V3(t, bh, 2 * hz), wood)
        }
        return LODModel(levels: [m, lite], switchDistances: [8])
    }
}
