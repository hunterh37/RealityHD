import simd
import Foundation

/// Light cycle, 2.6 m nose to tail: one lofted carbon fairing (64 stations, 48 radial points) under deep clearcoat, a lifting
/// smoked canopy, two solid-disc wheels with a glowing rim torus (128 by 8, see the handoff for the triangle budget), forks,
/// handlebar, cyan rim lines along the flanks and a rear light-wall emitter slot. Origin at the centre of the wheelbase on the
/// ground, nose toward +Z, up +Y. Wheel radius 0.46 m, wheelbase 1.9 m.
/// Joints: `spin` 0...1 (one wheel turn per unit, both wheels), `lean` -1...1 (body banks 35 degrees about the ground line,
/// positive toward +X), `glow` 0...1 (rim lines, wheel rims and emitter switch dim to bright at 0.5), `canopy` 0...1 (canopy
/// lifts 38 degrees at the nose).
public struct LightCycle: RealArticulated {
    public static let id = "light-cycle"
    public static let summary = "Light cycle, 2.6 m: carbon clearcoat fairing, smoked canopy, solid-disc wheels with glowing rim torus, cyan rim lines, light-wall slot, joints spin, lean, glow, canopy."
    public static let tags = ["prop", "vehicle", "neon", "scifi", "outdoor", "articulated"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 42, elevation: 12, distance: 1.0, ground: false, studio: true)

    /// Fairing shell: dark carbon basecoat under clearcoat.
    public var shell: MaterialKey = "paint.car-clearcoat:090B10"
    /// Canopy.
    public var canopy: MaterialKey = "glass.window-tint"
    /// Wheel discs, fork legs and engine pods.
    public var disc: MaterialKey = "metal.anodized-black"
    /// Hub caps and handlebar.
    public var trim: MaterialKey = "metal.chrome"
    /// Handlebar grips.
    public var grip: MaterialKey = "rubber.silicone"
    /// Rim lines, wheel rims and emitter at glow below 0.5.
    public var glowDim: MaterialKey = "emissive.holo-grid"
    /// Rim lines, wheel rims and emitter at glow 0.5 and above.
    public var glowBright: MaterialKey = "emissive.holo-plane"
    public init() {}

    // MARK: Profile (z ascending from tail to nose)

    private static let pz: [Float] = [-1.3, -1.0, -0.6, -0.2, 0.2, 0.6, 1.0, 1.3]
    private static let pw: [Float] = [0.04, 0.08, 0.22, 0.30, 0.30, 0.20, 0.07, 0.03]
    private static let pt: [Float] = [0.03, 0.10, 0.20, 0.26, 0.24, 0.14, 0.08, 0.03]
    private static let pb: [Float] = [0.03, 0.10, 0.16, 0.20, 0.20, 0.14, 0.08, 0.03]
    private static let pc: [Float] = [0.62, 0.60, 0.58, 0.60, 0.62, 0.66, 0.62, 0.55]
    private static let wheelZ: Float = 0.95
    private static let wheelR: Float = 0.46
    private static let canopyPivot = V3(0, 0.80, -0.45)

    private static func hermite(_ xs: [Float], _ ys: [Float], _ x0: Float) -> Float {
        let x = min(max(x0, xs[0]), xs[xs.count - 1])
        var i = 0
        while i < xs.count - 2 && x > xs[i + 1] { i += 1 }
        func tan(_ j: Int) -> Float {
            let a = max(0, j - 1), b = min(xs.count - 1, j + 1)
            return (ys[b] - ys[a]) / (xs[b] - xs[a])
        }
        let h = xs[i + 1] - xs[i], u = (x - xs[i]) / h
        let u2 = u * u, u3 = u2 * u
        return (2 * u3 - 3 * u2 + 1) * ys[i] + (u3 - 2 * u2 + u) * h * tan(i) + (-2 * u3 + 3 * u2) * ys[i + 1] + (u3 - u2) * h * tan(i + 1)
    }
    private static func sgnPow(_ x: Float, _ e: Float) -> Float { x < 0 ? -pow(-x, e) : pow(x, e) }
    private static func prof(_ z: Float) -> (w: Float, t: Float, b: Float, c: Float) {
        (max(0.02, hermite(pz, pw, z)), max(0.02, hermite(pz, pt, z)), max(0.02, hermite(pz, pb, z)), hermite(pz, pc, z))
    }

    /// Fairing cross-section at `z`: closed ring of `n` points in the XY plane, counterclockwise seen from +Z
    /// (point 0 at +X, a quarter turn is the roof).
    private static func fairingRing(_ z: Float, n: Int) -> [V3] {
        let p = prof(z)
        let e: Float = 2 / 2.6
        return (0..<n).map { k in
            let a = 2 * Float.pi * Float(k) / Float(n)
            let cs = cos(a), sn = sin(a)
            return V3(p.w * sgnPow(cs, e), p.c + (sn >= 0 ? p.t : p.b) * sgnPow(sn, e), z)
        }
    }

