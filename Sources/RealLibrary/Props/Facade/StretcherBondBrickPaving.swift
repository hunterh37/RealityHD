import simd
import Foundation

/// Stretcher bond brick paving tile, 2 x 2 m: 215 x 102 x 50 mm Victorian stock clay pavers laid
/// flat in running half-bond courses on a sharp-sand bed, kiln-dried sand swept into the joints,
/// mixed red and brindle tones, a few stained and sunken bricks and moss along the shaded joints.
public struct StretcherBondBrickPaving: RealAsset {
    public static let id = "stretcher-bond-brick-paving"
    public static let summary = "Stretcher bond brick paving tile, 2 x 2 m: 215 x 102 x 50 mm clay pavers in running half-bond courses on a sand bed with swept sand joints."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 40, distance: 2.4, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.08, 2.0)
    /// Brick length along the course (m).
    public var brickLength: Float = 0.215
    /// Brick width across the course (m).
    public var brickWidth: Float = 0.1
    /// Brick thickness (m).
    public var thickness: Float = 0.05
    /// Joint gap (m).
    public var joint: Float = 0.006
    /// Brick tones (sRGB hex): Victorian reds and brindles.
    public var tones: [UInt32] = [0x9C4A34, 0x8A3F2E, 0xA85A40, 0x7A3A2C, 0x94523C, 0x6E3A30, 0xB06A4C]
    /// Brick material (tinted per tone).
    public var brick: MaterialKey = "paver.clay"
    /// Stained brick variant.
    public var stained: MaterialKey = "paver.clay-stained"
    /// Joint and bedding sand.
    public var sand: MaterialKey = "ground.sand:A8987A"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = brickLength, W = brickWidth, g = joint, top = size.y, hx = size.x / 2, hz = size.z / 2
        let keys = tones.map { "\(brick):\(String(format: "%06X", $0))" }
        let rows = Int((size.z / W).rounded())
        let pitch = size.z / Float(rows)
        var mossJoints: [Float] = []
        for r in 0..<rows {
            let z0 = -hz + Float(r) * pitch + g / 2, z1 = z0 + pitch - g
            if r > 0 { mossJoints.append(z0 - g / 2) }
            var x = -hx - (r % 2 == 0 ? 0.03 : 0.03 + L / 2)
            while x < hx - 0.001 {
                let a = max(-hx + g / 2, x + g / 2), b = min(hx - g / 2, x + L - g / 2)
                if b - a > 0.03 {
                    let sunk: Float = rng.chance(0.04) ? 0.004 : 0
                    let mat = rng.chance(0.07) ? stained : rng.pick(keys)
                    FPK.piece(&m, FPK.rect((a + b) / 2, (z0 + z1) / 2, b - a, z1 - z0), top: top + rng.float(-0.0015...0.0015) - sunk,
                              thick: thickness, bevel: 0.005, mat, tilt: 0.35, rng: &rng)
                }
                x += L
            }
        }
        // Moss in the course joints toward one shaded edge.
        for k in 0..<24 {
            var rr = rng.fork(700 + k)
            let jz = mossJoints[rr.int(0...(mossJoints.count - 1))]
            let x = -hx + 0.1 + pow(rr.float(), 1.8) * 1.6
            FPK.moss(&m, at: V2(x, jz), y: top - 0.007, len: rr.float(0.03...0.1), alongX: true)
        }
        GK.slab(&m, w: size.x - 0.004, d: size.z - 0.004, h: top - 0.01, sand, r: 0.003)
        groundAO(&m, height: 0.05, floor: 0.7)
        var lite = Model(name: Self.id + "-lite")
        lite.add(Prim.roundedBox(V3(size.x, top, size.z), radius: 0.004, bevelSegments: 1, material: brick), Xform(translation: V3(0, top / 2, 0)))
        return LODModel(levels: [m, lite], switchDistances: [10])
    }
}
