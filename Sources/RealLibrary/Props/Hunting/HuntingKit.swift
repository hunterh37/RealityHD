import simd
import Foundation

/// Shared helpers for hunting props. Design space: +X toward the muzzle or arrow tip, bore or arrow
/// axis through y = 0, z = 0, +Y up, +Z to the shooter's right. `Placer` shifts design space to asset
/// space (centered on X/Z, base at y = 0).
struct Placer {
    var off: V3
    func at(_ t: V3 = .zero, _ q: simd_quatf = .identity) -> Xform { Xform(translation: t + off, rotation: q) }
    func p(_ v: V3) -> V3 { v + off }
}

enum HuntKit {
    /// Lathe +Y axis to +X.
    static let alongX = simd_quatf(angle: -.pi / 2, axis: V3(0, 0, 1))

    /// Solid of revolution about an X-parallel axis through (c.y, c.z). Profile pairs are (distance from c.x, radius);
    /// end the profile on radius 0 to close it.
    static func axial(_ prof: [(Float, Float)], at c: V3 = .zero, seg: Int = 24, tile: Float = 0.1, _ mat: MaterialKey) -> Surface {
        Prim.lathe(prof.map { V2($0.1, $0.0) }, segments: seg, seamTile: tile, material: mat, swapUV: true)
            .transformed(Xform(translation: c, rotation: alongX))
    }

    /// Straight round rod between two points.
    static func rod(_ a: V3, _ b: V3, r: Float, sides: Int = 12, _ mat: MaterialKey) -> Surface {
        Prim.tube([a, b], radii: [r, r], sides: sides, seamTile: 0.02, material: mat, capEnd: true)
    }

    /// Round wire through control points (Catmull-Rom smoothed).
    static func wire(_ pts: [V3], r: Float, per: Int = 6, sides: Int = 8, _ mat: MaterialKey) -> Surface {
        let path = catmull(pts, per: per)
        return Prim.tube(path, radii: path.map { _ in r }, sides: sides, seamTile: 0.02, material: mat, capEnd: true)
    }

    /// Rounded box at `c`.
    static func box(_ c: V3, _ size: V3, r: Float = 0.002, rot: simd_quatf = .identity, _ mat: MaterialKey) -> Surface {
        Prim.roundedBox(size, radius: r, bevelSegments: 2, material: mat).transformed(Xform(translation: c, rotation: rot))
    }

    /// Cylinder of radius `r` from `a` to `b` with rounded rims.
    static func cyl(_ a: V3, _ b: V3, r: Float, bevel: Float = 0.001, seg: Int = 20, _ mat: MaterialKey) -> Surface {
        let d = b - a, h = simd_length(d)
        return Prim.cylinder(radius: r, height: h, bevel: min(bevel, r * 0.4), segments: seg, material: mat)
            .transformed(Xform(translation: a, rotation: facing(d / h)))
    }

    /// Side profile (XY outline) extruded across Z, width scaled by `width(x)` meters. Grain follows X.
    static func profileSolid(_ pts: [V2], radius: Float, width: (Float) -> Float, bevel: Float = 0.0095, _ mat: MaterialKey) -> Surface {
        let base: Float = 0.04
        var s = Prim.extrude(Shape2D.rounded(pts, radius: radius, segments: 5), depth: base, bevel: bevel, bevelSegments: 3, material: mat)
        s.deform { V3($0.x, $0.y, $0.z * width($0.x) / base) }
        return s
    }

    /// Blended outline of a mirrored extrude (limbs, risers): see call sites.
    static func lensDisc(at c: V3, r: Float, thick: Float = 0.0012, _ mat: MaterialKey = "plastic.lens-clear") -> Surface {
        cyl(c, c + V3(thick, 0, 0), r: r, bevel: 0.0003, seg: 24, mat)
    }

    /// Pair of 2 mm studs for a sling swivel at `c` pointing down.
    static func swivel(at c: V3, _ mat: MaterialKey = "metal.bolt-bright") -> Surface {
        cyl(c, c + V3(0, -0.009, 0), r: 0.0035, bevel: 0.0008, seg: 10, mat)
    }
}

extension HuntKit {
    /// Rotation about the X axis.
    static func roll(_ degrees: Float) -> simd_quatf { simd_quatf(degrees: degrees, axis: V3(1, 0, 0)) }

    /// Fixed three-blade broadhead along +X from `x0`: ferrule cone plus blades with a swept cutting edge.
    /// `cut` is the cutting radius (half the cutting diameter), `len` the overall length from x0.
    static func broadhead(x0: Float, len: Float, cut: Float, ferrule: Float, blades: Int = 3, _ mat: MaterialKey) -> [(Surface, Xform)] {
        var out: [(Surface, Xform)] = []
        let cone: [(Float, Float)] = [(0, 0), (0, ferrule * 1.1), (len * 0.12, ferrule * 1.12), (len * 0.5, ferrule * 0.8), (len * 0.9, ferrule * 0.3), (len, 0.0004), (len, 0)]
        out.append((axial(cone, at: V3(x0, 0, 0), seg: 12, tile: 0.02, mat), .identity))
        let outline: [V2] = [V2(x0 + len * 0.02, 0.0015), V2(x0 + len * 0.10, cut), V2(x0 + len * 0.28, cut), V2(x0 + len * 0.97, 0.0008), V2(x0 + len, 0.0004), V2(x0 + len * 0.97, 0.0)]
        for i in 0..<blades {
            let blade = Prim.extrude(outline, depth: 0.0008, bevel: 0.0002, bevelSegments: 1, material: mat)
            out.append((blade, Xform(rotation: roll(Float(i) * 360 / Float(blades)))))
        }
        return out
    }

    /// Fletching vanes: `count` low shield-profile vanes from `x0` for `len`, rising `h` above the shaft radius `r`.
    static func vanes(x0: Float, len: Float, r: Float, h: Float, count: Int = 3, tints: [String]? = nil, base: MaterialKey = "plastic.fletching") -> [(Surface, Xform)] {
        let outline: [V2] = [V2(x0, r * 0.9), V2(x0 + len * 0.03, r + h * 0.55), V2(x0 + len * 0.35, r + h), V2(x0 + len * 0.95, r + h * 0.82), V2(x0 + len, r * 0.9)]
        var out: [(Surface, Xform)] = []
        for i in 0..<count {
            let mat = tints.map { MaterialKey(base + ":" + $0[i % $0.count]) } ?? base
            let v = Prim.extrude(outline, depth: 0.0007, bevel: 0.0002, bevelSegments: 1, material: mat)
            out.append((v, Xform(rotation: roll(Float(i) * 360 / Float(count)))))
        }
        return out
    }
}
