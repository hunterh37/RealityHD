import simd
import Foundation

/// Holo table: Ultra realistic 2035 design table, 1.6 x 0.9 x 1.0 m, dark anodized aluminum pedestal frame, black glass display top with subtle cyan emissive grid, bevelled rounded edges, cable port, leveling feet.. Parts: anodized dark aluminum pedestal frame, glass display top, subtle emissive grid, rounded bevelled edges, cable port, leveling feet.
public struct HoloTable: RealAsset {
    public static let id = "holo-table"
    public static let summary = "2035 holo table: anodized aluminum pedestal frame, glass top with emissive grid, cable port, leveling feet."
    public static let tags = ["prop", "furniture"]
    public static let budget = 6000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.6, 0.9, 1.0)
    public init() {}

    /// Grid line pitch on the glass (m).
    public var gridPitch: Float = 0.1
    public var frame: MaterialKey = "metal.anodized-black"
    public var trim: MaterialKey = "metal.anodized-worn"
    public var glass: MaterialKey = "glass.display"
    public var grid: MaterialKey = "emissive.holo-grid"
    public var foot: MaterialKey = "rubber"

    func strip(_ m: inout Model, _ w: Float, _ d: Float, _ at: V3) {
        m.add(Prim.extrude(Shape2D.rect(w, d), depth: 0.0006, bevel: 0, bevelSegments: 1, material: grid),
              Xform(translation: at, rotation: simd_quatf(angle: Float.pi / 2, axis: V3(1, 0, 0))))
    }

    func box(_ m: inout Model, _ s: V3, _ r: Float, _ at: V3, _ mat: MaterialKey) {
        m.add(Prim.roundedBox(s, radius: r, bevelSegments: 1, material: mat), Xform(translation: at))
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y, D = size.z
        let footH: Float = 0.05, baseT: Float = 0.04, topT: Float = 0.075, glassT: Float = 0.012
        let topY = H - topT
        // Leveling feet: threaded stem, rubber pad, under the base plate.
        let baseW = W - 0.5, baseD = D - 0.3
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            let x = sx * (baseW / 2 - 0.08), z = sz * (baseD / 2 - 0.08)
            m.add(Prim.cylinder(radius: 0.045, height: 0.02, bevel: 0.006, segments: 16, material: foot), Xform(translation: V3(x, 0, z)))
            m.add(Prim.cylinder(radius: 0.011, height: 0.03, bevel: 0.002, segments: 12, material: "metal.chrome"), Xform(translation: V3(x, 0.02, z)))
            m.add(Prim.cylinder(radius: 0.022, height: 0.008, bevel: 0.002, segments: 6, material: trim), Xform(translation: V3(x, 0.045, z)))
        } }
        // Base plate with machined step.
        box(&m, V3(baseW, baseT, baseD), 0.012, V3(0, footH + baseT / 2, 0), frame)
        box(&m, V3(baseW - 0.04, 0.006, baseD - 0.04), 0.002, V3(0, footH + baseT + 0.003, 0), trim)
        // Pedestal: central column with tapered side wings and a recessed trim reveal.
        let colH = topY - footH - baseT
        box(&m, V3(0.84, colH, 0.46), 0.025, V3(0, footH + baseT + colH / 2, 0), frame)
        for sx: Float in [-1, 1] {
            box(&m, V3(0.06, colH - 0.1, 0.56), 0.02, V3(sx * 0.45, footH + baseT + colH / 2, 0), frame)
            for sz: Float in [-1, 1] {
                box(&m, V3(0.008, colH - 0.2, 0.012), 0.003, V3(sx * 0.483, footH + baseT + colH / 2, sz * 0.2), trim)
            }
        }
        // Horizontal reveal grooves on the front and back.
        for sz: Float in [-1, 1] {
            for k in 0..<3 {
                let y = footH + baseT + 0.12 + Float(k) * 0.2
                box(&m, V3(0.76, 0.006, 0.004), 0.0015, V3(0, y, sz * 0.231), trim)
            }
        }
        // Cable port on the back: recessed trim plate with a dark socket and cable grommet.
        let py = footH + baseT + 0.22
        box(&m, V3(0.16, 0.07, 0.01), 0.008, V3(0.2, py, -0.233), trim)
        box(&m, V3(0.12, 0.04, 0.012), 0.012, V3(0.2, py, -0.236), "rubber")
        m.add(Prim.cylinder(radius: 0.012, height: 0.014, bevel: 0.003, segments: 16, material: "metal.chrome"),
              Xform(translation: V3(0.17, py, -0.238), rotation: simd_quatf(angle: -Float.pi / 2, axis: V3(1, 0, 0))))
        // Recessed shadow step under the top plus socket-head bolts on the wings and base plate.
        box(&m, V3(W - 0.5, 0.03, D - 0.3), 0.008, V3(0, topY - 0.015, 0), frame)
        for sx: Float in [-1, 1] { for k in 0..<3 {
            let z = (Float(k) - 1) * 0.14
            m.add(Prim.cylinder(radius: 0.007, height: 0.004, bevel: 0, segments: 6, material: "metal.chrome"),
                  Xform(translation: V3(sx * 0.48, footH + baseT + colH - 0.06, z), rotation: simd_quatf(angle: sx * -Float.pi / 2, axis: V3(0, 0, 1))))
            m.add(Prim.cylinder(radius: 0.007, height: 0.004, bevel: 0, segments: 6, material: "metal.chrome"),
                  Xform(translation: V3(sx * 0.48, footH + baseT + 0.06, z), rotation: simd_quatf(angle: sx * -Float.pi / 2, axis: V3(0, 0, 1))))
        } }
        // Top: anodized bezel tray, then the glass panel inset 2 mm proud of it.
        box(&m, V3(W, topT, D), 0.018, V3(0, topY + topT / 2, 0), frame)
        box(&m, V3(W - 0.01, 0.004, D - 0.01), 0.002, V3(0, topY - 0.002, 0), trim)
        let gW = W - 0.07, gD = D - 0.07
        m.add(Prim.roundedBox(V3(gW, glassT, gD), radius: 0.004, bevelSegments: 2, material: glass),
              Xform(translation: V3(0, H - glassT / 2, 0)).jittered(&rng))
        let gy = H + 0.0006
        // Emissive grid, thin strips just above the glass surface.
        let nx = Int((gW - 0.1) / gridPitch / 2), nz = Int((gD - 0.1) / gridPitch / 2)
        for i in -nx...nx {
            strip(&m, 0.0012, gD - 0.1, V3(Float(i) * gridPitch, gy, 0))
        }
        for j in -nz...nz {
            strip(&m, gW - 0.1, 0.0012, V3(0, gy, Float(j) * gridPitch))
        }
        // Emissive edge line framing the grid, and corner ticks.
        for sz: Float in [-1, 1] { strip(&m, gW - 0.06, 0.002, V3(0, gy, sz * (gD / 2 - 0.03))) }
        for sx: Float in [-1, 1] { strip(&m, 0.002, gD - 0.06, V3(sx * (gW / 2 - 0.03), gy, 0)) }
        // Status LED on the front bezel.
        box(&m, V3(0.05, 0.003, 0.002), 0.001, V3(0, H - 0.03, D / 2 + 0.0005), grid)
        groundAO(&m)
        return LODModel(m)
    }
}
