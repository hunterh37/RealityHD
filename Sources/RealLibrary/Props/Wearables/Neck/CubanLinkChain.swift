import simd
import Foundation

/// Gold Cuban (curb) link chain worn at the base of the neck: 40 individually modelled oval links, each
/// rolled 45 degrees from its neighbour so the chain lies flat, a lobster clasp with jump ring and a
/// stamped 10K tag at the back, one link knocked out of line. Hangs in a V to the sternum.
public struct CubanLinkChain: RealAsset {
    public static let id = "cuban-link-chain"
    public static let summary = "Worn gold Cuban link chain: individual interlocked oval links, lobster clasp, hallmark tag."
    public static let tags = ["prop", "wearable", "worn", "jewelry", "metal", "gold"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 14, distance: 0.7, ground: false, studio: true)

    /// Chain metal.
    public var metal: MaterialKey = "metal.gold"
    /// Wire radius (m).
    public var wire: Float = 0.0022
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let rx: Float = 0.068, rz0: Float = 0.064
        /// Worn path: round the neck at the back, V down to the sternum at the front.
        func point(_ th: Float) -> V3 {
            let f = (1 + cos(th)) / 2
            let y = 0.006 - 0.176 * pow(f, 1.6)
            return V3(sin(th) * (rx + 0.012 * f), y, cos(th) * (rz0 + 0.026 * pow(f, 1.5)))
        }
        let delta: Float = 0.17
        // Dense polyline from the back-left clasp end through the front to the back-right end.
        var dense: [V3] = [], thetas: [Float] = []
        let steps = 900
        for k in 0...steps {
            let th = -Float.pi + delta + (2 * Float.pi - 2 * delta) * Float(k) / Float(steps)
            dense.append(point(th)); thetas.append(th)
        }
        var cum: [Float] = [0]
        for i in 1..<dense.count { cum.append(cum[i - 1] + simd_distance(dense[i - 1], dense[i])) }
        let total = cum.last!
        let pitch = wire * 7
        func at(_ s: Float) -> (V3, Float) {
            var lo = 0, hi = cum.count - 1
            while hi - lo > 1 { let mid = (lo + hi) / 2; if cum[mid] <= s { lo = mid } else { hi = mid } }
            let t = (s - cum[lo]) / max(cum[hi] - cum[lo], 1e-9)
            return (lerp(dense[lo], dense[hi], t), lerp(thetas[lo], thetas[hi], t))
        }
        func linkShape(segments: Int, sides: Int) -> Surface {
            let w = wire * 2 * 1.75
            let outline = Shape2D.roundedRect(pitch + wire * 2, w + wire * 2, radius: (w + wire * 2) / 2 * 0.999, segments: segments)
                .map { V3($0.x, $0.y, 0) }
            return Prim.sweep(Shape2D.circle(wire * 0.78, ry: wire * 1.12, segments: sides), along: outline, up: V3(0, 0, 1),
                              closedPath: true, caps: false, material: metal)
        }
        let hi = linkShape(segments: 8, sides: 6), lo = linkShape(segments: 3, sides: 6)
        let count = Int((total - pitch * 0.5) / pitch)
        let flipped = 17
        for i in 0..<count {
            let s = pitch * 0.5 + Float(i) * pitch
            let (p, th) = at(s)
            let (pa, _) = at(max(0, s - pitch * 0.5)), (pb, _) = at(min(total, s + pitch * 0.5))
            let d = simd_normalize(pb - pa)
            // Gravity makes the plane of each link settle toward the body surface.
            var roll = Float.pi / 4 + Float(i % 2) * Float.pi / 2 + rng.float(-0.08...0.08)
            if i == flipped { roll += 0.55 }
            let q = simd_quatf(angle: roll, axis: d) * simd_quatf(from: V3(1, 0, 0), to: d)
            m.add(abs(th) < 1.45 ? hi : lo, Xform(translation: p, rotation: q))
        }
        // Clasp at the back: lobster claw on the +X end, jump ring and hallmark tag on the -X end.
        let eR = dense.last!, eL = dense.first!
        let lobster = Prim.lathe([V2(0, -0.0075), V2(0.0016, -0.0072), V2(0.0033, -0.0045), V2(0.0038, 0), V2(0.0033, 0.0045),
                                  V2(0.0018, 0.0072), V2(0, 0.0076)], segments: 32, seamTile: 0.02, material: metal)
        let lq = simd_quatf(degrees: -90, axis: V3(0, 0, 1))
        m.add(lobster, Xform(translation: eR + V3(-0.0075, 0, 0.0004), rotation: lq, scale: V3(1, 1, 0.62)))
        let claw = catmull([V3(0.0015, 0.0006, 0), V3(-0.0035, 0.0034, 0), V3(-0.0072, 0.0016, 0)], per: 5)
        m.add(Prim.tube(claw, radii: claw.map { _ in 0.0007 }, sides: 8, seamTile: 0.01, material: metal),
              Xform(translation: eR + V3(-0.0135, 0.0004, 0.0012)))
        let ring = Prim.torus(major: 0.0034, minor: 0.00085, segments: 32, sides: 8, material: metal)
        m.add(ring, Xform(translation: eL + V3(0.0036, 0, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        m.add(ring, Xform(translation: eR + V3(-0.0152, 0, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        let tagOutline = Shape2D.roundedRect(0.0085, 0.0042, radius: 0.0014, segments: 4)
        m.add(Prim.extrude(tagOutline, depth: 0.0008, bevel: 0.0003, bevelSegments: 2, material: "metal.gold"),
              Xform(translation: eL + V3(0.0095, -0.0025, -0.0006), rotation: simd_quatf(degrees: 14, axis: V3(0, 0, 1))))
        return LODModel(m)
    }
}
