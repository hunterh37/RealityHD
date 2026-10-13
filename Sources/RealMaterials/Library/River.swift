import RealCore

public extension MaterialLibrary {
    /// Mulberry River (Ozark National Forest, Arkansas): river water, Ozark rock, riparian trees, jon boat.
    static let river: [MaterialSpec] = [
        /// Clear jade-green Ozark river water. Transparent ShaderGraph path: two flow-scrolled ripple
        /// normals, Fresnel opacity, `Surface.splat` = shallowness (1 at the bank, 0 over the pools) tints
        /// shallow water toward pale green and lets the cobble bed show through.
        MaterialSpec(key: "water.mulberry", program: .water).with {
            $0.colorA = linear(0x143C30); $0.colorB = linear(0x7EAE88); $0.knobs = V4(0.5, 0, 0, 0); $0.seed = 41
            $0.tileSize = 2.2; $0.resolution = 1024; $0.normalStrength = 1.4; $0.mode = .transparent; $0.opacity = 0.42
            $0.roughness = 0.035; $0.specular = 0.5; $0.flow = 0.22; $0.hasAOMap = false
        },
        /// Riffle water: faster ripple scroll and more chop over shallow cobble.
        MaterialSpec(key: "water.mulberry-riffle", program: .water).with {
            $0.colorA = linear(0x2A4C40); $0.colorB = linear(0x9CBBA2); $0.knobs = V4(0.95, 0, 0, 0); $0.seed = 43
            $0.tileSize = 0.9; $0.resolution = 1024; $0.normalStrength = 2.4; $0.mode = .transparent; $0.opacity = 0.34
            $0.roughness = 0.05; $0.specular = 0.5; $0.flow = 0.6; $0.hasAOMap = false
        },
        /// Wet streambed cobble: rounded sandstone and chert, tan to blue grey, dark and glossy, 4-25 cm.
        MaterialSpec(key: "rock.cobble-wet", program: .rockRiver).with {
            $0.colorA = linear(0x6E6656); $0.colorB = linear(0x857A62); $0.colorC = linear(0xB9B0A0)
            $0.knobs = V4(0.85, 0.5, 0, 0); $0.seed = 45; $0.tileSize = 0.45; $0.normalStrength = 1.3; $0.triplanar = true
            $0.specular = 0.6
        },
        /// Dry bar cobble: sun-bleached, pale grey tan.
        MaterialSpec(key: "rock.cobble-dry", program: .rockRiver).with {
            $0.colorA = linear(0x9B9584); $0.colorB = linear(0xB1A78E); $0.colorC = linear(0xD2CBBB)
            $0.knobs = V4(0, 0.5, 0, 0); $0.seed = 47; $0.tileSize = 0.45; $0.normalStrength = 1.3; $0.triplanar = true
        },
        /// Ozark bluff limestone: grey bedded Boone/Pitkin limestone with dark water streaks and moss on ledges.
        MaterialSpec(key: "rock.ozark-limestone", program: .strataRock).with {
            $0.colorA = linear(0x66635C); $0.colorB = linear(0x837F75); $0.colorC = linear(0x4A4844)
            $0.knobs = V4(0.45, 9, 0.45, 0.5); $0.seed = 49; $0.tileSize = 3.0; $0.normalStrength = 2.6; $0.triplanar = true
            $0.topColor = linear(0x4E5A2E); $0.topAmount = 0.45; $0.topLow = 0.6
        },
        /// Atoka sandstone of the Boston Mountains: buff to rusty brown, thin bedded, lichen grey.
        MaterialSpec(key: "rock.ozark-sandstone", program: .strataRock).with {
            $0.colorA = linear(0x8A7458); $0.colorB = linear(0xA48E6E); $0.colorC = linear(0x6E6A62)
            $0.knobs = V4(0.5, 12, 0.4, 0.55); $0.seed = 51; $0.tileSize = 1.8; $0.normalStrength = 2.4; $0.triplanar = true
            $0.topColor = linear(0x56603A); $0.topAmount = 0.35; $0.topLow = 0.65
        },
        /// American sycamore bark: brown outer plates flaking off cream and olive-grey inner bark.
        MaterialSpec(key: "bark.sycamore", program: .barkSycamore).with {
            $0.colorA = linear(0x6B5A48); $0.colorB = linear(0xE2DDC8); $0.colorC = linear(0x9AA088)
            $0.knobs = V4(0.6, 0.6, 0, 0); $0.seed = 53; $0.tileSize = 0.7; $0.normalStrength = 2.4; $0.roughness = 0.75
            $0.wind = 0.03
        },
        /// Lower sycamore trunk: mostly intact brown scaly outer bark.
        MaterialSpec(key: "bark.sycamore-lower", program: .barkSycamore).with {
            $0.colorA = linear(0x5E5042); $0.colorB = linear(0xCFC8B0); $0.colorC = linear(0x8C907C)
            $0.knobs = V4(0.25, 0.8, 0, 0); $0.seed = 55; $0.tileSize = 0.6; $0.normalStrength = 3; $0.roughness = 0.85
            $0.wind = 0.02
        },
        /// River birch bark: salmon to cinnamon papery curls over darker inner bark.
        MaterialSpec(key: "bark.river-birch", program: .barkBirch).with {
            $0.colorA = linear(0xB08A72); $0.colorB = linear(0x3A2820); $0.colorC = linear(0xD8B89C)
            $0.seed = 57; $0.tileSize = 0.5; $0.normalStrength = 3.2; $0.roughness = 0.7
            $0.wind = 0.04
        },
        /// Shortleaf pine bark: reddish brown plates with dark fissures and resin pockets.
        MaterialSpec(key: "bark.shortleaf-pine", program: .barkPine).with {
            $0.colorA = linear(0x6E4A34); $0.colorB = linear(0x1E1510); $0.colorC = linear(0x8A7A6C)
            $0.seed = 59; $0.tileSize = 0.5; $0.normalStrength = 5; $0.roughness = 0.9
            $0.wind = 0.02
        },
        /// Sycamore leaves: large shallow-lobed leaves, 12-20 cm, mid green with a pale underside.
        MaterialSpec(key: "leaf.sycamore", program: .leafPalmate).with {
            $0.colorA = linear(0x3E5E1E); $0.colorB = linear(0x6E8F34); $0.colorC = linear(0xB89A3A)
            $0.knobs = V4(0.22, 0.04, 2, 5); $0.seed = 61; $0.tileSize = 0; $0.mode = .cutout; $0.twoSided = true; $0.normalStrength = 2
            $0.roughness = 0.55; $0.specular = 0.4
            $0.wind = 0.06; $0.translucency = 0.55
        },
        /// River birch leaves: small doubly toothed diamond leaves, glossy dark green.
        MaterialSpec(key: "leaf.river-birch", program: .leafBroad).with {
            $0.colorA = linear(0x3A5A1C); $0.colorB = linear(0x5F7E2A); $0.colorC = linear(0xB09A3A)
            $0.knobs = V4(0, 0.05, 2, 0); $0.seed = 63; $0.tileSize = 0; $0.mode = .cutout; $0.twoSided = true; $0.normalStrength = 1.5
            $0.wind = 0.07; $0.translucency = 0.5
        },
        /// Shortleaf pine needles: 7-11 cm, bundles of two or three, dark yellow green.
        MaterialSpec(key: "leaf.shortleaf-pine", program: .leafPine).with {
            $0.colorA = linear(0x2C3E22); $0.colorB = linear(0x445A30); $0.colorC = linear(0x7A8E58)
            $0.knobs = V4(0, 30, 2, 0); $0.seed = 65; $0.tileSize = 0; $0.mode = .cutout; $0.twoSided = true
            $0.normalStrength = 2; $0.roughness = 0.5
            $0.wind = 0.04; $0.translucency = 0.25
        },
        /// River cane leaves (Arundinaria gigantea): narrow lanceolate blades, 15-25 cm.
        MaterialSpec(key: "leaf.river-cane", program: .leafLanceolate).with {
            $0.colorA = linear(0x4A6424); $0.colorB = linear(0x8A9A5A); $0.colorC = linear(0xB8A452)
            $0.knobs = V4(6, 0.1, 2, 0); $0.seed = 67; $0.tileSize = 0; $0.mode = .cutout; $0.twoSided = true; $0.normalStrength = 1.4
            $0.roughness = 0.5; $0.specular = 0.4
            $0.wind = 0.1; $0.translucency = 0.5
        },
        /// Cane culm: olive green to straw, glossy, nodes every 15-25 cm.
        MaterialSpec(key: "plant.cane-culm", program: .plantStem).with {
            $0.colorA = linear(0x6E7A3C); $0.colorB = linear(0xA89A5E); $0.colorC = linear(0x4A5226)
            $0.seed = 69; $0.tileSize = 0.4; $0.normalStrength = 1; $0.roughness = 0.4; $0.specular = 0.5
            $0.wind = 0.08
        },
        /// Driftwood: sun-bleached silver grey wood with deep checks, no bark.
        MaterialSpec(key: "wood.driftwood", program: .woodPlank).with {
            $0.colorA = linear(0x938A7C); $0.colorB = linear(0x544C42); $0.knobs = V4(0.95, 0.9, 0, 0); $0.seed = 71
            $0.tileSize = 1.2; $0.normalStrength = 4; $0.roughness = 0.92
        },
        /// Weathered driftwood end grain.
        MaterialSpec(key: "wood.driftwood-end", program: .woodEndGrain).with {
            $0.colorA = linear(0x9A9080); $0.colorB = linear(0x5A5246); $0.seed = 73; $0.tileSize = 1.0; $0.normalStrength = 3; $0.roughness = 0.9
        },
        /// Bar gravel: rounded chert and sandstone pea gravel to small cobble, tan grey.
        MaterialSpec(key: "ground.river-gravel", program: .gravel).with {
            $0.colorA = linear(0x9C9482); $0.colorB = linear(0x6E6656); $0.colorC = linear(0xA89474)
            $0.knobs = V4(0.25, 2.0, 0.1, 0); $0.seed = 75; $0.tileSize = 1.4; $0.normalStrength = 3; $0.resolution = 2048
            $0.antiTile = true
        },
        /// Wet gravel at the waterline and on the riverbed.
        MaterialSpec(key: "ground.river-gravel-wet", program: .gravel).with {
            $0.colorA = linear(0x6A6252); $0.colorB = linear(0x48423A); $0.colorC = linear(0x7A6A52)
            $0.knobs = V4(0.35, 2.0, 0.1, 0); $0.seed = 77; $0.tileSize = 1.4; $0.normalStrength = 3; $0.resolution = 2048
            $0.antiTile = true; $0.roughness = 0.35; $0.specular = 0.6
        },
        /// Jon boat hull: marine aluminum sheet, mill finish with oxidation and scuffs.
        MaterialSpec(key: "metal.boat-aluminum", program: .brushedMetal).with {
            $0.colorA = linear(0xA6A8A4); $0.colorB = linear(0x77736A)
            $0.knobs = V4(0.6, 0.6, 0.55, 0.6); $0.seed = 79; $0.tileSize = 0.6; $0.normalStrength = 0.5
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.58
        },
        /// Jon boat exterior paint: flat olive drab marine enamel, chipped on the chines.
        MaterialSpec(key: "metal.boat-paint", program: .paintedMetal).with {
            $0.colorA = linear(0x4A5032); $0.colorC = linear(0x8A8A80, 0.0); $0.knobs = V4(0.55, 0.45, 0.6, 0); $0.seed = 81
            $0.tileSize = 0.9; $0.hasMetallicMap = true; $0.normalStrength = 1.5; $0.resolution = 1024
        },
        /// Ozark bank soil: oak-hickory leaf litter over brown loam, splat-blended to bar gravel near the water.
        MaterialSpec(key: "ground.ozark-bank", program: .forestFloor).with {
            $0.colorA = linear(0x3A2E20); $0.colorB = linear(0x6A5034); $0.colorC = linear(0x5E6A30)
            $0.knobs = V4(0.35, 0.75, 0, 0); $0.seed = 83; $0.tileSize = 2.0; $0.normalStrength = 4; $0.resolution = 2048
            $0.antiTile = true
            $0.splat = "ground.river-gravel"; $0.splatSoftness = 0.25; $0.splatHeight = 1.6
        },
        // realityhd:material.river
    ]
}
