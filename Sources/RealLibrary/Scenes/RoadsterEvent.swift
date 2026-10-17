import simd
import Foundation
import RealityKit
import RealKit

/// Night launch event: 60 x 40 m dark floor, a 26 m concrete ramp with red LED edges and a truss tower,
/// the roadster parked on the apron under a white key light, near-zero ambient. Entities named
/// "roadster", "ramp" and "smoke-anchor". Ramp origin is `rampOrigin`; its path comes from
/// `RoadsterRamp.centerline(_:)` (ramp-local, add `rampOrigin`).
public struct RoadsterEvent: RealSceneBuilder {
    public static let id = "roadster-event"
    public static let summary = "Night launch event: dark 60 x 40 m floor, 26 m red-LED concrete ramp with truss tower, roadster on the apron, near-zero ambient light."
    public static let tags = ["showcase", "vehicle"]
    public static let author = "realityhd"

    /// Ramp origin (apron start) in scene space, meters.
    public static let rampOrigin = V3(8, 0, -12)
    public init() {}

    public func build(seed: UInt64) -> RealScene {
        var scene = RealScene(name: Self.id)
        let o = Self.rampOrigin
        scene.farGround = nil
        scene.add(EventFloor(), seed: seed)
        var ramp = RoadsterRamp().build(seed: seed).levels[0]
        ramp.name = "ramp"
        scene.add(ramp, at: place(o.x, o.z))
        var tower = RampTrussTower()
        tower.height = 28
        // Flush behind the vertical run (ramp back at z = 10.7 local); arm turned to -Z over the lip.
        scene.add(tower, at: place(o.x - 4.8, o.z + 11.4, yaw: .pi / 2), seed: seed &+ 1)
        scene.addLive(Roadster2026(), at: place(o.x, o.z + 2.2), seed: seed &+ 2, state: "parked", interactive: false, name: "roadster")
        var anchor = Model(name: "smoke-anchor")
        anchor.add(cuboid(V3(0.02, 0.02, 0.02), material: "plastic.matte:101010"), Xform(translation: V3(0, 0.01, 0)))
        scene.add(anchor, at: place(o.x, o.z + 1))

        // Key: white wash on the apron from front and low, falling off up the ramp.
        scene.lights.append(RigLight(name: "apron-key", kind: .spot(inner: 25, outer: 50), position: V3(o.x - 3, 5, o.z - 9), direction: V3(0.25, -0.35, 1),
                                     color: V3(1, 0.95, 0.9), intensity: 450000, attenuationRadius: 40, castsShadow: false))
        scene.lights.append(RigLight(name: "car-spot", kind: .spot(inner: 12, outer: 28), position: V3(o.x - 7, 7, o.z - 3), direction: V3(7, -6, 5.2),
                                     color: V3(1, 0.97, 0.92), intensity: 200000, attenuationRadius: 25, castsShadow: false))
        // Key pool on the ramp base, 5600 K.
        scene.lights.append(RigLight(name: "ramp-base-pool", kind: .spot(inner: 14, outer: 32), position: V3(o.x - 2, 9, o.z + 2), direction: V3(0.2, -1, 0.35),
                                     color: V3(1, 0.93, 0.85), intensity: 500000, attenuationRadius: 22, castsShadow: false))
        // White key from behind the camera onto the ramp wall.
        scene.lights.append(RigLight(name: "wall-key", kind: .spot(inner: 24, outer: 46), position: V3(o.x, 2.2, o.z - 9), direction: V3(0, 0.12, 1),
                                     color: V3(1, 1, 1), intensity: 3500000, attenuationRadius: 40, castsShadow: false))
        // Front wash, 5600 K, aimed at the ramp face from the car side.
        for (i, (h, ty, tz)) in [(Float(2), Float(2), Float(10)), (6, 9, 15), (10, 19, 18)].enumerated() {
            let from = V3(o.x - 4, h, o.z - 6), to = V3(o.x, o.y + ty, o.z + tz)
            scene.lights.append(RigLight(name: "ramp-wash-\(i)", kind: .spot(inner: 22, outer: 45), position: from, direction: to - from,
                                         color: V3(1, 0.93, 0.85), intensity: 5000000, attenuationRadius: 45, castsShadow: false))
        }
        // Floodlights at the far edge, aimed at the camera side.
        for x: Float in [-20, 0, 20] {
            scene.lights.append(RigLight(name: "flood-\(Int(x))", kind: .spot(inner: 20, outer: 40), position: V3(x, 2.5, 19), direction: V3(0, 0.1, -1),
                                         color: V3(0.9, 0.95, 1), intensity: 120000, attenuationRadius: 30))
        }
        var sky = SunSky(elevation: -12, azimuth: 135, turbidity: 2)
        sky.iblExposure = -3.5
        scene.lighting = .init(sky: sky, fog: 0, sunScale: 0)
        scene.camera = .init(eye: V3(-2, 1.6, -17), target: V3(o.x, 7, o.z + 4), fov: 68)
        return scene
    }
}
