import simd
import Foundation

/// Copper standing seam valley flashing, Contemporary: 2.4 m long, 0.4 m across, 80 mm deep. Two nested valley pans (an
/// older patinated pan downhill and a bright replacement pan lapped over it with a soldered transverse seam), a 22 degree
/// V section with a 60 mm flat valley floor, double-lock standing seams on each slope, rolled edge hems over folded
/// steel cleats, copper nail heads, and patina streaks. Roof piece, sits on y = 0.
public struct CopperStandingSeamValleyFlashing: RealAsset {
    public static let id = "copper-standing-seam-valley-flashing"
    public static let summary = "Copper standing seam valley flashing, Contemporary facade prop, 2.4 x 0.08 x 0.4 m."
    public static let tags = ["prop", "architecture", "facade", "trim", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 32, distance: 1.9)

    /// Run length in meters.
    public var length: Float = 2.4
    /// Older pan.
    public var aged: MaterialKey = "metal.copper-patina"
    /// Replacement pan.
    public var fresh: MaterialKey = "metal.copper"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = length, t: Float = 0.003
        let zA: Float = 0.2, yTop: Float = 0.072, zB: Float = 0.03, yB: Float = 0.004
        let slope = atan2(yTop - yB, zA - zB)
        let deg = slope * 180 / .pi
        func yS(_ z: Float) -> Float { abs(z) <= zB ? yB : yB + (abs(z) - zB) / (zA - zB) * (yTop - yB) }
        func prof(_ lift: Float) -> [V2] {
            let top: [V2] = [V2(-zA, yTop), V2(-zB, yB), V2(zB, yB), V2(zA, yTop)].map { V2($0.x, $0.y + lift + t) }
            let bot: [V2] = [V2(-zA, yTop), V2(-zB, yB), V2(zB, yB), V2(zA, yTop)].map { V2($0.x, $0.y + lift) }
            return bot + top.reversed()
        }
        // Pan sections: older one downhill (left), replacement lapped over it.
        let x0: Float = -L / 2, xLap: Float = 0.25, xEnd: Float = L / 2
        let secs: [(Float, Float, Float, MaterialKey)] = [(x0, xLap + 0.06, 0, aged), (xLap - 0.06, xEnd, t + 0.0008, fresh)]
        for (a, b, lift, mat) in secs {
            FA.run(&m, prof(lift), length: b - a, at: V3((a + b) / 2, 0, 0), mat, bevel: 0.0008)
            // Rolled hems at both long edges with a folded steel cleat under them.
            for sgn: Float in [-1, 1] {
                FA.cylX(&m, r: 0.0055, h: b - a, at: V3(a, yTop + lift + t * 0.5, sgn * (zA - 0.001)), mat, bevel: 0.001, segments: lite(false))
                var x = a + 0.12
                while x < b - 0.08 {
                    FA.box(&m, V3(0.034, 0.0022, 0.03), V3(x, yTop + lift - 0.0022, sgn * (zA - 0.014)), "metal.galvanized-aged", r: 0.0006,
                           rot: FA.q(-sgn * deg, FA.X))
                    x += 0.3
                }
            }
            // Double-lock standing seams on each slope, tilted to the slope normal.
            for sgn: Float in [-1, 1] {
                let zr = sgn * 0.125
                let n = V3(0, cos(slope), -sgn * sin(slope))
                let c = V3((a + b) / 2, yS(zr) + lift + t, zr) + n * 0.008
                FA.box(&m, V3(b - a - 0.004, 0.02, 0.0085), c, mat, r: 0.0022, rot: FA.q(-sgn * deg, FA.X))
                FA.box(&m, V3(b - a - 0.004, 0.0045, 0.0125), c + n * 0.0075, mat, r: 0.0018, rot: FA.q(-sgn * deg, FA.X))   // folded cap
            }
            // Copper nail heads along the slopes near the hems.
            var x = a + 0.07
            while x < b - 0.04 {
                for sgn: Float in [-1, 1] {
                    let zn = sgn * (zA - 0.032)
                    let n = V3(0, cos(slope), -sgn * sin(slope))
                    rivet(&m, at: V3(x, yS(zn) + lift + t, zn), normal: n, radius: 0.0032, segments: 8, material: "metal.copper")
                }
                x += 0.16
            }
        }
        // Soldered transverse lap: tinned solder bead along the upper pan edge and a pressed lap line.
        let sx: Float = xLap - 0.06
        var solder: [V3] = []
        for z in stride(from: -zA + 0.004, through: zA - 0.004, by: 0.01) { solder.append(V3(sx - 0.002, yS(z) + 2 * t + 0.0008 + 0.0012, z)) }
        FA.path(&m, solder, r: 0.0017, "metal.solder", sides: 6)
        // Patina streaks and verdigris bloom on the old pan, bright scuff and flux stain on the new.
        for _ in 0..<14 {
            let sgn: Float = rng.chance(0.5) ? -1 : 1
            let z = sgn * rng.float(0.05...0.17)
            let x = rng.float(x0 + 0.1...xLap - 0.1)
            let n = V3(0, cos(slope), -sgn * sin(slope))
            FA.box(&m, V3(rng.float(0.15...0.5), 0.0007, rng.float(0.004...0.012)), V3(x, yS(z) + t + 0.001, z) + n * 0.0004,
                   rng.chance(0.5) ? "metal.verdigris-roof" : "metal.bronze-weathered", r: 0.0002, rot: FA.q(-sgn * deg, FA.X))
        }
        for _ in 0..<5 {
            let z = rng.float(-0.15...0.15)
            FA.box(&m, V3(rng.float(0.05...0.2), 0.0009, rng.float(0.008...0.02)), V3(rng.float(xLap + 0.1...xEnd - 0.1), yS(z) + 2 * t + 0.0018, z),
                   rng.chance(0.5) ? "metal.brass-aged" : "stone.limestone-sooted", r: 0.0002, rot: FA.q(-(z >= 0 ? 1 : -1) * deg * (abs(z) > zB ? 1 : 0), FA.X))
        }
        // Hail dimples on the replacement pan floor and a soldered patch over a nail hole on the old pan.
        for k in 0..<4 {
            let x = xLap + 0.2 + Float(k) * 0.2 + rng.float(-0.04...0.04), z = rng.float(-0.012...0.012)
            m.add(Prim.superellipsoid(V3(0.034, 0.003, 0.03), exponent: 2, subdivisions: 3, material: "metal.brass-aged"), Xform(translation: V3(x, yB + 2 * t + 0.0012, z)))
        }
        FA.box(&m, V3(0.05, 0.0014, 0.04), V3(-0.8, yS(0.1) + t + 0.0012, 0.1) + V3(0, cos(slope), -sin(slope)) * 0.0004, "metal.solder", r: 0.0006, rot: FA.q(-deg, FA.X))
        // Dirt line where leaves collect in the valley floor, and a bent corner on the new pan end.
        FA.box(&m, V3(0.9, 0.0008, 0.02), V3(-0.55, yB + t + 0.0007, 0), "wood.deadwood", r: 0.0002)
        groundAO(&m)
        return LODModel(FC.place(m))
    }

    private func lite(_ l: Bool) -> Int { l ? 6 : 10 }
}
