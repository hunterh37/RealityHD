// Fish programs: fishSkin, fishFin, fishEye. Atlas programs (tileSize 0).
// fishSkin: u wraps the body (0 dorsal midline, 0.5 ventral, mirrored), v runs 0 (tail) to 1 (snout).
// Scales reuse the fauna overlapping-row lookup (`fa_rows`) with free edges pointing toward the tail.
// fishFin: u 0 fin base to 1 fin margin (along the rays), v 0..1 across the fin.
// fishEye: planar disc, centre (0.5, 0.5), radius 0.5.

let metalFish = #"""
// ---------------------------------------------------------------- fish
// Pattern mask for the species patterns. t: 0 dorsal .. 1 ventral, v: 0 tail .. 1 snout.
float fi_pattern(int pat, float t, float v, FaRes r, uint sd) {
    float n = fbm(float2(t * 0.5, v), int2(4, 12), 4, sd + 9u);
    float n2 = fbm(float2(t * 0.5, v), int2(8, 32), 3, sd + 19u);
    if (pat == 1) {
        // Smallmouth / bluegill: broken vertical bars on the flank, fading toward the belly.
        float bars = 0.5 + 0.5 * cos((v * 11.0 + n * 0.9) * 6.2831853);
        float band = (1.0 - smoothstep(0.42, 0.72, t + n * 0.2)) * smoothstep(0.0, 0.08, t);
        float head = 1.0 - smoothstep(0.72, 0.82, v);
        return smoothstep(0.45, 0.85, bars + n2 * 0.4) * band * head;
    }
    if (pat == 2) {
        // Largemouth: jagged dark lateral band of joined blotches, snout to tail.
        float y = t - 0.40 - 0.03 * sin(v * 40.0) - n * 0.12;
        float w = 0.085 + 0.04 * n2;
        float bandM = 1.0 - smoothstep(w * 0.6, w, fabs(y));
        float dorsalMottle = smoothstep(0.15, 0.4, n2 + 0.2) * (1.0 - smoothstep(0.1, 0.32, t)) * 0.35;
        return max(bandM * (1.0 - smoothstep(0.92, 0.98, v)), dorsalMottle);
    }
    if (pat == 3) {
        // Spotted bass: blotch row along the lateral line plus rows of dark scale spots below it.
        float blot = 0.5 + 0.5 * cos((v * 13.0 + n * 0.6) * 6.2831853);
        float y = fabs(t - 0.40 - n * 0.08);
        float row = (1.0 - smoothstep(0.05, 0.09, y)) * smoothstep(0.3, 0.7, blot + n2 * 0.4);
        float spots = 0.0;
        if (r.hit && t > 0.52 && t < 0.80) {
            float c = 1.0 - smoothstep(0.15, 0.32, length(float2(r.an, r.al - 0.55) * float2(1.0, 0.9)));
            spots = c * step(0.25, r.fid);
        }
        return max(row * (1.0 - smoothstep(0.9, 0.96, v)), spots * 0.9);
    }
    if (pat == 4) {
        // Ozark bass: a dark freckle on most flank scales.
        if (!r.hit) return 0.0;
        float c = 1.0 - smoothstep(0.12, 0.30, length(float2(r.an, r.al - 0.5)));
        return c * step(0.18, r.fid) * smoothstep(0.05, 0.2, t) * (1.0 - smoothstep(0.78, 0.9, t));
    }
    if (pat == 5) {
        // Sunfish: wavy cheek lines and speckles of the accent colour, faint flank bars.
        float lines = 0.5 + 0.5 * sin((t * 22.0 + v * 9.0 + n * 3.0) * 3.14159);
        float cheek = smoothstep(0.78, 0.86, v) * smoothstep(0.25, 0.4, t) * (1.0 - smoothstep(0.85, 0.95, t));
        float wav = smoothstep(0.82, 0.95, lines) * cheek;
        float speck = 0.0;
        if (r.hit) speck = (1.0 - smoothstep(0.1, 0.24, length(float2(r.an, r.al - 0.5)))) * step(0.55, r.fid)
                         * (1.0 - smoothstep(0.80, 0.86, v)) * smoothstep(0.1, 0.3, t) * (1.0 - smoothstep(0.7, 0.85, t));
        return max(wav, speck * 0.8) + 2.0;   // > 1 flags accent-colour marks
    }
    if (pat == 6) {
        // Channel catfish: small scattered dark spots on the upper flank.
        float4 w = worley(float2(t * 0.5, v), int2(24, 40), sd + 41u, 0.9);
        float spot = (1.0 - smoothstep(0.10, 0.20, w.x)) * step(0.45, w.z);
        return spot * (1.0 - smoothstep(0.45, 0.6, t)) * smoothstep(0.04, 0.12, t) * (1.0 - smoothstep(0.9, 0.97, v));
    }
    if (pat == 7) {
        // Flathead: irregular marbled mottling.
        float m = fbm(float2(t * 0.5, v), int2(6, 18), 5, sd + 51u);
        return smoothstep(0.02, 0.22, m) * (1.0 - smoothstep(0.5, 0.75, t));
    }
    return 0.0;
}

