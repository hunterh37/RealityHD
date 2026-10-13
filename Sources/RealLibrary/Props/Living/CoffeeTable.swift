import simd
import Foundation

/// Mid-century walnut coffee table, 110 x 46 x 60 cm: 35 mm walnut-veneered top with rounded corners and an
/// eased edge, 20 mm apron frame with corner blocks, four tapered legs splayed 4 degrees with brass
/// ferrules, and a lower shelf of six walnut slats resting on two end rails.
public struct CoffeeTable: RealAsset {
    public static let id = "coffee-table"
    public static let summary = "Mid-century walnut coffee table with a rounded-corner top, tapered splayed legs with brass ferrules and a lower shelf."
    public static let tags = ["prop", "floorplan", "living", "furniture", "wood", "interior"]
    public static let budget = 7000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 22, distance: 1.6, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(1.1, 0.46, 0.6)
    /// Top thickness in meters.
    public var topThickness: Float = 0.035
    /// Top, apron and leg wood.
    public var topMaterial: MaterialKey = "wood.veneer-walnut:6A4630"
    /// Solid wood for legs, apron and shelf.
    public var solidMaterial: MaterialKey = "wood.walnut:5E3F2B"
    /// Legs: a sun-faded, hand-rubbed oil finish a shade lighter than the apron.
    public var legMaterial: MaterialKey = "wood.walnut:7A5339"
    /// Shelf slats: darker, unlit under the top.
    public var shelfMaterial: MaterialKey = "wood.walnut:6F4A33"
    /// Ferrule metal.
    public var ferruleMaterial: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [4])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y, D = size.z, t = topThickness
        let underTop = H - t
        let seg = detail ? 3 : 1

        // Top: veneered slab, plan corners r 35 mm, 4 mm eased edge. Extrusion axis turned vertical.
        let plan = Shape2D.roundedRect(W, D, radius: 0.035, segments: detail ? 6 : 3)
        m.add(Prim.extrude(plan, depth: t, bevel: 0.004, bevelSegments: seg, material: topMaterial),
              Xform(translation: V3(0, underTop + t / 2, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        // Underside reveal: a 6 mm shadow lip stepping in from the top edge.
        let lip = Shape2D.roundedRect(W - 0.05, D - 0.05, radius: 0.02, segments: detail ? 4 : 2)
        m.add(Prim.extrude(lip, depth: 0.008, bevel: 0.002, bevelSegments: 1, material: solidMaterial),
              Xform(translation: V3(0, underTop - 0.003, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))

        // Legs: square taper 40 -> 27 mm, splayed 4 degrees outward toward the floor.
        let legTopH = underTop - 0.004
        let topCx = W / 2 - 0.075, topCz = D / 2 - 0.07
        let splay: Float = tan(4 * .pi / 180)
        func center(_ sx: Float, _ sz: Float, y: Float) -> V3 {
            let k = (legTopH - y) * splay
            return V3(sx * (topCx + k), y, sz * (topCz + k * 0.7))
        }
        func halfWidth(y: Float) -> Float { 0.0135 + 0.0065 * (y / legTopH) }
        let ferruleH: Float = 0.032
        for sx: Float in [-1, 1] {
            for sz: Float in [-1, 1] {
                var rings: [[V3]] = []
                for y in [legTopH, legTopH * 0.55, ferruleH - 0.001] {
                    let w = halfWidth(y: y) * 2
                    rings.append(Prim.ring(Shape2D.roundedRect(w, w, radius: 0.004, segments: detail ? 2 : 1), y: y, offset: center(sx, sz, y: y) - V3(0, y, 0)))
                }
                m.add(Prim.loft(rings, capStart: true, capEnd: true, material: legMaterial).flipped().deformedGrainFix())
                // Brass ferrule: open sleeve slightly proud of the leg, flat foot.
                var fr: [[V3]] = []
                for y in [0.0005, ferruleH] {
                    let w = halfWidth(y: y) * 2 + 0.002
                    fr.append(Prim.ring(Shape2D.roundedRect(w, w, radius: 0.005, segments: detail ? 2 : 1), y: y, offset: center(sx, sz, y: y) - V3(0, y, 0)))
                }
                m.add(Prim.loft(fr, capStart: true, capEnd: true, material: ferruleMaterial).flipped())
            }
        }

        // Apron: 70 x 20 mm rails below the top, mortised into the legs (ends buried 6 mm).
        let apronH: Float = 0.07, apronY = underTop - apronH / 2 - 0.004
        let ax = topCx + (legTopH - apronY) * splay
        let az = topCz + (legTopH - apronY) * splay * 0.7
        let lw = halfWidth(y: apronY)
        m.add(plank(2 * ax - lw * 2 + 0.012, apronH, 0.02, bevel: 0.002, material: solidMaterial),
              Xform(translation: V3(0, apronY, az - lw + 0.0075)).jittered(&rng, deg: 0.05, offset: 0.0002))
        m.add(plank(2 * ax - lw * 2 + 0.012, apronH, 0.02, bevel: 0.002, material: solidMaterial),
              Xform(translation: V3(0, apronY, -(az - lw + 0.0075))).jittered(&rng, deg: 0.05, offset: 0.0002))
        for s: Float in [-1, 1] {
            m.add(plank(2 * az - lw * 2 + 0.012, apronH, 0.02, bevel: 0.002, material: solidMaterial),
                  Xform(translation: V3(s * (ax - lw + 0.0075), apronY, 0), rotation: simd_quatf(degrees: 90, axis: .up)))
        }
        // Corner blocks glued behind each leg-apron joint, with a screw pilot.
        if detail {
            for sx: Float in [-1, 1] {
                for sz: Float in [-1, 1] {
                    let p = V3(sx * (ax - lw - 0.03), underTop - 0.03, sz * (az - lw - 0.03))
                    m.add(Prim.roundedBox(V3(0.06, 0.05, 0.06), radius: 0.002, bevelSegments: 1, material: solidMaterial),
                          Xform(translation: p, rotation: simd_quatf(degrees: sx * sz * 45, axis: .up)))
                    m.add(Prim.cylinder(radius: 0.0035, height: 0.003, bevel: 0.0008, segments: 8, bevelSegments: 1, material: ferruleMaterial),
                          Xform(translation: p + V3(0, -0.0255, 0), rotation: simd_quatf(degrees: 180, axis: V3(1, 0, 0))))
                }
            }
        }

        // Lower shelf: two end rails along Z, six slats along X with 12 mm gaps.
        let shelfY: Float = 0.13, railH: Float = 0.04
        let sx0 = topCx + (legTopH - shelfY) * splay, sz0 = topCz + (legTopH - shelfY) * splay * 0.7
        let lw2 = halfWidth(y: shelfY)
        let railLen = 2 * (sz0 - lw2) + 0.012
        for s: Float in [-1, 1] {
            m.add(plank(railLen, railH, 0.022, bevel: 0.002, material: shelfMaterial),
                  Xform(translation: V3(s * (sx0 - lw2 + 0.005), shelfY - railH / 2 + 0.005, 0), rotation: simd_quatf(degrees: 90, axis: .up)))
        }
        let slatLen = 2 * (sx0 - lw2) - 0.002 + 0.02
        let span = 2 * (sz0 - lw2) - 0.004
        let gap: Float = 0.012, n = 6
        let slatW = (span - gap * Float(n - 1)) / Float(n)
        for i in 0..<n {
            let z = -span / 2 + slatW / 2 + Float(i) * (slatW + gap)
            m.add(plank(slatLen, slatW, 0.014, bevel: 0.0025, material: shelfMaterial),
                  Xform(translation: V3(0, shelfY + 0.005 + 0.007, z)).jittered(&rng, deg: 0.1, offset: 0.0003))
        }
        // Screw heads through slats into the rails (four per slat end pair on the outer slats).
        if detail {
            for s: Float in [-1, 1] {
                for i in [0, n - 1] {
                    let z = -span / 2 + slatW / 2 + Float(i) * (slatW + gap)
                    m.add(Prim.cylinder(radius: 0.0035, height: 0.0012, bevel: 0.0004, segments: 8, bevelSegments: 1, material: ferruleMaterial),
                          Xform(translation: V3(s * (sx0 - lw2 + 0.005), shelfY + 0.0125 + 0.007, z)))
                }
            }
        }

        if detail {
            // Dowel plugs: end-grain pegs capping the apron tenon pins on the outer leg faces and the shelf rail pins.
            for sx: Float in [-1, 1] {
                for sz: Float in [-1, 1] {
                    for (y, pegR) in [(apronY, Float(0.0045)), (shelfY - 0.01, Float(0.0045))] {
                        let c = center(sx, sz, y: y)
                        m.add(Prim.cylinder(radius: pegR, height: 0.0016, bevel: 0.0004, segments: 10, bevelSegments: 1, material: "wood.endgrain:4A2F1F"),
                              Xform(translation: c + V3(sx * (halfWidth(y: y) - 0.0004), 0, 0), rotation: facing(V3(sx, 0, 0))))
                    }
                }
            }
        }
        groundAO(&m, height: 0.14, floor: 0.55)
        return m
    }
}

private extension Surface {
    /// Loft UVs run around then along; wood grain should follow the leg length, so swap U and V.
    func deformedGrainFix() -> Surface {
        var s = self
        s.uvs = s.uvs.map { V2($0.y, $0.x) }
        s.computeTangents()
        return s
    }
}
