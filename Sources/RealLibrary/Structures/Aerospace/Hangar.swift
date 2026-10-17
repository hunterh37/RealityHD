import simd
import Foundation

/// Arched aircraft and rocket hangar, 24 x 30 m, 10.5 m at the crown: corrugated metal barrel roof on
/// steel portal arches, front header over an 18 m door opening with four sliding leaves on floor and head
/// tracks (two stacked open, two half shut), corrugated back wall, side personnel door with canopy and
/// lamp, translucent roof light strips, sealed interior floor with yellow bay lines and a concrete apron.
public struct Hangar: RealAsset {
    public static let id = "hangar"
    public static let summary = "Arched hangar, 24 x 30 m: corrugated barrel roof on steel arches, boxed door header over sliding doors, skylights, concrete plinth and apron."
    public static let tags = ["structure", "aerospace", "building", "industrial", "metal"]
    public static let budget = 30_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 14, distance: 1.05)

    /// Width (x), depth (z), side wall height and crown height in meters.
    public var width: Float = 24
    public var depth: Float = 30
    public var wallHeight: Float = 4
    public var crown: Float = 10.5
    /// Door opening width and height on the +Z front.
    public var doorWidth: Float = 18
    public var doorHeight: Float = 7
    /// Apron depth in front of the doors.
    public var apron: Float = 8
    public var cladding: MaterialKey = "metal.roofing:9EA4A6"
    public var doorCladding: MaterialKey = "metal.roofing:6F7E86"
    public var frame: MaterialKey = "metal.painted:4A5560"
    public var floor: MaterialKey = "concrete.shop"
    public var apronMaterial: MaterialKey = "concrete.rough"
    public init() {}

    /// Cross-section line of the roof at the inside face, left to right (x, y).
    func profile(_ inset: Float, n: Int) -> [V2] {
        let hw = width / 2 - inset, rise = crown - wallHeight - inset * 0.5
        var pts = [V2(-hw, 0), V2(-hw, wallHeight)]
        for k in 1..<n {
            let t = Float(k) / Float(n), a = Float.pi * (1 - t)
            pts.append(V2(cos(a) * hw, wallHeight + sin(a) * rise))
        }
        pts += [V2(hw, wallHeight), V2(hw, 0)]
        return pts
    }

    /// Arch top height at x.
    func archY(_ x: Float) -> Float {
        let hw = width / 2, rise = crown - wallHeight
        return wallHeight + rise * sqrt(max(0, 1 - (x / hw) * (x / hw)))
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(seed: seed, detail: true), level(seed: seed, detail: false)], switchDistances: [120])
    }

    func level(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, D = depth, hw = W / 2, hd = D / 2
        let n = detail ? 28 : 14
        func box(_ c: V3, _ s: V3, _ mt: MaterialKey, _ r: Float = 0.01) {
            m.add(Prim.roundedBox(s, radius: r, bevelSegments: 1, material: mt), Xform(translation: c))
        }
        // floor and apron with sawn joints
        if detail {
            for x in stride(from: -hw - 1.5, through: hw + 1.6, by: 4.5) {
                box(V3(x, 0.121, hd + apron / 2 + 0.2), V3(0.02, 0.004, apron - 0.1), "asphalt.sealant", 0.001)
            }
        }
        box(V3(0, 0.075, 0), V3(W + 0.6, 0.15, D + 0.4), floor, 0.03)
        box(V3(0, 0.06, hd + apron / 2 + 0.2), V3(W + 4, 0.12, apron), apronMaterial, 0.04)
        // roof shell: outer line and inner line closed into a thin band, extruded the full depth
        let outer = profile(-0.12, n: n), inner = profile(0.04, n: n)
        let shell = Shape2D.deduped(outer + inner.reversed())
        m.add(Prim.extrude(shell, depth: D, bevel: 0.02, bevelSegments: 1, material: cladding), Xform(translation: V3(0, 0.15, 0)))
        // concrete upstand along the side and back walls, darker with splash-back
        for sx in [Float(-1), 1] {
            box(V3(sx * (hw + 0.1), 0.3, 0), V3(0.6, 0.6, D + 0.4), "concrete.rough:7E786E", 0.04)
            box(V3(sx * (hw + 0.42), 0.03, 0), V3(0.3, 0.06, D + 0.6), "concrete.rough:6E685F", 0.02)
        }
        box(V3(0, 0.3, -hd - 0.08), V3(W + 0.8, 0.6, 0.6), "concrete.rough:7E786E", 0.04)
        // standing seams: low ribs around the arch every sheet width
        if detail {
            let rib = profile(-0.13, n: n)
            var z = -hd + 0.45, k = 0
            while z < hd - 0.2 {
                // sheet laps: every fourth seam is a taller capped lap, widths vary as sheets were cut
                let lap = k % 4 == 0, rh: Float = lap ? 0.05 : 0.03
                m.add(Prim.sweep([V2(0, -0.02), V2(rh, -0.02), V2(rh, 0.02), V2(0, 0.02)], along: rib.map { V3($0.x, $0.y + 0.15, z) },
                                 up: V3(0, 0, 1), caps: false, material: lap ? "metal.galvanized-aged" : cladding), .identity)
                z += rng.float(0.75...1.05); k += 1
            }
        }
        // weathered and replaced sheets: a few bays darker with oxide, one fresh
        if detail {
            let out = profile(-0.125, n: n), inn = profile(-0.12, n: n)
            for k in 0..<7 {
                let lo = rng.int(1...(out.count / 2 - 1)), hi = min(out.count - 2, lo + rng.int(3...8))
                let band = Shape2D.deduped(Array(out[lo...hi]) + Array(inn[lo...hi]).reversed())
                let tint = k == 0 ? "metal.roofing:C2C6C6" : (k % 2 == 0 ? "metal.roofing:858A86" : "metal.galvanized-aged")
                m.add(Prim.extrude(band, depth: rng.float(0.8...1.8), bevel: 0.002, bevelSegments: 1, material: tint),
                      Xform(translation: V3(0, 0.15, rng.float(-hd + 2...hd - 2)), rotation: rng.chance(0.5) ? .identity : simd_quatf(degrees: 180, axis: V3(0, 1, 0))))
            }
        }
        // back wall: the whole arch, thin
        let fill = Shape2D.deduped(profile(0.05, n: n))
        m.add(Prim.extrude(fill, depth: 0.12, bevel: 0.01, bevelSegments: 1, material: cladding), Xform(translation: V3(0, 0.15, -hd + 0.1)))
        // front: header above the doors and two side panels
        var header: [V2] = [V2(-hw + 0.05, doorHeight)]
        for p in profile(0.05, n: n) where p.y > doorHeight { header.append(p) }
        header.append(V2(hw - 0.05, doorHeight))
        let hdr = Shape2D.deduped(header.filter { abs($0.x) < hw })
        m.add(Prim.extrude(hdr, depth: 0.14, bevel: 0.01, bevelSegments: 1, material: cladding), Xform(translation: V3(0, 0.15, hd - 0.1)))
        let sideW = (W - doorWidth) / 2
        for s in [Float(-1), 1] {
            box(V3(s * (hw - sideW / 2), 0.15 + doorHeight / 2, hd - 0.1), V3(sideW - 0.1, doorHeight, 0.14), cladding, 0.01)
        }
        // header band and fascia stripe
        // deep door header: a boxed girder projecting over the door track, trimmed top and bottom
        let hy = 0.15 + doorHeight + 0.7, hzF = hd + 0.75
        box(V3(0, hy, hzF - 0.15), V3(W + 0.3, 1.4, 1.5), frame, 0.04)
        box(V3(0, hy + 0.72, hzF - 0.1), V3(W + 0.45, 0.08, 1.65), "metal.galvanized", 0.01)
        box(V3(0, hy - 0.72, hzF - 0.1), V3(W + 0.45, 0.08, 1.65), "metal.galvanized", 0.01)
        box(V3(0, hy, hzF + 0.61), V3(doorWidth * 0.55, 0.55, 0.02), "metal.painted:C8501E", 0.004)
        for x in stride(from: -hw + 1, through: hw - 1, by: 2.2) {
            box(V3(x, hy, hzF + 0.6), V3(0.08, 1.3, 0.03), "metal.galvanized-aged", 0.004)
        }
        // portal arches inside, every ~5 m
        let frames = max(2, Int(D / 5))
        for i in 0...frames {
            let z = -hd + 0.4 + (D - 0.8) * Float(i) / Float(frames)
            let path = profile(0.25, n: n).map { V3($0.x, $0.y + 0.15, z) }
            m.add(Prim.sweep(Shape2D.rect(0.22, 0.3), along: path, up: V3(0, 0, 1), material: frame), .identity)
        }
        // purlins along the roof at a few stations
        for t in stride(from: Float(0.15), through: 0.86, by: 0.14) {
            let a = Float.pi * (1 - t)
            let x = cos(a) * (hw - 0.5), y = wallHeight + sin(a) * (crown - wallHeight - 0.4) + 0.15
            m.add(Prim.tube([V3(x, y, -hd + 0.2), V3(x, y, hd - 0.2)], radii: [0.08, 0.08], sides: 6, seamTile: 0.5, material: frame), .identity)
        }
        // skylight panels either side of the crown, framed, in a staggered run
        for x in [Float(-3), 3] {
            let y = archY(x) + 0.15 + 0.03
            let tilt = simd_quatf(angle: -atan(x / max(1, crown - wallHeight) * 0.9), axis: V3(0, 0, 1))
            for z in stride(from: -hd + 3, to: hd - 2, by: 4.5) {
                let zz = z + (x > 0 ? 1.2 : 0)
                m.add(Prim.roundedBox(V3(1.3, 0.06, 3.1), radius: 0.01, bevelSegments: 1, material: frame), Xform(translation: V3(x, y, zz), rotation: tilt))
                m.add(Prim.roundedBox(V3(1.1, 0.03, 2.9), radius: 0.005, bevelSegments: 1, material: "plastic.fiberglass-yellow:9FA39C"),
                      Xform(translation: V3(x, y + 0.025, zz), rotation: tilt))
            }
        }
        // sliding doors: two leaves stacked open on the left, two half shut on the right
        let leafW = doorWidth / 4 + 0.2
        let leafX: [Float] = [-hw + sideW + leafW / 2 - 0.4, -hw + sideW + leafW / 2 - 0.2, 0.9 + leafW / 2, 0.9 + leafW * 1.5 - 0.2]
        for (i, x) in leafX.enumerated() {
            let z = hd + 0.3 + Float(i % 2) * 0.22
            box(V3(x, 0.15 + doorHeight / 2, z), V3(leafW, doorHeight - 0.05, 0.08), doorCladding, 0.01)
            box(V3(x, 0.15 + doorHeight - 0.1, z), V3(leafW, 0.12, 0.12), frame, 0.01)
            box(V3(x, 0.22, z), V3(leafW, 0.14, 0.12), frame, 0.01)
            // vertical stiffeners and a mid rail on each leaf, kick plate scuffed by tugs
            for k in 0...3 {
                box(V3(x - leafW / 2 + 0.1 + Float(k) * (leafW - 0.2) / 3, 0.15 + doorHeight / 2, z + 0.05), V3(0.08, doorHeight - 0.2, 0.04), frame, 0.008)
            }
            box(V3(x, 0.15 + doorHeight * 0.45, z + 0.05), V3(leafW - 0.1, 0.1, 0.04), frame, 0.008)
            box(V3(x, 0.5, z + 0.046), V3(leafW - 0.2, 0.5, 0.008), "metal.galvanized-aged", 0.003)
            if detail {
                for k in 0..<2 {
                    m.add(Prim.cylinder(radius: 0.09, height: 0.06, bevel: 0.01, segments: 12, material: "metal.galvanized"),
                          Xform(translation: V3(x - leafW / 2 + 0.5 + Float(k) * (leafW - 1), 0.15 + doorHeight + 0.0, z), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
                }
            }
        }
        for dz in [Float(0.3), 0.52] {
            box(V3(0, 0.155, hd + dz), V3(W, 0.02, 0.06), "metal.galvanized", 0.004)
            box(V3(0, 0.15 + doorHeight + 0.06, hd + dz), V3(W, 0.1, 0.1), "metal.galvanized", 0.006)
        }
        // side personnel door, canopy, lamp on the +X wall
        let px = hw + 0.13, pz: Float = 6
        box(V3(px, 0.15 + 1.05, pz), V3(0.06, 2.1, 1.0), "metal.painted:4A5560", 0.01)
        box(V3(px + 0.03, 0.15 + 1.05, pz + 0.38), V3(0.04, 0.04, 0.14), "metal.galvanized", 0.006)
        box(V3(px + 0.5, 2.45, pz), V3(1.0, 0.06, 1.6), "metal.galvanized", 0.01)
        box(V3(px + 0.08, 2.8, pz), V3(0.16, 0.12, 0.3), "metal.painted:2A2A2A", 0.02)
        box(V3(px + 0.15, 2.74, pz), V3(0.02, 0.02, 0.22), "emissive.warm", 0.004)
        // interior floor: yellow bay lines and a parked tool cart for scale
        for x in [Float(-5), 5] { box(V3(x, 0.152, 0), V3(0.12, 0.004, D - 4), "paint.lane-yellow", 0.001) }
        box(V3(0, 0.152, hd - 3), V3(10, 0.004, 0.12), "paint.lane-yellow", 0.001)
        // weathering: rust streaks under the header roll-off and a patched panel on the left
        if detail {
            for _ in 0..<5 {
                let x = rng.chance(0.5) ? rng.float(-hw + 0.4 ... -doorWidth / 2 - 0.3) : rng.float(doorWidth / 2 + 0.3 ... hw - 0.4)
                // tapered run-off streak from a fixing under the header
                let w0 = rng.float(0.08...0.18), len = rng.float(1.5...4)
                let streak = Prim.extrude([V2(-w0, 0), V2(w0, 0), V2(w0 * 0.3, -len), V2(-w0 * 0.2, -len * 0.9)], depth: 0.004, bevel: 0.001,
                                          bevelSegments: 1, material: "metal.rust")
                m.add(streak, Xform(translation: V3(x, 0.15 + doorHeight - 0.05, hd - 0.02)))
            }
            box(V3(-hw - 0.135, 2.2, -4), V3(0.02, 2.4, 3.2), "metal.roofing:B4B9BA", 0.004)
        }
        groundAO(&m, height: 0.8)
        return m
    }
}
