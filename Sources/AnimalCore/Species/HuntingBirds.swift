import Foundation
import RealCore

/// Ground game birds. Measurements are adult males: a tom turkey stands about 0.95 m with the head up,
/// a ringneck cock about 0.4 m with a tail as long as the body and neck together.
extension BirdProfile {
    private static let hAll: Set<AnimalSeason> = [.spring, .summer, .autumn, .winter]
    private static let hDay: [DayPart: Float] = [.dawn: 1.4, .day: 0.8, .dusk: 1.1, .night: 0]

    static let turkey = BirdProfile(
        species: .wildTurkey, name: "Wild Turkey", latin: "Meleagris gallopavo",
        blurb: "Bronze-black body, bare blue and red head, fan tail and chest beard. Gobbles at dawn and roosts in trees.",
        anatomy: BirdAnatomy(length: 1.08, wingspan: 1.4, bodyLength: 0.54, bodyDepth: 0.33, bodyWidth: 0.27, restPitch: 22,
                             neckLength: 0.34, neckPitch: 58, headLength: 0.11, headWidth: 0.066, headHeight: 0.075,
                             beakLength: 0.03, beakDepth: 0.0235, beakWidth: 0.0165, beakCurve: 0.004, tailLength: 0.34, tailWidth: 0.2,
                             tailFork: -0.03, tailFeathers: 18, tarsus: 0.17, toeLength: 0.09, crestHeight: 0, crestLength: 0,
                             eyeRadius: 0.0065, wingChord: 0.3, primaries: 10, bounds: false,
                             tibia: 0.14, caruncle: 0.05, neckThick: 0.34, beard: 0.2),
        plumage: Plumage(crown: 0x7F9AC0, cheek: 0xB5555C, mask: 0x92A8C8, back: 0x6E4A2A, belly: 0x4A3624, breast: 0x7A5832, wing: 0x6A4828,
                         flight: 0x4A3E36, wingEdge: 0xE4DCCC, tail: 0x8A6238, tailEdge: 0xD2B07A, beak: 0x7F715E, leg: 0xB98577,
                         eye: 0x3A220F, eyeRing: 0xB5555C, breastExtent: 0.62, flankLine: 0.52, spotting: 0.12, crownLine: 0.5,
                         throatExtent: 0, maskExtent: 0, barring: 0.9, fringe: 0.55, featherRows: 20, ornament: 0xC4303A, beard: 0x17120E),
        behavior: BirdBehavior(cruise: 14, wingbeatHz: 5, hovers: false, boldness: 0.05, skittishRadius: 30, groundForaging: 1, perchHeight: 0.6,
                               voiceRate: 0.08, rarity: 0.5, seasons: hAll, activity: hDay,
                               likes: [.openGround: 1, .tree: 0.8, .seedPlants: 0.6], minHabitat: 0.4, visitsYards: false),
        voice: .turkey)

    static let pheasant = BirdProfile(
        species: .ringneckPheasant, name: "Ringneck Pheasant", latin: "Phasianus colchicus",
        blurb: "Copper cock with a green head, red face, white neck ring and a long barred tail. Runs first and flushes late.",
        anatomy: BirdAnatomy(length: 0.84, wingspan: 0.78, bodyLength: 0.28, bodyDepth: 0.16, bodyWidth: 0.13, restPitch: 15,
                             neckLength: 0.1, neckPitch: 52, headLength: 0.054, headWidth: 0.032, headHeight: 0.036,
                             beakLength: 0.021, beakDepth: 0.012, beakWidth: 0.0105, beakCurve: 0.003, tailLength: 0.5, tailWidth: 0.1,
                             tailFork: -0.3, tailFeathers: 16, tarsus: 0.075, toeLength: 0.052, crestHeight: 0, crestLength: 0,
                             eyeRadius: 0.0048, wingChord: 0.17, primaries: 10, bounds: false,
                             tibia: 0.05, collar: 0.013, facePatch: 0.02),
        plumage: Plumage(crown: 0x2A5A44, cheek: 0x1F4C3C, mask: 0x1F4C3C, back: 0xA9692E, belly: 0x33291F, breast: 0x9B3C1B, wing: 0x8E7656,
                         flight: 0x6D5C47, wingEdge: 0xCBB88C, tail: 0x8C6D3C, tailEdge: 0xB38C54, beak: 0xCBC4AA, leg: 0x9C8C74,
                         eye: 0xD8A92E, eyeRing: 0xB3281F, breastExtent: 0.62, flankLine: 0.5, spotting: 0.35, crownLine: 0.5,
                         throatExtent: 0, maskExtent: 0, barring: 0.85, fringe: 0.3, featherRows: 26, ornament: 0xB3281F, collar: 0xF2F0E8),
        behavior: BirdBehavior(cruise: 16, wingbeatHz: 9, hovers: false, boldness: 0.05, skittishRadius: 22, groundForaging: 1, perchHeight: 0.15,
                               voiceRate: 0.06, rarity: 0.45, seasons: hAll, activity: hDay,
                               likes: [.openGround: 1, .seedPlants: 1, .shrub: 0.7], minHabitat: 0.35, visitsYards: false),
        voice: .pheasant)
}

