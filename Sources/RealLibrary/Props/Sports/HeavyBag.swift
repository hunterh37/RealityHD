import simd
import Foundation

/// Hanging 48 inch commercial heavy bag. Origin is the bag bottom (y = 0); the bag body runs to `length`,
/// four webbing tabs with D-rings take four steel chains up to a swivel and hook at `hangHeight`.
/// Red vinyl with a domed top and bottom, two stitched webbing bands, a welted vertical seam and one
/// athletic-tape patch where the bag gets hit most.
public struct HeavyBag: RealAsset {
    public static let id = "heavy-bag"
    public static let summary = "Hanging 48 inch red vinyl heavy bag: banded cylinder, four D-ring tabs, steel chains, swivel and hook."
    public static let tags = ["prop", "sports", "leather", "metal"]
    public static let budget = 18000
    public static let author = "hunter"
    public static let preview = PreviewHint(azimuth: 30, elevation: 8, distance: 1.0, studio: true)

    /// Bag body length (m).
    public var length: Float = 1.2
    /// Bag radius (m).
    public var radius: Float = 0.175
    /// Distance from the bag top to the swivel (chain run, m).
    public var chainRun: Float = 0.40
    /// Vinyl cover.
    public var vinyl: MaterialKey = "leather.oxblood:A61512"
    /// Webbing bands and tabs.
    public var webbing: MaterialKey = "fabric.webbing:15171A"
    /// Hardware steel.
    public var steel: MaterialKey = "metal.steel"
    public init() {}

    /// Height of the hook apex above the bag bottom (m): the attachment point for a ceiling mount.
    public var hangHeight: Float { length + chainRun + 0.078 }

