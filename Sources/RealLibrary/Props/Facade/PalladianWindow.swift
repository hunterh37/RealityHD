import simd
import Foundation

/// Georgian Palladian (Serliana) window, 1.8 x 2.6 m: a round-headed centre sash between two square-headed
/// sidelights. Tuscan pilaster pairs (plinth, torus base, shaft, echinus capital) divide the lights and carry
/// two impost entablatures (architrave fascias, frieze, dentil course, cornice) from which the centre arch
/// springs. The arch has a radiating-bar fanlight, a moulded archivolt and a keystone; a full-width head
/// entablature caps the window and a limestone sill with a drip nose carries it. Painted pine with sun-worn
/// lower rails, brass sash lock and lifts, sooted sill.
public struct PalladianWindow: RealAsset {
    public static let id = "palladian-window"
    public static let summary = "Georgian Palladian window, 1.8 x 2.6 m: arched centre sash and two sidelights, pilasters, impost entablatures, keystone, stone sill."
    public static let tags = ["prop", "architecture", "facade", "window", "trim", "wood", "stone"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 8, distance: 2.4)

    /// Overall width and height (m).
    public var width: Float = 1.8
    public var height: Float = 2.6
    /// White Georgian trim paint.
    public var trim: MaterialKey = "wood.painted-exterior:EFEBE0"
    /// Sash paint, scuffed along rails and stiles.
    public var sashPaint: MaterialKey = "wood.painted-shaker-worn:E6E1D2"
    /// Grimy paint near the sill where rain splash and soot land.
    public var splash: MaterialKey = "wood.painted-shaker-worn:B7B09E"
    public var sill: MaterialKey = "stone.limestone-sooted"
    public var glass: MaterialKey = "glass.clear"
    public var brass: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, H = height
        let hw = W / 2
        let ySill: Float = 0.06, y0: Float = 0.09          // sill top, bottom of lights
        let yShaftTop: Float = 1.63, yImpost: Float = 1.70, ySpring: Float = 1.92
        let rc: Float = 0.35                                // centre arch radius (opening 0.70 m)
        let xCas: Float = 0.81, xPil: Float = 0.35, pw: Float = 0.06   // casing inner face, centre opening edge, pilaster width
        let yHead: Float = 2.40

        // Limestone sill: weathered slope with a rounded nose and drip lip.
        FA.run(&m, [V2(0, 0), V2(0.205, 0), V2(0.205, 0.01), V2(0.22, 0.016), V2(0.22, 0.036), V2(0.14, 0.057), V2(0, ySill)],
               length: W, at: .zero, sill, bevel: 0.003)
        FA.box(&m, V3(W - 0.14, 0.012, 0.03), V3(0, ySill + 0.004, 0.06), "stone.limestone", r: 0.003)       // clean stool course under the sashes

        // Casing boards with bead mouldings, plus nail heads.
        for e: Float in [-1, 1] {
            FA.box(&m, V3(hw - xCas, yHead - ySill, 0.04), V3(e * (xCas + hw) / 2, (ySill + yHead) / 2, 0.02), trim, r: 0.002)
            FA.box(&m, V3(hw - xCas, 0.12, 0.046), V3(e * (xCas + hw) / 2, ySill + 0.06, 0.023), splash, r: 0.002)   // grimy casing foot
            for y in [0.5, 1.0, 1.5, 2.0] as [Float] {
                rivet(&m, at: V3(e * (xCas + hw) / 2, y, 0.04), normal: FA.Z, radius: 0.0032, segments: 6, material: "metal.wrought-iron")
            }
        }
        // Sidelight openings: bead mouldings and sashes.
        let swid = xCas - (xPil + 2 * pw + 0.02)             // 0.32
        for e: Float in [-1, 1] {
            let cx = e * (xCas + xPil + 2 * pw + 0.02) / 2, cy = (y0 + yImpost) / 2
            FJ.mouldedFrame(&m, cx: cx, cy: cy, w: swid, h: yImpost - y0, z: 0.036, profile: FJ.beadProfile(0.011), trim, r: 0.004)
            FJ.sash(&m, cx: cx, cy: cy, w: swid - 0.014, h: yImpost - y0 - 0.014, z0: 0.052, cols: 2, rows: 6, sashPaint, glass: glass)
            FA.box(&m, V3(swid - 0.014, 0.06, 0.042), V3(cx, y0 + 0.037, 0.073), splash, r: 0.002)        // sun-worn bottom rail
        }

