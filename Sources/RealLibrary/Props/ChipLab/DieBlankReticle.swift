import simd
import Foundation

/// Blank reticle-limit die, 26 x 33 mm, 0.8 mm thick: mirror-polished silicon backside (underside), chamfered
/// diced edges, front face with faint violet and teal metal-layer interference bands, seal ring inset from the
/// edge, scribe-line remnant with test-pad dashes, C4 solder bump field and a 3 x 4 grid of block slot pads.
/// Parts: slot-A1 ... slot-C4 (named sockets for die-block-tile, fixed joints, columns A-C, rows 1-4).
public struct DieBlankReticle: RealArticulated {
    public static let id = "die-blank-reticle"
    public static let summary = "Blank reticle-limit die: mirror silicon backside, interference-sheen front, seal ring, scribe remnant, C4 bump field, named block slot sockets."
    public static let tags = ["prop", "chiplab", "electronics", "articulated"]
    public static let budget = 2000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 38, distance: 1.0, studio: true)

    /// Die footprint (x width, z depth) in meters.
    public var footprint = V2(0.026, 0.033)
    /// Die thickness in meters.
    public var thickness: Float = 0.00074
    /// Block slot size (m) and pitch (m) for the 3 x 4 grid.
    public var slotSize = V2(0.0062, 0.0062)
    public var slotPitch = V2(0.0074, 0.0076)
    /// C4 bump grid pitch (m) and bump radius (m).
    public var bumpPitch: Float = 0.0023
    public var bumpRadius: Float = 0.00014
    public var edge: MaterialKey = "silicon.die-edge"
    public var mirror: MaterialKey = "silicon.die"
    public var face: MaterialKey = "silicon.die:343A52"
    public var sealMaterial: MaterialKey = "metal.nickel"
    public var bump: MaterialKey = "metal.solder"
    public init() {}

    func flat(_ w: Float, _ d: Float, _ t: Float, _ mat: MaterialKey) -> Surface {
        Prim.extrude(Shape2D.rect(w, d), depth: t, bevel: 0, bevelSegments: 1, material: mat)
    }

    /// Flat plate lying in XZ, bottom at y0, thickness t, centered at (cx, cz).
    func plate(_ m: inout Model, _ w: Float, _ d: Float, y0: Float, t: Float, cx: Float = 0, cz: Float = 0, _ mat: MaterialKey) {
        m.add(flat(w, d, t, mat), Xform(translation: V3(cx, y0 + t / 2, cz), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
    }

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 1)
        let W = footprint.x, D = footprint.y, T = thickness
        var m = Model(name: Self.id)

        // Body: chamfered diced silicon edge, mirror plate on the underside, passivated front face.
        m.add(Prim.roundedBox(V3(W, T - 0.000005, D), radius: 0.00006, bevelSegments: 2, material: edge),
              Xform(translation: V3(0, 0.000005 + (T - 0.000005) / 2, 0)))
        plate(&m, W - 0.00020, D - 0.00020, y0: 0, t: 0.00001, mirror)
        let top = T
        plate(&m, W - 0.00024, D - 0.00024, y0: top - 0.000004, t: 0.000008, face)

        // Scribe-line remnant: 0.35 mm diced-edge band with test-structure dashes and a gold fiducial.
        let sb: Float = 0.00035
        let seal = sb + 0.00012
        plate(&m, W - 0.00030, 0.00003, y0: top + 0.000002, t: 0.000004, cz: D / 2 - 0.00022, edge)
        plate(&m, W - 0.00030, 0.00003, y0: top + 0.000002, t: 0.000004, cz: -D / 2 + 0.00022, edge)
        for k in 0..<10 {
            let x = (Float(k) - 4.5) * 0.0023
            let len = rng.float(0.0004...0.0009)
            plate(&m, len, 0.00008, y0: top + 0.000002, t: 0.000005, cx: x, cz: D / 2 - 0.00022, k % 5 == 0 ? "metal.gold" : edge)
            plate(&m, len, 0.00008, y0: top + 0.000002, t: 0.000005, cx: x + 0.0004, cz: -D / 2 + 0.00022, k % 4 == 0 ? "metal.gold" : edge)
        }

        // Seal ring: closed nickel-colored band, 0.12 mm wide, raised 8 um, with a dark gap row outside.
        let sw: Float = 0.00012, sy = top + 0.000002
        let ox = W - 2 * seal, oz = D - 2 * seal
        plate(&m, ox, sw, y0: sy, t: 0.000008, cz: oz / 2 - sw / 2, sealMaterial)
        plate(&m, ox, sw, y0: sy, t: 0.000008, cz: -oz / 2 + sw / 2, sealMaterial)
        plate(&m, sw, oz - 2 * sw, y0: sy, t: 0.000008, cx: ox / 2 - sw / 2, sealMaterial)
        plate(&m, sw, oz - 2 * sw, y0: sy, t: 0.000008, cx: -ox / 2 + sw / 2, sealMaterial)

        // Metal-layer interference sheen: three stepped passivation bands inside the ring, violet then teal then blue.
        let inner = ox - 2 * sw - 0.0003
        plate(&m, inner, oz - 2 * sw - 0.0003, y0: sy, t: 0.000004, "silicon.die:3A4468")
        plate(&m, inner - 0.0010, oz - 2 * sw - 0.0013, y0: sy + 0.000004, t: 0.000003, "silicon.die:334E66")

        // Slot pads (named sockets), alternating tint so the interference bands read as a field.
        let cols = ["A", "B", "C"]
        let tints = ["silicon.die:5A4A8C", "silicon.die:2F6A80", "silicon.die:3A5A9A"]
        var slotCenters: [(Float, Float)] = []
        for (ci, c) in cols.enumerated() {
            for r in 0..<4 {
                let cx = (Float(ci) - 1) * slotPitch.x
                let cz = (Float(r) - 1.5) * slotPitch.y
                slotCenters.append((cx, cz))
                let name = "\(c)\(r + 1)"
                _ = rig.part("slot-\(name)", pivot: V3(cx, top, cz), joint: .fixed)
                let mat = tints[(ci + r) % 3]
                rig.add(flat(slotSize.x, slotSize.y, 0.000008, mat),
                        Xform(translation: V3(cx, sy + 0.000008, cz), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))), to: "slot-\(name)")
                // Gold alignment tick at the slot's pin-1 corner.
                rig.add(flat(0.00045, 0.00045, 0.000006, "metal.gold"),
                        Xform(translation: V3(cx - slotSize.x / 2 + 0.0004, sy + 0.000015, cz - slotSize.y / 2 + 0.0004), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))), to: "slot-\(name)")
            }
        }

        // C4 bump field: global grid in the corridors and margins, skipping slot pads.
        let h = bumpRadius * 0.8
        let bumpGeo = Prim.lathe([V2(bumpRadius, 0), V2(bumpRadius * 0.8, h * 0.7), V2(0, h)], segments: 5, seamTile: 1, material: bump)
        var pts: [V2] = []
        let lenZ = 4 * slotPitch.y - 0.0004, lenX = 3 * slotPitch.x - 0.0004
        let nz = Int(lenZ / bumpPitch), nx = Int(lenX / bumpPitch)
        for sx: Float in [-1, 1] {
            for j in 0..<nz { pts.append(V2(sx * slotPitch.x / 2, (Float(j) - Float(nz - 1) / 2) * lenZ / Float(nz - 1))) }
        }
        for r: Float in [-1, 0, 1] {
            for i in 0..<nx {
                let x = (Float(i) - Float(nx - 1) / 2) * lenX / Float(nx - 1)
                if abs(abs(x) - slotPitch.x / 2) < bumpPitch * 0.6 { continue }
                pts.append(V2(x, r * slotPitch.y))
            }
        }
        for p in pts { m.add(bumpGeo, Xform(translation: V3(p.x, sy + 0.000007, p.y))) }
        rig.base[0] = m
        _ = rng
        rig.states = [RigState("assembled")]
        return rig
    }
}
