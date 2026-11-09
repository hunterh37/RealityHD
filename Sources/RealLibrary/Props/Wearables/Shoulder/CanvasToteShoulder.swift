import simd
import Foundation

/// Natural cotton canvas tote hanging at the left side from two 30 mm webbing handles that loop over the shoulder. The
/// body is a lofted shell that belly-bulges and pinches at a double-stitched turned hem, with a darker lining, piped side
/// seams, a printed ring graphic, two enamel pins and a rolled knit sweater poking out of the mouth. Handle ends are
/// box-X stitched to the bag faces.
public struct CanvasToteShoulder: RealAsset {
    public static let id = "canvas-tote-shoulder"
    public static let summary = "Worn canvas tote on the shoulder: webbing handles, bellied body, hem stitching, enamel pins, sweater."
    public static let tags = ["prop", "wearable", "worn", "fabric"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 50, elevation: 8, distance: 1.7, ground: false, studio: true)

    /// Outer canvas.
    public var canvas: MaterialKey = "fabric.canvas:C8BA99"
    /// Lining canvas.
    public var lining: MaterialKey = "fabric.canvas:8A7C5E"
    /// Handle webbing.
    public var webbing: MaterialKey = "fabric.webbing:C2B48F"
    /// Printed ink.
    public var ink: MaterialKey = "fabric.canvas:1F2C48"
    /// Sweater knit.
    public var knit: MaterialKey = "fabric.knit:6B7A8C"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        typealias K = ChestKit
        let thread: MaterialKey = "fabric.canvas:7A6C4E"
        let cx: Float = 0.118, yTop: Float = -0.12, H: Float = 0.38, yBot = yTop - H
        func tt(_ y: Float) -> Float { (y - yBot) / H }
        func Wz(_ y: Float) -> Float { let t = tt(y); return 0.355 + 0.030 * sin(Float.pi * (t * 0.9 + 0.05)) - 0.012 * t * t * t }
        func Tx(_ y: Float) -> Float { let t = tt(y); return 0.112 + 0.024 * sin(Float.pi * t) - 0.044 * t * t * t }
        func expo(_ y: Float) -> Float { 7.0 - 4.0 * tt(y) }
        let levels = 15, nS = 40
        func outlineRings(_ inset: Float) -> [[V3]] {
            (0..<levels).map { i -> [V3] in
                let y = yBot + H * Float(i) / Float(levels - 1)
                var o = Shape2D.superellipse(Tx(y) - 2 * inset, Wz(y) - 2 * inset, exponent: expo(y), segments: nS)
                for k in o.indices {
                    let ang = Float(k) / Float(nS) * 2 * .pi
                    let wr = 1 + 0.006 * sin(ang * 6 + y * 40) * smoothstep(0.1, 0.5, tt(y))
                    o[k] = V2(o[k].x * wr, o[k].y * wr)
                }
                return Prim.ring(o, y: y, offset: V3(cx, 0, 0))
            }
        }
        m.add(ShoulderKit.facing(Prim.loft(outlineRings(0), capStart: true, material: canvas), outward: true, axisX: cx))
        m.add(ShoulderKit.facing(Prim.loft(outlineRings(0.0042), material: lining), outward: false, axisX: cx))

