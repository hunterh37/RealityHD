import simd
import Foundation

/// Parametric tapered wing section (OpenVSP names: Span, Root_Chord, Tip_Chord, Sweep, Dihedral), one
/// side of a light aircraft or UAV wing. NACA 4-digit carbon composite skin lofted root to tip, a machined
/// aluminium root rib with two spar attach lugs, a rounded tip cap, and an outboard aileron on three
/// hinge brackets along the 75 % chord line. Span runs along +X (root at -X), leading edge faces +Z.
public struct WingSection: RealArticulated {
    public static let id = "wing-section"
    public static let summary = "Parametric tapered wing section, 3.9 m span default: NACA 2412 carbon skin, aluminium root rib, tip cap and a hinged aileron."
    public static let tags = ["prop", "aerospace", "articulated"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 28, distance: 1.0, studio: true)

    /// One section's span (m), 2.0 to 5.0.
    public var span: Float = 3.9
    /// Root chord (m), 0.6 to 2.0.
    public var rootChord: Float = 1.4
    /// Tip chord (m), 0.3 to rootChord.
    public var tipChord: Float = 0.9
    /// Leading edge sweep (degrees), 0 to 35.
    public var sweep: Float = 3
    /// Dihedral (degrees), -5 to 10.
    public var dihedral: Float = 3
    /// NACA 4-digit section: max camber, camber position, thickness (2412 default).
    public var camber: Float = 0.02
    public var camberPosition: Float = 0.4
    public var thickness: Float = 0.12
    /// Aileron span as fractions of the section span, and its chord fraction.
    public var aileronFrom: Float = 0.5
    public var aileronTo: Float = 0.94
    public var aileronChord: Float = 0.25
    /// Aileron travel either way (degrees).
    public var aileronTravel: Float = 20
    public var skin: MaterialKey = "composite.carbon"
    public var fittings: MaterialKey = "metal.aluminum-brushed"
    public var fastener: MaterialKey = "metal.steel"
    /// Leading edge erosion strip.
    public var leStrip: MaterialKey = "metal.anodized-worn"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [12])
        let tanS = tan(sweep * .pi / 180), tanD = tan(dihedral * .pi / 180)
        let probe = nacaOutline(t: thickness, m: camber, p: camberPosition, n: 20)
        let yOff = -(probe.map(\.y).min() ?? 0) * rootChord + 0.002
        let zMax = rootChord / 2, zMin = min(-rootChord / 2, rootChord / 2 - span * tanS - tipChord), zShift = -(zMax + zMin) / 2
        // Station geometry: leading edge point and chord at span fraction f.
        func le(_ f: Float) -> V3 { V3(-span / 2 + f * span, yOff + f * span * tanD, rootChord / 2 - f * span * tanS + zShift) }
        func chord(_ f: Float) -> Float { rootChord + (tipChord - rootChord) * f }
        let back = V3(0, 0, -1), up = V3(0, 1, 0)
        let hingeX = 1 - aileronChord
        func surfaceY(_ outline: [V2], _ x: Float, upper: Bool) -> Float {
            let half = upper ? Array(outline.prefix(outline.count / 2 + 1)) : Array(outline.suffix(outline.count / 2 + 1))
            return half.min(by: { abs($0.x - x) < abs($1.x - x) })?.y ?? 0
        }

        for l in 0..<2 {
            let n = l == 0 ? 20 : 9
            let foil = nacaOutline(t: thickness, m: camber, p: camberPosition, n: n)
            let cut = foil.filter { $0.x <= hingeX - 0.012 }
            func rings(_ o: [V2], _ a: Float, _ b: Float, _ k: Int) -> [[V3]] {
                (0...k).map { i in let f = a + (b - a) * Float(i) / Float(k); return airfoilRing(o, le: le(f), chord: chord(f), chordDir: back, up: up) }
            }
            var m = Model(name: Self.id)
            // Skin: inboard full section, cut section ahead of the aileron cove, outboard full section and tip.
            m.add(Prim.loft(rings(foil, 0.004, aileronFrom, l == 0 ? 6 : 2), capStart: true, capEnd: true, material: skin))
            m.add(Prim.loft(rings(cut, aileronFrom, aileronTo, l == 0 ? 6 : 2), capStart: true, capEnd: true, material: skin))
            m.add(Prim.loft(rings(foil, aileronTo, 1, 1), capStart: true, material: skin))
            // Leading edge erosion strip: bare metal over the front 5 % of chord, scuffed by rain and grit.
            let lePts = foil.filter { $0.x <= 0.05 }.map { V2($0.x * 1.01 - 0.0012, $0.y * 1.06) }
            m.add(Prim.loft(rings(lePts, 0.004, 1, l == 0 ? 8 : 2), material: leStrip))
            // Tip cap: rounded fairing past the last station.
            let tipLE = le(1), tc = chord(1)
            var tipRings: [[V3]] = []
            for (k, s) in [Float(1), 0.93, 0.75, 0.45].enumerated() {
                let dx = [Float(0), 0.025, 0.05, 0.065][k]
                let ring = foil.map { p -> V3 in
                    let q = V2(p.x, p.y * s + (1 - s) * 0.02)
                    return tipLE + back * (q.x * tc * (0.98 + 0.02 * s)) + up * (q.y * tc) + V3(dx, dx * tanD, 0)
                }
                tipRings.append(ring)
            }
            m.add(Prim.loft(tipRings, capEnd: true, material: skin))
            // Root rib: aluminium plate the shape of the section, slightly proud of the skin.
            let rib = foil.map { V2($0.x * rootChord, $0.y * rootChord) }
            m.add(Prim.extrude(Shape2D.offset(rib, 0.004), depth: 0.012, bevel: 0.002, bevelSegments: 1, material: fittings),
                  Xform(translation: le(0) + V3(-0.002, 0, 0), rotation: simd_quatf(angle: .pi / 2, axis: up)))
            // Spar attach lugs at 25 % and 70 % chord, pointing inboard.
            for xc: Float in [0.25, 0.7] {
                let yu = surfaceY(foil, xc, upper: true), yl = surfaceY(foil, xc, upper: false)
                let h = (yu - yl) * rootChord * 0.55
                let c = le(0) + back * (xc * rootChord) + up * ((yu + yl) / 2 * rootChord)
                m.add(Prim.roundedBox(V3(0.07, h, 0.05), radius: 0.008, bevelSegments: l == 0 ? 2 : 1, material: fittings),
                      Xform(translation: c + V3(-0.04, 0, 0)))
                m.add(Prim.cylinder(radius: 0.012, height: 0.054, bevel: 0.002, segments: l == 0 ? 14 : 8, material: fastener),
                      Xform(translation: c + V3(-0.05, 0, -0.027), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
            }
            if l == 0 {
                // Access panels on the lower skin with screw rings.
                for f: Float in [0.22, 0.62] {
                    let xc: Float = 0.35, c = chord(f)
                    let yl = surfaceY(foil, xc, upper: false)
                    let p = le(f) + back * (xc * c) + up * (yl * c - 0.0006)
                    let w: Float = 0.26, d = 0.16 * c / rootChord
                    m.add(Prim.roundedBox(V3(w, 0.002, d), radius: 0.001, bevelSegments: 1, material: fittings),
                          Xform(translation: p, rotation: simd_quatf(angle: dihedral * .pi / 180, axis: V3(0, 0, 1))))
                    for sx: Float in [-1, 0, 1] { for sz: Float in [-1, 1] {
                        rivet(&m, at: p + V3(sx * (w / 2 - 0.015), sx * (w / 2 - 0.015) * tanD - 0.0012, sz * (d / 2 - 0.012)), normal: V3(0, -1, 0),
                              radius: 0.004, material: fastener)
                    } }
                }
                // Spar line fastener row on the upper skin at 25 % chord.
                let row = stride(from: Float(0.03), through: 0.97, by: 0.94 / 26).map { f -> V3 in
                    let c = chord(f), yu = surfaceY(foil, 0.25, upper: true)
                    return le(f) + back * (0.25 * c) + up * (yu * c + 0.0004)
                }
                for p in row { rivet(&m, at: p, normal: up, radius: 0.0035, material: fastener) }
            }
            rig.base[l] = m
        }

        // Aileron: hinge along the hingeX chord line between aileronFrom and aileronTo.
        let ha = le(aileronFrom) + V3(0, 0, -hingeX * chord(aileronFrom)), hb = le(aileronTo) + V3(0, 0, -hingeX * chord(aileronTo))
        let probeHinge = nacaOutline(t: thickness, m: camber, p: camberPosition, n: 20)
        let hy = (surfaceY(probeHinge, hingeX, upper: true) + surfaceY(probeHinge, hingeX, upper: false)) / 2
        let pa = ha + V3(0, hy * chord(aileronFrom), 0), pb = hb + V3(0, hy * chord(aileronTo), 0)
        rig.part("aileron", pivot: pa, joint: .hinge(axis: simd_normalize(pb - pa), -aileronTravel...aileronTravel, duration: 0.4))
        for l in 0..<2 {
            let foil = nacaOutline(t: thickness, m: camber, p: camberPosition, n: l == 0 ? 20 : 9)
            var aft = foil.filter { $0.x >= hingeX }
            // Rounded nose on the hinge line so the surface can swing inside the cove.
            let upperCount = foil.prefix(foil.count / 2 + 1).filter { $0.x >= hingeX }.count
            aft.insert(V2(hingeX - 0.01, hy), at: upperCount)
            let k = l == 0 ? 5 : 1
            let inset: Float = 0.006 / span
            let rs = (0...k).map { i -> [V3] in
                let f = aileronFrom + inset + (aileronTo - aileronFrom - 2 * inset) * Float(i) / Float(k)
                return airfoilRing(aft, le: le(f), chord: chord(f), chordDir: back, up: up)
            }
            rig.add(Prim.loft(rs, capStart: true, capEnd: true, material: skin), to: "aileron", lods: l...l)
        }
        // Hinge brackets (fixed) and the control horn (moves) on the lower side.
        for f in [aileronFrom + 0.03, (aileronFrom + aileronTo) / 2, aileronTo - 0.03] {
            let c = chord(f), p = le(f) + back * (hingeX * c)
            let yl = surfaceY(probeHinge, hingeX, upper: false)
            rig.base[0].add(Prim.roundedBox(V3(0.012, 0.03, 0.06), radius: 0.003, bevelSegments: 1, material: fittings),
                   Xform(translation: p + up * (yl * c - 0.006) + V3(0, 0, -0.01)))
        }
        var horn = Model(name: Self.id)
        let fh = aileronFrom + 0.08, ch = chord(fh)
        let hp = le(fh) + back * ((hingeX + 0.04) * ch) + up * (surfaceY(probeHinge, hingeX + 0.04, upper: false) * ch)
        horn.add(Prim.extrude([V2(-0.03, 0), V2(0.03, 0), V2(0.008, -0.07), V2(-0.008, -0.07)], depth: 0.005, bevel: 0.0015, bevelSegments: 1, material: fittings),
                 Xform(translation: hp, rotation: simd_quatf(angle: .pi / 2, axis: up)))
        rig.add(horn, to: "aileron", lod: 0)

        rig.states = [RigState("neutral"), RigState("aileron-up", ["aileron": -aileronTravel]), RigState("aileron-down", ["aileron": aileronTravel])]
        groundAO(&rig, height: 0.15, floor: 0.6)
        return rig
    }
}
