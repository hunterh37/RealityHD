import simd
import Foundation

/// Marathon finish-line gantry, 12 m wide, 6.5 m tall, 1.2 m deep: two aluminum box-truss posts on ballast
/// plates carrying an overhead box-truss beam, a blue sponsor banner hung under the beam, and a center race
/// clock panel with seven-segment amber digits. Up +Y, runners pass along Z, clock faces +Z.
/// Anchors: `clock.face`, `banner.center`, `beam.center`, `post.left`, `post.right`.
public struct FinishLineGantry: RealAsset {
    public static let id = "finish-line-gantry"
    public static let summary = "Marathon finish gantry, 12 m: aluminum box-truss posts and beam, blue banner, race clock panel with seven-segment digits."
    public static let tags = ["prop", "sports", "metal", "outdoor"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 16)

    /// Truss tubing.
    public var truss: MaterialKey = "metal.aluminum-brushed"
    /// Banner cloth.
    public var banner: MaterialKey = "fabric.nylon:1C3F8C"
    /// Clock housing.
    public var housing: MaterialKey = "metal.powdercoat:16181C"
    /// Digit segments (lit amber).
    public var digits: MaterialKey = "plastic.orange"
    public init() {}

    public var anchors: [String: Xform] {
        [
            "clock.face": Xform(translation: V3(0, 5.3, 0.38)),
            "banner.center": Xform(translation: V3(0, 5.3, 0.1)),
            "beam.center": Xform(translation: V3(0, 6.1, 0)),
            "post.left": Xform(translation: V3(-5.7, 0, 0)),
            "post.right": Xform(translation: V3(5.7, 0, 0)),
        ]
    }

    static let segs: [Int: [Int]] = [0: [0, 1, 2, 4, 5, 6], 1: [2, 5], 2: [0, 2, 3, 4, 6], 3: [0, 2, 3, 5, 6], 4: [1, 2, 3, 5],
                                      5: [0, 1, 3, 5, 6], 6: [0, 1, 3, 4, 5, 6], 7: [0, 2, 5], 8: [0, 1, 2, 3, 4, 5, 6], 9: [0, 1, 2, 3, 5, 6]]

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let truss = truss
        func chord(_ a: V3, _ b: V3, _ r: Float, _ sides: Int) {
            m.add(Prim.tube([a, b], radii: [r, r], sides: sides, seamTile: 0.2, material: truss))
        }
        // Box truss between two ends: four chords, zigzag diagonals on the four faces.
        func boxTruss(from a: V3, to b: V3, w: Float, d: Float, bay: Float) {
            let corners: [(Float, Float)] = [(-w / 2, -d / 2), (w / 2, -d / 2), (w / 2, d / 2), (-w / 2, d / 2)]
            let axis = b - a, len = simd_length(axis), dir = axis / len
            // Perpendicular offsets in the two cross-section axes.
            let ref: V3 = abs(dir.y) > 0.9 ? V3(1, 0, 0) : V3(0, 1, 0)
            let u = simd_normalize(simd_cross(dir, ref)), v = simd_normalize(simd_cross(dir, u))
            func p(_ c: (Float, Float), _ t: Float) -> V3 { a + dir * t + u * c.0 + v * c.1 }
            for c in corners { chord(p(c, 0), p(c, len), 0.032, 48) }
            let n = max(2, Int((len / bay).rounded()))
            for f in 0..<4 {
                let c0 = corners[f], c1 = corners[(f + 1) % 4]
                for i in 0..<n {
                    let t0 = len * Float(i) / Float(n), t1 = len * Float(i + 1) / Float(n)
                    if i % 2 == 0 { chord(p(c0, t0), p(c1, t1), 0.014, 8) } else { chord(p(c1, t0), p(c0, t1), 0.014, 8) }
                }
            }
        }
        for s in [Float(-1), 1] {
            let x = s * 5.7
            boxTruss(from: V3(x, 0.08, 0), to: V3(x, 6.5, 0), w: 1.0, d: 0.5, bay: 2.2)
            m.add(Prim.roundedBox(V3(0.9, 0.08, 1.2), radius: 0.01, bevelSegments: 2, material: "metal.galvanized"), Xform(translation: V3(s * 5.55, 0.04, 0)))
            for gx in [Float(-0.3), 0.3] { for gz in [Float(-0.5), 0.5] {
                m.add(Prim.cylinder(radius: 0.03, height: 0.02, bevel: 0.004, segments: 20, material: "metal.steel"), Xform(translation: V3(x + gx * 0 + s * 0, 0.08, gz) + V3(gx, 0, 0)))
            }}
        }
        boxTruss(from: V3(-5.7, 6.08, 0), to: V3(5.7, 6.08, 0), w: 1.0, d: 0.8, bay: 2.4)
        // Banner under the beam, clock panel with digits on top of it.
        m.add(Prim.roundedBox(V3(10.9, 0.75, 0.03), radius: 0.008, bevelSegments: 2, material: banner), Xform(translation: V3(0, 5.2, 0.1)))
        for x in stride(from: Float(-5.2), through: 5.2, by: 1.3) {
            chord(V3(x, 5.62, 0.1), V3(x, 5.7, 0.1), 0.006, 8)
        }
        m.add(Prim.roundedBox(V3(2.9, 0.9, 0.24), radius: 0.02, bevelSegments: 3, material: housing), Xform(translation: V3(0, 5.3, 0.22)))
        let text = [3, -1, 5, 9, -1, 4, 8]
        var x: Float = -1.12
        for ch in text {
            if ch < 0 {
                for y in [Float(5.22), 5.38] { m.add(Prim.cylinder(radius: 0.02, height: 0.01, bevel: 0.003, segments: 20, material: digits), Xform(translation: V3(x + 0.04, y, 0.34), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0)))) }
                x += 0.18
                continue
            }
            let w: Float = 0.26, h: Float = 0.34, t: Float = 0.045
            let hor = Shape2D.polygon(sides: 6, radius: 1).map { V2($0.x * (w - t) / 2, $0.y * t / 2) }
            let ver = Shape2D.polygon(sides: 6, radius: 1).map { V2($0.x * t / 2, $0.y * (h / 2 - t / 2)) }
            for s in Self.segs[ch] ?? [] {
                let (o, shape): (V2, [V2]) = [(V2(0, h), hor), (V2(-w / 2, h / 2), ver), (V2(w / 2, h / 2), ver), (V2(0, h / 2), hor), (V2(-w / 2, 0), ver), (V2(w / 2, 0), ver), (V2(0, 0), hor)][s]
                m.add(Prim.extrude(shape, depth: 0.012, bevel: 0.002, bevelSegments: 1, material: digits), Xform(translation: V3(x + w / 2 + o.x, 5.13 + o.y, 0.34)))
            }
            x += 0.34
        }
        groundAO(&m, height: 0.3, floor: 0.7)
        return LODModel(m)
    }
}
