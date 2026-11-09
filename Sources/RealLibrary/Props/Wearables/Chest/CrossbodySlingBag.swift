import simd
import Foundation

/// Nylon sling bag worn across the chest on a 38 mm webbing strap: piped gusset seam, zip front pocket with metal
/// teeth and pull, tan leather patch, webbing carry handle, D-ring end tabs, padded shoulder section, slider
/// adjuster with tail and keeper, and a side-release buckle. Strap runs from the left shoulder to the bag on the right ribs.
public struct CrossbodySlingBag: RealAsset {
    public static let id = "crossbody-sling-bag"
    public static let summary = "Worn nylon crossbody sling bag: zip pocket, webbing strap, slider adjuster, padded shoulder."
    public static let tags = ["prop", "wearable", "worn", "fabric", "leather", "metal", "plastic"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 8, distance: 1.0, ground: false, studio: true)

    /// Bag shell fabric.
    public var shell: MaterialKey = "fabric.nylon:3A4034"
    /// Strap and handle webbing.
    public var webbing: MaterialKey = "fabric.webbing:1C1E1F"
    /// Zip teeth, rings and sliders.
    public var hardware: MaterialKey = "metal.nickel-worn"
    /// Label patch leather.
    public var patch: MaterialKey = "leather.tan"
    /// Buckle plastic.
    public var plastic: MaterialKey = "plastic.black"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        typealias K = ChestKit
        let amp: Float = 0.2, y0: Float = -0.015
        func yAt(_ th: Float) -> Float { y0 + amp * sin(th) }
        func P(_ th: Float, _ off: Float = 0) -> V3 { K.torso(th, yAt(th), off) }
        let thread: MaterialKey = "fabric.canvas:A9A592"
        let tw: Float = 0.038, tt: Float = 0.0034

        // Bag frame: X along the strap chord, Z outward, centred on the right ribs.
        let thTop: Float = -0.10, thLow: Float = -1.34, thMid: Float = (thTop + thLow) / 2
        let bagL: Float = 0.25, bagH: Float = 0.145, bagD: Float = 0.085
        let ax = (P(thTop) - P(thLow)).normalized
        var zd = K.bodyNormal(P(thMid)); zd = (zd - ax * simd_dot(zd, ax)).normalized
        let yd = simd_cross(zd, ax)
        let C = P(thMid) + zd * (bagD / 2 + 0.002)
        let bagQ = simd_quatf(simd_float3x3(columns: (ax, yd, zd)))
        func world(_ l: V3) -> V3 { C + bagQ.act(l) }

