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
    /// Short EVA pistol-length rear grip and stub fore grip (spincast combos).
    case compact
    /// Long EVA rear grip for two-handed pitching and heavy casting (flipping, catfish).
    case flip
    /// Surf caster: long split EVA rear (butt grip, bare blank, lower grip), seat high up, long fore grip.
    case surf
    /// Ice rod: short cork rear grip, seat, stub fore grip.
    case ice
    /// Trolling: aluminum gimbal butt, long EVA rear grip, heavy seat, EVA fore grip.
    case trolling
    /// Centerpin float rod: long cork rear grip, seat, long cork fore grip.
    case centerpin
    /// Tenkara: gourd-shaped cork grip with a wooden butt plug, no reel seat.
    case tenkara
}

/// Reel seat styles.
enum RodSeatStyle {
    /// Down-locking anodized aluminum: fixed rear hood, threaded barrel, sliding hood, twin knurled nuts.
    case aluminum
    /// Casting seat: aluminum barrel with a trigger hook below.
    case trigger
    /// Up-locking fly seat: aluminum butt cap and hood, wood insert, sliding hood, knurled nut.
    case woodInsert
    /// No seat (fixed-line rods).
    case none
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
        case .compact: return RodLayout(style: s, seatStart: 0.155, seatLength: 0.10, gripEnd: 0.30, blankButt: 0.016)
        case .flip: return RodLayout(style: s, seatStart: 0.345, seatLength: 0.10, gripEnd: 0.505, blankButt: 0.016)
        case .surf: return RodLayout(style: s, seatStart: 0.56, seatLength: 0.10, gripEnd: 0.83, blankButt: 0.016)
        case .ice: return RodLayout(style: s, seatStart: 0.092, seatLength: 0.10, gripEnd: 0.235, blankButt: 0.012)
        case .trolling: return RodLayout(style: s, seatStart: 0.37, seatLength: 0.10, gripEnd: 0.60, blankButt: 0.03)
        case .centerpin: return RodLayout(style: s, seatStart: 0.37, seatLength: 0.10, gripEnd: 0.66, blankButt: 0.016)
        case .tenkara: return RodLayout(style: s, seatStart: 0.10, seatLength: 0, gripEnd: 0.275, blankButt: 0.01)
        }
    }

    /// Seat centre from the butt (reel foot centre).
    var footCentre: Float { style == .tenkara ? seatStart : seatStart + RodAssembly.footOffset(style == .flyWells ? .woodInsert : .aluminum) }
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
        case .compact:
            out.append(RodKit.buttCap(x0: xs, r: 0.0142, y: y, mat: cap))
            out.append(RodKit.grip(x0: xs + 0.017, shape: [V2(0.0138, 0), V2(0.0146, 0.04), V2(0.0132, 0.1), V2(0.0124, 0.137)], ringPitch: 0, y: y, mat: grip, step: 0.01))
            out.append(RodKit.grip(x0: xs + seatEnd + 0.001, shape: [V2(0.012, 0), V2(0.0104, 0.025), V2(0.0092, 0.043)], ringPitch: 0, y: y, mat: gripWorn, step: 0.01))
        case .flip:
            out.append(RodKit.buttCap(x0: xs, r: 0.0142, y: y, mat: cap))
            out.append(RodKit.grip(x0: xs + 0.017, shape: [V2(0.0136, 0), V2(0.0144, 0.06), V2(0.013, 0.2), V2(0.0123, 0.327)], ringPitch: 0, y: y, mat: grip, step: 0.01))
            out.append(RodKit.grip(x0: xs + seatEnd + 0.001, shape: [V2(0.0122, 0), V2(0.0108, 0.035), V2(0.0094, 0.058)], ringPitch: 0, y: y, mat: gripWorn, step: 0.01))
        case .surf:
            out.append(RodKit.buttCap(x0: xs, r: 0.0158, y: y, mat: cap))
            out.append(RodKit.grip(x0: xs + 0.017, shape: [V2(0.0152, 0), V2(0.0156, 0.05), V2(0.0148, 0.13)], ringPitch: 0, y: y, mat: grip, step: 0.01))
            out.append(RodKit.lathe([V2(0, 0), V2(0.0095, 0), V2(0.0092, L.seatStart)], x0: xs + 0.02, y: y, seg: 16, tile: 0.03, shaft))
            out.append(RodKit.windingCheck(x: xs + 0.147, blankR: 0.0093, y: y, mat: metal))
            out.append(RodKit.windingCheck(x: xs + 0.42, blankR: 0.0093, y: y, mat: metal))
            out.append(RodKit.grip(x0: xs + 0.426, shape: [V2(0.0132, 0), V2(0.0138, 0.06), V2(0.0128, 0.133)], ringPitch: 0, y: y, mat: gripWorn, step: 0.01))
            out.append(RodKit.grip(x0: xs + seatEnd + 0.001, shape: [V2(0.0128, 0), V2(0.0124, 0.08), V2(0.0108, 0.165)], ringPitch: 0, y: y, mat: gripWorn, step: 0.01))
        case .ice:
            out.append(RodKit.buttCap(x0: xs, r: 0.0128, y: y, mat: cap))
            out.append(RodKit.grip(x0: xs + 0.012, shape: [V2(0.0122, 0), V2(0.0128, 0.03), V2(0.012, 0.079)], ringPitch: 0.0127, y: y, mat: grip, step: 0.0063))
            out.append(RodKit.grip(x0: xs + seatEnd + 0.001, shape: [V2(0.0118, 0), V2(0.0104, 0.022), V2(0.0086, 0.04)], ringPitch: 0.0127, y: y, mat: gripWorn, step: 0.0063))
        case .trolling:
            // Gimbal butt: machined aluminum with a cross-slot pin for a rod holder, then a collar.
            out.append(RodKit.lathe([V2(0, 0), V2(0.0135, 0.0005), V2(0.0148, 0.003), V2(0.0148, 0.026), V2(0.0156, 0.028), V2(0.0156, 0.034), V2(0.0138, 0.036)], x0: xs, y: y, seg: 28, tile: 0.03, metal))
            out.append(Prim.cylinder(radius: 0.0022, height: 0.031, bevel: 0.0005, segments: 12, bevelSegments: 1, material: "metal.chrome")
                .transformed(Xform(translation: V3(xs + 0.006, y, -0.0155), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0)))))
            out.append(RodKit.grip(x0: xs + 0.036, shape: [V2(0.0146, 0), V2(0.0152, 0.08), V2(0.0142, 0.25), V2(0.0136, 0.332)], ringPitch: 0, y: y, mat: grip, step: 0.01))
            out.append(RodKit.grip(x0: xs + seatEnd + 0.001, shape: [V2(0.0136, 0), V2(0.014, 0.05), V2(0.0124, 0.128)], ringPitch: 0, y: y, mat: gripWorn, step: 0.01))
        case .centerpin:
            out.append(RodKit.buttCap(x0: xs, r: 0.0138, y: y, mat: cap))
            out.append(RodKit.grip(x0: xs + 0.017, shape: [V2(0.013, 0), V2(0.0138, 0.09), V2(0.0128, 0.25), V2(0.012, 0.352)], ringPitch: 0.0127, y: y, mat: grip, step: 0.0063))
            out.append(RodKit.grip(x0: xs + seatEnd + 0.001, shape: [V2(0.0122, 0), V2(0.0124, 0.06), V2(0.0112, 0.14), V2(0.0098, 0.188)], ringPitch: 0.0127, y: y, mat: gripWorn, step: 0.0063))
        case .tenkara:
            // Wooden butt plug, then a gourd cork grip (narrow waist, swelling toward the front).
            out.append(RodKit.lathe([V2(0, 0), V2(0.0075, 0.0005), V2(0.0098, 0.004), V2(0.0102, 0.012), V2(0.0098, 0.014)], x0: xs, y: y, seg: 24, tile: 0.03, "wood.seat-burl"))
            out.append(RodKit.grip(x0: xs + 0.014, shape: [V2(0.0112, 0), V2(0.0128, 0.03), V2(0.0112, 0.09), V2(0.0124, 0.17), V2(0.0132, 0.21), V2(0.0098, 0.258)], ringPitch: 0.0127, y: y, mat: grip, step: 0.0063))
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
                    let t = Float(i) / 11
                    path.append(V3(x0 + 0.03 - 0.012 * t + 0.008 * sin(t * .pi), y - b - 0.001 - 0.021 * sin(t * .pi * 0.62) + 0.002 * t, 0))
                }
                out.append(Prim.sweep(Shape2D.roundedRect(0.0055, 0.009, radius: 0.0024), along: path, up: V3(0, 0, 1), material: metal))
            }
        case .none:
            break
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

    static let spincastGuides: [Guide] = [
        Guide(t: 0.14, ring: 0.0065, h: 0.02, double: true), Guide(t: 0.32, ring: 0.005, h: 0.015), Guide(t: 0.49, ring: 0.0042, h: 0.0125),
        Guide(t: 0.64, ring: 0.0038, h: 0.011), Guide(t: 0.78, ring: 0.0035, h: 0.0098), Guide(t: 0.9, ring: 0.0032, h: 0.0088),
    ]
    static let surfGuides: [Guide] = [
        Guide(t: 0.12, ring: 0.025, h: 0.075, double: true), Guide(t: 0.29, ring: 0.016, h: 0.05, double: true), Guide(t: 0.45, ring: 0.011, h: 0.034, double: true),
        Guide(t: 0.6, ring: 0.008, h: 0.025), Guide(t: 0.73, ring: 0.0062, h: 0.019), Guide(t: 0.84, ring: 0.0052, h: 0.016), Guide(t: 0.93, ring: 0.0045, h: 0.014),
    ]
    static let iceGuides: [Guide] = [
        Guide(t: 0.16, ring: 0.0062, h: 0.019, double: true), Guide(t: 0.4, ring: 0.0052, h: 0.015), Guide(t: 0.62, ring: 0.0046, h: 0.013),
        Guide(t: 0.8, ring: 0.0042, h: 0.0115), Guide(t: 0.93, ring: 0.004, h: 0.0105),
    ]
    static let trollingGuides: [Guide] = [
        Guide(t: 0.13, ring: 0.0065, h: 0.022), Guide(t: 0.3, ring: 0.0065, h: 0.021), Guide(t: 0.46, ring: 0.0065, h: 0.02),
        Guide(t: 0.61, ring: 0.0065, h: 0.019), Guide(t: 0.75, ring: 0.0065, h: 0.018), Guide(t: 0.88, ring: 0.0065, h: 0.017),
    ]
    static let centerpinGuides: [Guide] = {
        (0..<12).map { i in
            let t = 0.07 + 0.88 * Float(i) / 11
            return Guide(t: t, ring: 0.0062 - 0.0032 * Float(i) / 11, h: 0.02 - 0.0105 * Float(i) / 11, double: i < 2)
        }
    }()
    /// Telescopic rods: one guide near the top of each section (the guides ride on the section ends).
    static func telescopicGuides(_ joints: [Float]) -> [Guide] {
        var g: [Guide] = []
        let ends = joints + [1]
        for (i, e) in ends.enumerated() {
            let f = Float(i) / Float(max(1, ends.count - 1))
            g.append(Guide(t: e - 0.035, ring: 0.011 - 0.0075 * f, h: 0.032 - 0.021 * f, double: i == 0))
        }
        return g
    }

    /// A blank with its hardware: blank (with trim wrap and hook keeper), guides, tip-top.
    struct BlankSet { var blank: [Surface] = []; var guides: [Surface] = []; var tip: [Surface] = [] }

    /// Builds a blank from `x0` to `x1` at axis height `y`; guides placed over the exposed part from `exposed`.
    static func blankSet(x0: Float, x1: Float, exposed: Float, r0: Float, r1: Float, y: Float, guides: [Guide], blankMat: MaterialKey,
                         wrapMat: MaterialKey, trimMat: MaterialKey, frame: MaterialKey, insert: MaterialKey, ferrules: [Float] = [],
                         ferruleMat: MaterialKey? = nil, telescopic: [Float] = [], roller: Bool = false, lillian: Bool = false) -> BlankSet {
        var set = BlankSet()
        set.blank.append(RodKit.blank(x0: x0, x1: x1, r0: r0, r1: r1, y: y, mat: blankMat))
        func r(_ x: Float) -> Float { RodKit.blankRadius(x, x0: x0, x1: x1, r0: r0, r1: r1) }
        // Telescopic joints: the larger section's flared lip over the next one, with a section stop ring.
        for j in telescopic {
            let jr = r(j)
            set.blank.append(RodKit.lathe([V2(jr * 0.98, 0), V2(jr + 0.0011, 0.0012), V2(jr + 0.0013, 0.009), V2(jr + 0.0016, 0.0115), V2(jr + 0.0004, 0.013), V2(jr * 0.98, 0.0132)], x0: j - 0.013, y: y, seg: 16, tile: 0.02, trimMat))
        }
        if lillian {
            // Fixed-line tip: no wraps or guides; a braided lillian cord glued over the tip, knotted at the end.
            let tipEnd = x1 + 0.075
            var path: [V3] = []
            for i in 0...10 { let t = Float(i) / 10; path.append(V3(x1 - 0.012 + (tipEnd - x1 + 0.012) * t, y - 0.004 * t * t, 0.0015 * sin(t * 3))) }
            set.tip.append(Prim.tube(path, radii: path.map { _ in 0.0006 }, sides: 6, seamTile: 0.005, material: "thread.red"))
            set.tip.append(Prim.superellipsoid(V3(0.0026, 0.0026, 0.0026), exponent: 2, subdivisions: 4, material: "thread.red").transformed(Xform(translation: path.last!)))
            set.tip.append(RodKit.lathe([V2(r(x1 - 0.02) * 0.98, 0), V2(r(x1 - 0.02) + 0.0004, 0.001), V2(r1 + 0.0004, 0.014), V2(r1 * 0.98, 0.015)], x0: x1 - 0.02, y: y, seg: 10, tile: 0.01, "thread.red"))
            return set
        }
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
            if roller {
                set.guides += RodKit.rollerGuide(x: gx, h: g.h, blankR: r(gx), y: y, frame: frame, roller: "metal.brass", wrap: wrapMat)
            } else if g.snake {
                set.guides += RodKit.snakeGuide(x: gx, ring: g.ring, blankR: r(gx), y: y, frame: frame, wrap: wrapMat)
            } else {
                set.guides += RodKit.ringGuide(x: gx, ring: g.ring, h: g.h, blankR: r(gx), y: y, frame: frame, insert: insert, wrap: wrapMat, double: g.double)
            }
        }
        set.tip = roller ? RodKit.rollerTip(x: x1, blankR: r1, y: y, frame: frame, roller: "metal.brass")
                         : RodKit.tipTop(x: x1, ring: 0.0016, blankR: r1, y: y, frame: frame, insert: insert)
        return set
    }
}
