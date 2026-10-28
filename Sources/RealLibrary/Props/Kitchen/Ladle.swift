import simd
import Foundation

/// Stainless ladle resting on its bowl: spun hemispherical bowl with a rolled rim and two pouring lips,
/// stamped flat handle with a center rib rising to a hooked hanging end, spot-welded at the rim. Length along Z.
public struct Ladle: RealAsset {
    public static let id = "ladle"
    public static let summary = "Stainless ladle: rolled-rim bowl with pouring lips, ribbed flat handle rising to a hanging hook, rivets at the join."
    public static let tags = ["prop", "interior", "kitchen", "metal", "tool", "handheld", "cookware"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 0.6, studio: true)

    /// Bowl outer radius (m).
    public var bowlRadius: Float = 0.0475
    /// Bowl finish.
    public var bowlMaterial: MaterialKey = "metal.stainless"
    /// Handle finish.
    public var handleMaterial: MaterialKey = "metal.satin-aluminum"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let R = bowlRadius, c = R, wall: Float = 0.0012
        var prof: [V2] = [V2(0, 0.0004)]
        for i in 0...16 {
            let phi = (-88 + Float(i) * 83 / 16) * .pi / 180
            prof.append(V2(R * cos(phi), c + R * sin(phi)))
        }
        let rimY = c + R * sin(-5 * .pi / 180)
        prof.append(V2(R - 0.0003, rimY + 0.0010))
        prof.append(V2(R - wall * 0.5, rimY + 0.0014))
        for i in 0...16 {
            let phi = (-5 - Float(i) * 83 / 16) * .pi / 180
            prof.append(V2((R - wall) * cos(phi), c + (R - wall) * sin(phi) + 0.0004))
        }
        prof.append(V2(0, 0.0016))
        var bowl = Prim.lathe(prof, segments: 56, seamTile: 0.1, material: bowlMaterial, swapUV: false)
        bowl.deform { p in
            var q = p
            let h = max(0, (p.y - 0.034) / 0.014)
            let g = exp(-(p.x * p.x) / (0.011 * 0.011))
            q.z += (p.z >= 0 ? 1 : -1) * 0.0055 * h * h * g
            return q
        }
        m.add(bowl)
        let path = catmull(DD1BKit.xz([(0.036, 0.036), (0.070, 0.047), (0.115, 0.0585), (0.170, 0.0705), (0.220, 0.0765),
                                       (0.255, 0.0765), (0.272, 0.0695), (0.2775, 0.0565)], y: 0).map { V3($0.x, $0.z, 0) }, per: 6)
        m.add(Prim.sweep(Shape2D.roundedRect(0.014, 0.0035, radius: 0.0012), along: path, up: V3(0, 0, 1), caps: true, material: handleMaterial))
        let ribPath = path.enumerated().filter { $0.offset >= 6 && $0.offset < path.count - 4 }.map { $0.element + V3(0, 0.0021, 0) }
        m.add(Prim.tube(ribPath, radii: ribPath.map { _ in 0.0011 }, sides: 6, seamTile: 0.02, material: handleMaterial, capEnd: true))
        for z: Float in [-0.0035, 0.0035] {
            rivet(&m, at: V3(0.055, 0.0406, z), normal: .up, radius: 0.0021, material: handleMaterial)
        }
        return DD1BKit.finish(m, rng: &rng)
    }
}
