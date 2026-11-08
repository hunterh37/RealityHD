import simd
import Foundation

/// Siege walker, 22 m tall six-legged armored artillery walker (original design). Segmented hull lofted in 64 stations of 64
/// radial points, a cockpit pod with lit amber slit windows on a yawing head joint, six digitigrade legs (48-sided tube
/// femurs, parallel steel pistons, hydraulic hoses, splayed foot pads), bolted armor plates in chipped paint and a dorsal
/// cannon with a sliding barrel. Snow-dusted mounds sit on the upper surfaces. Origin on the ground at hull centre, front
/// +Z, up +Y. Legs at azimuths +30, -30, +90, -90, +150, -150 degrees from +Z.
///
/// Joints: `stride` -1...1 (tripod gait phase: legs 0, 3, 4 swing and lift opposite legs 1, 2, 5), `head` -1...1 (cockpit
/// yaw 40 degrees, positive toward +X), `cannon` 0...1 (elevation 30 degrees), `recoil` 0...1 (barrel slides back 1.5 m),
/// `crouch` 0...1 (hull lowers 3 m, legs fold). All five are empty drivers; child parts mimic them. 2 LODs.
public struct SiegeWalker: RealArticulated {
    public static let id = "siege-walker"
    public static let summary = "22 m six-legged armored siege walker: lofted segmented hull, lit cockpit pod, six piston legs with hoses, dorsal cannon, chipped plates and snow dust; joints stride, head, cannon, recoil, crouch."
    public static let tags = ["prop", "vehicle", "metal", "outdoor", "articulated", "glowing"]
    public static let budget = 45_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 8, distance: 1.1, ground: true, studio: true)

    /// Armor plates, chipped paint.
    public var armor: MaterialKey = "metal.painted:5A5F5C"
    /// Hull shell and lower belly.
    public var hull: MaterialKey = "metal.painted:3E4448"
    /// Legs, weathered steel.
    public var legMetal: MaterialKey = "metal.painted:30363A"
    /// Pistons, joints, barrel.
    public var steel: MaterialKey = "metal.steel:6A7074"
    /// Worn cast iron for feet and cannon breech.
    public var iron: MaterialKey = "metal.cast-iron-worn"
    /// Hydraulic hoses.
    public var hose: MaterialKey = "rubber.insulating-black"
    /// Cockpit slit windows (Emissive.swift).
    public var window: MaterialKey = "emissive.amber"
    /// Snow dust on upper surfaces.
    public var snow: MaterialKey = "ground.snow"
    public init() {}

    static let azimuths: [Float] = [30, -30, 90, -90, 150, -150]
    static let hullY: Float = 17.0
    static let hullHalfLen: Float = 8.5
    static let cockpitPivot = V3(0, 20.6, 5.8)
    static let cannonPivot = V3(0, 20.4, -2.0)
    // (radial distance, height) of hip, knee 1, knee 2, foot.
    static let hip = (d: Float(3.9), y: Float(16.2))
    static let k1 = (d: Float(8.6), y: Float(21.0))
    static let k2 = (d: Float(13.2), y: Float(9.0))
    static let foot = (d: Float(14.2), y: Float(0.5))

    static func radial(_ az: Float) -> V3 { V3(sin(radians(az)), 0, cos(radians(az))) }
    static func at(_ r: V3, _ p: (d: Float, y: Float)) -> V3 { r * p.d + V3(0, p.y, 0) }

    /// Half width and half height of the hull cross-section at t in 0...1 (rear to front).
    static func section(_ t: Float) -> (w: Float, h: Float) {
        let nose = pow(max(0, 1 - pow(max(0, t - 0.55) / 0.45, 2.2)), 0.6)
        let tail = pow(min(1, t / 0.12 + 0.35), 0.5)
        let belly = 1 - 0.18 * pow(abs(t - 0.5) * 2, 2)
        return (4.7 * nose * min(1, tail) * belly + 0.05, 3.0 * (0.55 + 0.45 * nose) * min(1, tail) * belly + 0.05)
    }

    static func hullRings(stations: Int, radial: Int, from: Int, to: Int) -> [[V3]] {
        (from...to).map { k -> [V3] in
            let t = Float(k) / Float(stations - 1)
            let z = -hullHalfLen + 2 * hullHalfLen * t
            let s = section(t)
            // Segment bands: shallow grooves every ~2 m.
            let band = 1 - 0.025 * pow(abs(sin(t * 8 * .pi)), 8)
            return (0..<radial).map { j -> V3 in
                let a = 2 * Float.pi * Float(j) / Float(radial)
                let ca = cos(a), sa = sin(a)
                let ex: Float = 2.6
                let cx = copysign(pow(abs(ca), 2 / ex), ca), sy = copysign(pow(abs(sa), 2 / ex), sa)
                let hy = sy > 0 ? s.h : s.h * 0.7
                return V3(s.w * cx * band, hullY + hy * sy * band, z)
            }
        }
    }

    static func segment(_ a: V3, _ b: V3, r0: Float, r1: Float, stations: Int, sides: Int, _ mat: MaterialKey) -> Surface {
        var path: [V3] = [], radii: [Float] = []
        for i in 0..<stations {
            let t = Float(i) / Float(stations - 1)
            path.append(a + (b - a) * t)
            let rib = 1 + 0.06 * cos(t * 2 * .pi * 2) * sin(t * .pi)
            radii.append((r0 + (r1 - r0) * t) * rib)
        }
        return Prim.tube(path, radii: radii, sides: sides, seamTile: 0.5, material: mat, capEnd: true)
    }

    static func lookRot(from a: V3, to b: V3) -> simd_quatf {
        simd_quatf(from: V3(0, 0, 1), to: simd_normalize(b - a))
    }

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [120])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)

        for (name, range, dur): (String, ClosedRange<Float>, Float) in
            [("stride", -1...1, 1.0), ("head", -1...1, 1.2), ("cannon", 0...1, 1.5), ("recoil", 0...1, 0.4), ("crouch", 0...1, 2.0)] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, range, duration: dur))
        }
        _ = rig.part("body", pivot: .zero, joint: Joint(.prismatic, axis: Y, range: -3...0, mimic: .init("crouch", ratio: -3)))

        // Legs: tripod gait groups from `stride`, fold from `crouch`.
        for (i, az) in Self.azimuths.enumerated() {
            let r = Self.radial(az)
            let tangent = V3(r.z, 0, -r.x)
            let g: Float = (i == 0 || i == 3 || i == 4) ? 1 : -1
            let h = Self.at(r, Self.hip), k1 = Self.at(r, Self.k1), k2 = Self.at(r, Self.k2)
            let n = String(i)
            _ = rig.part("legYaw" + n, parent: "body", pivot: h, joint: Joint(.revolute, axis: Y, range: -10...10, mimic: .init("stride", ratio: 10 * g)))
            _ = rig.part("legLift" + n, parent: "legYaw" + n, pivot: h, joint: Joint(.revolute, axis: tangent, range: -7...7, mimic: .init("stride", ratio: -7 * g)))
            _ = rig.part("hip" + n, parent: "legLift" + n, pivot: h, joint: Joint(.revolute, axis: tangent, range: 0...12, mimic: .init("crouch", ratio: 12)))
            _ = rig.part("knee1_" + n, parent: "hip" + n, pivot: k1, joint: Joint(.revolute, axis: tangent, range: 0...22, mimic: .init("crouch", ratio: 22)))
            _ = rig.part("knee2_" + n, parent: "knee1_" + n, pivot: k2, joint: Joint(.revolute, axis: tangent, range: 0...30, mimic: .init("crouch", ratio: 30)))
        }

        // Head yaw, cannon elevation and barrel slide.
        _ = rig.part("headYaw", parent: "body", pivot: Self.cockpitPivot, joint: Joint(.revolute, axis: Y, range: -40...40, mimic: .init("head", ratio: 40)))
        _ = rig.part("cannonPitch", parent: "body", pivot: Self.cannonPivot, joint: Joint(.revolute, axis: X, range: -30...0, mimic: .init("cannon", ratio: -30)))
        _ = rig.part("barrel", parent: "cannonPitch", pivot: Self.cannonPivot, joint: Joint(.prismatic, axis: Z, range: -1.5...0, mimic: .init("recoil", ratio: -1.5)))

        for l in 0..<2 {
            let hi = l == 0
            func put(_ s: Surface, _ part: String, _ x: Xform = .identity) {
                rig.add(s, x, to: part, lods: l...l)
            }
            let tubeSides = hi ? 48 : 16
            let stations = hi ? 64 : 24
            let radial = hi ? 64 : 24
            let sub = hi ? 8 : 3

            // Hull: three lofts split along the length (rear block, centre, nose) so segments take different finishes.
            let a = stations / 3, b = 2 * stations / 3
            put(Prim.loft(Self.hullRings(stations: stations, radial: radial, from: 0, to: a), capStart: true, material: hull), "body")
            put(Prim.loft(Self.hullRings(stations: stations, radial: radial, from: a, to: b), material: armor), "body")
            put(Prim.loft(Self.hullRings(stations: stations, radial: radial, from: b, to: stations - 1), capEnd: true, material: hull), "body")

            // Armor plates on the flanks and deck with chipped finish.
            for (k, z) in [Float(-5.5), -1.5, 2.5].enumerated() {
                let s = Self.section((z + Self.hullHalfLen) / (2 * Self.hullHalfLen))
                for side: Float in [-1, 1] {
                    put(Prim.roundedBox(V3(0.35, s.h * 1.1, 3.0), radius: 0.12, bevelSegments: hi ? 4 : 2, material: k == 1 ? iron : armor), "body",
                        Xform(translation: V3(side * (s.w + 0.05), Self.hullY + 0.4, z), rotation: simd_quatf(angle: side * 0.12, axis: Z)))
                }
                put(Prim.roundedBox(V3(s.w * 1.5, 0.3, 2.4), radius: 0.1, bevelSegments: hi ? 4 : 2, material: armor), "body",
                    Xform(translation: V3(0, Self.hullY + s.h * 0.98, z)))
                // Snow mound on the deck plate.
                put(Prim.superellipsoid(V3(s.w * 0.75, 0.32, 1.3), exponent: 2.4, subdivisions: sub, material: snow), "body",
                    Xform(translation: V3(0.3 * Float(k - 1), Self.hullY + s.h * 0.98 + 0.28, z + 0.2)))
            }
            // Belly hatch and hip mounts.
            put(Prim.superellipsoid(V3(2.6, 0.7, 4.0), exponent: 2.4, subdivisions: sub, material: iron), "body",
                Xform(translation: V3(0, Self.hullY - 2.2, 0)))

            // Cockpit pod, windows, brow plate.
            let cp = Self.cockpitPivot
            put(Prim.superellipsoid(V3(3.0, 2.2, 3.4), exponent: 2.4, subdivisions: hi ? 10 : 4, material: hull), "headYaw",
                Xform(translation: cp + V3(0, 1.0, 0.8)))
            put(Prim.roundedBox(V3(3.4, 0.35, 2.4), radius: 0.12, bevelSegments: hi ? 4 : 2, material: armor), "headYaw",
                Xform(translation: cp + V3(0, 2.4, 1.8), rotation: simd_quatf(angle: -0.12, axis: X)))
            put(Prim.superellipsoid(V3(1.6, 0.18, 1.0), exponent: 2.4, subdivisions: sub, material: snow), "headYaw",
                Xform(translation: cp + V3(0, 2.7, 1.7)))
            for k in 0..<5 {
                let x = (Float(k) - 2) * 0.62
                let yaw = (Float(k) - 2) * -0.2
                put(Prim.roundedBox(V3(0.42, 0.2, 0.12), radius: 0.04, bevelSegments: hi ? 3 : 2, material: window), "headYaw",
                    Xform(translation: cp + V3(x, 1.2, 2.55 - abs(x) * 0.18), rotation: simd_quatf(angle: yaw, axis: Y)))
            }
            put(Prim.torus(major: 0.9, minor: 0.1, segments: hi ? 48 : 16, sides: hi ? 8 : 5, material: steel), "headYaw",
                Xform(translation: cp + V3(0, 0, 0), rotation: simd_quatf(angle: 0, axis: Y)))

            // Dorsal cannon: breech housing and cradle on the pitch joint, barrel and muzzle brake on the slide.
            let cn = Self.cannonPivot
            put(Prim.superellipsoid(V3(1.9, 1.5, 3.0), exponent: 2.4, subdivisions: sub, material: iron), "cannonPitch",
                Xform(translation: cn + V3(0, 0.9, -0.2)))
            put(Prim.roundedBox(V3(3.6, 0.5, 4.0), radius: 0.15, bevelSegments: hi ? 4 : 2, material: armor), "body",
                Xform(translation: cn + V3(0, -0.1, 0)))
            put(Self.segment(cn + V3(0, 0.9, 1.0), cn + V3(0, 0.9, 12.0), r0: 0.55, r1: 0.42, stations: hi ? 16 : 6, sides: tubeSides, steel), "barrel")
            put(Prim.tube([cn + V3(0, 0.9, 5.0), cn + V3(0, 0.9, 9.5)], radii: [0.85, 0.85], sides: tubeSides, seamTile: 0.5, material: legMetal, capEnd: true), "barrel")
            put(Prim.tube([cn + V3(0, 0.9, 11.6), cn + V3(0, 0.9, 12.8)], radii: [0.7, 0.7], sides: tubeSides, seamTile: 0.5, material: iron, capEnd: true), "barrel")
            put(Prim.superellipsoid(V3(0.8, 0.25, 1.6), exponent: 2.4, subdivisions: sub, material: snow), "cannonPitch",
                Xform(translation: cn + V3(0, 2.2, -0.2)))

            // Legs.
            for (i, az) in Self.azimuths.enumerated() {
                let r = Self.radial(az)
                let tangent = V3(r.z, 0, -r.x)
                let h = Self.at(r, Self.hip), k1 = Self.at(r, Self.k1), k2 = Self.at(r, Self.k2), f = Self.at(r, Self.foot)
                let n = String(i)
                let st = hi ? 6 : 3
                put(Prim.superellipsoid(V3(2.2, 2.2, 2.2), exponent: 2, subdivisions: sub, material: iron), "hip" + n, Xform(translation: h))
                put(Self.segment(h, k1, r0: 0.9, r1: 0.75, stations: st, sides: tubeSides, legMetal), "hip" + n)
                put(Prim.superellipsoid(V3(1.9, 1.9, 1.9), exponent: 2, subdivisions: sub, material: steel), "knee1_" + n, Xform(translation: k1))
                put(Self.segment(k1, k2, r0: 0.75, r1: 0.55, stations: st, sides: tubeSides, legMetal), "knee1_" + n)
                // Piston alongside the femur and hose with sag.
                let side = simd_normalize(simd_cross(simd_normalize(k2 - k1), tangent)) * 1.1
                put(Self.segment(h + side * 0.4 + V3(0, -1.0, 0), k1 + side + V3(0, -0.6, 0), r0: 0.26, r1: 0.26, stations: st, sides: tubeSides, steel), "hip" + n)
                put(Self.segment(k1 + side * 0.6, k2 + side * 0.3 + (k1 - k2) * 0.35, r0: 0.3, r1: 0.3, stations: st, sides: tubeSides, steel), "knee1_" + n)
                var hp: [V3] = [], hr: [Float] = []
                let hn = hi ? 16 : 6
                for q in 0..<hn {
                    let t = Float(q) / Float(hn - 1)
                    hp.append(h + (k1 - h) * t + tangent * 0.9 + V3(0, -0.5 - 0.7 * sin(t * .pi), 0))
                    hr.append(0.14)
                }
                put(Prim.tube(hp, radii: hr, sides: hi ? 12 : 6, seamTile: 0.5, material: hose, capEnd: true), "hip" + n)
                put(Prim.superellipsoid(V3(1.5, 1.5, 1.5), exponent: 2, subdivisions: sub, material: steel), "knee2_" + n, Xform(translation: k2))
                put(Self.segment(k2, f + V3(0, 0.5, 0), r0: 0.55, r1: 0.32, stations: st, sides: tubeSides, legMetal), "knee2_" + n)
                put(Prim.superellipsoid(V3(2.6, 0.7, 2.6), exponent: 2.4, subdivisions: hi ? 6 : 3, material: iron), "knee2_" + n,
                    Xform(translation: f + V3(0, -0.05, 0)))
                put(Prim.superellipsoid(V3(1.5, 0.22, 1.5), exponent: 2.4, subdivisions: sub, material: snow), "knee2_" + n,
                    Xform(translation: f + V3(0, 0.55, 0)))
            }
        }

        rig.lights = [RigLight(name: "cockpit-glow", part: "headYaw", position: Self.cockpitPivot + V3(0, 1.2, 3.2), direction: V3(0, -0.1, 1),
                               color: V3(1.0, 0.65, 0.25), intensity: 2500, attenuationRadius: 60)]

        rig.states = [
            RigState("stand"),
            RigState("step-front", ["stride": 1]),
            RigState("step-back", ["stride": -1]),
            RigState("look-left", ["head": -1]),
            RigState("look-right", ["head": 1]),
            RigState("crouch", ["crouch": 1]),
            RigState("aim", ["crouch": 1, "cannon": 1]),
            RigState("fire", ["crouch": 1, "cannon": 1, "recoil": 1]),
        ]
        return rig
    }
}
