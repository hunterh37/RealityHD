import simd
import Foundation

/// Haussmann continuous balcony, 6.0 x 1.0 x 0.9 m: a moulded limestone slab (cyma, corona and drip) in three
/// bedded sections on five scrolled corbels with acanthus drops, carrying a black iron railing of square posts with
/// ball caps, a flat handrail with a half-round cap, collared balusters and a ring-and-lozenge panel in each of the
/// four bays. Soot darkens the corbels and slab underside, rust bleeds from the post bases onto the stone.
public struct HaussmannBalconyContinuous: RealAsset {
    public static let id = "haussmann-balcony-continuous"
    public static let summary = "Haussmann continuous balcony, 6.0 x 1.0 x 0.9 m: moulded limestone slab on five scrolled corbels with a four-bay iron railing of ring panels and balusters."
    public static let tags = ["prop", "architecture", "facade", "decor", "stone", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 16, distance: 1.0)

    /// Limestone of slab and corbels.
    public var stone: MaterialKey = "stone.limestone"
    /// Soot on the corbels, joints and slab soffit.
    public var soot: MaterialKey = "stone.limestone-sooted"
    /// Black painted wrought iron.
    public var iron: MaterialKey = "metal.wrought-iron"
    /// Rust.
    public var rust: MaterialKey = "metal.rust"
    /// Replacement bolt.
    public var bolt: MaterialKey = "metal.bolt-bright"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [8])
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let sides = lite ? 4 : 5
        let W: Float = 6.0, D: Float = 0.9
        let slabY0: Float = 0.2, slabY1: Float = 0.34
        // Slab: three bedded sections sharing one moulded profile (out from the wall, up).
        let prof: [V2] = [V2(0, slabY0), V2(0.76, slabY0), V2(0.8, slabY0 + 0.006), V2(0.8, slabY0 + 0.02), V2(0.86, slabY0 + 0.036), V2(0.9, slabY0 + 0.052),
                          V2(0.9, slabY0 + 0.092), V2(0.885, slabY0 + 0.104), V2(0.84, slabY0 + 0.112), V2(0.82, slabY1 - 0.004), V2(0.8, slabY1), V2(0, slabY1)]
        let secW = (W - 0.01) / 3
        for k in 0..<3 {
            let cx = (Float(k) - 1) * (secW + 0.005)
            FA.run(&m, prof, length: secW, at: V3(cx, 0, 0), stone, bevel: 0.004)
        }
        // Joint lines between sections, a drip groove under the front edge, and soot on the soffit.
        for k in [-1, 1] { FA.box(&m, V3(0.006, 0.0012, D - 0.12), V3((Float(k) * (secW + 0.005)) / 2 + Float(k) * secW / 2 * 0 + Float(k) * 0.0, slabY1 + 0.0004, 0.4), soot, r: 0.0004) }
        FA.box(&m, V3(W - 0.02, 0.012, 0.012), V3(0, slabY0 - 0.0005, D - 0.06), soot, r: 0.003)
        // Corbels: S-curved bracket profile with a volute on each flank and an acanthus drop on the face.
        for cxk in 0..<5 {
            let cx = Float(cxk - 2) * 1.3 + (cxk == 0 ? 0.3 : cxk == 4 ? -0.3 : 0)
            let front = catmull([V3(0.58, slabY0, 0), V3(0.56, 0.12, 0), V3(0.46, 0.06, 0), V3(0.3, 0.02, 0), V3(0.12, 0.0, 0)], per: lite ? 3 : 6)
            let outline: [V2] = [V2(0, slabY0), V2(0.0, 0.0)] + front.reversed().map { V2($0.x, $0.y) } + [V2(0.58, slabY0)]
            FA.side(&m, Shape2D.deduped(outline), thick: 0.26, at: V3(cx, 0, 0), stone, bevel: 0.004)
            // Volute on each flank.
            for s: Float in [-1, 1] {
                var pts: [V3] = [], rad: [Float] = []
                let n = lite ? 8 : 12
                for k in 0...n {
                    let t = Float(k) / Float(n), a = -.pi / 2 + t * 2.3 * .pi, r = 0.085 * (1 - 0.75 * t)
                    pts.append(V3(cx + s * 0.135, 0.11 + sin(a) * r, 0.43 + cos(a) * r)); rad.append(0.017 * (1 - 0.45 * t))
                }
                m.add(Prim.tube(pts, radii: rad, sides: lite ? 4 : 6, seamTile: 0.2, material: stone, capEnd: true))
                FC.bead(&m, r: 0.02, at: pts.last!, stone, sub: lite ? 1 : 2)
            }
            // Acanthus drop on the corbel face, a flattened lozenge.
            m.add(turned([(0, 0), (0.02, 0.015), (0.045, 0.07), (0.03, 0.14), (0, 0.18)], segments: lite ? 5 : 8, material: soot, seamTile: 0.2),
                  Xform(translation: V3(cx, 0.185, 0.0), rotation: FA.q(0, FA.X), scale: V3(1, 1, 0.7)).self)
            // Abacus block under the slab.
            FA.box(&m, V3(0.34, 0.03, 0.62), V3(cx, slabY0 - 0.015 + 0.0, 0.31), stone, r: 0.004)
            // Soot on the face of each corbel.
            FA.box(&m, V3(0.2, 0.04, 0.0016), V3(cx, 0.15, 0.0), soot, r: 0.0005)
        }
        // Railing over the slab, inset 0.04 from the edges.
        let px: Float = W / 2 - 0.04, zf: Float = D - 0.04, zw: Float = 0.035
        let y0 = slabY1, yTop: Float = 0.96
        // Handrail and rails.
        FA.box(&m, V3(2 * px + 0.04, 0.026, 0.05), V3(0, yTop - 0.007, zf), iron, r: 0.004)
        FA.rod(&m, V3(-px - 0.02, yTop + 0.01, zf), V3(px + 0.02, yTop + 0.01, zf), r: 0.012, iron, sides: sides + 1)
        FA.box(&m, V3(2 * px, 0.032, 0.03), V3(0, y0 + 0.07, zf), iron, r: 0.004)
        FA.box(&m, V3(2 * px, 0.016, 0.02), V3(0, y0 + 0.2, zf), iron, r: 0.002)
        for s: Float in [-1, 1] {
            FA.box(&m, V3(0.05, 0.026, zf - zw), V3(s * px, yTop - 0.007, (zf + zw) / 2), iron, r: 0.004)
            FA.rod(&m, V3(s * px, yTop + 0.01, zw), V3(s * px, yTop + 0.01, zf), r: 0.012, iron, sides: sides + 1)
            FA.box(&m, V3(0.03, 0.032, zf - zw), V3(s * px, y0 + 0.07, (zf + zw) / 2), iron, r: 0.004)
        }
        // Posts: every bay line, with ball caps; wall posts at the returns.
        let postXs: [Float] = [-px, -px / 2, 0, px / 2, px]
        for x in postXs {
            FA.box(&m, V3(0.045, yTop - y0 - 0.02, 0.045), V3(x, (yTop + y0) / 2 - 0.01, zf), iron, r: 0.004)
            FA.box(&m, V3(0.06, 0.05, 0.06), V3(x, y0 + 0.025, zf), iron, r: 0.005)
            FC.bead(&m, r: 0.028, at: V3(x, yTop + 0.012, zf), iron, sub: lite ? 1 : 2)
        }
        for s: Float in [-1, 1] {
            FA.box(&m, V3(0.045, yTop - y0 - 0.02, 0.045), V3(s * px, (yTop + y0) / 2 - 0.01, zw), iron, r: 0.004)
            FA.box(&m, V3(0.06, 0.05, 0.06), V3(s * px, y0 + 0.025, zw), iron, r: 0.005)
            // Return balusters.
            for k in 0..<5 {
                let z = zw + 0.14 + Float(k) * 0.14
                FA.rod(&m, V3(s * px, y0 + 0.07, z), V3(s * px, yTop - 0.02, z), r: 0.008, iron, sides: sides)
                FC.bead(&m, r: 0.013, at: V3(s * px, y0 + 0.2, z), iron, sub: 1)
            }
        }
        // Bays: balusters flanking a ring-and-lozenge panel.
        let bayW = px / 2 * 1.0
        for b in 0..<4 {
            let x0 = postXs[b], x1 = postXs[b + 1], cxb = (x0 + x1) / 2, cy = y0 + 0.36
            for sd: Float in [-1, 1] {
                for k in 0..<3 {
                    let x = cxb + sd * (0.34 + Float(k) * 0.115)
                    FA.rod(&m, V3(x, y0 + 0.07, zf), V3(x, yTop - 0.02, zf), r: 0.008, iron, sides: sides)
                    FC.bead(&m, r: 0.013, at: V3(x, y0 + 0.2, zf), iron, sub: 1)
                }
            }
            m.add(Prim.torus(major: 0.21, minor: 0.011, segments: lite ? 16 : 24, sides: sides, material: iron), Xform(translation: V3(cxb, cy, zf), rotation: FA.q(90, FA.X)))
            let d: Float = 0.25
            for (a, c) in [(V3(0, d, 0), V3(d, 0, 0)), (V3(d, 0, 0), V3(0, -d, 0)), (V3(0, -d, 0), V3(-d, 0, 0)), (V3(-d, 0, 0), V3(0, d, 0))] {
                FA.rod(&m, V3(cxb, cy, zf) + a, V3(cxb, cy, zf) + c, r: 0.008, iron, sides: sides)
            }
            // Four inward C-scrolls and a centre boss.
            for k in 0..<4 {
                let ang = Float(k) * .pi / 2 + .pi / 4
                var pts: [V3] = [], rad: [Float] = []
                let c = V3(cxb + cos(ang) * 0.125, cy + sin(ang) * 0.125, zf)
                for j in 0...(lite ? 6 : 9) {
                    let t = Float(j) / Float(lite ? 6 : 9), a = ang + .pi * 0.9 + (k % 2 == 0 ? 1 : -1) * t * 1.8 * .pi, r = 0.07 * (1 - 0.78 * t)
                    pts.append(c + V3(cos(a) * r, sin(a) * r, 0)); rad.append(0.0065 * (1 - 0.3 * t))
                }
                m.add(Prim.tube(pts, radii: rad, sides: 4, seamTile: 0.1, material: iron, capEnd: true))
                FC.bead(&m, r: 0.011, at: pts.last!, iron, sub: 1)
            }
            m.add(turned([(0, 0), (0.04, 0), (0.04, 0.006), (0.03, 0.012), (0.016, 0.022), (0, 0.028)], segments: lite ? 8 : 14, material: iron, seamTile: 0.1),
                  Xform(translation: V3(cxb, cy, zf + 0.004), rotation: FA.q(90, FA.X)))
            FA.rod(&m, V3(x0 + 0.03, cy, zf), V3(cxb - 0.21, cy, zf), r: 0.0075, iron, sides: sides)
            FA.rod(&m, V3(x1 - 0.03, cy, zf), V3(cxb + 0.21, cy, zf), r: 0.0075, iron, sides: sides)
        }
        _ = bayW
        // Wear.
        if !lite {
            // Rust bleeding from post bases onto the stone, in streaks pointing out from the wall.
            for x in postXs {
                FO.patchTop(&m, cx: x, cz: zf, rx: rng.float(0.05...0.08), rz: rng.float(0.028...0.034), y: slabY1 + 0.0009, rust, rng: &rng, depth: 0.0008, n: 11)
                FO.patchTop(&m, cx: x + rng.float(-0.01...0.01), cz: zf - 0.07, rx: 0.015, rz: rng.float(0.04...0.07), y: slabY1 + 0.0007, rust, rng: &rng, depth: 0.0006, n: 7)
            }
            // Sooty rain-wash streaks across the slab top, and chips along the handrail cap.
            for _ in 0..<14 { FO.patchTop(&m, cx: rng.float(-2.9...2.9), cz: rng.float(0.1...0.8), rx: rng.float(0.05...0.2), rz: rng.float(0.03...0.12), y: slabY1 + 0.0006, soot, rng: &rng, depth: 0.0005) }
            for _ in 0..<18 { FO.patchTop(&m, cx: rng.float(-2.9...2.9), cz: zf + rng.float(-0.004...0.004), rx: rng.float(0.01...0.05), rz: 0.006, y: yTop + 0.0225, rust, rng: &rng, depth: 0.0006, n: 7) }
            // Corbel bed joints and iron fixing bolts through the post plinths.
            for x in postXs { for sd: Float in [-1, 1] { FO.head(&m, at: V3(x + sd * 0.018, y0 + 0.025, zf + 0.03), r: 0.0085, h: 0.005, segments: 6, (x == 0 && sd > 0) ? bolt : iron) } }
        }
        groundAO(&m, height: 0.25, floor: 0.75)
        return FC.place(m)
    }
}
