import simd
import Foundation

/// Retail gondola shelf bay, 1.2 x 1.6 x 0.5 m, light grey powder coat, stocked with boxed goods. Parts: perforated pegboard back panel, two slotted
/// steel end uprights with channel returns, four adjustable lipped shelves on clips plus a deep base shelf behind a charcoal kick plate, a clear price
/// rail with paper tags along every shelf lip, and rows of boxed goods in a handful of facings, leaning, gapped and two deep. Free-standing: centered on
/// X and Z with the front toward +Z.
public struct GondolaShelf: RealAsset {
    public static let id = "gondola-shelf"
    public static let summary = "Retail gondola shelf, 1.2 x 1.6 x 0.5 m: slotted steel uprights, perforated back panel, five lipped shelves with price rails and stocked boxes."
    public static let tags = ["prop", "floorplan", "commercial", "metal", "interior", "container"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 12, distance: 3.2, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(1.2, 1.6, 0.5)
    /// Shelf and upright powder coat.
    public var steel: MaterialKey = "metal.powdercoat:C3C6C8"
    /// Kick plate and header strip.
    public var darkSteel: MaterialKey = "metal.powdercoat:3E4247"
    /// Back panel.
    public var backPanel: MaterialKey = "wood.pegboard:B9BCBD"
    /// Heights of the five shelf tops above the floor (m), base shelf first.
    public var shelfHeights: [Float] = [0.16, 0.5, 0.8, 1.1, 1.4]
    /// Stock fill, 0 empty to 1 full.
    public var stock: Float = 0.9
    public init() {}

    private func shelfProfile(_ depth: Float, _ lipH: Float) -> [V2] {
        let t: Float = 0.004
        // (x = depth from the back edge, y = up), counterclockwise: sheet, front lip, back return.
        return [V2(0, 0), V2(depth, 0), V2(depth, lipH), V2(depth - t, lipH), V2(depth - t, t), V2(t, t), V2(t, 0.02), V2(0, 0.02)]
    }

    public func build(seed: UInt64) -> LODModel {
        func make(_ hi: Bool) -> Model {
            var rng = SeededRNG(seed: seed)
            var m = Model(name: Self.id)
            let W = size.x, H = size.y, D = size.z
            let zb = -D / 2, zf = D / 2
            let upX = W / 2 - 0.0015
            func box(_ sz: V3, _ c: V3, _ key: MaterialKey, r: Float = 0.002) {
                m.add(Prim.roundedBox(sz, radius: min(r, sz.x / 2.1, sz.y / 2.1, sz.z / 2.1), bevelSegments: 1, material: key), Xform(translation: c))
            }
            func flat(_ sz: V3, _ c: V3, _ key: MaterialKey, rot: simd_quatf = .identity) { m.add(cuboid(sz, material: key), Xform(translation: c, rotation: rot)) }
            // ---- Back panel: pegboard between the uprights, with a steel header strip along the top.
            let backT: Float = 0.012
            let backZ = zb + 0.02 + backT / 2
            m.add(Prim.roundedBox(V3(W - 0.07, H - 0.2, backT), radius: 0.001, bevelSegments: 1, material: backPanel), Xform(translation: V3(0, 0.1 + (H - 0.2) / 2 + 0.0, backZ)))
            box(V3(W - 0.07, 0.06, 0.03), V3(0, H - 0.03, zb + 0.02 + 0.012), darkSteel, r: 0.004)
            // ---- Uprights: slotted plates with channel returns and a base foot.
            let slotKey: MaterialKey = "plastic.black:1A1A1C"
            for s: Float in [-1, 1] {
                let ux = s * (W / 2 - 0.0125)
                // Plate (thin, full depth) and front/back channel returns.
                box(V3(0.0035, H, D), V3(s * (W / 2 - 0.00175), H / 2, 0), steel, r: 0.0012)
                for z in [zb + 0.0125, zf - 0.0125] {
                    box(V3(0.025, H, 0.0035), V3(ux - s * 0.0, H / 2, z), steel, r: 0.0012)
                }
                box(V3(0.025, 0.0035, D), V3(ux, H - 0.0018, 0), steel, r: 0.0012)
                // Base foot: a leveling plate and a toe block under each end.
                box(V3(0.03, 0.045, D - 0.03), V3(s * (W / 2 - 0.015), 0.0225, 0), darkSteel, r: 0.004)
                // Slots: two columns of vertical shelf-clip slots, 50 mm pitch.
                if hi {
                    var y: Float = 0.12
                    while y < H - 0.06 {
                        for z in [zb + 0.1, zf - 0.09] {
                            flat(V3(0.0008, 0.02, 0.006), V3(s * (W / 2 + 0.0002), y, z), slotKey)
                        }
                        y += 0.06
                    }
                }
            }
            // ---- Shelves, price rails, tags and stock.
            let tagCols: [MaterialKey] = ["paper.sheet:F4D24A", "paper.sheet:F2F2EE", "paper.sheet:EE6A4F"]
            let colors: [MaterialKey] = ["paper.sheet:C94A3B", "paper.sheet:E1B73A", "paper.sheet:2F6EA8", "paper.sheet:3A8F5A", "paper.sheet:EEE9DC", "paper.sheet:7A4B9B", "paper.sheet:D9782E", "paper.sheet:48A6B8"]
            let labelCols: [MaterialKey] = ["paper.sheet:F7F5EE", "paper.sheet:F0E3B8", "paper.sheet:1D2733"]
            for (si, sy) in shelfHeights.enumerated() {
                let isBase = si == 0
                let depth: Float = isBase ? D - 0.02 : 0.4
                let z0 = isBase ? zb + 0.01 : zb + 0.032
                let lip: Float = isBase ? 0.06 : 0.045
                let prof = Shape2D.rounded(shelfProfile(depth, lip), radius: 0.0015, segments: 1)
                // Outline x -> world +z, extrusion axis -> x; sits so the sheet's underside is at y = sy - 0.004.
                m.add(Prim.extrude(prof, depth: W - 0.01, bevel: 0.0012, bevelSegments: 1, material: steel),
                      Xform(translation: V3(0, sy - 0.004, z0), rotation: simd_quatf(degrees: -90, axis: .up)))
                if isBase {
                    // Kick plate across the front of the base.
                    box(V3(W - 0.05, sy - 0.05, 0.012), V3(0, (sy - 0.05) / 2 + 0.05 - 0.0, zf - 0.012), darkSteel, r: 0.004)
                }
                let zFront = z0 + depth
                // Clear price rail clipped to the lip, with paper tags.
                m.add(Prim.roundedBox(V3(W - 0.06, 0.028, 0.004), radius: 0.001, bevelSegments: 1, material: "plastic.clear"),
                      Xform(translation: V3(0, sy + lip - 0.032 + (isBase ? 0.0 : 0.0), zFront + 0.0025)))
                var tx = -W / 2 + 0.09 + rng.float(0...0.03)
                while tx < W / 2 - 0.08 {
                    flat(V3(0.05, 0.02, 0.0008), V3(tx, sy + lip - 0.032, zFront + 0.0052), tagCols[rng.int(0...2)])
                    tx += rng.float(0.11...0.17)
                }
                // Clips at the ends of the shelf (steel tabs into the slots).
                for s: Float in [-1, 1] {
                    box(V3(0.012, 0.03, 0.02), V3(s * (W / 2 - 0.016), sy - 0.015, z0 + 0.1), darkSteel, r: 0.002)
                    box(V3(0.012, 0.03, 0.02), V3(s * (W / 2 - 0.016), sy - 0.015, zFront - 0.06), darkSteel, r: 0.002)
                }
                // ---- Stock: groups of one product with 2 rows deep, facing the aisle.
                let maxH: Float = (si == shelfHeights.count - 1 ? H - 0.06 : shelfHeights[si + 1] - 0.055) - sy
                var x = -W / 2 + 0.022 + rng.float(0...0.02)
                var sr = rng.fork(10 + si)
                while x < W / 2 - 0.05 {
                    if sr.float() > stock { x += sr.float(0.05...0.12); continue }
                    // A product: box dims (w, h, d) by shelf, color, facings.
                    let kind = sr.int(0...3)
                    var bw: Float, bh: Float, bd: Float
                    switch kind {
                    case 0: bw = 0.075; bh = 0.205; bd = 0.05          // cereal / carton
                    case 1: bw = 0.06; bh = 0.11; bd = 0.06            // tea or small food box
                    case 2: bw = 0.1; bh = 0.14; bd = 0.1              // appliance-style cube
                    default: bw = 0.14; bh = 0.09; bd = 0.1            // flat gift or tray box
                    }
                    if isBase { bw *= 1.3; bh *= 1.3; bd *= 1.25 }
                    bh = min(bh, maxH)
                    let n = sr.int(2...5)
                    let body = colors[sr.int(0...(colors.count - 1))], label = labelCols[sr.int(0...2)]
                    for f in 0..<n {
                        if x + bw > W / 2 - 0.03 { break }
                        // Missing facing sometimes; a leaning one now and then.
                        if f == n - 1 && sr.chance(0.25) { break }
                        let lean = sr.chance(0.12) && f == n - 1
                        let tilt = lean ? simd_quatf(degrees: sr.float(-8...(-3)), axis: V3(0, 0, 1)) : simd_quatf(degrees: sr.float(-0.8...0.8), axis: .up)
                        let hh = bh * sr.float(0.985...1.0)
                        let front = zFront - 0.012 - bd / 2 - sr.float(0...0.006)
                        let cx = x + bw / 2
                        m.add(Prim.roundedBox(V3(bw - 0.002, hh, bd), radius: 0.0015, bevelSegments: 1, material: body),
                              Xform(translation: V3(cx, sy + hh / 2 + 0.0005, front), rotation: tilt))
                        // Printed front panel: band and label, on the front face.
                        let fz = front + bd / 2 + 0.0004
                        flat(V3(bw * 0.8, hh * 0.38, 0.0008), V3(cx, sy + hh * 0.66, fz), label, rot: tilt)
                        flat(V3(bw * 0.8, hh * 0.08, 0.0008), V3(cx, sy + hh * 0.28, fz), body == "paper.sheet:EEE9DC" ? "paper.sheet:C94A3B" : "paper.sheet:EEE9DC", rot: tilt)
                        x += bw + sr.float(0.001...0.004)
                    }
                    x += sr.float(0.012...0.05)
                }
            }
            // ---- Planted, centered.
            let bb = m.bounds
            m = m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)))
            groundAO(&m, height: 0.1, floor: 0.7)
            return m
        }
        return LODModel(levels: [make(true), make(false)], switchDistances: [6])
    }
}
