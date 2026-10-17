import simd
import Foundation

/// Archery range shelter: covered club shooting line: five lanes under a low mono-pitch roof, open to the front, plank rear wall, white painted shooting line along the front edge of the pad. Parts: concrete pad, shooting line, posts, beams, rafters, metal roof, rear wall, lane dividers, bench, gutter.
/// Asset space: x across lanes, shooting line at z = 0, pad z -0.3...3.7, open side toward -Z (targets), rear wall toward +Z.
public struct RangeShelter: RealAsset {
    public static let id = "range-shelter"
    public static let summary = "Open-sided archery shooting shelter, 12 x 4 m: cedar posts, standing-seam metal shed roof, concrete pad with painted shooting line, five lanes."
    public static let tags = ["prop", "archery", "outdoor", "wood", "building"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(12.4, 3.0, 4.0)
    /// Roof surface height at the front (-Z) edge.
    public var roofFront: Float = 3.0
    /// Roof surface height at the rear (+Z) edge.
    public var roofRear: Float = 2.6
    /// Concrete pad thickness (top surface height).
    public var padThickness: Float = 0.08
    /// Post spacing along x.
    public var postSpacing: Float = 3.0
    /// Lane divider spacing along x.
    public var laneSpacing: Float = 2.4
    /// Post and beam wood.
    public var timber = "wood.cedar-weathered"
    /// Wall and bench wood.
    public var lumber = "wood.lumber-pine"
    /// Roof metal.
    public var roofMetal = "metal.galvanized"
    /// Pad material.
    public var padMaterial = "concrete.smooth"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let halfW = size.x / 2
        let padTop = padThickness
        let zFront: Float = -0.35, zRear: Float = 3.8          // roof edges
        let zbF: Float = -0.2, zbR: Float = 3.5                // front / rear post lines
        func yt(_ z: Float) -> Float { roofFront + (roofRear - roofFront) * (z - zFront) / (zRear - zFront) }
        func add(_ s: Surface, _ x: Xform = .identity) { m.add(s, x.jittered(&rng, deg: 0.15, offset: 0.0006)) }
        func addExact(_ s: Surface, _ x: Xform = .identity) { m.add(s, x) }

        // Concrete pad: 5 x 2 panels with expansion joints over a dark filler slab.
        addExact(Prim.roundedBox(V3(size.x - 0.02, 0.03, 4.0 - 0.02), radius: 0.003, bevelSegments: 1, material: "asphalt.sealant"),
                 Xform(translation: V3(0, 0.015, 1.7)))
        let colW: Float = size.x / 5, gap: Float = 0.01
        let rowZ: [(Float, Float)] = [(-0.3, 1.7 - gap / 2), (1.7 + gap / 2, 3.7)]
        for c in 0..<5 {
            let x0 = -halfW + Float(c) * colW + gap / 2, x1 = -halfW + Float(c + 1) * colW - gap / 2
            for (z0, z1) in rowZ {
                addExact(Prim.roundedBox(V3(x1 - x0, padTop, z1 - z0), radius: 0.004, bevelSegments: 1, material: padMaterial),
                         Xform(translation: V3((x0 + x1) / 2, padTop / 2, (z0 + z1) / 2)))
            }
        }
        // Broom-finish ridges: fine shallow strips across each lane panel.
        for c in 0..<5 {
            let xc = -halfW + (Float(c) + 0.5) * colW
            for k in 0..<18 {
                let z = 0.2 + Float(k) * 0.19 + rng.float(-0.02...0.02)
                if abs(z - 1.7) < 0.05 { continue }
                addExact(cuboid(V3(colW - 0.2, 0.0007, 0.012), material: "concrete.rough"),
                         Xform(translation: V3(xc + rng.float(-0.03...0.03), padTop + 0.0002, z)))
            }
        }
        // Oil and rain stains.
        let flat = simd_quatf(degrees: -90, axis: V3(1, 0, 0))
        for i in 0..<7 {
            let r = rng.float(0.12...0.4)
            let p = V3(rng.float(-5.8...5.8), padTop + 0.0004 + Float(i) * 0.00006, rng.float(0.5...3.3))
            if abs(p.z - 1.7) < r * 0.5 { continue }
            addExact(Prim.extrude(Shape2D.circle(r, ry: r * rng.float(0.5...0.9)), depth: 0.0006, bevel: 0.0002, bevelSegments: 1, material: "concrete.shop"),
                     Xform(translation: p, rotation: simd_quatf(degrees: rng.float(0...180), axis: V3(0, 1, 0)) * flat))
        }
        // Painted shooting line.
        addExact(pl(size.x - 0.02, 0.08, 0.0012, bevel: 0.0004, material: "metal.painted:EEEEE8"),
                 Xform(translation: V3(0, padTop + 0.0007, 0)))

        // Posts, bases, beams.
        var postXs: [Float] = []
        var px = -6.0 as Float
        while px <= 6.001 { postXs.append(px); px += postSpacing }
        let postW: Float = 0.14
        for (zp, tag) in [(zbF, 0), (zbR, 1)] {
            let beamTop = yt(zp) - 0.182
            let beamH: Float = 0.22
            let postTop = beamTop - beamH
            for x in postXs {
                let h = postTop - (padTop - 0.01)
                add(pl(postW, postW, h, bevel: 0.004, material: timber).rotatedGrain(),
                    Xform(translation: V3(x, padTop - 0.01 + h / 2, zp)))
                addExact(cuboid(V3(0.2, 0.008, 0.2), material: "metal.corten"),
                         Xform(translation: V3(x, padTop + 0.004, zp)))
                // knee braces
                for dir: Float in [-1, 1] where abs(x + dir * 0.6) < halfW {
                    let a = V3(x + dir * (postW / 2 - 0.01), postTop - 0.55, zp)
                    let b = V3(x + dir * 0.6, postTop - 0.02, zp)
                    let (s, xf) = bd(from: a, to: b, width: 0.09, thick: 0.06, up: V3(0, 0, 1), bevel: 0, material: timber)
                    add(s, xf)
                }
            }
            let (bs, bx) = bd(from: V3(-halfW - 0.1, beamTop - beamH / 2, zp), to: V3(halfW + 0.1, beamTop - beamH / 2, zp),
                                 width: 0.1, thick: beamH, up: V3(0, 0, 1), bevel: 0.004, material: timber)
            _ = tag
            add(bs, bx)
        }

        // Rafters.
        let nR = 22
        for i in 0..<nR {
            let x = -6.2 + 12.4 * Float(i) / Float(nR - 1)
            let a = V3(x, yt(zFront) - 0.112, zFront), b = V3(x, yt(zRear) - 0.112, zRear - 0.02)
            let (s, xf) = bd(from: a, to: b, width: 0.06, thick: 0.14, up: V3(0, 1, 0), bevel: 0, material: timber)
            add(s, xf)
        }
        // Front fascia.
        addExact(pl(size.x + 0.4, 0.025, 0.2, bevel: 0.003, material: timber),
                 Xform(translation: V3(0, yt(zFront) - 0.14, zFront - 0.013)))

        // Roof: slab plus standing seams.
        let slabA = V3(0, yt(zFront) - 0.036, zFront), slabB = V3(0, yt(zRear) - 0.036, zRear)
        let (slab, slabX) = bd(from: slabA, to: slabB, width: 12.6, thick: 0.012, up: V3(0, 1, 0), bevel: 0.002, material: roofMetal)
        addExact(slab, slabX)
        for k in 0...28 {
            let x = -6.3 + 0.45 * Float(k)
            let a = V3(x, yt(zFront) - 0.015, zFront), b = V3(x, yt(zRear) - 0.015, zRear)
            let (s, xf) = bd(from: a, to: b, width: 0.026, thick: 0.03, up: V3(0, 1, 0), bevel: 0, material: roofMetal)
            addExact(s, xf)
        }
        // Gutter (half round) sloping along x to a downspout at +X, plus bracket straps.
        let gy = yt(zRear) - 0.04
        let R: Float = 0.07, t: Float = 0.006
        var prof: [V2] = []
        for i in 0...8 { let a = Float.pi + Float.pi * Float(i) / 8; prof.append(V2(R * sin(a), R * cos(a))) }
        for i in 0...8 { let a = 2 * Float.pi - Float.pi * Float(i) / 8; prof.append(V2((R - t) * sin(a), (R - t) * cos(a))) }
        let gz: Float = zRear + 0.035
        addExact(Prim.sweep(prof, along: [V3(-6.35, gy + 0.004, gz), V3(6.35, gy - 0.026, gz)], up: V3(0, 1, 0), material: "metal.galvanized"))
        let ds: Float = 6.1
        addExact(Prim.tube([V3(ds, gy - 0.03, gz), V3(ds, 0.15, gz)], radii: [0.032, 0.032], sides: 14, seamTile: 0.1, material: "metal.galvanized", capEnd: true))
        for y: Float in [0.5, 1.4, 2.2] {
            addExact(cuboid(V3(0.07, 0.025, 0.07), material: "metal.corten"),
                     Xform(translation: V3(ds, y, gz)))
        }

        // Rear wall: stacked planks inside the rear posts, top rail at 1.2 m.
        let rows = 8
        let rowH: Float = (1.2 - padTop - 0.05) / Float(rows)
        for r in 0..<rows {
            let y = padTop + 0.005 + rowH * (Float(r) + 0.5)
            var x = -halfW + 0.02
            while x < halfW - 0.02 {
                let len = min(rng.float(2.4...3.4), halfW - 0.02 - x)
                add(pl(len - 0.004, 0.028, rowH - 0.004, bevel: 0.003, material: lumber),
                    Xform(translation: V3(x + len / 2, y, zbR - postW / 2 - 0.014)))
                x += len
            }
        }
        addExact(pl(size.x - 0.04, 0.12, 0.05, bevel: 0.004, material: timber),
                 Xform(translation: V3(0, 1.2 - 0.025 + 0.05, zbR - postW / 2 - 0.03)))
        // Wall studs behind planks aren't visible; add two mid rails on the open upper section.
        addExact(pl(size.x - 0.04, 0.06, 0.09, bevel: 0.004, material: timber),
                 Xform(translation: V3(0, 1.95, zbR + 0.02)))

        // Lane divider posts on the line with lane plates.
        let nDiv = 6
        for i in 0..<nDiv {
            let x = -6.0 + laneSpacing * Float(i)
            let h: Float = 1.35
            add(pl(0.08, 0.08, h, bevel: 0.004, material: lumber),
                Xform(translation: V3(x, padTop + h / 2 - 0.005, 0.0)))
            if i < 5 {
                let py: Float = 1.15
                addExact(cuboid(V3(0.13, 0.13, 0.004), material: "metal.painted:F0EFE8"),
                         Xform(translation: V3(x, py, 0.042)))
                // tally dots: lane number i + 1
                let n = i + 1
                for d in 0..<n {
                    let dx = (Float(d) - Float(n - 1) / 2) * 0.022
                    addExact(Prim.cylinder(radius: 0.0085, height: 0.001, bevel: 0.0003, segments: 8, bevelSegments: 1, material: "metal.painted:141414"),
                             Xform(translation: V3(x + dx, py, 0.0445), rotation: facing(V3(0, 0, 1))))
                }
            }
        }

        // Bench against the rear wall, between the two end-bay posts.
        let bx: Float = -4.5, bz = zbR - postW / 2 - 0.028 - 0.19
        for k in 0..<2 {
            add(pl(1.8, 0.175, 0.04, bevel: 0.004, material: lumber),
                Xform(translation: V3(bx, padTop + 0.45 - 0.02, bz - 0.095 + 0.19 * Float(k))))
        }
        for dx: Float in [-0.8, 0.8] {
            for dz: Float in [-0.14, 0.14] {
                add(pl(0.06, 0.06, 0.41, bevel: 0.003, material: lumber),
                    Xform(translation: V3(bx + dx, padTop + 0.205, bz + dz)))
            }
            addExact(pl(0.05, 0.3, 0.06, bevel: 0.003, material: lumber),
                     Xform(translation: V3(bx + dx, padTop + 0.28, bz)))
        }
        add(pl(1.7, 0.05, 0.07, bevel: 0.003, material: lumber), Xform(translation: V3(bx, padTop + 0.24, bz + 0.0)))

        groundAO(&m)
        // Center on X/Z (asset contract); the scene offsets z by +1.765 to put the shooting line on z = 0.
        m.surfaces = m.surfaces.map { $0.transformed(Xform(translation: V3(0, 0, -1.765))) }
        return LODModel(m)
    }
}


private func pl(_ l: Float, _ w: Float, _ t: Float, bevel: Float = 0.004, material: MaterialKey) -> Surface {
    bevel <= 0 ? cuboid(V3(l, t, w), material: material) : Prim.roundedBox(V3(l, t, w), radius: bevel, bevelSegments: 1, material: material)
}
private func bd(from a: V3, to b: V3, width: Float, thick: Float, up: V3, bevel: Float = 0.004, material: MaterialKey) -> (Surface, Xform) {
    let (_, x) = board(from: a, to: b, width: width, thick: thick, up: up, bevel: bevel, material: material)
    return (pl(simd_length(b - a), width, thick, bevel: bevel, material: material), x)
}

private extension Surface {
    /// Posts are built as boxes with grain on U (x); standing posts want grain vertical: swap U and V.
    func rotatedGrain() -> Surface {
        var s = self
        s.uvs = s.uvs.map { V2($0.y, $0.x) }
        s.computeTangents()
        return s
    }
}
