import simd
import Foundation

/// Elizabethan stone mullion and transom window, 1.6 m wide, 1.4 m tall, 250 mm projection: ashlar jambs with chamfered
/// reveals, a throated and weathered sill, a flat head with a label (hood) moulding returning down in square stops, a
/// chamfered central mullion and transom forming four lights, and in each light a wrought-iron casement with a
/// leaded diamond-quarry lattice and a saddle bar. Wear: sooted ashlar, moss on the sill, a cast-stone repair to one
/// jamb, rust at the iron, one cracked quarry.
public struct StoneMullionWindowQuad: RealAsset {
    public static let id = "stone-mullion-window-quad"
    public static let summary = "Elizabethan stone mullion and transom window, four lights, label hood, leaded glazing."
    public static let tags = ["prop", "architecture", "facade", "stone"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 8, distance: 3.6)

    /// Window stone.
    public var stone: MaterialKey = "stone.limestone"
    /// Wrought iron casements.
    public var iron: MaterialKey = "metal.wrought-iron"
    /// Quarry glass.
    public var glass: MaterialKey = "glass.pane"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 1.6, H: Float = 1.4, D: Float = 0.2, P: Float = 0.25
        let sillH: Float = 0.11, jw: Float = 0.17, headY0: Float = 1.2, headY1: Float = 1.31
        let hw = W / 2 - jw                                                      // half opening
        let mw: Float = 0.1, tH: Float = 0.09, tY: Float = 0.76                  // mullion width, transom height and centre
        let ch: Float = 0.022                                                    // reveal chamfer

        // Sill: weathered top, projecting nose with a drip throat.
        let sill: [V2] = [V2(0, 0), V2(P - 0.01, 0), V2(P - 0.01, 0.07), V2(P, 0.078), V2(P - 0.012, 0.09), V2(0.02, sillH), V2(0, sillH)]
        FO.colX(&m, sill, x0: -W / 2, x1: W / 2, stone, bevel: 0.003)
        FJ.slab(&m, V3(W - 0.02, 0.012, 0.003), V3(0, 0.054, P - 0.0035), "stone.limestone-sooted")                // throat shadow
        for x in [-0.42, 0.37] as [Float] { FA.box(&m, V3(0.0016, 0.07, P - 0.02), V3(x, 0.05, P / 2), "stone.limestone-sooted", r: 0.0006) }   // joints

        // Jambs: chamfered reveal on both opening faces, built up in ashlar courses with bed joints.
        for e: Float in [-1, 1] {
            let x1 = e * W / 2, x0 = e * hw
            let sec: [V2] = [V2(x1, 0), V2(x1, D), V2(x0 + e * ch, D), V2(x0, D - ch), V2(x0, ch), V2(x0 + e * ch, 0)]
            FO.colY(&m, sec, y0: sillH - 0.002, y1: headY0 + 0.002, stone, bevel: 0.002)
            for (i, y) in ([0.33, 0.55, 0.78, 0.99] as [Float]).enumerated() {
                FA.box(&m, V3(jw + 0.002, 0.0022, 0.002), V3(e * (hw + jw / 2), y + (i % 2 == 0 ? 0 : 0.02), D + 0.0005), "stone.limestone-sooted", r: 0.0006)
            }
        }
        // Head: flat lintel with the same chamfered reveal; label moulding above, returning down in square stops.
        let head: [V2] = [V2(0, headY0), V2(D - ch, headY0), V2(D, headY0 + ch), V2(D, headY1), V2(0, headY1)]
        FO.colX(&m, head, x0: -W / 2, x1: W / 2, stone, bevel: 0.002)
        FA.box(&m, V3(0.0018, headY1 - headY0, 0.002), V3(0.32, (headY0 + headY1) / 2, D + 0.0005), "stone.limestone-sooted", r: 0.0005)
        FA.box(&m, V3(0.0018, headY1 - headY0, 0.002), V3(-0.31, (headY0 + headY1) / 2, D + 0.0005), "stone.limestone-sooted", r: 0.0005)
        // Label: a drip-moulded course (fillet, cavetto, roll, throat) running the full width.
        let lab: [V2] = [V2(0.01, headY1), V2(D, headY1), V2(D + 0.014, headY1 + 0.012), V2(P, headY1 + 0.022), V2(P, headY1 + 0.05), V2(P - 0.014, headY1 + 0.066), V2(0.01, H)]
        FO.colX(&m, lab, x0: -W / 2, x1: W / 2, stone, bevel: 0.002)
        // Returns turned down each end, ending in a square label stop.
        for e: Float in [-1, 1] {
            let x = e * (W / 2 - 0.03)
            FA.box(&m, V3(0.06, 0.18, P - 0.012), V3(x, headY0 + 0.04 + 0.09 - 0.02, (P - 0.012) / 2 + 0.006), stone, r: 0.004)
            FA.box(&m, V3(0.06, 0.012, P - 0.004), V3(x, headY0 + 0.02, (P - 0.004) / 2 + 0.002), stone, r: 0.003)
        }

