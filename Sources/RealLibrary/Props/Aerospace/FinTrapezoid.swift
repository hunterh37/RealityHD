import simd
import Foundation

/// Trapezoidal rocket fin, 0.9 m root chord x 0.6 m span. A thin symmetric-section aluminium panel
/// (bare, red tip band) stands on a machined root rail; a titanium leading edge cap and riveted root doublers hold
/// it. The panel cants about the root chord on two hinge pins in the rail end lugs (-5 to +5 degrees,
/// set in the workshop). Leading edge faces +X, span is +Y, the rail sits on y = 0.
public struct FinTrapezoid: RealArticulated {
    public static let id = "fin-trapezoid"
    public static let summary = "Trapezoidal rocket fin, 0.9 m root x 0.6 m span: tapered aluminium panel with rounded leading edge on a riveted root rail that cants -5 to +5 degrees."
    public static let tags = ["prop", "aerospace", "metal", "articulated"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 18, distance: 1.7, studio: true)

    /// Root chord (m).
    public var rootChord: Float = 0.9
    /// Tip chord (m).
    public var tipChord: Float = 0.36
    /// Span from the rail top to the tip (m).
    public var span: Float = 0.57
    /// Leading edge sweep back from root to tip (m along X).
    public var sweep: Float = 0.4
    /// Panel thickness at the root (m).
    public var thickness: Float = 0.012
    /// Cant limit either way (degrees).
    public var cantLimit: Float = 5
    /// Panel skin (bare aluminium sheet).
    public var panel: MaterialKey = "metal.anodized-worn"
    /// Tip band paint (sRGB hex) and where it starts as a fraction of span.
    public var bandColor: UInt32 = 0xB8261C
    public var tipBand: Float = 0.84
    public var rail: MaterialKey = "metal.aluminum-brushed"
    public var edge: MaterialKey = "metal.titanium"
    public var fastener: MaterialKey = "metal.steel"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [5])
        let railH: Float = 0.03, railW: Float = 0.07, L = rootChord + 0.02
        let painted = panel
        let pivotY = railH - 0.004

        // Root rail: flat base plate with a raised centre spine, end lugs carrying the hinge pins.
        for l in 0..<2 {
            var m = Model(name: Self.id)
            m.add(Prim.roundedBox(V3(L, 0.008, railW), radius: 0.003, bevelSegments: l == 0 ? 2 : 1, material: rail),
                  Xform(translation: V3(0, 0.004, 0)))
            m.add(Prim.roundedBox(V3(L - 0.06, railH - 0.006, 0.026), radius: 0.004, bevelSegments: l == 0 ? 2 : 1, material: rail),
                  Xform(translation: V3(0, 0.006 + (railH - 0.006) / 2 - 0.001, 0)))
            for s: Float in [-1, 1] {
                m.add(Prim.roundedBox(V3(0.026, railH + 0.008, 0.036), radius: 0.005, bevelSegments: l == 0 ? 2 : 1, material: rail),
                      Xform(translation: V3(s * (L / 2 - 0.016), (railH + 0.008) / 2, 0)))
                if l == 0 {
                    // Hinge pin head and nut on each end lug, along X.
                    hexBolt(&m, at: V3(s * (L / 2 - 0.003 + 0.0005), pivotY + 0.004, 0), normal: V3(s, 0, 0), size: 0.009, material: fastener)
                    // Mounting bolts through the base flanges.
                    for k in 0..<4 {
                        let x = -L / 2 + 0.08 + Float(k) * (L - 0.16) / 3
                        for z: Float in [-1, 1] {
                            hexBolt(&m, at: V3(x + rng.float(-0.002...0.002), 0.008, z * (railW / 2 - 0.011)), normal: .up, size: 0.007, material: fastener)
                        }
                    }
                }
            }
            rig.base[l] = m
        }

        // Fin panel: NACA 00xx section, tapered and swept, rooted inside the rail spine.
        rig.part("fin", pivot: V3(0, pivotY, 0), joint: .hinge(axis: V3(1, 0, 0), -cantLimit...cantLimit, duration: 0.5))
        let rootLE = rootChord / 2
        let band: MaterialKey = "sign.red-worn:" + String(format: "%06X", bandColor)
        for l in 0..<2 {
            let foil = nacaOutline(t: thickness / rootChord, n: l == 0 ? 14 : 7)
            let rings = l == 0 ? 6 : 2
            func ring(_ f: Float) -> [V3] {
                let y = railH - 0.012 + f * (span + 0.012)
                let c = rootChord + (tipChord - rootChord) * f
                return airfoilRing(foil, le: V3(rootLE - sweep * f, y, 0), chord: c, chordDir: V3(-1, 0, 0), up: V3(0, 0, 1))
            }
            // Bare panel, then a red tip band (range marking) closing the tip.
            rig.add(Prim.loft((0...rings).map { ring(Float($0) / Float(rings) * tipBand) }, material: painted), to: "fin", lods: l...l)
            rig.add(Prim.loft([ring(tipBand), ring((tipBand + 1) / 2), ring(1)], capEnd: true, material: band), to: "fin", lods: l...l)
            // Titanium leading edge cap: a tapered rod along the leading edge.
            let lePts = (0...4).map { k -> V3 in
                let f = Float(k) / 4
                return V3(rootLE - sweep * f + 0.002, railH - 0.002 + f * (span - 0.004), 0)
            }
            let leR = (0...4).map { k -> Float in
                let f = Float(k) / 4
                return (thickness * 0.42) * (1 + (tipChord / rootChord - 1) * f) + 0.0012
            }
            rig.add(Prim.tube(lePts, radii: leR, sides: l == 0 ? 10 : 6, seamTile: 0.05, material: edge, capEnd: true), to: "fin", lods: l...l)
        }
        // Root doublers: angle strips either side of the panel, riveted through.
        var dbl = Model(name: Self.id)
        for z: Float in [-1, 1] {
            dbl.add(Prim.roundedBox(V3(rootChord - 0.1, 0.05, 0.004), radius: 0.0015, bevelSegments: 1, material: rail),
                    Xform(translation: V3(-0.02, railH + 0.02, z * (thickness * 0.5 + 0.002))))
            let row = [V3(-rootChord / 2 + 0.05, railH + 0.03, z * (thickness * 0.5 + 0.004)),
                       V3(rootChord / 2 - 0.09, railH + 0.03, z * (thickness * 0.5 + 0.004))]
            rivetRow(&dbl, along: row, spacing: 0.06, normal: { _ in V3(0, 0, z) }, radius: 0.0035, material: fastener)
        }
        rig.add(dbl, to: "fin", lod: 0)
        var dbl1 = Model(name: Self.id)
        for z: Float in [-1, 1] {
            dbl1.add(Prim.roundedBox(V3(rootChord - 0.1, 0.05, 0.004), radius: 0.0015, bevelSegments: 1, material: rail),
                     Xform(translation: V3(-0.02, railH + 0.02, z * (thickness * 0.5 + 0.002))))
        }
        rig.add(dbl1, to: "fin", lod: 1)

        rig.states = [RigState("neutral"), RigState("cant-left", ["fin": -cantLimit]), RigState("cant-right", ["fin": cantLimit])]
        groundAO(&rig, height: 0.06, floor: 0.6)
        return rig
    }
}
