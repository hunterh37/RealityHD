import simd
import Foundation

/// Allotment irrigation furrow bed: loam drawn up into five ridges along X with flood furrows between,
/// water standing in the furrow bottoms, dark wet soil along the water line, young butterhead lettuces
/// on the ridge crowns and a galvanized watering-can rose left on the path end.
public struct AllotmentIrrigationFurrowBed: RealAsset {
    public static let id = "allotment-irrigation-furrow-bed"
    public static let summary = "Bed cut into parallel irrigation furrows with water standing in them, wet soil lines and young lettuces on the ridges."
    public static let tags = ["prop", "architecture", "facade", "ground"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 32, distance: 2.8, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.15, 2.0)
    /// Ridge count.
    public var ridges: Int = 5
    /// Ridge height above the furrow bottom (m).
    public var ridgeHeight: Float = 0.048
    /// Lettuce leaf material.
    public var lettuce: MaterialKey = "plant.stem:6E9A3E"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        let w = size.x, d = size.z, base: Float = 0.02
        let pitch = d / Float(ridges)
        func ridgeT(_ z: Float) -> Float { // 1 at ridge crown, 0 in furrow
            let u = (z + d / 2) / pitch - 0.5
            return AK.ridge(2 * (u - u.rounded()))
        }
        func h(_ p: V2) -> Float {
            let edge = min(1, (w / 2 - abs(p.x)) / 0.14)
            let n = 0.006 * Noise.fbm(V3(p.x * 6, 0, p.y * 6), octaves: 3, seed: sd)
            let wob = 0.01 * Noise.fbm(V3(p.x * 1.5, 0, 3), octaves: 2, seed: sd + 1)
            return base + 0.01 + 0.03 * (1 - edge) + edge * ridgeHeight * ridgeT(p.y + wob) + n
        }
        var m = Model(name: Self.id)
        AK.grid(&m, w: w, d: d, base: base + 0.035, nx: 20, nz: 70, h)
        // Water ribbons in each furrow with a wet-soil band either side.
        let waterY = base + 0.01 + ridgeHeight * 0.16
        for k in 0..<ridges {
            var r = rng.fork(50 + k)
            let z = -d / 2 + Float(k) * pitch
            guard k > 0 else { continue }
            let wl = waterY + r.float(-0.004...0.004)
            var wet = Prim.terrain(size: V2(w - 0.2, 0.13), segments: 24, material: "ground.mud:3A2A1C") { p in
                min(h(V2(p.x, p.y + z)) + 0.0015, wl + 0.02)
            }
            wet.positions = wet.positions.map { $0 + V3(0, 0, z) }
            m.add(wet)
            let len = w - 0.06 - r.float(0...0.02)
            var water = Prim.terrain(size: V2(len, 0.12), segments: 8, material: "water.puddle") { _ in wl }
            water.positions = water.positions.map { $0 + V3(r.float(-0.01...0.01), 0, z) }
            m.add(water)
        }
        // Lettuces on ridge crowns.
        for k in 0..<ridges {
            let z = -d / 2 + (Float(k) + 0.5) * pitch
            for i in 0..<5 {
                var r = rng.fork(100 + k * 10 + i)
                let p = V2(-0.72 + Float(i) * 0.36 + r.float(-0.03...0.03), z + r.float(-0.02...0.02))
                if r.chance(0.12) { continue }
                let root = V3(p.x, h(p) - 0.003, p.y)
                let s = r.float(0.7...1.1)
                let n = 9
                for j in 0..<n {
                    let yaw = Float(j) / Float(n) * 6.283 + r.float(-0.2...0.2)
                    m.add(AK.leaf(root, yaw: yaw, length: 0.12 * s, width: 0.1 * s, lean: r.float(0.85...1.0), curl: 0.35, fold: -0.3, segments: 4,
                                  material: j % 2 == 0 ? lettuce : "plant.stem:86B04E"))
                }
                for j in 0..<4 {
                    m.add(AK.leaf(root, yaw: Float(j) * 1.57 + 0.4, length: 0.07 * s, width: 0.06 * s, lean: 0.3, curl: -0.5, fold: -0.4, segments: 3,
                                  material: "plant.stem:A2C462"))
                }
            }
        }
        // Clods and stones on the ridge sides.
        for i in 0..<30 {
            var r = rng.fork(600 + i)
            let p = V2(r.float(-0.88...0.88), r.float(-0.92...0.92))
            if i % 3 == 0 { AK.stone(&m, at: p, y: h(p) - 0.004, size: r.float(0.012...0.03), rng: &r) }
            else { AK.clod(&m, at: p, y: h(p) - 0.005, size: r.float(0.02...0.04), rng: &r, material: ridgeT(p.y) > 0.5 ? AK.dryClod : AK.clod) }
        }
        // Watering-can rose dropped at the near end of a furrow.
        let rose = turned([(0.0, 0), (0.042, 0), (0.044, 0.004), (0.04, 0.014), (0.016, 0.05), (0.011, 0.058), (0.011, 0.075), (0.0, 0.075)],
                          segments: 24, material: "metal.galvanized-aged", seamTile: 0.1)
        let rp = V2(0.82, -d / 2 + pitch)
        m.add(rose, Xform(translation: V3(rp.x, h(rp) + 0.035, rp.y), rotation: simd_quatf(degrees: 80, axis: V3(0, 0, 1)) * simd_quatf(degrees: 20, axis: V3(1, 0, 0))))
        var lite = Model(name: Self.id + "-lite")
        AK.grid(&lite, w: w, d: d, base: base + 0.035, nx: 6, nz: 30, h)
        return AK.finish(&m, lite: lite, ao: 0.06)
    }
}
