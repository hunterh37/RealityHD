import simd
import Foundation

/// Kitchen island, 180 x 92 x 90 cm: 30 mm marble top overhanging 30 cm on +Z for stools, a navy painted
/// cabinet base on the work side (-Z) with a center bank of three drawers between two double-door units, a
/// beadboard back and walnut corbels on the seating side, finished end panels, toe kick and brass hardware.
public struct KitchenIsland: RealAsset {
    public static let id = "kitchen-island"
    public static let summary = "Kitchen island, 1.8 m: marble top with a 0.3 m seating overhang on +Z, navy shaker cabinets on the work side, beadboard back, corbels, brass pulls."
    public static let tags = ["prop", "floorplan", "kitchen", "furniture", "wood", "stone", "interior"]
    public static let budget = 11_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 18, distance: 2.6, studio: true)

    /// Overall size in meters (x width, y height, z depth); the seating overhang is on +Z.
    public var size = V3(1.8, 0.92, 0.9)
    /// Seating overhang depth beyond the cabinet back, in meters.
    public var overhang: Float = 0.30
    /// Painted cabinet color.
    public var paintMaterial: MaterialKey = "wood.painted-shaker:2F4358"
    /// Slightly worn paint on the toe kick and door edges.
    public var wornPaintMaterial: MaterialKey = "wood.painted-shaker-worn:2F4358"
    /// Countertop stone.
    public var stoneMaterial: MaterialKey = "stone.marble"
    /// Corbel wood.
    public var corbelMaterial: MaterialKey = "wood.walnut:5E3F2B"
    /// Back panel (inside the cabinets).
    public var backMaterial: MaterialKey = "wood.plywood:8A6C48"
    /// Knob and pull metal.
    public var metalMaterial: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [6])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y, D = size.z
        let paint = paintMaterial
        func box(_ s: V3, _ p: V3, _ mat: MaterialKey, r: Float = 0.0015, hard: Bool = false) {
            let surf = hard ? cuboid(s, material: mat) : Prim.roundedBox(s, radius: r, bevelSegments: 1, material: mat)
            m.add(surf, Xform(translation: p).jittered(&rng, deg: 0.03, offset: 0.0001))
        }
        let topT: Float = 0.03
        let zCabF: Float = -D / 2 + 0.03              // work-side face of doors and drawers
        let zCabB: Float = D / 2 - overhang           // seating-side back face of the cabinet
        let toe: Float = 0.1
        let baseTop = H - topT
        let bodyD = zCabB - (zCabF + 0.02)
        let bodyZ = (zCabB + zCabF + 0.02) / 2
        let panel: Float = 0.02

        // Countertop.
        m.add(Prim.extrude(Shape2D.roundedRect(W, D, radius: 0.012, segments: detail ? 4 : 2), depth: topT, bevel: 0.005, bevelSegments: detail ? 3 : 1, material: stoneMaterial),
              Xform(translation: V3(0, H - topT / 2, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))

        // Carcass.
        let inY0 = toe + panel, inY1 = baseTop, inH = inY1 - inY0, cyMid = (inY0 + inY1) / 2
        box(V3(W - 0.07, toe, bodyD - 0.06), V3(0, toe / 2, bodyZ - 0.0), wornPaintMaterial, hard: true)         // toe kick, set back 60 mm
        box(V3(W - 0.02, panel, bodyD), V3(0, toe + panel / 2, bodyZ), paint, hard: true)
        for s: Float in [-1, 1] { box(V3(panel, inH, bodyD), V3(s * (W / 2 - panel / 2 - 0.01), cyMid, bodyZ), paint, hard: true) }
        let divX: Float = 0.30
        for s: Float in [-1, 1] { box(V3(panel, inH, bodyD), V3(s * divX, cyMid, bodyZ), paint, hard: true) }
        box(V3(W - 0.06, inH, 0.006), V3(0, cyMid, zCabB - 0.003), backMaterial, hard: true)

        // Shaker fronts facing -Z: the face sits at zCabF, the frame runs 20 mm back into the case.
        func shaker(cx: Float, cy: Float, w: Float, h: Float, stile: Float, rail: Float) {
            let dd: Float = 0.02
            let zc = zCabF + dd / 2
            box(V3(stile, h, dd), V3(cx - w / 2 + stile / 2, cy, zc), paint)
            box(V3(stile, h, dd), V3(cx + w / 2 - stile / 2, cy, zc), paint)
            box(V3(w - 2 * stile + 0.004, rail, dd), V3(cx, cy + h / 2 - rail / 2, zc), paint)
            box(V3(w - 2 * stile + 0.004, rail, dd), V3(cx, cy - h / 2 + rail / 2, zc), paint)
            box(V3(w - 2 * stile + 0.004, h - 2 * rail + 0.004, 0.006), V3(cx, cy, zCabF + dd - 0.004), paint, r: 0.0008)
            if detail {
                let iw = w - 2 * stile, ih = h - 2 * rail
                for (bw, bh, dx, dy) in [(iw, Float(0.005), Float(0), ih / 2 - 0.0025), (iw, 0.005, 0, -ih / 2 + 0.0025), (0.005, ih - 0.01, iw / 2 - 0.0025, 0), (0.005, ih - 0.01, -iw / 2 + 0.0025, 0)] {
                    box(V3(bw, bh, 0.0025), V3(cx + dx, cy + dy, zCabF + dd - 0.0085), paint, hard: true)
                }
            }
        }
        let knob: [V2] = [V2(0.0001, 0), V2(0.009, 0), V2(0.009, 0.0012), V2(0.003, 0.002), V2(0.003, 0.007), V2(0.0075, 0.0085),
                          V2(0.0115, 0.0125), V2(0.0125, 0.017), V2(0.0105, 0.021), V2(0.006, 0.0235), V2(0.0001, 0.024)]
        // Doors: two double-door units flanking the drawers.
        let doorH = inH - 0.004
        let sideEdge = W / 2 - panel - 0.012, divEdge = divX + panel / 2
        let unitW = sideEdge - divEdge
        let doorW = (unitW - 0.009) / 2
        for s: Float in [-1, 1] {
            let ucx = s * (sideEdge + divEdge) / 2
            for k: Float in [-1, 1] {
                let cx = ucx + k * (doorW / 2 + 0.0015)
                shaker(cx: cx, cy: cyMid, w: doorW, h: doorH, stile: 0.065, rail: 0.07)
                let kx = cx - k * (doorW / 2 - 0.032)
                m.add(Prim.lathe(knob, segments: detail ? 20 : 10, seamTile: 0.1, material: metalMaterial),
                      Xform(translation: V3(kx, cyMid + doorH / 2 - 0.12, zCabF), rotation: facing(V3(0, 0, -1))))
            }
        }
        // Drawers: three across the center unit, 40 mm pulls.
        let drW = 2 * divX - panel - 0.006
        let n = 3, gap: Float = 0.003
        let drH = (inH - 0.004 - Float(n - 1) * gap) / Float(n)
        for i in 0..<n {
            let cy = inY0 + 0.002 + drH / 2 + Float(i) * (drH + gap)
            shaker(cx: 0, cy: cy, w: drW, h: drH, stile: 0.055, rail: 0.045)
            var pull = barHandle(length: 0.16, standoff: 0.022, radius: 0.0048, overhang: 0.008, material: metalMaterial)
            if !detail { pull = Prim.cylinder(radius: 0.005, height: 0.176, bevel: 0.003, segments: 8, bevelSegments: 1, material: metalMaterial) }
            m.add(pull, Xform(translation: V3(0, cy, zCabF), rotation: simd_quatf(degrees: 180, axis: .up)))
        }

        // Seating side: beadboard back panel with V-grooves every 70 mm, over the cabinet back.
        let bbZ = zCabB + 0.0075
        box(V3(W - 0.02, baseTop - toe, 0.015), V3(0, (baseTop + toe) / 2, bbZ), paint, hard: true)
        box(V3(W - 0.02, 0.14, 0.021), V3(0, baseTop - 0.07, bbZ + 0.003), paint, r: 0.0015)       // top rail
        box(V3(W - 0.02, toe, 0.021), V3(0, toe / 2 + 0.0, bbZ + 0.003), wornPaintMaterial, r: 0.0015)   // skirt over the toe kick
        if detail {
            var grooves = Surface(material: "plastic.black")
            let g = cuboid(V3(0.0025, baseTop - toe - 0.16, 0.0008), material: "plastic.black")
            let cnt = Int((W - 0.12) / 0.07)
            for k in 0..<cnt {
                let x = -(Float(cnt - 1) * 0.07) / 2 + Float(k) * 0.07
                grooves.append(g, Xform(translation: V3(x, toe + 0.0 + (baseTop - toe - 0.14) / 2 - 0.0, bbZ + 0.0079 + 0.0)))
            }
            m.add(grooves)
        }
        // Corbels under the overhang: 5 at 0.15, +/-0.7 and 0, extruded L-brackets with a concave sweep.
        let cx0: [Float] = [-0.7, 0, 0.7]
        let outline: [V2] = {
            // (u, v) = (-z offset from cabinet back, y); concave arc from the wall face down to the nose.
            var pts: [V2] = [V2(-0.02, baseTop - 0.001), V2(-0.27, baseTop - 0.001), V2(-0.27, baseTop - 0.06)]
            for k in 1...8 {
                let a = Float(k) / 9 * (.pi / 2)
                pts.append(V2(-0.27 + 0.21 * (1 - cos(a)) * 1.0 - 0.0, baseTop - 0.06 - 0.17 * sin(a)))
            }
            pts.append(V2(-0.02, baseTop - 0.25))
            return Shape2D.deduped(pts)
        }()
        for x in cx0 {
            m.add(Prim.extrude(outline, depth: 0.045, bevel: 0.003, bevelSegments: 1, material: corbelMaterial),
                  Xform(translation: V3(x, 0, zCabB + 0.0), rotation: simd_quatf(degrees: 90, axis: .up)))
        }

        // End panels: applied frame molding on both ends (shaker style), finished side faces.
        for s: Float in [-1, 1] {
            let ex = s * (W / 2 - 0.0075)
            let endD = zCabB - zCabF + 0.021 - 0.01, endZ = (zCabB + 0.021 + zCabF) / 2
            if detail {
                for (bw, bh, dz, dy) in [(Float(0.04), baseTop - toe - 0.08, endD / 2 - 0.03, Float(0)), (0.04, baseTop - toe - 0.08, -endD / 2 + 0.03, 0),
                                         (Float(0.04), Float(0.04), 0, (baseTop - toe) / 2 - 0.04), (0.04, 0.04, 0, -(baseTop - toe) / 2 + 0.04)] {
                    if dy == 0 {
                        box(V3(0.005, bh, bw), V3(ex, (baseTop + toe) / 2 + dy, endZ + dz), paint, hard: true)
                    } else {
                        box(V3(0.005, 0.04, endD - 0.08 + 0.04), V3(ex, (baseTop + toe) / 2 + dy, endZ), paint, hard: true)
                    }
                }
            }
        }

        groundAO(&m, height: 0.18, floor: 0.55)
        return m
    }
}
