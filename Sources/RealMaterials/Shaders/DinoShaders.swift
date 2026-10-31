// Dinosaur skin: dinoScale. Atlas program (tileSize 0) on the `Loft` layout:
// u wraps the body (0 dorsal midline, 0.5 ventral, mirrored), v runs along the part.
// knobs: x scale rows along v, y countershade boundary (0 dorsal .. 1 ventral), z dorsal scute strength,
// w stripe strength (colorC). colorA dorsal, colorB ventral, colorC stripes and scutes; colorC.a scales
// the cell count around u relative to x.

let metalDino = #"""
// ---------------------------------------------------------------- dino
S dinoScale(float2 uv, constant RFParams &P) {
    uint sd = P.seed;
    float t = 2.0 * min(uv.x, 1.0 - uv.x);
    float v = uv.y;
    float R = max(P.f.x, 4.0);
    int ru = max(4, int(round(R * max(P.colorC.a, 0.05))));
    int rv = max(4, int(round(R)));
    // Pebbly tubercles: a fine Worley field with a coarser feature-scale field mixed in.
    float4 w = worley(uv, int2(ru, rv), sd + 3u, 0.85);
    float4 w2 = worley(uv, int2(max(2, ru / 3), max(2, rv / 3)), sd + 11u, 0.9);
    float edge = w.y - w.x;
    float pebble = smoothstep(0.0, 0.32, edge);
    float big = smoothstep(0.0, 0.22, w2.y - w2.x) * step(0.72, w2.z);
    float n = fbm(uv, int2(4, 8), 4, sd + 5u);
    float n2 = fbm(uv, int2(12, 24), 3, sd + 17u);
    // Countershading: dark back, pale belly, soft mottled boundary.
    float under = smoothstep(P.f.y - 0.16, P.f.y + 0.16, t + (n - 0.5) * 0.18);
    float3 c = mix(P.colorA.rgb, P.colorB.rgb, under);
    // Broken stripes across the back and flanks.
    float stripe = 0.5 + 0.5 * cos((v * R * 0.11 + n * 1.6 + t * 0.8) * 6.2831853);
    float sm = smoothstep(0.62, 0.9, stripe) * (1.0 - smoothstep(0.35, 0.6, t)) * P.f.w;
    c = mix(c, P.colorC.rgb, sm);
    // Dorsal scute row: two staggered lines of large keeled osteoderm-like scales along the midline.
    float sc = 0.0;
    if (P.f.z > 0.001) {
        float lane = 1.0 - smoothstep(0.035, 0.07, fabs(t - 0.045));
        float k = fract(v * R * 0.33 + step(0.045, t) * 0.5);
        float keel = 1.0 - smoothstep(0.18, 0.42, fabs(k - 0.5));
        sc = lane * keel * P.f.z;
        c = mix(c, P.colorC.rgb * 0.8 + P.colorA.rgb * 0.2, sc * 0.6);
    }
    // Per-scale tone, darker crevices, warm wear in the folds.
    c *= 0.82 + 0.26 * w.z + 0.12 * (n2 - 0.5);
    c *= mix(0.62, 1.0, pebble);
    c = mix(c, c * float3(1.06, 0.98, 0.9), big * 0.4);
    S s = defaults();
    s.albedo = saturate(c);
    s.height = 0.25 + 0.45 * pebble * (0.75 + 0.25 * w.z) + 0.15 * big + 0.3 * sc;
    s.ao = 0.55 + 0.45 * pebble;
    s.rough = clamp(0.62 + 0.18 * (1.0 - pebble) + 0.1 * n2 - 0.1 * under, 0.35, 0.95);
    return s;
}
"""#
