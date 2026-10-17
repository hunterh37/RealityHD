import simd
import Foundation
import RealityKit
import RealKit

/// Outdoor archery range, 360 m terrain. A shelter and concrete pad on the shooting line (z = 0) with two bow tables
/// and a quiver, five lanes of mown turf running to targets at 10, 20, 30 and 50 yards and a foam deer, distance
/// signs, wind flags, an earth berm with stacked hay bales behind the targets, meadow with wildflowers, a gravel path
/// to a split-rail fence, and conifer and aspen tree lines beyond 75 m on low hills. Flat y = 0 inside 70 m.
/// The camera stands on the shooting line looking down the lanes.
public struct ArcheryRange: RealSceneBuilder {
    public static let id = "archery-range"
    public static let summary = "Outdoor archery range: shelter and pad, bow tables, quiver, lanes to 10-50 yard targets and a foam deer, signs, wind flags, earth berm with hay bales, meadow, gravel path, split-rail fence, tree line."
    public static let tags = ["outdoor", "sports", "nature", "showcase"]
    public static let author = "hunter"

    /// Terrain side length in meters.
    public var size: Float = 360
    /// Radius around the origin that is exactly y = 0.
    public var playRadius: Float = 70
    public var grass = 16000
    public var flowers = 1500
    public var trees = 320
    public init() {}

    static let lanes: [Float] = [-4.8, -2.4, 0, 2.4, 4.8]

