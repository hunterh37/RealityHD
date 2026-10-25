import simd
import Foundation

/// Squirrel-chewed spruce cone, 11 cm: bare woody core with scale stubs, a few intact scales left at the tip, and loose stripped scales around it. 2 LODs.
public struct ChewedSpruceCone: RealAsset {
    public static let id = "chewed-spruce-cone"
    public static let summary = "Squirrel-chewed spruce cone, 11 cm: stripped core, intact tip scales and loose scales scattered around it; 2 LODs."
    public static let tags = ["nature", "ground", "plant", "wood"]
    public static let budget = 3_850
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 50, distance: 0.45, ground: false)

    public init() {}

    public func build(seed: UInt64) -> LODModel {
        DetailKit20.lods(SeededRNG(seed: seed), dist: 3) { lvl, rng in make(lvl, &rng) }
    }

    private func make(_ lvl: Int, _ rng: inout SeededRNG) -> Model {
        let hi = lvl == 0, sub = hi ? 2 : 1
        let up = V3(0, 1, 0), golden: Float = 2.399963
        var core = Surface(material: "wood.pine:C8A878"), scale = Surface(material: "wood.oak:7A5530"), pale = Surface(material: "wood.pine:B89460")
        var cone = Surface(material: "wood.pine:C8A878"), tipScales = Surface(material: "wood.oak:7A5530")
        let L: Float = rng.float(0.10...0.12)
        let axis = (0...6).map { i -> V3 in V3(rng.float(-0.0012...0.0012), L * Float(i) / 6, rng.float(-0.0012...0.0012)) }
        let rad = (0...6).map { i -> Float in (0.0055 - 0.0028 * Float(i) / 6) * rng.float(0.9...1.1) }
        cone.append(Prim.tube(axis, radii: rad, sides: hi ? 7 : 5, seamTile: 0.03, material: "wood.pine:C8A878", capEnd: true))
        // Stubs of eaten scales up the core.
        let nStub = hi ? 52 : 28
        for i in 0..<nStub {
            let t = Float(i) / Float(nStub) * 0.74
            let ang = Float(i) * golden * (hi ? 1 : 2) + rng.float(-0.2...0.2)
            let out = V3(cos(ang), rng.float(0.1...0.4), sin(ang))
            let y = t * L
            let r = 0.0055 - 0.0028 * (y / L)
            core.append(DetailKit20.scaleBlob(base: V3(0, y, 0) + simd_normalize(V3(out.x, 0, out.z)) * r * 0.6, out: out, up: up, len: rng.float(0.0015...0.003), wid: 0.004, th: 0.0025, sub: 1, material: "wood.pine:C8A878"))
        }
        // Intact scales at the tip, flaring out and up.
        let nTip = hi ? 24 : 14
        for i in 0..<nTip {
            let t = 0.74 + Float(i) / Float(nTip) * 0.26
            let ang = Float(i) * golden * (hi ? 1 : 1.7) + rng.float(-0.15...0.15)
            let y = t * L
            let out = V3(cos(ang), rng.float(0.15...0.55) * (1 + t - 0.74), sin(ang))
            let r = 0.0055 - 0.0028 * t
            let len = 0.017 * (1 - 0.5 * (t - 0.74) / 0.26) * rng.float(0.85...1.1)
            tipScales.append(DetailKit20.scaleBlob(base: V3(0, y, 0) + simd_normalize(V3(out.x, 0, out.z)) * r * 0.5, out: out, up: up, len: len, wid: 0.012 * rng.float(0.85...1.1), th: 0.0013, sub: sub, material: "wood.oak:7A5530"))
        }
        core.append(cone)
        let q = simd_quatf(angle: rng.float(-0.3...0.3), axis: up) * simd_quatf(angle: .pi / 2 + rng.float(-0.08...0.08), axis: V3(0, 0, 1))
        let all = DetailKit20.place(core, q: q, at: .zero, sink: 0.0015)
        let lo = core.transformed(Xform(translation: .zero, rotation: q)).bounds.min.y
        let shift = Xform(translation: V3(0, -lo - 0.0015, 0))
        var m = Model(name: Self.id)
        var tipFinal = tipScales.transformed(Xform(translation: .zero, rotation: q))
        tipFinal = tipFinal.transformed(shift)
        // Center the group on x.
        let cx = (all.bounds.min.x + all.bounds.max.x) / 2
        let center = Xform(translation: V3(-cx, 0, 0))
        // Loose stripped scales on the ground beside the cone.
        let nLoose = hi ? 28 : 14
        for i in 0..<nLoose {
            let side: Float = i % 2 == 0 ? 1 : -1
            let c = V3(rng.float(-0.075...0.075), 0.0008, side * rng.float(0.018...0.07))
            let a = rng.float(0...6.28)
            let out = V3(cos(a), rng.float(0.0...0.12), sin(a))
            let piece = DetailKit20.scaleBlob(base: c, out: out, up: up, len: rng.float(0.013...0.02), wid: rng.float(0.008...0.012), th: 0.0012, sub: sub, material: "wood.oak:7A5530")
            if i % 5 == 4 { pale.append(piece) } else { scale.append(piece) }
        }
        scale.append(tipFinal.transformed(center))
        var core2 = all.transformed(center)
        core2.computeTangents(); scale.computeTangents(); pale.computeTangents()
        m.add(core2); m.add(scale); m.add(pale)
        groundAO(&m, height: 0.03, floor: 0.55)
        return m
    }
}
