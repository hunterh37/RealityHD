import simd
import Foundation

/// Hexagonal split cane fly rod blank, 2.1 m (7 ft, two-piece), lying on a flat with the guides up:
/// six flamed Tonkin strips glued into a tapered hex, staggered node marks on the flats, nickel silver
/// ferrule at the middle, red-brown silk wraps, snake guides, agate-style stripper and tip-top.
/// Anchors: `butt` (-X), `tipTop` (line exit).
public struct RodBlankBamboo: RealAsset, RealAnchored {
    public static let id = "rod-blank-bamboo"
    public static let summary = "Hexagonal split cane blank 2.1 m with node marks, ferrule, snake guides and tip-top."
    public static let tags = ["prop", "fishing", "handheld", "tool", "wood"]
    public static let budget = 10600
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 24, distance: 0.5, studio: true)

    /// Blank length (m).
    public var length: Float = 2.1
    /// Across-flats radius at the butt and tip (m).
    public var buttRadius: Float = 0.0052
    public var tipRadius: Float = 0.0011
    /// Cane material key.
    public var caneMaterial: MaterialKey = "wood.bamboo-cane"
    /// Silk wrap key.
    public var wrapMaterial: MaterialKey = "thread.wrap-epoxy:6A1E14"
    /// Ferrule metal key (nickel silver).
    public var ferruleMaterial: MaterialKey = "metal.brushed-nickel"
    /// Length hidden in the handle.
    public var insertDepth: Float = 0.3
    public init() {}

    var y: Float { buttRadius }
    public static var anchors: [String: RealAnchor] {
        let a = Self()
        return ["butt": RealAnchor(V3(-a.length / 2, a.y, 0), direction: V3(-1, 0, 0)),
                "tipTop": RealAnchor(V3(a.length / 2 - 0.002, a.y + a.tipRadius + 0.0005 + 0.0016 + 0.00084, 0), direction: V3(1, 0, 0))]
    }

    /// Hexagon (flat on the bottom) with tiny corner chamfers so the facets catch light.
    static func hex(_ r: Float) -> [V2] {
        var pts: [V2] = []
        let R = r / cos(.pi / 6)
        for k in 0..<6 {
            let a = Float(k) * .pi / 3
            let c = V2(cos(a), sin(a)) * R
            let prev = V2(cos(a - .pi / 3), sin(a - .pi / 3)) * R, next = V2(cos(a + .pi / 3), sin(a + .pi / 3)) * R
            pts.append(c + (prev - c) * 0.12); pts.append(c + (next - c) * 0.12)
        }
        return pts
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let x0 = -length / 2, x1 = length / 2, exposed = x0 + insertDepth
        func r(_ x: Float) -> Float { RodKit.blankRadius(x, x0: x0, x1: x1, r0: buttRadius, r1: tipRadius) }
        // Hex blank: sweep a unit hexagon along the axis with a taper. Profile x follows `up` (+Y), so rotate the
        // hexagon a sixth to land a flat on the ground.
        let n = 40
        let path = (0...n).map { V3(x0 + length * Float($0) / Float(n), y, 0) }
        let scales = path.map { r($0.x) / buttRadius }
        m.add(Prim.sweep(Self.hex(buttRadius).map { V2($0.y, $0.x) }, along: path, up: V3(0, 1, 0), scales: scales, grainAlongPath: true, material: caneMaterial))
        // Node marks: slightly raised darker ridges, staggered around the six strips every ~38 cm.
        var x = x0 + 0.12
        var k = 0
        while x < x1 - 0.12 {
            for strip in 0..<2 {
                let a = Float((k + strip * 3) % 6) * .pi / 3
                let rr = r(x) * 0.985
                let p = V3(x + Float(strip) * 0.05, y + cos(a) * rr, sin(a) * rr)
                let node = Prim.superellipsoid(V3(0.006, 0.0007, rr * 0.9), exponent: 3, subdivisions: 3, material: "wood.bamboo-cane:7A5028")
                m.add(node, Xform(translation: p, rotation: simd_quatf(from: V3(0, 1, 0), to: simd_normalize(V3(0, cos(a), sin(a))))))
            }
            x += rng.float(0.34...0.42); k += 1
        }
        let set = RodAssembly.blankSet(x0: x0, x1: x1, exposed: exposed, r0: buttRadius * 1.05, r1: tipRadius * 1.1, y: y, guides: RodAssembly.flyGuides,
                                       blankMat: caneMaterial, wrapMat: wrapMaterial, trimMat: "thread.wrap-epoxy:C9A24A", frame: "metal.chrome",
                                       insert: "ceramic.guide-insert")
        // Guides, tip-top and wraps from the shared set (its round blank is replaced by the hex sweep).
        // Story: one guide was rewrapped during a restoration in green silk that never matched the red.
        let rewrap = exposed + (x1 - exposed) * RodAssembly.flyGuides[5].t
        for var s in set.blank.dropFirst() + set.guides + set.tip {
            let b = s.bounds
            if s.material == wrapMaterial && abs((b.min.x + b.max.x) / 2 - rewrap) < 0.02 { s.material = "thread.wrap-epoxy:2E4A26" }
            m.add(s)
        }
        // Nickel silver ferrule: male slide into the female socket, wrapped at the female end.
        let fx: Float = 0
        let fr = r(fx) * 1.12
        m.add(RodKit.lathe([V2(fr * 0.95, 0), V2(fr + 0.0004, 0.0015), V2(fr + 0.0005, 0.055), V2(fr + 0.0012, 0.057), V2(fr + 0.0012, 0.062), V2(fr * 0.97, 0.0635)],
                           x0: fx - 0.06, y: y, seg: 20, tile: 0.02, ferruleMaterial))
        m.add(RodKit.wrap(x: fx - 0.078, len: 0.02, r: r(fx - 0.07), y: y, mat: wrapMaterial))
        groundAO(&m, height: 0.015, floor: 0.6)
        return LODModel(m)
    }
}