        // Dirt band at the base, coffee ring stains and a darker, sweat-stained outer handle.
        m.add(ShoulderKit.facing(Prim.loft(Array(outlineRings(-0.0007).prefix(4)), material: "fabric.canvas:B0A07C"), outward: true, axisX: cx))
        for (sy, sz, r) in [(Float(-0.40), Float(-0.10), Float(0.027)), (Float(-0.42), Float(0.06), Float(0.019))] {
            let sx = cx + Tx(sy) / 2 + 0.0008
            let ringPts = (0..<28).map { k -> V3 in let a = Float(k) / 28 * 2 * .pi; return V3(sx, sy + sin(a) * r, sz + cos(a) * r) }
            m.add(Prim.sweep(Shape2D.roundedRect(0.0010, 0.0045, radius: 0.0003, segments: 1), along: ringPts, up: V3(1, 0, 0), closedPath: true, caps: false, material: "fabric.canvas:9A8355"))
        }
        // Turned hem: rolled lip, two stitch rows and piped corner seams.
        let top = outlineRings(0)[levels - 1]
        m.add(Prim.sweep(Shape2D.circle(0.0046, segments: 6), along: top, up: V3(0, 1, 0), closedPath: true, caps: false, material: canvas))
        for dy: Float in [0.012, 0.034] {
            let y = yTop - dy
            let so = Shape2D.superellipse(Tx(y) + 0.0016, Wz(y) + 0.0016, exponent: expo(y), segments: 96)
            let ring = so.map { V3($0.x + cx, y, -$0.y) }
            m.add(K.stitch(along: ring + [ring[0]], normal: { V3($0.x - cx, 0, $0.z).normalized }, pitch: 0.006, thread: 0.0005, material: thread))
        }
        for sz: Float in [-1, 1] {
            let pts = (0..<levels).map { i -> V3 in
                let y = yBot + 0.012 + (H - 0.02) * Float(i) / Float(levels - 1)
                return V3(cx, y, sz * (Wz(y) / 2 + 0.0012))
            }
            m.add(Prim.tube(pts, radii: pts.map { _ in 0.0024 }, sides: 6, seamTile: 0.01, material: canvas, capEnd: false))
        }

        // Printed ring graphic on the outer face.
        let gy: Float = -0.33
        let fx = cx + Tx(gy) / 2 + 0.0006
        for (r, w) in [(Float(0.062), Float(0.0045)), (0.046, 0.0022)] {
            let ringPts = (0..<48).map { k -> V3 in let a = Float(k) / 48 * 2 * .pi; return V3(fx, gy + sin(a) * r, cos(a) * r) }
            m.add(Prim.sweep(Shape2D.roundedRect(0.0012, w, radius: 0.0004, segments: 1), along: ringPts, up: V3(1, 0, 0), closedPath: true, caps: false, material: ink))
        }
        for k in 0..<12 {
            let a = Float(k) / 12 * 2 * .pi + 0.26
            let rd = V3(0, sin(a), cos(a)), tg = V3(0, cos(a), -sin(a))
            m.add(Prim.extrude(Shape2D.roundedRect(0.0035, 0.020, radius: 0.0012, segments: 2), depth: 0.0010, bevel: 0.0003, bevelSegments: 1, material: ink),
                  Xform(translation: V3(fx, gy, 0) + rd * 0.031, rotation: K.basis(tg, rd)))
        }
        m.add(Prim.extrude(Shape2D.circle(0.014, segments: 24), depth: 0.0010, bevel: 0.0003, bevelSegments: 1, material: ink),
              Xform(translation: V3(fx, gy, 0), rotation: K.basis(V3(0, 0, 1), V3(0, 1, 0))))
        // Enamel pins.
        for (i, p) in [(0, V3(0, -0.218, 0.115)), (1, V3(0, -0.238, 0.087))] {
            let q = simd_quatf(from: .up, to: V3(1, 0, 0))
            let pos = V3(cx + Tx(p.y) / 2 + 0.0030, p.y, p.z)
            m.add(Prim.lathe([V2(0, 0), V2(0.0105, 0), V2(0.0108, 0.0012), V2(0.0092, 0.0022), V2(0.0, 0.0022)], segments: 20, seamTile: 0.05, material: "metal.brass"), Xform(translation: pos, rotation: q))
            m.add(Prim.lathe([V2(0, 0.0004), V2(0.0086, 0.0004), V2(0.0086, 0.0026), V2(0, 0.0030)], segments: 20, seamTile: 0.05, material: i == 0 ? "metal.enamel:B3201C" : "metal.enamel:2A6FA8"), Xform(translation: pos, rotation: q))
        }

