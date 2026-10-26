// Fauna programs: plumageBody, plumageHead, plumageFeather, furCoat, quillCoat.
// Atlas programs (tileSize 0): u wraps around the body and is mirror symmetric (0 = dorsal/crown midline,
// 0.5 = ventral/throat midline), v runs 0 (rear/nape) to 1 (front/beak). Feather and strand tips point rearward.

let metalFauna = #"""
// ---------------------------------------------------------------- fauna
// Result of the overlapping feather-row lookup. t = 0..1 mirrored half circumference, y in row units.
struct FaRes {
    bool hit; float al; float an; float fid; float fid2; float tc; float vc; float shadow; float rowK;
};

// Feather centre in column units for row k, candidate index ci. Even rows centre on c + 0.5, odd rows on c.
// Candidates past the mirror lines are folded so the hash (and the jitter) mirror exactly.
float fa_center(int ci, int k, int H, float off, uint sd, thread float &fid, thread float &fid2) {
    float pos = float(ci) + off; float hp = float(H);
    bool lo = pos < 0.0, hi = pos > hp;
    float fp = lo ? -pos : (hi ? 2.0 * hp - pos : pos);
    int cf = int(round(fp - off));
    uint hs = pcg(uint(cf + 64) * 7919u + uint(k + 4096) * 104729u + sd);
    float j = (float(hs & 0xffffu) / 65536.0 - 0.5) * 0.22;
    fid = float((hs >> 8) & 0xffffu) / 65536.0;
    fid2 = float(pcg(hs) & 0xffffu) / 65536.0;
    if (fp < 0.01 || fp > hp - 0.01) j = 0.0;
    float c = fp + j;
    return lo ? -c : (hi ? 2.0 * hp - c : c);
}

FaRes fa_rows(float t, float v, float R, int H, uint sd, float halfW, float tipK) {
    FaRes r; r.hit = false; r.al = 0; r.an = 0; r.fid = 0.5; r.fid2 = 0.5; r.tc = t; r.vc = v; r.shadow = 1; r.rowK = 0;
    float y = v * R, x = t * float(H);
    int k0 = int(floor(y));
    float bestAn = 9.0;
    for (int dk = 0; dk < 3; dk++) {
        int k = k0 - dk;
        float off = ((k & 1) == 0) ? 0.5 : 0.0;
        int ci0 = int(floor(x - off));
        for (int q = 0; q < 2; q++) {
            float f1, f2; float cx = fa_center(ci0 + q, k, H, off, sd, f1, f2);
            float a = (x - cx) / halfW;
            float tipJ = (f2 - 0.5) * 0.3;
            float al = (y - float(k)) - tipK * a * a - tipJ;
            if (al > 0.0 && al < 2.6 && fabs(a) < 1.0 && fabs(a) < bestAn) {
                bestAn = fabs(a); r.hit = true; r.al = al; r.an = a; r.fid = f1; r.fid2 = f2;
                r.tc = clamp(cx / float(H), 0.0, 1.0); r.vc = (float(k) + 0.6) / R; r.rowK = float(k);
            }
        }
        if (r.hit) break;
    }
    if (r.hit) {
        // Shadow cast by the next row's tip edge onto this feather's visible zone.
        int k = int(r.rowK) + 1; float off = ((k & 1) == 0) ? 0.5 : 0.0;
        int ci0 = int(floor(x - off)); float best = -9.0;
        for (int q = 0; q < 2; q++) {
            float f1, f2; float cx = fa_center(ci0 + q, k, H, off, sd, f1, f2);
            float a = (x - cx) / halfW;
            float al1 = (y - float(k)) - tipK * a * a - (f2 - 0.5) * 0.3;
            if (fabs(a) < 1.1) best = max(best, al1);
        }
        r.shadow = 1.0 - 0.62 * smoothstep(-0.55, 0.0, best);
    }
    return r;
}

