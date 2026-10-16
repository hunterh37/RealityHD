import Foundation
import RealCore

/// Hunting game on four legs. Proportions follow adult field measurements: shoulder height, body length
/// from chest to rump, and cannon length. Antlered variants add the rack only.
extension GroundProfile {
    static func profile(_ s: GroundSpecies, _ v: GroundVariant) -> GroundProfile {
        var p = table[s]!
        guard v == .antlered, s.hasAntlers else { return p }
        p.variant = .antlered
        switch s {
        case .whitetailDeer:
            p.name = "Whitetail Buck"
            p.anatomy.antlers = .whitetail
            // Bucks run heavier through the neck and chest.
            p.anatomy.neckThick *= 1.25; p.anatomy.bodyDepth *= 1.05; p.anatomy.bodyWidth *= 1.08
        case .rockyMountainElk:
            p.name = "Bull Elk"
            p.anatomy.antlers = .elk
            p.anatomy.neckThick *= 1.2; p.anatomy.bodyDepth *= 1.04; p.anatomy.bodyLength *= 1.03
        default: break
        }
        return p
    }

    static let huntingProfiles: [GroundProfile] = [whitetail, elk, boar, bear, coyote]

    private static let hSeasons: Set<AnimalSeason> = [.spring, .summer, .autumn, .winter]

    static let whitetail = GroundProfile(
        species: .whitetailDeer, name: "Whitetail Deer", latin: "Odocoileus virginianus",
        blurb: "Reddish-brown with a white flag tail. Browses edges at dawn and dusk and bounds off at a snort.",
        anatomy: GroundAnatomy(bodyLength: 1.0, bodyDepth: 0.40, bodyWidth: 0.25, headLength: 0.28, headWidth: 0.125, headHeight: 0.14, snout: 0.08,
                               earLength: 0.17, earWidth: 0.085, tailLength: 0.26, tailWidth: 0.1, foreLeg: 0.7, hindLeg: 0.72, legRadius: 0.018, pitch: -2, eyeRadius: 0.014,
                               whiskers: false, digitigrade: true, hooves: true, rideHeight: 0.745, foreAnkle: 0.11, hindAnkle: 0.43,
                               neckLength: 0.36, neckRise: 42, neckThick: 0.8, neckDeep: 1.2, headDrop: 22, thighScale: 3.0, noseSize: 0.13, earTilt: 0.85, tailDrop: 55,
                               depthShape: [0.30, 0.74, 0.80, 0.78, 0.92, 1.02, 1.04, 0.92, 0.55], widthShape: [0.30, 0.82, 0.88, 0.80, 0.90, 0.98, 1.0, 0.86, 0.5],
                               headShape: [0.82, 1.0, 0.98, 0.84, 0.62, 0.42, 0.3, 0.26], strideScale: 1, throatFrom: 0.45, withers: 0.6),
        palette: GroundPalette(back: 0xB48556, belly: 0xF4EEE2, accent: 0x7E5B38, ear: 0xD8C8B0, nose: 0x1A1512, eye: 0x1C130B, claw: 0x2B2521, tail: 0xB48556,
                               tailTip: 0xFAF6F0, face: 0x9A7A56, flankLine: 0.62, pattern: 0.35, strands: 150, fuzz: 0.1, muzzle: 0xCEC4B0, patch: 0xF6F2EA),
        behavior: GroundBehavior(gait: .stride, walk: 1.2, run: 11, climbs: false, boldness: 0.1, skittishRadius: 25, rarity: 0.4, seasons: hSeasons,
                                 activity: [.dawn: 1.5, .day: 0.4, .dusk: 1.5, .night: 0.6],
                                 likes: [.openGround: 1, .shrub: 0.7, .tree: 0.6], minHabitat: 0.5, alertRate: 0.2, visitsYards: false))