public extension BirdVoice {
    /// Gobble: a falling run of rattling, low notes, plus the yelp and putt calls.
    static let turkey = BirdVoice(
        songs: [[.arc(520, 780, 600, 0.14, gap: 0.03, amp: 0.9, harmonics: [1, 0.7, 0.5, 0.3], tremolo: V2(0.6, 28), noise: 0.2),
                 .arc(560, 820, 580, 0.12, gap: 0.03, amp: 0.9, harmonics: [1, 0.7, 0.5, 0.3], tremolo: V2(0.6, 30), noise: 0.2),
                 .arc(540, 800, 560, 0.12, gap: 0.03, amp: 0.9, harmonics: [1, 0.7, 0.5, 0.3], tremolo: V2(0.6, 30), noise: 0.2),
                 .arc(520, 760, 520, 0.12, gap: 0.03, amp: 0.85, harmonics: [1, 0.7, 0.5, 0.3], tremolo: V2(0.6, 28), noise: 0.2),
                 .arc(500, 720, 480, 0.13, gap: 0.03, amp: 0.8, harmonics: [1, 0.7, 0.5, 0.3], tremolo: V2(0.6, 26), noise: 0.2),
                 .slide(560, 400, 0.22, gap: 0.1, amp: 0.7, harmonics: [1, 0.6, 0.4], tremolo: V2(0.5, 24), noise: 0.2)]],
        calls: [[.arc(900, 1500, 1050, 0.2, gap: 0.12, amp: 0.8, harmonics: [1, 0.5, 0.3], noise: 0.1),
                 .arc(900, 1500, 1050, 0.2, gap: 0.12, amp: 0.8, harmonics: [1, 0.5, 0.3], noise: 0.1),
                 .arc(850, 1400, 1000, 0.22, gap: 0.12, amp: 0.8, harmonics: [1, 0.5, 0.3], noise: 0.1)],
                [.hold(700, 0.05, gap: 0.3, amp: 0.9, harmonics: [1, 0.6, 0.4], noise: 0.5)]],
        loudness: 0.95)

    /// Cock crow: two harsh notes, then a wing whirr in the next call.
    static let pheasant = BirdVoice(
        songs: [[.arc(1300, 1900, 1500, 0.2, gap: 0.08, amp: 0.9, harmonics: [1, 0.6, 0.4], noise: 0.3),
                 .hold(1700, 0.09, gap: 0.5, amp: 0.8, harmonics: [1, 0.6, 0.4], noise: 0.35)]],
        calls: [[.hold(1900, 0.05, gap: 0.05, amp: 0.8, harmonics: [1, 0.5, 0.3], noise: 0.5), .hold(1900, 0.05, gap: 0.05, amp: 0.8, harmonics: [1, 0.5, 0.3], noise: 0.5),
                 .hold(1800, 0.05, gap: 0.05, amp: 0.8, harmonics: [1, 0.5, 0.3], noise: 0.5)]],
        loudness: 0.85)
}
