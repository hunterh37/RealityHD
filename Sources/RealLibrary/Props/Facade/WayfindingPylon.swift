import simd
import Foundation

/// Wayfinding pylon: architectural facade customizer, Contemporary. Powder-coated steel monolith with
/// anodised sign panels, arrow pictograms, a glazed map panel, an LED header and a stainless base shroud.
public struct WayfindingPylon: RealAsset {
    public static let id = "wayfinding-pylon"
    public static let summary = "Wayfinding pylon 2.4 m: powder-coated steel monolith with anodised sign panels, arrow pictograms, a map panel, an LED header and a stainless base."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 8, distance: 3.6)

    /// Body powder coat.
    public var body: MaterialKey = "metal.anodized-black"
    /// Sign panel frames and trim.
    public var trim: MaterialKey = "metal.anodized"
    public init() {}

    static func arrow(_ m: inout Model, at c: V3, dir: Float, _ mat: MaterialKey) {
        let o: [V2] = [V2(-0.085, 0.012), V2(0.04, 0.012), V2(0.04, 0.034), V2(0.1, 0), V2(0.04, -0.034), V2(0.04, -0.012), V2(-0.085, -0.012)].map { V2($0.x * dir, $0.y) }
        let pts = dir < 0 ? Array(o.reversed()) : o
        m.add(Prim.extrude(pts, depth: 0.004, bevel: 0.0008, bevelSegments: 1, material: mat), Xform(translation: c))
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 0.58, D: Float = 0.18, baseH: Float = 0.14, top: Float = 2.329
        let bodyH = top - baseH
        // Base plate with four anchor bolts and a stainless shroud.
        FA.box(&m, V3(0.6, 0.012, 0.2), V3(0, 0.006, 0), "metal.stainless", r: 0.004)
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            m.add(Prim.cylinder(radius: 0.011, height: 0.008, bevel: 0.002, segments: 6, bevelSegments: 1, material: "metal.steel"),
                  Xform(translation: V3(sx * 0.27, 0.012, sz * 0.085)))
        }}
        FA.box(&m, V3(0.54, baseH - 0.012, 0.17), V3(0, 0.012 + (baseH - 0.012) / 2, 0), "metal.stainless", r: 0.006)
        // Monolith: core steel box with a rolled-edge section.
        FA.box(&m, V3(W - 0.04, bodyH, D - 0.02), V3(0, baseH + bodyH / 2, 0), body, r: 0.012)
        for e: Float in [-1, 1] {
            FA.box(&m, V3(0.03, bodyH - 0.01, D), V3(e * (W / 2 - 0.015), baseH + bodyH / 2, 0), body, r: 0.012)
        }
        // Top cap: shallow pitched cap with a drip lip, and a warm LED header strip beneath it.
        let cap: [V2] = [V2(-D / 2 - 0.01, 0), V2(D / 2 + 0.01, 0), V2(D / 2 + 0.01, 0.014), V2(0.02, 0.07), V2(-0.02, 0.07), V2(-D / 2 - 0.01, 0.014)]
        FA.run(&m, cap, length: W + 0.02, at: V3(0, top, 0), "metal.stainless", bevel: 0.003)
        FA.box(&m, V3(W - 0.06, 0.026, 0.012), V3(0, top - 0.026, D / 2 + 0.002), "emissive.warm", r: 0.003)
        // Front sign panels: header, three destination blades with arrows, and a glazed map panel.
        let zf = D / 2 - 0.004
        func framed(_ y: Float, _ h: Float, _ face: MaterialKey) {
            FA.box(&m, V3(W - 0.08, h, 0.012), V3(0, y, zf), trim, r: 0.004)
            FA.box(&m, V3(W - 0.1, h - 0.02, 0.006), V3(0, y, zf + 0.0045), face, r: 0.002)
        }
        framed(2.14, 0.15, "metal.painted:1B4F8F")
        let tones = ["metal.painted:1B4F8F", "metal.painted:2F7F4F", "metal.painted:B07A12"]
        for (k, t) in tones.enumerated() {
            let y = 1.93 - Float(k) * 0.22
            framed(y, 0.19, t)
            let dir: Float = (k == 1) ? -1 : 1
            Self.arrow(&m, at: V3(dir * 0.12, y, zf + 0.0105), dir: dir, "metal.powder-white")
            // Pictogram disc on the opposite end and a short text bar (embossed, no letters).
            FA.cylZ(&m, r: 0.026, h: 0.003, at: V3(-dir * 0.19, y, zf + 0.0075), "metal.powder-white", bevel: 0.0008, segments: 20)
            FA.box(&m, V3(0.13, 0.013, 0.0035), V3(-dir * 0.02, y + 0.03, zf + 0.009), "metal.powder-white", r: 0.001)
            FA.box(&m, V3(0.09, 0.009, 0.0035), V3(-dir * 0.04, y - 0.035, zf + 0.009), "metal.powder-white", r: 0.001)
        }
        // Map panel: white board with a street grid, under glass in a deep frame.
        let my: Float = 1.07, mh: Float = 0.7
        FA.box(&m, V3(W - 0.08, mh, 0.014), V3(0, my, zf), trim, r: 0.004)
        FA.box(&m, V3(W - 0.11, mh - 0.03, 0.004), V3(0, my, zf + 0.005), "metal.powder-white", r: 0.001)
        for k in 0..<7 {
            let horiz = k < 4
            let off = (Float(k % 4) - 1.5) * 0.15 + rng.float(-0.02...0.02)
            FA.box(&m, horiz ? V3(0.4, 0.006, 0.0016) : V3(0.006, 0.55, 0.0016), horiz ? V3(rng.float(-0.01...0.01), my + off * 0.9, zf + 0.0075) : V3(off, my + rng.float(-0.02...0.02), zf + 0.0075),
                   "metal.painted:6A7A8C", r: 0.0005)
        }
        FA.box(&m, V3(0.12, 0.09, 0.0016), V3(0.1, my - 0.1, zf + 0.0078), "metal.painted:2F7F4F", r: 0.0005)
        FA.box(&m, V3(0.1, 0.1, 0.0016), V3(-0.14, my + 0.15, zf + 0.0078), "metal.painted:B07A12", r: 0.0005)
        FA.cylZ(&m, r: 0.012, h: 0.0016, at: V3(0.02, my + 0.02, zf + 0.0078), "metal.painted:B3201C", bevel: 0.0004, segments: 14)
        FA.box(&m, V3(W - 0.1, mh - 0.02, 0.003), V3(0, my, zf + 0.0105), "glass.clear", r: 0.001)
        // Screws at panel corners.
        for (y, h) in [(2.14, 0.15), (1.07, 0.7)] as [(Float, Float)] {
            for sx: Float in [-1, 1] { for sy: Float in [-1, 1] {
                FA.cylZ(&m, r: 0.004, h: 0.003, at: V3(sx * (W / 2 - 0.045), y + sy * (h / 2 - 0.012), zf + 0.006), "metal.steel", bevel: 0.0008, segments: 8)
            }}
        }
        // Rear: service door with a flush lock, hinge knuckles and reveal gaps, plus an anodised info plate above it.
        let zb = -D / 2 + 0.004
        FA.box(&m, V3(0.4, 0.6, 0.005), V3(0, 1.05, zb - 0.0035), "metal.anodized-black", r: 0.003)
        for (x, w) in [(-0.2, 0.004), (0.2, 0.004)] as [(Float, Float)] { FA.box(&m, V3(w, 0.6, 0.0015), V3(x, 1.05, zb - 0.0065), "concrete.sealed-void", r: 0.0005) }
        for y in [0.75, 1.35] as [Float] { FA.box(&m, V3(0.4, 0.004, 0.0015), V3(0, y, zb - 0.0065), "concrete.sealed-void", r: 0.0005) }
        for y in [0.85, 1.25] as [Float] { FA.cylZ(&m, r: 0.007, h: 0.012, at: V3(-0.2, y, zb - 0.01), "metal.stainless", bevel: 0.0015, segments: 10) }
        FA.box(&m, V3(0.05, 0.03, 0.01), V3(0.15, 1.05, zb - 0.0085), "metal.stainless", r: 0.004)
        FA.box(&m, V3(0.4, 0.5, 0.006), V3(0, 1.72, zb - 0.002), trim, r: 0.003)
        FA.box(&m, V3(0.36, 0.46, 0.003), V3(0, 1.72, zb - 0.0055), "metal.painted:1B4F8F", r: 0.002)
        // Side seams: vertical reveal at each corner and two horizontal panel splits.
        for e: Float in [-1, 1] {
            FA.box(&m, V3(0.0016, bodyH - 0.1, 0.006), V3(e * (W / 2 - 0.0005), baseH + bodyH / 2, 0.0), "concrete.sealed-void", r: 0.0005)
            for y in [0.9, 1.7] as [Float] { FA.box(&m, V3(0.0016, 0.003, D - 0.04), V3(e * (W / 2 + 0.0006), y, 0), "concrete.sealed-void", r: 0.0005) }
        }
        // Vents in the stainless base shroud.
        for k in 0..<5 { FA.box(&m, V3(0.024, 0.0025, 0.004), V3(-0.12 + Float(k) * 0.06, 0.07, zf + 0.0), "concrete.sealed-void", r: 0.0008) }
        // Wear: scuff marks and kick marks low on the powder coat and one chipped corner showing bare steel.
        // Grime splash along the foot of the front face and a light sticker scar on the lower panel.
        FA.box(&m, V3(W - 0.1, 0.07, 0.0012), V3(0, 0.205, zf + 0.0005), "metal.anodized-worn", r: 0.0004)
        FA.box(&m, V3(0.1, 0.07, 0.0012), V3(0.11, 0.42, zf + 0.0005), "metal.satin-aluminum", r: 0.0004)
        FA.box(&m, V3(0.022, 0.04, 0.0014), V3(W / 2 - 0.025, 0.2, zf + 0.0005), "metal.stainless", r: 0.0006, rot: FA.q(8, FA.Z))
        m = FE.seat(m)
        groundAO(&m, height: 0.12, floor: 0.6)
        return LODModel(m)
    }
}
