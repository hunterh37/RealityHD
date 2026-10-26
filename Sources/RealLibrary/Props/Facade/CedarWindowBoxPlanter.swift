import simd
import Foundation

/// Alpine Chalet cedar window box, 1.0 m wide: tongue-and-groove cedar boards with five heart cut-outs
/// across the front, chamfered corner posts with pyramid caps, slatted bottom with drain gaps, two iron
/// brackets with wall bolts, soil and trailing geraniums. One end board is a fresh replacement and one
/// screw has rusted. Wall plane at z = 0.
public struct CedarWindowBoxPlanter: RealAsset {
    public static let id = "cedar-window-box-planter"
    public static let summary = "Alpine Chalet cedar window box, 1.0 m: tongue-and-groove cedar planks with heart-cut front fretwork, iron brackets, screw heads, soil and trailing geraniums."
    public static let tags = ["prop", "architecture", "facade", "wood"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 14, distance: 0.8)

    /// Weathered cedar boards.
    public var cedar: MaterialKey = "wood.cedar-weathered"
    /// Fresh cedar for the replacement board.
    public var fresh: MaterialKey = "wood.cedar"
    /// Bracket iron.
    public var iron: MaterialKey = "metal.iron"
    /// Geranium bloom tint.
    public var bloom: MaterialKey = "flower.petal:D4283C"
    public init() {}

