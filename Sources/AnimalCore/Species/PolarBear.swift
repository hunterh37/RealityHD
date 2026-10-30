import Foundation
import RealCore

/// Polar bear: adult male, about 1.3 m at the shoulder and 2.4 m nose to tail. Long neck, narrow skull,
/// small round ears, large flat paws. Built on the SDF coat path.
extension GroundProfile {
    static let wildProfiles: [GroundProfile] = [polarBear]

    static let polarBear = GroundProfile(
        species: .polarBear, name: "Polar Bear", latin: "Ursus maritimus",
        blurb: "Cream-white coat over black skin, a long neck and a narrow skull. Walks the ice with a rolling gait.",
        anatomy: GroundAnatomy(bodyLength: 1.75, bodyDepth: 0.74, bodyWidth: 0.64, headLength: 0.63, headWidth: 0.4, headHeight: 0.38, snout: 0.3,
                               earLength: 0.09, earWidth: 0.13, tailLength: 0.14, tailWidth: 0.09, foreLeg: 0.62, hindLeg: 0.68, legRadius: 0.07, pitch: -2, eyeRadius: 0.03,
                               whiskers: false, rideHeight: 0.74,
                               neckLength: 0.44, neckRise: 14, neckThick: 1.25, neckDeep: 1.0, headDrop: 26, thighScale: 1.4, clawScale: 3.8, noseSize: 0.14, earTilt: 0.6, tailDrop: 30,
                               depthShape: [0.4, 0.86, 0.96, 1.02, 1.06, 1.08, 1.04, 0.95, 0.6], widthShape: [0.4, 0.84, 0.94, 1.0, 1.02, 1.02, 1.0, 0.9, 0.6],
                               headShape: [0.7, 1.0, 0.9, 0.7, 0.54, 0.46, 0.42, 0.4], strideScale: 1.0, withers: 0.5, earSpread: 0.4, earUp: 0.36, earRound: true, eyeSeat: 1.0),
        palette: GroundPalette(back: 0xF8F0DC, belly: 0xFAF3E4, accent: 0xEBDDB8, ear: 0xE4DAC4, nose: 0x0E0C0C, eye: 0x1A100A, claw: 0x14110E, tail: 0xF2EAD6,
                               tailTip: 0xF2EAD6, face: 0xF6EEDC, flankLine: 0.6, pattern: 0.06, strands: 900, fuzz: 0.8, muzzle: 0xEFE6D0),
        behavior: GroundBehavior(gait: .stride, walk: 1.1, run: 8, climbs: false, boldness: 0.3, skittishRadius: 30, rarity: 0.9, seasons: [.winter, .spring, .autumn],
                                 activity: [.dawn: 1.2, .day: 0.8, .dusk: 1.2, .night: 0.8],
                                 likes: [.openGround: 1, .water: 1], minHabitat: 0.5, alertRate: 0.15, visitsYards: false))
}

extension QuadrupedPlan {
    static let polar = QuadrupedPlan(
        torso: [(0.00, 0.50, 0.50, 0.50, 0.02), (0.08, 0.5, 0.62, 0.62, 0.04), (0.20, 0.68, 0.9, 0.78, 0.04),
                (0.36, 0.8, 0.86, 0.66, 0.00), (0.50, 0.84, 0.92, 0.66, 0.00), (0.64, 0.98, 1.00, 0.90, 0.00),
                (0.78, 1.02, 1.22, 1.08, 0.04), (0.90, 0.94, 1.14, 1.06, 0.02), (0.98, 0.70, 0.86, 0.80, 0.00),
                (1.03, 0.42, 0.60, 0.50, 0.00)],
        foreUpper: [(0, 0.19, 0.21, 0.21), (0.3, 0.16, 0.18, 0.18), (0.7, 0.085, 0.095, 0.095), (1, 0.065, 0.07, 0.07)],
        foreCannon: [(0, 0.068, 0.072, 0.072), (0.5, 0.056, 0.064, 0.064), (1, 0.07, 0.076, 0.076)],
        forePastern: [(0, 0.07, 0.075, 0.075), (0.5, 0.065, 0.07, 0.07), (1, 0.08, 0.085, 0.085)],
        hindUpper: [(0, 0.13, 0.16, 0.14), (0.3, 0.125, 0.15, 0.135), (0.65, 0.105, 0.125, 0.11), (1, 0.09, 0.1, 0.095)],
        hindGaskin: [(0, 0.095, 0.11, 0.1), (0.4, 0.085, 0.1, 0.09), (1, 0.078, 0.088, 0.082)],
        hindCannon: [(0, 0.065, 0.075, 0.07), (0.5, 0.06, 0.07, 0.065), (1, 0.075, 0.08, 0.08)],
        legScale: 1.75, furCards: 0, cardLength: 0.05, dog: true, tailBrush: true,
        haunchFore: V2(0.004, 0.004), haunchHind: V2(0.004, 0.004), feather: 0, lowerScale: 1.0, massScale: 2.4, toes: 5, thighMass: 0.55)
}
