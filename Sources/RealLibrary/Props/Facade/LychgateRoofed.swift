import simd
import Foundation

/// Lychgate roofed: architectural facade customizer, English Churchyard. Parts: four oak posts, tie beams, king post truss, ridge beam, roof rafters, clay or slate roof, bargeboards, coffin rest bench, stone sill plinth, swing gates.
public struct LychgateRoofed: RealAsset {
    public static let id = "lychgate-roofed"
    public static let summary = "English churchyard timber lychgate, oak frame on stone sills, steep gabled roof with coffin rest"
    public static let tags = ["prop", "architecture", "facade", "wood", "trim"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(2.0, 2.8, 3.0)
    public init() {}

    /// Silvered oak for the exposed frame.
    public var oak: MaterialKey = "wood.weathered"
    /// Fresh oak for the replaced brace, pegs and gate leaves.
    public var freshOak: MaterialKey = "wood.oak"
    /// Clay peg tiles.
    public var tile: MaterialKey = "ceramic.terracotta"
    /// Stone sills and paving.
    public var stone: MaterialKey = "stone.sandstone"
    /// Floor flags.
    public var flags: MaterialKey = "stone.slate"
    /// Moss and lichen.
    public var moss: MaterialKey = "stone.granite-moss"
    /// Wrought ironmongery.
    public var iron: MaterialKey = "metal.wrought-iron"

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let H = size.y
        let px: Float = 0.66, pz: Float = 1.15, pw: Float = 0.16
        let eaveTop: Float = 1.74, ridgeTop: Float = H - 0.06      // tile surface: y = ridgeTop - |x|
        let sillH: Float = 0.3, postTop: Float = 1.70
        // Stone sills under each post, then the flagged floor.
        for sx in [-1, 1] as [Float] { for sz in [-1, 1] as [Float] {
            FA.box(&m, V3(0.32, sillH, 0.32), V3(sx * px, sillH / 2, sz * pz), stone, r: 0.006)
            FA.box(&m, V3(0.34, 0.03, 0.34), V3(sx * px, 0.015, sz * pz), "stone.limestone-sooted", r: 0.004)
            // Dowel stub where the post meets the sill.
            FA.box(&m, V3(pw + 0.02, 0.02, pw + 0.02), V3(sx * px, sillH + 0.01, sz * pz), "metal.rust-grime", r: 0.003)
        } }
        var z0: Float = -1.28
        for k in 0..<4 {
            let l: Float = [0.74, 0.62, 0.80, 0.58][k]
            FA.box(&m, V3(1.0, 0.045, l - 0.012), V3(0, 0.0225, z0 + l / 2), flags, r: 0.004)
            z0 += l
        }
        // Posts with chamfered arrises and a peg through each head.
        for sx in [-1, 1] as [Float] { for sz in [-1, 1] as [Float] {
            FA.box(&m, V3(pw, postTop - sillH - 0.02, pw), V3(sx * px, (postTop + sillH + 0.02) / 2, sz * pz), oak, r: 0.012)
            FA.rod(&m, V3(sx * px - 0.1, 1.6, sz * pz), V3(sx * px + 0.1, 1.6, sz * pz), r: 0.01, freshOak, sides: 6)
        } }
        // Wall plates along Z and tie beams across X (z = +-pz and mid span).
        for sx in [-1, 1] as [Float] {
            FA.box(&m, V3(0.14, 0.14, 2 * pz + 0.35), V3(sx * px, 1.76, 0), oak, r: 0.008)
        }
        for z in [-pz, 0, pz] as [Float] {
            FA.box(&m, V3(2 * px + 0.2, 0.18, 0.14), V3(0, 1.6, z), oak, r: 0.008)
            // King post, ridge-bearing, with a small stub.
            FA.box(&m, V3(0.12, ridgeTop - 0.26 - 1.69, 0.12), V3(0, (ridgeTop - 0.26 + 1.69) / 2, z), oak, r: 0.008)
            // Collar between the principal rafters.
            FA.box(&m, V3(0.5, 0.1, 0.09), V3(0, 2.36, z), oak, r: 0.006)
        }
        // Knee braces from the posts into the tie beams (and into the plates along Z).
        for sx in [-1, 1] as [Float] { for sz in [-1, 1] as [Float] {
            let fresh = sx > 0 && sz > 0
            FA.box(&m, V3(0.09, 0.55, 0.09), V3(sx * (px - 0.28), 1.32, sz * pz), fresh ? freshOak : oak, r: 0.006, rot: FA.q(sx * 45, FA.Z))
            FA.box(&m, V3(0.09, 0.55, 0.09), V3(sx * px, 1.32, sz * (pz - 0.28)), oak, r: 0.006, rot: FA.q(-sz * 45, FA.X))
        } }
        // Ridge beam on the king posts.
        FA.box(&m, V3(0.1, 0.14, 2 * pz + 0.5), V3(0, ridgeTop - 0.19, 0), oak, r: 0.006)
        // Roof: each slope is rafters, sheathing and clay tile courses, all parallel to the slope.
        let L: Float = 1.4142 + 0.05
        for side in [-1, 1] as [Float] {
            let d = V3(-side, 1, 0) / 1.4142, n = V3(side, 1, 0) / 1.4142
            let eave = V3(side * 0.98, eaveTop, 0), mid = eave + d * (L / 2 - 0.03)
            let rot = FA.q(side > 0 ? 135 : 45, FA.Z)
            for k in 0..<5 {
                FA.box(&m, V3(L, 0.09, 0.07), mid - n * 0.115 + V3(0, 0, -1.2 + Float(k) * 0.6), oak, r: 0.004, rot: rot)
            }
            m.add(Prim.roundedBox(V3(L, 0.03, 3.0), radius: 0.003, bevelSegments: 1, material: freshOak), Xform(translation: mid - n * 0.055, rotation: rot))
            // Tile courses (peg tiles laid to a 115 mm gauge) with staggered perpends.
            let courses = 12
            for c in 0..<courses {
                var r = rng.fork(c + 10 * (side > 0 ? 1 : 0))
                let center = eave + d * (0.075 + Float(c) * 0.1155) - n * (0.007 - Float(c % 2) * 0.0015)
                FG.slab(&m, V3(0.155, 0.014, 3.0), center, tile, rot: rot)
                var z: Float = -1.5 + (c % 2 == 0 ? 0.0 : 0.165)
                while z < 1.5 {
                    z += 0.33
                    if z > 1.49 { break }
                    FG.slab(&m, V3(0.155, 0.015, 0.003), center + n * 0.0004 + V3(0, 0, z), "wood.charred", rot: rot)
                }
                // Cracked or slipped tile and lichen on some courses.
                if r.chance(0.0) {
                    FG.slab(&m, V3(0.08, 0.0155, r.float(0.05...0.1)), center + n * 0.0006 + V3(0, 0, r.float(-1.3...1.3)), "stone.limestone-sooted", rot: rot)
                }
            }
            // Bargeboards at both gables, with peg heads, and a pendant finial at the apex.
            for e in [-1, 1] as [Float] {
                FA.box(&m, V3(L + 0.02, 0.2, 0.03), mid - n * 0.11 + V3(0, 0, e * 1.485), oak, r: 0.004, rot: rot)
                for k in 0..<3 {
                    FC.bead(&m, r: 0.008, at: eave + d * (0.3 + Float(k) * 0.4) - n * 0.11 + V3(0, 0, e * 1.5), freshOak, sub: 1)
                }
            }
        }
        // Ridge hat tiles and apex finials.
        let hat: [V2] = [V2(-0.11, -0.005), V2(-0.02, 0.055), V2(0.02, 0.055), V2(0.11, -0.005), V2(0.095, -0.012), V2(0.0, 0.04), V2(-0.095, -0.012)]
        m.add(Prim.extrude(hat, depth: 3.0, bevel: 0.003, bevelSegments: 1, material: tile), Xform(translation: V3(0, ridgeTop - 0.005, 0)))
        for e in [-1, 1] as [Float] {
            FA.rod(&m, V3(0, ridgeTop - 0.06, e * 1.47), V3(0, ridgeTop - 0.34, e * 1.47), r: 0.012, oak, sides: 8)
            FC.bead(&m, r: 0.024, at: V3(0, ridgeTop - 0.36, e * 1.47), oak, sub: 3)
        }
        // Ledged and braced oak gates between the front posts (z = +pz), hinged on the posts.
        let gz = pz + 0.0, inner = px - pw / 2
        for side in [-1, 1] as [Float] {
            let lw = inner - 0.012
            for k in 0..<5 {
                let pwid = lw / 5
                let x = side * (0.012 + (Float(k) + 0.5) * pwid)
                var r = rng.fork(100 + k + (side > 0 ? 7 : 0))
                FA.box(&m, V3(pwid - 0.004, 1.22 + r.float(-0.004...0.004), 0.034), V3(x, 0.72, gz + 0.005), freshOak, r: 0.003)
            }
            for y in [0.22, 0.72, 1.22] as [Float] {
                FA.box(&m, V3(lw, 0.11, 0.03), V3(side * (0.012 + lw / 2), y, gz - 0.025), freshOak, r: 0.003)
            }
            // Diagonal brace from the hinge foot up to the latch head.
            FA.box(&m, V3(0.1, 1.1, 0.028), V3(side * (0.012 + lw / 2), 0.72, gz - 0.054), freshOak, r: 0.003, rot: FA.q(side * -25, FA.Z))
            // Strap hinges across the face and a ring latch.
            for y in [0.22, 1.22] as [Float] {
                FG.strapHinge(&m, at: V3(side * (inner - 0.006), y, gz + 0.03), length: 0.42, dirX: -side, w: 0.036, iron)
            }
        }
        m.add(Prim.torus(major: 0.03, minor: 0.005, segments: 16, sides: 6, material: iron), Xform(translation: V3(0.05, 0.75, gz + 0.045), rotation: FA.q(90, FA.X)))
        FA.box(&m, V3(0.05, 0.05, 0.01), V3(0.05, 0.78, gz + 0.026), iron, r: 0.003)
        // Coffin-rest benches along the inside of both side walls.
        for sx in [-1, 1] as [Float] {
            FA.box(&m, V3(0.3, 0.05, 1.7), V3(sx * 0.4, 0.47, -0.05), oak, r: 0.006)
            for z in [-0.75, 0.65] as [Float] {
                FA.box(&m, V3(0.06, 0.45, 0.08), V3(sx * 0.4, 0.225, z), oak, r: 0.004)
                FA.box(&m, V3(0.3, 0.05, 0.06), V3(sx * 0.4, 0.42, z), oak, r: 0.004)
            }
        }
        // Weathering: moss at the sills, soot under the eaves.
        for k in 0..<6 {
            var r = rng.fork(200 + k)
            let sx: Float = r.chance(0.5) ? -1 : 1, sz: Float = r.chance(0.5) ? -1 : 1
            FG.slab(&m, V3(r.float(0.05...0.12), r.float(0.04...0.1), 0.004), V3(sx * px + r.float(-0.1...0.1), 0.05, sz * pz + (sz * 0.162)), moss)
        }
        // Water staining: dark runs down the posts from the plate joints and a damp band at the gate foot.
        for sx in [-1, 1] as [Float] { for sz in [-1, 1] as [Float] {
            var r = rng.fork(300 + Int(sx * 2 + sz))
            FG.slab(&m, V3(0.02, r.float(0.3...0.6), 0.004), V3(sx * px + r.float(-0.05...0.05), 1.35, sz * pz + sz * (pw / 2 + 0.002)), "wood.charred")
            FG.slab(&m, V3(0.16, r.float(0.1...0.18), 0.004), V3(sx * px, sillH + 0.12, sz * pz + sz * (pw / 2 + 0.002)), "wood.charred")
        } }
        FG.slab(&m, V3(1.1, 0.12, 0.004), V3(0, 0.1, pz + 0.0215), "wood.charred")
        groundAO(&m, height: 0.2, floor: 0.5)
        return LODModel(FC.place(m))
    }
}