    /// Heart outline (unit curve scaled so the width is 32 units), closed, no repeated points.
    static func heart(_ s: Float) -> [V2] {
        (0..<48).map { i in
            let t = Float(i) / 48 * 2 * .pi
            return V2(16 * pow(sin(t), 3) * s, (13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t)) * s)
        }
    }
    /// Sorted x crossings of the polygon with the horizontal line at y.
    static func crossings(_ poly: [V2], y: Float) -> [Float] {
        var xs: [Float] = []
        for i in poly.indices {
            let a = poly[i], b = poly[(i + 1) % poly.count]
            if (a.y <= y && b.y > y) || (b.y <= y && a.y > y) {
                xs.append(a.x + (y - a.y) / (b.y - a.y) * (b.x - a.x))
            }
        }
        return xs.sorted()
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L: Float = 1.0, hw = L / 2, y0: Float = 0.03, y1: Float = 0.19, zb: Float = 0.03, zf: Float = 0.27, t: Float = 0.018
        let hy0: Float = 0.075, hy1: Float = 0.165
        // Front: bottom rail, top rail and the board band cut into slices around five heart openings.
        FA.box(&m, V3(L, hy0 - y0, t), V3(0, (y0 + hy0) / 2, zf - t / 2), cedar, r: 0.002)
        FA.box(&m, V3(L, y1 - hy1, t), V3(0, (hy1 + y1) / 2, zf - t / 2), cedar, r: 0.002)
        let sc: Float = (hy1 - hy0 - 0.004) / 29
        let heartPoly = Self.heart(sc)
        let hb = heartPoly.map { $0.y }.min()!, ht = heartPoly.map { $0.y }.max()!
        let centers: [Float] = [-0.4, -0.2, 0, 0.2, 0.4]
        let cleft = 5 * sc
        let ys: [Float] = {
            var r: [Float] = []
            let lo = hy0 + 0.002, hi = hy1 - 0.002
            let base = lo - hb   // shift so the tip sits just above the lower rail
            _ = base
            let mid = lo + (cleft - hb)
            for k in 0...5 { r.append(lo + (mid - lo) * Float(k) / 5) }
            for k in 1...4 { r.append(mid + (hi - mid) * Float(k) / 4) }
            return r
        }()
        let shift = (hy0 + 0.002) - hb
        func row(_ ya: Float, _ yb: Float) {
            let ea = ya + 0.0006, eb = yb - 0.0006
            func xsAt(_ y: Float) -> [[Float]] {
                centers.map { c in Self.crossings(heartPoly.map { V2($0.x + c, $0.y + shift) }, y: y) }
            }
            let A = xsAt(ea).flatMap { $0 }, B = xsAt(eb).flatMap { $0 }
            guard A.count == B.count, A.count >= 2 else { return }
            var la: [Float] = [-hw], lb: [Float] = [-hw]
            var ra: [Float] = [], rb: [Float] = []
            // Pieces lie between hole intervals: hole k is (A[2k], A[2k+1]).
            for k in 0..<(A.count / 2) { ra.append(A[2 * k]); rb.append(B[2 * k]); la.append(A[2 * k + 1]); lb.append(B[2 * k + 1]) }
            ra.append(hw); rb.append(hw)
            for k in 0..<la.count {
                let p = [V2(la[k], ya), V2(ra[k], ya), V2(rb[k], yb), V2(lb[k], yb)]
                if ra[k] - la[k] < 0.0015 && rb[k] - lb[k] < 0.0015 { continue }
                FM.prism(&m, Shape2D.deduped(p), front: zf, depth: t, cedar, bevel: 0.0011)
            }
        }
        for k in 0..<(ys.count - 1) { row(ys[k], ys[k + 1]) }
        // Rounded rim lining each heart opening, centred on the cut edge.
        for c in centers {
            var ring = stride(from: 0, to: heartPoly.count, by: 2).map { V3(heartPoly[$0].x + c, heartPoly[$0].y + shift, zf - t / 2) }
            ring.append(ring[0])
            m.add(Prim.tube(ring, radii: Array(repeating: 0.0097, count: ring.count), sides: 6, seamTile: 0.1, material: cedar, capEnd: false))
        }
        // Fill above/below the heart extremes inside the band.
        FA.box(&m, V3(L, ys[0] - hy0, t), V3(0, (hy0 + ys[0]) / 2, zf - t / 2), cedar, r: 0.0008)
        FA.box(&m, V3(L, hy1 - ys.last!, t), V3(0, (hy1 + ys.last!) / 2, zf - t / 2), cedar, r: 0.0008)
        _ = ht
        // Tongue-and-groove joint lines on the rails, back and end boards.
        for y in [0.052] as [Float] { FA.box(&m, V3(L - 0.004, 0.0018, 0.001), V3(0, y, zf + 0.0004), "wood.charred", r: 0.0003) }
        // Dark liner behind the front board so the hearts read as cut-outs.
        FA.box(&m, V3(L - 2 * t - 0.004, hy1 - y0 - 0.01, 0.004), V3(0, (y0 + hy1) / 2 + 0.003, zf - t - 0.002), "wood.walnut", r: 0.001)
        // Back board, end boards (the left one is fresh stock) and slatted bottom.
        FA.box(&m, V3(L, y1 - y0, t), V3(0, (y0 + y1) / 2, zb + t / 2), cedar, r: 0.002)
        for s: Float in [-1, 1] {
            FA.box(&m, V3(t, y1 - y0, zf - zb - 2 * t + 0.004), V3(s * (hw - t / 2), (y0 + y1) / 2, (zf + zb) / 2), s < 0 ? fresh : cedar, r: 0.002)
        }
        for k in 0..<3 {
            let z = zb + t + 0.006 + 0.035 + Float(k) * 0.075
            FA.box(&m, V3(L - 2 * t, 0.014, 0.066), V3(0, y0 + 0.007, z), cedar, r: 0.0015)
        }
        // Corner posts with chamfered pyramid caps, and screws through the front into the end boards.
        for sx: Float in [-1, 1] {
            for (z, zz) in [(zf - 0.016, 1), (zb + 0.016, 0)] as [(Float, Int)] {
                FA.box(&m, V3(0.032, y1 - y0 + 0.016, 0.032), V3(sx * (hw - 0.016), (y0 + y1 + 0.016) / 2, z), zz == 1 && sx < 0 ? fresh : cedar, r: 0.003)
                m.add(Prim.lathe([V2(0.0236, 0), V2(0.0, 0.026)], segments: 4, material: cedar), Xform(translation: V3(sx * (hw - 0.016), y1 + 0.016, z), rotation: FA.q(45, FA.Y)))
            }
            for y in [0.07, 0.15] as [Float] {
                let rusty = sx > 0 && y > 0.1
                FA.cylZ(&m, r: 0.0042, h: 0.0016, at: V3(sx * (hw - 0.016), y, zf), rusty ? "metal.rust" : "metal.screw-zinc", bevel: 0.0005, segments: 8)
                FA.box(&m, V3(0.0065, 0.0012, 0.001), V3(sx * (hw - 0.016), y, zf + 0.0019), "metal.hinge-satin-nickel", r: 0.0002, rot: FA.q(Float(rng.int(0...3)) * 40, FA.Z))
            }
        }
        // Iron brackets under the box: wall plate, seat arm, diagonal brace and bolts.
        for x in [-0.3, 0.3] as [Float] {
            FA.box(&m, V3(0.03, 0.15, 0.006), V3(x, 0.075, 0.003), iron, r: 0.0015)
            FA.box(&m, V3(0.03, 0.007, zf - 0.01), V3(x, y0 - 0.0035, (zf + 0.01) / 2), iron, r: 0.0015)
            FA.rod(&m, V3(x, 0.02, 0.008), V3(x, y0 - 0.005, zf - 0.04), r: 0.0042, iron, sides: 6)
            hexBolt(&m, at: V3(x, 0.125, 0.0065), normal: FA.Z, size: 0.012, material: "metal.rust")
            hexBolt(&m, at: V3(x, 0.03, 0.0065), normal: FA.Z, size: 0.012, material: iron)
        }
        // Soil and geraniums.
        m.add(Prim.superellipsoid(V3(L - 2 * t - 0.01, 0.05, zf - zb - 2 * t - 0.004), exponent: 6, subdivisions: 4, material: "soil.potting"),
              Xform(translation: V3(0, y1 - 0.025, (zf + zb) / 2)))
        func leafSurface(_ mat: MaterialKey) -> Surface {
            var s = Prim.superellipsoid(V3(0.075, 0.07, 0.006), exponent: 2.2, subdivisions: 2, material: mat)
            s.uvs = s.positions.map { V2($0.x, $0.y) }
            s.computeTangents()
            return s
        }
        let leaf = leafSurface("leaf.plain:3F7A2C"), leafD = leafSurface("leaf.plain:2B5F25")
        for i in 0..<6 {
            let x = -0.4 + Float(i) * 0.16
            let z = (zf + zb) / 2 + rng.float(-0.015...0.015)
            for k in 0..<5 {
                let a = Float(k) * 72 + rng.float(0...30)
                let p = V3(x + 0.035 * cos(a * .pi / 180), y1 + 0.012 + rng.float(0...0.012), z + 0.035 * sin(a * .pi / 180))
                m.add(k % 2 == 0 ? leaf : leafD, Xform(translation: p, rotation: FA.q(-a, FA.Y) * FA.q(-72, FA.X) * FA.q(rng.float(-12...12), FA.Z)))
            }
            FA.rod(&m, V3(x, y1 - 0.01, z), V3(x, y1 + 0.045, z), r: 0.0032, "plant.stem", sides: 5)
            for k in 0..<5 {
                let a = Float(k) * 72
                FC.bead(&m, r: 0.0125, at: V3(x + 0.016 * cos(a * .pi / 180), y1 + 0.056 + (k == 0 ? 0.01 : 0), z + 0.016 * sin(a * .pi / 180)), bloom, sub: 2)
            }
        }
        // Trailing ivy vines over the front board.
        for x in [-0.33, 0.12, 0.38] as [Float] {
            let pts = (0...6).map { k -> V3 in let u = Float(k) / 6; return V3(x + 0.015 * sin(u * 7), y1 + 0.0 - u * 0.1, zf + 0.012 + 0.006 * sin(u * 5)) }
            FA.path(&m, pts, r: 0.0022, "plant.stem", sides: 4)
            for (k, p) in pts.enumerated() where k > 0 {
                m.add(leafD, Xform(translation: p + V3(0.012 * (k % 2 == 0 ? 1 : -1), 0, 0.005), rotation: FA.q(Float(k) * 31, FA.Z), scale: V3(repeating: 0.5)))
            }
        }
        // Wear: algae at the bottom edge, water stains under the hearts, a hairline split in the front rail.
        m.add(Prim.superellipsoid(V3(0.14, 0.012, 0.01), exponent: 2.4, subdivisions: 3, material: "moss.cushion"), Xform(translation: V3(0.25, y0 + 0.002, zf + 0.002)))
        for x in [-0.3, -0.1, 0.3] as [Float] {
            FA.box(&m, V3(0.01, 0.04, 0.0008), V3(x, 0.092, zf + 0.0006), "wood.walnut", r: 0.0002)
        }
        FA.box(&m, V3(0.12, 0.0012, 0.001), V3(-0.15, 0.172, zf + 0.0005), "wood.charred", r: 0.0002)
        groundAO(&m, height: 0.06, floor: 0.85)
        return LODModel(FC.seatY(FA.centerZ(m)))
    }
}
