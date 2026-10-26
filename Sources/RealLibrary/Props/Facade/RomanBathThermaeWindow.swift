import simd
import Foundation

/// Roman Revival thermae window, 2.4 x 2.2 m: semicircular lunette on straight jambs split by two stone mullions into
/// three lights. Ring of 13 wedge voussoirs with a projecting keystone, coursed ashlar piers, moulded impost caps,
/// ovolo archivolt, riveted iron glazing bars with a radial fan and ring bar, drip sill with soot runs.
/// Wall plane at z = 0, piece projecting toward +Z.
public struct RomanBathThermaeWindow: RealAsset {
    public static let id = "roman-bath-thermae-window"
    public static let summary = "Roman Revival thermae window, 2.4 m: semicircular lunette, two stone mullions, wedge voussoirs, keystone, iron glazing bars, sill."
    public static let tags = ["prop", "architecture", "facade", "trim", "stone", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 10, distance: 4.2)

    /// Half width of the clear opening in meters.
    public var halfOpening: Float = 0.8
    /// Height of the springing line above the base in meters.
    public var spring: Float = 0.97
    /// Principal ashlar and voussoirs.
    public var stone: MaterialKey = "stone.limestone:D6CDB6"
    /// Contrasting stone for imposts, keystone and sill.
    public var accent: MaterialKey = "stone.sandstone"
    /// Soot and weathered joints.
    public var soot: MaterialKey = "stone.limestone-sooted"
    /// Wrought iron glazing bars.
    public var iron: MaterialKey = "metal.wrought-iron:2B2A27"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hw = halfOpening, cy = spring, sillH: Float = 0.12
        let band: Float = 0.4
        let rOut = hw + band
        let stoneAlt: [MaterialKey] = [stone, "stone.limestone:CBC2AA", "stone.limestone:DDD5BF", "stone.limestone-sooted"]

        // Voussoir ring: 13 wedges, keystone in the middle (index 6) projects further.
        FO.voussoirs(&m, c: V2(0, cy), rIn: hw + 0.04, rOut: rOut, from: 0, to: 180, count: 13, z0: 0, depth: 0.22, gap: 0.005, bevel: 0.003) { i in
            i == 6 ? accent : stoneAlt[(i * 7 + 1) % 4]
        }
        // Keystone block standing proud with a moulded cap.
        let ky = cy + hw + band * 0.5
        m.add(Prim.extrude([V2(-0.07, cy + hw + 0.03), V2(0.07, cy + hw + 0.03), V2(0.09, cy + rOut + 0.02), V2(-0.09, cy + rOut + 0.02)],
                           depth: 0.06, bevel: 0.004, bevelSegments: 1, material: accent), Xform(translation: V3(0, 0, 0.24)))
        FA.box(&m, V3(0.2, 0.025, 0.09), V3(0, cy + rOut + 0.03, 0.255), accent, r: 0.004)
        m.add(Prim.superellipsoid(V3(0.07, 0.11, 0.035), exponent: 2.4, subdivisions: 5, material: accent), Xform(translation: V3(0, ky, 0.268)))

        // Archivolt moulding at the opening edge: fillet, ovolo, fillet (profile x = projection, y = outward).
        var prof: [V2] = [V2(0, 0), V2(0.2, 0), V2(0.2, 0.012)]
        for i in 1...6 {
            let a = Float(i) / 6 * (.pi / 2)
            prof.append(V2(0.2 + 0.05 * sin(a), 0.012 + 0.05 * (1 - cos(a))))
        }
        prof += [V2(0.25, 0.075), V2(0.22, 0.075), V2(0.22, 0.09), V2(0, 0.09)]
        prof = Shape2D.deduped(prof)
        let arch = FC.archPath(width: hw * 2, spring: cy - sillH, pointed: false, z: 0, steps: 26).map { V3($0.x, $0.y + sillH, 0) }
        m.add(Prim.sweep(prof, along: arch, up: V3(0, 0, 1), material: accent))