    public func build(seed: UInt64) -> LODModel {
        var levels: [Model] = []
        for l in 0..<2 {
            var rng = SeededRNG(seed: seed)
            let detail = l == 0
            var m = Model(name: Self.id)
            let L = length, R = radius

            // Body: slightly fuller toward the bottom where the fill settles.
            func r(_ y: Float) -> Float {
                let t = y / L
                let belly = 1 + 0.012 * (1 - t) * sin(min(1, t * 2.4) * .pi)
                return R * belly
            }
            var prof: [V2] = [V2(0, 0)]
            let bottom: [(Float, Float)] = [(0.06, 0.003), (0.11, 0.012), (0.145, 0.032), (0.164, 0.065), (0.172, 0.11)]
            for (x, y) in bottom { prof.append(V2(x * R / 0.175, y)) }
            let n = detail ? 26 : 12
            for k in 1...n { let y = 0.14 + (L - 0.30) * Float(k) / Float(n); prof.append(V2(r(y), y)) }
            let top: [(Float, Float)] = [(0.172, L - 0.08), (0.166, L - 0.045), (0.152, L - 0.022), (0.128, L - 0.008), (0.100, L - 0.002), (0.075, L)]
            for (x, y) in top { prof.append(V2(x * R / 0.175, y)) }
            prof.append(V2(0, L))
            m.add(Prim.lathe(prof, segments: detail ? 48 : 22, seamTile: 0.2, material: vinyl, swapUV: false))

            // Top cap collar: stitched disc.
            m.add(Prim.lathe([V2(0.0, L + 0.0008), V2(0.078, L + 0.0008), V2(0.082, L + 0.0035), V2(0.078, L + 0.006), V2(0, L + 0.006)],
                             segments: detail ? 32 : 14, seamTile: 0.1, material: "leather.black"))

            // Webbing bands.
            for yb: Float in [0.20, L - 0.20] {
                let rr = r(yb) + 0.0016
                m.add(Prim.lathe([V2(rr - 0.002, yb - 0.034), V2(rr + 0.0012, yb - 0.034), V2(rr + 0.0028, yb - 0.031), V2(rr + 0.0028, yb + 0.031),
                                  V2(rr + 0.0012, yb + 0.034), V2(rr - 0.002, yb + 0.034)],
                                 segments: detail ? 48 : 22, seamTile: 0.04, material: webbing, swapUV: false))
                if detail {
                    for dy: Float in [-0.026, 0.026] {
                        let ring = (0...72).map { k -> V3 in let a = Float(k) / 72 * 2 * .pi; return V3(cos(a) * (rr + 0.0029), yb + dy, sin(a) * (rr + 0.0029)) }
                        m.add(stitches(along: ring, normal: { V3($0.x, 0, $0.z) }, pitch: 0.012, thread: 0.0009, material: "thread.white"))
                    }
                }
            }

            // Vertical seam: welt and stitching on both sides.
            let seamA: Float = rng.float(0...(2 * .pi))
            func seamPoint(_ y: Float, _ da: Float, lift: Float) -> V3 {
                let a = seamA + da, rr = r(y) + lift
                return V3(cos(a) * rr, y, sin(a) * rr)
            }
            let ys = stride(from: Float(0.075), through: L - 0.06, by: 0.04).map { $0 }
            let weltPath = ys.map { seamPoint($0, 0, lift: 0.0006) }
            m.add(Prim.tube(weltPath, radii: weltPath.map { _ in 0.0028 }, sides: detail ? 6 : 4, seamTile: 0.03, material: vinyl))
            if detail {
                for da: Float in [-0.045, 0.045] {
                    let p = ys.map { seamPoint($0, da, lift: 0.0006) }
                    m.add(stitches(along: p, normal: { V3($0.x, 0, $0.z) }, pitch: 0.012, thread: 0.0009, material: "thread.white"))
                }
            }

            // Tape patch where the bag takes the most hits.
            let ty: Float = L * 0.55, tr = r(ty) + 0.0012
            m.add(Prim.lathe([V2(tr - 0.001, ty - 0.036), V2(tr + 0.0008, ty - 0.036), V2(tr + 0.0016, ty - 0.033), V2(tr + 0.0016, ty + 0.033),
                              V2(tr + 0.0008, ty + 0.036), V2(tr - 0.001, ty + 0.036)],
                             segments: detail ? 48 : 22, seamTile: 0.04, material: "fabric.webbing:E1DFD6"))

            // Four tabs with D-rings and four chains to the swivel.
            let ringR: Float = 0.118, ringY = L + 0.026
            let swivel = V3(0, L + chainRun, 0)
            for k in 0..<4 {
                let a = (Float(k) + 0.5) * .pi / 2 + rng.float(-0.02...0.02)
                let dir = V3(cos(a), 0, sin(a))
                // Webbing tab riding over the shoulder, from the band zone up and onto the cap.
                let pts: [V3] = [0.30, 0.42, 0.53, 0.63, 0.68].enumerated().map { (i, _) -> V3 in
                    let ys: [Float] = [L - 0.16, L - 0.095, L - 0.045, L - 0.012, L + 0.006]
                    let rs: [Float] = [r(L - 0.16) + 0.004, 0.173, 0.160, 0.140, ringR + 0.012]
                    return dir * rs[i] + V3(0, ys[i], 0)
                }
                m.add(Prim.sweep(Shape2D.roundedRect(0.036, 0.004, radius: 0.0012, segments: 2), along: catmull(pts, per: detail ? 4 : 2),
                                 up: simd_cross(dir, V3(0, 1, 0)), material: webbing))
                // D-ring through the tab loop.
                let ringC = dir * ringR + V3(0, ringY, 0)
                m.add(Prim.torus(major: 0.016, minor: 0.0034, segments: detail ? 14 : 8, sides: detail ? 6 : 4, material: steel),
                      Xform(translation: ringC, rotation: simd_quatf(from: V3(0, 1, 0), to: simd_normalize(simd_cross(dir, V3(0, 1, 0))))))
                // Chain from the D-ring top to the swivel plate.
                let a0 = ringC + V3(0, 0.013, 0), b0 = swivel + dir * 0.022 + V3(0, -0.012, 0)
                let pitch: Float = detail ? 0.019 : 0.026
                let count = max(2, Int(simd_distance(a0, b0) / pitch))
                let axis = (b0 - a0).normalized
                let link = Prim.torus(major: 0.0075, minor: 0.0017, segments: detail ? 8 : 5, sides: detail ? 4 : 3, material: steel)
                for j in 0..<count {
                    let p = a0 + (b0 - a0) * ((Float(j) + 0.5) / Float(count))
                    // Ring plane contains the chain axis; alternate links turn 90 degrees about it.
                    let n0 = simd_normalize(simd_cross(axis, dir))
                    let ny = simd_quatf(angle: Float(j % 2) * .pi / 2, axis: axis).act(n0)
                    let basis = simd_float3x3(axis, ny, simd_cross(axis, ny))
                    let q = simd_quatf(basis)
                    m.add(link, Xform(translation: p, rotation: q, scale: V3(1.55, 1, 1)))
                }
            }

            // Swivel: plate, ball-bearing barrel and a hook.
            m.add(Prim.cylinder(radius: 0.034, height: 0.006, bevel: 0.0018, segments: detail ? 24 : 12, material: steel),
                  Xform(translation: swivel + V3(0, -0.006, 0)))
            m.add(Prim.cylinder(radius: 0.011, height: 0.030, bevel: 0.003, segments: detail ? 16 : 8, material: "metal.chrome"),
                  Xform(translation: swivel))
            m.add(Prim.cylinder(radius: 0.0165, height: 0.008, bevel: 0.002, segments: detail ? 16 : 8, material: "metal.chrome"),
                  Xform(translation: swivel + V3(0, 0.012, 0)))
            m.add(Prim.torus(major: 0.019, minor: 0.0042, segments: detail ? 22 : 10, sides: detail ? 8 : 4, arc: 1.7 * .pi, material: "metal.chrome"),
                  Xform(translation: swivel + V3(0, 0.050, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0)) * simd_quatf(degrees: 20, axis: .up)))

            groundAO(&m, height: 0.3, floor: 0.7)
            levels.append(m)
        }
        return LODModel(levels: levels, switchDistances: [4])
    }
}
