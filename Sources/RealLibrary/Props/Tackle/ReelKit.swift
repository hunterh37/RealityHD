import simd
import Foundation

/// Shared reel helpers: lathes about X or Z, line fill, knurled knobs and a rig wrapper that offsets
/// everything (geometry and pivots) so the finished reel is centred on X/Z.
enum ReelKit {
    /// Lathe +Y to +Z (spool axis across the rod: baitcast and fly reels).
    static let alongZ = simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))

    /// Surface of revolution about +X from `x0` at axis point (y, z).
    static func latheX(_ prof: [V2], x0: Float, y: Float, z: Float = 0, seg: Int = 32, tile: Float = 0.03, _ mat: MaterialKey) -> Surface {
        Prim.lathe(prof, segments: seg, seamTile: tile, material: mat).transformed(Xform(translation: V3(x0, y, z), rotation: RodKit.alongX))
    }

    /// Surface of revolution about +Z from `z0` at axis point (x, y).
    static func latheZ(_ prof: [V2], z0: Float, x: Float, y: Float, seg: Int = 32, tile: Float = 0.03, _ mat: MaterialKey) -> Surface {
        Prim.lathe(prof, segments: seg, seamTile: tile, material: mat).transformed(Xform(translation: V3(x, y, z0), rotation: alongZ))
    }

    /// Wound line on a spool: a slightly crowned cylinder with fine winding ridges.
    static func lineFill(r: Float, core: Float, len: Float) -> [V2] {
        var p: [V2] = [V2(core, 0), V2(r - 0.0006, 0.0003)]
        let n = 14
        for i in 0...n {
            let t = Float(i) / Float(n)
            p.append(V2(r + 0.0004 * sin(t * .pi) - (i % 2 == 0 ? 0 : 0.00012), 0.0008 + (len - 0.0016) * t))
        }
        p += [V2(r - 0.0006, len - 0.0003), V2(core, len)]
        return p
    }

    /// Knurled knob profile: ridges along the axis direction become rings; `ridges` grooves.
    static func ribbedKnob(r: Float, len: Float, ridges: Int) -> [V2] {
        var p: [V2] = [V2(0, 0), V2(r * 0.8, 0.0003), V2(r, 0.0015)]
        for i in 1..<ridges { p.append(V2(i % 2 == 0 ? r : r * 0.94, 0.0015 + (len - 0.003) * Float(i) / Float(ridges))) }
        p += [V2(r, len - 0.0015), V2(r * 0.85, len - 0.0002), V2(0, len)]
        return p
    }

    /// Reel foot: a flat bar along X with tapered ends, bottom at y = 0.
    static func foot(length: Float, width: Float, thick: Float, mat: MaterialKey) -> Surface {
        let outline = Shape2D.rounded([V2(-length / 2, -width * 0.32), V2(-length / 2 + 0.012, -width / 2), V2(length / 2 - 0.012, -width / 2),
                                       V2(length / 2, -width * 0.32), V2(length / 2, width * 0.32), V2(length / 2 - 0.012, width / 2),
                                       V2(-length / 2 + 0.012, width / 2), V2(-length / 2, width * 0.32)], radius: 0.002)
        return Prim.extrude(outline, depth: thick, bevel: 0.0008, bevelSegments: 1, material: mat)
            .transformed(Xform(translation: V3(0, thick / 2, 0), rotation: simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))))
    }

    /// Adds `s` moved by `offset` to `part` (or the base when nil).
    static func add(_ rig: inout Rig, _ s: Surface, _ x: Xform = .identity, to part: String?, offset: V3) {
        var t = x; t.translation += offset
        if let part { rig.add(s, t, to: part) } else { rig.base[0].add(s, t) }
    }
}
