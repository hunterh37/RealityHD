import simd
import Foundation

/// Victorian Commercial glass prism transom row, 2.0 x 0.4 x 0.1 m: eight pyramid-faceted prism glass tiles (2 x 3 facets each) held
/// by nine cast iron muntins and stiles under a moulded cast cap rail on a sloped wood sill, with putty beads around each tile,
/// screw heads, corner brackets and a dirt line. Three tiles have turned purple in the sun and one is cracked. Base on y = 0.
public struct GlassPrismTransomRow: RealAsset {
    public static let id = "glass-prism-transom-row"
    public static let summary = "Victorian Commercial glass prism transom row, 2.0 x 0.4 m: eight prism tiles in a cast iron grid, rail, sill, brackets, fasteners, grime."
    public static let tags = ["prop", "architecture", "facade", "window", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 6, distance: 2.7)

    /// Run length in meters.
    public var length: Float = 2.0
    /// Aqua prism glass.
    public var glass: MaterialKey = "glass.frosted:BFD9D0"
    /// Sun-purpled manganese glass.
    public var purple: MaterialKey = "glass.frosted:AD93CC"
    /// Painted cast iron.
    public var iron: MaterialKey = "metal.painted:2F2E2A"
    public var rust: MaterialKey = "metal.rust"
    public var wood: MaterialKey = "wood.weathered"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = length, D: Float = 0.088
        let sillH: Float = 0.04, capH: Float = 0.045
        let top = 0.4 - capH
        let n = 8
        let pitch = (L - 0.05) / Float(n)            // muntin centres: ends at +-(L/2 - 0.025)
        let x0 = -L / 2 + 0.025

        // Wood sill with a sloped top and a drip nose.
        let sill: [V2] = [V2(0, 0), V2(D + 0.012, 0), V2(D + 0.012, 0.012), V2(D, 0.016), V2(0, sillH)]
        FA.run(&m, sill, length: L, wood, bevel: 0.002)
        // Moulded cast cap rail: fillet, cove and bead.
        let cap: [V2] = [V2(0, 0), V2(D, 0), V2(D, 0.012), V2(D - 0.008, 0.02), V2(D - 0.008, 0.03), V2(D, 0.036), V2(D, capH), V2(0, capH)]
        FA.run(&m, cap, length: L, at: V3(0, top, 0), iron, bevel: 0.002)

        // Muntins and end stiles: cast T-section (web 18 mm x 70 mm deep, flange 30 x 8 mm at the face).
        let mh = top - sillH
        for i in 0...n {
            let x = x0 + Float(i) * pitch
            let end = i == 0 || i == n
            FA.box(&m, V3(end ? 0.05 : 0.018, mh, 0.07), V3(x, sillH + mh / 2, D / 2), iron, r: 0.002)
            FA.box(&m, V3(end ? 0.05 : 0.032, mh, 0.008), V3(x, sillH + mh / 2, D - 0.014), iron, r: 0.002)
        }

