import simd
import Foundation

/// Green roof sedum tray: Contemporary modular tray, 1.0 m square and 0.15 m tall. A 3 mm aluminium tray
/// (rolled lip, stiffening rib grid, drain slots, corner brackets with bolts, rivets) holds a molded drainage
/// cup sheet, filter fabric and a mineral growing medium with a gravel firebreak border. One front corner is
/// cut away to show the layers. The mat is a patchwork of ruddy, glaucous, golden and green sedum pillows with
/// moss cushions and flowering stalks. Soil splash, white oxidation spots and algae weather the aluminium.
public struct GreenRoofSedumTray: RealAsset {
    public static let id = "green-roof-sedum-tray"
    public static let summary = "Green roof sedum tray, 1.0 m square: aluminium tray with drain cups, substrate and mixed sedum, moss and flower stalks."
    public static let tags = ["prop", "architecture", "facade", "roofline", "landscaping", "garden"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 32, distance: 1.7)

    /// Outer width and depth in meters.
    public var width: Float = 1.0
    /// Tray wall height in meters.
    public var wallHeight: Float = 0.1
    /// Cutaway corner size in meters (0 for a closed tray).
    public var cutaway: Float = 0.3
    /// Tray aluminium.
    public var aluminium: MaterialKey = "metal.powdercoat:4D5458"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, H = wallHeight
        let lipOut: Float = 0.014, wallT: Float = 0.003
        let e = W / 2 - lipOut                      // outer face of the wall
        let iw = e - wallT                          // inner face of the wall
        let yTop: Float = 0.088                     // substrate surface
        let yFloor: Float = 0.003
        let cut = cutaway
        let cx0 = iw - cut, cz0 = iw - cut          // cutaway: x > cx0 and z > cz0 (front right corner)
        func inCut(_ x: Float, _ z: Float, _ pad: Float = 0) -> Bool { cut > 0 && x > cx0 - pad && z > cz0 - pad }

        // Walls with an outward rolled lip, built once facing +Z then turned to each side.
        let body: [V2] = [V2(-wallT, 0), V2(0, 0), V2(0, H), V2(-wallT, H)]
        let lip: [V2] = [V2(-wallT, H - 0.0035), V2(lipOut, H - 0.0035), V2(lipOut, H - 0.0006), V2(lipOut - 0.0012, H), V2(-wallT, H)]
        for (i, a) in [Float(0), 90, 180, 270].enumerated() {
            let r = FA.q(a, FA.Y)
            let bodyLen = (i % 2 == 0) ? 2 * e : 2 * e - 2 * wallT
            let lipLen = (i % 2 == 0) ? 2 * e + 2 * lipOut : 2 * e
            m.add(Prim.extrude(body, depth: bodyLen, bevel: 0.0008, bevelSegments: 1, material: aluminium),
                  Xform(translation: r.act(V3(0, 0, e)), rotation: r * FA.q(-90, FA.Y)))
            m.add(Prim.extrude(lip, depth: lipLen, bevel: 0.0008, bevelSegments: 1, material: aluminium),
                  Xform(translation: r.act(V3(0, 0, e)), rotation: r * FA.q(-90, FA.Y)))
            // Drain slots low on the wall (dark pressed slots), a hand slot near the top, and rivets along the lip.
            for k in 0..<5 {
                let x = -0.36 + Float(k) * 0.18
                RK.plate(&m, V3(0.05, 0.007, 0.0006), r.act(V3(x, 0.014, e + 0.0003)), "plastic.black", rot: r)
            }
            for k in 0..<2 {
                RK.plate(&m, V3(0.1, 0.018, 0.0006), r.act(V3(k == 0 ? -0.3 : 0.3, 0.068, e + 0.0003)), "plastic.black", rot: r)
            }
            var rr = rng.fork(40 + i)
            for k in 0..<9 {
                let x = -0.4 + Float(k) * 0.1 + rr.float(-0.004...0.004)
                RK.plate(&m, V3(0.0065, 0.0018, 0.0065), r.act(V3(x, H + 0.0006, e + 0.007)), "metal.stainless", rot: r)
            }
        }
        // Floor with a stiffening rib grid pressed up from the sheet.
        FA.box(&m, V3(2 * iw, 0.003, 2 * iw), V3(0, 0.0015, 0), aluminium, r: 0.0008)
        for k in -4...4 {
            let c = Float(k) * 0.1
            RK.plate(&m, V3(2 * iw - 0.01, 0.005, 0.012), V3(0, 0.0045, c), aluminium)
            RK.plate(&m, V3(0.012, 0.005, 2 * iw - 0.01), V3(c, 0.0045, 0), aluminium)
        }

