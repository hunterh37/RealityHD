import simd
import Foundation

/// Spiral staircase, 1.6 m diameter, 3.0 m rise: a steel center pole with sleeve spacers carries 15 oak wedge
/// treads (26 degrees apart, 187.5 mm risers) and an oak landing sector at the upper floor. Round steel balusters,
/// two per tread, rise to a helical oak handrail 0.9 m above the nosing line. Pole, spacers and balusters are black
/// powder coat. Origin at the pole axis, base at y = 0.
public struct SpiralStaircase: RealAsset {
    public static let id = "spiral-staircase"
    public static let summary = "Spiral staircase, 1.6 m diameter, 3.0 m rise: steel center pole with spacers, 15 oak wedge treads, landing, steel balusters, helical oak handrail."
    public static let tags = ["structure", "floorplan", "interior", "stair", "metal", "wood"]
    public static let budget = 12_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 18, distance: 1.2, studio: true)

    /// Outer radius of the treads (m).
    public var radius: Float = 0.8
    /// Number of treads below the landing; rise per riser is 3.0 / (treads + 1).
    public var treads = 15
    /// Angle between treads (degrees).
    public var stepDegrees: Float = 26
    /// Handrail height above the nosing line (m).
    public var railHeight: Float = 0.9
    public var steel: MaterialKey = "metal.powdercoat:2B2B2E"
    public var treadMaterials: [MaterialKey] = ["wood.oak:BE9A68", "wood.oak:A98458", "wood.oak:C9A674", "wood.oak:B08C5E"]
    public var railMaterial: MaterialKey = "wood.oak:8F643A"
    public init() {}

    func model(lod: Int, seed: UInt64) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let n = treads
        let R: Float = 3.0 / Float(n + 1)
        let step = stepDegrees * .pi / 180
        let treadT: Float = 0.04
        let ri: Float = 0.07, ro = radius
        let poleR: Float = 0.06, sleeveR: Float = 0.072
        let arcN = lod == 0 ? 6 : 3

        // Wedge outline in plan, centered on +X, with a few degrees of overlap onto the next tread.
        func wedge(_ span: Float, outer: Float, rounded: Bool = true) -> [V2] {
            var pts: [V2] = []
            for k in 0...arcN { let t = span / 2 - span * Float(k) / Float(arcN); pts.append(V2(outer * cosf(t), outer * sinf(t))) }
            pts.append(V2(ri * cosf(-span / 2), ri * sinf(-span / 2)))
            pts.append(V2(ri * cosf(span / 2), ri * sinf(span / 2)))
            return rounded ? Shape2D.rounded(pts, radius: 0.012, segments: 1) : pts
        }
        let span = step + 4 * .pi / 180
        let outline = wedge(span, outer: ro)
        func place(_ i: Float, y: Float) -> Xform {
            Xform(translation: V3(0, y, 0), rotation: simd_quatf(angle: -i * step, axis: .up) * simd_quatf(degrees: 90, axis: V3(1, 0, 0)))
        }
        for i in 1...n {
            let mat = treadMaterials[(i * 3) % treadMaterials.count]
            let s = Prim.extrude(outline, depth: treadT, bevel: 0.008, bevelSegments: 1, material: mat)
            m.add(s, place(Float(i), y: Float(i) * R - treadT / 2 + rng.float(-0.0005...0.0005)))
        }
        // Landing sector at the upper floor.
        let land = Prim.extrude(wedge(100 * .pi / 180, outer: ro), depth: 0.05, bevel: 0.008, bevelSegments: 1, material: treadMaterials[0])
        m.add(land, place(Float(n + 1), y: 3.0 - 0.025))

        // Center pole, base flange, sleeve spacers and cap.
        m.add(Prim.cylinder(radius: poleR, height: 3.0, bevel: 0.002, segments: lod == 0 ? 20 : 10, bevelSegments: 1, material: steel))
        m.add(Prim.cylinder(radius: 0.14, height: 0.012, bevel: 0.004, segments: lod == 0 ? 28 : 12, bevelSegments: 1, material: steel))
        if lod == 0 {
            m.add(Prim.cylinder(radius: 0.085, height: 0.03, bevel: 0.006, segments: 20, bevelSegments: 1, material: steel), Xform(translation: V3(0, 3.0 - 0.0, 0)))
        }
        for i in 0...n {
            let y0 = i == 0 ? 0.012 : Float(i) * R
            let y1 = Float(i + 1) * R - (i == n ? 0.05 : treadT)
            m.add(Prim.tube([V3(0, y0, 0), V3(0, y1, 0)], radii: [sleeveR, sleeveR], sides: lod == 0 ? 14 : 8, seamTile: 0.2, material: steel))
        }

        // Balusters and helical handrail on the outer edge.
        let rr = ro - 0.04
        func railY(_ phi: Float) -> Float { R * phi / step + railHeight }
        let ballR: Float = 0.0075
        for i in 1...n {
            let offs: [Float] = lod == 0 ? [-0.25, 0.25] : [0]
            for o in offs {
                let phi = (Float(i) + o) * step
                let y0 = Float(i) * R - 0.004
                let h = railY(phi) - 0.044 - y0 + 0.01
                let bx = rr * cosf(phi), bz = rr * sinf(phi)
                m.add(Prim.tube([V3(bx, y0, bz), V3(bx, y0 + h, bz)], radii: [ballR, ballR], sides: lod == 0 ? 7 : 5, seamTile: 0.05, material: steel))
            }
        }
        let phi0 = (1 - 0.35) * step, phi1 = (Float(n) + 0.35) * step
        let per: Float = lod == 0 ? 3.5 : 8.0
        let count = max(8, Int(((phi1 - phi0) * 180 / .pi) / Float(per)))
        let path = (0...count).map { k -> V3 in
            let phi = phi0 + (phi1 - phi0) * Float(k) / Float(count)
            return V3(rr * cosf(phi), railY(phi) - 0.022, rr * sinf(phi))
        }
        m.add(Prim.tube(path, radii: [Float](repeating: 0.022, count: path.count), sides: lod == 0 ? 10 : 6, seamTile: 0.1, material: railMaterial))
        groundAO(&m, height: 0.12, floor: 0.75)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(lod: 0, seed: seed), model(lod: 1, seed: seed)], switchDistances: [8])
    }
}
