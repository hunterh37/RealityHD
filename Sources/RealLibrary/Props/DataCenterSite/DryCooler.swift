import simd
import Foundation

/// Shared fan, louver and coil helpers for the yard cooling props.
enum CoolKit {
    typealias Part = (Surface, Xform)

    /// Shroud wall with rolled inlet lip; axis up, base at c.y.
    static func shroud(_ c: V3, r: Float, h: Float, _ mat: MaterialKey) -> [Part] {
        let prof: [V2] = [V2(r + 0.012, 0), V2(r + 0.012, h), V2(r - 0.004, h), V2(r - 0.004, 0)]
        return [(Prim.lathe(prof, segments: 28, seamTile: 1, material: mat), Xform(translation: c)),
                (Prim.torus(major: r + 0.004, minor: 0.022, segments: 28, sides: 4, material: mat), Xform(translation: c + V3(0, h, 0)))]
    }
    /// Wire guard: concentric rings, radial wires, hub disc. Centered at c, axis up.
    static func guardWire(_ c: V3, r: Float, _ mat: MaterialKey) -> [Part] {
        var o: [Part] = []
        for f: Float in [0.4, 0.7, 1.0] {
            o.append((Prim.torus(major: r * f, minor: 0.0055, segments: 20, sides: 3, material: mat), Xform(translation: c)))
        }
        for k in 0..<12 { let a = Float(k) / 12 * 2 * .pi
            o.append((OK.rod(c + V3(cos(a) * r * 0.1, 0, sin(a) * r * 0.1), c + V3(cos(a) * r, 0, sin(a) * r), r: 0.0045, mat, sides: 3), .identity)) }
        o.append((Prim.cylinder(radius: r * 0.12, height: 0.03, bevel: 0.004, segments: 16, bevelSegments: 1, material: mat), Xform(translation: c)))
        return o
    }
    /// Seven-blade fan wheel with hub and motor can, centered at c.
    static func wheel(_ c: V3, r: Float, phase: Float, blade: MaterialKey, hub: MaterialKey) -> [Part] {
        var o: [Part] = []
        o.append((Prim.cylinder(radius: r * 0.17, height: 0.12, bevel: 0.01, segments: 16, bevelSegments: 1, material: hub), Xform(translation: c + V3(0, -0.06, 0))))
        let n = 7, len = r * 0.82
        for k in 0..<n {
            let yaw = simd_quatf(angle: phase + Float(k) / Float(n) * 2 * .pi, axis: V3(0, 1, 0))
            let pitch = simd_quatf(angle: 0.42, axis: V3(1, 0, 0))
            let mid = r * 0.17 + len / 2
            o.append((Prim.extrude(Shape2D.rect(len, 0.19), depth: 0.012, bevel: 0, bevelSegments: 1, material: blade),
                      Xform(translation: c + yaw.act(V3(mid, 0, 0)), rotation: yaw * pitch)))
        }
        return o
    }
    /// Coil slab tilted about X; returns the slab and fin-edge ribs.
    static func coil(center: V3, length: Float, h: Float, thick: Float, tilt: Float, _ mat: MaterialKey, ribs: Int) -> [Part] {
        let q = simd_quatf(angle: tilt, axis: V3(1, 0, 0))
        var o: [Part] = [(Prim.roundedBox(V3(length, h, thick), radius: 0.006, bevelSegments: 1, material: mat), Xform(translation: center, rotation: q))]
        for k in 0..<ribs {
            let x = -length / 2 + (Float(k) + 0.5) * length / Float(ribs)
            let off = q.act(V3(x, 0, thick / 2 + 0.002))
            o.append((Prim.extrude(Shape2D.rect(0.012, h), depth: 0.004, bevel: 0, bevelSegments: 1, material: "metal.galvanized"), Xform(translation: center + off, rotation: q)))
        }
        return o
    }
}

