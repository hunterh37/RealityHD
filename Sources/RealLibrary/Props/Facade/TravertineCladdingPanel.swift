import simd
import Foundation

/// Mid-century travertine cladding panel: a 30 mm honed vein-cut slab with banded strata, open pores
/// and 2 mm eased arrises, hung on stainless kerf clips from an aluminium agraffe rail, with a grey
/// silicone perimeter joint. One corner has a filled repair where a pore cluster broke out.
public struct TravertineCladdingPanel: RealAsset {
    public static let id = "travertine-cladding-panel"
    public static let summary = "Travertine cladding panel, 1.2 x 0.6 m: honed vein-cut slab with open pores, eased arrises, stainless kerf clips and silicone joints."
    public static let tags = ["prop", "architecture", "facade", "stone"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 12, distance: 1.8)

    /// Slab width in meters.
    public var width: Float = 1.2
    /// Slab height in meters.
    public var height: Float = 0.6
    /// Slab thickness in meters.
    public var thickness: Float = 0.03
    /// Travertine body.
    public var stone: MaterialKey = "stone.limestone:D9CBB0"
    /// Darker strata band.
    public var band: MaterialKey = "stone.limestone:C4AF8C"
    /// Clip and rail metal.
    public var clip: MaterialKey = "metal.stainless"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, H = height, t = thickness, joint: Float = 0.006, z0: Float = 0.008
        let sw = W - joint, sh = H - joint
        // Aluminium agraffe rails behind the slab (top and bottom).
        for y in [0.06, H - 0.06] as [Float] { FA.box(&m, V3(W - 0.02, 0.04, z0), V3(0, y, z0 / 2), "metal.aluminum-brushed", r: 0.0015) }
        // Slab with 2 mm eased arrises.
        FA.box(&m, V3(sw, sh, t - 0.002), V3(0, H / 2, z0 + (t - 0.002) / 2), stone, r: 0.002)
        FCL.face(&m, w: sw - 0.004, h: sh - 0.004, seg: 40, at: V3(0, H / 2, z0 + t - 0.0015), stone) { px, py in
            0.0012 * FCL.edge(px, py, sw - 0.004, sh - 0.004, 0.003) + 0.0001 * Noise.fbm(V3(px * 30, py * 30, 1), octaves: 2)
        }
        // Vein-cut strata: long horizontal bands, slightly wavy, flush to the honed face.
        let face = z0 + t
        let tones: [MaterialKey] = [band, "stone.limestone:CDBB98", "stone.limestone:E2D6BE"]
        for b in 0..<9 {
            let y = rng.float(0.03...(sh - 0.03)), bh = rng.float(0.012...0.05)
            FCL.face(&m, w: sw - 0.008, h: bh, seg: 10, at: V3(0, y, face + 0.0002 + Float(b) * 0.00003), tones[b % 3]) { px, _ in
                0.0001 * sin(px * 9 + Float(b)) - 0.0002 * max(0, Noise.perlin(V3(px * 60, Float(b), 0)))
            }
        }
        // Open pores: shallow dark voids elongated along the bedding.
        for i in 0..<110 {
            let x = rng.float(-sw / 2 + 0.02...sw / 2 - 0.02), y = rng.float(0.02...sh - 0.02)
            let l = rng.float(0.006...0.03), h = l * rng.float(0.25...0.45)
            let mat: MaterialKey = i % 3 == 0 ? "stone.limestone:6E5D45" : "stone.limestone:9A8463"
            m.add(Prim.superellipsoid(V3(l, h, 0.004), exponent: 2, subdivisions: 1, material: mat),
                  Xform(translation: V3(x, y, face - 0.0012)))
        }
        // Repaired corner: resin fill a shade lighter than the stone.
        FA.box(&m, V3(0.03, 0.022, 0.002), V3(sw / 2 - 0.02, H - 0.018, face - 0.0006), "stone.limestone:E3D8C2", r: 0.0008)
        // Kerf clips: stainless tabs into the top and bottom edge kerfs, screwed to the rail.
        for x in [-0.4, 0.4] as [Float] {
            for (y, s) in [(H - 0.0005, Float(1)), (0.0005, -1)] as [(Float, Float)] {
                FA.box(&m, V3(0.05, 0.003, z0 + t * 0.55), V3(x, y, (z0 + t * 0.55) / 2), clip, r: 0.0008)
                FA.box(&m, V3(0.05, 0.03, 0.003), V3(x, y - s * 0.03, z0 - 0.0015), clip, r: 0.0008)
                FCL.screw(&m, at: V3(x, y - s * 0.035, z0 - 0.0002), r: 0.004, clip)
            }
        }
        // Silicone perimeter joint, tooled concave, set back 3 mm.
        let sj: MaterialKey = "rubber.silicone-gray"
        FA.box(&m, V3(W, joint, t * 0.6), V3(0, H - joint / 2, z0 + t * 0.6 / 2 + 0.006), sj, r: 0.002)
        FA.box(&m, V3(W, joint, t * 0.6), V3(0, joint / 2, z0 + t * 0.6 / 2 + 0.006), sj, r: 0.002)
        for x in [-W / 2 + joint / 2, W / 2 - joint / 2] { FA.box(&m, V3(joint, H, t * 0.6), V3(x, H / 2, z0 + t * 0.6 / 2 + 0.006), sj, r: 0.002) }
        // groundAO omitted: thin slab, contact shadow grounds it.
        return LODModel(FC.place(m))
    }
}
