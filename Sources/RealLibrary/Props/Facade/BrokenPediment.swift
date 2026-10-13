import simd
import Foundation

/// Broken pediment: architectural facade customizer, Baroque/Georgian. Parts: entablature, raking cornices, open apex gap, plinth block, urn finial, tympanum, dentils.
public struct BrokenPediment: RealAsset {
    public static let id = "broken-pediment"
    public static let summary = "Broken pediment, 1.8 m: triangular pediment with the apex opened and a pedestal with urn between the raking cornices."
    public static let tags = ["prop", "architecture", "facade", "trim", "decor", "stone"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.8, 0.8, 0.35)
    public init() {}

    /// Rake pitch as rise over run.
    public var pitch: Float = 0.38
    /// Half width of the open apex gap.
    public var gap: Float = 0.27
    /// Cut limestone for the cornices, plinth and urn.
    public var stone: MaterialKey = "stone.limestone"
    /// Sooted limestone for the recessed tympanum and the weathered returns.
    public var sooted: MaterialKey = "stone.limestone-sooted"

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, D = size.z, s = pitch, g = gap
        let eH: Float = 0.22
        // Horizontal entablature with its dentil course (one dentil lost to a chip).
        let yE = FP.entablature(&m, width: W, y0: 0, depth: D, height: eH, dentil: true, stone, shadow: sooted, skipDentil: 11)
        let dB: Float = 0.035
        func lowerEdge(_ x: Float) -> Float { yE + dB + s * (W / 2 - abs(x)) }
        // Raking cornices cut off vertically at the gap: stacked bands give the stepped moulding profile.
        let layers: [(zEnd: Float, v0: Float, v1: Float, mat: MaterialKey)] = [
            (0.20, -dB, 0, stone), (0.25, 0, 0.08, stone), (D - 0.01, 0, 0.032, stone), (0.29, 0.032, 0.05, stone),
            (0.23, 0.08, 0.105, stone), (0.19, 0.105, 0.12, sooted)]
        for e: Float in [-1, 1] {
            let xa = e * (W / 2), xb = e * g
            for l in layers {
                let poly = [V2(xa, lowerEdge(xa) + l.v0), V2(xb, lowerEdge(xb) + l.v0), V2(xb, lowerEdge(xb) + l.v1), V2(xa, lowerEdge(xa) + l.v1)]
                let ordered = e > 0 ? poly.reversed() : poly
                let d = l.zEnd - 0.03
                m.add(Prim.extrude(Array(ordered), depth: d, bevel: 0.002, bevelSegments: 1, material: l.mat),
                      Xform(translation: V3(0, 0, 0.03 + d / 2)))
            }
            // Raking dentils on the slope, inset from the eave and the cut.
            let pa = V2(e * (W / 2 - 0.04), lowerEdge(e * (W / 2 - 0.04)) - dB / 2)
            let pb = V2(e * (g + 0.03), lowerEdge(e * (g + 0.03)) - dB / 2)
            FP.dentils(&m, from: pa, to: pb, z: 0.215, size: V3(0.026, dB * 0.9, 0.07), pitch: 0.048, sooted, skip: e > 0 ? 4 : -1)
        }
        // Tympanum: sooted panel recessed behind the cornices, running straight across the gap.
        let ty = yE
        func tympTop(_ x: Float) -> Float { ty + s * (W / 2 - abs(x)) }
        let tx = W / 2 - 0.02
        let tym = [V2(-tx, ty), V2(tx, ty), V2(tx, tympTop(tx)), V2(g, tympTop(g)), V2(-g, tympTop(g)), V2(-tx, tympTop(tx))]
        m.add(Prim.extrude(tym, depth: 0.05, bevel: 0.002, bevelSegments: 1, material: sooted), Xform(translation: V3(0, 0, 0.05)))
        // Pedestal in the gap: base moulding, die, cornice cap, then the urn.
        let pw: Float = 0.30, pd: Float = 0.17
        FA.box(&m, V3(pw + 0.05, 0.04, pd + 0.03), V3(0, yE + 0.02, 0.03 + (pd + 0.03) / 2), stone, r: 0.003)
        FA.box(&m, V3(pw, 0.30, pd), V3(0, yE + 0.04 + 0.15, 0.03 + pd / 2), stone, r: 0.003)
        FA.box(&m, V3(pw - 0.07, 0.19, 0.004), V3(0, yE + 0.19, 0.03 + pd + 0.001), sooted, r: 0.002)   // sunk die panel
        let capY = yE + 0.34
        FA.run(&m, FP.cornice(d: pd + 0.05, h: 0.05), length: pw + 0.06, at: V3(0, capY, 0.0), stone, bevel: 0.0015)
        let top = capY + 0.05
        m.add(turned([(0.056, 0), (0.056, 0.012), (0.034, 0.02), (0.026, 0.034), (0.03, 0.046), (0.052, 0.07), (0.064, 0.092),
                      (0.056, 0.12), (0.04, 0.134), (0.034, 0.14), (0.048, 0.146), (0.048, 0.156), (0.02, 0.162), (0.0, 0.17)],
                     segments: 28, material: stone, seamTile: 0.2), Xform(translation: V3(0, top, 0.03 + pd / 2 + 0.01)))
        // Gadroons: raised ribs gathered on the urn belly, and a lid knop.
        let uc = V3(0, top, 0.03 + pd / 2 + 0.01)
        for k in 0..<12 {
            let a = Float(k) / 12 * 2 * .pi
            m.add(Prim.superellipsoid(V3(0.008, 0.05, 0.012), exponent: 2, subdivisions: 2, material: stone),
                  Xform(translation: uc + V3(cos(a) * 0.060, 0.082, sin(a) * 0.060), rotation: FA.q(-a * 180 / .pi, FA.Y)))
        }
        FC.bead(&m, r: 0.012, at: uc + V3(0, 0.176, 0), stone)
        // Water stain below each cut end where the gap sheds rain onto the tympanum.
        for e: Float in [-1, 1] {
            for (dx, w) in [(Float(0.015), Float(0.03)), (0.07, 0.018)] {
                FA.box(&m, V3(w, tympTop(g) - ty - 0.02, 0.003), V3(e * (g + dx), ty + (tympTop(g) - ty) / 2 + 0.01 - 0.02 * e * 0, 0.077), sooted, r: 0.001)
            }
        }
        // Urn handles: two small scrolls.
        for e: Float in [-1, 1] {
            FA.path(&m, [V3(e * 0.055, top + 0.115, 0.125), V3(e * 0.085, top + 0.1, 0.125), V3(e * 0.09, top + 0.075, 0.125), V3(e * 0.065, top + 0.07, 0.125)],
                    r: 0.006, stone, sides: 6)
        }
        // Weathering: soot bloom on the horizontal cornice top.
        FA.box(&m, V3(W - 0.1, 0.002, D * 0.4), V3(0, yE + 0.001, D * 0.55), sooted, r: 0.0008)
        _ = rng.float()
        groundAO(&m, height: 0.1, floor: 0.7)
        return LODModel(FC.place(m))
    }
}
