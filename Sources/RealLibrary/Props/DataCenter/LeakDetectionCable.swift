import simd
import Foundation

/// Leak detection cable: 2 m yellow sensing cable laid in a gentle S on the floor, white terminator end cap at one end, black connector at the other, three adhesive hold-down clips. Parts: yellow sensing jacket, white terminator end cap, connector with coupling ring, adhesive clips.
public struct LeakDetectionCable: RealAsset {
    public static let id = "leak-detection-cable"
    public static let summary = "Yellow liquid-leak sensing cable, 2 m in a gentle S on the floor, with a white terminator cap, a connector and three adhesive hold-down clips."
    public static let tags = ["prop"]
    public static let budget = 800
    public static let author = "realityhd"

    /// Overall size in meters (x length, y height, z swing).
    public var size = V3(2.0, 0.018, 0.09)
    /// Sensing jacket radius in meters (6 mm cable).
    public var cordRadius: Float = 0.003
    /// Sideways amplitude of the S in meters.
    public var swing: Float = 0.032
    /// Jacket material.
    public var jacket: MaterialKey = "plastic.jacket:E8C21A"
    /// Terminator and clip material.
    public var white: MaterialKey = "plastic.matte:F2F2F2"
    /// Connector body material.
    public var connector: MaterialKey = "plastic.matte:1E1F21"
    public init() {}

    /// Centerline z at x (zero at both ends).
    func zAt(_ x: Float) -> Float {
        let u = (x + size.x / 2) / size.x
        return swing * sin(2 * .pi * u) * min(1, sin(.pi * min(max(u, 0), 1)) * 4)
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let half = size.x / 2
        let r = cordRadius
        let capL: Float = 0.032, conL: Float = 0.05
        // Cable between the two end fittings.
        var path: [V3] = []
        let n = 24
        let x0 = -half + conL - 0.004, x1 = half - capL + 0.004
        for i in 0...n {
            let x = x0 + (x1 - x0) * Float(i) / Float(n)
            path.append(V3(x, r, zAt(x)))
        }
        m.add(Prim.tube(path, radii: Array(repeating: r, count: path.count), sides: 6, seamTile: 0.02, material: jacket))
        let toX = simd_quatf(angle: -.pi / 2, axis: V3(0, 0, 1))
        func xcyl(_ prof: [V2], at c: V3, mat: MaterialKey, seg: Int = 12) {
            m.add(Prim.lathe(prof, segments: seg, seamTile: 0.02, material: mat), Xform(translation: c, rotation: toX))
        }
        // Terminator end cap at +x: white bullet with a collar.
        xcyl([V2(0, 0), V2(0.0042, 0), V2(0.0042, 0.018), V2(0.0050, 0.019), V2(0.0050, 0.027), V2(0.0035, 0.032), V2(0, 0.032)],
             at: V3(half - capL, r + 0.0005, 0), mat: white, seg: 10)
        // Connector at -x: strain relief, body, knurled coupling ring, pin collar.
        xcyl([V2(0, 0), V2(0.0042, 0), V2(0.0055, 0.014), V2(0.0055, 0.018), V2(0.0085, 0.018), V2(0.0085, 0.040),
              V2(0, 0.040)], at: V3(-half, 0.0085, 0), mat: connector, seg: 10)
        // Three adhesive hold-down clips: flat pad plus a bridge across the cable.
        for k in 0..<3 {
            let cx = -half + 0.55 + Float(k) * 0.45 + Float(rng.next() % 40) / 1000
            let ang = atan2(zAt(cx + 0.01) - zAt(cx - 0.01), 0.02)
            let rot = simd_quatf(angle: -ang, axis: V3(0, 1, 0))
            let c = V3(cx, 0, zAt(cx))
            m.add(cuboid(V3(0.022, 0.0012, 0.026), material: white), Xform(translation: c + V3(0, 0.0006, 0), rotation: rot))
            m.add(cuboid(V3(0.008, 0.0012, 0.016), material: white), Xform(translation: c + V3(0, 2 * r + 0.0016, 0), rotation: rot))
            for s: Float in [-1, 1] {
                m.add(cuboid(V3(0.008, 2 * r + 0.0016, 0.0018), material: white), Xform(translation: c + V3(0, (2 * r + 0.0016) / 2 + 0.0012, s * (r + 0.0012)), rotation: rot))
            }
        }
        // Story detail: a sparse dark scuff band near mid-run where it was dragged.
        let sx = Float(rng.next() % 200) / 1000 - 0.1
        m.add(cuboid(V3(0.05, 0.0004, 0.0014), material: "plastic.matte:8A7A3A"), Xform(translation: V3(sx, 2 * r - 0.0003, zAt(sx))))
        groundAO(&m)
        return LODModel(m)
    }
}
