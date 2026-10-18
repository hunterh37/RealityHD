import simd
import Foundation

/// GPU compute tray: Clean new hardware, satin brushed aluminium, green PCB visible with lid lifted.. Parts: chassis, lid, slide rails, GPU modules, cold plates, copper tubing, quick disconnects, front handles, PCB, DIMMs.
public struct ComputeTrayGpu: RealAsset {
    public static let id = "compute-tray-gpu"
    public static let summary = "2U liquid-cooled GPU compute tray: brushed aluminium chassis, four GPU cold plates with copper tubing to rear blind-mate quick disconnects, PCB, fan-less, removable lid and slide rails."
    public static let tags = ["prop"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width incl. slide rails, y height, z depth). Front faces +Z.
    public var size = V3(0.44, 0.09, 0.9)
    /// Chassis and lid material key.
    public var chassis: MaterialKey = "metal.aluminum-brushed"
    /// Cold plate material key.
    public var copper: MaterialKey = "copper.polished"
    /// Supply (cold) braided line tint.
    public var supply: MaterialKey = "rubber.tubing:2A6FD0"
    /// Return (warm) braided line tint.
    public var returnLine: MaterialKey = "rubber.tubing:C8402C"
    /// Distance the lid is slid rearward off the GPU bay (m).
    public var lidSlide: Float = 0
    public init() {}

    /// Low-poly bolt head: 6-sided prism, axis along `normal`.
    func hexBolt(_ m: inout Model, at p: V3, normal n: V3, size: Float, material: MaterialKey) {
        m.add(Prim.cylinder(radius: size * 0.55, height: size * 0.5, bevel: 0, segments: 6, bevelSegments: 1, material: material),
              Xform(translation: p, rotation: facing(n)))
    }

    func rb(_ s: V3, _ r: Float, _ mat: MaterialKey, seg: Int = 1) -> Surface {
        let b = r < 0.0006 ? 0 : min(r, min(s.x, min(s.y, s.z)) * 0.45)
        return Prim.extrude(Shape2D.rect(s.x, s.y), depth: s.z, bevel: b, bevelSegments: seg, material: mat)
    }

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let alu = chassis
        let steel: MaterialKey = "metal.stainless"
        let nickel: MaterialKey = "metal.nickel"
        let black: MaterialKey = "plastic.matte:0B0C0E"
        let pcb: MaterialKey = "plastic.pcb"
        let H: Float = 0.089
        let bodyW: Float = size.x - 0.012          // chassis without rail protrusion
        let hx = bodyW / 2
        let zF: Float = 0.43, zR: Float = -0.43     // front bezel plane, rear wall plane
        func box(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.0008, seg: Int = 1) {
            m.add(rb(s, r, mat, seg: seg), Xform(translation: c))
        }

        // Chassis tub: floor, side walls, rear wall.
        box(V3(bodyW, 0.002, zF - zR), V3(0, 0.001, (zF + zR) / 2), alu, r: 0.0007)
        for sx: Float in [-1, 1] {
            box(V3(0.0016, H, zF - zR), V3(sx * (hx - 0.0008), H / 2, (zF + zR) / 2), alu, r: 0.0007)
            // folded top flange
            box(V3(0.008, 0.0016, zF - zR - 0.02), V3(sx * (hx - 0.004), H - 0.0008, (zF + zR) / 2), alu, r: 0.0006)
        }
        box(V3(bodyW, H, 0.002), V3(0, H / 2, zR - 0.001), alu, r: 0.0007)

        // Slide rails: outer channel, inner bearing strip, front and rear brackets.
        for sx: Float in [-1, 1] {
            let rx = sx * (hx + 0.003)
            box(V3(0.006, 0.026, 0.62), V3(rx, 0.0445, -0.06), "metal.stainless", r: 0.001)
            box(V3(0.0012, 0.008, 0.60), V3(sx * (hx + 0.0066), 0.0445, -0.06), "plastic.matte:15161A", r: 0.0004)
            for z: Float in [-0.35, 0.22] {
                box(V3(0.008, 0.032, 0.012), V3(sx * (hx + 0.002), 0.0445, z), steel, r: 0.0008)
                hexBolt(&m, at: V3(sx * (hx + 0.0062), 0.0445, z), normal: V3(sx, 0, 0), size: 0.003, material: nickel)
            }
        }

