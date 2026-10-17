import simd
import Foundation

/// Queen Anne Victorian spindle frieze: 29 lathe-turned ball-and-ring spindles tenoned between a top rail
/// with cove, ovolo and fillet cap moulding and a chamfered bottom rail, dowel-pegged at the bottom rail.
/// Pierced sawn corner brackets hang at both ends and a turned pendant drop on a block hangs at the center.
/// Polychrome paint (sage rails, cream spindles, oxblood brackets) with flaking, stains and one bare replacement spindle.
public struct QueenAnneSpindleFrieze: RealAsset {
    public static let id = "queen-anne-spindle-frieze"
    public static let summary = "Queen Anne spindle frieze, 2.4 m: turned spindles between a top rail and a bottom rail, with sawn corner brackets and a central drop."
    public static let tags = ["prop", "architecture", "facade", "trim", "wood", "decor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 18, elevation: 6, distance: 3.4)

    /// Frieze length in meters.
    public var length: Float = 2.4
    /// Number of turned spindles.
    public var spindles = 29
    /// Rail paint (sage green).
    public var railPaint: MaterialKey = "wood.painted-exterior:6F7C5E"
    /// Spindle paint (cream).
    public var spindlePaint: MaterialKey = "wood.painted-exterior:DDD2B4"
    /// Bracket and pendant paint (oxblood).
    public var accentPaint: MaterialKey = "wood.painted-exterior:80362B"
    /// Bare wood showing through flaked paint.
    public var bare: MaterialKey = "wood.weathered"
    /// Dowel peg material.
    public var peg: MaterialKey = "wood.oak:8A6642"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [5])
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = length, hl = L / 2
        let yb0: Float = 0.13, yb1: Float = 0.17        // bottom rail
        let yt0: Float = 0.37, yt1: Float = 0.45        // top rail
        // Top rail with cap moulding: profile x = depth (wall at -0.04), y up. Cove, ovolo bead and fillet.
        var cap: [V2] = [V2(-0.04, yt0), V2(0.028, yt0), V2(0.030, yt0 + 0.003), V2(0.030, yt0 + 0.046), V2(0.034, yt0 + 0.049), V2(0.034, yt0 + 0.055)]
        for i in 0...6 { let t = Float(i) / 6; cap.append(V2(0.030 + 0.012 * sin(t * .pi / 2), yt0 + 0.058 + 0.016 * (1 - cos(t * .pi / 2)))) } // cove
        cap += [V2(0.042, yt1 - 0.004), V2(0.039, yt1), V2(-0.04, yt1)]
        FA.run(&m, cap, length: L, at: .zero, railPaint, bevel: 0.0015)
        // Bottom rail with chamfered top edge.
        FA.run(&m, [V2(-0.035, yb0), V2(0.032, yb0), V2(0.032, yb1 - 0.012), V2(0.025, yb1), V2(-0.035, yb1)], length: L, at: .zero, railPaint, bevel: 0.0015)
        // Turned spindles: half profile (radius, y) mirrored about the waist, tenons into both rails.
        let half: [(Float, Float)] = [(0, 0), (0.0075, 0), (0.0075, 0.008), (0.012, 0.008), (0.0135, 0.016), (0.0135, 0.024), (0.0095, 0.034),
                                      (0.0085, 0.050), (0.0095, 0.062), (0.0165, 0.080), (0.0178, 0.092), (0.0125, 0.103), (0.0070, 0.108)]
        let full = half + half.dropLast().reversed().map { (r, y) in (r, 0.216 - y) }
        let sp = (L - 0.12) / Float(spindles - 1)
        let y0 = yb1 - 0.008
        let bareIndex = 18
        for i in 0..<spindles {
            let x = -hl + 0.06 + Float(i) * sp
            let mat: MaterialKey = i == bareIndex ? bare : spindlePaint
            m.add(turned(full, segments: lite ? 5 : 8, material: mat, seamTile: 0.2, grainVertical: true),
                  Xform(translation: V3(x, y0, 0), rotation: FA.q(rng.float(-0.5...0.5), FA.Z)))
            if !lite && i % 2 == 0 { FA.cylZ(&m, r: 0.0035, h: 0.0025, at: V3(x, 0.15, 0.0305), peg, bevel: 0.0008, segments: 8) }
        }
        // Sawn corner brackets under the bottom rail: concave inner edge, pierced eye, scroll toe.
        for e: Float in [-1, 1] {
            // u = distance inward from the post; concave sawn edge is a quadratic curve pulled toward the corner.
            var o: [V2] = [V2(0, yb0), V2(0.2, yb0)]
            for i in 1...14 {
                let t = Float(i) / 14, u = 1 - t
                o.append(V2(0.2 * u * u + 0.03 * 2 * u * t, yb0 * u * u + 0.09 * 2 * u * t))
            }
            let pts = o.map { V2(e * (hl - $0.x), $0.y) }
            let eye = Shape2D.deduped((0..<16).map { i -> V2 in let a = Float(i) / 16 * 2 * .pi; return V2(e * (hl - 0.045) + cos(a) * 0.012, 0.10 + sin(a) * 0.012) })
            m.add(HTKit.plate(outer: pts, holes: [eye], depth: 0.026, bevel: 0.003, segments: 1, material: accentPaint), Xform(translation: V3(0, 0, 0)))
            FA.cylZ(&m, r: 0.004, h: 0.0025, at: V3(e * (hl - 0.03), 0.115, 0.0125), peg, bevel: 0.0008, segments: 8)
        }
        // Center pendant: block under the bottom rail, then a turned drop ending in an acorn.
        FA.box(&m, V3(0.07, 0.034, 0.05), V3(0, yb0 - 0.017, 0), accentPaint, r: 0.003)
        m.add(turned([(0, 0), (0.005, 0), (0.012, 0.012), (0.019, 0.030), (0.020, 0.044), (0.014, 0.060), (0.009, 0.068), (0.012, 0.074), (0.014, 0.082), (0.012, 0.090), (0.007, 0.096), (0.006, 0.100), (0.0, 0.100)],
                     segments: 14, material: accentPaint, seamTile: 0.2, grainVertical: true), Xform(translation: V3(0, 0.0, 0)))
        FA.cylZ(&m, r: 0.004, h: 0.0025, at: V3(0, yb0 - 0.01, 0.0255), peg, bevel: 0.0008, segments: 8)
        // Weathering: flaked paint patches on the rails, drip stains under the cap, grime band at the bottom rail.
        for i in 0..<(lite ? 0 : 18) {
            let top = i % 2 == 0
            let cx = rng.float(-hl + 0.1...hl - 0.1), cy = top ? rng.float(yt0 + 0.012...yt0 + 0.04) : rng.float(yb0 + 0.006...yb1 - 0.014)
            let rx = rng.float(0.015...0.045), ry = rng.float(0.006...0.012)
            var poly: [V2] = []
            for j in 0..<7 { let a = Float(j) / 7 * 2 * .pi; poly.append(V2(cx + cos(a) * rx * rng.float(0.6...1.1), cy + sin(a) * ry * rng.float(0.6...1.1))) }
            let zf: Float = top ? 0.0402 - 0.0 : 0.0322
            m.add(HTKit.plate(outer: poly, depth: 0.001, bevel: 0.0002, segments: 1, material: i % 3 == 0 ? "wood.deadwood" : bare),
                  Xform(translation: V3(0, 0, top ? 0.0305 : zf)))
        }
        groundAO(&m, height: 0.2, floor: 0.8)
        return FC.place(m)
    }
}