        // Coursed ashlar piers either side of the opening, alternating long and short blocks.
        let nCourse = 4
        let courseH = (cy - sillH) / Float(nCourse)
        for s: Float in [-1, 1] {
            for k in 0..<nCourse {
                let y0 = sillH + Float(k) * courseH
                let long = k % 2 == 0
                let wOut: Float = long ? 0.26 : 0.18
                let wIn: Float = band - wOut
                FA.box(&m, V3(wIn - 0.004, courseH - 0.005, 0.2), V3(s * (hw + wIn / 2), y0 + courseH / 2, 0.1), stoneAlt[(k + (s > 0 ? 1 : 0)) % 4], r: 0.003)
                FA.box(&m, V3(wOut - 0.004, courseH - 0.005, 0.22), V3(s * (hw + wIn + wOut / 2), y0 + courseH / 2, 0.11), stoneAlt[(k * 3 + 2) % 4], r: 0.003)
            }
            // Impost block: moulded cap over a plinth block, brass bolt heads.
            let x = s * (hw + band / 2)
            FA.box(&m, V3(band, 0.09, 0.2), V3(x, cy - 0.045, 0.1), accent, r: 0.004)
            let cap: [V2] = [V2(0, 0), V2(0.2, 0), V2(0.2, 0.012), V2(0.235, 0.024), V2(0.235, 0.04), V2(0.22, 0.05), V2(0, 0.05)]
            FA.run(&m, cap, length: band, at: V3(x, cy, 0), accent, bevel: 0.002)
            for (dx, dy) in [(Float(-0.1), Float(-0.03)), (0.1, -0.03), (-0.1, -0.07), (0.1, -0.07)] {
                let p = V3(x + dx, cy + dy, 0.201)
                m.add(Prim.torus(major: 0.0085, minor: 0.0022, segments: 10, sides: 4, material: "metal.brass-aged"),
                      Xform(translation: p, rotation: FA.q(90, FA.X)))
                FC.bead(&m, r: 0.0055, at: p + V3(0, 0, 0.002), "metal.brass-aged", sub: 3)
            }
        }
        // Plinth course below the piers.
        FA.box(&m, V3(2 * rOut, 0.02, 0.24), V3(0, sillH + 0.01, 0.12), soot, r: 0.003)

        // Sill: weathered slab, sloped top, drip groove.
        let sill: [V2] = [V2(0, 0), V2(0.25, 0), V2(0.25, 0.016), V2(0.285, 0.016), V2(0.285, 0.05), V2(0.2, sillH), V2(0, sillH)]
        FA.run(&m, sill, length: 2 * rOut, at: V3(0, 0, 0), accent, bevel: 0.002)
        FA.box(&m, V3(2 * hw, 0.003, 0.28), V3(0, sillH + 0.0005, 0.14), "stone.limestone:6A6454", r: 0.001)

