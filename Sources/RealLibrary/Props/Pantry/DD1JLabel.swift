import simd
import Foundation

extension DD1JKit {
    /// Printed wrap label for a bottle or jar: paper body, two edge bands, front panel, ink bars, barcode, overlap seam and grime.
    static func wrapLabel(_ m: inout Model, radius: @escaping (Float) -> Float, y0: Float, y1: Float, base: UInt32, band: UInt32,
                          panel: UInt32, ink: UInt32 = 0x2A2420, bandHeight: Float, bars: Int, detail: Bool, seamAt: Float = .pi / 2 + 0.6,
                          front: (inout Model, Float) -> Void) {
        let R = radius((y0 + y1) / 2)
        let seg = detail ? 36 : 16
        let rr: (Float) -> Float = { radius($0) }
        m.add(Prim.lathe([V2(rr(y0) - 0.0004, y0), V2(rr(y0), y0 + 0.0002), V2(rr(y1), y1 - 0.0002), V2(rr(y1) - 0.0004, y1)],
                         segments: seg, seamTile: 0.1, material: tint("plastic.matte", base)))
        for (a, b) in [(y0, y0 + bandHeight), (y1 - bandHeight, y1)] {
            m.add(arcPatch(center: 0, width: 2 * .pi * R, y0: a, y1: b, offset: 0.0004, material: tint("plastic.gloss", band), radius: rr, rows: 1))
        }
        m.add(arcPatch(center: 0, width: 2 * .pi * R, y0: y0, y1: y0 + 0.0022, offset: 0.0006, material: tint("plastic.matte", 0x4A3F33), radius: rr, rows: 1))
        m.add(arcPatch(center: seamAt, width: 0.0035, y0: y0, y1: y1, offset: 0.0009, material: tint("plastic.matte", base ^ 0x0C0C0C), radius: rr, rows: 1))
        let mid = (y0 + y1) / 2, ph = (y1 - y0 - 2 * bandHeight) * 0.82
        m.add(arcPatch(center: -.pi / 2, width: R * 1.3, y0: mid - ph / 2, y1: mid + ph / 2, offset: 0.0008, material: tint("plastic.gloss", panel),
                       radius: rr, rows: 3))
        for k in 0..<bars {
            let by = mid + ph / 2 - 0.0050 - Float(k) * 0.0050
            let w = R * (k == 0 ? 0.95 : 0.7 - 0.08 * Float(k))
            m.add(arcPatch(center: -.pi / 2, width: w, y0: by - 0.0016, y1: by + 0.0016, offset: 0.0013, material: tint("plastic.matte", ink), radius: rr, rows: 1))
        }
        for k in 0..<(detail ? 14 : 5) {
            let wd: Float = (k % 3 == 0) ? 0.0016 : 0.0009
            m.add(arcPatch(center: .pi / 2 - 0.62 + Float(k) * 0.045, width: wd, y0: mid - 0.009, y1: mid + 0.005, offset: 0.0008,
                           material: tint("plastic.matte", 0x1C1A18), radius: rr, rows: 1))
        }
        for i in 0..<4 {
            let a = Float(i) * 1.9 + 0.3, w: Float = 0.004 + 0.002 * Float(i % 3)
            let y = i % 2 == 0 ? y1 - bandHeight * (0.25 + 0.1 * Float(i)) : y0 + bandHeight * 0.3
            m.add(arcPatch(center: a, width: w, y0: y, y1: y + 0.0012, offset: 0.0009, material: tint("plastic.matte", 0xE7DFD0), radius: rr, rows: 1))
        }
        // Water ring stain, a drip streak below the lid and vertical creases.
        m.add(arcPatch(center: -.pi / 2 - 0.6, width: 0.014, y0: y0 + bandHeight + 0.004, y1: y0 + bandHeight + 0.015, offset: 0.0010,
                       material: tint("plastic.matte", base ^ 0x1E1C14), radius: rr, rows: 3))
        for (i, a) in [Float(0.2), 1.4, 2.6, -1.9].enumerated() {
            m.add(arcPatch(center: a, width: 0.0007, y0: y0 + 0.004, y1: y1 - 0.004, offset: 0.0010,
                           material: tint("plastic.matte", i % 2 == 0 ? 0xF7F2E4 : 0x3C342C), radius: rr, cols: 1, rows: 8))
        }
        front(&m, radius(mid) + 0.0013)
    }

    /// Dried drip down a neck or shoulder: narrow tapering run of fluid on the outside of the glass.
    static func drip(_ m: inout Model, radius: @escaping (Float) -> Float, angle: Float, yTop: Float, yBottom: Float, material: MaterialKey) {
        for (i, w) in [Float(0.0042), 0.0030, 0.0020].enumerated() {
            let a = yTop - (yTop - yBottom) * Float(i) / 3, b = yTop - (yTop - yBottom) * Float(i + 1) / 3
            m.add(arcPatch(center: angle, width: w, y0: b, y1: a, offset: 0.0002 + 0.00005 * Float(3 - i), material: material, radius: radius, rows: 3))
        }
        m.add(Prim.superellipsoid(V3(0.0026, 0.0034, 0.0020), exponent: 2, subdivisions: 1, material: material),
              Xform(translation: V3(cos(angle) * (radius(yBottom) + 0.0004), yBottom - 0.0012, -sin(angle) * (radius(yBottom) + 0.0004))))
    }
}
