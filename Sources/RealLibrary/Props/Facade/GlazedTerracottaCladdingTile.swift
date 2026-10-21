import simd
import Foundation

/// Art Deco glazed architectural terracotta (faience) tile, 600 mm square: a bisque body with a raised
/// border bead, three stepped chevrons over a band of vertical reeds, all under a glossy green faience
/// glaze with a gold-glazed apex. Galvanized anchor tabs at the top and bottom, buttered mortar joints,
/// and one chipped corner showing the bisque.
public struct GlazedTerracottaCladdingTile: RealAsset {
    public static let id = "glazed-terracotta-cladding-tile"
    public static let summary = "Glazed terracotta tile, 0.6 m square: stepped chevron relief in glossy faience glaze with crazing, buttered joints and anchor tabs."
    public static let tags = ["prop", "architecture", "facade", "decor"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 22, elevation: 12, distance: 1.25)

    /// Tile size in meters (square).
    public var size: Float = 0.6
    /// Field glaze.
    public var glaze: MaterialKey = "ceramic.celadon:2F6E5E"
    /// Accent glaze on the chevron apex and bead.
    public var accent: MaterialKey = "ceramic.celadon:C9A84A"
    /// Exposed body.
    public var bisque: MaterialKey = "ceramic.bisque"
    /// Joint mortar.
    public var mortar: MaterialKey = "concrete.smooth:C8C2B4"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let S = size, joint: Float = 0.008, s = S - joint, zb: Float = 0.006, t: Float = 0.024
        let cx: Float = 0, cy = S / 2
        // Buttered mortar joint frame and bed.
        FA.box(&m, V3(S, S, zb), V3(0, cy, zb / 2), mortar, r: 0.001)
        for (w, h, x, y) in [(S, joint, 0, joint / 2), (S, joint, 0, S - joint / 2), (joint, S, -S / 2 + joint / 2, cy), (joint, S, S / 2 - joint / 2, cy)] as [(Float, Float, Float, Float)] {
            FA.box(&m, V3(w, h, t * 0.7), V3(x, y, zb + t * 0.35), mortar, r: 0.002)
        }
        // Tile body (bisque) with glazed face sheet carrying faint crazing ripples.
        FA.box(&m, V3(s - 0.004, s - 0.004, t), V3(cx, cy, zb + t / 2), bisque, r: 0.004)
        FCL.face(&m, w: s - 0.006, h: s - 0.006, seg: 36, at: V3(cx, cy, zb + t + 0.0004), glaze) { px, py in
            let e = FCL.edge(px, py, s - 0.006, s - 0.006, 0.006)
            let c: Float = abs(Noise.perlin(V3(px * 70, py * 70, 2))) < 0.03 ? -0.00025 : 0
            let wave: Float = 0.0003 * Noise.fbm(V3(px * 12, py * 12, 5), octaves: 2)
            let base: Float = 0.0012 + c + wave
            return e * base
        }
        let face = zb + t + 0.0016
        // Raised border bead.
        let bw: Float = 0.018, inset: Float = 0.03
        for (w, h, x, y) in [(s - 2 * inset, bw, 0, inset), (s - 2 * inset, bw, 0, s - inset), (bw, s - 2 * inset, -s / 2 + inset, cy), (bw, s - 2 * inset, s / 2 - inset, cy)] as [(Float, Float, Float, Float)] {
            FA.box(&m, V3(w + bw, h, 0.008), V3(x, y + (y == cy ? 0 : joint / 2), face + 0.003), glaze, r: 0.004)
        }
        // Three stepped chevrons, each a step higher than the one below.
        for k in 0..<3 {
            let w = s - 0.16 - Float(k) * 0.02, rise = w * 0.42, y0 = cy - 0.07 + Float(k) * 0.06
            let hw = w / 2, arm: Float = 0.03 - Float(k) * 0.004
            let d: Float = 0.004 + Float(k) * 0.002
            let mat: MaterialKey = k == 2 ? accent : (k == 1 ? "ceramic.celadon:1F4F44" : glaze)
            let len = (hw * hw + rise * rise).squareRoot(), ang = atan2(rise, hw) * 180 / .pi
            for sx in [-1, 1] as [Float] {
                // Each arm runs from the outer foot to the apex; the arm's top edge meets at the apex.
                let mid = V3(cx + sx * hw / 2, y0 + rise / 2 - arm * 0.5, face + d / 2 + Float(k) * 0.001)
                FA.box(&m, V3(len + arm * 0.6, arm, d), mid, mat, r: 0.0015, rot: FA.q(-sx * ang, FA.Z))
            }
        }
        // Reeded band below: vertical half-round reeds.
        let reeds = 9, rw: Float = 0.026
        for i in 0..<reeds {
            let x = (Float(i) - Float(reeds - 1) / 2) * (rw + 0.006)
            m.add(Prim.cylinder(radius: rw / 2, height: 0.16, bevel: 0.004, segments: 12, bevelSegments: 1, material: glaze),
                  Xform(translation: V3(x, 0.07, face - rw * 0.2), scale: V3(1, 1, 0.55)))
        }
        // Chipped corner exposing the bisque.
        FCL.face(&m, w: 0.03, h: 0.022, seg: 8, at: V3(s / 2 - 0.018, s - 0.012, face + 0.0003), bisque) { px, py in
            -0.0008 * FCL.edge(px, py, 0.03, 0.022, 0.008) * (1 + 0.4 * Noise.perlin(V3(px * 200, py * 200, 1)))
        }
        // Galvanized anchor tabs top and bottom, wired into the joint.
        for x in [-0.15, 0.15] as [Float] {
            FA.box(&m, V3(0.03, 0.024, 0.004), V3(x, S - 0.012, zb * 0.5), "metal.galvanized", r: 0.0008)
            FA.box(&m, V3(0.03, 0.024, 0.004), V3(x, 0.012, zb * 0.5), "metal.galvanized", r: 0.0008)
            FA.box(&m, V3(0.004, 0.004, joint), V3(x, S - joint / 2, zb + joint / 2), "metal.galvanized", r: 0.001) // tie wire bent into the joint
        }
        groundAO(&m, height: 0.03, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
