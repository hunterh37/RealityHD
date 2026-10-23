import simd
import Foundation

/// Rusted horseshoe, 12 cm wide and 13 cm long, 9 mm bar: pitted iron, uneven wear, heel calks, six nail
/// heads, half sunk in forest soil.
public struct RustedHorseshoe: RealAsset {
    public static let id = "rusted-horseshoe"
    public static let summary = "Rusted horseshoe, ~12 cm: pitted iron bar with heel calks and nail heads, half sunk in forest soil."
    public static let tags = ["nature", "metal", "ground"]
    public static let budget = 2950
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 45, distance: 0.6)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let R: Float = rng.float(0.046...0.052), N = 28
        let a0 = -0.28 * Float.pi, a1 = 1.28 * Float.pi
        let off = rng.float(-0.08...0.08)
        var path: [V2] = [], w: [Float] = [], t: [Float] = []
        for i in 0...N {
            let f = Float(i) / Float(N), a = a0 + (a1 - a0) * f
            let sx: Float = 0.92 + 0.12 * sin(a), wob = 1 + 0.03 * sin(f * 11 + off * 40)
            // legs splay a little inward at the heels
            let rr = R * wob * (a < 0 || a > .pi ? 1.0 - 0.04 : 1)
            path.append(V2(cos(a + off * 0.3) * rr * sx * 1.1, sin(a + off * 0.3) * rr * 1.18))
            let edge = min(f, 1 - f)
            w.append(0.024 * (0.88 + 0.12 * smoothstep(0, 0.12, edge)) * (1 + 0.2 * (1 - smoothstep(0, 0.45, abs(f - 0.5) * 2)) * 0))
            t.append(0.0085 * (0.8 + 0.2 * smoothstep(0, 0.2, edge)) * rng.float(0.94...1.06))
        }
        let ty = 0.0
        var bar = DetailKit19.flatBar(path: path, width: w, thick: t, y0: Float(ty), sides: 12, rough: 0.05, material: "metal.wrought-iron:6E3F25", rng: &rng)
        // nail heads along the bar, rust bumps
        var heads = Surface(material: "metal.cast-iron-worn:5A3220")
        for k in 0..<6 {
            let i = k < 3 ? 5 + k * 3 : N - 5 - (k - 3) * 3
            let p = path[i]
            let hd = Prim.cubeSphere(subdivisions: 3, material: heads.material) { d in V3(d.x * 0.0042, d.y * 0.0018, d.z * 0.0048) * (1 + 0.15 * sin(d.x * 7 + Float(k))) }
            heads.append(hd, Xform(translation: V3(p.x, t[i] + 0.0006, p.y), rotation: simd_quatf(angle: rng.float(0...3), axis: V3(0, 1, 0))))
        }
        // heel calks: downward, small blocks at both tips
        for e in [0, N] {
            let p = path[e]
            let cl = Prim.cubeSphere(subdivisions: 3, material: heads.material) { d in V3(d.x * 0.0105, d.y * 0.0065, d.z * 0.0095) * (1 + 0.1 * sin(d.z * 5)) }
            heads.append(cl, Xform(translation: V3(p.x, t[e] + 0.0035, p.y), rotation: .identity))
        }
        // soil and a few leaf crumbs half covering one leg
        var soil = DetailKit19.mound(radius: 0.045, height: 0.0095, at: V3(path[3].x * 0.9, -0.002, path[3].y * 0.9), material: "ground.forest", rng: &rng)
        var litter = DetailKit19.mound(radius: 0.03, height: 0.006, at: V3(path[N - 4].x, 0.0005, path[N - 4].y), material: "litter.dry", rng: &rng)
        // tilt the whole thing a little, then drop so the lowest point sits at y = 0
        let q = simd_quatf(angle: rng.float(0...6.28), axis: V3(0, 1, 0)) * simd_quatf(angle: rng.float(0.03...0.09), axis: V3(1, 0, 0))
        var out = Model(name: Self.id)
        var tmp = [bar, heads]
        let lowY = tmp.map { s in s.positions.map { q.act($0).y }.min() ?? 0 }.min() ?? 0
        let xf = Xform(translation: V3(0, -lowY - 0.002, 0), rotation: q)
        for s in tmp { var o = Surface(material: s.material); o.append(s, xf); o.computeTangents(); out.add(o) }
        soil.computeTangents(); litter.computeTangents()
        var sx = Surface(material: soil.material); sx.append(soil, Xform(rotation: q)); sx.computeTangents(); out.add(sx)
        var lx = Surface(material: litter.material); lx.append(litter, Xform(rotation: q)); lx.computeTangents(); out.add(lx)
        m = out; tmp.removeAll(); bar = Surface(material: "x")
        groundAO(&m, height: 0.02, floor: 0.6)
        return LODModel(levels: [m], switchDistances: [])
    }
}
