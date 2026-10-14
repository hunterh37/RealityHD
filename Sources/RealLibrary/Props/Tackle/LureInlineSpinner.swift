import simd
import Foundation

/// Size 3 inline spinner, 75 mm, lying on the ground: stainless wire shaft with a twisted line-tie loop,
/// nickel French blade on a folded clevis, red plastic beads, brass bell body, treble with a red bucktail
/// dressing. Anchor: `lineTie` (front loop).
public struct LureInlineSpinner: RealAsset, RealAnchored {
    public static let id = "lure-inline-spinner"
    public static let summary = "Inline spinner 75 mm: wire shaft, nickel French blade on a clevis, beads, brass body, dressed treble."
    public static let tags = ["prop", "fishing", "handheld", "metal"]
    public static let budget = 5300
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 45, distance: 1.0, studio: true)

    /// Blade material key.
    public var bladeMaterial: MaterialKey = "metal.spinner-nickel"
    /// Bead colour (sRGB hex).
    public var beadColor: UInt32 = 0xC0221C
    /// Dressing colour.
    public var dressingColor: UInt32 = 0xB0201A
    public init() {}

    var tieSwim: V3 { V3(0.034, 0, 0) }
    public static var anchors: [String: RealAnchor] {
        let a = Self(), (_, x) = a.model(seed: 1)
        return ["lineTie": RealAnchor(x.point(a.tieSwim), direction: x.rotation.act(V3(1, 0, 0)))]
    }

    func model(seed: UInt64) -> (Model, Xform) {
        var rng = SeededRNG(seed: seed)
        let wire: MaterialKey = "metal.stainless", brass: MaterialKey = "metal.brass"
        let bead: MaterialKey = "paint.lure:" + String(format: "%06X", beadColor)
        var body: [Surface] = []
        let w: Float = 0.00045
        // Shaft with the front loop and a few twist wraps behind it.
        body.append(Prim.tube([V3(-0.02, 0, 0), V3(0.028, 0, 0)], radii: [w, w], sides: 6, seamTile: 0.01, material: wire))
        body.append(Prim.torus(major: 0.0022, minor: w, segments: 14, sides: 5, material: wire).transformed(Xform(translation: V3(0.0315, 0, 0), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0)))))
        body.append(Prim.helix(radius: 0.0007, pitch: 0.001, turns: 3, wire: 0.0003, perTurn: 10, sides: 4, material: wire).transformed(Xform(translation: V3(0.0255, 0, 0), rotation: RodKit.alongX)))
        // Clevis: folded strip around the shaft.
        body.append(Prim.roundedBox(V3(0.004, 0.0024, 0.0016), radius: 0.0006, bevelSegments: 1, material: wire).transformed(Xform(translation: V3(0.0215, 0.0006, 0))))
        // French blade: an oval cupped plate hanging off the clevis, rotated out from the shaft.
        var blade = Prim.superellipsoid(V3(0.026, 0.0008, 0.015), exponent: 2.1, subdivisions: 10, material: bladeMaterial)
        blade.deform { p in V3(p.x, p.y - 0.0012 * (1 - pow(p.x / 0.013, 2)) * (1 - pow(p.z / 0.0075, 2)), p.z) }
        body.append(blade.transformed(Xform(translation: V3(0.0095, -0.0016, 0.0068), rotation: simd_quatf(angle: 0.32, axis: V3(0, 1, 0)) * simd_quatf(angle: -0.12, axis: V3(1, 0, 0)))))
        // Beads and the brass bell body.
        for (x, r) in [(Float(0.0175), Float(0.0018)), (0.0142, 0.0022), (0.0105, 0.0018)] {
            body.append(Prim.superellipsoid(V3(r * 2, r * 2, r * 2), exponent: 2, subdivisions: 5, material: bead).transformed(Xform(translation: V3(x, 0, 0))))
        }
        body.append(RodKit.lathe([V2(0.0009, 0), V2(0.0042, 0.003), V2(0.0045, 0.009), V2(0.0036, 0.0145), V2(0.0014, 0.0168), V2(0.0006, 0.017)], x0: -0.0085, y: 0, seg: 32, tile: 0.02, brass).transformed(Xform(scale: V3(1, 1, 1))))
        // Rear wrap and eye for the treble.
        body.append(Prim.helix(radius: 0.0007, pitch: 0.001, turns: 3, wire: 0.0003, perTurn: 10, sides: 4, material: wire).transformed(Xform(translation: V3(-0.0168, 0, 0), rotation: RodKit.alongX)))
        body.append(Prim.torus(major: 0.0016, minor: w, segments: 12, sides: 5, material: wire).transformed(Xform(translation: V3(-0.0215, 0, 0), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0)))))
        // Treble trailing back (shank along -X) with bucktail.
        let eye = V3(-0.023, 0, 0)
        var hook = LureKit.treble(shank: 0.011, gap: 0.0068, wire: 0.0005, mat: "metal.hook").map { $0.transformed(Xform(translation: eye, rotation: simd_quatf(angle: -.pi / 2, axis: V3(0, 0, 1)))) }
        for k in 0..<22 {
            let a = Float(k) / 22 * 2 * .pi
            let len = rng.float(0.016...0.022)
            let dir = simd_normalize(V3(-1, 0.18 * sin(a), 0.18 * cos(a)))
            let p0 = eye + V3(-0.003, 0, 0)
            hook.append(Prim.tube([p0, p0 + dir * len * 0.5, p0 + dir * len], radii: [0.0005, 0.0005, 0.00012], sides: 3, seamTile: 0.01,
                                  material: "rubber.skirt:" + String(format: "%06X", dressingColor)))
        }
        hook.append(Prim.cylinder(radius: 0.0012, height: 0.0035, bevel: 0.0004, segments: 10, bevelSegments: 1, material: "thread.wrap-epoxy").transformed(Xform(translation: eye + V3(-0.0045, 0, 0), rotation: RodKit.alongX)))
        // Spinner lies flat as authored: shaft along the ground, blade beside it.
        let (m, x) = LureKit.layOnSide(body: body + hook, hooks: [], roll: false, name: Self.id)
        return (m, x)
    }

    public func build(seed: UInt64) -> LODModel {
        var (m, _) = model(seed: seed)
        groundAO(&m, height: 0.008, floor: 0.55)
        return LODModel(m)
    }
}
