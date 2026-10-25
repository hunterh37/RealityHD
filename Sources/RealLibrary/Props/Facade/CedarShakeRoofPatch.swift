import simd
import Foundation

/// Cedar shake roof patch: Shingle Style, a 1.5 x 1.5 m cut section of hand-split 450 mm cedar shakes laid in eight
/// courses with a doubled starter, keyed random widths, 6 mm gaps and a 190 mm exposure over felt interlay, stepped
/// battens and plank sheathing. A galvanized drip edge with a hemmed lip runs along the eave. Age is in the wood:
/// silvered shakes, split grain, curled butts, moss in the lower courses, two fresh replacement shakes with copper
/// nails and rust runs from the old galvanized ring-shank nails on the top course.
public struct CedarShakeRoofPatch: RealAsset {
    public static let id = "cedar-shake-roof-patch"
    public static let summary = "Cedar shake roof patch, 1.5 x 1.5 m: tapered hand-split shakes in staggered courses on battens and felt, galvanized drip edge, replacement shakes, curled and split shakes, moss."
    public static let tags = ["prop", "architecture", "facade", "roofline", "roof", "wood"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 2.4)

    /// Patch width and depth in meters.
    public var side: Float = 1.5
    /// Shake length in meters.
    public var shakeLength: Float = 0.45
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let half = side / 2
        let exposure: Float = 0.19
        let courses = 8
        let step: Float = 0.0105
        func Z(_ u: Float) -> Float { half - u }
        let galv: MaterialKey = "metal.galvanized-aged"
        let copper: MaterialKey = "metal.copper-patina"
        let tints = ["9C8A74", "857463", "A89580", "6E6459", "8F7C68", "B3A18A", "786B5E", "8C877D", "9A826C", "5F574E", "A39E94", "7A756C", "968C7E"]

        // Plank sheathing, spaced 1x6 boards, with nail heads at the ends.
        let nB = 11
        let bw = side / Float(nB)
        for k in 0..<nB {
            var r = rng.fork(10 + k)
            let z = half - (Float(k) + 0.5) * bw
            m.add(Prim.roundedBox(V3(side, 0.015, bw - 0.004), radius: 0.0015, bevelSegments: 1, material: r.chance(0.3) ? "wood.pine-aged" : "wood.lumber-pine"),
                  Xform(translation: V3(r.float(-0.003...0.003), 0.0075, z)))
            for ex: Float in [-1, 1] {
                RK.plate(&m, V3(0.006, 0.0008, 0.006), V3(ex * (half - 0.03), 0.0158, z + r.float(-0.015...0.015)), "metal.cast-iron")
            }
        }
        // Felt underlayment with lapped joints.
        FA.box(&m, V3(side - 0.012, 0.0012, side - 0.02), V3(0, 0.0156, 0), "roofing.shingle-granule:1E1E20", r: 0.0003)
        for k in 1..<4 {
            RK.plate(&m, V3(side - 0.012, 0.0006, 0.004), V3(0, 0.0166, half - Float(k) * 0.37), "roofing.shingle-granule:2A2A2D")
        }
        // Stepped battens, one solid timber riser per course, with a felt interlay strip on each riser.
        let base: Float = 0.0162
        for i in 0..<courses {
            let u0 = i == 0 ? 0.0 : -0.02 + Float(i) * exposure
            let u1 = i == courses - 1 ? side : -0.02 + Float(i + 1) * exposure
            let top = 0.026 + Float(i) * step
            let hgt = top - base
            FA.box(&m, V3(side - 0.02, hgt, u1 - u0 - 0.002), V3(0, base + hgt / 2, (Z(u0) + Z(u1)) / 2), i % 2 == 0 ? "wood.lumber-pine" : "wood.pine-aged", r: 0.0015)
            RK.plate(&m, V3(side - 0.024, 0.0008, 0.05), V3(0, top - 0.0006, Z(u0) - 0.03), "roofing.shingle-granule:1E1E20")
        }

