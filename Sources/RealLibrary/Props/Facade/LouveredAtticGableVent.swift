import simd
import Foundation

/// Colonial louvered attic gable vent, 0.8 x 0.6 m: painted timber frame with mitred corners, nine sloped
/// louver blades housed in the stiles, galvanized insect screen behind, a sloped sill with drip kerf and
/// screwed backing. Wall face at z = 0.
public struct LouveredAtticGableVent: RealAsset {
    public static let id = "louvered-attic-gable-vent"
    public static let summary = "Colonial louvered attic gable vent, 0.8 x 0.6 m: timber frame, sloped louver blades, galvanized screen, sloped sill."
    public static let tags = ["prop", "architecture", "facade", "wood", "trim"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 22, elevation: 8, distance: 1.0)

    /// Painted frame and blades.
    public var paint: MaterialKey = "wood.painted-exterior:D9D1B8"
    /// Weathered trim where paint has failed.
    public var worn: MaterialKey = "wood.weathered:7D7360"
    /// Insect screen.
    public var screen: MaterialKey = "glass.wire-mesh"
    /// Fasteners.
    public var fixing: MaterialKey = "metal.galvanized-aged"
    /// Louver blade count.
    public var blades = 9
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 0.8, H: Float = 0.6, D: Float = 0.08
        let fw: Float = 0.062, t: Float = 0.042
        let iw = W - fw * 2, ih = H - fw * 2 - 0.02
        let y0: Float = 0.02   // sill slope sits below
        // Back panel behind the screen.
        FA.box(&m, V3(iw, ih, 0.008), V3(0, y0 + fw + ih / 2 - 0.0, 0.004), "wood.painted-exterior:5A5043", r: 0.001)
        // Galvanized screen mesh stretched in a thin frame.
        FA.box(&m, V3(iw, ih, 0.002), V3(0, y0 + fw + ih / 2, 0.012), screen, r: 0.0005)
        FA.box(&m, V3(iw + 0.004, 0.008, 0.007), V3(0, y0 + fw + 0.004, 0.0145), fixing, r: 0.001)
        FA.box(&m, V3(iw + 0.004, 0.008, 0.007), V3(0, y0 + fw + ih - 0.004, 0.0145), fixing, r: 0.001)
        // Frame: stiles full height, mitred rail ends (boxes cut by rotation at corners), rails between.
        for s: Float in [-1, 1] {
            FA.box(&m, V3(fw, H - 0.02, D - 0.02), V3(s * (W / 2 - fw / 2), y0 + (H - 0.02) / 2, (D - 0.02) / 2 + 0.01), paint, r: 0.003)
            // Bead moulding on the inner edge of each stile.
            FA.box(&m, V3(0.012, H - 0.02 - fw * 2, 0.016), V3(s * (W / 2 - fw - 0.006), y0 + (H - 0.02) / 2, D - 0.02 + 0.012), paint, r: 0.005)
        }
        FA.box(&m, V3(iw, fw, D - 0.02), V3(0, y0 + H - 0.02 - fw / 2, (D - 0.02) / 2 + 0.01), paint, r: 0.003)
        FA.box(&m, V3(iw, fw, D - 0.02), V3(0, y0 + fw / 2, (D - 0.02) / 2 + 0.01), paint, r: 0.003)
        // Bead mould round the opening on the top and bottom rails, and a cove-and-fillet drip cap over the head
        // with end returns, so the frame reads as joined joinery rather than a flat border.
        for yy in [y0 + fw + 0.006, y0 + H - 0.02 - fw - 0.006] {
            FA.box(&m, V3(iw, 0.012, 0.016), V3(0, yy, D - 0.02 + 0.012), paint, r: 0.005)
        }
        let capProfile: [V2] = [V2(0, 0), V2(D - 0.004, 0), V2(D - 0.004, 0.006), V2(D - 0.012, 0.01), V2(D - 0.012, 0.016), V2(D - 0.026, 0.02), V2(D - 0.026, 0.026), V2(0, 0.026)]
        FA.run(&m, capProfile, length: W - 0.01, at: V3(0, y0 + H - 0.02 - 0.026, 0), paint, bevel: 0.0015)
        // Mitre joint lines at the four inner corners.
        for sx: Float in [-1, 1] { for top in [false, true] {
            let y = top ? y0 + H - 0.02 - fw : y0 + fw
            FA.box(&m, V3(0.002, 0.085, 0.003), V3(sx * (W / 2 - fw / 2), y + (top ? fw / 2 : -fw / 2), D - 0.0095), worn, r: 0.0005, rot: FA.q(-sx * (top ? 45 : -45), FA.Z))
        } }
        // Louver blades: sloped 38 degrees down toward the outside so rain sheds, each with a drip lip.
        let n = blades
        let pitch = ih / Float(n)
        for i in 0..<n {
            let y = y0 + fw + pitch * (Float(i) + 0.5)
            let mat = rng.chance(0.12) ? worn : paint
            let bl = V3(iw + 0.016, 0.0125, 0.062)
            FA.box(&m, bl, V3(0, y, D / 2 + 0.003), mat, r: 0.002, rot: FA.q(-38, FA.X))
            // Grime streak along the blade top where dust and rain collect.
            FA.box(&m, V3(iw * rng.float(0.35...0.8), 0.0014, 0.02), V3(rng.float(-0.12...0.12), y + 0.0045, D / 2 - 0.004), "wood.painted-exterior:9A9078", r: 0.0003, rot: FA.q(-38, FA.X))
            // Drip lip beneath the leading edge.
            FA.box(&m, V3(iw + 0.012, 0.006, 0.008), V3(0, y - 0.024, D / 2 + 0.024), mat, r: 0.0015, rot: FA.q(-38, FA.X))
        }
        // Slim weather bar behind each blade pair (stile pin): brass-less galvanized pins through stiles.
        for s: Float in [-1, 1] { for i in 0..<n where i % 2 == 0 {
            let y = y0 + fw + pitch * (Float(i) + 0.5)
            FA.cylZ(&m, r: 0.0032, h: 0.0035, at: V3(s * (W / 2 - fw / 2), y, D - 0.0115), fixing, bevel: 0.0007, segments: 8)
        } }
        // Sloped sill under the frame with a drip kerf.
        let sill: [V2] = [V2(0, 0), V2(D, 0), V2(D, 0.014), V2(0.0, 0.045), V2(0, 0.0)]
        FA.run(&m, Shape2D.deduped([V2(0, 0), V2(D, 0.0), V2(D, 0.012), V2(D - 0.018, 0.016), V2(0.0, 0.034)]), length: W - 0.01,
               at: V3(0, 0, 0), paint, bevel: 0.002)
        _ = sill
        // Drip kerf groove line and a rotted corner.
        FA.box(&m, V3(W + 0.01, 0.003, 0.004), V3(0, 0.003, D - 0.008), worn, r: 0.0008)
        FA.box(&m, V3(0.06, 0.03, 0.003), V3(-W / 2 + 0.05, 0.05, D - 0.0105), worn, r: 0.001)
        // Screws through the stiles (slotted heads proud 1 mm).
        for s: Float in [-1, 1] { for k in 0..<4 {
            let y = y0 + 0.06 + Float(k) * (H - 0.14) / 3
            FA.cylZ(&m, r: 0.0045, h: 0.0035, at: V3(s * (W / 2 - fw / 2), y, D - 0.0115), fixing, bevel: 0.0008, segments: 10)
            FA.box(&m, V3(0.007, 0.0012, 0.001), V3(s * (W / 2 - fw / 2), y, D - 0.0075), "metal.rust", r: 0.0003)
        } }
        // Weathering: failed paint patches on frame and lower blades, rust streaks under each stile screw, dirt on the sill.
        var wr = rng.fork(11)
        func blob(_ cx: Float, _ cy: Float, _ rx: Float, _ ry: Float, _ mat: MaterialKey, _ z: Float, _ depth: Float) {
            var pts: [V2] = []
            for k in 0..<9 {
                let a = Float(k) / 9 * 2 * .pi
                let j = wr.float(0.6...1.2)
                pts.append(V2(cx + cos(a) * rx * j, cy + sin(a) * ry * j))
            }
            m.add(Prim.extrude(Shape2D.deduped(pts), depth: depth, bevel: 0.0004, bevelSegments: 1, material: mat), Xform(translation: V3(0, 0, z)))
        }
        let zf: Float = D - 0.0098
        for k in 0..<10 {
            // Peeled paint on the stiles, biased to the lower third where splash and sun reach.
            let sx: Float = k % 2 == 0 ? -1 : 1
            let y = y0 + wr.float(0.05...0.45)
            blob(sx * (W / 2 - fw / 2) + wr.float(-0.012...0.012), y, wr.float(0.008...0.018), wr.float(0.014...0.04), worn, zf, 0.0014)
        }
        for k in 0..<5 {
            blob(wr.float(-0.3...0.3), y0 + fw / 2, wr.float(0.015...0.04), wr.float(0.008...0.016), worn, zf, 0.0014)
        }
        for k in 0..<3 {
            blob(wr.float(-0.3...0.3), y0 + H - 0.02 - fw / 2, wr.float(0.015...0.03), wr.float(0.01...0.016), worn, zf, 0.0014)
        }
        for s: Float in [-1, 1] { for k in 0..<4 {
            let y = y0 + 0.06 + Float(k) * (H - 0.14) / 3
            FA.box(&m, V3(0.004, wr.float(0.03...0.07), 0.0012), V3(s * (W / 2 - fw / 2), y - 0.03, D - 0.0102), "metal.rust", r: 0.0003)
        } }
        FA.box(&m, V3(W - 0.04, 0.006, 0.05), V3(0, 0.02, D - 0.03), "metal.rust-grime", r: 0.001)
        groundAO(&m, height: 0.1, floor: 0.9)
        return LODModel(FC.seatY(FA.centerZ(m)))
    }
}
