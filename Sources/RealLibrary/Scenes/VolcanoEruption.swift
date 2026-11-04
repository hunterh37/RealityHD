import simd
import Foundation
import RealityKit
import RealKit

/// Active stratovolcano at dusk, seen from the ash plain 200 m out. Three lava rivers run from a notched crater rim
/// down the gullied flank, each a glowing channel with broken crust plates, raised scoria levees and a cooled halo.
/// A lava fountain throws ballistic bombs over the crater, splatter splashes and cooled scoria litter the banks,
/// spatter cones vent at the channel edges. One ribbon per river, one instanced field per spatter variant, and a
/// point light per river reach keep it cheap.
public struct VolcanoEruption: RealSceneBuilder {
    public static let id = "volcano-eruption"
    public static let summary = "Erupting volcano at dusk: three lava rivers with crust plates and levees, fountain bombs, splatter, spatter cones, scoria and ash."
    public static let tags = ["volcano", "outdoor", "rock", "terrain"]
    public static let author = "hunter"

    /// Side of the detailed terrain patch in meters.
    public var size: Float = 380
    public var crater = V2(8, -118)
    public var coneRadius: Float = 150
    public var coneHeight: Float = 125
    public var rimRadius: Float = 17
    public init() {}

    func baseHeight(_ r: Float) -> Float { coneHeight * pow(saturate(1 - max(r, rimRadius) / coneRadius), 1.75) }

    func rivers() -> [[V2]] {
        let a = [V2(8, -105), V2(6, -94), V2(13, -76), V2(3, -56), V2(-8, -34), V2(-12, -10), V2(-4, 14), V2(-13, 38), V2(-24, 58), V2(-22, 76)]
        let b = [V2(0, -104), V2(-14, -92), V2(-33, -78), V2(-47, -58), V2(-55, -32), V2(-50, -6), V2(-58, 22), V2(-68, 46)]
        let c = [V2(14, -104), V2(28, -92), V2(44, -72), V2(54, -46), V2(44, -20), V2(48, 8), V2(62, 34), V2(70, 62)]
        return [a, b, c].map { EnvKit.spline($0, perSegment: 9) }
    }

