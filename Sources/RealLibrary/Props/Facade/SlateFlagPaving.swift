import simd
import Foundation

/// Slate flag paving: architectural facade customizer, Welsh Vernacular. Riven blue-grey slate flags
/// in random lengths laid in courses of 300-550 mm, 6 mm sand-mortar joints, slight lipping between
/// flags and one cracked flag.
public struct SlateFlagPaving: RealAsset {
    public static let id = "slate-flag-paving"
    public static let summary = "Slate flag paving, 2 x 2 m: Welsh riven slate flags in random-length courses with narrow pointed joints."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone"]
    public static let budget = 6000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 1.0, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.08, 2.0)
    /// Course depths (m); sum to the tile depth.
    public var courseDepths: [Float] = [0.45, 0.35, 0.55, 0.3, 0.35]
    /// Joint (m), flag thickness (m).
    public var joint: Float = 0.006
    public var thickness: Float = 0.03
    /// Slate tones (sRGB hex).
    public var tones: [UInt32] = [0x4A5058, 0x3E444C, 0x565A60, 0x4C4A54, 0x5A6066]
    public init() {}

    /// Splits `total` into random lengths within `range`.
    private func lengths(_ r: inout SeededRNG, total: Float, range: ClosedRange<Float>) -> [Float] {
        var out: [Float] = [], left = total
        while left > range.upperBound { let l = r.float(range); out.append(l); left -= l }
        if left < range.lowerBound, let last = out.popLast() { out.append((last + left) / 2); out.append((last + left) / 2) } else { out.append(left) }
        return out
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        PTK.bed(&m, w: size.x, d: size.z, top: size.y - thickness + 0.006, PTK.tint("ground.sand", 0x5E5A52))
        let scale = size.z / courseDepths.reduce(0, +)
        var z = -size.z / 2
        var cracked = false
        for (j, d0) in courseDepths.enumerated() {
            let d = d0 * scale
            var r = rng.fork(j)
            var x = -size.x / 2
            for (k, l) in lengths(&r, total: size.x, range: 0.35...0.75).enumerated() {
                var q = r.fork(k)
                let key = PTK.tint("rock.slate", q.pick(tones))
                let top = size.y - q.float(0...0.004)
                let tilt = V2(q.float(-0.35...0.35), q.float(-0.35...0.35))
                let cx = x + l / 2, cz = z + d / 2, w = l - joint, dd = d - joint
                if !cracked && j == 2 && k == 1 {
                    cracked = true
                    let a = q.float(-0.06...0.06)
                    let w1 = w / 2 + a - 0.0015, w2 = w - w1 - 0.003
                    PTK.slab(&m, x: cx - w / 2 + w1 / 2, z: cz, w: w1, d: dd, t: thickness, top: top, bevel: 0.002, corner: 0.006, key: key, tilt: tilt)
                    PTK.slab(&m, x: cx + w / 2 - w2 / 2, z: cz, w: w2, d: dd, t: thickness, top: top - 0.003, bevel: 0.002, corner: 0.004, key: key, tilt: tilt)
                } else {
                    PTK.slab(&m, x: cx, z: cz, w: w, d: dd, t: thickness, top: top, bevel: 0.0025, corner: 0.008, key: key, tilt: tilt)
                }
                x += l
            }
            z += d
        }
        return PTK.finish(&m, id: Self.id, size: size, cap: PTK.tint("rock.slate", tones[0]))
    }
}