// Barbs, rachis, tone jitter, shadows: shared by body and head. base = zone colour. Writes S.
S fa_featherShade(FaRes r, float3 base, float barbF, float sheen, uint sd, float2 uv) {
    S s = defaults();
    if (!r.hit) { s.albedo = base * 0.05; s.ao = 0.05; s.height = 0.0; s.rough = 0.7; return s; }
    float an = r.an, al = r.al;
    float tone = 0.86 + 0.28 * r.fid2;
    // Barbs: lines sweep from the rachis toward the tip.
    float bb = (al + 0.9 * fabs(an) * 0.6) * barbF;
    int bi = int(floor(bb)); float fr = bb - floor(bb);
    float hb = h01(int2(bi, int(r.fid * 997.0)), sd + 31u);
    float stripe = 0.5 + 0.5 * cos(fr * 6.2831853);
    float barbTone = 1.0 + 0.16 * (hb - 0.5) * 2.0 + 0.07 * (stripe - 0.5);
    // Feathers pale slightly toward the tip edge and darken toward the base (hidden part).
    float lit = 0.80 + 0.30 * (1.0 - smoothstep(0.0, 1.3, al));
    // Rachis.
    float rw = 0.045 * (1.0 - 0.35 * saturate(al / 1.6));
    float rach = 1.0 - smoothstep(rw * 0.5, rw, fabs(an));
    // Fine mottling.
    float mot = 1.0 + 0.10 * fbm(uv, int2(24, 24), 2, sd + 5u);
    float3 c = base * tone * barbTone * lit * mot;
    c = mix(c, c * 1.35 + 0.02, rach * 0.7);
    // Soft rounded edge darkening near the sides.
    c *= 1.0 - 0.18 * smoothstep(0.55, 1.0, fabs(an));
    // Fine split lines.
    float split = step(0.93, h01(int2(bi, int(r.fid * 997.0)), sd + 47u)) * smoothstep(0.35, 0.5, fr) * (1.0 - smoothstep(0.5, 0.65, fr));
    c *= 1.0 - 0.35 * split * smoothstep(0.15, 0.5, fabs(an));
    c *= mix(1.0, 0.55, 1.0 - r.shadow);
    s.albedo = c;
    float tipEdge = 1.0 - smoothstep(0.0, 0.10, al);
    s.height = 0.30 + 0.38 * (1.0 - smoothstep(0.0, 1.15, al)) + 0.05 * (stripe - 0.5) + 0.07 * rach - 0.10 * (1.0 - r.shadow) + 0.05 * tipEdge;
    s.ao = saturate(0.35 + 0.65 * r.shadow) * (0.8 + 0.2 * smoothstep(0.0, 0.5, al));
    s.rough = clamp(0.64 - sheen * (0.12 * stripe + 0.06 * rach), 0.45, 0.72);
    return s;
}

float3 fa_darken(float3 c) { return c * 0.30 + float3(0.004); }

S plumageBody(float2 uv, constant RFParams &P) {
    float R = max(P.f.x, 6.0);
    int H = max(4, int(round(R * 0.75)));
    float d = min(uv.x, 1.0 - uv.x); float t = d * 2.0;
    FaRes r = fa_rows(t, uv.y, R, H, P.seed, 0.62, 0.55);
    float bnd = P.f.y;
        // Colour fields use the continuous surface coordinate with a soft edge; per-feather noise only
    // feathers the boundary slightly so it never reads as a pixel grid.
    float fz = 0.04 * fbm(float2(t, uv.y), int2(4, 6), 3, P.seed + 3u) + (r.fid - 0.5) * 0.03;
    float uw = smoothstep(bnd - 0.07, bnd + 0.07, t + fz);
    bool under = uw > 0.5;
    float3 base = mix(P.colorA.rgb, P.colorB.rgb, uw);
    float patch = 0.0;
    if (P.f.z > 0.001) {
        float pv = (1.0 - uv.y) / P.f.z;
        float lat = smoothstep(bnd - 0.02, bnd + 0.22, t + fz);
        float w = (1.0 - smoothstep(0.55, 1.05, pv + fz * 2.0)) * lat;
        patch = smoothstep(0.25, 0.75, w + (r.fid2 - 0.5) * 0.08);
        base = mix(base, P.colorC.rgb, patch);
    }
    // Spots / streaks on underparts.
    float mark = 0.0;
    if (P.f.w > 0.001 && under) {
        float zone = 0.45 + 0.55 * smoothstep(0.1, 0.6, r.vc);
        float pick = h01(int2(int(r.fid * 1013.0), int(r.fid2 * 1013.0)), P.seed + 61u);
        if (pick < P.f.w * zone * 1.25) {
            float elong = mix(0.6, 1.6, fract(r.fid * 7.3));
            float ry = 0.34 * elong, rx = 0.26;
            float q = pow(r.an / rx, 2.0) + pow((r.al - 0.32 - 0.1 * elong) / ry, 2.0);
            // Teardrop: narrower toward the tip.
            q += 0.6 * max(0.0, (0.35 - r.al)) * 2.0;
            mark = 1.0 - smoothstep(0.6, 1.1, q);
            mark *= 0.85 * (1.0 - 0.5 * patch);
        }
    }
    base = mix(base, fa_darken(P.colorA.rgb) * 1.4, mark);
    S s = fa_featherShade(r, base, 7.0, 1.0, P.seed, uv);
    s.metal = 0.0;
    return s;
}

