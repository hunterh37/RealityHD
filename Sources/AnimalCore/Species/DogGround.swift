import Foundation
import RealCore

/// Dog breeds. Adult proportions from breed standards: height at the withers, body length from sternum to
/// buttock, skull and muzzle ratio. Pets, so never sent to yards by `VisitScheduler`.
extension GroundProfile {
    static let dogProfiles: [GroundProfile] = [goldenRetriever, germanShepherd, pembrokeCorgi]

    private static let dogSeasons: Set<AnimalSeason> = [.spring, .summer, .autumn, .winter]

    static let goldenRetriever = GroundProfile(
        species: .goldenRetriever, name: "Golden Retriever", latin: "Canis lupus familiaris",
        blurb: "Feathered gold coat, broad skull and soft hanging ears. Fetches, leans on a hand and wags with the whole back half.",
        anatomy: GroundAnatomy(bodyLength: 0.74, bodyDepth: 0.31, bodyWidth: 0.25, headLength: 0.26, headWidth: 0.15, headHeight: 0.16, snout: 0.1,
                               earLength: 0.15, earWidth: 0.115, tailLength: 0.4, tailWidth: 0.15, foreLeg: 0.5, hindLeg: 0.5, legRadius: 0.03, pitch: -1, eyeRadius: 0.0105,
                               whiskers: false, digitigrade: true, rideHeight: 0.5, foreAnkle: 0.085, hindAnkle: 0.17,
                               neckLength: 0.16, neckRise: 36, neckThick: 1.0, neckDeep: 1.1, headDrop: 8, thighScale: 1.5, clawScale: 0.8, noseSize: 0.13, earTilt: 0.5, tailDrop: 28,
                               depthShape: [0.35, 0.82, 0.92, 0.9, 0.92, 1.0, 1.04, 0.92, 0.55], widthShape: [0.35, 0.82, 0.9, 0.86, 0.92, 1.0, 1.0, 0.88, 0.5],
                               headShape: [0.86, 1.0, 1.0, 0.94, 0.7, 0.6, 0.56, 0.5], strideScale: 1.1, withers: 0.3, earDrop: 1),
        palette: GroundPalette(back: 0xDCA95C, belly: 0xDDB97E, accent: 0xE8CB96, ear: 0xB9863F, nose: 0x151110, eye: 0x3A2412, claw: 0x2B2521, tail: 0xD4A560,
                               tailTip: 0xE6C48C, face: 0xDDAE68, flankLine: 0.6, pattern: 0.08, strands: 360, fuzz: 0.7, muzzle: 0xDDB87C),
        behavior: GroundBehavior(gait: .stride, walk: 1.1, run: 7, climbs: false, boldness: 1, skittishRadius: 0.3, rarity: 0.2, seasons: dogSeasons,
                                 activity: [.dawn: 1.2, .day: 1, .dusk: 1.2, .night: 0.3],
                                 likes: [.openGround: 1], minHabitat: 0.1, alertRate: 0.25, visitsYards: false))

    static let germanShepherd = GroundProfile(
        species: .germanShepherd, name: "German Shepherd", latin: "Canis lupus familiaris",
        blurb: "Black saddle over tan, erect ears and a sloping back. Watches the doorway and trots beside a hand.",
        anatomy: GroundAnatomy(bodyLength: 0.8, bodyDepth: 0.31, bodyWidth: 0.22, headLength: 0.27, headWidth: 0.13, headHeight: 0.15, snout: 0.115,
                               earLength: 0.13, earWidth: 0.085, tailLength: 0.42, tailWidth: 0.13, foreLeg: 0.52, hindLeg: 0.52, legRadius: 0.029, pitch: -4, eyeRadius: 0.0095,
                               whiskers: false, digitigrade: true, rideHeight: 0.52, foreAnkle: 0.085, hindAnkle: 0.19,
                               neckLength: 0.11, neckRise: 38, neckThick: 0.75, neckDeep: 1.15, headDrop: 10, thighScale: 1.5, clawScale: 0.8, noseSize: 0.12, earTilt: 0.22, tailDrop: 40,
                               depthShape: [0.35, 0.8, 0.9, 0.82, 0.88, 1.0, 1.04, 0.9, 0.52], widthShape: [0.35, 0.8, 0.88, 0.8, 0.88, 0.96, 0.98, 0.84, 0.48],
                               headShape: [0.84, 1.0, 0.98, 0.9, 0.66, 0.5, 0.44, 0.4], strideScale: 1.1, withers: 0.6),
        palette: GroundPalette(back: 0x2A2019, belly: 0xA06A2C, accent: 0x1A1410, ear: 0x3A2A1E, nose: 0x0F0C0A, eye: 0x3A2412, claw: 0x1E1914, tail: 0x2A2019,
                               tailTip: 0x1A1410, face: 0xA06C32, flankLine: 0.5, pattern: 0.1, strands: 320, fuzz: 0.45, muzzle: 0x2C2018),
        behavior: GroundBehavior(gait: .stride, walk: 1.2, run: 9, climbs: false, boldness: 0.9, skittishRadius: 0.3, rarity: 0.25, seasons: dogSeasons,
                                 activity: [.dawn: 1.2, .day: 1, .dusk: 1.2, .night: 0.5],
                                 likes: [.openGround: 1], minHabitat: 0.1, alertRate: 0.35, visitsYards: false))

    static let pembrokeCorgi = GroundProfile(
        species: .pembrokeCorgi, name: "Pembroke Welsh Corgi", latin: "Canis lupus familiaris",
        blurb: "Low and long with a fox face, big upright ears and a white chest. Herds ankles and trots at hand height.",
        anatomy: GroundAnatomy(bodyLength: 0.58, bodyDepth: 0.25, bodyWidth: 0.19, headLength: 0.21, headWidth: 0.12, headHeight: 0.125, snout: 0.085,
                               earLength: 0.12, earWidth: 0.085, tailLength: 0.05, tailWidth: 0.05, foreLeg: 0.2, hindLeg: 0.2, legRadius: 0.028, pitch: 0, eyeRadius: 0.0085,
                               whiskers: false, rideHeight: 0.26,
                               neckLength: 0.07, neckRise: 30, neckThick: 0.8, neckDeep: 1.05, headDrop: 6, thighScale: 1.35, clawScale: 0.8, noseSize: 0.12, earTilt: 0.3, tailDrop: 0,
                               depthShape: [0.4, 0.86, 0.96, 1.0, 1.02, 1.04, 1.04, 0.95, 0.6], widthShape: [0.4, 0.86, 0.94, 0.98, 1.0, 1.02, 1.0, 0.9, 0.55],
                               headShape: [0.84, 1.0, 0.98, 0.9, 0.68, 0.54, 0.48, 0.44], strideScale: 0.55, withers: 0.2),
        palette: GroundPalette(back: 0xC27832, belly: 0xF4ECDD, accent: 0xF2E8D6, ear: 0xB86F2C, nose: 0x151110, eye: 0x2E1A0C, claw: 0x2B2521, tail: 0xC27832,
                               tailTip: 0xC27832, face: 0xC98240, flankLine: 0.3, pattern: 0.1, strands: 340, fuzz: 0.55, muzzle: 0xF0E4D0),
        behavior: GroundBehavior(gait: .stride, walk: 0.9, run: 5, climbs: false, boldness: 1, skittishRadius: 0.3, rarity: 0.2, seasons: dogSeasons,
                                 activity: [.dawn: 1.2, .day: 1, .dusk: 1.2, .night: 0.3],
                                 likes: [.openGround: 1], minHabitat: 0.1, alertRate: 0.3, visitsYards: false))
}