        // Tuscan pilaster pairs between the lights.
        func pilaster(_ cx: Float) {
            FA.box(&m, V3(pw + 0.024, 0.085, 0.118), V3(cx, ySill + 0.0425, 0.059), splash, r: 0.003)                    // plinth block
            FA.run(&m, [V2(0, 0), V2(0.114, 0), V2(0.114, 0.008), V2(0.122, 0.014), V2(0.122, 0.022), V2(0.11, 0.03), V2(0.102, 0.034), V2(0, 0.034)],
                   length: pw + 0.02, at: V3(cx, ySill + 0.085, 0), trim, bevel: 0.0015)                                 // torus base
            let b = ySill + 0.12, hs = yShaftTop - b
            FA.box(&m, V3(pw, hs, 0.1), V3(cx, b + hs / 2, 0.05), trim, r: 0.002)
            FA.box(&m, V3(pw - 0.02, hs - 0.14, 0.004), V3(cx, b + hs / 2, 0.102), trim, r: 0.001)                       // fillet panel on shaft
            FA.run(&m, [V2(0, 0), V2(0.1, 0), V2(0.1, 0.008), V2(0.106, 0.012), V2(0.106, 0.016), V2(0.1, 0.02), V2(0.124, 0.05), V2(0.128, 0.052),
                        V2(0.128, 0.07), V2(0, 0.07)],
                   length: pw + 0.016, at: V3(cx, yShaftTop, 0), trim, bevel: 0.0015)                                    // necking, echinus, abacus
        }
        for e: Float in [-1, 1] {
            pilaster(e * (xPil + pw / 2))
            pilaster(e * (xPil + pw + 0.02 + pw / 2))
            FA.box(&m, V3(0.02, yShaftTop - ySill, 0.06), V3(e * (xPil + pw + 0.01), (ySill + yShaftTop) / 2, 0.03), splash, r: 0.002)   // mullion between the pair
        }

        // Impost entablature over each sidelight: two architrave fascias, frieze, dentil course, cornice.
        for e: Float in [-1, 1] {
            let len = xCas - xPil, cx = e * (xCas + xPil) / 2
            FA.box(&m, V3(len, 0.03, 0.11), V3(cx, yImpost + 0.015, 0.055), trim, r: 0.002)
            FA.box(&m, V3(len, 0.03, 0.118), V3(cx, yImpost + 0.045, 0.059), trim, r: 0.002)
            FA.box(&m, V3(len, 0.012, 0.126), V3(cx, yImpost + 0.066, 0.063), trim, r: 0.003)
            FA.box(&m, V3(len, 0.08, 0.11), V3(cx, yImpost + 0.112, 0.055), trim, r: 0.002)                                // frieze
            let nd = Int(len / 0.034)
            for i in 0..<nd {
                let x = cx - len / 2 + (Float(i) + 0.5) * len / Float(nd)
                FJ.slab(&m, V3(0.016, 0.026, 0.03), V3(x, yImpost + 0.165, 0.125), trim)
            }
            FA.run(&m, [V2(0, 0), V2(0.14, 0), V2(0.14, 0.006), V2(0.15, 0.012), V2(0.15, 0.02), V2(0.17, 0.026), V2(0.17, 0.04), V2(0.165, 0.045),
                        V2(0.15, 0.052), V2(0.12, 0.055), V2(0, 0.055)],
                   length: len, at: V3(cx, yImpost + 0.165, 0), trim, bevel: 0.0015)
        }

