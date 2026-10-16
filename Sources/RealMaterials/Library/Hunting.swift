import RealCore

public extension MaterialLibrary {
    /// Hunting gear: walnut stocks, blued and parkerized steel, synthetic stocks, recoil pad, brass case,
    /// shotshell hull, carbon arrow shaft, bowstring, fletching.
    static let hunting: [MaterialSpec] = [
        // Oiled walnut gunstock: fine figure along the stock (grain along U), satin finish, 0.3 m repeat.
        MaterialSpec(key: "wood.walnut-stock", program: .woodPlank).with {
            $0.colorA = linear(0x6A4128); $0.colorB = linear(0x25140C); $0.knobs = V4(0, 0.38, 0, 0); $0.seed = 3301
            $0.tileSize = 0.3; $0.normalStrength = 0.9; $0.clearcoat = 0.55
        },
        // Hot-blued barrel and receiver steel: blue-black, polished lines.
        MaterialSpec(key: "metal.blued-steel", program: .brushedMetal).with {
            $0.colorA = linear(0x1C222B); $0.colorB = linear(0x0F1318)
            $0.knobs = V4(0.3, 0.2, 0.1, 0.06); $0.seed = 3302; $0.tileSize = 0.12; $0.normalStrength = 0.2
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.28
        },
        // Parkerized / matte phosphate finish for bolts and small parts: grey-green, rough.
        MaterialSpec(key: "metal.parkerized", program: .brushedMetal).with {
            $0.colorA = linear(0x4A4E4A); $0.colorB = linear(0x2E312E)
            $0.knobs = V4(0.9, 0.5, 0.3, 0.3); $0.seed = 3303; $0.tileSize = 0.05; $0.normalStrength = 0.4
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.62
        },
        // Bright steel: bolt body, polished lever and trigger.
        MaterialSpec(key: "metal.bolt-bright", program: .brushedMetal).with {
            $0.colorA = linear(0xB8BCC0); $0.colorB = linear(0x8A8E92)
            $0.knobs = V4(0.15, 0.2, 0.05, 0.05); $0.seed = 3304; $0.tileSize = 0.1; $0.normalStrength = 0.15
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.2
        },
        // Cartridge brass case.
        MaterialSpec(key: "metal.cartridge-brass", program: .polishedMetal).with {
            $0.colorA = linear(0xC49A3A); $0.colorB = linear(0x8F6C22)
            $0.knobs = V4(0.2, 0.1, 0, 0); $0.seed = 3305; $0.tileSize = 0.03; $0.normalStrength = 0.1
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.24
        },
        // Copper-jacketed bullet.
        MaterialSpec(key: "metal.bullet-copper", program: .polishedMetal).with {
            $0.colorA = linear(0xA0603A); $0.colorB = linear(0x6E3E24)
            $0.knobs = V4(0.2, 0.1, 0, 0); $0.seed = 3306; $0.tileSize = 0.03; $0.normalStrength = 0.1
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.3
        },
        // Black glass-filled nylon stock and grip caps. Tint for camo or OD.
        MaterialSpec(key: "plastic.stock-synthetic", program: .plastic).with {
            $0.colorA = linear(0x1A1B1C); $0.knobs = V4(0.35, 0.1, 0.6, 0); $0.seed = 3307; $0.tileSize = 0.04; $0.normalStrength = 0.8
        },
        // Vulcanized rubber recoil pad with fine pebble texture.
        MaterialSpec(key: "rubber.recoil-pad", program: .leather).with {
            $0.colorA = linear(0x151515); $0.colorB = linear(0x0C0C0C); $0.colorC = linear(0x262626)
            $0.knobs = V4(48, 0.2, 0.85, 0); $0.seed = 3308; $0.tileSize = 0.03; $0.normalStrength = 1.0; $0.roughness = 0.85
        },
        // 12 gauge hull: glossy polyethylene tube. Tint for colour.
        MaterialSpec(key: "plastic.shotshell", program: .plastic).with {
            $0.colorA = linear(0xB02820); $0.knobs = V4(0.1, 0.05, 0.22, 0); $0.seed = 3309; $0.tileSize = 0.04; $0.normalStrength = 0.2; $0.clearcoat = 0.6
        },
        // Carbon arrow shaft: woven carbon under gloss, graphite grey. Tint for colour.
        MaterialSpec(key: "plastic.carbon-shaft", program: .plastic).with {
            $0.colorA = linear(0x242628); $0.knobs = V4(0.05, 0.02, 0.2, 0); $0.seed = 3310; $0.tileSize = 0.02; $0.resolution = 512; $0.normalStrength = 0.5; $0.clearcoat = 1
        },
        // Bowstring and cable serving: waxed synthetic fibre.
        MaterialSpec(key: "fabric.bowstring", program: .fabricWeave).with {
            $0.colorA = linear(0x1E1E1C); $0.knobs = V4(0.5, 0.2, 0, 0); $0.seed = 3311; $0.tileSize = 0.01; $0.resolution = 256; $0.normalStrength = 0.8; $0.roughness = 0.7
        },
        // Vane fletching: translucent coloured plastic. Tint for colour.
        MaterialSpec(key: "plastic.fletching", program: .plastic).with {
            $0.colorA = linear(0xE0561A); $0.knobs = V4(0.05, 0.02, 0.3, 0); $0.seed = 3312; $0.tileSize = 0.03; $0.resolution = 256; $0.normalStrength = 0.15
        },
        // Camouflage-dipped bow limb / riser: dark brown and olive breakup.
        MaterialSpec(key: "paint.bow-camo", program: .paintedMetal).with {
            $0.colorA = linear(0x4A4A2A); $0.colorB = linear(0x2A2A1A); $0.colorC = linear(0x2C2418)
            $0.knobs = V4(0.5, 0.2, 0.55, 0); $0.seed = 3313; $0.tileSize = 0.12; $0.normalStrength = 0.4
            $0.hasMetallicMap = true; $0.metallic = 0.1; $0.roughness = 0.5
        },
    ]
}