        // Glazing: one glass sheet recessed in the reveal, three lights, iron bars riveted at the crossings.
        let outline = FC.archOutline(width: hw * 2 - 0.02, spring: cy - sillH, pointed: false, steps: 24)
        m.add(Prim.extrude(outline, depth: 0.008, bevel: 0.0005, bevelSegments: 1, material: "glass.tinted"),
              Xform(translation: V3(0, sillH + 0.005, 0.07)))
        let barZ: Float = 0.085
        for s: Float in [-1, 1] {
            let x = s * hw / 3
            let top = cy + sqrt(hw * hw - x * x)
            // Stone mullion with a moulded front roll and a square-section iron saddle bar.
            FA.box(&m, V3(0.1, top - sillH, 0.14), V3(x, (top + sillH) / 2, 0.07), accent, r: 0.01)
            FA.rod(&m, V3(x, sillH + 0.005, 0.15), V3(x, top, 0.15), r: 0.026, accent, sides: 12)
            FA.box(&m, V3(0.03, top - sillH, 0.012), V3(x, (top + sillH) / 2, 0.146), accent, r: 0.003)
        }
        // Impost bar across the springing line and the horizontal lattice in the lower lights.
        FA.box(&m, V3(2 * hw, 0.04, 0.05), V3(0, cy, barZ), accent, r: 0.006)
        let lights: [Float] = [-2 * hw / 3, 0, 2 * hw / 3]
        for lx in lights {
            let w = 2 * hw / 3 - 0.1
            for k in 1...3 {
                let y = sillH + (cy - sillH) * Float(k) / 4
                FA.box(&m, V3(w, 0.014, 0.014), V3(lx, y, barZ + 0.005), iron, r: 0.002)
                for q in 0..<2 {
                    let rx = lx + (q == 0 ? -1 : 1) * w * 0.38
                    FC.bead(&m, r: 0.0065, at: V3(rx, y, barZ + 0.013), iron, sub: 2)
                }
            }
            for q in 1...2 {
                let vx = lx - w / 2 + w * Float(q) / 3
                FA.box(&m, V3(0.012, cy - sillH - 0.04, 0.012), V3(vx, (cy + sillH) / 2, barZ + 0.005), iron, r: 0.002)
            }
        }
        // Lunette: radial bars fanning from the centre, one ring bar, perimeter frame.
        for a in [Float(36), 72, 108, 144] {
            let r = a * .pi / 180
            FA.rod(&m, V3(0, cy, barZ + 0.004), V3(cos(r) * (hw - 0.008), cy + sin(r) * (hw - 0.008), barZ + 0.004), r: 0.007, iron, sides: 8)
        }
        let ring = FO.ellipse(c: V2(0, cy), rx: 0.5, ry: 0.5, from: 8, to: 172, steps: 20, z: barZ + 0.004)
        FA.path(&m, ring, r: 0.007, iron, sides: 8)
        let frame = FC.archPath(width: hw * 2 - 0.02, spring: cy - sillH, pointed: false, z: barZ + 0.003, steps: 24)
            .map { V3($0.x * 0.995, $0.y + sillH, $0.z) }
        FA.path(&m, frame, r: 0.012, iron, sides: 8)
        FC.bead(&m, r: 0.016, at: V3(0, cy, barZ + 0.012), "metal.brass-aged", sub: 4)

        // Weathering: soot and lime runs from joints, one chipped arris at the sill end.
        for _ in 0..<10 {
            let a = rng.float(0.15...2.99)
            let rc = hw + band * 0.5
            FO.streak(&m, x: cos(a) * rc, top: cy + sin(a) * rc, w: 0.022, h: rng.float(0.05...0.16), z: 0.22, "stone.limestone:7E7766")
        }
        for s: Float in [-1, 1] {
            FO.streak(&m, x: s * (hw + 0.05), top: sillH + 0.6, w: 0.03, h: 0.5, z: 0.22, "stone.limestone:8A826F")
            FO.streak(&m, x: s * (hw + 0.33), top: cy - 0.1, w: 0.05, h: 0.55, z: 0.22, "stone.limestone:6F685A")
            // Rust bleed from the lowest iron bar onto the sill.
            FO.streak(&m, x: s * 0.5, top: sillH + 0.06, w: 0.02, h: 0.05, z: 0.27, "metal.rust")
        }
        // Soot band along the sill front and under the impost caps.
        FA.box(&m, V3(2 * hw, 0.03, 0.002), V3(0, sillH / 2, 0.2515), "stone.limestone:5E5849", r: 0.0005)
        for s: Float in [-1, 1] {
            FA.box(&m, V3(band, 0.025, 0.002), V3(s * (hw + band / 2), cy - 0.1, 0.2015), "stone.limestone:5E5849", r: 0.0005)
        }

        groundAO(&m, height: 0.12, floor: 0.88)
        return LODModel(FA.centerZ(FC.seatY(m)))
    }
}
