import simd
import Foundation

/// Limestone ashlar panel: architectural facade customizer, Neoclassical. Dressed Portland-type limestone
/// blocks in stretcher bond, 340 mm courses with 4 mm lime putty joints, over a rusticated plinth of
/// V-jointed (chamfered) blocks finished with a weathered splay. A moulded band course (fillet, cyma
/// reversa, corona with throated drip, weathered top) caps the panel. Soot crusts in the sheltered zone
/// under the band, run-off streaks, and the odd chipped arris.
public struct LimestoneAshlarPanel: RealAsset {
    public static let id = "limestone-ashlar-panel"
    public static let summary = "Neoclassical limestone ashlar panel, 1.2 m: dressed blocks in stretcher bond over a chamfered plinth, under a moulded band course."
    public static let tags = ["prop", "architecture", "facade", "stone", "trim"]
    public static let budget = 3000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 2.4)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(1.2, 1.2, 0.2)
    /// Ashlar course height (m).
    public var courseHeight: Float = 0.34
    /// Ashlar block length (m).
    public var blockLength: Float = 0.6
    /// Joint width (m).
    public var joint: Float = 0.004
    /// Clean limestone.
    public var stone: MaterialKey = "stone.limestone"
    /// Sooted limestone.
    public var sooted: MaterialKey = "stone.limestone-sooted"
    /// Lime putty joints.
    public var putty: MaterialKey = "concrete.rough:A8A08E"
    /// Stone tones (sRGB hex), Portland whitbed variation.
    public var tones: [UInt32] = [0xD8D2C2, 0xD0C9B6, 0xDCD6C8, 0xC9C1AC]
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, hw = W / 2
        let plinthTop: Float = 0.32, splayTop: Float = 0.36, bandY: Float = splayTop + 2 * courseHeight
        let face: Float = 0.125, plinthFace: Float = 0.15
        // Lime putty bed behind the joints.
        FA.box(&m, V3(W, bandY, face - 0.006), V3(0, bandY / 2, (face - 0.006) / 2), putty, r: 0.001)
        // Dressed block. Ashlar: 3 mm arris round over faint tooling. Rusticated: flat face with a 45 degree
        // chamfer (V-joint) from an extruded outline. A few ashlar arrises carry a chipped corner.
        var n = 0
        func block(_ x0: Float, _ x1: Float, _ y0: Float, _ y1: Float, front: Float, chamfer: Bool, key: MaterialKey) {
            n += 1
            var r = rng.fork(n)
            let w = x1 - x0 - joint, h = y1 - y0 - joint, d: Float = 0.1
            let c = V3((x0 + x1) / 2, (y0 + y1) / 2, front - d / 2)
            if chamfer {
                let e = Prim.extrude(Shape2D.rect(w - 0.008, h - 0.008), depth: d, bevel: 0.03, bevelSegments: 1, material: key)
                m.add(e, Xform(translation: c))
                return
            }
            m.add(Prim.roundedBox(V3(w, h, d), radius: 0.003, bevelSegments: 1, material: key), Xform(translation: c))
            if r.chance(0.3) {
                // Chipped arris: a shallow pale scar where a corner has spalled.
                let sx: Float = r.chance(0.5) ? 1 : -1, sy: Float = r.chance(0.5) ? 1 : -1
                let cw = r.float(0.025...0.05), ch = r.float(0.02...0.04)
                m.add(Prim.roundedBox(V3(cw, ch, 0.004), radius: 0.0015, bevelSegments: 1, material: SWK.tint(stone, 0xE6E0D2)),
                      Xform(translation: V3(c.x + sx * (w / 2 - cw / 2 + 0.001), c.y + sy * (h / 2 - ch / 2 + 0.001), front - 0.0015),
                            rotation: simd_quatf(degrees: r.float(-8...8), axis: V3(0, 0, 1))))
            }
        }
        // Rusticated plinth: one course of 600 mm blocks with chamfered V-joints, damp-darkened.
        var x = -hw
        for (i, l) in [0.3 as Float, 0.6, 0.3].enumerated() {
            block(x, x + l, 0.0, plinthTop, front: plinthFace, chamfer: true, key: SWK.tint(i == 1 ? sooted : stone, i == 1 ? 0xA8A090 : 0xB4AC98))
            x += l
        }
        // Weathered splay: slopes from the plinth face back to the ashlar face.
        let splay: [V2] = [V2(0, 0), V2(plinthFace - 0.002, 0), V2(plinthFace - 0.002, 0.012), V2(face + 0.002, splayTop - plinthTop), V2(0, splayTop - plinthTop)]
        FA.run(&m, splay, length: W, at: V3(0, plinthTop, 0), SWK.tint(stone, 0xC8C0AC), bevel: 0.003)
        // Small astragal where the splay meets the ashlar.
        FA.run(&m, (0...8).map { k -> V2 in let a = Float(k) / 8 * .pi; return V2(face + 0.008 * sin(a), 0.008 - 0.008 * cos(a)) } + [V2(0, 0.016), V2(0, 0)], length: W, at: V3(0, splayTop, 0), SWK.tint(stone, 0xC8C0AC), bevel: 0.001)
        // Ashlar: stretcher bond, perpends on alternate courses offset by half a block.
        for c in 0..<2 {
            let y0 = splayTop + Float(c) * courseHeight
            var xs: [Float] = [-hw]
            var xx = -hw + (c % 2 == 0 ? blockLength : blockLength / 2)
            while xx < hw - 0.01 { xs.append(xx); xx += blockLength }
            xs.append(hw)
            for i in 0..<(xs.count - 1) {
                var r = rng.fork(100 + c * 10 + i)
                // Soot crust in the sheltered top course, a run-off washed block below it.
                let key: MaterialKey = c == 1 && r.chance(0.7) ? SWK.tint(sooted, r.chance(0.5) ? 0x9A9282 : 0xAAA292) : SWK.tint(stone, r.pick(tones))
                block(xs[i], xs[i + 1], y0, y0 + courseHeight, front: face + r.float(0...0.0015), chamfer: false, key: key)
            }
        }
        // Moulded band course: fillet, cyma reversa, corona with throated drip, weathered top.
        // Bottom up: bed fillet, cyma reversa (ogee) bracketing out, corona soffit with a throated drip,
        // 60 mm corona face, then the weathered (sloped) top back to the wall.
        let f0 = face + 0.01
        var prof: [V2] = [V2(0, 0), V2(f0, 0), V2(f0, 0.016)]
        for k in 1...8 {
            let t = Float(k) / 8
            let s = t < 0.5 ? 2 * t * t : 1 - 2 * (1 - t) * (1 - t)
            prof.append(V2(f0 + 0.034 * s, 0.016 + 0.046 * t))
        }
        let cor = size.z - 0.002
        prof += [V2(f0 + 0.034, 0.068), V2(cor - 0.014, 0.068), V2(cor - 0.014, 0.06), V2(cor - 0.007, 0.06), V2(cor - 0.007, 0.068), V2(cor - 0.003, 0.068),
                 V2(cor, 0.071), V2(cor, 0.124), V2(cor - 0.003, 0.127), V2(face + 0.008, size.y - bandY - 0.002), V2(0, size.y - bandY)]
        FA.run(&m, prof, length: W, at: V3(0, bandY, 0), SWK.tint(sooted, 0xBDB5A2), bevel: 0.002)
        // Band joints: two perpends through the moulding.
        for jx: Float in [-0.3, 0.3] {
            FA.box(&m, V3(0.003, size.y - bandY - 0.004, 0.012), V3(jx, bandY + (size.y - bandY) / 2, face + 0.012), putty, r: 0.001)
        }
        // Moss and algae where splash-back keeps the plinth foot damp.
        for i in 0..<7 {
            var r = rng.fork(700 + i)
            SWK.stone(&m, V3(r.float(-0.56...0.56), 0.008, plinthFace - 0.004), V3(r.float(0.04...0.1), r.float(0.012...0.024), 0.03), exponent: 2.4, sub: 2,
                      relief: 0.4, key: "moss.cushion", seed: UInt32(i + 300))
        }
        return SWK.finish(&m, id: Self.id, cap: SWK.tint(stone, tones[0]))
    }
}
