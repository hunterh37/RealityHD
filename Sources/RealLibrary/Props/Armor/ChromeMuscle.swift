import simd
import Foundation

/// Meme chrome muscle suit, life size for a 1.75 m wearer: a polished liquid-metal torso with sculpted pecs, a six-pack,
/// trapezius and deltoids, two flexed-capable arms (bicep bulge, forearm), a belt ring and a jawline chin guard with
/// light strips. Superellipsoid muscle masses (6 subdivisions) and 48-side tubes. Original shapes only.
/// Origin at the neck base, face toward +Z, up +Y, wearer's left = +X.
///
/// Kit parts (pivots in asset space): `torso` (0, -0.2, 0.05), `belt` (0, -0.58, 0), `shoulderL` / `shoulderR` (+-0.21, -0.05, 0),
/// `armL` / `armR` (+-0.26, -0.3, 0) with the forearm along -Y, `jaw` (0, 0.1, 0.06).
///
/// Joints (set with `setJoints`): `flex` (0...1) is an empty driver for the bicep and pec swell, `shine` (0...1) is an empty
/// driver for the chrome sheen sweep, `flash` (0...1) lights the jawline strips. Follower `jawLit` switches with `flash`
/// at 0.05. 2 LODs.
public struct ChromeMuscle: RealArticulated {
    public static let id = "chrome-muscle"
    public static let summary = "Polished liquid-metal muscle suit: sculpted pecs and abs, deltoids, biceps, belt ring and a jawline guard with light strips."
    public static let tags = ["prop", "metal", "articulated", "glowing"]
    public static let budget = 24_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 6, distance: 1.2)

    /// Muscle masses.
    public var chrome: MaterialKey = "metal.chrome"
    /// Grooves between muscle groups, belt trim.
    public var steel: MaterialKey = "metal.steel"
    /// Belt, seams.
    public var dark: MaterialKey = "plastic.black"
    /// Lit jawline strips.
    public var jawLit: MaterialKey = "emissive.signal-white"
    public init() {}

    static let shoulderX: Float = 0.21
    static let elbowX: Float = 0.27
    static let elbowY: Float = -0.3

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [3])
        let Y = V3(0, 1, 0), Z = V3(0, 0, 1)

        for name in ["flex", "shine", "flash"] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.5))
        }
        let pivots: [(String, V3)] = [
            ("torso", V3(0, -0.2, 0.05)), ("belt", V3(0, -0.58, 0)),
            ("shoulderL", V3(Self.shoulderX, -0.05, 0)), ("shoulderR", V3(-Self.shoulderX, -0.05, 0)),
            ("armL", V3(Self.elbowX, Self.elbowY, 0)), ("armR", V3(-Self.elbowX, Self.elbowY, 0)),
            ("jaw", V3(0, 0.1, 0.06)),
        ]
        for (name, p) in pivots { _ = rig.part(name, pivot: p, joint: .fixed) }
        _ = rig.part("jawLit", parent: "jaw", pivot: V3(0, 0.1, 0.06), joint: .fixed, options: 2)
        rig.optionLinks = [RigOptionLink(part: "jawLit", joint: "flash", thresholds: [0.05])]

        for l in 0..<2 {
            let hi = l == 0
            let sides = hi ? 48 : 16
            let sub = hi ? 6 : 3
            func put(_ s: Surface, _ part: String, option: Int = 0, _ x: Xform = .identity) {
                rig.add(s, x, to: part, option: option, lods: l...l)
            }
            func mass(_ part: String, _ size: V3, at: V3, exponent: Float = 2.6, mat: MaterialKey? = nil, tilt: simd_quatf = simd_quatf(angle: 0, axis: V3(0, 1, 0))) {
                put(Prim.superellipsoid(size, exponent: exponent, subdivisions: sub, material: mat ?? chrome), part,
                    Xform(translation: at, rotation: tilt))
            }
            func ring(_ part: String, _ at: V3, major: Float, minor: Float, _ mat: MaterialKey, scale: V3 = V3(1, 1, 1)) {
                put(Prim.torus(major: major, minor: minor, segments: hi ? 48 : 16, sides: hi ? 12 : 6, material: mat), part,
                    Xform(translation: at, scale: scale))
            }

            // MARK: Torso: ribcage, pecs, abs grid, serratus, traps
            do {
                mass("torso", V3(0.4, 0.5, 0.22), at: V3(0, -0.2, -0.02), exponent: 2.9)
                for sx in [Float(-1), 1] {
                    mass("torso", V3(0.21, 0.15, 0.12), at: V3(sx * 0.1, -0.06, 0.1), exponent: 2.4, tilt: simd_quatf(angle: sx * 0.12, axis: Z))
                    mass("torso", V3(0.07, 0.3, 0.07), at: V3(sx * 0.23, -0.22, 0.06), exponent: 2.3)
                }
                for row in 0..<4 {
                    for sx in [Float(-1), 1] {
                        mass("torso", V3(0.1, 0.07, 0.06), at: V3(sx * 0.052, -0.22 - 0.075 * Float(row), 0.115), exponent: 2.4)
                    }
                }
                // Center groove and pec underline in dark steel.
                put(Prim.tube([V3(0, -0.1, 0.112), V3(0, -0.28, 0.125), V3(0, -0.5, 0.115)], radii: [0.004, 0.004, 0.004], sides: hi ? 12 : 6, seamTile: 0.05, material: steel, capEnd: true), "torso")
                mass("torso", V3(0.18, 0.1, 0.14), at: V3(0, 0.04, -0.03), exponent: 2.2)
            }

            // MARK: Belt ring and buckle
            do {
                ring("belt", .zero, major: 0.2, minor: 0.03, dark, scale: V3(1, 1, 0.72))
                ring("belt", V3(0, 0.0, 0), major: 0.2, minor: 0.012, steel, scale: V3(1.01, 1, 0.73))
                mass("belt", V3(0.1, 0.07, 0.03), at: V3(0, 0, 0.15), exponent: 3, mat: steel)
            }

            // MARK: Shoulders: deltoid cap and trapezius slope
            for (sx, name) in [(Float(1), "shoulderL"), (Float(-1), "shoulderR")] {
                mass(name, V3(0.15, 0.15, 0.15), at: V3(sx * 0.25, -0.05, 0), exponent: 2.2)
                mass(name, V3(0.16, 0.06, 0.12), at: V3(sx * 0.12, 0.04, -0.03), exponent: 2.2, tilt: simd_quatf(angle: -sx * 0.35, axis: Z))
            }

            // MARK: Arms: upper arm, bicep bulge, elbow, forearm
            for (sx, name) in [(Float(1), "armL"), (Float(-1), "armR")] {
                let e = V3(sx * Self.elbowX, Self.elbowY, 0)
                put(Prim.tube([V3(sx * 0.255, -0.08, 0), V3(sx * 0.26, -0.2, 0), e], radii: [0.062, 0.058, 0.048], sides: sides, seamTile: 0.05, material: chrome, capEnd: true), name)
                mass(name, V3(0.1, 0.16, 0.1), at: V3(sx * 0.265, -0.17, 0.02), exponent: 2.2)
                mass(name, V3(0.075, 0.1, 0.085), at: V3(sx * 0.255, -0.18, -0.03), exponent: 2.2)
                put(Prim.tube([e, e + V3(0, -0.12, 0.005), e + V3(0, -0.26, 0)], radii: [0.052, 0.054, 0.04], sides: sides, seamTile: 0.05, material: chrome, capEnd: true), name)
                ring(name, e + V3(0, -0.27, 0), major: 0.04, minor: 0.008, steel)
            }

            // MARK: Jawline chin guard: curved plate with a light strip underneath (option 0 dark, option 1 lit)
            do {
                let arc = [V3(-0.075, 0.1, 0.01), V3(-0.06, 0.07, 0.07), V3(0, 0.06, 0.095), V3(0.06, 0.07, 0.07), V3(0.075, 0.1, 0.01)]
                put(Prim.tube(arc, radii: arc.map { _ in 0.007 }, sides: hi ? 24 : 8, seamTile: 0.03, material: chrome, capEnd: true), "jaw")
                let strip = arc.map { $0 + V3(0, -0.012, 0.004) }
                put(Prim.tube(strip, radii: strip.map { _ in 0.004 }, sides: hi ? 16 : 6, seamTile: 0.03, material: jawLit, capEnd: true), "jawLit", option: 1)
                put(Prim.tube(strip, radii: strip.map { _ in 0.004 }, sides: hi ? 16 : 6, seamTile: 0.03, material: dark, capEnd: true), "jawLit", option: 0)
            }
        }

        rig.states = [
            RigState("rest", [:]),
            RigState("flex", ["flex": 1, "shine": 1]),
            RigState("flash", ["flex": 1, "shine": 1, "flash": 1], options: ["jawLit": 1]),
        ]
        return rig
    }
}
