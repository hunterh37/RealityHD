import simd
import Foundation

/// Parameters for a hexagonal-transfer-chamber cluster tool (etch, CVD/ALD, PVD). Angles are degrees in the XZ plane
/// measured from +X toward +Z, so 90 faces the EFEM at the front. Props pick chamber count, materials and lid parts.
public struct ClusterSpec {
    public var chamberAngles: [Float] = [0, 180, -60, -120]
    public var loadLockAngles: [Float] = [60, 120]
    public var lidPrefix = "lid"
    public var hexApothem: Float = 0.6
    public var hexCenterZ: Float = -0.15
    public var chamberRadius: Float = 0.46
    public var chamberBase: Float = 0.82
    public var chamberHeight: Float = 0.4
    public var chamberMat: MaterialKey = "metal.satin-aluminum"
    public var lidMat: MaterialKey = "metal.satin-aluminum"
    public var frameMat: MaterialKey = "metal.powdercoat:34373C"
    public var skinMat: MaterialKey = "metal.powdercoat:EDEDE9"
    public var matchBoxes = true
    public var gasSticks = 6
    public var portX: [Float] = [-0.9, 0, 0.9]
    public var efemZ: ClosedRange<Float> = 1.0...1.6
    public var efemWidth: Float = 3.0
    public var efemHeight: Float = 2.05
    /// Per-chamber extras hook (lid hardware, ampoule cabinets, pumps). Args: kit, chamber centre, outward dir, tangent, lid top y, lid part name, index.
    public var chamberExtra: ((ClusterKit, V3, V3, V3, Float, String, Int) -> Void)? = nil
    public init() {}
}

/// Geometry sink shared by cluster builders: one Model per LOD plus named rig parts.
public final class ClusterKit {
    public var rig: Rig
    public var m: Model
    public let hi: Bool
    let lod: Int
    public init(rig: Rig, lod: Int) {
        self.rig = rig; self.lod = lod; hi = lod == 0; m = Model(name: rig.name)
    }
    public func put(_ s: Surface, _ x: Xform, _ name: String? = nil) {
        if let n = name { rig.add(s, x, to: n, lods: lod...lod) } else { m.add(s, x) }
    }
    public func bx(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.004, yaw: Float = 0, name: String? = nil) {
        let surf = r > 0.003 && s.min() > 0.12
            ? Prim.extrude(Shape2D.rect(s.x, s.y), depth: s.z, bevel: min(r, s.min() * 0.4), bevelSegments: 1, material: mat)
            : cuboid(s, material: mat)
        put(surf, Xform(translation: c, rotation: simd_quatf(degrees: yaw, axis: V3(0, 1, 0))), name)
    }
    public func cyl(_ r: Float, _ h: Float, _ c: V3, _ mat: MaterialKey, seg: Int = 16, name: String? = nil) {
        put(Prim.cylinder(radius: r, height: h, bevel: 0, segments: hi ? seg : max(5, seg / 2), material: mat), Xform(translation: c), name)
    }
    public func tube(_ pts: [V3], _ r: Float, _ mat: MaterialKey, sides: Int = 8) {
        m.add(Prim.tube(pts, radii: Array(repeating: r, count: pts.count), sides: hi ? sides : 4, seamTile: 0.25, material: mat), .identity)
    }
}

public enum ClusterTool {
    static func dir(_ a: Float) -> V3 { V3(cos(a * .pi / 180), 0, sin(a * .pi / 180)) }
    static func tang(_ a: Float) -> V3 { V3(-sin(a * .pi / 180), 0, cos(a * .pi / 180)) }

    /// Chamber centre for a face angle.
    public static func chamberCenter(_ s: ClusterSpec, _ a: Float) -> V3 {
        V3(0, 0, s.hexCenterZ) + dir(a) * (s.hexApothem + 0.1 + s.chamberRadius)
    }

