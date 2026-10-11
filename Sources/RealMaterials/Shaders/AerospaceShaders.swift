// Aerospace programs: carbonWeave (2x2 twill carbon fiber), foilCrinkle (crinkled MLI foil).

let metalAerospace = #"""
// ---------------------------------------------------------------- aerospace
// 2x2 twill carbon fiber under clear resin. Warp tows run along U, weft along V; each tow is
// over two, under two, stepped one per row (diagonal twill lines).
// colorA dark fiber, colorB fiber sheen highlight, colorC resin-rich gap tint.
// f.x tows per tile (integer), f.y sheen contrast, f.z resin roughness, f.w tow gap width (tow fraction).
S carbonWeave(float2 uv, constant RFParams &P) {
    S s = defaults(); uint sd = P.seed;
    int n = max(4, int(P.f.x));
    float2 p = uv * float(n);
    int2 c = int2(floor(p)); float2 f = p - floor(p);
    int2 w = wrapc(c, int2(n, n));
    bool warp = ((w.x + w.y) & 3) < 2;
    // Across-tow coordinate: v for warp tows (fibers along U), u for weft.
    float across = warp ? f.y : f.x;
    float along = warp ? f.x : f.y;
    float gap = P.f.w;
    float edge = smoothstep(0.0, gap, across) * smoothstep(0.0, gap, 1.0 - across);
    float crown = sin(3.14159 * across);
    // Tow dips at its ends where it passes under the crossing tow.
    float dip = smoothstep(0.0, 0.18, along) * smoothstep(0.0, 0.18, 1.0 - along);
    float fib = warp ? gnoise(uv * float2(float(n), float(n * 60)), int2(n, n * 60), sd + 1u)
                     : gnoise(uv * float2(float(n * 60), float(n)), int2(n * 60, n), sd + 2u);
    float tone = h01(w, sd + 3u);
    // Sheen: warp and weft catch light differently (anisotropic look baked as two tones).
    float sheen = (warp ? 0.85 : 0.25) * P.f.y * crown * (0.75 + 0.25 * dip);
    float3 c3 = mix(P.colorA.rgb, P.colorB.rgb, sat(sheen + fib * 0.25 * P.f.y + (tone - 0.5) * 0.08));
    c3 = mix(P.colorC.rgb, c3, edge);
    s.albedo = c3;
    s.height = 0.5 + 0.18 * crown * dip * edge + fib * 0.01;
    s.rough = sat(P.f.z + (1.0 - edge) * 0.12 + abs(fib) * 0.05);
    s.ao = mix(0.6, 1.0, edge * (0.6 + 0.4 * dip));
    s.metal = 0.0; s.alpha = 1.0;
    return s;
}

// Crinkled multilayer insulation foil (gold-coated Kapton / aluminized): flat facets between sharp
// creases; each facet mirrors the sky at its own angle, so brightness jumps facet to facet.
// colorA bright foil, colorB dark reflection, colorC crease tint. f.x facets per tile, f.y crease depth,
// f.z base roughness, f.w large wrinkle amount.
S foilCrinkle(float2 uv, constant RFParams &P) {
    S s = defaults(); uint sd = P.seed;
    int g = max(4, int(P.f.x));
    float2 wv = float2(fbm(uv, int2(3, 3), 3, sd + 1u), fbm(uv, int2(3, 3), 3, sd + 2u)) * 0.06 * P.f.w;
    float4 a = worley(fract(uv + wv), int2(g, g), sd + 3u, 1.0);
    float4 b = worley(fract(uv + wv * 1.7), int2(g * 2 + 1, g * 2 + 1), sd + 4u, 1.0);
    float creaseA = 1.0 - smoothstep(0.0, 0.06, a.y - a.x);
    float creaseB = 1.0 - smoothstep(0.0, 0.05, b.y - b.x);
    float crease = max(creaseA, creaseB * 0.6);
    // Facet tilt -> reflected brightness, mixed from both crumple scales.
    float tilt = a.z * 0.65 + b.z * 0.35;
    float big = fbm(uv, int2(2, 2), 3, sd + 5u) * P.f.w;
    float refl = sat(pow(sat(tilt + big * 0.5), 1.4) * 1.25);
    float3 c = mix(P.colorB.rgb, P.colorA.rgb, refl);
    c = mix(c, P.colorC.rgb, crease * 0.55);
    s.albedo = c;
    // Height: tilted planes per facet (piecewise), sharp folds at creases.
    s.height = 0.5 + (a.z - 0.5) * 0.25 * (a.y - a.x) + (b.w - 0.5) * 0.1 - crease * 0.15 * P.f.y + big * 0.1;
    s.rough = sat(P.f.z + crease * 0.15 + (1.0 - a.w) * 0.04);
    s.ao = 1.0 - crease * 0.25;
    s.metal = 1.0; s.alpha = 1.0;
    return s;
}
"""#
