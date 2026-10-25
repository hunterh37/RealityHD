import simd
import Foundation

/// Slate roof patch: Victorian Welsh slate, a 1.5 x 1.5 m cut section laid in seven courses of random-width 500 mm
/// slates with a 75 mm head lap, on stepped battens, black felt and plank sarking. A lead soaker with copper clout
/// nails runs down one edge. Repairs and decay tell the story: three clean replacement slates, a slipped slate
/// that exposes felt and nails, a cracked slate with a missing corner, a lead tingle, lichen, moss and rust runs.
public struct SlateRoofPatch: RealAsset {
    public static let id = "slate-roof-patch"
    public static let summary = "Slate roof patch, 1.5 x 1.5 m: random-width Welsh slates in lapped courses on battens, felt and sarking, with a lead soaker, replacement, slipped and cracked slates."
    public static let tags = ["prop", "architecture", "facade", "roofline", "roof"]
    public static let budget = 15_000
    public static let author = "realityhd"

    /// Patch width and depth in meters.
    public var side: Float = 1.5
    /// Slate length in meters.
    public var slateLength: Float = 0.5
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let half = side / 2
        let exposure: Float = 0.2125
        let courses = 7
        let step: Float = 0.009
        let thick: Float = 0.010
        // Position on the patch: x across, u up-slope from the eave (u = 0 at z = +half), height y.
        func Z(_ u: Float) -> Float { half - u }
        let lead: MaterialKey = "metal.powdercoat:4A4E52"
        let copper: MaterialKey = "metal.copper-patina"
        let tints = ["575C65", "4F545C", "62656B", "5A5E66", "6A6C72", "4A4F57", "5F5A66", "666A70", "545A62"]

        // Plank sarking boards across the patch with felt on top and shims under each course's batten.
        let nB = 11
        let bw = side / Float(nB)
        for k in 0..<nB {
            var r = rng.fork(10 + k)
            let z = half - (Float(k) + 0.5) * bw
            m.add(Prim.roundedBox(V3(side, 0.015, bw - 0.004), radius: 0.0015, bevelSegments: 1, material: r.chance(0.3) ? "wood.pine-aged" : "wood.cedar-weathered"),
                  Xform(translation: V3(r.float(-0.003...0.003), 0.0075, z)))
            // Nail heads in the board ends.
            for ex: Float in [-1, 1] {
                RK.plate(&m, V3(0.006, 0.0008, 0.006), V3(ex * (half - 0.03), 0.0158, z + r.float(-0.015...0.015)), "metal.cast-iron")
            }
        }
        // Black felt with a torn edge at the eave and lapped joints.
        FA.box(&m, V3(side - 0.012, 0.0012, side - 0.02), V3(0, 0.0156, 0), "roofing.shingle-granule:1E1E20", r: 0.0003)
        for k in 1..<4 {
            RK.plate(&m, V3(side - 0.012, 0.0006, 0.004), V3(0, 0.0166, half - Float(k) * 0.37), "roofing.shingle-granule:2A2A2D")
        }

        // Stepped counter-batten blocks: one solid timber step per course carries the slate heads, with a felt lap on each riser.
        for i in 0..<courses {
            let u0 = i == 0 ? 0.0 : -0.012 + Float(i) * exposure
            let u1 = i == courses - 1 ? side : -0.012 + Float(i + 1) * exposure
            let top = 0.016 + 0.014 + Float(i) * step
            let hgt = top - 0.0162
            let zc = (Z(u0) + Z(u1)) / 2
            FA.box(&m, V3(side - 0.02, hgt, u1 - u0 - 0.002), V3(0, 0.0162 + hgt / 2, zc), i % 2 == 0 ? "wood.lumber-pine" : "wood.pine-aged", r: 0.0015)
            RK.plate(&m, V3(side - 0.024, 0.0008, 0.006), V3(0, top - 0.004, Z(u0) - 0.0005), "roofing.shingle-granule:1E1E20")
        }

