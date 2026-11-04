import simd
import Foundation

/// Viking longship, 22 m stem to stern post: clinker-built oak hull of ten overlapping strakes per side lofted over
/// a keel, ribs, cross beams and a lined interior, carved dragon prow and curled stern post swept from tapered
/// sections, twelve iron-bossed round shields per side on a shield rail, sixteen oars per side on thole pins, a
/// starboard steering oar, a mast with stays, a striped square sail on a yard that lowers to a furled bundle, and
/// an iron fire brazier with a flickering light. Origin at the waterline centre, bow toward +Z, port = +X.
/// Keel at y = -0.6, midship gunwale at y = 1.0. 2 LODs.
///
/// Articulation: `oars` 0...1 is the stroke cycle (all 32 oars mimic it, alternating oars carry an offset),
/// `sail` 0...1 lowers the furled bundle (0) to the set sail (1), `sway` -1...1 rolls the whole ship 4 degrees.
public struct VikingLongship: RealArticulated {
    public static let id = "viking-longship"
    public static let summary = "22 m clinker-built oak longship: carved dragon prow, round shields, 32 oars, striped square sail, steering oar and fire brazier."
    public static let tags = ["prop", "vehicle", "boat", "river", "wood", "articulated"]
    public static let budget = 30_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 52, elevation: 14, distance: 1.1)

    /// Half length of the hull body (m); the stems rise beyond it.
    public var halfLength: Float = 10.9
    /// Half beam at the widest strake (m).
    public var halfBeam: Float = 2.3
    /// Keel height below the waterline at midships (m).
    public var draft: Float = 0.6
    /// Number of overlapping strakes per side.
    public var strakeCount = 10
    /// Oars per side.
    public var oarsPerSide = 16
    /// Shields per side.
    public var shieldsPerSide = 12
    /// Plank wood, tinted per strake through the key.
    public var plankWood: MaterialKey = "wood.oak"
    /// Frames, beams, spars and rails.
    public var frameWood: MaterialKey = "wood.oak:8A6A44"
    /// Iron fittings, bosses, rims and oarlocks.
    public var iron: MaterialKey = "metal.iron"
    /// Sail stripes.
    public var sailRed: MaterialKey = "fabric.canvas:A32B22"
    public var sailCream: MaterialKey = "fabric.canvas:E6DABB"
    /// Tarred rope.
    public var rope: MaterialKey = "fabric.burlap:3A2F22"
    public init() {}

    // MARK: Hull shape (t = z / halfLength, v = 0 keel ... 1 sheer)

    static let sailLift: Float = 7.4
    static let yardRest: Float = 2.9
    static let mastZ: Float = 1.2
    static let oarReach: Float = 4.9
    static let oarInboard: Float = 1.35
    static let oarTilt: Float = 7
    static let swing: Float = 44
    static let shieldZ0: Float = -6.05

    func keelY(_ t: Float) -> Float { -draft + 1.3 * pow(smoothstep(0.35, 1, abs(t)), 1.8) }
    func sheerY(_ t: Float) -> Float { 1.0 + 0.85 * pow(abs(t), 2.6) }
    func beamAt(_ t: Float) -> Float { max(0.035, halfBeam * pow(max(0, 1 - pow(abs(t), 2.4)), 0.72)) }
    func shape(_ v: Float) -> Float { pow(max(v, 0), 0.75) }
    func hullPoint(_ t: Float, _ v: Float, _ side: Float, off: Float = 0, inset: Float = 0) -> V3 {
        let k = keelY(t), h = sheerY(t) - k
        let fade = 1 - 0.85 * smoothstep(0.93, 1, abs(t))
        let o = (off - inset) * fade
        let d = simd_normalize(V3(side, -0.5 * (1 - v), 0))
        let base = V3(side * beamAt(t) * shape(v), k + v * h, t * halfLength)
        return base + d * o
    }
    func stations(_ n: Int) -> [Float] {
        (0...n).map { i in let s = Float(i) / Float(n) * 2 - 1; return 0.5 * s + 0.5 * sin(s * .pi / 2) }
    }
    func rad(_ d: Float) -> Float { d * .pi / 180 }
    func hex(_ c: UInt32) -> String { String(format: "%06X", c) }

    func orient(_ s: inout Surface, _ center: (V3) -> V3) {
        WoodParts.orientOutward(&s, center: center)
        s.recomputeNormals(weldSeams: false)
        s.computeTangents()
    }

    /// Open-ended sweep of an elliptical section with per-point scale: spars, stems, neck, jaws, horns.
    func bone(_ path: [V3], _ a: Float, _ b: Float, _ scales: [Float], sides: Int, up: V3 = V3(1, 0, 0),
              caps: Bool = true, _ mat: MaterialKey) -> Surface {
        Prim.sweep(Shape2D.circle(a, ry: b, segments: sides), along: path, up: up, scales: scales, caps: caps, grainAlongPath: true, material: mat)
    }
    /// Resamples a polyline with Catmull-Rom and a matching scale ramp.
    func smooth(_ pts: [V3], per: Int, _ scale: (Float) -> Float) -> (path: [V3], scales: [Float]) {
        let p = catmull(pts, per: per)
        return (p, p.indices.map { scale(Float($0) / Float(max(1, p.count - 1))) })
    }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [14])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)
        let L = halfLength

        // Drivers first so mimics resolve.
        _ = rig.part("oars", pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 1.6))
        _ = rig.part("sail", pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 3.0))
        _ = rig.part("sway", pivot: .zero, joint: .hinge(axis: Y, -1...1, duration: 3.0))
        _ = rig.part("hull", pivot: .zero, joint: Joint(.revolute, axis: Z, range: -4...4, mimic: .init("sway", ratio: 4)))

        // Oar positions along the hull.
        let oarPitch: Float = 0.9
        func oarZ(_ i: Int) -> Float { -Float(oarsPerSide - 1) * oarPitch / 2 + Float(i) * oarPitch }
        func pinY(_ t: Float) -> Float { keelY(t) + 0.58 * (sheerY(t) - keelY(t)) + 0.06 }
        func pinPoint(_ side: Float, _ i: Int) -> V3 {
            let z = oarZ(i), t = z / L
            return V3(side * (beamAt(t) * shape(0.58) + 0.07), pinY(t) - 0.0, z)
        }
        for i in 0..<oarsPerSide {
            for (side, tag) in [(Float(1), "P"), (Float(-1), "S")] {
                let aft: Float = i % 2 == 0 ? 9 : -9
                let ratio = -side * Self.swing
                // port: yaw = -R * o + R / 2 + aft; starboard: yaw = +R * o - R / 2 - aft.
                let off: Float = side > 0 ? Self.swing / 2 + aft : -Self.swing / 2 - aft
                _ = rig.part("oar\(tag)\(i + 1)", parent: "hull", pivot: pinPoint(side, i),
                             joint: Joint(.revolute, axis: Y, range: -70...70, mimic: .init("oars", ratio: ratio, offset: off)))
            }
        }
        _ = rig.part("yard", parent: "hull", pivot: V3(0, Self.yardRest, Self.mastZ + 0.3),
                     joint: Joint(.prismatic, axis: Y, range: 0...Self.sailLift, mimic: .init("sail", ratio: Self.sailLift)), options: 2)
        rig.optionLinks = [RigOptionLink(part: "yard", joint: "sail", thresholds: [0.5])]

        // Shared builders.
        func mat(_ strake: Int) -> MaterialKey {
            let tones: [UInt32] = [0x7A5836, 0x8C6842, 0xC49A6A, 0xB08455, 0xC8A070, 0xB48A5E, 0xC49A6A, 0xAC8052, 0xC8A070, 0xB48A5E]
            return "wood.oak:" + hex(tones[strake % tones.count])
        }
        let shieldTints: [UInt32] = [0xA32B22, 0xD8B23A, 0x1E1C1A, 0xE4DCC8, 0x2C4A78, 0x4C6A32]

        for l in 0..<2 {
            let hi = l == 0
            var m = Model(name: Self.id)
            func addH(_ s: Surface, _ x: Xform = .identity) { rig.add(s, x, to: "hull", lods: l...l) }

            // MARK: Clinker strakes.
            let ns = hi ? 34 : 14
            let ts = stations(ns)
            for side: Float in [1, -1] {
                for k in 0..<strakeCount {
                    let v0 = Float(k) / Float(strakeCount), v1 = Float(k + 1) / Float(strakeCount)
                    let lip: [(Float, Float)] = [(v0, 0.0), (v0 + 0.006, 0.036)]
                    let vTop: Float = min(1, v1 + 0.012), vMid: Float = v0 + (v1 - v0) * 0.5, vLip: Float = v0 + 0.006
                    var face: [(Float, Float)] = [(vLip, 0.036)]
                    if hi { face.append((vMid, 0.033)) }
                    face.append((vTop, hi ? 0.014 : 0.016))
                    var s = Surface(material: mat(k))
                    for band in [lip, face] {
                        let base = UInt32(s.positions.count)
                        for t in ts {
                            var arc: Float = 0
                            for (r, row) in band.enumerated() {
                                let p = hullPoint(t, row.0, side, off: row.1)
                                if r > 0 { let q = hullPoint(t, band[r - 1].0, side, off: band[r - 1].1); arc += simd_distance(p, q) }
                                s.add(p, .up, V2(p.z * side + Float(k) * 3.1, arc + Float(k) * 0.37 + (side > 0 ? 0 : 11)))
                            }
                        }
                        let w = UInt32(band.count)
                        for i in 0..<ns { for r in 0..<(band.count - 1) {
                            let a = base + UInt32(i) * w + UInt32(r)
                            s.quad(a, a + 1, a + w + 1, a + w)
                        }}
                    }
                    orient(&s) { p in V3(0, 0.35, p.z) }
                    // Per-strake weathering on the baked occlusion, darker toward the waterline.
                    for q in s.positions.indices {
                        let p = s.positions[q]
                        let tone: Float = 0.9 + 0.1 * Float(abs(sin(p.z * 1.7 + Float(k) * 2.3)))
                        s.occlusion[q] *= tone * (0.86 + 0.14 * smoothstep(-0.6, 0.3, p.y))
                    }
                    addH(s)
                }
            }

            // MARK: Keel, stems and gunwales.
            do {
                let n = hi ? 24 : 10
                let path = stations(n).map { t in V3(0, keelY(t) - 0.04, t * L) }
                m.add(Prim.sweep(Shape2D.rect(0.17, 0.15), along: path, up: X, caps: true, grainAlongPath: true, material: frameWood))
                for side: Float in [1, -1] {
                    let pts = stations(hi ? 30 : 12).map { t in hullPoint(t, 1.0, side, off: 0.05) }
                    let trimmed = pts.filter { abs($0.z) < L * 0.985 }
                    m.add(Prim.sweep(Shape2D.rect(0.10, 0.075), along: trimmed, up: X, caps: true, grainAlongPath: true, material: frameWood))
                }
            }

            // MARK: Interior lining and floor.
            do {
                let n = hi ? 30 : 12, cols = hi ? 8 : 4
                var rows: [[V3]] = [], uvs: [[V2]] = []
                for t in stations(n) {
                    var r: [V3] = [], u: [V2] = []
                    for j in 0...(2 * cols) {
                        let sgn: Float = j <= cols ? -1 : 1
                        let v = j <= cols ? 1 - Float(j) / Float(cols) : Float(j - cols) / Float(cols)
                        r.append(hullPoint(t, max(v, 0.0), sgn, inset: 0.07))
                        u.append(V2(t * L, Float(j) * 0.3))
                    }
                    rows.append(r); uvs.append(u)
                }
                var lining = WoodParts.grid(rows, uvs: uvs, material: "wood.oak:6E4B2E")
                WoodParts.orientOutward(&lining) { p in V3(0, 0.6, p.z) }
                for k in stride(from: 0, to: lining.indices.count, by: 3) { lining.indices.swapAt(k + 1, k + 2) }
                lining.recomputeNormals(weldSeams: false); lining.computeTangents()
                addH(lining)
                // Floorboards: one lengthwise strip per board at y = -0.1.
                let boards = hi ? 5 : 3
                let fy: Float = -0.08
                for b in 0..<boards {
                    var s = Surface(material: b % 2 == 0 ? "wood.oak:A8804F" : "wood.oak:94703F")
                    let zs = stations(hi ? 24 : 8).map { $0 * (L - 1.2) }
                    for z in zs {
                        let t = z / L
                        let vf = max(0.05, (fy - keelY(t)) / (sheerY(t) - keelY(t)))
                        let w = max(0.1, beamAt(t) * shape(vf) - 0.09)
                        let x0 = -w + 2 * w * Float(b) / Float(boards) + 0.004, x1 = -w + 2 * w * Float(b + 1) / Float(boards) - 0.004
                        for x in [x0, x1] { s.add(V3(x, max(fy, keelY(t) + 0.12), z), .up, V2(z, x)) }
                    }
                    for i in 0..<(zs.count - 1) {
                        let a = UInt32(i * 2)
                        s.quad(a, a + 2, a + 3, a + 1)
                    }
                    s.recomputeNormals(weldSeams: false); s.computeTangents()
                    m.add(s)
                }
            }

            // MARK: Ribs, cross beams, keelson, mast partner.
            if hi {
                for j in 0..<12 {
                    let z = -8.8 + Float(j) * 1.6, t = z / L
                    var pts: [V3] = []
                    for q in 0...10 {
                        let sgn: Float = q <= 5 ? -1 : 1
                        let v = q <= 5 ? 0.96 - Float(q) / 5 * 0.9 : 0.06 + Float(q - 5) / 5 * 0.9
                        pts.append(hullPoint(t, v, sgn, inset: 0.065))
                    }
                    m.add(Prim.sweep(Shape2D.rect(0.075, 0.12), along: catmull(pts, per: 1), up: Y, caps: true, material: "wood.oak:8A6A44"))
                }
                for j in 0..<7 {
                    let z = -7.2 + Float(j) * 2.4, t = z / L
                    let yb = sheerY(t) - 0.42
                    let vb = (yb - keelY(t)) / (sheerY(t) - keelY(t))
                    let w = beamAt(t) * shape(vb) - 0.03
                    m.add(Prim.roundedBox(V3(2 * w, 0.12, 0.24), radius: 0.02, bevelSegments: 1, material: frameWood), Xform(translation: V3(0, yb, z)))
                }
                m.add(Prim.roundedBox(V3(0.34, 0.38, 3.4), radius: 0.03, bevelSegments: 1, material: frameWood), Xform(translation: V3(0, -0.22, Self.mastZ)))
                m.add(Prim.roundedBox(V3(1.0, 0.24, 1.5), radius: 0.03, bevelSegments: 1, material: frameWood), Xform(translation: V3(0, sheerY(Self.mastZ / L) - 0.53, Self.mastZ)))
            } else {
                for j in 0..<5 {
                    let z = -7.2 + Float(j) * 3.6, t = z / L
                    let yb = sheerY(t) - 0.42
                    let vb = (yb - keelY(t)) / (sheerY(t) - keelY(t))
                    m.add(Prim.roundedBox(V3(2 * (beamAt(t) * shape(vb) - 0.03), 0.12, 0.24), radius: 0.02, bevelSegments: 1, material: frameWood), Xform(translation: V3(0, yb, z)))
                }
            }

            // MARK: Mast, stays, masthead.
            do {
                let mz = Self.mastZ
                let path = [V3(0, -0.2, mz), V3(0, 2.5, mz), V3(0, 6.5, mz), V3(0, 11.2, mz)]
                var s = Prim.tube(path, radii: [0.22, 0.20, 0.16, 0.10], sides: hi ? 12 : 7, seamTile: 0.5, material: frameWood, capEnd: true)
                s.uvs = s.uvs.map { V2($0.y, $0.x) }; s.computeTangents()
                m.add(s)
                m.add(Prim.tube([V3(0, 11.15, mz), V3(0, 11.45, mz)], radii: [0.14, 0.06], sides: hi ? 10 : 6, seamTile: 0.2, material: iron, capEnd: true))
                func stay(_ a: V3, _ b: V3, _ r: Float, sag: Float) {
                    let mid = (a + b) / 2 - V3(0, sag, 0)
                    let p = catmull([a, a + (mid - a) * 0.5, mid, mid + (b - mid) * 0.5, b], per: hi ? 3 : 1)
                    m.add(Prim.tube(p, radii: p.map { _ in r }, sides: hi ? 6 : 4, seamTile: 0.1, material: rope, capEnd: false))
                }
                stay(V3(0, 11.0, mz), V3(0, 2.2, 10.8), 0.03, sag: 0.25)
                stay(V3(0, 11.0, mz), V3(0, 2.0, -10.6), 0.03, sag: 0.25)
                for side: Float in [1, -1] {
                    stay(V3(side * 0.12, 10.4, mz), V3(side * 2.2, 1.0, mz + 0.2), 0.025, sag: 0.05)
                }
            }

            // MARK: Dragon prow.
            do {
                let sub = hi ? 14 : 8
                let neckPts = [V3(0, 0.55, L - 0.02), V3(0, 1.45, L + 0.28), V3(0, 2.4, L + 0.46), V3(0, 3.3, L + 0.5), V3(0, 3.95, L + 0.7), V3(0, 4.25, L + 1.15)]
                let neck = smooth(neckPts, per: hi ? 4 : 2) { u in 1.0 - 0.38 * u + 0.12 * sin(u * .pi) }
                m.add(bone(neck.path, 0.115, 0.19, neck.scales, sides: hi ? 10 : 6, frameWood))
                // Carved collar rings (bronze) down the neck.
                for u: Float in [0.18, 0.36, 0.54, 0.72] {
                    let i = Int(u * Float(neck.path.count - 1))
                    let c = neck.path[i], tan = simd_normalize(neck.path[min(i + 1, neck.path.count - 1)] - neck.path[max(i - 1, 0)])
                    let sc = neck.scales[i]
                    var ring = Prim.torus(major: 0.17 * sc, minor: 0.024, segments: hi ? 16 : 8, sides: hi ? 6 : 4, material: "metal.bronze-weathered")
                    ring = ring.transformed(Xform(translation: c, rotation: simd_quatf(from: Y, to: tan), scale: V3(0.7, 1, 1.1)))
                    m.add(ring)
                }
                // Head: skull, snout, jaw, teeth, brow, horns, eye, nostril.
                let hc = V3(0, 4.28, L + 1.4)
                m.add(Prim.superellipsoid(V3(0.17, 0.2, 0.34), exponent: 2, subdivisions: hi ? 6 : 3, material: frameWood),
                      Xform(translation: hc, rotation: simd_quatf(angle: rad(-8), axis: X)))
                let snout = smooth([hc + V3(0, 0.0, 0.1), hc + V3(0, -0.04, 0.5), hc + V3(0, -0.12, 0.9)], per: hi ? 3 : 1) { u in 1 - 0.55 * u }
                m.add(bone(snout.path, 0.15, 0.13, snout.scales, sides: sub, frameWood))
                let jaw = smooth([hc + V3(0, -0.17, 0.0), hc + V3(0, -0.34, 0.45), hc + V3(0, -0.32, 0.88)], per: hi ? 3 : 1) { u in 1 - 0.5 * u }
                m.add(bone(jaw.path, 0.115, 0.07, jaw.scales, sides: hi ? 10 : 6, frameWood))
                m.add(Prim.superellipsoid(V3(0.12, 0.07, 0.09), exponent: 2, subdivisions: hi ? 3 : 2, material: frameWood), Xform(translation: hc + V3(0, -0.07, 1.03)))
                if hi {
                    for k in 0..<5 {
                        let z = hc.z + 0.2 + Float(k) * 0.15
                        for sx: Float in [-1, 1] {
                            m.add(Prim.tube([V3(sx * 0.1, hc.y - 0.2 - 0.02 * Float(k), z), V3(sx * 0.1, hc.y - 0.1, z + 0.01)], radii: [0.018, 0.004], sides: 5, seamTile: 0.05, material: "wood.painted-exterior:E4DCC8", capEnd: true))
                        }
                    }
                    for sx: Float in [-1, 1] {
                        // Brow ridge, eye and nostril.
                        m.add(Prim.superellipsoid(V3(0.045, 0.03, 0.12), exponent: 2, subdivisions: 3, material: frameWood), Xform(translation: hc + V3(sx * 0.15, 0.13, 0.3), rotation: simd_quatf(angle: rad(-18) * sx, axis: Z)))
                        m.add(Prim.superellipsoid(V3(0.045, 0.045, 0.045), exponent: 2, subdivisions: 4, material: "wood.painted-exterior:E4DCC8"), Xform(translation: hc + V3(sx * 0.165, 0.08, 0.3)))
                        m.add(Prim.superellipsoid(V3(0.024, 0.024, 0.024), exponent: 2, subdivisions: 3, material: "wood.charred"), Xform(translation: hc + V3(sx * 0.2, 0.08, 0.31)))
                        m.add(Prim.superellipsoid(V3(0.022, 0.02, 0.03), exponent: 2, subdivisions: 2, material: "wood.charred"), Xform(translation: hc + V3(sx * 0.06, 0.02, 0.98)))
                        // Swept back horn.
                        let horn = smooth([hc + V3(sx * 0.1, 0.15, -0.05), hc + V3(sx * 0.2, 0.34, -0.25), hc + V3(sx * 0.22, 0.48, -0.55), hc + V3(sx * 0.18, 0.5, -0.8)], per: 3) { u in 1 - 0.8 * u }
                        m.add(bone(horn.path, 0.045, 0.05, horn.scales, sides: 8, up: Y, frameWood))
                    }
                    // Crest scales down the back of the neck.
                    for i in stride(from: 3, to: neck.path.count - 2, by: 2) {
                        let c = neck.path[i] + V3(0, 0.0, 0)
                        let tan = simd_normalize(neck.path[i + 1] - neck.path[i - 1])
                        let n = simd_normalize(simd_cross(X, tan))
                        let dir = n.y > 0 ? n : -n
                        m.add(Prim.superellipsoid(V3(0.02, 0.07, 0.05), exponent: 2, subdivisions: 2, material: "metal.bronze-weathered"),
                              Xform(translation: c + dir * 0.17 * neck.scales[i], rotation: simd_quatf(from: Y, to: dir)))
                    }
                }
            }

            // MARK: Stern post, curled.
            do {
                var pts: [V3] = [V3(0, 0.55, -L + 0.02), V3(0, 1.3, -L - 0.15), V3(0, 2.0, -L - 0.3), V3(0, 2.55, -L - 0.3)]
                let c = V3(0, 2.55, -L - 0.3 + 0.55)
                let steps = hi ? 14 : 7
                for i in 1...steps {
                    let phi = 2.4 * Float.pi * Float(i) / Float(steps)
                    let r = 0.55 - 0.42 * Float(i) / Float(steps)
                    pts.append(c + V3(0, r * sin(phi), -r * cos(phi)))
                }
                let post = smooth(pts, per: 1) { u in max(0.28, 1 - 0.72 * u) }
                m.add(bone(post.path, 0.105, 0.16, post.scales, sides: hi ? 10 : 6, frameWood))
                // Iron bands on the post.
                for h: Float in [1.1, 1.8] {
                    m.add(Prim.torus(major: 0.13, minor: 0.018, segments: hi ? 16 : 8, sides: hi ? 6 : 4, material: iron),
                          Xform(translation: V3(0, h, -L - 0.12 - 0.2 * (h - 1.1)), rotation: simd_quatf(angle: rad(-12), axis: X), scale: V3(0.9, 1, 1.3)))
                }
            }

            // MARK: Shield rail and shields.
            do {
                for side: Float in [1, -1] {
                    let pts = stride(from: Self.shieldZ0 - 0.6, through: -Self.shieldZ0 + 0.6, by: 1.2).map { z -> V3 in
                        let t = z / L
                        return V3(side * (beamAt(t) + 0.08), sheerY(t) - 0.26, z)
                    }
                    m.add(Prim.sweep(Shape2D.rect(0.05, 0.05), along: catmull(pts, per: hi ? 3 : 1), up: X, caps: true, grainAlongPath: true, material: frameWood))
                }
            }
            rig.base[l] = m

            // Shields (on the hull part so they roll with it).
            let segs = hi ? 14 : 8
            for side: Float in [1, -1] {
                for i in 0..<shieldsPerSide {
                    let z = Self.shieldZ0 + Float(i) * (-2 * Self.shieldZ0 / Float(shieldsPerSide - 1)), t = z / L
                    let tint = shieldTints[(i * 2 + (side > 0 ? 0 : 1)) % shieldTints.count]
                    let alt = shieldTints[(i * 2 + (side > 0 ? 0 : 1) + 3) % shieldTints.count]
                    let center = V3(side * (beamAt(t) + 0.15), sheerY(t) - 0.2, z)
                    let rot = simd_quatf(angle: rad(-side * 90 + side * 6), axis: Z)
                    let x = Xform(translation: center, rotation: rot, scale: V3(1.18, 1.18, 1.18))
                    // Lathe profiles run bottom to top (upward faces run rim to centre).
                    addH(Prim.lathe([V2(0.43, 0.0), V2(0.28, 0.028)], segments: segs, seamTile: 0.5, material: "wood.painted-exterior:" + hex(tint)), x)
                    addH(Prim.lathe(hi ? [V2(0.28, 0.028), V2(0.12, 0.05), V2(0.001, 0.055)] : [V2(0.28, 0.028), V2(0.001, 0.055)], segments: segs, seamTile: 0.5, material: "wood.painted-exterior:" + hex(alt)), x)
                    addH(Prim.lathe(hi ? [V2(0.135, 0.055), V2(0.08, 0.12), V2(0.001, 0.15)] : [V2(0.135, 0.055), V2(0.001, 0.14)], segments: segs, seamTile: 0.3, material: iron), x)
                    addH(Prim.lathe(hi ? [V2(0.415, -0.012), V2(0.462, 0.0), V2(0.46, 0.016), V2(0.415, 0.018)] : [V2(0.415, -0.012), V2(0.46, 0.008), V2(0.415, 0.018)], segments: segs, seamTile: 0.4, material: iron), x)
                }
            }

            // Oarlocks (thole pins) on the hull; oars on their own parts.
            for i in 0..<oarsPerSide {
                for (side, tag) in [(Float(1), "P"), (Float(-1), "S")] {
                    let pin = pinPoint(side, i)
                    addH(Prim.tube([pin + V3(-side * 0.09, -0.04, 0), pin + V3(side * 0.03, -0.04, 0)], radii: [0.065, 0.05], sides: hi ? 6 : 4, seamTile: 0.1, material: iron, capEnd: true))
                    if hi { addH(Prim.tube([pin + V3(0, -0.04, -0.06), pin + V3(0, 0.12, -0.06)], radii: [0.02, 0.016], sides: 5, seamTile: 0.05, material: iron, capEnd: true)) }

                    // Oar, authored abeam with a downward tilt about the pin.
                    let k = rad(Self.oarTilt)
                    let u = V3(side * cos(k), -sin(k), 0)
                    func at(_ t: Float) -> V3 { pin + u * t }
                    let name = "oar\(tag)\(i + 1)"
                    var shaft = Prim.tube([at(-Self.oarInboard), at(0.4), at(2.6), at(Self.oarReach - 0.85)], radii: [0.032, 0.05, 0.043, 0.033],
                                          sides: hi ? 6 : 4, seamTile: 0.2, material: plankWood, capEnd: true)
                    shaft.uvs = shaft.uvs.map { V2($0.y, $0.x) }; shaft.computeTangents()
                    rig.add(shaft, to: name, lods: l...l)
                    let wd = simd_normalize(simd_cross(u, Z)), nm = simd_normalize(simd_cross(wd, u))
                    func ring(_ tau: Float) -> [V3] {
                        let hw = (0.035 + 0.09 * smoothstep(0, 0.4, tau)) * (1 - 0.45 * pow(max(0, (tau - 0.8) / 0.2), 2))
                        let th = 0.018 * (1 - 0.5 * tau) + 0.006
                        let c = at(Self.oarReach - 0.85 + 0.85 * tau)
                        return [c - wd * hw, c - wd * hw * 0.5 + nm * th, c + wd * hw * 0.5 + nm * th, c + wd * hw, c + wd * hw * 0.5 - nm * th, c - wd * hw * 0.5 - nm * th]
                    }
                    let taus: [Float] = hi ? [0, 0.35, 0.8, 1] : [0, 1]
                    var blade = Prim.loft(taus.map(ring), capStart: false, capEnd: true, material: plankWood)
                    orient(&blade) { p in pin + u * simd_dot(p - pin, u) }
                    rig.add(blade, to: name, lods: l...l)
                    // Leather grip wrap at the pin.
                }
            }

            // MARK: Steering oar, starboard quarter.
            do {
                let a = V3(-(beamAt(-0.8) + 0.18), 1.55, -8.3), b = V3(-(beamAt(-0.86) + 0.45), -0.1, -9.45)
                var shaft = Prim.tube(catmull([a, a + (b - a) * 0.5, b], per: 1), radii: [0.07, 0.085, 0.06], sides: hi ? 10 : 6, seamTile: 0.2, material: plankWood, capEnd: true)
                shaft.uvs = shaft.uvs.map { V2($0.y, $0.x) }; shaft.computeTangents()
                addH(shaft)
                let dir = simd_normalize(b - a)
                let wd = simd_normalize(simd_cross(dir, X)), nm = simd_normalize(simd_cross(dir, wd))
                var blade = Prim.loft([Float(0), 0.5, 1].map { tau -> [V3] in
                    let c = b + dir * (0.05 + 0.95 * tau)
                    let hw = 0.07 + 0.2 * smoothstep(0, 0.5, tau) * (1 - 0.3 * tau)
                    return [c - wd * hw, c - nm * 0.03, c + wd * hw, c + nm * 0.03]
                }, capStart: false, capEnd: true, material: plankWood)
                orient(&blade) { p in a + dir * simd_dot(p - a, dir) }
                addH(blade)
                // Tiller bar and iron boss on the rail.
                addH(Prim.tube([a + V3(0.0, 0.1, 0.0), a + V3(0.55, 0.18, 0.05)], radii: [0.04, 0.035], sides: 6, seamTile: 0.1, material: plankWood, capEnd: true))
                addH(Prim.superellipsoid(V3(0.1, 0.14, 0.1), exponent: 2, subdivisions: hi ? 4 : 3, material: iron), Xform(translation: V3(-(beamAt(-0.8) + 0.1), 1.0 + 0.85 * pow(0.8, 2.6) - 0.26, -8.3)))
            }

            // MARK: Brazier with coals.
            do {
                let c = V3(0, -0.08, 7.0)
                for k in 0..<3 {
                    let a = Float(k) / 3 * 2 * .pi + 0.4
                    addH(Prim.tube([c + V3(0.34 * cos(a), 0.55, 0.34 * sin(a)), c + V3(0.2 * cos(a), 0.0, 0.2 * sin(a))], radii: [0.025, 0.03], sides: 6, seamTile: 0.1, material: iron, capEnd: true))
                }
                let bowl: [V2] = [V2(0.001, 0.5), V2(0.18, 0.52), V2(0.34, 0.62), V2(0.42, 0.78), V2(0.45, 0.88)]
                addH(Prim.lathe(bowl, segments: hi ? 20 : 10, seamTile: 0.3, material: iron), Xform(translation: c))
                addH(Prim.lathe([V2(0.43, 0.88), V2(0.47, 0.885), V2(0.47, 0.9), V2(0.43, 0.9)], segments: hi ? 20 : 10, seamTile: 0.3, material: iron), Xform(translation: c))
                addH(Prim.lathe([V2(0.41, 0.84), V2(0.38, 0.86), V2(0.2, 0.85), V2(0.001, 0.86)], segments: hi ? 16 : 8, seamTile: 0.3, material: "emissive.ember"), Xform(translation: c))
                addH(Prim.lathe([V2(0.17, 0.88), V2(0.17, 0.9), V2(0.07, 1.0), V2(0.001, 1.15)], segments: hi ? 10 : 6, seamTile: 0.3, material: "emissive.flame"), Xform(translation: c))
                if hi {
                    for k in 0..<4 {
                        let a = Float(k) / 4 * 2 * .pi
                        addH(Prim.tube([c + V3(0.46 * cos(a), 0.88, 0.46 * sin(a)), c + V3(0.5 * cos(a), 0.99, 0.5 * sin(a))], radii: [0.02, 0.015], sides: 5, seamTile: 0.05, material: iron, capEnd: true))
                    }
                }
            }

            // MARK: Yard options: furled bundle (0) and set sail (1). Authored at the lowered rest pose.
            do {
                let y0 = Self.yardRest, z = Self.mastZ + 0.3
                func yardSpar(_ part: Int) {
                    var s = Prim.tube([V3(-5.3, y0, z), V3(-2.5, y0, z), V3(2.5, y0, z), V3(5.3, y0, z)], radii: [0.06, 0.11, 0.11, 0.06], sides: hi ? 10 : 6, seamTile: 0.4, material: frameWood, capEnd: true)
                    s.uvs = s.uvs.map { V2($0.y, $0.x) }; s.computeTangents()
                    rig.add(s, to: "yard", option: part, lods: l...l)
                    rig.add(Prim.tube([V3(-0.2, y0, z - 0.1), V3(0.2, y0, z - 0.1)], radii: [0.17, 0.17], sides: hi ? 10 : 6, seamTile: 0.2, material: iron, capEnd: true), to: "yard", option: part, lods: l...l)
                }
                yardSpar(0); yardSpar(1)
                let stripes = 11, halfTop: Float = 4.95
                // Furled bundle: one short roll per stripe, tied with rope.
                for s in 0..<stripes {
                    let x0 = -halfTop + 2 * halfTop * Float(s) / Float(stripes), x1 = -halfTop + 2 * halfTop * Float(s + 1) / Float(stripes)
                    let path = [V3(x0, y0 + 0.2, z + 0.05), V3((x0 + x1) / 2, y0 + 0.24, z + 0.05), V3(x1, y0 + 0.2, z + 0.05)]
                    rig.add(Prim.tube(path, radii: [0.2, 0.25, 0.2], sides: hi ? 10 : 6, seamTile: 0.3, material: s % 2 == 0 ? sailRed : sailCream, capEnd: true), to: "yard", option: 0, lods: l...l)
                }
                if hi { for x: Float in [-3.6, -1.2, 1.2, 3.6] {
                    rig.add(Prim.tube([V3(x, y0 + 0.2, z + 0.05 + 0.0), V3(x + 0.04, y0 + 0.2, z + 0.05)], radii: [0.265, 0.265], sides: 10, seamTile: 0.1, material: rope, capEnd: true), to: "yard", option: 0, lods: l...l)
                } }
                // Set sail: striped panels hanging from the yard, billowed forward.
                let hgt: Float = 6.6, bil: Float = 0.75
                let ny = hi ? 12 : 5, nxs = hi ? 3 : 1
                for s in 0..<stripes {
                    var surf = Surface(material: s % 2 == 0 ? sailRed : sailCream)
                    for j in 0...ny {
                        let tv = Float(j) / Float(ny)
                        let halfW = halfTop + 0.15 * tv
                        for i in 0...nxs {
                            let u = (Float(s) + Float(i) / Float(nxs)) / Float(stripes)
                            let x = -halfW + 2 * halfW * u
                            let b = bil * pow(sin(u * .pi), 0.8) * sin(tv * .pi * 0.9 + 0.1)
                            let ripple = 0.03 * sin(u * 31 + tv * 5) * sin(tv * .pi)
                            surf.add(V3(x, y0 - 0.12 - hgt * tv, z + b + ripple), .up, V2(x, -tv * hgt))
                        }
                    }
                    let cw = UInt32(nxs + 1)
                    for j in 0..<ny { for i in 0..<nxs { let a = UInt32(j) * cw + UInt32(i); surf.quad(a, a + 1, a + cw + 1, a + cw) } }
                    var front = surf, back = surf
                    WoodParts.orientOutward(&front) { p in V3(p.x, p.y, p.z - 3) }
                    WoodParts.orientOutward(&back) { p in V3(p.x, p.y, p.z + 3) }
                    front.recomputeNormals(weldSeams: false); front.computeTangents()
                    back.recomputeNormals(weldSeams: false); back.computeTangents()
                    rig.add(front, to: "yard", option: 1, lods: l...l)
                    rig.add(back, to: "yard", option: 1, lods: l...l)
                }
                // Bolt rope along the foot and the leech.
                var foot: [V3] = []
                for i in 0...(hi ? 16 : 6) {
                    let u = Float(i) / Float(hi ? 16 : 6), x = -(halfTop + 0.15) + 2 * (halfTop + 0.15) * u
                    foot.append(V3(x, y0 - 0.12 - hgt, z + 0.0))
                }
                rig.add(Prim.tube(foot, radii: foot.map { _ in 0.03 }, sides: hi ? 6 : 4, seamTile: 0.1, material: rope, capEnd: true), to: "yard", option: 1, lods: l...l)
                if hi {
                    for s in [Float(-1), 1] {
                        rig.add(Prim.tube([V3(s * 4.9, y0 - 0.12, z + 0.0), V3(s * 5.05, y0 - 0.12 - hgt, z + 0.0)], radii: [0.03, 0.03], sides: 6, seamTile: 0.1, material: rope, capEnd: true), to: "yard", option: 1, lods: l...l)
                        // Sheet lines from the clews to the rail.
                        rig.add(Prim.tube(catmull([V3(s * 5.05, y0 - 0.12 - hgt, z), V3(s * 3.6, y0 - 0.12 - hgt - 0.2, z - 0.4), V3(s * 2.3, 1.1, z - 1.0)], per: 3), radii: Array(repeating: 0.022, count: 7), sides: 5, seamTile: 0.1, material: rope, capEnd: false), to: "yard", option: 1, lods: l...l)
                    }
                }
            }
            _ = rng.float()
        }

        // Brazier fire light, flickered by the app.
        rig.lights.append(RigLight(name: "brazier", part: "hull", position: V3(0, 1.0, 7.0), color: V3(1.0, 0.62, 0.3), intensity: 800, attenuationRadius: 6))

        rig.states = [
            RigState("underway", ["oars": 0.5, "sail": 1, "sway": 0], options: ["yard": 1]),
            RigState("catch", ["oars": 0, "sail": 1, "sway": 0], options: ["yard": 1]),
            RigState("finish", ["oars": 1, "sail": 1, "sway": 0], options: ["yard": 1]),
            RigState("furled", ["oars": 0.5, "sail": 0, "sway": 0]),
            RigState("roll-port", ["oars": 0.5, "sail": 1, "sway": 1], options: ["yard": 1]),
            RigState("roll-starboard", ["oars": 0.5, "sail": 1, "sway": -1], options: ["yard": 1]),
        ]
        groundAO(&rig, height: 0.4, floor: 0.7)
        return rig
    }
}
