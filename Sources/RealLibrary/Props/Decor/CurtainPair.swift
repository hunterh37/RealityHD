import simd
import Foundation

/// Curtain pair, 2.0 m wide and 2.3 m tall: a walnut rod with brass finials on three brass wall brackets near the ceiling, two floor-length
/// oatmeal linen panels hung from brass rings and clips in pinch pleats, each gathered open with a rope tieback on a brass wall hook, with
/// weighted hems. Wall mount: the back of the brackets at z = -depth / 2, lowest point (hem) at y = 0, front is +Z.
public struct CurtainPair: RealAsset {
    public static let id = "curtain-pair"
    public static let summary = "Curtain pair, 2.0 x 2.3 m: walnut rod with brass finials, two pinch-pleat linen panels on rings, tied back with rope."
    public static let tags = ["prop", "floorplan", "decor", "fabric", "wall", "interior"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 18, elevation: 6, distance: 4.4, studio: true)

    /// Overall size in meters (x width, y height, z depth). Depth runs from the wall plate to the front of the tied-back folds.
    public var size = V3(2.0, 2.3, 0.15)
    /// Rod height above the floor (m).
    public var rodHeight: Float = 2.265
    /// Height of the tiebacks (m).
    public var tiebackHeight: Float = 1.0
    /// Pleats across each panel heading.
    public var pleats = 6
    /// Curtain fabric.
    public var fabric: MaterialKey = "fabric.drapery"
    /// Rod wood.
    public var rodWood: MaterialKey = "wood.walnut"
    /// Rings, brackets, finial caps, hook.
    public var brass: MaterialKey = "metal.brass-aged"
    /// Tieback rope.
    public var rope: MaterialKey = "fabric.canvas:9A8456"
    public init() {}

    private func smooth(_ x: Float) -> Float { let t = max(0, min(1, x)); return t * t * (3 - 2 * t) }

    /// Cloth point for panel side `s` (-1 left, +1 right), across fraction `u` in 0...1 (outer edge to inner edge) and down fraction `v`.
    private func point(_ s: Float, _ u: Float, _ v: Float, _ ph: Float) -> V3 {
        let yTop: Float = 2.19, yBot: Float = 0.004, yT = tiebackHeight
        let y = yTop - (yTop - yBot) * v
        let g: Float = 0.075                                  // half width at the tieback
        // Width and center follow a funnel above the tieback and a soft flare below it.
        var hw: Float, cx: Float
        if y >= yT {
            let k = smooth((y - yT) / (yTop - yT))
            hw = g + (0.26 - g) * pow(k, 1.3); cx = 0.88 + (0.69 - 0.88) * k
        } else {
            let k = smooth((yT - y) / yT)
            hw = g + (0.255 - g) * pow(k, 0.8); cx = 0.88 + (0.745 - 0.88) * k
        }
        let x = s * (cx + (0.5 - u) * 2 * hw)
        // Fold wave: pinch pleats at the top, tighter bunching at the tieback, relaxed below.
        let n = Float(pleats)
        let sp = u * n + ph
        let wave = sin(sp * 2 * .pi) + 0.12 * sin(sp * 4 * .pi + 0.8)
        let sharp = copysign(pow(abs(wave), 0.9), wave)
        let nearTie = exp(-pow((y - yT) / 0.34, 2))
        let head = exp(-pow((y - 2.19) / 0.16, 2))
        let amp: Float = 0.0055 + 0.006 * head + 0.009 * nearTie + 0.004 * smooth((yT - y) / yT) - 0.004 * smooth((y - 1.8) / 0.4)
        // Fold lines meander slightly down the cloth.
        let sway = 0.002 * sin(y * 5 + u * 7 + ph * 3)
        var z = amp * (sharp + 0.2 * sin(y * 6 + sp * 3.1)) + 0.024 * nearTie + sway
        // Hem weights: two small bumps in the hem pocket, and the hem fold line.
        if y < 0.09 {
            for ux: Float in [0.08, 0.92] {
                let d = (u - ux) * 2 * hw, e = y - 0.025
                z += 0.0035 * exp(-(d * d + e * e) / 0.00016)
            }
            z += 0.0014 * smooth((0.09 - y) / 0.01)
        }
        return V3(x, y, z)
    }

