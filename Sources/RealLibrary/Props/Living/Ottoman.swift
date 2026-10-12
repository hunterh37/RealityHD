import simd
import Foundation

/// Tufted square storage ottoman, 60 x 42 x 60 cm: a padded lid with a diamond button-tufted top and piped
/// edge over a box body (visible lid seam), two leather side handles and four turned walnut feet.
public struct Ottoman: RealAsset {
    public static let id = "ottoman"
    public static let summary = "Tufted square storage ottoman, 60 cm: button-tufted lid, piped edge, leather side handles, walnut feet."
    public static let tags = ["prop", "floorplan", "living", "furniture", "fabric", "interior"]
    public static let budget = 5500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 22, distance: 1.1, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.6, 0.42, 0.6)
    /// Upholstery.
    public var fabric: MaterialKey = "fabric.linen:3F5278"
    /// Handle strap leather.
    public var strap: MaterialKey = "leather.tan"
    /// Foot wood.
    public var wood: MaterialKey = "wood.walnut"
    /// Rivet metal.
    public var metal: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [4])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, D = size.z
        let footH: Float = 0.07, lidBot: Float = 0.307, lidTop: Float = 0.397
        // Body box under the lid and the padded lid slab.
        m.add(Prim.roundedBox(V3(W - 0.018, lidBot - footH + 0.01, D - 0.018), radius: 0.022, bevelSegments: 3, material: fabric),
              Xform(translation: V3(0, (footH + lidBot) / 2 + 0.005, 0)))
        m.add(Prim.roundedBox(V3(W, lidTop - lidBot, D), radius: 0.03, bevelSegments: 4, material: fabric),
              Xform(translation: V3(0, (lidBot + lidTop) / 2, 0)))
        // Tufted top: diamond lattice, puffs upward.
        let tw = W - 0.075
        var (panel, pts) = tuftedPanel(width: tw, height: tw, spacing: V2(0.105, 0.105), puff: 0.026, edgeTuck: 0.03,
                                       cell: detail ? 0.024 : 0.04, material: fabric)
        // Seated-on dent, off centre.
        panel.deform { p in V3(p.x, p.y, p.z - 0.007 * exp(-((p.x - 0.05) * (p.x - 0.05) + (p.y + 0.04) * (p.y + 0.04)) / 0.012)) }
        let tx = Xform(translation: V3(0, lidTop - 0.003, 0), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0)))
        m.add(panel, tx)
        if detail {
            buttons(&m, pts, tx, radius: 0.0085, material: fabric)
            // Piping around the top edge of the lid and the seam between lid and body.
            for (yy, rr) in [(lidTop - 0.004, Float(0.0045)), (lidBot + 0.003, 0.003)] {
                let ring = Shape2D.roundedRect(W - 0.004, D - 0.004, radius: 0.03, segments: 3).map { V3($0.x, yy, -$0.y) }
                m.add(Prim.sweep(Shape2D.circle(rr, segments: 5), along: ring, closedPath: true, caps: false, material: fabric))
            }
            // Stitch lines on the lid side.
            let st = Shape2D.roundedRect(W + 0.001, D + 0.001, radius: 0.03, segments: 3).map { V3($0.x, lidBot + 0.025, -$0.y) }
            m.add(stitches(along: st + [st[0]], normal: { p in V3(p.x, 0, p.z) }, pitch: 0.02, thread: 0.0008, material: fabric))
        }
        // Leather side handles on X faces: flat strap loop with rivets.
        for s: Float in [-1, 1] {
            let x0 = s * (W / 2 - 0.012)
            // Strap arc in the YZ plane, bulging away from the body.
            let arc = (0...14).map { k -> V3 in
                let a = Float.pi * Float(k) / 14
                return V3(x0 + s * (0.003 + 0.008 * sin(a)), 0.2, -0.07 + 0.14 * Float(k) / 14)
            }
            m.add(Prim.sweep(Shape2D.roundedRect(0.026, 0.003, radius: 0.001, segments: 1), along: arc, up: V3(0, 1, 0), caps: true, material: strap))
            if detail {
                for z: Float in [-0.07, 0.07] {
                    rivet(&m, at: V3(x0 + s * 0.003, 0.2, z), normal: V3(s, 0, 0), radius: 0.006, material: metal)
                }
            }
        }
        // Turned feet.
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            let p = V3(sx * (W / 2 - 0.06), 0, sz * (D / 2 - 0.06))
            m.add(turned([(0, 0), (0.02, 0), (0.023, 0.012), (0.028, 0.04), (0.034, footH + 0.01), (0, footH + 0.01)],
                         segments: 12, material: wood, grainVertical: true), Xform(translation: p + V3(rng.float(-0.001...0.001), 0, 0)))
        }}
        groundAO(&m, height: 0.12, floor: 0.5)
        return m
    }
}
