import simd
import Foundation

/// Ivory spray-rose boutonniere on a navy wool lapel: 29 hand-wrapped silk petals in five spiralling layers (blush
/// heart, ivory outside) with a green calyx, silver-dollar eucalyptus, baby's breath, a crepe-taped stem with an
/// ivory ribbon wrap, and a pearl-headed corsage pin through the lapel. The lapel is picked with hand stitching around
/// a thread buttonhole.
public struct BoutonniereFlower: RealAsset {
    public static let id = "boutonniere-flower"
    public static let summary = "Worn ivory rose boutonniere with eucalyptus, baby's breath, ribbon wrap and pearl pin on a wool lapel."
    public static let tags = ["prop", "wearable", "worn", "flower", "plant", "fabric"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 16, elevation: 8, distance: 0.95, ground: false, studio: true)

    /// Lapel cloth.
    public var cloth: MaterialKey = "fabric.cuff-navy"
    /// Petal outer colour.
    public var petal: MaterialKey = "fabric.velvet:F6F0E6"
    /// Leaf and stem green.
    public var green: MaterialKey = "fabric.velvet:56754A"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        typealias K = ChestKit
        var rng = SeededRNG(seed: seed)
        let thread: MaterialKey = "fabric.canvas:B9B4A2"
        let nf: (V3) -> V3 = { K.bodyNormal($0) }

