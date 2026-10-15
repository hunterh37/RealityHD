import simd
import Foundation

/// Restaurant booth, 1.8 m wide, 1.25 m high and 1.6 m deep: oxblood leather bench against the back wall with a high channel-tufted back (eleven vertical channels), a piped seat cushion on a walnut kick plinth, two leather end panels with a stepped profile and walnut cap, and in front a dark laminate table with a walnut edge band on a cast iron pedestal, carrying a nickel caddy with ketchup, mustard, salt and pepper shakers and a napkin dispenser. Bench against the wall at -Z, table in front, open to +Z.
public struct RestaurantBooth: RealAsset {
    public static let id = "restaurant-booth"
    public static let summary = "Restaurant booth, 1.8 m: channel-tufted leather bench with high back, wood trim, pedestal table with condiments."
    public static let tags = ["prop", "floorplan", "commercial", "dining", "retail", "furniture", "leather", "wood", "interior"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 20, distance: 4.4, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(1.8, 1.25, 1.6)
    /// Bench and end panel leather.
    public var leather: MaterialKey = "leather.oxblood"
    /// Worn seat leather.
    public var seatLeather: MaterialKey = "leather.oxblood-worn"
    /// Trim and edge band.
    public var wood: MaterialKey = "wood.walnut"
    /// Caddy and napkin dispenser.
    public var nickel: MaterialKey = "metal.brushed-nickel"
    /// Table top.
    public var laminate: MaterialKey = "laminate.white:3A2E26"
    /// Cast pedestal.
    public var iron: MaterialKey = "metal.powdercoat:1F1F21"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [5])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let bs = detail ? 2 : 1
        func box(_ sz: V3, _ c: V3, _ key: MaterialKey, r: Float = 0.01) {
            m.add(Prim.roundedBox(sz, radius: min(r, sz.x / 2.2, sz.y / 2.2, sz.z / 2.2), bevelSegments: bs, material: key), Xform(translation: c))
        }
        let W = size.x, H = size.y, D = size.z
        let zb = -D / 2                      // back wall plane
        let benchD: Float = 0.65
        let panelT: Float = 0.07
        let innerW = W - 2 * panelT
        // Kick plinth and leather base.
        box(V3(innerW - 0.02, 0.1, benchD - 0.06), V3(0, 0.05, zb + (benchD - 0.06) / 2 + 0.01), wood, r: 0.006)
        box(V3(innerW, 0.3, benchD), V3(0, 0.1 + 0.15, zb + benchD / 2), leather, r: 0.03)
        // Seat cushion: slightly worn, sagging, with piping around the top edge.
        let cw = innerW - 0.012, cd = benchD - 0.07, ch: Float = 0.13
        let sag = rng.float(0.01...0.02)
        var cushion = Prim.superellipsoid(V3(cw, ch, cd), exponent: 7, subdivisions: detail ? 10 : 6, material: seatLeather)
        cushion.deform { p in
            let fx = p.x / (cw / 2), fz = p.z / (cd / 2)
            let dip = max(0, 1 - fx * fx * fx * fx) * max(0, 1 - pow(fz - 0.05, 2)) * (p.y > 0 ? 1 : 0.3)
            return p - V3(0, dip * sag, 0)
        }
        let seatY: Float = 0.4
        let cz = zb + benchD - cd / 2 - 0.004
        m.add(cushion, Xform(translation: V3(0, seatY + ch / 2 - 0.004, cz)))
        if detail {
            let k = pow(max(0, 1 - pow((ch / 2 - 0.02) / (ch / 2), 7)), 1.0 / 7)
            let ring = Shape2D.roundedRect(cw * k - 0.002, cd * k - 0.002, radius: 0.04, segments: 4).map { V3($0.x, seatY + ch - 0.026 - sag * 0.1, cz - $0.y) }
            m.add(Prim.sweep(Shape2D.circle(0.0042, segments: 6), along: ring, closedPath: true, caps: false, material: seatLeather))
        }
        // Back: slab plus eleven vertical channel pillows, walnut cap rail.
        let backT: Float = 0.1
        box(V3(innerW, H - 0.45, backT), V3(0, 0.45 + (H - 0.45) / 2, zb + backT / 2), leather, r: 0.025)
        let channels = 11
        let chW = (innerW - 0.04) / Float(channels)
        let chH = H - 0.45 - 0.14
        for i in 0..<channels {
            var p = Prim.superellipsoid(V3(chW + 0.01, chH, 0.085), exponent: 4.5, subdivisions: detail ? 6 : 4, material: leather)
            p.deform { q in
                let t = q.y / (chH / 2)
                return q + V3(0, 0, (1 - t * t) * 0.012 * (q.z > 0 ? 1 : 0))
            }
            m.add(p, Xform(translation: V3(-innerW / 2 + 0.02 + chW * (Float(i) + 0.5), 0.45 + 0.04 + chH / 2 + 0.02, zb + backT + 0.034)))
        }
        box(V3(innerW + 0.01, 0.045, backT + 0.02), V3(0, H - 0.0225, zb + backT / 2 + 0.005), wood, r: 0.012)
        // End panels with a stepped, sloping front profile and a walnut cap on the top edge.
        let z0 = zb + benchD
        let prof = Shape2D.rounded([V2(-z0, 0.03), V2(-zb, 0.03), V2(-zb, H - 0.0), V2(-zb - 0.4, H - 0.0), V2(-zb - 0.52, 1.1), V2(-z0 - 0.0, 0.98)], radius: 0.035, segments: detail ? 4 : 2)
        for s: Float in [-1, 1] {
            m.add(Prim.extrude(prof, depth: panelT, bevel: 0.01, bevelSegments: 2, material: leather),
                  Xform(translation: V3(s * (W / 2 - panelT / 2), 0, 0), rotation: simd_quatf(degrees: 90, axis: V3(0, 1, 0))))
            box(V3(panelT + 0.012, 0.03, 0.4), V3(s * (W / 2 - panelT / 2), H - 0.015 - 0.0, zb + 0.2), wood, r: 0.008)
            if detail {
                // Brass-free stitched seam: a piping line along the front edge.
                m.add(Prim.tube([V3(s * (W / 2 - panelT - 0.0004 * s), 0.1, z0 + 0.003), V3(s * (W / 2 - panelT - 0.0004 * s), 0.96, z0 + 0.003)], radii: [0.0035, 0.0035], sides: 6, seamTile: 0.03, material: leather, capEnd: true))
            }
        }
        // Wear: scuffed kick zone on the bench front and lower end panels, rubbed by shoes.
        box(V3(innerW - 0.04, 0.075, 0.003), V3(0, 0.16, z0 + 0.001), seatLeather, r: 0.001)
        for s: Float in [-1, 1] {
            box(V3(panelT + 0.003, 0.16, 0.5), V3(s * (W / 2 - panelT / 2), 0.12, zb + 0.28 + rng.float(-0.03...0.03)), seatLeather, r: 0.002)
        }
        // Table: laminate top inside a walnut edge band on a cast pedestal, edge slightly over the seat.
        let tw: Float = 1.1, td: Float = 0.82, th: Float = 0.75, tt: Float = 0.035
        let tz = D / 2 - td / 2, tx: Float = 0
        box(V3(tw, tt, td), V3(tx, th - tt / 2, tz), wood, r: 0.012)
        box(V3(tw - 0.05, 0.004, td - 0.05), V3(tx, th + 0.0004, tz), laminate, r: 0.001)
        // Pedestal: stepped cast base, fluted column, top plate.
        let base: [(Float, Float)] = [(0, 0), (0.26, 0), (0.27, 0.006), (0.27, 0.02), (0.23, 0.034), (0.15, 0.05), (0.08, 0.1), (0.05, 0.16), (0.045, 0.6), (0.06, 0.64), (0.1, th - tt - 0.015), (0.0, th - tt - 0.015)]
        m.add(turned(base, segments: detail ? 28 : 12, material: iron, seamTile: 0.2, grainVertical: true), Xform(translation: V3(tx, 0, tz)))
        box(V3(0.3, 0.012, 0.3), V3(tx, th - tt - 0.006, tz), iron, r: 0.004)
        // Condiment caddy: nickel tray holding ketchup, mustard, shakers and a napkin dispenser.
        let cx: Float = 0.28, cdz = tz + 0.05
        box(V3(0.2, 0.012, 0.1), V3(cx, th + 0.006, cdz), nickel, r: 0.004)
        func bottle(_ x: Float, _ key: MaterialKey, _ h: Float) {
            m.add(turned([(0, 0), (0.017, 0), (0.019, 0.01), (0.019, h * 0.6), (0.012, h * 0.82), (0.006, h * 0.95), (0.0045, h), (0, h)], segments: detail ? 12 : 6, material: key, grainVertical: true),
                  Xform(translation: V3(x, th + 0.012, cdz + 0.03)))
        }
        bottle(cx - 0.07, "plastic.matte:B3201C", 0.17)
        bottle(cx - 0.025, "plastic.matte:D9A21B", 0.17)
        for (k, x) in [cx + 0.03, cx + 0.065].enumerated() {
            m.add(turned([(0, 0), (0.014, 0), (0.016, 0.01), (0.015, 0.075), (0.0, 0.075)], segments: detail ? 12 : 6, material: "glass.clear", grainVertical: true),
                  Xform(translation: V3(x, th + 0.012, cdz + 0.03)))
            m.add(Prim.cylinder(radius: 0.0155, height: 0.018, bevel: 0.004, segments: detail ? 12 : 6, material: nickel),
                  Xform(translation: V3(x, th + 0.012 + 0.07, cdz + 0.03)))
            _ = k
        }
        box(V3(0.11, 0.1, 0.045), V3(cx + 0.0, th + 0.012 + 0.05, cdz - 0.025), nickel, r: 0.004)
        for k in 0..<3 {
            box(V3(0.095, 0.0015, 0.04), V3(cx, th + 0.012 + 0.1 + 0.001 + Float(k) * 0.0015, cdz - 0.025), "paper.sheet", r: 0.0003)
        }
        groundAO(&m, height: 0.2, floor: 0.55)
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)))
        return m
    }
}
