import simd
import Foundation

/// Navy grosgrain lanyard with printed dashes around a 38 cm neck, breakaway buckle at the left side, crimp, swivel
/// lobster hook and a CR80 photo ID card (54 x 85.6 mm) in a clear rigid holder with a slot, hanging on the sternum.
public struct LanyardIdBadge: RealAsset {
    public static let id = "lanyard-id-badge"
    public static let summary = "Worn lanyard with swivel hook and clear-holder photo ID badge on the sternum."
    public static let tags = ["prop", "wearable", "worn", "fabric", "metal", "plastic"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 14, elevation: 6, distance: 0.7, ground: false, studio: true)

    /// Lanyard ribbon colour.
    public var ribbon: MaterialKey = "fabric.grosgrain:1B2F5E"
    /// Clip hardware.
    public var hardware: MaterialKey = "metal.nickel-worn"
    /// Card header colour.
    public var header: MaterialKey = "plastic.matte:1E5AA8"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        typealias K = ChestKit
        let lw: Float = 0.0155, lt: Float = 0.0018
        let yBot: Float = -0.0165, yTop: Float = 0.232
        func zf(_ y: Float) -> Float { 0.12 - 0.075 * smoothstep(0.10, 0.24, y) }
        // Neck loop geometry (centre z -0.012, 58 x 62 mm radii).
        func ringPt(_ phi: Float, _ off: Float) -> V3 { V3(sin(phi) * (0.064 + off), yTop, -0.012 + cos(phi) * (0.058 + off)) }
        let phiJ: Float = 0.60
        func strand(_ side: Float, _ y: Float, _ off: Float) -> V3 {
            let u = (y - yBot) / (yTop - yBot)
            let xj = sin(phiJ) * 0.064
            let x = side * (0.004 + (xj - 0.004) * pow(u, 1.1))
            let zj = -0.012 + cos(phiJ) * 0.058
            let zc = zf(y) * sqrt(max(0.05, 1 - pow(x / 0.175, 2)))
            let zz = lerp(zc, zj, smoothstep(0.85, 1.0, u))
            return V3(x, y, zz + off)
        }
        var path: [V3] = []
        for k in 0...24 { path.append(strand(1, yBot + (yTop - yBot) * Float(k) / 24, lt / 2)) }
        for k in 1..<44 { path.append(ringPt(phiJ + (2 * Float.pi - 2 * phiJ) * Float(k) / 44, lt / 2)) }
        for k in stride(from: 24, through: 0, by: -1) { path.append(strand(-1, yBot + (yTop - yBot) * Float(k) / 24, lt / 2)) }
        let nf: (V3) -> V3 = { p in
            if p.y > yTop - 0.001 || p.z < 0 { return V3(p.x, 0, p.z + 0.012).normalized }
            return V3(0, 0.12, 1).normalized
        }
        var fr = K.frames(path, normal: nf)
        // Width runs across the strand on the chest and vertically around the neck.
        for i in fr.indices where fr[i].p.y < yTop - 0.002 && fr[i].p.z > 0.02 {
            let w = simd_normalize(V3(1, 0, 0) - fr[i].t * fr[i].t.x)
            fr[i].w = w; fr[i].n = simd_cross(fr[i].t, w)
        }
        m.add(K.ribbon(fr, width: lw, thick: lt, radius: 0.0007, segments: 2, caps: true, material: ribbon))
        // Printed dashes down the centre of both strands.
        let ink: MaterialKey = "fabric.canvas:ECECE6"
        for side: Float in [1, -1] {
            let ps = (2...22).map { strand(side, yBot + (yTop - yBot) * Float($0) / 24, lt + 0.0002) }
            m.add(K.stitch(along: ps, normal: { _ in V3(0, 0.15, 1).normalized }, pitch: 0.0085, thread: 0.0011, material: ink))
        }
        // Sewn edge stitching down both strands.
        for side: Float in [1, -1] { for e: Float in [-1, 1] {
            let ps = (1...23).map { k -> V3 in
                let y = yBot + (yTop - yBot) * Float(k) / 24
                return strand(side, y, lt + 0.0003) + V3(e * (lw / 2 - 0.0016), 0, 0)
            }
            m.add(K.stitch(along: ps, normal: { _ in V3(0, 0.15, 1).normalized }, pitch: 0.0042, thread: 0.00035, material: "fabric.canvas:C9C3B0"))
        }}
        // Enamel pin on the right strand.
        let pp = strand(-1, 0.115, lt + 0.0007)
        var star: [V2] = []
        for k in 0..<10 { let a = Float(k) / 10 * 2 * .pi + .pi / 2, r: Float = k % 2 == 0 ? 0.0062 : 0.0028; star.append(V2(cos(a), sin(a)) * r) }
        m.add(Prim.extrude(Shape2D.rounded(star, radius: 0.0006, segments: 1), depth: 0.0016, bevel: 0.0005, bevelSegments: 1, material: "metal.gold"), Xform(translation: pp + V3(0, 0, 0.0007)))
        m.add(Prim.extrude(Shape2D.rounded(star.map { $0 * 0.72 }, radius: 0.0004, segments: 1), depth: 0.0006, bevel: 0.0002, bevelSegments: 1, material: "plastic.sharps-red"), Xform(translation: pp + V3(0, 0, 0.0016)))
        // Breakaway buckle at the left back of the neck loop.
        let bPhi: Float = 2.15
        let bp = ringPt(bPhi, lt + 0.0035)
        let tan = V3(cos(bPhi) * 0.064, 0, -sin(bPhi) * 0.058).normalized
        let bq = K.basis(tan, V3(0, 1, 0))
        m.add(Prim.roundedBox(V3(0.026, 0.020, 0.0055), radius: 0.0018, bevelSegments: 1, material: "plastic.black"), Xform(translation: bp, rotation: bq))
        m.add(Prim.roundedBox(V3(0.012, 0.014, 0.0075), radius: 0.0016, bevelSegments: 1, material: "plastic.black"), Xform(translation: bp + bq.act(V3(0.0, 0, 0.0004)), rotation: bq))
        for k in 0..<4 { m.add(Prim.roundedBox(V3(0.0012, 0.015, 0.001), radius: 0.0004, bevelSegments: 1, material: "plastic.black"),
                               Xform(translation: bp + bq.act(V3(-0.006 + Float(k) * 0.004, 0, 0.0032)), rotation: bq)) }
        // Crimp sleeve where both strands meet, then swivel eye, barrel and lobster hook.
        let zc = zf(0) + 0.004
        m.add(Prim.roundedBox(V3(0.021, 0.013, 0.0042), radius: 0.0016, bevelSegments: 1, material: hardware), Xform(translation: V3(0, yBot + 0.001, zc + 0.002)))
        for k in -1...1 { m.add(Prim.roundedBox(V3(0.0012, 0.0128, 0.0008), radius: 0.0003, bevelSegments: 1, material: hardware), Xform(translation: V3(Float(k) * 0.0055, yBot + 0.001, zc + 0.0045))) }
        let hz = zc + 0.003
        m.add(Prim.torus(major: 0.0042, minor: 0.00085, segments: 32, sides: 10, material: hardware), Xform(translation: V3(0, yBot - 0.0095, hz), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        m.add(Prim.cylinder(radius: 0.0029, height: 0.0085, bevel: 0.0007, segments: 24, material: hardware), Xform(translation: V3(0, yBot - 0.0215, hz)))
        // Badge: hangs from the hook through the holder slot.
        let slotY: Float = 0.0415
        let hy = yBot - 0.0215 - 0.0065 - 0.0055
        let loopTop = hy + 0.020
        let hook = Shape2D.roundedRect(0.0115, 0.026, radius: 0.0045, segments: 6).map { V3($0.x, $0.y + (loopTop + hy) / 2 - 0.003, 0) }
        m.add(Prim.sweep(Shape2D.circle(0.00125, segments: 12), along: hook, up: V3(0, 0, 1), closedPath: true, caps: false, material: hardware), Xform(translation: V3(0, 0, hz)))
        m.add(Prim.tube([V3(0.0057, hy + 0.0, hz), V3(0.0057, hy + 0.007, hz)], radii: [0.0015, 0.0015], sides: 8, seamTile: 0.01, material: "metal.nickel"))
        let cy = hy - slotY + 0.0005
        var card = Model(name: "card")
        let hw: Float = 0.0615, hh: Float = 0.0985
        card.add(Prim.extrude(Shape2D.roundedRect(hw, hh, radius: 0.0045, segments: 6), depth: 0.0034, bevel: 0.0009, bevelSegments: 3, material: "plastic.clear"))
        // Moulded rim lip around the holder.
        let rim = Shape2D.roundedRect(hw - 0.0016, hh - 0.0016, radius: 0.0038, segments: 6).map { V3($0.x, $0.y, 0) }
        card.add(Prim.sweep(Shape2D.circle(0.0009, ry: 0.0017, segments: 8), along: rim, up: V3(0, 0, 1), closedPath: true, caps: false, material: "plastic.clear"))
        card.add(Prim.roundedBox(V3(0.016, 0.0034, 0.0038), radius: 0.0012, bevelSegments: 1, material: "plastic.black"), Xform(translation: V3(0, slotY, 0)))
        // CR80 card inside.
        let cz: Float = 0.0
        card.add(Prim.extrude(Shape2D.roundedRect(0.0540, 0.0856, radius: 0.0030, segments: 4), depth: 0.0008, bevel: 0.0002, bevelSegments: 1, material: "plastic.white"), Xform(translation: V3(0, -0.001, cz)))
        let fz: Float = cz + 0.0005
        card.add(Prim.extrude(Shape2D.rect(0.0536, 0.0165), depth: 0.0003, bevel: 0.0001, bevelSegments: 1, material: header), Xform(translation: V3(0, 0.0333, fz)))
        card.add(Prim.cylinder(radius: 0.0047, height: 0.0003, bevel: 0.0001, segments: 28, material: "plastic.white"), Xform(translation: V3(-0.0185, 0.0333, fz - 0.0001), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        for k in 0..<2 { card.add(Prim.extrude(Shape2D.rect(0.016 - Float(k) * 0.005, 0.0017), depth: 0.0003, bevel: 0.0001, bevelSegments: 1, material: "plastic.white"), Xform(translation: V3(0.010 + Float(k) * -0.0025, 0.0360 - Float(k) * 0.0055, fz))) }
        // Photo: backdrop, head and shoulders.
        card.add(Prim.extrude(Shape2D.rect(0.0215, 0.0265), depth: 0.0003, bevel: 0.0001, bevelSegments: 1, material: "plastic.matte:8FA4B8"), Xform(translation: V3(-0.0135, 0.0045, fz)))
        card.add(Prim.cubeSphere(subdivisions: 7, material: "plastic.matte:C69A7B") { d in V3(d.x * 0.0058, d.y * 0.0072, d.z * 0.0034) }, Xform(translation: V3(-0.0135, 0.0105, fz + 0.0016)))
        card.add(Prim.cubeSphere(subdivisions: 6, material: "plastic.matte:2B2522") { d in V3(d.x * 0.0063, d.y * 0.0052, d.z * 0.0026) * (d.y > 0 ? 1 : 0.2) }, Xform(translation: V3(-0.0135, 0.0127, fz + 0.0018)))
        card.add(Prim.cubeSphere(subdivisions: 7, material: "plastic.matte:3A4A66") { d in V3(d.x * 0.0098, max(d.y, -0.2) * 0.0075, d.z * 0.0028) }, Xform(translation: V3(-0.0135, -0.0045, fz + 0.0012)))
        // Name, title, id lines and barcode.
        let lines: [(Float, Float, Float)] = [(0.0125, 0.0100, 0.0022), (0.0128, 0.0070, 0.0016), (0.0095, 0.0044, 0.0015)]
        for (i, l) in lines.enumerated() {
            card.add(Prim.extrude(Shape2D.rect(l.1 * 1.7, l.2), depth: 0.0003, bevel: 0.0001, bevelSegments: 1, material: "plastic.matte:1A1C20"),
                     Xform(translation: V3(0.0105 + (l.1 * 1.7 - 0.0166) / 2 * 0, 0.0085 - Float(i) * 0.0058 + 0.0, fz)))
        }
        var bx: Float = -0.0215
        var rng = SeededRNG(seed: seed)
        while bx < 0.0215 {
            let bw: Float = rng.chance(0.4) ? 0.0016 : 0.0008
            card.add(Prim.extrude(Shape2D.rect(bw, 0.0092), depth: 0.0003, bevel: 0.0001, bevelSegments: 1, material: "plastic.matte:101114"), Xform(translation: V3(bx + bw / 2, -0.0305, fz)))
            bx += bw + 0.0010
        }
        // Wear: a faint scuff band across the holder front (dull plastic strip).
        card.add(Prim.extrude(Shape2D.rect(0.052, 0.0014), depth: 0.0002, bevel: 0.0001, bevelSegments: 1, material: "plastic.frosted"), Xform(translation: V3(0.0, -0.016, 0.00173), rotation: simd_quatf(degrees: 14, axis: V3(0, 0, 1))))
        m.add(card, Xform(translation: V3(0, cy, hz + 0.0012)))
        return LODModel(m)
    }
}
