import simd
import Foundation

/// Louvered bifold closet door, 1.2 m x 2.03 m x 0.1 m overall: two bifold pairs of painted pine leaves (32 mm) with 40 mm stiles,
/// rails and angled slats, a head track with top pivot guides, bottom pivot plates, butt hinges at each fold, finger knobs at the
/// meeting stiles and plain casing with a head cap on both faces. Origin at the bottom center of the opening; each pair folds
/// toward +Z about its jamb pivot (fold joint mimics -2x).
public struct BifoldClosetDoor: RealArticulated {
    public static let id = "bifold-closet-door"
    public static let summary = "Four-foot louvered bifold closet door: two folding pairs of painted louvered leaves on a head track, pivots, hinges and finger knobs."
    public static let tags = ["structure", "floorplan", "home", "wood", "metal", "interior", "door", "articulated"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 6, distance: 1.5, studio: true)

    public var width: Float = 1.2
    public var height: Float = 2.03
    public var depth: Float = 0.1
    public var leafThickness: Float = 0.032
    public var paint: MaterialKey = "wood.painted-shaker:E0DACB"
    public var leafPaint: MaterialKey = "wood.painted-shaker-worn:E0DACB"
    public var hardware: MaterialKey = "metal.brushed-nickel"
    /// Slat tilt from horizontal (degrees).
    public var slatTilt: Float = 38
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [8])
        let T = leafThickness
        var c = DoorKit.Casing(openW: 0, openH: 0, wallT: depth - 0.033, material: paint)
        c.casingW = 0.045; c.casingT = 0.014; c.capOver = 0.006; c.capH = 0.012; c.jambT = 0.017
        c.withStop = false; c.bead = false
        c.openW = width - 2 * (c.reveal + c.casingW + c.capOver)
        c.openH = height - c.reveal - c.casingW - c.capH
        let g: Float = 0.004
        let yb: Float = 0.012, yt = c.openH - 0.022       // leaf bottom clears the floor; top clears the track
        let H = yt - yb
        let pw = (c.openW / 2 - g - 0.002 - 0.002) / 2
        let ss = hardware
        for l in 0..<2 {
            var m = Model(name: Self.id)
            c.build(&m, detail: l == 0)
            // Head track (black channel) and the top pivot guide blocks.
            m.add(cuboid(V3(c.openW, 0.016, 0.034), material: "plastic.black"), Xform(translation: V3(0, c.openH - 0.008, 0)))
            m.add(cuboid(V3(c.openW - 0.01, 0.003, 0.02), material: ss), Xform(translation: V3(0, c.openH - 0.0165, 0)))
            // Bottom pivot plates on the floor at each jamb.
            for sx: Float in [-1, 1] {
                m.add(Prim.cylinder(radius: 0.016, height: 0.004, bevel: 0.001, segments: 14, bevelSegments: 1, material: ss),
                      Xform(translation: V3(sx * (c.openW / 2 - g - 0.012), 0, 0)))
            }
            rig.base[l] = m
        }

        let slat = Float(slatTilt) * .pi / 180
        func leaf(_ part: String, x0: Float, x1: Float) {
            let st: Float = 0.04, tr: Float = 0.07, br: Float = 0.09
            let cx = (x0 + x1) / 2, cy = (yb + yt) / 2
            for sx: Float in [0, 1] {
                let s = DoorKit.vbox(V3(st, H, T), V3(sx == 0 ? x0 + st / 2 : x1 - st / 2, cy, 0), leafPaint, r: 0.003)
                rig.add(s.0, s.1, to: part)
            }
            let tp = DoorKit.box(V3(x1 - x0 - 2 * st + 0.002, tr, T), V3(cx, yt - tr / 2, 0), leafPaint, r: 0.003)
            let bt = DoorKit.box(V3(x1 - x0 - 2 * st + 0.002, br, T), V3(cx, yb + br / 2, 0), leafPaint, r: 0.003)
            rig.add(tp.0, tp.1, to: part); rig.add(bt.0, bt.1, to: part)
            // Slats, tilted so the exposed lower edge sheds toward the front.
            let y0 = yb + br, y1 = yt - tr
            let pitch: Float = 0.04
            let n = Int((y1 - y0) / pitch)
            let w = x1 - x0 - 2 * st + 0.002
            for i in 0..<n {
                let y = y0 + (Float(i) + 0.5) * (y1 - y0) / Float(n)
                let q = simd_quatf(angle: -slat, axis: V3(1, 0, 0))
                rig.add(cuboid(V3(w, 0.005, 0.044), material: leafPaint), Xform(translation: V3(cx, y, 0), rotation: q), to: part)
            }
        }
        for side: Float in [-1, 1] {
            let outer = side * (c.openW / 2 - g)                 // jamb edge of the pair
            let aX = side < 0 ? outer : outer - pw              // outer leaf x0
            let n1 = side < 0 ? "L1" : "R1", n2 = side < 0 ? "L2" : "R2"
            let axis = V3(0, -side, 0)
            rig.part(n1, pivot: V3(outer, 0, 0), joint: .hinge(axis: axis, 0...88, duration: 1.5))
            let foldX = side < 0 ? outer + pw + 0.001 : outer - pw - 0.001
            rig.part(n2, parent: n1, pivot: V3(foldX, 0, 0.0),
                     joint: Joint(.revolute, axis: axis, range: -176...0, mimic: .init(n1, ratio: -2)))
            leaf(n1, x0: side < 0 ? outer : outer - pw, x1: side < 0 ? outer + pw : outer)
            let o2 = side < 0 ? outer + pw + 0.002 : outer - pw - 0.002
            leaf(n2, x0: side < 0 ? o2 : o2 - pw, x1: side < 0 ? o2 + pw : o2)
            // Fold hinges: three small nickel butt hinges, frame knuckles on the outer leaf.
            DoorKit.hinges(&rig, leaf: n2, side: side < 0 ? -1 : 1, pinX: foldX, pinZ: T / 2 - 0.001, ys: [0.3, 1.0, 1.7],
                           length: 0.075, knuckle: 0.0045, plate: 0.02, mat: ss, fixedPart: n1, finials: false, knuckleSegments: 8)
            // Finger knob at the meeting stile of the inner leaf.
            let kx = side < 0 ? o2 + pw - 0.02 : o2 - pw + 0.02
            let knob = Prim.lathe([V2(0, 0), V2(0.004, 0), V2(0.004, 0.012), V2(0.012, 0.016), V2(0.016, 0.024), V2(0.013, 0.031), V2(0, 0.033)],
                                  segments: 14, seamTile: 0.05, material: leafPaint)
            rig.add(knob, Xform(translation: V3(kx, 1.0, T / 2), rotation: facing(V3(0, 0, 1))), to: n2)
        }
        // Story detail: dust-line scuff on the floor and a worn patch near the knobs handled by the worn paint.
        let sc = DoorKit.box(V3(0.12, 0.004, 0.02), V3(0.1, 0.002, 0.04), "decal.rubber-scuff", r: 0)
        rig.base[0].add(sc.0, sc.1)

        groundAO(&rig, height: 0.15, floor: 0.6)
        rig.states = [RigState("closed"), RigState("open", ["L1": 85, "R1": 85])]
        return rig
    }
}
