import simd
import Foundation

/// Sky manta, 22 m wingspan: a flat lofted body built spanwise (64 stations, 64 radial points) with a swept planform, a thick
/// central disc that thins to flexible wing tips, dark slate top over a white belly, two cephalic fins either side of a wide
/// mouth, eyes on the head sides, five gill slits per side on the underside, a long whip tail and a bioluminescent spot pattern
/// on the back (cyan emissive dots on the mesh). Origin at the body centre, head +Z, up +Y.
///
/// Joints: `wave` -1...1 (wing beat: inner wing 16 degrees, outer wing 26 degrees at full value, positive lifts both tips),
/// `bank` -1...1 (roll 30 degrees through wing asymmetry: positive drops the right wing 15 degrees and lifts the left wing
/// 15 degrees), `fins` 0...1 (cephalic fins unroll 70 degrees from curled to forward and down), `glow` 0...1 (spots switch to
/// emissive cyan at 0.05, with a cyan point light). All four are empty drivers; child parts mimic them. 2 LODs.
public struct SkyManta: RealArticulated {
    public static let id = "sky-manta"
    public static let summary = "22 m sky manta ray: lofted flat body with flexing wing tips, cephalic fins, gill slits, dark top and white belly, bioluminescent cyan spots, whip tail, joints wave, bank, fins, glow."
    public static let tags = ["prop", "creature", "fish", "fantasy", "flying", "outdoor", "articulated", "glowing"]
    public static let budget = 28_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 35, distance: 1.1, ground: false, studio: true)

    /// Dorsal skin, dark slate (scaleless fish skin atlas, tinted).
    public var top: MaterialKey = "fish.manta-top"
    /// Ventral skin, white.
    public var belly: MaterialKey = "fish.manta-belly"
    /// Cephalic fins and tail, dark.
    public var fin: MaterialKey = "fish.catfish-fin:1A222C"
    /// Mouth and gill slits.
    public var mouth: MaterialKey = "fish.mouth"
    /// Eyes.
    public var eye: MaterialKey = "fish.eye-dark"
    /// Spots when lit (Roadster.swift emissive cyan).
    public var lit: MaterialKey = "emissive.thruster-cyan"
    /// Spots when dark.
    public var unlit: MaterialKey = "glass.tinted:1E4650"
    public init() {}

    // MARK: Planform (x span, z chord, y thickness)

    static let span: Float = 11
    static func smooth(_ x: Float) -> Float { let t = min(1, max(0, x)); return t * t * (3 - 2 * t) }
    /// Chord length at span x.
    static func chord(_ x: Float) -> Float {
        let s = min(1, abs(x) / span)
        return 6.4 * pow(max(0, 1 - pow(s, 1.7)), 0.65) + 0.18
    }
    /// Chord midpoint z: the wing is swept back toward the tips.
    static func midZ(_ x: Float) -> Float { let s = min(1, abs(x) / span); return 0.2 - 3.4 * s * s }
    /// Half thickness: a thick disc over the body, thin wings.
    static func thick(_ x: Float) -> Float {
        let s = min(1, abs(x) / span)
        return 0.05 + 0.85 * exp(-pow(s / 0.2, 2)) + 0.22 * (1 - s)
    }
    /// Tip curls up slightly at rest.
    static func lift(_ x: Float) -> Float { let s = min(1, abs(x) / span); return 0.6 * pow(s, 3) }
    /// Section point at span x and angle a (0 top, pi/2 toward +Z leading edge).
    static func section(_ x: Float, _ a: Float) -> V3 {
        V3(x, lift(x) + thick(x) * cos(a), midZ(x) + 0.5 * chord(x) * sin(a))
    }
    static func outward(_ x: Float, _ a: Float) -> V3 {
        simd_normalize(V3(0, cos(a) / max(thick(x), 0.02), sin(a) / max(0.5 * chord(x), 0.05)))
    }
    /// Top-surface point at (x, z) for spots: the angle where the section passes z.
    static func topPoint(_ x: Float, _ z: Float) -> (p: V3, n: V3)? {
        let h = 0.5 * chord(x)
        let s = (z - midZ(x)) / h
        guard abs(s) < 0.82 else { return nil }
        let a = asin(s)
        return (section(x, a), outward(x, a))
    }

    /// Spanwise rings from xA to xB. Rings run toward +X, which gives outward winding for (cos a up, sin a forward).
    static func rings(_ xA: Float, _ xB: Float, count n: Int, radial: Int) -> [[V3]] {
        (0..<n).map { i -> [V3] in
            let u = Float(i) / Float(n - 1)
            let x = xA + (xB - xA) * u
            return (0..<radial).map { j in section(x, 2 * .pi * Float(j) / Float(radial)) }
        }
    }

    static func facing(_ n: V3) -> simd_quatf {
        let z = simd_normalize(n)
        var x = simd_cross(V3(0, 1, 0), z)
        if simd_length(x) < 1e-3 { x = V3(1, 0, 0) }
        x = simd_normalize(x)
        let y = simd_cross(z, x)
        return simd_quatf(simd_float3x3(columns: (x, y, z)))
    }

    static func hash(_ i: Int, _ salt: UInt64) -> Float {
        var z = UInt64(truncatingIfNeeded: i) &* 0x9E37_79B9_7F4A_7C15 ^ salt
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return Float((z ^ (z >> 31)) >> 40) / Float(1 << 24)
    }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [180])
        let X = V3(1, 0, 0), Z = V3(0, 0, 1)

        for (name, range, dur): (String, ClosedRange<Float>, Float) in
            [("wave", -1...1, 1.4), ("bank", -1...1, 1.0), ("fins", 0...1, 0.8), ("glow", 0...1, 1.5)] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Z, range, duration: dur))
        }
        _ = rig.part("body", pivot: .zero, joint: .fixed)

        // Wing chain per side: bank hinge, inner wing, outer wing, all about +Z at the segment roots.
        // Positive rotation about +Z lifts +X; the left side uses negative ratios to mirror.
        let xIn: Float = 2.2, xOut: Float = 6.2
        for (side, sg) in [("R", Float(1)), ("L", Float(-1))] {
            _ = rig.part("bank\(side)", parent: "body", pivot: V3(sg * xIn, 0, Self.midZ(xIn)),
                         joint: Joint(.revolute, axis: Z, range: -15...15, mimic: .init("bank", ratio: -15)))
            _ = rig.part("wing\(side)1", parent: "bank\(side)", pivot: V3(sg * xIn, 0, Self.midZ(xIn)),
                         joint: Joint(.revolute, axis: Z, range: -16...16, mimic: .init("wave", ratio: sg * 16)))
            _ = rig.part("wing\(side)2", parent: "wing\(side)1", pivot: V3(sg * xOut, Self.lift(xOut), Self.midZ(xOut)),
                         joint: Joint(.revolute, axis: Z, range: -10...10, mimic: .init("wave", ratio: sg * 10)))
        }
        // Cephalic fins unroll about X at their roots.
        _ = rig.part("finR", parent: "body", pivot: V3(1.05, 0.05, 3.15), joint: Joint(.revolute, axis: X, range: 0...70, mimic: .init("fins", ratio: 70)))
        _ = rig.part("finL", parent: "body", pivot: V3(-1.05, 0.05, 3.15), joint: Joint(.revolute, axis: X, range: 0...70, mimic: .init("fins", ratio: 70)))
        // Spot lamps follow their wing segment.
        let lampParts = ["lampsC": "body", "lampsR1": "wingR1", "lampsR2": "wingR2", "lampsL1": "wingL1", "lampsL2": "wingL2"]
        for (lp, parent) in lampParts.sorted(by: { $0.key < $1.key }) {
            _ = rig.part(lp, parent: parent, pivot: .zero, joint: .fixed, options: 2)
        }
        rig.optionLinks = lampParts.keys.sorted().map { RigOptionLink(part: $0, joint: "glow", thresholds: [0.05]) }

        func partFor(_ x: Float) -> (body: String, lamps: String) {
            let a = abs(x), s = x > 0 ? "R" : "L"
            if a < xIn { return ("body", "lampsC") }
            if a < xOut { return ("wing\(s)1", "lamps\(s)1") }
            return ("wing\(s)2", "lamps\(s)2")
        }

        for l in 0..<2 {
            let hi = l == 0
            func put(_ s: Surface, _ part: String, option: Int = 0, _ x: Xform = .identity) {
                rig.add(s, x, to: part, option: option, lods: l...l)
            }
            let radial = hi ? 64 : 24
            // Top half (a in -pi/2...pi/2) and belly half as separate lofts so each takes its own skin.
            func halfRings(_ xA: Float, _ xB: Float, n: Int, top: Bool) -> [[V3]] {
                let h = radial / 2
                return (0..<n).map { i -> [V3] in
                    let u = Float(i) / Float(n - 1)
                    let x = xA + (xB - xA) * u
                    return (0...h).map { j in
                        let a = (top ? -Float.pi / 2 : Float.pi / 2) + Float.pi * Float(j) / Float(h)
                        return Self.section(x, a)
                    }
                }
            }
            // 64 stations across the span: 12 + 12 + 16 + 12 + 12 (shared boundary rings).
            let segs: [(Float, Float, Int, String)] = [
                (-Self.span, -xOut, hi ? 12 : 5, "wingL2"), (-xOut, -xIn, hi ? 12 : 5, "wingL1"), (-xIn, xIn, hi ? 16 : 6, "body"),
                (xIn, xOut, hi ? 12 : 5, "wingR1"), (xOut, Self.span, hi ? 12 : 5, "wingR2"),
            ]
            for (a, b, n, part) in segs {
                put(Prim.loft(halfRings(a, b, n: n, top: true), capStart: a == -Self.span, capEnd: b == Self.span, material: top), part)
                put(Prim.loft(halfRings(a, b, n: n, top: false), capStart: a == -Self.span, capEnd: b == Self.span, material: belly), part)
            }

            // Head: mouth between the cephalic fins, eyes on the head sides.
            put(Prim.superellipsoid(V3(1.7, 0.42, 0.5), exponent: 2.4, subdivisions: hi ? 5 : 3, material: mouth), "body", Xform(translation: V3(0, -0.12, 3.28)))
            for side: Float in [-1, 1] {
                let p = V3(side * 1.25, 0.32, 2.75)
                let n = simd_normalize(V3(side, 0.35, 0.3))
                put(Prim.superellipsoid(V3(0.26, 0.26, 0.2), exponent: 2, subdivisions: hi ? 4 : 2, material: eye), "body", Xform(translation: p, rotation: Self.facing(n)))

                // Cephalic fin: flattened tube curled up and back at rest (fins 0), straight forward when unrolled.
                var path: [V3] = [], radii: [Float] = []
                let k = hi ? 14 : 6
                for i in 0..<k {
                    let t = Float(i) / Float(k - 1)
                    let curl = 1.9 * t
                    path.append(V3(side * (1.05 + 0.05 * t), 0.05 + 0.55 * sin(curl), 3.15 + 0.55 * (1 - cos(curl)) * 0.4 + 0.35 * sin(curl)))
                    radii.append(0.2 * (1 - 0.55 * t) + 0.02)
                }
                // Flatten the tube across X about the fin root (0.45 thick).
                let fs = Prim.tube(path, radii: radii, sides: hi ? 48 : 12, seamTile: 0.4, material: fin, capEnd: true)
                put(fs, side > 0 ? "finR" : "finL", Xform(translation: V3(side * 1.05 * 0.55, 0, 0), rotation: simd_quatf(ix: 0, iy: 0, iz: 0, r: 1), scale: V3(0.45, 1, 1)))

                // Gill slits on the underside, five per side.
                for g in 0..<5 {
                    let x = side * (1.0 + 0.24 * Float(g))
                    let z: Float = 1.55 - 0.12 * Float(g)
                    let y = -Self.thick(x) * 0.97
                    put(Prim.superellipsoid(V3(0.06, 0.04, 0.62), exponent: 3, subdivisions: hi ? 2 : 1, material: mouth), "body",
                        Xform(translation: V3(x, y, z), rotation: simd_quatf(angle: side * 0.25, axis: V3(0, 1, 0))))
                }
            }

            // Whip tail from the trailing edge.
            var tail: [V3] = [], tr: [Float] = []
            let tn = hi ? 24 : 8
            for i in 0..<tn {
                let t = Float(i) / Float(tn - 1)
                tail.append(V3(0, 0.05 + 0.25 * sin(t * 2.4) * t, -2.6 - 10.5 * t))
                tr.append(0.16 * pow(1 - t, 1.4) + 0.012)
            }
            put(Prim.tube(tail, radii: tr, sides: hi ? 32 : 8, seamTile: 0.3, material: fin, capEnd: true), "body")
            put(Prim.superellipsoid(V3(0.5, 0.3, 0.7), exponent: 2.2, subdivisions: hi ? 3 : 2, material: top), "body", Xform(translation: V3(0, 0.2, -2.55)))

            // Bioluminescent spots: two rows along each wing's leading third, a scatter over the disc.
            if hi {
                var spots: [(x: Float, z: Float, r: Float)] = []
                for i in 0..<34 {
                    let s = 0.16 + 0.8 * Float(i) / 33
                    for side: Float in [-1, 1] {
                        let x = side * s * Self.span
                        let row: Float = i % 2 == 0 ? 0.22 : -0.05
                        spots.append((x, Self.midZ(x) + row * Self.chord(x), 0.09 + 0.08 * (1 - s)))
                    }
                }
                for i in 0..<18 {
                    let x = (Self.hash(i, 0xA1 ^ seed) * 2 - 1) * 1.9
                    let z = -1.4 + 3.2 * Self.hash(i, 0xB2 ^ seed)
                    spots.append((x, z, 0.12 + 0.06 * Self.hash(i, 0xC3)))
                }
                for sp in spots {
                    guard let tp = Self.topPoint(sp.x, sp.z) else { continue }
                    let p = tp.p, n = tp.n
                    let lp = partFor(sp.x).lamps
                    for (opt, mat) in [(0, unlit), (1, lit)] {
                        put(Prim.superellipsoid(V3(2 * sp.r, 2 * sp.r, 0.05), exponent: 2, subdivisions: 2, material: mat), lp, option: opt,
                            Xform(translation: p + n * 0.012, rotation: Self.facing(n)))
                    }
                }
            }
        }

        rig.lights = [
            RigLight(name: "spot-glow", part: "lampsC", option: 1, position: V3(0, 1.2, 0), direction: V3(0, 1, 0), color: V3(0.2, 0.85, 1), intensity: 4000, attenuationRadius: 45),
        ]

        rig.states = [
            RigState("rest"),
            RigState("upstroke", ["wave": 1]),
            RigState("downstroke", ["wave": -1]),
            RigState("bank-right", ["bank": 1, "wave": 0.3]),
            RigState("fins-out", ["fins": 1]),
            RigState("glide", ["wave": 0.2, "fins": 1]),
            RigState("glow", ["fins": 1, "glow": 1], options: ["lampsC": 1, "lampsR1": 1, "lampsR2": 1, "lampsL1": 1, "lampsL2": 1]),
        ]
        return rig
    }
}
