import simd
import Foundation

/// English pub swinging sign: a wrought iron frame with corner rosettes and a scrolled crest topped by a
/// spear finial, a painted board hung from two eye bolts and S links, a gilt border and roundel, and
/// gilt lettering. The board face has weathered flaking paint and the iron is rust bloomed at the joints.
public struct PubHangingSign: RealAsset {
    public static let id = "pub-hanging-sign"
    public static let summary = "English pub swinging sign 0.8 x 1.0 m: wrought iron frame with scroll crest, painted board, gilt lettering, hanging links."
    public static let tags = ["prop", "architecture", "facade", "decor", "metal", "wood"]
    public static let budget = 14500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 26, elevation: 8, distance: 1.2)

    /// Pub name, two lines (A-Z, 0-9).
    public var title = ["THE", "RED LION"]
    public var iron: MaterialKey = "metal.wrought-iron"
    public var board: MaterialKey = "wood.painted-shaker-worn:7A1F1F"
    public var gilt: MaterialKey = "metal.gold-leaf"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Frame: top and bottom bars and two stiles, 0.54 x 0.66 inside, tube 8 mm.
        let fw: Float = 0.74, fh: Float = 0.62, y0: Float = 0.1
        let l = -fw / 2, r = fw / 2, b = y0, t = y0 + fh
        FA.path(&m, [V3(l, b, 0), V3(l, t, 0), V3(r, t, 0), V3(r, b, 0), V3(l, b, 0)], r: 0.0085, iron, sides: 10)
        for (x, y) in [(l, b), (l, t), (r, t), (r, b)] as [(Float, Float)] {
            m.add(Prim.superellipsoid(V3(0.036, 0.036, 0.022), exponent: 2, subdivisions: 4, material: iron), Xform(translation: V3(x, y, 0)))
            FG.dome(&m, at: V3(x, y, 0.012), r: 0.01, mat: "metal.rust")
        }
        // Scroll crest: facing C scrolls rising from the top bar to a central spear finial.
        for sx: Float in [-1, 1] {
            FA.path(&m, FG.spiral(c: V3(sx * 0.2, t + 0.09, 0), u: FA.X * sx, v: FA.Y, r0: 0.085, r1: 0.014, a0: -.pi / 2 - 0.2, turns: 1.15, steps: 34), r: 0.0075, iron, sides: 8)
            FA.path(&m, FG.spiral(c: V3(sx * 0.36, t + 0.045, 0), u: FA.X * sx, v: FA.Y, r0: 0.05, r1: 0.012, a0: 1.3, turns: -0.95, steps: 26), r: 0.006, iron, sides: 6)
            FA.rod(&m, V3(sx * 0.1, t, 0), V3(sx * 0.015, t + 0.16, 0), r: 0.006, iron, sides: 8)
        }
        FA.rod(&m, V3(0, t, 0), V3(0, t + 0.215, 0), r: 0.0085, iron, sides: 8)
        m.add(Prim.lathe([V2(0, 0), V2(0.012, 0.004), V2(0.022, 0.025), V2(0.012, 0.055), V2(0, 0.075)], segments: 14, seamTile: 0.2, material: iron), Xform(translation: V3(0, t + 0.215, 0)))
        FA.ball(&m, r: 0.011, at: V3(0, t + 0.21, 0), iron)
        // Hanging links: two eye bolts in the top bar, S hooks into the board eyes.
        let bw: Float = 0.6, bh: Float = 0.52, by = y0 + fh / 2 - 0.045
        let btop = by + bh / 2
        for sx: Float in [-1, 1] {
            let x = sx * 0.2
            m.add(Prim.torus(major: 0.012, minor: 0.0028, segments: 14, sides: 6, material: iron), Xform(translation: V3(x, t - 0.016, 0), rotation: FA.q(90, FA.Z)))
            FA.path(&m, FG.smooth([V3(x, t - 0.026, 0), V3(x + 0.01, t - 0.04, 0), V3(x - 0.008, t - 0.055, 0), V3(x, btop + 0.012, 0)]), r: 0.0032, iron, sides: 6)
            m.add(Prim.torus(major: 0.009, minor: 0.0028, segments: 12, sides: 6, material: iron), Xform(translation: V3(x, btop + 0.006, 0), rotation: FA.q(90, FA.Z)))
        }
        // Board: 0.5 x 0.6 x 0.032 with a moulded gilt frame, roundel and lettering.
        FA.box(&m, V3(bw, bh, 0.045), V3(0, by, 0), board, r: 0.005)
        let fz: Float = 0.0225
        var face = Model(name: "face")
        for (w, h, x, y) in [(bw, 0.03, 0.0, by + bh / 2 - 0.015), (bw, 0.03, 0.0, by - bh / 2 + 0.015), (0.03, bh - 0.06, -bw / 2 + 0.015, by), (0.03, bh - 0.06, bw / 2 - 0.015, by)] as [(Float, Float, Float, Float)] {
            FA.box(&face, V3(w, h, 0.009), V3(x, y, fz + 0.002), gilt, r: 0.0022)
        }
        FG.flat(&face, V3(bw - 0.1, 0.005, 0.0012), V3(0, by + bh / 2 - 0.05, fz + 0.0006), gilt)
        // Roundel with a stylised lion mask: gilt ring, red field, gilt face.
        let rc = V3(0, by + 0.1, fz)
        face.add(Prim.torus(major: 0.105, minor: 0.0075, segments: 40, sides: 8, material: gilt), Xform(translation: rc + V3(0, 0, 0.006), rotation: FA.q(90, FA.X)))
        FA.cylZ(&face, r: 0.1, h: 0.003, at: rc, "sign.red:4D1313", bevel: 0.0005, segments: 36)
        FA.cylZ(&face, r: 0.054, h: 0.005, at: rc + V3(0, 0, 0.002), gilt, bevel: 0.002, segments: 24)
        for sx: Float in [-1, 1] {
            face.add(Prim.superellipsoid(V3(0.02, 0.02, 0.01), exponent: 2, subdivisions: 3, material: "plastic.black"), Xform(translation: rc + V3(sx * 0.02, 0.012, 0.0095)))
            FA.box(&face, V3(0.018, 0.006, 0.004), rc + V3(sx * 0.028, 0.038, 0.008), gilt, r: 0.001, rot: FA.q(sx * 25, FA.Z))
        }
        FA.box(&face, V3(0.014, 0.03, 0.006), rc + V3(0, -0.012, 0.009), "metal.brass-aged", r: 0.002)
        FA.box(&face, V3(0.05, 0.006, 0.005), rc + V3(0, -0.04, 0.0085), "plastic.black", r: 0.001)
        FG.text(&face, title[0], h: 0.045, stroke: 0.0075, depth: 0.003, at: V3(0, by - 0.06, fz), gilt)
        FG.text(&face, title[1], h: 0.062, stroke: 0.0105, depth: 0.003, at: V3(0, by - 0.145, fz), gilt)
        // Flaking paint down to the dark undercoat, different on each side.
        for _ in 0..<5 {
            FG.flat(&face, V3(rng.float(0.02...0.06), rng.float(0.015...0.04), 0.0006), V3(rng.float(-0.22...0.22), rng.float(by - 0.24...by + 0.24), fz + 0.0005), "wood.painted-shaker-worn:3A1511", rot: FA.q(rng.float(-30...30), FA.Z))
        }
        m.add(face)
        m.add(face, Xform(rotation: FA.q(180, FA.Y)))
        // Hanging arm stub through the top bar: pivot pin with end balls and a cotter.
        FA.rod(&m, V3(0, t, -0.036), V3(0, t, 0.036), r: 0.009, iron, sides: 10)
        FA.ball(&m, r: 0.014, at: V3(0, t, -0.036), iron)
        FA.ball(&m, r: 0.014, at: V3(0, t, 0.036), iron)
        // Rust drip from the lower left corner rosette.
        FG.flat(&m, V3(0.012, 0.1, 0.0004), V3(l + 0.004, b - 0.05, 0.009), "metal.rust-grime")
        groundAO(&m, height: 0.05, floor: 0.95)
        return LODModel(FC.place(m))
    }
}