        // Frayed threads along the hem.
        for k in 0..<18 {
            let z = -0.16 + 0.32 * Float(k) / 17
            let y = yTop - 0.004
            let x = cx + Tx(y) / 2 + 0.0012
            m.add(K.stitch(along: [V3(x, y, z), V3(x + 0.003 * Float(k % 3), y - 0.012 - 0.006 * Float(k % 4), z + 0.004 * Float(k % 2 == 0 ? 1 : -1))], normal: { _ in V3(1, 0, 0) }, pitch: 0.03, thread: 0.0005, material: thread))
        }
        // Rolled sweater in the mouth.
        m.add(Prim.superellipsoid(V3(0.052, 0.13, 0.27), exponent: 4, subdivisions: 7, material: knit) { d in 1 + 0.02 * sin(d.z * 25) * cos(d.y * 18) },
              Xform(translation: V3(cx + 0.004, yTop - 0.004, 0.0), rotation: simd_quatf(degrees: 8, axis: V3(1, 0, 0))))

        // Webbing handles: one on each face, looping over the shoulder.
        let hw: Float = 0.030, ht: Float = 0.0046
        func faceX(_ outerSide: Bool, _ y: Float) -> Float { cx + (outerSide ? 1 : -1) * (Tx(y) / 2 + ht / 2 + 0.0006) }
        for outerSide in [true, false] {
            let sxo: Float = outerSide ? 1 : -1
            let xs: Float = outerSide ? 0.030 : -0.010
            let over = ShoulderKit.over(x: xs, off: ht / 2 + 0.0012, steps: 20, legY: -0.02, legSpread: 0.0, legSteps: 4)
            var ctrl: [V3] = []
            for zs: Float in [1, -1] {
                var side: [V3] = []
                side.append(V3(faceX(outerSide, yTop - 0.10), yTop - 0.10, zs * 0.115))
                side.append(V3(faceX(outerSide, yTop), yTop - 0.012, zs * 0.115))
                side.append(V3(faceX(outerSide, yTop) * 0.6 + xs * 0.4, yTop + 0.035, zs * 0.105))
                side.append(V3(xs + (faceX(outerSide, yTop) - xs) * 0.25, yTop + 0.07, zs * 0.085))
                if zs > 0 { ctrl += side } else { ctrl += side.reversed() }
                if zs > 0 { ctrl += over }
            }
            let path = catmull(ctrl, per: 2)
            let nf: (V3) -> V3 = { p in
                let w = smoothstep(yTop + 0.12, yTop + 0.01, p.y)
                let fn = V3(sxo, 0, 0)
                let bn = ShoulderKit.bodyNormal(p)
                let n = bn * (1 - w) + fn * w
                return simd_length(n) > 1e-4 ? simd_normalize(n) : fn
            }
            let hf = K.frames(path, normal: nf)
            m.add(K.ribbon(hf, width: hw, thick: ht, radius: 0.0015, segments: 1, material: outerSide ? "fabric.webbing:A39369" : webbing))
            for zs: Float in [1, -1] {
                let yy = yTop - 0.060
                let fxp = faceX(outerSide, yy) + sxo * (ht / 2 + 0.0004)
                let pts: [V3] = [V3(fxp, yTop - 0.012, zs * 0.115 - hw / 2 + 0.004), V3(fxp, yTop - 0.012, zs * 0.115 + hw / 2 - 0.004),
                                 V3(fxp, yTop - 0.105, zs * 0.115 + hw / 2 - 0.004), V3(fxp, yTop - 0.105, zs * 0.115 - hw / 2 + 0.004), V3(fxp, yTop - 0.012, zs * 0.115 - hw / 2 + 0.004)]
                m.add(K.stitch(along: pts, normal: { _ in V3(sxo, 0, 0) }, pitch: 0.0048, thread: 0.0006, material: thread))
                m.add(K.stitch(along: [pts[0], pts[2]], normal: { _ in V3(sxo, 0, 0) }, pitch: 0.0048, thread: 0.0006, material: thread))
                m.add(K.stitch(along: [pts[1], pts[3]], normal: { _ in V3(sxo, 0, 0) }, pitch: 0.0048, thread: 0.0006, material: thread))
            }
        }
        return LODModel(m)
    }
}
