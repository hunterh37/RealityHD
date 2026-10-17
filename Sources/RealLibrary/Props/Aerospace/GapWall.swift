import simd
import Foundation

/// Flight-course wall: a galvanized core frame clad on both faces with orange and white checker panels on
/// a concrete strip footing. An optional full-height vertical slot (centre x, width) cuts it in two; the slot
/// jambs carry yellow and black hazard bands and LED edge strips. `slotWidth = 0` builds a solid barrier.
/// Sizes come from course data (`200 x 100 x 2` and up); panel modules grow with the wall.
public struct GapWall: RealAsset {
    public static let id = "gap-wall"
    public static let summary = "Course wall, any size: checker-clad galvanized frame on a footing, optional full-height slot with hazard jambs and LED strips."
    public static let tags = ["prop", "aerospace", "outdoor", "barrier", "wall", "metal"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 12, distance: 1.05)

    /// Wall length along X, height and thickness in meters.
    public var width: Float = 24
    public var height: Float = 8
    public var thickness: Float = 1
    /// Vertical slot centre (x, from the wall centre) and width; width 0 = no slot.
    public var slotCenter: Float = 3
    public var slotWidth: Float = 5
    public var orange: MaterialKey = "metal.rack-powdercoat:E2561B"
    public var white: MaterialKey = "metal.rack-powdercoat:E6E2D8"
    public var frame: MaterialKey = "metal.galvanized"
    public var hazardYellow: MaterialKey = "metal.signal-yellow"
    public var hazardBlack: MaterialKey = "metal.painted:1C1C1C"
    public var led: MaterialKey = "emissive.signal-white"
    public var footing: MaterialKey = "concrete.rough"
    public init() {}

    /// Solid x-intervals of the wall.
    public var spans: [(Float, Float)] {
        let x0 = -width / 2, x1 = width / 2
        guard slotWidth > 0 else { return [(x0, x1)] }
        let s0 = max(x0, slotCenter - slotWidth / 2), s1 = min(x1, slotCenter + slotWidth / 2)
        return [(x0, s0), (s1, x1)].filter { $0.1 - $0.0 > 0.05 }
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(seed: seed, detail: true), level(seed: seed, detail: false)],
                 switchDistances: [max(30, max(width, height) * 2)])
    }

    func level(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let t = thickness, foot: Float = min(0.45, height * 0.05)
        let module = max(2.0, (width * height / 48).squareRoot())
        let rows = max(1, Int((height - foot) / module + 0.5))
        let ph = (height - foot) / Float(rows)
        let skin = max(0.03, t * 0.06), gap = min(0.05, module * 0.015)
        let edge: Float = detail ? min(0.02, skin * 0.4) : 0.004
        let slotEdges = slotWidth > 0 ? [slotCenter - slotWidth / 2, slotCenter + slotWidth / 2] : []
        for (a, b) in spans {
            let len = b - a, mid = (a + b) / 2
            // footing and galvanized core
            m.add(Prim.roundedBox(V3(len, foot, t + 0.5), radius: 0.03, bevelSegments: 1, material: footing),
                  Xform(translation: V3(mid, foot / 2, 0)))
            m.add(Prim.roundedBox(V3(len - 0.02, height - foot, t - skin * 2 - 0.004), radius: 0.01, bevelSegments: 1, material: frame),
                  Xform(translation: V3(mid, foot + (height - foot) / 2, 0)))
            // checker cladding, both faces
            let cols = max(1, Int(len / module + 0.5))
            let pw = len / Float(cols)
            for c in 0..<cols {
                for r in 0..<rows {
                    // global checker phase so both halves line up across the slot
                    let gc = Int(((a + pw * (Float(c) + 0.5)) + width) / module)
                    var mat = (gc + r) % 2 == 0 ? orange : white
                    // one replacement panel, fresher paint than its neighbours
                    if detail && c == 2 && r == min(2, rows - 1) && a < -width / 2 + 0.01 { mat = mat == orange ? "metal.rack-powdercoat:F06A28" : "metal.rack-powdercoat:F2F1EC" }
                    // bottom row: dust splash from the ground dulls the paint
                    if r == 0 { mat = mat == orange ? "metal.rack-powdercoat:B9532A" : "metal.rack-powdercoat:C9C0AE" }
                    for z in [Float(-1), 1] {
                        let p = V3(a + pw * (Float(c) + 0.5), foot + ph * (Float(r) + 0.5), z * (t / 2 - skin / 2))
                        let panel = Prim.extrude(Shape2D.rect(pw - gap, ph - gap), depth: skin, bevel: edge, bevelSegments: 1, material: mat)
                        m.add(panel,
                              Xform(translation: p, rotation: simd_quatf(degrees: rng.float(-0.05...0.05), axis: V3(0, 0, 1))))
                    }
                }
            }
            // galvanized battens over the row seams, both faces
            for r in 0...rows {
                for z in [Float(-1), 1] {
                    let by = foot + ph * Float(r)
                    m.add(Prim.extrude(Shape2D.rect(len - 0.04, min(0.12, ph * 0.06)), depth: 0.025, bevel: 0.006, bevelSegments: 1, material: frame),
                          Xform(translation: V3(mid, by, z * (t / 2 + 0.012))))
                    if detail {
                        for c in 0...cols {
                            let bx = min(b - 0.1, max(a + 0.1, a + pw * Float(c)))
                            rivet(&m, at: V3(bx, by, z * (t / 2 + 0.025)), normal: V3(0, 0, z), radius: 0.022, segments: 6, material: frame)
                        }
                    }
                }
            }
            // cap beam
            m.add(Prim.roundedBox(V3(len + 0.02, 0.12, t + 0.06), radius: 0.02, bevelSegments: 1, material: frame),
                  Xform(translation: V3(mid, height + 0.06, 0)))
            // jambs: open ends get a hazard-banded post; the slot side also an LED strip on both faces
            for x in [a, b] {
                let isSlot = slotEdges.contains { abs($0 - x) < 0.01 }
                let dir: Float = x == a ? 1 : -1
                let jw: Float = min(0.6, t * 0.5 + 0.1)
                let bandH = max(0.5, module / 4)
                let nb = Int(((height - foot) / bandH).rounded(.up))
                for i in 0..<nb {
                    let y0 = foot + Float(i) * bandH, y1 = min(height, y0 + bandH)
                    m.add(Prim.extrude(Shape2D.rect(jw, y1 - y0 - 0.004), depth: t + 0.04, bevel: edge, bevelSegments: 1,
                                       material: i % 2 == 0 ? hazardYellow : hazardBlack),
                          Xform(translation: V3(x + dir * jw / 2, (y0 + y1) / 2, 0)))
                }
                if isSlot {
                    for z in [Float(-1), 1] {
                        m.add(Prim.extrude(Shape2D.rect(0.05, height - foot - 0.2), depth: 0.05, bevel: 0.008, bevelSegments: 1, material: led),
                              Xform(translation: V3(x - dir * 0.012, foot + (height - foot) / 2, z * t * 0.3)))
                    }
                }
            }
        }
        groundAO(&m)
        return m
    }
}
