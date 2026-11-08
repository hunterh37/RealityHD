import simd
import Foundation

/// Pair of blank white canvas low-top sneakers, 28 cm each: a rounded rubber sole and midsole, a lofted
/// canvas upper with a toe cap, heel counter, tongue, collar, five laces with metal eyelets, a tonal side
/// panel and a heel tab. No brand marks. Toes +Z, pair centered on X/Z, base at y = 0.
public struct SneakerPair: RealAsset {
    public static let id = "sneaker-pair"
    public static let summary = "Pair of blank white canvas low-top sneakers, 28 cm: rubber sole, lofted upper, toe cap, tongue, five laces, eyelets, heel tab."
    public static let tags = ["prop", "fashion", "apparel", "handheld", "footwear"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 24, distance: 0.68, studio: true)

    /// Shoe length, width and upper height (m).
    public var length: Float = 0.278
    public var width: Float = 0.098
    public var upperHeight: Float = 0.098
    /// Material keys.
    public var canvas: MaterialKey = "fabric.canvas:EDEAE2"
    public var canvasPanel: MaterialKey = "fabric.canvas:E2DED2"
    public var sole: MaterialKey = "rubber"
    public var midsole: MaterialKey = "rubber"
    public var toeCap: MaterialKey = "rubber"
    public var lace: MaterialKey = "fabric.canvas:F7F5EE"
    public var eyelet: MaterialKey = "metal.chrome:9AA5A8"
    public var insole: MaterialKey = "fabric.canvas:8A857A"
    public var stitch: MaterialKey = "fabric.canvas:D6D1C6"
    public init() {}

    /// Foot outline in the XZ plane at height `y`, scaled about the centre. Toe at +Z (a = -pi/2).
    private func footRing(_ n: Int, y: Float, scale: Float, zShift: Float = 0) -> [V3] {
        (0..<n).map { k in
            let a = Float(k) / Float(n) * 2 * .pi
            let toe = 0.5 - 0.5 * sin(a)                     // 1 at +Z
            let w = width * 0.5 * (0.80 + 0.20 * toe) * scale
            let l = length * 0.5 * scale
            return V3(cos(a) * w, y, -sin(a) * l + zShift)
        }
    }

