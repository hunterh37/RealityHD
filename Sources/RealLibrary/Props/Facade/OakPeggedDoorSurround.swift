import simd
import Foundation

/// Tudor oak door surround, 1.3 m wide, 2.5 m tall, 200 mm deep: two 160 mm oak jambs with a hollow chamfer along the
/// opening arris and stop chamfers, a 250 mm oak lintel tenoned over the jamb heads, carved four-centred spandrel
/// blocks with a roll moulding on the arch and a Tudor rose boss, draw-bored oak pegs at every joint (one replaced in
/// fresh oak) and a sloped sandstone threshold sill with a drip nose. Wear: silvered grain, shakes in the lintel,
/// splash-zone darkening at the jamb feet, worn dip in the sill.
public struct OakPeggedDoorSurround: RealAsset {
    public static let id = "oak-pegged-door-surround"
    public static let summary = "Tudor oak door surround 1.3 m x 2.5 m: chamfered jambs, four-centred head, pegged joints, sill."
    public static let tags = ["prop", "architecture", "facade", "trim", "wood"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 8, distance: 3.3)

    /// Clear opening width between the jambs (m).
    public var opening: Float = 0.98
    /// Oak for jambs, lintel and spandrels.
    public var oak: MaterialKey = "wood.oak"
    /// Silvered, weathered oak for splash zones and the sun side.
    public var aged: MaterialKey = "wood.weathered"
    /// Fresh oak of the replaced peg.
    public var sunSide: MaterialKey = "wood.lumber-oak"
    /// Dark bog-oak pegs.
    public var pegWood: MaterialKey = "wood.walnut"
    public var fresh: MaterialKey = "wood.endgrain-fresh"
    /// Threshold stone.
    public var stone: MaterialKey = "stone.limestone"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 1.3, H: Float = 2.5, D: Float = 0.18
        let hw = opening / 2, jw = (W - opening) / 2
        let sillH: Float = 0.1, spring: Float = 2.0, apex: Float = 2.25
        let plinthH: Float = 0.3
        let hc: Float = 0.035                                                    // hollow chamfer radius

        // Sloped threshold sill with a drip nose, worn dip and a mismatched replacement block.
        let sill: [V2] = [V2(0, 0), V2(D, 0), V2(D, 0.07), V2(D - 0.012, 0.082), V2(0.0, sillH)]
        FO5.colX(&m, sill, x0: -W / 2, x1: W / 2, stone, bevel: 0.003)
        FJ.slab(&m, V3(0.5, 0.0016, 0.1), V3(0.0, 0.0905, 0.1), "stone.limestone-sooted")
        FJ.slab(&m, V3(0.34, 0.0015, 0.1), V3(-0.31, 0.0952, 0.07), "stone.cast-stone")
        for e: Float in [-1, 1] {
            FA.box(&m, V3(0.0016, 0.07, 0.2), V3(e * 0.13 + 0.0, 0.045, D / 2), "stone.limestone-sooted", r: 0.0006)   // block joint
        }
        FJ.slab(&m, V3(W - 0.01, 0.006, 0.0012), V3(0, 0.022, D + 0.0004), "stone.limestone-sooted")                   // splash line

        // Jambs: hollow chamfer on the opening arris, stop chamfer at the foot and head.
        for e: Float in [-1, 1] {
            let x0 = e * hw, x1 = e * (hw + jw)
            let c = V2(x0, D)
            var sec: [V2] = [V2(x1, 0), V2(x1, D), V2(x0 + e * hc, D)]
            sec += FO5.arc(c: c, r: hc, from: e > 0 ? 0 : 180, to: e > 0 ? -90 : 270, steps: 5).dropFirst()
            sec.append(V2(x0, 0))
            FO5.colY(&m, sec, y0: sillH + plinthH - 0.002, y1: apex + 0.0, e > 0 ? sunSide : oak)
            // Sandstone padstone under each post, dressed with a weathered top and a mortar bed line.
            FA.box(&m, V3(jw, plinthH, D - 0.004), V3(e * (hw + jw / 2), sillH + plinthH / 2 - 0.001, D / 2), "stone.slate", r: 0.004)
            FA.box(&m, V3(jw, 0.006, D - 0.002), V3(e * (hw + jw / 2), sillH + plinthH - 0.002, D / 2), "stone.limestone-sooted", r: 0.002)
            FO5.patch(&m, V2(jw, 0.1), V2(e * (hw + jw / 2), sillH + 0.06), z: D - 0.004, "stone.limestone-sooted")
            FO5.patch(&m, V2(0.05, 0.14), V2(e * (hw + jw / 2 - 0.03), sillH + 0.2), z: D - 0.004, "stone.limestone")
            // Stop chamfers: lamb's-tongue cut at the foot and the head of the hollow chamfer.
            FA.box(&m, V3(0.04, 0.05, 0.04), V3(e * (hw + 0.02), sillH + plinthH + 0.12, D - 0.02), oak, r: 0.004, rot: FA.q(45, FA.Y))
            FA.box(&m, V3(0.04, 0.05, 0.04), V3(e * (hw + 0.02), apex - 0.18, D - 0.02), oak, r: 0.004, rot: FA.q(45, FA.Y))
            // Tenon shoulders visible at the jamb head (shadow gap to the lintel).
            FJ.slab(&m, V3(jw, 0.0022, 0.002), V3(e * (hw + jw / 2), apex + 0.0012, D + 0.0004), "wood.deadwood")
        }

