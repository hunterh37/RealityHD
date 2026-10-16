import simd
import Foundation
import RealityKit
import RealKit

/// Backcountry hunting basin, 150 m terrain: a rolling-hill meadow with a trodden game trail, a reedy lake on its
/// north edge, a rocky ridge with outcrops and scree behind, spruce, fir and aspen forest on the flanks, fallen
/// logs, and at the west meadow edge a ladder stand on an aspen, a ground blind, a deer feeder with a salt lick and
/// a trail camera strapped to a spruce above the trail. The camera stands in the meadow looking across it to the lake.
public struct TimberlineBackcountry: RealSceneBuilder {
    public static let id = "timberline-backcountry"
    public static let summary = "Backcountry hunting basin: spruce, fir and aspen forest on rolling hills, meadow, reedy lake, rocky ridge, game trail, ladder stand, blind, feeder, trail camera and salt lick."
    public static let tags = ["nature", "forest", "water", "rock", "hunting", "outdoor", "showcase"]
    public static let author = "realityhd"

    /// Terrain side length in meters.
    public var size: Float = 150
    /// Meadow center and half-extents (x, z) in meters.
    public var meadow = V2(2, -4)
    public var meadowSize = V2(28, 28)
    /// Lake center and half-extents (x, z) in meters.
    public var lake = V2(14, -24)
    public var lakeSize = V2(15, 9.5)
    /// Water surface height in meters.
    public var waterLevel: Float = -0.16
    /// Z of the ridge crest line in meters.
    public var ridgeZ: Float = -56
    public var trees = 430
    public var grass = 15000
    public init() {}

