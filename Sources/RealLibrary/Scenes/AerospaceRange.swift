import simd
import Foundation
import RealityKit
import RealKit

/// Desert launch range at true scale. A launch pad with its service tower at the origin, a blockhouse
/// 80 m off with its slits on the pad, a runway along the south edge with a windsock, course obstacles
/// (ring gate, banded pylons, a lattice pylon, a gap wall, a tethered balloon, floating debris rocks)
/// out to 200 m, and scrub, boulders, dry grass and oil drums on sandy ground. The camera stands on
/// the viewing platform 60 m from the pad (VisionSpacecraft flight-test spec).
public struct AerospaceRange: RealSceneBuilder {
    public static let id = "aerospace-range"
    public static let summary = "Desert launch range: pad and service tower, blockhouse, runway with windsock, ring gate, pylons, gap wall, balloon and debris, seen from the viewing platform."
    public static let tags = ["aerospace", "desert", "outdoor"]
    public static let author = "hunter"

    /// Side of the detailed ground patch in meters.
    public var size: Float = 420
    public var sand: MaterialKey = "ground.sand:B79E78"
    public init() {}

    public func build(seed: UInt64) -> RealScene {
        var scene = RealScene(name: Self.id)
        scene.farGround = sand
        var rng = SeededRNG(seed: seed &+ 99)
        let ground = GroundPatch().with { $0.size = size; $0.segments = 220; $0.relief = 0.7; $0.featureSize = 28; $0.flatCenter = 45; $0.material = sand }
        scene.add(ground, seed: seed)
        func y(_ x: Float, _ z: Float) -> Float { ground.height(x: x, z: z, seed: seed) }
        func at(_ x: Float, _ z: Float, yaw: Float = 0, sink: Float = 0, lift: Float = 0) -> Xform {
            place(x, z, y: y(x, z) - sink + lift, yaw: yaw)
        }
        func yawToward(_ from: V2, _ to: V2) -> Float { atan2(-(to.y - from.y), to.x - from.x) * 180 / .pi }

        // Launch complex: pad at the origin, service tower on the rear deck with its arm over the mount.
        let pad = LaunchPad()
        scene.add(pad, at: at(0, 0, sink: 0.05), seed: seed &+ 1)
        scene.add(LaunchTower(), at: place(-4.2, 0, y: y(0, 0) - 0.05 + pad.deckHeight), seed: seed &+ 2)

        // Viewing platform 60 m from the pad, front rail (+X) facing it.
        let vp = V2(-42, 43)
        scene.add(ViewingPlatform(), at: at(vp.x, vp.y, yaw: yawToward(vp, V2(0, 0)), sink: 0.05), seed: seed &+ 3)

        // Blockhouse 80 m out, slits (+X) on the pad, oil drums by the door.
        let bh = V2(-60, -55)
        scene.add(Blockhouse(), at: at(bh.x, bh.y, yaw: yawToward(bh, V2(0, 0)), sink: 0.1), seed: seed &+ 4)
        for k in 0..<4 {
            scene.add(OilDrum(), at: at(bh.x - 9 + Float(k % 2) * 0.65, bh.y + 6 + Float(k / 2) * 0.65, yaw: rng.float(0...360)), seed: seed &+ UInt64(40 + k))
        }

        // Runway along the south edge: 30 m tiles end to end, threshold bars at the west end.
        let rz: Float = -130
        for i in 0..<10 {
            let x = -150 + Float(i) * 30 + 15
            let tile = RunwaySegment().with { $0.threshold = i == 0 }
            scene.add(tile, at: place(x, rz, y: y(0, rz) - 0.28), seed: seed &+ UInt64(60 + i))
        }
        scene.add(Windsock(), at: at(40, rz + 26, yaw: 200), seed: seed &+ 5)

        // Course obstacles to the east.
        scene.add(RingGate(), at: at(70, -20, yaw: 90), seed: seed &+ 6)
        for k in 0..<6 {
            let a = Float(k) / 6 * 2 * .pi
            scene.add(Pylon(), at: at(30 + cos(a) * 16, 70 + sin(a) * 16), seed: seed &+ UInt64(70 + k))
        }
        scene.add(Pylon().with { $0.radius = 1.5; $0.height = 60 }, at: at(130, 40), seed: seed &+ 8)
        scene.add(GapWall().with { $0.width = 40; $0.height = 18; $0.thickness = 1.5; $0.slotCenter = 6; $0.slotWidth = 9 },
                  at: at(150, -40, yaw: 90), seed: seed &+ 9)
        scene.add(ObstacleBalloon().with { $0.radius = 4; $0.tetherLength = 24 }, at: at(100, 90), seed: seed &+ 10)
        for k in 0..<3 {
            scene.add(DebrisRock().with { $0.radius = Float(2 + k) }, at: at(170 + Float(k) * 14, 10 - Float(k) * 22, yaw: rng.float(0...360), lift: 18 + Float(k) * 9),
                      seed: seed &+ UInt64(90 + k))
        }

        // Desert scatter, kept off the pad, roads of travel and structures.
        let keepOut: [(V2, Float)] = [(V2(0, 0), 14), (vp, 7), (bh, 9), (V2(70, -20), 6), (V2(150, -40), 24), (V2(100, 90), 6), (V2(130, 40), 5)]
        func clear(_ p: V2) -> Bool { abs(p.y - rz) > 22 && !keepOut.contains { simd_length($0.0 - p) < $0.1 } }
        for (i, p) in Scatter.poisson(count: 26, outerRadius: 180, innerRadius: 20, minSpacing: 18, seed: seed &+ 11, accept: clear).enumerated() {
            scene.add(Boulder().with { $0.material = "rock.sandstone"; $0.size = V3(1.6, 1.0, 1.3) * rng.float(0.5...2.2) },
                      at: at(p.x, p.y, yaw: rng.float(0...360), sink: 0.05), seed: seed &+ UInt64(100 + i))
        }
        var shrubs = [[simd_float4x4]](repeating: [], count: 3)
        for p in Scatter.poisson(count: 60, outerRadius: 190, innerRadius: 12, minSpacing: 12, seed: seed &+ 12, accept: clear) {
            shrubs[rng.int(0...2)].append(SceneStrips.xform(p, y: y(p.x, p.y) - 0.05, &rng, scale: 0.25...0.45))
        }
        for v in 0..<3 { scene.field(Shrub(), seed: seed &+ UInt64(120 + v), transforms: shrubs[v], options: .trees) }
        // desert plants: agave and barrel cactus clumps
        let succulents = Scatter.poisson(count: 160, outerRadius: 160, innerRadius: 10, minSpacing: 5, seed: seed &+ 17, accept: clear)
        scene.field(Agave(), seed: seed &+ 18, transforms: succulents.enumerated().filter { $0.offset % 2 == 0 }.map {
            SceneStrips.xform($0.element, y: y($0.element.x, $0.element.y) - 0.05, &rng, scale: 0.5...1.0) }, options: .groundCover(cull: 90))
        scene.field(BarrelCactus(), seed: seed &+ 19, transforms: succulents.enumerated().filter { $0.offset % 2 == 1 }.map {
            SceneStrips.xform($0.element, y: y($0.element.x, $0.element.y) - 0.05, &rng, scale: 0.5...1.1) }, options: .groundCover(cull: 90))
        // distant buttes on the horizon
        for (i, b) in [(V2(-260, -40), V3(80, 40, 60)), (V2(40, 300), V3(120, 55, 70)), (V2(300, 120), V3(70, 35, 50))].enumerated() {
            scene.add(MesaRock().with { $0.size = b.1; $0.material = "rock.sandstone"; $0.bedHeight = b.1.y / 9; $0.ledgeDepth = b.1.y / 22; $0.lodDistances = [160, 380] },
                      at: place(b.0.x, b.0.y, y: -1), seed: seed &+ UInt64(150 + i))
        }
        let grass = Scatter.uniform(count: 4000, outerRadius: 80, seed: seed &+ 13) { p in
            clear(p) && simd_length(p - vp) > 4 && Noise.fbm(V3(p.x * 0.08, 0, p.y * 0.08), octaves: 3, seed: UInt32(truncatingIfNeeded: seed)) > 0
        }
        scene.field(DryGrass(), seed: seed &+ 14, transforms: grass.map { SceneStrips.xform($0, y: y($0.x, $0.y) - 0.02, &rng, scale: 0.5...1.1) },
                    options: .groundCover(cull: 45))
        scene.field(Pebbles(), seed: seed &+ 15, transforms: Scatter.uniform(count: 300, outerRadius: 60, seed: seed &+ 16, accept: clear).map {
            SceneStrips.xform($0, y: y($0.x, $0.y) - 0.01, &rng, scale: 0.8...1.4)
        }, options: .groundCover(cull: 35))

        // Camera on the platform deck at standing height, looking at the pad.
        let deck = y(vp.x, vp.y) - 0.05 + ViewingPlatform().deckHeight - 0.1
        let dir = simd_normalize(V2(0, 0) - vp)
        let eye = vp + dir * 1.2
        scene.camera = .init(eye: V3(eye.x, deck + 1.65, eye.y), target: V3(0, 6, 0), fov: 60)
        return scene
    }
}
