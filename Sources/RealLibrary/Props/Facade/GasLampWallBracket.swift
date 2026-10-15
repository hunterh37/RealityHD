import simd
import Foundation

/// Victorian gas lamp wall bracket, 0.75 m: a cast-iron wall plate with side volutes and acanthus leaves,
/// an S-scroll arm, a lantern base cup, a tapered four-pane lantern in an iron frame, a brass burner with
/// a glowing mantle, a pyramidal hood with a louvred chimney vent and a ball finial.
/// Black enamel over cast iron, brass burner, soot at the hood and rust tears under the plate bolts.
public struct GasLampWallBracket: RealAsset {
    public static let id = "gas-lamp-wall-bracket"
    public static let summary = "Victorian gas lamp wall bracket, 0.75 m: cast wall plate, scrolled arm, tapered four-pane lantern, finial and burner."
    public static let tags = ["prop", "architecture", "facade", "light", "metal", "trim"]
    public static let budget = 13500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 38, elevation: 10, distance: 1.5)

    /// Black enamel on the lantern frame, hood and arm.
    public var enamel: MaterialKey = "metal.enamel:141416"
    /// Bare cast iron of the wall plate.
    public var castIron: MaterialKey = "metal.painted:1B1B1D"
    /// Bare iron of bolt heads.
    public var bareIron: MaterialKey = "metal.cast-iron"
    /// Brass burner and fittings.
    public var brass: MaterialKey = "metal.brass-aged"
    /// Lantern panes.
    public var glass: MaterialKey = "glass.pane"
    /// Lit gas mantle.
    public var mantle: MaterialKey = "emissive.warm"
    /// Corrosion under the bolts.
    public var rust: MaterialKey = "metal.rust"
    public init() {}

    private static func leaf(w: Float, h: Float) -> [V2] {
        let right: [V2] = [V2(0.0, 0), V2(0.34 * w, 0.18 * h), V2(0.5 * w, 0.46 * h), V2(0.36 * w, 0.66 * h),
                           V2(0.22 * w, 0.8 * h), V2(0.0, h)]
        return right + right.reversed().dropFirst().dropLast().map { V2(-$0.x, $0.y) }
    }

    /// Spiral in the XY plane about `c`, `turns` turns, radius shrinking to `r1`.
    private static func spiral(c: V3, a0: Float, dir: Float, r0: Float, r1: Float, turns: Float, z: Float, n: Int = 16) -> [V3] {
        (0...n).map { j in
            let t = Float(j) / Float(n), a = a0 + dir * t * turns * 2 * .pi, r = r0 + (r1 - r0) * t
            return V3(c.x + r * cos(a), c.y + r * sin(a), z)
        }
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let zc: Float = 0.328
        let plateY: Float = 0.15
        let cupY: Float = 0.235
        let y0: Float = 0.29, y1: Float = 0.55, h0: Float = 0.054, h1: Float = 0.1

        // Wall plate: pointed-oval cast plate with a raised border, centre boss and a bead rim.
        let oval = Shape2D.superellipse(0.12, 0.3, exponent: 2.6, segments: 32).map { V2($0.x, $0.y + plateY) }
        m.add(Prim.extrude(oval, depth: 0.016, bevel: 0.003, bevelSegments: 2, material: castIron), Xform(translation: V3(0, 0, 0.008)))
        m.add(Prim.extrude(Shape2D.offset(oval, -0.012), depth: 0.008, bevel: 0.0025, bevelSegments: 1, material: castIron), Xform(translation: V3(0, 0, 0.019)))
        FA.cylZ(&m, r: 0.03, h: 0.014, at: V3(0, plateY, 0.02), castIron, bevel: 0.004, segments: 24)
        m.add(Prim.torus(major: 0.03, minor: 0.0045, segments: 24, sides: 6, material: brass), Xform(translation: V3(0, plateY, 0.034), rotation: FA.q(90, FA.X)))
        // Wall bolts: hex heads through the plate ends, each with a washer and a rust tear.
        for y in [plateY - 0.105, plateY + 0.105] {
            FA.cylZ(&m, r: 0.011, h: 0.003, at: V3(0, y, 0.026), castIron, bevel: 0.001, segments: 14)
            hexBolt(&m, at: V3(0, y, 0.029), normal: V3(0, 0, 1), size: 0.014, material: bareIron)
            m.add(Prim.superellipsoid(V3(0.006, rng.float(0.03...0.05), 0.0014), exponent: 2.4, subdivisions: 2, material: rust),
                  Xform(translation: V3(0.001, y - 0.025, 0.0265)))
        }
        // Side volutes: C-scrolls curling out of the plate flanks, each ending in a bead.
        for s: Float in [-1, 1] {
            for (yy, tw) in [(plateY - 0.055, Float(1)), (plateY + 0.055, Float(-1))] {
                var pts = Self.spiral(c: V3(s * 0.14, yy, 0), a0: s > 0 ? .pi : 0, dir: s * tw, r0: 0.05, r1: 0.014, turns: 0.85, z: 0.014)
                pts.insert(V3(s * 0.055, yy - 0.0, 0.014), at: 0)
                pts[0].y = pts[1].y
                m.add(Prim.tube(pts, radii: pts.indices.map { 0.0085 - 0.004 * Float($0) / Float(pts.count - 1) }, sides: 8, seamTile: 0.1, material: castIron, capEnd: true))
                FC.bead(&m, r: 0.0085, at: pts.last!, castIron, sub: 3)
            }
            // Acanthus leaf lying on the plate flank.
            m.add(Prim.extrude(Self.leaf(w: 0.05, h: 0.08), depth: 0.005, bevel: 0.0015, bevelSegments: 1, material: castIron),
                  Xform(translation: V3(s * 0.04, plateY - 0.03, 0.022), rotation: FA.q(s * -25, FA.Z)))
        }
        // S-scroll arm: leaves the boss, drops, rises into the base cup.
        let armPts = catmull([V3(0, plateY, 0.034), V3(0, plateY - 0.03, 0.08), V3(0, plateY - 0.045, 0.14), V3(0, plateY - 0.01, 0.2),
                              V3(0, plateY + 0.06, 0.26), V3(0, cupY + 0.004, zc - 0.015)], per: 8)
        m.add(Prim.tube(armPts, radii: armPts.indices.map { 0.0125 - 0.0045 * Float($0) / Float(armPts.count - 1) }, sides: 12, seamTile: 0.15, material: enamel, capEnd: true))
        // Volute under the arm bend and a leaf on the rising limb.
        var vol: [V3] = []
        for j in 0...16 {
            let t = Float(j) / 16, ang = Float.pi * (0.1 + 1.6 * t), rad: Float = 0.04 * (1 - 0.65 * t)
            vol.append(V3(0, plateY - 0.075 + rad * sin(ang) * -1 + 0.0, 0.1 + rad * cos(ang)))
        }
        m.add(Prim.tube(vol, radii: vol.indices.map { 0.007 - 0.003 * Float($0) / 16 }, sides: 8, seamTile: 0.1, material: enamel, capEnd: true))
        FC.bead(&m, r: 0.007, at: vol.last!, enamel, sub: 3)
        m.add(Prim.extrude(Self.leaf(w: 0.045, h: 0.075), depth: 0.005, bevel: 0.0015, bevelSegments: 1, material: enamel),
              Xform(translation: V3(0.0125, plateY + 0.02, 0.225), rotation: FA.q(90, FA.Y) * FA.q(-35, FA.Z)))
        m.add(Prim.extrude(Self.leaf(w: 0.045, h: 0.075), depth: 0.005, bevel: 0.0015, bevelSegments: 1, material: enamel),
              Xform(translation: V3(-0.0125, plateY + 0.02, 0.225), rotation: FA.q(-90, FA.Y) * FA.q(-35, FA.Z)))
        FA.cylZ(&m, r: 0.017, h: 0.012, at: V3(0, plateY, 0.034), brass, bevel: 0.002, segments: 16)
        // Base cup with a brass rim.
        m.add(turned([(0, cupY), (0.026, cupY), (0.032, cupY + 0.006), (0.044, cupY + 0.03), (0.06, cupY + 0.05), (0.06, cupY + 0.055), (0, cupY + 0.055)],
                     segments: 28, material: enamel), Xform(translation: V3(0, 0, zc)))
        m.add(Prim.torus(major: 0.058, minor: 0.003, segments: 28, sides: 6, material: brass), Xform(translation: V3(0, y0 - 0.004, zc)))
        // Lantern.
        FC.lantern(&m, c: V3(0, 0, zc), y0: y0, y1: y1, h0: h0, h1: h1, post: 0.005, frame: enamel, glass: glass, muntins: false, rng: &rng)
        // Brass burner: stem, gallery ring, flame cap, glowing mantle.
        m.add(turned([(0, y0), (0.018, y0), (0.018, y0 + 0.006), (0.009, y0 + 0.012), (0.009, y0 + 0.05), (0.02, y0 + 0.055), (0.02, y0 + 0.06), (0.012, y0 + 0.064), (0, y0 + 0.064)],
                     segments: 20, material: brass), Xform(translation: V3(0, 0, zc)))
        m.add(Prim.superellipsoid(V3(0.036, 0.075, 0.036), exponent: 2, subdivisions: 6, material: mantle), Xform(translation: V3(0, y0 + 0.1, zc)))
        // Hood: pyramidal ogee of rounded-square rings.
        let steps: [(Float, Float, Float)] = [(0.0, 0.232, 0.01), (0.008, 0.238, 0.01), (0.014, 0.23, 0.01), (0.03, 0.2, 0.012),
                                              (0.055, 0.15, 0.014), (0.082, 0.1, 0.016), (0.102, 0.066, 0.018), (0.112, 0.05, 0.02)]
        m.add(Prim.loft(steps.map { Prim.ring(Shape2D.roundedRect($0.1, $0.1, radius: $0.2, segments: 3), y: y1 + $0.0, offset: V3(0, 0, zc)) },
                        capEnd: true, material: enamel))
        m.add(Prim.loft([Prim.ring(Shape2D.roundedRect(0.232, 0.232, radius: 0.01, segments: 3), y: y1, offset: V3(0, 0, zc)),
                         Prim.ring(Shape2D.roundedRect(0.18, 0.18, radius: 0.01, segments: 3), y: y1, offset: V3(0, 0, zc))], material: enamel).flipped())
        // Hip ribs: rolled corner ribs with a scroll foot at each eave corner.
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            let a = V3(sx * 0.117, y1 + 0.006, zc + sz * 0.117), b = V3(sx * 0.03, y1 + 0.108, zc + sz * 0.03)
            FA.rod(&m, a, b, r: 0.0042, enamel, sides: 6)
            FC.bead(&m, r: 0.0075, at: a + V3(sx * 0.002, -0.002, sz * 0.002), enamel, sub: 3)
        } }
        // Door: barrel hinges on the left corner post, a latch plate and hook on the right.
        let hf = FC.lanternHalf(y: 0.4, y0: y0, y1: y1, h0: h0, h1: h1)
        for yy in [y0 + 0.045, y1 - 0.045] {
            let hh = FC.lanternHalf(y: yy, y0: y0, y1: y1, h0: h0, h1: h1)
            FA.rod(&m, V3(-hh - 0.002, yy - 0.013, zc + hh + 0.002), V3(-hh - 0.002, yy + 0.013, zc + hh + 0.002), r: 0.0052, brass, sides: 10)
        }
        FA.box(&m, V3(0.009, 0.034, 0.003), V3(hf, 0.4, zc + hf + 0.003), brass, r: 0.0007)
        FA.box(&m, V3(0.004, 0.004, 0.007), V3(hf, 0.4 - 0.004, zc + hf + 0.0065), brass, r: 0.0006)
        // Chimney vent: louvred drum and a hat with a ball finial.
        let cy = y1 + 0.112
        m.add(turned([(0, cy), (0.03, cy), (0.03, cy + 0.03), (0, cy + 0.03)], segments: 20, material: enamel), Xform(translation: V3(0, 0, zc)))
        for k in 0..<10 {
            let a = Float(k) / 10 * 2 * .pi
            FA.box(&m, V3(0.014, 0.003, 0.003), V3(0.0315 * cos(a), cy + 0.015, zc + 0.0315 * sin(a)), brass, r: 0.0008, rot: FA.q(90 - a * 180 / .pi, FA.Y))
        }
        m.add(turned([(0.0, cy + 0.03), (0.05, cy + 0.03), (0.054, cy + 0.034), (0.04, cy + 0.044), (0.02, cy + 0.054), (0, cy + 0.056)], segments: 24, material: enamel),
              Xform(translation: V3(0, 0, zc)))
        FA.rod(&m, V3(0, cy + 0.054, zc), V3(0, cy + 0.072, zc), r: 0.005, brass, sides: 8)
        FA.ball(&m, r: 0.016, at: V3(0, cy + 0.085, zc), brass)
        // Soot above the vent hat and hood rim; bare chips at the frame corners.
        for _ in 0..<4 {
            let a = rng.float(0...(2 * .pi))
            m.add(Prim.superellipsoid(V3(0.02, 0.0012, 0.02), exponent: 2.2, subdivisions: 2, material: rust),
                  Xform(translation: V3(0.04 * cos(a), cy + 0.0325, zc + 0.04 * sin(a)) + V3(0, 0.001, 0)))
        }
        groundAO(&m, height: 0.12, floor: 0.7)
        return LODModel(FC.place(m))
    }
}
