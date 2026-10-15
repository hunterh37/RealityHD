import simd
import Foundation

/// Built-in bookcase, 120 x 240 x 35 cm, painted off-white to sit against a wall: face frame with a stepped crown and base
/// moulding, a two-door shaker cabinet with brass knobs, a counter deck, four shelf rows split by a center divider with
/// nosed shelf edges, filled with cloth-bound books of varied height and color, a vase, a framed photo, a keepsake box
/// and a candlestick.
public struct BuiltInBookcase: RealAsset {
    public static let id = "built-in-bookcase"
    public static let summary = "Built-in bookcase, 1.2 x 2.4 x 0.35 m: painted face frame, crown and base trim, shaker lower doors, filled shelves."
    public static let tags = ["prop", "floorplan", "living", "furniture", "wood", "book", "wall", "interior"]
    public static let budget = 14500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 8, distance: 0.95, studio: true)

    /// Overall size in meters (x width, y height, z depth); the open side faces +Z and the back stands on the wall at -Z.
    public var size = V3(1.2, 2.4, 0.35)
    /// Painted case, face frame and doors.
    public var paint: MaterialKey = "wood.painted-shaker:E9E5DB"
    /// Door and knob hardware.
    public var hardware: MaterialKey = "metal.brass"
    /// Books on the shelves per opening (0 = empty).
    public var bookDensity: Float = 1
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [5])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y, D = size.z
        let z0 = -D / 2                      // wall plane
        let zf: Float = 0.115                // carcass front plane
        let plinth: Float = 0.12
        let crownH: Float = 0.12
        let topBoardY: Float = H - crownH - 0.03       // underside of top board
        let sideT: Float = 0.02
        let paintWorn: MaterialKey = "wood.painted-shaker-worn:E9E5DB"
        let backPaint: MaterialKey = "wood.painted-shaker:CFCABC"      // back panel painted a shade darker than the frame

        func box(_ s: V3, _ p: V3, _ mat: MaterialKey? = nil, r: Float = 0.002) {
            m.add(Prim.roundedBox(s, radius: min(r, s.x / 2.2, s.y / 2.2, s.z / 2.2), bevelSegments: 1, material: mat ?? paint), Xform(translation: p))
        }
        func flat(_ s: V3, _ p: V3, _ mat: MaterialKey? = nil, rot: simd_quatf = .identity) {
            m.add(cuboid(s, material: mat ?? paint), Xform(translation: p, rotation: rot))
        }

        // Carcass: sides, back, deck, shelves, divider, top board.
        let deckTop: Float = 0.91
        let shelfTops: [Float] = [deckTop, 1.27, 1.61, 1.93]
        let shelfT: Float = 0.022
        let iw0 = W - 2 * sideT
        for s: Float in [-1, 1] {
            flat(V3(sideT, H - crownH, zf - z0), V3(s * (W / 2 - sideT / 2), (H - crownH) / 2, (zf + z0) / 2))
        }
        flat(V3(iw0, H - crownH - plinth, 0.012), V3(0, plinth + (H - crownH - plinth) / 2, z0 + 0.006), backPaint)
        flat(V3(iw0, 0.03, zf - z0 - 0.012), V3(0, deckTop - 0.015, (zf + z0) / 2 + 0.006))              // counter deck
        flat(V3(iw0, 0.03, zf - z0 - 0.012), V3(0, topBoardY + 0.015, (zf + z0) / 2 + 0.006))            // top board
        flat(V3(iw0, 0.05, zf - z0 - 0.012), V3(0, plinth + 0.025, (zf + z0) / 2 + 0.006), paintWorn)     // cabinet floor
        for st in shelfTops.dropFirst() {
            flat(V3(iw0, shelfT, zf - z0 - 0.012), V3(0, st - shelfT / 2, (zf + z0) / 2 + 0.006))
        }
        flat(V3(0.02, topBoardY - deckTop - 0.03, zf - z0 - 0.012), V3(0, (topBoardY + deckTop - 0.03) / 2 + 0.0, (zf + z0) / 2 + 0.006))

        // Face frame: stiles, top rail, shelf-edge nosings, counter rail, lower rail, center stile.
        let faceT: Float = 0.02
        let fz = zf + faceT / 2
        let stile: Float = 0.06
        for s: Float in [-1, 1] {
            box(V3(stile, H - crownH - plinth, faceT), V3(s * (W / 2 - stile / 2), plinth + (H - crownH - plinth) / 2, fz), r: 0.003)
        }
        box(V3(W - 2 * stile + 0.004, 0.06, faceT), V3(0, topBoardY + 0.03 - 0.0, fz), r: 0.003)                       // top rail
        box(V3(W - 2 * stile + 0.004, 0.05, faceT), V3(0, deckTop - 0.025, fz), r: 0.003)                                      // counter rail
        box(V3(W - 2 * stile + 0.004, 0.05, faceT), V3(0, plinth + 0.025, fz), r: 0.003)                                       // lower rail
        box(V3(0.05, deckTop - plinth - 0.1, faceT), V3(0, plinth + 0.05 + (deckTop - plinth - 0.1) / 2, fz), r: 0.003)        // door center stile
        box(V3(0.03, topBoardY - deckTop - 0.03, faceT), V3(0, (topBoardY + deckTop - 0.03) / 2 + 0.0, fz), r: 0.003)         // divider face
        for st in shelfTops.dropFirst() {
            box(V3(W - 2 * stile + 0.004, 0.032, 0.014), V3(0, st - 0.016, zf + 0.007), r: 0.0025)                             // nosing
        }
        // Rounded counter nosing across the front of the deck.
        m.add(Prim.roundedBox(V3(W - 0.04, 0.032, 0.036), radius: 0.012, bevelSegments: detail ? 3 : 1, material: paint), Xform(translation: V3(0, deckTop - 0.0, zf + 0.012 + faceT)))

        // Base: recessed toe kick under a two-step base moulding.
        flat(V3(iw0, plinth - 0.05, zf - z0 - 0.05), V3(0, (plinth - 0.05) / 2, (zf + z0) / 2 - 0.0), paintWorn)
        box(V3(W - 0.004, 0.034, zf - z0 + 0.016), V3(0, plinth - 0.05 + 0.017, (zf + z0) / 2 + 0.008), paintWorn, r: 0.003)
        box(V3(W, 0.016, zf - z0 + 0.03), V3(0, plinth - 0.016 + 0.008, (zf + z0) / 2 + 0.015), paintWorn, r: 0.003)

        // Crown: stepped moulding above the top rail, projecting to the full depth.
        let cy = H - crownH
        box(V3(W - 0.03, 0.03, D - 0.1), V3(0, cy + 0.015, z0 + (D - 0.1) / 2), r: 0.003)
        box(V3(W - 0.012, 0.05, D - 0.05), V3(0, cy + 0.055, z0 + (D - 0.05) / 2), r: 0.005)
        box(V3(W, 0.04, D), V3(0, cy + 0.1, z0 + D / 2), r: 0.006)

        // Lower shaker doors with brass knobs.
        let doorBot = plinth + 0.04, doorTop = deckTop - 0.04
        let dw: Float = 0.55, dh = doorTop - doorBot, dt: Float = 0.02
        let dz = zf + faceT + dt / 2 - 0.0
        let st2: Float = 0.065
        for s: Float in [-1, 1] {
            let cx = s * (0.0125 + dw / 2)
            let cyd = (doorBot + doorTop) / 2
            for sx: Float in [-1, 1] { box(V3(st2, dh, dt), V3(cx + sx * (dw / 2 - st2 / 2), cyd, dz), r: 0.003) }
            for sy: Float in [-1, 1] { box(V3(dw - 2 * st2 + 0.004, st2, dt), V3(cx, cyd + sy * (dh / 2 - st2 / 2), dz), r: 0.003) }
            flat(V3(dw - 2 * st2 + 0.006, dh - 2 * st2 + 0.006, 0.008), V3(cx, cyd, dz - 0.0045), paintWorn)
            // Bead lip around the recessed panel.
            let iw = dw - 2 * st2, ih = dh - 2 * st2
            for sx: Float in [-1, 1] { flat(V3(0.006, ih, 0.006), V3(cx + sx * (iw / 2 - 0.003), cyd, dz + dt / 2 - 0.003 + 0.0)) }
            for sy: Float in [-1, 1] { flat(V3(iw - 0.012, 0.006, 0.006), V3(cx, cyd + sy * (ih / 2 - 0.003), dz + dt / 2 - 0.003 + 0.0)) }
            m.add(CaseworkKit.knob(radius: 0.015, material: hardware), Xform(translation: V3(s * (0.0125 + 0.032), doorTop - 0.04, zf + faceT + dt)))
        }

        // Books and objects.
        let palette: [MaterialKey] = ["book.cloth:6E2B2B", "book.cloth:2E4A63", "book.cloth:3F5B43", "book.cloth:B59A62", "book.cloth:D8CFB8", "book.cloth:2B2B2E",
                                      "book.cloth:7B5A3C", "book.cloth:8A3F3A", "book.cloth:4C6A78", "book.cloth:C9BFA6", "book.cloth:5A4B63", "book.cloth:A6784B", "book.cloth:E1DCCB"]
        let bookZ = zf - 0.025
        func book(x: Float, y: Float, w: Float, h: Float, d: Float, lean: Float = 0, mat: MaterialKey) {
            let q = simd_quatf(degrees: lean, axis: V3(0, 0, 1))
            let c = V3(x, y + h / 2, bookZ - d / 2)
            m.add(cuboid(V3(w, h, d), material: mat), Xform(translation: c, rotation: q))
            m.add(cuboid(V3(w - 0.004, 0.002, d - 0.012), material: "paper.pages"), Xform(translation: c + q.act(V3(0, h / 2 + 0.0005, 0.0)), rotation: q))
            if detail && rng.chance(0.55) {
                m.add(cuboid(V3(w * 0.8, 0.008 + rng.float(0...0.008), 0.0008), material: rng.chance(0.5) ? "paper.sheet:C9AE6E" : "paper.sheet:D8D0B8"),
                      Xform(translation: c + q.act(V3(0, h * rng.float(0.15...0.38), d / 2)), rotation: q))
            }
        }
        func row(x0: Float, x1: Float, y: Float, maxH: Float, fill: Float, tall: Bool = true) {
            var x = x0
            var i = Int(rng.int(0...12))
            while x < x1 - 0.02 {
                let w = rng.float(0.018...0.048), h = min(maxH, rng.float(0.17...0.30) * (tall ? 1 : 0.85)), d = rng.float(0.15...0.205)
                if x + w > x1 { break }
                if (x - x0) / (x1 - x0) > fill { break }
                if rng.chance(0.06) { x += rng.float(0.01...0.03); continue }
                book(x: x + w / 2, y: y, w: w, h: h, d: d, mat: palette[i % palette.count])
                x += w + 0.0006; i += Int(rng.int(1...5))
            }
            // Last book leans on the end of the row.
            if x < x1 - 0.05 {
                let h = min(maxH, 0.25)
                book(x: x + 0.03, y: y, w: 0.032, h: h, d: 0.18, lean: 12, mat: palette[i % palette.count])
            }
        }
        func stack(x: Float, y: Float, n: Int, wide: Float) {
            var yy = y
            for k in 0..<n {
                let h = rng.float(0.028...0.05), w = wide - rng.float(0...0.07), d = rng.float(0.17...0.21)
                m.add(cuboid(V3(w, h, d), material: palette[(k * 3 + 4) % palette.count]), Xform(translation: V3(x + rng.float(-0.01...0.01), yy + h / 2, bookZ - d / 2), rotation: simd_quatf(degrees: rng.float(-3...3), axis: .up)))
                yy += h
            }
        }
        func lathe(_ prof: [V2], _ mat: MaterialKey, at p: V3, seg: Int = 14) {
            m.add(Prim.lathe(prof, segments: detail ? seg : seg / 2, seamTile: 0.1, material: mat), Xform(translation: p))
        }

        let bays: [(Float, Float)] = [(-W / 2 + 0.05, -0.012), (0.012, W / 2 - 0.05)]
        let rowCeil: [Float] = [1.27 - shelfT, 1.61 - shelfT, 1.93 - shelfT, topBoardY]
        for (ri, ceil) in rowCeil.enumerated() {
            let base = shelfTops[ri]
            let openH = ceil - base
            for (bi, b) in bays.enumerated() {
                let key = ri * 2 + bi
                let fill: Float = bookDensity <= 0 ? 0 : [0.62, 0.8, 0.95, 0.7, 1.0, 0.55, 0.9, 0.78][key]
                switch key {
                case 0:      // lower left: books then a vase
                    row(x0: b.0, x1: b.1 - 0.17, y: base, maxH: openH - 0.04, fill: 0.95)
                    lathe([V2(0.0001, 0), V2(0.05, 0), V2(0.078, 0.07), V2(0.086, 0.12), V2(0.066, 0.18), V2(0.03, 0.23), V2(0.032, 0.27), V2(0.045, 0.285), V2(0.04, 0.287), V2(0.0001, 0.287)], "ceramic.celadon", at: V3(b.1 - 0.09, base, zf - 0.11))
                case 1:      // framed photo leaning on a stack of books
                    stack(x: b.0 + 0.15, y: base, n: 4, wide: 0.27)
                    row(x0: b.0 + 0.32, x1: b.1, y: base, maxH: openH - 0.04, fill: 0.9)
                    let fy = base + 0.14
                    m.add(Prim.roundedBox(V3(0.17, 0.21, 0.014), radius: 0.003, bevelSegments: 1, material: "wood.walnut"), Xform(translation: V3(b.0 + 0.15, fy + 0.105 + 0.0, bookZ - 0.1), rotation: simd_quatf(degrees: -7, axis: V3(1, 0, 0))))
                    m.add(cuboid(V3(0.135, 0.175, 0.002), material: "paper.sheet:C9BFA6"), Xform(translation: V3(b.0 + 0.15, fy + 0.105, bookZ - 0.0925), rotation: simd_quatf(degrees: -7, axis: V3(1, 0, 0))))
                case 2:      // keepsake box and books
                    box(V3(0.22, 0.11, 0.15), V3(b.0 + 0.12, base + 0.055, bookZ - 0.1), "wood.walnut", r: 0.004)
                    box(V3(0.03, 0.02, 0.006), V3(b.0 + 0.12, base + 0.095, bookZ - 0.0215), hardware, r: 0.002)
                    row(x0: b.0 + 0.26, x1: b.1, y: base, maxH: openH - 0.03, fill: 0.95)
                case 3:      // books with a brass candlestick
                    row(x0: b.0, x1: b.1 - 0.12, y: base, maxH: openH - 0.04, fill: fill)
                    lathe([V2(0.0001, 0), V2(0.04, 0), V2(0.04, 0.008), V2(0.012, 0.02), V2(0.01, 0.1), V2(0.017, 0.12), V2(0.012, 0.13), V2(0.012, 0.16), V2(0.018, 0.17), V2(0.0001, 0.17)], hardware, at: V3(b.1 - 0.07, base, zf - 0.1), seg: 10)
                    lathe([V2(0.009, 0.17), V2(0.009, 0.24), V2(0.0001, 0.245)], "paper.sheet", at: V3(b.1 - 0.07, base, zf - 0.1), seg: 8)
                default:
                    row(x0: b.0, x1: b.1, y: base, maxH: openH - 0.04, fill: fill, tall: ri < 2)
                    if key == 5 { stack(x: b.1 - 0.12, y: base, n: 3, wide: 0.22) }
                }
            }
        }

        // Authoring frame: centered on X/Z, base at y = 0.
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)))
        groundAO(&m, height: 0.25, floor: 0.5)
        return m
    }
}
