import simd
import Foundation

/// Velcro tie: black hook-and-loop cable strap, 0.2 m long, lying on the floor with the free end curled into a loop and a slotted buckle. Parts: black loop-side strap, hook-side patch, slotted buckle, curled loop.
public struct VelcroTie: RealAsset {
    public static let id = "velcro-tie"
    public static let summary = "Black hook-and-loop cable tie, 0.2 m strap with a slotted buckle, free end curled into a loop."
    public static let tags = ["prop"]
    public static let budget = 400
    public static let author = "realityhd"

    /// Overall size in meters (x length of the lying tail plus loop, y loop height, z strap width).
    public var size = V3(0.098, 0.045, 0.018)
    /// Strap width in meters.
    public var width: Float = 0.012
    /// Strap thickness in meters.
    public var thick: Float = 0.002
    /// Loop-side outer fabric.
    public var strap: MaterialKey = "fabric.nylon:1A1A1A"
    /// Hook-side patch.
    public var hook: MaterialKey = "fabric.nylon:0E0E0F"
    /// Buckle plastic.
    public var buckle: MaterialKey = "plastic.matte:222325"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let t = thick, w = width
        let R: Float = 0.0205
        // Path in the xy plane: tail lies along the floor, then curls up into an open spiral loop.
        let tailL: Float = 0.070
        var path: [V3] = []
        for i in 0..<4 { path.append(V3(-tailL + tailL * Float(i) / 4, t / 2, 0)) }
        let cx: Float = 0, cyc = t / 2 + R
        let steps = 25
        for i in 0...steps {
            let a = -Float.pi / 2 + Float(i) / Float(steps) * 1.78 * .pi
            let rr = R + Float(i) / Float(steps) * 0.0035
            path.append(V3(cx + rr * cos(a), cyc + rr * sin(a), 0))
        }
        let prof: [V2] = [V2(-w / 2, -t / 2), V2(w / 2, -t / 2), V2(w / 2, t / 2), V2(-w / 2, t / 2)]
        m.add(Prim.sweep(prof, along: path, up: V3(0, 0, 1), caps: true, material: strap))
        // Hook-side patch on the tail's upper face.
        m.add(cuboid(V3(0.045, 0.0006, w * 0.8), material: hook), Xform(translation: V3(-tailL + 0.03, t + 0.0003, 0)))
        // Slotted buckle at the tail end: frame with an open slot.
        let bx = -tailL - 0.002
        m.add(Prim.roundedBox(V3(0.007, 0.0045, w + 0.006), radius: 0.001, bevelSegments: 1, material: buckle), Xform(translation: V3(bx, 0.00225, 0)))
        m.add(cuboid(V3(0.0018, 0.0048, w * 0.8), material: "plastic.matte:050506"), Xform(translation: V3(bx, 0.00225, 0)))
        // Story detail: a frayed loop-side edge strip near the tail.
        let fx = -0.02 + Float(rng.next() % 100) / 10000
        m.add(cuboid(V3(0.016, 0.0003, 0.0008), material: "plastic.matte:2E2F31"), Xform(translation: V3(fx, t + 0.0001, w / 2 - 0.0006)))
        groundAO(&m)
        return LODModel(m)
    }
}
