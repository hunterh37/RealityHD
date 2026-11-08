import simd
import Foundation

/// Apollo-style lunar module, 9.2 m across the footpads and about 6.3 m from pad soles to the S-band dish. Gold foil octagonal descent
/// stage (4.7 m across corners, 1.65 m tall) with a descent engine bell, an ascent stage with a hatch, porch and two windows on the front,
/// four landing legs with footpads, four RCS quads, a ladder down the forward leg, an S-band dish and a rendezvous radar dish.
/// Origin at the centre of the descent stage floor (bottom plane), hatch faces +Z, up +Y. Legs sit at +Z, +X, -Z, -X.
/// Joints: `legs` 0...1 (legs fold under the stage at 0 and deploy at 1), `hatch` 0...1 (door swings out up to 110 degrees),
/// `ladder` 0...1 (ladder slides down the forward leg, 0.8 m of travel) and `thrust` 0...1 (engine bell lining switches to
/// emissive at 0.5, with a white point light under the bell).
public struct LunarLander: RealArticulated {
    public static let id = "lunar-lander"
    public static let summary = "9 m Apollo-style lunar module: gold foil octagonal descent stage, ascent stage with windows and hatch, four legs with footpads, engine bell, RCS quads, ladder, dish; joints legs, hatch, ladder, thrust."
    public static let tags = ["prop", "aerospace", "lunar", "space", "vehicle", "metal", "outdoor", "articulated"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 14, distance: 1.2, studio: true)

    /// Descent stage panels, core and leg struts wrapped in Kapton.
    public var gold: MaterialKey = "insulation.foil-gold"
    /// Ascent stage skin, secondary struts, rails, mylar-silver trim.
    public var silver: MaterialKey = "metal.aluminum-brushed"
    /// Hatch door, RCS booms, dish backs.
    public var white: MaterialKey = "metal.powder-white"
    /// Window frames, hatch recess, RCS boxes, bay plates.
    public var dark: MaterialKey = "plastic.matte:2A2C2E"
    /// Window glass.
    public var glass: MaterialKey = "glass.lens-coated"
    /// Engine bell shell.
    public var bell: MaterialKey = "metal.steel"
    /// Bell lining at rest.
    public var lining: MaterialKey = "metal.heat-tint-cold"
    /// Bell lining when `thrust` is 0.5 or more.
    public var liningGlow: MaterialKey = "emissive.warm"
    public init() {}

    private static let circumRadius: Float = 2.35
    private static let stageHeight: Float = 1.65
    private static let legTop: (r: Float, y: Float) = (2.25, 1.5)
    private static let legFoot: (r: Float, y: Float) = (4.15, -1.2)
    private static let padY: Float = -1.42
    private static let legFold: Float = 40
    private static let ladderTravel: Float = 0.8
    private static let cabinCentre = V3(0, 2.7, 0.05)
    private static let cabinFront: Float = 1.25

    /// Point at azimuth `a` (0 = +Z, pi/2 = +X), radius `r`, height `y` and tangent offset `q`.
    private static func pt(_ a: Float, _ r: Float, _ y: Float, _ q: Float = 0) -> V3 {
        V3(sin(a) * r + cos(a) * q, y, cos(a) * r - sin(a) * q)
    }

    private static func box(_ size: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.03, bs: Int, yaw: Float = 0, roll: Float = 0) -> (Surface, Xform) {
        (Prim.roundedBox(size, radius: r, bevelSegments: bs, material: mat),
         Xform(translation: c, rotation: simd_quatf(angle: yaw, axis: V3(0, 1, 0)) * simd_quatf(angle: roll, axis: V3(0, 0, 1))))
    }

