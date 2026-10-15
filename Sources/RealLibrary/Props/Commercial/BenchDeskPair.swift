import simd
import Foundation

/// Face-to-face bench desk for four, 280 x 75 x 150 cm: two 25 mm laminate tops (73 cm work height) with
/// 2 mm ABS banding facing each other across a 6 cm anodized center spine (cable trough, power module,
/// 2 cm raised rail), black steel T-leg frames at both ends and the middle, a steel modesty panel under
/// each top and a fabric divider hung under the spine, grommets and levelling glides.
public struct BenchDeskPair: RealAsset {
    public static let id = "bench-desk-pair"
    public static let summary = "Face-to-face open-plan bench desk for four: two laminate tops, black steel T-legs, center cable spine and fabric divider."
    public static let tags = ["prop", "floorplan", "office", "commercial", "furniture", "metal", "interior"]
    public static let budget = 7500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 22, distance: 1.1, studio: true)

    /// Overall length (x).
    public var width: Float = 2.8
    /// Overall depth (z), both rows and the spine.
    public var depth: Float = 1.5
    /// Overall height (top of the spine rail).
    public var height: Float = 0.75
    /// Laminate top tint.
    public var topColor = "E4DCCB"
    /// Powder-coat tint of the frame.
    public var frameColor = "2B2D30"
    /// Divider fabric tint.
    public var dividerColor = "C9CED3"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [6])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, D = depth, H = height
        let top: MaterialKey = "laminate.white:\(topColor)"
        let band: MaterialKey = "plastic.matte:\(topColor)"
        let steel: MaterialKey = "metal.powdercoat:\(frameColor)"
        let alu: MaterialKey = "metal.anodized"
        let black: MaterialKey = "plastic.matte:2A2B2D"
        let fabric: MaterialKey = "fabric.upholstery:\(dividerColor)"
        func box(_ size: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.003) {
            let s = detail ? Prim.roundedBox(size, radius: r, bevelSegments: 1, material: mat) : cuboid(size, material: mat)
            m.add(s, Xform(translation: c).jittered(&rng, deg: 0.02, offset: 0.0002))
        }
        let spineW: Float = 0.06, railH: Float = 0.02
        let workH = H - railH          // 0.73 work surface
        let t: Float = 0.025
        let topD = (D - spineW) / 2    // 0.72
        let under = workH - t

        // Tops with ABS band core and a laminate skin.
        for s: Float in [-1, 1] {
            let z = s * (spineW / 2 + topD / 2)
            box(V3(W, t - 0.001, topD), V3(0, under + (t - 0.001) / 2, z), band, r: 0.002)
            m.add(cuboid(V3(W - 0.003, 0.001, topD - 0.003), material: top), Xform(translation: V3(0, workH - 0.0006, z)))
        }
        // Spine: aluminum extrusion (trough) with a raised rail and a dark cap strip.
        box(V3(W - 0.02, 0.07, spineW), V3(0, workH - 0.035 + 0.0, 0), alu, r: 0.004)
        box(V3(W - 0.02, railH, spineW), V3(0, workH + railH / 2, 0), alu, r: 0.004)
        m.add(cuboid(V3(W - 0.06, 0.003, 0.03), material: black), Xform(translation: V3(0, H + 0.0005, 0)))
        // Power module: two dark blocks with sockets and a small LED.
        for x: Float in [-0.7, 0.7] {
            box(V3(0.22, 0.012, 0.045), V3(x, H + 0.004, 0), black, r: 0.002)
            if detail {
                for k in 0..<2 {
                    m.add(cuboid(V3(0.04, 0.003, 0.025), material: "metal.chrome"), Xform(translation: V3(x - 0.045 + Float(k) * 0.09, H + 0.0105, 0)))
                }
                m.add(cuboid(V3(0.006, 0.003, 0.006), material: "emissive.indicator"), Xform(translation: V3(x + 0.1, H + 0.0105, 0)))
            }
        }

        // T-legs: a floor foot bar along Z, a post at the center and a top plate under the spine.
        let legXs: [Float] = [-W / 2 + 0.12, 0, W / 2 - 0.12]
        for x in legXs {
            box(V3(0.05, 0.035, D - 0.2), V3(x, 0.0175 + 0.007, 0), steel, r: 0.004)
            box(V3(0.06, under - 0.045, 0.06), V3(x, 0.042 + (under - 0.045) / 2, 0), steel, r: 0.004)
            box(V3(0.06, 0.012, D - 0.18), V3(x, under - 0.006, 0), steel, r: 0.003)
            // Feet glides under each end of the foot bar.
            for z: Float in [-1, 1] {
                let p = V3(x, 0.0035, z * (D / 2 - 0.12))
                m.add(Prim.cylinder(radius: 0.018, height: 0.007, bevel: 0.002, segments: detail ? 12 : 6, bevelSegments: 1, material: black), Xform(translation: p))
            }
        }
        // Modesty panels (steel, 1.5 mm with hems) under each top, near the spine.
        let mpW = W - 0.5
        for s: Float in [-1, 1] {
            box(V3(mpW, 0.3, 0.012), V3(0, under - 0.02 - 0.15, s * (spineW / 2 + 0.09)), steel, r: 0.002)
        }
        // Fabric divider hung between the modesty panels under the spine.
        box(V3(mpW - 0.1, 0.34, 0.03), V3(0, under - 0.02 - 0.17 + 0.0, 0), fabric, r: 0.008)
        box(V3(mpW - 0.1, 0.012, 0.05), V3(0, under - 0.02 - 0.34 - 0.0, 0), alu, r: 0.003)
        // Rails along X under each top (anti-sag), 50 x 20 mm.
        for s: Float in [-1, 1] {
            box(V3(W - 0.24, 0.022, 0.05), V3(0, under - 0.011, s * (D / 2 - 0.1)), steel, r: 0.003)
        }
        // Grommets in the tops.
        if detail {
            for (x, s) in [(-0.7, Float(1)), (0.7, Float(-1)), (-0.7, Float(-1)), (0.7, Float(1))] as [(Float, Float)] {
                let gp = V3(x, workH, s * (spineW / 2 + 0.12))
                m.add(Prim.lathe([V2(0.03, -t + 0.002), V2(0.03, -0.001), V2(0.04, -0.0005), V2(0.04, 0.0012), V2(0.0385, 0.0025), V2(0.03, 0.0025), V2(0.03, -0.004)],
                                 segments: 24, seamTile: 0.1, material: black), Xform(translation: gp))
            }
        }
        groundAO(&m, height: 0.12, floor: 0.55)
        return m
    }
}
