import simd
import Foundation

/// Roadster launch ramp: 6.5 m wide cast concrete, 2 m flat apron, R6 m transition to 70 degrees, a short
/// straight, then an R22 m arc to 120 degrees (past vertical, overhanging the approach) at 26 m. Red LED edge
/// strips (#E23B4A emissive) and a white centerline. Local frame: origin at the apron start on the
/// floor, centered on X, the ramp climbs toward +Z. The driving surface is the concave (-Z) side.
public struct RoadsterRamp: RealAsset {
    public static let id = "roadster-ramp"
    public static let summary = "Roadster launch ramp: 6.5 m concrete, 2 m apron, R6 m transition to 70 degrees, R22 m arc to a 120 degree lip at 26 m, red LED edges, white centerline."
    public static let tags = ["structure", "concrete"]
    public static let budget = 30000
    public static let author = "realityhd"

    /// Ramp width in meters.
    public var width: Float = 6.5
    /// Slab thickness in meters (below the driving surface).
    public var thickness: Float = 0.4
    public init() {}

    /// Flat apron length in meters.
    public static let apron: Float = 2
    /// Radius of the base transition in meters.
    public static let radius: Float = 0.5
    /// Surface angle above horizontal at the end of the base transition, degrees.
    public static let wallDegrees: Float = 70
    /// Radius of the long upper arc in meters.
    public static let lipRadius: Float = 22
    /// Surface angle at the lip in degrees (past vertical, overhanging the approach).
    public static let lipDegrees: Float = 120
    /// Total height of the driving surface in meters.
    public static let totalHeight: Float = 26
    /// Height of the driving surface above the floor plane at the apron, meters (avoids coplanar z-fighting).
    public static let surfaceLift: Float = 0.01

    static var wallAngle: Float { wallDegrees * .pi / 180 }
    static var lipAngle: Float { lipDegrees * .pi / 180 }
    static var arcLen: Float { radius * wallAngle }
    /// Length of the straight run at the wall angle that makes up the remaining height.
    static var verticalHeight: Float {
        let rise = radius * (1 - cos(wallAngle)) + lipRadius * (cos(wallAngle) - cos(lipAngle))
        return (totalHeight - surfaceLift - rise) / sin(wallAngle)
    }
    static var upperArcLen: Float { lipRadius * (lipAngle - wallAngle) }
    /// Length of the centerline in meters.
    public static var arcLength: Float { apron + arcLen + verticalHeight + upperArcLen }

    /// Centerline of the driving surface at arc length `s` meters from the apron start (clamped to
    /// 0...arcLength): world position in ramp-local space and the unit direction of travel.
    public static func centerline(_ s: Float) -> (position: V3, tangent: V3) {
        let f = centerlineFrame(s)
        return (f.position, f.tangent)
    }

    /// Position, tangent and surface normal (toward the car side) at arc length `s`.
    public static func centerlineFrame(_ s: Float) -> (position: V3, tangent: V3, normal: V3) {
        let s = min(max(s, 0), arcLength)
        let L = surfaceLift
        let R = radius, R2 = lipRadius, a1 = wallAngle
        func frame(_ p: V3, _ a: Float) -> (position: V3, tangent: V3, normal: V3) {
            (p, V3(0, sin(a), cos(a)), V3(0, cos(a), -sin(a)))
        }
        if s <= apron { return frame(V3(0, L, s), 0) }
        var t = s - apron
        if t <= arcLen {
            let a = t / R
            return frame(V3(0, L + R * (1 - cos(a)), apron + R * sin(a)), a)
        }
        t -= arcLen
        let y1 = L + R * (1 - cos(a1)), z1 = apron + R * sin(a1)
        if t <= verticalHeight { return frame(V3(0, y1 + t * sin(a1), z1 + t * cos(a1)), a1) }
        t -= verticalHeight
        let y2 = y1 + verticalHeight * sin(a1), z2 = z1 + verticalHeight * cos(a1)
        let a = a1 + t / R2
        return frame(V3(0, y2 + R2 * (cos(a1) - cos(a)), z2 + R2 * (sin(a) - sin(a1))), a)
    }

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let n = Int(Self.arcLength / 0.35)
        var path: [V3] = []
        for i in 0...n { path.append(Self.centerline(Self.arcLength * Float(i) / Float(n)).position) }
        let w = width, T = thickness
        // Profile: x across the ramp, y along the surface normal (down into the slab is negative).
        let slab: [V2] = [V2(-w / 2, -T), V2(w / 2, -T), V2(w / 2, 0), V2(-w / 2, 0)]
        m.add(Prim.sweep(slab, along: path, up: V3(1, 0, 0), caps: true, material: "concrete.ramp-cast:8E918F"))
        func strip(_ x: Float, _ sw: Float, _ h: Float, _ mat: MaterialKey, under: Bool = false) -> Surface {
            let y0: Float = under ? -T : 0, y1: Float = under ? -T - h : h
            let p: [V2] = [V2(x - sw / 2, y0), V2(x + sw / 2, y0), V2(x + sw / 2, y1), V2(x - sw / 2, y1)]
            return Prim.sweep(p, along: path, up: V3(1, 0, 0), caps: true, material: mat)
        }
        for sx: Float in [-1, 1] { m.add(strip(sx * (w / 2 - 0.1), 0.14, 0.03, "emissive.led-edge-red")) }
        m.add(strip(-0.2, 0.3, 0.06, "metal.painted:E8E8E8"))
        m.add(strip(-0.2, 0.3, 0.06, "metal.painted:E8E8E8", under: true))
        return LODModel(m)
    }
}
