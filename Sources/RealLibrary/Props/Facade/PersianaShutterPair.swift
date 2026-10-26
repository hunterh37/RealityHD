import simd
import Foundation

/// Persiana shutter pair: two Spanish colonial louvered wood leaves closed over a window, each with
/// mortised stiles, three rails, raked louvers in two fields with a tilt rod, forged strap hinges on
/// wall pintles, a cremone bolt and a turn catch. Paint is flaked and sun-bleached. Wall plane at z = 0.
public struct PersianaShutterPair: RealAsset {
    public static let id = "persiana-shutter-pair"
    public static let summary = "Spanish colonial louvered wood persiana pair 1.2 x 1.8 m: mortised stiles and rails, raked louvers, strap hinges, cremone bolt."
    public static let tags = ["prop", "architecture", "facade", "trim", "wood", "metal"]
    public static let budget = 14_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 6, distance: 2.6)

    /// Width of one leaf, height and thickness (m).
    public var leafWidth: Float = 0.578
    public var height: Float = 1.8
    public var thickness: Float = 0.038
    /// Louver pitch (m) and rake angle (degrees from horizontal).
    public var pitch: Float = 0.038
    public var rake: Float = 33
    public var iron: MaterialKey = "metal.wrought-iron"
    public init() {}

    /// Louver section (x out from the wall, y up), raked down toward the outside.
    private func louver(_ c: Float, _ t: Float, _ a: Float) -> [V2] {
        let r = a * .pi / 180
        let dx = cos(r), dy = -sin(r), nx = sin(r), ny = cos(r)
        func pt(_ s: Float, _ n: Float) -> V2 { V2(dx * s * c + nx * n * t, dy * s * c + ny * n * t) }
        return [pt(-0.5, 0.5), pt(0.5, 0.5), pt(0.5, -0.5), pt(-0.5, -0.5)]
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = leafWidth, H = height, t = thickness
        let stile: Float = 0.062, topRail: Float = 0.105, midRail: Float = 0.082, botRail: Float = 0.15
        let midY = H * 0.52
        let z0: Float = 0.008
        let greens: [MaterialKey] = ["wood.painted-shaker-worn:2F4A39", "wood.painted-shaker-worn:36513F", "wood.painted-shaker-worn:2A4033"]
        let louvProfile = louver(0.060, 0.0085, rake)
        for (li, side) in ([-1, 1] as [Float]).enumerated() {
            let cx = side * (W / 2 + 0.003)
            let paint = greens[li]
            // Stiles run full height; rails tenon between them.
            for e: Float in [-1, 1] {
                FA.box(&m, V3(stile, H, t), V3(cx + e * (W / 2 - stile / 2), H / 2, z0 + t / 2), paint, r: 0.003)
            }
            let iw = W - 2 * stile
            let fields: [(Float, Float)] = [(botRail, midY - midRail / 2), (midY + midRail / 2, H - topRail)]
            FA.box(&m, V3(iw + 0.006, topRail, t * 0.96), V3(cx, H - topRail / 2, z0 + t / 2), paint, r: 0.003)
            FA.box(&m, V3(iw + 0.006, midRail, t * 0.96), V3(cx, midY, z0 + t / 2), paint, r: 0.003)
            FA.box(&m, V3(iw + 0.006, botRail, t * 0.96), V3(cx, botRail / 2, z0 + t / 2), paint, r: 0.003)
            // Sun-bleached bare wood showing through flaked paint on the bottom rail and stile feet.
            FA.box(&m, V3(iw * 0.55, botRail * 0.5, 0.0008), V3(cx + rng.float(-0.04...0.04), botRail * 0.34, z0 + t + 0.0004), "wood.weathered", r: 0.0003)
            FA.box(&m, V3(0.04, 0.22, 0.0008), V3(cx + side * (W / 2 - stile / 2), 0.13, z0 + t + 0.0004), "wood.weathered", r: 0.0003)
            // Stick moulding around each field, plus the louvers themselves.
            for (fi, (y0, y1)) in fields.enumerated() {
                let h = y1 - y0, yc = (y0 + y1) / 2
                FA.box(&m, V3(iw, 0.011, 0.012), V3(cx, y0 + 0.0055, z0 + t - 0.004), paint, r: 0.0025)
                FA.box(&m, V3(iw, 0.011, 0.012), V3(cx, y1 - 0.0055, z0 + t - 0.004), paint, r: 0.0025)
                for e: Float in [-1, 1] {
                    FA.box(&m, V3(0.011, h, 0.012), V3(cx + e * (iw / 2 - 0.0055), yc, z0 + t - 0.004), paint, r: 0.0025)
                }
                let count = Int((h - 0.02) / pitch)
                for k in 0..<count {
                    // One louver missing from the lower field of the left leaf; one dropped on the right.
                    if li == 0 && fi == 0 && k == 6 { continue }
                    let y = y0 + 0.02 + (Float(k) + 0.5) * pitch
                    var rot = simd_quatf(angle: 0, axis: FA.X)
                    var dy: Float = 0
                    if li == 1 && fi == 1 && k == 11 { rot = FA.q(-14, FA.Z); dy = -0.004 }
                    let tone: MaterialKey = rng.chance(0.18) ? "wood.painted-shaker-worn:5B6E55" : paint
                    m.add(Prim.extrude(louvProfile, depth: iw - 0.012, bevel: 0.0012, bevelSegments: 1, material: tone),
                          Xform(translation: V3(cx, y + dy, z0 + t / 2 - 0.002), rotation: rot * FA.q(-90, FA.Y)))
                }
                // Tilt rod with one staple per three louvers.
                let rx = cx + side * 0.012
                FA.box(&m, V3(0.013, h - 0.03, 0.010), V3(rx, yc, z0 + t + 0.001), paint, r: 0.003)
                var sy = y0 + 0.07
                while sy < y1 - 0.05 {
                    FA.box(&m, V3(0.022, 0.005, 0.004), V3(rx, sy, z0 + t + 0.0065), iron, r: 0.001)
                    sy += pitch * 3
                }
            }
            // Strap hinges on the outer edge, hand-forged and tapered, riveted, on wall pintles.
            let ex = cx + side * (W / 2)
            for y in [0.30, midY, H - 0.30] {
                let sh = [V2(0, -0.017), V2(0.30, -0.011), V2(0.34, 0), V2(0.30, 0.011), V2(0, 0.017)]
                m.add(Prim.extrude(sh.map { V2($0.x, $0.y) }, depth: 0.0055, bevel: 0.0013, bevelSegments: 1, material: iron),
                      Xform(translation: V3(ex, y, z0 + t + 0.0055 / 2), rotation: FA.q(side > 0 ? 180 : 0, FA.Y)))
                for i in 0..<4 {
                    FC.bead(&m, r: 0.0035, at: V3(ex - side * (0.05 + Float(i) * 0.07), y, z0 + t + 0.0066), iron, sub: 3)
                }
                // Eye, pintle driven into the wall.
                FA.cylZ(&m, r: 0.0085, h: 0.020, at: V3(ex + side * 0.006, y, z0 + t - 0.01), iron, bevel: 0.001, segments: 10)
                FA.cylZ(&m, r: 0.0055, h: z0 + t, at: V3(ex + side * 0.011, y, 0), iron, bevel: 0.001, segments: 8)
            }
        }
        // Cremone bolt on the right meeting stile with two guides and a turn knob, plus a turn catch.
        FA.rod(&m, V3(0.003, 0.25, z0 + t + 0.012), V3(0.003 + 0.0, 1.55, z0 + t + 0.012), r: 0.0045, iron, sides: 8)
        for y in [0.55, 0.95, 1.40] as [Float] {
            FA.box(&m, V3(0.018, 0.022, 0.012), V3(0.003, y, z0 + t + 0.006), iron, r: 0.002)
        }
        FC.bead(&m, r: 0.009, at: V3(0.003, 1.02, z0 + t + 0.018), "metal.brass-aged", sub: 4)
        FA.rod(&m, V3(0.003, 1.02, z0 + t + 0.012), V3(0.003, 1.02, z0 + t + 0.018), r: 0.004, iron, sides: 8)
        FA.box(&m, V3(0.075, 0.016, 0.006), V3(-0.036, 0.19, z0 + t + 0.004), iron, r: 0.002, rot: FA.q(8, FA.Z))
        FA.cylZ(&m, r: 0.006, h: 0.007, at: V3(-0.062, 0.19, z0 + t + 0.004), iron, bevel: 0.001, segments: 8)
        _ = rng.float()
        groundAO(&m, height: 0.12, floor: 0.7)
        return LODModel(FC.place(m))
    }
}
