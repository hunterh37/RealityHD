import simd
import Foundation

/// Island turtle, 40 m long sea turtle carrying a small wooded island: a lofted shell (64 stations, 64 radial points) with
/// scute seams and barnacle clusters, a moss mound on the back with three trees (lofted bark trunks and leaf cards) and a rock
/// outcrop, a leathery neck and head (lofted, glass eyes with lids), four paddle flippers (lofted, two segments on the front pair)
/// and a tail. Origin at the waterline under the shell centre, head +Z, up +Y. Shell spans z -15...15, nose at z 21.7, tail tip
/// at z -19.
///
/// Authored pose is the neck fully out, eyes open, body at the waterline. Joints: `swim` -1...1 (front flippers beat +-32 degrees
/// with a lagging tip, hind flippers paddle +-18 degrees), `head` -1...1 (head yaw 35 degrees, positive toward +X), `neck` 0...1
/// (0 pulls the head 7 m back into the shell, 1 fully out), `rise` 0...1 (whole body lifts 4 m), `blink` 0...1 (lids close).
/// All five are empty drivers; child parts mimic them. 2 LODs.
public struct IslandTurtle: RealArticulated {
    public static let id = "island-turtle"
    public static let summary = "40 m island turtle: lofted scute shell with barnacles, moss mound with three trees and a rock outcrop, leathery neck and head with lids, four paddle flippers, joints swim, head, neck, rise, blink."
    public static let tags = ["prop", "creature", "vehicle", "outdoor", "plant", "stone", "articulated"]
    public static let budget = 30_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 14, distance: 1.2, ground: true, studio: true)

    /// Shell dome, wet olive-brown plates.
    public var shell: MaterialKey = "rock.river-wet"
    /// Leathery skin of head, neck, flippers and tail (dino.scale-skin, 2048 px, scale normal).
    public var skin: MaterialKey = "dino.scale-skin"
    /// Barnacle clusters.
    public var barnacle: MaterialKey = "rock.limestone"
    /// Moss and grass mound on the shell.
    public var moss: MaterialKey = "moss.cushion"
    /// Rock outcrop on the mound.
    public var rock: MaterialKey = "rock.mossy"
    /// Tree trunks.
    public var bark: MaterialKey = "bark.oak"
    /// Leaf cards (tintable plain leaf).
    public var leaf: MaterialKey = "leaf.plain:3E6A26"
    /// Eyes (tinted glass over dark iris).
    public var eye: MaterialKey = "glass.tinted:0C0804"
    public init() {}

    // MARK: Geometry

    static let halfLen: Float = 15
    static let halfWidth: Float = 10.5
    static let domeTop: Float = 7
    static let domeBottom: Float = 4
    static let neckPivot = V3(0, 1.0, 12)
    static let eyePos = V3(2.15, 1.9, 18.7)

    static func clamp01(_ x: Float) -> Float { min(1, max(0, x)) }
    static func smooth(_ x: Float) -> Float { let t = clamp01(x); return t * t * (3 - 2 * t) }
    static func mix(_ a: Float, _ b: Float, _ t: Float) -> Float { a + (b - a) * t }

    /// Shell radius factor along z.
    static func shellF(_ z: Float) -> Float { max(0.03, sqrt(max(0, 1 - pow(abs(z / halfLen), 2.4)))) }

    /// Shell top height at (x, z), 0 outside the footprint.
    static func shellTop(_ x: Float, _ z: Float) -> Float {
        let f = shellF(z)
        let q = x / (halfWidth * f)
        return domeTop * f * sqrt(max(0, 1 - q * q))
    }

    /// Scute seam relief in metres (negative grooves) from z and ring angle.
    static func scuteRelief(_ z: Float, _ a: Float) -> Float {
        func seam(_ x: Float) -> Float { let d = x - floor(x) - 0.5; return exp(-d * d / 0.004) }
        let rows = seam((z + halfLen) / 6.0 + 0.5)
        let cols = seam(a / (.pi / 3.2) + 0.5) * smooth(sin(a) * 3)
        return -0.22 * max(rows * smooth(sin(a) * 3), cols) + 0.1 * sin(z * 1.3 + a * 5) * sin(a)
    }

    static func shellRings(stations: Int, radial: Int, from: Int, to: Int) -> [[V3]] {
        (from...to).map { k -> [V3] in
            let z = -halfLen + 2 * halfLen * Float(k) / Float(stations - 1)
            let f = shellF(z)
            return (0..<radial).map { j -> V3 in
                let a = 2 * Float.pi * Float(j) / Float(radial)
                let top = sin(a) > 0
                let relief = top ? scuteRelief(z, a) * f : 0
                let rx = halfWidth * f + relief, ry = (top ? domeTop : domeBottom) * f + relief
                return V3(rx * cos(a), ry * sin(a), z)
            }
        }
    }

    /// Mound rings from the buried edge (k = 0) to the crown, centre cap closes the top.
    static func moundRings(rings: Int, radial: Int) -> [[V3]] {
        (0..<rings).map { k -> [V3] in
            let r = 1 - Float(k) / Float(rings) * 0.97
            return (0..<radial).map { j -> V3 in
                let a = 2 * Float.pi * Float(j) / Float(radial)
                let wob = 1 + 0.08 * sin(a * 3 + 1) + 0.05 * sin(a * 7)
                let x = 7.2 * r * wob * cos(a), z = -9.6 * r * wob * sin(a) - 0.5
                let hump = 2.4 * pow(max(0, 1 - r * r), 0.7) + 0.2 * sin(x * 0.9) * sin(z * 0.8) * (1 - r)
                return V3(x, shellTop(x, z) - 0.7 + 0.7 * smooth(1 - r * 3) + hump, z)
            }
        }
    }

    static func groundY(_ x: Float, _ z: Float) -> Float {
        let r2 = (x / 7.2) * (x / 7.2) + ((z + 0.5) / 9.6) * ((z + 0.5) / 9.6)
        return shellTop(x, z) + 2.4 * pow(max(0, 1 - r2), 0.7)
    }

    /// Ellipse ring in the XY plane along +Z, counter-clockwise seen from +Z.
    static func zRing(_ p: V3, _ rx: Float, _ ry: Float, radial: Int, wrinkle: Float = 0) -> [V3] {
        (0..<radial).map { j -> V3 in
            let a = 2 * Float.pi * Float(j) / Float(radial)
            let w = 1 + wrinkle * sin(a * 6 + p.z * 1.4)
            return p + V3(rx * w * cos(a), ry * w * sin(a), 0)
        }
    }

    static func neckRings(stations: Int, radial: Int) -> [[V3]] {
        (0..<stations).map { k -> [V3] in
            let t = Float(k) / Float(stations - 1)
            let z = 9.5 + 6.9 * t
            return zRing(V3(0, mix(0.4, 1.1, t), z), mix(2.9, 2.2, smooth(t)), mix(2.6, 2.1, smooth(t)), radial: radial, wrinkle: 0.05 * (1 - t * 0.5))
        }
    }

    static func headRings(stations: Int, radial: Int) -> [[V3]] {
        (0..<stations).map { k -> [V3] in
            let u = Float(k) / Float(stations - 1)
            let z = 16.3 + 5.4 * u
            let cap = max(0.03, sqrt(max(0, 1 - pow(u, 3.2))))
            let brow = 1 + 0.12 * exp(-pow((u - 0.35) / 0.2, 2))
            let rx = mix(2.2, 2.45, smooth(u * 2)) * (1 - 0.3 * smooth(u)) * cap * brow
            let ry = mix(2.1, 1.9, smooth(u)) * cap * (u > 0.6 ? 0.78 : 1) * brow
            return zRing(V3(0, 1.1 + 0.7 * sin(.pi * u) - 0.5 * smooth(u), z), rx, ry, radial: radial)
        }
    }

    /// Flipper axis point at t in 0...1 (right side, mirror for left).
    static func flipperPath(_ shoulder: V3, length: Float, sweep: Float, droop: Float, _ t: Float, side s: Float) -> V3 {
        shoulder + V3(s * length * t, -droop * t - 0.5 * t * t, -sweep * t * t)
    }

    static func flipperRings(shoulder: V3, length: Float, chord: Float, thick: Float, sweep: Float, droop: Float, side s: Float,
                             t0: Float, t1: Float, stations: Int, radial: Int) -> [[V3]] {
        (0..<stations).map { k -> [V3] in
            let t = mix(t0, t1, Float(k) / Float(stations - 1))
            let c = flipperPath(shoulder, length: length, sweep: sweep, droop: droop, t, side: s)
            let w = chord * (0.28 + 0.72 * pow(sin(.pi * min(1, 0.18 + 0.82 * t) * 0.92), 0.7)) * pow(1 - 0.9 * t * t, 0.6) + 0.12
            let h = thick * (1 - 0.7 * t) + 0.1
            return (0..<radial).map { j -> V3 in
                let a = 2 * Float.pi * Float(j) / Float(radial)
                return c + V3(0, h * sin(a), -s * w * cos(a))
            }
        }
    }

    static func trunk(_ base: V3, height: Float, lean: V3, radius: Float, stations: Int, sides: Int, _ mat: MaterialKey) -> Surface {
        var path: [V3] = [], radii: [Float] = []
        for i in 0..<stations {
            let t = Float(i) / Float(stations - 1)
            path.append(base + V3(0, height * t, 0) + lean * t * t + V3(0.25 * sin(t * 5 + base.x), 0, 0.25 * cos(t * 4 + base.z)) * t)
            radii.append(radius * (1 - 0.72 * t) * (1 + 0.5 * exp(-t * 14)))
        }
        return Prim.tube(path, radii: radii, sides: sides, seamTile: 0.6, material: mat, capEnd: true)
    }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [140])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)
        let eyeOpen: Float = 70

        for (name, range, dur): (String, ClosedRange<Float>, Float) in
            [("swim", -1...1, 1.0), ("head", -1...1, 1.2), ("neck", 0...1, 2.0), ("rise", 0...1, 5.0), ("blink", 0...1, 0.3)] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, range, duration: dur))
        }
        _ = rig.part("body", pivot: .zero, joint: Joint(.prismatic, axis: Y, range: 0...4, mimic: .init("rise", ratio: 4)))
        _ = rig.part("neckSlide", parent: "body", pivot: Self.neckPivot, joint: Joint(.prismatic, axis: Z, range: -7...0, mimic: .init("neck", ratio: 7, offset: -7)))
        _ = rig.part("headYaw", parent: "neckSlide", pivot: Self.neckPivot, joint: Joint(.revolute, axis: Y, range: -35...35, mimic: .init("head", ratio: 35)))

        let frontShoulder = V3(8.4, -0.4, 7.5), hindShoulder = V3(6.2, -0.8, -12.2)
        let frontLen: Float = 14, hindLen: Float = 6.2
        let tipT: Float = 0.55
        for (n, s) in [("R", Float(1)), ("L", Float(-1))] {
            let sh = V3(frontShoulder.x * s, frontShoulder.y, frontShoulder.z)
            _ = rig.part("fFlip" + n, parent: "body", pivot: sh, joint: Joint(.revolute, axis: Z, range: -32...32, mimic: .init("swim", ratio: 32 * s)))
            let tipPivot = Self.flipperPath(sh, length: frontLen, sweep: 3.4, droop: 1.6, tipT, side: s)
            _ = rig.part("fTip" + n, parent: "fFlip" + n, pivot: tipPivot, joint: Joint(.revolute, axis: Z, range: -22...22, mimic: .init("swim", ratio: 22 * s)))
            let hs = V3(hindShoulder.x * s, hindShoulder.y, hindShoulder.z)
            _ = rig.part("hFlip" + n, parent: "body", pivot: hs, joint: Joint(.revolute, axis: Y, range: -18...18, mimic: .init("swim", ratio: -18 * s)))
            let eye = V3(Self.eyePos.x * s, Self.eyePos.y, Self.eyePos.z)
            _ = rig.part("lid" + n, parent: "headYaw", pivot: eye, joint: Joint(.revolute, axis: Z, range: s > 0 ? 0...eyeOpen : -eyeOpen...0,
                                                                              mimic: .init("blink", ratio: -eyeOpen * s, offset: eyeOpen * s)))
        }

        let rng0 = SeededRNG(seed: 7)
        for l in 0..<2 {
            let hi = l == 0
            func put(_ s: Surface, _ part: String, _ x: Xform = .identity) { rig.add(s, x, to: part, lods: l...l) }
            let st = hi ? 64 : 24
            let rad = hi ? 64 : 24

            // Shell: two lofts split at the middle, plain wet plates above the waterline, same material below.
            let mid = st / 2
            put(Prim.loft(Self.shellRings(stations: st, radial: rad, from: 0, to: mid), capStart: true, material: shell), "body")
            put(Prim.loft(Self.shellRings(stations: st, radial: rad, from: mid, to: st - 1), capEnd: true, material: shell), "body")

            // Moss and grass mound.
            put(Prim.loft(Self.moundRings(rings: hi ? 26 : 12, radial: hi ? 48 : 20), capEnd: true, material: moss), "body")

            // Rock outcrop: two stacked blocks.
            put(Prim.superellipsoid(V3(4.2, 3.2, 3.6), exponent: 3, subdivisions: hi ? 8 : 3, material: rock,
                                    bulge: { d in 1 + 0.12 * sin(d.x * 7) * cos(d.z * 5) }), "body",
                Xform(translation: V3(4.6, Self.groundY(4.6, 4.5) + 0.4, 4.5), rotation: simd_quatf(angle: 0.5, axis: Y)))
            put(Prim.superellipsoid(V3(2.6, 2.4, 2.4), exponent: 3, subdivisions: hi ? 6 : 3, material: rock,
                                    bulge: { d in 1 + 0.1 * cos(d.y * 6) * sin(d.x * 4) }), "body",
                Xform(translation: V3(5.6, Self.groundY(5.6, 3.2) + 1.9, 3.4), rotation: simd_quatf(angle: -0.4, axis: Y)))

            // Three trees: bark trunk plus leaf-card crown over a dense inner lobe.
            var rng = rng0
            let trees: [(x: Float, z: Float, h: Float, r: Float)] = [(-2.4, 3.8, 9.5, 0.5), (2.2, -1.5, 7.6, 0.42), (-1.2, -6.2, 6.4, 0.38)]
            var crown = Surface(material: leaf), darkCrown = Surface(material: "leaf.plain:243E16")
            for (i, tr) in trees.enumerated() {
                let base = V3(tr.x, Self.groundY(tr.x, tr.z) - 0.2, tr.z)
                let lean = V3(Float(i - 1) * 0.5, 0, 0.4)
                put(Self.trunk(base, height: tr.h, lean: lean, radius: tr.r, stations: hi ? 12 : 5, sides: hi ? 32 : 10, bark), "body")
                let top = base + V3(0, tr.h, 0) + lean
                let cr = tr.h * 0.38
                put(Prim.superellipsoid(V3(cr * 1.6, cr * 1.1, cr * 1.6), exponent: 2, subdivisions: hi ? 5 : 2, material: "leaf.plain:243E16"), "body",
                    Xform(translation: top + V3(0, cr * 0.25, 0)))
                for _ in 0..<(hi ? 34 : 12) {
                    let d = V3(rng.float(-1...1), rng.float(-0.5...1), rng.float(-1...1))
                    let p = top + V3(0, cr * 0.25, 0) + simd_normalize(d + V3(0, 0.001, 0)) * cr * rng.float(0.65...0.95)
                    let sz = rng.float(2.0...3.2)
                    var c = Prim.card(width: sz, height: sz, cell: (V2(0, 0), V2(1, 1)), material: leaf, extra: V2(1, 0))
                    let q = simd_quatf(angle: atan2(d.x, d.z) + rng.float(-0.6...0.6), axis: Y) * simd_quatf(angle: rng.float(-0.9...0.4), axis: X)
                    c = c.transformed(Xform(translation: p, rotation: q))
                    if rng.chance(0.3) { darkCrown.append(c) } else { crown.append(c) }
                }
            }
            put(crown, "body")
            put(darkCrown, "body")

            // Barnacle clusters around the waterline and low flanks.
            var barn = Surface(material: barnacle)
            for _ in 0..<(hi ? 46 : 14) {
                let z = rng.float(-12...12)
                let side: Float = rng.chance(0.5) ? 1 : -1
                let a = rng.float(-0.35...0.55)
                let f = Self.shellF(z)
                let p = V3(side * Self.halfWidth * f * cos(a) * 0.98, Self.domeTop * f * sin(a) * (a > 0 ? 1 : 0.57), z)
                let r = rng.float(0.25...0.6)
                let b = Prim.superellipsoid(V3(r * 2, r * 1.4, r * 2), exponent: 2.4, subdivisions: 2, material: barnacle)
                barn.append(b, Xform(translation: p, rotation: simd_quatf(angle: rng.float(0...6.28), axis: Y)))
            }
            put(barn, "body")

            // Tail.
            var tp: [V3] = [], tr: [Float] = []
            for i in 0..<(hi ? 12 : 5) {
                let t = Float(i) / Float(hi ? 11 : 4)
                tp.append(V3(0, 0.2 - 0.8 * t, -13.5 - 5.5 * t))
                tr.append(1.5 * pow(1 - t, 0.8) + 0.12)
            }
            put(Prim.tube(tp, radii: tr, sides: hi ? 32 : 10, seamTile: 0.6, material: skin, capEnd: true), "body")

            // Neck and head ride the neck slide and head yaw.
            put(Prim.loft(Self.neckRings(stations: hi ? 16 : 6, radial: hi ? 48 : 16), capStart: true, material: skin), "neckSlide")
            put(Prim.loft(Self.headRings(stations: hi ? 28 : 10, radial: hi ? 56 : 20), capEnd: true, material: skin), "headYaw")
            for s: Float in [1, -1] {
                let n = s > 0 ? "R" : "L"
                let e = V3(Self.eyePos.x * s, Self.eyePos.y, Self.eyePos.z)
                put(Prim.superellipsoid(V3(1.15, 1.15, 1.15), exponent: 2, subdivisions: hi ? 8 : 3, material: eye), "headYaw", Xform(translation: e))
                // Lid slab sits on the eye in the closed pose, joint offset rotates it open.
                put(Prim.superellipsoid(V3(0.34, 1.55, 1.55), exponent: 2, subdivisions: hi ? 6 : 3, material: skin), "lid" + n,
                    Xform(translation: e + V3(0.3 * s, 0, 0)))
            }

            // Flippers.
            for s: Float in [1, -1] {
                let n = s > 0 ? "R" : "L"
                let sh = V3(frontShoulder.x * s, frontShoulder.y, frontShoulder.z)
                put(Prim.loft(Self.flipperRings(shoulder: sh, length: frontLen, chord: 3.4, thick: 0.9, sweep: 3.4, droop: 1.6, side: s,
                                                t0: 0, t1: tipT, stations: hi ? 10 : 4, radial: hi ? 40 : 14), capStart: true, material: skin), "fFlip" + n)
                put(Prim.loft(Self.flipperRings(shoulder: sh, length: frontLen, chord: 3.4, thick: 0.9, sweep: 3.4, droop: 1.6, side: s,
                                                t0: tipT, t1: 1, stations: hi ? 12 : 4, radial: hi ? 40 : 14), capEnd: true, material: skin), "fTip" + n)
                let hs = V3(hindShoulder.x * s, hindShoulder.y, hindShoulder.z)
                put(Prim.loft(Self.flipperRings(shoulder: hs, length: hindLen, chord: 1.7, thick: 0.6, sweep: -2.2, droop: 0.4, side: s,
                                                t0: 0, t1: 1, stations: hi ? 12 : 4, radial: hi ? 32 : 12), capStart: true, capEnd: true, material: skin), "hFlip" + n)
            }
        }

        rig.states = [
            RigState("island"),
            RigState("surfaced", ["rise": 1, "neck": 1]),
            RigState("look-left", ["rise": 1, "neck": 1, "head": -1]),
            RigState("look-right", ["rise": 1, "neck": 1, "head": 1]),
            RigState("blink", ["rise": 1, "neck": 1, "blink": 1]),
            RigState("stroke-up", ["neck": 1, "swim": 1]),
            RigState("stroke-down", ["neck": 1, "swim": -1]),
        ]
        return rig
    }
}