    private func cloth(_ s: Float, _ nu: Int, _ nv: Int, _ ph: Float) -> [Surface] {
        var cs = Surface(material: fabric)
        let row = UInt32(nu + 1)
        for j in 0...nv {
            // Denser rows near the tieback, where the folds change fastest, and near the heading.
            let t = Float(j) / Float(nv)
            let v = t
            for i in 0...nu {
                let u = Float(i) / Float(nu)
                let p = point(s, u, v, ph)
                let uv = V2(u * 1.1 * (s > 0 ? 1 : -1), (2.19 - p.y))
                _ = cs.add(p, V3(0, 0, 1), uv)
            }
        }
        for j in 0..<nv { for i in 0..<nu {
            let a = UInt32(j) * row + UInt32(i)
            if s > 0 { cs.quad(a, a + 1, a + row + 1, a + row) } else { cs.quad(a, a + row, a + row + 1, a + 1) }
        } }
        cs.recomputeNormals()
        cs.computeTangents()
        // Hem soiling and a faint dust line: occlusion darkens the albedo toward the floor.
        for j in 0...nv { for i in 0...nu {
            let k = j * (nu + 1) + i
            let y = cs.positions[k].y
            let dirt = 0.3 * smooth((0.24 - y) / 0.24) * (0.65 + 0.35 * sin(Float(i) * 2.3 + ph * 9))
            // Valleys of the pleats sit in their own shade; ridges stay open.
            let fold = cs.positions[k].z - point(s, Float(i) / Float(nu), Float(j) / Float(nv), ph + 0.5 / Float(pleats)).z
            let cavity = 0.16 * max(0, min(1, -fold / 0.02))
            cs.occlusion[k] = 1 - dirt - cavity
        } }
        // Back shell behind the front, thicker in the double hem and the heading tape, wound the other way.
        var back = cs
        for k in back.positions.indices {
            let y = cs.positions[k].y
            let th: Float = 0.0022 + 0.004 * smooth((0.075 - y) / 0.01) + 0.0025 * smooth((y - 2.115) / 0.01)
            back.positions[k] = cs.positions[k] - cs.normals[k] * th
        }
        back = back.flipped()
        // Close the open edges (hem and both sides, and the heading) so the cloth reads as a folded sheet, not two layers.
        var edge = Surface(material: fabric)
        func strip(_ pairs: [(Int, Int)]) {
            for (a, b) in pairs {
                let f0 = edge.add(cs.positions[a], cs.normals[a], cs.uvs[a]), f1 = edge.add(cs.positions[b], cs.normals[b], cs.uvs[b])
                let b0 = edge.add(back.positions[a], cs.normals[a], cs.uvs[a]), b1 = edge.add(back.positions[b], cs.normals[b], cs.uvs[b])
                edge.quad(f0, f1, b1, b0)
                edge.quad(f0, b0, b1, f1)
            }
        }
        let idx = { (i: Int, j: Int) in j * (nu + 1) + i }
        var pairs: [(Int, Int)] = []
        for i in 0..<nu { pairs.append((idx(i, nv), idx(i + 1, nv))); pairs.append((idx(i, 0), idx(i + 1, 0))) }
        for j in 0..<nv { pairs.append((idx(0, j), idx(0, j + 1))); pairs.append((idx(nu, j), idx(nu, j + 1))) }
        strip(pairs)
        edge.recomputeNormals(); edge.computeTangents()
        cs.append(back)
        cs.append(edge)
        // Thread lines along the heading tape and the double hem.
        var thread = Surface(material: "fabric.canvas:857551")
        for y in [Float(2.115), Float(0.078)] {
            let v = (2.19 - y) / (2.19 - 0.004)
            let n = nu * 2
            var prev: (UInt32, UInt32)?
            for i in 0...n {
                let u = Float(i) / Float(n)
                var p = point(s, u, v, ph)
                p.z += 0.0014
                let a = thread.add(V3(p.x, p.y + 0.0011, p.z), V3(0, 0, 1), V2(u * 0.5, 0))
                let b = thread.add(V3(p.x, p.y - 0.0011, p.z), V3(0, 0, 1), V2(u * 0.5, 0.0022))
                if let pr = prev { thread.quad(pr.1, b, a, pr.0) }
                prev = (a, b)
            }
        }
        thread.recomputeNormals(); thread.computeTangents()
        return [cs, thread]
    }

