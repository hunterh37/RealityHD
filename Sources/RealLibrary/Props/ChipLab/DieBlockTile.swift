import simd
import Foundation

/// IP-block die tile, parametric footprint (default 6.2 x 6.2 mm), 0.4 mm thick: chamfered silicon body with a
/// type-specific surface pattern and a dim emissive tint, plus four snap pins at the corners.
/// Types: tensor (4 x 4 MAC array), sram (bit-cell stripes), noc (router grid), hbmPhy (edge bump rows), io (pad ring).
/// Parts: pin-nw, pin-ne, pin-sw, pin-se (named sockets, fixed joints, mate with die-blank-reticle slots).
public struct DieBlockTile: RealArticulated {
    public static let id = "die-block-tile"
    public static let summary = "Parametric die block tile (tensor, sram, noc, hbmPhy, io): silicon body, type-specific surface pattern, emissive tint, named snap pin sockets."
    public static let tags = ["prop", "chiplab", "electronics", "articulated"]
    public static let budget = 600
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 40, distance: 1.0, studio: true)

    public enum BlockType: String, CaseIterable, Sendable { case tensor, sram, noc, hbmPhy, io }

    /// Block type that selects the surface pattern and emissive tint.
    public var type: BlockType = .tensor
    /// Footprint in meters (x width, z height).
    public var footprint = V2(0.0062, 0.0062)
    /// Thickness in meters.
    public var thickness: Float = 0.0004
    public var body: MaterialKey = "silicon.die"
    public var edge: MaterialKey = "silicon.die-edge"
    public var pin: MaterialKey = "metal.gold"
    public init() {}

    var tint: MaterialKey { "emissive.die-\(type.rawValue.lowercased())" }
    var cellTint: MaterialKey {
        switch type {
        case .tensor: return "silicon.die:4A3A7A"
        case .sram: return "silicon.die:2A5A78"
        case .noc: return "silicon.die:5A4A30"
        case .hbmPhy: return "silicon.die:2E5A40"
        case .io: return "silicon.die:5A343C"
        }
    }

    func slab(_ m: inout Model, _ w: Float, _ d: Float, _ t: Float, _ cx: Float, _ cz: Float, _ y0: Float, _ mat: MaterialKey) {
        m.add(Prim.extrude(Shape2D.rect(w, d), depth: t, bevel: 0, bevelSegments: 1, material: mat),
              Xform(translation: V3(cx, y0 + t / 2, cz), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
    }

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 1)
        let W = footprint.x, D = footprint.y, T = thickness
        var m = Model(name: Self.id)
        m.add(Prim.roundedBox(V3(W, T, D), radius: 0.00004, bevelSegments: 1, material: edge), Xform(translation: V3(0, T / 2, 0)))
        // Polished front face and a keep-out border.
        let fw = W - 0.00024, fd = D - 0.00024
        slab(&m, fw, fd, 0.000006, 0, 0, T, body)
        let y = T + 0.000006, t: Float = 0.000005
        let iw = W - 0.0009, id = D - 0.0009   // active area
        switch type {
        case .tensor:
            let n = 4, cw = iw / Float(n) - 0.00018, cd = id / Float(n) - 0.00018
            for r in 0..<n { for c in 0..<n {
                let cx = (Float(c) - 1.5) * iw / Float(n), cz = (Float(r) - 1.5) * id / Float(n)
                slab(&m, cw, cd, t, cx, cz, y, cellTint)
                slab(&m, cw * 0.22, cd * 0.22, t, cx + cw * 0.18, cz - cd * 0.12, y + t, (r + c) % 3 == 0 ? tint : cellTint)
            } }
        case .sram:
            let n = 10, sd = id / Float(n)
            for r in 0..<n {
                let cz = (Float(r) - 4.5) * sd
                slab(&m, iw * 0.88, sd * 0.62, t, iw * 0.06, cz, y, cellTint)
                if r % 3 == 1 { slab(&m, iw * 0.88, sd * 0.12, t, iw * 0.06, cz, y + t, tint) }
            }
            slab(&m, iw * 0.08, id, t, -iw * 0.46, 0, y, tint)
        case .noc:
            let n = 3
            for k in 0..<n {
                let p = (Float(k) - 1) * id / 2.2
                slab(&m, iw, 0.00012, t, 0, p, y, cellTint)
                slab(&m, 0.00012, id, t, p, 0, y, cellTint)
            }
            for r in 0..<n { for c in 0..<n {
                slab(&m, 0.00055, 0.00055, t * 1.6, (Float(c) - 1) * iw / 2.2, (Float(r) - 1) * id / 2.2, y, (r + c) % 2 == 0 ? tint : cellTint)
            } }
        case .hbmPhy:
            let n = 8
            for row: Float in [-1, 1] {
                for i in 0..<n {
                    let x = (Float(i) - 3.5) * iw / Float(n)
                    slab(&m, 0.00032, 0.00032, t, x, row * id * 0.42, y, i % 2 == 0 ? tint : cellTint)
                }
            }
            slab(&m, iw, id * 0.5, t, 0, 0, y, cellTint)
            slab(&m, iw * 0.7, id * 0.08, t, 0, 0, y + t, tint)
        case .io:
            let n = 6
            for side: Float in [-1, 1] {
                for i in 0..<n {
                    let u = (Float(i) - 2.5) * iw / Float(n)
                    slab(&m, 0.00042, 0.00042, t, u, side * (D / 2 - 0.0005), y, i % 2 == 0 ? tint : cellTint)
                    slab(&m, 0.00042, 0.00042, t, side * (W / 2 - 0.0005), (Float(i) - 2.5) * id / Float(n), y, i % 2 == 1 ? tint : cellTint)
                }
            }
            slab(&m, iw * 0.5, id * 0.5, t, 0, 0, y, cellTint)
        }
        // Metal routing rails in the margin, a dicing chip at one corner and a dust speck.
        let rail: MaterialKey = "silicon.die:7A7A98"
        slab(&m, iw, 0.00007, t, 0, id / 2 + 0.00022, y, rail)
        slab(&m, iw * 0.8, 0.00007, t, iw * 0.1, -id / 2 - 0.00022, y, rail)
        slab(&m, 0.00028 + rng.float(0...0.0001), 0.00016, 0.000012, W / 2 - 0.00018, -D / 2 + 0.00009, y, edge)
        rig.base[0] = m
        // Snap pins at the corners, gold pads that mate with die-blank-reticle slot corners.
        for (name, sx, sz) in [("nw", Float(-1), Float(-1)), ("ne", 1, -1), ("sw", -1, 1), ("se", 1, 1)] {
            let px = sx * (W / 2 - 0.00028), pz = sz * (D / 2 - 0.00028)
            _ = rig.part("pin-\(name)", pivot: V3(px, T, pz), joint: .fixed)
            rig.add(Prim.extrude(Shape2D.rect(0.00022, 0.00022), depth: 0.00004, bevel: 0, bevelSegments: 1, material: pin),
                    Xform(translation: V3(px, y + 0.00002, pz), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))), to: "pin-\(name)")
        }
        rig.states = [RigState("assembled")]
        return rig
    }
}