S plumageHead(float2 uv, constant RFParams &P) {
    float R = max(P.f.x, 10.0);
    int H = max(5, int(round(R * 0.9)));
    float d = min(uv.x, 1.0 - uv.x); float t = d * 2.0;
    FaRes r = fa_rows(t, uv.y, R, H, P.seed + 17u, 0.62, 0.5);
    float fz = 0.035 * fbm(float2(t, uv.y), int2(4, 4), 3, P.seed + 9u) + (r.fid - 0.5) * 0.025;
    float sw = smoothstep(P.f.y - 0.06, P.f.y + 0.06, t + fz);
    float3 base = mix(P.colorA.rgb, P.colorB.rgb, sw);
    float jit = (r.fid2 - 0.5) * 0.08;
    if (P.f.w > 0.001) {
        float m = smoothstep(1.0 - P.f.w - 0.06, 1.0 - P.f.w + 0.06, uv.y + fz);
        float lat = smoothstep(P.f.y - 0.04, P.f.y + 0.10, t + fz);
        base = mix(base, P.colorC.rgb, smoothstep(0.3, 0.7, m * lat + jit));
    }
    if (P.f.z > 0.001) {
        float pv = (uv.y - (1.0 - P.f.z)) / P.f.z;
        float lat = smoothstep(0.60, 0.84, t + fz);
        base = mix(base, P.colorC.rgb, smoothstep(0.3, 0.7, smoothstep(-0.05, 0.5, pv) * lat + jit));
    }
    S s = fa_featherShade(r, base, 9.0, 1.0, P.seed, uv);
    s.metal = 0.0;
    return s;
}

