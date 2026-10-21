import simd
import Foundation

/// Finished AI accelerator package, 100 x 100 mm: nickel-plated lid (separate part) with laser marking and
/// sealant bead, two compute dies and four HBM stacks on a glass-core interposer, ABF substrate with decoupling
/// capacitor arrays and a BGA ball grid underneath. Parts: lid, dies, interposer, balls.
public struct ChipPackageFinal: RealArticulated {
    public static let id = "chip-package-final"
    public static let summary = "AI accelerator package: nickel lid with laser mark, compute dies and HBM on glass interposer, ABF substrate, BGA balls; explodes."
    public static let tags = ["prop", "chiplab", "electronics", "articulated"]
    public static let budget = 12500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 38, distance: 1.0, studio: true)

    /// Substrate edge length (m).
    public var edge: Float = 0.1
    /// BGA ball grid per side.
    public var ballCount = 10
    public var lidMaterial: MaterialKey = "metal.nickel"
    public var substrateMaterial: MaterialKey = "laminate.abf"
    public init() {}

    func box(_ s: V3, _ r: Float = 0.00003, _ mat: MaterialKey) -> Surface {
        r < 0.0001 ? cuboid(s, material: mat) : Prim.roundedBox(s, radius: r, bevelSegments: 1, material: mat)
    }

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 1)
        let W = edge
        let ballH: Float = 0.0016, subT: Float = 0.0016, ipT: Float = 0.0004
        let subBot = ballH - 0.0002, subTop = subBot + subT          // 0.0014 ... 0.0030
        let ipTop = subTop + ipT
        let dieH: Float = 0.0007, hbmH: Float = 0.0008
        let lidWall: Float = 0.002, lidOuter: Float = 0.084, lidT: Float = 0.0012
        let lidTop: Float = 0.006, lidBot = lidTop - lidT

        // ---- base: substrate, caps, pads
        var base = Model(name: Self.id)
        base.add(box(V3(W, subT, W), 0.0002, substrateMaterial), Xform(translation: V3(0, subBot + subT / 2, 0)))
        // Solder-mask-edge copper-clad strip along the underside rim.
        base.add(box(V3(W - 0.001, 0.00012, W - 0.001), 0.00003, "metal.copper"), Xform(translation: V3(0, subBot + 0.00006 - 0.00002, 0)))
        // Gold bond-pad rows outside the lid footprint.
        for k in 0..<2 {
            let o = W / 2 - 0.0016 - Float(k) * 0.0018
            base.add(box(V3(W - 0.012, 0.00012, 0.0009), 0.00002, "metal.gold"), Xform(translation: V3(0, subTop + 0.00004, o)))
            base.add(box(V3(W - 0.012, 0.00012, 0.0009), 0.00002, "metal.gold"), Xform(translation: V3(0, subTop + 0.00004, -o)))
        }
        // Edge decoupling capacitors (0402 class): ceramic body with solder terminals.
        func cap(_ x: Float, _ z: Float, _ rot: Float) {
            let q = simd_quatf(degrees: rot, axis: V3(0, 1, 0))
            base.add(box(V3(0.0011, 0.0005, 0.0006), 0.00004, "plastic.underfill"), Xform(translation: V3(x, subTop + 0.00025, z), rotation: q))
            for s in [Float(-1), 1] {
                let d = q.act(V3(s * 0.00046, 0, 0))
                base.add(box(V3(0.00022, 0.00052, 0.00062), 0.00004, "metal.solder"), Xform(translation: V3(x + d.x, subTop + 0.00026, z + d.z), rotation: q))
            }
        }
        // Outside the lid: two rows on each side of the package.
        for k in 0..<14 {
            let t = (Float(k) - 6.5) * 0.0042 + rng.float(-0.0001...0.0001)
            let o = W / 2 - 0.0058
            for row in 0..<1 {
                _ = row
                cap(t, o, 0); cap(t, -o, 0); cap(o, t, 90); cap(-o, t, 90)
            }
        }
        // Inside the lid: rows between interposer and lid wall (visible with the lid off).
        for k in 0..<12 {
            let t = (Float(k) - 5.5) * 0.0042
            cap(t, 0.0305, 0); cap(t, -0.0305, 0)
        }
        for k in 0..<4 {
            let t = (Float(k) - 1.5) * 0.0042
            cap(0.0408, t, 90); cap(-0.0408, t, 90)
        }
        // Fiducials and pin-1 triangle.
        for (sx, sz) in [(Float(-1), Float(-1)), (1, -1), (1, 1)] {
            base.add(Prim.lathe([V2(0.0007, 0), V2(0.0007, 0.00012), V2(0, 0.00012)], segments: 10, seamTile: 1, material: "metal.gold"),
                     Xform(translation: V3(sx * (W / 2 - 0.0018), subTop, sz * (W / 2 - 0.0018))))
        }
        base.add(Prim.extrude([V2(0, 0), V2(0.003, 0), V2(0, 0.003)], depth: 0.00012, bevel: 0.00002, bevelSegments: 1, material: "metal.gold"),
                 Xform(translation: V3(-W / 2 + 0.0012, subTop + 0.00006, W / 2 - 0.0012), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
        rig.base[0] = base

        // ---- balls (BGA): own part so the grid can drop away.
        _ = rig.part("balls", pivot: V3(0, 0, 0), joint: .slide(axis: V3(0, -1, 0), 0...0.03, duration: 0.8))
        let pitch: Float = 0.0092
        for i in 0..<ballCount { for j in 0..<ballCount {
            let x = (Float(i) - Float(ballCount - 1) / 2) * pitch, z = (Float(j) - Float(ballCount - 1) / 2) * pitch
            if abs(x) < 0.0095 && abs(z) < 0.0095 && (i + j) % 2 == 0 { continue }
            let b = Prim.lathe([V2(0, 0), V2(0.0006, 0), V2(0.0008, 0.0008), V2(0.0004, 0.0015), V2(0, 0.0016)], segments: 7, seamTile: 1, material: "metal.solder")
            rig.add(b, Xform(translation: V3(x, 0, z), rotation: simd_quatf(degrees: rng.float(0...50), axis: V3(0, 1, 0))), to: "balls")
        } }

        // ---- interposer
        _ = rig.part("interposer", pivot: V3(0, subTop, 0), joint: .slide(axis: V3(0, 1, 0), 0...0.03, duration: 0.8))
        let ipW: Float = 0.078, ipD: Float = 0.047
        rig.add(box(V3(ipW + 0.0016, 0.0002, ipD + 0.0016), 0.0001, "plastic.underfill"), Xform(translation: V3(0, subTop + 0.0001, 0)), to: "interposer")
        rig.add(box(V3(ipW, ipT, ipD), 0.00004, "glass.substrate"), Xform(translation: V3(0, subTop + ipT / 2 + 0.00004, 0)), to: "interposer")
        // Copper RDL bus runs between each die and its HBM neighbours.
        let dieW: Float = 0.022, dieD: Float = 0.032
        for sx in [Float(-1), 1] {
            for zi in [Float(-1), 1] {
                for l in 0..<5 {
                    let z = zi * 0.0075 + (Float(l) - 2) * 0.0013
                    rig.add(box(V3(0.0030, 0.00005, 0.00040), 0.00001, "metal.copper"),
                            Xform(translation: V3(sx * 0.0232, ipTop + 0.00004, z)), to: "interposer")
                }
            }
            for l in 0..<5 {
                rig.add(box(V3(0.0012, 0.00005, 0.00040), 0.00001, "metal.copper"),
                        Xform(translation: V3(0, ipTop + 0.00004, (Float(l) - 2) * 0.0013 + 0.0)), to: "interposer")
            }
        }
        _ = dieW; _ = dieD

        // ---- dies: two compute dies, four HBM stacks
        _ = rig.part("dies", pivot: V3(0, ipTop, 0), joint: .slide(axis: V3(0, 1, 0), 0...0.04, duration: 0.8))
        for sx in [Float(-1), 1] {
            let cx = sx * 0.0125
            let cy = ipTop + dieH / 2 + 0.00006
            rig.add(box(V3(0.022, dieH, 0.032), 0.00008, "silicon.die-edge"), Xform(translation: V3(cx, cy, 0)), to: "dies")
            rig.add(box(V3(0.0215, 0.00004, 0.0315), 0.00002, "silicon.die"), Xform(translation: V3(cx, cy + dieH / 2 + 0.00001, 0)), to: "dies")
            // Floorplan blocks: 2 x 3 core tiles raised 30 um.
            for a in 0..<2 { for b in 0..<3 {
                let px = cx + (Float(a) - 0.5) * 0.0100, pz = (Float(b) - 1) * 0.0098
                rig.add(box(V3(0.0092, 0.00004, 0.0090), 0.00002, "silicon.die-edge"), Xform(translation: V3(px, cy + dieH / 2 + 0.00004, pz)), to: "dies")
            } }
            // Underfill fillet skirt.
            rig.add(box(V3(0.0232, 0.00028, 0.0332), 0.00012, "plastic.underfill"), Xform(translation: V3(cx, ipTop + 0.00014, 0)), to: "dies")
            // HBM stacks: base logic die plus slices, mold-grey sides, polished cap.
            for zi in [Float(-1), 1] {
                let hx = sx * 0.0315, hz = zi * 0.0102
                let hy = ipTop + 0.00006
                rig.add(box(V3(0.0112, 0.00018, 0.0104), 0.00004, "silicon.die-edge"), Xform(translation: V3(hx, hy + 0.00009, hz)), to: "dies")
                for s in 0..<4 {
                    let yy = hy + 0.00018 + Float(s) * 0.00014 + 0.00007
                    rig.add(box(V3(0.0100, 0.00011, 0.0092), 0.00002, s % 2 == 0 ? "silicon.die-edge" : "metal.solder"), Xform(translation: V3(hx, yy, hz)), to: "dies")
                }
                rig.add(box(V3(0.0100, 0.00006, 0.0092), 0.00002, "silicon.die-edge"), Xform(translation: V3(hx, hy + hbmH - 0.00003, hz)), to: "dies")
            }
        }

        // ---- lid: plate, perimeter wall, sealant bead, laser marking
        _ = rig.part("lift", pivot: V3(0, lidTop, 0), joint: .slide(axis: V3(0, 1, 0), 0...0.07, duration: 1.0))
        _ = rig.part("lid", parent: "lift", pivot: V3(0, subTop, -0.043), joint: .hinge(axis: V3(1, 0, 0), -120...0, duration: 1.2))
        let lm = lidMaterial
        rig.add(box(V3(lidOuter, lidT, lidOuter), 0.0004, lm), Xform(translation: V3(0, lidTop - lidT / 2, 0)), to: "lid")
        let wallH = lidBot - subTop + 0.0002
        let wallY = subTop - 0.0002 + wallH / 2
        for s in [Float(-1), 1] {
            rig.add(box(V3(lidOuter, wallH, lidWall), 0.0002, lm), Xform(translation: V3(0, wallY, s * (lidOuter / 2 - lidWall / 2))), to: "lid")
            rig.add(box(V3(lidWall, wallH, lidOuter - 2 * lidWall + 0.0004), 0.0002, lm), Xform(translation: V3(s * (lidOuter / 2 - lidWall / 2), wallY, 0)), to: "lid")
            // Sealant bead: rounded rail hugging the foot.
            rig.add(box(V3(lidOuter + 0.0016, 0.00042, 0.0009), 0.00018, "plastic.underfill"), Xform(translation: V3(0, subTop + 0.0001, s * (lidOuter / 2 + 0.0004))), to: "lid")
            rig.add(box(V3(0.0009, 0.00042, lidOuter + 0.0016), 0.00018, "plastic.underfill"), Xform(translation: V3(s * (lidOuter / 2 + 0.0004), subTop + 0.0001, 0)), to: "lid")
        }
        // Fill-port notch dot and laser marking in dark engraved-oxide grey, proud 20 um.
        let mk: MaterialKey = "silicon.die"
        let my = lidTop + 0.00002
        // Logo: hexagonal ring with bar.
        rig.add(Prim.lathe([V2(0.0056, 0), V2(0.0056, 0.00004), V2(0.0042, 0.00004), V2(0.0042, 0)], segments: 6, seamTile: 1, material: mk),
                Xform(translation: V3(-0.026, my - 0.00002, -0.024)), to: "lid")
        rig.add(box(V3(0.0044, 0.00004, 0.0010), 0.00001, mk), Xform(translation: V3(-0.026, my, -0.024)), to: "lid")
        // Text-like lines: glyph runs.
        var tr = rng.fork(7)
        for line in 0..<4 {
            var x: Float = -0.0125
            let z = -0.0285 + Float(line) * 0.0042
            let n = line == 0 ? 9 : 6 + line
            for _ in 0..<n {
                let w = tr.float(0.0010...0.0026)
                rig.add(box(V3(w, 0.00004, line == 0 ? 0.0023 : 0.0015), 0.00001, mk), Xform(translation: V3(x + w / 2, my, z)), to: "lid")
                x += w + 0.0010
            }
        }
        // Data-matrix code, 8 x 8 cells.
        var qr = rng.fork(11)
        for a in 0..<8 { for b in 0..<8 where a == 0 || b == 7 || qr.chance(0.5) {
            rig.add(box(V3(0.0012, 0.00004, 0.0012), 0.00001, mk),
                    Xform(translation: V3(0.0185 + Float(a) * 0.0016, my, 0.0235 + Float(b) * 0.0016)), to: "lid")
        } }
        // Serial strip.
        for k in 0..<14 {
            let w = qr.float(0.0008...0.0018)
            rig.add(box(V3(w, 0.00004, 0.0016), 0.00001, mk), Xform(translation: V3(-0.0330 + Float(k) * 0.0030, my, 0.0345)), to: "lid")
        }
        // Chamfer corner mark on the lid.
        rig.add(Prim.extrude([V2(0, 0), V2(0.0045, 0), V2(0, 0.0045)], depth: 0.00004, bevel: 0.00001, bevelSegments: 1, material: mk),
                Xform(translation: V3(-0.0385, my, 0.0385), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))), to: "lid")

        rig.states = [
            RigState("lid-off", ["lid": -105]),
            RigState("assembled"),
            RigState("exploded", ["lift": 0.07, "dies": 0.032, "interposer": 0.014, "balls": 0.012]),
        ]
        return rig
    }
}
