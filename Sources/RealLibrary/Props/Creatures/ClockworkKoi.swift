import simd
import Foundation

/// Clockwork koi, 14 m nose to tail tip: a lofted kohaku body (64 stations, 64 radial points) in white baked enamel with red
/// enamel panels and a red head spot, overlapping brass and copper scale plates along the flanks, a gear ring with teeth at the
/// gill line, glass eye domes over amber irises, a hinged lower jaw with brass barbels, and a segmented tail (four lofted
/// segments chained on hinges) ending in a forked caudal fin. Fins are perforated metal membranes on brass spines: two pectorals,
/// a dorsal, two pelvics and an anal fin. Origin at the body centre, nose +Z, up +Y.
///
/// Joints: `swim` -1...1 (S-wave through the four tail segments, 6, 10, 14 and 18 degrees at full value, positive swings the
/// tail toward +X), `fins` 0...1 (pectoral fins swing out 45 degrees, dorsal fin rises 35 degrees), `jaw` 0...1 (lower jaw opens
/// 28 degrees), `glow` 0...1 (eye irises and gill slits switch to emissive amber at 0.05, with two amber point lights).
/// All four joints are empty drivers; child parts mimic them. 2 LODs.
public struct ClockworkKoi: RealArticulated {
    public static let id = "clockwork-koi"
    public static let summary = "14 m clockwork koi: lofted kohaku enamel body, brass and copper scale plates, gill gear ring, glass eyes with amber irises, jaw, segmented tail, mesh fins, joints swim, fins, jaw, glow."
    public static let tags = ["prop", "creature", "fish", "metal", "glass", "outdoor", "articulated", "glowing"]
    public static let budget = 28_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 60, elevation: 10, distance: 1.1, ground: false, studio: true)

    /// Body and forward tail segments, white baked enamel.
    public var white: MaterialKey = "metal.enamel:F1ECE2"
    /// Kohaku red panels, head spot, peduncle and mouth lining.
    public var red: MaterialKey = "metal.enamel:C4281C"
    /// Mouth lining.
    public var mouth: MaterialKey = "metal.enamel:3A0A08"
    /// Scale plates, odd rows, gear teeth, fin spines, barbels.
    public var brass: MaterialKey = "metal.brass"
    /// Scale plates, even rows, gear ring.
    public var copper: MaterialKey = "metal.copper"
    /// Fin membranes (Metal.swift perforated sheet).
    public var mesh: MaterialKey = "metal.perforated"
    /// Eye dome glass.
    public var glass: MaterialKey = "glass.clear"
    /// Pupils.
    public var pupil: MaterialKey = "metal.enamel:0A0A0A"
    /// Iris and gill slits when lit (Emissive.swift).
    public var lit: MaterialKey = "emissive.amber"
    /// Iris and gill slits when dark.
    public var unlit: MaterialKey = "glass.tinted:5A3A10"
    public init() {}

    // MARK: Body profile

    static let noseZ: Float = 7
    static let tailZ: Float = -5

    static func smooth(_ x: Float) -> Float { let t = min(1, max(0, x)); return t * t * (3 - 2 * t) }

    /// Taper factor along the body, s = 0 at the nose, 1 at the peduncle end.
    static func shape(_ z: Float) -> Float {
        let s = (noseZ - z) / (noseZ - tailZ)
        let a: Float = s < 0.08 ? max(0.04, sqrt(max(0, 1 - pow((0.08 - s) / 0.08, 2)))) : 1
        let b: Float = s < 0.28 ? 0.78 + 0.22 * smooth(s / 0.28) : 0.12 + 0.88 * pow(1 - smooth((s - 0.28) / 0.72), 1.2)
        return a * b
    }
    static func halfWidth(_ z: Float) -> Float { 1.15 * shape(z) }
    static func halfHeight(_ z: Float) -> Float { 1.5 * shape(z) }
    /// Point on the body section at z, angle a (0 up, pi/2 toward +X).
    static func section(_ z: Float, _ a: Float, grow: Float = 1) -> V3 { V3(halfWidth(z) * sin(a) * grow, halfHeight(z) * cos(a) * grow, z) }
    static func outward(_ z: Float, _ a: Float) -> V3 { simd_normalize(V3(sin(a) / halfWidth(z), cos(a) / halfHeight(z), 0)) }

    /// Loft rings from zA to zB inclusive. Rings run nose to tail, which gives outward winding for (sin a, cos a).
    static func rings(_ zA: Float, _ zB: Float, count n: Int, radial: Int, nose: Bool = false) -> [[V3]] {
        (0..<n).map { i -> [V3] in
            let u = Float(i) / Float(n - 1)
            let z = zA + (zB - zA) * (nose ? pow(u, 1.5) : u)
            return (0..<radial).map { j in section(z, 2 * .pi * Float(j) / Float(radial)) }
        }
    }

    /// Orientation with local +Z along `n`, local X along the body's lateral direction.
    static func facing(_ n: V3, tilt: Float = 0.25) -> simd_quatf {
        let z = simd_normalize(n + V3(0, 0, tilt))
        var x = simd_cross(V3(0, 0, 1), z)
        if simd_length(x) < 1e-3 { x = V3(1, 0, 0) }
        x = simd_normalize(x)
        let y = simd_cross(z, x)
        return simd_quatf(simd_float3x3(columns: (x, y, z)))
    }

    // MARK: Fins

    /// Double-sided perforated membrane fanned between two ray directions, ripple along the span.
    static func membrane(_ o: V3, _ dA: V3, _ dB: V3, length: (Float) -> Float, normal: V3, cols: Int, rows: Int, ripple: Float, _ mat: MaterialKey) -> Surface {
        var s = Surface(material: mat)
        let nrm = simd_normalize(normal)
        for side in 0..<2 {
            let base = UInt32(s.vertexCount)
            for r in 0...rows {
                let v = Float(r) / Float(rows)
                for c in 0...cols {
                    let u = Float(c) / Float(cols)
                    let d = simd_normalize(dA + (dB - dA) * u)
                    let wave = ripple * sin(v * 8 + u * 5) * v
                    let p = o + d * (length(u) * v) + nrm * (wave + (side == 0 ? 0.012 : -0.012))
                    _ = s.add(p, side == 0 ? nrm : -nrm, V2(u * length(u), v * length(u)))
                }
            }
            let row = UInt32(cols + 1)
            for r in 0..<rows { for c in 0..<cols {
                let a = base + UInt32(r) * row + UInt32(c)
                if side == 0 { s.quad(a, a + 1, a + row + 1, a + row) } else { s.quad(a, a + row, a + row + 1, a + 1) }
            }}
        }
        s.recomputeNormals(weldSeams: false)
        s.computeTangents()
        return s
    }

    /// Brass spines along the rays of a fan.
    static func spines(_ o: V3, _ dA: V3, _ dB: V3, length: (Float) -> Float, count: Int, sides: Int, _ mat: MaterialKey) -> [Surface] {
        (0..<count).map { i -> Surface in
            let u = Float(i) / Float(count - 1)
            let d = simd_normalize(dA + (dB - dA) * u)
            let l = length(u)
            return Prim.tube([o, o + d * l * 0.5, o + d * l], radii: [0.055, 0.04, 0.022], sides: sides, seamTile: 0.3, material: mat, capEnd: true)
        }
    }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [160])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)

        for (name, range, dur): (String, ClosedRange<Float>, Float) in
            [("swim", -1...1, 1.2), ("fins", 0...1, 0.8), ("jaw", 0...1, 0.5), ("glow", 0...1, 1.5)] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, range, duration: dur))
        }
        _ = rig.part("body", pivot: .zero, joint: .fixed)

        // Tail chain: each segment yaws about its own front ring, angles accumulate down the chain.
        let tailZ: [Float] = [0, -1.6, -3.0, -4.2]
        let tailRatio: [Float] = [6, 10, 14, 18]
        for i in 0..<4 {
            _ = rig.part("tail\(i + 1)", parent: i == 0 ? "body" : "tail\(i)", pivot: V3(0, 0, tailZ[i]),
                         joint: Joint(.revolute, axis: Y, range: -tailRatio[i]...tailRatio[i], mimic: .init("swim", ratio: tailRatio[i])))
        }
        // Pectorals swing out about a vertical axis at the fin root, dorsal rises about X.
        _ = rig.part("pecR", parent: "body", pivot: V3(1.05, -0.6, 3.8), joint: Joint(.revolute, axis: Y, range: -45...0, mimic: .init("fins", ratio: -45)))
        _ = rig.part("pecL", parent: "body", pivot: V3(-1.05, -0.6, 3.8), joint: Joint(.revolute, axis: Y, range: 0...45, mimic: .init("fins", ratio: 45)))
        _ = rig.part("dorsal", parent: "body", pivot: V3(0, 1.4, 3.0), joint: Joint(.revolute, axis: X, range: 0...35, mimic: .init("fins", ratio: 35)))
        _ = rig.part("jawHinge", parent: "body", pivot: V3(0, -0.9, 5.4), joint: Joint(.revolute, axis: X, range: 0...28, mimic: .init("jaw", ratio: 28)))
        _ = rig.part("lamps", parent: "body", pivot: .zero, joint: .fixed, options: 2)
        rig.optionLinks = [RigOptionLink(part: "lamps", joint: "glow", thresholds: [0.05])]

        for l in 0..<2 {
            let hi = l == 0
            func put(_ s: Surface, _ part: String, option: Int = 0, _ x: Xform = .identity) {
                rig.add(s, x, to: part, option: option, lods: l...l)
            }
            let radial = hi ? 64 : 24
            let sub = hi ? 2 : 1

            // Body lofts: 34 + 10 + 8 + 8 + 8 rings, 64 stations in all (shared boundary rings).
            let counts = hi ? [34, 10, 8, 8, 8] : [14, 4, 4, 4, 4]
            put(Prim.loft(Self.rings(7, 0, count: counts[0], radial: radial, nose: true), capStart: true, material: white), "body")
            put(Prim.loft(Self.rings(0, -1.6, count: counts[1], radial: radial), material: white), "tail1")
            put(Prim.loft(Self.rings(-1.6, -3.0, count: counts[2], radial: radial), material: white), "tail2")
            put(Prim.loft(Self.rings(-3.0, -4.2, count: counts[3], radial: radial), material: red), "tail3")
            put(Prim.loft(Self.rings(-4.2, -5.0, count: counts[4], radial: radial), capEnd: true, material: red), "tail4")

            // Scale plates: overlapping flank rows, alternating brass and copper, tilted toward the tail.
            typealias Row = (z: Float, part: String, per: Int)
            var flank: [Row] = []
            if hi {
                for k in 0..<9 { flank.append((z: 5.4 - 0.6 * Float(k), part: "body", per: 7)) }
                let tailRows: [Row] = [(-0.5, "tail1", 5), (-1.1, "tail1", 5), (-1.9, "tail2", 4), (-2.5, "tail2", 4), (-3.4, "tail3", 3), (-3.9, "tail3", 3)]
                flank += tailRows
            } else {
                for k in 0..<4 { flank.append((z: 5.0 - 1.4 * Float(k), part: "body", per: 4)) }
                let tailRows: [Row] = [(-0.8, "tail1", 3), (-2.2, "tail2", 3)]
                flank += tailRows
            }
            for (row, f) in flank.enumerated() {
                let size = V3(max(0.2, 0.5 * Self.shape(f.z) * 1.2), max(0.2, 0.62 * Self.shape(f.z) * 1.3), 0.1)
                for side: Float in [-1, 1] {
                    for k in 0..<f.per {
                        let off: Float = row % 2 == 0 ? 0 : 0.5
                        let deg = 38 + (Float(k) + off) * (108 / Float(f.per))
                        let a = side * deg * .pi / 180
                        let n = Self.outward(f.z, a)
                        let p = Self.section(f.z, a) + n * 0.03
                        let plate = Prim.superellipsoid(size, exponent: 2.4, subdivisions: sub, material: (row + k) % 2 == 0 ? brass : copper)
                        put(plate, f.part, Xform(translation: p, rotation: Self.facing(n)))
                    }
                }
            }

            // Kohaku panels and the head spot (red enamel plates a little proud of the white body).
            let panels: [(z: Float, a: Float, sx: Float, sz: Float)] = [(3.4, -0.18, 1.5, 1.9), (1.5, 0.25, 1.3, 2.2), (0.2, -0.1, 1.0, 1.5), (5.7, 0.05, 0.95, 0.95)]
            for p in panels {
                let n = Self.outward(p.z, p.a)
                put(Prim.superellipsoid(V3(p.sx, p.sz, 0.12), exponent: 3, subdivisions: hi ? 3 : 2, material: red), "body",
                    Xform(translation: Self.section(p.z, p.a) + n * 0.03, rotation: Self.facing(n, tilt: 0.1)))
            }

            // Gear rings at the gill line: copper hoop with brass teeth, plus a thin inner brass hoop behind it.
            let gz: Float = 4.4
            let gw = Self.halfWidth(gz) * 1.03, gh = Self.halfHeight(gz) * 1.03
            put(Prim.torus(major: 1, minor: 0.075, segments: hi ? 64 : 24, sides: hi ? 10 : 6, material: copper), "body",
                Xform(translation: V3(0, 0, gz), rotation: simd_quatf(angle: .pi / 2, axis: X), scale: V3(gw, 1, gh)))
            put(Prim.torus(major: 1, minor: 0.05, segments: hi ? 64 : 24, sides: hi ? 8 : 6, material: brass), "body",
                Xform(translation: V3(0, 0, gz - 0.55), rotation: simd_quatf(angle: .pi / 2, axis: X), scale: V3(Self.halfWidth(gz - 0.55) * 1.03, 1, Self.halfHeight(gz - 0.55) * 1.03)))
            if hi {
                for k in 0..<28 {
                    let a = 2 * Float.pi * Float(k) / 28
                    let n = simd_normalize(V3(sin(a) / gw, cos(a) / gh, 0))
                    let p = V3(gw * sin(a), gh * cos(a), gz) + n * 0.1
                    put(Prim.superellipsoid(V3(0.16, 0.24, 0.12), exponent: 8, subdivisions: 2, material: brass), "body",
                        Xform(translation: p, rotation: simd_quatf(angle: atan2(-n.x, n.y), axis: Z)))
                }
            }

            // Eyes: glass dome over amber iris and black pupil. Gill slits behind the gear ring.
            let ez: Float = 5.3
            for side: Float in [-1, 1] {
                let a = side * 76 * Float.pi / 180
                let n = Self.outward(ez, a)
                let c = Self.section(ez, a) + n * 0.02
                let q = Self.facing(n, tilt: 0)
                put(Prim.superellipsoid(V3(0.66, 0.66, 0.5), exponent: 2, subdivisions: hi ? 5 : 3, material: glass), "body", Xform(translation: c + n * 0.08, rotation: q))
                for (opt, mat) in [(0, unlit), (1, lit)] {
                    put(Prim.superellipsoid(V3(0.5, 0.5, 0.3), exponent: 2, subdivisions: hi ? 4 : 2, material: mat), "lamps", option: opt, Xform(translation: c + n * 0.04, rotation: q))
                }
                put(Prim.superellipsoid(V3(0.2, 0.2, 0.1), exponent: 2, subdivisions: hi ? 3 : 2, material: pupil), "body", Xform(translation: c + n * 0.2, rotation: q))
                let ga = side * 98 * Float.pi / 180
                let gn = Self.outward(4.85, ga)
                for (opt, mat) in [(0, unlit), (1, lit)] {
                    for j in 0..<3 {
                        let z = 4.85 - 0.13 * Float(j)
                        put(Prim.superellipsoid(V3(0.06, 0.9, 0.07), exponent: 3, subdivisions: hi ? 2 : 1, material: mat), "lamps", option: opt,
                            Xform(translation: Self.section(z, ga) + gn * 0.015, rotation: Self.facing(Self.outward(z, ga), tilt: 0)))
                    }
                }
                // Barbels.
                var path: [V3] = [], radii: [Float] = []
                for i in 0..<8 {
                    let t = Float(i) / 7
                    path.append(V3(side * (0.32 + 0.55 * t), -0.25 - 0.35 * t, 6.65 - 0.3 * t + 0.1 * sin(t * 5)))
                    radii.append(0.05 * (1 - 0.6 * t))
                }
                put(Prim.tube(path, radii: radii, sides: hi ? 8 : 5, seamTile: 0.2, material: brass, capEnd: true), "body")
            }

            // Jaw and mouth lining.
            put(Prim.superellipsoid(V3(1.25, 0.4, 1.5), exponent: 2.4, subdivisions: hi ? 4 : 2, material: red), "jawHinge", Xform(translation: V3(0, -0.15, 0.85)))
            put(Prim.superellipsoid(V3(0.95, 0.85, 0.9), exponent: 2, subdivisions: hi ? 3 : 2, material: mouth), "body", Xform(translation: V3(0, -0.5, 6.0)))

            // Fins.
            let fseg = hi ? 5 : 3
            let fcols = hi ? 14 : 6
            func fan(_ o: V3, _ dA: V3, _ dB: V3, _ len: @escaping (Float) -> Float, normal: V3, part: String, rays: Int, ripple: Float) {
                put(Self.membrane(o, dA, dB, length: len, normal: normal, cols: fcols, rows: fseg, ripple: ripple, mesh), part)
                for s in Self.spines(o, dA, dB, length: len, count: rays, sides: hi ? 8 : 4, brass) { put(s, part) }
            }
            fan(V3(0, 0, -4.8), V3(0, -sin(1.08), -cos(1.08)), V3(0, sin(1.08), -cos(1.08)), { u in 2.6 * (0.62 + 0.38 * pow(abs(2 * u - 1), 1.3)) },
                normal: X, part: "tail4", rays: hi ? 9 : 5, ripple: 0.07)
            fan(V3(1.05, -0.6, 3.8), V3(0.05, -0.25, -0.97), V3(0.45, -0.35, -0.8), { u in 2.2 * (0.7 + 0.3 * sin(.pi * u)) },
                normal: V3(0.3, 0.9, 0), part: "pecR", rays: hi ? 6 : 4, ripple: 0.05)
            fan(V3(-1.05, -0.6, 3.8), V3(-0.05, -0.25, -0.97), V3(-0.45, -0.35, -0.8), { u in 2.2 * (0.7 + 0.3 * sin(.pi * u)) },
                normal: V3(-0.3, 0.9, 0), part: "pecL", rays: hi ? 6 : 4, ripple: 0.05)
            fan(V3(0, 1.4, 3.0), V3(0, 0.25, -0.97), V3(0, 0.85, -0.53), { u in 1.2 + 1.4 * u },
                normal: X, part: "dorsal", rays: hi ? 8 : 4, ripple: 0.05)
            fan(V3(0.6, -1.25, 1.2), V3(0.1, -0.2, -0.97), V3(0.4, -0.5, -0.76), { _ in 1.1 }, normal: V3(0.3, 0.9, 0), part: "body", rays: 4, ripple: 0.03)
            fan(V3(-0.6, -1.25, 1.2), V3(-0.1, -0.2, -0.97), V3(-0.4, -0.5, -0.76), { _ in 1.1 }, normal: V3(-0.3, 0.9, 0), part: "body", rays: 4, ripple: 0.03)
            fan(V3(0, -0.95, -0.4), V3(0, -0.2, -0.97), V3(0, -0.6, -0.8), { _ in 1.0 }, normal: X, part: "tail1", rays: 4, ripple: 0.03)
        }

        rig.lights = [
            RigLight(name: "eye-glow", part: "lamps", option: 1, position: V3(0, 0.4, 5.9), direction: V3(0, 0, 1), color: V3(1, 0.58, 0.16), intensity: 3500, attenuationRadius: 40),
            RigLight(name: "gill-glow", part: "lamps", option: 1, position: V3(0, 0, 4.4), direction: V3(0, 1, 0), color: V3(1, 0.5, 0.12), intensity: 2200, attenuationRadius: 30),
        ]

        rig.states = [
            RigState("rest"),
            RigState("swim-left", ["swim": -1]),
            RigState("swim-right", ["swim": 1]),
            RigState("spread", ["fins": 1]),
            RigState("gape", ["jaw": 1]),
            RigState("leap", ["swim": 0.5, "fins": 1, "jaw": 0.4]),
            RigState("blaze", ["fins": 1, "glow": 1], options: ["lamps": 1]),
        ]
        return rig
    }
}
