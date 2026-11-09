import simd
import Foundation

/// Carpenter's leather tool belt: 60 mm tan belt (5.5 mm, double saddle stitched, riveted) with a nickel prong buckle,
/// a stitched split-leather nail pouch with riveted front pocket on the left, a three-sleeve tool pouch on the
/// right holding a screwdriver, pliers and a carpenter pencil, a yellow tape measure on the belt and a hickory
/// framing hammer hanging from a leather loop at the right hip.
public struct LeatherToolBelt: RealAsset {
    public static let id = "leather-tool-belt"
    public static let summary = "Worn carpenter's tool belt: nail pouch, sleeve pouch with tools, tape measure, hammer loop, stitched tan leather."
    public static let tags = ["prop", "wearable", "worn", "leather", "metal", "wood"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 1.0, ground: false, studio: true)

    /// Belt leather.
    public var leather: MaterialKey = "leather.tan"
    /// Pouch leather.
    public var pouch: MaterialKey = "leather.split-tan"
    /// Hardware.
    public var steel: MaterialKey = "metal.nickel-worn"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        typealias H = HipsKit
        typealias K = ChestKit
        let nf: (V3) -> V3 = { H.normal($0) }
        let bw: Float = 0.060, t: Float = 0.0055
        let thread: MaterialKey = "fabric.canvas:E6D6A6"
        let brass: MaterialKey = "metal.brass-aged"

        // ---- Belt with two stitch rows, tail, buckle ----
        H.band(&m, y: 0, width: bw, thick: t, radius: 0.0018, segments: 1, stitchInset: 0.0040, pitch: 0.0085, thread: thread, material: leather)
        let tailPts = (0...32).map { H.torso(-0.02 + 0.56 * Float($0) / 32, 0, t * 1.5 + 0.0003) }
        let tailF = K.frames(tailPts, normal: nf)
        m.add(K.ribbon(tailF, width: bw - 0.0008, thick: t, radius: 0.0018, segments: 1, widthScale: { 1 - 0.36 * smoothstep(0.82, 1.0, $0) }, material: leather))
        for side: Float in [-1, 1] {
            m.add(K.stitch(along: K.offset(tailF, w: side * (bw / 2 - 0.0040), n: t / 2 + 0.0003).dropFirst(8).map { $0 }, normal: nf, pitch: 0.0085, thread: 0.00047, material: thread))
        }
        for th in [Float(0.22), 0.36] {
            let p = H.torso(th, 0, t * 2 + 0.0004)
            m.add(Prim.cylinder(radius: 0.0025, height: 0.0005, bevel: 0.0002, segments: 20, bevelSegments: 1, material: "leather.black"),
                  Xform(translation: p - nf(p) * 0.0002, rotation: simd_quatf(from: .up, to: nf(p))))
        }
        H.keeper(&m, th: 0.14, y: 0, beltWidth: bw, beltThick: t * 2, thick: 0.0026, material: leather)
        let fx = H.place(0, 0, t * 2 + 0.0034)
        m.add(K.ring(0.066, 0.052, wire: 0.0036, radius: 0.008, sides: 14, material: steel), fx)
        m.add(Prim.tube([V3(-0.0045, -0.026 + 0.001, 0), V3(-0.0045, 0.026 - 0.001, 0)], radii: [0.0033, 0.0033], sides: 14, seamTile: 0.01, material: steel),
              Xform(translation: fx.translation + V3(0, 0, -0.0005), rotation: fx.rotation))
        let prong = catmull([V3(-0.0045, 0.0, 0.0040), V3(0.008, 0, 0.0052), V3(0.022, 0, 0.0024), V3(0.0275, 0, -0.0040)], per: 6)
        m.add(Prim.tube(prong, radii: prong.map { _ in 0.0020 }, sides: 8, seamTile: 0.01, material: steel), fx)

