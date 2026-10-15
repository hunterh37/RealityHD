import simd
import Foundation

/// Herringbone brick paving tile, 2 x 2 m: 20 x 10 x 6 cm clay brick pavers laid in a 45-degree
/// herringbone, cut against a soldier-course border, on a sand bed with swept sand joints, tone
/// variation, a few stained and sunken bricks and moss in the shaded border joint.
public struct HerringboneBrickPaving: RealAsset {
    public static let id = "herringbone-brick-paving"
    public static let summary = "Herringbone brick paving tile, 2 x 2 m: clay brick pavers in a 45-degree herringbone inside a soldier-course border, sand joints."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 40, distance: 2.4, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.1, 2.0)
    /// Brick width (m); length is twice this.
    public var brickWidth: Float = 0.1
    /// Brick thickness (m).
    public var thickness: Float = 0.06
    /// Joint gap (m).
    public var joint: Float = 0.006
    /// Brick tones (sRGB hex).
    public var tones: [UInt32] = [0xA2523B, 0x8E4733, 0xB0614A, 0x7C3F30, 0x9A5A42]
    /// Brick material (tinted per tone).
    public var brick: MaterialKey = "paver.clay"
    /// Stained brick variant.
    public var stained: MaterialKey = "paver.clay-stained"
    /// Joint sand.
    public var sand: MaterialKey = "ground.sand"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let u = brickWidth, g = joint, top = size.y, hx = size.x / 2, hz = size.z / 2
        let keys = tones.map { "\(brick):\(String(format: "%06X", $0))" }
        func lay(_ o: [V2]) {
            let sunk: Float = rng.chance(0.05) ? 0.004 : 0
            let mat = rng.chance(0.06) ? stained : rng.pick(keys)
            FPK.piece(&m, o, top: top + rng.float(-0.0015...0.0015) - sunk, thick: thickness, bevel: 0.004, mat, tilt: 0.35, rng: &rng)
        }
        // Soldier course: bricks standing perpendicular to each edge, 10 cm along it.
        let b = 2 * u
        var p = -hx
        while p < hx - 0.01 {
            let q = min(hx, p + u)
            lay(FPK.rect((p + q) / 2, -hz + b / 2, q - p - g, b - g))
            lay(FPK.rect((p + q) / 2, hz - b / 2, q - p - g, b - g))
            p = q
        }
        p = -hz + b
        while p < hz - b - 0.01 {
            let q = min(hz - b, p + u)
            lay(FPK.rect(-hx + b / 2, (p + q) / 2, b - g, q - p - g))
            lay(FPK.rect(hx - b / 2, (p + q) / 2, b - g, q - p - g))
            p = q
        }
        // 45-degree herringbone field, clipped to the inside of the border.
        let ix0 = -hx + b, ix1 = hx - b, iz0 = -hz + b, iz1 = hz - b
        let r = Float.pi / 4, c = cos(r), s = sin(r)
        func world(_ a: V2) -> V2 { V2(a.x * c - a.y * s, a.x * s + a.y * c) }
        let n = Int((size.x * 1.5) / u) + 6
        for i in -n...n { for t in -n...n {
            for vert in [false, true] {
                let bx = Float(t + 4 * i) + (vert ? 4 : 0) - 2, by = Float(t) + (vert ? 1 : 0)
                let sx: Float = vert ? 1 : 2, sy: Float = vert ? 2 : 1
                let x0 = bx * u + g / 2, z0 = by * u + g / 2, x1 = x0 + sx * u - g, z1 = z0 + sy * u - g
                let local = [V2(x0, z0), V2(x1, z0), V2(x1, z1), V2(x0, z1)].map(world)
                let cc = FPK.centroid(local)
                guard abs(cc.x) < hx, abs(cc.y) < hz else { continue }
                let cut = FPK.clip(local, x0: ix0 + g / 2, x1: ix1 - g / 2, z0: iz0 + g / 2, z1: iz1 - g / 2)
                if cut.count >= 3, abs(FPK.area(cut)) > 0.0012 { lay(cut) }
            }
        }}
        // Moss in the shaded joint between border and field.
        for k in 0..<18 {
            var rr = rng.fork(700 + k)
            let side = rr.int(0...3), a = rr.float(-0.8...0.8), len = rr.float(0.03...0.09)
            let pt: V2 = side == 0 ? V2(a, iz0) : side == 1 ? V2(a, iz1) : side == 2 ? V2(ix0, a) : V2(ix1, a)
            FPK.moss(&m, at: pt, y: top - 0.006, len: len, alongX: side < 2)
        }
        // Sand bed under the bricks, its top a few mm under the brick tops so the joints read.
        let bed = top - 0.012
        GK.slab(&m, w: size.x - 0.004, d: size.z - 0.004, h: bed, sand, r: 0.003)
        groundAO(&m, height: 0.05, floor: 0.7)
        var lite = Model(name: Self.id + "-lite")
        lite.add(Prim.roundedBox(V3(size.x, top, size.z), radius: 0.004, bevelSegments: 1, material: "paver.herringbone"), Xform(translation: V3(0, top / 2, 0)))
        return LODModel(levels: [m, lite], switchDistances: [10])
    }
}
