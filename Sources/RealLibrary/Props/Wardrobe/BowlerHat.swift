import simd
import Foundation

/// Bowler hat (derby), 30 x 27 cm, 13 cm tall: oval domed crown in black fur felt, black grosgrain silk band
/// 32 mm deep with a flat bow on the left side, bound brim edge, brim curled up hard at the sides and nearly
/// flat front and back, leather sweatband inside.
public struct BowlerHat: RealAsset {
    public static let id = "bowler-hat"
    public static let summary = "Black felt bowler hat, 30 cm: oval domed crown, silk grosgrain band with bow, side-curled bound brim, leather sweatband."
    public static let tags = ["prop", "interior", "wardrobe", "fabric", "handheld"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 22, distance: 0.9, studio: true)

    /// Fur felt.
    public var felt: MaterialKey = "fabric.felt"
    /// Silk grosgrain band, bow and brim binding.
    public var silk: MaterialKey = "fabric.grosgrain"
    /// Leather sweatband.
    public var sweatband: MaterialKey = "leather.black"
    /// Crown radius at the band (m, along X; Z is 12 percent longer).
    public var crownRadius: Float = 0.082
    /// Crown height above the brim (m).
    public var crownHeight: Float = 0.118
    /// Brim outer radius (m).
    public var brimRadius: Float = 0.138
    /// Side curl height of the brim edge (m).
    public var curl: Float = 0.034
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let R = crownRadius, H = crownHeight, oval: Float = 1.12
        let seg = 64
        // Brim lift: rises toward the sides (X) with the square of the distance past the crown.
        func lift(_ p: V3) -> Float {
            let r = simd_length(V2(p.x, p.z / oval))
            let t = max(0, min(1, (r - R) / (brimRadius - R)))
            let side = p.x * p.x / max(1e-6, p.x * p.x + p.z * p.z)
            return curl * t * t * (0.18 + 0.82 * side)
        }
        func ovalize(_ s: inout Surface, brim: Bool) {
            s.deform { p in
                var q = V3(p.x, p.y, p.z * oval)
                if brim { q.y += lift(q) }
                return q
            }
        }
        // Crown: tapered side wall into a full dome, 3 mm felt shell.
        var crown: [V2] = []
        for k in 0...14 {
            let t = Float(k) / 14
            let y = 0.004 + t * (H * 0.56)
            crown.append(V2(R - 0.004 * t + 0.003 * sin(t * .pi), y))
        }
        let y0 = 0.004 + H * 0.56, rTop = R - 0.004
        for k in 1...16 {
            let a = Float(k) / 16 * .pi / 2
            crown.append(V2(max(0, rTop * cos(a)), y0 + (H - y0) * sin(a)))
        }
        var crownS = Prim.lathe(crown, segments: seg, seamTile: 0.2, material: felt)
        ovalize(&crownS, brim: false)
        m.add(crownS)
        // Brim: flat annulus with a rolled edge, lifted at the sides.
        var brim: [V2] = [V2(R - 0.004, 0.0035), V2(R + 0.01, 0.003)]
        for k in 1...7 { let t = Float(k) / 7; brim.append(V2(R + 0.01 + t * (brimRadius - R - 0.018), 0.0028 - 0.0004 * t)) }
        for k in 0...8 {
            let a = Float(k) / 8 * .pi
            brim.append(V2(brimRadius - 0.006 + 0.0045 * sin(a), 0.0026 + 0.0042 * (1 - cos(a)) * 0.5 - 0.0014 * sin(a)))
        }
        brim.append(V2(brimRadius - 0.012, 0.0007))
        for k in 1...5 { let t = Float(k) / 5; brim.append(V2(brimRadius - 0.012 - t * (brimRadius - R - 0.012), 0.0004)) }
        var brimS = Prim.lathe(brim.reversed(), segments: seg, seamTile: 0.2, material: felt)
        ovalize(&brimS, brim: true)
        m.add(brimS)
        // Bound edge: silk binding tape over the brim roll.
        var bind = Prim.torus(major: brimRadius - 0.0018, minor: 0.0026, segments: seg, sides: 10, material: silk)
        bind.deform { p in var q = V3(p.x, p.y + 0.0028, p.z * oval); q.y += lift(q) * 0.985; return q }
        m.add(bind)
        // Grosgrain band: 32 mm tall, proud of the crown by 1 mm, with ribs.
        var band: [V2] = [V2(R - 0.001, 0.0045), V2(R + 0.0012, 0.005)]
        for k in 0...6 {
            let t = Float(k) / 6
            band.append(V2(R + 0.0012 - 0.0006 * t , 0.005 + t * 0.032))
        }
        band.append(V2(R - 0.0012, 0.0375))
        var bandS = Prim.lathe(band, segments: seg, seamTile: 0.12, material: silk)
        ovalize(&bandS, brim: false)
        m.add(bandS)
        // Flat bow on the left side (-X): two loops and a knot.
        let bx = -(R + 0.0018)
        for dz: Float in [-1, 1] {
            var loop = Prim.superellipsoid(V3(0.004, 0.019, 0.026), exponent: 3, subdivisions: 6, material: silk)
            loop.deform { p in V3(p.x - 0.0016 * (p.z * p.z) / 0.00017, p.y, p.z) }
            m.add(loop, Xform(translation: V3(bx - 0.001, 0.021, dz * 0.014 * oval), rotation: simd_quatf(degrees: dz * 6, axis: V3(1, 0, 0))))
            var tail = Prim.superellipsoid(V3(0.003, 0.024, 0.012), exponent: 3, subdivisions: 6, material: silk)
            tail.deform { p in V3(p.x, p.y, p.z) }
            m.add(tail, Xform(translation: V3(bx - 0.0008, 0.014, dz * 0.008), rotation: simd_quatf(degrees: dz * 18, axis: V3(1, 0, 0))))
        }
        m.add(Prim.superellipsoid(V3(0.006, 0.02, 0.011), exponent: 2.6, subdivisions: 6, material: silk), Xform(translation: V3(bx - 0.0026, 0.0215, 0)))
        // Leather sweatband inside the crown with a stitched turn.
        var sweat = Prim.lathe([V2(R - 0.0042, 0.003), V2(R - 0.0062, 0.004), V2(R - 0.0066, 0.03), V2(R - 0.0046, 0.035)], segments: seg, seamTile: 0.12, material: sweatband)
        ovalize(&sweat, brim: false)
        m.add(sweat)
        // Crown pinch: a faint dent of handling on the front right.
        let dentA = rng.float(0.3...0.9)
        for i in m.surfaces.indices where m.surfaces[i].material == felt {
            m.surfaces[i].deform { p in
                guard p.y > 0.05 else { return p }
                let d = simd_length(V2(p.x - R * 0.55 * cos(dentA), p.z - R * 0.6 * sin(dentA)))
                return p - V3(cos(dentA), 0, sin(dentA)) * (0.0015 * exp(-d * d / 0.0006))
            }
        }
        groundAO(&m, height: 0.04, floor: 0.6)
        return LODModel(m)
    }
}
