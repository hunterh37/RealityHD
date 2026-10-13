import RealCore

public extension MaterialLibrary {
    /// Freshwater fish (Ozark stream pack). Skin atlases: u wraps the body (0 dorsal, 0.5 ventral), v 0 tail to 1 snout.
    /// Skin knobs: scale rows head to tail (0 = scaleless), dorsal/ventral boundary, pattern id, pattern strength.
    /// Patterns: 0 plain silver, 1 vertical bars, 2 lateral band, 3 blotch row + spot rows, 4 scale freckles,
    /// 5 sunfish cheek lines + speckle (colorC), 6 small spots, 7 marbled mottling.
    /// Fin knobs: ray count, unused, margin width (colorC), rear-base blotch strength. Eye knobs: pupil radius.
    static let fish: [MaterialSpec] = {
        func skin(_ k: String, _ a: UInt32, _ b: UInt32, _ c: UInt32, rows: Float, bnd: Float, pat: Float, str: Float, op: Float = 0.27, seed: UInt32) -> MaterialSpec {
            MaterialSpec(key: "fish.\(k)", program: .fishSkin).with {
                $0.colorA = linear(a, 1 - 0.95 * op + 0.0); $0.colorB = linear(b); $0.colorC = linear(c)
                $0.knobs = V4(rows, bnd, pat, str); $0.seed = seed; $0.tileSize = 0; $0.resolution = 1024
                $0.normalStrength = rows > 0 ? 0.9 : 0.6; $0.roughness = 0.3; $0.clearcoat = 0.6
            }
        }
        func fin(_ k: String, _ a: UInt32, _ b: UInt32, _ c: UInt32, rays: Float, margin: Float, blotch: Float = 0, seed: UInt32) -> MaterialSpec {
            MaterialSpec(key: "fish.\(k)", program: .fishFin).with {
                $0.colorA = linear(a); $0.colorB = linear(b); $0.colorC = linear(c)
                $0.knobs = V4(rays, 0, margin, blotch); $0.seed = seed; $0.tileSize = 0; $0.resolution = 512
                $0.normalStrength = 1.2; $0.roughness = 0.4; $0.twoSided = true
            }
        }
        func eye(_ k: String, _ iris: UInt32, pupil: Float, seed: UInt32) -> MaterialSpec {
            MaterialSpec(key: "fish.\(k)", program: .fishEye).with {
                $0.colorA = linear(iris); $0.colorB = linear(0x050505); $0.colorC = linear(0x2A2418)
                $0.knobs = V4(pupil, 0, 0, 0); $0.seed = seed; $0.tileSize = 0; $0.resolution = 256
                $0.normalStrength = 0.5; $0.roughness = 0.05; $0.clearcoat = 1
            }
        }
        return [
            skin("smallmouth-skin", 0x5A4828, 0xC6B892, 0x2E2210, rows: 72, bnd: 0.6, pat: 1, str: 0.62, seed: 9101),
            skin("spotted-skin", 0x4E5634, 0xDCD8C4, 0x262412, rows: 64, bnd: 0.58, pat: 3, str: 0.85, seed: 9102),
            skin("largemouth-skin", 0x46523A, 0xE0DCC8, 0x1F2416, rows: 64, bnd: 0.6, pat: 2, str: 0.85, seed: 9103),
            skin("ozark-bass-skin", 0x7A6E3E, 0xC8BC80, 0x231A12, rows: 42, bnd: 0.62, pat: 4, str: 0.9, seed: 9104),
            skin("longear-skin", 0x4E3E22, 0xD8702A, 0x3A9EAE, rows: 40, bnd: 0.66, pat: 5, str: 0.9, op: 0.29, seed: 9105),
            skin("green-sunfish-skin", 0x56604A, 0xCDB050, 0x4A9AA8, rows: 46, bnd: 0.6, pat: 5, str: 0.8, op: 0.28, seed: 9106),
            skin("bluegill-skin", 0x5A5032, 0xC88E44, 0x2A2A22, rows: 42, bnd: 0.62, pat: 1, str: 0.55, op: 0.29, seed: 9107),
            skin("channel-cat-skin", 0x3E464E, 0xDCDCD6, 0x16181C, rows: 0, bnd: 0.7, pat: 6, str: 0.9, op: 0.21, seed: 9108),
            skin("flathead-skin", 0x6A6450, 0xD8D0B8, 0x3A3424, rows: 0, bnd: 0.62, pat: 7, str: 0.8, op: 0.2, seed: 9109),
            skin("drum-skin", 0x8A7C5C, 0xD8CEB0, 0x5A5444, rows: 52, bnd: 0.5, pat: 0, str: 0, op: 0.26, seed: 9110),
            fin("bass-fin", 0x3E3220, 0x5A4A30, 0x2A2014, rays: 14, margin: 0.06, seed: 9121),
            fin("largemouth-fin", 0x56603A, 0x7E8458, 0x3C4228, rays: 14, margin: 0, seed: 9122),
            fin("sunfish-fin", 0x6A5838, 0x8A7450, 0x2E2A22, rays: 12, margin: 0.05, seed: 9123),
            fin("longear-fin", 0x7A5A30, 0xB0703A, 0x3A9EAE, rays: 12, margin: 0.06, seed: 9124),
            fin("green-sunfish-fin", 0x4A5A44, 0x6A7A5E, 0xE0C060, rays: 12, margin: 0.08, blotch: 0.8, seed: 9125),
            fin("bluegill-fin", 0x4E5A50, 0x7A8274, 0x3A4048, rays: 12, margin: 0, blotch: 0.9, seed: 9126),
            fin("catfish-fin", 0x5A646C, 0x7A848C, 0x2A2E32, rays: 10, margin: 0.05, seed: 9127),
            fin("flathead-fin", 0x6A5430, 0x8A7444, 0xD8C890, rays: 10, margin: 0.06, seed: 9128),
            fin("drum-fin", 0x5E5A4E, 0x7A766A, 0x5A5C56, rays: 14, margin: 0, seed: 9129),
            // Sunfish opercular ear flap: black with a pale or coloured margin (colorC per species via fin tint).
            fin("ear-flap", 0x0E0E10, 0x16161A, 0x9AB8C0, rays: 4, margin: 0.06, seed: 9130),
            fin("ear-flap-longear", 0x0E0E10, 0x16161A, 0xE8E0C8, rays: 4, margin: 0.05, seed: 9131),
            fin("ear-flap-black", 0x0C0C0E, 0x121214, 0x1A1A1E, rays: 4, margin: 0, seed: 9133),
            fin("barbel", 0x3A3C3E, 0x4A4C4E, 0x2A2C2E, rays: 4, margin: 0, seed: 9132),
            eye("eye-red", 0xB4261A, pupil: 0.48, seed: 9141),
            eye("eye-amber", 0xA2701E, pupil: 0.5, seed: 9142),
            eye("eye-dark", 0x3A3020, pupil: 0.55, seed: 9143),
            eye("eye-silver", 0xC8C6B8, pupil: 0.5, seed: 9144),
            MaterialSpec(key: "fish.mouth", program: nil).with { $0.baseColor = V3(0.16, 0.10, 0.09); $0.roughness = 0.35 },
        ]
    }()
}
