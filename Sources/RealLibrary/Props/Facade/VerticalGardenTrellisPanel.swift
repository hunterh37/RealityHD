import simd
import Foundation

/// Contemporary vertical garden trellis panel, 1.2 x 2.0 m: powder coated steel frame, tensioned stainless wire
/// grid on 0.1 m centres, three galvanized planter troughs with potting soil and leaf mass, trailing stems and wall
/// standoffs. Wall face at z = 0, planters project toward +Z.
public struct VerticalGardenTrellisPanel: RealAsset {
    public static let id = "vertical-garden-trellis-panel"
    public static let summary = "Vertical garden trellis panel, 1.2 x 2.0 m: steel frame, wire grid, three galvanized planters with trailing plants."
    public static let tags = ["prop", "architecture", "facade", "metal", "wood"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 10, distance: 1.1)

    /// Frame and trough powder coat.
    public var frame: MaterialKey = "metal.powdercoat-worn"
    /// Wire.
    public var wire: MaterialKey = "metal.stainless"
    /// Planter trough steel.
    public var trough: MaterialKey = "metal.painted:46503F"
    /// Potting soil.
    public var soil: MaterialKey = "soil.potting"
    /// Leaf mass.
    public var leaf: MaterialKey = "leaf.boxwood-mass:5E8E3A"
    /// Stem.
    public var stem: MaterialKey = "plant.stem"
    public init() {}

    /// Lumpy leaf mass: superellipsoid with fBm displacement so it reads as overlapping foliage.
    func lump(_ size: V3, _ k: Float, _ sub: Int, _ mat: MaterialKey? = nil) -> Surface {
        var s = Prim.superellipsoid(size, exponent: 2, subdivisions: sub, material: mat ?? leaf)
        let amp = min(size.x, size.y) * 0.13
        s.displace { p, _ in amp * Noise.fbm(p * (14 / max(size.x, 0.05)) + V3(k, k * 0.7, k * 1.3), octaves: 2) }
        return s
    }

