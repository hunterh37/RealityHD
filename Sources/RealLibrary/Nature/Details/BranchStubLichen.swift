import simd
import Foundation

/// Dead branch stub, 28 cm long and 7 cm thick, with a splintered break and pale lichen rosettes on the bark.
public struct BranchStubLichen: RealAsset {
    public static let id = "branch-stub-lichen"
    public static let summary = "Dead branch stub, 28 cm long and 7 cm thick, with a splintered break and pale lichen rosettes on the bark."
    public static let tags = ["nature", "wood", "fungus"]
    public static let budget = 1500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 40, distance: 0.6)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var bark = Surface(material: "bark.dead:6E6455"), end = Surface(material: "wood.endgrain:B89B70"), splint = Surface(material: "wood.weathered:B7A07C")
        var lichenA = Surface(material: "moss.cushion:B9C3A6"), lichenB = Surface(material: "moss.cushion:C8C77E")
        let L = rng.float(0.26...0.32), r0 = rng.float(0.032...0.038)
        let N = 14, ns = 18
        let axis = V3(1, rng.float(0.06...0.14), rng.float(-0.08...0.08)).normalized
        let side = simd_cross(axis, V3(0, 1, 0)).normalized, up = simd_cross(side, axis).normalized
        let bendUp = rng.float(0.01...0.03), bendSide = rng.float(-0.02...0.02)
        let hR = DetailKit11.Harmonics(&rng, count: 3, lowest: 2), brk = rng.float(0...(2 * .pi))
        func axisP(_ s: Float) -> V3 { axis * (s * L - L / 2) + up * (bendUp * s * s) + side * (bendSide * s * (1 - s)) }
        func rad(_ s: Float, _ th: Float) -> Float { r0 * (1 - 0.3 * s + 0.35 * pow(1 - s, 6)) * (1 + 0.05 * hR(th + s * 4)) }
        func sEnd(_ th: Float) -> Float { 1 - 0.1 * (0.5 + 0.5 * cos(th - brk)) }
        func surf(_ s: Float, _ th: Float) -> V3 {
            let ss = s * sEnd(th)
            let d = up * cos(th) + side * sin(th)
            return axisP(ss) + d * rad(ss, th)
        }
        func dirAt(_ th: Float) -> V3 { up * cos(th) + side * sin(th) }
        var ids: [[UInt32]] = []
        for i in 0...N { var row: [UInt32] = []
            for k in 0...ns {
                let th = Float(k % ns) / Float(ns) * 2 * .pi, s = Float(i) / Float(N)
                row.append(bark.add(surf(s, th), dirAt(th), V2(Float(k) / Float(ns) * 0.22, s * L)))
            }
            ids.append(row)
        }
        for i in 0..<N { for k in 0..<ns { bark.quad(ids[i][k], ids[i][k + 1], ids[i + 1][k + 1], ids[i + 1][k]) } }
        // flipped winding check: axis x up-ish; make outward by reversing if needed below via recompute sign
        // caps
        for (s, flip) in [(Float(0), true), (Float(1), false)] {
            let c = end.add(axisP(s == 0 ? 0 : sEnd(brk)) + axis * (s == 0 ? 0 : 0.004), axis * (flip ? -1 : 1), V2(0.5, 0.5))
            var rr: [UInt32] = []
            for k in 0...ns {
                let th = Float(k % ns) / Float(ns) * 2 * .pi
                let p = surf(s, th)
                rr.append(end.add(p, axis * (flip ? -1 : 1), V2(0.5 + cos(th) * 0.5, 0.5 + sin(th) * 0.5)))
            }
            for k in 0..<ns { if flip { end.tri(c, rr[k + 1], rr[k]) } else { end.tri(c, rr[k], rr[k + 1]) } }
        }
        // splinters at the break
        for _ in 0..<5 {
            let th = brk + rng.float(-1.3...1.3), l = rng.float(0.015...0.04)
            let b = surf(1, th) - dirAt(th) * 0.008
            let tipDir = (axis + dirAt(th) * rng.float(-0.4...0.2)).normalized
            let path = [b - axis * 0.01, b + tipDir * l * 0.5, b + tipDir * l]
            splint.append(Prim.tube(path, radii: [0.009, 0.006, 0.0008], sides: 5, seamTile: 0.03, material: "wood.weathered:B7A07C", capEnd: false))
        }
        // lichen rosettes on the upper bark
        for p in 0..<16 {
            let s0 = rng.float(0.08...0.85), th0 = rng.float(-1.9...1.9), R = rng.float(0.008...0.019) * (p < 4 ? 1.4 : 1), ph = rng.float(0...6.28)
            let r = rad(s0, th0), n = 10
            var into = p % 3 == 0 ? lichenB : lichenA
            let c = into.add(surf(s0, th0) + dirAt(th0) * 0.0075, dirAt(th0), V2(0, 0))
            var ring: [UInt32] = [], mid: [UInt32] = []
            for q in 0...n {
                let phi = Float(q % n) / Float(n) * 2 * .pi
                let rho = R * (1 + 0.3 * sin(3 * phi + ph) + 0.15 * sin(5 * phi + ph * 2))
                for (f, off, isMid) in [(Float(1), Float(0.005), false), (Float(0.5), Float(0.0065), true)] {
                    let sp = s0 + f * rho * cos(phi) / L, tp = th0 + f * rho * sin(phi) / r
                    let id = into.add(surf(sp, tp) + dirAt(tp) * off, dirAt(tp), V2(cos(phi) * rho * f, sin(phi) * rho * f))
                    if isMid { mid.append(id) } else { ring.append(id) }
                }
            }
            for q in 0..<n {
                into.tri(c, mid[q + 1], mid[q])
                into.quad(mid[q], mid[q + 1], ring[q + 1], ring[q])
            }
            if p % 3 == 0 { lichenB = into } else { lichenA = into }
        }
        bark.recomputeNormals(); splint.recomputeNormals()
        var ss = [bark, end, splint, lichenA, lichenB]
        // rest on the ground
        DetailKit11.ground(&ss)
        var m = Model(name: Self.id)
        for var s in ss { s.computeTangents(); m.add(s) }
        groundAO(&m)
        return LODModel(levels: [m], switchDistances: [])
    }
}
