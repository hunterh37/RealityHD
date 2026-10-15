import simd
import Foundation
import RealityKit
import RealKit

/// Inside the arched `hangar` structure (24 x 30 m), sliding doors open to the south. A gantry crane stands over a
/// fuel tank in the middle bay, a crew capsule and a liquid engine wait on the floor, a wing section rests
/// on sawhorses, part racks line the west wall and the avionics workbench, anglepoise lamp and tool chest
/// the east wall. Oil drums, a cable spool and a barrel sit in the corners.
public struct AerospaceHangar: RealSceneBuilder {
    public static let id = "aerospace-hangar"
    public static let summary = "Hangar bay: gantry crane over a fuel tank, capsule and engine on the floor, wing on sawhorses, part racks, avionics workbench and tool chest."
    public static let tags = ["aerospace", "interior", "industrial"]
    public static let author = "hunter"

    /// The hangar shell; its floor top sits at `floorY`, doors on +Z.
    public var hangar = Hangar()
    public var floorY: Float = 0.15
    public init() {}

    static let light = InteriorLight().with {
        $0.ceiling = SIMD3(0.5, 0.5, 0.5); $0.walls = SIMD3(0.5, 0.51, 0.5); $0.floor = SIMD3(0.36, 0.35, 0.33)
        $0.fixtures = SIMD3(5.0, 5.0, 4.8); $0.fixturePitch = 0.3; $0.fixtureSize = SIMD2(0.06, 0.3)
        $0.windowAzimuth = 180; $0.windowWidth = 70; $0.windowElevation = 0...25; $0.exposure = -0.3
    }

    public func build(seed: UInt64) -> RealScene {
        var scene = RealScene(name: Self.id)
        var rng = SeededRNG(seed: seed &+ 11)
        let hx = hangar.width / 2 - 0.3, hz = hangar.depth / 2
        let fy = floorY
        func at(_ x: Float, _ z: Float, y: Float = 0, yaw: Float = 0) -> Xform { place(x, z, y: fy + y, yaw: yaw) }
        scene.add(hangar, at: .identity, seed: seed)

        // Middle bay: gantry crane over an upright fuel tank, yellow bay box on the floor.
        scene.add(GantryCrane(), at: at(0, -1.5), seed: seed &+ 1, state: "centered")
        scene.add(FuelTankM(), at: at(0.2, -1.6, yaw: 20), seed: seed &+ 2)
        // Floor work: capsule, engine, wing on sawhorses.
        scene.add(CommandPod(), at: at(-5.5, -4, yaw: 30), seed: seed &+ 3)
        scene.add(EngineLiquidSmall(), at: at(5.5, -4.5, yaw: -20), seed: seed &+ 4)
        for x in [Float(-6.2), -3.2] { scene.add(Sawhorse(), at: at(x, 3.8, yaw: 90), seed: seed &+ UInt64(5 + Int(-x))) }
        scene.add(WingSection(), at: at(-6.4, 3.8, y: 0.78, yaw: 0), seed: seed &+ 7)
        scene.add(NoseCone(), at: at(-7.5, 6.8, yaw: rng.float(0...360)), seed: seed &+ 8)

        // West wall: part racks facing the bay.
        for (i, z) in [Float(-5.5), -2.2, 1.1].enumerated() {
            scene.add(PartRack(), at: at(-hx + 0.9, z, yaw: 90), seed: seed &+ UInt64(10 + i))
        }
        // East wall: avionics bench with a lamp, tool chest beside it.
        let bx = hx - 0.6
        scene.add(AerospaceWorkbench(), at: at(bx, 1.5, yaw: -90), seed: seed &+ 20)
        scene.add(AnglepoiseLamp(), at: at(bx + 0.1, 2.2, y: 0.9, yaw: -120), seed: seed &+ 21)
        scene.add(ToolChest(), at: at(bx + 0.05, -1.4, yaw: -90), seed: seed &+ 22)

        // Corners: oil drums, cable spool, barrel.
        for k in 0..<3 {
            scene.add(OilDrum(), at: at(hx - 1.4 - Float(k % 2) * 0.66, -hz + 1.6 + Float(k / 2) * 0.66, yaw: rng.float(0...360)), seed: seed &+ UInt64(30 + k))
        }
        scene.add(CableSpool(), at: at(hx - 3.6, -hz + 1.8, yaw: 80), seed: seed &+ 34)
        scene.add(Barrel(), at: at(-hx + 1.4, -hz + 1.6), seed: seed &+ 35)

        // High-bay lights in a 3 x 3 grid under the roof.
        for i in 0..<3 { for j in 0..<3 {
            scene.lights.append(RigLight(name: "high-bay-\(i)-\(j)", position: V3(-6 + Float(i) * 6, 8.6, -9 + Float(j) * 8),
                                         color: V3(1, 0.97, 0.92), intensity: 14_000, attenuationRadius: 16))
        }}

        scene.farGround = "ground.sand:B79E78"
        scene.lighting = .init(sky: SunSky(elevation: 30, azimuth: 200, turbidity: 3), interior: Self.light, fog: 0)
        scene.bake = .interior
        scene.batchStatics = true
        scene.batchCell = 6
        scene.camera = .init(eye: V3(4, fy + 1.68, -12.5), target: V3(-1, fy + 1.8, 2), fov: 66)
        return scene
    }
}
