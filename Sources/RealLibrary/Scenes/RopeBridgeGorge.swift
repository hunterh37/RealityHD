import simd
import Foundation
import RealityKit
import RealKit

/// A hemp and plank rope bridge 42 m across a 70 m deep granite gorge. The deck sags, planks are missing and two hang by
/// one rope; a river runs on the gorge floor and a waterfall drops off the far rim. Pines crowd both rims. The camera
/// stands on the deck a few steps in. Planks, hangers and trees are instanced, the ropes are single tubes.
public struct RopeBridgeGorge: RealSceneBuilder {
    public static let id = "rope-bridge-gorge"
    public static let summary = "Hemp rope bridge with missing planks 70 m above a river gorge: strata walls, waterfall, pines on both rims."
    public static let tags = ["outdoor", "gorge", "rock", "water", "terrain"]
    public static let author = "hunter"

    public var size: Float = 300
    public var depth: Float = 70
    public var span: Float = 42
    public init() {}

    func center(_ z: Float) -> Float { 9 * sin(z * 0.022 + 0.6) + 4 * sin(z * 0.057) }

    public func build(seed: UInt64) -> RealScene {
        var scene = RealScene(name: Self.id)
        scene.farGround = nil
        var rng = SeededRNG(seed: seed &+ 99)
        let ns = UInt32(truncatingIfNeeded: seed)
        let half = size / 2

        func profile(_ d: Float) -> Float { 1 - smoothstep(5, 17, d) }
        func height(_ p: V2) -> Float {
            let z = p.y
            let d0 = abs(p.x - center(z))
            let d = d0 + 2.2 * Noise.fbm(V3(p.x * 0.07, z * 0.05, 0), octaves: 3, seed: ns) + 1.6 * Noise.ridged(V3(p.x * 0.11, 0, z * 0.11), octaves: 3, seed: ns &+ 1)
            let D = depth * (1 - smoothstep(105, 145, abs(z)))
            var h = -D * profile(d)
            // Strata terraces on the walls.
            let wall = profile(d) * (1 - profile(d)) * 4
            let st = h / 5.5
            h = lerp(h, (floor(st) + smoothstep(0.65, 1, st - floor(st))) * 5.5, min(1, wall) * 0.55)
            // Rim: rolling forested plateau, rising away from the lip.
            h += (2.5 * Noise.fbm(V3(p.x * 0.02, 0, z * 0.02), octaves: 4, seed: ns &+ 5) + 0.035 * max(0, d0 - 18)) * smoothstep(8, 22, d0)
            let edge = 1 - smoothstep(half * 0.8, half * 0.98, max(abs(p.x), abs(z)))
            return h * edge - 0.25 * (1 - edge)
        }
        var ground = SceneStrips.ground(size: size, segments: 330, material: "ground.alpine-cliff", hollows: 0.5, relief: 4) { height($0) }
        ground.paintSplat { v in
            let h0 = height(V2(v.x, v.z)), hx = height(V2(v.x + 1.2, v.z)) - height(V2(v.x - 1.2, v.z)), hz = height(V2(v.x, v.z + 1.2)) - height(V2(v.x, v.z - 1.2))
            let slope = simd_length(V2(hx, hz)) / 2.4
            return (1 - smoothstep(0.3, 0.7, slope)) * (h0 < -40 ? 0.3 : 1)
        }
        scene.add(Model(name: "gorge-terrain", surfaces: [ground]))
        scene.add(Model(name: "far-plain", surfaces: [EnvKit.plane(size: 7200, cells: 240, hole: half, y: -0.25, material: "ground.alpine")]))

        // River on the floor.
        let floorLine = EnvKit.spline((0...10).map { i -> V2 in let z = -140 + Float(i) * 28; return V2(center(z), z) }, perSegment: 8)
        var river = Model(name: "river")
        river.add(EnvKit.ribbon(material: "water.stream", line: floorLine, width: { 8.5 + 2.5 * sin($0 * 12) - 6 * smoothstep(0.8, 1, abs($0 * 2 - 1)) }, across: 8, y: { _ in -depth + 0.55 }) { _, _ in 0 })
        scene.add(river)

        // Waterfall on the far rim: a sheet hugging the wall, from the rim lip to a foam pool on the floor.
        let wz: Float = -62, wx = center(wz) + 17
        func wallX(at y: Float) -> Float {
            // Solve height(x, wz) = y on the right wall by bisection between the floor edge and the rim.
            var lo = center(wz) + 3, hi = center(wz) + 26
            for _ in 0..<28 { let m = (lo + hi) / 2; if height(V2(m, wz)) < y { lo = m } else { hi = m } }
            return (lo + hi) / 2
        }
        var fall = Surface(material: "water.fountain")
        let steps = 48
        let top = height(V2(wx + 3, wz)) + 0.1
        for i in 0...steps {
            let t = Float(i) / Float(steps)
            let y = lerp(top - 0.5, -depth + 1.0, pow(t, 0.97))
            let x = wallX(at: y) - 0.7 - 1.8 * sin(.pi * t) * 0.0
            let w = 3.2 + 2.4 * t
            for k in 0...6 {
                let s = Float(k) / 6 * 2 - 1
                _ = fall.add(V3(x - 0.25 * sin(t * 40 + s * 3) * 0.05 + 0.5 * t * t, y, wz + s * w / 2), V3(-1, 0, 0), V2(y * 0.5, s * w / 2))
            }
        }
        for j in 0..<UInt32(steps) { for k in 0..<UInt32(6) { let a = j * 7 + k; fall.quad(a, a + 7, a + 8, a + 1) } }
        fall.recomputeNormals(weldSeams: false)
        fall.computeTangents()
        scene.add(Model(name: "waterfall", surfaces: [fall]))
        var pool = Model(name: "fall-pool")
        pool.add(EnvKit.disc(radius: 7, center: V2(wallX(at: -depth + 1) - 3, wz), rings: 6, segments: 28, y: { _ in -depth + 0.7 }, material: "water.foam"))
        scene.add(pool)

        // Bridge geometry: sagging catenary deck along x at z = 0.
        let bx = center(0), xa = bx - span / 2, xb = bx + span / 2
        let rimY = height(V2(xa - 1.5, 0))
        let sag: Float = 2.6
        func deckY(_ x: Float) -> Float {
            let t = (x - bx) / (span / 2)
            return rimY + 0.55 - sag * (1 - t * t)
        }
        let deckHalf: Float = 0.62
        // Plank field: 0.19 m treads, a tenth missing, the odd one cocked.
        let plankModel: Model = { var m = Model(name: "plank"); m.add(plank(1.3, 0.19, 0.045, bevel: 0.006, material: "wood.weathered")); return m }()
        var planks: [simd_float4x4] = [], hanging: [simd_float4x4] = []
        let missing: Set<Int> = [14, 15, 31, 32, 33, 47, 70, 71, 100, 118, 119, 140]
        let dangling: Set<Int> = [13, 34, 99, 120]
        var x = xa + 0.6
        var idx = 0
        while x < xb - 0.5 {
            idx += 1
            defer { x += 0.21 }
            if missing.contains(idx) { continue }
            let ya = deckY(x)
            let pitch = atan((deckY(x + 0.05) - deckY(x - 0.05)) / 0.1)
            let yaw = simd_quatf(angle: .pi / 2 + rng.float(-0.03...0.03), axis: .up)
            let tilt = simd_quatf(angle: pitch, axis: V3(0, 0, 1))
            if dangling.contains(idx) {
                // Hangs from one rope: pivots about its near end and swings down.
                let theta: Float = rng.float(0.9...1.35)
                let swing = simd_quatf(angle: theta, axis: V3(1, 0, 0))
                let center = V3(x, ya, -deckHalf + 0.02) + V3(0, -0.65 * sin(theta), 0.65 * cos(theta))
                hanging.append(Xform(translation: center, rotation: tilt * swing * yaw).matrix)
            } else {
                planks.append(Xform(translation: V3(x, ya, rng.float(-0.025...0.025)), rotation: tilt * yaw).matrix)
            }
        }
        scene.field(model: plankModel, id: "bridge-plank", transforms: planks, options: .groundCover(cull: 140))
        scene.field(model: plankModel, id: "bridge-plank-hang", transforms: hanging, options: .groundCover(cull: 140))

        // Ropes: two load ropes under the deck edge, two handropes at 1.05 m, hemp, 24-sided.
        let n = 90
        func rope(z: Float, lift: Float, radius: Float, sagScale: Float) -> Surface {
            let path: [V3] = (0...n).map { i in
                let x = lerp(xa - 1.2, xb + 1.2, Float(i) / Float(n))
                let t = (x - bx) / (span / 2)
                let y = rimY + 0.55 + lift - sag * sagScale * max(0, 1 - t * t) + (abs(t) > 1 ? 0 : 0)
                return V3(x, y, z)
            }
            return Prim.tube(path, radii: Array(repeating: radius, count: path.count), sides: 24, seamTile: 0.2, material: "rope.hemp")
        }
        var ropes = Model(name: "bridge-ropes")
        for side: Float in [-1, 1] {
            ropes.add(rope(z: side * (deckHalf - 0.05), lift: -0.07, radius: 0.036, sagScale: 1))
            ropes.add(rope(z: side * (deckHalf + 0.04), lift: 1.08, radius: 0.03, sagScale: 0.92))
        }
        scene.add(ropes)
        // Hangers: vertical hemp every 1.4 m joining handrope to the load rope.
        var hangerMesh = Model(name: "hanger")
        hangerMesh.add(Prim.tube([V3(0, 0, 0), V3(0, 1, 0)], radii: [0.012, 0.012], sides: 12, seamTile: 0.1, material: "rope.hemp"))
        var hangers: [simd_float4x4] = []
        var hx = xa + 0.9
        while hx < xb - 0.4 {
            let t = (hx - bx) / (span / 2)
            let y0 = rimY + 0.55 - 0.07 - sag * (1 - t * t)
            let y1 = rimY + 0.55 + 1.08 - sag * 0.92 * (1 - t * t)
            for side: Float in [-1, 1] {
                hangers.append(Xform(translation: V3(hx, y0, side * (deckHalf - 0.02)), scale: V3(1, max(0.2, y1 - y0), 1)).matrix)
            }
            hx += 1.4
        }
        scene.field(model: hangerMesh, id: "bridge-hanger", transforms: hangers, options: .groundCover(cull: 120))
        // Anchor posts: squared timber with a cross-tie, one at each end of each rope pair.
        for (i, ax) in [xa - 1.3, xb + 1.3].enumerated() {
            let g = height(V2(ax, 0))
            for side: Float in [-1, 1] {
                var m = Model(name: "bridge-post")
                m.add(plank(0.2, 0.2, 1.9, bevel: 0.02, material: "wood.weathered"), Xform(translation: V3(0, 0.8, 0), rotation: simd_quatf(angle: .pi / 2, axis: V3(0, 0, 1))))
                m.add(plank(0.18, 0.55, 0.12, bevel: 0.01, material: "wood.weathered"), Xform(translation: V3(0, 1.35, 0), rotation: simd_quatf(angle: .pi / 2, axis: .up)))
                scene.add(m, at: place(ax, side * 0.82, y: g - 0.1, yaw: Float(i) * 8))
            }
        }

        // Trees along both rims, away from the lip; boulders and ferns beneath them.
        func rimOK(_ p: V2) -> Bool { abs(p.x - center(p.y)) > 22 && abs(p.y) < 120 && simd_length(V2(p.x - bx, p.y)) > 26 }
        let treeAssets: [(any RealAsset, Float)] = [(SpruceTree(), 0.9), (ScotsPine(), 1.0), (FirTree(), 0.85)]
        let pts = Scatter.poisson(count: 140, outerRadius: 130, minSpacing: 7, seed: seed &+ 3) { rimOK($0) }
        var buckets = [[simd_float4x4]](repeating: [], count: 3)
        for p in pts { buckets[rng.int(0...2)].append(SceneStrips.xform(p, y: height(p) - 0.12, &rng, scale: 0.7...1.25, lean: 2)) }
        scene.field(treeAssets[0].0 as! SpruceTree, seed: seed &+ 11, transforms: buckets[0], options: .trees)
        scene.field(treeAssets[1].0 as! ScotsPine, seed: seed &+ 12, transforms: buckets[1], options: .trees)
        scene.field(treeAssets[2].0 as! FirTree, seed: seed &+ 13, transforms: buckets[2], options: .trees)
        let fernPts = Scatter.uniform(count: 600, outerRadius: 60, seed: seed &+ 4) { p in rimOK(V2(p.x + bx, p.y)) && abs(p.x + bx - center(p.y)) < 50 }
        scene.field(Fern(), seed: seed &+ 5, transforms: fernPts.map { p in SceneStrips.xform(V2(p.x + bx, p.y), y: height(V2(p.x + bx, p.y)) - 0.03, &rng, scale: 0.8...1.5) }, options: .groundCover(cull: 40))
        for (i, p) in Scatter.poisson(count: 18, outerRadius: 70, minSpacing: 9, seed: seed &+ 6, accept: { rimOK(V2($0.x + bx, $0.y)) }).enumerated() {
            let c = V2(p.x + bx, p.y)
            scene.add(Boulder().with { $0.material = "rock.granite"; $0.size = V3(1.8, 1.2, 1.5) * rng.float(0.6...2.0) },
                      at: place(c.x, c.y, y: height(c) - 0.1, yaw: rng.float(0...360)), seed: seed &+ UInt64(20 + i))
        }

        scene.lighting.sky = SunSky(elevation: 36, azimuth: 150, turbidity: 3.0).with { $0.fogDensity = 0.0045; $0.sunLux = 7500; $0.shadowDistance = 90; $0.cloudSeed = 2 }
        let eye = V3(xa + 5.5, deckY(xa + 5.5) + 1.7, 0.1)
        scene.camera = .init(eye: eye, target: V3(xb, deckY(xb - 6) - 5, 0), fov: 70)
        scene.spots = [.init("Bridge", eye: eye, target: V3(xb, deckY(xb - 6) - 5, 0)),
                       .init("Rim", eye: V3(xa - 6, height(V2(xa - 6, 6)) + 1.7, 6), target: V3(bx, -40, -20))]
        return scene
    }
}
