import simd
import Foundation

/// Flat moss carpet about 60 cm across with a lobed outline, 1-2 cm lumpy pile, scattered brown-red
/// sporophyte stalks with capsules in clusters and a few exposed soil patches. LOD1: coarser mesh, fewer stalks.
public struct MossCarpet: RealAsset {
    public static let id = "moss-carpet"
    public static let summary = "Flat 60 cm moss carpet with lumpy pile, clustered sporophyte stalks with capsules and exposed soil patches; 2 LODs."
    public static let tags = ["nature", "ground", "plant"]
    public static let budget = 5_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 40, distance: 0.8, ground: false)

    public init() {}

    public func build(seed: UInt64) -> LODModel {
        DetailKit04.lods { lod in
            var rng = SeededRNG(seed: seed)
            let ns = UInt32(truncatingIfNeeded: seed)
            var m = Model(name: Self.id)
            func mossH(_ x: Float, _ z: Float, _ t: Float) -> Float {
                let lump = 0.5 + 0.5 * DetailKit04.noise(x, z, 14, ns) + 0.25 * DetailKit04.noise(x, z, 40, ns &+ 3)
                let taper = pow(min(1, max(0, (1 - t) / 0.14)), 0.7)
                return -0.002 + (0.008 + 0.012 * lump) * taper
            }
            let rings = lod == 0 ? 16 : 8, sectors = lod == 0 ? 32 : 16
            m.add(DetailKit04.patch(at: .zero, radius: 0.30, rings: rings, sectors: sectors, rng: &rng, lobes: 0.2,
                                    material: "moss.cushion", height: mossH))
            for i in 0..<(lod == 0 ? 5 : 3) {
                var cr = rng.fork(i)
                let c = cr.inDisc(radius: 0.17)
                m.add(DetailKit04.patch(at: c, radius: cr.float(0.014...0.03), rings: lod == 0 ? 3 : 2, sectors: lod == 0 ? 10 : 6, rng: &cr, lobes: 0.5,
                                        material: i % 2 == 0 ? "ground.dirt" : "ground.dirt:3e2e22") { x, z, t in mossH(x, z, 0.4) + 0.0015 })
            }
            // Sporophytes in 5 clusters.
            var stalks = Surface(material: "plant.stem:4a2214"), caps = Surface(material: "plant.stem:6a3418")
            let clusters = lod == 0 ? 5 : 3, per = lod == 0 ? 11 : 6
            for c in 0..<clusters {
                var cr = rng.fork(100 + c)
                let center = cr.inDisc(radius: 0.18)
                for _ in 0..<per {
                    let p = center + cr.inDisc(radius: 0.05)
                    let h = cr.float(0.018...0.032), y0 = mossH(p.x, p.y, 0.3) - 0.002
                    let a = cr.float(0...6.28), lean = cr.float(0.1...0.5) * h
                    let d = V3(cos(a), 0, sin(a))
                    let path = (0...3).map { i -> V3 in let t = Float(i) / 3; return V3(p.x, y0, p.y) + d * lean * t * t + V3(0, h * t, 0) }
                    stalks.append(Prim.tube(path, radii: [0.0004, 0.00035, 0.0003, 0.0003], sides: 3, seamTile: 0.01, material: "plant.stem", capEnd: false))
                    if lod == 0 || cr.chance(0.6) {
                        let tip = path[3], tang = (path[3] - path[2]).normalized
                        let q = simd_quatf(from: .up, to: (tang + d * 0.5 + V3(0, -0.3, 0).normalized * 0.2).normalized)
                        let cap = Prim.lathe([V2(0.0004, 0), V2(0.0019, 0.0016), V2(0.0021, 0.0035), V2(0.0012, 0.0062), V2(0, 0.0072)],
                                             segments: 5, seamTile: 0.01, material: "plant.stem")
                        caps.append(cap, Xform(translation: tip - tang * 0.0005, rotation: q))
                    }
                }
            }
            m.add(stalks); m.add(caps)
            return m
        }
    }
}
