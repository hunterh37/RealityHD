import simd
import Foundation

/// Traditional mahogany china cabinet, 100 x 190 x 45 cm: plinth base, lower case with two drawers over two
/// shaker doors (brass knobs and bar pulls), a 30 mm counter slab, a set-back upper case with two glazed
/// doors (muntin grid, glass panes), three interior shelves holding plates, and stepped crown molding.
public struct ChinaCabinet: RealAsset {
    public static let id = "china-cabinet"
    public static let summary = "Mahogany china cabinet, 1.0 m wide: glazed upper doors over shelves with plates, lower drawers and doors, crown molding, plinth."
    public static let tags = ["prop", "floorplan", "dining", "furniture", "wood", "glass", "interior"]
    public static let budget = 12_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 26, elevation: 12, distance: 3.2, studio: true)

    /// Overall size in meters (x width, y height, z depth); the doors face +Z.
    public var size = V3(1.0, 1.9, 0.45)
    /// Depth of the upper case in meters (set back from the lower front).
    public var upperDepth: Float = 0.34
    /// Case wood.
    public var woodMaterial: MaterialKey = "wood.mahogany"
    /// Counter slab and crown wood (a shade darker).
    public var topMaterial: MaterialKey = "wood.mahogany:5B2E20"
    /// Back panel.
    public var backMaterial: MaterialKey = "wood.plywood:6E5238"
    /// Door glass.
    public var glassMaterial: MaterialKey = "glass.pane"
    /// Knob and pull metal.
    public var metalMaterial: MaterialKey = "metal.brass-aged"
    /// Display plates.
    public var plateMaterial: MaterialKey = "ceramic.stoneware"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [6])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y
        let D = size.z - 0.0265                       // lower body depth; hardware adds 26.5 mm
        let wood = woodMaterial
        func box(_ s: V3, _ p: V3, _ mat: MaterialKey, r: Float = 0.0015, hard: Bool = false) {
            let surf = hard ? cuboid(s, material: mat) : Prim.roundedBox(s, radius: r, bevelSegments: 1, material: mat)
            m.add(surf, Xform(translation: p).jittered(&rng, deg: 0.03, offset: 0.0001))
        }
        let panel: Float = 0.02
        let zBack = -D / 2
        let knob: [V2] = [V2(0.0001, 0), V2(0.009, 0), V2(0.009, 0.0012), V2(0.003, 0.002), V2(0.003, 0.007), V2(0.0075, 0.0085),
                          V2(0.0115, 0.0125), V2(0.0125, 0.017), V2(0.0105, 0.021), V2(0.006, 0.0235), V2(0.0001, 0.024)]
        func shaker(cx: Float, cy: Float, w: Float, h: Float, zF: Float, stile: Float, rail: Float) {
            let dd: Float = 0.02
            let zc = zF - dd / 2
            box(V3(stile, h, dd), V3(cx - w / 2 + stile / 2, cy, zc), wood)
            box(V3(stile, h, dd), V3(cx + w / 2 - stile / 2, cy, zc), wood)
            box(V3(w - 2 * stile + 0.004, rail, dd), V3(cx, cy + h / 2 - rail / 2, zc), wood)
            box(V3(w - 2 * stile + 0.004, rail, dd), V3(cx, cy - h / 2 + rail / 2, zc), wood)
            box(V3(w - 2 * stile + 0.004, h - 2 * rail + 0.004, 0.006), V3(cx, cy, zF - dd + 0.004), wood, r: 0.0008)
            if detail {
                let iw = w - 2 * stile, ih = h - 2 * rail
                for (bw, bh, dx, dy) in [(iw, Float(0.005), Float(0), ih / 2 - 0.0025), (iw, 0.005, 0, -ih / 2 + 0.0025), (0.005, ih - 0.01, iw / 2 - 0.0025, 0), (0.005, ih - 0.01, -iw / 2 + 0.0025, 0)] {
                    box(V3(bw, bh, 0.0025), V3(cx + dx, cy + dy, zF - dd + 0.0085), wood, hard: true)
                }
            }
        }
        func knobAt(_ x: Float, _ y: Float, _ z: Float) {
            m.add(Prim.lathe(knob, segments: detail ? 20 : 10, seamTile: 0.1, material: metalMaterial), Xform(translation: V3(x, y, z), rotation: facing(V3(0, 0, 1))))
        }

        // ---- Lower case ----
        let plinthH: Float = 0.09, counterY0: Float = 0.88, counterT: Float = 0.03
        box(V3(W - 0.03, plinthH, D - 0.03), V3(0, plinthH / 2, -0.005), wood, hard: true)
        let loY0 = plinthH + panel, loY1 = counterY0, loH = loY1 - loY0, loMid = (loY0 + loY1) / 2
        let bodyD = D - 0.025, bodyZ = zBack + bodyD / 2
        box(V3(W - 0.004, panel, bodyD), V3(0, plinthH + panel / 2, bodyZ), wood, hard: true)
        for s: Float in [-1, 1] { box(V3(panel, loH, bodyD), V3(s * (W / 2 - panel / 2 - 0.002), loMid, bodyZ), wood, hard: true) }
        box(V3(W - 0.044, loH, 0.006), V3(0, loMid, zBack + 0.01), backMaterial, hard: true)
        let zF = D / 2
        let drawerH: Float = 0.12
        let dwY1 = loY1, dwY0 = dwY1 - drawerH - 0.003
        box(V3(W - 0.044, 0.018, bodyD), V3(0, dwY0 - 0.009, bodyZ), wood, hard: true)            // rail under the drawers
        box(V3(panel, dwY0 - loY0, bodyD), V3(0, (loY0 + dwY0) / 2, bodyZ), wood, hard: true)       // center stile between doors
        // Drawers: two across.
        let inW = W - 2 * panel - 0.004
        let drW = (inW - 0.003) / 2
        for s: Float in [-1, 1] {
            let cx = s * (drW / 2 + 0.0015)
            shaker(cx: cx, cy: (dwY0 + dwY1) / 2, w: drW, h: drawerH - 0.002, zF: zF, stile: 0.045, rail: 0.03)
            var pull = barHandle(length: 0.1, standoff: 0.022, radius: 0.0045, overhang: 0.008, material: metalMaterial)
            if !detail { pull = Prim.cylinder(radius: 0.005, height: 0.116, bevel: 0.003, segments: 8, bevelSegments: 1, material: metalMaterial) }
            m.add(pull, Xform(translation: V3(cx, (dwY0 + dwY1) / 2, zF)))
        }
        // Doors: two shaker doors under the drawers.
        let doorH = dwY0 - loY0 - 0.004, doorCy = (loY0 + dwY0) / 2
        let doorW = (inW - panel) / 2 - 0.003
        for s: Float in [-1, 1] {
            let cx = s * (panel / 2 + 0.0015 + doorW / 2)
            shaker(cx: cx, cy: doorCy, w: doorW, h: doorH, zF: zF, stile: 0.065, rail: 0.07)
            knobAt(cx - s * (doorW / 2 - 0.033), doorCy + doorH / 2 - 0.12, zF)
        }
        // Counter slab: 30 mm with eased edge, overhangs the front by 15 mm.
        m.add(Prim.extrude(Shape2D.roundedRect(W, D + 0.015, radius: 0.008, segments: detail ? 3 : 1), depth: counterT, bevel: 0.0035, bevelSegments: detail ? 3 : 1, material: topMaterial),
              Xform(translation: V3(0, counterY0 + counterT / 2, 0.0075), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))

        // ---- Upper case (set back, flush with the lower back) ----
        let upW = W - 0.06, upD = upperDepth
        let uY0 = counterY0 + counterT, uY1 = H - 0.065, uH = uY1 - uY0, uMid = (uY0 + uY1) / 2
        let uZc = zBack + upD / 2, uF = zBack + upD
        box(V3(upW, panel, upD), V3(0, uY0 + panel / 2, uZc), wood, hard: true)
        box(V3(upW, panel, upD), V3(0, uY1 - panel / 2, uZc), wood, hard: true)
        for s: Float in [-1, 1] { box(V3(panel, uH, upD), V3(s * (upW / 2 - panel / 2), uMid, uZc), wood, hard: true) }
        box(V3(upW - 2 * panel, uH, 0.006), V3(0, uMid, zBack + 0.012), backMaterial, hard: true)
        // Face frame lip (30 mm stiles) so the doors close against something.
        for s: Float in [-1, 1] { box(V3(0.03, uH, 0.012), V3(s * (upW / 2 - 0.015), uMid, uF - 0.006), wood, hard: true) }
        // Shelves: three, 18 mm, with plate-groove strips; plates stand and stack on them.
        let shelfYs: [Float] = [uY0 + 0.30, uY0 + 0.59, uY0 + 0.80]
        let uIn = upW - 2 * panel
        for y in shelfYs {
            box(V3(uIn - 0.002, 0.018, upD - 0.04), V3(0, y, zBack + 0.012 + (upD - 0.04) / 2 + 0.003), wood, hard: true)
            if detail { box(V3(uIn - 0.04, 0.008, 0.012), V3(0, y + 0.012, uF - 0.03), wood, hard: true) }      // plate-rail lip on the front
        }
        // Plates: leaned plates on the second shelf, stacks on the first.
        let plate: [V2] = [V2(0.0001, 0), V2(0.07, 0), V2(0.085, 0.002), V2(0.115, 0.016), V2(0.12, 0.0185), V2(0.113, 0.0187), V2(0.085, 0.006),
                           V2(0.07, 0.004), V2(0.0001, 0.0042)]
        let seg = detail ? 16 : 10
        let plates = Prim.lathe(plate, segments: seg, seamTile: 0.3, material: plateMaterial)
        let stackY = shelfYs[0] + 0.009
        for (x, count) in [(Float(-0.2), 3), (0.12, 3)] {
            for k in 0..<count {
                m.add(plates, Xform(translation: V3(x, stackY + Float(k) * 0.019, zBack + 0.012 + 0.14)))
            }
        }
        let tilt: Float = 12
        for (i, x) in [Float(-0.2), 0.0, 0.2].enumerated() {
            let r = simd_quatf(degrees: 90 - tilt, axis: V3(1, 0, 0))
            let y = shelfYs[1] + 0.009 + 0.12 * sin(tilt * .pi / 180) - (i == 1 ? 0 : 0)
            m.add(plates, Xform(translation: V3(x, y + 0.08, zBack + 0.012 + 0.05), rotation: r))
        }
        let topPlate = Xform(translation: V3(0, shelfYs[2] + 0.009, zBack + 0.012 + 0.14))
        m.add(plates, topPlate)

        // Glazed doors: frame with muntin grid (2 columns x 3 rows) and a glass pane behind it.
        let udW = (upW - 0.06) / 2 - 0.0015
        let udH = uH - 0.004
        for s: Float in [-1, 1] {
            let cx = s * (udW / 2 + 0.0015)
            let dd: Float = 0.022, zc = uF - dd / 2 + 0.002
            let st: Float = 0.055, rl: Float = 0.06
            box(V3(st, udH, dd), V3(cx - udW / 2 + st / 2, uMid, zc), wood)
            box(V3(st, udH, dd), V3(cx + udW / 2 - st / 2, uMid, zc), wood)
            box(V3(udW - 2 * st + 0.004, rl, dd), V3(cx, uMid + udH / 2 - rl / 2, zc), wood)
            box(V3(udW - 2 * st + 0.004, rl, dd), V3(cx, uMid - udH / 2 + rl / 2, zc), wood)
            let gw = udW - 2 * st, gh = udH - 2 * rl
            m.add(cuboid(V3(gw + 0.004, gh + 0.004, 0.003), material: glassMaterial), Xform(translation: V3(cx, uMid, zc - 0.002)))
            // Muntins: one vertical, two horizontal, 12 mm wide, 14 mm deep, proud of the glass on both sides.
            box(V3(0.012, gh, 0.014), V3(cx, uMid, zc), wood, r: 0.0012)
            for k in 1...2 {
                box(V3(gw, 0.012, 0.014), V3(cx, uMid - gh / 2 + gh * Float(k) / 3, zc), wood, r: 0.0012)
            }
            // Brass knob on the meeting stile.
            knobAt(cx - s * (udW / 2 - st / 2), uMid - 0.05, uF + 0.002 + 0.0)
        }

        // ---- Crown molding: stepped cornice around the top ----
        let crownY = H - 0.065
        box(V3(upW + 0.012, 0.025, upD + 0.012), V3(0, crownY + 0.0125, uZc + 0.006 - 0.0), topMaterial, r: 0.002)
        box(V3(upW + 0.03, 0.022, upD + 0.03), V3(0, crownY + 0.036, uZc + 0.015 - 0.0), topMaterial, r: 0.002)
        box(V3(upW + 0.05, 0.018, upD + 0.05), V3(0, crownY + 0.056, uZc + 0.025 - 0.0), topMaterial, r: 0.003)
        // Dentil strip under the crown front (cove proxy): thin cap bead.
        if detail {
            for k in 0..<22 {
                let x = -upW / 2 + 0.02 + Float(k) * ((upW - 0.04) / 21)
                box(V3(0.016, 0.014, 0.008), V3(x, crownY - 0.007, uF + 0.004), topMaterial, hard: true)
            }
        }

        // Center on z: hardware and counter overhang change the span.
        for i in m.surfaces.indices { m.surfaces[i].positions = m.surfaces[i].positions.map { $0 - V3(0, 0, 0.012) } }
        groundAO(&m, height: 0.3, floor: 0.55)
        return m
    }
}