    public func build(seed: UInt64) -> LODModel {
        func make(_ hi: Bool) -> Model {
            var rng = SeededRNG(seed: seed)
            var m = Model(name: Self.id)
            let wall = -size.z / 2
            let rz: Float = wall + 0.075                         // rod axis, 7.5 cm off the wall
            let ry = rodHeight
            let rodR: Float = 0.0125
            // Rod with a reeded turned look: plain tube plus end finials.
            m.add(Prim.cylinder(radius: rodR, height: 1.94, bevel: 0.0006, segments: hi ? 14 : 8, material: rodWood),
                  Xform(translation: V3(-0.97, ry, rz), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
            for s: Float in [-1, 1] {
                let fin: [V2] = [V2(0, 0), V2(0.0145, 0), V2(0.0145, 0.004), V2(0.012, 0.007), V2(0.012, 0.011), V2(0.019, 0.017), V2(0.0225, 0.026), V2(0.0215, 0.034),
                                 V2(0.0125, 0.0405), V2(0.003, 0.0425), V2(0, 0.0425)]
                // Axis +Y rotated to point outward along +/-X.
                m.add(Prim.lathe(fin, segments: hi ? 16 : 10, seamTile: 0.1, material: rodWood),
                      Xform(translation: V3(s * 0.958, ry, rz), rotation: simd_quatf(degrees: -s * 90, axis: V3(0, 0, 1))))
                m.add(Prim.torus(major: 0.0138, minor: 0.0019, segments: hi ? 14 : 8, sides: 4, material: brass),
                      Xform(translation: V3(s * 0.9605, ry, rz), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
            }
            // Brackets: round wall plate, short arm and a cradle ring around the rod. Two ends plus one at the center.
            for bx: Float in [-0.93, 0, 0.93] {
                m.add(Prim.cylinder(radius: 0.032, height: 0.011, bevel: 0.003, segments: hi ? 14 : 8, material: brass),
                      Xform(translation: V3(bx, ry, wall), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
                m.add(Prim.torus(major: 0.0148, minor: 0.0034, segments: hi ? 12 : 8, sides: 5, material: brass),
                      Xform(translation: V3(bx, ry, rz), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
                m.add(Prim.tube([V3(bx, ry, wall + 0.008), V3(bx, ry - 0.003, (wall + rz) / 2), V3(bx, ry - 0.0145, rz)], radii: [0.0072, 0.0068, 0.0062], sides: hi ? 8 : 5,
                                seamTile: 0.03, material: brass, capEnd: true))
            }
            // Panels.
            let nu = hi ? 34 : 26, nv = hi ? 20 : 14
            for s: Float in [-1, 1] {
                let ph = rng.float(0...1)
                for sf in cloth(s, nu, nv, ph) { m.add(sf) }
                // Rings and clips along the heading.
                let nr = hi ? 9 : 5
                for k in 0..<nr {
                    let u = (Float(k) + 0.5) / Float(nr)
                    let top = point(s, u, 0, ph)
                    let ringY = ry
                    m.add(Prim.torus(major: 0.0172, minor: 0.0021, segments: hi ? 10 : 8, sides: 4, material: brass),
                          Xform(translation: V3(top.x, ringY, rz), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
                    // Clip: brass tab from the ring bottom down onto the heading.
                    let ringBottom = ringY - 0.0172 - 0.001
                    let clipH = ringBottom - (top.y - 0.012)
                    m.add(Prim.roundedBox(V3(0.011, clipH, 0.0035), radius: 0.0012, bevelSegments: 1, material: brass),
                          Xform(translation: V3(top.x, ringBottom - clipH / 2, rz + top.z * 0.8)))
                }
                // Rope tieback around the gathered folds, with two tails to the wall hook.
                let yT = tiebackHeight
                let cxT = s * 0.88
                let rx: Float = 0.086, rzR: Float = 0.05
                let cz: Float = 0.004 + 0.013
                var loop: [V3] = []
                let nl = hi ? 20 : 12
                for k in 0...nl {
                    let a = Float(k) / Float(nl) * 2 * .pi
                    loop.append(V3(cxT + rx * cos(a), yT + 0.004 * sin(a * 2), cz + rzR * sin(a)))
                }
                m.add(Prim.tube(loop, radii: loop.map { _ in 0.0075 }, sides: hi ? 6 : 5, seamTile: 0.02, material: rope, capEnd: true))
                // Tails run from the back of the loop to the hook and hang as a small tassel.
                let hook = V3(s * 0.985, yT, wall + 0.03)
                let backPt = V3(cxT + rx * 0.7, yT, cz - rzR * 0.7)
                let tail = catmull([backPt, V3((backPt.x + hook.x) / 2, yT - 0.012, (backPt.z + hook.z) / 2), hook + V3(-s * 0.006, -0.004, 0)], per: 4)
                m.add(Prim.tube(tail, radii: tail.map { _ in 0.0052 }, sides: hi ? 6 : 5, seamTile: 0.02, material: rope, capEnd: true))
                m.add(Prim.cylinder(radius: 0.011, height: 0.07, bevel: 0.004, segments: hi ? 8 : 6, material: rope),
                      Xform(translation: V3(hook.x - s * 0.006, yT - 0.082, hook.z)))
                m.add(Prim.cylinder(radius: 0.0045, height: 0.012, bevel: 0.002, segments: 10, material: brass),
                      Xform(translation: V3(hook.x - s * 0.006, yT - 0.013, hook.z)))
                // Brass hook: plate on the wall and a curved arm.
                m.add(Prim.cylinder(radius: 0.022, height: 0.008, bevel: 0.002, segments: hi ? 12 : 8, material: brass),
                      Xform(translation: V3(hook.x, yT, wall), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
                let arm = catmull([V3(hook.x, yT, wall + 0.006), V3(hook.x, yT + 0.003, wall + 0.028), V3(hook.x, yT + 0.02, wall + 0.04), V3(hook.x, yT + 0.034, wall + 0.034)], per: 4)
                m.add(Prim.tube(arm, radii: arm.map { _ in 0.0055 }, sides: 8, seamTile: 0.03, material: brass, capEnd: true))
            }
            // Planted: lowest point y = 0, back plane at z = -depth / 2, centered in X.
            let bb = m.bounds
            m = m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, 0)))
            return m
        }
        return LODModel(levels: [make(true), make(false)], switchDistances: [14])
    }
}
