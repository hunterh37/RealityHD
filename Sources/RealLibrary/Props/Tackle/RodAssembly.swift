import simd
import Foundation

/// Handle styles shared by complete rods and the handle component assets.
enum RodHandleStyle {
    /// Full cork: rear grip, reel seat gap, tapered fore grip (spinning).
    case cork
    /// Full EVA: long rear grip, seat gap, short fore grip (baitcasting).
    case eva
    /// Split cork rear grip with exposed blank between the pieces.
    case split
    /// Full-wells cork fly grip in front of a butt reel seat.
    case flyWells
}

/// Reel seat styles.
enum RodSeatStyle {
    /// Down-locking anodized aluminum: fixed rear hood, threaded barrel, sliding hood, twin knurled nuts.
    case aluminum
    /// Casting seat: aluminum barrel with a trigger hook below.
    case trigger
    /// Up-locking fly seat: aluminum butt cap and hood, wood insert, sliding hood, knurled nut.
    case woodInsert
}

/// Handle layout along +X from the butt end (`xs`): where the seat sits and where the blank leaves the grip.
struct RodLayout {
    var style: RodHandleStyle
    /// Seat start and length, measured from the butt.
    var seatStart: Float
    var seatLength: Float
    /// Front of the grip (winding check), from the butt.
    var gripEnd: Float
    /// Point inside the handle where the blank butt sits, from the butt.
    var blankButt: Float

    static func of(_ s: RodHandleStyle) -> RodLayout {
        switch s {
        case .cork: return RodLayout(style: s, seatStart: 0.236, seatLength: 0.10, gripEnd: 0.452, blankButt: 0.016)
        case .eva: return RodLayout(style: s, seatStart: 0.25, seatLength: 0.10, gripEnd: 0.41, blankButt: 0.016)
        case .split: return RodLayout(style: s, seatStart: 0.244, seatLength: 0.10, gripEnd: 0.41, blankButt: 0.016)
        case .flyWells: return RodLayout(style: s, seatStart: 0, seatLength: 0.092, gripEnd: 0.27, blankButt: 0.01)
        }
    }

    /// Seat centre from the butt (reel foot centre).
    var footCentre: Float { seatStart + RodAssembly.footOffset(style == .flyWells ? .woodInsert : .aluminum) }
}

enum RodAssembly {
    /// Seat barrel radius (top of the barrel carries the reel foot).
    static let seatBarrel: Float = 0.0108
    /// Reel foot centre from the seat's rear end (between the hoods).
    static func footOffset(_ s: RodSeatStyle) -> Float { s == .woodInsert ? 0.037 : 0.0405 }
    /// Seat length.
    static func seatLength(_ s: RodSeatStyle) -> Float { s == .woodInsert ? 0.092 : 0.10 }

