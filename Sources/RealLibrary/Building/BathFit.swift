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
}
