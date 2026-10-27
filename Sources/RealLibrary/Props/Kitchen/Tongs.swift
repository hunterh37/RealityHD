import simd
import Foundation

/// Spring tongs lying on their edge: one folded stainless band forms both arms and the spring bend,
/// scalloped flat tips, and a sliding lock ring. Length along Z.
public struct Tongs: RealAsset {
    public static let id = "tongs"
    public static let summary = "Stainless spring tongs: folded band arms, scalloped tips, sliding lock ring."
    public static let tags = ["prop", "interior", "kitchen", "metal", "tool", "handheld", "cookware"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 50, distance: 0.55, studio: true)

    /// Arm band finish.
    public var armMaterial: MaterialKey = "metal.stainless"
    /// Lock ring finish.
    public var ringMaterial: MaterialKey = "metal.satin-aluminum"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let y: Float = 0.0105
        let r: Float = 0.0068, cx: Float = -0.128
        let arm = catmull(DD1BKit.xz([(0.148, 0.0225), (0.12, 0.0205), (0.07, 0.0150), (0.0, 0.0098), (-0.07, 0.0072), (cx, r)], y: y), per: 6)
        var path = arm
        for k in 1..<6 {
            let phi = Float(k) / 6 * .pi
            path.append(V3(cx - r * sin(phi), y, r * cos(phi)))
        }
        path += arm.reversed().map { V3($0.x, $0.y, -$0.z) }
        m.add(Prim.sweep(Shape2D.roundedRect(0.018, 0.0024, radius: 0.0009), along: path, up: .up, caps: true, material: armMaterial))
        for s: Float in [-1, 1] {
            let zc = s * 0.0225
            var pts: [V2] = [V2(0.128, zc + s * 0.0012), V2(0.158, zc + s * 0.0012)]
            for i in 0...32 {
                let t = Float(i) / 32
                pts.append(V2(0.158 - 0.026 * t, zc - s * (0.0057 - 0.0013 * abs(sin(t * 4 * .pi)))))
            }
            pts.append(V2(0.128, zc - s * 0.0012))
            m.add(DD1BKit.flat(pts, thick: 0.0185, y: y, bevel: 0.0007, material: armMaterial))
        }
        let ring = Shape2D.roundedRect(0.0200, 0.0165, radius: 0.004).map { V3(-0.065, y + $0.y, $0.x) }
        m.add(Prim.sweep(Shape2D.circle(0.0014, segments: 8), along: ring, up: V3(1, 0, 0), closedPath: true, caps: false, material: ringMaterial))
        return DD1BKit.finish(m, rng: &rng)
    }
}
