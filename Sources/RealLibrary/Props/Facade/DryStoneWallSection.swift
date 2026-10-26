import simd
import Foundation

/// Dry stone wall section: architectural facade customizer, Vernacular. Battered double-skin wall with
/// base footing, coursed rubble, through stones, hearting and cock-and-hen cope.
public struct DryStoneWallSection: RealAsset {
    public static let id = "dry-stone-wall-section"
    public static let summary = "Dry stone wall section 2.0 m: battered double-skin wall of coursed rubble with through stones, hearting and cock-and-hen cope."
    public static let tags = ["prop", "architecture", "facade", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 14, distance: 3.2)

    /// Wall length in meters.
    public var length: Float = 1.96
    /// Height to the top of the cope in meters.
    public var height: Float = 1.0
    /// Thickness at the footing in meters.
    public var baseDepth: Float = 0.42
    /// Thickness under the cope in meters.
    public var topDepth: Float = 0.36
    /// Main rubble material.
    public var rubble: MaterialKey = "stone.wall-block"
    /// Footing and through-stone material.
    public var footing: MaterialKey = "stone.slate"
    /// Cope material.
    public var cope: MaterialKey = "stone.cap"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let copeH: Float = 0.2, footH: Float = 0.1
        let bodyTop = height - copeH
        // Footing course: large slabs proud of the face.
        var x: Float = -length / 2
        while x < length / 2 - 0.05 {
            let w = min(rng.float(0.34...0.52), length / 2 - x)
            FE.stone(&m, V3(w - 0.008, footH, baseDepth + 0.04 + rng.float(-0.02...0.02)), V3(x + w / 2, footH / 2, 0), footing, rng: &rng, r: 0.014, yaw: 2)
            x += w
        }
        // Core hearting of small stones between the skins.
        var y = footH
        var course = 0
        while y < bodyTop - 0.04 {
            let t = (y - footH) / (bodyTop - footH)
            let depth = baseDepth + (topDepth - baseDepth) * t
            let ch = min(rng.float(0.11...0.16), bodyTop - y)
            let skin = depth * 0.36
            // Hearting fill.
            var hx: Float = -length / 2 + 0.05
            while hx < length / 2 - 0.05 {
                let hw = rng.float(0.16...0.26)
                FE.lump(&m, V3(hw, ch * 0.9, depth * 0.32), V3(hx, y + ch / 2, rng.float(-0.03...0.03)), footing, rng: &rng, exponent: 3, sub: 1)
                hx += hw * 0.95
            }
            // Both skins: running bond with random lengths, face stones batter inward.
            for side: Float in [-1, 1] {
                var sx: Float = -length / 2 + (course % 2 == 0 ? 0 : rng.float(0.05...0.12))
                while sx < length / 2 - 0.02 {
                    let w = min(rng.float(0.26...0.46), length / 2 + 0.0 - sx)
                    if w < 0.07 { break }
                    let d = skin * rng.float(0.9...1.15)
                    let h = ch * rng.float(0.88...1.0)
                    let zc = side * (depth / 2 - d / 2 + rng.float(-0.006...0.008))
                    let mat: MaterialKey = rng.chance(0.4) ? (rng.chance(0.5) ? "stone.granite-moss" : (rng.chance(0.5) ? "rock.mossy" : footing)) : rubble
                    let hh = h * rng.float(0.8...1.0)
                    let c = V3(sx + w / 2, y + hh / 2 + rng.float(0...0.01), zc + side * rng.float(0...0.025))
                    if rng.chance(0.55) {
                        FE.stone(&m, V3(w - 0.012, hh, d * 1.1), c, mat, rng: &rng, r: 0.026, yaw: 4, tilt: 1.5, segs: 2)
                    } else {
                        FE.lump(&m, V3(w - 0.012, hh, d * 1.1), c, mat, rng: &rng, exponent: rng.float(5...8), sub: 2)
                    }
                    if rng.chance(0.3) {
                        FE.patch(&m, V3(c.x + rng.float(-0.05...0.05), c.y + hh * 0.2, c.z + side * d * 0.55), V3(rng.float(0.06...0.12), hh * 0.5, 0.012), rng.chance(0.5) ? "moss.cushion" : "moss.sedum-gold")
                    }
                    sx += w
                }
            }
            // Through stones every third course project past both faces.
            if course % 3 == 2 {
                var tx: Float = -length / 2 + 0.35
                while tx < length / 2 - 0.3 {
                    FE.stone(&m, V3(0.2, ch * 0.95, depth + 0.07), V3(tx, y + ch * 0.475, 0), footing, rng: &rng, r: 0.014, yaw: 1.5)
                    tx += rng.float(0.55...0.75)
                }
            }
            y += ch
            course += 1
        }
        // Cope: stones set on edge, alternately tall and short (cock and hen).
        let ty = bodyTop
        var cx: Float = -length / 2
        var i = 0
        while cx < length / 2 - 0.02 {
            let w = min(rng.float(0.13...0.2), length / 2 - cx)
            let h = i % 2 == 0 ? copeH : copeH * 0.86
            FE.stone(&m, V3(w - 0.006, h, topDepth + 0.07 + rng.float(-0.02...0.02)), V3(cx + w / 2, ty + h / 2, 0), cope, rng: &rng, r: 0.014, yaw: 2, tilt: 2)
            cx += w
            i += 1
        }
        // Lichen and moss at the foot and on the cope.
        for _ in 0..<6 {
            let px = rng.float(-length / 2 + 0.1...length / 2 - 0.1)
            FE.patch(&m, V3(px, footH + 0.003, (rng.chance(0.5) ? 1 : -1) * (baseDepth / 2 + 0.01)), V3(rng.float(0.12...0.24), 0.035, 0.05), "moss.cushion")
        }
        for _ in 0..<4 {
            FE.patch(&m, V3(rng.float(-length / 2 + 0.1...length / 2 - 0.1), bodyTop + copeH - 0.01, rng.float(-0.1...0.1)), V3(0.07, 0.016, 0.05), "moss.cushion")
        }
        m = FE.seat(m)
        groundAO(&m, height: 0.12, floor: 0.6)
        return LODModel(m)
    }
}
