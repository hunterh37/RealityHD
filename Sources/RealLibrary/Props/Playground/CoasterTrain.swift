import simd
import Foundation

/// Three-car roller coaster train, each car 3 m long and 1.6 m wide: lofted open-cockpit shells (64 stations at LOD0) with rounded
/// noses in red clearcoat paint, two rows of two leather seats per car with chrome lap bars, steel chassis, two bogies per car (each
/// with running, side and up-stop wheel sets for a 1.2 m tubular rail pair), couplers, a chrome bumper and two headlights on the lead car.
/// Origin at the centre of the lead car with the rail top at y = 0, forward +Z, up +Y; the other cars trail toward -Z (pitch 3.25 m).
/// Joints (set with `setJoints`): `wheels` 0...1 (every wheel turns one revolution), `bars` 0...1 (lap bars closed to open),
/// `pitch` -1...1 (whole train pitches 45 degrees about the lead car centre, +1 nose up) and `bank` -1...1 (whole train rolls 60 degrees
/// about the rail axis, +1 banks left toward +X).
public struct CoasterTrain: RealArticulated {
    public static let id = "coaster-train"
    public static let summary = "Three-car roller coaster train: red clearcoat lofted car shells, leather seats, chrome lap bars, steel bogies with running, side and up-stop wheels, headlights, joints wheels, bars, pitch, bank."
    public static let tags = ["prop", "amusement", "coaster", "vehicle", "playground", "metal", "outdoor", "articulated"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 12, distance: 1.05, studio: true)

    /// Car body paint (red clearcoat, sRGB hex suffix).
    public var paint: MaterialKey = "paint.car-clearcoat:C4121C"
    /// Lap bars, bumper and wheel hub bars.
    public var chrome: MaterialKey = "metal.chrome"
    /// Chassis spines and couplers.
    public var steel: MaterialKey = "metal.steel"
    /// Bogie frames and struts.
    public var frame: MaterialKey = "metal.anodized-gunmetal"
    /// Running wheel tread.
    public var tire: MaterialKey = "rubber.silicone-gray"
    /// Side and up-stop wheels.
    public var guide: MaterialKey = "plastic.black"
    /// Seat cushions and backs.
    public var seat: MaterialKey = "leather.black"
    /// Headlight lenses.
    public var lamp: MaterialKey = "emissive.lamp-white"
    public init() {}

    static let cars = 3
    static let carPitch: Float = 3.25
    static let halfLength: Float = 1.5
    /// Row centres inside a car (z from the car centre).
    static let rowZ: [Float] = [-0.55, 0.25]
    /// Cockpit floor height at full depth.
    static let floorY: Float = 0.61

    static func ss(_ a: Float, _ b: Float, _ x: Float) -> Float {
        let t = min(max((x - a) / (b - a), 0), 1)
        return t * t * (3 - 2 * t)
    }

    /// One shell cross-section (CCW in XY, seen from +Z) at station u in -1...1 (rear to front), laid at height z.
    /// 16 points: outer skin from the keel up the right side, rim lip, inner wall, floor, then mirrored.
    static func shellRing(_ u: Float, z: Float) -> [V3] {
        let front = u >= 0
        let p: Float = front ? 2.4 : 4
        let w = max(0.01, 0.8 * pow(max(0, 1 - pow(abs(u), p)), 1 / p))
        let sb = front ? ss(0.55, 1, u) : ss(-0.6, -1, u)
        let sr = front ? ss(0.6, 1, u) : ss(-0.7, -1, u)
        let yb: Float = front ? 0.38 + 0.25 * sb * sb : 0.38 + 0.08 * sb * sb
        let yr: Float = front ? 0.95 - 0.25 * sr * sr : 0.95 - 0.12 * sr * sr
        let cav: Float = front ? ss(0.78, 0.5, u) : ss(-0.97, -0.8, u)
        let hgt = yr - yb
        let dep = 0.34 * cav
        let yf = yr - dep
        let wall = min(0.07, w * 0.5), cx = min(0.04, w * 0.3)
        let wi = w - wall
        let half: [V2] = [
            V2(0.55 * w, yb), V2(0.96 * w, yb + 0.14 * hgt), V2(w + 0.012, yb + 0.6 * hgt), V2(w - 0.01, yr),
            V2(w - cx, yr + 0.03), V2(wi, yr), V2(wi, yf + 0.08 * dep),
        ]
        var pts: [V2] = [V2(0, yb)] + half + [V2(0, yf + 0.05 * (1 - cav))]
        pts += half.reversed().map { V2(-$0.x, $0.y) }
        return pts.map { V3($0.x, $0.y, z) }
    }

