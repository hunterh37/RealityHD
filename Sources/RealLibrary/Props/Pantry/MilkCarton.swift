import simd
import Foundation

/// Milk carton: everyday pantry, paperboard. 7 x 7 cm gable-top carton, 24 cm tall: laminated paperboard body
/// with a vertical glue seam, a blue printed wrap with a white drop badge and text bars (geometry, no brand),
/// sloped gable roof with crease lines, a flat sealed fin on top, and a plastic screw cap on the front slope.
/// Corners are scuffed and one side shows a handling crease.
public struct MilkCarton: RealAsset {
    public static let id = "milk-carton"
    public static let summary = "Paperboard gable-top milk carton with fin seam, folded spout and screw cap."
    public static let tags = ["prop", "interior", "pantry", "paper", "plastic"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 20, distance: 1.05, studio: true)

    /// Paperboard.
    public var board: MaterialKey = "paper.sheet:F1EFE8"
    /// Printed blue wrap.
    public var wrap: MaterialKey = "paper.sheet:2F6DB3"
    /// Scuffed board.
    public var scuff: MaterialKey = "paper.sheet:CBC7BB"
    /// Cap.
    public var cap: MaterialKey = "plastic.white"
    public init() {}

    private func sx(_ k: Int) -> Float { k % 2 == 0 ? -1 : 1 }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let h: Float = 0.035, H: Float = 0.18, roofTop: Float = 0.214, finTop: Float = 0.24
        var bodyS = Prim.roundedBox(V3(0.07, H, 0.07), radius: 0.0016, bevelSegments: 2, material: board)
        bodyS.displace { p, n in -0.0014 * exp(-(pow(p.x + 0.012, 2) + pow(p.y - 0.07, 2)) / 0.00012) * (n.z < -0.5 ? 1 : 0) }
        m.add(bodyS, Xform(translation: V3(0, H / 2, 0)))
        // Water-stain band on the lower body.
        var stainBand = Prim.loft([Prim.ring(Shape2D.roundedRect(0.0704, 0.0704, radius: 0.0016, segments: 3), y: 0.005),
                                   Prim.ring(Shape2D.roundedRect(0.0704, 0.0704, radius: 0.0016, segments: 3), y: 0.03)], material: "paper.sheet:B9B3A2")
        stainBand.recomputeNormals()
        m.add(stainBand)
        // Bottom fold flange.
        m.add(Prim.roundedBox(V3(0.0712, 0.005, 0.0712), radius: 0.0016, bevelSegments: 2, material: board), Xform(translation: V3(0, 0.0025, 0)))
        // Gable roof: square section to the flat ridge.
        var roof = Prim.loft([Prim.ring(Shape2D.roundedRect(0.07, 0.07, radius: 0.0016, segments: 3), y: H - 0.0005),
                              Prim.ring(Shape2D.roundedRect(0.07, 0.006, radius: 0.0022, segments: 3), y: roofTop)], capEnd: true, material: board)
        roof.recomputeNormals()
        m.add(roof)
        // Sealed fin with crimp ridges.
        m.add(Prim.roundedBox(V3(0.07, finTop - roofTop + 0.002, 0.0046), radius: 0.0007, bevelSegments: 1, material: board),
              Xform(translation: V3(0, (finTop + roofTop - 0.002) / 2, 0)))
        for k in 0..<6 {
            let y = roofTop + 0.003 + Float(k) * 0.0042
            m.add(Prim.roundedBox(V3(0.0685, 0.0011, 0.0052), radius: 0.0004, bevelSegments: 1, material: scuff),
                  Xform(translation: V3(0, y, 0)))
        }
        // Roof creases from the corners to the ridge ends.
        for sx: Float in [-1, 1] {
            for sz: Float in [-1, 1] {
                m.add(Prim.tube([V3(sx * h, H, sz * h), V3(sx * h * 0.99, (H + roofTop) / 2, sz * 0.0195), V3(sx * h, roofTop, sz * 0.003)], radii: [0.0004, 0.0004, 0.0004], sides: 4, seamTile: 0.01, material: scuff))
            }
        }
        // Printed wrap around the body.
        var band = Prim.loft([Prim.ring(Shape2D.roundedRect(0.0706, 0.0706, radius: 0.0016, segments: 3), y: 0.031),
                              Prim.ring(Shape2D.roundedRect(0.0706, 0.0706, radius: 0.0016, segments: 3), y: 0.125)], material: wrap)
        band.recomputeNormals()
        m.add(band)
        // White drop badge and text bars on the front.
        m.add(Prim.extrude(Shape2D.circle(0.017, ry: 0.022, segments: 24), depth: 0.0008, bevel: 0.0002, bevelSegments: 1, material: "paper.sheet:F4F2EC"),
              Xform(translation: V3(0, 0.083, h + 0.0004)))
        for (i, w) in ([0.044, 0.036, 0.028] as [Float]).enumerated() {
            m.add(Prim.roundedBox(V3(w, 0.004, 0.0007), radius: 0.0002, bevelSegments: 1, material: "paper.sheet:F4F2EC"),
                  Xform(translation: V3(0, 0.052 - Float(i) * 0.0075, h + 0.0004)))
        }
        // Nutrition panel on the right side: frame, rows and a recycling mark.
        m.add(Prim.roundedBox(V3(0.0006, 0.062, 0.05), radius: 0.0002, bevelSegments: 1, material: "paper.sheet:F4F2EC"), Xform(translation: V3(h + 0.0003, 0.1, 0.0)))
        for r in 0..<9 {
            m.add(Prim.roundedBox(V3(0.0008, 0.0014, 0.04 - 0.002 * Float(r % 3)), radius: 0.0002, bevelSegments: 1, material: "paper.sheet:2F6DB3"), Xform(translation: V3(h + 0.0006, 0.122 - Float(r) * 0.0053, 0.0)))
        }
        // Vertical glue seam on the back.
        m.add(Prim.roundedBox(V3(0.012, 0.17, 0.0008), radius: 0.0003, bevelSegments: 1, material: "paper.sheet:E6E2D8"),
              Xform(translation: V3(0.018, 0.09, -h - 0.0002)))
        // Screw cap on the front slope.
        let ang: Float = 43
        let cz = h - 0.45 * 0.032, cy = H + 0.45 * (roofTop - H)
        let slope = Xform(translation: V3(0, cy, cz), rotation: simd_quatf(degrees: ang, axis: V3(1, 0, 0)))
        m.add(Prim.cylinder(radius: 0.0125, height: 0.0016, bevel: 0.0006, segments: 20, bevelSegments: 1, material: "plastic.white:F1F1EC"), slope)
        var capS = Prim.cylinder(radius: 0.0112, height: 0.0125, bevel: 0.0014, segments: 28, bevelSegments: 2, material: cap)
        capS.displace { p, n in abs(n.y) > 0.6 ? 0 : 0.0003 * sin(atan2(p.z, p.x) * 24) }
        m.add(capS, Xform(translation: slope.translation, rotation: slope.rotation).applying(V3(0, 0.0014, 0)))
        // Scuffed corners and a handling crease.
        for k in 0..<8 {
            let side = k % 3 == 0
            let y = rng.float(0.03...0.15), off = rng.float(-0.026...0.026)
            let size = V3(0.0045, rng.float(0.012...0.032), 0.0005)
            m.add(Prim.roundedBox(side ? V3(size.z, size.y, size.x) : size, radius: 0.00018, bevelSegments: 1, material: scuff),
                  Xform(translation: side ? V3(h + 0.0004, y, off) : V3(sx(k) * (h - 0.0035), y, h + 0.0004)))
        }
        m.add(Prim.roundedBox(V3(0.0006, 0.07, 0.0009), radius: 0.0002, bevelSegments: 1, material: scuff),
              Xform(translation: V3(h + 0.0004, 0.095, 0.004), rotation: simd_quatf(degrees: 6, axis: V3(0, 0, 1))))
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(0, -b.min.y, 0)))
        groundAO(&m, height: 0.04, floor: 0.7)
        return LODModel(m)
    }
}

private extension Xform {
    /// Moves along local axes by `v` after applying this transform's rotation.
    func applying(_ v: V3) -> Xform {
        var x = self
        x.translation += rotation.act(v)
        return x
    }
}
