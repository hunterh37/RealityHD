import simd
import Foundation

/// Granite curb step: architectural facade customizer, Municipal. Two quarried slabs with a bullnose arris,
/// flame-finished tread, chiselled draft margin, a tight mortar joint, drill marks on the ends and tyre scuffs.
public struct GraniteCurbStep: RealAsset {
    public static let id = "granite-curb-step"
    public static let summary = "Granite curb step 1.5 m: two quarried slabs with bullnose arris, flame-finished tread, chiselled margin and drill marks on the ends."
    public static let tags = ["prop", "architecture", "facade", "stone"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 20, distance: 2.4)

    /// Overall length in meters.
    public var length: Float = 1.5
    /// Slab height in meters.
    public var height: Float = 0.143
    /// Slab depth in meters.
    public var depth: Float = 0.49
    /// Slab granite.
    public var granite: MaterialKey = "stone.granite-curb"
    /// Flame-finished tread granite.
    public var tread: MaterialKey = "stone.granite-paver"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = length, H = height, D = depth
        let joint: Float = 0.012
        let lens: [Float] = [0.78, L - 0.78 - joint]
        var x0 = -L / 2
        for (k, w) in lens.enumerated() {
            let xc = x0 + w / 2
            // Sawn body with a split (pitched) front face and a clean back.
            FE.rockBlock(&m, V3(w, H - 0.026, D - 0.01), V3(xc, (H - 0.026) / 2 + 0.01, 0), k == 0 ? granite : "stone.granite-paver", seed: Float(k) * 5 + 1, amp: 0.011, margin: 0.03, r: 0.01, flatTop: true)
            // Flame-finished tread slab with a chiselled 30 mm draft margin around it.
            FA.box(&m, V3(w - 0.006, 0.014, D - 0.008), V3(xc, H - 0.007, 0), k == 0 ? granite : "stone.granite-paver", r: 0.007)
            FA.box(&m, V3(w - 0.07, 0.003, D - 0.075), V3(xc, H + 0.0005, 0), k == 0 ? tread : granite, r: 0.001)
            // Bullnose roll on the kerb edge.
            FA.cylX(&m, r: 0.012, h: w - 0.012, at: V3(xc - (w - 0.012) / 2, H - 0.012, -D / 2 + 0.012), granite, bevel: 0.001, segments: 14)
            // Anti-slip grooves cut across the front of the tread.
            for g in 0..<4 {
                FA.box(&m, V3(w - 0.1, 0.002, 0.004), V3(xc, H + 0.0013, -D / 2 + 0.07 + Float(g) * 0.022), "stone.slate", r: 0.0008)
            }
            // Feather-and-tare drill half-marks on the end face (dark vertical flutes).
            for e: Float in k == 0 ? [-1] : [1] {
                for j in 0..<3 {
                    let z = -0.14 + Float(j) * 0.14
                    FA.box(&m, V3(0.004, H - 0.05, 0.014), V3(xc + e * (w / 2 - 0.0005), (H - 0.012) / 2, z), "stone.slate", r: 0.0035)
                }
            }
            x0 += w + joint
        }
        // Mortar bed in the butt joint (lime mortar grey), set back 3 mm from the face.
        FA.box(&m, V3(joint + 0.002, H - 0.02, D - 0.03), V3(-L / 2 + lens[0] + joint / 2, (H - 0.02) / 2 + 0.002, 0), "brick.mortar-grey", r: 0.002)
        // Tyre scuff and a chipped front corner.
        FE.stain(&m, V3(0.42, H + 0.0016, -D / 2 + 0.13), w: 0.36, d: 0.09, "stone.slate", yaw: 6)
        FE.stain(&m, V3(-0.25, H + 0.0016, 0.05), w: 0.2, d: 0.14, "stone.limestone-sooted", yaw: -20)
        // Spalled corner chips showing fresh stone, and a hairline crack.
        for (cx, cz, cs) in [(-L / 2 + 0.02, -D / 2 + 0.02, Float(0.035)), (lens[0] - L / 2 - 0.02, D / 2 - 0.02, 0.028), (L / 2 - 0.03, D / 2 - 0.015, 0.03)] {
            FA.box(&m, V3(cs, 0.02, cs), V3(cx, H - 0.011, cz), "stone.limestone", r: 0.005, rot: FA.q(rng.float(10...70), FA.Y))
        }
        FA.box(&m, V3(0.25, 0.0012, 0.0025), V3(0.3, H + 0.0014, 0.03), "stone.slate", r: 0.0005, rot: FA.q(18, FA.Y))
        FE.patch(&m, V3(-0.5, 0.004, D / 2 + 0.002), V3(0.2, 0.03, 0.02))
        m = FE.seat(m)
        groundAO(&m, height: 0.06, floor: 0.6)
        return LODModel(m)
    }
}