    public func build(seed: UInt64) -> RealScene {
        var scene = RealScene(name: Self.id)
        scene.farGround = "ground.ash"
        var rng = SeededRNG(seed: seed &+ 99)
        let ns = UInt32(truncatingIfNeeded: seed)
        let half = size / 2
        let lines = rivers()
        let widths: [Float] = [1.0, 0.8, 0.85]

        func riverDist(_ p: V2) -> Float { lines.map { EnvKit.distance(p, to: $0) }.min() ?? 100 }

        // Terrain: gullied cone with a crater and a notch, ash plain, channels carved under the rivers.
        func height(_ p: V2) -> Float {
            let d = p - crater
            let r = simd_length(d)
            let a = atan2(d.y, d.x)
            var h = baseHeight(r)
            let flank = smoothstep(rimRadius + 8, rimRadius + 45, r) * (1 - smoothstep(coneRadius * 0.55, coneRadius * 0.98, r))
            let gully = sin(a * 11 + 2.6 * Noise.fbm(V3(r * 0.02, a * 2, 0), octaves: 3, seed: ns)) * 2.6 + sin(a * 23 + r * 0.05) * 0.9
            h += gully * flank
            h += Noise.ridged(V3(p.x * 0.03, 0, p.y * 0.03), octaves: 4, seed: ns &+ 3) * 3.0 * smoothstep(8, 40, r) * (1 - smoothstep(60, 170, r)) * 0.6
            // Crater bowl, rim lip, notch where the rivers leave.
            h -= 20 * pow(1 - smoothstep(rimRadius * 0.35, rimRadius, r), 1.4)
            h += 2.4 * exp(-pow((r - rimRadius) / 3.2, 2))
            let notch = simd_length(p - V2(crater.x + 3, crater.y + rimRadius))
            h -= 5.5 * exp(-pow(notch / 5.5, 2))
            // Plain: low undulating ash, rising slightly toward the base of the cone.
            h += (Noise.fbm(V3(p.x * 0.012, 0, p.y * 0.012), octaves: 4, seed: ns &+ 7) * 5 + 0.8 * Noise.fbm(V3(p.x * 0.09, 0, p.y * 0.09), octaves: 3, seed: ns &+ 8)) * (1 - 0.7 * smoothstep(0, 80, 175 - r))
            let rd = riverDist(p)
            h -= 0.9 * (1 - smoothstep(2.5, 10, rd)) * smoothstep(rimRadius + 3, rimRadius + 12, r)
            let edge = 1 - smoothstep(half * 0.8, half * 0.98, max(abs(p.x), abs(p.y)))
            return h * edge - 0.25 * (1 - edge) - 0.0
        }
        var ground = SceneStrips.ground(size: size, segments: 340, material: "ground.ash", hollows: 0.4, relief: 3) { height($0) }
        ground.paintSplat { v in
            let p = V2(v.x, v.z)
            let near = 1 - smoothstep(6, 34, riverDist(p))
            let n = Noise.fbm(V3(p.x * 0.05, 0, p.y * 0.05), octaves: 3, seed: ns &+ 4)
            return near * 1.2 + n * 0.5 + 0.2 * smoothstep(rimRadius + 20, 120, simd_length(p - crater))
        }
        scene.add(Model(name: "volcano-terrain", surfaces: [ground]))

        // Lava lake in the crater, with an uplifting dome and a rim of crust.
        let lakeY = baseHeight(rimRadius) - 13.2
        var lake = Model(name: "lava-lake")
        lake.add(EnvKit.disc(radius: rimRadius * 0.62, center: crater, rings: 10, segments: 48, y: { p in
            lakeY + 0.5 * Noise.fbm(V3(p.x * 0.4, 0, p.y * 0.4), octaves: 2, seed: ns &+ 11)
        }, material: "lava.lake"))
        scene.add(lake)

        // Rivers: cooled halo, scoria levees, then the molten channel.
        var lightSpots: [V3] = []
        for (i, line) in lines.enumerated() {
            let wScale = widths[i]
            func w(_ t: Float) -> Float { (3.4 + 6.5 * pow(t, 0.8)) * wScale * (1 + 0.22 * sin(t * 19 + Float(i))) }
            var m = Model(name: "lava-river-\(i)")
            m.add(EnvKit.ribbon(material: "lava.crusted", line: line, width: { w($0) * 3.4 }, across: 10, y: { height($0) }) { t, s in
                0.05 + 0.1 * (1 - abs(s))
            })
            m.add(EnvKit.ribbon(material: "rock.scoria", line: line, width: { w($0) * 1.75 }, across: 16, y: { height($0) }) { t, s in
                let a = abs(s)
                return 0.12 + 0.55 * smoothstep(0.42, 0.7, a) * (1 - smoothstep(0.8, 1.0, a)) * (0.7 + 0.3 * sin(t * 61))
            })
            m.add(EnvKit.ribbon(material: "lava.molten", line: line, width: { w($0) }, across: 14, y: { height($0) }) { t, s in
                0.26 + 0.14 * sqrt(max(0, 1 - s * s))
            })
            scene.add(m)
            for k in stride(from: 6, to: line.count - 4, by: 24) {
                let p = line[k]
                lightSpots.append(V3(p.x, height(p) + 2.5, p.y))
            }
        }

        // Fountain over the crater: ballistic bombs frozen mid-flight, stretched along their heading.
        let bombHot = EnvKit.blob(V3(0.5, 0.5, 0.9), lump: 0.22, subdiv: 10, seed: 1, material: "lava.rivulet")
        let bombCool = EnvKit.blob(V3(0.5, 0.5, 0.85), lump: 0.3, subdiv: 10, seed: 2, material: "lava.crusted")
        var hot: [simd_float4x4] = [], cool: [simd_float4x4] = []
        let launch = V3(crater.x, lakeY + 1, crater.y)
        for _ in 0..<150 {
            let ang = rng.float(0...(2 * .pi)), spread = rng.float(0.05...0.5)
            let speed = rng.float(24...46)
            let v = V3(cos(ang) * sin(spread), cos(spread), sin(ang) * sin(spread)) * speed
            let tFlight = 2 * v.y / 9.8
            let t = rng.float(0.05...0.98) * tFlight
            let pos = launch + v * t + V3(0, -0.5 * 9.8 * t * t, 0)
            let vel = v + V3(0, -9.8 * t, 0)
            let s = rng.float(0.5...2.0)
            let age = t / tFlight
            let m = EnvKit.aligned(pos, heading: vel, scale: V3(s, s, s * (1.6 + 0.8 * (1 - age))))
            if age < 0.55 { hot.append(m) } else { cool.append(m) }
        }
        scene.field(model: Model(name: "bomb-hot", surfaces: [bombHot]), id: "bomb-hot", transforms: hot, options: .trees)
        scene.field(model: Model(name: "bomb-cool", surfaces: [bombCool]), id: "bomb-cool", transforms: cool, options: .trees)

        // Splatter on the banks: a molten puddle with radial streaks and satellite drops. Four variants, instanced.
        func splatter(_ k: UInt64) -> Model {
            var r2 = SeededRNG(seed: k)
            var m = Model(name: "splatter-\(k)")
            let hotMat: MaterialKey = k % 2 == 0 ? "lava.rivulet" : "lava.molten"
            m.add(EnvKit.blob(V3(0.55, 0.07, 0.5), lump: 0.25, subdiv: 10, seed: UInt32(k), material: hotMat), Xform(translation: V3(0, 0.03, 0)))
            let arms = r2.int(6...10)
            for a in 0..<arms {
                let ang = Float(a) / Float(arms) * 2 * .pi + r2.float(-0.25...0.25)
                let len = r2.float(0.5...1.6)
                let dir = V3(cos(ang), 0, sin(ang))
                var s = EnvKit.blob(V3(0.09, 0.035, len * 0.5), lump: 0.15, subdiv: 6, seed: UInt32(k) &+ UInt32(a), material: hotMat)
                s.positions = s.positions.map { V3($0.x * (1.1 - 0.7 * max(0, $0.z / max(len * 0.5, 0.01))), $0.y, $0.z) }
                m.add(s, Xform(translation: dir * (0.35 + len * 0.5) + V3(0, 0.02, 0), rotation: simd_quatf(angle: atan2(dir.x, dir.z), axis: .up)))
                for _ in 0..<r2.int(1...3) {
                    let d = (0.7 + len + r2.float(0.1...0.9))
                    let rr = r2.float(0.035...0.1)
                    m.add(EnvKit.blob(V3(rr, rr * 0.45, rr), lump: 0.2, subdiv: 5, seed: UInt32(k) &+ 40, material: hotMat),
                          Xform(translation: dir * d + V3(r2.float(-0.15...0.15), 0.01, r2.float(-0.15...0.15))))
                }
            }
            return m
        }
        let variants = (0..<4).map { splatter(UInt64(500 + $0)) }
        var splats = [[simd_float4x4]](repeating: [], count: 4)
        for _ in 0..<95 {
            let li = rng.int(0...2), line = lines[li]
            let k = rng.int((line.count / 3)...(line.count - 2))
            let p = line[k], q = line[k + 1]
            let tan = simd_normalize(q - p), side = V2(tan.y, -tan.x)
            let off = (rng.chance(0.5) ? 1 : -1) * rng.float(3.2...16)
            let at = p + side * off
            let ny = height(at)
            let sc = rng.float(0.9...2.6)
            splats[rng.int(0...3)].append(Xform(translation: V3(at.x, ny + 0.02, at.y), rotation: simd_quatf(angle: rng.float(0...(2 * .pi)), axis: .up), scale: V3(repeating: sc)).matrix)
        }
        for v in 0..<4 { scene.field(model: variants[v], id: "splatter-\(v)", transforms: splats[v], options: .groundCover(cull: 160)) }

        // Cooled scoria litter and bomb crust on the plain and flank, tinted dark.
        let scoria = [EnvKit.blob(V3(0.35, 0.22, 0.3), lump: 0.45, subdiv: 8, seed: 21, material: "rock.scoria"),
                      EnvKit.blob(V3(0.3, 0.25, 0.4), lump: 0.5, subdiv: 8, seed: 22, material: "rock.scoria"),
                      EnvKit.blob(V3(0.5, 0.3, 0.45), lump: 0.5, subdiv: 8, seed: 23, material: "rock.scoria")]
        var litter = [[simd_float4x4]](repeating: [], count: 3)
        let pts = Scatter.uniform(count: 700, outerRadius: 120, seed: seed &+ 31) { p in
            simd_length(p - V2(0, 20)) < 110 && riverDist(p) > 3.5
        }
        for p in pts {
            let c = V2(p.x, p.y + 20)
            let s = rng.float(0.5...2.4)
            litter[rng.int(0...2)].append(Xform(translation: V3(c.x, height(c) - 0.04 * s, c.y), rotation: simd_quatf(angle: rng.float(0...(2 * .pi)), axis: .up), scale: V3(repeating: s)).matrix)
        }
        for v in 0..<3 { scene.field(model: Model(name: "scoria-\(v)", surfaces: [scoria[v]]), id: "scoria-\(v)", transforms: litter[v], options: .groundCover(cull: 140)) }

        // Obsidian shards and large basalt blocks on the nearer plain.
        for (i, p) in Scatter.poisson(count: 12, outerRadius: 60, innerRadius: 6, minSpacing: 11, seed: seed &+ 41, accept: { riverDist($0 + V2(0, 20)) > 8 }).enumerated() {
            let c = V2(p.x, p.y + 20)
            scene.add(Boulder().with { $0.material = i % 3 == 0 ? "rock.obsidian" : "rock.basalt"; $0.size = V3(1.6, 1.1, 1.3) * rng.float(0.6...2.0) },
                      at: place(c.x, c.y, y: height(c) - 0.1, yaw: rng.float(0...360)), seed: seed &+ UInt64(60 + i))
        }

        // Spatter cones venting beside the channels: a scoria stack with a glowing mouth.
        for (i, li) in [(0, 0), (1, 1), (2, 2), (3, 0)].enumerated() {
            let line = lines[li.1]
            let k = Int(Float(line.count) * [0.52, 0.62, 0.7, 0.8][i])
            let p = line[k], q = line[k + 1]
            let tan = simd_normalize(q - p), side = V2(tan.y, -tan.x)
            let at = p + side * (i % 2 == 0 ? 11.0 : -12.5)
            let g = height(at)
            let prof: [V2] = [V2(0, 0), V2(3.4, 0), V2(2.7, 0.7), V2(1.7, 1.7), V2(1.2, 2.6), V2(1.35, 3.0), V2(0.9, 3.15), V2(0.0, 2.7)]
            var cone = Model(name: "spatter-cone-\(i)")
            cone.add(Prim.lathe(prof, segments: 36, seamTile: 0.5, material: "rock.scoria"))
            cone.add(EnvKit.disc(radius: 0.85, rings: 3, segments: 20, y: { _ in 2.8 }, material: "lava.rivulet"))
            scene.add(cone, at: place(at.x, at.y, y: g - 0.2, yaw: Float(i) * 70))
            lightSpots.append(V3(at.x, g + 4, at.y))
        }

        // Light: crater glow, fountain glare and a point light per river reach (budgeted by the renderer).
        scene.lights.append(RigLight(name: "crater", position: V3(crater.x, lakeY + 14, crater.y), color: V3(1, 0.42, 0.12), intensity: 60_000_000, attenuationRadius: 260))
        for (i, p) in lightSpots.enumerated() {
            scene.lights.append(RigLight(name: "lava-\(i)", position: p, color: V3(1, 0.4, 0.1), intensity: 12_000_000, attenuationRadius: 60))
        }

        scene.lighting.sky = SunSky(elevation: 3, azimuth: 262, turbidity: 6).with {
            $0.sunLux = 3500; $0.iblExposure = -0.7; $0.overcast = 0.78; $0.fogDensity = 0.0042; $0.fogBrightness = 0.7; $0.shadowDistance = 80; $0.cloudSeed = 4
        }

        let eye = V2(14, 46)
        let eyeY = height(eye) + 1.7
        scene.camera = .init(eye: V3(eye.x, eyeY, eye.y), target: V3(crater.x, lakeY + 12, crater.y), fov: 64)
        scene.spots = [.init("Ash plain", eye: V3(eye.x, eyeY, eye.y), target: V3(crater.x, lakeY + 12, crater.y)),
                       .init("River bank", eye: V3(-30, height(V2(-30, 40)) + 1.7, 40), target: V3(-10, 12, -20))]
        return scene
    }
}
