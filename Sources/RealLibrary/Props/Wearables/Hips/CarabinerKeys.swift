import simd
import Foundation

/// Belt-clipped key set: black 34 mm leather belt with a nickel prong buckle, a riveted leather tab carrying a
/// D-ring, an anodised screw-gate carabiner threaded through the ring, a split key ring with five cut keys (brass
/// and nickel, individually toothed) and a stitched leather fob. Hangs at the wearer's left hip.
public struct CarabinerKeys: RealAsset {
    public static let id = "carabiner-keys"
    public static let summary = "Worn belt with a screw-gate carabiner on a D-ring tab carrying a split ring of five keys and a leather fob."
    public static let tags = ["prop", "wearable", "worn", "leather", "metal", "brass"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 76, elevation: 6, distance: 0.95, ground: false, studio: true)

    /// Belt leather.
    public var leather: MaterialKey = "leather.black"
    /// Carabiner body.
    public var anodized: MaterialKey = "metal.anodized:2C62C4"
    /// Hardware.
    public var steel: MaterialKey = "metal.nickel-worn"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        typealias H = HipsKit
        typealias K = ChestKit
        let nf: (V3) -> V3 = { H.normal($0) }
        let bw: Float = 0.034, t: Float = 0.0040
        let thread: MaterialKey = "fabric.canvas:BDB59B"

        // ---- Belt, tail, holes, keepers, prong buckle ----
        H.band(&m, y: 0, width: bw, thick: t, radius: 0.0015, segments: 1, stitchInset: 0.0034, pitch: 0.0085, thread: thread, material: leather)
        let tailPts = (0...40).map { H.torso(-0.02 + 0.74 * Float($0) / 40, 0, t * 1.5 + 0.0003) }
        let tailF = K.frames(tailPts, normal: nf)
        m.add(K.ribbon(tailF, width: bw - 0.0008, thick: t, radius: 0.0015, segments: 1, widthScale: { 1 - 0.40 * smoothstep(0.84, 1.0, $0) }, material: leather))
        for side: Float in [-1, 1] {
            m.add(K.stitch(along: K.offset(tailF, w: side * (bw / 2 - 0.0034), n: t / 2 + 0.0003).dropFirst(8).map { $0 }, normal: nf, pitch: 0.0085, thread: 0.00047, material: thread))
        }
        for th in [Float(0.28), 0.46] {
            let p = H.torso(th, 0, t * 2 + 0.0004)
            m.add(Prim.cylinder(radius: 0.0021, height: 0.0005, bevel: 0.0002, segments: 20, bevelSegments: 1, material: "leather.black"),
                  Xform(translation: p - nf(p) * 0.0002, rotation: simd_quatf(from: .up, to: nf(p))))
            m.add(Prim.torus(major: 0.0024, minor: 0.0006, segments: 20, sides: 6, material: steel),
                  Xform(translation: p + nf(p) * 0.0001, rotation: simd_quatf(from: .up, to: nf(p))))
        }
        H.keeper(&m, th: -0.34, y: 0, beltWidth: bw, beltThick: t, material: leather)
        H.keeper(&m, th: 0.17, y: 0, beltWidth: bw, beltThick: t * 2, material: leather)
        let fx = H.place(0, 0, t * 2 + 0.0030)
        m.add(K.ring(0.050, 0.040, wire: 0.0029, radius: 0.007, sides: 12, material: steel), fx)
        m.add(Prim.tube([V3(-0.0035, -0.020 + 0.0008, 0), V3(-0.0035, 0.020 - 0.0008, 0)], radii: [0.0027, 0.0027], sides: 12, seamTile: 0.01, material: steel),
              Xform(translation: fx.translation + V3(0, 0, -0.0004), rotation: fx.rotation))
        let prong = catmull([V3(-0.0035, 0.0, 0.0034), V3(0.006, 0, 0.0044), V3(0.017, 0, 0.0020), V3(0.021, 0, -0.0034)], per: 6)
        m.add(Prim.tube(prong, radii: prong.map { _ in 0.0017 }, sides: 8, seamTile: 0.01, material: steel), fx)