        // Mullion and transom: chamfered sections tenoned into the jambs and head.
        let mSec: [V2] = [V2(-mw / 2, ch), V2(-mw / 2 + ch, 0), V2(mw / 2 - ch, 0), V2(mw / 2, ch), V2(mw / 2, D - ch), V2(mw / 2 - ch, D), V2(-mw / 2 + ch, D), V2(-mw / 2, D - ch)]
        FO.colY(&m, mSec, y0: sillH - 0.002, y1: headY0 + 0.002, stone, bevel: 0.0015)
        let tSec: [V2] = [V2(ch, tY - tH / 2), V2(0, tY - tH / 2 + ch), V2(0, tY + tH / 2 - ch), V2(ch, tY + tH / 2), V2(D - ch, tY + tH / 2), V2(D, tY + tH / 2 - ch), V2(D, tY - tH / 2 + ch), V2(D - ch, tY - tH / 2)]
        FO.colX(&m, tSec, x0: -hw - 0.002, x1: hw + 0.002, stone, bevel: 0.0015)
        // Weathered drip groove under the transom nose.
        FJ.slab(&m, V3(2 * hw, 0.003, 0.003), V3(0, tY - tH / 2 + 0.004, D + 0.0005), "stone.limestone-sooted")

        // Casements: iron frame, saddle bar, leaded diamond quarries, one per light.
        let zc: Float = 0.085
        let lights: [(Float, Float, Float, Float)] = [                           // x0, x1, y0, y1
            (-hw, -mw / 2, sillH, tY - tH / 2), (mw / 2, hw, sillH, tY - tH / 2),
            (-hw, -mw / 2, tY + tH / 2, headY0), (mw / 2, hw, tY + tH / 2, headY0)]
        for (li, L) in lights.enumerated() {
            let x0 = L.0 + 0.004, x1 = L.1 - 0.004, y0 = L.2 + 0.004, y1 = L.3 - 0.004
            let w = x1 - x0, h = y1 - y0, cx = (x0 + x1) / 2, cy = (y0 + y1) / 2
            let fb: Float = 0.022
            // Frame of flat iron bars with rounded edges and a rebate for the glass.
            for sy: Float in [-1, 1] { FA.box(&m, V3(w, fb, 0.026), V3(cx, cy + sy * (h / 2 - fb / 2), zc), iron, r: 0.003) }
            for sx: Float in [-1, 1] { FA.box(&m, V3(fb, h - 2 * fb + 0.002, 0.026), V3(cx + sx * (w / 2 - fb / 2), cy, zc), iron, r: 0.003) }
            let iw = w - 2 * fb, ih = h - 2 * fb
            FJ.slab(&m, V3(iw, ih, 0.003), V3(cx, cy, zc - 0.002), glass)
            // Diamond lattice: lead cames clipped to the light.
            let pitch: Float = 0.085
            for dir: Float in [-1, 1] {
                let n = Int((iw + ih) / pitch) + 1
                for k in 0..<n {
                    // Line y = dir * (x - xs); clip to the rectangle in local coordinates.
                    let xs = -iw / 2 - ih / 2 + Float(k) * pitch
                    var pts: [V2] = []
                    for (px, py) in [(-iw / 2, dir * (-iw / 2 - xs)), (iw / 2, dir * (iw / 2 - xs))] { pts.append(V2(px, py)) }
                    // Intersections with top and bottom edges.
                    var seg: [V2] = []
                    for p in pts where abs(p.y) <= ih / 2 { seg.append(p) }
                    for yEdge in [-ih / 2, ih / 2] {
                        let x = xs + dir * yEdge
                        if abs(x) <= iw / 2 { seg.append(V2(x, yEdge)) }
                    }
                    if seg.count >= 2 {
                        seg.sort { $0.x < $1.x }
                        let a = seg.first!, b = seg.last!
                        if simd_distance(a, b) > 0.02 {
                            FA.rod(&m, V3(cx + a.x, cy + a.y, zc + 0.002), V3(cx + b.x, cy + b.y, zc + 0.002), r: 0.0026, "metal.tinned-copper", sides: 4)
                        }
                    }
                }
            }
            // Saddle bar across each light, tied to the lattice with lead ties.
            FA.box(&m, V3(w - 0.01, 0.011, 0.016), V3(cx, cy + (li < 2 ? 0.05 : 0.02), zc + 0.017), iron, r: 0.002)
            for sx: Float in [-1, 1] {
                FA.box(&m, V3(0.02, 0.018, 0.014), V3(cx + sx * (w / 2 - 0.02), cy + (li < 2 ? 0.05 : 0.02), zc + 0.0165), iron, r: 0.002)
            }
            // Rust bloom at the frame corners.
            for sx: Float in [-1, 1] { FJ.slab(&m, V3(0.03, 0.012, 0.0012), V3(cx + sx * (w / 2 - 0.03), y0 + 0.015, zc + 0.0136), "metal.rust") }
        }
        // Stay pin/hinge pintles on the mullion face for the casements.
        for y in [0.3, 0.52, 0.92, 1.1] as [Float] {
            FA.cylZ(&m, r: 0.006, h: 0.03, at: V3(0, y, zc - 0.005), iron, bevel: 0.0012, segments: 8)
        }
        // One cracked quarry: a dark lead-patched seam.
        FJ.slab(&m, V3(0.085, 0.0025, 0.002), V3(0.28, 0.4, zc + 0.0045), "metal.tinned-copper", rot: FA.q(40, FA.Z))

