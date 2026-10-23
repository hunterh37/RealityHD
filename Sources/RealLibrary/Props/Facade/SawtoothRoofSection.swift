import simd
import Foundation

/// Sawtooth roof section: architectural facade customizer, industrial, weathered. Parts: standing-seam steel roof slopes, north-light vertical glazing, glazing mullions, steel purlins and rafters, valley gutter, ridge flashing, end gable wall, downpipe.
public struct SawtoothRoofSection: RealAsset {
    public static let id = "sawtooth-roof-section"
    public static let summary = "Sawtooth roof section, 6.0 x 4.0 m: three saw-tooth bays with standing-seam slopes, north-light glazing, valley gutters."
    public static let tags = ["prop", "architecture", "facade", "roof", "metal"]
    public static let budget = 30000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(6.0, 2.0, 4.0)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = size.x - 0.34, D = size.z - 0.12, H = size.y
        let teeth = 3, bw = D / Float(teeth), vy: Float = 0.9, rz = bw * 0.75
        let slopeDz = rz, slopeDy = H - vy - 0.03
        let slopeLen = sqrt(slopeDz * slopeDz + slopeDy * slopeDy)
        let th = atan2(slopeDy, slopeDz) * 180 / .pi
        let gz = bw - rz, gdy = H - vy - 0.03
        let glen = sqrt(gz * gz + gdy * gdy), gdeg = atan2(gz, gdy) * 180 / .pi
        let roof: MaterialKey = "metal.galvanized-aged", frame: MaterialKey = "metal.anodized-worn"
        // End gable walls following the saw-tooth outline.
        var o: [V2] = [V2(-D / 2, 0), V2(D / 2, 0), V2(D / 2, vy)]
        for i in stride(from: teeth - 1, through: 0, by: -1) {
            let z0 = -D / 2 + bw * Float(i)
            o.append(V2(z0 + rz, H - 0.03)); if i > 0 { o.append(V2(z0, vy)) }
        }
        o.append(V2(-D / 2, vy))
        for e: Float in [-1, 1] {
            m.add(Prim.extrude(o, depth: 0.08, bevel: 0.004, bevelSegments: 1, material: "metal.anodized-worn"),
                  Xform(translation: V3(e * (L / 2 + 0.06), 0, 0), rotation: FA.q(-90, FA.Y)))
        }
        for i in 0..<teeth {
            let z0 = -D / 2 + bw * Float(i)
            // Standing-seam slope: pan, seams every 0.5 m, rafters beneath.
            let mz = z0 + slopeDz / 2, my = vy + slopeDy / 2 + 0.005
            FA.box(&m, V3(L, 0.035, slopeLen), V3(0, my, mz), "metal.galvanized", r: 0.004, rot: FA.q(-th, FA.X))
            let nS = Int(L / 0.75)
            for k in 0...nS {
                let x = -L / 2 + 0.02 + (L - 0.04) * Float(k) / Float(nS)
                FA.box(&m, V3(0.026, 0.03, slopeLen), V3(x, my + 0.026 * cos(th * .pi / 180), mz - 0.026 * sin(th * .pi / 180)), roof, r: 0.005, rot: FA.q(-th, FA.X))
            }
            for k in 0..<3 {
                let x = -L / 2 + 0.1 + (L - 0.2) * Float(k) / 2
                FA.box(&m, V3(0.06, 0.1, slopeLen), V3(x, my - 0.07, mz + 0.03), frame, r: 0.004, rot: FA.q(-th, FA.X))
            }
            // North-light glazing: frame rails, mullions every 0.75 m, panes.
            let gx = L / 2
            let gcz = z0 + rz + gz / 2, gcy = vy + gdy / 2 + 0.015
            let gq = FA.q(-gdeg, FA.X)
            FA.box(&m, V3(L, 0.05, 0.05), V3(0, H - 0.05, z0 + rz - 0.01), frame, r: 0.004)
            FA.box(&m, V3(L, 0.05, 0.05), V3(0, vy + 0.06, z0 + bw - 0.03), frame, r: 0.004)
            let nb = 6
            let bay = L / Float(nb)
            for k in 0...nb {
                let x = -gx + bay * Float(k)
                FA.box(&m, V3(0.04, glen, 0.05), V3(x, gcy, gcz), frame, r: 0.004, rot: gq)
            }
            for k in 0..<nb {
                let x = -gx + bay * (Float(k) + 0.5)
                m.add(Prim.roundedBox(V3(bay - 0.05, glen - 0.11, 0.008), radius: 0.001, bevelSegments: 1, material: "glass.tinted"),
                      Xform(translation: V3(x, gcy, gcz + 0.004), rotation: gq))
            }
            // Ridge flashing with zinc screws.
            FA.box(&m, V3(L + 0.04, 0.03, 0.14), V3(0, H - 0.01, z0 + rz - 0.04), roof, r: 0.006, rot: FA.q(-th * 0.3, FA.X))
            for k in 0..<7 {
                let x = -L / 2 + 0.15 + (L - 0.3) * Float(k) / 6
                FA.cylZ(&m, r: 0.006, h: 0.006, at: V3(x, H + 0.007, z0 + rz - 0.04), "metal.screw-zinc", bevel: 0.001, segments: 6)
            }
            // Valley gutter at the foot of the glazing.
            let gzv = z0 + bw
            if i < teeth - 1 || true {
                FA.box(&m, V3(L + 0.1, 0.02, 0.22), V3(0, vy - 0.045, gzv - 0.05), roof, r: 0.003)
                FA.box(&m, V3(L + 0.1, 0.1, 0.02), V3(0, vy + 0.0, gzv - 0.15), roof, r: 0.003)
                FA.box(&m, V3(L + 0.1, 0.07, 0.02), V3(0, vy - 0.01, gzv + 0.05), roof, r: 0.003)
            }
            for _ in 0..<14 {
                let f: Float = 0.22, x = rng.float(-L / 2 + 0.2...L / 2 - 0.2), sl = rng.float(0.4...0.9)
                FA.box(&m, V3(0.05, 0.004, sl), V3(x, vy + slopeDy * f + 0.026, z0 + slopeDz * f - 0.02), "metal.rust-grime", r: 0.001, rot: FA.q(-th, FA.X))
            }
            // Real detail: transverse lap joints, seam-clip screws, drip edge, cap strips, brackets, rafter tails.
            for f: Float in [0.38, 0.72] {
                FA.box(&m, V3(L, 0.012, 0.03), V3(0, vy + slopeDy * f + 0.024, z0 + slopeDz * f), roof, r: 0.003, rot: FA.q(-th, FA.X))
                for k in 0...nS {
                    let x = -L / 2 + 0.02 + (L - 0.04) * Float(k) / Float(nS)
                    FA.cylZ(&m, r: 0.007, h: 0.006, at: V3(x + 0.0, vy + slopeDy * f + 0.036, z0 + slopeDz * f - 0.012), "metal.screw-zinc", bevel: 0.001, segments: 6)
                }
            }
            FA.box(&m, V3(L + 0.02, 0.012, 0.06), V3(0, vy - 0.002, z0 + 0.0), roof, r: 0.003, rot: FA.q(-th * 0.5, FA.X))
            FA.box(&m, V3(L, 0.012, 0.07), V3(0, H - 0.03, z0 + rz + 0.012), frame, r: 0.003)
            for k in 0..<3 {
                let x = -L / 2 + 0.1 + (L - 0.2) * Float(k) / 2
                FA.box(&m, V3(0.07, 0.07, 0.07), V3(x, vy - 0.06, z0 + 0.02), frame, r: 0.004)
                FA.box(&m, V3(0.1, 0.02, 0.16), V3(x, vy - 0.03, gzv - 0.05), frame, r: 0.003)
            }
            for k in 0...nb {
                let x = -gx + bay * Float(k)
                for f: Float in [0.25, 0.75] {
                    FA.cylZ(&m, r: 0.007, h: 0.006, at: V3(x, vy + gdy * f + 0.015, z0 + rz + gz * f + 0.03), "metal.screw-zinc", bevel: 0.001, segments: 6)
                }
            }
            for _ in 0..<2 {
                FA.box(&m, V3(rng.float(0.12...0.25), 0.004, rng.float(0.08...0.14)), V3(rng.float(-L / 2 + 0.3...L / 2 - 0.3), vy - 0.032, gzv - 0.1), "metal.rust-grime", r: 0.001)
            }
            // Rust grime streak below the slope foot.
            FA.box(&m, V3(0.5, 0.004, 0.3), V3(rng.float(-2...2), vy - 0.032, gzv - 0.05), "metal.rust-grime", r: 0.001)
        }
        // End wall coping caps and wall anchor bolts.
        for e: Float in [-1, 1] {
            for k in 0..<4 {
                FA.box(&m, V3(0.1, 0.012, 0.05), V3(e * (L / 2 + 0.06), vy + 0.15 * Float(k) * 0.3, -D / 2 + 0.15 + Float(k) * 0.9), "metal.rust-grime", r: 0.001)
                FA.cylZ(&m, r: 0.012, h: 0.012, at: V3(e * (L / 2 + 0.06), 0.3 + Float(k) * 0.15, -D / 2 + 0.12 + Float(k) * 0.9), "metal.screw-zinc", bevel: 0.002, segments: 6)
            }
        }
        // Downpipe at one end with brackets.
        let dx = L / 2 + 0.17, dzp = -D / 2 + bw
        FA.rod(&m, V3(dx, vy - 0.04, dzp - 0.05), V3(dx, 0.03, dzp - 0.05), r: 0.04, "metal.galvanized-aged", sides: 14)
        for y: Float in [0.2, 0.5, 0.8] { FA.box(&m, V3(0.1, 0.02, 0.025), V3(dx - 0.04, y, dzp - 0.05), frame, r: 0.003) }
        FA.box(&m, V3(0.16, 0.06, 0.16), V3(dx, 0.03, dzp - 0.05), roof, r: 0.01)
        for y: Float in [0.2, 0.5, 0.8] { FA.rod(&m, V3(dx, y - 0.015, dzp - 0.05), V3(dx, y + 0.015, dzp - 0.05), r: 0.048, frame, sides: 14) }
        FA.box(&m, V3(0.03, 0.5, 0.03), V3(dx, 0.35, dzp - 0.05 + 0.035), "metal.rust-grime", r: 0.001)
        // Story detail: a leaf drift caught in the first valley.
        for k in 0..<3 {
            m.add(Prim.superellipsoid(V3(0.07, 0.006, 0.05), exponent: 2, subdivisions: 5, material: "wood.cedar-weathered"),
                  Xform(translation: V3(rng.float(1.5...2.7), vy - 0.03, -D / 2 + bw - 0.06 + Float(k) * 0.02), rotation: FA.q(rng.float(0...180), FA.Y)))
        }
        groundAO(&m)
        return LODModel(m)
    }
}