        // Slates: random widths 0.2-0.32 m, staggered joints, 3 mm gaps.
        let slipC = 3, slipK = 2
        var slateLog: [[(x0: Float, x1: Float)]] = []
        for i in 0..<courses {
            var xs = -half + 0.004
            var row: [(x0: Float, x1: Float)] = []
            var k = 0
            var first = true
            while xs < half - 0.01 {
                var r = rng.fork(1000 + i * 40 + k)
                var w = r.float(0.2...0.32)
                if first {
                    // Start with a partial slate so joints stagger between courses.
                    w = 0.12 + Float((i * 37) % 11) * 0.019
                    first = false
                }
                let x1 = min(xs + w, half - 0.004)
                if x1 - xs < 0.07 { break }
                row.append((xs, x1))
                xs = x1 + 0.004
                k += 1
            }
            slateLog.append(row)
        }
        for i in 0..<courses {
            let uT = -0.012 + Float(i) * exposure
            let len = min(slateLength, side - uT - 0.0)
            let hBase = 0.016 + 0.014 + Float(i) * step
            for (k, sl) in slateLog[i].enumerated() {
                var r = rng.fork(2000 + i * 40 + k)
                let w = sl.x1 - sl.x0
                let xc = (sl.x0 + sl.x1) / 2
                let isNew = (i == 1 && k == 3) || (i == 3 && k == 4) || (i == 5 && k == 1)
                let slipped = (i == slipC && k == slipK)
                let cracked = (i == 2 && k == 1)
                let tint = isNew ? "92969B" : r.pick(tints)
                let mat: MaterialKey = "stone.slate:" + tint
                var dz: Float = 0, dh: Float = 0
                var rotQ = simd_quatf(angle: r.float(-0.004...0.004), axis: FA.Y) * simd_quatf(angle: r.float(-0.008...0.018), axis: FA.X)
                if slipped {
                    dz = 0.11; dh = -0.001
                    rotQ = simd_quatf(angle: 0.035, axis: FA.Y) * simd_quatf(angle: 0.02, axis: FA.X)
                }
                let uStart = uT + r.float(-0.003...0.003) + dz
                let t = slipped ? len - 0.0 : len
                let zc = Z(uStart + t / 2)
                // Slates are cut square at the head; the top course is clipped at the patch edge.
                m.add(Prim.roundedBox(V3(w, thick + (isNew ? 0.001 : 0), t), radius: 0.0012, bevelSegments: 1, material: mat),
                      Xform(translation: V3(xc, hBase + thick / 2 + dh + r.float(0...0.0008), zc), rotation: rotQ))
                // Tail face bevel strip: lighter edge where the slate is split, darker on old slates.
                RK.plate(&m, V3(w - 0.004, 0.0008, 0.004), V3(xc, hBase + thick + dh + 0.0047, Z(uStart + 0.002)), isNew ? "stone.slate:9A9DA2" : "stone.slate:3E434A", rot: rotQ)
                // Cracked slate: diagonal crack with a gap line, plus a missing corner showing felt below.
                if cracked {
                    for q in 0..<5 {
                        RK.plate(&m, V3(0.0032, 0.0009, 0.05), V3(xc - 0.05 + Float(q) * 0.021, hBase + thick + 0.0049, Z(uStart + 0.06 + Float(q) * 0.037)),
                                 "roofing.shingle-granule:101012", rot: simd_quatf(angle: 0.55, axis: FA.Y))
                    }
                    RK.plate(&m, V3(0.11, 0.0016, 0.11), V3(xc + w / 2 - 0.05, hBase + thick + 0.0047, Z(uStart + 0.035)), "roofing.shingle-granule:1E1E20", rot: simd_quatf(angle: 0.78, axis: FA.Y))
                }
                // Weathering per slate: lichen rosettes, moss at tails, rust runs from iron nails.
                if r.chance(0.4) {
                    for _ in 0..<r.int(1...3) {
                        let lw = r.float(0.012...0.04), ld = r.float(0.01...0.03)
                        m.add(Prim.superellipsoid(V3(lw, 0.0016, ld), exponent: 2, subdivisions: 2, material: r.pick(["roofing.shingle-granule:7E8A66", "roofing.shingle-granule:8D917C", "roofing.shingle-granule:6C7A5A", "roofing.shingle-granule:9A9A88"])),
                              Xform(translation: V3(xc + r.float(-w / 2 + 0.03...w / 2 - 0.03), hBase + thick + dh + 0.0045, Z(uStart + r.float(0.02...exposure - 0.02))), rotation: simd_quatf(angle: r.float(0...3), axis: FA.Y)))
                    }
                }
                if i < 2 && r.chance(0.6) {
                    RK.plate(&m, V3(r.float(0.03...0.08), 0.0008, r.float(0.01...0.03)), V3(xc + r.float(-0.05...0.05), hBase + thick + dh + 0.0053, Z(uStart + r.float(0.005...0.04))), "concrete.river-algae")
                }
                if r.chance(0.18) {
                    RK.plate(&m, V3(0.006, 0.0006, r.float(0.05...0.12)), V3(xc + r.float(-w / 3...w / 3), hBase + thick + dh + 0.0052, Z(uStart + 0.07)), "metal.rust-grime")
                }
                // Top course is face-nailed at the cut head: two copper nails with lead dots per slate.
                if i == courses - 1 {
                    for nx: Float in [-0.35, 0.35] {
                        let px = xc + nx * w
                        m.add(Prim.cylinder(radius: 0.0038, height: 0.0022, bevel: 0.0009, segments: 8, bevelSegments: 1, material: lead),
                              Xform(translation: V3(px, hBase + thick + dh, Z(side - 0.03))))
                        m.add(Prim.cylinder(radius: 0.0022, height: 0.0016, bevel: 0.0007, segments: 6, bevelSegments: 1, material: copper),
                              Xform(translation: V3(px, hBase + thick + dh + 0.0051, Z(side - 0.03))))
                    }
                }
                // Slipped slate: exposed felt strip and two copper nails left in the batten above.
                if slipped {
                    RK.plate(&m, V3(w, 0.0016, 0.11), V3(xc, hBase + 0.0004, Z(uT + 0.055)), "roofing.shingle-granule:101012")
                    for nx: Float in [-0.07, 0.07] {
                        m.add(Prim.cylinder(radius: 0.0022, height: 0.012, bevel: 0.0006, segments: 6, bevelSegments: 1, material: copper),
                              Xform(translation: V3(xc + nx, hBase, Z(uT + 0.006))))
                    }
                }
                // Replacement slates carry a lead tingle strap with a copper nail at the tail.
                if isNew {
                    FA.box(&m, V3(0.022, 0.0016, 0.15), V3(xc, hBase + thick + 0.0049, Z(uStart + 0.075)), lead, r: 0.0005)
                    FA.box(&m, V3(0.022, 0.003, 0.012), V3(xc, hBase + thick + 0.0059, Z(uStart + 0.152)), lead, r: 0.0006)
                    m.add(Prim.cylinder(radius: 0.0024, height: 0.0014, bevel: 0.0006, segments: 8, bevelSegments: 1, material: copper),
                          Xform(translation: V3(xc, hBase + thick + 0.0057, Z(uStart + 0.06))))
                }
            }
        }

