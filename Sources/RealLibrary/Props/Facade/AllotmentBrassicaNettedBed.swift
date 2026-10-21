import simd
import Foundation

/// Allotment brassica netted bed: a mounded bed of cabbages and kale under four blue MDPE water-pipe
/// hoops pushed over rebar pins, draped with green anti-butterfly netting weighted with bricks.
public struct AllotmentBrassicaNettedBed: RealAsset {
    public static let id = "allotment-brassica-netted-bed"
    public static let summary = "Allotment brassica bed: cabbages and kale under blue MDPE pipe hoops draped with green butterfly netting held down by bricks."
    public static let tags = ["prop", "architecture", "facade", "ground", "garden", "outdoor", "plastic"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 28, distance: 3.2, studio: true)

    /// Tile footprint (m).
    public var width: Float = 2.0
    public var depth: Float = 2.0
    /// Hoop height above the path (m).
    public var hoopHeight: Float = 0.84
    /// Netting material (cutout mesh).
    public var netting: MaterialKey = "plastic.matte:2F5A2C"
    /// Hoop pipe material.
    public var pipe: MaterialKey = "plastic.gloss:2D5BA0"
    /// Brassica leaf material (glaucous blue-green).
    public var brassica: MaterialKey = "plant.stem:3F5E4C"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        let w = width, d = depth, pathH: Float = 0.02
        var m = Model(name: Self.id)
        // Path tile with the bed mounded 6 cm in the middle.
        AKK.field(&m, w: w, d: d, base: pathH, segments: 30) { p in
            let e = max(abs(p.x) / 0.85, abs(p.y) / 0.88)
            let mound = 0.06 * AKK.ridge(min(1, max(0, (e - 0.7) / 0.3)))
            return pathH + (e < 0.7 ? 0.06 : mound) + 0.008 * Noise.fbm(V3(p.x * 6, 0, p.y * 6), octaves: 3, seed: sd)
        }
        func ground(_ p: V2) -> Float {
            let e = max(abs(p.x) / 0.85, abs(p.y) / 0.88)
            return pathH + (e < 0.7 ? 0.06 : 0.06 * AKK.ridge(min(1, max(0, (e - 0.7) / 0.3))))
        }
        // Hoops: semi-elliptic arches across X, legs in the path.
        let a: Float = 0.82, H = hoopHeight, hoopZ: [Float] = [-0.78, -0.26, 0.26, 0.78]
        func arch(_ th: Float) -> V2 { V2(-a * cos(th), pathH - 0.01 + H * sin(th)) }
        for z in hoopZ {
            let path = (0...24).map { i -> V3 in let q = arch(Float(i) / 24 * .pi); return V3(q.x, q.y, z) }
            m.add(Prim.tube(path, radii: Array(repeating: 0.0125, count: path.count), sides: 8, seamTile: 0.08, material: pipe))
        }
        // Net: 25 mm-ish mesh drawn as knotted strands sagging between hoops, ends drawn down.
        func netPoint(_ th: Float, _ z: Float) -> V3 {
            var q = arch(th)
            var sag: Float = 0
            for k in 0..<3 where z >= hoopZ[k] && z <= hoopZ[k + 1] {
                sag = 0.035 * sin((z - hoopZ[k]) / (hoopZ[k + 1] - hoopZ[k]) * .pi)
            }
            let over = max(0, abs(z) - 0.78) / 0.08
            q.y -= sag * sin(th) + over * 0.12 * sin(th)
            q.x *= 1 - over * 0.04
            q.y += 0.015 * sin(th)
            q.x += 0.015 * -cos(th)
            return V3(q.x, q.y, z)
        }
        let z0: Float = -0.86, z1: Float = 0.86, mesh: Float = 0.055
        var net = Surface(material: netting)
        let nz = Int((z1 - z0) / mesh)
        for j in 0...nz {
            let z = z0 + Float(j) * mesh
            let pts = (0...16).map { netPoint(Float($0) / 16 * .pi, z) }
            net.append(Prim.tube(pts, radii: Array(repeating: 0.0011, count: pts.count), sides: 3, seamTile: 0.01, material: netting))
        }
        let nu = Int(Float.pi * a / mesh)
        for i in 0...nu {
            let th = Float(i) / Float(nu) * .pi
            let pts = (0...12).map { netPoint(th, z0 + (z1 - z0) * Float($0) / 12) }
            net.append(Prim.tube(pts, radii: Array(repeating: 0.0011, count: pts.count), sides: 3, seamTile: 0.01, material: netting))
        }
        m.add(net)
        // Hem weighted with old bricks along both long sides.
        for sx: Float in [-1, 1] { for k in 0..<4 {
            var r = rng.fork(20 + k + (sx > 0 ? 4 : 0))
            let z = (Float(k) - 1.5) * 0.48
            GK.box(&m, V3(sx * (a + 0.07), pathH + 0.032, z), V3(0.1, 0.065, 0.215), r.chance(0.5) ? "brick.red" : "brick.common", r: 0.006, yaw: r.float(-8...8))
        }}
        // Brassicas: 3 x 3, cabbages and two kale.
        for i in 0..<3 { for j in 0..<3 {
            var r = rng.fork(100 + i * 3 + j)
            let c = V2((Float(i) - 1) * 0.5 + r.float(-0.03...0.03), (Float(j) - 1) * 0.5 + r.float(-0.03...0.03))
            let base = V3(c.x, ground(c) - 0.004, c.y)
            let kale = (i + j) % 4 == 1
            let s = r.float(0.9...1.15)
            if kale {
                m.add(Prim.cylinder(radius: 0.014, height: 0.22, bevel: 0.003, segments: 8, material: "plant.stem:55704A"), Xform(translation: base + V3(0, 0.11, 0)))
                for k in 0..<7 {
                    let yaw = Float(k) * 2.4
                    let y = base + V3(0, 0.08 + Float(k) * 0.02, 0)
                    m.add(AKK.leaf(y, yaw: yaw, length: 0.26 * s, width: 0.09 * s, lean: r.float(0.35...0.6), curl: 0.7, fold: 0.4,
                                   segments: 6, material: "plant.stem:2F4A36"))
                }
            } else {
                for k in 0..<7 {
                    let yaw = Float(k) / 7 * 2 * .pi + r.float(-0.2...0.2)
                    m.add(AKK.leaf(base + V3(0, 0.01, 0), yaw: yaw, length: 0.24 * s, width: 0.2 * s, lean: r.float(0.6...0.85),
                                   curl: r.float(0.3...0.6), fold: -0.35, segments: 5, material: brassica))
                }
                m.add(Prim.superellipsoid(V3(0.1, 0.085, 0.1) * s, exponent: 2.2, subdivisions: 2, material: "plant.stem:7C9A6E") { dd in
                    1 + 0.05 * sin(dd.x * 11) * sin(dd.z * 9) }, Xform(translation: base + V3(0, 0.07 * s, 0)))
                // Caterpillar holes are a story for another day; one yellowed outer leaf on the soil.
                if r.chance(0.4) {
                    m.add(AKK.leaf(base, yaw: r.float(0...6), length: 0.2, width: 0.17, lean: 1.0, curl: 0.1, fold: -0.1, material: "plant.stem:A39A4A"))
                }
            }
        }}
        for i in 0..<8 {
            var r = rng.fork(500 + i)
            let p = V2(r.float(-0.95...0.95), (r.chance(0.5) ? -1 : 1) * r.float(0.9...0.93))
            AKK.weed(&m, at: V3(p.x, pathH - 0.002, p.y), height: r.float(0.04...0.08), count: 8, rng: &r)
        }
        var lite = Model(name: Self.id + "-lite")
        AKK.field(&lite, w: w, d: d, base: pathH, segments: 8) { _ in pathH }
        lite.add(net)
        return AKK.finish(&m, lite: lite, ao: 0.08)
    }
}
