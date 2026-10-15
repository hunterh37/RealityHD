import simd
import Foundation

/// Painted shaker sideboard, 160 x 85 x 45 cm: 30 mm walnut-veneered top, painted carcass on four tapered
/// legs, two framed doors with recessed panels and brass knobs, a center bank of three shaker drawers with
/// brass bar pulls. Doors and drawers are closed.
public struct Sideboard: RealAsset {
    public static let id = "sideboard"
    public static let summary = "Painted shaker sideboard with a walnut top, two doors, three center drawers, brass pulls and short tapered legs."
    public static let tags = ["prop", "floorplan", "dining", "furniture", "wood", "interior"]
    public static let budget = 10_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 16, distance: 2.1, studio: true)

    /// Overall size in meters (x width, y height, z depth); the fronts face +Z.
    public var size = V3(1.6, 0.85, 0.45)
    /// Leg height under the case.
    public var legHeight: Float = 0.12
    /// Top veneer.
    public var topMaterial: MaterialKey = "wood.veneer-walnut:6A4630"
    /// Painted case and fronts (sage).
    public var paintMaterial: MaterialKey = "wood.painted-shaker:86978B"
    /// Slightly worn paint on the leading edges and legs.
    public var wornPaintMaterial: MaterialKey = "wood.painted-shaker-worn:86978B"
    /// Back panel.
    public var backMaterial: MaterialKey = "wood.plywood:8A6C48"
    /// Knob and pull metal.
    public var metalMaterial: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [5])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y, D = size.z - 0.0365, L = legHeight      // hardware stands 26.5 mm proud of the fronts
        let paint = paintMaterial
        func box(_ s: V3, _ p: V3, _ mat: MaterialKey, r: Float = 0.0015) {
            m.add(Prim.roundedBox(s, radius: r, bevelSegments: 1, material: mat), Xform(translation: p).jittered(&rng, deg: 0.03, offset: 0.0001))
        }
        let topT: Float = 0.03, panel: Float = 0.02
        let zFront = D / 2, bodyD = D - 0.025, bodyZ: Float = -0.0125

        m.add(Prim.extrude(Shape2D.roundedRect(W, D + 0.02, radius: 0.012, segments: detail ? 4 : 2), depth: topT, bevel: 0.0035, bevelSegments: detail ? 3 : 1, material: topMaterial),
              Xform(translation: V3(0, H - topT / 2, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        let inY0 = L + panel, inY1 = H - topT, inH = inY1 - inY0, cyMid = (inY0 + inY1) / 2
        box(V3(W - 0.004, panel, bodyD), V3(0, L + panel / 2, bodyZ), paint)
        for s: Float in [-1, 1] { box(V3(panel, inH, bodyD), V3(s * (W / 2 - panel / 2 - 0.002), cyMid, bodyZ), paint) }
        let divX: Float = 0.29
        for s: Float in [-1, 1] { box(V3(panel, inH, bodyD), V3(s * divX, cyMid, bodyZ), paint) }
        // Back panel and a dark cavity behind each opening.
        box(V3(W - 0.044, inH, 0.006), V3(0, cyMid, -D / 2 + 0.014), backMaterial, r: 0.0005)

        // Shaker front: stile/rail frame with a recessed flat panel and a cove bead around it.
        func shaker(cx: Float, cy: Float, w: Float, h: Float, stile: Float, rail: Float, mat: MaterialKey) {
            let dd: Float = 0.02
            let zc = zFront - dd / 2
            box(V3(stile, h, dd), V3(cx - w / 2 + stile / 2, cy, zc), mat)
            box(V3(stile, h, dd), V3(cx + w / 2 - stile / 2, cy, zc), mat)
            box(V3(w - 2 * stile + 0.004, rail, dd), V3(cx, cy + h / 2 - rail / 2, zc), mat)
            box(V3(w - 2 * stile + 0.004, rail, dd), V3(cx, cy - h / 2 + rail / 2, zc), mat)
            let iw = w - 2 * stile, ih = h - 2 * rail
            box(V3(iw + 0.004, ih + 0.004, 0.006), V3(cx, cy, zFront - dd + 0.004), mat, r: 0.0008)
            if detail {
                for (bw, bh, dx, dy) in [(iw, Float(0.005), Float(0), ih / 2 - 0.0025), (iw, 0.005, 0, -ih / 2 + 0.0025), (0.005, ih - 0.01, iw / 2 - 0.0025, 0), (0.005, ih - 0.01, -iw / 2 + 0.0025, 0)] {
                    box(V3(bw, bh, 0.0025), V3(cx + dx, cy + dy, zFront - dd + 0.0075 + 0.0012), mat, r: 0.0008)
                }
            }
        }

        // Doors.
        let sideEdge = W / 2 - panel - 0.002, divEdge = divX + panel / 2
        let doorW = sideEdge - divEdge - 0.003, doorH = inH - 0.004
        let doorCx = (sideEdge + divEdge) / 2
        for s: Float in [-1, 1] {
            let cx = s * doorCx
            shaker(cx: cx, cy: cyMid, w: doorW, h: doorH, stile: 0.07, rail: 0.075, mat: paint)
            let kx = cx - s * (doorW / 2 - 0.035)
            let knob: [V2] = [V2(0.0001, 0), V2(0.009, 0), V2(0.009, 0.0012), V2(0.003, 0.002), V2(0.003, 0.007), V2(0.0075, 0.0085),
                              V2(0.0115, 0.0125), V2(0.0125, 0.017), V2(0.0105, 0.021), V2(0.006, 0.0235), V2(0.0001, 0.024)]
            m.add(Prim.lathe(knob, segments: detail ? 20 : 10, seamTile: 0.1, material: metalMaterial),
                  Xform(translation: V3(kx, cyMid, zFront), rotation: facing(V3(0, 0, 1))))
        }
        // Three center drawers.
        let drW = 2 * divX - panel - 0.006
        let n = 3, gap: Float = 0.003
        let drH = (inH - 0.004 - Float(n - 1) * gap) / Float(n)
        for i in 0..<n {
            let cy = inY0 + 0.002 + drH / 2 + Float(i) * (drH + gap)
            shaker(cx: 0, cy: cy, w: drW, h: drH, stile: 0.055, rail: 0.045, mat: paint)
            var pull = barHandle(length: 0.1, standoff: 0.022, radius: 0.0045, overhang: 0.008, material: metalMaterial)
            if !detail { pull = Prim.cylinder(radius: 0.005, height: 0.116, bevel: 0.003, segments: 8, bevelSegments: 1, material: metalMaterial) }
            m.add(pull, Xform(translation: V3(0, cy, zFront)))
        }

        // Legs: four tapered square legs 55 -> 35 mm, set under the carcass corners, worn paint, brass toe caps.
        let lx = W / 2 - 0.05, lz = D / 2 - 0.05
        for sx: Float in [-1, 1] {
            for sz: Float in [-1, 1] {
                let top = Shape2D.roundedRect(0.055, 0.055, radius: 0.003, segments: 1)
                let bot = Shape2D.roundedRect(0.035, 0.035, radius: 0.003, segments: 1)
                let r0 = Prim.ring(bot, y: 0.012, offset: V3(sx * lx, 0, sz * lz))
                let r1 = Prim.ring(top, y: L + 0.004, offset: V3(sx * lx, 0, sz * lz))
                var leg = Prim.loft([r0, r1], capStart: true, capEnd: true, material: wornPaintMaterial).flipped()
                leg.uvs = leg.uvs.map { V2($0.y, $0.x) }; leg.computeTangents()
                m.add(leg)
                m.add(Prim.cylinder(radius: 0.0215, height: 0.014, bevel: 0.0025, segments: 12, bevelSegments: 1, material: metalMaterial),
                      Xform(translation: V3(sx * lx, 0, sz * lz)))
            }
        }
        // Plinth rail between the front legs and a kick board at the back.
        box(V3(W - 0.18, 0.035, 0.018), V3(0, L - 0.0175, zFront - 0.05 + 0.0), wornPaintMaterial, r: 0.0015)

        // Overall depth includes the hardware and the top overhang; center it on z.
        for i in m.surfaces.indices { m.surfaces[i].positions = m.surfaces[i].positions.map { $0 - V3(0, 0, 0.00825) } }
        groundAO(&m, height: 0.16, floor: 0.55)
        return m
    }
}
