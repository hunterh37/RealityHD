import simd
import Foundation

/// A complete rod: handle style, seat, blank and guide train, material keys. Rods lie along +X with the
/// butt at -X and the reel side (+Y) up; `rig` exposes parts `blank`, `handle`, `reel-seat`, `guides`,
/// `tip-top` (blank, guides and tip-top carry a loaded-bend option).
struct RodSpec {
    var length: Float
    var handle: RodHandleStyle
    var seat: RodSeatStyle
    var y: Float
    var buttR: Float
    var tipR: Float
    var guides: [RodAssembly.Guide]
    var blank: MaterialKey
    var grip: MaterialKey
    var gripWorn: MaterialKey
    var cap: MaterialKey
    var seatMetal: MaterialKey
    var seatAccent: MaterialKey
    var insert: MaterialKey = "wood.seat-burl"
    var wrap: MaterialKey
    var trim: MaterialKey
    var frame: MaterialKey = "metal.chrome"
    var guideInsert: MaterialKey = "ceramic.guide-insert"
    /// Ferrule positions as fractions of the blank (two-piece rods).
    var ferrules: [Float] = []
    /// Tip angle of the loaded bend (radians).
    var bend: Float = 1.15
    /// Guide ring and height scale against the listed train.
    var guideScale: Float = 1
    /// Telescopic section joints as fractions of the exposed blank.
    var telescopic: [Float] = []
    /// Roller guides and roller tip (trolling).
    var roller: Bool = false
    /// Fixed-line rod: no guides, lillian cord at the tip (tenkara).
    var lillian: Bool = false

    var layout: RodLayout { RodLayout.of(handle) }
    var xs: Float { -length / 2 }
    var x1: Float { length / 2 }
    var exposed: Float { xs + layout.gripEnd }

    /// Line exit at the tip-top ring centre.
    var tipTop: V3 {
        if lillian { return V3(x1 + 0.075 + 0.0013, y - 0.004, 0.0015 * sin(3)) }
        if roller { return V3(x1 + 0.004, y + 0.004 + 0.006, 0) }
        let ring: Float = 0.0016, insT = max(0.0006, ring * 0.14)
        return V3(x1 - 0.002, y + tipR + 0.0005 + ring + insT * 1.6, 0)
    }

    var anchors: [String: RealAnchor] {
        ["butt": RealAnchor(V3(xs, y, 0), direction: V3(-1, 0, 0)),
         "tipTop": RealAnchor(tipTop, direction: V3(1, 0, 0)),
         "reelFoot": RealAnchor(V3(xs + layout.footCentre, y + (seat == .none ? 0.0118 : RodAssembly.seatBarrel), 0), direction: V3(0, 1, 0))]
    }

    func rig(name: String, seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: name)
        let L = layout
        let worn = rng.chance(0.5) ? gripWorn : grip
        rig.part("handle", pivot: V3(xs, y, 0), joint: .fixed)
        for s in RodAssembly.handle(handle, xs: xs, y: y, grip: grip, gripWorn: worn, cap: cap, metal: seatMetal, shaft: blank, blankR: buttR) {
            rig.add(s, to: "handle")
        }
        rig.part("reel-seat", pivot: V3(xs + L.footCentre, y, 0), joint: .fixed)
        for s in RodAssembly.seat(seat, x0: xs + L.seatStart, y: y, metal: seatMetal, accent: seatAccent, insert: insert) { rig.add(s, to: "reel-seat") }
        let scaled = guides.map { g in var g = g; g.ring *= guideScale; g.h *= guideScale; return g }
        let set = RodAssembly.blankSet(x0: xs + L.blankButt, x1: x1, exposed: exposed, r0: buttR, r1: tipR, y: y, guides: lillian ? [] : scaled,
                                       blankMat: blank, wrapMat: wrap, trimMat: trim, frame: frame, insert: guideInsert,
                                       ferrules: ferrules.map { exposed + (x1 - exposed) * $0 }, ferruleMat: wrap,
                                       telescopic: telescopic.map { exposed + (x1 - exposed) * $0 }, roller: roller, lillian: lillian)
        let bendLen = x1 - exposed
        func bent(_ s: Surface) -> Surface { RodKit.bend(s, from: exposed, length: bendLen, y: y, tipAngle: bend) }
        rig.part("blank", pivot: V3(exposed, y, 0), joint: .fixed, options: 2)
        rig.part("guides", parent: "blank", pivot: V3(exposed, y, 0), joint: .fixed, options: 2)
        rig.part("tip-top", parent: "blank", pivot: V3(x1, y, 0), joint: .fixed, options: 2)
        for (part, surfaces) in [("blank", set.blank), ("guides", set.guides), ("tip-top", set.tip)] {
            for s in surfaces { rig.add(s, to: part); rig.add(bent(s), to: part, option: 1) }
        }
        rig.states = [RigState("rest"), RigState("loaded", options: ["blank": 1, "guides": 1, "tip-top": 1])]
        groundAO(&rig, height: 0.03, floor: 0.6)
        return rig
    }
}
