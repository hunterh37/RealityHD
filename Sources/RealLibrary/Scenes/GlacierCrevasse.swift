import simd
import Foundation
import RealityKit
import RealKit

/// Crevasse field on an alpine glacier at sunrise. A 22 m deep blue-ice slot cuts across the snow in front of the viewer with
/// an aluminium ladder laid over a pinch and a sagging snow bridge further along; icicles hang from the lips, seracs stand
/// beyond, a dome tent and a fixed line mark the route, a range of peaks closes the horizon. The inner 68 m is a fine
/// heightfield (0.24 m cells) so the walls stay near vertical; the outer snow is coarse.
public struct GlacierCrevasse: RealSceneBuilder {
    public static let id = "glacier-crevasse"
    public static let summary = "Glacier at sunrise: deep blue-ice crevasses, ladder crossing, snow bridge, hanging icicles, seracs, tent and a mountain range."
    public static let tags = ["glacier", "snow", "outdoor", "terrain"]
    public static let author = "hunter"

    public var depth: Float = 22
    public var inner: Float = 34
    public init() {}

    func lines() -> [[V2]] {
        let c1 = EnvKit.spline([V2(-52, 3), V2(-30, -5), V2(-14, -1.5), V2(0, -7), V2(13, -3.5), V2(30, -9), V2(52, -4)], perSegment: 10)
        let c2 = EnvKit.spline([V2(21, -4), V2(25, -16), V2(19, -27), V2(24, -40), V2(18, -58)], perSegment: 10)
        let c3 = EnvKit.spline([V2(-26, -7), V2(-30, -19), V2(-23, -30), V2(-27, -46), V2(-20, -62)], perSegment: 10)
        return [c1, c2, c3]
    }

