import simd
import Foundation

/// Canon EOS R50 mirrorless camera with the RF-S 18-45mm kit lens, black body. Body 116.3 x 85.5 mm with a
/// 68.8 mm deep grip, 3.0 in vari-angle LCD, lens 69.5 mm dia x 44.3 mm. Base at y = 0, centered on X, lens
/// axis along -Z (lens points -Z, rear LCD faces +Z), grip on +X (the photographer's right).
/// Parts (joint entities): shutter, main-dial, mode-dial, power, video, rear-dial, dpad (dpad-up, dpad-down,
/// dpad-left, dpad-right, dpad-ok), menu, play, q, af-on, zoom-ring, screen (hinges out to the left), evf.
/// States: rest, half-press (shutter 0.6 mm), full-press (1.2 mm), screen-out.
public struct CanonR50: RealArticulated {
    public static let id = "camera-canon-r50"
    public static let summary = "Canon EOS R50 mirrorless camera with RF-S 18-45mm kit lens: black body, deep leatherette grip, vari-angle LCD, EVF hump with pop-up flash, articulated controls."
    public static let tags = ["prop", "electronics", "camera", "articulated", "handheld"]
    public static let budget = 12_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 15, distance: 1.1, studio: true)

    /// Rear LCD glass in asset space at rest: center, size (m) and outward normal.
    public struct ScreenRect: Sendable {
        public var center: V3
        public var size: V2
        public var normal: V3
    }
    public static let screenRect = ScreenRect(center: V3(-0.0208, 0.0335, 0.0345), size: V2(0.0634, 0.0423), normal: V3(0, 0, 1))

    /// Body plastic.
    public var bodyMaterial: MaterialKey = "plastic.black"
    /// Leatherette on the grip and the front inlay.
    public var leatherMaterial: MaterialKey = "plastic.soft-touch"
    /// Zoom ring rubber.
    public var ribMaterial: MaterialKey = "rubber"
    /// Zoom ring turn in degrees from 18 mm to 45 mm.
    public var zoomTravel: Float = 55
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
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [1.5])
        func put(_ s: Surface, _ x: Xform, to part: String? = nil, lods: ClosedRange<Int> = 0...1) {
            if let part { rig.add(s, x, to: part, lods: lods) } else { for l in lods { rig.base[l].add(s, x) } }
        }
        let W: Float = 0.1163, H: Float = 0.068, hx = W / 2
        let zF: Float = -0.015, zR: Float = 0.0314, zG: Float = -0.0344     // body front, body rear, grip front
        let ay: Float = 0.0375                                             // lens axis height
        let body = bodyMaterial, leather = leatherMaterial
        let btn: MaterialKey = "plastic.matte:2B2C2F", dark: MaterialKey = "plastic.matte:151618"
        let white: MaterialKey = "plastic.white", steel: MaterialKey = "metal.satin-aluminum"
        let toZ = simd_quatf(degrees: 90, axis: V3(1, 0, 0))               // local +Y -> +Z (rear controls)
        let toNegZ = simd_quatf(degrees: -90, axis: V3(1, 0, 0))           // local +Y -> -Z (lens axis)
        func at(_ x: Float, _ y: Float, _ z: Float) -> Xform { Xform(translation: V3(x, y, z)) }

        // MARK: body
        put(Prim.roundedBox(V3(W, H, zR - zF), radius: 0.0045, bevelSegments: 2, material: body), at(0, H / 2, (zF + zR) / 2))
        // Deep grip on the right, leatherette, with a finger lobe.
        put(Prim.roundedBox(V3(0.0263, H, 0.0234), radius: 0.0085, bevelSegments: 3, material: leather), at(0.04515, H / 2, (zG + zF + 0.004) / 2))
        put(Prim.roundedBox(V3(0.0030, 0.046, 0.0120), radius: 0.0012, bevelSegments: 1, material: leather), at(0.0575, 0.034, -0.008))
        // Front-left leatherette inlay.
        put(Prim.extrude(Shape2D.roundedRect(0.0237, 0.054, radius: 0.003, segments: 3), depth: 0.0006, bevel: 0.0002, bevelSegments: 1, material: leather),
            at(-0.0444, 0.034, zF - 0.0002), lods: 0...1)
        // Strap lugs.
        for sx: Float in [-1, 1] {
            put(Prim.roundedBox(V3(0.0030, 0.0075, 0.0100), radius: 0.0008, bevelSegments: 1, material: steel), at(sx * (hx + 0.0004), 0.0585, sx > 0 ? -0.004 : 0.004))
        }
        // EVF + pop-up flash hump.
        put(Prim.roundedBox(V3(0.054, 0.0195, 0.0382), radius: 0.004, bevelSegments: 2, material: body), at(0, 0.07575, 0.0071))
        put(Prim.extrude(Shape2D.roundedRect(0.034, 0.0075, radius: 0.0018, segments: 2), depth: 0.0006, bevel: 0.0002, bevelSegments: 1, material: "plastic.gloss:2A2C30"),
            at(0, 0.0777, -0.012 - 0.0001), lods: 0...0)
        // Hot shoe.
        put(Prim.roundedBox(V3(0.0190, 0.0008, 0.0186), radius: 0.0003, bevelSegments: 1, material: steel), at(0, 0.0855 + 0.0002, 0.0071))
        for sx: Float in [-1, 1] {
            put(Prim.roundedBox(V3(0.0018, 0.0006, 0.0176), radius: 0.0002, bevelSegments: 1, material: dark), at(sx * 0.0058, 0.0855 + 0.0008, 0.0071), lods: 0...0)
        }
        // Lens mount: front face plate, speaker-less; RF mount ring.
        put(Prim.lathe([V2(0.0300, -0.0005), V2(0.0320, -0.0005), V2(0.0320, 0.0022), V2(0.0303, 0.0022)], segments: 40, seamTile: 0.1, material: steel),
            Xform(translation: V3(0, ay, zF), rotation: toNegZ))

        // MARK: lens (RF-S 18-45mm, 44.3 mm long, 69.5 mm at the zoom ring)
        let lensX = Xform(translation: V3(0, ay, zF), rotation: toNegZ)
        for l in 0..<2 {
            let seg = l == 0 ? 40 : 20
            put(Prim.lathe([V2(0.0300, 0.0022), V2(0.0300, 0.0124), V2(0.0338, 0.0125)], segments: seg, seamTile: 0.1, material: "plastic.matte:1A1B1D"), lensX, lods: l...l)
            // Front barrel with the face ring and the recessed element bore.
            put(Prim.lathe([V2(0.0338, 0.0345), V2(0.0330, 0.0346), V2(0.0330, 0.0440), V2(0.0329, 0.0443), V2(0.0250, 0.0443), V2(0.0248, 0.0441), V2(0.0246, 0.0430), V2(0.0246, 0.0398)], segments: seg, seamTile: 0.1, material: "plastic.matte:1A1B1D"), lensX, lods: l...l)
            // Coated front element dome and the dark element behind it.
            put(Prim.lathe([V2(0, 0.0408), V2(0.0075, 0.0407), V2(0.0145, 0.0403), V2(0.0200, 0.0398), V2(0.0246, 0.0394)], segments: seg, seamTile: 0.1, material: "glass.tinted:3A2A5C"), lensX, lods: l...l)
        }
        put(Prim.cylinder(radius: 0.0244, height: 0.0006, bevel: 0, segments: 28, bevelSegments: 1, material: "plastic.matte:0C0C10"), Xform(translation: V3(0, ay, zF - 0.0382), rotation: toNegZ), lods: 0...0)
        put(Prim.lathe([V2(0, 0.0349), V2(0.0050, 0.0348), V2(0.0095, 0.0345), V2(0.0125, 0.0340)], segments: 28, seamTile: 0.1, material: "plastic.gloss:2B1B3F"), lensX, lods: 0...0)
        put(Prim.lathe([V2(0.0236, 0.0397), V2(0.0236, 0.0392), V2(0.0170, 0.0392)], segments: 28, seamTile: 0.1, material: "metal.steel"), lensX, lods: 0...0)
        // Index dot on the fixed barrel and the engraved mark.
        put(Prim.roundedBox(V3(0.0016, 0.0003, 0.0016), radius: 0.0003, bevelSegments: 1, material: white), at(0, ay + 0.0331, zF - 0.0383), lods: 0...0)

        // Zoom ring: rubber ribs, smooth lip with white focal marks.
        rig.part("zoom-ring", pivot: V3(0, ay, zF - 0.02), joint: .hinge(axis: V3(0, 0, -1), 0...zoomTravel, duration: 0.6))
        put(Self.ribbedSolid(0.0340, amp: 0.00075, teeth: 64, 0.0125, 0.0315, ribMaterial), lensX, to: "zoom-ring", lods: 0...0)
        put(Prim.lathe([V2(0.0343, 0.0315), V2(0.0343, 0.0345), V2(0.0300, 0.0345)], segments: 40, seamTile: 0.1, material: "plastic.matte:1A1B1D"), lensX, to: "zoom-ring")
        put(Prim.cylinder(radius: 0.03475, height: 0.0190, bevel: 0.0004, segments: 24, bevelSegments: 1, material: ribMaterial),
            Xform(translation: V3(0, ay, zF - 0.0125), rotation: toNegZ), to: "zoom-ring", lods: 1...1)
        for (deg, len) in [(-26, 0.0030), (-9, 0.0018), (9, 0.0018), (26, 0.0030)] as [(Float, Float)] {
            let t = deg * .pi / 180, r: Float = 0.03435
            put(Prim.roundedBox(V3(0.0007, 0.0003, len), radius: 0.00012, bevelSegments: 1, material: white),
                Xform(translation: V3(r * sin(t), ay + r * cos(t), zF - 0.0330), rotation: simd_quatf(degrees: -deg, axis: V3(0, 0, 1))), to: "zoom-ring", lods: 0...0)
        }

        // MARK: top plate controls
        let dx: Float = 0.0455, dz: Float = -0.004
        rig.part("shutter", pivot: V3(dx, 0.0745, dz), joint: .slide(axis: V3(0, -1, 0), 0...0.0012, duration: 0.15))
        rig.part("main-dial", pivot: V3(dx, 0.07, dz), joint: .hinge(axis: V3(0, 1, 0), -40...40, duration: 0.3))
        put(Self.ribbedSolid(0.0082, amp: 0.0004, teeth: 28, 0.0672, 0.0722, ribMaterial), at(dx, 0, dz), to: "main-dial", lods: 0...0)
        put(Prim.cylinder(radius: 0.0086, height: 0.0050, bevel: 0.0004, segments: 16, bevelSegments: 1, material: ribMaterial), at(dx, 0.0672, dz), to: "main-dial", lods: 1...1)
        put(Prim.cylinder(radius: 0.0047, height: 0.0072, bevel: 0.0013, segments: 20, bevelSegments: 2, material: btn), at(dx, 0.0673, dz), to: "shutter")

        rig.part("video", pivot: V3(dx, 0.0685, 0.0155), joint: .slide(axis: V3(0, -1, 0), 0...0.0008, duration: 0.1))
        put(Prim.cylinder(radius: 0.0037, height: 0.0020, bevel: 0.0006, segments: 14, bevelSegments: 1, material: btn), at(dx, 0.0670, 0.0155), to: "video")
        put(Prim.cylinder(radius: 0.0016, height: 0.0002, bevel: 0, segments: 12, bevelSegments: 1, material: "plastic.sharps-red"), at(dx, 0.0690, 0.0155), to: "video", lods: 0...0)

        let mx: Float = -0.0405
        rig.part("mode-dial", pivot: V3(mx, 0.07, 0), joint: .hinge(axis: V3(0, 1, 0), -150...150, duration: 0.4))
        put(Self.ribbedSolid(0.0090, amp: 0.0005, teeth: 32, 0.0668, 0.0745, ribMaterial), at(mx, 0, 0), to: "mode-dial", lods: 0...0)
        put(Prim.cylinder(radius: 0.0095, height: 0.0077, bevel: 0.0005, segments: 16, bevelSegments: 1, material: ribMaterial), at(mx, 0.0668, 0), to: "mode-dial", lods: 1...1)
        put(Prim.cylinder(radius: 0.0074, height: 0.0004, bevel: 0.0001, segments: 28, bevelSegments: 1, material: steel), at(mx, 0.0745, 0), to: "mode-dial")
        for i in 0..<8 {
            let a = Float(i) / 8 * 2 * .pi, r: Float = 0.0053
            put(Prim.cylinder(radius: 0.0007, height: 0.0002, bevel: 0, segments: 8, bevelSegments: 1, material: i == 0 ? "plastic.sharps-red" : white),
                at(mx + r * cos(a), 0.0749, r * sin(a)), to: "mode-dial", lods: 0...0)
        }
        rig.part("power", pivot: V3(mx, 0.0685, 0.0215), joint: .slide(axis: V3(1, 0, 0), -0.003...0.003, duration: 0.15))
        put(Prim.roundedBox(V3(0.0078, 0.0030, 0.0042), radius: 0.0012, bevelSegments: 1, material: btn), at(mx, 0.0688, 0.0215), to: "power")

        // MARK: EVF (fixed): rubber eyecup frame around the dark glass
        rig.part("evf", pivot: V3(0, 0.0758, 0.0262), joint: .fixed)
        let ez: Float = 0.0262
        put(Prim.roundedBox(V3(0.0300, 0.0230, 0.0012), radius: 0.0005, bevelSegments: 1, material: ribMaterial), at(0, 0.0758, ez + 0.0004), to: "evf")
        let cw: Float = 0.0262, ch: Float = 0.0202, bt: Float = 0.0032, bd: Float = 0.0050
        for sy: Float in [-1, 1] {
            put(Prim.roundedBox(V3(cw, bt, bd), radius: 0.0012, bevelSegments: 1, material: ribMaterial), at(0, 0.0758 + sy * (ch - bt) / 2, ez + 0.0006 + bd / 2), to: "evf")
        }
        for sx: Float in [-1, 1] {
            put(Prim.roundedBox(V3(bt, ch, bd), radius: 0.0012, bevelSegments: 1, material: ribMaterial), at(sx * (cw - bt) / 2, 0.0758, ez + 0.0006 + bd / 2), to: "evf")
        }
        put(Prim.extrude(Shape2D.roundedRect(cw - 2 * bt + 0.001, ch - 2 * bt + 0.001, radius: 0.002, segments: 3), depth: 0.0004, bevel: 0.0001, bevelSegments: 1, material: "glass.tinted"),
            at(0, 0.0758, ez + 0.0010), to: "evf")

        // MARK: rear controls (RF thumb area right of the LCD)
        let rz: Float = zR - 0.0005
        for (name, x, y) in [("menu", 0.0215, 0.0590), ("play", 0.0215, 0.0090), ("q", 0.0545, 0.0095), ("af-on", 0.0510, 0.0590)] as [(String, Float, Float)] {
            rig.part(name, pivot: V3(x, y, zR), joint: .slide(axis: V3(0, 0, -1), 0...0.0008, duration: 0.1))
            put(Prim.cylinder(radius: 0.0042, height: 0.0019, bevel: 0.0007, segments: 16, bevelSegments: 1, material: btn), Xform(translation: V3(x, y, rz), rotation: toZ), to: name)
        }
        let px: Float = 0.0385, py: Float = 0.0300
        rig.part("rear-dial", pivot: V3(px, py, zR), joint: .hinge(axis: V3(0, 0, 1), -40...40, duration: 0.3))
        rig.part("dpad", pivot: V3(px, py, zR), joint: .slide(axis: V3(0, 0, -1), 0...0.0006, duration: 0.1))
        put(Self.ribbedSolid(0.0143, amp: 0.0005, teeth: 28, 0, 0.0014, ribMaterial), Xform(translation: V3(px, py, rz), rotation: toZ), to: "rear-dial", lods: 0...0)
        put(Prim.cylinder(radius: 0.0148, height: 0.0014, bevel: 0.0004, segments: 24, bevelSegments: 1, material: ribMaterial), Xform(translation: V3(px, py, rz), rotation: toZ), to: "rear-dial", lods: 1...1)
        put(Prim.cylinder(radius: 0.0113, height: 0.0017, bevel: 0.0005, segments: 28, bevelSegments: 1, material: dark), Xform(translation: V3(px, py, rz), rotation: toZ), to: "dpad")
        let pads: [(String, Float, Float, Float, Float)] = [("dpad-up", 0, 1, 0.0062, 0.0034), ("dpad-down", 0, -1, 0.0062, 0.0034),
                                                            ("dpad-left", -1, 0, 0.0034, 0.0062), ("dpad-right", 1, 0, 0.0034, 0.0062)]
        for (name, sx, sy, w, h) in pads {
            let x = px + sx * 0.0078, y = py + sy * 0.0078
            rig.part(name, parent: "dpad", pivot: V3(x, y, zR), joint: .slide(axis: V3(0, 0, -1), 0...0.0006, duration: 0.1))
            put(Prim.roundedBox(V3(w, h, 0.0006), radius: 0.00025, bevelSegments: 1, material: btn), at(x, y, rz + 0.0017 + 0.00025), to: name)
        }
        rig.part("dpad-ok", parent: "dpad", pivot: V3(px, py, zR), joint: .slide(axis: V3(0, 0, -1), 0...0.0006, duration: 0.1))
        put(Prim.cylinder(radius: 0.0052, height: 0.0010, bevel: 0.0004, segments: 18, bevelSegments: 1, material: btn), Xform(translation: V3(px, py, rz + 0.0017), rotation: toZ), to: "dpad-ok")

        // MARK: vari-angle LCD (hinged on the left edge, swings out rearward)
        let sc = Self.screenRect, sx0 = sc.center.x
        rig.part("screen", pivot: V3(-0.0568, 0.0335, 0.0314), joint: .hinge(axis: V3(0, 1, 0), -180...0, duration: 0.8))
        put(Prim.extrude(Shape2D.roundedRect(0.0712, 0.0510, radius: 0.0035, segments: 4), depth: 0.0062, bevel: 0.0008, bevelSegments: 2, material: "plastic.matte:222326"),
            at(sx0, 0.0335, 0.0314), to: "screen", lods: 0...0)
        put(Prim.roundedBox(V3(0.0712, 0.0510, 0.0062), radius: 0.0012, bevelSegments: 1, material: "plastic.matte:222326"), at(sx0, 0.0335, 0.0314), to: "screen", lods: 1...1)
        var glass = Surface(material: "screen.off")
        let gw = sc.size.x / 2, gh = sc.size.y / 2, gz = sc.center.z, n = V3(0, 0, 1)
        let a = glass.add(V3(sx0 - gw, 0.0335 - gh, gz), n, V2(0, 0)), b = glass.add(V3(sx0 + gw, 0.0335 - gh, gz), n, V2(1, 0))
        let c = glass.add(V3(sx0 + gw, 0.0335 + gh, gz), n, V2(1, 1)), d = glass.add(V3(sx0 - gw, 0.0335 + gh, gz), n, V2(0, 1))
        glass.quad(a, b, c, d)
        glass.computeTangents()
        rig.add(glass, to: "screen")

        groundAO(&rig, height: 0.01, floor: 0.7)
        rig.states = [RigState("rest"), RigState("half-press", ["shutter": 0.0006]), RigState("full-press", ["shutter": 0.0012]),
                      RigState("screen-out", ["screen": -95])]
        _ = rng
        return rig
    }
}
