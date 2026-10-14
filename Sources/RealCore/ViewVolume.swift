import simd

/// A view frustum as six inward-facing planes. Sphere tests are conservative (a sphere touching the
/// volume counts as inside), matching how RealityKit culls by entity bounds.
public struct ViewFrustum: Sendable, Equatable {
    /// (normal, d): a point p is inside when dot(normal, p) + d >= 0 for every plane.
    public var planes: [SIMD4<Float>]

    /// `forward` and `up` need not be orthogonal; `up` is re-orthogonalized. Angles are full angles in degrees.
    public init(eye: V3, forward: V3, up: V3 = V3(0, 1, 0), horizontalFov: Float, verticalFov: Float,
                near: Float = 0.05, far: Float = 10_000) {
        let f = simd_normalize(forward)
        var r = simd_cross(f, up)
        if simd_length(r) < 1e-4 { r = simd_cross(f, V3(0, 0, 1)) }
        r = simd_normalize(r)
        let u = simd_cross(r, f)
        let th = tanf(horizontalFov * .pi / 360), tv = tanf(verticalFov * .pi / 360)
        func plane(_ n: V3, _ p: V3) -> SIMD4<Float> { let n = simd_normalize(n); return SIMD4(n, -simd_dot(n, p)) }
        planes = [
            plane(f, eye + f * near),
            plane(-f, eye + f * far),
            plane(f * th + r, eye),     // left plane: normal points right-inward
            plane(f * th - r, eye),     // right plane
            plane(f * tv + u, eye),     // bottom
            plane(f * tv - u, eye),     // top
        ]
    }

    public func intersects(center: V3, radius: Float) -> Bool {
        for p in planes where simd_dot(SIMD3(p.x, p.y, p.z), center) + p.w < -radius { return false }
        return true
    }
}

/// What the headset sees: the union of the two eye frustums. Apple Vision Pro defaults: 64 mm IPD and a
/// per-eye field of view of about 100 x 90 degrees (wider than any preview camera, so the scene camera's
/// `fov` is not used).
public struct ViewVolume: Sendable, Equatable {
    public var eyes: [ViewFrustum]
    public var center: V3
    public var forward: V3

    public static let deviceHorizontalFov: Float = 100
    public static let deviceVerticalFov: Float = 90
    public static let deviceIPD: Float = 0.064

    public init(eye: V3, target: V3, up: V3 = V3(0, 1, 0), horizontalFov: Float = ViewVolume.deviceHorizontalFov,
                verticalFov: Float = ViewVolume.deviceVerticalFov, ipd: Float = ViewVolume.deviceIPD, far: Float = 10_000) {
        var f = target - eye
        if simd_length(f) < 1e-5 { f = V3(0, 0, -1) }
        self.init(eye: eye, forward: f, up: up, horizontalFov: horizontalFov, verticalFov: verticalFov, ipd: ipd, far: far)
    }

    public init(eye: V3, forward: V3, up: V3 = V3(0, 1, 0), horizontalFov: Float = ViewVolume.deviceHorizontalFov,
                verticalFov: Float = ViewVolume.deviceVerticalFov, ipd: Float = ViewVolume.deviceIPD, far: Float = 10_000) {
        let f = simd_normalize(forward)
        var r = simd_cross(f, up)
        if simd_length(r) < 1e-4 { r = V3(1, 0, 0) }
        r = simd_normalize(r)
        center = eye; self.forward = f
        eyes = [-0.5, 0.5].map { s in
            ViewFrustum(eye: eye + r * (ipd * s), forward: f, up: up, horizontalFov: horizontalFov, verticalFov: verticalFov, far: far)
        }
    }

    /// True when either eye sees any part of the sphere.
    public func intersects(center: V3, radius: Float) -> Bool {
        eyes.contains { $0.intersects(center: center, radius: radius) }
    }

    /// Shadow-pass test for a caster: its shadow can land in view when the sphere, stretched along the
    /// light by `shadowLength`, touches the view. `toLight` points from the scene toward the sun.
    public func castsIntoView(center: V3, radius: Float, toLight: V3, shadowLength: Float) -> Bool {
        let d = -simd_normalize(toLight)
        // Sample the swept capsule with spheres spaced by the radius (at most 8).
        let n = max(1, min(8, Int(ceilf(shadowLength / max(radius, 0.25)))))
        for i in 0...n {
            let c = center + d * (shadowLength * Float(i) / Float(n))
            if intersects(center: c, radius: radius) { return true }
        }
        return false
    }
}
