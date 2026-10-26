import simd
import Foundation

/// Federal elliptical fanlight, 1.6 x 0.8 x 0.15 m, painted timber: half-ellipse frame with a moulded section and a row of
/// beads around the rim, eleven radiating muntins from the hub, two nested web ellipses with drooping swags between the bars,
/// a carved central fan of nine petals, a keystone block, and a moulded impost bar closed by end blocks with brass-centred paterae.
/// Wall plane at z = 0, piece projecting toward +Z.
public struct FederalEllipticalFanlight: RealAsset {
    public static let id = "federal-elliptical-fanlight"
    public static let summary = "Federal elliptical fanlight, 1.6 m: half-ellipse frame, radiating muntins, web arcs, central fan, beaded rim, keystone, impost with paterae."
    public static let tags = ["prop", "architecture", "facade", "trim", "wood"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 8, distance: 3.0)

    /// Painted frame, muntins and fan.
    public var paint: MaterialKey = "wood.painted-exterior:DDD2B6"
    /// Aged paint on the blocks and the lower frame.
    public var worn: MaterialKey = "wood.barn-white"
    /// Paterae centres.
    public var brass: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let base: Float = 0.1
        let rx: Float = 0.73, ry: Float = 0.625       // clear opening
        let hub = V3(0, base, 0)

        // Impost bar and end blocks.
        let imp: [V2] = [V2(0, 0), V2(0.12, 0), V2(0.12, 0.01), V2(0.145, 0.02), V2(0.145, 0.06), V2(0.12, 0.075), V2(0.12, base), V2(0, base)]
        FA.run(&m, imp, length: 1.36, at: .zero, paint, bevel: 0.002)
        for s: Float in [-1, 1] {
            FA.box(&m, V3(0.12, 0.125, 0.14), V3(s * 0.74, 0.0625, 0.07), worn, r: 0.004)
            FA.box(&m, V3(0.125, 0.012, 0.145), V3(s * 0.74, 0.125, 0.0725), paint, r: 0.003)
            FO7.rosette(&m, at: V3(s * 0.74, 0.06, 0.136), r: 0.034, petals: 8, paint)
            FC.bead(&m, r: 0.01, at: V3(s * 0.74, 0.06, 0.1385), brass, sub: 3)
        }

        // Moulded half-ellipse frame, swept along the opening edge (profile x projection, y outward).
        let edge = FO7.ellipse(c: V2(0, base), rx: rx, ry: ry, from: 0, to: 180, steps: 36, z: 0)
        let prof: [V2] = [V2(0, 0), V2(0.1, 0), V2(0.1, 0.01), V2(0.12, 0.022), V2(0.12, 0.045), V2(0.14, 0.055), V2(0.14, 0.07), V2(0, 0.07)]
        m.add(Prim.sweep(prof, along: edge, up: V3(0, 0, 1), material: paint))
        // Bead row around the rim.
        let rim = FO7.ellipse(c: V2(0, base), rx: rx + 0.0575, ry: ry + 0.0575, from: 2, to: 178, steps: 52, z: 0.1365)
        for p in rim { FC.bead(&m, r: 0.0075, at: p, paint, sub: 2) }

        // Glass: half-ellipse sheet recessed in the frame.
        var outline: [V2] = [V2(-rx + 0.01, 0), V2(rx - 0.01, 0)]
        for p in FO7.ellipse(c: V2(0, 0), rx: rx - 0.01, ry: ry - 0.01, from: 0, to: 180, steps: 36, z: 0) { outline.append(V2(p.x, p.y)) }
        m.add(Prim.extrude(FO7.ccw(Shape2D.deduped(outline)), depth: 0.008, bevel: 0.0005, bevelSegments: 1, material: "glass.tinted"),
              Xform(translation: V3(0, base + 0.002, 0.05)))

        // Radiating muntins from the hub, eleven bars.
        let nB = 11
        func rimPoint(_ k: Int, scale: Float, z: Float) -> V3 {
            let a = Float(k) * .pi / Float(nB + 1)
            return V3(cos(a) * rx * scale, base + sin(a) * ry * scale, z)
        }
        for k in 1...nB {
            FA.rod(&m, hub + V3(0, 0.01, 0.07), rimPoint(k, scale: 0.995, z: 0.07), r: 0.0075, paint, sides: 6)
        }
        // Nested web ellipses and drooping swags between neighbouring bars.
        for sc in [Float(0.38), 0.66, 0.9] {
            let ring = FO7.ellipse(c: V2(0, base), rx: rx * sc, ry: ry * sc, from: 2, to: 178, steps: 24, z: 0.075)
            FA.path(&m, ring, r: 0.0065, paint, sides: 6)
        }
        for sc in [Float(0.52), 0.78] {
            for k in 1..<nB {
                let a = rimPoint(k, scale: sc, z: 0.072), b = rimPoint(k + 1, scale: sc, z: 0.072)
                let mid = (a + b) / 2
                let toHub = simd_normalize(V3(hub.x - mid.x, hub.y - mid.y, 0))
                let sag = mid + toHub * 0.045
                FA.path(&m, [a, (a + sag) / 2 + toHub * 0.008, sag, (b + sag) / 2 + toHub * 0.008, b], r: 0.0055, paint, sides: 5)
            }
        }
        // Central carved fan: nine petals around the hub and a hub boss.
        for k in 0..<9 {
            let a = (Float(k) + 0.5) * .pi / 9
            let dir = V3(cos(a), sin(a), 0)
            m.add(Prim.superellipsoid(V3(0.05, 0.19, 0.03), exponent: 2, subdivisions: 3, material: paint),
                  Xform(translation: hub + dir * 0.13 + V3(0, 0.02, 0.085), rotation: FA.q(a * 180 / .pi - 90, FA.Z)))
        }
        m.add(Prim.superellipsoid(V3(0.1, 0.05, 0.05), exponent: 2, subdivisions: 4, material: paint), Xform(translation: hub + V3(0, 0.02, 0.095)))

        // Keystone block at the crown, with a drop.
        FA.box(&m, V3(0.1, 0.085, 0.145), V3(0, base + ry + 0.035, 0.0725), worn, r: 0.004)
        m.add(Prim.superellipsoid(V3(0.04, 0.05, 0.02), exponent: 2, subdivisions: 3, material: paint), Xform(translation: V3(0, base + ry + 0.04, 0.139)))

        // Wear: flaking paint on the lower frame, a soot run from the keystone, dirt on the glass at the bar roots.
        FO7.streak(&m, x: -0.71, top: 0.3, w: 0.05, h: 0.14, z: 0.139, "wood.trim-weathered")
        FO7.streak(&m, x: 0.69, top: 0.26, w: 0.03, h: 0.1, z: 0.139, "wood.trim-weathered")
        FO7.streak(&m, x: 0, top: base + ry, w: 0.02, h: 0.18, z: 0.0695, "wood.trim-weathered")
        for _ in 0..<5 {   // chipped paint on the impost bar front
            let x = rng.float(-0.6...0.6)
            FO7.streak(&m, x: x, top: rng.float(0.05...0.095), w: rng.float(0.03...0.09), h: rng.float(0.015...0.04), z: 0.1445, "wood.trim-weathered")
        }
        for _ in 0..<4 {
            let k = rng.int(1...nB)
            FA.box(&m, V3(0.04, 0.012, 0.006), rimPoint(k, scale: 0.12, z: 0.058) + V3(0, 0.03, 0), "wood.trim-weathered", r: 0.002)
        }

        groundAO(&m, height: 0.1, floor: 0.9)
        return LODModel(FA.centerZ(FC.seatY(m)))
    }
}