    private func shoe(_ rng: inout SeededRNG) -> Model {
        var m = Model(name: Self.id)
        let n = 56
        let L = length, W = width, H = upperHeight

        // Sole and midsole: three loft rings each, rounded rims.
        let soleRings = [footRing(n, y: 0.000, scale: 0.93), footRing(n, y: 0.008, scale: 0.99),
                         footRing(n, y: 0.016, scale: 1.00), footRing(n, y: 0.021, scale: 0.97)]
        m.add(Prim.loft(soleRings, capStart: true, capEnd: false, material: sole))
        let midRings = [footRing(n, y: 0.021, scale: 0.97), footRing(n, y: 0.028, scale: 1.01),
                        footRing(n, y: 0.034, scale: 0.99)]
        m.add(Prim.loft(midRings, capStart: false, capEnd: true, material: midsole))

        // Upper: a dome that slopes down at the toe and rises at the heel.
        let upperRings = [footRing(n, y: 0.034, scale: 0.985), footRing(n, y: 0.050, scale: 0.95),
                          footRing(n, y: 0.068, scale: 0.88), footRing(n, y: 0.084, scale: 0.78),
                          footRing(n, y: 0.094, scale: 0.62)]
        var upper = Prim.loft(upperRings, capStart: false, capEnd: true, material: canvas)
        upper.deform { p in
            let toe = clamp01((p.z - 0.010) / 0.120)
            let heel = clamp01((-0.020 - p.z) / 0.110)
            let ease = toe * toe * (3 - 2 * toe)
            return V3(p.x, p.y - 0.030 * ease + 0.010 * heel, p.z)
        }
        m.add(upper)

        // Toe cap and heel counter, both slightly proud of the upper.
        m.add(Prim.superellipsoid(V3(W * 0.92, 0.042, 0.082), exponent: 3.0, subdivisions: 4, material: toeCap),
              Xform(translation: V3(0, 0.046, L * 0.33)))
        m.add(Prim.superellipsoid(V3(W * 0.88, 0.058, 0.050), exponent: 3.2, subdivisions: 4, material: canvasPanel),
              Xform(translation: V3(0, 0.064, -L * 0.40)))

        // Tongue and collar.
        m.add(Prim.roundedBox(V3(W * 0.52, 0.010, 0.078), radius: 0.004, bevelSegments: 2, material: canvas),
              Xform(translation: V3(0, 0.092, 0.016), rotation: simd_quatf(angle: -0.22, axis: V3(1, 0, 0))))
        m.add(Prim.torus(major: 0.040, minor: 0.0060, segments: 40, sides: 10, material: canvas),
              Xform(translation: V3(0, 0.094, -0.030), scale: V3(1.0, 1.0, 1.34)))
        m.add(Prim.torus(major: 0.036, minor: 0.0022, segments: 40, sides: 8, material: insole),
              Xform(translation: V3(0, 0.092, -0.030), scale: V3(1.0, 1.0, 1.32)))
        m.add(Prim.superellipsoid(V3(W * 0.80, 0.006, 0.190), exponent: 3.2, subdivisions: 3, material: insole),
              Xform(translation: V3(0, 0.086, -0.010)))

        // Tonal side panels (blank, no logo).
        for sx: Float in [-1, 1] {
            m.add(Prim.superellipsoid(V3(0.004, 0.032, 0.078), exponent: 3.0, subdivisions: 3, material: canvasPanel),
                  Xform(translation: V3(sx * W * 0.455, 0.060, -0.012),
                        rotation: simd_quatf(angle: sx * 0.08, axis: V3(0, 0, 1))))
        }

        // Laces: five arcs across the instep, with eyelets.
        for i in 0..<5 {
            let z = 0.002 + Float(i) * 0.013
            let y = 0.093 + 0.003 * sin(Float(i) / 4 * .pi)
            let pts: [V3] = (0...8).map { j in
                let t = Float(j) / 8
                let x = -W * 0.34 + W * 0.68 * t
                return V3(x, y + 0.006 * sin(t * .pi), z + 0.002 * sin(t * .pi))
            }
            m.add(Prim.tube(pts, radii: pts.map { _ in 0.0017 }, sides: 4, seamTile: 0.01, material: lace))
            for sx: Float in [-1, 1] {
                m.add(Prim.torus(major: 0.0032, minor: 0.0011, segments: 10, sides: 6, material: eyelet),
                      Xform(translation: V3(sx * W * 0.33, y - 0.002, z + 0.001),
                            rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
            }
        }

        // Heel tab.
        m.add(Prim.roundedBox(V3(0.020, 0.020, 0.007), radius: 0.003, bevelSegments: 2, material: canvasPanel),
              Xform(translation: V3(0, 0.100, -L * 0.445), rotation: simd_quatf(angle: 0.10, axis: V3(1, 0, 0))))

        // Stitched seam around the sole/upper join.
        let seamPath: [V3] = (0..<n).map { k in
            let a = Float(k) / Float(n) * 2 * .pi
            let toe = 0.5 - 0.5 * sin(a)
            let w = W * 0.5 * (0.80 + 0.20 * toe) * 1.006
            let l = L * 0.5 * 1.006
            return V3(cos(a) * w, 0.036, -sin(a) * l)
        }
        m.add(Prim.sweep(Shape2D.circle(0.0009, segments: 5), along: seamPath, up: .up,
                         closedPath: true, caps: false, material: stitch))

        // Outsole grooves.
        for i in 0..<4 {
            let z = -0.075 + Float(i) * 0.050
            m.add(Prim.roundedBox(V3(W * 0.62, 0.0016, 0.0030), radius: 0.0006, bevelSegments: 1, material: insole),
                  Xform(translation: V3(0, 0.0008, z)))
        }

        // Small per-shoe variation.
        m = m.transformed(Xform(scale: V3(rng.vary(1, 0.012), 1, rng.vary(1, 0.008))))
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let gap = width * 0.62
        let left = shoe(&rng).transformed(Xform(translation: V3(-gap, 0, 0.006),
                                                rotation: simd_quatf(angle: 0.10, axis: V3(0, 1, 0))))
        let right = shoe(&rng).transformed(Xform(translation: V3(gap, 0, -0.004),
                                                 rotation: simd_quatf(angle: -0.07, axis: V3(0, 1, 0))))
        m.add(left)
        m.add(right)
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2)))
        groundAO(&m, height: 0.012, floor: 0.4)
        return LODModel(m)
    }
}

private func clamp01(_ x: Float) -> Float { max(0, min(1, x)) }
