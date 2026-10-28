import simd
import Foundation

/// Polaroid Now (2nd gen) i-Type instant camera, about 150 x 110 x 95 mm. Base at y = 0, centered on X and Z of the
/// body, lens axis along -Z (lens and film slot face -Z, rear screen faces +Z). Glossy white shell, black lens barrel
/// with a ribbed shutter ring, rainbow stripe, flash window and optical viewfinder window on the front, film exit slot
/// under the lens, red shutter button on top, 40 x 40 mm rear LCD, optical viewfinder eyepiece, zoom +/- rockers, d-pad,
/// thumbwheel, strap lug, film door latch, bottom tripod socket.
/// Parts (joint entities): shutter, power, menu, play, dpad (dpad-up, dpad-down, dpad-left, dpad-right, dpad-ok),
/// main-dial, zoom-in, zoom-out, screen, evf, film-slot. States: rest, half-press (shutter 0.6 mm), full-press (1.2 mm).
public struct CameraPolaroidNow: RealArticulated {
    public static let id = "camera-polaroid-now"
    public static let summary = "Polaroid Now 2nd gen i-Type instant camera: white glossy body, black front face, rainbow stripe, big lens barrel, flash, viewfinder, film slot, articulated controls."
    public static let tags = ["prop", "electronics", "camera", "articulated", "handheld"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 18, distance: 0.8, studio: true)

    /// Rear LCD glass in asset space at rest: center, size (m) and outward normal.
    public struct ScreenRect: Sendable {
        public var center: V3
        public var size: V2
        public var normal: V3
    }
    public static let screenRect = ScreenRect(center: V3(-0.040, 0.066, 0.04875), size: V2(0.040, 0.040), normal: V3(0, 0, 1))

    /// Film exit slot in asset space: center of the opening on the front face, width and height (m), exit direction.
    public struct FilmSlot: Sendable {
        public var center: V3
        public var width: Float
        public var height: Float
        public var normal: V3
    }
    public static let filmSlot = FilmSlot(center: V3(0, 0.010, -0.020), width: 0.090, height: 0.003, normal: V3(0, 0, -1))

    /// Glossy shell plastic.
    public var bodyMaterial: MaterialKey = "plastic.gloss:F1EFE8"
    /// Black lens barrel and bezels.
    public var blackMaterial: MaterialKey = "plastic.gloss:121214"
    /// Shutter button.
    public var shutterMaterial: MaterialKey = "plastic.gloss:D2352B"
    public init() {}

