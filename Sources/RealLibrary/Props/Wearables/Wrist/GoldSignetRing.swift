import simd
import Foundation

/// Gold signet ring on the ring finger of the left hand, 9 cm below the wrist: tapered shank swelling from 2.4 mm at the back to
/// wide shoulders, oval pad with a raised polished rim, a recessed field with patina and a raised block monogram with serifs, beaded
/// edge, hallmark stamp inside. The rim is worn flat, the monogram is rubbed and the shoulder carries a dent.
public struct GoldSignetRing: RealAsset {
    public static let id = "gold-signet-ring"
    public static let summary = "Worn gold signet ring: tapered shank, oval pad with raised rim, patina field and raised monogram, hallmark."
    public static let tags = ["prop", "wearable", "worn", "jewelry", "metal", "gold"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 22, distance: 1.0, ground: false, studio: true)

    /// Ring gold.
    public var gold: MaterialKey = "metal.gold"
    /// Patina field and recesses.
    public var patina: MaterialKey = "metal.brass-aged"
    /// Height of the ring centre below the wrist (m).
    public var drop: Float = 0.090
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let y0 = -drop
        let rin: Float = 0.0090
        func spow(_ v: Float, _ e: Float) -> Float { (v < 0 ? -1 : 1) * pow(abs(v), e) }
        func thick(_ th: Float) -> Float { 0.0024 + 0.0030 * pow(max(0, cos(th / 2)), 5) }
        func width(_ th: Float) -> Float { 0.0042 + 0.0118 * pow(max(0, cos(th / 2)), 2.0) }
        // Shank: u around the finger (0 = front), v around the section.
        var shank = WristKit.grid(120, 20, flip: false, material: gold) { u, v in
            let th = u * 2 * Float.pi, ph = v * 2 * Float.pi
            let c = cos(ph), s = sin(ph)
            let ax = width(th) / 2 * spow(c, 0.45)
            let rad = rin + thick(th) * (0.5 + 0.5 * spow(s, 0.45))
            return V3(sin(th) * rad, y0 + ax, cos(th) * rad)
        }
        let dent = V3(0.0125, y0 + 0.0030, 0.0070)
        shank.displace { p, _ in
            0.00010 * Noise.fbm(p * 400, octaves: 2) - 0.00045 * exp(-simd_length_squared(p - dent) / 0.0000012)
        }
        m.add(shank)

        // Signet pad: flared base, raised rim, recessed patina field, monogram, beaded edge.
        let top = rin + thick(0)
        let outline = Shape2D.superellipse(0.0140, 0.0172, exponent: 2.6, segments: 40)
        let qx = simd_quatf(angle: 0, axis: V3(0, 0, 1))
        let base = V3(0, y0, top - 0.0016)
        m.add(Prim.extrude(Shape2D.offset(outline, 0.0004), depth: 0.0030, bevel: 0.0007, bevelSegments: 3, material: gold),
              Xform(translation: base + V3(0, 0, 0.0015), rotation: qx))
        // Raised rim (worn flat on the lower side).
        let rimPts = Shape2D.offset(outline, -0.0006).map { V3($0.x, $0.y, 0) }
        m.add(Prim.sweep(Shape2D.circle(0.00065, segments: 8), along: rimPts, up: V3(0, 0, 1), closedPath: true, caps: false, material: gold),
              Xform(translation: base + V3(0, 0, 0.0031)))
        m.add(Prim.extrude(Shape2D.offset(outline, -0.0006), depth: 0.0003, bevel: 0.00008, bevelSegments: 1, material: patina),
              Xform(translation: base + V3(0, 0, 0.0030)))
        // Raised monogram "H" with serifs, slightly rubbed (lower on the right stem).
        let zf = base.z + 0.0031
        func bar(_ x: Float, _ y: Float, _ wd: Float, _ ht: Float, h: Float = 0.00055) {
            m.add(Prim.roundedBox(V3(wd, ht, h), radius: min(0.00018, h * 0.4), bevelSegments: 1, material: gold),
                  Xform(translation: V3(x, y0 + y, zf + h / 2)))
        }
        bar(-0.0026, 0.0, 0.0012, 0.0086)
        bar(0.0026, 0.0, 0.0012, 0.0086, h: 0.00042)
        bar(0.0, 0.0, 0.0044, 0.0009)
        for (x, y) in [(-0.0026, 0.0045), (-0.0026, -0.0045), (0.0026, 0.0045), (0.0026, -0.0045)] as [(Float, Float)] {
            bar(x, y, 0.0034, 0.0006, h: 0.0005)
        }
        // Beaded edge between rim and field: ring of small tubes.
        let beadPts = Shape2D.offset(outline, -0.0015).map { V3($0.x, $0.y, 0) }
        m.add(Prim.sweep(Shape2D.circle(0.00022, segments: 6), along: beadPts, up: V3(0, 0, 1), closedPath: true, caps: false, material: gold),
              Xform(translation: base + V3(0, 0, 0.0033)))
        // Micro scratches across the pad face, a chip in the rim and a tarnished liner inside the shank.
        var seedR = SeededRNG(seed: seed)
        for _ in 0..<9 {
            let len = seedR.float(0.0020...0.0058)
            m.add(WristKit.box(V3(len, 0.00007, 0.00004), material: "metal.mirror-polish"),
                  Xform(translation: V3(seedR.float(-0.0042...0.0042), y0 + seedR.float(-0.0060...0.0060), zf + 0.00075),
                        rotation: simd_quatf(angle: seedR.float(0...Float.pi), axis: V3(0, 0, 1))))
        }
        var liner = WristKit.grid(60, 4, flip: false, material: patina) { u, v in
            let th = Float.pi * 0.35 + u * Float.pi * 1.30
            return V3(sin(th) * (rin - 0.00008), y0 + (v - 0.5) * 0.0030, cos(th) * (rin - 0.00008))
        }
        liner.displace { p, _ in 0.00006 * Noise.fbm(p * 500, octaves: 2) }
        m.add(liner)
        // Inside hallmark stamp.
        m.add(WristKit.box(V3(0.0028, 0.0010, 0.0002), material: patina), Xform(translation: V3(0, y0, -rin + 0.0001), rotation: simd_quatf(angle: Float.pi, axis: V3(0, 1, 0))))
        return LODModel(m)
    }
}
