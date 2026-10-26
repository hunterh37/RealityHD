import simd
import Foundation

/// Driver area of a 2024 Freightliner Cascadia sleeper cab at 1:1. Cab floor at y = 0, X centered on the cab,
/// driver faces +Z, driver seat on +X (US left-hand drive), passenger seat on -X, sleeper opening at -Z.
/// Air-ride high-back seat with armrests and quilted grey/black vinyl, 18 in four-spoke wheel with buttons,
/// wraparound dash, 12 in digital cluster, center infotainment screen, DT12 stalk on the right of the column,
/// yellow diamond parking brake and red octagon trailer air supply knobs, split windshield, door panels with
/// window openings, overhead console, visors and West Coast mirrors.
///
/// Parts: `steering` (-900...900 about the column), `speedNeedle` and `rpmNeedle` (0...270), `throttle` (0...18),
/// `brake` (0...20), `shifter` (DT12 stalk, -20 R ... 0 ... 20 D), `parkingBrake` and `trailerSupply` (pull
/// 0...0.04 m), `wiperLeft` and `wiperRight` (0...75). States `parked`, `driving`, `wipers`.
public struct CascadiaCabInterior: RealArticulated {
    public static let id = "cascadia-cab-interior"
    public static let summary = "Freightliner Cascadia 2024 sleeper cab driver area at 1:1: air-ride seats, four-spoke wheel, wraparound dash, digital cluster, DT12 stalk, air brake knobs, split windshield, mirrors."
    public static let tags = ["prop", "vehicle", "plastic", "glass", "interior", "electronics", "articulated"]
    public static let budget = 30_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 215, elevation: 48, distance: 1.0, studio: true)

    /// Seated driver eye point (asset space, meters): 0.5 m toward the door side of the cab centerline, 1.30 m
    /// above the floor, 0.20 m behind the cab-floor origin. Floor center is the asset origin.
    public static let driverEye = SIMD3<Float>(0.5, 1.30, -0.20)
    /// Driver centerline X (seat, wheel, column, pedals).
    static let dx: Float = 0.5
    /// Steering wheel center and column axis (toward the driver).
    public static let steeringCenter = V3(0.5, 0.98, 0.36)
    public static let steeringAxis = simd_normalize(V3(0, 0.5, -0.87))

    /// Dash plastic.
    public var dash: MaterialKey = "plastic.dash:4A4D52"
    /// Seat upholstery (center panels).
    public var seat: MaterialKey = "vinyl.seat-grey"
    /// Seat bolsters and trim.
    public var bolster: MaterialKey = "vinyl.seat-grey:2C2D30"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [5])
        let black: MaterialKey = "plastic.black", chrome: MaterialKey = "metal.chrome"
        let trim: MaterialKey = "plastic.dash:3C3E42", glass: MaterialKey = "glass.cabin"
        let cx = Self.dx
        // Windshield plane: bottom edge at (z 1.05, y 0.98), rake up and back.
        let u = simd_normalize(V3(0, 0.903, -0.43)), n = simd_normalize(V3(0, 0.43, 0.903))
        let g0 = V3(0, 0.98, 1.05)
        func gp(_ x: Float, _ t: Float, off: Float = 0) -> V3 { g0 + V3(x, 0, 0) + u * t + n * off }
        let dashX: [Float] = [1.02, 0.85, 0.5, 0, -0.5, -0.85, -1.02]
        let dashZ: [Float] = [0.30, 0.62, 0.78, 0.80, 0.78, 0.62, 0.30]
        let dashPath = catmull(zip(dashX, dashZ).map { V3($0, 0.86, $1) }, per: 6)

        func fb(_ size: V3, _ c: V3, _ mat: MaterialKey) -> Surface { cuboid(size, material: mat).transformed(Xform(translation: c)) }
        for l in 0..<2 {
            var m = Model(name: Self.id)
            let hi = l == 0
            let s = hi ? 2 : 1
            // Floor, driver mat, center console, step sill.
            m.add(VK.span(V3(-1.1, 0, -0.95), V3(1.1, 0.03, 0.95), "rubber.floor-mat:3A3B3E", r: 0.006))
            m.add(VK.span(V3(cx - 0.4, 0.03, -0.1), V3(cx + 0.4, 0.034, 0.95), "rubber.floor-mat:2A2B2D", r: 0.002))
            // Wear: scuffed lighter mat patch under the pedals and a worn driver seat entry bolster.
            m.add(VK.span(V3(cx - 0.22, 0.034, 0.5), V3(cx + 0.2, 0.0355, 0.84), "rubber.floor-mat:55575A", r: 0.001))
            if hi { for k in 0..<10 { m.add(cuboid(V3(0.7, 0.004, 0.01), material: "rubber.floor-mat"), Xform(translation: V3(cx, 0.036, 0.1 + Float(k) * 0.08))) } }
            m.add(VK.span(V3(-0.14, 0.03, -0.45), V3(0.14, 0.46, 0.5), trim, r: 0.02, seg: s))
            m.add(VK.span(V3(-0.11, 0.46, -0.3), V3(0.11, 0.475, 0.0), "plastic.gloss:121417", r: 0.004))
            // Toe board and knee bolster.
            m.add(VK.span(V3(-1.05, 0.03, 0.88), V3(1.05, 0.62, 0.98), dash, r: 0.02, seg: s))
            m.add(VK.span(V3(-1.0, 0.3, 0.62), V3(1.0, 0.7, 0.9), dash, r: 0.03, seg: s))
            // Wraparound dash: swept rounded bar following the curved plan path.
            m.add(Prim.sweep(Shape2D.roundedRect(0.30, 0.50, radius: 0.05, segments: s), along: dashPath, up: .up, caps: true, material: dash))
            // Dash top pad under the glass (soft touch) and defrost vent strip.
            m.add(Prim.sweep(Shape2D.roundedRect(0.02, 0.36, radius: 0.008, segments: 1), along: dashPath.map { $0 + V3(0, 0.155, 0.05) }, up: .up, caps: true, material: "plastic.soft-touch"))
            // Silver accent strip along the dash face and stitched door inserts.
            m.add(Prim.sweep(Shape2D.roundedRect(0.012, 0.012, radius: 0.003, segments: 1), along: dashPath.map { $0 + V3(0, -0.03, -0.248) }, up: .up, caps: true, material: "metal.aluminum-brushed"))
            for sg: Float in [-1, 1] {
                m.add(VK.span(V3(sg * 1.05, 0.46, -0.45), V3(sg * 1.07, 0.6, 0.75), "vinyl.seat-grey:3A3C40", r: 0.006))
                m.add(VK.span(V3(sg * 1.045, 0.703, -0.45), V3(sg * 1.075, 0.74, 0.75), "metal.aluminum-brushed", r: 0.003))
            }
            // Cluster binnacle and bezel (12 in cluster, 0.30 x 0.11 m screen).
            let cz: Float = 0.64, cyy: Float = 1.12
            m.add(VK.side(Shape2D.rounded([V2(0.58, 0.9), V2(0.6, 1.14), V2(0.76, 1.2), V2(0.84, 1.1), V2(0.8, 0.9)], radius: 0.025, segments: s), width: 0.46, x: cx, bevel: 0.012, seg: s, mat: dash))
            m.add(HK.box(V3(0.34, 0.14, 0.014), V3(cx, cyy, cz - 0.004), "plastic.gloss:0C0D0F", r: 0.004, seg: 1))
            m.add(HK.rect("screen.cluster", center: V3(cx, cyy, cz - 0.0125), right: V3(-1, 0, 0), up: .up, w: 0.30, h: 0.11))
            // Center infotainment screen (emissive) in a bezel on the center stack.
            m.add(HK.box(V3(0.27, 0.17, 0.03), V3(0, 0.9, 0.545), "plastic.gloss:0C0D0F", r: 0.006, seg: 1))
            m.add(HK.rect("screen.cluster", center: V3(0, 0.9, 0.529), right: V3(-1, 0, 0), up: .up, w: 0.24, h: 0.14))
            // Switch rows under the screen and left vents.
            m.add(VK.span(V3(-0.15, 0.74, 0.525), V3(0.15, 0.8, 0.55), trim, r: 0.004))
            if hi {
                for k in 0..<7 { m.add(fb(V3(0.02, 0.026, 0.01), V3(-0.12 + Float(k) * 0.04, 0.77, 0.52), black)) }
                for k in 0..<5 { m.add(fb(V3(0.09, 0.004, 0.012), V3(cx + 0.38, 0.8 + Float(k) * 0.012, 0.52), black)) }
            }
            // Warning lamp strip above the cluster.
            m.add(HK.box(V3(0.14, 0.008, 0.004), V3(cx, cyy + 0.085, cz - 0.01), "emissive.led-red", r: 0.001, seg: 1))
            // Gauge dials drawn on the cluster: speed (driver's left, +X) and rpm.
            for gx in [cx + 0.085, cx - 0.085] {
                m.add(Prim.torus(major: 0.048, minor: 0.002, segments: hi ? 28 : 12, sides: 4, material: "emissive.signal-white")
                    .transformed(Xform(translation: V3(gx, cyy, cz - 0.0135), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0)))))
                if hi {
                    for k in 0...12 {
                        let a = Float.pi * 1.25 - Float(k) / 12 * Float.pi * 1.5
                        m.add(cuboid(V3(0.0018, 0.006, 0.0008), material: "emissive.signal-white"),
                              Xform(translation: V3(gx - cos(a) * 0.04, cyy + sin(a) * 0.04, cz - 0.0138), rotation: simd_quatf(angle: -(a - .pi / 2), axis: V3(0, 0, 1))))
                    }
                }
            }
            // Steering column shroud.
            let col = Self.steeringAxis
            m.add(HK.cyl(r: 0.055, len: 0.3, at: Self.steeringCenter - col * 0.17, axis: col, mat: dash, seg: hi ? 16 : 8, bevel: 0.01))
            // Windshield: glass panes split at x = 0, frame, header, sill.
            for (x0, x1) in [(Float(0.03), Float(1.0)), (Float(-1.0), Float(-0.03))] {
                let c = gp((x0 + x1) / 2, 0.45)
                m.add(HK.rect(glass, center: c, right: V3(-1, 0, 0), up: u, w: x1 - x0, h: 0.9))
            }
            m.add(HK.pipe([gp(0, 0.0), gp(0, 0.92)], r: 0.018, sides: hi ? 8 : 5, mat: trim))
            m.add(HK.pipe([gp(-1.02, 0.92), gp(1.02, 0.92)], r: 0.022, sides: hi ? 8 : 5, mat: trim))
            m.add(HK.pipe([gp(-1.02, 0.0), gp(1.02, 0.0)], r: 0.015, sides: hi ? 8 : 5, mat: trim))
            // A-pillars, roof rails and header, rear header.
            for sg: Float in [-1, 1] {
                m.add(HK.pipe([gp(sg * 1.05, 0.0), gp(sg * 1.05, 0.46), gp(sg * 1.05, 0.95)], r: 0.032, sides: hi ? 10 : 6, mat: trim))
                m.add(HK.pipe([gp(sg * 1.05, 0.95), V3(sg * 1.08, 1.93, 0.3), V3(sg * 1.08, 1.93, -0.55)], r: 0.026, sides: hi ? 8 : 5, mat: trim))
            }
            m.add(HK.pipe([V3(-1.08, 1.93, -0.55), V3(1.08, 1.93, -0.55)], r: 0.026, sides: hi ? 8 : 5, mat: trim))
            m.add(HK.pipe([V3(-1.08, 1.93, 0.28), V3(1.08, 1.93, 0.28)], r: 0.02, sides: hi ? 8 : 5, mat: trim))
            // Door panels at x = +/-1.1 with window openings, glass, pulls, armrests, switch pods, speakers.
            for sg: Float in [-1, 1] {
                let xi = sg * 1.06, xo = sg * 1.12
                m.add(VK.span(V3(xi, 0.28, -0.55), V3(xo, 0.98, 0.9), "fabric.headliner:3A3C40", r: 0.008, seg: s))
                m.add(VK.span(V3(xi - sg * 0.02, 0.62, -0.5), V3(xo + sg * 0.004, 0.7, 0.55), trim, r: 0.012, seg: s))
                m.add(VK.span(V3(xi - sg * 0.05, 0.76, -0.2), V3(xi, 0.82, 0.42), black, r: 0.015, seg: s))
                m.add(VK.span(V3(xi - sg * 0.03, 0.93, -0.5), V3(xo + sg * 0.008, 1.0, 0.9), trim, r: 0.012, seg: s))
                // Window frame: B-pillar, A-pillar side, top rail around the opening z -0.5...0.78, y 1.0...1.75.
                m.add(VK.span(V3(xi - sg * 0.012, 1.0, -0.58), V3(xo + sg * 0.004, 1.93, -0.5), trim, r: 0.01, seg: s))
                m.add(VK.span(V3(xi - sg * 0.024, 1.75, -0.5), V3(xo + sg * 0.008, 1.82, 0.62), trim, r: 0.01, seg: s))
                m.add(VK.span(V3(xi - sg * 0.012, 1.0, 0.76), V3(xo + sg * 0.004, 1.75, 0.84), trim, r: 0.01, seg: s))
                m.add(HK.rect(glass, center: V3(sg * 1.09, 1.375, 0.14), right: V3(0, 0, 1), up: .up, w: 1.26, h: 0.75))
                m.add(HK.cyl(r: 0.05, len: 0.012, at: V3(xi - sg * 0.006, 0.45, 0.2), axis: V3(-sg, 0, 0), mat: black, seg: hi ? 16 : 8, bevel: 0.003))
                if hi {
                    m.add(HK.box(V3(0.03, 0.03, 0.16), V3(xi - sg * 0.04, 0.88, 0.1), chrome, r: 0.006, seg: 1))
                    for k in 0..<4 { m.add(fb(V3(0.012, 0.014, 0.02), V3(xi - sg * 0.055, 0.795, -0.12 + Float(k) * 0.045), "plastic.gloss:2A2C2F")) }
                }
                // West Coast mirror: two arms, black housing, chrome face (0.18 x 0.40 m).
                let mx = sg * 1.42
                m.add(HK.pipe([V3(sg * 1.1, 1.46, 0.78), V3(sg * 1.26, 1.5, 0.92), V3(mx - sg * 0.02, 1.52, 0.9)], r: 0.011, sides: hi ? 8 : 5, mat: "metal.painted:1E1F20"))
                m.add(HK.pipe([V3(sg * 1.1, 1.0, 0.82), V3(sg * 1.26, 1.1, 0.92), V3(mx - sg * 0.02, 1.12, 0.9)], r: 0.011, sides: hi ? 8 : 5, mat: "metal.painted:1E1F20"))
                m.add(HK.box(V3(0.045, 0.42, 0.2), V3(mx, 1.32, 0.9), "plastic.black", r: 0.012, seg: s))
                m.add(HK.rect("metal.chrome", center: V3(mx - sg * 0.024, 1.32, 0.9), right: V3(0, 0, sg), up: .up, w: 0.18, h: 0.4))
            }
            // Sleeper opening: rear wall with a doorway behind the seats.
            let wallM: MaterialKey = "plastic.dash:35373A"
            m.add(VK.span(V3(0.45, 0.03, -1.0), V3(1.1, 1.93, -0.94), wallM, r: 0.008))
            m.add(VK.span(V3(-1.1, 0.03, -1.0), V3(-0.45, 1.93, -0.94), wallM, r: 0.008))
            m.add(VK.span(V3(-0.45, 1.72, -1.0), V3(0.45, 1.93, -0.94), wallM, r: 0.008))
            m.add(VK.span(V3(-0.45, 0.03, -1.0), V3(0.45, 0.3, -0.94), wallM, r: 0.008))
            m.add(VK.span(V3(-0.47, 0.3, -0.998), V3(-0.452, 1.72, -0.93), black, r: 0.002))
            m.add(VK.span(V3(0.452, 0.3, -0.998), V3(0.47, 1.72, -0.93), black, r: 0.002))
            // Overhead console and sun visors.
            m.add(VK.span(V3(-0.5, 1.78, 0.0), V3(0.5, 1.9, 0.28), trim, r: 0.02, seg: s))
            if hi { for k in 0..<8 { m.add(fb(V3(0.03, 0.006, 0.03), V3(-0.38 + Float(k) * 0.11, 1.775, 0.14), black)) } }
            for vx in [cx, -cx] {
                m.add(HK.box(V3(0.58, 0.02, 0.22), V3(vx, 1.8, 0.5), "fabric.headliner:55575A", r: 0.008, seg: s, rot: simd_quatf(angle: 0.35, axis: V3(1, 0, 0))))
                m.add(HK.cyl(r: 0.007, len: 0.2, at: V3(vx + 0.31, 1.84, 0.6), axis: V3(1, 0, 0), mat: chrome, seg: 6))
            }
            // Seats: driver (air ride, armrests, quilting) and passenger.
            for (sx, driver) in [(cx, true), (-cx, false)] {
                let sz: Float = -0.3
                m.add(VK.span(V3(sx - 0.24, 0.03, sz - 0.28), V3(sx + 0.24, 0.07, sz + 0.28), black, r: 0.008))
                m.add(VK.span(V3(sx - 0.2, 0.07, sz - 0.2), V3(sx + 0.2, 0.3, sz + 0.2), "rubber.plate", r: 0.012, seg: s))
                if hi && driver { for k in 0..<5 { m.add(fb(V3(0.42, 0.01, 0.42), V3(sx, 0.1 + Float(k) * 0.04, sz), black)) } }
                m.add(VK.span(V3(sx - 0.25, 0.3, sz - 0.28), V3(sx + 0.25, 0.37, sz + 0.28), black, r: 0.01, seg: s))
                // Cushion and bolsters.
                m.add(Prim.superellipsoid(V3(0.54, 0.14, 0.54), exponent: 5, subdivisions: 3, material: bolster), Xform(translation: V3(sx, 0.5, sz)))
                if hi && driver {
                    let (cp, _) = tuftedPanel(width: 0.28, height: 0.42, spacing: V2(0.07, 0.07), puff: 0.024, edgeTuck: 0.02, cell: 0.05, material: seat)
                    m.add(cp, Xform(translation: V3(sx, 0.568, sz + 0.0), rotation: simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))))
                } else {
                    m.add(Prim.superellipsoid(V3(0.3, 0.06, 0.44), exponent: 5, subdivisions: 3, material: seat), Xform(translation: V3(sx, 0.55, sz)))
                }
                for sg: Float in [-1, 1] {
                    m.add(Prim.superellipsoid(V3(0.1, 0.12, 0.5), exponent: 4, subdivisions: 3, material: driver && sg < 0 ? "vinyl.seat-grey:4A4C50" : bolster), Xform(translation: V3(sx + sg * 0.21, 0.56, sz)))
                }
                // High back: shell, quilted center, bolsters, headrest, lumbar.
                let tilt = simd_quatf(angle: -0.14, axis: V3(1, 0, 0))
                let bz = sz - 0.28
                m.add(Prim.superellipsoid(V3(0.54, 0.86, 0.11), exponent: 5, subdivisions: 3, material: bolster), Xform(translation: V3(sx, 1.0, bz), rotation: tilt))
                if hi && driver {
                    let (bp, _) = tuftedPanel(width: 0.3, height: 0.66, spacing: V2(0.075, 0.095), puff: 0.026, edgeTuck: 0.02, cell: 0.05, material: seat)
                    m.add(bp, Xform(translation: tilt.act(V3(0, 0.0, 0.055)) + V3(sx, 0.98, bz), rotation: tilt))
                } else {
                    m.add(Prim.superellipsoid(V3(0.3, 0.66, 0.05), exponent: 5, subdivisions: 3, material: seat), Xform(translation: tilt.act(V3(0, 0, 0.045)) + V3(sx, 0.98, bz), rotation: tilt))
                }
                for sg: Float in [-1, 1] {
                    m.add(Prim.superellipsoid(V3(0.11, 0.8, 0.15), exponent: 4, subdivisions: 3, material: bolster), Xform(translation: tilt.act(V3(sg * 0.2, 0, 0.03)) + V3(sx, 1.0, bz), rotation: tilt))
                }
                m.add(Prim.superellipsoid(V3(0.34, 0.22, 0.1), exponent: 4, subdivisions: 3, material: seat), Xform(translation: tilt.act(V3(0, 0.0, 0.0)) + V3(sx, 1.5, bz - 0.04), rotation: tilt))
                m.add(HK.cyl(r: 0.008, len: 0.1, at: V3(sx - 0.05, 1.41, bz - 0.04), axis: .up, mat: chrome, seg: 6))
                m.add(HK.cyl(r: 0.008, len: 0.1, at: V3(sx + 0.05, 1.41, bz - 0.04), axis: .up, mat: chrome, seg: 6))
                // Armrests.
                for sg: Float in [-1, 1] where driver || sg > 0 {
                    m.add(VK.span(V3(sx + sg * 0.3 - 0.02, 0.4, sz - 0.3), V3(sx + sg * 0.3 + 0.02, 0.75, sz - 0.26), black, r: 0.008))
                    m.add(HK.box(V3(0.075, 0.055, 0.3), V3(sx + sg * 0.3, 0.77, sz - 0.14), bolster, r: 0.02, seg: s))
                }
            }
            // Headliner: flat ceiling and sloped front panel, set 5 mm above the rail pipes' underside.
            let hl: MaterialKey = "fabric.headliner:4A4C50"
            m.add(HK.rect(hl, center: V3(0, 1.9545, -0.135), right: V3(-1, 0, 0), up: V3(0, 0, 1), w: 2.1, h: 0.83))
            let fa = gp(0, 0.95) + V3(0, -0.012, 0), fq = V3(0, 1.95, 0.3)
            m.add(HK.rect(hl, center: (fa + fq) / 2, right: V3(-1, 0, 0), up: simd_normalize(fa - fq), w: 2.1, h: simd_length(fa - fq)))
            // Rear side panels behind the doors, door skirts and sill plates.
            let skirt: MaterialKey = "plastic.dash:35373A"
            for sg: Float in [-1, 1] {
                let xi = sg * 1.06, xo = sg * 1.12
                m.add(VK.span(V3(xi - sg * 0.003, 0.03, -0.95), V3(xo, 1.93, -0.56), "fabric.headliner:3A3C40", r: 0.008, seg: s))
                m.add(VK.span(V3(xi - sg * 0.004, 0.03, -0.55), V3(xo, 0.285, 0.9), skirt, r: 0.006, seg: s))
                m.add(VK.span(V3(xi - sg * 0.05, 0.03, -0.4), V3(xi - sg * 0.006, 0.036, 0.8), "metal.aluminum-brushed", r: 0.002))
            }
            // Sleeper curtain: pleated panel pulled across the left of the doorway.
            for k in 0..<9 {
                let px = -0.43 + Float(k) * 0.05
                m.add(VK.span(V3(px, 0.3, -0.935 + (k % 2 == 0 ? 0 : 0.012)), V3(px + 0.048, 1.72, -0.9 + (k % 2 == 0 ? 0 : 0.012)), "fabric.upholstery:3A3D46", r: 0.01, seg: 1))
            }
            m.add(HK.pipe([V3(-0.46, 1.72, -0.895), V3(0.46, 1.72, -0.895)], r: 0.008, sides: 6, mat: chrome))
            // Exterior seen through the windshield: hood, fender tops, wiper cowl.
            let paint: MaterialKey = "metal.painted:D5D9DC"
            m.add(VK.span(V3(-0.78, 0.88, 1.14), V3(0.78, 1.0, 1.5), paint, r: 0.03, seg: 2))
            for sg: Float in [-1, 1] {
                m.add(VK.span(V3(sg * 0.8, 0.84, 1.14), V3(sg * 1.12, 0.94, 1.4), paint, r: 0.03, seg: 2))
            }
            m.add(VK.span(V3(-1.04, 0.93, 1.0), V3(1.04, 0.99, 1.13), "plastic.black", r: 0.01, seg: 1))
            // Dash details: round vents, HVAC knobs, switch bank, cup holders.
            for vx in [Float(-0.3), 0.3, cx + 0.36, cx - 0.3] {
                m.add(HK.cyl(r: 0.04, len: 0.03, at: V3(vx, 0.9, 0.52), axis: V3(0, 0, -1), mat: black, seg: hi ? 16 : 8, bevel: 0.004))
                if hi { for k in 0..<4 { m.add(fb(V3(0.07, 0.004, 0.006), V3(vx, 0.9 + (Float(k) - 1.5) * 0.014, 0.503), "plastic.gloss:2A2C2F")) } }
            }
            for k in 0..<3 {
                m.add(HK.cyl(r: 0.017, len: 0.02, at: V3(-0.09 + Float(k) * 0.09, 0.665, 0.52), axis: V3(0, 0, -1), mat: k == 1 ? "plastic.gloss:7A7D80" : black, seg: hi ? 14 : 8, bevel: 0.002))
            }
            if hi {
                for k in 0..<6 { m.add(fb(V3(0.026, 0.02, 0.01), V3(cx + 0.55 + Float(k % 3) * 0.04, 0.82 + Float(k / 3) * 0.03, 0.4), black)) }
                for sx: Float in [-1, 1] {
                    m.add(Prim.torus(major: 0.036, minor: 0.003, segments: 20, sides: 4, material: chrome).transformed(Xform(translation: V3(sx * 0.055, 0.4775, -0.15))))
                    m.add(HK.cyl(r: 0.034, len: 0.004, at: V3(sx * 0.055, 0.4765, -0.15), axis: .up, mat: "plastic.gloss:0C0D0F", seg: 16, bevel: 0.0005))
                }
            }
            m.add(HK.cyl(r: 0.08, len: 0.1, at: Self.steeringCenter - Self.steeringAxis * 0.33, axis: Self.steeringAxis, mat: dash, seg: hi ? 16 : 8, bevel: 0.01))
            rig.base[l] = m
        }

        // MARK: steering wheel (18 in, four spokes, buttons)
        let c = Self.steeringCenter, ax = Self.steeringAxis
        let face = simd_quatf(from: .up, to: ax)
        rig.part("steering", pivot: c, joint: .hinge(axis: ax, -900...900, duration: 3))
        for l in 0..<2 {
            let hi = l == 0
            rig.add(Prim.torus(major: 0.215, minor: 0.017, segments: hi ? 40 : 16, sides: hi ? 8 : 5, minorY: 0.015, material: "plastic.dash:2A2B2D").transformed(Xform(translation: c, rotation: face)), to: "steering", lods: l...l)
            rig.add(Prim.lathe([V2(0, 0.0), V2(0.07, 0.0), V2(0.075, 0.025), V2(0.06, 0.05), V2(0, 0.055)], segments: hi ? 24 : 10, material: "plastic.dash:2A2B2D")
                .transformed(Xform(translation: c - ax * 0.012, rotation: face)), to: "steering", lods: l...l)
            for (k, a) in ([Float(0.45), 2.69, 3.75, 5.67]).enumerated() {
                let dir = face.act(V3(cos(a), 0, sin(a)))
                let basis = simd_quatf(simd_float3x3(columns: (dir, ax, simd_normalize(simd_cross(dir, ax)))))
                rig.add(HK.box(V3(0.15, 0.012, 0.03), c + dir * 0.135 - ax * 0.004, "plastic.dash:2A2B2D", r: 0.005, seg: 1, rot: basis), to: "steering", lods: l...l)
                if hi && k < 2 {
                    // Button clusters on the upper spokes.
                    for b in 0..<3 {
                        let side = simd_normalize(simd_cross(ax, dir))
                        rig.add(HK.cyl(r: 0.0085, len: 0.006, at: c + dir * (0.12 + Float(b) * 0.001) + side * (Float(b) - 1) * 0.02 + ax * 0.009, axis: ax, mat: b == 1 ? "plastic.gloss:7A7D80" : "plastic.gloss:1A1B1D", seg: 10, bevel: 0.001), to: "steering", lods: 0...0)
                    }
                }
            }
            rig.add(HK.cyl(r: 0.035, len: 0.006, at: c + ax * 0.056, axis: ax, mat: "metal.chrome", seg: hi ? 16 : 8, bevel: 0.001), to: "steering", lods: l...l)
        }
        // MARK: cluster needles
        for (name, gx) in [("speedNeedle", cx + 0.085), ("rpmNeedle", cx - 0.085)] {
            let p = V3(gx, 1.12, 0.64 - 0.0145)
            rig.part(name, pivot: p, joint: .hinge(axis: V3(0, 0, 1), 0...270, duration: 1))
            rig.add(cuboid(V3(0.0035, 0.04, 0.0015), material: "emissive.signal-orange"), Xform(translation: p + V3(0.02 * sin(0.785), -0.02 * cos(0.785), -0.0008), rotation: simd_quatf(angle: 0.785, axis: V3(0, 0, 1))), to: name)
            rig.add(HK.cyl(r: 0.006, len: 0.003, at: p + V3(0, 0, -0.001), axis: V3(0, 0, -1), mat: "emissive.signal-white", seg: 8, bevel: 0.0005), to: name)
        }
        // MARK: DT12 stalk on the right of the column (driver's right = -X)
        let sp = V3(cx - 0.055, 1.0, 0.3)
        rig.part("shifter", pivot: sp, joint: .hinge(axis: V3(0, 0, 1), -20...20, duration: 0.4))
        rig.add(HK.cyl(r: 0.009, len: 0.13, at: sp + V3(-0.065, 0, 0), axis: V3(-1, 0, 0), mat: "plastic.dash:2A2B2D", seg: 10, bevel: 0.002), to: "shifter")
        rig.add(HK.cyl(r: 0.016, len: 0.045, at: sp + V3(-0.15, 0, 0), axis: V3(-1, 0, 0), mat: "plastic.gloss:1A1B1D", seg: 14, bevel: 0.004), to: "shifter")
        rig.add(HK.cyl(r: 0.01, len: 0.004, at: sp + V3(-0.175, 0, 0), axis: V3(-1, 0, 0), mat: "plastic.gloss:7A7D80", seg: 10, bevel: 0.001), to: "shifter")
        // MARK: air brake knobs: yellow diamond parking brake, red octagon trailer air supply
        let ky: Float = 0.7, kz: Float = 0.55
        rig.part("parkingBrake", pivot: V3(cx - 0.3, ky, kz), joint: .slide(axis: V3(0, 0, -1), 0...0.04, duration: 0.3))
        rig.add(HK.cyl(r: 0.006, len: 0.05, at: V3(cx - 0.3, ky, kz - 0.015), axis: V3(0, 0, -1), mat: chrome, seg: 8), to: "parkingBrake")
        rig.add(Prim.extrude(Shape2D.polygon(sides: 4, radius: 0.03, rotation: 0), depth: 0.016, bevel: 0.003, bevelSegments: 1, material: "plastic.yellow:E0B020")
            .transformed(Xform(translation: V3(cx - 0.3, ky, kz - 0.05))), to: "parkingBrake")
        rig.part("trailerSupply", pivot: V3(cx - 0.4, ky, kz), joint: .slide(axis: V3(0, 0, -1), 0...0.04, duration: 0.3))
        rig.add(HK.cyl(r: 0.006, len: 0.05, at: V3(cx - 0.4, ky, kz - 0.015), axis: V3(0, 0, -1), mat: chrome, seg: 8), to: "trailerSupply")
        rig.add(Prim.extrude(Shape2D.polygon(sides: 8, radius: 0.026, rotation: .pi / 8), depth: 0.016, bevel: 0.003, bevelSegments: 1, material: "plastic.gloss:B52A22")
            .transformed(Xform(translation: V3(cx - 0.4, ky, kz - 0.05))), to: "trailerSupply")
        // MARK: pedals (accelerator on the driver's right = -X of the brake)
        rig.part("throttle", pivot: V3(cx - 0.13, 0.06, 0.74), joint: .hinge(axis: V3(1, 0, 0), 0...18, duration: 0.3))
        rig.add(HK.box(V3(0.08, 0.27, 0.02), V3(cx - 0.13, 0.19, 0.69), "rubber.floor-mat", r: 0.008, seg: 1, rot: simd_quatf(angle: -0.55, axis: V3(1, 0, 0))), to: "throttle")
        rig.part("brake", pivot: V3(cx + 0.06, 0.62, 0.7), joint: .hinge(axis: V3(-1, 0, 0), 0...20, duration: 0.3))
        rig.add(HK.pipe([V3(cx + 0.06, 0.62, 0.7), V3(cx + 0.06, 0.34, 0.6), V3(cx + 0.06, 0.24, 0.5)], r: 0.012, sides: 6, mat: "metal.painted:1E1F20"), to: "brake")
        rig.add(HK.box(V3(0.14, 0.1, 0.022), V3(cx + 0.06, 0.22, 0.49), "rubber.floor-mat", r: 0.008, seg: 1, rot: simd_quatf(angle: -0.45, axis: V3(1, 0, 0))), to: "brake")
        for k in 0..<5 {
            rig.add(HK.box(V3(0.07, 0.006, 0.012), V3(cx - 0.13, 0.12 + Float(k) * 0.045, 0.72 - Float(k) * 0.024), "metal.aluminum-brushed", r: 0.002, seg: 1, rot: simd_quatf(angle: -0.55, axis: V3(1, 0, 0))), to: "throttle")
        }
        // MARK: wipers (arms lie along -X on the glass, sweep up)
        for (name, px) in [("wiperLeft", Float(0.82)), ("wiperRight", Float(0.0))] {
            let p = gp(px, 0.07, off: 0.012)
            let basis = simd_quatf(simd_float3x3(columns: (V3(1, 0, 0), n, simd_cross(V3(1, 0, 0), n))))
            rig.part(name, pivot: p, joint: .hinge(axis: -n, 0...75, duration: 0.8))
            rig.add(HK.box(V3(0.5, 0.008, 0.012), p + V3(-0.25, 0, 0), "metal.painted:1E1F20", r: 0.003, seg: 1, rot: basis), to: name)
            rig.add(HK.box(V3(0.48, 0.012, 0.02), p + V3(-0.26, 0, 0) - n * 0.006 - u * 0.012, "rubber.floor-mat:111213", r: 0.004, seg: 1, rot: basis), to: name)
            rig.add(HK.cyl(r: 0.012, len: 0.02, at: p, axis: n, mat: chrome, seg: 8, bevel: 0.002), to: name)
        }
        groundAO(&rig, height: 0.1)
        rig.states = [
            RigState("parked", ["parkingBrake": 0.04]),
            RigState("driving", ["shifter": 20, "throttle": 10, "speedNeedle": 70, "rpmNeedle": 90, "steering": 20]),
            RigState("wipers", ["wiperLeft": 70, "wiperRight": 70, "trailerSupply": 0.04]),
        ]
        return rig
    }
}