    /// Rounded rectangle outline centered on X, from y0 to y1, with separate top and bottom corner radii.
    static func rrect(_ w: Float, _ y0: Float, _ y1: Float, top rt: Float, bottom rb: Float, seg: Int = 5) -> [V2] {
        var pts: [V2] = []
        func arc(_ cx: Float, _ cy: Float, _ r: Float, _ a0: Float) {
            for i in 0...seg {
                let a = (a0 + 90 * Float(i) / Float(seg)) * .pi / 180
                pts.append(V2(cx + r * cos(a), cy + r * sin(a)))
            }
        }
        arc(w / 2 - rb, y0 + rb, rb, -90); arc(w / 2 - rt, y1 - rt, rt, 0)
        arc(-w / 2 + rt, y1 - rt, rt, 90); arc(-w / 2 + rb, y0 + rb, rb, 180)
        return pts
    }

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [1.2])
        func put(_ s: Surface, _ x: Xform, to part: String? = nil, lods: ClosedRange<Int> = 0...1) {
            if let part { rig.add(s, x, to: part, lods: lods) } else { for l in lods { rig.base[l].add(s, x) } }
        }
        func at(_ x: Float, _ y: Float, _ z: Float) -> Xform { Xform(translation: V3(x, y, z)) }
        let toZ = simd_quatf(degrees: 90, axis: V3(1, 0, 0)), toNegZ = simd_quatf(degrees: -90, axis: V3(1, 0, 0))
        let H: Float = 0.110, yB: Float = 0.0008
        let zF: Float = -0.020, zS: Float = -0.008, zBf: Float = -0.010, zR: Float = 0.0475
        let body = bodyMaterial, black = blackMaterial
        let btn: MaterialKey = "plastic.matte:2B2C2F", dark: MaterialKey = "plastic.matte:0B0B0C", white: MaterialKey = "plastic.white"
        let steel: MaterialKey = "metal.satin-aluminum", rubber: MaterialKey = "rubber"
        let ay: Float = 0.062

        // MARK: shell. Rear body, front shell split around the film exit slot (y 8.5 to 11.5 mm, x +-45 mm).
        put(Prim.extrude(Self.rrect(0.150, yB, H, top: 0.014, bottom: 0.010), depth: zR - zBf, bevel: 0.004, bevelSegments: 3, material: body), at(0, 0, (zR + zBf) / 2))
        put(Prim.extrude(Self.rrect(0.1504, 0.0115, H + 0.0002, top: 0.0142, bottom: 0.002), depth: zS + 0.004 - zF, bevel: 0.0018, bevelSegments: 2, material: body), at(0, 0, (zF + zS + 0.004) / 2))
        put(Prim.extrude(Self.rrect(0.1504, 0.0006, 0.0085, top: 0.002, bottom: 0.0035), depth: zS + 0.004 - zF, bevel: 0.0015, bevelSegments: 2, material: body), at(0, 0, (zF + zS + 0.004) / 2))
        for sx: Float in [-1, 1] {
            put(Prim.roundedBox(V3(0.0300, 0.0031, 0.012), radius: 0.0007, bevelSegments: 1, material: body), at(sx * 0.060, 0.0100, (zF + zS) / 2))
        }
        // Film slot: dark liner plate on the body face, dark top and bottom liners (the opening is real).
        rig.part("film-slot", pivot: Self.filmSlot.center, joint: .fixed)
        put(Prim.roundedBox(V3(0.0900, 0.0030, 0.0004), radius: 0.0001, bevelSegments: 1, material: dark), at(0, 0.0100, zBf - 0.0002), to: "film-slot")
        put(Prim.roundedBox(V3(0.0900, 0.0004, zBf - zF), radius: 0.0001, bevelSegments: 1, material: dark), at(0, 0.0113, (zF + zBf) / 2), to: "film-slot", lods: 0...0)
        put(Prim.roundedBox(V3(0.0900, 0.0004, zBf - zF), radius: 0.0001, bevelSegments: 1, material: dark), at(0, 0.0087, (zF + zBf) / 2), to: "film-slot", lods: 0...0)
        // Rainbow stripe.
        for (i, c) in ["E4312B", "F28C28", "F7D21B", "3DA544", "2B6CC4"].enumerated() {
            put(Prim.roundedBox(V3(0.120, 0.0013, 0.0006), radius: 0.0002, bevelSegments: 1, material: MaterialKey("plastic.gloss:" + c)), at(0, 0.0135 + 0.00065 + Float(i) * 0.0013, zF - 0.00005))
        }
        // Rubber feet and tripod socket.
        for sx: Float in [-1, 1] { for z: Float in [-0.004, 0.040] {
            put(Prim.cylinder(radius: 0.0048, height: 0.0008, bevel: 0.0003, segments: 14, bevelSegments: 1, material: rubber), at(sx * 0.055, 0, z), lods: 0...0)
        } }
        put(Prim.cylinder(radius: 0.0058, height: 0.0007, bevel: 0.0002, segments: 20, bevelSegments: 1, material: steel), at(0, 0.0001, 0.014), lods: 0...0)
        put(Prim.cylinder(radius: 0.0034, height: 0.0002, bevel: 0, segments: 18, bevelSegments: 1, material: dark), at(0, -0.00005, 0.014), lods: 0...0)

        // MARK: lens barrel (lens local space: +Y out of the front face, placed along -Z)
        let lensX = Xform(translation: V3(0, ay, zF), rotation: toNegZ)
        for l in 0..<2 {
            let seg = l == 0 ? 44 : 22
            put(Prim.lathe([V2(0.0390, 0), V2(0.0390, 0.0040), V2(0.0375, 0.0046), V2(0.0375, 0.0060), V2(0.0345, 0.0065), V2(0.0345, 0.0165)], segments: seg, seamTile: 0.1, material: black), lensX, lods: l...l)
            put(Prim.lathe([V2(0.0345, 0.0245), V2(0.0345, 0.0268), V2(0.0240, 0.0268)], segments: seg, seamTile: 0.1, material: black), lensX, lods: l...l)
            for s in CameraKit.lensGlass(rimY: 0.0268, floorY: 0.0165, boreR: 0.0240, lod: l) { put(s, lensX, lods: l...l) }
        }
        // Shutter ring: ribbed rubber between the barrel base and the lip.
        put(CanonR50.ribbedSolid(0.0352, amp: 0.0006, teeth: 48, 0.0165, 0.0245, rubber), lensX, lods: 0...0)
        put(Prim.cylinder(radius: 0.0355, height: 0.0080, bevel: 0.0004, segments: 24, bevelSegments: 1, material: rubber), Xform(translation: V3(0, ay, zF - 0.0165), rotation: toNegZ), lods: 1...1)
        put(Prim.lathe([V2(0.0348, 0.0165), V2(0.0348, 0.0167), V2(0.0260, 0.0167)], segments: 36, seamTile: 0.1, material: steel), lensX, lods: 0...0)
        // Index dot on the ring front.
        put(Prim.roundedBox(V3(0.0020, 0.0003, 0.0020), radius: 0.0004, bevelSegments: 1, material: "plastic.sharps-red"), at(0, ay + 0.0308, zF - 0.0269), lods: 0...0)

        // MARK: front windows
        // Flash window (upper right) with prism ridges.
        put(Prim.roundedBox(V3(0.0220, 0.0150, 0.0008), radius: 0.0020, bevelSegments: 2, material: black), at(0.0575, 0.0895, zF - 0.0003))
        put(Prim.roundedBox(V3(0.0190, 0.0120, 0.0006), radius: 0.0015, bevelSegments: 1, material: "plastic.gloss:EDE6CC"), at(0.0575, 0.0895, zF - 0.0008), lods: 0...0)
        for i in 0..<6 {
            put(Prim.roundedBox(V3(0.0002, 0.0110, 0.0003), radius: 0.00005, bevelSegments: 1, material: "plastic.gloss:C9C2A6"), at(0.0575 + (Float(i) - 2.5) * 0.0027, 0.0895, zF - 0.0013), lods: 0...0)
        }
        // Optical viewfinder window (upper left).
        put(Prim.roundedBox(V3(0.0200, 0.0140, 0.0008), radius: 0.0020, bevelSegments: 2, material: black), at(-0.0575, 0.0895, zF - 0.0003))
        put(Prim.roundedBox(V3(0.0160, 0.0100, 0.0005), radius: 0.0012, bevelSegments: 1, material: "glass.tinted:1C2A33"), at(-0.0575, 0.0895, zF - 0.0008))
        // Self-timer LED and light sensor window.
        put(Prim.cylinder(radius: 0.0026, height: 0.0006, bevel: 0.0002, segments: 14, bevelSegments: 1, material: "glass.tinted:151A22"), Xform(translation: V3(0.0575, 0.0715, zF - 0.0006), rotation: toNegZ))
        put(Prim.cylinder(radius: 0.0016, height: 0.0006, bevel: 0.0002, segments: 12, bevelSegments: 1, material: "plastic.sharps-red"), Xform(translation: V3(-0.0575, 0.0715, zF - 0.0006), rotation: toNegZ), lods: 0...0)

        // MARK: top controls
        rig.part("shutter", pivot: V3(0.052, H, 0.002), joint: .slide(axis: V3(0, -1, 0), 0...0.0012, duration: 0.15))
        put(Prim.cylinder(radius: 0.0085, height: 0.0070, bevel: 0.0020, segments: 24, bevelSegments: 2, material: shutterMaterial), at(0.052, H - 0.0045, 0.002), to: "shutter")
        rig.part("power", pivot: V3(-0.052, H, 0.002), joint: .slide(axis: V3(1, 0, 0), -0.003...0.003, duration: 0.15))
        put(Prim.roundedBox(V3(0.0090, 0.0030, 0.0050), radius: 0.0012, bevelSegments: 1, material: btn), at(-0.052, H - 0.0001, 0.002), to: "power")

        // MARK: rear
        let rz = zR - 0.0005
        // Screen module: bezel box, glass quad, bezel lip.
        let sc = Self.screenRect, gz = sc.center.z
        rig.part("screen", pivot: sc.center, joint: .fixed)
        put(Prim.roundedBox(V3(0.0476, 0.0476, 0.0016), radius: 0.0030, bevelSegments: 2, material: "plastic.gloss:121214"), at(sc.center.x, sc.center.y, zR + 0.0004), to: "screen")
        for s in CameraKit.lcdSurround(center: V2(sc.center.x, sc.center.y), z: gz, inner: sc.size) { put(s, at(0, 0, 0), to: "screen") }
        var glass = Surface(material: "screen.off")
        let gw = sc.size.x / 2, gh = sc.size.y / 2, n = V3(0, 0, 1)
        let a = glass.add(V3(sc.center.x - gw, sc.center.y - gh, gz), n, V2(0, 0)), b = glass.add(V3(sc.center.x + gw, sc.center.y - gh, gz), n, V2(1, 0))
        let c = glass.add(V3(sc.center.x + gw, sc.center.y + gh, gz), n, V2(1, 1)), d = glass.add(V3(sc.center.x - gw, sc.center.y + gh, gz), n, V2(0, 1))
        glass.quad(a, b, c, d); glass.computeTangents()
        rig.add(glass, to: "screen")
        // Optical viewfinder eyepiece.
        rig.part("evf", pivot: V3(0, 0.098, zR), joint: .fixed)
        put(Prim.roundedBox(V3(0.0180, 0.0125, 0.0014), radius: 0.0016, bevelSegments: 2, material: rubber), at(0, 0.098, zR + 0.0003), to: "evf")
        put(Prim.roundedBox(V3(0.0132, 0.0078, 0.0004), radius: 0.0010, bevelSegments: 1, material: "glass.tinted:10181E"), at(0, 0.098, zR + 0.0011), to: "evf")
        // Zoom rockers with + and - glyphs.
        for (name, y, plus) in [("zoom-in", 0.0955, true), ("zoom-out", 0.0875, false)] as [(String, Float, Bool)] {
            rig.part(name, pivot: V3(0.050, y, zR), joint: .slide(axis: V3(0, 0, -1), 0...0.0008, duration: 0.1))
            put(Prim.roundedBox(V3(0.0090, 0.0060, 0.0016), radius: 0.0012, bevelSegments: 2, material: btn), at(0.050, y, zR + 0.0003), to: name)
            put(Prim.roundedBox(V3(0.0034, 0.0007, 0.0003), radius: 0.0001, bevelSegments: 1, material: white), at(0.050, y, zR + 0.0012), to: name, lods: 0...0)
            if plus { put(Prim.roundedBox(V3(0.0007, 0.0034, 0.0003), radius: 0.0001, bevelSegments: 1, material: white), at(0.050, y, zR + 0.0012), to: name, lods: 0...0) }
        }
        // Menu and play buttons.
        for (name, x, y) in [("menu", 0.0105, 0.0780), ("play", 0.0105, 0.0600)] as [(String, Float, Float)] {
            rig.part(name, pivot: V3(x, y, zR), joint: .slide(axis: V3(0, 0, -1), 0...0.0008, duration: 0.1))
            put(Prim.cylinder(radius: 0.0042, height: 0.0019, bevel: 0.0007, segments: 16, bevelSegments: 1, material: btn), Xform(translation: V3(x, y, rz), rotation: toZ), to: name)
        }
        for i in 0..<3 {
            put(Prim.roundedBox(V3(0.0042, 0.0004, 0.0003), radius: 0.0001, bevelSegments: 1, material: white), at(0.0105, 0.0780 + (Float(i) - 1) * 0.0011, zR + 0.0013), to: "menu", lods: 0...0)
        }
        put(Prim.extrude(Shape2D.polygon(sides: 3, radius: 0.0021), depth: 0.0003, bevel: 0, bevelSegments: 1, material: white),
            Xform(translation: V3(0.0105, 0.0600, zR + 0.0013), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))), to: "play", lods: 0...0)
        // Thumbwheel (lighten / darken).
        rig.part("main-dial", pivot: V3(0.064, 0.074, zR), joint: .hinge(axis: V3(0, 0, 1), -40...40, duration: 0.3))
        put(CanonR50.ribbedSolid(0.0063, amp: 0.0004, teeth: 20, 0, 0.0020, rubber), Xform(translation: V3(0.064, 0.074, rz), rotation: toZ), to: "main-dial", lods: 0...0)
        put(Prim.cylinder(radius: 0.0066, height: 0.0020, bevel: 0.0004, segments: 14, bevelSegments: 1, material: rubber), Xform(translation: V3(0.064, 0.074, rz), rotation: toZ), to: "main-dial", lods: 1...1)
        // D-pad.
        let px: Float = 0.043, py: Float = 0.050
        rig.part("dpad", pivot: V3(px, py, zR), joint: .slide(axis: V3(0, 0, -1), 0...0.0006, duration: 0.1))
        put(Prim.cylinder(radius: 0.0113, height: 0.0017, bevel: 0.0005, segments: 28, bevelSegments: 1, material: dark), Xform(translation: V3(px, py, rz), rotation: toZ), to: "dpad")
        for (name, sx, sy, w, h) in [("dpad-up", 0, 1, 0.0062, 0.0034), ("dpad-down", 0, -1, 0.0062, 0.0034), ("dpad-left", -1, 0, 0.0034, 0.0062), ("dpad-right", 1, 0, 0.0034, 0.0062)] as [(String, Float, Float, Float, Float)] {
            let x = px + sx * 0.0078, y = py + sy * 0.0078
            rig.part(name, parent: "dpad", pivot: V3(x, y, zR), joint: .slide(axis: V3(0, 0, -1), 0...0.0006, duration: 0.1))
            put(Prim.roundedBox(V3(w, h, 0.0006), radius: 0.00025, bevelSegments: 1, material: btn), at(x, y, rz + 0.0017 + 0.00025), to: name)
        }
        rig.part("dpad-ok", parent: "dpad", pivot: V3(px, py, zR), joint: .slide(axis: V3(0, 0, -1), 0...0.0006, duration: 0.1))
        put(Prim.cylinder(radius: 0.0052, height: 0.0010, bevel: 0.0004, segments: 18, bevelSegments: 1, material: btn), Xform(translation: V3(px, py, rz + 0.0017), rotation: toZ), to: "dpad-ok")

        // MARK: side hardware, film door
        put(Prim.roundedBox(V3(0.0020, 0.0120, 0.0090), radius: 0.0008, bevelSegments: 1, material: steel), at(-0.0757, 0.0900, 0.030))
        put(Prim.roundedBox(V3(0.0004, 0.0060, 0.0030), radius: 0.0001, bevelSegments: 1, material: dark), at(-0.0768, 0.0900, 0.030), lods: 0...0)
        put(Prim.roundedBox(V3(0.0016, 0.0160, 0.0070), radius: 0.0007, bevelSegments: 1, material: "plastic.matte:2B2C2F"), at(0.0756, 0.0450, 0.030))
        put(Prim.roundedBox(V3(0.1300, 0.0004, 0.0004), radius: 0.0001, bevelSegments: 1, material: dark), at(0, 0.0270, zR + 0.0001), lods: 0...0)

        // Film door: raised lower rear panel with parting seams, latch recess, speaker dots.
        put(Prim.extrude(Self.rrect(0.1340, 0.0040, 0.0262, top: 0.0015, bottom: 0.0060), depth: 0.0006, bevel: 0.0002, bevelSegments: 1, material: "plastic.gloss:E6E4DC"), at(0, 0, zR + 0.0001))
        for sx: Float in [-1, 1] {
            put(Prim.roundedBox(V3(0.0004, 0.0222, 0.0004), radius: 0.0001, bevelSegments: 1, material: dark), at(sx * 0.0672, 0.0151, zR + 0.0003), lods: 0...0)
        }
        for i in 0..<5 { for j in 0..<2 {
            put(Prim.cylinder(radius: 0.0008, height: 0.0003, bevel: 0, segments: 8, bevelSegments: 1, material: dark), Xform(translation: V3(-0.050 + Float(i) * 0.0026, 0.0120 + Float(j) * 0.0026, zR + 0.0006), rotation: toZ), lods: 0...0)
        } }
        put(Prim.roundedBox(V3(0.0120, 0.0040, 0.0006), radius: 0.0010, bevelSegments: 1, material: "plastic.matte:2B2C2F"), at(0.050, 0.0150, zR + 0.0008), lods: 0...0)
        // Parting seam around the shell at the front-shell join.
        for sx: Float in [-1, 1] {
            put(Prim.roundedBox(V3(0.0004, 0.0900, 0.0004), radius: 0.0001, bevelSegments: 1, material: "plastic.matte:B9B7AF"), at(sx * 0.0751, 0.0560, -0.0040), lods: 0...0)
        }

        // MARK: wear and grounding
        let tx: MaterialKey = "plastic.matte:C9C6BC"
        for (s, x) in CameraKit.boxWear(&rng, center: V3(0, 0.0554, (zBf + zR) / 2), size: V3(0.1345, H - yB, zR - zBf), radius: 0.004,
                                         edges: [.init(0, 1, 1, density: 1), .init(0, -1, 1, density: 1), .init(0, 1, -1, density: 0.6)], perMeter: 60, length: 0.0012...0.0040, material: tx) { put(s, x, lods: 0...0) }
        for (s, x) in CameraKit.smudges(&rng, center: V3(0, 0.040, zR + 0.0001), normal: V3(0, 0, 1), along: V3(1, 0, 0), extent: V2(0.10, 0.060), count: 10, material: "plastic.gloss:C8C5BB", size: 0.006...0.016) { put(s, x, lods: 0...0) }
        for (s, x) in CameraKit.smudges(&rng, center: V3(0, H + 0.0001, 0.015), normal: V3(0, 1, 0), along: V3(1, 0, 0), extent: V2(0.10, 0.040), count: 5, material: "plastic.gloss:C8C5BB", size: 0.006...0.014) { put(s, x, lods: 0...0) }
        for sx: Float in [-1, 1] {
            for (s, x) in CameraKit.smudges(&rng, center: V3(sx * 0.058, 0.052, zF - 0.0004), normal: V3(0, 0, -1), along: V3(1, 0, 0), extent: V2(0.012, 0.040), count: 3, material: "plastic.gloss:C2BFB4", size: 0.004...0.010) { put(s, x, lods: 0...0) }
        }
        for s in CameraKit.contactShadow(center: V3(0, 0, (zBf + zR) / 2), size: V2(0.1408, zR - zBf - 0.0092)) { put(s, at(0, 0, 0)) }
        groundAO(&rig, height: 0.01, floor: 0.7)
        rig.states = [RigState("rest"), RigState("half-press", ["shutter": 0.0006]), RigState("full-press", ["shutter": 0.0012])]
        return rig
    }
}
