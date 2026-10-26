import simd
import Foundation

/// Paired Gothic Revival lancet windows, 1.0 x 2.4 m: two pointed openings on a 120 mm ashlar pier, each ringed by a
/// roll-moulded arch and a hood mould that ends on carved label stops. Diamond-quarry glass sits in lead cames behind
/// iron saddle bars and a stanchion; limestone jamb courses, a spandrel, a corbelled string course and a throated
/// chamfered sill complete the 300 mm deep reveal. Upper stone is sooted, the sill carries a rain stain.
public struct LancetWindowTraceryPair: RealAsset {
    public static let id = "lancet-window-tracery-pair"
    public static let summary = "Paired Gothic Revival lancet windows: two pointed limestone openings under one hood mould, with leaded glass, iron saddle bars and a shared drip sill."
    public static let tags = ["prop", "architecture", "facade", "window", "stone", "glass"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 6, distance: 4.2)

    /// Clear width of each lancet opening (m).
    public var openWidth: Float = 0.38
    /// Height of the opening from the sill top to the springing line (m).
    public var springHeight: Float = 1.55
    /// Ashlar and moulded stone.
    public var stone: MaterialKey = "stone.limestone"
    /// Sooted stone for the upper courses and the sill.
    public var sooted: MaterialKey = "stone.limestone-sooted"
    /// Lead cames.
    public var lead: MaterialKey = "metal.galvanized-aged"
    /// Saddle bars and stanchions.
    public var iron: MaterialKey = "metal.wrought-iron"
    /// Quarry glass.
    public var glass: MaterialKey = "glass.tinted"
    public init() {}

