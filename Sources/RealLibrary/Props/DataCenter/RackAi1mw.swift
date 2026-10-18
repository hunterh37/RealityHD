import simd
import Foundation

/// AI rack 1 MW: Hyperscale AI hall, black powder coat, lightly scuffed at door edges, clean, new-install.. Parts: frame, front door (perforated), rear door (perforated), GPU trays, tray handles, coolant manifold, busbar, hoses, casters, leveling feet.
public struct RackAi1mw: RealArticulated {
    public static let id = "rack-ai-1mw"
    public static let summary = "Liquid-cooled 1 MW AI rack: perforated doors, 18 named GPU tray slots, U rails, PDUs, coolant manifolds, TOR switch."
    public static let tags = ["prop", "articulated"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Front faces +Z.
    public var size = V3(0.6, 2.4, 1.4)
    /// Number of named 1U compute tray slots (two banks, up to 18).
    public var trayCount = 18
    /// Front door opening angle in the default state (degrees).
    public var frontDoorAngle: Float = 0
    /// Rear door opening angle in the default state (degrees).
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

    public func rig(seed: UInt64) -> Rig {
        let rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 1)
        let frame = frameMaterial
        let matte: MaterialKey = "plastic.matte:0D0E10"
        let alu: MaterialKey = "metal.aluminum-brushed"
        let steel: MaterialKey = "metal.stainless"
        let perf: MaterialKey = "metal.perforated"
        let w = size.x, d = size.z - 0.11
        let hx = w / 2, hz = d / 2
        let baseY: Float = 0.14, topY = size.y
        let zFront = hz - 0.03
        let zRear = -hz + 0.03
        let pitch: Float = 0.04445
        let y0: Float = 0.30
        let zFace = zFront - 0.03
        let stackU = 43
        let stackTop = y0 + Float(stackU) * pitch
        func uy(_ u: Int) -> Float { y0 + (Float(u) + 0.5) * pitch }

        func box(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.002, seg: Int = 1, to part: String? = nil) {
            let surf = (seg <= 1 && r < 0.004) ? cuboid(s, material: mat) : rb(s, radius: r, bevelSegments: seg, material: mat)
            if let part { rig.add(surf, Xform(translation: c), to: part) } else { rig.base[0].add(surf, Xform(translation: c)) }
        }
        func cyl(_ rad: Float, _ h: Float, _ c: V3, _ mat: MaterialKey, rot: simd_quatf = .identity, segs: Int = 8, to part: String? = nil) {
            let surf = Prim.cylinder(radius: rad, height: h, bevel: min(0.002, rad * 0.2), segments: segs, bevelSegments: 1, material: mat)
            if let part { rig.add(surf, Xform(translation: c, rotation: rot), to: part) } else { rig.base[0].add(surf, Xform(translation: c, rotation: rot)) }
        }
        func tubeAdd(_ pts: [V3], _ rad: Float, _ mat: MaterialKey, sides: Int = 5, to part: String? = nil) {
            let surf = Prim.tube(pts, radii: Array(repeating: rad, count: pts.count), sides: sides, seamTile: 0.1, material: mat)
            if let part { rig.add(surf, to: part) } else { rig.base[0].add(surf, .identity) }
        }
        let faceUp = simd_quatf(degrees: 90, axis: V3(1, 0, 0))

        // Frame: base plate, roof, four posts, side skins with louvers and cable ports.
        box(V3(w, 0.03, d), V3(0, baseY - 0.015, 0), frame, r: 0.006, seg: 2)
        box(V3(w, 0.03, d), V3(0, topY - 0.015, 0), frame, r: 0.006, seg: 2)
        for sx: Float in [-1, 1] {
            for sz: Float in [-1, 1] {
                box(V3(0.035, topY - baseY - 0.06, 0.035), V3(sx * (hx - 0.0175), (topY + baseY) / 2, sz * (hz - 0.0175 - 0.03)), frame, r: 0.004, seg: 2)
            }
            box(V3(0.003, topY - baseY - 0.06, d - 0.08), V3(sx * (hx - 0.0015), (topY + baseY) / 2, 0), frame, r: 0.001)
            for sz: Float in [-0.2, 0.25] {
                box(V3(0.002, topY - baseY - 0.2, 0.006), V3(sx * (hx + 0.0005), (topY + baseY) / 2, sz), "metal.powdercoat:2A2C30", r: 0.0006)
            }
            box(V3(0.002, 0.05, 0.09), V3(sx * (hx + 0.0006), 1.9, 0.05), "plastic.matte:C8C8C6", r: 0.0006)
            for i in 0..<6 {
                box(V3(0.002, 0.010, 0.22), V3(sx * (hx + 0.0004), 0.55 + Float(i) * 0.05, 0.0), "plastic.matte:050506", r: 0.0006)
            }
            for i in 0..<1 {
                m_grommet(sx, 1.6 + Float(i) * 0.12)
            }
        }
        func m_grommet(_ sx: Float, _ y: Float) {
            rig.base[0].add(Prim.torus(major: 0.016, minor: 0.003, segments: 10, sides: 4, material: "rubber.seal"),
                            Xform(translation: V3(sx * (hx + 0.001), y, -0.35), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        }
        // Roof cable entry and label strip.
        box(V3(0.30, 0.004, 0.16), V3(0.10, topY + 0.002, -0.40), alu, r: 0.001)
        box(V3(0.24, 0.032, 0.002), V3(0, topY - 0.07, zFront - 0.004), alu, r: 0.001)
        for i in 0..<5 {
            box(V3(0.006, 0.006, 0.002), V3(-0.09 + Float(i) * 0.014, topY - 0.14, zFront - 0.004), i == 4 ? "emissive.led-red" : "emissive.led-green", r: 0.0003)
        }

        // Tray filler keeps gaps dark; rear plate closes the stack.
        box(V3(w - 0.07, stackTop - y0, zFace + 0.30), V3(0, (stackTop + y0) / 2, (zFace - 0.30) / 2), matte, r: 0.001)

        // U rails with a tick every 44.45 mm, longer every fifth U.
        for (name, sx) in [("u-rail-left", Float(-1)), ("u-rail-right", Float(1))] {
            rig.part(name, pivot: V3(sx * 0.257, (y0 + stackTop) / 2, zFace), joint: .fixed)
            box(V3(0.014, stackTop - y0, 0.004), V3(sx * 0.257, (y0 + stackTop) / 2, zFace - 0.002), "metal.galvanized", r: 0.0006, to: name)
            for u in 0...stackU {
                let long = u % 5 == 0
                let tw: Float = long ? 0.009 : 0.005
                box(V3(tw, 0.0012, 0.0012), V3(sx * (0.257 + (sx > 0 ? -1 : 1) * (0.007 - tw / 2)), y0 + Float(u) * pitch, zFace + 0.0006), long ? "plastic.matte:F2F2F0" : "plastic.matte:C8C8C6", r: 0.0003, to: name)
            }
        }

        // Compute tray slots: two banks of nine 1U trays, anchored at real U heights.
        func slotU(_ n: Int) -> Int { n < 9 ? n : n + 6 }
        let slotCount = min(trayCount, 18)
        for n in 0..<slotCount {
            let name = String(format: "tray-slot-%02d", n + 1)
            let y = uy(slotU(n))
            var r = rng.fork(n)
            rig.part(name, pivot: V3(0, y, zFace), joint: .slide(axis: V3(0, 0, 1), 0...0.5, duration: 0.8))
            box(V3(0.50, pitch - 0.003, 0.012), V3(0, y, zFace - 0.006), alu, r: 0.002, to: name)
            // Vent field and fins.
            box(V3(0.24, 0.024, 0.0016), V3(0.0, y - 0.002, zFace + 0.0008), "plastic.matte:060607", r: 0.0004, to: name)
            for k in 0..<3 {
                box(V3(0.0018, 0.022, 0.0022), V3(-0.07 + Float(k) * 0.07, y - 0.002, zFace + 0.0012), alu, r: 0.0003, to: name)
            }
            for sx: Float in [-1, 1] {
                let h0 = sx * 0.215
                let p = [V3(h0 - 0.016, y + 0.006, zFace), V3(h0 - 0.016, y + 0.006, zFace + 0.014), V3(h0 + 0.016, y + 0.006, zFace + 0.014), V3(h0 + 0.016, y + 0.006, zFace)]
                rig.add(Prim.tube(p, radii: [0.0028, 0.0028, 0.0028, 0.0028], sides: 3, seamTile: 0.1, material: alu), to: name)
            }
            for k in 0..<3 {
                let green = !(k == 2 && r.chance(0.08))
                box(V3(0.004, 0.004, 0.002), V3(-0.19 + Float(k) * 0.011, y - 0.011, zFace + 0.001), green ? "emissive.led-green" : "emissive.led-red", r: 0.0003, to: name)
            }
        }
        // Fixed trays: switch trays, power shelves, blanks, with LED rows.
        func fixedFace(_ u: Int, units: Int, mat: MaterialKey, leds: Int) {
            let h = Float(units) * pitch
            let y = y0 + Float(u) * pitch + h / 2
            box(V3(0.50, h - 0.003, 0.012), V3(0, y, zFace - 0.006), mat, r: 0.002)
            for k in 0..<leds {
                box(V3(0.005, 0.004, 0.002), V3(-0.2 + Float(k) * 0.022, y - h / 2 + 0.012, zFace + 0.001), k % 9 == 8 ? "emissive.led-red" : "emissive.led-green", r: 0.0003)
            }
            for sx: Float in [-1, 1] {
                box(V3(0.008, 0.016, 0.008), V3(sx * 0.225, y + h / 2 - 0.012, zFace + 0.004), steel, r: 0.0012)
            }
        }
        for n in 0..<9 { fixedFace(24 + n, units: 1, mat: alu, leds: 5) }
        for n in 0..<3 { fixedFace(9 + n * 2, units: 2, mat: "plastic.matte:15161A", leds: 3) }
        for n in 0..<3 { fixedFace(33 + n * 2, units: 2, mat: "plastic.matte:15161A", leds: 3) }
        fixedFace(39, units: 3, mat: "plastic.matte:0D0E10", leds: 0)

        // Top-of-rack switch, 1U with a row of 32 ports.
        rig.part("tor-switch", pivot: V3(0, y0 + Float(42) * pitch + pitch / 2, zFace), joint: .fixed)
        do {
            let y = uy(42)
            box(V3(0.50, pitch - 0.003, 0.016), V3(0, y, zFace - 0.008), "plastic.matte:1B1D21", r: 0.002, to: "tor-switch")
            for k in 0..<32 {
                box(V3(0.0115, 0.009, 0.004), V3(-0.2 + Float(k) * 0.0129, y + 0.006, zFace + 0.0005), "plastic.matte:020203", r: 0.0006, to: "tor-switch")
                if k % 2 == 0 { box(V3(0.0035, 0.0018, 0.0012), V3(-0.2 + Float(k) * 0.0129, y - 0.0045, zFace + 0.0006), k % 7 == 3 ? "emissive.led-red" : "emissive.led-green", r: 0.0002, to: "tor-switch") }
            }
            box(V3(0.06, 0.012, 0.002), V3(0.2, y - 0.008, zFace + 0.001), alu, r: 0.0005, to: "tor-switch")
        }

        // Rear: plate, PDUs, manifolds, hoses, busbar, cable managers.
        let zBack = zFace - 0.30
        let rz = zBack - 0.015
        box(V3(0.50, stackTop - y0, 0.006), V3(0, (stackTop + y0) / 2, rz), alu, r: 0.001)

        // PDUs: vertical 0U strips on the rear posts, outlet rows facing inward.
        let pduLo: Float = 0.36, pduHi: Float = 2.10
        for (name, px, face) in [("pdu-a", Float(-0.27), Float(1)), ("pdu-b", Float(0.26), Float(-1))] {
            let c = V3(px, (pduLo + pduHi) / 2, -0.555)
            rig.part(name, pivot: c, joint: .fixed)
            box(V3(0.04, pduHi - pduLo, 0.04), c, "metal.powdercoat:1E2024", r: 0.004, seg: 2, to: name)
            box(V3(0.046, 0.12, 0.046), V3(px, pduHi + 0.04, -0.555), "plastic.matte:1A1B1E", r: 0.004, to: name)
            cyl(0.0035, 0.012, V3(px, pduHi + 0.108, -0.555), "emissive.led-green", segs: 6, to: name)
            for k in 0..<18 {
                let y = pduLo + 0.05 + Float(k) * 0.095
                box(V3(0.004, 0.034, 0.024), V3(px + face * 0.0205, y, -0.555), "plastic.matte:020203", r: 0.0008, to: name)
            }
            tubeAdd([V3(px, pduLo, -0.555), V3(px, pduLo - 0.08, -0.56), V3(px + face * 0.04, 0.2, -0.57), V3(px + face * 0.1, 0.16, -0.5)], 0.011, "plastic.matte:101112", sides: 6, to: name)
        }

        // Coolant manifolds: vertical headers with quick-disconnect hoses to each slot bank.
        let supplyX: Float = -0.235, returnX: Float = -0.175, pipeZ = zRear + 0.12
        let manLen = stackTop - y0 + 0.20
        for (name, px, mat, hex) in [("manifold-supply", supplyX, supplyMaterial, "2A6FD0"), ("manifold-return", returnX, returnMaterial, "C8402C")] {
            rig.part(name, pivot: V3(px, y0 - 0.12 + manLen / 2, pipeZ), joint: .fixed)
            cyl(0.02, manLen, V3(px, y0 - 0.12, pipeZ), "metal.powdercoat:" + hex, segs: 14, to: name)
            for yy in stride(from: y0 + 0.05, to: stackTop + 0.1, by: 0.45) {
                cyl(0.0235, 0.03, V3(px, yy, pipeZ), steel, segs: 14, to: name)
            }
            cyl(0.026, 0.012, V3(px, y0 - 0.12 + manLen, pipeZ), steel, segs: 14, to: name)
            for t in stride(from: 0, to: slotCount, by: 3) {
                let y = uy(slotU(t))
                let isSupply = px == supplyX
                let end = V3(-0.14 + (isSupply ? 0 : 0.05) + (isSupply ? 0 : 0.04), y + (isSupply ? 0.008 : -0.008), rz)
                let src = V3(px, y, pipeZ)
                let wob = Float(t % 4) * 0.003
                let pts = catmull([src + V3(0, 0, 0.02), V3(px + 0.04 + wob, y + 0.01, pipeZ + 0.06), V3(end.x - 0.01, end.y + 0.02, end.z - 0.06 - wob), end], per: 1)
                tubeAdd(pts, 0.0085, mat, to: name)
                box(V3(0.022, 0.022, 0.022), end + V3(0, 0, 0.009), steel, r: 0.003, to: name)
            }
        }

        // 800 V busbar: two flat copper bars with insulated spacers and tap blocks.
        for bx in [Float(0.05), 0.10] {
            box(V3(0.035, stackTop - y0 + 0.2, 0.008), V3(bx, (stackTop + y0) / 2 + 0.05, zRear + 0.06), "metal.tinned-copper", r: 0.001)
            box(V3(0.04, stackTop - y0 + 0.1, 0.014), V3(bx, (stackTop + y0) / 2 + 0.05, zRear + 0.06 - 0.011), "rubber.insulating-orange", r: 0.002)
        }
        for yy in stride(from: y0 + 0.02, to: stackTop + 0.1, by: 0.3) {
            box(V3(0.11, 0.03, 0.03), V3(0.075, yy, zRear + 0.06), "rubber.insulating-orange", r: 0.003)
        }
        for t in stride(from: 0, to: slotCount, by: 3) {
            let y = uy(slotU(t))
            box(V3(0.09, 0.012, 0.004), V3(0.075, y, zRear + 0.09), "metal.tinned-copper", r: 0.0008)
            box(V3(0.04, 0.014, 0.018), V3(0.12, y, zRear + 0.11), "plastic.matte:E06A10", r: 0.002)
        }

        // Cable managers: finger ducts down both sides of the rear bay.
        for (name, cx) in [("cable-manager-left", Float(-0.10)), ("cable-manager-right", Float(0.19))] {
            let hh = stackTop - y0 - 0.3
            let cy = y0 + 0.15 + hh / 2
            rig.part(name, pivot: V3(cx, cy, zRear + 0.03), joint: .fixed)
            box(V3(0.05, hh, 0.003), V3(cx, cy, zRear + 0.012), "metal.powdercoat:1A1C1F", r: 0.0008, to: name)
            for yy in stride(from: y0 + 0.17, to: y0 + 0.15 + hh, by: 0.1334) {
                box(V3(0.05, 0.004, 0.034), V3(cx, yy, zRear + 0.03), "metal.powdercoat:1A1C1F", r: 0.001, to: name)
            }
        }

        // Cable bundles with ties, dropping from the roof entry through the right cable manager.
        for (i, off) in [Float(0), 0.012, -0.012].enumerated() {
            let top = V3(0.19 + off, topY, -0.40 + off)
            let pts = catmull([top, V3(0.19 + off, topY - 0.1, zRear + 0.05), V3(0.19 + off, 1.4, zRear + 0.045), V3(0.19 + off, 0.5, zRear + 0.05 + Float(i) * 0.004), V3(0.19 + off, y0 + 0.05, rz)], per: 3)
            tubeAdd(pts, 0.0095, i == 1 ? "rubber.tubing:C9C30D" : "plastic.matte:101112")
        }
        for yy in stride(from: Float(0.45), to: 2.3, by: 0.24) {
            rig.base[0].add(Prim.torus(major: 0.026, minor: 0.0028, segments: 8, sides: 3, material: "plastic.matte:2A2C30"),
                            Xform(translation: V3(0.19, yy, zRear + 0.048)))
        }

        // Grounding lug: tinned barrel lug bolted to the left rear post with a green-yellow bond strap.
        rig.part("grounding-lug", pivot: V3(-0.255, 0.30, zRear - 0.002), joint: .fixed)
        box(V3(0.034, 0.05, 0.003), V3(-0.255, 0.30, zRear - 0.0005 + 0.0), "metal.tinned-copper", r: 0.0008, to: "grounding-lug")
        cyl(0.007, 0.03, V3(-0.255, 0.285, zRear + 0.004), "metal.tinned-copper", rot: faceUp, segs: 10, to: "grounding-lug")
        for dy: Float in [0.015, -0.015] {
            cyl(0.004, 0.004, V3(-0.255, 0.31 + dy, zRear + 0.003), steel, rot: faceUp, segs: 6, to: "grounding-lug")
        }
        tubeAdd(catmull([V3(-0.255, 0.285, zRear + 0.02), V3(-0.25, 0.22, zRear + 0.03), V3(-0.23, baseY + 0.02, zRear + 0.05)], per: 3), 0.005, "rubber.tubing:B8C20D", sides: 6, to: "grounding-lug")

        // Doors: perforated panel inside a powder-coated frame; hinged on opposite sides.
        func door(_ name: String, hinge: Float, zPlane: Float) {
            let dw = w - 0.03, dh = topY - baseY - 0.03
            let dirX = -hinge, off = dirX * dw / 2
            let pivot = V3(hinge * (hx - 0.005), baseY + 0.015, zPlane)
            rig.part(name, pivot: pivot, joint: .hinge(axis: .up, -110...0, duration: 1.1))
            func put(_ s: Surface, _ t: V3, _ rot: simd_quatf = .identity) {
                rig.add(s, Xform(translation: pivot + t, rotation: rot), to: name)
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
            // Edge scuffs at the latch side.
            for (i, sy) in [Float(0.05), 0.31, 0.62].enumerated() {
                put(rb(V3(0.004 + Float(i) * 0.002, 0.03 + Float(i) * 0.01, 0.0012), radius: 0.0004, bevelSegments: 1, material: "metal.aluminum"), V3(dirX * (dw - 0.012), sy, zPlane > 0 ? 0.0134 : -0.0134))
            }
            let outward: Float = zPlane > 0 ? 1 : -1
            let hr = simd_quatf(degrees: zPlane > 0 ? 0 : 180, axis: V3(0, 1, 0)) * simd_quatf(degrees: 90, axis: V3(0, 0, 1))
            put(barHandle(length: 0.16, standoff: 0.03, radius: 0.007, overhang: 0.01, material: alu),
                V3(dirX * (dw - 0.015), dh * 0.5, 0.013 * outward), hr)
        }
        door("rack-front-door", hinge: -1, zPlane: hz - 0.012)
        door("rack-rear-door", hinge: 1, zPlane: -hz + 0.012)

        // Casters at the corners, leveling feet inboard.
        for sx: Float in [-1, 1] {
            for sz: Float in [-1, 1] {
                let cp = V3(sx * 0.24, 0, sz * 0.52)
                box(V3(0.07, 0.004, 0.07), cp + V3(0, baseY - 0.002, 0), steel, r: 0.001)
                cyl(0.012, 0.02, cp + V3(0, baseY - 0.024, 0), steel)
                for side: Float in [-1, 1] {
                    box(V3(0.003, baseY - 0.03, 0.04), cp + V3(side * 0.02, (baseY - 0.03) / 2 + 0.02, 0), steel, r: 0.0006)
                }
                cyl(0.04, 0.032, cp + V3(0.016, 0.04, 0), "rubber.tire", rot: simd_quatf(degrees: 90, axis: V3(0, 0, 1)), segs: 12)
                let fp = V3(sx * 0.26, 0, sz * 0.62)
                cyl(0.022, 0.012, fp, "metal.cast-iron")
                cyl(0.008, baseY - 0.012, fp + V3(0, 0.012, 0), steel, segs: 6)
            }
        }
        groundAO(&rig, height: 0.1, floor: 0.55)
        let service: [String: Float] = ["rack-front-door": -(frontDoorAngle + 12), "rack-rear-door": -(rearDoorAngle + 30)]
        rig.states = [RigState("closed", ["rack-front-door": -frontDoorAngle, "rack-rear-door": -rearDoorAngle]), RigState("service", service),
                      RigState("open", ["rack-front-door": -100, "rack-rear-door": -100, "tray-slot-05": 0.26])]
        rig.defaultState = "closed"
        return rig
    }
}
