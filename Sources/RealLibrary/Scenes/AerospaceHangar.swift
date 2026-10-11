import simd
import Foundation
import RealityKit
import RealKit

/// Hangar bay, 22 x 18 m and 9 m high, with a 14 m door open to the north. A gantry crane stands over a
/// fuel tank in the middle bay, a crew capsule and a liquid engine wait on the floor, a wing section rests
/// on sawhorses, part racks line the west wall and the avionics workbench, anglepoise lamp and tool chest
/// the east wall. Oil drums, a cable spool and a barrel sit in the corners.
public struct AerospaceHangar: RealSceneBuilder {
    public static let id = "aerospace-hangar"
    public static let summary = "Hangar bay: gantry crane over a fuel tank, capsule and engine on the floor, wing on sawhorses, part racks, avionics workbench and tool chest."
    public static let tags = ["aerospace", "interior", "industrial"]
    public static let author = "hunter"

    public var size = V3(22, 9, 18)
    public var doorWidth: Float = 14
    public var doorHeight: Float = 7
    public init() {}

    public func room() -> Room {
        var r = Room(size: size)
        r.floor = "concrete.shop"
        r.wall = "metal.roofing:9EA4A6"
        r.skirting = "concrete.rough:8C877E"
        r.skirtingHeight = 0.4
        r.ceiling = .none
        r.cell = 0.5
        r.openings.append(.init(.north, offset: 0, width: doorWidth, sill: 0, head: doorHeight))
        return r
    }

    static let light = InteriorLight().with {
        $0.ceiling = SIMD3(0.5, 0.5, 0.5); $0.walls = SIMD3(0.5, 0.51, 0.5); $0.floor = SIMD3(0.36, 0.35, 0.33)
        $0.fixtures = SIMD3(5.0, 5.0, 4.8); $0.fixturePitch = 0.3; $0.fixtureSize = SIMD2(0.06, 0.3)
        $0.windowAzimuth = 0; $0.windowWidth = 70; $0.windowElevation = 0...25; $0.exposure = -0.3
    }

    public func build(seed: UInt64) -> RealScene {
        var scene = RealScene(name: Self.id)
        var rng = SeededRNG(seed: seed &+ 11)
        let room = room()
        let hx = size.x / 2, hz = size.z / 2, T = room.wallThickness
        scene.add(room.shell(), bake: true)
        scene.add(room.with { $0.ceiling = .flat; $0.wall = "metal.roofing:8E9496" }.ceilingModel())

        // Middle bay: gantry crane over an upright fuel tank, yellow bay box on the floor.
        scene.add(GantryCrane(), at: place(0, -1.5), seed: seed &+ 1, state: "centered")
        scene.add(FuelTankM(), at: place(0.2, -1.6, yaw: 20), seed: seed &+ 2)
        for (x, z, w, d) in [(Float(0), Float(-4.2), Float(7), Float(0.12)), (0, 1.2, 7, 0.12), (-3.5, -1.5, 0.12, 5.5), (3.5, -1.5, 0.12, 5.5)] {
            scene.add(Model(name: "bay-line", surfaces: [Prim.roundedBox(V3(w, 0.004, d), radius: 0.001, bevelSegments: 1, material: "paint.lane-yellow")]),
                      at: Xform(translation: V3(x, 0.002, z)))
        }

        // Floor work: capsule, engine, wing on sawhorses.
        scene.add(CommandPod(), at: place(-5.5, -4, yaw: 30), seed: seed &+ 3)
        scene.add(EngineLiquidSmall(), at: place(5.5, -4.5, yaw: -20), seed: seed &+ 4)
        for x in [Float(-6.2), -3.2] { scene.add(Sawhorse(), at: place(x, 3.8, yaw: 90), seed: seed &+ UInt64(5 + Int(-x))) }
        scene.add(WingSection(), at: place(-6.4, 3.8, y: 0.78, yaw: 0), seed: seed &+ 7)
        scene.add(NoseCone(), at: place(-7.5, 6.8, yaw: rng.float(0...360)), seed: seed &+ 8)

        // West wall: part racks facing the bay.
        for (i, z) in [Float(-5.5), -2.2, 1.1].enumerated() {
            scene.add(PartRack(), at: place(-hx + T / 2 + 0.6, z, yaw: 90), seed: seed &+ UInt64(10 + i))
        }
        // East wall: avionics bench with a lamp, tool chest beside it.
        let bx = hx - T / 2 - 0.5
        scene.add(AerospaceWorkbench(), at: place(bx, 1.5, yaw: -90), seed: seed &+ 20)
        scene.add(AnglepoiseLamp(), at: place(bx + 0.1, 2.2, y: 0.9, yaw: -120), seed: seed &+ 21)
        scene.add(ToolChest(), at: place(bx + 0.05, -1.4, yaw: -90), seed: seed &+ 22)

        // Corners: oil drums, cable spool, barrel.
        for k in 0..<3 {
            scene.add(OilDrum(), at: place(hx - 1.4 - Float(k % 2) * 0.66, hz - 1.2 - Float(k / 2) * 0.66, yaw: rng.float(0...360)), seed: seed &+ UInt64(30 + k))
        }
        scene.add(CableSpool(), at: place(hx - 3.6, hz - 1.4, yaw: 80), seed: seed &+ 34)
        scene.add(Barrel(), at: place(-hx + 1.2, hz - 1.2), seed: seed &+ 35)

        // High-bay lights in a 3 x 3 grid under the roof.
        for i in 0..<3 { for j in 0..<3 {
            scene.lights.append(RigLight(name: "high-bay-\(i)-\(j)", position: V3(-7 + Float(i) * 7, size.y - 0.6, -6 + Float(j) * 6),
                                         color: V3(1, 0.97, 0.92), intensity: 14_000, attenuationRadius: 16))
        }}

        scene.farGround = "concrete.rough"
        scene.lighting = .init(sky: SunSky(elevation: 30, azimuth: 200, turbidity: 3), interior: Self.light, fog: 0)
        scene.bake = .interior
        scene.batchStatics = true
        scene.batchCell = 6
        scene.camera = .init(eye: V3(4, 1.68, 7.5), target: V3(-1, 1.8, -2), fov: 66)
        return scene
    }
}
