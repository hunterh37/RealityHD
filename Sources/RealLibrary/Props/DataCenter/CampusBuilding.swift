import simd
import Foundation

/// Campus building: Tabletop-scale exterior shell of a hyperscale data-center building, precast panels, parapet, rooftop dry coolers, dock doors, louvers, fenced generator yard pad. Parts: precast concrete panels with reveals, roof parapet, dry-cooler rows on roof, loading docks, louvers, generator yard pad.
public struct CampusBuilding: RealAsset {
    public static let id = "campus-building"
    public static let summary = "Parametric data-center campus building exterior shell for tabletop."
    public static let tags = ["prop"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Building width along x in meters.
    public var width: Float = 30
    /// Building depth along z in meters (dock side is +z).
    public var depth: Float = 18
    /// Wall height to parapet top in meters.
    public var wallHeight: Float = 9.0
    /// Dock doors on the front wall.
    public var docks: Int = 4
    /// Dry-cooler units per row on the roof (two rows).
    public var coolersPerRow: Int = 5
    /// Generator containers on the yard pad.
    public var generators: Int = 4
    /// Precast panel concrete.
    public var panel: MaterialKey = "concrete.smooth:B4B1AA"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        func rnd() -> Float { Float(rng.next() % 1000) / 1000 }
        func box(_ s: V3, _ c: V3, r: Float = 0, mat: MaterialKey) {
            if r == 0 { m.add(cuboid(s, material: mat), Xform(translation: c)); return }
            m.add(Prim.roundedBox(s, radius: min(r, min(s.x, min(s.y, s.z)) * 0.4), bevelSegments: 1, material: mat), Xform(translation: c))
        }
        func cyl(_ r: Float, _ h: Float, _ c: V3, seg: Int = 12, mat: MaterialKey) {
            m.add(Prim.cylinder(radius: r, height: h, bevel: 0, segments: seg, bevelSegments: 1, material: mat), Xform(translation: c - V3(0, h / 2, 0)))
        }
        let W = width, D = depth, H = wallHeight
        let yardW: Float = 10, gap: Float = 2.5, apron: Float = 7
        let pt: Float = 0.2
        let steel: MaterialKey = "metal.powdercoat:5A6066"
        let gal: MaterialKey = "metal.galvanized"
        let galAged: MaterialKey = "metal.galvanized-aged"
        let dark: MaterialKey = "plastic.matte:1E1F20"
        let wallBase: Float = 0.18
        let wh = H - wallBase
        let zf = D / 2

        // Ground: asphalt apron, dock-side concrete walk, generator yard pad, stall stripes.
        let padX = W / 2 + gap + yardW / 2
        box(V3(W + gap + yardW + 2, 0.04, D + apron + 1.5), V3((gap + yardW) / 2, 0.02, (apron - 0.5) / 2 + 0.0), mat: "asphalt.worn")
        box(V3(W + 0.8, 0.12, 1.4), V3(0, 0.06, zf + 0.7 + pt), r: 0.01, mat: "concrete.smooth:8F8D88")
        box(V3(yardW, 0.18, D - 2), V3(padX, 0.09, 0), r: 0.012, mat: "concrete.rough:8A8781")
        for i in 1..<4 { box(V3(yardW, 0.004, 0.015), V3(padX, 0.182, -(D - 2) / 2 + Float(i) * (D - 2) / 4), mat: dark) }
        for i in 0..<8 { box(V3(0.12, 0.004, 4.0), V3(-W / 2 + 1.5 + Float(i) * 3.4, 0.002, zf + 4.6), mat: "plastic.matte:D8D6CE") }

        // Precast panel walls with reveals, dark joint backing and weather streaks.
        let dockW: Float = 3.0, dockH: Float = 4.2
        let dockPitch = W / Float(docks + 1)
        let dockXs: [Float] = (1...docks).map { -W / 2 + Float($0) * dockPitch }
        func wallRun(_ n: Int, span: Float, fixed: Float, axisX: Bool, out: Float, skipDocks: Bool = false) {
            box(axisX ? V3(span, wh - 0.1, 0.1) : V3(0.1, wh - 0.1, span), axisX ? V3(0, wallBase + wh / 2, fixed) : V3(fixed, wallBase + wh / 2, 0), mat: dark)
            let pw = span / Float(n)
            for i in 0..<n {
                let c = -span / 2 + (Float(i) + 0.5) * pw
                let t = Int(rnd() * 12)
                let tint = "concrete.smooth:\(String(format: "%02X%02X%02X", 172 + t, 169 + t, 162 + t))"
                var lowH = wh, lowY: Float = 0
                if skipDocks, dockXs.contains(where: { abs($0 - c) < pw / 2 + dockW / 2 - 0.05 }) {
                    // panel above a dock opening: shortened
                    lowH = wh - dockH - 0.1; lowY = dockH + 0.1
                    if dockXs.allSatisfy({ abs($0 - c) > 0.3 }) && lowH < 0 { continue }
                }
                let sz = axisX ? V3(pw - 0.02, lowH, pt) : V3(pt, lowH, pw - 0.02)
                let yc = wallBase + lowY + lowH / 2
                let pos = axisX ? V3(c, yc, fixed + out * pt / 2) : V3(fixed + out * pt / 2, yc, c)
                box(sz, pos, mat: tint)
                for k in 1...2 {
                    let y = wallBase + lowY + Float(k) * lowH / 3
                    let rs = axisX ? V3(pw - 0.1, 0.03, 0.01) : V3(0.01, 0.03, pw - 0.1)
                    let rp = axisX ? V3(c, y, fixed + out * (pt + 0.002)) : V3(fixed + out * (pt + 0.002), y, c)
                    box(rs, rp, mat: "concrete.rough:6A6762")
                }
                if rnd() > 0.6 {
                    let ss = axisX ? V3(0.1, 2 + rnd() * 2, 0.006) : V3(0.006, 2 + rnd() * 2, 0.1)
                    let off = (rnd() - 0.5) * pw * 0.6
                    let sp = axisX ? V3(c + off, H - 2.5, fixed + out * (pt + 0.003)) : V3(fixed + out * (pt + 0.003), H - 2.5, c + off)
                    box(ss, sp, mat: "concrete.rough:8A7C6E")
                }
            }
        }
        let nW = Int((W / 3).rounded()), nD = Int((D / 3).rounded())
        wallRun(nW, span: W, fixed: -D / 2, axisX: true, out: -1)
        wallRun(nD, span: D, fixed: -W / 2, axisX: false, out: -1)
        wallRun(nD, span: D, fixed: W / 2, axisX: false, out: 1)
        // Front wall: solid below-grade backing plus panels only between and above the docks.
        box(V3(W, wh, 0.1), V3(0, wallBase + wh / 2, zf), mat: dark)
        do {
            var edges: [Float] = [-W / 2]
            for x in dockXs { edges += [x - dockW / 2, x + dockW / 2] }
            edges.append(W / 2)
            for i in stride(from: 0, to: edges.count, by: 2) {
                let a = edges[i], b = edges[i + 1]
                let n = max(1, Int(((b - a) / 3).rounded()))
                let pw = (b - a) / Float(n)
                for j in 0..<n {
                    let c = a + (Float(j) + 0.5) * pw
                    let t = Int(rnd() * 12)
                    box(V3(pw - 0.02, wh, pt), V3(c, wallBase + wh / 2, zf + pt / 2), mat: "concrete.smooth:\(String(format: "%02X%02X%02X", 172 + t, 169 + t, 162 + t))")
                    for k in 1...2 { box(V3(pw - 0.1, 0.03, 0.01), V3(c, wallBase + Float(k) * wh / 3, zf + pt + 0.002), mat: "concrete.rough:6A6762") }
                }
            }
            for x in dockXs {
                box(V3(dockW, wh - dockH, pt), V3(x, wallBase + dockH + (wh - dockH) / 2, zf + pt / 2), r: 0.01, mat: "concrete.smooth:B1AEA7")
            }
        }
        // Plinth, caulk line, corner flashing.
        let ply: MaterialKey = "concrete.rough:77746E"
        box(V3(W + 0.1, wallBase, 0.34), V3(0, wallBase / 2, -D / 2 - pt / 2), mat: ply)
        box(V3(W + 0.1, wallBase, 0.34), V3(0, wallBase / 2, zf + pt / 2), mat: ply)
        for s: Float in [-1, 1] { box(V3(0.34, wallBase, D), V3(s * (W / 2 + pt / 2), wallBase / 2, 0), mat: ply) }

        // Roof: membrane, parapet coping, scuppers, downspouts, roof hatch.
        let wallTopY = H
        box(V3(W, 0.12, D), V3(0, wallTopY - 0.7, 0), mat: "plastic.matte:6E7072")
        let cop = V3(W + 2 * pt + 0.12, 0.07, 0.38)
        box(cop, V3(0, wallTopY + 0.035, -D / 2 - pt / 2), r: 0.008, mat: galAged)
        box(cop, V3(0, wallTopY + 0.035, zf + pt / 2), r: 0.008, mat: galAged)
        for s: Float in [-1, 1] { box(V3(0.38, 0.07, D + 2 * pt), V3(s * (W / 2 + pt / 2), wallTopY + 0.035, 0), r: 0.008, mat: galAged) }
        for i in 0..<4 {
            let x = -W / 2 + 3 + Float(i) * (W - 6) / 3
            cyl(0.045, H - 0.5, V3(x, (H - 0.5) / 2 + 0.2, -D / 2 - pt - 0.06), seg: 8, mat: "metal.galvanized-aged")
            box(V3(0.1, 0.012, 0.03), V3(x, 0.8, -D / 2 - pt - 0.03), mat: gal)
        }

        // Rooftop dry-cooler rows: casing on steel legs, three fans with guards and grille rings, header pipe.
        let roofY = wallTopY - 0.64
        let ucW: Float = 4.2, ucD: Float = 2.0, ucH: Float = 0.9, legH: Float = 0.6
        let nC = coolersPerRow
        let rowPitch = ucW + 0.5
        for row in 0..<2 {
            let z = -2.0 + Float(row) * 5.6 - 1.0
            for i in 0..<nC {
                let x = (Float(i) - Float(nC - 1) / 2) * rowPitch - 1
                let base = roofY + legH
                box(V3(ucW, ucH, ucD), V3(x, base + ucH / 2, z), mat: "metal.powdercoat:C9CCD0")
                for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
                    box(V3(0.08, legH, 0.08), V3(x + sx * (ucW / 2 - 0.2), roofY + legH / 2, z + sz * (ucD / 2 - 0.2)), mat: gal)
                } }
                box(V3(ucW - 0.2, 0.06, 0.06), V3(x, roofY + 0.4, z), mat: gal)
                for f in 0..<3 {
                    let fx = x + (Float(f) - 1) * 1.35
                    cyl(0.6, 0.03, V3(fx, base + ucH + 0.03, z), seg: 12, mat: "metal.powdercoat:2A2D30")
                    cyl(0.12, 0.08, V3(fx, base + ucH + 0.06, z), seg: 6, mat: "metal.powdercoat:3A3D41")
                }
                // coil face grille on both long sides
                for sz: Float in [-1, 1] { box(V3(ucW - 0.3, ucH - 0.3, 0.02), V3(x, base + ucH / 2, z + sz * (ucD / 2 + 0.008)), mat: "metal.aluminum") }
            }
            let hx0 = (-Float(nC - 1) / 2) * rowPitch - 1 - ucW / 2
            let hx1 = (Float(nC - 1) / 2) * rowPitch - 1 + ucW / 2
            m.add(Prim.tube([V3(hx0, roofY + 0.5, z + ucD / 2 + 0.4), V3(hx1, roofY + 0.5, z + ucD / 2 + 0.4)], radii: [0.12, 0.12], sides: 12, seamTile: 0.3, material: "rubber.tubing:1F4E8C"), .identity)
            m.add(Prim.tube([V3(hx0, roofY + 0.3, z + ucD / 2 + 0.4), V3(hx1, roofY + 0.3, z + ucD / 2 + 0.4)], radii: [0.1, 0.1], sides: 12, seamTile: 0.3, material: "rubber.tubing:B51D17"), .identity)
        }
        // Roof hatch and exhaust stacks.
        box(V3(1.2, 0.9, 1.0), V3(W / 2 - 3, roofY + 0.45, D / 2 - 2.5), r: 0.01, mat: "metal.powdercoat:B8BBB6")
        for i in 0..<3 { cyl(0.18, 1.2, V3(-W / 2 + 2 + Float(i) * 1.0, roofY + 0.6, D / 2 - 2.2), seg: 10, mat: galAged); cyl(0.24, 0.05, V3(-W / 2 + 2 + Float(i) * 1.0, roofY + 1.22, D / 2 - 2.2), seg: 10, mat: gal) }

        // Loading docks: dark opening, sectional door ribs, bumpers, wheel guides, dock light, numbers.
        for (i, x) in dockXs.enumerated() {
            box(V3(dockW, dockH, 0.12), V3(x, wallBase + dockH / 2, zf - 0.02), mat: dark)
            let open = rnd() > 0.7
            let doorTop: Float = open ? dockH - 1.2 : dockH
            box(V3(dockW - 0.1, doorTop - 0.1, 0.06), V3(x, wallBase + 0.05 + (doorTop - 0.1) / 2 + (open ? 1.2 : 0), zf + 0.02), mat: "metal.powdercoat:D9DAD5")
            for k in 1..<5 { box(V3(dockW - 0.1, 0.02, 0.012), V3(x, wallBase + Float(k) * doorTop / 5 + (open ? 1.2 : 0), zf + 0.06), mat: "metal.powdercoat:A8ABA8") }
            for s: Float in [-1, 1] {
                box(V3(0.15, dockH + 0.1, 0.14), V3(x + s * (dockW / 2 + 0.07), wallBase + dockH / 2, zf + 0.1), mat: steel)
                box(V3(0.2, 0.3, 0.1), V3(x + s * (dockW / 2 - 0.3), 1.2, zf + pt + 0.05), r: 0.015, mat: "rubber.tubing:1A1A1A")
                box(V3(0.12, 0.18, 1.2), V3(x + s * (dockW / 2 - 0.4), 0.09 + 0.01, zf + pt + 1.0), mat: "concrete.rough:6F6C66")
            }
            box(V3(dockW + 0.3, 0.14, 0.14), V3(x, wallBase + dockH + 0.07, zf + 0.1), mat: steel)
            box(V3(0.28, 0.14, 0.06), V3(x, wallBase + dockH + 0.35, zf + pt + 0.04), r: 0.01, mat: "emissive.panel")
            box(V3(0.4, 0.4, 0.01), V3(x, wallBase + dockH + 1.0, zf + pt + 0.006), mat: "plastic.matte:E3B81A")
            box(V3(dockW - 0.4, 0.02, 1.1), V3(x, 0.1, zf + pt + 0.55), mat: galAged)   // dock leveler plate
            if i % 2 == 0 { box(V3(0.5, 0.5, 0.004), V3(x + 0.9, wallBase + dockH + 1.0, zf + pt + 0.004), mat: dark) }
        }
        // Dock-side bollards.
        for x in dockXs { for s: Float in [-1, 1] { cyl(0.1, 1.0, V3(x + s * (dockW / 2 + 0.6), 0.5 + 0.1, zf + 3.2), seg: 10, mat: "metal.powdercoat:E3B81A") } }

        // Louver banks: frame, angled blades, backing, on back wall and west wall.
        func louverBank(_ c: V3, axisX: Bool, out: Float, w: Float, h: Float) {
            let fr: MaterialKey = "metal.powdercoat:7A7F84"
            let ox = axisX ? V3(0, 0, out * 0.03) : V3(out * 0.03, 0, 0)
            box(axisX ? V3(w, h, 0.05) : V3(0.05, h, w), c + ox * 0.5, mat: dark)
            let n = Int(h / 0.12)
            for k in 0..<n {
                let y = c.y - h / 2 + 0.08 + Float(k) * (h - 0.16) / Float(n - 1)
                let ang: Float = -0.7 * out * (axisX ? 1 : -1)
                let q = axisX ? simd_quatf(angle: ang, axis: V3(1, 0, 0)) : simd_quatf(angle: -ang, axis: V3(0, 0, 1))
                let sz = axisX ? V3(w - 0.12, 0.012, 0.14) : V3(0.14, 0.012, w - 0.12)
                m.add(cuboid(sz, material: "metal.aluminum"), Xform(translation: V3(c.x, y, c.z) + ox * 2.2, rotation: q))
            }
            for s: Float in [-1, 1] { box(axisX ? V3(0.06, h + 0.1, 0.1) : V3(0.1, h + 0.1, 0.06), V3(c.x + (axisX ? s * w / 2 : 0), c.y, c.z + (axisX ? 0 : s * w / 2)) + ox * 2.2, mat: fr) }
            for s: Float in [-1, 1] { box(axisX ? V3(w + 0.1, 0.06, 0.1) : V3(0.1, 0.06, w + 0.1), V3(c.x, c.y + s * h / 2, c.z) + ox * 2.2, mat: fr) }
        }
        for i in 0..<3 { louverBank(V3(-W / 2 + 5 + Float(i) * 10, 2.6, -D / 2 - pt - 0.02), axisX: true, out: -1, w: 3.4, h: 2.4) }
        louverBank(V3(-W / 2 - pt - 0.02, 2.6, -3), axisX: false, out: -1, w: 3.4, h: 2.4)
        louverBank(V3(-W / 2 - pt - 0.02, 2.6, 4), axisX: false, out: -1, w: 3.4, h: 2.4)
        // Personnel entry with canopy.
        let ex = -W / 2 + 1.8
        box(V3(1.1, 2.2, 0.08), V3(ex, wallBase + 1.1, zf + pt + 0.02), r: 0.01, mat: "metal.powdercoat:2F4A63")
        box(V3(2.0, 0.1, 1.1), V3(ex, 3.0, zf + pt + 0.55), r: 0.01, mat: "metal.powdercoat:5A6066")
        for s: Float in [-1, 1] { box(V3(0.06, 2.8, 0.06), V3(ex + s * 0.9, 1.5, zf + pt + 1.0), mat: steel) }
        box(V3(0.5, 0.2, 0.08), V3(ex + 1.4, 2.8, zf + pt + 0.04), mat: "emissive.panel")

        // Generator yard: pad, containers with doors and stacks, fence, bollards, gate.
        let gw: Float = 2.4, gd: Float = 6.0, gh: Float = 2.7
        let gz0 = -(D - 2) / 2 + 0.2 + gd / 2
        for i in 0..<generators {
            let z = (Float(i) - Float(generators - 1) / 2) * (gd + 0.6) * 0.78
            let xg = padX + (i % 2 == 0 ? -1.2 : 1.2)
            _ = gz0
            box(V3(gw, gh, gd * 0.55), V3(xg, 0.18 + gh / 2, z), r: 0.02, mat: "metal.powdercoat:C8C9C2")
            box(V3(gw + 0.06, 0.12, gd * 0.55 + 0.06), V3(xg, 0.18 + 0.06, z), mat: steel)
            for k in 0..<3 { box(V3(0.01, gh - 0.5, 0.9), V3(xg - gw / 2 - 0.004, 0.18 + gh / 2, z - 1.0 + Float(k) * 1.0), mat: "metal.powdercoat:A5A8A3") }
            cyl(0.09, 1.0, V3(xg + 0.4, 0.18 + gh + 0.5, z + 0.8), seg: 8, mat: "metal.powdercoat:3A3A3A")
            box(V3(0.3, 0.1, 0.3), V3(xg - 0.5, 0.18 + gh + 0.05, z - 0.6), mat: gal)
        }
        let fz = D / 2 - 0.6
        let fx0 = W / 2 + gap + 0.2, fx1 = W / 2 + gap + yardW - 0.2
        let fh: Float = 2.4
        let fm: MaterialKey = "metal.galvanized"
        for (ax, bx, zz) in [(fx0, fx1, -fz), (fx0, fx1, fz)] {
            box(V3(bx - ax, fh - 0.2, 0.012), V3((ax + bx) / 2, fh / 2, zz), mat: "metal.perforated")
            box(V3(bx - ax, 0.05, 0.05), V3((ax + bx) / 2, fh, zz), mat: fm)
        }
        for zz in [-fz, fz] { for i in 0...3 { cyl(0.04, fh, V3(fx0 + Float(i) * (fx1 - fx0) / 3, fh / 2, zz), seg: 6, mat: fm) } }
        box(V3(0.012, fh - 0.2, 2 * fz), V3(fx1, fh / 2, 0), mat: "metal.perforated")
        box(V3(0.012, fh - 0.2, 2 * fz - 6.0), V3(fx0, fh / 2, -3.0 + 0.0), mat: "metal.perforated")
        for i in 0...2 { cyl(0.04, fh, V3(fx1, fh / 2, -fz + Float(i) * fz), seg: 6, mat: fm) }
        // Wall packs and a generator-yard fuel tank pad marker.
        for x in stride(from: -W / 2 + 4, to: W / 2, by: 8) { box(V3(0.3, 0.14, 0.12), V3(x, 4.8, -D / 2 - pt - 0.06), r: 0.01, mat: "metal.powdercoat:2A2D30") }

        // Centre the footprint on x/z with the base at y = 0.
        let b = m.bounds
        let shift = V3(-(b.min.x + b.max.x) / 2, 0, -(b.min.z + b.max.z) / 2)
        var out = m.transformed(Xform(translation: shift))
        groundAO(&out, height: 0.6, floor: 0)
        return LODModel(out)
    }
}
