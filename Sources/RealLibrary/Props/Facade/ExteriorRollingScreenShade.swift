import simd
import Foundation

/// Exterior solar screen roller shade, 1.5 m wide, lowered a little over half way: charcoal woven
/// glass-fibre mesh with sewn hem, in an extruded anthracite aluminium cassette with rounded end caps and
/// a front slot, two zip guide rails with rubber gaskets and white zip beads, a weighted bottom bar with
/// gasket, slider end plugs and pull tab, wall brackets with stainless screws, and base pads. Dusty at the
/// hem, grimy rail feet, one rail scuffed to bare aluminium.
public struct ExteriorRollingScreenShade: RealAsset {
    public static let id = "exterior-rolling-screen-shade"
    public static let summary = "Exterior solar screen roller shade, 1.5 m wide: woven PVC-glass mesh in aluminium cassette with side zip guides and bottom bar."
    public static let tags = ["prop", "architecture", "facade", "metal", "fabric"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 1.9, studio: true)

    /// Overall width and height (m).
    public var width: Float = 1.5
    public var height: Float = 2.0
    /// Fraction of the drop that is lowered.
    public var lowered: Float = 0.58
    /// Anthracite powdercoat (sRGB hex) for cassette and rails.
    public var coat: UInt32 = 0x2E3033
    /// Mesh colour (sRGB hex).
    public var meshColor: UInt32 = 0x5A5A58
    public var steel: MaterialKey = "metal.stainless"
    public init() {}

