import simd
import Foundation

/// Runway segment that tiles end to end along X: 30 m of asphalt, 30 m wide, with worn shoulders, an 18 m
/// centerline dash, edge stripes, elevated edge lights at the tile ends, rubber skid deposits in the
/// touchdown lanes and tar-sealed cracks. `threshold = true` paints threshold bars instead of the dash.
public struct RunwaySegment: RealAsset {
    public static let id = "runway-segment"
    public static let summary = "Runway segment, 30 m along x 30 m wide plus shoulders: asphalt with centerline dash, edge stripes, edge lights, skid marks and sealed cracks; tiles end to end."
    public static let tags = ["prop", "aerospace", "outdoor", "road", "tile"]
    public static let budget = 8_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 20, distance: 0.9)

    /// Tile length (x), runway width (z) and shoulder width in meters.
    public var length: Float = 30
    public var width: Float = 30
    public var shoulder: Float = 2
    /// Pavement thickness above grade.
    public var thickness: Float = 0.3
    /// Threshold piano-key bars in place of the centerline dash.
    public var threshold = false
    public var pavement: MaterialKey = "asphalt.road"
    public var shoulderMaterial: MaterialKey = "asphalt.worn"
    public var paint: MaterialKey = "paint.lane-white"
    public var rubber: MaterialKey = "rubber.tire"
    public var sealant: MaterialKey = "asphalt.sealant"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(seed: seed, detail: true), level(seed: seed, detail: false)], switchDistances: [120])
    }

    func level(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = length, W = width, T = thickness, hw = W / 2
        m.add(Prim.roundedBox(V3(L, T, W), radius: 0.03, bevelSegments: 1, material: pavement), Xform(translation: V3(0, T / 2, 0)))
        for z in [Float(-1), 1] {
            m.add(Prim.roundedBox(V3(L, T - 0.04, shoulder), radius: 0.05, bevelSegments: 1, material: shoulderMaterial),
                  Xform(translation: V3(0, (T - 0.04) / 2, z * (hw + shoulder / 2))))
        }
        let top = T + 0.002
        func strip(_ cx: Float, _ cz: Float, _ lx: Float, _ lz: Float, _ mat: MaterialKey, lift: Float = 0, yaw: Float = 0) {
            m.add(Prim.roundedBox(V3(lx, 0.004, lz), radius: 0.0015, bevelSegments: 1, material: mat),
                  Xform(translation: V3(cx, top + lift, cz), rotation: simd_quatf(angle: yaw, axis: V3(0, 1, 0))))
        }
        // markings
        for z in [Float(-1), 1] { strip(0, z * (hw - 0.6), L - 0.02, 0.9, paint) }
        if threshold {
            let bars = 8, bw: Float = 1.8
            for i in 0..<bars {
                let z = -hw + 3 + (Float(i) + 0.5) * (W - 6) / Float(bars)
                strip(-L / 2 + 15.5, z, 30 * 0.9, bw, paint)
            }
        } else {
            strip(0, 0, 18, 0.9, paint)
        }
        // rubber deposits in the main-gear lanes: overlapping dark streaks along X
        let lanes: [Float] = [-3.2, 3.2]
        for lz in lanes {
            for k in 0..<(detail ? 9 : 4) {
                let len = rng.float(6...16), x = rng.float(-L / 2 + len / 2...L / 2 - len / 2)
                strip(x, lz + rng.float(-0.9...0.9), len, rng.float(0.25...0.6), rubber, lift: 0.001 + Float(k) * 0.0002,
                      yaw: rng.float(-0.012...0.012))
            }
        }
        // tar-sealed cracks: wandering transverse and longitudinal lines
        if detail {
            for c in 0..<7 {
                var pts: [V3] = []
                let transverse = c < 4
                var p = transverse ? V3(rng.float(-L / 2 + 2...L / 2 - 2), 0, -hw + 0.3) : V3(-L / 2 + 0.2, 0, rng.float(-hw + 2...hw - 2))
                let steps = 14
                let stepLen = (transverse ? W - 0.6 : rng.float(8...20)) / Float(steps)
                for _ in 0...steps {
                    pts.append(V3(p.x, top + 0.0045, p.z))
                    if transverse { p += V3(rng.float(-0.5...0.5), 0, stepLen) } else { p += V3(stepLen, 0, rng.float(-0.4...0.4)) }
                }
                m.add(Prim.sweep([V2(-0.0015, -0.04), V2(0.0015, -0.04), V2(0.0015, 0.04), V2(-0.0015, 0.04)], along: pts, up: V3(0, 1, 0),
                                 material: sealant), .identity)
            }
        }
        // elevated edge lights at both tile ends on the shoulders
        for x in [-L / 2 + 0.6, L / 2 - 0.6] {
            for z in [Float(-1), 1] {
                let base = V3(x, T - 0.04, z * (hw + 0.6))
                m.add(Prim.cylinder(radius: 0.03, height: 0.32, bevel: 0.004, segments: 10, material: "metal.galvanized"), Xform(translation: base))
                m.add(Prim.cylinder(radius: 0.08, height: 0.025, bevel: 0.004, segments: 12, material: "metal.galvanized"), Xform(translation: base))
                m.add(Prim.lathe([V2(0.055, 0), V2(0.06, 0.06), V2(0.045, 0.12), V2(0, 0.14)], segments: 12, seamTile: 0.2,
                                 material: "emissive.signal-white"), Xform(translation: base + V3(0, 0.32, 0)))
            }
        }
        groundAO(&m)
        return m
    }
}
