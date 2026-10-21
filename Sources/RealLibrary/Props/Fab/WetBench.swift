import simd
import Foundation

/// Semiconductor wet bench, generic, 4 x 2.2 x 1.5 m. White PVDF/polypropylene cabinet and deck with four recessed chemical
/// baths and two DI rinse tanks, rear exhaust plenum, clear sash (named part "sash") sliding up in a stainless frame,
/// control panel column at the right end, chemical splash marks on the deck.
public struct WetBench: RealArticulated {
    public static let id = "wet-bench"
    public static let summary = "Wet bench: white PVDF deck with recessed baths, DI rinse tanks, clear sliding sash, exhaust plenum, control panel."
    public static let tags = ["prop", "semiconductor", "articulated"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 20, distance: 1.0, studio: true)

    /// Deck and cabinet plastic (sRGB hex tint of plastic.pvdf is not applied; panels use this tint on plastic.matte accents).
    public var accent: UInt32 = 0x2F5E8C
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        _ = seed
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [10])
        let pv: MaterialKey = "plastic.pvdf", steel: MaterialKey = "metal.stainless", anod: MaterialKey = "metal.anodized"
        let black: MaterialKey = "plastic.matte:1E2023", glass: MaterialKey = "glass.window-tint"
        let ptfe: MaterialKey = "plastic.matte:8EA2AC"
        rig.part("sash", pivot: V3(-0.2, 1.5, 0.66), joint: .slide(axis: V3(0, 1, 0), 0...0.75, duration: 3))
        let dy: Float = 0.9           // deck top
        for l in 0..<2 {
            let k = ClusterKit(rig: rig, lod: l)
            let hi = k.hi
            // Cabinet base x -2..2, z -0.75..0.75, toe kick, doors with gaps.
            k.bx(V3(3.9, 0.1, 1.4), V3(0, 0.06, 0), "metal.powdercoat:34373C", r: 0.003)
            k.bx(V3(4.0, dy - 0.04 - 0.1, 1.5), V3(0, (dy - 0.04 + 0.1) / 2, 0), pv, r: 0.006)
            for q in 0..<8 {
                let x = -1.75 + Float(q) * 0.5
                k.bx(V3(0.012, 0.7, 0.01), V3(x + 0.25, 0.5, 0.755), black, r: 0)
                k.bx(V3(0.012, 0.12, 0.012), V3(x + (q % 2 == 0 ? 0.42 : 0.08), 0.62, 0.77), steel, r: 0.002)
            }
            // Deck slab built around recesses. Deck x -2..2, z -0.75..0.75, y dy-0.04..dy.
            let bx0: [Float] = [-1.9, -1.25, -0.6, 0.05], bw: Float = 0.55
            let dx0: [Float] = [0.75, 1.25], dw: Float = 0.42
            let rz0: Float = -0.3, rz1: Float = 0.42
            var cuts: [(Float, Float)] = bx0.map { ($0, $0 + bw) } + dx0.map { ($0, $0 + dw) }
            cuts.sort { $0.0 < $1.0 }
            var xcur: Float = -2.0
            let dyc = dy - 0.02
            for (a, b) in cuts {
                if a > xcur { k.bx(V3(a - xcur, 0.04, 1.5), V3((a + xcur) / 2, dyc, 0), pv, r: 0.004) }
                // Front and rear strips beside the recess.
                k.bx(V3(b - a, 0.04, rz0 + 0.75), V3((a + b) / 2, dyc, (-0.75 + rz0) / 2), pv, r: 0.004)
                k.bx(V3(b - a, 0.04, 0.75 - rz1), V3((a + b) / 2, dyc, (0.75 + rz1) / 2), pv, r: 0.004)
                xcur = b
            }
            k.bx(V3(2.0 - xcur, 0.04, 1.5), V3((2.0 + xcur) / 2, dyc, 0), pv, r: 0.004)
            // Bath liners: four walls, floor, liquid surface, overflow weir.
            let liquids: [MaterialKey] = ["plastic.matte:3A6A8A", "plastic.matte:8A6A3A", "plastic.matte:5A8A6A", "plastic.matte:7A5A8A", "glass.clear", "glass.clear"]
            for (i, (a, b)) in cuts.enumerated() {
                let w = b - a, cx = (a + b) / 2, d = rz1 - rz0, cz = (rz0 + rz1) / 2
                k.bx(V3(w, 0.02, d), V3(cx, dy - 0.38, cz), ptfe, r: 0)
                k.bx(V3(0.015, 0.36, d), V3(a + 0.0075, dy - 0.2, cz), ptfe, r: 0)
                k.bx(V3(0.015, 0.36, d), V3(b - 0.0075, dy - 0.2, cz), ptfe, r: 0)
                k.bx(V3(w, 0.36, 0.015), V3(cx, dy - 0.2, rz0 + 0.0075), ptfe, r: 0)
                k.bx(V3(w, 0.36, 0.015), V3(cx, dy - 0.2, rz1 - 0.0075), ptfe, r: 0)
                k.bx(V3(w - 0.03, 0.004, d - 0.03), V3(cx, dy - 0.07 - Float(i % 3) * 0.01, cz), liquids[i], r: 0)
                k.bx(V3(w + 0.02, 0.008, 0.02), V3(cx, dy + 0.004, rz0 - 0.012), anod, r: 0.001)
                k.bx(V3(w + 0.02, 0.008, 0.02), V3(cx, dy + 0.004, rz1 + 0.012), anod, r: 0.001)
                k.bx(V3(w - 0.08, 0.003, 0.05), V3(cx, dy + 0.001, rz0 + 0.028), "metal.stainless", r: 0)   // bath grating
                if hi {
                    k.bx(V3(w + 0.03, 0.012, 0.012), V3(cx, dy + 0.006, rz1 + 0.008), anod, r: 0.002)
                    k.cyl(0.018, 0.006, V3(cx, dy - 0.385, cz), steel, seg: 10)   // drain
                    if i < 4 { k.cyl(0.02, 0.1, V3(a + 0.05, dy - 0.3, rz0 + 0.04), "quartz", seg: 8) }   // heater / immersion probe
                }
            }
            // Wafer cassette resting in bath 2: PFA carrier.
            k.bx(V3(0.24, 0.18, 0.2), V3(-1.25 + 0.275, dy - 0.13, 0.06), "plastic.matte:E8E4D8", r: 0.004)
            if hi { for q in 0..<5 { k.bx(V3(0.24, 0.004, 0.19), V3(-0.975, dy - 0.2 + Float(q) * 0.03, 0.06), "silicon.thinfilm", r: 0) } }
            // Rear wall x -2..2 and side walls, z -0.75..0.75, y dy..1.95.
            let wt: Float = 0.04, top: Float = 1.95
            k.bx(V3(4.0, top - dy, wt), V3(0, (top + dy) / 2, -0.75 + wt / 2), pv, r: 0.004)
            k.bx(V3(wt, top - dy, 1.5), V3(-2 + wt / 2, (top + dy) / 2, 0), pv, r: 0.004)
            k.bx(V3(wt, top - dy, 1.5), V3(2 - wt / 2, (top + dy) / 2, 0), pv, r: 0.004)
            k.bx(V3(3.92, 0.03, 1.46), V3(0, top - 0.015, 0), pv, r: 0.003)
            // Header above the sash and sash track uprights.
            k.bx(V3(3.9, 0.35, 0.05), V3(0, top - 0.175, 0.7), pv, r: 0.004)
            k.bx(V3(0.06, 0.65, 0.05), V3(-1.55, 1.52, 0.7), steel, r: 0.002)
            k.bx(V3(0.06, 0.65, 0.05), V3(1.15, 1.52, 0.7), steel, r: 0.002)
            // Sash: clear panel in stainless frame, pull handle (named part).
            let s = "sash"
            k.bx(V3(2.7, 0.6, 0.01), V3(-0.2, 1.5, 0.66), glass, r: 0, name: s)
            for (c, sz) in [(V3(-0.2, 1.8, 0.66), V3(2.76, 0.04, 0.03)), (V3(-0.2, 1.2, 0.66), V3(2.76, 0.04, 0.03)),
                            (V3(-1.55, 1.5, 0.66), V3(0.04, 0.6, 0.03)), (V3(1.15, 1.5, 0.66), V3(0.04, 0.6, 0.03))] { k.bx(sz, c, steel, r: 0.002, name: s) }
            k.put(barHandle(length: 0.5, standoff: 0.04, radius: 0.012, material: steel), Xform(translation: V3(-0.2, 1.2, 0.68)), s)
            // Panel seams and vents on side and rear walls.
            for q in 0..<5 { k.bx(V3(0.012, top - dy - 0.4, 0.004), V3(-1.6 + Float(q) * 0.8, 1.35, -0.752), black, r: 0) }
            for sx: Float in [-1, 1] {
                k.bx(V3(0.004, 0.012, 1.46), V3(sx * 2.002, 1.4, 0), black, r: 0)
                for q in 0..<6 { k.bx(V3(0.004, 0.02, 0.5), V3(sx * 2.002, 1.55 + Float(q) * 0.04, -0.3), black, r: 0) }
            }
            k.bx(V3(0.004, 0.3, 0.3), V3(2.003, 1.15, 0.4), "plastic.matte:EEEEEA", r: 0)
            // Exhaust plenum on top, duct collar.
            k.bx(V3(3.6, 0.2, 0.7), V3(0, top + 0.1, -0.35), pv, r: 0.01)
            k.bx(V3(3.6, 0.02, 0.5), V3(0, top + 0.21, -0.35), steel, r: 0.002)
            k.cyl(0.2, 0.04, V3(-0.4, top + 0.2, -0.35), steel, seg: hi ? 20 : 8)
            k.cyl(0.18, 0.01, V3(1.2, top + 0.21, -0.35), black, seg: hi ? 20 : 8)
            if hi { for q in 0..<9 { k.bx(V3(0.04, 0.012, 0.3), V3(-1.55 + Float(q) * 0.38, top - 0.13, -0.5), black, r: 0) } }
            // Rear wall: DI gooseneck faucets over DI tanks, N2 guns on hoses, spray bars.
            for x in dx0 {
                let cx = x + dw / 2
                k.tube(catmull([V3(cx, dy + 0.1, -0.7), V3(cx, dy + 0.45, -0.68), V3(cx, dy + 0.5, -0.5), V3(cx, dy + 0.4, rz0 + 0.2)], per: hi ? 4 : 2), 0.012, steel, sides: 8)
                k.cyl(0.016, 0.04, V3(cx, dy + 0.33, rz0 + 0.2), anod, seg: 8)
                k.bx(V3(0.1, 0.1, 0.05), V3(cx, dy + 0.1, -0.7), steel, r: 0.003)
            }
            k.tube(catmull([V3(0.8, 1.2, -0.72), V3(0.9, 1.0, -0.6), V3(1.5, 1.05, -0.45), V3(1.55, 0.95, -0.2)], per: hi ? 4 : 2), 0.007, "rubber.tubing", sides: 6)
            // Control panel column at the right end x 1.65..1.95, sloped screen, e-stop, buttons, status lamps.
            let px: Float = 1.8
            k.bx(V3(0.3, 0.46, 0.3), V3(px, dy + 0.23, 0.4), pv, r: 0.006)
            k.bx(V3(0.26, 0.2, 0.012), V3(px, dy + 0.4, 0.552), black, r: 0.004)
            k.bx(V3(0.22, 0.15, 0.004), V3(px, dy + 0.4, 0.559), "glass.lamp:2A6AC0", r: 0.001)
            for q in 0..<4 { k.bx(V3(0.035, 0.035, 0.012), V3(px - 0.09 + Float(q) * 0.06, dy + 0.27, 0.556), q == 3 ? "glass.lamp:E03020" : "plastic.matte:3A3C40", r: 0.004) }
            k.cyl(0.026, 0.02, V3(px, dy + 0.46, 0.2), "glass.lamp:E03020", seg: 12)
            k.cyl(0.015, 0.1, V3(px, dy + 0.46, 0.12), black, seg: 8)
            // Splash marks and stains (deck level, mm thick) and hazard labels.
            let stains: [(Float, Float, Float, Float, String)] = [(-1.62, 0.58, 0.4, 0.16, "C8B070"), (-0.95, 0.56, 0.3, 0.12, "9A7040"), (-0.3, 0.6, 0.36, 0.1, "B8B4A8"),
                                                              (0.38, 0.51, 0.16, 0.1, "7A9A8A"), (-1.1, -0.45, 0.28, 0.07, "C0A860"), (0.9, 0.6, 0.12, 0.08, "A0B8C8")]
            for (x, z, w, d, c) in stains { k.bx(V3(w, 0.0008, d), V3(x, dy + 0.0006, z), MaterialKey(stringLiteral: "plastic.matte:" + c), r: 0) }
            for (i, c) in ["E8C21A", "E03020", "E8C21A", "2F8FC0"].enumerated() { k.bx(V3(0.07, 0.07, 0.003), V3(-1.62 + Float(i) * 0.65, dy + 0.3, -0.725), MaterialKey(stringLiteral: "plastic.matte:" + c), r: 0.001) }
            k.bx(V3(3.0, 0.012, 0.006), V3(0, 0.3, 0.76), "plastic.yellow", r: 0.0005)
            rig = k.rig
            rig.base[l] = k.m
        }
        groundAO(&rig, height: 0.15, floor: 0.6)
        rig.states = [RigState("closed"), RigState("open", ["sash": 0.75])]
        return rig
    }
}
