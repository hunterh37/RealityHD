import simd
import Foundation

/// Straight stair flight for the floor planning pack. Local frame: origin at the foot-front center
/// (y = 0 floor, x = flight center), the flight climbs along -Z. Treads, risers, a closed skirt stringer on a
/// wall side or a cut stringer with newels, balusters and handrail on an open side.
struct StairFlight {
    var width: Float = 1.0
    var risers = 16
    var rise: Float = 0.1875
    var going: Float = 0.26
    var nose: Float = 0.025
    var treadT: Float = 0.035
    var riserT: Float = 0.018
    /// Open side(s): cut stringer, rail, newels. The other side is a closed skirt against a wall.
    var leftOpen = false
    var rightOpen = true
    /// Landing plate beyond the last riser (m); 0 omits it.
    var stub: Float = 0.075
    var newelStart = true
    var newelEnd = true
    /// Newel and rail anchors along the run (m); nil keeps the defaults at the flight ends.
    var startU: Float? = nil
    var endU: Float? = nil
    /// Rail start when there is no start newel (a post built by the neighboring flight).
    var railStartU: Float? = nil
    /// Base height of the end newel (default: top landing) and an override for its top.
    var endBaseY: Float? = nil
    var endPostTopY: Float? = nil
    /// The first tread and riser stop at the start newel.
    var shortenFirst = true
    /// Rail height above the nosing line (m).
    var railHeight: Float = 0.9
    var lod = 0
    /// Nosing roundover segments on LOD 0.
    var treadSeg = 2
    var treadMats: [MaterialKey] = ["wood.oak:BE9A68", "wood.oak:A98458", "wood.oak:C9A674", "wood.oak:B08C5E"]
    var riserMat: MaterialKey = "wood.painted-shaker-worn:E6E1D3"
    var stringerMat: MaterialKey = "wood.painted-shaker-worn:E4DFD2"
    var carriageMat: MaterialKey = "wood.lumber-pine"
    var balusterMat: MaterialKey = "wood.painted-shaker:EAE6DA"
    var railMat: MaterialKey = "wood.oak:9A6E40"
    let newelWidth: Float = 0.09

    var slope: Float { rise / going }
    /// Run length of the flight including the landing plate.
    var length: Float { Float(risers - 1) * going + nose + (stub > 0 ? stub : riserT + 0.012) }
    var topY: Float { Float(risers) * rise }
    /// Rail top surface height at run position `u`.
    func railTop(_ u: Float) -> Float { slope * u + rise + railHeight }

    private func extruded(_ pts: [V2], x0: Float, x1: Float, mat: MaterialKey, bevel: Float = 0.002) -> (Surface, Xform) {
        (Prim.extrude(pts, depth: x1 - x0, bevel: bevel, bevelSegments: 1, material: mat),
         Xform(translation: V3((x0 + x1) / 2, 0, 0), rotation: simd_quatf(degrees: 90, axis: .up)))
    }

    private func cutStringer() -> [V2] {
        let a1 = nose + riserT
        let y1 = rise - treadT
        var pts: [V2] = [V2(a1, 0)]
        for i in 1...risers {
            let ai = Float(i - 1) * going + nose + riserT
            let yi = Float(i) * rise - treadT
            pts.append(V2(ai, yi))
            pts.append(V2(i == risers ? length : Float(i) * going + nose + riserT, yi))
        }
        let lowY: (Float) -> Float = { self.slope * ($0 - a1) + y1 - 0.17 }
        pts.append(V2(length, lowY(length)))
        pts.append(V2(a1 + (0.17 - y1) / slope, 0))
        return pts
    }

    private func skirtStringer() -> [V2] {
        let a1 = nose + riserT
        let y1 = rise - treadT
        let top0 = rise + 0.09
        let uc = (topY - top0) / slope
        let lowY: (Float) -> Float = { self.slope * ($0 - a1) + y1 - 0.25 }
        return [V2(0, 0), V2(0, top0), V2(uc, topY), V2(length, topY), V2(length, lowY(length)), V2(a1 + (0.25 - y1) / slope, 0)]
    }

