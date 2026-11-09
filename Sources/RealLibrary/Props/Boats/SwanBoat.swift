import simd
import Foundation

/// Boston Public Garden swan boat, 6.0 m long, 2.4 m wide, 2.6 m to the top of the swan's head: twin white
/// pontoon hulls with a raised bow, green plank deck with gunwale boards, five varnished mahogany passenger
/// benches, and at the stern a white swan figurehead with an S-curved neck, orange beak and raised layered
/// wings that shield the rider's pedal housing. Bow is +Z, swan at the stern (-Z), up +Y, base at y = 0.
/// Anchors: `swan.head`, `pedal.housing`, `bench.front`, `bench.rear`, `bow`.
public struct SwanBoat: RealAsset {
    public static let id = "swan-boat"
    public static let summary = "Boston swan boat, 6 m: twin white pontoons, green deck, five mahogany benches, stern swan with S-neck, orange beak and raised wings over the pedal housing."
    public static let tags = ["prop", "vehicle", "boat", "wood", "park"]
    public static let budget = 25_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 140, elevation: 18, distance: 6.5)

    /// Hull and swan paint (white gloss).
    public var white: MaterialKey = "plastic.gloss:F4F2EA"
    /// Deck and housing trim paint.
    public var green: MaterialKey = "wood.painted-shaker:2E5A3C"
    /// Bench slats.
    public var bench: MaterialKey = "wood.mahogany"
    /// Beak.
    public var beak: MaterialKey = "plastic.gloss:E4821B"
    public init() {}

    static let neckPath: [V3] = [V3(0, 1.62, -1.52), V3(0, 1.82, -1.36), V3(0, 2.06, -1.33), V3(0, 2.28, -1.46),
                                 V3(0, 2.44, -1.62), V3(0, 2.52, -1.50), V3(0, 2.52, -1.36)]

    public var anchors: [String: Xform] {
        [
            "swan.head": Xform(translation: V3(0, 2.52, -1.30)),
            "pedal.housing": Xform(translation: V3(0, 1.1, -1.75)),
            "bench.front": Xform(translation: V3(0, 1.10, 2.35)),
            "bench.rear": Xform(translation: V3(0, 1.10, 0.15)),
            "bow": Xform(translation: V3(0, 0.52, 3.0)),
        ]
    }

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let L: Float = 6.0
        // Pontoons: tapered spindle along Z with the bow lifted.
        for side in [Float(-1), 1] {
            let n = 17
            var path: [V3] = [], radii: [Float] = []
            for i in 0..<n {
                let t = Float(i) / Float(n - 1)
                let up = max(0, (t - 0.82) / 0.18)
                path.append(V3(side * 0.9, 0.3 + 0.2 * up * up, -L / 2 + L * t))
                radii.append(max(0.012, 0.3 * pow(max(0, 1 - pow(abs(2 * t - 1), 3.2)), 0.5)))
            }
            m.add(Prim.tube(path, radii: radii, sides: 48, seamTile: 0.5, material: white))
            // Green waterline stripe collar amidships.
            m.add(Prim.tube([V3(side * 0.9, 0.3, -2.2), V3(side * 0.9, 0.3, 2.0)], radii: [0.302, 0.302], sides: 48, seamTile: 0.5, material: green))
        }
        // Deck, side boards and cross beams.
        m.add(Prim.roundedBox(V3(2.16, 0.07, 5.5), radius: 0.012, bevelSegments: 2, material: green), Xform(translation: V3(0, 0.62, -0.1)))
        for side in [Float(-1), 1] {
            m.add(Prim.roundedBox(V3(0.05, 0.3, 5.5), radius: 0.012, bevelSegments: 2, material: white), Xform(translation: V3(side * 1.07, 0.82, -0.1)))
        }
        // Five benches facing the bow: seat, back, two legs.
        for i in 0..<5 {
            let z = 2.35 - Float(i) * 0.55
            m.add(Prim.roundedBox(V3(1.9, 0.045, 0.36), radius: 0.012, bevelSegments: 3, material: bench), Xform(translation: V3(0, 1.08, z)))
            m.add(Prim.roundedBox(V3(1.9, 0.34, 0.035), radius: 0.012, bevelSegments: 3, material: bench), Xform(translation: V3(0, 1.28, z - 0.18), rotation: simd_quatf(degrees: -8, axis: V3(1, 0, 0))))
            for lx in [Float(-0.85), 0.85] {
                m.add(Prim.roundedBox(V3(0.05, 0.42, 0.3), radius: 0.01, bevelSegments: 2, material: bench), Xform(translation: V3(lx, 0.87, z)))
            }
        }
        // Pedal housing and trim.
        m.add(Prim.superellipsoid(V3(1.3, 0.95, 1.7), exponent: 3.5, subdivisions: 12, material: white), Xform(translation: V3(0, 1.1, -1.75)))
        m.add(Prim.roundedBox(V3(1.34, 0.06, 1.74), radius: 0.02, bevelSegments: 2, material: green), Xform(translation: V3(0, 0.67, -1.75)))
        // Swan body, S-neck, head, beak, eyes.
        m.add(Prim.superellipsoid(V3(0.78, 0.56, 1.4), exponent: 2.4, subdivisions: 12, material: white), Xform(translation: V3(0, 1.72, -1.95)))
        let neck = catmull(Self.neckPath, per: 4)
        let radii = neck.indices.map { i -> Float in let t = Float(i) / Float(neck.count - 1); return lerp(0.12, 0.05, smoothstep(0, 0.85, t)) }
        m.add(Prim.tube(neck, radii: radii, sides: 48, seamTile: 0.3, material: white))
        let head = V3(0, 2.52, -1.31)
        m.add(Prim.superellipsoid(V3(0.11, 0.10, 0.19), exponent: 2, subdivisions: 8, material: white), Xform(translation: head))
        m.add(Prim.tube([head + V3(0, -0.005, 0.07), head + V3(0, -0.02, 0.16), head + V3(0, -0.045, 0.23)], radii: [0.03, 0.026, 0.012], sides: 48, seamTile: 0.1, material: beak))
        for s in [Float(-1), 1] {
            m.add(Prim.superellipsoid(V3(0.016, 0.016, 0.016), exponent: 2, subdivisions: 3, material: "plastic.gloss:0A0A0A"), Xform(translation: head + V3(s * 0.05, 0.015, 0.04)))
        }
        // Raised wings: main plate plus two layered feather banks, leaning outward over the housing.
        for s in [Float(-1), 1] {
            let lean = simd_quatf(degrees: -s * 20, axis: V3(0, 0, 1)) * simd_quatf(degrees: -8, axis: V3(1, 0, 0))
            let c = V3(s * 0.66, 1.55, -1.95)
            m.add(Prim.superellipsoid(V3(0.10, 1.1, 1.7), exponent: 2.4, subdivisions: 10, material: white), Xform(translation: c, rotation: lean))
            m.add(Prim.superellipsoid(V3(0.06, 0.8, 1.35), exponent: 2.4, subdivisions: 6, material: white),
                  Xform(translation: c + lean.act(V3(s * 0.06, -0.12, -0.12)), rotation: lean))
        }
        groundAO(&m, height: 0.4, floor: 0.6)
        return LODModel(m)
    }
}