// Single feather card. u across (rachis near 0.5), v from base (0) to tip (1).
S plumageFeather(float2 uv, constant RFParams &P) {
    S s = defaults(); s.alpha = 0.0; s.rough = 0.58;
    float dens = max(P.f.x, 20.0);
    float asym = saturate(P.f.w);
    float phase = h01u(P.seed + 5u) * 6.28;
    float v = uv.y;
    float rc = 0.03 * sin(v * 2.4 + phase) * v;
    float x = uv.x - 0.5 - rc;
    float ax = fabs(x);
    bool outer = x < 0.0;
    // Vane width profile: narrow quill, broad middle, rounded tip.
    float vb = smoothstep(0.03, 0.5, v);
    float tp = v < 0.6 ? 1.0 : sqrt(saturate(1.0 - pow((v - 0.6) / 0.38, 2.0)));
    tp = pow(tp, 0.85);
    float w0 = 0.43 * pow(vb, 0.65) * tp;
    float notch = 0.38 * asym * exp(-pow((v - 0.66) / 0.035, 2.0));
    float w = outer ? w0 * (1.0 - 0.5 * asym) * (1.0 - notch) : w0 * (1.0 + 0.08 * asym);
    // Barb lines sweep toward the tip.
    float slope = outer ? 1.15 : 0.9;
    float bb = (v - slope * ax) * dens;
    int bi = int(floor(bb)); float fr = bb - floor(bb);
    int side = outer ? 1 : 0;
    float hb = h01(int2(bi, side), P.seed + 3u);
    float hg = h01(int2(bi, side), P.seed + 11u);
    float hg2 = h01(int2(bi, side), P.seed + 19u);
    // Frayed barb ends and split gaps.
    float edgeZone = smoothstep(0.55, 1.0, ax / max(w, 1e-3));
    float wEff = w * (1.0 + 0.09 * (hb - 0.5) * 2.0 * (0.4 + 0.6 * edgeZone));
    bool gap = hg < 0.055 && ax > w * (0.25 + 0.55 * hg2) && fr > 0.28 && fr < 0.72;
    float wr = 0.0075 * (1.0 - 0.45 * v) + 0.0045 * (1.0 - smoothstep(0.0, 0.12, v));
    float aa = 1.5 / float(P.size);
    float vane = gap ? 0.0 : saturate((wEff - ax) / aa);
    float shaft = saturate((wr - ax) / aa);
    float alive = v < 0.992 ? 1.0 : saturate((1.0 - v) / (aa * 3.0));
    float alpha = max(vane, shaft) * alive;
    // Colour.
    float edgeN = saturate(ax / max(w, 1e-3));
    float outerMix = saturate(0.75 * pow(edgeN, 2.0) + 0.55 * smoothstep(0.5, 1.0, v));
    float3 c = mix(P.colorA.rgb, P.colorB.rgb, outerMix);
    // Cross bars and mottle.
    float bars = 0.0;
    if (P.f.z > 0.001) {
        float q = v + 0.5 * x * x * 2.0 + 0.012 * sin(ax * 40.0 + phase);
        float b = 0.5 + 0.5 * sin(q * 6.2831853 * 5.5 + phase);
        float mot = fbm(float2(uv.x, uv.y), int2(6, 10), 3, P.seed + 7u);
        bars = P.f.z * (smoothstep(0.55, 0.85, b) * 0.8 + 0.5 * smoothstep(-0.05, 0.25, mot)) * smoothstep(0.2, 0.4, v);
        bars = saturate(bars);
        c = mix(c, c * 0.28 + float3(0.003), bars);
    }
    // Barb striations.
    float stripe = 0.5 + 0.5 * cos(fr * 6.2831853);
    c *= 1.0 + 0.20 * (hb - 0.5) * 2.0 + 0.08 * (stripe - 0.5);
    c *= 0.90 + 0.14 * fbm(uv, int2(14, 20), 2, P.seed + 13u);
    // Pale tip / edge fringe, ragged per barb.
    float dist = wEff - ax;
    float fringeW = P.f.y * 0.09;
    float pale = fringeW > 0.0 ? 1.0 - smoothstep(0.0, fringeW, dist + 0.012 * (hb - 0.5)) : 0.0;
    pale *= smoothstep(0.3, 0.85, v);
    pale *= 1.0 - 0.7 * bars * 0.0;
    c = mix(c, P.colorC.rgb, pale);
    // Rachis: lighter shaft toward the quill, slightly darker at the tip.
    float3 shaftC = mix(float3(0.62, 0.56, 0.42), P.colorC.rgb, 0.3) * (1.0 - 0.3 * v);
    c = mix(c, shaftC, shaft);
    // Downy base: loose, paler, thinner.
    c = mix(c, c * 1.15 + 0.02, 1.0 - smoothstep(0.1, 0.35, v));
    float3 avg = mix(P.colorA.rgb, P.colorB.rgb, 0.4);
    s.albedo = alpha > 0.02 ? c : avg;
    s.alpha = alpha;
    s.height = 0.45 + 0.06 * (stripe - 0.5) + 0.04 * (hb - 0.5) + 0.38 * shaft * (1.0 - ax / max(wr, 1e-4) * 0.4) - 0.05 * smoothstep(0.7, 1.0, edgeN);
    s.rough = clamp(0.55 + 0.1 * (1.0 - stripe) - 0.08 * shaft, 0.4, 0.7);
    s.ao = 1.0 - 0.18 * edgeN * edgeN;
    return s;
}

// Mirror-symmetric strand lookup. Returns true on hit; writes colour parameters.
struct FaStrand { bool hit; float sl; float across; float cxn; float vcs; float h1; float h2; float h3; };

