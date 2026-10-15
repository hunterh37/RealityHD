import simd
import Foundation

/// Chip seal road surface tile, 2 x 2 m: surface dressing on a rural lane, a sprayed film of hot
/// bitumen binder with single-size 10 mm grey granite chippings rolled in shoulder to shoulder over
/// an older asphalt base. Surplus loose chips gather at the verge edge and binder has bled up
/// through the chips in the nearside wheel track, leaving a dark glossy stripe.
public struct ChipSealRoadSurface: RealAsset {
    public static let id = "chip-seal-road-surface"
    public static let summary = "Chip seal road surface tile, 2 x 2 m: sprayed bitumen binder with rolled single-size 10 mm grey granite chippings, loose surplus chips and a bled wheel track."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 0.7, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.05, 2.0)
    /// Embedded chippings modelled individually.
    public var chipCount: Int = 700
    /// Loose surplus chips at the verge (+Z) edge.
    public var looseCount: Int = 120
    /// Wheel-track centre (z) and half width (m).
    public var track: Float = -0.35, trackHalf: Float = 0.16
    /// Chip tones: grey granite with a few buff and dark pieces.
    public var chipKeys: [MaterialKey] = ["rock.granite:8A8A86", "rock.granite:9C9890", "rock.granite:6E6E6C", "rock.granite:A8A298", "rock.granite:7C7468"]
    /// Chip mosaic surface.
    public var mosaic: MaterialKey = "ground.gravel:7C7A76"
    /// Bled binder.
    public var binder: MaterialKey = "asphalt.patch:1A1A1A"
    /// Base course.
    public var base: MaterialKey = "asphalt.road:3A3A3A"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let top = size.y - 0.006, hx = size.x / 2, hz = size.z / 2
        let sd = UInt32(truncatingIfNeeded: rng.int(0...100_000))
        func bleed(_ p: V2) -> Float { max(0, 1 - abs(p.y - track - 0.03 * sin(p.x * 3)) / trackHalf) }
        func h(_ p: V2) -> Float {
            // Slight camber toward the verge plus rutting in the wheel track.
            -0.004 * (p.y + hz) / size.z - 0.003 * bleed(p) + 0.0008 * Noise.fbm(V3(p.x * 25, 0, p.y * 25), octaves: 2, seed: sd)
        }
        GK.slab(&m, w: size.x - 0.002, d: size.z - 0.002, h: top - 0.012, base, r: 0.002)
        GTK.field(&m, w: size.x, d: size.z, edge: top, segments: 30, mosaic, uvScale: 1.4) { h($0) }
        // Bled binder stripe: thin glossy film over the mosaic in the wheel track.
        var b = Prim.terrain(size: V2(size.x - 0.02, trackHalf * 2.2), segments: 20, material: binder) { q in
            let p = V2(q.x, q.y + track)
            let n = Noise.fbm(V3(p.x * 9, 0, p.y * 9), octaves: 3, seed: sd + 7)
            return top + h(p) - 0.0022 + 0.0042 * (bleed(p) + 0.6 * n)
        }
        b.positions = b.positions.map { $0 + V3(0, 0, track) }
        b.computeTangents()
        m.add(b)
        var lite = m
        // Embedded chips: flaky cubical 8-12 mm chippings, sunk deeper where the binder has bled.
        GTK.stones(&m, &rng, count: chipCount, hx: hx - 0.006, hz: hz - 0.006, size: 0.008...0.013, flat: 0.45...0.65,
                   keys: chipKeys, subdivisions: 1, exponent: 3.0, sink: 0.5,
                   surface: { top + h($0) }, keep: { p in bleed(p) < 0.4 || (sin(p.x * 127.1 + p.y * 311.7) * 43758.5).truncatingRemainder(dividingBy: 1) > 0.8 })
        // Loose surplus chips swept to the verge.
        var r2 = rng.fork(42)
        GTK.stones(&m, &r2, count: looseCount, hx: hx - 0.01, hz: 0.12, size: 0.008...0.013, flat: 0.5...0.7,
                   keys: chipKeys, subdivisions: 1, exponent: 3.0, sink: 0.1, offset: V3(0, 0, hz - 0.13),
                   surface: { q in top + h(q + V2(0, hz - 0.13)) })
        groundAO(&m, height: 0.03, floor: 0.75)
        groundAO(&lite, height: 0.03, floor: 0.75)
        return LODModel(levels: [m, lite], switchDistances: [4])
    }
}
