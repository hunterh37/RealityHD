import simd
import Foundation

/// Pour-over coffee scale, 190 x 120 x 30 mm: matte black body with filleted corners on rubber feet,
/// raised weighing platform edged by a silicone ring, front LCD showing weight and brew time in
/// seven-segment digits (unlit segments greyed), power/tare and timer buttons either side.
public struct CoffeeScale: RealAsset {
    public static let id = "coffee-scale"
    public static let summary = "Coffee brewing scale, 190 x 120 x 30 mm black matte body, rubber-ringed platform, LCD weight and timer, two front buttons."
    public static let tags = ["prop", "kitchen", "plastic", "electronics", "tool", "handheld"]
    public static let budget = 6000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 28, studio: true)

    /// Body width (x), depth (z) in meters.
    public var width: Float = 0.19
    public var depth: Float = 0.12
    /// Body shell height (m), above the feet.
    public var bodyHeight: Float = 0.023
    /// Body plastic.
    public var body: MaterialKey = "plastic.matte:1C1C1E"
    /// Platform plastic (slightly worn where cups sit).
    public var platform: MaterialKey = "plastic.medical-grey-worn:202022"
    /// Silicone ring and feet.
    public var rubber: MaterialKey = "rubber.silicone:1A1A1B"
    /// LCD background, lit and unlit segments.
    public var lcd: MaterialKey = "plastic.matte:A6B0A2"
    public var segOn: MaterialKey = "plastic.matte:141516"
    public var segOff: MaterialKey = "plastic.matte:85907F"
    /// Displayed weight (grams, one decimal) and time (seconds).
    public var grams: Float = 18.5
    public var seconds: Int = 32
    public init() {}

    static let digitSegs: [Int: [Int]] = [  // a b c d e f g
        0: [1, 1, 1, 1, 1, 1, 0], 1: [0, 1, 1, 0, 0, 0, 0], 2: [1, 1, 0, 1, 1, 0, 1], 3: [1, 1, 1, 1, 0, 0, 1],
        4: [0, 1, 1, 0, 0, 1, 1], 5: [1, 0, 1, 1, 0, 1, 1], 6: [1, 0, 1, 1, 1, 1, 1], 7: [1, 1, 1, 0, 0, 0, 0],
        8: [1, 1, 1, 1, 1, 1, 1], 9: [1, 1, 1, 1, 0, 1, 1],
    ]

    /// Flat front-facing (+Z) rectangle, w x h, centred.
    static func quad(_ w: Float, _ h: Float, material: MaterialKey) -> Surface {
        var s = Surface(material: material)
        let a = s.add(V3(-w / 2, -h / 2, 0), V3(0, 0, 1), V2(0, 0)), b = s.add(V3(w / 2, -h / 2, 0), V3(0, 0, 1), V2(w, 0))
        let c = s.add(V3(w / 2, h / 2, 0), V3(0, 0, 1), V2(w, h)), d = s.add(V3(-w / 2, h / 2, 0), V3(0, 0, 1), V2(0, h))
        s.tri(a, b, c); s.tri(a, c, d)
        s.computeTangents()
        return s
    }

    /// Adds one seven-segment digit centred at (x, y) on the plane z.
    func digit(_ m: inout Model, _ d: Int?, x: Float, y: Float, z: Float, h: Float) {
        let w = h * 0.55, t = h * 0.13, hh = h / 2
        let segs: [(V3, V3)] = [
            (V3(0, hh, 0), V3(w - t, t, 1)), (V3(w / 2, hh / 2, 0), V3(t, hh - t, 1)), (V3(w / 2, -hh / 2, 0), V3(t, hh - t, 1)),
            (V3(0, -hh, 0), V3(w - t, t, 1)), (V3(-w / 2, -hh / 2, 0), V3(t, hh - t, 1)), (V3(-w / 2, hh / 2, 0), V3(t, hh - t, 1)),
            (V3(0, 0, 0), V3(w - t, t, 1)),
        ]
        let on = d.flatMap { Self.digitSegs[$0] } ?? [0, 0, 0, 0, 0, 0, 0]
        for (i, s) in segs.enumerated() {
            let lit = on[i] == 1
            m.add(Self.quad(s.1.x, s.1.y, material: lit ? segOn : segOff),
                  Xform(translation: V3(x + s.0.x + s.0.y * 0.08, y + s.0.y, z + (lit ? 0.00012 : 0.00006))))
        }
    }

    func level(detail: Bool, seed: UInt64) -> Model {
        var m = Model(name: Self.id)
        let W = width, D = depth, H = bodyHeight, foot: Float = 0.002
        let cs = detail ? 6 : 3
        // Body shell: rounded-rectangle prism, beveled 4 mm, standing on feet.
        let outline = Shape2D.roundedRect(W, D, radius: 0.02, segments: cs)
        m.add(Prim.extrude(outline, depth: H, bevel: 0.004, bevelSegments: detail ? 3 : 1, material: body),
              Xform(translation: V3(0, foot + H / 2, 0), rotation: simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))))
        for sx in [Float(-1), 1] { for sz in [Float(-1), 1] {
            m.add(Prim.cylinder(radius: 0.006, height: foot + 0.001, bevel: 0.0008, segments: detail ? 12 : 6, bevelSegments: 1, material: rubber),
                  Xform(translation: V3(sx * (W / 2 - 0.022), 0, sz * (D / 2 - 0.02))))
        } }
        // Platform: thin plate set back from the front, ringed by silicone.
        let pw: Float = 0.158, pd: Float = 0.086, pz: Float = -0.012, top = foot + H
        let pOut = Shape2D.roundedRect(pw, pd, radius: 0.014, segments: cs)
        m.add(Prim.extrude(pOut, depth: 0.0042, bevel: 0.0012, bevelSegments: detail ? 2 : 1, material: platform),
              Xform(translation: V3(0, top + 0.0021 - 0.0005, pz), rotation: simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))))
        let ringPath = Shape2D.roundedRect(pw + 0.006, pd + 0.006, radius: 0.017, segments: cs).map { V3($0.x, top + 0.0022, pz - $0.y) }
        m.add(Prim.sweep(Shape2D.superellipse(0.0052, 0.0058, exponent: 2.6, segments: detail ? 10 : 6), along: ringPath, up: V3(0, 1, 0),
                         closedPath: true, caps: false, material: rubber))
        // Dried coffee drips on the platform from a pour-over (story detail).
        if detail {
            var rng = SeededRNG(seed: seed)
            for _ in 0..<5 {
                let r = rng.float(0.0018...0.0045)
                m.add(Prim.superellipsoid(V3(r * 2, 0.0004, r * rng.float(1.6...2.1)), exponent: 2.4, subdivisions: 3, material: "plastic.gloss:1C0F08"),
                      Xform(translation: V3(rng.float(-0.06...0.06), top + 0.0037, pz + rng.float(-0.03...0.03)), rotation: simd_quatf(angle: rng.float(0...3), axis: V3(0, 1, 0))))
            }
        }
        // Front LCD: gloss bezel, panel, two digit groups (time left, weight right).
        let fz = D / 2, ly = foot + H / 2
        m.add(Prim.roundedBox(V3(0.078, 0.0135, 0.0016), radius: 0.0006, bevelSegments: 1, material: "plastic.gloss:0B0B0C"),
              Xform(translation: V3(0, ly, fz - 0.0004)))
        m.add(Prim.roundedBox(V3(0.072, 0.0105, 0.0006), radius: 0.0002, bevelSegments: 1, material: lcd),
              Xform(translation: V3(0, ly, fz + 0.0003)))
        let dz = fz + 0.0006, dh: Float = 0.0072, step: Float = 0.0062
        let mm = seconds / 60, ss = seconds % 60
        let time: [Int?] = [mm % 10, ss / 10, ss % 10]
        for (i, d) in time.enumerated() { digit(&m, d, x: -0.029 + Float(i) * step + (i > 0 ? 0.002 : 0), y: ly, z: dz, h: dh) }
        for yy in [Float(0.0015), -0.0015] {   // colon
            m.add(Prim.roundedBox(V3(0.0008, 0.0008, 0.0004), radius: 0.0001, bevelSegments: 1, material: segOn), Xform(translation: V3(-0.0252, ly + yy, dz + 0.0002)))
        }
        let g = Int((grams * 10).rounded())
        let wDigits: [Int?] = [g >= 1000 ? (g / 1000) % 10 : nil, g >= 100 ? (g / 100) % 10 : nil, (g / 10) % 10, g % 10]
        for (i, d) in wDigits.enumerated() { digit(&m, d, x: 0.004 + Float(i) * step + (i == 3 ? 0.0015 : 0), y: ly, z: dz, h: dh) }
        m.add(Prim.roundedBox(V3(0.0009, 0.0009, 0.0004), radius: 0.0001, bevelSegments: 1, material: segOn),
              Xform(translation: V3(0.004 + 2.5 * step + 0.0008, ly - dh / 2, dz + 0.0002)))
        // "g" unit mark: small lit bar block.
        m.add(Prim.roundedBox(V3(0.0026, 0.0034, 0.0004), radius: 0.0003, bevelSegments: 1, material: segOn),
              Xform(translation: V3(0.0315, ly - 0.0016, dz + 0.0002)))
        // Buttons: domed rubber discs either side of the LCD.
        for sx in [Float(-1), 1] {
            m.add(Prim.cylinder(radius: 0.0052, height: 0.0022, bevel: 0.0009, segments: detail ? 16 : 8, bevelSegments: 2, material: rubber),
                  Xform(translation: V3(sx * 0.058, ly, fz - 0.0006), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
            m.add(Prim.roundedBox(sx < 0 ? V3(0.0006, 0.0028, 0.0003) : V3(0.0028, 0.0006, 0.0003), radius: 0.0001, bevelSegments: 1, material: "plastic.matte:8A8A8A"),
                  Xform(translation: V3(sx * 0.058, ly, fz + 0.0017)))
        }
        groundAO(&m, height: 0.008, floor: 0.6)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(detail: true, seed: seed), level(detail: false, seed: seed)], switchDistances: [3])
    }
}
