import simd
import Foundation

/// Pull hardware style for drawer fronts.
enum PullStyle: Equatable { case knob, bar, cup }

/// One horizontal bay of a case, listed top to bottom.
struct Bay {
    enum Kind { case drawers(Int), open }
    var kind: Kind
    var height: Float
}

/// Parameters for `CaseworkKit.cabinet`: a carcass with an overhanging top, drawer bays and legs or a plinth.
struct CaseSpec {
    var width: Float, height: Float, depth: Float
    var bays: [Bay]
    var legHeight: Float
    var legs: Bool = true
    var wood: MaterialKey
    var topWood: MaterialKey? = nil
    var pull: PullStyle = .knob
    var pullMaterial: MaterialKey = "metal.brass"
    /// Shaker-style raised center panel on the drawer fronts.
    var raisedPanel: Bool = true
    var topThickness: Float = 0.025
    var interior: MaterialKey = "wood.plywood"
}

enum CaseworkKit {
    /// Knob: turned brass mushroom, axis +Z at the origin (mounting face at z = 0).
    static func knob(radius r: Float = 0.016, material: MaterialKey) -> Surface {
        Prim.lathe([V2(0, 0), V2(r * 0.3, 0), V2(r * 0.3, 0.01), V2(r * 0.55, 0.014), V2(r, 0.018), V2(r * 0.9, 0.024), V2(r * 0.45, 0.027), V2(0, 0.028)],
                   segments: 14, seamTile: 0.05, material: material, swapUV: false)
    }

    /// Cup (bin) pull: backplate, hanging half ring and a small lip, mounting face at z = 0, ring centered on X.
    static func cupPull(material: MaterialKey) -> Surface {
        var s = Surface(material: material)
        // Backplate: rounded rectangle in XY.
        s.append(Prim.roundedBox(V3(0.075, 0.036, 0.0035), radius: 0.003, bevelSegments: 1, material: material), Xform(translation: V3(0, 0, 0.00175)))
        // Half-ring path hanging in the XZ plane, bulging forward, ring top at the plate.
        let r: Float = 0.026
        var path: [V3] = []
        for k in 0...10 {
            let a = Float.pi * Float(k) / 10
            path.append(V3(-cos(a) * r, 0.002, 0.004 + sin(a) * 0.022))
        }
        s.append(Prim.sweep(Shape2D.circle(0.0045, segments: 6), along: path, up: .up, caps: true, material: material))
        // Rising front lip of the cup.
        s.append(Prim.roundedBox(V3(0.05, 0.012, 0.004), radius: 0.0015, bevelSegments: 1, material: material), Xform(translation: V3(0, -0.012, 0.0045)))
        return s
    }

