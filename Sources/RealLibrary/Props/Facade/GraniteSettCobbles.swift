import simd
import Foundation

/// Granite sett cobbles: architectural facade customizer, Victorian. 200 x 100 mm split-face granite
/// setts in half-bond stretcher courses on a sand bed with sand-swept joints; tops worn smooth, mixed
/// grey and pink-grey tones, one sett sunk 6 mm.
public struct GraniteSettCobbles: RealAsset {
    public static let id = "granite-sett-cobbles"
    public static let summary = "Granite sett cobbles, 2 x 2 m: Victorian 200 x 100 mm split granite setts in half-bond courses, sand joints, worn tops."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 1.0, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.12, 2.0)
    /// Setts per course (x) and courses (z); pitches divide the tile exactly so it repeats.
    public var perCourse = 10
    public var courses = 18
    /// Joint width (m).
    public var joint: Float = 0.012
    /// Granite tones (sRGB hex).
    public var tones: [UInt32] = [0x7C7B7D, 0x6C6B6E, 0x8D8784, 0x75706F, 0x5F5F63]
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hx = size.x / 2, hz = size.z / 2
        let px = size.x / Float(perCourse), pz = size.z / Float(courses)
        PTK.bed(&m, w: size.x, d: size.z, top: size.y - 0.022, PTK.tint("ground.sand", 0x8A7E6A))
        let sunk = (rng.int(0...(perCourse - 1)), rng.int(0...(courses - 1)))
        for j in 0..<courses {
            let z = -hz + pz * (Float(j) + 0.5)
            let off: Float = j % 2 == 0 ? 0 : px / 2
            for i in 0..<perCourse {
                var r = rng.fork(j * 97 + i)
                let x0 = -hx + px * (Float(i) + 0.5) + off
                for (x, w) in PTK.wrap(x0, px, half: hx) {
                    let h = 0.1 * r.float(0.94...1.04)
                    let top = size.y - r.float(0...0.006) - ((i, j) == sunk ? 0.006 : 0)
                    let sz = V3(w - joint - r.float(0...0.006), h, pz - joint - r.float(0...0.005))
                    PTK.block(&m, V3(x, top - h / 2, z), sz, exponent: 6, subdivisions: 2, relief: 0.03,
                              key: PTK.tint("stone.granite-paver", r.pick(tones)), yaw: r.float(-1.5...1.5), tilt: r.float(-1.2...1.2),
                              seed: UInt32(truncatingIfNeeded: r.int(0...100_000)))
                }
            }
        }
        return PTK.finish(&m, id: Self.id, size: size, cap: PTK.tint("stone.granite-paver", tones[0]))
    }
}
