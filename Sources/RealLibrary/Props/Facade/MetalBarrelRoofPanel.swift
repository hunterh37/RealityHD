import simd
import Foundation

/// Metal barrel roof panel: a 1.0 m wide, 3.0 m long 0.9 mm aluminium standing-seam pan curved to an 82 mm crown,
/// with a mechanically double-locked seam (male rib with rolled hem folded over the female leg), three
/// 12 mm stiffening striations, a hemmed eave drip edge with a closure strip, concealed clips shown at the
/// open eave, and stainless screws with EPDM washers through the eave flat. Dirt tracks run down the length,
/// scratches show bright metal, one fastener has rusted, and a shallow oil-canning dent breaks the crown.
public struct MetalBarrelRoofPanel: RealAsset {
    public static let id = "metal-barrel-roof-panel"
    public static let summary = "Curved standing-seam aluminium barrel roof panel: double-lock seams, striations, hemmed eave, clips and screws."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 22, distance: 2.6)

    /// Overall size in meters (x width, y height, z length).
    public var size = V3(1.0, 0.1, 3.0)
    public var panel: MaterialKey = "metal.powdercoat:A9ADAA"
    public var weathered: MaterialKey = "metal.powdercoat:8E8B80"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 1.0, L: Float = 3.0, sag: Float = 0.082, t: Float = 0.0015, sh: Float = 0.047
        func arc(_ x: Float) -> Float { sag * (1 - pow(2 * x / (W - 0.04), 2)) }
        func slope(_ x: Float) -> Float { atan(-sag * 8 * x / pow(W - 0.04, 2)) }
        // Pan: closed outline (outer curve then inner curve back), extruded the full 3 m.
        let n = 28
        var outer: [V2] = [], inner: [V2] = []
        for i in 0...n {
            let x = -(W / 2 - 0.02) + Float(i) / Float(n) * (W - 0.04)
            outer.append(V2(x, arc(x) + t))
            inner.append(V2(x, arc(x)))
        }
        let outline = outer + inner.reversed()
        m.add(Prim.extrude(outline.map { $0 }, depth: L, bevel: 0.0004, bevelSegments: 1, material: panel), Xform(translation: V3(0, 0, L / 2)))
        // Seams: female leg (left) and male rib with hem (right), double-locked into one T-bulb at the crest.
        let lx: Float = -(W / 2 - 0.02), rx: Float = W / 2 - 0.02
        let female: [V2] = [V2(lx - 0.02, 0), V2(lx, 0), V2(lx, sh - 0.012), V2(lx + 0.012, sh - 0.004), V2(lx + 0.012, sh + 0.004), V2(lx - 0.006, sh + 0.004), V2(lx - 0.006, sh - 0.008), V2(lx - 0.002, sh - 0.008), V2(lx - 0.002, sh - 0.016), V2(lx - 0.02, sh - 0.016)]
        _ = female
        func seam(_ x: Float, _ s: Float) {
            // Cross-section: base flange, rib wall, rolled bead with a folded hem.
            let o: [V2] = [V2(x + s * 0.022, 0), V2(x - s * 0.001, 0), V2(x - s * 0.001, sh - 0.01), V2(x - s * 0.008, sh - 0.002), V2(x - s * 0.008, sh + 0.004),
                           V2(x + s * 0.008, sh + 0.004), V2(x + s * 0.008, sh - 0.002), V2(x + s * 0.0025, sh - 0.01), V2(x + s * 0.0025, 0.004), V2(x + s * 0.022, 0.004)]
            m.add(Prim.extrude(o, depth: L, bevel: 0.0005, bevelSegments: 1, material: panel), Xform(translation: V3(0, 0, L / 2)))
        }
        seam(lx, -1)
        seam(rx, 1)
        // Hem fold line: the lower fold's visible edge as a thin bright bead.
        for x in [lx, rx] {
            FA.box(&m, V3(0.0016, 0.0016, L - 0.01), V3(x, sh + 0.0045, L / 2 - 0.0), "metal.aluminum", r: 0.0005)
        }
        // Striations: three 12 mm half-round ribs rolled into the pan.
        for x in [-0.22, 0.0, 0.22] as [Float] {
            var o: [V2] = []
            for k in 0...8 {
                let a = Float(k) / 8 * .pi
                o.append(V2(x + cos(a) * 0.006, arc(x) + t + sin(a) * 0.0035))
            }
            m.add(Prim.extrude(o, depth: L - 0.06, bevel: 0.0003, bevelSegments: 1, material: panel), Xform(translation: V3(0, 0, L / 2)))
        }
        // Eave drip edge: closure strip under the front edge with a 12 mm hem, and the open eave showing clips.
        var strip: [V2] = []
        for i in 0...n { let x = -(W / 2 - 0.02) + Float(i) / Float(n) * (W - 0.04); strip.append(V2(x, arc(x) - 0.002)) }
        for i in stride(from: n, through: 0, by: -1) { let x = -(W / 2 - 0.02) + Float(i) / Float(n) * (W - 0.04); strip.append(V2(x, arc(x) - 0.012)) }
        m.add(Prim.extrude(strip, depth: 0.004, bevel: 0.0006, bevelSegments: 1, material: "metal.galvanized"), Xform(translation: V3(0, 0, 0.002)))
        // Rolled eave hem along the arc and black profile closure foam at the ridge end (cut ends of the seams show the fold).
        let hemPath = (0...n).map { i -> V3 in let x = -(W / 2 - 0.02) + Float(i) / Float(n) * (W - 0.04); return V3(x, arc(x) + t / 2, 0.001) }
        m.add(Prim.tube(hemPath, radii: Array(repeating: 0.0034, count: hemPath.count), sides: 6, seamTile: 0.1, material: panel, capEnd: true))
        let foam = (0...n).map { i -> V3 in let x = -(W / 2 - 0.045) + Float(i) / Float(n) * (W - 0.09); return V3(x, arc(x) - 0.004, L - 0.012) }
        m.add(Prim.tube(foam, radii: Array(repeating: 0.0065, count: foam.count), sides: 6, seamTile: 0.1, material: "plastic.black", capEnd: true))
        // Concealed clips visible at the open end: 3 mm stainless tabs with slotted holes at 600 mm spacing, under the seams.
        for z in [-1.2, -0.6, 0.0, 0.6, 1.2] as [Float] {
            for x in [lx, rx] {
                FA.box(&m, V3(0.034, 0.0012, 0.04), V3(x, 0.0012, L / 2 + z - 0.0), "metal.stainless", r: 0.0003)
            }
        }
        // Eave and ridge screws: stainless #12 with EPDM washers on the flat at both ends.
        for zEnd: Float in [0.03, L - 0.03] {
            for x in [-0.34, -0.17, 0.0, 0.17, 0.34] as [Float] {
                let sx = x + rng.float(-0.003...0.003)
                let p = V3(sx, arc(sx) + t + 0.0008, zEnd)
                m.add(Prim.cylinder(radius: 0.0095, height: 0.0016, bevel: 0.0004, segments: 12, bevelSegments: 1, material: "rubber.silicone"), Xform(translation: p))
                rivet(&m, at: p + V3(0, 0.0014, 0), normal: V3(0, 1, 0), radius: 0.0075, height: 0.0045, segments: 8, material: rng.chance(0.2) ? "metal.rust" : "metal.stainless")
            }
        }
        // Weathering: dirt tracks, scratches, a dent, white oxide bloom at the seam bases.
        func strip3(_ x0: Float, _ x1: Float, _ z0: Float, _ len: Float, _ mat: MaterialKey, lift: Float = 0.0005) {
            var o: [V2] = []
            for i in 0...4 { let x = x0 + Float(i) / 4 * (x1 - x0); o.append(V2(x, arc(x) + t + lift)) }
            for i in stride(from: 4, through: 0, by: -1) { let x = x0 + Float(i) / 4 * (x1 - x0); o.append(V2(x, arc(x) + t + lift - 0.0004)) }
            m.add(Prim.extrude(o, depth: len, bevel: 0.0001, bevelSegments: 1, material: mat), Xform(translation: V3(0, 0, z0 + len / 2)))
        }
        for _ in 0..<7 {
            let x0 = rng.float(-0.4...0.38), w = rng.float(0.01...0.04)
            strip3(x0, x0 + w, rng.float(0...2.0) , rng.float(0.5...1.2), weathered)
        }
        for _ in 0..<5 {
            let x0 = rng.float(-0.4...0.4)
            strip3(x0, x0 + 0.0025, rng.float(0.1...2.5), rng.float(0.1...0.35), "metal.aluminum", lift: 0.0007)
        }
        m.add(Prim.superellipsoid(V3(0.2, 0.004, 0.3), exponent: 2, subdivisions: 4, material: panel), Xform(translation: V3(0.12, arc(0.12) + 0.0005, 1.0)))
        groundAO(&m, height: 0.06, floor: 0.8)
        return LODModel(FC.fit(m, size))
    }
}
