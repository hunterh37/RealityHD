import simd
import Foundation

/// Brick stoop with iron rails: architectural facade customizer, Federal. Brick cheek walls on a stone water
/// table, marble steps and landing, wrought iron handrails with square balusters and lyre scrolls, newels
/// topped with cast urns.
public struct BrickStoopWithIronRails: RealAsset {
    public static let id = "brick-stoop-with-iron-rails"
    public static let summary = "Federal brick stoop 1.8 m: brick cheek walls on a stone water table, marble steps, and wrought iron rails with lyre scrolls and urn newels."
    public static let tags = ["prop", "architecture", "facade", "metal", "stone"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 18, distance: 4.5)

    /// Riser height in meters.
    public var rise: Float = 0.14
    /// Rail and baluster iron.
    public var iron: MaterialKey = "metal.wrought-iron"
    /// Newel and urn iron.
    public var castIron: MaterialKey = "metal.cast-iron-worn"
    /// Step and landing stone.
    public var steps: MaterialKey = "stone.limestone"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 1.8, D: Float = 1.6
        let cheekW: Float = 0.2, cheekX = W / 2 - cheekW / 2
        let treadW = W - 2 * cheekW - 0.02
        let tt: Float = 0.06, nose: Float = 0.03
        let z0 = -D / 2
        // Step edges along z: tread 1 front, tread 2 (landing) front.
        let go: Float = 0.3
        let z1 = z0, z2 = z0 + go, z3 = z0 + 2 * go
        let top1 = rise, top2 = 2 * rise, top3 = 3 * rise
        let ch: Float = 0.1  // cheek wall rises above tread tops
        let waterH: Float = 0.1
        func treadTop(_ z: Float) -> Float { z < z2 ? top1 : (z < z3 ? top2 : top3) }
        // Cheek profile in (z, y).
        let cheekProfile: [V2] = [V2(z1, 0), V2(z1, top1 + ch - 0.03), V2(z2, top1 + ch - 0.03), V2(z2, top2 + ch - 0.03), V2(z3, top2 + ch - 0.03), V2(z3, top3 + ch - 0.03), V2(D / 2, top3 + ch - 0.03), V2(D / 2, 0)]
        for e: Float in [-1, 1] {
            FA.run(&m, cheekProfile, length: cheekW - 0.012, at: V3(e * cheekX, 0, 0), "brick.red", bevel: 0.004)
            // Stone water table around the foot.
            FA.box(&m, V3(cheekW + 0.02, waterH, D + 0.02), V3(e * cheekX, waterH / 2, 0), "stone.limestone", r: 0.008)
            // Cap stones over each cheek section with a drip.
            for (za, zb, th) in [(z1, z2, top1), (z2, z3, top2), (z3, D / 2, top3)] {
                let lenz = zb - za + (za == z1 ? 0.02 : 0.0)
                FA.box(&m, V3(cheekW + 0.03, 0.04, lenz - 0.004), V3(e * cheekX, th + ch - 0.01, (za + zb) / 2 - (za == z1 ? 0.01 : 0)), "stone.cap", r: 0.01)
            }
        }
        // Brick core between cheeks beneath the treads (parged).
        FA.run(&m, [V2(z1 + 0.03, 0), V2(z1 + 0.03, top1 - tt), V2(z2, top1 - tt), V2(z2, top2 - tt), V2(z3, top2 - tt), V2(z3, top3 - tt), V2(D / 2, top3 - tt), V2(D / 2, 0)], length: treadW, "brick.red", bevel: 0.003)
        // Limestone treads with rounded nosings, risers set 4 mm behind them.
        let edges: [(Float, Float, Float)] = [(z1, z2, top1), (z2, z3, top2), (z3, D / 2, top3)]
        for (k, (za, zb, th)) in edges.enumerated() {
            let len = zb - za + nose + 0.02
            FA.box(&m, V3(treadW, tt + (k == 2 ? 0.01 : 0), len), V3(0, th - (tt + (k == 2 ? 0.01 : 0)) / 2, za - nose + len / 2), steps, r: 0.012, rot: FA.q(rng.float(-0.3...0.3), FA.X))
            let below = k == 0 ? 0 : edges[k - 1].2
            FA.box(&m, V3(treadW - 0.01, th - below - tt + 0.004, 0.04), V3(0, below + (th - below - tt) / 2 + 0.002 - 0.002, za + 0.012), k == 1 ? "stone.limestone-sooted" : steps, r: 0.006)
            FE.patch(&m, V3(rng.float(-0.1...0.1), th + 0.001, za + 0.17), V3(0.8, 0.004, 0.2), "stone.limestone-sooted")
        }
        for _ in 0..<5 {
            let e: Float = rng.chance(0.5) ? 1 : -1
            FE.patch(&m, V3(e * (cheekX + rng.float(-0.05...0.05)), waterH + 0.01, rng.float(z1 + 0.1...D / 2 - 0.2)), V3(0.03, 0.03, rng.float(0.1...0.2)))
        }
        // Iron rails. Handrail follows the stair pitch, then runs level over the landing.
        let railH: Float = 0.46
        func railY(_ z: Float) -> Float {
            let base = top3 + ch + railH - 0.02
            if z >= z3 + 0.05 { return base }
            let lo = top1 + ch + railH - 0.02
            let t = max(0, (z - (z1 + 0.04)) / (z3 + 0.05 - (z1 + 0.04)))
            return lo + t * (base - lo)
        }
        func capY(_ z: Float) -> Float { treadTop(z) + ch + 0.01 }
        let zf = z1 + 0.05, zb = D / 2 - 0.05
        for e: Float in [-1, 1] {
            let x = e * cheekX
            let hr = [V3(x, railY(zf), zf), V3(x, railY(z3 + 0.05), z3 + 0.05), V3(x, railY(zb), zb)]
            m.add(Prim.tube(hr, radii: [0.017, 0.017, 0.017], sides: 12, seamTile: 0.15, material: iron, capEnd: true))
            // Bottom rail shoe: flat bar following the cap line.
            FA.rod(&m, V3(x, capY(zf) + 0.03, zf), V3(x, capY(z3 - 0.02) + 0.03, z3 - 0.02), r: 0.009, iron, sides: 8)
            FA.box(&m, V3(0.018, 0.02, zb - z3), V3(x, top3 + ch + 0.04, (zb + z3) / 2), iron, r: 0.004)
            // Square balusters, pitched with the rail.
            var z = zf + 0.05
            while z < zb - 0.02 {
                let base = capY(z) + 0.02
                let h = railY(z) - 0.017 - base
                FA.box(&m, V3(0.014, h, 0.014), V3(x, base + h / 2, z), iron, r: 0.002)
                if rng.chance(0.35) { FA.box(&m, V3(0.02, 0.03, 0.02), V3(x, base + 0.015, z), "metal.rust", r: 0.004) }
                z += 0.105
            }
            // Lyre scroll in the landing panel: two C scrolls mirrored.
            let cz = (z3 + zb) / 2 + 0.05, cy = top3 + ch + 0.24
            FA.rod(&m, V3(x, cy - 0.11, cz), V3(x, cy, cz), r: 0.0055, iron, sides: 8)
            for s: Float in [-1, 1] {
                var pts: [V3] = []
                let R: Float = 0.075
                for k in 0...28 {
                    let t = Float(k) / 28
                    let ang = t * 3.0 * Float.pi
                    let r = R * (1 - 0.8 * t)
                    // Start at the shared point, rise and curl outward to the side s.
                    let zz = cz + s * (R + (-r) * cos(ang)) * 1.0
                    let yy = cy + r * sin(ang)
                    pts.append(V3(x, yy, zz))
                }
                FA.path(&m, pts, r: 0.0055, iron, sides: 8)
            }
            // Newels at the foot and at the landing back, with urn finials.
            for (nz, nb) in [(zf - 0.0, top1 + ch + 0.02), (zb, top3 + ch + 0.02)] {
                FA.box(&m, V3(0.04, railY(nz) - nb - 0.02, 0.04), V3(x, nb + (railY(nz) - nb - 0.02) / 2, nz), castIron, r: 0.006)
                FE.turn(&m, [V2(0.0, 0), V2(0.03, 0), V2(0.032, 0.012), V2(0.02, 0.025), V2(0.014, 0.04), V2(0.026, 0.07), V2(0.03, 0.095), V2(0.016, 0.12), V2(0.022, 0.13), V2(0, 0.14)],
                        at: V3(x, railY(nz) - 0.03, nz), castIron, segments: 20)
            }
        }
        // Bolts through the newel feet and a rust-weeping stain on the cap below the rail.
        for e: Float in [-1, 1] {
            for (nz, nb) in [(zf, top1 + ch + 0.02), (zb, top3 + ch + 0.02)] {
                FA.cylZ(&m, r: 0.012, h: 0.006, at: V3(e * cheekX, nb + 0.01, nz - 0.021), "metal.rust", bevel: 0.001, segments: 8)
            }
        }
        m = FE.seat(m)
        groundAO(&m, height: 0.12, floor: 0.6)
        return LODModel(m)
    }
}
