import simd
import Foundation

/// Ornithopter, 18 m wingspan Renaissance flapping-wing machine (original design): ash-wood spine, mast and A-frame (48-sided
/// turned spars), two canvas wings (lofted lens sections with camber, scalloped trailing edge, ash leading and mid spars and
/// batten ribs), brass hub brackets, pulleys and a toothed crank drum, a wicker pilot cradle with rim hoop and seat, hemp rope
/// rigging and a bird-like seven-feather tail fan. Origin at the pilot cradle, nose +Z, up +Y. Wing tips at x +-9.0, spine
/// z -5.4...4.6, tail fan reaches z -9.4.
///
/// Authored pose is the wings open and level, tail level, drum at rest. Joints: `flap` -1...1 (wings beat +-45 degrees about
/// the body axis, the outer section adds up to 20 degrees of tip lag), `fold` 0...1 (wings sweep back 80 degrees about the
/// vertical shoulder axis), `tail` -1...1 (tail fan pitch 25 degrees, positive lifts the fan), `crank` 0...1 (gear drum turns 360
/// degrees). All four are empty drivers; child parts mimic them. 2 LODs.
public struct Ornithopter: RealArticulated {
    public static let id = "ornithopter"
    public static let summary = "18 m ornithopter: ash-wood frame, canvas wings on ribbed spars, brass pulleys and crank drum, wicker pilot cradle, hemp rigging, tail fan, joints flap, fold, tail, crank."
    public static let tags = ["prop", "vehicle", "wood", "fabric", "metal", "outdoor", "articulated"]
    public static let budget = 30_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 12, distance: 1.1, ground: true, studio: true)

    /// Frame spars, mast, battens and seat (pale ash).
    public var wood: MaterialKey = "wood.ash"
    /// Wing and tail membranes (woven canvas).
    public var canvas: MaterialKey = "fabric.canvas"
    /// Brackets, pulleys, drum and gear teeth.
    public var brass: MaterialKey = "metal.brass-aged"
    /// Rigging lines.
    public var rope: MaterialKey = "rope.hemp"
    /// Pilot cradle weave.
    public var wicker: MaterialKey = "wicker.willow"
    public init() {}

    // MARK: Geometry

    static let shoulderT: Float = 0
    static let tipT: Float = 0.6

    static func clamp01(_ x: Float) -> Float { min(1, max(0, x)) }
    static func smooth(_ x: Float) -> Float { let t = clamp01(x); return t * t * (3 - 2 * t) }
    static func mix(_ a: Float, _ b: Float, _ t: Float) -> Float { a + (b - a) * t }

    /// Leading spar point at span fraction t (0 root, 1 tip), right side s = 1, mirror with s = -1.
    static func lead(_ t: Float, side s: Float) -> V3 {
        V3(s * (0.9 + 8.1 * t), 1.8 + 1.0 * t - 0.2 * t * t, 0.8 - 1.4 * t)
    }

    /// Chord length at t, rounded at the tip.
    static func chord(_ t: Float) -> Float { 4.4 * (1 - 0.62 * t) * sqrt(max(0.04, 1 - pow(t, 7))) }

    /// Trailing edge scallop between ribs (0 at a rib, 1 between).
    static func scallop(_ t: Float) -> Float { let d = t * 9 - floor(t * 9); return sin(.pi * d) }

    /// Point on the wing surface at span t, chord fraction q (0 leading edge, 1 trailing edge), thickness sign k.
    static func wingPoint(_ t: Float, _ q: Float, k: Float, side s: Float) -> V3 {
        let l = lead(t, side: s)
        let c = chord(t) * (1 - 0.05 * scallop(t) * Self.smooth((q - 0.8) * 5))
        let camber = 0.16 * c * 4 * q * (1 - q)
        let flutter = 0.035 * sin(t * 38 + q * 7) * q
        let thick = 0.05 * c * sqrt(q) * (1 - q) * k
        return V3(l.x, l.y + camber + flutter + thick - 0.55 * q * t, l.z - c * q)
    }

    /// Membrane section rings from t0 to t1.
    static func wingRings(t0: Float, t1: Float, stations: Int, radial: Int, side s: Float) -> [[V3]] {
        (0..<stations).map { i -> [V3] in
            let t = Self.mix(t0, t1, Float(i) / Float(stations - 1))
            return (0..<radial).map { j -> V3 in
                let a = 2 * Float.pi * Float(j) / Float(radial)
                let q = (1 - cos(a)) / 2
                return wingPoint(t, q, k: sin(a) >= 0 ? 1 : -1, side: s)
            }
        }
    }

    static func xzRing(y: Float, rx: Float, rz: Float, center: V3 = .zero, radial: Int, weave: Float = 0) -> [V3] {
        (0..<radial).map { j -> V3 in
            let a = 2 * Float.pi * Float(j) / Float(radial)
            let w = 1 + weave * sin(a * 16)
            return center + V3(rx * w * sin(a), y, rz * w * cos(a))
        }
    }

    /// Cradle rings from the floor (k = 0) to the rim.
    static func cradleRings(stations: Int, radial: Int) -> [[V3]] {
        (0..<stations).map { k -> [V3] in
            let u = Float(k) / Float(stations - 1)
            let r = Self.mix(0.28, 1.0, pow(sin(.pi * 0.5 * min(1, u * 1.15 + 0.1)), 0.7))
            return xzRing(y: -1.1 + 1.3 * u, rx: 0.78 * r, rz: 1.0 * r, radial: radial, weave: 0.012)
        }
    }

    /// Tail feather rings along -Z from the root.
    static func featherRings(length: Float, width: Float, stations: Int, radial: Int) -> [[V3]] {
        (0..<stations).map { k -> [V3] in
            let t = Float(k) / Float(stations - 1)
            let w = width * (0.35 + 0.65 * sin(.pi * min(1, 0.25 + 0.75 * t) * 0.9)) * sqrt(max(0.05, 1 - pow(t, 6)))
            let bow = 0.05 * sin(.pi * t)
            return (0..<radial).map { j -> V3 in
                let a = 2 * Float.pi * Float(j) / Float(radial)
                return V3(w * cos(a), 0.035 * sin(a) + bow, -length * t)
            }
        }
    }

    static let tailBase = V3(0, 0.9, -5.2)
    static let drumPivot = V3(0, 0.95, 0.35)

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [120])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)

        for (name, range, dur): (String, ClosedRange<Float>, Float) in
            [("flap", -1...1, 0.55), ("fold", 0...1, 1.6), ("tail", -1...1, 0.8), ("crank", 0...1, 1.1)] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, range, duration: dur))
        }
        _ = rig.part("frame", pivot: .zero, joint: .fixed)
        _ = rig.part("tailPitch", pivot: Self.tailBase, joint: Joint(.revolute, axis: X, range: -25...25, mimic: .init("tail", ratio: 25)))
        _ = rig.part("drum", pivot: Self.drumPivot, joint: Joint(.revolute, axis: X, range: 0...360, mimic: .init("crank", ratio: 360)))
        for (n, s) in [("R", Float(1)), ("L", Float(-1))] {
            let sh = Self.lead(0, side: s)
            _ = rig.part("fold" + n, pivot: sh, joint: Joint(.revolute, axis: Y, range: s > 0 ? 0...80 : -80...0, mimic: .init("fold", ratio: 80 * s)))
            _ = rig.part("wing" + n, parent: "fold" + n, pivot: sh, joint: Joint(.revolute, axis: Z, range: -45...45, mimic: .init("flap", ratio: 45 * s)))
            let tp = Self.lead(Self.tipT, side: s)
            _ = rig.part("tip" + n, parent: "wing" + n, pivot: tp, joint: Joint(.revolute, axis: Z, range: -20...20, mimic: .init("flap", ratio: 20 * s)))
        }

        for l in 0..<2 {
            let hi = l == 0
            func put(_ s: Surface, _ part: String, _ x: Xform = .identity) { rig.add(s, x, to: part, lods: l...l) }
            let tubeSides = hi ? 32 : 16
            let thin = hi ? 10 : 6

            func line(_ a: V3, _ b: V3, r: Float, sides: Int, _ mat: MaterialKey, stations: Int = 4, sag: Float = 0) -> Surface {
                var path: [V3] = [], radii: [Float] = []
                for i in 0..<stations {
                    let t = Float(i) / Float(stations - 1)
                    path.append(simd_mix(a, b, V3(repeating: t)) - V3(0, sag * 4 * t * (1 - t), 0))
                    radii.append(r)
                }
                return Prim.tube(path, radii: radii, sides: sides, seamTile: 0.4, material: mat, capEnd: true)
            }

            // Spine, tail boom, mast and A-frame.
            var sp: [V3] = [], sr: [Float] = []
            for i in 0..<(hi ? 14 : 6) {
                let t = Float(i) / Float(hi ? 13 : 5)
                sp.append(V3(0, Self.mix(0.15, 0.95, Self.smooth(t * 1.3)) - 0.1 * sin(.pi * t), Self.mix(4.6, -5.4, t)))
                sr.append(Self.mix(0.12, 0.17, sin(.pi * t)) * (t > 0.9 ? 0.8 : 1))
            }
            put(Prim.tube(sp, radii: sr, sides: tubeSides, seamTile: 0.5, material: wood, capEnd: true), "frame")
            put(line(V3(0, 2.7, 0.5), V3(0.62, 0.1, 0.95), r: 0.1, sides: tubeSides, wood), "frame")
            put(line(V3(0, 2.7, 0.5), V3(-0.62, 0.1, 0.95), r: 0.1, sides: tubeSides, wood), "frame")
            put(line(V3(0, 2.7, 0.5), V3(0, 0.3, -1.2), r: 0.09, sides: tubeSides, wood), "frame")
            put(line(V3(0, 2.7, 0.5), V3(0, 0.55, 4.0), r: 0.04, sides: thin, rope, sag: 0.1), "frame")
            put(line(V3(0, 2.7, 0.5), V3(0, 0.75, -5.0), r: 0.04, sides: thin, rope, sag: 0.1), "frame")
            put(Prim.superellipsoid(V3(0.3, 0.26, 0.3), exponent: 2, subdivisions: hi ? 5 : 3, material: brass), "frame", Xform(translation: V3(0, 2.75, 0.5)))
            put(Prim.superellipsoid(V3(0.24, 0.22, 0.34), exponent: 2, subdivisions: hi ? 5 : 3, material: brass), "frame", Xform(translation: V3(0, 0.15, 4.65)))

            // Pilot cradle, rim hoop, seat, control bar and foot rails.
            put(Prim.loft(Self.cradleRings(stations: hi ? 14 : 6, radial: hi ? 36 : 16), capStart: true, material: wicker), "frame")
            put(Prim.torus(major: 0.9, minor: 0.05, segments: hi ? 36 : 16, sides: hi ? 10 : 8, material: wood), "frame", Xform(translation: V3(0, 0.2, 0), scale: V3(0.8, 1, 1.0)))
            put(Prim.roundedBox(V3(1.1, 0.08, 0.8), radius: 0.03, material: wood), "frame", Xform(translation: V3(0, -0.45, -0.1)))
            put(line(V3(-0.75, 0.55, 1.0), V3(0.75, 0.55, 1.0), r: 0.045, sides: thin, wood), "frame")
            put(line(V3(-0.3, -0.7, 1.1), V3(0.3, -0.7, 1.1), r: 0.04, sides: thin, wood), "frame")
            put(line(V3(0, 0.2, 0.9), V3(0, 0.55, 1.0), r: 0.04, sides: thin, wood), "frame")

            // Brass shoulder hubs and mast pulleys.
            for s: Float in [1, -1] {
                put(Prim.superellipsoid(V3(0.32, 0.3, 0.32), exponent: 2, subdivisions: hi ? 5 : 3, material: brass), "frame", Xform(translation: Self.lead(0, side: s) - V3(s * 0.25, 0, 0)))
                let pu = V3(s * 0.45, 2.45, 0.5)
                put(Prim.torus(major: 0.26, minor: 0.05, segments: hi ? 24 : 12, sides: hi ? 10 : 8, material: brass), "frame",
                    Xform(translation: pu, rotation: simd_quatf(angle: .pi / 2, axis: Z)))
                put(Prim.cylinder(radius: 0.08, height: 0.14, segments: hi ? 24 : 10, material: brass), "frame",
                    Xform(translation: pu - V3(s * 0.07, 0, 0), rotation: simd_quatf(angle: -.pi / 2 * s, axis: Z)))
            }

            // Crank drum: axle, drum barrel, two flanges, spokes and gear teeth, turns on `drum`.
            let dq = simd_quatf(angle: -.pi / 2, axis: Z)
            put(Prim.cylinder(radius: 0.5, height: 1.2, segments: hi ? 48 : 16, material: brass, grainVertical: true), "drum", Xform(translation: Self.drumPivot + V3(-0.6, 0, 0), rotation: dq))
            put(Prim.cylinder(radius: 0.07, height: 1.9, segments: hi ? 24 : 10, material: wood), "drum", Xform(translation: Self.drumPivot + V3(-0.95, 0, 0), rotation: dq))
            for fx: Float in [-0.62, 0.62] {
                put(Prim.torus(major: 0.58, minor: 0.06, segments: hi ? 36 : 16, sides: hi ? 10 : 8, material: brass), "drum", Xform(translation: Self.drumPivot + V3(fx, 0, 0), rotation: dq))
            }
            for k in 0..<(hi ? 10 : 8) {
                let a = 2 * Float.pi * Float(k) / Float(hi ? 10 : 8)
                let off = V3(0, 0.66 * cos(a), 0.66 * sin(a))
                put(Prim.roundedBox(V3(0.16, 0.16, 0.12), radius: 0.025, material: brass), "drum",
                    Xform(translation: Self.drumPivot + V3(0.62, 0, 0) + off, rotation: simd_quatf(angle: -a, axis: X)))
            }
            put(line(Self.drumPivot + V3(0.62, 0, 0.0), Self.drumPivot + V3(0.62, 0, 0.58), r: 0.05, sides: thin, wood), "drum")

            // Wings: membrane sections, leading and mid spars, batten ribs, rigging.
            for (n, s) in [("R", Float(1)), ("L", Float(-1))] {
                for (part, t0, t1) in [("wing" + n, Float(0), Self.tipT), ("tip" + n, Self.tipT, Float(1))] {
                    let inner = t0 == 0
                    put(Prim.loft(Self.wingRings(t0: t0, t1: t1, stations: hi ? (inner ? 12 : 10) : 6, radial: hi ? 28 : 14, side: s), capStart: inner, capEnd: !inner, material: canvas), part)
                    var lp: [V3] = [], lr: [Float] = []
                    var mp: [V3] = [], mr: [Float] = []
                    for i in 0..<(hi ? 6 : 4) {
                        let t = Self.mix(t0, t1, Float(i) / Float(hi ? 5 : 3))
                        lp.append(Self.wingPoint(t, 0.0, k: 1, side: s) + V3(0, 0.02, 0)); lr.append(0.13 * (1 - 0.7 * t) + 0.025)
                        mp.append(Self.wingPoint(t, 0.34, k: 1, side: s) + V3(0, 0.07, 0)); mr.append(0.07 * (1 - 0.65 * t) + 0.02)
                    }
                    put(Prim.tube(lp, radii: lr, sides: tubeSides, seamTile: 0.5, material: wood, capEnd: true), part)
                    put(Prim.tube(mp, radii: mr, sides: hi ? 32 : 10, seamTile: 0.4, material: wood, capEnd: true), part)
                    let ribs = 9
                    for r in 0..<ribs {
                        let t = (Float(r) + 0.5) / Float(ribs)
                        guard t >= t0 && t < t1 else { continue }
                        var rp: [V3] = [], rr: [Float] = []
                        for i in 0..<5 {
                            let q = Float(i) / 4 * 0.97
                            rp.append(Self.wingPoint(t, q, k: 1, side: s) + V3(0, 0.03, 0)); rr.append(0.035 * (1 - 0.5 * q))
                        }
                        put(Prim.tube(rp, radii: rr, sides: thin, seamTile: 0.3, material: wood, capEnd: true), part)
                    }
                }
                // Rigging from the mast crown to the wing spars, slack.
                let crown = V3(s * 0.25, 2.7, 0.5)
                put(line(crown, Self.wingPoint(0.5, 0, k: 1, side: s), r: 0.028, sides: thin, rope, stations: 5, sag: 0.15), "wing" + n)
                put(line(crown + V3(0, 0, -0.2), Self.wingPoint(0.3, 0.34, k: 1, side: s), r: 0.028, sides: thin, rope, stations: 5, sag: 0.1), "wing" + n)
                put(line(V3(s * 0.7, 0.2, 0.6), Self.wingPoint(0.15, 0.0, k: -1, side: s), r: 0.028, sides: thin, rope, stations: 5, sag: 0.1), "wing" + n)
                put(line(Self.wingPoint(0.6, 0.0, k: 1, side: s), Self.wingPoint(0.92, 0.0, k: 1, side: s) + V3(0, 0.3, 0), r: 0.022, sides: thin, rope, stations: 4, sag: 0.05), "tip" + n)
            }

            // Tail: stub boom, spreader spars and seven feathers fanning +-52 degrees.
            put(line(Self.tailBase + V3(0, 0, 0.5), Self.tailBase + V3(0, 0.0, -0.5), r: 0.1, sides: tubeSides, wood), "tailPitch")
            let feathers = 7
            for f in 0..<feathers {
                let u = Float(f) / Float(feathers - 1) * 2 - 1
                let ang = u * 0.9
                let len: Float = 4.2 - 0.5 * abs(u)
                put(Prim.loft(Self.featherRings(length: len, width: 0.62, stations: hi ? 10 : 5, radial: hi ? 14 : 8), capStart: true, capEnd: true, material: canvas), "tailPitch",
                    Xform(translation: Self.tailBase, rotation: simd_quatf(angle: ang, axis: Y)))
                put(Prim.tube([Self.tailBase, Self.tailBase + simd_quatf(angle: ang, axis: Y).act(V3(0, 0.04, -len + 0.2))], radii: [0.035, 0.02], sides: thin, seamTile: 0.3, material: wood, capEnd: true), "tailPitch")
            }
            put(Prim.superellipsoid(V3(0.2, 0.18, 0.28), exponent: 2, subdivisions: hi ? 6 : 3, material: brass), "tailPitch", Xform(translation: Self.tailBase))
        }

        rig.states = [
            RigState("glide"),
            RigState("up", ["flap": 1]),
            RigState("down", ["flap": -1]),
            RigState("folded", ["fold": 1]),
            RigState("climb", ["flap": 0.5, "tail": 1, "crank": 0.5]),
            RigState("dive", ["flap": -0.5, "tail": -1]),
        ]
        return rig
    }
}
