import simd
import Foundation

/// Corten steel cladding panel: four rows by four columns of folded weathering-steel pans with raised
/// standing seams, 12 mm horizontal reveals, galvanized hat-section clip rails behind, stainless pan-head
/// fasteners and edge returns, with rust run-off streaks. Wall plane at z = 0.
public struct CortenSteelCladdingPanel: RealAsset {
    public static let id = "corten-steel-cladding-panel"
    public static let summary = "Corten steel cladding panel, 1.2 x 2.4 m: folded pans with standing seams, reveal joints, clip rails, stainless fasteners and rust run-off."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 16000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 3.8)

    public var width: Float = 1.2
    public var height: Float = 2.4
    public var depth: Float = 0.06
    public var columns = 4
    public var rows = 4
    /// Reveal (gap) between pan rows (m) and sheet thickness (m).
    public var reveal: Float = 0.014
    public var sheet: Float = 0.003
    public var corten: MaterialKey = "metal.corten"
    public var stainless: MaterialKey = "metal.stainless"
    public var galvanized: MaterialKey = "metal.galvanized"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, H = height, D = depth, t = sheet
        let rowH = (H - Float(rows - 1) * reveal) / Float(rows)
        let pw = W / Float(columns)
        let zb: Float = 0.032, zf: Float = D - 0.008, zt = D

        // Backing sheet and horizontal hat-section clip rails (visible through the reveals).
        FA.box(&m, V3(W, H, 0.004), V3(0, H / 2, 0.002), galvanized, r: 0.001)
        let hat: [V2] = [V2(0, 0.0), V2(0.006, 0.0), V2(0.006, 0.026), V2(0.034, 0.026), V2(0.034, 0.0), V2(0.04, 0.0), V2(0.04, 0.032), V2(0, 0.032)]
        _ = hat
        var railYs: [Float] = []
        for r in 0..<rows {
            let y0 = Float(r) * (rowH + reveal)
            railYs.append(y0 + 0.07)
            railYs.append(y0 + rowH - 0.07)
            if r < rows - 1 { railYs.append(y0 + rowH + reveal / 2) }
        }
        for y in railYs {
            // hat channel: two flanges on the wall, raised web carrying the pans
            FA.box(&m, V3(W - 0.01, 0.036, 0.003), V3(0, y, 0.0055), galvanized, r: 0.001)
            FA.box(&m, V3(W - 0.01, 0.003, 0.026), V3(0, y - 0.0165, 0.017), galvanized, r: 0.001)
            FA.box(&m, V3(W - 0.01, 0.003, 0.026), V3(0, y + 0.0165, 0.017), galvanized, r: 0.001)
            FA.box(&m, V3(W - 0.01, 0.036, 0.003), V3(0, y, 0.0305), galvanized, r: 0.001)
        }

        // Pans: tray with face and upstanding seam ribs; polygon in (x, z), extruded along Y.
        func pan(_ w: Float) -> [V2] {
            let a = -w / 2, b = w / 2
            return [V2(a, zb), V2(a, zt), V2(a + t, zt), V2(a + t, zf), V2(b - t, zf), V2(b - t, zt), V2(b, zt), V2(b, zb),
                    V2(b - t, zb), V2(b - t, zf - t), V2(a + t, zf - t), V2(a + t, zb)]
        }
        let tones: [MaterialKey] = ["metal.corten:8A4A2A", "metal.corten:7A3F24", "metal.corten:9A5530", "metal.corten:6B3520", "metal.corten:A05E36", "metal.corten:7F4528"]
        for r in 0..<rows {
            let y0 = Float(r) * (rowH + reveal)
            for c in 0..<columns {
                let x = -W / 2 + (Float(c) + 0.5) * pw
                let w = pw - 0.004
                // tray rotated so the profile (x, z) extrudes along +Y
                m.add(Prim.extrude(pan(w), depth: rowH - 0.002, bevel: 0.0008, bevelSegments: 1, material: tones[rng.int(0...(tones.count - 1))]),
                      Xform(translation: V3(x, y0 + rowH / 2, 0), rotation: FA.q(90, FA.X) * FA.q(0, FA.Z)))
            }
            // Edge returns folded down at the head and sill of each pan row.
            for e: Float in [0, 1] {
                FA.box(&m, V3(W - 0.004, t, zf - zb), V3(0, y0 + 0.001 + e * (rowH - 0.002), (zf + zb) / 2), corten, r: 0.0006)
            }
        }
        // Stainless pan-head fasteners with washers through each pan near both rails, and seam clips.
        for r in 0..<rows {
            let y0 = Float(r) * (rowH + reveal)
            for c in 0..<columns {
                let x = -W / 2 + (Float(c) + 0.5) * pw
                for dy in [0.07, rowH - 0.07] as [Float] {
                    FA.cylZ(&m, r: 0.0085, h: 0.0012, at: V3(x, y0 + dy, zf), stainless, bevel: 0.0003, segments: 12)
                    FC.bead(&m, r: 0.0055, at: V3(x, y0 + dy, zf + 0.0018), stainless, sub: 1)
                }
            }
        }
        // Rust run-off: darker streaks below each reveal and weld-like stains; one patch of lighter fresh steel.
        for r in 1..<rows {
            let y = Float(r) * (rowH + reveal) - reveal
            for _ in 0..<5 {
                let x = rng.float(-0.55...0.55), len = rng.float(0.08...0.3)
                FA.box(&m, V3(rng.float(0.006...0.02), len, 0.0006), V3(x, y - len / 2, zf + 0.0004), "metal.corten:4A2814", r: 0.0002)
            }
        }
        FA.box(&m, V3(0.12, 0.09, 0.0006), V3(0.16, 0.55, zf + 0.0004), "metal.corten:B86A3C", r: 0.0002)

        groundAO(&m, height: 0.15, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
