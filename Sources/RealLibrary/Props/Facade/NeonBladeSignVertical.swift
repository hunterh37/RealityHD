import simd
import Foundation

/// Mid-century Commercial vertical neon sign, 0.6 x 2.0 x 0.25 m: a sheet steel can cabinet with welded mounting ears and lag bolts,
/// a cream enamel face with a red border band, five stacked letters (H O T E L) bent from glass tube on porcelain-post standoffs over
/// black raceway plates, a cyan border tube, brass-capped electrodes with GTO boots, a rooftop transformer box with conduit to the
/// wall. One tube section is dead (frosted), the enamel is chipped and rust runs from the bolts. Base on y = 0.
public struct NeonBladeSignVertical: RealAsset {
    public static let id = "neon-blade-sign-vertical"
    public static let summary = "Mid-century Commercial vertical neon blade sign, 0.6 x 2.0 m: steel cabinet, glass neon tubes, standoffs, transformer, wall brackets, conduit."
    public static let tags = ["prop", "architecture", "facade", "sign", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 22, elevation: 5, distance: 3.6)

    /// Cabinet width in meters.
    public var cabinetWidth: Float = 0.5
    /// Cabinet height in meters.
    public var cabinetHeight: Float = 1.8
    /// Letter tube.
    public var letters: MaterialKey = "emissive.signal-red"
    /// Border tube.
    public var border: MaterialKey = "emissive.thruster-cyan"
    /// Cream enamel face.
    public var face: MaterialKey = "metal.painted:E4DABB"
    /// Cabinet returns, dark teal.
    public var can: MaterialKey = "metal.painted:2F4C57"
    public var rust: MaterialKey = "metal.rust"
    public var brass: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let cw = cabinetWidth, ch = cabinetHeight
        let y0: Float = 0.04, zc0: Float = 0.04, depth: Float = 0.16
        let cy = y0 + ch / 2
        let zFace = zc0 + depth

        // Cabinet can with returns, a seam line and rolled rim; face panel and border band on the front.
        FA.box(&m, V3(cw, ch, depth), V3(0, cy, zc0 + depth / 2), can, r: 0.008)
        FO.slab(&m, cw - 0.012, ch - 0.012, 0.006, V3(0, cy, zFace + 0.002), face, bevel: 0.0015)
        let bw: Float = 0.026
        FO.slab(&m, cw - 0.012, bw, 0.004, V3(0, y0 + ch - 0.006 - bw / 2, zFace + 0.0055), "metal.painted:A82E26", bevel: 0.001)
        FO.slab(&m, cw - 0.012, bw, 0.004, V3(0, y0 + 0.006 + bw / 2, zFace + 0.0055), "metal.painted:A82E26", bevel: 0.001)
        for s: Float in [-1, 1] { FO.slab(&m, bw, ch - 0.012 - 2 * bw, 0.004, V3(s * (cw / 2 - 0.006 - bw / 2), cy, zFace + 0.0055), "metal.painted:A82E26", bevel: 0.001) }
        // Spot-welded seam rivets down the sides of the face.
        for s: Float in [-1, 1] {
            var ry = y0 + 0.07
            while ry < y0 + ch - 0.05 {
                rivet(&m, at: V3(s * (cw / 2 - 0.006 - bw / 2), ry, zFace + 0.0075), normal: FA.Z, radius: 0.0042, segments: 6, material: "metal.painted:C9C0A4")
                ry += 0.14
            }
        }

        // Welded mounting ears with lag bolts at four corners (the 0.6 m overall width).
        for s: Float in [-1, 1] {
            for y in [y0 + 0.1, y0 + ch - 0.1] {
                FA.box(&m, V3(0.055, 0.075, 0.008), V3(s * (cw / 2 + 0.0275), y, 0.046), can, r: 0.002)
                hexBolt(&m, at: V3(s * (cw / 2 + 0.03), y, 0.05), normal: FA.Z, size: 0.014, material: rust)
                FO.slab(&m, 0.012, 0.09, 0.0016, V3(s * (cw / 2 + 0.034), y - 0.08, 0.0502), "metal.rust:7A4A2E", bevel: 0.0004)
            }
        }

        // Rooftop transformer: gray steel box with louvres, high-voltage boots, EMT conduit to the wall.
        let tx: Float = -0.06, ty = y0 + ch + 0.07
        FA.box(&m, V3(0.22, 0.14, 0.09), V3(tx, ty, 0.1), "metal.painted:6C706B", r: 0.004)
        for i in 0..<5 { FO.slab(&m, 0.16, 0.005, 0.003, V3(tx, ty - 0.04 + Float(i) * 0.02, 0.1 + 0.0465), "metal.painted:3C3F3C", bevel: 0.0008) }
        for dx: Float in [-0.07, 0.07] {
            m.add(Prim.lathe([V2(0, 0), V2(0.012, 0), V2(0.01, 0.02), V2(0.005, 0.03), V2(0, 0.03)], segments: 8, seamTile: 0.05, material: "rubber.insulating-black"),
                  Xform(translation: V3(tx + dx, ty - 0.07 - 0.0, 0.1), rotation: FA.q(180, FA.X)))
            FA.rod(&m, V3(tx + dx, ty - 0.07, 0.1), V3(tx + dx, ty - 0.1, 0.145), r: 0.004, "rubber.insulating-black", sides: 6)
        }
        FA.rod(&m, V3(tx - 0.11, ty, 0.1), V3(tx - 0.16, ty, 0.012), r: 0.011, "metal.galvanized-aged", sides: 10)
        m.add(Prim.torus(major: 0.011, minor: 0.0025, segments: 10, sides: 4, material: "metal.galvanized-aged"), Xform(translation: V3(tx - 0.156, ty, 0.02), rotation: FA.q(90, FA.X)))

