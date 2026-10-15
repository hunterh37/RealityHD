import simd
import Foundation

/// Home treadmill, 85 x 140 x 180 cm: dark rubber running belt over a brushed-aluminium side frame, ribbed grey foot rails,
/// rear roller and end caps, a charcoal motor hood with vent slots and a silver accent band, two raked uprights, foam
/// handrails with a pulse-grip crossbar, and a tilted console carrying a seven-segment display, rubber keys, start and stop
/// buttons, a magnetic safety key on a lanyard and two bottle holders. Console end toward -Z, display facing +Z (the
/// side a runner steps on from).
public struct Treadmill: RealAsset {
    public static let id = "treadmill"
    public static let summary = "Home treadmill: rubber belt, ribbed foot rails, motor hood, uprights, handrails and a console with display."
    public static let tags = ["prop", "floorplan", "commercial", "metal", "plastic", "rubber", "interior"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 18, distance: 2.6, studio: true)

    /// Overall size in meters (x width, y height to the console top, z length including hood and rear caps).
    public var size = V3(0.85, 1.4, 1.8)
    /// Hood and console plastic.
    public var shell: MaterialKey = "plastic.matte:2B2E33"
    /// Frame and upright metal.
    public var frame: MaterialKey = "metal.aluminum-brushed"
    /// Running belt.
    public var belt: MaterialKey = "rubber.floor-mat:26262A"
    /// Foot rails and grips.
    public var rubber: MaterialKey = "rubber.silicone-gray"
    public init() {}

    private func box(_ m: inout Model, _ sz: V3, _ c: V3, _ key: MaterialKey, r: Float = 0.004, seg: Int = 1) {
        m.add(Prim.roundedBox(sz, radius: min(r, sz.x / 2.2, sz.y / 2.2, sz.z / 2.2), bevelSegments: seg, material: key), Xform(translation: c))
    }

