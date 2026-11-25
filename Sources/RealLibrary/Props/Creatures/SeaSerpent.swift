import simd
import Foundation

/// Sea serpent, 60 m tail tip to snout: a lofted tube body (96 stations, 64 radial points) in overlapping green-bronze scales
/// (dorsal arc) over pale ridged belly plates (ventral arc), a dorsal crest of translucent membrane frills between horn spines,
/// a horned head with a hinged lower jaw, two rows of teeth, glossy eye domes over gold irises with slit pupils, and gill frills
/// fanned on spines behind the jaw. Origin at the body centre on the waterline, head +Z, up +Y. Body z -30 (tail tip) to +30.5 (snout).
///
/// Joints: `coil` -1...1 (vertical sine-wave undulation along the body: alternating pitch hinges at z -22, -14, -6, 6, 12 and 18,
/// so the back rises in humps; negative inverts the wave), `head` -1...1 (head yaw 40 degrees, positive turns the snout toward +X),
/// `rear` 0...1 (front third lifts upright: hinge at z 6 pitches up 45 degrees, neck hinge at z 18 pitches back down 30 degrees,
/// the head rises about 12 m), `jaw` 0...1 (lower jaw opens 32 degrees), `frills` 0...1 (gill frills fan out 55 degrees).
/// All five joints are empty drivers; child parts mimic them. 2 LODs.
public struct SeaSerpent: RealArticulated {
    public static let id = "sea-serpent"
    public static let summary = "60 m sea serpent: lofted scaled body with pale belly plates, dorsal membrane crest, horned head, jaw with teeth, slit-pupil eyes, gill frills, joints coil, head, rear, jaw, frills."
    public static let tags = ["prop", "creature", "fantasy", "water", "river", "outdoor", "articulated"]
    public static let budget = 30_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 55, elevation: 14, distance: 1.1, ground: false, studio: true)

    /// Dorsal and flank scales, green-bronze (Dino.swift dragon scale, tinted).
    public var scales: MaterialKey = "dino.dragon-scale:2E5A3C"
    /// Belly plates, pale bone.
    public var belly: MaterialKey = "dino.scale-skin:D6CBA8"
    /// Crest and gill frill membranes, translucent green.
    public var membrane: MaterialKey = "glass.tinted:2F6A4A"
    /// Horns and crest spines.
    public var horn: MaterialKey = "plastic.gloss:2E2620"
    /// Teeth.
    public var tooth: MaterialKey = "plastic.gloss:E4DCC4"
    /// Mouth lining.
    public var mouth: MaterialKey = "fish.mouth"
    /// Eye dome.
    public var eyeGlass: MaterialKey = "glass.clear"
    /// Iris.
    public var iris: MaterialKey = "glass.tinted:C8961E"
    /// Slit pupil.
    public var pupil: MaterialKey = "plastic.black"
    public init() {}

    // MARK: Body profile

    static let tailZ: Float = -30
    static let snoutZ: Float = 30.5
    static let neckZ: Float = 24

    static func smooth(_ x: Float) -> Float { let t = min(1, max(0, x)); return t * t * (3 - 2 * t) }

    /// Body radius along z: thin tail tip, 1.55 m trunk, neck taper, skull bulge, snout tip.
    static func radius(_ z: Float) -> Float {
        if z < -6 { return 0.02 + 1.53 * pow(smooth((z - tailZ) / 24), 0.75) }
        if z < 10 { return 1.55 + 0.05 * sin((z + 6) / 16 * .pi) }
        if z < neckZ { return 1.55 - 0.5 * smooth((z - 10) / 14) }
        let s = (z - neckZ) / (snoutZ - neckZ)
        if s < 0.4 { return 1.05 + 0.3 * smooth(s / 0.4) }
        return max(0.02, 1.35 * sqrt(max(0, 1 - pow((s - 0.4) / 0.6, 2))) * (0.55 + 0.45 * (1 - s)) / 0.82)
    }
    /// Head sections are wider and flatter than the trunk.
    static func flat(_ z: Float) -> Float { smooth((z - 23) / 3) }
    static func halfWidth(_ z: Float) -> Float { radius(z) * (1.04 + 0.22 * flat(z)) }
    static func halfHeight(_ z: Float) -> Float { radius(z) * (0.96 - 0.18 * flat(z)) }
    /// Ventral plate ridges: each 0.9 m plate overlaps the next toward the tail.
    static func plateRidge(_ z: Float) -> Float { let f = (z / 0.9) - floor(z / 0.9); return 0.035 * f * f }
    /// Point on the section at z, angle a (0 up, pi/2 toward +X, pi down).
    static func section(_ z: Float, _ a: Float, ridge: Float = 0) -> V3 {
        let g = 1 + ridge
        return V3(halfWidth(z) * sin(a) * g, halfHeight(z) * cos(a) * g, z)
    }
    static func outward(_ z: Float, _ a: Float) -> V3 {
        simd_normalize(V3(sin(a) / max(halfWidth(z), 0.01), cos(a) / max(halfHeight(z), 0.01), 0))
    }

    /// Open strip over the angle range a0...a1 and the z stations, outward facing, UVs in meters / 4.
    static func strip(_ zs: [Float], _ a0: Float, _ a1: Float, cols: Int, ridged: Bool, material: MaterialKey) -> Surface {
        var s = Surface(material: material)
        let row = UInt32(cols + 1)
        for z in zs {
            let r = radius(z)
            for c in 0...cols {
                let a = a0 + (a1 - a0) * Float(c) / Float(cols)
                let p = section(z, a, ridge: ridged ? plateRidge(z) : 0)
                _ = s.add(p, outward(z, a), V2(a * r / 4, z / 4))
            }
        }
        // Winding test on a mid quad against the outward normal.
        let mr = zs.count / 2, mc = cols / 2
        let zA = zs[mr], zB = zs[min(mr + 1, zs.count - 1)]
        let aM = a0 + (a1 - a0) * Float(mc) / Float(cols), aN = a0 + (a1 - a0) * Float(mc + 1) / Float(cols)
        let p00 = section(zA, aM), p01 = section(zA, aN), p11 = section(zB, aN)
        let flip = simd_dot(simd_cross(p01 - p00, p11 - p00), outward(zA, aM)) < 0
        for r in 0..<(zs.count - 1) { for c in 0..<cols {
            let a = UInt32(r) * row + UInt32(c), b = a + 1, cc = a + row + 1, d = a + row
            if flip { s.quad(a, d, cc, b) } else { s.quad(a, b, cc, d) }
        }}
        s.recomputeNormals(weldSeams: false)
        s.computeTangents()
        return s
    }

    static func stations(_ zA: Float, _ zB: Float, _ n: Int) -> [Float] { (0..<n).map { zA + (zB - zA) * Float($0) / Float(n - 1) } }

    /// Double-sided membrane on a grid of points (cols along the span, rows up the frill).
    static func membrane(_ grid: [[V3]], normal: V3, _ mat: MaterialKey) -> Surface {
        var s = Surface(material: mat)
        let nrm = simd_normalize(normal)
        let rows = grid.count - 1, cols = grid[0].count - 1
        for side in 0..<2 {
            let base = UInt32(s.vertexCount)
            for r in 0...rows { for c in 0...cols {
                let p = grid[r][c] + nrm * (side == 0 ? 0.015 : -0.015)
                _ = s.add(p, side == 0 ? nrm : -nrm, V2(Float(c) / Float(cols) * 2, Float(r) / Float(rows)))
            }}
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

    /// Tapered cone from base along dir (horns, teeth, spines).
    static func cone(_ base: V3, _ dir: V3, radius r: Float, length: Float, curl: V3 = .zero, sides: Int, _ mat: MaterialKey) -> Surface {
        let d = simd_normalize(dir)
        var path: [V3] = [], radii: [Float] = []
        for i in 0..<6 {
            let t = Float(i) / 5
            path.append(base + d * length * t + curl * (t * t))
            radii.append(max(0.004, r * pow(1 - t, 1.2)))
        }
        return Prim.tube(path, radii: radii, sides: sides, seamTile: 0.3, material: mat, capEnd: true)
    }

    /// Orientation with local +Z along `n`.
    static func facing(_ n: V3) -> simd_quatf {
        let z = simd_normalize(n)
        var x = simd_cross(V3(0, 1, 0), z)
        if simd_length(x) < 1e-3 { x = V3(1, 0, 0) }
        x = simd_normalize(x)
        return simd_quatf(simd_float3x3(columns: (x, simd_cross(z, x), z)))
    }

    // MARK: Rig

    /// Segment layout: (part, zA, zB, LOD0 stations). 96 stations in all, 0.4 m overlap at each hinge.
    static let segments: [(part: String, zA: Float, zB: Float, n: Int)] = [
        ("tail3", -30, -22, 14), ("tail2", -22.4, -14, 12), ("tail1", -14.4, -6, 12), ("body", -6.4, 6.4, 14),
        ("front1", 5.6, 12.4, 10), ("front2", 11.6, 18.4, 10), ("neck", 17.6, 24.4, 10), ("skull", 23.8, 30.5, 14),
    ]

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [220])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0)

        for (name, range, dur): (String, ClosedRange<Float>, Float) in
            [("coil", -1...1, 2.0), ("head", -1...1, 1.0), ("rear", 0...1, 2.5), ("jaw", 0...1, 0.6), ("frills", 0...1, 0.8)] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, range, duration: dur))
        }
        _ = rig.part("body", pivot: .zero, joint: .fixed)

        // Coil wave: alternating pitch about X. Positive rotation about X lifts a -Z (tail-ward) segment and drops a +Z one.
        _ = rig.part("tail1", parent: "body", pivot: V3(0, 0, -6), joint: Joint(.revolute, axis: X, range: -10...10, mimic: .init("coil", ratio: 10)))
        _ = rig.part("tail2", parent: "tail1", pivot: V3(0, 0, -14), joint: Joint(.revolute, axis: X, range: -18...18, mimic: .init("coil", ratio: -18)))
        _ = rig.part("tail3", parent: "tail2", pivot: V3(0, 0, -22), joint: Joint(.revolute, axis: X, range: -16...16, mimic: .init("coil", ratio: 16)))
        _ = rig.part("rearHinge", parent: "body", pivot: V3(0, 0, 6), joint: Joint(.revolute, axis: X, range: -45...0, mimic: .init("rear", ratio: -45)))
        _ = rig.part("front1", parent: "rearHinge", pivot: V3(0, 0, 6), joint: Joint(.revolute, axis: X, range: -10...10, mimic: .init("coil", ratio: -10)))
        _ = rig.part("front2", parent: "front1", pivot: V3(0, 0, 12), joint: Joint(.revolute, axis: X, range: -18...18, mimic: .init("coil", ratio: 18)))
        _ = rig.part("neckRear", parent: "front2", pivot: V3(0, 0, 18), joint: Joint(.revolute, axis: X, range: 0...30, mimic: .init("rear", ratio: 30)))
        _ = rig.part("neck", parent: "neckRear", pivot: V3(0, 0, 18), joint: Joint(.revolute, axis: X, range: -12...12, mimic: .init("coil", ratio: -12)))
        _ = rig.part("skull", parent: "neck", pivot: V3(0, 0, 24), joint: Joint(.revolute, axis: Y, range: -40...40, mimic: .init("head", ratio: 40)))
        _ = rig.part("jawHinge", parent: "skull", pivot: V3(0, -0.55, 25.2), joint: Joint(.revolute, axis: X, range: 0...32, mimic: .init("jaw", ratio: 32)))
        _ = rig.part("frillR", parent: "skull", pivot: V3(1.15, -0.1, 24.6), joint: Joint(.revolute, axis: Y, range: -55...0, mimic: .init("frills", ratio: -55)))
        _ = rig.part("frillL", parent: "skull", pivot: V3(-1.15, -0.1, 24.6), joint: Joint(.revolute, axis: Y, range: 0...55, mimic: .init("frills", ratio: 55)))

        let bellyA: Float = 125 * .pi / 180
        for l in 0..<2 {
            let hi = l == 0
            func put(_ s: Surface, _ part: String, _ x: Xform = .identity) { rig.add(s, x, to: part, lods: l...l) }
            let dorsalCols = hi ? 44 : 16, bellyCols = hi ? 20 : 8
            let sides = hi ? 12 : 6

            // Body: dorsal scale arc plus ventral plate arc; 44 + 20 = 64 radial points per station.
            for seg in Self.segments {
                let n = hi ? seg.n : max(4, seg.n / 3)
                let zs = Self.stations(seg.zA, seg.zB, n)
                put(Self.strip(zs, -bellyA, bellyA, cols: dorsalCols, ridged: false, material: scales), seg.part)
                put(Self.strip(zs, bellyA, 2 * .pi - bellyA, cols: bellyCols, ridged: true, material: belly), seg.part)
            }

            // Dorsal crest: membrane between horn spines on every trunk and neck segment, scalloped between spines.
            let crest: [(part: String, zA: Float, zB: Float, spines: Int)] = [
                ("tail2", -21.6, -14.4, 5), ("tail1", -13.6, -6.4, 6), ("body", -5.6, 5.6, 8), ("front1", 6.4, 11.6, 4),
                ("front2", 12.4, 17.6, 4), ("neck", 18.4, 23.4, 4),
            ]
            for c in crest {
                let cols = hi ? 6 * (c.spines - 1) : 2 * (c.spines - 1)
                let rows = hi ? 4 : 2
                var grid: [[V3]] = []
                for r in 0...rows {
                    let v = Float(r) / Float(rows)
                    grid.append((0...cols).map { k in
                        let u = Float(k) / Float(cols)
                        let z = c.zA + (c.zB - c.zA) * u
                        let spineU = u * Float(c.spines - 1)
                        let scallop = 0.55 + 0.45 * pow(abs(cos(.pi * spineU)), 0.6)
                        let h = 0.75 * Self.radius(z) * scallop
                        let top = Self.halfHeight(z) - 0.08
                        return V3(0.04 * sin(u * 19), top + h * v, z - 0.35 * h * v)
                    })
                }
                put(Self.membrane(grid, normal: X, membrane), c.part)
                for k in 0..<c.spines {
                    let z = c.zA + (c.zB - c.zA) * Float(k) / Float(c.spines - 1)
                    let h = 0.75 * Self.radius(z) * 1.12
                    put(Self.cone(V3(0, Self.halfHeight(z) - 0.15, z), V3(0, 1, -0.35), radius: 0.09, length: h, sides: sides, horn), c.part)
                }
            }

            // Head: horns sweeping back, brow ridges, eyes, mouth lining, upper teeth.
            for side: Float in [-1, 1] {
                put(Self.cone(V3(side * 0.75, 0.85, 26.4), V3(side * 0.35, 0.55, -1), radius: 0.3, length: 3.2, curl: V3(side * 0.2, 0.6, 0),
                              sides: hi ? 16 : 8, horn), "skull")
                put(Self.cone(V3(side * 0.95, 0.55, 25.6), V3(side * 0.6, 0.25, -1), radius: 0.16, length: 1.4, sides: sides, horn), "skull")
                put(Prim.superellipsoid(V3(0.32, 0.22, 1.1), exponent: 2.4, subdivisions: hi ? 3 : 2, material: scales), "skull",
                    Xform(translation: V3(side * 0.82, 0.78, 27.6), rotation: simd_quatf(angle: side * 0.12, axis: Y)))

                let ez: Float = 27.5, ea = side * 58 * Float.pi / 180
                let n = Self.outward(ez, ea)
                let c = Self.section(ez, ea)
                let q = Self.facing(n)
                put(Prim.superellipsoid(V3(0.34, 0.34, 0.24), exponent: 2, subdivisions: hi ? 5 : 3, material: eyeGlass), "skull", Xform(translation: c + n * 0.06, rotation: q))
                put(Prim.superellipsoid(V3(0.3, 0.3, 0.14), exponent: 2, subdivisions: hi ? 4 : 2, material: iris), "skull", Xform(translation: c + n * 0.04, rotation: q))
                put(Prim.superellipsoid(V3(0.045, 0.24, 0.06), exponent: 2, subdivisions: hi ? 3 : 2, material: pupil), "skull", Xform(translation: c + n * 0.17, rotation: q))

                // Upper teeth along the lip line, pointing down.
                let count = hi ? 9 : 4
                for k in 0..<count {
                    let z = 26.2 + 3.6 * Float(k) / Float(count - 1)
                    let lip = Self.section(z, side * 112 * Float.pi / 180)
                    let len: Float = k == 1 ? 0.55 : 0.32 * (1 - 0.4 * Float(k) / Float(count))
                    put(Self.cone(lip, V3(0, -1, 0.15), radius: 0.07, length: len, sides: hi ? 8 : 5, tooth), "skull")
                }
            }
            put(Prim.superellipsoid(V3(0.95, 0.4, 2.6), exponent: 2.2, subdivisions: hi ? 4 : 2, material: mouth), "skull", Xform(translation: V3(0, -0.45, 27.6)))

            // Lower jaw with teeth.
            put(Prim.superellipsoid(V3(1.05, 0.34, 2.75), exponent: 2.4, subdivisions: hi ? 5 : 3, material: scales), "jawHinge", Xform(translation: V3(0, -0.85, 27.8)))
            put(Prim.superellipsoid(V3(0.9, 0.12, 2.5), exponent: 2.4, subdivisions: hi ? 4 : 2, material: mouth), "jawHinge", Xform(translation: V3(0, -0.55, 27.8)))
            for side: Float in [-1, 1] {
                let count = hi ? 8 : 4
                for k in 0..<count {
                    let z = 26.0 + 3.6 * Float(k) / Float(count - 1)
                    let w = 0.85 * sqrt(max(0.05, 1 - pow((z - 27.8) / 2.75, 2)))
                    put(Self.cone(V3(side * w, -0.6, z), V3(0, 1, 0.1), radius: 0.06, length: k == 1 ? 0.45 : 0.28, sides: hi ? 8 : 5, tooth), "jawHinge")
                }
            }

            // Gill frills: membrane fans on five spines, folded back along the neck at frills 0.
            for (side, part) in [(Float(1), "frillR"), (Float(-1), "frillL")] {
                let o = V3(side * 1.15, -0.1, 24.6)
                let dirs: [V3] = (0..<5).map { i in
                    let t = Float(i) / 4
                    return simd_normalize(V3(side * 0.25, -0.9 + 1.8 * t, -1))
                }
                let len: (Float) -> Float = { t in 1.6 + 0.9 * sin(.pi * t) }
                let cols = hi ? 16 : 6, rows = hi ? 4 : 2
                var grid: [[V3]] = []
                for r in 0...rows {
                    let v = Float(r) / Float(rows)
                    grid.append((0...cols).map { k in
                        let t = Float(k) / Float(cols)
                        let f = t * 4, i = min(3, Int(f))
                        let d = simd_normalize(dirs[i] + (dirs[i + 1] - dirs[i]) * (f - Float(i)))
                        let scallop = 0.82 + 0.18 * abs(cos(.pi * f))
                        return o + d * len(t) * v * scallop + V3(side * 0.06 * sin(v * 6 + t * 9) * v, 0, 0)
                    })
                }
                put(Self.membrane(grid, normal: V3(side, 0, -0.25), membrane), part)
                for i in 0..<5 {
                    put(Self.cone(o, dirs[i], radius: 0.06, length: len(Float(i) / 4) * 1.05, sides: hi ? 8 : 4, horn), part)
                }
            }
        }

        rig.states = [
            RigState("rest"),
            RigState("humps", ["coil": 1]),
            RigState("humps-inverse", ["coil": -1]),
            RigState("rear", ["rear": 1, "head": -0.4, "frills": 1]),
            RigState("roar", ["rear": 1, "head": -0.6, "jaw": 1, "frills": 1]),
            RigState("surface", ["coil": 0.6, "frills": 0.5]),
        ]
        return rig
    }
}
