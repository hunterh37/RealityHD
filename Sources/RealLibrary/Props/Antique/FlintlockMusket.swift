import simd
import Foundation

/// 1775 British Land Pattern flintlock musket, 1.45 m: full walnut stock with wrist swell and cheek relief, brass butt
/// plate, trigger guard, side plate and three barrel bands, 1.0 m blued round barrel, brass sights, flintlock with
/// frizzen, pan, cock with flint in leather jaws, mainspring and screws, ramrod in pipes, sling swivels.
/// Origin at the lock plate center, barrel along +Z, butt toward -Z, up +Y, lock on the +X side.
///
/// Articulated: `cock` swings the hammer forward 0...50 degrees onto the frizzen. States: cocked, fired.
public struct FlintlockMusket: RealArticulated {
    public static let id = "flintlock-musket"
    public static let summary = "1775 British Land Pattern flintlock musket, 1.45 m: walnut full stock, blued steel barrel, brass furniture, flintlock with flint in leather jaws, ramrod and sling swivels."
    public static let tags = ["prop", "antique", "handheld", "wood", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 62, elevation: 10, distance: 1.0, studio: true)

    /// Full stock and ramrod.
    public var wood: MaterialKey = "wood.walnut-stock"
    /// Barrel, blued with wear at the muzzle.
    public var steel: MaterialKey = "metal.blued-steel"
    /// Lock plate, frizzen, screws, mainspring.
    public var bright: MaterialKey = "metal.steel"
    /// Furniture and sights.
    public var brass: MaterialKey = "metal.brass-aged"
    /// Cock jaw wrap.
    public var leather: MaterialKey = "leather.tan"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [4])
        // Build space: x along the barrel from the butt, y up, z toward the stock's left side. Final: x -> +Z, z -> -X.
        let R = simd_quatf(angle: -.pi / 2, axis: V3(0, 1, 0))
        let off = V3(-0.36, 0.010, 0)
        func fp(_ v: V3) -> V3 { R.act(v + off) }
        func at(_ t: V3 = .zero, _ q: simd_quatf = .identity) -> Xform { Xform(translation: fp(t), rotation: R * q) }
        let woodM = wood, steelM = steel, brightM = bright, brassM = brass, leatherM = leather
        let tumbler = V3(0.345, -0.008, 0.0)

        rig.part("cock", pivot: fp(tumbler), joint: .hinge(axis: R.act(V3(0, 0, -1)), 0...50, duration: 0.2))

        for lod in 0..<2 {
            let hi = lod == 0, L = lod...lod, seg = hi ? 24 : 10, ws = hi ? 8 : 5
            func base(_ s: Surface, _ x: Xform) { rig.base[lod].add(s, x) }
            func box(_ c: V3, _ size: V3, r: Float = 0.002, rot: simd_quatf = .identity, _ mat: MaterialKey) -> Surface {
                Prim.roundedBox(size, radius: r, bevelSegments: 1, material: mat).transformed(Xform(translation: c, rotation: rot))
            }

            // Full stock: butt with comb and cheek relief, wrist swell, belly, forend to 1.20 m.
            let outline: [V2] = [V2(0, 0.030), V2(0.06, 0.036), V2(0.14, 0.032), V2(0.22, 0.020), V2(0.30, 0.010), V2(0.36, 0.006),
                                 V2(0.46, 0.0), V2(1.19, 0.0), V2(1.205, -0.010), V2(1.205, -0.026), V2(1.19, -0.032),
                                 V2(0.62, -0.034), V2(0.50, -0.040), V2(0.42, -0.050), V2(0.37, -0.062), V2(0.34, -0.060),
                                 V2(0.29, -0.058), V2(0.25, -0.066), V2(0.17, -0.078), V2(0.08, -0.090), V2(0.012, -0.098), V2(0, -0.088)]
            func width(_ x: Float) -> Float {
                x < 0.14 ? lerp(0.040, 0.034, smoothstep(0, 0.14, x))
                : x < 0.26 ? lerp(0.034, 0.030, smoothstep(0.14, 0.26, x))
                : x < 0.40 ? lerp(0.030, 0.048, smoothstep(0.26, 0.38, x))
                : lerp(0.048, 0.030, smoothstep(0.40, 0.62, x))
            }
            var stock = Prim.extrude(Shape2D.rounded(outline, radius: 0.02, segments: hi ? 4 : 1), depth: 0.04, bevel: 0.006, bevelSegments: hi ? 2 : 1, material: woodM)
            stock.deform { V3($0.x, $0.y, $0.z * width($0.x) / 0.04) }
            base(stock, at())
            // Breech tang and barrel.
            var prof: [(Float, Float)] = [(0, 0), (0, 0.0108)]
            for i in 0...12 {
                let t = Float(i) / 12
                prof.append((0.02 + 0.96 * t, lerp(0.0108, 0.0092, pow(t, 0.7)) + (t > 0.88 ? 0.0005 * (t - 0.88) / 0.12 : 0)))
            }
            prof += [(0.995, 0.0098), (1.0, 0.0090), (1.0, 0.0062), (0.985, 0.0062), (0.985, 0)]
            base(HuntKit.axial(prof, at: V3(0.45, 0, 0), seg: hi ? 48 : 20, steelM), at())
            base(HuntKit.axial([(0, 0), (0, 0.0100), (0.012, 0.0100), (0.012, 0)], at: V3(1.438, 0, 0), seg: hi ? 48 : 20, brightM), at())
            base(box(V3(0.447, 0.0102, 0), V3(0.050, 0.003, 0.014), r: 0.001, steelM), at())

            // Brass furniture.
            base(box(V3(0.004, -0.030, 0), V3(0.008, 0.134, 0.040), r: 0.003, brassM), at())
            base(box(V3(0.060, 0.0365, 0), V3(0.110, 0.003, 0.016), r: 0.001, brassM), at())
            base(box(V3(0.336, -0.022, 0.0245), V3(0.075, 0.034, 0.004), r: 0.0015, rot: simd_quatf(degrees: -8, axis: V3(0, 0, 1)), brassM), at())
            base(box(V3(0.375, -0.014, 0.0245), V3(0.030, 0.010, 0.004), r: 0.0015, rot: simd_quatf(degrees: 14, axis: V3(0, 0, 1)), brassM), at())
            // Trigger guard bow with finial, trigger.
            base(HuntKit.wire([V3(0.215, -0.074, 0), V3(0.260, -0.092, 0), V3(0.320, -0.104, 0), V3(0.385, -0.096, 0), V3(0.420, -0.066, 0), V3(0.435, -0.046, 0)],
                              r: 0.0034, per: 6, sides: ws, brassM), at())
            base(box(V3(0.215, -0.072, 0), V3(0.050, 0.006, 0.016), r: 0.002, brassM), at())
            base(box(V3(0.336, -0.064, 0), V3(0.005, 0.024, 0.004), r: 0.0012, rot: simd_quatf(degrees: -12, axis: V3(0, 0, 1)), brightM), at())
            // Three barrel bands with ramrod pipes under each.
            for bx in [Float(0.64), 0.90, 1.14] {
                base(box(V3(bx, -0.0165, 0), V3(0.018, 0.052, 0.034), r: 0.004, brassM), at())
                base(HuntKit.cyl(V3(bx - 0.011, -0.0345, 0), V3(bx + 0.011, -0.0345, 0), r: 0.0062, bevel: 0.0008, seg: hi ? 16 : 8, brassM), at())
            }
            // Sights.
            base(box(V3(0.50, 0.0120, 0), V3(0.014, 0.006, 0.010), r: 0.001, brassM), at())
            base(box(V3(1.395, 0.0120, 0), V3(0.016, 0.008, 0.005), r: 0.001, brassM), at())
            // Ramrod with steel head, held by the pipes.
            base(HuntKit.rod(V3(0.58, -0.0345, 0), V3(1.40, -0.0345, 0), r: 0.0041, sides: hi ? 14 : 6, woodM), at())
            base(HuntKit.cyl(V3(1.40, -0.0345, 0), V3(1.428, -0.0345, 0), r: 0.0062, bevel: 0.0012, seg: hi ? 16 : 8, brightM), at())
            // Sling swivels: guard rear and middle band.
            if hi {
                base(HuntKit.wire((0..<9).map { i in
                    let a = Float(i) / 8 * 2 * .pi
                    return V3(0.215 + 0.007 * cos(a), -0.086 + 0.007 * sin(a) , 0)
                }, r: 0.0012, per: 2, sides: 6, brightM), at())
                base(HuntKit.wire((0..<9).map { i in
                    let a = Float(i) / 8 * 2 * .pi
                    return V3(0.90 + 0.007 * cos(a), -0.050 + 0.007 * sin(a), 0)
                }, r: 0.0012, per: 2, sides: 6, brightM), at())
            }

            // Lock: plate with tail, pan, frizzen, spring, screws.
            let zp: Float = -0.0245
            base(box(V3(0.355, -0.008, zp), V3(0.140, 0.034, 0.005), r: 0.002, brightM), at())
            base(box(V3(0.290, -0.016, zp), V3(0.050, 0.014, 0.005), r: 0.002, rot: simd_quatf(degrees: -14, axis: V3(0, 0, 1)), brightM), at())
            base(box(V3(0.412, 0.0100, zp - 0.005), V3(0.030, 0.010, 0.018), r: 0.002, brassM), at())
            base(box(V3(0.412, 0.0160, zp - 0.010), V3(0.030, 0.006, 0.004), r: 0.001, brassM), at())
            base(HuntKit.wire([V3(0.300, -0.022, zp - 0.003), V3(0.325, -0.015, zp - 0.004), V3(0.350, -0.020, zp - 0.004), V3(0.372, -0.026, zp - 0.004)],
                              r: 0.0022, per: 5, sides: ws, brightM), at())
            for sp in [V3(0.300, -0.004, zp - 0.004), V3(0.395, -0.016, zp - 0.004), V3(0.345, -0.026, zp - 0.004)] {
                base(HuntKit.cyl(sp, sp + V3(0, 0, -0.003), r: 0.0034, bevel: 0.0006, seg: hi ? 14 : 8, brightM), at())
            }
            // Frizzen: face plate with thumb piece, on a pivot screw behind the pan.
            base(box(V3(0.436, 0.032, zp - 0.010), V3(0.004, 0.036, 0.016), r: 0.0012, rot: simd_quatf(degrees: -10, axis: V3(0, 0, 1)), brightM), at())
            base(box(V3(0.425, 0.0170, zp - 0.010), V3(0.026, 0.003, 0.016), r: 0.001, brightM), at())
            base(HuntKit.wire([V3(0.440, 0.048, zp - 0.010), V3(0.448, 0.052, zp - 0.010), V3(0.455, 0.050, zp - 0.010)], r: 0.0022, per: 3, sides: ws, brightM), at())
            base(HuntKit.wire([V3(0.440, 0.004, zp - 0.003), V3(0.448, 0.020, zp - 0.003), V3(0.443, 0.032, zp - 0.004)], r: 0.0018, per: 4, sides: ws, brightM), at())
            base(HuntKit.cyl(V3(0.352, -0.008, zp), V3(0.352, -0.008, zp - 0.007), r: 0.0075, bevel: 0.0012, seg: hi ? 20 : 8, brightM), at())

            // Cock: neck, tumbler boss, jaws with leather wrap, flint and top screw.
            let neck = HuntKit.wire([V3(0.345, -0.008, 0), V3(0.344, 0.010, 0), V3(0.336, 0.028, 0), V3(0.338, 0.044, 0), V3(0.350, 0.052, 0)],
                                    r: 0.0046, per: 7, sides: ws, brightM)
            rig.add(neck, at(V3(0, 0, zp - 0.012)), to: "cock", lods: L)
            rig.add(HuntKit.cyl(V3(0.345, -0.008, zp - 0.006), V3(0.345, -0.008, zp - 0.016), r: 0.0072, bevel: 0.001, seg: hi ? 18 : 8, brightM), at(), to: "cock", lods: L)
            let jz = zp - 0.012
            rig.add(box(V3(0.360, 0.048, jz), V3(0.030, 0.005, 0.016), r: 0.0012, brightM), at(), to: "cock", lods: L)
            rig.add(box(V3(0.360, 0.062, jz), V3(0.030, 0.005, 0.016), r: 0.0012, brightM), at(), to: "cock", lods: L)
            rig.add(box(V3(0.356, 0.055, jz), V3(0.020, 0.012, 0.018), r: 0.002, leatherM), at(), to: "cock", lods: L)
            rig.add(box(V3(0.378, 0.0555, jz), V3(0.022, 0.0065, 0.013), r: 0.0012, rot: simd_quatf(degrees: -8, axis: V3(0, 0, 1)), "metal.iron"), at(), to: "cock", lods: L)
            rig.add(HuntKit.cyl(V3(0.352, 0.060, jz), V3(0.352, 0.072, jz), r: 0.0034, bevel: 0.0006, seg: hi ? 12 : 6, brightM), at(), to: "cock", lods: L)
        }
        rig.states = [RigState("cocked"), RigState("fired", ["cock": 50])]
        groundAO(&rig, height: 0.12, floor: 0.6)
        return rig
    }
}
