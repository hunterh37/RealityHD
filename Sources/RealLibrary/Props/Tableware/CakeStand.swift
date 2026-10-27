import simd
import Foundation

/// Shared helpers for the DD1I tableware props.
enum DD1ITableware {
    /// Closed oval ring of `n` points at height `y`.
    static func oval(_ rx: Float, _ rz: Float, y: Float, n: Int = 64) -> [V3] {
        (0..<n).map { k in
            let a = Float(k) / Float(n) * 2 * .pi
            return V3(rx * cos(a), y, rz * sin(a))
        }
    }
    /// Arc of (radius, y) profile points around `center`.
    static func arc(center: V2, r: Float, from a0: Float, to a1: Float, steps: Int) -> [V2] {
        (0...steps).map { k in
            let a = a0 + (a1 - a0) * Float(k) / Float(steps)
            return center + V2(r * cos(a), r * sin(a))
        }
    }
    /// Flat plate lying on XZ from an XY outline (extrude depth runs along Y after the turn).
    static let lay = simd_quatf(degrees: 90, axis: V3(1, 0, 0))
}

/// Cake stand: everyday tableware, porcelain. A 28 cm dished plate with a rolled lip sits on a turned,
/// beaded pedestal over an unglazed foot ring. A brass-aged cap nut holds the plate down, the stem glaze
/// has yellowed against the plate, and a small chip shows body at the lip.
public struct CakeStand: RealAsset {
    public static let id = "cake-stand"
    public static let summary = "Porcelain cake stand: 28 cm plate on a turned beaded pedestal with unglazed foot ring and a chipped rim."
    public static let tags = ["prop", "interior", "tableware", "ceramic"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 24, distance: 0.62, studio: true)