        // Centre arch: sash frame, fanlight bars, glazing, archivolt and keystone.
        let iw = 2 * rc - 0.012
        let outline = FC.archOutline(width: iw - 0.08, spring: ySpring - y0 - 0.04, pointed: false, steps: 20)
        m.add(Prim.extrude(outline, depth: 0.004, bevel: 0.0008, bevelSegments: 1, material: glass), Xform(translation: V3(0, y0 + 0.04, 0.07)))
        for e: Float in [-1, 1] {
            FA.box(&m, V3(0.04, ySpring - y0, 0.04), V3(e * (rc - 0.026), (y0 + ySpring) / 2, 0.07), sashPaint, r: 0.002)
        }
        FA.box(&m, V3(iw, 0.062, 0.04), V3(0, y0 + 0.031, 0.07), splash, r: 0.002)                                       // bottom rail
        let archFrame: [V3] = (0...24).map { i in let a = Float(i) / 24 * .pi; return V3(cos(a) * (rc - 0.026), ySpring + sin(a) * (rc - 0.026), 0.05) }
        m.add(Prim.sweep([V2(0, -0.02), V2(0.04, -0.02), V2(0.04, 0.02), V2(0, 0.02)], along: archFrame, up: FA.Z, caps: true, grainAlongPath: true,
                         material: sashPaint))
        // Meeting rail (double-hung), vertical bars and horizontal bars.
        let ym: Float = 1.035
        FA.box(&m, V3(iw, 0.046, 0.046), V3(0, ym, 0.071), sashPaint, r: 0.002)
        for x in [-0.115, 0.115] as [Float] { FA.box(&m, V3(0.016, ySpring - y0 - 0.06, 0.032), V3(x, (y0 + 0.06 + ySpring) / 2, 0.07), sashPaint, r: 0.0015) }
        for k in 1...5 where k != 3 {
            let y = 0.15 + Float(k) * 0.295
            FA.box(&m, V3(iw - 0.07, 0.016, 0.032), V3(0, y, 0.07), sashPaint, r: 0.0015)
        }
        FJ.radial(&m, cx: 0, cy: ySpring, z: 0.07, angles: [22.5, 45, 67.5, 90, 112.5, 135, 157.5], r0: 0.045, r1: rc - 0.045, bar: 0.014, depth: 0.03, sashPaint)
        for rr in [0.13, 0.23] as [Float] {
            let ring: [V3] = (0...20).map { i in let a = Float(i) / 20 * .pi; return V3(cos(a) * rr, ySpring + sin(a) * rr, 0.07) }
            m.add(Prim.sweep([V2(-0.014, -0.007), V2(0.014, -0.007), V2(0.014, 0.007), V2(-0.014, 0.007)], along: ring, up: FA.Z, caps: true, material: sashPaint))
        }
        FA.cylZ(&m, r: 0.034, h: 0.034, at: V3(0, ySpring, 0.056), sashPaint, bevel: 0.004, segments: 20)               // fan hub
        // Brass sash lock on the meeting rail and two bar lifts on the bottom rail.
        FA.box(&m, V3(0.07, 0.022, 0.004), V3(0, ym, 0.096), brass, r: 0.001)
        FA.box(&m, V3(0.034, 0.012, 0.007), V3(0.012, ym + 0.014, 0.1), brass, r: 0.002, rot: FA.q(12, FA.Z))
        for x in [-0.025, 0.025] as [Float] { rivet(&m, at: V3(x, ym, 0.098), normal: FA.Z, radius: 0.0033, segments: 6, material: "metal.screw-zinc") }
        for x in [-0.2, 0.2] as [Float] {
            FA.box(&m, V3(0.05, 0.006, 0.008), V3(x, y0 + 0.07, 0.094), brass, r: 0.002)
            FA.box(&m, V3(0.004, 0.014, 0.012), V3(x, y0 + 0.062, 0.097), brass, r: 0.001)
        }
        // Archivolt (ovolo band) springing from the impost cornice; keystone at the crown.
        let rm = rc + 0.036
        let arch: [V3] = (0...28).map { i in let a = Float(i) / 28 * .pi; return V3(cos(a) * rm, ySpring + sin(a) * rm, 0.04) }
        m.add(Prim.sweep(FJ.ovoloProfile(width: 0.072, height: 0.055), along: arch, up: FA.Z, caps: true, grainAlongPath: true, material: trim))
        let yk = ySpring + rc - 0.015
        let key = Shape2D.rounded([V2(-0.036, 0), V2(0.036, 0), V2(0.056, 0.148), V2(-0.056, 0.148)], radius: 0.003, segments: 1)
        m.add(Prim.extrude(key, depth: 0.1, bevel: 0.003, bevelSegments: 1, material: trim), Xform(translation: V3(0, yk, 0.05)))
        FA.box(&m, V3(0.118, 0.012, 0.108), V3(0, yk + 0.154, 0.054), trim, r: 0.002)                                   // keystone cap
        FA.box(&m, V3(0.05, 0.1, 0.004), V3(0, yk + 0.075, 0.1), trim, r: 0.001)                                       // keystone face panel