S fishSkin(float2 uv, constant RFParams &P) {
    uint sd = P.seed;
    float t = 2.0 * min(uv.x, 1.0 - uv.x);
    float v = uv.y;
    float R = P.f.x; int pat = int(P.f.z + 0.5); float strength = P.f.w;
    bool scaled = R > 1.0;
    FaRes r; r.hit = false; r.al = 0.5; r.an = 0; r.fid = 0.5; r.fid2 = 0.5; r.shadow = 1;
    if (scaled) r = fa_rows(t, v, R, max(4, int(round(R * 0.6))), sd, 0.62, 0.55);
    float n = fbm(float2(t * 0.5, v), int2(4, 10), 4, sd + 3u);
    float bnd = P.f.y;
    float under = smoothstep(bnd - 0.14, bnd + 0.14, t + n * 0.1);
    float3 c = mix(P.colorA.rgb, P.colorB.rgb, under);
    // Darker dorsal ridge, lighter cheek and throat.
    c *= 1.0 - 0.25 * (1.0 - smoothstep(0.0, 0.18, t));
    float pm = fi_pattern(pat, t, v, r, sd);
    if (pm >= 2.0) c = mix(c, P.colorC.rgb, saturate(pm - 2.0) * strength);
    else c = mix(c, P.colorC.rgb, pm * strength);
    // Lateral line: a faint pale dotted line following the upper flank.
    float ll = 1.0 - smoothstep(0.004, 0.012, fabs(t - 0.36 - 0.04 * (1.0 - v)));
    float dots = scaled ? smoothstep(0.2, 0.6, 1.0 - r.al) : 0.5 + 0.5 * sin(v * 420.0);
    c = mix(c, c * 1.35 + 0.03, ll * dots * smoothstep(0.08, 0.2, v) * (1.0 - smoothstep(0.82, 0.86, v)));
    // Gill cover: colorA.a holds the operculum edge v (head side is smooth skin with a dark rim line).
    float opV = P.colorA.a < 0.99 ? P.colorA.a : 0.74;
    float edgeV = opV + 0.035 * (t - 0.45) * (t - 0.45) * 4.0 - 0.01;
    float headZ = smoothstep(edgeV - 0.002, edgeV + 0.03, v);
    float rim = 1.0 - smoothstep(0.0, 0.008, fabs(v - edgeV));
    c *= 1.0 - 0.35 * rim * step(0.08, t) * (1.0 - step(0.9, t));
    if (scaled) c *= mix(1.0, 0.95, headZ);
    S s = defaults();
    if (scaled && r.hit && headZ < 0.98) {
        float tone = 0.9 + 0.2 * r.fid2;
        // Iridescent shift: scale edges lean blue-green, centres warm, per-scale variation.
        float edge = smoothstep(0.75, 1.0, fabs(r.an)) + (1.0 - smoothstep(0.0, 0.25, r.al));
        float3 iri = mix(float3(0.92, 1.0, 1.08), float3(1.06, 1.0, 0.9), r.fid);
        c = c * tone * iri * (1.0 - 0.22 * saturate(edge));
        c *= mix(1.0, 0.86, 1.0 - r.shadow);
        s.height = 0.35 + 0.30 * (1.0 - smoothstep(0.0, 1.0, r.al)) - 0.08 * (1.0 - r.shadow);
        s.ao = saturate(0.55 + 0.45 * r.shadow);
        s.rough = 0.26 + 0.12 * r.fid2 + 0.1 * saturate(edge);
        s.height = mix(s.height, 0.5, headZ);
    } else {
        // Scaleless skin: fine wrinkles and pores, wet sheen.
        float wr = fbm(float2(t * 0.5, v), int2(24, 80), 3, sd + 71u);
        c *= 0.94 + 0.12 * wr;
        s.height = 0.5 + 0.12 * wr; s.ao = 1.0; s.rough = 0.22 + 0.08 * wr;
    }
    // Guanine silvering on the lower flank (drum and bass bellies).
    s.metal = under * (pat == 0 ? 0.35 : 0.08);
    s.albedo = c;
    return s;
}