        // Corner brackets: vertical L plates in each inside corner with two hex bolts.
        for (sx, sz) in [(Float(1), Float(1)), (-1, 1), (1, -1), (-1, -1)] {
            FA.box(&m, V3(0.05, 0.06, 0.003), V3(sx * (iw - 0.025), 0.045, sz * (iw - 0.0015)), aluminium, r: 0.001)
            FA.box(&m, V3(0.003, 0.06, 0.05), V3(sx * (iw - 0.0015), 0.045, sz * (iw - 0.025)), aluminium, r: 0.001)
            for dy: Float in [0.03, 0.06] {
                RK.plate(&m, V3(0.011, 0.011, 0.004), V3(sx * (iw - 0.03), dy + 0.015, sz * (iw - 0.005)), "metal.stainless")
            }
        }

        // Drainage cups: molded reservoir sheet, 0.04 pitch, cones with a flat top, over the full floor outside the substrate cut only.
        let pitch: Float = 0.04
        let cupProfile: [V2] = [V2(0.0, 0.0), V2(0.0165, 0.0), V2(0.0125, 0.017), V2(0.0, 0.018)]
        let nC = Int((2 * iw - 0.008) / pitch)
        let cupSurf = Prim.lathe(cupProfile, segments: 8, seamTile: 0.1, material: "plastic.black", swapUV: false)
        for i in 0..<nC {
            for j in 0..<nC {
                let x = -iw + 0.006 + pitch * (Float(i) + 0.5) + (2 * iw - 0.012 - Float(nC) * pitch) / 2
                let z = -iw + 0.006 + pitch * (Float(j) + 0.5) + (2 * iw - 0.012 - Float(nC) * pitch) / 2
                // Cups under the substrate are hidden; draw them only in and near the cutaway.
                if inCut(x, z, 0.02) { m.add(cupSurf, Xform(translation: V3(x, yFloor, z))) }
            }
        }
        // Flat web between the cups in the cutaway.
        if cut > 0 { FA.box(&m, V3(cut + 0.04 + 0.0, 0.0035, cut + 0.04), V3(iw - (cut + 0.04) / 2 - 0.0, yFloor + 0.002, iw - (cut + 0.04) / 2), "plastic.black", r: 0.0008) }

        // Filter fabric over the cups on part of the cutaway, with a lifted corner showing the cups.
        if cut > 0 {
            FA.box(&m, V3(cut * 0.6, 0.0012, cut + 0.04), V3(iw - (cut * 0.6) / 2, 0.0215, iw - (cut + 0.04) / 2), "fabric.nylon:7E8280", r: 0.0004)
            FA.box(&m, V3(cut * 0.2, 0.0012, cut * 0.3), V3(iw - cut * 0.6 - cut * 0.1, 0.0245, iw - cut * 0.15 - 0.04 + 0.04 - cut * 0.55),
                   "fabric.nylon:7E8280", r: 0.0004, rot: FA.q(-14, FA.Z))
        }

        // Growing medium: full box with the corner quadrant removed (two boxes), plus layered cut faces.
        let sub: MaterialKey = "soil.potting"
        let subY0: Float = 0.023, subH = yTop - subY0
        func subBox(_ x0: Float, _ x1: Float, _ z0: Float, _ z1: Float) {
            FA.box(&m, V3(x1 - x0, subH, z1 - z0), V3((x0 + x1) / 2, subY0 + subH / 2, (z0 + z1) / 2), sub, r: 0.004)
        }
        if cut > 0 {
            subBox(-iw + 0.001, iw - 0.001, -iw + 0.001, cz0)
            subBox(-iw + 0.001, cx0, cz0, iw - 0.001)
        } else {
            subBox(-iw + 0.001, iw - 0.001, -iw + 0.001, iw - 0.001)
        }
        // Rest of the layer stack under the substrate away from the cut: a plate stands in for cups and fabric.
        func stand(_ x0: Float, _ x1: Float, _ z0: Float, _ z1: Float) {
            FA.box(&m, V3(x1 - x0, 0.02, z1 - z0), V3((x0 + x1) / 2, 0.013, (z0 + z1) / 2), "plastic.black", r: 0.002)
        }
        if cut > 0 { stand(-iw + 0.001, iw - 0.001, -iw + 0.001, cz0 - 0.04); stand(-iw + 0.001, cx0 - 0.04, cz0 - 0.04, iw - 0.001) }
        else { stand(-iw + 0.001, iw - 0.001, -iw + 0.001, iw - 0.001) }
        // Expanded shale chunks showing in the substrate cut faces and scattered through the surface.
        if cut > 0 {
            for _ in 0..<18 {
                let onX = rng.chance(0.5)
                let y = rng.float(subY0 + 0.004...yTop - 0.006), s = rng.float(0.006...0.013)
                let p = onX ? V3(cx0 - 0.001, y, rng.float(cz0 + 0.01...iw - 0.01)) : V3(rng.float(cx0 + 0.01...iw - 0.01), y, cz0 - 0.001)
                m.add(Prim.superellipsoid(V3(onX ? 0.006 : s, s * 0.8, onX ? s : 0.006), exponent: 2.6, subdivisions: 2, material: "ceramic.terracotta:9A4F33"), Xform(translation: p, rotation: FA.q(rng.float(0...360), FA.Y)))
            }
        }

