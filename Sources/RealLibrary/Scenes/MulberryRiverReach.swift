import simd
import Foundation
import RealityKit
import RealKit

/// Mulberry River, Ozark National Forest, Arkansas, late spring afternoon: a 400 m reach flowing +X, water at
/// y = 0, 20 m wide, a 5 m pool under a grey limestone bluff on the north (-Z) bank, a gravel bar and eddy
/// on the south bank, riffles at 0.3 m, a driftwood logjam and a tailout, sycamore and river birch on the
/// banks, oak and shortleaf pine on the hills. A 10 ft jon boat with a clamp-on trolling motor floats at
/// the head of the bluff pool; the camera is a seated angler on its stern seat. River data: `RiverPath.mulberry()`.
public struct MulberryRiverReach: RealSceneBuilder {
    public static let id = "mulberry-river"
    public static let summary = "Ozark river reach, 400 m: clear green pools, riffles, limestone bluff, gravel bar, logjam, sycamores; jon boat with trolling motor."
    public static let tags = ["nature", "river", "water", "forest", "showcase"]
    public static let author = "realityhd"

    /// Terrain extent across the valley (Z) in meters.
    public var valleyWidth: Float = 240
    /// Boat position (x, lateral offset from the centerline).
    public var boatAt = V2(-68, 2.5)
    public var path = RiverPath.mulberry()
    /// Clear green Ozark water: about 6 m visibility, red absorbed first, caustics on the bed.
    public static let water = RealScene.Lighting.Water(level: 0, density: 0.36, color: V3(0.012, 0.042, 0.032), caustics: 0.55)
    public init() {}

    /// Bluff zone along x (north bank).
    func bluffWeight(_ x: Float) -> Float { smoothstep(-102, -90, x) * (1 - smoothstep(4, 16, x)) }
    /// Gravel bar zone along x (south bank).
    func barWeight(_ x: Float) -> Float { smoothstep(8, 18, x) * (1 - smoothstep(52, 64, x)) }

    /// Ground or riverbed height at p.
    public func height(_ p: V2, seed: UInt64) -> Float {
        let ns = UInt32(truncatingIfNeeded: seed) &+ 17
        let (d, s) = path.lateral(p)
        let half = s.width / 2
        if abs(d) < half { return -path.bedDepth(p) + Noise.fbm(V3(p.x * 0.3, 0, p.y * 0.3), octaves: 3, seed: ns) * 0.18 }
        let e = abs(d) - half
        let north = d < 0
        let n = Noise.fbm(V3(p.x * 0.012, 0.5, p.y * 0.012), octaves: 4, seed: ns &+ 1)
        var h = 1.3 * smoothstep(0, 7, e) + 0.6 * smoothstep(7, 30, e)
        h += (26 + 18 * n) * smoothstep(28, 100, e)
        h += Noise.fbm(V3(p.x * 0.08, 1.5, p.y * 0.08), octaves: 3, seed: ns &+ 2) * 0.5 * smoothstep(2, 10, e)
        if north { h += bluffWeight(p.x) * (12.5 * smoothstep(0.5, 3.5, e)) }
        else { h *= 1 - barWeight(p.x) * 0.85 * (1 - smoothstep(10, 22, e)) }
        return h
    }

