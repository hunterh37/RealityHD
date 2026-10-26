import simd
import Foundation

/// Georgian egg-and-dart cornice run, 2.4 m: two timber lengths meeting at a butt joint, each with a
/// frieze fillet, reverse-cyma bed mould, dentil course, carved egg-and-dart ovolo, corona with drip
/// groove and a cyma recta crown. Fixing nails, one replacement dentil and flaking paint. Wall plane z = 0.
public struct EggAndDartCorniceRun: RealAsset {
    public static let id = "egg-and-dart-cornice-run"
    public static let summary = "Georgian egg-and-dart cornice, 2.4 m: timber bed mould, dentils, carved ovolo, corona and cyma crown with a butt joint."
    public static let tags = ["prop", "architecture", "facade", "trim", "wood"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 18, elevation: 2, distance: 0.9)

    /// Overall run length in meters.
    public var length: Float = 2.4
    /// Dentil centre spacing in meters.
    public var dentilPitch: Float = 0.04
    /// Egg-and-dart spacing in meters.
    public var eggPitch: Float = 0.06
    /// Painted timber.
    public var paint: MaterialKey = "wood.barn-white"
    /// Second length, repainted at a different date.
    public var paintB: MaterialKey = "wood.painted-exterior"
    /// Bare weathered timber showing through flaked paint.
    public var bare: MaterialKey = "wood.weathered"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = length, joint: Float = L / 2 - 0.8, gap: Float = 0.0015
        let cuts: [(Float, Float, MaterialKey)] = [(-L / 2, joint - gap, paint), (joint + gap, L / 2, paintB)]
        // Profiles (x out from the wall, y up), 0.2 m high and 0.2 m deep.
        let frieze = [V2(0, 0), V2(0.016, 0), V2(0.016, 0.03), V2(0, 0.03)]
        var bed = [V2(0.0, 0.03), V2(0.03, 0.03), V2(0.03, 0.034)]
        bed += FL.ogee(from: V2(0.03, 0.034), to: V2(0.07, 0.06), steps: 5)
        bed += [V2(0.07, 0.062), V2(0.0, 0.062)]
        let dentilBack = [V2(0.0, 0.062), V2(0.05, 0.062), V2(0.05, 0.097), V2(0.0, 0.097)]
        var ovolo = [V2(0.0, 0.097), V2(0.1, 0.097), V2(0.1, 0.099)]
        for i in 1...4 {
            let a = Float(i) / 4 * (.pi / 2)
            ovolo.append(V2(0.1 + 0.04 * sin(a), 0.099 + 0.036 * (1 - cos(a))))
        }
        ovolo += [V2(0.14, 0.137), V2(0.0, 0.137)]
        let corona = [V2(0.0, 0.137), V2(0.2, 0.137), V2(0.2, 0.1385), V2(0.199, 0.14), V2(0.199, 0.168), V2(0.18, 0.172), V2(0.0, 0.172)]
        var crown = [V2(0.0, 0.172), V2(0.15, 0.172), V2(0.15, 0.174)]
        crown += FL.ogee(from: V2(0.15, 0.174), to: V2(0.2, 0.2), steps: 6).map { V2($0.x, $0.y) }
        crown += [V2(0.0, 0.2)]
        for (x0, x1, mat) in cuts {
            let len = x1 - x0, cx = (x0 + x1) / 2
            for p in [frieze, bed, dentilBack, ovolo, corona] {
                FA.run(&m, p, length: len, at: V3(cx, 0, 0), mat, bevel: 0.0015)
            }
            FA.run(&m, crown, length: len, at: V3(cx, 0, 0), mat, bevel: 0.002)
            // Drip groove under the corona nose.
            FA.run(&m, [V2(0.185, 0.1365), V2(0.19, 0.1365), V2(0.19, 0.139), V2(0.185, 0.139)], length: len - 0.01, at: V3(cx, 0, 0), "wood.trim-weathered", bevel: 0.0005)
            // Dentils.
            let n0 = Int(ceil((x0 + 0.02) / dentilPitch)), n1 = Int(floor((x1 - 0.02) / dentilPitch))
            for k in n0...n1 {
                let x = Float(k) * dentilPitch
                let replaced = k == 7
                FA.box(&m, V3(0.021, 0.033, 0.034), V3(x, 0.0795, 0.034 + 0.015), replaced ? "wood.pine-aged" : mat, r: 0.0015)
            }
            // Egg-and-dart: shell, egg and dart per bay along the ovolo, tilted to the 45 degree face.
            let e0 = Int(ceil((x0 + 0.03) / eggPitch)), e1 = Int(floor((x1 - 0.03) / eggPitch))
            for k in e0...e1 {
                let x = Float(k) * eggPitch
                let chipped = k == -9
                m.add(Prim.superellipsoid(V3(0.056, 0.056, 0.012), exponent: 2, subdivisions: 2, material: mat),
                      Xform(translation: V3(x, 0.116, 0.131), rotation: FA.q(48, FA.X)))
                m.add(Prim.superellipsoid(V3(0.036, 0.05, 0.022), exponent: 2, subdivisions: 3, material: chipped ? bare : mat),
                      Xform(translation: V3(x, 0.116, 0.1355), rotation: FA.q(48, FA.X)))
                m.add(Prim.lathe([V2(0.008, 0), V2(0.004, 0.02), V2(0, 0.034)], segments: 4, material: mat),
                      Xform(translation: V3(x + eggPitch / 2, 0.104, 0.12), rotation: FA.q(45, FA.X)))
            }
            // Fixing nails through the frieze.
            let f0 = Int(ceil((x0 + 0.05) / 0.4)), f1 = Int(floor((x1 - 0.05) / 0.4))
            for k in f0...f1 {
                FA.cylZ(&m, r: 0.003, h: 0.002, at: V3(Float(k) * 0.4 + 0.08, 0.015, 0.016), "metal.galvanized-aged", bevel: 0.0008, segments: 8)
            }
        }
        // Butt joint backer splice plate and the flaked paint patches.
        FA.box(&m, V3(0.003, 0.03, 0.016), V3(joint, 0.015, 0.008), "wood.trim-weathered", r: 0.0005)
        for _ in 0..<5 {
            let x = rng.float(-1.1...1.1)
            FA.box(&m, V3(rng.float(0.05...0.12), 0.012, 0.006), V3(x, 0.188 + rng.float(-0.004...0.004), 0.197 - rng.float(0...0.01)), bare, r: 0.001, rot: FA.q(-30, FA.X))
        }
        for _ in 0..<4 {
            FA.box(&m, V3(0.02, 0.07, 0.003), V3(rng.float(-1.1...1.1), 0.088, 0.0165), "wood.trim-weathered", r: 0.0008)
        }
        groundAO(&m, height: 0.06, floor: 0.9)
        return LODModel(FC.seatY(FA.centerZ(m)))
    }
}
