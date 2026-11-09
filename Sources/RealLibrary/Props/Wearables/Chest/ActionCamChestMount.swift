import simd
import Foundation

/// Chest harness with a matte action camera: black webbing shoulder straps and under-chest band with side-release
/// buckle, tri-glide adjusters and a rear slide, a moulded chest plate with strap slots, a three-prong mount base
/// whose prongs interleave the camera's two folding fingers on a knurled thumbscrew, and a 71 x 50 x 33 mm camera
/// with coated lens, front status screen, shutter button and side hatch, tilted up 10 degrees.
public struct ActionCamChestMount: RealAsset {
    public static let id = "action-cam-chest-mount"
    public static let summary = "Worn action camera on a webbing chest harness: plate, three-prong mount, thumbscrew, buckles."
    public static let tags = ["prop", "wearable", "worn", "electronics", "camera", "plastic", "fabric"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 22, elevation: 8, distance: 0.85, ground: false, studio: true)

    /// Webbing.
    public var webbing: MaterialKey = "fabric.webbing:2A2D31"
    /// Moulded plastic parts.
    public var plastic: MaterialKey = "plastic.black"
    /// Camera shell.
    public var shell: MaterialKey = "plastic.soft-touch"
    /// Bolt and knurled screw metal.
    public var steel: MaterialKey = "metal.nickel-worn"
    /// Camera tilt above horizontal (degrees).
    public var tilt: Float = 10
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        typealias K = ChestKit
        let sw: Float = 0.025, t: Float = 0.0028
        let thread: MaterialKey = "fabric.canvas:8A8A82"
        let nf: (V3) -> V3 = { K.bodyNormal($0) }
        func P(_ th: Float, _ y: Float, _ off: Float) -> V3 { K.torso(th, y, off) }

