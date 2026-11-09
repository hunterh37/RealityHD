import simd
import Foundation

/// Biker wallet chain on indigo denim: jeans waistband with belt loops, fly and slant-pocket stitching, a 32 mm
/// black leather belt with a nickel prong buckle, a plate belt-loop clip with an eye, 22 individually modelled
/// interlocked stainless curb links swagged around the right hip, a D-ring on a leather tab and an oxblood
/// bifold wallet with cards standing out of a stitched, riveted back pocket.
public struct WalletChain: RealAsset {
    public static let id = "wallet-chain"
    public static let summary = "Worn wallet chain: interlocked steel links from a belt clip to a bifold wallet in a denim back pocket."
    public static let tags = ["prop", "wearable", "worn", "leather", "metal", "fabric", "denim"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: -48, elevation: 8, distance: 0.8, ground: false, studio: true)

    /// Chain metal.
    public var steel: MaterialKey = "metal.stainless"
    /// Denim (tinted).
    public var denim: MaterialKey = "fabric.canvas:2A3F66"
    /// Wallet leather.
    public var leather: MaterialKey = "leather.oxblood-worn"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        typealias H = HipsKit
        typealias K = ChestKit
        let nf: (V3) -> V3 = { H.normal($0) }
        let nickel: MaterialKey = "metal.nickel-worn"
        let thread: MaterialKey = "fabric.canvas:D49A3C"
        let r0: Float = (H.rx + H.rz) / 2

        // ---- Jeans: body, waistband, seams, belt loops ----
        let jTop: Float = 0.022, jBot: Float = -0.225
        // Hips flare toward the hem: radial scale by height, shared by every part that sits on the denim.
        let flare: Float = 0.075
        func F(_ p: V3) -> V3 { let f = 1 + flare * smoothstep(0, 1, min(1, max(0, -p.y / 0.2))); return V3(p.x * f, p.y, p.z * f) }
        var jm = Model(name: "jeans")
        H.band(&jm, y: (jTop + jBot) / 2, width: jTop - jBot, thick: 0.0030, radius: 0.0012, segments: 1, thread: nil, nb: 72, material: denim)
        for var js in jm.surfaces {
            js.deform { p in
                var q = F(p)
                let side = pow(q.x / (H.rx * 1.1), 2)              // 0 front/back, 1 at the hips
                q.y += 0.055 * side * min(1, max(0, (-p.y - 0.03) / 0.19))
                return q
            }
            m.add(js)
        }
        let beltOff: Float = 0.0030, bw: Float = 0.032, t: Float = 0.0045
        for y in [Float(0.0150), -0.0165] {
            let pts = (0...100).map { H.torso(2 * Float.pi * Float($0) / 100, y, 0.0033) }
            m.add(K.stitch(along: pts, normal: nf, pitch: 0.0085, thread: 0.00055, material: thread))
        }
        func P(_ x: Float, _ y: Float, _ off: Float) -> V3 { F(H.torso(x / r0, y, off)) }
        // Belt loops.
        for th in [Float(0.46), -0.46, 1.50, -1.50, Float.pi] {
            H.keeper(&m, th: th, y: 0.001, beltWidth: 0.0382, beltThick: beltOff + t - 0.0002, span: 0.0125, thick: 0.0026, material: denim)
            for e: Float in [-1] {
                let p = H.torso(th, 0.001 + e * 0.0205, beltOff + t + 0.0026)
                rivet(&m, at: p, normal: nf(p), radius: 0.0023, segments: 8, material: "metal.copper")
            }
        }
        // Fly and slant pocket stitching on the front.
        let fly = catmull([V3(0.026, -0.024, 0), V3(0.028, -0.070, 0), V3(0.024, -0.112, 0), V3(0.006, -0.134, 0)], per: 8).map { P($0.x, $0.y, 0.0033) }
        m.add(K.stitch(along: fly, normal: nf, pitch: 0.0085, thread: 0.00055, material: thread))
        for s: Float in [-1, 1] {
            let ctrl: [V3] = [V3(0.092, -0.026, 0), V3(0.084, -0.066, 0), V3(0.070, -0.100, 0), V3(0.046, -0.122, 0)]
            let pts = catmull(ctrl, per: 8).map { P(s * $0.x, $0.y, 0.0033) }
            m.add(K.stitch(along: pts, normal: nf, pitch: 0.0085, thread: 0.00055, material: thread))
        }
        // Jean button under the belt buckle edge and a bartack at the pocket corners.
        for s: Float in [-1, 1] {
            let p = P(s * 0.092, -0.026, 0.0034)
            rivet(&m, at: p, normal: nf(p), radius: 0.0028, segments: 8, material: "metal.copper")
        }

