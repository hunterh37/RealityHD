import simd
import Foundation

/// Ferris wheel, 40 m rim diameter on twin A-frame legs, hub at 22 m, 28 spoke pairs, a double rim truss (two lattice rings 2 m apart)
/// with 112 bulb sockets in 28 chase groups, and 20 gondolas that hang upright by counter-rotation.
/// Origin on the ground under the hub axle, axle along X, wheel faces +X (rim plane is YZ), up +Y.
/// Joints (all 0...1 drivers): `turn` (one revolution, gondolas counter-rotate to stay upright), `build` (legs rise 26 m, then
/// spokes, rim bays and their gondolas slide up from below the ground in a staggered order and all arrive at 1), `lights`
/// (bulb groups switch on in a chase around the rim, threshold (k+1)/28) and `sway` (gondola swing, up to 16 degrees each).
/// Parts that assemble slide along +Y with ranges of -50 or -26 m; apps clamp to the range, so before its start a part
/// sits fully underground.
public struct FerrisWheel: RealArticulated {
    public static let id = "ferris-wheel"
    public static let summary = "40 m Ferris wheel: A-frame legs, hub, 28 spokes, double rim truss, 112 emissive bulbs, 20 upright gondolas; joints turn, build, lights, sway."
    public static let tags = ["prop", "fairground", "structure", "outdoor", "articulated", "lights"]
    public static let budget = 14_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 8, distance: 1.25, studio: true)

    /// Rim truss, spokes accents and roofs.
    public var paint: MaterialKey = "metal.painted:F3F1EA"
    /// A-frame legs, hub drum and cross braces.
    public var legPaint: MaterialKey = "metal.painted:B3262E"
    /// Axle, spokes, hangers and flanges.
    public var steel: MaterialKey = "metal.steel"
    /// Gondola glazing.
    public var glass: MaterialKey = "glass.tinted"
    /// Bulbs when `lights` has not reached their group.
    public var bulbOff: MaterialKey = "glass.frosted"
    /// Bulbs lit.
    public var bulbOn: MaterialKey = "emissive.bulb"
    /// Footings under the legs.
    public var footing: MaterialKey = "concrete.rough"
    /// Gondola body colours, dealt around the wheel from the seed.
    public var gondolaColors: [MaterialKey] = [
        "metal.painted:D9262E", "metal.painted:F2B21B", "metal.painted:2A6FB5",
        "metal.painted:2E9A5B", "metal.painted:E26A2C", "metal.painted:8E3FA8",
    ]
    public init() {}

    private static let hubY: Float = 22
    private static let radius: Float = 20
    private static let ringX: Float = 1.0
    private static let bays = 28
    private static let gondolas = 20
    private static let pivotR: Float = 19.0
    private static let lift: Float = 26
    private static let drop: Float = 50

    private static var hub: V3 { V3(0, hubY, 0) }

    /// Point on the wheel: radius r, angle th (0 at the top, toward +Z), axle offset x.
    private static func P(_ r: Float, _ th: Float, _ x: Float) -> V3 { V3(x, hubY + r * cos(th), r * sin(th)) }
    private static func radial(_ th: Float) -> V3 { V3(0, cos(th), sin(th)) }

    /// Gondola in pivot space (origin on the hanger axle at the inner rim, upright): axle between the rings, hanger, roof, glass cage, body.
    /// Built once per colour and reused for all gondolas of that colour.
    private func gondola(body: MaterialKey, lod l: Int) -> [Surface] {
        let ax = Prim.tube([V3(-Self.ringX, 0, 0), V3(Self.ringX, 0, 0)], radii: [0.08, 0.08], sides: [5, 4][l], seamTile: 0.5, material: steel)
        let hanger = Prim.tube([V3(0, 0, 0), V3(0, -0.6, 0)], radii: [0.07, 0.07], sides: [4, 3][l], seamTile: 0.5, material: steel)
        var roof = Prim.superellipsoid(V3(2.3, 0.3, 2.1), exponent: 4, subdivisions: [2, 1][l], material: paint)
        roof = roof.transformed(Xform(translation: V3(0, -0.72, 0)))
        let cage = Prim.superellipsoid(V3(1.9, 1.0, 1.7), exponent: 8, subdivisions: [1, 1][l], material: glass)
            .transformed(Xform(translation: V3(0, -1.27, 0)))
        let hull = Prim.superellipsoid(V3(2.05, 0.55, 1.85), exponent: 5, subdivisions: [3, 2][l], material: body)
            .transformed(Xform(translation: V3(0, -1.95, 0)))
        return [ax, hanger, roof, cage, hull]
    }

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [150])
        var rng = SeededRNG(seed: seed &* 2654435761 &+ 71)
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)
        let H = Self.hub
        let nb = Self.bays
        let dBay = 2 * Float.pi / Float(nb)
        let half = dBay / 2

        // Drivers first so mimics resolve.
        _ = rig.part("turn", pivot: .zero, joint: .hinge(axis: X, 0...1, duration: 8))
        _ = rig.part("build", pivot: .zero, joint: .hinge(axis: X, 0...1, duration: 4))
        _ = rig.part("lights", pivot: .zero, joint: .hinge(axis: X, 0...1, duration: 1.4))
        _ = rig.part("sway", pivot: .zero, joint: .hinge(axis: X, 0...1, duration: 1.6))

        // Everything above ground rides `lift`; legs and axle belong to it, the wheel turns inside it.
        _ = rig.part("lift", pivot: H, joint: Joint(.prismatic, axis: Y, range: -Self.lift...0, mimic: .init("build", ratio: Self.lift, offset: -Self.lift)))
        _ = rig.part("wheel", parent: "lift", pivot: H, joint: Joint(.revolute, axis: X, range: 0...360, mimic: .init("turn", ratio: 360)))

        // Staggered slide-in: value = -drop * (1 - build) / (1 - start), reaching 0 exactly at build 1.
        func slide(_ start: Float) -> Joint.Mimic {
            let k = Self.drop / (1 - start)
            return .init("build", ratio: k, offset: -k)
        }

        for k in 0..<nb {
            _ = rig.part("spoke\(k)", parent: "wheel", pivot: H,
                         joint: Joint(.prismatic, axis: Y, range: -Self.drop...0, mimic: slide(0.15 + 0.45 * Float(k) / Float(nb - 1))))
        }
        for k in 0..<nb {
            _ = rig.part("rim\(k)", parent: "wheel", pivot: H,
                         joint: Joint(.prismatic, axis: Y, range: -Self.drop...0, mimic: slide(0.5 + 0.35 * Float(k) / Float(nb - 1))))
            _ = rig.part("bulb\(k)", parent: "rim\(k)", pivot: H, joint: .fixed, options: 2)
            rig.optionLinks.append(RigOptionLink(part: "bulb\(k)", joint: "lights", thresholds: [Float(k + 1) / Float(nb)]))
        }

        // Gondolas: hang from the bay nearest their angle; counter-rotate against the wheel, then swing.
        var gondolaParts: [(String, String, V3)] = []
        let colourShift = rng.int(0...(gondolaColors.count - 1))
        for j in 0..<Self.gondolas {
            let th = 2 * Float.pi * Float(j) / Float(Self.gondolas)
            let bay = Int((th / dBay).rounded()) % nb
            let pivot = Self.P(Self.pivotR, th, 0)
            let sign: Float = j % 2 == 0 ? 1 : -1
            let amp = rng.float(8...16) * sign
            _ = rig.part("gc\(j)", parent: "rim\(bay)", pivot: pivot,
                         joint: Joint(.revolute, axis: X, range: -360...0, mimic: .init("turn", ratio: -360)))
            _ = rig.part("gs\(j)", parent: "gc\(j)", pivot: pivot,
                         joint: Joint(.revolute, axis: X, range: -45...45, mimic: .init("sway", ratio: amp)))
            gondolaParts.append(("gs\(j)", gondolaColors[(j + colourShift) % gondolaColors.count], pivot))
        }

        for l in 0..<2 {
            let lod = l...l
            let chordSides = [6, 4][l], innerSides = [6, 4][l], diagSides = [4, 3][l], tieSides = [5, 4][l], spokeSides = [6, 4][l]
            let bulbSegs = [6, 4][l]
            let hubSegs = [20, 12][l]

            // Footings (static base, stay on the ground while the frame lifts).
            for s: Float in [-1, 1] {
                rig.base[l].add(Prim.roundedBox(V3(7.6, 0.5, 2.0), radius: 0.2, bevelSegments: 1, material: footing),
                                Xform(translation: V3(0, 0.25, s * 12.0)))
            }

            // Hub drum and flanges (turn with the wheel).
            let toX = simd_quatf(degrees: -90, axis: Z)
            let drum: [V2] = [V2(0, -1.7), V2(1.1, -1.7), V2(1.5, -1.5), V2(1.5, 1.5), V2(1.1, 1.7), V2(0, 1.7)]
            rig.add(Prim.lathe(drum, segments: hubSegs, seamTile: 0.5, material: legPaint), Xform(translation: H, rotation: toX), to: "wheel", lods: lod)
            for s: Float in [-1, 1] {
                let flange: [V2] = [V2(0, -0.12), V2(1.8, -0.12), V2(1.8, 0.12), V2(0, 0.12)]
                rig.add(Prim.lathe(flange, segments: hubSegs, seamTile: 0.5, material: steel),
                        Xform(translation: H + V3(s * Self.ringX, 0, 0), rotation: toX), to: "wheel", lods: lod)
            }

            // Axle and bearings (in the frame).
            rig.add(Prim.tube([H + V3(-3.4, 0, 0), H + V3(3.4, 0, 0)], radii: [0.42, 0.42], sides: [12, 8][l], seamTile: 0.5, material: steel), to: "lift", lods: lod)
            for s: Float in [-1, 1] {
                rig.add(Prim.roundedBox(V3(1.2, 1.6, 1.6), radius: 0.25, bevelSegments: 1, material: legPaint),
                        Xform(translation: H + V3(s * 3.0, 0, 0)), to: "lift", lods: lod)
            }

            // A-frame legs: two per side, splayed along Z, with cross braces and tie beams.
            let legSides = [10, 6][l]
            for sx: Float in [-1, 1] {
                let x = sx * 3.0
                for sz: Float in [-1, 1] {
                    let foot = V3(x, 0.4, sz * 12.0), apex = V3(x, Self.hubY - 0.6, sz * 0.2)
                    let mid = (foot + apex) / 2
                    rig.add(Prim.tube([foot, mid, apex], radii: [0.7, 0.6, 0.5], sides: legSides, seamTile: 0.5, material: legPaint), to: "lift", lods: lod)
                }
                let zb: Float = 12.0 * (1 - 7.0 / 21.6)
                rig.add(Prim.tube([V3(x, 7, -zb), V3(x, 7, zb)], radii: [0.22, 0.22], sides: [6, 4][l], seamTile: 0.5, material: steel), to: "lift", lods: lod)
            }
            for sz: Float in [-1, 1] {
                let zb: Float = sz * 12.0 * (1 - 7.0 / 21.6)
                rig.add(Prim.tube([V3(-3, 7, zb), V3(3, 7, zb)], radii: [0.2, 0.2], sides: [6, 4][l], seamTile: 0.5, material: steel), to: "lift", lods: lod)
            }

            // Spokes: pair per bay from the hub flange to the inner rim chord.
            let rInner = Self.radius - 0.55
            for k in 0..<nb {
                let th = Float(k) * dBay
                for s: Float in [-1, 1] {
                    let a = Self.P(1.7, th, s * Self.ringX), b = Self.P(rInner, th, s * Self.ringX)
                    rig.add(Prim.tube([a, b], radii: [0.08, 0.08], sides: spokeSides, seamTile: 0.5, material: steel), to: "spoke\(k)", lods: lod)
                }
            }

            // Rim bays: outer and inner chord per ring, lacing, one tie, and 4 bulbs.
            let rOuter = Self.radius + 0.55
            let bulbProfile: [V2] = [V2(0.10, 0), V2(0.17, 0.13), V2(0, 0.27)]
            let bulbOffS = Prim.lathe(bulbProfile, segments: bulbSegs, seamTile: 0.3, material: bulbOff)
            let bulbOnS = Prim.lathe(bulbProfile, segments: bulbSegs, seamTile: 0.3, material: bulbOn)
            for k in 0..<nb {
                let th = Float(k) * dBay
                let part = "rim\(k)", bp = "bulb\(k)"
                for s: Float in [-1, 1] {
                    let x = s * Self.ringX
                    rig.add(Prim.tube([Self.P(rOuter, th - half, x), Self.P(rOuter, th, x), Self.P(rOuter, th + half, x)],
                                      radii: [0.13, 0.13, 0.13], sides: chordSides, seamTile: 0.5, material: paint), to: part, lods: lod)
                    rig.add(Prim.tube([Self.P(rInner, th - half, x), Self.P(rInner, th + half, x)],
                                      radii: [0.1, 0.1], sides: innerSides, seamTile: 0.5, material: paint), to: part, lods: lod)
                    let even = k % 2 == 0
                    let da = even ? (th - half, th + half) : (th + half, th - half)
                    rig.add(Prim.tube([Self.P(rOuter, da.0, x), Self.P(rInner, da.1, x)],
                                      radii: [0.05, 0.05], sides: diagSides, seamTile: 0.5, material: paint), to: part, lods: lod)
                    for q: Float in [-0.5, 0.5] {
                        let bt = th + q * half
                        let n = Self.radial(bt)
                        let at = Self.P(rOuter + 0.1, bt, x)
                        let rot = simd_quatf(from: Y, to: n)
                        rig.add(bulbOffS, Xform(translation: at, rotation: rot), to: bp, option: 0, lods: lod)
                        rig.add(bulbOnS, Xform(translation: at, rotation: rot), to: bp, option: 1, lods: lod)
                    }
                }
                rig.add(Prim.tube([Self.P(rOuter, th, -Self.ringX), Self.P(rOuter, th, Self.ringX)],
                                  radii: [0.07, 0.07], sides: tieSides, seamTile: 0.5, material: paint), to: part, lods: lod)
                if l == 0 && k % 4 == 0 {
                    let n = Self.radial(th)
                    rig.lights.append(RigLight(name: "rimLight\(k)", part: bp, option: 1, position: Self.P(rOuter + 0.7, th, 0),
                                               direction: n, color: V3(1.0, 0.72, 0.36), intensity: 3500, attenuationRadius: 28))
                }
            }

            // Gondolas: one mesh per colour, reused for every gondola of that colour.
            var cache: [MaterialKey: [Surface]] = [:]
            for (part, colour, pivot) in gondolaParts {
                let meshes = cache[colour] ?? gondola(body: colour, lod: l)
                cache[colour] = meshes
                for s in meshes { rig.add(s, Xform(translation: pivot), to: part, lods: lod) }
            }
        }

        var lit: [String: Int] = [:]
        for k in 0..<nb { lit["bulb\(k)"] = 1 }
        rig.states = [
            RigState("rest"),
            RigState("assembling", ["build": 0.6]),
            RigState("built", ["build": 1]),
            RigState("lit", ["build": 1, "lights": 1], options: lit),
            RigState("swing", ["build": 1, "lights": 1, "sway": 1], options: lit),
            RigState("turned", ["build": 1, "lights": 1, "turn": 0.25, "sway": 0.5], options: lit),
        ]
        rig.defaultState = "lit"
        return rig
    }
}