FaStrand fa_strand(float t, float v, int nx, float lenV, uint sd, float wmax, float wavy) {
    FaStrand o; o.hit = false; o.sl = 0; o.across = 0; o.cxn = t; o.vcs = v; o.h1 = 0; o.h2 = 0; o.h3 = 0;
    float x = t * float(nx);
    int c0 = int(floor(x));
    float bestAcross = 9.0;
    for (int dc = -1; dc <= 1; dc++) {
        int ci = c0 + dc;
        float pos = float(ci) + 0.5; float hp = float(nx);
        bool lo = pos < 0.0, hi = pos > hp;
        float fp = lo ? -pos : (hi ? 2.0 * hp - pos : pos);
        int cf = int(round(fp - 0.5));
        uint hc = pcg(uint(cf + 8) * 2654435u + sd);
        float jit = (float(hc & 0xffffu) / 65536.0 - 0.5) * 0.6;
        float ph = float((hc >> 12) & 0xffffu) / 65536.0;
        float yy = v / lenV + ph;
        int k0 = int(floor(yy));
        for (int dk = 0; dk < 2; dk++) {
            int kk = k0 - dk;
            uint hs = pcg(hc ^ pcg(uint(kk + 100000)));
            float g1 = float(hs & 0xffffu) / 65536.0, g2 = float((hs >> 10) & 0xffffu) / 65536.0, g3 = float(pcg(hs) & 0xffffu) / 65536.0;
            float loc = yy - float(kk);
            float Lk = 1.15 + 0.5 * g1;
            float sl = loc / Lk;
            if (sl <= 0.0 || sl >= 1.0) continue;
            float wave = wavy * sin(yy * 2.3 + g2 * 6.28) * (0.4 + 0.6 * sl) * ((fp < 0.05 || fp > hp - 0.05) ? 0.0 : 1.0);
            float rj = (g3 - 0.5) * 0.9 * ((fp < 0.05 || fp > hp - 0.05) ? 0.0 : 1.0);   // per-row offset breaks column alignment
            float cu = fp + jit + rj + wave;
            float cx = lo ? -cu : (hi ? 2.0 * hp - cu : cu);
            float hw = wmax * pow(saturate(sl * 4.0), 0.6) * (1.0 - 0.25 * sl);
            float a = (x - cx) / max(hw, 1e-3);
            if (fabs(a) < 1.0 && fabs(a) < bestAcross) {
                bestAcross = fabs(a);
                o.hit = true; o.sl = sl; o.across = a; o.cxn = clamp(cx / float(nx), 0.0, 1.0);
                o.vcs = (float(kk) + 0.5 - ph) * lenV; o.h1 = g1; o.h2 = g2; o.h3 = g3;
            }
        }
    }
    return o;
}

// Coat marking weight 0..1 in atlas space (t: 0 dorsal midline .. 1 ventral midline, v: 0 rear .. 1 front).
// kind 1 tabby stripes, 2 spots, 3 patches, 4 saddle. Painted in the accent colour by furCoat and furShell.
float coatMark(float2 uv, int kind, uint sd) {
    kind = kind & 15;
    if (kind <= 0) return 0.0;
    float t = min(uv.x, 1.0 - uv.x) * 2.0;
    float n = fbm(uv, int2(6, 8), 3, sd + 4001u);
    if (kind == 1) {
        float w = fbm(uv, int2(4, 6), 2, sd + 4003u);
        float band = sin((uv.y * 15.0 + t * 2.2 + w * 2.6) * 3.14159265);
        return smoothstep(0.30, 0.52, band) * (1.0 - smoothstep(0.62, 0.86, t + 0.08 * n));
    }
    if (kind == 2) {
        float2 g = float2(t * 9.0, uv.y * 15.0);
        float2 c0 = floor(g); float best = 9.0; float rad = 0.3;
        for (int j = -1; j <= 1; j++) for (int i = -1; i <= 1; i++) {
            float2 c = c0 + float2(i, j);
            uint hs = pcg(uint(int(c.x) + 4096) * 7919u + uint(int(c.y) + 4096) * 104729u + sd + 4007u);
            float2 o = float2(float(hs & 0xffffu), float((hs >> 16) & 0xffffu)) / 65536.0;
            float r = length(g - (c + 0.2 + 0.6 * o));
            if (r < best) { best = r; rad = 0.18 + 0.2 * (float(pcg(hs) & 0xffffu) / 65536.0); }
        }
        return (1.0 - smoothstep(rad * 0.7, rad, best)) * (1.0 - smoothstep(0.8, 0.95, t));
    }
    if (kind == 3) return smoothstep(0.0, 0.06, fbm(uv, int2(3, 4), 3, sd + 4011u));
    return 1.0 - smoothstep(0.34, 0.46, t + 0.07 * n);
}

