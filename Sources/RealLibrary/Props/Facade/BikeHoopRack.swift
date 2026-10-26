import simd
import Foundation

/// Bike hoop rack: architectural facade customizer, Contemporary. Stainless steel inverted-U tube with
/// radiused corners and weld seams, on round base flanges with tamper-resistant bolts; scuffed at the lock height.
public struct BikeHoopRack: RealAsset {
    public static let id = "bike-hoop-rack"
    public static let summary = "Bike hoop rack 0.7 m: stainless steel inverted-U tube with radiused corners, base flanges and bolts."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 12, distance: 2.0)

    /// Tube radius in meters (42 mm outside diameter).
    public var tubeRadius: Float = 0.021
    /// Brushed stainless.
    public var steel: MaterialKey = "metal.stainless"
    /// Scuffed stainless where locks hang.
    public var scuffed: MaterialKey = "metal.stainless-smudged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let r = tubeRadius, half: Float = 0.30, rc: Float = 0.16, top: Float = 0.8 - r
        let legTop = top - rc
        // Hoop path: left leg, left corner arc, bar, right corner arc, right leg.
        func arc(_ cx: Float, _ cy: Float, from a0: Float, to a1: Float) -> [V3] {
            (0...12).map { k in
                let a = a0 + (a1 - a0) * Float(k) / 12
                return V3(cx + rc * cos(a), cy + rc * sin(a), 0)
            }
        }
        let leftLeg = [V3(-half, 0.02, 0), V3(-half, 0.45, 0)]
        var upper: [V3] = [V3(-half, 0.45, 0), V3(-half, legTop, 0)]
        upper += arc(-half + rc, legTop, from: .pi, to: .pi / 2).dropFirst()
        upper += arc(half - rc, legTop, from: .pi / 2, to: 0).dropFirst()
        upper += [V3(half, 0.45, 0)]
        let rightLeg = [V3(half, 0.45, 0), V3(half, 0.02, 0)]
        FA.path(&m, leftLeg, r: r, scuffed, sides: 28)
        FA.path(&m, rightLeg, r: r, scuffed, sides: 28)
        m.add(Prim.tube(upper, radii: Array(repeating: r, count: upper.count), sides: 28, seamTile: 0.2, material: steel, capEnd: true))
        // Base plates: rounded rectangular flanges aligned with the hoop plane, each with two tamper-resistant bolts.
        for e: Float in [-1, 1] {
            let x = e * half
            FA.box(&m, V3(0.1, 0.012, 0.05), V3(x, 0.006, 0), steel, r: 0.005)
            FA.box(&m, V3(0.07, 0.006, 0.042), V3(x, 0.014, 0), steel, r: 0.004)
            let sleeve: [V2] = [V2(0, 0.016), V2(r + 0.004, 0.016), V2(r + 0.0035, 0.026), V2(r + 0.001, 0.034), V2(0, 0.034)]
            FE.turn(&m, sleeve, at: V3(x, 0, 0), steel, segments: 32)
            m.add(Prim.torus(major: r + 0.001, minor: 0.0035, segments: 40, sides: 8, material: "metal.steel"), Xform(translation: V3(x, 0.034, 0)))
            for sx in [-1, 1] as [Float] {
                m.add(Prim.cylinder(radius: 0.0065, height: 0.006, bevel: 0.0012, segments: 6, bevelSegments: 1, material: "metal.steel"),
                      Xform(translation: V3(x + sx * 0.038, 0.016, 0)))
            }
        }
        // Weld seam beads where the corner tangents join the bar, and a lock scuff.
        for e: Float in [-1, 1] {
            m.add(Prim.torus(major: r + 0.0005, minor: 0.002, segments: 28, sides: 6, material: "metal.steel"),
                  Xform(translation: V3(e * half, 0.45, 0)))
        }
        // Slip-joint coupling sleeves at the leg splices (a stepped collar with a bead each side).
        for e: Float in [-1, 1] {
            let col: [V2] = [V2(r, 0.43), V2(r + 0.0035, 0.432), V2(r + 0.0035, 0.468), V2(r, 0.47)]
            m.add(Prim.lathe(col, segments: 32, seamTile: 0.2, material: "metal.stainless"), Xform(translation: V3(e * half, 0, 0)))
        }
        // Lock-height wear: a grime band where cable locks hang, with bright scratches and dark rub marks over it.
        for e: Float in [-1, 1] {
            let band: [V2] = [V2(r + 0.0003, 0.5), V2(r + 0.0007, 0.51), V2(r + 0.0007, 0.62), V2(r + 0.0003, 0.64)]
            m.add(Prim.lathe(band, segments: 32, seamTile: 0.2, material: "metal.stainless-smudged"), Xform(translation: V3(e * half, 0, 0)))
            for k in 0..<14 {
                let a = rng.float(-1.4...1.4) + (e > 0 ? 0 : .pi)
                let y = rng.float(0.5...0.64)
                let bright = k % 3 != 0
                FA.box(&m, V3(rng.float(0.01...0.026), rng.float(0.0008...0.002), 0.0008), V3(e * half + (r + 0.0006) * cos(a), y, (r + 0.0006) * sin(a)),
                       bright ? "metal.steel" : "concrete.sealed-dark", r: 0.0003, rot: FA.q(-a * 180 / .pi + 90, FA.Y) * FA.q(rng.float(-20...20), FA.Z))
            }
        }
        m = FE.seat(m)
        groundAO(&m, height: 0.04, floor: 0.6)
        return LODModel(m)
    }
}