    func build(seed: UInt64) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: "stair")
        let W = width, hw = W / 2
        let seg = lod == 0 ? treadSeg : 1
        func box(_ size: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.002, seg sg: Int? = nil) {
            m.add(Prim.roundedBox(size, radius: min(r, min(size.x, size.y, size.z) * 0.45), bevelSegments: sg ?? 1, material: mat), Xform(translation: c))
        }
        // World helpers: run position u maps to z = -u.
        func P(_ x: Float, _ y: Float, _ u: Float) -> V3 { V3(x, y, -u) }

        let sides: [(s: Float, open: Bool)] = [(-1, leftOpen), (1, rightOpen)]
        // Stringers.
        var xInner: [Float] = [0, 0]      // inside face per side (-X side, +X side) as signed x
        for (k, sd) in sides.enumerated() {
            let s = sd.s
            if sd.open {
                let xo = s * (hw - 0.04), xi = s * (hw - 0.08)
                let e = extruded(cutStringer(), x0: min(xo, xi), x1: max(xo, xi), mat: stringerMat)
                m.add(e.0, e.1)
                xInner[k] = xi
            } else {
                let xo = s * hw, xi = s * (hw - 0.035)
                let e = extruded(skirtStringer(), x0: min(xo, xi), x1: max(xo, xi), mat: stringerMat)
                m.add(e.0, e.1)
                xInner[k] = xi
            }
        }
        // Cap molding along the top edge of each closed skirt.
        for sd in sides where !sd.open && lod == 0 {
            let xc = sd.s * (hw - 0.035 - 0.006)
            let uc = (topY - (rise + 0.09)) / slope
            let b = board(from: P(xc, rise + 0.09 + 0.004, 0), to: P(xc, topY + 0.004, uc), width: 0.014, thick: 0.014, up: V3(sd.s, 0, 0), bevel: 0.004, material: stringerMat)
            m.add(b.0, b.1)
        }
        // Center carriage under the treads (visible from the back and below).
        if lod == 0 {
            let e = extruded(cutStringer(), x0: -0.02, x1: 0.02, mat: carriageMat, bevel: 0.001)
            m.add(e.0, e.1)
        }
        let xl = xInner[0], xr = xInner[1]
        let nw = newelWidth
        // Treads, risers, nosing scotia.
        for i in 1...risers {
            let u0 = Float(i - 1) * going
            if i < risers {
                var tl = leftOpen ? -hw + 0.01 : xl, tr = rightOpen ? hw - 0.01 : xr
                var rl = xl, rr = xr
                if i == 1 && newelStart && shortenFirst {
                    if rightOpen { tr = hw - nw - 0.012; rr = hw - nw - 0.012 }
                    if leftOpen { tl = -hw + nw + 0.012; rl = -hw + nw + 0.012 }
                }
                let tm = treadMats[(i * 7) % treadMats.count]
                let jit = rng.float(-0.0006...0.0006)
                box(V3(tr - tl, treadT, going + nose), P((tl + tr) / 2, Float(i) * rise - treadT / 2 + jit, u0 + (going + nose) / 2), tm, r: 0.009, seg: seg)
                if lod == 0 {
                    m.add(cuboid(V3(tr - tl - 0.01, 0.014, 0.014), material: tm), Xform(translation: P((tl + tr) / 2, Float(i) * rise - treadT - 0.006, u0 + nose - 0.002)))
                }
                m.add(cuboid(V3(rr - rl, rise - treadT, riserT), material: riserMat), Xform(translation: P((rl + rr) / 2, (Float(i - 1) * rise + Float(i) * rise - treadT) / 2, u0 + nose + riserT / 2)))
            } else {
                // Riser under the landing plate.
                m.add(cuboid(V3(xr - xl, rise - treadT, riserT), material: riserMat), Xform(translation: P((xl + xr) / 2, (Float(i - 1) * rise + Float(i) * rise - treadT) / 2, u0 + nose + riserT / 2)))
            }
        }
        if stub > 0 {
            let tl = leftOpen ? -hw + 0.01 : xl, tr = rightOpen ? hw - 0.01 : xr
            let u0 = Float(risers - 1) * going + nose
            box(V3(tr - tl, treadT, length - u0 + 0.01), P((tl + tr) / 2, topY - treadT / 2, (u0 - 0.01 + length) / 2), treadMats[0], r: 0.005, seg: 1)
        }

        // Rails, balusters and newels per open side.
        for sd in sides where sd.open {
            let x = sd.s * (hw - 0.057)
            let pu = nw / 2 + 0.012
            let uA = railStartU ?? (newelStart ? (startU ?? pu) : 0.0), uB = newelEnd ? (endU ?? length - pu) : Float(risers - 1) * going + nose
            let railR = Float(0.0225)
            let a = P(x, railTop(uA) - railR, uA), b = P(x, railTop(uB) - railR, uB)
            // Molded rail: flat underside, rounded top and shoulders. Profile x is vertical (follows `up`), y horizontal.
            let hv: [(Float, Float)] = [(-0.017, -0.0225), (0.017, -0.0225), (0.026, -0.012), (0.028, 0.004), (0.019, 0.0225), (-0.019, 0.0225), (-0.028, 0.004), (-0.026, -0.012)]
            let rprof = Shape2D.rounded(hv.map { V2($0.1, $0.0) }, radius: 0.007, segments: lod == 0 ? 2 : 1)
            let dir = simd_normalize(b - a)
            let ext = dir * (nw / 2)
            let n = lod == 0 ? 8 : 2
            let path = (0...n).map { a - ext + (b - a + 2 * ext) * (Float($0) / Float(n)) }
            m.add(Prim.sweep(rprof, along: path, up: .up, grainAlongPath: true, material: railMat))
            // Balusters: two per tread, standing on the tread over the stringer edge.
            let proto: [V2] = [V2(0, 0), V2(0.017, 0), V2(0.017, 0.07), V2(0.012, 0.11), V2(0.0105, 0.5), V2(0.019, 0.62),
                               V2(0.0105, 0.73), V2(0.017, 0.77), V2(0.017, 0.84), V2(0, 0.84)]
            let lowPoly: [V2] = [V2(0, 0), V2(0.016, 0), V2(0.016, 0.07), V2(0.011, 0.16), V2(0.011, 0.6), V2(0.017, 0.7), V2(0.017, 0.84), V2(0, 0.84)]
            let prof = lod == 0 ? proto : lowPoly
            let bal = Prim.lathe(prof, segments: lod == 0 ? 8 : 5, seamTile: 0.05, material: balusterMat)
            for i in ((newelStart && shortenFirst) ? 2 : 1)..<risers {
                for d: Float in [0.07, 0.07 + going / 2] {
                    let u = Float(i - 1) * going + d
                    if u < uA + nw / 2 + 0.03 || u > uB - nw / 2 - 0.03 { continue }
                    let y0 = Float(i) * rise - 0.004
                    let h = railTop(u) - 0.045 - y0 + 0.01
                    m.add(bal, Xform(translation: P(x, y0, u), scale: V3(1, h / 0.84, 1)))
                }
            }
            // Newel posts with caps and ball finials.
            func newel(_ u: Float, _ y0: Float, top topOverride: Float? = nil, foot: Bool = false) {
                let top = topOverride ?? (railTop(u) + 0.06)
                box(V3(nw, top - y0, nw), P(x, (y0 + top) / 2, u), railMat, r: 0.006)
                box(V3(nw + 0.024, 0.028, nw + 0.024), P(x, top + 0.006, u), railMat, r: 0.007)
                let ball = Prim.lathe([V2(0, 0), V2(0.03, 0.004), V2(0.038, 0.03), V2(0.03, 0.058), V2(0.01, 0.07), V2(0, 0.072)], segments: lod == 0 ? 16 : 8, seamTile: 0.1, material: railMat)
                m.add(ball, Xform(translation: P(x, top + 0.02, u)))
                if lod == 0 {
                    box(V3(nw + 0.014, 0.05, nw + 0.014), P(x, y0 + 0.28, u), railMat, r: 0.004)
                    if foot { box(V3(nw + 0.02, 0.12, nw + 0.02), P(x, y0 + 0.06, u), railMat, r: 0.005) }
                }
            }
            if newelStart { newel(startU ?? pu, 0) }
            if newelEnd { newel(endU ?? length - pu, endBaseY ?? topY - 0.01, top: endPostTopY, foot: endBaseY != nil && endBaseY! < 0.02) }
        }
        groundAO(&m, height: 0.25, floor: 0.7)
        return m
    }
}

