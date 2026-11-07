import simd
import Foundation

/// Bowler hat: black wool felt crown, silk grosgrain band with a flat bow, curled brim, leather sweatband. Origin on the brim underside, crown along +Y.
public struct BowlerHat: RealAsset {
    public static let id = "bowler-hat"
    public static let summary = "Black felt bowler hat, 29 cm brim: domed oval crown, silk grosgrain band and bow, curled brim, leather sweatband."
    public static let tags = ["prop", "fabric", "decor"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Plan-view stretch of the oval head opening (front-back over side-to-side).
    public var ovalness: Float = 1.2
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let felt: MaterialKey = "fabric.wool:151517", silk: MaterialKey = "fabric.nylon:070708", leather: MaterialKey = "leather.tan"
        let oval = Xform(scale: V3(1, 1, ovalness))
        // Outer crown from the top centre down to the brim junction, then the curled brim out to its rolled edge.
        let crown: [V2] = Profile.smooth([V2(0, 0.1185), V2(0.030, 0.1175), V2(0.055, 0.1130), V2(0.075, 0.1040), V2(0.0875, 0.0900),
                                          V2(0.0925, 0.0700), V2(0.0945, 0.0450), V2(0.0955, 0.0200), V2(0.0975, 0.0070)], per: 5)
        let brim: [V2] = Profile.smooth([V2(0.0975, 0.0070), V2(0.1050, 0.0030), V2(0.1200, 0.0010), V2(0.1340, 0.0015), V2(0.1430, 0.0040),
                                         V2(0.1475, 0.0085), V2(0.1475, 0.0125), V2(0.1445, 0.0140)], per: 6)
        // Underside: back along the brim, then up inside the crown with a 2.5 mm felt wall.
        let under: [V2] = Profile.smooth([V2(0.1445, 0.0140), V2(0.1420, 0.0100), V2(0.1350, 0.0045), V2(0.1200, 0.0010), V2(0.1050, 0.0006), V2(0.0930, 0.0010)], per: 4)
        let inner: [V2] = crown.dropFirst().reversed().map { V2(max(0, $0.x - 0.0025), $0.y - 0.0025) }
        let shell = crown + brim.dropFirst() + under.dropFirst() + inner.dropFirst()
        m.add(Prim.lathe(shell, segments: 96, seamTile: 0.12, material: felt), oval)
        // Silk grosgrain band wrapping the crown base, slightly proud of the felt.
        let band: [V2] = [V2(0.0962, 0.0105), V2(0.0972, 0.0115), V2(0.0972, 0.0330), V2(0.0962, 0.0340)].map { V2($0.x + 0.0010, $0.y) }
        m.add(Prim.lathe(band, segments: 96, seamTile: 0.06, material: silk), oval)
        // Flat bow and knot at the back of the band.
        let zb = 0.0975 * ovalness + 0.0009
        for s: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(0.026, 0.020, 0.003), radius: 0.0012, bevelSegments: 2, material: silk),
                  Xform(translation: V3(s * 0.016, 0.022, zb + 0.0012), rotation: simd_quatf(degrees: s * 14, axis: V3(0, 0, 1))))
        }
        m.add(Prim.roundedBox(V3(0.012, 0.018, 0.005), radius: 0.0022, bevelSegments: 3, material: silk), Xform(translation: V3(0, 0.022, zb + 0.0028)))
        // Leather sweatband inside the crown.
        let sweat: [V2] = [V2(0.0905, 0.0040), V2(0.0915, 0.0050), V2(0.0915, 0.0290), V2(0.0905, 0.0300)]
        m.add(Prim.lathe(sweat, segments: 96, seamTile: 0.1, material: leather), oval)
        // Resting on the ground by its brim.
        return LODModel(m)
    }
}
