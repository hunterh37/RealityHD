import simd
import Foundation

/// Mech heron, 12 m tall robotic wading bird: a lofted body (48 stations, 64 radial points) in gunmetal under glossy white
/// vitreous ceramic panels, chrome hydraulic piston legs (48 radial tubes) with backward-bending knees and four-toed chrome feet,
/// an articulated S-neck of six chrome segments with ceramic collars and twin piston rods, a ceramic head with a blade beak
/// (hinged lower blade) and a cyan LED eye strip, and two folding wings of overlapping ceramic panels on chrome spars.
/// Origin on the ground between the feet, face +Z, up +Y.
///
/// Joints: `walk` -1...1 (wading gait: positive swings the right leg back and the left leg forward 24 degrees at the hip,
/// shins counter-bend 14 degrees), `neck` -1...1 (-1 coils the S-neck back, +1 extends it down and forward into a strike;
/// the rest shape is the midpoint, a natural standing pose is about -0.5), `beak` 0...1 (lower blade opens 30 degrees),
/// `wings` 0...1 (panel wings swing up and out 100 degrees from folded at the flanks), `glow` 0...1 (eye strip switches to
/// emissive cyan at 0.05, with a cyan point light). All five joints are empty drivers; child parts mimic them. 2 LODs.
public struct MechHeron: RealArticulated {
    public static let id = "mech-heron"
    public static let summary = "12 m mech heron: chrome and white ceramic panels, hydraulic piston legs with backward knees, six-segment S-neck, blade beak, LED eye strip, folding panel wings, joints walk, neck, beak, wings, glow."
    public static let tags = ["prop", "robot", "mech", "creature", "metal", "ceramic", "outdoor", "articulated", "glowing"]
    public static let budget = 28_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 55, elevation: 8, distance: 1.1, ground: false, studio: true)

    /// Body, head and wing panels, glossy white ceramic.
    public var panel: MaterialKey = "ceramic.vitreous"
    /// Leg housings, neck segments, pistons, spars, feet.
    public var chrome: MaterialKey = "metal.chrome"
    /// Body core, joints and recesses.
    public var frame: MaterialKey = "metal.anodized-gunmetal"
    /// Blade beak.
    public var blade: MaterialKey = "metal.stainless"
    /// Hydraulic hoses.
    public var hose: MaterialKey = "rubber.tubing"
    /// Eye strip when lit.
    public var lit: MaterialKey = "emissive.thruster-cyan"
    /// Eye strip when dark.
    public var unlit: MaterialKey = "glass.tinted:0A1418"
    public init() {}

    // MARK: Neck (shared with RealityStudio MechHeronMath)

    static let neckBase = V3(0, 7.2, 1.4)
    static let neckSeg: Float = 1.1
    static let beakLen: Float = 1.4
    /// Absolute segment pitch (degrees, up positive from +Z) at neck -1 (coiled) and +1 (strike). Rest is the midpoint.
    static let coil: [Float] = [95, 130, 150, 100, 40, -10]
    static let strike: [Float] = [-35, -45, -52, -56, -60, -62]
    static func restPitch(_ i: Int) -> Float { (coil[i] + strike[i]) / 2 }
    static func dir(_ deg: Float) -> V3 { let r = deg * .pi / 180; return V3(0, sin(r), cos(r)) }
    /// Joint starts at rest, index 0...6 (6 is the neck end where the head sits).
    static func neckPoints() -> [V3] {
        var p = [neckBase]
        for i in 0..<6 { p.append(p[i] + dir(restPitch(i)) * neckSeg) }
        return p
    }
    /// Mimic ratio per segment (degrees about +X per unit of `neck`). Pitch up is a negative X rotation.
    static func neckRatio(_ i: Int) -> Float {
        let d = (strike[i] - coil[i]) / 2
        let dPrev: Float = i == 0 ? 0 : (strike[i - 1] - coil[i - 1]) / 2
        return -(d - dPrev)
    }

    // MARK: Body

    static func smooth(_ x: Float) -> Float { let t = min(1, max(0, x)); return t * t * (3 - 2 * t) }
    static let bodyY: Float = 8.2
    static let bodyFront: Float = 2.4
    static let bodyBack: Float = -3.4
    static func shape(_ z: Float) -> Float {
        let s = (bodyFront - z) / (bodyFront - bodyBack)
        return max(0.05, pow(max(0, sin(.pi * min(1, max(0, s)))), 0.6) * (1 - 0.35 * smooth((s - 0.55) / 0.45)))
    }
    static func section(_ z: Float, _ a: Float) -> V3 {
        let k = shape(z)
        let lift: Float = 0.35 * smooth((bodyFront - z) / (bodyFront - bodyBack) - 0.5)
        return V3(1.3 * k * sin(a), bodyY + lift + 1.35 * k * cos(a), z)
    }
    static func outward(_ z: Float, _ a: Float) -> V3 { simd_normalize(V3(sin(a) / 1.3, cos(a) / 1.35, 0)) }

    /// Orientation with local +Z along n.
    static func facing(_ n: V3) -> simd_quatf { simd_quatf(from: V3(0, 0, 1), to: simd_normalize(n)) }

    /// Flat blade loft along `u` from `o`, width and height tapering to a point; `side` is the in-plane lateral axis.
    static func bladeLoft(_ o: V3, _ u: V3, length: Float, width: Float, height: Float, stations: Int, radial: Int, drop: Float, _ mat: MaterialKey) -> Surface {
        let x = V3(1, 0, 0)
        let e2 = simd_normalize(simd_cross(u, x)) // x cross e2 = u, outward winding along u
        var rings: [[V3]] = []
        for i in 0..<stations {
            let t = Float(i) / Float(stations - 1)
            let k = max(0.02, pow(1 - t, 0.85))
            let c = o + u * (length * t) + e2 * (-drop * t * t)
            rings.append((0..<radial).map { j in
                let a = 2 * Float.pi * Float(j) / Float(radial)
                let edge = pow(abs(cos(a)), 0.6) * (cos(a) < 0 ? -1 : 1)
                return c + x * (width * k * sin(a)) + e2 * (height * k * edge)
            })
        }
        return Prim.loft(rings, capStart: true, material: mat)
    }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [150])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)

        for (name, range, dur): (String, ClosedRange<Float>, Float) in
            [("walk", -1...1, 1.4), ("neck", -1...1, 0.6), ("beak", 0...1, 0.25), ("wings", 0...1, 1.2), ("glow", 0...1, 1.0)] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, range, duration: dur))
        }
        _ = rig.part("body", pivot: .zero, joint: .fixed)

        // Legs: hip swings about X, shin counter-bends at the backward knee.
        let hipY: Float = 7.0, kneeP = V3(0, 3.7, -0.95), ankleP = V3(0, 0.45, 0.1)
        for (side, s): (String, Float) in [("R", 1), ("L", -1)] {
            let hx = 0.95 * s
            _ = rig.part("hip\(side)", parent: "body", pivot: V3(hx, hipY, -0.2), joint: Joint(.revolute, axis: X, range: -24...24, mimic: .init("walk", ratio: 24 * s)))
            _ = rig.part("knee\(side)", parent: "hip\(side)", pivot: V3(hx, kneeP.y, kneeP.z), joint: Joint(.revolute, axis: X, range: -14...14, mimic: .init("walk", ratio: -14 * s)))
        }
        // Neck chain.
        let np = Self.neckPoints()
        for i in 0..<6 {
            let r = Self.neckRatio(i)
            _ = rig.part("neck\(i + 1)", parent: i == 0 ? "body" : "neck\(i)", pivot: np[i],
                         joint: Joint(.revolute, axis: X, range: -abs(r)...abs(r), mimic: .init("neck", ratio: r)))
        }
        let headU = Self.dir(Self.restPitch(5))
        let beakBase = np[6] + headU * 0.75
        _ = rig.part("jaw", parent: "neck6", pivot: beakBase + V3(0, -0.08, 0), joint: Joint(.revolute, axis: X, range: 0...30, mimic: .init("beak", ratio: 30)))
        _ = rig.part("lamps", parent: "neck6", pivot: np[6], joint: .fixed, options: 2)
        rig.optionLinks = [RigOptionLink(part: "lamps", joint: "glow", thresholds: [0.05])]
        // Wings fold down and back along the flanks, spread swings them up and out about Z.
        let shoulder: Float = 1.15
        _ = rig.part("wingR", parent: "body", pivot: V3(shoulder, 8.9, 0.6), joint: Joint(.revolute, axis: Z, range: 0...100, mimic: .init("wings", ratio: 100)))
        _ = rig.part("wingL", parent: "body", pivot: V3(-shoulder, 8.9, 0.6), joint: Joint(.revolute, axis: Z, range: -100...0, mimic: .init("wings", ratio: -100)))

        for l in 0..<2 {
            let hi = l == 0
            func put(_ s: Surface, _ part: String, option: Int = 0, _ x: Xform = .identity) {
                rig.add(s, x, to: part, option: option, lods: l...l)
            }
            let radial = hi ? 64 : 24
            let tubeSides = hi ? 48 : 16
            let sub = hi ? 3 : 2

            // Body core loft (gunmetal), front to back.
            let stations = hi ? 48 : 16
            let rings = (0..<stations).map { i -> [V3] in
                let z = Self.bodyFront + (Self.bodyBack - Self.bodyFront) * Float(i) / Float(stations - 1)
                return (0..<radial).map { j in Self.section(z, 2 * .pi * Float(j) / Float(radial)) }
            }
            put(Prim.loft(rings, capStart: true, capEnd: true, material: frame), "body")
            // Ceramic armour panels over the back and flanks, gaps show the gunmetal core.
            let rows: [Float] = hi ? [1.7, 0.9, 0.1, -0.7, -1.5, -2.3] : [1.4, 0, -1.4]
            for (ri, z) in rows.enumerated() {
                let per = hi ? 5 : 3
                for k in 0..<per {
                    let a = (-70 + 140 * Float(k) / Float(per - 1) + (ri % 2 == 0 ? 0 : 10)) * Float.pi / 180
                    let n = Self.outward(z, a)
                    let sz = max(0.3, Self.shape(z))
                    put(Prim.superellipsoid(V3(0.95 * sz, 0.85, 0.1), exponent: 4, subdivisions: sub, material: panel), "body",
                        Xform(translation: Self.section(z, a) + n * 0.05, rotation: Self.facing(n)))
                }
            }
            // Breast plate and tail fan of ceramic blades.
            put(Prim.superellipsoid(V3(1.9, 2.0, 0.9), exponent: 2.6, subdivisions: hi ? 5 : 3, material: panel), "body", Xform(translation: V3(0, 8.0, 2.0)))
            for k in 0..<5 {
                let a = (Float(k) - 2) * 0.22
                let d = simd_normalize(V3(sin(a) * 0.6, -0.25, -1))
                put(Prim.superellipsoid(V3(0.55, 0.08, 2.2), exponent: 3, subdivisions: sub, material: k % 2 == 0 ? panel : chrome), "body",
                    Xform(translation: V3(0, 8.5, -3.3) + d * 1.0, rotation: Self.facing(d)))
            }

            // Legs.
            for (side, s): (String, Float) in [("R", 1), ("L", -1)] {
                let hx = 0.95 * s
                let hip = V3(hx, hipY, -0.2), knee = V3(hx, kneeP.y, kneeP.z), ankle = V3(hx, ankleP.y, ankleP.z)
                put(Prim.superellipsoid(V3(0.9, 0.9, 0.9), exponent: 2, subdivisions: hi ? 5 : 3, material: frame), "hip\(side)", Xform(translation: hip))
                // Thigh housing (ceramic shell over a chrome tube) and twin pistons.
                put(Prim.tube([hip, hip + (knee - hip) * 0.5, knee], radii: [0.42, 0.36, 0.3], sides: tubeSides, seamTile: 0.5, material: chrome, capEnd: true), "hip\(side)")
                put(Prim.superellipsoid(V3(0.85, 1.9, 0.7), exponent: 3, subdivisions: sub, material: panel), "hip\(side)",
                    Xform(translation: hip + (knee - hip) * 0.35 + V3(0.12 * s, 0, 0.1), rotation: simd_quatf(from: Y, to: simd_normalize(hip - knee))))
                for o: Float in [-1, 1] {
                    let off = V3(0.32 * s, 0, 0.28 * o)
                    put(Prim.tube([hip + off + V3(0, -0.4, 0), knee + off + V3(0, 0.5, 0)], radii: [0.12, 0.12], sides: tubeSides, seamTile: 0.3, material: frame, capEnd: true), "hip\(side)")
                }
                put(Prim.superellipsoid(V3(0.62, 0.62, 0.62), exponent: 2, subdivisions: hi ? 4 : 2, material: frame), "knee\(side)", Xform(translation: knee))
                // Shin: long chrome piston with a sliding rod and a hose.
                put(Prim.tube([knee, knee + (ankle - knee) * 0.55], radii: [0.26, 0.22], sides: tubeSides, seamTile: 0.5, material: chrome, capEnd: true), "knee\(side)")
                put(Prim.tube([knee + (ankle - knee) * 0.5, ankle], radii: [0.14, 0.14], sides: tubeSides, seamTile: 0.3, material: chrome, capEnd: true), "knee\(side)")
                var hosePath: [V3] = []
                for i in 0..<10 {
                    let t = Float(i) / 9
                    hosePath.append(knee + (ankle - knee) * t + V3(0.3 * s, 0, -0.22 - 0.12 * sin(.pi * t)))
                }
                put(Prim.tube(hosePath, radii: [Float](repeating: 0.06, count: 10), sides: hi ? 12 : 6, seamTile: 0.2, material: hose, capEnd: true), "knee\(side)")
                // Foot: ankle ball, three toes forward, one back, chrome talon tips.
                put(Prim.superellipsoid(V3(0.4, 0.4, 0.4), exponent: 2, subdivisions: hi ? 4 : 2, material: frame), "knee\(side)", Xform(translation: ankle))
                for (yaw, len): (Float, Float) in [(-0.45, 1.6), (0, 1.9), (0.45, 1.6), (.pi, 0.9)] {
                    let d = V3(sin(yaw), 0, cos(yaw))
                    let a = ankle, b = V3(ankle.x, 0.12, ankle.z) + d * (len * 0.45), c = V3(ankle.x, 0.08, ankle.z) + d * len
                    put(Prim.tube([a, b, c], radii: [0.13, 0.09, 0.05], sides: hi ? 16 : 8, seamTile: 0.2, material: chrome, capEnd: true), "knee\(side)")
                }
            }

            // Neck: chrome segments, ceramic collars, twin piston rods.
            for i in 0..<6 {
                let a = np[i], b = np[i + 1]
                let u = simd_normalize(b - a)
                let r0: Float = 0.34 - 0.025 * Float(i), r1 = r0 - 0.03
                put(Prim.tube([a, a + (b - a) * 0.5, b], radii: [r0, (r0 + r1) / 2, r1], sides: tubeSides, seamTile: 0.4, material: chrome, capEnd: true), "neck\(i + 1)")
                put(Prim.torus(major: r0 + 0.06, minor: 0.07, segments: tubeSides, sides: hi ? 8 : 5, material: panel), "neck\(i + 1)",
                    Xform(translation: a, rotation: simd_quatf(from: Y, to: u)))
                for o: Float in [-1, 1] {
                    let off = V3(0.3 * o, 0, 0)
                    put(Prim.tube([a + off + u * 0.15, b + off - u * 0.15], radii: [0.05, 0.05], sides: hi ? 24 : 8, seamTile: 0.2, material: frame, capEnd: true), "neck\(i + 1)")
                }
            }
            // Head: ceramic capsule, eye strip around the front, blade beak.
            let head = np[6] + headU * 0.3
            put(Prim.superellipsoid(V3(0.75, 0.7, 1.25), exponent: 2.4, subdivisions: hi ? 6 : 3, material: panel), "neck6",
                Xform(translation: head, rotation: Self.facing(headU)))
            for (opt, mat) in [(0, unlit), (1, lit)] {
                put(Prim.superellipsoid(V3(0.8, 0.14, 0.7), exponent: 3, subdivisions: sub, material: mat), "lamps", option: opt,
                    Xform(translation: head + headU * 0.2 + V3(0, 0.12, 0), rotation: Self.facing(headU)))
            }
            put(Self.bladeLoft(beakBase, headU, length: Self.beakLen, width: 0.2, height: 0.17, stations: hi ? 16 : 6, radial: hi ? 16 : 8, drop: 0.08, blade), "neck6",
                Xform(translation: V3(0, 0.08, 0)))
            put(Self.bladeLoft(beakBase, headU, length: Self.beakLen * 0.92, width: 0.18, height: 0.12, stations: hi ? 16 : 6, radial: hi ? 16 : 8, drop: -0.04, blade), "jaw",
                Xform(translation: V3(0, -0.12, 0)))

            // Wings: folded down and back along the flanks; three overlapping ceramic panel rows on a chrome spar.
            for (side, s): (String, Float) in [("R", 1), ("L", -1)] {
                let root = V3(shoulder * s, 8.9, 0.6)
                let spanDir = simd_normalize(V3(0.15 * s, -0.75, -0.65))
                let spar = (0..<6).map { i -> V3 in root + spanDir * (Float(i) * 0.9) + V3(0.05 * s * Float(i), 0, 0) }
                put(Prim.tube(spar, radii: [0.16, 0.14, 0.12, 0.1, 0.08, 0.06], sides: tubeSides, seamTile: 0.3, material: chrome, capEnd: true), "wing\(side)")
                let n = simd_normalize(V3(s, 0.1, 0))
                for row in 0..<3 {
                    let count = hi ? 5 : 3
                    for k in 0..<count {
                        let t = (Float(k) + 0.5) / Float(count)
                        let p = root + spanDir * (4.5 * t) + V3(0, 0, -0.55 - 0.75 * Float(row)) + n * (0.05 + 0.04 * Float(row))
                        let len: Float = 1.3 + 0.5 * Float(row)
                        let q = simd_quatf(from: Z, to: n) * simd_quatf(angle: 0.25, axis: Z)
                        put(Prim.superellipsoid(V3(1.0, len, 0.07), exponent: 4, subdivisions: sub, material: row == 1 ? chrome : panel), "wing\(side)",
                            Xform(translation: p, rotation: q))
                    }
                }
                // Jump-jet nozzle under the wing root.
                put(Prim.tube([root + V3(0.1 * s, -0.6, -0.4), root + V3(0.1 * s, -1.3, -0.5)], radii: [0.3, 0.42], sides: tubeSides, seamTile: 0.3, material: frame, capEnd: false), "body")
            }
        }

        rig.lights = [
            RigLight(name: "eye-glow", part: "lamps", option: 1, position: np[6] + headU * 0.9, direction: headU, color: V3(0.3, 0.9, 1), intensity: 2200, attenuationRadius: 30),
        ]

        rig.states = [
            RigState("rest"),
            RigState("stand", ["neck": -0.5]),
            RigState("stride-left", ["walk": -1, "neck": -0.5]),
            RigState("stride-right", ["walk": 1, "neck": -0.5]),
            RigState("coil", ["neck": -1]),
            RigState("strike", ["neck": 1, "beak": 1]),
            RigState("spread", ["wings": 1, "neck": -0.5]),
            RigState("hover", ["wings": 1, "neck": -0.5, "glow": 1], options: ["lamps": 1]),
        ]
        return rig
    }
}
