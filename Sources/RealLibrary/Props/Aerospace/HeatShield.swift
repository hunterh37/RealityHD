import simd
import Foundation

/// Ablative heat shield for the 1.25 m bus, 0.15 m deep: a shallow spherical dish of PICA-class hex tiles
/// (char varies tile to tile, heaviest at the stagnation point) bonded on a dark substrate, an aluminum
/// carrier ring with a bolted attach flange, and a ribbed back deck with a centre hub.
public struct HeatShield: RealAsset {
    public static let id = "heat-shield"
    public static let summary = "Ablative heat shield, 1.25 m: charred PICA dish in hex tiles on an aluminum carrier ring with bolts."
    public static let tags = ["prop", "aerospace", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: -28, distance: 1.0, studio: true)

    /// Diameter in meters.
    public var diameter: Float = 1.25
    /// Overall depth in meters.
    public var depth: Float = 0.15
    /// Hex tile size (across corners, meters).
    public var tile: Float = 0.13
    /// Carrier structure.
    public var carrier: MaterialKey = "metal.aluminum-brushed"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let R = diameter / 2, sag: Float = 0.06, Rd = R - 0.045
        let dishY: (Float) -> Float = { r in sag * min(r / Rd, 1) * min(r / Rd, 1) }
        let slope: (Float) -> Float = { r in 2 * sag * r / (Rd * Rd) }
        var levels: [Model] = []
        for l in 0..<2 {
            var m = Model(name: Self.id)
            let sg = l == 0 ? 64 : 28
            // Substrate (dark, shows in the tile gaps) and the carrier ring around the rim.
            var sub: [V2] = []
            for k in 0...(l == 0 ? 12 : 6) { let r = Rd * Float(k) / Float(l == 0 ? 12 : 6); sub.append(V2(r, dishY(r) + 0.004)) }
            m.add(Prim.lathe(sub, segments: sg, seamTile: 1, material: "ablative.char-heavy"))
            // Ablator shoulder: toroidal edge segments wrapping the rim (visible from the side), with gaps.
            var sh: [V2] = []
            let nk = l == 0 ? 8 : 4
            for k in 0...nk {
                let t = Float(k) / Float(nk) * .pi / 2
                sh.append(V2(Rd - 0.01 + (R - Rd + 0.01) * sin(t), sag - 0.004 + 0.05 * (1 - cos(t))))
            }
            sh.append(V2(R, sag + 0.062)); sh.append(V2(R - 0.012, sag + 0.064))
            m.add(Prim.lathe(sh, segments: sg, seamTile: 0.4, material: "ablative.char-light"))
            if l == 0 {
                for k in 0..<24 {
                    let a = Float(k) / 24 * 2 * .pi
                    m.add(revPatch(radius: { _ in R }, a0: a - 0.004, a1: a + 0.004, y0: sag + 0.03, y1: sag + 0.06, lift: 0.0006,
                                   thickness: 0.002, nu: 1, nv: 1, material: "ablative.char-heavy"))
                }
            }
            m.add(Prim.lathe([V2(R - 0.012, sag + 0.064), V2(R - 0.003, sag + 0.064), V2(R, sag + 0.067), V2(R, depth - 0.035),
                              V2(R - 0.004, depth - 0.03), V2(R - 0.004, depth - 0.02), V2(R, depth - 0.016), V2(R, depth - 0.004),
                              V2(R - 0.004, depth), V2(R - 0.07, depth), V2(R - 0.07, depth - 0.03), V2(Rd - 0.02, sag + 0.01)],
                             segments: sg, seamTile: 0.5, material: carrier))
            // Back deck: flat plate, centre hub, six radial ribs.
            m.add(Prim.lathe([V2(R - 0.07, depth - 0.03), V2(0.14, depth - 0.03), V2(0.14, depth - 0.006), V2(0.13, depth - 0.002),
                              V2(0.06, depth - 0.002), V2(0.06, depth - 0.02), V2(0, depth - 0.02)], segments: sg, seamTile: 0.5, material: carrier))
            for k in 0..<6 {
                let a = Float(k) / 6 * 2 * .pi
                let len = R - 0.07 - 0.14
                m.add(Prim.roundedBox(V3(0.012, 0.024, len), radius: 0.002, bevelSegments: 1, material: carrier),
                      Xform(translation: V3(sin(a), 0, cos(a)) * (0.14 + len / 2) + V3(0, depth - 0.018, 0), rotation: simd_quatf(angle: a, axis: .up)))
            }
            // Hex tiles on the dish face (down), char heavier toward the centre.
            let s = tile / 2, w = sqrt(3) * s
            let hex = Shape2D.polygon(sides: 6, radius: s - 0.003, rotation: .pi / 6)
            let tileSurfaces = l == 0 ? 3 : 1
            var tiles = (0..<tileSurfaces).map { _ in Surface(material: "ablative.char") }
            let mats: [MaterialKey] = ["ablative.tile-heavy", "ablative.tile", "ablative.tile-light"]
            for i in 0..<tileSurfaces { tiles[i].material = l == 0 ? mats[i] : "ablative.tile" }
            let proto = Prim.extrude(hex, depth: 0.02, bevel: l == 0 ? 0.003 : 0.0015, bevelSegments: 1, material: "ablative.char")
            let nRows = Int(Rd / (1.5 * s)) + 1
            for row in -nRows...nRows {
                for col in -nRows...nRows {
                    let x = Float(col) * w + (row & 1 == 0 ? 0 : w / 2), z = Float(row) * 1.5 * s
                    let r = sqrt(x * x + z * z)
                    if r > Rd - s * 0.6 { continue }
                    let radial = r > 1e-4 ? V3(x / r, 0, z / r) : V3(1, 0, 0)
                    let nOut = simd_normalize(V3(0, -1, 0) + radial * slope(r))
                    let surf = V3(x, dishY(r), z)
                    let q = simd_quatf(from: V3(0, -1, 0), to: nOut) * simd_quatf(degrees: 90, axis: V3(1, 0, 0))
                    // Char class: heavy near the stagnation point, light at the shoulder, with noise.
                    let heat = 1 - r / Rd + rng.float(-0.25...0.25)
                    let cls = l == 0 ? (heat > 0.6 ? 0 : heat > 0.25 ? 1 : 2) : 0
                    tiles[cls].append(proto, Xform(translation: surf + nOut * (0.004 - 0.01), rotation: q))
                }
            }
            for t in tiles { m.add(t) }
            if l == 0 {
                boltCircle(&m, radius: R - 0.035, y: depth, count: 24, phase: rng.float(0...0.1), up: true, size: 0.007, material: "metal.steel")
                boltCircle(&m, radius: 0.1, y: depth - 0.002, count: 8, up: true, size: 0.006, material: "metal.steel")
            }
            groundAO(&m, height: 0.05)
            levels.append(m)
        }
        return LODModel(levels: levels, switchDistances: [8])
    }
}
