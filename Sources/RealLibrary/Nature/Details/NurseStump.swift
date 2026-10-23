import simd
import Foundation

/// Rotten conifer stump 50 cm tall and 30 cm across with a flared base, moss caps, bracket fungi and a
/// hemlock seedling growing from the crown. LOD1: fewer sides.
public struct NurseStump: RealAsset {
    public static let id = "nurse-stump"
    public static let summary = "Rotten stump 50 cm with moss, shelf bracket fungi and a tree seedling rooted in its crown; 2 LODs."
    public static let tags = ["nature", "wood", "fungus", "plant"]
    public static let budget = 3_600
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 20, distance: 1.4)

    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m0 = Model(name: Self.id), m1 = Model(name: Self.id)
        let phases = (0..<4).map { _ in rng.float(0...6.28) }
        let amps = (0..<4).map { _ in rng.float(0.03...0.09) }
        let H: Float = 0.5
        let ripple: (Float, Float) -> Float = { t, v in
            var f: Float = 1
            for k in 0..<4 { f += amps[k] * sin(t * 2 * .pi * Float(k + 2) + phases[k] + v * 6) }
            return f
        }
        for (lod, sides, rings) in [(0, 18, 10), (1, 10, 6)] {
            var pts: [V3] = [], rad: [Float] = []
            for j in 0..<rings {
                let t = Float(j) / Float(rings - 1)
                pts.append(V3(0.02 * t * t, -0.005 + (H + 0.005) * t, 0.01 * t))
                let flare = 1 + 0.55 * pow(1 - t, 5)
                rad.append(0.145 * flare * (1 - 0.1 * t))
            }
            let wood = Prim.tube(pts, radii: rad, sides: sides, seamTile: 0.06, material: "bark.dead", capEnd: false, rippling: ripple)
            // Top: dished rotten crown (endgrain disc).
            let top = pts.last!
            let crown0 = Prim.lathe([V2(0.0, H - 0.035), V2(0.06, H - 0.02), V2(0.125, H - 0.002)], segments: sides, seamTile: 0.08, material: "wood.waterlogged")
            let crown = crown0.transformed(Xform(translation: V3(top.x, 0, top.z)))
            if lod == 0 { m0.add(wood); m0.add(crown) } else { m1.add(wood); m1.add(crown) }
        }
        // Moss: caps on the crown and drapes on the north side.
        for i in 0..<9 {
            let a = rng.float(0...6.28)
            let onTop = i < 4
            let r = onTop ? rng.float(0.0...0.1) : 0.15
            let y = onTop ? H - 0.005 : rng.float(0.02...0.42)
            let c = V3(cos(a) * r + 0.02, y, sin(a) * r + 0.01)
            let s = rng.float(0.035...0.07)
            let rot = onTop ? simd_quatf(angle: 0, axis: .up) : simd_quatf(from: V3(0, 1, 0), to: V3(cos(a), 0.2, sin(a)).normalized)
            let b = DetailKit10.blob(c, V3(s, s * 0.45, s), rot: rot, sub: 2, material: "moss.cushion")
            m0.add(b)
            m1.add(DetailKit10.blob(c, V3(s, s * 0.45, s), rot: rot, sub: 1, material: "moss.cushion"))
        }
        // Bracket fungi: stacked half-discs on the flank.
        let ba = rng.float(0...6.28)
        for i in 0..<5 {
            let a = ba + rng.float(-0.5...0.5), y = 0.12 + Float(i) * 0.06 + rng.float(-0.02...0.02)
            let r: Float = 0.12 * (1 - 0.08 * Float(i)) + 0.025
            let s = rng.float(0.055...0.09)
            let out = V3(cos(a), 0, sin(a))
            let rot = simd_quatf(from: V3(0, 1, 0), to: V3(0, 1, 0)) * simd_quatf(angle: -a, axis: .up)
            let c = out * r + V3(0.01, y, 0.005)
            m0.add(DetailKit10.blob(c, V3(s, s * 0.2, s * 0.75), rot: rot, sub: 2, material: "fungus.cap"))
            m0.add(DetailKit10.blob(c - V3(0, s * 0.18, 0), V3(s * 0.95, s * 0.06, s * 0.7), rot: rot, sub: 1, material: "fungus.gills"))
            m1.add(DetailKit10.blob(c, V3(s, s * 0.2, s * 0.75), rot: rot, sub: 1, material: "fungus.cap"))
        }
        // Seedling: thin leader with whorled needle sprays.
        let sx: Float = 0.03, sz: Float = -0.02, sh: Float = rng.float(0.17...0.22)
        var sp: [V3] = []
        for j in 0..<6 { let t = Float(j) / 5; sp.append(V3(sx + 0.012 * t * t, H - 0.02 + sh * t, sz + 0.008 * t)) }
        let leader = PlantKit.stem(sp, radius: 0.0022, tipRadius: 0.0008, sides: 4, weight: V2(0, 0.5), phase: 1, material: "bark.dead")
        m0.add(leader); m1.add(leader)
        for j in 1..<6 {
            let base = sp[j]
            for k in 0..<4 {
                var b = PlantKit.Blade()
                b.root = base; b.yaw = Float(k) * 1.57 + Float(j) * 0.9 + rng.float(-0.3...0.3)
                b.length = (0.07 - 0.009 * Float(j)) * rng.float(0.8...1.2); b.width = 0.02
                b.lean = rng.float(1.0...1.4); b.curl = 0.3; b.segments = 2; b.tipWidth = 0.1; b.weight = V2(0.3, 0.9); b.fold = 0.2
                let s = PlantKit.blade(b, material: "leaf.fir")
                m0.add(s); m1.add(s)
            }
        }
        // Forest floor skirt.
        var lr = rng.fork(5)
        DetailKit10.litter(&m0, radius: 0.28, count: 12, rng: &lr)
        var lr1 = rng.fork(5)
        DetailKit10.litter(&m1, radius: 0.28, count: 12, rng: &lr1)
        groundAO(&m0, height: 0.2, floor: 0.55); groundAO(&m1, height: 0.2, floor: 0.55)
        PlantKit.finish(&m0); PlantKit.finish(&m1)
        return LODModel(levels: [m0, m1], switchDistances: [5])
    }
}
