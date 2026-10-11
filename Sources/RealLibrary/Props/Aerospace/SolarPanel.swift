import simd
import Foundation

/// Two-leaf deployable solar panel, 1.6 x 0.6 m deployed, shown open on its root bracket. Each leaf is a
/// carbon substrate with a dark blue silicon cell grid (silver bus lines between cells) in a machined
/// aluminium frame, gold MLI foil on the back. The outer leaf folds 178 degrees over the inner one on a
/// three-knuckle centre hinge; a wiring harness crosses the hinge. Span along X, the hinge line along Z.
public struct SolarPanel: RealArticulated {
    public static let id = "solar-panel"
    public static let summary = "Two-leaf deployable solar panel, 1.6 x 0.6 m deployed: silicon cell grid on carbon substrate in aluminium frames, folded about a centre hinge on a root bracket."
    public static let tags = ["prop", "aerospace", "electronics", "articulated"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 30, distance: 1.05, studio: true)

    /// Deployed size (m): x length of both leaves, z width.
    public var length: Float = 1.6
    public var width: Float = 0.6
    /// Height of the leaf underside above the base (m).
    public var mountHeight: Float = 0.07
    /// Cells per leaf along X and Z.
    public var cellsX = 6
    public var cellsZ = 5
    public var frame: MaterialKey = "metal.aluminum-brushed"
    public var cells: MaterialKey = "screen.off:16233F"
    public var substrate: MaterialKey = "composite.carbon"
    public var foil: MaterialKey = "insulation.foil-gold"
    public init() {}

