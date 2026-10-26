import simd
import Foundation

/// Wooden privacy fence panel: architectural facade customizer, American Traditional. Parts: posts, post caps, stringers, vertical boards, cap rail, kickboard, galvanised nails.
public struct WoodenPrivacyFencePanel: RealAsset {
    public static let id = "wooden-privacy-fence-panel"
    public static let summary = "American traditional dog-ear privacy panel, 1x6 boards on 2x4 stringers between 4x4 posts"
    public static let tags = ["prop", "architecture", "facade", "wood"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(2.4, 1.8, 0.1)
    public init() {}

    /// Board tones, mixed across the panel (weathered cedar, aged pine, a newer board).
    public var boards: [MaterialKey] = ["wood.cedar-weathered", "wood.cedar-weathered", "wood.pine-aged", "wood.cedar-weathered", "wood.lumber-pine"]
    /// Pressure-treated pine for posts, stringers and the kickboard.
    public var frame: MaterialKey = "wood.pine-aged"
    /// Weathered grey for rail faces and post tops.
    public var grey: MaterialKey = "wood.weathered"
    /// Galvanised ring-shank nails.
    public var nail: MaterialKey = "metal.galvanized"
    /// Dark stain: knots, rot at the foot, nail bleed.
    public var stain: MaterialKey = "wood.charred"
    /// Damp, rotted wood at ground contact.
    public var damp: MaterialKey = "wood.waterlogged"

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y
        let pw: Float = 0.09, pxc = W / 2 - pw / 2, inner = W - 2 * pw
        let top = H - 0.1
        // Posts: 4x4 with a weathered pyramid cap and a ground-contact stain.
        for sx in [-1, 1] as [Float] {
            FA.box(&m, V3(pw, H - 0.05, pw), V3(sx * pxc, (H - 0.05) / 2, 0), frame, r: 0.004)
            FG.frustum(&m, w0: 0.096, w1: 0.05, y0: H - 0.05, y1: H, at: V3(sx * pxc, 0, 0), grey)
            FA.box(&m, V3(0.098, 0.012, 0.096), V3(sx * pxc, H - 0.054, 0), grey, r: 0.003)
            FA.box(&m, V3(pw + 0.002, 0.26, pw + 0.002), V3(sx * pxc, 0.13, 0), damp, r: 0.002)
        }
        // Three 2x4 stringers (on edge) and a 2x6 kickboard between the posts.
        for y in [0.34, 0.9, 1.5] as [Float] {
            FA.box(&m, V3(inner, 0.089, 0.038), V3(0, y, 0.0), frame, r: 0.003)
        }
        FA.box(&m, V3(inner, 0.14, 0.038), V3(0, 0.1, 0.022), frame, r: 0.003)
        // Capping 2x4 laid flat over the board tops.
        FA.box(&m, V3(inner, 0.038, 0.089), V3(0, top + 0.05 + 0.019 - 0.0, 0.01), frame, r: 0.003)
        // Fifteen 1x6 dog-eared boards on the face, 8 mm gaps; tone, height and nailing vary board to board.
        let n = 15, pitch = inner / Float(n), bw = pitch - 0.008
        for k in 0..<n {
            var r = rng.fork(k)
            let x = -inner / 2 + (Float(k) + 0.5) * pitch
            let mat = boards[(k * 3 + r.int(0...4)) % boards.count]
            let y0: Float = 0.17 + r.float(-0.004...0.004)
            let y1 = top - 0.012 + r.float(-0.012...0.006)
            FG.verticalBoard(&m, x: x, y0: y0, y1: y1, w: bw, z: 0.0195, thick: 0.019, ear: 0.032, mat)
            // Nails: two per stringer, with rust bleed under some heads.
            for y in [0.34, 0.9, 1.5] as [Float] {
                for dx in [-0.04, 0.04] as [Float] {
                    FG.slab(&m, V3(0.0065, 0.0065, 0.0025), V3(x + dx + r.float(-0.004...0.004), y + r.float(-0.012...0.012), 0.0388), nail)
                }
                if r.chance(0.18) { FG.slab(&m, V3(0.008, r.float(0.05...0.12), 0.0012), V3(x + 0.04, y - 0.07, 0.0392), stain) }
            }
            // Knot, and a checked split in a few boards.
            if r.chance(0.4) { FG.slab(&m, V3(0.028, 0.045, 0.0012), V3(x + r.float(-0.03...0.03), r.float(0.3...1.4), 0.0392), stain) }
            if r.chance(0.25) { FG.slab(&m, V3(0.003, r.float(0.15...0.35), 0.0012), V3(x + r.float(-0.04...0.04), r.float(0.4...1.2), 0.0392), stain) }
        }
        // Galvanised joist hangers where the stringers meet the posts, and a replaced new board in the run.
        for sx in [-1, 1] as [Float] { for y in [0.34, 0.9, 1.5] as [Float] {
            FA.box(&m, V3(0.04, 0.1, 0.044), V3(sx * (inner / 2 - 0.0), y, 0.0), nail, r: 0.002)
        } }
        // Lag screws through the posts into each stringer.
        for sx in [-1, 1] as [Float] {
            for y in [0.34, 0.9, 1.5] as [Float] {
                for dy in [-0.02, 0.02] as [Float] {
                    FG.slab(&m, V3(0.014, 0.014, 0.004), V3(sx * pxc, y + dy, 0.0465), nail)
                }
            }
        }
        // Damp, green-grey weathering on the lower boards and kickboard.
        FG.slab(&m, V3(inner, 0.18, 0.0012), V3(0, 0.26, 0.0393), damp)
        groundAO(&m, height: 0.22, floor: 0.55)
        return LODModel(FC.place(m))
    }
}
