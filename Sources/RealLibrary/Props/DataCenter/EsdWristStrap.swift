import simd
import Foundation

/// ESD wrist strap: Anti-static wrist strap lying on a bench: black woven elastic band loop with silver thread stripe, steel contact plate and snap, coiled black cord, red/black insulated alligator clip. Parts: black elastic woven band loop with metal thread, steel contact plate, 10 mm snap, coiled black cord about 10 turns, red and black alligator clip.
public struct EsdWristStrap: RealAsset {
    public static let id = "esd-wrist-strap"
    public static let summary = "Anti-static wrist strap with elastic band, steel snap, coiled cord and alligator clip."
    public static let tags = ["prop", "handheld"]
    public static let budget = 1500
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.08, 0.02, 0.3)
    /// Band centerline half extents in meters (x, z) of the wrist loop.
    public var loopHalf = V2(0.038, 0.033)
    /// Band width in meters.
    public var bandWidth: Float = 0.015
    /// Coil turns in the cord.
    public var turns: Float = 10
    /// Band material.
    public var band: MaterialKey = "fabric.webbing:1A1A1A"
    /// Cord and sleeve material.
    public var cord: MaterialKey = "rubber.insulating-black:141414"
    /// Metal parts.
    public var metal: MaterialKey = "metal.steel"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let cy = bandWidth / 2
        let lcz: Float = size.z / 2 - loopHalf.y - 0.0015 // loop centre z
        let cz = lcz
        let snapZ = cz - loopHalf.y
        // z-axis cylinder from z0 extending dz (sign picks direction).
        func zcyl(_ r: Float, _ x: Float, _ y: Float, _ z0: Float, _ dz: Float, mat: MaterialKey, seg: Int = 8) {
            m.add(Prim.cylinder(radius: r, height: abs(dz), bevel: 0.0003, segments: seg, bevelSegments: 1, topBevel: false, bottomBevel: false, material: mat),
                  Xform(translation: V3(x, y, z0), rotation: simd_quatf(degrees: dz > 0 ? 90 : -90, axis: V3(1, 0, 0))))
        }
        func flat(_ s: V3, _ c: V3, rot: Float = 0, mat: MaterialKey) {
            m.add(cuboid(s, material: mat), Xform(translation: c, rotation: simd_quatf(degrees: rot, axis: V3(1, 0, 0))))
        }
        func box(_ s: V3, _ c: V3, r: Float = 0.0008, rot: Float = 0, mat: MaterialKey) {
            m.add(Prim.roundedBox(s, radius: min(r, min(s.x, min(s.y, s.z)) * 0.4), bevelSegments: 1, material: mat),
                  Xform(translation: c, rotation: simd_quatf(degrees: rot, axis: V3(1, 0, 0))))
        }
        // Elastic band: closed ellipse lying flat, width along y. Seam overlap at the +z end.
        let n = 20
        let loop: [V3] = (0..<n).map { k in
            let a = Float(k) / Float(n) * 2 * .pi
            return V3(cos(a) * loopHalf.x, cy, cz + sin(a) * loopHalf.y)
        }
        let prof = Shape2D.rect(bandWidth, 0.0022)
        m.add(Prim.sweep(prof, along: loop, up: V3(0, 1, 0), closedPath: true, caps: false, material: band))
        // Metal thread stripes: two thin raised bands near the edges.
        for off: Float in [0.0] {
            let pr = Shape2D.rect(0.0016, 0.0027).map { V2($0.x + off, $0.y) }
            m.add(Prim.sweep(pr, along: loop, up: V3(0, 1, 0), closedPath: true, caps: false, material: "metal.aluminum-brushed"))
        }
        // Stitched seam patch on the +z side.
        flat(V3(0.016, bandWidth + 0.0006, 0.0034), V3(0, cy, cz + loopHalf.y), mat: band)
        // Contact plate on the inside of the loop at the snap, rim, and snap stud outside.
        zcyl(0.0095, 0, cy, snapZ + 0.0011, 0.0016, mat: metal, seg: 12)
        zcyl(0.0050, 0, cy, snapZ - 0.0011, -0.0052, mat: metal, seg: 8)
        // Female snap socket and black sleeve on the cord end.
        let sockZ = snapZ - 0.0065
        zcyl(0.0068, 0, cy, sockZ, -0.0075, mat: metal, seg: 12)
        zcyl(0.0072, 0, cy, sockZ - 0.0040, -0.0062, mat: cord, seg: 8)
        // Cord: straight lead to the snap, coil of `turns`, straight lead to the clip.
        let coilR: Float = 0.0038, wire: Float = 0.0012
        let pitch: Float = 0.0118
        let coilLen = pitch * turns
        let coilEnd = sockZ - 0.0110 - 0.012
        let coilStart = coilEnd - coilLen
        let lead1 = (0..<4).map { k in V3(0, cy, sockZ - 0.0090 - Float(k) * (coilEnd - (sockZ - 0.0090)) / 3) }
        m.add(Prim.tube(lead1, radii: [Float](repeating: 0.0016, count: 4), sides: 6, seamTile: 0.02, material: cord))
        m.add(Prim.helix(radius: coilR, pitch: pitch, turns: turns, wire: wire, perTurn: 7, sides: 3, material: cord),
              Xform(translation: V3(0, cy, coilStart + wire), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        let clipTail = coilStart - 0.016
        let lead2 = (0..<3).map { k in V3(0, cy, coilStart - Float(k) * 0.008) }
        m.add(Prim.tube(lead2, radii: [Float](repeating: 0.0016, count: 3), sides: 6, seamTile: 0.02, material: cord))
        // Alligator clip: red and black insulated boots, steel jaws with teeth, pivot rivet.
        let bootL: Float = 0.026
        let bz = clipTail - bootL / 2 + 0.002
        box(V3(0.0115, 0.0062, bootL), V3(0, cy + 0.0033, bz), r: 0.0016, mat: "rubber.insulating-red")
        box(V3(0.0115, 0.0062, bootL), V3(0, cy - 0.0033, bz), r: 0.0016, mat: "rubber.insulating-black")
        let jawZ = clipTail - bootL + 0.002
        let jawL: Float = 0.021
        for (sgn, ang) in [(Float(1), Float(-4)), (Float(-1), Float(4))] {
            flat(V3(0.0080, 0.0022, jawL), V3(0, cy + sgn * 0.0027, jawZ - jawL / 2 + 0.002), rot: ang * sgn, mat: metal)
            for k in 0..<3 {
                flat(V3(0.0075, 0.0011, 0.0016), V3(0, cy + sgn * 0.0015, jawZ - 0.002 - Float(k) * 0.006), mat: "metal.steel")
            }
        }
        // Wear: faint worn tooth and a sweat-darkened patch on the band inside.
        let wz = cz - loopHalf.y * 0.4
        flat(V3(0.012, bandWidth * 0.7, 0.0004), V3(-0.011, cy, wz), mat: "fabric.webbing:0E0E0E")
        _ = rng.next()
        // Shift so the bounds sit at y = 0 and the object is centred on z.
        groundAO(&m)
        return LODModel(m)
    }
}
