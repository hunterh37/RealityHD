import simd
import Foundation

/// Four-sided stainless box grater standing on a rolled base rim: coarse staggered teeth, fine rasp
/// teeth, a slicing slot with a blade lip, and punched dimples, with a riveted arched top handle.
public struct BoxGrater: RealAsset {
    public static let id = "box-grater"
    public static let summary = "Stainless box grater: coarse, fine, slicer and punched faces, rolled base and top rims, riveted arch handle."
    public static let tags = ["prop", "interior", "kitchen", "metal", "tool", "cookware"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 25, distance: 0.7, studio: true)

    /// Body finish.
    public var bodyMaterial: MaterialKey = "metal.stainless-smudged"
    /// Tooth and trim finish.
    public var trimMaterial: MaterialKey = "metal.stainless"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 0.090, Dp: Float = 0.062, y0: Float = 0.006, y1: Float = 0.2165
        let o = Shape2D.roundedRect(W, Dp, radius: 0.008)
        m.add(Prim.loft([Prim.ring(o, y: y0), Prim.ring(o, y: y1)], capStart: false, capEnd: true, material: bodyMaterial))
        let base = Shape2D.roundedRect(W + 0.002, Dp + 0.002, radius: 0.009).map { V3($0.x, 0.0033, $0.y) }
        m.add(Prim.sweep(Shape2D.circle(0.0028, segments: 8), along: base, up: .up, closedPath: true, caps: false, material: trimMaterial))
        let top = Shape2D.roundedRect(W + 0.0012, Dp + 0.0012, radius: 0.0085).map { V3($0.x, y1 - 0.0012, $0.y) }
        m.add(Prim.sweep(Shape2D.circle(0.0021, segments: 8), along: top, up: .up, closedPath: true, caps: false, material: trimMaterial))

        func faceRot(_ f: Int) -> simd_quatf { simd_quatf(degrees: [0, 180, 90, -90][f], axis: .up) }
        let half: [Float] = [Dp / 2, Dp / 2, W / 2, W / 2]
        func place(_ s: Surface, face f: Int, u: Float, v: Float, out: Float, extra: simd_quatf = .identity) {
            let r = faceRot(f)
            m.add(s, Xform(translation: r.act(V3(u, v, half[f] + out)), rotation: r * extra))
        }
        let coarseOutline = Shape2D.rounded(DD1BKit.v2([(-0.0065, -0.0042), (0.0065, -0.0042), (0.0052, 0.0042), (-0.0052, 0.0042)]), radius: 0.0016, segments: 2)
        let coarse = Prim.extrude(coarseOutline, depth: 0.0030, bevel: 0.0010, bevelSegments: 1, material: trimMaterial)
        for row in 0..<8 {
            for c in 0..<4 {
                let u = -0.0335 + 0.019 * Float(c) + Float(row % 2) * 0.0095
                place(coarse, face: 0, u: u, v: 0.045 + 0.019 * Float(row), out: 0.0007)
            }
        }
        let fine = Prim.extrude(DD1BKit.v2([(-0.0028, -0.0016), (0.0028, -0.0016), (0.0022, 0.0016), (-0.0022, 0.0016)]), depth: 0.0016, bevel: 0.0004, bevelSegments: 1, material: trimMaterial)
        for row in 0..<12 {
            for c in 0..<7 {
                let u = -0.0285 + 0.0095 * Float(c) + Float(row % 2) * 0.0047
                place(fine, face: 1, u: u, v: 0.04 + 0.0145 * Float(row), out: 0.0005)
            }
        }
        place(Prim.roundedBox(V3(0.050, 0.030, 0.0022), radius: 0.0008, bevelSegments: 2, material: trimMaterial), face: 2, u: 0, v: 0.115, out: 0.0004)
        place(Prim.roundedBox(V3(0.038, 0.0075, 0.0016), radius: 0.0005, bevelSegments: 1, material: "plastic.black"), face: 2, u: 0, v: 0.1155, out: 0.0017)
        place(Prim.roundedBox(V3(0.040, 0.0026, 0.0045), radius: 0.0009, bevelSegments: 2, material: trimMaterial), face: 2, u: 0, v: 0.1075, out: 0.0028,
              extra: simd_quatf(degrees: 14, axis: V3(1, 0, 0)))
        let dimple = Prim.cylinder(radius: 0.0032, height: 0.0016, bevel: 0.0007, segments: 8, bevelSegments: 2, material: trimMaterial)
        let toZ = simd_quatf(degrees: 90, axis: V3(1, 0, 0))
        for row in 0..<9 {
            for c in 0..<5 {
                place(dimple, face: 3, u: -0.016 + 0.008 * Float(c) + Float(row % 2) * 0.004, v: 0.04 + 0.0185 * Float(row), out: -0.0002, extra: toZ)
            }
        }
        let arch = catmull(DD1BKit.xz([(0, -0.026), (0, -0.023), (0, -0.013), (0, 0), (0, 0.013), (0, 0.023), (0, 0.026)], y: 0).enumerated().map { i, p in
            V3(0, [0.2135, 0.2225, 0.2335, 0.2385, 0.2335, 0.2225, 0.2135][i], p.z) }, per: 6)
        m.add(Prim.sweep(Shape2D.roundedRect(0.013, 0.0038, radius: 0.0012), along: arch, up: V3(1, 0, 0), caps: true, material: trimMaterial))
        for z: Float in [-0.0245, 0.0245] {
            rivet(&m, at: V3(0, y1 + 0.0004, z), normal: .up, radius: 0.0026, material: trimMaterial)
        }
        return DD1BKit.finish(m, rng: &rng, groundHeight: 0.06, turn: false)
    }
}
