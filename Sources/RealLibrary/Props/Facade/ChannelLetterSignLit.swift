import simd
import Foundation

/// Illuminated channel letter sign: five painted aluminium return cans on a shallow raceway, each with a
/// translucent acrylic face held by a jewelite trim cap, wired through a conduit and a junction box.
public struct ChannelLetterSignLit: RealAsset {
    public static let id = "channel-letter-sign-lit"
    public static let summary = "Illuminated channel letter sign DINER, 2.0 m: aluminium return cans, acrylic faces with jewelite trim cap, raceway and conduit."
    public static let tags = ["prop", "architecture", "facade", "trim", "metal"]
    public static let budget = 10500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 1.2)

    /// Lettering shown (A-Z, 0-9).
    public var word = "DINER"
    /// Letter cap height (m).
    public var letterHeight: Float = 0.355
    /// Raceway length (m).
    public var racewayLength: Float = 2.0
    /// Return can paint.
    public var returns: MaterialKey = "metal.painted:262A33"
    /// Lit acrylic face.
    public var face: MaterialKey = "emissive.signal-red"
    /// Jewelite trim cap.
    public var trim: MaterialKey = "plastic.white"
    public var raceway: MaterialKey = "metal.painted:2A2A2C"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let h = letterHeight, cy: Float = 0.11 + letterHeight / 2, stroke = h * 0.19
        // Raceway: formed aluminium box under the letters with a lid seam, end caps and screws.
        FA.box(&m, V3(racewayLength, 0.075, 0.07), V3(0, 0.0375, 0.035), raceway, r: 0.006)
        FA.box(&m, V3(racewayLength - 0.012, 0.003, 0.072), V3(0, 0.07, 0.036), "metal.steel:1A1A1A", r: 0.001)
        for e: Float in [-1, 1] { FA.box(&m, V3(0.006, 0.081, 0.074), V3(e * (racewayLength / 2 - 0.003), 0.0375, 0.036), raceway, r: 0.002) }
        for i in 0..<7 { FG.screw(&m, at: V3((Float(i) - 3) * 0.3, 0.03, 0.07), r: 0.004, mat: "metal.stainless") }
        // Rust drips from the screw heads.
        for i in [1, 4] { FA.box(&m, V3(0.003, rng.float(0.02...0.04), 0.0005), V3((Float(i) - 3) * 0.3 + 0.003, 0.012, 0.0705), "metal.rust-grime", r: 0.0003) }
        let w = strokeTextWidth(word, height: h)
        let n = word.count
        let pitch = 5.4 * h / 6
        let z0: Float = 0.03
        // Letters: can (return), trim cap ring, acrylic face; one dead segment in the penultimate letter.
        for (i, ch) in word.enumerated() {
            let cx = -w / 2 + (Float(i) + 0.5) * pitch - 0.7 * h / 6
            let s = String(ch)
            let dead = i == n - 2
            FG.soft(&m, s, h: h, stroke: stroke, depth: 0.108, at: V3(cx, cy, z0), returns, bevel: 0.004)
            FG.text(&m, s, h: h, stroke: stroke * 0.99, depth: 0.0035, at: V3(cx, cy, z0 + 0.1085), trim)
            FG.text(&m, s, h: h, stroke: stroke * 0.72, depth: 0.003, at: V3(cx, cy, z0 + 0.1105), dead ? "plastic.white:8C857A" : face)
            // Weep hole in the bottom of each can and a dirt streak where water runs off the trim cap.
            FA.box(&m, V3(0.006, 0.0015, 0.006), V3(cx, cy - h / 2 - 0.018, z0 + 0.05), "metal.steel:0A0A0A", r: 0.0003)
            FA.box(&m, V3(stroke * 0.5, rng.float(0.03...0.07), 0.0006), V3(cx - h * 0.1 + rng.float(-0.01...0.01), cy - h * 0.2, z0 + 0.1142), "metal.steel:2B2118", r: 0.0002)
            // Standoff studs from the wall to the letter back, and a wiring grommet in the can.
            for dy: Float in [-1, 1] {
                FA.cylZ(&m, r: 0.004, h: z0 + 0.004, at: V3(cx - h * 0.1, cy + dy * h * 0.4, 0), "metal.stainless", bevel: 0.0005, segments: 8)
                FG.screw(&m, at: V3(cx - h * 0.1, cy + dy * h * 0.4, z0 + 0.1135), r: 0.0025, mat: "metal.stainless")
            }
        }
        // Conduit rising along the wall from the raceway to a disconnect box.
        let x = racewayLength / 2 - 0.045
        FA.rod(&m, V3(x, 0.07, 0.012), V3(x, 0.2, 0.012), r: 0.008, "metal.galvanized-aged", sides: 12)
        FA.box(&m, V3(0.085, 0.1, 0.045), V3(x, 0.24, 0.0225), "metal.galvanized", r: 0.004)
        FA.box(&m, V3(0.06, 0.012, 0.048), V3(x, 0.27, 0.024), "metal.steel:1A1A1A", r: 0.001)
        FG.screw(&m, at: V3(x - 0.03, 0.2, 0.045), r: 0.003, mat: "metal.stainless")
        FG.screw(&m, at: V3(x + 0.03, 0.28, 0.045), r: 0.003, mat: "metal.stainless")
        groundAO(&m, height: 0.1, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
