// Packaging programs: packagePrint (printed retail label / carton / can / bag face, one design per tile)
// and packageSubstrate (unprinted films, foil, molded pulp, HDPE, wax paper, clear PET).

let metalPackaging = #"""
// ---------------------------------------------------------------- packaging
inline float pkN(float2 uv, int2 f, int o, uint s) { return 0.5 + fbm(uv, f, o, s); }
inline float pkRBox(float2 p, float2 c, float2 h, float r, float aa) {
    float2 d = abs(p - c) - h + r;
    float dist = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
    return 1.0 - smoothstep(-aa, aa, dist);
}
inline float pkIn(float2 p, float2 lo, float2 hi) { return step(lo.x, p.x) * step(p.x, hi.x) * step(lo.y, p.y) * step(p.y, hi.y); }
// Fine body copy: rows of word runs inside [lo, hi]; rowH in design units. Returns ink 0...1.
inline float pkText(float2 p, float2 lo, float2 hi, float rowH, uint sd) {
    if (pkIn(p, lo, hi) < 0.5) return 0.0;
    float2 q = float2(p.x - lo.x, hi.y - p.y);
    int row = int(q.y / rowH);
    float fy = fract(q.y / rowH);
    float line = smoothstep(0.18, 0.3, fy) * smoothstep(0.82, 0.7, fy);
    float len = 0.6 + 0.4 * h01(int2(row, 7), sd);
    if (h01(int2(row, 3), sd) < 0.15) len *= 0.4;
    float inRow = step(q.x, (hi.x - lo.x) * len);
    float cw = rowH * 0.45;
    int ci = int(q.x / cw);
    float space = step(0.17, h01(int2(ci, row), sd + 11u));
    float fx = fract(q.x / cw);
    float glyph = smoothstep(0.05, 0.2, fx) * smoothstep(0.95, 0.8, fx);
    float stems = 0.5 + 0.5 * step(0.45, h01(int2(int(q.x / cw * 3.0), row * 5 + int(fy * 3.0)), sd + 13u));
    return line * inRow * space * glyph * stems;
}
// UPC-A style barcode in [lo, hi] (white quiet zone drawn by the caller).
inline float pkBarcode(float2 p, float2 lo, float2 hi, uint sd) {
    if (pkIn(p, lo, hi) < 0.5) return 0.0;
    float u = (p.x - lo.x) / (hi.x - lo.x), v = (p.y - lo.y) / (hi.y - lo.y);
    int m = int(u * 95.0);
    bool guard = m < 3 || m > 91 || (m >= 46 && m < 49);
    float bar = guard ? float((m & 1) == 0) : step(0.48, h01(int2(m / 2, m & 1), sd));
    float digits = step(v, 0.16) * step(0.03, v) * step(0.3, fract(u * 24.0)) * step(fract(u * 24.0), 0.75) * (guard ? 0.0 : 1.0);
    return max(bar * step(guard ? 0.04 : 0.22, v), digits * 0.9);
}

