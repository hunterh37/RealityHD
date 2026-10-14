import simd
import Foundation

/// English allotment woodchip path, 2 x 2 m: a 0.8 m strip of council arboricultural woodchip running
/// along X, held between two treated softwood edging boards (22 x 95 mm) on square pegs with
/// galvanised nails, with tilled soil verges outside. Chips are heaped in the middle, thinned in the
/// wheel line, and a few have spilled onto the verges.
public struct AllotmentWoodchipPath: RealAsset {
    public static let id = "allotment-woodchip-path"
    public static let summary = "Allotment path 2 x 2 m: woodchip strip between treated edging boards on pegs, soil verges either side."
    public static let tags = ["prop", "architecture", "facade", "ground", "wood"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 2.6, studio: true)

    /// Tile size in meters (x, max height, z).
    public var size = V3(2.0, 0.12, 2.0)
    /// Path width between boards (m).
    public var pathWidth: Float = 0.8
    /// Edging board top height (m).
    public var boardTop: Float = 0.1
    /// Woodchip layer height at the crown (m).
    public var chipTop: Float = 0.085
    /// Loose chips modelled on the surface.
    public var chips: Int = 230
    /// Woodchip material.
    public var mulch: MaterialKey = "mulch.bark"
    /// Verge soil material.
    public var soil: MaterialKey = "soil.potting"
    /// Edging board material.
    public var wood: MaterialKey = "wood.weathered:6E6A4E"
    /// Nail material.
    public var nail: MaterialKey = "metal.galvanized-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(rng.int(0...50_000))
        let w = size.x, d = size.z, hw = pathWidth / 2
        var m = Model(name: Self.id)
        // Soil verges.
        GK.field(&m, w: w, d: d, edge: 0.04, segments: 32, soil) { p in
            0.01 * Noise.fbm(V3(p.x * 3, 0, p.y * 3), octaves: 3, seed: sd) + 0.006 * Noise.ridged(V3(p.x * 12, 0, p.y * 12), octaves: 2, seed: sd + 1)
        }
        // Woodchip bed between the boards: crowned, lumpy, a barrow line slightly lower.
        let lineZ = rng.float(-0.1...0.1)
        func chipH(_ p: V2) -> Float {
            let t = p.y / hw
            let crown = 0.012 * (1 - t * t)
            let line = -0.008 * exp(-pow((p.y - lineZ) / 0.06, 2))
            return chipTop - 0.012 + crown + line + 0.008 * Noise.fbm(V3(p.x * 6, 0, p.y * 6), octaves: 3, seed: sd + 2)
                + 0.004 * Noise.ridged(V3(p.x * 25, 0, p.y * 25), octaves: 2, seed: sd + 3)
        }
        var bed = Prim.terrain(size: V2(w - 0.006, pathWidth - 0.004), segments: 36, material: mulch) { chipH($0) }
        bed.uvs = bed.positions.map { V2($0.x, $0.z) }; bed.computeTangents()
        m.add(bed)
        // Edging boards with pegs outside on the verge.
        for s: Float in [-1, 1] {
            var r = rng.fork(s > 0 ? 11 : 12)
            let z = s * (hw + 0.011)
            PBK.edging(&m, V2(-w / 2 + 0.002, z), V2(w / 2 - 0.002, z), top: boardTop, height: 0.095, thick: 0.022, pegSide: s, pegEvery: 0.95, wood: wood, nail: nail, rng: &r)
        }
        // Loose chips on the bed, plus a few spilled over onto the verges.
        for k in 0..<chips {
            var r = rng.fork(100 + k)
            let spill = k < 18
            let q = spill ? V2(r.float(-0.95...0.95), (r.chance(0.5) ? 1 : -1) * r.float((hw + 0.05)...(hw + 0.2)))
                          : V2(r.float(-0.96...0.96), r.float(-hw + 0.02...hw - 0.02))
            let y = spill ? 0.04 + 0.006 : chipH(q) + 0.002
            let len = r.float(0.035...0.085)
            m.add(Prim.superellipsoid(V3(len, r.float(0.006...0.012), len * r.float(0.25...0.5)), exponent: 3, subdivisions: 1, material: mulch),
                  Xform(translation: V3(q.x, y, q.y), rotation: simd_quatf(degrees: r.float(0...360), axis: .up) * simd_quatf(degrees: r.float(-15...15), axis: V3(1, 0, 0))))
        }
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2)))
        groundAO(&m, height: 0.05, floor: 0.6)
        var lite = Model(name: Self.id + "-lite")
        GK.field(&lite, w: w, d: d, edge: 0.04, segments: 12, soil) { _ in 0 }
        lite.add(Prim.terrain(size: V2(w - 0.006, pathWidth), segments: 8, material: mulch) { chipH($0) })
        for s: Float in [-1, 1] { GK.box(&lite, V3(0, boardTop - 0.0475, s * (hw + 0.011)), V3(w - 0.004, 0.095, 0.022), wood) }
        return LODModel(levels: [m, lite], switchDistances: [8])
    }
}