    public func build(seed: UInt64) -> RealScene {
        var scene = RealScene(name: Self.id)
        var rng = SeededRNG(seed: seed &+ 99)
        let ns = UInt32(truncatingIfNeeded: seed)
        let pr = playRadius

        // Ground: exactly flat inside the play radius, low rolling hills beyond 75 m.
        func height(_ p: V2) -> Float {
            let r = simd_length(p)
            let t = smoothstep(pr + 5, pr + 70, r)
            if t <= 0 { return 0 }
            let n = Float(Noise.fbm(V3(p.x * 0.012, 2, p.y * 0.012), octaves: 4, seed: ns &+ 3)) + 0.5
            return t * (1.5 + 16 * max(0, n))
        }
        var terrain = SceneStrips.ground(size: size, segments: 300, material: "turf.worn", hollows: 0.35, relief: 1) { height($0) }
        terrain.paintSplat { p in
            // Worn earth patch in front of the pad and at the target line.
            let d = simd_length(V2(p.x, p.z) - V2(0, 5.5))
            return 0.25 * (1 - smoothstep(3, 7, d))
        }
        scene.add(Model(name: "range-ground", surfaces: [terrain]))

        // Mown lane strips, 1.6 m wide, from the pad to 3 m past each target.
        let targetZ: [Float] = [-9.14, -18.29, -27.43, -45.72, -18.29]
        var strips: [Surface] = []
        for (i, lx) in Self.lanes.enumerated() {
            let end = targetZ[i] - 3
            strips.append(SceneStrips.ribbon(material: "turf.ballpark", z0: 3.7, z1: end, width: 1.6, along: 40, across: 2,
                                             cx: { _ in lx }, y: { _, _ in 0.012 }))
        }
        // Mown apron in front of the pad.
        strips.append(SceneStrips.ribbon(material: "turf.ballpark", z0: 3.7, z1: -0.4, width: 13.6, along: 4, across: 4,
                                         cx: { _ in 0 }, y: { _, _ in 0.01 }))
        scene.add(Model(name: "mown-lanes", surfaces: strips))

        // Gravel path from the pad's rear to the fence.
        func pathX(_ z: Float) -> Float { 1.0 + 1.6 * sin((z - 3.7) * 0.22) }
        let fenceZ: Float = 17
        let gravel = SceneStrips.ribbon(material: "ground.gravel", z0: 3.9, z1: fenceZ + 4, width: 1.5, along: 60, across: 4,
                                        cx: pathX, y: { _, _ in 0.016 })
        scene.add(Model(name: "gravel-path", surfaces: [gravel]))

        // Earth berm, 3 m high across z = -52...-58, x -30...30. Separate mesh so the ground stays flat.
        func bermH(_ p: V2) -> Float {
            let z = p.y - (-55)                              // local to berm center
            let across = smoothstep(-3, -1, z) * (1 - smoothstep(1, 3, z))   // z in -52...-58 slopes, plateau between
            let ends = 1 - smoothstep(26, 30, abs(p.x))
            let wob = 1 + 0.06 * Float(Noise.fbm(V3(p.x * 0.15, 1, p.y * 0.4), octaves: 3, seed: ns &+ 5))
            return 3 * across * ends * wob
        }
        scene.add(Model(name: "berm", surfaces: [
            Prim.terrain(size: V2(64, 12), segments: 160, material: "turf.worn") { bermH($0 + V2(0, -55)) }
        ]), at: Xform(translation: V3(0, 0.005, -55)))

        // Props.
        scene.add(RangeShelter(), at: place(0, 1.765, y: -0.08, yaw: 0), seed: seed &+ 1)
        scene.add(BowTable(), at: place(1.9, 0.9, y: 0, yaw: 0), seed: seed &+ 2)
        scene.add(BowTable(), at: place(4.6, 0.9, y: 0, yaw: 0), seed: seed &+ 3)
        scene.add(ArrowQuiver(), at: place(3.25, 1.0, y: 0, yaw: 0), seed: seed &+ 4)
        for (i, lx) in Self.lanes.enumerated() where i != 4 {
            scene.add(ArcheryTarget(), at: place(lx, targetZ[i] - 0.288, y: 0, yaw: 0), seed: seed &+ UInt64(10 + i))
        }
        scene.add(FoamDeerTarget(), at: place(4.8, -18.29, y: 0, yaw: 180), seed: seed &+ 20)
        let yards = [10, 20, 30, 50, 20]
        for (i, lx) in Self.lanes.enumerated() {
            scene.add(DistanceSign().with { $0.yards = yards[i] }, at: place(lx - 1.0, -3, y: 0, yaw: 0), seed: seed &+ UInt64(30 + i))
        }
        for (k, f) in [V2(-3.6, -12), V2(3.6, -30), V2(-3.6, -48)].enumerated() {
            scene.add(WindFlag(), at: place(f.x + 0.346, f.y, y: 0, yaw: 0), seed: seed &+ UInt64(40 + k))
        }

        // Hay bales stacked at the berm toe: three staggered courses across the full width, double thickness behind the lanes.
        var bales: [simd_float4x4] = []
        func bale(_ x: Float, _ z: Float, _ course: Int) {
            let jitter = V2(rng.float(-0.015...0.015), rng.float(-0.02...0.02))
            let q = simd_quatf(degrees: rng.float(-1.5...1.5), axis: .up)
            bales.append(Xform(translation: V3(x + jitter.x, 0.18 + 0.36 * Float(course) - 0.005, z + jitter.y), rotation: q).matrix)
        }
        for course in 0..<3 {
            var x: Float = -29.5 + (course % 2 == 0 ? 0 : 0.46)
            while x < 29.6 { bale(x, -51.6, course); x += 0.92 }
        }
        for course in 0..<3 {
            var x: Float = -8.0 + (course % 2 == 0 ? 0.46 : 0)
            while x < 8.1 { bale(x, -51.1, course); x += 0.92 }
        }
        scene.field(SquareHayBale(), seed: seed &+ 50, transforms: bales, options: .trees)

        // Split-rail fence across the site edge with a gap for the path.
        var fence: [simd_float4x4] = []
        for side in [-1, 1] as [Float] {
            var x: Float = side * 1.6 + pathX(fenceZ)
            while abs(x) < 24 {
                fence.append(Xform(translation: V3(x + side * 1.0, 0, fenceZ), rotation: simd_quatf(degrees: 90, axis: .up)).matrix)
                x += side * 2.0
            }
        }
        scene.field(SplitRailFence(), seed: seed &+ 60, transforms: fence, options: .trees)

        // Keep-clear test: pad, lanes, path.
        func onLane(_ p: V2, pad: Float) -> Bool {
            if p.y < 4.5 && p.y > targetZ.min()! - 4 && Self.lanes.contains(where: { abs(p.x - $0) < 0.8 + pad }) { return true }
            if abs(p.x) < 6.8 + pad && p.y > -1 && p.y < 4.6 { return true }
            if p.y > 3 && p.y < fenceZ + 5 && abs(p.x - pathX(p.y)) < 0.75 + pad { return true }
            return false
        }
        func busy(_ p: V2) -> Bool { onLane(p, pad: 0.15) || (p.y < -50 && p.y > -59 && abs(p.x) < 31) }

        // Ground cover: meadow grass thick near the range, flowers in drifts, all outside the lanes, pad and berm.
        let cover = RealInstancing.Options.groundCover(cull: 38)
        func xf(_ p: V2, _ s: ClosedRange<Float>, sink: Float = 0.02) -> simd_float4x4 { SceneStrips.xform(p, y: height(p) - sink, &rng, scale: s) }
        let spots = Scatter.uniform(count: grass, outerRadius: 62, seed: seed &+ 70) { p in
            guard !busy(p) else { return false }
            let d = Float(Noise.perlin(V3(p.x * 0.25, 1, p.y * 0.25), seed: ns &+ 1)) * 0.5 + 0.5
            return d < 0.95
        }
        let near = spots.filter { simd_length($0) < 30 }, far = spots.filter { simd_length($0) >= 30 }
        scene.field(GrassTuft().with { $0.height = 0.3 }, seed: seed &+ 71, transforms: near.map { xf($0, 0.7...1.3) }, options: cover)
        scene.field(GrassClump().with { $0.height = 0.35; $0.width = 0.4 }, seed: seed &+ 72, transforms: far.map { xf($0, 0.7...1.3) }, options: cover)
        let tall = Scatter.uniform(count: 1800, outerRadius: 66, seed: seed &+ 73) { p in
            !busy(p) && simd_length(p) > 9 && (abs(p.x) > 9 || p.y < -56 || p.y > 8)
        }
        scene.field(TallGrass(), seed: seed &+ 74, transforms: tall.map { xf($0, 0.8...1.3) }, options: cover)
        let blooms = Scatter.uniform(count: flowers, outerRadius: 68, seed: seed &+ 75) { p in
            !busy(p) && simd_length(p) > 8 && Float(Noise.perlin(V3(p.x * 0.12, 4, p.y * 0.12), seed: ns &+ 2)) > 0.0
        }
        scene.field(MeadowFlowers(), seed: seed &+ 76, transforms: blooms.map { xf($0, 0.8...1.25, sink: 0.01) }, options: cover)

        // Tree line beyond 75 m: conifers and aspens on the low hills.
        let tspots = Scatter.poisson(count: trees, outerRadius: 160, innerRadius: 76, minSpacing: 6, seed: seed &+ 1) { p in
            Float(Noise.perlin(V3(p.x * 0.03, 0, p.y * 0.03), seed: ns &+ 12)) > -0.25
        }
        var spruce: [[simd_float4x4]] = [[], []], fir: [[simd_float4x4]] = [[], []], aspen: [[simd_float4x4]] = [[], []]
        for p in tspots {
            let t = xf(p, 0.9...1.4, sink: 0.1)
            let r = rng.float()
            if r < 0.4 { spruce[rng.int(0...1)].append(t) } else if r < 0.7 { fir[rng.int(0...1)].append(t) } else { aspen[rng.int(0...1)].append(t) }
        }
        for v in 0..<2 {
            scene.field(SpruceTree(), seed: seed &+ UInt64(80 + v), transforms: spruce[v], options: .trees)
            scene.field(FirTree(), seed: seed &+ UInt64(82 + v), transforms: fir[v], options: .trees)
            scene.field(AspenTree(), seed: seed &+ UInt64(84 + v), transforms: aspen[v], options: .trees)
        }

        scene.farGround = "ground.meadow"
        // Standing on the shooting line looking down the lanes.
        scene.camera = .init(eye: V3(0.6, 1.65, -0.45), target: V3(0.1, 1.2, -30), fov: 70)
        scene.spots = [
            .init("table", eye: V3(3.25, 1.65, 2.6), target: V3(3.25, 0.9, 0.9)),
            .init("berm", eye: V3(0, 1.65, -38), target: V3(0, 1.5, -55)),
            .init("path", eye: V3(1, 1.65, 12), target: V3(1, 1.2, 4)),
        ]
        return scene
    }
}
