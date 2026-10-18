import simd
import Foundation

/// AI rack 1 MW: Hyperscale AI hall, black powder coat, lightly scuffed at door edges, clean, new-install.. Parts: frame, front door (perforated), rear door (perforated), GPU trays, tray handles, coolant manifold, busbar, hoses, casters, leveling feet.
public struct RackAi1mw: RealAsset {
    public static let id = "rack-ai-1mw"
    public static let summary = "Liquid-cooled 1 MW AI training rack: black powder-coated steel frame, perforated front and rear doors, stacked GPU compute trays on slides, rear coolant manifold with quick-disconnect hoses and busbar."
    public static let tags = ["prop"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Front faces +Z.
    public var size = V3(0.6, 2.4, 1.4)
    /// Number of 1U GPU trays in the stack.
    public var trayCount = 29
    /// Index of the tray drawn out on its slides.
    public var pulledTray = -1
    /// How far the pulled tray extends (m).
    public var pullDistance: Float = 0.26
    /// Front door opening angle (degrees).
    public var frontDoorAngle: Float = 12
    /// Rear door opening angle (degrees).
    public var rearDoorAngle: Float = 0
    /// Rack frame material.
    public var frameMaterial: MaterialKey = "metal.anodized-black"
    /// Coolant supply hose tint (sRGB hex suffix).
    public var supplyMaterial: MaterialKey = "rubber.tubing:2A6FD0"
    /// Coolant return hose tint.
    public var returnMaterial: MaterialKey = "rubber.tubing:C8402C"
    public init() {}

    /// Cheap beveled box: XY rectangle extruded along Z, centered.
    func rb(_ s: V3, radius: Float, bevelSegments: Int, material: MaterialKey) -> Surface {
        let b = min(radius, min(s.x, min(s.y, s.z)) * 0.45)
        return Prim.extrude(Shape2D.rect(s.x, s.y), depth: s.z, bevel: b, bevelSegments: bevelSegments, material: material)
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let frame = frameMaterial
        let matte: MaterialKey = "plastic.matte:0D0E10"
        let alu: MaterialKey = "metal.aluminum-brushed"
        let steel: MaterialKey = "metal.stainless"
        let perf: MaterialKey = "metal.perforated"
        let trayFace: MaterialKey = "metal.aluminum-brushed"
        let w = size.x, d = size.z - 0.11
        let hx = w / 2, hz = d / 2
        let baseY: Float = 0.14, topY = size.y
        let zFront = hz - 0.03   // front door plane
        let zRear = -hz + 0.03

        func box(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.002, seg: Int = 1) {
            m.add(rb(s, radius: r, bevelSegments: seg, material: mat), Xform(translation: c))
        }

        // Frame: base plate, roof, four posts, solid side skins.
        box(V3(w, 0.03, d), V3(0, baseY - 0.015, 0), frame, r: 0.006, seg: 2)
        box(V3(w, 0.03, d), V3(0, topY - 0.015, 0), frame, r: 0.006, seg: 2)
        for sx: Float in [-1, 1] {
            for sz: Float in [-1, 1] {
                box(V3(0.035, topY - baseY - 0.06, 0.035), V3(sx * (hx - 0.0175), (topY + baseY) / 2, sz * (hz - 0.0175 - 0.03)), frame, r: 0.004, seg: 2)
            }
            box(V3(0.003, topY - baseY - 0.06, d - 0.08), V3(sx * (hx - 0.0015), (topY + baseY) / 2, 0), frame, r: 0.001)
        }
        // Roof cable entry and label strip.
        box(V3(0.30, 0.004, 0.16), V3(0.10, topY + 0.002, -0.40), alu, r: 0.001)
        box(V3(0.24, 0.032, 0.002), V3(0, topY - 0.07, zFront - 0.004), alu, r: 0.001)
        for i in 0..<5 {
            m.add(Prim.cylinder(radius: 0.003, height: 0.002, bevel: 0.0005, segments: 8, bevelSegments: 1, material: i == 4 ? "emissive.led-red" : "emissive.led-green"),
                  Xform(translation: V3(-0.09 + Float(i) * 0.014, topY - 0.14, zFront - 0.004), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }

        // Tray stack. Filler keeps gaps dark.
        let pitch: Float = 0.04445
        let y0: Float = 0.30
        let zFace = zFront - 0.03
        let stackTop = y0 + Float(trayCount) * pitch
        box(V3(w - 0.07, stackTop - y0, zFace + 0.30), V3(0, (stackTop + y0) / 2, (zFace - 0.30) / 2), matte, r: 0.001)
        // Switch and power shelf blocks above the trays.
        box(V3(0.50, 0.17, 0.02), V3(0, stackTop + 0.11, zFace - 0.01), alu, r: 0.003, seg: 2)
        for i in 0..<3 {
            let y = stackTop + 0.04 + Float(i) * 0.055
            box(V3(0.47, 0.048, 0.006), V3(0, y, zFace + 0.004), matte, r: 0.002)
            for k in 0..<6 {
                m.add(Prim.cylinder(radius: 0.0025, height: 0.002, bevel: 0.0004, segments: 6, bevelSegments: 1, material: "emissive.led-green"),
                      Xform(translation: V3(-0.2 + Float(k) * 0.022, y + 0.012, zFace + 0.007), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            }
        }

        for t in 0..<trayCount {
            var r = rng.fork(t)
            let y = y0 + (Float(t) + 0.5) * pitch
            let pulled = t == pulledTray
            let zf = zFace + (pulled ? pullDistance : 0)
            box(V3(0.50, pitch - 0.003, 0.012), V3(0, y, zf - 0.006), trayFace, r: 0.002)
            // Handles: tube loops left and right.
            for sx: Float in [-1, 1] {
                let hx0 = sx * 0.215
                let p = [V3(hx0 - 0.016, y + 0.006, zf), V3(hx0 - 0.016, y + 0.006, zf + 0.014), V3(hx0 + 0.016, y + 0.006, zf + 0.014), V3(hx0 + 0.016, y + 0.006, zf)]
                m.add(Prim.tube(p, radii: [0.0028, 0.0028, 0.0028, 0.0028], sides: 4, seamTile: 0.1, material: alu))
            }
            // Status LEDs and port.
            for k in 0..<3 {
                let green = !(k == 2 && r.chance(0.08))
                box(V3(0.004, 0.003, 0.0016), V3(-0.17 + Float(k) * 0.011, y - 0.008, zf + 0.0008), green ? "emissive.led-green" : "emissive.led-red", r: 0.0003)
            }
        }

        // Pulled tray body: chassis, PCB, four GPU modules with cold plates, copper tubing.
        if pulledTray >= 0 {
            let y = y0 + (Float(pulledTray) + 0.5) * pitch
            let zf = zFace + pullDistance
            let len = pullDistance + 0.10
            let zc = zf - len / 2 - 0.012
            box(V3(0.46, 0.002, len), V3(0, y - 0.016, zc), alu, r: 0.0006)
            for sx: Float in [-1, 1] {
                box(V3(0.002, 0.034, len), V3(sx * 0.229, y + 0.001, zc), alu, r: 0.0006)
                box(V3(0.006, 0.008, len + 0.02), V3(sx * 0.236, y - 0.002, zc - 0.01), steel, r: 0.0015)
            }
            box(V3(0.44, 0.0016, len - 0.01), V3(0, y - 0.0144, zc), "plastic.pcb", r: 0.0005)
            for gx: Float in [-1, 1] {
                for gz in 0..<2 {
                    let c = V3(gx * 0.10, y - 0.0, zc - 0.03 - Float(gz) * 0.12)
                    if c.z < zf - 0.03 - 0.012 - 0.01 || gz == 0 {
                        box(V3(0.075, 0.026, 0.085), c, "metal.nickel", r: 0.002)
                        box(V3(0.07, 0.0016, 0.08), c + V3(0, 0.0138, 0), "copper.polished", r: 0.0003)
                    }
                }
            }
            let p = [V3(-0.10, y + 0.013, zc - 0.03), V3(-0.10, y + 0.02, zc - 0.07), V3(0.10, y + 0.02, zc - 0.07), V3(0.10, y + 0.013, zc - 0.03)]
            m.add(Prim.tube(catmull(p, per: 3), radii: Array(repeating: 0.004, count: catmull(p, per: 3).count), sides: 6, seamTile: 0.1, material: "metal.copper"))
        }

        // Rear: back plate for trays, manifold, hoses, busbar, cables.
        let zBack = zFace - 0.30 - 0.0  // tray rear face z
        let rz = zBack - 0.015
        box(V3(0.50, stackTop - y0, 0.006), V3(0, (stackTop + y0) / 2, rz), "metal.aluminum-brushed", r: 0.001)
        let supplyX: Float = -0.235, returnX: Float = -0.175, pipeZ = zRear + 0.12
        for (px, mat) in [(supplyX, supplyMaterial), (returnX, returnMaterial)] {
            m.add(Prim.cylinder(radius: 0.02, height: stackTop - y0 + 0.30, bevel: 0.004, segments: 14, bevelSegments: 1, material: steel),
                  Xform(translation: V3(px, y0 - 0.12, pipeZ)))
            for yy in stride(from: y0 + 0.05, to: stackTop + 0.1, by: 0.45) {
                m.add(Prim.cylinder(radius: 0.0235, height: 0.03, bevel: 0.003, segments: 14, bevelSegments: 1, material: mat),
                      Xform(translation: V3(px, yy, pipeZ)))
            }
        }
        for t in stride(from: 0, to: trayCount, by: 3) {
            let y = y0 + (Float(t) + 1.0) * pitch
            for (px, mat, dx) in [(supplyX, supplyMaterial, Float(0.00)), (returnX, returnMaterial, 0.05)] {
                let end = V3(-0.14 + dx + (px == supplyX ? -0.0 : 0.04), y + (px == supplyX ? 0.008 : -0.008), rz)
                let src = V3(px, y, pipeZ)
                let wob = Float(t % 4) * 0.003
                let pts = catmull([src + V3(0, 0, 0.02), V3(px + 0.04 + wob, y + 0.01, pipeZ + 0.06), V3(end.x - 0.01, end.y + 0.02, end.z - 0.06 - wob), end], per: 1)
                m.add(Prim.tube(pts, radii: Array(repeating: 0.0085, count: pts.count), sides: 5, seamTile: 0.1, material: mat))
                box(V3(0.022, 0.022, 0.022), end + V3(0, 0, 0.009), steel, r: 0.003)
            }
        }

        // 800 V busbar: two flat copper bars with insulated spacers and tap blocks.
        for (bx, tag) in [(Float(0.05), 0), (Float(0.10), 1)] {
            box(V3(0.035, stackTop - y0 + 0.4, 0.008), V3(bx, (stackTop + y0) / 2 + 0.1, zRear + 0.06), "metal.tinned-copper", r: 0.001)
            box(V3(0.04, stackTop - y0 + 0.2, 0.014), V3(bx, (stackTop + y0) / 2 + 0.1, zRear + 0.06 - 0.011), "rubber.insulating-orange", r: 0.002)
            _ = tag
        }
        for yy in stride(from: y0 + 0.02, to: stackTop + 0.3, by: 0.3) {
            box(V3(0.11, 0.03, 0.03), V3(0.075, yy, zRear + 0.06 - 0.0), "rubber.insulating-orange", r: 0.003)
        }
        for t in stride(from: 0, to: trayCount, by: 4) {
            let y = y0 + (Float(t) + 1.0) * pitch
            box(V3(0.09, 0.012, 0.004), V3(0.075, y, zRear + 0.09), "metal.tinned-copper", r: 0.0008)
            box(V3(0.04, 0.014, 0.018), V3(0.12, y, rz + 0.1 > zRear ? (rz + zRear + 0.06) / 2 + 0.05 : rz), "plastic.matte:E06A10", r: 0.002)
        }

        // Cable bundles with ties, dropping from the roof entry along the right rear post.
        for (i, off) in [Float(0), 0.012, -0.012].enumerated() {
            let top = V3(0.19 + off, topY, -0.40 + off)
            let pts = catmull([top, V3(0.22 + off, topY - 0.1, zRear + 0.05), V3(0.255 + off, 1.4, zRear + 0.04), V3(0.24 + off, 0.5, zRear + 0.06 + Float(i) * 0.006), V3(0.20 + off, y0 + 0.05, rz)], per: 3)
            m.add(Prim.tube(pts, radii: Array(repeating: 0.0095, count: pts.count), sides: 5, seamTile: 0.1, material: i == 1 ? "rubber.tubing:C9C30D" : "plastic.matte:101112"))
        }
        for yy in stride(from: Float(0.45), to: 2.3, by: 0.24) {
            let x: Float = 0.23 + 0.014 * sin(yy * 4)
            m.add(Prim.torus(major: 0.026, minor: 0.0028, segments: 8, sides: 3, material: "plastic.matte:2A2C30"),
                  Xform(translation: V3(x, yy, zRear + 0.05)))
        }

        // Doors: perforated panel inside a powder-coated frame; hinged on opposite sides.
        func door(angle: Float, hinge: Float, zPlane: Float) {
            let dw = w - 0.03, dh = topY - baseY - 0.03
            let dirX = -hinge, off = dirX * dw / 2
            let q = simd_quatf(degrees: -angle, axis: V3(0, 1, 0))
            let pivot = V3(hinge * (hx - 0.005), baseY + 0.015, zPlane)
            func put(_ s: Surface, _ t: V3, _ r: simd_quatf = .identity) {
                m.add(s, Xform(translation: pivot + q.act(t), rotation: q * r))
            }
            put(rb(V3(dw - 0.04, dh - 0.04, 0.002), radius: 0.0005, bevelSegments: 1, material: perf), V3(off, dh / 2, 0))
            for yy in [Float(0), dh] {
                put(rb(V3(dw, 0.03, 0.026), radius: 0.004, bevelSegments: 2, material: frame), V3(off, yy, 0))
            }
            for ex in [Float(0.015), dw - 0.015] {
                put(rb(V3(0.03, dh, 0.026), radius: 0.004, bevelSegments: 2, material: frame), V3(dirX * ex, dh / 2, 0))
            }
            let hs = rb(V3(0.018, 0.12, 0.018), radius: 0.004, bevelSegments: 1, material: steel)
            for hy in [Float(0.2), dh / 2, dh - 0.2] { put(hs, V3(0, hy, 0)) }
            let outward: Float = zPlane > 0 ? 1 : -1
            let hr = simd_quatf(degrees: zPlane > 0 ? 0 : 180, axis: V3(0, 1, 0)) * simd_quatf(degrees: 90, axis: V3(0, 0, 1))
            put(barHandle(length: 0.16, standoff: 0.03, radius: 0.007, overhang: 0.01, material: alu),
                V3(dirX * (dw - 0.015), dh * 0.5, 0.013 * outward), hr)
        }
        door(angle: frontDoorAngle, hinge: -1, zPlane: hz - 0.012)
        door(angle: rearDoorAngle, hinge: 1, zPlane: -hz + 0.012)

        // Casters at the corners, leveling feet inboard.
        for sx: Float in [-1, 1] {
            for sz: Float in [-1, 1] {
                let cp = V3(sx * 0.24, 0, sz * 0.52)
                box(V3(0.07, 0.004, 0.07), cp + V3(0, baseY - 0.002, 0), steel, r: 0.001)
                m.add(Prim.cylinder(radius: 0.012, height: 0.02, bevel: 0.002, segments: 8, bevelSegments: 1, material: steel), Xform(translation: cp + V3(0, baseY - 0.024, 0)))
                for side: Float in [-1, 1] {
                    box(V3(0.003, baseY - 0.03, 0.04), cp + V3(side * 0.02, (baseY - 0.03) / 2 + 0.02, 0), steel, r: 0.0006)
                }
                m.add(Prim.cylinder(radius: 0.04, height: 0.032, bevel: 0.006, segments: 12, bevelSegments: 1, material: "rubber.tire"),
                      Xform(translation: cp + V3(0.016, 0.04, 0), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
                let fp = V3(sx * 0.26, 0, sz * 0.62)
                m.add(Prim.cylinder(radius: 0.022, height: 0.012, bevel: 0.003, segments: 8, bevelSegments: 1, material: "metal.cast-iron"), Xform(translation: fp))
                m.add(Prim.cylinder(radius: 0.008, height: baseY - 0.012, bevel: 0.001, segments: 6, bevelSegments: 1, material: steel), Xform(translation: fp + V3(0, 0.012, 0)))
            }
        }
        groundAO(&m)
        return LODModel(m)
    }
}
