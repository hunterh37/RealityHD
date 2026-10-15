import simd
import Foundation

/// Queen Anne Victorian conical turret roof, 3.6 m on a 2.8 m round drum: fascia and crown mould eave on a
/// cove bed mould with scroll soffit brackets, a cone skinned in staggered fish-scale slate with two
/// contrasting bands, eight copper hip ribs, a copper flashing collar, a wrought-iron spire with copper
/// balls and an arched eyebrow dormer with painted trim. Verdigris on the copper, slipped and replaced slates.
public struct ConicalTurretRoof: RealAsset {
    public static let id = "conical-turret-roof"
    public static let summary = "Queen Anne conical turret roof, 3.6 m: 2.8 m round drum with eave, fish-scale shingled cone, copper finial, dormer."
    public static let tags = ["prop", "architecture", "facade", "roof", "trim", "decor", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 14, distance: 2.6)

    /// Eave radius in meters.
    public var eaveRadius: Float = 1.4
    /// Slate.
    public var slate: MaterialKey = "rock.slate"
    /// Contrast slate bands.
    public var slateBand: MaterialKey = "rock.slate:5F6B66"
    /// Slightly lighter slate on every fourth course.
    public var slateAlt: MaterialKey = "rock.slate:6A7276"
    /// Moss and lichen staining.
    public var moss: MaterialKey = "rock.slate:5E7058"
    /// Replacement slates.
    public var slateNew: MaterialKey = "rock.slate:8E9496"
    /// Painted trim.
    public var paint: MaterialKey = "wood.barn-white"
    /// Copper with verdigris.
    public var copper: MaterialKey = "metal.copper-patina"
    /// Spire iron.
    public var iron: MaterialKey = "metal.wrought-iron"
    public init() {}