        // ---- Straps ----
        let bandY: Float = -0.053
        let nb = 72
        let bandPath = (0..<nb).map { P(2 * Float.pi * Float($0) / Float(nb), bandY, t / 2) }
        m.add(K.ribbon(K.frames(bandPath, normal: nf, closed: true), width: sw, thick: t, radius: 0.0011, segments: 1, closed: true, material: webbing))
        let ctrl: [V3] = [V3(0.14, 0.012, 0), V3(0.32, 0.085, 0), V3(0.72, 0.165, 0), V3(1.20, 0.205, 0), V3(1.57, 0.226, 0),
                          V3(1.95, 0.205, 0), V3(2.40, 0.150, 0), V3(2.80, 0.070, 0), V3(3.06, 0.0, 0)]
        let cp = catmull(ctrl, per: 4)
        var sf: [[K.Frame]] = []
        for s: Float in [1, -1] {
            let f = K.frames(cp.map { P(s * $0.x, $0.y, t / 2 + 0.0006) }, normal: nf)
            sf.append(f)
            m.add(K.ribbon(f, width: sw, thick: t, radius: 0.0011, segments: 1, material: webbing))
        }
        // Rear vertical strap and slide.
        let rp = (0...8).map { P(Float.pi, -0.004 + (bandY + 0.004) * Float($0) / 8, t / 2 + 0.0012) }
        m.add(K.ribbon(K.frames(rp, normal: nf), width: sw, thick: t, radius: 0.0011, segments: 1, material: webbing))
        let rb = P(Float.pi, -0.012, t + 0.002)
        let rq = K.basis(V3(1, 0, 0), V3(0, 1, 0))
        m.add(K.ring(0.056, 0.024, wire: 0.0022, radius: 0.004, sides: 8, material: plastic), Xform(translation: rb, rotation: simd_quatf(angle: .pi, axis: V3(0, 1, 0)) * rq))
        m.add(Prim.tube([V3(-0.027, 0, 0), V3(0.027, 0, 0)], radii: [0.0021, 0.0021], sides: 10, seamTile: 0.01, material: plastic), Xform(translation: rb))
        // Tri-glide adjusters with folded tails on each shoulder strap.
        for f in sf {
            let i0 = Int(Float(f.count) * 0.24)
            let fr = f[i0]
            let q = K.basis(fr.t, fr.w)
            let c = fr.p + fr.n * (t / 2 + 0.0016)
            m.add(K.ring(0.014, 0.032, wire: 0.0016, radius: 0.0025, sides: 8, material: plastic), Xform(translation: c, rotation: q))
            m.add(Prim.tube([V3(0, -0.015, 0), V3(0, 0.015, 0)], radii: [0.0016, 0.0016], sides: 10, seamTile: 0.01, material: plastic), Xform(translation: c, rotation: q))
            let tail = (i0 - 1...i0 + 9).map { f[$0].p + f[$0].n * (t * 1.5 + 0.0004) }
            let tf = K.frames(tail, normal: nf)
            m.add(K.ribbon(tf, width: sw - 0.001, thick: t, radius: 0.0011, segments: 1, widthScale: { 1 - 0.3 * smoothstep(0.8, 1, $0) }, material: webbing))
            let bx = tf.suffix(4)
            let a = bx.first!, b2 = bx.last!
            let o = (sw - 0.004) / 2
            let r = [a.p + a.w * -o, b2.p + b2.w * -o, b2.p + b2.w * o, a.p + a.w * o, a.p + a.w * -o].map { $0 + nf($0) * (t / 2 + 0.0004) }
            m.add(K.stitch(along: r, normal: nf, pitch: 0.0032, thread: 0.00045, material: thread))
            m.add(K.stitch(along: [r[0], r[2]], normal: nf, pitch: 0.0032, thread: 0.00045, material: thread))
            m.add(K.stitch(along: [r[1], r[3]], normal: nf, pitch: 0.0032, thread: 0.00045, material: thread))
        }
        // Side-release buckle at the front left of the band, adjuster on the right.
        let bf = K.frames([P(0.93, bandY, t), P(0.95, bandY, t), P(0.97, bandY, t)], normal: nf)[1]
        let bq = K.basis(bf.t, bf.w)
        func at(_ q: simd_quatf, _ p: V3, _ l: V3) -> V3 { p + q.act(l) }
        let bp = bf.p + bf.n * 0.0036
        m.add(Prim.roundedBox(V3(0.044, 0.030, 0.0085), radius: 0.0022, bevelSegments: 1, material: plastic), Xform(translation: at(bq, bp, V3(0.016, 0, 0)), rotation: bq))
        m.add(Prim.roundedBox(V3(0.026, 0.022, 0.0062), radius: 0.0018, bevelSegments: 1, material: plastic), Xform(translation: at(bq, bp, V3(-0.026, 0, 0)), rotation: bq))
        for k in 0..<5 {
            m.add(Prim.roundedBox(V3(0.0012, 0.020, 0.001), radius: 0.0004, bevelSegments: 1, material: plastic), Xform(translation: at(bq, bp, V3(0.024 + (Float(k) - 2) * 0.0045, 0, 0.0052)), rotation: bq))
        }
        for sy: Float in [-0.0085, 0.0085] {
            m.add(Prim.tube([V3(-0.014, sy, 0), V3(0.012, sy, 0)], radii: [0.0017, 0.0017], sides: 8, seamTile: 0.01, material: plastic), Xform(translation: at(bq, bp, V3(-0.026, 0, 0)), rotation: bq))
        }
        let af = K.frames([P(-0.97, bandY, t), P(-0.95, bandY, t), P(-0.93, bandY, t)], normal: nf)[1]
        let aq = K.basis(af.t, af.w)
        m.add(K.ring(0.014, 0.032, wire: 0.0016, radius: 0.0025, sides: 8, material: plastic), Xform(translation: af.p + af.n * (t / 2 + 0.0016), rotation: aq))
        m.add(Prim.tube([V3(0, -0.015, 0), V3(0, 0.015, 0)], radii: [0.0016, 0.0016], sides: 10, seamTile: 0.01, material: plastic), Xform(translation: af.p + af.n * (t / 2 + 0.0016), rotation: aq))
        let tailP = (0...14).map { P(-0.90 + 0.30 * Float($0) / 14, bandY, t * 1.5 + 0.0004) }
        m.add(K.ribbon(K.frames(tailP, normal: nf), width: sw - 0.001, thick: t, radius: 0.0011, segments: 1, widthScale: { 1 - 0.3 * smoothstep(0.8, 1, $0) }, material: "fabric.webbing:D8531B"))