    public func build(seed: UInt64) -> RealScene {
        var scene = RealScene(name: Self.id)
        var rng = SeededRNG(seed: seed &+ 99)
        let L = path.length
        func y(_ p: V2) -> Float { height(p, seed: seed) }
        func zc(_ x: Float) -> Float { path.sample(atX: x).center.y }
        func lat(_ p: V2) -> Float { abs(path.lateral(p).offset) - path.sample(atX: p.x).width / 2 }
        func xf(_ p: V2, scale: ClosedRange<Float>, sink: Float) -> simd_float4x4 {
            Xform(translation: V3(p.x, y(p) - sink, p.y), rotation: simd_quatf(degrees: rng.float(0...360), axis: .up),
                  scale: V3(repeating: rng.float(scale))).matrix
        }

        // Terrain in four tiles along X: riverbed triangles get the wet gravel bed, the rest bank soil
        // splat-blended to bar gravel near the water.
        let tiles = 4, tw = (L + 20) / Float(tiles)
        for t in 0..<tiles {
            let cx = -(L + 20) / 2 + tw * (Float(t) + 0.5)
            var g = Prim.terrain(size: V2(tw, valleyWidth), segments: 200, material: "ground.ozark-bank") { q in y(V2(q.x + cx, q.y)) }
            g.paintSplat { q in
                let p = V2(q.x + cx, q.z)
                return 1 - smoothstep(0.4, 1.6, q.y) * (1 - barWeight(p.x) * (1 - smoothstep(6, 18, lat(p))))
            }
            let (bank, bed) = ConiferBuild.split(g, material: "ground.river-gravel-wet") { $0.y < -0.02 }
            // Pools below 2.2 m settle fine silt over the gravel.
            let (gravel, silt) = ConiferBuild.split(bed, material: "ground.river-silt") { $0.y < -2.2 }
            scene.add(Model(name: "mulberry-ground-\(t)", surfaces: [bank, gravel, silt]), at: Xform(translation: V3(cx, 0, 0)))
            // Water: shallowness in splat; riffle sections move to the faster, choppier riffle water.
            var w = Prim.terrain(size: V2(tw, 64), segments: 96, material: "water.mulberry") { _ in 0 }
            w.paintSplat { q in 1 - smoothstep(0.1, 3.2, path.bedDepth(V2(q.x + cx, q.z))) }
            let (pool, riffle) = ConiferBuild.split(w, material: "water.mulberry-riffle") { c in
                let s = path.sample(atX: c.x + cx); return s.depth < 0.55 && path.bedDepth(V2(c.x + cx, c.z)) > 0
            }
            scene.add(Model(name: "mulberry-water-\(t)", surfaces: [pool, riffle]), at: Xform(translation: V3(cx, 0, 0)))
        }

        // North bluff over the pool: overlapping tapered sections that follow the bank, so no section end shows.
        for (i, x) in stride(from: Float(-84), through: 4, by: 22).enumerated() {
            let s = path.sample(atX: x)
            let yaw = -atan2(s.tangent.y, s.tangent.x) * 180 / .pi
            scene.add(LimestoneBluff().with { $0.length = 30; $0.height = rng.float(11...14); $0.endTaper = 6; $0.bedHeight = rng.float(0.6...1.2); $0.ledgeDepth = 0.6 },
                      at: place(x, s.center.y - s.width / 2 - 1.3 - Float(i % 2) * 0.6, y: -2.9, yaw: yaw), seed: seed &+ UInt64(1 + i))
        }
        // Talus: angular blocks fallen from the bluff along its foot, and slabs on the south bank at the riffles.
        var talusL: [simd_float4x4] = [], talusS: [simd_float4x4] = []
        for _ in 0..<70 {
            let x = rng.float(-96...14), s = path.sample(atX: x)
            let z = s.center.y - s.width / 2 + rng.float(-1.5...2.5)
            talusL.append(Xform(translation: V3(x, y(V2(x, z)) - 0.25, z), rotation: simd_quatf(degrees: rng.float(0...360), axis: .up),
                                scale: V3(repeating: rng.float(0.5...1.8))).matrix)
        }
        for _ in 0..<60 {
            let x = rng.float(-L / 2...L / 2), s = path.sample(atX: x)
            if barWeight(x) > 0.1 { continue }
            let z = s.center.y + s.width / 2 + rng.float(-1...3)
            talusS.append(Xform(translation: V3(x, y(V2(x, z)) - 0.2, z), rotation: simd_quatf(degrees: rng.float(0...360), axis: .up),
                                scale: V3(rng.float(0.5...1.4), rng.float(0.3...0.7), rng.float(0.5...1.4))).matrix)
        }
        scene.field(Boulder().with { $0.material = "rock.ozark-limestone"; $0.facets = 14 }, seed: seed &+ 8, transforms: talusL, options: .trees)
        scene.field(Boulder().with { $0.material = "rock.ozark-sandstone"; $0.facets = 12 }, seed: seed &+ 9, transforms: talusS, options: .trees)

        // Gravel bar on the south bank opposite the bluff tail, a second small one at the tailout.
        for (x, len, k) in [(Float(34), Float(30), UInt64(4)), (166, 20, 5)] {
            let s = path.sample(atX: x)
            let yaw = -atan2(s.tangent.y, s.tangent.x) * 180 / .pi
            scene.add(GravelBar().with { $0.length = len; $0.width = len * 0.34 }, at: place(x, s.center.y + s.width / 2 + len * 0.1, y: -0.46, yaw: yaw), seed: seed &+ k)
        }

        // Riverbed cobble where the water is shallow enough to see the bottom, and along the waterline.
        var cobWet: [simd_float4x4] = [], cobDry: [simd_float4x4] = []
        for _ in 0..<900 {
            let x = rng.float(-L / 2...L / 2), s = path.sample(atX: x)
            let off = rng.float(-s.width / 2 - 2...s.width / 2 + 2)
            let p = V2(x, s.center.y + off)
            let dep = path.bedDepth(p)
            if dep > 1.3 || (dep <= 0 && rng.chance(0.5)) { continue }
            let m = Xform(translation: V3(p.x, y(p) - 0.04, p.y), rotation: simd_quatf(degrees: rng.float(-20...20), axis: .up), scale: V3(repeating: rng.float(0.7...1.3))).matrix
            if dep > 0 { cobWet.append(m) } else { cobDry.append(m) }
        }
        scene.field(RiverCobble(), seed: seed &+ 6, transforms: cobWet, options: .groundCover(cull: 60))
        scene.field(RiverCobble().with { $0.wet = false }, seed: seed &+ 7, transforms: cobDry, options: .groundCover(cull: 60))

        // Logjam on the north bank of the lower pool, driftwood on the bar.
        let lj = path.spots["logjam"]!
        for i in 0..<7 {
            let a = Float(i)
            let p = V2(lj.x - 6 + a * 2.1 + rng.float(-0.6...0.6), lj.z - 2.5 + rng.float(-2...2))
            let yaw = rng.float(-50...50) + (i % 2 == 0 ? 20 : -15)
            let lift = Float(i % 3) * 0.35
            scene.add(DriftwoodLog().with { $0.length = rng.float(4...7); $0.buttDiameter = rng.float(0.35...0.6) },
                      at: Xform(translation: V3(p.x, max(y(p), -0.5) + lift - 0.15, p.y), rotation: simd_quatf(degrees: yaw, axis: .up) * simd_quatf(degrees: rng.float(-8...8), axis: V3(0, 0, 1))),
                      seed: seed &+ UInt64(20 + i))
        }
        for (x, off, yaw) in [(Float(28), Float(13), Float(20)), (44, 15.5, -35)] {
            let p = V2(x, zc(x) + off)
            scene.add(DriftwoodLog(), at: place(p.x, p.y, y: y(p) - 0.05, yaw: yaw), seed: seed &+ UInt64(30 + Int(x)))
        }

        MulberryUnderwater.add(to: &scene, reach: self, seed: seed)
        scene.lighting.water = Self.water

        MulberryVegetation.add(to: &scene, reach: self, seed: seed, rng: &rng)

        // Jon boat at the head of the bluff pool with the trolling motor on its bow, deployed.
        let bs = path.sample(atX: boatAt.x)
        let boatP = V3(boatAt.x, -0.09, bs.center.y + boatAt.y)
        let boat = SkampBoat()
        let boatX = Xform(translation: boatP, rotation: simd_quatf(degrees: 4, axis: .up))
        scene.add(boat, at: boatX, seed: seed &+ 40)
        let motor = TrollingMotor()
        let mount = boatX.point(boat.anchors["motorMount"]!.translation)
        scene.addLive(motor, at: Xform(translation: mount - boatX.rotation.act(motor.mountPoint), rotation: boatX.rotation), seed: seed &+ 41, state: "deployed")

        scene.farGround = "ground.forest"
        let seat = boatX.point(boat.anchors["seatStern"]!.translation)
        let eye = seat + V3(0, 0.78, 0)
        scene.camera = .init(eye: eye, target: V3(eye.x + 40, 1.2, zc(eye.x + 40) - 7), fov: 62)
        return scene
    }
}
