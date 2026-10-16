import RealCore

public extension MaterialLibrary {
    /// Hunting gear: walnut stocks, blued and parkerized steel, synthetic stocks, recoil pad, brass case,
    /// shotshell hull, carbon arrow shaft, bowstring, fletching.
    static let hunting: [MaterialSpec] = [
        // Oiled walnut gunstock: fine figure along the stock (grain along U), satin finish, 0.3 m repeat.
        MaterialSpec(key: "wood.walnut-stock", program: .woodPlank).with {
            $0.colorA = linear(0x5A3722); $0.colorB = linear(0x0E0603); $0.knobs = V4(0.0, 0.6, 0, 0); $0.seed = 3301
            $0.tileSize = 0.45; $0.normalStrength = 0.6; $0.clearcoat = 0.12
        },
        // Hot-blued barrel and receiver steel: blue-black, polished lines.
        MaterialSpec(key: "metal.blued-steel", program: .brushedMetal).with {
            $0.colorA = linear(0x2B3542); $0.colorB = linear(0x161C25)
            $0.knobs = V4(0.5, 0.34, 0.45, 0.35); $0.seed = 3302; $0.tileSize = 0.08; $0.normalStrength = 0.35
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.34
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
            $0.knobs = V4(0.4, 0.26, 0.35, 0.3); $0.seed = 3304; $0.tileSize = 0.06; $0.normalStrength = 0.3
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.2
        },
        // Cartridge brass case.
        MaterialSpec(key: "metal.cartridge-brass", program: .polishedMetal).with {
            $0.colorA = linear(0xC49A3A); $0.colorB = linear(0x8F6C22)
            $0.knobs = V4(0.45, 0, 0, 0.3); $0.seed = 3305; $0.tileSize = 0.03; $0.normalStrength = 0.1
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.3
        },
        // Copper-jacketed bullet.
        MaterialSpec(key: "metal.bullet-copper", program: .polishedMetal).with {
            $0.colorA = linear(0xA0603A); $0.colorB = linear(0x6E3E24)
            $0.knobs = V4(0.4, 0, 0, 0.3); $0.seed = 3306; $0.tileSize = 0.03; $0.normalStrength = 0.1
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.34
        },
        // Black glass-filled nylon stock and grip caps. Tint for camo or OD.
        MaterialSpec(key: "plastic.stock-synthetic", program: .plastic).with {
            $0.colorA = linear(0x1A1B1C); $0.knobs = V4(0.9, 0.55, 0.7, 0); $0.seed = 3307; $0.tileSize = 0.05; $0.normalStrength = 1.4
        },
        // Vulcanized rubber recoil pad with fine pebble texture.
        MaterialSpec(key: "rubber.recoil-pad", program: .leather).with {
            $0.colorA = linear(0x151515); $0.colorB = linear(0x0C0C0C); $0.colorC = linear(0x262626)
            $0.knobs = V4(48, 0.2, 0.85, 0); $0.seed = 3308; $0.tileSize = 0.03; $0.normalStrength = 1.0; $0.roughness = 0.85
        },
        // 12 gauge hull: glossy polyethylene tube. Tint for colour.
        MaterialSpec(key: "plastic.shotshell", program: .plastic).with {
            $0.colorA = linear(0x9C281E); $0.knobs = V4(0.8, 0.4, 0.4, 0); $0.seed = 3309; $0.tileSize = 0.02; $0.resolution = 512; $0.normalStrength = 0.5; $0.clearcoat = 0.2
        },
        // Carbon arrow shaft: woven carbon under gloss, graphite grey. Tint for colour.
        MaterialSpec(key: "plastic.carbon-shaft", program: .carbonWeave).with {
            $0.colorA = linear(0x1B1C1E); $0.colorB = linear(0x4A4D52); $0.colorC = linear(0x0B0B0C)
            $0.knobs = V4(16, 0.7, 0.26, 0.1); $0.seed = 3310; $0.tileSize = 0.018; $0.resolution = 512; $0.normalStrength = 1.0; $0.roughness = 0.26; $0.clearcoat = 0.7
        },
        // Bowstring and cable serving: waxed synthetic fibre.
        MaterialSpec(key: "fabric.bowstring", program: .fabricWeave).with {
            $0.colorA = linear(0x1E1E1C); $0.knobs = V4(0.5, 0.2, 0, 0); $0.seed = 3311; $0.tileSize = 0.01; $0.resolution = 256; $0.normalStrength = 0.8; $0.roughness = 0.7
        },
        // Vane fletching: translucent coloured plastic. Tint for colour.
        MaterialSpec(key: "plastic.fletching", program: .plastic).with {
            $0.colorA = linear(0xE0561A); $0.knobs = V4(0.5, 0.4, 0.5, 0); $0.seed = 3312; $0.tileSize = 0.03; $0.resolution = 256; $0.normalStrength = 0.15
        },
        // Camouflage-dipped bow limb / riser: dark brown and olive breakup.
        MaterialSpec(key: "paint.bow-camo", program: .forestFloor).with {
            $0.colorA = linear(0x2A2A1A); $0.colorB = linear(0x7A6A3E); $0.colorC = linear(0x4A5428)
            $0.knobs = V4(0.55, 0.7, 0, 0); $0.seed = 3313; $0.tileSize = 0.16; $0.resolution = 1024; $0.normalStrength = 0.5; $0.roughness = 0.5
        },
        // Trail camera housing: scuffed, dirty textured polymer at 3 cm repeat. Tint for colour.
        MaterialSpec(key: "plastic.trailcam", program: .plastic).with {
            $0.colorA = linear(0x59613F); $0.knobs = V4(0.9, 0.8, 0.78, 0); $0.seed = 3314; $0.tileSize = 0.03; $0.resolution = 512; $0.normalStrength = 1.5
        },
        // Powder-coated steel with chips, scuffs and grime at 22 cm repeat (ladder stand, hardware). Tint for colour.
        MaterialSpec(key: "metal.powdercoat-worn", program: .paintedMetal).with {
            $0.colorA = linear(0x3A4430); $0.colorC = linear(0x7A7A74, 0.9); $0.knobs = V4(0.85, 0.75, 0.5, 0)
            $0.seed = 3315; $0.tileSize = 0.16; $0.hasMetallicMap = true; $0.normalStrength = 1.2; $0.roughness = 0.5
        },
        // Mud and surface rust splashed on steel feet: dark and desaturated.
        MaterialSpec(key: "metal.rust-grime", program: .rustMetal).with {
            $0.colorA = linear(0x5A3A28); $0.colorB = linear(0x2E2018); $0.knobs = V4(0.12, 0, 0, 0)
            $0.seed = 3316; $0.tileSize = 0.14; $0.hasMetallicMap = true; $0.normalStrength = 1.3; $0.roughness = 0.85
        },
        // Hunting blind canvas: heavy duck weave at 3 cm repeat with stains. Tint for colour.
        MaterialSpec(key: "fabric.blind", program: .fabricWeave).with {
            $0.colorA = linear(0x6E7549); $0.colorB = linear(0x5A6040, 0.25); $0.colorC = linear(0x3A3226, 0.45)
            $0.knobs = V4(36, 0.5, 0.9, 0); $0.seed = 3317; $0.tileSize = 0.03; $0.normalStrength = 3.4; $0.roughness = 0.9
        },
        // Pressed trace-mineral salt block: red-brown crystalline body, pale crystals, pits, light rain streaks.
        MaterialSpec(key: "stone.salt-block", program: .rockGranite).with {
            $0.colorA = linear(0x8A4E3A); $0.colorB = linear(0xB07A60); $0.colorC = linear(0xD8C4B4)
            $0.knobs = V4(0, 0.7, 0.35, 0.55); $0.seed = 3318; $0.tileSize = 0.3; $0.normalStrength = 1.6; $0.roughness = 0.82
            $0.triplanar = true
        },
        // Dried mud and grime caked on gear: dark brown, rough, with dirt streaks.
        MaterialSpec(key: "plastic.grime", program: .plastic).with {
            $0.colorA = linear(0x4A3A2A); $0.knobs = V4(0.2, 0.9, 0.95, 0); $0.seed = 3319; $0.tileSize = 0.02; $0.resolution = 256; $0.normalStrength = 1.4
        },
    ]
}
