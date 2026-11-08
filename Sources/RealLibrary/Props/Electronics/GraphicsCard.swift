import simd
import Foundation

/// Triple-fan consumer graphics card, 30 cm: black anodised shroud with three 86 mm fans, a dense
/// aluminium fin stack, four polished copper heatpipes, a vented backplate, a two-slot bracket with
/// display ports and a 12-pin power socket. Stands upright as it sits in a case: long axis +X, height +Y,
/// thickness +Z, base at y = 0, centered on X/Z. Bracket at -X, fan face at +Z.
public struct GraphicsCard: RealAsset {
    public static let id = "graphics-card"
    public static let summary = "Triple-fan graphics card, 30 cm: black shroud, 86 mm fans, aluminium fin stack, four copper heatpipes, vented backplate, bracket."
    public static let tags = ["prop", "electronics", "computer", "metal", "plastic"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 34, elevation: 18, distance: 0.62, studio: true)

    /// Overall length, height and thickness (m).
    public var length: Float = 0.300
    public var height: Float = 0.115
    public var thickness: Float = 0.055
    /// Fan centres along X (m).
    public var fanSpacing: Float = 0.090
    /// Material keys.
    public var shroud: MaterialKey = "metal.anodized-black"
    public var blade: MaterialKey = "plastic.matte:1A1B1E"
    public var trim: MaterialKey = "metal.aluminum-brushed"
    public var fins: MaterialKey = "metal.aluminum-fins"
    public var pcb: MaterialKey = "plastic.pcb"
    public var copper: MaterialKey = "copper.polished"
    public var bracket: MaterialKey = "metal.stainless"
    public var rgb: MaterialKey = "emissive.signal-white"
    public var socket: MaterialKey = "plastic.matte:0A0A0C"
    public var port: MaterialKey = "plastic.matte:050506"
    public init() {}

