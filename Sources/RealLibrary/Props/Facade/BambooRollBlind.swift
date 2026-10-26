import simd
import Foundation

/// Tropical bamboo roll-up blind, 1.2 m wide: 120 split-cane half-round slats (sun-bleached at the head,
/// honey toward the hem, a few replaced darker slats and one sprung slat) bound by five pairs of cotton
/// cord with tie knots, cotton edge tape, a spiral-ended head roll tied with two hanging loops, two
/// brass-aged wall brackets with screws, a pull cord with a cleat and tassel, and a weathered bottom
/// batten with eyelets.
public struct BambooRollBlind: RealAsset {
    public static let id = "bamboo-roll-blind"
    public static let summary = "Tropical bamboo roll-up blind, 1.2 m wide: split-cane slats bound with cotton cord, rolled to a head roll on a wall bracket."
    public static let tags = ["prop", "architecture", "facade", "wood"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 1.9, studio: true)

    /// Blind width and overall height (m).
    public var width: Float = 1.2
    public var height: Float = 1.8
    /// Slat count.
    public var slats: Int = 120
    /// Slat base colour (sRGB hex), bleached toward the head.
    public var cane: UInt32 = 0xB68C50
    public var cord: MaterialKey = "fabric.linen:D8CDB0"
    public var brass: MaterialKey = "metal.brass-aged"
    public init() {}

