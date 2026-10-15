import simd
import Foundation

/// Bean bag chair, 90 x 60 x 90 cm: a slumped six-gore teardrop body of upholstery fabric with a wide flat base, a high
/// back, a seated dent at the front, soft sag wrinkles, white-thread seam piping between the gores and around the base, a
/// canvas webbing carry handle on the back and a zipper tape with a pull low at the rear.
public struct BeanBag: RealAsset {
    public static let id = "bean-bag"
    public static let summary = "Bean bag chair, 0.9 x 0.6 x 0.9 m: slumped fabric body with seat dent, panel seams, piping and carry handle."
    public static let tags = ["prop", "floorplan", "living", "furniture", "fabric", "interior"]
    public static let budget = 14500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 18, distance: 0.95, studio: true)

    /// Overall size in meters (x width, y height with the handle, z depth); the seat dent faces +Z.
    public var size = V3(0.9, 0.6, 0.9)
    /// Body fabric.
    public var fabric: MaterialKey = "fabric.upholstery:46606E"
    /// Piping and handle webbing.
    public var trim: MaterialKey = "fabric.canvas:D9D2BF"
    /// Gore count around the body.
    public var gores = 6
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, sub: 22, ring: 40), model(seed: seed, sub: 12, ring: 20)], switchDistances: [3.5])
    }

    func model(seed: UInt64, sub: Int, ring: Int) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let ph1 = rng.float(0...6.28), ph2 = rng.float(0...6.28), ph3 = rng.float(0...6.28)

        // Raw slumped shape from a unit direction: a disc footprint with a rounded flat base, a high back, rolled arms, a
        // seat dent toward +Z, radial gathers near the edge and soft sag folds.
        func raw(_ u: V3) -> V3 {
            let R: Float = 0.45
            let r = min(1, sqrt(u.x * u.x + u.z * u.z))
            let ang = atan2(u.z, u.x)
            let gather = 1 + 0.02 * sin(ang * 9 + ph1) * smoothstep(0.5, 1, r) + 0.012 * sin(ang * 5 + ph2)
            let belly = 1 + 0.07 * sin(Float.pi * min(1, max(0, u.y + 0.1) / 0.5)) * (u.y > -0.1 ? 1 : 0)
            let x = u.x * R * gather * belly, z = u.z * R * gather * belly
            if u.y < 0 { return V3(x, u.y * 0.06, z) }
            let t = smoothstep(-0.1, 0.8, -z / R)                      // back weight
            let arm = smoothstep(0.12, 0.38, abs(x)) * smoothstep(0.7, -0.2, z / R)
            var h: Float = 0.30 + 0.24 * t + 0.07 * arm
            h -= 0.085 * exp(-(x * x / 0.025 + (z - 0.1) * (z - 0.1) / 0.04))      // seat dent
            let fold = 0.014 * sin(x * 19 + ph1 + 2 * sin(z * 11 + ph2)) * sin(z * 15 + ph3) + 0.007 * sin(x * 31 + z * 23 + ph2)
            let wall = pow(u.y, 0.5)
            return V3(x, (h + fold * smoothstep(0, 0.3, u.y)) * wall, z - 0.03 * t * wall)
        }
        // Fit raw extents to the brief size (height leaves room for the handle).
        var lo = V3(repeating: Float.greatestFiniteMagnitude), hi = V3(repeating: -Float.greatestFiniteMagnitude)
        for d in Prim.cubeSphereDirections(subdivisions: 28) { let p = raw(d); lo = simd_min(lo, p); hi = simd_max(hi, p) }
        let handleRise: Float = 0.055
        let target = V3(size.x, size.y - handleRise - 0.03, size.z)
        let k = target / (hi - lo)
        func body(_ u: V3) -> V3 { (raw(u) - (lo + hi) / 2) * k + V3(0, target.y / 2, 0) }
        /// Surface point plus an outward offset.
        func skin(_ u: V3, _ off: Float) -> V3 { body(u) + simd_normalize(u * V3(1, 1, 1)) * off }
        func dir(_ theta: Float, _ phi: Float) -> V3 { V3(cos(theta) * cos(phi), sin(phi), sin(theta) * cos(phi)) }

        m.add(Prim.cubeSphere(subdivisions: sub, material: fabric) { body($0) })

        let piping: MaterialKey = trim
        let pr: Float = 0.0065
        // Gore seams from the base ring to the crown, following the surface.
        let n = max(3, gores)
        for g in 0..<n {
            let th = Float(g) / Float(n) * 2 * .pi + 0.3
            var path: [V3] = []
            for i in 0...ring / 2 {
                let phi = -0.08 + (Float(i) / Float(ring / 2)) * (1.52 + 0.08)
                path.append(skin(dir(th, phi), 0.0015))
            }
            m.add(Prim.sweep(Shape2D.circle(pr * 0.85, segments: 5), along: path, caps: true, material: piping))
        }
        // Base piping ring.
        var baseRing: [V3] = []
        for i in 0..<ring { baseRing.append(skin(dir(Float(i) / Float(ring) * 2 * .pi, -0.08), 0.0015)) }
        m.add(Prim.sweep(Shape2D.circle(pr, segments: 6), along: baseRing, closedPath: true, caps: false, material: piping))

        // Top-stitching either side of the base piping and the gore seams (full detail only).
        if ring >= 40 {
            func sewn(_ phi0: Float, _ phi1: Float, _ th: Float, _ dth: Float) {
                var pth: [V3] = []
                for i in 0...20 { let phi = phi0 + (phi1 - phi0) * Float(i) / 20; pth.append(skin(dir(th + dth, phi), 0.001)) }
                m.add(stitches(along: pth, normal: { simd_normalize($0 - V3(0, 0.2, 0)) }, pitch: 0.016, thread: 0.0007, material: "thread.white"))
            }
            for g in 0..<n { let th = Float(g) / Float(n) * 2 * .pi + 0.3; sewn(0.05, 1.3, th, 0.045); sewn(0.05, 1.3, th, -0.045) }
            for off: Float in [-0.075, 0.075] {
                var rp: [V3] = []
                for i in 0..<ring * 2 { rp.append(skin(dir(Float(i) / Float(ring * 2) * 2 * .pi, -0.08 + off), 0.001)) }
                rp.append(rp[0])
                m.add(stitches(along: rp, normal: { simd_normalize($0 - V3(0, 0.2, 0)) }, pitch: 0.016, thread: 0.0007, material: "thread.white"))
            }
        }

        // Crown: the gores meet under a small stitched cap.
        let top = body(V3(0.0, 1, 0.0))
        m.add(Prim.superellipsoid(V3(0.05, 0.022, 0.05), exponent: 2.2, subdivisions: 2, material: fabric), Xform(translation: top + V3(0, 0.002, 0)))

        // Carry handle: flat webbing loop on the upper back, sewn down with box-stitch patches.
        let hb = body(simd_normalize(V3(0, 0.82, -0.58)))
        let hw: Float = 0.085
        let hp: [V3] = [V3(-hw, -0.004, 0.0), V3(-hw, 0.03, -0.01), V3(-hw * 0.6, 0.062, -0.02), V3(0, 0.074, -0.022), V3(hw * 0.6, 0.062, -0.02), V3(hw, 0.03, -0.01), V3(hw, -0.004, 0.0)]
        m.add(Prim.sweep(Shape2D.roundedRect(0.036, 0.007, radius: 0.0025, segments: 2), along: catmull(hp.map { $0 + hb }, per: 4), up: V3(0, 0, 1),
                         caps: true, material: trim))
        for s: Float in [-1, 1] {
            m.add(Prim.superellipsoid(V3(0.075, 0.012, 0.07), exponent: 3, subdivisions: 2, material: trim),
                  Xform(translation: hb + V3(s * hw, -0.004, 0), rotation: simd_quatf(degrees: -30, axis: V3(1, 0, 0))))
            m.add(stitches(along: [hb + V3(s * hw - 0.032, 0.002, -0.004), hb + V3(s * hw + 0.032, 0.002, -0.004), hb + V3(s * hw + 0.032, 0.002, 0.03), hb + V3(s * hw - 0.032, 0.002, 0.03), hb + V3(s * hw - 0.032, 0.002, -0.004)],
                            normal: { _ in V3(0, 1, 0) }, pitch: 0.007, thread: 0.0007, material: "thread.white"))
        }

        // Rear zipper: black tape along a low arc with steel teeth and a pull.
        var zipPath: [V3] = []
        for i in 0...16 { zipPath.append(skin(dir(.pi * (1.18 + 0.64 * Float(i) / 16), 0.2), 0.0016)) }
        m.add(Prim.sweep(Shape2D.roundedRect(0.022, 0.0025, radius: 0.001, segments: 1), along: zipPath, up: V3(0, 1, 0), caps: true, material: "plastic.black:1B1B1D"))
        m.add(Prim.sweep(Shape2D.circle(0.0028, segments: 4), along: zipPath.map { $0 + simd_normalize($0 - V3(0, 0.25, 0)) * 0.0015 }, caps: true, material: "metal.stainless"))
        let zs = zipPath[5]
        let zn = simd_normalize(zs - V3(0, 0.25, 0))
        m.add(Prim.roundedBox(V3(0.026, 0.02, 0.008), radius: 0.002, bevelSegments: 1, material: "metal.stainless"), Xform(translation: zs + zn * 0.006, rotation: facing(zn)))
        m.add(Prim.roundedBox(V3(0.008, 0.032, 0.003), radius: 0.0015, bevelSegments: 1, material: "metal.stainless"), Xform(translation: zs + zn * 0.012 + V3(0, -0.02, 0), rotation: facing(zn)))
        // Care label sewn into the base piping near the zipper.
        let lb = skin(dir(.pi * 1.1, -0.08), 0.003)
        m.add(Prim.roundedBox(V3(0.04, 0.05, 0.002), radius: 0.0005, bevelSegments: 1, material: "paper.sheet"), Xform(translation: lb, rotation: facing(simd_normalize(lb - V3(0, 0.2, 0)))))

        // Authoring frame: centered on X/Z, base at y = 0 (bags settle a few mm into the floor).
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y - 0.004, -(bb.min.z + bb.max.z) / 2)))
        groundAO(&m, height: 0.28, floor: 0.4)
        return m
    }
}