        // ---- Bag body (local frame) ----
        var b = Model(name: "bag")
        let ne: Float = 5
        func bz(_ x: Float, _ y: Float) -> Float {
            let r = 1 - pow(abs(x) / (bagL / 2), ne) - pow(abs(y) / (bagH / 2), ne)
            return r > 0 ? bagD / 2 * pow(r, 1 / ne) : 0
        }
        b.add(Prim.superellipsoid(V3(bagL, bagH, bagD), exponent: ne, subdivisions: 9, material: shell) { d in
            1 + 0.012 * sin(d.x * 9) * sin(d.y * 7)   // slight fabric puckering
        })
        // Piping at the gusset seam plus a stitch line on each side.
        func se(_ a: Float, _ s: Float = 1) -> V3 {
            let c = cos(a), sn = sin(a)
            return V3((c < 0 ? -1 : 1) * pow(abs(c), 2 / ne) * bagL / 2 * s, (sn < 0 ? -1 : 1) * pow(abs(sn), 2 / ne) * bagH / 2 * s, 0)
        }
        let seam = (0..<96).map { se(2 * Float.pi * Float($0) / 96, 1.0) }
        b.add(Prim.sweep(Shape2D.circle(0.0024, segments: 6), along: seam, up: V3(0, 0, 1), closedPath: true, caps: false, material: "fabric.webbing:15171A"))
        for side: Float in [-1, 1] {
            let pts = (0...120).map { k -> V3 in var p = se(2 * Float.pi * Float(k % 120) / 120, 1.0); p.z = side * 0.0055; return p }
            b.add(K.stitch(along: pts, normal: { V3($0.x / pow(bagL / 2, 2), $0.y / pow(bagH / 2, 2), 0).normalized }, pitch: 0.0066, thread: 0.0005, material: thread))
        }
        // Front zip pocket panel.
        let py: Float = -0.020, pw: Float = 0.19, ph: Float = 0.074
        let pz = bz(0, py)
        b.add(Prim.extrude(Shape2D.roundedRect(pw, ph, radius: 0.016, segments: 6), depth: 0.014, bevel: 0.005, bevelSegments: 3, material: shell),
              Xform(translation: V3(0, py, pz + 0.001)))
        let pf = pz + 0.008
        let outline = Shape2D.roundedRect(pw - 0.016, ph - 0.016, radius: 0.011, segments: 6)
        let op = (outline + [outline[0]]).map { V3($0.x, $0.y + py, pf + 0.0002) }
        b.add(K.stitch(along: op, normal: { _ in V3(0, 0, 1) }, pitch: 0.0038, thread: 0.0005, material: thread))
        // Zip tape, teeth and slider.
        let zy = py + ph / 2 - 0.013
        b.add(Prim.extrude(Shape2D.roundedRect(0.172, 0.0105, radius: 0.0035, segments: 3), depth: 0.0012, bevel: 0.0004, bevelSegments: 1, material: "fabric.webbing:0F1011"),
              Xform(translation: V3(0, zy, pf + 0.0006)))
        var teeth = Surface(material: hardware)
        var tx: Float = -0.083
        var alt = false
        while tx < 0.083 {
            let dy: Float = alt ? 0.0007 : -0.0007
            teeth.append(Prim.tube([V3(tx, zy + dy - 0.0021, pf + 0.0016), V3(tx, zy + dy + 0.0021, pf + 0.0016)], radii: [0.0006, 0.0006], sides: 3, seamTile: 0.01, material: hardware, capEnd: false))
            alt.toggle(); tx += 0.0023
        }
        b.add(teeth)
        let slX: Float = -0.062
        b.add(Prim.roundedBox(V3(0.012, 0.012, 0.0045), radius: 0.0016, bevelSegments: 1, material: hardware), Xform(translation: V3(slX, zy, pf + 0.0034)))
        b.add(Prim.extrude(Shape2D.roundedRect(0.0075, 0.021, radius: 0.0032, segments: 4), depth: 0.0018, bevel: 0.0006, bevelSegments: 2, material: hardware),
              Xform(translation: V3(slX, zy - 0.012, pf + 0.0052), rotation: simd_quatf(degrees: 12, axis: V3(1, 0, 0))))
        let cord = catmull([V3(slX, zy - 0.020, pf + 0.0052), V3(slX - 0.004, zy - 0.034, pf + 0.007), V3(slX + 0.004, zy - 0.034, pf + 0.007), V3(slX, zy - 0.020, pf + 0.0052)], per: 6)
        b.add(Prim.tube(cord, radii: cord.map { _ in 0.0011 }, sides: 8, seamTile: 0.01, material: "fabric.webbing:15171A"))
        // Leather label patch, stitched, with two rivets.
        let lx: Float = 0.058, ly: Float = py - 0.021
        b.add(Prim.extrude(Shape2D.roundedRect(0.032, 0.020, radius: 0.002, segments: 3), depth: 0.0018, bevel: 0.0006, bevelSegments: 2, material: patch),
              Xform(translation: V3(lx, ly, pf + 0.0009)))
        let lr = Shape2D.roundedRect(0.027, 0.015, radius: 0.0012, segments: 2)
        b.add(K.stitch(along: (lr + [lr[0]]).map { V3($0.x + lx, $0.y + ly, pf + 0.0019) }, normal: { _ in V3(0, 0, 1) }, pitch: 0.0028, thread: 0.0004, material: "fabric.canvas:D8C9A0"))
        for sx: Float in [-0.0105, 0.0105] { rivet(&b, at: V3(lx + sx, ly, pf + 0.0018), normal: V3(0, 0, 1), radius: 0.0022, segments: 12, material: hardware) }
        // Carry handle on the top edge with box-X stitched feet.
        func topY(_ x: Float) -> Float { bagH / 2 * pow(max(0, 1 - pow(abs(x) / (bagL / 2), ne)), 1 / ne) }
        var hp: [V3] = []
        for x in stride(from: Float(-0.07), through: -0.042, by: 0.007) { hp.append(V3(x, topY(x) + 0.0019, 0)) }
        for k in 1..<12 { let a = Float.pi - Float.pi * Float(k) / 12; hp.append(V3(cos(a) * 0.04, topY(0.04) + 0.0019 + sin(a) * 0.026, 0)) }
        for x in stride(from: Float(0.042), through: 0.07, by: 0.007) { hp.append(V3(x, topY(x) + 0.0019, 0)) }
        let hf = K.frames(hp, normal: { _ in V3(0, 0, 1) })
        b.add(K.ribbon(hf.map { var q = $0; q.w = V3(0, 0, 1); q.n = simd_cross(q.t, q.w); return q }, width: 0.022, thick: 0.0032, radius: 0.001, material: webbing))
        for sx: Float in [-1, 1] {
            let cx = sx * 0.059, cy = topY(cx) + 0.0038
            let r = [V3(cx - 0.008, cy, -0.0085), V3(cx + 0.008, cy, -0.0085), V3(cx + 0.008, cy, 0.0085), V3(cx - 0.008, cy, 0.0085), V3(cx - 0.008, cy, -0.0085)]
            b.add(K.stitch(along: r, normal: { _ in V3(0, 1, 0) }, pitch: 0.003, thread: 0.0005, material: thread))
            b.add(K.stitch(along: [r[0], r[2]], normal: { _ in V3(0, 1, 0) }, pitch: 0.003, thread: 0.0005, material: thread))
            b.add(K.stitch(along: [r[1], r[3]], normal: { _ in V3(0, 1, 0) }, pitch: 0.003, thread: 0.0005, material: thread))
        }
        // End tabs with D-rings.
        for sx: Float in [-1, 1] {
            let xe = sx * (bagL / 2)
            b.add(Prim.extrude(Shape2D.roundedRect(0.026, 0.034, radius: 0.003, segments: 3), depth: 0.0032, bevel: 0.0008, bevelSegments: 2, material: webbing),
                  Xform(translation: V3(xe + sx * 0.007, 0, 0), rotation: simd_quatf(degrees: 90, axis: V3(0, 1, 0))))
            b.add(K.ring(0.026, 0.034, wire: 0.0022, radius: 0.012, material: hardware), Xform(translation: V3(xe + sx * 0.027, 0, 0), rotation: simd_quatf(degrees: 90, axis: V3(0, 1, 0))))
            rivet(&b, at: V3(xe - sx * 0.002, 0.009, 0.0016), normal: V3(0, 0, 1), radius: 0.0028, segments: 12, material: hardware)
            rivet(&b, at: V3(xe - sx * 0.002, -0.009, 0.0016), normal: V3(0, 0, 1), radius: 0.0028, segments: 12, material: hardware)
        }
        // Key carabiner clipped to the lower end D-ring and a tan leather zip pull tab.
        let kx = -(bagL / 2 + 0.027)
        b.add(K.ring(0.013, 0.030, wire: 0.0014, radius: 0.0055, sides: 6, material: hardware), Xform(translation: V3(kx - 0.004, -0.012, 0.012), rotation: simd_quatf(degrees: 90, axis: V3(0, 1, 0)) * simd_quatf(degrees: 70, axis: V3(0, 0, 1))))
        b.add(Prim.extrude(Shape2D.roundedRect(0.007, 0.022, radius: 0.0030, segments: 4), depth: 0.0016, bevel: 0.0005, bevelSegments: 1, material: patch),
              Xform(translation: V3(slX, zy - 0.011, pf + 0.0075), rotation: simd_quatf(degrees: 18, axis: V3(1, 0, 0))))
        m.add(b, Xform(translation: C, rotation: bagQ))

