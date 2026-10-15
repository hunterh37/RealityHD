import simd
import Foundation

/// Pedestal lavatory: vitreous china basin with rolled rim and backsplash, tapered pedestal column on a
/// floor flare, chrome centerset faucet with lever handles, pop-up drain and lift rod, angle stops and
/// supply lines behind the column. Wall at z = -0.21, front +Z, rim 0.79 m, backsplash top 0.83 m.
public struct PedestalSink: RealAsset {
    public static let id = "pedestal-sink"
    public static let summary = "Pedestal lavatory: vitreous china basin with backsplash and column, chrome centerset faucet, pop-up drain and angle stops."
    public static let tags = ["prop", "floorplan", "bathroom", "plumbing", "ceramic", "interior"]
    public static let budget = 6500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 20, distance: 2.0, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.5, 0.85, 0.42)
    public var china: MaterialKey = "ceramic.vitreous"
    public var chrome: MaterialKey = "metal.chrome"
    /// Basin rim height.
    public var rimHeight: Float = 0.79
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        func make(_ lod: Int) -> Model {
            var m = Model(name: Self.id)
            let hi = lod == 0
            let back = -size.z / 2, front = size.z / 2, hw = size.x / 2, rim = rimHeight
            let nf = hi ? 10 : 5
            func ring(_ w: Float, _ fr: Float, _ re: Float, _ rr: Float, _ y: Float) -> [V3] {
                Prim.ring(BathFit.dOutline(hw: w, front: fr, rear: re, rr: rr, exponent: 3.0, nFront: nf), y: y)
            }
            // Basin: underside to rim, rim roll, deck, then the dish.
            let dishRear = back + 0.095
            let rows: [[V3]] = [
                ring(0.075, front - 0.15, back, 0.03, 0.665), ring(0.14, front - 0.1, back, 0.03, 0.69),
                ring(0.215, front - 0.035, back, 0.03, 0.745), ring(hw - 0.005, front - 0.004, back, 0.03, rim - 0.03),
                ring(hw, front, back, 0.03, rim - 0.01), ring(hw - 0.004, front - 0.004, back, 0.03, rim - 0.001),
                ring(hw - 0.012, front - 0.012, back, 0.03, rim),
                ring(hw - 0.05, front - 0.045, dishRear - 0.03, 0.06, rim - 0.001),
                ring(hw - 0.056, front - 0.05, dishRear, 0.06, rim - 0.012),
                ring(hw - 0.075, front - 0.07, dishRear + 0.012, 0.07, rim - 0.05),
                ring(hw - 0.12, front - 0.105, dishRear + 0.035, 0.07, rim - 0.075),
                ring(hw - 0.155, front - 0.13, dishRear + 0.06, 0.07, rim - 0.085)]
            m.add(Prim.loft(Array(rows[0...6]), capStart: true, material: china))
            m.add(Prim.loft(Array(rows[6...]), capEnd: true, material: china))
            // Backsplash.
            m.add(Prim.roundedBox(V3(size.x - 0.004, 0.044, 0.016), radius: 0.005, bevelSegments: hi ? 2 : 1, material: china),
                  Xform(translation: V3(0, rim + 0.016, back + 0.008)))
            // Pedestal column: tapered ellipse sections, flat against the wall.
            let pz = back + 0.115
            func col(_ w: Float, _ d: Float, _ y: Float) -> [V3] { Prim.ring(Shape2D.superellipse(w, d, exponent: 2.6), y: y, offset: V3(0, 0, pz)) }
            m.add(Prim.loft([col(0.2, 0.2, 0.0), col(0.205, 0.205, 0.012), col(0.185, 0.19, 0.03), col(0.12, 0.14, 0.1), col(0.096, 0.12, 0.35),
                             col(0.105, 0.125, 0.55), col(0.14, 0.15, 0.665)], capStart: true, material: china))
            // Faucet, lift rod, drain.
            let fz = back + 0.058
            BathFit.faucet(&m, at: V3(0, rim - 0.0015, fz), finish: chrome, spread: 0.1, reach: 0.11, height: 0.038, hi: hi)
            m.add(Prim.cylinder(radius: 0.0042, height: 0.04, bevel: 0.0012, segments: hi ? 10 : 6, material: chrome), Xform(translation: V3(0, rim - 0.0015, fz - 0.033)))
            m.add(Prim.cylinder(radius: 0.0085, height: 0.008, bevel: 0.003, segments: hi ? 12 : 8, material: chrome), Xform(translation: V3(0, rim - 0.0015 + 0.038, fz - 0.033)))
            let dc = V3(0, rim - 0.085, dishRear + 0.16)
            m.add(Prim.lathe([V2(0.001, 0.0005), V2(0.024, 0.0005), V2(0.026, 0.002), V2(0.022, 0.0042), V2(0.001, 0.0042)], segments: hi ? 20 : 10, seamTile: 0.05, material: chrome), Xform(translation: dc))
            m.add(Prim.lathe([V2(0.001, 0.0042), V2(0.016, 0.0042), V2(0.017, 0.0062), V2(0.001, 0.0068)], segments: hi ? 16 : 8, seamTile: 0.05, material: "metal.stainless"), Xform(translation: dc))
            // Overflow slot below the rear rim.
            m.add(Prim.roundedBox(V3(0.028, 0.012, 0.003), radius: 0.0012, bevelSegments: 1, material: "plastic.black"),
                  Xform(translation: V3(0, rim - 0.034, dishRear + 0.0035), rotation: simd_quatf(degrees: -12, axis: V3(1, 0, 0))))
            // Angle stops and supply lines at the wall.
            for k: Float in [-1, 1] {
                let sx = k * 0.042, sz = back + 0.026
                m.add(Prim.tube([V3(sx, 0.47, sz), V3(sx, 0.62, sz), V3(sx, 0.7, sz + 0.004), V3(sx, 0.725, sz + 0.012)], radii: [0.0045, 0.0045, 0.0045, 0.0045], sides: hi ? 8 : 5, seamTile: 0.03, material: chrome))
                m.add(Prim.cylinder(radius: 0.0105, height: 0.03, bevel: 0.003, segments: hi ? 12 : 8, material: chrome), Xform(translation: V3(sx, 0.445, sz)))
                m.add(Prim.roundedBox(V3(0.024, 0.009, 0.006), radius: 0.003, bevelSegments: 1, material: chrome), Xform(translation: V3(sx, 0.455, sz + 0.012)))
                m.add(Prim.cylinder(radius: 0.017, height: 0.004, bevel: 0.001, segments: hi ? 14 : 8, material: chrome),
                      Xform(translation: V3(sx, 0.43, back + 0.002), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            }
            // Caulk bead round the floor flare.
            let bead = Prim.ring(Shape2D.superellipse(0.2, 0.2, exponent: 2.6), y: 0.0035, offset: V3(0, 0, pz))
            m.add(Prim.sweep(Shape2D.circle(0.0035, ry: 0.0028, segments: hi ? 8 : 5), along: bead, up: V3(0, 1, 0), closedPath: true, material: "plastic.matte:D6D1BE"))
            groundAO(&m, height: 0.2, floor: 0.6)
            return m
        }
        return LODModel(levels: [make(0), make(1)], switchDistances: [5])
    }
}
