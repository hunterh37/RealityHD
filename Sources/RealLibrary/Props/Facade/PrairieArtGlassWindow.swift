import simd
import Foundation

/// Prairie School art glass window, 0.9 x 1.4 m: a quarter-sawn oak casement frame with a mitred glazing stop,
/// a zinc-came geometric lattice (vertical banding down the centre, diamonds in the head band, nested squares in
/// the foot band) glazed in clear, amber and emerald, a wood head casing with horns, a projecting limestone sill
/// with a drip groove, brass butt hinges and a cam latch. One cracked amber quarry, grime on the glass, zinc
/// oxide at the cames and a lichen stain on the sill.
public struct PrairieArtGlassWindow: RealAsset {
    public static let id = "prairie-art-glass-window"
    public static let summary = "Prairie School art glass window, 0.9 x 1.4 m: oak frame, zinc came geometric lattice, green amber and clear glass, stone sill."
    public static let tags = ["prop", "architecture", "facade", "trim", "decor", "wood", "metal"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 22, elevation: 8, distance: 2.6)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.9, 1.4, 0.1)
    /// Oak frame and stops.
    public var oak: MaterialKey = "wood.walnut"
    /// Zinc came lattice.
    public var zinc: MaterialKey = "metal.galvanized-aged"
    /// Amber and emerald glass.
    public var amber: MaterialKey = "plastic.amber"
    public var green: MaterialKey = "glass.emerald"
    /// Clear glass.
    public var clear: MaterialKey = "glass.clear"
    /// Sill stone.
    public var stone: MaterialKey = "stone.limestone"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let sillH: Float = 0.05
        let fw: Float = 0.84, fz: Float = -0.012, fd: Float = 0.07      // frame width, centre z, depth
        let stile: Float = 0.055, rail: Float = 0.06
        let yb = sillH, yt: Float = 1.34                                  // frame bottom and top
        let ix0 = -fw / 2 + stile, ix1 = fw / 2 - stile                    // opening x
        let iy0 = yb + rail, iy1 = yt - rail                               // opening y
        let gz = fz - 0.004                                                // glass plane

        // Limestone sill: projecting 0.05 past the frame with a drip groove, slightly sloped top and weathered ends.
        let sill = Shape2D.rounded([V2(-0.45, 0), V2(0.45, 0), V2(0.45, 0.04), V2(0.43, 0.052), V2(-0.43, 0.052), V2(-0.45, 0.04)], radius: 0.004)
        m.add(Prim.extrude(sill, depth: 0.1, bevel: 0.003, bevelSegments: 2, material: stone), Xform(translation: V3(0, 0, 0), rotation: FA.q(0, FA.X)))
        FA.box(&m, V3(0.86, 0.006, 0.008), V3(0, 0.003, 0.04), "stone.limestone", r: 0.002)   // drip groove lip
        // Frame: stiles, rails, mid-rail dividing the head transom, all with a rounded arris.
        FA.box(&m, V3(stile, yt - yb, fd), V3(-fw / 2 + stile / 2, (yt + yb) / 2, fz), oak, r: 0.004)
        FA.box(&m, V3(stile, yt - yb, fd), V3(fw / 2 - stile / 2, (yt + yb) / 2, fz), oak, r: 0.004)
        FA.box(&m, V3(fw - 2 * stile + 0.004, rail, fd), V3(0, yb + rail / 2, fz), oak, r: 0.004)
        FA.box(&m, V3(fw - 2 * stile + 0.004, rail, fd), V3(0, yt - rail / 2, fz), oak, r: 0.004)
        // Wood head casing with horns, a flat Prairie cap overhanging the frame.
        FA.box(&m, V3(0.9, 0.04, 0.09), V3(0, yt + 0.02, 0.0), oak, r: 0.004)
        FA.box(&m, V3(0.88, 0.014, 0.1), V3(0, yt + 0.053, 0.0), oak, r: 0.004)
        // Mitred glazing stop: four trapezoid strips around the opening, 0.014 wide, 0.012 deep, proud of the glass.
        func stopSide(_ pts: [V2], at c: V3, rot: simd_quatf = .identity) {
            m.add(Prim.extrude(pts, depth: 0.012, bevel: 0.001, bevelSegments: 1, material: oak), Xform(translation: c, rotation: rot))
        }
        let ow = ix1 - ix0, oh = iy1 - iy0, sw: Float = 0.016, sz = fz + fd / 2 - 0.004
        stopSide([V2(-ow / 2, 0), V2(ow / 2, 0), V2(ow / 2 - sw, sw), V2(-ow / 2 + sw, sw)], at: V3(0, iy0, sz))
        stopSide([V2(-ow / 2 + sw, -sw), V2(ow / 2 - sw, -sw), V2(ow / 2, 0), V2(-ow / 2, 0)], at: V3(0, iy1, sz))
        stopSide([V2(0, -oh / 2), V2(sw, -oh / 2 + sw), V2(sw, oh / 2 - sw), V2(0, oh / 2)], at: V3(ix0, (iy0 + iy1) / 2, sz))
        stopSide([V2(-sw, -oh / 2 + sw), V2(0, -oh / 2), V2(0, oh / 2), V2(-sw, oh / 2 - sw)], at: V3(ix1, (iy0 + iy1) / 2, sz))
        // Mitred brickmould casing around the frame: four trapezoid strips 0.026 wide standing 0.012 proud of the frame face.
        let bw: Float = 0.026, bx = fw / 2, bz = fz + fd / 2
        func casing(_ pts: [V2], at c: V3) {
            m.add(Prim.extrude(pts, depth: 0.014, bevel: 0.0015, bevelSegments: 1, material: oak), Xform(translation: c))
        }
        casing([V2(-bx, 0), V2(bx, 0), V2(bx - bw, bw), V2(-bx + bw, bw)], at: V3(0, yt - bw - 0.0, bz + 0.003))
        casing([V2(-bx, 0), V2(-bx + bw, bw), V2(-bx + bw, yt - yb - 0.0), V2(-bx, yt - yb - bw)], at: V3(0, yb, bz + 0.003))
        casing([V2(bx, 0), V2(bx, yt - yb - bw), V2(bx - bw, yt - yb), V2(bx - bw, bw)], at: V3(0, yb, bz + 0.003))
        // Reveal shadow lines where the sash meets the frame.
        FA.box(&m, V3(0.0025, yt - yb - 2 * rail + 0.02, 0.002), V3(ix0 - 0.0015, (iy0 + iy1) / 2, fz + fd / 2 + 0.0004), "wood.deadwood", r: 0.0003)
        FA.box(&m, V3(0.0025, yt - yb - 2 * rail + 0.02, 0.002), V3(ix1 + 0.0015, (iy0 + iy1) / 2, fz + fd / 2 + 0.0004), "wood.deadwood", r: 0.0003)
        // Brass pins in the stops.
        for y in stride(from: iy0 + 0.12, to: iy1, by: 0.26) {
            for x in [ix0 + 0.008, ix1 - 0.008] { pin(&m, V3(x, y, sz + 0.0065)) }
        }

        // Glass pieces and cames. pane() lays a thin sheet and its zinc came border.
        func glass(_ x0: Float, _ y0: Float, _ x1: Float, _ y1: Float, _ mat: MaterialKey, z: Float = 0) {
            m.add(cuboid(V3(x1 - x0 - 0.002, y1 - y0 - 0.002, 0.005), material: mat), Xform(translation: V3((x0 + x1) / 2, (y0 + y1) / 2, gz + z)))
        }
        var seen = Set<String>()
        var joints = Set<Int>()
        func lead(_ a: V2, _ b: V2, w: Float = 0.009) {
            let ka = Int((a.x * 1000).rounded()) * 100_000 + Int((a.y * 1000).rounded())
            let kb = Int((b.x * 1000).rounded()) * 100_000 + Int((b.y * 1000).rounded())
            let k = "\(min(ka, kb))|\(max(ka, kb))"
            if !seen.insert(k).inserted { return }
            for p in [a, b] where joints.insert(Int((p.x * 1000).rounded()) * 100_000 + Int((p.y * 1000).rounded())).inserted {
                m.add(Prim.superellipsoid(V3(0.014, 0.014, 0.008), exponent: 2, subdivisions: 1, material: zinc), Xform(translation: V3(p.x, p.y, gz + 0.0055)))
            }
            let c = (a + b) / 2, d = b - a, len = simd_length(d), ang = atan2(d.y, d.x) * 180 / .pi
            m.add(cuboid(V3(len + w * 0.6, w, 0.013), material: zinc), Xform(translation: V3(c.x, c.y, gz), rotation: FA.q(ang, FA.Z)))
        }
        func came(_ x0: Float, _ y0: Float, _ x1: Float, _ y1: Float) {
            lead(V2(x0, y0), V2(x1, y0)); lead(V2(x0, y1), V2(x1, y1)); lead(V2(x0, y0), V2(x0, y1)); lead(V2(x1, y0), V2(x1, y1))
        }
        // Layout: foot band, centre field, head band.
        let footTop = iy0 + 0.26, headBot = iy1 - 0.26
        let edge: Float = 0.085
        let cx0 = ix0 + edge, cx1 = ix1 - edge, cw = (cx1 - cx0) / 3
        let crackCell = (x: 2, y: 1)
        // Side banding: stacked rectangles alternating amber / emerald / clear over the full height.
        let nRows = 8, rh = (iy1 - iy0) / Float(nRows)
        for side in 0..<2 {
            let x0 = side == 0 ? ix0 : cx1, x1 = side == 0 ? cx0 : ix1
            for r in 0..<nRows {
                let y0 = iy0 + Float(r) * rh, y1 = y0 + rh
                let mat = r % 4 == 1 ? amber : (r % 4 == 3 ? green : clear)
                glass(x0, y0, x1, y1, mat)
                came(x0, y0, x1, y1)
            }
        }
        // Centre field: three columns, the middle one banded amber / clear / emerald / clear, the outer two clear in two panes.
        let fy0 = footTop, fy1 = headBot
        for c in 0..<3 {
            let x0 = cx0 + Float(c) * cw, x1 = x0 + cw
            if c == 1 {
                let n = 4, h = (fy1 - fy0) / Float(n)
                for r in 0..<n {
                    let y0 = fy0 + Float(r) * h, y1 = y0 + h
                    glass(x0, y0, x1, y1, r % 2 == 0 ? (r == 0 ? amber : green) : clear)
                    came(x0, y0, x1, y1)
                }
            } else {
                let h = (fy1 - fy0) / 2
                for r in 0..<2 {
                    let y0 = fy0 + Float(r) * h, y1 = y0 + h
                    glass(x0, y0, x1, y1, clear)
                    came(x0, y0, x1, y1)
                    _ = crackCell
                }
            }
        }
        // Head band: clear squares each holding a diamond of amber or emerald with a came diamond outline.
        for c in 0..<3 {
            let x0 = cx0 + Float(c) * cw, x1 = x0 + cw, y0 = headBot, y1 = iy1
            glass(x0, y0, x1, y1, clear)
            came(x0, y0, x1, y1)
            let ctr = V2((x0 + x1) / 2, (y0 + y1) / 2), hx = cw * 0.38, hy = (y1 - y0) * 0.38
            let pts = [V2(ctr.x, ctr.y + hy), V2(ctr.x + hx, ctr.y), V2(ctr.x, ctr.y - hy), V2(ctr.x - hx, ctr.y)]
            let dmat = c == 1 ? green : amber
            let d = V3(hx * 2 * 0.72, hy * 2 * 0.72, 0.005)
            FA.box(&m, d, V3(ctr.x, ctr.y, gz + 0.0012), dmat, r: 0.0008, rot: FA.q(atan2(hy, hx) * 0 + 45, FA.Z))
            for i in 0..<4 { lead(pts[i], pts[(i + 1) % 4], w: 0.008) }
            m.add(Prim.superellipsoid(V3(0.034, 0.034, 0.012), exponent: 2, subdivisions: 4, material: c == 1 ? amber : green), Xform(translation: V3(ctr.x, ctr.y, gz + 0.006)))
        }
        // Foot band: nested squares, an amber core inside an emerald frame inside clear.
        for c in 0..<3 {
            let x0 = cx0 + Float(c) * cw, x1 = x0 + cw, y0 = iy0, y1 = footTop
            glass(x0, y0, x1, y1, clear)
            came(x0, y0, x1, y1)
            let mx = (x1 - x0) * 0.2, my = (y1 - y0) * 0.2
            glass(x0 + mx, y0 + my, x1 - mx, y1 - my, green, z: 0.0012)
            came(x0 + mx, y0 + my, x1 - mx, y1 - my)
            let mx2 = (x1 - x0) * 0.36, my2 = (y1 - y0) * 0.36
            glass(x0 + mx2, y0 + my2, x1 - mx2, y1 - my2, c == 1 ? clear : amber, z: 0.0024)
            came(x0 + mx2, y0 + my2, x1 - mx2, y1 - my2)
        }
        // Horizontal bars of the whole lattice at band joints, a stout came the full width.
        lead(V2(ix0, footTop), V2(ix1, footTop), w: 0.012)
        lead(V2(ix0, headBot), V2(ix1, headBot), w: 0.012)
        // Casement hardware on the oak: two brass butt hinges on the left stile, a cam latch on the right.
        for y: Float in [0.28, 1.12] {
            FA.box(&m, V3(0.012, 0.07, 0.006), V3(-fw / 2 - 0.0005, y, fz + fd / 2 + 0.001), "metal.brass-aged", r: 0.0015)
            m.add(Prim.cylinder(radius: 0.0055, height: 0.07, bevel: 0.0008, segments: 8, bevelSegments: 1, material: "metal.brass-aged"), Xform(translation: V3(-fw / 2 - 0.003, y - 0.035, fz + fd / 2 + 0.0)))
            for dy: Float in [-0.022, 0.022] { pin(&m, V3(-fw / 2 + 0.01, y + dy, fz + fd / 2 + 0.0045)) }
        }
        FA.box(&m, V3(0.02, 0.05, 0.008), V3(fw / 2 - stile / 2, 0.69, fz + fd / 2 + 0.003), "metal.brass-aged", r: 0.002)
        FA.box(&m, V3(0.05, 0.012, 0.01), V3(fw / 2 - stile / 2 - 0.02, 0.69, fz + fd / 2 + 0.01), "metal.brass-aged", r: 0.003, rot: FA.q(-12, FA.Z))

        // Weathering and one story: a crack radiating across an amber quarry, grime on the glass, zinc oxide at the cames.
        let crackX = ix0 + edge * 0.5, crackY = iy0 + rh * 5.5
        _ = crackX; _ = crackY
        let ax = (ix0 + ix1) / 2
        FA.box(&m, V3(0.002, 0.07, 0.001), V3(ix0 + edge / 2 + 0.006, iy0 + 5 * rh + rh * 0.45, gz + 0.0032), "paint.stucco:2B2118", r: 0.0003, rot: FA.q(28, FA.Z))
        FA.box(&m, V3(0.002, 0.05, 0.001), V3(ix0 + edge / 2 - 0.004, iy0 + 5 * rh + rh * 0.65, gz + 0.0032), "paint.stucco:2B2118", r: 0.0003, rot: FA.q(-35, FA.Z))
        _ = ax
        for _ in 0..<18 {
            let x = rng.float(ix0 + 0.03...ix1 - 0.03), y = rng.float(iy0 + 0.03...iy1 - 0.1)
            FA.box(&m, V3(rng.float(0.003...0.012), rng.float(0.04...0.1), 0.0008), V3(x, y, gz + 0.0027), "paint.stucco:8F8878", r: 0.0003)
        }
        for _ in 0..<26 {
            let x = rng.float(ix0 + 0.02...ix1 - 0.02), y = rng.float(iy0...iy1)
            FA.box(&m, V3(rng.float(0.01...0.03), 0.004, 0.0008), V3(x, y, gz + 0.0072), "paint.stucco:D9D6CC", r: 0.0003)
        }
        // Grime collects along the lower came of each centre pane and darkens the glass edge.
        for c in 0..<3 {
            for (y0, y1) in [(fy0, (fy0 + fy1) / 2), ((fy0 + fy1) / 2, fy1)] {
                let x0 = cx0 + Float(c) * cw
                FA.box(&m, V3(cw * rng.float(0.5...0.85), 0.007, 0.0008), V3(x0 + cw / 2 + rng.float(-0.02...0.02), y0 + 0.0075, gz + 0.0029), "paint.stucco:7A7466", r: 0.0003)
                _ = y1
            }
        }
        // Water staining on the oak stiles and rails: dark patches where rain pools at the lower joints.
        for e: Float in [-1, 1] {
            for (y, h): (Float, Float) in [(yb + 0.14, 0.18), (yb + 0.4, 0.07)] {
                FA.box(&m, V3(0.014, h, 0.001), V3(e * (fw / 2 - stile / 2 + rng.float(-0.006...0.006)), y, fz + fd / 2 + 0.0105), "wood.deadwood", r: 0.0003)
            }
        }
        FA.box(&m, V3(0.5, 0.012, 0.001), V3(0, yb + 0.03, fz + fd / 2 + 0.0105), "wood.deadwood", r: 0.0003)
        // Dirt line and rain streaks on the oak rails, and lichen at the sill.
        for _ in 0..<7 {
            let x = rng.float(-0.38...0.38)
            FA.box(&m, V3(rng.float(0.008...0.02), rng.float(0.03...0.07), 0.001), V3(x, yb + 0.03, fz + fd / 2 + 0.0006), "wood.deadwood", r: 0.0003)
        }
        for _ in 0..<5 {
            let x = rng.float(-0.4...0.4)
            m.add(Prim.cylinder(radius: rng.float(0.012...0.03), height: 0.0014, bevel: 0.0004, segments: 6, bevelSegments: 1, material: "paint.stucco:7F8A5E"), Xform(translation: V3(x, 0.0515, rng.float(-0.03...0.03))))
        }
        FA.box(&m, V3(0.9, 0.018, 0.001), V3(0, 0.03, 0.0472), "paint.stucco:7E725E", r: 0.0003)
        groundAO(&m, height: 0.1, floor: 0.85)
        return LODModel(FA.centerZ(m))
    }

    /// Brass pin head, low dome.
    func pin(_ m: inout Model, _ c: V3) {
        m.add(Prim.superellipsoid(V3(0.007, 0.007, 0.004), exponent: 2, subdivisions: 2, material: "metal.brass-aged"), Xform(translation: c))
    }
}
