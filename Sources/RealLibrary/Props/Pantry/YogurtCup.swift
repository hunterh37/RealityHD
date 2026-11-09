import simd
import Foundation

/// Yogurt cup, 150 g: tapered polypropylene cup 7.4 cm across the rim and 7.8 cm tall with a stacking
/// shoulder near the foot, a rolled rim flange, an in-mould printed wrap (invented brand SKYLA) with a lap
/// seam at the back, and a printed foil lid peeled back from the front: the pull tab curls up and over,
/// showing the yogurt surface inside. A streak of yogurt runs down the outside under the peel.
public struct YogurtCup: RealAsset {
    public static let id = "yogurt-cup"
    public static let summary = "Yogurt cup, 8 cm: tapered PP cup, rolled rim, printed IML wrap with lap seam, foil lid peeled back over the yogurt."
    public static let tags = ["prop", "interior", "pantry", "plastic", "metal", "container", "food"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 28, distance: 1.0, studio: true)

    /// Cup plastic.
    public var plastic: MaterialKey = "plastic.matte:F4F3EE"
    /// Yogurt.
    public var yogurt: MaterialKey = "plastic.matte:F7F3E8"
    /// Foil lid.
    public var foil: MaterialKey = "pkg.foil-wrapper"
    /// Printed wrap (brand field tint).
    public var label: MaterialKey = "pkg.paper-label:D6336C"
    public var ink: MaterialKey = "paper.sheet:FFFFFF"
    public var brand = "SKYLA"
    public var line = "STRAWBERRY"
    public init() {}