S furCoat(float2 uv, constant RFParams &P) {
    S s = defaults(); s.rough = 0.9;
    float nx0 = max(P.f.x, 24.0);
    float fuzz = saturate(P.f.w);
    float d = min(uv.x, 1.0 - uv.x); float t = d * 2.0;
    float zn = 0.07 * fbm(float2(t, uv.y), int2(4, 6), 3, P.seed + 3u);
    float lum = dot(P.colorC.rgb, float3(0.3, 0.55, 0.15));
    float sw = P.f.z * (1.0 - smoothstep(0.08, 0.30, lum));            // stripes only with a dark colorC
    // Coat-wide colour variation: broad light/dark patches plus a warm/cool drift.
    // Dog charts (pad0 bit 16) cover u 0..0.5 per half circumference but v 0..1, so halve the u frequency for round blotches.
    bool dg = int(P.pad0) >= 16;
    int2 fP = dg ? int2(3, 6) : int2(5, 7), fD = dg ? int2(6, 12) : int2(9, 13);
    float patch = fbm(uv, fP, 3, P.seed + 111u);
    float drift = fbm(uv, fD, 2, P.seed + 211u);
    float3 tint = float3(1.0 + 0.06 * drift, 1.0, 1.0 - 0.06 * drift) * (1.0 + 0.14 * patch);
    // Low-frequency domain warp breaks strand-row alignment (tile banding). Mirror safe: t stays >= 0.
    float2 wp = float2(fbm(uv, dg ? int2(4, 8) : int2(6, 9), 2, P.seed + 301u), fbm(uv, dg ? int2(3, 6) : int2(7, 5), 2, P.seed + 303u));
    float tw = fabs(t + 0.006 * wp.x), vw = uv.y + 0.008 * wp.y;
    // Layers from the surface down: sparse long guard hairs, then four dense fine coat layers.
    const float scl[5] = { 0.42, 1.0, 1.17, 0.88, 1.31 };
    float3 outC = float3(0.0); float hgt = 0.1, ao = 0.3; bool got = false;
    for (int l = 0; l < 5; l++) {
        bool gl = (l == 0);
        int nx = max(8, int(round(nx0 * scl[l] * (gl ? 1.0 : 1.35))));
        float lenV = (gl ? (5.0 + 5.0 * fuzz) : (2.6 + 2.6 * fuzz)) / float(nx);   // short strands: 2-4x width, no grain streaks
        FaStrand st = fa_strand(tw, vw, nx, lenV, P.seed + uint(l) * 977u, gl ? 0.36 : 0.56, gl ? 0.18 : 0.30);
        if (!st.hit) continue;
        if (gl && st.h1 < 0.55) continue;                                  // guard hairs are a sparse subset
        got = true;
        float front = 1.0 - float(l) / 4.0;
        bool under = (st.cxn + (st.h3 - 0.5) * 0.12 + zn) > P.f.y;
        float3 baseC = (under ? P.colorB.rgb : P.colorA.rgb) * tint;
        float3 uc = baseC * 0.66;
        float tone = 0.86 + 0.28 * st.h2;
        float3 band = under ? baseC * tone : baseC * (0.92 + 0.22 * st.h2);
        float guard = step(0.72 - 0.35 * P.f.z, st.h1);
        float3 tip = under ? baseC * 1.05 : mix(baseC * 0.82, P.colorC.rgb, guard);
        float sl = st.sl;
        // Root dark, mid band, light tip: smooth gradient along the strand (sl 0 tip .. 1 root).
        float3 c = mix(tip * 1.12, band, smoothstep(0.05, 0.40, sl));
        c = mix(c, uc * 0.72, smoothstep(0.45, 0.95, sl));
        // Per-strand fine noise across and along the hair.
        c *= 0.9 + 0.2 * fract(st.h3 * 37.0 + st.across * 3.1) * (0.6 + 0.4 * sl);
        // Pale, translucent-looking tip.
        c += baseC * 0.25 * (1.0 - smoothstep(0.0, 0.10, sl)) * (0.4 + 0.6 * st.h2);
        if (gl) {
            // Guard hair: dark, glossy, tapering to a point.
            float3 gc = mix(baseC * 0.45, P.colorC.rgb * 0.8 + baseC * 0.15, 0.6);
            c = mix(gc * (0.8 + 0.4 * st.h2), uc, smoothstep(0.6, 0.9, sl));
        }
        // Chipmunk stripes on the back (u about 0.075..0.142).
        if (sw > 0.001) {
            float dd = st.cxn * 0.5 + (st.h3 - 0.5) * 0.010;
            float dark = smoothstep(0.068, 0.078, dd) * (1.0 - smoothstep(0.106, 0.114, dd));
            float pale = smoothstep(0.106, 0.114, dd) * (1.0 - smoothstep(0.140, 0.150, dd));
            float3 pc = P.colorB.rgb * 1.25 + 0.01;
            if (dark * sw > st.h2 * 0.8 + 0.1) c = mix(c, P.colorC.rgb * (0.55 + 0.9 * smoothstep(0.1, 0.6, sl)), 0.9);
            else if (pale * sw > st.h1 * 0.8 + 0.1) c = mix(c, pc * (0.5 + 0.7 * smoothstep(0.1, 0.5, sl)), 0.85);
        }
        float cyl = sqrt(max(0.0, 1.0 - st.across * st.across));
        // Depth shading: lower layers sit in the under-coat shadow.
        c *= (0.84 + 0.16 * front) * (0.90 + 0.10 * cyl);
        outC = c;
        hgt = 0.12 + 0.13 * (4.0 - float(l)) + (0.10 + 0.12 * fuzz) * cyl;
        float depthAO = gl ? 1.0 : (0.38 + 0.16 * (4.0 - float(l)));
        ao = depthAO * (0.45 + 0.55 * (1.0 - smoothstep(0.35, 0.95, sl)));
        break;
    }
    if (!got) {
        bool under = (t + zn) > P.f.y;
        float3 baseC = (under ? P.colorB.rgb : P.colorA.rgb) * tint;
        outC = baseC * 0.72 * (0.85 + 0.3 * fbm(uv, int2(120, 120), 2, P.seed + 31u));
        hgt = 0.03; ao = 0.08;
    }
    float soft = fbm(uv, int2(160, 160), 2, P.seed + 71u);
    outC *= 1.0 + (0.06 + 0.10 * fuzz) * soft;
    // Soften strand contrast toward the local coat colour so the coat reads as fur, not grain.
    bool underM = (t + zn) > P.f.y;
    float3 coat = (underM ? P.colorB.rgb : P.colorA.rgb) * tint * (0.92 + 0.12 * soft);
    outC = mix(outC, coat, 0.45);
    float mk = coatMark(uv, int(P.pad0), P.seed);
    if (mk > 0.001) {
        float dr = clamp(dot(outC, float3(0.3, 0.55, 0.15)) / max(dot(coat, float3(0.3, 0.55, 0.15)), 0.02), 0.55, 1.5);
        outC = mix(outC, P.colorC.rgb * dr, mk * 0.94);
        coat = mix(coat, P.colorC.rgb, mk * 0.94);
    }
    // Guard every channel: a NaN height turns the derived normal map NaN, which renders black under IBL.
    if (!all(isfinite(outC))) outC = coat;
    if (!isfinite(hgt)) hgt = 0.2;
    if (!isfinite(ao)) ao = 0.6;
    if (!isfinite(soft)) soft = 0.0;
    s.albedo = outC;
    s.height = hgt;
    s.ao = clamp(ao, 0.0, 1.0);
    s.rough = 0.88 + 0.06 * soft;
    return s;
}

