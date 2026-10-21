import simd
import Foundation
import RealityKit
import RealKit
import RealCore

/// Alpine downhill racing road: a 400 m chain of `mountain-road-tile` pieces with three bends between
/// straights, a spruce, larch and Scots pine forest on both slopes, granite outcrops and cliff faces on the
/// uphill side, hay bales on the outside of each bend and traffic cones before it. The camera stands at the
/// start line looking down the road in the afternoon sun.
public struct MountainDownhillRoad: RealSceneBuilder {
    public static let id = "mountain-downhill-road"
    public static let summary = "Alpine downhill road: chained mountain road tiles, spruce, larch, Scots pine, rock outcrops, cliffs, hay bales at bends, cones, afternoon sun."
    public static let tags = ["road", "outdoor", "sports", "rock", "tree", "conifer"]
    public static let author = "hunter"

    /// Signed bend radius per 40 m tile in meters (0 = straight, positive = right).
    public var bends: [Float] = [0, 0, 110, 110, 0, -85, -85, 0, 90, 0]
    /// Side of the detailed ground patch in meters.
    public var size: Float = 560
    public init() {}

    public func build(seed: UInt64) -> RealScene {
        var scene = RealScene(name: Self.id)
        scene.farGround = "ground.alpine"
        scene.lighting = .init(sky: .afternoon)
        var rng = SeededRNG(seed: seed &+ 99)
        let ns = UInt32(truncatingIfNeeded: seed)
        let tile = MountainRoadTile()
        let L = tile.length, T = tile.roadTop, hw = tile.width / 2

        // Start poses and the centerline polyline (2 m samples) for lateral distance queries.
        var starts: [MountainRoadTile.Pose] = []
        var pose = MountainRoadTile.Pose(p: V2(0, 0), heading: 0)
        var line: [V2] = [], lineDir: [V2] = []
        for r in bends {
            starts.append(pose)
            for k in 0..<20 { let q = pose.advanced(Float(k) * L / 20, radius: r); line.append(q.p); lineDir.append(V2(cos(q.heading), sin(q.heading))) }
            pose = pose.advanced(L, radius: r)
        }
        line.append(pose.p); lineDir.append(V2(cos(pose.heading), sin(pose.heading)))
        let centre = line[line.count / 2]
        /// Signed distance from the centerline, positive on the drop side (right of travel).
        func lateral(_ p: V2) -> Float {
            var best: Float = .greatestFiniteMagnitude, sign: Float = 1
            for (i, c) in line.enumerated() {
                let d = p - c, dist = simd_length(d)
                if dist < best { best = dist; sign = (lineDir[i].x * d.y - lineDir[i].y * d.x) >= 0 ? 1 : -1 }
            }
            return best * sign
        }
        let half = size / 2
        func height(_ p: V2) -> Float {
            let d = lateral(p)
            let edge = 1 - smoothstep(0.72, 0.98, max(abs(p.x - centre.x), abs(p.y - centre.y)) / half)
            var h: Float
            if d >= 0 {
                h = -26 * smoothstep(8.2, 70, d) * (1 - smoothstep(160, 260, d))
                h += 3 * Noise.fbm(V3(p.x * 0.03, 0, p.y * 0.03), octaves: 3, seed: ns) * smoothstep(10, 40, d)
            } else {
                let u = -d
                h = u < 13.2 ? (T + tile.cutHeight) * smoothstep(5, 13.2, u) : (T + tile.cutHeight) + 0.62 * (u - 13.2)
                h = min(h, 85)
                h += 9 * Noise.fbm(V3(p.x * 0.02, 0, p.y * 0.02), octaves: 4, seed: ns &+ 1) * smoothstep(13, 45, u)
            }
            return h * edge - 0.25 * (1 - edge)
        }
        scene.add(Model(name: "mountain-ground", surfaces: [SceneStrips.ground(size: size, segments: 220, material: "ground.alpine", relief: 1.5) {
            height(V2($0.x + centre.x, $0.y + centre.y))
        }]), at: Xform(translation: V3(centre.x, 0, centre.y)))

        // Road tiles.
        for (i, r) in bends.enumerated() {
            scene.add(tile.with { $0.curvature = r }, at: starts[i].tilePlacement(length: L, radius: r, y: 0), seed: seed &+ UInt64(i))
        }
        /// World position and heading at `s` m along tile `i`, `u` m right of the centerline.
        func at(_ i: Int, _ s: Float, _ u: Float) -> (p: V2, heading: Float) {
            let q = starts[i].advanced(s, radius: bends[i])
            return (q.p + V2(-sin(q.heading), cos(q.heading)) * u, q.heading)
        }
        func yaw(_ h: Float) -> Float { -h * 180 / .pi }

        // Rock outcrops and cliff faces on the uphill slope.
        for i in 0..<bends.count {
            let o = at(i, rng.float(6...34), -rng.float(15...26))
            scene.add(RockOutcrop().with { $0.size = V3(3.2, 2.2, 2.4) * rng.float(1.5...2.6) },
                      at: place(o.p.x, o.p.y, y: height(o.p) - 0.3, yaw: yaw(o.heading) + rng.float(-30...30)), seed: seed &+ UInt64(40 + i))
        }
        for i in stride(from: 1, to: bends.count, by: 2) {
            let c = at(i, 20, -rng.float(34...48))
            scene.add(CliffFace().with { $0.length = 28; $0.height = 16; $0.depth = 5; $0.bedHeight = 1.1; $0.ledgeDepth = 0.5; $0.material = "rock.granite" },
                      at: place(c.p.x, c.p.y, y: height(c.p) - 1, yaw: yaw(c.heading) - 90), seed: seed &+ UInt64(60 + i))
        }

        // Forest: spruce, larch and Scots pine; denser on the uphill side, open toward the drop.
        func lateralOK(_ p: V2, _ lo: Float, _ hi: Float) -> Bool { let d = lateral(p); return d > lo && d < hi }
        func forest<A: RealAsset>(_ a: A, count: Int, spacing: Float, lo: Float, hi: Float, scale: ClosedRange<Float>, _ s: UInt64) {
            let pts = Scatter.poisson(count: count, outerRadius: half * 0.82, minSpacing: spacing, seed: seed &+ s) { p in
                lateralOK(V2(p.x + centre.x, p.y + centre.y), lo, hi)
            }
            var buckets = [[simd_float4x4]](repeating: [], count: 2)
            for (k, q) in pts.enumerated() {
                let w = V2(q.x + centre.x, q.y + centre.y)
                buckets[k % 2].append(place(w.x, w.y, y: height(w) - 0.1, yaw: rng.float(0...360), scale: rng.float(scale)).matrix)
            }
            for v in 0..<2 { scene.field(a, seed: seed &+ s &+ UInt64(v), transforms: buckets[v], options: .trees) }
        }
        forest(SpruceTree(), count: 260, spacing: 7, lo: -150, hi: -13.5, scale: 0.8...1.35, 100)
        forest(LarchTree(), count: 120, spacing: 9, lo: -140, hi: -14, scale: 0.8...1.25, 110)
        forest(ScotsPine(), count: 90, spacing: 10, lo: -120, hi: -15, scale: 0.8...1.2, 120)
        forest(SpruceTree(), count: 110, spacing: 8, lo: 11, hi: 90, scale: 0.7...1.2, 130)
        forest(ScotsPine(), count: 40, spacing: 12, lo: 11, hi: 80, scale: 0.7...1.1, 140)

        // Hay bales on the outside of each bend (two high, ahead of the apex) and cones before it.
        var bales: [simd_float4x4] = [], cones: [simd_float4x4] = []
        for (i, r) in bends.enumerated() where r != 0 {
            let outer: Float = r > 0 ? -(hw + 0.5) : (hw + 0.45)
            var s: Float = 6
            while s <= L - 6 {
                let a = at(i, s, outer)
                for layer in 0..<2 {
                    bales.append(place(a.p.x, a.p.y, y: T - 0.03 + 0.46 * Float(layer), yaw: yaw(a.heading) + rng.float(-3...3)).matrix)
                }
                s += 0.95
            }
            // Cones along both edge lines through the last 12 m of the previous tile.
            if i > 0 {
                for k in 0..<4 { for side: Float in [-1, 1] {
                    let c = at(i - 1, L - 12 + Float(k) * 3.5, side * (hw - 0.65 + Float(k) * 0.18 * (side == (r > 0 ? -1 : 1) ? 1 : 0)))
                    cones.append(place(c.p.x, c.p.y, y: T + 0.01, yaw: rng.float(0...360)).matrix)
                }}
            }
        }
        scene.field(SquareHayBale(), seed: seed &+ 200, transforms: bales, options: .groundCover(cull: 120))
        scene.field(TrafficCone(), seed: seed &+ 201, transforms: cones, options: .groundCover(cull: 120))

        // Start line: rider eye height, 1.7 m, looking down the first straights into the first bend.
        let e = at(0, 4, 1.0), tg = at(3, 20, -1.0)
        scene.camera = .init(eye: V3(e.p.x, T + 1.7, e.p.y), target: V3(tg.p.x, T + 1.2, tg.p.y), fov: 62)
        return scene
    }
}
