import simd
import Foundation

/// Oval slow cooker: stainless housing with black end handles and a front dial, removable stoneware
/// insert with a glazed rim (one chip), tempered glass lid in a steel rim with a knob, rubber feet.
public struct SlowCooker: RealAsset {
    public static let id = "slow-cooker"
    public static let summary = "Oval slow cooker: steel housing, stoneware insert, glass lid with knob, end handles and dial."
    public static let tags = ["prop", "interior", "kitchen", "ceramic", "plastic", "glass"]
    public static let budget = 10000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth) including the end handles.
    public var size = V3(0.38, 0.26, 0.30)
    /// Insert material.
    public var insert: MaterialKey = "ceramic.stoneware"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        typealias K = DD1DKitchen
        let bw = size.x - 0.085, bd = size.z
        let foot: Float = 0.012
        _ = rng.float()
        K.feet(&m, w: bw - 0.06, d: bd - 0.04, inset: 0.03, h: foot, r: 0.012)
        func oval(_ w: Float, _ d: Float) -> [V2] { Shape2D.superellipse(w, d, exponent: 2.6, segments: 56) }

        // Housing: stainless wall, slight belly, black base plinth.
        m.add(Prim.loft([
            Prim.ring(oval(bw - 0.03, bd - 0.03), y: foot),
            Prim.ring(oval(bw - 0.02, bd - 0.02), y: foot + 0.01),
            Prim.ring(oval(bw, bd), y: foot + 0.05),
            Prim.ring(oval(bw, bd), y: 0.145),
            Prim.ring(oval(bw - 0.006, bd - 0.006), y: 0.152),
        ], capStart: true, capEnd: false, material: "metal.satin-aluminum"))
        // Top shoulder ring covering the insert gap.
        m.add(Prim.loft([
            Prim.ring(oval(bw - 0.006, bd - 0.006), y: 0.152),
            Prim.ring(oval(bw - 0.03, bd - 0.03), y: 0.158),
            Prim.ring(oval(bw - 0.056, bd - 0.056), y: 0.156),
        ], capStart: false, capEnd: false, material: "metal.stainless-smudged"))
        // Stoneware insert: rim lip above the housing, inner well.
        m.add(Prim.loft([
            Prim.ring(oval(bw - 0.052, bd - 0.052), y: 0.156),
            Prim.ring(oval(bw - 0.044, bd - 0.044), y: 0.172),
            Prim.ring(oval(bw - 0.048, bd - 0.048), y: 0.178),
            Prim.ring(oval(bw - 0.06, bd - 0.06), y: 0.178),
            Prim.ring(oval(bw - 0.064, bd - 0.064), y: 0.166),
        ], capStart: false, capEnd: false, material: insert))
        m.add(Prim.loft([
            Prim.ring(oval(bw - 0.07, bd - 0.07), y: 0.168),
            Prim.ring(oval(bw - 0.09, bd - 0.09), y: 0.1),
        ], capStart: false, capEnd: true, material: "ceramic.stoneware"))
        // Chip in the glaze on the front rim.
        K.box(&m, V3(0.014, 0.004, 0.004), V3(0.07, 0.1785, (bd - 0.052) / 2 - 0.003), "ceramic.bisque", r: 0.001)
        // Glass lid: flat steel rim band, dome, steam vent, black knob on two posts.
        let lo: Float = 0.178
        m.add(Prim.loft([
            Prim.ring(oval(bw - 0.03, bd - 0.03), y: lo),
            Prim.ring(oval(bw - 0.026, bd - 0.026), y: lo + 0.005),
            Prim.ring(oval(bw - 0.034, bd - 0.034), y: lo + 0.008),
        ], capStart: false, capEnd: false, material: "metal.stainless"))
        var domeRings: [[V3]] = []
        for k in 0...8 {
            let t = Float(k) / 8
            let a = t * .pi / 2
            let inset = 0.036 + 0.17 * (1 - cos(a))      // plan inset grows toward the crown
            domeRings.append(Prim.ring(oval(bw - inset, bd - inset), y: lo + 0.004 + 0.046 * sin(a)))
        }
        m.add(Prim.loft(domeRings, capStart: false, capEnd: true, material: "glass.clear"))
        K.cyl(&m, r: 0.016, h: 0.012, at: V3(0, lo + 0.046, 0), "metal.stainless", bevel: 0.002, seg: 20)
        K.cyl(&m, r: 0.025, h: 0.022, at: V3(0, lo + 0.054, 0), "plastic.black", bevel: 0.006, seg: 24)
        K.box(&m, V3(0.004, 0.004, 0.012), V3(0, lo + 0.077, 0), "plastic.matte:3A3A3D", r: 0.001)
        // End handles: black loops riveted to the housing.
        for sx: Float in [-1, 1] {
            let x0 = sx * (bw / 2 - 0.002)
            let p = catmull([V3(x0, 0.125, -0.045), V3(x0 + sx * 0.02, 0.128, -0.04), V3(x0 + sx * 0.031, 0.115, 0), V3(x0 + sx * 0.02, 0.1, 0.04), V3(x0, 0.098, 0.045)], per: 8)
            m.add(Prim.tube(p, radii: p.map { _ in 0.0085 }, sides: 12, seamTile: 0.05, material: "plastic.cordless-worn", capEnd: true), Xform())
            for zz: Float in [-0.045, 0.045] {
                K.cylX(&m, r: 0.007, len: 0.003, at: V3(x0 - sx * 0.002, zz > 0 ? 0.098 : 0.125, zz), "metal.stainless", bevel: 0.001, seg: 10)
            }
        }
        // Front: dial with off/low/high marks and a lamp.
        let zF = (bd - 0.006) / 2
        K.dial(&m, at: V3(0, 0.07, zF - 0.002), r: 0.021, mat: "plastic.black")
        for (i, a) in [Float(-50), 0, 50].enumerated() {
            let ar = a * .pi / 180
            K.box(&m, V3(0.003, 0.006, 0.0015), V3(sin(ar) * 0.036, 0.07 + cos(ar) * 0.036, zF - 0.0005), i == 2 ? "emissive.signal-red" : "plastic.white", r: 0.0004)
        }
        K.box(&m, V3(0.008, 0.008, 0.002), V3(0.04, 0.1, zF - 0.0005), "emissive.signal-orange", r: 0.0008)
        K.seam(&m, V3(0.1, 0.0014, 0.001), V3(0, 0.152, zF - 0.002))
        K.cord(&m, from: V3(-0.08, 0.04, -bd / 2 + 0.012), to: V3(-0.13, 0, -bd / 2 + 0.002))
        // Story: stew drips down the housing from the insert rim.
        K.drip(&m, at: V3(-0.07, 0.15, zF + 0.0005), w: 0.009, len: 0.06, "food.stock")
        K.drip(&m, at: V3(0.09, 0.15, zF - 0.0035), w: 0.006, len: 0.035, "food.stock")
        K.blob(&m, V3(0.035, lo + 0.0085, (bd - 0.052) / 2 - 0.004), V3(0.03, 0.003, 0.008), "food.tomato-sauce")
        groundAO(&m)
        return LODModel(m)
    }
}