    public func rig(seed: UInt64) -> Rig {
        _ = seed   // deterministic: no randomness, every car identical
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [20])
        let rotZ90 = simd_quatf(degrees: 90, axis: V3(0, 0, 1))     // cylinder +Y -> -X
        let rotX90 = simd_quatf(degrees: 90, axis: V3(1, 0, 0))     // lathe +Y -> +Z
        var lod = 0
        func seg(_ n: Int) -> Int { lod == 0 ? n : max(8, n * 2 / 3) }
        func sub(_ n: Int) -> Int { lod == 0 ? n : max(2, n - 1) }
        func sides(_ n: Int) -> Int { lod == 0 ? n : max(5, n * 2 / 3) }
        func put(_ s: Surface, _ x: Xform = .identity, _ part: String) { rig.add(s, x, to: part, lods: lod...lod) }
        func at(_ p: V3, _ q: simd_quatf = .identity) -> Xform { Xform(translation: p, rotation: q) }

        let n = Self.cars
        let gauge: Float = 0.6                      // rail centre offset
        let wheelX = V3(1, 0, 0), wheelY = V3(0, 1, 0)

        // Control joints (no geometry).
        rig.part("wheels", pivot: V3(0, 0.15, 0), joint: .hinge(axis: wheelX, 0...1, duration: 1.2))
        rig.part("bars", pivot: V3(0, 0.65, 0), joint: .hinge(axis: wheelX, 0...1, duration: 1.0))
        rig.part("pitch", pivot: V3(0, 0, 0), joint: .hinge(axis: wheelX, -1...1, duration: 1.4))
        rig.part("bank", pivot: V3(0, 0, 0), joint: .hinge(axis: V3(0, 0, 1), -1...1, duration: 1.4))
        // Whole-train pitch and bank, then the car geometry.
        rig.part("train", pivot: V3(0, 0, 0), joint: Joint(.revolute, axis: V3(-1, 0, 0), range: -45...45, mimic: .init("pitch", ratio: 45)))
        rig.part("trainBank", parent: "train", pivot: V3(0, 0, 0), joint: Joint(.revolute, axis: V3(0, 0, -1), range: -60...60, mimic: .init("bank", ratio: 60)))
        rig.part("chassis", parent: "trainBank", pivot: V3(0, 0, 0), joint: .fixed)

        var bogies: [(id: String, z: Float)] = []
        for c in 0..<n {
            let zc = -Float(c) * Self.carPitch
            for (tag, dz) in [("f", Float(0.95)), ("r", Float(-0.95))] { bogies.append(("\(c)\(tag)", zc + dz)) }
        }
        for b in bogies {
            let z = b.z
            rig.part("run\(b.id)", parent: "chassis", pivot: V3(0, 0.15, z), joint: Joint(.revolute, axis: wheelX, range: 0...360, mimic: .init("wheels", ratio: 360)))
            rig.part("stop\(b.id)", parent: "chassis", pivot: V3(0, -0.16, z), joint: Joint(.revolute, axis: wheelX, range: -360...0, mimic: .init("wheels", ratio: -360)))
            rig.part("sideL\(b.id)", parent: "chassis", pivot: V3(0.47, -0.045, z), joint: Joint(.revolute, axis: wheelY, range: 0...360, mimic: .init("wheels", ratio: 360)))
            rig.part("sideR\(b.id)", parent: "chassis", pivot: V3(-0.47, -0.045, z), joint: Joint(.revolute, axis: wheelY, range: -360...0, mimic: .init("wheels", ratio: -360)))
        }
        for c in 0..<n {
            let zc = -Float(c) * Self.carPitch
            for (row, rz) in Self.rowZ.enumerated() {
                // Hinge at the floor ahead of the row; positive degrees swing the bar forward and up.
                rig.part("bar\(c)\(row)", parent: "chassis", pivot: V3(0, 0.65, zc + rz + 0.36), joint: Joint(.revolute, axis: wheelX, range: 0...80, mimic: .init("bars", ratio: 80)))
            }
        }

