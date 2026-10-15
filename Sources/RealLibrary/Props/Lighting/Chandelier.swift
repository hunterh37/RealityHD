import simd
import Foundation

/// Six-arm traditional chandelier, authored in place: the canopy top touches the ceiling plane at y = 2.6, the
/// lowest finial hangs at y = 1.7. Aged brass chain, turned column, six scrolled S-arms joined by a hoop, glass
/// bobeches, white candle sleeves with flame bulbs and a glass drop under each arm.
public struct Chandelier: RealAsset {
    public static let id = "chandelier"
    public static let summary = "Six-arm brass chandelier: chain, turned column, scrolled arms, glass bobeches, candle sleeves and flame bulbs."
    public static let tags = ["prop", "floorplan", "interior", "ceiling", "light", "metal", "glass"]
    public static let budget = 6500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: -20, distance: 1.9, ground: false, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.8, 0.9, 0.8)
    /// Ceiling plane height (m).
    public var ceilingY: Float = 2.6
    /// Number of arms.
    public var arms = 6
    /// Frame finish.
    public var brass: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let top = ceilingY
        let bottom = ceilingY - size.y
        let reach = (size.x / 2 - 0.046) / 0.966       // bobeche centre radius; arms phased 15 degrees so X and Z spans match
        func make(_ lod: Int) -> Model {
            var m = Model(name: Self.id)
            let seg = lod == 0 ? 22 : 12
            // Canopy with rolled edge.
            m.add(Prim.lathe([V2(0, top), V2(0.075, top), V2(0.083, top - 0.004), V2(0.083, top - 0.014), V2(0.07, top - 0.024), V2(0.035, top - 0.03), V2(0, top - 0.03)],
                             segments: seg, seamTile: 0.1, material: brass))
            // Chain of oval links, alternating planes.
            let chainTop = top - 0.03, chainBot = top - 0.3
            let links = lod == 0 ? 10 : 5
            let pitch = (chainTop - chainBot) / Float(links)
            for i in 0..<links {
                let y = chainTop - pitch * (Float(i) + 0.5)
                let q = simd_quatf(degrees: i % 2 == 0 ? 0 : 90, axis: .up) * simd_quatf(degrees: 90, axis: V3(1, 0, 0))
                m.add(Prim.torus(major: 0.011, minor: 0.0032, segments: lod == 0 ? 8 : 6, sides: 4, material: brass),
                      Xform(translation: V3(0, y, 0), rotation: q, scale: V3(1, 1, 1.75)))
            }
            // Turned column: top cap, vase body, collar band, lower ball and finial down to the lowest point.
            let col: [(Float, Float)] = [(0.0, chainBot), (0.026, chainBot), (0.034, chainBot - 0.012), (0.017, chainBot - 0.03), (0.016, chainBot - 0.06),
                                         (0.032, chainBot - 0.085), (0.052, chainBot - 0.125), (0.058, chainBot - 0.17), (0.05, chainBot - 0.22), (0.03, chainBot - 0.26),
                                         (0.02, chainBot - 0.275), (0.036, chainBot - 0.295), (0.036, chainBot - 0.31), (0.02, chainBot - 0.33), (0.034, chainBot - 0.36),
                                         (0.034, chainBot - 0.395), (0.016, chainBot - 0.425), (0.008, chainBot - 0.46), (0.0, bottom)]
            m.add(Prim.lathe(col.map { V2($0.0, $0.1) }, segments: seg, seamTile: 0.1, material: brass))
            // Hoop brace ring.
            let ringY = chainBot - 0.2
            m.add(Prim.torus(major: reach * 0.52, minor: 0.0045, segments: lod == 0 ? 28 : 14, sides: 5, material: brass), Xform(translation: V3(0, ringY, 0)))
            for k in 0..<arms {
                let a = Float(k) * 2 * .pi / Float(arms) + 0.2618
                let dir = V3(cos(a), 0, -sin(a))
                func P(_ r: Float, _ y: Float) -> V3 { dir * r + V3(0, y, 0) }
                // S-curve arm: leaves the column low, swings down and out, rises to the cup.
                let pts = [P(0.05, ringY - 0.02), P(reach * 0.36, ringY - 0.075), P(reach * 0.68, ringY - 0.06), P(reach * 0.9, ringY + 0.005), P(reach, ringY + 0.075), P(reach, ringY + 0.125)]
                let path = catmull(pts, per: lod == 0 ? 3 : 1)
                let n = path.count
                let radii = (0..<n).map { 0.0085 - 0.0025 * Float($0) / Float(n - 1) }
                m.add(Prim.tube(path, radii: radii, sides: lod == 0 ? 6 : 4, seamTile: 0.03, material: brass))
                let cy = ringY + 0.125
                // Cup under the bobeche and the glass dish.
                m.add(Prim.lathe([V2(0, cy - 0.012), V2(0.016, cy - 0.012), V2(0.02, cy - 0.004), V2(0.018, cy + 0.006), V2(0.0, cy + 0.006)], segments: lod == 0 ? 12 : 8, seamTile: 0.03, material: brass), Xform(translation: V3(dir.x * reach, 0, dir.z * reach)))
                m.add(Prim.lathe([V2(0.0, cy + 0.003), V2(0.02, cy + 0.003), V2(0.045, cy + 0.016), V2(0.046, cy + 0.02), V2(0.04, cy + 0.0175), V2(0.02, cy + 0.01), V2(0.0, cy + 0.01)], segments: lod == 0 ? 18 : 10, seamTile: 0.1, material: "glass.clear"), Xform(translation: V3(dir.x * reach, 0, dir.z * reach)))
                // Candle sleeve with a rolled brass top, flame bulb above.
                m.add(Prim.lathe([V2(0, cy + 0.008), V2(0.0125, cy + 0.008), V2(0.0125, cy + 0.098), V2(0.0145, cy + 0.1), V2(0.0145, cy + 0.108), V2(0, cy + 0.108)], segments: lod == 0 ? 12 : 8, seamTile: 0.04, material: "plastic.white"), Xform(translation: V3(dir.x * reach, 0, dir.z * reach)))
                m.add(Prim.lathe(Profile.smooth([V2(0.0095, cy + 0.108), V2(0.0115, cy + 0.12), V2(0.0095, cy + 0.14), V2(0.004, cy + 0.158), V2(0, cy + 0.165)], per: 1), segments: 8, seamTile: 0.03, material: "emissive.bulb"), Xform(translation: V3(dir.x * reach, 0, dir.z * reach)))
                if lod == 0 {
                    // Glass drop hanging from the bobeche rim.
                    let rp = dir * (reach + 0.043)
                    m.add(Prim.lathe(Profile.smooth([V2(0.0, cy + 0.0), V2(0.004, cy - 0.004), V2(0.0085, cy - 0.022), V2(0.006, cy - 0.04), V2(0.0, cy - 0.052)], per: 1), segments: 8, seamTile: 0.02, material: "glass.clear"),
                          Xform(translation: V3(rp.x, 0, rp.z)))
                }
            }
            return m
        }
        return LODModel(levels: [make(0), make(1)], switchDistances: [6])
    }
}
