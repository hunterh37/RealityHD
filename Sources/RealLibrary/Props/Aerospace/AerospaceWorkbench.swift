import simd
import Foundation

/// Avionics workbench, 2 m: grey powder-coated steel frame on leveling feet, blue ESD mat over a steel
/// top, a three-drawer unit, lower shelf, pegboard riser with a shelf and an LED light bar, and on the
/// mat an avionics box with connectors and a ground cord, a bench vise, a wire spool and a torque wrench.
public struct AerospaceWorkbench: RealAsset {
    public static let id = "aerospace-workbench"
    public static let summary = "Avionics workbench, 2 m: grey steel frame on leveling feet, blue ESD mat, drawer unit, pegboard riser with LED bar, avionics box, vise and wire spool."
    public static let tags = ["prop", "aerospace", "interior", "workshop", "furniture", "metal"]
    public static let budget = 12_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 14, distance: 1.05)

    public var width: Float = 2.0
    public var depth: Float = 0.8
    public var topHeight: Float = 0.9
    public var riserHeight: Float = 1.0
    public var frame: MaterialKey = "metal.enamel:6B7177"
    public var mat: MaterialKey = "rubber.silicone-gray:3E6E9E"
    public var steel: MaterialKey = "metal.galvanized"
    public var peg: MaterialKey = "wood.pegboard"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(seed: seed, detail: true), level(seed: seed, detail: false)], switchDistances: [8])
    }

    func level(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hw = width / 2, hd = depth / 2, T = topHeight
        let segs = detail ? 16 : 8
        func box(_ c: V3, _ s: V3, _ mt: MaterialKey, _ r: Float = 0.004) {
            m.add(Prim.roundedBox(s, radius: r, bevelSegments: 1, material: mt), Xform(translation: c))
        }
        // legs with leveling feet, stretchers, lower shelf
        for x in [-hw + 0.04, hw - 0.04] { for z in [-hd + 0.04, hd - 0.04] {
            box(V3(x, 0.05 + (T - 0.09) / 2, z), V3(0.05, T - 0.09 - 0.05, 0.05), frame)
            m.add(Prim.cylinder(radius: 0.012, height: 0.05, bevel: 0.002, segments: 8, material: steel), Xform(translation: V3(x, 0.012, z)))
            m.add(Prim.cylinder(radius: 0.035, height: 0.014, bevel: 0.003, segments: segs, material: "rubber"), Xform(translation: V3(x, 0, z)))
        }}
        for z in [-hd + 0.04, hd - 0.04] { box(V3(0, 0.2, z), V3(width - 0.06, 0.04, 0.03), frame) }
        box(V3(0, 0.23, 0), V3(width - 0.1, 0.02, depth - 0.04), frame)
        // top: steel sheet, ESD mat inset, front lip
        box(V3(0, T - 0.03, 0), V3(width, 0.04, depth), frame, 0.006)
        box(V3(0.05, T - 0.006, 0.01), V3(width - 0.2, 0.004, depth - 0.12), mat, 0.0015)
        // drawer unit under the right end
        let dx = hw - 0.3
        box(V3(dx, T - 0.05 - 0.2, 0), V3(0.5, 0.4, depth - 0.06), frame)
        for i in 0..<3 {
            let y = T - 0.1 - Float(i) * 0.125
            box(V3(dx, y, hd - 0.03 + 0.006), V3(0.47, 0.11, 0.012), frame, 0.003)
            m.add(barHandle(length: 0.14, standoff: 0.025, radius: 0.006, material: steel), Xform(translation: V3(dx, y + 0.02, hd - 0.03 + 0.012)))
            box(V3(dx - 0.17, y + 0.02, hd - 0.02), V3(0.06, 0.025, 0.002), "paper.sheet", 0.0005)
        }
        // pegboard riser on posts, shelf, LED bar
        for x in [-hw + 0.03, hw - 0.03] { box(V3(x, T + riserHeight / 2, -hd + 0.03), V3(0.04, riserHeight, 0.04), frame) }
        box(V3(0, T + riserHeight * 0.45, -hd + 0.03), V3(width - 0.08, riserHeight * 0.75, 0.006), peg, 0.001)
        box(V3(0, T + riserHeight - 0.02, -hd + 0.15), V3(width, 0.02, 0.26), frame)
        box(V3(0, T + riserHeight - 0.045, -hd + 0.22), V3(width - 0.3, 0.03, 0.06), "metal.aluminum-brushed")
        box(V3(0, T + riserHeight - 0.062, -hd + 0.22), V3(width - 0.34, 0.006, 0.04), "emissive.panel", 0.001)
        // pegboard hooks with two hanging cables
        if detail {
            for (i, x) in [Float(-0.6), -0.35, 0.3].enumerated() {
                let y = T + 0.55
                m.add(Prim.tube([V3(x, y, -hd + 0.035), V3(x, y, -hd + 0.11), V3(x, y + 0.03, -hd + 0.13)], radii: [0.003, 0.003, 0.003],
                                sides: 5, seamTile: 0.1, material: steel), .identity)
                if i < 2 {
                    m.add(Prim.torus(major: 0.07, minor: 0.006, segments: 18, sides: 5, material: i == 0 ? "rubber.insulating-red" : "rubber"),
                          Xform(translation: V3(x, y - 0.07, -hd + 0.1), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
                }
            }
        }
        // avionics box with connectors on the mat, ground cord to the mat snap
        let ab = V3(-0.35, T, 0.05)
        box(ab + V3(0, 0.07, 0), V3(0.34, 0.14, 0.24), "metal.anodized-black", 0.006)
        for k in 0..<3 {
            m.add(Prim.cylinder(radius: 0.017, height: 0.02, bevel: 0.002, segments: 12, material: "metal.aluminum-brushed"),
                  Xform(translation: ab + V3(-0.1 + Float(k) * 0.1, 0.07, 0.12), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }
        box(ab + V3(0.1, 0.143, -0.05), V3(0.08, 0.004, 0.05), "label.biomed", 0.0005)
        if detail {
            let cord = catmull([ab + V3(0.17, 0.03, 0), ab + V3(0.3, 0.004, 0.05), ab + V3(0.45, 0.004, -0.15), V3(-hw + 0.35, T, -hd + 0.1)], per: 6)
            m.add(Prim.tube(cord, radii: Array(repeating: 0.004, count: cord.count), sides: 5, seamTile: 0.1, material: "plastic.matte:2C5E2C"), .identity)
        }
        // bench vise at the left end
        let vx = -hw + 0.18
        box(V3(vx, T + 0.03, hd - 0.12), V3(0.16, 0.06, 0.2), "metal.painted:3C5A7A", 0.01)
        box(V3(vx, T + 0.11, hd - 0.08), V3(0.16, 0.1, 0.05), "metal.painted:3C5A7A", 0.008)
        box(V3(vx, T + 0.11, hd - 0.16), V3(0.16, 0.1, 0.05), "metal.painted:3C5A7A", 0.008)
        m.add(Prim.tube([V3(vx, T + 0.09, hd - 0.05), V3(vx, T + 0.09, hd + 0.08)], radii: [0.008, 0.008], sides: 8, seamTile: 0.1, material: steel), .identity)
        m.add(Prim.tube([V3(vx - 0.1, T + 0.09, hd + 0.08), V3(vx + 0.1, T + 0.09, hd + 0.08)], radii: [0.006, 0.006], sides: 8, seamTile: 0.1, material: steel), .identity)
        // wire spool and torque wrench
        let sp = V3(0.25, T, -0.12)
        m.add(Prim.cylinder(radius: 0.07, height: 0.008, bevel: 0.002, segments: segs, material: "plastic.black"), Xform(translation: sp))
        m.add(Prim.cylinder(radius: 0.05, height: 0.06, bevel: 0.002, segments: segs, material: "rubber.insulating-orange"), Xform(translation: sp + V3(0, 0.008, 0)))
        m.add(Prim.cylinder(radius: 0.07, height: 0.008, bevel: 0.002, segments: segs, material: "plastic.black"), Xform(translation: sp + V3(0, 0.068, 0)))
        let wr = V3(0.1, T + 0.012, 0.22), ang = rng.float(-0.3...0.3)
        m.add(Prim.tube([wr, wr + V3(cos(ang), 0, sin(ang)) * 0.42], radii: [0.011, 0.009], sides: 8, seamTile: 0.1, material: "metal.chrome"), .identity)
        m.add(Prim.cylinder(radius: 0.02, height: 0.025, bevel: 0.003, segments: 12, material: "metal.chrome"), Xform(translation: wr - V3(0, 0.012, 0)))
        groundAO(&m)
        return m
    }
}
