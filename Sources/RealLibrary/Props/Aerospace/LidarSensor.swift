import simd
import Foundation

/// Spinning lidar puck, 0.15 m diameter x 0.1 m. A black anodized base with three mounting ears and a
/// cable gland at the back carries a rotating head: a dark wraparound optical window between a ribbed
/// lower collar and a brushed aluminium cap. The head turns about +Y (10 Hz in use).
public struct LidarSensor: RealArticulated {
    public static let id = "lidar-sensor"
    public static let summary = "Spinning lidar puck, 0.15 m dia x 0.1 m: anodized base with cable gland and a rotating head behind a dark wraparound optical window."
    public static let tags = ["prop", "aerospace", "electronics", "articulated"]
    public static let budget = 8000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 34, elevation: 22, distance: 1.1, studio: true)

    /// Head diameter and overall height (m).
    public var diameter: Float = 0.15
    public var height: Float = 0.1
    public var body: MaterialKey = "metal.anodized-black"
    public var cap: MaterialKey = "metal.aluminum-brushed"
    public var window: MaterialKey = "glass.led-lens:34507A"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [3])
        let R = diameter / 2, baseH: Float = 0.03
        for l in 0..<2 {
            var m = Model(name: Self.id)
            let sg = l == 0 ? 48 : 20
            // Base: chamfered puck with a groove.
            m.add(Prim.lathe([V2(0, 0), V2(R - 0.004, 0), V2(R - 0.001, 0.003), V2(R - 0.001, baseH - 0.012), V2(R - 0.004, baseH - 0.01),
                              V2(R - 0.004, baseH - 0.008), V2(R - 0.001, baseH - 0.006), V2(R - 0.001, baseH - 0.002), V2(R - 0.005, baseH), V2(0, baseH)],
                             segments: sg, seamTile: 0.1, material: body))
            // Mounting ears with screws, and the cable gland at the back (-Z).
            for k in 0..<3 {
                let a = Float(k) / 3 * 2 * .pi + .pi / 6
                let d = V3(sin(a), 0, cos(a))
                m.add(Prim.roundedBox(V3(0.024, 0.006, 0.024), radius: 0.004, bevelSegments: l == 0 ? 2 : 1, material: body),
                      Xform(translation: d * (R + 0.002) + V3(0, 0.003, 0), rotation: simd_quatf(angle: a, axis: .up)))
                if l == 0 { hexBolt(&m, at: d * (R + 0.004) + V3(0, 0.006, 0), normal: .up, size: 0.004, material: "metal.steel") }
            }
            let gz = -R + 0.004, gy = baseH * 0.5
            m.add(Prim.cylinder(radius: 0.009, height: 0.014, bevel: 0.0015, segments: l == 0 ? 18 : 8, material: "metal.anodized:6E7378"),
                  Xform(translation: V3(0, gy, gz), rotation: simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))))
            if l == 0 {
                let cable = catmull([V3(0, gy, gz - 0.014), V3(0, gy - 0.003, gz - 0.025), V3(0.003, 0.0045, gz - 0.04), V3(0.008, 0.0045, gz - 0.05)], per: 5)
                m.add(Prim.tube(cable, radii: cable.map { _ in 0.0045 }, sides: 8, seamTile: 0.03, material: "rubber", capEnd: true))
            }
            if l == 0 {
                // Serial label on the base front.
                m.add(Prim.roundedBox(V3(0.034, 0.012, 0.0008), radius: 0.0003, bevelSegments: 1, material: "label.inspection"),
                      Xform(translation: V3(0, baseH * 0.42, R - 0.0006)))
            }
            rig.base[l] = m
        }
        rig.part("head", pivot: V3(0, baseH, 0), joint: .hinge(axis: .up, 0...360, duration: 0.1))
        for l in 0..<2 {
            var m = Model(name: Self.id)
            let sg = l == 0 ? 48 : 20
            let y0 = baseH + 0.002, wy0 = y0 + 0.018, wy1 = height - 0.016
            // Ribbed collar, window band, cap.
            m.add(Prim.lathe([V2(0, y0), V2(R - 0.006, y0), V2(R - 0.003, y0 + 0.003), V2(R - 0.003, wy0)], segments: sg, seamTile: 0.1, material: body))
            if l == 0 {
                for k in 0..<3 {
                    let y = y0 + 0.004 + Float(k) * 0.005
                    m.add(Prim.torus(major: R - 0.003, minor: 0.0012, segments: sg, sides: 6, material: body), Xform(translation: V3(0, y, 0)))
                }
            }
            m.add(Prim.lathe([V2(R - 0.003, wy0), V2(R - 0.0045, wy0 + 0.002), V2(R - 0.0045, wy1 - 0.002), V2(R - 0.003, wy1)], segments: sg, seamTile: 0.15, material: window))
            m.add(Prim.lathe([V2(R - 0.003, wy1), V2(R - 0.003, height - 0.006), V2(R - 0.008, height - 0.001), V2(R - 0.02, height), V2(0, height)],
                             segments: sg, seamTile: 0.1, material: cap))
            // Inner emitter block faintly visible: a dark rib behind the window front.
            m.add(Prim.roundedBox(V3(0.03, wy1 - wy0 - 0.006, 0.004), radius: 0.0015, bevelSegments: 1, material: "metal.anodized-black"),
                  Xform(translation: V3(0, (wy0 + wy1) / 2, R - 0.012)))
            rig.add(m, to: "head", lod: l)
        }
        rig.states = [RigState("idle"), RigState("spin-half", ["head": 180])]
        groundAO(&rig, height: 0.03, floor: 0.6)
        return rig
    }
}