        // Lintel with a hollow chamfer along the lower front edge.
        var lin: [V2] = [V2(0, apex), V2(D - hc, apex)]
        lin += FO5.arc(c: V2(D, apex), r: hc, from: 180, to: 90 + 0, steps: 5).dropFirst().map { V2($0.x, $0.y) }
        lin += [V2(D, H), V2(0, H)]
        FO5.colX(&m, lin, x0: -W / 2, x1: W / 2, oak, bevel: 0.002)

        // Four-centred arch: corner arcs radius ra about the springing, large arcs meeting at the apex.
        let rise = apex - spring, ra: Float = 0.22
        let cxs = hw - ra
        // Large arc radius from tangency: cxs^2 + (rise - R)^2 = (R - ra)^2.
        let R = (cxs * cxs + rise * rise - ra * ra) / (2 * (rise - ra))
        let bigC = V2(0, apex - R)
        let tAng = atan2(spring - bigC.y, cxs) * 180 / .pi
        func archHalf(_ e: Float) -> [V2] {
            var pts: [V2] = []
            let small = FO5.arc(c: V2(e * cxs, spring), r: ra, from: e > 0 ? 0 : 180, to: e > 0 ? tAng : 180 - tAng, steps: 6)
            pts += small
            let big = FO5.arc(c: bigC, r: R, from: e > 0 ? tAng : 180 - tAng, to: 90, steps: 8).dropFirst()
            pts += big
            return pts
        }
        for e: Float in [-1, 1] {
            var out = archHalf(e)
            out.append(V2(e * hw, apex))
            FM.prism(&m, out, front: D - 0.002, depth: D - 0.002, oak, bevel: 0.002)
            // Roll moulding on the arch edge, set into the face.
            let path = archHalf(e).map { V3($0.x, $0.y, D - 0.004) }
            FA.path(&m, path, r: 0.0085, oak, sides: 8)
            // Tudor rose boss in the spandrel: central dome, five petals, bud.
            let cx = e * (hw - 0.115), cy = apex - 0.075
            FA.cylZ(&m, r: 0.038, h: 0.01, at: V3(cx, cy, D - 0.004), oak, bevel: 0.003, segments: 16)
            for k in 0..<5 {
                let a = Float(k) / 5 * 2 * .pi + .pi / 2
                m.add(Prim.superellipsoid(V3(0.036, 0.036, 0.014), exponent: 2, subdivisions: 4, material: oak),
                      Xform(translation: V3(cx + cos(a) * 0.024, cy + sin(a) * 0.024, D + 0.004)))
            }
            FC.bead(&m, r: 0.011, at: V3(cx, cy, D + 0.009), "wood.endgrain", sub: 4)
            // Pegs through the spandrel into the jamb and lintel.
            for (px, py) in [(hw + 0.08, apex - 0.1), (hw + 0.08, spring + 0.02)] as [(Float, Float)] {
                FO5.peg(&m, at: V3(e * px, py, D - 0.002), normal: FA.Z, r: 0.011, h: 0.012, pegWood)
            }
        }

