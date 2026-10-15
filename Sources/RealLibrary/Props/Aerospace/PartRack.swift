import simd
import Foundation

/// Hangar part rack, 2.8 m wide: two blue roll-formed upright frames with zigzag bracing and foot plates,
/// orange step beams at three levels with wire decks, holding a brushed tank section on a padded plywood
/// cradle, a white nose cone on its side and two plywood parts crates with hazard tags.
public struct PartRack: RealAsset {
    public static let id = "part-rack"
    public static let summary = "Hangar part rack, 2.8 m: blue upright frames, orange step beams, wire decks with a tank section in a cradle, nose cone and parts crates."
    public static let tags = ["prop", "aerospace", "interior", "industrial", "metal", "furniture"]
    public static let budget = 12_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 12, distance: 1.1)

    public var width: Float = 2.8
    public var height: Float = 2.4
    public var depth: Float = 1.0
    /// Beam levels (top of beam) in meters.
    public var levels: [Float] = [0.15, 1.0, 1.85]
    public var upright: MaterialKey = "metal.hammer-painted:2B5DA8"
    public var beam: MaterialKey = "metal.hammer-painted:E06A1B"
    public var deck: MaterialKey = "metal.basket-mesh"
    public var steel: MaterialKey = "metal.galvanized"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(seed: seed, detail: true), level(seed: seed, detail: false)], switchDistances: [12])
    }

    func level(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hw = width / 2, hd = depth / 2, H = height
        let sides = detail ? 6 : 4
        func box(_ c: V3, _ s: V3, _ mat: MaterialKey, _ r: Float = 0.004) {
            m.add(Prim.roundedBox(s, radius: r, bevelSegments: 1, material: mat), Xform(translation: c))
        }
        // upright frames: two posts each, zigzag bracing, foot plates
        for x in [-hw + 0.04, hw - 0.04] {
            for z in [-hd + 0.04, hd - 0.04] {
                box(V3(x, H / 2, z), V3(0.075, H, 0.065), upright, 0.006)
                box(V3(x, 0.004, z), V3(0.14, 0.008, 0.12), upright, 0.002)
                if detail { hexBolt(&m, at: V3(x + 0.05, 0.008, z), normal: V3(0, 1, 0), size: 0.014, material: steel) }
            }
            var y: Float = 0.15
            var front = true
            while y + 0.55 <= H {
                let a = V3(x, y, front ? -hd + 0.07 : hd - 0.07), b = V3(x, y + 0.55, front ? hd - 0.07 : -hd + 0.07)
                m.add(Prim.tube([a, b], radii: [0.016, 0.016], sides: sides, seamTile: 0.3, material: upright), .identity)
                y += 0.55; front.toggle()
            }
            m.add(Prim.tube([V3(x, 0.1, -hd + 0.07), V3(x, 0.1, hd - 0.07)], radii: [0.016, 0.016], sides: sides, seamTile: 0.3, material: upright), .identity)
        }
        // beams and wire decks
        for yl in levels {
            for z in [-hd + 0.04, hd - 0.04] {
                box(V3(0, yl - 0.06, z + (z < 0 ? -0.045 : 0.045)), V3(width - 0.02, 0.12, 0.05), beam, 0.006)
            }
            box(V3(0, yl + 0.012, 0), V3(width - 0.12, 0.025, depth - 0.02), deck, 0.003)
            if detail {
                for x in stride(from: -hw + 0.4, to: hw - 0.2, by: 0.45) { box(V3(x, yl - 0.012, 0), V3(0.04, 0.03, depth - 0.04), steel, 0.003) }
            }
        }
        // middle level: brushed tank section on a padded plywood cradle, shrink-wrapped ends
        let y1 = levels[1] + 0.025
        let tr: Float = 0.32, tl: Float = 1.5
        for x in [Float(-0.45), 0.45] {
            // saddle block with a felt pad strip under the shell
            box(V3(x, y1 + 0.09, 0), V3(0.06, 0.18, 0.62), "wood.lumber-pine", 0.008)
            box(V3(x, y1 + 0.185, 0), V3(0.07, 0.012, 0.5), "fabric.wool:3A3A3A", 0.004)
        }
        let tank = Prim.lathe([V2(tr * 0.98, 0), V2(tr, 0.01), V2(tr, tl - 0.01), V2(tr * 0.98, tl)], segments: detail ? 28 : 12, seamTile: 0.4,
                              material: "metal.aluminum-brushed")
        m.add(tank, Xform(translation: V3(-tl / 2, y1 + 0.19 + tr, 0), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
        for x in [-tl / 2 - 0.004, tl / 2 + 0.004] {
            m.add(Prim.cylinder(radius: tr - 0.01, height: 0.008, bevel: 0.002, segments: detail ? 28 : 12, material: "plastic.clear"),
                  Xform(translation: V3(x, y1 + 0.19 + tr, 0), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        }
        // ratchet straps holding the shell to the saddles, inspection tag on the shell
        for x in [Float(-0.45), 0.45] {
            m.add(Prim.torus(major: tr + 0.006, minor: 0.022, segments: 24, sides: 4, minorY: 0.003, material: "fabric.webbing:E0B21B"),
                  Xform(translation: V3(x + 0.05, y1 + 0.19 + tr, 0), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
            box(V3(x + 0.05, y1 + 0.19 + tr * 0.3, tr * 0.95 + 0.02), V3(0.05, 0.12, 0.03), "metal.galvanized", 0.005)
        }
        m.add(Prim.roundedBox(V3(0.12, 0.08, 0.004), radius: 0.001, bevelSegments: 1, material: "label.hazard"),
              Xform(translation: V3(-0.2, y1 + 0.19 + tr * 1.5, tr * 0.87 + 0.004), rotation: simd_quatf(degrees: -30, axis: V3(1, 0, 0))))
        // weld seam ring
        m.add(Prim.torus(major: tr + 0.002, minor: 0.004, segments: 28, sides: 4, material: "metal.heat-tint-light"),
              Xform(translation: V3(0.1, y1 + 0.19 + tr, 0), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        // top level: nose cone on its side, two crates with hazard tags
        let y2 = levels[2] + 0.025
        let cone = Prim.lathe((0...10).map { k in let t = Float(k) / 10; return V2(0.22 * sqrt(max(0, 1 - t * t)) + 0.001, t * 0.75) },
                              segments: detail ? 24 : 10, seamTile: 0.3, material: "plastic.white")
        m.add(cone, Xform(translation: V3(-0.65, y2 + 0.2, 0.05), rotation: simd_quatf(degrees: -88, axis: V3(0, 0, 1))))
        m.add(Prim.roundedBox(V3(0.3, 0.06, 0.3), radius: 0.01, bevelSegments: 1, material: "plastic.black"), Xform(translation: V3(-0.65, y2 + 0.03, 0.05)))
        for (i, x) in [Float(0.45), 1.0].enumerated() {
            let s = V3(0.5, i == 0 ? 0.42 : 0.3, 0.55)
            box(V3(x, y2 + s.y / 2, rng.float(-0.05...0.05)), s, "wood.lumber-pine", 0.01)
            box(V3(x, y2 + s.y * 0.6, -s.z / 2 - 0.003), V3(0.16, 0.11, 0.004), "label.hazard", 0.001)
        }
        // bottom level: a coil of umbilical hose
        m.add(Prim.torus(major: 0.28, minor: 0.03, segments: 24, sides: 6, material: "rubber"), Xform(translation: V3(0.7, levels[0] + 0.055, 0)))
        m.add(Prim.torus(major: 0.24, minor: 0.03, segments: 24, sides: 6, material: "rubber"), Xform(translation: V3(0.72, levels[0] + 0.11, 0.02)))
        groundAO(&m)
        return m
    }
}