        // ---- Belt ----
        H.band(&m, y: 0, width: bw, thick: t, off: beltOff, radius: 0.0015, segments: 1, stitchInset: 0.0034, pitch: 0.0090, thread: "fabric.canvas:BDB59B", nb: 72, material: "leather.black")
        let tailPts = (0...40).map { H.torso(-0.02 + 0.74 * Float($0) / 40, 0, beltOff + t * 1.5 + 0.0003) }
        let tailF = K.frames(tailPts, normal: nf)
        m.add(K.ribbon(tailF, width: bw - 0.0008, thick: t, radius: 0.0015, segments: 1, widthScale: { 1 - 0.40 * smoothstep(0.84, 1.0, $0) }, material: "leather.black"))
        for th in [Float(0.28), 0.46] {
            let p = H.torso(th, 0, beltOff + t * 2 + 0.0004)
            m.add(Prim.cylinder(radius: 0.0020, height: 0.0005, bevel: 0.0002, segments: 20, bevelSegments: 1, material: "leather.oxblood"),
                  Xform(translation: p - nf(p) * 0.0002, rotation: simd_quatf(from: .up, to: nf(p))))
        }
        let fx = H.place(0, 0, beltOff + t * 2 + 0.0030)
        m.add(K.ring(0.046, 0.036, wire: 0.0027, radius: 0.007, sides: 8, material: nickel), fx)
        m.add(Prim.tube([V3(-0.0035, -0.018 + 0.0008, 0), V3(-0.0035, 0.018 - 0.0008, 0)], radii: [0.0026, 0.0026], sides: 8, seamTile: 0.01, material: nickel),
              Xform(translation: fx.translation + V3(0, 0, -0.0004), rotation: fx.rotation))
        let prong = catmull([V3(-0.0035, 0.0, 0.0034), V3(0.006, 0, 0.0042), V3(0.017, 0, 0.0020), V3(0.0205, 0, -0.0034)], per: 6)
        m.add(Prim.tube(prong, radii: prong.map { _ in 0.0016 }, sides: 8, seamTile: 0.01, material: nickel), fx)

        // ---- Wrapped parts: local x across, y absolute, z from the jeans surface ----
        func wrap(_ s: Surface, _ th: Float) { m.add(H.wrapped(s, th: th, y: 0, off: 0, flare: flare)) }
        func at(_ s: Surface, _ p: V3, _ q: simd_quatf = .identity) -> Surface { s.transformed(Xform(translation: p, rotation: q)) }
        let zj: Float = 0.0030

        // Belt-loop clip plate with an eye.
        let thC: Float = -0.80
        wrap(at(Prim.extrude(Shape2D.roundedRect(0.016, 0.052, radius: 0.0035, segments: 4), depth: 0.0034, bevel: 0.0011, bevelSegments: 2, material: nickel), V3(0, -0.012, beltOff + t + 0.0010 + 0.0017)), thC)
        wrap(at(Prim.cylinder(radius: 0.0030, height: 0.0006, bevel: 0.0002, segments: 20, bevelSegments: 1, material: nickel), V3(0, 0.002, beltOff + t + 0.0010 + 0.0036), simd_quatf(degrees: 90, axis: V3(1, 0, 0))), thC)
        let eyeQ = simd_quatf(degrees: 90, axis: V3(0, 1, 0))
        wrap(at(K.ring(0.009, 0.015, wire: 0.0018, radius: 0.0035, sides: 10, material: nickel), V3(0, -0.039, beltOff + t + 0.0010 + 0.0017), eyeQ), thC)

