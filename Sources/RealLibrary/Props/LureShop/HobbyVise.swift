import simd
import Foundation

/// Pedestal hobby vise in the fly-tying style, sized for holding lure blanks: a heavy turned pedestal
/// base on a rubber ring, a 11 mm steel stem with a set collar and thumbscrew, a black anodized head with a
/// tilt knob, a collet sleeve and two tapered hardened jaws angled up 30 degrees, closed by a cam lever
/// with a ball end. `anchor:jaws` sits at the jaw tip with +X along the jaw axis for attaching a lure.
/// Story detail: paint flecks on the jaw tips and a few wood shavings on the base.
public struct HobbyVise: RealAsset {
    public static let id = "hobby-vise"
    public static let summary = "Pedestal hobby vise for lure carving: cast pedestal base, upright stem, cam-lever jaws angled up, anchor at the jaw tip."
    public static let tags = ["prop", "workshop", "tool", "metal"]
    public static let budget = 5800
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 15, distance: 1.2, studio: true)

    /// Base radius (m).
    public var baseRadius: Float = 0.055
    /// Height of the head pivot above the bench (m).
    public var headHeight: Float = 0.155
    /// Jaw tilt above horizontal (degrees).
    public var jawAngle: Float = 30
    /// Jaw length beyond the collet (m).
    public var jawLength: Float = 0.042
    /// Base finish.
    public var baseMaterial: MaterialKey = "metal.cast-iron-seasoned"
    /// Stem steel.
    public var stemMaterial: MaterialKey = "metal.steel"
    /// Jaw steel.
    public var jawMaterial: MaterialKey = "metal.tool-ground"
    /// Head and collet finish.
    public var headMaterial: MaterialKey = "metal.anodized-black"
    public init() {}

    /// Jaw frame in asset space: origin at the head pivot, +X along the jaws.
    var jawFrame: Xform {
        Xform(translation: V3(0, headHeight, 0), rotation: simd_quatf(angle: jawAngle * .pi / 180, axis: V3(0, 0, 1)))
    }
    /// Distance from the pivot to the jaw tip along the jaw axis (m).
    var tipDistance: Float { 0.034 + jawLength }

    /// Jaw tip in asset space, +X along the jaws.
    public var jawTip: Xform {
        Xform(translation: jawFrame.point(V3(tipDistance, 0, 0)), rotation: jawFrame.rotation)
    }

    /// Y-up cylinder laid along +X starting at x0.
    func alongX(_ s: Surface, x0: Float) -> Xform {
        Xform(translation: V3(x0, 0, 0), rotation: simd_quatf(angle: -.pi / 2, axis: V3(0, 0, 1)))
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let R = baseRadius
        // Rubber foot ring and turned pedestal.
        m.add(Prim.lathe([V2(R * 0.55, 0), V2(R - 0.001, 0), V2(R - 0.0005, 0.0012), V2(R - 0.0012, 0.0026), V2(R * 0.55, 0.0026)], segments: 40, seamTile: 0.1, material: "rubber.plate"))
        m.add(Prim.lathe([V2(0, 0.0024), V2(R - 0.0008, 0.0024), V2(R, 0.004), V2(R, 0.012), V2(R - 0.0015, 0.0145), V2(R * 0.82, 0.017),
                          V2(R * 0.45, 0.022), V2(0.016, 0.027), V2(0.0125, 0.031), V2(0.0115, 0.036), V2(0, 0.036)], segments: 40, seamTile: 0.15, material: baseMaterial))
        // Stem.
        m.add(Prim.cylinder(radius: 0.0055, height: headHeight - 0.03, bevel: 0.0008, segments: 20, bevelSegments: 1, material: stemMaterial), Xform(translation: V3(0, 0.035, 0)))
        // Set collar with thumbscrew.
        m.add(Prim.cylinder(radius: 0.0095, height: 0.012, bevel: 0.0012, segments: 24, bevelSegments: 2, material: headMaterial), Xform(translation: V3(0, 0.095, 0)))
        m.add(Prim.cylinder(radius: 0.0016, height: 0.008, bevel: 0.0003, segments: 10, bevelSegments: 1, material: stemMaterial),
              Xform(translation: V3(0, 0.101, 0.009), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
        m.add(Prim.cylinder(radius: 0.0055, height: 0.004, bevel: 0.0008, segments: 16, bevelSegments: 1, material: "metal.knurl-chrome"),
              Xform(translation: V3(0, 0.101, 0.017), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
        // Head block on the stem top, tilt knob on the -Z side.
        m.add(Prim.roundedBox(V3(0.02, 0.022, 0.02), radius: 0.003, bevelSegments: 2, material: headMaterial), Xform(translation: V3(0, headHeight - 0.004, 0)))
        m.add(Prim.cylinder(radius: 0.0035, height: 0.008, bevel: 0.0005, segments: 12, bevelSegments: 1, material: stemMaterial),
              Xform(translation: V3(0, headHeight, -0.009), rotation: simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))))
        m.add(Prim.cylinder(radius: 0.008, height: 0.007, bevel: 0.0012, segments: 20, bevelSegments: 2, material: "metal.knurl-chrome"),
              Xform(translation: V3(0, headHeight, -0.016), rotation: simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))))

        // Jaw assembly in the jaw frame.
        var j = Model(name: "jaws")
        // Collet sleeve and nose.
        j.add(Prim.lathe([V2(0, 0), V2(0.0072, 0), V2(0.0078, 0.001), V2(0.0078, 0.024), V2(0.0068, 0.028), V2(0.0058, 0.034), V2(0, 0.034)], segments: 24, seamTile: 0.08, material: headMaterial),
              alongX(Surface(material: headMaterial), x0: 0))
        // Two tapered jaw halves split in Y, closing on a 0.5 mm gap.
        let L = jawLength + 0.004
        for s in [Float(1), -1] {
            let outline = Shape2D.rounded([V2(0, 0.00025), V2(L, 0.00025), V2(L, 0.0016), V2(L * 0.35, 0.0042), V2(0, 0.0048)], radius: 0.0007, segments: 2)
            let pts = s > 0 ? outline : outline.map { V2($0.x, -$0.y) }.reversed()
            j.add(Prim.extrude(Array(pts), depth: 0.0075, bevel: 0.0006, bevelSegments: 1, material: jawMaterial), Xform(translation: V3(0.030, 0, 0)))
            // Paint flecks on the tip faces.
            for _ in 0..<3 {
                let c = rng.pick(["C0262D", "F2C230", "2E8B57", "E8E4D8"])
                j.add(Prim.superellipsoid(V3(0.0012, 0.0012, 0.0004), exponent: 2, subdivisions: 2, material: "plastic.gloss:" + c),
                      Xform(translation: V3(0.030 + L * rng.float(0.7...0.95), s * rng.float(0.0012...0.0028), 0.0038)))
            }
        }
        // Cam lever: pivot lug on the collet top, arm swept back and down, ball end.
        j.add(Prim.roundedBox(V3(0.008, 0.005, 0.006), radius: 0.0015, bevelSegments: 1, material: stemMaterial), Xform(translation: V3(0.012, 0.0085, 0)))
        let arm = [V3(0.012, 0.010, 0), V3(0.002, 0.014, 0), V3(-0.016, 0.012, 0), V3(-0.034, 0.006, 0)]
        j.add(Prim.tube(catmull(arm, per: 4), radii: Array(repeating: 0.0019, count: catmull(arm, per: 4).count), sides: 10, seamTile: 0.03, material: stemMaterial))
        j.add(Prim.superellipsoid(V3(0.009, 0.009, 0.009), exponent: 2, subdivisions: 6, material: "plastic.black"), Xform(translation: V3(-0.036, 0.0055, 0)))
        // Rear clamp nut behind the head.
        j.add(Prim.cylinder(radius: 0.006, height: 0.008, bevel: 0.001, segments: 6, bevelSegments: 1, material: stemMaterial), alongX(Surface(material: stemMaterial), x0: -0.016))
        m.add(j, jawFrame)

        // Wood shavings on the base.
        for _ in 0..<4 {
            let a = rng.float(0...(2 * Float.pi)), r = rng.float(0.022...0.045)
            let c = V3(cos(a) * r, 0.0165 + (0.045 - r) * 0.12, sin(a) * r)
            let curl = Prim.helix(radius: rng.float(0.002...0.0035), pitch: 0.0012, turns: rng.float(1...1.8), wire: 0.0005, perTurn: 10, sides: 4, material: "wood.lumber-pine")
            m.add(curl, Xform(translation: c, rotation: simd_quatf(angle: .pi / 2, axis: V3(cos(a), 0, sin(a)))))
        }
        groundAO(&m)
        var lod = LODModel(m)
        lod.anchors["jaws"] = jawTip
        return lod
    }
}