    /// Grip surfaces for a handle style: butt cap, grips, winding check (and shaft for split grips).
    static func handle(_ h: RodHandleStyle, xs: Float, y: Float, grip: MaterialKey, gripWorn: MaterialKey, cap: MaterialKey,
                       metal: MaterialKey, shaft: MaterialKey, blankR: Float) -> [Surface] {
        let L = RodLayout.of(h)
        var out: [Surface] = []
        let seatEnd = L.seatStart + L.seatLength
        switch h {
        case .cork:
            out.append(RodKit.buttCap(x0: xs, r: 0.0136, y: y, mat: cap))
            out.append(RodKit.grip(x0: xs + 0.017, shape: [V2(0.0128, 0), V2(0.0137, 0.07), V2(0.013, 0.16), V2(0.012, 0.218)], ringPitch: 0.0127, y: y, mat: grip))
            out.append(RodKit.grip(x0: xs + seatEnd + 0.001, shape: [V2(0.0124, 0), V2(0.0121, 0.03), V2(0.0098, 0.11)], ringPitch: 0.0127, y: y, mat: gripWorn))
        case .eva:
            out.append(RodKit.buttCap(x0: xs, r: 0.0138, y: y, mat: cap))
            out.append(RodKit.grip(x0: xs + 0.017, shape: [V2(0.0132, 0), V2(0.014, 0.05), V2(0.0128, 0.15), V2(0.0122, 0.232)], ringPitch: 0, y: y, mat: grip))
            out.append(RodKit.grip(x0: xs + seatEnd + 0.001, shape: [V2(0.0122, 0), V2(0.0108, 0.035), V2(0.0094, 0.058)], ringPitch: 0, y: y, mat: gripWorn))
        case .split:
            out.append(RodKit.buttCap(x0: xs, r: 0.0132, y: y, mat: cap))
            out.append(RodKit.grip(x0: xs + 0.017, shape: [V2(0.0128, 0), V2(0.0132, 0.03), V2(0.0124, 0.07)], ringPitch: 0.0127, y: y, mat: grip))
            out.append(RodKit.lathe([V2(0, 0), V2(0.0072, 0), V2(0.0069, L.seatStart)], x0: xs + 0.02, y: y, seg: 16, tile: 0.03, shaft))
            out.append(RodKit.windingCheck(x: xs + 0.087, blankR: 0.0071, y: y, mat: metal))
            out.append(RodKit.lathe([V2(0.0069, 0), V2(0.0098, 0.0005), V2(0.0098, 0.005), V2(0.0069, 0.0055)], x0: xs + 0.1625, y: y, seg: 20, tile: 0.02, metal))
            out.append(RodKit.grip(x0: xs + 0.168, shape: [V2(0.0118, 0), V2(0.0125, 0.04), V2(0.0122, 0.075)], ringPitch: 0.0127, y: y, mat: gripWorn))
            out.append(RodKit.grip(x0: xs + seatEnd + 0.001, shape: [V2(0.0122, 0), V2(0.0108, 0.035), V2(0.0094, 0.064)], ringPitch: 0.0127, y: y, mat: gripWorn))
        case .flyWells:
            out.append(RodKit.grip(x0: xs + seatEnd + 0.002, shape: [V2(0.0118, 0), V2(0.0148, 0.028), V2(0.0129, 0.075), V2(0.0153, 0.13), V2(0.0112, 0.172), V2(0.0098, 0.176)],
                                   ringPitch: 0.0127, y: y, mat: grip))
        }
        out.append(RodKit.windingCheck(x: xs + L.gripEnd - 0.002, blankR: blankR, y: y, mat: metal))
        // Arbor: the tube the grips are glued on (the blank runs inside it); shows in the seat gap of a bare handle.
        do {
            out.append(RodKit.lathe([V2(0, 0), V2(0.0074, 0.0004), V2(0.0074, L.gripEnd - 0.004), V2(0, L.gripEnd - 0.0036)], x0: xs + 0.012, y: y, seg: 16, tile: 0.03, shaft))
        }
        return out
    }

    /// Hood shell over the reel foot: an annular sector (top, +Y) extruded along X.
    static func hood(x0: Float, len: Float, y: Float, inner: Float, outer: Float, mat: MaterialKey) -> Surface {
        var pts: [V2] = []
        let a0: Float = .pi * 0.22, a1: Float = .pi * 0.78
        for i in 0...10 { let a = a0 + (a1 - a0) * Float(i) / 10; pts.append(V2(cos(a) * outer, sin(a) * outer)) }
        for i in (0...10).reversed() { let a = a0 + (a1 - a0) * Float(i) / 10; pts.append(V2(cos(a) * inner, sin(a) * inner)) }
        return Prim.extrude(pts, depth: len, bevel: 0.0006, bevelSegments: 1, material: mat)
            .transformed(Xform(translation: V3(x0 + len / 2, y, 0), rotation: simd_quatf(angle: .pi / 2, axis: V3(0, 1, 0))))
    }

    /// Knurled lock nut: a ring with fine ridges.
    static func nut(x0: Float, len: Float, r: Float, y: Float, mat: MaterialKey) -> Surface {
        var p: [V2] = [V2(seatBarrel * 0.98, 0), V2(r - 0.0008, 0.0002), V2(r, 0.0012)]
        let n = Int(len / 0.0016)
        for i in 1..<n { p.append(V2(i % 2 == 0 ? r : r - 0.00035, len * Float(i) / Float(n))) }
        p += [V2(r, len - 0.0012), V2(r - 0.0008, len - 0.0002), V2(seatBarrel * 0.94, len)]
        return RodKit.lathe(p, x0: x0, y: y, seg: 28, tile: 0.02, mat)
    }

