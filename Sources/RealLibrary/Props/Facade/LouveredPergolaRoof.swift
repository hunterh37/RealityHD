import simd
import Foundation

/// Contemporary louvered pergola, 3 m square: four box-section aluminium posts on bolted base plates,
/// U-section gutter beams on all four sides with drain slots, 22 pivoting louvre blades (rounded-lens
/// extrusions with rubber seals and end caps) tilted 35 degrees on stainless pivot pins, a linkage bar with
/// pin links, a motor housing with conduit, and knee brackets at every post-beam joint. Charcoal powdercoat
/// with dust on the blades, chipped arrises on the posts and rust at the base-plate bolts.
public struct LouveredPergolaRoof: RealAsset {
    public static let id = "louvered-pergola-roof"
    public static let summary = "Contemporary aluminium pergola, 3 m square: four posts, perimeter gutter beams and 22 motorised louvre blades."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 14900
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 18, distance: 1.9, studio: true)

    /// Overall plan size (m) and height (m).
    public var span: Float = 3.0
    public var height: Float = 2.7
    /// Louvre tilt from horizontal (degrees).
    public var tilt: Float = 35
    /// Louvre count along the span.
    public var blades: Int = 22
    /// Powdercoat colour (sRGB hex).
    public var coat: UInt32 = 0x3A3D40
    public var steel: MaterialKey = "metal.stainless"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let S = span, H = height
        let pc = S / 2 - 0.075            // post centre offset
        let pw: Float = 0.12
        let beamH: Float = 0.2, beamW: Float = 0.16
        let beamBot = H - beamH
        let base = "metal.powdercoat:" + hex(coat, 0)
        let dust = "metal.powdercoat:" + hex(coat, 0.18)
        func box(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.003, rot: simd_quatf = .identity) { FA.box(&m, s, c, mat, r: r, rot: rot) }
        // Posts: box section with a vertical reveal, cap, drain slot and base plate with bolts.
        for (sx, sz) in [(1, 1), (-1, 1), (-1, -1), (1, -1)] as [(Float, Float)] {
            let c = V3(sx * pc, 0, sz * pc)
            box(V3(pw, beamBot - 0.012, pw), c + V3(0, 0.012 + (beamBot - 0.012) / 2, 0), base, r: 0.006)
            for dx in [-1, 1] as [Float] { box(V3(0.004, beamBot - 0.2, 0.012), c + V3(dx * (pw / 2 - 0.0005), 0.2 + (beamBot - 0.2) / 2, 0), "metal.powdercoat:" + hex(coat, -0.4), r: 0.0012) }
            box(V3(0.15, 0.012, 0.15), c + V3(0, 0.006, 0), "metal.galvanized-aged", r: 0.003)
            for (a, b) in [(-1, -1), (-1, 1), (1, -1), (1, 1)] as [(Float, Float)] { FSH.nut(&m, at: c + V3(a * 0.055, 0.012, b * 0.055), normal: FA.Y, size: 0.02, "metal.rust") }
            box(V3(0.13, 0.04, 0.13), c + V3(0, 0.032, 0), base, r: 0.006)   // base skirt
            // outlet slot near the top for the gutter downpipe
            box(V3(0.05, 0.012, 0.004), c + V3(0, beamBot - 0.12, sz * (pw / 2 + 0.001)), "metal.powdercoat:" + hex(coat, -0.6), r: 0.001)
            // chipped arris: bright aluminium showing at the lower corner
            box(V3(0.004, 0.06, 0.004), c + V3(sx * (pw / 2 - 0.001), 0.18 + rng.float(0...0.05), sz * (pw / 2 - 0.001)), "metal.aluminum-brushed", r: 0.0008)
        }
        // Gutter beams: base plate with two upstanding walls (U section) on four sides.
        func gutter(len: Float, at c: V3, alongX: Bool) {
            let rot: simd_quatf = alongX ? .identity : FA.q(90, FA.Y)
            func p(_ x: Float, _ y: Float, _ z: Float) -> V3 { c + (alongX ? V3(x, y, z) : V3(z, y, -x)) }
            box(V3(len, 0.03, beamW), p(0, 0.015, 0), base, r: 0.004, rot: rot)
            for s in [-1, 1] as [Float] {
                box(V3(len, beamH, 0.018), p(0, beamH / 2, s * (beamW / 2 - 0.009)), base, r: 0.0035, rot: rot)
            }
            // end caps
            box(V3(0.012, beamH - 0.01, beamW - 0.004), p(len / 2 - 0.006, beamH / 2, 0), dust, r: 0.0025, rot: rot)
            box(V3(0.012, beamH - 0.01, beamW - 0.004), p(-len / 2 + 0.006, beamH / 2, 0), dust, r: 0.0025, rot: rot)
            // dust line along the channel floor
            box(V3(len - 0.04, 0.003, beamW - 0.05), p(0, 0.0315, 0), dust, r: 0.001, rot: rot)
        }
        gutter(len: S, at: V3(0, beamBot, pc), alongX: true)
        gutter(len: S, at: V3(0, beamBot, -pc), alongX: true)
        gutter(len: S - 2 * pw - 0.004, at: V3(pc, beamBot, 0), alongX: false)
        gutter(len: S - 2 * pw - 0.004, at: V3(-pc, beamBot, 0), alongX: false)
        // Louvre blades pivoting between the side (Z-running) beams.
        let inner = pc - beamW / 2 + 0.009 - 0.018 + 0.018   // clear distance from the beam centre to the wall face
        let bl = 2 * (pc - (beamW / 2 - 0.018)) - 0.01
        let pitch = (2 * pc - beamW - 0.06) / Float(blades - 1)
        let chord: Float = 0.2, thick: Float = 0.026
        let t = tilt * .pi / 180
        func rotp(_ v: V2) -> V2 { V2(v.x * cos(t) - v.y * sin(t), v.x * sin(t) + v.y * cos(t)) }
        func lensPts(_ w: Float, _ h: Float, _ e: Float, _ n: Int) -> [V2] {
            (0..<n).map { i in
                let a = Float(i) / Float(n) * 2 * .pi, c = cos(a), sn = sin(a)
                return rotp(V2(w / 2 * (c < 0 ? -1 : 1) * pow(abs(c), 2 / e), h / 2 * (sn < 0 ? -1 : 1) * pow(abs(sn), 2 / e)))
            }
        }
        let lens = lensPts(chord, thick, 2.8, 12)
        let capLens = lensPts(chord + 0.01, thick + 0.01, 2.4, 12)
        let yP = beamBot + 0.1
        let z0 = -(Float(blades - 1) * pitch) / 2
        var linkPts: [V3] = []
        for i in 0..<blades {
            let z = z0 + Float(i) * pitch
            let wob = rng.float(-0.004...0.004) * .pi / 180
            let mat = "metal.powdercoat:" + hex(coat, 0.05 + 0.4 * rng.float() * (0.4 + 0.6 * Float(i) / Float(blades)))
            m.add(Prim.extrude(lens, depth: bl - 0.04, bevel: 0.001, bevelSegments: 1, material: mat),
                  Xform(translation: V3(0, yP, z), rotation: FA.q(-90, FA.Y) * simd_quatf(angle: wob, axis: FA.Z)))
            // rubber seals on both long edges
            for s in [-1, 1] as [Float] {
                let e = rotp(V2(s * chord / 2, 0))
                FA.rod(&m, V3(-bl / 2 + 0.03, yP + e.y, z + e.x), V3(bl / 2 - 0.03, yP + e.y, z + e.x), r: 0.0045, "rubber.silicone-gray", sides: 4)
            }
            for s in [-1, 1] as [Float] {
                m.add(Prim.extrude(capLens, depth: 0.02, bevel: 0, bevelSegments: 1, material: dust),
                      Xform(translation: V3(s * (bl / 2 - 0.012), yP, z), rotation: FA.q(-90, FA.Y)))
                FA.cylX(&m, r: 0.007, h: 0.02, at: V3(s * (bl / 2 - 0.002), yP, z), steel, bevel: 0, segments: 6)
            }
            linkPts.append(V3(bl / 2 - 0.035, yP - 0.03, z))
        }
        // Linkage bar and pin links on the +X end.
        let lx = bl / 2 - 0.045
        FA.rod(&m, V3(lx, yP - 0.034, z0 - 0.04), V3(lx, yP - 0.034, -z0 + 0.04), r: 0.007, steel, sides: 6)
        for i in 0..<blades where i % 1 == 0 {
            let z = z0 + Float(i) * pitch
            FSH.nut(&m, at: V3(lx - 0.003, yP - 0.017, z + 0.012), normal: FA.X, size: 0.012, steel)
        }
        // Motor housing and conduit near the +X, -Z corner.
        box(V3(0.2, 0.11, 0.1), V3(pc - 0.17, beamBot + 0.085, -pc + 0.115), "metal.powdercoat:" + hex(coat, -0.2), r: 0.012)
        FA.rod(&m, V3(pc - 0.17, beamBot + 0.03, -pc + 0.165), V3(pc - 0.01, beamBot + 0.03, -pc + 0.165), r: 0.009, "rubber.tubing", sides: 6)
        FA.rod(&m, V3(pc - 0.01, beamBot + 0.03, -pc + 0.165), V3(pc - 0.01, 0.2, -pc + 0.165), r: 0.009, "rubber.tubing", sides: 6)
        FA.cylX(&m, r: 0.02, h: 0.04, at: V3(pc - 0.27, beamBot + 0.085, -pc + 0.115), steel, bevel: 0.002, segments: 12)
        // Knee brackets: gusset triangles under each beam, both directions at every post.
        for (sx, sz) in [(1, 1), (-1, 1), (-1, -1), (1, -1)] as [(Float, Float)] {
            let d: Float = 0.26
            let triX: [V2] = [V2(0, 0), V2(-sx * d, d), V2(0, d)]
            let triZ: [V2] = [V2(0, 0), V2(-sz * d, d), V2(0, d)]
            m.add(Prim.extrude(sx > 0 ? triX : triX.reversed(), depth: 0.014, bevel: 0.002, bevelSegments: 1, material: base),
                  Xform(translation: V3(sx * (pc - pw / 2), beamBot - d, sz * pc)))
            m.add(Prim.extrude(sz > 0 ? triZ : triZ.reversed(), depth: 0.014, bevel: 0.002, bevelSegments: 1, material: base),
                  Xform(translation: V3(sx * pc, beamBot - d, sz * (pc - pw / 2)), rotation: FA.q(-90, FA.Y)))
            FSH.nut(&m, at: V3(sx * (pc - pw / 2 - 0.05), beamBot - 0.1, sz * (pc + 0.007)), normal: V3(0, 0, sz), size: 0.015, steel)
        }
        _ = inner
        groundAO(&m, height: 0.2, floor: 0.8)
        return LODModel(FC.place(m))
    }

    func hex(_ base: UInt32, _ light: Float) -> String {
        func ch(_ v: UInt32) -> UInt32 { UInt32(max(0, min(255, Float(v) + light * 90))) }
        return String(format: "%02X%02X%02X", ch(base >> 16 & 255), ch(base >> 8 & 255), ch(base & 255))
    }
}
