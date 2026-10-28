import simd
import Foundation

/// Hollywood premiere stanchion pair: two polished brass posts 1.2 m apart with a crimson velvet rope sagging between them.
public struct VelvetRopeStanchion: RealAsset {
    public static let id = "velvet-rope-stanchion"
    public static let summary = "Brass stanchion pair, 0.96 m posts with weighted bases and ball finials, crimson velvet rope sagging between."
    public static let tags = ["prop", "barrier", "metal", "fabric", "decor"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 12, distance: 2.6)

    /// Distance between post centers in meters.
    public var span: Float = 1.2
    /// Post height in meters.
    public var height: Float = 0.96
    /// Rope sag in meters.
    public var sag: Float = 0.14
    /// Brass.
    public var brass: MaterialKey = "metal.brass"
    /// Velvet rope.
    public var velvet: MaterialKey = "fabric.velvet"
    /// Base underside.
    public var foot: MaterialKey = "rubber"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(lite: false), make(lite: true)], switchDistances: [5])
    }

    func make(lite: Bool) -> Model {
        var m = Model(name: Self.id)
        let seg = lite ? 12 : 24
        let attach = height - 0.12
        for s: Float in [-1, 1] {
            let x = s * span / 2
            m.add(turned([(0, 0), (0.15, 0), (0.155, 0.004), (0.15, 0.012), (0.12, 0.024), (0.05, 0.034), (0.03, 0.04), (0, 0.04)], segments: seg, material: brass, seamTile: 0.1), Xform(translation: V3(x, 0, 0)))
            m.add(turned([(0, 0), (0.148, 0), (0.148, 0.003), (0, 0.003)], segments: seg, material: foot, seamTile: 0.1), Xform(translation: V3(x, 0, 0)))
            m.add(turned([(0, 0.03), (0.026, 0.03), (0.0145, 0.06), (0.0145, height - 0.06), (0.02, height - 0.045), (0, height - 0.045)], segments: seg, material: brass, seamTile: 0.1, grainVertical: true), Xform(translation: V3(x, 0, 0)))
            for y in [Float(0.45), attach + 0.06] {
                m.add(Prim.torus(major: 0.0175, minor: 0.006, segments: seg, sides: 8, material: brass), Xform(translation: V3(x, y, 0)))
            }
            m.add(Prim.superellipsoid(V3(0.075, 0.075, 0.075), exponent: 2, subdivisions: lite ? 2 : 3, material: brass), Xform(translation: V3(x, height - 0.03, 0)))
            // Hook ring facing the rope.
            m.add(Prim.torus(major: 0.02, minor: 0.0035, segments: 16, sides: 6, material: brass), Xform(translation: V3(x + (-s) * 0.022, attach, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }
        // Rope: sagging tube with brass end caps and clips.
        let n = lite ? 12 : 24
        var path: [V3] = []
        for i in 0...n {
            let t = Float(i) / Float(n)
            path.append(V3(-span / 2 + 0.045 + (span - 0.09) * t, attach - sag * 4 * t * (1 - t), 0))
        }
        m.add(Prim.tube(path, radii: Array(repeating: 0.021, count: path.count), sides: lite ? 8 : 14, seamTile: 0.05, material: velvet, capEnd: true))
        for s: Float in [-1, 1] {
            m.add(Prim.cylinder(radius: 0.0235, height: 0.05, bevel: 0.004, segments: seg, bevelSegments: 2, material: brass),
                  Xform(translation: V3(s * (span / 2 - 0.045), attach, 0), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        }
        if !lite {
            // Tassel at the low point.
            let mid = path[n / 2]
            m.add(Prim.superellipsoid(V3(0.03, 0.035, 0.03), exponent: 2, subdivisions: 2, material: brass), Xform(translation: mid + V3(0, -0.035, 0)))
            m.add(turned([(0, 0), (0.016, 0), (0.02, -0.04), (0.01, -0.09), (0, -0.1)], segments: 12, material: velvet, seamTile: 0.05), Xform(translation: mid + V3(0, -0.05, 0)))
        }
        groundAO(&m, height: 0.1, floor: 0.85)
        return m
    }
}