        // ---- Wrapped parts: local x across, y absolute, z from the belt surface ----
        let z0 = t + 0.0012
        func wrap(_ s: Surface, _ th: Float) { m.add(H.wrapped(s, th: th, y: 0, off: 0)) }
        func at(_ s: Surface, _ p: V3, _ q: simd_quatf = .identity) -> Surface { s.transformed(Xform(translation: p, rotation: q)) }
        func panel(_ w0: Float, _ w1: Float, top: Float, bottom: Float, r: Float, depth: Float, bevel: Float, cx: Float = 0, cy: Float? = nil, z: Float, belly: Float = 0, material: MaterialKey) -> Surface {
            let poly = [V2(-w0 / 2, top), V2(w0 / 2, top), V2(w1 / 2, bottom), V2(-w1 / 2, bottom)]
            var s = Prim.extrude(Shape2D.rounded(poly, radius: r), depth: depth, bevel: bevel, bevelSegments: 2, material: material)
            if belly != 0 {
                let hw = max(w0, w1) / 2, mid = (top + bottom) / 2, hh = (top - bottom) / 2
                s.deform { p in
                    let u = min(1, abs(p.x) / hw), v = min(1, abs(p.y - mid) / hh)
                    let k = max(0, 1 - u * u) * max(0, 1 - pow(v, 4)) * smoothstep(-depth * 0.1, depth * 0.5, p.z)
                    return V3(p.x, p.y, p.z + belly * k)
                }
            }
            return at(s, V3(cx, 0, z + depth / 2))
        }

        // Left nail pouch.
        let thL: Float = 0.96
        wrap(panel(0.150, 0.140, top: 0.022, bottom: -0.190, r: 0.010, depth: 0.044, bevel: 0.0045, z: z0, belly: 0.020, material: pouch), thL)
        wrap(panel(0.128, 0.124, top: -0.040, bottom: -0.176, r: 0.008, depth: 0.016, bevel: 0.0030, z: z0 + 0.041, belly: 0.008, material: pouch), thL)
        wrap(at(Prim.roundedBox(V3(0.136, 0.0016, 0.030), radius: 0.0006, bevelSegments: 1, material: "leather.black"), V3(0, 0.0226, z0 + 0.022)), thL)
        wrap(K.stitch(along: HipsKit.rectPath(0.128, 0.136, inset: 0.0052, radius: 0.008).map { $0 + V3(0, -0.108, z0 + 0.0573) },
                      normal: { _ in V3(0, 0, 1) }, pitch: 0.0085, thread: 0.00047, material: thread), thL)
        wrap(K.stitch(along: HipsKit.rectPath(0.150, 0.212, inset: 0.0060, radius: 0.010).map { $0 + V3(0, -0.084, z0 + 0.0443) }.filter { $0.y > -0.036 },
                      normal: { _ in V3(0, 0, 1) }, pitch: 0.0085, thread: 0.00047, material: thread), thL)
        for p in [V3(-0.056, -0.047, 0.0573), V3(0.056, -0.047, 0.0573), V3(-0.066, 0.013, 0.0443), V3(0.066, 0.013, 0.0443), V3(0, 0.013, 0.0443)] {
            var rv = Model(name: "r")
            rivet(&rv, at: V3(p.x, p.y, z0 + p.z), normal: V3(0, 0, 1), radius: 0.0042, segments: 8, material: brass)
            for s in rv.surfaces { wrap(s, thL) }
        }
        // Leather strap loop on the pouch edge and a bit of overall wear: nails poking from the opening.
        for k in 0..<4 {
            let x = -0.040 + Float(k) * 0.026 + rng.float(-0.004...0.004)
            let tilt = rng.float(-0.35...0.35)
            wrap(at(Prim.tube([V3(0, 0, 0), V3(0, 0.026, 0)], radii: [0.0011, 0.0011], sides: 6, seamTile: 0.01, material: "metal.galvanized"),
                    V3(x, 0.0226, z0 + 0.012 + Float(k % 2) * 0.016), simd_quatf(angle: tilt, axis: V3(0, 0, 1))), thL)
        }

