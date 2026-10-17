import simd
import Foundation

/// Nursery changing table, 90 x 100 x 55 cm: painted case with solid shaker side panels, oak tapered legs, two open shelves
/// holding woven baskets and folded blankets, a top deck with a solid back rail and slatted side rails (open at the
/// front), and a contoured vinyl pad with quilted stitching and a buckled safety strap.
public struct ChangingTable: RealAsset {
    public static let id = "changing-table"
    public static let summary = "Changing table, 0.9 x 1.0 x 0.55 m: rail-guarded top with contoured pad and strap, two shelves with baskets, oak legs."
    public static let tags = ["prop", "floorplan", "bedroom", "furniture", "wood", "interior"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 12, distance: 0.95, studio: true)

    /// Overall size in meters (x width, y height to the rail tops, z depth); the open front faces +Z, the solid back goes to the wall.
    public var size = V3(0.9, 1.0, 0.55)
    /// Case, rails and shelves paint.
    public var paint: MaterialKey = "wood.painted-shaker:F1EEE6"
    /// Legs.
    public var legWood: MaterialKey = "wood.oak"
    /// Pad cover.
    public var padCover: MaterialKey = "padding.vinyl:EFEBE0"
    /// Basket weave.
    public var basket: MaterialKey = "wicker.willow"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [4])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, D = size.z
        let deckTop: Float = 0.89, deckT: Float = 0.03
        let railTop = size.y - 0.01
        let legX = W / 2 - 0.03, legZ = D / 2 - 0.03, legW: Float = 0.052
        let worn: MaterialKey = "wood.painted-shaker-worn:F1EEE6"

        func box(_ s: V3, _ p: V3, _ mat: MaterialKey? = nil, r: Float = 0.002) {
            m.add(Prim.roundedBox(s, radius: min(r, s.x / 2.2, s.y / 2.2, s.z / 2.2), bevelSegments: 1, material: mat ?? paint), Xform(translation: p))
        }
        func flat(_ s: V3, _ p: V3, _ mat: MaterialKey? = nil) { m.add(cuboid(s, material: mat ?? paint), Xform(translation: p)) }

        // Legs: oak, tapered, the top section hidden in the corners.
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            m.add(BedroomKit.taperedLeg(height: deckTop - deckT, top: legW, bottom: 0.034, radius: 0.004, material: legWood), Xform(translation: V3(sx * legX, 0, sz * legZ)))
        } }

        // Deck with a rounded overhang, apron, back panel and solid sides with raised shaker frames.
        m.add(Prim.roundedBox(V3(W, deckT, D), radius: 0.01, bevelSegments: detail ? 3 : 1, material: paint), Xform(translation: V3(0, deckTop - deckT / 2, 0)))
        let apronY: Float = deckTop - deckT - 0.04
        flat(V3(2 * legX - legW, 0.08, 0.018), V3(0, apronY, legZ))
        flat(V3(2 * legX - legW, 0.64, 0.016), V3(0, 0.17 + 0.32, -legZ + 0.001), worn)
        flat(V3(2 * legX - legW, 0.08, 0.018), V3(0, apronY, -legZ))
        for s: Float in [-1, 1] {
            let x = s * legX
            flat(V3(0.018, 0.66, 2 * legZ - legW), V3(x, 0.17 + 0.33, 0))
            // Raised frame on the outer face.
            let ox = x + s * 0.0125, zs = 2 * legZ - legW - 0.08, hs: Float = 0.5, yc: Float = 0.17 + 0.33
            box(V3(0.007, hs, 0.025), V3(ox, yc, -zs / 2 + 0.0125), r: 0.0015)
            box(V3(0.007, hs, 0.025), V3(ox, yc, zs / 2 - 0.0125), r: 0.0015)
            box(V3(0.007, 0.025, zs - 0.05), V3(ox, yc + hs / 2 - 0.0125, 0), r: 0.0015)
            box(V3(0.007, 0.025, zs - 0.05), V3(ox, yc - hs / 2 + 0.0125, 0), r: 0.0015)
        }

        // Two open shelves with a routed nosing.
        let shelfYs: [Float] = [0.6, 0.31]
        for y in shelfYs {
            flat(V3(2 * legX - legW, 0.02, 2 * legZ - legW - 0.02), V3(0, y - 0.01, -0.01))
            box(V3(2 * legX - legW, 0.03, 0.014), V3(0, y - 0.012, legZ - legW / 2 + 0.002), worn, r: 0.003)
        }

        // Baskets: tapered willow with a rolled rim and cut handles, loft outer and inner skins.
        func basketAt(_ c: V3, w: Float, d: Float, h: Float) {
            let rBottom = Shape2D.roundedRect(w * 0.88, d * 0.88, radius: 0.02, segments: 2)
            let rTop = Shape2D.roundedRect(w, d, radius: 0.028, segments: 2)
            let outer = Prim.loft([Prim.ring(rBottom, y: 0), Prim.ring(Shape2D.roundedRect(w * 0.95, d * 0.95, radius: 0.025, segments: 2), y: h * 0.5), Prim.ring(rTop, y: h)],
                                  capStart: true, capEnd: false, material: basket)
            let inW = w - 0.024, inD = d - 0.024
            let inner = Prim.loft([Prim.ring(Shape2D.roundedRect(inW * 0.88, inD * 0.88, radius: 0.012, segments: 2), y: 0.012),
                                   Prim.ring(Shape2D.roundedRect(inW, inD, radius: 0.02, segments: 2), y: h)], capStart: false, capEnd: false, material: basket).flipped()
            m.add(outer, Xform(translation: c))
            m.add(inner, Xform(translation: c))
            let rim = Shape2D.roundedRect(w - 0.006, d - 0.006, radius: 0.026, segments: 3).map { V3($0.x, h, $0.y) + c }
            m.add(Prim.sweep(Shape2D.circle(0.0075, segments: 6), along: rim, closedPath: true, caps: false, grainAlongPath: true, material: basket))
            // Handle cut-outs: dark slots on the front and back faces.
            for sz: Float in [-1, 1] {
                m.add(Prim.roundedBox(V3(0.1, 0.03, 0.004), radius: 0.008, bevelSegments: 1, material: "plastic.black:211E1B"),
                      Xform(translation: c + V3(0, h * 0.78, sz * (d / 2 * 0.95 + 0.001))))
            }
        }
        basketAt(V3(-0.2, shelfYs[0], 0.0), w: 0.36, d: 0.34, h: 0.2)
        basketAt(V3(0.2, shelfYs[0], 0.0), w: 0.36, d: 0.34, h: 0.2)
        basketAt(V3(-0.2, shelfYs[1], 0.0), w: 0.36, d: 0.34, h: 0.2)
        // Folded blankets on the lower right.
        let blankets: [MaterialKey] = ["fabric.upholstery:C7D3D6", "fabric.upholstery:EDE6D6", "fabric.upholstery:D9B7A8"]
        for (i, c) in blankets.enumerated() {
            m.add(Prim.superellipsoid(V3(0.34 - 0.01 * Float(i), 0.05, 0.3), exponent: 3.5, subdivisions: detail ? 3 : 2, material: c),
                  Xform(translation: V3(0.2 + rng.float(-0.01...0.01), shelfYs[1] + 0.025 + Float(i) * 0.048, 0.0), rotation: simd_quatf(degrees: rng.float(-3...3), axis: .up)))
        }

        // Guard rails: solid back with a raised panel and cap, slatted sides, front posts with turned caps.
        let railZ0 = -D / 2 + 0.015
        flat(V3(W - 0.02, railTop - deckTop, 0.03), V3(0, (railTop + deckTop) / 2, railZ0))
        box(V3(W, 0.03, 0.036), V3(0, railTop - 0.015, railZ0), r: 0.008)
        box(V3(W - 0.14, railTop - deckTop - 0.07, 0.008), V3(0, deckTop + 0.015 + (railTop - deckTop - 0.07) / 2 + 0.01, railZ0 + 0.018), r: 0.002)
        for s: Float in [-1, 1] {
            let x = s * (W / 2 - 0.0175)
            let zA = railZ0 + 0.02, zB = D / 2 - 0.02
            box(V3(0.035, 0.026, zB - zA + 0.04), V3(x, railTop - 0.013, (zA + zB) / 2), r: 0.007)
            box(V3(0.035, 0.026, zB - zA + 0.04), V3(x, deckTop + 0.02, (zA + zB) / 2), r: 0.005)
            let n = 9
            for i in 0..<n {
                let z = zA + 0.04 + (zB - zA - 0.08) * Float(i) / Float(n - 1)
                flat(V3(0.016, railTop - deckTop - 0.06, 0.016), V3(x, (railTop + deckTop) / 2 - 0.0, z), paint)
            }
            // Front post.
            box(V3(0.035, railTop - deckTop, 0.035), V3(x, (railTop + deckTop) / 2, D / 2 - 0.0175), r: 0.005)
            m.add(Prim.superellipsoid(V3(0.04, 0.024, 0.04), exponent: 2.2, subdivisions: 2, material: paint), Xform(translation: V3(x, railTop + 0.008, D / 2 - 0.0175)))
        }

        // Contoured pad: dished center, raised side bolsters, vinyl cover.
        let pw: Float = 0.82, pd: Float = 0.46, ph: Float = 0.07
        let padC = V3(0, deckTop + ph / 2 + 0.0005, -0.01)
        func dish(_ x: Float, _ z: Float) -> Float { 0.03 * exp(-((x / 0.3) * (x / 0.3) + (z / 0.15) * (z / 0.15))) }
        var pad = Prim.superellipsoid(V3(pw, ph, pd), exponent: 5, subdivisions: detail ? 4 : 3, material: padCover)
        pad.deform { p in
            var q = p
            if q.y > 0 { q.y -= dish(q.x, q.z) * (q.y / (ph / 2)) }
            return q
        }
        m.add(pad, Xform(translation: padC))
        func padTop(_ x: Float, _ z: Float) -> Float {
            let nx = abs(x) / (pw / 2), nz = abs(z) / (pd / 2)
            return padC.y + ph / 2 * pow(max(0.0001, 1 - pow(nx, 5) - pow(nz, 5)), 0.2) - dish(x, z)
        }
        if detail {
            // Quilting rectangle stitched on the pad.
            var qp: [V3] = []
            let qx: Float = 0.33, qz: Float = 0.17
            let corners: [(Float, Float)] = [(-qx, -qz), (qx, -qz), (qx, qz), (-qx, qz), (-qx, -qz)]
            for i in 0..<4 {
                let a = corners[i], b = corners[i + 1]
                for k in 0..<20 { let t = Float(k) / 20; let x = a.0 + (b.0 - a.0) * t, z = a.1 + (b.1 - a.1) * t; qp.append(V3(x, padTop(x, z - 0.01) + 0.0006, z - 0.01)) }
            }
            qp.append(qp[0])
            m.add(stitches(along: qp, normal: { _ in V3(0, 1, 0) }, pitch: 0.012, thread: 0.0007, material: "thread.white"))
        }
        // Safety strap across the pad with a buckle at the center.
        let sz: Float = 0.05 - 0.01
        var strap: [V3] = []
        for i in 0...14 {
            let x = -0.4 + 0.8 * Float(i) / 14
            strap.append(V3(x, padTop(x, sz) + 0.0035, sz))
        }
        m.add(Prim.sweep(Shape2D.roundedRect(0.034, 0.005, radius: 0.0015, segments: 1), along: catmull(strap, per: 3), up: V3(0, 0, 1), caps: true, material: "fabric.webbing:3E4A5C"))
        let by = padTop(0, sz)
        m.add(Prim.roundedBox(V3(0.06, 0.012, 0.045), radius: 0.004, bevelSegments: 1, material: "plastic.matte:2A2A2C"), Xform(translation: V3(0, by + 0.0085, sz)))
        m.add(Prim.roundedBox(V3(0.026, 0.004, 0.028), radius: 0.002, bevelSegments: 1, material: "plastic.matte:B9B3A6"), Xform(translation: V3(0, by + 0.0155, sz)))

        // Authoring frame: centered on X/Z, base at y = 0.
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)))
        groundAO(&m, height: 0.2, floor: 0.55)
        return m
    }
}
