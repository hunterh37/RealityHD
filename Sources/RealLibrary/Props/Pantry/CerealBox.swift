import simd
import Foundation

/// Cereal box, 200 x 300 x 65 mm: printed gloss carton (invented brand SUNNY). Front and back panels bow
/// out over the liner bag, every fold edge is rounded, the top shows the tuck flap with its slot and dust
/// flaps, one side carries the glue-lap seam and the other a nutrition panel. A yellow net-weight band runs
/// across the foot of the front, and the top right corner is crushed in.
public struct CerealBox: RealAsset {
    public static let id = "cereal-box"
    public static let summary = "Printed gloss cereal carton: bowed liner panels, rounded folds, tuck top, glue lap, nutrition side, crushed corner."
    public static let tags = ["prop", "interior", "pantry", "paper", "plastic"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 16, studio: true)

    /// Carton width, height, depth (m).
    public var size = V3(0.20, 0.30, 0.065)
    /// Printed face (brand field tint) and the matching board color for folds and sides.
    public var print: MaterialKey = "pkg.carton-gloss:C8262B"
    public var board: MaterialKey = "paper.sheet:C42A2E"
    /// Net-weight band.
    public var band: MaterialKey = "paper.sheet:F4D23C"
    public var brand = "SUNNY"
    public var line = "HONEY OATS"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(hi: true), make(hi: false)], switchDistances: [4])
    }

    func make(hi: Bool) -> Model {
        typealias K = GroceryKit
        var m = Model(name: Self.id)
        let w = size.x, h = size.y, d = size.z, e: Float = 0.0012
        let crushC = V2(w / 2 - 0.022, h - 0.02)
        func bow(_ x: Float, _ y: Float) -> Float { 0.0032 * (1 - pow(2 * x / w, 2)) * (1 - pow(2 * y / h - 1, 4)) }
        func crush(_ x: Float, _ y: Float) -> Float { -0.0026 * exp(-simd_length_squared(V2(x, y) - crushC) / 0.00022) }
        // Core board block (folds hidden by the edge rolls).
        m.add(Prim.roundedBox(V3(w - 0.006, h - 0.006, d - 0.006), radius: 0.003, bevelSegments: 1, material: board), Xform(translation: V3(0, h / 2, 0)))
        // Front and back: printed design rows 0.32...1 over the top 0.24 m, band below.
        let pc = hi ? 24 : 6, pr = hi ? 30 : 6, bandH: Float = 0.06
        for side: Float in [1, -1] {
            m.add(K.sheet(cols: pc, rows: pr, uSpan: 0.19, vSpan: -0.19, v0: 0.19, print) { s, t in
                let x = side * (-w / 2 + e + s * (w - 2 * e)), y = bandH + t * (h - bandH - e)
                return V3(x, y, side * (d / 2 + bow(x, y) + (side > 0 ? crush(x, y) : 0)))
            })
            m.add(K.sheet(cols: pc, rows: 3, uSpan: w, vSpan: bandH, band) { s, t in
                let x = side * (-w / 2 + e + s * (w - 2 * e)), y = e + t * (bandH - e)
                return V3(x, y, side * (d / 2 + bow(x, y)))
            })
        }
        // Sides: plain board; the right side carries the nutrition panel, the left the glue lap.
        for side: Float in [1, -1] {
            m.add(K.sheet(cols: 2, rows: 2, uSpan: d, vSpan: h, board) { s, t in
                V3(side * w / 2, e + t * (h - 2 * e), side * (d / 2 - e - s * (d - 2 * e)))
            })
        }
        // Top: dust flaps under the tuck flap, flap lip and slot; bottom panel.
        m.add(K.sheet(cols: 2, rows: 2, uSpan: w, vSpan: d, board) { s, t in V3(-w / 2 + e + s * (w - 2 * e), h, d / 2 - e - t * (d - 2 * e)) })
        m.add(K.sheet(cols: 2, rows: 2, uSpan: w, vSpan: d, board) { s, t in V3(w / 2 - e - s * (w - 2 * e), 0, d / 2 - e - t * (d - 2 * e)) })
        // Rounded folds on all twelve edges.
        let hw = w / 2 - e, hh = h - e, hd = d / 2 - e
        var edges: [(V3, V3)] = []
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] { edges.append((V3(sx * hw, e, sz * hd), V3(sx * hw, hh, sz * hd))) } }
        for y in [e, hh] { for sz: Float in [-1, 1] { edges.append((V3(-hw, y, sz * hd), V3(hw, y, sz * hd))) }
            for sx: Float in [-1, 1] { edges.append((V3(sx * hw, y, -hd), V3(sx * hw, y, hd))) } }
        for (a, b) in edges {
            var path = [a, b]
            if hi, a.z > 0, b.z > 0, abs(a.y - b.y) < 0.001, a.y > h / 2 { path = (0...12).map { a + (b - a) * Float($0) / 12 }.map { p in p + V3(0, crush(p.x, p.y) * 0.6, crush(p.x, p.y) * 0.8) } }
            m.add(Prim.tube(path, radii: path.map { _ in e }, sides: hi ? 8 : 4, seamTile: 0.02, material: board))
        }
        if hi {
            // Tuck flap lip and slot on the top.
            m.add(Prim.roundedBox(V3(w - 0.01, 0.0006, 0.0012), radius: 0.0002, bevelSegments: 1, material: K.tint("paper.sheet", GroceryKit.shade(0xC42A2E, 0.6))),
                  Xform(translation: V3(0, h + 0.0002, d / 2 - 0.016)))
            m.add(Prim.roundedBox(V3(0.05, 0.0005, 0.0018), radius: 0.0002, bevelSegments: 1, material: "paper.sheet:2A2420"), Xform(translation: V3(0, h + 0.0002, d / 2 - 0.004)))
            for sx: Float in [-1, 1] {
                m.add(Prim.roundedBox(V3(0.0008, 0.0005, d - 0.008), radius: 0.0002, bevelSegments: 1, material: K.tint("paper.sheet", GroceryKit.shade(0xC42A2E, 0.7))),
                      Xform(translation: V3(sx * (w / 2 - 0.03), h + 0.0002, 0)))
            }
            // Glue lap on the left side.
            m.add(Prim.roundedBox(V3(0.0005, h - 0.01, 0.014), radius: 0.0002, bevelSegments: 1, material: board), Xform(translation: V3(-w / 2 - 0.0002, h / 2, -d / 2 + 0.009)))
            // Nutrition panel on the right side.
            let nx = w / 2 + 0.0004, rotR = simd_quatf(angle: .pi / 2, axis: .up)
            m.add(Prim.roundedBox(V3(0.0003, 0.15, 0.048), radius: 0.0001, bevelSegments: 1, material: "paper.sheet:F6F3EA"), Xform(translation: V3(nx, 0.11, 0)))
            K.printSmooth(&m, "NUTRITION", height: 0.0055, at: V3(nx + 0.0003, 0.174, 0), "paper.sheet:1A1A1A", rot: rotR, maxWidth: 0.042, weight: 1.2)
            for k in 0..<12 {
                let y = 0.168 - Float(k) * 0.0085
                m.add(Prim.roundedBox(V3(0.0003, k % 4 == 0 ? 0.0016 : 0.0006, 0.044), radius: 0.0001, bevelSegments: 1, material: "paper.sheet:1A1A1A"), Xform(translation: V3(nx + 0.0002, y, 0)))
            }
            // Wordmark on the logo pill, product line, net weight on the band.
            let fz = d / 2 + 0.0006
            let face: (Float, Float) -> Float = { x, y in fz + bow(x, y) + crush(x, y) }
            let px = -w / 2 + 0.7 * w, py: (Float) -> Float = { bandH + $0 * (h - bandH) }
            K.printOn(&m, brand, height: 0.024, x: px, y: py(0.705), "paper.sheet:FFFFFF", maxWidth: 0.084, weight: 1.35, lift: 0, surfaceZ: face)
            K.printOn(&m, line, height: 0.011, x: px, y: py(0.555), "paper.sheet:FFFFFF", maxWidth: 0.088, weight: 1.2, lift: 0, surfaceZ: face)
            K.printOn(&m, "NET WT 12 OZ", height: 0.008, x: -0.045, y: 0.022, "paper.sheet:5A3A10", maxWidth: 0.08, weight: 1.0, lift: 0, surfaceZ: face)
            K.printOn(&m, "WHOLE GRAIN", height: 0.008, x: 0.05, y: 0.022, "paper.sheet:B8261E", maxWidth: 0.08, weight: 1.1, lift: 0, surfaceZ: face)
            m.add(K.sheet(cols: 24, rows: 1, uSpan: w, vSpan: 0.002, "paper.sheet:FFFFFF") { s, t in
                let x = -w / 2 + 0.002 + s * (w - 0.004), y = bandH - 0.0009 + t * 0.0018
                return V3(x, y, d / 2 + bow(x, y) + 0.0003)
            })
        }
        groundAO(&m, height: 0.03, floor: 0.75)
        return m
    }
}