        // Wear: soot above the transom and under the label, moss on the sill, a cast-stone repair to the left jamb,
        // staining beneath the sill nose, chipped arris on the mullion.
        FJ.slab(&m, V3(W - 0.1, 0.03, 0.0014), V3(0, headY1 - 0.02, D + 0.0007), "stone.brownstone-sooted")
        for _ in 0..<6 {
            FJ.slab(&m, V3(rng.float(0.01...0.026), rng.float(0.08...0.3), 0.0014), V3(rng.float(-0.78...0.78), rng.float(0.5...1.1), D + 0.0008), "stone.limestone-sooted")
        }
        for _ in 0..<5 {
            m.add(Prim.superellipsoid(V3(rng.float(0.05...0.12), 0.005, rng.float(0.04...0.07)), exponent: 2, subdivisions: 4, material: "stone.granite-moss"),
                  Xform(translation: V3(rng.float(-0.65...0.65), sillH - 0.001, rng.float(0.12...0.22))))
        }
        FA.box(&m, V3(jw + 0.004, 0.2, D + 0.002), V3(-(hw + jw / 2), 0.34, D / 2), "stone.cast-stone", r: 0.003)                  // dutchman repair
        FA.box(&m, V3(jw - 0.02, 0.0022, 0.002), V3(-(hw + jw / 2), 0.44, D + 0.0012), "stone.limestone-sooted", r: 0.0006)
        for _ in 0..<5 {
            FJ.slab(&m, V3(rng.float(0.014...0.03), rng.float(0.01...0.02), 0.0016), V3(rng.float(-0.04...0.04), rng.float(0.2...1.1), D + 0.0008), "stone.limestone")
        }
        groundAO(&m, height: 0.18, floor: 0.7)
        return LODModel(FC.place(m))
    }
}
