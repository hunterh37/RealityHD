import simd
import Foundation

/// Retail checkout counter, 150 x 100 x 70 cm: white laminate cabinet with oak trim and a stainless kick plate, a laminate
/// top with a raised oak lip on the customer side (+Z), a stainless-railed conveyor belt on the left, a tablet POS on a
/// swivel stand with a card reader, a receipt printer and a barcode scanner on the right. The cashier side (-Z) has a
/// cash drawer front and an open bagging niche with a shelf of paper bags.
public struct CheckoutCounter: RealAsset {
    public static let id = "checkout-counter"
    public static let summary = "Checkout counter, 1.5 x 1.0 x 0.7 m: laminate cabinet with oak trim, POS terminal, card reader, printer, belt and bagging shelf."
    public static let tags = ["prop", "floorplan", "commercial", "retail", "furniture", "interior"]
    public static let budget = 13000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 18, distance: 0.9, studio: true)

    /// Overall size in meters (x width, y height to the top of the POS terminal, z depth); the customer side faces +Z.
    public var size = V3(1.5, 1.0, 0.7)
    /// Counter top surface height.
    public var topHeight: Float = 0.83
    /// Cabinet and top laminate.
    public var laminate: MaterialKey = "laminate.white"
    /// Trim wood.
    public var trim: MaterialKey = "wood.veneer-oak"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [4.5])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, D = size.z
        let topY = topHeight, slabT: Float = 0.04
        let kick: Float = 0.1
        let zf = D / 2 - 0.03, zb = -D / 2 + 0.03          // carcass front and back planes (top overhangs 3 cm)
        let steel: MaterialKey = "metal.stainless", black: MaterialKey = "plastic.black:1C1C1E", matte: MaterialKey = "plastic.matte:2B2B2E"

        func box(_ s: V3, _ p: V3, _ mat: MaterialKey? = nil, r: Float = 0.002, rot: simd_quatf = .identity) {
            m.add(Prim.roundedBox(s, radius: min(r, s.x / 2.2, s.y / 2.2, s.z / 2.2), bevelSegments: 1, material: mat ?? laminate), Xform(translation: p, rotation: rot))
        }
        func flat(_ s: V3, _ p: V3, _ mat: MaterialKey? = nil, rot: simd_quatf = .identity) {
            m.add(cuboid(s, material: mat ?? laminate), Xform(translation: p, rotation: rot))
        }
        func cylX(_ r: Float, _ len: Float, _ p: V3, _ mat: MaterialKey, seg: Int = 12) {
            m.add(Prim.cylinder(radius: r, height: len, bevel: r * 0.2, segments: detail ? seg : 6, bevelSegments: 1, material: mat),
                  Xform(translation: p - V3(len / 2, 0, 0), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
        }
        func cylZ(_ r: Float, _ len: Float, _ p: V3, _ mat: MaterialKey, seg: Int = 12) {
            m.add(Prim.cylinder(radius: r, height: len, bevel: r * 0.2, segments: detail ? seg : 6, bevelSegments: 1, material: mat),
                  Xform(translation: p - V3(0, 0, len / 2), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }

        // Top slab with a rounded edge, oak edge band on the front, raised oak lip along the customer side.
        m.add(Prim.roundedBox(V3(W, slabT, D), radius: 0.012, bevelSegments: detail ? 2 : 1, material: laminate), Xform(translation: V3(0, topY - slabT / 2, 0)))
        box(V3(W - 0.004, 0.012, 0.012), V3(0, topY - slabT + 0.006, D / 2 - 0.0), trim, r: 0.003)
        box(V3(W - 0.06, 0.03, 0.035), V3(0, topY + 0.015, D / 2 - 0.0275), trim, r: 0.009)
        // Cabinet carcass, kick plate and plinth shadow.
        let nx0: Float = 0.37, nx1: Float = W / 2 - 0.035
        flat(V3(nx0 + W / 2 - 0.03, topY - slabT - kick, zf - zb - 0.06), V3((nx0 - W / 2 + 0.03) / 2, kick + (topY - slabT - kick) / 2, 0), "plastic.matte:D9D6CD")
        flat(V3(0.02, topY - slabT - kick, zf - zb - 0.06), V3(W / 2 - 0.04, kick + (topY - slabT - kick) / 2, 0), "plastic.matte:D9D6CD")        // niche end wall
        flat(V3(0.02, topY - slabT - kick, zf - zb - 0.06), V3(nx0 + 0.01, kick + (topY - slabT - kick) / 2, 0), "plastic.matte:D9D6CD")         // niche side wall
        flat(V3(W - 0.07, kick, zf - zb - 0.05), V3(0, kick / 2, 0), "plastic.black:222224")
        box(V3(W - 0.06, kick - 0.004, 0.012), V3(0, (kick - 0.004) / 2, zf + 0.002), "metal.kickplate", r: 0.002)
        box(V3(W - 0.06, kick - 0.004, 0.012), V3(0, (kick - 0.004) / 2, zb - 0.002), "metal.kickplate", r: 0.002)
        for s: Float in [-1, 1] { box(V3(0.012, kick - 0.004, zf - zb - 0.03), V3(s * (W / 2 - 0.03), (kick - 0.004) / 2, 0), "metal.kickplate", r: 0.002) }

        // Customer side (+Z) fascia: three laminate panels, oak pilasters, an oak band and a base strip.
        let bodyH = topY - slabT - kick
        let panelT: Float = 0.018
        let pz = zf + panelT / 2 - 0.004
        for (x0, x1) in [(-W / 2 + 0.035, -0.26), (-0.24, 0.24), (0.26, W / 2 - 0.035)] as [(Float, Float)] {
            box(V3(x1 - x0, bodyH - 0.04, panelT), V3((x0 + x1) / 2, kick + 0.02 + (bodyH - 0.04) / 2, pz), laminate, r: 0.003)
        }
        for s: Float in [-1, 1] { box(V3(0.04, bodyH, 0.026), V3(s * (W / 2 - 0.02), kick + bodyH / 2, pz + 0.004), trim, r: 0.004) }
        for x in [Float(-0.25), 0.25] { box(V3(0.02, bodyH - 0.04, 0.024), V3(x, kick + 0.02 + (bodyH - 0.04) / 2, pz + 0.003), trim, r: 0.003) }
        box(V3(W - 0.04, 0.03, 0.024), V3(0, kick + 0.015, pz + 0.003), trim, r: 0.003)
        box(V3(W - 0.04, 0.026, 0.024), V3(0, kick + bodyH - 0.013 - 0.0, pz + 0.003), trim, r: 0.003)
        // Customer-side scuffs: a worn oak strip protecting the lower panel and a kicked laminate panel.
        box(V3(0.46, 0.05, 0.004), V3(-0.5, kick + 0.06, pz + 0.012), "metal.kickplate", r: 0.001)

        // Cashier side (-Z): closed left bay, drawer front, open bagging niche on the right.
        let bz = zb - panelT / 2 + 0.004
        box(V3(0.66, bodyH - 0.04, panelT), V3(-W / 2 + 0.035 + 0.33, kick + 0.02 + (bodyH - 0.04) / 2, bz), laminate, r: 0.003)
        box(V3(0.46, 0.14, panelT), V3(0.12, topY - slabT - 0.09, bz), steel, r: 0.003)                    // cash drawer front
        box(V3(0.46, bodyH - 0.04 - 0.16, panelT), V3(0.12, kick + 0.02 + (bodyH - 0.2) / 2, bz), laminate, r: 0.003)
        box(V3(0.02, 0.02, 0.006), V3(0.34, topY - slabT - 0.09, bz - 0.011), "metal.brass-aged", r: 0.004)  // drawer lock
        flat(V3(0.14, 0.003, 0.002), V3(0.12, topY - slabT - 0.066, bz - 0.0105), "plastic.black:121214")   // pull recess
        // Niche: oak frame, dark back panel, shelf with stacked paper bags and a bag roll.
        flat(V3(nx1 - nx0, 0.018, zf - zb - 0.06), V3((nx0 + nx1) / 2, 0.36, 0.0))
        flat(V3(nx1 - nx0, 0.018, zf - zb - 0.06), V3((nx0 + nx1) / 2, kick + 0.009, 0.0))
        box(V3(0.02, bodyH - 0.04, 0.024), V3(nx0 - 0.01, kick + 0.02 + (bodyH - 0.04) / 2, bz - 0.003), trim, r: 0.003)
        box(V3(nx1 - nx0 + 0.02, 0.02, 0.024), V3((nx0 + nx1) / 2, 0.36 - 0.008, bz - 0.003), trim, r: 0.003)
        for i in 0..<3 {
            let h: Float = 0.06 + rng.float(0...0.02)
            flat(V3(0.24 - 0.01 * Float(i), h, 0.16), V3(0.57 + rng.float(-0.01...0.01), 0.369 + 0.03 + Float(i) * 0.062, -0.12 + rng.float(-0.01...0.01)), "paper.sheet:B8946A")
            flat(V3(0.226 - 0.01 * Float(i), h - 0.012, 0.162), V3(0.57, 0.369 + 0.03 + Float(i) * 0.062, -0.12), "paper.sheet:C9A87C")
        }
        cylX(0.07, 0.2, V3(0.57, kick + 0.018 + 0.07, -0.12), "paper.sheet:C9A87C", seg: 18)
        cylX(0.02, 0.22, V3(0.57, kick + 0.018 + 0.07, -0.12), "metal.casework", seg: 8)

        // Conveyor belt on the left: stainless tray and rails, rubber belt with cleats, end rollers, divider bar.
        let bx0: Float = -W / 2 + 0.06, bx1: Float = -0.1, bcz: Float = 0.1, bw: Float = 0.38
        let bcx = (bx0 + bx1) / 2, bl = bx1 - bx0
        box(V3(bl, 0.03, bw), V3(bcx, topY + 0.015, bcz), steel, r: 0.004)
        for s: Float in [-1, 1] { box(V3(bl, 0.05, 0.018), V3(bcx, topY + 0.055, bcz + s * (bw / 2 - 0.009)), steel, r: 0.004) }
        flat(V3(bl - 0.04, 0.006, bw - 0.05), V3(bcx, topY + 0.033, bcz), "rubber")
        for i in 0..<(detail ? 14 : 7) {
            let x = bx0 + 0.04 + (bl - 0.08) * Float(i) / Float(detail ? 13 : 6)
            flat(V3(0.006, 0.0035, bw - 0.05), V3(x, topY + 0.0375, bcz), "plastic.black:101012")
        }
        for s: Float in [-1, 1] { cylZ(0.017, bw - 0.04, V3(bcx + s * (bl / 2 - 0.022), topY + 0.047, bcz), "metal.casework", seg: 14) }
        box(V3(0.016, 0.075, bw - 0.05), V3(bx1 - 0.18, topY + 0.07, bcz), "plastic.matte:E0A93A", r: 0.003)       // belt divider bar
        box(V3(0.08, 0.05, bw), V3(bx0 + 0.02, topY + 0.055, bcz), matte, r: 0.006)                                  // drive housing
        for s: Float in [-1, 1] { box(V3(0.012, 0.012, 0.012), V3(bx1 - 0.06, topY + 0.085, bcz + s * (bw / 2 - 0.009)), black, r: 0.002) }   // photo-eyes

        // POS terminal: round swivel base, neck, tablet facing the cashier (-Z).
        let px: Float = 0.12, pz2: Float = -0.1
        m.add(Prim.lathe([V2(0.0001, 0), V2(0.08, 0), V2(0.085, 0.004), V2(0.08, 0.012), V2(0.03, 0.016), V2(0.0001, 0.016)], segments: detail ? 28 : 12, seamTile: 0.1, material: matte), Xform(translation: V3(px, topY, pz2)))
        m.add(Prim.roundedBox(V3(0.05, 0.03, 0.03), radius: 0.008, bevelSegments: 1, material: matte), Xform(translation: V3(px, topY + 0.03, pz2)))
        let tilt = simd_quatf(degrees: 180, axis: .up) * simd_quatf(degrees: -14, axis: V3(1, 0, 0))
        let tc = V3(px, topY + 0.1, pz2 + 0.005)
        m.add(Prim.roundedBox(V3(0.25, 0.165, 0.014), radius: 0.006, bevelSegments: 2, material: matte), Xform(translation: tc, rotation: tilt))
        m.add(cuboid(V3(0.231, 0.147, 0.002), material: "screen.ui"), Xform(translation: tc + tilt.act(V3(0, 0, 0.0075)), rotation: tilt))
        // Cable out the back of the neck.
        let cable = catmull([V3(px, topY + 0.03, pz2 + 0.016), V3(px, topY + 0.012, pz2 + 0.06), V3(px + 0.02, topY + 0.002, pz2 + 0.1), V3(px + 0.1, topY + 0.002, pz2 + 0.14)], per: 4)
        m.add(Prim.tube(cable, radii: cable.map { _ in 0.0035 }, sides: 5, seamTile: 0.02, material: black))

        // Card reader on the customer side: tilted body, screen and keypad.
        let rx: Float = 0.12, rz: Float = 0.22
        let rq = simd_quatf(degrees: -28, axis: V3(1, 0, 0))
        box(V3(0.085, 0.022, 0.13), V3(rx, topY + 0.02, rz), black, r: 0.006, rot: rq)
                let rc = V3(rx, topY + 0.02, rz)
        m.add(cuboid(V3(0.056, 0.001, 0.03), material: "screen.ui"), Xform(translation: rc + rq.act(V3(0, 0.0115, -0.04)), rotation: rq))
        for ix in 0..<3 { for iy in 0..<4 {
            m.add(cuboid(V3(0.015, 0.002, 0.011), material: "plastic.matte:8E8E92"),
                  Xform(translation: rc + rq.act(V3(-0.021 + 0.021 * Float(ix), 0.012, -0.005 + 0.0135 * Float(iy))), rotation: rq))
        } }

        // Receipt printer and a barcode scanner on the cashier side right.
        let prx: Float = 0.36, prz: Float = -0.12
        box(V3(0.14, 0.12, 0.15), V3(prx, topY + 0.06, prz), black, r: 0.006)
        flat(V3(0.14, 0.004, 0.03), V3(prx, topY + 0.121, prz - 0.04), "plastic.matte:3A3A3E")
        flat(V3(0.08, 0.035, 0.0015), V3(prx, topY + 0.14, prz - 0.065), "paper.sheet:F2EFE4", rot: simd_quatf(degrees: -20, axis: V3(1, 0, 0)))
        flat(V3(0.006, 0.006, 0.006), V3(prx + 0.05, topY + 0.123, prz + 0.06), "emissive.led-green")
        let scx: Float = 0.55, scz: Float = -0.2
        m.add(Prim.lathe([V2(0.0001, 0), V2(0.05, 0), V2(0.05, 0.01), V2(0.034, 0.025), V2(0.0001, 0.025)], segments: detail ? 20 : 10, seamTile: 0.1, material: matte), Xform(translation: V3(scx, topY, scz)))
        let sq = simd_quatf(degrees: 22, axis: V3(1, 0, 0))
        box(V3(0.04, 0.032, 0.1), V3(scx, topY + 0.06, scz + 0.0), black, r: 0.012, rot: sq)
        box(V3(0.032, 0.085, 0.03), V3(scx, topY + 0.045, scz - 0.02), matte, r: 0.008, rot: simd_quatf(degrees: -12, axis: V3(1, 0, 0)))
        flat(V3(0.028, 0.002, 0.012), V3(scx, topY + 0.077, scz + 0.052) , "emissive.led-red", rot: sq)
        // Receipt spike with a few curled receipts on the counter edge, and a coin tray.
        box(V3(0.2, 0.012, 0.09), V3(0.47, topY + 0.006, 0.18), "plastic.matte:3A3A3E", r: 0.004)
        for i in 0..<4 { box(V3(0.03, 0.01, 0.03), V3(0.41 + 0.045 * Float(i), topY + 0.015, 0.18), "metal.casework", r: 0.003) }

        // Customer-side panel beads and a scuffed lower band.
        for (x0, x1) in [(-W / 2 + 0.035, -0.26), (-0.24, 0.24), (0.26, W / 2 - 0.035)] as [(Float, Float)] {
            let cx = (x0 + x1) / 2, pw = x1 - x0 - 0.1, ph = bodyH - 0.04 - 0.24, py = kick + 0.02 + 0.2 + ph / 2
            flat(V3(pw, 0.008, 0.004), V3(cx, py + ph / 2, pz + panelT / 2 + 0.002), trim)
            flat(V3(pw, 0.008, 0.004), V3(cx, py - ph / 2, pz + panelT / 2 + 0.002), trim)
            flat(V3(0.008, ph, 0.004), V3(cx - pw / 2, py, pz + panelT / 2 + 0.002), trim)
            flat(V3(0.008, ph, 0.004), V3(cx + pw / 2, py, pz + panelT / 2 + 0.002), trim)
            flat(V3(x1 - x0 - 0.01, 0.1, 0.0015), V3(cx, kick + 0.02 + 0.05, pz + panelT / 2 + 0.0008), "plastic.matte:C8C4B8")
            for _ in 0..<3 {
                flat(V3(rng.float(0.04...0.1), 0.004, 0.0012), V3(cx + rng.float(-0.12...0.12), kick + 0.02 + rng.float(0.01...0.09), pz + panelT / 2 + 0.0018), "plastic.black:55524C",
                     rot: simd_quatf(degrees: rng.float(-25...25), axis: V3(0, 0, 1)))
            }
        }
        // Cashier-side beads on the left bay and below the drawer, a cable grommet, and a price-sign stand.
        for (cx, pw, py, ph) in [(Float(-W / 2 + 0.035 + 0.33), Float(0.56), Float(kick + 0.02 + (bodyH - 0.04) / 2), Float(bodyH - 0.04 - 0.14)),
                                 (Float(0.12), Float(0.36), Float(kick + 0.02 + (bodyH - 0.2) / 2), Float(bodyH - 0.2 - 0.12))] {
            let zz = bz - panelT / 2 - 0.002
            flat(V3(pw, 0.008, 0.004), V3(cx, py + ph / 2, zz), trim)
            flat(V3(pw, 0.008, 0.004), V3(cx, py - ph / 2, zz), trim)
            flat(V3(0.008, ph, 0.004), V3(cx - pw / 2, py, zz), trim)
            flat(V3(0.008, ph, 0.004), V3(cx + pw / 2, py, zz), trim)
        }
        m.add(Prim.cylinder(radius: 0.03, height: 0.003, bevel: 0.001, segments: detail ? 20 : 10, bevelSegments: 1, material: black), Xform(translation: V3(0.24, topY, -0.2)))
        m.add(Prim.cylinder(radius: 0.022, height: 0.0035, bevel: 0.001, segments: detail ? 16 : 8, bevelSegments: 1, material: "metal.casework"), Xform(translation: V3(0.24, topY + 0.0004, -0.2)))
        box(V3(0.12, 0.004, 0.08), V3(-0.03, topY + 0.002, 0.29), "plastic.black:1C1C1E", r: 0.0015)
        box(V3(0.11, 0.075, 0.003), V3(-0.03, topY + 0.04, 0.29), "paper.sheet:F2EFE4", r: 0.001, rot: simd_quatf(degrees: -18, axis: V3(1, 0, 0)))

        // Goods on the belt: a red hand basket with items, three cans and a boxed item.
        let bkx = bx0 + 0.2, bkz = bcz
        let bkOuter = Prim.loft([Prim.ring(Shape2D.roundedRect(0.2, 0.15, radius: 0.02, segments: 2), y: 0), Prim.ring(Shape2D.roundedRect(0.27, 0.2, radius: 0.025, segments: 2), y: 0.09)],
                                capStart: true, capEnd: false, material: "plastic.gloss:B3342A")
        let bkInner = Prim.loft([Prim.ring(Shape2D.roundedRect(0.19, 0.14, radius: 0.015, segments: 2), y: 0.006), Prim.ring(Shape2D.roundedRect(0.256, 0.186, radius: 0.02, segments: 2), y: 0.09)],
                                capStart: false, capEnd: false, material: "plastic.gloss:B3342A").flipped()
        m.add(bkOuter, Xform(translation: V3(bkx, topY + 0.0405, bkz)))
        m.add(bkInner, Xform(translation: V3(bkx, topY + 0.0405, bkz)))
        let hpath = catmull([V3(-0.135, 0.09, 0), V3(-0.09, 0.115, 0), V3(0, 0.126, 0), V3(0.09, 0.115, 0), V3(0.135, 0.09, 0)], per: 5).map { $0 + V3(bkx, topY + 0.0405, bkz) }
        m.add(Prim.tube(hpath, radii: hpath.map { _ in 0.006 }, sides: 6, seamTile: 0.03, material: "plastic.matte:1C1C1E"))
        m.add(Prim.superellipsoid(V3(0.14, 0.06, 0.11), exponent: 3, subdivisions: 2, material: "fabric.upholstery:3F5B7A"), Xform(translation: V3(bkx - 0.03, topY + 0.0405 + 0.05, bkz), rotation: simd_quatf(degrees: 8, axis: .up)))
        m.add(Prim.superellipsoid(V3(0.1, 0.045, 0.09), exponent: 3, subdivisions: 2, material: "fabric.upholstery:C9B79A"), Xform(translation: V3(bkx + 0.05, topY + 0.0405 + 0.058, bkz + 0.01), rotation: simd_quatf(degrees: -12, axis: .up)))
        for (i, c) in ["paper.sheet:B33A2E", "paper.sheet:2F6B3F", "paper.sheet:C9A13A"].enumerated() {
            let cx = bx0 + 0.45 + 0.06 * Float(i), cz = bcz + (i == 1 ? 0.05 : -0.04)
            m.add(Prim.cylinder(radius: 0.033, height: 0.11, bevel: 0.003, segments: detail ? 14 : 8, bevelSegments: 1, material: "metal.aluminum-brushed"), Xform(translation: V3(cx, topY + 0.0405, cz)))
            m.add(Prim.cylinder(radius: 0.0335, height: 0.07, bevel: 0.0005, segments: detail ? 14 : 8, bevelSegments: 1, material: c), Xform(translation: V3(cx, topY + 0.0405 + 0.02, cz)))
        }
        // Tip jar and a pen cup on the cashier side.
        m.add(Prim.lathe([V2(0.0001, 0), V2(0.045, 0), V2(0.048, 0.004), V2(0.048, 0.13), V2(0.04, 0.14), V2(0.04, 0.15), V2(0.036, 0.15), V2(0.036, 0.14), V2(0.0001, 0.14)].prefix(7).map { $0 } + [V2(0.0001, 0.13)], segments: detail ? 20 : 10, seamTile: 0.1, material: "glass.clear"),
              Xform(translation: V3(-0.02, topY, -0.2)))
        for i in 0..<5 {
            m.add(Prim.cylinder(radius: 0.012, height: 0.0025, bevel: 0.0004, segments: 8, bevelSegments: 1, material: i % 2 == 0 ? "metal.brass-aged" : "metal.casework"),
                  Xform(translation: V3(-0.02 + rng.float(-0.02...0.02), topY + 0.005 + 0.003 * Float(i), -0.2 + rng.float(-0.02...0.02))))
        }

        // Authoring frame: centered on X/Z, base at y = 0.
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)))
        groundAO(&m, height: 0.15, floor: 0.55)
        return m
    }
}
