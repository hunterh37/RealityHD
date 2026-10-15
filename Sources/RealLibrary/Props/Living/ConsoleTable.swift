import simd
import Foundation

/// Narrow entry console, 120 x 80 x 35 cm: veneered oak top with an eased edge, 95 mm apron with two flush
/// drawers behind a face frame (brass bar pulls), four tapered legs splayed 2 degrees, and a lower shelf
/// on two end rails.
public struct ConsoleTable: RealAsset {
    public static let id = "console-table"
    public static let summary = "Narrow oak entry console with two shallow drawers, brass bar pulls, tapered legs and a lower shelf."
    public static let tags = ["prop", "floorplan", "living", "furniture", "wood", "interior"]
    public static let budget = 7600
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 16, distance: 1.5, studio: true)

    /// Overall size in meters (x width, y height, z depth); the drawers face +Z.
    public var size = V3(1.2, 0.8, 0.35)
    /// Top veneer.
    public var topMaterial: MaterialKey = "wood.veneer-oak:BFA27C"
    /// Apron, drawer and shelf wood.
    public var caseMaterial: MaterialKey = "wood.oak:B59869"
    /// Leg wood (a shade darker from hand contact and sun).
    public var legMaterial: MaterialKey = "wood.oak:A58660"
    /// Pull and foot-cap metal.
    public var metalMaterial: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [5])
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

        m.add(Prim.extrude(Shape2D.roundedRect(W, D, radius: 0.012, segments: detail ? 4 : 2), depth: t, bevel: 0.0035, bevelSegments: detail ? 3 : 1, material: topMaterial),
              Xform(translation: V3(0, underTop + t / 2, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))

        // Legs: 40 -> 26 mm taper, brass sabots 25 mm.
        let legTop = underTop - 0.003
        let cx = W / 2 - 0.05, cz = D / 2 - 0.04
        let splay: Float = tan(2 * .pi / 180)
        func hw(_ y: Float) -> Float { 0.013 + 0.007 * (y / legTop) }
        func ctr(_ sx: Float, _ sz: Float, _ y: Float) -> V3 { let k = (legTop - y) * splay; return V3(sx * (cx + k), y, sz * (cz + k * 0.6)) }
        let sabot: Float = 0.025
        for sx: Float in [-1, 1] {
            for sz: Float in [-1, 1] {
                var rings: [[V3]] = []
                for y in [legTop, legTop * 0.5, sabot - 0.001] {
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

        // Apron 95 mm with face frame around two drawer openings.
        let ah: Float = 0.095, ay = underTop - 0.004 - ah / 2
        let aX = cx + (legTop - ay) * splay, aZ = cz + (legTop - ay) * splay * 0.6
        let lw = hw(ay)
        let spanX = 2 * (aX - lw) + 0.012, spanZ = 2 * (aZ - lw) + 0.012
        let fz = aZ - lw + 0.0075 - 0.002
        box(V3(spanX, ah, 0.018), V3(0, ay, -fz), caseMaterial)
        for s: Float in [-1, 1] { box(V3(0.018, ah, spanZ), V3(s * (aX - lw + 0.0075 - 0.002), ay, 0), caseMaterial) }
        let openH: Float = 0.067, openW: Float = (spanX - 0.07 - 0.04) / 2 // two openings, 40 mm center stile, 35 mm end stiles
        box(V3(spanX, (ah - openH) / 2, 0.018), V3(0, ay + ah / 2 - (ah - openH) / 4, fz), caseMaterial)
        box(V3(spanX, (ah - openH) / 2, 0.018), V3(0, ay - ah / 2 + (ah - openH) / 4, fz), caseMaterial)
        box(V3(0.04, openH, 0.018), V3(0, ay, fz), caseMaterial)
        for s: Float in [-1, 1] { box(V3(0.035, openH, 0.018), V3(s * (spanX / 2 - 0.0175), ay, fz), caseMaterial) }
        for s: Float in [-1, 1] {
            let cxo = s * (0.02 + openW / 2)
            // Story detail: the left drawer is left 10 mm proud, showing its plywood sides.
            let out: Float = s < 0 ? 0.01 : 0
            m.add(cuboid(V3(openW, openH, 0.13), material: dark), Xform(translation: V3(cxo, ay, fz - 0.07)))
            box(V3(openW - 0.004, openH - 0.004, 0.017), V3(cxo, ay, fz + 0.0004 + out), caseMaterial, r: 0.0018)
            if out > 0 {
                for q: Float in [-1, 1] {
                    box(V3(0.012, openH - 0.012, 0.12), V3(cxo + q * (openW / 2 - 0.012), ay - 0.003, fz + 0.0004 + out - 0.0635), "wood.plywood:C9A877", r: 0.0008)
                }
            }
            if detail {
                // 1.2 mm routed groove frame on each drawer front.
                for (dy, w, h) in [(openH / 2 - 0.012, openW - 0.04, Float(0.0012)), (-openH / 2 + 0.012, openW - 0.04, 0.0012)] {
                    m.add(cuboid(V3(w, h, 0.0005), material: dark), Xform(translation: V3(cxo, ay + dy, fz + 0.0092 + out)))
                }
            }
            var pull = barHandle(length: 0.09, standoff: 0.022, radius: 0.0045, overhang: 0.008, material: metalMaterial)
            if !detail { pull = Prim.cylinder(radius: 0.005, height: 0.106, bevel: 0.003, segments: 8, bevelSegments: 1, material: metalMaterial) }
            m.add(pull, Xform(translation: V3(cxo, ay, fz + 0.0089 + out)))
        }

        // Lower shelf at 0.18 on two end rails.
        let shelfY: Float = 0.18
        let sX = cx + (legTop - shelfY) * splay, sZ = cz + (legTop - shelfY) * splay * 0.6
        let sl = hw(shelfY)
        for s: Float in [-1, 1] {
            box(V3(0.018, 0.03, 2 * (sZ - sl) + 0.012), V3(s * (sX - sl + 0.0045), shelfY - 0.0105, 0), caseMaterial)
        }
        box(V3(2 * (sX - sl) - 0.002 + 0.012, 0.016, 2 * (sZ - sl) - 0.002), V3(0, shelfY + 0.0015, 0), caseMaterial, r: 0.0025)
        if detail {
            for s: Float in [-1, 1] { for z: Float in [-0.07, 0.07] {
                m.add(Prim.cylinder(radius: 0.0032, height: 0.0012, bevel: 0.0004, segments: 8, bevelSegments: 1, material: metalMaterial),
                      Xform(translation: V3(s * (sX - sl + 0.0045), shelfY + 0.0095, z)))
            } }
        }

        groundAO(&m, height: 0.15, floor: 0.55)
        return m
    }
}
