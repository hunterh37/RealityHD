import simd
import Foundation

/// Shadowbox fence panel: architectural facade customizer, American Traditional. Parts: posts, post caps, stringers, alternating boards front and back, cap rail, kickboard, nails.
public struct ShadowboxFencePanel: RealAsset {
    public static let id = "shadowbox-fence-panel"
    public static let summary = "American traditional shadowbox fence, boards alternating each side of the rails"
    public static let tags = ["prop", "architecture", "facade", "wood"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(2.4, 1.8, 0.1)
    public init() {}

    /// Board tones, mixed across the panel.
    public var boards: [MaterialKey] = ["wood.cedar-weathered", "wood.cedar-weathered", "wood.pine-aged", "wood.cedar", "wood.cedar-weathered"]
    /// Posts, stringers, kickboard and cap rail (aged pine).
    public var frame: MaterialKey = "wood.pine-aged"
    /// Weathered grey for the post caps.
    public var grey: MaterialKey = "wood.weathered"
    /// Galvanised ring-shank nails and hangers.
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
        // Posts: 4x4 with weathered pyramid caps and a damp stain at the foot.
        for sx in [-1, 1] as [Float] {
            FA.box(&m, V3(pw, H - 0.05, pw), V3(sx * pxc, (H - 0.05) / 2, 0), frame, r: 0.004)
            FG.frustum(&m, w0: 0.092, w1: 0.05, y0: H - 0.05, y1: H, d0: 0.1, d1: 0.05, at: V3(sx * pxc, 0, 0), grey)
            FA.box(&m, V3(0.092, 0.012, 0.1), V3(sx * pxc, H - 0.054, 0), grey, r: 0.003)
            FA.box(&m, V3(pw + 0.002, 0.26, pw + 0.002), V3(sx * pxc, 0.13, 0), damp, r: 0.002)
        }
        // Three 2x4 stringers on edge, centred on the posts, and a 2x6 kickboard.
        for y in [0.34, 0.9, 1.5] as [Float] { FA.box(&m, V3(inner, 0.089, 0.038), V3(0, y, 0), frame, r: 0.003) }
        FA.box(&m, V3(inner, 0.14, 0.038), V3(0, 0.1, 0.0), frame, r: 0.003)
        // Flat 2x4 capping over the board tops.
        FA.box(&m, V3(inner, 0.038, 0.089), V3(0, top + 0.069 - 0.0, 0.0), frame, r: 0.003)
        // Twenty-two 1x6 boards alternating front and back of the stringers, 40 mm overlap, flat tops with a small ear.
        let n = 22, pitch = inner / Float(n), bw: Float = 0.14
        let missing = 13                                            // one back board gone: the gap shows the street
        for k in 0..<n {
            var r = rng.fork(k)
            if k == missing { continue }
            let front = k % 2 == 0
            let x = -inner / 2 + (Float(k) + 0.5) * pitch
            let mat = boards[(k * 3 + r.int(0...4)) % boards.count]
            let y0: Float = 0.17 + r.float(-0.004...0.004)
            let y1 = top + 0.05 - 0.002 + r.float(-0.004...0.002)
            let z: Float = front ? 0.038 : -0.038
            FG.verticalBoard(&m, x: x, y0: y0, y1: y1, w: bw, z: front ? 0.0285 : -0.0285, thick: 0.019, ear: 0.018, mat)
            let nz: Float = front ? 0.0393 : -0.0393
            for y in [0.34, 0.9, 1.5] as [Float] {
                for dx in [-0.035, 0.035] as [Float] {
                    FG.slab(&m, V3(0.0065, 0.0065, 0.0025), V3(x + dx + r.float(-0.004...0.004), y + r.float(-0.012...0.012), nz), nail)
                }
                if r.chance(0.15) { FG.slab(&m, V3(0.008, r.float(0.05...0.12), 0.0012), V3(x + 0.035, y - 0.07, nz + (front ? 0.0003 : -0.0003)), stain) }
            }
            if r.chance(0.4) { FG.slab(&m, V3(0.028, 0.045, 0.0012), V3(x + r.float(-0.03...0.03), r.float(0.3...1.4), front ? 0.0387 : -0.0387), stain) }
            if r.chance(0.25) { FG.slab(&m, V3(0.003, r.float(0.15...0.35), 0.0012), V3(x + r.float(-0.04...0.04), r.float(0.4...1.2), front ? 0.0387 : -0.0387), stain) }
        }
        // Lag screws through the posts into each stringer end.
        for sx in [-1, 1] as [Float] {
            for y in [0.34, 0.9, 1.5] as [Float] {
                for dy in [-0.02, 0.02] as [Float] { FG.slab(&m, V3(0.014, 0.014, 0.004), V3(sx * pxc, y + dy, 0.0465), nail) }
            }
        }
        // Damp band on the lowest boards, both faces.
        for zf in [0.0388, -0.0388] as [Float] {
            FG.slab(&m, V3(inner, 0.16, 0.0012), V3(0, 0.25, zf), damp)
        }
        groundAO(&m, height: 0.22, floor: 0.55)
        return LODModel(FC.place(m))
    }
}
