import simd
import Foundation

/// Mossy stone flag paving tile, 2 x 2 m: irregular riven gritstone flags 50-70 mm thick, laid
/// crazy-style on bare earth with wide 20-40 mm joints. Thick moss cushions fill the joints and
/// creep over the flag arrises, some flags have settled and tilted, and a few leaves have fallen.
public struct MossyStoneFlagPaving: RealAsset {
    public static let id = "mossy-stone-flag-paving"
    public static let summary = "Mossy stone flag paving tile, 2 x 2 m: irregular riven gritstone flags on earth with thick moss cushions filling the wide joints."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 40, distance: 2.4, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.1, 2.0)
    /// Mean flag spacing (m).
    public var spacing: Float = 0.45
    /// Half joint width (m).
    public var halfJoint: Float = 0.014
    /// Flag thickness (m).
    public var thickness: Float = 0.06
    /// Flag tones (sRGB hex): weathered gritstone greys and buffs.
    public var tones: [UInt32] = [0x8C8676, 0x7A7566, 0x969080, 0x6E6A5E, 0x857C68]
    /// Flag stone.
    public var stone: MaterialKey = "stone.sandstone"
    /// Lichen-stained flag variant.
    public var mossyStone: MaterialKey = "stone.granite-moss"
    /// Earth in the joints.
    public var earth: MaterialKey = "ground.dirt:4A3E30"
    /// Moss.
    public var moss: MaterialKey = "moss.cushion"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let top = size.y, hx = size.x / 2, hz = size.z / 2
        let keys = tones.map { "\(stone):\(String(format: "%06X", $0))" }
        // Jittered sites, Voronoi cells clipped to the tile.
        var sites: [V2] = []
        let n = Int(size.x / spacing) + 2
        for j in -1...n { for i in -1...n {
            if rng.chance(0.22) { continue }
            sites.append(V2(-hx + (Float(i) + 0.5 + rng.float(-0.38...0.38)) * spacing * (size.x / (spacing * Float(n - 1))),
                            -hz + (Float(j) + 0.5 + rng.float(-0.38...0.38)) * spacing * (size.z / (spacing * Float(n - 1)))))
        }}
        var flags: [[V2]] = []
        for (si, s) in sites.enumerated() {
            var cell = FPK.rect(s.x, s.y, 2, 2)
            for (oi, o) in sites.enumerated() where oi != si && simd_distance(o, s) < spacing * 3 {
                cell = FPK.clipHalf(cell, o: (s + o) / 2, n: simd_normalize(o - s))
                if cell.count < 3 { break }
            }
            cell = FPK.clip(cell, x0: -hx, x1: hx, z0: -hz, z1: hz)
            guard cell.count >= 3, abs(FPK.area(cell)) > 0.01 else { continue }
            let inset = FPK.inset(cell, halfJoint * rng.float(0.8...1.4))
            guard inset.count >= 3 else { continue }
            flags.append(inset)
            let mat = rng.chance(0.12) ? "\(mossyStone):\(String(format: "%06X", rng.pick(tones)))" : rng.pick(keys)
            let settle: Float = rng.chance(0.2) ? rng.float(0.004...0.01) : 0
            FPK.piece(&m, inset, top: top + rng.float(-0.003...0.003) - settle, thick: thickness * rng.float(0.85...1.1), bevel: 0.008,
                      mat, tilt: 0.9, rng: &rng)
        }
        // Earth bed, humped in the joints.
        let sd = UInt32(truncatingIfNeeded: rng.int(0...100_000))
        GTK.field(&m, w: size.x - 0.004, d: size.z - 0.004, edge: top - 0.03, segments: 30, earth, uvScale: 1.5) { p in
            0.006 * Noise.fbm(V3(p.x * 6, 0, p.y * 6), octaves: 2, seed: sd)
        }
        var lite = m
        // Moss cushions along every flag edge; denser on the shaded (+z) half.
        var mossSurf = Surface(material: moss)
        for (fi, f) in flags.enumerated() {
            for e in 0..<f.count {
                let a = f[e], b = f[(e + 1) % f.count], len = simd_distance(a, b)
                let dir = (b - a) / max(len, 1e-4), out = V2(dir.y, -dir.x) * (FPK.area(f) > 0 ? 1 : -1)
                var r = rng.fork(5000 + fi * 16 + e)
                let dens = 0.55 + 0.4 * ((a.y + b.y) / 2 + hz) / size.z
                var u: Float = r.float(0...0.05)
                while u < len - 0.02 {
                    let step = r.float(0.035...0.07)
                    if r.chance(dens) {
                        let p = simd_clamp(a + dir * u + out * r.float(0.004...0.014), V2(-hx + 0.04, -hz + 0.04), V2(hx - 0.04, hz - 0.04))
                        let w = r.float(0.04...0.08), hgt = r.float(0.02...0.032)
                        let ss = UInt32(truncatingIfNeeded: r.int(0...100_000))
                        var c = Prim.superellipsoid(V3(w, hgt, r.float(0.03...0.045)), exponent: 2.2, subdivisions: 1, material: moss) { d in
                            1 + 0.15 * Noise.fbm(d * 4, octaves: 2, seed: ss)
                        }
                        c.uvs = c.positions.map { V2($0.x + $0.y, $0.z - $0.y) }; c.computeTangents()
                        mossSurf.append(c, Xform(translation: V3(p.x, top - 0.01, p.y), rotation: simd_quatf(angle: -atan2(dir.y, dir.x), axis: .up)))
                    }
                    u += step
                }
            }
        }
        m.add(mossSurf)
        // Fallen leaves on the flags.
        for k in 0..<9 {
            var r = rng.fork(8000 + k)
            let c = V2(r.float(-0.85...0.85), r.float(-0.85...0.85)), yaw = r.float(0...6.28), sz = r.float(0.035...0.06)
            let tone = ["7A4A22", "9A6A2A", "5E3A1E"][r.int(0...2)]
            GK.poly(&m, (0..<12).map { i in
                let a = Float(i) / 12 * 2 * .pi, rad = sz * (1 - 0.5 * pow(abs(cos(a)), 2)) * (1 + 0.08 * sin(a * 7))
                let q = V2(cos(a) * rad * 1.5, sin(a) * rad * 0.8)
                return c + V2(q.x * cos(yaw) - q.y * sin(yaw), q.x * sin(yaw) + q.y * cos(yaw))
            }, top: top + 0.003, "wood.deadwood:\(tone)", thick: 0.0012)
        }
        return GTK.finish(&m, &lite, ao: 0.05, switchAt: 8)
    }
}
