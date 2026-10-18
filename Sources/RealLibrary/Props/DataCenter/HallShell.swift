import simd
import Foundation

/// Hall shell: parametric data-center building shell with tilt-up concrete wall panels, steel columns with yellow impact guards, Warren roof trusses with purlins, partial roof deck, exposed MEP (duct, cable tray, chilled-water pipes, sprinkler main) and a sealed concrete floor with expansion joints. Origin at the floor center, +z is the open loading wall.
public struct HallShell: RealAsset {
    public static let id = "hall-shell"
    public static let summary = "Parametric data-center hall shell with tilt-up concrete walls, steel columns with impact guards, roof trusses, exposed MEP and sealed concrete floor with expansion joints."
    public static let tags = ["prop"]
    public static let budget = 20000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 32, distance: 1.5, studio: false)

    /// Interior length along z in meters.
    public var length: Float = 24
    /// Interior width along x in meters.
    public var width: Float = 16
    /// Clear height from slab to truss bottom chord in meters.
    public var clearHeight: Float = 8
    /// Wall panel concrete.
    public var wall: MaterialKey = "concrete.rough:A8A59E"
    /// Floor slab.
    public var floor: MaterialKey = "concrete.smooth:8E8C88"
    /// Structural steel paint.
    public var steel: MaterialKey = "metal.powdercoat:4E5359"
    /// Impact guard paint.
    public var guardPaint: MaterialKey = "metal.powdercoat:E3B81A"
    /// Fraction of the roof (from the back wall) covered by deck.
    public var deckCoverage: Float = 0.4
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        func rnd() -> Float { Float(rng.next() % 1000) / 1000 }
        let L = length, W = width, H = clearHeight
        let slab: Float = 0.15, tw: Float = 0.25
        let trussD: Float = 1.2
        let wallTop = slab + H + trussD + 0.5
        let bays = max(2, Int((L / 6).rounded()))
        let bay = L / Float(bays)

        func box(_ s: V3, _ c: V3, r: Float = 0, mat: MaterialKey) {
            if r == 0 { m.add(cuboid(s, material: mat), Xform(translation: c)); return }
            m.add(Prim.roundedBox(s, radius: min(r, min(s.x, min(s.y, s.z)) * 0.4), bevelSegments: 1, material: mat), Xform(translation: c))
        }
        func beam(_ a: V3, _ b: V3, _ w: Float, _ h: Float, mat: MaterialKey) {
            let d = b - a, len = simd_length(d)
            let q = simd_quatf(from: V3(1, 0, 0), to: d / len)
            m.add(cuboid(V3(len, h, w), material: mat), Xform(translation: (a + b) / 2, rotation: q))
        }
        func pipe(_ a: V3, _ b: V3, _ r: Float, sides: Int = 12, mat: MaterialKey) {
            m.add(Prim.tube([a, b], radii: [r, r], sides: sides, seamTile: 0.3, material: mat), .identity)
        }

        // Floor: sealed slab, saw-cut expansion joints on a grid, sealer wear paths, a floor drain.
        box(V3(W + 2 * tw, slab, L + 2 * tw), V3(0, slab / 2, 0), r: 0.01, mat: floor)
        let jointMat: MaterialKey = "plastic.matte:1E1E1F"
        for i in 1..<bays { box(V3(W, 0.002, 0.012), V3(0, slab + 0.001, -L / 2 + Float(i) * bay), mat: jointMat) }
        for i in 1..<3 { box(V3(0.012, 0.002, L), V3(-W / 2 + Float(i) * W / 3, slab + 0.001, 0), mat: jointMat) }
        for i in 0..<5 {
            box(V3(0.6 + rnd(), 0.0015, 0.5 + 2 * rnd()), V3(-W / 2 + W * rnd(), slab + 0.0012, -L / 2 + L * rnd()), mat: "concrete.smooth:777571")
        }
        box(V3(0.3, 0.002, 0.3), V3(W / 4, slab + 0.001, L / 4), mat: "metal.galvanized-aged")

        // Tilt-up wall panels with reveals, caulked joints and base staining.
        let reveal: MaterialKey = "concrete.rough:5D5B57"
        func panelsAlong(_ n: Int, span: Float, fixed: Float, axisX: Bool, skip: (Float) -> Bool) {
            let pw = span / Float(n)
            for i in 0..<n {
                let c = -span / 2 + (Float(i) + 0.5) * pw
                if skip(c) { continue }
                let tint = "concrete.rough:\(String(format: "%02X%02X%02X", 160 + Int(rnd() * 14), 157 + Int(rnd() * 14), 150 + Int(rnd() * 12)))"
                let sz = axisX ? V3(pw - 0.012, wallTop - slab, tw) : V3(tw, wallTop - slab, pw - 0.012)
                let pos = axisX ? V3(c, slab + (wallTop - slab) / 2, fixed) : V3(fixed, slab + (wallTop - slab) / 2, c)
                box(sz, pos, r: 0.012, mat: tint)
                let out: Float = fixed > 0 ? 1 : -1
                for k in 0..<3 {
                    let y = slab + 1.4 + Float(k) * (wallTop - slab - 2) / 2.2
                    let rs = axisX ? V3(pw - 0.2, 0.025, 0.006) : V3(0.006, 0.025, pw - 0.2)
                    let rp = axisX ? V3(c, y, fixed + out * (tw / 2 + 0.002)) : V3(fixed + out * (tw / 2 + 0.002), y, c)
                    box(rs, rp, mat: reveal)
                }
                let bs = axisX ? V3(pw - 0.05, 0.5, 0.005) : V3(0.005, 0.5, pw - 0.05)
                let bp = axisX ? V3(c, slab + 0.25, fixed + out * (tw / 2 + 0.002)) : V3(fixed + out * (tw / 2 + 0.002), slab + 0.25, c)
                box(bs, bp, mat: "concrete.rough:6F6C66")
                // Rust and water streak below the roof edge.
                if rnd() > 0.55 {
                    let ss = axisX ? V3(0.12, 1.5 + rnd() * 2, 0.004) : V3(0.004, 1.5 + rnd() * 2, 0.12)
                    let sp = axisX ? V3(c + (rnd() - 0.5) * pw * 0.6, wallTop - 1.1, fixed + out * (tw / 2 + 0.0015)) : V3(fixed + out * (tw / 2 + 0.0015), wallTop - 1.1, c + (rnd() - 0.5) * pw * 0.6)
                    box(ss, sp, mat: "concrete.rough:7A6A5C")
                }
            }
        }
        let nL = bays * 1, nW = max(2, Int((W / 6).rounded()))
        panelsAlong(nL, span: L, fixed: -W / 2 - tw / 2, axisX: false) { _ in false }
        panelsAlong(nL, span: L, fixed: W / 2 + tw / 2, axisX: false) { _ in false }
        panelsAlong(nW, span: W, fixed: -L / 2 - tw / 2, axisX: true) { _ in false }
        // Loading wall: three roll-up door openings, panels above and between.
        let doorW: Float = 3.6, doorH: Float = 4.5
        let doorXs: [Float] = [-W / 3, 0, W / 3]
        let zf = L / 2 + tw / 2
        var edges: [Float] = [-W / 2]
        for x in doorXs { edges += [x - doorW / 2, x + doorW / 2] }
        edges.append(W / 2)
        for i in stride(from: 0, to: edges.count, by: 2) {
            let a = edges[i], b = edges[i + 1]
            box(V3(b - a, wallTop - slab, tw), V3((a + b) / 2, slab + (wallTop - slab) / 2, zf), r: 0.012, mat: "concrete.rough:A5A29B")
        }
        for x in doorXs {
            box(V3(doorW, wallTop - slab - doorH, tw), V3(x, slab + doorH + (wallTop - slab - doorH) / 2, zf), r: 0.012, mat: "concrete.rough:A5A29B")
            for s: Float in [-1, 1] { box(V3(0.12, doorH, 0.3), V3(x + s * (doorW / 2 + 0.06), slab + doorH / 2, zf + 0.02), r: 0.005, mat: steel) }
            box(V3(doorW + 0.3, 0.2, 0.3), V3(x, slab + doorH + 0.1, zf + 0.02), r: 0.005, mat: steel)
            // Dock bumpers and bollards outside.
            for s: Float in [-1, 1] {
                m.add(Prim.cylinder(radius: 0.1, height: 1.0, bevel: 0.015, segments: 12, bevelSegments: 1, material: guardPaint), Xform(translation: V3(x + s * (doorW / 2 + 0.5), slab, zf + 0.8)))
            }
        }
        // Roof edge coping.
        box(V3(W + 2 * tw + 0.1, 0.08, 0.34), V3(0, wallTop + 0.04, -L / 2 - tw / 2), r: 0.01, mat: "metal.galvanized-aged")
        box(V3(W + 2 * tw + 0.1, 0.08, 0.34), V3(0, wallTop + 0.04, L / 2 + tw / 2), r: 0.01, mat: "metal.galvanized-aged")
        for s: Float in [-1, 1] { box(V3(0.34, 0.08, L + 2 * tw), V3(s * (W / 2 + tw / 2), wallTop + 0.04, 0), r: 0.01, mat: "metal.galvanized-aged") }

        // Columns: two interior rows plus wall pilasters, each with base plate, bolts, cap and impact guard.
        let colX: [Float] = [-W / 4, W / 4]
        func column(_ x: Float, _ z: Float) {
            let top = slab + H
            box(V3(0.55, 0.03, 0.55), V3(x, slab + 0.015, z), r: 0.004, mat: steel)
            box(V3(0.3, top - slab - 0.03, 0.3), V3(x, slab + 0.03 + (top - slab - 0.03) / 2, z), r: 0.012, mat: steel)
            box(V3(0.5, 0.03, 0.5), V3(x, top - 0.015, z), r: 0.004, mat: steel)
            for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
                m.add(Prim.cylinder(radius: 0.016, height: 0.07, bevel: 0.004, segments: 6, bevelSegments: 1, material: "metal.galvanized"), Xform(translation: V3(x + sx * 0.22, slab + 0.03, z + sz * 0.22)))
            } }
            // Impact guard: yellow sleeve with black hazard bands, scuffed.
            box(V3(0.42, 1.0, 0.42), V3(x, slab + 0.08 + 0.5, z), r: 0.03, mat: guardPaint)
            for k in 0..<2 { box(V3(0.425, 0.1, 0.425), V3(x, slab + 0.33 + Float(k) * 0.4, z), r: 0.02, mat: "plastic.matte:1A1A1A") }
            box(V3(0.2, 0.02, 0.003), V3(x + 0.05, slab + 0.62, z + 0.212), mat: "metal.powdercoat:6A6B6E")
            box(V3(0.003, 0.2, 0.15), V3(x + 0.212, slab + 0.45, z - 0.05), mat: "metal.powdercoat:5A5446")
        }
        for i in 0...bays { for x in colX { column(x, -L / 2 + Float(i) * bay) } }

        // Roof trusses: Warren pattern spanning the width at each column line, with wall bearing plates.
        let nSeg = max(6, Int((W / 2).rounded()) / 2 * 2)
        let yb = slab + H, yt = yb + trussD
        for i in 0...bays {
            let z = -L / 2 + Float(i) * bay
            beam(V3(-W / 2 - tw / 2, yb, z), V3(W / 2 + tw / 2, yb, z), 0.16, 0.12, mat: steel)
            beam(V3(-W / 2 - tw / 2, yt, z), V3(W / 2 + tw / 2, yt, z), 0.16, 0.12, mat: steel)
            let dx = W / Float(nSeg)
            for k in 0..<nSeg {
                let x0 = -W / 2 + Float(k) * dx, x1 = x0 + dx
                let up = k % 2 == 0
                beam(V3(x0, up ? yb : yt, z), V3(x1, up ? yt : yb, z), 0.08, 0.08, mat: steel)
            }
            for k in 0...nSeg where k % 2 == 0 {
                let x = -W / 2 + Float(k) * dx
                beam(V3(x, yb, z), V3(x, yt, z), 0.08, 0.08, mat: steel)
            }
        }
        // Purlins along z with bridging, deck panels over the rear part.
        let purlinN = 9
        for k in 0..<purlinN {
            let x = -W / 2 + 0.3 + Float(k) * (W - 0.6) / Float(purlinN - 1)
            box(V3(0.06, 0.18, L + 0.2), V3(x, yt + 0.15, 0), mat: "metal.galvanized")
        }
        let deckLen = L * deckCoverage
        box(V3(W + 0.2, 0.05, deckLen), V3(0, yt + 0.26, -L / 2 + deckLen / 2), mat: "metal.galvanized-aged")
        for i in 0..<Int(W / 0.6) { box(V3(0.02, 0.02, deckLen), V3(-W / 2 + 0.3 + Float(i) * 0.6, yt + 0.295, -L / 2 + deckLen / 2), mat: "metal.galvanized") }

        // Exposed MEP under the trusses: duct, ladder tray, chilled-water pair, sprinkler main, conduit, light bars, hangers.
        let ym = yb - 0.55
        pipe(V3(-W / 4 - 1.6, ym, -L / 2), V3(-W / 4 - 1.6, ym, L / 2), 0.38, sides: 24, mat: "metal.galvanized-aged")
        for i in 0...bays * 2 {
            let z = -L / 2 + Float(i) * bay / 2
            box(V3(0.04, 0.05, 0.1), V3(-W / 4 - 1.6, ym + 0.4, z), mat: "metal.galvanized")
            box(V3(0.02, yb - ym - 0.4, 0.02), V3(-W / 4 - 1.6 + 0.2, (yb + ym + 0.4) / 2, z), mat: "metal.galvanized")
        }
        for s: Float in [-1, 1] { box(V3(0.04, 0.1, L), V3(W / 4 + 1.2 + s * 0.3, ym + 0.1, 0), mat: "metal.powdercoat:C9CCD0") }
        for i in 0..<Int(L / 0.3) { box(V3(0.6, 0.025, 0.03), V3(W / 4 + 1.2, ym + 0.1, -L / 2 + 0.15 + Float(i) * 0.3), mat: "metal.powdercoat:C9CCD0") }
        for i in 0...bays { box(V3(0.02, yb - ym - 0.1, 0.02), V3(W / 4 + 1.2, (yb + ym + 0.1) / 2, -L / 2 + Float(i) * bay), mat: "metal.galvanized") }
        pipe(V3(0.5, yb - 0.3, -L / 2), V3(0.5, yb - 0.3, L / 2), 0.1, mat: "rubber.tubing:1F4E8C")
        pipe(V3(0.8, yb - 0.3, -L / 2), V3(0.8, yb - 0.3, L / 2), 0.1, mat: "rubber.tubing:B51D17")
        pipe(V3(-0.4, yb - 0.25, -L / 2), V3(-0.4, yb - 0.25, L / 2), 0.055, sides: 10, mat: "metal.powdercoat:B5231A")
        for i in 0..<bays * 2 {
            let z = -L / 2 + (Float(i) + 0.5) * bay / 2
            pipe(V3(-0.4, yb - 0.25, z), V3(-0.4, yb - 0.45, z), 0.012, sides: 6, mat: "metal.brass")
            for x in [Float(0.5), 0.8] { box(V3(0.02, 0.03, 0.2), V3(x, yb - 0.3 + 0.12, z), mat: "metal.galvanized") }
        }
        for i in 0..<bays * 2 { box(V3(W / 2 - 1, 0.04, 0.12), V3(0, yb - 0.28, -L / 2 + (Float(i) + 0.5) * bay / 2 + 1), mat: "emissive.panel") }

        groundAO(&m, height: 0.4, floor: 0)
        return LODModel(m)
    }
}
