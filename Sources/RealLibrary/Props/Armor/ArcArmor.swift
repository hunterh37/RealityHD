import simd
import Foundation

/// Arc armor kit: red and gold powered suit on a 1.75 m body, built as nine articulated pieces so a lens can reparent
/// each to a body joint. Skull and faceplate, chest and back plates (thick, rimmed, riveted, seamed), pauldrons with
/// hanging lames, forearm gauntlets with fingered hands and palm repulsors, greaves and boots with sole thrusters,
/// an emissive chest reactor ring and eye slits. Origin at the neck base with the kit assembled, face and chest toward +Z,
/// left = +X. 2 LODs.
///
/// Parts (pivot): `helmet` (neck base), `chest` (sternum), `back` (between shoulder blades), `shoulderL` `shoulderR`
/// (shoulder joint), `gauntletL` `gauntletR` (elbow, forearm along -Y, hand at 0.27 m), `bootL` `bootR` (ankle).
///
/// Joints (drivers 0...1): `faceplate` 1 opens the faceplate 70 degrees about the brow, `repulsor` pushes both palm
/// glow discs out of their housings, `reactor` (to 1.5) pushes the chest glow ring flush, `thruster` slides both
/// sole flame cones out of the boots.
public struct ArcArmor: RealArticulated {
    public static let id = "arc-armor"
    public static let summary = "Red and gold powered armor kit in nine articulated pieces: helmet with hinged faceplate, riveted chest and back plates, pauldrons, gauntlets with palm repulsors, boots, glowing arc reactor."
    public static let tags = ["prop", "armor", "costume", "scifi", "metal", "articulated"]
    public static let budget = 20_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 1.5)

    /// Painted armor plate (red).
    public var red: MaterialKey = "metal.painted:A3141A"
    /// Gold trim, faceplate, hands.
    public var gold: MaterialKey = "metal.gold"
    /// Panel seams and under-armor.
    public var iron: MaterialKey = "metal.iron"
    /// Thruster bells.
    public var titanium: MaterialKey = "metal.titanium"
    /// Glowing parts (reactor, eye slits, palm discs).
    public var glow: MaterialKey = "emissive.panel"
    /// Thruster flame.
    public var flame: MaterialKey = "emissive.indicator"
    public init() {}

    typealias Row = (y: Float, ru: Float, rv: Float, cz: Float)

    // MARK: Profiles (y up; ru = half width, rv = half depth, cz = depth centre)

    static let helmet: [Row] = [
        (0.000, 0.062, 0.070, 0.000), (0.030, 0.070, 0.080, 0.000), (0.070, 0.085, 0.098, 0.005),
        (0.120, 0.092, 0.108, 0.010), (0.170, 0.095, 0.112, 0.010), (0.220, 0.088, 0.105, 0.005),
        (0.260, 0.068, 0.082, 0.000), (0.285, 0.036, 0.045, 0.000), (0.292, 0.004, 0.006, 0.000),
    ]
    static let torso: [Row] = [
        (-0.040, 0.120, 0.075, 0.000), (-0.080, 0.185, 0.100, 0.010), (-0.140, 0.192, 0.112, 0.020),
        (-0.220, 0.178, 0.108, 0.025), (-0.300, 0.165, 0.100, 0.020), (-0.380, 0.158, 0.092, 0.012),
        (-0.460, 0.150, 0.085, 0.005),
    ]
    static let forearm: [Row] = [
        (0.035, 0.056, 0.060, 0.000), (0.000, 0.060, 0.064, 0.000), (-0.060, 0.064, 0.066, 0.004),
        (-0.130, 0.056, 0.058, 0.002), (-0.200, 0.046, 0.050, 0.000), (-0.250, 0.040, 0.044, 0.000),
        (-0.275, 0.037, 0.041, 0.000),
    ]
    static let pauldron: [Row] = [
        (0.000, 0.082, 0.090, 0), (0.012, 0.088, 0.097, 0), (0.035, 0.086, 0.095, 0), (0.060, 0.070, 0.078, 0),
        (0.080, 0.045, 0.050, 0), (0.092, 0.020, 0.022, 0), (0.098, 0.002, 0.002, 0),
    ]
    static let greave: [Row] = [
        (0.240, 0.055, 0.060, 0.000), (0.180, 0.056, 0.062, 0.004), (0.100, 0.052, 0.058, 0.010),
        (0.040, 0.050, 0.056, 0.012), (0.000, 0.048, 0.056, 0.010),
    ]
    /// Foot along its axis (y = distance from the ankle toward the toe); `cz` drops the centre so the sole sits at -0.075.
    static let foot: [Row] = {
        let r: [(Float, Float, Float)] = [(-0.075, 0.010, 0.010), (-0.060, 0.034, 0.034), (-0.020, 0.043, 0.040),
                                          (0.060, 0.046, 0.038), (0.140, 0.045, 0.030), (0.210, 0.037, 0.022), (0.245, 0.012, 0.012)]
        return r.map { (y: $0.0, ru: $0.1, rv: $0.2, cz: 0.075 - $0.2) }
    }()

    // MARK: Helpers

    static func lerpRow(_ t: [Row], _ y: Float) -> Row {
        let lo = t.first!.y < t.last!.y
        for i in 0..<(t.count - 1) {
            let a = t[i], b = t[i + 1]
            let inside = lo ? (y >= a.y && y <= b.y) : (y <= a.y && y >= b.y)
            if inside {
                let u = abs(b.y - a.y) < 1e-6 ? 0 : (y - a.y) / (b.y - a.y)
                return (y, a.ru + (b.ru - a.ru) * u, a.rv + (b.rv - a.rv) * u, a.cz + (b.cz - a.cz) * u)
            }
        }
        return y < min(t.first!.y, t.last!.y) ? (lo ? t.first! : t.last!) : (lo ? t.last! : t.first!)
    }
    /// Point on a superelliptic section at height `y`, angle `a` (0 = +X, pi/2 = +Z), pushed `off` along the radial.
    static func surf(_ t: [Row], _ y: Float, _ a: Float, e: Float = 2.6, off: Float = 0) -> V3 {
        let r = lerpRow(t, y)
        let ca = cos(a), sa = sin(a)
        let x = (ca < 0 ? -1 : 1) * pow(abs(ca), 2 / e), z = (sa < 0 ? -1 : 1) * pow(abs(sa), 2 / e)
        let p = V3(r.ru * x, y, r.cz + r.rv * z)
        let radial = simd_normalize(V3(p.x, 0, p.z - r.cz) + V3(1e-6, 0, 1e-6))
        return p + radial * off
    }
    func orient(_ s: inout Surface, _ center: (V3) -> V3) {
        WoodParts.orientOutward(&s, center: center)
        s.recomputeNormals(weldSeams: false)
        s.computeTangents()
    }
    /// Closed shell lofted over a profile table, `sides` around.
    func shell(_ t: [Row], sides: Int, e: Float = 2.6, capEnd: Bool = false, _ mat: MaterialKey) -> Surface {
        let rings = t.map { row in (0..<sides).map { Self.surf(t, row.y, 2 * .pi * Float($0) / Float(sides), e: e) } }
        var s = Prim.loft(rings, capStart: false, capEnd: capEnd, material: mat)
        orient(&s) { p in V3(0, p.y, Self.lerpRow(t, p.y).cz) }
        return s
    }
    /// Open patch of a profile between angles, `rows` ys from y0 to y1, offset `off` outward.
    func patch(_ t: [Row], y0: Float, y1: Float, a0: Float, a1: Float, rows: Int, cols: Int, off: Float, e: Float = 2.6) -> [[V3]] {
        (0..<rows).map { i in
            let y = y0 + (y1 - y0) * Float(i) / Float(rows - 1)
            return (0..<cols).map { k in Self.surf(t, y, a0 + (a1 - a0) * Float(k) / Float(cols - 1), e: e, off: off) }
        }
    }
    /// Thick plate: outer skin, inner skin and a rim strip, as three surfaces.
    func plate(_ g: [[V3]], thick: Float, _ mat: MaterialKey) -> [Surface] {
        let R = g.count, C = g[0].count
        func axis(_ p: V3) -> V3 { V3(0, p.y, 0) }
        func uv(_ i: Int, _ k: Int) -> V2 { V2(Float(k) * 0.02, Float(i) * 0.02) }
        let inner = g.map { row in row.map { p in p - simd_normalize(V3(p.x, 0, p.z) + V3(1e-6, 0, 1e-6)) * thick } }
        func skin(_ rows: [[V3]], flip: Bool) -> Surface {
            var s = Surface(material: mat)
            for (i, row) in rows.enumerated() { for (k, p) in row.enumerated() { s.add(p, .up, uv(i, k)) } }
            for i in 0..<(R - 1) { for k in 0..<(C - 1) {
                let a = UInt32(i * C + k), c = UInt32(C)
                s.quad(a, a + 1, a + c + 1, a + c)
            }}
            orient(&s, axis)
            if flip { for t in stride(from: 0, to: s.indices.count, by: 3) { s.indices.swapAt(t + 1, t + 2) }; s.recomputeNormals(weldSeams: false); s.computeTangents() }
            return s
        }
        var rim = Surface(material: mat)
        func strip(_ a: V3, _ b: V3, _ ia: V3, _ ib: V3) {
            let n = rim.positions.count
            rim.add(a, .up, V2(0, 0)); rim.add(b, .up, V2(0.02, 0)); rim.add(ib, .up, V2(0.02, thick)); rim.add(ia, .up, V2(0, thick))
            rim.quad(UInt32(n), UInt32(n + 1), UInt32(n + 2), UInt32(n + 3))
        }
        for k in 0..<(C - 1) {
            strip(g[0][k], g[0][k + 1], inner[0][k], inner[0][k + 1])
            strip(g[R - 1][k], g[R - 1][k + 1], inner[R - 1][k], inner[R - 1][k + 1])
        }
        for i in 0..<(R - 1) {
            strip(g[i][0], g[i + 1][0], inner[i][0], inner[i + 1][0])
            strip(g[i][C - 1], g[i + 1][C - 1], inner[i][C - 1], inner[i + 1][C - 1])
        }
        let mid = g.flatMap { $0 }.reduce(V3.zero, +) / Float(R * C)
        orient(&rim) { _ in mid }
        return [skin(g, flip: false), skin(inner, flip: true), rim]
    }
    /// Closed ellipse band in the XZ plane (rim trims, cuffs).
    func band(_ c: V3, _ ru: Float, _ rv: Float, _ r: Float, n: Int, _ mat: MaterialKey) -> Surface {
        let path = (0..<n).map { k -> V3 in let a = 2 * .pi * Float(k) / Float(n); return c + V3(cos(a) * ru, 0, sin(a) * rv) }
        return Prim.sweep(Shape2D.circle(r, segments: 6), along: path, up: .up, closedPath: true, caps: false, material: mat)
    }
    func line(_ path: [V3], _ r: Float, _ mat: MaterialKey) -> Surface {
        Prim.tube(path, radii: path.map { _ in r }, sides: 5, seamTile: 0.05, material: mat, capEnd: true)
    }
    func rivet(_ p: V3, _ n: V3, _ mat: MaterialKey) -> (Surface, Xform) {
        let s = Prim.lathe([V2(0.0065, 0), V2(0.006, 0.0018), V2(0.0042, 0.0034), V2(0.0001, 0.0042)], segments: 10, seamTile: 0.05, material: mat)
        return (s, Xform(translation: p, rotation: simd_quatf(from: V3(0, 1, 0), to: n)))
    }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [3])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)
        func rad(_ d: Float) -> Float { d * .pi / 180 }
        let sides: [(Float, String)] = [(1, "L"), (-1, "R")]

        // Drivers first so mimics resolve.
        _ = rig.part("faceplate", pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.5))
        _ = rig.part("repulsor", pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.25))
        _ = rig.part("reactor", pivot: .zero, joint: .hinge(axis: Y, 0...1.5, duration: 0.8))
        _ = rig.part("thruster", pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.4))

        // Kit pieces at their pivots.
        _ = rig.part("helmet", pivot: V3(0, 0, 0), joint: .fixed)
        _ = rig.part("chest", pivot: V3(0, -0.2, 0.05), joint: .fixed)
        _ = rig.part("back", pivot: V3(0, -0.2, -0.08), joint: .fixed)
        for (sx, t) in sides {
            _ = rig.part("shoulder" + t, pivot: V3(sx * 0.21, -0.05, 0), joint: .fixed)
            _ = rig.part("gauntlet" + t, pivot: V3(sx * 0.25, -0.35, 0), joint: .fixed)
            _ = rig.part("boot" + t, pivot: V3(sx * 0.10, -1.42, 0), joint: .fixed)
        }
        _ = rig.part("faceplatePlate", parent: "helmet", pivot: V3(0, 0.21, 0.09),
                     joint: Joint(.revolute, axis: X, range: -70...0, mimic: .init("faceplate", ratio: -70)))
        _ = rig.part("reactorGlow", parent: "chest", pivot: V3(0, -0.17, 0.14),
                     joint: Joint(.prismatic, axis: Z, range: 0...0.012, mimic: .init("reactor", ratio: 0.008)))
        for (sx, t) in sides {
            let palm = V3(sx * 0.25 - sx * 0.018, -0.35 - 0.325, 0)
            _ = rig.part("repulsorGlow" + t, parent: "gauntlet" + t, pivot: palm,
                         joint: Joint(.prismatic, axis: V3(-sx, 0, 0), range: 0...0.012, mimic: .init("repulsor", ratio: 0.008)))
            _ = rig.part("flame" + t, parent: "boot" + t, pivot: V3(sx * 0.10, -1.42 - 0.075, -0.01),
                         joint: Joint(.prismatic, axis: V3(0, -1, 0), range: 0...0.22, mimic: .init("thruster", ratio: 0.22)))
        }

        for l in 0..<2 {
            let hi = l == 0
            let n = hi ? 48 : 24
            func put(_ s: Surface, _ part: String, _ x: Xform = .identity) { rig.add(s, x, to: part, lods: l...l) }

            // MARK: Helmet
            put(shell(Self.helmet, sides: n, e: 2.4, capEnd: true, red), "helmet")
            put(band(V3(0, 0.004, 0), 0.066, 0.074, 0.011, n: hi ? 32 : 16, gold), "helmet")
            for sx: Float in [1, -1] {
                let ear = Prim.cylinder(radius: 0.027, height: 0.012, bevel: 0.003, segments: hi ? 32 : 16, material: gold)
                put(ear, "helmet", Xform(translation: V3(sx * 0.092, 0.135, 0.008), rotation: simd_quatf(from: Y, to: V3(sx, 0, 0))))
                if hi {
                    put(Prim.torus(major: 0.027, minor: 0.004, segments: 24, sides: 6, material: iron), "helmet",
                        Xform(translation: V3(sx * 0.104, 0.135, 0.008), rotation: simd_quatf(from: Y, to: V3(sx, 0, 0))))
                }
            }
            // Faceplate, hinged at the brow, with eye slits and a mouth seam.
            let fp = patch(Self.helmet, y0: 0.012, y1: 0.205, a0: .pi / 2 - 1.0, a1: .pi / 2 + 1.0, rows: hi ? 12 : 6, cols: hi ? 25 : 13, off: 0.008)
            for s in plate(fp, thick: 0.007, gold) { put(s, "faceplatePlate") }
            put(Prim.tube(fp[0], radii: fp[0].map { _ in 0.004 }, sides: 5, seamTile: 0.05, material: red, capEnd: true), "faceplatePlate")
            for sx: Float in [1, -1] {
                let a0: Float = .pi / 2 - sx * 0.22, a1: Float = .pi / 2 - sx * 0.80
                let rows: [[V3]] = [0, 1].map { r in (0..<9).map { j in
                    let u = Float(j) / 8
                    let y = 0.152 - 0.016 * u - Float(r) * 0.016 + 0.01 * sin(u * .pi)
                    return Self.surf(Self.helmet, y, a0 + (a1 - a0) * u, e: 2.4, off: 0.0105)
                }}
                var slit = WoodParts.grid(rows, uvs: rows.map { r in r.indices.map { V2(Float($0) * 0.01, 0) } }, material: glow)
                orient(&slit) { p in V3(0, p.y, 0.01) }
                put(slit, "faceplatePlate")
            }
            if hi {
                let mouth = (0..<17).map { k in Self.surf(Self.helmet, 0.045, .pi / 2 - 0.55 + 1.1 * Float(k) / 16, e: 2.4, off: 0.011) }
                put(line(mouth, 0.0028, iron), "faceplatePlate")
                for k in 0..<5 { let a: Float = .pi / 2 - 0.7 + 1.4 * Float(k) / 4
                    let p = Self.surf(Self.helmet, 0.19, a, e: 2.4, off: 0.0105)
                    let r = rivet(p, simd_normalize(V3(p.x, 0, p.z - 0.01)), iron); put(r.0, "faceplatePlate", r.1) }
            }

            // MARK: Chest plate, reactor housing, belt
            let front = patch(Self.torso, y0: -0.06, y1: -0.45, a0: .pi / 2 - 1.75, a1: .pi / 2 + 1.75, rows: hi ? 12 : 6, cols: hi ? 25 : 13, off: 0.012)
            for s in plate(front, thick: 0.009, red) { put(s, "chest") }
            put(band(V3(0, -0.07, 0.01), 0.15, 0.092, 0.007, n: hi ? 32 : 16, gold), "chest")
            put(band(V3(0, -0.455, 0.005), 0.152, 0.088, 0.0085, n: hi ? 32 : 16, gold), "chest")
            let flange = Prim.lathe([V2(0.0001, 0), V2(0.066, 0), V2(0.066, 0.006), V2(0.056, 0.014), V2(0.044, 0.01), V2(0.044, 0.004), V2(0.0001, 0.004)],
                                    segments: hi ? 48 : 24, seamTile: 0.1, material: gold)
            let rx = Xform(translation: V3(0, -0.17, 0.128), rotation: simd_quatf(from: Y, to: Z))
            put(flange, "chest", rx)
            put(Prim.torus(major: 0.06, minor: 0.004, segments: hi ? 48 : 24, sides: 6, material: iron), "chest",
                Xform(translation: V3(0, -0.17, 0.136), rotation: simd_quatf(from: Y, to: Z)))
            // Reactor glow: ring, hub and six spokes, recessed 0.008 until `reactor` rises.
            let gz: Float = 0.134 - 0.008
            put(Prim.torus(major: 0.034, minor: 0.0065, segments: hi ? 48 : 24, sides: hi ? 12 : 6, material: glow), "reactorGlow",
                Xform(translation: V3(0, -0.17, gz), rotation: simd_quatf(from: Y, to: Z)))
            put(Prim.lathe([V2(0.0001, 0), V2(0.016, 0), V2(0.019, 0.003), V2(0.0001, 0.004)], segments: hi ? 32 : 16, seamTile: 0.1, material: glow), "reactorGlow",
                Xform(translation: V3(0, -0.17, gz), rotation: simd_quatf(from: Y, to: Z)))
            if hi {
                for k in 0..<6 {
                    let a = Float(k) * .pi / 3
                    put(Prim.superellipsoid(V3(0.036, 0.007, 0.005), exponent: 2.5, subdivisions: 4, material: glow), "reactorGlow",
                        Xform(translation: V3(0, -0.17, gz + 0.001), rotation: simd_quatf(angle: a, axis: Z)))
                }
                // Panel seams: sternum, abdomen segments, pec lines, rivets along both rims.
                put(line((0..<9).map { Self.surf(Self.torso, -0.25 - 0.2 * Float($0) / 8, .pi / 2, off: 0.0125) }, 0.003, iron), "chest")
                for y: Float in [-0.30, -0.36, -0.42] {
                    put(line((0..<15).map { Self.surf(Self.torso, y, .pi / 2 - 1.4 + 2.8 * Float($0) / 14, off: 0.0125) }, 0.0028, iron), "chest")
                }
                for y: Float in [-0.08, -0.115] {
                    put(line((0..<13).map { Self.surf(Self.torso, y - 0.04 * abs(Float($0) - 6) / 6, .pi / 2 - 1.0 + 2.0 * Float($0) / 12, off: 0.0125) }, 0.0028, iron), "chest")
                }
                for (y, count) in [(-0.085 as Float, 9), (-0.435, 9)] {
                    for k in 0..<count {
                        let a: Float = .pi / 2 - 1.5 + 3.0 * Float(k) / Float(count - 1)
                        let p = Self.surf(Self.torso, y, a, off: 0.0125)
                        let r = rivet(p, simd_normalize(V3(p.x, 0, p.z - 0.02)), gold); put(r.0, "chest", r.1)
                    }
                }
            }

            // MARK: Back plate, spine, thruster nozzles
            let rear = patch(Self.torso, y0: -0.07, y1: -0.44, a0: 3 * .pi / 2 - 1.5, a1: 3 * .pi / 2 + 1.5, rows: hi ? 11 : 6, cols: hi ? 23 : 12, off: 0.012)
            for s in plate(rear, thick: 0.009, red) { put(s, "back") }
            put(line((0..<11).map { Self.surf(Self.torso, -0.08 - 0.35 * Float($0) / 10, 3 * .pi / 2, off: 0.02) }, 0.009, gold), "back")
            for sx: Float in [1, -1] {
                let bell = Prim.lathe([V2(0.018, 0), V2(0.026, 0.02), V2(0.036, 0.055), V2(0.042, 0.072), V2(0.037, 0.074), V2(0.031, 0.05), V2(0.02, 0.008)],
                                      segments: hi ? 32 : 16, seamTile: 0.1, material: titanium)
                put(bell, "back", Xform(translation: V3(sx * 0.06, -0.31, -0.088), rotation: simd_quatf(angle: -.pi / 2, axis: X)))
                put(Prim.cylinder(radius: 0.03, height: 0.05, bevel: 0.005, segments: hi ? 32 : 16, material: gold), "back",
                    Xform(translation: V3(sx * 0.06, -0.31, -0.115), rotation: simd_quatf(angle: -.pi / 2, axis: X)))
            }
            if hi {
                for (y, count) in [(-0.085 as Float, 7), (-0.425, 7)] {
                    for k in 0..<count {
                        let p = Self.surf(Self.torso, y, 3 * .pi / 2 - 1.3 + 2.6 * Float(k) / Float(count - 1), off: 0.0125)
                        let r = rivet(p, simd_normalize(V3(p.x, 0, p.z - 0.02)), gold); put(r.0, "back", r.1)
                    }
                }
            }

            // MARK: Pauldrons and lames
            for (sx, t) in sides {
                let toX = simd_quatf(angle: -sx * .pi / 2, axis: Z)
                let o = V3(sx * 0.17, -0.05, 0)
                let xf = Xform(translation: o, rotation: toX)
                put(shell(Self.pauldron, sides: n, e: 2.2, capEnd: false, red).transformed(xf), "shoulder" + t)
                put(band(V3(0, 0.002, 0), 0.084, 0.092, 0.0075, n: hi ? 32 : 16, gold).transformed(xf), "shoulder" + t)
                put(band(V3(0, 0.05, 0), 0.07, 0.078, 0.004, n: hi ? 32 : 16, gold).transformed(xf), "shoulder" + t)
                for (i, (top, h)) in [(-0.012 as Float, 0.052 as Float), (-0.058, 0.048)].enumerated() {
                    let ru = 0.074 - 0.006 * Float(i), rv = 0.08 - 0.006 * Float(i)
                    let rows: [Row] = [(top, ru - 0.004, rv - 0.004, 0), (top - h * 0.5, ru + 0.004, rv + 0.004, 0), (top - h, ru, rv, 0)]
                    let c = V3(sx * 0.21, -0.05, 0)
                    put(shell(rows.map { (y: $0.y, ru: $0.ru, rv: $0.rv, cz: $0.cz) }, sides: n, e: 2.4, red).transformed(Xform(translation: c)), "shoulder" + t)
                    put(band(c + V3(0, top - h, 0), ru, rv, 0.0055, n: hi ? 32 : 16, gold), "shoulder" + t)
                }
                if hi {
                    for k in 0..<10 {
                        let a = 2 * .pi * Float(k) / 10
                        let p = o + simd_act(toX, V3(cos(a) * 0.088, 0.014, sin(a) * 0.096))
                        let nrm = simd_normalize(simd_act(toX, V3(cos(a), 0.5, sin(a))))
                        let r = rivet(p, nrm, gold); put(r.0, "shoulder" + t, r.1)
                    }
                }
            }

            // MARK: Gauntlets, hands, repulsors
            for (sx, t) in sides {
                let P = V3(sx * 0.25, -0.35, 0)
                let rows = Self.forearm.map { (y: $0.y, ru: $0.ru, rv: $0.rv, cz: $0.cz) }
                put(shell(rows, sides: n, e: 2.6, red).transformed(Xform(translation: P)), "gauntlet" + t)
                put(band(P + V3(0, 0.03, 0), 0.058, 0.062, 0.0075, n: hi ? 32 : 16, gold), "gauntlet" + t)
                put(band(P + V3(0, -0.13, 0), 0.058, 0.06, 0.005, n: hi ? 32 : 16, gold), "gauntlet" + t)
                put(band(P + V3(0, -0.25, 0), 0.044, 0.048, 0.0085, n: hi ? 32 : 16, gold), "gauntlet" + t)
                // Elbow cop.
                put(Prim.superellipsoid(V3(0.05, 0.075, 0.085), exponent: 2.4, subdivisions: hi ? 8 : 4, material: gold), "gauntlet" + t,
                    Xform(translation: P + V3(sx * 0.047, 0.03, 0)))
                // Forearm back fin.
                put(Prim.roundedBox(V3(0.012, 0.15, 0.03), radius: 0.005, bevelSegments: 2, material: red), "gauntlet" + t,
                    Xform(translation: P + V3(sx * 0.068, -0.115, 0), rotation: simd_quatf(angle: rad(-4) * sx, axis: Z)))
                // Hand: palm block, fingers, thumb.
                let inward = V3(-sx, 0, 0)
                put(Prim.roundedBox(V3(0.036, 0.105, 0.08), radius: 0.011, bevelSegments: 3, material: red), "gauntlet" + t,
                    Xform(translation: P + V3(0, -0.325, 0)))
                let face = P + V3(-sx * 0.018, -0.325, 0)
                let toIn = simd_quatf(from: Y, to: inward)
                put(Prim.torus(major: 0.027, minor: 0.0055, segments: hi ? 40 : 20, sides: hi ? 10 : 6, material: gold), "gauntlet" + t,
                    Xform(translation: face + inward * 0.004, rotation: toIn))
                put(Prim.lathe([V2(0.0001, 0), V2(0.029, 0), V2(0.0285, -0.004), V2(0.0001, -0.004)], segments: hi ? 32 : 16, seamTile: 0.1, material: iron), "gauntlet" + t,
                    Xform(translation: face + inward * 0.001, rotation: toIn))
                // Palm glow disc, recessed 0.008 until `repulsor` rises (part pivot at `face`).
                put(Prim.lathe([V2(0.0001, 0), V2(0.021, 0), V2(0.023, 0.003), V2(0.0001, 0.004)], segments: hi ? 32 : 16, seamTile: 0.1, material: glow), "repulsorGlow" + t,
                    Xform(translation: face - inward * 0.004, rotation: toIn))
                if hi {
                    for z: Float in [-0.027, -0.009, 0.009, 0.027] {
                        let pts = [P + V3(0, -0.37, z), P + V3(inward.x * 0.004, -0.4, z), P + V3(inward.x * 0.012, -0.425, z)]
                        put(Prim.tube(catmull(pts, per: 2), radii: catmull(pts, per: 2).enumerated().map { 0.0088 - 0.0003 * Float($0.offset) }, sides: 10, seamTile: 0.05, material: gold, capEnd: true), "gauntlet" + t)
                    }
                    let th = [P + V3(inward.x * 0.012, -0.31, 0.04), P + V3(inward.x * 0.02, -0.33, 0.062), P + V3(inward.x * 0.022, -0.355, 0.072)]
                    put(Prim.tube(catmull(th, per: 2), radii: catmull(th, per: 2).map { _ in 0.0085 }, sides: 10, seamTile: 0.05, material: gold, capEnd: true), "gauntlet" + t)
                    for k in 0..<4 {
                        let a = 2 * .pi * Float(k) / 4 + .pi / 4
                        let p = P + V3(sx * 0.002, 0.03, 0) + V3(cos(a) * 0.065 * 0.9, 0.0, sin(a) * 0.068 * 0.9)
                        let r = rivet(p, simd_normalize(V3(cos(a), 0, sin(a))), iron); put(r.0, "gauntlet" + t, r.1)
                    }
                }
            }

            // MARK: Boots, greaves, thrusters
            for (sx, t) in sides {
                let B = V3(sx * 0.10, -1.42, 0)
                let shin = Self.greave.map { (y: $0.y, ru: $0.ru, rv: $0.rv, cz: $0.cz) }
                put(shell(shin, sides: n, e: 2.6, red).transformed(Xform(translation: B)), "boot" + t)
                put(band(B + V3(0, 0.235, 0), 0.057, 0.062, 0.0085, n: hi ? 32 : 16, gold), "boot" + t)
                put(band(B + V3(0, 0.01, 0.01), 0.05, 0.058, 0.007, n: hi ? 32 : 16, gold), "boot" + t)
                put(shell(Self.foot, sides: n, e: 2.4, capEnd: true, red).transformed(Xform(translation: B, rotation: simd_quatf(angle: .pi / 2, axis: X))), "boot" + t)
                // Toe cap and heel guard.
                put(Prim.superellipsoid(V3(0.07, 0.05, 0.075), exponent: 2.5, subdivisions: hi ? 7 : 3, material: gold), "boot" + t,
                    Xform(translation: B + V3(0, -0.045, 0.19)))
                put(Prim.superellipsoid(V3(0.075, 0.05, 0.06), exponent: 2.5, subdivisions: hi ? 6 : 3, material: gold), "boot" + t,
                    Xform(translation: B + V3(0, -0.04, -0.05)))
                // Sole thruster bell and flame cone (cone at rest sits inside the boot; `thruster` slides it out).
                let nz = B + V3(0, -0.075, -0.01)
                put(Prim.lathe([V2(0.034, -0.032), V2(0.030, -0.026), V2(0.022, -0.012), V2(0.016, 0), V2(0.0001, 0.001)], segments: hi ? 32 : 16, seamTile: 0.1, material: titanium), "boot" + t,
                    Xform(translation: nz))
                let cone = Prim.lathe([V2(0.0004, -0.22), V2(0.010, -0.15), V2(0.022, -0.07), V2(0.028, -0.02), V2(0.029, 0)], segments: hi ? 32 : 16, seamTile: 0.1, material: flame)
                put(cone, "flame" + t, Xform(translation: V3(0, 0.22, 0)))
                if hi {
                    for k in 0..<6 {
                        let a = 2 * .pi * Float(k) / 6
                        let p = B + V3(cos(a) * 0.052, 0.225, sin(a) * 0.058 + 0.0)
                        let r = rivet(p, simd_normalize(V3(cos(a), 0, sin(a))), iron); put(r.0, "boot" + t, r.1)
                    }
                }
            }
        }
        _ = rng.float()

        // Lights: reactor and palm glow (the lens flickers them), thruster glow under each boot.
        rig.lights.append(RigLight(name: "reactor", part: "chest", position: V3(0, -0.17, 0.2), color: V3(0.55, 0.85, 1.0), intensity: 500, attenuationRadius: 3))
        for (sx, t) in sides {
            rig.lights.append(RigLight(name: "repulsor" + t, part: "gauntlet" + t, position: V3(sx * 0.19, -0.68, 0), color: V3(0.6, 0.9, 1.0), intensity: 250, attenuationRadius: 2))
            rig.lights.append(RigLight(name: "thruster" + t, part: "boot" + t, position: V3(sx * 0.10, -1.52, -0.01), color: V3(1.0, 0.62, 0.3), intensity: 400, attenuationRadius: 3))
        }

        rig.states = [
            RigState("assembled", ["faceplate": 0, "repulsor": 0, "reactor": 1, "thruster": 0]),
            RigState("faceplate-open", ["faceplate": 1, "repulsor": 0, "reactor": 1, "thruster": 0]),
            RigState("repulsor", ["faceplate": 0, "repulsor": 1, "reactor": 1, "thruster": 0]),
            RigState("boost", ["faceplate": 0, "repulsor": 1, "reactor": 1.3, "thruster": 1]),
            RigState("dormant", ["faceplate": 1, "repulsor": 0, "reactor": 0, "thruster": 0]),
        ]
        return rig
    }
}
