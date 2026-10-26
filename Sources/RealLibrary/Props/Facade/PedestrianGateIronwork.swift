import simd
import Foundation

/// Pedestrian gate ironwork: architectural facade customizer, Contemporary. Parts: steel frame, flat bar pickets, horizontal rails, gate leaf, hinge, magnetic latch, post, striker plate.
public struct PedestrianGateIronwork: RealAsset {
    public static let id = "pedestrian-gate-ironwork"
    public static let summary = "Contemporary powder-coated steel pedestrian gate with slim flat pickets and concealed hardware."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.0, 1.8, 0.05)
    public init() {}

    /// Anthracite powder coat (hex tint after the colon).
    public var coat: MaterialKey = "metal.powdercoat:3F4449"
    /// Chipped powder coat for edges and the foot.
    public var worn: MaterialKey = "metal.powdercoat-worn"
    /// Stainless hardware.
    public var steel: MaterialKey = "metal.stainless"
    /// Galvanised steel visible where the coat has chipped.
    public var zinc: MaterialKey = "metal.galvanized"
    /// Picket pitch in meters.
    public var pitch: Float = 0.1

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y
        let pw: Float = 0.05, px = W / 2 - pw / 2 - 0.005, inner = 2 * px - pw   // post size and inner opening
        // Posts: 50 mm square tube with a welded cap plate and a base cover plate.
        for sx in [-1, 1] as [Float] {
            FA.box(&m, V3(pw, H - 0.02, pw), V3(sx * px, (H + 0.02) / 2 - 0.0, 0), coat, r: 0.004)
            FA.box(&m, V3(pw + 0.006, 0.012, pw), V3(sx * px, H - 0.006, 0), coat, r: 0.003)
            FA.box(&m, V3(pw + 0.014, 0.01, pw + 0.0), V3(sx * px, 0.03, 0), worn, r: 0.003)
            FA.box(&m, V3(pw + 0.02, 0.01, pw), V3(sx * px, 0.005, 0), steel, r: 0.002)
        }
        // Leaf frame: 40 x 25 tube top and bottom, 25 mm stiles, one mid flat bar.
        let lw = inner - 0.012, ly0: Float = 0.1, ly1 = H - 0.12
        let cx: Float = 0
        FA.box(&m, V3(lw, 0.04, 0.03), V3(cx, ly1, 0), coat, r: 0.004)
        FA.box(&m, V3(lw, 0.04, 0.03), V3(cx, ly0 + 0.02, 0), coat, r: 0.004)
        for sx in [-1, 1] as [Float] {
            FA.box(&m, V3(0.03, ly1 - ly0 + 0.04, 0.03), V3(sx * (lw / 2 - 0.015), (ly0 + ly1 + 0.04) / 2 - 0.0, 0), coat, r: 0.004)
        }
        FA.box(&m, V3(lw - 0.06, 0.025, 0.012), V3(cx, 0.98, 0.0), coat, r: 0.002)
        // Slim 20 x 12 flat pickets, 100 mm pitch, passing through the rails, with a facetted top.
        let n = Int((lw - 0.06) / pitch)
        let x0 = -Float(n - 1) * pitch / 2
        for k in 0..<n {
            var r = rng.fork(k)
            let x = x0 + Float(k) * pitch
            let top = ly1 + 0.11 + r.float(-0.002...0.002)
            FA.box(&m, V3(0.02, top - ly0 - 0.02, 0.012), V3(x, (top + ly0 + 0.02) / 2, 0), coat, r: 0.002)
            // Chamfered top: a short pyramid cap welded on the flat.
            FGate.frustum(&m, w0: 0.02, w1: 0.008, y0: top, y1: top + 0.018, d0: 0.012, d1: 0.006, at: V3(x, 0, 0), coat)
            // Weld beads at both rail crossings.
            for y in [ly0 + 0.04, ly1 - 0.02, 0.98 + 0.0] as [Float] { FC.bead(&m, r: 0.0048, at: V3(x, y, 0.0125), worn, sub: 1) }
        }
        // Second flat bar low on the leaf, and a stainless pull handle with a lock escutcheon on the lock stile.
        FA.box(&m, V3(lw - 0.06, 0.025, 0.012), V3(cx, 0.4, 0.0), coat, r: 0.002)
        m.add(Prim.cylinder(radius: 0.016, height: 0.006, bevel: 0.0015, segments: 16, bevelSegments: 1, material: steel),
              Xform(translation: V3(lw / 2 - 0.015, 1.1, 0.015), rotation: FA.q(90, FA.X)))
        m.add(barHandle(length: 0.14, standoff: 0.007, radius: 0.0065, material: steel),
              Xform(translation: V3(lw / 2 - 0.015, 1.1, 0.0125), rotation: FA.q(90, FA.Z)))
        // Concealed hinges: barrel hinge cylinders at the hinge post, adjustable cap screws.
        for y in [0.32, H - 0.32] as [Float] {
            FA.cylZ(&m, r: 0.012, h: 0.034, at: V3(-px + pw / 2 + 0.002, y, -0.017), steel, bevel: 0.0015, segments: 14)
            FA.cylX(&m, r: 0.004, h: 0.014, at: V3(-px + pw / 2 - 0.004, y, 0.0), steel, bevel: 0.001, segments: 8)
            FA.box(&m, V3(0.014, 0.05, 0.03), V3(-px + pw / 2 + 0.016, y, 0), steel, r: 0.002)
        }
        // Magnetic latch: body on the lock post, striker plate on the leaf.
        FA.box(&m, V3(0.022, 0.1, 0.034), V3(px - pw / 2 - 0.006, 0.95, 0.0), steel, r: 0.003)
        FA.box(&m, V3(0.01, 0.07, 0.03), V3(px - pw / 2 - 0.03, 0.95, 0.0), zinc, r: 0.002)
        FA.box(&m, V3(0.012, 0.016, 0.03), V3(px - 0.002, 0.95, 0.0), steel, r: 0.002)
        // Wear: chipped coat on the lower rail and stiles, damp run at the foot, rust bloom at the weld.
        for k in 0..<7 {
            var r = rng.fork(80 + k)
            FA.box(&m, V3(r.float(0.01...0.03), r.float(0.008...0.02), 0.0305), V3(r.float(-lw / 2...lw / 2), r.chance(0.6) ? ly0 + 0.02 : ly1, 0), zinc, r: 0.001)
        }
        for sx in [-1, 1] as [Float] { FA.box(&m, V3(0.006, 0.12, 0.0305), V3(sx * (lw / 2 - 0.004), ly0 + 0.15, 0), zinc, r: 0.001) }
        groundAO(&m, height: 0.18, floor: 0.55)
        return LODModel(FC.place(m))
    }
}
