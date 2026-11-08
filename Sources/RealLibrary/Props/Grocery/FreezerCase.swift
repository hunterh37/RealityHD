import simd
import Foundation

/// Glass-door reach-in freezer, one two-door section: 1.6 m wide, 2.15 m tall, 0.9 m deep, front toward
/// +Z. Parts: plinth, white cabinet with a lit header sign, black interior with five wire shelves and
/// price rails, a center mullion with a vertical LED strip, and two framed glass doors hinged on the
/// outer edges with full-height chrome pull bars. Frozen stock (pizza boxes, ice cream pints, vegetable
/// bags, meal trays) under invented brands. States: closed, left-open, open.
public struct FreezerCase: RealArticulated {
    public static let id = "freezer-case"
    public static let summary = "Glass-door reach-in freezer, 1.6 x 2.15 x 0.9 m: two hinged framed glass doors, LED mullion, wire shelves with frozen stock."
    public static let tags = ["prop", "grocery", "retail", "commercial", "appliance", "glass", "metal", "door", "light", "articulated"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 8, distance: 1.5, studio: true)

    /// Section width, height and depth (m).
    public var size = V3(1.6, 2.15, 0.9)
    /// Shelf tops above the floor (m).
    public var shelfHeights: [Float] = [0.2, 0.55, 0.9, 1.25, 1.6]
    /// Header sign word.
    public var label = "FROZEN"
    public var fill: Float = 0.94
    public var shell: MaterialKey = "metal.powder-white"
    public var frame: MaterialKey = "metal.anodized-black"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [9])
        let W = size.x, H = size.y, D = size.z
        let zb = -D / 2, zf = D / 2
        let doorZ = zf - 0.03, y0: Float = 0.12, y1 = H - 0.2
        let inner: MaterialKey = "metal.powdercoat:1E2125"
        for l in 0..<2 {
            let hi = l == 0
            var rng = SeededRNG(seed: seed)
            var m = Model(name: Self.id)
            GroceryKit.box(&m, V3(W, 0.12, D - 0.04), V3(0, 0.06, -0.02), "metal.powdercoat:2A2C30", r: 0.004)
            for s: Float in [-1, 1] { GroceryKit.box(&m, V3(0.04, H, D), V3(s * (W / 2 - 0.02), H / 2, 0), shell, r: 0.006) }
            GroceryKit.box(&m, V3(W, 0.04, D), V3(0, H - 0.02, 0), shell, r: 0.006)
            GroceryKit.box(&m, V3(W, H, 0.05), V3(0, H / 2, zb + 0.025), shell, r: 0.006)
            GroceryKit.box(&m, V3(W - 0.08, y1 - y0, 0.01), V3(0, (y0 + y1) / 2, zb + 0.055), inner, r: 0.002)
            GroceryKit.box(&m, V3(W - 0.08, 0.01, D - 0.1), V3(0, y0, -0.02), inner, r: 0.002)
            // Header with lit sign.
            GroceryKit.box(&m, V3(W, H - y1, 0.06), V3(0, (H + y1) / 2, zf - 0.03), frame, r: 0.004)
            GroceryKit.decal(&m, W - 0.1, H - y1 - 0.06, V3(0, (H + y1) / 2, zf + 0.0005), "emissive.panel")
            GroceryKit.print(&m, label, height: 0.08, at: V3(0, (H + y1) / 2 - 0.04, zf + 0.001), "plastic.matte:1F4E96", maxWidth: W * 0.6)
            // Door frame surround and center mullion with LED.
            GroceryKit.box(&m, V3(W - 0.04, 0.03, 0.05), V3(0, y0 - 0.015, doorZ - 0.03), frame, r: 0.003)
            GroceryKit.box(&m, V3(0.05, y1 - y0, 0.05), V3(0, (y0 + y1) / 2, doorZ - 0.03), frame, r: 0.003)
            GroceryKit.decal(&m, 0.012, y1 - y0 - 0.04, V3(0, (y0 + y1) / 2, doorZ - 0.0545), "emissive.lamp-white",
                             rot: simd_quatf(degrees: 180, axis: .up))
            // Shelves and stock.
            for (si, sy) in shelfHeights.enumerated() {
                let d = D - 0.2
                let front = zb + 0.06 + d
                if si > 0 {
                    for k in 0..<(hi ? 9 : 3) {
                        let z = zb + 0.07 + Float(k) * (d - 0.02) / Float(hi ? 8 : 2)
                        GroceryKit.box(&m, V3(W - 0.09, 0.004, 0.004), V3(0, sy - 0.004, z), "metal.chrome", r: 0.0015)
                    }
                    GroceryKit.priceRail(&m, x0: -W / 2 + 0.05, x1: W / 2 - 0.05, y: sy - 0.016, z: front, rng: &rng, hi: hi)
                }
                let top = si < shelfHeights.count - 1 ? shelfHeights[si + 1] - 0.03 : y1 - 0.03
                let mixes: [[GroceryKit.Pack]] = [[.tray, .box], [.bag, .tray], [.cup, .cup], [.box, .tray], [.bag, .bag]]
                let mix = mixes[si % mixes.count]
                GroceryKit.stockShelf(&m, x0: -W / 2 + 0.05, x1: W / 2 - 0.05, y: sy, zFront: front - 0.01, depth: d - 0.04,
                                      maxH: min(0.3, top - sy), packs: mix, fill: fill, rng: &rng, hi: hi, coarseAt: 7000, boxAt: 9500)
            }
            rig.base[l] = m
        }
        // Doors: outer-edge hinges, swing out toward +Z.
        let gap: Float = 0.004
        let doors: [(String, Float, Float, Float)] = [("left", -W / 2 + 0.04, -0.025 - gap, -1), ("right", 0.025 + gap, W / 2 - 0.04, 1)]
        for (name, x0, x1, hs) in doors {
            let hx = hs < 0 ? x0 : x1
            rig.part(name, pivot: V3(hx, (y0 + y1) / 2, doorZ), joint: .hinge(axis: .up, hs < 0 ? -100...0 : 0...100, duration: 0.9))
            for l in 0..<2 {
                var d = Model(name: name)
                let w = x1 - x0, h = y1 - y0 - 0.01, cx = (x0 + x1) / 2, cy = (y0 + y1) / 2
                let rail: Float = 0.05
                GroceryKit.box(&d, V3(w, rail, 0.04), V3(cx, cy + h / 2 - rail / 2, doorZ), frame, r: 0.004)
                GroceryKit.box(&d, V3(w, rail + 0.02, 0.04), V3(cx, cy - h / 2 + (rail + 0.02) / 2, doorZ), frame, r: 0.004)
                for e in [x0 + rail / 2, x1 - rail / 2] { GroceryKit.box(&d, V3(rail, h - 2 * rail, 0.04), V3(e, cy, doorZ), frame, r: 0.004) }
                GroceryKit.box(&d, V3(w - 2 * rail + 0.02, h - 2 * rail - 0.01, 0.012), V3(cx, cy + 0.005, doorZ), "glass.display", r: 0.002)
                // Pull bar on the free edge, on two standoffs.
                let px = hs < 0 ? x1 - 0.035 : x0 + 0.035
                d.add(GroceryKit.cyl(0.012, h * 0.7, seg: l == 0 ? 12 : 6, "metal.chrome", bevel: 0.004), Xform(translation: V3(px, cy - h * 0.35, doorZ + 0.07)))
                for sy in [cy - h * 0.3, cy + h * 0.3] {
                    d.add(GroceryKit.cyl(0.008, 0.05, seg: 8, "metal.chrome"), Xform(translation: V3(px, sy, doorZ + 0.02), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
                }
                rig.set(d, part: name, lod: l)
            }
        }
        groundAO(&rig, height: 0.1, floor: 0.75)
        rig.states = [RigState("closed"), RigState("left-open", ["left": -95]), RigState("open", ["left": -95, "right": 95])]
        return rig
    }
}
