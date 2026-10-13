import simd
import Foundation

/// Roller blind, 1.2 m wide and 1.5 m drop, wall-mounted over a window: off-white linen-look fabric hanging from a white powder-coated aluminum cassette headrail with wall brackets and a chain clutch at the right end, stitched hem pocket holding a satin aluminum bottom bar with plastic end caps, and a stainless ball-chain loop. Back (wall side) at z = -depth / 2, fabric hangs on the +Z side.
public struct RollerBlind: RealAsset {
    public static let id = "roller-blind"
    public static let summary = "Roller window blind, 1.2 x 1.5 m: linen-look fabric, aluminum cassette, bottom bar, ball chain."
    public static let tags = ["prop", "floorplan", "home", "decor", "fabric", "metal", "wall", "interior"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 2.8, studio: true)

    /// Overall size in meters (x width, y drop, z depth). Authored with the lowest point at y = 0 and the wall side at the back.
    public var size = V3(1.2, 1.5, 0.08)
    /// Blind fabric.
    public var fabric: MaterialKey = "fabric.linen:E2DAC8"
    /// Dirtier hem pocket where hands pull the blind down.
    public var soiledHem: MaterialKey = "fabric.linen:D3C7AC"
    /// Cassette and brackets.
    public var cassette: MaterialKey = "metal.powdercoat:F0EEE8"
    /// Ball chain.
    public var chainMaterial: MaterialKey = "metal.stainless"
    /// Clutch, end caps and chain connector.
    public var plastic: MaterialKey = "plastic.matte:E8E6E0"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [4])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let w = size.x, h = size.y, d = size.z
        let bs = detail ? 2 : 1
        func box(_ sz: V3, _ c: V3, _ key: MaterialKey, r: Float = 0.002) {
            m.add(Prim.roundedBox(sz, radius: min(r, sz.x / 2.2, sz.y / 2.2, sz.z / 2.2), bevelSegments: bs, material: key), Xform(translation: c))
        }
        let cassH: Float = 0.068, cassD: Float = 0.056
        let cassW = w - 0.036 - 0.04, cassX: Float = -0.02
        let cassY = h - cassH / 2, cassZ: Float = -d / 2 + 0.004 + cassD / 2
        // Cassette: rounded fascia profile extruded along X; the short side caps are separate plates.
        let prof = Shape2D.rounded([V2(-cassD / 2, -cassH / 2), V2(cassD / 2, -cassH / 2), V2(cassD / 2, cassH / 2), V2(-cassD / 2, cassH / 2)], radius: 0.012, segments: 4)
        m.add(Prim.extrude(prof, depth: cassW, bevel: 0.0015, bevelSegments: 1, material: cassette),
              Xform(translation: V3(cassX, cassY, cassZ), rotation: simd_quatf(degrees: 90, axis: V3(0, 1, 0))))
        // Dark fabric slot under the front lip.
        box(V3(cassW - 0.05, 0.003, 0.02), V3(cassX, h - cassH + 0.0008, cassZ + 0.016), "plastic.black", r: 0.0008)
        // Wall brackets at both ends: plate on the wall, arm into the cassette, two screws.
        for s: Float in [-1, 1] {
            let bx = s * (w / 2 - 0.009)
            box(V3(0.018, 0.062, 0.005), V3(bx, cassY, -d / 2 + 0.0025), cassette, r: 0.002)
            box(V3(0.018, 0.022, 0.03), V3(bx, cassY, -d / 2 + 0.019), cassette, r: 0.002)
            if detail {
                for dy: Float in [-0.02, 0.02] {
                    m.add(Prim.cylinder(radius: 0.0042, height: 0.0018, bevel: 0.0008, segments: 10, material: "metal.steel"),
                          Xform(translation: V3(bx, cassY + dy, -d / 2 + 0.004), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
                }
            }
        }
        // Clutch housing on the right end and the ball chain loop.
        let cx = w / 2 - 0.04
        m.add(Prim.cylinder(radius: 0.027, height: 0.046, bevel: 0.005, segments: detail ? 24 : 12, material: plastic),
              Xform(translation: V3(cx + 0.003, cassY, cassZ + 0.0), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        let fabricZ: Float = cassZ + cassD / 2 - 0.006
        // Chain loop: two strands from the clutch wheel, joined by a connector at the bottom.
        let loopLen: Float = 0.5 + rng.float(-0.02...0.02)
        let chainTop = cassY - 0.026
        let cz = fabricZ + 0.012
        for dz: Float in [0, 0.009] {
            // Ball chain: one lathe whose radius pulses every 4.5 mm (beads) around a thin core.
            var prof: [(Float, Float)] = []
            let pitch: Float = 0.0045, rBall: Float = 0.0021, rCore: Float = 0.0006
            let beads = Int(loopLen / pitch)
            if detail {
                for b in 0..<beads {
                    let y = Float(b) * pitch
                    prof += [(rCore, y), (rBall, y + pitch * 0.5)]
                }
                prof.append((rCore, Float(beads) * pitch))
            } else {
                prof = [(rBall * 0.8, 0), (rBall * 0.8, Float(beads) * pitch)]
            }
            m.add(turned(prof, segments: detail ? 6 : 5, material: chainMaterial, seamTile: 0.01),
                  Xform(translation: V3(cx, chainTop - loopLen, cz + dz)))
        }
        box(V3(0.008, 0.016, 0.016), V3(cx, chainTop - loopLen, cz + 0.0045), plastic, r: 0.002)
        // Fabric drop: hangs from the slot to the hem pocket. Slightly uneven width at the roll edges.
        let barH: Float = 0.014
        let hemH: Float = 0.05
        let dropTop = h - cassH + 0.004
        let dropBottom = barH / 2 + 0.003
        let fw = cassW - 0.014 - 0.0
        // Cloth: two gently waved sheets (front and back) so light breaks across the weave and the drop is not a flat slab.
        let drop = dropTop - dropBottom
        let ph = rng.float(0...6.28)
        func wave(_ p: V2) -> Float {
            let t = (p.y + drop / 2) / drop          // 0 at the cassette end of the sheet (z axis flipped by the terrain rotation)
            return 0.003 * sin(p.x * 8 + ph) * (0.3 + 0.7 * t) + 0.0016 * sin(p.x * 21 + p.y * 2.5 + ph * 2) * (1 - 0.6 * t) + 0.0009 * sin(p.x * 47 + ph * 3)
        }
        let seg = detail ? 40 : 4
        let sheet = Prim.terrain(size: V2(fw, drop), segments: seg, material: fabric) { wave($0) }
        let tilt = simd_quatf(degrees: 90, axis: V3(1, 0, 0))
        m.add(sheet, Xform(translation: V3(cassX, (dropTop + dropBottom) / 2, fabricZ), rotation: tilt))
        box(V3(fw - 0.001, drop - 0.002, 0.0012), V3(cassX, (dropTop + dropBottom) / 2, fabricZ - 0.0012), fabric, r: 0.0004)
        // Hem pocket: a doubled strip with a stitched edge, holding the bar.
        box(V3(fw, hemH, 0.009), V3(cassX, barH / 2 + hemH / 2 - 0.004, fabricZ + 0.0035), soiledHem, r: 0.003)
        if detail {
            let stitchY = barH / 2 + hemH - 0.012
            m.add(stitches(along: [V3(cassX - fw / 2 + 0.008, stitchY, fabricZ + 0.0081), V3(cassX + fw / 2 - 0.008, stitchY, fabricZ + 0.0081)], normal: { _ in V3(0, 0, 1) }, pitch: 0.007, material: "thread.white"))
        }
        // Bottom bar and end caps (the bar sits inside the pocket).
        box(V3(fw - 0.01, barH, 0.006), V3(cassX, barH / 2, fabricZ + 0.003), "metal.satin-aluminum", r: 0.0025)
        for s: Float in [-1, 1] {
            box(V3(0.006, barH + 0.002, 0.011), V3(cassX + s * (fw / 2 - 0.002), barH / 2, fabricZ + 0.0035), plastic, r: 0.0025)
        }
        // Pull tab: small finger tab on the hem pocket.
        box(V3(0.04, 0.02, 0.003), V3(cassX - 0.18, 0.026, fabricZ + 0.0092), plastic, r: 0.001)
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -d / 2 - bb.min.z)))
        return m
    }
}