        // ---- Chest plate ----
        let zs: Float = K.rzFront + t                       // plate back sits on the strap layer
        let pw: Float = 0.092, ph: Float = 0.074, pd: Float = 0.010
        let pz = zs + pd / 2
        m.add(Prim.extrude(Shape2D.roundedRect(pw, ph, radius: 0.014, segments: 6), depth: pd, bevel: 0.0032, bevelSegments: 2, material: plastic),
              Xform(translation: V3(0, 0.002, pz)))
        let pf = zs + pd
        // Raised rim line and strap slots with inserted dark frames.
        let rim = Shape2D.roundedRect(pw - 0.012, ph - 0.012, radius: 0.010, segments: 6).map { V3($0.x, $0.y + 0.002, pf + 0.0004) }
        m.add(Prim.sweep(Shape2D.circle(0.0007, segments: 4), along: rim, up: V3(0, 0, 1), closedPath: true, caps: false, material: plastic))
        for sx: Float in [-1, 1] { for sy: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(0.026, 0.0052, 0.0016), radius: 0.0016, bevelSegments: 1, material: "plastic.matte:060607"), Xform(translation: V3(sx * 0.027, 0.002 + sy * 0.0285, pf)))
        }}
        // Moulded ribs at the plate sides.
        for sx: Float in [-1, 1] { for k in 0..<2 {
            m.add(Prim.roundedBox(V3(0.0045, 0.0022, 0.0016), radius: 0.0007, bevelSegments: 1, material: plastic), Xform(translation: V3(sx * 0.0405, -0.008 + Float(k) * 0.0085, pf)))
        }}
        // ---- Mount base and prongs ----
        let baseH: Float = 0.022
        m.add(Prim.roundedBox(V3(0.034, 0.030, baseH), radius: 0.004, bevelSegments: 1, material: plastic), Xform(translation: V3(0, -0.014, pf + baseH / 2 - 0.0004)))
        m.add(Prim.roundedBox(V3(0.020, 0.0045, 0.0030), radius: 0.0014, bevelSegments: 1, material: plastic), Xform(translation: V3(0, -0.0315, pf + 0.0082)))  // release latch
        let hingeY: Float = 0.004, hingeZ = pf + 0.0215
        let prongQ = simd_quatf(simd_float3x3(columns: (V3(0, 0, 1), V3(0, 1, 0), V3(-1, 0, 0))))
        for x: Float in [-0.0068, 0, 0.0068] {
            m.add(Prim.extrude(Shape2D.roundedRect(0.016, 0.027, radius: 0.0078, segments: 6), depth: 0.0030, bevel: 0.0006, bevelSegments: 2, material: plastic),
                  Xform(translation: V3(x, hingeY - 0.0075, hingeZ), rotation: simd_quatf(simd_float3x3(columns: (V3(0, 0, 1), V3(0, 1, 0), V3(-1, 0, 0)))) * simd_quatf(degrees: 0, axis: V3(0, 0, 1))))
        }
        _ = prongQ
        // Bolt (along X) and knurled thumbscrew.
        let alongX = simd_quatf(degrees: -90, axis: V3(0, 0, 1))
        m.add(Prim.cylinder(radius: 0.0021, height: 0.0200, bevel: 0.0005, segments: 20, material: steel), Xform(translation: V3(-0.0100, hingeY, hingeZ), rotation: alongX))
        let nutX: Float = 0.0104
        m.add(Prim.cylinder(radius: 0.0100, height: 0.0072, bevel: 0.0014, segments: 28, material: plastic), Xform(translation: V3(nutX, hingeY, hingeZ), rotation: alongX))
        for k in 0..<22 {
            let a = Float(k) / 22 * 2 * .pi
            m.add(Prim.tube([V3(nutX + 0.0004, hingeY + cos(a) * 0.0101, hingeZ + sin(a) * 0.0101), V3(nutX + 0.0068, hingeY + cos(a) * 0.0101, hingeZ + sin(a) * 0.0101)], radii: [0.0005, 0.0005], sides: 3, seamTile: 0.01, material: plastic, capEnd: false))
        }
        m.add(Prim.cylinder(radius: 0.0034, height: 0.0014, bevel: 0.0004, segments: 20, material: steel), Xform(translation: V3(nutX + 0.0066, hingeY, hingeZ), rotation: alongX))
        m.add(Prim.cylinder(radius: 0.0032, height: 0.0012, bevel: 0.0004, segments: 20, material: steel), Xform(translation: V3(-0.0118, hingeY, hingeZ), rotation: alongX * simd_quatf(degrees: 180, axis: V3(1, 0, 0))))

        // ---- Camera (local frame: origin on the hinge, lens toward +Z) ----
        var c = Model(name: "camera")
        let cw: Float = 0.0715, chh: Float = 0.0505, cd: Float = 0.0335
        let by: Float = chh / 2 + 0.0105 + 0.0002
        c.add(Prim.roundedBox(V3(cw, chh, cd), radius: 0.0048, bevelSegments: 2, material: shell), Xform(translation: V3(0, by, 0)))
        // Camera folding fingers.
        for x: Float in [-0.0034, 0.0034] {
            c.add(Prim.extrude(Shape2D.roundedRect(0.016, 0.0245, radius: 0.0078, segments: 6), depth: 0.0030, bevel: 0.0006, bevelSegments: 2, material: shell),
                  Xform(translation: V3(x, 0.0035, 0), rotation: prongQ))
        }
        let fz = cd / 2
        let facing = simd_quatf(degrees: 90, axis: V3(1, 0, 0))
        // Lens stack, upper left of the front face.
        let lx: Float = 0.0135, ly: Float = by + 0.0070
        c.add(Prim.cylinder(radius: 0.0150, height: 0.0030, bevel: 0.0009, segments: 32, material: plastic), Xform(translation: V3(lx, ly, fz - 0.0004), rotation: facing))
        c.add(Prim.torus(major: 0.0128, minor: 0.0007, segments: 32, sides: 6, material: "metal.anodized-black"), Xform(translation: V3(lx, ly, fz + 0.0030), rotation: facing))
        let dome: [V2] = [V2(0, 0), V2(0.0122, 0), V2(0.0122, 0.0010), V2(0.0112, 0.0026), V2(0.0086, 0.0040), V2(0.0050, 0.0047), V2(0, 0.0049)]
        c.add(Prim.lathe(Profile.smooth(dome, per: 2), segments: 36, seamTile: 0.05, material: "glass.lens-coated"), Xform(translation: V3(lx, ly, fz + 0.0024), rotation: facing))
        // Inner lens barrel, coated element and logo bars.
        c.add(Prim.cylinder(radius: 0.0082, height: 0.0010, bevel: 0.0003, segments: 24, bevelSegments: 1, material: "metal.anodized-black"), Xform(translation: V3(lx, ly, fz + 0.0050), rotation: facing))
        c.add(Prim.cylinder(radius: 0.0048, height: 0.0006, bevel: 0.0002, segments: 20, bevelSegments: 1, material: "glass.signal-off"), Xform(translation: V3(lx, ly, fz + 0.0058), rotation: facing))
        for k in 0..<3 { c.add(Prim.roundedBox(V3(0.0042, 0.0020, 0.0005), radius: 0.0006, bevelSegments: 1, material: "metal.satin-aluminum"), Xform(translation: V3(-0.0245 + Float(k) * 0.0052, by + 0.0155, fz))) }
        // Front status screen, logo plate, indicator.
        c.add(Prim.roundedBox(V3(0.0225, 0.0225, 0.0012), radius: 0.0022, bevelSegments: 1, material: "glass.display"), Xform(translation: V3(-0.0195, by - 0.0090, fz)))
        c.add(Prim.roundedBox(V3(0.0140, 0.0030, 0.0006), radius: 0.0008, bevelSegments: 1, material: "metal.satin-aluminum"), Xform(translation: V3(-0.0190, by + 0.0105, fz)))
        // Shutter button with red ring on top, mode button and hatch seam on the side.
        c.add(Prim.cylinder(radius: 0.0108, height: 0.0026, bevel: 0.0008, segments: 28, material: plastic), Xform(translation: V3(-0.0140, by + chh / 2 - 0.0004, 0)))
        c.add(Prim.torus(major: 0.0104, minor: 0.0009, segments: 28, sides: 6, material: "plastic.sharps-red"), Xform(translation: V3(-0.0140, by + chh / 2 + 0.0022, 0)))
        c.add(Prim.roundedBox(V3(0.0024, 0.0062, 0.0150), radius: 0.0009, bevelSegments: 1, material: plastic), Xform(translation: V3(cw / 2 + 0.0008, by + 0.004, 0)))
        c.add(Prim.tube([V3(cw / 2 + 0.0001, by - 0.020, -cd / 2 + 0.003), V3(cw / 2 + 0.0001, by - 0.020, cd / 2 - 0.003)], radii: [0.00045, 0.00045], sides: 5, seamTile: 0.01, material: "plastic.matte:040405"))
        // Rear touch screen.
        c.add(Prim.roundedBox(V3(0.0425, 0.0270, 0.0010), radius: 0.003, bevelSegments: 1, material: "glass.display"), Xform(translation: V3(0, by, -fz)))
        m.add(c, Xform(translation: V3(0, hingeY, hingeZ), rotation: simd_quatf(degrees: -tilt, axis: V3(1, 0, 0))))
        return LODModel(m)
    }
}
