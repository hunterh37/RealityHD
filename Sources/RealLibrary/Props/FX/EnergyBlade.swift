import simd
import Foundation

/// Energy blade: Clean machined anodized metal, hot white core with cyan shell. Parts: Machined hilt 28 cm with grip ridges, Pommel cap, Guard ring and emitter shroud, Core blade 0.9 m, emissive, Soft outer glow shell.
public struct EnergyBlade: RealAsset {
    public static let id = "energy-blade"
    public static let summary = "Sci-fi energy sword: 28 cm machined hilt, 0.9 m glowing blade. Grip origin at handle center, blade along +Y."
    public static let tags = ["prop", "handheld", "fx", "metal", "light"]
    public static let budget = 11000
    public static let author = "realityhd"

    /// Blade shell material (one of the emissive.* keys: thruster-cyan, signal-red, signal-green, signal-orange, amber).
    public var bladeColor: MaterialKey = "emissive.thruster-cyan"
    /// Hilt length in meters, centered on the grip at the origin.
    public var hiltLength: Float = 0.28
    /// Blade length in meters, from the emitter along +Y.
    public var bladeLength: Float = 0.9
    public init() {}

    /// Rounded-diamond blade section lofted along +Y, tip closed with a short taper.
    private func bladeLoft(width: Float, thick: Float, y0: Float, y1: Float, material: MaterialKey) -> Surface {
        let sec = Shape2D.superellipse(width, thick, exponent: 3)
        func ring(_ s: Float, _ y: Float) -> [V3] { Prim.ring(sec.map { V2($0.x * s, $0.y * s) }, y: y) }
        var rings = [ring(0.55, y0), ring(1, y0 + 0.012)]
        let n = 6
        for i in 1...n { let t = Float(i) / Float(n); rings.append(ring(1, y0 + 0.012 + (y1 - y0 - 0.05) * t)) }
        for (s, d) in [(0.9, 0.012), (0.6, 0.026), (0.25, 0.038)] as [(Float, Float)] { rings.append(ring(s, y1 - 0.05 + d)) }
        rings.append(ring(0.02, y1))
        return Prim.loft(rings, capStart: true, capEnd: true, material: material)
    }

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let h = hiltLength / 2
        let gun: MaterialKey = "metal.anodized-gunmetal", chrome: MaterialKey = "metal.chrome", rubber: MaterialKey = "rubber"
        // Pommel cap and neck.
        m.add(turned([(0, -h), (0.011, -h), (0.0165, -h + 0.004), (0.0175, -h + 0.014), (0.014, -h + 0.02), (0.0125, -h + 0.024), (0, -h + 0.024)], segments: 24, material: gun))
        // Grip core with ridge rings every 8 mm.
        let g0 = -h + 0.024, g1 = h - 0.1
        var prof: [(Float, Float)] = [(0, g0), (0.0115, g0)]
        var y = g0 + 0.004
        while y < g1 - 0.006 {
            prof += [(0.0115, y), (0.0122, y + 0.0012), (0.0138, y + 0.0028), (0.0138, y + 0.0042), (0.0122, y + 0.0058), (0.0115, y + 0.007)]
            y += 0.0085
        }
        prof += [(0.0115, g1), (0, g1)]
        m.add(turned(prof, segments: 24, material: rubber, seamTile: 0.05))
        // Activation stud and chrome pressure ring.
        m.add(Prim.roundedBox(V3(0.007, 0.012, 0.006), radius: 0.0015, bevelSegments: 2, material: chrome), Xform(translation: V3(0, g1 - 0.035, 0.0135)))
        m.add(turned([(0.0115, g1), (0.0172, g1), (0.0176, g1 + 0.002), (0.0176, g1 + 0.012), (0.0172, g1 + 0.014), (0.0115, g1 + 0.014)], segments: 24, material: chrome))
        // Machined body section with flutes, then guard ring.
        let b0 = g1 + 0.014, b1 = h - 0.05
        m.add(turned([(0.0115, b0), (0.0155, b0), (0.0165, b0 + 0.004), (0.0165, b1 - 0.004), (0.0155, b1), (0.0115, b1)], segments: 24, material: gun))
        for k in 0..<8 {
            let a = Float(k) / 8 * 2 * .pi
            m.add(Prim.roundedBox(V3(0.0022, b1 - b0 - 0.02, 0.0016), radius: 0.0006, bevelSegments: 1, material: chrome),
                  Xform(translation: V3(cos(a) * 0.0166, (b0 + b1) / 2, sin(a) * 0.0166), rotation: simd_quatf(angle: -a + .pi / 2, axis: .up)))
        }
        m.add(turned([(0.0115, b1), (0.019, b1), (0.0225, b1 + 0.003), (0.0225, b1 + 0.008), (0.019, b1 + 0.011), (0.0115, b1 + 0.011)], segments: 28, material: chrome))
        // Emitter shroud: flared cup holding the emitter lens.
        let e0 = b1 + 0.011
        m.add(turned([(0.0115, e0), (0.0165, e0), (0.019, e0 + 0.014), (0.0215, e0 + 0.03), (0.0215, e0 + 0.036), (0.0195, e0 + 0.039), (0.0165, e0 + 0.039), (0.0165, e0 + 0.036), (0.0125, e0 + 0.0345), (0.0, e0 + 0.0345)], segments: 28, material: gun))
        // Blade: soft shell (wide, thin) crossed by a hot core (narrow, thick) so the white shows as a bright line.
        let by0 = e0 + 0.0335
        m.add(bladeLoft(width: 0.034, thick: 0.014, y0: by0, y1: by0 + bladeLength, material: bladeColor))
        m.add(bladeLoft(width: 0.011, thick: 0.019, y0: by0 + 0.004, y1: by0 + bladeLength - 0.012, material: "emissive.signal-white"))
        return LODModel(m)
    }
}