    private func fan(_ x: Float, _ z: Float, _ m: inout Model, _ rng: inout SeededRNG) {
        let y = height * 0.52
        let r: Float = 0.043
        // outer ring and recessed rim
        m.add(Prim.torus(major: r, minor: 0.0040, segments: 36, sides: 8, material: shroud),
              Xform(translation: V3(x, y, z + 0.001)))
        m.add(Prim.torus(major: r - 0.006, minor: 0.0018, segments: 36, sides: 6, material: trim),
              Xform(translation: V3(x, y, z + 0.004)))
        // hub, facing +Z
        let q = simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))
        m.add(Prim.cylinder(radius: 0.0145, height: 0.007, bevel: 0.0012, segments: 28, material: shroud),
              Xform(translation: V3(x, y, z + 0.003), rotation: q))
        m.add(Prim.cylinder(radius: 0.0105, height: 0.0012, bevel: 0.0004, segments: 28, material: trim),
              Xform(translation: V3(x, y, z + 0.0105), rotation: q))
        // 11 curved blades as swept slivers, pitched around the hub.
        for i in 0..<9 {
            let a = Float(i) / 9 * 2 * .pi
            let bladeS = Prim.superellipsoid(V3(0.0042, 0.030, 0.0016), exponent: 3.0, subdivisions: 1, material: blade)
            let rot = simd_quatf(angle: a, axis: V3(0, 0, 1)) * simd_quatf(angle: 0.38, axis: V3(1, 0, 0))
            let mid = V3(x + cos(a) * 0.023, y + sin(a) * 0.023, z + 0.007)
            m.add(bladeS, Xform(translation: mid, rotation: rot).jittered(&rng, deg: 0.6, offset: 0.0002))
        }
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let h = height, L = length, t = thickness, front = t * 0.5
        let yc = h * 0.52

        // Shroud plate behind the fans: a rounded slab with a raised centre spine.
        m.add(Prim.roundedBox(V3(L, h, 0.012), radius: 0.005, bevelSegments: 1, material: shroud),
              Xform(translation: V3(0, yc, front - 0.008)))
        // Fan wells.
        for i in -1...1 { fan(Float(i) * fanSpacing, front, &m, &rng) }

        // Fin stack: vertical aluminium plates visible through the fans and at the edges.
        let finCount = 22
        for i in 0..<finCount {
            let x = -L * 0.43 + L * 0.86 * Float(i) / Float(finCount - 1)
            m.add(Prim.roundedBox(V3(0.0012, h * 0.72, t * 0.52), radius: 0.0004, bevelSegments: 1, material: fins),
                  Xform(translation: V3(x, yc, -0.004)))
        }
        // Heatpipes: four copper tubes running the length, two high and two low.
        for (k, y) in [h * 0.30, h * 0.72].enumerated() {
            for zs: Float in [-0.006, 0.006] {
                let pipePath: [V3] = (0...10).map { j in
                    let u = Float(j) / 10
                    return V3(-L * 0.44 + L * 0.88 * u, y + 0.004 * sin(u * .pi),
                              zs + (k == 0 ? 0.002 : -0.002))
                }
                m.add(Prim.tube(pipePath, radii: pipePath.map { _ in 0.0028 }, sides: 10, seamTile: 0.05, material: copper))
            }
        }

        // PCB and backplate.
        m.add(Prim.roundedBox(V3(L * 0.94, h * 0.86, 0.0024), radius: 0.001, bevelSegments: 1, material: pcb),
              Xform(translation: V3(0, yc, -t * 0.5 + 0.010)))
        m.add(Prim.roundedBox(V3(L * 0.96, h * 0.92, 0.0040), radius: 0.002, bevelSegments: 1, material: shroud),
              Xform(translation: V3(0, yc, -t * 0.5 + 0.004)))
        // Backplate vents: four recessed black slots near the fan side.
        for i in 0..<4 {
            let x = -0.06 + Float(i) * 0.045
            m.add(Prim.roundedBox(V3(0.030, 0.008, 0.0016), radius: 0.001, bevelSegments: 1, material: port),
                  Xform(translation: V3(x, h * 0.78, -t * 0.5 + 0.0016)))
        }

        // Bracket at -X with three display port cut-outs.
        m.add(Prim.roundedBox(V3(0.0040, h * 0.94, t * 0.86), radius: 0.0012, bevelSegments: 1, material: bracket),
              Xform(translation: V3(-L * 0.5 - 0.002, yc, 0)))
        for i in 0..<3 {
            let y = h * 0.30 + Float(i) * 0.028
            m.add(Prim.roundedBox(V3(0.0014, 0.016, 0.026), radius: 0.001, bevelSegments: 1, material: port),
                  Xform(translation: V3(-L * 0.5 - 0.0045, y, 0.006)))
        }
        // Bracket screw tabs.
        for y in [h * 0.14, h * 0.86] {
            m.add(Prim.cylinder(radius: 0.0042, height: 0.0012, bevel: 0.0004, segments: 16, material: bracket),
                  Xform(translation: V3(-L * 0.5 - 0.0045, y, 0.0), rotation: simd_quatf(angle: .pi / 2, axis: V3(0, 1, 0))))
        }

        // 12-pin power socket on the top edge, with pin block.
        m.add(Prim.roundedBox(V3(0.030, 0.011, 0.014), radius: 0.0015, bevelSegments: 1, material: socket),
              Xform(translation: V3(L * 0.30, h - 0.005, 0.010)))
        for i in 0..<6 {
            for j in 0..<2 {
                m.add(Prim.roundedBox(V3(0.0016, 0.0022, 0.0016), radius: 0.0003, bevelSegments: 1, material: "metal.brass"),
                      Xform(translation: V3(L * 0.30 - 0.011 + Float(i) * 0.0044, h - 0.004,
                                            0.010 - 0.003 + Float(j) * 0.006)))
            }
        }

        // RGB light bar along the top front edge and a small illuminated logo-free badge.
        m.add(Prim.roundedBox(V3(L * 0.72, 0.0030, 0.0022), radius: 0.001, bevelSegments: 1, material: rgb),
              Xform(translation: V3(0, h - 0.003, front + 0.001)))
        m.add(Prim.roundedBox(V3(0.030, 0.004, 0.0018), radius: 0.001, bevelSegments: 1, material: rgb),
              Xform(translation: V3(L * 0.36, h * 0.78, front + 0.0008)))

        // Silver edge trim on both long sides.
        for sy: Float in [0.012, h - 0.012] {
            m.add(Prim.roundedBox(V3(L * 0.98, 0.0022, t * 0.72), radius: 0.0008, bevelSegments: 1, material: trim),
                  Xform(translation: V3(0, sy, 0)))
        }

        let b = m.bounds
        m = m.transformed(Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2)))
        groundAO(&m, height: 0.015, floor: 0.35)
        return LODModel(m)
    }
}