        // ---- Belt tab with D-ring at the left hip ----
        let th0: Float = 1.30
        let tabPts = (0...14).map { H.torso(th0, 0.010 - 0.056 * Float($0) / 14, t + 0.0020) }
        let tabF = K.frames(tabPts, normal: nf)
        _ = tabF
        let tabX = H.place(th0, 0, t + 0.0034)
        func onTab(_ s: Surface, _ p: V3, _ q: simd_quatf = .identity) { m.add(s, Xform(translation: tabX.translation + tabX.rotation.act(p), rotation: tabX.rotation * q)) }
        onTab(Prim.extrude(Shape2D.roundedRect(0.019, 0.060, radius: 0.0045, segments: 5), depth: 0.0034, bevel: 0.0010, bevelSegments: 2, material: leather), V3(0, -0.019, 0))
        for e: Float in [-1, 1] {
            let pts = HipsKit.rectPath(0.019, 0.060, inset: 0.0028, radius: 0.0045).map { $0 + V3(0, -0.019, 0.0021) }
            _ = e
            onTab(K.stitch(along: pts, normal: { _ in V3(0, 0, 1) }, pitch: 0.0055, thread: 0.00042, material: thread), .zero)
            break
        }
        for dy in [Float(0.004), -0.003] { // rivets
            let rp = V3(0, dy - 0.0, 0.0019)
            rivet(&m, at: tabX.translation + tabX.rotation.act(rp), normal: tabX.rotation.act(V3(0, 0, 1)), radius: 0.0036, segments: 12, material: steel)
        }
        // D-ring held by a folded leather bridge.
        let ringY: Float = -0.062
        onTab(Prim.roundedBox(V3(0.019, 0.0085, 0.0085), radius: 0.0028, bevelSegments: 3, material: leather), V3(0, -0.0455, 0.0034))
        let dRing = K.ring(0.026, 0.032, wire: 0.0021, radius: 0.0075, sides: 12, material: steel)
        onTab(dRing, V3(0, ringY + 0.0170, 0.0036))
        // Ring bottom bar sits at y = ringY + 0.0170 - 0.016 relative to tab frame.
        let barY = ringY + 0.0170 - 0.016

        // ---- Carabiner: plane perpendicular to the belt, passing over the D-ring bar ----
        let cy = barY - 0.0281
        let cpoly: [V2] = [V2(-0.0165, -0.036), V2(0.0140, -0.036), V2(0.0165, 0.034), V2(-0.0165, 0.034)]
        let cpath = Shape2D.rounded(cpoly, radius: 0.0125).map { V3($0.x, $0.y, 0) }
        let carbQ = simd_quatf(degrees: -90, axis: V3(0, 1, 0))
        let cb = Prim.sweep(Shape2D.circle(0.0031, ry: 0.0036, segments: 12), along: cpath, up: V3(0, 0, 1), closedPath: true, caps: false, material: anodized)
        func onCarb(_ s: Surface, _ p: V3, _ q: simd_quatf = .identity) { onTab(s, V3(0, cy, 0.0036) + carbQ.act(p), carbQ * q) }
        onCarb(cb, .zero)
        // Gate details: screw sleeve, hinge pin, nose pin.
        onCarb(Prim.cylinder(radius: 0.0048, height: 0.0125, bevel: 0.0012, segments: 28, bevelSegments: 2, seamTile: 0.003, material: "metal.knurl-chrome"), V3(0.0160, 0.0050, 0), simd_quatf(degrees: 0, axis: V3(0, 0, 1)))
        for y in [Float(0.0295), -0.0295] {
            onCarb(Prim.cylinder(radius: 0.0011, height: 0.0085, bevel: 0.0003, segments: 12, bevelSegments: 1, material: steel), V3(y > 0 ? 0.0152 : 0.0140, y, -0.0042), simd_quatf(degrees: 90, axis: V3(1, 0, 0)))
        }
        // Stamped load mark on the spine.
        onCarb(Prim.roundedBox(V3(0.0006, 0.020, 0.0032), radius: 0.0002, bevelSegments: 1, material: "metal.cast-iron-seasoned"), V3(-0.0178, -0.002, 0))

