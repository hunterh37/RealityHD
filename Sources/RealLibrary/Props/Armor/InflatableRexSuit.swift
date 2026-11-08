import simd
import Foundation

/// Inflatable tyrannosaur costume kit, life size for a 1.75 m wearer: a big puffed head with a hinged jaw, teeth, tongue and bulging
/// eyes, a seamed ripstop torso with legs and feet, a stubby tail with dorsal spikes, two tiny forearms with claws, and a back fan
/// housing. Original shapes only. Origin at the neck base, face toward +Z, up +Y, wearer's left = +X.
///
/// Kit parts (pivots in asset space): `head` (0, 0, 0), `body` (0, -0.2, 0), `tailRoot` (0, -0.85, -0.25),
/// `armL` / `armR` (+-0.3, -0.35, 0.25) with the forearm running forward and down.
///
/// Joints (set with `setJoints`): `inflate` (0...1) puffs the suit out, `jaw` (0...1) opens the mouth, `arms` (0...1) is an empty
/// driver for the tiny arm flail, `tail` (-1...1) is an empty driver for the tail sway. Followers `jawOpen` and `puffed` switch
/// between option 0 and option 1 when `jaw` or `inflate` passes 0.05. 2 LODs.
public struct InflatableRexSuit: RealArticulated {
    public static let id = "inflatable-rex-suit"
    public static let summary = "Inflatable T-rex costume kit: puffed head with hinged jaw and teeth, seamed ripstop torso and legs, stubby tail, tiny clawed arms and a back fan."
    public static let tags = ["prop", "fabric", "articulated", "creature"]
    public static let budget = 20_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 8, distance: 2.4)

    /// Ripstop shell (tint olive green at the lens).
    public var shell: MaterialKey = "fabric.nylon"
    /// Lighter belly panel and seam piping.
    public var belly: MaterialKey = "fabric.canvas"
    /// Teeth and eye whites.
    public var tooth: MaterialKey = "plastic.white"
    /// Mouth interior and tongue.
    public var mouth: MaterialKey = "rubber.insulating-red"
    /// Irises.
    public var iris: MaterialKey = "plastic.yellow"
    /// Pupils, nostrils, fan housing.
    public var dark: MaterialKey = "plastic.black"
    /// Claws.
    public var claw: MaterialKey = "plastic.orange"
    /// Fan grille.
    public var steel: MaterialKey = "metal.steel"
    public init() {}

    static let jawPivot = V3(0, 0.02, 0.25)

    func rad(_ d: Float) -> Float { d * .pi / 180 }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [4])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0)

        _ = rig.part("inflate", pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.6))
        _ = rig.part("jaw", pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.3))
        _ = rig.part("arms", pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.3))
        _ = rig.part("tail", pivot: .zero, joint: .hinge(axis: Y, -1...1, duration: 0.5))
        let pivots: [(String, V3)] = [
            ("head", V3(0, 0, 0)), ("body", V3(0, -0.2, 0)), ("tailRoot", V3(0, -0.85, -0.25)),
            ("armL", V3(0.3, -0.35, 0.25)), ("armR", V3(-0.3, -0.35, 0.25)),
        ]
        for (name, p) in pivots { _ = rig.part(name, pivot: p, joint: .fixed) }
        _ = rig.part("jawOpen", parent: "head", pivot: Self.jawPivot, joint: .fixed, options: 2)
        _ = rig.part("puffed", parent: "body", pivot: V3(0, -0.5, 0), joint: .fixed, options: 2)
        rig.optionLinks = [
            RigOptionLink(part: "jawOpen", joint: "jaw", thresholds: [0.05]),
            RigOptionLink(part: "puffed", joint: "inflate", thresholds: [0.05]),
        ]

        for l in 0..<2 {
            let hi = l == 0
            let sides = hi ? 48 : 16
            func put(_ s: Surface, _ part: String, option: Int = 0, _ x: Xform = .identity) {
                rig.add(s, x, to: part, option: option, lods: l...l)
            }
            func ring(_ part: String, _ at: V3, major: Float, minor: Float, _ mat: MaterialKey, scale: V3 = V3(1, 1, 1)) {
                put(Prim.torus(major: major, minor: minor, segments: hi ? 48 : 16, sides: hi ? 12 : 6, material: mat), part,
                    Xform(translation: at, scale: scale))
            }
            /// Cone (tooth, claw, spike) with its base at the origin and tip along +Y.
            func cone(_ part: String, option: Int = 0, at: V3, tip: V3 = V3(0, 1, 0), length: Float, radius: Float, _ mat: MaterialKey) {
                let s = Prim.lathe([V2(radius, 0), V2(radius * 0.8, length * 0.35), V2(radius * 0.4, length * 0.75), V2(0.001, length)],
                                   segments: hi ? 16 : 6, seamTile: 0.02, material: mat)
                let d = simd_normalize(tip)
                let q = simd_quatf(from: Y, to: d)
                put(s, part, option: option, Xform(translation: at, rotation: q))
            }
            /// Rotates a point about the jaw hinge by `a` radians (open jaw).
            func hinge(_ p: V3, _ a: Float) -> V3 {
                let r = p - Self.jawPivot
                return Self.jawPivot + V3(r.x, r.y * cos(a) - r.z * sin(a), r.y * sin(a) + r.z * cos(a))
            }

            // MARK: Head: neck collar, puffed skull, snout, brow spikes, eyes, nostrils, upper teeth
            do {
                ring("head", V3(0, 0.0, 0), major: 0.15, minor: 0.03, shell)
                put(Prim.superellipsoid(V3(0.52, 0.44, 0.56), exponent: 2.3, subdivisions: hi ? 6 : 3, material: shell), "head", Xform(translation: V3(0, 0.22, 0.08)))
                put(Prim.superellipsoid(V3(0.4, 0.26, 0.6), exponent: 2.4, subdivisions: hi ? 6 : 3, material: shell,
                                        bulge: { d in 1 + 0.05 * sin(d.z * 9) }), "head", Xform(translation: V3(0, 0.14, 0.52)))
                // Seam piping around the skull and snout.
                for (z, r) in [(Float(0.0), Float(0.25)), (0.26, 0.24), (0.62, 0.18)] {
                    ring("head", V3(0, 0.15 + (z < 0.5 ? 0.07 : 0.0), z), major: r, minor: 0.008, belly, scale: V3(1, 1, 1))
                }
                // Upper lip band over the teeth.
                put(Prim.superellipsoid(V3(0.42, 0.05, 0.62), exponent: 3, subdivisions: hi ? 5 : 3, material: belly), "head", Xform(translation: V3(0, 0.025, 0.5)))
                for sx in [Float(-1), 1] {
                    // Eye: white, iris, slit pupil, puffed lid ring.
                    let e = V3(sx * 0.19, 0.42, 0.28)
                    put(Prim.superellipsoid(V3(0.15, 0.15, 0.13), exponent: 2, subdivisions: hi ? 5 : 3, material: tooth), "head", Xform(translation: e))
                    put(Prim.superellipsoid(V3(0.085, 0.085, 0.04), exponent: 2, subdivisions: hi ? 5 : 3, material: iris), "head", Xform(translation: e + V3(sx * 0.015, 0, 0.055)))
                    put(Prim.superellipsoid(V3(0.016, 0.07, 0.03), exponent: 2, subdivisions: hi ? 4 : 2, material: dark), "head", Xform(translation: e + V3(sx * 0.015, 0, 0.085)))
                    put(Prim.torus(major: 0.078, minor: 0.016, segments: hi ? 48 : 16, sides: hi ? 12 : 6, material: shell), "head",
                        Xform(translation: e + V3(0, 0.0, 0.01), rotation: simd_quatf(angle: .pi / 2, axis: X), scale: V3(1, 1, 1)))
                    // Nostril and brow spikes.
                    put(Prim.superellipsoid(V3(0.04, 0.03, 0.03), exponent: 2, subdivisions: hi ? 4 : 2, material: dark), "head", Xform(translation: V3(sx * 0.08, 0.2, 0.82)))
                    for k in 0..<3 {
                        let z = 0.0 + 0.1 * Float(k)
                        cone("head", at: V3(sx * 0.17, 0.4 - 0.01 * Float(k), -0.12 + z), tip: V3(sx * 0.4, 1, -0.2), length: 0.1 - 0.015 * Float(k), radius: 0.03, shell)
                    }
                }
                // Upper teeth: two curved rows following the snout, tips down.
                let n = hi ? 9 : 5
                for k in 0..<n {
                    let u = Float(k) / Float(n - 1)
                    let z = 0.82 - 0.5 * u
                    let hx = 0.14 + 0.07 * u
                    for sx in [Float(-1), 1] {
                        cone("head", at: V3(sx * hx, 0.0, z), tip: V3(0, -1, 0.1), length: 0.07 + 0.02 * sin(u * .pi), radius: 0.016, tooth)
                    }
                }
                cone("head", at: V3(0, 0.0, 0.86), tip: V3(0, -1, 0.15), length: 0.06, radius: 0.016, tooth)
            }

            // MARK: Jaw: closed (option 0) and open with tongue and interior (option 1)
            do {
                for opt in 0..<2 {
                    let a: Float = opt == 0 ? 0 : 0.62
                    func jp(_ p: V3) -> V3 { hinge(p, a) }
                    let rot = simd_quatf(angle: a, axis: X)
                    put(Prim.superellipsoid(V3(0.36, 0.1, 0.58), exponent: 2.6, subdivisions: hi ? 5 : 3, material: shell), "jawOpen", option: opt,
                        Xform(translation: jp(V3(0, -0.04, 0.5)), rotation: rot))
                    put(Prim.superellipsoid(V3(0.3, 0.05, 0.5), exponent: 3, subdivisions: hi ? 5 : 3, material: belly), "jawOpen", option: opt,
                        Xform(translation: jp(V3(0, -0.075, 0.5)), rotation: rot))
                    let n = hi ? 7 : 4
                    for k in 0..<n {
                        let u = Float(k) / Float(n - 1)
                        for sx in [Float(-1), 1] {
                            let p = jp(V3(sx * (0.11 + 0.05 * u), 0.0, 0.76 - 0.42 * u))
                            let tip = rot.act(V3(0, 1, -0.1))
                            cone("jawOpen", option: opt, at: p, tip: tip, length: 0.06, radius: 0.014, tooth)
                        }
                    }
                }
                // Interior and tongue show when the mouth is open.
                put(Prim.superellipsoid(V3(0.3, 0.16, 0.5), exponent: 2.2, subdivisions: hi ? 5 : 3, material: mouth), "jawOpen", option: 1, Xform(translation: V3(0, 0.0, 0.45)))
                put(Prim.tube([V3(0, -0.05, 0.3), V3(0, -0.12, 0.55), V3(0, -0.2, 0.74)], radii: [0.09, 0.07, 0.04], sides: sides, seamTile: 0.05, material: mouth, capEnd: true), "jawOpen", option: 1)
            }

            // MARK: Body: seamed torso, belly panel, piping, legs, feet, fan housing
            do {
                put(Prim.superellipsoid(V3(0.78, 1.0, 0.62), exponent: 2.2, subdivisions: hi ? 6 : 3, material: shell,
                                        bulge: { d in 1 + 0.04 * sin(d.y * 14) }), "body", Xform(translation: V3(0, -0.5, -0.02)))
                put(Prim.superellipsoid(V3(0.5, 0.72, 0.1), exponent: 2.4, subdivisions: hi ? 5 : 3, material: belly), "body", Xform(translation: V3(0, -0.5, 0.29)))
                for (k, y) in [Float(-0.28), -0.52, -0.76].enumerated() {
                    ring("body", V3(0, y, -0.02), major: 0.34 - 0.012 * Float(abs(k - 1)), minor: 0.009, belly, scale: V3(1.12, 1, 0.9))
                }
                for sx in [Float(-1), 1] {
                    put(Prim.tube([V3(sx * 0.15, -0.88, 0), V3(sx * 0.16, -1.1, 0.02), V3(sx * 0.17, -1.4, 0.03)], radii: [0.17, 0.14, 0.12], sides: sides, seamTile: 0.06, material: shell, capEnd: true), "body")
                    put(Prim.superellipsoid(V3(0.26, 0.15, 0.46), exponent: 2.6, subdivisions: hi ? 5 : 3, material: shell), "body", Xform(translation: V3(sx * 0.17, -1.44, 0.14)))
                    for k in 0..<3 {
                        cone("body", at: V3(sx * (0.17 + (Float(k) - 1) * 0.07), -1.45, 0.34), tip: V3(0, 0.2, 1), length: 0.1, radius: 0.025, claw)
                    }
                    ring("body", V3(sx * 0.165, -1.28, 0.03), major: 0.125, minor: 0.008, belly)
                }
                // Back fan housing with grille.
                put(Prim.lathe([V2(0.11, 0), V2(0.12, 0.02), V2(0.12, 0.06), V2(0.08, 0.08), V2(0.001, 0.085)], segments: sides, seamTile: 0.05, material: dark), "body",
                    Xform(translation: V3(0, -0.4, -0.3), rotation: simd_quatf(angle: -.pi / 2, axis: X)))
                put(Prim.torus(major: 0.1, minor: 0.006, segments: hi ? 48 : 16, sides: hi ? 10 : 5, material: steel), "body",
                    Xform(translation: V3(0, -0.4, -0.375), rotation: simd_quatf(angle: .pi / 2, axis: X)))
                // Puffed state: an outer, tighter shell.
                put(Prim.superellipsoid(V3(0.9, 1.1, 0.72), exponent: 2.1, subdivisions: hi ? 6 : 3, material: shell,
                                        bulge: { d in 1 + 0.05 * sin(d.y * 16) * sin(d.x * 5) }), "puffed", option: 1, Xform(translation: V3(0, -0.5, -0.02)))
            }

            // MARK: Tail: tapered tube with ridge rings and dorsal spikes
            do {
                let path = [V3(0, -0.85, -0.25), V3(0, -0.86, -0.7), V3(0, -0.8, -1.15), V3(0, -0.68, -1.6), V3(0, -0.6, -1.9)]
                put(Prim.tube(path, radii: [0.26, 0.2, 0.14, 0.08, 0.025], sides: sides, seamTile: 0.08, material: shell, capEnd: true), "tailRoot")
                for k in 0..<4 {
                    let p = path[k]
                    let r: Float = [0.26, 0.2, 0.14, 0.08][k]
                    put(Prim.torus(major: r, minor: 0.008, segments: hi ? 48 : 16, sides: hi ? 8 : 4, material: belly), "tailRoot",
                        Xform(translation: p + V3(0, 0.0, 0.12), rotation: simd_quatf(angle: .pi / 2, axis: X)))
                }
                for k in 0..<5 {
                    let p = path[min(k, 4)]
                    let r: Float = [0.26, 0.2, 0.14, 0.08, 0.025][min(k, 4)]
                    cone("tailRoot", at: p + V3(0, r * 0.92, 0.0), tip: V3(0, 1, -0.35), length: 0.16 - 0.025 * Float(k), radius: 0.045 - 0.007 * Float(k), shell)
                }
            }

            // MARK: Tiny arms: sleeve, forearm, two claws
            for (sx, name) in [(Float(1), "armL"), (Float(-1), "armR")] {
                let p0 = V3(sx * 0.3, -0.35, 0.25)
                put(Prim.tube([p0, p0 + V3(sx * 0.04, -0.12, 0.14), p0 + V3(sx * 0.04, -0.2, 0.26)], radii: [0.075, 0.062, 0.05], sides: sides, seamTile: 0.05, material: shell, capEnd: true), name)
                ring(name, p0 + V3(sx * 0.03, -0.09, 0.1), major: 0.066, minor: 0.007, belly, scale: V3(1, 1, 1))
                for c in 0..<2 {
                    let off = (Float(c) - 0.5) * 0.04
                    cone(name, at: p0 + V3(sx * 0.04 + off, -0.2, 0.26), tip: V3(sx * 0.1 * (Float(c) - 0.5) * 2, -0.5, 1), length: 0.1, radius: 0.016, claw)
                }
            }
        }

        rig.states = [
            RigState("rest", [:]),
            RigState("inflated", ["inflate": 1], options: ["puffed": 1]),
            RigState("roar", ["inflate": 1, "jaw": 1], options: ["puffed": 1, "jawOpen": 1]),
            RigState("flail", ["inflate": 1, "arms": 1], options: ["puffed": 1]),
            RigState("whip", ["inflate": 1, "tail": 1], options: ["puffed": 1]),
        ]
        return rig
    }
}