    static let elk = GroundProfile(
        species: .rockyMountainElk, name: "Rocky Mountain Elk", latin: "Cervus canadensis",
        blurb: "Tawny body, dark mane and a pale rump patch. Herds graze meadows and bugle in the rut.",
        anatomy: GroundAnatomy(bodyLength: 1.55, bodyDepth: 0.64, bodyWidth: 0.38, headLength: 0.44, headWidth: 0.17, headHeight: 0.21, snout: 0.12,
                               earLength: 0.21, earWidth: 0.1, tailLength: 0.13, tailWidth: 0.07, foreLeg: 1.0, hindLeg: 1.0, legRadius: 0.037, pitch: -1, eyeRadius: 0.019,
                               whiskers: false, digitigrade: true, hooves: true, rideHeight: 1.02, foreAnkle: 0.17, hindAnkle: 0.66,
                               neckLength: 0.58, neckRise: 38, neckThick: 1.0, neckDeep: 1.05, headDrop: 24, thighScale: 2.9, noseSize: 0.13, earTilt: 0.8, tailDrop: 30,
                               depthShape: [0.30, 0.74, 0.80, 0.78, 0.92, 1.02, 1.04, 0.92, 0.55], widthShape: [0.30, 0.82, 0.88, 0.80, 0.90, 0.98, 1.0, 0.86, 0.5],
                               headShape: [0.82, 1.0, 0.98, 0.84, 0.64, 0.46, 0.34, 0.3], darkLimbs: true, strideScale: 1.3, maneDrop: 0.055, rumpPatch: 0.2, withers: 0.9),
        palette: GroundPalette(back: 0xD2B284, belly: 0xB8A07A, accent: 0x5A4230, ear: 0xD2BFA4, nose: 0x1A1512, eye: 0x20150B, claw: 0x2B2521, tail: 0xE6D4AE,
                               tailTip: 0xE6D4AE, face: 0x7E5C42, flankLine: 0.6, pattern: 0.4, strands: 130, fuzz: 0.15, muzzle: 0xA88C6C, patch: 0xE9D9B6, mane: 0x3C281E),
        behavior: GroundBehavior(gait: .stride, walk: 1.3, run: 12, climbs: false, boldness: 0.05, skittishRadius: 30, rarity: 0.6, seasons: hSeasons,
                                 activity: [.dawn: 1.5, .day: 0.4, .dusk: 1.5, .night: 0.5],
                                 likes: [.openGround: 1, .tree: 0.6], minHabitat: 0.6, alertRate: 0.2, visitsYards: false))

    static let boar = GroundProfile(
        species: .wildBoar, name: "Wild Boar", latin: "Sus scrofa",
        blurb: "Coarse grizzled bristle, a wedge head and short tusks. Roots up meadows and wallows at dusk.",
        anatomy: GroundAnatomy(bodyLength: 0.95, bodyDepth: 0.52, bodyWidth: 0.36, headLength: 0.42, headWidth: 0.21, headHeight: 0.25, snout: 0.16,
                               earLength: 0.14, earWidth: 0.1, tailLength: 0.26, tailWidth: 0.035, foreLeg: 0.46, hindLeg: 0.46, legRadius: 0.031, pitch: -6, eyeRadius: 0.009,
                               whiskers: false, digitigrade: true, hooves: true, rideHeight: 0.55, foreAnkle: 0.1, hindAnkle: 0.17,
                               neckLength: 0.03, neckRise: 10, neckThick: 1.0, neckDeep: 1.15, headDrop: 12, thighScale: 2.2, noseSize: 0.42, snoutDisc: true, earTilt: 0.25, tailDrop: 50,
                               depthShape: [0.35, 0.78, 0.86, 0.94, 1.02, 1.08, 1.06, 0.95, 0.6], widthShape: [0.35, 0.8, 0.92, 0.98, 1.0, 1.0, 0.98, 0.9, 0.6],
                               headShape: [0.55, 1.0, 0.92, 0.7, 0.5, 0.4, 0.36, 0.34], tusks: 0.075, strideScale: 0.8, bristle: 0.06, withers: 1.1),
        palette: GroundPalette(back: 0x9C8468, belly: 0xA08A70, accent: 0xD0B890, ear: 0x2E241E, nose: 0x7A6256, eye: 0x1A1008, claw: 0x2B2521, tail: 0x806C58,
                               tailTip: 0x3A2E24, face: 0x8A7662, flankLine: 0.6, pattern: 0.8, strands: 90, fuzz: 0.3, mane: 0x2A2019),
        behavior: GroundBehavior(gait: .stride, walk: 1.0, run: 10, climbs: false, boldness: 0.2, skittishRadius: 18, rarity: 0.5, seasons: hSeasons,
                                 activity: [.dawn: 1.2, .day: 0.3, .dusk: 1.5, .night: 1.4],
                                 likes: [.openGround: 1, .shrub: 0.8, .water: 0.8], minHabitat: 0.4, alertRate: 0.1, visitsYards: false))