/// Landing platform for turning stairs: oak boards on rim beams, painted fascia on open edges, baseboard on walls.
/// World coordinates: x from `x0` to `x1`, z from `zFront` (nosing edge) back to `zBack` (smaller z), top at `topY`.
struct StairLanding {
    var x0: Float, x1: Float, zFront: Float, zBack: Float, topY: Float
    var wallLeft = true, wallRight = false, wallBack = true
    /// Fascia boards on open edges: front only where `frontFasciaX` spans, right edge when `fasciaRight`.
    var frontFasciaX: ClosedRange<Float>? = nil
    var fasciaRight = false
    var boardMats: [MaterialKey] = ["wood.oak:BE9A68", "wood.oak:A98458", "wood.oak:C9A674", "wood.oak:B08C5E"]
    var paint: MaterialKey = "wood.painted-shaker:EAE6DA"
    var paintWorn: MaterialKey = "wood.painted-shaker-worn:E4DFD2"
    var lod = 0
    let thick: Float = 0.035

    func build() -> Model {
        var m = Model(name: "landing")
        func box(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.003) {
            m.add(Prim.roundedBox(s, radius: min(r, min(s.x, s.y, s.z) * 0.45), bevelSegments: 1, material: mat), Xform(translation: c))
        }
        let w = x1 - x0, d = zFront - zBack, cx = (x0 + x1) / 2
        let nb = max(2, Int((d / 0.2).rounded()))
        let bd = d / Float(nb)
        for i in 0..<nb {
            let zc = zFront - bd * (Float(i) + 0.5)
            box(V3(w, thick, bd - 0.002), V3(cx, topY - thick / 2, zc), boardMats[(i * 3 + 1) % boardMats.count], r: 0.004)
        }
        // Rim beams and joists under the platform.
        let bh: Float = 0.16
        let by = topY - thick - bh / 2
        for (zc, hd) in [(zBack + 0.02, Float(0.04)), (zFront - 0.06, Float(0.04)), ((zFront + zBack) / 2, Float(0.04))] {
            m.add(cuboid(V3(w - 0.01, bh, hd), material: "wood.lumber-pine"), Xform(translation: V3(cx, by, zc)))
        }
        if let fx = frontFasciaX {
            box(V3(fx.upperBound - fx.lowerBound, bh + thick, 0.02), V3((fx.lowerBound + fx.upperBound) / 2, topY - (bh + thick) / 2, zFront - 0.012), paintWorn, r: 0.002)
        }
        if fasciaRight {
            box(V3(0.02, bh + thick, d), V3(x1 - 0.012, topY - (bh + thick) / 2, (zFront + zBack) / 2), paintWorn, r: 0.002)
        }
        if lod == 0 {
            // Baseboard against the walls.
            if wallLeft { box(V3(0.012, 0.09, d), V3(x0 + 0.006, topY + 0.045, (zFront + zBack) / 2), paint, r: 0.003) }
            if wallRight { box(V3(0.012, 0.09, d), V3(x1 - 0.006, topY + 0.045, (zFront + zBack) / 2), paint, r: 0.003) }
            if wallBack { box(V3(w, 0.09, 0.012), V3(cx, topY + 0.045, zBack + 0.006), paint, r: 0.003) }
        }
        return m
    }
}
