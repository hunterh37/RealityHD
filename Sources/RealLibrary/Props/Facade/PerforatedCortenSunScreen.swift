import simd
import Foundation

/// Perforated weathering-steel sun screen, 1.2 m wide, 2.4 m tall, 50 mm deep: a 3 mm corten sheet cut with ten by
/// twenty round perforations that grow from 24 mm at the head to 88 mm at the foot (modelled holes with cut walls on
/// both faces), solid ligament cells along the edges, 30 mm folded return flanges on all four sides, six cylindrical
/// stainless standoffs with hex bolts, and uneven patina. Wear: bright orange wet zone at the foot, dark mature head,
/// run-off streaks, white salt bloom under a bolt, one replacement bolt.
public struct PerforatedCortenSunScreen: RealAsset {
    public static let id = "perforated-corten-sun-screen"
    public static let summary = "Perforated corten sun screen 1.2x2.4 m: folded-edge panel, round hole pattern, standoffs."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 26, elevation: 6, distance: 4.4)

    /// Mature weathering steel.
    public var corten: MaterialKey = "metal.corten"
    /// Fresh, wet-zone patina.
    public var wet: MaterialKey = "metal.rust"
    /// Fasteners and spacers.
    public var steel: MaterialKey = "metal.stainless"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 1.2, H: Float = 2.4, t: Float = 0.003
        let cols = 10, rows = 20
        let p = W / Float(cols)
        let zf: Float = 0.039                                                // front face of the sheet

        func holeR(_ c: Int, _ r: Int) -> Float {
            if c == 0 || c == cols - 1 || r == 0 || r == rows - 1 { return 0 }
            let v = Float(r) / Float(rows - 1)                              // 0 at the foot, 1 at the head
            let g = 0.012 + 0.032 * (1 - v) * (1 - v) * (3 - 2 * (1 - v)) * 0.5 + 0.032 * (1 - v)   // grows toward the foot
            let wave = 0.88 + 0.12 * sin(Float(c) * 1.3 + Float(r) * 0.6)
            return min(g * wave, p * 0.5 - 0.016)
        }
        func isBoltCell(_ c: Int, _ r: Int) -> Bool { (c == 0 || c == cols - 1) && (r == 2 || r == 10 || r == 17) }

        var plates: [MaterialKey: Surface] = [corten: Surface(material: corten), wet: Surface(material: wet)]
        for r in 0..<rows { for c in 0..<cols {
            let x0 = -W / 2 + Float(c) * p, y0 = Float(r) * p
            let cx = x0 + p / 2, cy = y0 + p / 2
            let n = noise(c, r)
            let key = (n > 0.62 || (r < 3 && n > 0.3) || (r > 17 && n < 0.15)) ? wet : corten
            var s = plates[key]!
            let R = holeR(c, r)
            if R <= 0 {
                // Solid cell: front and back quads.
                for (z, nz) in [(zf, Float(1)), (zf - t, Float(-1))] as [(Float, Float)] {
                    let b = UInt32(s.positions.count)
                    for (px, py) in [(x0, y0), (x0 + p, y0), (x0 + p, y0 + p), (x0, y0 + p)] as [(Float, Float)] {
                        s.add(V3(px, py, z), V3(0, 0, nz), V2(px, py))
                    }
                    if nz > 0 { s.quad(b, b + 1, b + 2, b + 3) } else { s.quad(b, b + 3, b + 2, b + 1) }
                }
            } else {
                let n8 = 8
                var hole: [V2] = [], sq: [V2] = []
                for k in 0..<n8 {
                    let a = Float(k) * .pi / 4
                    hole.append(V2(cos(a) * R, sin(a) * R))
                    let d = max(abs(cos(a)), abs(sin(a)))
                    sq.append(V2(cos(a) / d * p / 2, sin(a) / d * p / 2))
                }
                for (z, nz) in [(zf, Float(1)), (zf - t, Float(-1))] as [(Float, Float)] {
                    for k in 0..<n8 {
                        let k1 = (k + 1) % n8
                        let b = UInt32(s.positions.count)
                        for q in [hole[k], hole[k1], sq[k1], sq[k]] { s.add(V3(cx + q.x, cy + q.y, z), V3(0, 0, nz), V2(cx + q.x, cy + q.y)) }
                        if nz > 0 { s.quad(b, b + 1, b + 2, b + 3) } else { s.quad(b, b + 3, b + 2, b + 1) }
                    }
                }
                // Cut wall of the hole, facing inward.
                for k in 0..<n8 {
                    let k1 = (k + 1) % n8
                    let a0 = hole[k], a1 = hole[k1]
                    let mid = (a0 + a1) / 2
                    let nn = simd_normalize(V3(-mid.x, -mid.y, 0))
                    let b = UInt32(s.positions.count)
                    s.add(V3(cx + a0.x, cy + a0.y, zf), nn, V2(0, 0))
                    s.add(V3(cx + a1.x, cy + a1.y, zf), nn, V2(0.02, 0))
                    s.add(V3(cx + a1.x, cy + a1.y, zf - t), nn, V2(0.02, t))
                    s.add(V3(cx + a0.x, cy + a0.y, zf - t), nn, V2(0, t))
                    s.quad(b, b + 1, b + 2, b + 3)
                }
            }
            plates[key] = s
        }}
        for (_, var s) in plates where !s.positions.isEmpty {
            s.recomputeNormals(weldSeams: false)
            s.computeTangents()
            m.add(s)
        }

        // Folded return flanges on all four edges with rounded bends.
        let fd: Float = 0.03
        FA.box(&m, V3(W, t, fd), V3(0, H - t / 2, zf - t - fd / 2 + 0.0015), corten, r: 0.0012)
        FA.box(&m, V3(W, t, fd), V3(0, t / 2, zf - t - fd / 2 + 0.0015), wet, r: 0.0012)
        for e: Float in [-1, 1] { FA.box(&m, V3(t, H, fd), V3(e * (W / 2 - t / 2), H / 2, zf - t - fd / 2 + 0.0015), e > 0 ? corten : wet, r: 0.0012) }
        // Bend radius bead along the fold.
        for e: Float in [-1, 1] {
            FA.rod(&m, V3(e * (W / 2 - 0.001), 0.001, zf - 0.0015), V3(e * (W / 2 - 0.001), H - 0.001, zf - 0.0015), r: 0.0026, corten, sides: 6)
        }
        FA.rod(&m, V3(-W / 2 + 0.001, H - 0.001, zf - 0.0015), V3(W / 2 - 0.001, H - 0.001, zf - 0.0015), r: 0.0026, corten, sides: 6)
        FA.rod(&m, V3(-W / 2 + 0.001, 0.001, zf - 0.0015), V3(W / 2 - 0.001, 0.001, zf - 0.0015), r: 0.0026, wet, sides: 6)

        // Standoffs: stainless spacer tube on a wall plate, bolt through the sheet with a hex head on the front.
        for c in [0, cols - 1] { for r in [2, 10, 17] {
            let cx = -W / 2 + (Float(c) + 0.5) * p, cy = (Float(r) + 0.5) * p
            m.add(Prim.cylinder(radius: 0.0125, height: zf - t - 0.003, bevel: 0.002, segments: 14, bevelSegments: 1, material: steel),
                  Xform(translation: V3(cx, cy, 0.003), rotation: FA.q(90, FA.X)))
            FA.cylZ(&m, r: 0.018, h: 0.003, at: V3(cx, cy, 0.0), steel, bevel: 0.0008, segments: 14)                           // wall plate
            FA.cylZ(&m, r: 0.0125, h: 0.0016, at: V3(cx, cy, zf + 0.0001), "metal.satin-aluminum", bevel: 0.0005, segments: 12) // washer
            hexBolt(&m, at: V3(cx, cy, zf + 0.0016), normal: FA.Z, size: 0.0145, material: (c == 0 && r == 10) ? "metal.bolt-bright" : steel)
            // Corten staining around the fixing: rust halo and a run below.
            FJ.slab(&m, V3(0.04, 0.04, 0.0012), V3(cx, cy, zf + 0.0006), wet)
            FJ.slab(&m, V3(0.011, rng.float(0.1...0.22), 0.0012), V3(cx + rng.float(-0.008...0.008), cy - 0.08, zf + 0.0004), "metal.rust-grime")
        }}
        // Salt bloom under the middle bolt, and dark mature patches near the head.
        FJ.slab(&m, V3(0.05, 0.08, 0.0012), V3(-W / 2 + 0.5 * p, 10.5 * p - 0.07, zf + 0.0008), "stone.limestone")
        for _ in 0..<12 {
            let c = rng.int(1...cols - 2), r = rng.int(0...rows - 1)
            if holeR(c, r) <= 0 { continue }
            FJ.slab(&m, V3(0.004, rng.float(0.03...0.07), 0.0012), V3(-W / 2 + (Float(c) + 0.5) * p + holeR(c, r) * rng.float(-0.9...0.9), (Float(r) + 0.5) * p - holeR(c, r) - 0.02, zf + 0.0004), "metal.rust-grime")
        }
        groundAO(&m, height: 0.25, floor: 0.7)
        return LODModel(FC.place(m))
    }

    func noise(_ c: Int, _ r: Int) -> Float {
        let x = Float(c), y = Float(r)
        let v = sin(x * 1.7 + y * 0.9) * 0.5 + sin(x * 0.7 - y * 1.3 + 2) * 0.3 + sin(x * 2.9 + y * 2.1) * 0.2
        return v * 0.5 + 0.5
    }
}