        for l in 0..<2 {
            lod = l
            let stations = lod == 0 ? 64 : 24
            for c in 0..<n {
                let zc = -Float(c) * Self.carPitch
                // Lofted shell, stations denser toward the nose and tail.
                var rings: [[V3]] = []
                for i in 0..<stations {
                    let u = sin((Float(i) / Float(stations - 1) - 0.5) * .pi)
                    rings.append(Self.shellRing(u, z: zc + u * Self.halfLength))
                }
                put(Prim.loft(rings, capStart: true, capEnd: true, material: paint), .identity, "chassis")
                // Steel spine under the shell.
                put(cuboid(V3(0.5, 0.08, 2.5), material: steel), at(V3(0, 0.33, zc)), "chassis")
                // Seats and lap bars.
                for (row, rz) in Self.rowZ.enumerated() {
                    let zr = zc + rz
                    for sx: Float in [-0.3, 0.3] {
                        put(Prim.superellipsoid(V3(0.46, 0.16, 0.5), exponent: 4, subdivisions: sub(3), material: seat), at(V3(sx, Self.floorY + 0.08, zr)), "chassis")
                        put(Prim.superellipsoid(V3(0.46, 0.6, 0.14), exponent: 4, subdivisions: sub(2), material: seat),
                            at(V3(sx, Self.floorY + 0.42, zr - 0.25), simd_quatf(degrees: -8, axis: V3(1, 0, 0))), "chassis")
                    }
                    let bar = "bar\(c)\(row)"
                    let cross = [-0.34, -0.17, 0, 0.17, 0.34].map { (x: Float) -> V3 in V3(x, 0.88, zr + 0.2 + 0.05 * (x / 0.34) * (x / 0.34)) }
                    put(Prim.tube(cross, radii: cross.map { _ in 0.025 }, sides: sides(8), seamTile: 0.1, material: chrome), .identity, bar)
                    let post = [V3(0, 0.65, zr + 0.36), V3(0, 0.78, zr + 0.31), V3(0, 0.88, zr + 0.22)]
                    put(Prim.tube(post, radii: [0.03, 0.03, 0.03], sides: sides(8), seamTile: 0.1, material: chrome), .identity, bar)
                }
            }
            // Couplers between cars.
            for c in 0..<(n - 1) {
                let z1 = -Float(c) * Self.carPitch - 1.2, z2 = -Float(c + 1) * Self.carPitch + 1.2
                let path = [V3(0, 0.33, z1), V3(0, 0.33, (z1 + z2) / 2), V3(0, 0.33, z2)]
                put(Prim.tube(path, radii: [0.035, 0.035, 0.035], sides: sides(8), seamTile: 0.1, material: steel), .identity, "chassis")
                for z in [z1, z2] { put(cuboid(V3(0.1, 0.1, 0.14), material: frame), at(V3(0, 0.33, z)), "chassis") }
            }
            // Bogies: frame beam, struts, arms, and the three wheel sets.
            for b in bogies {
                let z = b.z
                put(cuboid(V3(1.5, 0.1, 0.34), material: frame), at(V3(0, 0.3, z)), "chassis")
                for sx: Float in [-1, 1] {
                    put(cuboid(V3(0.04, 0.52, 0.2), material: frame), at(V3(sx * 0.68, 0.07, z)), "chassis")
                    put(cuboid(V3(0.04, 0.36, 0.1), material: frame), at(V3(sx * 0.47, 0.13, z)), "chassis")
                }
                for sx: Float in [-1, 1] {
                    let cx = sx * gauge
                    // Running wheel (axis X) with a chrome hub bar so the spin reads.
                    put(Prim.cylinder(radius: 0.15, height: 0.1, bevel: 0.012, segments: seg(14), bevelSegments: 1, material: tire),
                        at(V3(cx + 0.05, 0.15, z), rotZ90), "run\(b.id)")
                    put(cuboid(V3(0.016, 0.18, 0.03), material: chrome), at(V3(cx + sx * 0.056, 0.15, z)), "run\(b.id)")
                    // Up-stop wheel under the rail head.
                    put(Prim.cylinder(radius: 0.07, height: 0.06, bevel: 0.01, segments: seg(10), bevelSegments: 1, material: guide),
                        at(V3(cx + 0.03, -0.16, z), rotZ90), "stop\(b.id)")
                }
                // Side wheels (axis Y) on the inner rail faces.
                put(Prim.cylinder(radius: 0.085, height: 0.05, bevel: 0.01, segments: seg(10), bevelSegments: 1, material: guide),
                    at(V3(0.47, -0.045 - 0.025, z)), "sideL\(b.id)")
                put(Prim.cylinder(radius: 0.085, height: 0.05, bevel: 0.01, segments: seg(10), bevelSegments: 1, material: guide),
                    at(V3(-0.47, -0.045 - 0.025, z)), "sideR\(b.id)")
            }
            // Lead car: chrome bumper under the nose and two headlight lenses.
            let bumper = [-0.4, -0.27, -0.13, 0, 0.13, 0.27, 0.4].map { (x: Float) -> V3 in V3(x, 0.56, 1.52 - 0.2 * (x / 0.4) * (x / 0.4)) }
            put(Prim.tube(bumper, radii: bumper.map { _ in 0.03 }, sides: sides(8), seamTile: 0.1, material: chrome), .identity, "chassis")
            for sx: Float in [-0.14, 0.14] {
                put(Prim.lathe([V2(0, 0), V2(0.06, 0), V2(0.06, 0.015), V2(0.045, 0.035), V2(0, 0.04)], segments: seg(12), material: lamp),
                    at(V3(sx, 0.665, 1.465), rotX90), "chassis")
            }
        }

        rig.lights = [RigLight(name: "headlight", kind: .spot(inner: 15, outer: 40), part: "chassis", position: V3(0, 0.68, 1.7), direction: V3(0, -0.05, 1),
                               color: V3(1, 0.95, 0.85), intensity: 2500, attenuationRadius: 25)]
        rig.states = [
            RigState("rest"),
            RigState("bars-open", ["bars": 1]),
            RigState("wheels-half", ["wheels": 0.5]),
            RigState("climb", ["pitch": 1, "wheels": 0.5]),
            RigState("drop", ["pitch": -1, "wheels": 0.5]),
            RigState("bank-left", ["bank": 1]),
            RigState("bank-right", ["bank": -1]),
        ]
        groundAO(&rig, height: 0.3)
        return rig
    }
}
