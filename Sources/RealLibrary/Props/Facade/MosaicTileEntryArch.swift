import simd
import Foundation

/// Moorish Revival tiled entry arch, 1.6 x 2.6 m: horseshoe arch of alternating cobalt, celadon and limestone
/// voussoirs set in an alfiz rectangle banded with mosaic tile, stepped jamb pilasters with tiled dados, a
/// carved cornice and a limestone threshold plinth. The opening is clear. Wall face at z = 0.2.
public struct MosaicTileEntryArch: RealAsset {
    public static let id = "mosaic-tile-entry-arch"
    public static let summary = "Moorish Revival tiled entry arch, 1.6 x 2.6 m: horseshoe arch of tile voussoirs, alfiz band, tiled jambs, threshold."
    public static let tags = ["prop", "architecture", "facade", "stone", "decor", "trim"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 10, distance: 2.7)

    /// Cobalt tile.
    public var cobalt: MaterialKey = "ceramic.cobalt"
    /// Celadon tile.
    public var celadon: MaterialKey = "ceramic.celadon"
    /// Limestone dressings.
    public var stone: MaterialKey = "stone.limestone"
    /// Mortar between tiles.
    public var mortar: MaterialKey = "brick.mortar-grey"
    /// Terracotta field tile.
    public var terracotta: MaterialKey = "ceramic.terracotta"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 1.6, H: Float = 2.6, D: Float = 0.2
        let jamb: Float = 0.25
        let openW: Float = W - jamb * 2     // 1.1 m clear
        let R: Float = openW / 2 * 1.04       // horseshoe radius > half span
        let spring: Float = 1.45
        let hw = openW / 2
        // Backing mass: piers and head wall (mortar), behind the tiles.
        for s: Float in [-1, 1] {
            FC.brickBox(&m, V3(jamb, spring, D - 0.02), V3(s * (hw + jamb / 2), spring / 2, (D - 0.02) / 2), mortar, r: 0.003)
        }
        // Head wall above the arch: outline of a rectangle with the horseshoe cut out (two sides built from fan polys).
        let cy = spring
        let apex = cy + sqrt(R * R - 0)    // top of the horseshoe circle
        func archPoint(_ a: Float, _ r: Float) -> V2 { V2(cos(a) * r, cy + sin(a) * r) }
        // Horseshoe arc runs from angle -asin(hw/R)... use the circle arc from just below the centre line.
        let drop = asin(min(0.999, hw / R))
        let a0 = -(.pi / 2 - drop) * 0 - 0.22    // start slightly below the spring (horseshoe returns inward)
        let a1 = Float.pi - a0
        // Voussoirs: 23 tiles around the arc, alternating colour, projecting 0.06 beyond the head wall.
        let vN = 23
        for i in 0..<vN {
            let u0 = a0 + (a1 - a0) * Float(i) / Float(vN), u1 = a0 + (a1 - a0) * Float(i + 1) / Float(vN)
            let um = (u0 + u1) / 2
            let band: Float = 0.19
            let chord = (R + band / 2) * (u1 - u0) - 0.008
            let mat = (i == vN / 2) ? stone : (i % 2 == 0 ? cobalt : celadon)
            let c = archPoint(um, R + band / 2)
            FC.brickBox(&m, V3(chord, band, D - 0.02), V3(c.x, c.y, (D - 0.02) / 2 + 0.012), mat, r: 0.003, rot: FA.q(um * 180 / .pi - 90, FA.Z))
            // Tile gouge: occasional chipped tile in terracotta ground showing through.
            if rng.chance(0.08) {
                FC.brickBox(&m, V3(chord * 0.5, 0.02, 0.003), V3(c.x, c.y, D - 0.0075 + 0.012), terracotta, r: 0.001, rot: FA.q(um * 180 / .pi - 90, FA.Z))
            }
        }
        // Extrados moulding: thin limestone ring around the voussoirs.
        var ring: [V3] = []
        for i in 0...28 {
            let u = a0 + (a1 - a0) * Float(i) / 28
            let p = archPoint(u, R + 0.2)
            ring.append(V3(p.x, p.y, D - 0.016))
        }
        let rp: [V2] = [V2(-0.014, 0), V2(0.014, 0), V2(0.014, 0.009), V2(0.006, 0.014), V2(-0.006, 0.014), V2(-0.014, 0.009)]
        m.add(Prim.sweep(rp.map { V2($0.y, $0.x) }, along: ring, up: FA.Z, caps: true, material: stone))
        // Spandrel panels: terracotta tile infill beside the arch inside the alfiz, with a tile rosette each.
        let top = cy + R + 0.215
        let alfizL = -W / 2 + 0.03, alfizR = W / 2 - 0.03, alfizT: Float = H - 0.12
        _ = apex
        for s: Float in [-1, 1] {
            let x0 = s > 0 ? hw + 0.05 : -(hw + jamb - 0.03)
            let w = jamb - 0.08 + 0.0
            _ = x0
            // Tile rosette.
            let rc = V3(s * (hw + jamb / 2), (spring + alfizT) / 2 + 0.2, D - 0.0275)
            for k in 0..<8 {
                let a = Float(k) * .pi / 4
                FC.brickBox(&m, V3(0.07, 0.034, 0.007), rc + V3(cos(a) * 0.06, sin(a) * 0.06, 0), k % 2 == 0 ? cobalt : celadon, r: 0.002, rot: FA.q(a * 180 / .pi, FA.Z))
            }
            FA.cylZ(&m, r: 0.034, h: 0.009, at: rc - V3(0, 0, 0.002), stone, bevel: 0.002, segments: 14)
        }
        // Spandrels: terracotta fill from the extrados up to the alfiz top on each side of the crown.
        for s: Float in [-1, 1] {
            var poly: [V2] = []
            for i in 0...10 {
                let u = Float.pi / 2 + (a0 - Float.pi / 2) * Float(i) / 10
                let p = archPoint(u, R + 0.19)
                poly.append(V2(s * p.x, p.y))
            }
            let last = poly[poly.count - 1]
            poly.append(V2(s * (W / 2 - 0.03), last.y))
            poly.append(V2(s * (W / 2 - 0.03), alfizT))
            poly.append(V2(0, alfizT))
            FM.prism(&m, Shape2D.deduped(poly), front: D - 0.04, depth: D - 0.04, terracotta, bevel: 0.003)
        }
        // Diamond tile band above the crown, alternating cobalt and celadon on edge.
        let bandY = alfizT - 0.16
        for k in 0..<17 {
            let dx = -0.56 + Float(k) * 0.07
            FC.brickBox(&m, V3(0.05, 0.05, 0.01), V3(dx, bandY, D - 0.04 + 0.005), k % 2 == 0 ? cobalt : celadon, r: 0.002, rot: FA.q(45, FA.Z))
        }
        // Alfiz frame: rectangular border of mosaic tile bands, alternating cobalt and celadon, 0.07 wide.
        let bt: Float = 0.07, tile: Float = 0.07
        func tileRun(_ a: V3, _ b: V3, tmat: Bool) {
            let len = simd_length(b - a), n = max(1, Int(len / tile))
            let dir = (b - a) / len
            for i in 0..<n {
                let p = a + dir * ((Float(i) + 0.5) * len / Float(n))
                let along = dir.x != 0 ? V3(len / Float(n) - 0.006, bt - 0.006, 0.02) : V3(bt - 0.006, len / Float(n) - 0.006, 0.02)
                FC.brickBox(&m, along, p, (i + (tmat ? 1 : 0)) % 2 == 0 ? cobalt : celadon, r: 0.002)
            }
        }
        let zc: Float = D - 0.03
        tileRun(V3(alfizL + bt / 2, bt / 2 + 0.0, zc), V3(alfizL + bt / 2, alfizT, zc), tmat: false)
        tileRun(V3(alfizR - bt / 2, bt / 2 + 0.0, zc), V3(alfizR - bt / 2, alfizT, zc), tmat: true)
        // Top run, across the full width.
        tileRun(V3(alfizL + bt, alfizT - bt / 2, zc), V3(alfizR - bt, alfizT - bt / 2, zc), tmat: false)
                // Stepped jamb pilasters: a tile dado up to 0.9 m, limestone shaft above, with a bead capital.
        for s: Float in [-1, 1] {
            let jx = s * (hw + jamb / 2)
            FC.brickBox(&m, V3(jamb - 0.04, spring - 0.1, 0.02), V3(jx, 0.065 + (spring - 0.1) / 2, D - 0.01), mortar, r: 0.002)
            // Zellige dado: columns of 70 mm tiles in cobalt, celadon and terracotta on the diagonal.
            let rows = Int((spring - 0.2) / 0.075)
            for r in 0..<rows { for c in 0..<3 {
                let tx = jx + (Float(c) - 1) * 0.073
                let ty = 0.1 + Float(r) * 0.075 + 0.0375
                let k = (r + c) % 3
                let mat: MaterialKey = k == 0 ? cobalt : (k == 1 ? celadon : terracotta)
                FC.brickBox(&m, V3(0.068, 0.068, 0.009), V3(tx, ty, D - 0.0045), mat, r: 0.0015)
            } }
            FC.brickBox(&m, V3(jamb - 0.04, 0.03, 0.024), V3(jx, spring - 0.065, D - 0.012), stone, r: 0.004)
            // Capital: a lathe-turned bead and block at the spring line.
            FC.brickBox(&m, V3(jamb - 0.02, 0.05, 0.03), V3(jx, spring - 0.025, D - 0.015), stone, r: 0.005)
        }
        // Carved cornice: two stepped limestone courses and a drip on top of the alfiz.
        FC.brickBox(&m, V3(W, 0.04, 0.16), V3(0, H - 0.1, 0.08), stone, r: 0.004)
        FC.brickBox(&m, V3(W, 0.06, 0.2), V3(0, H - 0.03, 0.1), stone, r: 0.006)
        FC.brickBox(&m, V3(W - 0.04, 0.012, 0.012), V3(0, H - 0.06, D - 0.002), mortar, r: 0.002)
        // Threshold plinth: limestone step with worn centre.
        FC.brickBox(&m, V3(openW + 0.2, 0.06, 0.2), V3(0, 0.03, 0.1), stone, r: 0.004)
        FC.brickBox(&m, V3(0.6, 0.004, 0.14), V3(0, 0.0605, 0.12), "stone.limestone-sooted", r: 0.001)
        groundAO(&m, height: 0.4, floor: 0.82)
        return LODModel(FC.place(m))
    }
}
