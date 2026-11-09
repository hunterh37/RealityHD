import simd
import Foundation

/// DSLR on a padded neoprene shoulder strap: the strap loops over the left shoulder with front and back legs running to
/// the camera's side lugs, so the camera hangs at the hip with the lens pointing outward. Camera has a leatherette grip,
/// pentaprism hump with hot shoe, mode dial, shutter collar, rear LCD and eyecup, a ribbed zoom/focus barrel with red
/// accent ring, coated front element and a petal hood. Strap has diamond quilting, contrast stitching and slider adjusters.
public struct DslrShoulderStrap: RealAsset {
    public static let id = "dslr-shoulder-strap"
    public static let summary = "Worn DSLR on a padded neoprene shoulder strap: grip, prism, dials, ribbed lens with hood, sliders."
    public static let tags = ["prop", "wearable", "worn", "plastic", "fabric", "metal"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 55, elevation: 12, distance: 1.5, ground: false, studio: true)

    /// Camera body.
    public var body: MaterialKey = "plastic.matte:1B1C1F"
    /// Lens barrel.
    public var barrel: MaterialKey = "plastic.matte:101113"
    /// Grip and eyecup rubber.
    public var rubber: MaterialKey = "plastic.soft-touch"
    /// Dials, mount, rings.
    public var metal: MaterialKey = "metal.nickel-worn"
    /// Strap webbing.
    public var webbing: MaterialKey = "fabric.webbing:17181A"
    /// Neoprene pad.
    public var pad: MaterialKey = "fabric.nylon:1D1E21"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        typealias K = ChestKit
        let thread: MaterialKey = "fabric.canvas:C9A53A"
        let Cx: Float = 0.088, Cy: Float = -0.30
        let camQ = K.basis(V3(0, 0, -1), V3(0, 1, 0))
        let toZ = simd_quatf(from: V3(0, 1, 0), to: V3(0, 0, 1))

