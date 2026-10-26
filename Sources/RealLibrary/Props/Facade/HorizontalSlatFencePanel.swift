import simd
import Foundation

/// Horizontal slat fence panel: architectural facade customizer, Contemporary. Parts: steel posts, horizontal cedar slats with gaps, top cap, back channel, fixing screws, base plate.
public struct HorizontalSlatFencePanel: RealAsset {
    public static let id = "horizontal-slat-fence-panel"
    public static let summary = "Contemporary horizontal cedar slat screen in powder-coated posts"
    public static let tags = ["prop", "architecture", "facade", "wood", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.8, 1.8, 0.05)
    public init() {}

    /// Cedar slat tones (fresh and silvering) mixed across the panel.
    public var slats: [MaterialKey] = ["wood.cedar", "wood.cedar-weathered", "wood.cedar", "wood.cedar", "wood.cedar-weathered"]
    /// Powder-coated steel posts, cap and uprights (hex tint after the colon).
    public var coat: MaterialKey = "metal.powdercoat:3E4247"
    /// Galvanised fixings and base plates.
    public var zinc: MaterialKey = "metal.galvanized-aged"
    /// Countersunk screw heads.
    public var screw: MaterialKey = "metal.nickel-worn"
    /// Damp, stained cedar at the foot.
    public var damp: MaterialKey = "wood.waterlogged"
    /// Slat face height and gap in meters.
    public var slatH: Float = 0.092
    public var gap: Float = 0.016

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y
        let pw: Float = 0.05, pxc = W / 2 - pw / 2, inner = W - 2 * pw
        let y0: Float = 0.1, y1 = H - 0.06
        // Posts: 50 mm square tube with a welded cap, base plate and bolts.
        for sx in [-1, 1] as [Float] {
            FA.box(&m, V3(pw, H - 0.012, pw), V3(sx * pxc, (H - 0.012) / 2 + 0.006, 0), coat, r: 0.003)
            FA.box(&m, V3(pw + 0.004, 0.012, pw), V3(sx * pxc, H - 0.006, 0), coat, r: 0.002)
            FA.box(&m, V3(pw, 0.008, pw), V3(sx * pxc, 0.004, 0), zinc, r: 0.002)
            for bx in [-0.018, 0.018] as [Float] { FGate.slab(&m, V3(0.01, 0.01, 0.004), V3(sx * pxc + bx, 0.012, 0.0), screw) }
        }
        // Two flat-bar uprights behind the slats, riveted through to the posts' rail line, and a top channel cap.
        for x in [-0.45, 0.45] as [Float] { FA.box(&m, V3(0.04, y1 - y0 + 0.02, 0.01), V3(x, (y0 + y1) / 2, -0.012), coat, r: 0.0015) }
        FA.box(&m, V3(inner, 0.04, 0.036), V3(0, y1 + 0.018, 0.0), coat, r: 0.002)
        FA.box(&m, V3(inner, 0.012, 0.03), V3(0, y0 - 0.006, 0.0), coat, r: 0.002)
        // Horizontal cedar slats, 92 x 20 mm, 16 mm shadow gaps, tone and length varying slightly.
        let pitch = slatH + gap
        let n = Int((y1 - y0) / pitch)
        for k in 0..<n {
            var r = rng.fork(k)
            let y = y0 + gap / 2 + slatH / 2 + Float(k) * pitch
            let mat = slats[(k * 2 + r.int(0...4)) % slats.count]
            let len = inner - 0.004 - r.float(0...0.004)
            var sl = Prim.roundedBox(V3(len, slatH, 0.02), radius: 0.0025, bevelSegments: 1, material: mat)
            sl.uvs = sl.uvs.map { V2($0.x * 2.2, $0.y * 2.2) }
            sl.computeTangents()
            m.add(sl, Xform(translation: V3(r.float(-0.002...0.002), y, 0.006)))
            // Two countersunk screws per upright, aligned down the column.
            for x in [-0.45, 0.45] as [Float] {
                for dx in [-0.011, 0.011] as [Float] { FGate.slab(&m, V3(0.006, 0.006, 0.002), V3(x + dx, y + r.float(-0.001...0.001), 0.0165), screw) }
            }
            // Checking at a slat end and a knot on some boards.
            if r.chance(0.45) { FGate.slab(&m, V3(r.float(0.08...0.2), 0.002, 0.0012), V3(r.float(-inner / 2 + 0.15...inner / 2 - 0.15), y + r.float(-0.02...0.02), 0.0166), "wood.charred") }
            if r.chance(0.25) { FGate.slab(&m, V3(0.026, 0.026, 0.0012), V3(r.float(-0.7...0.7), y, 0.0166), "wood.charred") }
        }
        // Water staining on the lowest slats, bleached top slat band.
        FGate.slab(&m, V3(inner - 0.01, 0.2, 0.0012), V3(0, y0 + 0.11, 0.0166), damp)
        groundAO(&m, height: 0.2, floor: 0.55)
        return LODModel(FC.place(m))
    }
}
