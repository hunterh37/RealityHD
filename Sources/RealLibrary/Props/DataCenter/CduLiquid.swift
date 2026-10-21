import simd
import Foundation

/// CDU liquid: light-gray powdercoated coolant distribution unit with hinged doors, window onto the heat exchanger and pumps.
public struct CduLiquid: RealArticulated {
    public static let id = "cdu-liquid"
    public static let summary = "Coolant distribution unit: powdercoat cabinet, hinged doors, window onto plate heat exchanger and pumps, gauges, top piping stubs."
    public static let tags = ["prop", "articulated"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 15, distance: 4.2, studio: true)

    /// Overall size in meters (x width, y height, z depth). Front faces +Z.
    public var size = V3(0.8, 2.2, 1.2)
    /// Cabinet paint material key.
    public var paint: MaterialKey = "metal.powdercoat:C9CCCC"
    /// Door opening angle for the open state, degrees.
    public var openAngle: Float = 100
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 1)
        let w = size.x, hx = w / 2, hz = size.z / 2
        let plinth: Float = 0.1, bodyTop: Float = 2.1
        let steel: MaterialKey = "metal.stainless"
        let dark: MaterialKey = "plastic.matte:121316"
        func b(_ s: V3, _ p: V3, _ mat: MaterialKey, r: Float = 0.003) {
            rig.base[0].add(r < 0.002 ? cuboid(s, material: mat) : Prim.roundedBox(s, radius: r, bevelSegments: 1, material: mat), Xform(translation: p))
        }
        func cyl(_ rad: Float, _ h: Float, _ p: V3, _ mat: MaterialKey, rot: simd_quatf = .identity, segs: Int = 14) {
            rig.base[0].add(Prim.cylinder(radius: rad, height: h, bevel: min(0.002, rad * 0.25), segments: segs, bevelSegments: 1, material: mat), Xform(translation: p, rotation: rot))
        }
        let alongZ = simd_quatf(degrees: 90, axis: V3(1, 0, 0))
        let alongX = simd_quatf(degrees: 90, axis: V3(0, 0, 1))
        // Cabinet shell: plinth, floor, sides, back, roof, front header, inner dark liner.
        b(V3(w, plinth - 0.04, size.z), V3(0, 0.04 + (plinth - 0.04) / 2, 0), "metal.powdercoat:3A3C40", r: 0.004)
        b(V3(w, 0.02, size.z), V3(0, plinth + 0.01, 0), paint)
        for sx: Float in [-1, 1] { b(V3(0.02, bodyTop - plinth, size.z), V3(sx * (hx - 0.01), (bodyTop + plinth) / 2, 0), paint, r: 0.004) }
        b(V3(w - 0.04, bodyTop - plinth, 0.02), V3(0, (bodyTop + plinth) / 2, -hz + 0.01), paint, r: 0.004)
        b(V3(w, 0.025, size.z), V3(0, bodyTop - 0.0125, 0), paint, r: 0.006)
        b(V3(w - 0.05, bodyTop - plinth - 0.05, 0.004), V3(0, (bodyTop + plinth) / 2, -hz + 0.022), dark, r: 0.001)
        // Front header with gauges, HMI display and nameplate.
        let hy: Float = 1.95
        b(V3(w - 0.04, 0.28, 0.02), V3(0, hy, hz - 0.01), paint, r: 0.004)
        b(V3(0.14, 0.1, 0.006), V3(0.24, hy, hz + 0.003), dark, r: 0.003)
        b(V3(0.124, 0.08, 0.002), V3(0.24, hy, hz + 0.0072), "plastic.matte:2C5A8A", r: 0.001)
        b(V3(0.1, 0.012, 0.0014), V3(0.24, hy + 0.02, hz + 0.0086), "plastic.matte:E8E8E4", r: 0.0005)
        for (i, tint) in ["plastic.matte:2A5CB8", "plastic.matte:B51D17", "plastic.matte:2A5CB8"].enumerated() {
            let gx = -0.28 + Float(i) * 0.13
            cyl(0.05, 0.014, V3(gx, hy, hz + 0.0), steel, rot: alongZ, segs: 24)
            cyl(0.043, 0.002, V3(gx, hy, hz + 0.0135), "plastic.matte:F2F2EE", rot: alongZ, segs: 24)
            cyl(0.045, 0.0016, V3(gx, hy, hz + 0.0152), "glass.gauge-lens", rot: alongZ, segs: 24)
            b(V3(0.0018, 0.034, 0.0008), V3(gx + 0.008, hy + 0.01, hz + 0.0142), "plastic.matte:B51D17", r: 0.0005)
            b(V3(0.012, 0.004, 0.0008), V3(gx, hy - 0.028, hz + 0.0144), tint, r: 0.0005)
        }
        // Top piping stubs: facility supply/return, secondary supply/return, each with flange, bolts, colored band.
        for (i, (px, pz, band)) in [(-0.22, 0.25, "plastic.matte:2A5CB8"), (-0.08, 0.25, "plastic.matte:B51D17"), (0.12, -0.2, "plastic.matte:2A5CB8"), (0.26, -0.2, "plastic.matte:B51D17")].enumerated() {
            let p = V3(Float(px), bodyTop, Float(pz))
            _ = i
            cyl(0.04, 0.0015, p, steel, segs: 14)
            cyl(0.0285, 0.17, p + V3(0, 0.0015, 0), steel, segs: 14)
            cyl(0.048, 0.014, p + V3(0, 0.1, 0), steel, segs: 14)
            for k in 0..<4 {
                let a = Float(k) * .pi / 2
                cyl(0.0042, 0.006, p + V3(cos(a) * 0.04, 0.114, sin(a) * 0.04), steel, segs: 6)
            }
            cyl(0.0295, 0.012, p + V3(0, 0.05, 0), band, segs: 14)
        }
        // Interior: plate heat exchanger (stainless plate stack in frame), two pumps on a shelf, headers.
        let hxX: Float = -0.2, hxZ: Float = 0.0
        b(V3(0.26, 0.012, 0.8), V3(hxX, 0.72, hxZ), steel, r: 0.002)
        b(V3(0.26, 0.02, 0.8), V3(hxX, 1.5, hxZ), steel, r: 0.004)
        for k in 0..<10 {
            rig.base[0].add(cuboid(V3(0.2, 0.7, 0.0045), material: k % 2 == 0 ? steel : "metal.aluminum-brushed"), Xform(translation: V3(hxX, 1.11, -0.26 + Float(k) * 0.048)))
        }
        for sz: Float in [-1, 1] { b(V3(0.26, 0.76, 0.022), V3(hxX, 1.11, sz * 0.31), steel, r: 0.004) }
        for k in 0..<4 { _ = k; cyl(0.012, 0.22, V3(hxX + 0.11, 0.78 + Float(k / 2) * 0.62 + 0.0, (k < 2 ? -1 : 1) * 0.32 + 0.0), steel, rot: alongX, segs: 8) }
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] { cyl(0.009, 0.74, V3(hxX + sx * 0.12, 0.74, sz * 0.34), "metal.galvanized", segs: 8) } }
        b(V3(0.6, 0.02, 0.9), V3(0.1, 0.86, 0.0), "metal.powdercoat:3A3C40", r: 0.003)
        for (i, pz) in [Float(-0.2), 0.2].enumerated() {
            let px: Float = 0.04
            _ = i
            cyl(0.07, 0.2, V3(px - 0.1, 0.99, pz), "metal.powdercoat:2E5C9A", rot: alongX, segs: 14)
            cyl(0.085, 0.07, V3(px + 0.15, 0.99, pz), steel, rot: alongX, segs: 14)
            cyl(0.05, 0.08, V3(px + 0.18, 1.07, pz), steel, segs: 16)
            b(V3(0.09, 0.06, 0.1), V3(px - 0.12, 0.9, pz), "plastic.matte:121316", r: 0.003)
            cyl(0.03, 0.12, V3(px + 0.22, 0.99, pz), steel, rot: alongX, segs: 12)
        }
        // Piping runs from the exchanger up to the stubs and across to the pumps.
        for (sx, tz) in [(Float(-0.22), Float(0.25)), (-0.08, 0.25)] {
            let pts = [V3(hxX + sx * 0.3 - 0.0, 1.52, 0.3), V3(sx, 1.9, tz), V3(sx, bodyTop + 0.01, tz)]
            rig.base[0].add(Prim.tube(pts, radii: [0.0225, 0.0225, 0.0225], sides: 12, seamTile: 0.2, material: steel), .identity)
        }
        rig.base[0].add(Prim.tube([V3(0.1, 1.15, 0.2), V3(0.1, 1.9, -0.2), V3(0.12, bodyTop + 0.01, -0.2)], radii: [0.0225, 0.0225, 0.0225], sides: 12, seamTile: 0.2, material: steel), .identity)
        // Casters under the plinth.
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            let cp = V3(sx * (hx - 0.07), 0, sz * (hz - 0.07))
            b(V3(0.07, 0.004, 0.07), cp + V3(0, 0.042, 0), steel, r: 0.001)
            cyl(0.04, 0.03, cp + V3(0.0, 0.04, 0), "rubber.tire", rot: alongX, segs: 12)
        } }
        // Doors: left holds the window onto the exchanger and pumps, right is solid with louvers and a pull.
        let dh: Float = 1.7, dBottom: Float = 0.12, dw = (w - 0.04) / 2 - 0.004
        func door(_ name: String, hinge: Float, window: Bool) {
            let pivot = V3(hinge * (hx - 0.022), dBottom, hz - 0.005)
            rig.part(name, pivot: pivot, joint: .hinge(axis: .up, hinge > 0 ? -openAngle...0 : 0...openAngle, duration: 1.1))
            let dir = -hinge
            func put(_ s: Surface, _ t: V3, _ rot: simd_quatf = .identity) { rig.add(s, Xform(translation: pivot + t, rotation: rot), to: name) }
            func slab(_ sx: Float, _ sy: Float, _ cx: Float, _ cy: Float, _ mat: MaterialKey = paint) {
                put(Prim.roundedBox(V3(sx, sy, 0.024), radius: 0.003, bevelSegments: 1, material: mat), V3(dir * cx, cy, 0))
            }
            if window {
                let wy0: Float = 0.62, wy1: Float = 1.42, ww: Float = 0.3
                let side = (dw - ww) / 2
                slab(dw, wy0, dw / 2, wy0 / 2)
                slab(dw, dh - wy1, dw / 2, wy1 + (dh - wy1) / 2)
                for s: Float in [0, 1] { slab(side, wy1 - wy0, s == 0 ? side / 2 : dw - side / 2, (wy0 + wy1) / 2) }
                put(cuboid(V3(ww, wy1 - wy0, 0.004), material: "glass.clear"), V3(dir * dw / 2, (wy0 + wy1) / 2, 0.002))
                for s: Float in [-1, 1] { put(cuboid(V3(ww + 0.02, 0.012, 0.007), material: "plastic.matte:121316"), V3(dir * dw / 2, (wy0 + wy1) / 2 + s * (wy1 - wy0) / 2, 0.009)) }
                for s: Float in [-1, 1] { put(cuboid(V3(0.012, wy1 - wy0, 0.007), material: "plastic.matte:121316"), V3(dir * (dw / 2 + s * ww / 2), (wy0 + wy1) / 2, 0.009)) }
            } else {
                slab(dw, dh, dw / 2, dh / 2)
                for k in 0..<10 { put(cuboid(V3(dw - 0.1, 0.008, 0.002), material: dark), V3(dir * dw / 2, 0.2 + Float(k) * 0.026, 0.0132)) }
                put(cuboid(V3(0.06, 0.03, 0.0012), material: "plastic.matte:E8E8E4"), V3(dir * dw / 2, 1.5, 0.0126))
            }
            // Hinge barrels and a quarter-turn latch with chrome pull.
            for hy in [Float(0.15), dh / 2, dh - 0.15] { put(Prim.cylinder(radius: 0.007, height: 0.08, bevel: 0.001, segments: 8, material: steel), V3(0, hy - 0.04, 0.0)) }
            put(Prim.roundedBox(V3(0.02, 0.18, 0.016), radius: 0.006, bevelSegments: 2, material: steel), V3(dir * (dw - 0.03), 0.85, 0.02))
            put(Prim.cylinder(radius: 0.011, height: 0.006, bevel: 0.002, segments: 12, material: "metal.brass"), V3(dir * (dw - 0.03), 1.1, 0.012), alongZ)
        }
        door("cdu-door-left", hinge: -1, window: true)
        door("cdu-door-right", hinge: 1, window: false)
        groundAO(&rig, height: 0.15, floor: 0.5)
        rig.states = [RigState("closed", ["cdu-door-left": 0, "cdu-door-right": 0]), RigState("open", ["cdu-door-left": openAngle, "cdu-door-right": -openAngle])]
        rig.defaultState = "closed"
        return rig
    }
}
