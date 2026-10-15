import simd
import Foundation

/// Two-door wardrobe, 100 x 200 x 60 cm: painted shaker armoire with stepped crown moulding, recessed plinth, two
/// framed-and-panel doors on exposed hinge knuckles with nickel pulls, a bottom drawer, a hanging rail with hangers
/// and garments, a top shelf with folded linens and a painted interior. Rig: `doorL` and `doorR` swing about the
/// outer edges, `drawer` slides out. States: closed, open.
public struct Wardrobe: RealArticulated {
    public static let id = "wardrobe"
    public static let summary = "Two-door painted wardrobe with a bottom drawer, hanging rail with garments, top shelf and nickel pulls; doors and drawer open."
    public static let tags = ["prop", "floorplan", "bedroom", "furniture", "wood", "interior", "articulated"]
    public static let budget = 11500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 1.25, studio: true)

    /// Overall size in meters (x width, y height, z depth), pulls included.
    public var size = V3(1.0, 2.0, 0.6)
    /// Painted case and doors.
    public var paint: MaterialKey = "wood.painted-shaker:A9A08F"
    /// Worn paint at the crown, plinth and door edges.
    public var wornPaint: MaterialKey = "wood.painted-shaker-worn:A9A08F"
    /// Hardware.
    public var hardware: MaterialKey = "metal.brushed-nickel"
    /// Door swing in degrees for the open state.
    public var doorAngle: Float = 100
    /// Drawer travel in meters for the open state.
    public var drawerTravel: Float = 0.3
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [6])
        let W = size.x, H = size.y, D = size.z
        let t: Float = 0.019, plinth: Float = 0.09, crownH: Float = 0.07
        let cW = W - 0.04
        let zf = D / 2 - 0.06                       // front plane of the case; doors sit in front of it
        let cD = zf + D / 2                         // case depth (back flush at -D / 2)
        let cz = (zf - D / 2) / 2
        let top = H - crownH, bottom = plinth
        let drawerTop: Float = 0.315, doorBot: Float = 0.322, doorTop = top + 0.012 - 0.003
        let interior: MaterialKey = "wood.painted-shaker:C9C0AD"
        let doorT: Float = 0.02
        let pullProj: Float = 0.03

        // --- Static case, both LODs.
        for l in 0..<2 {
            var m = Model(name: Self.id)
            for s: Float in [-1, 1] {
                m.add(Prim.roundedBox(V3(t, top - bottom, cD), radius: 0.003, bevelSegments: 1, material: paint), Xform(translation: V3(s * (cW / 2 - t / 2), (top + bottom) / 2, cz)))
            }
            m.add(Prim.roundedBox(V3(cW - 2 * t + 0.002, t, cD - 0.01), radius: 0.002, bevelSegments: 1, material: interior), Xform(translation: V3(0, top - t / 2, cz - 0.005)))
            m.add(Prim.roundedBox(V3(cW - 2 * t + 0.002, 0.018, cD - 0.01), radius: 0.002, bevelSegments: 1, material: interior), Xform(translation: V3(0, bottom + 0.009, cz - 0.005)))
            // Shelf above the drawer.
            m.add(Prim.roundedBox(V3(cW - 2 * t + 0.002, 0.018, cD - 0.03), radius: 0.002, bevelSegments: 1, material: interior), Xform(translation: V3(0, doorBot - 0.009 - 0.003, cz - 0.015)))
            m.add(cuboid(V3(cW - 2 * t + 0.002, top - bottom, 0.008), material: interior), Xform(translation: V3(0, (top + bottom) / 2, -D / 2 + 0.004)))
            // Front face frame: stiles at the sides, rail between drawer and doors.
            m.add(Prim.roundedBox(V3(cW - 2 * t, 0.03, 0.016), radius: 0.002, bevelSegments: 1, material: paint), Xform(translation: V3(0, doorBot - 0.012, zf - 0.008)))
            // Top shelf and a lower hanging-rail cleat.
            let shelfY = top - 0.17
            m.add(Prim.roundedBox(V3(cW - 2 * t + 0.002, 0.018, cD - 0.03), radius: 0.002, bevelSegments: 1, material: interior), Xform(translation: V3(0, shelfY, cz - 0.015)))
            // Plinth: recessed toe kick with a scalloped apron.
            m.add(Prim.roundedBox(V3(cW - 0.03, plinth - 0.01, cD - 0.04), radius: 0.003, bevelSegments: 1, material: wornPaint), Xform(translation: V3(0, (plinth - 0.01) / 2 + 0.005, cz - 0.0)))
            m.add(Prim.roundedBox(V3(cW + 0.012, 0.026, cD + 0.012), radius: 0.004, bevelSegments: 1, material: wornPaint), Xform(translation: V3(0, plinth - 0.013, cz)))
            // Stepped crown moulding with a cove.
            m.add(Prim.roundedBox(V3(cW + 0.012, 0.03, cD + 0.02), radius: 0.004, bevelSegments: 1, material: paint), Xform(translation: V3(0, top + 0.015, cz + 0.005)))
            m.add(Prim.roundedBox(V3(W - 0.008, 0.024, D - 0.05 + 0.02), radius: 0.005, bevelSegments: 2, material: wornPaint), Xform(translation: V3(0, H - 0.026, (-D / 2 + zf + 0.02) / 2 + 0.0)))
            m.add(Prim.roundedBox(V3(W, 0.014, D - 0.05 + 0.032), radius: 0.004, bevelSegments: 2, material: paint), Xform(translation: V3(0, H - 0.007, (-D / 2 + zf + 0.032) / 2)))
            // Hanging rod with end sockets.
            let rodY = shelfY - 0.12, rodZ = cz - 0.02
            m.add(Prim.cylinder(radius: 0.0125, height: cW - 2 * t, bevel: 0.002, segments: l == 0 ? 14 : 8, bevelSegments: 1, material: "metal.chrome"),
                  Xform(translation: V3(-(cW - 2 * t) / 2, rodY, rodZ), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
            for s: Float in [-1, 1] {
                m.add(Prim.roundedBox(V3(0.014, 0.05, 0.06), radius: 0.003, bevelSegments: 1, material: "metal.brushed-nickel"), Xform(translation: V3(s * (cW / 2 - t - 0.007), rodY, rodZ)))
            }
            if l == 0 {
                // Garments on hangers, hanging sideways along the rail (thin in X, wide in Z).
                var x = -(cW / 2 - t) + 0.045
                let cols: [MaterialKey] = ["fabric.linen:E9E4D8", "fabric.linen:6B7F95", "fabric.wool:3C4350", "fabric.linen:B9A68A", "fabric.canvas:7A8268", "fabric.linen:C9D3DA", "fabric.wool:8A4B45", "fabric.linen:F1EEE6"]
                var gi = 0
                while x < cW / 2 - t - 0.05 {
                    let len = rng.float(0.5...0.95), gw = rng.float(0.36...0.44), gt = rng.float(0.03...0.05)
                    let mat = cols[gi % cols.count]
                    let gy = rodY - 0.02 - len / 2 - 0.04
                    let lean = rng.float(-4...4)
                    m.add(Prim.roundedBox(V3(gt, len, gw), radius: 0.012, bevelSegments: 1, material: mat),
                          Xform(translation: V3(x, gy, rodZ), rotation: simd_quatf(degrees: lean, axis: V3(0, 0, 1))))
                    // Wire hanger and hook.
                    let hy = rodY - 0.012
                    m.add(Prim.tube([V3(x, hy - 0.07, rodZ - gw / 2), V3(x, hy - 0.002, rodZ), V3(x, hy - 0.07, rodZ + gw / 2)], radii: [0.0012, 0.0012, 0.0012], sides: 4, seamTile: 0.02, material: "metal.chrome"))
                    x += gt + rng.float(0.035...0.07); gi += 1
                }
                // Folded linens on the top shelf.
                var sx = -cW / 2 + t + 0.13
                var k = 0
                while sx < cW / 2 - t - 0.12 {
                    let n = rng.int(1...3)
                    for j in 0..<n {
                        m.add(Prim.roundedBox(V3(0.24, 0.04, 0.34), radius: 0.01, bevelSegments: 1, material: cols[(k + j) % cols.count]),
                              Xform(translation: V3(sx, shelfY + 0.009 + 0.02 + Float(j) * 0.04, cz - 0.03 + rng.float(-0.01...0.01)), rotation: simd_quatf(degrees: rng.float(-3...3), axis: .up)))
                    }
                    sx += 0.28; k += 1
                }
            }
            rig.base[l] = m
        }

        // --- Doors: frame-and-panel with nickel hinge knuckles and a vertical pull.
        let doorW = cW / 2 - 0.0015, doorH = doorTop - doorBot
        let stile: Float = 0.068
        for (name, s) in [("doorL", Float(-1)), ("doorR", Float(1))] {
            let pivot = V3(s * cW / 2, (doorBot + doorTop) / 2, zf + doorT / 2)
            let cx = s * (cW / 2 - doorW / 2)
            let cy = (doorBot + doorTop) / 2, cz2 = zf + doorT / 2
            rig.part(name, pivot: pivot, joint: .hinge(axis: V3(0, 1, 0), s < 0 ? (-doorAngle - 5)...0 : 0...(doorAngle + 5), duration: 0.9))
            // Stiles, rails and recessed panel.
            for sx2: Float in [-1, 1] {
                rig.add(Prim.roundedBox(V3(stile, doorH, doorT), radius: 0.003, bevelSegments: 1, material: paint), Xform(translation: V3(cx + sx2 * (doorW / 2 - stile / 2), cy, cz2)), to: name)
            }
            for sy: Float in [-1, 1] {
                rig.add(Prim.roundedBox(V3(doorW - 2 * stile + 0.004, stile, doorT), radius: 0.003, bevelSegments: 1, material: paint), Xform(translation: V3(cx, cy + sy * (doorH / 2 - stile / 2), cz2)), to: name)
            }
            rig.add(Prim.roundedBox(V3(doorW - 2 * stile + 0.006, doorH - 2 * stile + 0.006, 0.008), radius: 0.002, bevelSegments: 1, material: paint),
                    Xform(translation: V3(cx, cy, zf + 0.007)), to: name)
            // Inner bead lip around the panel opening (front).
            let loop = Shape2D.roundedRect(doorW - 2 * stile + 0.002, doorH - 2 * stile + 0.002, radius: 0.004, segments: 2).map { V3(cx + $0.x, cy + $0.y, zf + doorT - 0.0012) }
            rig.add(Prim.sweep(Shape2D.circle(0.0028, segments: 4), along: loop, closedPath: true, caps: false, material: wornPaint), to: name)
            // Pull near the meeting edge.
            let px = s * 0.035
            rig.add(barHandle(length: 0.14, standoff: pullProj - 0.0045, radius: 0.0045, material: hardware),
                    Xform(translation: V3(px, cy - 0.05, zf + doorT), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))), to: name)
            // Hinge knuckles on the outer edge.
            for hy in [doorBot + 0.14, cy, doorTop - 0.14] {
                rig.add(Prim.cylinder(radius: 0.0065, height: 0.07, bevel: 0.0012, segments: 10, bevelSegments: 1, material: "metal.brushed-nickel"),
                        Xform(translation: V3(s * (cW / 2 + 0.0), hy - 0.035, zf + doorT - 0.004)), to: name)
                rig.add(Prim.roundedBox(V3(0.026, 0.06, 0.003), radius: 0.001, bevelSegments: 1, material: "metal.brushed-nickel"),
                        Xform(translation: V3(s * (cW / 2 - 0.013), hy, zf + doorT + 0.0006)), to: name, lods: 0...0)
            }
        }

        // --- Drawer.
        let dH = drawerTop - plinth - 0.004
        let dy = plinth + 0.004 + dH / 2
        let dz = zf + doorT / 2
        rig.part("drawer", pivot: V3(0, dy, dz), joint: .slide(axis: V3(0, 0, 1), 0...(drawerTravel + 0.02), duration: 0.7))
        rig.add(Prim.roundedBox(V3(cW - 2 * t, dH, doorT), radius: 0.004, bevelSegments: 1, material: paint), Xform(translation: V3(0, dy, dz)), to: "drawer")
        rig.add(Prim.roundedBox(V3(cW - 2 * t - 0.07, dH - 0.07, 0.007), radius: 0.002, bevelSegments: 1, material: paint), Xform(translation: V3(0, dy, dz + doorT / 2 + 0.002)), to: "drawer")
        rig.add(barHandle(length: 0.14, standoff: pullProj - 0.0045, radius: 0.0045, material: hardware), Xform(translation: V3(0, dy, zf + doorT + 0.0035)), to: "drawer")
        let bw = cW - 2 * t - 0.05, bd = cD - 0.1, bh = dH - 0.04
        let bz = zf - bd / 2
        for s: Float in [-1, 1] {
            rig.add(Prim.roundedBox(V3(0.012, bh, bd), radius: 0.002, bevelSegments: 1, material: interior), Xform(translation: V3(s * bw / 2, dy - 0.01, bz)), to: "drawer")
        }
        rig.add(Prim.roundedBox(V3(bw, 0.01, bd), radius: 0.002, bevelSegments: 1, material: interior), Xform(translation: V3(0, dy - 0.01 - bh / 2 + 0.005, bz)), to: "drawer")
        rig.add(Prim.roundedBox(V3(bw, bh, 0.012), radius: 0.002, bevelSegments: 1, material: interior), Xform(translation: V3(0, dy - 0.01, bz - bd / 2 + 0.006)), to: "drawer")
        let cols: [MaterialKey] = ["fabric.linen:E9E4D8", "fabric.linen:6B7F95", "fabric.wool:3C4350", "fabric.linen:B9A68A"]
        for k in 0..<5 {
            let z = zf - 0.1 - Float(k) * 0.085
            rig.add(Prim.roundedBox(V3(bw - 0.03, 0.06 + Float(rng.int(0...1)) * 0.02, 0.075), radius: 0.012, bevelSegments: 2, material: cols[k % cols.count]),
                    Xform(translation: V3(0, dy - 0.01 - bh / 2 + 0.01 + 0.03, z), rotation: simd_quatf(degrees: rng.float(-2...2), axis: .up)), to: "drawer", lods: 0...0)
        }
        groundAO(&rig, height: 0.2, floor: 0.55)
        rig.states = [RigState("closed"),
                      RigState("open", ["doorL": -doorAngle, "doorR": doorAngle, "drawer": drawerTravel])]
        return rig
    }
}
