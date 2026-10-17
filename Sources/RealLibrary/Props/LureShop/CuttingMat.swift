import simd
import Foundation

/// Green self-healing cutting mat, 45 x 30 cm, 3 mm thick with 6 mm corner radii. Printed in pale yellow:
/// a 1 cm grid, heavier lines every 5 cm, a 5 mm tick ruler along the top and left margins, a 15 mm
/// unprinted border and two 45 degree angle lines from the lower-left corner. Story detail: a cluster
/// of light knife scores near the centre where lure blanks get trimmed, and a few paint spots.
public struct CuttingMat: RealAsset {
    public static let id = "cutting-mat"
    public static let summary = "Green self-healing cutting mat, 45 x 30 cm: printed 1 cm grid, 5 cm major lines, edge rulers, angle lines, knife scores."
    public static let tags = ["prop", "workshop", "plastic"]
    public static let budget = 2400
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 50, distance: 1.0, studio: true)

    /// Mat width X (m).
    public var width: Float = 0.45
    /// Mat depth Z (m).
    public var depth: Float = 0.30
    /// Slab thickness (m).
    public var thickness: Float = 0.003
    /// Grid pitch (m).
    public var pitch: Float = 0.01
    /// Unprinted border inside the edge (m).
    public var border: Float = 0.015
    /// Slab material.
    public var slab: MaterialKey = "plastic.matte:2F6B45"
    /// Print material.
    public var print: MaterialKey = "plastic.matte:E2DC9C"
    /// Knife score material (lighter exposed core).
    public var score: MaterialKey = "plastic.matte:7FA88A"
    public init() {}

    /// Flat strip on the top face from a to b (XZ), `w` wide, `lift` above the slab.
    static func strip(_ s: inout Surface, _ a: V2, _ b: V2, _ w: Float, _ y: Float) {
        let d = simd_normalize(b - a), n = V2(-d.y, d.x) * (w / 2)
        let p = [a - n, a + n, b + n, b - n].map { V3($0.x, y, $0.y) }
        let i = p.map { s.add($0, V3(0, 1, 0), V2($0.x, $0.z)) }
        // Wind so the face points +Y.
        let c = simd_cross(p[1] - p[0], p[2] - p[0])
        if c.y > 0 { s.quad(i[0], i[1], i[2], i[3]) } else { s.quad(i[0], i[3], i[2], i[1]) }
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let t = thickness, W = width, D = depth
        m.add(Prim.extrude(Shape2D.roundedRect(W, D, radius: 0.006), depth: t, bevel: 0.0008, bevelSegments: 2, material: slab),
              Xform(translation: V3(0, t / 2, 0), rotation: simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))))

        var ink = Surface(material: print)
        let y = t + 0.00006
        let x0 = -W / 2 + border, x1 = W / 2 - border, z0 = -D / 2 + border, z1 = D / 2 - border
        let nx = Int(((x1 - x0) / pitch).rounded(.down)), nz = Int(((z1 - z0) / pitch).rounded(.down))
        let gx1 = x0 + Float(nx) * pitch, gz1 = z0 + Float(nz) * pitch
        for i in 0...nx {
            let x = x0 + Float(i) * pitch, major = i % 5 == 0
            Self.strip(&ink, V2(x, z0), V2(x, gz1), major ? 0.0007 : 0.00028, y)
        }
        for j in 0...nz {
            let z = z0 + Float(j) * pitch, major = j % 5 == 0
            Self.strip(&ink, V2(x0, z), V2(gx1, z), major ? 0.0007 : 0.00028, y)
        }
        // Ruler ticks in the top (-Z) and left (-X) margins, every 5 mm.
        for i in 0...(nx * 2) {
            let x = x0 + Float(i) * pitch / 2, len: Float = i % 10 == 0 ? 0.008 : (i % 2 == 0 ? 0.005 : 0.003)
            Self.strip(&ink, V2(x, -D / 2 + 0.003), V2(x, -D / 2 + 0.003 + len), 0.0004, y)
        }
        for j in 0...(nz * 2) {
            let z = z0 + Float(j) * pitch / 2, len: Float = j % 10 == 0 ? 0.008 : (j % 2 == 0 ? 0.005 : 0.003)
            Self.strip(&ink, V2(-W / 2 + 0.003, z), V2(-W / 2 + 0.003 + len, z), 0.0004, y)
        }
        // 45 and 60 degree lines from the lower-left grid corner.
        let o = V2(x0, gz1)
        Self.strip(&ink, o, o + V2(1, -1) * (gz1 - z0), 0.0006, y + 0.00002)
        let l60 = (gz1 - z0) / sin(Float.pi / 3)
        Self.strip(&ink, o, o + V2(cos(Float.pi / 3), -sin(Float.pi / 3)) * l60, 0.0006, y + 0.00002)
        m.add(ink)

        // Knife scores: short lighter slits near the centre.
        var cuts = Surface(material: score)
        for _ in 0..<22 {
            let c = V2(rng.float(-0.07...0.09), rng.float(-0.05...0.06))
            let a = rng.float(0...Float.pi), len = rng.float(0.03...0.11)
            let d = V2(cos(a), sin(a)) * len / 2
            Self.strip(&cuts, c - d, c + d, rng.float(0.0004...0.0007), y + 0.00004)
        }
        m.add(cuts)
        // Paint spots: small flat discs.
        let colors: [UInt32] = [0xC0262D, 0xF2C230, 0x1E5FA8, 0xE8E4D8]
        for k in 0..<9 {
            let r = rng.float(0.0015...0.004)
            let c = V2(rng.float(-0.18...0.18), rng.float(-0.12...0.12))
            let col = String(format: "%06X", colors[k % colors.count])
            m.add(Prim.cylinder(radius: r, height: 0.00025, bevel: 0.0001, segments: 14, bevelSegments: 1, material: "plastic.gloss:" + col),
                  Xform(translation: V3(c.x, t, c.y)))
        }
        groundAO(&m)
        return LODModel(m)
    }
}
