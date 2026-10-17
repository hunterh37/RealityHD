import simd
import Foundation

/// Wall towel bar, 66 x 20 x 10 cm: a 60 cm polished chrome bar on two stand-off arms with domed wall rosettes, end
/// holders with set screws, and a terry hand towel folded over the bar with a woven border band. Authored with the wall
/// face at z = -depth / 2, bar centre 17 cm above the lowest point of the towel.
public struct TowelBar: RealAsset {
    public static let id = "towel-bar"
    public static let summary = "Towel bar: 60 cm chrome bar on two wall-plate brackets with a terry hand towel folded over it."
    public static let tags = ["prop", "floorplan", "bathroom", "wall", "metal", "fabric", "interior"]
    public static let budget = 9600
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 12, distance: 1.3, studio: true)

    /// Overall size in meters (x width over the rosettes, y height from towel hem to bar top, z depth from wall).
    public var size = V3(0.66, 0.2, 0.1)
    /// Bar and bracket metal.
    public var chrome: MaterialKey = "metal.chrome"
    /// Towel cloth (terry read from a coarse weave).
    public var cloth: MaterialKey = "fabric.canvas:EEE9DD"
    /// Towel border band.
    public var band: MaterialKey = "fabric.curtain:3F6A8C"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let wallZ = -size.z / 2
        let armX = size.x / 2 - 0.030                 // arm centre to the left and right of centre
        let barY: Float = 0.1905
        let barR: Float = 0.0095
        let barZ = wallZ + 0.070                      // bar axis stands 70 mm off the wall
        // Bar: slightly short of the holders, ends hidden inside them.
        m.add(Prim.cylinder(radius: barR, height: 2 * armX, bevel: 0.0006, segments: 24, material: chrome),
              Xform(translation: V3(-armX, barY, barZ), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
        for s: Float in [-1, 1] {
            let x = s * armX
            // Rosette: a low dome with a stepped foot, backed by a thin base plate.
            let rose: [V2] = Profile.smooth([V2(0, wallZ), V2(0.0265, wallZ), V2(0.0265, wallZ + 0.0025), V2(0.0245, wallZ + 0.0045), V2(0.0200, wallZ + 0.0095),
                                             V2(0.0150, wallZ + 0.0132), V2(0.0115, wallZ + 0.0140), V2(0.0, wallZ + 0.0142)], per: 4)
            m.add(Prim.lathe(rose, segments: 32, seamTile: 0.1, material: chrome),
                  Xform(translation: V3(x, barY, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            // Arm: round post from the rosette out to the holder, with a small swept bend.
            let arm = catmull([V3(x, barY, wallZ + 0.012), V3(x, barY, wallZ + 0.040), V3(x, barY, barZ - 0.020), V3(x, barY, barZ - 0.0105)], per: 4)
            m.add(Prim.tube(arm, radii: arm.map { _ in 0.0080 }, sides: 12, seamTile: 0.05, material: chrome, capEnd: true))
            // End holder: a barrel running along X that grips the bar end, with rounded outer face.
            m.add(Prim.cylinder(radius: 0.0135, height: 0.026, bevel: 0.004, segments: 24, material: chrome),
                  Xform(translation: V3(x - 0.013, barY, barZ), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
            // Set screw boss on the underside of the holder, hex socket dot.
            m.add(Prim.cylinder(radius: 0.0034, height: 0.0045, bevel: 0.0007, segments: 12, material: chrome),
                  Xform(translation: V3(x, barY - 0.0130, barZ), rotation: simd_quatf(degrees: 180, axis: V3(1, 0, 0))))
            m.add(cuboid(V3(0.0018, 0.0006, 0.0018), material: "metal.steel"), Xform(translation: V3(x, barY - 0.0173, barZ)))
        }
        // Folded hand towel: one ribbon swept from the front hem, up and over the bar, down the back.
        let tw: Float = 0.40
        let tx = rng.float(-0.02...0.02)
        let thick: Float = 0.0115
        let hemFront: Float = 0.019, hemBack: Float = 0.034
        let r = barR + thick / 2 + 0.0007
        var path: [V3] = []
        let nF = 7
        for i in 0...nF {
            let t = Float(i) / Float(nF)
            let y = hemFront + (barY - hemFront) * t
            let z = barZ + r + 0.0045 * sin(t * .pi) + 0.0025 * sin(t * 9 + 1.2) * (1 - t)       // soft sag away from the bar
            path.append(V3(tx, y, z))
        }
        for k in 1..<10 {                                              // wrap over the top
            let a = Float(k) / 10 * .pi
            path.append(V3(tx, barY + sin(a) * r, barZ + cos(a) * r))
        }
        let nB = 7
        for i in 0...nB {
            let t = Float(i) / Float(nB)
            let y = barY - (barY - hemBack) * t
            let z = barZ - r - 0.0030 * sin(t * .pi) - 0.0030 * sin(t * 7)
            path.append(V3(tx, y, z))
        }
        let ribbon = Shape2D.rounded([V2(-tw / 2, -thick / 2), V2(tw / 2, -thick / 2), V2(tw / 2, thick / 2), V2(-tw / 2, thick / 2)], radius: 0.0035, segments: 2)
        var towel = Prim.sweep(ribbon, along: path, up: V3(1, 0, 0), caps: true, material: cloth)
        let ph = rng.float(0...6)
        let crease0 = rng.float(-1...1)
        towel.deform { p in       // gentle cloth waviness across the width, strongest low on the hang
            let low = max(0, 1 - p.y / barY)
            let side: Float = p.z > barZ ? 1 : -1
            // Hem hangs a little uneven: one corner rides up, and a soft diagonal crease crosses the lower third.
            let skew = ((p.x - tx) / tw + 0.5) * 0.012 * low
            let crease = 0.0016 * low * exp(-pow((p.x - tx) * 0.9 + (p.y - 0.07) * 3.2 - 0.02 * crease0, 2) * 260)
            return V3(p.x, p.y + skew, p.z + side * (0.0011 * low * sin((p.x - tx) * 38 + ph) + crease))
        }
        m.add(towel)
        // Woven border: a band across the front and back hang near the hem.
        for (front, y0) in [(true, Float(0.052)), (false, Float(0.062))] {
            let t = (y0 - hemFront) / (barY - hemFront)
            let zf = barZ + r + 0.0045 * sin(t * .pi) + 0.0025 * sin(t * 9 + 1.2) * (1 - t) + thick / 2 + 0.0008
            let z = front ? zf : barZ - r - 0.0030 * sin(((barY - y0) / (barY - hemBack)) * .pi) - 0.0030 * sin(((barY - y0) / (barY - hemBack)) * 7) - thick / 2 - 0.0008
            m.add(Prim.roundedBox(V3(tw - 0.002, 0.010, 0.0012), radius: 0.0004, bevelSegments: 1, material: band), Xform(translation: V3(tx, y0, z)))
            m.add(Prim.roundedBox(V3(tw - 0.002, 0.0035, 0.0012), radius: 0.0004, bevelSegments: 1, material: band), Xform(translation: V3(tx, y0 + 0.016, z)))
        }
        // Towel hem edge: stitch row along the bottom (front only).
        for i in 0..<18 {
            let sx = tx - tw / 2 + 0.020 + Float(i) * (tw - 0.040) / 17
            m.add(cuboid(V3(0.010, 0.0006, 0.0006), material: "fabric.canvas:CFC8B6"), Xform(translation: V3(sx, hemFront + 0.012, barZ + r + 0.0015 + thick / 2 + 0.0003)))
        }
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y, 0)))
        return LODModel(m)
    }
}
