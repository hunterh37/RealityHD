import simd
import Foundation

/// Placemat, 45 x 33 cm and under 1 cm thick: plain-weave rattan reed (25 x 18 strands, over and under) on a dark backing,
/// bound at the rim with a rattan cord and tape wraps every 10 mm. One strand end frays at the binding, and a darker
/// scuffed patch sits near the front edge.
public struct Placemat: RealAsset {
    public static let id = "placemat"
    public static let summary = "Rattan placemat, woven: weft strands over warp, bound rim cord, wraps, frayed strand, worn dark scuff near the front edge."
    public static let tags = ["prop", "interior", "tableware", "wood"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 48, distance: 0.95, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.45, 0.01, 0.33)
    /// Strands along X and along Z.
    public var strands = (x: 25, z: 18)
    /// Reed.
    public var reed: MaterialKey = "wood.rattan:B08A55"
    /// Lighter reed lot.
    public var reedLight: MaterialKey = "wood.rattan:C39E64"
    /// Dark backing seen in the gaps.
    public var backing: MaterialKey = "wood.rattan:4A3520"
    /// Edge cord.
    public var cord: MaterialKey = "wood.rattan:8A683A"
    /// Binding wraps.
    public var wrapTape: MaterialKey = "wood.rattan:C09C66"
    /// Sun-faded reed.
    public var faded: MaterialKey = "wood.rattan:BE9A62"
    /// Worn scuffed reed.
    public var scuff: MaterialKey = "wood.hammer-hickory-grimy"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [3])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hx = size.x / 2 - 0.0105, hz = size.z / 2 - 0.0105
        let cx = 2 * hx / Float(strands.x), cz = 2 * hz / Float(strands.z)
        let baseY: Float = 0.0044, amp: Float = 0.0052
        func bump(_ t: Float) -> Float { pow(max(0, 1 - pow(2 * t - 1, 2)), 0.5) }
        func weave(_ x: Float, _ z: Float) -> Float {
            let fx = (x + hx) / cx, fz = (z + hz) / cz
            let i = floor(fx), j = floor(fz)
            let u = fx - i, v = fz - j
            let weftOver = 0.5 + 0.5 * cos(.pi * (fx - 0.5) + .pi * j)
            let warpOver = 0.5 + 0.5 * cos(.pi * (fz - 0.5) + .pi * i + .pi)
            let a = bump(v) * (0.32 + 0.68 * weftOver), b = bump(u) * (0.32 + 0.68 * warpOver)
            return baseY + amp * max(a, b)
        }
        m.add(Prim.roundedBox(V3(size.x - 0.006, 0.0046, size.z - 0.006), radius: 0.0012, bevelSegments: 2, material: backing),
              Xform(translation: V3(0, 0.0023, 0)))
        let k = detail ? 3 : 2
        func weftTop(_ x: Float, _ z: Float) -> Bool {
            let fx = (x + hx) / cx, fz = (z + hz) / cz, i = floor(fx), j = floor(fz)
            return (i + j).truncatingRemainder(dividingBy: 2) == 0
        }
        // Weft-over cells a shade darker than warp-over cells, as two dyed reed lots read in a real mat.
        m.add(DD1HTable.topGrid(nx: strands.x * k, nz: strands.z * k, halfX: hx, halfZ: hz, material: reed, region: { x, z in weftTop(x, z) }, height: weave))
        m.add(DD1HTable.topGrid(nx: strands.x * k, nz: strands.z * k, halfX: hx, halfZ: hz, material: reedLight, region: { x, z in !weftTop(x, z) }, height: weave))
        if detail {
            let c = V2(0.06, 0.1)
            m.add(DD1HTable.topGrid(nx: strands.x * k, nz: strands.z * k, halfX: hx, halfZ: hz, material: scuff,
                                    region: { x, z in pow((x - c.x) / 0.055, 2) + pow((z - c.y) / 0.024, 2) < 1 },
                                    height: { x, z in weave(x, z) + 0.0004 }))
        }
        // Edge cord.
        let cy: Float = 0.0061, cr: Float = 0.0039
        let path = DD1HTable.railPath(w: size.x - 2 * cr, d: size.z - 2 * cr, radius: 0.014, y: cy, segments: detail ? 5 : 3)
        m.add(DD1HTable.bead(path: path, r: cr, sides: detail ? 8 : 6, material: cord))
        if detail {
            // Tape wraps around the cord, every 9.5 mm, skipping the corners.
            let ex = size.x / 2 - cr, ez = size.z / 2 - cr
            for sgn in [Float(-1), 1] {
                var x: Float = -0.195
                while x < 0.2 {
                    m.add(cuboid(V3(0.0024, 2 * cr + 0.0008, 2 * cr + 0.0008), material: wrapTape),
                          Xform(translation: V3(x, cy, sgn * ez), rotation: simd_quatf(degrees: rng.float(-4...4), axis: .up)))
                    x += 0.0095
                }
                var z: Float = -0.135
                while z < 0.14 {
                    m.add(cuboid(V3(2 * cr + 0.0008, 2 * cr + 0.0008, 0.0024), material: wrapTape),
                          Xform(translation: V3(sgn * ex, cy, z), rotation: simd_quatf(degrees: rng.float(-4...4), axis: .up)))
                    z += 0.0095
                }
            }
            // Sun-faded reed near the back left corner.
            let bl = V2(-0.12, -0.08)
            m.add(DD1HTable.topGrid(nx: strands.x * k, nz: strands.z * k, halfX: hx, halfZ: hz, material: faded,
                                    region: { x, z in pow((x - bl.x) / 0.09, 2) + pow((z - bl.y) / 0.05, 2) < 1 },
                                    height: { x, z in weave(x, z) + 0.0003 }))
            // Frayed strands escaping the binding.
            for (fx, sgn) in [(Float(0.07), Float(-1)), (Float(0.16), Float(1))] {
                m.add(Prim.tube([V3(fx, 0.0055, sgn * (ez - 0.002)), V3(fx + 0.002, 0.0066, sgn * (ez + 0.0025)), V3(fx + 0.007, 0.0075, sgn * (ez + 0.0052))],
                                radii: [0.0007, 0.0006, 0.0003], sides: 4, seamTile: 0.01, material: reed))
            }
            // One frayed strand escaping the binding.
            m.add(Prim.tube([V3(-0.11, 0.0055, ez - 0.002), V3(-0.108, 0.0072, ez + 0.0025), V3(-0.101, 0.0088, ez + 0.0055)],
                            radii: [0.0007, 0.0006, 0.0003], sides: 4, seamTile: 0.01, material: reed))
        }
        groundAO(&m, height: 0.01)
        return m
    }
}
