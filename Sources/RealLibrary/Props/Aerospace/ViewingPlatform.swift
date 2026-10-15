import simd
import Foundation

/// Spectator viewing platform, 6 x 4 m deck at 2.4 m: galvanized columns with knee braces on concrete
/// pads, grated deck, a straight stair with treads and stringers, yellow handrails with mesh infill,
/// a canvas sunshade on a steel frame and a coin-style viewing scope at the front rail (+X).
public struct ViewingPlatform: RealAsset {
    public static let id = "viewing-platform"
    public static let summary = "Spectator viewing platform, 6 x 4 m deck at 2.4 m: galvanized frame, grated deck, stair, mesh-infill handrails, canvas sunshade and a viewing scope."
    public static let tags = ["prop", "aerospace", "outdoor", "metal", "furniture"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 14, distance: 1.05)

    /// Deck size (x toward the pad, z) and height in meters.
    public var deckX: Float = 4
    public var deckZ: Float = 6
    public var deckHeight: Float = 2.4
    public var steel: MaterialKey = "metal.galvanized"
    public var rail: MaterialKey = "metal.signal-yellow"
    public var grate: MaterialKey = "metal.galvanized-aged"
    public var mesh: MaterialKey = "fence.chainlink"
    public var canvas: MaterialKey = "fabric.canvas:C9B98F"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(seed: seed, detail: true), level(seed: seed, detail: false)], switchDistances: [50])
    }

    func level(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hx = deckX / 2, hz = deckZ / 2, H = deckHeight
        let sides = detail ? 8 : 5
        func rod(_ a: V3, _ b: V3, _ r: Float, _ mat: MaterialKey? = nil) {
            m.add(Prim.tube([a, b], radii: [r, r], sides: sides, seamTile: 0.3, material: mat ?? steel), .identity)
        }
        func box(_ c: V3, _ s: V3, _ mat: MaterialKey, _ r: Float = 0.01) {
            m.add(Prim.roundedBox(s, radius: r, bevelSegments: 1, material: mat), Xform(translation: c))
        }
        // columns on pads, knee braces, deck beams
        let cols: [V2] = [V2(-hx + 0.15, -hz + 0.15), V2(hx - 0.15, -hz + 0.15), V2(hx - 0.15, hz - 0.15), V2(-hx + 0.15, hz - 0.15),
                          V2(-hx + 0.15, 0), V2(hx - 0.15, 0)]
        for c in cols {
            box(V3(c.x, 0.1, c.y), V3(0.5, 0.2, 0.5), "concrete.rough", 0.02)
            box(V3(c.x, 0.2 + (H - 0.2 - 0.15) / 2, c.y), V3(0.12, H - 0.2 - 0.15, 0.12), steel, 0.008)
            if detail { for (dx, dz) in [(-0.14, -0.14), (0.14, 0.14)] as [(Float, Float)] {
                hexBolt(&m, at: V3(c.x + dx, 0.21, c.y + dz), normal: V3(0, 1, 0), size: 0.024, material: steel)
            }}
        }
        for z in [-hz + 0.15, hz - 0.15, Float(0)] {
            rod(V3(-hx + 0.15, H - 0.9, z), V3(-hx + 0.15, H - 0.2, z + (z == 0 ? 0.6 : (z < 0 ? 0.6 : -0.6))), 0.035)
            rod(V3(hx - 0.15, H - 0.9, z), V3(hx - 0.15, H - 0.2, z + (z == 0 ? -0.6 : (z < 0 ? 0.6 : -0.6))), 0.035)
        }
        for x in [-hx + 0.15, hx - 0.15] { box(V3(x, H - 0.25, 0), V3(0.12, 0.2, deckZ), steel, 0.008) }
        for z in [-hz + 0.15, Float(0), hz - 0.15] { box(V3(0, H - 0.25, z), V3(deckX, 0.18, 0.1), steel, 0.008) }
        // grated deck with toe boards
        box(V3(0, H - 0.12, 0), V3(deckX + 0.1, 0.05, deckZ + 0.1), grate, 0.006)
        // stair down the -Z end along -X... runs from deck edge at z = -hz toward -z
        let rise = H - 0.1, run = rise / 0.75, steps = Int(rise / 0.18)
        let sx0: Float = -hx + 0.3, sx1: Float = -hx + 1.3
        for x in [sx0, sx1] {
            rod(V3(x, 0.05, -hz - run), V3(x, H - 0.15, -hz), 0.045)
            rod(V3(x, 0.95, -hz - run), V3(x, H + 0.9, -hz), 0.022, rail)
        }
        for i in 0..<steps {
            let t = (Float(i) + 0.5) / Float(steps)
            box(V3((sx0 + sx1) / 2, 0.05 + t * (H - 0.2), -hz - run * (1 - t)), V3(sx1 - sx0 - 0.04, 0.035, 0.26), grate, 0.004)
        }
        // handrails on three sides plus the stair-free part of -Z, mesh infill panels
        let railH: Float = 1.05
        let runs: [(V3, V3)] = [(V3(hx, 0, -hz), V3(hx, 0, hz)), (V3(-hx, 0, hz), V3(hx, 0, hz)),
                                (V3(-hx, 0, -hz), V3(-hx, 0, hz)), (V3(sx1 + 0.05, 0, -hz), V3(hx, 0, -hz))]
        for (a, b) in runs {
            let ya = V3(0, H - 0.1, 0)
            rod(a + ya + V3(0, railH, 0), b + ya + V3(0, railH, 0), 0.025, rail)
            rod(a + ya + V3(0, 0.5, 0), b + ya + V3(0, 0.5, 0), 0.018, rail)
            let len = simd_length(b - a), n = max(1, Int(len / 1.5))
            for k in 0...n {
                let p = a + (b - a) * (Float(k) / Float(n))
                rod(p + ya, p + ya + V3(0, railH, 0), 0.022, rail)
            }
            let mid = (a + b) / 2 + ya + V3(0, 0.5, 0)
            let alongX = abs(b.x - a.x) > abs(b.z - a.z)
            box(mid, alongX ? V3(len - 0.06, 0.88, 0.006) : V3(0.006, 0.88, len - 0.06), mesh, 0.002)
        }
        // sunshade: four posts at the rear half, sloped canvas on a frame
        let sh0: Float = -hx + 0.15, sh1: Float = 0.3
        for x in [sh0, sh1] { for z in [-hz + 0.15, hz - 0.15] {
            rod(V3(x, H - 0.1, z), V3(x, H + (x == sh0 ? 2.5 : 2.3), z), 0.04)
        }}
        // shade frame: purlins under the canvas
        for z in [-hz + 0.15, Float(0), hz - 0.15] {
            rod(V3(sh0 - 0.25, H + 2.5, z), V3(sh1 + 0.25, H + 2.3 + 0.0, z), 0.035)
        }
        var shade = Prim.roundedBox(V3(sh1 - sh0 + 0.5, 0.02, deckZ - 0.1), radius: 0.008, bevelSegments: 1, material: canvas)
        shade.displace { p, n in -0.06 * abs(sin(p.z * .pi / (hz - 0.15))) }
        m.add(shade, Xform(translation: V3((sh0 + sh1) / 2, H + 2.44, 0), rotation: simd_quatf(degrees: -4.5, axis: V3(0, 0, 1))))
        // viewing scope at the front rail, aimed at the pad
        let sp = V3(hx - 0.45, H - 0.1, rng.float(-0.4...0.4))
        rod(sp, sp + V3(0, 1.0, 0), 0.05, "metal.painted:2E5E8C")
        m.add(Prim.roundedBox(V3(0.42, 0.24, 0.26), radius: 0.06, bevelSegments: 2, material: "metal.painted:2E5E8C"),
              Xform(translation: sp + V3(0.05, 1.13, 0), rotation: simd_quatf(degrees: 6, axis: V3(0, 0, 1))))
        for dz in [Float(-0.07), 0.07] {
            m.add(Prim.cylinder(radius: 0.035, height: 0.1, bevel: 0.005, segments: 12, material: "rubber"),
                  Xform(translation: sp + V3(-0.16, 1.15, dz), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        }
        groundAO(&m)
        // centre deck plus stair run on the origin
        var c = Model(name: Self.id)
        c.add(m, Xform(translation: V3(0, 0, (H - 0.1) / 0.75 / 2)))
        return c
    }
}
