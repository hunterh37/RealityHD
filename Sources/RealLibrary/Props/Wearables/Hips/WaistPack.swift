import simd
import Foundation

/// Nylon waist pack (fanny pack) worn at the front: 265 x 115 x 85 mm padded body with a curved top zipper (metal
/// teeth on tape, slider, paracord pull with orange tab), a zipped front pocket with a stitched leather patch,
/// 38 mm webbing waist strap with side-release buckle and tri-glide adjuster, webbing keepers sewn at the pack ends.
public struct WaistPack: RealAsset {
    public static let id = "waist-pack"
    public static let summary = "Worn nylon waist pack: zipped body and front pocket, webbing strap, side-release buckle and adjuster."
    public static let tags = ["prop", "wearable", "worn", "fabric", "plastic", "metal"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 10, distance: 0.9, ground: false, studio: true)

    /// Body nylon (tinted).
    public var nylon: MaterialKey = "fabric.webbing:2B2F35"
    /// Strap webbing.
    public var webbing: MaterialKey = "fabric.webbing:24272B"
    /// Hardware plastic.
    public var plastic: MaterialKey = "plastic.black"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        typealias H = HipsKit
        typealias K = ChestKit
        let nf: (V3) -> V3 = { H.normal($0) }
        let bw: Float = 0.038, bt: Float = 0.0032
        let orange: MaterialKey = "plastic.orange"
        let zip: MaterialKey = "metal.nickel-worn"

        // ---- Strap loop with herringbone ribs ----
        H.band(&m, y: 0, width: bw, thick: bt, radius: 0.0012, segments: 1, stitchInset: 0.0034, pitch: 0.0085, thread: "fabric.nylon:101214", material: webbing)
        // ---- Pack body (flat, wrapped to the waist) ----
        let yc: Float = -0.008, a: Float = 0.1325, b: Float = 0.0575, c: Float = 0.0385, n: Float = 4.8
        let zOff: Float = bt + 0.0010 + c
        func wrap(_ s: Surface, th: Float = 0, y: Float? = nil) { m.add(H.wrapped(s, th: th, y: y ?? yc, off: 0)) }
        func lift(_ s: Surface, _ p: V3) -> Surface { s.transformed(Xform(translation: p)) }
        func surfY(_ x: Float, _ z: Float, _ a: Float, _ b: Float, _ c: Float) -> Float {
            b * pow(max(0.0001, 1 - pow(abs(x) / a, n) - pow(abs(z) / c, n)), 1 / n)
        }
        func surfZ(_ x: Float, _ y: Float, _ a: Float, _ b: Float, _ c: Float) -> Float {
            c * pow(max(0.0001, 1 - pow(abs(x) / a, n) - pow(abs(y) / b, n)), 1 / n)
        }
        let body = Prim.superellipsoid(V3(2 * a, 2 * b, 2 * c), exponent: n, subdivisions: 12, material: nylon)
        wrap(lift(body, V3(0, 0, zOff)))

