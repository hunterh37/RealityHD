import simd
import Foundation

/// Square walnut end table, 55 x 55 x 55 cm: veneered top with rounded corners, 120 mm apron with a face
/// frame around a single flush drawer (raised front, brass ball knob, escutcheon), four tapered legs with
/// brass sabots and a lower shelf on two end rails.
public struct EndTable: RealAsset {
    public static let id = "end-table"
    public static let summary = "Square walnut end table with a single drawer, brass knob, tapered legs with brass feet and a lower shelf."
    public static let tags = ["prop", "floorplan", "living", "furniture", "wood", "interior"]
    public static let budget = 6000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 20, distance: 1.1, studio: true)

    /// Overall size in meters (x width, y height, z depth); the drawer faces +Z.
    public var size = V3(0.55, 0.55, 0.55)
    /// Top veneer.
    public var topMaterial: MaterialKey = "wood.veneer-walnut:6A4630"
    /// Apron, drawer and shelf wood.
    public var caseMaterial: MaterialKey = "wood.walnut:5E3F2B"
    /// Leg wood.
    public var legMaterial: MaterialKey = "wood.walnut:7A5339"
    /// Knob and sabot metal.
    public var metalMaterial: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [4])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y, D = size.z
        let t: Float = 0.03, underTop = H - t
        let dark: MaterialKey = "plastic.black"
        func box(_ s: V3, _ p: V3, _ mat: MaterialKey, r: Float = 0.0015) {
            m.add(Prim.roundedBox(s, radius: r, bevelSegments: detail ? 2 : 1, material: mat), Xform(translation: p).jittered(&rng, deg: 0.04, offset: 0.0001))
        }

        // Top with 20 mm plan corners and an eased edge, plus a stepped underside lip.
        m.add(Prim.extrude(Shape2D.roundedRect(W, D, radius: 0.022, segments: detail ? 5 : 2), depth: t, bevel: 0.0035, bevelSegments: detail ? 3 : 1, material: topMaterial),
              Xform(translation: V3(0, underTop + t / 2, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))

        // Legs: 40 -> 25 mm taper, 2 degree splay, brass sabots 30 mm tall.
        let legTop = underTop - 0.003
        let cx = W / 2 - 0.045, cz = D / 2 - 0.045
        let splay: Float = tan(2 * .pi / 180)
        func hw(_ y: Float) -> Float { 0.0125 + 0.0075 * (y / legTop) }
        func ctr(_ sx: Float, _ sz: Float, _ y: Float) -> V3 { let k = (legTop - y) * splay; return V3(sx * (cx + k), y, sz * (cz + k)) }
        let sabot: Float = 0.03
        for sx: Float in [-1, 1] {
            for sz: Float in [-1, 1] {
                var rings: [[V3]] = []
                for y in [legTop, legTop * 0.55, sabot - 0.001] {
                    let w = hw(y) * 2
                    rings.append(Prim.ring(Shape2D.roundedRect(w, w, radius: 0.0035, segments: detail ? 2 : 1), y: y, offset: ctr(sx, sz, y) - V3(0, y, 0)))
                }
                var leg = Prim.loft(rings, capStart: true, capEnd: true, material: legMaterial).flipped()
                leg.uvs = leg.uvs.map { V2($0.y, $0.x) }; leg.computeTangents()
                m.add(leg)
                var sb: [[V3]] = []
                for y in [0.0005, sabot] {
                    let w = hw(y) * 2 + 0.0018
                    sb.append(Prim.ring(Shape2D.roundedRect(w, w, radius: 0.0045, segments: detail ? 2 : 1), y: y, offset: ctr(sx, sz, y) - V3(0, y, 0)))
                }
                m.add(Prim.loft(sb, capStart: true, capEnd: true, material: metalMaterial).flipped())
            }
        }

        // Apron: 120 mm high rails between legs, set 4 mm under the top, 20 mm thick.
        let ah: Float = 0.12, ay = underTop - 0.004 - ah / 2
        let aX = cx + (legTop - ay) * splay, aZ = cz + (legTop - ay) * splay
        let lw = hw(ay)
        let spanX = 2 * (aX - lw) + 0.012, spanZ = 2 * (aZ - lw) + 0.012
        box(V3(spanX, ah, 0.02), V3(0, ay, -(aZ - lw + 0.0075 - 0.002)), caseMaterial)           // back
        for s: Float in [-1, 1] { box(V3(0.02, ah, spanZ), V3(s * (aX - lw + 0.0075 - 0.002), ay, 0), caseMaterial) }
        // Face frame around the drawer opening (opening 380 x 94 mm).
        let fz = aZ - lw + 0.0075 - 0.002, openW: Float = 0.38, openH: Float = 0.092
        box(V3(spanX, (ah - openH) / 2, 0.02), V3(0, ay + ah / 2 - (ah - openH) / 4, fz), caseMaterial)
        box(V3(spanX, (ah - openH) / 2, 0.02), V3(0, ay - ah / 2 + (ah - openH) / 4, fz), caseMaterial)
        let stileW = (spanX - openW) / 2
        for s: Float in [-1, 1] { box(V3(stileW, openH, 0.02), V3(s * (openW / 2 + stileW / 2), ay, fz), caseMaterial) }
        // Drawer box behind the opening (shadowed interior) and the 2 mm reveal.
        m.add(cuboid(V3(openW, openH, 0.18), material: dark), Xform(translation: V3(0, ay, fz - 0.1)))
        let dfW = openW - 0.004, dfH = openH - 0.004
        // Story detail: the drawer sits 14 mm proud of its opening, showing the plywood drawer-box sides.
        let out: Float = 0.014
        box(V3(dfW, dfH, 0.019), V3(0, ay, fz + 0.0005 + out), caseMaterial, r: 0.002)
        for s: Float in [-1, 1] {
            box(V3(0.012, dfH - 0.012, 0.15), V3(s * (dfW / 2 - 0.014), ay - 0.003, fz + 0.0005 + out - 0.0845), "wood.plywood:C9A877", r: 0.0008)
        }
        m.add(cuboid(V3(dfW - 0.03, 0.01, 0.15), material: "wood.plywood:B8956A"), Xform(translation: V3(0, ay - dfH / 2 + 0.003, fz + out - 0.084)))
        if detail {
            // Raised field on the drawer front: 6 mm bevelled panel with a routed groove around it.
            box(V3(dfW - 0.05, dfH - 0.03, 0.004), V3(0, ay, fz + 0.011 + out), caseMaterial, r: 0.001)
            m.add(cuboid(V3(dfW - 0.036, 0.0012, 0.0005), material: dark), Xform(translation: V3(0, ay + dfH / 2 - 0.0125, fz + 0.0099 + out)))
            m.add(cuboid(V3(dfW - 0.036, 0.0012, 0.0005), material: dark), Xform(translation: V3(0, ay - dfH / 2 + 0.0125, fz + 0.0099 + out)))
        }
        // Brass ball knob: 28 mm head on a 6 mm shank, backplate rosette.
        let kz = fz + 0.0135 + out
        let knob: [V2] = [V2(0.0001, 0.0), V2(0.011, 0.0), V2(0.011, 0.0015), V2(0.0035, 0.0025), V2(0.0035, 0.008),
                          V2(0.0085, 0.0095), V2(0.0125, 0.0135), V2(0.0145, 0.0185), V2(0.0125, 0.0235), V2(0.0075, 0.0265), V2(0.0001, 0.027)]
        m.add(Prim.lathe(knob, segments: detail ? 24 : 12, seamTile: 0.1, material: metalMaterial),
              Xform(translation: V3(0, ay, kz), rotation: facing(V3(0, 0, 1))))

        // Lower shelf on two end rails.
        let shelfY: Float = 0.12
        let sX = cx + (legTop - shelfY) * splay, sZ = cz + (legTop - shelfY) * splay
        let sl = hw(shelfY)
        for s: Float in [-1, 1] {
            box(V3(0.02, 0.03, 2 * (sZ - sl) + 0.012), V3(s * (sX - sl + 0.0055), shelfY - 0.0105, 0), caseMaterial)
        }
        box(V3(2 * (sX - sl) - 0.002 + 0.012, 0.016, 2 * (sZ - sl) - 0.002), V3(0, shelfY + 0.0015, 0), caseMaterial, r: 0.0025)
        // Brass screws through the shelf into the rails.
        if detail {
            for s: Float in [-1, 1] { for z: Float in [-0.12, 0.12] {
                m.add(Prim.cylinder(radius: 0.0032, height: 0.0012, bevel: 0.0004, segments: 8, bevelSegments: 1, material: metalMaterial),
                      Xform(translation: V3(s * (sX - sl + 0.0055), shelfY + 0.0095, z)))
            } }
        }

        groundAO(&m, height: 0.12, floor: 0.55)
        return m
    }
}
