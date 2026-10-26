import simd
import Foundation

/// Art Moderne Vitrolite storefront panel, 1.2 x 2.4 x 0.05 m: eight polished structural glass slabs (2 x 4) bedded in mastic on a
/// grey backing, separated by stainless reveal strips with brass screw caps, a stainless kick plate, side channels and a bullnose
/// top cap. Slabs carry engraved horizontal groove lines. One corner is chipped and the lowest slabs show water staining and
/// lime deposits. Base on y = 0.
public struct VitroliteStorefrontPanel: RealAsset {
    public static let id = "vitrolite-storefront-panel"
    public static let summary = "Art Moderne Vitrolite storefront panel, 1.2 x 2.4 m: structural glass slabs, stainless reveals, kickplate, grooved bands, screw caps, chips."
    public static let tags = ["prop", "architecture", "facade", "wall", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 6, distance: 3.3)

    /// Panel width in meters.
    public var width: Float = 1.2
    /// Panel height in meters.
    public var height: Float = 2.4
    /// Structural glass, polished green.
    public var glass: MaterialKey = "glass.emerald:1D4634"
    public var steel: MaterialKey = "metal.stainless"
    public var brass: MaterialKey = "metal.brass-aged"
    public var backing: MaterialKey = "brick.mortar-grey"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, H = height
        let kick: Float = 0.15, cap: Float = 0.04
        let field0 = kick, field1 = H - cap
        let rows = 4, rowH = (field1 - field0) / Float(rows)
        let strip: Float = 0.014, side: Float = 0.012
        let sw = (W - strip - 2 * side) / 2

        // Backing board and mastic bed.
        FA.box(&m, V3(W - 0.004, H - 0.01, 0.01), V3(0, H / 2, 0.005), backing, r: 0.002)
        FA.box(&m, V3(W - 0.03, field1 - field0, 0.006), V3(0, (field0 + field1) / 2, 0.012), "brick.mortar-dark", r: 0.001)

        // Slabs: 2 columns x 4 rows, each 20 mm structural glass with a 6 mm arris, tone varying per sheet.
        let tones: [MaterialKey] = ["glass.emerald:1D4634", "glass.emerald:224F3A", "glass.emerald:19402F", "glass.emerald:275640"]
        for r in 0..<rows {
            for c in 0..<2 {
                let cx = (c == 0 ? -1 : 1) * (strip / 2 + sw / 2)
                let cy = field0 + (Float(r) + 0.5) * rowH
                let band = r == 0 || r == rows - 1
                let mat: MaterialKey = band ? (c == 0 ? "glass.emerald:0E1613" : "glass.emerald:121C18") : tones[(r * 2 + c + Int(rng.float(0...3.99))) % 4]
                FA.box(&m, V3(sw - 0.002, rowH - strip - 0.001, 0.02), V3(cx, cy, 0.022), mat, r: 0.005)
            }
        }

        // Streamline inlays: three stainless speed lines across both columns on each green row, with a thin black groove beside them.
        for r in 1..<(rows - 1) {
            let cy = field0 + (Float(r) + 0.5) * rowH
            for g in 0..<3 {
                let yl = cy + (Float(g) - 1) * 0.034
                FO.slab(&m, W - 0.1, 0.006, 0.0014, V3(0, yl, 0.0327), steel, bevel: 0.0005)
                FO.slab(&m, W - 0.1, 0.0025, 0.0012, V3(0, yl - 0.0065, 0.0326), "metal.painted:070C0A", bevel: 0.0003)
            }
        }

        // Chevron medallions inlaid in stainless on the black top and bottom courses: two nested V bands per slab.
        for r in [0, rows - 1] {
            for c in 0..<2 {
                let cx = (c == 0 ? -1 : 1) * (strip / 2 + sw / 2)
                let cy = field0 + (Float(r) + 0.5) * rowH
                for k in 0..<2 {
                    let y0 = cy - 0.05 + Float(k) * 0.05
                    let chev: [V2] = [V2(-0.15, 0.06), V2(0, 0.0), V2(0.15, 0.06), V2(0.15, 0.078), V2(0, 0.018), V2(-0.15, 0.078)]
                    m.add(Prim.extrude(chev, depth: 0.0014, bevel: 0.0004, bevelSegments: 1, material: steel), Xform(translation: V3(cx, y0, 0.0327)))
                }
            }
        }

        // Stainless reveals: centre vertical, horizontal between rows, and side channels, proud 15 mm of the glass.
        FA.box(&m, V3(strip, field1 - field0, 0.036), V3(0, (field0 + field1) / 2, 0.028), steel, r: 0.003)
        for k in 1..<rows {
            FA.box(&m, V3(W - 2 * side, strip, 0.036), V3(0, field0 + Float(k) * rowH, 0.028), steel, r: 0.003)
        }
        for s: Float in [-1, 1] {
            FA.box(&m, V3(side, field1 - field0 + 0.014, 0.034), V3(s * (W / 2 - side / 2 - 0.001), (field0 + field1) / 2, 0.027), steel, r: 0.003)
        }
        // Mastic squeeze-out lines along the vertical reveal.
        for s: Float in [-1, 1] {
            FO.slab(&m, 0.004, field1 - field0 - 0.01, 0.002, V3(s * (strip / 2 + 0.002), (field0 + field1) / 2, 0.0326), "metal.painted:1A1A18", bevel: 0.0005)
        }

