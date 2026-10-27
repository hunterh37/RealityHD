import simd
import Foundation

/// Shared construction for the dd1a cookware batch: rolled-rim trays, loop handles, assembly.
enum DD1AKit {
    /// Centers a vessel model on X by `shift`, turns it `degrees` about +Y, puts the floor surface last and adds ground AO.
    static func assemble(name: String, body: Model, floor: Surface?, shift: Float, degrees: Float, ao: Float = 0.03) -> Model {
        var out = Model(name: name)
        let x = Xform(translation: V3(shift, 0, 0))
        let r = Xform(rotation: simd_quatf(degrees: degrees, axis: V3(0, 1, 0)))
        for s in body.surfaces { out.surfaces.append(s.transformed(x).transformed(r)) }
        if let f = floor { out.surfaces.append(f.transformed(x).transformed(r)) }
        groundAO(&out, height: ao, floor: 0.55)
        return out
    }

    /// Top-down UVs in meters (lofts and fan caps stretch otherwise).
    static func planar(_ surface: Surface) -> Surface {
        var s = surface
        s.uvs = s.positions.map { V2($0.x, $0.z) }
        s.computeTangents()
        return s
    }

    /// Rolled bead ring at height `y` (turned pans).
    static func beadRing(_ m: inout Model, radius: Float, y: Float, minor: Float, segments: Int, material: MaterialKey) {
        let path = (0..<(segments)).map { k -> V3 in
            let a = Float(k) / Float(segments) * 2 * .pi
            return V3(radius * cos(a), y, radius * sin(a))
        }
        m.add(Prim.sweep(Shape2D.circle(minor, segments: 8), along: path, closedPath: true, material: material))
    }

    /// Rounded-rectangle tray with flared walls, a floor fillet and a rolled wire rim. Base at y = 0, top at `h`.
    static func tray(_ m: inout Model, w: Float, d: Float, h: Float, wall: Float, corner: Float, flare: Float, bead: Float,
                     interior: MaterialKey, exterior: MaterialKey, rim: MaterialKey, detail: Bool) {
        let top = h - bead, seg = detail ? 6 : 3
        func inset(_ y: Float) -> Float { flare * (1 - y / top) }
        func rr(_ i: Float) -> [V2] { Shape2D.roundedRect(w - 2 * i, d - 2 * i, radius: max(corner - i, 0.002), segments: seg) }
        let outer = [Prim.ring(rr(inset(0) + 0.003), y: 0), Prim.ring(rr(inset(0.003)), y: 0.003), Prim.ring(rr(0), y: top)]
        m.add(planar(Prim.loft(outer, capStart: true, material: exterior)))
        let fy = wall
        let inner = [Prim.ring(rr(inset(fy) + wall + 0.004), y: fy), Prim.ring(rr(inset(fy + 0.004) + wall), y: fy + 0.004),
                     Prim.ring(rr(wall), y: top)]
        m.add(planar(Prim.loft(inner, capStart: true, material: interior).flipped()))
        let path = Prim.ring(Shape2D.roundedRect(w - wall, d - wall, radius: max(corner - wall / 2, 0.002), segments: seg + 2), y: top)
        m.add(Prim.sweep(Shape2D.circle(bead, segments: detail ? 10 : 6), along: path, closedPath: true, material: rim))
    }

    /// Cast loop (ear) handle from a vessel wall: starts at `base`, bows `length` out along `dir` (unit, XZ) and returns `height` higher.
    static func earHandle(_ m: inout Model, base: V3, dir: V3, length: Float, height: Float, lateral: Float, radial: Float,
                          material: MaterialKey, detail: Bool) {
        let n = simd_normalize(simd_cross(dir, V3(0, 1, 0)))
        let pts = (0...6).map { k -> V3 in
            let t = Float(k) / 6
            return base + dir * (length * pow(sin(.pi * t), 0.7)) + V3(0, height * t, 0)
        }
        let path = catmull(pts, per: detail ? 5 : 2)
        m.add(Prim.sweep(Shape2D.superellipse(lateral, radial, exponent: 2.8, segments: detail ? 16 : 8), along: path, up: n, material: material))
    }
}
