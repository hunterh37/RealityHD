import simd
import Foundation

/// Stone steps with risers: architectural facade customizer, Vernacular. Five sandstone treads with
/// rounded nosings over limestone risers, between stepped rubble cheek walls topped with cap stones.
public struct StoneStepsWithRisers: RealAsset {
    public static let id = "stone-steps-with-risers"
    public static let summary = "Stone steps 1.5 m wide: five sandstone treads with rounded nosings over limestone risers between stepped rubble cheek walls with cap stones."
    public static let tags = ["prop", "architecture", "facade", "stone"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 22, distance: 4.2)

    /// Number of risers.
    public var steps = 5
    /// Riser height in meters (tread top to tread top).
    public var rise: Float = 0.175
    /// Going (tread depth) in meters.
    public var going: Float = 0.4
    /// Tread stone.
    public var tread: MaterialKey = "stone.sandstone"
    /// Riser stone.
    public var riser: MaterialKey = "stone.limestone"
    /// Cheek wall stone.
    public var cheek: MaterialKey = "stone.wall-block"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let n = steps
        let D = Float(n) * going
        let tw: Float = 1.26, tt: Float = 0.07, nose: Float = 0.03
        let cheekX: Float = 0.69, cheekW: Float = 0.1
        // Stepped core and cheek profile in (z, y), z from the first nosing back to the landing edge.
        func top(_ i: Int) -> Float { rise * Float(i) }
        var core: [V2] = [V2(-D / 2, 0)]
        var wall: [V2] = [V2(-D / 2, 0)]
        for i in 1...n {
            let zs = -D / 2 + going * Float(i - 1), ze = i == n ? D / 2 : zs + going
            core += [V2(zs + 0.02, top(i) - tt), V2(ze, top(i) - tt)]
            wall += [V2(zs, top(i) + 0.02 - 0.03), V2(ze, top(i) + 0.02 - 0.03)]
        }
        core.append(V2(D / 2, 0)); wall.append(V2(D / 2, 0))
        // Core fill under the steps (mortar bed seen in the joints).
        let coreProfile = core.map { V2($0.x + D / 2, $0.y) }
        _ = coreProfile
        FA.run(&m, core.map { V2($0.x, $0.y) }, length: tw - 0.02, at: .zero, "brick.mortar-lime", bevel: 0.002)
        // Cheek walls with a rubble-faced body and cap stones.
        for e: Float in [-1, 1] {
            FA.run(&m, wall, length: cheekW - 0.016, at: V3(e * cheekX, 0, 0), "brick.mortar-lime", bevel: 0.004)
            // Rubble-faced ashlar courses clipped under the stepped cap line.
            func wallTop(_ z: Float) -> Float {
                let i = min(n, max(1, Int(((z + D / 2) / going).rounded(.down)) + 1))
                return top(i) + 0.02 - 0.03
            }
            let ch: Float = 0.15
            for side: Float in [-1, 1] {
                for c in 0..<7 {
                    let y0 = ch * Float(c)
                    var z0 = -D / 2 + (c % 2 == 0 ? 0 : 0.16)
                    while z0 < D / 2 - 0.02 {
                        let len = min(rng.float(0.28...0.48), D / 2 - z0)
                        if len > 0.06 {
                            let zt = min(wallTop(z0 + 0.005), wallTop(z0 + len - 0.005))
                            let h = min(ch - 0.008, zt - y0)
                            if h > 0.03 {
                                let mat: MaterialKey = rng.chance(0.25) ? "stone.granite-moss" : cheek
                                FE.stone(&m, V3(0.034, h, len - 0.01), V3(e * cheekX + side * (cheekW / 2 - 0.017), y0 + h / 2, z0 + len / 2), mat, rng: &rng, r: 0.008, yaw: 0.8, tilt: 0.4)
                            }
                        }
                        z0 += len
                    }
                }
            }
            for i in 1...n {
                let zs = -D / 2 + going * Float(i - 1), ze = i == n ? D / 2 : zs + going
                let capW = ze - zs + (i == 1 ? 0.03 : 0.0) + rng.float(-0.004...0.004)
                FA.box(&m, V3(0.125, 0.035, capW - 0.006), V3(e * cheekX, top(i) + 0.02 - 0.0125, (zs + ze) / 2 - (i == 1 ? 0.015 : 0)),
                       "stone.cap", r: 0.008, rot: FA.q(rng.float(-0.4...0.4), FA.Y))
            }
        }
        for i in 1...n {
            let zs = -D / 2 + going * Float(i - 1), ze = i == n ? D / 2 : zs + going
            let tm: MaterialKey = i % 2 == 0 ? "stone.sandstone" : tread
            // Tread slab with a rounded nosing overhanging the riser.
            let len = ze - zs + nose + 0.02
            let sp = rng.float(-0.35...0.35)
            for (k, (x0, x1)) in [(-tw / 2, sp - 0.003), (sp + 0.003, tw / 2)].enumerated() {
                let pm: MaterialKey = (i + k) % 3 == 0 ? "stone.sandstone" : ((i + k) % 3 == 1 ? tm : "stone.limestone")
                FA.box(&m, V3(x1 - x0, tt, len), V3((x0 + x1) / 2, top(i) - tt / 2, zs - nose + len / 2), pm, r: 0.014, rot: FA.q(rng.float(-0.4...0.4), FA.X))
            }
            // Worn dip: a slightly darker patch where feet land.
            FE.patch(&m, V3(rng.float(-0.12...0.12), top(i) + 0.001, zs + going * 0.55), V3(0.6, 0.005, 0.22), "stone.limestone-sooted")
            // Limestone riser set 4 mm behind the nosing, with a vertical joint at one third.
            let rh = top(i) - top(i - 1) - tt + 0.006
            let rz = zs + 0.012
            let split = rng.float(-0.3...0.3)
            for (x0, x1) in [(-tw / 2 + 0.006, split - 0.002), (split + 0.002, tw / 2 - 0.006)] {
                FA.box(&m, V3(x1 - x0, rh, 0.05), V3((x0 + x1) / 2, top(i - 1) + rh / 2, rz), i % 2 == 0 ? riser : "stone.limestone-sooted", r: 0.007)
            }
            // Moss in the riser base joint and a chipped nosing corner.
            for _ in 0..<2 where rng.chance(0.8) {
                FE.patch(&m, V3(rng.float(-0.55...0.55), top(i - 1) + 0.009, zs + 0.034), V3(rng.float(0.12...0.3), 0.022, 0.026))
            }
            // Hairline crack across one tread.
            if i == 3 {
                FA.box(&m, V3(0.004, 0.003, 0.3), V3(0.2, top(i) + 0.0008, zs + 0.2), "stone.limestone-sooted", r: 0.001, rot: FA.q(14, FA.Y))
            }
        }
        // Chipped nosing: a small dark void on the second tread.
        FA.box(&m, V3(0.05, 0.02, 0.02), V3(0.5, top(2) - 0.012, -D / 2 + going - 0.028), "stone.limestone-sooted", r: 0.004)
        m = FE.seat(m)
        groundAO(&m, height: 0.12, floor: 0.6)
        return LODModel(m)
    }
}