        // Main board.
        let pcbY: Float = 0.006
        box(V3(bodyW - 0.012, 0.0016, 0.80), V3(0, pcbY, 0.0), pcb, r: 0.0004)
        for sx: Float in [-1, 1] { for z: Float in [-0.38, -0.12, 0.12, 0.38] {
            m.add(Prim.cylinder(radius: 0.0035, height: 0.004, bevel: 0, segments: 8, bevelSegments: 1, material: nickel),
                  Xform(translation: V3(sx * (hx - 0.01), 0.002, z)))
        } }

        // DIMM banks.
        for sx: Float in [-1, 1] {
            let cx = sx * 0.125
            box(V3(0.136, 0.006, 0.07), V3(cx, pcbY + 0.0038, 0.31), black, r: 0.0008)   // socket block
            for i in 0..<6 {
                let z = 0.282 + Float(i) * 0.0105
                box(V3(0.133, 0.031, 0.0013), V3(cx, pcbY + 0.0008 + 0.0155 + 0.003, z), pcb, r: 0)
                for k in 0..<2 {
                    box(V3(0.018, 0.012, 0.0009), V3(cx - 0.03 + Float(k) * 0.06, pcbY + 0.026, z + 0.0011), black, r: 0.0003)
                }
            }        }

        // Centre CPU cold plate and retimer area between DIMM banks.
        box(V3(0.075, 0.012, 0.075), V3(0, pcbY + 0.012, 0.31), copper, r: 0.002)
        box(V3(0.055, 0.004, 0.055), V3(0, pcbY + 0.020, 0.31), nickel, r: 0.0012)

