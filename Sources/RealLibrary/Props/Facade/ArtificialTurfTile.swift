import simd
import Foundation

/// Artificial turf tile, 2 x 2 m: two 1 m rolls of tufted polyethylene grass laid over a compacted
/// sub-base, meeting at a glued seam. Blades are tufted in stitch rows 16 mm apart on a latex-coated
/// backing, with a brown curled thatch layer and rubber-crumb/sand infill between the tufts. A traffic
/// lane has flattened the pile diagonally; galvanized U-pins hold the perimeter where the backing shows.
public struct ArtificialTurfTile: RealAsset {
    public static let id = "artificial-turf-tile"
    public static let summary = "Artificial turf tile, 2 x 2 m: tufted polyethylene pile on latex-backed rolls over a sub-base, rubber-crumb infill, taped seam and U-pins."
    public static let tags = ["prop", "architecture", "facade", "ground"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 0.75, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.06, 2.0)
    /// Pile height (m).
    public var pile: Float = 0.032
    /// Tuft spacing (m): stitch-row gauge and stitch rate.
    public var gauge: Float = 0.1
    /// Blade greens: two-tone field green plus olive.
    public var bladeKeys: [MaterialKey] = ["plastic.matte:3E7A2A", "plastic.matte:4E8C34", "plastic.matte:5E7A2C"]
    /// Thatch (curled lower fibre).
    public var thatch: MaterialKey = "plastic.matte:6A5A30"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hx = size.x / 2, hz = size.z / 2
        let sub: Float = 0.02, back: Float = 0.004
        let top = sub + back
        // Compacted grey sub-base, a little proud at the edges where it was screeded.
        GTK.field(&m, w: size.x, d: size.z, edge: sub, segments: 8, "ground.gravel:7E7A74", uvScale: 2) { p in 0.002 * Noise.fbm(V3(p.x * 5, 0, p.y * 5), seed: 2) }
        // Two rolls of backing with turf-textured top (pile base), 4 mm seam gap along x = 0 showing jointing tape.
        for s: Float in [-1, 1] {
            let w = hx - 0.004 - 0.02
            GK.box(&m, V3(s * (0.004 + w / 2), sub + back / 2, 0), V3(w, back, size.z - 0.04), "turf.ballpark:4A7A30", r: 0.0015)
        }
        GK.box(&m, V3(0, sub + 0.0008, 0), V3(0.2, 0.0016, size.z - 0.05), "rubber.plate:1E1E1C", r: 0.0005)
        // Traffic lane: pile crushed flat, backing sheen lighter where the fibres lie over.
        for sd: Float in [-1, 1] {
            let lane: [V2] = sd < 0 ? [V2(-0.95, 0.4), V2(-0.02, -0.53), V2(-0.02, -0.1), V2(-0.6, 0.48), V2(-0.95, 0.83)]
                                     : [V2(0.02, -0.57), V2(0.6, -0.95), V2(0.95, -0.95), V2(0.95, -0.7), V2(0.02, 0.0)]
            GK.poly(&m, lane, top: top - 0.001, "turf.ballpark:5E8A3C", thick: 0.0015)
        }
        // Infill: rubber crumb and sand between tufts as a granular skim.
        var lite = m
        GTK.stones(&m, &rng, count: 80, hx: hx - 0.03, hz: hz - 0.03, size: 0.003...0.006, flat: 0.5...0.8,
                   keys: ["rubber.tire:1C1C1C", "rubber.tire:2A2826", "ground.sand:B8A27E"], exponent: 2.6, sink: 0.2,
                   surface: { _ in top }, keep: { abs($0.x) > 0.008 })
        // Tufts: each stitch is a small fan of blades; lane flattens them toward +X.
        var blades = bladeKeys.map { Surface(material: $0) }
        var curl = Surface(material: thatch)
        let lane = { (p: V2) -> Float in exp(-pow((p.x * 0.7 + p.y * 0.7 - 0.2) / 0.22, 2)) }
        let rows = Int((size.z - 0.06) / gauge), cols = Int((size.x - 0.06) / gauge)
        for j in 0..<rows { for i in 0..<cols {
            var r = rng.fork(j * 1000 + i)
            let p = V2(-hx + 0.03 + (Float(i) + 0.5) * gauge + r.float(-0.004...0.004), -hz + 0.03 + (Float(j) + 0.5) * gauge + r.float(-0.003...0.003))
            if abs(p.x) < 0.012 { continue }
            let flat = lane(p)
            let n = 2
            for b in 0..<n {
                let ang = Float(b) / Float(n) * 2 * .pi + r.float(-0.4...0.4)
                let spread = r.float(0.003...0.009) + flat * 0.02
                var lean = V3(cos(ang), 0, sin(ang)) * spread
                lean += V3(0.7, 0, 0.7) * flat * 0.02
                let ht = pile * r.float(0.85...1.05) * (1 - 0.55 * flat)
                let base = V3(p.x + cos(ang) * 0.002, top - 0.001, p.y + sin(ang) * 0.002)
                blades[r.int(0...(blades.count - 1))].append(GTK.blade(base, height: ht, lean: lean, width: 0.0024, material: bladeKeys[0]))
            }
            // Curled thatch fibre at the root.
            if (i + j) % 7 == 0 { curl.append(Prim.superellipsoid(V3(0.012, 0.005, 0.01), exponent: 2, subdivisions: 1, material: thatch),
                        Xform(translation: V3(p.x, top + 0.002, p.y), rotation: simd_quatf(degrees: r.float(0...360), axis: .up))) }
        }}
        for b in blades { m.add(b) }
        m.add(curl)
        // Galvanized U-pins along the perimeter every 0.3 m, through the backing into the sub-base.
        for side in 0..<4 {
            for k in 0..<3 {
                let u = -0.6 + Float(k) * 0.6
                let p: V3 = side < 2 ? V3(u, top, (side == 0 ? -1 : 1) * (hz - 0.035)) : V3((side == 2 ? -1 : 1) * (hx - 0.035), top, u)
                let along: V3 = side < 2 ? V3(1, 0, 0) : V3(0, 0, 1)
                let pin = Prim.tube([p - along * 0.012 + V3(0, -0.01, 0), p - along * 0.012 + V3(0, 0.001, 0), p + along * 0.012 + V3(0, 0.001, 0), p + along * 0.012 + V3(0, -0.01, 0)],
                                    radii: [0.0018, 0.0018, 0.0018, 0.0018], sides: 6, seamTile: 0.02, material: "metal.galvanized-aged")
                m.add(pin); lite.add(pin)
            }
        }
        return GTK.finish(&m, &lite)
    }
}