        // Gravel firebreak strip inside each wall; the strip is open at the cutaway.
        let gravW: Float = 0.045
        let grav: MaterialKey = "stone.granite-paver"
        func gravel(_ x0: Float, _ x1: Float, _ z0: Float, _ z1: Float) {
            if x1 - x0 < 0.01 || z1 - z0 < 0.01 { return }
            FA.box(&m, V3(x1 - x0, 0.007, z1 - z0), V3((x0 + x1) / 2, yTop + 0.0015, (z0 + z1) / 2), grav, r: 0.0025)
        }
        gravel(-iw + 0.001, iw - 0.001, -iw + 0.001, -iw + gravW)
        gravel(-iw + 0.001, -iw + gravW, -iw + gravW, iw - 0.001)
        gravel(iw - gravW, iw - 0.001, -iw + gravW, cut > 0 ? cz0 : iw - 0.001)
        gravel(-iw + gravW, cut > 0 ? cx0 : iw - 0.001, iw - gravW, iw - 0.001)
        for _ in 0..<20 {
            let side = rng.int(0...3)
            let t = rng.float(-iw + 0.02...iw - 0.02), d = rng.float(0.006...gravW - 0.006)
            let p: V3
            switch side {
            case 0: p = V3(t, yTop + 0.007, -iw + d)
            case 1: p = V3(-iw + d, yTop + 0.007, t)
            case 2: p = V3(iw - d, yTop + 0.007, t)
            default: p = V3(t, yTop + 0.007, iw - d)
            }
            if inCut(p.x, p.z) { continue }
            let s = rng.float(0.008...0.016)
            m.add(Prim.superellipsoid(V3(s, s * 0.65, s * 0.85), exponent: 2.4, subdivisions: 2, material: "stone.granite-paver"), Xform(translation: p, rotation: FA.q(rng.float(0...360), FA.Y)))
        }

