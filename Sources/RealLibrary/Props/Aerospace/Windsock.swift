import simd
import Foundation

/// Airfield windsock on a 6 m galvanized mast and concrete pad. The swivel head turns on the mast
/// (`head`, yaw) and the banded nylon sock hinges at its hoop (`sock`): gale holds it level, breeze
/// lets it sag, calm hangs it nearly straight down.
public struct Windsock: RealArticulated {
    public static let id = "windsock"
    public static let summary = "Airfield windsock, 6 m galvanized mast on a concrete pad: swivel head and orange and white banded sock, states calm, breeze and gale."
    public static let tags = ["prop", "aerospace", "outdoor", "articulated", "metal", "fabric"]
    public static let budget = 10_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 10, distance: 1.1)

    /// Mast height to the swivel in meters.
    public var mastHeight: Float = 6
    /// Sock length and throat / tail radius.
    public var sockLength: Float = 3.6
    public var throat: Float = 0.45
    public var tail: Float = 0.2
    public var bands = 5
    public var orange: MaterialKey = "fabric.nylon:D9541E"
    public var white: MaterialKey = "fabric.nylon:E4E0D6"
    public var metal: MaterialKey = "metal.galvanized"
    public var pad: MaterialKey = "concrete.rough"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [30])
        let H = mastHeight
        let hoopX: Float = 0.42
        for l in 0..<2 {
            let segs = l == 0 ? 24 : 10
            var m = Model(name: Self.id)
            m.add(Prim.roundedBox(V3(0.9, 0.3, 0.9), radius: 0.03, bevelSegments: 2, material: pad), Xform(translation: V3(0, 0.15, 0)))
            m.add(Prim.cylinder(radius: 0.16, height: 0.02, bevel: 0.004, segments: segs, material: metal), Xform(translation: V3(0, 0.3, 0)))
            m.add(Prim.lathe([V2(0.075, 0), V2(0.06, H * 0.4), V2(0.05, H - 0.12), V2(0, H - 0.12)], segments: segs, seamTile: 0.3,
                             material: metal), Xform(translation: V3(0, 0.3, 0)))
            if l == 0 {
                for k in 0..<4 {
                    let a = Float(k) / 4 * 2 * .pi + .pi / 4
                    hexBolt(&m, at: V3(cos(a) * 0.12, 0.32, sin(a) * 0.12), normal: V3(0, 1, 0), size: 0.022, material: metal)
                }
                // hinged base flange gusset plates
                for k in 0..<4 {
                    let a = Float(k) / 4 * 2 * .pi
                    m.add(Prim.extrude([V2(0, 0), V2(0.09, 0), V2(0, 0.22)], depth: 0.008, bevel: 0.002, bevelSegments: 1, material: metal),
                          Xform(translation: V3(cos(a) * 0.065, 0.32, sin(a) * 0.065), rotation: simd_quatf(angle: -a, axis: V3(0, 1, 0))))
                }
            }
            rig.base[l] = m
        }
        let top = H + 0.3 - 0.12
        rig.part("head", pivot: V3(0, top, 0), joint: .hinge(axis: V3(0, 1, 0), -180...180))
        rig.part("sock", parent: "head", pivot: V3(hoopX, top + 0.05, 0), joint: .hinge(axis: V3(0, 0, 1), -80...0))
        // head: swivel collar, arm, hoop and a small finial
        rig.add(Prim.cylinder(radius: 0.07, height: 0.2, bevel: 0.01, segments: 16, material: metal), Xform(translation: V3(0, top - 0.04, 0)), to: "head")
        rig.add(Prim.tube([V3(0, top + 0.05, 0), V3(hoopX, top + 0.05, 0)], radii: [0.025, 0.025], sides: 8, seamTile: 0.2, material: metal), to: "head")
        rig.add(Prim.lathe([V2(0.03, 0), V2(0.03, 0.06), V2(0, 0.12)], segments: 12, seamTile: 0.2, material: metal),
                Xform(translation: V3(0, top + 0.16, 0)), to: "head")
        // sock: banded frustum along +X from the hoop, inner face too, hoop and tail rings
        let toX = simd_quatf(degrees: -90, axis: V3(0, 0, 1))
        let o = V3(hoopX, top + 0.05, 0)
        for l in 0..<2 {
            let segs = l == 0 ? 28 : 12
            for b in 0..<bands {
                let t0 = Float(b) / Float(bands), t1 = Float(b + 1) / Float(bands)
                var prof: [V2] = []
                for k in 0...3 {
                    let t = t0 + (t1 - t0) * Float(k) / 3
                    // fabric pinches slightly between the sewn bands
                    let pinch: Float = (k == 0 || k == 3) ? 0.985 : 1
                    prof.append(V2((throat + (tail - throat) * t) * pinch, t * sockLength))
                }
                let mat = b % 2 == 0 ? orange : white
                var s = Prim.lathe(prof, segments: segs, seamTile: 0.5, material: mat)
                if l == 0 {
                    // wind ripple: low-amplitude flutter growing toward the tail
                    let ph = rng.float(0...6)
                    s.displace { p, _ in 0.012 * (p.y / sockLength) * sin(p.y * 6 + atan2(p.z, p.x) * 3 + ph) }
                }
                rig.add(s, Xform(translation: o, rotation: toX), to: "sock", lods: l...l)
                rig.add(s.flipped(), Xform(translation: o, rotation: toX), to: "sock", lods: l...l)
            }
        }
        for (x, r) in [(Float(0), throat), (sockLength, tail)] {
            rig.add(Prim.torus(major: r + 0.006, minor: 0.012, segments: 24, sides: 6, material: metal),
                    Xform(translation: o + V3(x, 0, 0), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))), to: "sock")
        }
        rig.states = [RigState("breeze", ["sock": -28]), RigState("gale", ["sock": 0]), RigState("calm", ["sock": -76])]
        groundAO(&rig, height: 0.3)
        return rig
    }
}