        // Shake rows: random widths 0.09-0.20, staggered, 6 mm gaps.
        var rows: [[(x0: Float, x1: Float)]] = []
        for i in 0..<courses {
            var xs = -half + 0.004
            var row: [(x0: Float, x1: Float)] = []
            var k = 0
            var first = true
            while xs < half - 0.01 {
                var r = rng.fork(1000 + i * 40 + k)
                var w = r.float(0.09...0.2)
                if first { w = 0.06 + Float((i * 29) % 9) * 0.017; first = false }
                let x1 = min(xs + w, half - 0.004)
                if x1 - xs < 0.045 { break }
                row.append((xs, x1))
                xs = x1 + 0.006
                k += 1
            }
            rows.append(row)
        }
        // Tapered shake: local x runs up-slope from the butt (x = 0), y up, depth along Z becomes the width.
        func shake(_ w: Float, _ len: Float, _ butt: Float, _ head: Float, _ mat: MaterialKey) -> Surface {
            let pts: [V2] = [V2(0, 0), V2(len, 0), V2(len, head), V2(len * 0.5, head + (butt - head) * 0.55), V2(0.012, butt - 0.0006), V2(0, butt - 0.003)]
            return Prim.extrude(pts, depth: w, bevel: 0.0012, bevelSegments: 1, material: mat)
        }
        let rotY = simd_quatf(angle: .pi / 2, axis: FA.Y)
        let newC = [(2, 3), (5, 1)]
        let curlC = (4, 2), splitC = (3, 4), mossStart = 2
        for i in 0..<courses {
            let uT = i == 0 ? 0.0 : -0.02 + Float(i) * exposure
            let len = min(shakeLength, side - uT - 0.0)
            let hBase = 0.026 + Float(i) * step
            for (k, sk) in rows[i].enumerated() {
                var r = rng.fork(2000 + i * 40 + k)
                let w = sk.x1 - sk.x0
                let xc = (sk.x0 + sk.x1) / 2
                let isNew = newC.contains { $0.0 == i && $0.1 == k }
                let curled = (i == curlC.0 && k == curlC.1)
                let split = (i == splitC.0 && k == splitC.1)
                let tint = isNew ? "D0A070" : (i < 2 && r.chance(0.55) ? r.pick(["4F473F", "5A5248", "463F38"]) : r.pick(tints))
                let mat: MaterialKey = "wood.lumber-cedar:" + tint
                let butt = r.float(0.013...0.017) + (curled ? 0.002 : 0)
                let head: Float = 0.0035
                let uStart = uT + r.float(-0.005...0.005)
                var rot = rotY * simd_quatf(angle: r.float(-0.004...0.004), axis: FA.X)
                var lift: Float = 0
                if curled { rot = simd_quatf(angle: -0.05, axis: FA.X) * rot; lift = 0.0015 }
                if split {
                    // Split shake: two halves with a 9 mm open crack that shows the felt.
                    let wl = w * 0.58 - 0.0045, wr = w * 0.42 - 0.0045
                    m.add(shake(wl, len, butt, head, mat), Xform(translation: V3(sk.x0 + wl / 2, hBase, Z(uStart)), rotation: rot))
                    m.add(shake(wr, len, butt - 0.001, head, mat), Xform(translation: V3(sk.x1 - wr / 2, hBase, Z(uStart)), rotation: rot))
                    RK.plate(&m, V3(0.0085, 0.0008, len * 0.6), V3(sk.x0 + w * 0.58, hBase - 0.0003, Z(uStart + len * 0.3)), "roofing.shingle-granule:101012")
                } else {
                    m.add(shake(w, len, butt, head, mat), Xform(translation: V3(xc, hBase + lift, Z(uStart)), rotation: rot))
                }
                let topY = hBase + butt + lift
                // Dark kerf shadow under each gap and a butt-end grain line.
                RK.plate(&m, V3(0.005, 0.0006, 0.11), V3(sk.x1 + 0.003, hBase + 0.0004, Z(uStart + 0.06)), "roofing.shingle-granule:0E0E10")
                if !isNew {
                    RK.plate(&m, V3(w - 0.006, 0.0006, 0.0035), V3(xc, topY + 0.0009, Z(uStart + 0.003)), "wood.cedar-weathered:4F4338")
                }
                // Hand-split grain: long raised streaks along the slope, light and dark.
                let nG = r.int(2...4)
                for q in 0..<nG {
                    let gx = sk.x0 + (Float(q) + 0.5) * w / Float(nG) + r.float(-0.008...0.008)
                    let gu = r.float(0.02...0.1)
                    let gl = min(r.float(0.12...0.3), len - gu - 0.02)
                    let thickAt = butt - (butt - head) * (gu + gl / 2) / len
                    RK.plate(&m, V3(r.float(0.0015...0.003), 0.0006, gl), V3(gx, hBase + thickAt * 0.98 + lift + 0.0003, Z(uStart + gu + gl / 2)),
                             r.chance(0.5) ? "wood.cedar-weathered:4D4238" : "wood.cedar-weathered:B5A28C")
                }
                // Weathering: moss and algae on the lower courses, lichen elsewhere.
                if i < mossStart + 1 && r.chance(0.8) {
                    for _ in 0..<r.int(1...3) {
                        let mt = r.float(0.04...0.2)
                        let ty = butt - (butt - head) * mt / len
                        m.add(Prim.superellipsoid(V3(r.float(0.025...0.055), 0.006, r.float(0.02...0.04)), exponent: 2.4, subdivisions: 1, material: r.chance(0.6) ? "roofing.shingle-granule:5E7A3A" : "concrete.river-algae"),
                              Xform(translation: V3(xc + r.float(-w / 2.6...w / 2.6), hBase + ty + lift, Z(uStart + mt)), rotation: simd_quatf(angle: r.float(0...3), axis: FA.Y)))
                    }
                } else if r.chance(0.18) {
                    m.add(Prim.superellipsoid(V3(r.float(0.012...0.03), 0.0014, r.float(0.01...0.025)), exponent: 2, subdivisions: 2, material: "roofing.shingle-granule:8D917C"),
                          Xform(translation: V3(xc + r.float(-w / 3...w / 3), hBase + butt * 0.5 + 0.0015, Z(uStart + r.float(0.1...0.3))), rotation: simd_quatf(angle: r.float(0...3), axis: FA.Y)))
                }
                // Rust runs from nails below the next course.
                if !isNew && r.chance(0.22) {
                    RK.plate(&m, V3(0.005, 0.0006, r.float(0.04...0.1)), V3(xc + r.float(-w / 3...w / 3), hBase + butt * 0.5 + 0.0012, Z(uStart + 0.15)), "metal.rust-grime")
                }
                // Top course: face nails, two per shake, ring-shank galvanized.
                if i == courses - 1 || isNew {
                    let ny = i == courses - 1 ? Z(side - 0.03) : Z(uStart + 0.14)
                    let h = i == courses - 1 ? hBase + 0.0035 : hBase + butt * 0.65 - 0.002
                    for nx: Float in [-0.28, 0.28] {
                        m.add(Prim.cylinder(radius: 0.0034, height: 0.0014, bevel: 0.0006, segments: 8, bevelSegments: 1, material: isNew ? copper : galv),
                              Xform(translation: V3(xc + nx * w, h, ny)))
                        if !isNew {
                            RK.plate(&m, V3(0.004, 0.0005, 0.03), V3(xc + nx * w, h + 0.0016, ny + 0.017), "metal.rust-grime")
                        }
                    }
                }
            }
        }
        // Galvanized drip edge with a hemmed lip along the eave.
        FA.box(&m, V3(side - 0.012, 0.0016, 0.036), V3(0, 0.0178, Z(0) - 0.004), galv, r: 0.0005)
        FA.box(&m, V3(side - 0.012, 0.022, 0.0016), V3(0, 0.0058, Z(0) + 0.0), galv, r: 0.0005)
        FA.box(&m, V3(side - 0.012, 0.0045, 0.006), V3(0, 0.0018, Z(0) - 0.004), galv, r: 0.002)
        for k in 0..<7 {
            let x = -half + 0.06 + Float(k) * (side - 0.12) / 6
            m.add(Prim.cylinder(radius: 0.0032, height: 0.0014, bevel: 0.0006, segments: 8, bevelSegments: 1, material: "metal.cast-iron"),
                  Xform(translation: V3(x, 0.0186, Z(0) - 0.008)))
        }
        // Cut edge on -x: sheathing and felt ends show.
        for i in 0..<courses {
            RK.plate(&m, V3(0.0008, 0.008, 0.1), V3(-half + 0.0006, 0.026 + Float(i) * step + 0.0045, Z(-0.02 + Float(i) * exposure + 0.1)), "concrete.sealed-dim")
        }
        groundAO(&m, height: 0.05, floor: 0.85)
        return LODModel(m)
    }
}
