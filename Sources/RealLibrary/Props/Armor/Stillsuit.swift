import simd
import Foundation

/// Desert stillsuit kit, life size for a 1.75 m wearer: a hooded cowl with a face veil, glowing eye slit and two nose tubes,
/// a ribbed knit torso (24 rib rings) with a brass collar manifold and leather harness, a belt with pump pouches and reclaim
/// tubes, and two ribbed sleeves with cuffs and gloved hands. Original shapes only: no logos, no film marks.
/// Origin at the neck base, face toward +Z, up +Y, wearer's left = +X.
///
/// Kit parts (pivots in asset space): `hood` (0, 0.02, 0), `torso` (0, -0.18, 0), `belt` (0, -0.62, 0),
/// `armL` / `armR` (+-0.20, -0.05, 0) with the sleeve along -Y to the wrist at y = -0.6.
///
/// Joints (set with `setJoints`): `spice` (0...1) lights the eyes, `inhale` (0...1) is an empty driver for chest rise.
/// Follower `eyesLit` switches with `spice` at 0.05. 2 LODs.
public struct Stillsuit: RealArticulated {
    public static let id = "stillsuit"
    public static let summary = "Desert stillsuit: ribbed knit torso and sleeves, hooded cowl with nose tubes, tan harness and brass catch-pocket fittings."
    public static let tags = ["prop", "fabric", "articulated", "glowing"]
    public static let budget = 20_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 6, distance: 1.1)

    /// Ribbed knit body of the suit.
    public var cloth: MaterialKey = "fabric.knit"
    /// Straps, pouches, gloves.
    public var leather: MaterialKey = "leather.tan"
    /// Collar manifold, buckle, tube clamps.
    public var brass: MaterialKey = "metal.brass-aged"
    /// Nose tubes and reclaim hoses.
    public var tubing: MaterialKey = "rubber.tubing"
    /// Lit eyes.
    public var eyesLit: MaterialKey = "emissive.nebula-blue"
    public init() {}

    static let shoulderX: Float = 0.20
    static let wristY: Float = -0.6

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [3])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0)

        for name in ["spice", "inhale"] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.5))
        }
        let pivots: [(String, V3)] = [
            ("hood", V3(0, 0.02, 0)), ("torso", V3(0, -0.18, 0)), ("belt", V3(0, -0.62, 0)),
            ("armL", V3(Self.shoulderX, -0.05, 0)), ("armR", V3(-Self.shoulderX, -0.05, 0)),
        ]
        for (name, p) in pivots { _ = rig.part(name, pivot: p, joint: .fixed) }
        _ = rig.part("eyesLit", parent: "hood", pivot: V3(0, 0.17, 0.1), joint: .fixed, options: 2)
        rig.optionLinks = [RigOptionLink(part: "eyesLit", joint: "spice", thresholds: [0.05])]

        for l in 0..<2 {
            let hi = l == 0
            let sides = hi ? 48 : 16
            func put(_ s: Surface, _ part: String, option: Int = 0, _ x: Xform = .identity) {
                rig.add(s, x, to: part, option: option, lods: l...l)
            }
            func ring(_ part: String, _ at: V3, major: Float, minor: Float, _ mat: MaterialKey, tilt: simd_quatf = simd_quatf(angle: 0, axis: V3(0, 1, 0)), scale: V3 = V3(1, 1, 1)) {
                put(Prim.torus(major: major, minor: minor, segments: hi ? 48 : 16, sides: hi ? 12 : 6, material: mat), part,
                    Xform(translation: at, rotation: tilt, scale: scale))
            }
            func rivet(_ part: String, _ at: V3, r: Float = 0.006) {
                put(Prim.lathe([V2(r, 0), V2(r * 0.95, 0.003), V2(r * 0.55, 0.006), V2(0.001, 0.007)], segments: hi ? 16 : 6, seamTile: 0.02, material: brass), part,
                    Xform(translation: at, rotation: simd_quatf(angle: .pi / 2, axis: X)))
            }

            // MARK: Hood: cowl shell, face veil, eye slit (dark or lit), two nose tubes into the collar
            do {
                put(Prim.superellipsoid(V3(0.27, 0.32, 0.31), exponent: 2.3, subdivisions: hi ? 6 : 3, material: cloth), "hood", Xform(translation: V3(0, 0.12, -0.01)))
                // Cowl fold draped on the shoulders.
                ring("hood", V3(0, 0.0, 0), major: 0.15, minor: 0.035, cloth, scale: V3(1, 1, 0.9))
                // Face veil over the lower face.
                put(Prim.superellipsoid(V3(0.19, 0.15, 0.16), exponent: 2.6, subdivisions: hi ? 5 : 3, material: leather), "hood", Xform(translation: V3(0, 0.07, 0.075)))
                // Eye slit band: dark option 0, lit blue option 1.
                put(Prim.superellipsoid(V3(0.19, 0.035, 0.05), exponent: 3, subdivisions: hi ? 5 : 3, material: tubing), "eyesLit", option: 0, Xform(translation: V3(0, 0.1, 0.0)))
                for sx in [Float(-1), 1] {
                    put(Prim.superellipsoid(V3(0.065, 0.026, 0.03), exponent: 2.4, subdivisions: hi ? 5 : 3, material: eyesLit), "eyesLit", option: 1, Xform(translation: V3(sx * 0.053, 0.1, 0.005)))
                }
                // Nose tubes: out of the veil, curving down to the collar manifold.
                for sx in [Float(-1), 1] {
                    let path = [V3(sx * 0.02, 0.1, 0.13), V3(sx * 0.05, 0.05, 0.17), V3(sx * 0.085, -0.02, 0.15), V3(sx * 0.1, -0.1, 0.14)]
                    put(Prim.tube(path, radii: path.map { _ in 0.007 }, sides: hi ? 24 : 8, seamTile: 0.03, material: tubing, capEnd: true), "hood")
                    ring("hood", V3(sx * 0.02, 0.1, 0.125), major: 0.008, minor: 0.003, brass, tilt: simd_quatf(angle: .pi / 2, axis: X))
                }
            }

            // MARK: Torso: ribbed knit core, brass collar manifold, harness straps, catch-pocket buckle
            do {
                put(Prim.superellipsoid(V3(0.38, 0.52, 0.22), exponent: 2.6, subdivisions: hi ? 6 : 3, material: cloth), "torso", Xform(translation: V3(0, -0.12, -0.01)))
                let ribs = hi ? 24 : 8
                for k in 0..<ribs {
                    let y = 0.1 - 0.4 * Float(k) / Float(ribs - 1)
                    let w = 0.172 + 0.012 * sin(Float(k) / Float(ribs - 1) * .pi)
                    ring("torso", V3(0, y - 0.0, -0.01), major: w, minor: 0.0045, cloth, scale: V3(1, 1, 0.62))
                }
                put(Prim.lathe([V2(0.07, 0), V2(0.075, 0.01), V2(0.06, 0.03), V2(0.05, 0.04)], segments: sides, seamTile: 0.04, material: brass), "torso",
                    Xform(translation: V3(0, 0.08, 0.1), rotation: simd_quatf(angle: .pi / 2, axis: X)))
                for sx in [Float(-1), 1] {
                    let strap = [V3(sx * 0.1, 0.12, 0.11), V3(sx * 0.12, -0.1, 0.14), V3(sx * 0.1, -0.36, 0.11)]
                    put(Prim.tube(strap, radii: strap.map { _ in 0.015 }, sides: hi ? 24 : 8, seamTile: 0.05, material: leather, capEnd: true), "torso")
                    rivet("torso", V3(sx * 0.12, -0.02, 0.155))
                }
                put(Prim.superellipsoid(V3(0.06, 0.05, 0.02), exponent: 3, subdivisions: hi ? 5 : 3, material: brass), "torso", Xform(translation: V3(0, -0.08, 0.15)))
                // Recovery hose from the collar down the left flank to the belt.
                let hose = [V3(0.15, 0.06, 0.04), V3(0.19, -0.1, 0.06), V3(0.18, -0.3, 0.07), V3(0.12, -0.42, 0.08)]
                put(Prim.tube(hose, radii: hose.map { _ in 0.008 }, sides: hi ? 24 : 8, seamTile: 0.03, material: tubing, capEnd: true), "torso")
            }

            // MARK: Belt: leather band, two pump pouches, reclaim tubes
            do {
                ring("belt", V3(0, 0, 0), major: 0.2, minor: 0.03, leather, scale: V3(1, 1, 0.72))
                ring("belt", V3(0, -0.05, 0), major: 0.19, minor: 0.012, cloth, scale: V3(1, 1, 0.72))
                for sx in [Float(-1), 1] {
                    put(Prim.superellipsoid(V3(0.08, 0.1, 0.05), exponent: 3, subdivisions: hi ? 5 : 3, material: leather), "belt", Xform(translation: V3(sx * 0.17, -0.01, 0.1)))
                    rivet("belt", V3(sx * 0.17, 0.03, 0.128))
                    let path = [V3(sx * 0.17, -0.04, 0.12), V3(sx * 0.22, -0.14, 0.08), V3(sx * 0.2, -0.3, 0.04)]
                    put(Prim.tube(path, radii: path.map { _ in 0.008 }, sides: hi ? 24 : 8, seamTile: 0.03, material: tubing, capEnd: true), "belt")
                }
                put(Prim.superellipsoid(V3(0.07, 0.05, 0.02), exponent: 3, subdivisions: hi ? 5 : 3, material: brass), "belt", Xform(translation: V3(0, 0.0, 0.147)))
            }

            // MARK: Sleeves: ribbed knit, cuff and gloved hand
            for (sx, name) in [(Float(1), "armL"), (Float(-1), "armR")] {
                let top = V3(sx * 0.2, -0.05, 0)
                let bot = V3(sx * 0.225, Self.wristY, 0)
                let mid = (top + bot) * 0.5
                put(Prim.tube([top, mid, bot], radii: [0.055, 0.047, 0.036], sides: hi ? 32 : 10, seamTile: 0.05, material: cloth, capEnd: true), name)
                for k in 0..<(hi ? 10 : 4) {
                    let u = (Float(k) + 0.5) / Float(hi ? 10 : 4)
                    let p = top + (bot - top) * u
                    ring(name, p, major: 0.0545 - 0.017 * u, minor: 0.0035, cloth)
                }
                ring(name, bot + V3(0, 0.02, 0), major: 0.038, minor: 0.009, leather)
                put(Prim.superellipsoid(V3(0.085, 0.14, 0.05), exponent: 2.4, subdivisions: hi ? 5 : 3, material: leather), name, Xform(translation: bot + V3(0, -0.075, 0)))
                put(Prim.superellipsoid(V3(0.11, 0.1, 0.12), exponent: 2.2, subdivisions: hi ? 5 : 3, material: cloth), name, Xform(translation: top + V3(0, 0.0, 0), scale: V3(1, 1, 1)))
                rivet(name, top + V3(sx * 0.05, -0.1, 0.05))
            }
        }

        rig.states = [
            RigState("rest", [:]),
            RigState("lit", ["spice": 1], options: ["eyesLit": 1]),
            RigState("inhale", ["spice": 1, "inhale": 1], options: ["eyesLit": 1]),
        ]
        return rig
    }
}
