import simd
import Foundation

/// Storm roc, a giant eagle with a 30 m wingspan: lofted torso (40 stations, 64 radial points) in dark brown plumage, a white
/// lofted head and neck ruff, a hooked yellow beak with a hinged lower mandible and cere, glass eyes over amber irises under a
/// white brow, and two wings built as three bone segments each (arm, forearm, hand) with a leading-edge tube, a covert panel and
/// layered double-sided feather cards: 10 primaries splayed at the tip, 14 secondaries, 8 tertials, a greater and a lesser covert
/// row in gold-brown. White tail fan of 12 feathers. Feathered thighs, scaled yellow tarsi, four toes per foot with black keratin
/// talons. Legs rest tucked back under the tail. Origin at the body centre, beak +Z, up +Y.
///
/// Joints: `flap` -1...1 (positive raises the wings: shoulder 32 degrees, wrist another 20 degrees so the tip leads the bend),
/// `fold` 0...1 (shoulder sweeps back 55 degrees, elbow 25 more, wings tuck along the body), `talons` 0...1 (legs swing down 80
/// degrees from the tucked rest, front toes open 40 degrees, hind toe 40 degrees), `beak` 0...1 (lower mandible opens 28
/// degrees), `head` -1...1 (head yaw 40 degrees, positive toward +X). All five joints are empty drivers; child parts mimic them. 2 LODs.
public struct StormRoc: RealArticulated {
    public static let id = "storm-roc"
    public static let summary = "30 m wingspan storm roc: lofted brown plumage body, white head, hooked yellow beak, layered primary, secondary and covert feather cards, white tail fan, yellow tarsi with black talons, joints flap, fold, talons, beak, head."
    public static let tags = ["prop", "creature", "fantasy", "flying", "outdoor", "articulated"]
    public static let budget = 28_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 28, distance: 1.1, ground: false, studio: true)

    /// Torso plumage, dark brown.
    public var body: MaterialKey = "dino.feather-coat:3E2A1A"
    /// Head, neck ruff and brow, white.
    public var head: MaterialKey = "dino.feather-coat:F2EEE6"
    /// Covert panels and leading-edge tubes, gold-brown.
    public var covert: MaterialKey = "dino.feather-coat:8A6232"
    /// Primary and secondary flight feathers (cutout cards), dark brown.
    public var flight: MaterialKey = "fauna.feather:2E2016"
    /// Covert feather rows, gold-brown.
    public var gold: MaterialKey = "fauna.feather:A47A3C"
    /// Tail fan and hackles, white.
    public var tail: MaterialKey = "fauna.feather:F0ECE4"
    /// Beak and cere, glossy yellow keratin.
    public var beakKey: MaterialKey = "plastic.gloss:E2A81E"
    /// Talons, black keratin.
    public var claw: MaterialKey = "plastic.gloss:16120E"
    /// Tarsi and toes, scaled yellow skin.
    public var foot: MaterialKey = "dino.scale-skin:D6A42A"
    /// Eye dome glass.
    public var glass: MaterialKey = "glass.clear"
    /// Iris.
    public var iris: MaterialKey = "glass.tinted:C8860E"
    /// Pupil.
    public var pupil: MaterialKey = "metal.enamel:0A0A0A"
    public init() {}

    // MARK: Body profile

    static func smooth(_ x: Float) -> Float { let t = min(1, max(0, x)); return t * t * (3 - 2 * t) }
    static func mix(_ a: Float, _ b: Float, _ t: Float) -> Float { a + (b - a) * t }

    static let tailEnd: Float = -3.4
    static let neckZ: Float = 3.3
    static let crownZ: Float = 6.0

    /// Torso half width at z: chest peak near the middle, 0.82 m at both ends.
    static func torsoR(_ z: Float) -> Float {
        let u = (z - tailEnd) / (neckZ - tailEnd)
        return 1.35 * (0.42 + 0.58 * pow(max(0, sin(.pi * (0.08 + 0.84 * u))), 0.8))
    }
    /// Head radius at z: neck to skull bulge, closed at the crown.
    static func headR(_ z: Float) -> Float {
        let base = 0.82 + 0.16 * sin(.pi * min(1, max(0, (z - neckZ) / 1.9)))
        if z <= 5.2 { return base }
        let k = (z - 5.2) / (crownZ - 5.2)
        return max(0.04, base * sqrt(max(0, 1 - k * k)))
    }
    /// Spine height: chest hangs low, neck and head rise.
    static func spineY(_ z: Float) -> Float {
        z < neckZ ? -0.12 * sin(.pi * (z - tailEnd) / (neckZ - tailEnd)) : 0.5 * smooth((z - neckZ) / 1.6)
    }

    /// Elliptic ring at z, angle 0 up, pi/2 toward +X. Rings must run +Z to -Z for outward winding.
    static func ring(_ c: V3, hw: Float, hh: Float, radial: Int) -> [V3] {
        (0..<radial).map { j in
            let a = 2 * Float.pi * Float(j) / Float(radial)
            return c + V3(hw * sin(a), hh * cos(a), 0)
        }
    }

    // MARK: Feathers

    /// Double-sided feather card from `root` along `dir`, 0...1 UV (u across, v along the shaft), cambered and curled.
    static func feather(_ root: V3, _ dir: V3, up: V3 = V3(0, 1, 0), length: Float, width: Float, curl: Float, rows: Int, cols: Int, _ mat: MaterialKey) -> Surface {
        var s = Surface(material: mat)
        let d = simd_normalize(dir)
        var side = simd_cross(up, d)
        if simd_length(side) < 1e-3 { side = V3(1, 0, 0) }
        side = simd_normalize(side)
        let n = simd_normalize(simd_cross(d, side))
        for face in 0..<2 {
            let base = UInt32(s.vertexCount)
            for r in 0...rows {
                let v = Float(r) / Float(rows)
                let half = 0.5 * width * (1 - 0.3 * v)
                for c in 0...cols {
                    let u = Float(c) / Float(cols)
                    let x = (u - 0.5) * 2
                    let camber = -0.08 * width * x * x
                    let p = root + d * (length * v) + side * (x * half) + n * (curl * length * v * v + camber + (face == 0 ? 0.008 : -0.008))
                    _ = s.add(p, face == 0 ? n : -n, V2(u, v))
                }
            }
            let row = UInt32(cols + 1)
            for r in 0..<rows { for c in 0..<cols {
                let a = base + UInt32(r) * row + UInt32(c)
                if face == 0 { s.quad(a, a + 1, a + row + 1, a + row) } else { s.quad(a, a + row, a + row + 1, a + 1) }
            }}
        }
        s.recomputeNormals(weldSeams: false)
        s.computeTangents()
        return s
    }

    /// Wing bone points for side sx (+1 right, -1 left): shoulder, elbow, wrist, hand tip.
    static func wingPoints(_ sx: Float) -> [V3] {
        [V3(1.1 * sx, 0.55, 1.4), V3(5.3 * sx, 0.65, 1.1), V3(9.9 * sx, 0.65, 1.5), V3(11.7 * sx, 0.6, 1.3)]
    }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [180])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)

        for (name, range, dur): (String, ClosedRange<Float>, Float) in
            [("flap", -1...1, 0.6), ("fold", 0...1, 0.9), ("talons", 0...1, 0.7), ("beak", 0...1, 0.4), ("head", -1...1, 0.8)] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, range, duration: dur))
        }
        _ = rig.part("body", pivot: .zero, joint: .fixed)

        // Wings: fold (Y at shoulder) > arm flap (Z at shoulder) > forearm fold (Y at elbow) > hand flap (Z at wrist).
        for (sx, tag) in [(Float(1), "R"), (Float(-1), "L")] {
            let w = Self.wingPoints(sx)
            _ = rig.part("fold\(tag)", parent: "body", pivot: w[0], joint: Joint(.revolute, axis: Y, range: sx > 0 ? 0...55 : -55...0, mimic: .init("fold", ratio: 55 * sx)))
            _ = rig.part("arm\(tag)", parent: "fold\(tag)", pivot: w[0], joint: Joint(.revolute, axis: Z, range: -32...32, mimic: .init("flap", ratio: 32 * sx)))
            _ = rig.part("fore\(tag)", parent: "arm\(tag)", pivot: w[1], joint: Joint(.revolute, axis: Y, range: sx > 0 ? 0...25 : -25...0, mimic: .init("fold", ratio: 25 * sx)))
            _ = rig.part("hand\(tag)", parent: "fore\(tag)", pivot: w[2], joint: Joint(.revolute, axis: Z, range: -20...20, mimic: .init("flap", ratio: 20 * sx)))
        }
        // Head yaw at the neck, lower mandible hinged under it.
        _ = rig.part("neck", parent: "body", pivot: V3(0, 0, Self.neckZ), joint: Joint(.revolute, axis: Y, range: -40...40, mimic: .init("head", ratio: 40)))
        _ = rig.part("mandible", parent: "neck", pivot: V3(0, 0.2, 5.5), joint: Joint(.revolute, axis: X, range: 0...28, mimic: .init("beak", ratio: 28)))
        // Legs: geometry is authored hanging down, then rotated +90 deg about X into the tucked rest (feet trail toward -Z).
        let tuck = simd_quatf(angle: .pi / 2, axis: X)
        for (sx, tag) in [(Float(1), "R"), (Float(-1), "L")] {
            let hip = V3(0.75 * sx, -0.9, -0.6)
            let ankle = hip + tuck.act(V3(0, -2.4, 0))
            _ = rig.part("leg\(tag)", parent: "body", pivot: hip, joint: Joint(.revolute, axis: X, range: -80...0, mimic: .init("talons", ratio: -80)))
            _ = rig.part("toes\(tag)", parent: "leg\(tag)", pivot: ankle, joint: Joint(.revolute, axis: X, range: -40...0, mimic: .init("talons", ratio: -40)))
            _ = rig.part("hallux\(tag)", parent: "leg\(tag)", pivot: ankle, joint: Joint(.revolute, axis: X, range: 0...40, mimic: .init("talons", ratio: 40)))
        }

        for l in 0..<2 {
            let hi = l == 0
            func put(_ s: Surface, _ part: String, _ x: Xform = .identity) { rig.add(s, x, to: part, lods: l...l) }
            let radial = hi ? 64 : 24
            let tubeSides = hi ? 48 : 12
            let rows = hi ? 5 : 3
            let cols = hi ? 2 : 1

            // Torso: 40 rings from the neck seam back to the vent, capped at the tail end.
            let tn = hi ? 34 : 14
            let torso = (0..<tn).map { i -> [V3] in
                let z = Self.mix(Self.neckZ, Self.tailEnd, Float(i) / Float(tn - 1))
                let r = Self.torsoR(z)
                return Self.ring(V3(0, Self.spineY(z), z), hw: r, hh: r * 0.96, radial: radial)
            }
            put(Prim.loft(torso, capEnd: true, material: body), "body")

            // Head and neck: crown to the neck seam (the neck part yaws about the seam centre).
            let hn = hi ? 24 : 10
            let headRings = (0..<hn).map { i -> [V3] in
                let z = Self.mix(Self.crownZ, Self.neckZ, pow(Float(i) / Float(hn - 1), 0.8))
                let r = Self.headR(z)
                return Self.ring(V3(0, Self.spineY(z), z), hw: r * 0.86, hh: r, radial: radial)
            }
            put(Prim.loft(headRings, capStart: true, material: head), "neck")

            // Neck ruff: white hackles over the seam, laid back onto the shoulders.
            let hackles = hi ? 24 : 10
            for k in 0..<hackles {
                let a = 2 * Float.pi * Float(k) / Float(hackles)
                let r = Self.headR(3.6) * 0.98
                let root = V3(r * 0.86 * sin(a), Self.spineY(3.6) + r * cos(a), 3.6)
                let out = simd_normalize(V3(sin(a), cos(a), 0))
                put(Self.feather(root, out * 0.35 - Z, up: out, length: 1.1, width: 0.42, curl: -0.05, rows: rows, cols: cols, tail), "neck")
            }

            // Beak: hooked upper bill (rings tip to base), lower mandible, cere.
            let bn = hi ? 18 : 8
            let beakTop = Self.spineY(5.5) + 0.05
            let upper = (0..<bn).map { i -> [V3] in
                let t = 1 - Float(i) / Float(bn - 1)
                let c = V3(0, beakTop - 0.95 * pow(t, 2.5), 5.45 + 1.6 * t - 0.3 * t * t * t)
                return Self.ring(c, hw: 0.4 * pow(1 - t, 0.8) + 0.02, hh: 0.48 * (1 - t) + 0.03, radial: hi ? 32 : 12)
            }
            put(Prim.loft(upper, capStart: true, capEnd: true, material: beakKey), "neck")
            let lower = (0..<(hi ? 12 : 6)).map { i -> [V3] in
                let t = 1 - Float(i) / Float(hi ? 11 : 5)
                let c = V3(0, beakTop - 0.45 - 0.1 * t, 5.45 + 1.05 * t)
                return Self.ring(c, hw: 0.32 * (1 - t) + 0.03, hh: 0.16 * (1 - t) + 0.02, radial: hi ? 32 : 12)
            }
            put(Prim.loft(lower, capStart: true, capEnd: true, material: beakKey), "mandible")
            put(Prim.superellipsoid(V3(0.86, 0.5, 0.5), exponent: 2.2, subdivisions: hi ? 4 : 2, material: beakKey), "neck", Xform(translation: V3(0, beakTop - 0.1, 5.45)))

            // Eyes under a white brow ridge.
            for sx: Float in [-1, 1] {
                let c = V3(0.66 * sx, Self.spineY(5.0) + 0.22, 5.0)
                let q = simd_quatf(from: Z, to: simd_normalize(V3(sx, 0.05, 0.35)))
                put(Prim.superellipsoid(V3(0.34, 0.34, 0.2), exponent: 2, subdivisions: hi ? 5 : 3, material: glass), "neck", Xform(translation: c + V3(0.05 * sx, 0, 0), rotation: q))
                put(Prim.superellipsoid(V3(0.3, 0.3, 0.14), exponent: 2, subdivisions: hi ? 4 : 2, material: iris), "neck", Xform(translation: c, rotation: q))
                put(Prim.superellipsoid(V3(0.14, 0.14, 0.08), exponent: 2, subdivisions: hi ? 3 : 2, material: pupil), "neck", Xform(translation: c + V3(0.07 * sx, 0, 0.02), rotation: q))
                put(Prim.superellipsoid(V3(0.25, 0.22, 0.7), exponent: 2.4, subdivisions: hi ? 3 : 2, material: head), "neck", Xform(translation: c + V3(-0.02 * sx, 0.2, 0.05), rotation: q))
            }

            // Wings.
            for (sx, tag) in [(Float(1), "R"), (Float(-1), "L")] {
                let w = Self.wingPoints(sx)
                let segParts = ["arm\(tag)", "fore\(tag)", "hand\(tag)"]
                let radii: [(Float, Float)] = [(0.55, 0.42), (0.42, 0.3), (0.3, 0.16)]
                let chords: [Float] = [3.0, 2.6, 1.5]
                for s in 0..<3 {
                    let a = w[s], b = w[s + 1]
                    let pn = hi ? 8 : 4
                    let path = (0..<pn).map { i -> V3 in
                        let t = Float(i) / Float(pn - 1)
                        return a + (b - a) * t + V3(0, 0.12 * sin(.pi * t), 0)
                    }
                    let rr = (0..<pn).map { i in Self.mix(radii[s].0, radii[s].1, Float(i) / Float(pn - 1)) }
                    put(Prim.tube(path, radii: rr, sides: tubeSides, seamTile: 0.8, material: covert, capEnd: s == 2), segParts[s])
                    // Covert panel behind the leading edge.
                    let mid = (a + b) / 2 + V3(0, 0.05, -chords[s] * 0.42)
                    let dir = simd_normalize(b - a)
                    put(Prim.superellipsoid(V3(simd_length(b - a) * 1.04, 0.22, chords[s]), exponent: 2.6, subdivisions: hi ? 4 : 2, material: covert),
                        segParts[s], Xform(translation: mid, rotation: simd_quatf(from: X * sx, to: dir)))
                }
                // Tertials on the arm, secondaries on the forearm, primaries fanned on the hand.
                let tert = hi ? 8 : 4
                for k in 0..<tert {
                    let t = (Float(k) + 0.5) / Float(tert)
                    let root = w[0] + (w[1] - w[0]) * t + V3(0, 0, -0.35)
                    put(Self.feather(root, V3(-0.1 * sx, -0.04, -1), length: 2.6 + 0.4 * t, width: 0.8, curl: 0.02, rows: rows, cols: cols, flight), "arm\(tag)")
                }
                let sec = hi ? 14 : 6
                for k in 0..<sec {
                    let t = (Float(k) + 0.5) / Float(sec)
                    let root = w[1] + (w[2] - w[1]) * t + V3(0, 0, -0.3)
                    put(Self.feather(root, V3(0.12 * sx * t, -0.04, -1), length: 3.0, width: 0.78, curl: 0.03, rows: rows, cols: cols, flight), "fore\(tag)")
                }
                let pri = hi ? 10 : 5
                for k in 0..<pri {
                    let t = Float(k) / Float(pri - 1)
                    let root = w[2] + (w[3] - w[2]) * t + V3(0, 0, -0.2)
                    let dA = V3(0.3 * sx, 0, -1), dB = V3(1 * sx, 0.04, 0.1)
                    let len = 3.2 + 0.9 * sin(.pi * (0.2 + 0.7 * t))
                    put(Self.feather(root, dA + (dB - dA) * t, length: len, width: 0.7 - 0.18 * t, curl: 0.05 + 0.04 * t, rows: rows, cols: cols, flight), "hand\(tag)")
                }
                // Greater and lesser covert rows on top of the flight feathers.
                for (row, count, len, back, lift) in [(0, hi ? 16 : 8, Float(1.6), Float(-0.6), Float(0.12)), (1, hi ? 11 : 6, Float(1.0), Float(-0.15), Float(0.2))] {
                    for k in 0..<count {
                        let t = (Float(k) + 0.5) / Float(count) * 0.92
                        let span = t * 2.6
                        let s = min(2, Int(span))
                        let f = span - Float(s)
                        let root = w[s] + (w[s + 1] - w[s]) * f + V3(0, lift, back)
                        put(Self.feather(root, V3(0.08 * sx, -0.05, -1), length: len, width: row == 0 ? 0.6 : 0.5, curl: 0.02, rows: rows, cols: cols, gold), segParts[s])
                    }
                }
            }

            // Tail fan.
            let tf = hi ? 12 : 6
            for k in 0..<tf {
                let t = Float(k) / Float(tf - 1)
                let a = (t - 0.5) * 1.2
                let root = V3(0.6 * sin(a), Self.spineY(Self.tailEnd) + 0.1 + 0.02 * Float(k % 2), Self.tailEnd + 0.4)
                put(Self.feather(root, V3(sin(a), 0.02, -cos(a)), length: 3.2 - 0.3 * abs(t - 0.5), width: 0.72, curl: 0.03, rows: rows, cols: cols, tail), "body")
            }

            // Legs, authored hanging down from the hip, then tucked.
            for (sx, tag) in [(Float(1), "R"), (Float(-1), "L")] {
                let hip = V3(0.75 * sx, -0.9, -0.6)
                let rest = Xform(translation: hip, rotation: tuck)
                put(Prim.superellipsoid(V3(0.95, 1.6, 1.05), exponent: 2.2, subdivisions: hi ? 4 : 2, material: body), "leg\(tag)", Xform(translation: hip + tuck.act(V3(0, -0.55, 0.05)), rotation: tuck))
                let tp = hi ? 6 : 3
                let tarsus = (0..<tp).map { i in V3(0, -0.9 - 1.5 * Float(i) / Float(tp - 1), 0) }
                put(Prim.tube(tarsus, radii: (0..<tp).map { i in 0.22 - 0.05 * Float(i) / Float(tp - 1) }, sides: tubeSides, seamTile: 0.4, material: foot, capEnd: false), "leg\(tag)", rest)
                let ankle = V3(0, -2.4, 0)
                func toe(_ yaw: Float, _ len: Float, part: String) {
                    let d = V3(sin(yaw), 0, cos(yaw))
                    let n = hi ? 5 : 3
                    let path = (0..<n).map { i -> V3 in
                        let t = Float(i) / Float(n - 1)
                        return ankle + d * (len * t) + V3(0, -0.25 * t * t, 0)
                    }
                    put(Prim.tube(path, radii: (0..<n).map { i in 0.14 - 0.05 * Float(i) / Float(n - 1) }, sides: hi ? 32 : 8, seamTile: 0.3, material: foot, capEnd: true), part, rest)
                    // Talon: curved keratin hook from the toe tip, curling down and back.
                    let tip = path[n - 1]
                    let cn = hi ? 7 : 3
                    let cl = (0..<cn).map { i -> V3 in
                        let t = Float(i) / Float(cn - 1)
                        let ang = t * 1.7
                        return tip + d * (0.45 * sin(ang)) + V3(0, -0.45 * (1 - cos(ang)), 0)
                    }
                    put(Prim.tube(cl, radii: (0..<cn).map { i in 0.1 * (1 - Float(i) / Float(cn - 1)) + 0.006 }, sides: hi ? 16 : 6, seamTile: 0.3, material: claw, capEnd: true), part, rest)
                }
                for yaw: Float in [-0.45, 0, 0.45] { toe(yaw * sx + 0.08 * sx, 0.95, part: "toes\(tag)") }
                toe(.pi, 0.7, part: "hallux\(tag)")
            }
        }

        rig.states = [
            RigState("rest"),
            RigState("glide"),
            RigState("upstroke", ["flap": 1]),
            RigState("downstroke", ["flap": -1]),
            RigState("tuck", ["fold": 1]),
            RigState("strike", ["flap": 0.6, "talons": 1]),
            RigState("scream", ["beak": 1, "head": 0.4]),
        ]
        return rig
    }
}
