import simd
import Foundation

/// 15 ft ladder tree stand: 4.57 m platform height, three-section powder-coated steel ladder leaning 11 degrees,
/// slatted platform 76 x 80 cm, padded seat with mesh back, padded shooting rail with side rails, support braces,
/// ratchet strap, haul line and bow hook. Tree side is -Z, ladder foot +Z.
public struct LadderTreeStand: RealAsset {
    public static let id = "ladder-tree-stand"
    public static let summary = "15 ft ladder tree stand: steel ladder, slatted platform, padded seat and shooting rail, braces, ratchet strap, haul line."
    public static let tags = ["prop", "hunting", "outdoor", "metal"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 38, elevation: 22, distance: 1.15)

    /// Platform floor height in meters (15 ft).
    public var platformHeight: Float = 4.57
    /// Platform width and depth in meters.
    public var platform = V2(0.76, 0.80)
    /// Ladder lean from vertical in degrees.
    public var lean: Float = 11
    /// Shooting rail height above the platform in meters.
    public var railHeight: Float = 0.80
    /// Frame color (sRGB hex).
    public var frameColor: UInt32 = 0x3A4430
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let frame = "metal.powdercoat-worn:" + HuntCampKit.hex(frameColor)
        let worn = "metal.galvanized-aged"
        let pad = "foam.eva:2F382A"
        let H = platformHeight, tl = tan(lean * .pi / 180)
        let halfW = platform.x / 2
        let frontZ: Float = 0.05
        func railZ(_ y: Float) -> Float { frontZ + (H - y) * tl }
        let lw: Float = 0.19                       // ladder rail center offset

