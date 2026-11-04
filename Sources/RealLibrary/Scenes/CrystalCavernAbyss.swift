import simd
import Foundation
import RealityKit
import RealKit

/// A cavern 140 m across with no floor in sight: a natural stone bridge 70 m long and barely 4 m wide arches over a pit that
/// ends in a glowing underground lake. Giant crystal clusters in cyan, magenta and amber grow from the walls and light the
/// rock, stalactites hang from a ceiling 45 m up, hand lanterns burn on the bridge. The cave shell is one displaced
/// cube-sphere seen from inside; crystals, stalactites and stalagmites are instanced.
public struct CrystalCavernAbyss: RealSceneBuilder {
    public static let id = "crystal-cavern-abyss"
    public static let summary = "Crystal cavern: natural stone bridge over a bottomless pit, glowing cyan, magenta and amber crystals, stalactites, lantern light."
    public static let tags = ["cave", "interior", "rock", "stone"]
    public static let author = "hunter"

    public var radii = V3(74, 46, 70)
    public init() {}

    public func build(seed: UInt64) -> RealScene {
        var scene = RealScene(name: Self.id)
        scene.farGround = nil
        var rng = SeededRNG(seed: seed &+ 99)
        let ns = UInt32(truncatingIfNeeded: seed)

        // Cave shell: lumpy ellipsoid with ridged wall relief and pinched pockets.
        func shellRadius(_ d: V3) -> Float {
            let n = Noise.fbm(d * 2.1 + V3(3, 1, 7), octaves: 4, seed: ns)
            let r = Noise.ridged(d * 4.3 + V3(1, 5, 2), octaves: 3, seed: ns &+ 1)
            let k = 1 + 0.22 * n + 0.07 * r
            // Squared-ellipsoid distance along d.
            let e = sqrt((d.x * d.x) / (radii.x * radii.x) + (d.y * d.y) / (radii.y * radii.y) + (d.z * d.z) / (radii.z * radii.z))
            return k / e
        }
        func shellPoint(_ d: V3) -> V3 { d * shellRadius(d) }
        var shell = Prim.cubeSphere(subdivisions: 90, material: "rock.cave") { d in shellPoint(d) }
        shell = EnvKit.inverted(shell)
        scene.add(Model(name: "cavern-shell", surfaces: [shell]))

        // Bridge: a rock arch, wider at the abutments, flattened into a walkway, crossing the cavern along X.
        let reach = min(shellRadius(V3(1, 0, 0)), shellRadius(V3(-1, 0, 0))) + 4
        let bridgeSpan = reach - 20
        func bridgeY(_ x: Float) -> Float { -0.9 * pow(min(abs(x), bridgeSpan) / bridgeSpan, 2) * 3 + 0.2 * sin(x * 0.4) }
        func bridgeZ(_ x: Float) -> Float { 0.8 * sin(x * 0.07) }
        let steps = 110
        var path: [V3] = []
        var radius: [Float] = []
        for i in 0...steps {
            let t = Float(i) / Float(steps)
            let x = lerp(-reach, reach, t)
            let r = 2.5 + 3.2 * smoothstep(0.55, 1.0, abs(x) / reach) + 0.45 * Noise.perlin(V3(x * 0.12, 0, 0), seed: ns &+ 4)
            radius.append(r)
            // Flattened by 0.5 in Y after building: pre-scale height keeps the crown at bridgeY.
            path.append(V3(x, 2 * bridgeY(x) - r, bridgeZ(x)))
        }
        let beam = Prim.tube(path, radii: radius, sides: 48, seamTile: 0.5, material: "rock.cave", rippling: { v, u in 0.18 * Noise.fbm(V3(v * 0.6, u * 4, 0), octaves: 3, seed: ns &+ 6) })
        var bridge = Model(name: "stone-bridge")
        bridge.add(beam, Xform(scale: V3(1, 0.5, 1)))
        // Walking surface: compacted gravel laid on the crown.
        let walk = EnvKit.ribbon(material: "ground.gravel", line: (0...90).map { i -> V2 in let x = lerp(-reach + 6, reach - 6, Float(i) / 90); return V2(x, bridgeZ(x)) },
                                 width: { _ in 2.4 }, across: 6, y: { p in bridgeY(p.x) - 0.02 }) { _, s in 0.07 * (1 - s * s) }
        bridge.add(walk)
        scene.add(bridge)

        // Stalactites from the ceiling and stalagmites on ledges: instanced rock spires, three variants.
        let spikes = (0..<3).map { EnvKit.spire(radius: 1.0, height: 1.0, sides: 40, wobble: 0.22, seed: UInt32(10 + $0), material: "rock.cave", curve: 0.85 + 0.25 * Float($0)) }
        var hang = [[simd_float4x4]](repeating: [], count: 3)
        var tries = 0
        while hang.reduce(0, { $0 + $1.count }) < 170 && tries < 4000 {
            tries += 1
            let a = rng.float(0...(2 * .pi)), y = rng.float(0.4...0.98)
            let d = simd_normalize(V3(cos(a) * sqrt(1 - y * y), y, sin(a) * sqrt(1 - y * y)))
            let p = shellPoint(d)
            let h = rng.float(2.5...13), r = h * rng.float(0.08...0.16)
            hang[rng.int(0...2)].append(Xform(translation: p + V3(0, 0.6, 0), rotation: simd_quatf(angle: .pi, axis: V3(1, 0, 0)), scale: V3(r, h, r)).matrix)
        }
        for v in 0..<3 { scene.field(model: Model(name: "stalactite-\(v)", surfaces: [spikes[v]]), id: "stalactite-\(v)", transforms: hang[v], options: .trees) }
        var rise = [[simd_float4x4]](repeating: [], count: 3)
        tries = 0
        while rise.reduce(0, { $0 + $1.count }) < 60 && tries < 4000 {
            tries += 1
            let a = rng.float(0...(2 * .pi)), y = rng.float(-0.6...(-0.1))
            let d = simd_normalize(V3(cos(a) * sqrt(1 - y * y), y, sin(a) * sqrt(1 - y * y)))
            let p = shellPoint(d)
            guard abs(p.z) > 14 || abs(p.x) > 44 else { continue }
            let h = rng.float(2.0...9), r = h * rng.float(0.1...0.18)
            rise[rng.int(0...2)].append(Xform(translation: p - V3(0, 0.5, 0), scale: V3(r, h, r)).matrix)
        }
        for v in 0..<3 { scene.field(model: Model(name: "stalagmite-\(v)", surfaces: [spikes[v]]), id: "stalagmite-\(v)", transforms: rise[v], options: .trees) }

        // Crystal clusters: three colours, two shapes each, grown along the wall normal. Small clusters instanced, giants as singles.
        let mats: [MaterialKey] = ["crystal.cyan", "crystal.magenta", "crystal.amber"]
        let lightColors: [V3] = [V3(0.1, 0.6, 1), V3(1, 0.15, 0.75), V3(1, 0.55, 0.12)]
        func cluster(_ m: MaterialKey, seed k: UInt64, big: Bool) -> Model {
            var r2 = SeededRNG(seed: k)
            var model = Model(name: "crystal-cluster")
            let n = big ? r2.int(9...14) : r2.int(5...9)
            for i in 0..<n {
                let tilt = i == 0 ? 0 : r2.float(0.15...0.7)
                let az = r2.float(0...(2 * .pi))
                let len = (i == 0 ? 1.0 : r2.float(0.35...0.85)) * (big ? 9 : 1.6)
                let rad = len * r2.float(0.11...0.17)
                let c = EnvKit.crystal(radius: rad, length: len, tip: rad * r2.float(1.4...2.4), sides: 6, material: m, twist: r2.float(-0.3...0.3), taper: r2.float(0.82...0.97))
                let q = simd_quatf(angle: az, axis: .up) * simd_quatf(angle: tilt, axis: V3(1, 0, 0))
                model.add(c, Xform(translation: V3(r2.float(-0.3...0.3), -0.2, r2.float(-0.3...0.3)) * (big ? 4 : 0.7), rotation: q))
            }
            return model
        }
        var lightSpots: [(V3, V3)] = []
        for (mi, m) in mats.enumerated() {
            for v in 0..<2 {
                var xs: [simd_float4x4] = []
                for _ in 0..<28 {
                    let a = rng.float(0...(2 * .pi)), y = rng.float(-0.55...0.8)
                    let d = simd_normalize(V3(cos(a) * sqrt(1 - y * y), y, sin(a) * sqrt(1 - y * y)))
                    let p = shellPoint(d)
                    let nrm = simd_normalize(-V3(d.x / (radii.x * radii.x), d.y / (radii.y * radii.y), d.z / (radii.z * radii.z)))
                    let up = V3(0, 1, 0)
                    let axis = simd_cross(up, nrm)
                    let ang = acos(simd_clamp(simd_dot(up, nrm), -1, 1))
                    let q = simd_length(axis) > 1e-4 ? simd_quatf(angle: ang, axis: simd_normalize(axis)) : .identity
                    xs.append(Xform(translation: p, rotation: q, scale: V3(repeating: rng.float(0.8...2.6))).matrix)
                }
                scene.field(model: cluster(m, seed: UInt64(900 + mi * 10 + v), big: false), id: "crystal-\(mi)-\(v)", transforms: xs, options: .trees)
            }
        }
        // Giants near the bridge: lit by a point light each.
        let giants: [(Int, V3, V3)] = [(0, V3(-30, -14, 30), V3(0.4, 1, -0.6)), (1, V3(26, -6, -34), V3(-0.3, 1, 0.5)), (2, V3(-58, 6, -16), V3(0.7, 0.8, 0.2)),
                                       (0, V3(52, -20, 24), V3(-0.5, 1, -0.3)), (1, V3(4, -38, 40), V3(0, 1, -0.3)), (2, V3(10, 30, -30), V3(0.1, -1, 0.2))]
        for (gi, g) in giants.enumerated() {
            let (mi, at0, dir0) = g
            let d = simd_normalize(at0)
            let p = shellPoint(d)
            let dir = simd_normalize(dir0)
            let up = V3(0, 1, 0), axis = simd_cross(up, dir)
            let q = simd_length(axis) > 1e-4 ? simd_quatf(angle: acos(simd_clamp(simd_dot(up, dir), -1, 1)), axis: simd_normalize(axis)) : simd_quatf.identity
            scene.add(cluster(mats[mi], seed: UInt64(1200 + gi), big: true), at: Xform(translation: p, rotation: q, scale: V3(repeating: 1.0 + 0.25 * Float(gi % 3))))
            lightSpots.append((p + dir * 7, lightColors[mi]))
        }
        for (p, c) in lightSpots {
            scene.lights.append(RigLight(name: "crystal-\(scene.lights.count)", position: p, color: c, intensity: 4_000_000, attenuationRadius: 90))
        }

        // The pit's floor: a lake that glows teal, far below the bridge.
        var lake = Model(name: "abyss-lake")
        lake.add(EnvKit.disc(radius: 32, center: .zero, rings: 10, segments: 48, y: { p in -radii.y * 0.78 + 0.4 * Noise.fbm(V3(p.x * 0.2, 0, p.y * 0.2), octaves: 2, seed: ns) }, material: "emissive.abyss-lake"))
        scene.add(lake)
        scene.lights.append(RigLight(name: "lake", position: V3(0, -radii.y * 0.7, 0), color: V3(0.1, 0.8, 0.7), intensity: 1_500_000, attenuationRadius: 90))

        // Lanterns on posts along the bridge.
        for (i, x) in [-24, -8, 10, 28].enumerated() {
            let px = Float(x), z: Float = (i % 2 == 0 ? 1.0 : -1.0) * 1.15
            let y = bridgeY(px) + 0.04
            scene.add(CampLantern(), at: place(px, z + bridgeZ(px), y: y, yaw: Float(i) * 40), seed: seed &+ UInt64(i))
            scene.lights.append(RigLight(name: "lantern-\(i)", position: V3(px, y + 0.5, z + bridgeZ(px)), color: V3(1, 0.62, 0.28), intensity: 6_000, attenuationRadius: 14))
        }

        scene.lighting.interior = InteriorLight().with {
            $0.ceiling = SIMD3(1.2, 1.4, 2.2); $0.walls = SIMD3(1.4, 1.5, 2.4); $0.floor = SIMD3(0.6, 1.0, 1.3)
            $0.fixtures = SIMD3(0, 0, 0); $0.windowWidth = 0; $0.windowElevation = 0...0; $0.windowSky = .zero; $0.windowGround = .zero; $0.exposure = 0.6
        }
        scene.lighting.sky = SunSky(elevation: -20, azimuth: 0, turbidity: 2).with { $0.sunLux = 0; $0.fogDensity = 0.002; $0.fogBrightness = 0.3; $0.iblExposure = -2 }
        scene.lighting.fog = 0.002
        let eye = V3(-18, bridgeY(-18) + 1.7, bridgeZ(-18))
        scene.camera = .init(eye: eye, target: V3(40, -2, 2), fov: 74)
        scene.spots = [.init("Bridge", eye: eye, target: V3(40, -2, 2)),
                       .init("Abutment", eye: V3(-50, 1.7, 0.4), target: V3(0, -12, 2))]
        return scene
    }
}