        // Perimeter piping seams around the body and the pocket.
        func contour(_ a: Float, _ b: Float, _ n: Float, _ cx: Float, _ cy: Float, _ z: Float) -> [V3] {
            (0...56).map { k -> V3 in
                let t = 2 * Float.pi * Float(k) / 56, ca = cos(t), sa = sin(t)
                let x = a * (ca < 0 ? -1 : 1) * pow(abs(ca), 2 / n), y = b * (sa < 0 ? -1 : 1) * pow(abs(sa), 2 / n)
                return V3(cx + x, cy + y, z)
            }
        }
        let bodySeam = contour(a, b, n, 0, 0, zOff)
        wrap(Prim.tube(bodySeam, radii: bodySeam.map { _ in 0.0017 }, sides: 6, seamTile: 0.01, material: "fabric.nylon:1B1D21"))
        // Top zipper: tape, teeth, slider, paracord pull with orange tab.
        let zz: Float = 0.016
        let zpts = (-18...18).map { k -> V3 in
            let x = Float(k) / 18 * (a * 0.88); return V3(x, surfY(x, zz, a, b, c) - 0.0006, zOff + zz)
        }
        wrap(Prim.tube(zpts, radii: zpts.map { _ in 0.0034 }, sides: 6, seamTile: 0.01, material: "fabric.nylon:15171A"))
        wrap(K.stitch(along: zpts.map { $0 + V3(0, 0.0034, 0.0007) }, normal: { _ in V3(0, 1, 0.3) }, pitch: 0.0026, thread: 0.0006, material: zip))
        // Piping along the zipper tape edges.
        for s: Float in [-1, 1] {
            wrap(Prim.tube(zpts.map { $0 + V3(0, 0.0004, s * 0.0034) }, radii: zpts.map { _ in 0.0011 }, sides: 4, seamTile: 0.01, material: "fabric.nylon:1B1D21"))
        }
        let sp = zpts[26]
        wrap(lift(Prim.roundedBox(V3(0.013, 0.0085, 0.0095), radius: 0.0022, bevelSegments: 3, material: zip), sp + V3(0, 0.0036, 0)))
        // Paracord pull through the slider: loop of cord and an orange rubber tab.
        let tx = sp.x + 0.010, ty = sp.y - 0.020, tz = zOff + surfZ(tx, ty, a, b, c) + 0.0016
        let cord = catmull([sp + V3(0, 0.004, 0), sp + V3(0.004, 0.006, 0.010), V3(tx, ty + 0.025, tz + 0.007), V3(tx, ty + 0.017, tz)], per: 6)
        wrap(Prim.tube(cord, radii: cord.map { _ in 0.0015 }, sides: 8, seamTile: 0.01, material: "fabric.nylon:E86A1B"))
        wrap(lift(Prim.extrude(Shape2D.roundedRect(0.009, 0.030, radius: 0.0035, segments: 5), depth: 0.0030, bevel: 0.0010, bevelSegments: 2, material: orange), V3(tx, ty, tz)))

        // Front pocket: separate superellipsoid, own zipper arc, stitched leather patch.
        let pa: Float = 0.095, pb: Float = 0.036, pc: Float = 0.016, py: Float = -0.018
        let pz = zOff + c - 0.004 - 0.001 + pc - 0.006
        let pocket = Prim.superellipsoid(V3(2 * pa, 2 * pb, 2 * pc), exponent: n, subdivisions: 10, material: nylon)
        wrap(lift(pocket, V3(0, py, pz)))
        let ppts = (-14...14).map { k -> V3 in
            let x = Float(k) / 14 * (pa * 0.82); return V3(x, py + surfY(x, pc * 0.55, pa, pb, pc) - 0.0006, pz + pc * 0.55)
        }
        wrap(Prim.tube(ppts, radii: ppts.map { _ in 0.0030 }, sides: 6, seamTile: 0.01, material: "fabric.nylon:15171A"))
        wrap(K.stitch(along: ppts.map { $0 + V3(0, 0.0030, 0.0006) }, normal: { _ in V3(0, 1, 0.3) }, pitch: 0.0026, thread: 0.0006, material: zip))
        let pp = ppts[22]
        wrap(lift(Prim.roundedBox(V3(0.011, 0.0075, 0.0085), radius: 0.002, bevelSegments: 3, material: zip), pp + V3(0, 0.0030, 0)))
        let cord2 = catmull([pp + V3(0, 0.0035, 0), pp + V3(0.004, 0.014, 0.003), pp + V3(0.012, 0.016, 0.007), pp + V3(0.012, 0.006, 0.008)], per: 6)
        wrap(Prim.tube(cord2, radii: cord2.map { _ in 0.0013 }, sides: 8, seamTile: 0.01, material: "fabric.nylon:E86A1B"))
        let pocketSeam = contour(pa, pb, n, 0, py, pz)
        wrap(Prim.tube(pocketSeam, radii: pocketSeam.map { _ in 0.0014 }, sides: 5, seamTile: 0.01, material: "fabric.nylon:1B1D21"))
        // Webbing daisy-chain strips with bar tacks across the pocket.
        for sx: Float in [-1, 1] {
            let x = sx * 0.064
            let zs = pz + surfZ(x, 0, pa, pb, pc) + 0.0006
            let sp2 = (0...8).map { k -> V3 in let yy = py - 0.026 + 0.052 * Float(k) / 8; return V3(x, yy, pz + surfZ(x, yy - py, pa, pb, pc) + 0.0012) }
            _ = zs
            wrap(Prim.tube(sp2, radii: sp2.map { _ in 0.0020 }, sides: 4, seamTile: 0.01, material: webbing))
            for k in stride(from: 0, through: 8, by: 4) {
                wrap(lift(Prim.roundedBox(V3(0.0090, 0.0010, 0.0010), radius: 0.0003, bevelSegments: 1, material: "fabric.nylon:101214"), sp2[k] + V3(0, 0, 0.0016)))
            }
        }
        // Leather patch.
        let pxy = V2(-0.030, -0.040)
        let patchZ = pz + surfZ(pxy.x, pxy.y - py, pa, pb, pc)
        wrap(lift(Prim.extrude(Shape2D.roundedRect(0.036, 0.015, radius: 0.0025, segments: 4), depth: 0.0016, bevel: 0.0005, bevelSegments: 2, material: "leather.tan"), V3(pxy.x, pxy.y, patchZ)))
        wrap(K.stitch(along: HipsKit.rectPath(0.036, 0.015, inset: 0.0026, radius: 0.0025).map { $0 + V3(pxy.x, pxy.y, patchZ + 0.0010) },
                      normal: { _ in V3(0, 0, 1) }, pitch: 0.0030, thread: 0.0004, material: "fabric.canvas:E3D5AA"))
        // Embossed wordmark bars on the patch.
        for k in 0..<3 {
            wrap(lift(Prim.roundedBox(V3(0.022 - Float(k) * 0.005, 0.0012, 0.0006), radius: 0.0003, bevelSegments: 1, material: "leather.black"),
                      V3(pxy.x, pxy.y + 0.0035 - Float(k) * 0.0026, patchZ + 0.0010)))
        }
        for s: Float in [-1, 1] {
            let thk = s * 1.07
            H.keeper(&m, th: thk, y: 0, beltWidth: bw, beltThick: bt, span: 0.020, thick: 0.0024, material: webbing)
            for e: Float in [-1, 1] {
                let st = H.torso(thk + e * 0.07, 0, bt + 0.0026)
                m.add(Prim.cylinder(radius: 0.0017, height: 0.0005, bevel: 0.0002, segments: 12, bevelSegments: 1, material: "fabric.nylon:101214"),
                      Xform(translation: st, rotation: simd_quatf(from: .up, to: nf(st))))
            }
        }