        // ---- Camera in its own frame: X width, Y height, Z lens axis ----
        var c = Model(name: "camera")
        c.add(Prim.roundedBox(V3(0.146, 0.098, 0.050), radius: 0.008, bevelSegments: 3, material: body))
        c.add(Prim.roundedBox(V3(0.046, 0.098, 0.076), radius: 0.013, bevelSegments: 3, material: body), Xform(translation: V3(0.051, 0, 0.012)))
        c.add(Prim.roundedBox(V3(0.0415, 0.088, 0.003), radius: 0.003, bevelSegments: 2, material: rubber), Xform(translation: V3(0.051, 0, 0.0505)))
        c.add(Prim.roundedBox(V3(0.002, 0.070, 0.0016), radius: 0.0006, bevelSegments: 1, material: "metal.enamel:B3201C"), Xform(translation: V3(0.0285, 0, 0.0508)))
        c.add(Prim.roundedBox(V3(0.030, 0.080, 0.003), radius: 0.003, bevelSegments: 2, material: rubber), Xform(translation: V3(-0.055, -0.002, 0.0265)))
        // Prism hump, hot shoe and top controls.
        c.add(Prim.roundedBox(V3(0.060, 0.026, 0.058), radius: 0.011, bevelSegments: 3, material: body), Xform(translation: V3(-0.006, 0.060, -0.004)))
        c.add(Prim.roundedBox(V3(0.020, 0.0022, 0.020), radius: 0.0008, bevelSegments: 1, material: metal), Xform(translation: V3(-0.006, 0.0742, -0.002)))
        for sx: Float in [-0.0085, 0.0085] {
            c.add(Prim.roundedBox(V3(0.0020, 0.0030, 0.020), radius: 0.0008, bevelSegments: 1, material: metal), Xform(translation: V3(-0.006 + sx, 0.0768, -0.002)))
        }
        // Mode dial with stepped ridges.
        c.add(Prim.lathe([V2(0, 0), V2(0.0165, 0), V2(0.0165, 0.003), V2(0.0152, 0.0034), V2(0.0165, 0.0045), V2(0.0165, 0.0075), V2(0.0152, 0.0079),
                          V2(0.0165, 0.0090), V2(0.0165, 0.0115), V2(0.0145, 0.0125), V2(0, 0.0125)], segments: 36, seamTile: 0.05, material: metal),
              Xform(translation: V3(-0.052, 0.049, -0.004)))
        c.add(Prim.lathe([V2(0, 0), V2(0.0185, 0), V2(0.0185, 0.0025), V2(0.0165, 0.0035), V2(0, 0.0035)], segments: 32, seamTile: 0.05, material: body),
              Xform(translation: V3(-0.052, 0.049, -0.004)))
        // Shutter button with collar, top LCD and power lever.
        c.add(Prim.lathe([V2(0, 0), V2(0.0115, 0), V2(0.0115, 0.0035), V2(0.0100, 0.0042), V2(0, 0.0042)], segments: 28, seamTile: 0.05, material: metal),
              Xform(translation: V3(0.050, 0.049, 0.014)))
        c.add(Prim.lathe([V2(0, 0), V2(0.0058, 0), V2(0.0058, 0.0052), V2(0.0042, 0.0064), V2(0, 0.0066)], segments: 20, seamTile: 0.05, material: "metal.enamel:B3201C"),
              Xform(translation: V3(0.050, 0.0532, 0.014)))
        c.add(Prim.roundedBox(V3(0.026, 0.0016, 0.016), radius: 0.0006, bevelSegments: 1, material: "glass.display"), Xform(translation: V3(0.050, 0.0498, -0.012)))
        // Rear LCD, eyecup and dial.
        c.add(Prim.roundedBox(V3(0.078, 0.054, 0.0022), radius: 0.002, bevelSegments: 1, material: "glass.display"), Xform(translation: V3(-0.016, -0.008, -0.0258)))
        c.add(Prim.roundedBox(V3(0.034, 0.026, 0.011), radius: 0.005, bevelSegments: 2, material: rubber), Xform(translation: V3(-0.006, 0.060, -0.0385)))
        c.add(Prim.lathe([V2(0, 0), V2(0.0105, 0), V2(0.0105, 0.004), V2(0.0092, 0.0048), V2(0, 0.0048)], segments: 24, seamTile: 0.05, material: metal),
              Xform(translation: V3(0.040, 0.020, -0.0258), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
        // Side lugs with triangle rings and leather tabs.
        for sx: Float in [-1, 1] {
            c.add(Prim.cylinder(radius: 0.0042, height: 0.006, bevel: 0.0008, segments: 14, bevelSegments: 1, material: metal),
                  Xform(translation: V3(sx * 0.073, 0.034, 0), rotation: simd_quatf(degrees: -90 * sx, axis: V3(0, 0, 1))))
            c.add(ShoulderKit.ring(0.014, 0.018, wire: 0.0022, radius: 0.004, sides: 6, material: metal),
                  Xform(translation: V3(sx * 0.0845, 0.037, 0), rotation: simd_quatf(degrees: 90, axis: V3(0, 1, 0))))
        }
        // Gaffer tape label on the grip.
        c.add(Prim.roundedBox(V3(0.030, 0.014, 0.0012), radius: 0.0004, bevelSegments: 1, material: "plastic.matte:CFCBBE"), Xform(translation: V3(0.051, -0.030, 0.0512), rotation: simd_quatf(degrees: 6, axis: V3(0, 0, 1))))
        // Brassing where the paint has worn off the edges.
        for (px, py, pz, sx, sy, sz) in [(Float(-0.006), Float(0.0715), Float(0.0225), Float(0.040), Float(0.0022), Float(0.0035)), (Float(0.073), Float(0.046), Float(0.0), Float(0.0022), Float(0.0035), Float(0.020)),
                                         (Float(-0.073), Float(0.046), Float(0.0), Float(0.0022), Float(0.0035), Float(0.018)), (Float(0.051), Float(0.0), Float(0.0508), Float(0.0036), Float(0.030), Float(0.0014)),
                                         (Float(0.0), Float(-0.049), Float(0.015), Float(0.030), Float(0.0022), Float(0.0035))] {
            c.add(Prim.roundedBox(V3(sx, sy, sz), radius: 0.0007, bevelSegments: 1, material: "metal.brass-aged"), Xform(translation: V3(px, py, pz)))
        }
        // Lens: rotated so its axis runs along +Z, mount at z = 0.025, centred at x = -0.006.
        var lens = Model(name: "lens")
        lens.add(Prim.lathe([V2(0, 0.0), V2(0.0335, 0.0), V2(0.0335, 0.012), V2(0.0325, 0.013), V2(0.0325, 0.034), V2(0.0335, 0.035), V2(0.0335, 0.062),
                             V2(0.0325, 0.063), V2(0.0325, 0.070), V2(0.0335, 0.0715), V2(0.0335, 0.082), V2(0.0300, 0.0835), V2(0.0275, 0.0835),
                             V2(0.0275, 0.080), V2(0, 0.080)], segments: 36, seamTile: 0.08, material: barrel))
        lens.add(Prim.lathe([V2(0.0215, -0.0035), V2(0.0348, -0.0035), V2(0.0348, 0.0), V2(0.0215, 0.0)], segments: 36, seamTile: 0.05, material: metal))
        var ridges: [V2] = [V2(0.0332, 0.0405)]
        for k in 0..<9 {
            let y0 = 0.0405 + Float(k) * 0.0024
            ridges += [V2(0.0344, y0 + 0.0004), V2(0.0344, y0 + 0.0013), V2(0.0334, y0 + 0.0020)]
        }
        ridges.append(V2(0.0332, 0.0405 + 9 * 0.0024))
        lens.add(Prim.lathe(ridges, segments: 36, seamTile: 0.08, material: "plastic.matte:0A0B0C"))
        lens.add(Prim.lathe([V2(0.0334, 0.0145), V2(0.0341, 0.0145), V2(0.0341, 0.0305), V2(0.0334, 0.0305)], segments: 36, seamTile: 0.08, material: "plastic.matte:0A0B0C"))
        lens.add(Prim.lathe([V2(0.0336, 0.0636), V2(0.0343, 0.0636), V2(0.0343, 0.0700), V2(0.0336, 0.0700)], segments: 36, seamTile: 0.08, material: "metal.enamel:B3201C"))
        lens.add(Prim.lathe([V2(0.0276, 0.0820), V2(0.0300, 0.0830), V2(0.0300, 0.0850), V2(0.0276, 0.0850)], segments: 36, seamTile: 0.05, material: metal))
        lens.add(Prim.lathe([V2(0, 0.0770), V2(0.012, 0.0762), V2(0.021, 0.0775), V2(0.0272, 0.0805), V2(0.0272, 0.0815), V2(0, 0.0815)], segments: 36, seamTile: 0.08, material: "glass.lens-coated"))
        lens.add(Prim.lathe([V2(0.0432, 0.1228), V2(0.0446, 0.1228), V2(0.0446, 0.1246), V2(0.0432, 0.1246)], segments: 36, seamTile: 0.05, material: "metal.magnesium-worn"))
        let hood: [V2] = [V2(0.0345, 0.0845), V2(0.0385, 0.0955), V2(0.0425, 0.1095), V2(0.0440, 0.1235), V2(0.0430, 0.1245), V2(0.0415, 0.1105), V2(0.0370, 0.0965), V2(0.0330, 0.0865)]
        lens.add(Prim.lathe(hood, segments: 36, seamTile: 0.08, material: barrel))
        c.add(lens, Xform(translation: V3(-0.006, -0.003, 0.025), rotation: toZ))
        m.add(c, Xform(translation: V3(Cx, Cy, 0), rotation: camQ))

        // ---- Strap: front and back legs from the lugs over the shoulder ----
        let tw: Float = 0.038, tt: Float = 0.0046
        func attach(_ zs: Float) -> V3 { V3(Cx, Cy + 0.040, zs * 0.0845) }
        let over = ShoulderKit.over(x: 0.012, off: 0.0133, steps: 12, legY: -0.09, legSpread: 0.0, legSteps: 3)
        var ctrl: [V3] = [attach(1), V3(0.07, Cy + 0.10, 0.087), V3(0.04, -0.14, 0.078)]
        ctrl += over
        ctrl += [V3(0.04, -0.14, -0.078), V3(0.07, Cy + 0.10, -0.087), attach(-1)]
        let path = catmull(ctrl, per: 2)
        let nf: (V3) -> V3 = { ShoulderKit.bodyNormal($0) }
        let sf = K.frames(path, normal: nf)
        m.add(K.ribbon(sf, width: tw, thick: tt, radius: 0.0015, segments: 1, material: webbing))
        for side: Float in [-1, 1] {
            m.add(K.stitch(along: K.offset(sf, w: side * 0.0145, n: tt / 2 + 0.0003), normal: nf, pitch: 0.012, thread: 0.0007, material: thread))
        }
        // Neoprene pad with diamond quilting.
        let padPts = Array(ShoulderKit.over(x: 0.012, off: 0.0058, steps: 15).dropFirst(1).dropLast(1))
        let pf = K.frames(padPts, normal: nf)
        m.add(K.ribbon(pf, width: 0.074, thick: 0.0105, radius: 0.0048, segments: 3, widthScale: { 0.84 + 0.16 * sin(Float.pi * $0) }, material: pad))
        let step = 3
        for i in stride(from: 0, to: pf.count - step, by: step) {
            for dir: Float in [-1, 1] {
                let a = pf[i], b = pf[i + step]
                m.add(K.stitch(along: [a.p + a.w * (0.026 * dir) + a.n * 0.0053, b.p - b.w * (0.026 * dir) + b.n * 0.0053], normal: nf, pitch: 0.0055, thread: 0.0005, material: thread))
            }
        }
        // Leather ends at the lug rings, sliders on both legs.
        for rng in [0...5, (sf.count - 6)...(sf.count - 1)] {
            let wr = sf[rng].map { f -> K.Frame in var q = f; q.p += q.n * (tt / 2 + 0.0012); return q }
            m.add(K.ribbon(wr, width: tw + 0.004, thick: 0.0026, radius: 0.001, segments: 1, material: "leather.black"))
        }
        for zs: Float in [1, -1] {
            guard let i = sf.firstIndex(where: { $0.p.z * zs > 0 && $0.p.y > -0.30 && $0.p.x > 0.05 }) else { continue }
            let f = sf[i]
            let q = K.basis(f.w, f.t)
            m.add(ShoulderKit.ring(0.046, 0.018, wire: 0.0021, radius: 0.004, sides: 6, material: metal), Xform(translation: f.p + f.n * (tt + 0.0012), rotation: q))
            m.add(Prim.tube([V3(-0.021, 0, 0), V3(0.021, 0, 0)], radii: [0.0021, 0.0021], sides: 8, seamTile: 0.01, material: metal), Xform(translation: f.p + f.n * (tt + 0.0012), rotation: q))
            let j = min(sf.count - 1, max(0, i + (zs > 0 ? -7 : 7)))
            let seg: [K.Frame] = zs > 0 ? Array(sf[j...i].reversed()) : Array(sf[i...j])
            let tail = seg.map { fr -> K.Frame in var t = fr; t.p += t.n * (tt + 0.0006); return t }
            m.add(K.ribbon(tail, width: tw - 0.004, thick: tt * 0.9, radius: 0.0012, segments: 1, widthScale: { 1 - 0.4 * smoothstep(0.85, 1, $0) }, material: webbing))
        }
        // Leather logo patch on the pad, stitched.
        if let mid = pf.indices.first(where: { pf[$0].p.z < 0.004 }) {
            let f = pf[mid]
            let q = K.basis(f.t, f.w)
            m.add(Prim.extrude(Shape2D.roundedRect(0.034, 0.016, radius: 0.0016, segments: 3), depth: 0.0016, bevel: 0.0005, bevelSegments: 1, material: "leather.tan"),
                  Xform(translation: f.p + f.n * 0.0060, rotation: q))
            let lr = Shape2D.roundedRect(0.030, 0.012, radius: 0.001, segments: 2)
            m.add(K.stitch(along: (lr + [lr[0]]).map { f.p + f.t * $0.x + f.w * $0.y + f.n * 0.0070 }, normal: nf, pitch: 0.0028, thread: 0.0004, material: thread))
        }
        return LODModel(m)
    }
}
