import simd
import Foundation

/// Beaux-Arts rooftop statue plinth in sooted limestone: a moulded base (plinth block, torus, fillet),
/// a rusticated base course with V-jointed blocks, a panelled die with recessed fields and a raised
/// cartouche with swags on the front, and a cornice cap with dentils, corona and cyma. A bronze statue
/// foot plate is fixed with hex bolts over a lead weathering flashing. Sits on y = 0, 1.2 m tall.
public struct RooftopStatuePlinth: RealAsset {
    public static let id = "rooftop-statue-plinth"
    public static let summary = "Rooftop statue plinth, 1.2 m: rusticated base course, panelled die with cartouche and swags, cornice cap with dentils, bronze foot plate with fixing bolts."
    public static let tags = ["prop", "architecture", "facade", "stone", "decor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 12, distance: 2.8)

    /// Footprint width in meters.
    public var width: Float = 0.9
    /// Overall height in meters.
    public var height: Float = 1.2
    /// Dressed stone.
    public var stone: MaterialKey = "stone.limestone"
    /// Weathered stone for the base and cap.
    public var sooted: MaterialKey = "stone.limestone-sooted"
    /// Statue foot plate.
    public var bronze: MaterialKey = "metal.bronze-cast"
    /// Lead weathering on the cap.
    public var lead: MaterialKey = "metal.galvanized-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let w = width, k = height / 1.2
        func slab(_ sw: Float, _ y: Float, _ h: Float, _ mat: MaterialKey, r: Float = 0.006) {
            FA.box(&m, V3(sw, h, sw), V3(0, y + h / 2, 0), mat, r: min(r, h * 0.4))
        }
        // Base: plinth block, torus, fillet.
        slab(w, 0, 0.08 * k, sooted, r: 0.008)
        let torusY = 0.08 * k
        slab(w - 0.03, torusY, 0.045 * k, sooted, r: 0.02)
        slab(w - 0.06, torusY + 0.045 * k, 0.015 * k, sooted, r: 0.004)
        // Rusticated base course: two courses of V-jointed blocks per face.
        let rbY = torusY + 0.06 * k, rbH = 0.22 * k, rw = w - 0.07
        slab(rw - 0.03, rbY, rbH, sooted, r: 0.004)
        for face in 0..<4 {
            let q = simd_quatf(degrees: Float(face) * 90, axis: FA.Y)
            for c in 0..<2 {
                let n = c == 0 ? 3 : 2
                let bw = (rw - 0.012 * Float(n - 1)) / Float(n)
                for b in 0..<n {
                    let x = -rw / 2 + bw / 2 + Float(b) * (bw + 0.012)
                    let y = rbY + 0.006 + Float(c) * rbH / 2 + rbH / 4
                    let size = V3(bw - 0.004 + rng.float(-0.002...0.002), rbH / 2 - 0.014, 0.03)
                    m.add(Prim.roundedBox(size, radius: 0.009, bevelSegments: 1, material: sooted),
                          Xform(translation: q.act(V3(x, y, (rw - 0.03) / 2)), rotation: q))
                }
            }
        }
        // Base course cap (ovolo).
        let dieY = rbY + rbH
        slab(rw + 0.01, dieY, 0.025 * k, sooted, r: 0.012)
        // Die with recessed fields.
        let dw = w - 0.16, dieH = 0.5 * k, d0 = dieY + 0.025 * k
        slab(dw, d0, dieH, stone, r: 0.005)
        for face in 0..<4 {
            let q = simd_quatf(degrees: Float(face) * 90, axis: FA.Y)
            // Bolection frame around the field.
            let fw = dw - 0.1, fh = dieH - 0.1, cy = d0 + dieH / 2, z = dw / 2
            for (sz, c) in [(V3(fw, 0.022, 0.02), V3(0, cy + fh / 2, z)), (V3(fw, 0.022, 0.02), V3(0, cy - fh / 2, z)),
                            (V3(0.022, fh, 0.02), V3(-fw / 2, cy, z)), (V3(0.022, fh, 0.02), V3(fw / 2, cy, z))] {
                m.add(Prim.roundedBox(sz, radius: 0.008, bevelSegments: 1, material: stone), Xform(translation: q.act(c), rotation: q))
            }
            if face == 0 {
                // Cartouche: oval shield with scrolled frame and hanging swags.
                m.add(Prim.superellipsoid(V3(0.22, 0.28 * k, 0.05), exponent: 2.2, subdivisions: 4, material: stone),
                      Xform(translation: V3(0, cy, z + 0.006)))
                m.add(Prim.torus(major: 0.12, minor: 0.014, segments: 24, sides: 6, material: stone),
                      Xform(translation: V3(0, cy, z + 0.012), rotation: FA.q(90, FA.X), scale: V3(1, 1, 1.25 * k)))
                for s: Float in [-1, 1] {
                    // Laurel garland: beads swagging from a ribbon knot to the cartouche, with a pendant drop.
                    for i in 0...10 {
                        let t = Float(i) / 10
                        let r = 0.011 + 0.009 * sin(t * .pi)
                        let p = V3(s * (0.125 + t * 0.12), cy + 0.11 - sin(t * .pi) * 0.09 - t * 0.02, z + 0.012)
                        m.add(Prim.superellipsoid(V3(r * 2.4, r * 1.6, r * 1.4), exponent: 2, subdivisions: 2, material: stone),
                              Xform(translation: p, rotation: FA.q(s * (30 - t * 60) + Float(i % 2) * 25, FA.Z)))
                    }
                    FC.bead(&m, r: 0.016, at: V3(s * 0.25, cy + 0.09, z + 0.014), stone)
                    for j in 0..<3 {
                        FC.bead(&m, r: 0.012 - Float(j) * 0.003, at: V3(s * 0.25, cy + 0.06 - Float(j) * 0.03, z + 0.012), stone)
                    }
                }
            }
        }
        // Cornice cap: bed mould, dentils, corona, cyma, then the top weathered slab.
        let cY = d0 + dieH
        slab(dw + 0.04, cY, 0.03 * k, stone, r: 0.008)
        let dentY = cY + 0.03 * k
        slab(dw + 0.06, dentY, 0.05 * k, stone, r: 0.003)
        let nD = 10
        for face in 0..<4 {
            let q = simd_quatf(degrees: Float(face) * 90, axis: FA.Y)
            for i in 0..<nD {
                let x = -(dw + 0.06) / 2 + 0.03 + Float(i) * ((dw + 0.0) / Float(nD - 1))
                m.add(Prim.roundedBox(V3(0.032, 0.045 * k, 0.03), radius: 0.003, bevelSegments: 1, material: stone),
                      Xform(translation: q.act(V3(x, dentY + 0.025 * k, (dw + 0.06) / 2 + 0.012)), rotation: q))
            }
        }
        let coronaY = dentY + 0.05 * k
        slab(w - 0.02, coronaY, 0.07 * k, sooted, r: 0.006)
        slab(w - 0.05, coronaY + 0.07 * k, 0.025 * k, sooted, r: 0.012)
        let topY = coronaY + 0.095 * k
        // Lead weathering flashing dressed over the top, turned down at the edges.
        slab(w - 0.07, topY, height - topY - 0.022, sooted, r: 0.006)
        slab(w - 0.064, height - 0.022, 0.01, lead, r: 0.003)
        slab(w - 0.07, height - 0.04, 0.02, lead, r: 0.002)
        // Bronze statue foot plate with hex bolts.
        let pY = height - 0.012
        FA.box(&m, V3(0.42, 0.012, 0.36), V3(0, pY + 0.006, 0), bronze, r: 0.003)
        for (x, z) in [(Float(-0.17), Float(-0.14)), (0.17, -0.14), (-0.17, 0.14), (0.17, 0.14)] {
            hexBolt(&m, at: V3(x, pY + 0.012, z), normal: FA.Y, size: 0.022, material: "metal.steel")
        }
        // Soot and lichen: darker patches under the cornice drip and moss on the base torus.
        for i in 0..<6 {
            var r2 = rng.fork(i)
            let q = simd_quatf(degrees: Float(i % 4) * 90, axis: FA.Y)
            m.add(Prim.superellipsoid(V3(r2.float(0.06...0.12), 0.004, r2.float(0.03...0.06)), exponent: 2.5, subdivisions: 3, material: "stone.granite-moss"),
                  Xform(translation: q.act(V3(r2.float(-0.3...0.3), torusY + 0.045 * k, (w - 0.03) / 2 - 0.01)), rotation: q))
        }
        // Soot washes down the die from the cornice drip, heavier at the corners.
        for i in 0..<14 {
            var r3 = rng.fork(50 + i)
            let q = simd_quatf(degrees: Float(i % 4) * 90, axis: FA.Y)
            let x = (i % 3 == 0 ? (r3.chance(0.5) ? -1 : 1) * (dw / 2 - 0.03) : r3.float(-0.3...0.3))
            let len = r3.float(0.08...0.25) * k
            m.add(Prim.superellipsoid(V3(r3.float(0.01...0.03), len, 0.003), exponent: 2.6, subdivisions: 2, material: "stone.cast-grey"),
                  Xform(translation: q.act(V3(x, cY - len / 2 + 0.005, dw / 2 + 0.0005)), rotation: q))
        }
        m = FC.place(m)
        groundAO(&m, height: 0.15, floor: 0.9)
        return LODModel(m)
    }
}
