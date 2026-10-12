import simd
import Foundation

/// Bahama shutter, 1.2 x 1.4 m: a Caribbean/Colonial top-hinged louvred awning shutter cracked open on its
/// hinge line. Mortise-and-tenon pine frame (stiles, top rail, mid rail, drip-lipped bottom rail, pegged
/// joints) holding 28 fixed louvre slats tilted 40 degrees that shed rain, hung from a painted header board
/// by two barrel hinges, with two adjustable prop-stay rods hooked to wall eyes. Sun-faded teal paint,
/// chipped on the lower rail and stile feet.
public struct BahamaShutter: RealAsset {
    public static let id = "bahama-shutter"
    public static let summary = "Bahama (Colonial) shutter, 1.2 x 1.4 m: top-hinged louvred panel, barrel hinges and prop stays on a header board."
    public static let tags = ["prop", "architecture", "facade", "shutter", "wood", "metal"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 1.7)

    /// Overall width and height (m).
    public var width: Float = 1.2
    public var height: Float = 1.4
    /// Angle the shutter hangs open from the wall (degrees).
    public var openAngle: Float = 1.9
    /// Sun-faded paint on the frame and louvres.
    public var paint: MaterialKey = "wood.painted-shaker-worn:3F7A70"
    /// Header board paint.
    public var header: MaterialKey = "wood.painted-exterior:E9E3D2"
    /// Grimy paint at the bottom rail where rain splash reaches.
    public var splash: MaterialKey = "wood.painted-shaker-worn:6A7F6F"
    public var iron: MaterialKey = "metal.wrought-iron"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, H = height
        let hdrH: Float = 0.07, hdrT: Float = 0.02
        let yHinge = H - hdrH                       // hinge axis height
        let sh = yHinge - 0.057                     // shutter panel height
        let sw: Float = W - 0.04      // panel width
        let t: Float = 0.04                         // frame thickness
        let stile: Float = 0.07