        // Sedum mat: a continuous green carpet, overlapping drifts of ruddy, glaucous and golden sedum, then pillow clumps.
        let drift: [MaterialKey] = ["moss.sedum-red", "moss.sedum-blue", "moss.sedum-gold", "leaf.boxwood-mass", "moss.sedum-red", "leaf.lavender-mass", "moss.sedum-gold"]
        let pillowMats: [MaterialKey] = ["moss.sedum-red", "moss.sedum-blue", "moss.sedum-gold", "leaf.boxwood-mass", "moss.cushion", "leaf.lavender-mass"]
        let inner0 = -iw + gravW, inner1 = iw - gravW
        func carpet(_ x0: Float, _ x1: Float, _ z0: Float, _ z1: Float) {
            m.add(Prim.superellipsoid(V3(x1 - x0, 0.02, z1 - z0), exponent: 8, subdivisions: 4, material: "moss.cushion"), Xform(translation: V3((x0 + x1) / 2, yTop + 0.001, (z0 + z1) / 2)))
        }
        if cut > 0 {
            carpet(inner0, inner1, inner0, cz0 - 0.004)
            carpet(inner0, cx0 - 0.004, cz0 - 0.004, inner1)
        } else { carpet(inner0, inner1, inner0, inner1) }
        for k in 0..<26 {
            var q = rng.fork(100 + k)
            let px = q.float(inner0 + 0.05...inner1 - 0.05), pz = q.float(inner0 + 0.05...inner1 - 0.05)
            let sx = q.float(0.10...0.2), sz = q.float(0.09...0.17)
            if inCut(px, pz, sx * 0.55) { continue }
            m.add(Prim.superellipsoid(V3(sx, 0.026, sz), exponent: 2.8, subdivisions: 3, material: drift[k % drift.count]),
                  Xform(translation: V3(px, yTop + 0.003, pz), rotation: FA.q(q.float(0...180), FA.Y)))
        }
        // Die-back: one dried straw-brown drift where the irrigation never reached.
        m.add(Prim.superellipsoid(V3(0.17, 0.024, 0.13), exponent: 2.8, subdivisions: 3, material: "moss.sedum-dry"), Xform(translation: V3(-0.27, yTop + 0.004, 0.21), rotation: FA.q(25, FA.Y)))
        for k in 0..<40 {
            var q = rng.fork(300 + k)
            let px = q.float(inner0 + 0.02...inner1 - 0.02), pz = q.float(inner0 + 0.02...inner1 - 0.02)
            if inCut(px, pz, 0.03) { continue }
            let sz = q.float(0.028...0.05), hgt = q.float(0.014...0.026)
            m.add(Prim.superellipsoid(V3(sz, hgt, sz * q.float(0.8...1.1)), exponent: 2.6, subdivisions: 2, material: q.pick(pillowMats)),
                  Xform(translation: V3(px, yTop + 0.012 + hgt / 2, pz), rotation: FA.q(q.float(0...360), FA.Y)))
        }
        // Moss cushions near the gravel, flowering stalks standing out of the mat.
        for _ in 0..<5 {
            let p = V3(rng.float(-iw + 0.06...iw - 0.06), yTop + 0.012, rng.float(-iw + 0.06...iw - 0.06))
            if inCut(p.x, p.z, 0.02) { continue }
            let s = rng.float(0.025...0.045)
            m.add(Prim.superellipsoid(V3(s, 0.02, s), exponent: 2.2, subdivisions: 2, material: "moss.cushion"), Xform(translation: p))
        }
        for k in 0..<11 {
            var q = rng.fork(600 + k)
            let base = V3(q.float(-iw + 0.1...iw - 0.1), yTop + 0.01, q.float(-iw + 0.1...iw - 0.1))
            if inCut(base.x, base.z, 0.03) { continue }
            let h = q.float(0.024...0.034)
            let lean = V3(q.float(-0.01...0.01), 0, q.float(-0.01...0.01))
            FA.path(&m, [base, base + V3(lean.x * 0.5, h * 0.55, lean.z * 0.5), base + V3(lean.x, h, lean.z)], r: 0.0017, "leaf.plain", sides: 5)
            m.add(Prim.superellipsoid(V3(0.032, 0.012, 0.032), exponent: 2.4, subdivisions: 3, material: q.chance(0.5) ? "moss.sedum-red" : "paint.stucco:E6B8C2"),
                  Xform(translation: base + V3(lean.x, h + 0.004, lean.z)))
        }

        // Weathering on the aluminium: soil splash at the base, white oxidation spots on the lip, algae on the lower wall.
        for (i, a) in [Float(0), 90, 180, 270].enumerated() {
            let r = FA.q(a, FA.Y)
            var rr = rng.fork(80 + i)
            for _ in 0..<6 {
                RK.plate(&m, V3(rr.float(0.05...0.14), rr.float(0.015...0.05), 0.0006), r.act(V3(rr.float(-0.42...0.42), rr.float(0.01...0.04), e + 0.0004)), "soil.potting", rot: r)
            }
            for _ in 0..<4 {
                RK.plate(&m, V3(rr.float(0.04...0.1), rr.float(0.01...0.028), 0.0006), r.act(V3(rr.float(-0.42...0.42), rr.float(0.02...0.04), e + 0.0007)), "moss.cushion", rot: r)
            }
            // Powder coat chipped to bare aluminium on the lip edge and the wall face below it.
            for _ in 0..<7 {
                let cxp = rr.float(-0.45...0.45)
                RK.plate(&m, V3(rr.float(0.01...0.03), 0.0004, rr.float(0.004...0.009)), r.act(V3(cxp, H + 0.0002, e + lipOut - 0.004)), "metal.aluminum-brushed", rot: r)
                RK.plate(&m, V3(rr.float(0.004...0.012), rr.float(0.006...0.02), 0.0005), r.act(V3(rr.float(-0.45...0.45), H - rr.float(0.01...0.03), e + 0.0009)), "metal.aluminum-brushed", rot: r)
            }
            for _ in 0..<7 {
                RK.plate(&m, V3(rr.float(0.006...0.016), 0.0004, rr.float(0.006...0.016)), r.act(V3(rr.float(-0.45...0.45), H + 0.0001, e + rr.float(0.002...0.012))), "paint.stucco:D8D5CC", rot: r)
            }
        }
        groundAO(&m, height: 0.06, floor: 0.9)
        return LODModel(m)
    }
}