    /// Outer wall radius at height y (taper from the stacking shoulder to the rim).
    func wall(_ y: Float) -> Float { 0.0272 + (0.0336 - 0.0272) * (y - 0.0075) / (0.07 - 0.0075) }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(hi: true), make(hi: false)], switchDistances: [3])
    }

    func make(hi: Bool) -> Model {
        typealias K = GroceryKit
        var m = Model(name: Self.id)
        let segs = hi ? 72 : 24, top: Float = 0.0762, rimR: Float = 0.037
        // Cup: recessed base, foot ring, stacking shoulder, tapered wall, rolled rim, inner wall down to the yogurt.
        var prof: [V2] = [V2(0, 0.0016), V2(0.022, 0.0014), V2(0.0245, 0), V2(0.0262, 0.0008), V2(0.0263, 0.0058), V2(0.0272, 0.0075)]
        for k in 1...8 { let y = 0.0075 + (0.07 - 0.0075) * Float(k) / 8; prof.append(V2(wall(y), y)) }
        prof += [V2(0.0348, 0.0712), V2(0.0362, 0.0722), V2(rimR, 0.0738), V2(0.0366, 0.0752), V2(0.0356, top - 0.0003), V2(0.0336, top - 0.0004),
                 V2(0.0326, 0.0745), V2(0.0322, 0.071)]
        m.add(Prim.lathe(prof, segments: segs, seamTile: 0.05, material: plastic))
        // Yogurt surface with a soft swirl.
        var yog = Prim.lathe([V2(0.0323, 0.0712), V2(0.031, 0.0716), V2(0.02, 0.0719), V2(0.008, 0.0722), V2(0, 0.0723)], segments: hi ? 48 : 16, seamTile: 0.05, material: yogurt)
        if hi { yog.displace { p, nn in nn.y > 0.5 ? 0.0006 * sin(atan2(p.z, p.x) * 2 + simd_length(V2(p.x, p.z)) * 320) : 0 } }
        m.add(yog)
        // Printed wrap: one design around, lap seam at the back.
        let ly0: Float = 0.0095, ly1: Float = 0.0675, over: Float = 0.14
        let span = 0.25 * (1 + over / (2 * .pi))
        m.add(K.revSheet(cols: hi ? 72 : 24, rows: 3, y0: ly0, y1: ly1, a0: -.pi, a1: .pi + over, uSpan: span, vSpan: -0.09, u0: 0.03, v0: 0.09, label) { y, a in
            wall(y) + 0.0004 + (a > .pi ? 0.00026 : 0) })
        // Foil lid: disc on the rim with a pull tab at the front; the front part peels back in a curl.
        let zp: Float = 0.006, kappa: Float = 1 / 0.011
        func foilPos(_ s: Float, _ t: Float, lift: Float) -> V3 {
            let a = -s * 2 * .pi
            let tab = 0.0085 * exp(-a.remainder(dividingBy: 2 * .pi) * a.remainder(dividingBy: 2 * .pi) / 0.04)
            let rho = t * (rimR + tab)
            let x = rho * sin(a), z = rho * cos(a)
            let y = top + lift + (rho < 0.0345 ? 0 : 0.0002) - 0.0003 * smoothstep(0.034, rimR, rho)
            if z <= zp { return V3(x, y, z) }
            let d = z - zp, th = kappa * d
            return V3(x, y + (1 - cos(th)) / kappa + lift * (cos(th) - 1), zp + sin(th) / kappa - lift * sin(th))
        }
        let fc = hi ? 64 : 24, fr = hi ? 12 : 4
        m.add(K.sheet(cols: fc, rows: fr, uSpan: 0.23, vSpan: 0.04, foil) { s, t in foilPos(s, t, lift: 0.0002) })
        m.add(K.sheet(cols: fc, rows: fr, uSpan: 0.23, vSpan: 0.04, foil) { s, t in foilPos(1 - s, t, lift: -0.0001) })
        if hi {
            // Crimp ripples pressed into the foil over the rim.
            for k in 0..<36 {
                let a = Float(k) / 36 * 2 * .pi
                guard cos(a) * 0.0355 < zp - 0.002 else { continue }
                m.add(Prim.roundedBox(V3(0.0006, 0.00025, 0.0022), radius: 0.0001, bevelSegments: 1, material: foil),
                      Xform(translation: V3(0.0355 * sin(a), top + 0.0002, 0.0355 * cos(a)), rotation: simd_quatf(angle: a, axis: .up)))
            }
            // Print on the foil: brand and a keyline ring on the flat part.
            K.printSmooth(&m, brand, height: 0.0085, at: V3(0, top + 0.0005, -0.004), "paper.sheet:B8264F",
                          rot: simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0)), maxWidth: 0.045, weight: 1.3)
            K.printSmooth(&m, "150 G", height: 0.0042, at: V3(0, top + 0.0005, -0.022), "paper.sheet:3A3A40",
                          rot: simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0)), weight: 1.0)
            // Wordmark on the wrap's logo pill and the flavour line under it.
            let aPill = (0.7 * 0.25 - 0.03) / span * (2 * .pi + over) - .pi
            K.wrapText(&m, brand, height: 0.0062, y: ly0 + 0.81 * (ly1 - ly0), at: aPill, ink, maxWidth: 0.06, weight: 1.3, lift: 0.0012) { wall($0) }
            K.wrapText(&m, line, height: 0.0045, y: ly0 + 0.69 * (ly1 - ly0), at: aPill, ink, maxWidth: 0.055, weight: 1.1, lift: 0.0012) { wall($0) }
            // Yogurt streak down the outside, under the peeled tab.
            let sp = (0...6).map { k -> V3 in
                let y = 0.0705 - Float(k) * 0.0035, a: Float = 0.25 + 0.015 * sin(Float(k) * 1.3)
                return V3((wall(min(y, 0.07)) + 0.0006) * sin(a), y, (wall(min(y, 0.07)) + 0.0006) * cos(a))
            }
            m.add(Prim.tube(sp, radii: [0.0024, 0.0016, 0.0013, 0.0012, 0.0013, 0.0018, 0.0021], sides: 8, seamTile: 0.01, material: yogurt),
                  Xform(scale: V3(1, 1, 1)))
        }
        groundAO(&m, height: 0.015, floor: 0.75)
        return m
    }
}
