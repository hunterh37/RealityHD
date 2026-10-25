import simd
import Foundation

/// Cobra head wall light: architectural facade customizer, Commercial. Tapered cast aluminum housing with a
/// hinged door and spring latch, drop prismatic refractor, photocell receptacle, slip-fitter tenon and braced
/// steel arm on a bolted wall plate. Grey enamel is chalked and the refractor is yellowed and dusty.
public struct CobraHeadWallLight: RealAsset {
    public static let id = "cobra-head-wall-light"
    public static let summary = "Cobra head luminaire on wall arm, 0.6 m: grey tapered housing with refractor and photocell."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 18, distance: 1.7)

    /// Housing enamel.
    public var enamel: MaterialKey = "metal.transformer-gray"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let steel: MaterialKey = "metal.screw-zinc", galv: MaterialKey = "metal.galvanized-aged", grime: MaterialKey = "metal.rust-grime"
        let zc: Float = 0.178
        // Wall plate, braced arm and slip fitter at the tail end (x = -0.27).
        let ax: Float = -0.255
        FA.box(&m, V3(0.09, 0.15, 0.01), V3(ax, 0.105, 0.005), galv, r: 0.003)
        for sx: Float in [-1, 1] { for sy: Float in [-1, 1] { FSV.bolt(&m, at: V3(ax + sx * 0.03, 0.105 + sy * 0.055, 0.01), normal: FA.Z, size: 0.011, material: steel) } }
        FA.rod(&m, V3(ax, 0.108, 0.008), V3(ax, 0.108, 0.13), r: 0.0215, galv, sides: 16)
        FA.rod(&m, V3(ax, 0.04, 0.012), V3(ax, 0.1, 0.11), r: 0.0095, galv, sides: 10)
        FSV.cyl(&m, V3(ax, 0.108, 0.1), V3(ax, 0.108, 0.125), r: 0.0285, galv, bevel: 0.0025, segments: 18)
        for s: Float in [-1, 1] { FSV.bolt(&m, at: V3(ax + s * 0.0285, 0.108, 0.112), normal: V3(s, 0, 0), size: 0.011, material: steel) }
        // Housing: lofted tapered shell along X (superellipse rings), wider and taller toward the head (+X).
        let yb: Float = 0.058
        func hh(_ s: Float) -> Float { 0.036 + 0.026 * (1 - pow(abs(s - 0.06) / 0.36, 2.0)) }
        func dd(_ s: Float) -> Float { 0.05 + 0.07 * max(0, (s + 0.3) / 0.6) * (1 - pow(max(0, s - 0.1) / 0.2, 2.4) * 0.45) }
        var rings: [[V3]] = []
        for i in 0...16 {
            let s = -0.3 + 0.6 * Float(i) / 16
            let hw = max(hh(s), 0.02), dw = max(dd(s), 0.04)
            rings.append(Prim.ring(Shape2D.superellipse(2 * hw, 2 * dw, exponent: 3.4), y: s, offset: V3(-(yb + hw), 0, zc)))
        }
        m.add(Prim.loft(rings, capStart: true, capEnd: true, material: enamel), Xform(rotation: FA.q(-90, FA.Z)))
        // Ribbed cap line, hinge pair on the wall side, spring latch on the street side.
        for s: Float in [-0.08, 0.1] {
            FA.box(&m, V3(0.05, 0.02, 0.014), V3(s, yb + 0.02, zc - dd(s) + 0.002), enamel, r: 0.003)
            FSV.cyl(&m, V3(s - 0.022, yb + 0.02, zc - dd(s) - 0.003), V3(s + 0.022, yb + 0.02, zc - dd(s) - 0.003), r: 0.006, steel, bevel: 0.001, segments: 10)
        }
        FA.box(&m, V3(0.04, 0.026, 0.016), V3(0.1, yb + 0.02, zc + dd(0.1) + 0.002), "metal.aluminum-brushed", r: 0.003)
        FSV.cyl(&m, V3(0.1, yb + 0.008, zc + dd(0.1) + 0.006), V3(0.1, yb + 0.03, zc + dd(0.1) + 0.006), r: 0.004, steel, bevel: 0.0008, segments: 10)
        // Drop refractor bowl under the housing, prismatic ribs, rim gasket.
        let rr: [(Float, Float, Float)] = [(0.0, 0.5, 0.2), (0.012, 0.49, 0.192), (0.032, 0.42, 0.16), (0.05, 0.3, 0.1)]
        m.add(Prim.loft(rr.map { Prim.ring(Shape2D.superellipse($0.1, $0.2, exponent: 2.6), y: yb - $0.0, offset: V3(0.03, 0, zc + 0.01)) }, capStart: false, capEnd: true, material: "glass.polycarbonate"))
        for k in 0..<9 {
            FA.box(&m, V3(0.0016, 0.0016, 0.15 - abs(Float(k) - 4) * 0.01), V3(-0.12 + Float(k) * 0.03, yb - 0.0475 + abs(Float(k) - 4) * 0.0035, zc + 0.01), "glass.polycarbonate", r: 0.0003)
        }
        m.add(Prim.loft([Prim.ring(Shape2D.superellipse(0.504, 0.204, exponent: 2.6), y: yb + 0.002, offset: V3(0.03, 0, zc + 0.01)),
                         Prim.ring(Shape2D.superellipse(0.5, 0.2, exponent: 2.6), y: yb - 0.005, offset: V3(0.03, 0, zc + 0.01))], material: "rubber.seal"))
        // Photocell receptacle on top near the head: twist-lock base, cell body, window.
        let yt = yb + 2 * hh(0.1) - 0.004
        FSV.cyl(&m, V3(0.1, yt, zc), V3(0.1, yt + 0.01, zc), r: 0.03, "rubber.seal", bevel: 0.002, segments: 18)
        FSV.cyl(&m, V3(0.1, yt + 0.008, zc), V3(0.1, yt + 0.028, zc), r: 0.024, "plastic.black", bevel: 0.002, segments: 18)
        FSV.cyl(&m, V3(0.1, yt + 0.027, zc), V3(0.1, yt + 0.029, zc), r: 0.012, "glass.frosted", bevel: 0.0005, segments: 12)
        // Cast cooling ribs along the crown, cover bolts, and a mould parting bead down each flank.
        for off: Float in [-0.026, 0.026] {
            let pts: [V3] = (2...14).map { i in
                let s = -0.3 + 0.6 * Float(i) / 16
                return V3(s, yb + 2 * hh(s) - 0.001 + 0.002, zc + off * min(1, dd(s) / 0.09))
            }
            FA.path(&m, pts, r: 0.0026, enamel, sides: 6)
        }
        for k in 0..<4 { let x = -0.15 + Float(k) * 0.05; FSV.bolt(&m, at: V3(x, yb + 2 * hh(x) + 0.0005, zc), normal: FA.Y, size: 0.012, material: steel) }
        for sg: Float in [-1, 1] {
            let pts: [V3] = (1...15).map { i in
                let s = -0.3 + 0.6 * Float(i) / 16
                return V3(s, yb + hh(s) * 0.95, zc + sg * dd(s) * 0.995)
            }
            FA.path(&m, pts, r: 0.0022, "metal.painted:6D6B66", sides: 6)
        }
        FSV.streak(&m, at: V3(ax + 0.03, 0.04, 0.0105), w: 0.008, h: 0.03, "metal.rust")
        // Dust and bird streaks on the shell top.
        for _ in 0..<3 {
            let x = rng.float(-0.15...0.0)
            FA.box(&m, V3(0.025, 0.0012, 0.04), V3(x, yb + 2 * hh(x) + 0.0003, zc + rng.float(-0.02...0.02)), "metal.painted:B4B2AA", r: 0.0003)
        }
        return LODModel(FC.seatY(m))
    }
}