    /// Plate diameter (m).
    public var diameter: Float = 0.28
    /// Plate glaze.
    public var plateGlaze: MaterialKey = "ceramic.vitreous:F3EEE2"
    /// Pedestal glaze, slightly yellowed.
    public var stemGlaze: MaterialKey = "ceramic.vitreous:E6DCC2"
    /// Unglazed foot ring.
    public var foot: MaterialKey = "ceramic.bisque:E6E0D2"
    /// Cap nut.
    public var nut: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let R = diameter / 2, P: Float = 0.126
        let seg = 56
        // Pedestal: foot, neck, two beads, collar.
        let ped: [V2] = [V2(0, 0.004), V2(0.048, 0.0035), V2(0.0535, 0.0012), V2(0.0575, 0.0012), V2(0.0595, 0.0035), V2(0.0585, 0.0075),
                         V2(0.052, 0.0125), V2(0.04, 0.0175), V2(0.028, 0.0235), V2(0.0195, 0.031), V2(0.0165, 0.038),
                         V2(0.0225, 0.042), V2(0.0245, 0.046), V2(0.0225, 0.05), V2(0.0155, 0.054),
                         V2(0.0135, 0.06), V2(0.0135, 0.074),
                         V2(0.021, 0.0785), V2(0.0235, 0.0835), V2(0.021, 0.0885), V2(0.0145, 0.093),
                         V2(0.0125, 0.099), V2(0.0125, 0.108),
                         V2(0.0185, 0.1115), V2(0.027, 0.1155), V2(0.045, 0.1205), V2(0.06, 0.1235), V2(0.03, P - 0.001), V2(0, P - 0.001)]
        m.add(Prim.lathe(ped, segments: seg, seamTile: 0.3, material: stemGlaze))
        // Unglazed ring on the underside of the foot.
        let ring: [V2] = [V2(0.0515, 0.0005), V2(0.0575, 0.0005), V2(0.0575, -0.0002), V2(0.0515, -0.0002), V2(0.0515, 0.0005)]
        m.add(Prim.lathe(ring, segments: seg, seamTile: 0.3, material: foot))
        // Plate: dished with a rolled lip.
        var plate: [V2] = [V2(0, P), V2(0.06, P + 0.001), V2(0.12, P + 0.002), V2(R - 0.0045, P + 0.0046)]
        plate += DD1ITableware.arc(center: V2(R - 0.0045, P + 0.0095), r: 0.0048, from: -Float.pi / 2, to: Float.pi / 2, steps: 8)
        plate += [V2(R - 0.011, P + 0.0125), V2(R - 0.02, P + 0.0108), V2(0.1, P + 0.0098), V2(0.05, P + 0.0089), V2(0, P + 0.0085)]
        var pl = Prim.lathe(plate, segments: seg + 16, seamTile: 0.3, material: plateGlaze)
        pl.recomputeNormals()
        m.add(pl)
        // Cap nut: dome on a washer.
        let capP: [V2] = [V2(0, P + 0.0085), V2(0.0135, P + 0.0085), V2(0.0135, P + 0.0095), V2(0.0098, P + 0.0098), V2(0.0098, P + 0.0115),
                          V2(0.0085, P + 0.0145), V2(0.0055, P + 0.0162), V2(0, P + 0.0168)]
        m.add(Prim.lathe(capP, segments: 24, seamTile: 0.05, material: nut))
        // Chip at the lip: exposed body plus a hairline crack running in.
        let ca = rng.float(0.4...1.1)
        let chipPos = V3((R - 0.0015) * cos(ca), P + 0.0105, (R - 0.0015) * sin(ca))
        m.add(Prim.superellipsoid(V3(0.014, 0.006, 0.006), exponent: 3, subdivisions: 4, material: "ceramic.porcelain-fracture"),
              Xform(translation: chipPos, rotation: simd_quatf(degrees: -ca * 180 / .pi, axis: .up)))
        m.add(Prim.extrude([V2(0, -0.00008), V2(0.026, -0.00004), V2(0.026, 0.00004), V2(0, 0.00008)], depth: 0.00012, bevel: 0.00003, bevelSegments: 1, material: "ceramic.porcelain-fracture"),
              Xform(translation: V3((R - 0.019) * cos(ca), P + 0.0108, (R - 0.019) * sin(ca)), rotation: simd_quatf(degrees: -ca * 180 / .pi, axis: .up) * DD1ITableware.lay))
        // Cutlery scuffs and cake crumbs on the plate.
        // Worn gilt line on the lip: short surviving arcs.
        for g in 0..<9 {
            let a0 = Float(g) / 9 * 2 * .pi + rng.float(0...0.2), len = rng.float(0.2...0.5)
            let pts = (0...6).map { i -> V3 in
                let a = a0 + len * Float(i) / 6
                return V3((R - 0.0044) * cos(a), P + 0.0143, (R - 0.0044) * sin(a))
            }
            m.add(Prim.tube(pts, radii: Array(repeating: 0.00085, count: 7), sides: 4, seamTile: 0.01, material: nut))
        }
        for k in 0..<7 {
            let r0 = rng.float(0.055...0.1), a0 = rng.float(0...6.28), len = rng.float(0.25...0.7)
            let pts = (0...6).map { i -> V3 in
                let a = a0 + len * Float(i) / 6
                return V3(r0 * cos(a), P + 0.0096 + 0.0003, r0 * sin(a))
            }
            m.add(Prim.tube(pts, radii: Array(repeating: 0.0004 + 0.00015 * Float(k % 3), count: 7), sides: 3, seamTile: 0.01, material: "ceramic.vitreous:BFBBB1"))
        }
        for _ in 0..<7 {
            let a = rng.float(0...6.28), d = rng.float(0.03...0.09)
            m.add(Prim.superellipsoid(V3(rng.float(0.002...0.004), 0.0018, rng.float(0.002...0.0035)), exponent: 3, subdivisions: 3, material: "food.bread-crumb"),
                  Xform(translation: V3(d * cos(a), P + 0.0105, d * sin(a)), rotation: simd_quatf(degrees: rng.float(0...360), axis: .up)))
        }
        // Tea ring stain on the plate and hairline crazing on the stem.
        let ringPts = (0...40).map { i -> V3 in
            let a = Float(i) / 40 * 2 * .pi * 0.85 + 0.8
            return V3(0.058 * cos(a), P + 0.0100, 0.058 * sin(a))
        }
        m.add(Prim.tube(ringPts, radii: Array(repeating: 0.0011, count: ringPts.count), sides: 3, seamTile: 0.01, material: "ceramic.vitreous:CDBB92"))
        for k in 0..<5 {
            let a = Float(k) * 1.3 + 0.2
            let y0 = rng.float(0.03...0.06)
            let pts = (0...4).map { i -> V3 in
                let t = Float(i) / 4
                return V3(0.0185 * cos(a + 0.12 * t), y0 + 0.03 * t, 0.0185 * sin(a + 0.12 * t))
            }
            m.add(Prim.tube(pts, radii: Array(repeating: 0.00025, count: 5), sides: 3, seamTile: 0.01, material: "ceramic.vitreous:A89F86"))
        }
        let grime: [V2] = [V2(0.0528, 0.0004), V2(0.0576, 0.0004), V2(0.0592, 0.0035), V2(0.0584, 0.0075), V2(0.0568, 0.0092), V2(0.0553, 0.0075), V2(0.0528, 0.0004)]
        m.add(Prim.lathe(grime, segments: 40, seamTile: 0.3, material: "ceramic.bisque:B8AC92"))
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(0, -b.min.y, 0)))
        groundAO(&m, height: 0.03, floor: 0.7)
        return LODModel(m)
    }
}