    /// Wheel body: solid disc with a rounded shoulder, axis along X, centred on the origin.
    private static func wheelDisc(material: MaterialKey) -> Surface {
        let prof: [(x: Float, r: Float)] = [(-0.085, 0.30), (-0.07, 0.395), (0.07, 0.395), (0.085, 0.30)]
        let n = 64
        let rings: [[V3]] = prof.map { s in
            (0..<n).map { k in
                let a = 2 * Float.pi * Float(k) / Float(n)
                return V3(s.x, s.r * cos(a), s.r * sin(a))
            }
        }
        return Prim.loft(rings, capStart: true, capEnd: true, material: material)
    }

    /// Torus around the X axis at x offset `x`.
    private static func ringX(major: Float, minor: Float, segments: Int, sides: Int, x: Float, material: MaterialKey) -> Surface {
        Prim.torus(major: major, minor: minor, segments: segments, sides: sides, material: material)
            .transformed(Xform(translation: V3(x, 0, 0), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
    }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 1)
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)
        let wz = Self.wheelZ, wr = Self.wheelR

        // Drivers first so mimics resolve.
        _ = rig.part("spin", pivot: .zero, joint: .hinge(axis: X, 0...1, duration: 1.2))
        _ = rig.part("lean", pivot: .zero, joint: .hinge(axis: Z, -1...1, duration: 0.9))
        _ = rig.part("glow", pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.5))
        _ = rig.part("canopy", pivot: .zero, joint: .hinge(axis: X, 0...1, duration: 1.0))
        // Body bank about the ground line through both contact patches.
        _ = rig.part("bank", pivot: .zero, joint: Joint(.revolute, axis: Z, range: -40...40, mimic: .init("lean", ratio: 35)))
        _ = rig.part("wheelF", parent: "bank", pivot: V3(0, wr, wz), joint: Joint(.revolute, axis: X, range: -400...400, mimic: .init("spin", ratio: 360)))
        _ = rig.part("wheelR", parent: "bank", pivot: V3(0, wr, -wz), joint: Joint(.revolute, axis: X, range: -400...400, mimic: .init("spin", ratio: 360)))
        _ = rig.part("rimF", parent: "wheelF", pivot: V3(0, wr, wz), joint: .fixed, options: 2)
        _ = rig.part("rimR", parent: "wheelR", pivot: V3(0, wr, -wz), joint: .fixed, options: 2)
        _ = rig.part("lines", parent: "bank", pivot: .zero, joint: .fixed, options: 2)
        _ = rig.part("hood", parent: "bank", pivot: Self.canopyPivot, joint: Joint(.revolute, axis: X, range: -40...0, mimic: .init("canopy", ratio: -38)))

        // Fairing: 64 stations, 48 radial points, caps close the tail and nose tips.
        let zs = (0..<64).map { -1.3 + 2.6 * Float($0) / 63 }
        rig.add(Prim.loft(zs.map { Self.fairingRing($0, n: 48) }, capStart: true, capEnd: true, material: shell), to: "bank")

        // Wheels: carbon disc, glowing rim torus 128 by 8 at the shoulder, chrome hub ring on the +X face.
        for (name, rim, z) in [("wheelF", "rimF", wz), ("wheelR", "rimR", -wz)] {
            let at = Xform(translation: V3(0, wr, z))
            rig.add(Self.wheelDisc(material: disc), at, to: name)
            rig.add(Self.ringX(major: 0.12, minor: 0.014, segments: 24, sides: 6, x: 0.088, material: trim), at, to: name)
            for (opt, mat) in [(0, glowDim), (1, glowBright)] {
                rig.add(Self.ringX(major: 0.40, minor: 0.055, segments: 128, sides: 8, x: 0, material: mat), at, to: rim, option: opt)
            }
        }

        // Forks: two legs per wheel from the wheel axle up into the fairing, on both sides of the disc.
        for side: Float in [1, -1] {
            let f = [V3(side * 0.12, wr, wz), V3(side * 0.12, 0.62, wz - 0.05), V3(side * 0.10, 0.78, wz - 0.22)]
            rig.add(Prim.tube(f, radii: [0.022, 0.026, 0.030], sides: 8, seamTile: 0.1, material: disc), to: "bank")
            let r = [V3(side * 0.12, wr, -wz), V3(side * 0.12, 0.62, -wz + 0.05), V3(side * 0.10, 0.74, -wz + 0.22)]
            rig.add(Prim.tube(r, radii: [0.022, 0.026, 0.030], sides: 8, seamTile: 0.1, material: disc), to: "bank")
        }

        // Handlebar: chrome bar across the nose with two grips and short risers.
        for side: Float in [1, -1] {
            let bar = [V3(side * 0.04, 0.80, 0.52), V3(side * 0.18, 0.84, 0.54), V3(side * 0.30, 0.86, 0.50)]
            rig.add(Prim.tube(bar, radii: [0.016, 0.016, 0.016], sides: 8, seamTile: 0.1, material: trim), to: "bank")
            rig.add(Prim.tube([bar[2], bar[2] + V3(side * 0.10, 0.005, -0.03)], radii: [0.022, 0.022], sides: 8, seamTile: 0.1, material: grip), to: "bank")
        }

        // Engine pods: dark cylinders either side of the tail with a cyan intake ring.
        for side: Float in [1, -1] {
            let pod = [V3(side * 0.30, 0.50, -0.95), V3(side * 0.30, 0.50, -0.45)]
            rig.add(Prim.tube(pod, radii: [0.075, 0.095], sides: 12, seamTile: 0.1, material: disc), to: "bank")
        }

        // Rim lines: a cyan line along each flank at the widest stations, plus a roof spine.
        for side: Float in [1, -1] {
            var path: [V3] = []
            for k in 0..<24 {
                let z = -1.05 + 2.05 * Float(k) / 23
                let p = Self.prof(z)
                path.append(V3(side * p.w * 1.01, p.c + 0.02, z))
            }
            let radii = path.map { _ in Float(0.012) }
            for (opt, mat) in [(0, glowDim), (1, glowBright)] {
                rig.add(Prim.tube(path, radii: radii, sides: 6, seamTile: 0.1, material: mat), to: "lines", option: opt)
            }
        }
        // Light-wall emitter slot on the tail: a thin glowing bar across the rear stations.
        let tailP = Self.prof(-1.22)
        for (opt, mat) in [(0, glowDim), (1, glowBright)] {
            let slot = Prim.tube([V3(-0.11, tailP.c + 0.01, -1.24), V3(0.11, tailP.c + 0.01, -1.24)], radii: [0.012, 0.012], sides: 6, seamTile: 0.1, material: mat)
            rig.add(slot, to: "lines", option: opt)
        }

        // Canopy: smoked bubble lofted over the rider bay, hinged at the rear edge, lifts at the nose.
        let cz: [Float] = [-0.45, -0.38, -0.25, -0.05, 0.12, 0.28, 0.36]
        let ch: [Float] = [0.0, 0.14, 0.24, 0.27, 0.22, 0.12, 0.0]
        let cw: [Float] = [0.0, 0.16, 0.24, 0.26, 0.22, 0.14, 0.0]
        let cn = 28
        let cr: [[V3]] = (0..<cz.count).map { i in
            let w = max(0.012, cw[i]), h = max(0.012, ch[i])
            return (0..<cn).map { k in
                let a = Float.pi * Float(k) / Float(cn / 2)   // full ring; lower half squashed flat into the fairing
                let up = sin(a) >= 0
                return V3(w * cos(a), Self.canopyPivot.y + (up ? h * sin(a) : 0.012 * sin(a)), cz[i])
            }
        }
        rig.add(Prim.loft(cr, capStart: true, capEnd: true, material: canopy), to: "hood")

        // Lights ride on the rim lines: dim cyan at rest, bright above glow 0.5.
        rig.lights = [
            RigLight(name: "rim-dim", part: "lines", option: 0, position: V3(0, 0.45, 0), color: V3(0.1, 0.5, 0.8), intensity: 120, attenuationRadius: 2.5),
            RigLight(name: "rim-bright", part: "lines", option: 1, position: V3(0, 0.45, 0), color: V3(0.2, 0.8, 1.0), intensity: 650, attenuationRadius: 5),
        ]
        rig.optionLinks = [
            RigOptionLink(part: "lines", joint: "glow", thresholds: [0.5]),
            RigOptionLink(part: "rimF", joint: "glow", thresholds: [0.5]),
            RigOptionLink(part: "rimR", joint: "glow", thresholds: [0.5]),
        ]
        let on: [String: Int] = ["lines": 1, "rimF": 1, "rimR": 1]
        rig.states = [
            RigState("rest"),
            RigState("ride", ["spin": 0.5, "glow": 1], options: on),
            RigState("lean-left", ["lean": -1, "spin": 0.25, "glow": 1], options: on),
            RigState("lean-right", ["lean": 1, "spin": 0.25, "glow": 1], options: on),
            RigState("canopy-open", ["canopy": 1]),
            RigState("derezz", ["glow": 1, "canopy": 1], options: on),
        ]
        return rig
    }
}
