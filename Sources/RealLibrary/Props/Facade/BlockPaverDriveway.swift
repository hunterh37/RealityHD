import simd
import Foundation

/// Block paver driveway tile, 2 x 2 m: 200 x 100 x 60 mm chamfered concrete block pavers laid in
/// stretcher bond across the drive on a sharp-sand laying course, kiln-dried sand brushed into the
/// joints, brindle tone mix, a dark oil drip stain where a car parks and a tyre-polished track.
public struct BlockPaverDriveway: RealAsset {
    public static let id = "block-paver-driveway"
    public static let summary = "Block paver driveway tile, 2 x 2 m: 200 x 100 mm concrete block pavers in stretcher bond on sand, with sand joints and an oil drip stain."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 40, distance: 2.4, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.1, 2.0)
    /// Paver length along the course (m).
    public var paverLength: Float = 0.2
    /// Paver width across the course (m).
    public var paverWidth: Float = 0.1
    /// Paver thickness (m).
    public var thickness: Float = 0.06
    /// Joint gap (m).
    public var joint: Float = 0.004
    /// Brindle tone mix (sRGB hex) applied to the paver material.
    public var tones: [UInt32] = [0x5E5A55, 0x6E675F, 0x4C4945, 0x77706A, 0x6A5A4E, 0x57524D, 0x837B72]
    /// Paver material (tinted per tone).
    public var paver: MaterialKey = "paver.charcoal"
    /// Joint and bedding sand.
    public var sand: MaterialKey = "ground.sand:B9A684"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = paverLength, W = paverWidth, g = joint, top = size.y, hx = size.x / 2, hz = size.z / 2
        let keys = tones.map { "\(paver):\(String(format: "%06X", $0))" }
        let stain = V2(rng.float(-0.3...0.3), rng.float(-0.3...0.3)), sph = rng.float(0...6.28)
        let trackX = rng.float(-0.5...0.5)
        func lay(_ x0: Float, _ x1: Float, _ z0: Float, _ z1: Float) {
            let c = V2((x0 + x1) / 2, (z0 + z1) / 2)
            var mat = rng.pick(keys)
            if simd_length((c - stain) * V2(1, 1.4)) < 0.17 { mat = "paver.charcoal:2E2B28" }
            else if abs(c.x - trackX) < 0.1 && rng.chance(0.5) { mat = "paver.charcoal:4A4743" }
            let sunk: Float = rng.chance(0.04) ? 0.003 : 0
            FPK.piece(&m, FPK.rect(c.x, c.y, x1 - x0, z1 - z0), top: top + rng.float(-0.001...0.001) - sunk,
                      thick: thickness, bevel: 0.004, mat, tilt: 0.25, rng: &rng)
        }
        // Courses run along X; alternate courses shift half a paver. Cut pavers at the tile edge keep a half joint so tiles butt seamlessly.
        let rows = Int((size.z / W).rounded())
        for r in 0..<rows {
            let z0 = -hz + Float(r) * W + g / 2, z1 = z0 + W - g
            var x = -hx + (r % 2 == 0 ? 0 : -L / 2)
            while x < hx - 0.001 {
                let a = max(-hx + g / 2, x + g / 2), b = min(hx - g / 2, x + L - g / 2)
                if b - a > 0.02 { lay(a, b, z0, z1) }
                x += L
            }
        }
        // Oil drip: thin dark film over the stained pavers.
        GK.poly(&m, (0..<16).map { k in let a = Float(k) / 16 * 2 * .pi; return stain + V2(cos(a) * (0.08 + 0.02 * sin(a * 3 + sph) + 0.012 * sin(a * 7)), sin(a) * (0.06 + 0.012 * cos(a * 5))) },
                top: top + 0.0006, "ground.puddle:4A443E", thick: 0.0008)
        // Laying course sand, its top a few mm below the pavers so the joints read as sand.
        GK.slab(&m, w: size.x - 0.002, d: size.z - 0.002, h: top - 0.008, sand, r: 0.002)
        groundAO(&m, height: 0.05, floor: 0.7)
        var lite = Model(name: Self.id + "-lite")
        lite.add(Prim.roundedBox(V3(size.x, top, size.z), radius: 0.003, bevelSegments: 1, material: "paver.charcoal"), Xform(translation: V3(0, top / 2, 0)))
        return LODModel(levels: [m, lite], switchDistances: [10])
    }
}
