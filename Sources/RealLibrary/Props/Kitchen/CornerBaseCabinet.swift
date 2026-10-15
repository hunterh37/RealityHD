import simd
import Foundation

/// L-shaped blind corner base cabinet, 36 in legs on 24 in deep boxes: the wall corner sits at back left
/// (-X, -Z) and the 12 in notch at front right (x and z from 0.15 to 0.45) is the open inner corner of
/// the run. Painted five-piece shaker doors with brushed-nickel bar pulls face +Z and +X inside the
/// notch, the carcass stands on a recessed toe kick and carries an L-shaped quartz top with eased
/// edges and a 20 mm overhang past the door faces.
public struct CornerBaseCabinet: RealAsset {
    public static let id = "corner-base-cabinet"
    public static let summary = "L-shaped blind corner base cabinet, 36 in legs: painted shaker doors on both inner faces, nickel pulls, quartz L top, toe kick."
    public static let tags = ["prop", "floorplan", "kitchen", "furniture", "wood", "stone", "metal", "interior"]
    public static let budget = 8000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 38, elevation: 22, distance: 2.0, studio: true)

    /// Overall size in meters (x, y, z); the L spans x and z.
    public var size = V3(0.9, 0.9, 0.9)
    /// Leg depth (the 24 in box plus overhang).
    public var legDepth: Float = 0.6
    public var topThickness: Float = 0.03
    /// Paint tint (sRGB hex): sage 0xA3AD98, white 0xE9E6DD, navy 0x34404F.
    public var color: UInt32 = 0xA3AD98
    public var top: MaterialKey = "stone.quartz"
    public var hardware: MaterialKey = "metal.brushed-nickel"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let W = size.x, Dp = size.z, H = size.y
        let paint: MaterialKey = "wood.painted-shaker:" + String(format: "%06X", color)
        let dark: MaterialKey = "plastic.matte:1C1C1E"
        let kick: Float = 0.1, recess: Float = 0.07
        let doorT: Float = 0.019, reveal: Float = 0.003, over: Float = 0.02, side: Float = 0.018
        let pullOut: Float = 0.032
        let x0 = -W / 2, z0 = -Dp / 2, x1 = W / 2, z1 = Dp / 2
        let nx = x1 - (W - legDepth), nz = z1 - (Dp - legDepth)     // notch corner: 0.15, 0.15
        let faceA = nz - over, faceB = nx - over                  // door faces
        let boxTop = H - topThickness

        func level(_ hi: Bool) -> Model {
            var m = Model(name: Self.id)
            func box(_ lo: V3, _ hiP: V3, _ mat: MaterialKey, r: Float = 0.002) {
                let s = hiP - lo
                m.add(r <= 0.0025 && !hi ? cuboid(s, material: mat) : Prim.roundedBox(s, radius: r, bevelSegments: 1, material: mat), Xform(translation: (lo + hiP) / 2))
            }
            // Carcass, two legs. Back leg along -Z wall, left leg along -X wall.
            let aFront = faceA - doorT, bFront = faceB - doorT
            box(V3(x0, kick, z0), V3(x1, boxTop, z0 + side), paint)                    // back panel
            box(V3(x0, kick, z0), V3(x0 + side, boxTop, z1), paint)                    // left panel
            box(V3(x1 - side, kick, z0), V3(x1, boxTop, aFront), paint)                // right end of back leg
            box(V3(x0, kick, z1 - side), V3(bFront, boxTop, z1), paint)                // front end of left leg
            box(V3(x0, kick, z0), V3(x1, kick + side, aFront), "wood.plywood")          // bottom, back leg
            box(V3(x0, kick, aFront), V3(bFront, kick + side, z1), "wood.plywood")      // bottom, left leg
            box(V3(x0, boxTop - side, z0), V3(x1, boxTop, aFront), paint)      // top rail
            box(V3(x0, boxTop - side, aFront), V3(bFront, boxTop, z1), paint)
            // Inner partition behind the notch faces, and dark void inside.
            box(V3(nx - 0.2 + 0.0, kick + side, z0 + side), V3(nx - 0.2 + 0.004, boxTop - side, aFront), "wood.plywood")
            m.add(cuboid(V3(W - 0.12, boxTop - kick - 2 * side, aFront - z0 - side - 0.01), material: dark).flipped(),
                  Xform(translation: V3(0.06, (kick + boxTop) / 2, (z0 + side + aFront - 0.01) / 2)))
            m.add(cuboid(V3(bFront - x0 - side - 0.01, boxTop - kick - 2 * side, z1 - aFront - 0.04), material: dark).flipped(),
                  Xform(translation: V3((x0 + side + bFront - 0.01) / 2, (kick + boxTop) / 2, (aFront + z1 - 0.04) / 2 + 0.02)))
            // Toe kick, recessed, following the L.
            box(V3(x0, 0, aFront - recess), V3(x1, kick, aFront - recess + 0.018), dark)
            box(V3(bFront - recess, 0, aFront - recess), V3(bFront - recess + 0.018, kick, z1), dark)
            box(V3(x0, 0, z1 - 0.018 - 0.0), V3(bFront - recess + 0.018, kick, z1), dark)
            box(V3(x0, 0, z0), V3(x0 + 0.018, kick, z1), dark)
            box(V3(x0, 0, z0), V3(x1, kick, z0 + 0.018), dark)
            box(V3(x1 - 0.018, 0, z0), V3(x1, kick, aFront - recess + 0.018), dark)

            // Doors. A faces +Z on the back leg (x from nx to x1), B faces +X on the left leg (z from nz to z1).
            func door(center: V3, along: V3, width: Float, normal: V3, pullAlongX: Bool) {
                let lo = kick + reveal, hiY = boxTop - reveal, dh = hiY - lo
                let st: Float = 0.055
                let c = V3(center.x, (lo + hiY) / 2 + (hi ? rng.float(-0.0005...0.0005) : 0), center.z)
                let rot = simd_quatf(from: V3(0, 0, 1), to: normal)
                func piece(_ s: V3, _ off: V3, _ mat: MaterialKey, r: Float = 0.0025) {
                    let p = Prim.roundedBox(s, radius: r, bevelSegments: 1, material: mat)
                    m.add(p, Xform(translation: c + rot.act(off), rotation: rot))
                }
                for e: Float in [-1, 1] { piece(V3(st, dh, doorT), V3(e * (width / 2 - st / 2), 0, -doorT / 2 + 0.0), paint) }
                for e: Float in [-1, 1] { piece(V3(width - 2 * st + 0.002, st, doorT), V3(0, e * (dh / 2 - st / 2), -doorT / 2), paint) }
                m.add(cuboid(V3(width - 2 * st + 0.004, dh - 2 * st + 0.004, 0.008), material: paint), Xform(translation: c + rot.act(V3(0, 0, -doorT + 0.004)), rotation: rot))
                if hi {
                    let bw = width - 2 * st + 0.004, bh = dh - 2 * st + 0.004
                    for e: Float in [-1, 1] {
                        m.add(cuboid(V3(bw, 0.003, 0.003), material: paint), Xform(translation: c + rot.act(V3(0, e * (bh / 2 - 0.0015), -doorT + 0.0095)), rotation: rot))
                        m.add(cuboid(V3(0.003, bh, 0.003), material: paint), Xform(translation: c + rot.act(V3(e * (bw / 2 - 0.0015), 0, -doorT + 0.0095)), rotation: rot))
                    }
                }
                // Vertical bar pull near the outer top corner (toward the run end), 0.128 m.
                let px = width / 2 - 0.03
                var pull = barHandle(length: 0.128, standoff: pullOut, radius: 0.0045, overhang: 0.014, material: hardware)
                pull = pull.transformed(Xform(translation: V3(-px * 0, 0, 0), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
                if hi {
                    m.add(pull, Xform(translation: c + rot.act(V3(-px * (pullAlongX ? 1 : -1) * 0 + (pullAlongX ? -px : px), dh / 2 - 0.1, 0)), rotation: rot))
                } else {
                    m.add(cuboid(V3(0.01, 0.17, 0.01), material: hardware), Xform(translation: c + rot.act(V3(pullAlongX ? -px : px, dh / 2 - 0.1, pullOut)), rotation: rot))
                }
            }
            let wA = x1 - nx - 2 * reveal
            door(center: V3(nx + (x1 - nx) / 2, 0, faceA), along: V3(1, 0, 0), width: wA, normal: V3(0, 0, 1), pullAlongX: true)
            let wB = z1 - nz - 2 * reveal
            door(center: V3(faceB, 0, nz + (z1 - nz) / 2), along: V3(0, 0, 1), width: wB, normal: V3(1, 0, 0), pullAlongX: false)

            // L-shaped quartz top, 30 mm, corners eased.
            let outline: [V2] = [V2(x0, z0), V2(x1, z0), V2(x1, nz), V2(nx, nz), V2(nx, z1), V2(x0, z1)]
            let rounded = Shape2D.rounded(outline, radius: 0.012, segments: hi ? 4 : 2)
            var slab = Prim.extrude(rounded, depth: topThickness, bevel: 0.004, bevelSegments: hi ? 2 : 1, material: top)
            slab = slab.transformed(Xform(rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            m.add(slab, Xform(translation: V3(0, H - topThickness / 2, 0)))
            groundAO(&m, height: 0.15, floor: 0.7)
            return m
        }
        return LODModel(levels: [level(true), level(false)], switchDistances: [5])
    }
}