    func powder(_ light: Float) -> MaterialKey {
        func ch(_ v: UInt32) -> UInt32 { UInt32(max(0, min(255, Float(v) + light * 90))) }
        return "metal.powdercoat:" + String(format: "%02X%02X%02X", ch(coat >> 16 & 255), ch(coat >> 8 & 255), ch(coat & 255))
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, H = height
        let cH: Float = 0.14, cD: Float = 0.145
        let cassBot = H - cH
        let base: MaterialKey = "metal.anodized-black", worn: MaterialKey = "metal.anodized-worn"
        // Cassette: rounded extrusion along X with a front-bottom slot.
        let prof = Shape2D.rounded([V2(0.004, cassBot), V2(cD, cassBot), V2(cD, H), V2(0.004, H)], radius: 0.026, segments: 3)
        FA.run(&m, prof, length: W, at: V3(0, 0, 0), base, bevel: 0.002)
        // Front slot where the fabric leaves the roller, with a gasket brush.
        FA.box(&m, V3(W - 0.01, 0.014, 0.036), V3(0, cassBot + 0.004, cD - 0.062), "rubber.silicone-gray", r: 0.003)
        // Weather hood lip and a seam line along the cassette.
        FA.box(&m, V3(W - 0.004, 0.003, 0.008), V3(0, cassBot + 0.05, cD + 0.001), worn, r: 0.0012)
        FA.box(&m, V3(W - 0.004, 0.003, 0.008), V3(0, H - 0.05, cD + 0.001), worn, r: 0.0012)
        // End caps with screw heads.
        for e: Float in [-1, 1] {
            FA.box(&m, V3(0.012, cH + 0.004, cD + 0.006), V3(e * (W / 2 + 0.002), (cassBot + H) / 2, cD / 2 + 0.003), worn, r: 0.006)
            for (dy, dz) in [(-0.04, 0.03), (0.04, 0.03), (0.0, 0.11)] as [(Float, Float)] {
                FSH.nut(&m, at: V3(e * (W / 2 + 0.008), (cassBot + H) / 2 + dy, dz), normal: V3(e, 0, 0), size: 0.013, steel)
            }
        }
        // Wall mounting brackets under the cassette.
        for x in [-0.45, 0.45] as [Float] {
            FA.box(&m, V3(0.06, 0.012, 0.03), V3(x, cassBot - 0.006, 0.019), steel, r: 0.002)
            FA.box(&m, V3(0.06, 0.05, 0.006), V3(x, cassBot - 0.03, 0.003), steel, r: 0.002)
            for dy: Float in [-0.045, -0.015] { FSH.nut(&m, at: V3(x, cassBot + dy + 0.0, 0.006), normal: FA.Z, size: 0.012, steel) }
        }
        // Guide rails: wall web, outer wall, front lip, gasket and zip bead track.
        let railH = cassBot - 0.004
        let rx = W / 2 - 0.022
        for e: Float in [-1, 1] {
            let x = e * rx
            let rail: MaterialKey = e > 0 ? worn : base
            FA.box(&m, V3(0.044, railH, 0.005), V3(x, railH / 2, 0.0025 + 0.01), rail, r: 0.0015)
            FA.box(&m, V3(0.005, railH, 0.044), V3(x + e * 0.0195, railH / 2, 0.034), rail, r: 0.0015)
            FA.box(&m, V3(0.016, railH, 0.005), V3(x + e * 0.0115, railH / 2, 0.0555), rail, r: 0.0015)
            FA.box(&m, V3(0.016, railH, 0.005), V3(x - e * 0.0125, railH / 2, 0.0555), rail, r: 0.0015)
            // zip bead channel (white) running with the fabric edge, only where the screen is lowered
            // gasket brushes
            FA.rod(&m, V3(x - e * 0.0045, 0.01, 0.0555), V3(x - e * 0.0045, railH, 0.0555), r: 0.0035, "rubber.silicone-gray", sides: 5)
            // base pad with screws
            FA.box(&m, V3(0.07, 0.01, 0.07), V3(x, 0.005, 0.034), "metal.galvanized-aged", r: 0.002)
            FSH.nut(&m, at: V3(x - 0.02, 0.01, 0.034), normal: FA.Y, size: 0.012, "metal.rust")
            FSH.nut(&m, at: V3(x + 0.02, 0.01, 0.034), normal: FA.Y, size: 0.012, steel)
            // fixing screws up the web
            for y in [0.5, 1.0, 1.5] as [Float] { FSH.nut(&m, at: V3(x, y, 0.0145), normal: FA.Z, size: 0.011, steel) }
        }
        // Mesh screen: three vertical panels with growing dust toward the hem, sewn side hems and seam.
        let sTop = cassBot - 0.002
        let drop = (H - cH) * lowered
        let hem = sTop - drop
        let sw = 2 * rx - 0.03
        let zS: Float = 0.034
        let bands = 5
        for i in 0..<bands {
            let t = Float(i) / Float(bands)
            let y1 = sTop - drop * t, y0 = sTop - drop * (t + 1 / Float(bands))
            let key = FSH.canvas(meshColor, fade: 0.05 * (1 - t), dirt: 0.05 + 0.34 * pow(t, 2), family: "fabric.canvas")
            FA.box(&m, V3(sw, y1 - y0, 0.0022), V3(0, (y0 + y1) / 2, zS), key, r: 0.0004)
        }
        for e: Float in [-1, 1] {
            FA.box(&m, V3(0.012, drop, 0.0034), V3(e * (sw / 2 - 0.006), sTop - drop / 2, zS), FSH.canvas(meshColor, dirt: 0.45, family: "fabric.canvas"), r: 0.0006)
            FA.rod(&m, V3(e * (sw / 2 + 0.003), sTop, zS), V3(e * (sw / 2 + 0.003), hem + 0.02, zS), r: 0.0042, "plastic.white", sides: 5)
        }
        // Horizontal sewn seam and stitch row part way down.
        let seamY = sTop - drop * 0.42
        FA.box(&m, V3(sw - 0.02, 0.012, 0.0032), V3(0, seamY, zS), FSH.canvas(meshColor, dirt: 0.3, family: "fabric.canvas"), r: 0.0005)
        let st = stitches(along: [V3(-sw / 2 + 0.02, seamY + 0.004, zS + 0.0017), V3(sw / 2 - 0.02, seamY + 0.004, zS + 0.0017)], normal: { _ in FA.Z }, pitch: 0.012, thread: 0.0008, material: "fabric.canvas:25252A")
        m.add(st, Xform())
        // Weighted bottom bar with gasket, end plugs and pull tab.
        let bY = hem - 0.02
        FA.box(&m, V3(sw - 0.006, 0.042, 0.03), V3(0, bY, zS), "metal.anodized-black", r: 0.008)
        FA.box(&m, V3(sw - 0.02, 0.01, 0.024), V3(0, bY - 0.024, zS), "rubber.silicone-gray", r: 0.004)
        for e: Float in [-1, 1] {
            FA.box(&m, V3(0.024, 0.044, 0.034), V3(e * (sw / 2 - 0.004), bY, zS), "plastic.black", r: 0.006)
        }
        FA.box(&m, V3(0.03, 0.09, 0.0025), V3(0.1, bY - 0.058, zS + 0.015), "fabric.webbing", r: 0.0008)
        FA.cylZ(&m, r: 0.011, h: 0.003, at: V3(0.1, bY - 0.08, zS + 0.0165), steel, bevel: 0.001, segments: 10)
        // Dust streak and bird mark on the bar.
        FA.box(&m, V3(0.07, 0.0015, 0.0015), V3(-0.3, bY + 0.02, zS + 0.0155), "metal.anodized-worn", r: 0.0004)
        _ = rng.float()
        groundAO(&m, height: 0.1, floor: 0.8)
        return LODModel(FA.centerZ(m))
    }
}