    /// Reel seat surfaces from `x0`. The reel foot sits on top of the barrel at `RodLayout.footCentre`.
    static func seat(_ s: RodSeatStyle, x0: Float, y: Float, metal: MaterialKey, accent: MaterialKey, insert: MaterialKey) -> [Surface] {
        let b = seatBarrel
        var out: [Surface] = []
        switch s {
        case .aluminum, .trigger:
            // Barrel with a flat foot track on top, threads toward the front.
            out.append(RodKit.lathe([V2(0, 0), V2(b * 0.9, 0), V2(b, 0.001), V2(b, 0.07), V2(b * 0.93, 0.071), V2(b * 0.93, 0.1), V2(0, 0.1)], x0: x0, y: y, seg: 28, tile: 0.03, metal))
            var thread: [V2] = []
            for i in 0...24 { thread.append(V2(i % 2 == 0 ? b * 0.93 : b * 0.985, 0.071 + 0.022 * Float(i) / 24)) }
            out.append(RodKit.lathe(thread, x0: x0, y: y, seg: 28, tile: 0.02, metal))
            // Fixed rear hood: collar plus shell.
            out.append(RodKit.lathe([V2(b * 0.98, 0), V2(0.0126, 0.0006), V2(0.0129, 0.004), V2(0.0129, 0.014), V2(b * 0.99, 0.0145)], x0: x0, y: y, seg: 28, tile: 0.03, metal))
            out.append(hood(x0: x0 + 0.012, len: 0.011, y: y, inner: b + 0.0018, outer: b + 0.003, mat: metal))
            // Sliding front hood and two knurled nuts (accent anodize).
            out.append(hood(x0: x0 + 0.058, len: 0.011, y: y, inner: b + 0.0018, outer: b + 0.003, mat: metal))
            out.append(RodKit.lathe([V2(b * 0.99, 0), V2(0.0127, 0.0005), V2(0.0127, 0.009), V2(b * 0.99, 0.0095)], x0: x0 + 0.068, y: y, seg: 28, tile: 0.03, metal))
            out.append(nut(x0: x0 + 0.078, len: 0.011, r: 0.0138, y: y, mat: accent))
            out.append(nut(x0: x0 + 0.09, len: 0.009, r: 0.0133, y: y, mat: accent))
            if s == .trigger {
                // Trigger hook under the seat (finger rest), swept flat bar.
                var path: [V3] = []
                for i in 0...12 {
                    let t = Float(i) / 12
                    path.append(V3(x0 + 0.03 - 0.012 * t + 0.008 * sin(t * .pi), y - b - 0.001 - 0.021 * sin(t * .pi * 0.62) + 0.002 * t, 0))
                }
                out.append(Prim.sweep(Shape2D.roundedRect(0.0055, 0.009, radius: 0.0024), along: path, up: V3(0, 0, 1), material: metal))
            }
        case .woodInsert:
            // Butt cap: closed aluminum end with a rounded shoulder, then the fixed hood.
            out.append(RodKit.lathe([V2(0, 0), V2(0.0105, 0.0004), V2(0.0128, 0.003), V2(0.0132, 0.008), V2(0.0132, 0.016), V2(b * 1.02, 0.0165)], x0: x0, y: y, seg: 28, tile: 0.03, metal))
            out.append(hood(x0: x0 + 0.014, len: 0.01, y: y, inner: b + 0.0018, outer: b + 0.003, mat: metal))
            // Wood insert with a mortised foot slot (the reel foot rides in the slot).
            out.append(RodKit.lathe([V2(b * 0.95, 0), V2(0.0118, 0.0008), V2(0.0118, 0.054), V2(b * 0.95, 0.055)], x0: x0 + 0.016, y: y, seg: 28, tile: 0.04, insert))
            // Up-locking sliding hood, threads, knurled nut, front check ring.
            out.append(hood(x0: x0 + 0.05, len: 0.01, y: y, inner: b + 0.0018, outer: b + 0.003, mat: metal))
            out.append(RodKit.lathe([V2(b * 0.99, 0), V2(0.0125, 0.0005), V2(0.0125, 0.008), V2(b * 0.99, 0.0085)], x0: x0 + 0.059, y: y, seg: 28, tile: 0.03, metal))
            out.append(nut(x0: x0 + 0.068, len: 0.014, r: 0.0136, y: y, mat: accent))
            out.append(RodKit.lathe([V2(b * 0.96, 0), V2(0.0122, 0.001), V2(0.0122, 0.008), V2(0.0105, 0.0095)], x0: x0 + 0.082, y: y, seg: 28, tile: 0.03, metal))
        }
        return out
    }

    /// Guide position: fraction of the exposed blank from the grip, ring inner radius, ring height above the axis, double foot.
    struct Guide { var t: Float; var ring: Float; var h: Float; var double: Bool = false; var snake: Bool = false }