        // Right tool pouch with sleeves.
        let thR: Float = -0.98
        wrap(panel(0.122, 0.118, top: 0.022, bottom: -0.148, r: 0.010, depth: 0.030, bevel: 0.0040, z: z0, belly: 0.014, material: pouch), thR)
        wrap(at(Prim.roundedBox(V3(0.108, 0.0016, 0.020), radius: 0.0006, bevelSegments: 1, material: "leather.black"), V3(0, 0.0226, z0 + 0.015)), thR)
        for (i, x) in [Float(-0.038), 0, 0.038].enumerated() {
            wrap(panel(0.034, 0.034, top: -0.030, bottom: -0.136, r: 0.006, depth: 0.011, bevel: 0.0025, cx: x, z: z0 + 0.026, material: pouch), thR)
            for e: Float in [-1, 1] {
                let pts = (0...14).map { k in V3(x + e * 0.0138, -0.036 - 0.092 * Float(k) / 14, z0 + 0.0372) }
                wrap(K.stitch(along: pts, normal: { _ in V3(0, 0, 1) }, pitch: 0.0085, thread: 0.00045, material: thread), thR)
            }
            _ = i
        }
        wrap(K.stitch(along: HipsKit.rectPath(0.122, 0.170, inset: 0.0058, radius: 0.010).map { $0 + V3(0, -0.063, z0 + 0.0303) }.filter { $0.y > -0.028 },
                      normal: { _ in V3(0, 0, 1) }, pitch: 0.0085, thread: 0.00047, material: thread), thR)
        // Sleeve bottom rivets.
        for x in [Float(-0.038), 0, 0.038] {
            var rv = Model(name: "r")
            rivet(&rv, at: V3(x, -0.130, z0 + 0.0375), normal: V3(0, 0, 1), radius: 0.0036, segments: 8, material: brass)
            for s in rv.surfaces { wrap(s, thR) }
        }
        // Tools standing in the sleeves.
        let tz = z0 + 0.0195
        // Screwdriver: ribbed orange handle with black cap.
        let hp: [V2] = [V2(0, 0), V2(0.0075, 0), V2(0.0092, 0.004), V2(0.0098, 0.012), V2(0.0092, 0.020), V2(0.0098, 0.030), V2(0.0108, 0.044), V2(0.0112, 0.056),
                        V2(0.0102, 0.066), V2(0.0072, 0.072), V2(0, 0.0735)]
        wrap(at(Prim.lathe(hp, segments: 28, seamTile: 0.02, material: "plastic.orange"), V3(-0.038, 0.001, tz)), thR)
        wrap(at(Prim.lathe([V2(0, 0), V2(0.0078, 0), V2(0.0095, 0.0022), V2(0.0095, 0.0070), V2(0.0078, 0.0082), V2(0, 0.0082)], segments: 24, seamTile: 0.02, material: "rubber.insulating-black"), V3(-0.038, -0.0067, tz)), thR)
        // Slip-joint pliers: two splayed rubber grips and the steel pivot head hidden in the sleeve.
        for s: Float in [-1, 1] {
            let q = simd_quatf(angle: s * -0.055, axis: V3(0, 0, 1))
            wrap(at(Prim.lathe([V2(0, 0), V2(0.0058, 0), V2(0.0070, 0.004), V2(0.0072, 0.040), V2(0.0066, 0.058), V2(0.0058, 0.060), V2(0, 0.0605)], segments: 20, seamTile: 0.02, material: "rubber.insulating-red"),
                    V3(s * 0.0062, -0.012, tz), q), thR)
        }
        // Carpenter pencil.
        wrap(at(Prim.roundedBox(V3(0.0092, 0.115, 0.0036), radius: 0.0009, bevelSegments: 2, material: "wood.pencil-cedar"), V3(0.038, 0.0075, tz)), thR)
        let tip: [V2] = [V2(0, 0), V2(0.0043, 0), V2(0.0012, 0.0085), V2(0, 0.0090)]
        wrap(at(Prim.lathe(tip, segments: 12, seamTile: 0.01, material: "metal.tool-ground"), V3(0.038, 0.0650, tz)), thR)
        wrap(at(Prim.roundedBox(V3(0.0094, 0.0040, 0.0038), radius: 0.0004, bevelSegments: 1, material: "plastic.black"), V3(0.038, 0.0645, tz)), thR)

        // ---- Tape measure on the belt at the front right ----
        let thT: Float = -0.30
        let tw: Float = 0.072, th: Float = 0.066, td: Float = 0.036
        let tzc = t + 0.0022 + td / 2
        wrap(at(Prim.roundedBox(V3(tw, th, td), radius: 0.011, bevelSegments: 3, material: "plastic.yellow"), V3(0, 0.002, tzc)), thT)
        let bump = Shape2D.roundedRect(tw - 0.002, th - 0.002, radius: 0.0105, segments: 3).map { V3($0.x, $0.y, 0) }
        wrap(at(Prim.sweep(Shape2D.circle(0.0026, segments: 6), along: bump, up: V3(0, 0, 1), closedPath: true, caps: false, material: "rubber.insulating-black"), V3(0, 0.002, tzc)), thT)
        wrap(at(Prim.cylinder(radius: 0.0155, height: 0.0016, bevel: 0.0005, segments: 28, bevelSegments: 1, material: "plastic.black"), V3(0.008, 0.006, tzc + td / 2), simd_quatf(degrees: 90, axis: V3(1, 0, 0))), thT)
        wrap(at(Prim.roundedBox(V3(0.020, 0.012, 0.006), radius: 0.0025, bevelSegments: 2, material: "plastic.black"), V3(-0.018, 0.036, tzc + td / 2 - 0.001)), thT)
        wrap(at(Prim.roundedBox(V3(0.026, 0.0045, 0.0030), radius: 0.001, bevelSegments: 2, material: steel), V3(-0.002, -0.0325, tzc + td / 2 + 0.0008)), thT)

