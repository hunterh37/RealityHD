import simd
import Foundation

/// Folded plate roof bay: architectural facade customizer, modernism, weathered galvanized folded roof. Parts: folded galvanized plates, ridge cap flashing, valley gutter, timber valley beams, corner posts, end fascia band, downpipe, fastener rows.
public struct FoldedPlateRoofBay: RealAsset {
    public static let id = "folded-plate-roof-bay"
    public static let summary = "Folded plate roof bay, 4.0 x 1.5 x 6.0 m: six galvanized folded plates on timber valley beams and corner posts."
    public static let tags = ["prop", "architecture", "facade", "roof", "metal"]
    public static let budget = 24000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(4.0, 1.5, 6.0)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x - 0.2, D = size.z - 0.1, H = size.y
        let plates = 6, pw = W / Float(plates), yl: Float = 0.95, yh = H - 0.03
        let rise = yh - yl, chord = sqrt(pw * pw + rise * rise), ang = atan2(rise, pw) * 180 / .pi
        let pan: MaterialKey = "metal.galvanized", aged: MaterialKey = "metal.galvanized-aged", frame: MaterialKey = "metal.anodized-worn", wood: MaterialKey = "wood.cedar-weathered"
        func scr(_ c: V3, _ w: Float, _ q: simd_quatf = .identity) {
            m.add(Prim.cylinder(radius: w / 2, height: 0.004, bevel: 0, segments: 8, material: "metal.screw-zinc"), Xform(translation: c, rotation: q))
        }
        func fy(_ i: Int) -> Float { i % 2 == 0 ? yl : yh }       // fold line heights
        func fx(_ i: Int) -> Float { -W / 2 + pw * Float(i) }
        // End fascia bands following the zigzag.
        var top: [V2] = [], bot: [V2] = []
        for i in 0...plates { top.append(V2(fx(i), fy(i))); bot.append(V2(fx(i), fy(i) - 0.16)) }
        let outline = top + bot.reversed()
        for e: Float in [-1, 1] {
            m.add(Prim.extrude(outline, depth: 0.05, bevel: 0.004, bevelSegments: 1, material: frame),
                  Xform(translation: V3(0, 0, e * (D / 2 + 0.01) - 0.025)))
        }
        for i in 0..<plates {
            let up = fy(i) < fy(i + 1)
            let cx = (fx(i) + fx(i + 1)) / 2, cy = (fy(i) + fy(i + 1)) / 2
            let q = FA.q(up ? ang : -ang, FA.Z)
            FA.box(&m, V3(chord, 0.03, D), V3(cx, cy + 0.015, 0), pan, r: 0.004, rot: q)
            // Stiffening ribs and transverse lap joints with screws.
            for k in 0..<5 {
                let t = (Float(k) + 0.5) / 5 - 0.5
                FA.box(&m, V3(chord - 0.06, 0.018, 0.025), V3(cx + t * 0.0, cy + 0.04, -D / 2 + D * (Float(k) + 0.5) / 5), aged, r: 0.003, rot: q)
            }
            for k in 0...6 {
                let z = -D / 2 + 0.1 + (D - 0.2) * Float(k) / 6
                for s: Float in [-0.22, 0, 0.22] {
                    let px = cx + s * cos(ang * .pi / 180), py = cy + 0.034 + (up ? 1 : -1) * s * sin(ang * .pi / 180)
                    scr(V3(px, py, z), 0.014, q)
                }
            }
            for _ in 0..<4 {
                let t = rng.float(-0.25...0.25)
                FA.box(&m, V3(rng.float(0.05...0.12), 0.004, rng.float(0.4...1.2)), V3(cx + t, cy + 0.034 + t * (up ? 0.6 : -0.6), rng.float(-D / 2 + 0.6...D / 2 - 0.6)), "metal.rust-grime", r: 0.0004, rot: q)
            }
        }
        // Fold lines: ridge caps on highs, valley gutters on lows, timber beams below the valleys.
        for i in 0...plates {
            let x = fx(i), y = fy(i)
            if y == yh {
                FA.box(&m, V3(0.1, 0.03, D + 0.04), V3(x, y + 0.012, 0), aged, r: 0.006)
            } else {
                FA.box(&m, V3(0.16, 0.02, D + 0.04), V3(x, y - 0.012, 0), aged, r: 0.003)
                FA.box(&m, V3(0.1, 0.12, D), V3(x, y - 0.15, 0), wood, r: 0.004)
                for k in 0..<10 {
                    scr(V3(x, y - 0.0, -D / 2 + 0.2 + (D - 0.4) * Float(k) / 9), 0.012)
                }
                for _ in 0..<3 {
                    FA.box(&m, V3(0.1, 0.003, rng.float(0.15...0.35)), V3(x + rng.float(-0.03...0.03), y - 0.0, rng.float(-D / 2 + 0.4...D / 2 - 0.4)), "metal.rust-grime", r: 0.0004)
                }
            }
        }
        // Corner posts under the outer valleys with base plates and bolts.
        for x in [fx(0), fx(plates)] {
            for z in [-D / 2 + 0.15, D / 2 - 0.15] {
                let ph = yl - 0.23
                FA.box(&m, V3(0.1, ph, 0.1), V3(x, 0.012 + ph / 2, z), wood, r: 0.004)
                FA.box(&m, V3(0.18, 0.012, 0.18), V3(x, 0.006, z), frame, r: 0.002)
                for (bx, bz) in [(-0.06 as Float, -0.06 as Float), (0.06, 0.06), (-0.06, 0.06), (0.06, -0.06)] {
                    scr(V3(x + bx, 0.017, z + bz), 0.008 * 2)
                }
                FA.box(&m, V3(0.03, 0.4, 0.004), V3(x + 0.03, 0.35, z + 0.052), "metal.rust-grime", r: 0.0004)
            }
        }
        // Downpipe at one valley end.
        let dx = fx(0) - 0.08, dz = D / 2 - 0.15
        FA.rod(&m, V3(dx, yl - 0.1, dz), V3(dx, 0.03, dz), r: 0.035, aged, sides: 14)
        for y: Float in [0.2, 0.5, 0.8] {
            FA.box(&m, V3(0.08, 0.02, 0.025), V3(dx + 0.03, y, dz), frame, r: 0.003)
            FA.rod(&m, V3(dx, y - 0.015, dz), V3(dx, y + 0.015, dz), r: 0.042, frame, sides: 14)
        }
        FA.box(&m, V3(0.14, 0.05, 0.14), V3(dx, 0.025, dz), aged, r: 0.01)
        // Story detail: leaf litter caught in the first valley.
        for _ in 0..<4 {
            m.add(Prim.superellipsoid(V3(0.07, 0.006, 0.05), exponent: 2, subdivisions: 5, material: wood),
                  Xform(translation: V3(fx(0) + rng.float(-0.03...0.03), yl + 0.0, rng.float(1.0...2.4)), rotation: FA.q(rng.float(0...180), FA.Y)))
        }
        groundAO(&m)
        return LODModel(m)
    }
}
