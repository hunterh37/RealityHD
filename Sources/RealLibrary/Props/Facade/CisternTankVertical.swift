import simd
import Foundation

/// Cistern tank, vertical: 1.8 m diameter bolted corrugated galvanised steel water tank, 2.4 m to the roof apex,
/// 100 mm corrugation pitch, twelve sheets with bolted vertical laps, rolled eave, radial roof ribs, 500 mm
/// manway hatch, mesh vent, 110 mm inlet and overflow with flap, external sight gauge on clamps with a
/// graduated plate, gate valve with red handwheel on a 63 mm outlet, on a concrete ring plinth with angle anchors.
public struct CisternTankVertical: RealAsset {
    public static let id = "cistern-tank-vertical"
    public static let summary = "Bolted corrugated galvanised cistern: 12 lapped sheets, ribbed roof, hatch, vent, sight gauge, gate valve, concrete plinth."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 12, distance: 4.2)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(1.8, 2.4, 1.8)
    public var shell: MaterialKey = "metal.galvanized-aged"
    public var fresh: MaterialKey = "metal.galvanized"
    public var concrete: MaterialKey = "concrete.rough"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let R: Float = 0.9, y0: Float = 0.1, y1: Float = 2.2, pitch: Float = 0.1, amp: Float = 0.0095
        func P(_ aDeg: Float, _ r: Float, _ y: Float) -> V3 { V3(r * cos(aDeg * .pi / 180), y, r * sin(aDeg * .pi / 180)) }
        /// Cheap flat plate: outline w x h, thickness d, facing outward at angle a, centre c.
        func plate(_ w: Float, _ h: Float, _ d: Float, _ c: V3, yaw: Float, _ mat: MaterialKey) {
            m.add(Prim.extrude(Shape2D.rect(w, h), depth: d, bevel: min(0.001, d * 0.3), bevelSegments: 1, material: mat), Xform(translation: c, rotation: FA.q(yaw, FA.Y)))
        }
        func outward(_ aDeg: Float) -> V3 { V3(cos(aDeg * .pi / 180), 0, sin(aDeg * .pi / 180)) }
        // Plinth: concrete ring slab 100 mm with a 6 mm chamfer, 12 angle anchors with bolts.
        m.add(Prim.lathe([V2(0, 0), V2(0.97, 0), V2(0.97, 0.094), V2(0.964, 0.1), V2(0, 0.1)], segments: 36, seamTile: 0.5, material: concrete))
        for k in 0..<12 {
            let a = Float(k) * 30 + 15
            plate(0.08, 0.05, 0.012, P(a, R + 0.045, y0 + 0.03), yaw: -a + 90, "metal.steel")
            m.add(Prim.cylinder(radius: 0.011, height: 0.012, bevel: 0.001, segments: 6, bevelSegments: 1, material: "metal.rust"), Xform(translation: P(a, R + 0.045, y0 + 0.056)))
        }
        // Corrugated shell, one lathe: 4 profile points per 100 mm corrugation.
        var prof: [V2] = []
        var y = y0
        while y < y1 {
            let pts: [(Float, Float)] = [(0, 0), (0.25, 1), (0.5, 0), (0.75, -1)]
            for (f, s) in pts { prof.append(V2(R + amp * s, y + f * pitch)) }
            y += pitch
        }
        prof.append(V2(R, y1))
        m.add(Prim.lathe(prof, segments: 26, seamTile: 0.3, material: shell))
        // Sheet laps: 12 vertical strips with two bolt columns, plus alternate fresher sheets.
        for k in 0..<12 {
            let a = Float(k) * 30
            plate(0.075, y1 - y0, 0.004, P(a, R + 0.016, (y0 + y1) / 2), yaw: -a + 90, k % 3 == 0 ? fresh : shell)
            var yy = y0 + 0.1
            while yy < y1 - 0.04 {
                for d: Float in [-1.8, 1.8] {
                    m.add(Prim.superellipsoid(V3(0.014, 0.008, 0.014), exponent: 2, subdivisions: 1, material: rng.chance(0.12) ? "metal.rust" : "metal.screw-zinc"),
                          Xform(translation: P(a + d, R + 0.018, yy), rotation: facing(outward(a + d))))
                }
                yy += 0.36
            }
        }
        // Horizontal ring flanges at 1/3 and 2/3 (angle iron stiffeners) and bottom angle.
        for yy in [0.8, 1.5] as [Float] {
            m.add(Prim.lathe([V2(R + amp, yy), V2(R + 0.045, yy), V2(R + 0.045, yy + 0.006), V2(R + amp, yy + 0.006)], segments: 36, seamTile: 0.3, material: fresh))
        }
        // Rolled eave and roof: 12 degree cone with radial ribs.
        m.add(Prim.torus(major: R + 0.01, minor: 0.016, segments: 36, sides: 8, material: shell), Xform(translation: V3(0, y1 + 0.005, 0)))
        m.add(Prim.lathe([V2(R + 0.005, y1 + 0.005), V2(0.45, 2.325), V2(0.27, 2.37), V2(0.0, 2.375)], segments: 36, seamTile: 0.3, material: shell))
        for k in 0..<12 {
            let a = Float(k) * 30 + 15
            m.add(Prim.tube([P(a, R - 0.01, y1 + 0.012), P(a, 0.5, 2.318), P(a, 0.28, 2.372)], radii: [0.0065, 0.0065, 0.0065], sides: 5, seamTile: 0.1, material: fresh, capEnd: true))
        }
        // Manway hatch: 500 mm collar, hinged lid with hasp and padlock.
        m.add(Prim.cylinder(radius: 0.26, height: 0.1, bevel: 0.004, segments: 28, bevelSegments: 1, material: fresh), Xform(translation: V3(0, 2.36, 0)))
        m.add(Prim.cylinder(radius: 0.285, height: 0.025, bevel: 0.004, segments: 28, bevelSegments: 1, material: shell), Xform(translation: V3(0, 2.455, 0)))
        FA.box(&m, V3(0.12, 0.01, 0.02), V3(0, 2.488, -0.26), "metal.steel", r: 0.002)
        FA.box(&m, V3(0.05, 0.03, 0.03), V3(0, 2.472, 0.28), "metal.brass-aged", r: 0.004)
        // Vent: 80 mm pipe, mushroom cap and bird mesh on the roof.
        FA.rod(&m, P(120, 0.55, 2.31), P(120, 0.55, 2.52), r: 0.04, "metal.galvanized", sides: 14)
        m.add(Prim.lathe([V2(0.0, 0), V2(0.085, 0.0), V2(0.1, 0.03), V2(0.0, 0.06)], segments: 20, seamTile: 0.2, material: shell), Xform(translation: P(120, 0.55, 2.52)))
        // Inlet: 110 mm PVC with elbow dropping to the roof edge.
        let inl = catmull([P(210, 1.15, 2.2), P(210, 0.98, 2.285), P(210, 0.75, 2.34)], per: 4)
        m.add(Prim.tube(inl, radii: Array(repeating: 0.055, count: inl.count), sides: 14, seamTile: 0.2, material: "plastic.white", capEnd: true))
        // Overflow: 110 mm pipe from the top course, elbow, vertical drop with flap.
        let ofA: Float = 150
        let of1 = [P(ofA, R, 2.05), P(ofA, R + 0.12, 2.05), P(ofA, R + 0.17, 2.0), P(ofA, R + 0.17, 1.9), P(ofA, R + 0.17, 0.6)]
        m.add(Prim.tube(catmull(of1, per: 4), radii: Array(repeating: 0.055, count: catmull(of1, per: 4).count), sides: 14, seamTile: 0.2, material: "plastic.white", capEnd: true))
        FA.box(&m, V3(0.1, 0.12, 0.006), P(ofA, R + 0.17, 0.57), "plastic.black", r: 0.002, rot: FA.q(-ofA + 90, FA.Y) * FA.q(18, FA.X))
        // Sight gauge: clear tube on four clamps with a graduated plate and float.
        let ga: Float = 90
        let gx = P(ga, R + 0.07, 0)
        FA.rod(&m, V3(gx.x, 0.3, gx.z), V3(gx.x, 2.0, gx.z), r: 0.0125, "glass.clear", sides: 12)
        FA.box(&m, V3(0.03, 1.72, 0.004), V3(gx.x + 0.04, 1.15, gx.z - 0.0), "metal.aluminum-brushed", r: 0.001)
        for i in 0..<18 {
            FC.slab(&m, V3(i % 5 == 0 ? 0.02 : 0.012, 0.003, 0.002), V3(gx.x + 0.04, 0.31 + Float(i) * 0.095, gx.z + 0.0025), "plastic.black")
        }
        for yy in [0.35, 0.8, 1.3, 1.85] as [Float] {
            FA.box(&m, V3(0.04, 0.02, 0.06), V3(gx.x, yy, gx.z - 0.03), "metal.steel", r: 0.003)
            FA.cylZ(&m, r: 0.016, h: 0.02, at: V3(gx.x, yy, gx.z - 0.01), "metal.stainless", bevel: 0.002, segments: 12)
        }
        FA.ball(&m, r: 0.0105, at: V3(gx.x, 1.15, gx.z), "plastic.orange")
        // Outlet: 63 mm pipe, gate valve with red wheel, camlock.
        let oa: Float = 50
        let o0 = P(oa, R, 0.3), o1 = P(oa, R + 0.3, 0.3)
        FA.rod(&m, o0, o1, r: 0.0315, "metal.galvanized", sides: 14)
        let vc = P(oa, R + 0.17, 0.3)
        FA.box(&m, V3(0.1, 0.12, 0.1), vc, "metal.cast-iron", r: 0.008)
        FA.rod(&m, vc + V3(0, 0.06, 0), vc + V3(0, 0.16, 0), r: 0.009, "metal.steel", sides: 8)
        m.add(Prim.torus(major: 0.06, minor: 0.008, segments: 20, sides: 8, material: "metal.fire-extinguisher-red"), Xform(translation: vc + V3(0, 0.16, 0)))
        // Weathering: dark splash band at the base, rust runs under bolts, white scale tide marks.
        m.add(Prim.lathe([V2(R + 0.0, y0), V2(R + 0.0005, y0 + 0.2), V2(R + 0.0005, y0 + 0.28)].map { V2($0.x + amp * 1.6, $0.y) }, segments: 36, seamTile: 0.3, material: "metal.galvanized-aged:5A5448"))
        for _ in 0..<24 {
            let a = rng.float(0...360), len = rng.float(0.1...0.35), yy = rng.float(0.4...2.1)
            m.add(Prim.extrude(Shape2D.rect(rng.float(0.01...0.025), len), depth: 0.002, bevel: 0.0003, bevelSegments: 1, material: "metal.rust:8A4A2A"),
                  Xform(translation: P(a, R + 0.021, yy - len / 2), rotation: FA.q(-a + 90 + 0, FA.Y)))
        }
        groundAO(&m, height: 0.5, floor: 0.7)
        return LODModel(FC.fit(m, size))
    }
}
