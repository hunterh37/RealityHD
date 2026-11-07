import simd
import Foundation

/// Black felt bowler (derby), 0.19 m across the brim: oval domed crown, rolled and curled brim edge,
/// grosgrain band with a tied bow and two short tails on the right side. Origin at the brim base centre, +Y up.
public struct BowlerHat: RealAsset {
    public static let id = "bowler-hat"
    public static let summary = "Black felt bowler hat, 0.19 m brim width: oval domed crown, curled rolled brim, grosgrain band with tied bow."
    public static let tags = ["prop", "fashion", "hat", "felt", "costume"]
    public static let budget = 8_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 24, distance: 0.4, studio: true)

    public var felt: MaterialKey = "fabric.wool:141414"
    public var ribbon: MaterialKey = "fabric.canvas:0B0B0B"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        _ = seed
        var levels: [Model] = []
        let cr: Float = 0.0705, ch: Float = 0.108, t: Float = 0.0028, y0: Float = 0.036
        let ovalZ: Float = 1.17
        for l in 0..<2 {
            var m = Model(name: Self.id)
            let segs = l == 0 ? 64 : 24
            let dome = l == 0 ? 14 : 6
            let rw = cr * 0.99, rwI = rw - t, chI = ch - t
            func cp(_ a: Float) -> Float { pow(max(cos(a), 0), 0.87) }
            func sp(_ a: Float) -> Float { pow(max(sin(a), 0), 0.87) }
            var p: [V2] = []
            // Inner dome from the top centre down, inner wall, brim underside with the rolled curl.
            for k in 0...dome {
                let a = Float.pi / 2 * (1 - Float(k) / Float(dome))
                p.append(V2(rwI * cp(a), y0 + (chI - y0) * sp(a)))
            }
            p += [V2(cr - t + 0.0003, 0.02), V2(cr - t, 0.0), V2(0.080, -0.0003), V2(0.088, 0.0018), V2(0.0925, 0.0058),
                  V2(0.0945, 0.0105), V2(0.0950, 0.0140), V2(0.0946, 0.0165), V2(0.0930, 0.0174), V2(0.0912, 0.0152)]
            // Brim top surface back to the crown, outer wall, outer dome.
            p += [V2(0.0895, 0.0105), V2(0.0850, 0.0064), V2(0.0780, 0.0037), V2(0.0725, 0.0034), V2(cr, 0.0048), V2(cr, 0.02), V2(rw, y0)]
            for k in 1...dome {
                let a = Float.pi / 2 * Float(k) / Float(dome)
                p.append(V2(rw * cp(a), y0 + (ch - y0) * sp(a)))
            }
            let oval = Xform(scale: V3(1, 1, ovalZ))
            m.add(Prim.lathe(p, segments: segs, seamTile: 0.12, material: felt), oval)
            // Grosgrain band, a thin ribbed ring hugging the crown wall.
            let b: [V2] = [V2(cr + 0.0004, 0.0075), V2(cr + 0.0012, 0.0086), V2(cr + 0.0013, 0.0245), V2(cr + 0.0004, 0.0256)]
            m.add(Prim.lathe(b, segments: segs, seamTile: 0.12, material: ribbon), oval)
            // Bow on the +X side: two pillow loops, knot, two tails resting on the brim.
            let bx = cr + 0.0045, by: Float = 0.016
            let loopSize = V3(0.0075, 0.013, 0.027), sub = l == 0 ? 8 : 4
            for s in [Float(-1), 1] {
                let q = simd_quatf(angle: s * 0.28, axis: V3(1, 0, 0))
                m.add(Prim.superellipsoid(loopSize, exponent: 3, subdivisions: sub, material: ribbon),
                      Xform(translation: V3(bx, by + s * 0.0012, s * 0.0155), rotation: q))
                m.add(Prim.roundedBox(V3(0.0022, 0.017, 0.0105), radius: 0.0008, bevelSegments: 2, material: ribbon),
                      Xform(translation: V3(bx - 0.0005, 0.0085, s * 0.0075), rotation: simd_quatf(angle: -s * 0.14, axis: V3(1, 0, 0))))
            }
            m.add(Prim.superellipsoid(V3(0.0105, 0.0155, 0.0135), exponent: 2.6, subdivisions: sub, material: ribbon),
                  Xform(translation: V3(bx + 0.0006, by, 0)))
            levels.append(m)
        }
        return LODModel(levels: levels, switchDistances: [2])
    }
}
