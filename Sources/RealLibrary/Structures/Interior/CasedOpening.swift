import simd
import Foundation

/// Cased doorway without a leaf, 0.94 m x 2.1 m x 0.15 m overall: split jamb legs and head across a 109 mm wall, flat 57 mm casing with
/// bead and rounded edges on both wall faces, a deeper head cap, plinth blocks at the floor with scuffs, and a hardwood floor
/// transition strip. `arch` swaps the flat head for a segmental arch (jamb soffit, casing band and cap built from short mitred
/// segments) that keeps the overall height. Origin at the bottom center of the opening.
public struct CasedOpening: RealAsset {
    public static let id = "cased-opening"
    public static let summary = "Cased doorway with no leaf: split jamb, flat casing with bead and back band on both faces, head cap, plinth blocks; optional arched head."
    public static let tags = ["structure", "floorplan", "home", "wood", "interior", "door"]
    public static let budget = 5000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 26, elevation: 6, distance: 1.2, studio: true)

    public var width: Float = 0.94
    public var height: Float = 2.1
    public var depth: Float = 0.15
    /// Segmental arch head instead of the flat head.
    public var arch = false
    /// Rise of the arch above the springline (m).
    public var archRise: Float = 0.15
    public var paint: MaterialKey = "wood.painted-shaker:D6CFC0"
    public var plinthPaint: MaterialKey = "wood.painted-shaker-worn:D6CFC0"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var levels: [Model] = []
        for lod in 0..<2 {
            var m = Model(name: Self.id)
            var c = DoorKit.Casing(openW: 0, openH: 0, wallT: depth - 0.041, material: paint)
            c.openW = width - 2 * (c.reveal + c.casingW + c.capOver)
            c.openH = height - c.reveal - c.casingW - c.capH - (arch ? archRise : 0)
            c.withStop = false
            c.withHead = !arch
            c.withHeadJamb = !arch
            c.build(&m, detail: lod == 0)
            let hx = c.openW / 2, D = c.wallT

            if arch {
                let rise = archRise
                let R = (hx * hx + rise * rise) / (2 * rise)
                let cy = c.openH + rise - R
                let n = lod == 0 ? 18 : 10
                // band(r0, radial, depth, z, material): arc band between radii r0 and r0 + radial.
                func band(_ r0: Float, _ radial: Float, _ thick: Float, z: Float, mat: MaterialKey, edge: Float) {
                    let rOut = r0 + radial
                    let half = asin(min(0.999, (hx + c.reveal + c.casingW + c.capOver) / max(rOut, 0.01)))
                    let a0 = Float.pi / 2 + half, a1 = Float.pi / 2 - half
                    let dθ = (a1 - a0) / Float(n)
                    for i in 0..<n {
                        let am = a0 + (Float(i) + 0.5) * dθ
                        let rm = r0 + radial / 2
                        let len = 2 * rOut * tan(abs(dθ) / 2) * 1.04
                        let center = V3(rm * cos(am), cy + rm * sin(am), z)
                        let p = DoorKit.box(V3(len, radial, thick), center, mat, r: edge)
                        m.add(p.0, Xform(translation: center, rotation: simd_quatf(angle: am - Float.pi / 2, axis: V3(0, 0, 1))))
                    }
                }
                band(R, c.jambT, D, z: 0, mat: paint, edge: 0)                                   // soffit across the wall
                for sz: Float in [-1, 1] {
                    let zc = sz * (D / 2 + c.casingT / 2) - sz * 0.0005
                    band(R + c.reveal, c.casingW, c.casingT, z: zc, mat: paint, edge: lod == 0 ? 0.0025 : 0)
                    band(R + c.reveal + c.casingW, c.capH, c.casingT + 0.003, z: zc + sz * 0.0015, mat: paint, edge: lod == 0 ? 0.003 : 0)
                }
            }

            // Plinth blocks at the foot of each casing leg, with a scuff on the front faces.
            let px = hx + c.reveal + c.casingW / 2
            for sx: Float in [-1, 1] {
                for sz: Float in [-1, 1] {
                    let zc = sz * (D / 2 + 0.01)
                    let b = DoorKit.box(V3(c.casingW, 0.115, 0.021), V3(sx * px, 0.0575, zc), plinthPaint, r: 0.003)
                    m.add(b.0, b.1)
                    if lod == 0 {
                        let cap = DoorKit.box(V3(c.casingW + 0.004, 0.006, 0.023), V3(sx * px, 0.118, zc), plinthPaint, r: 0.0015)
                        m.add(cap.0, cap.1)
                        if sx * sz > 0 {
                            let sc = DoorKit.box(V3(0.03, 0.012, 0.0006), V3(sx * px + 0.004, 0.035, sz * (D / 2 + 0.0205 + 0.0003)), "decal.rubber-scuff", r: 0)
                            m.add(sc.0, sc.1)
                        }
                    }
                }
            }
            // Floor transition strip between the rooms.
            let strip = DoorKit.box(V3(c.openW, 0.004, D), V3(0, 0.002, 0), "wood.oak", r: 0.0012)
            m.add(strip.0, strip.1)
            groundAO(&m, height: 0.12)
            levels.append(m)
        }
        return LODModel(levels: levels, switchDistances: [8])
    }
}