        // ---- Strap ----
        let r1 = world(V3(bagL / 2 + 0.034, 0, 0)), r2 = world(V3(-bagL / 2 - 0.034, 0, 0))
        let a0 = thTop + 0.10, a1 = thLow + 2 * Float.pi - 0.10
        let steps = 72
        let v1 = r1 - P(a0, tt / 2), v2 = r2 - P(a1, tt / 2)
        var sp: [V3] = []
        for k in 0...steps {
            var p = P(a0 + (a1 - a0) * Float(k) / Float(steps), tt / 2)
            if k < 12 { p += v1 * pow(1 - Float(k) / 12, 2) }
            if k > steps - 12 { p += v2 * pow(1 - Float(steps - k) / 12, 2) }
            sp.append(p)
        }
        let nf: (V3) -> V3 = { K.bodyNormal($0) }
        let sf = K.frames(sp, normal: nf)
        m.add(K.ribbon(sf, width: tw, thick: tt, radius: 0.0012, segments: 1, material: webbing))
        // Tan leather end wraps at both D-rings and a reflective dash line down the strap.
        for rng in [0...5, (sf.count - 6)...(sf.count - 1)] {
            let wr = sf[rng].map { f -> K.Frame in var q = f; q.p += q.n * (tt / 2 + 0.0012); return q }
            m.add(K.ribbon(wr, width: tw + 0.003, thick: 0.0024, radius: 0.001, segments: 1, material: patch))
        }
        m.add(K.stitch(along: Array(K.offset(sf, w: 0, n: tt / 2 + 0.0003)[14..<(sf.count - 14)]), normal: nf, pitch: 0.011, thread: 0.0009, material: "fabric.canvas:BDBFB8"))
        // Index of the strap frames by azimuth for hardware placement.
        func fr(_ th: Float) -> K.Frame {
            let k = Int(((th - a0) / (a1 - a0) * Float(steps)).rounded())
            return sf[max(1, min(sf.count - 2, k))]
        }
        func place(_ f: K.Frame, _ off: V3 = .zero) -> Xform {
            Xform(translation: f.p + f.t * off.x + f.w * off.y + f.n * off.z, rotation: K.basis(f.t, f.w))
        }
        // Padded shoulder section with quilted channels.
        let pa = Float.pi / 2 - 0.55, pb = Float.pi / 2 + 0.60
        let padPath = (0...28).map { P(pa + (pb - pa) * Float($0) / 28, tt + 0.0058) }
        let pf2 = K.frames(padPath, normal: nf)
        m.add(K.ribbon(pf2, width: 0.07, thick: 0.0116, radius: 0.0052, segments: 3, widthScale: { 0.78 + 0.22 * sin(Float.pi * $0) }, material: "fabric.nylon:222527"))
        for off: Float in [-0.026, 0.026] {
            m.add(K.stitch(along: K.offset(pf2, w: off, n: 0.0059), normal: nf, pitch: 0.0045, thread: 0.0005, material: thread))
        }
        // Slider adjuster with folded tail and keeper.
        let f1 = fr(0.58)
        m.add(K.ring(0.016, 0.048, wire: 0.0016, radius: 0.0035, material: hardware), place(f1, V3(0, 0, tt + 0.0016)))
        m.add(Prim.tube([V3(0, -0.024, 0), V3(0, 0.024, 0)], radii: [0.0016, 0.0016], sides: 10, seamTile: 0.01, material: hardware), place(f1, V3(0, 0, tt + 0.0016)))
        let ta: Float = 0.64, tb: Float = 0.16
        let tailPath = (0...30).map { P(ta + (tb - ta) * Float($0) / 30, tt * 1.5 + 0.0004) }
        let tf = K.frames(tailPath, normal: nf)
        m.add(K.ribbon(tf, width: tw - 0.002, thick: tt, radius: 0.0012, segments: 1, widthScale: { 1 - 0.35 * smoothstep(0.88, 1, $0) }, material: webbing))
        m.add(K.stitch(along: K.offset(tf, w: 0, n: tt / 2 + 0.0003), normal: nf, pitch: 0.0032, thread: 0.0005, material: thread))
        let kp = (0...6).map { P(0.30 - 0.03 + 0.06 * Float($0) / 6, tt * 2.6 + 0.0006) }
        m.add(K.ribbon(K.frames(kp, normal: nf), width: tw + 0.004, thick: 0.0018, radius: 0.0007, segments: 1, material: webbing))
        // Side-release buckle on the chest strap.
        let f2 = fr(1.18)
        let bp = place(f2, V3(0, 0, tt + 0.0044))
        m.add(Prim.roundedBox(V3(0.044, 0.030, 0.0085), radius: 0.0022, bevelSegments: 1, material: plastic), Xform(translation: bp.translation + bp.rotation.act(V3(0.016, 0, 0)), rotation: bp.rotation))
        m.add(Prim.roundedBox(V3(0.026, 0.022, 0.0062), radius: 0.0018, bevelSegments: 1, material: plastic), Xform(translation: bp.translation + bp.rotation.act(V3(-0.026, 0, 0)), rotation: bp.rotation))
        for k in 0..<5 {
            let g = Float(k) - 2
            m.add(Prim.roundedBox(V3(0.0012, 0.020, 0.001), radius: 0.0004, bevelSegments: 1, material: plastic),
                  Xform(translation: bp.translation + bp.rotation.act(V3(0.024 + g * 0.0045, 0, 0.0052)), rotation: bp.rotation))
        }
        for sy: Float in [-0.0085, 0.0085] {
            m.add(Prim.tube([V3(-0.014, sy, 0), V3(0.012, sy, 0)], radii: [0.0017, 0.0017], sides: 8, seamTile: 0.01, material: plastic),
                  Xform(translation: bp.translation + bp.rotation.act(V3(-0.026, 0, 0)), rotation: bp.rotation))
        }
        return LODModel(m)
    }
}
