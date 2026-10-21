import simd
import Foundation

/// Wall mounted speed bag platform: 24 inch round oiled oak board, ball-bearing swivel under the centre,
/// steel wall plate with two braces and a hinge strap. Origin is the board centre at its underside (y = 0);
/// the wall plate sits at z = -`wallOffset`. Bag hooks on at `swivelPoint`.
public struct SpeedBagPlatform: RealAsset {
    public static let id = "speed-bag-platform"
    public static let summary = "Round hardwood speed bag platform on a steel wall bracket with an under-board swivel."
    public static let tags = ["prop", "sports", "wood", "metal"]
    public static let budget = 10000
    public static let author = "hunter"
    public static let preview = PreviewHint(azimuth: 55, elevation: 22, distance: 1.0, studio: true)

    /// Board radius (m).
    public var boardRadius: Float = 0.305
    /// Board thickness (m).
    public var thickness: Float = 0.032
    /// Distance from the board centre to the wall plate (m).
    public var wallOffset: Float = 0.355
    /// Board wood.
    public var wood: MaterialKey = "wood.oak"
    public init() {}

    /// Inner bottom of the swivel eye, where a bag hook bears (asset space).
    public var swivelPoint: V3 { V3(0, -0.0332, 0) }

    public func build(seed: UInt64) -> LODModel {
        var levels: [Model] = []
        for l in 0..<2 {
            let detail = l == 0
            var m = Model(name: Self.id)
            let R = boardRadius, T = thickness
            // Board: beveled disc, grain across.
            m.add(Prim.cylinder(radius: R, height: T, bevel: 0.006, segments: detail ? 64 : 28, bevelSegments: 2, seamTile: 0.3, material: wood), Xform(translation: V3(0, 0, 0)))
            // Underside mount plate, bolts, compact ball-bearing swivel and hanging eye.
            m.add(Prim.cylinder(radius: 0.045, height: 0.005, bevel: 0.0015, segments: detail ? 28 : 12, material: "metal.steel"), Xform(translation: V3(0, -0.005, 0)))
            for k in 0..<4 {
                let a = Float(k) / 4 * 2 * .pi + .pi / 4
                hexBolt(&m, at: V3(cos(a) * 0.032, -0.005, sin(a) * 0.032), normal: V3(0, -1, 0), size: 0.007, material: "metal.bolt-bright")
            }
            m.add(Prim.cylinder(radius: 0.022, height: 0.014, bevel: 0.003, segments: detail ? 24 : 12, material: "metal.chrome"), Xform(translation: V3(0, -0.019, 0)))
            m.add(Prim.torus(major: 0.0105, minor: 0.0028, segments: detail ? 18 : 10, sides: detail ? 8 : 4, material: "metal.chrome"),
                  Xform(translation: V3(0, -0.0255, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))

            // Wall plate, braces, hinge strap.
            let wz = -wallOffset
            m.add(Prim.roundedBox(V3(0.18, 0.34, 0.008), radius: 0.003, bevelSegments: 2, material: "metal.anodized-black"), Xform(translation: V3(0, -0.04, wz)))
            for sx: Float in [-1, 1] {
                for sy: Float in [-1, 1] { hexBolt(&m, at: V3(sx * 0.06, -0.04 + sy * 0.13, wz + 0.004), normal: V3(0, 0, 1), size: 0.011, material: "metal.bolt-bright") }
                let (s, x) = board(from: V3(sx * 0.07, -0.16, wz + 0.01), to: V3(sx * 0.07, -0.014, -R + 0.07), width: 0.028, thick: 0.006, up: V3(1, 0, 0), bevel: 0.0015, material: "metal.anodized-black")
                m.add(s, x)
                // Hinge strap over the board top edge.
                let (hs, hx) = board(from: V3(sx * 0.07, T + 0.003, wz + 0.01), to: V3(sx * 0.07, T + 0.003, -R + 0.05), width: 0.034, thick: 0.004, up: .up, bevel: 0.001, material: "metal.anodized-black")
                m.add(hs, hx)
                m.add(Prim.cylinder(radius: 0.011, height: 0.044, bevel: 0.002, segments: detail ? 14 : 8, material: "metal.steel"),
                      Xform(translation: V3(sx * 0.07 - 0.022, T + 0.003, wz + 0.014), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1)) * simd_quatf(degrees: 0, axis: .up)))
                for k in 0..<2 { hexBolt(&m, at: V3(sx * 0.07, T + 0.005, -R + 0.04 + Float(k) * 0.02), normal: .up, size: 0.008, material: "metal.bolt-bright") }
            }
            levels.append(m)
        }
        return LODModel(levels: levels, switchDistances: [3])
    }
}
