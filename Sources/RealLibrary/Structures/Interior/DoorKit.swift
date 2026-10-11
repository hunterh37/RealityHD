import simd
import Foundation

/// Shared construction helpers for the floor-planning door set (interior, entry, pocket, barn, bifold, French).
/// Doors share one frame: origin at the bottom center of the rough opening, leaf thickness on Z, swing toward +Z.
enum DoorKit {
    typealias Piece = (Surface, Xform)

    static func box(_ size: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.002, seg: Int = 1) -> Piece {
        (r <= 0 ? cuboid(size, material: mat) : Prim.roundedBox(size, radius: r, bevelSegments: seg, material: mat), Xform(translation: c))
    }

    /// Box with vertical grain (U along Y): built lying along X, stood up.
    static func vbox(_ size: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.002) -> Piece {
        (r <= 0 ? cuboid(V3(size.y, size.x, size.z), material: mat) : Prim.roundedBox(V3(size.y, size.x, size.z), radius: r, bevelSegments: 1, material: mat),
         Xform(translation: c, rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
    }

    /// Cased opening: split jamb across the wall, flat casing with bead and back band on both wall faces, a head
    /// cap, and a rebated stop on the -Z side of the leaf plane. `openW`/`openH` are clear sizes between jamb faces.
    struct Casing {
        var openW: Float, openH: Float, wallT: Float
        var casingW: Float = 0.057, casingT: Float = 0.018, capOver: Float = 0.008, capH: Float = 0.014
        var jambT: Float = 0.019, reveal: Float = 0.006
        var stopT: Float = 0.012, stopW: Float = 0.014, stopZ: Float = 0
        /// Depth of casing faces beyond the wall plane (m), used to size the wall.
        var faceT: Float { casingT + 0.0025 }
        /// False for a pocket opening: no jamb leg or stop on the -X side.
        var leftJamb = true
        /// False for an arched head built by the caller.
        var withHead = true
        var withStop = true, withHeadJamb = true, bead = true
        var material: MaterialKey
        /// Overall width and height of the casing set.
        var totalW: Float { openW + 2 * (reveal + casingW + capOver) }
        var totalH: Float { openH + reveal + casingW + capH }

        func build(_ m: inout Model, detail: Bool) {
            let hx = openW / 2, hy = openH, D = wallT
            func add(_ p: Piece) { m.add(p.0, p.1) }
            for sx: Float in [-1, 1] {
                // Jamb leg across the wall.
                if leftJamb || sx > 0 { add(box(V3(jambT, hy + jambT, D), V3(sx * (hx + jambT / 2), (hy + jambT) / 2, 0), material, r: 0)) }
                for sz: Float in [-1, 1] {
                    let zc = sz * (D / 2 + casingT / 2) - sz * 0.0005
                    // Side casing board and its back band.
                    let cx = hx + reveal + casingW / 2
                    add(vbox(V3(casingW, hy + reveal, casingT), V3(sx * cx, (hy + reveal) / 2, zc), material, r: 0.003))
                    if detail && bead {
                        add(vbox(V3(0.007, hy + reveal - 0.01, 0.004), V3(sx * (hx + reveal + 0.0035), (hy + reveal) / 2, zc + sz * (casingT / 2 + 0.0005)), material, r: 0))
                        add(vbox(V3(0.012, hy + reveal - 0.01, 0.004), V3(sx * (hx + reveal + casingW - 0.006), (hy + reveal) / 2, zc + sz * (casingT / 2 + 0.0005)), material, r: 0))
                    }
                }
                if withStop && (leftJamb || sx > 0) {
                    add(vbox(V3(stopW, hy, stopT), V3(sx * (hx - stopW / 2), hy / 2, stopZ - stopT / 2), material, r: 0))
                }
            }
            if withHeadJamb {
                add(box(V3(openW + 2 * jambT, jambT, D), V3(0, hy + jambT / 2, 0), material, r: 0))
            }
            if withStop {
                add(box(V3(openW - 2 * stopW, stopW, stopT), V3(0, hy - stopW / 2, stopZ - stopT / 2), material, r: 0))
            }
            for sz: Float in withHead ? [-1, 1] : [] {
                let zc = sz * (D / 2 + casingT / 2) - sz * 0.0005
                let headW = openW + 2 * (reveal + casingW)
                add(box(V3(headW, casingW, casingT), V3(0, hy + reveal + casingW / 2, zc), material, r: 0.003, seg: 2))
                // Cap board: wider, deeper, with a small cove strip below it.
                add(box(V3(headW + 2 * capOver, capH, casingT + 0.003), V3(0, hy + reveal + casingW + capH / 2, zc + sz * 0.0015), material, r: 0.0035))
                if detail && bead {
                    add(box(V3(headW - 0.01, 0.007, 0.004), V3(0, hy + reveal + 0.0035, zc + sz * (casingT / 2 + 0.0005)), material, r: 0))
                    add(box(V3(headW - 0.01, 0.012, 0.004), V3(0, hy + reveal + casingW - 0.006, zc + sz * (casingT / 2 + 0.0005)), material, r: 0))
                }
            }
        }
    }

    /// Recessed panel with a stuck bead (and optional raised field) filling the rectangle between rails and stiles.
    /// Returns pieces flagged `true` when they belong to LOD0 only.
    static func panelPieces(x0: Float, x1: Float, y0: Float, y1: Float, zc: Float, mat: MaterialKey, raised: Bool,
                            bead: Float = 0.016, bd: Float = 0.010, beadRadius: Float = 0.0035, raisedSeg: Int = 2) -> [(Surface, Xform, Bool)] {
        var out: [(Surface, Xform, Bool)] = []
        let w = x1 - x0, h = y1 - y0, cx = (x0 + x1) / 2, cy = (y0 + y1) / 2
        let tp: Float = raised ? 0.012 : 0.009
        let p = box(V3(w + 0.006, h + 0.006, tp), V3(cx, cy, zc), mat, r: 0)
        out.append((p.0, p.1, false))
        for side: Float in [-1, 1] {
            let z = zc + side * (tp / 2 + bd / 2 - 0.001)
            let ends: [(V3, V3)] = [
                (V3(w, bead, bd), V3(cx, y1 - bead / 2, z)), (V3(w, bead, bd), V3(cx, y0 + bead / 2, z)),
                (V3(bead, h - 2 * bead + 0.004, bd), V3(x0 + bead / 2, cy, z)), (V3(bead, h - 2 * bead + 0.004, bd), V3(x1 - bead / 2, cy, z)),
            ]
            for (sz, c) in ends {
                let b = box(sz, c, mat, r: beadRadius, seg: 1)
                out.append((b.0, b.1, true))
            }
            if raised {
                let f = box(V3(w - 2 * bead - 0.03, h - 2 * bead - 0.03, 0.012), V3(cx, cy, zc + side * (tp / 2 + 0.003)), mat, r: 0.004, seg: raisedSeg)
                out.append((f.0, f.1, false))
            }
        }
        return out
    }

    static func panel(_ rig: inout Rig, to part: String, x0: Float, x1: Float, y0: Float, y1: Float, zc: Float, T: Float,
                      mat: MaterialKey, raised: Bool, detail: Bool = true, beadRadius: Float = 0.0035, raisedSeg: Int = 2) {
        for (s, x, only0) in panelPieces(x0: x0, x1: x1, y0: y0, y1: y1, zc: zc, mat: mat, raised: raised, beadRadius: beadRadius, raisedSeg: raisedSeg) {
            rig.add(s, x, to: part, lods: only0 ? 0...0 : nil)
        }
    }

    /// Adds pieces to both base LODs (detail pieces only to LOD0).
    static func addBase(_ rig: inout Rig, _ pieces: [(Surface, Xform, Bool)]) {
        for (s, x, only0) in pieces {
            rig.base[0].add(s, x)
            if !only0 { rig.base[1].add(s, x) }
        }
    }

    /// Hinge column: butt hinges (five knuckles, frame 1/3/5 and leaf 2/4) with finials, frame plate and leaf plate.
    /// `side` is the hinge side (-1 left): the leaf lies toward -side. Pin at (pinX, pinZ).
    static func hinges(_ rig: inout Rig, leaf: String, side: Float, pinX: Float, pinZ: Float, ys: [Float],
                       length: Float = 0.089, knuckle: Float = 0.0055, plate: Float = 0.026, mat: MaterialKey,
                       fixedPart: String? = nil, finials: Bool = true, knuckleSegments: Int = 10) {
        let seg = length / 5
        for hy in ys {
            for k in 0..<5 {
                let y0 = hy - length / 2 + Float(k) * seg + 0.0004
                let s = Prim.cylinder(radius: knuckle, height: seg - 0.0008, bevel: 0.0007, segments: knuckleSegments, bevelSegments: 1, material: mat)
                let x = Xform(translation: V3(pinX, y0, pinZ))
                if k % 2 == 0 {
                    if let fp = fixedPart { rig.add(s, x, to: fp) } else { rig.base[0].add(s, x); rig.base[1].add(s, x) }
                } else { rig.add(s, x, to: leaf) }
            }
            for (fy, flip) in (finials ? [(hy + length / 2, false), (hy - length / 2, true)] : []) {
                let f = Prim.lathe([V2(0, 0), V2(knuckle * 0.98, 0), V2(knuckle * 0.8, 0.0025), V2(knuckle * 0.45, 0.0045), V2(0, 0.0052)], segments: 14, seamTile: 0.05, material: mat)
                rig.base[0].add(f, Xform(translation: V3(pinX, fy, pinZ), rotation: flip ? simd_quatf(degrees: 180, axis: V3(1, 0, 0)) : .identity))
            }
            // Plates: the jamb plate sits at the pin, the leaf plate on the leaf edge, both running back from the pin.
            let fplate = cuboid(V3(0.002, length - 0.002, plate), material: mat)
            let fx = Xform(translation: V3(pinX + side * 0.0016, hy, pinZ - plate / 2 - 0.003))
            if let fp = fixedPart { rig.add(fplate, fx, to: fp, lods: 0...0) } else { rig.base[0].add(fplate, fx) }
            rig.add(cuboid(V3(0.002, length - 0.002, plate), material: mat), Xform(translation: V3(pinX - side * 0.0016, hy, pinZ - plate / 2 - 0.003)), to: leaf, lods: 0...0)
        }
    }

    /// Return-to-door lever pair on round roses with a latch, forend and strike. The lever points toward the hinge.
    /// `leaf` carries the rose; parts `handle` and `latch` are added as children of `leaf`.
    static func lever(_ rig: inout Rig, leaf: String, hingeSide: Float, edgeX: Float, backset: Float = 0.06, y: Float,
                      zFront: Float, zBack: Float, mat: MaterialKey, strikeInBase: Bool = true, strikeY: Float? = nil, strikeX: Float? = nil) {
        let freeSign = -hingeSide                    // +1 when the free edge is on +X
        let px = edgeX - freeSign * backset
        let zMid = (zFront + zBack) / 2
        rig.part("handle", parent: leaf, pivot: V3(px, y, zMid), joint: .hinge(axis: V3(0, 0, -1 * freeSign), -45...0, duration: 0.35))
        rig.part("latch", parent: leaf, pivot: V3(edgeX, y, zMid),
                 joint: Joint(.prismatic, axis: V3(freeSign, 0, 0), range: -0.012...0, mimic: .init("handle", ratio: 0.0003)))
        for side: Float in [1, -1] {
            let face = side > 0 ? zFront : zBack
            let n = V3(0, 0, side)
            let roseProfile = [V2(0, 0), V2(0.026, 0), V2(0.026, 0.0035), V2(0.0245, 0.0068), V2(0.021, 0.0082), V2(0, 0.0082)]
            let rose = Prim.lathe(roseProfile, segments: 24, seamTile: 0.05, material: mat)
            rig.add(rose, Xform(translation: V3(px, y, face), rotation: facing(n)), to: leaf)
            let dir = -freeSign   // toward the hinge
            let ctrl: [V3] = [V3(0, 0, 0.003), V3(0, 0, 0.022), V3(dir * 0.006, 0, 0.034), V3(dir * 0.03, 0, 0.041),
                              V3(dir * 0.085, 0, 0.0425), V3(dir * 0.115, 0, 0.04), V3(dir * 0.126, 0, 0.031)]
            let path = catmull(ctrl, per: 4).map { V3(px + $0.x, y + $0.y, face + side * $0.z) }
            let radii = path.indices.map { i -> Float in
                let t = Float(i) / Float(path.count - 1)
                return t < 0.15 ? 0.0075 : (t > 0.93 ? 0.0088 - (t - 0.93) * 0.05 : 0.0088)
            }
            rig.add(Prim.tube(path, radii: radii, sides: 10, seamTile: 0.05, material: mat), to: "handle")
            rig.add(Prim.cylinder(radius: 0.0105, height: 0.007, bevel: 0.0018, segments: 18, bevelSegments: 1, material: mat),
                    Xform(translation: V3(px, y, face + side * 0.006), rotation: facing(n)), to: "handle")
        }
        // Forend plate on the leaf edge and the latch bolt.
        let fe = box(V3(0.0025, 0.16, 0.022), V3(edgeX + freeSign * 0.0008, y, zMid), mat, r: 0.0008, seg: 1)
        rig.add(fe.0, fe.1, to: leaf, lods: 0...0)
        rig.add(Prim.roundedBox(V3(0.012, 0.018, 0.012), radius: 0.002, bevelSegments: 1, material: mat),
                Xform(translation: V3(edgeX + freeSign * 0.0045, y, zMid)), to: "latch", lods: 0...0)
        if strikeInBase {
            let sx = strikeX ?? (edgeX + freeSign * 0.0042)
            for l in 0..<2 {
                rig.base[l].add(Prim.roundedBox(V3(0.002, 0.11, 0.024), radius: 0.0008, bevelSegments: 1, material: mat),
                                Xform(translation: V3(sx, strikeY ?? y, zMid)))
            }
            rig.base[0].add(Prim.roundedBox(V3(0.0025, 0.022, 0.014), radius: 0.001, bevelSegments: 1, material: "plastic.black"),
                            Xform(translation: V3(sx + freeSign * 0.0005, strikeY ?? y, zMid)))
        }
    }
}