S fishFin(float2 uv, constant RFParams &P) {
    S s = defaults(); uint sd = P.seed;
    float rays = max(P.f.x, 4.0);
    float ray = 0.5 + 0.5 * cos(uv.y * rays * 6.2831853);
    float rayM = smoothstep(0.75, 0.95, ray);
    // Segments along each ray.
    float seg = smoothstep(0.85, 1.0, 0.5 + 0.5 * cos(uv.x * rays * 2.4 * 6.2831853));
    float n = fbm(uv, int2(6, 6), 3, sd + 5u);
    float3 c = mix(P.colorB.rgb, P.colorA.rgb, rayM * (1.0 - 0.3 * seg));
    c *= 0.88 + 0.24 * n;
    // Margin colour band and darker base.
    float margin = smoothstep(1.0 - P.f.z - 0.05, 1.0 - P.f.z + 0.02, uv.x + n * 0.04);
    c = mix(c, P.colorC.rgb, margin * step(0.001, P.f.z));
    c *= 0.8 + 0.2 * smoothstep(0.0, 0.25, uv.x);
    // Optional dark blotch at the rear base (bluegill dorsal spot): f.w strength.
    float bl = 1.0 - smoothstep(0.18, 0.3, length(float2(uv.x - 0.35, (uv.y - 0.15) * 0.8)));
    c = mix(c, P.colorA.rgb * 0.25, bl * P.f.w);
    s.albedo = c;
    s.height = 0.45 + 0.25 * rayM - 0.05 * seg;
    s.rough = 0.35 + 0.15 * (1.0 - rayM);
    s.ao = 0.85 + 0.15 * rayM;
    s.metal = 0.0;
    return s;
}

S fishEye(float2 uv, constant RFParams &P) {
    S s = defaults(); uint sd = P.seed;
    float2 d = uv - 0.5; float r = length(d) * 2.0;
    float pr = P.f.x;                                     // pupil radius (0..1 of disc)
    float ang = atan2(d.y, d.x);
    float fib = fbm(float2(ang / 6.2831853 + 0.5, r), int2(48, 3), 3, sd + 3u);
    float3 iris = P.colorA.rgb * (0.75 + 0.5 * fib) * mix(1.2, 0.7, r);
    float3 rim = P.colorC.rgb;
    float pupil = 1.0 - smoothstep(pr - 0.03, pr + 0.02, r);
    float ring = smoothstep(0.86, 0.96, r);
    float3 c = mix(iris, P.colorB.rgb, pupil);
    c = mix(c, rim, ring);
    s.albedo = c;
    s.height = 0.5 - 0.1 * pupil;
    s.rough = 0.06; s.ao = 1.0; s.metal = 0.0;
    return s;
}
"""#
