import simd
import Foundation

/// Bathroom fixture helpers shared by the floor planning pack (toilet, bidet, sinks, tubs).
public enum BathFit {
    /// "D" plan outline for toilet bowls, seats and lids: straight sides, a squared rear with corner
    /// radius `rr`, and a superellipse front reaching `front`. Plan coordinates (x, -z) so it feeds
    /// `Prim.ring`; counter-clockwise from +Y. Point count is constant for a given `nFront`.
    public static func dOutline(hw: Float, front: Float, rear: Float, rr: Float, exponent: Float = 2.4, nFront: Int = 16) -> [V2] {
        let r = max(rr, 0.001)
        let zs = rear + r + (front - rear) * 0.22   // where the straight sides end
        var pts: [V2] = []
        pts.append(V2(hw, -zs))
        for i in 0...4 {
            let a = Float(i) / 4 * .pi / 2
            pts.append(V2(hw - r + r * cos(a), -(rear + r - r * sin(a))))
        }
        for i in 0...4 {
            let a = Float(i) / 4 * .pi / 2
            pts.append(V2(-hw + r - r * sin(a), -(rear + r - r * cos(a))))
        }
        pts.append(V2(-hw, -zs))
        // Front: half superellipse from the left side round to the right side.
        let b = front - zs
        for i in 1..<(2 * nFront) {
            let t = Float(i) / Float(2 * nFront) * .pi
            let cx = -cos(t), sz = sin(t)
            let px = (cx < 0 ? -1 : 1) * pow(abs(cx), 2 / exponent) * hw
            let pz = pow(sz, 2 / exponent) * b
            pts.append(V2(px, -(zs + pz)))
        }
        return pts
    }

    /// Deck-mounted centerset or widespread faucet, deck at `at.y`, spout reaching +Z. `spread` is the handle
    /// spacing center to center (0 for a single lever at the spout base), `reach` the spout length.
    public static func faucet(_ m: inout Model, at o: V3, finish: MaterialKey = "metal.chrome", spread: Float = 0.1,
                              reach: Float = 0.11, height: Float = 0.085, hi: Bool = true) {
        let seg = hi ? 20 : 10
        // Escutcheon and spout body.
        m.add(Prim.lathe([V2(0.001, 0), V2(0.026, 0), V2(0.026, 0.0025), V2(0.021, 0.006), V2(0.017, 0.016), V2(0.016, 0.022), V2(0.001, 0.022)],
                         segments: seg, seamTile: 0.05, material: finish), Xform(translation: o))
        let path = catmull([V3(0, 0.02, 0), V3(0, height * 0.7, 0.002), V3(0, height + 0.006, reach * 0.18), V3(0, height, reach * 0.62),
                            V3(0, height - 0.012, reach)], per: hi ? 5 : 2).map { $0 + o }
        let n = path.count
        m.add(Prim.tube(path, radii: (0..<n).map { i in 0.0115 - 0.0018 * Float(i) / Float(n - 1) }, sides: hi ? 14 : 8, seamTile: 0.04, material: finish))
        // Aerator ring at the tip.
        m.add(Prim.cylinder(radius: 0.0108, height: 0.012, bevel: 0.0015, segments: hi ? 14 : 8, material: finish),
              Xform(translation: path[n - 1] + V3(0, -0.009, 0)))
        // Handles.
        let hs: [Float] = spread > 0 ? [-spread / 2, spread / 2] : [0.03]
        for hx in hs {
            let base = V3(hx, 0, 0) + o
            m.add(Prim.lathe([V2(0.001, 0), V2(0.0215, 0), V2(0.0215, 0.002), V2(0.017, 0.007), V2(0.0115, 0.02), V2(0.001, 0.02)],
                             segments: seg, seamTile: 0.05, material: finish), Xform(translation: base))
            let lever = catmull([base + V3(0, 0.018, 0), base + V3(hx < 0 || spread == 0 ? -0.004 : 0.004, 0.04, 0.0), base + V3(hx < 0 || spread == 0 ? -0.03 : 0.03, 0.052, 0.0), base + V3(hx < 0 || spread == 0 ? -0.058 : 0.058, 0.052, 0.0)], per: hi ? 4 : 2)
            m.add(Prim.tube(lever, radii: lever.indices.map { i in i < lever.count - 2 ? Float(0.0058) : Float(0.0072) }, sides: hi ? 10 : 6, seamTile: 0.03, material: finish))
        }
    }
}
