import simd
import Foundation

/// Supermarket checkout lane, 3.0 m long along X. Parts: a laminate counter with a black conveyor belt
/// between stainless rails and an order divider bar, a flatbed scanner with a red scan line, a POS
/// touchscreen and cash drawer facing the cashier (-Z), a customer display and a card reader with keypad
/// on a pole facing the customer (+Z), a bagging shelf with a three-arm bag carousel and a stack of
/// bags, an impulse rack of candy and gum, a numbered lane light on a pole and an anti-fatigue mat.
public struct CheckoutLane: RealAsset {
    public static let id = "checkout-lane"
    public static let summary = "Supermarket checkout lane, 3.0 m: conveyor belt counter, scanner, POS screen, card reader, bag carousel, impulse rack, lane light."
    public static let tags = ["prop", "grocery", "retail", "commercial", "electronics", "furniture", "light", "interior"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 18, distance: 1.25, studio: true)

    /// Lane length along X (m) and counter height.
    public var length: Float = 3.0
    public var counterHeight: Float = 0.86
    /// Number on the lane light.
    public var laneNumber = 1
    public var laminate: MaterialKey = "laminate.white:5E6166"
    public var trim: MaterialKey = "metal.stainless"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(seed, hi: true), level(seed, hi: false)], switchDistances: [8])
    }

    func level(_ seed: UInt64, hi: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = length, H = counterHeight
        let x0 = -L / 2, beltEnd = x0 + 1.75, regEnd = beltEnd + 0.6, bagEnd = L / 2
        let cw: Float = 0.62
        let seg = hi ? 16 : 8
        // Counter body: belt section, register section, bagging section.
        GroceryKit.box(&m, V3(beltEnd - x0, H - 0.08, cw), V3((x0 + beltEnd) / 2, 0.04 + (H - 0.08) / 2, 0), laminate, r: 0.006)
        GroceryKit.box(&m, V3(beltEnd - x0, 0.08, cw - 0.06), V3((x0 + beltEnd) / 2, 0.04, 0), "plastic.black:1A1A1C", r: 0.004)
        GroceryKit.box(&m, V3(regEnd - beltEnd, H - 0.04, cw), V3((beltEnd + regEnd) / 2, (H - 0.04) / 2, 0), laminate, r: 0.006)
        GroceryKit.box(&m, V3(regEnd - beltEnd + 0.02, 0.04, cw + 0.02), V3((beltEnd + regEnd) / 2, H - 0.02, 0), "stone.terrazzo:5A5C60", r: 0.006)
        GroceryKit.box(&m, V3(bagEnd - regEnd, H - 0.12, cw), V3((regEnd + bagEnd) / 2, (H - 0.12) / 2, 0), laminate, r: 0.006)
        GroceryKit.box(&m, V3(bagEnd - regEnd, 0.03, cw + 0.02), V3((regEnd + bagEnd) / 2, H - 0.135, 0), "stone.terrazzo:5A5C60", r: 0.006)
        // Belt between rails, rollers at the ends, divider bar.
        let bw: Float = 0.42
        GroceryKit.box(&m, V3(beltEnd - x0 - 0.12, 0.02, bw), V3((x0 + beltEnd) / 2, H - 0.01, 0), "rubber.floor-mat:1C1C1E", r: 0.008)
        for s: Float in [-1, 1] {
            GroceryKit.box(&m, V3(beltEnd - x0, 0.03, (cw - bw) / 2), V3((x0 + beltEnd) / 2, H - 0.005, s * (bw / 2 + (cw - bw) / 4)), trim, r: 0.006)
        }
        for x in [x0 + 0.06, beltEnd - 0.06] {
            m.add(GroceryKit.cyl(0.012, bw, seg: seg, trim), Xform(translation: V3(x, H - 0.006, -bw / 2), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }
        let dx = x0 + 0.5 + rng.float(0...0.4)
        let bar = Prim.extrude([V2(-0.02, 0), V2(0.02, 0), V2(0, 0.035)], depth: 0.38, bevel: 0.002, bevelSegments: 1, material: "plastic.matte:2E4D8A")
        m.add(bar, Xform(translation: V3(dx, H, 0)))
        GroceryKit.print(&m, "NEXT", height: 0.012, at: V3(dx, H + 0.005, 0.0), "plastic.matte:FFFFFF",
                         rot: simd_quatf(degrees: -90, axis: .up) * simd_quatf(degrees: -30, axis: V3(1, 0, 0)))
        // Scanner: glass top with red line, vertical window.
        let sx = beltEnd + 0.22
        GroceryKit.box(&m, V3(0.36, 0.006, 0.3), V3(sx, H + 0.003, 0), "glass.display", r: 0.002)
        GroceryKit.decal(&m, 0.003, 0.24, V3(sx, H + 0.0065, 0), "emissive.signal-red", rot: simd_quatf(degrees: -90, axis: V3(1, 0, 0)))
        GroceryKit.box(&m, V3(0.06, 0.16, 0.3), V3(sx + 0.21, H + 0.08, 0), "plastic.black:1A1A1C", r: 0.01)
        GroceryKit.decal(&m, 0.12, 0.2, V3(sx + 0.179, H + 0.09, 0), "glass.tinted", rot: simd_quatf(degrees: -90, axis: .up))
        // POS screen facing the cashier (-Z), cash drawer below.
        let px = regEnd - 0.12
        m.add(GroceryKit.cyl(0.02, 0.28, seg: seg, "metal.anodized-black"), Xform(translation: V3(px, H, -0.18)))
        GroceryKit.box(&m, V3(0.38, 0.27, 0.04), V3(px, H + 0.4, -0.2), "plastic.black:1A1A1C", r: 0.01,
                       rot: simd_quatf(degrees: 15, axis: V3(1, 0, 0)))
        GroceryKit.decal(&m, 0.34, 0.22, V3(px, H + 0.4, -0.2205), "screen.ui", rot: simd_quatf(degrees: 15, axis: V3(1, 0, 0)) * simd_quatf(degrees: 180, axis: .up))
        GroceryKit.box(&m, V3(0.42, 0.11, 0.44), V3(px - 0.1, H - 0.1, -cw / 2 + 0.2), "metal.anodized-black", r: 0.006)
        GroceryKit.box(&m, V3(0.1, 0.012, 0.003), V3(px - 0.1, H - 0.1, -cw / 2 - 0.0215), trim, r: 0.001)
        // Customer display and card reader on a pole (+Z side).
        let cx = beltEnd + 0.06
        m.add(GroceryKit.cyl(0.015, 0.25, seg: seg, "metal.anodized-black"), Xform(translation: V3(cx, H, cw / 2 - 0.05)))
        GroceryKit.box(&m, V3(0.09, 0.16, 0.045), V3(cx, H + 0.3, cw / 2 - 0.05), "plastic.black:1A1A1C", r: 0.01, rot: simd_quatf(degrees: -25, axis: V3(1, 0, 0)))
        let tilt = simd_quatf(degrees: -25, axis: V3(1, 0, 0))
        GroceryKit.decal(&m, 0.07, 0.06, V3(cx, H + 0.335, cw / 2 - 0.05) + tilt.act(V3(0, 0, 0.0235)), "screen.kiosk", rot: tilt)
        if hi {
            for r in 0..<4 { for c in 0..<3 {
                GroceryKit.decal(&m, 0.016, 0.01, V3(cx + Float(c - 1) * 0.022, H + 0.235 + Float(r) * 0.016, cw / 2 - 0.05) + tilt.act(V3(0, 0, 0.0235)),
                                 r == 0 && c == 2 ? "plastic.matte:3A9A4A" : "plastic.matte:C8C8C4", rot: tilt)
            }}
        }
        GroceryKit.box(&m, V3(0.24, 0.14, 0.03), V3(cx + 0.22, H + 0.4, -0.15), "plastic.black:1A1A1C", r: 0.006)
        GroceryKit.decal(&m, 0.22, 0.12, V3(cx + 0.22, H + 0.4, -0.1345), "screen.kiosk")
        // Bag carousel: post, three arms, bags hanging.
        let bx = (regEnd + bagEnd) / 2, by = H - 0.12
        m.add(GroceryKit.cyl(0.015, 0.5, seg: seg, trim), Xform(translation: V3(bx, by, 0)))
        for k in 0..<3 {
            let a = Float(k) * 2 * .pi / 3 + 0.4
            let dir = V3(cos(a), 0, sin(a))
            GroceryKit.box(&m, V3(0.008, 0.008, 0.22), V3(bx, by + 0.48, 0) + dir * 0.11, trim, r: 0.003, rot: simd_quatf(angle: atan2(dir.x, dir.z), axis: .up))
            let bag = Prim.superellipsoid(V3(0.28, 0.4, 0.12), exponent: 3, subdivisions: hi ? 3 : 2, material: "plastic.translucent:F2F2EE")
            m.add(bag, Xform(translation: V3(bx, by + 0.27, 0) + dir * 0.13, rotation: simd_quatf(angle: atan2(dir.x, dir.z), axis: .up)))
        }
        // Impulse rack on the customer side of the belt.
        let rx = x0 + 0.45
        GroceryKit.box(&m, V3(0.6, 1.3, 0.2), V3(rx, 0.65, cw / 2 + 0.16), "metal.powdercoat:3A3E44", r: 0.006)
        for (i, y) in [Float(0.35), 0.65, 0.95].enumerated() {
            GroceryKit.box(&m, V3(0.56, 0.01, 0.16), V3(rx, y, cw / 2 + 0.17), "metal.powdercoat:3A3E44", r: 0.002)
            var sub = rng.fork(40 + i)
            GroceryKit.stockShelf(&m, x0: rx - 0.27, x1: rx + 0.27, y: y + 0.005, zFront: cw / 2 + 0.25, depth: 0.14, maxH: 0.2,
                                  packs: [.tray, .box], fill: 0.95, rng: &sub, hi: hi)
        }
        // Lane light pole with number box, at the start of the belt.
        let lx = x0 + 0.08
        m.add(GroceryKit.cyl(0.025, 2.1 - H, seg: seg, "metal.powdercoat:3A3E44"), Xform(translation: V3(lx, H, -cw / 2 + 0.06)))
        GroceryKit.box(&m, V3(0.18, 0.18, 0.18), V3(lx, 2.18, -cw / 2 + 0.06), "plastic.diffuser", r: 0.01)
        for f in 0..<4 {
            let rot = simd_quatf(degrees: Float(f) * 90, axis: .up)
            let off = rot.act(V3(0, 0, 0.0905))
            GroceryKit.decal(&m, 0.15, 0.15, V3(lx, 2.18, -cw / 2 + 0.06) + off, "emissive.panel", rot: rot)
            GroceryKit.print(&m, String(laneNumber), height: 0.1, at: V3(lx, 2.13, -cw / 2 + 0.06) + rot.act(V3(0, 0, 0.0915)), "plastic.matte:1F4E96", rot: rot)
        }
        // Anti-fatigue mat on the cashier side.
        GroceryKit.box(&m, V3(0.9, 0.012, 0.6), V3(beltEnd + 0.2, 0.006, -cw / 2 - 0.35), "rubber.floor-mat", r: 0.004)
        groundAO(&m, height: 0.1, floor: 0.7)
        return m
    }
}
