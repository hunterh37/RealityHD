import simd
import Foundation

/// Stack of dinner plates, 27 cm across and about 9 cm high: six white vitreous dinner plates nested foot ring
/// in well, one slightly creamier plate in the middle, and a 19 cm side plate on top. Each plate has a rolled
/// rim, a coved well and an unglazed foot ring, and sits a few millimeters off its neighbor's axis.
public struct PlateStack: RealAsset {
    public static let id = "plate-stack"
    public static let summary = "Stack of 6 white glazed dinner plates topped by a side plate, with foot rings and slight offsets."
    public static let tags = ["prop", "floorplan", "kitchen", "ceramic", "interior"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 28, distance: 0.7, studio: true)

    /// Dinner plate diameter (m).
    public var diameter: Float = 0.27
    /// Number of dinner plates under the side plate.
    public var plateCount = 6
    /// Side plate diameter (m); 0 leaves the stack without one.
    public var sideDiameter: Float = 0.19
    /// Glaze of the plates.
    public var glaze: MaterialKey = "ceramic.vitreous"
    /// Slightly creamier glaze of the odd plate in the stack.
    public var creamGlaze: MaterialKey = "ceramic.vitreous:F1EBDD"
    /// Unglazed foot ring.
    public var foot: MaterialKey = "ceramic.bisque:E6E0D2"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [3])
    }

    /// One plate profile (radius, height) from the underside center out over the rolled edge and back to the well center.
    /// `top` plates get the full coved well; buried plates only need the visible rim and edge.
    static func profile(R: Float, H: Float, wr: Float, wy: Float, rim: Float, top: Bool, buried: Bool = false) -> [V2] {
        let t: Float = 0.0045, er: Float = 0.0024
        let rimIn = R - rim
        var p: [V2] = [V2(0, 0.0032), V2(wr - 0.004, 0.0024), V2(wr - 0.0025, 0.0006), V2(wr - 0.0012, 0), V2(wr + 0.0012, 0),
                       V2(wr + 0.0028, 0.0008), V2(wr + 0.008, wy - t + 0.0012)]
        let steps = top ? 5 : 2
        for k in 1...steps {
            let f = Float(k) / Float(steps)
            p.append(V2(wr + 0.008 + (rimIn - wr - 0.004) * f, wy - t + 0.0012 + (H - wy - 0.0018) * (1 - pow(1 - f, 2))))
        }
        p.append(V2(R - er, H - 2 * er + 0.0002))
        let arc = top ? 6 : 3
        let ec = V2(R - er, H - er)
        for k in 1...arc {
            let a = -Float.pi / 2 + Float(k) / Float(arc + 1) * .pi
            p.append(ec + V2(er * cos(a), er * sin(a)))
        }
        p.append(V2(R - er, H))
        p.append(V2(rimIn + 0.004, H - 0.0012))
        let wsteps = top ? 6 : 2
        for k in 1...wsteps {
            let f = Float(k) / Float(wsteps)
            p.append(V2(rimIn + 0.004 - (rimIn + 0.004 - wr) * f, (H - 0.0012) - (H - 0.0012 - wy) * (0.5 - 0.5 * cos(f * .pi))))
        }
        if buried { return Array(p[6...(p.count - 1)]) }   // buried plates: only the cove, rim and edge show
        p.append(V2(wr * 0.4, wy))
        p.append(V2(0, wy))
        return p
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let R = diameter / 2, H: Float = 0.027, wr = R * 0.65, wy: Float = 0.0115, rim = R * 0.27
        let cream = plateCount / 2
        var base: Float = 0
        var topWell: Float = 0
        for k in 0..<plateCount {
            let top = k == plateCount - 1
            let segs = detail ? (top ? 56 : 40) : (top ? 36 : 24)
            let jx = rng.float(-0.0035...0.0035), jz = rng.float(-0.0035...0.0035)
            let tilt = simd_quatf(degrees: rng.float(-0.35...0.35), axis: simd_normalize(V3(rng.float(0.2...1), 0, rng.float(-1...1))))
            let spin = simd_quatf(degrees: rng.float(0...360), axis: .up)
            let x = Xform(translation: V3(jx, base, jz), rotation: tilt * spin)
            var s = Prim.lathe(Self.profile(R: R, H: H, wr: wr, wy: wy, rim: rim, top: top, buried: k > 0 && !top), segments: segs, seamTile: 0.3,
                               material: k == cream ? creamGlaze : glaze)
            s.recomputeNormals()
            m.add(s, x)
            let fp: [V2] = [V2(wr - 0.0013, 0.0002), V2(wr + 0.0013, 0.0002), V2(wr + 0.0013, -0.00005), V2(wr - 0.0013, -0.00005), V2(wr - 0.0013, 0.0002)]
            if k == 0 || top { m.add(Prim.lathe(fp, segments: segs, seamTile: 0.3, material: foot), x) }
            topWell = base + wy
            base += wy
        }
        if sideDiameter > 0.01 {
            let sr = sideDiameter / 2, sh: Float = 0.021
            var s = Prim.lathe(Self.profile(R: sr, H: sh, wr: sr * 0.6, wy: 0.0085, rim: sr * 0.28, top: true), segments: detail ? 48 : 30, seamTile: 0.3, material: glaze)
            s.recomputeNormals()
            let x = Xform(translation: V3(rng.float(-0.004...0.004), topWell, rng.float(-0.004...0.004)), rotation: simd_quatf(degrees: rng.float(0...360), axis: .up))
            m.add(s, x)
            let fr = sr * 0.6
            let fp: [V2] = [V2(fr - 0.0013, 0.0002), V2(fr + 0.0013, 0.0002), V2(fr + 0.0013, -0.00005), V2(fr - 0.0013, -0.00005), V2(fr - 0.0013, 0.0002)]
            m.add(Prim.lathe(fp, segments: detail ? 48 : 30, seamTile: 0.3, material: foot), x)
        }
        groundAO(&m, height: 0.02, floor: 0.7)
        return m
    }
}