        // Tiles.
        let tw = pitch - 0.018 - 0.006, th = mh - 0.008
        let purpleTiles: Set<Int> = [1, 4, 6]
        for i in 0..<n {
            let cx = x0 + (Float(i) + 0.5) * pitch
            let cy = sillH + mh / 2
            let mat = purpleTiles.contains(i) ? purple : glass
            FO8.slab(&m, tw, th, 0.007, V3(cx, cy, D / 2), mat, bevel: 0.001)
            // 2 x 3 pyramid facets on the street face.
            let fw = tw / 2, fh = th / 3
            for cxi in 0..<2 {
                for cyi in 0..<3 {
                    let px = cx - tw / 2 + fw * (Float(cxi) + 0.5)
                    let py = cy - th / 2 + fh * (Float(cyi) + 0.5)
                    m.add(Prim.loft([Prim.ring(Shape2D.rect(fw - 0.002, fh - 0.002), y: 0), Prim.ring(Shape2D.rect(0.004, 0.004), y: 0.015)],
                                    capStart: true, capEnd: true, material: mat),
                          Xform(translation: V3(px, py, D / 2 + 0.0035), rotation: FA.q(90, FA.X)))
                }
            }
            // Putty bead around the tile, on the inside of the flange.
            let pm: MaterialKey = "metal.painted:B7AE98"
            FO8.slab(&m, tw + 0.004, 0.006, 0.006, V3(cx, cy + th / 2 + 0.001, D / 2 + 0.004), pm, bevel: 0.0012)
            FO8.slab(&m, tw + 0.004, 0.006, 0.006, V3(cx, cy - th / 2 - 0.001, D / 2 + 0.004), pm, bevel: 0.0012)
            for s: Float in [-1, 1] { FO8.slab(&m, 0.006, th, 0.006, V3(cx + s * (tw / 2 + 0.001), cy, D / 2 + 0.004), pm, bevel: 0.0012) }
            // Dirt line along the bottom of every tile.
            FO8.slab(&m, tw - 0.006, 0.012, 0.0014, V3(cx, cy - th / 2 + 0.012, D / 2 + 0.0092), "metal.painted:6C675B", bevel: 0.0004)
        }
        // Cracked tile: three hairlines radiating from a corner impact, frosted white.
        let ct = x0 + 5.5 * pitch
        for (ang, ln) in [(Float(24), Float(0.14)), (-12, 0.11), (63, 0.08)] {
            FA.box(&m, V3(ln, 0.003, 0.002), V3(ct - 0.03 + ln * 0.35 * cos(ang * .pi / 180), 0.2 + ln * 0.35 * sin(ang * .pi / 180), D / 2 + 0.0115), "metal.painted:E8E6DE", r: 0.0006, rot: FA.q(ang, FA.Z))
        }

        // Screw heads along the cap rail face and the sill nose, brass-free iron slotted heads; rust at a few.
        var sx: Float = -L / 2 + 0.06
        var idx = 0
        while sx < L / 2 - 0.04 {
            rivet(&m, at: V3(sx, top + 0.022, D + 0.0002), normal: FA.Z, radius: 0.0055, segments: 6, material: idx % 5 == 2 ? rust : "metal.painted:2F2E2A")
            sx += 0.11
            idx += 1
        }
        // Corner brackets: cast spandrel triangles under the cap rail at both ends, 4 screws each.
        for e: Float in [-1, 1] {
            let bx = e * (L / 2 - 0.05)
            let tri: [V2] = [V2(0, 0), V2(0.07 * -e, 0), V2(0, -0.07)]
            m.add(Prim.extrude(tri.map { V2($0.x, $0.y) }, depth: 0.02, bevel: 0.002, bevelSegments: 1, material: iron),
                  Xform(translation: V3(bx + e * 0.0, top - 0.002, D - 0.02)))
            rivet(&m, at: V3(bx - e * 0.03, top - 0.012, D - 0.009), normal: FA.Z, radius: 0.0055, segments: 6, material: rust)
        }

        // Wear: rust bleed from the screw heads, flaked paint on the cap rail, rain-stained sill, grime in the sill rebate.
        for _ in 0..<9 {
            let wx = rng.float(-L / 2 + 0.1...L / 2 - 0.1)
            FO8.slab(&m, rng.float(0.006...0.012), rng.float(0.02...0.05), 0.0012, V3(wx, top - 0.02, D + 0.0008), "metal.rust:7A4A2E", bevel: 0.0003)
        }
        for _ in 0..<8 {
            let wx = rng.float(-L / 2 + 0.1...L / 2 - 0.1)
            FO8.slab(&m, rng.float(0.03...0.08), rng.float(0.008...0.016), 0.0012, V3(wx, top + 0.022, D + 0.0003), rng.chance(0.5) ? rust : "metal.cast-iron", bevel: 0.0003)
        }
        FA.box(&m, V3(L - 0.1, 0.004, 0.06), V3(0, sillH + 0.001 - 0.0, 0.055), "metal.painted:4A4338", r: 0.001)
        for _ in 0..<6 {
            let wx = rng.float(-L / 2 + 0.1...L / 2 - 0.1)
            FO8.slab(&m, rng.float(0.03...0.1), rng.float(0.006...0.012), 0.0012, V3(wx, 0.008, D + 0.0126), "wood.weathered:58564E", bevel: 0.0003)
        }

        groundAO(&m, height: 0.05, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
