import simd
import Foundation

/// Z-fold rigid-panel solar array wing, 30 x 0.1 x 6 m: ten 2.7 m panels, each a carbon-skinned honeycomb tray with an aluminum
/// edge frame and a Kapton-backed grid of 8 x 4 cm triple-junction cells (cell grid is the material), hinged in a chain
/// with titanium knuckles and pins, a root spar with drive housing and slip-ring box, and a tip lock bar.
/// Parts: base root spar, deploy (hinge, panel 1), fold2..fold10 (each mimics deploy at -/+2x).
/// States: deployed, half, stowed. Base y = 0, wing runs along +X from x = -15.
public struct SolarArrayWing: RealArticulated {
    public static let id = "solar-array-wing"
    public static let summary = "Z-fold solar array wing: ten hinged cell-grid panels with carbon trays, edge frames, knuckles and a root drive spar."
    public static let tags = ["prop", "articulated", "space", "solar", "datacenter"]
    public static let budget = 4000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 40, distance: 1.0, studio: true)

    /// Panel count and width along Z (m).
    public var panelCount = 10
    public var panelWidth: Float = 6
    public var cells: MaterialKey = "solar.cell"
    public var back: MaterialKey = "solar.kapton"
    public var tray: MaterialKey = "composite.carbon"
    public var frame: MaterialKey = "metal.aluminum-brushed"
    public var hardware: MaterialKey = "metal.titanium"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 1)
        let W = panelWidth, n = panelCount, x0: Float = -14.6
        let pitch = (15 - 0.4 - x0 - 0.0 + 14.6 - 0.0) / Float(n) // panel pitch
        let pl = (30 - 0.4) / Float(n) - 0.02
        _ = pitch
        let T: Float = 0.05, y: Float = 0.05
        func B(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.002) { let (a, x) = OK.box(s, c, mat, r: r); rig.base[0].add(a, x) }
        // Root spar along Z with drive housing, slip-ring box and cable loops.
        let (spar, sx) = OK.cylZ(0.045, W, x: -14.75, y: 0.05, z0: -W / 2, hardware, seg: 16); rig.base[0].add(spar, sx)
        B(V3(0.3, 0.09, 0.6), V3(-14.85, 0.045, 0), frame, r: 0.006)
        B(V3(0.18, 0.07, 0.4), V3(-14.88, 0.045, 1.2), "plastic.matte:2A2D33", r: 0.004)
        for sz: Float in [-1, 1] {
            rig.base[0].add(Prim.tube(catmull([V3(-14.85, 0.06, sz * 0.3), V3(-14.95, 0.075, sz * 0.9), V3(-14.8, 0.07, sz * 1.5)], per: 4), radii: Array(repeating: 0.012, count: 9), sides: 6, seamTile: 0.2, material: "mli.blanket"))
        }
        var bolts = Model(name: "bolts")
        for k in 0..<4 { OK.bolt(&bolts, at: V3(-14.85, 0.09, -0.25 + Float(k % 2) * 0.16 + (k < 2 ? 0 : 1.2) - 0.0), size: 0.012, hardware) }
        rig.base[0].add(bolts)

        var parent: String? = nil
        for i in 0..<n {
            let name = i == 0 ? "deploy" : "fold\(i + 1)"
            let hx = x0 + Float(i) * (pl + 0.02) - 0.0
            let hinge = i == 0 ? Joint.hinge(axis: V3(0, 0, 1), 0...90, duration: 6)
                : Joint(.revolute, axis: V3(0, 0, 1), range: (i % 2 == 1 ? -180...0 : 0...180), duration: 6, mimic: .init("deploy", ratio: i % 2 == 1 ? -2 : 2))
            rig.part(name, parent: parent, pivot: V3(hx, y, 0), joint: hinge)
            let xc = hx + 0.01 + pl / 2
            func A(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.0015) { let (a, x) = OK.box(s, c, mat, r: r); rig.add(a, x, to: name) }
            // Tray, edge frame, cell face and Kapton back.
            A(V3(pl - 0.04, T - 0.012, W - 0.04), V3(xc, y, 0), tray, r: 0.002)
            for sz: Float in [-1, 1] { A(V3(pl, 0.062, 0.03), V3(xc, y, sz * (W / 2 - 0.015)), frame, r: 0.003) }
            for xe: Float in [-1, 1] { A(V3(0.03, 0.062, W - 0.06), V3(xc + xe * (pl / 2 - 0.015), y, 0), frame, r: 0.003) }
            A(V3(pl - 0.07, 0.003, W - 0.07), V3(xc, y + T / 2 - 0.004, 0), cells, r: 0.0005)
            A(V3(pl - 0.07, 0.003, W - 0.07), V3(xc, y - T / 2 + 0.004, 0), back, r: 0.0005)
            // Cross stiffener rib visible at the edge, hinge knuckles on the leading edge, pin caps.
            for k in 0..<3 {
                let z = -2.0 + Float(k) * 2.0
                let (a, x) = OK.cylZ(0.03, 0.34, x: hx, y: y, z0: z - 0.17, hardware, seg: 8, bevel: 0); rig.add(a, x, to: name)
            }
            // Per-panel harness tie-downs (kapton tape) along the long edges.
            for sz: Float in [-1, 1] { A(V3(0.05, 0.004, 0.02), V3(xc + rng.float(-0.8...0.8), y + T / 2 + 0.0, sz * (W / 2 - 0.045)), "metal.steel", r: 0.001) }
            parent = name
        }
        // Tip lock bar on the last panel.
        let (lb, lx) = OK.box(V3(0.12, 0.08, W - 0.3), V3(x0 + Float(n) * (pl + 0.02) - 0.06, y, 0), frame, r: 0.004)
        rig.add(lb, lx, to: "fold\(n)")
        groundAO(&rig, height: 0.05, floor: 0.7)
        rig.states = [RigState("deployed"), RigState("half", ["deploy": 45]), RigState("stowed", ["deploy": 90])]
        return rig
    }
}