        // GPU modules: 2 x 2.
        let plateW: Float = 0.11, plateD: Float = 0.15
        let gx: [Float] = [-0.1, 0.1]
        let gz: [Float] = [0.14, -0.10]
        let topY: Float = 0.040
        for (zi, z) in gz.enumerated() {
            let ps: Float = zi == 0 ? -1 : 1      // ports face the middle gap
            for x in gx {
                // carrier board + package
                box(V3(0.125, 0.0016, 0.17), V3(x, 0.0108, z), pcb, r: 0.0004)
                box(V3(0.114, 0.006, 0.154), V3(x, 0.0151, z), "plastic.matte:1A1B1E", r: 0.001)
                // VRM rows: chokes and polymer caps either side
                for side: Float in [-1, 1] {
                    for k in 0..<4 {
                        let zz = z - 0.054 + Float(k) * 0.036
                        box(V3(0.009, 0.0075, 0.0085), V3(x + side * 0.0595, 0.0108 + 0.0045, zz), "metal.anodized-black", r: 0)
                        if side > 0 { m.add(Prim.cylinder(radius: 0.0032, height: 0.007, bevel: 0, segments: 8, bevelSegments: 1, material: "metal.aluminum-brushed"),
                              Xform(translation: V3(x + side * 0.0525 + side * 0.012 - side * 0.002, 0.0116, zz + 0.0))) }
                    }
                }
                // cold plate: copper base and top block with machined step
                box(V3(plateW, 0.004, plateD), V3(x, 0.0215 + 0.002 - 0.0004, z), copper, r: 0.0012)
                box(V3(plateW - 0.012, topY - 0.0255 - 0.004, plateD - 0.012), V3(x, 0.0255 + (topY - 0.0255) / 2 + 0.002 - 0.0004, z), "metal.copper", r: 0.002)
                box(V3(plateW - 0.03, 0.002, plateD - 0.03), V3(x, topY + 0.001 + 0.0016, z), "metal.copper", r: 0.0008)
                // four captive screws
                for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
                    let p = V3(x + sx * (plateW / 2 - 0.0045), 0.0255 + 0.0016, z + sz * (plateD / 2 - 0.0045))
                    m.add(Prim.cylinder(radius: 0.0028, height: 0.003, bevel: 0, segments: 8, bevelSegments: 1, material: nickel), Xform(translation: p))
                } }
                // ports: inlet and outlet barbs on the gap-facing end
                for (pi, cap) in [(Float(-1), supply), (Float(1), returnLine)] {
                    let p = V3(x + pi * 0.03, topY + 0.0016, z + ps * (plateD / 2 - 0.016))
                    m.add(Prim.cylinder(radius: 0.0058, height: 0.0045, bevel: 0.0008, segments: 10, bevelSegments: 1, material: nickel), Xform(translation: p - V3(0, 0.0025, 0)))
                    m.add(Prim.cylinder(radius: 0.0044, height: 0.006, bevel: 0, segments: 10, bevelSegments: 1, material: cap), Xform(translation: p + V3(0, 0.0015, 0)))
                }
                // braided branches to the headers (supply y 0.066, return y 0.052, z = 0.02)
                for (pi, isSupply) in [(Float(-1), true), (Float(1), false)] {
                    let px = x + pi * 0.03
                    let pz = z + ps * (plateD / 2 - 0.016)
                    let hy: Float = isSupply ? 0.066 : 0.052
                    let hz: Float = isSupply ? 0.04 : 0.0
                    let midZ = (pz + hz) / 2
                    let pts = catmull([V3(px, topY + 0.0045, pz), V3(px, topY + 0.014, pz + ps * 0.004), V3(px, hy - 0.004, midZ), V3(px, hy, hz)], per: 3)
                    m.add(Prim.tube(pts, radii: Array(repeating: 0.0048, count: pts.count), sides: 6, seamTile: 0.012,
                                    material: "metal.tinned-copper", capEnd: false))
                    for e in [pts.first!, pts.last!] {
                        m.add(Prim.cylinder(radius: 0.0062, height: 0.007, bevel: 0.001, segments: 10, bevelSegments: 1, material: isSupply ? supply : returnLine),
                              Xform(translation: e - V3(0, e == pts.first! ? 0.002 : 0.0035, 0)))
                    }
                }
            }
        }

        // Headers along X plus trunks to the rear quick-disconnects.
        for (isSupply, hy, hz, tx) in [(true, Float(0.066), Float(0.04), Float(-0.04)), (false, Float(0.052), Float(0.0), Float(0.04))] {
            let mat: MaterialKey = isSupply ? supply : returnLine
            m.add(Prim.tube([V3(-0.185, hy, hz), V3(0.185, hy, hz)], radii: [0.0058, 0.0058], sides: 8, seamTile: 0.02, material: "metal.tinned-copper"))
            for sx: Float in [-1, 1] {
                m.add(Prim.cylinder(radius: 0.0072, height: 0.006, bevel: 0.001, segments: 10, bevelSegments: 1, material: mat),
                      Xform(translation: V3(sx * 0.185, hy, hz), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
            }
            let tp = catmull([V3(tx, hy, hz), V3(tx, hy, hz - 0.03), V3(tx, hy - 0.014, -0.2), V3(tx, 0.034, -0.36), V3(tx, 0.034, -0.41)], per: 4)
            m.add(Prim.tube(tp, radii: Array(repeating: 0.0058, count: tp.count), sides: 8, seamTile: 0.015, material: "metal.tinned-copper"))
            // blind-mate quick disconnect at the rear wall
            let qz: Float = zR - 0.002
            m.add(Prim.cylinder(radius: 0.0125, height: 0.012, bevel: 0.002, segments: 10, bevelSegments: 1, material: nickel),
                  Xform(translation: V3(tx, 0.034, qz + 0.0), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
            m.add(Prim.cylinder(radius: 0.0155, height: 0.004, bevel: 0.001, segments: 10, bevelSegments: 1, material: mat),
                  Xform(translation: V3(tx, 0.034, qz - 0.003), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
            m.add(Prim.cylinder(radius: 0.0075, height: 0.002, bevel: 0.0005, segments: 10, bevelSegments: 1, material: black),
                  Xform(translation: V3(tx, 0.034, qz - 0.012), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
            // collar ring and coupling
            m.add(Prim.torus(major: 0.0105, minor: 0.0014, segments: 12, sides: 5, material: nickel),
                  Xform(translation: V3(tx, 0.034, qz - 0.005), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            m.add(Prim.cylinder(radius: 0.0100, height: 0.0035, bevel: 0.0006, segments: 10, bevelSegments: 1, material: nickel),
                  Xform(translation: V3(tx, 0.034, zR + 0.0), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
        }
        // rear power blind-mate (800 VDC) and signal connector
        box(V3(0.05, 0.03, 0.012), V3(0.115, 0.034, zR - 0.006), black, r: 0.0015)
        for k in 0..<2 { box(V3(0.016, 0.018, 0.004), V3(0.103 + Float(k) * 0.024, 0.034, zR - 0.013), "metal.copper", r: 0.001) }
        box(V3(0.05, 0.03, 0.012), V3(-0.115, 0.034, zR - 0.006), black, r: 0.0015)
        for k in 0..<6 { box(V3(0.004, 0.010, 0.003), V3(-0.133 + Float(k) * 0.0052, 0.034, zR - 0.0135), "metal.copper", r: 0.0003) }

        // Lid: slid over the rear section only so the GPU bay stays visible.
        let lidD: Float = 0.2
        let lz = zR + lidD / 2 + 0.004 - lidSlide
        box(V3(bodyW - 0.004, 0.0016, lidD), V3(0, H + 0.0008 - 0.0016, lz), alu, r: 0.0006)
        for sx: Float in [-1, 1] {
            box(V3(0.0016, 0.012, lidD), V3(sx * (hx - 0.0026), H - 0.0016 - 0.004, lz), alu, r: 0.0005)
            for k in 0..<1 { hexBolt(&m, at: V3(sx * (hx - 0.018), H, lz - 0.07 + Float(k) * 0.14), normal: V3(0, 1, 0), size: 0.0036, material: nickel) }
        }
        // vent slots in the lid
        for k in 0..<7 { box(V3(0.0035, 0.0003, 0.06), V3(-0.09 + Float(k) * 0.03, H - 0.0006, lz + 0.01), black, r: 0.0001) }
        // lift tab
        box(V3(0.045, 0.006, 0.012), V3(0, H + 0.0005, lz + lidD / 2 - 0.012), alu, r: 0.0015)

        // Front bezel.
        box(V3(bodyW, H, 0.004), V3(0, H / 2, zF + 0.002), alu, r: 0.001)
        // vent slot field
        for r in 0..<4 { for c in 0..<13 {
            let x = -0.168 + Float(c) * 0.01
            box(V3(0.0032, 0.0085, 0.0006), V3(x, 0.016 + Float(r) * 0.019, zF + 0.0043), black, r: 0)
        } }
        // 2 x 4 OSFP cages
        for r in 0..<2 { for c in 0..<4 {
            let p = V3(0.045 + Float(c) * 0.034, 0.063 - Float(r) * 0.022, zF + 0.0045)
            box(V3(0.0275, 0.0135, 0.014), p + V3(0, 0, 0.0035), steel, r: 0.0006)
            box(V3(0.0225, 0.0085, 0.001), p + V3(0, 0, 0.0108), black, r: 0)
            box(V3(0.0050, 0.0014, 0.0008), p + V3(0.0, -0.0049, 0.0114), "metal.copper", r: 0)
            box(V3(0.0035, 0.0014, 0.0005), p + V3(0.010, 0.0075, 0.0105), "emissive.led-green", r: 0.0001)
        } }
        // BMC ports, USB-C, buttons, status LEDs
        for k in 0..<2 {
            box(V3(0.016, 0.0135, 0.012), V3(0.05 + Float(k) * 0.022, 0.0165, zF + 0.0085), steel, r: 0.0005)
            box(V3(0.0125, 0.0085, 0.001), V3(0.05 + Float(k) * 0.022, 0.0165, zF + 0.0145), black, r: 0)
        }
        box(V3(0.009, 0.0035, 0.006), V3(0.102, 0.0165, zF + 0.007), steel, r: 0.0008)
        for (k, led) in ["emissive.led-green", "emissive.signal-white", "emissive.signal-orange"].enumerated() {
            box(V3(0.0035, 0.0035, 0.0008), V3(0.132 + Float(k) * 0.011, 0.0165, zF + 0.0044), led, r: 0.0001)
        }
        m.add(Prim.cylinder(radius: 0.0045, height: 0.0025, bevel: 0, segments: 10, bevelSegments: 1, material: nickel),
              Xform(translation: V3(0.135, 0.032, zF + 0.0045), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        // service tag pull-tab
        box(V3(0.040, 0.0016, 0.012), V3(0.0, 0.0795, zF + 0.012), "plastic.matte:D8D8D4", r: 0.0004)
        // Handles, vertical bars at both ends.
        for sx: Float in [-1, 1] {
            let hxp = sx * (hx - 0.012)
            m.add(Prim.cylinder(radius: 0.0045, height: 0.062, bevel: 0.002, segments: 10, bevelSegments: 1, material: alu),
                  Xform(translation: V3(hxp, H / 2 - 0.031, zF + 0.02)))
            for dy: Float in [-0.026, 0.026] {
                m.add(Prim.cylinder(radius: 0.0036, height: 0.016, bevel: 0, segments: 8, bevelSegments: 1, material: alu),
                      Xform(translation: V3(hxp, H / 2 + dy, zF + 0.004), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            }
            // thumbscrew
            m.add(Prim.cylinder(radius: 0.0055, height: 0.007, bevel: 0.0012, segments: 10, bevelSegments: 1, material: nickel),
                  Xform(translation: V3(sx * (hx - 0.012), 0.014, zF + 0.0045), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }
        // Story detail: asset plate.
        box(V3(0.030, 0.0006, 0.010), V3(-0.12, 0.0752, 0.0), "metal.stainless", r: 0.0001)

        groundAO(&m)
        return LODModel(m)
    }
}
