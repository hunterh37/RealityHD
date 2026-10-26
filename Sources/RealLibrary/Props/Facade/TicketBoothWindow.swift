import simd
import Foundation

/// Art Deco ticket booth: a terrazzo plinth under an enamelled steel cabin with a chrome edged service
/// window, a speaking grille and ticket slot plate, a brass rail counter, a lit header sign, a stepped
/// roof cap with finial and a side door. Interior shows a back wall, shelf and stool through the glass.
public struct TicketBoothWindow: RealAsset {
    public static let id = "ticket-booth-window"
    public static let summary = "Art Deco ticket booth 1.2 x 2.4 m: terrazzo base, glass window, brass speaking grille, ticket slot, counter, canopy."
    public static let tags = ["prop", "architecture", "facade", "decor", "metal", "stone"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 10, distance: 1.1)

    /// Header sign text (A-Z, 0-9).
    public var header = "TICKETS"
    public var base: MaterialKey = "stone.terrazzo"
    public var cabin: MaterialKey = "metal.painted:7B2229"
    public var trim: MaterialKey = "metal.stainless"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 1.16, D: Float = 1.05, bh: Float = 0.16, ch: Float = 2.0
        // Terrazzo plinth with a brass kick band.
        FA.box(&m, V3(W, bh, D), V3(0, bh / 2, 0), base, r: 0.006)
        FA.box(&m, V3(W - 0.04, 0.02, D - 0.04), V3(0, bh + 0.01, 0), "metal.brass-aged", r: 0.003)
        // Cabin walls: back, two sides and a front with the window opening (0.7 x 0.5 at y 1.05...1.55).
        let t: Float = 0.05, cw = W - 0.12, cd = D - 0.12, y0 = bh + 0.02
        FA.box(&m, V3(cw, ch, t), V3(0, y0 + ch / 2, -cd / 2 + t / 2), cabin, r: 0.004)
        for sx: Float in [-1, 1] { FA.box(&m, V3(t, ch, cd), V3(sx * (cw / 2 - t / 2), y0 + ch / 2, 0), cabin, r: 0.004) }
        let ox: Float = 0.66, oy0: Float = 1.05, oy1: Float = 1.55, fz = cd / 2 - t / 2
        FA.box(&m, V3(cw, oy0 - y0, t), V3(0, (y0 + oy0) / 2, fz), cabin, r: 0.004)
        FA.box(&m, V3(cw, y0 + ch - oy1, t), V3(0, (oy1 + y0 + ch) / 2, fz), cabin, r: 0.004)
        for sx: Float in [-1, 1] { FA.box(&m, V3((cw - ox) / 2, oy1 - oy0, t), V3(sx * (ox / 2 + (cw - ox) / 4), (oy0 + oy1) / 2, fz), cabin, r: 0.004) }
        // Window: chrome frame, glass, mullion, counter shelf with brass rail, ticket slot plate and grille.
        let wz = cd / 2 + 0.002
        for (w, h, x, y) in [(ox + 0.06, 0.03, 0.0, oy1 + 0.015), (ox + 0.06, 0.03, 0.0, oy0 - 0.015), (0.03, oy1 - oy0, -ox / 2 - 0.015, (oy0 + oy1) / 2), (0.03, oy1 - oy0, ox / 2 + 0.015, (oy0 + oy1) / 2)] as [(Float, Float, Float, Float)] {
            FA.box(&m, V3(w, h, 0.03), V3(x, y, wz), trim, r: 0.005)
        }
        FA.box(&m, V3(ox, oy1 - oy0, 0.006), V3(0, (oy0 + oy1) / 2, fz - 0.008), "glass.pane", r: 0.001)
        FA.box(&m, V3(0.014, oy1 - oy0, 0.02), V3(0.0, (oy0 + oy1) / 2, wz - 0.006), trim, r: 0.003)
        FA.box(&m, V3(ox + 0.16, 0.04, 0.2), V3(0, oy0 - 0.045, wz + 0.07), "wood.walnut", r: 0.006)
        FA.rod(&m, V3(-ox / 2 - 0.07, oy0 - 0.005, wz + 0.17), V3(ox / 2 + 0.07, oy0 - 0.005, wz + 0.17), r: 0.007, "metal.brass", sides: 8)
        for sx: Float in [-1, 1] { FA.rod(&m, V3(sx * (ox / 2 + 0.07), oy0 - 0.005, wz + 0.17), V3(sx * (ox / 2 + 0.07), oy0 - 0.06, wz + 0.15), r: 0.006, "metal.brass", sides: 6) }
        FA.box(&m, V3(0.2, 0.012, 0.1), V3(0.0, oy0 - 0.021, wz + 0.1), "metal.brass-aged", r: 0.002)
        FA.box(&m, V3(0.12, 0.004, 0.012), V3(0, oy0 - 0.0232, wz + 0.1), "metal.steel:101010", r: 0.0006)
        // Speaking grille: perforated disc in a brass ring left of centre at glass height.
        let gc = V3(-0.19, oy0 + 0.25, fz - 0.008 + 0.005)
        FA.cylZ(&m, r: 0.05, h: 0.004, at: gc, "metal.perforated", bevel: 0.001, segments: 20)
        m.add(Prim.torus(major: 0.052, minor: 0.005, segments: 24, sides: 6, material: "metal.brass"), Xform(translation: gc + V3(0, 0, 0.004), rotation: FA.q(90, FA.X)))
        // Interior: dark back wall, shelf, stool and a glowing lamp seen through the glass.
        FA.box(&m, V3(ox - 0.02, 0.42, 0.01), V3(0, (oy0 + oy1) / 2, -0.25), "metal.painted:2A2A2C", r: 0.002)
        FA.box(&m, V3(0.5, 0.025, 0.24), V3(0.05, 1.28, -0.12), "wood.oak", r: 0.003)
        FA.cylZ(&m, r: 0.03, h: 0.02, at: V3(-0.2, 1.4, -0.24), "emissive.warm", bevel: 0.004, segments: 12)
        // Chrome flutes up the front pilasters and belt course below the window.
        for sx: Float in [-1, 1] { for k in 0..<3 { FA.box(&m, V3(0.012, 1.3, 0.012), V3(sx * (0.48 + Float(k) * 0.03) , 0.86 + 0.5, cd / 2 + 0.004), trim, r: 0.003) } }
        FA.box(&m, V3(cw + 0.02, 0.03, 0.03), V3(0, oy0 - 0.12, cd / 2), trim, r: 0.004)
        FA.box(&m, V3(cw + 0.02, 0.03, 0.03), V3(0, oy1 + 0.1, cd / 2), trim, r: 0.004)
        // Lit header sign above the window: black plate, chrome frame, lit lamp letters.
        let hy = oy1 + 0.27
        FA.box(&m, V3(0.9, 0.22, 0.03), V3(0, hy, cd / 2 + 0.014), trim, r: 0.004)
        FA.box(&m, V3(0.86, 0.18, 0.03), V3(0, hy, cd / 2 + 0.018), "metal.painted:121214", r: 0.003)
        FG.text(&m, header, h: 0.12, stroke: 0.02, depth: 0.012, at: V3(0, hy, cd / 2 + 0.034), "emissive.signal-white", squeeze: 0.85)
        // Stepped roof cap with chrome edge, tier and ball finial.
        let ry = y0 + ch
        FA.box(&m, V3(W + 0.04, 0.05, D + 0.04), V3(0, ry + 0.025, 0), cabin, r: 0.01)
        FA.box(&m, V3(W + 0.04, 0.014, D + 0.04), V3(0, ry + 0.057, 0), trim, r: 0.004)
        FA.box(&m, V3(W - 0.2, 0.06, D - 0.2), V3(0, ry + 0.09, 0), cabin, r: 0.006)
        FA.box(&m, V3(W - 0.5, 0.05, D - 0.5), V3(0, ry + 0.145, 0), cabin, r: 0.006)
        FA.ball(&m, r: 0.04, at: V3(0, ry + 0.2, 0), "metal.brass-aged")
        // Side door on the right wall: panel, handle and a hinge pair.
        let dz: Float = 0.05
        FA.box(&m, V3(0.008, 1.75, 0.6), V3(cw / 2 + 0.002, y0 + 0.92, dz), cabin, r: 0.002)
        FA.box(&m, V3(0.01, 1.6, 0.46), V3(cw / 2 + 0.004, y0 + 0.92, dz), "metal.painted:6A1D23", r: 0.002)
        FA.rod(&m, V3(cw / 2 + 0.01, y0 + 0.95, dz + 0.2), V3(cw / 2 + 0.05, y0 + 0.95, dz + 0.2), r: 0.007, "metal.brass", sides: 8)
        for y: Float in [0.45, 1.6] { FA.cylZ(&m, r: 0.008, h: 0.06, at: V3(cw / 2 + 0.005, y0 + y, dz - 0.31), "metal.stainless", bevel: 0.001, segments: 8) }
        // Wear: scuffs on the kick area, hairline rust under the chrome, a posted bill on the side wall.
        for _ in 0..<6 {
            FG.flat(&m, V3(rng.float(0.05...0.16), rng.float(0.02...0.05), 0.001), V3(rng.float(-0.45...0.45), rng.float(0.25...0.6), cd / 2 + 0.001), "metal.steel:3B2E2A")
        }
        FG.flat(&m, V3(0.01, 0.28, 0.001), V3(-0.31, oy1 + 0.0, cd / 2 + 0.001), "metal.rust-grime")
        FG.flat(&m, V3(0.002, 0.3, 0.2), V3(-cw / 2 - 0.0005, 1.3, -0.05), "sign.white:E8DFC8")
        groundAO(&m, height: 0.4, floor: 0.85)
        return LODModel(FC.place(m))
    }
}