        // Panel built hanging from y = 0 downward, back face on z = 0.
        var s = Model(name: "panel")
        // Stiles with a 3 mm arris and pegged mortise joints.
        for e: Float in [-1, 1] {
            FA.box(&s, V3(stile, sh, t), V3(e * (sw / 2 - stile / 2), -sh / 2, t / 2), paint, r: 0.007)
        }
        let topRail: Float = 0.09, botRail: Float = 0.12, midRail: Float = 0.07
        let iw = sw - 2 * stile
        FA.box(&s, V3(iw + 0.016, topRail, t * 0.92), V3(0, -topRail / 2, t / 2), paint, r: 0.005)
        FA.box(&s, V3(iw + 0.016, botRail, t * 0.92), V3(0, -sh + botRail / 2, t / 2), splash, r: 0.005)
        let ym = -(sh - botRail + topRail) / 2 + 0.0
        FA.box(&s, V3(iw + 0.016, midRail, t * 0.92), V3(0, ym, t / 2), paint, r: 0.003)
        // Drip lip under the bottom rail.
        FA.box(&s, V3(sw - 0.01, 0.012, t + 0.004), V3(0, -sh - 0.002, t / 2 + 0.002), splash, r: 0.004)
        // Louvre slats: tilted 40 degrees, high edge toward the wall, tenoned into the stiles.
        let a: Float = 38 * .pi / 180, lw: Float = 0.056, lt: Float = 0.009
        let d = V2(cos(a), -sin(a)), n = V2(sin(a), cos(a))
        let slat: [V2] = [d * (-lw / 2) + n * (-lt / 2), d * (lw / 2) + n * (-lt / 2), d * (lw / 2) + n * (lt / 2), d * (-lw / 2) + n * (lt / 2)]
        let y0 = -topRail, y1 = -sh + botRail
        let bands: [(Float, Float)] = [(y0, ym + midRail / 2), (ym - midRail / 2, y1)]
        var count = 0
        let fade: [MaterialKey] = ["wood.painted-shaker-worn:5C9A8F", "wood.painted-shaker-worn:4C8A80", "wood.painted-shaker-worn:3F7A70", "wood.painted-shaker-worn:33695F", "wood.painted-shaker-worn:2A5C54"]
        for (hi, lo) in bands {
            let n2 = Int((hi - lo) / 0.045)
            let pitch = (hi - lo) / Float(n2)
            for i in 0..<n2 {
                let yc = hi - pitch * (Float(i) + 0.5)
                s.add(Prim.extrude(Shape2D.rounded(slat, radius: 0.0018, segments: 1), depth: iw + 0.03, bevel: 0.0008, bevelSegments: 1, material: fade[min(4, max(0, Int((-yc / sh) * 5 + Float((i * 7 + count) % 3) * 0.6 - 0.5)))]),
                      Xform(translation: V3(0, yc, t / 2), rotation: FA.q(-90, FA.Y)))
                count += 1
            }
        }
        // Bead moulding stuck round each louvre field.
        for (hi, lo) in bands {
            FJ.mouldedFrame(&s, cx: 0, cy: (hi + lo) / 2, w: iw, h: hi - lo, z: t * 0.92, profile: FJ.beadProfile(0.006, segments: 4), paint, r: 0.003)
        }
        // Pegs through the stiles at each rail.
        for e: Float in [-1, 1] {
            for y in [-topRail / 2, ym, -sh + botRail / 2] as [Float] {
                FA.cylZ(&s, r: 0.0055, h: 0.003, at: V3(e * (sw / 2 - stile / 2), y, t), "wood.weathered", bevel: 0.0008, segments: 8)
            }
        }
        // Hinge leaves on the top rail, 2 per shutter, with screws; barrel pivots at the hinge line.
        for e: Float in [-1, 1] {
            let x = e * 0.38
            FA.box(&s, V3(0.07, 0.11, 0.004), V3(x, -0.07, t + 0.002), iron, r: 0.0015)
            for dy in [-0.03, -0.11] as [Float] { rivet(&s, at: V3(x, dy - 0.0, t + 0.004), normal: FA.Z, radius: 0.0045, segments: 6, material: "metal.screw-zinc") }
        }
        // Paint chips on the bottom rail and stile feet, and wear along the leading edge.
        var chipRng = rng.fork(2)
        FJ.chips(&s, spots: [V3(-0.45, -sh + 0.05, 0), V3(0.3, -sh + 0.04, 0), V3(-0.53, -sh + 0.25, 0), V3(0.53, -sh + 0.3, 0), V3(0.1, -sh + 0.08, 0), V3(-0.2, -sh + 0.2, 0), V3(0.45, -sh + 0.15, 0), V3(-0.55, -0.1, 0), V3(0.5, -0.09, 0), V3(-0.55, -0.7, 0)],
                 face: t, "wood.weathered", rng: &chipRng, each: 7)
        // Pull handle on the bottom rail: two posts and a bar, with a fixing screw in each post.
        for dx in [-0.07, 0.07] as [Float] {
            FA.cylZ(&s, r: 0.007, h: 0.011, at: V3(dx, -sh + 0.075, t), iron, bevel: 0.0012, segments: 10)
            rivet(&s, at: V3(dx, -sh + 0.075, t + 0.011), normal: FA.Z, radius: 0.005, segments: 6, material: "metal.screw-zinc")
        }
        FA.rod(&s, V3(-0.07, -sh + 0.075, t + 0.011), V3(0.07, -sh + 0.075, t + 0.011), r: 0.005, iron)
        // Bare-wood slivers where the paint has worn off the stile arrises.
        for k in 0..<22 {
            let e: Float = k % 2 == 0 ? -1 : 1
            let len = rng.float(0.03...0.12), y = -rng.float(0.15...(sh - 0.05))
            FJ.slab(&s, V3(0.003, len, 0.0016), V3(e * (sw / 2 - 0.0015), y, t - 0.0004), "wood.weathered")
        }
        // Splash-grimed lower stiles.
        for e: Float in [-1, 1] { FA.box(&s, V3(stile + 0.002, 0.3, t + 0.002), V3(e * (sw / 2 - stile / 2), -sh + 0.27, t / 2), splash, r: 0.004) }
        let rot = FA.q(-openAngle, FA.X)
        let xf = Xform(translation: V3(0, yHinge, hdrT + 0.004), rotation: rot)
        m.add(s, xf)