    private static func leaf(w: Float, h: Float) -> [V2] {
        let right: [V2] = [V2(0.0, 0), V2(0.34 * w, 0.2 * h), V2(0.5 * w, 0.5 * h), V2(0.3 * w, 0.76 * h), V2(0.0, h)]
        return right + right.reversed().dropFirst().dropLast().map { V2(-$0.x, $0.y) }
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let E = eaveRadius
        let yC: Float = 0.21, yTop: Float = 2.72, rBase: Float = 1.3, rTop: Float = 0.1
        func rAt(_ y: Float) -> Float { rBase + (rTop - rBase) * (y - yC) / (yTop - yC) }
        let slopeDeg = atan2(rBase - rTop, yTop - yC) * 180 / .pi

        // Eave: fascia board, crown mould and the cove bed mould beneath, one lathe each.
        m.add(turned([(0, 0), (E - 0.02, 0), (E, 0.01), (E, 0.14), (E - 0.005, 0.15), (E - 0.03, 0.155), (E - 0.04, 0.17), (E - 0.07, 0.186),
                      (E - 0.09, 0.2), (rBase, yC), (0, yC)], segments: 56, material: paint, seamTile: 0.5))
        m.add(turned([(E - 0.2, 0), (E - 0.2, -0.012), (E - 0.14, -0.03), (E - 0.08, -0.052), (E - 0.03, -0.066), (E - 0.012, -0.07), (E - 0.012, 0)],
                     segments: 56, material: paint, seamTile: 0.5))
        // Fascia drip bead and a shadow-line fillet between fascia and crown.
        m.add(Prim.torus(major: E - 0.008, minor: 0.006, segments: 56, sides: 6, material: paint), Xform(translation: V3(0, 0.012, 0)))
        // Soffit brackets: 16 scroll brackets under the bed mould.
        let bracket: [V2] = [V2(0, -0.2), V2(0.014, -0.2), V2(0.022, -0.17), V2(0.05, -0.12), V2(0.09, -0.085), V2(0.2, -0.07), V2(0.2, 0), V2(0, 0)]
        for k in 0..<16 {
            let a = Float(k) / 16 * 2 * .pi
            let rot = FA.q(-a * 180 / .pi, FA.Y)
            m.add(Prim.extrude(bracket, depth: 0.045, bevel: 0.003, bevelSegments: 1, material: paint),
                  Xform(translation: V3((E - 0.2) * cos(a), -0.002, (E - 0.2) * sin(a)), rotation: rot))
        }

        // Underlay cone, dark felt showing between the scallops.
        m.add(turned([(0, yC), (rBase - 0.004, yC), (rTop - 0.004, yTop), (0, yTop)], segments: 56, material: "metal.enamel:1F2024", seamTile: 0.5))

        // Fish-scale slate: each course is a loft whose lower edge is scalloped; courses alternate by half a cell.
        let rows = 25
        let hr = (yTop - yC) / Float(rows)
        for i in 0..<rows {
            let yb = yC - 0.012 + Float(i) * hr, yt = min(yTop, yb + 2.2 * hr)
            let rt = rAt(yt) + 0.001
            let n = max(5, Int((2 * .pi * rAt(yb + hr / 2) / 0.18).rounded()))
            let phase: Float = i % 2 == 0 ? 0 : 0.5
            var bottom: [V3] = [], top: [V3] = []
            for c in 0..<n { for s in 0..<4 {
                let f = Float(s) / 4
                let a = (Float(c) + f + phase) / Float(n) * 2 * .pi
                let drop = 0.062 * (1 - pow(2 * f - 1, 2)) * (1 + rng.float(-0.05...0.05))
                let rr = rAt(yb - drop) + 0.009 - 0.003 * (1 - pow(2 * f - 1, 2))
                bottom.append(V3(rr * cos(a), yb - drop, -rr * sin(a)))
                top.append(V3(rt * cos(a), yt, -rt * sin(a)))
            } }
            let banded = (7...8).contains(i) || (16...17).contains(i)
            m.add(Prim.loft([bottom, top], material: banded ? slateBand : (i % 4 == 0 ? slateAlt : slate)))
        }
        // Replaced slates: pale, square-cut tiles that do not match the fish-scale pattern.
        for _ in 0..<5 {
            let a = rng.float(0.2...2.9) + (rng.chance(0.5) ? 0 : .pi), y = rng.float(0.5...2.0)
            m.add(Prim.extrude(Shape2D.rect(0.1, 0.12), depth: 0.006, bevel: 0.0015, bevelSegments: 1, material: slateNew),
                  Xform(translation: V3((rAt(y) + 0.02) * cos(a), y, (rAt(y) + 0.02) * sin(a)),
                        rotation: FA.q(90 - a * 180 / .pi, FA.Y) * FA.q(-slopeDeg, FA.X)))
        }

        // Weathering: moss collecting on the north-facing lower courses, rust runs below the collar.
        for _ in 0..<7 {
            let a = rng.float(0.2...2.9) + .pi, y = rng.float(0.35...1.3)
            m.add(Prim.superellipsoid(V3(rng.float(0.14...0.3), rng.float(0.1...0.22), 0.006), exponent: 2.4, subdivisions: 2, material: moss),
                  Xform(translation: V3((rAt(y) + 0.014) * cos(a), y, (rAt(y) + 0.014) * sin(a)),
                        rotation: FA.q(90 - a * 180 / .pi, FA.Y) * FA.q(-slopeDeg, FA.X)))
        }
        for k in 0..<4 {
            let a = (Float(k) + 0.25) / 4 * 2 * .pi, y = yTop - 0.28
            m.add(Prim.superellipsoid(V3(0.02, rng.float(0.3...0.5), 0.004), exponent: 2.4, subdivisions: 2, material: "metal.rust"),
                  Xform(translation: V3((rAt(y) + 0.014) * cos(a), y, (rAt(y) + 0.014) * sin(a)),
                        rotation: FA.q(90 - a * 180 / .pi, FA.Y) * FA.q(-slopeDeg, FA.X)))
        }
        // Hip ribs: eight rolled copper ridges from the eave crown to the collar.
        for k in 0..<8 {
            let a = (Float(k) + 0.5) / 8 * 2 * .pi
            let pts = (0...8).map { j -> V3 in
                let y = yC + 0.02 + (yTop - yC - 0.06) * Float(j) / 8
                let r = rAt(y) + 0.03
                return V3(r * cos(a), y, r * sin(a))
            }
            m.add(Prim.tube(pts, radii: pts.indices.map { 0.017 - 0.008 * Float($0) / 8 }, sides: 6, seamTile: 0.1, material: copper, capEnd: true))
        }
        // Copper flashing collar where the cone meets the spire base.
        m.add(turned([(rTop + 0.06, yTop - 0.09), (rTop + 0.07, yTop - 0.08), (rTop + 0.05, yTop + 0.0), (rTop + 0.02, yTop + 0.06),
                      (0.075, yTop + 0.08), (0.075, yTop + 0.12), (0.06, yTop + 0.12), (0.06, yTop - 0.09)], segments: 36, material: copper))
        m.add(Prim.torus(major: rTop + 0.065, minor: 0.008, segments: 36, sides: 6, material: copper), Xform(translation: V3(0, yTop - 0.085, 0)))

        // Spire: iron baluster base, copper ball, long shaft with a second ball and a spear tip.
        let y2 = yTop + 0.12
        m.add(turned([(0, y2), (0.05, y2), (0.058, y2 + 0.015), (0.04, y2 + 0.045), (0.022, y2 + 0.08), (0.03, y2 + 0.11), (0.012, y2 + 0.14), (0.009, y2 + 0.16), (0, y2 + 0.16)],
                     segments: 20, material: iron))
        FA.ball(&m, r: 0.04, at: V3(0, y2 + 0.19, 0), copper)
        m.add(turned([(0, y2 + 0.23), (0.009, y2 + 0.23), (0.007, y2 + 0.4), (0.006, y2 + 0.5), (0, y2 + 0.5)], segments: 12, material: iron))
        FA.ball(&m, r: 0.022, at: V3(0, y2 + 0.4, 0), copper)
        m.add(turned([(0, y2 + 0.5), (0.011, y2 + 0.5), (0.011, y2 + 0.512), (0.007, y2 + 0.53), (0.003, y2 + 0.57), (0, y2 + 0.58)], segments: 10, material: iron))
        // Cross-arm scrolls on the spire.
        for s: Float in [-1, 1] {
            var pts: [V3] = []
            for j in 0...10 {
                let t = Float(j) / 10, ang = t * 1.4 * .pi, rad = 0.05 * (1 - 0.7 * t)
                pts.append(V3(s * (0.01 + rad * sin(ang)), y2 + 0.31 + rad * (1 - cos(ang)) * 0.8 - 0.01, 0))
            }
            m.add(Prim.tube(pts, radii: Array(repeating: 0.0035, count: pts.count), sides: 6, seamTile: 0.1, material: iron, capEnd: true))
        }

        // Eyebrow dormer facing +Z, set on the slope at y = 1.1.
        let dy: Float = 1.1
        let dpos = V3(0, dy, rAt(dy) + 0.01)
        let drot = FA.q(-slopeDeg, FA.X)
        func local(_ p: V3) -> V3 { dpos + drot.act(p) }
        let arch = FC.archOutline(width: 0.42, spring: 0.2, pointed: false, steps: 7).map { V2($0.x, $0.y - 0.21) }
        // Frame box, dark sash behind the glass, glass and muntins.
        m.add(Prim.extrude(Shape2D.offset(arch, 0.045), depth: 0.16, bevel: 0.004, bevelSegments: 1, material: paint),
              Xform(translation: local(V3(0, 0, 0.0)), rotation: drot))
        m.add(Prim.extrude(arch, depth: 0.004, bevel: 0.001, bevelSegments: 1, material: "metal.enamel:18191C"),
              Xform(translation: local(V3(0, 0, 0.082)), rotation: drot))
        m.add(Prim.extrude(Shape2D.offset(arch, -0.004), depth: 0.004, bevel: 0.0008, bevelSegments: 1, material: "glass.pane"),
              Xform(translation: local(V3(0, 0, 0.087)), rotation: drot))
        FA.box(&m, V3(0.012, 0.4, 0.008), local(V3(0, -0.0, 0.09)), paint, r: 0.002, rot: drot)
        FA.box(&m, V3(0.42, 0.012, 0.008), local(V3(0, -0.03, 0.09)), paint, r: 0.002, rot: drot)
        FA.box(&m, V3(0.56, 0.036, 0.09), local(V3(0, -0.245, 0.07)), paint, r: 0.004, rot: drot)
        for sx: Float in [-1, 1] {
            FA.box(&m, V3(0.024, 0.3, 0.07), local(V3(sx * 0.255, -0.02, 0.05)), paint, r: 0.003, rot: drot)
        }
        // Eyebrow hood: crescent bargeboard and a slate-clad crescent over it, sweeping out over the sash.
        func crescent(_ ro: Float, _ ri: Float) -> [V2] {
            var pts: [V2] = [V2(ro, -0.12)]
            for j in 0...12 { let t = Float(j) / 12 * .pi; pts.append(V2(ro * cos(t), -0.01 + ro * sin(t))) }
            pts += [V2(-ro, -0.12), V2(-ri, -0.12)]
            for j in 0...12 { let t = (1 - Float(j) / 12) * .pi; pts.append(V2(ri * cos(t), -0.01 + ri * sin(t))) }
            pts.append(V2(ri, -0.12))
            return pts
        }
        m.add(Prim.extrude(crescent(0.31, 0.232), depth: 0.016, bevel: 0.003, bevelSegments: 1, material: paint),
              Xform(translation: local(V3(0, 0.0, 0.1)), rotation: drot * FA.q(-10, FA.X)))
        m.add(Prim.extrude(crescent(0.3, 0.24), depth: 0.012, bevel: 0.002, bevelSegments: 1, material: slate),
              Xform(translation: local(V3(0, 0.004, 0.114)), rotation: drot * FA.q(-10, FA.X)))
        // Painted leaf finial on the hood crown.
        m.add(Prim.extrude(Self.leaf(w: 0.05, h: 0.08), depth: 0.006, bevel: 0.0015, bevelSegments: 1, material: paint),
              Xform(translation: local(V3(0, 0.3, 0.125)), rotation: drot))

        groundAO(&m, height: 0.4, floor: 0.7)
        return LODModel(FC.place(m))
    }
}