// Printed retail face, one design per tile. Tile width = tileSize meters, height = tileSize * colorB.a.
// colorA brand field (the `key:RRGGBB` tint), colorB secondary panel / swoosh, colorC accent: logo pill,
// badge and product-art hue. colorC.a = crinkle (foil bag facets) 0...1.
// f.x product-art amount 0...1, f.y gloss 0 matte...1 high gloss, f.z wear (scuffs, creases, rubbed rims),
// f.w metallic substrate 0...1 (cans, metallised bags: bare metal shows where ink is rubbed and on rims).
S packagePrint(float2 uv, constant RFParams &P) {
    S s = defaults(); uint sd = P.seed;
    float aspect = P.colorB.a > 0.05 ? P.colorB.a : 1.0;
    float2 q = float2(fract(uv.x), 1.0 - fract(uv.y / aspect));   // design upright in the swatch and in world (v-up)
    float j1 = h01(int2(1, 1), sd), j2 = h01(int2(2, 1), sd), j3 = h01(int2(3, 1), sd);
    float3 A = P.colorA.rgb, B = P.colorB.rgb, C = P.colorC.rgb;
    float lumA = dot(A, float3(0.2126, 0.7152, 0.0722));
    float3 inkCopy = lumA > 0.22 ? float3(0.03, 0.03, 0.035) : float3(0.93);
    float fib = pkN(uv, int2(96, 96), 2, sd + 1u);
    float mott = pkN(uv, int2(8, 8), 3, sd + 2u);
    float2 mis = float2(0.0012 + 0.0016 * j1, -0.0009);       // plate B misregistration

    // Brand field: vertical gradient plus a soft glow behind the art.
    float3 c = A * mix(0.72, 1.12, smoothstep(0.0, 1.0, q.y));
    float2 ac = float2(0.30 + 0.06 * j3, 0.63);
    c *= 1.0 + 0.22 * P.f.x * (1.0 - smoothstep(0.0, 0.42, length((q - ac) * float2(1.0, 1.3))));
    float ink = 0.0;

    // Swoosh band (plate B) with white keyline.
    float2 qb = q + mis;
    float yc = 0.40 + 0.06 * sin((qb.x + j2) * 6.2831853);
    float yk = 0.40 + 0.06 * sin((q.x + j2) * 6.2831853);
    float band = 1.0 - smoothstep(-0.002, 0.002, abs(qb.y - yc) - 0.065);
    float keyl = 1.0 - smoothstep(0.0015, 0.004, abs(abs(q.y - yk) - 0.072));
    c = mix(c, B * mix(0.82, 1.08, sat((qb.y - yc + 0.065) / 0.13)), band);
    c = mix(c, float3(0.94), keyl * 0.95);

    // Product art: soft-lit organic forms, ground shadow, specular highlight.
    float2 ap = (q - ac) / float2(0.21, 0.19);
    float edgeN = pkN(uv, int2(5, 5), 2, sd + 3u) - 0.5;
    float artMask = (1.0 - smoothstep(0.78, 0.98, length(ap) + 0.25 * edgeN)) * P.f.x;
    float b1 = pkN(uv, int2(3, 3), 4, sd + 4u), b2 = pkN(uv, int2(4, 4), 4, sd + 5u);
    // Soft defocused backdrop, then three lit "product" forms (sphere shading, rim light, highlight).
    float3 art = mix(C * 0.55, mix(C, B, 0.5) * 0.8, smoothstep(0.3, 0.7, b1));
    art *= 0.8 + 0.3 * smoothstep(0.3, 0.7, b2);
    float3 L = normalize(float3(-0.5, 0.6, 0.65));
    for (int i = 0; i < 3; i++) {
        float2 oc = float2(-0.38 + 0.38 * float(i) + 0.08 * (h01(int2(i, 21), sd) - 0.5), -0.12 + 0.18 * h01(int2(i, 22), sd) + (i == 1 ? 0.14 : 0.0));
        float rr = 0.36 + 0.1 * h01(int2(i, 23), sd);
        float2 d = (ap - oc) / float2(rr, rr * 0.9);
        d += 0.06 * float2(pkN(uv, int2(7, 7), 2, sd + 24u + uint(i)) - 0.5, 0.0);
        float r2 = dot(d, d);
        if (r2 < 1.0) {
            float3 nrm = float3(d.x, d.y, sqrt(1.0 - r2));
            float dif = max(dot(nrm, L), 0.0);
            float tone = h01(int2(i, 25), sd);
            float3 base = mix(C, C * float3(1.1, 0.75, 0.5), tone * 0.6);
            base *= 0.9 + 0.2 * pkN(uv, int2(24, 24), 2, sd + 26u + uint(i));
            float3 lit = base * (0.22 + 0.95 * dif) + float3(1.0) * pow(max(dot(reflect(-L, nrm), float3(0, 0, 1)), 0.0), 24.0) * 0.7;
            lit += base * 0.35 * pow(1.0 - nrm.z, 3.0);
            art = mix(art, lit, smoothstep(1.0, 0.92, r2));
        }
    }
    float shadow = 1.0 - smoothstep(0.0, 1.0, length((q - ac - float2(0.0, -0.185)) / float2(0.24, 0.035)));
    c = mix(c, c * 0.55, shadow * P.f.x * 0.7);
    c = mix(c, art, artMask);

    // Logo pill (colorC) with white rim and bold rounded letterforms.
    float2 pc = float2(0.70, 0.85);
    float rim = pkRBox(q, pc, float2(0.25, 0.075), 0.07, 0.002);
    float pill = pkRBox(q, pc, float2(0.235, 0.06), 0.055, 0.002);
    c = mix(c, float3(0.95), rim);
    c = mix(c, C * mix(0.85, 1.1, (q.y - 0.79) / 0.12), pill);
    // Claim badge.
    float br = length(q - float2(0.84, 0.62));
    float badge = 1.0 - smoothstep(0.066, 0.07, br);
    c = mix(c, B, badge);
    c = mix(c, C * 0.8, (1.0 - smoothstep(0.002, 0.0045, abs(br - 0.058))) * badge);
    float bt = pkText(q, float2(0.80, 0.60), float2(0.885, 0.645), 0.012, sd + 40u);
    c = mix(c, A * 0.7, bt * badge);
    ink += pill + badge * 0.5;

    // Body copy, nutrition panel, barcode (lower third).
    float copy = pkText(q, float2(0.52, 0.06), float2(0.95, 0.28), 0.016, sd + 20u);
    c = mix(c, inkCopy, copy * 0.9);
    float2 nlo = float2(0.04, 0.04), nhi = float2(0.24, 0.31);
    float npan = pkIn(q, nlo, nhi);
    float nb = npan * (1.0 - pkIn(q, nlo + 0.004, nhi - 0.004));
    float ny = (nhi.y - q.y);
    float title = pkIn(q, float2(0.05, 0.27), float2(0.20, 0.295));
    float rules = npan * step(0.05, ny) * (1.0 - smoothstep(0.0006, 0.0016, abs(fract(ny / 0.022) - 0.5) * 0.022 - 0.0095));
    float thick = pkIn(q, float2(0.045, 0.255), float2(0.235, 0.262)) + pkIn(q, float2(0.045, 0.15), float2(0.235, 0.155));
    float ntext = pkText(q, float2(0.05, 0.05), float2(0.23, 0.25), 0.022, sd + 30u);
    c = mix(c, float3(0.95), npan);
    c = mix(c, float3(0.04), sat(nb + title + rules * 0.7 + thick + ntext * 0.85) * npan);
    float qz = pkIn(q, float2(0.27, 0.04), float2(0.46, 0.17));
    float bars = pkBarcode(q, float2(0.285, 0.05), float2(0.445, 0.16), sd + 50u);
    c = mix(c, float3(0.96), qz);
    c = mix(c, float3(0.03), bars * qz);
    ink += npan + qz;

    // Halftone-free ink texture: fibre and press mottle.
    c *= 0.97 + 0.04 * fib + 0.03 * (mott - 0.5);

    // Wear: rubbed scuffs along the wrap direction, rims, creases.
    float scN = pkN(uv, int2(3, 36), 3, sd + 60u) + 0.3 * (mott - 0.5);
    float scuff = smoothstep(0.8, 0.86, scN) * P.f.z;
    float rimW = (1.0 - smoothstep(0.0, 0.025, min(q.y, 1.0 - q.y))) * P.f.z * (0.5 + mott);
    float crease = 0.0;
    for (int i = 0; i < 3; i++) {
        float a = h01(int2(i, 70), sd) * 3.14159;
        float2 o = float2(h01(int2(i, 71), sd), h01(int2(i, 72), sd));
        float d = abs(dot(q - o, float2(cos(a), sin(a))));
        crease += (1.0 - smoothstep(0.0, 0.003, d)) * step(0.4, pkN(uv + float2(i), int2(6, 6), 2, sd + 73u + uint(i)));
    }
    crease = sat(crease) * P.f.z;
    float bare = sat(scuff * 0.8 + rimW);
    float3 substrate = mix(float3(0.86, 0.85, 0.82), float3(0.78, 0.79, 0.80), P.f.w);
    c = mix(c, substrate, bare);
    c = mix(c, c * 0.72, crease * 0.6);
    c = mix(c, c * 1.12 + 0.03, crease * 0.3 * smoothstep(0.6, 0.7, mott));

    // Crinkled film facets (bags).
    float crk = P.colorC.a;
    float cid = 0.0, cid2 = 0.0;
    float2 cl = cellLocal(uv, int2(14, 14), sd + 80u, cid, cid2);
    float4 wf = worley(uv, int2(14, 14), sd + 81u, 1.0);
    float ridge = 1.0 - smoothstep(0.0, 0.05, wf.y - wf.x);
    c *= 1.0 + crk * (0.14 * (cid - 0.5) + 0.1 * ridge);

    s.albedo = saturate(c);
    s.height = 0.5 + 0.01 * ink - 0.06 * crease + crk * (0.12 * (cid - 0.5) + 0.06 * ridge + 0.02 * cl.x) + 0.005 * fib;
    float rough = mix(0.62, 0.1, P.f.y) + 0.05 * (fib - 0.5) + 0.04 * (mott - 0.5);
    rough = mix(rough, rough * 0.75, artMask * P.f.y);            // spot varnish on the art
    rough += 0.25 * scuff + 0.15 * crease;
    rough = mix(rough, mix(0.35, 0.22, P.f.w), rimW);
    s.rough = clamp(rough, 0.04, 1.0);
    s.metal = sat(P.f.w * mix(0.3, 1.0, bare));
    s.ao = 1.0 - 0.3 * crease - 0.15 * crk * ridge;
    return s;
}

