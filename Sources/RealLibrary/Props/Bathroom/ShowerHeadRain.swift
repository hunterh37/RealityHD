import simd
import Foundation

/// Rain shower head: everyday bathroom, chrome. Parts: round head face with nozzle grid, head body, ball joint, shower arm stub, wall flange.
public struct ShowerHeadRain: RealAsset {
    public static let id = "shower-head-rain"
    public static let summary = "Chrome rain shower head: disc face with rubber nozzle grid, ball joint, short arm and wall flange."
    public static let tags = ["prop", "interior", "bathroom", "metal"]
    public static let budget = 8000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.25, 0.05, 0.25)
    public init() {}

    public var chrome: MaterialKey = "metal.chrome"
    public var rubber: MaterialKey = "plastic.black"

    public func build(seed: UInt64) -> LODModel {
        func make(_ lod: Int) -> Model {
            var m = Model(name: Self.id)
            let hi = lod == 0
            let r = size.x / 2, h = size.y
            let seg = hi ? 48 : 20
            let dy: Float = 0.0026
            func lp(_ pts: [V2]) -> [V2] { pts.map { V2($0.x, $0.y + dy) } }
            // Head body: shallow dome, face just above y = 0, rolled chrome edge.
            m.add(Prim.lathe(lp([V2(0.001, 0.0), V2(r - 0.012, 0.0), V2(r - 0.004, 0.0015), V2(r, 0.006), V2(r - 0.001, 0.012),
                              V2(r - 0.015, 0.02), V2(r - 0.07, 0.029), V2(0.04, 0.0335), V2(0.02, 0.0345), V2(0.001, 0.035)]),
                             segments: seg, seamTile: 0.12, material: chrome))
            // Rubber nozzle plate on the face.
            m.add(Prim.lathe(lp([V2(0.001, -0.0004), V2(r - 0.018, -0.0004), V2(r - 0.016, 0.0006), V2(0.001, 0.0006)]),
                             segments: seg, seamTile: 0.12, material: rubber))
            // Nozzle studs in concentric rings.
            let stud = [V2(0.0001, 0.0028), V2(0.0018, 0.0026), V2(0.0031, 0.0), V2(0.0033, -0.0004)]
            let ringsN = hi ? 5 : 3
            for k in 0..<ringsN {
                let rr = Float(k + 1) / Float(ringsN) * (r - 0.03)
                let count = max(6, Int(2 * Float.pi * rr / 0.014))
                for i in 0..<count {
                    let a = (Float(i) + (k % 2 == 0 ? 0 : 0.5)) / Float(count) * 2 * Float.pi
                    m.add(Prim.lathe(stud, segments: hi ? 6 : 4, seamTile: 0.01, material: rubber),
                          Xform(translation: V3(cos(a) * rr, 0, sin(a) * rr)))
                }
            }
            // Collar and ball joint on top.
            m.add(Prim.lathe(lp([V2(0.001, 0.034), V2(0.02, 0.034), V2(0.019, 0.0365), V2(0.013, 0.0375), V2(0.001, 0.0375)]), segments: hi ? 28 : 12, seamTile: 0.08, material: chrome))
            m.add(Prim.superellipsoid(V3(0.022, 0.02, 0.022), exponent: 2, subdivisions: hi ? 12 : 6, material: chrome),
                  Xform(translation: V3(0, h - 0.01, 0)))
            groundAO(&m)
            return m
        }
        return LODModel(levels: [make(0), make(1)], switchDistances: [4])
    }
}