// Shell fur strands for cutout shells. Alpha = strand height 0..1 (length x clump map); a shell at level
// k keeps texels with alpha > k, so strands thin toward their tips across the stack. Colour: back/belly
// split at the flank line (P.f.y), guard hairs (share P.f.w) tipped with colorC, P.f.z frost strength.
S furShell(float2 uv, constant RFParams &P) {
    S s = defaults(); s.rough = 0.86;
    float d = min(uv.x, 1.0 - uv.x); float t = d * 2.0;
    float nx = max(P.f.x, 24.0) * 3.0;
    float2 g = float2(t * nx, uv.y * nx * 0.7);
    float2 c0 = floor(g);
    float best = 9.0; float h1 = 0.0, h2 = 0.0;
    for (int j = -1; j <= 1; j++) for (int i = -1; i <= 1; i++) {
        float2 c = c0 + float2(i, j);
        uint hs = pcg(uint(int(c.x) + 4096) * 7919u + uint(int(c.y) + 4096) * 104729u + P.seed);
        float2 o = float2(float(hs & 0xffffu), float((hs >> 16) & 0xffffu)) / 65536.0;
        float r = length(g - (c + 0.15 + 0.7 * o));
        if (r < best) { best = r; h1 = float(pcg(hs) & 0xffffu) / 65536.0; h2 = o.x; }
    }
    float clump = fbm(uv, int2(14, 20), 2, P.seed + 17u);
    float len = saturate(0.45 + 0.4 * h1 + 0.35 * clump);
    float strand = 1.0 - smoothstep(0.22, 0.42, best);
    s.alpha = strand * len;
    float zn = 0.06 * fbm(float2(t, uv.y), int2(4, 6), 3, P.seed + 3u);
    bool under = (t + zn) > P.f.y;
    float3 base = (under ? P.colorB.rgb : P.colorA.rgb) * (0.86 + 0.28 * h2);
    bool guard = h1 > 1.0 - P.f.w;
    float mk = coatMark(uv, int(P.pad0), P.seed);
    base = mix(base, P.colorC.rgb * (0.86 + 0.28 * h2), mk * 0.94);
    s.albedo = guard ? mix(base, P.colorC.rgb, P.f.z) : base;
    s.height = s.alpha; s.ao = 1.0;
    return s;
}