    static let bear = GroundProfile(
        species: .blackBear, name: "Black Bear", latin: "Ursus americanus",
        blurb: "Black coat, tan muzzle and a rolling walk. Forages berries and carrion and avoids people.",
        anatomy: GroundAnatomy(bodyLength: 1.15, bodyDepth: 0.58, bodyWidth: 0.46, headLength: 0.4, headWidth: 0.29, headHeight: 0.31, snout: 0.12,
                               earLength: 0.09, earWidth: 0.09, tailLength: 0.08, tailWidth: 0.07, foreLeg: 0.5, hindLeg: 0.52, legRadius: 0.05, pitch: -3, eyeRadius: 0.0085,
                               whiskers: false, rideHeight: 0.62,
                               neckLength: 0.1, neckRise: 15, neckThick: 0.95, neckDeep: 1.0, headDrop: 12, thighScale: 1.35, clawScale: 2.4, noseSize: 0.16, earTilt: 0.45,
                               depthShape: [0.4, 0.86, 0.96, 1.02, 1.06, 1.08, 1.04, 0.95, 0.6], widthShape: [0.4, 0.84, 0.94, 1.0, 1.02, 1.02, 1.0, 0.9, 0.6],
                               headShape: [0.85, 1.0, 0.98, 0.88, 0.76, 0.64, 0.56, 0.5], strideScale: 0.8, withers: 1.0),
        palette: GroundPalette(back: 0xB4977A, belly: 0xA38A70, accent: 0xD8C0A0, ear: 0x6E5A48, nose: 0x120E0C, eye: 0x2A1C10, claw: 0x4A423A, tail: 0x84705E,
                               tailTip: 0x84705E, face: 0xA68C70, flankLine: 0.6, pattern: 0.5, strands: 140, fuzz: 0.15, muzzle: 0xD2AE7C),
        behavior: GroundBehavior(gait: .stride, walk: 1.0, run: 9, climbs: false, boldness: 0.2, skittishRadius: 28, rarity: 0.7, seasons: [.spring, .summer, .autumn],
                                 activity: [.dawn: 1.3, .day: 0.6, .dusk: 1.4, .night: 0.8],
                                 likes: [.shrub: 1, .tree: 0.8, .water: 0.6], minHabitat: 0.5, alertRate: 0.15, visitsYards: false))

    static let coyote = GroundProfile(
        species: .coyote, name: "Coyote", latin: "Canis latrans",
        blurb: "Grizzled grey-buff with a bushy black-tipped tail. Trots the meadow edge and yips at dusk.",
        anatomy: GroundAnatomy(bodyLength: 0.66, bodyDepth: 0.27, bodyWidth: 0.17, headLength: 0.22, headWidth: 0.1, headHeight: 0.12, snout: 0.09,
                               earLength: 0.11, earWidth: 0.065, tailLength: 0.34, tailWidth: 0.12, foreLeg: 0.46, hindLeg: 0.47, legRadius: 0.0185, pitch: -2, eyeRadius: 0.0085,
                               whiskers: true, digitigrade: true, rideHeight: 0.485, foreAnkle: 0.085, hindAnkle: 0.19,
                               neckLength: 0.1, neckRise: 28, neckThick: 0.7, neckDeep: 1.15, headDrop: 14, thighScale: 2.4, clawScale: 0.9, noseSize: 0.12, earTilt: 0.35, tailDrop: 40,
                               depthShape: [0.35, 0.8, 0.86, 0.78, 0.88, 1.0, 1.04, 0.92, 0.55], widthShape: [0.35, 0.8, 0.88, 0.82, 0.9, 0.98, 1.0, 0.86, 0.5],
                               headShape: [0.8, 1.0, 0.94, 0.76, 0.54, 0.38, 0.28, 0.24], strideScale: 1, withers: 0.5),
        palette: GroundPalette(back: 0xB09878, belly: 0xEADFCB, accent: 0x4A3A2E, ear: 0xB59A7C, nose: 0x0F0C0A, eye: 0xC48C26, claw: 0x2B2521, tail: 0xA89270,
                               tailTip: 0xD8CAAA, face: 0xC09E78, flankLine: 0.58, pattern: 0.1, strands: 120, fuzz: 0.3, muzzle: 0xDCCCAA),
        behavior: GroundBehavior(gait: .stride, walk: 1.2, run: 12, climbs: false, boldness: 0.15, skittishRadius: 22, rarity: 0.55, seasons: hSeasons,
                                 activity: [.dawn: 1.4, .day: 0.4, .dusk: 1.5, .night: 1.3],
                                 likes: [.openGround: 1, .shrub: 0.6], minHabitat: 0.4, alertRate: 0.3, visitsYards: false))
}