        // Lead soaker down the +x edge: apron over the last slates with copper clout nails and lap joints.
        let xL = half - 0.07
        let leadH = 0.016 + 0.014 + Float(courses - 1) * step + thick
        FA.box(&m, V3(0.12, 0.0014, side - 0.03), V3(xL, 0.016 + 0.014 + 0.0 + 0.0, 0.0), lead, r: 0.0005)
        for k in 0..<courses {
            let hh = 0.016 + 0.014 + Float(k) * step + thick + 0.0016
            let u0 = -0.012 + Float(k) * exposure
            FA.box(&m, V3(0.12, 0.0016, exposure - 0.004), V3(xL, hh, Z(u0 + exposure / 2 + 0.02)), lead, r: 0.0006)
            // Clout nails along the inner edge, two per step.
            for j in 0..<3 {
                let z = Z(u0 + 0.03 + Float(j) * 0.07)
                m.add(Prim.cylinder(radius: 0.0034, height: 0.0016, bevel: 0.0008, segments: 8, bevelSegments: 1, material: copper),
                      Xform(translation: V3(xL - 0.05, hh + 0.0008, z)))
            }
            // Lead dressing over the edge, with a darker oxide patch.
            RK.plate(&m, V3(0.05, 0.0004, exposure - 0.03), V3(xL + 0.02, hh + 0.0009, Z(u0 + 0.12)), "metal.powdercoat:33363A")
        }
        _ = leadH
        // Cut edges on the -x side: sarking, felt and batten ends show; a few dark drip stains on the slate stack.
        for i in 0..<courses {
            RK.plate(&m, V3(0.0008, 0.006, 0.12), V3(-half + 0.0006, 0.016 + 0.014 + Float(i) * step + thick + 0.0, Z(-0.012 + Float(i) * exposure + 0.1)), "concrete.sealed-dim")
        }

        groundAO(&m, height: 0.05, floor: 0.85)
        return LODModel(m)
    }
}
