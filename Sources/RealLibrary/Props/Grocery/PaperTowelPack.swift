import simd
import Foundation

/// Six-roll paper towel pack (3 x 2 rolls standing), 40 x 28.5 x 27 cm: embossed paper rolls with kraft
/// cores, a clear shrink overwrap that sags between rolls and folds over the ends with crease lines, a printed
/// band wrapped around the pack, a carry handle strap and the invented brand SOFTLEAF.
public struct PaperTowelPack: RealAsset {
    public static let id = "paper-towel-pack"
    public static let summary = "Six-roll paper towel pack, 40 cm: embossed rolls with cores, shrink overwrap with folded ends, printed band, handle."
    public static let tags = ["prop", "grocery", "paper", "plastic", "home", "handheld"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 20, distance: 1.3, studio: true)

    public var rollRadius: Float = 0.064
    public var rollHeight: Float = 0.278
    /// Printed band brand field color.
    public var color: UInt32 = 0x1F5FA8
    public var brand = "SOFTLEAF"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true), level(hi: false)], switchDistances: [3])
    }

    /// Film outline (x, z) around the rolls, starting at the front center and running toward +x, with a sag
    /// between neighbouring rolls. `grow` offsets outward.
    func outline(_ grow: Float, hi: Bool) -> [V3] {
        let r = rollRadius, x0 = 2 * r, z0 = r, R = r + grow
        var pts: [V3] = []
        let ns = hi ? 24 : 8, nc = hi ? 10 : 4, ne = hi ? 12 : 4
        func sag(_ t: Float) -> Float { 0.0032 * pow(max(0, cos(2 * .pi * t)), 6) }
        for i in 0..<ns { let x = x0 * Float(i) / Float(ns); pts.append(V3(x, 0, z0 + R - sag((x - r) / (2 * r)))) }
        for i in 0..<nc { let a = Float.pi / 2 * (1 - Float(i) / Float(nc)); pts.append(V3(x0 + R * cos(a), 0, z0 + R * sin(a))) }
        for i in 0..<ne { let z = z0 - 2 * z0 * Float(i) / Float(ne); pts.append(V3(x0 + R - sag(z / (2 * r)), 0, z)) }
        for i in 0..<nc { let a = -Float.pi / 2 * Float(i) / Float(nc); pts.append(V3(x0 + R * cos(a), 0, -z0 + R * sin(a))) }
        for i in 0..<(2 * ns) { let x = x0 - 2 * x0 * Float(i) / Float(2 * ns); pts.append(V3(x, 0, -z0 - R + sag((x - r) / (2 * r)))) }
        for i in 0..<nc { let a = -Float.pi / 2 - Float.pi / 2 * Float(i) / Float(nc); pts.append(V3(-x0 + R * cos(a), 0, -z0 + R * sin(a))) }
        for i in 0..<ne { let z = -z0 + 2 * z0 * Float(i) / Float(ne); pts.append(V3(-x0 - R + sag(z / (2 * r)), 0, z)) }
        for i in 0..<nc { let a = Float.pi - Float.pi / 2 * Float(i) / Float(nc); pts.append(V3(-x0 + R * cos(a), 0, z0 + R * sin(a))) }
        for i in 0..<ns { let x = -x0 + x0 * Float(i) / Float(ns); pts.append(V3(x, 0, z0 + R - sag((x - r) / (2 * r)))) }
        return pts
    }

    func level(hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let r = rollRadius, h = rollHeight, seg = hi ? 40 : 14, base: Float = 0.003
        // Rolls: embossed paper with rounded edges, kraft cores.
        let paper: [V2] = [V2(0.0225, 0.0008), V2(r - 0.003, 0.0004), V2(r - 0.0006, 0.0018), V2(r, 0.004), V2(r, h - 0.004),
                           V2(r - 0.0006, h - 0.0018), V2(r - 0.003, h - 0.0004), V2(0.0225, h - 0.0008)]
        let core: [V2] = [V2(0.0225, h - 0.0008), V2(0.0212, h - 0.0005), V2(0.0205, h - 0.002), V2(0.0205, 0.002), V2(0.0212, 0.0005), V2(0.0225, 0.0008)]
        let paperS = Prim.lathe(paper, segments: seg, seamTile: 0.1, material: "paper.exam:F7F6F2")
        let coreS = Prim.lathe(core, segments: seg / 2, seamTile: 0.05, material: "paper.screwbox-kraft")
        for ix in -1...1 { for iz in [-1, 1] {
            let c = V3(Float(ix) * 2 * r, base, Float(iz) * r)
            let spin = simd_quatf(angle: Float(ix * 3 + iz) * 0.9, axis: .up)
            m.add(paperS, Xform(translation: c, rotation: spin)); m.add(coreS, Xform(translation: c, rotation: spin))
        } }
        // Shrink film: sides with sag, rounded shoulders, folded top and bottom.
        let top = base + h
        let levels: [(Float, Float)] = [(0, -0.018), (0.0012, -0.006), (base + 0.002, 0.0018), (top - 0.002, 0.0018), (top + 0.0018, -0.008),
                                        (top + 0.0028, -0.03)]
        let film = Prim.loft(levels.map { (y, g) in outline(g, hi: hi).map { V3($0.x, y, $0.z) } }.reversed(),
                             capStart: true, capEnd: true, material: "pkg.shrink-film")
        m.add(film)
        // End fold creases on top and bottom.
        if hi {
            for sx: Float in [1, -1] { for (y, k) in [(top + 0.0026, Float(1)), (0.0016, Float(-1))] {
                let ex = sx * (2 * r + r), cx = sx * (2 * r + 0.012)
                for sz: Float in [1, -1] {
                    m.add(Prim.tube([V3(ex, y - k * 0.0012, sz * (r + 0.02)), V3(cx, y, sz * 0.012), V3(cx - sx * 0.02, y, 0)],
                                    radii: [0.0007, 0.0009, 0.0005], sides: 4, seamTile: 0.05, material: "plastic.translucent:EEF2F4"))
                }
            } }
        }
        // Printed band around the pack, 3 designs around, logo pill centered on the front.
        let key = GroceryKit.tint("pkg.paper-label", color)
        let (t, a) = GroceryKit.printTile(key)
        let ring = outline(0.0034, hi: hi)
        var len: [Float] = [0]
        for i in 1...ring.count { len.append(len[i - 1] + simd_distance(ring[i % ring.count], ring[i - 1])) }
        let total = len.last!, rep = total / 3
        let y0: Float = 0.05, y1 = y0 + rep * a
        var band = Surface(material: key)
        for i in 0...ring.count {
            let p = ring[i % ring.count], u = (len[i] / rep + 0.70) * t
            _ = band.add(V3(p.x, y0, p.z), .up, V2(u, t * a)); _ = band.add(V3(p.x, y1, p.z), .up, V2(u, 0))
        }
        for i in 0..<UInt32(ring.count) { let q = i * 2; band.quad(q, q + 2, q + 3, q + 1) }
        band.recomputeNormals(weldSeams: false); band.computeTangents()
        m.add(band)
        // Wordmark in the pill, product line under the art.
        let fz = rollRadius * 2 + 0.0034 + 0.0006
        let py = y0 + 0.85 * (y1 - y0)
        GroceryKit.printSmooth(&m, brand, height: 0.018, at: V3(0, py - 0.009, fz), "plastic.gloss:FFFFFF", maxWidth: 0.15, weight: 1.3)
        GroceryKit.printSmooth(&m, "6 DOUBLE ROLLS", height: 0.009, at: V3(0, y0 + 0.012, fz), "plastic.gloss:FFFFFF", maxWidth: 0.12, weight: 1.1)
        // Carry handle strap over the top along x.
        let strap = GroceryKit.sheet(cols: hi ? 18 : 6, rows: 1, "plastic.gloss:F4F4F0") { u, v in
            let x = -0.1 + 0.2 * u, lift = 0.02 * pow(sin(.pi * u), 0.7)
            return V3(x, top + 0.003 + lift, (0.5 - v) * 0.04)
        }
        var st = strap; st.uvs = st.positions.map { V2($0.x, $0.z) }; st.computeTangents()
        m.add(st); m.add(st.flipped())
        GroceryKit.printSmooth(&m, brand, height: 0.008, at: V3(0, top + 0.003 + 0.02 + 0.0006, 0.004), "plastic.gloss:1F5FA8",
                               rot: simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0)), maxWidth: 0.08, weight: 1.1)
        return m
    }
}
