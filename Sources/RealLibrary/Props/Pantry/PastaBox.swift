import simd
import Foundation

/// Spaghetti box, 60 x 278 x 39 mm (500 g): matte printed carton (invented brand VELLA) built from panels with
/// rounded fold edges. A film window on the front shows the bundle of dry strands running the full length of
/// the box; the printed design sits above it and a product band below. The top carries a perforated tear
/// strip, one side the glue lap, the back cooking copy. The top front fold is rubbed through to bare board.
public struct PastaBox: RealAsset {
    public static let id = "pasta-box"
    public static let summary = "Spaghetti box: matte printed carton panels, film window over a strand bundle, tear strip, glue lap, rounded folds."
    public static let tags = ["prop", "interior", "pantry", "paper", "glass"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 16, studio: true)

    /// Carton width, height, depth (m).
    public var size = V3(0.06, 0.278, 0.039)
    /// Printed face (brand field tint) and matching board.
    public var print: MaterialKey = "pkg.carton-matte:1F4E96"
    public var board: MaterialKey = "paper.sheet:24519A"
    public var pasta: MaterialKey = "plastic.matte:E6C46E"
    public var film: MaterialKey = "pkg.pet-clear"
    public var brand = "VELLA"
    public var line = "SPAGHETTI"
    public var strandCount = 44
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, hi: true), make(seed: seed, hi: false)], switchDistances: [3])
    }

    func make(seed: UInt64, hi: Bool) -> Model {
        typealias K = GroceryKit
        var rng = SeededRNG(seed: seed &+ 7)
        var m = Model(name: Self.id)
        let w = size.x, h = size.y, d = size.z, e: Float = 0.0009
        let wy0: Float = 0.052, wy1: Float = 0.168, wx: Float = 0.021, fz = d / 2
        func panel(_ key: MaterialKey, _ x0: Float, _ x1: Float, _ y0: Float, _ y1: Float, z: Float, u: (Float, Float) = (0, 0), v: (Float, Float) = (0, 0), back: Bool = false) {
            let us = u.1 == 0 ? x1 - x0 : u.1, vs = v.1 == 0 ? y1 - y0 : v.1
            m.add(K.sheet(cols: 1, rows: 1, uSpan: us, vSpan: vs, u0: u.0, v0: v.0, key) { s, t in
                back ? V3(x1 - s * (x1 - x0), y0 + t * (y1 - y0), z) : V3(x0 + s * (x1 - x0), y0 + t * (y1 - y0), z)
            })
        }
        let L = -w / 2 + e, R = w / 2 - e
        // Front: product band, window margins, printed design above (design x 0.45...1, rows 0.45...1).
        panel(board, L, R, e, wy0, z: fz)
        panel(board, L, -wx, wy0, wy1, z: fz)
        panel(board, wx, R, wy0, wy1, z: fz)
        panel(board, L, R, wy1, wy1 + 0.004, z: fz)
        panel(print, L, R, wy1 + 0.004, h - e, z: fz, u: (0.0675, 0.0825), v: (0.121, -0.121))
        // Back: design on top, cooking copy board below.
        m.add(K.sheet(cols: 1, rows: 1, uSpan: 0.0825, vSpan: -0.121, u0: 0.0675, v0: 0.121, print) { s, t in V3(R - s * (R - L), wy1 + 0.004 + t * (h - e - wy1 - 0.004), -fz) })
        panel(board, L, R, e, wy1 + 0.004, z: -fz, back: true)
        // Sides, top, bottom.
        for side: Float in [1, -1] {
            m.add(K.sheet(cols: 1, rows: 1, uSpan: d, vSpan: h, board) { s, t in V3(side * w / 2, e + t * (h - 2 * e), side * (d / 2 - e - s * (d - 2 * e))) })
        }
        m.add(K.sheet(cols: 1, rows: 1, uSpan: w, vSpan: d, board) { s, t in V3(L + s * (R - L), h, d / 2 - e - t * (d - 2 * e)) })
        m.add(K.sheet(cols: 1, rows: 1, uSpan: w, vSpan: d, board) { s, t in V3(R - s * (R - L), 0, d / 2 - e - t * (d - 2 * e)) })
        // Rounded folds.
        let hw = w / 2 - e, hd = d / 2 - e
        var edges: [(V3, V3)] = []
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] { edges.append((V3(sx * hw, e, sz * hd), V3(sx * hw, h - e, sz * hd))) } }
        for y in [e, h - e] { for sz: Float in [-1, 1] { edges.append((V3(-hw, y, sz * hd), V3(hw, y, sz * hd))) }
            for sx: Float in [-1, 1] { edges.append((V3(sx * hw, y, -hd), V3(sx * hw, y, hd))) } }
        for (i, (a, b)) in edges.enumerated() {
            // Top front fold rubbed to bare board.
            let key: MaterialKey = i == 9 && hi ? "paper.screwbox-kraft" : board
            m.add(Prim.tube([a, b], radii: [e, e], sides: hi ? 8 : 4, seamTile: 0.02, material: key))
        }
        // Inside back wall seen through the window, film over the window, strand bundle.
        panel("paper.sheet:C9B48A", -wx - 0.002, wx + 0.002, wy0 - 0.002, wy1 + 0.002, z: -fz + 0.001)
        m.add(K.sheet(cols: 6, rows: 10, uSpan: 0.05, vSpan: 0.12, film) { s, t in
            let x = -wx + s * 2 * wx, y = wy0 + t * (wy1 - wy0)
            return V3(x, y, fz - 0.0004 + 0.0006 * sin(s * .pi) * sin(t * .pi) + 0.0002 * sin(t * 40 + s * 9))
        })
        let n = hi ? strandCount : 14
        for k in 0..<n {
            let x = rng.float(-0.024...0.024), z = rng.float(-0.012...(fz - 0.0045))
            let lean = rng.float(-0.003...0.003), r: Float = hi ? 0.0009 : 0.0016
            m.add(Prim.tube([V3(x, 0.006, z), V3(x + lean, h - 0.006, z + lean * 0.5)], radii: [r, r], sides: hi ? 5 : 3, seamTile: 0.01, material: pasta))
            _ = k
        }
        if hi {
            // Window keyline, wordmark on the pill, product band copy.
            let kp: [V3] = [V3(-wx, wy0, fz + 0.0003), V3(wx, wy0, fz + 0.0003), V3(wx, wy1, fz + 0.0003), V3(-wx, wy1, fz + 0.0003)]
            m.add(Prim.sweep(Shape2D.rect(0.0005, 0.0014), along: kp, up: V3(0, 0, 1), closedPath: true, material: "paper.sheet:E8C24A"))
            let dy = wy1 + 0.004, dh = h - e - dy
            K.printSmooth(&m, brand, height: 0.011, at: V3(-w / 2 + 0.4545 * w, dy + 0.66 * dh, fz + 0.0005), "paper.sheet:FFFFFF", maxWidth: 0.044, weight: 1.35)
            K.printSmooth(&m, line, height: 0.0065, at: V3(0, 0.03, fz + 0.0005), "paper.sheet:FFFFFF", maxWidth: 0.05, weight: 1.2)
            K.printSmooth(&m, "N 5", height: 0.009, at: V3(0, 0.012, fz + 0.0005), "paper.sheet:E8C24A", weight: 1.3)
            K.printSmooth(&m, "500 G", height: 0.0045, at: V3(0, 0.043, fz + 0.0005), "paper.sheet:DCE4F2", weight: 1.0)
            // Perforated tear strip on the top.
            for k in 0..<14 {
                m.add(Prim.roundedBox(V3(0.0022, 0.0003, 0.0005), radius: 0.0001, bevelSegments: 1, material: "paper.sheet:10284F"),
                      Xform(translation: V3(L + 0.003 + Float(k) * 0.0039, h + 0.0001, d / 2 - 0.008)))
            }
            // Glue lap on the left side, cooking copy rules on the back.
            m.add(Prim.roundedBox(V3(0.0004, h - 0.008, 0.01), radius: 0.0001, bevelSegments: 1, material: board), Xform(translation: V3(-w / 2 - 0.0002, h / 2, -d / 2 + 0.007)))
            for k in 0..<9 {
                m.add(Prim.roundedBox(V3(0.04 - Float(k % 3) * 0.006, 0.0012, 0.0003), radius: 0.0001, bevelSegments: 1, material: "paper.sheet:DCE4F2"),
                      Xform(translation: V3(0, 0.15 - Float(k) * 0.009, -fz - 0.0002)))
            }
        }
        groundAO(&m, height: 0.02, floor: 0.75)
        return m
    }
}
