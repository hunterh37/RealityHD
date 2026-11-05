import simd
import Foundation

/// Trophy hunter armor kit, human scale (helmet 0.30 m, chest 0.38 m wide, forearm 0.27 m). Dark parkerized and
/// blued plates with bronze trim: a mandible battle mask with four hinged mandible plates and dreadlock tubes, a
/// shoulder plasma caster on the right shoulder, retractable twin wrist blades in sheaths on both gauntlets, a
/// netted mesh chest under pectoral and abdomen plates, a spine back plate with power cells, and inlay strips that
/// glow when the cloak is on. Origin at the neck base with the kit assembled on a 1.75 m body, face toward +Z,
/// up +Y, character left = +X. 2 LODs.
///
/// Kit parts (own pivots, geometry in assembled coordinates): `helmet` (neck base), `chest` (sternum), `back`
/// (between the shoulder blades), `shoulderL`, `shoulderR` (shoulder joints), `gauntletL`, `gauntletR` (elbows,
/// forearm along -Y, hand at 0.27 m).
///
/// Articulation: `mandibles` 0...1 opens the four mandible plates, `caster` -1...1 yaws the shoulder caster 40
/// degrees each way, `blades` 0...1 slides the four wrist blades 0.42 m out of the sheaths, `cloak` 0...1 swaps
/// the dormant inlay strips for emissive ones and turns on the cloak light.
public struct HunterArmor: RealArticulated {
    public static let id = "hunter-armor"
    public static let summary = "Human-scale trophy hunter armor kit: mandible battle mask, shoulder plasma caster, wrist blades, netted mesh chest and cloak shimmer inlays."
    public static let tags = ["prop", "metal", "leather", "fantasy", "articulated"]
    public static let budget = 20_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 1.3)

    /// Main plates.
    public var plateMetal: MaterialKey = "metal.parkerized"
    /// Mask shell, shoulder lames and gauntlet shells.
    public var shellMetal: MaterialKey = "metal.blued-steel"
    /// Mandibles, trim, collars and rivets.
    public var trim: MaterialKey = "metal.bronze-weathered"
    /// Seams, frames and sheaths.
    public var iron: MaterialKey = "metal.iron"
    /// Blades.
    public var blade: MaterialKey = "metal.steel"
    /// Dreadlock tubes and straps.
    public var leather: MaterialKey = "leather.black"
    /// Chest mesh.
    public var net: MaterialKey = "fabric.mesh"
    /// Eye lenses and plasma core.
    public var glow: MaterialKey = "emissive.led-green"
    /// Laser sight lenses.
    public var laser: MaterialKey = "emissive.led-red"
    public init() {}

    static let neckY: Float = 0
    static let bladeTravel: Float = 0.42
    static let casterAim: Float = 40

    typealias Pts = [V3]

    // MARK: Helpers

    func mx(_ v: V3, _ side: Float) -> V3 { V3(v.x * side, v.y, v.z) }

    func finish(_ s: inout Surface) { s.recomputeNormals(weldSeams: false); s.computeTangents() }

    /// Beveled shell plate: a curved grid (edges clustered and rolled down by `bevel`, `curl` bends the width
    /// away from the normal, `taper` scales the width at the top and bottom) with a back skin and a rim strip.
    /// `n` is the outward normal, `u` the width direction, up in the plate is n x u.
    func plate(_ o: V3, n: V3, u: V3, w: Float, h: Float, bulge: Float = 0.006, curl: Float = 0, bevel: Float = 0.004,
               thick: Float = 0.006, taper: V2 = V2(1, 1), nu: Int = 8, nv: Int = 6, _ mat: MaterialKey) -> Surface {
        let nn = simd_normalize(n)
        let uu = simd_normalize(u - nn * simd_dot(u, nn))
        let vv = simd_cross(nn, uu)
        func cl(_ i: Int, _ n: Int) -> Float { 0.5 - 0.5 * cos(Float.pi * Float(i) / Float(n)) }
        func pt(_ i: Int, _ j: Int, back: Bool) -> V3 {
            let a = cl(i, nu), b = cl(j, nv)
            let x = (a - 0.5) * w * (taper.y + (taper.x - taper.y) * b)
            let y = (b - 0.5) * h
            let dome = bulge * (1 - pow(2 * a - 1, 2)) * (1 - pow(2 * b - 1, 2))
            var lift = dome - curl * x * x
            if back { lift -= thick } else {
                let rim = i == 0 || i == nu || j == 0 || j == nv
                let sub = i == 1 || i == nu - 1 || j == 1 || j == nv - 1
                lift -= rim ? bevel : (sub ? bevel * 0.25 : 0)
            }
            return o + uu * x + vv * y + nn * lift
        }
        var s = Surface(material: mat)
        let cols = nv + 1
        for back in [false, true] {
            for i in 0...nu { for j in 0...nv {
                let p = pt(i, j, back: back)
                s.add(p, back ? -nn : nn, V2(simd_dot(p - o, uu) * 3, simd_dot(p - o, vv) * 3))
            }}
        }
        let off = UInt32((nu + 1) * cols)
        func id(_ i: Int, _ j: Int) -> UInt32 { UInt32(i * cols + j) }
        for i in 0..<nu { for j in 0..<nv {
            s.quad(id(i, j), id(i + 1, j), id(i + 1, j + 1), id(i, j + 1))
            s.quad(off + id(i, j), off + id(i, j + 1), off + id(i + 1, j + 1), off + id(i + 1, j))
        }}
        var ring: [(Int, Int)] = []
        for i in 0..<nu { ring.append((i, 0)) }
        for j in 0..<nv { ring.append((nu, j)) }
        for i in stride(from: nu, to: 0, by: -1) { ring.append((i, nv)) }
        for j in stride(from: nv, to: 0, by: -1) { ring.append((0, j)) }
        for k in ring.indices {
            let a = ring[k], b = ring[(k + 1) % ring.count]
            s.quad(id(a.0, a.1), off + id(a.0, a.1), off + id(b.0, b.1), id(b.0, b.1))
        }
        finish(&s)
        return s
    }

    func rivet(_ p: V3, _ n: V3, _ r: Float = 0.0045) -> (Surface, Xform) {
        let s = Prim.lathe([V2(r, 0), V2(r * 0.92, r * 0.55), V2(0.001, r)], segments: 8, seamTile: 0.05, material: trim)
        return (s, Xform(translation: p, rotation: simd_quatf(from: V3(0, 1, 0), to: simd_normalize(n))))
    }

    /// Closed outline in the ring plane (x, then -z); front (+Z) bulges by `front`.
    func outline(_ rx: Float, _ rz: Float, _ n: Int, front: Float = 0) -> [V2] {
        (0..<n).map { k in
            let a = 2 * Float.pi * Float(k) / Float(n)
            var y = rz * sin(a)
            if y < 0 { y *= 1 + front * pow(-sin(a), 2) }
            return V2(rx * cos(a), y)
        }
    }

    func thin(_ path: Pts, _ r: Float, sides: Int, _ mat: MaterialKey, caps: Bool = true) -> Surface {
        Prim.tube(path, radii: path.map { _ in r }, sides: sides, seamTile: 0.02, material: mat, capEnd: caps)
    }

    // MARK: Body ellipses

    func torsoHalfWidth(_ t: Float) -> Float { 0.185 - 0.045 * smoothstep(0.25, 1, t) }
    func torsoHalfDepth(_ t: Float) -> Float { 0.105 - 0.02 * t }
    func torsoY(_ t: Float) -> Float { -0.06 - 0.36 * t }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [3])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)

        // Drivers first so mimics resolve.
        _ = rig.part("mandibles", pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.9))
        _ = rig.part("caster", pivot: .zero, joint: .hinge(axis: Y, -1...1, duration: 0.5))
        _ = rig.part("blades", pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.35))
        _ = rig.part("cloak", pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 1.4))

        // Kit parts.
        let fixed = Joint(.fixed)
        _ = rig.part("helmet", pivot: V3(0, 0, 0), joint: fixed)
        _ = rig.part("chest", pivot: V3(0, -0.17, 0.04), joint: fixed)
        _ = rig.part("back", pivot: V3(0, -0.17, -0.09), joint: fixed)
        _ = rig.part("shoulderL", pivot: V3(0.20, -0.05, 0), joint: fixed)
        _ = rig.part("shoulderR", pivot: V3(-0.20, -0.05, 0), joint: fixed)
        _ = rig.part("gauntletL", pivot: V3(0.30, -0.33, 0), joint: fixed)
        _ = rig.part("gauntletR", pivot: V3(-0.30, -0.33, 0), joint: fixed)

        // Mandible plates: inner pair and outer pair, hinged about Y at the mouth corners.
        let mandHinge: [(String, Float, Float, Float)] = [("mandIL", 1, 0.030, 24), ("mandIR", -1, 0.030, 24), ("mandOL", 1, 0.058, 44), ("mandOR", -1, 0.058, 44)]
        for m in mandHinge {
            _ = rig.part(m.0, parent: "helmet", pivot: V3(m.1 * m.2, 0.045, 0.105),
                         joint: Joint(.revolute, axis: Y, range: -70...70, mimic: .init("mandibles", ratio: m.1 * m.3)))
        }
        let casterPivot = V3(-0.27, 0.06, 0.02)
        _ = rig.part("casterYaw", parent: "shoulderR", pivot: casterPivot,
                     joint: Joint(.revolute, axis: Y, range: -Self.casterAim...Self.casterAim, mimic: .init("caster", ratio: Self.casterAim)))
        let bladePivots: [(String, String, Float, Float)] = [("bladeLa", "gauntletL", 1, 0.016), ("bladeLb", "gauntletL", 1, -0.016),
                                                             ("bladeRa", "gauntletR", -1, 0.016), ("bladeRb", "gauntletR", -1, -0.016)]
        for b in bladePivots {
            _ = rig.part(b.0, parent: b.1, pivot: V3(b.2 * 0.362, -0.37, b.3),
                         joint: Joint(.prismatic, axis: V3(0, -1, 0), range: 0...Self.bladeTravel, mimic: .init("blades", ratio: Self.bladeTravel)))
        }
        _ = rig.part("shimmer", pivot: .zero, joint: fixed, options: 2)
        rig.optionLinks = [RigOptionLink(part: "shimmer", joint: "cloak", thresholds: [0.3])]

        for l in 0..<2 {
            let hi = l == 0
            let sides = hi ? 12 : 6
            func add(_ s: Surface, _ part: String, _ x: Xform = .identity) { rig.add(s, x, to: part, lods: l...l) }
            func rivets(_ pts: [(V3, V3)], _ part: String) {
                guard hi else { return }
                for p in pts { let r = rivet(p.0, p.1); add(r.0, part, r.1) }
            }

            // MARK: Helmet (battle mask)
            do {
                let rings = hi ? 26 : 12, seg = hi ? 64 : 24
                var rs: [[V3]] = []
                for i in 0...rings {
                    let t = Float(i) / Float(rings)
                    let dome = sqrt(max(0, 1 - pow(max(0, (t - 0.55) / 0.45), 2.2)))
                    let r = (0.060 + 0.030 * smoothstep(0, 0.35, t)) * max(dome, 0.02)
                    let rz = (0.074 + 0.036 * smoothstep(0, 0.4, t)) * max(dome, 0.02)
                    rs.append(Prim.ring(outline(r, rz, seg, front: 0.35 * (1 - smoothstep(0.45, 0.85, t))), y: 0.02 + 0.28 * t, offset: V3(0, 0, -0.012)))
                }
                var shell = Prim.loft(rs, capStart: false, capEnd: true, material: shellMetal)
                finish(&shell)
                add(shell, "helmet")
                // Forehead crest, brow ridge and face plates.
                add(plate(V3(0, 0.255, 0.075), n: V3(0, 0.35, 1), u: X, w: 0.11, h: 0.075, bulge: 0.012, curl: 2.4, nu: hi ? 10 : 5, nv: hi ? 8 : 4, plateMetal), "helmet")
                add(plate(V3(0, 0.205, 0.108), n: V3(0, 0.1, 1), u: X, w: 0.15, h: 0.03, bulge: 0.012, curl: 3.2, bevel: 0.006, nu: hi ? 12 : 6, nv: 3, trim), "helmet")
                for s: Float in [1, -1] {
                    add(plate(V3(s * 0.062, 0.150, 0.092), n: V3(s * 0.55, 0, 1), u: V3(1, 0, -s * 0.55), w: 0.060, h: 0.09, bulge: 0.008, curl: 1.8, taper: V2(1, 0.7), nu: hi ? 7 : 4, nv: hi ? 8 : 4, plateMetal), "helmet")
                    add(plate(V3(s * 0.088, 0.115, 0.012), n: V3(s, 0, 0.1), u: Z, w: 0.12, h: 0.13, bulge: 0.01, curl: 4, nu: hi ? 8 : 4, nv: hi ? 8 : 4, plateMetal), "helmet")
                    // Eye lenses in bronze bezels.
                    let e = V3(s * 0.034, 0.188, 0.103)
                    add(Prim.lathe([V2(0.001, 0), V2(0.018, 0.001), V2(0.016, 0.01), V2(0.001, 0.013)], segments: hi ? 24 : 10, seamTile: 0.05, material: glow),
                        "helmet", Xform(translation: e, rotation: simd_quatf(from: Y, to: simd_normalize(V3(0, 0.1, 1)))))
                    add(Prim.torus(major: 0.021, minor: 0.0045, segments: hi ? 32 : 12, sides: hi ? 10 : 5, material: trim), "helmet",
                        Xform(translation: e + V3(0, 0, 0.003), rotation: simd_quatf(from: Y, to: simd_normalize(V3(0, 0.1, 1)))))
                    // Breather tubes from the jaw to the neck.
                    add(Prim.tube(catmull([V3(s * 0.045, 0.06, 0.092), V3(s * 0.075, 0.03, 0.06), V3(s * 0.085, -0.01, 0.02), V3(s * 0.07, -0.05, 0.0)], per: hi ? 4 : 2),
                                  radii: Array(repeating: 0.0075, count: hi ? 13 : 7), sides: sides, seamTile: 0.03, material: iron, capEnd: true), "helmet")
                }
                // Mouth grille: vertical slats in a frame.
                add(plate(V3(0, 0.070, 0.116), n: V3(0, 0, 1), u: X, w: 0.07, h: 0.05, bulge: 0.004, curl: 2, bevel: 0.004, nu: hi ? 8 : 4, nv: 4, iron), "helmet")
                if hi { for k in -3...3 { add(thin([V3(Float(k) * 0.009, 0.048, 0.121), V3(Float(k) * 0.009, 0.092, 0.121)], 0.0018, sides: 6, trim), "helmet") } }
                // Dreadlock tubes hang from the back of the skull, banded with bronze rings.
                let locks = hi ? 11 : 5
                for k in 0..<locks {
                    let a = (Float(k) / Float(locks - 1) - 0.5) * 2.2
                    let base = V3(0.075 * sin(a), 0.19 - 0.02 * abs(a), -0.075 * cos(a) - 0.012)
                    let sway = rng.float() * 0.02
                    let path = catmull([base, base + V3(0.03 * sin(a), -0.07, -0.03 * cos(a)), base + V3(0.05 * sin(a) + sway, -0.18, -0.045 * cos(a) - 0.02),
                                        base + V3(0.06 * sin(a), -0.30, -0.05 * cos(a) - 0.03)], per: hi ? 4 : 2)
                    let radii = path.indices.map { 0.0085 - 0.0035 * Float($0) / Float(path.count - 1) }
                    add(Prim.tube(path, radii: radii, sides: hi ? 8 : 5, seamTile: 0.03, material: leather, capEnd: true), "helmet")
                    if hi { for q in [0.25, 0.6] as [Float] {
                        let i = Int(q * Float(path.count - 1))
                        add(Prim.torus(major: radii[i] + 0.0012, minor: 0.0018, segments: 10, sides: 5, material: trim), "helmet",
                            Xform(translation: path[i], rotation: simd_quatf(from: Y, to: simd_normalize(path[i + 1] - path[i]))))
                    }}
                }
                rivets([(V3(0.040, 0.215, 0.108), V3(0, 0.2, 1)), (V3(-0.040, 0.215, 0.108), V3(0, 0.2, 1)), (V3(0.0, 0.283, 0.082), V3(0, 1, 0.4)),
                        (V3(0.09, 0.17, 0.05), V3(1, 0, 0.3)), (V3(-0.09, 0.17, 0.05), V3(-1, 0, 0.3))], "helmet")
            }

            // MARK: Mandible plates
            for m in mandHinge {
                let s = m.1, x0 = m.2, outer = m.2 > 0.04
                let len: Float = outer ? 0.115 : 0.095
                let base = V3(s * x0, 0.045, 0.105)
                let path = catmull([base, base + V3(s * 0.004, -0.012, 0.03), base + V3(s * 0.002, -0.032, len * 0.7), base + V3(-s * 0.004, -0.050, len)], per: hi ? 4 : 2)
                let radii = path.indices.map { (outer ? 0.0125 : 0.010) * (1 - 0.82 * pow(Float($0) / Float(path.count - 1), 1.3)) + 0.0015 }
                add(Prim.tube(path, radii: radii, sides: hi ? 14 : 6, seamTile: 0.03, material: trim, capEnd: true), m.0)
                add(Prim.lathe([V2(0.014, 0), V2(0.013, 0.01), V2(0.001, 0.014)], segments: hi ? 14 : 6, seamTile: 0.03, material: plateMetal), m.0,
                    Xform(translation: base + V3(0, 0, -0.004), rotation: simd_quatf(from: Y, to: V3(0, 0, -1))))
                if hi {
                    let mid = path[path.count / 2], dir = simd_normalize(path[path.count / 2 + 1] - mid)
                    add(plate(mid + V3(s * 0.011, 0.002, 0), n: V3(s, 0.1, 0), u: dir, w: 0.05, h: 0.013, bulge: 0.003, thick: 0.003, bevel: 0.002, nu: 6, nv: 3, plateMetal), m.0)
                }
            }

            // MARK: Chest: mesh shell, lattice, plates
            do {
                let rings = hi ? 14 : 6, seg = hi ? 48 : 20
                let rs = (0...rings).map { i -> [V3] in
                    let t = Float(i) / Float(rings)
                    return Prim.ring(outline(torsoHalfWidth(t), torsoHalfDepth(t), seg), y: torsoY(t))
                }
                var shell = Prim.loft(rs, capStart: false, capEnd: false, material: net)
                finish(&shell)
                add(shell, "chest")
                // Diagonal lattice over the front, two directions.
                let strands = hi ? 9 : 5, pts = hi ? 12 : 6
                for dir: Float in [1, -1] {
                    for k in 0..<strands {
                        let p0 = (Float(k) / Float(strands - 1) - 0.5) * 3.0 - dir * 0.7
                        var path: Pts = []
                        for i in 0..<pts {
                            let t = Float(i) / Float(pts - 1)
                            let phi = max(-1.55, min(1.55, p0 + dir * 1.4 * t))
                            path.append(V3(torsoHalfWidth(t) * 1.015 * sin(phi), torsoY(t), torsoHalfDepth(t) * 1.015 * cos(phi)))
                        }
                        add(thin(path, 0.0034, sides: hi ? 6 : 4, iron, caps: true), "chest")
                    }
                }
                // Plates: pectorals, sternum, abdomen segments, collar ring.
                for s: Float in [1, -1] {
                    add(plate(V3(s * 0.092, -0.115, 0.098), n: V3(s * 0.25, 0.1, 1), u: V3(1, 0, -s * 0.25), w: 0.155, h: 0.12, bulge: 0.016, curl: 2.4, taper: V2(1, 0.85), nu: hi ? 10 : 5, nv: hi ? 8 : 4, plateMetal), "chest")
                    add(plate(V3(s * 0.15, -0.045, 0.045), n: V3(s * 0.2, 1, 0.5), u: V3(0.5, 0, -s), w: 0.12, h: 0.04, bulge: 0.01, curl: 3, nu: hi ? 8 : 4, nv: 3, shellMetal), "chest")
                }
                add(plate(V3(0, -0.12, 0.104), n: V3(0, 0, 1), u: X, w: 0.04, h: 0.14, bulge: 0.012, curl: 6, taper: V2(1, 0.7), nu: hi ? 5 : 3, nv: hi ? 8 : 4, trim), "chest")
                for k in 0..<3 {
                    let y = -0.215 - Float(k) * 0.065
                    add(plate(V3(0, y, 0.088 - 0.006 * Float(k)), n: V3(0, 0.08, 1), u: X, w: 0.22 - 0.025 * Float(k), h: 0.058, bulge: 0.010, curl: 3.5, bevel: 0.005, nu: hi ? 12 : 6, nv: hi ? 5 : 3, k % 2 == 0 ? plateMetal : shellMetal), "chest")
                }
                add(Prim.torus(major: 0.085, minor: 0.012, segments: hi ? 48 : 16, sides: hi ? 12 : 6, material: shellMetal), "chest", Xform(translation: V3(0, -0.035, 0.0), scale: V3(1.15, 1, 0.9)))
                // Plate seams and belt straps.
                add(thin([V3(0, -0.05, 0.1055), V3(0, -0.40, 0.088)], 0.0022, sides: 6, iron), "chest")
                for k in 0..<3 {
                    let y = -0.19 - Float(k) * 0.065
                    add(thin([V3(-0.10, y, 0.098), V3(0, y, 0.101), V3(0.10, y, 0.098)], 0.0022, sides: 6, iron), "chest")
                }
                add(thin(catmull([V3(-0.19, -0.05, 0.0), V3(-0.14, -0.06, 0.098), V3(0.14, -0.06, 0.098), V3(0.19, -0.05, 0.0)], per: hi ? 4 : 2), 0.006, sides: 8, leather), "chest")
                rivets([(V3(0.150, -0.150, 0.104), V3(0.2, 0.1, 1)), (V3(-0.150, -0.150, 0.104), V3(-0.2, 0.1, 1)), (V3(0.05, -0.085, 0.118), V3(0, 0, 1)),
                        (V3(-0.05, -0.085, 0.118), V3(0, 0, 1)), (V3(0.085, -0.255, 0.093), V3(0, 0.1, 1)), (V3(-0.085, -0.255, 0.093), V3(0, 0.1, 1))], "chest")
            }

            // MARK: Back plate
            do {
                add(plate(V3(0, -0.15, -0.098), n: V3(0, 0, -1), u: -X, w: 0.26, h: 0.26, bulge: 0.012, curl: 2.6, taper: V2(1, 0.7), nu: hi ? 12 : 6, nv: hi ? 10 : 5, plateMetal), "back")
                let spine = (0..<(hi ? 9 : 4)).map { V3(0, -0.06 - 0.03 * Float($0) * (hi ? 1 : 2.2), -0.112) }
                for p in spine { add(Prim.lathe([V2(0.001, -0.008), V2(0.016, -0.004), V2(0.014, 0.008), V2(0.001, 0.010)], segments: hi ? 14 : 6, seamTile: 0.05, material: trim), "back", Xform(translation: p)) }
                for s: Float in [1, -1] {
                    // Power cells.
                    add(Prim.cylinder(radius: 0.026, height: 0.17, bevel: 0.005, segments: hi ? 32 : 10, material: shellMetal), "back", Xform(translation: V3(s * 0.085, -0.28, -0.124)))
                    add(Prim.torus(major: 0.027, minor: 0.004, segments: hi ? 24 : 10, sides: 6, material: trim), "back", Xform(translation: V3(s * 0.085, -0.15, -0.124)))
                    add(Prim.lathe([V2(0.001, 0), V2(0.018, 0), V2(0.018, 0.004), V2(0.001, 0.004)], segments: hi ? 20 : 8, seamTile: 0.05, material: glow), "back",
                        Xform(translation: V3(s * 0.085, -0.19, -0.1495), rotation: simd_quatf(from: Y, to: V3(0, 0, -1))))
                }
                add(thin(catmull([V3(-0.085, -0.28, -0.14), V3(-0.04, -0.34, -0.13), V3(0.04, -0.34, -0.13), V3(0.085, -0.28, -0.14)], per: hi ? 4 : 2), 0.007, sides: 8, leather), "back")
            }

            // MARK: Shoulders and the plasma caster
            for s: Float in [1, -1] {
                let part = s > 0 ? "shoulderL" : "shoulderR"
                for k in 0..<3 {
                    let kf = Float(k)
                    add(plate(V3(s * (0.235 - 0.012 * kf), 0.0 - 0.04 * kf, 0.0), n: V3(s * 0.75, 0.65 - 0.1 * kf, 0), u: Z, w: 0.18 - 0.012 * kf, h: 0.085, bulge: 0.012, curl: 2.8, bevel: 0.005,
                              nu: hi ? 10 : 5, nv: hi ? 6 : 3, k == 0 ? shellMetal : plateMetal), part)
                }
                add(Prim.torus(major: 0.055, minor: 0.008, segments: hi ? 40 : 14, sides: hi ? 10 : 5, material: trim), part, Xform(translation: V3(s * 0.20, -0.075, 0.0), rotation: simd_quatf(angle: 0.25 * s, axis: Z), scale: V3(1, 1, 1)))
                rivets([(V3(s * 0.255, 0.012, 0.05), V3(s, 0.6, 0.3)), (V3(s * 0.255, 0.012, -0.05), V3(s, 0.6, -0.3))], part)
            }
            // Caster: mount ring on the right shoulder plus a yawing housing, barrel and sight lenses.
            do {
                add(Prim.cylinder(radius: 0.040, height: 0.018, bevel: 0.004, segments: hi ? 40 : 12, material: trim), "shoulderR", Xform(translation: casterPivot + V3(0, -0.012, 0)))
                let c = casterPivot
                add(plate(c + V3(0, 0.03, 0), n: Y, u: X, w: 0.07, h: 0.075, bulge: 0.012, curl: 6, bevel: 0.006, thick: 0.014, nu: hi ? 8 : 4, nv: hi ? 8 : 4, shellMetal), "casterYaw")
                add(Prim.tube([c + V3(0, 0.03, -0.03), c + V3(0, 0.03, 0.04), c + V3(0, 0.03, 0.10), c + V3(0, 0.03, 0.125)], radii: [0.027, 0.024, 0.019, 0.021], sides: hi ? 28 : 10, seamTile: 0.03, material: plateMetal, capEnd: true), "casterYaw")
                for z: Float in [0.02, 0.07, 0.115] {
                    add(Prim.torus(major: 0.025 - 0.0018 * (z / 0.05), minor: 0.0045, segments: hi ? 32 : 12, sides: hi ? 8 : 5, material: trim), "casterYaw",
                        Xform(translation: c + V3(0, 0.03, z), rotation: simd_quatf(from: Y, to: Z)))
                }
                add(Prim.lathe([V2(0.001, 0), V2(0.015, 0), V2(0.014, 0.004), V2(0.001, 0.007)], segments: hi ? 28 : 10, seamTile: 0.05, material: glow), "casterYaw",
                    Xform(translation: c + V3(0, 0.03, 0.1255), rotation: simd_quatf(from: Y, to: Z)))
                for k in 0..<3 {
                    let a = Float(k) * 2 * .pi / 3 + .pi / 2
                    let q = c + V3(0.012 * cos(a), 0.03 + 0.012 * sin(a), 0.13)
                    add(Prim.lathe([V2(0.001, 0), V2(0.0035, 0), V2(0.003, 0.003), V2(0.001, 0.004)], segments: hi ? 10 : 6, seamTile: 0.05, material: laser), "casterYaw",
                        Xform(translation: q - V3(0, 0, 0.002), rotation: simd_quatf(from: Y, to: Z)))
                }
                add(thin(catmull([c + V3(0.02, 0.02, -0.03), c + V3(0.05, -0.02, -0.06), c + V3(0.08, -0.10, -0.05)], per: hi ? 4 : 2), 0.005, sides: 8, leather), "casterYaw")
            }

            // MARK: Gauntlets, sheaths and wrist blades
            for s: Float in [1, -1] {
                let part = s > 0 ? "gauntletL" : "gauntletR"
                let e = V3(s * 0.30, -0.33, 0)
                let rings = hi ? 12 : 5, seg = hi ? 40 : 16
                let rs = (0...rings).map { i -> [V3] in
                    let t = Float(i) / Float(rings)
                    let rx = 0.047 - 0.012 * t + 0.006 * sin(t * .pi), rz = 0.040 - 0.008 * t + 0.005 * sin(t * .pi)
                    return Prim.ring(outline(rx, rz, seg), y: e.y - 0.27 * t, offset: V3(e.x, 0, 0))
                }
                var shell = Prim.loft(rs, capStart: false, capEnd: true, material: shellMetal)
                finish(&shell)
                add(shell, part)
                // Outer plates, elbow cop and wrist cuff.
                add(plate(e + V3(s * 0.034, -0.12, 0.0), n: V3(s, 0, 0), u: Z, w: 0.085, h: 0.2, bulge: 0.012, curl: 4, taper: V2(0.7, 1), bevel: 0.005, nu: hi ? 8 : 4, nv: hi ? 12 : 5, plateMetal), part)
                add(plate(e + V3(0, -0.10, 0.034), n: V3(0, 0, 1), u: X, w: 0.07, h: 0.17, bulge: 0.008, curl: 4, taper: V2(1, 0.7), nu: hi ? 6 : 3, nv: hi ? 10 : 4, plateMetal), part)
                add(Prim.lathe([V2(0.001, 0), V2(0.058, 0.0), V2(0.062, 0.02), V2(0.05, 0.04), V2(0.001, 0.044)], segments: hi ? 40 : 14, seamTile: 0.05, material: trim), part,
                    Xform(translation: e + V3(0, 0.025, 0), scale: V3(1, 1, 0.85)))
                add(Prim.torus(major: 0.043, minor: 0.008, segments: hi ? 40 : 14, sides: hi ? 10 : 5, material: trim), part, Xform(translation: e + V3(0, -0.255, 0), scale: V3(1, 1, 0.88)))
                // Twin sheath rails on the outer face; the blades slide between them.
                for z: Float in [0.030, -0.030] {
                    add(thin([e + V3(s * 0.036, -0.03, z), e + V3(s * 0.040, -0.14, z * 1.05), e + V3(s * 0.036, -0.25, z)], 0.005, sides: hi ? 8 : 5, iron), part)
                }
                add(plate(e + V3(s * 0.050, -0.14, 0), n: V3(s, 0, 0), u: Z, w: 0.06, h: 0.19, bulge: 0.005, curl: 4, bevel: 0.003, nu: hi ? 6 : 3, nv: hi ? 8 : 4, iron), part)
                // Wrist pad, seam and glove strap.
                add(plate(e + V3(-s * 0.010, -0.215, -0.040), n: V3(0, 0, -1), u: X, w: 0.07, h: 0.07, bulge: 0.008, curl: 5, nu: hi ? 6 : 3, nv: hi ? 5 : 3, trim), part)
                add(thin([e + V3(s * 0.034, -0.02, 0.0), e + V3(s * 0.036, -0.14, 0.0), e + V3(s * 0.032, -0.26, 0.0)], 0.0022, sides: 6, iron), part)
                add(Prim.torus(major: 0.043, minor: 0.0045, segments: hi ? 36 : 12, sides: 6, material: leather), part, Xform(translation: e + V3(0, -0.16, 0), scale: V3(1, 1, 0.85)))
                rivets([(e + V3(s * 0.0775, -0.06, 0.03), V3(s, 0, 0.2)), (e + V3(s * 0.0775, -0.06, -0.03), V3(s, 0, -0.2)), (e + V3(s * 0.0775, -0.20, 0.03), V3(s, 0, 0.2)),
                        (e + V3(s * 0.0775, -0.20, -0.03), V3(s, 0, -0.2))], part)
                // Blades.
                let names = s > 0 ? ["bladeLa", "bladeLb"] : ["bladeRa", "bladeRb"]
                for (idx, name) in names.enumerated() {
                    let z: Float = idx == 0 ? 0.016 : -0.016
                    let x = e.x + s * 0.062
                    let ys = hi ? 10 : 5
                    let path = (0...ys).map { i in V3(x, e.y - 0.04 - 0.30 * Float(i) / Float(ys), z) }
                    // Diamond section tapering to the tip, with a spine ridge; the last scale is the point.
                    let scales = (0...ys).map { i -> Float in let t = Float(i) / Float(ys); return t < 0.7 ? 1 - 0.1 * t : 0.93 * (1 - pow((t - 0.7) / 0.3, 1.6)) + 0.03 }
                    let section: [V2] = [V2(-0.0125, 0), V2(-0.004, 0.0035), V2(0.004, 0.0035), V2(0.0125, 0), V2(0.004, -0.0035), V2(-0.004, -0.0035)]
                    var b = Prim.sweep(section, along: path, up: Z, scales: scales, caps: true, grainAlongPath: true, material: blade)
                    finish(&b)
                    add(b, name)
                    add(Prim.tube([V3(x, e.y - 0.035, z), V3(x, e.y - 0.05, z)], radii: [0.011, 0.011], sides: hi ? 12 : 6, seamTile: 0.03, material: trim, capEnd: true), name)
                    if hi {
                        for k in 0..<5 {
                            let y0 = e.y - 0.12 - Float(k) * 0.035
                            let tooth = [V3(x + s * 0.012, y0, z), V3(x + s * 0.020, y0 - 0.012, z), V3(x + s * 0.012, y0 - 0.026, z)]
                            add(Prim.tube(tooth, radii: [0.0030, 0.0020, 0.0006], sides: 5, seamTile: 0.01, material: blade, capEnd: true), name)
                        }
                    }
                }
            }

            // MARK: Cloak shimmer inlays: dormant (option 0) and emissive (option 1).
            do {
                func inlays(_ mat: MaterialKey, option: Int) {
                    var strips: [(Pts, String)] = []
                    for s: Float in [1, -1] {
                        strips.append((catmull([V3(s * 0.12, -0.075, 0.108), V3(s * 0.17, -0.12, 0.092), V3(s * 0.185, -0.16, 0.05)], per: hi ? 4 : 2), "chest"))
                        strips.append(([V3(s * 0.045, -0.20, 0.0916), V3(s * 0.04, -0.34, 0.0868)], "chest"))
                        let g = s > 0 ? "gauntletL" : "gauntletR"
                        strips.append(([V3(s * 0.30 + s * 0.0405, -0.36, 0.0), V3(s * 0.30 + s * 0.0435, -0.47, 0.0), V3(s * 0.30 + s * 0.0415, -0.58, 0.0)], g))
                        strips.append(([V3(s * 0.20 + s * 0.215, -0.045, 0.06), V3(s * 0.20 + s * 0.222, -0.045, 0.0), V3(s * 0.20 + s * 0.215, -0.045, -0.06)], s > 0 ? "shoulderL" : "shoulderR"))
                    }
                    strips.append(([V3(0, -0.09, -0.108), V3(0, -0.2, -0.113), V3(0, -0.32, -0.108)], "back"))
                    strips.append((catmull([V3(-0.07, 0.0, 0.1), V3(0, 0.014, 0.112), V3(0.07, 0.0, 0.1)], per: hi ? 4 : 2).map { $0 + V3(0, 0.10, 0.012) }, "helmet"))
                    for st in strips where st.0.count >= 2 {
                        rig.add(thin(st.0, 0.0024, sides: hi ? 6 : 4, mat), to: "shimmer", option: option, lods: l...l)
                    }
                }
                inlays(iron, option: 0)
                inlays(glow, option: 1)
            }
        }

        // Lights: eyes (always), caster lens (always), cloak shimmer (cloak on).
        rig.lights.append(RigLight(name: "eyes", part: "helmet", position: V3(0, 0.188, 0.14), color: V3(0.4, 1.0, 0.45), intensity: 120, attenuationRadius: 1.2))
        rig.lights.append(RigLight(name: "casterLens", part: "casterYaw", position: casterPivot + V3(0, 0.03, 0.15), color: V3(0.25, 1.0, 0.7), intensity: 260, attenuationRadius: 2.0))
        rig.lights.append(RigLight(name: "cloakGlow", part: "shimmer", option: 1, position: V3(0, -0.2, 0.2), color: V3(0.3, 1.0, 0.5), intensity: 300, attenuationRadius: 2.5))

        rig.states = [
            RigState("armed", ["mandibles": 0, "caster": 0, "blades": 0, "cloak": 0]),
            RigState("roar", ["mandibles": 1, "caster": 0, "blades": 0, "cloak": 0]),
            RigState("blades-out", ["mandibles": 0, "caster": 0, "blades": 1, "cloak": 0]),
            RigState("aim-left", ["mandibles": 0, "caster": 1, "blades": 0, "cloak": 0]),
            RigState("aim-right", ["mandibles": 0, "caster": -1, "blades": 0, "cloak": 0]),
            RigState("cloaked", ["mandibles": 0, "caster": 0, "blades": 0, "cloak": 1], options: ["shimmer": 1]),
            RigState("hunt", ["mandibles": 1, "caster": 0.5, "blades": 1, "cloak": 1], options: ["shimmer": 1]),
        ]
        return rig
    }
}
