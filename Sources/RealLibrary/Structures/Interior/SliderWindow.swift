import simd
import Foundation

/// Horizontal slider window, 1.2 x 0.9 x 0.15 m: white powder-coated aluminum frame with a two-rail track,
/// fixed left sash, right sash that slides across it, double glazing with spacer and gaskets, pile weatherstrip
/// on the meeting stiles, crescent latch and pull, laminate stool and returns, brushed aluminum exterior sill.
/// Origin at the sill center, thickness on Z, interior toward +Z.
public struct SliderWindow: RealArticulated {
    public static let id = "slider-window"
    public static let summary = "Slider window, 1.2 x 0.9 m: white aluminum frame, fixed and sliding sashes with double glazing, crescent latch; states closed, open."
    public static let tags = ["structure", "floorplan", "interior", "window", "glass", "metal", "articulated"]
    public static let budget = 10_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 8, distance: 1.1, studio: true)

    public var width: Float = 1.2
    public var height: Float = 0.9
    /// Frame and sash coating.
    public var frameMaterial: MaterialKey = "metal.powder-white"
    /// Interior stool and casing return.
    public var trimMaterial: MaterialKey = "laminate.white"
    /// Exterior sill.
    public var sillMaterial: MaterialKey = "metal.aluminum-brushed"
    public var glass: MaterialKey = "glass.clear"
    public var hardware: MaterialKey = "metal.brushed-nickel"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [6])
        let W = width, H = height
        let sillTop: Float = 0.04, jw: Float = 0.05, jz: Float = 0.05
        func box(_ s: V3, _ c: V3, _ m: MaterialKey, r: Float = 0.002, seg: Int = 2) -> (Surface, Xform) { WindowKit.box(s, c, m, r: r, seg: seg) }
        var opening = WindowKit.Opening(ox: 0, y0: 0, y1: 0, jz: jz)
        for l in 0..<2 {
            var m = Model(name: Self.id)
            let seg = l == 0 ? 2 : 1
            let s = WindowKit.surround(W: W, H: H, sillTop: sillTop, jw: jw, jz: jz, casing: 0.045, depth: 0.075, out: 0.075,
                                       frame: frameMaterial, trim: trimMaterial, sillMat: sillMaterial, seg: seg)
            for p in s.parts { m.add(p.0, p.1) }
            opening = s.opening
            rig.base[l] = m
        }
        let ox = opening.ox, y0 = opening.y0, y1 = opening.y1
        let gcy = (y0 + y1) / 2
        let sw: Float = 0.042, sd: Float = 0.026
        let zL: Float = -0.015, zR: Float = 0.015             // track centers (fixed sash outside, slider inside)
        // Track rails along the bottom and head channel.
        for l in 0..<2 {
            for z in [-0.027, 0.0, 0.027] as [Float] {
                let r = box(V3(2 * ox, 0.014, 0.004), V3(0, y0 + 0.007, z), frameMaterial, r: 0.001, seg: 1)
                rig.base[l].add(r.0, r.1)
            }
            for z in [-0.027, 0.0, 0.027] as [Float] {
                let r = box(V3(2 * ox, 0.012, 0.004), V3(0, y1 - 0.006, z), frameMaterial, r: 0.001, seg: 1)
                rig.base[l].add(r.0, r.1)
            }
        }
        // Sash builder: stiles, rails, double glazing, gaskets (asset space at rest).
        func sash(xa: Float, xb: Float, z: Float, to part: String?, lods: ClosedRange<Int> = 0...1) -> [(Surface, Xform)] {
            var out: [(Surface, Xform)] = []
            let cx = (xa + xb) / 2, w = xb - xa
            let ya = y0 + 0.016, yb = y1 - 0.014
            for sx: Float in [-1, 1] { out.append(box(V3(sw, yb - ya, sd), V3(cx + sx * (w / 2 - sw / 2), (ya + yb) / 2, z), frameMaterial, r: 0.003, seg: 1)) }
            for y in [ya + sw / 2, yb - sw / 2] { out.append(box(V3(w - 2 * sw + 0.002, sw, sd), V3(cx, y, z), frameMaterial, r: 0.003, seg: 1)) }
            let gw = w - 2 * sw, gh = yb - ya - 2 * sw
            for dz: Float in [-0.0065, 0.0065] { out.append(box(V3(gw + 0.02, gh + 0.02, 0.004), V3(cx, (ya + yb) / 2, z + dz), glass, r: 0.001, seg: 1)) }
            return out
        }
        func addAll(_ parts: [(Surface, Xform)], base: Bool, part: String? = nil) {
            for p in parts {
                if base { for l in 0..<2 { rig.base[l].add(p.0, p.1) } } else { rig.add(p.0, p.1, to: part!) }
            }
        }
        // Spacer and gaskets for one sash, appended to base or a part.
        func details(xa: Float, xb: Float, z: Float, base: Bool, part: String?) {
            let cx = (xa + xb) / 2, w = xb - xa
            let ya = y0 + 0.016, yb = y1 - 0.014
            let gw = w - 2 * sw, gh = yb - ya - 2 * sw, gy = (ya + yb) / 2
            func put(_ s: Surface, _ x: Xform) { if base { for l in 0..<1 { rig.base[l].add(s, x) } } else { rig.add(s, x, to: part!, lods: 0...0) } }
            for sx: Float in [-1, 1] {
                put(cuboid(V3(0.012, gh, 0.009), material: "rubber"), Xform(translation: V3(cx + sx * (gw / 2 - 0.006), gy, z)))
                for dz: Float in [-1, 1] {
                    let g = box(V3(0.006, gh, 0.004), V3(cx + sx * (gw / 2 + 0.001), gy, z + dz * 0.0115), "rubber", r: 0.0015, seg: 1)
                    put(g.0, g.1)
                }
            }
            for dy: Float in [-1, 1] {
                put(cuboid(V3(gw, 0.012, 0.009), material: "rubber"), Xform(translation: V3(cx, gy + dy * (gh / 2 - 0.006), z)))
                for dz: Float in [-1, 1] {
                    let g = box(V3(gw, 0.006, 0.004), V3(cx, gy + dy * (gh / 2 + 0.001), z + dz * 0.0115), "rubber", r: 0.0015, seg: 1)
                    put(g.0, g.1)
                }
            }
        }
        // Fixed left sash (static) and sliding right sash.
        let mid: Float = 0.022
        addAll(sash(xa: -ox + 0.003, xb: mid, z: zL, to: nil), base: true)
        details(xa: -ox + 0.003, xb: mid, z: zL, base: true, part: nil)
        rig.part("slide", pivot: V3(0, gcy, zR), joint: .slide(axis: V3(1, 0, 0), -0.5...0, duration: 1.2))
        addAll(sash(xa: -mid, xb: ox - 0.003, z: zR, to: "slide"), base: false, part: "slide")
        details(xa: -mid, xb: ox - 0.003, z: zR, base: false, part: "slide")
        // Pile weatherstrip on the meeting stiles, crescent latch and pull on the slider's interlock stile.
        let ya = y0 + 0.016, yb = y1 - 0.014
        let pile = box(V3(0.004, yb - ya - 0.06, 0.01), V3(-mid + 0.002, gcy, zR - 0.011), "rubber", r: 0.001, seg: 1)
        rig.add(pile.0, pile.1, to: "slide", lods: 0...0)
        let lx = -mid + sw / 2, lz = zR + sd / 2
        let lbase = box(V3(0.026, 0.07, 0.006), V3(lx, gcy, lz + 0.003), hardware, r: 0.003, seg: 1)
        rig.add(lbase.0, lbase.1, to: "slide", lods: 0...0)
        // Crescent: a flat torus arc turned toward the fixed stile.
        rig.add(Prim.torus(major: 0.016, minor: 0.004, segments: 20, sides: 8, arc: .pi, material: hardware),
                Xform(translation: V3(lx, gcy + 0.012, lz + 0.01), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0)) * simd_quatf(degrees: 180, axis: V3(0, 1, 0))),
                to: "slide", lods: 0...0)
        rig.add(Prim.cylinder(radius: 0.007, height: 0.008, bevel: 0.002, segments: 12, bevelSegments: 1, material: hardware),
                Xform(translation: V3(lx, gcy, lz + 0.006), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))), to: "slide", lods: 0...0)
        let pull = box(V3(0.014, 0.09, 0.006), V3(ox - 0.003 - sw / 2, gcy, lz + 0.003), hardware, r: 0.003, seg: 1)
        rig.add(pull.0, pull.1, to: "slide", lods: 0...0)

        groundAO(&rig, height: 0.05, floor: 0.75)
        rig.states = [RigState("closed"), RigState("open", ["slide": -0.46])]
        return rig
    }
}
