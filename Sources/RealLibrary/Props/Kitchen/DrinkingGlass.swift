import simd
import Foundation

/// Drinking glass: 330 ml pressed-glass tumbler, 8 cm across the rim and 12 cm tall. Parts: thick heavy base with a beveled foot ring and a
/// hollow punt under it, tapered wall, thin rolled rim, optional water fill with a meniscus, and a pair of ice cubes.
public struct DrinkingGlass: RealAsset {
    public static let id = "drinking-glass"
    public static let summary = "Clear glass tumbler, 330 ml: thick base, thin rim, optional water fill level knob."
    public static let tags = ["prop", "floorplan", "kitchen", "glass", "interior", "handheld"]
    public static let budget = 4200
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 18, distance: 1.2, studio: true)

    /// Overall size in meters (x width, y height, z depth). Authored with the base at y = 0.
    public var size = V3(0.08, 0.12, 0.08)
    /// Water fill as a fraction of the inner height (0 empty, 1 to the brim).
    public var fill: Float = 0.62
    /// Radius of the base (m).
    public var baseRadius: Float = 0.031
    /// Wall thickness at the rim (m).
    public var wall: Float = 0.0022
    /// Glass thickness under the water (m).
    public var baseThickness: Float = 0.016
    /// Ice cubes floating in the water.
    public var ice = true
    /// Glass and liquid keys.
    public var glass: MaterialKey = "glass.clear"
    public var water: MaterialKey = "glass.water-clear"
    public init() {}

    private func innerR(_ y: Float, _ rimR: Float) -> Float {
        let t = max(0, min(1, (y - baseThickness) / (size.y - baseThickness)))
        return (baseRadius - 0.0045 + (rimR - wall - (baseRadius - 0.0045)) * t)
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let h = size.y, rimR = size.x / 2, rb = baseRadius
        func make(_ seg: Int, _ detail: Bool) -> Model {
            var m = Model(name: Self.id)
            // Outer wall with a faint waist, thick foot, hollow punt, then the rolled rim and the inner wall down to the floor.
            let punt: [V2] = [V2(0, 0.0035), V2(0.012, 0.0028), V2(0.022, 0.0012), V2(rb - 0.0035, 0.0006)]
            var pts: [V2] = punt
            pts.append(V2(rb - 0.0012, 0.0004)); pts.append(V2(rb, 0.0022))
            pts.append(V2(rb + 0.0006, 0.006))
            let nOut = detail ? 6 : 3
            for k in 1...nOut {
                let t = Float(k) / Float(nOut)
                let r = (rb + 0.0006) + (rimR - rb - 0.0006) * t + 0.0009 * sin(t * .pi)
                pts.append(V2(r, 0.006 + (h - 0.006) * t))
            }
            // Rolled rim.
            let rimOuter = pts.last!.x
            pts.append(V2(rimOuter - wall * 0.35, h + 0.0004))
            pts.append(V2(rimOuter - wall * 0.75, h + 0.0002))
            pts.append(V2(rimOuter - wall, h - 0.0012))
            let nIn = detail ? 6 : 3
            for k in (0..<nIn).reversed() {
                let y = baseThickness + (h - 0.0015 - baseThickness) * Float(k) / Float(nIn)
                pts.append(V2(innerR(y, rimOuter), y))
            }
            pts.append(V2(innerR(baseThickness, rimOuter) - 0.003, baseThickness - 0.0006))
            pts.append(V2(0, baseThickness - 0.0008))
            m.add(Prim.lathe(pts, segments: seg, seamTile: 0.09, material: glass))
            // Fill: water body inset from the glass, flat surface with a meniscus ring at the wall.
            if fill > 0.01 {
                let wy = baseThickness + (h - 0.012 - baseThickness) * fill
                let r0 = innerR(baseThickness, rimOuter) - 0.0004
                let rw = innerR(wy, rimOuter) - 0.0004
                let body: [V2] = [V2(0, baseThickness + 0.0002), V2(r0 - 0.002, baseThickness + 0.0002), V2(r0, baseThickness + 0.002),
                                  V2(rw, wy - 0.0035), V2(rw, wy - 0.0012), V2(rw - 0.0016, wy), V2(rw - 0.0045, wy - 0.0006), V2(0, wy - 0.0006)]
                m.add(Prim.lathe(body, segments: seg, seamTile: 0.1, material: water))
                if ice {
                    for (i, p) in [V2(-0.009, 0.006), V2(0.011, -0.004)].enumerated() {
                        let sz = rng.float(0.019...0.023)
                        let cube = Prim.superellipsoid(V3(sz, sz * 0.92, sz), exponent: 6, subdivisions: detail ? 3 : 2, material: "glass.ice")
                        let top = wy - 0.0006
                        let y = top - sz * 0.92 * 0.42 + Float(i) * 0.002
                        let q = simd_quatf(degrees: rng.float(0...60), axis: .up) * simd_quatf(degrees: rng.float(-12...12), axis: V3(1, 0, 0))
                        m.add(cube, Xform(translation: V3(p.x, y, p.y), rotation: q))
                    }
                }
            }
            if detail {
                // Condensation beads on the outer wall, denser low on the glass and a few running drips.
                var r2 = rng.fork(11)
                for _ in 0..<16 {
                    let a = r2.float(0...(2 * .pi)), y = r2.float(0.018...(h - 0.02))
                    let rr = (rb + 0.0006) + (rimR - rb - 0.0006) * ((y - 0.006) / (h - 0.006)) + 0.0004
                    let d = r2.float(0.0016...0.0034)
                    let n = V3(cos(a), 0, sin(a))
                    let q = simd_quatf(from: .up, to: n)
                    m.add(Prim.superellipsoid(V3(d, d * 0.5, d * 1.15), exponent: 2, subdivisions: 2, material: water),
                          Xform(translation: V3(n.x * rr, y, n.z * rr), rotation: q))
                }
            }
            return m
        }
        let lod0 = make(40, true), lod1 = make(20, false)
        return LODModel(levels: [lod0, lod1], switchDistances: [3])
    }
}
