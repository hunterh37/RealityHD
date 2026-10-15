import simd
import Foundation

/// Exposed aggregate concrete: architectural facade customizer, Mid-Century Modern. Four 1 m cast bays
/// with tooled smooth margins, washed pebble-aggregate field, 10 mm expansion joints with grit and moss.
public struct ExposedAggregateConcrete: RealAsset {
    public static let id = "exposed-aggregate-concrete"
    public static let summary = "Exposed aggregate concrete tile, 2 x 2 m: four cast bays with tooled smooth margins, washed river-pebble aggregate field, grit-filled expansion joints."
    public static let tags = ["prop", "architecture", "facade", "ground", "concrete", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 35, distance: 1.0, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.15, 2.0)
    /// Bays per side.
    public var bays = 2
    /// Expansion joint width (m).
    public var joint: Float = 0.01
    /// Tooled smooth margin width (m).
    public var margin: Float = 0.055
    /// Exposed pebbles per bay.
    public var pebblesPerBay = 150
    /// Margin concrete.
    public var marginMaterial: MaterialKey = "concrete.smooth:8F897F"
    /// Aggregate field.
    public var fieldMaterial: MaterialKey = "concrete.exposed-aggregate"
    /// Pebble tones (sRGB hex) on the river rock material.
    public var pebbleTones: [UInt32] = [0xA79A86, 0x8C8173, 0xC2B49C, 0x6F665C, 0xB59B7E]
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let top = size.y
        let bay = V2(size.x, size.z) / Float(bays)
        let pebbleKeys = pebbleTones.map { "rock.river:\(String(format: "%06X", $0))" }
        for i in 0..<bays { for j in 0..<bays {
            var r = rng.fork(i * 31 + j)
            let c = V2(-size.x / 2 + bay.x * (Float(i) + 0.5), -size.z / 2 + bay.y * (Float(j) + 0.5))
            let sx = bay.x - joint, sz = bay.y - joint
            let h = top - 0.002 + r.float(-0.0015...0.0015)
            // Cast slab with tooled 12 mm radius arris.
            m.add(Prim.roundedBox(V3(sx, h, sz), radius: 0.012, bevelSegments: 2, material: marginMaterial),
                  Xform(translation: V3(c.x, h / 2, c.y), rotation: simd_quatf(degrees: r.float(-0.12...0.12), axis: r.unitVector())))
            // Washed aggregate field, 1.5 mm below the margin edge is faked by a thin proud panel with soft edge.
            let fx = sx - 2 * margin, fz = sz - 2 * margin
            m.add(Prim.roundedBox(V3(fx, 0.004, fz), radius: 0.0018, bevelSegments: 1, material: fieldMaterial),
                  Xform(translation: V3(c.x, h - 0.0012, c.y)))
            // Individual exposed pebbles, half-buried.
            for k in 0..<pebblesPerBay {
                var q = r.fork(1000 + k)
                let p = V2(q.float(-0.5...0.5) * (fx - 0.02), q.float(-0.5...0.5) * (fz - 0.02)) + c
                let s = q.float(0.011...0.024)
                let sz3 = V3(s * q.float(0.8...1.3), s * q.float(0.45...0.7), s * q.float(0.8...1.3))
                let peb = Prim.superellipsoid(sz3, exponent: 2.2, subdivisions: 1, material: pebbleKeys[q.int(0...(pebbleKeys.count - 1))])
                m.add(peb, Xform(translation: V3(p.x, h + 0.0008 - sz3.y * 0.15, p.y),
                                 rotation: simd_quatf(angle: q.float(0...6.28), axis: V3(0, 1, 0))))
            }
        }}
        // Grit bed in the joints.
        m.add(Prim.roundedBox(V3(size.x - 0.004, top - 0.03, size.z - 0.004), radius: 0.002, bevelSegments: 1, material: "ground.dirt"),
              Xform(translation: V3(0, (top - 0.03) / 2, 0)))
        // Moss and weeds creeping along the joints.
        for k in 0..<18 {
            var r = rng.fork(5000 + k)
            let along = r.float(-0.95...0.95)
            let p: V2 = r.chance(0.5) ? V2(along * size.x / 2, 0) : V2(0, along * size.z / 2)
            let len = r.float(0.03...0.09)
            let sz3 = p.y == 0 ? V3(len, 0.01, 0.012) : V3(0.012, 0.01, len)
            m.add(Prim.superellipsoid(sz3, exponent: 2.4, subdivisions: 2, material: "moss.cushion"), Xform(translation: V3(p.x, top - 0.012, p.y)))
        }
        groundAO(&m, height: 0.05, floor: 0.7)
        var lite = Model(name: Self.id + "-lite")
        lite.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 1, material: fieldMaterial), Xform(translation: V3(0, top / 2, 0)))
        return LODModel(levels: [m, lite], switchDistances: [10])
    }
}
