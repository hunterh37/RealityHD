import simd
import Foundation

/// Power shelf 800 VDC: 2U rack power shelf in worn dark powder-coat with six hot-swap PSU modules (handles, status LEDs, airflow grilles), vented top cover, rack ears and a rear copper busbar clip. Named part "psu-slide" (module 3) slides out 0.28 m.
public struct PowerShelf800vdc: RealArticulated {
    public static let id = "power-shelf-800vdc"
    public static let summary = "2U 800 VDC rack power shelf with six hot-swap PSU modules, handles, LEDs, airflow grilles, vented cover and a rear busbar clip."
    public static let tags = ["prop", "articulated"]
    public static let budget = 6000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 14, distance: 0.8, studio: true)

    /// Overall width (x), height (y), depth (z) in meters.
    public var size = V3(0.44, 0.09, 0.7)
    /// Chassis paint.
    public var paint: MaterialKey = "metal.powdercoat:6B7077"
    /// Module face paint.
    public var faceplate: MaterialKey = "metal.powdercoat:8A8F96"
    /// Handle and latch plastic.
    public var handle: MaterialKey = "plastic.matte:151618"
    /// Busbar metal.
    public var busbar: MaterialKey = "metal.copper"
    /// Slide-out travel of module 3 in meters.
    public var travel: Float = 0.28
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 1)
        var rng = SeededRNG(seed: seed)
        let W = size.x, H = size.y, D = size.z
        let t: Float = 0.0016
        let part = "psu-slide"
        let slideIndex = 2
        let mw: Float = (W - 0.024 - 7 * 0.002) / 6
        let mh = H - 0.014
        let zf = size.z / 2 - 0.004
        let zR = -size.z / 2 + 0.06
        let md: Float = 0.42
        rig.part(part, pivot: V3(0, H / 2, zf), joint: .slide(axis: V3(0, 0, 1), 0...travel, duration: 1.2))

        func add(_ s: Surface, _ x: Xform, to: String? = nil) {
            if let to { rig.add(s, x, to: to) } else { rig.base[0].add(s, x) }
        }
        func box(_ s: V3, _ c: V3, r: Float = 0, mat: MaterialKey, to: String? = nil) {
            if r == 0 || min(s.x, min(s.y, s.z)) < 0.004 { add(cuboid(s, material: mat), Xform(translation: c), to: to); return }
            add(Prim.roundedBox(s, radius: min(r, min(s.x, min(s.y, s.z)) * 0.4), bevelSegments: 1, material: mat), Xform(translation: c), to: to)
        }
        func cyl(_ r: Float, _ h: Float, _ c: V3, mat: MaterialKey, axisZ: Bool = true, to: String? = nil) {
            add(Prim.cylinder(radius: r, height: h, bevel: min(0.0008, r * 0.3), segments: 8, bevelSegments: 1, material: mat),
                Xform(translation: c, rotation: simd_quatf(degrees: axisZ ? 90 : 0, axis: V3(1, 0, 0))), to: to)
        }

        // Chassis: floor, top cover, side walls, rear plate, front bay dividers.
        let chassisD: Float = D - 0.02
        let cz: Float = (size.z / 2 - 0.02 + zR) / 2
        box(V3(W, t, chassisD), V3(0, t / 2, cz), r: 0.0008, mat: paint)
        box(V3(W, t, chassisD), V3(0, H - t / 2, cz), r: 0.0008, mat: paint)
        for s: Float in [-1, 1] {
            box(V3(t, H, chassisD), V3(s * (W / 2 - t / 2), H / 2, cz), r: 0.0008, mat: paint)
        }
        box(V3(W, H, t), V3(0, H / 2, zR + t / 2), r: 0.0008, mat: paint)
        box(V3(W - 0.01, H - 0.01, 0.004), V3(0, H / 2, zR + 0.05), mat: "plastic.matte:0B0B0C")   // dark cavity back wall
        for i in 0...6 {
            let x = -W / 2 + 0.012 + 0.001 + Float(i) * (mw + 0.002)
            box(V3(0.002, H - 0.004, 0.012), V3(x, H / 2, zf - 0.006), mat: paint)
        }
        // Front frame lips above and below the bays.
        box(V3(W - 0.004, 0.005, 0.012), V3(0, H - 0.0025, zf - 0.006), r: 0.0008, mat: paint)
        box(V3(W - 0.004, 0.005, 0.012), V3(0, 0.0025, zf - 0.006), r: 0.0008, mat: paint)

        // Rack ears: flush pads at each end with oval mounting slots, rear stiffening flange.
        for s: Float in [-1, 1] {
            box(V3(0.012, H, 0.003), V3(s * (W / 2 - 0.006), H / 2, zf + 0.0005), r: 0.001, mat: paint)
            for y in [H * 0.22, H * 0.78] {
                box(V3(0.006, 0.011, 0.0012), V3(s * (W / 2 - 0.006), y, zf + 0.0023), mat: "plastic.matte:050505")
            }
        }

        // Top cover vents: two ranks of slots, plus a rolled stiffening bead and an ID label.
        for rank in 0..<2 {
            let z0: Float = rank == 0 ? 0.12 : -0.2
            for i in 0..<8 {
                let x = -0.158 + Float(i) * 0.045
                for j in 0..<2 {
                    box(V3(0.016, 0.0004, 0.004), V3(x, H + 0.0001, z0 + Float(j) * 0.009), mat: "plastic.matte:040404")
                }
            }
        }
        box(V3(0.001, 0.0008, chassisD - 0.04), V3(-0.205, H + 0.0004, cz), mat: "metal.powdercoat:3A3C41")
        box(V3(0.001, 0.0008, chassisD - 0.04), V3(0.205, H + 0.0004, cz), mat: "metal.powdercoat:3A3C41")
        box(V3(0.07, 0.0003, 0.03), V3(0.11, H + 0.00015, -0.02), mat: "plastic.matte:E8E8E4")
        for i in 0..<5 {
            box(V3(0.05 - 0.006 * Float(i % 2), 0.0004, 0.0025), V3(0.11 - 0.005 * Float(i % 2) * 0.5, H + 0.0004, -0.007 - Float(i) * 0.0058), mat: "plastic.matte:1A1A1A")
        }
        // Handling wear: pale rub marks on cover edge and ears, one chip.
        for i in 0..<5 {
            let x = -0.19 + Float(rng.next() % 380) / 1000
            box(V3(0.012 + Float(rng.next() % 20) / 1000, 0.0004, 0.0012), V3(x, H + 0.0003, zf - 0.03 - Float(i) * 0.002), mat: "metal.powdercoat:5B5E63")
        }
        for s: Float in [-1, 1] {
            box(V3(0.0012, H - 0.02, 0.0008), V3(s * (W / 2 - 0.0125), H / 2, zf + 0.0026), mat: "metal.powdercoat:6A6D72")
        }

        // Rear: busbar clip housing and two copper bars with bolted lugs, plus exhaust grille.
        let zr = zR
        box(V3(0.12, H - 0.016, 0.03), V3(0.11, H / 2, zr - 0.015), r: 0.002, mat: "plastic.matte:2B2D30")
        box(V3(0.12, 0.004, 0.012), V3(0.11, H - 0.012, zr - 0.036), r: 0.001, mat: "plastic.matte:3A3C40")
        box(V3(0.12, 0.004, 0.012), V3(0.11, 0.012, zr - 0.036), r: 0.001, mat: "plastic.matte:3A3C40")
        for (i, x) in [Float(0.085), 0.135].enumerated() {
            box(V3(0.028, H - 0.03, 0.004), V3(x, H / 2, zr - 0.032), r: 0.0006, mat: busbar)
            for y in [H * 0.28, H * 0.72] {
                cyl(0.004, 0.003, V3(x, y, zr - 0.035), mat: "metal.steel", to: nil)
            }
            if i == 1 { box(V3(0.014, 0.0012, 0.0008), V3(x, H * 0.5, zr - 0.0345), mat: "metal.copper-patina") }
        }
        for i in 0..<8 {
            for j in 0..<2 {
                box(V3(0.0035, 0.016, 0.0006), V3(-0.19 + Float(i) * 0.0132, 0.02 + Float(j) * 0.05, zr - 0.0003), mat: "plastic.matte:030303")
            }
        }
        // Rear terminal block for the AC/HVDC input.
        box(V3(0.09, 0.03, 0.02), V3(-0.12, H / 2, zr - 0.01), r: 0.0015, mat: "plastic.matte:3A3C40")

        // Six PSU modules.
        for i in 0..<6 {
            let x = -W / 2 + 0.012 + 0.002 + mw / 2 + Float(i) * (mw + 0.002)
            let to: String? = i == slideIndex ? part : nil
            let fault = i == 4
            // Body, faceplate, grille slots, release latch, handle, LEDs, label.
            box(V3(mw - 0.002, mh - 0.002, md), V3(x, H / 2, zf - md / 2 - 0.004), mat: "metal.galvanized", to: to)
            box(V3(mw, mh, 0.008), V3(x, H / 2, zf - 0.002), r: 0.0015, mat: faceplate, to: to)
            for k in 0..<7 {
                let gx = x - mw / 2 + 0.008 + Float(k) * (mw - 0.016) / 6
                box(V3(0.0018, 0.034, 0.001), V3(gx, H / 2 + 0.014, zf + 0.0024), mat: "plastic.matte:040404", to: to)
            }
            box(V3(0.02, 0.006, 0.004), V3(x + mw / 2 - 0.016, H / 2 - 0.006, zf + 0.004), r: 0.0012, mat: "plastic.orange", to: to)
            let hy = H / 2 - 0.022
            let hz = zf + 0.003
            let pts = [V3(x - 0.02, hy, hz), V3(x - 0.02, hy, hz + 0.012), V3(x - 0.016, hy, hz + 0.019),
                       V3(x + 0.016, hy, hz + 0.019), V3(x + 0.02, hy, hz + 0.012), V3(x + 0.02, hy, hz)]
            add(Prim.tube(pts, radii: Array(repeating: 0.0028, count: pts.count), sides: 8, seamTile: 0.05, material: handle), .identity, to: to)
            cyl(0.0016, 0.0016, V3(x - 0.016, H / 2 + 0.002, zf + 0.0034), mat: fault ? "emissive.signal-orange" : "emissive.led-green", to: to)
            cyl(0.0016, 0.0016, V3(x - 0.008, H / 2 + 0.002, zf + 0.0034), mat: fault ? "emissive.signal-red" : "emissive.led-green", to: to)
            box(V3(0.026, 0.0003, 0.0005), V3(x, H / 2 + 0.034, zf + 0.0022), mat: "plastic.matte:E8E8E4", to: to)
            // Edge wear on the faceplate.
            box(V3(0.0012, mh - 0.01, 0.0006), V3(x - mw / 2 + 0.0008, H / 2, zf + 0.0023), mat: "metal.powdercoat:6A6D72", to: to)
        }
        // Story detail: module 5 faceplate has a dent-scuff and a hand-written asset tag.
        box(V3(0.02, 0.003, 0.0006), V3(-W / 2 + 0.012 + 0.002 + mw / 2 + 4 * (mw + 0.002), H / 2 - 0.0345 + 0.06, zf + 0.0024), mat: "plastic.matte:D8C86A")

        rig.states = [RigState("seated"), RigState("open", [part: travel])]
        rig.defaultState = "seated"
        groundAO(&rig.base[0])
        return rig
    }
}
