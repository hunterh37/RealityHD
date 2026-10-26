import simd
import Foundation

/// Shopfront transom light: a painted timber frame with moulded rails and stiles, a central glazing bar,
/// two panes bedded in putty with gold leaf lettering and a black shadow applied to the glass, brass pivot
/// screws at the stiles and a latch keeper. Gilt is chipped, putty cracked and glass dusty at the sill.
public struct OculusDoorTransomLettering: RealAsset {
    public static let id = "oculus-door-transom-lettering"
    public static let summary = "Shopfront transom light 1.0 x 0.4 m: moulded timber frame, putty bead, glazing bar and gold leaf lettering with shadow."
    public static let tags = ["prop", "architecture", "facade", "trim", "wood"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 22, elevation: 6, distance: 1.1)

    /// Lettering on the left and right panes (A-Z, 0-9).
    public var left = "COFFEE"
    public var right = "HOUSE"
    public var frame: MaterialKey = "wood.painted-exterior:2B4A44"
    public var gilt: MaterialKey = "metal.gold-leaf"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 1.0, H: Float = 0.4, r: Float = 0.055, d: Float = 0.014
        // Rails with an ogee moulding facing out, stiles and mullion.
        let rail: [V2] = [V2(0, 0), V2(d, 0), V2(d, 0.006), V2(d - 0.004, 0.012), V2(d - 0.008, 0.02), V2(d - 0.008, r - 0.006), V2(d - 0.012, r), V2(0, r)]
        FA.run(&m, rail, length: W, at: V3(0, 0, 0), frame, bevel: 0.001)
        FA.run(&m, rail.map { V2($0.x, r - $0.y) }.reversed(), length: W, at: V3(0, H - r, 0), frame, bevel: 0.001)
        for sx: Float in [-1, 1] { FA.box(&m, V3(r, H - 2 * r + 0.004, d), V3(sx * (W / 2 - r / 2), H / 2, d / 2), frame, r: 0.0025) }
        FA.box(&m, V3(0.028, H - 2 * r + 0.004, d - 0.004), V3(0, H / 2, (d - 0.004) / 2), frame, r: 0.0025)
        // Two panes with a putty bead round each, set back 7 mm.
        let pw = (W - 2 * r - 0.028) / 2, ph = H - 2 * r
        for sx: Float in [-1, 1] {
            let cx = sx * (0.014 + pw / 2)
            FA.box(&m, V3(pw, ph, 0.004), V3(cx, H / 2, 0.005), "glass.pane", r: 0.0005)
            for (w, h, x, y) in [(pw, 0.006, 0.0, ph / 2 - 0.003), (pw, 0.006, 0.0, -ph / 2 + 0.003), (0.006, ph, -pw / 2 + 0.003, 0.0), (0.006, ph, pw / 2 - 0.003, 0.0)] as [(Float, Float, Float, Float)] {
                FG.flat(&m, V3(w, h, 0.005), V3(cx + x, H / 2 + y, 0.0085), "paint.stucco:C9C3B0")
            }
        }
        // Gold leaf lettering on the glass with black shadow, flaking in places.
        let h: Float = 0.078
        for (side, s) in [(Float(-1), left), (Float(1), right)] {
            let w = FG.width(s, h: h), pitch = 5.4 * h / 6
            let cx0 = side * (0.014 + pw / 2)
            for (i, c) in s.enumerated() {
                let cx = cx0 - w / 2 + Float(i) * pitch + 2 * h / 6
                FG.text(&m, String(c), h: h, stroke: 0.012, depth: 0.0006, at: V3(cx + 0.0035, H / 2 - 0.004, 0.0072), "metal.painted:0A0A0A")
                FG.text(&m, String(c), h: h, stroke: 0.012, depth: 0.0008, at: V3(cx, H / 2, 0.0076), rng.chance(0.2) ? "metal.brass-aged" : gilt)
            }
        }
        // Keeper and latch at the top rail, brass pivot screws on the stiles, cracked putty and dust at the sill.
        FA.box(&m, V3(0.05, 0.02, 0.004), V3(0, H - r / 2, d + 0.001), "metal.brass", r: 0.002)
        FA.box(&m, V3(0.014, 0.03, 0.006), V3(0.012, H - r / 2 - 0.02, d + 0.003), "metal.brass-aged", r: 0.002)
        for sx: Float in [-1, 1] { FG.screw(&m, at: V3(sx * (W / 2 - r / 2), H / 2, d), r: 0.007, mat: "metal.brass-aged") }
        for k in 0..<10 {
            // Flaked paint on the rails and stiles only.
            let onRail = k % 2 == 0
            let x = onRail ? rng.float(-0.46...0.46) : (k % 4 == 1 ? -1 : 1) * (W / 2 - rng.float(0.01...0.045))
            let y = onRail ? (k % 4 == 0 ? rng.float(0.008...r - 0.008) : H - rng.float(0.008...r - 0.008)) : rng.float(r...H - r)
            FG.flat(&m, V3(rng.float(0.01...0.035), rng.float(0.008...0.02), 0.0006), V3(x, y, d - 0.0003), "wood.weathered", rot: FA.q(rng.float(-30...30), FA.Z))
        }
        for _ in 0..<5 { FG.flat(&m, V3(0.0012, rng.float(0.02...0.05), 0.0004), V3(rng.float(-0.45...0.45), r + 0.02, 0.0078), "metal.steel:3A352C") }
        FG.flat(&m, V3(W - 2 * r - 0.04, 0.012, 0.0004), V3(0, r + 0.008, 0.0072), "paint.stucco:A9A394")
        groundAO(&m, height: 0.05, floor: 0.95)
        return LODModel(FC.place(m))
    }
}
