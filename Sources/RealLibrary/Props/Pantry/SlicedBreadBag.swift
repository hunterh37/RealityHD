import simd
import Foundation

/// Sliced bread bag: everyday pantry, plastic bag. 30 cm bag lying on its side, 12 cm tall and 10 cm deep: clear
/// film loft with wrinkles that closes into a flat crimped seam at one end and a gathered, twisted neck at
/// the other with a blue tag clip. Eleven sliced bread slices (crust ring, crumb face) show through the
/// film, and a printed golden label band with text bars wraps the middle. One slice leans out of line.
public struct SlicedBreadBag: RealAsset {
    public static let id = "sliced-bread-bag"
    public static let summary = "Plastic bag of sliced bread with crimped seam, gathered neck and a colored tag clip."
    public static let tags = ["prop", "interior", "pantry", "plastic", "food"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 28, distance: 0.8, studio: true)

    /// Film.
    public var film: MaterialKey = "plastic.clear"
    /// Printed label band.
    public var label: MaterialKey = "plastic.matte:D9B36A"
    /// Tag clip.
    public var clip: MaterialKey = "plastic.matte:2F6DB3"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let segs = 28
        // Pre-frame: bag length along +Y, section axes (x = up, z = side). Rotated onto +X at the end.
        var pre = Model(name: "bag")
        func ring(_ y: Float, _ a: Float, _ b: Float, _ ex: Float) -> [V3] { Prim.ring(DD1IPantry.superSection(a, b, ex: ex, segs: segs), y: y) }
        let rs: [[V3]] = [ring(0.0, 0.052, 0.0025, 5), ring(0.012, 0.056, 0.008, 4.4), ring(0.03, 0.0595, 0.034, 3.4), ring(0.06, 0.0605, 0.0505, 3.1),
                          ring(0.1, 0.0605, 0.0525, 3.0), ring(0.2, 0.0605, 0.0525, 3.0), ring(0.235, 0.056, 0.0485, 2.9), ring(0.262, 0.032, 0.03, 2.4),
                          ring(0.28, 0.0125, 0.0125, 2.0), ring(0.29, 0.0105, 0.0105, 2.0), ring(0.297, 0.013, 0.013, 2.0)]
        var f = Prim.loft(rs, capStart: true, capEnd: true, material: film)
        f.displace { p, _ in 0.0011 * sin(p.y * 90 + p.x * 40) * sin(p.z * 70 + p.y * 30) }
        pre.add(f)
        // Printed label band, slightly proud of the film.
        var band = Prim.loft([ring(0.095, 0.0611, 0.0531, 3.0), ring(0.17, 0.0611, 0.0531, 3.0)], material: label)
        band.recomputeNormals()
        pre.add(band)
        for (i, w) in ([0.06, 0.045, 0.03] as [Float]).enumerated() {
            pre.add(Prim.roundedBox(V3(0.0006, 0.0045, w), radius: 0.0002, bevelSegments: 1, material: "plastic.matte:F1EDE2"),
                    Xform(translation: V3(0.0617, 0.145 - Float(i) * 0.0085, 0)))
        }
        pre.add(Prim.extrude(Shape2D.circle(0.016, segments: 20), depth: 0.0007, bevel: 0.0002, bevelSegments: 1, material: "plastic.matte:B5452F"),
                Xform(translation: V3(0.0617, 0.112, 0), rotation: simd_quatf(degrees: 90, axis: V3(0, 1, 0))))
        // Crimped seam ridges across the flat end.
        for k in 0..<7 {
            pre.add(Prim.roundedBox(V3(0.098, 0.0011, 0.0042), radius: 0.0003, bevelSegments: 1, material: film),
                    Xform(translation: V3(0, 0.0028 + Float(k) * 0.0023, 0)))
        }
        // Creases across the film, a small tear at the crimp and grime on the label's lower edge.
        for k in 0..<5 {
            let y = rng.float(0.05...0.23), a = rng.float(0.2...1.2)
            let pts = (0...5).map { i -> V3 in
                let t = Float(i) / 5 * 2 - 1
                return V3(0.0612 * cos(t * 1.3 + a) * 0.98, y + t * 0.012 * (k % 2 == 0 ? 1 : -1), 0.0535 * sin(t * 1.3 + a))
            }
            pre.add(Prim.tube(pts, radii: Array(repeating: 0.00055, count: 6), sides: 3, seamTile: 0.01, material: "plastic.matte:E6E8EA"))
        }
        var grimeBand = Prim.loft([ring(0.095, 0.0613, 0.0533, 3.0), ring(0.1, 0.0613, 0.0533, 3.0)], material: "plastic.matte:8E7447")
        grimeBand.recomputeNormals()
        pre.add(grimeBand)
        pre.add(Prim.roundedBox(V3(0.03, 0.0011, 0.0042), radius: 0.0003, bevelSegments: 1, material: "plastic.matte:EFEFEF"), Xform(translation: V3(0.034, 0.0046, 0.0), rotation: simd_quatf(degrees: 20, axis: V3(0, 0, 1))))
        // Slices: crust ring plus crumb face.
        let outline0 = Shape2D.rounded([V2(-0.054, -0.044), V2(-0.054, 0.044), V2(0.02, 0.046), V2(0.034, 0.054), V2(0.05, 0.054), V2(0.056, 0.043),
                                       V2(0.056, -0.043), V2(0.05, -0.054), V2(0.034, -0.054), V2(0.02, -0.046)].map { $0 }, radius: 0.008, segments: 2)
        let outline = outline0.map { $0 * 0.93 }
        let inner = Shape2D.offset(outline, -0.0032)
        let lay = simd_quatf(degrees: 90, axis: V3(1, 0, 0))
        for k in 0..<11 {
            let y = 0.052 + Float(k) * 0.0165 + (k == 6 ? 0.004 : 0)
            let tilt = k == 6 ? rng.float(5...8) : rng.float(-0.8...0.8)
            let q = simd_quatf(degrees: tilt, axis: V3(0, 0, 1)) * lay
            var crust = Prim.extrude(outline, depth: 0.0125, bevel: 0.0014, bevelSegments: 1, material: k % 3 == 0 ? "food.bread-crust:B87838" : (k % 3 == 1 ? "food.bread-crust" : "food.bread-crust:A8662E"))
            crust.recomputeNormals()
            pre.add(crust, Xform(translation: V3(0, y, 0), rotation: q))
            var crumb = Prim.extrude(inner, depth: 0.0132, bevel: 0.0008, bevelSegments: 1, material: "food.bread-crumb")
            crumb.recomputeNormals()
            pre.add(crumb, Xform(translation: V3(0, y, 0), rotation: q))
        }
        // Gathered neck: twist ties and tag clip.
        pre.add(Prim.tube([V3(0, 0.289, 0), V3(0, 0.292, 0)], radii: [0.0125, 0.0125], sides: 10, seamTile: 0.03, material: film))
        let clipOutline = Shape2D.rounded([V2(-0.0165, -0.0045), V2(0.0165, -0.0045), V2(0.0165, 0.0045), V2(-0.0165, 0.0045)], radius: 0.0012, segments: 2)
        var tag = Prim.extrude(clipOutline, depth: 0.0075, bevel: 0.0006, bevelSegments: 1, material: clip)
        tag.recomputeNormals()
        pre.add(tag, Xform(translation: V3(0, 0.2865, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0)) * simd_quatf(degrees: 0, axis: V3(0, 0, 1))))
        // Twist tie wound around the gathered neck.
        pre.add(Prim.helix(radius: 0.0128, pitch: 0.0036, turns: 3, wire: 0.0009, perTurn: 14, sides: 5, material: "metal.aluminum-brushed"), Xform(translation: V3(0, 0.2825, 0)))
        // Barcode patch on the label band: white block, dark bars of varied width.
        pre.add(Prim.roundedBox(V3(0.0006, 0.026, 0.017), radius: 0.0002, bevelSegments: 1, material: "plastic.matte:F1EDE2"), Xform(translation: V3(0.0616, 0.176 - 0.0145, 0.026)))
        var bz: Float = 0.0185
        for k in 0..<13 {
            let w = Float(0.0004 + 0.0004 * Float((k * 7) % 3))
            pre.add(Prim.roundedBox(V3(0.0008, 0.018, w), radius: 0.0001, bevelSegments: 1, material: "plastic.matte:2A2A2A"), Xform(translation: V3(0.0618, 0.176 - 0.0145, 0.026 - 0.0085 + (bz - 0.0185) * 0.0 + Float(k) * 0.0013 + 0.0005)))
            bz += w
        }
        var m = Model(name: Self.id)
        m.add(pre, Xform(rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        // Crumbs on the table next to the bag.
        for _ in 0..<5 {
            m.add(Prim.superellipsoid(V3(rng.float(0.002...0.004), 0.002, rng.float(0.002...0.004)), exponent: 3, subdivisions: 2, material: "food.bread-crumb"),
                  Xform(translation: V3(rng.float((-0.27)...(-0.03)), 0.001, rng.float(0.049...0.055)), rotation: simd_quatf(degrees: rng.float(0...360), axis: .up)))
        }
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2)))
        groundAO(&m, height: 0.03, floor: 0.7)
        return LODModel(m)
    }
}
