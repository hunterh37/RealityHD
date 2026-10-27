import simd
import Foundation

/// Countertop blender: tapered glass jar with a moulded handle, collar and blade assembly on a black
/// motor base with a dial and three keys, vented lid with a pour cap, power cord.
public struct Blender: RealAsset {
    public static let id = "blender"
    public static let summary = "Countertop blender: glass jar with handle and lid on a plastic motor base with dial."
    public static let tags = ["prop", "interior", "kitchen", "glass", "plastic", "metal"]
    public static let budget = 10000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.17, 0.42, 0.19)
    /// Jar glass material.
    public var glass: MaterialKey = "glass.clear"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        typealias K = DD1DKitchen
        let W = size.x, D = size.z
        let foot: Float = 0.010
        let baseH: Float = 0.12
        let js: Float = 0.88
        let blk: MaterialKey = "plastic.black"
        let blkWorn: MaterialKey = "plastic.cordless-worn"
        let zJar: Float = 0.004
        _ = rng.float()

        K.feet(&m, w: W, d: D - 0.03, inset: 0.022, h: foot, r: 0.009)
        // Motor base: flared housing, stainless trim band under the jar seat.
        m.add(Prim.loft([
            Prim.ring(Shape2D.rounded(Shape2D.rect(W, 0.168), radius: 0.022), y: foot),
            Prim.ring(Shape2D.rounded(Shape2D.rect(W - 0.008, 0.162), radius: 0.024), y: foot + 0.05),
            Prim.ring(Shape2D.rounded(Shape2D.rect(W - 0.03, 0.14), radius: 0.03), y: baseH),
        ], capStart: true, capEnd: true, material: "plastic.black"))
        K.box(&m, V3(W - 0.044, 0.004, 0.118), V3(0, baseH + 0.001, 0), "metal.stainless", r: 0.0015)
        K.seam(&m, V3(W - 0.016, 0.0016, 0.001), V3(0, foot + 0.056, 0.082))
        // Front controls: dial and three keys.
        K.dial(&m, at: V3(0, 0.066, 0.0665 + 0.01), r: 0.019, mat: blkWorn)
        K.keys(&m, n: 3, at: V3(0, 0.103, 0.0605 + 0.012), pitch: 0.036, size: V3(0.026, 0.011, 0.004), mat: "plastic.matte:3A3A3D")
        K.display(&m, at: V3(0, 0.036, 0.0715 + 0.003), w: 0.04, h: 0.012)

        // Jar collar and glass.
        let cy = baseH + 0.003
        K.lathe(&m, [(0, 0), (0.05, 0), (0.054, 0.003), (0.054, 0.024), (0.05, 0.026), (0, 0.026)], at: V3(0, cy, zJar), "metal.stainless", seg: 36)
        let jy = cy + 0.022
        let outer: [(Float, Float)] = [(0.042, 0), (0.05, 0.002), (0.056, 0.03), (0.064, 0.12), (0.071, 0.2), (0.077, 0.255)]
        let inner: [(Float, Float)] = [(0.074, 0.255), (0.0685, 0.2), (0.0615, 0.12), (0.0535, 0.03), (0.0475, 0.007), (0, 0.007)]
        K.lathe(&m, (outer + [(0.0775, 0.2565)] + inner).map { ($0.0, $0.1 * js) }, at: V3(0, jy, zJar), glass, seg: 44)
        // Measuring ridges moulded on the glass.
        func jarR(_ y: Float) -> Float {
            let o = outer.map { ($0.0, $0.1 * js) }
            for k in 1..<o.count where y <= o[k].1 {
                let t = (y - o[k - 1].1) / (o[k].1 - o[k - 1].1)
                return o[k - 1].0 + (o[k].0 - o[k - 1].0) * t
            }
            return o[o.count - 1].0
        }
        for yy in [Float(0.06), 0.12, 0.18] {
            let y = yy * js
            m.add(Prim.torus(major: jarR(y) + 0.0004, minor: 0.0007, segments: 44, sides: 5, material: "glass.frosted"), Xform(translation: V3(0, jy + y, zJar)))
        }
        // Blade assembly: spindle, hub and four bent blades.
        K.cyl(&m, r: 0.009, h: 0.02, at: V3(0, jy + 0.005, zJar), "metal.stainless", bevel: 0.002, seg: 16)
        for k in 0..<4 {
            let ang = Float(k) * 90 + 20
            let tilt: Float = k % 2 == 0 ? 22 : -22
            let q = simd_quatf(degrees: ang, axis: V3(0, 1, 0)) * simd_quatf(degrees: tilt, axis: V3(0, 0, 1))
            m.add(Prim.roundedBox(V3(0.034, 0.0014, 0.014), radius: 0.0006, bevelSegments: 1, material: "metal.stainless"),
                  Xform(translation: V3(0, jy + (k % 2 == 0 ? 0.027 : 0.016), zJar) + q.act(V3(0.02, 0, 0)), rotation: q))
        }
        // Handle: tube sweeping from the jar wall, with a thumb rest.
        let hz = zJar - 0.071
        let hp = catmull([V3(0, jy + 0.215 * js, hz + 0.003), V3(0, jy + 0.222 * js, hz - 0.012), V3(0, jy + 0.19 * js, hz - 0.019), V3(0, jy + 0.12 * js, hz - 0.015), V3(0, jy + 0.07 * js, hz - 0.004)], per: 8)
        m.add(Prim.tube(hp, radii: hp.map { _ in 0.0085 }, sides: 12, seamTile: 0.05, material: blk, capEnd: true), Xform())
        // Lid with flange, ribbed top, vent step and pour cap.
        let ly = jy + 0.2525 * js
        K.lathe(&m, [(0, 0.0), (0.0785, 0.0), (0.0795, 0.003), (0.0795, 0.011), (0.0745, 0.0125), (0.07, 0.016), (0.03, 0.019), (0.0225, 0.02), (0.0225, 0.027), (0, 0.027)], at: V3(0, ly, zJar), "plastic.black", seg: 44)
        K.cyl(&m, r: 0.0235, h: 0.03, at: V3(0, ly + 0.015, zJar), "rubber.silicone-gray", bevel: 0.004, seg: 24)
        K.cyl(&m, r: 0.0175, h: 0.006, at: V3(0, ly + 0.043, zJar), "rubber.silicone-gray", bevel: 0.002, seg: 20)
        // Lip tab on the lid for the thumb.
        K.box(&m, V3(0.03, 0.006, 0.014), V3(0, ly + 0.008, zJar + 0.0815), "plastic.black", r: 0.002)
        K.cord(&m, from: V3(0.04, 0.05, -0.083), to: V3(0.075, 0, -0.092))
        // Story: smoothie residue pooled in the jar and flicked on the lid and collar.
        K.cyl(&m, r: 0.0495, h: 0.02, at: V3(0, jy + 0.0075, zJar), "food.tomato-sauce", bevel: 0.004, seg: 32)
        K.blob(&m, V3(0.035, ly + 0.0185, zJar + 0.02), V3(0.016, 0.002, 0.01), "food.tomato-sauce", yaw: 30)
        K.blob(&m, V3(-0.03, ly + 0.0185, zJar - 0.025), V3(0.008, 0.002, 0.007), "food.tomato-sauce", yaw: 70)
        K.blob(&m, V3(0.052, cy + 0.025, zJar + 0.005), V3(0.004, 0.012, 0.004), "food.tomato-sauce")
        groundAO(&m)
        return LODModel(m)
    }
}
