import simd
import Foundation

/// Four loose pine bark slabs, 20 to 35 cm long and 10 to 16 cm wide, curved and plated with deep crevices, red inner faces, one leaning on another.
public struct BarkSlabLoose: RealAsset {
    public static let id = "bark-slab-loose"
    public static let summary = "Four curved plated pine bark slabs, 20 to 35 cm long, deep crevices on top and reddish inner faces, one propped on another."
    public static let tags = ["nature", "wood"]
    public static let budget = 5_300
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 45, distance: 0.8)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        DetailKit20.lods(SeededRNG(seed: seed), dist: 4) { lod, rng in
            let hi = lod == 0
            var all: [Surface] = []
            let cols = hi ? 12 : 4, rows = hi ? 18 : 6
            let spots: [(V2, Float, Float, Float)] = [(V2(-0.11, -0.07), 0, 0, 0), (V2(0.13, -0.05), 0, 0, 0), (V2(-0.06, 0.13), 0, 0, 0), (V2(0.1, 0.06), 0, 0.045, 0.28)]
            for (xz, _, lift, tilt) in spots {
                let len = rng.float(0.20...0.35), wid = rng.float(0.10...0.16), th = rng.float(0.014...0.024)
                let rc = rng.float(0.08...0.13), span = wid / rc
                let px = (0..<3).map { _ in rng.float(0...6.28) }, py = (0..<3).map { _ in rng.float(0...6.28) }
                let nu = rng.float(2.5...3.5), nv = rng.float(5...7)
                func plate(_ u: Float, _ v: Float) -> Float {
                    // 1 at plate faces, falling to 0 in crevices
                    let a = abs(sin(.pi * (u * nu + 0.25 * sin(v * 9 + px[0]) + px[1] * 0.1)))
                    let b = abs(sin(.pi * (v * nv + 0.35 * sin(u * 7 + py[0]) + py[1] * 0.1)))
                    return pow(min(1, a * 4.5), 0.5) * pow(min(1, b * 4.5), 0.5)
                }
                var outer: [[V3]] = [], inner: [[V3]] = [], uvO: [[V2]] = [], uvI: [[V2]] = []
                for i in 0...rows {
                    let v = Float(i) / Float(rows)
                    var ro: [V3] = [], ri: [V3] = [], uo: [V2] = [], ui: [V2] = []
                    for j in 0...cols {
                        let u = Float(j) / Float(cols)
                        let ang = (u - 0.5) * span
                        let edge = min(1, min(u, 1 - u) * 8, min(v, 1 - v) * 8)
                        let taper = 1 - 0.18 * v * (0.5 + 0.5 * sin(u * 3))
                        let x = (v - 0.5) * len, rr = rc
                        let inn = V3(x, rc * cos(ang) - rc * cos(span / 2), rr * sin(ang) * taper)
                        let t = th * (0.45 + 0.55 * plate(u, v)) * (0.35 + 0.65 * edge)
                        let nrm = V3(0, cos(ang), sin(ang))
                        ri.append(inn); ro.append(inn + nrm * t)
                        uo.append(V2(u * wid * 1.2, v * len * 1.2)); ui.append(V2(u * wid, v * len))
                    }
                    outer.append(ro); inner.append(ri); uvO.append(uo); uvI.append(ui)
                }
                var top = WoodParts.grid(outer, uvs: uvO, material: "bark.pine:7A6350")
                var under = WoodParts.grid(inner.reversed(), uvs: uvI.reversed(), material: "wood.pine:A5593A")
                _ = (top, under)
                top.recomputeNormals(); under.recomputeNormals()
                // edge walls
                var wall = Surface(material: "wood.pine:9B5638")
                func strip(_ a: [V3], _ b: [V3]) {
                    var ia: [UInt32] = [], ib: [UInt32] = []
                    for k in a.indices { ia.append(wall.add(a[k], V3(0, 1, 0), V2(Float(k) * 0.02, 0))); ib.append(wall.add(b[k], V3(0, 1, 0), V2(Float(k) * 0.02, 0.02))) }
                    for k in 0..<(a.count - 1) { wall.quad(ia[k], ia[k + 1], ib[k + 1], ib[k]); wall.quad(ia[k + 1], ia[k], ib[k], ib[k + 1]) }
                }
                strip(outer[0], inner[0]); strip(outer[rows], inner[rows])
                strip(outer.map { $0[0] }, inner.map { $0[0] }); strip(outer.map { $0[cols] }, inner.map { $0[cols] })
                wall.recomputeNormals()
                let q = simd_quatf(angle: rng.float(0...(2 * .pi)), axis: V3(0, 1, 0)) * simd_quatf(angle: tilt, axis: V3(0, 0, 1)) * simd_quatf(angle: rng.float(-0.05...0.05), axis: V3(1, 0, 0))
                all += DetailKit22.lay([top, under, wall], q: q, at: xz, lift: lift, sink: 0.002)
            }
            return DetailKit22.model(Self.id, all)
        }
    }
}
