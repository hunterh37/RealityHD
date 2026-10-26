import simd
import Foundation

/// Glazed terracotta spandrel, Chicago School: a 2.0 x 0.8 m panel of eight cream-glazed terracotta
/// tiles (500 x 355 mm, 6 mm joints), each moulded with a Sullivan-style raised border, interlaced ring
/// and eight-petal rosette, under a glazed coping. Crazing hairlines, iron staining and a spalled corner
/// exposing the red body.
public struct GlazedTerracottaSpandrel: RealAsset {
    public static let id = "glazed-terracotta-spandrel"
    public static let summary = "Glazed terracotta spandrel, 2.0 x 0.8 m: eight relief tiles, joints, glazed coping, crazing, spalled corner."
    public static let tags = ["prop", "architecture", "facade", "stone", "trim"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 18, elevation: 8, distance: 3.6)

    /// Cream glaze.
    public var glaze: MaterialKey = "ceramic.celadon"
    /// Red clay body showing at chips and edges.
    public var body: MaterialKey = "ceramic.terracotta"
    /// Mortar and backing.
    public var mortar: MaterialKey = "stone.limestone"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 2.0, tw: Float = 0.5, th: Float = 0.355, jt: Float = 0.006
        let tz: Float = 0.062          // tile glazed face
        let H: Float = 0.8, copH: Float = 0.08
        // Backing wall with raked mortar.
        FA.box(&m, V3(W, H - copH, 0.012), V3(0, (H - copH) / 2, 0.006), "stone.limestone-sooted", r: 0.001)
        for row in 0..<2 {
            for col in 0..<4 {
                let cx = -W / 2 + tw / 2 + Float(col) * tw, cy = th / 2 + Float(row) * (th + jt) + 0.01
                // Clay body, then the glazed face skinned over it as a relief heightfield.
                FA.box(&m, V3(tw - jt, th, tz - 0.014), V3(cx, cy, 0.012 + (tz - 0.014) / 2), body, r: 0.003)
                let ph = rng.float(0...6.28)
                FCL.grid(&m, w: tw - jt - 0.004, h: th - 0.004, nx: 26, ny: 20, at: V3(cx, cy, tz), glaze) { x, y in
                    let hx = (tw - jt) / 2, hy = th / 2
                    // Border band with a stepped inner fillet.
                    let e = min(hx - abs(x), hy - abs(y))
                    var h: Float = e < 0.02 ? 0.009 * FL.smooth(max(0, min(1, (0.02 - e) / 0.012 + 0.2))) : 0
                    if e < 0.034 && e >= 0.02 { h = 0.012 * FL.smooth(1 - (e - 0.02) / 0.014) * 0.6 }
                    // Interlaced ring and rosette.
                    let r = sqrt(x * x + y * y), a = atan2(y, x)
                    let ring = exp(-pow((r - 0.115) / 0.014, 2)) * 0.012
                    let lobes = exp(-pow((r - 0.06 * (1 + 0.28 * cos(8 * a + ph * 0))) / 0.012, 2)) * 0.010
                    let boss = exp(-pow(r / 0.018, 2)) * 0.012
                    // Corner quatrefoil leaves.
                    let cxn = abs(x) - (hx - 0.062), cyn = abs(y) - (hy - 0.062)
                    let leaf = exp(-(cxn * cxn + cyn * cyn) / 0.00025) * 0.008
                    return h + ring + lobes + boss + leaf
                }
                // Crazing hairlines.
                for _ in 0..<3 {
                    let x = cx + rng.float(-0.2...0.2), y = cy + rng.float(-0.14...0.14)
                    FJ.slab(&m, V3(rng.float(0.04...0.12), 0.0007, 0.0006), V3(x, y, tz + 0.0006), "stone.limestone-sooted", rot: FA.q(rng.float(-60...60), FA.Z))
                }
            }
        }
        // Spalled corner on the top-right tile exposing the clay body, and iron stain below the coping.
        // Spalled corner on the top-right tile exposing the clay body, and iron-stain runs under the coping.
        FA.box(&m, V3(0.075, 0.055, 0.004), V3(W / 2 - 0.045, th * 2 + jt + 0.01 - 0.03, tz + 0.001), body, r: 0.002, rot: FA.q(8, FA.Z))
        FA.box(&m, V3(0.05, 0.04, 0.004), V3(-W / 2 + 0.04, 0.045, tz + 0.001), body, r: 0.002, rot: FA.q(-10, FA.Z))
        for (sx, sy, h) in [(Float(-0.33), th * 2 - 0.09, Float(0.12)), (0.62, th * 2 - 0.08, 0.1)] {
            m.add(Prim.superellipsoid(V3(0.03, h, 0.003), exponent: 2.6, subdivisions: 3, material: "metal.rust"), Xform(translation: V3(sx, sy, tz + 0.003)))
        }
        // Glazed coping: bed, cavetto and a drip.
        let cop: [V2] = [V2(0, H - copH), V2(0.1, H - copH), V2(0.1, H - copH + 0.01), V2(0.092, H - copH + 0.018), V2(0.082, H - copH + 0.05),
                         V2(0.094, H - copH + 0.062), V2(0.094, H), V2(0, H)]
        let cl = (W - 3 * jt) / 4
        for k in 0..<4 { FA.run(&m, cop, length: cl, at: V3(-W / 2 + cl / 2 + Float(k) * (cl + jt), 0.0, 0), glaze, bevel: 0.0012) }
        groundAO(&m, height: 0.1, floor: 0.85)
        return LODModel(FC.place(m))
    }
}