        // ---- Split key ring hanging on the carabiner base ----
        let carbBot = V3(0, cy - 0.036, 0.0036)
        let ringC = carbBot + V3(0, -0.0074 + 0.0, 0)   // in tab frame
        let ringQ = simd_quatf(degrees: 90, axis: V3(1, 0, 0))
        onTab(Prim.torus(major: 0.0115, minor: 0.00088, segments: 36, sides: 6, material: "metal.stainless"), ringC, ringQ)
        onTab(Prim.torus(major: 0.0115, minor: 0.00088, segments: 36, sides: 6, material: "metal.stainless"), ringC + V3(0, 0, 0.0017), simd_quatf(degrees: 91.8, axis: V3(1, 0, 0)))
        // Keys.
        let ringBottom = ringC + V3(0, -0.0115, 0.0008)
        func keyShape(len: Float, teeth: Int) -> Surface {
            var pts: [V2] = [V2(-0.0040, -0.0115), V2(-0.0040, -len + 0.004), V2(-0.0022, -len), V2(0.0030, -len), V2(0.0040, -len + 0.002)]
            let top: Float = -0.0215, bot: Float = -len + 0.0045
            let span: Float = (top - bot) / Float(teeth)
            for k in 0..<teeth {
                let y1: Float = bot + span * Float(k)
                let y0: Float = y1 + span * 0.5
                let d = rng.float(0.0012...0.0030)
                pts.append(V2(0.0040, y1)); pts.append(V2(0.0040 - d, y1 + 0.0004)); pts.append(V2(0.0040 - d, y0)); pts.append(V2(0.0040, y0 + 0.0008))
            }
            pts.append(V2(0.0040, -0.0115))
            return Prim.extrude(pts, depth: 0.0024, bevel: 0.0005, bevelSegments: 1, material: steel)
        }
        let keyDefs: [(Float, Int, MaterialKey, Float)] = [(0.046, 5, "metal.brass-aged", -17), (0.041, 4, steel, -8), (0.044, 5, "metal.brass-aged", 2), (0.038, 4, steel, 10), (0.042, 5, "metal.brass-aged", 20)]
        for (i, (len, teeth, mat, spin)) in keyDefs.enumerated() {
            var ks = keyShape(len: len, teeth: teeth)
            ks.material = mat
            let bowPath = (0..<18).map { k -> V3 in let a = 2 * Float.pi * Float(k) / 18; return V3(cos(a) * 0.0092, sin(a) * 0.0092, 0) }
            var bow = Prim.sweep(Shape2D.roundedRect(0.0024, 0.0072, radius: 0.0008, segments: 1), along: bowPath, up: V3(0, 0, 1), closedPath: true, caps: false, material: mat)
            bow.material = mat
            ks.append(bow)
            let q = simd_quatf(degrees: spin, axis: V3(0, 1, 0)) * simd_quatf(degrees: 90, axis: V3(0, 1, 0)) * simd_quatf(degrees: rng.float(-4...4), axis: V3(0, 0, 1))
            let kx = (Float(i) - 2) * 0.0034
            let ksc = Xform(translation: .zero, rotation: .identity, scale: V3(1.22, 1.22, 1.0))
            ks = ks.transformed(ksc)
            onTab(ks, ringBottom + V3(kx, -0.0058, 0.0), q)
            // Engraved head stamp.
            onTab(Prim.cylinder(radius: 0.0016, height: 0.0003, bevel: 0.0001, segments: 12, bevelSegments: 1, material: "metal.cast-iron-seasoned"),
                  ringBottom + V3(kx, -0.0058, 0.0) + q.act(V3(0, 0, 0.0013)), q * simd_quatf(degrees: 90, axis: V3(1, 0, 0)))
        }
        // Leather fob hanging from the ring on a short loop.
        let fobQ = simd_quatf(degrees: 8, axis: V3(0, 1, 0))
        let fob = Prim.extrude(Shape2D.roundedRect(0.0185, 0.034, radius: 0.0045, segments: 5), depth: 0.0030, bevel: 0.0009, bevelSegments: 2, material: "leather.oxblood-worn")
        onTab(fob, ringBottom + V3(0.014, -0.030, 0.003), fobQ * simd_quatf(degrees: 90, axis: V3(0, 1, 0)))
        return LODModel(m)
    }
}