        // Brass screw caps along every reveal: domed, 0.2 m apart.
        var yy = field0 + 0.1
        while yy < field1 - 0.05 {
            rivet(&m, at: V3(0, yy, 0.046), normal: FA.Z, radius: 0.0065, segments: 8, material: brass)
            yy += 0.2
        }
        for k in 1..<rows {
            for sx: Float in [-0.45, -0.15, 0.15, 0.45] {
                rivet(&m, at: V3(sx, field0 + Float(k) * rowH, 0.046), normal: FA.Z, radius: 0.0065, segments: 8, material: brass)
            }
        }

        // Kick plate: brushed stainless with a lipped top, six countersunk screws.
        let kp: [V2] = [V2(0, 0), V2(0.04, 0), V2(0.04, kick - 0.012), V2(0.034, kick - 0.004), V2(0.03, kick), V2(0, kick)]
        FA.run(&m, kp, length: W - 0.002, steel, bevel: 0.002)
        for sx: Float in [-0.5, -0.3, -0.1, 0.1, 0.3, 0.5] {
            rivet(&m, at: V3(sx, 0.075, 0.0402), normal: FA.Z, radius: 0.005, segments: 6, material: sx > 0.2 ? "metal.rust:6D5A4A" : brass)
        }

        // Bullnose top cap: stainless quarter-round returning to the wall.
        var cp: [V2] = [V2(0, 0), V2(0.05, 0)]
        for i in 0...6 {
            let a = Float(i) / 6 * (.pi / 2)
            cp.append(V2(0.05 - 0.05 * (1 - cos(a)) * 0.9, 0.0 + cap * sin(a)))
        }
        cp.append(V2(0, cap))
        FA.run(&m, Shape2D.deduped(cp), length: W - 0.002, at: V3(0, field1, 0), steel, bevel: 0.001)

        // Chipped corner on the second row, right column: missing glass shows the dark mastic, with a cracked edge line.
        let chipX = sw / 2 + strip / 2 - sw * 0.5 + 0.0, chipY = field0 + 1.5 * rowH - rowH / 2 + 0.0
        _ = chipX; _ = chipY
        let cx1 = strip / 2 + sw - 0.06, cy1 = field0 + 3 * rowH - strip - 0.06
        m.add(Prim.extrude([V2(0, 0), V2(0.12, 0), V2(0.12, 0.08), V2(0.07, 0.05), V2(0.04, 0.095), V2(0, 0.03)].map { V2($0.x - 0.06, $0.y - 0.045) }, depth: 0.0215, bevel: 0.0005, bevelSegments: 1, material: "brick.mortar-dark"),
              Xform(translation: V3(cx1, cy1, 0.0225)))
        for (ang, ln) in [(Float(30), Float(0.1)), (-50, 0.07)] {
            m.add(Prim.extrude(Shape2D.rect(ln, 0.0024), depth: 0.0012, bevel: 0.0003, bevelSegments: 1, material: "metal.painted:E3EBE5"),
                  Xform(translation: V3(cx1 - 0.1 - ln * 0.4, cy1 - 0.05, 0.0328), rotation: FA.q(ang, FA.Z)))
        }

        // Wear on the lowest row and kick: water staining, lime deposits, rust runs, grime at the base.
        for _ in 0..<7 {
            let sx = rng.float(-W / 2 + 0.06...W / 2 - 0.06)
            FO.slab(&m, rng.float(0.01...0.03), rng.float(0.04...0.16), 0.0012, V3(sx, field0 + rng.float(0.04...0.2), 0.0329), "glass.emerald:0F2A1E", bevel: 0.0003)
        }
        for _ in 0..<9 {
            let sx = rng.float(-W / 2 + 0.06...W / 2 - 0.06)
            FO.slab(&m, rng.float(0.03...0.09), rng.float(0.005...0.014), 0.0012, V3(sx, field0 + rng.float(0.01...0.1), 0.0331), "metal.painted:C9D2CC", bevel: 0.0003)
        }
        for sx: Float in [0.1, 0.3, 0.5] {
            FO.slab(&m, 0.008, 0.07, 0.0012, V3(sx + 0.004, 0.035, 0.0407), "metal.rust:7A4A2E", bevel: 0.0003)
        }
        FO.slab(&m, W - 0.04, 0.02, 0.0012, V3(0, 0.012, 0.0409), "metal.painted:4B473F", bevel: 0.0004)

        groundAO(&m, height: 0.12, floor: 0.85)
        return LODModel(FC.place(m))
    }
}