        // ---- Lapel strip along the left chest, widest at the peak ----
        let lt: Float = 0.0075, lw: Float = 0.072
        let nl = 44
        let lp = (0...nl).map { k -> V3 in
            let u = Float(k) / Float(nl)
            return K.torso(0.31 - 0.27 * u, 0.15 - 0.23 * u, lt / 2)
        }
        let lf = K.frames(lp, normal: nf)
        func lapW(_ u: Float) -> Float { lw * (0.52 + 0.48 * (1 - smoothstep(0.05, 0.95, u))) }
        m.add(K.ribbon(lf, width: lw, thick: lt, radius: 0.0032, segments: 2, widthScale: { lapW($0) / lw }, material: cloth))
        for e: Float in [-1, 1] {
            let pts = (2...nl - 1).map { k -> V3 in
                let u = Float(k) / Float(nl); let f = lf[k]
                return f.p + f.w * (e * (lapW(u) / 2 - 0.0042)) + f.n * (lt / 2 + 0.0002)
            }
            m.add(K.stitch(along: pts, normal: nf, pitch: 0.0046, thread: 0.00042, material: thread))
        }
        // Thread buttonhole near the outer edge.
        let bh = lf[14]
        let bq = K.basis(bh.t, bh.w)
        let bpos = bh.p + bh.w * (lapW(14.0 / 44) / 2 - 0.016) + bh.n * (lt / 2)
        m.add(Prim.roundedBox(V3(0.020, 0.0030, 0.0004), radius: 0.0010, bevelSegments: 1, material: "fabric.cuff-navy:0C1220"), Xform(translation: bpos, rotation: bq * simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        let bo = Shape2D.roundedRect(0.0225, 0.0058, radius: 0.0028, segments: 4)
        let bpath = (bo + [bo[0]]).map { bpos + bq.act(V3($0.y, $0.x, 0.0003)) }
        m.add(K.stitch(along: bpath, normal: { _ in bh.n }, pitch: 0.0014, thread: 0.00038, material: thread))

        // ---- Flower assembly in local space: stem from y = 0, bloom axis +Y ----
        var fl = Model(name: "flower")
        let stemLen: Float = 0.074
        let stemPath = catmull([V3(0, -0.012, 0), V3(0.0006, 0.02, 0.0004), V3(0.0004, 0.05, -0.0003), V3(0, stemLen + 0.002, 0)], per: 8)
        fl.add(Prim.tube(stemPath, radii: stemPath.map { _ in 0.0022 }, sides: 12, seamTile: 0.02, material: "plastic.matte:5E7D45"))
        // Crepe-paper tape seam: a fine spiral.
        let tapeSp = (0...56).map { k -> V3 in
            let y = -0.010 + 0.080 * Float(k) / 56, a = Float(k) * 0.55
            return V3(cos(a) * 0.00225, y, sin(a) * 0.00225)
        }
        fl.add(Prim.tube(tapeSp, radii: tapeSp.map { _ in 0.00038 }, sides: 4, seamTile: 0.01, material: "plastic.matte:446436"))
        // Ivory ribbon wrap.
        let wrap = (0...48).map { k -> V3 in
            let y = 0.006 + 0.016 * Float(k) / 48, a = Float(k) / 48 * 2 * .pi * 3.2
            return V3(cos(a) * 0.0026, y, sin(a) * 0.0026)
        }
        let wf = K.frames(wrap, normal: { p in V3(p.x, 0, p.z).normalized })
        fl.add(K.ribbon(wf, width: 0.0075, thick: 0.0007, radius: 0.0003, segments: 1, caps: true, material: "fabric.grosgrain:EFE7D8"))
        // Ribbon tails hanging from the wrap.
        for (k, x) in [Float(-0.0016), 0.0018].enumerated() {
            let tp = catmull([V3(x, 0.008, 0.0027), V3(x * 1.6, -0.004 - Float(k) * 0.004, 0.0044), V3(x * 2.4, -0.014 - Float(k) * 0.006, 0.0042)], per: 6)
            fl.add(K.ribbon(K.frames(tp, normal: { _ in V3(0, 0, 1) }), width: 0.0062, thick: 0.0006, radius: 0.0002, segments: 1, widthScale: { 1 - 0.25 * $0 }, material: "fabric.grosgrain:EFE7D8"))
        }
        // Calyx: receptacle and five sepals.
        let by = stemLen
        fl.add(Prim.lathe([V2(0, by - 0.003), V2(0.0042, by - 0.001), V2(0.0058, by + 0.0035), V2(0.0050, by + 0.0075), V2(0, by + 0.0085)], segments: 24, seamTile: 0.02, material: green))
        func bend(_ p: V3, _ w: Float, _ h: Float, _ curl: Float) -> V3 { p }
        for k in 0..<5 {
            let a = Float(k) / 5 * 2 * .pi + 0.3
            var sp = Prim.cubeSphere(subdivisions: 3, material: green) { d in V3(d.x * 0.0030, d.y * 0.0125, d.z * 0.0005) }
            sp.deform { p in
                let yy = p.y + 0.0125, tilt: Float = 1.15 - 0.3 * yy / 0.0125
                let z0 = 0.0042 + yy * sin(tilt) * 0.9 + 0.0006 * yy / 0.0125
                let y0 = yy * cos(tilt) * 0.85
                return V3(p.x * cos(a) + z0 * sin(a), by + y0 + 0.0008, -p.x * sin(a) + z0 * cos(a))
            }
            fl.add(sp)
        }
        // Petals: spiral layers, cupped and flared at the lip.
        func petal(_ w: Float, _ h: Float, tilt: Float, rad: Float, az: Float, cupR: Float, curl: Float, base: Float, _ mat: MaterialKey) -> Surface {
            var s = Prim.cubeSphere(subdivisions: 4, material: mat) { d in V3(d.x * w / 2, d.y * h / 2, d.z * 0.00055) }
            s.deform { p in
                let yy = p.y + h / 2, f = yy / h
                let x = p.x * (0.62 + 0.52 * f)
                let a = x / cupR
                var z = -cupR * (1 - cos(a)) + curl * pow(f, 2.4) + 0.00022 * sin(x * 260 + az * 3) * pow(f, 3) + p.z
                let xx = cupR * sin(a)
                let y2 = yy * cos(tilt) - z * sin(tilt)
                z = yy * sin(tilt) + z * cos(tilt) + rad
                return V3(xx * cos(az) + z * sin(az), base + y2, -xx * sin(az) + z * cos(az))
            }
            s.uvs = s.positions.map { V2($0.x + $0.z * 0.7, $0.y) }
            s.computeTangents()
            return s
        }
        let layers: [(Int, Float, Float, Float, Float, Float, MaterialKey)] = [
            (3, 0.0016, 0.03, 0.0105, 0.0190, 0.0003, "fabric.velvet:EBCBBF"),
            (4, 0.0036, 0.12, 0.0150, 0.0230, 0.0006, "fabric.velvet:EFD8CD"),
            (5, 0.0060, 0.30, 0.0185, 0.0250, 0.0012, "fabric.velvet:F3E6DC"),
            (6, 0.0088, 0.56, 0.0215, 0.0255, 0.0020, "fabric.velvet:F6EEE4"),
            (7, 0.0116, 0.88, 0.0240, 0.0250, 0.0034, "fabric.velvet:F6F0E6")]
        for (li, L) in layers.enumerated() {
            for k in 0..<L.0 {
                let az = Float(k) / Float(L.0) * 2 * .pi + Float(li) * 2.399 + rng.float(-0.12...0.12)
                let tl = L.2 + rng.float(-0.06...0.06)
                fl.add(petal(L.3, L.4, tilt: tl, rad: L.1, az: az, cupR: L.3 * 0.95, curl: L.5, base: by + 0.0035 + Float(li) * 0.0004, (li == 4 && k == 2) ? "fabric.velvet:D9BC9C" : L.6))
            }
        }
        // Eucalyptus sprigs: silver-dollar leaf pairs on thin stems.
        for (i, az) in [Float(-1.0), 2.4, 3.7].enumerated() {
            let reach: Float = 0.030 + Float(i) * 0.004
            let dir = V3(sin(az), 0.55, cos(az)).normalized
            let base = V3(0, by - 0.012 + Float(i) * 0.004, 0)
            let sp = catmull([base, base + dir * reach * 0.5 + V3(0, 0.004, 0), base + dir * reach + V3(0, 0.009, 0)], per: 6)
            fl.add(Prim.tube(sp, radii: sp.map { _ in 0.00055 }, sides: 5, seamTile: 0.01, material: "plastic.matte:6E8A62"))
            for k in 1...3 {
                let u = Float(k) / 3
                let p = base + dir * reach * u + V3(0, 0.009 * u, 0)
                for sd: Float in [-1, 1] {
                    let side = simd_normalize(simd_cross(dir, V3(0, 1, 0)))
                    var lf2 = Prim.cubeSphere(subdivisions: 3, material: "fabric.velvet:8DA593") { d in V3(d.x * 0.0052, d.y * 0.0058, d.z * 0.0004) }
                    lf2.deform { q in V3(q.x, q.y + 0.0058, q.z + 0.0007 * (q.x * q.x) / 0.00003) }
                    let q = K.basis(side * sd, dir + V3(0, 0.5, 0))
                    fl.add(lf2, Xform(translation: p + side * sd * 0.0012, rotation: q))
                }
            }
        }
        // Baby's breath sprays.
        for (i, az) in [Float(0.6), 1.7, 4.4, 5.3].enumerated() {
            let dir = V3(sin(az), 0.75, cos(az)).normalized
            let base = V3(0, by - 0.008 + Float(i % 2) * 0.004, 0)
            let reach: Float = 0.026 + Float(i) * 0.002
            let br = catmull([base, base + dir * reach * 0.6, base + dir * reach + V3(0, 0.006, 0)], per: 5)
            fl.add(Prim.tube(br, radii: br.map { _ in 0.0003 }, sides: 4, seamTile: 0.01, material: "plastic.matte:7E9A6A"))
            for j in 0..<5 {
                let u = 0.35 + Float(j) * 0.15
                let tip = base + dir * reach * u + V3(rng.float(-0.003...0.003), 0.006 * u, rng.float(-0.003...0.003))
                fl.add(Prim.tube([base + dir * reach * u, tip + V3(0, 0.003, 0)], radii: [0.00022, 0.00022], sides: 3, seamTile: 0.01, material: "plastic.matte:7E9A6A"))
                fl.add(Prim.cubeSphere(subdivisions: 2, material: "fabric.velvet:FBFAF6") { d in d * 0.0020 }, Xform(translation: tip + V3(0, 0.0032, 0)))
            }
        }
        // Place on the lapel: stem lies along the lapel, bloom lifted forward.
        let li = 22
        let lfm = lf[li]
        let dir = simd_normalize(lfm.t * -0.80 + lfm.n * 0.60 + lfm.w * -0.10)
        let anchor = lfm.p + lfm.n * (lt / 2 + 0.0030) + lfm.w * 0.004
        let fq = simd_quatf(from: V3(0, 1, 0), to: dir)
        m.add(fl, Xform(translation: anchor, rotation: fq))
        // Corsage pin with pearl head, through the stem and lapel.
        let pinMid = anchor + fq.act(V3(0, 0.014, 0))
        let pd = simd_normalize(lfm.w * 0.80 + lfm.t * -0.55)
        m.add(Prim.tube([pinMid - pd * 0.022, pinMid + pd * 0.026], radii: [0.00042, 0.00042], sides: 6, seamTile: 0.01, material: "metal.nickel"))
        m.add(Prim.cubeSphere(subdivisions: 7, material: "plastic.gloss:F1EBDD") { d in d * 0.0034 }, Xform(translation: pinMid + pd * 0.0295))
        m.add(Prim.cylinder(radius: 0.0016, height: 0.0014, bevel: 0.0004, segments: 14, material: "metal.nickel"), Xform(translation: pinMid + pd * 0.0258, rotation: simd_quatf(from: .up, to: pd)))
        return LODModel(m)
    }
}
