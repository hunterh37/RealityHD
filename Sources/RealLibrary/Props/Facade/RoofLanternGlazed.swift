import simd
import Foundation

/// Glazed roof lantern: architectural facade customizer, georgian contemporary, weathered. Parts: masonry upstand, timber sill and curb, hipped glazed roof, hip and ridge rafters, glazing bars, lead flashing, finial, corner posts.
public struct RoofLanternGlazed: RealAsset {
    public static let id = "roof-lantern-glazed"
    public static let summary = "Glazed roof lantern, 1.5 x 1.5 m: painted timber lantern, hipped glass roof, glazing bars, lead flashing, finial."
    public static let tags = ["prop", "architecture", "facade", "roof", "wood"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 20, distance: 2.6)

    /// Overall footprint (x, z) and height (y) in meters.
    public var size = V3(1.5, 1.0, 1.5)
    /// Upstand height in meters.
    public var upstand: Float = 0.2
    /// Roof pitch in degrees.
    public var pitch: Float = 30
    /// Painted timber material key.
    public var paint: MaterialKey = "wood.barn-white"
    /// Glass material key.
    public var glass: MaterialKey = "glass.clear"
    /// Lead flashing material key.
    public var lead: MaterialKey = "metal.galvanized-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, D = size.z
        let up = upstand
        // Masonry upstand with a drip-throated stone coping.
        FA.box(&m, V3(W, up, D), V3(0, up / 2, 0), "stone.limestone-sooted", r: 0.006)
        FA.box(&m, V3(W + 0.04, 0.03, D + 0.04), V3(0, up + 0.015, 0), "stone.cast-stone", r: 0.005)
        for e: Float in [-1, 1] {
            FA.box(&m, V3(W, 0.004, 0.003), V3(0, up * 0.5, e * (D / 2 + 0.0005)), "stone.limestone-sooted", r: 0.001)
        }
        // Lead flashing collar draped over the coping.
        FA.box(&m, V3(W + 0.05, 0.006, D + 0.05), V3(0, up + 0.033, 0), lead, r: 0.003)
        // Timber lantern base: sill rail and four corner posts.
        let sillY = up + 0.036, sillH: Float = 0.08
        let lw = W - 0.14, ld = D - 0.14
        FA.box(&m, V3(lw + 0.04, sillH, 0.07), V3(0, sillY + sillH / 2, ld / 2), "wood.trim-weathered", r: 0.004)
        FA.box(&m, V3(lw + 0.04, sillH, 0.07), V3(0, sillY + sillH / 2, -ld / 2), "wood.trim-weathered", r: 0.004)
        FA.box(&m, V3(0.07, sillH, ld - 0.07), V3(lw / 2, sillY + sillH / 2, 0), paint, r: 0.004)
        FA.box(&m, V3(0.07, sillH, ld - 0.07), V3(-lw / 2, sillY + sillH / 2, 0), paint, r: 0.004)
        // Glazed walls: height of the vertical lantern.
        let wallH: Float = 0.3
        let y0 = sillY + sillH
        let y1 = y0 + wallH
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            FA.box(&m, V3(0.06, wallH, 0.06), V3(sx * lw / 2, y0 + wallH / 2, sz * ld / 2), "wood.trim-weathered", r: 0.004)
        } }
        // Four walls of glass, each with a mid mullion and a transom.
        for side in 0..<4 {
            let alongX = side < 2
            let sgn: Float = side % 2 == 0 ? 1 : -1
            let span = alongX ? lw : ld
            let c = alongX ? V3(0, 0, sgn * ld / 2) : V3(sgn * lw / 2, 0, 0)
            func put(_ s: V3, _ p: V3, _ mat: MaterialKey, r: Float = 0.003) {
                let sz = alongX ? s : V3(s.z, s.y, s.x)
                let pp = alongX ? p : V3(p.z, p.y, p.x)
                FA.box(&m, sz, c + pp, mat, r: r)
            }
            put(V3(span - 0.06, wallH - 0.04, 0.008), V3(0, y0 + wallH / 2, 0), glass, r: 0.0015)
            put(V3(0.035, wallH, 0.04), V3(0, y0 + wallH / 2, 0.004), paint)
            put(V3(span - 0.06, 0.03, 0.044), V3(0, y0 + wallH * 0.62, 0.004), paint)
            for k in [-1, 1] as [Float] { put(V3(0.02, wallH - 0.04, 0.03), V3(k * span * 0.25, y0 + wallH / 2, 0.003), paint, r: 0.002) }
        }
        // Eaves plate (wall plate) around the top of the walls.
        FA.box(&m, V3(lw + 0.1, 0.05, 0.08), V3(0, y1 + 0.025, ld / 2), paint, r: 0.004)
        FA.box(&m, V3(lw + 0.1, 0.05, 0.08), V3(0, y1 + 0.025, -ld / 2), paint, r: 0.004)
        FA.box(&m, V3(0.08, 0.05, ld + 0.1), V3(lw / 2, y1 + 0.025, 0), paint, r: 0.004)
        FA.box(&m, V3(0.08, 0.05, ld + 0.1), V3(-lw / 2, y1 + 0.025, 0), paint, r: 0.004)
        // Hipped roof (pyramid to a short ridge), glass panes and rafters on each face.
        let eaveY = y1 + 0.05
        let ridgeLen = max(lw - ld, 0) + 0.0
        let roofRise = size.y - eaveY - 0.22
        let runZ = ld / 2, runX = lw / 2
        let apexY = eaveY + roofRise
        let ang = atan2(roofRise, runZ) * 180 / .pi
        let slopeZ = sqrt(runZ * runZ + roofRise * roofRise)
        let slopeX = sqrt(runX * runX + roofRise * roofRise)
        let angX = atan2(roofRise, runX) * 180 / .pi
        _ = ridgeLen; _ = ang; _ = angX
        let apex = V3(0, apexY, 0)
        let corners: [V3] = [V3(-lw / 2, eaveY, -ld / 2), V3(lw / 2, eaveY, -ld / 2), V3(lw / 2, eaveY, ld / 2), V3(-lw / 2, eaveY, ld / 2)]
        // Hip rafters from each corner to the apex.
        for c in corners {
            let d = apex - c
            let len = simd_length(d)
            let dir = d / len
            let rot = simd_quatf(from: V3(0, 0, 1), to: dir)
            FA.box(&m, V3(0.05, 0.05, len), (c + apex) / 2 + V3(0, 0.012, 0), paint, r: 0.004, rot: rot)
            // Lead roll along the hip.
            FA.box(&m, V3(0.034, 0.014, len), (c + apex) / 2 + V3(0, 0.044, 0), lead, r: 0.005, rot: rot)
        }
        // Four roof faces: trapezoid glass in a frame basis, centre bar, transoms, lead flashing at the eaves.
        for side in 0..<4 {
            let alongX = side < 2
            let sgn: Float = side % 2 == 0 ? 1 : -1
            let run = alongX ? runZ : runX
            let span = alongX ? lw : ld
            let slope = alongX ? slopeZ : slopeX
            let tr = atan2(roofRise, run)
            let out = alongX ? V3(0, 0, sgn) : V3(sgn, 0, 0)
            let upS = -out * cos(tr) + V3(0, sin(tr), 0)
            var across = simd_cross(upS, out)
            if alongX { across = V3(1, 0, 0) } else { across = V3(0, 0, 1) }
            var nrm = simd_cross(across, upS)
            if simd_dot(nrm, out) < 0 { nrm = -nrm; across = -across }
            let rot = simd_quatf(simd_float3x3(columns: (across, upS, nrm)))
            let eaveP = V3(alongX ? 0 : sgn * run, eaveY, alongX ? sgn * run : 0)
            let wb = span + 0.02, wt: Float = 0.05
            let ln = slope - 0.02
            let glassOutline = [V2(-wb / 2, 0), V2(wb / 2, 0), V2(wt / 2, ln), V2(-wt / 2, ln)]
            let base = eaveP + nrm * 0.022 + upS * 0.01
            m.add(Prim.extrude(glassOutline, depth: 0.008, bevel: 0.0015, bevelSegments: 1, material: glass),
                  Xform(translation: base, rotation: rot))
            // Centre glazing bar and cap.
            FA.box(&m, V3(0.034, ln, 0.03), base + upS * (ln / 2) + nrm * 0.012, paint, r: 0.004, rot: rot)
            FA.box(&m, V3(0.02, ln, 0.01), base + upS * (ln / 2) + nrm * 0.03, lead, r: 0.003, rot: rot)
            // Transoms at 35% and 68% of the slope, width following the taper.
            for f in [0.35, 0.68] as [Float] {
                let w = wb + (wt - wb) * f
                FA.box(&m, V3(w, 0.026, 0.03), base + upS * (ln * f) + nrm * 0.012, paint, r: 0.004, rot: rot)
            }
            // Lead eaves flashing strip and drip.
            let ep = alongX ? V3(0, eaveY + 0.012, sgn * (runZ + 0.045)) : V3(sgn * (runX + 0.045), eaveY + 0.012, 0)
            FA.box(&m, alongX ? V3(span + 0.12, 0.02, 0.05) : V3(0.05, 0.02, span + 0.12), ep, lead, r: 0.006)
        }
        // Ridge pyramid cap and finial: turned lead base, timber shaft, ball.
        m.add(Prim.lathe([V2(0.001, 0), V2(0.06, 0), V2(0.062, 0.012), V2(0.04, 0.03), V2(0.03, 0.06), V2(0.001, 0.06)], segments: 16, seamTile: 0.1, material: lead),
              Xform(translation: V3(0, apexY - 0.01, 0)))
        FA.rod(&m, V3(0, apexY + 0.04, 0), V3(0, apexY + 0.14, 0), r: 0.012, paint)
        FA.ball(&m, r: 0.026, at: V3(0, apexY + 0.16, 0), "metal.bronze-weathered")
        m.add(Prim.lathe([V2(0.001, 0.17), V2(0.007, 0.175), V2(0.003, 0.2), V2(0.001, 0.215)], segments: 8, seamTile: 0.1, material: "metal.bronze-weathered"),
              Xform(translation: V3(0, apexY, 0)))
        // Fasteners: bronze screws on the sill rails.
        for sz: Float in [-1, 1] {
            for k in 0..<7 {
                let x = -lw / 2 + 0.06 + Float(k) * (lw - 0.12) / 6
                FA.cylZ(&m, r: 0.005, h: 0.003, at: V3(x, sillY + sillH * 0.5, sz * ld / 2 + sz * 0.035), "metal.bronze-weathered", bevel: 0.001, segments: 8)
            }
        }
        for k in 0..<5 {
            let x = -W / 2 + 0.2 + Float(k) * (W - 0.4) / 4 + rng.float(-0.05...0.05)
            m.add(Prim.superellipsoid(V3(0.02, rng.float(0.08...0.16), 0.004), exponent: 3, subdivisions: 5, material: "stone.limestone-sooted"),
                  Xform(translation: V3(x, up - 0.07, D / 2 + 0.002)))
        }
        // Story detail: moss streak on the north upstand.
        m.add(Prim.superellipsoid(V3(0.3, 0.05, 0.006), exponent: 3, subdivisions: 6, material: "stone.granite-moss"),
              Xform(translation: V3(rng.float(-0.3...0.3), 0.05, -(D / 2) - 0.002)))
        groundAO(&m)
        return LODModel(m)
    }
}
