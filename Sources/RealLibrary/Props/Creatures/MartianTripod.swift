import simd
import Foundation

/// Martian tripod, 30 m tall alien war machine: a flattened lofted hood (64 stations, 64 radial points) in weathered gunmetal
/// with oil-dark underside, three jointed legs (three segments of 48-sided tubes with ball knees and splayed foot pads), an
/// articulated cowl carrying a glass heat-ray lens with an emissive green core and an eight-leaf iris, and six tapered whip
/// tentacles hanging under the hood (64 stations each). Origin on the ground at the tripod centre, front +Z, up +Y. Legs sit
/// at azimuths +60, -60 (front pair) and 180 degrees (rear).
///
/// Authored pose is the full stand. Joints: `stride` -1...1 (leg cycle phase: front legs swing fore and aft and lift in
/// opposition, rear leg lifts), `rise` 0...1 (0 = hood sunk 22 m and legs folded flat, 1 = full stand), `cowl` -1...1 (cowl yaw
/// 50 degrees, positive toward +X), `aim` 0...1 (cowl pitch down 35 degrees), `charge` 0...1 (lens core lights and the iris
/// leaves slide open). 0...1 and -1...1 joints are empty drivers; child parts mimic them. Follower `lensGlow` switches option at
/// charge 0.05. 2 LODs.
public struct MartianTripod: RealArticulated {
    public static let id = "martian-tripod"
    public static let summary = "30 m Martian tripod: lofted gunmetal hood, three jointed legs with ball knees, articulated heat-ray cowl with glass lens and iris, six whip tentacles, joints stride, rise, cowl, aim, charge."
    public static let tags = ["prop", "creature", "vehicle", "metal", "glass", "outdoor", "articulated", "glowing"]
    public static let budget = 30_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 8, distance: 1.1, ground: true, studio: true)

    /// Hood upper shell (Paint.swift, weathered gunmetal with clearcoat).
    public var hull: MaterialKey = "metal.painted:424A4E"
    /// Hood underside and oil-streaked lower shell.
    public var oiled: MaterialKey = "metal.painted:1E2326"
    /// Leg tubes.
    public var legMetal: MaterialKey = "metal.painted:363D41"
    /// Lower leg segments, oil stained.
    public var legLow: MaterialKey = "metal.painted:262C2F"
    /// Ball knees, foot pads, lens frame.
    public var joint: MaterialKey = "metal.steel:565D61"
    /// Tentacles.
    public var tentacle: MaterialKey = "rubber.silicone:2A3A30"
    /// Heat-ray lens glass.
    public var glass: MaterialKey = "glass.tinted:12402A"
    /// Lens core when lit (Emissive.swift).
    public var core: MaterialKey = "emissive.led-green"
    /// Lens core when dark.
    public var coreDark: MaterialKey = "glass.tinted:0A1A12"
    public init() {}

    static let hoodC: Float = 27.4
    static let azimuths: [Float] = [60, -60, 180]
    // (radial distance, height) of hip, knee 1, knee 2, foot in a leg's vertical plane.
    static let hip = (d: Float(2.6), y: Float(26.6))
    static let k1 = (d: Float(8.6), y: Float(29.4))
    static let k2 = (d: Float(15.5), y: Float(14.5))
    static let foot = (d: Float(17.5), y: Float(0.45))
    static let cowlY: Float = 27.0

    static func radial(_ az: Float) -> V3 { V3(sin(radians(az)), 0, cos(radians(az))) }
    static func at(_ r: V3, _ p: (d: Float, y: Float)) -> V3 { r * p.d + V3(0, p.y, 0) }

    /// Rounded rib-banded segment between two points.
    static func segment(_ a: V3, _ b: V3, r0: Float, r1: Float, stations: Int, sides: Int, _ mat: MaterialKey) -> Surface {
        var path: [V3] = [], radii: [Float] = []
        for i in 0..<stations {
            let t = Float(i) / Float(stations - 1)
            path.append(a + (b - a) * t)
            let rib = 1 + 0.07 * cos(t * 2 * .pi * 2) * sin(t * .pi)
            radii.append((r0 + (r1 - r0) * t) * rib)
        }
        return Prim.tube(path, radii: radii, sides: sides, seamTile: 0.5, material: mat, capEnd: true)
    }

    /// Hood radius factor at u in -1...1 (flat underside, domed top).
    static func hoodRadius(_ u: Float) -> Float {
        let e: Float = u < 0 ? 2.6 : 2.2
        return max(0.02, sqrt(max(0, 1 - pow(abs(u), e))))
    }

    static func hoodRings(stations: Int, radial: Int, from: Int, to: Int) -> [[V3]] {
        let rx: Float = 5.2, rz: Float = 5.8
        return (from...to).map { k -> [V3] in
            let u = Float(k) / Float(stations - 1) * 2 - 1
            let y = hoodC + (u < 0 ? u * 1.6 : u * 2.6)
            let f = hoodRadius(u)
            let bulge = 0.5 * f * max(0, 1 - abs(u) * 1.4)
            return (0..<radial).map { j -> V3 in
                let a = 2 * Float.pi * Float(j) / Float(radial)
                return V3(rx * f * cos(a), y, -(rz * f * sin(a) + bulge))
            }
        }
    }

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [120])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)

        for (name, range, dur): (String, ClosedRange<Float>, Float) in
            [("stride", -1...1, 1.0), ("rise", 0...1, 4.0), ("cowl", -1...1, 1.5), ("aim", 0...1, 1.0), ("charge", 0...1, 2.0)] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, range, duration: dur))
        }
        _ = rig.part("body", pivot: .zero, joint: Joint(.prismatic, axis: Y, range: -22...0, mimic: .init("rise", ratio: 22, offset: -22)))

        // Leg chains: yaw swing and lift from `stride`, fold from `rise`.
        let yawRatio: [Float] = [-14, -14, 0]
        let liftRatio: [Float] = [-8, 8, -5]
        for (i, az) in Self.azimuths.enumerated() {
            let r = Self.radial(az)
            let tangent = V3(r.z, 0, -r.x)
            let h = Self.at(r, Self.hip), k1 = Self.at(r, Self.k1), k2 = Self.at(r, Self.k2)
            let n = String(i)
            _ = rig.part("legYaw" + n, parent: "body", pivot: h, joint: Joint(.revolute, axis: Y, range: -16...16, mimic: .init("stride", ratio: yawRatio[i])))
            _ = rig.part("legLift" + n, parent: "legYaw" + n, pivot: h, joint: Joint(.revolute, axis: tangent, range: -12...12, mimic: .init("stride", ratio: liftRatio[i])))
            _ = rig.part("hip" + n, parent: "legLift" + n, pivot: h, joint: Joint(.revolute, axis: tangent, range: -5...55, mimic: .init("rise", ratio: -50, offset: 50)))
            _ = rig.part("knee1_" + n, parent: "hip" + n, pivot: k1, joint: Joint(.revolute, axis: tangent, range: -5...70, mimic: .init("rise", ratio: -65, offset: 65)))
            _ = rig.part("knee2_" + n, parent: "knee1_" + n, pivot: k2, joint: Joint(.revolute, axis: tangent, range: -5...105, mimic: .init("rise", ratio: -100, offset: 100)))
        }

        // Cowl: yaw about the hood centre, pitch about the mount, glowing core, iris leaves.
        let lensZ: Float = 8.0
        _ = rig.part("cowlYaw", parent: "body", pivot: V3(0, Self.cowlY, 0), joint: Joint(.revolute, axis: Y, range: -50...50, mimic: .init("cowl", ratio: 50)))
        _ = rig.part("cowlPitch", parent: "cowlYaw", pivot: V3(0, Self.cowlY, 4.8), joint: Joint(.revolute, axis: X, range: 0...35, mimic: .init("aim", ratio: 35)))
        _ = rig.part("lensGlow", parent: "cowlPitch", pivot: V3(0, Self.cowlY, lensZ - 0.4), joint: .fixed, options: 2)
        rig.optionLinks = [RigOptionLink(part: "lensGlow", joint: "charge", thresholds: [0.05])]
        for k in 0..<8 {
            let phi = 2 * Float.pi * Float(k) / 8
            let dir = V3(cos(phi), sin(phi), 0)
            _ = rig.part("iris\(k)", parent: "cowlPitch", pivot: V3(0, Self.cowlY, lensZ + 0.15),
                         joint: Joint(.prismatic, axis: dir, range: 0...1.0, mimic: .init("charge", ratio: 0.95)))
        }

        for l in 0..<2 {
            let hi = l == 0
            func put(_ s: Surface, _ part: String, option: Int = 0, _ x: Xform = .identity) {
                rig.add(s, x, to: part, option: option, lods: l...l)
            }
            let tubeSides = hi ? 48 : 16
            let stations = hi ? 64 : 24
            let radial = hi ? 64 : 24

            // Hood: two lofts split at the equator so the lower shell takes the oiled finish.
            let mid = stations / 2
            put(Prim.loft(Self.hoodRings(stations: stations, radial: radial, from: 0, to: mid), capStart: true, material: oiled), "body")
            put(Prim.loft(Self.hoodRings(stations: stations, radial: radial, from: mid, to: stations - 1), capEnd: true, material: hull), "body")
            // Underside neck boss.
            put(Prim.lathe([V2(0.01, 0), V2(2.6, 0.1), V2(3.2, 0.7), V2(2.9, 1.4)], segments: hi ? 48 : 16, seamTile: 0.4, material: joint), "body",
                Xform(translation: V3(0, Self.hoodC - 2.1, 0), scale: V3(1, 1, 1)))

            // Tentacles: six tapered whips under the hood, 64 stations each.
            let tCount = hi ? 64 : 20
            for k in 0..<6 {
                let a = 2 * Float.pi * (Float(k) + 0.3) / 6
                var path: [V3] = [], radii: [Float] = []
                for i in 0..<tCount {
                    let t = Float(i) / Float(tCount - 1)
                    let d = 2.0 + 1.9 * sin(t * .pi * 0.8)
                    let sway = 0.8 * t * sin(t * 9 + Float(k) * 1.7)
                    let y = Self.hoodC - 1.7 - 10.5 * pow(t, 0.9)
                    let ra = a + sway / max(d, 1)
                    path.append(V3(d * cos(ra) + 0.3 * sway, y, d * sin(ra)))
                    radii.append(0.4 * pow(1 - t, 0.85) + 0.04)
                }
                put(Prim.tube(path, radii: radii, sides: hi ? 8 : 5, seamTile: 0.4, material: tentacle, capEnd: true), "body")
            }

            // Legs.
            for (i, az) in Self.azimuths.enumerated() {
                let r = Self.radial(az)
                let h = Self.at(r, Self.hip), k1 = Self.at(r, Self.k1), k2 = Self.at(r, Self.k2), f = Self.at(r, Self.foot)
                let n = String(i)
                let st = hi ? 6 : 3
                put(Self.segment(h, k1, r0: 0.95, r1: 0.8, stations: st, sides: tubeSides, legMetal), "hip" + n)
                put(Prim.superellipsoid(V3(2.0, 2.0, 2.0), exponent: 2, subdivisions: hi ? 8 : 3, material: joint), "knee1_" + n, Xform(translation: k1))
                put(Self.segment(k1, k2, r0: 0.8, r1: 0.6, stations: st, sides: tubeSides, legLow), "knee1_" + n)
                put(Prim.superellipsoid(V3(1.6, 1.6, 1.6), exponent: 2, subdivisions: hi ? 8 : 3, material: joint), "knee2_" + n, Xform(translation: k2))
                put(Self.segment(k2, f + V3(0, 0.5, 0), r0: 0.6, r1: 0.34, stations: st, sides: tubeSides, legMetal), "knee2_" + n)
                put(Prim.superellipsoid(V3(3.2, 0.9, 3.2), exponent: 2.4, subdivisions: hi ? 6 : 3, material: joint), "knee2_" + n,
                    Xform(translation: f + V3(0, -0.05, 0)))
            }

            // Cowl housing, lens frame, glass.
            let cz = Self.cowlY
            put(Prim.tube([V3(0, cz, 4.6), V3(0, cz, 5.8), V3(0, cz, 7.0), V3(0, cz, lensZ - 0.2)], radii: [2.0, 2.1, 1.8, 1.55],
                          sides: tubeSides, seamTile: 0.5, material: hull, capEnd: false), "cowlPitch")
            put(Prim.torus(major: 1.45, minor: 0.2, segments: hi ? 48 : 16, sides: hi ? 8 : 5, material: joint), "cowlPitch",
                Xform(translation: V3(0, cz, lensZ - 0.1), rotation: simd_quatf(angle: .pi / 2, axis: X)))
            put(Prim.lathe([V2(0.01, 0.35), V2(0.6, 0.3), V2(1.2, 0.12), V2(1.3, 0)], segments: hi ? 48 : 16, seamTile: 0.4, material: glass), "cowlPitch",
                Xform(translation: V3(0, cz, lensZ - 0.25), rotation: simd_quatf(angle: .pi / 2, axis: X)))
            for (opt, mat) in [(0, coreDark), (1, core)] {
                put(Prim.superellipsoid(V3(1.1, 1.1, 0.8), exponent: 2, subdivisions: hi ? 8 : 3, material: mat), "lensGlow", option: opt,
                    Xform(translation: V3(0, cz, lensZ - 0.5)))
            }
            for k in 0..<8 {
                let phi = 2 * Float.pi * Float(k) / 8
                let c = V3(cos(phi) * 0.85, sin(phi) * 0.85, 0)
                put(Prim.superellipsoid(V3(0.8, 0.42, 0.08), exponent: 3, subdivisions: hi ? 4 : 2, material: joint), "iris\(k)",
                    Xform(translation: V3(0, cz, lensZ + 0.15) + c, rotation: simd_quatf(angle: phi, axis: Z)))
            }
        }

        rig.lights = [RigLight(name: "lens-glow", part: "cowlPitch", position: V3(0, Self.cowlY, lensZ + 0.8), direction: V3(0, 0, 1),
                               color: V3(0.2, 1.0, 0.4), intensity: 4000, attenuationRadius: 80)]

        rig.states = [
            RigState("sunk"),
            RigState("stand", ["rise": 1]),
            RigState("step-front", ["rise": 1, "stride": 1]),
            RigState("step-back", ["rise": 1, "stride": -1]),
            RigState("look-left", ["rise": 1, "cowl": -1]),
            RigState("look-right", ["rise": 1, "cowl": 1]),
            RigState("charge", ["rise": 1, "charge": 1], options: ["lensGlow": 1]),
            RigState("fire-down", ["rise": 1, "aim": 1, "charge": 1], options: ["lensGlow": 1]),
        ]
        return rig
    }
}
