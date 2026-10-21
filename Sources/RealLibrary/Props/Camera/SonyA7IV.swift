import simd
import Foundation

/// Sony a7 IV mirrorless camera with the FE 28-70mm f/3.5-5.6 OSS kit lens. Body 131.3 x 96.4 x 79.8 mm with a
/// deep grip, 3.0 in vari-angle LCD, tall EVF hump, lens 72.5 mm dia x 83.5 mm. Base at y = 0, centered on X,
/// lens axis along -Z (lens points -Z, rear LCD faces +Z), grip on +X (the photographer's right).
/// Parts (joint entities): shutter, power, main-dial (front), rear-dial, mode-dial (with mode-switch), c1, c2, c3,
/// video, af-on, menu, play, dpad (dpad-up, dpad-down, dpad-left, dpad-right, dpad-ok wheel), zoom-ring,
/// focus-ring, screen (hinges out to the left), evf.
/// States: rest, half-press (shutter 0.6 mm), full-press (1.2 mm), screen-out.
public struct SonyA7IV: RealArticulated {
    public static let id = "camera-sony-a7iv"
    public static let summary = "Sony a7 IV mirrorless camera with FE 28-70mm f/3.5-5.6 OSS kit lens: textured body, deep grip, mode dial stack, tall EVF, vari-angle LCD, articulated controls."
    public static let tags = ["prop", "electronics", "camera", "articulated", "handheld"]
    public static let budget = 20_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 15, distance: 1.1, studio: true)

    /// Rear LCD glass in asset space at rest: center, size (m) and outward normal.
    public struct ScreenRect: Sendable {
        public var center: V3
        public var size: V2
        public var normal: V3
    }
    public static let screenRect = ScreenRect(center: V3(-0.0225, 0.0370, 0.0432), size: V2(0.0634, 0.0423), normal: V3(0, 0, 1))

    /// Stipple-textured body plastic.
    public var bodyMaterial: MaterialKey = "plastic.cordless-stipple:25262A"
    /// Worn magnesium top plate.
    public var plateMaterial: MaterialKey = "metal.anodized-worn:2B2D31"
    /// Grip rubber.
    public var gripMaterial: MaterialKey = "rubber.cordless-grip"
    /// Lens ring rubber.
    public var ribMaterial: MaterialKey = "rubber"
    /// Zoom ring turn in degrees from 28 mm to 70 mm.
    public var zoomTravel: Float = 60
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        let rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [1.5])
        func put(_ s: Surface, _ x: Xform, to part: String? = nil, lods: ClosedRange<Int> = 0...1) {
            if let part { rig.add(s, x, to: part, lods: lods) } else { for l in lods { rig.base[l].add(s, x) } }
        }
        let W: Float = 0.1313, H: Float = 0.0745, hx = W / 2
        let zF: Float = -0.0215, zR: Float = 0.0400, zG: Float = -0.0398
        let ay: Float = 0.0400, topY: Float = 0.0964
        let body = bodyMaterial, plate = plateMaterial, grip = gripMaterial
        let btn: MaterialKey = "plastic.matte:2B2C2F", dark: MaterialKey = "plastic.matte:121316"
        let white: MaterialKey = "plastic.white", steel: MaterialKey = "metal.satin-aluminum"
        let orange: MaterialKey = "plastic.orange", red: MaterialKey = "plastic.sharps-red"
        let toZ = simd_quatf(degrees: 90, axis: V3(1, 0, 0))
        let toNegZ = simd_quatf(degrees: -90, axis: V3(1, 0, 0))
        func at(_ x: Float, _ y: Float, _ z: Float) -> Xform { Xform(translation: V3(x, y, z)) }
        func rib(_ r: Float, _ amp: Float, _ t: Int, _ y0: Float, _ y1: Float, _ m: MaterialKey) -> Surface { CanonR50.ribbedSolid(r, amp: amp, teeth: t, y0, y1, m) }

        // MARK: body
        put(Prim.roundedBox(V3(W, H, zR - zF), radius: 0.0050, bevelSegments: 2, material: body), at(0, H / 2, (zF + zR) / 2))
        // Magnesium top plate, slightly proud, with bare-metal edge wear strips.
        put(Prim.roundedBox(V3(W - 0.0004, 0.0036, zR - zF - 0.0004), radius: 0.0016, bevelSegments: 2, material: plate), at(0, H - 0.0012, (zF + zR) / 2))
        for sx: Float in [-1, 1] {
            put(Prim.roundedBox(V3(0.0006, 0.0004, 0.0300), radius: 0.0002, bevelSegments: 1, material: steel), at(sx * (hx - 0.0004), H + 0.0005, -0.0030 + sx * 0.0040), lods: 0...0)
        }
        put(Prim.roundedBox(V3(0.0500, 0.0004, 0.0006), radius: 0.0002, bevelSegments: 1, material: steel), at(-0.0100, H + 0.0004, zF + 0.0002), lods: 0...0)
        // Deep grip, textured rubber, with front finger lobe and rear thumb rest.
        put(Prim.roundedBox(V3(0.0300, H, zF - zG + 0.0105), radius: 0.0100, bevelSegments: 3, material: grip), at(hx - 0.0150 + 0.0004, H / 2, (zG + zF + 0.0105) / 2))
        put(Prim.roundedBox(V3(0.0036, 0.0500, 0.0170), radius: 0.0014, bevelSegments: 1, material: grip), at(hx + 0.0003, 0.0360, zG + 0.0110))
        put(Prim.roundedBox(V3(0.0220, 0.0300, 0.0030), radius: 0.0014, bevelSegments: 1, material: grip), at(0.0440, 0.0250, zR + 0.0001), lods: 0...0)
        // Front rubber inlay left of the mount and orange accent plate.
        put(Prim.extrude(Shape2D.roundedRect(0.0240, 0.0500, radius: 0.0030, segments: 3), depth: 0.0006, bevel: 0.0002, bevelSegments: 1, material: grip),
            at(-0.0510, 0.0370, zF - 0.0002 - 0.0004))
        put(Prim.roundedBox(V3(0.0090, 0.0012, 0.0004), radius: 0.0003, bevelSegments: 1, material: orange), at(-0.0510, 0.0655, zF - 0.0003), lods: 0...0)
        // Strap lugs.
        for sx: Float in [-1, 1] {
            put(Prim.roundedBox(V3(0.0032, 0.0080, 0.0110), radius: 0.0008, bevelSegments: 1, material: steel), at(sx * (hx + 0.0004), 0.0640, sx > 0 ? -0.0050 : 0.0100))
        }
        // EVF hump: tall prism block, centered over the lens.
        put(Prim.roundedBox(V3(0.0580, topY - H + 0.0030, 0.0420), radius: 0.0050, bevelSegments: 2, material: body), at(0, (topY + H - 0.0030) / 2, 0.0090))
        put(Prim.roundedBox(V3(0.0560, 0.0030, 0.0400), radius: 0.0014, bevelSegments: 2, material: plate), at(0, topY - 0.0010, 0.0090), lods: 0...0)
        // Hot shoe.
        put(Prim.roundedBox(V3(0.0190, 0.0008, 0.0200), radius: 0.0003, bevelSegments: 1, material: steel), at(0, topY + 0.0003, 0.0000))
        for sx: Float in [-1, 1] {
            put(Prim.roundedBox(V3(0.0018, 0.0006, 0.0190), radius: 0.0002, bevelSegments: 1, material: dark), at(sx * 0.0058, topY + 0.0009, 0.0000), lods: 0...0)
        }
        // Mount ring with white index dot and orange body accent.
        put(Prim.lathe([V2(0.0305, -0.0005), V2(0.0330, -0.0005), V2(0.0330, 0.0022), V2(0.0308, 0.0022)], segments: 44, seamTile: 0.1, material: steel),
            Xform(translation: V3(0, ay, zF), rotation: toNegZ))
        put(Prim.cylinder(radius: 0.0016, height: 0.0004, bevel: 0, segments: 10, bevelSegments: 1, material: white), Xform(translation: V3(-0.0330 * sin(0.9), ay + 0.0330 * cos(0.9), zF - 0.0004), rotation: toNegZ), lods: 0...0)
        put(Prim.cylinder(radius: 0.0016, height: 0.0004, bevel: 0, segments: 10, bevelSegments: 1, material: orange), Xform(translation: V3(0.0480, 0.0680, zG - 0.0002), rotation: toNegZ), lods: 0...0)

        // MARK: lens, FE 28-70mm f/3.5-5.6 OSS: base 72.5 mm, 83.5 mm long
        let lensX = Xform(translation: V3(0, ay, zF), rotation: toNegZ)
        let lensBlack: MaterialKey = "plastic.cordless-stipple:15161A"
        for l in 0..<2 {
            let seg = l == 0 ? 48 : 24
            // Base collar, fixed center barrel, front barrel with bore.
            put(Prim.lathe([V2(0.0308, 0.0022), V2(0.0345, 0.0023), V2(0.0348, 0.0125)], segments: seg, seamTile: 0.1, material: lensBlack), lensX, lods: l...l)
            put(Prim.lathe([V2(0.0345, 0.0455), V2(0.0345, 0.0520)], segments: seg, seamTile: 0.1, material: lensBlack), lensX, lods: l...l)
            put(Prim.lathe([V2(0.0318, 0.0700), V2(0.0318, 0.0830), V2(0.0324, 0.0832), V2(0.0324, 0.0835), V2(0.0262, 0.0835), V2(0.0258, 0.0833), V2(0.0255, 0.0820), V2(0.0255, 0.0740)], segments: seg, seamTile: 0.1, material: lensBlack), lensX, lods: l...l)
            // Coated front element (blue-green tint) over a deep violet inner element.
            put(Prim.lathe([V2(0, 0.0806), V2(0.0080, 0.0802), V2(0.0150, 0.0792), V2(0.0210, 0.0782), V2(0.0255, 0.0774)], segments: seg, seamTile: 0.1, material: "glass.tinted:1F7F8A"), lensX, lods: l...l)
        }
        put(Prim.lathe([V2(0, 0.0814), V2(0.0060, 0.0813), V2(0.0120, 0.0810), V2(0.0170, 0.0805)], segments: 32, seamTile: 0.1, material: "glass.tinted:2A44B0"), lensX, lods: 0...0)
        put(Prim.lathe([V2(0.0252, 0.0780), V2(0.0252, 0.0774), V2(0.0200, 0.0774)], segments: 32, seamTile: 0.1, material: "glass.tinted:2FA070"), lensX, lods: 0...0)
        put(Prim.cylinder(radius: 0.0250, height: 0.0006, bevel: 0, segments: 28, bevelSegments: 1, material: dark), Xform(translation: V3(0, ay, zF - 0.0690), rotation: toNegZ), lods: 0...0)
        put(Prim.lathe([V2(0.0240, 0.0786), V2(0.0240, 0.0780), V2(0.0180, 0.0780)], segments: 28, seamTile: 0.1, material: "metal.steel"), lensX, lods: 0...0)
        put(Prim.lathe([V2(0.0262, 0.0836), V2(0.0262, 0.0822), V2(0.0256, 0.0822), V2(0.0256, 0.0836)], segments: 48, seamTile: 0.1, material: "metal.chrome"), lensX, lods: 0...0)
        // Orange accent band on the fixed barrel and white index dot.
        put(Prim.lathe([V2(0.0348, 0.0480), V2(0.0348, 0.0492)], segments: 48, seamTile: 0.1, material: orange), lensX, lods: 0...0)
        put(Prim.lathe([V2(0.0325, 0.0702), V2(0.0325, 0.0707)], segments: 40, seamTile: 0.1, material: orange), lensX, lods: 0...0)
        put(Prim.roundedBox(V3(0.0020, 0.0004, 0.0020), radius: 0.0003, bevelSegments: 1, material: white), at(0, ay + 0.0346, zF - 0.0490), lods: 0...0)

        // Zoom ring (rear, wide) with rubber ribs and white focal marks 28/35/50/70.
        rig.part("zoom-ring", pivot: V3(0, ay, zF - 0.0290), joint: .hinge(axis: V3(0, 0, -1), 0...zoomTravel, duration: 0.6))
        put(rib(0.03625, 0.0009, 72, 0.0125, 0.0420, ribMaterial), lensX, to: "zoom-ring", lods: 0...0)
        put(Prim.cylinder(radius: 0.0368, height: 0.0295, bevel: 0.0004, segments: 28, bevelSegments: 1, material: ribMaterial),
            Xform(translation: V3(0, ay, zF - 0.0273), rotation: toNegZ), to: "zoom-ring", lods: 1...1)
        put(Prim.lathe([V2(0.0350, 0.0420), V2(0.0350, 0.0455), V2(0.0345, 0.0455)], segments: 44, seamTile: 0.1, material: lensBlack), lensX, to: "zoom-ring")
        for (deg, len) in [(-30, 0.0034), (-10, 0.0022), (10, 0.0022), (30, 0.0034)] as [(Float, Float)] {
            let t = deg * .pi / 180, r: Float = 0.0351
            put(Prim.roundedBox(V3(0.0008, 0.0003, len), radius: 0.00012, bevelSegments: 1, material: white),
                Xform(translation: V3(r * sin(t), ay + r * cos(t), zF - 0.0437), rotation: simd_quatf(degrees: -deg, axis: V3(0, 0, 1))), to: "zoom-ring", lods: 0...0)
        }
        // Focus ring (front, narrower).
        rig.part("focus-ring", pivot: V3(0, ay, zF - 0.0610), joint: .hinge(axis: V3(0, 0, -1), -90...90, duration: 0.6))
        put(rib(0.0334, 0.0008, 56, 0.0520, 0.0700, ribMaterial), lensX, to: "focus-ring", lods: 0...0)
        put(Prim.cylinder(radius: 0.0338, height: 0.0180, bevel: 0.0004, segments: 24, bevelSegments: 1, material: ribMaterial),
            Xform(translation: V3(0, ay, zF - 0.0520 - 0.0180 / 2 - 0.0000), rotation: toNegZ), to: "focus-ring", lods: 1...1)

        // MARK: top plate controls
        // Shutter with the power collar around it; front command dial on the grip front.
        let sxp: Float = 0.0500, szp: Float = -0.0060
        rig.part("shutter", pivot: V3(sxp, H + 0.0030, szp), joint: .slide(axis: V3(0, -1, 0), 0...0.0012, duration: 0.15))
        put(Prim.cylinder(radius: 0.0050, height: 0.0072, bevel: 0.0014, segments: 20, bevelSegments: 2, material: btn), at(sxp, H + 0.0005, szp), to: "shutter")
        put(Prim.cylinder(radius: 0.0019, height: 0.0003, bevel: 0, segments: 12, bevelSegments: 1, material: red), at(sxp, H + 0.0077, szp), to: "shutter", lods: 0...0)
        rig.part("power", pivot: V3(sxp, H, szp), joint: .hinge(axis: V3(0, 1, 0), -30...0, duration: 0.15))
        put(Prim.lathe([V2(0.0105, 0), V2(0.0105, 0.0020), V2(0.0058, 0.0020)], segments: 32, seamTile: 0.1, material: "plastic.matte:1A1B1E"), at(sxp, H, szp), to: "power")
        put(Prim.roundedBox(V3(0.0045, 0.0022, 0.0016), radius: 0.0005, bevelSegments: 1, material: white), at(sxp + 0.0090, H + 0.0010, szp), to: "power", lods: 0...0)

        let fx: Float = 0.0480, fy: Float = 0.0615
        rig.part("main-dial", pivot: V3(fx, fy, zF), joint: .hinge(axis: V3(0, 0, 1), -40...40, duration: 0.3))
        put(rib(0.0092, 0.0004, 30, 0, 0.0044, ribMaterial), Xform(translation: V3(fx, fy, zF - 0.0012), rotation: toNegZ), to: "main-dial", lods: 0...0)
        put(Prim.cylinder(radius: 0.0096, height: 0.0044, bevel: 0.0004, segments: 18, bevelSegments: 1, material: ribMaterial), Xform(translation: V3(fx, fy, zF - 0.0012), rotation: toNegZ), to: "main-dial", lods: 1...1)

        // C1 and video record on top, right of the hump.
        rig.part("c1", pivot: V3(0.0340, H + 0.0020, 0.0180), joint: .slide(axis: V3(0, -1, 0), 0...0.0008, duration: 0.1))
        put(Prim.cylinder(radius: 0.0036, height: 0.0020, bevel: 0.0006, segments: 14, bevelSegments: 1, material: btn), at(0.0340, H + 0.0012, 0.0180), to: "c1")
        put(Prim.cylinder(radius: 0.0010, height: 0.0002, bevel: 0, segments: 10, bevelSegments: 1, material: white), at(0.0340, H + 0.0024, 0.0180), to: "c1", lods: 0...0)
        rig.part("video", pivot: V3(0.0580, H + 0.0020, 0.0170), joint: .slide(axis: V3(0, -1, 0), 0...0.0008, duration: 0.1))
        put(Prim.cylinder(radius: 0.0036, height: 0.0020, bevel: 0.0006, segments: 14, bevelSegments: 1, material: btn), at(0.0580, H + 0.0012, 0.0170), to: "video")
        put(Prim.cylinder(radius: 0.0017, height: 0.0002, bevel: 0, segments: 12, bevelSegments: 1, material: red), at(0.0580, H + 0.0024, 0.0170), to: "video", lods: 0...0)

        // Locking mode dial stack: photo/video/S&Q switch ring under the dial, lock button on top.
        let mx: Float = -0.0470, mz: Float = 0.0090
        rig.part("mode-switch", pivot: V3(mx, H, mz), joint: .hinge(axis: V3(0, 1, 0), -20...20, duration: 0.2))
        put(rib(0.0108, 0.0004, 30, H, H + 0.0046, "plastic.matte:1B1C1F"), at(mx, 0, mz), to: "mode-switch", lods: 0...0)
        put(Prim.cylinder(radius: 0.0110, height: 0.0046, bevel: 0.0004, segments: 18, bevelSegments: 1, material: "plastic.matte:1B1C1F"), at(mx, H, mz), to: "mode-switch", lods: 1...1)
        put(Prim.roundedBox(V3(0.0030, 0.0005, 0.0016), radius: 0.0002, bevelSegments: 1, material: white), at(mx - 0.0100, H + 0.0047, mz), to: "mode-switch", lods: 0...0)
        rig.part("mode-dial", pivot: V3(mx, H + 0.0046, mz), joint: .hinge(axis: V3(0, 1, 0), -150...150, duration: 0.4))
        put(rib(0.0092, 0.0005, 32, H + 0.0046, H + 0.0120, ribMaterial), at(mx, 0, mz), to: "mode-dial", lods: 0...0)
        put(Prim.cylinder(radius: 0.0096, height: 0.0074, bevel: 0.0005, segments: 16, bevelSegments: 1, material: ribMaterial), at(mx, H + 0.0046, mz), to: "mode-dial", lods: 1...1)
        put(Prim.cylinder(radius: 0.0070, height: 0.0004, bevel: 0.0001, segments: 28, bevelSegments: 1, material: steel), at(mx, H + 0.0120, mz), to: "mode-dial")
        for i in 0..<8 {
            let a = Float(i) / 8 * 2 * .pi, r: Float = 0.0050
            put(Prim.cylinder(radius: 0.0007, height: 0.0002, bevel: 0, segments: 8, bevelSegments: 1, material: i == 0 ? orange : white),
                at(mx + r * cos(a), H + 0.0125, mz + r * sin(a)), to: "mode-dial", lods: 0...0)
        }
        put(Prim.cylinder(radius: 0.0026, height: 0.0004, bevel: 0.0001, segments: 14, bevelSegments: 1, material: dark), at(mx, H + 0.0123, mz), to: "mode-dial", lods: 0...0)

        // MARK: EVF (fixed): tall rubber eyecup around dark glass
        rig.part("evf", pivot: V3(0, 0.0855, 0.0300), joint: .fixed)
        let ey: Float = 0.0855, ez: Float = 0.0300
        put(Prim.roundedBox(V3(0.0340, 0.0200, 0.0014), radius: 0.0006, bevelSegments: 1, material: ribMaterial), at(0, ey, ez + 0.0004), to: "evf")
        let cw: Float = 0.0300, ch: Float = 0.0200, bt: Float = 0.0034, bd: Float = 0.0080
        for sy: Float in [-1, 1] {
            put(Prim.roundedBox(V3(cw, bt, bd), radius: 0.0013, bevelSegments: 1, material: ribMaterial), at(0, ey + sy * (ch - bt) / 2, ez + 0.0006 + bd / 2), to: "evf")
        }
        for sx: Float in [-1, 1] {
            put(Prim.roundedBox(V3(bt, ch, bd), radius: 0.0013, bevelSegments: 1, material: ribMaterial), at(sx * (cw - bt) / 2, ey, ez + 0.0006 + bd / 2), to: "evf")
        }
        put(Prim.extrude(Shape2D.roundedRect(cw - 2 * bt + 0.001, ch - 2 * bt + 0.001, radius: 0.002, segments: 3), depth: 0.0004, bevel: 0.0001, bevelSegments: 1, material: "glass.tinted:0B1A2A"),
            at(0, ey, ez + 0.0010), to: "evf")

        // MARK: rear controls
        let rz: Float = zR - 0.0005
        for (name, x, y, r) in [("menu", -0.0560, 0.0670, 0.0036), ("c2", -0.0440, 0.0670, 0.0036), ("af-on", 0.0290, 0.0650, 0.0042),
                                ("play", 0.0270, 0.0085, 0.0040), ("c3", 0.0580, 0.0085, 0.0040)] as [(String, Float, Float, Float)] {
            rig.part(name, pivot: V3(x, y, zR), joint: .slide(axis: V3(0, 0, -1), 0...0.0008, duration: 0.1))
            put(Prim.cylinder(radius: r, height: 0.0019, bevel: 0.0007, segments: 16, bevelSegments: 1, material: btn), Xform(translation: V3(x, y, rz), rotation: toZ), to: name)
        }
        // Rear dial: thumb wheel at the top right of the back.
        let rdx: Float = 0.0560, rdy: Float = 0.0600
        rig.part("rear-dial", pivot: V3(rdx, rdy, zR), joint: .hinge(axis: V3(0, 0, 1), -40...40, duration: 0.3))
        put(rib(0.0080, 0.0004, 24, 0, 0.0020, ribMaterial), Xform(translation: V3(rdx, rdy, rz), rotation: toZ), to: "rear-dial", lods: 0...0)
        put(Prim.cylinder(radius: 0.0084, height: 0.0020, bevel: 0.0005, segments: 20, bevelSegments: 1, material: ribMaterial), Xform(translation: V3(rdx, rdy, rz), rotation: toZ), to: "rear-dial", lods: 1...1)
        // Control wheel: dpad pads in a ring, wheel turns as dpad-ok with the center button.
        let px: Float = 0.0430, py: Float = 0.0300
        rig.part("dpad", pivot: V3(px, py, zR), joint: .slide(axis: V3(0, 0, -1), 0...0.0006, duration: 0.1))
        put(rib(0.0146, 0.0005, 36, 0, 0.0014, ribMaterial), Xform(translation: V3(px, py, rz), rotation: toZ), to: "dpad", lods: 0...0)
        put(Prim.cylinder(radius: 0.0150, height: 0.0014, bevel: 0.0004, segments: 28, bevelSegments: 1, material: ribMaterial), Xform(translation: V3(px, py, rz), rotation: toZ), to: "dpad", lods: 1...1)
        put(Prim.cylinder(radius: 0.0112, height: 0.0017, bevel: 0.0005, segments: 28, bevelSegments: 1, material: dark), Xform(translation: V3(px, py, rz), rotation: toZ), to: "dpad")
        let pads: [(String, Float, Float, Float, Float)] = [("dpad-up", 0, 1, 0.0058, 0.0030), ("dpad-down", 0, -1, 0.0058, 0.0030),
                                                            ("dpad-left", -1, 0, 0.0030, 0.0058), ("dpad-right", 1, 0, 0.0030, 0.0058)]
        for (name, sx, sy, w, h) in pads {
            let x = px + sx * 0.0086, y = py + sy * 0.0086
            rig.part(name, parent: "dpad", pivot: V3(x, y, zR), joint: .slide(axis: V3(0, 0, -1), 0...0.0006, duration: 0.1))
            put(Prim.roundedBox(V3(w, h, 0.0006), radius: 0.00025, bevelSegments: 1, material: btn), at(x, y, rz + 0.0017 + 0.00025), to: name, lods: 0...0)
            put(Prim.roundedBox(V3(w, h, 0.0006), radius: 0.00025, bevelSegments: 1, material: btn), at(x, y, rz + 0.0017 + 0.00025), to: name, lods: 1...1)
        }
        rig.part("dpad-ok", parent: "dpad", pivot: V3(px, py, zR), joint: .hinge(axis: V3(0, 0, 1), -40...40, duration: 0.3))
        put(Prim.cylinder(radius: 0.0052, height: 0.0010, bevel: 0.0004, segments: 18, bevelSegments: 1, material: btn), Xform(translation: V3(px, py, rz + 0.0017), rotation: toZ), to: "dpad-ok")

        // MARK: vari-angle LCD (hinged on the left edge)
        let sc = Self.screenRect, sx0 = sc.center.x, sy0 = sc.center.y
        let bezel: MaterialKey = "plastic.cordless-stipple:25262A"
        rig.part("screen", pivot: V3(-0.0625, sy0, zR), joint: .hinge(axis: V3(0, 1, 0), -180...0, duration: 0.8))
        put(Prim.extrude(Shape2D.roundedRect(0.0800, 0.0540, radius: 0.0035, segments: 4), depth: 0.0050, bevel: 0.0008, bevelSegments: 2, material: bezel),
            at(sx0, sy0, zR), to: "screen", lods: 0...0)
        put(Prim.roundedBox(V3(0.0800, 0.0540, 0.0050), radius: 0.0012, bevelSegments: 1, material: bezel), at(sx0, sy0, zR), to: "screen", lods: 1...1)
        // Glossy blue-black glass pane, slightly larger than the active area.
        put(Prim.extrude(Shape2D.roundedRect(0.0690, 0.0480, radius: 0.0020, segments: 3), depth: 0.0003, bevel: 0.0001, bevelSegments: 1, material: "plastic.gloss:08162E"),
            at(sx0, sy0, sc.center.z - 0.0004), to: "screen", lods: 0...1)
        var glass = Surface(material: "screen.off:07122E")
        let gw = sc.size.x / 2, gh = sc.size.y / 2, gz = sc.center.z, n = V3(0, 0, 1)
        let a = glass.add(V3(sx0 - gw, sy0 - gh, gz), n, V2(0, 0)), b = glass.add(V3(sx0 + gw, sy0 - gh, gz), n, V2(1, 0))
        let c = glass.add(V3(sx0 + gw, sy0 + gh, gz), n, V2(1, 1)), d = glass.add(V3(sx0 - gw, sy0 + gh, gz), n, V2(0, 1))
        glass.quad(a, b, c, d)
        glass.computeTangents()
        rig.add(glass, to: "screen")

        // Edge wear: bare-metal chips along the top plate edges, mount corners and grip.
        var wr = rng.fork(7)
        for _ in 0..<26 {
            let side: Float = wr.chance(0.5) ? -1 : 1
            let onFront = wr.chance(0.4)
            let fx0: Float = wr.float(-(W - 0.02) / 2 ... (W - 0.02) / 2)
            let x: Float = onFront ? fx0 : side * (hx - 0.0004)
            let zs: Float = zF + wr.float(0.004...(zR - zF - 0.004))
            let z: Float = onFront ? zF + 0.0002 : zs
            let lenF: Float = wr.float(0.0016...0.0046), lenS: Float = wr.float(0.0012...0.0047)
            let sz: V3 = onFront ? V3(lenF, 0.0004, 0.0006) : V3(0.0006, 0.0004, lenS)
            put(Prim.roundedBox(sz, radius: 0.00012, bevelSegments: 1, material: steel), at(x, H + 0.0004, z), lods: 0...0)
        }
        for sy: Float in [-1, 1] {
            put(Prim.roundedBox(V3(0.0004, 0.0100, 0.0006), radius: 0.0001, bevelSegments: 1, material: steel), at(hx - 0.0001, 0.0372 + sy * 0.0210, zR - 0.0003), lods: 0...0)
        }

        groundAO(&rig, height: 0.01, floor: 0.7)
        rig.states = [RigState("rest"), RigState("half-press", ["shutter": 0.0006]), RigState("full-press", ["shutter": 0.0012]),
                      RigState("screen-out", ["screen": -95])]
        _ = rng; _ = hx
        return rig
    }
}
