import simd
import Foundation

/// Open-plan cubicle, 180 x 150 x 180 cm: three 60 mm fabric panels (back and two sides, 1.5 m high) with
/// anodized top caps and corner posts, an L-shaped 30 mm laminate work surface (168 x 65 back run, 55 cm
/// return on the left), a three-drawer pedestal on the right, an overhead bin with flip-up door and a task
/// light bar under it, a raceway strip on the back panel and pinned notes.
public struct CubicleWorkstation: RealAsset {
    public static let id = "cubicle-workstation"
    public static let summary = "Open-plan cubicle: three fabric panels with aluminum caps, L-shaped laminate desk, drawer pedestal, overhead bin and task light."
    public static let tags = ["prop", "floorplan", "office", "commercial", "furniture", "fabric", "metal", "interior"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 24, distance: 1.25, studio: true)

    /// Overall width (x).
    public var width: Float = 1.8
    /// Overall depth (z).
    public var depth: Float = 1.8
    /// Panel height.
    public var height: Float = 1.5
    /// Fabric panel material.
    public var fabric: MaterialKey = "fabric.upholstery:E4EAF0"
    /// Work surface laminate.
    public var laminate: MaterialKey = "laminate.white:D8CFBE"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [6])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, D = depth, H = height
        let alu: MaterialKey = "metal.anodized"
        let steel: MaterialKey = "metal.powdercoat:C9CBCC"
        let black: MaterialKey = "plastic.matte:3A3B3D"
        let seg = 1
        func box(_ size: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.003, bevel: Int = 1) {
            let s = detail ? Prim.roundedBox(size, radius: r, bevelSegments: detail ? bevel : seg, material: mat) : cuboid(size, material: mat)
            m.add(s, Xform(translation: c).jittered(&rng, deg: 0.02, offset: 0.0002))
        }
        let pt: Float = 0.06           // panel thickness
        let zBack = -D / 2 + pt / 2
        let xSide = W / 2 - pt / 2
        let fabricTop = H - 0.03

        // Panels: fabric slab between a powder-coat base raceway and an anodized cap.
        func panel(len: Float, center: V3, alongX: Bool) {
            let sz = alongX ? V3(len, fabricTop - 0.1, pt - 0.008) : V3(pt - 0.008, fabricTop - 0.1, len)
            box(sz, V3(center.x, 0.1 + sz.y / 2, center.z), fabric, r: 0.012, bevel: 2)
            let base = alongX ? V3(len, 0.1, pt - 0.004) : V3(pt - 0.004, 0.1, len)
            box(base, V3(center.x, 0.05 + 0.0, center.z), steel, r: 0.003)
            let cap = alongX ? V3(len, 0.03, pt) : V3(pt, 0.03, len)
            box(cap, V3(center.x, H - 0.015, center.z), alu, r: 0.006, bevel: 2)
            // Tile reveal: dark aluminum strip where the lower and upper fabric tiles meet, both faces.
            for f: Float in [-1, 1] {
                let rs = alongX ? V3(len - 0.004, 0.012, 0.002) : V3(0.002, 0.012, len - 0.004)
                let off = alongX ? V3(0, 0, f * (pt / 2 - 0.003)) : V3(f * (pt / 2 - 0.003), 0, 0)
                m.add(cuboid(rs, material: alu), Xform(translation: V3(center.x, 0.92, center.z) + off))
            }
            // Glides under the base.
            if detail {
                let n = Int(len / 0.7) + 1
                for i in 0..<n {
                    let t = n == 1 ? 0 : (Float(i) / Float(n - 1) - 0.5) * (len - 0.12)
                    let p = alongX ? V3(center.x + t, 0.007, center.z) : V3(center.x, 0.007, center.z + t)
                    m.add(Prim.cylinder(radius: 0.018, height: 0.014, bevel: 0.003, segments: 12, bevelSegments: 1, material: black), Xform(translation: p))
                }
            }
        }
        panel(len: W, center: V3(0, 0, zBack), alongX: true)
        let sideLen = D - pt
        for s: Float in [-1, 1] { panel(len: sideLen, center: V3(s * xSide, 0, pt / 2), alongX: false) }
        // Posts at the corners and the free front ends (aluminum extrusion).
        for s: Float in [-1, 1] {
            box(V3(0.066, H - 0.004, 0.066), V3(s * (W / 2 - 0.033), (H - 0.004) / 2 + 0.002, -D / 2 + 0.033), alu, r: 0.005)
            box(V3(0.066, H - 0.004, 0.026), V3(s * xSide, (H - 0.004) / 2 + 0.002, D / 2 - 0.013), alu, r: 0.004)
        }

        // Work surface: back run on the right pedestal and the left return on a leg.
        let inner = W - 2 * pt
        let top: Float = 0.73, t: Float = 0.03
        let backD: Float = 0.65, retW: Float = 0.55, retD: Float = 0.75
        let runX0 = -inner / 2 + 0.002, runX1 = inner / 2 - 0.002
        // Back run, with a rounded front-right corner.
        func slab(x0: Float, x1: Float, z0: Float, z1: Float) {
            let c = V3((x0 + x1) / 2, top - t / 2, (z0 + z1) / 2)
            let band: MaterialKey = "plastic.matte:B9AE98"
            box(V3(x1 - x0, t - 0.001, z1 - z0), c, band, r: 0.002)
            box(V3(x1 - x0 - 0.003, 0.001, z1 - z0 - 0.003), c + V3(0, t / 2 - 0.0004, 0), laminate, r: 0.0003)
        }
        let zRun0 = -D / 2 + pt, zRun1 = zRun0 + backD
        slab(x0: runX0, x1: runX1, z0: zRun0, z1: zRun1)
        slab(x0: runX0, x1: runX0 + retW, z0: zRun1, z1: zRun1 + retD - backD + 0.0)
        // Return leg: square steel post with a foot at the free corner, and a stretcher under the top.
        let legX = runX0 + retW - 0.04, legZ = zRun1 + retD - backD - 0.04
        box(V3(0.04, top - t, 0.04), V3(legX, (top - t) / 2, legZ), steel, r: 0.003)
        box(V3(0.06, 0.012, 0.3), V3(legX, 0.006, legZ + 0.0), steel, r: 0.004)
        box(V3(0.04, 0.035, 0.6), V3(legX, top - t - 0.0175, legZ - 0.3 + 0.02), steel, r: 0.003)

        // Drawer pedestal under the right end of the back run.
        let pedW: Float = 0.42, pedD: Float = 0.58, pedH = top - t
        let px = runX1 - pedW / 2 - 0.02, pz = zRun0 + pedD / 2 + 0.02
        box(V3(pedW, pedH - 0.03, pedD), V3(px, 0.03 + (pedH - 0.03) / 2, pz), steel, r: 0.004)
        box(V3(pedW - 0.03, 0.03, pedD - 0.04), V3(px, 0.015, pz), black, r: 0.002)
        let drawerH = (pedH - 0.06) / 3
        for i in 0..<3 {
            let y = 0.04 + drawerH * (Float(i) + 0.5)
            box(V3(pedW - 0.016, drawerH - 0.01, 0.018), V3(px, y, pz + pedD / 2 + 0.006), steel, r: 0.003)
            // Recessed pull slot and lock.
            if detail { box(V3(0.18, 0.016, 0.01), V3(px, y + drawerH / 2 - 0.035, pz + pedD / 2 + 0.01), black, r: 0.002) }
            if detail && i == 0 {
                m.add(Prim.cylinder(radius: 0.008, height: 0.004, bevel: 0.001, segments: 12, bevelSegments: 1, material: "metal.chrome"),
                      Xform(translation: V3(px + 0.15, y - 0.012, pz + pedD / 2 + 0.014), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            }
        }

        // Overhead bin hung from the back panel and the left side panel.
        let binW: Float = 1.15, binD: Float = 0.36, binH: Float = 0.4
        let binX = 0.0 as Float, binY: Float = 1.06, binZ = zRun0 + binD / 2
        let body: MaterialKey = "laminate.white:CDD0D3"
        box(V3(binW, 0.012, binD), V3(binX, binY + 0.006, binZ), body, r: 0.002)
        box(V3(binW, 0.012, binD), V3(binX, binY + binH - 0.006, binZ), body, r: 0.002)
        for s: Float in [-1, 1] { box(V3(0.012, binH, binD), V3(binX + s * (binW / 2 - 0.006), binY + binH / 2, binZ), body, r: 0.002) }
        // Flip-up door, slightly open? kept closed: front panel with finger pull and end tabs.
        m.add(cuboid(V3(binW - 0.02, binH - 0.02, 0.006), material: black), Xform(translation: V3(binX, binY + binH / 2, binZ + binD / 2 - 0.012)))
        box(V3(binW - 0.04, binH - 0.045, 0.018), V3(binX, binY + binH / 2 + 0.006, binZ + binD / 2 - 0.004), body, r: 0.005)
        if detail { box(V3(0.3, 0.02, 0.012), V3(binX, binY + 0.03, binZ + binD / 2 + 0.005), black, r: 0.004) }
        for s: Float in [-1, 1] where detail {
            box(V3(0.04, 0.04, 0.02), V3(binX + s * (binW / 2 - 0.05), binY + binH - 0.02, binZ + binD / 2 - 0.004), black, r: 0.003)
        }
        // Task light bar under the bin.
        m.add(cuboid(V3(0.8, 0.014, 0.05), material: black), Xform(translation: V3(binX, binY - 0.007, binZ + 0.02)))
        m.add(cuboid(V3(0.76, 0.003, 0.03), material: "emissive.panel"), Xform(translation: V3(binX, binY - 0.0145, binZ + 0.02)))

        // Raceway strip on the back panel above the work surface.
        box(V3(1.4, 0.05, 0.014), V3(0, top + 0.05, -D / 2 + pt + 0.007), steel, r: 0.003)
        if detail {
            for x: Float in [-0.4, 0.0, 0.4] {
                m.add(cuboid(V3(0.05, 0.03, 0.004), material: black), Xform(translation: V3(x, top + 0.05, -D / 2 + pt + 0.015)))
            }
        }

        // Pinned notes on the back panel between raceway and bin.
        if detail {
            let notes: [(Float, Float, Float, String)] = [(-0.45, 0.94, 0.1, "F2E27A"), (-0.3, 0.9, 0.18, "FFFFFF"), (0.46, 0.93, 0.09, "7FC6A4"), (0.6, 0.88, 0.2, "FFFFFF")]
            for (x, y, w, c) in notes {
                let h = w * (c == "FFFFFF" ? 1.3 : 1.0)
                let n = Prim.roundedBox(V3(w, h, 0.0015), radius: 0.0003, bevelSegments: 1, material: "laminate.white:\(c)")
                m.add(n, Xform(translation: V3(x, y, -D / 2 + pt + 0.0008), rotation: simd_quatf(degrees: rng.float(-4...4), axis: V3(0, 0, 1))))
                m.add(Prim.cylinder(radius: 0.004, height: 0.003, bevel: 0.001, segments: 8, bevelSegments: 1, material: "metal.chrome"),
                      Xform(translation: V3(x, y + h / 2 - 0.012, -D / 2 + pt + 0.0016), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            }
        }
        // Pinboard: cork tile in an anodized frame on the left side panel above the return.
        do {
            let bx = -W / 2 + pt + 0.006, bz = zRun1 + 0.1
            box(V3(0.012, 0.46, 0.62), V3(bx, 1.05, bz), alu, r: 0.003)
            m.add(cuboid(V3(0.004, 0.42, 0.58), material: "wood.plywood-osb"), Xform(translation: V3(bx + 0.007, 1.05, bz)))
            if detail {
                for (dy, dz, c) in [(0.1, -0.12, "F2E27A"), (-0.08, 0.1, "FFFFFF"), (0.12, 0.14, "E88A9A")] as [(Float, Float, String)] {
                    m.add(cuboid(V3(0.002, 0.1, 0.1), material: "paper.sheet:\(c)"), Xform(translation: V3(bx + 0.0105, 1.05 + dy, bz + dz), rotation: simd_quatf(degrees: dz * 40, axis: V3(1, 0, 0))))
                }
            }
        }
        // Grommet in the work surface and worn laminate at the front edge of the return.
        m.add(Prim.cylinder(radius: 0.03, height: 0.003, bevel: 0.001, segments: detail ? 20 : 10, bevelSegments: 1, material: black),
              Xform(translation: V3(0.3, top + 0.0005, zRun0 + 0.12)))
        m.add(cuboid(V3(0.4, 0.0008, 0.012), material: "laminate.white:EDE8DD"), Xform(translation: V3(runX0 + retW / 2, top + 0.0003, zRun1 + retD - backD - 0.012)))
        // Desk story: a corded desk phone, a paper stack with a pen tray, a worn patch of lighter laminate at the front edge.
        let deskZ = zRun1 - 0.2
        box(V3(0.19, 0.045, 0.22), V3(0.25, top + 0.0225, deskZ), black, r: 0.01)
        box(V3(0.05, 0.03, 0.2), V3(0.25 - 0.06, top + 0.06, deskZ), black, r: 0.012)
        box(V3(0.05, 0.03, 0.2), V3(0.25 + 0.06, top + 0.06, deskZ), black, r: 0.012)
        for i in 0..<3 {
            box(V3(0.22, 0.012, 0.3), V3(-0.28, top + 0.006 + Float(i) * 0.013, deskZ - 0.03 + 0.003 * Float(i)), "paper.sheet", r: 0.001)
        }
        if detail {
            box(V3(0.2, 0.04, 0.09), V3(-0.28, top + 0.02, deskZ + 0.2), black, r: 0.004)
            for k in 0..<3 {
                m.add(Prim.cylinder(radius: 0.004, height: 0.14, bevel: 0.001, segments: 8, bevelSegments: 1, material: k == 1 ? "plastic.matte:2B4C8F" : black),
                      Xform(translation: V3(-0.33 + Float(k) * 0.03, top + 0.02, deskZ + 0.2), rotation: simd_quatf(degrees: 10 * Float(k - 1), axis: V3(0, 0, 1))))
            }
        }
        groundAO(&m, height: 0.12, floor: 0.55)
        return m
    }
}