        // Letters: H O T E L stacked top to bottom, each over a black raceway plate, tubes on porcelain posts.
        let zt: Float = 0.246
        func tube(_ pts: [V2], _ mat: MaterialKey, at c: V2, endcaps: Bool = true) {
            let p = pts.map { V3(c.x + $0.x, c.y + $0.y, zt) }
            m.add(Prim.tube(p, radii: Array(repeating: 0.0065, count: p.count), sides: 6, seamTile: 0.08, material: mat, capEnd: true))
            // Posts along the tube, every ~0.12.
            var acc: Float = 0
            for i in 0..<p.count {
                if i > 0 { acc += simd_distance(p[i], p[i - 1]) }
                if i == 0 || i == p.count - 1 || acc > 0.12 {
                    if acc > 0.12 { acc = 0 }
                    FA.cylZ(&m, r: 0.0055, h: 0.03, at: V3(p[i].x, p[i].y, zFace + 0.012), "ceramic.porcelain-gray", bevel: 0.0008, segments: 8)
                }
            }
            if endcaps {
                for e in [p.first!, p.last!] {
                    FC.bead(&m, r: 0.0085, at: e + V3(0, 0, 0), brass, sub: 2)
                    FA.rod(&m, V3(e.x, e.y, zt), V3(e.x, e.y, zFace + 0.008), r: 0.0042, "rubber.insulating-black", sides: 5)
                }
            }
        }
        let word: [Character] = ["H", "O", "T", "E", "L"]
        for (i, ch0) in word.enumerated() {
            let c = V2(0, 1.5 - Float(i) * 0.3 + 0.0)
            FO.slab(&m, 0.25, 0.31, 0.012, V3(c.x, c.y, zFace + 0.0085), "metal.painted:191B1D", bevel: 0.002)
            switch ch0 {
            case "H":
                tube([V2(-0.08, -0.12), V2(-0.08, 0.12)], letters, at: c)
                tube([V2(0.08, -0.12), V2(0.08, 0.12)], letters, at: c)
                tube([V2(-0.08, 0), V2(0.08, 0)], letters, at: c)
            case "O":
                var pts: [V2] = []
                for k in 0...26 {
                    let a = (-75 + Float(k) / 26 * 330) * .pi / 180
                    pts.append(V2(0.085 * cos(a), 0.12 * sin(a)))
                }
                tube(pts, letters, at: c)
            case "T":
                tube([V2(-0.09, 0.12), V2(0.09, 0.12)], letters, at: c)
                tube([V2(0, 0.12), V2(0, -0.12)], letters, at: c)
            case "E":
                tube([V2(0.08, 0.12), V2(-0.07, 0.12), V2(-0.07, -0.12), V2(0.08, -0.12)], letters, at: c)
                tube([V2(-0.07, 0), V2(0.05, 0)], "glass.frosted", at: c)       // dead section
            default:
                tube([V2(-0.07, 0.12), V2(-0.07, -0.12), V2(0.08, -0.12)], letters, at: c)
            }
        }
        // Border tube: rounded rectangle on the enamel, 0.04 m inside the red band, with a gap at the lower right for the electrodes.
        var loop = Shape2D.roundedRect(cw - 0.12, ch - 0.12, radius: 0.05, segments: 5)
        loop = Shape2D.deduped(loop)
        let n = loop.count
        let start = n - 5
        var ordered: [V2] = []
        for k in 0..<(n - 6) { ordered.append(loop[(start + 3 + k) % n]) }
        tube(ordered.map { V2($0.x, $0.y + ch / 2 + y0 - 0.0) }, border, at: V2(0, 0))

        // Wear: chipped enamel on the face, rust runs under the bolts and at the can seams, grime along the bottom edge.
        for _ in 0..<12 {
            let wx = rng.float(-cw / 2 + 0.04...cw / 2 - 0.04), wy = rng.float(y0 + 0.05...y0 + ch - 0.05)
            FO.slab(&m, rng.float(0.008...0.03), rng.float(0.006...0.02), 0.0012, V3(wx, wy, zFace + 0.0053), rng.chance(0.5) ? "metal.painted:6A6354" : "metal.rust:8A5636", bevel: 0.0003)
        }
        for _ in 0..<5 {
            let wx = rng.float(-cw / 2 + 0.05...cw / 2 - 0.05)
            FO.slab(&m, rng.float(0.01...0.02), rng.float(0.06...0.16), 0.0012, V3(wx, y0 + 0.12 + rng.float(0...0.08), zFace + 0.0053), "metal.painted:8C7C62", bevel: 0.0003)
        }
        FO.slab(&m, cw - 0.03, 0.028, 0.0012, V3(0, y0 + 0.04, zFace + 0.0053), "metal.painted:70675A", bevel: 0.0003)
        for s: Float in [-1, 1] { FO.slab(&m, 0.01, ch * 0.5, 0.0012, V3(s * (cw / 2 + 0.0002), cy - ch * 0.2, zc0 + depth * 0.5), "metal.rust:7A4A2E", bevel: 0.0003) }

        groundAO(&m, height: 0.1, floor: 0.88)
        return LODModel(FC.place(m))
    }
}