/// Industrial dry cooler, 12 x 2.5 x 2.4 m: V-bank of aluminum fin coils on a galvanized frame, eight EC fans with wire
/// guards on the top deck, flanged header pipes with stubs, and a NEMA control panel on the end frame.
/// Parts: base (frame, coils, pipes, panel, guards), fan1...fan8 (blades and hub; spin about the vertical axis).
public struct DryCooler: RealArticulated {
    public static let id = "dry-cooler"
    public static let summary = "Industrial dry cooler: V-bank finned coils, eight spinning EC fans with guards, galvanized frame, header pipes, control panel."
    public static let tags = ["prop", "articulated", "datacenter", "metal", "cooling"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 22, distance: 1.0, studio: true)

    /// Fan count along the 12 m length.
    public var fans = 8
    public var fan: Float = 0.7
    public var frame: MaterialKey = "metal.galvanized"
    public var fins: MaterialKey = "metal.aluminum-fins"
    public var casing: MaterialKey = "metal.galvanized"
    public var pipe: MaterialKey = "metal.steel"
    public var panel: MaterialKey = "metal.painted:B9BDBC"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 1)
        func put(_ ps: [CoolKit.Part], to part: String? = nil) {
            for (s, x) in ps { if let part { rig.add(s, x, to: part) } else { rig.base[0].add(s, x) } }
        }
        func B(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.004) {
            let (a, x) = OK.box(s, c, mat, r: r); rig.base[0].add(a, x)
        }
        let L: Float = 12, yb: Float = 0.7, yt: Float = 2.12
        let zb: Float = 0.22, zt: Float = 1.0
        // Base rails and posts.
        for sz: Float in [-1, 1] {
            B(V3(L - 0.1, 0.12, 0.1), V3(0, 0.06, sz * 0.75), frame)
            for k in 0...4 { let x = -5.8 + Float(k) * 2.9
                B(V3(0.1, yb, 0.1), V3(x, yb / 2, sz * 0.55), frame)
                B(V3(0.06, 0.06, 1.1), V3(x, 0.15, 0), frame, r: 0.003) }
        }
        // Apex plenum floor (closes the V) and V coils with end plates.
        B(V3(L - 0.1, 0.05, 2 * zb + 0.12), V3(0, yb - 0.02, 0), frame)
        let ang = atan2(zt - zb, yt - yb), ch = (yt - yb) / cos(ang)
        for sz: Float in [-1, 1] {
            put(CoolKit.coil(center: V3(0, (yb + yt) / 2, sz * (zb + zt) / 2), length: L - 0.3, h: ch, thick: 0.15, tilt: sz * ang, fins, ribs: 36))
            // Coil casing flanges top and bottom.
            B(V3(L - 0.1, 0.06, 0.1), V3(0, yt + 0.01, sz * (zt + 0.02)), casing, r: 0.003)
        }
        for sx: Float in [-1, 1] {
            let pl = Shape2D.rounded([V2(-zb - 0.1, yb), V2(zb + 0.1, yb), V2(zt + 0.08, yt + 0.06), V2(-zt - 0.08, yt + 0.06)], radius: 0.01)
            rig.base[0].add(Prim.extrude(pl, depth: 0.05, bevel: 0.004, bevelSegments: 1, material: casing),
                            Xform(translation: V3(sx * (L / 2 - 0.05), 0, 0), rotation: simd_quatf(angle: -.pi / 2, axis: V3(0, 1, 0))))
        }
        // Top deck strips between and beside the fans.
        let pitch = (L - 0.3) / Float(fans), x0 = -(L - 0.3) / 2 + pitch / 2
        let deckY = yt + 0.04
        for sz: Float in [-1, 1] { B(V3(L - 0.1, 0.05, zt - fan * 1.0 - 0.0 + 0.08), V3(0, deckY, sz * (fan + zt + 0.1) / 2 + 0), casing, r: 0.003) }
        for k in 0...fans { B(V3(0.14, 0.05, 2 * fan + 0.04), V3(-(L - 0.3) / 2 + Float(k) * pitch, deckY, 0), casing, r: 0.003) }
        // Fans.
        for k in 0..<fans {
            let c = V3(x0 + Float(k) * pitch, deckY, 0)
            let name = "fan\(k + 1)"
            put(CoolKit.shroud(c, r: fan, h: 0.3, casing))
            put(CoolKit.guardWire(c + V3(0, 0.33, 0), r: fan, "metal.galvanized"))
            // Motor spider under the wheel.
            for a: Float in [0, .pi / 2] { rig.base[0].add(OK.rod(c + V3(cos(a) * fan, 0.1, sin(a) * fan), c + V3(-cos(a) * fan, 0.1, -sin(a) * fan), r: 0.012, frame)) }
            rig.part(name, pivot: c + V3(0, 0.2, 0), joint: .hinge(axis: .up, -360...360, duration: 1.0))
            put(CoolKit.wheel(c + V3(0, 0.2, 0), r: fan, phase: Float(k) * 0.37 + Float(rng.next() % 100) / 100, blade: "plastic.black", hub: "metal.painted:2F3438"), to: name)
        }
        // Headers: inlet along the upper edge of each coil bank, outlet along the lower edge; flanged stubs at the east end.
        for sz: Float in [-1, 1] {
            for (y, z, r) in [(yt - 0.12, sz * (zt + 0.12), Float(0.065)), (yb + 0.1, sz * (zb + 0.22), 0.05)] {
                rig.base[0].add(Prim.tube([V3(-L / 2 + 0.2, y, z), V3(L / 2 + 0.28, y, z)], radii: [r, r], sides: 14, seamTile: 0.4, material: pipe))
                for fx: Float in [-L / 2 + 0.2, L / 2 + 0.18] {
                    let (cy, cx) = OK.cylX(r * 1.6, 0.025, x0: fx, y: y, z: z, pipe, seg: 14, bevel: 0.003); rig.base[0].add(cy, cx) }
            }
            // Branch connections to the coil along the length.
            for k in 0..<6 { let x = -5 + Float(k) * 2
                rig.base[0].add(OK.rod(V3(x, yt - 0.12, sz * (zt + 0.12)), V3(x, yt - 0.12, sz * (zt - 0.05)), r: 0.03, pipe, sides: 8)) }
        }
        // End manifold risers joining the two banks at the +X end.
        rig.base[0].add(Prim.tube([V3(L / 2 + 0.28, yt - 0.12, -zt - 0.17), V3(L / 2 + 0.28, yt - 0.12, zt + 0.12)], radii: [0.075, 0.075], sides: 14, seamTile: 0.4, material: pipe))
        // Control panel on a stand at the -X end.
        B(V3(0.32, 0.9, 0.7), V3(-L / 2 - 0.3, 1.15, 0), panel, r: 0.01)
        B(V3(0.02, 0.8, 0.6), V3(-L / 2 - 0.46, 1.15, 0), "metal.painted:A7ABAA", r: 0.004)
        B(V3(0.02, 0.1, 0.03), V3(-L / 2 - 0.48, 1.2, 0.22), "metal.steel", r: 0.004)
        B(V3(0.04, 0.5, 0.1), V3(-L / 2 - 0.18, 0.45, 0), frame)
        B(V3(0.02, 0.1, 0.2), V3(-L / 2 - 0.47, 1.45, 0), "plastic.black", r: 0.003)
        // Warning label.
        B(V3(0.005, 0.1, 0.14), V3(-L / 2 - 0.465, 0.95, -0.15), "metal.painted:E0B000", r: 0.001)
        // Lifting lugs on the top deck corners.
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            B(V3(0.12, 0.1, 0.03), V3(sx * 5.8, yt + 0.12, sz * 1.1), frame, r: 0.004) } }
        groundAO(&rig, height: 0.8, floor: 0.6)
        rig.states = [RigState("spin"), RigState("still", [:])]
        return rig
    }
}
