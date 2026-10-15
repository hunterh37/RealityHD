import simd
import Foundation

/// Tethered obstacle balloon, radius 2 to 8 m. Glossy gored envelope with a white marker band and seam
/// welts, a reinforced load patch, a four-line bridle to a galvanized confluence ring, and a tether down to
/// a concrete anchor block with an eye bolt. Course balloons set `tetherLength` to the flight altitude.
public struct ObstacleBalloon: RealAsset {
    public static let id = "obstacle-balloon"
    public static let summary = "Tethered obstacle balloon, radius 2-8 m: red gored envelope with white band, four-line bridle, tether to a concrete anchor."
    public static let tags = ["prop", "aerospace", "outdoor", "barrier", "plastic"]
    public static let budget = 12_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 10, distance: 1.15)

    /// Envelope radius in meters (2 to 8).
    public var radius: Float = 2
    /// Tether length from the anchor to the confluence ring.
    public var tetherLength: Float = 4.5
    /// Bridle length from the confluence ring to the envelope.
    public var bridle: Float = 1.2
    public var gores = 12
    public var envelope: MaterialKey = "plastic.gloss:C8261E"
    /// Lower envelope: same colour, dulled by dust and handling.
    public var dusty: MaterialKey = "plastic.bucket:B32A20"
    public var band: MaterialKey = "plastic.gloss:ECE9E2"
    public var line: MaterialKey = "fabric.webbing:2B2B2B"
    public var hardware: MaterialKey = "metal.galvanized"
    public var anchor: MaterialKey = "concrete.rough"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(seed: seed, segs: 40, detail: true), level(seed: seed, segs: 18, detail: false)],
                 switchDistances: [radius * 12])
    }

    func level(seed: UInt64, segs: Int, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let R = min(max(radius, 2), 8)
        let ringY = tetherLength + 0.45
        let attachLat: Float = -0.62 // radians below the equator where the bridle meets the envelope
        let cy = ringY + bridle - sin(attachLat) * 0.97 * R
        let c = V3(0, cy, 0)
        // envelope: slightly oblate, pulled down at the load patch
        func sphere(_ r: Float, _ lat0: Float, _ lat1: Float, _ n: Int, _ mat: MaterialKey) -> Surface {
            var prof: [V2] = []
            for k in 0...n {
                let a = lat0 + (lat1 - lat0) * Float(k) / Float(n)
                let sag: Float = a < -1.1 ? 1 - 0.06 * (-a - 1.1) : 1
                prof.append(V2(r * cos(a) * sag * 1.02, r * sin(a) * 0.97))
            }
            return Prim.lathe(prof, segments: segs, seamTile: 1, material: mat)
        }
        let n = segs / 2
        // lower envelope: load wrinkles fanning out from the patch, gore bulges between seams
        var lower = sphere(R, -.pi / 2, -0.16, n * 7 / 10, dusty)
        let gs = Float(gores)
        lower.displace { p, _ in
            let lat = asin(max(-1, min(1, p.y / R))), lon = atan2(p.z, p.x)
            let low = max(0, (-lat - 0.7) / 0.87)
            return R * (0.004 * abs(sin(lon * gs / 2 - 0.13 * gs / 2)) + 0.006 * low * low * sin(lon * 37) - 0.004 * low)
        }
        m.add(lower, Xform(translation: c))
        m.add(sphere(R * 1.002, -0.16, 0.16, 4, band), Xform(translation: c))
        var upper = sphere(R, 0.16, .pi / 2, n * 7 / 10, envelope)
        upper.displace { p, _ in R * 0.004 * abs(sin(atan2(p.z, p.x) * gs / 2 - 0.13 * gs / 2)) }
        m.add(upper, Xform(translation: c))
        // gore seam welts along meridians
        if detail {
            for g in 0..<gores {
                let lon = Float(g) / Float(gores) * 2 * .pi + 0.13
                var path: [V3] = []
                for k in 1..<23 {
                    let a = -.pi / 2 + .pi * Float(k) / 23
                    path.append(c + V3(cos(a) * cos(lon) * 1.02, sin(a) * 0.97, cos(a) * sin(lon) * 1.02) * (R + 0.004))
                }
                m.add(Prim.tube(path, radii: Array(repeating: 0.012 * R / 2, count: path.count), sides: 4, seamTile: 0.2,
                                material: g % 3 == 0 ? band : envelope), .identity)
            }
            // two field repair patches on the windward side
            for (lat, lon, r) in [(Float(0.42), Float(0.7), Float(0.16)), (Float(-0.38), Float(0.95), Float(0.11))] {
                let d = V3(cos(lat) * cos(lon) * 1.02, sin(lat) * 0.97, cos(lat) * sin(lon) * 1.02)
                m.add(Prim.lathe([V2(r * R / 2, 0), V2(r * R / 2 * 0.96, 0.004), V2(0, 0.005)], segments: 16, seamTile: 0.3, material: "plastic.gloss:A3221A"),
                      Xform(translation: c + d * R + simd_normalize(d) * 0.003, rotation: facing(simd_normalize(d))))
            }
            // fill valve on the crown
            m.add(Prim.cylinder(radius: 0.09, height: 0.06, bevel: 0.01, segments: 12, material: "plastic.black"),
                  Xform(translation: c + V3(0, R * 0.97 - 0.01, 0)))
        }
        // load patch at the bottom
        m.add(Prim.lathe([V2(R * 0.28, 0.0), V2(R * 0.2, -0.004), V2(0, -0.012)], segments: segs, seamTile: 0.3, material: band),
              Xform(translation: c + V3(0, -R * 0.97 * 0.995, 0)))
        // bridle: four lines from patch tabs to the confluence ring
        let ring = V3(0, ringY, 0)
        for k in 0..<4 {
            let lon = Float(k) / 4 * 2 * .pi + .pi / 4
            let tab = c + V3(cos(attachLat) * cos(lon) * 1.02, sin(attachLat) * 0.97, cos(attachLat) * sin(lon) * 1.02) * (R + 0.01)
            m.add(Prim.tube([tab, ring + V3(cos(lon), 0, sin(lon)) * 0.06], radii: [0.012, 0.012], sides: 5, seamTile: 0.1, material: line), .identity)
        }
        m.add(Prim.torus(major: 0.08, minor: 0.015, segments: 16, sides: 6, material: hardware), Xform(translation: ring))
        // tether with a slight sway, down to the anchor eye bolt
        let sway = V3(rng.float(-0.2...0.2), 0, rng.float(-0.2...0.2))
        let tetherPath = (0...8).map { i -> V3 in
            let t = Float(i) / 8
            return V3(0, 0.5, 0) * (1 - t) + ring * t + sway * sin(t * .pi) * 0.5
        }
        m.add(Prim.tube(tetherPath, radii: Array(repeating: 0.01, count: tetherPath.count), sides: 5, seamTile: 0.1, material: line), .identity)
        m.add(Prim.roundedBox(V3(0.8, 0.4, 0.8), radius: 0.03, bevelSegments: 2, material: anchor), Xform(translation: V3(0, 0.2, 0)).jittered(&rng))
        m.add(Prim.torus(major: 0.06, minor: 0.014, segments: 14, sides: 6, material: hardware),
              Xform(translation: V3(0, 0.46, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        m.add(Prim.cylinder(radius: 0.05, height: 0.03, bevel: 0.005, segments: 12, material: hardware), Xform(translation: V3(0, 0.4, 0)))
        // a coil of spare line dropped on the block: the crew left it there
        if detail {
            m.add(Prim.torus(major: 0.14, minor: 0.012, segments: 20, sides: 5, material: line),
                  Xform(translation: V3(0.22, 0.415, 0.18), rotation: simd_quatf(degrees: 4, axis: V3(1, 0, 0))))
            m.add(Prim.torus(major: 0.12, minor: 0.012, segments: 20, sides: 5, material: line),
                  Xform(translation: V3(0.24, 0.438, 0.17), rotation: simd_quatf(degrees: -6, axis: V3(0, 0, 1))))
        }
        groundAO(&m)
        return m
    }
}
