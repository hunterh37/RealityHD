import simd
import Foundation

/// Cast lead rainwater hopper, Georgian: 400 mm wide at the lip, 450 mm high, 300 mm deep. A tapered open hopper of 5 mm
/// cast lead against the wall, rolled top lip, three vertical ribs and a horizontal band on the front, a raised date
/// panel with a cast cipher and four rosettes, a round outlet spigot with two bead rings, nailed wall ears at the
/// back corners, a wall strap under the outlet, and oxide bloom, run-off streaks and a debris stain inside.
public struct CastLeadRainwaterHopper: RealAsset {
    public static let id = "cast-lead-rainwater-hopper"
    public static let summary = "Cast lead rainwater hopper, Georgian facade prop, 0.4 x 0.45 x 0.3 m."
    public static let tags = ["prop", "architecture", "facade", "trim", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 20, distance: 1.7)

    /// Cast lead body.
    public var lead: MaterialKey = "stone.cast-grey"
    /// Raised ornament, cleaner lead.
    public var cast: MaterialKey = "stone.limestone-sooted"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let topW: Float = 0.384, topD: Float = 0.29, botW: Float = 0.15, botD: Float = 0.12
        let yT: Float = 0.44, yB: Float = 0.08
        let wall: Float = 0.006
        // Body: outer skin and inner skin (flipped), back flat on the wall plane.
        func rings(_ w: Float, _ d: Float, _ w2: Float, _ d2: Float, _ yt: Float, _ yb: Float, _ zc: Float, _ zc2: Float) -> [[V3]] {
            [Prim.ring(Shape2D.rect(w2, d2), y: yb, offset: V3(0, 0, zc2)), Prim.ring(Shape2D.rect(w, d), y: yt, offset: V3(0, 0, zc))]
        }
        m.add(Prim.loft(rings(topW, topD, botW, botD, yT, yB, topD / 2, botD / 2), capStart: true, capEnd: false, material: lead))
        m.add(Prim.loft(rings(topW - 2 * wall, topD - 2 * wall, botW - 2 * wall, botD - 2 * wall, yT, yB, topD / 2 + wall / 2, botD / 2 + wall / 2), capStart: true, capEnd: false, material: "metal.rust-grime").flipped())
        func zf(_ y: Float) -> Float { botD + (topD - botD) * (y - yB) / (yT - yB) }
        let tilt = atan2(topD - botD, yT - yB)
        let tdeg = tilt * 180 / .pi
        let nF = V3(0, -sin(tilt), cos(tilt))
        func front(_ x: Float, _ y: Float, _ off: Float) -> V3 { V3(x, y, zf(y)) + nF * off }
        // Rolled top lip on all four sides.
        let lipH: Float = 0.016
        FA.box(&m, V3(topW + 0.014, lipH, 0.014), V3(0, yT, topD + 0.001), lead, r: 0.005)
        for sgn: Float in [-1, 1] { FA.box(&m, V3(0.014, lipH, topD + 0.008), V3(sgn * (topW / 2 + 0.0035), yT, topD / 2 + 0.002), lead, r: 0.005) }
        FA.box(&m, V3(topW + 0.014, lipH, 0.012), V3(0, yT, 0.004), lead, r: 0.005)
        // Front ribs follow the taper; horizontal band across the front at the waist.
        func halfW(_ y: Float) -> Float { (botW + (topW - botW) * (y - yB) / (yT - yB)) / 2 }
        for fx: Float in [-0.55, 0, 0.55] {
            let y0: Float = 0.12, y1: Float = 0.42
            FA.rod(&m, front(fx * halfW(y0), y0, 0.003), front(fx * halfW(y1), y1, 0.003), r: 0.0062, cast, sides: 8)
        }
        FA.box(&m, V3(2 * halfW(0.37) - 0.016, 0.02, 0.012), front(0, 0.37, 0.005), cast, r: 0.004, rot: FA.q(tdeg, FA.X))
        // Date panel: raised cartouche with cast cipher (stroke numerals) and four corner rosettes.
        let pc = front(0, 0.27, 0.005)
        FA.box(&m, V3(0.17, 0.085, 0.006), pc, cast, r: 0.003, rot: FA.q(tdeg, FA.X))
        FA.box(&m, V3(0.15, 0.065, 0.004), pc + nF * 0.003, "metal.rust-grime", r: 0.002, rot: FA.q(tdeg, FA.X))
        let digits = FSO.segments("1789", origin: V2(0, 0), h: 0.04, ws: 0.9, gap: 0.3)
        var dm = Model(name: "digits")
        for (a, b) in digits.segs { FSO.bar(&dm, a - V2(digits.width / 2, 0.02), b - V2(digits.width / 2, 0.02), w: 0.005, z: 0, t: 0.004, cast) }
        m.add(dm, Xform(translation: pc + nF * 0.0055, rotation: FA.q(tdeg, FA.X)))
        for (dx, dy) in [(-0.095, -0.05), (0.095, -0.05), (-0.095, 0.05), (0.095, 0.05)] as [(Float, Float)] {
            let y = 0.27 + dy * cos(tilt)
            FC.bead(&m, r: 0.0085, at: front(dx, y, 0.008), cast)
        }
        // Outlet spigot with bead rings and a flared lip.
        let sp: [(Float, Float)] = [(0, 0), (0.032, 0), (0.034, 0.004), (0.031, 0.01), (0.031, 0.03), (0.037, 0.034), (0.037, 0.04), (0.031, 0.044), (0.031, yB + 0.012), (0.0, yB + 0.012)]
        m.add(turned(sp, segments: 20, material: lead, seamTile: 0.2, grainVertical: true), Xform(translation: V3(0, 0, botD / 2 + 0.003)))
        // Wall ears with nails, wall strap under the outlet.
        for sgn: Float in [-1, 1] {
            FA.box(&m, V3(0.04, 0.07, 0.008), V3(sgn * 0.16, 0.39, 0.004), lead, r: 0.003)
            rivet(&m, at: V3(sgn * 0.16, 0.41, 0.008), normal: FA.Z, radius: 0.0042, segments: 8, material: "metal.cast-iron")
            rivet(&m, at: V3(sgn * 0.16, 0.37, 0.008), normal: FA.Z, radius: 0.0042, segments: 8, material: "metal.cast-iron")
        }
        FA.box(&m, V3(0.1, 0.03, 0.006), V3(0, 0.055, botD / 2 + 0.003 + 0.032), lead, r: 0.0025)
        for sgn: Float in [-1, 1] { rivet(&m, at: V3(sgn * 0.035, 0.055, botD / 2 + 0.003 + 0.0345), normal: FA.Z, radius: 0.0035, segments: 8, material: "metal.cast-iron") }
        // Weathering: oxide bloom blobs on the front, run-off streaks below the ornament, leaf litter inside.
        for _ in 0..<10 {
            let y = rng.float(0.13...0.42)
            FSO.blob(&m, at: front(rng.float(-0.6...0.6) * halfW(y), y, 0.0006), size: V3(rng.float(0.02...0.05), rng.float(0.015...0.035), 0.0016), rng.chance(0.55) ? "stone.limestone" : "stone.limestone-sooted", rot: FA.q(tdeg, FA.X))
        }
        for _ in 0..<5 {
            let y = rng.float(0.15...0.22)
            FSO.blob(&m, at: front(rng.float(-0.5...0.5) * halfW(y), y, 0.0007), size: V3(rng.float(0.008...0.014), rng.float(0.07...0.12), 0.0014), "wood.deadwood", rot: FA.q(tdeg, FA.X))
        }
        // Pressed dent on the left face, bird lime on the lip, rust at the ear nails, green algae at the spigot.
        FSO.blob(&m, at: front(-0.5 * halfW(0.2), 0.2, 0.0), size: V3(0.06, 0.05, 0.007), "stone.slate", rot: FA.q(tdeg, FA.X))
        for _ in 0..<5 {
            FSO.blob(&m, at: V3(rng.float(-0.17...0.17), yT + lipH / 2 + 0.0004, topD + 0.001), size: V3(rng.float(0.02...0.04), 0.0018, 0.012), "stone.limestone")
            FSO.blob(&m, at: front(rng.float(-0.5...0.5) * halfW(0.4), 0.4, 0.0006), size: V3(0.012, rng.float(0.04...0.08), 0.0014), "stone.limestone", rot: FA.q(tdeg, FA.X))
        }
        for sgn: Float in [-1, 1] { FSO.blob(&m, at: V3(sgn * 0.16, 0.36, 0.0095), size: V3(0.012, 0.03, 0.0016), "metal.rust") }
        FSO.blob(&m, at: front(0, 0.11, 0.0006), size: V3(0.07, 0.03, 0.0016), "stone.granite-moss", rot: FA.q(tdeg, FA.X))
        for k in 0..<4 {
            FSO.blob(&m, at: V3(rng.float(-0.1...0.1), yT - 0.062, topD / 2 + rng.float(-0.06...0.06)), size: V3(rng.float(0.03...0.05), 0.005, rng.float(0.02...0.04)), k % 2 == 0 ? "wood.deadwood" : "stone.granite-moss", rot: FA.q(rng.float(0...180), FA.Y))
        }
        groundAO(&m)
        return LODModel(FC.place(m))
    }
}