    static func tint(_ hex: UInt32, _ k: Float) -> MaterialKey {
        func ch(_ v: UInt32) -> UInt32 { UInt32(max(0, min(255, Float(v) * (1 + k * 0.5) + (k > 0 ? k * 60 : 0)))) }
        return "wood.bamboo-cane:" + String(format: "%02X%02X%02X", ch(hex >> 16 & 255), ch(hex >> 8 & 255), ch(hex & 255))
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, H = height
        let R: Float = 0.034, rollY = H - R, rollZ: Float = R
        let zS: Float = 2 * R - 0.0045                 // slat centre line: tangent to the front of the roll
        let batten: Float = 0.03
        let top = rollY - 0.012, bot = batten + 0.002
        let pitch = (top - bot) / Float(slats)
        let sr: Float = pitch * 0.5 + 0.0003
        // Head roll: core plus slat-end spirals.
        m.add(Prim.cylinder(radius: R - 0.006, height: W - 0.02, bevel: 0.002, segments: 18, bevelSegments: 1, material: BambooRollBlind.tint(cane, 0.15)),
              Xform(translation: V3(-(W - 0.02) / 2, rollY, rollZ), rotation: FA.q(-90, FA.Z)))
        for e: Float in [-1, 1] {
            var sp: [V3] = []
            for s in 0...54 {
                let a = Float(s) / 54 * 3.2 * 2 * .pi
                let rad = R - 0.0035 - 0.032 * Float(s) / 54
                sp.append(V3(e * (W / 2 - 0.004), rollY + sin(a) * rad, rollZ + cos(a) * rad))
            }
            m.add(Prim.tube(sp, radii: Array(repeating: 0.0045, count: sp.count), sides: 5, seamTile: 0.1, material: BambooRollBlind.tint(cane, 0.25 * e), capEnd: true))
        }
        // Slat field: half-round cane tubes, tone by height, with replaced and sprung slats.
        let bad = Set((0..<7).map { _ in rng.int(8...(slats - 8)) })
        let sprung = rng.int(40...90)
        for i in 0..<slats {
            let y = top - pitch * (Float(i) + 0.5)
            let t = Float(i) / Float(slats)
            var k = 0.24 - 0.5 * t + rng.float(-0.06...0.06)
            if bad.contains(i) { k -= 0.28 }
            k = (k / 0.07).rounded() * 0.07
            let belly = 0.002 * sin(t * .pi) + 0.0015 * sin(t * 5)
            var x0 = -W / 2 + 0.012, x1 = W / 2 - 0.012
            var z = zS + belly
            if i == sprung { x1 -= 0.05; z += 0.005 }
            FA.rod(&m, V3(x0, y, z), V3(x1, y, z), r: sr, BambooRollBlind.tint(cane, k), sides: 5)
            // darker node bands
            if i % 11 == 3 { for nx in [rng.float(-0.45...(-0.15)), rng.float(0.1...0.45)] {
                FA.rod(&m, V3(nx, y, z + 0.0004), V3(nx + 0.012, y, z + 0.0004), r: sr + 0.0004, BambooRollBlind.tint(cane, k - 0.35), sides: 5)
            } }
            x0 += 0
        }
        // Cotton binding: five cord pairs with a knot at every fourth slat.
        let bx: [Float] = [-0.5, -0.25, 0, 0.25, 0.5]
        for x in bx {
            for s in [-1, 1] as [Float] {
                let cx = x + s * 0.006
                let zf = zS + 0.0052
                FA.rod(&m, V3(cx, top, zf), V3(cx, bot, zf), r: 0.0017, cord, sides: 4)
            }
            var j = 2
            while j < slats {
                let y = top - pitch * (Float(j) + 0.5)
                FSH.nut(&m, at: V3(x, y, zS + 0.0058), normal: FA.Z, size: 0.0085, "fabric.linen:CFC3A4")
                j += 6
            }
        }
        // Edge tape.
        for e: Float in [-1, 1] {
            FA.box(&m, V3(0.016, top - bot, 0.0016), V3(e * (W / 2 - 0.009), (top + bot) / 2, zS + 0.0058), "fabric.linen:B7A07A", r: 0.0005)
        }
        // Bottom batten with eyelets and the cord anchors.
        FA.box(&m, V3(W, batten, 0.016), V3(0, batten / 2, zS), "wood.weathered", r: 0.004)
        for x in bx { FA.cylZ(&m, r: 0.0055, h: 0.0022, at: V3(x, batten / 2, zS + 0.008), brass, bevel: 0.0006, segments: 8) }
        // Tie loops round the head roll.
        for x in [-0.32, 0.32] as [Float] {
            m.add(Prim.torus(major: R + 0.002, minor: 0.0032, segments: 20, sides: 5, material: cord),
                  Xform(translation: V3(x, rollY, rollZ), rotation: FA.q(90, FA.Z)))
            FC.bead(&m, r: 0.0065, at: V3(x, rollY - R - 0.002, rollZ), cord, sub: 3)
        }
        // Wall brackets: back plate, arm, cradle, screws.
        for x in [-0.46, 0.46] as [Float] {
            FA.box(&m, V3(0.03, 0.09, 0.005), V3(x, rollY, 0.0025), brass, r: 0.0012)
            FA.rod(&m, V3(x, rollY, 0.004), V3(x, rollY, rollZ - 0.004), r: 0.006, brass, sides: 6)
            m.add(Prim.torus(major: R - 0.001, minor: 0.0045, segments: 22, sides: 6, material: brass),
                  Xform(translation: V3(x, rollY, rollZ), rotation: FA.q(90, FA.Z)))
            for dy in [-0.032, 0.032] as [Float] { FSH.nut(&m, at: V3(x, rollY + dy, 0.005), normal: FA.Z, size: 0.012, "metal.screw-zinc") }
        }
        // Pull cord down the right edge with knot, tassel and wall cleat.
        let cx: Float = 0.545
        var pull: [V3] = []
        for s in 0...10 { let t = Float(s) / 10; pull.append(V3(cx + 0.01 * sin(t * 3), rollY - R - 0.002 - 0.78 * t, 0.069 + 0.002 * sin(t * 2))) }
        FA.path(&m, pull, r: 0.0024, cord, sides: 4)
        FC.bead(&m, r: 0.0065, at: pull.last!, cord, sub: 3)
        FA.rod(&m, pull.last!, pull.last! - V3(0, 0.06, 0), r: 0.0042, "fabric.linen:BDAE8A", sides: 5)
        FA.box(&m, V3(0.05, 0.012, 0.012), V3(cx + 0.04, rollY - 0.4, 0.008), brass, r: 0.003)
        _ = rng.float()
        groundAO(&m, height: 0.05, floor: 0.9)
        return LODModel(FA.centerZ(m))
    }
}