    /// RCS or engine nozzle, base at origin, opening along +Y.
    private static func nozzle(_ s: Float, segments: Int, material: MaterialKey) -> Surface {
        Prim.lathe([V2(0.05 * s, 0), V2(0.02 * s, 0.04 * s), V2(0.018 * s, 0.07 * s), V2(0.055 * s, 0.2 * s)],
                   segments: segments, seamTile: 0.2, material: material)
    }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [30])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0)

        // Drivers first so mimics resolve.
        _ = rig.part("legs", pivot: .zero, joint: .hinge(axis: X, 0...1, duration: 2.4))
        _ = rig.part("hatch", pivot: .zero, joint: .hinge(axis: X, 0...1, duration: 1.8))
        _ = rig.part("ladder", pivot: .zero, joint: .hinge(axis: X, 0...1, duration: 2.0))
        _ = rig.part("thrust", pivot: .zero, joint: .hinge(axis: X, 0...1, duration: 0.5))

        // Legs: authored deployed, folded by the mimic offset. Positive angle about the tangent swings the foot inward.
        let top = Self.legTop, foot = Self.legFoot
        for k in 0..<4 {
            let a = Float(k) * .pi / 2
            let t = V3(cos(a), 0, -sin(a))
            _ = rig.part("leg\(k)", pivot: Self.pt(a, top.r, top.y),
                         joint: Joint(.revolute, axis: t, range: 0...Self.legFold, mimic: .init("legs", ratio: -Self.legFold, offset: Self.legFold)))
        }
        // Ladder rides on the forward leg and slides up its strut when retracted.
        let sdir = simd_normalize(V3(0, 0, foot.r - top.r) + V3(0, foot.y - top.y, 0))
        _ = rig.part("ladderSlide", parent: "leg0", pivot: Self.pt(0, top.r, top.y),
                     joint: Joint(.prismatic, axis: sdir, range: -Self.ladderTravel...0, mimic: .init("ladder", ratio: Self.ladderTravel, offset: -Self.ladderTravel)))
        _ = rig.part("hatchDoor", pivot: V3(-0.43, 2.47, 1.305), joint: Joint(.revolute, axis: Y, range: -110...0, mimic: .init("hatch", ratio: -110)))
        _ = rig.part("thrustFx", pivot: .zero, joint: .fixed, options: 2)
        rig.optionLinks = [RigOptionLink(part: "thrustFx", joint: "thrust", thresholds: [0.5])]

        for l in 0..<2 {
            let bs = l == 0 ? 2 : 1
            let hi = l == 0
            let seg = hi ? 48 : 20
            func base(_ p: (Surface, Xform)) { rig.base[l].add(p.0, p.1) }

            // MARK: Descent stage: eight foil panels around a core, bay plates, bottom plate.
            let R = Self.circumRadius
            let apothem = R * cos(.pi / 8)
            let side = 2 * R * sin(.pi / 8)
            let H = Self.stageHeight
            for i in 0..<8 {
                let ang = (22.5 + 45 * Float(i)) * .pi / 180
                let c = V3(sin(ang) * (apothem - 0.12), H / 2, cos(ang) * (apothem - 0.12))
                base(Self.box(V3(side + 0.16, H, 0.24), c, gold, r: 0.06, bs: bs, yaw: ang))
                // Equipment bay plate and two seam rails on each panel face.
                let out = apothem + 0.012
                base(Self.box(V3(1.15, 0.7, 0.04), V3(sin(ang) * out, 0.85, cos(ang) * out), i % 2 == 0 ? silver : dark, r: 0.012, bs: 1, yaw: ang))
                if hi {
                    for yy: Float in [0.12, H - 0.12] {
                        let o2 = apothem + 0.01
                        base(Self.box(V3(side * 0.92, 0.04, 0.03), V3(sin(ang) * o2, yy, cos(ang) * o2), silver, r: 0.008, bs: 1, yaw: ang))
                    }
                }
            }
            rig.base[l].add(Prim.cylinder(radius: 2.0, height: H - 0.06, bevel: 0.02, segments: hi ? 32 : 16, bevelSegments: 1, material: gold),
                            Xform(translation: V3(0, 0.03, 0)))
            rig.base[l].add(Prim.cylinder(radius: 2.1, height: 0.06, bevel: 0.015, segments: hi ? 32 : 16, bevelSegments: 1, material: silver),
                            Xform(translation: V3(0, -0.02, 0)))
            // Engine bell shell under the floor.
            let shell: [V2] = [V2(0.0001, 0.05), V2(0.3, 0.05), V2(0.3, -0.02), V2(0.24, -0.25), V2(0.27, -0.5), V2(0.42, -0.76), V2(0.62, -0.95), V2(0.585, -0.95)]
            rig.base[l].add(Prim.lathe(shell, segments: seg, seamTile: 0.3, material: bell), Xform(translation: V3(0, -0.02, 0)))

            // MARK: Ascent stage.
            let cc = Self.cabinCentre
            base(Self.box(V3(2.6, 2.1, 2.4), cc, silver, r: 0.18, bs: bs))
            base(Self.box(V3(2.2, 1.5, 1.3), V3(0, 2.4, -1.7), gold, r: 0.12, bs: bs))
            for yy: Float in [1.76, 3.64] { base(Self.box(V3(2.64, 0.12, 2.44), V3(0, yy, 0.05), gold, r: 0.04, bs: 1)) }
            for s: Float in [-1, 1] {
                base(Self.box(V3(0.3, 1.2, 1.6), V3(s * 1.4, 2.7, -0.2), gold, r: 0.08, bs: bs))
            }
            rig.base[l].add(Prim.cylinder(radius: 0.45, height: 0.18, bevel: 0.03, segments: hi ? 32 : 14, bevelSegments: 2, material: silver), Xform(translation: V3(0, 3.75, 0.1)))
            rig.base[l].add(Prim.cylinder(radius: 0.36, height: 0.03, bevel: 0.005, segments: hi ? 32 : 14, bevelSegments: 1, material: dark), Xform(translation: V3(0, 3.93, 0.1)))

            // Hatch frame, recess, porch with rails.
            base(Self.box(V3(0.9, 0.96, 0.1), V3(0, 2.47, 1.215), dark, r: 0.01, bs: 1))
            for s: Float in [-1, 1] {
                base(Self.box(V3(0.06, 1.0, 0.07), V3(s * 0.46, 2.47, 1.285), silver, r: 0.012, bs: 1))
                base(Self.box(V3(1.0, 0.06, 0.07), V3(0, 2.47 + s * 0.49, 1.285), silver, r: 0.012, bs: 1))
            }
            base(Self.box(V3(1.3, 0.07, 0.9), V3(0, 1.96, 1.7), silver, r: 0.02, bs: 1))
            for s: Float in [-1, 1] {
                let px = s * 0.62
                rig.base[l].add(Prim.tube([V3(px, 1.96, 2.1), V3(px, 2.45, 2.1), V3(px, 2.45, 1.3)], radii: [0.02, 0.02, 0.02], sides: hi ? 10 : 6, seamTile: 0.1, material: silver))
            }
            // Windows: dark frame with coated glass, slanted slightly.
            for s: Float in [-1, 1] {
                base(Self.box(V3(0.62, 0.62, 0.04), V3(s * 0.98, 3.2, 1.265), dark, r: 0.04, bs: bs, roll: s * 0.25))
                base(Self.box(V3(0.5, 0.5, 0.03), V3(s * 0.98, 3.2, 1.285), glass, r: 0.03, bs: bs, roll: s * 0.25))
            }

            // S-band dish, rendezvous dish, rod antennas.
            let dq = simd_quatf(angle: 0.7, axis: X)
            let dc = V3(0.95, 4.4, -0.5)
            rig.base[l].add(Prim.tube([V3(0.95, 3.75, -0.5), dc], radii: [0.035, 0.03], sides: hi ? 12 : 6, seamTile: 0.1, material: silver))
            for s in LunarKit.dish(R: 0.34, f: 0.22, thick: 0.012, segments: hi ? 40 : 16, rings: hi ? 6 : 3, front: silver, back: white) {
                rig.base[l].add(s, Xform(translation: dc, rotation: dq))
            }
            rig.base[l].add(Prim.tube([dc, dc + dq.act(Y) * 0.24], radii: [0.012, 0.01], sides: 8, seamTile: 0.1, material: dark))
            let rq = simd_quatf(angle: 1.1, axis: X)
            let rc = V3(-0.55, 3.98, 0.75)
            rig.base[l].add(Prim.tube([V3(-0.55, 3.84, 0.75), rc], radii: [0.03, 0.025], sides: 8, seamTile: 0.1, material: silver))
            for s in LunarKit.dish(R: 0.26, f: 0.16, thick: 0.01, segments: hi ? 32 : 14, rings: hi ? 5 : 3, front: silver, back: white) {
                rig.base[l].add(s, Xform(translation: rc, rotation: rq))
            }
            for (p0, p1) in [(V3(-0.9, 3.15, -2.0), V3(-1.4, 4.6, -2.25)), (V3(0.9, 3.15, -2.0), V3(1.2, 4.3, -2.2))] {
                rig.base[l].add(Prim.tube([p0, p1], radii: [0.012, 0.006], sides: 6, seamTile: 0.1, material: silver))
            }

            // RCS quads on booms at the four cabin corners.
            for sx: Float in [-1, 1] {
                for sz: Float in [-1, 1] {
                    let qc = V3(sx * 1.78, 2.9, sz * 1.0 + 0.05)
                    rig.base[l].add(Prim.tube([V3(sx * 1.3, 2.9, sz * 0.9 + 0.05), qc], radii: [0.06, 0.05], sides: hi ? 10 : 6, seamTile: 0.1, material: white))
                    base(Self.box(V3(0.26, 0.26, 0.26), qc, dark, r: 0.03, bs: 1))
                    if hi {
                        for d in [V3(0, 1, 0), V3(0, -1, 0), V3(sx, 0, 0), V3(0, 0, sz)] {
                            rig.base[l].add(Self.nozzle(1.1, segments: 12, material: silver),
                                            Xform(translation: qc + d * 0.12, rotation: simd_quatf(from: Y, to: d)))
                        }
                    }
                }
            }

            // MARK: Bell lining (option 0 dark, option 1 emissive).
            let inner: [V2] = [V2(0.58, -0.97), V2(0.40, -0.75), V2(0.23, -0.5), V2(0.19, -0.25), V2(0.19, 0.03)]
            for (opt, m) in [(0, lining), (1, liningGlow)] {
                rig.add(Prim.lathe(inner, segments: seg, seamTile: 0.3, material: m).flipped(), Xform(translation: V3(0, -0.02, 0)), to: "thrustFx", option: opt, lods: l...l)
            }

            // MARK: Legs.
            for k in 0..<4 {
                let a = Float(k) * .pi / 2
                let part = "leg\(k)"
                func P(_ r: Float, _ y: Float, _ q: Float = 0) -> V3 { Self.pt(a, r, y, q) }
                let A = P(top.r, top.y), F = P(foot.r, foot.y)
                let M = A + (F - A) * 0.6
                let t = V3(cos(a), 0, -sin(a))
                rig.add(Prim.cylinder(radius: 0.14, height: 0.5, bevel: 0.02, segments: hi ? 20 : 10, bevelSegments: 1, material: silver),
                        Xform(translation: A - t * 0.25, rotation: simd_quatf(from: Y, to: t)), to: part, lods: l...l)
                rig.add(Prim.tube([A, A + (F - A) * 0.5, F], radii: [0.10, 0.09, 0.07], sides: hi ? 20 : 8, seamTile: 0.2, material: gold), to: part, lods: l...l)
                for s: Float in [-1, 1] {
                    let S = P(1.66, 0.5, s * 1.66)
                    rig.add(Prim.tube([S, M], radii: [0.05, 0.05], sides: hi ? 14 : 6, seamTile: 0.2, material: silver), to: part, lods: l...l)
                }
                rig.add(Prim.superellipsoid(V3(0.24, 0.24, 0.24), exponent: 2, subdivisions: hi ? 4 : 2, material: silver), Xform(translation: M), to: part, lods: l...l)
                rig.add(Prim.superellipsoid(V3(0.26, 0.26, 0.26), exponent: 2, subdivisions: hi ? 4 : 2, material: silver), Xform(translation: F), to: part, lods: l...l)
                // Footpad: shallow dish, sole at padY.
                let pad: [V2] = [V2(0.0001, 0), V2(0.40, 0), V2(0.47, 0.03), V2(0.45, 0.07), V2(0.22, 0.13), V2(0.1, 0.2), V2(0.0001, 0.2)]
                rig.add(Prim.lathe(pad, segments: hi ? 40 : 18, seamTile: 0.3, material: gold), Xform(translation: P(foot.r, Self.padY)), to: part, lods: l...l)
            }

            // MARK: Ladder on the forward leg: two rails offset from the strut, rungs between.
            do {
                let a: Float = 0
                let A = Self.pt(a, top.r, top.y), F = Self.pt(a, foot.r, foot.y)
                let u = simd_normalize(F - A)
                let n = simd_normalize(simd_cross(V3(1, 0, 0), u))
                let o = n * 0.2
                let len = simd_length(F - A)
                let s0: Float = -0.5, s1 = len - 0.85
                let rails = ([-0.27, 0.27] as [Float]).map { q -> [V3] in [A + u * s0 + o + V3(q, 0, 0), A + u * s1 + o + V3(q, 0, 0)] }
                for r in rails {
                    rig.add(Prim.tube(r, radii: [0.025, 0.025], sides: hi ? 12 : 6, seamTile: 0.1, material: silver), to: "ladderSlide", lods: l...l)
                }
                let rungs = hi ? 10 : 5
                for j in 0..<rungs {
                    let s = s0 + 0.2 + (s1 - s0 - 0.4) * Float(j) / Float(rungs - 1)
                    let c = A + u * s + o
                    rig.add(Prim.tube([c + V3(-0.27, 0, 0), c + V3(0.27, 0, 0)], radii: [0.02, 0.02], sides: hi ? 8 : 5, seamTile: 0.1, material: silver), to: "ladderSlide", lods: l...l)
                }
            }

            // MARK: Hatch door.
            rig.add(Prim.roundedBox(V3(0.86, 0.92, 0.06), radius: 0.02, bevelSegments: bs, material: white), Xform(translation: V3(0, 2.47, 1.305)), to: "hatchDoor", lods: l...l)
            rig.add(Prim.roundedBox(V3(0.1, 0.06, 0.03), radius: 0.01, bevelSegments: 1, material: dark), Xform(translation: V3(0.28, 2.47, 1.35)), to: "hatchDoor", lods: l...l)
        }

        // Engine light under the bell, on while the lining is emissive.
        rig.lights.append(RigLight(name: "engine", part: "thrustFx", option: 1, position: V3(0, -1.2, 0), direction: V3(0, -1, 0),
                                   color: V3(1, 0.95, 0.85), intensity: 1500, attenuationRadius: 30))

        rig.states = [
            RigState("stowed"),
            RigState("landed", ["legs": 1]),
            RigState("descent-burn", ["legs": 1, "thrust": 1], options: ["thrustFx": 1]),
            RigState("hatch-open", ["legs": 1, "hatch": 1]),
            RigState("ladder-out", ["legs": 1, "hatch": 1, "ladder": 1]),
        ]
        rig.defaultState = "landed"
        return rig
    }
}
