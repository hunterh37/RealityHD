import simd
import Foundation

/// Course pylon: radius 0.3 to 3 m, height 3 to 150 m. Up to 20 m a banded orange and white painted cone
/// on a rubber ballast skirt; above 20 m a triangular lattice tower painted in seven aviation bands.
/// Both carry a red obstruction light on the top cap.
public struct Pylon: RealAsset {
    public static let id = "pylon"
    public static let summary = "Course pylon, radius 0.3-3 m, height 3-150 m: banded painted cone on a rubber skirt with red light; lattice tower above 20 m."
    public static let tags = ["prop", "aerospace", "outdoor", "barrier", "metal"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 14, distance: 1.2)

    /// Base radius in meters (0.3 to 3).
    public var radius: Float = 0.3
    /// Overall height in meters (3 to 150). Above `latticeAbove` the pylon is a lattice tower.
    public var height: Float = 3
    public var latticeAbove: Float = 20
    /// Band colours.
    public var orange: MaterialKey = "metal.painted:E2561B"
    public var white: MaterialKey = "metal.painted:E6E2D8"
    public var skirt: MaterialKey = "rubber"
    public var light: MaterialKey = "emissive.signal-red"
    public var hardware: MaterialKey = "metal.galvanized"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let r = min(max(radius, 0.3), 3), h = min(max(height, 3), 150)
        if h > latticeAbove {
            return LODModel(levels: [lattice(r: r, h: h, sides: 5, braces: true), lattice(r: r, h: h, sides: 4, braces: false)],
                            switchDistances: [h * 1.5])
        }
        return LODModel(levels: [cone(seed: seed, r: r, h: h, segs: 32), cone(seed: seed, r: r, h: h, segs: 14)],
                        switchDistances: [max(15, h * 6)])
    }

    func cone(seed: UInt64, r: Float, h: Float, segs: Int) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let skirtH = r * 0.22, top = h - r * 0.28
        // rubber ballast skirt: a low flared ring with a rolled lip
        m.add(Prim.lathe([V2(0, 0), V2(r * 1.55, 0), V2(r * 1.6, skirtH * 0.25), V2(r * 1.5, skirtH * 0.45),
                          V2(r * 1.1, skirtH * 0.7), V2(r * 1.02, skirtH), V2(0, skirtH)],
                         segments: segs, seamTile: 0.5, material: skirt), .identity)
        // banded cone shell, radius tapering linearly to 0.22 r below the cap
        func rad(_ y: Float) -> Float { r - (r - r * 0.22) * (y - skirtH) / (top - skirtH) }
        let bands = 6
        for i in 0..<bands {
            let y0 = skirtH + (top - skirtH) * Float(i) / Float(bands)
            let y1 = skirtH + (top - skirtH) * Float(i + 1) / Float(bands)
            var prof: [V2] = []
            for k in 0...4 { let y = y0 + (y1 - y0) * Float(k) / 4; prof.append(V2(rad(y), y)) }
            m.add(Prim.lathe(prof, segments: segs, seamTile: 0.5, material: i % 2 == 0 ? orange : white), .identity)
        }
        // band seams: thin rolled beads where the shell sections overlap
        for i in 0...bands {
            let y = skirtH + (top - skirtH) * Float(i) / Float(bands)
            m.add(Prim.torus(major: rad(y) + 0.002, minor: r * 0.012, segments: segs, sides: 5, material: i == 0 ? hardware : white),
                  Xform(translation: V3(0, y, 0)))
        }
        // top cap and obstruction light
        let capR = r * 0.24
        m.add(Prim.cylinder(radius: capR, height: r * 0.1, bevel: capR * 0.1, segments: segs, material: hardware),
              Xform(translation: V3(0, top, 0)))
        m.add(Prim.lathe([V2(capR * 0.7, 0), V2(capR * 0.72, r * 0.08), V2(capR * 0.55, r * 0.15), V2(0, r * 0.18)],
                         segments: segs, seamTile: 0.2, material: light), Xform(translation: V3(0, top + r * 0.1, 0)))
        // skirt bolts and a lifting handle slot: the story is a pylon dragged into place
        if segs > 20 {
            for k in 0..<8 {
                let a = Float(k) / 8 * 2 * .pi + rng.float(-0.04...0.04)
                hexBolt(&m, at: V3(cos(a) * r * 1.22, skirtH * 0.62, sin(a) * r * 1.22),
                        normal: simd_normalize(V3(cos(a) * 0.5, 1, sin(a) * 0.5)), size: r * 0.07, material: hardware)
            }
            // scuff: a dented, dirt-streaked lower band patch
            m.add(Prim.lathe([V2(rad(skirtH + 0.02) + 0.003, skirtH + 0.02), V2(rad(skirtH + r * 0.5) + 0.003, skirtH + r * 0.5)],
                             segments: 6, seamTile: 0.5, material: "metal.rust"),
                  Xform(rotation: simd_quatf(angle: rng.float(0...6), axis: V3(0, 1, 0)), scale: V3(1, 1, 1)))
        }
        groundAO(&m)
        return m
    }

    func lattice(r: Float, h: Float, sides: Int, braces: Bool) -> Model {
        var m = Model(name: Self.id)
        let legR = max(0.03, r * 0.045), braceR = max(0.015, r * 0.022)
        let sections = max(6, Int(h / max(2.5, r * 2.2)))
        let bandOf: (Float) -> MaterialKey = { y in Int(y / h * 7).clamped(0, 6) % 2 == 0 ? self.orange : self.white }
        func corner(_ k: Int, _ y: Float) -> V3 {
            let a = Float(k) / 3 * 2 * .pi + .pi / 2
            let rr = r * (1 - 0.35 * y / h)
            return V3(cos(a) * rr, y, sin(a) * rr)
        }
        let topY = h - r * 0.25
        for s in 0..<sections {
            let y0 = topY * Float(s) / Float(sections), y1 = topY * Float(s + 1) / Float(sections)
            let mat = bandOf((y0 + y1) / 2)
            for k in 0..<3 {
                m.add(Prim.tube([corner(k, y0), corner(k, y1)], radii: [legR, legR], sides: sides, seamTile: 0.5, material: mat), .identity)
                m.add(Prim.tube([corner(k, y1), corner((k + 1) % 3, y1)], radii: [braceR, braceR], sides: sides, seamTile: 0.5,
                                material: mat), .identity)
                if braces {
                    // zigzag web: diagonal direction alternates per section
                    let a = s % 2 == 0 ? corner(k, y0) : corner((k + 1) % 3, y0)
                    let b = s % 2 == 0 ? corner((k + 1) % 3, y1) : corner(k, y1)
                    m.add(Prim.tube([a, b], radii: [braceR * 0.8, braceR * 0.8], sides: max(4, sides - 2), seamTile: 0.5, material: mat), .identity)
                }
            }
        }
        // concrete pier feet and the top cap with obstruction light
        for k in 0..<3 {
            let p = corner(k, 0)
            m.add(Prim.roundedBox(V3(legR * 8, 0.5, legR * 8), radius: 0.03, bevelSegments: 2, material: "concrete.rough"),
                  Xform(translation: V3(p.x, 0.0, p.z)))
        }
        let capR = r * 0.7
        m.add(Prim.cylinder(radius: capR, height: r * 0.1, bevel: 0.01, segments: 12, material: hardware), Xform(translation: V3(0, topY, 0)))
        m.add(Prim.lathe([V2(r * 0.14, 0), V2(r * 0.15, r * 0.08), V2(r * 0.1, r * 0.14), V2(0, r * 0.15)],
                         segments: 12, seamTile: 0.2, material: light), Xform(translation: V3(0, topY + r * 0.1, 0)))
        groundAO(&m)
        return m
    }
}

private extension Int {
    func clamped(_ a: Int, _ b: Int) -> Int { Swift.min(Swift.max(self, a), b) }
}