        // ---- Hammer on a leather loop at the right hip ----
        let thH: Float = -1.62
        let hx = H.place(thH, 0, 0)
        func onHip(_ s: Surface, _ p: V3, _ q: simd_quatf = .identity) { m.add(s, Xform(translation: hx.translation + hx.rotation.act(p), rotation: hx.rotation * q)) }
        // Strap riveted on the belt and the loop around the handle.
        let hz = t + 0.0036 + 0.0094
        onHip(Prim.extrude(Shape2D.roundedRect(0.020, 0.062, radius: 0.004, segments: 4), depth: 0.0032, bevel: 0.0010, bevelSegments: 2, material: leather), V3(0, -0.012, t + 0.0016))
        onHip(Prim.sweep(Shape2D.roundedRect(0.022, 0.0034, radius: 0.0012, segments: 1),
                         along: (0..<20).map { k -> V3 in let a = 2 * Float.pi * Float(k) / 20; return V3(cos(a) * 0.0115, 0, sin(a) * 0.0095) },
                         up: V3(0, 1, 0), closedPath: true, caps: false, material: leather), V3(0, -0.026, hz))
        for dy in [Float(0.012), -0.040] {
            rivet(&m, at: hx.translation + hx.rotation.act(V3(0, dy, t + 0.0032)), normal: hx.rotation.act(V3(0, 0, 1)), radius: 0.0038, segments: 10, material: steel)
        }
        // Handle (hickory, oval section) hanging head-up, with a rubberised grip.
        let hand: [V2] = [V2(0, 0), V2(0.0092, 0), V2(0.0098, 0.010), V2(0.0112, 0.045), V2(0.0108, 0.075), V2(0.0112, 0.150), V2(0.0108, 0.190), V2(0, 0.190)]
        var handle = Prim.lathe(hand, segments: 24, seamTile: 0.04, material: "wood.hammer-hickory", swapUV: true)
        handle.deform { V3($0.x * 1.18, $0.y, $0.z * 0.92) }
        onHip(handle, V3(0, -0.195, hz))
        let gripP: [V2] = [V2(0, 0), V2(0.0108, 0), V2(0.0124, 0.004), V2(0.0108, 0.010), V2(0.0124, 0.018), V2(0.0108, 0.024), V2(0.0124, 0.032), V2(0.0108, 0.044),
                           V2(0.0124, 0.054), V2(0.0108, 0.066), V2(0.0125, 0.072), V2(0.0108, 0.078), V2(0, 0.080)]
        var grip = Prim.lathe(gripP, segments: 24, seamTile: 0.02, material: "rubber.insulating-black")
        grip.deform { V3($0.x * 1.12, $0.y, $0.z * 0.92) }
        onHip(grip, V3(0, -0.275, hz))
        // Forged head: poll, eye, curved claw (lathe along Y, laid on the X axis).
        let headP: [V2] = [V2(0.0020, -0.0620), V2(0.0040, -0.0560), V2(0.0062, -0.0420), V2(0.0085, -0.0240), V2(0.0112, -0.0100), V2(0.0124, 0.0), V2(0.0126, 0.0150),
                           V2(0.0112, 0.0200), V2(0.0106, 0.0300), V2(0.0114, 0.0345), V2(0.0126, 0.0360), V2(0.0126, 0.0460), V2(0.0112, 0.0500), V2(0, 0.0505)]
        var head = Prim.lathe(headP, segments: 32, seamTile: 0.03, material: "metal.hammer-forged")
        head.deform { p in V3((p.x - (p.y < -0.012 ? 4.2 * pow(-p.y - 0.012, 2) : 0)) * 1.28, p.y * 1.0, p.z * 1.28) }
        onHip(head, V3(0, -0.0, hz), simd_quatf(degrees: 50, axis: V3(0, 1, 0)) * simd_quatf(degrees: 90, axis: V3(0, 0, 1)))
        return LODModel(m)
    }
}
