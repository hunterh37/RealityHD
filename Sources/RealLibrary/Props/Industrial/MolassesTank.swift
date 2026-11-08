import simd
import Foundation

/// 1919 riveted steel molasses storage tank (Boston Great Molasses Flood) at 1:3 scale, 9 m across the stair and 5 m tall.
/// Five lapped plate courses on a base ring, rivet rows at every seam, vertical butt straps, a shallow conical roof with
/// vent stack and hatch, a spiral stair, a caged ladder, an inlet pipe with flanged valve, brown weep stains, a faded
/// painted-out stencil band and one bulging seam near the base with a dark drip puddle (front, toward +Z). Origin at the
/// base center.
public struct MolassesTank: RealAsset {
    public static let id = "molasses-tank"
    public static let summary = "1919 riveted steel molasses tank (Boston Great Molasses Flood), 1:3 scale: lapped courses, rivets, spiral stair, valve, bulging weeping seam."
    public static let tags = ["prop", "industrial", "metal", "container", "harbor", "antique"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 1.2, studio: true)

    /// Plate courses, roof and stair.
    public var steel: MaterialKey = "metal.painted:6F6B60"
    /// Rivet heads, bolts and the base ring.
    public var iron: MaterialKey = "metal.iron"
    /// Rust bloom at seams and weep stains.
    public var rust: MaterialKey = "metal.rust"
    /// Handrails, ladder, vent and valve.
    public var galvanized: MaterialKey = "metal.galvanized-aged"
    /// Faded stencil band.
    public var band: MaterialKey = "metal.painted:9A927E"
    /// Spilled molasses on the ground.
    public var molasses: MaterialKey = "metal.rust-grime:3B2312"
    public init() {}

    static let radius: Float = 4.08
    static let courseHeight: Float = 0.8
    static let baseHeight: Float = 0.14
    static let courses = 5
    static let wallTop: Float = 0.14 + 5 * 0.8
    static let roofRise: Float = 0.4

