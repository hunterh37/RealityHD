import simd
import RealCore
import RealKit

public extension RealScene {
    /// Whether `shadowResolved` culls sun-blocked casters for this scene.
    var cullsSunBlockedCasters: Bool { cullSunBlockedCasters ?? (lighting.interior != nil && lighting.sky != nil) }

    /// `statics` with `castsShadow` cleared on interior statics the sun cannot reach. The occluders are the
    /// room shell: singles marked `bake` and singles larger than `shellSize`, which keep casting. A static
    /// keeps casting when any of 27 probes (a 3 x 3 x 3 grid over its bounds, pulled 5 % inward) has a
    /// clear ray toward the sun: a shadow lands only where the object sits between a lit point and the sun.
    func shadowResolved(_ statics: [Single], shellSize: Float = 4) -> [Single] {
        guard cullsSunBlockedCasters, let sky = lighting.sky else { return statics }
        let toSun = simd_normalize(sky.sunDirection)
        func isShell(_ s: Single) -> Bool { s.bake || s.asset.levels[0].boundsDiagonal * s.at.scale.max() > shellSize }
        var tris: [V3] = []
        for s in statics where isShell(s) {
            let m = s.asset.levels[0].transformed(s.at)
            for surf in m.surfaces where MaterialLibrary.spec(for: surf.material).mode != .transparent {
                for i in surf.indices { tris.append(surf.positions[Int(i)]) }
            }
        }
        guard !tris.isEmpty else { return statics }
        let bvh = BVH(triangles: tris)
        return statics.map { s in
            guard s.castsShadow, !isShell(s) else { return s }
            let b = s.asset.levels[0].bounds
            let c = (b.min + b.max) / 2, h = (b.max - b.min) / 2 * 0.95
            var probes: [V3] = []
            for x: Float in [-1, 0, 1] { for y: Float in [-1, 0, 1] { for z: Float in [-1, 0, 1] { probes.append(c + h * V3(x, y, z)) } } }
            let lit = probes.contains { p in bvh.firstHit(s.at.point(p) + toSun * 0.01, toSun, tMax: 1000) == nil }
            var o = s
            o.castsShadow = lit
            return o
        }
    }
}
