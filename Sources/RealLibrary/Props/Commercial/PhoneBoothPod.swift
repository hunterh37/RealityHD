import simd
import Foundation

/// Office phone booth pod, 1.0 x 1.0 m footprint and 2.3 m high: charcoal felt-wrapped slat acoustic walls on three sides, anodized aluminum corner posts on a black plinth, a tinted glass door in an aluminum frame with a frosted privacy band and a vertical bar handle, a powder-coated roof with a vent grille and LED strip, and inside an oak floor, built-in oak-topped bench, wall ledge, power outlet and downlight. Door and handle face +Z.
public struct PhoneBoothPod: RealAsset {
    public static let id = "phone-booth-pod"
    public static let summary = "Acoustic phone booth pod, 1 x 1 x 2.3 m: felt slat walls, glass door, bench and shelf inside, LED roof."
    public static let tags = ["prop", "floorplan", "commercial", "office", "furniture", "fabric", "glass", "metal", "interior"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 12, distance: 4.2, studio: true)

    /// Overall size in meters (x width, y height, z depth including the door handle).
    public var size = V3(1.0, 2.3, 1.0)
    /// Felt on the slats.
    public var felt: MaterialKey = "fabric.upholstery:5E6B74"
    /// Darker felt behind the slats and inside.
    public var feltDark: MaterialKey = "fabric.upholstery:3B434A"
    /// Corner posts, door frame and handle.
    public var aluminum: MaterialKey = "metal.anodized"
    /// Plinth, roof and bench base.
    public var coat: MaterialKey = "metal.powdercoat:2B2D30"
    /// Floor, bench top and ledge.
    public var oak: MaterialKey = "wood.veneer-oak"
    /// Door glass.
    public var glass: MaterialKey = "glass.tinted"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [6])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let bs = detail ? 2 : 1
        func box(_ sz: V3, _ c: V3, _ key: MaterialKey, r: Float = 0.003, flat: Bool = false) {
            if flat { m.add(cuboid(sz, material: key), Xform(translation: c)); return }
            m.add(Prim.roundedBox(sz, radius: min(r, sz.x / 2.2, sz.y / 2.2, sz.z / 2.2), bevelSegments: bs, material: key), Xform(translation: c))
        }
        let W = size.x, H = size.y
        let px: Float = W / 2 - 0.02, pz: Float = 0.4625     // post centers
        let plinth: Float = 0.08, roofT: Float = 0.07
        let yBot = plinth, yTop = H - roofT
        let postH = yTop - yBot
        // Plinth and roof.
        box(V3(W - 0.004, plinth, 2 * pz + 0.04), V3(0, plinth / 2, 0), coat, r: 0.006)
        box(V3(W, roofT, 2 * pz + 0.045), V3(0, H - roofT / 2, 0), coat, r: 0.012)
        // Posts.
        for sx: Float in [-1, 1] {
            for sz: Float in [-1, 1] {
                box(V3(0.04, postH, 0.04), V3(sx * px, yBot + postH / 2, sz * pz), aluminum, r: 0.005)
            }
        }
        // Slat walls: dark backing panel plus vertical felt slats on the outside.
        let slatH = postH - 0.02
        func wall(span: Float, center: V3, alongX: Bool, outward: Float) {
            let t: Float = 0.03
            let sz = alongX ? V3(span, postH, t) : V3(t, postH, span)
            box(sz, center, feltDark, r: 0.002)
            let pitch: Float = detail ? 0.04 : 0.08, sw: Float = detail ? 0.028 : 0.07
            let count = Int(span / pitch)
            for k in 0..<count {
                let o = -span / 2 + (Float(k) + 0.5) * span / Float(count)
                let c = alongX ? V3(center.x + o, yBot + postH / 2, center.z + outward * (t / 2 + 0.006))
                               : V3(center.x + outward * (t / 2 + 0.006), yBot + postH / 2, center.z + o)
                // Every seventh slat a shade lighter; the lowest 0.22 m darkened by scuffs and dust.
                let tone: MaterialKey = k % 7 == 3 ? "fabric.upholstery:6A777F" : felt
                let low: Float = 0.22
                let ss = alongX ? V3(sw, slatH - low, 0.012) : V3(0.012, slatH - low, sw)
                box(ss, c + V3(0, low / 2, 0), tone, flat: true)
                let sl = alongX ? V3(sw, low, 0.0125) : V3(0.0125, low, sw)
                box(sl, c + V3(0, -(slatH - low) / 2, 0), "fabric.upholstery:2F363C", flat: true)
            }
        }
        let span = 2 * px - 0.04
        wall(span: span, center: V3(0, yBot + postH / 2, -pz + 0.002), alongX: true, outward: -1)
        wall(span: 2 * pz - 0.04, center: V3(-px + 0.002, yBot + postH / 2, 0), alongX: false, outward: -1)
        wall(span: 2 * pz - 0.04, center: V3(px - 0.002, yBot + postH / 2, 0), alongX: false, outward: 1)
        // Door: aluminum stiles and rails around tinted glass, frosted band, bar handle.
        let dz = pz
        let dw = 2 * px - 0.04
        for sx: Float in [-1, 1] { box(V3(0.04, postH, 0.04), V3(sx * (dw / 2 - 0.02), yBot + postH / 2, dz), sx > 0 ? "metal.anodized-worn" : aluminum, r: 0.004) }
        box(V3(dw, 0.05, 0.04), V3(0, yTop - 0.025, dz), aluminum, r: 0.004)
        box(V3(dw, 0.1, 0.04), V3(0, yBot + 0.05, dz), aluminum, r: 0.004)
        let gw = dw - 0.08, gy0 = yBot + 0.1, gy1 = yTop - 0.05
        box(V3(gw, gy1 - gy0, 0.008), V3(0, (gy0 + gy1) / 2, dz), glass, r: 0.001)
        box(V3(gw, 0.2, 0.0095), V3(0, 1.0, dz), "glass.frosted", r: 0.001)
        // Door seal strip and a sticker-like pictogram plate on the glass.
        box(V3(0.006, gy1 - gy0, 0.012), V3(-gw / 2 + 0.003, (gy0 + gy1) / 2, dz), "plastic.black", flat: true)
        box(V3(0.06, 0.06, 0.0012), V3(-0.25, 1.3, dz + 0.0052), "metal.satin-aluminum", flat: true)
        // Handle: vertical bar standing off the front of the right stile.
        let hx = dw / 2 - 0.02
        m.add(barHandle(length: 0.5, standoff: 0.0325, radius: 0.0085, overhang: 0.02, material: "metal.anodized-worn"),
              Xform(translation: V3(hx - 0.045, 1.05, dz + 0.02), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        // Roof details: vent grille slots on top, underside LED strip and downlight.
        for k in 0..<(detail ? 7 : 0) {
            box(V3(0.5, 0.0012, 0.012), V3(0, H + 0.0004, -0.2 + Float(k) * 0.03), "plastic.black", flat: true)
        }
        box(V3(0.8, 0.008, 0.02), V3(0, yTop - 0.004, 0.36), "emissive.warm", flat: true)
        m.add(Prim.cylinder(radius: 0.06, height: 0.006, bevel: 0.002, segments: detail ? 20 : 8, material: "emissive.warm"),
              Xform(translation: V3(0, yTop - 0.006, -0.05), rotation: simd_quatf(degrees: 180, axis: V3(1, 0, 0)) ))
        // Interior: oak floor, built-in bench against the back wall, wall ledge, outlet.
        box(V3(2 * px - 0.04, 0.012, 2 * pz - 0.04), V3(0, yBot + 0.006, 0), oak, r: 0.002)
        let bw = 2 * px - 0.07, bd: Float = 0.38
        box(V3(bw, 0.36, bd), V3(0, yBot + 0.012 + 0.18, -pz + 0.02 + bd / 2), oak, r: 0.006)
        box(V3(bw + 0.01, 0.04, bd + 0.012), V3(0, yBot + 0.012 + 0.38, -pz + 0.02 + bd / 2 + 0.002), oak, r: 0.008)
        box(V3(bw - 0.12, 0.04, bd - 0.1), V3(0, yBot + 0.012 + 0.42 + 0.01, -pz + 0.02 + bd / 2), "fabric.upholstery:C9C2B2", r: 0.014)
        // Ledge on the right wall and a small laptop-like slab on it for scale.
        box(V3(0.3, 0.025, 0.46), V3(px - 0.04 - 0.15 + 0.02, 1.0, 0.04), oak, r: 0.005)
        box(V3(0.24, 0.012, 0.17), V3(px - 0.18, 1.0 + 0.0185, 0.05), "plastic.black:222222", r: 0.004)
        // Power outlet with USB ports on the back wall above the bench.
        let oz = -pz + 0.02 + 0.015
        box(V3(0.075, 0.115, 0.008), V3(-0.25, 0.95, oz + 0.004), "plastic.white", r: 0.003)
        for oy: Float in [0.975, 0.925] {
            box(V3(0.036, 0.03, 0.002), V3(-0.25, oy, oz + 0.009), "plastic.black", flat: true)
        }
        // Wall light: small emissive bar beside the outlet.
        box(V3(0.18, 0.02, 0.012), V3(0.1, 1.55, oz + 0.006), "emissive.warm", r: 0.004)
        // Scuffs: lighter nicks along the plinth top edge.
        for _ in 0..<(detail ? 4 : 0) {
            box(V3(rng.float(0.02...0.06), 0.004, 0.0015), V3(rng.float(-0.4...0.4), plinth - 0.01, pz + 0.0215), "metal.satin-aluminum", flat: true)
        }
        groundAO(&m)
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)))
        return m
    }
}