        // Lap siding behind the shutter: seven clapboards, grimy at the foot.
        for k in 0..<8 {
            let y = 0.04 + Float(k) * ((yHinge - 0.04) / 8)
            FA.run(&m, [V2(0, 0), V2(0.018, 0), V2(0.014, (yHinge - 0.04) / 8 + 0.004), V2(0.006, (yHinge - 0.04) / 8 + 0.004), V2(0, (yHinge - 0.04) / 8 - 0.02)], length: W, at: V3(0, y, 0),
                   k < 2 ? "wood.painted-shaker-worn:B9B2A0" : "wood.painted-exterior:E9E3D2", bevel: 0.0012)
        }
        // Header board with a drip cap, fixed to the wall, and hinge barrels.
        FA.box(&m, V3(W, hdrH, hdrT), V3(0, H - hdrH / 2, hdrT / 2), header, r: 0.003)
        FA.run(&m, [V2(0, 0), V2(0.05, 0), V2(0.05, 0.005), V2(0.042, 0.011), V2(0.034, 0.014), V2(0.034, 0.019), V2(0, 0.019)], length: W, at: V3(0, H - 0.019, 0), header, bevel: 0.0012)
        FA.run(&m, [V2(0, 0), V2(0.026, 0), V2(0.026, 0.004), V2(0.02, 0.01), V2(0, 0.01)], length: W - 0.01, at: V3(0, H - hdrH - 0.001, 0), header, bevel: 0.001)   // bed bead
        // Sill board with a weathered nose under the siding.
        FA.run(&m, [V2(0, 0), V2(0.075, 0), V2(0.075, 0.01), V2(0.058, 0.04), V2(0, 0.04)], length: W, at: V3(0, 0, 0), "wood.painted-shaker-worn:B9B2A0", bevel: 0.002)
        for i in 0..<7 {
            let x = -W / 2 + 0.06 + Float(i) * (W - 0.12) / 6
            rivet(&m, at: V3(x, H - 0.045, hdrT), normal: FA.Z, radius: 0.0045, segments: 6, material: "metal.screw-zinc")
        }
        // Rust bleed running down the siding from each hinge barrel.
        for e: Float in [-1, 1] {
            for k in 0..<3 {
                FJ.slab(&m, V3(rng.float(0.004...0.012), rng.float(0.08...0.3), 0.0014), V3(e * 0.38 + rng.float(-0.03...0.03), yHinge - 0.2 - rng.float(0...0.2), 0.0185),
                        "metal.rust")
            }
        }
        for e: Float in [-1, 1] {
            let x = e * 0.38
            FA.cylX(&m, r: 0.009, h: 0.07, at: V3(x, yHinge + 0.003, hdrT + 0.0045), iron, bevel: 0.001, segments: 12)
            FA.box(&m, V3(0.07, 0.06, 0.004), V3(x, yHinge + 0.04, hdrT + 0.002), iron, r: 0.0015)       // wall leaf
            for dy in [0.025, 0.055] as [Float] { rivet(&m, at: V3(x, yHinge + dy, hdrT + 0.004), normal: FA.Z, radius: 0.0045, segments: 6, material: "metal.screw-zinc") }
        }
        // Prop stays: iron rods from a pivot bolt on the shutter back to a wall eye.
        for e: Float in [-1, 1] {
            let x = e * (sw / 2 + 0.012)
            let local = V3(x, -sh + 0.12, t * 0.5)
            let p = xf.translation + xf.rotation.act(local)
            let eye = V3(x, 0.78, hdrT + 0.012)
            FA.rod(&m, p, eye, r: 0.0085, iron)
            FA.ball(&m, r: 0.011, at: p, iron)
            m.add(Prim.torus(major: 0.012, minor: 0.0032, segments: 14, sides: 6, material: iron), Xform(translation: eye + V3(0, 0.002, 0), rotation: FA.q(90, FA.Y)))
            FA.cylZ(&m, r: 0.016, h: 0.004, at: V3(x, 0.78, hdrT), iron, bevel: 0.001, segments: 12)
            FA.box(&m, V3(0.02, 0.05, 0.006), V3(x, p.y + 0.0, p.z), iron, r: 0.002)
        }
        groundAO(&m, height: 0.2, floor: 0.75)
        return LODModel(FC.place(m))
    }
}
