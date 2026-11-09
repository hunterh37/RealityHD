import simd
import Foundation

/// 20 oz squeeze ketchup bottle, 21 cm: oval PET body (depth 0.64 of width) with a waist grip, a push-up base
/// and parting lines, red ketchup showing through, a shoulder and neck, a white flip-top cap with split line,
/// rear hinge and front thumb lip, and printed gloss labels front and back (invented brand RUBY). A ring of
/// dried ketchup sits at the cap seam.
public struct KetchupBottle: RealAsset {
    public static let id = "ketchup-bottle"
    public static let summary = "Squeeze ketchup bottle, 21 cm: oval red PET body with waist grip, flip-top cap with hinge, printed gloss labels, invented brand."
    public static let tags = ["prop", "grocery", "food", "plastic", "container", "kitchen", "handheld"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 14, distance: 1.3, studio: true)

    /// Body depth as a fraction of width (oval).
    public var oval: Float = 0.64
    public var body: MaterialKey = "plastic.gloss:9E130E"
    public var cap: MaterialKey = "plastic.matte:F3F1EA"
    /// Printed label (brand field tint).
    public var label: MaterialKey = "pkg.carton-gloss:1E6B3A"
    public var ink: MaterialKey = "paper.sheet:FFFFFF"
    public var brand = "RUBY"
    public var line = "TOMATO KETCHUP"
    public init() {}

    /// Body half width at height y.
    func radius(_ y: Float) -> Float {
        let knots: [(Float, Float)] = [(0, 0.0335), (0.004, 0.0372), (0.012, 0.0385), (0.05, 0.039), (0.085, 0.0372), (0.1, 0.0366),
                                       (0.118, 0.0378), (0.134, 0.0372), (0.146, 0.033), (0.156, 0.025), (0.163, 0.0175), (0.167, 0.0158)]
        if y <= knots[0].0 { return knots[0].1 }
        for i in 1..<knots.count where y <= knots[i].0 {
            let (y0, r0) = knots[i - 1], (y1, r1) = knots[i]
            let t = (y - y0) / (y1 - y0)
            return r0 + (r1 - r0) * (3 * t * t - 2 * t * t * t)
        }
        return knots.last!.1
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(hi: true), make(hi: false)], switchDistances: [3])
    }

    func make(hi: Bool) -> Model {
        typealias K = GroceryKit
        var m = Model(name: Self.id)
        let segs = hi ? 64 : 20
        // Body: push-up base then the oval wall to the neck.
        var prof: [V2] = [V2(0, 0.004), V2(0.02, 0.0028), V2(0.03, 0.0004), V2(0.0335, 0)]
        let n = hi ? 40 : 12
        for k in 1...n { let y = 0.168 * Float(k) / Float(n); prof.append(V2(radius(y), y)) }
        prof += [V2(0.0158, 0.172), V2(0.0152, 0.173)]
        var bodyS = Prim.lathe(prof, segments: segs, seamTile: 0.05, material: body)
        // Waist grip panels on the narrow sides.
        if hi { bodyS.displace { p, nn in
            let side = smoothstep(0.75, 0.95, abs(nn.x))
            return -0.0012 * side * exp(-pow((p.y - 0.1) / 0.016, 2))
        } }
        m.add(bodyS, Xform(scale: V3(1, 1, oval)))
        // Parting lines on the narrow sides.
        if hi { for s: Float in [-1, 1] {
            let path = stride(from: Float(0.004), through: 0.164, by: 0.008).map { V3(s * (radius($0) + 0.0001), $0, 0) }
            m.add(Prim.tube(path, radii: path.map { _ in 0.00035 }, sides: 4, seamTile: 0.01, material: body))
        } }
        // Labels front and back: one carton-gloss texture tile (design rows 0.32...1) on 0.08 x 0.094 m.
        let ly0: Float = 0.034, ly1: Float = 0.128, ha: Float = 1.05
        for back in [false, true] where hi || !back {
            let c: Float = back ? .pi : 0
            m.add(K.revSheet(cols: hi ? 24 : 8, rows: hi ? 16 : 4, y0: ly0, y1: ly1, a0: c - ha, a1: c + ha, uSpan: 0.19, vSpan: -0.19, v0: 0.19, label,
                             oval: oval) { y, _ in radius(y) + 0.0004 })
        }
        // Flip-top cap: base, split line, domed lid, rear hinge, front thumb lip.
        let cy: Float = 0.168
        m.add(Prim.lathe([V2(0.0196, cy), V2(0.0206, cy + 0.002), V2(0.021, cy + 0.02), V2(0.0204, cy + 0.0212), V2(0.0198, cy + 0.0218)],
                         segments: segs, seamTile: 0.05, material: cap))
        m.add(Prim.lathe([V2(0.0198, cy + 0.0222), V2(0.0208, cy + 0.0226), V2(0.0208, cy + 0.031), V2(0.0196, cy + 0.0345), V2(0.012, cy + 0.0372),
                          V2(0, cy + 0.0378)], segments: segs, seamTile: 0.05, material: cap))
        m.add(Prim.roundedBox(V3(0.012, 0.0055, 0.004), radius: 0.0012, bevelSegments: 1, material: cap), Xform(translation: V3(0, cy + 0.022, -0.0205)))
        m.add(Prim.superellipsoid(V3(0.012, 0.0028, 0.006), exponent: 3, subdivisions: hi ? 4 : 2, material: cap), Xform(translation: V3(0, cy + 0.0232, 0.0212)))
        if hi {
            // Dried ketchup at the cap seam.
            m.add(Prim.lathe([V2(0.0158, cy - 0.0005), V2(0.0185, cy + 0.0002), V2(0.0168, cy + 0.0016)], segments: 32, seamTile: 0.05, material: "plastic.matte:5E0E0A"),
                  Xform(rotation: simd_quatf(angle: 0.4, axis: .up)))
            let aPill = -ha + 0.7 * 2 * ha
            K.wrapText(&m, brand, height: 0.0095, y: ly0 + 0.735 * (ly1 - ly0), at: aPill, "paper.sheet:FFFFFF", maxWidth: 0.031, weight: 1.3, lift: 0.0009, oval: oval) { radius($0) }
            K.wrapText(&m, line, height: 0.0055, y: ly0 + 0.57 * (ly1 - ly0), at: -0.05, ink, maxWidth: 0.06, weight: 1.1, lift: 0.0009, oval: oval) { radius($0) }
            K.wrapText(&m, "20 OZ", height: 0.004, y: ly0 + 0.012, at: -0.55, ink, weight: 0.9, lift: 0.0009, oval: oval) { radius($0) }
        }
        groundAO(&m, height: 0.02, floor: 0.7)
        return m
    }
}