        // Spandrel infill above the impost entablatures and around the arch, with a raised panel on each side.
        for e: Float in [-1, 1] {
            var sp: [V2] = [V2(rc + 0.072, ySpring), V2(xCas, ySpring), V2(xCas, yHead), V2(0, yHead)]
            for i in 0...14 {   // arch extrados from the crown down to the impost
                let a = (.pi / 2) * (1 - Float(i) / 14)
                sp.append(V2(cos(a) * (rc + 0.072), ySpring + sin(a) * (rc + 0.072)))
            }
            sp = Shape2D.deduped(sp).map { V2($0.x * e, $0.y) }
            if e < 0 { sp.reverse() }
            m.add(Prim.extrude(sp, depth: 0.03, bevel: 0.002, bevelSegments: 1, material: splash), Xform(translation: V3(0, 0, 0.015)))
            FJ.raisedPanel(&m, cx: e * 0.62, cy: 2.17, w: 0.3, h: 0.34, z0: 0.03, rise: 0.012, bevelRun: 0.024, trim)
            FJ.mouldedFrame(&m, cx: e * 0.62, cy: 2.17, w: 0.33, h: 0.37, z: 0.03, profile: FJ.ovoloProfile(width: 0.014, height: 0.016), trim, r: 0.006)
        }

        // Head entablature: architrave, frieze, dentils, cornice across the full width.
        FA.box(&m, V3(W - 0.04, 0.03, 0.062), V3(0, yHead + 0.015, 0.031), trim, r: 0.002)
        FA.box(&m, V3(W - 0.04, 0.03, 0.072), V3(0, yHead + 0.045, 0.036), trim, r: 0.002)
        FA.box(&m, V3(W - 0.02, 0.08, 0.07), V3(0, yHead + 0.1, 0.035), trim, r: 0.002)
        let nd = Int((W - 0.04) / 0.034)
        for i in 0..<nd {
            let x = -(W - 0.04) / 2 + (Float(i) + 0.5) * (W - 0.04) / Float(nd)
            FJ.slab(&m, V3(0.016, 0.024, 0.032), V3(x, yHead + 0.152, 0.086), trim)
        }
        FA.run(&m, [V2(0, 0), V2(0.1, 0), V2(0.1, 0.006), V2(0.13, 0.012), V2(0.13, 0.02), V2(0.17, 0.028), V2(0.17, 0.046), V2(0.16, 0.051),
                    V2(0.12, 0.052), V2(0, 0.052)],
               length: W, at: V3(0, yHead + 0.14, 0), trim, bevel: 0.0015)
        FA.box(&m, V3(W - 0.06, 0.012, 0.18), V3(0, H - 0.006, 0.09), "wood.painted-exterior:E3DED2", r: 0.002)       // lead-flashed cap board

        // Weathering: paint chips on the casing, plinths and bottom rails.
        var chipRng = rng.fork(5)
        FJ.chips(&m, spots: [V3(0.855, 0.35, 0), V3(-0.855, 0.62, 0), V3(0.855, 1.35, 0), V3(-0.855, 2.1, 0)], face: 0.04, "wood.weathered", rng: &chipRng, each: 3)
        FJ.chips(&m, spots: [V3(0.2, y0 + 0.037, 0), V3(-0.12, y0 + 0.03, 0)], face: 0.091, "wood.weathered", rng: &chipRng, each: 3)
        groundAO(&m, height: 0.14, floor: 0.7)
        return LODModel(FA.centerZ(m))
    }
}
