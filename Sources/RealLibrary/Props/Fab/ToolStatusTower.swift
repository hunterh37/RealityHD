import simd
import Foundation

/// Four-lamp tool status tower, 0.05 x 0.4 x 0.05 m: bracket, pole, stacked translucent lamps red/amber/green/blue (bottom to top), buzzer cap.
public struct ToolStatusTower: RealAsset {
    public static let id = "tool-status-tower"
    public static let summary = "Tool status tower: mounting bracket, pole, four stacked translucent lamps, buzzer cap, lamp state knob."
    public static let tags = ["prop", "semiconductor"]
    public static let budget = 600
    public static let author = "realityhd"

    /// Lamp state bitmask: bit 0 red, 1 amber, 2 green, 3 blue. Set bits glow (`glass.lamp`), clear bits are dark translucent.
    public var lampState: Int = 0b0100
    public init() {}

    private func cyl(_ r: Float, _ h: Float, _ y: Float, _ mat: MaterialKey, _ seg: Int = 12) -> (Surface, Xform) {
        (Prim.lathe([V2(0, 0), V2(r, 0), V2(r, h), V2(0, h)], segments: seg, seamTile: 0.4, material: mat), Xform(translation: V3(0, y + h / 2, 0)))
    }
    private func box(_ s: V3, _ c: V3, _ mat: MaterialKey) -> (Surface, Xform) {
        (cuboid(s, material: mat), Xform(translation: c))
    }

    public func build(seed: UInt64) -> LODModel {
        _ = seed
        var m = Model(name: Self.id)
        func add(_ p: (Surface, Xform)) { m.add(p.0, p.1) }
        let steel: MaterialKey = "metal.stainless", anod: MaterialKey = "metal.anodized", black: MaterialKey = "plastic.matte:1E2023"
        // L bracket: base plate with slotted holes, upright, gusset.
        add(box(V3(0.05, 0.004, 0.05), V3(0, 0.002, 0), steel))
        add(box(V3(0.036, 0.034, 0.004), V3(0, 0.021, -0.02), steel))
        add(box(V3(0.004, 0.026, 0.02), V3(0.014, 0.017, -0.01), steel))
        add(box(V3(0.004, 0.026, 0.02), V3(-0.014, 0.017, -0.01), steel))
        add(cyl(0.012, 0.01, 0.004, anod, 8))
        add(cyl(0.0065, 0.07, 0.014, steel, 6))
        // Lamps: base ring, dark inner core with LED disc, translucent lens, grooves, divider ring.
        let cols = ["E03020", "F0A020", "30C050", "2A70E8"]
        var y: Float = 0.08
        for (i, c) in cols.enumerated() {
            let lit = lampState & (1 << i) != 0
            add(cyl(0.0255, 0.006, y, black, 10))
            add(cyl(0.012, 0.06, y + 0.006, lit ? MaterialKey(stringLiteral: "glass.lamp:" + c) : "plastic.matte:2A2C2F", 6))
            let lens = cyl(0.0245, 0.058, y + 0.006, MaterialKey(stringLiteral: "plastic.translucent:" + c), 10)
            add(lens)
            y += 0.068
        }
        // Buzzer: grille cap with slots, top knob.
        add(cyl(0.0255, 0.044, y, "plastic.matte:2A2C2F", 10))
        add(cyl(0.0125, 0.008, y + 0.044, black, 8))
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(0, -b.min.y, 0)))
        return LODModel(m)
    }
}
