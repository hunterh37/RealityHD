import simd
import Foundation

/// 22 m 4-6-2 steam locomotive with six-wheel tender. Lofted boiler (73 stations, 48 radial points) in green with black smokebox,
/// lagging bands, brass steam dome, sand dome and safety valve, copper-capped chimney, domed smokebox door, headlamp with spot light,
/// spoked 2 m drivers with counterweights and crank pins, coupling and connecting rods, outside cylinders, running boards with handrails,
/// cab with window glass and a firebox backhead, whistle, and a tender with coal bunker and a mound of coal. Front faces +Z, wheels
/// sit on y = 0 (railhead), centered on X and Z.
/// Joints (all values 0...1): `drive` (drivers, bogie, trailing and tender wheels turn; drivers one turn per unit; coupling and
/// connecting rods follow the crank pins through counter-rotating mimic parts), `whistle` (valve lifts 3 cm), `door` (firebox door swings
/// open 110 degrees and the fire glows, with an orange point light).
public struct SteamLocomotive: RealArticulated {
    public static let id = "steam-locomotive"
    public static let summary = "Steam locomotive, 22 m 4-6-2 with tender: lofted boiler, brass domes, spoked drivers with rods, cab, headlamp, whistle, firebox door, coal load."
    public static let tags = ["prop", "vehicle", "rail", "locomotive", "steam", "outdoor", "articulated"]
    public static let budget = 30_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 52, elevation: 10, distance: 1.0, studio: true)

    /// Boiler, cab, tank and wheel paint (British green).
    public var paint: MaterialKey = "metal.painted:3A7D4B"
    /// Smokebox, chimney, frames, cylinders, running boards.
    public var black: MaterialKey = "metal.painted:16181B"
    /// Cylinders, steam chests and frame plates (oily cast iron).
    public var worn: MaterialKey = "metal.cast-iron-worn"
    /// Buffer beams.
    public var red: MaterialKey = "metal.painted:9E1B20"
    /// Rods, tires and fittings.
    public var steel: MaterialKey = "metal.steel"
    /// Polished rods and handwheel.
    public var bright: MaterialKey = "metal.stainless"
    /// Domes, whistle, plates, handrails.
    public var brass: MaterialKey = "metal.brass"
    /// Handrails, hatches and plates handled every day.
    public var brassAged: MaterialKey = "metal.brass-aged"
    /// Smokebox, door and chimney (soot and heat worn).
    public var sooty: MaterialKey = "metal.powdercoat-worn:2A2A2C"
    /// Soot streak band behind the chimney.
    public var soot: MaterialKey = "metal.rust-grime"
    /// Chimney cap.
    public var copper: MaterialKey = "metal.copper"
    /// Cab window glass.
    public var glass: MaterialKey = "glass.cabin"
    /// Coal load.
    public var coal: MaterialKey = "ablative.char-heavy"
    /// Cab floor.
    public var floorMaterial: MaterialKey = "metal.grate-iron"
    /// Cab roof.
    public var roof: MaterialKey = "metal.painted:34373C"
    public init() {}

    // Boiler axis, radii and stations.
    private let axisY: Float = 2.55
    private let zFront: Float = 10.7
    private let zBack: Float = 0.9

    /// Barrel radius along z (smokebox, tapered barrel). Firebox is an ellipse handled in `section`.
    private func barrelR(_ z: Float) -> Float {
        let t = max(0, min(1, (9.1 - z) / (9.1 - 4.9)))
        return z > 9.1 ? 0.96 : 0.96 + 0.12 * t
    }

    /// Cross-section (rx, ry, cy) at z: circle on the barrel blending into a wide, shallow firebox ellipse.
    private func section(_ z: Float) -> (Float, Float, Float) {
        let r = barrelR(z)
        let t = max(0, min(1, (4.95 - z) / 0.5))
        let s = t * t * (3 - 2 * t)
        return (r + (1.25 - r) * s, r + (0.95 - r) * s, axisY + (2.9 - axisY) * s)
    }

    /// Top of the boiler at z (for domes).
    private func topY(_ z: Float) -> Float { let (_, ry, cy) = section(z); return cy + ry }

    /// Outline loop CCW in (axial, y) for a closed lathe cross-section (rounded corners).
    private func loop(_ pts: [V2], fillet: Float = 0.01) -> [V2] {
        var p = Shape2D.rounded(pts, radius: fillet, segments: 1)
        p.append(p[0])
        return p
    }

    /// Flat plate in the YZ plane (outline given as (z, y)), thickness along X centered on x.
    private func plate(_ zy: [V2], x: Float, thick: Float, bevel: Float = 0.006, material: MaterialKey) -> (Surface, Xform) {
        var o = zy.map { V2(-$0.x, $0.y) }
        if Shape2D.area(o) < 0 { o.reverse() }
        let s = Prim.extrude(o, depth: thick, bevel: bevel, bevelSegments: 1, material: material)
        return (s, Xform(translation: V3(x, 0, 0), rotation: simd_quatf(degrees: 90, axis: V3(0, 1, 0))))
    }

    public func rig(seed: UInt64) -> Rig {
        _ = seed
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [45])
        let rotZ = simd_quatf(degrees: 90, axis: V3(1, 0, 0))    // lathe +Y -> +Z
        let qYX = simd_quatf(degrees: -90, axis: V3(0, 0, 1))    // lathe +Y -> +X
        let gauge: Float = 0.74
        let driverZ: [Float] = [7.0, 4.75, 2.5]
        let driverR: Float = 1.0, crank: Float = 0.30
        let aL: Float = 20 * .pi / 180, aR: Float = aL + .pi / 2
        func pin(_ side: Float, _ zc: Float, r: Float, yc: Float) -> V3 {
            let a = side > 0 ? aR : aL
            return V3(side * gauge, yc + r * sin(a), zc + r * cos(a))
        }

        // Joints.
        rig.part("drive", pivot: V3(0, 1, 0), joint: .hinge(axis: V3(1, 0, 0), 0...1, duration: 3))
        rig.part("whistle", pivot: V3(0, 4.2, 2.5), joint: .hinge(axis: V3(1, 0, 0), 0...1, duration: 0.4))
        rig.part("door", pivot: V3(0, 2.45, 0.9), joint: .hinge(axis: V3(0, 1, 0), 0...1, duration: 1.4))
        for i in 0..<3 {
            rig.part("driver\(i)", pivot: V3(0, driverR, driverZ[i]), joint: Joint(.revolute, axis: V3(1, 0, 0), range: -360...360, mimic: .init("drive", ratio: 360)))
        }
        let bogieZ: Float = 9.9, bogieR: Float = 0.5, trailZ: Float = -0.15, trailR: Float = 0.55
        rig.part("bogie", pivot: V3(0, bogieR, bogieZ), joint: Joint(.revolute, axis: V3(1, 0, 0), range: -720...720, mimic: .init("drive", ratio: 360 * driverR / bogieR)))
        rig.part("trailing", pivot: V3(0, trailR, trailZ), joint: Joint(.revolute, axis: V3(1, 0, 0), range: -720...720, mimic: .init("drive", ratio: 360 * driverR / trailR)))
        let tenderZ: [Float] = [-4.5, -6.9, -9.3], tenderR: Float = 0.6
        for i in 0..<3 {
            rig.part("tender\(i)", pivot: V3(0, tenderR, tenderZ[i]), joint: Joint(.revolute, axis: V3(1, 0, 0), range: -720...720, mimic: .init("drive", ratio: 360 * driverR / tenderR)))
        }
        // Rods follow the crank pins: parent turns with the wheel, the rod turns back, so it translates on the pin circle.
        for (side, tag) in [(Float(-1), "L"), (Float(1), "R")] {
            let p1 = pin(side, driverZ[1], r: crank, yc: driverR)
            rig.part("coup\(tag)", parent: "driver1", pivot: p1, joint: Joint(.revolute, axis: V3(1, 0, 0), range: -360...360, mimic: .init("drive", ratio: -360)))
            rig.part("con\(tag)", parent: "driver1", pivot: p1, joint: Joint(.revolute, axis: V3(1, 0, 0), range: -360...360, mimic: .init("drive", ratio: -360)))
        }
        rig.part("whistleValve", parent: "whistle", pivot: V3(0, 4.2, 2.5), joint: Joint(.prismatic, axis: V3(0, 1, 0), range: 0...0.03, mimic: .init("whistle", ratio: 0.03)))
        rig.part("fireDoor", parent: "door", pivot: V3(-0.31, 2.45, 0.875), joint: Joint(.revolute, axis: V3(0, 1, 0), range: 0...110, mimic: .init("door", ratio: 110)))
        rig.part("fireGlow", pivot: V3(0, 2.45, 0.893), joint: .fixed, options: 2)
        rig.optionLinks = [RigOptionLink(part: "fireGlow", joint: "door", thresholds: [0.05])]
        rig.lights = [
            RigLight(name: "headlamp", kind: .spot(inner: 14, outer: 38), position: V3(0, 3.78, 10.95), direction: V3(0, -0.04, 1),
                     color: V3(1, 0.93, 0.8), intensity: 2000, attenuationRadius: 40),
            RigLight(name: "firebox", part: "fireGlow", option: 1, position: V3(0, 2.45, 0.2), direction: V3(0, 0, -1),
                     color: V3(1, 0.45, 0.12), intensity: 700, attenuationRadius: 4),
        ]

        let segs = [40, 24], spokes = [10, 8], sides = [4, 4], radial = [48, 24], tub = [6, 4]
        // Boiler stations: 0.14 m apart, finer across the firebox flare.
        func stations(_ l: Int) -> [Float] {
            var z = zBack
            var out: [Float] = []
            let step: Float = l == 0 ? 0.14 : 0.36
            while z < zFront { out.append(z); z += (z > 4.4 && z < 5.0) ? step * 0.4 : step }
            out.append(zFront)
            return out
        }

        for l in 0..<2 {
            func put(_ s: Surface, _ x: Xform = .identity, to part: String? = nil, lod0: Bool = false) {
                if lod0 && l != 0 { return }
                if let p = part { rig.add(s, x, to: p, lods: l...l) } else { rig.base[l].add(s, x) }
            }
            let tubeSeg = tub[l]

            // MARK: boiler, smokebox, firebox
            let rings: [[V3]] = stations(l).map { z in
                let (rx, ry, cy) = section(z)
                let o = (0..<radial[l]).map { k -> V2 in
                    let a = Float(k) / Float(radial[l]) * 2 * .pi
                    return V2(rx * cos(a), cy + ry * sin(a))
                }
                return Prim.ring(o, y: z)
            }
            put(Prim.loft(rings, capStart: true, capEnd: true, material: paint), Xform(rotation: rotZ))
            // Black smokebox sleeve over the front length.
            let sbR = barrelR(9.1) + 0.012
            let sb: [V2] = [V2(sbR - 0.01, 8.85), V2(sbR, 8.88), V2(sbR, 10.55), V2(sbR + 0.015, 10.58), V2(sbR + 0.015, 10.7), V2(sbR - 0.02, 10.7)]
            put(Prim.lathe(Profile.smooth(sb, per: 1), segments: radial[l] * 2 / 3, seamTile: 1, material: sooty), Xform(translation: V3(0, axisY, 0), rotation: rotZ))
            do { let r = barrelR(8.5); let sp: [V2] = [V2(r - 0.002, 8.35), V2(r + 0.006, 8.4), V2(r + 0.006, 8.82), V2(r - 0.002, 8.85)]
                put(Prim.lathe(sp, segments: radial[l] / 2, seamTile: 1, material: soot), Xform(translation: V3(0, axisY, 0), rotation: rotZ)) }
            // Domed smokebox door with rim, dart and number plate.
            let door: [V2] = [V2(0, 10.86), V2(0.30, 10.85), V2(0.60, 10.80), V2(0.84, 10.74), V2(0.96, 10.70)]
            put(Prim.lathe(Profile.smooth(door.reversed(), per: 2), segments: radial[l] / 2, seamTile: 1, material: sooty), Xform(translation: V3(0, axisY, 0), rotation: rotZ))
            put(Prim.torus(major: 0.955, minor: 0.022, segments: radial[l] / 2, sides: 5, material: steel), Xform(translation: V3(0, axisY, 10.70), rotation: rotZ))
            // Lagging bands.
            let bandZ: [Float] = l == 0 ? [8.6, 8.0, 7.6, 6.7, 6.1, 5.2] : [8.4, 7.3, 6.4, 5.4]
            for z0 in bandZ {
                let r = barrelR(z0)
                let p: [V2] = [V2(r - 0.002, z0 - 0.05), V2(r + 0.014, z0 - 0.03), V2(r + 0.014, z0 + 0.03), V2(r - 0.002, z0 + 0.05)]
                put(Prim.lathe(p, segments: radial[l] * 5 / 12, seamTile: 1, material: black), Xform(translation: V3(0, axisY, 0), rotation: rotZ))
                let e: [V2] = [V2(r + 0.001, z0 - 0.07), V2(r + 0.006, z0 - 0.06), V2(r + 0.006, z0 - 0.052)]
                
            }
            if l == 0 {
                put(Prim.roundedBox(V3(0.26, 0.26, 0.03), radius: 0.012, bevelSegments: 2, material: brass), Xform(translation: V3(0, axisY + 0.62, 10.9)))
                put(Prim.torus(major: 0.13, minor: 0.014, segments: 24, sides: 6, material: bright), Xform(translation: V3(0, axisY - 0.15, 10.91), rotation: rotZ))
                put(Prim.tube([V3(-0.30, axisY - 0.15, 10.95), V3(0.30, axisY - 0.15, 10.95)], radii: [0.016, 0.016], sides: 6, seamTile: 0.1, material: bright))
                for s: Float in [-1, 1] { put(Prim.superellipsoid(V3(0.05, 0.05, 0.05), exponent: 2, subdivisions: 3, material: bright), Xform(translation: V3(s * 0.30, axisY - 0.15, 10.95))) }
                // Hinge straps across the door.
                for s: Float in [-1, 1] {
                    put(Prim.tube([V3(s * 0.12, axisY + 0.05, 10.86), V3(s * 0.55, axisY + 0.34, 10.78), V3(s * 0.84, axisY + 0.30, 10.74)], radii: [0.03, 0.03, 0.03], sides: 6, seamTile: 0.2, material: black))
                }
            }

            // MARK: chimney
            let chim: [V2] = [V2(0, 3.38), V2(0.31, 3.38), V2(0.30, 3.50), V2(0.22, 3.68), V2(0.16, 3.92), V2(0.15, 4.12), V2(0.18, 4.26), V2(0.22, 4.34), V2(0.19, 4.35), V2(0.14, 4.20), V2(0, 4.12)]
            put(Prim.lathe(Profile.smooth(chim, per: 1), segments: radial[l] / 2, seamTile: 0.4, material: sooty), Xform(translation: V3(0, 0, 10.05)))
            let cap: [V2] = [V2(0.22, 4.28), V2(0.255, 4.30), V2(0.27, 4.34), V2(0.255, 4.375), V2(0.20, 4.385), V2(0.185, 4.35), V2(0.22, 4.33)]
            put(Prim.lathe(cap, segments: radial[l] / 2, seamTile: 0.4, material: copper), Xform(translation: V3(0, 0, 10.05)))

            // MARK: domes, safety valve, whistle body
            func dome(_ z: Float, base: Float, body: Float, h: Float, mat: MaterialKey) {
                let y0 = topY(z) - 0.10
                let pts: [V2] = [V2(0, y0 + h + 0.1), V2(body * 0.5, y0 + h + 0.07), V2(body * 0.86, y0 + h - 0.06), V2(body, y0 + h * 0.62), V2(body * 0.98, y0 + 0.16), V2(base, y0 + 0.11), V2(base * 1.02, y0 + 0.04), V2(base, y0), V2(0, y0)]
                put(Prim.lathe(Profile.smooth(pts.reversed(), per: 1), segments: radial[l] / 2, seamTile: 0.5, material: mat), Xform(translation: V3(0, 0, z)))
            }
            dome(7.2, base: 0.47, body: 0.38, h: 0.52, mat: brass)
            dome(5.6, base: 0.34, body: 0.27, h: 0.34, mat: brass)
            // Safety valve column.
            let sv: [V2] = [V2(0, 3.72), V2(0.20, 3.72), V2(0.17, 3.84), V2(0.13, 3.96), V2(0.15, 4.14), V2(0.11, 4.27), V2(0.04, 4.31), V2(0, 4.32)]
            put(Prim.lathe(Profile.smooth(sv, per: 1), segments: radial[l] / 3, seamTile: 0.4, material: brass), Xform(translation: V3(0, 0, 3.55)))
            // Whistle.
            let wh: [V2] = [V2(0, 3.78), V2(0.09, 3.78), V2(0.075, 3.90), V2(0.035, 3.94), V2(0.035, 4.0), V2(0.08, 4.04), V2(0.075, 4.16), V2(0.06, 4.19), V2(0.06, 4.0)]
            put(Prim.lathe(Profile.smooth(wh, per: 1), segments: 10 / (l + 1), seamTile: 0.3, material: brass), Xform(translation: V3(0, 0, 2.5)))
            put(Prim.lathe(Profile.smooth([V2(0, 3.78), V2(0.07, 3.78), V2(0.06, 3.95), V2(0.07, 4.0), V2(0.06, 4.2), V2(0.05, 4.22), V2(0.05, 4.05)], per: 2),
                           segments: 10 / (l + 1), seamTile: 0.3, material: brass), Xform(translation: V3(0.0, 0, 2.5 + 0.17)))
            // Valve stem and pull lever (part whistleValve).
            put(Prim.tube([V3(0, 4.19, 2.5), V3(0, 4.34, 2.5)], radii: [0.012, 0.012], sides: 6, seamTile: 0.1, material: bright), to: "whistleValve")
            put(Prim.superellipsoid(V3(0.05, 0.04, 0.05), exponent: 2, subdivisions: 3, material: brass), Xform(translation: V3(0, 4.35, 2.5)), to: "whistleValve")

            // MARK: headlamp
            let lamp: [V2] = [V2(0, 10.80), V2(0.19, 10.80), V2(0.21, 10.84), V2(0.21, 10.95), V2(0.19, 10.98), V2(0.17, 10.98)]
            put(Prim.lathe(Profile.smooth(lamp, per: 1), segments: 24 / (l + 1), seamTile: 0.3, material: black), Xform(translation: V3(0, 3.76, 0), rotation: rotZ))
            put(Prim.lathe([V2(0, 10.99), V2(0.15, 10.985), V2(0.16, 10.975), V2(0.0, 10.96)], segments: 24 / (l + 1), seamTile: 0.3, material: "emissive.lamp-white"), Xform(translation: V3(0, 3.76, 0), rotation: rotZ))
            put(cuboid(V3(0.12, 0.24, 0.22), material: black), Xform(translation: V3(0, 3.62, 10.55)))

            // MARK: frames, buffer beams, buffers
            for s: Float in [-1, 1] {
                put(cuboid(V3(0.06, 0.46, 11.4), material: worn), Xform(translation: V3(s * 0.58, 1.30, 4.85)))
            }
            for z in [9.0, 6.0, 3.6, 0.9] as [Float] { put(cuboid(V3(1.2, 0.30, 0.14), material: black), Xform(translation: V3(0, 1.28, z))) }
            put(Prim.roundedBox(V3(3.00, 0.52, 0.14), radius: 0.02, bevelSegments: 2, material: red), Xform(translation: V3(0, 1.33, 10.55)))
            for s: Float in [-1, 1] {
                put(Prim.cylinder(radius: 0.09, height: 0.42, bevel: 0, segments: 14 / (l + 1), bevelSegments: 1, material: steel), Xform(translation: V3(s * 0.86, 1.33, 10.58), rotation: rotZ))
                put(Prim.cylinder(radius: 0.20, height: 0.05, bevel: 0.012, segments: 20 / (l + 1), bevelSegments: 1, material: bright), Xform(translation: V3(s * 0.86, 1.33, 10.95), rotation: rotZ))
            }
            put(Prim.roundedBox(V3(0.12, 0.18, 0.30), radius: 0.02, bevelSegments: 2, material: steel), Xform(translation: V3(0, 1.20, 10.78)))   // drag hook shank
            put(Prim.torus(major: 0.07, minor: 0.016, segments: 16, sides: 6, material: steel), Xform(translation: V3(0, 1.10, 10.9), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0)) * simd_quatf(degrees: 90, axis: V3(0, 0, 1))), lod0: true)

            // MARK: cylinders, steam chest, pipes, valve gear
            for s: Float in [-1, 1] {
                let cx: Float = s * 1.20
                let cyl: [V2] = [V2(0, 7.98), V2(0.22, 8.00), V2(0.37, 8.06), V2(0.37, 8.30), V2(0.36, 9.44), V2(0.39, 9.50), V2(0.28, 9.60), V2(0, 9.65)]
                put(Prim.lathe(cyl, segments: 16 / (l + 1), seamTile: 0.6, material: worn), Xform(translation: V3(cx, 1.0, 0), rotation: rotZ))
                put(Prim.cylinder(radius: 0.19, height: 1.45, bevel: 0, segments: 12 / (l + 1), bevelSegments: 1, material: worn), Xform(translation: V3(cx, 1.62, 8.05), rotation: rotZ))
                put(Prim.roundedBox(V3(0.42, 0.28, 0.9), radius: 0.03, bevelSegments: 1, material: black), Xform(translation: V3(cx, 1.38, 8.8)))
                // Piston rod gland collar.
                put(Prim.cylinder(radius: 0.055, height: 0.22, bevel: 0, segments: 14, bevelSegments: 1, material: bright), Xform(translation: V3(cx, 1.0, 7.80), rotation: rotZ), lod0: true)
                // Steam pipe from smokebox to cylinder.
                put(Prim.tube([V3(s * 0.55, 1.95, 9.30), V3(s * 0.85, 1.80, 9.00), V3(cx, 1.60, 8.9)], radii: [0.07, 0.07, 0.06], sides: tubeSeg + 2, seamTile: 0.3, material: bright))
                if l == 0 {
                    // Walschaerts gear: radius rod, expansion link, union link, valve spindle.
                    let gx = s * 1.12
                    put(Prim.tube([V3(gx, 1.50, 6.20), V3(gx, 1.62, 7.20), V3(gx, 1.64, 7.90)], radii: [0.022, 0.022, 0.022], sides: 8, seamTile: 0.1, material: bright))
                    put(Prim.torus(major: 0.30, minor: 0.018, segments: 8, sides: 5, arc: .pi * 0.62, material: steel),
                        Xform(translation: V3(gx, 1.18, 6.15), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1)) * simd_quatf(degrees: -90 - 56, axis: V3(0, 1, 0))))
                    put(Prim.tube([V3(gx, 1.26, 6.12), V3(gx, 1.05, 6.50), V3(gx, 0.78, 6.95)], radii: [0.020, 0.020, 0.020], sides: 8, seamTile: 0.1, material: steel))
                    put(Prim.tube([V3(gx, 1.64, 7.90), V3(gx, 1.66, 8.8)], radii: [0.030, 0.030], sides: 8, seamTile: 0.1, material: bright))
                    put(Prim.tube([V3(gx, 1.64, 7.0), V3(gx, 1.42, 6.2)], radii: [0.018, 0.018], sides: 8, seamTile: 0.1, material: steel))
                }
            }

            // MARK: wheels
            // Wheel rim loop (r, y) with y outward-positive for +X; mirrored for -X.
            let tireD = loop([V2(1.07, -0.07), V2(1.07, -0.045), V2(1.0, -0.03), V2(1.0, 0.07), V2(0.88, 0.07), V2(0.88, -0.07)], fillet: 0.012)
            let tireS = loop([V2(1.0, -0.07), V2(1.0, -0.045), V2(0.95, -0.03), V2(0.95, 0.07), V2(0.88, 0.07), V2(0.88, -0.07)], fillet: 0)
            func wheel(_ part: String, side s: Float, zc: Float, yc: Float, r: Float, nSpokes: Int, pinAngle: Float?, weights: Bool, solid: Bool) {
                let k = r / driverR
                func prof(_ p: [V2]) -> [V2] {
                    let m = p.map { V2($0.x * k, $0.y * s * 1) }
                    return s < 0 ? m.reversed() : m
                }
                let xw = s * gauge
                let place = Xform(translation: V3(xw, yc, zc), rotation: qYX)
                put(Prim.lathe(prof(tireS), segments: solid ? [14, 10][l] : [20, 14][l], seamTile: 0.5, material: steel), place, to: part)
                // Rim web.
                let rimPts: [V2] = [V2(0.88 * k, -0.055), V2(0.88 * k, 0.055), V2(0.80 * k, 0.045), V2(0.80 * k, -0.045)]
                let hub: [V2] = [V2(0, -0.11), V2(0.19, -0.11), V2(0.22, -0.09), V2(0.22, 0.06), V2(0.17, 0.09), V2(0.15, 0.14), V2(0.08, 0.16), V2(0, 0.16)]
                if !solid { put(Prim.lathe(Profile.smooth(s < 0 ? hub.map { V2($0.x * (0.5 + 0.5 * k), -$0.y) } : hub.map { V2($0.x * (0.5 + 0.5 * k), $0.y) }, per: 1), segments: 8 / (l + 1), seamTile: 0.3, material: steel), place, to: part) }
                _ = rimPts
                if solid {
                    let web: [V2] = [V2(0.12 * k, -0.02), V2(0.85 * k, -0.02), V2(0.85 * k, 0.02), V2(0.12 * k, 0.02)]
                    put(Prim.lathe(s < 0 ? web.reversed().map { V2($0.x, $0.y) } : web, segments: [14, 10][l], seamTile: 0.5, material: paint), place, to: part)
                } else {
                    for j in 0..<nSpokes {
                        let a = Float(j) / Float(nSpokes) * 2 * .pi + 0.1
                        let a0 = V3(xw, yc + 0.17 * k * sin(a), zc + 0.17 * k * cos(a))
                        let a1 = V3(xw, yc + 0.90 * k * sin(a), zc + 0.90 * k * cos(a))
                        put(Prim.tube([a0, a1], radii: [0.036, 0.026], sides: sides[l], seamTile: 0.1, material: paint), to: part)
                    }
                }
                if let pa = pinAngle {
                    // Counterweight opposite the pin, crank pin boss.
                    let ca = pa + .pi
                    var o: [V2] = []
                    let n = 3
                    for q in 0...n { let t = ca - 0.95 + Float(q) / Float(n) * 1.9; o.append(V2(-0.86 * cos(t), 0.86 * sin(t))) }
                    for q in 0...n { let t = ca + 0.75 - Float(q) / Float(n) * 1.5; o.append(V2(-0.42 * cos(t), 0.42 * sin(t))) }
                    if Shape2D.area(o) < 0 { o.reverse() }
                    let outline = Shape2D.rounded(o, radius: 0.035, segments: 1)
                    let cw = Prim.extrude(outline, depth: 0.05, bevel: 0.004, bevelSegments: 1, material: paint)
                    put(cw, Xform(translation: V3(xw + s * 0.045, yc, zc), rotation: simd_quatf(degrees: 90, axis: V3(0, 1, 0))), to: part, lod0: true)
                    let pp = V3(xw, yc + crank * k * sin(pa), zc + crank * k * cos(pa))
                    let ext: Float = part == "driver1" ? 0.38 : 0.26
                    put(Prim.cylinder(radius: 0.075, height: ext, bevel: 0, segments: 10 / (l + 1), bevelSegments: 1, material: steel),
                        Xform(translation: V3(s > 0 ? pp.x - 0.04 : pp.x - ext + 0.04, pp.y, pp.z), rotation: qYX), to: part)
                }
            }
            for (i, zc) in driverZ.enumerated() {
                for s: Float in [-1, 1] { wheel("driver\(i)", side: s, zc: zc, yc: driverR, r: driverR, nSpokes: spokes[l], pinAngle: s > 0 ? aR : aL, weights: true, solid: false) }
                // Axle.
                put(Prim.cylinder(radius: 0.09, height: 2 * gauge, bevel: 0, segments: 12, bevelSegments: 1, material: steel), Xform(translation: V3(-gauge, driverR, zc), rotation: qYX), to: "driver\(i)")
            }
            for s: Float in [-1, 1] {
                wheel("bogie", side: s, zc: bogieZ, yc: bogieR, r: bogieR, nSpokes: 0, pinAngle: nil, weights: false, solid: true)
                wheel("trailing", side: s, zc: trailZ, yc: trailR, r: trailR, nSpokes: 0, pinAngle: nil, weights: false, solid: true)
                for i in 0..<3 { wheel("tender\(i)", side: s, zc: tenderZ[i], yc: tenderR, r: tenderR, nSpokes: 0, pinAngle: nil, weights: false, solid: true) }
            }
            put(Prim.cylinder(radius: 0.06, height: 2 * gauge, bevel: 0, segments: 8, bevelSegments: 1, material: steel), Xform(translation: V3(-gauge, bogieR, bogieZ), rotation: qYX), to: "bogie")
            put(Prim.cylinder(radius: 0.06, height: 2 * gauge, bevel: 0, segments: 6, bevelSegments: 1, material: steel), Xform(translation: V3(-gauge, trailR, trailZ), rotation: qYX), to: "trailing")
            for i in 0..<3 { put(Prim.cylinder(radius: 0.06, height: 2 * gauge, bevel: 0, segments: 6, bevelSegments: 1, material: steel), Xform(translation: V3(-gauge, tenderR, tenderZ[i]), rotation: qYX), to: "tender\(i)") }
            // Bogie and trailing truck frames (static).
            put(cuboid(V3(1.6, 0.12, 0.30), material: black), Xform(translation: V3(0, 0.82, bogieZ)))
            put(cuboid(V3(1.6, 0.12, 0.30), material: black), Xform(translation: V3(0, 0.88, trailZ)))

            // MARK: rods (parts coupL/R, conL/R)
            for (side, tag) in [(Float(-1), "L"), (Float(1), "R")] {
                let a = side > 0 ? aR : aL
                func pinPos(_ i: Int) -> V2 { V2(driverZ[i] + crank * cos(a), driverR + crank * sin(a)) }   // (z, y)
                let p0 = pinPos(0), p1 = pinPos(1), p2 = pinPos(2)
                // Coupling rod: tapered bar from pin 0 to pin 2 with bosses.
                let xr = side * 0.93
                let w0: Float = 0.075, w1: Float = 0.055
                let rodOutline: [V2] = [V2(p0.x, p0.y - w0), V2(p1.x, p1.y - w1), V2(p2.x, p2.y - w0), V2(p2.x, p2.y + w0), V2(p1.x, p1.y + w1), V2(p0.x, p0.y + w0)]
                let (cs, cx) = plate(Shape2D.rounded(rodOutline, radius: 0.04, segments: 3), x: xr, thick: 0.035, material: bright)
                put(cs, cx, to: "coup\(tag)")
                for p in [p0, p1, p2] {
                    put(Prim.cylinder(radius: 0.105, height: 0.06, bevel: 0, segments: 12 / (l + 1), bevelSegments: 1, material: bright),
                        Xform(translation: V3(side > 0 ? xr - 0.03 : xr - 0.03, p.y, p.x), rotation: qYX), to: "coup\(tag)")
                }
                // Connecting rod from the middle pin forward to the crosshead.
                let czRod: Float = 7.25
                let xc = side * 1.08
                let cy: Float = driverR
                let conOutline: [V2] = [V2(czRod + 0.05, cy - 0.05), V2(p1.x - 0.02, p1.y - 0.115), V2(p1.x - 0.02, p1.y + 0.115), V2(czRod + 0.05, cy + 0.05)]
                let (ns, nx) = plate(Shape2D.rounded(conOutline, radius: 0.03, segments: 3), x: xc, thick: 0.04, material: bright)
                put(ns, nx, to: "con\(tag)")
                put(Prim.cylinder(radius: 0.13, height: 0.075, bevel: 0, segments: 24 / (l + 1), bevelSegments: 1, material: bright), Xform(translation: V3(xc - 0.04, p1.y, p1.x), rotation: qYX), to: "con\(tag)")
                // Crosshead and piston rod to the cylinder gland.
                put(cuboid(V3(0.12, 0.22, 0.26), material: steel), Xform(translation: V3(xc, cy, czRod + 0.02)), to: "con\(tag)")
                put(Prim.tube([V3(xc, cy, czRod + 0.12), V3(xc, cy, 8.0)], radii: [0.032, 0.032], sides: sides[l], seamTile: 0.1, material: bright), to: "con\(tag)")
            }

            // MARK: running boards, handrails, steps
            for s: Float in [-1, 1] {
                put(Prim.roundedBox(V3(0.60, 0.05, 8.0), radius: 0.02, bevelSegments: 1, material: worn), Xform(translation: V3(s * 1.32, 2.26, 5.35)))
                put(cuboid(V3(0.04, 0.16, 8.0), material: soot), Xform(translation: V3(s * 1.60, 2.18, 5.35)))
                // Handrail along the barrel with stanchions.
                var rail: [V3] = []
                for z in stride(from: Float(9.0), through: 5.0, by: -1.0) {
                    let dy: Float = 0.62
                    let xs = sqrt(max(0.01, barrelR(z) * barrelR(z) - dy * dy)) + 0.10
                    rail.append(V3(s * xs, axisY + dy, z))
                }
                put(Prim.tube(rail, radii: rail.map { _ in 0.018 }, sides: tubeSeg, seamTile: 0.1, material: brassAged))
                for pz in [9.0, 7.0, 5.0] as [Float] {
                    let dy: Float = 0.62
                    let xs = sqrt(max(0.01, barrelR(pz) * barrelR(pz) - dy * dy))
                    put(Prim.tube([V3(s * xs, axisY + dy, pz), V3(s * (xs + 0.10), axisY + dy, pz)], radii: [0.012, 0.012], sides: 6, seamTile: 0.1, material: brass), lod0: true)
                }
                put(cuboid(V3(0.04, 0.58, 0.5), material: black), Xform(translation: V3(s * 1.47, 1.31, -1.4)))
                // Cab steps and grab rail.
                for (y, w) in [(1.05, 0.34)] as [(Float, Float)] {
                    put(cuboid(V3(w, 0.04, 0.5), material: black), Xform(translation: V3(s * 1.30, y, -1.4)), lod0: l == 1 ? false : false)
                    put(Prim.tube([V3(s * 1.15, y - 0.02, -1.4), V3(s * 1.15, y + 0.5, -1.4)], radii: [0.012, 0.012], sides: 5, seamTile: 0.1, material: black), lod0: true)
                }
                put(Prim.tube([V3(s * 1.56, 1.65, -1.62), V3(s * 1.56, 3.05, -1.62)], radii: [0.018, 0.018], sides: tubeSeg, seamTile: 0.1, material: brass))
            }

            // MARK: cab
            let cabFront: Float = 1.35, cabBack: Float = -1.9, cabLen = cabFront - cabBack, cabMid = (cabFront + cabBack) / 2
            put(cuboid(V3(3.04, 0.07, cabLen + 0.2), material: floorMaterial), Xform(translation: V3(0, 1.58, cabMid - 0.1)))
            put(Prim.roundedBox(V3(3.00, 2.20, 0.06), radius: 0.012, bevelSegments: 1, material: paint), Xform(translation: V3(0, 2.72, cabFront)))
            for s: Float in [-1, 1] {
                let x = s * 1.50
                put(Prim.roundedBox(V3(0.06, 0.90, cabLen), radius: 0.012, bevelSegments: 1, material: paint), Xform(translation: V3(x, 2.05, cabMid)))             // lower panel y 1.60...2.50
                put(Prim.roundedBox(V3(0.06, 0.48, cabLen), radius: 0.012, bevelSegments: 1, material: paint), Xform(translation: V3(x, 3.50, cabMid)))             // header y 3.26...3.74
                for (z0, z1) in [(1.35, 1.05), (0.30, -0.30), (-1.40, -1.90)] as [(Float, Float)] {
                    put(cuboid(V3(0.06, 0.78, abs(z1 - z0)), material: paint), Xform(translation: V3(x, 2.88, (z0 + z1) / 2)))   // posts
                }
                for (z0, z1) in [(1.05, 0.30), (-0.30, -1.40)] as [(Float, Float)] {
                    let zc = (z0 + z1) / 2, wz = abs(z1 - z0)
                    put(cuboid(V3(0.016, 0.74, wz - 0.03), material: glass), Xform(translation: V3(x, 2.88, zc)))
                    put(cuboid(V3(0.085, 0.03, wz + 0.02), material: brass), Xform(translation: V3(x, 2.505, zc)), lod0: true)
                    put(cuboid(V3(0.085, 0.03, wz + 0.02), material: brass), Xform(translation: V3(x, 3.265, zc)), lod0: true)
                }
                // Bench and number plate.
                put(cuboid(V3(0.40, 0.06, 1.0), material: "wood.pine-aged"), Xform(translation: V3(s * 1.25, 2.05, -1.1)), lod0: true)
                put(Prim.roundedBox(V3(0.012, 0.22, 0.52), radius: 0.03, bevelSegments: 1, material: brass), Xform(translation: V3(s * 1.535, 3.52, -0.55)), lod0: true)
            }
            if l == 0 { for (cx, cz) in [(0.4, -0.6), (-0.7, -1.2)] as [(Float, Float)] { put(Prim.superellipsoid(V3(0.14, 0.11, 0.16), exponent: 3, subdivisions: 1, material: coal), Xform(translation: V3(cx, 1.67, cz), rotation: simd_quatf(degrees: cx * 90, axis: V3(0, 1, 0)))) } }
            // Roof: arched loft with a front and rear overhang, ventilator.
            let roofRings: [[V3]] = [(-2.35, 0.95), (-2.30, 1.0), (1.80, 1.0), (1.85, 0.95)].map { (z: Float, k: Float) in
                Prim.ring(Shape2D.superellipse(3.36 * k, 0.50 * k, exponent: 3, segments: 48 / (l + 1)).map { V2($0.x, $0.y + 3.99) }, y: z)
            }
            put(Prim.loft(roofRings, capStart: true, capEnd: true, material: roof), Xform(rotation: rotZ))
            put(Prim.roundedBox(V3(0.56, 0.10, 1.0), radius: 0.02, bevelSegments: 1, material: roof), Xform(translation: V3(0, 4.27, -0.2)), lod0: true)
            put(Prim.roundedBox(V3(0.56, 0.16, 0.5), radius: 0.02, bevelSegments: 1, material: roof), Xform(translation: V3(0, 4.20, 0.5)))
            // Backhead plate details and gauges inside the cab.
            put(cuboid(V3(0.74, 0.62, 0.02), material: black), Xform(translation: V3(0, 2.45, 0.9)))
            for gx: Float in [-0.6, 0.6] {
                put(Prim.cylinder(radius: 0.10, height: 0.03, bevel: 0, segments: 20 / (l + 1), bevelSegments: 1, material: brass), Xform(translation: V3(gx, 3.12, 0.86), rotation: rotZ * simd_quatf(degrees: 180, axis: V3(1, 0, 0))), lod0: true)
            }
            put(Prim.tube([V3(0.9, 2.20, 0.86), V3(0.9, 3.00, 0.86)], radii: [0.025, 0.025], sides: tubeSeg, seamTile: 0.1, material: bright), lod0: true)   // gauge glass
            put(Prim.tube([V3(-0.55, 2.35, 0.86), V3(-0.55, 2.55, 0.40), V3(-0.55, 2.65, 0.20)], radii: [0.018, 0.018, 0.018], sides: 6, seamTile: 0.1, material: brass), lod0: true)   // regulator handle
            // Firebox door (part fireDoor), glow (part fireGlow option 1).
            put(Prim.roundedBox(V3(0.62, 0.56, 0.03), radius: 0.03, bevelSegments: 2, material: black), Xform(translation: V3(0, 2.45, 0.875)), to: "fireDoor")
            put(cuboid(V3(0.30, 0.04, 0.03), material: steel), Xform(translation: V3(0.08, 2.45, 0.855)), to: "fireDoor")
            put(Prim.roundedBox(V3(0.50, 0.44, 0.012), radius: 0.02, bevelSegments: 1, material: "emissive.flame"), Xform(translation: V3(0, 2.45, 0.893)), to: "fireGlow")
            rig.add(Prim.roundedBox(V3(0.50, 0.44, 0.012), radius: 0.02, bevelSegments: 1, material: "emissive.flame"), Xform(translation: V3(0, 2.45, 0.893)), to: "fireGlow", option: 1, lods: l...l)
            put(cuboid(V3(0.54, 0.48, 0.015), material: black), Xform(translation: V3(0, 2.45, 0.892)))

            // MARK: drawbar and tender
            put(cuboid(V3(0.5, 0.12, 1.0), material: black), Xform(translation: V3(0, 1.35, -2.35)))
            put(cuboid(V3(2.3, 0.07, 0.8), material: "metal.grate-iron"), Xform(translation: V3(0, 1.58, -2.4)))
            let tankLen: Float = 7.85, tankMid: Float = -2.7 - tankLen / 2
            put(Prim.roundedBox(V3(2.90, 1.75, tankLen), radius: 0.07, bevelSegments: 3, material: paint), Xform(translation: V3(0, 2.15, tankMid)))
            put(Prim.roundedBox(V3(2.96, 0.10, tankLen + 0.06), radius: 0.03, bevelSegments: 2, material: black), Xform(translation: V3(0, 3.0, tankMid)))
            put(Prim.roundedBox(V3(2.50, 0.20, tankLen - 0.3), radius: 0.03, bevelSegments: 1, material: black), Xform(translation: V3(0, 1.22, tankMid)))
            for s: Float in [-1, 1] {
                put(Prim.roundedBox(V3(0.06, 0.98, 3.7), radius: 0.012, bevelSegments: 1, material: paint), Xform(translation: V3(s * 1.45, 3.54, -4.57)))
                put(Prim.roundedBox(V3(0.012, 0.30, 0.78), radius: 0.04, bevelSegments: 1, material: brass), Xform(translation: V3(s * 1.462, 2.45, -6.6)), lod0: true)
                put(cuboid(V3(0.08, 0.04, 7.0), material: steel), Xform(translation: V3(s * 1.45, 2.55, tankMid)), lod0: true)
            }
            for s: Float in [-1, 1] {
                put(cuboid(V3(0.012, 0.28, tankLen - 0.4), material: soot), Xform(translation: V3(s * 1.456, 1.50, tankMid)))
                put(cuboid(V3(0.012, 0.22, cabLen - 0.1), material: soot), Xform(translation: V3(s * 1.532, 1.75, cabMid)))
            }
            put(Prim.roundedBox(V3(2.90, 0.98, 0.06), radius: 0.012, bevelSegments: 1, material: paint), Xform(translation: V3(0, 3.54, -2.78)))
            put(cuboid(V3(2.90, 0.82, 0.06), material: paint), Xform(translation: V3(0, 3.46, -6.40), rotation: simd_quatf(degrees: 14, axis: V3(1, 0, 0))))
            // Coal heap: lumpy mound plus loose lumps.
            let heap = Prim.cubeSphere(subdivisions: l == 0 ? 3 : 3, material: coal) { d in
                let n = Noise.fbm(d * 2.4 + V3(3.1, 1.7, 0.6), octaves: 3)
                let y = max(d.y, 0)
                let lump = 1 + 0.16 * n
                let ex = V3(1.38 * d.x * lump, 1.15 * pow(y, 0.9) * (1 + 0.5 * n) , 1.78 * d.z * lump)
                return V3(ex.x, ex.y, ex.z)
            }
            put(heap, Xform(translation: V3(0, 3.02, -4.6)))
            if l == 0 {
                var rng = SeededRNG(seed: 11)
                for _ in 0..<0 {
                    let x = Float.random(in: -1.15...1.15, using: &rng), z = Float.random(in: -1.5...1.5, using: &rng)
                    let h = 1.05 * max(0, 1 - pow(abs(x) / 1.35, 2) - pow(abs(z) / 1.75, 2)) + 0.03
                    let sz = Float.random(in: 0.09...0.20, using: &rng)
                    put(Prim.superellipsoid(V3(sz, sz * 0.8, sz * 1.1), exponent: 3, subdivisions: 2, material: coal),
                        Xform(translation: V3(x, 3.02 + h, -4.6 + z), rotation: simd_quatf(degrees: Float.random(in: 0...360, using: &rng), axis: simd_normalize(V3(1, 0.4, 0.3)))))
                }
            }
            // Water filler hatch, tool box, tender rear.
            let hatch: [V2] = [V2(0, 3.05), V2(0.34, 3.05), V2(0.34, 3.09), V2(0.30, 3.12), V2(0.24, 3.15), V2(0, 3.16)]
            put(Prim.lathe(Profile.smooth(hatch, per: 1), segments: 24 / (l + 1), seamTile: 0.4, material: brassAged), Xform(translation: V3(0, 0, -8.6)), lod0: false)
            put(Prim.tube([V3(-0.18, 3.16, -8.6), V3(0.18, 3.16, -8.6)], radii: [0.02, 0.02], sides: 6, seamTile: 0.1, material: bright), lod0: true)
            put(Prim.roundedBox(V3(2.96, 0.52, 0.14), radius: 0.02, bevelSegments: 2, material: red), Xform(translation: V3(0, 1.33, -10.65)))
            for s: Float in [-1, 1] {
                put(Prim.cylinder(radius: 0.09, height: 0.35, bevel: 0, segments: 14 / (l + 1), bevelSegments: 1, material: steel), Xform(translation: V3(s * 0.86, 1.33, -10.65), rotation: rotZ * simd_quatf(degrees: 180, axis: V3(1, 0, 0))))
                put(Prim.cylinder(radius: 0.20, height: 0.05, bevel: 0.012, segments: 20 / (l + 1), bevelSegments: 1, material: bright), Xform(translation: V3(s * 0.86, 1.33, -10.92 - 0.0), rotation: rotZ * simd_quatf(degrees: 180, axis: V3(1, 0, 0))))
            }
            put(cuboid(V3(0.16, 0.22, 0.14), material: black), Xform(translation: V3(0, 1.72, -10.62)), lod0: true)
        }
        rig.base[0].add(cuboid(V3(0.05, 0.2, 0.05), material: black), Xform(translation: V3(0.6, 3.1, -10.45)))
        rig.base[0].add(cuboid(V3(0.05, 0.2, 0.05), material: black), Xform(translation: V3(-0.6, 3.1, -10.45)))
        rig.states = [
            RigState("rest"),
            RigState("rolling", ["drive": 0.125]),
            RigState("whistling", ["whistle": 1]),
            RigState("fire-lit", ["door": 1], options: ["fireGlow": 1]),
        ]
        groundAO(&rig, height: 1.3)
        return rig
    }
}