    /// Ivy leaf: pointed heart outline extruded 3 mm, with a mid-vein ridge, in the xy plane facing +z.
    static let leafOutline: [V2] = [V2(0, 0), V2(0.015, 0.008), V2(0.019, 0.026), V2(0, 0.052), V2(-0.019, 0.026), V2(-0.015, 0.008)]

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 1.2, H: Float = 2.0, D: Float = 0.15
        let fr: Float = 0.032
        let mixes: [MaterialKey] = [leaf, "leaf.privet-mass:6FA03E", "leaf.boxwood-mass:4A7A30"]
        // Welded frame: 32 mm square tube rails with mitred corners, back stand-off tabs.
        FA.box(&m, V3(fr, H, fr), V3(-W / 2 + fr / 2, H / 2, 0.02), frame, r: 0.003)
        FA.box(&m, V3(fr, H, fr), V3(W / 2 - fr / 2, H / 2, 0.02), frame, r: 0.003)
        FA.box(&m, V3(W - fr * 2, fr, fr), V3(0, H - fr / 2, 0.02), frame, r: 0.003)
        FA.box(&m, V3(W - fr * 2, fr, fr), V3(0, fr / 2 + 0.0, 0.02), frame, r: 0.003)
        // Weld beads at the corners.
        for sx: Float in [-1, 1] { for y: Float in [fr, H - fr] {
            FC.bead(&m, r: 0.008, at: V3(sx * (W / 2 - fr), y, 0.038), frame, sub: 2)
        } }
        // Wire grid: vertical wires every 0.1 m, horizontal wires every 0.1 m, woven by alternating z.
        let wz: Float = 0.036
        var x = -W / 2 + fr + 0.05
        var k = 0
        while x < W / 2 - fr - 0.02 {
            FA.rod(&m, V3(x, fr, wz), V3(x, H - fr, wz), r: 0.0022, wire, sides: 4)
            x += 0.1; k += 1
        }
        var y: Float = fr + 0.1
        while y < H - fr {
            FA.rod(&m, V3(-W / 2 + fr, y, wz + 0.0045), V3(W / 2 - fr, y, wz + 0.0045), r: 0.0022, wire, sides: 4)
            y += 0.1
        }
        // Wall standoffs: 6 cylinders with caps, each fixed by a hex bolt.
        for sx: Float in [-1, 1] { for yy: Float in [0.3, 1.0, 1.7] {
            FA.cylZ(&m, r: 0.011, h: 0.02, at: V3(sx * (W / 2 - fr / 2), yy, -0.0), frame, bevel: 0.002, segments: 8)
            rivet(&m, at: V3(sx * (W / 2 - fr / 2), yy, 0.0), normal: V3(0, 0, -1), radius: 0.008, material: wire)
        } }
        // Planter troughs: open steel boxes hung on hooks, soil, leaf mass and trailing stems.
        let rows: [Float] = [0.45, 1.05, 1.65]
        for (ri, ry) in rows.enumerated() {
            let tw: Float = 1.02, th: Float = 0.11, td: Float = 0.085
            let cz: Float = 0.04 + td / 2
            // Floor and front/back/ends of the trough with a rolled lip.
            FC.brickBox(&m, V3(tw, td, 0.004), V3(0, ry, cz), trough, r: 0.0008, rot: FA.q(-90, FA.X))
            FC.brickBox(&m, V3(tw, th, 0.004), V3(0, ry + th / 2, 0.04 + td - 0.002), trough, r: 0.001)
            FC.brickBox(&m, V3(tw, th, 0.004), V3(0, ry + th / 2, 0.042), trough, r: 0.001)
            for s: Float in [-1, 1] { FC.brickBox(&m, V3(td, th, 0.004), V3(s * (tw / 2 - 0.002), ry + th / 2, cz), trough, r: 0.001, rot: FA.q(90, FA.Y)) }
            FA.rod(&m, V3(-tw / 2, ry + th, 0.04 + td - 0.002), V3(tw / 2, ry + th, 0.04 + td - 0.002), r: 0.0035, trough, sides: 8)
            FA.rod(&m, V3(-tw / 2, ry + th, 0.042), V3(tw / 2, ry + th, 0.042), r: 0.003, trough, sides: 8)
            // Hanger hooks over the top rail of the grid, riveted to the trough back.
            for hx: Float in [-0.4, 0.4] {
                FA.box(&m, V3(0.025, 0.07, 0.003), V3(hx, ry + th - 0.01, 0.0385), frame, r: 0.0008)
                rivet(&m, at: V3(hx, ry + th - 0.03, 0.0415), normal: V3(0, 0, 1), radius: 0.0035, material: wire)
            }
            // Soil fill with a rough surface.
            var fork = rng.fork(ri + 1)
            FC.brickBox(&m, V3(tw - 0.012, td - 0.012, 0.012), V3(0, ry + th - 0.016, cz), soil, r: 0.003, rot: FA.q(-90, FA.X))
            // Leaf masses along the trough: overlapping flattened domes.
            let clumps = 9
            for c in 0..<clumps {
                let span: Float = (tw - 0.12) / Float(clumps - 1)
                let jx: Float = fork.float(-0.02...0.02)
                let cx: Float = -tw / 2 + 0.06 + Float(c) * span + jx
                let r = fork.float(0.05...0.07)
                let cy = ry + th + r * 0.45 + 0.004
                m.add(lump(V3(r * 2.4, r * 1.7, r * 1.15), fork.float(0...50), 2, mixes[c % 3]),
                      Xform(translation: V3(cx, cy, cz + fork.float(-0.01...0.01)), rotation: FA.q(fork.float(-12...12), FA.Y)))
            }
            // Trailing stems: tubes from the front lip curving down and clinging to the wires; leaf clumps along them.
            for t in 0..<5 {
                let jt: Float = fork.float(-0.03...0.03)
                let sx: Float = -tw / 2 + 0.14 + Float(t) * 0.17 + jt
                let len = fork.float(0.2...0.32)
                var path: [V3] = []
                for i in 0...8 {
                    let u = Float(i) / 8
                    path.append(V3(sx + sin(u * 4 + Float(t)) * 0.02, ry + th - u * len, 0.04 + td + 0.002 - u * 0.03 + fork.float(-0.003...0.003)))
                }
                m.add(Prim.tube(path, radii: path.indices.map { 0.0028 - 0.001 * Float($0) / 8 }, sides: 5, seamTile: 0.1, material: stem, capEnd: true))
                for (i, p) in path.enumerated() where i > 0 && i % 2 == 0 {
                    for side: Float in [-1, 1] {
                        let tilt = side * fork.float(35...75)
                        let sc = fork.float(0.9...1.5)
                        m.add(Prim.extrude(Self.leafOutline, depth: 0.0025, bevel: 0.0004, bevelSegments: 1, material: mixes[(i + t) % 3]),
                              Xform(translation: p + V3(side * 0.004, 0, 0.003), rotation: FA.q(fork.float(150...210) + tilt, FA.Z) * FA.q(fork.float(-25...25), FA.X),
                                    scale: V3(repeating: sc)))
                    }
                }
            }
        }
        // Climber: one strong vine tracking up the wire grid on the right side with a tendril loop.
        var vp: [V3] = []
        for i in 0...22 {
            let u = Float(i) / 22
            vp.append(V3(0.38 + sin(u * 9) * 0.05, 0.6 + u * 1.2, wz + 0.007 + 0.004 * sin(u * 20)))
        }
        m.add(Prim.tube(vp, radii: vp.indices.map { 0.0032 - 0.0012 * Float($0) / 22 }, sides: 5, seamTile: 0.1, material: stem, capEnd: true))
        for (i, p) in vp.enumerated() {
            for side: Float in [-1, 1] where (i % 2 == 0) == (side > 0) {
                m.add(Prim.extrude(Self.leafOutline, depth: 0.0025, bevel: 0.0004, bevelSegments: 1, material: mixes[(i + 1) % 3]),
                      Xform(translation: p + V3(0, 0, 0.006), rotation: FA.q(Float(i) * 53 + side * 70, FA.Z) * FA.q(side * 20, FA.X), scale: V3(repeating: 1.3)))
            }
        }
        var vp2: [V3] = []
        for i in 0...20 {
            let u = Float(i) / 20
            vp2.append(V3(-0.33 + sin(u * 7 + 1) * 0.06, 0.2 + u * 1.5, wz + 0.007 + 0.004 * sin(u * 17)))
        }
        m.add(Prim.tube(vp2, radii: vp2.indices.map { 0.003 - 0.001 * Float($0) / 20 }, sides: 5, seamTile: 0.1, material: stem, capEnd: true))
        for (i, p) in vp2.enumerated() {
            for side: Float in [-1, 1] where (i % 2 == 0) == (side > 0) {
                m.add(Prim.extrude(Self.leafOutline, depth: 0.0025, bevel: 0.0004, bevelSegments: 1, material: mixes[i % 3]),
                      Xform(translation: p + V3(0, 0, 0.006), rotation: FA.q(Float(i) * 41 + side * 65 + 30, FA.Z) * FA.q(side * 20, FA.X), scale: V3(repeating: 1.3)))
            }
        }
        // Drip stains under each trough: soil-brown streaks on the wire and frame, and a rust spot at each hook.
        for ry in rows {
            for sx: Float in [-0.35, -0.1, 0.2, 0.42] {
                FC.brickBox(&m, V3(0.006, 0.09, 0.0015), V3(sx, ry - 0.05, 0.0415 + 0.0), "soil.potting", r: 0.0004)
            }
        }
        // Wear: dead leaves browning among the trailing growth, chipped powder coat rusting at the frame feet and weld beads.
        var wr = rng.fork(61)
        for k in 0..<7 {
            let ry = rows[k % 3]
            let p = V3(wr.float(-0.45...0.45), ry - wr.float(0.04...0.22), 0.058)
            m.add(Prim.extrude(Self.leafOutline, depth: 0.0025, bevel: 0.0004, bevelSegments: 1, material: "leaf.oak-fallen"),
                  Xform(translation: p, rotation: FA.q(wr.float(120...240), FA.Z) * FA.q(wr.float(-20...20), FA.X), scale: V3(repeating: 1.2)))
        }
        for sx: Float in [-1, 1] {
            for k in 0..<3 {
                FC.brickBox(&m, V3(0.014, wr.float(0.02...0.06), 0.0012), V3(sx * (W / 2 - fr / 2), 0.03 + Float(k) * 0.07, 0.0366 + 0.0), "metal.rust", r: 0.0004)
            }
        }
        FC.brickBox(&m, V3(0.5, 0.012, 0.0012), V3(0.1, fr / 2, 0.0366), "metal.rust", r: 0.0004)
        groundAO(&m, height: 0.25, floor: 0.88)
        return LODModel(FC.seatY(FA.centerZ(m)))
    }
}