S quillCoat(float2 uv, constant RFParams &P) {
    S s = defaults(); s.rough = 0.6;
    int N = max(8, int(P.f.x));
    float2 p = uv * float(N);
    int2 c0 = int2(floor(p));
    float contrast = saturate(P.f.y), jitter = saturate(P.f.z);
    float flow = gnoise(uv * 3.0, int2(3, 3), P.seed + 5u) * 1.4;
    float bestZ = -1.0;
    float3 col = P.colorC.rgb * 0.5; float hgt = 0.0, ao = 0.12;
    for (int L = 0; L < 2; L++) {
        for (int dy = -4; dy <= 1; dy++) for (int dx = -4; dx <= 4; dx++) {
            int2 cc = c0 + int2(dx, dy); int2 w = wrapc(cc, int2(N, N));
            uint hs = hash2(w, P.seed + uint(L) * 7919u);
            float h1 = float(hs & 0xffffu) / 65536.0, h2 = float((hs >> 16) & 0xffffu) / 65536.0;
            uint hs2 = pcg(hs);
            float h3 = float(hs2 & 0xffffu) / 65536.0, h4 = float((hs2 >> 16) & 0xffffu) / 65536.0;
            float h5 = float(pcg(hs2) & 0xffffu) / 65536.0;
            float2 p0 = float2(cc) + float2(h1, h2);
            float ang = 1.5708 + flow + (h3 - 0.5) * jitter * 3.0;
            float2 dir = float2(cos(ang), sin(ang)), perp = float2(-dir.y, dir.x);
            float Lc = 4.4 * (0.8 + 0.4 * h4);
            float2 dv = p - p0;
            float al = dot(dv, dir) / Lc, ac = dot(dv, perp);
            float hw = 0.17 * (0.45 + 0.55 * smoothstep(0.0, 0.18, al)) * (1.0 - 0.8 * smoothstep(0.72, 1.0, al));
            if (al > 0.0 && al < 1.0 && fabs(ac) < hw && h5 > bestZ) {
                bestZ = h5;
                float cyl = sqrt(max(0.0, 1.0 - pow(ac / hw, 2.0)));
                // Cream root, dark band, cream, dark tip (band edges jittered per spine).
                float j = (h4 - 0.5) * 0.08;
                float b1 = smoothstep(0.20 + j, 0.26 + j, al) * (1.0 - smoothstep(0.50 + j, 0.56 + j, al));
                float b2 = smoothstep(0.84 + j, 0.90 + j, al);
                float band = max(b1, b2) * contrast;
                float3 c = mix(P.colorA.rgb, P.colorB.rgb, band) * (0.88 + 0.24 * h3);
                c *= 0.65 + 0.35 * cyl;
                col = c;
                hgt = 0.2 + 0.55 * h5 + 0.2 * al + 0.15 * cyl;
                ao = mix(0.22, 1.0, pow(h5, 1.3)) * mix(0.5, 1.0, smoothstep(0.0, 0.4, al));
            }
        }
    }
    s.albedo = col; s.height = hgt; s.ao = ao;
    s.rough = 0.6 + 0.08 * (1.0 - bestZ);
    return s;
}
"""#
