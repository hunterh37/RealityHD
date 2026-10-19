import simd
import Foundation

/// CRAH unit: floor-standing computer room air handler in off-white powdercoat with hinged front doors, chilled-water coil and EC fans inside, top discharge grille.
public struct CrahUnit: RealArticulated {
    public static let id = "crah-unit"
    public static let summary = "Computer room air handler: powdercoat cabinet, three hinged front doors, chilled-water coil and EC fan bank inside, display, top grille, water stubs."
    public static let tags = ["prop", "articulated"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 14, distance: 5.2, studio: true)

    /// Overall size in meters (x width, y height, z depth). Front faces +Z.
    public var size = V3(2.5, 2.2, 1.0)
    /// Cabinet paint material key.
    public var paint: MaterialKey = "metal.powdercoat:E9E9E4"
    /// Door opening angle for the open state, degrees.
    public var openAngle: Float = 100
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 1)
        let w = size.x, hx = w / 2, hz = size.z / 2, top = size.y
        let plinth: Float = 0.1
        let steel: MaterialKey = "metal.stainless"
        let dark: MaterialKey = "plastic.matte:121316"
        func b(_ s: V3, _ p: V3, _ mat: MaterialKey, r: Float = 0.003) {
            rig.base[0].add(r < 0.002 ? cuboid(s, material: mat) : Prim.roundedBox(s, radius: r, bevelSegments: 1, material: mat), Xform(translation: p))
        }
        func cyl(_ rad: Float, _ h: Float, _ p: V3, _ mat: MaterialKey, rot: simd_quatf = .identity, segs: Int = 12) {
            rig.base[0].add(Prim.cylinder(radius: rad, height: h, bevel: min(0.002, rad * 0.25), segments: segs, bevelSegments: 1, material: mat), Xform(translation: p, rotation: rot))
        }
        let alongZ = simd_quatf(degrees: 90, axis: V3(1, 0, 0))
        // Shell.
        b(V3(w, plinth, size.z), V3(0, plinth / 2, 0), "metal.powdercoat:3A3C40", r: 0.004)
        b(V3(w, 0.02, size.z), V3(0, plinth + 0.01, 0), paint)
        for sx: Float in [-1, 1] { b(V3(0.025, top - plinth, size.z), V3(sx * (hx - 0.0125), (top + plinth) / 2, 0), paint, r: 0.004) }
        b(V3(w - 0.05, top - plinth, 0.02), V3(0, (top + plinth) / 2, -hz + 0.01), paint, r: 0.004)
        b(V3(w - 0.05, 0.004, size.z - 0.04), V3(0, (top + plinth) / 2, 0), dark, r: 0.001)
        // Top: frame with a discharge grille and a duct collar.
        b(V3(w, 0.03, 0.12), V3(0, top - 0.015, hz - 0.06), paint, r: 0.004)
        b(V3(w, 0.03, 0.12), V3(0, top - 0.015, -hz + 0.06), paint, r: 0.004)
        for sx: Float in [-1, 1] { b(V3(0.12, 0.03, size.z - 0.24), V3(sx * (hx - 0.06), top - 0.015, 0), paint, r: 0.004) }
        for k in 0..<14 { b(V3(w - 0.24, 0.006, 0.012), V3(0, top - 0.018, -0.36 + Float(k) * 0.055), "metal.powdercoat:3A3C40", r: 0.001) }
        // Interior: coil block on the right half, three EC fans on the left half.
        b(V3(0.9, 1.5, 0.12), V3(hx - 0.6, 1.0, 0.1), "metal.aluminum-brushed", r: 0.002)
        for k in 0..<18 { b(V3(0.88, 0.0035, 0.1), V3(hx - 0.6, 0.28 + Float(k) * 0.08, 0.1), steel, r: 0.0005) }
        for k in 0..<3 {
            let fx = -hx + 0.35 + Float(k) * 0.4
            cyl(0.17, 0.12, V3(fx, 1.2, 0.1), "plastic.matte:2A2C30", rot: alongZ, segs: 20)
            cyl(0.06, 0.14, V3(fx, 1.2, 0.1), steel, rot: alongZ, segs: 14)
            for j in 0..<7 {
                let a = Float(j) * 2 * .pi / 7
                b(V3(0.1, 0.02, 0.012), V3(fx + cos(a) * 0.1, 1.2 + sin(a) * 0.1, 0.17), "plastic.matte:3A3C40", r: 0.0)
            }
        }
        // Chilled-water stubs through the roof: supply (blue), return (red), flanged.
        for (i, band) in ["plastic.matte:2A5CB8", "plastic.matte:B51D17"].enumerated() {
            let p = V3(hx - 0.5 + Float(i) * 0.18, top, -0.25)
            cyl(0.04, 0.0015, p, steel, segs: 12)
            cyl(0.028, 0.14, p + V3(0, 0.0015, 0), steel, segs: 12)
            cyl(0.046, 0.012, p + V3(0, 0.1, 0), steel, segs: 12)
            cyl(0.029, 0.012, p + V3(0, 0.05, 0), band, segs: 12)
        }
        // Front: HMI display and status lamp in the header strip.
        b(V3(0.16, 0.1, 0.006), V3(-hx + 0.4, top - 0.1, hz + 0.003), dark, r: 0.003)
        b(V3(0.14, 0.08, 0.002), V3(-hx + 0.4, top - 0.1, hz + 0.0065), "plastic.matte:2C5A8A", r: 0.001)
        cyl(0.008, 0.004, V3(-hx + 0.55, top - 0.1, hz + 0.003), "plastic.matte:2AB85C", rot: alongZ, segs: 8)
        // Doors.
        let dh: Float = top - 0.3, dBottom: Float = 0.12, dw = (w - 0.05) / 3 - 0.004
        func door(_ name: String, hinge: Float, cx: Float, solid: Bool) {
            let pivot = V3(cx + hinge * dw / 2, dBottom, hz - 0.005)
            rig.part(name, pivot: pivot, joint: .hinge(axis: .up, hinge > 0 ? -openAngle...0 : 0...openAngle, duration: 1.1))
            let dir = -hinge
            func put(_ s: Surface, _ t: V3) { rig.add(s, Xform(translation: pivot + t), to: name) }
            put(Prim.roundedBox(V3(dw, dh, 0.024), radius: 0.003, bevelSegments: 1, material: paint), V3(dir * dw / 2, dh / 2, 0))
            for k in 0..<(solid ? 8 : 12) { put(cuboid(V3(dw - 0.14, 0.01, 0.002), material: dark), V3(dir * dw / 2, 0.25 + Float(k) * 0.12, 0.0132)) }
            for hy in [Float(0.2), dh - 0.2] { put(Prim.cylinder(radius: 0.007, height: 0.08, bevel: 0.001, segments: 8, material: steel), V3(0, hy, 0)) }
            put(Prim.roundedBox(V3(0.02, 0.16, 0.016), radius: 0.006, bevelSegments: 2, material: steel), V3(dir * (dw - 0.04), 0.9, 0.02))
        }
        let third = (w - 0.05) / 3
        door("crah-door-left", hinge: -1, cx: -third, solid: false)
        door("crah-door-mid", hinge: -1, cx: 0, solid: true)
        door("crah-door-right", hinge: 1, cx: third, solid: false)
        groundAO(&rig, height: 0.15, floor: 0.5)
        rig.states = [RigState("closed", ["crah-door-left": 0, "crah-door-mid": 0, "crah-door-right": 0]),
                      RigState("open", ["crah-door-left": openAngle, "crah-door-mid": openAngle, "crah-door-right": -openAngle])]
        rig.defaultState = "closed"
        return rig
    }
}