    private static func inside(_ p: V2, _ poly: [V2]) -> Bool {
        var c = false
        var j = poly.count - 1
        for i in 0..<poly.count {
            let a = poly[i], b = poly[j]
            if (a.y > p.y) != (b.y > p.y), p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x { c.toggle() }
            j = i
        }
        return c
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 1.0, D: Float = 0.30, ow = openWidth, S = springHeight
        let base: Float = 0.16, spring = base + S, top: Float = 2.28
        let cx: Float = 0.25, zg: Float = 0.13
        let rise = FC.archRise(width: ow, spring: S, pointed: true)
        let outline = FC.archOutline(width: ow, spring: S, pointed: true, steps: 14).map { V2($0.x, $0.y + base) }

        // Jamb and pier courses: ashlar blocks with 6 mm mortar joints, every second course sooted at the top.
        let courses = 8, ch = (spring - base) / Float(courses)
        for c in 0..<courses {
            let y = base + (Float(c) + 0.5) * ch
            func tone() -> MaterialKey {
                let t = rng.float(0...1)
                let g = Int(0xC4 + t * 0x1C), b = Int(0xA8 + t * 0x1A)
                return "\(stone):" + String(format: "%02X%02X%02X", g + 0x10, g, b)
            }
            let mat = c >= courses - 3 && rng.chance(0.7) ? sooted : tone()
            FA.box(&m, V3(0.118, ch - 0.006, D - 0.004), V3(0, y, D / 2), rng.chance(0.4) ? sooted : mat, r: 0.004)
            for e: Float in [-1, 1] {
                let jw: Float = 0.06 - 0.004
                FA.box(&m, V3(jw, ch - 0.006, D - 0.004), V3(e * (W / 2 - jw / 2 - 0.002), y, D / 2), mat, r: 0.004)
            }
        }
        // Spandrel: one block outline notched by both arches.
        var sp: [V2] = [V2(-W / 2, spring)]
        for e: Float in [-1, 1] {
            let a = outline.dropFirst(2).reversed().map { V2($0.x + e * cx, $0.y) }
            sp += e < 0 ? Array(a) : Array(a)
        }
        sp += [V2(W / 2, spring), V2(W / 2, top), V2(-W / 2, top)]
        m.add(Prim.extrude(Shape2D.deduped(sp), depth: D - 0.004, bevel: 0.003, bevelSegments: 1, material: sooted),
              Xform(translation: V3(0, 0, D / 2)))
        // Corbelled string course across the top.
        FA.run(&m, [V2(0, 0), V2(0.27, 0), V2(0.27, 0.018), V2(0.30, 0.034), V2(0.30, 0.082), V2(0.25, 0.12), V2(0, 0.12)],
               length: W, at: V3(0, top, 0), sooted, bevel: 0.0025)
        // Sill: plinth under a chamfered, throated weathering.
        FA.box(&m, V3(W, 0.07, 0.27), V3(0, 0.035, 0.135), stone, r: 0.004)
        FA.run(&m, [V2(0, 0), V2(0.28, 0), V2(0.28, 0.012), V2(0.265, 0.014), V2(0.265, 0.024), V2(0.30, 0.03), V2(0.30, 0.06), V2(0.12, base - 0.07), V2(0, base - 0.07)],
               length: W + 0.02, at: V3(0, 0.07, 0), sooted, bevel: 0.0025)
        // Rain stain below the sill, a darker streak on the plinth face.
        for sx: Float in [-0.31, 0.12, 0.29] {
            FA.box(&m, V3(rng.float(0.04...0.08), 0.06, 0.0015), V3(sx + rng.float(-0.02...0.02), 0.035, 0.2705), sooted, r: 0.0006)
        }

        for e: Float in [-1, 1] {
            let x0 = e * cx
            // Glass: one quad per lancet, inset behind the roll moulding.
            let inner = Shape2D.deduped(outline.map { V2($0.x * 0.94 + x0, base + ($0.y - base) * 0.985) })
            m.add(Prim.extrude(inner, depth: 0.006, bevel: 0.0008, bevelSegments: 1, material: glass), Xform(translation: V3(0, 0, zg)))
            // Diamond-quarry cames clipped to the opening.
            let poly = inner
            let pitch: Float = 0.085
            for dir: Float in [1, -1] {
                for k in -32...32 {
                    let c = Float(k) * pitch * 1.25
                    var first: V2? = nil, last: V2? = nil
                    var yy = base
                    while yy <= base + rise + 0.01 {
                        let x = (yy - base - S * 0.5 - c) * dir * 0.72
                        let p = V2(x + x0, yy)
                        if Self.inside(p, poly.map { V2($0.x, $0.y) }) { if first == nil { first = p }; last = p }
                        yy += 0.012
                    }
                    if let a = first, let b = last, simd_length(b - a) > 0.05 {
                        let ang = atan2(b.y - a.y, b.x - a.x) * 180 / .pi
                        let mid = (a + b) / 2
                        FJ.slab(&m, V3(simd_length(b - a) + 0.002, 0.0038, 0.007), V3(mid.x, mid.y, zg + 0.003), lead, rot: FA.q(ang, FA.Z))
                    }
                }
            }
            // Perimeter came, then a repair quarry in slightly different glass.
            m.add(Prim.sweep([V2(-0.005, -0.004), V2(0.005, -0.004), V2(0.005, 0.004), V2(-0.005, 0.004)],
                             along: Array(FC.archPath(width: ow * 0.94, spring: S * 0.985, pointed: true, z: zg + 0.003, steps: 14).map { V3($0.x + x0, $0.y + base, $0.z) }),
                             up: FA.Z, material: lead))
            FJ.slab(&m, V3(0.05, 0.05, 0.0035), V3(x0 + 0.06, base + 0.55, zg + 0.0042), "glass.frosted", rot: FA.q(45, FA.Z))
            // Saddle bars through the jambs and a central stanchion.
            for y in [base + 0.32, base + 0.74, base + 1.16, base + S + 0.06] {
                let hw = ow / 2 * (y > base + S ? 1 - (y - base - S) * 0.5 : 1) + 0.012
                FA.rod(&m, V3(x0 - hw, y, zg + 0.02), V3(x0 + hw, y, zg + 0.02), r: 0.0055, iron, sides: 8)
                for s: Float in [-1, 1] { FA.box(&m, V3(0.012, 0.022, 0.004), V3(x0 + s * (hw - 0.002), y, zg + 0.02), iron, r: 0.001) }
            }
            FA.rod(&m, V3(x0, base + 0.01, zg + 0.02), V3(x0, base + S + 0.12, zg + 0.02), r: 0.0065, iron, sides: 8)
            for y in [base + 0.32, base + 0.74, base + 1.16] { rivet(&m, at: V3(x0, y, zg + 0.0265), normal: FA.Z, radius: 0.0055, segments: 8, material: iron) }

            // Roll-moulded arch and jambs, plus a hollow behind it.
            let rollPath = FC.archPath(width: ow + 0.03, spring: S, pointed: true, z: D - 0.018, steps: 14).map { V3($0.x + x0, $0.y + base, $0.z) }
            FA.path(&m, rollPath, r: 0.017, stone, sides: 10)
            let hollowPath = FC.archPath(width: ow + 0.06, spring: S, pointed: true, z: D - 0.008, steps: 14).map { V3($0.x + x0, $0.y + base, $0.z) }
            FA.path(&m, Array(hollowPath.dropFirst(2).dropLast(2)), r: 0.0095, sooted, sides: 8)
            // Hood mould, dripping over the arch, ending on label stops with a carved head.
            let hoodAll = FC.archPath(width: ow + 0.095, spring: S + 0.02, pointed: true, z: D - 0.012, steps: 14).map { V3($0.x + x0, $0.y + base, $0.z) }
            let hood = Array(hoodAll.dropFirst().dropLast())
            FA.path(&m, hood, r: 0.0125, sooted, sides: 8)
            for s: Float in [-1, 1] {
                let sx = x0 + s * (ow + 0.095) / 2
                FA.box(&m, V3(0.038, 0.048, 0.034), V3(sx, spring + 0.0, D - 0.022), stone, r: 0.004)
                m.add(Prim.superellipsoid(V3(0.032, 0.036, 0.026), exponent: 2.2, subdivisions: 4, material: stone), Xform(translation: V3(sx, spring - 0.002, D - 0.0)))
                FA.box(&m, V3(0.022, 0.004, 0.006), V3(sx, spring - 0.008, D + 0.011), sooted, r: 0.001)
            }
        }
        // Fine ridge where the hood mould tops of both lancets meet the string course.
        FA.box(&m, V3(0.08, 0.02, 0.05), V3(0, top - 0.01, D - 0.03), sooted, r: 0.003)
        // Soot and drip streaks: dark runs under the string course and label stops, lime-wash bloom on the sill front.
        for i in 0..<7 {
            let sx = -0.46 + Float(i) * 0.153 + rng.float(-0.02...0.02), len = rng.float(0.10...0.30)
            FJ.slab(&m, V3(rng.float(0.012...0.03), len, 0.0014), V3(sx, top - len / 2 - 0.004, D - 0.0006), "stone.limestone-sooted:5E574D")
        }
        for e: Float in [-1, 1] {
            for s: Float in [-1, 1] {
                let sx = e * cx + s * (ow + 0.095) / 2
                FJ.slab(&m, V3(0.012, rng.float(0.15...0.28), 0.0014), V3(sx, spring - 0.15, D - 0.0006), "stone.limestone-sooted:625B50")
            }
            // Rust bleed from the saddle-bar ends down the reveal.
            for y in [base + 0.32, base + 0.74] {
                for s: Float in [-1, 1] {
                    FJ.slab(&m, V3(0.0012, rng.float(0.06...0.14), 0.026), V3(e * cx + s * (ow / 2 + 0.0018), y - 0.07, zg + 0.04), "metal.rust")
                }
            }
        }
        // Spalled arrises: small bare-stone pits on the roll mouldings and sill nosing.
        FJ.chips(&m, spots: [V3(-0.31, 0.098, 0), V3(0.31, 0.098, 0), V3(0.0, 0.098, 0)], face: D + 0.0005, "stone.limestone:EDE3CF", rng: &rng, each: 3)
        groundAO(&m, height: 0.12, floor: 0.85)
        return LODModel(FC.place(m))
    }
}
