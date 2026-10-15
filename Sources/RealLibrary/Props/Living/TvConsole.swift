import simd
import Foundation

/// Mid-century media console, 160 x 56 x 42 cm: veneered oak case on four splayed walnut legs with brass
/// caps, a 25 mm eased top, two framed slatted doors (brass knobs), a center bay with an open shelf (back
/// panel with a cable cutout) above two drawers with brass bar pulls. Doors and drawers are closed.
public struct TvConsole: RealAsset {
    public static let id = "tv-console"
    public static let summary = "Oak media console, 1.6 m: slatted side doors, center open shelf with cable cutout, two drawers, splayed walnut legs."
    public static let tags = ["prop", "floorplan", "living", "furniture", "wood", "interior"]
    public static let budget = 9500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 16, distance: 2.0, studio: true)

    /// Overall size in meters (x width, y height, z depth); the doors face +Z.
    public var size = V3(1.6, 0.56, 0.42)
    /// Leg height under the case.
    public var legHeight: Float = 0.14
    /// Case veneer.
    public var caseMaterial: MaterialKey = "wood.veneer-oak:B89B72"
    /// Solid oak for door frames, slats and drawer fronts.
    public var frontMaterial: MaterialKey = "wood.oak:AD8F64"
    /// Leg wood.
    public var legMaterial: MaterialKey = "wood.walnut:5E3F2B"
    /// Back panel.
    public var backMaterial: MaterialKey = "wood.plywood:8A6C48"
    /// Knob, pull and cap metal.
    public var metalMaterial: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [5])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y, D = size.z - 0.025, L = legHeight
        let dark: MaterialKey = "plastic.black"
        func box(_ s: V3, _ p: V3, _ mat: MaterialKey, r: Float = 0.0015) {
            m.add(Prim.roundedBox(s, radius: r, bevelSegments: 1, material: mat), Xform(translation: p).jittered(&rng, deg: 0.03, offset: 0.0001))
        }
        let topT: Float = 0.025, panel: Float = 0.02
        let zFront = D / 2                                       // doors and drawers sit in the front 20 mm
        let bodyD = D - 0.02, bodyZ: Float = -0.01

        // Top: veneered slab with eased edge; plan corners r 12 mm.
        m.add(Prim.extrude(Shape2D.roundedRect(W, D, radius: 0.012, segments: detail ? 4 : 2), depth: topT, bevel: 0.003, bevelSegments: detail ? 3 : 1, material: caseMaterial),
              Xform(translation: V3(0, H - topT / 2, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        // Carcass: bottom, sides, two dividers, center shelf and drawer divider.
        let inY0 = L + panel, inY1 = H - topT, inH = inY1 - inY0
        box(V3(W - 0.004, panel, bodyD), V3(0, L + panel / 2, bodyZ), caseMaterial)
        for s: Float in [-1, 1] { box(V3(panel, inH, bodyD), V3(s * (W / 2 - panel / 2 - 0.002), (inY0 + inY1) / 2, bodyZ), caseMaterial) }
        let divX: Float = 0.30
        for s: Float in [-1, 1] { box(V3(panel, inH, bodyD), V3(s * divX, (inY0 + inY1) / 2, bodyZ), caseMaterial) }
        let shelfY: Float = inY0 + 0.20
        box(V3(2 * divX - panel, 0.02, bodyD), V3(0, shelfY, bodyZ), caseMaterial)
        // Back panel with a cable cutout (90 x 45 mm) at the upper right of the open bay.
        let bz = -D / 2 + 0.012
        box(V3(W - 0.044, shelfY - inY0 + 0.0, 0.006), V3(0, (inY0 + shelfY) / 2, bz), backMaterial, r: 0.0005)
                for s: Float in [-1, 1] { box(V3((W / 2 - 0.02 - divX) - 0.012, inH, 0.006), V3(s * ((W / 2 - 0.02 + divX) / 2 + 0.005), (inY0 + inY1) / 2, bz), backMaterial, r: 0.0005) }
        let cutW: Float = 0.09, cutH: Float = 0.045, cutX: Float = 0.17, cutY = shelfY + 0.01 + 0.05
        let bayHalf = divX - panel / 2
        // Build the bay back in four pieces around the cutout.
        let bx0 = -bayHalf, bx1 = bayHalf, by0 = shelfY + 0.01, by1 = inY1
        let cx0 = cutX - cutW / 2, cx1 = cutX + cutW / 2, cy0 = cutY - cutH / 2, cy1 = cutY + cutH / 2
        box(V3(bx1 - bx0, cy0 - by0, 0.006), V3((bx0 + bx1) / 2, (by0 + cy0) / 2, bz), backMaterial, r: 0.0005)
        box(V3(bx1 - bx0, by1 - cy1, 0.006), V3((bx0 + bx1) / 2, (cy1 + by1) / 2, bz), backMaterial, r: 0.0005)
        box(V3(cx0 - bx0, cy1 - cy0, 0.006), V3((bx0 + cx0) / 2, (cy0 + cy1) / 2, bz), backMaterial, r: 0.0005)
        box(V3(bx1 - cx1, cy1 - cy0, 0.006), V3((cx1 + bx1) / 2, (cy0 + cy1) / 2, bz), backMaterial, r: 0.0005)
        // Cable grommet: brass-edged ring around the cutout.
        if detail {
            for (w, h, x, y) in [(cutW + 0.008, 0.004, cutX, cy1 + 0.002), (cutW + 0.008, 0.004, cutX, cy0 - 0.002), (0.004, cutH, cx0 - 0.002, cutY), (0.004, cutH, cx1 + 0.002, cutY)] {
                box(V3(w, h, 0.004), V3(x, y, bz + 0.004), "plastic.black", r: 0.0008)
            }
        }

        // Doors: 20 mm frame (45 mm stiles, 55 mm rails) with vertical slats over a dark backing.
        let doorW = (W / 2 - panel - 0.002) - divX - panel / 2 - 0.002
        let doorH = inH - 0.004
        let doorCx = (W / 2 - panel - 0.002 + divX + panel / 2) / 2
        for s: Float in [-1, 1] {
            let cx = s * doorCx, cy = (inY0 + inY1) / 2
            let stile: Float = 0.045, rail: Float = 0.055, dd: Float = 0.02
            box(V3(stile, doorH, dd), V3(cx - doorW / 2 + stile / 2, cy, zFront - dd / 2), frontMaterial)
            box(V3(stile, doorH, dd), V3(cx + doorW / 2 - stile / 2, cy, zFront - dd / 2), frontMaterial)
            box(V3(doorW - 2 * stile + 0.004, rail, dd), V3(cx, cy + doorH / 2 - rail / 2, zFront - dd / 2), frontMaterial)
            box(V3(doorW - 2 * stile + 0.004, rail, dd), V3(cx, cy - doorH / 2 + rail / 2, zFront - dd / 2), frontMaterial)
            let iw = doorW - 2 * stile, ih = doorH - 2 * rail
            m.add(cuboid(V3(iw, ih, 0.004), material: dark), Xform(translation: V3(cx, cy, zFront - dd + 0.003)))
            let pitch: Float = 0.0225, sw: Float = 0.0145
            let n = Int(iw / pitch)
            let start = cx - Float(n - 1) * pitch / 2
            for i in 0..<n {
                m.add(cuboid(V3(sw, ih + 0.004, 0.011), material: frontMaterial), Xform(translation: V3(start + Float(i) * pitch, cy, zFront - dd + 0.0065)))
            }
            // Brass knob on the stile nearest the center, 28 mm head.
            let kx = cx + (-s) * (doorW / 2 - stile / 2)
            let knob: [V2] = [V2(0.0001, 0), V2(0.009, 0), V2(0.009, 0.0012), V2(0.003, 0.002), V2(0.003, 0.007), V2(0.0075, 0.0085),
                              V2(0.0115, 0.0125), V2(0.0125, 0.017), V2(0.0105, 0.021), V2(0.006, 0.0235), V2(0.0001, 0.024)]
            m.add(Prim.lathe(knob, segments: detail ? 20 : 10, seamTile: 0.1, material: metalMaterial),
                  Xform(translation: V3(kx, cy + 0.04, zFront), rotation: facing(V3(0, 0, 1))))
        }

        // Center bay: two drawers under the open shelf (shelf top at shelfY + 0.01).
        let dBot = inY0 + 0.002, dTop = shelfY - 0.010 - 0.002
        let drH = dTop - dBot, drW = (2 * divX - panel - 0.006) / 2
        for s: Float in [-1, 1] {
            let cx = s * (drW / 2 + 0.001)
            m.add(cuboid(V3(drW, drH, 0.17), material: dark), Xform(translation: V3(cx, (dBot + dTop) / 2, zFront - 0.09)))
            box(V3(drW - 0.003, drH - 0.003, 0.02), V3(cx, (dBot + dTop) / 2, zFront - 0.01), frontMaterial, r: 0.002)
            if detail {
                for dy in [drH / 2 - 0.016, -drH / 2 + 0.016] {
                    m.add(cuboid(V3(drW - 0.045, 0.0012, 0.0005), material: dark), Xform(translation: V3(cx, (dBot + dTop) / 2 + dy, zFront + 0.0002)))
                }
            }
            var pull = barHandle(length: 0.09, standoff: 0.02, radius: 0.0045, overhang: 0.008, material: metalMaterial)
            if !detail { pull = Prim.cylinder(radius: 0.005, height: 0.106, bevel: 0.003, segments: 8, bevelSegments: 1, material: metalMaterial) }
            m.add(pull, Xform(translation: V3(cx, (dBot + dTop) / 2, zFront)))
        }

        // Legs: 4 tapered square legs 40 -> 28 mm, splayed 6 degrees outward, brass cap 15 mm, set into the base.
        let splay: Float = tan(6 * .pi / 180)
        let lx = W / 2 - 0.07, lz = D / 2 - 0.06
        func hw(_ y: Float) -> Float { 0.014 + 0.006 * (y / L) }
        func ctr(_ sx: Float, _ sz: Float, _ y: Float) -> V3 { let k = (L - y) * splay; return V3(sx * (lx + k), y, sz * (lz + k * 0.7)) }
        let cap: Float = 0.014
        for sx: Float in [-1, 1] {
            for sz: Float in [-1, 1] {
                var rings: [[V3]] = []
                for y in [L + 0.004, L * 0.5, cap - 0.001] {
                    let w = hw(min(y, L)) * 2
                    rings.append(Prim.ring(Shape2D.roundedRect(w, w, radius: 0.003, segments: detail ? 2 : 1), y: y, offset: ctr(sx, sz, y) - V3(0, y, 0)))
                }
                var leg = Prim.loft(rings, capStart: true, capEnd: true, material: legMaterial).flipped()
                leg.uvs = leg.uvs.map { V2($0.y, $0.x) }; leg.computeTangents()
                m.add(leg)
                var sb: [[V3]] = []
                for y in [0.0005, cap] {
                    let w = hw(y) * 2 + 0.0016
                    sb.append(Prim.ring(Shape2D.roundedRect(w, w, radius: 0.004, segments: detail ? 2 : 1), y: y, offset: ctr(sx, sz, y) - V3(0, y, 0)))
                }
                m.add(Prim.loft(sb, capStart: true, capEnd: true, material: metalMaterial).flipped())
            }
        }
        // Leg mounting plates under the base (rail blocks), visible between legs from low angles.
        for sz: Float in [-1, 1] {
            box(V3(W - 0.18, 0.025, 0.03), V3(0, L - 0.0125, sz * (lz - 0.005)), legMaterial, r: 0.002)
        }

        // Hardware protrudes 25 mm past the body; center the overall depth on z = 0.
        for i in m.surfaces.indices { m.surfaces[i].positions = m.surfaces[i].positions.map { $0 - V3(0, 0, 0.0125) } }
        groundAO(&m, height: 0.16, floor: 0.55)
        return m
    }
}
