import simd
import Foundation

/// Art Deco chevron frieze, 3.0 m: cast stone band carrying triple nested chevrons per 0.25 m bay, a fluted
/// reeded border at each end, stepped-back cornice and base mouldings and a brass inlay line running through the
/// centre of every chevron. Wall face at z = 0.
public struct ArtDecoChevronFrieze: RealAsset {
    public static let id = "art-deco-chevron-frieze"
    public static let summary = "Art Deco chevron frieze, 3.0 m: cast stone band, nested chevrons, stepped mouldings, brass inlay."
    public static let tags = ["prop", "architecture", "facade", "decor", "stone"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 10, distance: 0.95)

    /// Band length in meters.
    public var length: Float = 3.0
    /// Cast stone ground.
    public var stone: MaterialKey = "stone.cast-stone:A89D86"
    /// Lighter stone for the raised chevrons.
    public var raised: MaterialKey = "stone.cast-stone:E6DFCF"
    /// Brass inlay.
    public var brass: MaterialKey = "metal.brass"
    /// Aged brass for the dulled bays.
    public var brassAged: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = length, H: Float = 0.35
        let endW: Float = 0.12
        // Ground slab and stepped mouldings: base fillet, two cornice steps, drip.
        FA.box(&m, V3(L, 0.35, 0.02), V3(0, H / 2, 0.01), stone, r: 0.002)
        FA.box(&m, V3(L, 0.03, 0.036), V3(0, 0.015, 0.018), stone, r: 0.003)
        FA.box(&m, V3(L, 0.024, 0.044), V3(0, H - 0.044, 0.022), stone, r: 0.003)
        FA.box(&m, V3(L, 0.02, 0.056), V3(0, H - 0.022, 0.028), stone, r: 0.003)
        FA.box(&m, V3(L, 0.012, 0.06), V3(0, H - 0.006, 0.03), raised, r: 0.0025)
        // Thin rope-bead between base and field.
        FA.rod(&m, V3(-L / 2 + 0.01, 0.042, 0.022), V3(L / 2 - 0.01, 0.042, 0.022), r: 0.004, stone, sides: 8)
        // Reeded end blocks, 6 half-round reeds each.
        for s: Float in [-1, 1] {
            let x0 = s * (L / 2 - endW / 2)
            FA.box(&m, V3(endW, H - 0.06, 0.03), V3(x0, H / 2 - 0.0, 0.017), raised, r: 0.003)
            for k in 0..<6 {
                let rx = x0 - endW / 2 + 0.01 + Float(k) * (endW - 0.02) / 5
                FA.cylZ(&m, r: 0.0075, h: 0.0, at: V3(rx, 0, 0), stone, segments: 4)
                m.add(Prim.cylinder(radius: 0.0072, height: H - 0.1, bevel: 0.002, segments: 10, bevelSegments: 1, material: raised),
                      Xform(translation: V3(rx, 0.05, 0.034)))
            }
        }
        // Chevrons: a V band with three nesting rings per bay; the point projects downward in the field.
        let fieldL = L - endW * 2 - 0.04
        let bays = Int((fieldL / 0.25).rounded())
        let bay = fieldL / Float(bays)
        let fy0: Float = 0.06, fy1: Float = H - 0.06
        let fieldH = fy1 - fy0
        for i in 0..<bays {
            let cx = -fieldL / 2 + (Float(i) + 0.5) * bay
            for r in 0..<3 {
                let hw = bay / 2 - 0.012
                let rise: Float = 0.097
                let t: Float = 0.026
                let ytop = fy0 + 0.197 - Float(r) * 0.045
                let outline: [V2] = [V2(-hw, ytop), V2(0, ytop - rise), V2(hw, ytop), V2(hw, ytop + t), V2(0, ytop - rise + t), V2(-hw, ytop + t)]
                let mat = (r == 1) ? raised : stone
                m.add(Prim.extrude(outline, depth: 0.02, bevel: 0.0018, bevelSegments: 1, material: mat),
                      Xform(translation: V3(cx, 0, 0.03)))
            }
            // Brass inlay: V line along the centre of the middle chevron, with the occasional dulled bay.
            let hw = bay / 2 - 0.012
            let ytop = fy0 + 0.197 - 0.045
            let mat = rng.chance(0.2) ? brassAged : brass
            for s: Float in [-1, 1] {
                let a = V3(cx, ytop - 0.097 + 0.013, 0.0405), b = V3(cx + s * hw, ytop + 0.013, 0.0405)
                FA.rod(&m, a, b, r: 0.0028, mat, sides: 6)
            }
            // Small stone lozenge between chevron points.
            let lz: [V2] = [V2(0, 0.0), V2(0.014, 0.014), V2(0, 0.028), V2(-0.014, 0.014)]
            m.add(Prim.extrude(lz, depth: 0.012, bevel: 0.0012, bevelSegments: 1, material: raised), Xform(translation: V3(cx + bay / 2, fy0 + 0.1, 0.026)))
        }
        // Chipped corner: replacement stone patch at the right cornice.
        FA.box(&m, V3(0.08, 0.02, 0.0025), V3(0.9, H - 0.022, 0.0575), "stone.limestone", r: 0.0006)
        // Weathering: soot under the cornice, damp staining above the base, efflorescence on the raised chevrons, chipped arrises.
        var wr = rng.fork(41)
        func blob(_ cx: Float, _ cy: Float, _ rx: Float, _ ry: Float, _ mat: MaterialKey, _ z: Float, _ depth: Float) {
            var pts: [V2] = []
            for k in 0..<9 {
                let a = Float(k) / 9 * 2 * .pi
                let j = wr.float(0.6...1.2)
                pts.append(V2(cx + cos(a) * rx * j, cy + sin(a) * ry * j))
            }
            m.add(Prim.extrude(Shape2D.deduped(pts), depth: depth, bevel: 0.0003, bevelSegments: 1, material: mat), Xform(translation: V3(0, 0, z)))
        }
        for _ in 0..<16 {
            blob(wr.float(-L / 2 + 0.2...L / 2 - 0.2), H - 0.07 - wr.float(0...0.06), wr.float(0.01...0.04), wr.float(0.012...0.035), "stone.cast-stone:6F665A", 0.0201, 0.0012)
        }
        for _ in 0..<10 {
            blob(wr.float(-L / 2 + 0.2...L / 2 - 0.2), 0.06 + wr.float(0...0.03), wr.float(0.03...0.08), wr.float(0.01...0.02), "stone.cast-stone:7C7364", 0.0201, 0.0012)
        }
        for _ in 0..<8 {
            blob(wr.float(-L / 2 + 0.2...L / 2 - 0.2), wr.float(0.1...0.28), wr.float(0.008...0.02), wr.float(0.004...0.01), "stone.limestone", 0.0402, 0.0012)
        }
        groundAO(&m, height: 0.05, floor: 0.92)
        return LODModel(FC.seatY(FA.centerZ(m)))
    }
}
