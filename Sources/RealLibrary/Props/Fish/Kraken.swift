import simd
import Foundation

/// Kraken, 18 m mantle and head with two glowing eyes and 8 tapered arms about 30 m long, each with two rows of cup suckers.
/// Wet crimson mantle, violet arms, pale suckers. Head faces +Z, up +Y, origin at the waterline under the head.
/// Joints: `rise` 0...1 (body sinks 22 m at 0, arms droop at 0 and lift as it rises), `arms` -1...1 (arms sweep inward to outward),
/// `curl` 0...1 (arm tips curl up through three segments), `thrash` -1...1 (alternating arm sway) and `eye` 0...1 (pupils switch
/// to emissive red at 0.5, with a red point light each). Arm 0 points at +Z, arms step 45 degrees toward +X.
public struct Kraken: RealArticulated {
    public static let id = "kraken"
    public static let summary = "18 m kraken with wet crimson mantle, glowing eyes, 8 tapered 30 m arms with sucker rows and joints rise, arms, curl, thrash, eye."
    public static let tags = ["prop", "animal", "marine", "monster", "outdoor", "articulated"]
    public static let budget = 14_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 14, distance: 1.1, studio: true)

    /// Mantle skin.
    public var mantle: MaterialKey = "plastic.gloss:8C1B3A"
    /// Head skin.
    public var head: MaterialKey = "plastic.gloss:6E1530"
    /// Arm skin.
    public var arm: MaterialKey = "plastic.gloss:5B2A78"
    /// Sucker cups.
    public var sucker: MaterialKey = "plastic.gloss:E9C9D6"
    /// Fins.
    public var fin: MaterialKey = "plastic.gloss:4E2468"
    /// Eyeball.
    public var eyeball: MaterialKey = "fish.eye-amber"
    /// Pupil at rest.
    public var pupil: MaterialKey = "fish.eye-dark"
    /// Pupil when `eye` is 0.5 or more.
    public var pupilGlow: MaterialKey = "emissive.signal-red"
    public init() {}

    private static let armCount = 8
    private static let armLength: Float = 30
    private static let sink: Float = 22
    private static let root = V3(0, 3.0, 3.2)
    private static let mantleBase = V3(0, 4.2, -0.5)
    private static let mantleLean: Float = -50
    private static let headCentre = V3(0, 4.0, 1.6)
    private static let headHalf = V3(3.0, 2.6, 3.5)

    private struct Rng {
        var s: UInt64
        mutating func f() -> Float {
            s = s &* 6364136223846793005 &+ 1442695040888963407
            return Float((s >> 40) & 0xFFFFFF) / Float(0x1000000)
        }
    }

    // MARK: Arm curve

    private static func azimuth(_ i: Int) -> Float { Float(i) * .pi / 4 }

    /// Centreline of arm `i` at u in 0...1 (asset space, rest pose).
    private static func armPoint(_ i: Int, _ u: Float, phase: Float) -> V3 {
        let psi = azimuth(i)
        let d = V3(sin(psi), 0, cos(psi))
        let side = V3(cos(psi), 0, -sin(psi))
        let arch = 0.2 + 0.8 * (1 + cos(psi)) / 2
        let y = 10 * arch * u * (1 - u) - 4.5 * u * u
        let lat = 2.2 * sin(2 * .pi * 1.1 * u + phase) * u
        let h = 1.6 + 27 * u
        return root + d * h + side * lat + V3(0, y, 0)
    }

    private static func armRadius(_ u: Float) -> Float { 0.06 + 0.92 * pow(1 - u, 1.1) }

    private static func tangent(_ i: Int, _ u: Float, phase: Float) -> V3 {
        let e: Float = 0.01
        return (armPoint(i, min(1, u + e), phase: phase) - armPoint(i, max(0, u - e), phase: phase)).normalized
    }

    private static func bendAxis(_ i: Int, _ u: Float, phase: Float) -> V3 {
        let t = tangent(i, u, phase: phase)
        let a = simd_cross(t, V3(0, 1, 0))
        return simd_length(a) < 1e-4 ? V3(1, 0, 0) : a.normalized
    }

    /// Sucker cup, base on the skin at origin, opening along +Y.
    private static func cup(_ s: Float, material: MaterialKey, segments: Int) -> Surface {
        Prim.lathe([V2(1.0 * s, 0), V2(0.8 * s, 0.38 * s), V2(0, 0.10 * s)], segments: segments, seamTile: 0.5, material: material)
    }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [60])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0)
        var rng = Rng(s: seed &* 2654435761 &+ 29)

        // Drivers first so mimics resolve.
        _ = rig.part("rise", pivot: .zero, joint: .hinge(axis: X, 0...1, duration: 3.6))
        _ = rig.part("arms", pivot: .zero, joint: .hinge(axis: X, -1...1, duration: 1.4))
        _ = rig.part("curl", pivot: .zero, joint: .hinge(axis: X, 0...1, duration: 1.6))
        _ = rig.part("thrash", pivot: .zero, joint: .hinge(axis: X, -1...1, duration: 1.0))
        _ = rig.part("eye", pivot: .zero, joint: .hinge(axis: X, 0...1, duration: 0.6))

        _ = rig.part("riseBody", pivot: .zero, joint: Joint(.prismatic, axis: Y, range: -Self.sink...0, mimic: .init("rise", ratio: Self.sink, offset: -Self.sink)))
        _ = rig.part("pupils", parent: "riseBody", pivot: .zero, joint: .fixed, options: 2)
        rig.optionLinks = [RigOptionLink(part: "pupils", joint: "eye", thresholds: [0.5])]

        // Arm chains: A (sweep), T (thrash), U (unfurl), then curl c and sway w per segment.
        let segN = Self.armCount
        var phases: [Float] = []
        for i in 0..<segN {
            phases.append(rng.f() * 2 * .pi)
            let psi = Self.azimuth(i)
            let sweepSign: Float = (psi > 0.01 && psi < .pi - 0.01) || i == 0 ? 1 : -1
            let altSign: Float = i % 2 == 0 ? 1 : -1
            let root = Self.root
            let n = "a\(i)"
            _ = rig.part("\(n)A", parent: "riseBody", pivot: root, joint: Joint(.revolute, axis: Y, range: -40...40, mimic: .init("arms", ratio: 14 * sweepSign)))
            _ = rig.part("\(n)T", parent: "\(n)A", pivot: root, joint: Joint(.revolute, axis: Y, range: -40...40, mimic: .init("thrash", ratio: 10 * altSign)))
            _ = rig.part("\(n)U", parent: "\(n)T", pivot: root, joint: Joint(.revolute, axis: Self.bendAxis(i, 0.05, phase: phases[i]), range: -60...15, mimic: .init("rise", ratio: 45, offset: -45)))
            var parent = "\(n)U"
            let curlRatio: [Float] = [20, 40, 55]
            let swayRatio: [Float] = [6, 10, 14]
            for k in 0..<3 {
                let u0 = Float(k) / 3
                let pivot = Self.armPoint(i, u0, phase: phases[i])
                _ = rig.part("\(n)c\(k)", parent: parent, pivot: pivot,
                             joint: Joint(.revolute, axis: Self.bendAxis(i, u0 + 0.02, phase: phases[i]), range: -20...130, mimic: .init("curl", ratio: curlRatio[k])))
                _ = rig.part("\(n)w\(k)", parent: "\(n)c\(k)", pivot: pivot,
                             joint: Joint(.revolute, axis: Y, range: -40...40, mimic: .init("thrash", ratio: swayRatio[k] * altSign)))
                parent = "\(n)w\(k)"
            }
        }

        for l in 0..<2 {
            let perSeg = [8, 4][l], sides = [12, 8][l], cupSegs = [8, 6][l]
            let suckers = [9, 5][l]
            let cupMat = sucker

            // Mantle: lathe along +Y, leaned back (-Z) and up.
            let mp = [24, 14][l]
            var profile: [V2] = []
            for j in 0..<mp {
                let t = Float(j) / Float(mp - 1)
                let r = 10.7 * pow(t, 0.5) * pow(1 - t, 0.85) + (j == 0 || j == mp - 1 ? 0 : 0.02)
                profile.append(V2(r, t * 18))
            }
            let q = simd_quatf(degrees: Self.mantleLean, axis: X)
            let dir = q.act(Y)
            rig.add(Prim.lathe(profile, segments: [32, 20][l], seamTile: 0.5, material: mantle), Xform(translation: Self.mantleBase, rotation: q), to: "riseBody", lods: l...l)

            // Fins on the upper mantle, plane through the mantle axis and X.
            let ft: Float = 0.74
            let fr = 10.7 * pow(ft, 0.5) * pow(1 - ft, 0.85)
            let fc = Self.mantleBase + dir * (ft * 18)
            for side: Float in [1, -1] {
                let f = Prim.superellipsoid(V3(4.0, 6.0, 0.35), exponent: 2, subdivisions: [5, 3][l], material: fin)
                rig.add(f, Xform(translation: fc + V3(side * (fr + 1.2), 0, 0), rotation: q * simd_quatf(degrees: side * 12, axis: Y)), to: "riseBody", lods: l...l)
            }

            // Head.
            rig.add(Prim.superellipsoid(Self.headHalf * 2, exponent: 2, subdivisions: [7, 4][l], material: head), Xform(translation: Self.headCentre), to: "riseBody", lods: l...l)

            // Eyes and pupils with red lights.
            for side: Float in [1, -1] {
                let a = Self.headHalf
                let ex: Float = 2.6, ey: Float = 4.6
                let dx = ex / a.x, dy = (ey - Self.headCentre.y) / a.y
                let dz = a.z * sqrt(max(0.01, 1 - dx * dx - dy * dy))
                let c = V3(side * ex, ey, Self.headCentre.z + dz)
                let nrm = V3(side * ex / (a.x * a.x), (ey - Self.headCentre.y) / (a.y * a.y), dz / (a.z * a.z)).normalized
                rig.add(Prim.superellipsoid(V3(1.8, 1.8, 1.8), exponent: 2, subdivisions: [4, 2][l], material: eyeball), Xform(translation: c), to: "riseBody", lods: l...l)
                let pn = (nrm + V3(0, 0, 0.5)).normalized
                let pc = c + pn * 0.72
                let pq = simd_quatf(from: V3(0, 0, 1), to: pn)
                for (opt, m) in [(0, pupil), (1, pupilGlow)] {
                    rig.add(Prim.superellipsoid(V3(0.5, 1.05, 0.4), exponent: 2, subdivisions: [2, 1][l], material: m), Xform(translation: pc, rotation: pq), to: "pupils", option: opt, lods: l...l)
                }
                if l == 0 {
                    rig.lights.append(RigLight(name: side > 0 ? "eyeL" : "eyeR", part: "pupils", option: 1, position: pc + pn * 0.8,
                                               direction: pn, color: V3(1, 0.08, 0.04), intensity: 1800, attenuationRadius: 30))
                }
            }

            // Arms.
            for i in 0..<segN {
                let ph = phases[i]
                let n = "a\(i)"
                for k in 0..<3 {
                    let part = "\(n)w\(k)"
                    var path: [V3] = [], radii: [Float] = [], us: [Float] = []
                    for j in 0...perSeg {
                        let u = (Float(k) + Float(j) / Float(perSeg)) / 3
                        us.append(u)
                        path.append(Self.armPoint(i, u, phase: ph))
                        radii.append(Self.armRadius(u))
                    }
                    let last = k == 2
                    rig.add(Prim.tube(path, radii: radii, sides: sides, seamTile: 0.5, material: arm, capEnd: last), to: part, lods: l...l)
                    if !last {
                        let r = radii[perSeg] * 1.04
                        rig.add(Prim.superellipsoid(V3(2 * r, 2 * r, 2 * r), exponent: 2, subdivisions: [2, 1][l], material: arm), Xform(translation: path[perSeg]), to: part, lods: l...l)
                    }
                    // Two sucker rows on the underside, second row staggered.
                    var cups = Surface(material: cupMat)
                    for row in 0..<2 {
                        let ang: Float = (row == 0 ? 28 : -28) * .pi / 180
                        for m in 0..<suckers {
                            let uu = 0.07 + 0.86 * (Float(m) + (row == 0 ? 0 : 0.5)) / Float(suckers)
                            if uu < us[0] - 1e-5 || uu >= us[perSeg] - (last ? -1e-5 : 1e-5) { continue }
                            let t = Self.tangent(i, uu, phase: ph)
                            var down = V3(0, -1, 0) - t * simd_dot(V3(0, -1, 0), t)
                            down = down.normalized
                            let sd = simd_cross(t, down).normalized
                            let dn = (down * cos(ang) + sd * sin(ang)).normalized
                            let r = Self.armRadius(uu)
                            let s = max(0.05, 0.52 * r * (0.92 + 0.16 * rng.f()))
                            let p = Self.armPoint(i, uu, phase: ph) + dn * (r * 0.96)
                            cups.append(Self.cup(s, material: cupMat, segments: cupSegs), Xform(translation: p, rotation: simd_quatf(from: Y, to: dn)))
                        }
                    }
                    if !cups.indices.isEmpty { rig.add(cups, to: part, lods: l...l) }
                }
            }
        }

        rig.states = [
            RigState("rest"),
            RigState("risen", ["rise": 1]),
            RigState("alert", ["rise": 1, "arms": 0.4, "curl": 0.2, "eye": 1], options: ["pupils": 1]),
            RigState("flare", ["rise": 1, "arms": 1, "eye": 1], options: ["pupils": 1]),
            RigState("coil", ["rise": 1, "arms": -1, "curl": 1]),
            RigState("thrash-left", ["rise": 1, "thrash": 1]),
            RigState("thrash-right", ["rise": 1, "thrash": -1]),
        ]
        rig.defaultState = "risen"
        return rig
    }
}