    static let spinningGuides: [Guide] = [
        Guide(t: 0.22, ring: 0.0125, h: 0.040, double: true), Guide(t: 0.40, ring: 0.008, h: 0.027, double: true),
        Guide(t: 0.55, ring: 0.0055, h: 0.019), Guide(t: 0.68, ring: 0.0045, h: 0.015), Guide(t: 0.785, ring: 0.004, h: 0.012),
        Guide(t: 0.865, ring: 0.0035, h: 0.0105), Guide(t: 0.935, ring: 0.0033, h: 0.0095),
    ]
    static let castingGuides: [Guide] = [
        Guide(t: 0.12, ring: 0.0055, h: 0.018, double: true), Guide(t: 0.24, ring: 0.0045, h: 0.014), Guide(t: 0.35, ring: 0.004, h: 0.012),
        Guide(t: 0.46, ring: 0.0037, h: 0.011), Guide(t: 0.56, ring: 0.0035, h: 0.010), Guide(t: 0.65, ring: 0.0033, h: 0.0095),
        Guide(t: 0.735, ring: 0.0032, h: 0.009), Guide(t: 0.81, ring: 0.003, h: 0.0085), Guide(t: 0.88, ring: 0.003, h: 0.008),
        Guide(t: 0.945, ring: 0.003, h: 0.0078),
    ]
    static let flyGuides: [Guide] = [
        Guide(t: 0.12, ring: 0.0045, h: 0.016, double: true), Guide(t: 0.21, ring: 0.0038, h: 0.013, double: true),
        Guide(t: 0.30, ring: 0.0034, h: 0, snake: true), Guide(t: 0.385, ring: 0.0032, h: 0, snake: true),
        Guide(t: 0.465, ring: 0.003, h: 0, snake: true), Guide(t: 0.54, ring: 0.0029, h: 0, snake: true),
        Guide(t: 0.61, ring: 0.0028, h: 0, snake: true), Guide(t: 0.68, ring: 0.0027, h: 0, snake: true),
        Guide(t: 0.745, ring: 0.0026, h: 0, snake: true), Guide(t: 0.81, ring: 0.0025, h: 0, snake: true),
        Guide(t: 0.87, ring: 0.0024, h: 0, snake: true), Guide(t: 0.93, ring: 0.0023, h: 0, snake: true),
    ]

    /// A blank with its hardware: blank (with trim wrap and hook keeper), guides, tip-top.
    struct BlankSet { var blank: [Surface] = []; var guides: [Surface] = []; var tip: [Surface] = [] }

    /// Builds a blank from `x0` to `x1` at axis height `y`; guides placed over the exposed part from `exposed`.
    static func blankSet(x0: Float, x1: Float, exposed: Float, r0: Float, r1: Float, y: Float, guides: [Guide], blankMat: MaterialKey,
                         wrapMat: MaterialKey, trimMat: MaterialKey, frame: MaterialKey, insert: MaterialKey, ferrules: [Float] = [],
                         ferruleMat: MaterialKey? = nil) -> BlankSet {
        var set = BlankSet()
        set.blank.append(RodKit.blank(x0: x0, x1: x1, r0: r0, r1: r1, y: y, mat: blankMat))
        func r(_ x: Float) -> Float { RodKit.blankRadius(x, x0: x0, x1: x1, r0: r0, r1: r1) }
        // Trim wrap above the grip (a decorative band with a contrasting thread line), and the hook keeper.
        set.blank.append(RodKit.wrap(x: exposed + 0.006, len: 0.03, r: r(exposed + 0.02), y: y, mat: wrapMat))
        set.blank.append(RodKit.wrap(x: exposed + 0.022, len: 0.003, r: r(exposed + 0.022) + 0.0004, y: y, mat: trimMat))
        set.blank += RodKit.hookKeeper(x: exposed + 0.07, blankR: r(exposed + 0.07), y: y, frame: frame, wrap: wrapMat)
        // Ferrules (multi-piece rods): a thicker wrapped joint.
        for f in ferrules {
            let fr = r(f)
            set.blank.append(RodKit.lathe([V2(fr * 0.98, 0), V2(fr + 0.0009, 0.002), V2(fr + 0.0011, 0.045), V2(fr * 0.98, 0.047)], x0: f - 0.03, y: y, seg: 14, tile: 0.02, ferruleMat ?? wrapMat))
        }
        for g in guides {
            let gx = exposed + (x1 - exposed) * g.t
            if g.snake {
                set.guides += RodKit.snakeGuide(x: gx, ring: g.ring, blankR: r(gx), y: y, frame: frame, wrap: wrapMat)
            } else {
                set.guides += RodKit.ringGuide(x: gx, ring: g.ring, h: g.h, blankR: r(gx), y: y, frame: frame, insert: insert, wrap: wrapMat, double: g.double)
            }
        }
        set.tip = RodKit.tipTop(x: x1, ring: 0.0016, blankR: r1, y: y, frame: frame, insert: insert)
        return set
    }
}