        // Ladder rails with sleeve joints at the section breaks, rubber-footed.
        for s: Float in [-1, 1] {
            let top = V3(s * lw, H - 0.04, railZ(H - 0.04)), foot = V3(s * lw, 0.012, railZ(0.012))
            HuntCampKit.bar(&m, foot, top, w: 0.05, t: 0.032, up: V3(1, 0, 0), mat: frame)
            for y in [1.52, 3.05] as [Float] {
                let c = V3(s * lw, y, railZ(y)), d = simd_normalize(top - foot) * 0.07
                HuntCampKit.bar(&m, c - d, c + d, w: 0.056, t: 0.038, up: V3(1, 0, 0), mat: worn, bevel: 0.004)
                for k: Float in [-0.035, 0.035] { hexBolt(&m, at: c + d * k * 20 + V3(s * 0.019, 0, 0), normal: V3(s, 0, 0), size: 0.011, material: "metal.screw-zinc") }
            }
            m.add(Prim.roundedBox(V3(0.06, 0.012, 0.09), radius: 0.004, bevelSegments: 1, material: "rubber.plate"),
                  Xform(translation: V3(s * lw, 0.006, railZ(0.0) + 0.012)))
        }
        // Rust and mud at the feet, weld beads at the platform joints.
        for s: Float in [-1, 1] {
            HuntCampKit.bar(&m, V3(s * lw, 0.02, railZ(0.02)), V3(s * lw, 0.30, railZ(0.30)), w: 0.052, t: 0.034, up: V3(1, 0, 0), mat: "metal.rust-grime", bevel: 0.004)
        }
        // Rungs: serrated steps, 5 cm deep, every 30 cm.
        var y: Float = 0.34
        while y < H - 0.2 {
            let a = V3(-lw, y, railZ(y)), b = V3(lw, y, railZ(y))
            HuntCampKit.bar(&m, a, b, w: 0.055, t: 0.016, mat: y < 1.4 ? "metal.rust-grime" : worn, bevel: 0.003)
            y += 0.305
        }
        // Platform frame at the top of the ladder, tree notch at the back.
        let fy = H - 0.03, backZ = frontZ - platform.y
        let fl = V3(-halfW, fy, frontZ), fr = V3(halfW, fy, frontZ)
        HuntCampKit.bar(&m, fl, fr, w: 0.045, t: 0.032, mat: frame)
        for s: Float in [-1, 1] {
            HuntCampKit.bar(&m, V3(s * halfW, fy, frontZ), V3(s * halfW, fy, backZ), w: 0.045, t: 0.032, mat: frame)
            HuntCampKit.bar(&m, V3(s * 0.20, fy, backZ), V3(s * halfW, fy, backZ), w: 0.04, t: 0.032, mat: frame)
            // Angled gripper teeth at the notch.
            HuntCampKit.bar(&m, V3(s * 0.20, fy + 0.005, backZ), V3(s * 0.13, fy + 0.005, backZ - 0.07), w: 0.04, t: 0.032, mat: worn)
            for k in 0..<3 { HuntCampKit.bar(&m, V3(s * (0.16 - Float(k) * 0.015), fy + 0.02, backZ - 0.05), V3(s * (0.16 - Float(k) * 0.015), fy + 0.034, backZ - 0.05), w: 0.007, t: 0.007, mat: worn, bevel: 0.001) }
        }
        for z in [frontZ - platform.y * 0.33, frontZ - platform.y * 0.66] as [Float] {
            HuntCampKit.bar(&m, V3(-halfW, fy - 0.005, z), V3(halfW, fy - 0.005, z), w: 0.03, t: 0.03, mat: frame)
        }
        // Floor slats, welded flat bar with a punched edge.
        let slats = 13
        let pitch = (platform.y - 0.04) / Float(slats)
        for i in 0..<slats {
            let z = frontZ - 0.025 - pitch * (Float(i) + 0.5)
            HuntCampKit.bar(&m, V3(-halfW + 0.02, H - 0.012, z), V3(halfW - 0.02, H - 0.012, z), w: pitch * 0.62, t: 0.012, mat: worn, bevel: 0.002)
        }
        // Braces: platform back corner to the ladder rails.
        for s: Float in [-1, 1] {
            HuntCampKit.bar(&m, V3(s * (halfW - 0.04), fy - 0.02, backZ + 0.05), V3(s * lw, 3.2, railZ(3.2)), w: 0.035, t: 0.03, up: V3(1, 0, 0), mat: frame)
            HuntCampKit.bar(&m, V3(s * lw, 3.2, railZ(3.2)), V3(s * lw, 3.2, railZ(3.2)) + V3(s * 0.01, 0, 0), w: 0.06, t: 0.04, mat: worn)
        }
        // Posts and padded rails: front posts, side rails running back, padded front rail.
        let rt = H + railHeight
        for s: Float in [-1, 1] {
            let px = s * (halfW - 0.02)
            HuntCampKit.rod(&m, V3(px, H, frontZ - 0.02), V3(px, rt, frontZ - 0.02), r: 0.0165, sides: 10, mat: frame)
            let side = [V3(px, rt, frontZ - 0.02), V3(px, rt - 0.01, frontZ - 0.30), V3(px, rt - 0.02, backZ + 0.12), V3(px, rt - 0.12, backZ + 0.03), V3(px, H + 0.2, backZ + 0.02)]
            m.add(Prim.tube(catmull(side, per: 4), radii: catmull(side, per: 4).map { _ in 0.0165 }, sides: 10, seamTile: 0.1, material: frame, capEnd: true))
            HuntCampKit.rod(&m, V3(px, rt - 0.015, frontZ - 0.05), V3(px, rt - 0.02, backZ + 0.15), r: 0.027, sides: 12, mat: pad, seamTile: 0.12)
        }
        HuntCampKit.rod(&m, V3(-halfW + 0.02, rt, frontZ - 0.02), V3(halfW - 0.02, rt, frontZ - 0.02), r: 0.0165, sides: 10, mat: frame)
        HuntCampKit.rod(&m, V3(-halfW + 0.05, rt + 0.005, frontZ - 0.02), V3(halfW - 0.05, rt + 0.005, frontZ - 0.02), r: 0.032, sides: 12, mat: pad, seamTile: 0.12)
        // Mid rail for the flip-up gate and a hinge pin.
        HuntCampKit.rod(&m, V3(-halfW + 0.02, H + 0.40, frontZ - 0.02), V3(halfW - 0.02, H + 0.40, frontZ - 0.02), r: 0.012, sides: 8, mat: frame)
        // Seat: side supports, cushion, mesh back with padded top.
        let seatY = H + 0.46
        for s: Float in [-1, 1] {
            let px = s * 0.205
            HuntCampKit.rod(&m, V3(px, H, backZ + 0.07), V3(px, seatY, backZ + 0.07), r: 0.013, mat: frame)
            HuntCampKit.rod(&m, V3(px, H, backZ + 0.40), V3(px, seatY - 0.01, backZ + 0.38), r: 0.013, mat: frame)
            HuntCampKit.rod(&m, V3(px, seatY - 0.01, backZ + 0.38), V3(px, seatY, backZ + 0.07), r: 0.013, mat: frame)
            HuntCampKit.rod(&m, V3(px, seatY, backZ + 0.07), V3(px * 1.06, seatY + 0.46, backZ + 0.0), r: 0.013, mat: frame)
        }
        m.add(Prim.superellipsoid(V3(0.46, 0.065, 0.40), exponent: 5, subdivisions: 8, material: "fabric.nylon:2F382A"),
              Xform(translation: V3(0, seatY + 0.035, backZ + 0.23)))
        m.add(Prim.superellipsoid(V3(0.42, 0.40, 0.03), exponent: 8, subdivisions: 6, material: "fabric.mesh:2A3326"),
              Xform(translation: V3(0, seatY + 0.26, backZ + 0.05), rotation: simd_quatf(degrees: -8, axis: V3(1, 0, 0))))
        m.add(Prim.superellipsoid(V3(0.46, 0.07, 0.06), exponent: 4, subdivisions: 6, material: "fabric.nylon:2F382A"),
              Xform(translation: V3(0, seatY + 0.48, backZ + 0.03)))
        // Ratchet strap: buckle on the notch bar, webbing hanging in a loop with a tail.
        let sx: Float = 0.27
        m.add(Prim.roundedBox(V3(0.07, 0.03, 0.045), radius: 0.006, bevelSegments: 1, material: worn), Xform(translation: V3(sx, fy + 0.03, backZ - 0.03)))
        HuntCampKit.bar(&m, V3(sx + 0.03, fy + 0.03, backZ - 0.05), V3(sx + 0.05, fy + 0.07, backZ - 0.09), w: 0.012, t: 0.004, mat: worn, bevel: 0.001)
        let strap = catmull([V3(sx, fy + 0.03, backZ - 0.05), V3(sx - 0.06, fy - 0.08, backZ - 0.14), V3(sx - 0.14, fy - 0.2, backZ - 0.22), V3(sx - 0.2, fy - 0.36, backZ - 0.2), V3(sx - 0.21, fy - 0.5, backZ - 0.16)], per: 4)
        m.add(Prim.sweep(Shape2D.rect(0.004, 0.036), along: strap, up: V3(1, 0, 0), material: "fabric.webbing:3A4430"))
        // Haul line with a bow hook on the right side rail.
        let hookTop = V3(halfW - 0.005, rt - 0.12, frontZ - 0.40)
        let haul = catmull([hookTop, hookTop + V3(0.06, -0.3, 0.0), hookTop + V3(0.14, -0.8, 0.04), hookTop + V3(0.16, -1.4, 0.0), hookTop + V3(0.1, -1.8, -0.04)], per: 5)
        m.add(Prim.tube(haul, radii: haul.map { _ in 0.0035 }, sides: 6, seamTile: 0.03, material: "fabric.webbing:7A6A48"))
        m.add(Prim.torus(major: 0.016, minor: 0.0035, segments: 14, sides: 6, arc: 4.4, material: worn), Xform(translation: hookTop, rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        // Hex bolts at the platform frame corners.
        for s: Float in [-1, 1] {
            hexBolt(&m, at: V3(s * halfW, fy, frontZ + 0.001), normal: V3(0, 0, 1), size: 0.012, material: "metal.screw-zinc")
            hexBolt(&m, at: V3(s * halfW, fy + 0.017, frontZ - 0.3), normal: V3(0, 1, 0), size: 0.012, material: "metal.screw-zinc")
        }
        _ = rng.float()

        let b = m.bounds
        m = m.transformed(Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2)))
        groundAO(&m, height: 0.4, floor: 0.7)
        return LODModel(m)
    }
}
