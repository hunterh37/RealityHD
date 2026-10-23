import simd
import Foundation

/// River flood wrack line, 1 m long and ~25 cm wide: twigs, snapped reed bits, bark strips and dry leaves
/// dragged into a ragged windrow along the high-water mark. 2 LODs.
public struct FloodWrack: RealAsset {
    public static let id = "flood-wrack"
    public static let summary = "Flood debris line, 1 m: twigs, reed bits, bark strips and dry leaves left in a ragged windrow; 2 LODs."
    public static let tags = ["nature", "ground", "wood", "river"]
    public static let budget = 4_800
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 45, distance: 0.9, ground: false)

    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [gen(seed, 0), gen(seed, 1)], switchDistances: [5])
    }

    private func gen(_ seed: UInt64, _ lod: Int) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let wood: MaterialKey = "wood.deadwood", reed: MaterialKey = "grass.reed:B8A462"
        var twigs = Surface(material: wood), reeds = Surface(material: reed)
        func spot() -> V2 {
            let x = rng.float(-0.5...0.5)
            let w = 0.12 * (0.6 + 0.4 * cos(x * 5)) * (rng.float() + rng.float() - 1)
            return V2(x, w + 0.04 * sin(x * 7))
        }
        // Twigs, mostly aligned along the line.
        for _ in 0..<14 {
            let p = spot(), len = rng.float(0.1...0.38), r = rng.float(0.0015...0.005)
            let yaw = rng.chance(0.7) ? rng.float(-0.5...0.5) : rng.float(0...(2 * .pi))
            let d = V3(cos(yaw), rng.float(0...0.08), sin(yaw))
            let a = V3(p.x, 0.005, p.y) - d * len / 2
            let st = rng.state
            DetailKit01.limb(&twigs, rng: &rng, from: a, dir: d, len: len, r: r, fork: lod == 0 ? rng.int(0...2) : 0, sides: lod == 0 ? 5 : 3, material: wood)
            if lod == 1 { rng.state = st; var t = Surface(material: wood); DetailKit01.limb(&t, rng: &rng, from: a, dir: d, len: len, r: r, fork: rng.int(0...2), sides: 3, material: wood); _ = t }
        }
        // Reed bits: straw-colored hollow stalks, snapped short.
        for _ in 0..<12 {
            let p = spot(), len = rng.float(0.06...0.22), r = rng.float(0.0022...0.004)
            let yaw = rng.float(-0.6...0.6) + (rng.chance(0.3) ? 1.5 : 0)
            let d = V3(cos(yaw), rng.float(0...0.05), sin(yaw))
            let a = V3(p.x, 0.004 + r, p.y) - d * len / 2
            let pts = [a, a + d * len * 0.5 + V3(0, rng.float(0...0.006), 0), a + d * len]
            reeds.append(Prim.tube(pts, radii: [r, r * 0.9, r * 0.8], sides: lod == 0 ? 5 : 3, seamTile: 0.02, material: reed, capEnd: true))
        }
        twigs.computeTangents(); reeds.computeTangents()
        m.add(twigs); m.add(reeds)
        // Bark strips: thin curved plates.
        for _ in 0..<7 {
            let p = spot()
            let size = V3(rng.float(0.04...0.1), rng.float(0.003...0.006), rng.float(0.02...0.04))
            var b = Prim.roundedBox(size, radius: 0.0012, bevelSegments: 1, material: rng.chance(0.5) ? "bark.dead" : "bark.oak-dry")
            b.computeTangents()
            let rot = DetailKit01.yawQuat(rng.float(0...(2 * .pi))) * simd_quatf(angle: rng.float(-0.25...0.25), axis: V3(1, 0, 0))
            m.add(b.transformed(Xform(translation: V3(p.x, 0.005 + size.y / 2, p.y), rotation: rot)))
        }
        // Dry leaf cards, clumped along the line.
        var leaves = Surface(material: "litter.dry")
        for i in 0..<(lod == 0 ? 40 : 22) {
            let p = spot()
            let c = PlantKit.cell(rng.int(0...15), cols: 4, rows: 4)
            var b = PlantKit.Blade()
            b.length = rng.float(0.04...0.1); b.width = b.length
            b.yaw = rng.float(0...6.28)
            let d = V3(cos(b.yaw), 0, sin(b.yaw))
            b.root = V3(p.x, 0.003 + Float(i) * 0.0004, p.y) - d * b.length / 2
            b.constantWidth = true; b.tipWidth = 1
            b.lean = rng.float(1.42...1.56); b.curl = rng.float(-0.05...0.08); b.segments = 1
            b.u = V2(c.origin.x, c.origin.x + c.size.x); b.v = V2(c.origin.y, c.origin.y + c.size.y)
            b.weight = V2(0, 0); b.ao = V2(0.75, 0.9); b.upNormal = 0.2
            var lf = PlantKit.blade(b, material: "litter.dry"); lf.computeTangents(); m.add(lf)
        }
        groundAO(&m)
        return m
    }
}
