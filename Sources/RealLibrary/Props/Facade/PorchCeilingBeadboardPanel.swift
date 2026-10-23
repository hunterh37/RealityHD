import simd
import Foundation

/// Southern porch ceiling beadboard panel, 2.4 x 1.2 m: thirteen 92 mm tongue-and-groove boards, each with a half-round
/// bead beside chamfered joint edges, backed by four cross cleats and two edge battens that are screwed together. Modelled
/// face up (+Y) so it can be gated and placed flat; rotate 180 degrees about X to hang it on a ceiling. Haint-blue paint
/// is sun-faded, a few boards are butt-jointed mid-run, bead crowns are worn to bare wood, face nails and filled nail
/// holes dot the field, rust bleeds from steel heads and a water stain runs across the lower corner.
public struct PorchCeilingBeadboardPanel: RealAsset {
    public static let id = "porch-ceiling-beadboard-panel"
    public static let summary = "Southern porch ceiling beadboard panel, 2.4 x 1.2 m: tongue and groove boards with bead profile, blue painted, framed by battens."
    public static let tags = ["prop", "architecture", "facade", "wood"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 32, distance: 3.4)

    /// Paint for the boards (worn).
    public var paintKey = "wood.painted-shaker-worn"
    /// Sun-faded haint blue (sRGB hex).
    public var blue: UInt32 = 0x7FA39F
    /// Number of boards across the 1.2 m width.
    public var boards = 13
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [6])
    }

    func hex(_ r: Int, _ g: Int, _ b: Int) -> String {
        String(format: "%02X%02X%02X", max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b)))
    }

    /// Board cross-section (z across, y thickness) with face at the low y: half-round bead, chamfered joint edges,
    /// tongue on the right and a groove on the left. Face-down; the whole panel is flipped at the end.
    func profile(p: Float, tongue: Bool, segs: Int) -> [V2] {
        let L = -p / 2, Rr = p / 2
        let yf: Float = 0.0035, yt: Float = 0.0125, ch: Float = 0.0012
        let br: Float = 0.0035, zb = L + 0.0155
        var pts: [V2] = [V2(L, yf + ch), V2(L + ch, yf)]
        pts.append(V2(zb - br - 0.0016, yf)); pts.append(V2(zb - br - 0.0008, yf + 0.0009)); pts.append(V2(zb - br, yf))
        for i in 0...segs {
            let a = Float.pi * (1 - Float(i) / Float(segs))
            pts.append(V2(zb + br * cos(a), yf - br * sin(a)))
        }
        pts.append(V2(zb + br + 0.0008, yf + 0.0009)); pts.append(V2(zb + br + 0.0016, yf))
        pts.append(V2(Rr - ch, yf)); pts.append(V2(Rr, yf + ch))
        if tongue {
            pts += [V2(Rr, 0.0062), V2(Rr + 0.0052, 0.0066), V2(Rr + 0.006, 0.0075), V2(Rr + 0.0052, 0.0084), V2(Rr, 0.0088)]
        }
        pts.append(V2(Rr, yt)); pts.append(V2(L, yt))
        pts += [V2(L, 0.0090), V2(L + 0.0062, 0.0086), V2(L + 0.0062, 0.0064), V2(L, 0.0060)]
        return pts
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let br = Int((blue >> 16) & 0xFF), bg = Int((blue >> 8) & 0xFF), bb = Int(blue & 0xFF)
        func tone(_ d: Int) -> MaterialKey { "\(paintKey):" + hex(br + d, bg + d, bb + d) }
        let Lx: Float = 2.4, Wz: Float = 1.2
        let p = Wz / Float(boards)
        let yt: Float = 0.0125
        var zc: [Float] = []
        var splitAt: [Float?] = []
        for i in 0..<boards {
            let z = -Wz / 2 + p * (Float(i) + 0.5)
            zc.append(z)
            let tg = i < boards - 1
            let prof = profile(p: p, tongue: tg, segs: lite ? 3 : 6)
            let mat = tone(rng.int(-24...12))
            if rng.chance(0.45) {
                let s = rng.float(-0.7...0.7)
                splitAt.append(s)
                let l1 = (Lx / 2 + s) - 0.0004, l2 = (Lx / 2 - s) - 0.0004
                FA.run(&m, prof, length: l1, at: V3(-Lx / 2 + l1 / 2, 0, z), mat, bevel: 0.0005)
                FA.run(&m, prof, length: l2, at: V3(Lx / 2 - l2 / 2, 0, z), tone(rng.int(-18...10)), bevel: 0.0005)
            } else {
                splitAt.append(nil)
                FA.run(&m, prof, length: Lx, at: V3(0, 0, z), mat, bevel: 0.0005)
            }
        }
        // Bead crowns worn to bare wood in patches.
        if !lite {
            for i in 0..<boards {
                let zb = zc[i] - p / 2 + 0.0155
                for _ in 0..<3 where rng.chance(0.8) {
                    let len = rng.float(0.05...0.35)
                    m.add(cuboid(V3(len, 0.0005, 0.0022), material: "wood.weathered:A8A08C"), Xform(translation: V3(rng.float(-1.1...1.1) * (1.15 - len / 2) / 1.15, 0.0001, zb)))
                }
            }
        }
        // Raw end grain where the boards were cut square, unpainted.
        if !lite {
            for i in 0..<boards { for sx: Float in [-1, 1] where rng.chance(0.8) {
                m.add(cuboid(V3(0.0008, 0.0072, p - 0.012), material: "wood.endgrain-weathered"), Xform(translation: V3(sx * (Lx / 2 - 0.0003), 0.0083, zc[i])))
            }}
        }
        // Backing: edge battens along X, cross cleats between them.
        let ct: Float = 0.0075
        let cy = yt + ct / 2 - 0.0008
        let edgeW: Float = 0.04
        for sz: Float in [-1, 1] {
            FA.box(&m, V3(Lx - 0.004, ct, edgeW), V3(0, cy, sz * (Wz / 2 - edgeW / 2 - 0.002)), "wood.pine-aged", r: 0.0012)
        }
        let cxs: [Float] = [-1.17, -0.39, 0.39, 1.17]
        for x in cxs {
            FA.box(&m, V3(0.05, ct, Wz - 2 * edgeW - 0.004), V3(x, cy, 0), "wood.pine-aged", r: 0.0012)
        }
        if !lite {
            // Screws through edge battens into cleats, nail heads and filled holes on the face.
            for x in cxs { for sz: Float in [-1, 1] {
                m.add(Prim.cylinder(radius: 0.0032, height: 0.0016, bevel: 0.0004, segments: 6, bevelSegments: 1, material: "metal.steel"),
                      Xform(translation: V3(x, cy + ct / 2 - 0.0002, sz * (Wz / 2 - edgeW / 2 - 0.002)), rotation: facing(FA.Y)))
            }}
            for i in 0..<boards {
                for x in cxs where rng.chance(0.55) {
                    let nz = zc[i] - p / 2 + 0.012 + rng.float(-0.0005...0.0005)
                    let steel = rng.chance(0.4)
                    m.add(Prim.cylinder(radius: steel ? 0.0016 : 0.0013, height: 0.0008, bevel: 0.0002, segments: 6, bevelSegments: 1, material: steel ? "metal.steel" : "wood.charred"),
                          Xform(translation: V3(x + rng.float(-0.003...0.003), 0.0035 - 0.0001, nz), rotation: facing(-FA.Y)))
                    if steel {
                        m.add(cuboid(V3(0.0011, 0.0003, rng.float(0.015...0.05)), material: "metal.rust"), Xform(translation: V3(x, 0.0031, max(-0.57, min(0.57, nz - 0.02)))))
                    }
                }
            }
            // Water stain across the lower corner and drip marks along two joints.
            m.add(cuboid(V3(0.55, 0.0003, 0.2), material: "\(paintKey):5F7872"), Xform(translation: V3(0.85, 0.00325, 0.38), rotation: FA.q(14, FA.Y)))
            for _ in 0..<5 {
                m.add(cuboid(V3(rng.float(0.05...0.2), 0.0003, rng.float(0.01...0.03)), material: "\(paintKey):66807A"), Xform(translation: V3(rng.float(0.5...1.15), 0.0032, rng.float(0.28...0.58))))
            }
            // Grime settled in the V-joints.
            for i in 1..<boards {
                for _ in 0..<3 where rng.chance(0.7) {
                    let gl = rng.float(0.1...0.7)
                    m.add(cuboid(V3(gl, 0.0004, 0.0016), material: "\(paintKey):45585A"),
                          Xform(translation: V3(rng.float(-1.0...1.0) * (1.19 - gl / 2) / 1.0, 0.0032, zc[i] - p / 2)))
                }
            }
            // Paint chips along joint chamfers.
            for _ in 0..<40 {
                let i = rng.int(0...(boards - 1))
                let cl = rng.float(0.02...0.1)
                m.add(cuboid(V3(cl, 0.0004, 0.0013), material: "wood.weathered"),
                      Xform(translation: V3(rng.float(-1.15...1.15), 0.0035 - 0.0001, zc[i] + (rng.chance(0.5) ? -p / 2 + 0.0005 : p / 2 - 0.0005))))
            }
        }
        _ = splitAt
        _ = rng
        let flipped = m.transformed(Xform(rotation: FA.q(180, FA.X)))
        return FC.place(flipped)
    }
}