    /// One leaf from x0 to x0 + L at height y (underside), cells facing +Y.
    func leaf(_ m: inout Model, x0: Float, y: Float, lod: Int) {
        let L = length / 2 - 0.004, W = width, t: Float = 0.018, fr: Float = 0.022
        let cx = x0 + L / 2
        let bs = lod == 0 ? 2 : 1
        // Frame rails.
        for s: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(L, t, fr), radius: 0.003, bevelSegments: bs, material: frame), Xform(translation: V3(cx, y + t / 2, s * (W / 2 - fr / 2))))
            m.add(Prim.roundedBox(V3(fr, t, W - 2 * fr + 0.002), radius: 0.003, bevelSegments: bs, material: frame), Xform(translation: V3(x0 + (s < 0 ? fr / 2 : L - fr / 2), y + t / 2, 0)))
        }
        // Substrate and cell sheet; foil on the back.
        m.add(Prim.roundedBox(V3(L - 2 * fr + 0.004, 0.008, W - 2 * fr + 0.004), radius: 0.001, bevelSegments: 1, material: substrate),
              Xform(translation: V3(cx, y + t / 2, 0)))
        if lod > 0 {
            m.add(Prim.roundedBox(V3(L - 2 * fr, 0.002, W - 2 * fr), radius: 0.0008, bevelSegments: 1, material: cells),
                  Xform(translation: V3(cx, y + t / 2 + 0.005, 0)))
        } else {
            // Individual cells, tint varying per cell by batch; one replaced cell reads a shade lighter.
            var rng = SeededRNG(seed: UInt64(abs(x0 * 1000)) + 7)
            let cw = (L - 2 * fr) / Float(cellsX), cd = (W - 2 * fr) / Float(cellsZ)
            let replaced = rng.int(0...(cellsX * cellsZ - 1))
            for i in 0..<cellsX { for k in 0..<cellsZ {
                let base: (Float, Float, Float) = (i * cellsZ + k == replaced) ? (0x2A, 0x3D, 0x66) : (0x16, 0x23, 0x3F)
                let j = rng.float(-3...3)
                let hex = String(format: "%02X%02X%02X", Int(base.0 + j), Int(base.1 + j), Int(base.2 + j * 1.5))
                m.add(Prim.extrude([V2(-(cw - 0.005) / 2, -(cd - 0.005) / 2), V2((cw - 0.005) / 2, -(cd - 0.005) / 2), V2((cw - 0.005) / 2, (cd - 0.005) / 2), V2(-(cw - 0.005) / 2, (cd - 0.005) / 2)],
                                   depth: 0.002, bevel: 0, bevelSegments: 0, material: "screen.off:" + hex),
                      Xform(translation: V3(x0 + fr + cw * (Float(i) + 0.5), y + t / 2 + 0.005, -(W / 2 - fr) + cd * (Float(k) + 0.5)), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
            } }
        }
        m.add(Prim.roundedBox(V3(L - 2 * fr, 0.0015, W - 2 * fr), radius: 0.0005, bevelSegments: 1, material: foil),
              Xform(translation: V3(cx, y + t / 2 - 0.0048, 0)))
        guard lod == 0 else { return }
        // Bus lines between cells (silver) and fine fingers along each cell row.
        let iw = L - 2 * fr, id = W - 2 * fr
        for i in 1..<cellsX {
            let x = x0 + fr + iw * Float(i) / Float(cellsX)
            m.add(Prim.roundedBox(V3(0.004, 0.0012, id), radius: 0.0004, bevelSegments: 1, material: frame), Xform(translation: V3(x, y + t / 2 + 0.0063, 0)))
        }
        for k in 1..<cellsZ {
            let z = -id / 2 + id * Float(k) / Float(cellsZ)
            m.add(Prim.roundedBox(V3(iw, 0.0012, 0.004), radius: 0.0004, bevelSegments: 1, material: frame), Xform(translation: V3(cx, y + t / 2 + 0.0063, z)))
        }
        // Frame corner screws.
        for (sx, sz) in [(Float(0), Float(-1)), (0, 1), (1, -1), (1, 1)] {
            rivet(&m, at: V3(x0 + fr / 2 + sx * (L - fr), y + t, sz * (W / 2 - fr / 2)), normal: .up, radius: 0.004, segments: 6, material: "metal.steel")
        }
    }

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [6])
        let y = mountHeight, t: Float = 0.018
        for l in 0..<2 {
            var m = Model(name: Self.id)
            let bs = l == 0 ? 2 : 1
            // Root bracket: base plate, two posts and a cross saddle under the inner leaf.
            m.add(Prim.roundedBox(V3(0.24, 0.01, 0.34), radius: 0.003, bevelSegments: bs, material: frame), Xform(translation: V3(-length / 4, 0.005, 0)))
            for s: Float in [-1, 1] {
                m.add(Prim.roundedBox(V3(0.03, y - 0.016, 0.03), radius: 0.004, bevelSegments: bs, material: frame),
                      Xform(translation: V3(-length / 4, 0.01 + (y - 0.016) / 2, s * 0.12)))
            }
            m.add(Prim.roundedBox(V3(0.06, 0.008, 0.3), radius: 0.002, bevelSegments: bs, material: frame), Xform(translation: V3(-length / 4, y - 0.004, 0)))
            if l == 0 {
                for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
                    hexBolt(&m, at: V3(-length / 4 + sx * 0.095, 0.01, sz * 0.145), normal: .up, size: 0.007, material: "metal.steel")
                } }
            }
            leaf(&m, x0: -length / 2, y: y, lod: l)
            // Fixed hinge knuckles on the inner leaf edge.
            for z: Float in [-0.22, 0.22] {
                m.add(Prim.cylinder(radius: 0.007, height: 0.06, bevel: 0.0015, segments: l == 0 ? 14 : 8, material: frame),
                      Xform(translation: V3(0, y + t, z - 0.03), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
            }
            rig.base[l] = m
        }

        rig.part("leaf", pivot: V3(0, y + t, 0), joint: .hinge(axis: V3(0, 0, 1), 0...178, duration: 3))
        for l in 0..<2 {
            var m = Model(name: Self.id)
            leaf(&m, x0: 0.004, y: y, lod: l)
            m.add(Prim.cylinder(radius: 0.007, height: 0.1, bevel: 0.0015, segments: l == 0 ? 14 : 8, material: frame),
                  Xform(translation: V3(0, y + t, -0.05), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
            if l == 0 {
                // Harness: a slack cable loop from the outer leaf across the hinge.
                let pts = catmull([V3(0.05, y + 0.004, 0.27), V3(0.01, y - 0.012, 0.275), V3(-0.03, y - 0.008, 0.27), V3(-0.06, y + 0.004, 0.265)], per: 5)
                m.add(Prim.tube(pts, radii: pts.map { _ in 0.004 }, sides: 8, seamTile: 0.03, material: "rubber", capEnd: true))
            }
            rig.add(m, to: "leaf", lod: l)
        }

        rig.states = [RigState("deployed"), RigState("stowed", ["leaf": 178])]
        groundAO(&rig, height: 0.08, floor: 0.6)
        return rig
    }
}
