import simd
import Foundation
import RealKit

/// Riverbed dressing for `mulberry-river`, one design per fishing spot:
/// bluff pool (fallen limestone blocks under algae, silt, sunken logs), riffles (algae boulder gardens and
/// mossy rocks), gravel eddy (wild celery beds over stones), logjam (sunken logs, root wads, brush piles) and
/// tailout (an abandoned low-water bridge with its collapsed span, weed beds downstream).
enum MulberryUnderwater {
    static func add(to scene: inout RealScene, reach: MulberryRiverReach, seed: UInt64) {
        var rng = SeededRNG(seed: seed &+ 7_301)
        let path = reach.path
        func y(_ p: V2) -> Float { reach.height(p, seed: seed) }
        func off(_ x: Float) -> (c: Float, w: Float) { let s = path.sample(atX: x); return (s.center.y, s.width) }
        /// Bed point at x with lateral fraction f (-1 north bank ... 1 south bank).
        func bed(_ x: Float, _ f: Float) -> V2 { let o = off(x); return V2(x, o.c + f * o.w / 2) }
        func submerged(_ p: V2, by d: Float = 0.25) -> Bool { path.bedDepth(p) > d }
        func xf(_ p: V2, scale: V3, sink: Float, yaw: Float? = nil, tilt: Float = 0) -> simd_float4x4 {
            let r = simd_quatf(degrees: yaw ?? rng.float(0...360), axis: .up) * simd_quatf(degrees: rng.float(-tilt...tilt), axis: V3(1, 0, 0))
            return Xform(translation: V3(p.x, y(p) - sink, p.y), rotation: r, scale: scale).matrix
        }
        func flowYaw(_ x: Float) -> Float { let s = path.sample(atX: x); return -atan2(s.tangent.y, s.tangent.x) * 180 / .pi }

        // 1. Bluff pool: limestone blocks fallen from the bluff into deep water, algae on top; silt between.
        var blocks: [simd_float4x4] = [], poolStones: [simd_float4x4] = [], poolLogs: [V2] = []
        for _ in 0..<70 {
            let x = rng.float(-92...6), p = bed(x, rng.float(-0.98...(-0.2)))
            guard submerged(p, by: 0.6) else { continue }
            let k = rng.float(0.7...2.2)
            blocks.append(xf(p, scale: V3(k * rng.float(0.9...1.4), k * rng.float(0.5...0.8), k), sink: 0.25 * k, tilt: 14))
        }
        for _ in 0..<50 {
            let x = rng.float(-92...6), p = bed(x, rng.float(-0.8...0.7))
            guard submerged(p, by: 0.8) else { continue }
            poolStones.append(xf(p, scale: V3(repeating: rng.float(0.5...1.3)), sink: 0.08))
        }
        for x in [Float(-70), -52, -31, -14] { poolLogs.append(bed(x + rng.float(-4...4), rng.float(-0.7...(-0.3)))) }
        scene.field(Boulder().with { $0.material = "rock.limestone-algae"; $0.facets = 12; $0.lodDistances = [6, 20] }, seed: seed &+ 301, transforms: blocks, options: .submerged())
        scene.field(SubmergedBoulder(), seed: seed &+ 302, transforms: poolStones, options: .submerged())
        for (i, p) in poolLogs.enumerated() {
            scene.add(SunkenLog().with { $0.length = rng.float(5...8); $0.buttDiameter = rng.float(0.5...0.75) },
                      at: Xform(translation: V3(p.x, y(p) - 0.05, p.y), rotation: simd_quatf(degrees: flowYaw(p.x) + rng.float(-40...40), axis: .up)),
                      seed: seed &+ UInt64(310 + i))
        }

        // 2. Riffles: dense algae boulder garden, moss-capped rocks along the edges.
        var riffle: [simd_float4x4] = [], riffleBig: [simd_float4x4] = [], edgeMoss: [simd_float4x4] = []
        for range in [Float(-150)...(-104), 60...86, 166...186] {
            for _ in 0..<150 {
                let x = rng.float(range), p = bed(x, rng.float(-0.95...0.95))
                guard submerged(p, by: 0.05) else { continue }
                if rng.chance(0.18) { riffleBig.append(xf(p, scale: V3(repeating: rng.float(0.7...1.2)), sink: 0.12)) }
                else { riffle.append(xf(p, scale: V3(repeating: rng.float(0.3...0.65)), sink: 0.05)) }
            }
            for _ in 0..<26 {
                let x = rng.float(range), side: Float = rng.chance(0.5) ? -1 : 1, p = bed(x, side * rng.float(0.85...1.1))
                edgeMoss.append(xf(p, scale: V3(repeating: rng.float(0.45...0.9)), sink: 0.15))
            }
        }
        scene.field(SubmergedBoulder(), seed: seed &+ 320, transforms: riffle, options: .submerged(cull: 50))
        scene.field(SubmergedBoulder().with { $0.size = V3(1.3, 0.75, 1.0); $0.upstream = 0.6 }, seed: seed &+ 321, transforms: riffleBig, options: .submerged())
        scene.field(MossyRock().with { $0.material = "rock.algae-wet" }, seed: seed &+ 322, transforms: edgeMoss, options: .submerged())

        // 3. Gravel eddy: wild celery beds over the slack water behind the bar, stones between.
        var celery: [simd_float4x4] = [], eddyStones: [simd_float4x4] = []
        for _ in 0..<160 {
            let x = rng.float(14...56), p = bed(x, rng.float(-0.1...0.9))
            guard submerged(p, by: 0.35) else { continue }
            celery.append(xf(p, scale: V3(repeating: rng.float(0.8...1.5)), sink: 0.02, yaw: flowYaw(x) + rng.float(-15...15)))
        }
        for _ in 0..<40 {
            let x = rng.float(14...56), p = bed(x, rng.float(-0.4...0.9))
            guard submerged(p) else { continue }
            eddyStones.append(xf(p, scale: V3(repeating: rng.float(0.8...1.3)), sink: 0.03))
        }
        scene.field(EelgrassBed(), seed: seed &+ 330, transforms: celery, options: .groundCover(cull: 45))
        scene.field(RiverStones().with { $0.wet = true }, seed: seed &+ 331, transforms: eddyStones, options: .groundCover(cull: 45))

        // 4. Logjam: sunken trunks with root wads and brush piles under the floating jam.
        let lj = path.spots["logjam"]!
        for i in 0..<6 {
            let p = V2(lj.x - 9 + Float(i) * 3.6 + rng.float(-1...1), lj.z + rng.float(-3...3))
            guard submerged(p) else { continue }
            scene.add(SunkenLog().with { $0.length = rng.float(4.5...8); $0.buttDiameter = rng.float(0.45...0.8) },
                      at: Xform(translation: V3(p.x, y(p) - 0.05, p.y), rotation: simd_quatf(degrees: flowYaw(p.x) + rng.float(-55...55), axis: .up)
                                * simd_quatf(degrees: rng.float(-6...6), axis: V3(0, 0, 1))),
                      seed: seed &+ UInt64(340 + i))
        }
        for i in 0..<4 {
            let p = V2(lj.x - 6 + Float(i) * 4 + rng.float(-1.5...1.5), lj.z + rng.float(-1...4))
            guard submerged(p, by: 1.2) else { continue }
            scene.add(BrushPile(), at: Xform(translation: V3(p.x, y(p) - 0.08, p.y), rotation: simd_quatf(degrees: rng.float(0...360), axis: .up)),
                      seed: seed &+ UInt64(350 + i))
        }

        // 5. Tailout: abandoned low-water bridge across the run above the tailout riffle, celery downstream.
        let bx: Float = 154
        let bc = bed(bx, 0.12)
        let deckTop: Float = -0.32
        let bridge = LowWaterBridge().with { $0.span = 14; $0.deckHeight = max(0.9, deckTop - y(bc) + 0.25) }
        scene.add(bridge, at: Xform(translation: V3(bc.x, deckTop - bridge.deckHeight, bc.y), rotation: simd_quatf(degrees: flowYaw(bx) + 4, axis: .up)),
                  seed: seed &+ 360)
        var tail: [simd_float4x4] = [], scour: [simd_float4x4] = []
        for _ in 0..<70 {
            let x = rng.float(158...172), p = bed(x, rng.float(-0.8...0.8))
            guard submerged(p, by: 0.3) else { continue }
            tail.append(xf(p, scale: V3(repeating: rng.float(0.7...1.3)), sink: 0.02, yaw: flowYaw(x) + rng.float(-15...15)))
        }
        for _ in 0..<30 {
            let x = rng.float(146...152), p = bed(x, rng.float(-0.8...0.8))
            scour.append(xf(p, scale: V3(repeating: rng.float(0.6...1.1)), sink: 0.1))
        }
        scene.field(EelgrassBed().with { $0.height = 0.7; $0.streaming = 0.9 }, seed: seed &+ 361, transforms: tail, options: .groundCover(cull: 45))
        scene.field(SubmergedBoulder(), seed: seed &+ 362, transforms: scour, options: .submerged())
    }
}