        // ---- Side-release buckle at the wearer's left, tri-glide on the right ----
        let off = bt + 0.0020
        func buckleHalf(_ w: Float, _ h: Float, x: Float, th: Float) {
            let box = Prim.roundedBox(V3(w, h, 0.0090), radius: 0.0030, bevelSegments: 2, material: plastic)
            wrap(lift(box, V3(x, 0, off + 0.0045)), th: th, y: 0)
        }
        buckleHalf(0.038, 0.027, x: -0.013, th: 1.50)
        buckleHalf(0.024, 0.019, x: 0.019, th: 1.50)
        wrap(lift(Prim.roundedBox(V3(0.012, 0.011, 0.0012), radius: 0.0004, bevelSegments: 1, material: "plastic.matte"), V3(-0.016, 0, off + 0.0092)), th: 1.50, y: 0)
        wrap(lift(Prim.cylinder(radius: 0.0018, height: 0.0004, bevel: 0.0001, segments: 12, bevelSegments: 1, material: "plastic.matte"), V3(0.020, 0.0, off + 0.0090)), th: 1.50, y: 0)
        let glide = K.ring(0.034, 0.030, wire: 0.0016, radius: 0.0030, sides: 8, material: plastic)
        let gx = H.place(-1.46, 0, bt + 0.0035)
        m.add(glide, Xform(translation: gx.translation, rotation: gx.rotation))
        // Loose strap tail past the glide, with a sewn bar tack.
        let tpts = (0...16).map { H.torso(-1.52 - 0.34 * Float($0) / 16, 0, bt * 1.5 + 0.0004) }
        m.add(K.ribbon(K.frames(tpts, normal: nf), width: bw - 0.001, thick: bt, radius: 0.0012, segments: 1, material: webbing))
        _ = rng.float()
        return LODModel(m)
    }
}
