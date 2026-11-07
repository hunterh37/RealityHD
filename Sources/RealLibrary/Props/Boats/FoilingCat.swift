import simd
import Foundation

/// 15 m foiling racing catamaran. Two lofted hulls (64 stations, white clearcoat paint with graphite rubbing strakes), a
/// graphite trampoline net on two carbon crossbeams with a bow pole, two crew pods, a 24 m two-element rigid wing sail
/// (main element 48 stations, trailing flap, graphite base and tip bands), carbon L-foils and T-rudders on telescoping
/// struts. Origin at the centre between the hulls at the waterline, bow +Z, up +Y. Hulls sit at x = +-3.6.
///
/// Authored pose is foil 0, heel 0, wing 0, rudder 0. Joints: `foil` 0...1 (hulls, net, wing and rudder posts lift 2 m
/// while the foil blades stay in the water, so the exposed strut lengthens), `heel` -1...1 (whole boat rolls 15 degrees about
/// the bow axis, positive raises +X), `wing` -1...1 (wing trim yaw 30 degrees about the mast, flap camber 15 degrees more),
/// `rudder` -1...1 (rudder blade yaw 20 degrees). All four are empty drivers; parts mimic them. 2 LODs.
public struct FoilingCat: RealArticulated {
    public static let id = "foiling-cat"
    public static let summary = "15 m foiling racing catamaran: lofted white hulls, trampoline net, carbon crossbeams, crew pods, two-element rigid wing sail, L-foils and T-rudders, joints foil, heel, wing, rudder."
    public static let tags = ["prop", "vehicle", "metal", "fabric", "harbor", "outdoor", "articulated", "sports"]
    public static let budget = 28_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 10, distance: 1.2)

    /// Hulls, wing skin, pods (clearcoat white paint).
    public var paint: MaterialKey = "metal.painted:EDEFEF"
    /// Rubbing strakes, wing base and tip bands, deck pads.
    public var livery: MaterialKey = "metal.painted:2A2D31"
    /// Crossbeams, foils, rudders, posts (Library carbon).
    public var carbon: MaterialKey = "composite.carbon"
    /// Trampoline net.
    public var net: MaterialKey = "fabric.webbing:1C1F23"
    /// Net lacing.
    public var lacing: MaterialKey = "fabric.nylon:D8DADA"
    /// Deck pad.
    public var pad: MaterialKey = "rubber.plate:1C1C1C"
    /// Pod windscreens.
    public var glass: MaterialKey = "glass.tinted:12202A"
    public init() {}

    static let hullX: Float = 3.6
    static let halfLen: Float = 7.5
    static let beam: Float = 0.46
    static let mast = V3(0, 1.0, 0.9)
    static let hinge: Float = -0.2          // flap hinge z (mast z - 1.1)
    static let wingY0: Float = 1.6
    static let wingSpan: Float = 24
    static let rudZ: Float = -6.6
    static let foilZ: Float = 0.4

    static func sgnPow(_ v: Float, _ p: Float) -> Float { (v < 0 ? -1 : 1) * pow(abs(v), p) }

    // MARK: Hull

    static func widthFactor(_ t: Float) -> Float {
        var w: Float = 1
        if t > 0.1 { let u = (t - 0.1) / 0.9; w = pow(max(0, 1 - pow(u, 2.2)), 0.6) }
        else if t < -0.2 { let u = (-t - 0.2) / 0.8; w = pow(max(0, 1 - pow(u, 2.8)), 0.5) }
        return max(0.02, w)
    }
    static func keel(_ t: Float) -> Float { -0.38 + 0.9 * pow(max(0, (t - 0.55) / 0.45), 2) + 0.5 * pow(max(0, (-t - 0.55) / 0.45), 2) }
    static func deck(_ t: Float) -> Float { 0.86 + 0.3 * pow(max(0, (t - 0.4) / 0.6), 2) - 0.2 * pow(max(0, (-t - 0.4) / 0.6), 2) }

    /// Point on the hull skin at station t in -1...1 and ring angle a (0 = +X side, pi/2 = deck centreline).
    static func hullPoint(_ side: Float, _ t: Float, _ a: Float, grow: Float = 1) -> V3 {
        let wf = widthFactor(t)
        let lo = keel(t), hi = deck(t)
        let yc = (lo + hi) / 2, h = (hi - lo) / 2 * pow(wf, 0.4)
        let c = cos(a), s = sin(a)
        return V3(side * hullX + beam * wf * sgnPow(c, 0.85) * grow, yc + h * sgnPow(s, 0.85) * grow, t * halfLen)
    }

    static func hullRings(_ side: Float, stations: Int, ring: Int) -> [[V3]] {
        (0..<stations).map { k -> [V3] in
            let t = Float(k) / Float(stations - 1) * 2 - 1
            return (0..<ring).map { j in hullPoint(side, t, 2 * .pi * Float(j) / Float(ring)) }
        }
    }

    // MARK: Foil sections

    /// Symmetric section: (lateral half thickness signed, z offset from the leading edge, negative aft). Winding runs leading
    /// edge, +lateral surface, trailing edge, -lateral surface.
    static func section(chord c: Float, thick: Float, per: Int) -> [(Float, Float)] {
        func t(_ p: Float) -> Float { 5 * thick * c * (0.2969 * sqrt(p) - 0.1260 * p - 0.3516 * p * p + 0.2843 * p * p * p - 0.1036 * p * p * p * p) }
        var out: [(Float, Float)] = []
        for j in 0..<(2 * per) {
            let th = j < per ? Float.pi * Float(j) / Float(per) : Float.pi * Float(2 * per - j) / Float(per)
            let p = 0.5 * (1 - cos(th))
            out.append((j < per ? t(p) : -t(p), -p * c))
        }
        return out
    }

    /// Rings stacked along +Y (vertical blades). Each station gives y, chord, thickness ratio, leading edge z, x centre.
    static func bladeRings(_ ys: [Float], per: Int, x0: Float = 0, _ f: (Float) -> (c: Float, th: Float, zle: Float, twist: Float)) -> [[V3]] {
        ys.map { y in
            let p = f(y)
            let pts = section(chord: p.c, thick: p.th, per: per)
            return pts.map { lat, dz in
                // Twist about the mast axis (x0, mast z).
                let q = V3(lat, 0, p.zle + dz - mast.z)
                let r = simd_quatf(angle: radians(p.twist), axis: V3(0, 1, 0)).act(q)
                return V3(x0 + r.x, y, r.z + mast.z)
            }
        }
    }

    /// Rings stacked along +X (horizontal foils). Ring plane is YZ; winding is flipped to stay right-handed about +X.
    static func spanRings(_ xs: [Float], y: Float, per: Int, _ f: (Float) -> (c: Float, th: Float, zle: Float)) -> [[V3]] {
        xs.map { x in
            let p = f(x)
            return section(chord: p.c, thick: p.th, per: per).map { lat, dz in V3(x, y - lat, p.zle + dz) }
        }
    }

    static func linspace(_ a: Float, _ b: Float, _ n: Int) -> [Float] { (0..<n).map { a + (b - a) * Float($0) / Float(n - 1) } }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [120])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)
        let m = Self.mast

        for (name, range, dur): (String, ClosedRange<Float>, Float) in
            [("foil", 0...1, 3.0), ("heel", -1...1, 1.5), ("wing", -1...1, 1.2), ("rudder", -1...1, 0.8)] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, range, duration: dur))
        }
        _ = rig.part("boat", pivot: .zero, joint: Joint(.revolute, axis: Z, range: -15...15, mimic: .init("heel", ratio: 15)))
        _ = rig.part("lift", parent: "boat", pivot: .zero, joint: Joint(.prismatic, axis: Y, range: 0...2, mimic: .init("foil", ratio: 2)))
        _ = rig.part("wingYaw", parent: "lift", pivot: m, joint: Joint(.revolute, axis: Y, range: -30...30, mimic: .init("wing", ratio: 30)))
        _ = rig.part("flap", parent: "wingYaw", pivot: V3(0, m.y, Self.hinge), joint: Joint(.revolute, axis: Y, range: -15...15, mimic: .init("wing", ratio: 15)))
        _ = rig.part("foilBladeL", parent: "boat", pivot: .zero, joint: .fixed)
        _ = rig.part("foilBladeR", parent: "boat", pivot: .zero, joint: .fixed)
        for (n, s) in [("L", Float(-1)), ("R", Float(1))] {
            _ = rig.part("rudder" + n, parent: "boat", pivot: V3(s * Self.hullX, 0, Self.rudZ),
                         joint: Joint(.revolute, axis: Y, range: -20...20, mimic: .init("rudder", ratio: 20)))
        }

        for l in 0..<2 {
            let hi = l == 0
            func put(_ s: Surface, _ part: String, _ x: Xform = .identity) { rig.add(s, x, to: part, lods: l...l) }
            let tubeSides = hi ? 48 : 16
            let per = hi ? 14 : 6
            let hullSt = hi ? 64 : 24
            let hullRing = hi ? 28 : 12

            // Hulls, rubbing strakes, deck pads.
            for side: Float in [-1, 1] {
                put(Prim.loft(Self.hullRings(side, stations: hullSt, ring: hullRing), capStart: true, capEnd: true, material: paint), "lift")
                for a in [Float(0.5), Float.pi - 0.5] {
                    let n = hi ? 40 : 14
                    let path = (0..<n).map { k -> V3 in
                        Self.hullPoint(side, -0.82 + 1.62 * Float(k) / Float(n - 1), a, grow: 1.012)
                    }
                    put(Prim.tube(path, radii: path.map { _ in 0.032 }, sides: hi ? 6 : 4, seamTile: 0.4, material: livery, capEnd: true), "lift")
                }
                put(Prim.superellipsoid(V3(0.5, 0.05, 7.4), exponent: 4, subdivisions: hi ? 6 : 3, material: pad), "lift",
                    Xform(translation: V3(side * Self.hullX, 0.865, -0.5)))
            }

            // Crossbeams, bow pole, net, lacing.
            for z in [Float(4.4), -5.0] {
                let path = (0..<10).map { k in V3(-Self.hullX - 0.2 + (2 * Self.hullX + 0.4) * Float(k) / 9, 0.56, z) }
                let radii = path.map { p -> Float in 0.15 - 0.03 * abs(p.x) / Self.hullX }
                put(Prim.tube(path, radii: radii, sides: tubeSides, seamTile: 0.5, material: carbon, capEnd: true), "lift")
            }
            let pole = (0..<8).map { k in V3(0, 0.7 + 0.25 * pow(Float(k) / 7, 2), 4.4 + 3.6 * Float(k) / 7) }
            put(Prim.tube(pole, radii: pole.indices.map { 0.11 - 0.06 * Float($0) / 7 }, sides: tubeSides, seamTile: 0.5, material: carbon, capEnd: true), "lift")
            put(Prim.roundedBox(V3(6.3, 0.04, 9.4), radius: 0.015, bevelSegments: 2, material: net), "lift", Xform(translation: V3(0, 0.78, -0.3)))
            let lace = hi ? 10 : 5
            for k in 0..<lace {
                let z = -4.6 + 8.6 * Float(k) / Float(lace - 1)
                let p = [V3(-3.1, 0.806, z), V3(0, 0.806, z), V3(3.1, 0.806, z)]
                put(Prim.tube(p, radii: [0.018, 0.018, 0.018], sides: hi ? 8 : 4, seamTile: 0.1, material: lacing, capEnd: true), "lift")
            }
            for k in 0..<(hi ? 6 : 3) {
                let x = -2.7 + 5.4 * Float(k) / Float(hi ? 5 : 2)
                let p = [V3(x, 0.806, -4.8), V3(x, 0.806, -0.3), V3(x, 0.806, 4.2)]
                put(Prim.tube(p, radii: [0.018, 0.018, 0.018], sides: hi ? 8 : 4, seamTile: 0.1, material: lacing, capEnd: true), "lift")
            }

            // Crew pods.
            for sx: Float in [-1, 1] {
                let px = sx * 0.95
                put(Prim.superellipsoid(V3(1.05, 0.55, 2.3), exponent: 2.6, subdivisions: hi ? 10 : 4, material: paint), "lift", Xform(translation: V3(px, 0.98, -2.0)))
                put(Prim.superellipsoid(V3(0.7, 0.12, 1.55), exponent: 2, subdivisions: hi ? 8 : 3, material: livery), "lift", Xform(translation: V3(px, 1.22, -2.25)))
                put(Prim.superellipsoid(V3(0.78, 0.38, 0.7), exponent: 2.4, subdivisions: hi ? 8 : 3, material: glass), "lift",
                    Xform(translation: V3(px, 1.2, -1.2), rotation: simd_quatf(angle: radians(-20), axis: X)))
            }

            // Mast step and swivel ring.
            put(Prim.lathe([V2(0.01, 0), V2(0.62, 0.02), V2(0.58, 0.45), V2(0.42, 0.75), V2(0.36, 0.8)], segments: hi ? 48 : 16, seamTile: 0.4, material: carbon), "lift",
                Xform(translation: V3(0, 0.88, m.z)))
            put(Prim.torus(major: 0.5, minor: 0.045, segments: hi ? 48 : 16, sides: hi ? 12 : 6, material: livery), "wingYaw", Xform(translation: V3(0, 1.62, m.z)))

            // Wing sail: main element and flap, lofted along the span.
            let n = hi ? 48 : 20
            let ys = Self.linspace(Self.wingY0, Self.wingY0 + Self.wingSpan, n)
            func chordAt(_ y: Float) -> Float { let u = (y - Self.wingY0) / Self.wingSpan; return 4.2 - 2.4 * pow(u, 1.2) }
            func twistAt(_ y: Float) -> Float { -3 * (y - Self.wingY0) / Self.wingSpan }
            let main = Self.bladeRings(ys, per: per) { y in
                let c = chordAt(y)
                return (0.35 * c + 1.2, 0.17, m.z + 0.35 * c, twistAt(y))
            }
            let flapR = Self.bladeRings(ys, per: per) { y in
                let c = chordAt(y)
                return (0.30 * c + 0.2, 0.10, Self.hinge + 0.1, twistAt(y))
            }
            let b0 = max(2, n / 9), b1 = n - 1 - max(2, n / 12)
            put(Prim.loft(Array(main[0...b0]), capStart: true, material: livery), "wingYaw")
            put(Prim.loft(Array(main[b0...b1]), material: paint), "wingYaw")
            put(Prim.loft(Array(main[b1...(n - 1)]), capEnd: true, material: livery), "wingYaw")
            put(Prim.loft(Array(flapR[0...b1]), capStart: true, material: paint), "flap")
            put(Prim.loft(Array(flapR[b1...(n - 1)]), capEnd: true, material: livery), "flap")

            // L-foils: telescoping sleeve under the hull, fixed blade in the water, inboard foil wing.
            for (name, s) in [("L", Float(-1)), ("R", Float(1))] {
                let sx = s * (Self.hullX - 0.35)
                let sleeve = Self.bladeRings(Self.linspace(-1.4, 0.5, hi ? 10 : 5), per: per, x0: sx) { _ in (0.62, 0.16, Self.foilZ + 0.3, 0) }
                put(Prim.loft(sleeve, capStart: true, capEnd: true, material: carbon), "lift")
                let lower = Self.bladeRings(Self.linspace(-2.3, 0.8, hi ? 12 : 5), per: per, x0: sx) { _ in (0.46, 0.13, Self.foilZ + 0.23, 0) }
                put(Prim.loft(lower, capStart: true, capEnd: true, material: carbon), "foilBlade" + name)
                let xs = s < 0 ? Self.linspace(sx, sx + 1.7, hi ? 10 : 4) : Self.linspace(sx - 1.7, sx, hi ? 10 : 4)
                let wingRings = Self.spanRings(xs, y: -2.25, per: per) { x in
                    let u = abs(x - sx) / 1.7
                    return (0.44 - 0.24 * u, 0.09, Self.foilZ + 0.22 - 0.1 * u)
                }
                put(Prim.loft(wingRings, capStart: true, capEnd: true, material: carbon), "foilBlade" + name)
            }

            // T-rudders: stock post on the hull, yawing blade, elevator.
            for (name, s) in [("L", Float(-1)), ("R", Float(1))] {
                let x0 = s * Self.hullX
                let post = Self.bladeRings(Self.linspace(-0.9, 2.0, hi ? 10 : 5), per: per, x0: x0) { _ in (0.3, 0.2, Self.rudZ + 0.15, 0) }
                put(Prim.loft(post, capStart: true, capEnd: true, material: carbon), "lift")
                let blade = Self.bladeRings(Self.linspace(-1.9, 1.6, hi ? 12 : 5), per: per, x0: x0) { y in
                    let u = (1.6 - y) / 3.5
                    return (0.26 + 0.2 * (1 - u), 0.11, Self.rudZ + 0.12 + 0.05 * u, 0)
                }
                put(Prim.loft(blade, capStart: true, capEnd: true, material: carbon), "rudder" + name)
                let elev = Self.spanRings(Self.linspace(x0 - 0.65, x0 + 0.65, hi ? 10 : 4), y: -1.86, per: per) { x in
                    let u = abs(x - x0) / 0.65
                    return (0.26 - 0.12 * u, 0.08, Self.rudZ + 0.12 - 0.02 * u)
                }
                put(Prim.loft(elev, capStart: true, capEnd: true, material: carbon), "rudder" + name)
            }
        }

        rig.states = [
            RigState("displacement"),
            RigState("foiling", ["foil": 1]),
            RigState("heel-lee", ["foil": 1, "heel": 1]),
            RigState("heel-windward", ["foil": 1, "heel": -1]),
            RigState("wing-eased", ["wing": 1]),
            RigState("wing-sheeted", ["wing": -1]),
            RigState("bear-away", ["foil": 1, "rudder": 1, "heel": 0.5, "wing": 0.5]),
            RigState("luff", ["foil": 1, "rudder": -1, "heel": -0.5, "wing": -0.5]),
        ]
        return rig
    }
}