    /// Declares the hinged lids (pivot at the outer rim, tangent axis).
    public static func declareParts(_ rig: inout Rig, _ s: ClusterSpec) {
        for (i, a) in s.chamberAngles.enumerated() {
            let c = chamberCenter(s, a)
            let top = s.chamberBase + s.chamberHeight
            let pivot = c + dir(a) * (s.chamberRadius + 0.04) + V3(0, top, 0)
            let t = tang(a)
            rig.part("\(s.lidPrefix)-\(i + 1)", pivot: pivot, joint: .hinge(axis: t, -105...0, duration: 1.4))
        }
    }

    /// Builds one LOD of the cluster: plinth, transfer chamber, load locks, chambers, gas sticks, cables, EFEM.
    public static func assemble(_ k: ClusterKit, _ s: ClusterSpec, status: V3) {
        let hi = k.hi
        let steel: MaterialKey = "metal.stainless", anod: MaterialKey = "metal.anodized"
        let black: MaterialKey = "plastic.matte:1E2023"
        let frame = s.frameMat, skin = s.skinMat
        let y0: Float = 0.12, cz = s.hexCenterZ, a0 = s.hexApothem
        let yb = s.chamberBase
        let ezf = s.efemZ.upperBound, ezb = s.efemZ.lowerBound
        let ew = s.efemWidth, eh = s.efemHeight

        // Cleanroom grate floor and central plinth.
        k.m.add(Prim.extrude(Shape2D.rect(4.0, 4.0), depth: 0.05, bevel: 0.004, bevelSegments: 1, material: "metal.grate-iron"),
                Xform(translation: V3(0, 0.025, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))

        // Transfer chamber: hex body, lid ring, viewport, robot motor cap.
        let R = a0 / cos(Float.pi / 6)
        func hex(_ r: Float) -> [V2] { (0..<6).map { let t = (30 + Float($0) * 60) * Float.pi / 180; return V2(r * cos(t), r * sin(t)) } }
        func hexPrism(_ r: Float, _ y0: Float, _ y1: Float, _ mat: MaterialKey, bevel: Float = 0.006) {
            k.put(Prim.extrude(hex(r), depth: y1 - y0, bevel: bevel, bevelSegments: 1, material: mat),
                  Xform(translation: V3(0, (y0 + y1) / 2, cz), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }
        hexPrism(R - 0.04, y0, yb, frame)
        hexPrism(R, yb, yb + 0.36, s.chamberMat)
        hexPrism(R + 0.012, yb + 0.36, yb + 0.4, anod)
        hexPrism(R - 0.03, yb + 0.4, yb + 0.46, s.lidMat)
        hexPrism(R - 0.2, yb + 0.46, yb + 0.5, anod)
        k.cyl(0.13, 0.12, V3(0, yb + 0.5, cz), anod, seg: 20)
        k.cyl(0.085, 0.08, V3(0, yb + 0.62, cz), "glass.window-tint", seg: 16)
        k.cyl(0.1, 0.02, V3(0, yb + 0.7, cz), steel, seg: 16)
        for i in 0..<6 where hi {
            let t = (Float(i) * 60 + 20) * Float.pi / 180
            k.cyl(0.011, 0.014, V3(0.31 * cos(t), yb + 0.5, cz + 0.31 * sin(t)), steel, seg: 6)
        }
        // Ion gauge and pump-out tee on the transfer lid.
        k.cyl(0.03, 0.15, V3(0.25, yb + 0.5, cz - 0.15), steel, seg: 10)
        k.cyl(0.04, 0.03, V3(0.25, yb + 0.65, cz - 0.15), black, seg: 10)

        // Process chambers.
        for (i, a) in s.chamberAngles.enumerated() {
            let c = chamberCenter(s, a), d = dir(a), t = tang(a), rc = s.chamberRadius
            let top = yb + s.chamberHeight
            // Slit valve housing between hex face and chamber.
            let sv = V3(0, 0, cz) + d * (a0 + 0.06)
            k.bx(V3(0.46, 0.34, 0.12), V3(sv.x, yb + 0.2, sv.z), anod, r: 0.004, yaw: 90 - a)
            k.bx(V3(0.5, 0.05, 0.14), V3(sv.x, yb + 0.4, sv.z), steel, r: 0.003, yaw: 90 - a)
            // Pedestal, body and flange rings.
            k.bx(V3(rc * 1.9, yb - y0, rc * 1.9), V3(c.x, (yb + y0) / 2, c.z), frame, r: 0.006, yaw: 90 - a)
            let body: [V2] = [V2(0, yb), V2(rc + 0.01, yb), V2(rc + 0.01, yb + 0.05), V2(rc - 0.01, yb + 0.07), V2(rc - 0.01, top - 0.09),
                              V2(rc + 0.03, top - 0.07), V2(rc + 0.03, top - 0.02), V2(rc + 0.04, top - 0.02), V2(rc + 0.04, top), V2(0, top)]
            k.put(Prim.lathe(body, segments: hi ? 16 : 8, seamTile: 0.45, material: s.chamberMat), Xform(translation: V3(c.x, 0, c.z)))
            if hi {
                for j in 0..<8 {
                    let q = Float(j) / 8 * 2 * .pi
                    k.cyl(0.009, 0.012, V3(c.x + (rc + 0.02) * cos(q), top - 0.05 + 0.0, c.z + (rc + 0.02) * sin(q)), steel, seg: 6)
                }
                // Heater jacket stripes and service port with blank flange.
                k.bx(V3(0.1, 0.1, 0.05), c + d * (rc + 0.03) + t * 0.15 + V3(0, yb + 0.22 - c.y, 0), anod, r: 0.003, yaw: 90 - a)
                k.cyl(0.04, 0.03, c + t * -0.18 + d * (rc * 0.98) + V3(0, yb + 0.15, 0), steel, seg: 10)
            }
            k.cyl(rc + 0.02, 0.03, V3(c.x, yb + 0.12, c.z), anod, seg: hi ? 16 : 8)
            // Quarter-turn latches around the flange.
            for j in 0..<4 where hi {
                let q = (Float(j) * 90 + 45) * Float.pi / 180
                k.bx(V3(0.05, 0.05, 0.03), V3(c.x + (rc + 0.05) * cos(q), top - 0.04, c.z + (rc + 0.05) * sin(q)), steel, r: 0.002, yaw: 90 - Float(j) * 90 - 45)
            }
            // Lid (named): disc, rim, hinge knuckles, handle, match box, RF strap.
            let ln = "\(s.lidPrefix)-\(i + 1)"
            let lid: [V2] = [V2(0, 0.0), V2(rc + 0.04, 0.0), V2(rc + 0.04, 0.045), V2(rc, 0.06), V2(0.22, 0.075), V2(0.2, 0.11), V2(0, 0.11)]
            k.put(Prim.lathe(lid, segments: hi ? 16 : 8, seamTile: 0.45, material: s.lidMat), Xform(translation: V3(c.x, top + 0.0015, c.z)), ln)
            let outer = c + d * (rc + 0.04)
            for q: Float in [-1, 1] {
                k.bx(V3(0.06, 0.05, 0.05), V3(outer.x + t.x * q * 0.18, top + 0.03, outer.z + t.z * q * 0.18), steel, r: 0.002, yaw: 90 - a, name: ln)
            }
            k.bx(V3(0.2, 0.03, 0.03), V3(c.x - d.x * (rc - 0.03), top + 0.1, c.z - d.z * (rc - 0.03)), steel, r: 0.002, yaw: 90 - a, name: ln)
            if s.matchBoxes {
                let mc = c + d * 0.06
                k.put(cuboid(V3(0.34, 0.26, 0.3), material: "metal.powdercoat:C9CBCC").rotated(yaw: 90 - a), Xform(translation: V3(mc.x, top + 0.24, mc.z)), ln)
                k.put(cuboid(V3(0.36, 0.03, 0.32), material: steel).rotated(yaw: 90 - a), Xform(translation: V3(mc.x, top + 0.375, mc.z)), ln)
                k.put(cuboid(V3(0.2, 0.08, 0.01), material: black).rotated(yaw: 90 - a), Xform(translation: V3(mc.x + d.x * 0.151, top + 0.26, mc.z + d.z * 0.151)), ln)
                k.put(Prim.cylinder(radius: 0.035, height: 0.12, bevel: 0, segments: hi ? 14 : 6, material: "metal.anodized"), Xform(translation: V3(mc.x, top + 0.39, mc.z)), ln)
                k.put(Prim.cylinder(radius: 0.05, height: 0.14, bevel: 0, segments: hi ? 16 : 6, material: steel), Xform(translation: V3(c.x, top + 0.11, c.z)), ln)
                if hi {
                    for q: Float in [-1, 1] {
                        k.put(Prim.cylinder(radius: 0.012, height: 0.05, bevel: 0, segments: 8, material: "metal.brass"),
                              Xform(translation: V3(mc.x - d.x * 0.0 + t.x * q * 0.09, top + 0.5, mc.z + t.z * q * 0.09)), ln)
                    }
                }
            }
            // Gas tray beyond the outer rim: posts, tray, stainless sticks with valves and MFCs.
            let gc = c + d * (rc + 0.2)
            let gy = top + 0.16
            for q: Float in [-1, 1] { for w: Float in [0, 1] {
                let p = gc + t * q * 0.27 + d * (w * 0.2 - 0.1)
                k.bx(V3(0.04, gy - y0, 0.04), V3(p.x, (gy + y0) / 2, p.z), skin, r: 0.001)
            } }
            k.bx(V3(0.6, 0.03, 0.34), V3(gc.x, gy, gc.z), "metal.powdercoat:9EA3A8", r: 0.002, yaw: 90 - a)
            let n = s.gasSticks
            for j in 0..<n {
                let off = (Float(j) - Float(n - 1) / 2) * 0.05
                let a1 = gc + d * off + t * -0.26 + V3(0, 0.03, 0), a2 = gc + d * off + t * 0.26 + V3(0, 0.03, 0)
                k.tube([a1, a2], 0.011, steel, sides: 6)
                if hi {
                    for v: Float in [-0.12, 0, 0.1] {
                        let p = gc + d * off + t * v + V3(0, 0.03, 0)
                        k.bx(V3(0.045, 0.07, 0.045), p + V3(0, 0.035, 0), steel, r: 0.001, yaw: 90 - a)
                    }
                    k.bx(V3(0.045, 0.14, 0.14), gc + d * off + t * 0.2 + V3(0, 0.1, 0), skin, r: 0.003, yaw: 90 - a)
                }
                // drop line from first stick end into the body
            }
            let st = gc + d * -0.05 + t * -0.26 + V3(0, 0.03, 0)
            k.tube([st, st + V3(0, 0.06, 0) + t * -0.04, c + d * (rc * 0.7) + t * -0.3 + V3(0, top - 0.02, 0)], 0.01, steel)
            // Cable bundle from match box to pedestal.
            if s.matchBoxes {
                let p0 = c + d * 0.06 + t * 0.17 + V3(0, top + 0.22, 0)
                let path = catmull([p0, p0 + t * 0.12 + V3(0, 0.02, 0), c + t * (rc + 0.12) + d * 0.1 + V3(0, top - 0.1, 0), c + t * (rc + 0.1) + V3(0, yb - 0.05, 0), c + t * (rc - 0.04) + V3(0, y0 + 0.05, 0)], per: hi ? 2 : 1)
                for (ci, cm) in ["plastic.matte:2A2C2F", "rubber.tubing", "plastic.matte:2A2C2F"].enumerated() {
                    k.tube(path.map { $0 + d * (Float(ci) - 1) * 0.022 }, 0.011, MaterialKey(stringLiteral: cm.description))
                }
            }
            // Foreline to the dry pump manifold below the hex plinth.
            k.tube([c + V3(0, y0 + 0.1, 0) - d * 0.02, V3(0, y0 + 0.1, cz) + d * (a0 + 0.1), V3(0, y0 + 0.1, cz)], 0.035, steel, sides: 8)
            s.chamberExtra?(k, c, d, t, top, ln, i)
            // Leveling feet.
            for q: Float in [-1, 1] { k.cyl(0.04, 0.015, V3(c.x + t.x * q * 0.3 + d.x * 0.3, 0.05, c.z + t.z * q * 0.3 + d.z * 0.3), steel, seg: 12) }
        }

        // Load locks.
        for a in s.loadLockAngles {
            let d = dir(a)
            let c = V3(0, 0, cz) + d * (a0 + 0.3)
            k.bx(V3(0.44, yb - y0, 0.5), V3(c.x, (yb + y0) / 2, c.z), frame, r: 0.004, yaw: 90 - a)
            k.bx(V3(0.44, 0.5, 0.5), V3(c.x, yb + 0.25, c.z), skin, r: 0.004, yaw: 90 - a)
            k.bx(V3(0.3, 0.2, 0.03), V3(c.x, yb + 0.3, c.z) + d * 0.255 + tang(a) * 0.0, "metal.powdercoat:1A1C1F", r: 0.002, yaw: 90 - a)
            k.bx(V3(0.46, 0.05, 0.52), V3(c.x, yb + 0.525, c.z), anod, r: 0.003, yaw: 90 - a)
            k.cyl(0.07, 0.02, V3(c.x, yb + 0.55, c.z), "glass.window-tint", seg: 14)
            if hi { k.bx(V3(0.2, 0.16, 0.012), V3(c.x - d.x * 0.0, yb + 0.28, c.z) + d * 0.255, "glass.window-tint", r: 0.002, yaw: 90 - a) }
            k.cyl(0.03, 0.2, V3(c.x, yb + 0.57, c.z) + tang(a) * 0.12, steel, seg: 10)
        }

        // EFEM: dark core, white skins, load ports with FOUPs, FFU, slot-line detail.
        let ec = (ezf + ezb) / 2, ed = ezf - ezb
        k.bx(V3(ew, eh - y0, ed), V3(0, (eh + y0) / 2, ec), frame, r: 0.005)
        let cols = 5, cw = ew / Float(cols)
        for ci in 0..<cols {
            let x = -ew / 2 + (Float(ci) + 0.5) * cw
            k.bx(V3(cw - 0.006, 0.55, 0.02), V3(x, y0 + 0.275, ezf + 0.008), skin, r: 0.003)
            k.bx(V3(cw - 0.006, 0.42, 0.02), V3(x, eh - 0.21, ezf + 0.008), skin, r: 0.003)
            for sx: Float in [-1, 1] { k.bx(V3(0.02, 0.5, 0.02), V3(x + sx * (cw / 2 - 0.01), 1.2, ezf + 0.005), skin, r: 0.001) }
        }
        for sx: Float in [-1, 1] {
            k.bx(V3(0.02, eh - y0 - 0.02, ed - 0.01), V3(sx * (ew / 2 + 0.008), (eh + y0) / 2, ec), skin, r: 0.004)
        }
        k.bx(V3(ew + 0.04, 0.04, ed + 0.04), V3(0, eh + 0.02, ec), skin, r: 0.004)
        let fy: Float = 0.98
        for px in s.portX {
            k.bx(V3(0.46, fy - y0, 0.3), V3(px, (fy + y0) / 2, ezf + 0.15), skin, r: 0.006)
            k.bx(V3(0.5, 0.03, 0.42), V3(px, fy - 0.015, ezf + 0.21), anod, r: 0.004)
            k.bx(V3(0.58, 0.66, 0.025), V3(px, fy + 0.33, ezf + 0.0125), frame, r: 0.004)
            k.bx(V3(0.38, 0.3, 0.01), V3(px, fy + 0.2, ezf + 0.03), "metal.powdercoat:1A1C1F", r: 0.002)
            k.bx(V3(0.06, 0.016, 0.006), V3(px + 0.22, fy + 0.58, ezf + 0.028), "glass.lamp:40E060", r: 0.001)
            k.bx(V3(0.06, 0.016, 0.006), V3(px - 0.22, fy + 0.58, ezf + 0.028), "glass.lamp:F0A020", r: 0.001)
            let zc = ezf + 0.19
            k.bx(V3(0.316, 0.29, 0.26), V3(px, fy + 0.162, zc + 0.01), "plastic.polycarbonate-tint", r: 0.004)
            k.bx(V3(0.33, 0.30, 0.012), V3(px, fy + 0.167, zc - 0.12), "plastic.matte:2A2C2F", r: 0.003)
            k.bx(V3(0.3, 0.012, 0.28), V3(px, fy + 0.011, zc), "plastic.matte:2A2C2F", r: 0.002)
            k.cyl(0.013, 0.03, V3(px, fy + 0.307, zc), "plastic.matte:3A3C40", seg: 12)
            k.bx(V3(0.19, 0.008, 0.09), V3(px, fy + 0.341, zc), "plastic.matte:3A3C40", r: 0.002)
            for sx: Float in [-1, 1] { k.bx(V3(0.012, 0.02, 0.1), V3(px + sx * 0.18, fy + 0.19, zc), "plastic.matte:3A3C40", r: 0.002) }
            if hi { for q in 0..<3 { k.bx(V3(0.29, 0.07, 0.26), V3(px, fy + 0.08 + Float(q) * 0.085, zc + 0.01), "silicon.thinfilm", r: 0) } }
        }
        k.bx(V3(ew - 0.2, 0.07, ed - 0.2), V3(0, eh + 0.075, ec), frame, r: 0.004)
        if hi { for q in 0..<10 { k.bx(V3(ew - 0.3, 0.01, 0.012), V3(0, eh + 0.115, ezb + 0.14 + Float(q) * 0.03), black, r: 0.0005) } }
        for fx: Float in [-1.3, 0, 1.3] {
            k.cyl(0.05, 0.018, V3(fx, 0.05, ezf - 0.05), steel, seg: 12)
            k.cyl(0.016, 0.055, V3(fx, 0.068, ezf - 0.05), steel, seg: 8)
        }
        // Status tower on the EFEM roof.
        let tx = status.x, tz = status.z, tb = eh + 0.11
        k.cyl(0.03, 0.02, V3(tx, tb, tz), anod, seg: 12)
        k.cyl(0.011, 0.14, V3(tx, tb + 0.02, tz), steel, seg: 8)
        for (q, col) in ["E03020", "F0A020", "30C050", "F4F8FF"].enumerated() {
            k.cyl(0.032, 0.05, V3(tx, tb + 0.16 + Float(q) * 0.052, tz), MaterialKey(stringLiteral: "glass.lamp:" + col), seg: 14)
        }
        k.cyl(0.03, 0.012, V3(tx, tb + 0.37, tz), black, seg: 12)

        // Story detail: hazard strip and equipment tag on the EFEM end, wear scuffs near ports.
        k.bx(V3(0.006, 0.06, 0.5), V3(ew / 2 + 0.02, 0.44, ec), "plastic.yellow", r: 0.0005)
        k.bx(V3(0.1, 0.06, 0.004), V3(1.3, 1.5, ezf + 0.02), "plastic.matte:EEEEEA", r: 0.0005)
        if hi {
            for px in s.portX { k.bx(V3(0.5, 0.16, 0.004), V3(px, 0.34, ezf + 0.02), "plastic.matte:C8C8C2", r: 0.0005) }
            // Roof cable tray over the transfer chamber with three runs.
            for q: Float in [-1, 1] { k.bx(V3(1.4, 0.05, 0.014), V3(0, 2.18, cz + q * 0.15), anod, r: 0.002) }
            for q in 0..<6 { k.bx(V3(0.014, 0.012, 0.32), V3(-0.65 + Float(q) * 0.26, 2.15, cz), anod, r: 0.001) }
        }
    }
}

extension Surface {
    /// Rotates positions and normals about +Y by `yaw` degrees (helper for cluster parts).
    func rotated(yaw: Float) -> Surface {
        if yaw == 0 { return self }
        return self.transformed(Xform(rotation: simd_quatf(degrees: yaw, axis: V3(0, 1, 0))))
    }
}