        // Cast-iron pintles driven into the right jamb, with the vertical pin and a rust bloom below.
        for y in [0.62, 1.7] as [Float] {
            FA.cylX(&m, r: 0.011, h: 0.05, at: V3(hw - 0.046, y, D * 0.42), "metal.cast-iron", bevel: 0.002, segments: 10)
            FA.box(&m, V3(0.008, 0.07, 0.07), V3(hw - 0.001, y, D * 0.42), "metal.cast-iron", r: 0.002)
            m.add(Prim.cylinder(radius: 0.0085, height: 0.085, bevel: 0.0015, segments: 10, bevelSegments: 1, material: "metal.cast-iron"),
                  Xform(translation: V3(hw - 0.046, y - 0.02, D * 0.42)))
            FJ.slab(&m, V3(0.006, 0.12, 0.012), V3(hw + 0.0006, y - 0.09, D * 0.42), "metal.rust")
        }
        // Moss and splash staining on the padstones and sill, damp darkening at the oak feet.
        for e: Float in [-1, 1] {
            let px = e * (hw + jw / 2)
            for _ in 0..<4 {
                FO5.patch(&m, V2(rng.float(0.03...0.07), rng.float(0.02...0.06)), V2(px + rng.float(-0.05...0.05), sillH + rng.float(0.01...0.12)), z: D - 0.004, "stone.granite-moss", rot: rng.float(-20...20))
            }
            FO5.patch(&m, V2(jw - 0.02, 0.07), V2(px, sillH + plinthH + 0.045), z: D, "wood.deadwood")
            FO5.patch(&m, V2(jw - 0.05, 0.07), V2(px, sillH + plinthH + 0.12), z: D, aged)
        }
        for _ in 0..<5 {
            FO5.patch(&m, V2(rng.float(0.04...0.12), rng.float(0.012...0.025)), V2(rng.float(-0.55...0.55), rng.float(0.05...0.095)), z: D, "stone.granite-moss", rot: rng.float(-10...10))
        }
        // Weathered top face of the lintel (silvered by rain) and a lead-grey drip cap line.
        FJ.slab(&m, V3(W - 0.01, 0.0016, D - 0.03), V3(0, H + 0.0004, D / 2), aged)
        // Draw-bored pegs: pairs through each lintel/jamb mortise and tenon, heads offset a hair in x.
        for e: Float in [-1, 1] {
            for (i, y) in [apex + 0.07, apex + 0.18].enumerated() {
                let draw: Float = (i == 0 ? 0.0025 : -0.0025)
                let mat: MaterialKey = (e > 0 && i == 1) ? fresh : pegWood
                FO5.peg(&m, at: V3(e * (hw + jw / 2) + draw, y, D - 0.002), normal: FA.Z, r: 0.0115, h: 0.016, mat)
                // Peg end sawn flush on the back would show from the side; chamfer ring at the head.
                FA.cylZ(&m, r: 0.0132, h: 0.0016, at: V3(e * (hw + jw / 2) + draw, y, D - 0.0016), "wood.deadwood", bevel: 0.0004, segments: 8)
            }
        }
        // Lintel joint end-grain: the tenon tip shows on the jamb outer face as a darker square.
        for e: Float in [-1, 1] {
            FJ.slab(&m, V3(0.0016, 0.07, 0.07), V3(e * (W / 2 + 0.0004), apex + 0.07, D / 2), "wood.endgrain")
        }

        // Weathering: silvered streaks, shakes, splash darkening, a rain-washed top.
        for e: Float in [-1, 1] {
            for _ in 0..<7 {
                FO5.patch(&m, V2(rng.float(0.004...0.011), rng.float(0.06...0.32)), V2(e * (hw + jw / 2) + rng.float(-0.05...0.05), rng.float(0.2...1.9)),
                         z: D, rng.chance(0.6) ? aged : "wood.deadwood")
            }
            for _ in 0..<5 {
                FO5.patch(&m, V2(rng.float(0.004...0.008), rng.float(0.04...0.12)), V2(e * (hw + jw / 2) + rng.float(-0.05...0.05), rng.float(0.12...0.4)), z: D, "wood.deadwood")
            }
        }
        for _ in 0..<3 {
            FO5.patch(&m, V2(0.0022, rng.float(0.08...0.2)), V2(rng.float(-0.5...0.5), apex + 0.125), z: D, "wood.deadwood")          // shakes
        }
        FO5.patch(&m, V2(0.5, 0.008), V2(-0.1, H - 0.012), z: D, aged)
        // Gap line between lintel and spandrel blocks, and the centre joint of the two spandrels.
        FJ.slab(&m, V3(0.0022, rise, 0.001), V3(0, apex - rise / 2 + 0.0, D + 0.0003), "wood.deadwood")

        groundAO(&m, height: 0.25, floor: 0.6)
        return LODModel(FC.place(m))
    }
}
