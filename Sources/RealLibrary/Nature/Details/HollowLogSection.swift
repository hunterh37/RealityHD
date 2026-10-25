import simd
import Foundation

/// Rotted hollow log section, 60 cm long and 38 cm across: bark shell, punky hollow core and ragged broken ends.
public struct HollowLogSection: RealAsset {
    public static let id = "hollow-log-section"
    public static let summary = "Rotted hollow log section, 60 cm long and 38 cm across, with bark shell, punky core and ragged broken ends."
    public static let tags = ["nature", "wood"]
    public static let budget = 1500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 30, distance: 1.3)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var outer = Surface(material: "bark.oak:5A4D40"), inner = Surface(material: "wood.deadwood:7A6248"), rim = Surface(material: "wood.endgrain:A58A64")
        let L = rng.float(0.55...0.66), R = rng.float(0.17...0.2)
        let nu = 14, ns = 20
        let hR = DetailKit11.Harmonics(&rng, count: 4, lowest: 2), hI = DetailKit11.Harmonics(&rng, count: 4, lowest: 2)
        let e0 = DetailKit11.Harmonics(&rng, count: 3, lowest: 1), e1 = DetailKit11.Harmonics(&rng, count: 3, lowest: 1)
        let bark = DetailKit11.Harmonics(&rng, count: 5, lowest: 4), bend = rng.float(-0.03...0.03), sag = rng.float(0.01...0.025)
        let wall = rng.float(0.5...0.62)
        func outerP(_ i: Int, _ k: Int) -> V3 {
            let u = Float(i) / Float(nu), th = Float(k % ns) / Float(ns) * 2 * .pi
            let x = lerp(-L / 2 + 0.05 * (0.5 + 0.5 * e0(th)) + (th > 5.5 ? 0.04 : 0), L / 2 - 0.07 * (0.5 + 0.5 * e1(th)) - (th < 1 ? 0.06 : 0), u)
            let flare = 1 + 0.06 * pow(abs(2 * u - 1), 4)
            let r = R * flare * (1 + 0.05 * hR(th + u * 2)) + 0.006 * bark(th * 3 + u * 9)
            let cy = R * 0.93 + sag * (1 - pow(2 * u - 1, 2) * 0), cz = bend * (2 * u - 1)
            return V3(x, max(cy + r * cos(th), 0), cz + r * sin(th))
        }
        func innerP(_ i: Int, _ k: Int) -> V3 {
            let u = Float(i) / Float(nu), th = Float(k % ns) / Float(ns) * 2 * .pi
            let o = outerP(i, k)
            let cy = R * 0.93 + sag, cz = bend * (2 * u - 1)
            let r = R * wall * (1 + 0.14 * hI(th * 1.5 + u * 3)) * (1 + 0.1 * pow(abs(2 * u - 1), 3))
            var p = V3(o.x, cy + r * cos(th), cz + r * sin(th))
            // inner surface tucks in from ragged ends
            let t = min(u, 1 - u)
            if t < 0.12 { p.x += (u < 0.5 ? 1 : -1) * (0.12 - t) * 0.25 }
            return p
        }
        var oi: [[UInt32]] = [], ii: [[UInt32]] = []
        for i in 0...nu {
            var ro: [UInt32] = [], ri: [UInt32] = []
            for k in 0...ns {
                let o = outerP(i, k), n = innerP(i, k)
                ro.append(outer.add(o, V3(0, 1, 0), V2(Float(k) / Float(ns) * 1.2, o.x)))
                ri.append(inner.add(n, V3(0, 1, 0), V2(Float(k) / Float(ns) * 0.8, n.x)))
            }
            oi.append(ro); ii.append(ri)
        }
        for i in 0..<nu { for k in 0..<ns {
            outer.quad(oi[i][k], oi[i][k + 1], oi[i + 1][k + 1], oi[i + 1][k])
            inner.quad(ii[i][k], ii[i + 1][k], ii[i + 1][k + 1], ii[i][k + 1])
        }}
        for (i, flip) in [(0, true), (nu, false)] {
            for k in 0..<ns {
                let a = rim.add(outerP(i, k), V3(0, 1, 0), V2(0, 0)), b = rim.add(outerP(i, k + 1), V3(0, 1, 0), V2(0.05, 0))
                let c = rim.add(innerP(i, k + 1), V3(0, 1, 0), V2(0.05, 0.1)), d = rim.add(innerP(i, k), V3(0, 1, 0), V2(0, 0.1))
                if flip { rim.quad(a, d, c, b) } else { rim.quad(a, b, c, d) }
            }
        }
        var ss = [outer, inner, rim]
        for k in ss.indices { ss[k].recomputeNormals() }
        var m = Model(name: Self.id)
        for var s in ss { s.computeTangents(); m.add(s) }
        groundAO(&m)
        return LODModel(levels: [m], switchDistances: [])
    }
}
