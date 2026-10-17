import simd
import Foundation

/// Flight-course ring gate authored at 8 m outer diameter, inner radius 3.5 m. A course gate with inner
/// radius r uses uniform scale r / 3.5. Banded painted torus with flange collars and an inner LED strip,
/// on a galvanized A-frame stand with concrete ballast feet (`showBase = false` for gates above 20 m).
public struct RingGate: RealAsset {
    public static let id = "ring-gate"
    public static let summary = "Course ring gate, 8 m outer diameter, 3.5 m inner radius: orange and white banded torus, LED strip, galvanized A-frame stand."
    public static let tags = ["prop", "aerospace", "outdoor", "barrier", "metal"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 12, distance: 1.1)

    /// Inner (fly-through) radius in meters at scale 1.
    public var innerRadius: Float = 3.5
    /// Tube radius of the ring in meters.
    public var tubeRadius: Float = 0.25
    /// Height of the ring centre above the ground with the stand.
    public var centerHeight: Float = 5.0
    /// Number of alternating colour bands.
    public var bands = 12
    /// Band colours.
    public var colorA: MaterialKey = "metal.painted:E2561B"
    public var colorB: MaterialKey = "metal.painted:E6E2D8"
    /// Inner LED strip.
    public var led: MaterialKey = "emissive.signal-white"
    /// Stand and ballast materials.
    public var frame: MaterialKey = "metal.galvanized"
    public var ballast: MaterialKey = "concrete.rough"
    /// Builds the stand; course gates above 20 m set this false.
    public var showBase = true
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(seed: seed, sides: 24), level(seed: seed, sides: 12)], switchDistances: [40])
    }

    func level(seed: UInt64, sides: Int) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let R = innerRadius + tubeRadius, c = V3(0, centerHeight, 0)
        let upright = simd_quatf(degrees: 90, axis: V3(1, 0, 0))
        let arc = 2 * Float.pi / Float(bands)
        let segs = max(4, sides * 2 / bands + 2)
        for i in 0..<bands {
            let t = Prim.torus(major: R, minor: tubeRadius, segments: segs, sides: sides, arc: arc,
                               material: i % 2 == 0 ? colorA : colorB)
            m.add(t, Xform(translation: c, rotation: upright * simd_quatf(angle: Float(i) * arc, axis: V3(0, 1, 0))))
        }
        // flange collars at every band joint, slightly proud of the tube
        for i in 0..<bands {
            let a = Float(i) * arc
            // torus lies in XZ, rotated about X by 90: point (cos a, 0, sin a) maps to (cos a, -sin a, 0)
            let p = V3(cos(a) * R, -sin(a) * R, 0)
            let tangent = simd_normalize(V3(-sin(a), -cos(a), 0))
            let collar = Prim.torus(major: tubeRadius + 0.004, minor: 0.022, segments: 16, sides: 5, material: frame)
            m.add(collar, Xform(translation: c + p, rotation: facing(tangent)))
            if sides > 16 {
                for k in 0..<0 {
                    let b = (Float(k) + 0.5) / 4 * 2 * .pi
                    let side = simd_normalize(V3(cos(a), -sin(a), 0)) * cos(b) + V3(0, 0, 1) * sin(b)
                    rivet(&m, at: c + p + side * (tubeRadius + 0.024) + tangent * 0.02, normal: side, radius: 0.012, material: frame)
                }
            }
        }
        // inner LED strip: a flat band on the inner face, split in two arcs leaving the stand joint clear
        let strip = Prim.torus(major: innerRadius + 0.01, minor: 0.06, segments: sides * 4, sides: 6,
                               minorY: 0.018, material: led)
        m.add(strip, Xform(translation: c, rotation: upright))
        // wear: one scuffed band near the bottom where the crew lifts it
        let scuff = Prim.torus(major: R, minor: tubeRadius + 0.002, segments: 4, sides: sides, arc: arc * 0.35,
                               material: "metal.rust")
        m.add(scuff, Xform(translation: c, rotation: upright * simd_quatf(angle: -Float.pi / 2 + arc * 0.6 + rng.float(-0.05...0.05), axis: V3(0, 1, 0))))

        if showBase {
            let postX: Float = 1.4
            let postTop = centerHeight - sqrt(R * R - postX * postX) + tubeRadius * 0.6
            let footZ: Float = 1.1
            for sx in [-postX, postX] {
                // A-frame: two raking legs from the ring to ballast feet front and back
                for sz in [-footZ, footZ] {
                    m.add(Prim.tube([V3(sx, postTop, 0), V3(sx * 1.08, 0.32, sz)], radii: [0.085, 0.07], sides: sides / 2,
                                    seamTile: 0.3, material: frame), .identity)
                    m.add(Prim.roundedBox(V3(0.7, 0.32, 0.7), radius: 0.03, bevelSegments: 2, material: ballast),
                          Xform(translation: V3(sx * 1.08, 0.15, sz)).jittered(&rng))
                    m.add(Prim.roundedBox(V3(0.3, 0.02, 0.3), radius: 0.004, bevelSegments: 1, material: frame),
                          Xform(translation: V3(sx * 1.08, 0.31, sz)))
                    if sides > 16 {
                        for (dx, dz) in [(-0.11, -0.11), (0.11, 0.11)] as [(Float, Float)] {
                            hexBolt(&m, at: V3(sx * 1.08 + dx, 0.32, sz + dz), normal: V3(0, 1, 0), size: 0.024, material: frame)
                        }
                    }
                }
                // saddle clamp hugging the ring
                let saddle = Prim.torus(major: tubeRadius + 0.02, minor: 0.03, segments: sides, sides: 6, arc: .pi,
                                        material: frame)
                m.add(saddle, Xform(translation: V3(sx, centerHeight - sqrt(R * R - sx * sx), 0),
                                    rotation: simd_quatf(degrees: 180, axis: V3(0, 0, 1))))
                // cross brace between the legs
                m.add(Prim.tube([V3(sx * 1.04, 1.4, -footZ * 0.62), V3(sx * 1.04, 1.4, footZ * 0.62)], radii: [0.04, 0.04],
                                sides: sides / 2, seamTile: 0.3, material: frame), .identity)
            }
            // LED power feed: junction box on the spreader, cable sagging to the ground
            m.add(Prim.roundedBox(V3(0.32, 0.24, 0.14), radius: 0.015, bevelSegments: 2, material: "plastic.matte:5A5F63"),
                  Xform(translation: V3(0.35, 1.4, 0.09)))
            let top = V3(0.3, centerHeight - R - tubeRadius * 0.2, 0.0)
            m.add(cable(catmull([top, V3(0.33, 1.9, 0.06), V3(0.33, 1.52, 0.09)], per: 6), 0.012), .identity)
            m.add(cable(catmull([V3(0.45, 1.3, 0.1), V3(0.7, 0.6, 0.35), V3(1.2, 0.06, 0.6), V3(2.6, 0.03, 1.4)], per: 6), 0.014), .identity)
            // spreader beam tying both A-frames
            m.add(Prim.tube([V3(-postX * 1.04, 1.4, 0), V3(postX * 1.04, 1.4, 0)], radii: [0.05, 0.05], sides: sides / 2,
                            seamTile: 0.3, material: frame), .identity)
        }
        groundAO(&m)
        return m
    }

    func cable(_ path: [V3], _ r: Float) -> Surface {
        Prim.tube(path, radii: Array(repeating: r, count: path.count), sides: 6, seamTile: 0.1, material: "rubber")
    }
}