    static func cabinet(_ sp: CaseSpec, seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: "case")
        let proj: Float = sp.pull == .knob ? 0.022 : (sp.pull == .bar ? 0.0285 : 0.025)
        let W = sp.width, H = sp.height, D = sp.depth - proj
        let wood = sp.wood
        let t: Float = 0.019
        let topT = sp.topThickness
        let ovh: Float = 0.012
        let cW = W - 2 * ovh, cD = D - ovh
        let cZ = -ovh / 2                 // carcass center (back flush with top)
        let frontZ = cZ + cD / 2          // carcass front plane
        let y0 = sp.legs ? sp.legHeight : 0.0
        let bodyBottom = sp.legs ? sp.legHeight : 0.06
        let bodyTop = H - topT
        // Top slab.
        m.add(Prim.roundedBox(V3(W, topT, D), radius: 0.005, bevelSegments: 2, material: sp.topWood ?? wood), Xform(translation: V3(0, H - topT / 2, 0)))
        // Plinth or legs.
        if sp.legs {
            for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
                m.add(BedroomKit.taperedLeg(height: sp.legHeight + 0.004, top: 0.04, bottom: 0.026, radius: 0.003, material: wood),
                      Xform(translation: V3(sx * (cW / 2 - 0.028), 0, sz * (cD / 2 - 0.028) + cZ)))
            }}
        } else {
            m.add(Prim.roundedBox(V3(cW - 0.03, bodyBottom, cD - 0.03), radius: 0.003, bevelSegments: 1, material: sp.interior == "wood.plywood" ? "wood.plywood" : wood),
                  Xform(translation: V3(0, bodyBottom / 2, cZ - 0.005)))
        }
        // Carcass: sides, bottom, back.
        let bodyH = bodyTop - bodyBottom
        for s: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(t, bodyH, cD), radius: 0.003, bevelSegments: 1, material: wood), Xform(translation: V3(s * (cW / 2 - t / 2), bodyBottom + bodyH / 2, cZ)))
        }
        m.add(cuboid(V3(cW - 2 * t + 0.002, 0.012, cD - 0.012), material: sp.interior), Xform(translation: V3(0, bodyBottom + 0.006, cZ - 0.004)))
        m.add(cuboid(V3(cW - 2 * t + 0.002, bodyH, 0.006), material: wood), Xform(translation: V3(0, bodyBottom + bodyH / 2, cZ - cD / 2 + 0.004)))
        // Bays from the top down.
        let reveal: Float = 0.004
        let innerW = cW - 2 * t
        var yTop = bodyTop
        let gapT: Float = 0.012   // rail between bays
        for (bi, bay) in sp.bays.enumerated() {
            let yBot = yTop - bay.height
            // Divider rail under this bay (also stiffens the top).
            if bi < sp.bays.count - 1 || true {
                m.add(Prim.roundedBox(V3(innerW, gapT, cD - 0.01), radius: 0.002, bevelSegments: 1, material: wood), Xform(translation: V3(0, yBot + gapT / 2, cZ)))
            }
            switch bay.kind {
            case .open:
                // Open shelf: a recessed floor plus a vertical face rail so the cavity reads clearly.
                break
            case .drawers(let n):
                let fw = (innerW - reveal * Float(n + 1)) / Float(n)
                let fh = bay.height - gapT - reveal
                for i in 0..<n {
                    let x = -innerW / 2 + reveal + fw / 2 + Float(i) * (fw + reveal)
                    let yc = yBot + gapT + fh / 2 + reveal * 0.5 - 0.0
                    let fz = frontZ - 0.004
                    let jit = rng.float(-0.0008...0.0008)
                    m.add(Prim.roundedBox(V3(fw, fh, 0.02), radius: 0.003, bevelSegments: 1, material: wood), Xform(translation: V3(x, yc + jit, fz - 0.0)))
                    if sp.raisedPanel && fh > 0.09 && fw > 0.2 {
                        m.add(Prim.roundedBox(V3(fw - 0.07, fh - 0.07, 0.006), radius: 0.002, bevelSegments: 1, material: wood), Xform(translation: V3(x, yc + jit, fz + 0.0105)))
                        if detail {
                            // Bead around the raised panel.
                            let loop = Shape2D.roundedRect(fw - 0.058, fh - 0.058, radius: 0.004, segments: 2).map { V3(x + $0.x, yc + jit + $0.y, fz + 0.0102) }
                            m.add(Prim.sweep(Shape2D.circle(0.0016, segments: 4), along: loop, closedPath: true, caps: false, material: wood))
                        }
                    }
                    let face = fz + 0.01
                    switch sp.pull {
                    case .knob:
                        m.add(knob(material: sp.pullMaterial), Xform(translation: V3(x, yc + jit, face), rotation: facing(V3(0, 0, 1))))
                    case .bar:
                        m.add(barHandle(length: min(0.128, fw * 0.5), standoff: 0.03, radius: 0.0045, material: sp.pullMaterial), Xform(translation: V3(x, yc + jit, face)))
                    case .cup:
                        m.add(cupPull(material: sp.pullMaterial), Xform(translation: V3(x, yc + jit + fh * 0.12, face)))
                    }
                }
            }
            yTop = yBot
        }
        _ = y0
        // Pulls project in front of the top edge; shift so the whole piece spans the contract depth.
        for i in m.surfaces.indices { m.surfaces[i].positions = m.surfaces[i].positions.map { $0 + V3(0, 0, -proj / 2) } }
        groundAO(&m, height: 0.18, floor: 0.55)
        return m
    }
}
