import simd
import Foundation

/// Arts and Crafts hammered copper mail slot, 0.35 x 0.1 m: dimpled copper face plate with a long slot,
/// a sprung hood flap with turned-over lip, riveted corners and a brass pull strip. Hand hammering is modelled
/// in the plate surface. Wall face at z = 0, hood projects 60 mm.
public struct HammeredCopperMailboxSlot: RealAsset {
    public static let id = "hammered-copper-mailbox-slot"
    public static let summary = "Arts and Crafts hammered copper mail slot, 0.35 m: dimpled plate, sprung hood flap, riveted corners, brass pull."
    public static let tags = ["prop", "architecture", "facade", "metal", "decor"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 14, distance: 0.55)

    /// Copper face plate.
    public var plateMat: MaterialKey = "metal.copper"
    /// Patinated recesses.
    public var patina: MaterialKey = "metal.copper-patina"
    /// Brass hardware.
    public var brass: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 0.35, H: Float = 0.1
        let slotW: Float = 0.26, slotH: Float = 0.026
        // Hammered plate: four pieces around the slot, each subdivided and dimpled with overlapping peen marks.
        let t: Float = 0.0035
        var dimples: [(V2, Float)] = []
        for _ in 0..<90 { dimples.append((V2(rng.float(-W / 2...W / 2), rng.float(-H / 2...H / 2)), rng.float(0.006...0.011))) }
        func piece(_ w: Float, _ h: Float, _ cx: Float, _ cy: Float) {
            // Face: heightfield with peen dimples (terrain is Y-up, rotated to face +Z; its z maps to -y).
            let nx = max(2, Int(w / 0.0045)), ny = max(2, Int(h / 0.0045))
            var face = Surface(material: plateMat)
            for j in 0...ny { for i in 0...nx {
                let x = (Float(i) / Float(nx) - 0.5) * w, y = (Float(j) / Float(ny) - 0.5) * h
                let wx = x + cx, wy = y + cy
                var d: Float = 0
                for (c, r) in dimples {
                    let dd = simd_length(V2(wx, wy) - c)
                    if dd < r { d -= 0.0009 * (1 - dd / r) * (1 - dd / r * 0.3) }
                }
                face.add(V3(x, y, t + d), V3(0, 0, 1), V2(wx, wy))
            } }
            let row = UInt32(nx + 1)
            for j in 0..<UInt32(ny) { for i in 0..<UInt32(nx) {
                let a = j * row + i
                face.quad(a, a + 1, a + row + 1, a + row)
            } }
            face.recomputeNormals(weldSeams: false)
            face.computeTangents()
            m.add(face, Xform(translation: V3(cx, cy + H / 2, 0)))
            FC.brickBox(&m, V3(w, h, t - 0.0016), V3(cx, cy + H / 2, (t - 0.0016) / 2), plateMat, r: 0.0008)
        }
        let sideW = (W - slotW) / 2
        let tb = (H - slotH) / 2
        piece(W, tb, 0, -(H - tb) / 2)                        // bottom band
        piece(W, tb, 0, (H - tb) / 2)                         // top band
        piece(sideW, slotH, -(slotW / 2 + sideW / 2), 0)      // left end
        piece(sideW, slotH, (slotW / 2 + sideW / 2), 0)       // right end
        // Patinated slot reveal: dark cavity behind the slot, plus thin copper reveal walls.
        FA.box(&m, V3(slotW, slotH, 0.006), V3(0, H / 2, -0.003), "metal.parkerized", r: 0.001)
        FA.box(&m, V3(slotW, 0.003, 0.012), V3(0, H / 2 - slotH / 2 + 0.0015, 0.004), patina, r: 0.0006)
        FA.box(&m, V3(slotW, 0.003, 0.012), V3(0, H / 2 + slotH / 2 - 0.0015, 0.004), patina, r: 0.0006)
        // Raised rolled border around the plate: copper wire bent to the outline.
        let bw = W / 2 - 0.004, bh = H / 2 - 0.004
        let border: [V3] = [V3(-bw, H / 2 - bh, 0.0042), V3(bw, H / 2 - bh, 0.0042), V3(bw, H / 2 + bh, 0.0042), V3(-bw, H / 2 + bh, 0.0042), V3(-bw, H / 2 - bh, 0.0042)]
        for i in 0..<4 { FA.rod(&m, border[i], border[i + 1], r: 0.0018, plateMat, sides: 6) }
        // Hood flap: a curved sheet hinged above the slot, hanging past the slot with a turned-over lip.
        var hood: [V3] = []
        for i in 0...10 {
            let u = Float(i) / 10
            let y = H / 2 + slotH / 2 + 0.014 - u * (slotH + 0.032)
            let z = 0.008 + 0.046 * sin(u * .pi * 0.62) * (1 - 0.15 * u)
            hood.append(V3(0, y, z))
        }
        let hprof: [V2] = [V2(-slotW / 2 - 0.012, -0.0016), V2(slotW / 2 + 0.012, -0.0016), V2(slotW / 2 + 0.012, 0.0016), V2(-slotW / 2 - 0.012, 0.0016)]
        var hs = Prim.sweep(hprof, along: hood, up: V3(1, 0, 0), caps: true, material: plateMat)
        hs.displace { p, n in abs(n.z) > 0.6 ? -0.0004 * sin(p.x * 220) * cos(p.y * 260) : 0 }
        m.add(hs)
        // Hinge knuckles and pin along the hood top (copper tube segments over a brass pin).
        let hy = H / 2 + slotH / 2 + 0.014
        FA.rod(&m, V3(-slotW / 2 - 0.012, hy, 0.008), V3(slotW / 2 + 0.012, hy, 0.008), r: 0.0042, plateMat, sides: 10)
        FA.rod(&m, V3(-slotW / 2 - 0.016, hy, 0.008), V3(slotW / 2 + 0.016, hy, 0.008), r: 0.0018, brass, sides: 8)
        // Side cheeks bracing the hood: triangular copper gussets.
        for s: Float in [-1, 1] {
            let prof: [V2] = [V2(0, 0), V2(0.05, 0.004), V2(0.045, 0.02), V2(0.006, 0.036), V2(0, 0.036)]
            m.add(Prim.extrude(prof, depth: 0.0025, bevel: 0.0005, bevelSegments: 1, material: plateMat),
                  Xform(translation: V3(s * (slotW / 2 + 0.0135), hy - 0.034, 0), rotation: FA.q(-90, FA.Y)))
        }
        // Brass pull strip across the lip with two rivets.
        FA.box(&m, V3(0.12, 0.007, 0.004), V3(0, H / 2 - slotH / 2 - 0.0085, 0.047), brass, r: 0.001)
        // Corner rivets (eight, domed copper), plus four brass mounting screws.
        for sx: Float in [-1, 1] { for sy: Float in [-1, 1] {
            rivet(&m, at: V3(sx * (W / 2 - 0.012), H / 2 + sy * (H / 2 - 0.012), t), normal: V3(0, 0, 1), radius: 0.0042, material: brass)
        } }
        for sx: Float in [-1, 1] {
            rivet(&m, at: V3(sx * 0.09, H / 2 - 0.0396 + 0.0, t), normal: V3(0, 0, 1), radius: 0.003, material: plateMat)
            rivet(&m, at: V3(sx * 0.09, H / 2 + 0.0396, t), normal: V3(0, 0, 1), radius: 0.003, material: plateMat)
        }
        // Verdigris in the lower border groove.
        FA.box(&m, V3(0.18, 0.003, 0.0015), V3(0.03, 0.006, 0.0041), patina, r: 0.0005)
        return LODModel(FC.place(m))
    }
}