    public func build(seed: UInt64) -> RealScene {
        var scene = RealScene(name: Self.id)
        scene.farGround = nil
        var rng = SeededRNG(seed: seed &+ 99)
        let ns = UInt32(truncatingIfNeeded: seed)
        let cl = lines()
        let widthScale: [Float] = [1.0, 0.7, 0.6]
        // Snow bridge on the main slot, and the pinch where the ladder lies.
        let bridgeT: Float = 0.66, ladderT: Float = 0.405

        func crevasseDrop(_ p: V2) -> Float {
            let fade = 1 - smoothstep(inner - 9, inner - 1, max(abs(p.x), abs(p.y)))
            guard fade > 0 else { return 0 }
            var drop: Float = 0
            for (i, line) in cl.enumerated() {
                let (d, t) = EnvKit.nearest(p, on: line)
                let w = (1.0 + 2.3 * sin(t * .pi * 3.0 + Float(i) * 1.7) * sin(t * .pi * 3.0 + Float(i) * 1.7) + 0.7 * Noise.perlin(V3(t * 18, Float(i), 0), seed: ns)) * widthScale[i]
                var wClamped = max(0.55, w)
                if i == 0 { wClamped = lerp(wClamped, 1.35, exp(-pow((t - ladderT) / 0.025, 2))) }
                let wall = 1 - smoothstep(wClamped * 0.44, wClamped * 0.54, d)
                let v = 1 - 0.6 * smoothstep(0, wClamped * 0.5, d)
                var dep = depth * wall * v * (1 - 0.35 * Noise.fbm(V3(p.x * 0.6, p.y * 0.6, 0), octaves: 2, seed: ns &+ 9))
                if i == 0 { dep *= 1 - exp(-pow((t - bridgeT) / 0.03, 2)) }
                drop = max(drop, dep)
            }
            return drop * fade
        }
        func surface(_ p: V2) -> Float {
            let tilt = -0.012 * p.y
            let swell = 3.2 * Noise.fbm(V3(p.x * 0.011, 0, p.y * 0.011), octaves: 3, seed: ns)
            // Wind sastrugi: stretched ridges lying across the wind (+X).
            let wind = 0.09 * Noise.ridged(V3(p.x * 0.07, 0, p.y * 0.55), octaves: 3, seed: ns &+ 2) + 0.03 * Noise.perlin(V3(p.x * 0.9, 0, p.y * 3.1), seed: ns &+ 3)
            return tilt + swell + wind
        }
        func height(_ p: V2) -> Float {
            var h = surface(p)
            // Lip: a soft cornice rolled over the edge before the wall.
            h -= crevasseDrop(p)
            return h
        }
        func splat(_ v: V3) -> Float {
            let p = V2(v.x, v.z)
            let dx = height(V2(p.x + 0.35, p.y)) - height(V2(p.x - 0.35, p.y)), dz = height(V2(p.x, p.y + 0.35)) - height(V2(p.x, p.y - 0.35))
            let slope = simd_length(V2(dx, dz)) / 0.7
            return smoothstep(0.35, 0.9, slope) + smoothstep(0.5, 6, surface(p) - v.y)
        }

        // Fine patch: heightfield with baked hollow occlusion in the slots.
        let fineSeg = Int(inner * 2 / 0.24)
        var fine = EnvKit.terrain(min: V2(-inner, -inner), max: V2(inner, inner), segments: fineSeg, material: "ground.glacier-snow", height: { height($0) })
        GroundMesh.shadeHollows(&fine, gridSide: fineSeg + 1, radius: 10, relief: 4, strength: 0.9)
        fine.paintSplat(splat)
        scene.add(Model(name: "glacier-inner", surfaces: [fine]))
        // Coarse outer snow with the inner square left open.
        let outer: Float = 180, outerSeg = Int(outer * 2 / 1.545)
        let base: Float = -2.5
        func outerHeight(_ p: V2) -> Float { lerp(base, surface(p), 1 - smoothstep(110, 178, max(abs(p.x), abs(p.y)))) }
        var coarse = EnvKit.terrain(min: V2(-outer, -outer), max: V2(outer, outer), segments: outerSeg, material: "ground.glacier-snow",
                                     skip: { abs($0.x) < inner && abs($0.y) < inner }, height: { outerHeight($0) })
        coarse.paintSplat { _ in 0 }
        scene.add(Model(name: "glacier-outer", surfaces: [coarse]))
        scene.add(Model(name: "far-snow", surfaces: [EnvKit.plane(size: 7200, cells: 200, hole: outer, y: base - 0.4, material: "ground.glacier-snow")]))
        scene.add(Model(name: "peaks", surfaces: [EnvKit.farRange(size: 3600, segments: 220, clear: 380, peak: 1100, seed: ns &+ 20, material: "rock.alpine-peak", base: base)]))

        // Icicles hanging from the lips of the main slots.
        let icicle = EnvKit.spire(radius: 0.16, height: 1.0, sides: 20, wobble: 0.2, seed: 5, material: "ice.glacier", curve: 1.1)
        var icicles: [simd_float4x4] = []
        for (i, line) in cl.enumerated() {
            for k in stride(from: 3, to: line.count - 3, by: 2) {
                let p = line[k], q = line[k + 1]
                guard max(abs(p.x), abs(p.y)) < inner - 10 else { continue }
                let tan = simd_normalize(q - p), side = V2(tan.y, -tan.x)
                let t = Float(k) / Float(line.count - 1)
                if i == 0 && abs(t - bridgeT) < 0.05 { continue }
                for sgn: Float in [-1, 1] where rng.chance(0.55) {
                    let w = (1.0 + 2.3 * pow(sin(t * .pi * 3 + Float(i) * 1.7), 2)) * widthScale[i]
                    let at = p + side * sgn * max(0.55, w) * 0.44 + tan * rng.float(-0.4...0.4)
                    let s = rng.float(0.35...1.9)
                    icicles.append(Xform(translation: V3(at.x, surface(at) - 0.12, at.y), rotation: simd_quatf(angle: .pi, axis: V3(1, 0, 0)), scale: V3(s * 0.8, s, s * 0.8)).matrix)
                }
            }
        }
        scene.field(model: Model(name: "icicle", surfaces: [icicle]), id: "icicle", transforms: icicles, options: .groundCover(cull: 70))

        // Aluminium ladder across the pinch, ends resting on both lips.
        do {
            let line = cl[0]
            let k = Int(ladderT * Float(line.count - 1))
            let p = line[k], q = line[k + 1]
            let tan = simd_normalize(q - p), side = V2(tan.y, -tan.x)
            let a2 = p - side * 2.1, b2 = p + side * 2.1
            let ya = surface(a2) + 0.05, yb = surface(b2) + 0.05
            let a = V3(a2.x, ya, a2.y), b = V3(b2.x, yb, b2.y)
            var m = Model(name: "ladder")
            for off: Float in [-0.21, 0.21] {
                let o = V3(tan.x, 0, tan.y) * off
                let (rail, xf) = board(from: a + o, to: b + o, width: 0.05, thick: 0.035, up: .up, bevel: 0.006, material: "metal.aluminum-brushed")
                m.add(rail, xf)
            }
            let n = 14
            for r in 0...n {
                let c = lerp(a, b, Float(r) / Float(n) * 0.94 + 0.03)
                let (rung, xf) = board(from: c - V3(tan.x, 0, tan.y) * 0.21, to: c + V3(tan.x, 0, tan.y) * 0.21, width: 0.03, thick: 0.03, up: .up, bevel: 0.005, material: "metal.aluminum-brushed")
                m.add(rung, xf)
            }
            scene.add(m)
            // Fixed line: pickets either end and a red rope with a catenary dip, tied to the ladder rails.
            for (j, base) in [a2 - V2(tan.x, tan.y) * 1.4, b2 - V2(tan.x, tan.y) * 1.4].enumerated() {
                let g = surface(base)
                var pk = Model(name: "picket-\(j)")
                pk.add(Prim.tube([V3(0, -0.4, 0), V3(0, 0.45, 0)], radii: [0.016, 0.016], sides: 24, seamTile: 0.1, material: "metal.aluminum-brushed"))
                scene.add(pk, at: place(base.x, base.y, y: g))
            }
            let r0 = a2 - V2(tan.x, tan.y) * 1.4, r1 = b2 - V2(tan.x, tan.y) * 1.4
            let rp: [V3] = (0...30).map { i in
                let t = Float(i) / 30
                let pt = r0 + (r1 - r0) * t
                return V3(pt.x, surface(pt) + 0.44 - 0.22 * sin(t * .pi) * 0, pt.y)
            }
            scene.add(Model(name: "fixed-line", surfaces: [Prim.tube(rp, radii: Array(repeating: 0.011, count: rp.count), sides: 24, seamTile: 0.1, material: "rope.hemp:B8261C")]))
        }

        // Seracs: leaning ice blocks with a snow cap, tallest at the back.
        let serac: [(V2, V3, Float)] = [(V2(-46, -78), V3(9, 14, 7), 18.0), (V2(-30, -96), V3(14, 22, 10), -10.0), (V2(8, -110), V3(18, 30, 12), 8.0), (V2(34, -92), V3(8, 16, 8), 25.0),
                     (V2(52, -70), V3(11, 20, 9), -20.0), (V2(-62, -50), V3(7, 11, 6), 30.0), (V2(58, -30), V3(6, 9, 5), 12.0)]
        for (i, s) in serac.enumerated() {
            let g = surface(s.0)
            let sl = EnvKit.slab(s.1, n: 5.5, lump: 0.1, subdiv: 22, seed: UInt32(30 + i), material: "ice.serac", taper: 0.18)
            var m = Model(name: "serac-\(i)")
            m.add(sl)
            scene.add(m, at: Xform(translation: V3(s.0.x, g + s.1.y * 0.42, s.0.y), rotation: simd_quatf(angle: radians(s.2), axis: .up) * simd_quatf(angle: radians(rng.float(-6...6)), axis: V3(0, 0, 1))))
        }

        // Camp: tent and cairn on the snow behind the viewer, an ice axe planted at the edge.
        scene.add(DomeTent(), at: place(-14, 16, y: surface(V2(-14, 16)) - 0.02, yaw: 28), seed: seed &+ 3)
        scene.add(CairnTrailMarker(), at: place(8, 11, y: surface(V2(8, 11)) - 0.05, yaw: 20), seed: seed &+ 4)
        do {
            let at = V2(-3.2, -1.3)
            let g = surface(at)
            var axe = Model(name: "ice-axe")
            axe.add(Prim.tube([V3(0, 0, 0), V3(0, 0.82, 0)], radii: [0.013, 0.016], sides: 24, seamTile: 0.1, material: "metal.aluminum-brushed"))
            axe.add(Prim.tube([V3(0, -0.04, 0), V3(0, 0.0, 0)], radii: [0.0015, 0.013], sides: 24, seamTile: 0.1, material: "metal.steel"))
            axe.add(plank(0.34, 0.03, 0.012, bevel: 0.003, material: "metal.steel"), Xform(translation: V3(0.04, 0.84, 0), rotation: simd_quatf(angle: -0.18, axis: V3(0, 0, 1))))
            scene.add(axe, at: Xform(translation: V3(at.x, g, at.y), rotation: simd_quatf(angle: radians(7), axis: V3(0, 0, 1)) * simd_quatf(angle: radians(20), axis: .up)))
        }
        for (i, p) in Scatter.poisson(count: 10, outerRadius: 30, minSpacing: 7, seed: seed &+ 8, accept: { crevasseDrop($0) < 0.01 && $0.y > 2 }).enumerated() {
            scene.add(Boulder().with { $0.material = "rock.granite-snow"; $0.size = V3(1.0, 0.7, 0.9) * rng.float(0.4...1.1) },
                      at: place(p.x, p.y, y: surface(p) - 0.12, yaw: rng.float(0...360)), seed: seed &+ UInt64(70 + i))
        }

        scene.lighting.sky = SunSky(elevation: 15, azimuth: 70, turbidity: 1.8).with { $0.sunLux = 10000; $0.fogDensity = 0.0004; $0.shadowDistance = 90; $0.iblExposure = -0.2 }
        let lk = Int(ladderT * Float(cl[0].count - 1))
        let lp = cl[0][lk]
        let ep = V2(lp.x + 4.2, lp.y + 5.5)
        let eye = V3(ep.x, surface(ep) + 1.7, ep.y)
        let tgt = V3(lp.x - 2, surface(lp) - 3, lp.y - 3)
        scene.camera = .init(eye: eye, target: tgt, fov: 68)
        scene.spots = [.init("Lip", eye: eye, target: tgt),
                       .init("Camp", eye: V3(-9, surface(V2(-9, 21)) + 1.7, 21), target: V3(0, 4, -40))]
        return scene
    }
}