    /// Seven-segment glyph on the console, `at` in panel-local coordinates, segment length `l`. Segments a..g as a bitmask.
    private static let segMap: [Character: [Bool]] = [
        "0": [true, true, true, true, true, true, false], "1": [false, true, true, false, false, false, false], "2": [true, true, false, true, true, false, true],
        "3": [true, true, true, true, false, false, true], "4": [false, true, true, false, false, true, true], "5": [true, false, true, true, false, true, true],
        "6": [true, false, true, true, true, true, true], "7": [true, true, true, false, false, false, false], "8": [true, true, true, true, true, true, true],
        "9": [true, true, true, true, false, true, true],
    ]

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hw = size.x / 2
        // Floor feet and adjusters under the four frame corners, transport wheels at the hood.
        let railY0: Float = 0.105, railH: Float = 0.085
        let fx = hw - 0.040
        for sx: Float in [-1, 1] { for zz in [-0.800, 0.780] as [Float] {
            m.add(Prim.cylinder(radius: 0.034, height: 0.040, bevel: 0.006, segments: 14, bevelSegments: 1, material: "rubber.silicone:1B1B1D"), Xform(translation: V3(sx * fx, 0, zz)))
            m.add(Prim.cylinder(radius: 0.010, height: railY0 - 0.036, bevel: 0.001, segments: 8, bevelSegments: 1, material: "metal.steel"), Xform(translation: V3(sx * fx, 0.036, zz)))
        } }
        // Side frame: two long aluminium rails with rounded ends, joined by cross tubes.
        for s: Float in [-1, 1] {
            box(&m, V3(0.056, railH, 1.500), V3(s * (hw - 0.034), railY0 + railH / 2, 0.130), frame, r: 0.012, seg: 2)
            // Side trim cover in charcoal along the outer face.
            box(&m, V3(0.010, 0.060, 1.300), V3(s * (hw - 0.0045), railY0 + railH / 2 + 0.002, 0.180), shell, r: 0.004)
        }
        for cz: Float in [-0.45, 0.20, 0.82] {
            m.add(Prim.cylinder(radius: 0.016, height: 2 * (hw - 0.07), bevel: 0.002, segments: 10, bevelSegments: 1, material: "metal.steel"),
                  Xform(translation: V3(-(hw - 0.07), railY0 + 0.045, cz), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
        }
        // Deck board under the belt, belt surface with a faint run-in sheen strip, rear roller.
        let deckY: Float = railY0 + railH + 0.006
        let beltW: Float = 0.500
        box(&m, V3(beltW + 0.020, 0.018, 1.470), V3(0, deckY - 0.004, 0.150 - 0.015), "wood.plywood", r: 0.003)
        box(&m, V3(beltW, 0.010, 1.400), V3(0, deckY + 0.010, 0.170), belt, r: 0.004)
        // Belt splice line across the running surface.
        box(&m, V3(beltW - 0.004, 0.0008, 0.010), V3(0, deckY + 0.0155, 0.40 + rng.float(-0.05...0.05)), "rubber.floor-mat:3A3A3E", r: 0.0003)
        let rollerR: Float = 0.036
        m.add(Prim.cylinder(radius: rollerR, height: beltW, bevel: 0.002, segments: 18, bevelSegments: 1, material: belt),
              Xform(translation: V3(-beltW / 2, deckY + 0.0145 - rollerR, 0.862), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
        // Ribbed foot rails either side of the belt.
        for s: Float in [-1, 1] {
            let cx = s * (beltW / 2 + 0.055)
            box(&m, V3(0.110, 0.022, 1.440), V3(cx, deckY + 0.008, 0.140), rubber, r: 0.006, seg: 2)
            var z: Float = -0.52
            while z < 0.84 {
                m.add(cuboid(V3(0.090, 0.0016, 0.0050), material: "rubber.silicone-gray:2A2A2C"), Xform(translation: V3(cx, deckY + 0.0200, z)))
                z += 0.060
            }
        }
        // Rear end caps: moulded charcoal blocks around the roller ends with a tracking-adjust screw.
        for s: Float in [-1, 1] {
            box(&m, V3(0.080, 0.075, 0.110), V3(s * (hw - 0.040), railY0 + 0.0475, 0.850), shell, r: 0.014, seg: 2)
            m.add(Prim.cylinder(radius: 0.0055, height: 0.003, bevel: 0.0008, segments: 8, bevelSegments: 1, material: "metal.steel"),
                  Xform(translation: V3(s * (hw - 0.040), railY0 + 0.0475, 0.905), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }
        // Motor hood: charcoal shell with a silver band, vent slots, power switch and a cord stub at the front.
        let hoodZ: Float = -0.675, hoodD: Float = 0.450, hoodH: Float = 0.270
        box(&m, V3(0.780, hoodH, hoodD), V3(0, 0.105 + hoodH / 2, hoodZ), shell, r: 0.050, seg: 2)
        box(&m, V3(0.784, 0.012, hoodD + 0.004), V3(0, 0.105 + 0.090, hoodZ), "metal.aluminum-brushed", r: 0.004)
        for k in 0..<7 {
            m.add(cuboid(V3(0.0060, 0.060, 0.0030), material: "plastic.matte:050506"), Xform(translation: V3(-0.270 + Float(k) * 0.045, 0.105 + 0.185, hoodZ - hoodD / 2 - 0.001)))
        }
        box(&m, V3(0.040, 0.022, 0.012), V3(0.250, 0.105 + 0.052, hoodZ - hoodD / 2 - 0.002), "plastic.matte:A8221C", r: 0.004)     // power rocker
        m.add(Prim.cylinder(radius: 0.020, height: 0.010, bevel: 0.002, segments: 14, bevelSegments: 1, material: "plastic.black"),
              Xform(translation: V3(-0.270, 0.105 + 0.052, hoodZ - hoodD / 2 - 0.009), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))    // circuit breaker
        let cord = catmull([V3(-0.290, 0.105 + 0.040, hoodZ - hoodD / 2 - 0.006), V3(-0.300, 0.070, hoodZ - hoodD / 2 - 0.020), V3(-0.250, 0.012, hoodZ - hoodD / 2 - 0.022)], per: 6)
        m.add(Prim.tube(cord, radii: cord.map { _ in 0.0060 }, sides: 8, seamTile: 0.04, material: "plastic.black", capEnd: true))
        // Uprights: raked brushed tubes with a foot collar and a cuff under the console.
        let upBase = V3(0, 0.300, -0.730), upTop = V3(0, 1.150, -0.800)
        for s: Float in [-1, 1] {
            let b = V3(s * 0.345, upBase.y, upBase.z), t = V3(s * 0.335, upTop.y, upTop.z)
            let pts = [b, b + (t - b) * 0.33, b + (t - b) * 0.66, t]
            m.add(Prim.tube(pts, radii: [0.026, 0.026, 0.025, 0.025], sides: 12, seamTile: 0.1, material: frame, capEnd: true))
            box(&m, V3(0.090, 0.070, 0.095), V3(b.x, 0.385, b.z - 0.010), shell, r: 0.014, seg: 2)
            box(&m, V3(0.070, 0.048, 0.080), t + V3(0, 0.004, 0.002), shell, r: 0.010, seg: 1)
        }
        // Handrails: swept tube from each upright out over the deck with a foam grip section and chrome end cap.
        for s: Float in [-1, 1] {
            let hx = s * 0.372
            let path = catmull([V3(s * 0.335, 1.060, -0.790), V3(hx, 1.045, -0.700), V3(hx, 1.020, -0.500), V3(hx, 1.000, -0.250), V3(hx, 0.985, -0.050), V3(hx * 0.98, 0.955, 0.060)], per: 6)
            let radii = path.map { _ in Float(0.0185) }
            m.add(Prim.tube(path, radii: radii, sides: 10, seamTile: 0.1, material: frame, capEnd: true))
            // Foam grip covers the middle third.
            let gp = Array(path[10..<26])
            m.add(Prim.tube(gp, radii: gp.map { _ in Float(0.0225) }, sides: 10, seamTile: 0.05, material: "rubber.silicone:1B1B1D", capEnd: true))
        }
        // Pulse-grip crossbar: chrome tube between the uprights with two black sensor pads.
        let xbar = V3(0, 1.045, -0.790)
        m.add(Prim.cylinder(radius: 0.014, height: 0.670, bevel: 0.002, segments: 12, bevelSegments: 1, material: "metal.chrome"),
              Xform(translation: V3(-0.335, xbar.y, xbar.z + 0.020), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
        for s: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(0.085, 0.024, 0.034), radius: 0.010, bevelSegments: 2, material: "plastic.matte:1A1B1E"), Xform(translation: V3(s * 0.130, xbar.y, xbar.z + 0.020)))
        }
        // Console: tilted housing on the uprights. Panel-local frame: x right, y up the panel, z out of the face.
        let alpha: Float = 28
        let qC = simd_quatf(degrees: -alpha, axis: V3(1, 0, 0))
        let C = V3(0, 1.250, -0.790)
        func cadd(_ s: Surface, _ l: V3, _ q: simd_quatf = simd_quatf(angle: 0, axis: V3(0, 1, 0))) {
            m.add(s, Xform(translation: C + qC.act(l), rotation: qC * q))
        }
        cadd(Prim.roundedBox(V3(0.600, 0.280, 0.100), radius: 0.028, bevelSegments: 2, material: shell), V3(0, 0, 0))
        cadd(Prim.roundedBox(V3(0.565, 0.250, 0.006), radius: 0.012, bevelSegments: 2, material: "plastic.black"), V3(0, 0, 0.0505))
        // Display: smoked glass window over a dark panel with seven-segment readouts.
        cadd(Prim.roundedBox(V3(0.380, 0.118, 0.006), radius: 0.006, bevelSegments: 1, material: "plastic.matte:0A0B0D"), V3(0, 0.060, 0.0540))
        cadd(Prim.roundedBox(V3(0.372, 0.110, 0.003), radius: 0.005, bevelSegments: 1, material: "glass.tinted"), V3(0, 0.060, 0.0585))
        func digits(_ text: String, at o: V3, h: Float, key: MaterialKey) {
            let l = h * 0.44, t = h * 0.075
            var x: Float = 0
            for ch in text {
                if ch == "." { cadd(cuboid(V3(t * 1.1, t * 1.1, 0.0012), material: key), o + V3(x - h * 0.10, -h * 0.5, 0.0)); x += h * 0.20; continue }
                if ch == ":" {
                    for dy: Float in [-0.16, 0.16] { cadd(cuboid(V3(t, t, 0.0012), material: key), o + V3(x + h * 0.06, h * dy, 0.0)) }
                    x += h * 0.22; continue
                }
                guard let seg = Self.segMap[ch] else { x += h * 0.5; continue }
                let pos: [(V3, Bool)] = [(V3(0, h / 2, 0), true), (V3(l / 2 + t * 0.4, h / 4, 0), false), (V3(l / 2 + t * 0.4, -h / 4, 0), false),
                                         (V3(0, -h / 2, 0), true), (V3(-l / 2 - t * 0.4, -h / 4, 0), false), (V3(-l / 2 - t * 0.4, h / 4, 0), false), (V3(0, 0, 0), true)]
                for (i, on) in seg.enumerated() where on {
                    let (p, horiz) = pos[i]
                    cadd(cuboid(horiz ? V3(l, t, 0.0012) : V3(t, h / 2 - t, 0.0012), material: key), o + V3(x + l / 2 + p.x, p.y, p.z))
                }
                x += l + h * 0.30
            }
        }
        digits("24:36", at: V3(-0.150, 0.082, 0.0605), h: 0.034, key: "emissive.led-green")
        digits("10.5", at: V3(0.040, 0.082, 0.0605), h: 0.034, key: "emissive.signal-orange")
        digits("1.35", at: V3(-0.150, 0.036, 0.0605), h: 0.022, key: "emissive.led-green")
        digits("0.0", at: V3(0.040, 0.036, 0.0605), h: 0.022, key: "emissive.signal-white")
        // Left and right control clusters: rocker keys for speed and incline, quick-speed row.
        for (cx, up) in [(-0.230, true), (0.230, false)] as [(Float, Bool)] {
            for dy: Float in [0.040, -0.012] {
                cadd(Prim.roundedBox(V3(0.060, 0.044, 0.008), radius: 0.010, bevelSegments: 2, material: "rubber.silicone:2A2C30"), V3(cx, dy + (up ? 0.0 : 0.0), 0.0555))
                cadd(cuboid(V3(0.020, 0.0030, 0.0008), material: "plastic.white"), V3(cx, dy, 0.0600))
                if dy > 0 { cadd(cuboid(V3(0.0030, 0.020, 0.0008), material: "plastic.white"), V3(cx, dy, 0.0600)) }
            }
        }
        for k in 0..<6 {
            cadd(Prim.roundedBox(V3(0.044, 0.022, 0.007), radius: 0.006, bevelSegments: 1, material: "rubber.silicone:2A2C30"), V3(-0.110 + Float(k) * 0.052, -0.040, 0.0550))
            cadd(cuboid(V3(0.020, 0.0030, 0.0008), material: "plastic.white"), V3(-0.110 + Float(k) * 0.052, -0.040, 0.0590))
        }
        // Start and stop buttons with a light ring; pause between them.
        let btn: [(Float, MaterialKey)] = [(-0.075, "plastic.gloss:1F8A3A"), (0.0, "plastic.gloss:D8B21C"), (0.075, "plastic.gloss:B82822")]
        for (bx, key) in btn {
            cadd(Prim.cylinder(radius: 0.022, height: 0.007, bevel: 0.0015, segments: 20, bevelSegments: 1, material: key), V3(bx, -0.088, 0.0505), simd_quatf(degrees: 90, axis: V3(1, 0, 0)))
        }
        // Safety key: slot, magnet tag and red lanyard falling to a clip on the upright.
        cadd(Prim.roundedBox(V3(0.034, 0.020, 0.010), radius: 0.004, bevelSegments: 1, material: "plastic.black"), V3(0.0, -0.112, 0.0525))
        cadd(Prim.roundedBox(V3(0.026, 0.014, 0.008), radius: 0.003, bevelSegments: 1, material: "plastic.gloss:B82822"), V3(0.0, -0.112, 0.0585))
        let lan0 = C + qC.act(V3(0.0, -0.118, 0.060))
        let lan = catmull([lan0, lan0 + V3(0.004, -0.050, 0.020), lan0 + V3(0.012, -0.120, 0.030), V3(0.020, 1.040, -0.748)], per: 5)
        m.add(Prim.tube(lan, radii: lan.map { _ in 0.0020 }, sides: 6, seamTile: 0.04, material: "plastic.gloss:B82822", capEnd: true))
        m.add(Prim.roundedBox(V3(0.030, 0.016, 0.010), radius: 0.003, bevelSegments: 1, material: "metal.steel"), Xform(translation: V3(0.020, 1.040, -0.750)))
        // Top lip (tablet ledge) and a speaker slot row.
        cadd(Prim.roundedBox(V3(0.540, 0.012, 0.040), radius: 0.005, bevelSegments: 1, material: shell), V3(0, 0.140, 0.0600))
        for k in 0..<8 {
            cadd(cuboid(V3(0.0060, 0.026, 0.0010), material: "plastic.matte:060607"), V3(-0.330 + Float(k) * 0.0095, 0.082, 0.0535))
            cadd(cuboid(V3(0.0060, 0.026, 0.0010), material: "plastic.matte:060607"), V3(0.2565 + Float(k) * 0.0095, 0.082, 0.0535))
        }
        // Bottle holders: open cups on either side of the console.
        for s: Float in [-1, 1] {
            let cup: [V2] = [V2(0, 0), V2(0.034, 0), V2(0.036, 0.004), V2(0.040, 0.060), V2(0.043, 0.075), V2(0.0415, 0.077), V2(0.0385, 0.060), V2(0.0345, 0.006), V2(0, 0.004)]
            let at = C + qC.act(V3(s * 0.352, -0.030, 0.012))
            m.add(Prim.lathe(cup, segments: 20, seamTile: 0.1, material: "plastic.matte:24262A"), Xform(translation: at, rotation: qC * simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }
        // Console back wire cover and a short cable gland, where the uprights meet.
        box(&m, V3(0.140, 0.050, 0.080), C + qC.act(V3(0, -0.110, -0.078)), shell, r: 0.012, seg: 1)
        // Authoring frame: centred X/Z, lowest point y = 0.
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2)))
        groundAO(&m, height: 0.12, floor: 0.55)
        return LODModel(m)
    }
}