        // Back pocket (right hip) as a loaded denim block with a wallet standing out of it.
        let thP: Float = -2.60
        let pw: Float = 0.130, pTop: Float = -0.062, pBot: Float = -0.205, pd: Float = 0.022
        let poly = [V2(-pw / 2, pTop), V2(pw / 2, pTop), V2(pw / 2, pBot + 0.030), V2(0, pBot), V2(-pw / 2, pBot + 0.030)]
        wrap(at(Prim.extrude(Shape2D.rounded(poly, radius: 0.007), depth: pd, bevel: 0.0055, bevelSegments: 3, material: denim), V3(0, 0, zj + pd / 2 - 0.002)), thP)
        let zf = zj + pd - 0.002 + 0.0003
        // Gull stitching, hem rows and copper rivets.
        for dy in [Float(0.0055), 0.0120] {
            wrap(K.stitch(along: [V3(-pw / 2 + 0.006, pTop - dy, zf), V3(pw / 2 - 0.006, pTop - dy, zf)], normal: { _ in V3(0, 0, 1) }, pitch: 0.0060, thread: 0.00055, material: thread), thP)
        }
        for s: Float in [-1, 1] {
            let g = catmull([V3(s * 0.058, pTop - 0.022, 0), V3(s * 0.043, pTop - 0.050, 0), V3(s * 0.024, pTop - 0.070, 0), V3(0, pBot + 0.026, 0)], per: 8).map { $0 + V3(0, 0, zf) }
            wrap(K.stitch(along: g, normal: { _ in V3(0, 0, 1) }, pitch: 0.0062, thread: 0.00055, material: thread), thP)
            var rv = Model(name: "r")
            rivet(&rv, at: V3(s * (pw / 2 - 0.0045), pTop - 0.004, zf), normal: V3(0, 0, 1), radius: 0.0030, segments: 8, material: "metal.copper")
            for sf in rv.surfaces { wrap(sf, thP) }
        }
        // Dark pocket mouth.
        wrap(at(Prim.roundedBox(V3(pw - 0.016, 0.0020, pd - 0.010), radius: 0.0006, bevelSegments: 1, material: "fabric.canvas:0E1219"), V3(0, pTop + 0.0004, zj + pd / 2 - 0.002)), thP)
        // Wallet.
        let ww: Float = 0.098, wd: Float = 0.0185, wTop: Float = -0.028
        let wz = zj + pd / 2 - 0.002
        wrap(at(Prim.roundedBox(V3(ww, 0.100, wd), radius: 0.0030, bevelSegments: 3, material: leather), V3(0, wTop - 0.050, wz)), thP)
        // Fold crease along the spine and stitched border.
        wrap(at(Prim.roundedBox(V3(0.0016, 0.094, wd + 0.0006), radius: 0.0006, bevelSegments: 1, material: "leather.oxblood"), V3(-ww / 2 + 0.0010, wTop - 0.050, wz)), thP)
        for sgn: Float in [-1, 1] {
            let zs = wz + sgn * (wd / 2 + 0.0003)
            let pts = HipsKit.rectPath(ww, 0.100, inset: 0.0048, radius: 0.003).map { $0 + V3(0, wTop - 0.050, zs) }.filter { $0.y > wTop - 0.030 }
            wrap(K.stitch(along: pts, normal: { _ in V3(0, 0, sgn) }, pitch: 0.0050, thread: 0.00042, material: "fabric.canvas:E3D5AA"), thP)
        }
        // Cards standing in the slot.
        let cards: [(MaterialKey, Float, Float)] = [("plastic.white", 0.0050, 0.014), ("plastic.gloss", -0.0010, 0.019), ("plastic.black", -0.0060, 0.0095)]
        for (i, (mat, dz, up)) in cards.enumerated() {
            wrap(at(Prim.roundedBox(V3(0.0840, up * 2 + 0.002, 0.0009), radius: 0.0004, bevelSegments: 1, material: mat), V3(Float(i) * 0.0016 - 0.002, wTop - 0.002, wz + dz)), thP)
        }
        // Leather tab with a D-ring toward the front of the hip.
        wrap(at(Prim.extrude(Shape2D.roundedRect(0.026, 0.0090, radius: 0.0030, segments: 4), depth: 0.0030, bevel: 0.0009, bevelSegments: 2, material: leather), V3(ww / 2 + 0.003, wTop - 0.008, wz + wd / 2 + 0.0010)), thP)
        var rvt = Model(name: "r")
        rivet(&rvt, at: V3(ww / 2 - 0.006, wTop - 0.008, wz + wd / 2 + 0.0027), normal: V3(0, 0, 1), radius: 0.0032, segments: 10, material: nickel)
        for sf in rvt.surfaces { wrap(sf, thP) }
        let ringLocal = V3(ww / 2 + 0.0155, wTop - 0.008, wz + wd / 2 + 0.0026)
        wrap(at(K.ring(0.012, 0.017, wire: 0.0017, radius: 0.0045, sides: 10, material: nickel), ringLocal), thP)

        // ---- Chain from the clip eye to the wallet ring ----
        let startTh: Float = thC, startY: Float = -0.0512
        // End point: world position of the ring's outer edge (local -> wrapped).
        func wrapPoint(_ p: V3, th: Float) -> V3 {
            let a = th + p.x / r0
            let q = H.torso(a, p.y, 0)
            return F(V3(q.x, 0, q.z) + nf(q) * p.z + V3(0, q.y, 0))
        }
        let endW = wrapPoint(ringLocal + V3(-0.0085, 0.0, 0), th: thP)
        let startW = H.torso(startTh, startY, beltOff + t + 0.0030)
        // Parametrise the swag around the waist by azimuth.
        let th1 = startTh, th2 = atan2(endW.x / H.rx, endW.z / H.rz)
        let dense: [V3] = (0...320).map { k -> V3 in
            let f = Float(k) / 320
            let th = lerp(th1, th2, f)
            let sag = 0.088 * sin(Float.pi * pow(f, 0.85))
            let y = lerp(startW.y, endW.y, smoothstep(0, 1, f)) - sag
            let off = lerp(0.0165, 0.0075, smoothstep(0.0, 0.45, f)) + 0.0015
            return F(H.torso(th, y, off))
        }
        var d2 = dense
        d2[0] = startW + V3(0, 0, 0.0)
        d2[d2.count - 1] = endW
        H.chain(&m, along: d2, wire: 0.0019, pitch: 0.0142, width: 0.0094, sides: 6, material: steel, rng: &rng)
        // Terminal ring link to the clip eye.
        return LODModel(m)
    }
}