    /// Outer radius of course `i` (alternate courses lap outside the one below).
    static func courseRadius(_ i: Int) -> Float { radius + (i % 2 == 0 ? 0 : 0.009) }
    /// Wall radius at height y.
    static func wallRadius(at y: Float) -> Float {
        let i = min(courses - 1, max(0, Int((y - baseHeight) / courseHeight)))
        return courseRadius(i)
    }
    /// Point on a cylinder of radius r at angle a (radians, a = -90 degrees faces +Z).
    static func pt(_ a: Float, _ y: Float, _ r: Float) -> V3 { V3(r * cos(a), y, -r * sin(a)) }
    static func rad(_ d: Float) -> Float { d * .pi / 180 }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, hi: true), model(seed: seed, hi: false)], switchDistances: [14])
    }

    /// Low dome rivet head, sunk into the plate.
    func rivet(_ m: inout Model, _ p: V3, _ n: V3, r: Float = 0.016) {
        let prof = [V2(r, -0.001), V2(r * 0.8, r * 0.7), V2(0, r * 0.95)]
        m.add(Prim.lathe(prof, segments: 5, seamTile: 0.05, material: iron), Xform(translation: p, rotation: facing(n)))
    }

    func model(seed: UInt64, hi: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let R = Self.radius, segs = hi ? 64 : 32
        let pt = Self.pt, rad = Self.rad
        let Y = V3(0, 1, 0)
        func yaw(_ a: Float) -> simd_quatf { simd_quatf(angle: a, axis: Y) }
        func out(_ a: Float) -> V3 { V3(cos(a), 0, -sin(a)) }

        // Base ring: foundation curb with a rolled angle at the foot.
        m.add(Prim.lathe([V2(0, 0), V2(R + 0.07, 0), V2(R + 0.07, 0.10), V2(R + 0.04, 0.125), V2(R + 0.012, 0.125), V2(R + 0.012, Self.baseHeight),
                          V2(0, Self.baseHeight)], segments: segs, seamTile: 0.5, material: iron))

        // Plate courses with lapped edges.
        for i in 0..<Self.courses {
            let r = Self.courseRadius(i), y0 = Self.baseHeight + Float(i) * Self.courseHeight, y1 = y0 + Self.courseHeight
            m.add(Prim.lathe([V2(r - 0.01, y0), V2(r, y0 + 0.004), V2(r, y1 - 0.004), V2(r - 0.01, y1)], segments: segs, seamTile: 0.5, material: steel))
        }
        // Top angle ring and roof eave.
        m.add(Prim.lathe([V2(R - 0.02, Self.wallTop - 0.01), V2(R + 0.06, Self.wallTop), V2(R + 0.06, Self.wallTop + 0.04), V2(R - 0.02, Self.wallTop + 0.04)],
                         segments: segs, seamTile: 0.5, material: iron))
        // Shallow conical roof, slightly dished.
        let roofY = Self.wallTop + 0.04
        m.add(Prim.lathe([V2(R + 0.05, roofY), V2(R * 0.5, roofY + Self.roofRise * 0.56), V2(0.2, roofY + Self.roofRise * 0.97), V2(0, roofY + Self.roofRise)],
                         segments: segs, seamTile: 0.5, material: steel))
        let apex = roofY + Self.roofRise
        // Vent stack with a rain hood (top at 5.0 m).
        m.add(Prim.lathe([V2(0.17, apex - 0.02), V2(0.17, apex + 0.22), V2(0.11, apex + 0.23), V2(0.11, apex + 0.3), V2(0.24, apex + 0.36), V2(0.22, apex + 0.37), V2(0, apex + 0.4)],
                         segments: hi ? 32 : 16, seamTile: 0.2, material: galvanized))
        // Roof hatch: coaming and hinged lid.
        let hatchAt = pt(rad(20), roofY + Self.roofRise * 0.55 * (1 - 1.9 / R) + 0.02, 1.9)
        m.add(cuboid(V3(0.62, 0.1, 0.62), material: galvanized), Xform(translation: hatchAt + V3(0, 0.04, 0), rotation: yaw(rad(20))))
        m.add(cuboid(V3(0.56, 0.025, 0.56), material: steel), Xform(translation: hatchAt + V3(0, 0.105, 0), rotation: yaw(rad(20))))
        // Radial roof rib seams.
        for k in 0..<(hi ? 8 : 4) {
            let a = Float(k) / Float(hi ? 8 : 4) * 2 * .pi + 0.1
            let len = R * 0.92
            m.add(cuboid(V3(len, 0.012, 0.09), material: iron), Xform().adjusted(a: a, len: len, roofY: roofY, rise: Self.roofRise))
        }

        // Rivet rows at each seam, top and bottom of the wall.
        guard hi else { return finish(&m, hi: false) }
        var rowYs: [Float] = [Self.baseHeight + 0.05, Self.wallTop - 0.05]
        for i in 1..<Self.courses { rowYs.append(Self.baseHeight + Float(i) * Self.courseHeight) }
        for y in rowYs {
            let count = 20
            for k in 0..<count {
                let a = (Float(k) + (y > 2 ? 0.5 : 0)) / Float(count) * 2 * .pi
                let r = Self.wallRadius(at: min(max(y, Self.baseHeight + 0.01), Self.wallTop - 0.01))
                rivet(&m, pt(a, y, r), out(a))
            }
        }
        // Vertical butt straps with two rivet columns each.
        for i in 0..<Self.courses {
            let r = Self.courseRadius(i) + 0.006, y0 = Self.baseHeight + Float(i) * Self.courseHeight
            let n = 8
            for k in 0..<n {
                let a = (Float(k) + (i % 2 == 0 ? 0 : 0.5)) / Float(n) * 2 * .pi + 0.07
                m.add(cuboid(V3(0.012, Self.courseHeight - 0.03, 0.2), material: steel),
                      Xform(translation: pt(a, y0 + Self.courseHeight / 2, r), rotation: yaw(a)))
                for t: Float in [-0.07, 0.07] { for j in 0..<1 {
                    let y = y0 + 0.4
                    let aa = a - t / r
                    rivet(&m, pt(aa, y, r + 0.006), out(aa), r: 0.013)
                }}
            }
        }
        // Sink the tank on a ladder-free front: bulge, stains, band, stair, ladder, pipe.
        buildStory(&m, &rng)
        buildAccess(&m)
        buildPipe(&m)
        return finish(&m, hi: true)
    }

    func finish(_ m: inout Model, hi: Bool) -> Model {
        if !hi {
            // Lite LOD: add the cheap access geometry without rivets or small hardware.
            var rng = SeededRNG(seed: 1)
            buildStory(&m, &rng, lite: true)
            buildAccess(&m, lite: true)
            buildPipe(&m, lite: true)
        }
        groundAO(&m, height: 0.5, floor: 0.55)
        return m
    }

    /// Story details: stencil band, bulging seam, drip puddle, weep stains and rust bloom.
    func buildStory(_ m: inout Model, _ rng: inout SeededRNG, lite: Bool = false) {
        let R = Self.radius, pt = Self.pt, rad = Self.rad
        let Y = V3(0, 1, 0)
        // Painted-out stencil band on course 2 with ghosted letter blocks.
        let bandY = Self.baseHeight + 2.5 * Self.courseHeight
        let bandR = Self.courseRadius(2) + 0.0025
        let a0 = rad(-150), a1 = rad(-30), steps = lite ? 12 : 30
        let path = (0...steps).map { pt(a0 + (a1 - a0) * Float($0) / Float(steps), bandY, bandR) }
        m.add(Prim.sweep(Shape2D.rect(0.004, 0.5), along: path, up: out(a0), caps: true, material: band))
        if !lite {
            for k in 0..<12 {
                let a = a0 + (a1 - a0) * (Float(k) + 0.5) / 12
                let w = rng.float(0.14...0.2)
                m.add(cuboid(V3(0.004, rng.float(0.2...0.3), w), material: steel),
                      Xform(translation: pt(a, bandY + rng.float(-0.03...0.03), bandR + 0.003), rotation: simd_quatf(angle: a, axis: Y)))
            }
        }
        // Bulging seam near the base: a swollen plate patch spanning 50 degrees.
        let ba = rad(-70)
        let bulgePath = (0...(lite ? 8 : 24)).map { pt(ba - rad(25) + rad(50) * Float($0) / Float(lite ? 8 : 24), 0.62, Self.courseRadius(0) + 0.002) }
        let n = bulgePath.count
        let sc = (0..<n).map { i -> Float in let t = Float(i) / Float(n - 1) * 2 - 1; return 0.12 + 0.88 * pow(max(0, 1 - t * t), 0.7) }
        m.add(Prim.sweep(Shape2D.circle(0.055, ry: 0.34, segments: lite ? 10 : 20), along: bulgePath, up: out(ba), scales: sc, caps: true, material: steel))
        // Dark ooze along the bulged seam.
        let seam = (0...(lite ? 8 : 24)).map { pt(ba - rad(22) + rad(44) * Float($0) / Float(lite ? 8 : 24), 0.62, Self.courseRadius(0) + 0.062) }
        let ssc = (0..<seam.count).map { i -> Float in let t = Float(i) / Float(seam.count - 1) * 2 - 1; return 0.2 + 0.8 * max(0, 1 - t * t) }
        m.add(Prim.sweep(Shape2D.rect(0.004, 0.035), along: seam, up: out(ba), scales: ssc, caps: true, material: molasses))
        // Drip puddle on the ground beneath the bulge.
        let pc = pt(ba, 0, R + 0.4)
        m.add(Prim.lathe([V2(0, 0.012), V2(0.55, 0.011), V2(0.8, 0.007), V2(0.92, 0.002), V2(0.95, 0)], segments: lite ? 16 : 36, seamTile: 0.5, material: molasses),
              Xform(translation: pc, rotation: simd_quatf(angle: ba, axis: Y), scale: V3(0.95, 1, 0.65)))
        m.add(Prim.lathe([V2(0, 0.014), V2(0.22, 0.012), V2(0.34, 0)], segments: lite ? 10 : 20, seamTile: 0.5, material: molasses),
              Xform(translation: pt(ba + rad(16), 0, R + 0.95), scale: V3(0.9, 1, 0.6)))
        // Thick run from the bulge down the wall, over the base ring to the puddle.
        let runY: [Float] = [0.56, 0.42, 0.3, 0.2, 0.13, 0.125, 0.06, 0.012]
        let runR: [Float] = [0.07, 0.07, 0.07, 0.08, 0.09, R + 0.2 - Self.radius + 0.07, 0.4, 0.5]
        let runPath = zip(runY, runR).enumerated().map { (i, p) -> V3 in
            let r = i < 4 ? Self.courseRadius(0) + 0.062 - 0.0 : (i == 4 ? R + 0.075 : (i == 5 ? R + 0.09 : R + 0.35 + Float(i - 5) * 0.2))
            return pt(ba + rad(1.5) * sin(Float(i)), p.0, r)
        }
        m.add(Prim.sweep(Shape2D.circle(0.04, ry: 0.0045, segments: 6), along: runPath, up: V3(0, 1, 0), scales: [0.9, 1, 1.1, 1.2, 1.1, 1, 1, 0.9], caps: true, material: molasses))
        guard !lite else { return }
        // Thin weeps from the seams, tapering as they run down.
        for k in 0..<8 {
            let seamI = rng.int(1...4)
            let a = rng.float(-Float.pi...Float.pi)
            let y0 = Self.baseHeight + Float(seamI) * Self.courseHeight
            let len = rng.float(0.25...1.0), w = rng.float(0.03...0.07)
            let pts: [V3] = (0..<6).map { j in
                let t = Float(j) / 5
                let y = y0 - len * t
                return pt(a + 0.004 * sin(t * 5 + Float(k)), y, Self.wallRadius(at: max(y, Self.baseHeight + 0.01)) + 0.0045)
            }
            let tapered: [Float] = [1, 0.85, 0.7, 0.62, 0.55, 0.9]
            m.add(Prim.sweep(Shape2D.rect(0.003, w), along: pts, up: out(a), scales: tapered, caps: true, material: k % 3 == 0 ? rust : molasses))
        }
    }

    func out(_ a: Float) -> V3 { V3(cos(a), 0, -sin(a)) }

    /// Spiral stair from the base to the roof edge and the caged ladder in the gap.
    func buildAccess(_ m: inout Model, lite: Bool = false) {
        let R = Self.radius, pt = Self.pt, rad = Self.rad
        let Y = V3(0, 1, 0)
        func yaw(_ a: Float) -> simd_quatf { simd_quatf(angle: a, axis: Y) }
        let treads = lite ? 18 : 30
        let a0 = rad(-170), turn = rad(300), y0: Float = 0.15, y1 = Self.wallTop
        let tw: Float = 0.42, rOut = R + 0.012 + tw
        var rail: [V3] = [], mid: [V3] = []
        for i in 0..<treads {
            let t = Float(i) / Float(treads - 1)
            let a = a0 + turn * t, y = y0 + (y1 - y0) * t
            let len = 2 * .pi * (R + tw / 2) * (turn / Float(treads - 1)) / (2 * .pi) * 1.08
            m.add(cuboid(V3(tw, 0.028, len), material: galvanized), Xform(translation: pt(a, y, R + 0.012 + tw / 2), rotation: yaw(a)))
            if !lite {
                m.add(cuboid(V3(tw * 0.9, 0.045, 0.03), material: iron), Xform(translation: pt(a, y - 0.035, R + 0.012 + tw / 2), rotation: yaw(a)))
                if i % 3 == 0 { m.add(cuboid(V3(0.028, 0.9, 0.028), material: galvanized), Xform(translation: pt(a, y + 0.45, rOut - 0.02), rotation: yaw(a))) }
            }
            rail.append(pt(a, y + 0.9, rOut - 0.02)); mid.append(pt(a, y + 0.5, rOut - 0.02))
        }
        let rs = lite ? 4 : 6
        m.add(Prim.tube(rail, radii: rail.map { _ in 0.022 }, sides: rs, seamTile: 0.1, material: galvanized))
        m.add(Prim.tube(mid, radii: mid.map { _ in 0.014 }, sides: rs, seamTile: 0.1, material: galvanized))
        // Roof landing at the top of the stair.
        let la = a0 + turn + rad(10)
        m.add(cuboid(V3(0.9, 0.04, 0.8), material: galvanized), Xform(translation: pt(la, y1 + 0.02, R - 0.2), rotation: yaw(la)))
        // Caged ladder at a = 160 degrees.
        let ladderA = rad(160)
        let lr = R + 0.13
        let sideA = 0.22 / lr
        for s: Float in [-1, 1] {
            let p = [pt(ladderA + s * sideA, 0.1, lr), pt(ladderA + s * sideA, y1 + 0.85, lr)]
            m.add(Prim.tube(p, radii: [0.02, 0.02], sides: lite ? 4 : 6, seamTile: 0.1, material: galvanized))
        }
        if !lite {
            for j in 0..<15 {
                m.add(cuboid(V3(0.02, 0.02, 0.44), material: galvanized), Xform(translation: pt(ladderA, 0.35 + Float(j) * 0.3, lr), rotation: yaw(ladderA)))
            }
            for k in 0..<3 {
                let y = 2.5 + Float(k) * 0.9
                let arcLen: Float = 1.55 * .pi
                m.add(Prim.torus(major: 0.4, minor: 0.012, segments: 12, sides: 5, arc: arcLen, material: galvanized),
                      Xform(translation: pt(ladderA, y, lr + 0.2), rotation: yaw(ladderA - arcLen / 2)))
            }
        }
    }

    /// Inlet pipe with flanged gate valve near the base, at a = -110 degrees.
    func buildPipe(_ m: inout Model, lite: Bool = false) {
        let pt = Self.pt, rad = Self.rad
        let Y = V3(0, 1, 0)
        let a = rad(-112), y: Float = 0.52, r0 = Self.courseRadius(0) - 0.1
        func yaw(_ ang: Float) -> simd_quatf { simd_quatf(angle: ang, axis: Y) }
        let dir = V3(cos(a), 0, -sin(a))
        let sides = lite ? 10 : 16
        // Run out from the wall, then elbow down to ground level.
                var path = [pt(a, y, r0), pt(a, y, Self.radius + 0.2), pt(a, y, Self.radius + 0.42)]
        let elbow = (0...6).map { k -> V3 in
            let t = Float(k) / 6 * .pi / 2
            return pt(a, y - 0.3 + 0.3 * cos(t), Self.radius + 0.42 + 0.3 * sin(t))
        }
        path += elbow.dropFirst()
        path.append(pt(a, 0.12, Self.radius + 0.72))
        m.add(Prim.tube(path, radii: path.map { _ in 0.11 }, sides: sides, seamTile: 0.2, material: iron))
        // Gate valve: flange pair around a body, stem and handwheel.
        let vp = pt(a, y, Self.radius + 0.28)
        let q = facing(dir)
        m.add(Prim.cylinder(radius: 0.19, height: 0.035, bevel: 0.004, segments: lite ? 12 : 20, material: iron), Xform(translation: vp - dir * 0.2, rotation: q))
        m.add(Prim.cylinder(radius: 0.19, height: 0.035, bevel: 0.004, segments: lite ? 12 : 20, material: iron), Xform(translation: vp + dir * 0.17, rotation: q))
        m.add(Prim.lathe([V2(0.12, 0), V2(0.14, 0.05), V2(0.15, 0.18), V2(0.14, 0.31), V2(0.12, 0.36)], segments: lite ? 12 : 20, seamTile: 0.2, material: iron),
              Xform(translation: vp - dir * 0.17, rotation: q))
        guard !lite else { return }
        for k in 0..<8 {
            let ang = Float(k) / 8 * 2 * .pi
            let off = V3(0, 1, 0) * (cos(ang) * 0.155) + simd_cross(dir, Y) * (sin(ang) * 0.155)
            rivet(&m, vp - dir * 0.2 + off + dir * 0.035, dir, r: 0.016)
            rivet(&m, vp + dir * 0.17 + off + dir * 0.035, dir, r: 0.016)
        }
        // Stem upright from the bonnet with a handwheel.
        let top = vp + V3(0, 0.15, 0) + V3(0, 0.0, 0)
        m.add(Prim.lathe([V2(0.09, 0), V2(0.07, 0.04), V2(0.03, 0.1), V2(0.03, 0.34)], segments: 16, seamTile: 0.1, material: iron), Xform(translation: top))
        m.add(Prim.torus(major: 0.12, minor: 0.012, segments: 18, sides: 6, material: iron), Xform(translation: top + V3(0, 0.36, 0)))
        for k in 0..<3 {
            m.add(cuboid(V3(0.24, 0.012, 0.014), material: iron), Xform(translation: top + V3(0, 0.36, 0), rotation: simd_quatf(angle: Float(k) * .pi / 3, axis: Y)))
        }
    }
}

private extension Xform {
    /// Rib placement helper: yaw about Y, slope down toward the eave.
    func adjusted(a: Float, len: Float, roofY: Float, rise: Float) -> Xform {
        let slope = atan2(rise * 0.85, len)
        let flat = V3(cos(a), 0, -sin(a))
        let mid = V3(0, roofY + rise * 0.46, 0) + flat * (len / 2 + 0.2)
        let q = simd_quatf(angle: a, axis: V3(0, 1, 0)) * simd_quatf(angle: -slope, axis: V3(0, 0, 1))
        return Xform(translation: mid, rotation: q, scale: scale)
    }
}
