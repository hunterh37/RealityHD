import simd
import Foundation
import RealKit

/// Planting for `mulberry-river`: riparian sycamore and river birch on the banks, oak and shortleaf pine on
/// the hills, river cane brakes on the south flats, grass and ferns under the canopy.
enum MulberryVegetation {
    static func add(to scene: inout RealScene, reach: MulberryRiverReach, seed: UInt64, rng: inout SeededRNG) {
        let path = reach.path, L = path.length
        let ns = UInt32(truncatingIfNeeded: seed) &+ 5
        func y(_ p: V2) -> Float { reach.height(p, seed: seed) }
        func edge(_ p: V2) -> Float { abs(path.lateral(p).offset) - path.sample(atX: p.x).width / 2 }
        func north(_ p: V2) -> Bool { path.lateral(p).offset < 0 }
        func xf(_ p: V2, scale: ClosedRange<Float>, sink: Float, lean: Float = 0) -> simd_float4x4 {
            var r = simd_quatf(degrees: rng.float(0...360), axis: .up)
            if lean > 0 {
                // Bank trees lean out over the water.
                let toward: Float = north(p) ? 1 : -1
                r = simd_quatf(degrees: lean * toward, axis: V3(1, 0, 0)) * r
            }
            return Xform(translation: V3(p.x, y(p) - sink, p.y), rotation: r, scale: V3(repeating: rng.float(scale))).matrix
        }
        func onBluffFace(_ p: V2) -> Bool { north(p) && reach.bluffWeight(p.x) > 0.3 && edge(p) < 4.5 }
        func onBluffFaceTop(_ p: V2) -> Bool { north(p) && reach.bluffWeight(p.x) > 0.5 }
        func onBar(_ p: V2) -> Bool { !north(p) && reach.barWeight(p.x) > 0.3 && edge(p) < 16 }

        // Jittered grid over the valley.
        func grid(spacing: Float, band: ClosedRange<Float>, keep: Float, accept: (V2) -> Bool = { _ in true }) -> [V2] {
            var out: [V2] = []
            for x in stride(from: -L / 2 - 8, through: L / 2 + 8, by: spacing) {
                for o in stride(from: -reach.valleyWidth / 2 + 4, through: reach.valleyWidth / 2 - 4, by: spacing) {
                    let p = V2(x + rng.float(-0.45...0.45) * spacing, path.sample(atX: x).center.y + o + rng.float(-0.45...0.45) * spacing)
                    let e = edge(p)
                    if !band.contains(e) || !rng.chance(keep) || !accept(p) { continue }
                    out.append(p)
                }
            }
            return out
        }

        // Riparian band: sycamores and river birch, leaning toward the river at the water's edge.
        var syc: [[simd_float4x4]] = [[], [], []], birch: [[simd_float4x4]] = [[], []]
        for p in grid(spacing: 9, band: 1.5...16, keep: 0.75, accept: { !onBluffFace($0) && !onBar($0) }) {
            let v = rng.int(0...2)
            let lean: Float = edge(p) < 5 ? rng.float(3...10) : 0
            if rng.chance(0.55) { syc[v].append(xf(p, scale: 0.75...1.15, sink: 0.15, lean: lean)) }
            else { birch[v % 2].append(xf(p, scale: 0.8...1.1, sink: 0.12, lean: lean)) }
        }
        for v in 0..<3 { scene.field(SycamoreTree(), seed: seed &+ UInt64(100 + v), transforms: syc[v], options: .trees) }
        for v in 0..<2 { scene.field(RiverBirch(), seed: seed &+ UInt64(110 + v), transforms: birch[v], options: .trees) }

        // Hills and the bluff top: oak-hickory with shortleaf pine on the drier slopes.
        var oak: [[simd_float4x4]] = [[], [], []], pine: [[simd_float4x4]] = [[], [], []], sycHill: [simd_float4x4] = []
        for p in grid(spacing: 11, band: 14...112, keep: 0.8, accept: { !onBar($0) }) {
            let v = rng.int(0...2), dry = y(p) > 12 || Noise.perlin(V3(p.x * 0.02, 3, p.y * 0.02), seed: ns) > 0.15
            if dry && rng.chance(0.6) { pine[v].append(xf(p, scale: 0.8...1.15, sink: 0.1)) }
            else if rng.chance(0.85) { oak[v].append(xf(p, scale: 0.9...1.5, sink: 0.1)) }
            else { sycHill.append(xf(p, scale: 0.8...1.0, sink: 0.15)) }
        }
        for p in grid(spacing: 8, band: 4...14, keep: 0.8, accept: onBluffFaceTop) { pine[0].append(xf(p, scale: 0.7...1.0, sink: 0.1)) }
        for v in 0..<3 {
            scene.field(OakTree(), seed: seed &+ UInt64(120 + v), transforms: oak[v], options: .trees)
            scene.field(ShortleafPine(), seed: seed &+ UInt64(130 + v), transforms: pine[v], options: .trees)
        }
        scene.field(SycamoreTree().with { $0.height = 20 }, seed: seed &+ 140, transforms: sycHill, options: .trees)

        // River cane brakes on the low south flats, in patches.
        var cane: [simd_float4x4] = []
        for p in grid(spacing: 1.6, band: 1...12, keep: 0.9, accept: { p in
            !north(p) && !onBar(p) && Noise.perlin(V3(p.x * 0.05, 7, p.y * 0.05), seed: ns &+ 1) > 0.12 }) {
            cane.append(xf(p, scale: 0.8...1.2, sink: 0.03))
        }
        scene.field(RiverCane(), seed: seed &+ 150, transforms: cane, options: .trees)

        // Ground cover on the banks; nothing on the bar, the bluff face or below the waterline.
        let cover = RealInstancing.Options.groundCover(cull: 40)
        var grass: [simd_float4x4] = [], ferns: [simd_float4x4] = []
        for p in grid(spacing: 1.3, band: 1.2...30, keep: 0.6, accept: { !onBar($0) && !onBluffFace($0) }) {
            if Noise.perlin(V3(p.x * 0.08, 9, p.y * 0.08), seed: ns &+ 2) > 0.05 { ferns.append(xf(p, scale: 0.7...1.2, sink: 0.02)) }
            else { grass.append(xf(p, scale: 0.7...1.2, sink: 0.02)) }
        }
        scene.field(GrassClump().with { $0.height = 0.45 }, seed: seed &+ 160, transforms: grass, options: cover)
        scene.field(Fern(), seed: seed &+ 161, transforms: ferns, options: cover)
    }
}
