import simd
import Foundation

/// Floor-mounted bidet: skirted elongated vitreous china bowl on a floor flange, wide rim around an
/// inner dish, rear deck with a chrome faucet (swivel spout, two lever handles), pop-up drain and a
/// caulk bead. Back at z = -0.3, front +Z, rim at 0.34 m, faucet top at 0.4 m.
public struct Bidet: RealAsset {
    public static let id = "bidet"
    public static let summary = "Floor-mounted bidet: skirted elongated vitreous china bowl, deck-mounted chrome faucet with two lever handles, pop-up drain."
    public static let tags = ["prop", "floorplan", "bathroom", "plumbing", "ceramic", "interior"]
    public static let budget = 5500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 25, distance: 1.6, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.37, 0.4, 0.6)
    public var china: MaterialKey = "ceramic.vitreous"
    public var chrome: MaterialKey = "metal.chrome"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        func make(_ lod: Int) -> Model {
            var m = Model(name: Self.id)
            let hi = lod == 0
            let back = -size.z / 2, front = size.z / 2, rim = size.y - 0.062
            let hw = size.x / 2
            let nf = hi ? 10 : 5
            func ring(_ w: Float, _ fr: Float, _ re: Float, _ rr: Float, _ y: Float) -> [V3] {
                Prim.ring(BathFit.dOutline(hw: w, front: fr, rear: re, rr: rr, nFront: nf), y: y)
            }
            // Floor flange.
            m.add(Prim.loft([ring(0.147, front - 0.055, back + 0.065, 0.03, 0.0), ring(0.150, front - 0.055, back + 0.065, 0.03, 0.009),
                             ring(0.147, front - 0.053, back + 0.065, 0.03, 0.014)], capStart: true, capEnd: true, material: china))
            // Skirt, bottom to top, then rim and dish continue in the same skin.
            let dishRear = back + 0.15
            let rows: [[V3]] = [
                ring(0.142, front - 0.062, back + 0.075, 0.04, 0.012), ring(0.15, front - 0.05, back + 0.06, 0.045, 0.06),
                ring(0.168, front - 0.025, back + 0.03, 0.05, 0.16), ring(hw - 0.007, front - 0.008, back + 0.012, 0.05, rim - 0.1),
                ring(hw, front, back, 0.05, rim - 0.015), ring(hw - 0.002, front - 0.002, back + 0.002, 0.05, rim - 0.003),
                ring(hw - 0.009, front - 0.009, back + 0.009, 0.045, rim),
                ring(hw - 0.05, front - 0.05, dishRear - 0.02, 0.06, rim - 0.002),
                ring(hw - 0.056, front - 0.056, dishRear, 0.06, rim - 0.012),
                ring(hw - 0.07, front - 0.075, dishRear + 0.015, 0.07, rim - 0.07),
                ring(hw - 0.11, front - 0.11, dishRear + 0.04, 0.07, rim - 0.14),
                ring(hw - 0.135, front - 0.13, dishRear + 0.06, 0.07, rim - 0.17)]
            m.add(Prim.loft(Array(rows[0...6]), capStart: true, material: china))
            // Dish glaze: slightly creamier from years of hard water.
            m.add(Prim.loft(Array(rows[6...]), capEnd: true, material: "ceramic.vitreous:ECE8DA"))
            // Rear deck and faucet.
            let fz = back + 0.085
            BathFit.faucet(&m, at: V3(0, rim - 0.0035, fz), finish: chrome, spread: 0.1, reach: 0.12, height: 0.04, hi: hi)
            // Pop-up drain flange and stopper in the dish floor.
            let dc = V3(0, rim - 0.17, dishRear + 0.2)
            m.add(Prim.lathe([V2(0.001, 0.0005), V2(0.026, 0.0005), V2(0.028, 0.002), V2(0.024, 0.004), V2(0.001, 0.004)], segments: hi ? 20 : 10, seamTile: 0.05, material: chrome), Xform(translation: dc))
            m.add(Prim.lathe([V2(0.001, 0.004), V2(0.017, 0.004), V2(0.018, 0.006), V2(0.001, 0.0065)], segments: hi ? 16 : 8, seamTile: 0.05, material: "metal.stainless"), Xform(translation: dc))
            // Overflow slot at the dish front rim.
            m.add(Prim.roundedBox(V3(0.03, 0.004, 0.006), radius: 0.0018, bevelSegments: 1, material: "plastic.black"),
                  Xform(translation: V3(0, rim - 0.04, front - 0.082)))
            // Pop-up lift rod behind the spout.
            m.add(Prim.cylinder(radius: 0.0045, height: 0.045, bevel: 0.0012, segments: hi ? 10 : 6, material: chrome), Xform(translation: V3(0, rim - 0.0035, fz - 0.04)))
            m.add(Prim.cylinder(radius: 0.0095, height: 0.009, bevel: 0.003, segments: hi ? 14 : 8, material: chrome), Xform(translation: V3(0, rim - 0.0035 + 0.043, fz - 0.04)))
            m.add(Prim.lathe([V2(0.001, 0), V2(0.0115, 0), V2(0.0115, 0.002), V2(0.008, 0.0035), V2(0.001, 0.0035)], segments: hi ? 14 : 8, seamTile: 0.05, material: chrome), Xform(translation: V3(0, rim - 0.0035, fz - 0.04)))
            // Rinse jet on the dish rear wall, angled up and forward.
            let jet = V3(0, rim - 0.075, dishRear + 0.02)
            m.add(Prim.cylinder(radius: 0.013, height: 0.014, bevel: 0.003, segments: hi ? 14 : 8, material: chrome),
                  Xform(translation: jet, rotation: simd_quatf(degrees: 62, axis: V3(1, 0, 0))))
            m.add(Prim.cylinder(radius: 0.0065, height: 0.012, bevel: 0.002, segments: hi ? 12 : 6, material: "metal.stainless"),
                  Xform(translation: jet + V3(0, 0.0045, 0.0085), rotation: simd_quatf(degrees: 62, axis: V3(1, 0, 0))))
            // Caulk bead.
            let bead = ring(0.1505, front - 0.0535, back + 0.0635, 0.0335, 0.0035)
            m.add(Prim.sweep(Shape2D.circle(0.0035, ry: 0.0028, segments: hi ? 8 : 5), along: bead, up: V3(0, 1, 0), closedPath: true, material: "plastic.matte:D6D1BE"))
            // Bolt caps.
            for k: Float in [-1, 1] {
                m.add(Prim.cylinder(radius: 0.0125, height: 0.013, bevel: 0.004, segments: 12, material: "plastic.white"),
                      Xform(translation: V3(k * 0.112, 0.016, -0.04)))
            }
            groundAO(&m, height: 0.2, floor: 0.6)
            return m
        }
        return LODModel(levels: [make(0), make(1)], switchDistances: [5])
    }
}
