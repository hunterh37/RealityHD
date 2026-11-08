import simd
import Foundation

/// Traditional six-sided (toe-pinch) coffin, 1.98 m long, 0.58 m at the shoulders, 0.40 m at the head, 0.30 m at
/// the foot, 0.46 m tall closed: lacquered dark mahogany, stepped plinth and rim mouldings, raised lid panel,
/// three cast brass bar handles per side. The lid is its own part ("lid", entity `joint:lid`); states
/// "closed" and "open" (lifted 0.32 m).
public struct Coffin: RealArticulated {
    public static let id = "coffin"
    public static let summary = "Six-sided lacquered mahogany coffin, 1.98 m: plinth and rim mouldings, raised-panel lid part, six brass bar handles."
    public static let tags = ["prop", "interior", "funeral", "wood", "articulated", "halloween"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 24, distance: 0.9, studio: true)

    public var wood: MaterialKey = "wood.mahogany:3B1810"
    public var trim: MaterialKey = "wood.mahogany:2A100A"
    public var brass: MaterialKey = "metal.brass"
    public var length: Float = 1.98
    public var shoulder: Float = 0.58
    public var head: Float = 0.40
    public var foot: Float = 0.30
    /// Body height under the lid (m).
    public var bodyHeight: Float = 0.36
    public var lidHeight: Float = 0.08
    public init() {}

    /// Six-sided outline in plan (x across, y along the length; head at +y). Counter-clockwise.
    private func outline(_ grow: Float = 0) -> [V2] {
        let hl = length / 2, sy = hl - 0.45
        let raw = [V2(head / 2, hl), V2(-head / 2, hl), V2(-shoulder / 2, sy), V2(-foot / 2, -hl), V2(foot / 2, -hl), V2(shoulder / 2, sy)]
        let o = grow == 0 ? raw : Shape2D.offset(raw, grow)
        return Shape2D.rounded(o, radius: 0.012, segments: 3)
    }

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id)
        let flat = simd_quatf(degrees: -90, axis: V3(1, 0, 0))
        func slab(_ grow: Float, _ y0: Float, _ h: Float, bevel: Float, _ mat: MaterialKey) -> (Surface, Xform) {
            (Prim.extrude(outline(grow), depth: h, bevel: bevel, bevelSegments: 2, material: mat), Xform(translation: V3(0, y0 + h / 2, 0), rotation: flat))
        }
        let H = bodyHeight
        // Body: plinth, main box, rim moulding.
        for (g, y0, h, b, mat) in [(Float(0.022), Float(0), Float(0.045), Float(0.01), trim), (0.012, 0.045, 0.018, 0.006, trim),
                                   (0, 0.06, H - 0.09, 0.004, wood), (0.01, H - 0.035, 0.02, 0.006, trim), (0.018, H - 0.018, 0.018, 0.006, trim)] {
            let (s, x) = slab(g, y0, h, bevel: b, mat)
            rig.base[0].add(s, x)
        }
        // Handles: three per side, on the head-shoulder panel (one) and shoulder-foot panel (two).
        let pts = outline()
        let hl = length / 2, sy = hl - 0.45
        func handle(_ a: V2, _ b: V2, t: Float, side: Float) {
            let p = a + (b - a) * t
            let dir = simd_normalize(b - a)
            let nrm = V2(dir.y, -dir.x) * (side > 0 ? 1 : -1)
            let n3 = V3(nrm.x, 0, -nrm.y), d3 = V3(dir.x, 0, -dir.y)
            let y: Float = H * 0.52
            let base = V3(p.x, y, -p.y) + n3 * 0.003
            let span: Float = 0.24
            // Back plates and arms.
            for s: Float in [-1, 1] {
                let c = base + d3 * (s * span / 2)
                let rot = simd_quatf(from: V3(0, 0, 1), to: n3)
                rig.base[0].add(Prim.superellipsoid(V3(0.05, 0.07, 0.012), exponent: 2.6, subdivisions: 4, material: brass), Xform(translation: c, rotation: rot))
                rig.base[0].add(Prim.tube([c, c + n3 * 0.03 + V3(0, -0.006, 0), c + n3 * 0.05 + V3(0, -0.012, 0)], radii: [0.011, 0.01, 0.0105], sides: 20, seamTile: 0.05, material: brass))
                rig.base[0].add(Prim.superellipsoid(V3(0.026, 0.026, 0.026), exponent: 2, subdivisions: 4, material: brass), Xform(translation: c + n3 * 0.05 + V3(0, -0.012, 0)))
            }
            // Bar.
            var bar: [V3] = [], rr: [Float] = []
            for k in 0...8 {
                let t = Float(k) / 8 - 0.5
                bar.append(base + n3 * (0.05 + 0.006 * (1 - 4 * t * t)) + V3(0, -0.012, 0) + d3 * (t * span)); rr.append(0.0115)
            }
            rig.base[0].add(Prim.tube(bar, radii: rr, sides: 20, seamTile: 0.05, material: brass))
        }
        _ = pts
        let headR = V2(head / 2, hl), shR = V2(shoulder / 2, sy), footR = V2(foot / 2, -hl)
        for side: Float in [1, -1] {
            let f = V2(side, 1)
            handle(shR * f, headR * f, t: 0.5, side: side)
            handle(footR * f, shR * f, t: 0.33, side: side)
            handle(footR * f, shR * f, t: 0.72, side: side)
        }
        // Lid: overhanging slab, stepped edge, raised center panel, all lacquered.
        let ly = H
        rig.part("lid", pivot: V3(0, ly, 0), joint: .slide(axis: .up, 0...0.32, duration: 0.9))
        for (g, y0, h, b, mat) in [(Float(0.026), ly, Float(0.03), Float(0.008), trim), (0.008, ly + 0.03, 0.03, 0.01, wood),
                                   (-0.05, ly + 0.06, 0.022, 0.012, wood)] {
            let (s, x) = slab(g, y0, h, bevel: b, mat)
            rig.add(s, x.jittered(&rng, deg: 0.05, offset: 0.0005), to: "lid")
        }
        // Brass lid escutcheons at the head and foot.
        for z: Float in [-(hl - 0.08), hl - 0.08] {
            rig.add(Prim.cylinder(radius: 0.018, height: 0.004, bevel: 0.0015, segments: 48, bevelSegments: 2, material: brass), Xform(translation: V3(0, ly + 0.061, z)), to: "lid")
        }
        rig.states = [RigState("closed"), RigState("open", ["lid": 0.32])]
        groundAO(&rig, height: 0.08, floor: 0.55)
        return rig
    }
}
