import simd
import Foundation
import RealityKit
import RealKit

/// A 2.6 m dirt ledge cut into a 56 m sea cliff in a gale. The path winds along the face with a hemp handline that has
/// given way in two places, rock wall above, and surf breaking over the foot of the cliff below. Sea stacks stand offshore,
/// a striped lighthouse burns on the headland. The coast is one coarse heightfield; surf, foam and spray are one wave patch,
/// foam ribbons and an instanced spray field.
public struct SeaCliffLedge: RealSceneBuilder {
    public static let id = "sea-cliff-ledge"
    public static let summary = "Storm on a sea cliff: narrow ledge path with a broken handline, 56 m drop to breaking surf, sea stacks and a lighthouse."
    public static let tags = ["cliff", "ocean", "outdoor", "rock", "water", "terrain"]
    public static let author = "hunter"

    public var shelf: Float = 56
    public var plateau: Float = 92
    public init() {}

    func coast(_ x: Float) -> Float { 14 * sin(x * 0.03) + 6 * sin(x * 0.09 + 1) + 3 * sin(x * 0.21) }

    public func build(seed: UInt64) -> RealScene {
        var scene = RealScene(name: Self.id)
        scene.farGround = "water.deep"
        var rng = SeededRNG(seed: seed &+ 99)
        let ns = UInt32(truncatingIfNeeded: seed)

        func shelfY(_ x: Float) -> Float { shelf + 2.5 * sin(x * 0.02 + 0.5) + 1.2 * sin(x * 0.057) }
        func land(_ p: V2) -> Float {
            let x = p.x
            let d = p.y - coast(x)
            let shelfMask = smoothstep(-0.6, 0.4, d) * (1 - smoothstep(3.0, 4.2, d))
            let rough = (1 - shelfMask)
            let dn = d + rough * (2.6 * Noise.fbm(V3(x * 0.07, p.y * 0.05, 0), octaves: 4, seed: ns) + 1.4 * Noise.ridged(V3(x * 0.15, 0, p.y * 0.15), octaves: 3, seed: ns &+ 1))
            let sy = shelfY(x)
            var h: Float
            if dn < -9 { h = -0.7 + 0.5 * Noise.fbm(V3(x * 0.2, 0, p.y * 0.2), octaves: 2, seed: ns &+ 2) }
            else if dn < 0 { h = lerp(-0.6, sy, pow(smoothstep(-9, 0, dn), 0.82)) }
            else if dn < 3.6 { h = sy + 0.06 * Noise.fbm(V3(x * 0.9, 0, p.y * 0.9), octaves: 2, seed: ns &+ 3) }
            else { h = sy + (plateau - shelf) * pow(smoothstep(3.6, 11.5, dn), 0.85) + 0.025 * max(0, d - 12) }
            // Strata terraces on the cliff and wall faces.
            let faces = (1 - shelfMask) * smoothstep(-8, -2, d) * 0.45
            let st = h / 3.6
            h = lerp(h, (floor(st) + smoothstep(0.7, 1, st - floor(st))) * 3.6, faces * 0.6)
            // Plateau: rolling grass.
            if dn > 11.5 { h += 3.2 * Noise.fbm(V3(x * 0.02, 0, p.y * 0.02), octaves: 3, seed: ns &+ 5) * smoothstep(11.5, 30, dn) }
            // Headlands fall away to low coast at both ends of the patch.
            let end = 1 - smoothstep(150, 196, abs(x))
            let far = 1 - smoothstep(100, 118, p.y)
            return lerp(-0.4, h, end * far)
        }

        let x0: Float = -200, x1: Float = 200, z0: Float = -120, z1: Float = 120
        var ground = EnvKit.terrain(min: V2(x0, z0), max: V2(x1, z1), segments: 420, material: "ground.alpine-cliff", height: { land($0) })
        ground.paintSplat { v in
            let p = V2(v.x, v.z)
            let hx = land(V2(p.x + 0.9, p.y)) - land(V2(p.x - 0.9, p.y)), hz = land(V2(p.x, p.y + 0.9)) - land(V2(p.x, p.y - 0.9))
            return (v.z - coast(v.x) < 12) ? 0 : 1 - smoothstep(0.3, 0.75, simd_length(V2(hx, hz)) / 1.8)
        }
        scene.add(Model(name: "cliff-coast", surfaces: [ground]))

        // Sea: breaking swell near the cliff (finer patch), flat plane to the horizon from farGround.
        func swell(_ p: V2) -> Float {
            let a = 0.42 * sin(0.21 * p.x + 0.33 * p.y) + 0.28 * sin(0.37 * p.x - 0.19 * p.y + 1.2) + 0.15 * sin(0.8 * p.x + 0.5 * p.y + 2.0)
            let d = p.y - coast(p.x)
            let crash = 3.2 * exp(-pow((d + 13) / 5.0, 2)) * (0.55 + 0.45 * sin(p.x * 0.31 + 1.7)) * (0.7 + 0.3 * sin(p.x * 0.07))
            return a + crash + 1.0
        }
        var sea = EnvKit.terrain(min: V2(-260, -230), max: V2(260, 18), segments: 360, material: "water.ocean", height: { p in
            let fade = smoothstep(0, 40, min(p.y + 230, 260 - abs(p.x)))
            return lerp(-0.25, swell(p), fade)
        })
        sea.paintSplat { _ in 0 }
        scene.add(Model(name: "sea-swell", surfaces: [sea]))

        // Trodden dirt on the ledge.
        let pathLine = EnvKit.spline((0...40).map { i -> V2 in let x = x0 + 30 + Float(i) / 40 * (x1 - x0 - 60); return V2(x, coast(x) + 1.7) }, perSegment: 4)
        scene.add(Model(name: "ledge-path", surfaces: [EnvKit.ribbon(material: "ground.dirt", line: pathLine, width: { _ in 2.5 }, across: 6, y: { land($0) }) { _, s in 0.03 - 0.02 * s * s }]))

        // Foam along the foot of the cliff and over the swell crests.
        var foam = Model(name: "surf-foam")
        let foamLine = (0...120).map { i -> V2 in let x = x0 + 40 + Float(i) / 120 * (x1 - x0 - 80); return V2(x, coast(x) - 11.5 + 2.2 * sin(x * 0.11)) }
        foam.add(EnvKit.ribbon(material: "water.foam", line: foamLine, width: { t in 6 + 3.5 * sin(t * 61) + 2 * sin(t * 23) }, across: 6, y: { swell($0) }) { _, s in 0.16 + 0.1 * (1 - abs(s)) })
        let foamLine2 = (0...80).map { i -> V2 in let x = x0 + 40 + Float(i) / 80 * (x1 - x0 - 80); return V2(x, coast(x) - 24 + 5 * sin(x * 0.05)) }
        foam.add(EnvKit.ribbon(material: "water.foam", line: foamLine2, width: { t in 2.5 + 1.5 * sin(t * 71) }, across: 4, y: { swell($0) }) { _, s in 0.12 })
        scene.add(foam)

        // Spray: white blobs thrown up the foot of the cliff.
        let sprayModel = EnvKit.blob(V3(0.5, 0.42, 0.5), lump: 0.35, subdiv: 8, seed: 3, material: "water.foam")
        var spray: [simd_float4x4] = []
        for _ in 0..<260 {
            let x = rng.float((x0 + 60)...(x1 - 60))
            let p = V2(x, coast(x) - rng.float(7...13))
            let s = rng.float(0.4...2.2)
            spray.append(Xform(translation: V3(p.x, swell(p) + rng.float(0.2...9) * rng.float(0.3...1), p.y), rotation: simd_quatf(angle: rng.float(0...6.28), axis: .up), scale: V3(s, s * rng.float(0.6...1.3), s)).matrix)
        }
        scene.field(model: Model(name: "spray", surfaces: [sprayModel]), id: "spray", transforms: spray, options: .groundCover(cull: 200))

        // Sea stacks and the rocks at the foot of the cliff.
        let stacks: [(V2, V3, Float)] = [(V2(-70, -62), V3(14, 38, 12), 20), (V2(-52, -85), V3(9, 26, 8), -30), (V2(40, -75), V3(18, 44, 14), 10),
                                         (V2(78, -58), V3(10, 22, 9), 35), (V2(-135, -95), V3(22, 52, 18), 0), (V2(125, -110), V3(26, 48, 20), 15)]
        for (i, s) in stacks.enumerated() {
            let m = EnvKit.slab(s.1, n: 4.6, lump: 0.14, subdiv: 28, seed: UInt32(60 + i), material: "rock.mountain", taper: 0.35)
            var model = Model(name: "sea-stack-\(i)")
            model.add(m)
            scene.add(model, at: Xform(translation: V3(s.0.x, s.1.y * 0.5 - 4, s.0.y), rotation: simd_quatf(angle: radians(s.2), axis: .up)))
            var ring = Model(name: "stack-foam-\(i)")
            ring.add(EnvKit.disc(radius: max(s.1.x, s.1.z) * 0.95, center: s.0, rings: 4, segments: 28, y: { p in swell(p) + 0.14 }, material: "water.foam"))
            scene.add(ring)
        }
        for (i, p) in Scatter.poisson(count: 40, outerRadius: 120, minSpacing: 5, seed: seed &+ 5, accept: { q in
            let d = q.y - coast(q.x); return d > -16 && d < -7 && abs(q.x) < 140 }).enumerated() {
            let g = land(p)
            scene.add(Boulder().with { $0.material = "rock.mountain"; $0.size = V3(2.4, 1.6, 2.0) * rng.float(0.6...2.2) }, at: place(p.x, p.y, y: max(g, -0.5) - 0.2, yaw: rng.float(0...360)), seed: seed &+ UInt64(100 + i))
        }

        // Handline along the seaward edge of the ledge: posts every 2.4 m and hemp strung between them, broken in two reaches.
        let railX0: Float = -60, railX1: Float = 110
        let broken: [ClosedRange<Float>] = [10...21, 58...66]
        var posts: [simd_float4x4] = []
        let postModel: Model = { var m = Model(name: "rail-post"); m.add(plank(0.1, 0.1, 1.12, bevel: 0.012, material: "wood.weathered"), Xform(translation: V3(0, 0.56, 0), rotation: simd_quatf(angle: .pi / 2, axis: V3(0, 0, 1)))); return m }()
        var rx = railX0
        var ropePts: [[V3]] = []
        var cur: [V3] = []
        while rx < railX1 {
            let z = coast(rx) + 0.15
            let y = land(V2(rx, z))
            let isBroken = broken.contains { $0.contains(rx) }
            if isBroken {
                if cur.count > 1 { ropePts.append(cur) }
                cur = []
                if rng.chance(0.4) { posts.append(Xform(translation: V3(rx, y - 0.03, z), rotation: simd_quatf(angle: rng.float(0.3...1.1), axis: V3(0, 0, 1)) * simd_quatf(angle: rng.float(-0.4...0.4), axis: .up)).matrix) }
            } else {
                posts.append(Xform(translation: V3(rx, y - 0.03, z), rotation: simd_quatf(angle: rng.float(-0.04...0.04), axis: V3(0, 0, 1))).matrix)
                cur.append(V3(rx, y + 0.96, z))
            }
            rx += 2.4
        }
        if cur.count > 1 { ropePts.append(cur) }
        scene.field(model: postModel, id: "rail-post", transforms: posts, options: .groundCover(cull: 160))
        var ropes = Model(name: "handline")
        for run in ropePts {
            // Densify with a catenary dip between posts.
            var path: [V3] = []
            for i in 0..<(run.count - 1) {
                for k in 0..<8 {
                    let t = Float(k) / 8
                    var p = lerp(run[i], run[i + 1], t)
                    p.y -= 0.11 * sin(t * .pi)
                    path.append(p)
                }
            }
            path.append(run[run.count - 1])
            ropes.add(Prim.tube(path, radii: Array(repeating: 0.016, count: path.count), sides: 24, seamTile: 0.1, material: "rope.hemp"))
        }
        scene.add(ropes)

        // Grass and shrubs on the plateau and the ledge verge.
        let grassPts = Scatter.uniform(count: 2600, outerRadius: 130, seed: seed &+ 9) { q in
            let d = q.y - coast(q.x); return abs(q.x) < 150 && ((d > 13 && d < 90) || (d > 3.6 && d < 5.5 && abs(q.x) < 100))
        }
        let gh = grassPts.count / 2
        scene.field(GrassTuft(), seed: seed &+ 10, transforms: grassPts[..<gh].map { SceneStrips.xform($0, y: land($0) - 0.02, &rng, scale: 0.8...1.6) }, options: .groundCover(cull: 70))
        scene.field(TallGrass(), seed: seed &+ 11, transforms: grassPts[gh...].map { SceneStrips.xform($0, y: land($0) - 0.02, &rng, scale: 0.7...1.3) }, options: .groundCover(cull: 70))
        let shrubPts = Scatter.poisson(count: 30, outerRadius: 120, minSpacing: 9, seed: seed &+ 12) { q in let d = q.y - coast(q.x); return d > 16 && d < 80 && abs(q.x) < 140 }
        scene.field(Shrub(), seed: seed &+ 13, transforms: shrubPts.map { SceneStrips.xform($0, y: land($0) - 0.05, &rng, scale: 0.8...1.8) }, options: .groundCover(cull: 120))

        // Lighthouse on the far headland.
        let lh = V2(120, coast(120) + 16)
        let base = land(lh)
        var tower = Model(name: "lighthouse")
        let bands: [(MaterialKey, Float, Float, Float, Float)] = [
            ("concrete.smooth:ECE8DE", 0, 5, 4.6, 4.1), ("metal.painted:B3201C", 5, 9, 4.1, 3.8), ("concrete.smooth:ECE8DE", 9, 14, 3.8, 3.4),
            ("metal.painted:B3201C", 14, 18, 3.4, 3.1), ("concrete.smooth:ECE8DE", 18, 22, 3.1, 2.8)]
        for b in bands { tower.add(Prim.lathe([V2(0, b.1), V2(b.3, b.1), V2(b.4, b.2), V2(0, b.2)], segments: 56, seamTile: 0.5, material: b.0)) }
        tower.add(Prim.lathe([V2(0, 22), V2(3.8, 22), V2(3.8, 22.35), V2(3.1, 22.35), V2(3.1, 22.6), V2(0, 22.6)], segments: 56, seamTile: 0.5, material: "metal.painted:1E1E20"))
        tower.add(Prim.lathe([V2(0, 22.6), V2(2.1, 22.6), V2(2.1, 25.4), V2(0, 25.4)], segments: 56, seamTile: 0.5, material: "glass.lamp"))
        tower.add(Prim.lathe([V2(0, 25.4), V2(2.5, 25.4), V2(2.2, 26.0), V2(0.0, 27.6)], segments: 56, seamTile: 0.5, material: "metal.painted:1E1E20"))
        scene.add(tower, at: place(lh.x, lh.y, y: base - 0.3))
        scene.lights.append(RigLight(name: "lighthouse", position: V3(lh.x, base + 24, lh.y), color: V3(1, 0.92, 0.7), intensity: 400_000, attenuationRadius: 220))

        scene.lighting.sky = SunSky(elevation: 26, azimuth: 225, turbidity: 3).with {
            $0.sunLux = 8000; $0.overcast = 0.85; $0.fogDensity = 0.0042; $0.fogBrightness = 0.85; $0.shadowDistance = 110; $0.cloudSeed = 7; $0.iblExposure = 0.2
        }
        let ex: Float = -34
        let eye = V3(ex, land(V2(ex, coast(ex) + 1.5)) + 1.7, coast(ex) + 1.5)
        let tx: Float = 38
        scene.camera = .init(eye: eye, target: V3(tx, 36, coast(tx) - 24), fov: 72)
        scene.spots = [.init("Ledge", eye: eye, target: V3(tx, 36, coast(tx) - 24)),
                       .init("Lookout", eye: V3(70, land(V2(70, coast(70) + 1.5)) + 1.7, coast(70) + 1.5), target: V3(20, 20, coast(20) - 40))]
        return scene
    }
}
