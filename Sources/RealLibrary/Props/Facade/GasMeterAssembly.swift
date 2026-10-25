import simd
import Foundation

/// Residential diaphragm gas meter set: tin-plated case with crimped top and bottom seams and an index dial,
/// swivel unions with hex nuts and a lead seal, yellow-painted riser with quarter-turn lever shutoff and a
/// round regulator, black iron outlet nipple through a wall escutcheon, wall bracket with U-bolt, brass
/// serial tag. Wall plane at z = 0, base on the floor.
public struct GasMeterAssembly: RealAsset {
    public static let id = "gas-meter-assembly"
    public static let summary = "Residential diaphragm gas meter on swivel unions: tin-plated case with crimped seams and index dial, yellow riser with quarter-turn shutoff and regulator, black iron outlet nipple, wall bracket, lead seal and serial tag."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 12, distance: 1.5)

    /// Meter case paint.
    public var caseFinish: MaterialKey = "metal.painted:A9A89F"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let zc: Float = 0.1, inX: Float = 0.08, rx: Float = 0.16
        let by0: Float = 0.2, bh: Float = 0.28, ty = by0 + bh
        let r34: Float = 0.0135
        // Case: lower and upper shells meeting at a crimped seam band with rolled edge and bolts.
        FA.box(&m, V3(0.28, bh / 2 + 0.004, 0.14), V3(0, by0 + bh / 4 + 0.002, zc), caseFinish, r: 0.03)
        FA.box(&m, V3(0.28, bh / 2 + 0.004, 0.14), V3(0, by0 + 3 * bh / 4 - 0.002, zc), caseFinish, r: 0.03)
        FA.box(&m, V3(0.292, 0.016, 0.152), V3(0, by0 + bh / 2, zc), "metal.galvanized-aged", r: 0.006)
        var bx: Float = -0.125
        while bx <= 0.126 {
            hexBolt(&m, at: V3(bx, by0 + bh / 2, zc + 0.076), normal: FA.Z, size: 0.008, material: "metal.screw-zinc")
            bx += 0.05
        }
        // Index: bezel, glass, dial face with a pointer and a fixed odometer window.
        let fz = zc + 0.07
        FA.cylZ(&m, r: 0.052, h: 0.012, at: V3(0.0, by0 + 0.1, fz), "metal.aluminum-brushed", bevel: 0.003, segments: 28)
        FA.cylZ(&m, r: 0.044, h: 0.006, at: V3(0.0, by0 + 0.1, fz + 0.011), "plastic.black", bevel: 0.001, segments: 28)
        FA.box(&m, V3(0.058, 0.016, 0.002), V3(0, by0 + 0.1 + 0.014, fz + 0.0175), "paint.field-white", r: 0.0008)
        FA.cylZ(&m, r: 0.004, h: 0.002, at: V3(0, by0 + 0.1 - 0.016, fz + 0.0175), "metal.brass-aged", bevel: 0.0008, segments: 10)
        FA.box(&m, V3(0.002, 0.026, 0.0012), V3(0.0, by0 + 0.1 - 0.012, fz + 0.0183), "paint.field-white", r: 0.0004, rot: FA.q(-35, FA.Z))
        FA.cylZ(&m, r: 0.048, h: 0.003, at: V3(0.0, by0 + 0.1, fz + 0.0155), "glass.gauge-lens", bevel: 0.0008, segments: 28)
        // Brass serial tag with two rivets, and a stamped capacity plate.
        FA.box(&m, V3(0.07, 0.024, 0.0015), V3(0.0, by0 + 0.2, fz + 0.0008 - 0.0007), "metal.brass-aged", r: 0.0006)
        FS.screws(&m, [V3(-0.032, by0 + 0.2, fz + 0.0016), V3(0.032, by0 + 0.2, fz + 0.0016)], r: 0.0018, mat: "metal.brass-aged")
        FA.box(&m, V3(0.06, 0.03, 0.0012), V3(0.0, by0 + 0.045, fz + 0.0005), "metal.aluminum-brushed", r: 0.0004)
        // Inlet and outlet necks with swivel unions: neck, union body, hex swivel nut, lead seal wire.
        for sx in [Float(-1), 1] {
            let x = sx * inX
            FS.cyl(&m, r: 0.022, h: 0.012, at: V3(x, ty - 0.004, zc), axis: FA.Y, "metal.galvanized", bevel: 0.003)
            FS.cyl(&m, r: r34 + 0.003, h: 0.03, at: V3(x, ty + 0.007, zc), axis: FA.Y, "metal.brass-aged", bevel: 0.002)
            FS.nut(&m, at: V3(x, ty + 0.034, zc), axis: FA.Y, af: 0.044, h: 0.02, "metal.cast-iron")
            FS.cyl(&m, r: r34 + 0.001, h: 0.04, at: V3(x, ty + 0.044, zc), axis: FA.Y, "metal.cast-iron")
        }
        // Lead seal on the right union nut: wire through a nut flat, pressed lead bead.
        FA.path(&m, [V3(inX + 0.026, ty + 0.03, zc), V3(inX + 0.032, ty + 0.045, zc + 0.012), V3(inX + 0.012, ty + 0.056, zc + 0.026), V3(inX + 0.0, ty + 0.05, zc + 0.026)], r: 0.0007, "metal.stainless", sides: 5)
        FC.bead(&m, r: 0.006, at: V3(inX + 0.0, ty + 0.05, zc + 0.026), "metal.galvanized-aged")
        // Outlet: black iron to the left, then back through a wall escutcheon.
        let oy = ty + 0.092
        FS.pipe(&m, [V3(-inX, ty + 0.06, zc), V3(-inX, oy, zc), V3(-rx, oy, zc), V3(-rx, oy, 0.012)], r: r34, "metal.cast-iron", bend: 0.03)
        FS.cyl(&m, r: 0.03, h: 0.008, at: V3(-rx, oy, 0.0), axis: FA.Z, "metal.galvanized", bevel: 0.002, segments: 24)
        FS.cyl(&m, r: 0.017, h: 0.012, at: V3(-rx, oy, 0.008), axis: FA.Z, "metal.cast-iron", bevel: 0.002)
        FS.nut(&m, at: V3(-rx, oy, 0.045), axis: FA.Z, af: 0.034, h: 0.014, "metal.cast-iron")
        // Inlet: yellow riser from the slab, lever shutoff valve, regulator, run to the meter inlet.
        FS.cyl(&m, r: 0.038, h: 0.03, at: V3(rx, 0, zc), axis: FA.Y, "concrete.rough", bevel: 0.006, segments: 20)
        FS.pipe(&m, [V3(rx, 0.025, zc), V3(rx, oy, zc), V3(inX, oy, zc), V3(inX, ty + 0.06, zc)], r: r34, "metal.signal-yellow", bend: 0.03)
        FS.cyl(&m, r: 0.0185, h: 0.01, at: V3(rx, 0.03, zc), axis: FA.Y, "metal.rust", bevel: 0.001)
        // Lever ball valve at y 0.12: body, bonnet nut, stem, tee-handle lever in the open position.
        FS.cyl(&m, r: 0.022, h: 0.07, at: V3(rx, 0.09, zc), axis: FA.Y, "metal.brass-aged", bevel: 0.004)
        FS.nut(&m, at: V3(rx, 0.098, zc), axis: FA.Y, af: 0.036, h: 0.012, "metal.brass-aged")
        FS.cyl(&m, r: 0.006, h: 0.03, at: V3(rx, 0.155, zc), axis: FA.Y, "metal.stainless", bevel: 0.001, segments: 10)
        FA.box(&m, V3(0.006, 0.006, 0.09), V3(rx, 0.176, zc + 0.033), "metal.signal-yellow", r: 0.0025)
        FA.box(&m, V3(0.014, 0.01, 0.02), V3(rx, 0.176, zc + 0.08), "plastic.black", r: 0.003)
        // Regulator: round spring housing on the riser at y 0.30, vent cap and adjusting screw.
        FS.cyl(&m, r: 0.026, h: 0.06, at: V3(rx, 0.30, zc), axis: FA.Y, "metal.painted:55575A", bevel: 0.004)
        m.add(Prim.superellipsoid(V3(0.1, 0.05, 0.1), exponent: 2, subdivisions: 6, material: "metal.painted:55575A"), Xform(translation: V3(rx, 0.34, zc)))
        FS.cyl(&m, r: 0.012, h: 0.022, at: V3(rx, 0.364, zc), axis: FA.Y, "metal.brass-aged", bevel: 0.003, segments: 14)
        FA.cylX(&m, r: 0.008, h: 0.03, at: V3(rx - 0.015, 0.33, zc + 0.04), "metal.brass-aged", bevel: 0.002, segments: 10)
        // Wall bracket: flat strap arm from the wall, U-bolt around the riser, screws and rust bleed.
        FA.box(&m, V3(0.03, 0.012, zc - 0.012), V3(rx, 0.24, (zc - 0.012) / 2 + 0.002), "metal.galvanized", r: 0.002)
        FA.box(&m, V3(0.045, 0.045, 0.004), V3(rx, 0.24, 0.002), "metal.galvanized", r: 0.002)
        FS.screws(&m, [V3(rx - 0.015, 0.255, 0.004), V3(rx + 0.015, 0.255, 0.004), V3(rx - 0.015, 0.225, 0.004), V3(rx + 0.015, 0.225, 0.004)], r: 0.003)
        FS.nut(&m, at: V3(rx + 0.02, 0.24, zc + 0.02), axis: FA.X, af: 0.012, h: 0.007, "metal.screw-zinc")
        FS.nut(&m, at: V3(rx - 0.02, 0.24, zc + 0.02), axis: FA.X, af: 0.012, h: 0.007, "metal.screw-zinc")
        // Second strap on the outlet leg.
        FA.box(&m, V3(0.03, 0.012, zc - 0.012), V3(-rx, oy - 0.0, (zc - 0.012) / 2 - 0.01), "metal.galvanized", r: 0.002)
        // Weathering: rust at the case foot and nuts, tape-wrapped pipe stain.
        FA.box(&m, V3(0.27, 0.01, 0.13), V3(0, by0 + 0.002, zc), "metal.rust", r: 0.004)
        // Condensation drip marks and rust weep under the lower seam band.
        for k in 0..<5 {
            FS.streak(&m, x: -0.11 + Float(k) * 0.055 + rng.float(-0.01...0.01), top: by0 + bh / 2 - 0.009, w: 0.004, h: rng.float(0.02...0.05), z: zc + 0.0715, "metal.rust")
        }
        _ = rng.float(0...1)
        groundAO(&m, height: 0.05, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
