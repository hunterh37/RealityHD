import simd
import Foundation

/// Fujifilm X100VI compact camera, silver edition: brushed aluminum top and bottom plates, black pebbled
/// leatherette body, fixed 23mm f/2 lens. 128 x 74.8 x 55.3 mm. Base at y = 0, centered on X/Z, lens axis along
/// -Z (lens points -Z, rear LCD faces +Z). The EVF eyepiece sits top-left on the rear (-X).
/// Parts: shutter (with threaded release socket), power (lever ring), shutter-dial (ISO window), iso-dial,
/// ev-dial, main-dial (front), rear-dial, aperture-ring, focus-ring, ovf-lever, evf, screen (tilts up),
/// menu, play, af-on, focus-lever, dpad (dpad-up, dpad-down, dpad-left, dpad-right, dpad-ok).
/// States: rest, half-press (shutter 0.6 mm), full-press (1.2 mm), screen-out (LCD tilted up 45 degrees).
public struct FujiX100VI: RealArticulated {
    public static let id = "camera-fuji-x100vi"
    public static let summary = "Fujifilm X100VI compact camera, silver: brushed aluminum plates, pebbled leatherette, fixed 23mm f/2 lens, knurled dials, tilting LCD, rangefinder EVF."
    public static let tags = ["prop", "electronics", "camera", "articulated", "handheld"]
    public static let budget = 13_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 15, distance: 1.0, studio: true)

    /// Rear LCD glass in asset space at rest: center, size (m) and outward normal.
    public struct ScreenRect: Sendable {
        public var center: V3
        public var size: V2
        public var normal: V3
    }
    public static let screenRect = ScreenRect(center: V3(-0.0080, 0.0305, 0.0279), size: V2(0.0620, 0.0413), normal: V3(0, 0, 1))

    /// Top and bottom plates.
    public var plateMaterial: MaterialKey = "metal.satin-aluminum"
    /// Worn plate corners and edges.
    public var wearMaterial: MaterialKey = "metal.aluminum-brushed"
    /// Pebbled leatherette.
    public var leatherMaterial: MaterialKey = "leather.black"
    /// Aperture ring rotation in degrees either side of f/5.6.
    public var apertureTravel: Float = 75
    public init() {}

    static func ribbed(_ r: Float, amp: Float, teeth: Int) -> [V2] {
        let pat: [Float] = [0, 1, 1, 0], n = teeth * 4
        return (0..<n).map { i in
            let a = 2 * Float.pi * Float(i) / Float(n), rr = r + amp * pat[i % 4]
            return V2(rr * cos(a), rr * sin(a))
        }
    }
    static func ribbedSolid(_ r: Float, amp: Float, teeth: Int, _ y0: Float, _ y1: Float, _ mat: MaterialKey) -> Surface {
        let o = ribbed(r, amp: amp, teeth: teeth)
        return Prim.loft([Prim.ring(o, y: y0), Prim.ring(o, y: y1)], capStart: true, capEnd: true, material: mat)
    }

    public func rig(seed: UInt64) -> Rig {
        let rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [1.2])
        func put(_ s: Surface, _ x: Xform, to part: String? = nil, lods: ClosedRange<Int> = 0...1) {
            if let part { rig.add(s, x, to: part, lods: lods) } else { for l in lods { rig.base[l].add(s, x) } }
        }
        let W: Float = 0.128, hx = W / 2
        let zF: Float = -0.0123, zR: Float = 0.0227, zM = (zF + zR) / 2, D = zR - zF
        let ay: Float = 0.0320                                             // lens axis height
        let plate = plateMaterial, wear = wearMaterial, leather = leatherMaterial
        let btn: MaterialKey = "plastic.matte:26272A", dark: MaterialKey = "plastic.matte:121316"
        let ink: MaterialKey = "plastic.matte:101113", white: MaterialKey = "plastic.white"
        let toZ = simd_quatf(degrees: 90, axis: V3(1, 0, 0))               // local +Y -> +Z (rear controls)
        let toNegZ = simd_quatf(degrees: -90, axis: V3(1, 0, 0))           // local +Y -> -Z (lens axis)
        func at(_ x: Float, _ y: Float, _ z: Float) -> Xform { Xform(translation: V3(x, y, z)) }
        let bodyTop: Float = 0.0640, plateH: Float = 0.0090, botH: Float = 0.0075

        // MARK: body shell
        put(Prim.roundedBox(V3(W - 0.0030, bodyTop - botH - plateH + 0.0030, D - 0.0010), radius: 0.0020, bevelSegments: 2, material: dark),
            at(0, (botH + bodyTop - plateH) / 2, zM))
        // Pebbled leatherette panels front and rear, side wraps, raised grip pad on the front right.
        let ly0 = botH + 0.0003, ly1 = bodyTop - plateH - 0.0003, lh = ly1 - ly0
        for (z, s): (Float, Float) in [(zF, -1), (zR, 1)] {
            put(Prim.extrude(Shape2D.roundedRect(W - 0.0045, lh, radius: 0.0018, segments: 3), depth: 0.0010, bevel: 0.0003, bevelSegments: 1, material: leather),
                at(0, (ly0 + ly1) / 2, z + s * 0.0001))
        }
        for sx: Float in [-1, 1] {
            put(Prim.roundedBox(V3(0.0012, lh, D - 0.0014), radius: 0.0005, bevelSegments: 1, material: leather), at(sx * (hx - 0.0017), (ly0 + ly1) / 2, zM))
        }
        put(Prim.roundedBox(V3(0.0140, lh - 0.0040, 0.0020), radius: 0.0008, bevelSegments: 2, material: leather), at(0.0525, (ly0 + ly1) / 2, zF - 0.0008))

        // MARK: plates
        put(Prim.roundedBox(V3(W, plateH, D), radius: 0.0022, bevelSegments: 2, material: plate), at(0, bodyTop - plateH / 2, zM))
        put(Prim.roundedBox(V3(W, botH, D), radius: 0.0022, bevelSegments: 2, material: "metal.anodized-worn"), at(0, botH / 2, zM))
        // Bright worn corners on the plates (vertical edges and front lip).
        for sx: Float in [-1, 1] {
            for (z, sz) in [(zF, Float(-1)), (zR, Float(1))] {
                put(Prim.roundedBox(V3(0.0030, plateH - 0.0006, 0.0030), radius: 0.0010, bevelSegments: 1, material: wear), at(sx * (hx - 0.0011), bodyTop - plateH / 2, z - sz * 0.0011), lods: 0...0)
                put(Prim.roundedBox(V3(0.0030, botH - 0.0006, 0.0030), radius: 0.0010, bevelSegments: 1, material: wear), at(sx * (hx - 0.0011), botH / 2, z - sz * 0.0011), lods: 0...0)
            }
            put(Prim.roundedBox(V3(0.0140 + (sx > 0 ? 0.004 : 0), 0.0004, 0.0004), radius: 0.0002, bevelSegments: 1, material: wear), at(sx * 0.052, bodyTop - 0.0003, zF + 0.0002), lods: 0...0)
        }
        // Bottom plate details: tripod socket, battery door seam.
        put(Prim.cylinder(radius: 0.0030, height: 0.0004, bevel: 0, segments: 14, bevelSegments: 1, material: ink), Xform(translation: V3(0.0, 0.0, zM), rotation: simd_quatf(degrees: 180, axis: V3(1, 0, 0))), lods: 0...0)
        put(cuboid(V3(0.0300, 0.0003, 0.0008), material: ink), at(0.0310, 0.0001, zM + 0.0060), lods: 0...0)
        // Strap lugs.
        for sx: Float in [-1, 1] {
            put(Prim.roundedBox(V3(0.0036, 0.0075, 0.0100), radius: 0.0012, bevelSegments: 2, material: plate), at(sx * (hx + 0.0006), 0.0560, zM + 0.0005))
            put(Prim.roundedBox(V3(0.0040, 0.0040, 0.0044), radius: 0.0006, bevelSegments: 1, material: ink), at(sx * (hx + 0.0008), 0.0560, zM + 0.0005), lods: 0...0)
        }

        // MARK: EVF hump (left rear), hot shoe
        let hxC: Float = -0.0440, hw: Float = 0.0320, hh: Float = 0.0074
        put(Prim.roundedBox(V3(hw, hh, D - 0.0040), radius: 0.0030, bevelSegments: 2, material: plate), at(hxC, bodyTop + hh / 2 - 0.0004, zM + 0.0010))
        // Front OVF/EVF window (glossy coated) in the hump face.
        put(Prim.extrude(Shape2D.roundedRect(0.0120, 0.0050, radius: 0.0012, segments: 3), depth: 0.0006, bevel: 0.0002, bevelSegments: 1, material: "plastic.gloss:1C2733"),
            at(hxC + 0.0050, bodyTop + hh / 2 - 0.0004, zF + 0.0010 - 0.0005), lods: 0...0)
        put(Prim.roundedBox(V3(0.0044, 0.0044, 0.0006), radius: 0.0010, bevelSegments: 1, material: "glass.tinted:1A1C22"), at(hxC - 0.0090, bodyTop + hh / 2 - 0.0004, zF + 0.0008), lods: 0...0)
        let hs: Float = -0.0145
        put(cuboid(V3(0.0180, 0.0008, 0.0186), material: "metal.stainless"), at(hs, bodyTop + 0.0003, zM - 0.0010))
        for sx: Float in [-1, 1] {
            put(cuboid(V3(0.0018, 0.0006, 0.0176), material: dark), at(hs + sx * 0.0058, bodyTop + 0.0010, zM - 0.0010), lods: 0...0)
        }
        // Speaker grille dots left of the shoe are omitted; stereo mic slots on the plate.
        for sx: Float in [-1, 1] {
            put(cuboid(V3(0.0012, 0.0003, 0.0044), material: ink), at(sx * 0.0300 + 0.002, bodyTop + 0.0001, zF + 0.0062), lods: 0...0)
        }
        // AF illuminator.
        put(Prim.cylinder(radius: 0.0018, height: 0.0004, bevel: 0.0001, segments: 14, bevelSegments: 1, material: "glass.tinted:3A1E1E"), Xform(translation: V3(0.0480, 0.0590, zF - 0.0001), rotation: toNegZ), lods: 0...0)

        // MARK: lens (fixed 23mm f/2, 15.3 mm protrusion)
        let lensX = Xform(translation: V3(0, ay, zF), rotation: toNegZ)
        for l in 0..<2 {
            let seg = l == 0 ? 40 : 24
            // Mount collar and inner barrel.
            put(Prim.lathe([V2(0.0272, -0.0003), V2(0.0276, 0.0000), V2(0.0276, 0.0018), V2(0.0258, 0.0020), V2(0.0230, 0.0020), V2(0.0230, 0.0086)], segments: seg, seamTile: 0.1, material: plate), lensX, lods: l...l)
            // Front barrel: filter lip and recessed bore.
            put(Prim.lathe([V2(0.0236, 0.0120), V2(0.0236, 0.0150), V2(0.0231, 0.0153), V2(0.0212, 0.0153), V2(0.0210, 0.0149), V2(0.0200, 0.0140), V2(0.0196, 0.0100)], segments: seg, seamTile: 0.1, material: plate), lensX, lods: l...l)
            // Dark inner baffle and coated front element.
            put(Prim.lathe([V2(0.0196, 0.0100), V2(0.0196, 0.0116), V2(0.0170, 0.0116), V2(0.0170, 0.0100)], segments: seg, seamTile: 0.1, material: "plastic.matte:0A0A0D"), lensX, lods: l...l)
            put(Prim.lathe([V2(0, 0.0112), V2(0.0060, 0.0111), V2(0.0115, 0.0108), V2(0.0152, 0.0104), V2(0.0172, 0.0100)], segments: seg, seamTile: 0.1, material: "plastic.gloss:150F2A"), lensX, lods: l...l)
        }
        put(Prim.cylinder(radius: 0.0197, height: 0.0004, bevel: 0, segments: 32, bevelSegments: 1, material: "plastic.matte:07070A"), Xform(translation: V3(0, ay, zF - 0.0090), rotation: toNegZ), lods: 0...1)
        put(Prim.lathe([V2(0, 0.0115), V2(0.0030, 0.0114), V2(0.0065, 0.0111), V2(0.0092, 0.0107)], segments: 24, seamTile: 0.1, material: "plastic.gloss:1E2E3A"), lensX, lods: 0...0)
        put(Prim.lathe([V2(0.0171, 0.0107), V2(0.0171, 0.0102), V2(0.0150, 0.0102)], segments: 28, seamTile: 0.1, material: "metal.chrome"), lensX, lods: 0...0)

        // Focus ring (rear, fine ribs) and aperture ring (front, knurled with engraved marks).
        rig.part("focus-ring", pivot: V3(0, ay, zF - 0.0045), joint: .hinge(axis: V3(0, 0, -1), -90...90, duration: 0.6))
        put(Self.ribbedSolid(0.0258, amp: 0.0004, teeth: 32, 0.0020, 0.0070, "metal.aluminum-brushed"), lensX, to: "focus-ring", lods: 0...0)
        put(Prim.cylinder(radius: 0.0261, height: 0.0050, bevel: 0.0003, segments: 28, bevelSegments: 1, material: "metal.aluminum-brushed"),
            Xform(translation: V3(0, ay, zF - 0.0020), rotation: toNegZ), to: "focus-ring", lods: 1...1)
        rig.part("aperture-ring", pivot: V3(0, ay, zF - 0.0098), joint: .hinge(axis: V3(0, 0, -1), -apertureTravel...apertureTravel, duration: 0.5))
        do {
            let o = Self.ribbed(0.0250, amp: 0.00065, teeth: 34)
            put(Prim.loft([Prim.ring(o, y: 0.0072), Prim.ring(o, y: 0.0124)], capStart: false, capEnd: false, material: "metal.satin-aluminum"), lensX, to: "aperture-ring", lods: 0...0)
            put(Prim.lathe([V2(0.0252, 0.0124), V2(0.0214, 0.0124)], segments: 40, seamTile: 0.1, material: "metal.satin-aluminum"), lensX, to: "aperture-ring", lods: 0...0)
        }
        put(Prim.lathe([V2(0.0253, 0.0072), V2(0.0253, 0.0124), V2(0.0214, 0.0124)], segments: 28, seamTile: 0.1, material: "metal.satin-aluminum"),
            Xform(translation: V3(0, ay, zF), rotation: toNegZ), to: "aperture-ring", lods: 1...1)
        for (i, deg) in stride(from: Float(-60), through: 60, by: 15).enumerated() {
            let t = deg * .pi / 180, r: Float = 0.02565, len: Float = i % 2 == 0 ? 0.0030 : 0.0018
            put(cuboid(V3(0.0007, 0.0003, len), material: ink),
                Xform(translation: V3(r * sin(t), ay + r * cos(t), zF - 0.0112), rotation: simd_quatf(degrees: -deg, axis: V3(0, 0, 1))), to: "aperture-ring", lods: 0...0)
        }
        put(cuboid(V3(0.0012, 0.0003, 0.0034), material: "plastic.sharps-red"),
            Xform(translation: V3(0.02565 * sin(-0.95), ay + 0.02565 * cos(-0.95), zF - 0.0112), rotation: simd_quatf(angle: 0.95, axis: V3(0, 0, 1))), to: "aperture-ring", lods: 0...0)
        // Index mark on the fixed collar.
        put(cuboid(V3(0.0010, 0.0003, 0.0016), material: white), at(0, ay + 0.0277, zF - 0.0012), lods: 0...0)

        // MARK: top plate controls
        let ty = bodyTop
        // Shutter-speed dial with ISO ring and window.
        let sdx: Float = 0.0100, sdz: Float = zM - 0.0010
        rig.part("iso-dial", pivot: V3(sdx, ty, sdz), joint: .hinge(axis: V3(0, 1, 0), -50...50, duration: 0.3))
        put(Self.ribbedSolid(0.0124, amp: 0.0005, teeth: 32, ty, ty + 0.0042, "metal.satin-aluminum"), at(sdx, 0, sdz), to: "iso-dial", lods: 0...0)
        put(Prim.cylinder(radius: 0.0127, height: 0.0042, bevel: 0.0004, segments: 24, bevelSegments: 1, material: "metal.satin-aluminum"), at(sdx, ty, sdz), to: "iso-dial", lods: 1...1)
        for deg in stride(from: Float(-40), through: 40, by: 20) {
            let t = (deg - 90) * .pi / 180
            put(cuboid(V3(0.0005, 0.0002, 0.0020), material: ink),
                Xform(translation: V3(sdx + 0.0120 * cos(t), ty + 0.0042, sdz - 0.0120 * sin(t)), rotation: simd_quatf(angle: t - .pi / 2, axis: V3(0, 1, 0))), to: "iso-dial", lods: 0...0)
        }
        rig.part("shutter-dial", pivot: V3(sdx, ty + 0.0042, sdz), joint: .hinge(axis: V3(0, 1, 0), -150...150, duration: 0.4))
        put(Self.ribbedSolid(0.0100, amp: 0.0005, teeth: 28, ty + 0.0042, ty + 0.0108, "metal.satin-aluminum"), at(sdx, 0, sdz), to: "shutter-dial", lods: 0...0)
        put(Prim.cylinder(radius: 0.0103, height: 0.0066, bevel: 0.0004, segments: 24, bevelSegments: 1, material: "metal.satin-aluminum"), at(sdx, ty + 0.0042, sdz), to: "shutter-dial", lods: 1...1)
        put(Prim.cylinder(radius: 0.0092, height: 0.0004, bevel: 0.0001, segments: 28, bevelSegments: 1, material: plate), at(sdx, ty + 0.0108, sdz), to: "shutter-dial")
        for i in 0..<12 {
            let a = Float(i) / 12 * 2 * .pi, r: Float = 0.0072
            put(cuboid(V3(0.0006, 0.0002, i % 3 == 0 ? 0.0020 : 0.0012), material: i == 0 ? "plastic.sharps-red" : ink),
                Xform(translation: V3(sdx + r * cos(a), ty + 0.0113, sdz + r * sin(a)), rotation: simd_quatf(angle: -a, axis: V3(0, 1, 0))), to: "shutter-dial", lods: 0...0)
        }
        // ISO window on the dial rim facing the rear.
        put(cuboid(V3(0.0052, 0.0014, 0.0004), material: ink), at(sdx, ty + 0.0075, sdz + 0.0101), to: "shutter-dial", lods: 0...0)
        put(cuboid(V3(0.0044, 0.0008, 0.0002), material: white), at(sdx, ty + 0.0075, sdz + 0.0104), to: "shutter-dial", lods: 0...0)

        // Shutter button in a power lever ring with a threaded release socket.
        let bx: Float = 0.0370, bz: Float = zM - 0.0030
        rig.part("power", pivot: V3(bx, ty, bz), joint: .hinge(axis: V3(0, 1, 0), 0...28, duration: 0.2))
        put(Prim.lathe([V2(0.0070, 0.0), V2(0.0074, 0.0003), V2(0.0074, 0.0030), V2(0.0066, 0.0033), V2(0.0050, 0.0033), V2(0.0050, 0.0)], segments: 28, seamTile: 0.1, material: "metal.satin-aluminum"), at(bx, ty, bz), to: "power")
        put(Prim.roundedBox(V3(0.0030, 0.0022, 0.0050), radius: 0.0008, bevelSegments: 1, material: "metal.satin-aluminum"), at(bx - 0.0074, ty + 0.0011, bz + 0.0004), to: "power")
        rig.part("shutter", pivot: V3(bx, ty + 0.0070, bz), joint: .slide(axis: V3(0, -1, 0), 0...0.0012, duration: 0.15))
        put(Prim.lathe([V2(0.0046, 0.0000), V2(0.0046, 0.0036), V2(0.0042, 0.0043), V2(0.0030, 0.0046), V2(0.0022, 0.0045), V2(0.0022, 0.0030), V2(0.0014, 0.0030), V2(0.0014, 0.0043)], segments: 24, seamTile: 0.1, material: "metal.satin-aluminum"), at(bx, ty + 0.0010, bz), to: "shutter")
        put(Prim.cylinder(radius: 0.0021, height: 0.0001, bevel: 0, segments: 14, bevelSegments: 1, material: ink), at(bx, ty + 0.0053, bz), to: "shutter", lods: 0...0)

        // Exposure compensation dial.
        let ex: Float = 0.0545, ez: Float = zM + 0.0005
        rig.part("ev-dial", pivot: V3(ex, ty, ez), joint: .hinge(axis: V3(0, 1, 0), -45...45, duration: 0.3))
        put(Self.ribbedSolid(0.0088, amp: 0.0005, teeth: 24, ty, ty + 0.0066, "metal.satin-aluminum"), at(ex, 0, ez), to: "ev-dial", lods: 0...0)
        put(Prim.cylinder(radius: 0.0091, height: 0.0066, bevel: 0.0004, segments: 20, bevelSegments: 1, material: "metal.satin-aluminum"), at(ex, ty, ez), to: "ev-dial", lods: 1...1)
        put(Prim.cylinder(radius: 0.0078, height: 0.0004, bevel: 0.0001, segments: 24, bevelSegments: 1, material: plate), at(ex, ty + 0.0066, ez), to: "ev-dial")
        for (i, deg) in stride(from: Float(-45), through: 45, by: 15).enumerated() {
            let t = deg * .pi / 180, r: Float = 0.0058
            put(cuboid(V3(0.0005, 0.0002, i == 3 ? 0.0024 : 0.0014), material: i == 3 ? "plastic.sharps-red" : ink),
                Xform(translation: V3(ex + r * sin(t), ty + 0.0071, ez - r * cos(t)), rotation: simd_quatf(angle: t, axis: V3(0, 1, 0))), to: "ev-dial", lods: 0...0)
        }

        // MARK: front controls: command dial (front right grip) and OVF/EVF lever
        let fx: Float = 0.0535, fy: Float = 0.0465
        rig.part("main-dial", pivot: V3(fx, fy, zF - 0.0018), joint: .hinge(axis: V3(0, 0, -1), -40...40, duration: 0.3))
        put(Self.ribbedSolid(0.0070, amp: 0.0004, teeth: 18, 0, 0.0014, "metal.satin-aluminum"), Xform(translation: V3(fx, fy, zF - 0.0016), rotation: toNegZ), to: "main-dial", lods: 0...0)
        put(Prim.cylinder(radius: 0.0072, height: 0.0014, bevel: 0.0004, segments: 18, bevelSegments: 1, material: "metal.satin-aluminum"), Xform(translation: V3(fx, fy, zF - 0.0016), rotation: toNegZ), to: "main-dial", lods: 1...1)
        rig.part("ovf-lever", pivot: V3(-0.0455, 0.0400, zF), joint: .slide(axis: V3(1, 0, 0), -0.0030...0.0030, duration: 0.15))
        put(Prim.roundedBox(V3(0.0100, 0.0030, 0.0012), radius: 0.0010, bevelSegments: 2, material: "metal.satin-aluminum"), at(-0.0455, 0.0400, zF - 0.0010), to: "ovf-lever")
        for i in -2...2 {
            put(cuboid(V3(0.0003, 0.0020, 0.0003), material: ink), at(-0.0455 + Float(i) * 0.0016, 0.0400, zF - 0.0017), to: "ovf-lever", lods: 0...0)
        }

        // MARK: EVF eyepiece (fixed, rubber cup around dark glass)
        rig.part("evf", pivot: V3(hxC, bodyTop + hh / 2 - 0.0004, zR - 0.0010), joint: .fixed)
        let ez0 = zR - 0.0010, ecy = bodyTop + hh / 2 - 0.0004
        put(Prim.roundedBox(V3(0.0210, 0.0066, 0.0020), radius: 0.0012, bevelSegments: 1, material: "rubber"), at(hxC, ecy, ez0 + 0.0010), to: "evf")
        put(Prim.extrude(Shape2D.roundedRect(0.0160, 0.0042, radius: 0.0010, segments: 3), depth: 0.0003, bevel: 0.0001, bevelSegments: 1, material: "plastic.gloss:07070C"), at(hxC, ecy, ez0 + 0.0021), to: "evf")

        // MARK: rear controls
        let rz: Float = zR + 0.0003
        for (name, x, y, r) in [("menu", Float(-0.0545), Float(0.0300), Float(0.0036)), ("play", -0.0545, 0.0430, 0.0036), ("af-on", 0.0540, 0.0395, 0.0034)] as [(String, Float, Float, Float)] {
            rig.part(name, pivot: V3(x, y, zR), joint: .slide(axis: V3(0, 0, -1), 0...0.0008, duration: 0.1))
            put(Prim.cylinder(radius: r, height: 0.0018, bevel: 0.0006, segments: 16, bevelSegments: 1, material: btn), Xform(translation: V3(x, y, rz), rotation: toZ), to: name)
        }
        rig.part("focus-lever", pivot: V3(0.0540, 0.0310, zR), joint: .hinge(axis: V3(0, 1, 0), -12...12, duration: 0.1))
        put(Prim.cylinder(radius: 0.0030, height: 0.0020, bevel: 0.0008, segments: 14, bevelSegments: 1, material: btn), Xform(translation: V3(0.0540, 0.0310, rz), rotation: toZ), to: "focus-lever")
        rig.part("rear-dial", pivot: V3(0.0520, 0.0490, zR), joint: .hinge(axis: V3(0, 0, 1), -40...40, duration: 0.3))
        put(Self.ribbedSolid(0.0073, amp: 0.0004, teeth: 18, 0, 0.0017, "metal.satin-aluminum"), Xform(translation: V3(0.0520, 0.0490, rz - 0.0001), rotation: toZ), to: "rear-dial", lods: 0...0)
        put(Prim.cylinder(radius: 0.0075, height: 0.0017, bevel: 0.0004, segments: 18, bevelSegments: 1, material: "metal.satin-aluminum"), Xform(translation: V3(0.0520, 0.0490, rz - 0.0001), rotation: toZ), to: "rear-dial", lods: 1...1)
        let px: Float = 0.0495, py: Float = 0.0185
        rig.part("dpad", pivot: V3(px, py, zR), joint: .slide(axis: V3(0, 0, -1), 0...0.0006, duration: 0.1))
        put(Prim.cylinder(radius: 0.0100, height: 0.0016, bevel: 0.0005, segments: 28, bevelSegments: 1, material: dark), Xform(translation: V3(px, py, rz), rotation: toZ), to: "dpad")
        let pads: [(String, Float, Float, Float, Float)] = [("dpad-up", 0, 1, 0.0060, 0.0030), ("dpad-down", 0, -1, 0.0060, 0.0030),
                                                            ("dpad-left", -1, 0, 0.0030, 0.0060), ("dpad-right", 1, 0, 0.0030, 0.0060)]
        for (name, sx, sy, w, h) in pads {
            let x = px + sx * 0.0070, y = py + sy * 0.0070
            rig.part(name, parent: "dpad", pivot: V3(x, y, zR), joint: .slide(axis: V3(0, 0, -1), 0...0.0006, duration: 0.1))
            put(cuboid(V3(w, h, 0.0006), material: btn), at(x, y, rz + 0.0016 + 0.00025), to: name)
        }
        rig.part("dpad-ok", parent: "dpad", pivot: V3(px, py, zR), joint: .slide(axis: V3(0, 0, -1), 0...0.0006, duration: 0.1))
        put(Prim.cylinder(radius: 0.0046, height: 0.0010, bevel: 0.0004, segments: 18, bevelSegments: 1, material: btn), Xform(translation: V3(px, py, rz + 0.0016), rotation: toZ), to: "dpad-ok")

        // MARK: 3.0 in tilting LCD (hinged on the lower edge, top swings up and rearward)
        let sc = Self.screenRect, cx = sc.center.x, cy = sc.center.y
        rig.part("screen", pivot: V3(cx, 0.0080, zR), joint: .hinge(axis: V3(1, 0, 0), 0...45, duration: 0.6))
        put(Prim.extrude(Shape2D.roundedRect(0.0680, 0.0455, radius: 0.0030, segments: 4), depth: 0.0050, bevel: 0.0007, bevelSegments: 2, material: "plastic.gloss:17181C"),
            at(cx, cy, zR + 0.0025), to: "screen", lods: 0...0)
        put(Prim.roundedBox(V3(0.0680, 0.0455, 0.0050), radius: 0.0010, bevelSegments: 1, material: "plastic.gloss:17181C"), at(cx, cy, zR + 0.0025), to: "screen", lods: 1...1)
        var glass = Surface(material: "plastic.gloss:05060B")
        let gw = sc.size.x / 2, gh = sc.size.y / 2, gz = sc.center.z, n = V3(0, 0, 1)
        let a = glass.add(V3(cx - gw, cy - gh, gz), n, V2(0, 0)), b = glass.add(V3(cx + gw, cy - gh, gz), n, V2(1, 0))
        let c = glass.add(V3(cx + gw, cy + gh, gz), n, V2(1, 1)), d = glass.add(V3(cx - gw, cy + gh, gz), n, V2(0, 1))
        glass.quad(a, b, c, d)
        glass.computeTangents()
        rig.add(glass, to: "screen")

        groundAO(&rig, height: 0.01, floor: 0.7)
        rig.states = [RigState("rest"), RigState("half-press", ["shutter": 0.0006]), RigState("full-press", ["shutter": 0.0012]),
                      RigState("screen-out", ["screen": 45])]
        _ = rng
        return rig
    }
}