    public func build(seed: UInt64) -> RealScene {
        var scene = RealScene(name: Self.id)
        var rng = SeededRNG(seed: seed &+ 99)
        let ns = UInt32(truncatingIfNeeded: seed)
        let half = size / 2

        // Rolling relief from the TerrainHill height field; the meadow and lake are flattened out of it.
        let hills = TerrainHill().with { $0.size = 420; $0.peak = 13; $0.featureSize = 34; $0.border = 20 }
        func mDist(_ p: V2) -> Float {
            simd_length((p - meadow) / meadowSize) + Float(Noise.fbm(V3(p.x * 0.09, 3, p.y * 0.09), octaves: 3, seed: ns &+ 6)) * 0.16
        }
        func lakeR(_ p: V2) -> Float {
            simd_length((p - lake) / lakeSize) + Float(Noise.fbm(V3(p.x * 0.35, 2, p.y * 0.35), octaves: 3, seed: ns &+ 4)) * 0.25
        }
        func crest(_ x: Float) -> Float { ridgeZ + 4 * sin(x * 0.07 + 0.5) }
        func ridge(_ p: V2) -> Float {
            let d = (p.y - crest(p.x)) / 10
            let along = 1 - smoothstep(36, 58, abs(p.x))
            return 21 * exp(-d * d) * along * (0.85 + 0.3 * Float(Noise.fbm(V3(p.x * 0.07, 1, p.y * 0.07), octaves: 3, seed: ns &+ 9)))
        }
        func meadowH(_ p: V2) -> Float { 0.08 + 0.3 * Float(Noise.fbm(V3(p.x * 0.04, 4, p.y * 0.04), octaves: 3, seed: ns &+ 7)) }
        func height(_ p: V2) -> Float {
            let flat = 1 - smoothstep(0.85, 1.5, mDist(p))
            let rolling = hills.height(x: p.x, z: p.y, seed: seed &+ 5) * 0.7 + ridge(p)
            let land = meadowH(p) * flat + rolling * (1 - flat)
            let r = lakeR(p)
            let bowl = -1.1 * (1 - smoothstep(0.35, 1.15, r))
            let edge = 1 - smoothstep(half * 0.8, half * 0.99, max(abs(p.x), abs(p.y)))
            return (land * smoothstep(0.9, 1.6, r) + bowl) * edge - 0.15 * (1 - edge)
        }
        // Height cache on a 0.5 m grid for placement (the mesh samples `height` directly).
        let gN = Int(size / 0.5) + 1
        var grid = [Float](repeating: 0, count: gN * gN)
        for j in 0..<gN { for i in 0..<gN { grid[j * gN + i] = height(V2(Float(i) * 0.5 - half, Float(j) * 0.5 - half)) } }
        func y(_ p: V2) -> Float {
            let fx = (p.x + half) / 0.5, fz = (p.y + half) / 0.5
            let i = max(0, min(gN - 2, Int(fx.rounded(.down)))), j = max(0, min(gN - 2, Int(fz.rounded(.down))))
            let tx = max(0, min(1, fx - Float(i))), tz = max(0, min(1, fz - Float(j)))
            let a = grid[j * gN + i] * (1 - tx) + grid[j * gN + i + 1] * tx
            let b = grid[(j + 1) * gN + i] * (1 - tx) + grid[(j + 1) * gN + i + 1] * tx
            return a * (1 - tz) + b * tz
        }
        func wet(_ p: V2) -> Bool { y(p) < waterLevel + 0.04 }
        func slope(_ p: V2) -> Float { (abs(y(p + V2(1.5, 0)) - y(p - V2(1.5, 0))) + abs(y(p + V2(0, 1.5)) - y(p - V2(0, 1.5)))) / 3 }

        // Game trails: a main trail from the southwest forest across the meadow to the lake, a shore trail and an
        // eastern branch. Polylines are dense Catmull-Rom samples.
        func line(_ pts: [V2]) -> [V2] {
            catmull(pts.map { V3($0.x, 0, $0.y) }, per: 10).map { V2($0.x, $0.z) }
        }
        let main = line([V2(-36, 14), V2(-27, 5), V2(-18, 0), V2(-9, -5), V2(-2, -12), V2(5, -18), V2(10, -21.5)])
        let shore = line([V2(10, -21.5), V2(17, -20.5), V2(24, -21), V2(30, -24)])
        let east = line([V2(40, -8), V2(30, -10), V2(20, -15), V2(12, -20)])
        let trails = [main, shore, east]
        func trailDist(_ p: V2) -> Float {
            var best: Float = 1e9
            for t in trails {
                for k in 0..<(t.count - 1) {
                    let a = t[k], b = t[k + 1], ab = b - a
                    let u = max(0, min(1, simd_dot(p - a, ab) / max(simd_dot(ab, ab), 1e-6)))
                    best = min(best, simd_length(p - (a + ab * u)))
                }
            }
            return best
        }
        func wear(_ p: V2) -> Float {
            let n = Float(Noise.fbm(V3(p.x * 1.8, 5, p.y * 1.8), octaves: 3, seed: ns &+ 8)) * 0.4
            let path = 1 - smoothstep(0.22, 0.7, trailDist(p) + n * 0.6)
            let bank = 1 - smoothstep(0.02, 0.14, y(p) - waterLevel + n * 0.04)
            let feeder = 1 - smoothstep(0.8, 2.4, simd_length(p - V2(-14, -6.5)) + n)
            return max(max(path * 0.85, bank), feeder * 0.8)
        }

        var terrain = SceneStrips.ground(size: size, segments: 240, material: "ground.meadow-worn", hollows: 0.5, relief: 1) { height($0) }
        terrain.paintSplat { wear(V2($0.x, $0.z)) }
        scene.add(Model(name: "timberline-ground", surfaces: [terrain]))

        // Lake: water sheet, splat 1 at the waterline so the shallows show the bed.
        var water = Prim.terrain(size: lakeSize * 2.8, segments: 90, material: "water.pond") { _ in 0 }
        water.paintSplat { p in 1 - smoothstep(0.0, 0.5, waterLevel - height(V2(p.x, p.z) + lake)) }
        scene.add(Model(name: "lake", surfaces: [water]), at: Xform(translation: V3(lake.x, waterLevel, lake.y)))
        var shoreline: [V2] = []
        for i in 0..<720 {
            let a = Float(i) / 720 * 2 * .pi
            var lo: Float = 0.4, hi: Float = 2.2
            for _ in 0..<16 { let mid = (lo + hi) / 2; if height(lake + V2(cos(a), sin(a)) * lakeSize * mid) < waterLevel { lo = mid } else { hi = mid } }
            shoreline.append(lake + V2(cos(a), sin(a)) * lakeSize * lo)
        }

        // Backdrop hills beyond the ridge, sunk so their flat border hides under the far ground, with a conifer skirt.
        let back = TerrainHill().with { $0.size = 360; $0.peak = 70; $0.featureSize = 55; $0.border = 8; $0.rockSlope = 0.72; $0.material = "ground.alpine-rock" }
        let backZ: Float = -236
        scene.add(back, at: place(0, backZ, y: -0.4), seed: seed &+ 5)
        func backY(_ p: V2) -> Float { back.height(x: p.x, z: p.y - backZ, seed: seed &+ 5) - 0.4 }
        let skirt = Scatter.poisson(count: 360, outerRadius: 190, minSpacing: 6, seed: seed &+ 7) { p in
            guard p.y < -80, p.y > backZ - 70 else { return false }
            let h = backY(p)
            let g = abs(backY(p + V2(2, 0)) - h) + abs(backY(p + V2(0, 2)) - h)
            return h > 1 && h < 34 * (0.7 + 0.6 * Float(Noise.perlin(V3(p.x * 0.03, 0, p.y * 0.03)) + 0.5)) && g < 2.4
        }
        var skirtTrees: [[simd_float4x4]] = [[], []]
        for p in skirt { skirtTrees[rng.int(0...1)].append(SceneStrips.xform(p, y: backY(p) - 0.3, &rng, scale: 0.8...1.25)) }
        scene.field(SpruceTree(), seed: seed &+ 90, transforms: skirtTrees[0], options: .trees)
        scene.field(FirTree(), seed: seed &+ 91, transforms: skirtTrees[1], options: .trees)

        // Placement helpers.
        func at(_ p: V2, yaw: Float, sink: Float = 0.02) -> Xform { place(p.x, p.y, y: y(p) - sink, yaw: yaw) }
        func face(_ p: V2, _ target: V2) -> Float { let d = target - p; return atan2(d.x, d.y) * 180 / .pi }
        func xf(_ p: V2, scale: ClosedRange<Float>, sink: Float) -> simd_float4x4 { SceneStrips.xform(p, y: y(p) - sink, &rng, scale: scale) }

        // Hunt camp at the west meadow edge. Positions first so forest and ground cover can keep clear.
        let feederP = V2(-14, -6.5), lickP = V2(-11, -3.6)
        let blindP = V2(-23.5, -3.4)
        let standTree = V2(-25, -13.5)
        let camTree = V2(-28.5, 9.5)
        let keepClear: [(V2, Float)] = [(feederP, 2.4), (lickP, 1.2), (blindP, 2.4), (standTree, 3.2), (camTree, 1.4)]
        func clearOfCamp(_ p: V2) -> Bool { !keepClear.contains { simd_length($0.0 - p) < $0.1 } }

        // Forest: spruce, fir, aspen (gold and green groves) outside the meadow, off the lake, trails and bare rock.
        let spots = Scatter.poisson(count: trees, outerRadius: half - 3, minSpacing: 3.3, seed: seed &+ 1) { p in
            let h = y(p)
            let dens = Float(Noise.perlin(V3(p.x * 0.07, 0, p.y * 0.07), seed: ns &+ 12)) + 0.5
            return mDist(p) > 1.02 && lakeR(p) > 1.35 && trailDist(p) > 1.5 && clearOfCamp(p) && h < 14.5 * (0.75 + 0.5 * dens) && slope(p) < 0.9
                && dens > 0.18 && p.y > crest(p.x) - 6
        }
        var spruce = [[simd_float4x4]](repeating: [], count: 3), fir = [[simd_float4x4]](repeating: [], count: 3)
        var aspenGold = [[simd_float4x4]](repeating: [], count: 2), aspenGreen = [[simd_float4x4]](repeating: [], count: 2)
        var canopy: [V2] = []
        for p in spots {
            let h = y(p)
            let grove = Float(Noise.perlin(V3(p.x * 0.05, 8, p.y * 0.05), seed: ns &+ 13)) + 0.5
            let edge = mDist(p) < 1.25
            let r = rng.float()
            if (grove > 0.58 && r < 0.75) || (edge && r < 0.3) {
                if grove > 0.62 { aspenGold[rng.int(0...1)].append(xf(p, scale: 0.85...1.15, sink: 0.08)) }
                else { aspenGreen[rng.int(0...1)].append(xf(p, scale: 0.85...1.15, sink: 0.08)) }
            } else if h > 6 || r < 0.55 { spruce[rng.int(0...2)].append(xf(p, scale: 0.8...1.25, sink: 0.1)) }
            else { fir[rng.int(0...2)].append(xf(p, scale: 0.8...1.2, sink: 0.1)) }
            canopy.append(p)
        }
        for v in 0..<3 {
            scene.field(SpruceTree(), seed: seed &+ UInt64(10 + v), transforms: spruce[v], options: .trees)
            scene.field(FirTree(), seed: seed &+ UInt64(13 + v), transforms: fir[v], options: .trees)
        }
        for v in 0..<2 {
            scene.field(AspenTree().with { $0.autumn = 0.9 }, seed: seed &+ UInt64(16 + v), transforms: aspenGold[v], options: .trees)
            scene.field(AspenTree(), seed: seed &+ UInt64(18 + v), transforms: aspenGreen[v], options: .trees)
        }

        // Hunt props. Stand and trail camera need their host trees as singles.
        scene.add(DeerFeeder(), at: at(feederP, yaw: 15, sink: 0.0), seed: seed &+ 120)
        scene.add(SaltLick(), at: at(lickP, yaw: 70, sink: 0.0), seed: seed &+ 121)
        scene.add(GroundBlind(), at: at(blindP, yaw: face(blindP, feederP) + 8, sink: 0.01), seed: seed &+ 122)
        // Ladder stand: aspen trunk behind the platform notch, ladder foot toward the meadow.
        let standBounds = LadderTreeStand().build(seed: seed &+ 123).levels[0].bounds
        let standFace = face(standTree, feederP)
        let fwd = V2(sin(standFace * .pi / 180), cos(standFace * .pi / 180))
        let standP = standTree + fwd * (-standBounds.min.z + 0.1 - 0.0)
        scene.add(AspenTree().with { $0.height = 16 }, at: at(standTree, yaw: 30, sink: 0.08), seed: seed &+ 124)
        scene.add(LadderTreeStand(), at: at(standP, yaw: standFace, sink: 0.0), seed: seed &+ 123)
        // Trail camera on a spruce beside the trail, facing it at 1.1 m.
        let toTrail = simd_normalize(V2(-26.5, 4.8) - camTree)
        scene.add(SpruceTree().with { $0.height = 13 }, at: at(camTree, yaw: 80, sink: 0.1), seed: seed &+ 125)
        let camFace = face(camTree, camTree + toTrail)
        let camP = camTree + toTrail * 0.205
        scene.add(TrailCamera(), at: Xform(translation: V3(camP.x, y(camP) + 1.1, camP.y), rotation: simd_quatf(degrees: camFace, axis: .up)), seed: seed &+ 126)

        // Rocky ridge: cliff sections where the slope steepens, outcrops on the crest, scree fans, boulders.
        let cliff = CliffFace().with { $0.height = 6; $0.depth = 2.4; $0.material = "rock.granite-bare"; $0.endTaper = 0; $0.endBulge = 0 }.build(seed: seed &+ 2)
        var cx: Float = -30
        while cx < 32 {
            var zz = ridgeZ + 14
            while zz > ridgeZ - 6 && y(V2(cx, zz)) < 11 { zz -= 0.25 }
            let c = V2(cx, zz)
            let lo = stride(from: -3, through: 3, by: 1).map { (d: Float) in y(V2(c.x + d, c.y + 1.2)) }.min() ?? 0
            scene.singles.append(.init(asset: cliff, at: Xform(translation: V3(c.x, lo - 0.3, c.y), rotation: simd_quatf(degrees: rng.float(-10...10), axis: .up))))
            cx += 6
        }
        for k in 0..<9 {
            let x = -40 + Float(k) * 9.5 + rng.float(-2...2)
            let p = V2(x, crest(x) + rng.float(-3...3))
            let s = V3(rng.float(5...8), rng.float(3.5...5.5), rng.float(3.5...5))
            scene.add(RockOutcrop().with { $0.size = s }, at: place(p.x, p.y, y: y(p) - 0.4, yaw: rng.float(-30...30)), seed: seed &+ UInt64(130 + k))
        }
        for k in 0..<7 {
            let x = -33 + Float(k) * 11 + rng.float(-2...2)
            let p = V2(x, crest(x) + rng.float(7...11))
            scene.add(ScreePile().with { $0.footprint = V2(rng.float(6...9), rng.float(4.5...6)); $0.height = rng.float(1.6...2.6); $0.material = "rock.granite-bare" },
                      at: place(p.x, p.y, y: y(p) - 0.15, yaw: rng.float(-20...20)), seed: seed &+ UInt64(145 + k))
        }
        var mossy: [simd_float4x4] = []
        let rocks = Scatter.poisson(count: 26, outerRadius: 46, minSpacing: 5, seed: seed &+ 40) { p in
            !wet(p) && lakeR(p) > 1.0 && trailDist(p) > 1.3 && clearOfCamp(p) && (mDist(p) > 0.85 || lakeR(p) < 1.9) && p.y > -42
        }
        for (i, p) in rocks.enumerated() {
            let k = rng.float(0.6...1.5), yaw = rng.float(0...360)
            if i % 2 == 0 { scene.add(MossyRock().with { $0.size = V3(1.3, 0.8, 1.1) * k }, at: place(p.x, p.y, y: y(p) - 0.05, yaw: yaw), seed: seed &+ UInt64(160 + i)) }
            else { scene.add(Boulder().with { $0.size = V3(1.6, 0.95, 1.3) * k }, at: place(p.x, p.y, y: y(p) - 0.05, yaw: yaw), seed: seed &+ UInt64(160 + i)) }
            for _ in 0..<3 { let a = rng.float(0...6.28); mossy.append(xf(p + V2(cos(a), sin(a)) * (0.8 * k + rng.float(0...0.4)), scale: 0.7...1.4, sink: 0.02)) }
        }
        scene.field(MossMound(), seed: seed &+ 190, transforms: mossy, options: .groundCover(cull: 40))

        // Old wood: fallen logs on the meadow fringe and in the forest, a snag, a brush pile.
        let logs: [(V2, Float, Float, Float)] = [(V2(-18, 8), 25, 3.6, 0.4), (V2(22, 6), -50, 3.0, 0.36), (V2(-3, -33), 80, 3.4, 0.38),
                                                  (V2(30, -14), 20, 2.6, 0.3), (V2(-31, -2), -20, 4.0, 0.42), (V2(-14, -26), 60, 3.0, 0.34)]
        for (i, l) in logs.enumerated() {
            scene.add(FallenLog().with { $0.length = l.2; $0.buttDiameter = l.3; $0.topDiameter = l.3 * 0.6 }, at: at(l.0, yaw: l.1, sink: 0.03), seed: seed &+ UInt64(200 + i))
        }
        scene.add(DeadSnag(), at: at(V2(-30, -20), yaw: 40, sink: 0.1), seed: seed &+ 210)
        scene.add(BrushPile(), at: at(V2(-28, -9), yaw: 110, sink: 0.04), seed: seed &+ 211)

        // Lake shore: wet stones at the waterline, reeds and cattails on the far and east banks.
        for k in 0..<7 {
            let p = shoreline[(k * 101 + 30) % shoreline.count]
            scene.add(RiverStones().with { $0.wet = true; $0.radius = 0.7 }, at: at(p, yaw: rng.float(0...360), sink: 0.03), seed: seed &+ UInt64(220 + k))
        }
        var reeds: [simd_float4x4] = [], reedsB: [simd_float4x4] = []
        for (i, p) in shoreline.enumerated() where i % 3 == 0 {
            let a = Float(i) / Float(shoreline.count) * 2 * .pi
            if sin(a) > 0.55 && cos(a) < 0.6 { continue }                       // keep the open south landing
            if Float(Noise.perlin(V3(p.x * 0.4, 9, p.y * 0.4), seed: ns)) < -0.18 { continue }
            let q = p + simd_normalize(p - lake) * rng.float(-0.6...0.4)
            if trailDist(q) < 1.0 { continue }
            let t = xf(q, scale: 0.75...1.2, sink: 0.05)
            if i % 2 == 0 { reeds.append(t) } else { reedsB.append(t) }
        }
        scene.field(ReedClump(), seed: seed &+ 230, transforms: reeds, options: .trees)
        scene.field(ReedClump().with { $0.height = 1.4 }, seed: seed &+ 231, transforms: reedsB, options: .trees)

        // Ground cover. Meadow grass thick near the camera, cards farther out; flowers in drifts.
        let cover = RealInstancing.Options.groundCover(cull: 34)
        let eye = V2(-6, 14)
        let grassSpots = Scatter.uniform(count: grass, outerRadius: 62, seed: seed &+ 70) { p in
            guard !wet(p), wear(p) < 0.25 else { return false }
            let m = mDist(p)
            let density = Float(Noise.perlin(V3(p.x * 0.3, 1, p.y * 0.3))) * 0.5 + 0.5
            return density < (m < 1 ? 0.95 : 0.5) && (keepClear.allSatisfy { simd_length($0.0 - p) > $0.1 * 0.6 })
        }
        let near = grassSpots.filter { simd_length($0 - eye) < 15 }
        let far = grassSpots.filter { simd_length($0 - eye) >= 15 }
        let half2 = near.count / 2
        scene.field(GrassTuft(), seed: seed &+ 71, transforms: near[..<half2].map { xf($0, scale: 0.7...1.3, sink: 0.02) }, options: cover)
        scene.field(GrassTuft().with { $0.height = 0.35 }, seed: seed &+ 72, transforms: near[half2...].map { xf($0, scale: 0.7...1.3, sink: 0.02) }, options: cover)
        scene.field(GrassClump().with { $0.height = 0.32; $0.width = 0.4 }, seed: seed &+ 73, transforms: far.map { xf($0, scale: 0.7...1.2, sink: 0.02) }, options: cover)
        let tall = Scatter.uniform(count: 1400, outerRadius: 55, seed: seed &+ 74) { p in
            let m = mDist(p), r = lakeR(p)
            return !wet(p) && wear(p) < 0.12 && ((r > 1.0 && r < 1.6) || (m > 0.8 && m < 1.25)) && clearOfCamp(p)
        }
        scene.field(TallGrass(), seed: seed &+ 75, transforms: tall.map { xf($0, scale: 0.8...1.25, sink: 0.02) }, options: cover)
        let flowers = Scatter.uniform(count: 520, outerRadius: 36, seed: seed &+ 76) { p in
            !wet(p) && mDist(p) < 0.95 && wear(p) < 0.1 && Float(Noise.perlin(V3(p.x * 0.22, 4, p.y * 0.22), seed: ns &+ 1)) > 0.1
        }
        scene.field(MeadowFlowers(), seed: seed &+ 77, transforms: flowers.map { xf($0, scale: 0.8...1.2, sink: 0.01) }, options: cover)
        let shrubSpots = Scatter.poisson(count: 70, outerRadius: 50, minSpacing: 3.5, seed: seed &+ 78) { p in
            let m = mDist(p)
            return m > 0.92 && m < 1.3 && lakeR(p) > 1.3 && trailDist(p) > 1.2 && clearOfCamp(p) && slope(p) < 0.7
        }
        scene.field(Shrub().with { $0.height = 1.2 }, seed: seed &+ 79, transforms: shrubSpots.map { xf($0, scale: 0.7...1.3, sink: 0.08) }, options: .trees)

        // Under the trees: ferns, litter, mushrooms by the logs.
        let shade = Scatter.uniform(count: 1500, outerRadius: 62, seed: seed &+ 80) { p in
            mDist(p) > 1.08 && lakeR(p) > 1.4 && trailDist(p) > 0.9 && clearOfCamp(p) && Float(Noise.perlin(V3(p.x * 0.2, 6, p.y * 0.2), seed: ns &+ 2)) > -0.1 && slope(p) < 1.0
        }
        scene.field(Fern(), seed: seed &+ 81, transforms: shade.filter { _ in rng.float() < 0.55 }.map { xf($0, scale: 0.7...1.2, sink: 0.02) }, options: cover)
        let litter = Scatter.uniform(count: 600, outerRadius: 60, seed: seed &+ 82) { p in mDist(p) > 0.98 && lakeR(p) > 1.3 && clearOfCamp(p) }
        scene.field(LeafLitter(), seed: seed &+ 83, transforms: litter.map { xf($0, scale: 0.8...1.4, sink: 0.0) }, options: cover)
        var shrooms: [simd_float4x4] = []
        for l in logs where rng.float() < 0.9 { shrooms.append(xf(l.0 + V2(0.4, 0.5), scale: 0.9...1.2, sink: 0)) }
        for c in canopy.prefix(30) where rng.float() < 0.5 {
            let a = rng.float(0...6.28)
            shrooms.append(xf(c + V2(cos(a), sin(a)) * rng.float(0.5...1.1), scale: 0.8...1.2, sink: 0.0))
        }
        scene.field(MushroomCluster(), seed: seed &+ 84, transforms: shrooms, options: cover)

        scene.farGround = "ground.forest"
        // Hero camera: meadow-edge eye height looking across grass to the whole lake and its far bank.
        let camE = V2(2, -8)
        scene.camera = .init(eye: V3(camE.x, y(camE) + 2.6, camE.y), target: V3(lake.x, waterLevel - 0.3, lake.y), fov: 68)
        scene.spots = [
            .init("hunt camp", eye: V3(-8, y(V2(-8, 4)) + 1.65, 4), target: V3(-20, y(blindP) + 1.4, -5)),
            .init("lake", eye: V3(6, y(V2(6, -10)) + 1.65, -10), target: V3(16, 0.3, -26)),
            .init("ridge", eye: V3(0, y(V2(0, -30)) + 1.65, -30), target: V3(0, 8, ridgeZ)),
        ]
        return scene
    }
}