// Unprinted packaging substrate. colorA base, colorB shade / fibre, colorC highlight (a = metallic).
// f.x feature cells per tile, f.y relief strength 0...1, f.z roughness, f.w mode:
// 0 crinkled foil / film, 1 molded pulp, 2 natural HDPE (flow lines, orange peel),
// 3 wax paper (fibres, creases, wax sheen), 4 clear PET / shrink film (faint ripples).
S packageSubstrate(float2 uv, constant RFParams &P) {
    S s = defaults(); uint sd = P.seed;
    int G = max(2, int(P.f.x));
    int mode = int(P.f.w + 0.5);
    float3 A = P.colorA.rgb, B = P.colorB.rgb, C = P.colorC.rgb;
    float mott = pkN(uv, int2(4, 4), 3, sd + 1u);
    float3 c = A; float h = 0.5; float r = P.f.z; float ao = 1.0;
    if (mode == 0) {
        float cid = 0.0, cid2 = 0.0;
        float2 cl = cellLocal(uv, int2(G, G), sd + 2u, cid, cid2);
        float4 w = worley(uv, int2(G, G), sd + 3u, 1.0);
        float ridge = 1.0 - smoothstep(0.0, 0.06, w.y - w.x);
        float facet = cid + 0.35 * (cl.x * (cid2 - 0.5));
        c = mix(B, A, sat(0.25 + facet));
        c = mix(c, C, ridge * 0.5);
        h = 0.5 + P.f.y * (0.18 * (cid - 0.5) + 0.12 * ridge + 0.05 * cl.y);
        r = P.f.z * (0.8 + 0.4 * cid2) + 0.1 * ridge;
        ao = 1.0 - 0.25 * ridge * P.f.y;
    } else if (mode == 1) {
        float fibre = pkN(uv, int2(G * 8, G * 8), 3, sd + 4u);
        float lumps = pkN(uv, int2(G * 2, G * 2), 3, sd + 5u);
        float cid = 0.0, cid2 = 0.0;
        float2 cl = cellLocal(uv, int2(G, G), 0u, cid, cid2);
        float cup = 1.0 - smoothstep(0.0, 0.48, length(cl));
        c = A * (0.86 + 0.18 * fibre + 0.08 * (mott - 0.5));
        c = mix(c, B, smoothstep(0.62, 0.8, fibre) * 0.5);
        float speck = step(0.985, h01(int2(uv * float(G * 64)), sd + 6u));
        c = mix(c, C, speck * 0.8);
        h = 0.5 + P.f.y * (0.35 * cup) + 0.06 * fibre + 0.04 * lumps;
        c *= 0.82 + 0.18 * cup; r = P.f.z; ao = 0.8 + 0.2 * cup;
    } else if (mode == 2) {
        float flow = pkN(uv, int2(2, G), 4, sd + 7u);
        float peel = pkN(uv, int2(G * 6, G * 6), 2, sd + 8u);
        c = mix(A, B, smoothstep(0.35, 0.75, flow) * 0.35);
        c *= 0.97 + 0.05 * peel;
        h = 0.5 + 0.04 * P.f.y * peel + 0.03 * flow;
        r = P.f.z + 0.06 * (peel - 0.5);
    } else if (mode == 3) {
        float fibre = pkN(uv * float2(1.0, 1.0), int2(G * 4, G * 16), 3, sd + 9u);
        c = A * (0.92 + 0.12 * fibre) ;
        float crease = 0.0;
        for (int i = 0; i < 4; i++) {
            float a = h01(int2(i, 90), sd) * 3.14159;
            float2 o = float2(h01(int2(i, 91), sd), h01(int2(i, 92), sd));
            float d = abs(dot(fract(uv) - o, float2(cos(a), sin(a))));
            crease += 1.0 - smoothstep(0.0, 0.006, d);
        }
        crease = sat(crease) * P.f.y;
        c = mix(c, B, crease * 0.4);
        float sheen = smoothstep(0.45, 0.75, mott);
        c = mix(c, C, sheen * 0.15);
        h = 0.5 + 0.03 * fibre - 0.1 * crease;
        r = P.f.z + 0.2 * (1.0 - sheen) * 0.5 + 0.15 * crease;
        ao = 1.0 - 0.2 * crease;
    } else {
        float rip = pkN(uv, int2(1, G), 4, sd + 10u);
        c = mix(A, B, smoothstep(0.4, 0.7, rip) * 0.3);
        h = 0.5 + 0.05 * P.f.y * rip;
        r = P.f.z + 0.03 * mott;
    }
    s.albedo = saturate(c); s.height = h; s.rough = clamp(r, 0.02, 1.0); s.ao = ao;
    s.metal = sat(P.colorC.a);
    return s;
}
"""#
