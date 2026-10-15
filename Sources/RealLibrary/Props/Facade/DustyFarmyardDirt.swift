import simd
import Foundation

/// Dusty farmyard dirt tile, 2 x 2 m: dry trodden yard earth 7 cm deep, pocked with cloven cattle
/// hoof prints in a wandering line, a tractor tyre rut along X with its lugs pressed in, dry dust
/// heaped at the rut lips, wisps of barley straw blown across, and grit and flint underfoot.
public struct DustyFarmyardDirt: RealAsset {
    public static let id = "dusty-farmyard-dirt"
    public static let summary = "Dusty farmyard dirt tile, 2 x 2 m: dry trodden yard earth with hoof prints, scattered straw and grit."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 2.6, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.08, 2.0)
    /// Earth depth at the tile edge (m).
    public var depth: Float = 0.065
    /// Yard earth material.
    public var earth: MaterialKey = "ground.dirt:8A7558"
    /// Dry dust clod material.
    public var dust: MaterialKey = "ground.site:B3A285"
    /// Straw material.
    public var straw: MaterialKey = "straw.hay"
    /// Straw wisps.
    public var wisps: Int = 14
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(rng.int(0...50_000))
        let w = size.x, d = size.z
        var hooves: [(V2, Float)] = []
        for k in 0..<10 {
            let t = Float(k) / 9
            let c = V2(-0.85 + t * 1.7 + rng.float(-0.03...0.03), 0.35 + 0.25 * sin(t * 3) + (k % 2 == 0 ? 0.08 : -0.08))
            hooves.append((c, rng.float(-0.4...0.4)))
        }
        let rutZ: Float = -0.45
        func bump(_ p: V2) -> Float {
            var h = 0.006 * Noise.fbm(V3(p.x * 2.4, 0, p.y * 2.4), octaves: 4, seed: sd)
                + 0.002 * Noise.fbm(V3(p.x * 20, 0, p.y * 20), octaves: 2, seed: sd + 3)
            let rz = (p.y - rutZ - 0.03 * sin(p.x * 1.7)) / 0.17
            if abs(rz) < 1 {
                let lug = max(0, sin((p.x + abs(rz) * 0.12) * 45))
                h -= (1 - pow(abs(rz), 6)) * (0.012 + 0.003 * lug)
            }
            h += 0.005 * exp(-pow((abs(rz) - 1.15) / 0.18, 2))
            for (c, yaw) in hooves {
                let q = p - c
                let l = V2(cos(yaw) * q.x + sin(yaw) * q.y, -sin(yaw) * q.x + cos(yaw) * q.y)
                for s: Float in [-1, 1] {
                    let e = pow((l.x - s * 0.022) / 0.02, 2) + pow(l.y / 0.045, 2)
                    h -= 0.012 * exp(-pow(e, 2))
                    h += 0.002 * exp(-pow((sqrt(e) - 1.2) / 0.25, 2))
                }
            }
            return h
        }
        var m = Model(name: Self.id)
        GTK.field(&m, w: w, d: d, edge: depth, segments: 72, earth, uvScale: 1, bump: bump)
        func height(_ p: V2) -> Float {
            let e = min(w / 2 - abs(p.x), d / 2 - abs(p.y)), k = max(0, min(1, e / 0.06))
            return depth + bump(p) * k * k * (3 - 2 * k)
        }
        var lite = Model(name: Self.id + "-lite")
        GTK.field(&lite, w: w, d: d, edge: depth, segments: 24, earth, uvScale: 1, bump: bump)
        // Straw wisps lying on the dirt.
        for k in 0..<wisps {
            var r = rng.fork(300 + k)
            let c = V2(r.float(-0.9...0.9), r.float(-0.9...0.9)), yaw = r.float(0...6.28)
            for _ in 0..<r.int(4...8) {
                let a = yaw + r.float(-0.35...0.35), len = r.float(0.08...0.2)
                let p0 = simd_clamp(c, V2(repeating: -0.75), V2(repeating: 0.75)) + V2(r.float(-0.02...0.02), r.float(-0.02...0.02)), p1 = p0 + V2(cos(a), sin(a)) * len
                let mid = (p0 + p1) / 2
                m.add(Prim.tube([V3(p0.x, height(p0) + 0.0015, p0.y), V3(mid.x, height(mid) + 0.003, mid.y), V3(p1.x, height(p1) + 0.0015, p1.y)],
                                radii: [0.0018, 0.0018, 0.0014], sides: 4, seamTile: 0.05, material: straw))
            }
        }
        GTK.stones(&m, &rng, count: 60, hx: 0.95, hz: 0.95, size: 0.008...0.03, keys: ["rock.river", "rock.granite-weathered", "rock.limestone", dust], subdivisions: 1, sink: 0.4, surface: height)
        return GTK.finish(&m, &lite, ao: 0.03, switchAt: 8)
    }
}
