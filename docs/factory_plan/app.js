(() => {
  const P = window.PLAN;
  const NS = "http://www.w3.org/2000/svg";
  const LV = ["B", "G", "C1", "C2"];
  const LVY = { B: -4, G: 0, C1: 4, C2: 8 };
  const LVNAME = { B: "Basement −4", G: "Ground 0", C1: "Catwalk +4", C2: "Catwalk +8" };
  const lvOf = y => (y <= -2 ? "B" : y >= 6 ? "C2" : y >= 2 ? "C1" : "G");
  const rank = lv => LV.indexOf(lv);
  const svg = document.getElementById("map");
  const state = { focus: "all", layers: { route: true, blockers: true, payoffs: true, labels: true, walls: false, setpiece: true } };
  try {
    const s = JSON.parse(localStorage.getItem("factoryPlan.ui") || "null");
    if (s && s.layers) { if (s.focus === "all" || s.focus in LVY) state.focus = s.focus; Object.assign(state.layers, s.layers); }
  } catch (e) {}
  const save = () => { try { localStorage.setItem("factoryPlan.ui", JSON.stringify(state)); } catch (e) {} };

  const fmt = n => String(Math.round(n * 10) / 10).replace("-", "−");
  const el = (tag, attrs, parent) => {
    const e = document.createElementNS(NS, tag);
    for (const k in attrs) if (attrs[k] != null && attrs[k] !== "") e.setAttribute(k, attrs[k]);
    if (parent) parent.appendChild(e);
    return e;
  };
  const ptsOf = o => o.poly || [[o.rect[0], o.rect[1]], [o.rect[2], o.rect[1]], [o.rect[2], o.rect[3]], [o.rect[0], o.rect[3]]];
  const pstr = pts => pts.map(p => p[0] + "," + p[1]).join(" ");
  const sizeOf = o => {
    if (o.circle) return "⌀ " + fmt(o.circle[2] * 2);
    const pts = ptsOf(o), xs = pts.map(p => p[0]), zs = pts.map(p => p[1]);
    return fmt(Math.max(...xs) - Math.min(...xs)) + " × " + fmt(Math.max(...zs) - Math.min(...zs));
  };
  const segStats = seg => {
    let len = 0, climb = 0;
    for (let i = 0; i < seg.pts.length - 1; i++) {
      const a = seg.pts[i], b = seg.pts[i + 1];
      len += Math.hypot(b[0] - a[0], b[1] - a[1]);
      climb += Math.abs(b[2] - a[2]);
    }
    return { len, climb };
  };
  const clock = s => Math.floor(s / 60) + ":" + String(Math.round(s % 60)).padStart(2, "0");

  let INFO = [];
  let defs;
  const reg = (g, info) => { g.setAttribute("data-i", INFO.push(info) - 1); g.classList.add("hit"); };
  const group = (parent, cls) => el("g", { class: cls }, parent);

  function vis(lv, pass) {
    if (state.focus === "all") return pass === "xray" ? "xray" : "";
    const d = rank(lv) - rank(state.focus);
    return d === 0 ? "" : d < 0 ? "ghost" : "over";
  }
  function visSpan(a, b) {
    if (state.focus === "all") return "";
    const f = rank(state.focus), lo = Math.min(rank(a), rank(b)), hi = Math.max(rank(a), rank(b));
    return f >= lo && f <= hi ? "" : hi < f ? "ghost" : "over";
  }

  function patterns() {
    const hb = el("pattern", { id: "hatchBack", width: 2, height: 2, patternUnits: "userSpaceOnUse", patternTransform: "rotate(45)" }, defs);
    el("rect", { width: 2, height: 2, class: "pat", style: "fill:var(--backdrop)" }, hb);
    el("line", { x1: 0, y1: 0, x2: 0, y2: 2, class: "pat", style: "stroke:var(--grid-major);stroke-width:.6px" }, hb);
    const hl = el("pattern", { id: "hatchLow", width: 1.1, height: 1.1, patternUnits: "userSpaceOnUse", patternTransform: "rotate(45)" }, defs);
    el("rect", { width: 1.1, height: 1.1, class: "pat", style: "fill:var(--panel)" }, hl);
    el("line", { x1: 0, y1: 0, x2: 0, y2: 1.1, class: "pat", style: "stroke:var(--blocker-low);stroke-width:.35px" }, hl);
    const vd = el("pattern", { id: "void", width: 1.6, height: 1.6, patternUnits: "userSpaceOnUse", patternTransform: "rotate(-45)" }, defs);
    el("rect", { width: 1.6, height: 1.6, class: "pat", style: "fill:var(--mass)" }, vd);
    el("line", { x1: 0, y1: 0, x2: 0, y2: 1.6, class: "pat", style: "stroke:var(--lv-B);stroke-width:.45px" }, vd);
  }

  function drawGrid(root) {
    const [bx, bz, bw, bh] = P.bounds;
    let minor = "", major = "";
    const g = group(root);
    for (let x = Math.ceil(bx / 10) * 10; x <= bx + bw; x += 10) {
      const d = `M${x},${bz}V${bz + bh}`;
      if (x % 50 === 0) { major += d; el("text", { x: x + 0.6, y: bz + 2.6, class: "axis", style: "font-size:2px" }, g).textContent = "x " + fmt(x); }
      else minor += d;
    }
    for (let z = Math.ceil(bz / 10) * 10; z <= bz + bh; z += 10) {
      const d = `M${bx},${z}H${bx + bw}`;
      if (z % 50 === 0) { major += d; el("text", { x: bx + 0.8, y: z - 0.7, class: "axis", style: "font-size:2px" }, g).textContent = "z " + fmt(z); }
      else minor += d;
    }
    g.prepend(el("path", { d: major, style: "fill:none;stroke:var(--grid-major);stroke-width:1px" }));
    g.prepend(el("path", { d: minor, style: "fill:none;stroke:var(--grid);stroke-width:1px" }));
    // Scale bar and north, in the empty north-west corner.
    const s = group(root);
    el("path", { d: "M-100,-120H-80M-100,-121.2V-118.8M-90,-120.8V-119.2M-80,-121.2V-118.8", style: "fill:none;stroke:var(--ink);stroke-width:1.5px" }, s);
    el("text", { x: -100, y: -122.6, class: "axis", style: "font-size:2.2px;fill:var(--ink)" }, s).textContent = "20 units";
    el("path", { d: "M-72,-117 L-70,-122.5 L-68,-117 L-70,-118.3 Z", style: "fill:var(--ink);stroke:none" }, s);
    el("text", { x: -70, y: -124.4, "text-anchor": "middle", class: "lbl", style: "font-size:2.4px" }, s).textContent = "N";
  }

  function drawShell(sh, root, cls) {
    const g = group(root, cls);
    el("polygon", { points: pstr(ptsOf(sh)), style: "fill:var(--mass);stroke:var(--edge);stroke-width:2px" }, g);
    reg(g, { name: sh.name, kind: "Walls and solid mass", lv: "G", size: sizeOf(sh) });
  }

  const ZONEKIND = { outdoor: "Outdoor", backdrop: "Seen, not reachable", indoor: "Room", pit: "Pit", room: "Basement room", deck: "Deck" };
  function drawZone(z, root, cls, drop) {
    const g = group(root, cls);
    const pts = pstr(ptsOf(z));
    const style = {
      outdoor: "fill:var(--outdoor);stroke:none",
      backdrop: "fill:url(#hatchBack);stroke:none",
      indoor: `fill:${z.lv === "C1" ? "var(--lv-C1)" : "var(--indoor)"};stroke:var(--edge);stroke-width:1.2px`,
      pit: `fill:${drop ? "url(#void)" : "var(--lv-B)"};stroke:none`,
      room: "fill:var(--lv-B);stroke:var(--edge);stroke-width:1.2px",
      deck: "fill:var(--lv-C2);stroke:var(--rail);stroke-width:1.2px",
    }[z.kind];
    el("polygon", { points: pts, style }, g);
    if (z.kind === "pit") {
      el("polygon", { points: pts, style: "fill:none;stroke:#1A1A17;stroke-width:4px" }, g);
      el("polygon", { points: pts, style: "fill:none;stroke:var(--hazard);stroke-width:4px;stroke-dasharray:7 7" }, g);
    }
    reg(g, { name: z.name, kind: ZONEKIND[z.kind], lv: z.lv, size: sizeOf(z), note: z.note });
  }

  function drawCorridor(c, root, cls) {
    const g = group(root, cls);
    const col = c.lv === "B" ? "var(--lv-B)" : c.lv === "C2" ? "var(--lv-C2)" : "var(--indoor)";
    const pts = pstr(c.pts);
    const base = "fill:none;stroke-linejoin:miter;stroke-linecap:butt;";
    el("polyline", { points: pts, class: "cor", style: `${base}stroke:var(--edge);stroke-width:${c.w + 0.6}px` }, g);
    el("polyline", { points: pts, class: "cor", style: `${base}stroke:${col};stroke-width:${c.w - 0.1}px` }, g);
    let len = 0;
    for (let i = 0; i < c.pts.length - 1; i++) len += Math.hypot(c.pts[i + 1][0] - c.pts[i][0], c.pts[i + 1][1] - c.pts[i][1]);
    reg(g, { name: c.name, kind: c.lv === "C2" ? "Enclosed bridge" : "Corridor", lv: c.lv, size: `${fmt(c.w)} wide, ${fmt(len)} long`, note: c.note });
  }

  function drawCatwalk(c, root, cls) {
    const g = group(root, cls);
    const [x0, z0, x1, z1] = c.rect;
    el("rect", { x: x0, y: z0, width: x1 - x0, height: z1 - z0, style: `fill:var(--lv-${c.lv});stroke:var(--rail);stroke-width:1px` }, g);
    reg(g, { name: c.name, kind: "Catwalk, railed", lv: c.lv, size: sizeOf(c), note: c.note });
  }

  function drawRamp(r, root, cls, i) {
    const lo = r.from[2] <= r.to[2] ? r.from : r.to, hi = lo === r.from ? r.to : r.from;
    const dx = hi[0] - lo[0], dz = hi[1] - lo[1], L = Math.hypot(dx, dz);
    const ux = dx / L, uz = dz / L, nx = -uz, nz = ux, hw = r.w / 2;
    const corners = [[lo[0] + nx * hw, lo[1] + nz * hw], [hi[0] + nx * hw, hi[1] + nz * hw], [hi[0] - nx * hw, hi[1] - nz * hw], [lo[0] - nx * hw, lo[1] - nz * hw]];
    const grad = el("linearGradient", { id: "ramp" + i, gradientUnits: "userSpaceOnUse", x1: lo[0], y1: lo[1], x2: hi[0], y2: hi[1] }, defs);
    el("stop", { offset: 0, style: `stop-color:var(--lv-${lvOf(lo[2])})` }, grad);
    el("stop", { offset: 1, style: `stop-color:var(--lv-${lvOf(hi[2])})` }, grad);
    const g = group(root, cls);
    el("polygon", { points: pstr(corners), style: `fill:url(#ramp${i});stroke:var(--edge);stroke-width:1px` }, g);
    let d = "";
    for (let s = 2; s < L - 0.8; s += 2.5) {
      const cx = lo[0] + ux * s, cz = lo[1] + uz * s, a = hw * 0.65, back = 0.9;
      d += `M${cx - ux * back + nx * a},${cz - uz * back + nz * a}L${cx},${cz}L${cx - ux * back - nx * a},${cz - uz * back - nz * a}`;
    }
    el("path", { d, style: "fill:none;stroke:var(--ink);stroke-width:1.3px;stroke-linejoin:round" }, g);
    const deg = Math.atan2(hi[2] - lo[2], L) * 180 / Math.PI;
    reg(g, { name: r.name, kind: "Stairs as a ramp, arrows point up", lv: `${LVNAME[lvOf(lo[2])]} to ${LVNAME[lvOf(hi[2])]}`, size: `${fmt(L)} run, ${fmt(hi[2] - lo[2])} rise, ${fmt(deg)}°, ${fmt(r.w)} wide` });
  }

  const BTYPE = { vehicle: "Vehicle", building: "Hut", furniture: "Furniture", rack: "Shelving", container: "Container", crates: "Crates and clutter", tank: "Tank", machine: "Machine" };
  function drawBlocker(bk, root, cls) {
    const g = group(root, cls);
    const tall = bk.h >= 1.8;
    const style = tall ? "fill:var(--blocker);stroke:var(--blocker);stroke-width:1px" : "fill:url(#hatchLow);stroke:var(--blocker-low);stroke-width:1.2px";
    let cx, cz, dim;
    if (bk.circle) {
      const [x, z, r] = bk.circle;
      el("circle", { cx: x, cy: z, r, style }, g);
      cx = x; cz = z; dim = r * 2;
    } else {
      const [x0, z0, x1, z1] = bk.rect;
      el("rect", { x: x0, y: z0, width: x1 - x0, height: z1 - z0, style }, g);
      cx = (x0 + x1) / 2; cz = (z0 + z1) / 2; dim = Math.min(x1 - x0, z1 - z0);
    }
    if (dim >= 1.9 && !(bk.rect && bk.rect[2] - bk.rect[0] < 3 && bk.rect[3] - bk.rect[1] < 3 && bk.type === "vehicle")) {
      el("text", { x: cx, y: cz, class: "fine", "text-anchor": "middle", "dominant-baseline": "central",
        style: `font-size:${Math.min(1.7, dim * 0.55)}px;font-family:var(--f-mono);pointer-events:none;fill:${tall ? "var(--blocker-text)" : "var(--ink)"}` }, g).textContent = fmt(bk.h);
    }
    reg(g, { name: bk.name, kind: BTYPE[bk.type] + (tall ? ", hides a standing enemy" : ", see over it"), lv: bk.lv, size: sizeOf(bk), h: bk.h, note: bk.note });
  }

  const DOOR = {
    open: { name: "Doorway" },
    kick: { name: "Kick door", style: "stroke:var(--kick);stroke-width:5px" },
    shutter: { name: "Shutter or locked gate, never kickable", style: "stroke:var(--shutter);stroke-width:5px;stroke-dasharray:3 2" },
    oneway: { name: "One way", style: "stroke:var(--ink);stroke-width:4px;stroke-dasharray:2 2" },
    timed: { name: "Opens when the machine blows", style: "stroke:var(--escape);stroke-width:5px" },
    exit: { name: "Level exit", style: "stroke:var(--route);stroke-width:5px" },
  };
  function drawDoor(d, root, cls) {
    const g = group(root, cls);
    const [x, z] = d.at, hw = d.w / 2;
    const [x1, z1, x2, z2] = d.axis === "h" ? [x - hw, z, x + hw, z] : [x, z - hw, x, z + hw];
    if (d.type === "open") {
      const t = 0.9;
      const path = d.axis === "h" ? `M${x1},${z - t}V${z + t}M${x2},${z - t}V${z + t}` : `M${x - t},${z1}H${x + t}M${x - t},${z2}H${x + t}`;
      el("path", { d: path, style: "fill:none;stroke:var(--ink);stroke-width:2px" }, g);
      el("line", { x1, y1: z1, x2, y2: z2, style: "stroke:transparent;stroke-width:10px" }, g);
    } else {
      el("line", { x1, y1: z1, x2, y2: z2, style: DOOR[d.type].style + ";stroke-linecap:butt" }, g);
    }
    reg(g, { name: d.name, kind: DOOR[d.type].name, lv: d.lv, size: fmt(d.w) + " wide", note: d.note });
  }

  function drawFence(f, root, cls) {
    const g = group(root, cls);
    el("polyline", { points: pstr(f.pts), style: "fill:none;stroke:var(--ink-2);stroke-width:1.5px;stroke-dasharray:6 3" }, g);
    el("polyline", { points: pstr(f.pts), style: "fill:none;stroke:transparent;stroke-width:9px" }, g);
    reg(g, { name: f.name, kind: "Chain-link fence, see through", lv: "G" });
  }

  function drawRoute(root) {
    const g = group(root);
    P.route.forEach((seg, si) => {
      const col = seg.escape ? "var(--escape)" : "var(--route)";
      for (let i = 0; i < seg.pts.length - 1; i++) {
        const a = seg.pts[i], b = seg.pts[i + 1];
        const lg = group(g, visSpan(lvOf(a[2]), lvOf(b[2])));
        el("line", { x1: a[0], y1: a[1], x2: b[0], y2: b[1], style: `stroke:${col};stroke-width:2.6px;stroke-linecap:round${seg.escape ? ";stroke-dasharray:9 5" : ""}` }, lg);
        const L = Math.hypot(b[0] - a[0], b[1] - a[1]);
        if (L > 8) {
          const ang = Math.atan2(b[1] - a[1], b[0] - a[0]) * 180 / Math.PI;
          el("path", { d: "M1.4,0L-1.1,1.1L-1.1,-1.1Z", transform: `translate(${(a[0] + b[0]) / 2},${(a[1] + b[1]) / 2}) rotate(${ang})`, style: `fill:${col};stroke:none` }, lg);
        }
      }
      const s = seg.pts[0];
      const bg = group(g, vis(lvOf(s[2])));
      el("circle", { cx: s[0], cy: s[1], r: 2.2, style: `fill:${col};stroke:var(--paper);stroke-width:1.5px` }, bg);
      el("text", { x: s[0], y: s[1] + 0.1, "text-anchor": "middle", "dominant-baseline": "central", style: "font-size:2.5px;font-family:var(--f-display);font-weight:700;fill:var(--paper);pointer-events:none" }, bg).textContent = si + 1;
      const st = segStats(seg);
      reg(bg, { name: `${si + 1}. ${seg.name}`, kind: "Route section starts here", lv: lvOf(s[2]), size: `${Math.round(st.len)} units, ${fmt(st.climb)} climbed` });
    });
  }

  // A short way against the stretch of golden path it replaces.
  const same = (a, b) => a[0] === b[0] && a[1] === b[1] && a[2] === b[2];
  function altStats(alt) {
    const path = [];
    P.route.forEach(s => s.pts.forEach(p => { if (!path.length || !same(path[path.length - 1], p)) path.push(p); }));
    const i = path.findIndex(p => same(p, alt.split)), j = path.findIndex(p => same(p, alt.join));
    const skipped = i >= 0 && j > i ? segStats({ pts: path.slice(i, j + 1) }).len : NaN;
    return { len: segStats(alt).len, skipped };
  }
  function drawAlt(root) {
    const g = group(root);
    P.alt.forEach(alt => {
      const st = altStats(alt);
      for (let i = 0; i < alt.pts.length - 1; i++) {
        const a = alt.pts[i], b = alt.pts[i + 1];
        const lg = group(g, visSpan(lvOf(a[2]), lvOf(b[2])));
        el("line", { x1: a[0], y1: a[1], x2: b[0], y2: b[1], style: "stroke:var(--ink);stroke-width:2.6px;stroke-linecap:round;stroke-dasharray:1 5" }, lg);
        el("line", { x1: a[0], y1: a[1], x2: b[0], y2: b[1], style: "stroke:transparent;stroke-width:9px" }, lg);
        const L = Math.hypot(b[0] - a[0], b[1] - a[1]);
        if (L > 12) {
          const ang = Math.atan2(b[1] - a[1], b[0] - a[0]) * 180 / Math.PI;
          el("path", { d: "M1.3,0L-1,1L-1,-1Z", transform: `translate(${(a[0] + b[0]) / 2},${(a[1] + b[1]) / 2}) rotate(${ang})`, style: "fill:var(--ink);stroke:none" }, lg);
        }
        reg(lg, { name: alt.name, kind: "Short way", lv: lvOf(a[2]), size: `${Math.round(st.len)} units instead of ${Math.round(st.skipped)} on the golden path` });
      }
    });
  }

  const PAY = { ammo: ["A", "Ammo"], health: ["+", "Health"], secret: ["S", "Secret"], enemy: ["E", "Enemy"] };
  function drawPayoff(p, root, cls) {
    const g = group(root, cls);
    const n = p.types.length;
    p.types.forEach((t, i) => {
      const x = p.at[0] + (i - (n - 1) / 2) * 3.9, z = p.at[1], sec = t === "secret";
      el("circle", { cx: x, cy: z, r: 1.8, style: `fill:${sec ? "var(--secret)" : "var(--panel)"};stroke:${sec ? "var(--secret)" : "var(--ink)"};stroke-width:1.5px` }, g);
      el("text", { x, y: z + 0.1, "text-anchor": "middle", "dominant-baseline": "central", style: `font-size:2.3px;font-family:var(--f-display);font-weight:700;pointer-events:none;fill:${sec ? "var(--panel)" : "var(--ink)"}` }, g).textContent = PAY[t][0];
    });
    reg(g, { name: p.where, kind: "Dead-end payoff: " + p.types.map(t => PAY[t][1].toLowerCase()).join(" and "), lv: p.lv });
  }

  function drawLabel(z, root, cls) {
    if (!z.label) return;
    const pts = ptsOf(z), xs = pts.map(p => p[0]), zs = pts.map(p => p[1]);
    const area = (Math.max(...xs) - Math.min(...xs)) * (Math.max(...zs) - Math.min(...zs));
    const size = area > 900 ? 3.2 : area > 250 ? 2.5 : 2;
    const g = group(root, cls);
    el("text", { x: z.label[0], y: z.label[1], class: "lbl", "text-anchor": "middle", "dominant-baseline": "central", style: `font-size:${size}px${z.kind === "backdrop" ? ";fill:var(--ink-2)" : ""}` }, g).textContent = z.name;
  }

  // The machine set piece and the weapon pickups. Points in the plan are [x, z, y].
  function drawSetPiece(root) {
    const sp = P.setpiece;
    const g = group(root);
    const badge = (x, z, text, fill, ink, parent, w) => {
      el("rect", { x: x - w / 2, y: z - 1.2, width: w, height: 2.4, rx: 0.4, style: `fill:${fill};stroke:var(--ink);stroke-width:1.2px` }, parent);
      el("text", { x, y: z + 0.1, "text-anchor": "middle", "dominant-baseline": "central", style: `font-size:1.8px;font-family:var(--f-display);font-weight:700;pointer-events:none;fill:${ink}` }, parent).textContent = text;
    };
    if (sp) {
      const [sx, sz, sy] = sp.start.at, [w, , d] = sp.start.size;
      const ag = group(g, vis(lvOf(sy)));
      el("rect", { x: sx - w / 2, y: sz - d / 2, width: w, height: d, style: "fill:none;stroke:var(--route);stroke-width:1.5px;stroke-dasharray:2 4" }, ag);
      reg(ag, { name: "Machine fight starts", kind: `Step in here and the way back is sealed; the first arm comes down ${sp.first_arm_seconds || 0} s later`, lv: lvOf(sy), size: `${w} × ${d}`, note: sp.start.note });
      const [ex, ez, ey] = sp.seal.at;
      const seal = group(g, vis(lvOf(ey)));
      el("rect", { x: ex - sp.seal.radius, y: ez - sp.seal.length / 2, width: sp.seal.radius * 2, height: sp.seal.length, rx: 1, style: "fill:var(--shutter);stroke:var(--ink);stroke-width:1.2px" }, seal);
      reg(seal, { name: "Falling pipe", kind: "Lands across the tunnel door when the fight starts", lv: lvOf(ey) });
      const [xx, xz, xy] = sp.exit.at;
      const shut = group(g, vis(lvOf(xy)));
      el("line", { x1: xx - sp.exit.size[0] / 2, y1: xz, x2: xx + sp.exit.size[0] / 2, y2: xz, style: "stroke:#D8342A;stroke-width:6px" }, shut);
      reg(shut, { name: "High exit shutter", kind: sp.button ? "Red until the button is kicked, then it lifts" : "Red until the last coolant pipe breaks, then it lifts", lv: lvOf(xy) });
      const waves = sp.waves.map(([f, h, r, b], i) => `${i + 1}: ${f}F ${h}H ${r}R${b ? " " + b + "B" : ""}`).join(" · ");
      const hatch = (at, ranged) => {
        const hg = group(g, vis(lvOf(at[2])));
        el("rect", { x: at[0] - 0.9, y: at[1] - 0.9, width: 1.8, height: 1.8, style: `fill:var(--blocker);stroke:${ranged ? "var(--escape)" : "#D8342A"};stroke-width:1.5px` }, hg);
        reg(hg, { name: ranged ? "Hunter hatch" : "Melee hatch", kind: ranged ? "Hunters climb out here, any level" : "Fodder, Rammers and brutes, used when the player is on this level", lv: lvOf(at[2]), note: "Waves: " + waves });
      };
      sp.melee_hatches.forEach(at => hatch(at, false));
      (sp.ranged_hatches || []).forEach(at => hatch(at, true));
      // The end zone sits in front of the exit gate, as bake.js builds it.
      const pad = group(g, vis("G"));
      const end = P.route[P.route.length - 1].pts.slice(-1)[0];
      const gate = P.doors.find(dr => dr.type === "exit");
      let zone = { x: end[0] - 2, z: end[1] - 6, w: 8, d: 12 };
      if (gate) {
        const across = gate.axis === "h";
        const side = Math.sign(across ? end[1] - gate.at[1] : end[0] - gate.at[0]) || 1;
        const cx = across ? gate.at[0] : gate.at[0] + side * 5, cz = across ? gate.at[1] + side * 5 : gate.at[1];
        const zw = across ? gate.w : 8, zd = across ? 8 : gate.w;
        zone = { x: cx - zw / 2, z: cz - zd / 2, w: zw, d: zd };
      }
      el("rect", { x: zone.x, y: zone.z, width: zone.w, height: zone.d, style: "fill:rgba(64,220,110,.35);stroke:#2FB35A;stroke-width:2px" }, pad);
      reg(pad, { name: "End zone", kind: "Lights up when the machine goes critical; ends the run on arrival", lv: "G", size: `${zone.w} × ${zone.d}` });
      // Pressure arms: shoulder on the machine's roof edge, elbow, pipe plugged into a pit floor
      // socket. A dashed line joins the sockets in the order the arms come down.
      const arms = sp.arms || [], order = sp.order || [];
      const armAt = n => arms.find(a => a.n === n);
      if (order.length > 1) {
        const og = group(g, vis("B"));
        const pts = order.map(armAt).filter(Boolean).map(a => a.socket);
        el("polyline", { points: pts.map(q => q[0] + "," + q[1]).join(" "), style: "fill:none;stroke:var(--hazard);stroke-width:1.6px;stroke-dasharray:3 3;opacity:.9" }, og);
        for (let i = 0; i < pts.length - 1; i++) {
          const [a, b] = [pts[i], pts[i + 1]], mx = (a[0] + b[0]) / 2, mz = (a[1] + b[1]) / 2, ang = Math.atan2(b[1] - a[1], b[0] - a[0]);
          const tip = (dx, dz) => (mx + Math.cos(ang) * dx - Math.sin(ang) * dz) + "," + (mz + Math.sin(ang) * dx + Math.cos(ang) * dz);
          el("polygon", { points: [tip(1, 0), tip(-0.6, 0.7), tip(-0.6, -0.7)].join(" "), style: "fill:var(--hazard);stroke:var(--ink);stroke-width:.8px" }, og);
        }
        reg(og, { name: "Arm order", kind: "Arms come down " + order.join(", ") + ", so the fight moves round the machine", lv: "B" });
      }
      const nth = k => k + ({ 1: "st", 2: "nd", 3: "rd" }[k] || "th");
      arms.forEach(a => {
        const k = order.indexOf(a.n) + 1;
        const ag2 = group(g, visSpan("B", "C2"));
        el("polyline", { points: [a.shoulder, a.elbow, a.socket].map(q => q[0] + "," + q[1]).join(" "), style: "fill:none;stroke:var(--ink);stroke-width:5px;stroke-linecap:round;stroke-linejoin:round" }, ag2);
        el("polyline", { points: [a.shoulder, a.elbow, a.socket].map(q => q[0] + "," + q[1]).join(" "), style: "fill:none;stroke:var(--hazard);stroke-width:2.5px;stroke-linecap:round;stroke-linejoin:round" }, ag2);
        el("circle", { cx: a.elbow[0], cy: a.elbow[1], r: 0.7, style: "fill:#D8342A;stroke:var(--ink);stroke-width:1px" }, ag2);
        badge(a.socket[0], a.socket[1], k ? `${a.n} · ${nth(k)}` : "A" + a.n, "var(--hazard)", "#1A1A17", ag2, 6.4);
        const wave = sp.waves[k - 1];
        const then = k && k < order.length && wave ? `, then wave ${k} climbs out: ${wave[0]} fodder, ${wave[2]} Rammers${wave[3] ? ", " + wave[3] + " brute" + (wave[3] > 1 ? "s" : "") : ""}` : k === order.length ? ", then the Commander sends you up to the button" : "";
        reg(ag2, { name: `Arm ${a.n}, down ${k ? nth(k) : "?"}`, kind: `Plugs its pipe into the pit floor. 3 kicks or 10 pistol hits break it${then}`, lv: "B", note: `${a.where}. Red dot: its beacon, up on the elbow at +${a.elbow[2]}, spins with the alarm for ${sp.warning_seconds || 0} s before it drops. Pressure forces the next arm down after ${sp.pressure_seconds} s` });
      });
      (sp.irons || []).forEach(iron => {
        const ig = group(g, visSpan("C1", "C2"));
        el("line", { x1: iron.from[0], y1: iron.from[1], x2: iron.to[0], y2: iron.to[1], style: "stroke:var(--ink);stroke-width:3px;stroke-linecap:round" }, ig);
        reg(ig, { name: "Iron strut", kind: `Cauldron to ceiling, +${iron.from[2]} to +${iron.to[2]}. Visual only`, lv: "C2" });
      });
      if (sp.button) {
        const bg = group(g, vis(lvOf(sp.button.at[2])));
        badge(sp.button.at[0], sp.button.at[1] - 1.8, sp.button.sign || "BUTTON", "#D8342A", "#FFF", bg, 8.6);
        el("circle", { cx: sp.button.at[0], cy: sp.button.at[1], r: 0.8, style: "fill:#D8342A;stroke:var(--ink);stroke-width:1.2px" }, bg);
        reg(bg, { name: "Button: " + (sp.button.sign || "button"), kind: "Kick it after the sixth pipe: the machine goes critical and the escape countdown starts (" + sp.escape_seconds + " s)", lv: lvOf(sp.button.at[2]), note: sp.button.where + (sp.line_last_pipe ? '. "' + sp.line_last_pipe + '"' : "") });
      }
      (sp.pipes || []).forEach((p, i) => {
        const pg = group(g, vis(lvOf(p.at[2])));
        badge(p.at[0], p.at[1], "P" + (i + 1), "var(--hazard)", "#1A1A17", pg, 3.4);
        reg(pg, { name: `Coolant pipe ${i + 1}`, kind: "3 kicks or 10 pistol hits" + (i < sp.pipes.length - 1 ? `, sends wave ${i + 2}` : ", sends the machine critical"), lv: lvOf(p.at[2]), note: p.where });
      });
    }
    // Compressor pumps: the ram over each housing.
    (P.pumps || []).forEach((p, i) => {
      const pg = group(g, vis(lvOf(p.at[2])));
      el("circle", { cx: p.at[0], cy: p.at[1], r: 1.3, style: "fill:none;stroke:var(--hazard);stroke-width:1.2px" }, pg);
      el("circle", { cx: p.at[0], cy: p.at[1], r: 0.5, style: "fill:var(--hazard);stroke:var(--ink);stroke-width:.8px" }, pg);
      reg(pg, { name: `Compressor pump ${i + 1}`, kind: `Its ram drives down, hisses steam and creeps back up, every ${p.period} s. Visual only`, lv: lvOf(p.at[2]) });
    });
    (P.secrets || []).forEach(sc => {
      const sg = group(g, vis(lvOf(sc.at[2])));
      el("polyline", { points: sc.path.map(p => p[0] + "," + p[1]).join(" "), style: "fill:none;stroke:var(--secret);stroke-width:1.5px;stroke-dasharray:1 3;stroke-linecap:round" }, sg);
      el("circle", { cx: sc.at[0], cy: sc.at[1], r: 1.8, style: "fill:var(--secret);stroke:var(--secret);stroke-width:1.5px" }, sg);
      el("text", { x: sc.at[0], y: sc.at[1] + 0.1, "text-anchor": "middle", "dominant-baseline": "central", style: "font-size:2.3px;font-family:var(--f-display);font-weight:700;fill:var(--panel);pointer-events:none" }, sg).textContent = "S";
      reg(sg, { name: "Secret: " + sc.name, kind: `Reward: ${sc.reward}. Never signposted; the dotted line is the way in`, lv: lvOf(sc.at[2]) });
    });
    if (sp && sp.escape_events) sp.escape_events.forEach(ev => {
      const eg = group(g, vis(lvOf(ev.at[2])));
      if (ev.trigger) el("circle", { cx: ev.trigger[0], cy: ev.trigger[1], r: ev.radius, style: "fill:none;stroke:#E0702A;stroke-width:1px;stroke-dasharray:2 3" }, eg);
      if (ev.kind === "fall") {
        const [sx, , sz] = ev.size;
        el("rect", { x: ev.at[0] - sx / 2, y: ev.at[1] - sz / 2, width: sx, height: sz, style: "fill:rgba(224,112,42,.55);stroke:#E0702A;stroke-width:1.5px" }, eg);
      } else {
        el("circle", { cx: ev.at[0], cy: ev.at[1], r: 1.2, style: "fill:rgba(255,255,255,.7);stroke:#E0702A;stroke-width:1.5px" }, eg);
      }
      reg(eg, { name: ev.kind === "fall" ? "Escape: debris falls" : "Escape: steam burst", kind: ev.trigger ? "When the player comes within the dashed circle" : `${ev.delay} s after the machine goes critical`, lv: lvOf(ev.at[2]), note: ev.where });
    });
    if (sp && sp.outside) {
      const [ox, oz, oy] = sp.outside.at, [ow, , od] = sp.outside.size;
      const og = group(g, vis(lvOf(oy)));
      el("rect", { x: ox - ow / 2, y: oz - od / 2, width: ow, height: od, style: "fill:none;stroke:#2FB35A;stroke-width:1.5px;stroke-dasharray:6 4" }, og);
      reg(og, { name: "Out of the building", kind: "Step in here and the escape countdown stops; the factory blows up behind you", lv: lvOf(oy) });
    }
    if (sp && sp.finale) sp.finale.forEach(f => {
      const fg = group(g, "");
      el("circle", { cx: f.at[0], cy: f.at[1], r: f.kind === "boom" ? Math.max(1.5, f.size / 3) : 1.4, style: f.kind === "boom" ? "fill:rgba(255,140,40,.55);stroke:#E0702A;stroke-width:1.5px" : "fill:rgba(80,80,80,.45);stroke:var(--ink-2);stroke-width:1.2px" }, fg);
      reg(fg, { name: f.kind === "boom" ? "Finale: boom" : "Finale: smoke column", kind: `${f.delay} s after getting out`, lv: lvOf(f.at[2]), note: f.where });
    });
    (P.ambushes || []).forEach(a => {
      const [tx, tz, ty] = a.trigger.at, [w, , d] = a.trigger.size;
      const ag = group(g, vis(lvOf(ty)));
      el("rect", { x: tx - w / 2, y: tz - d / 2, width: w, height: d, style: "fill:rgba(216,52,42,.12);stroke:#D8342A;stroke-width:1.5px;stroke-dasharray:4 3" }, ag);
      el("line", { x1: tx, y1: tz, x2: a.spawn[0], y2: a.spawn[1], style: "stroke:#D8342A;stroke-width:1px;stroke-dasharray:2 3" }, ag);
      badge(a.spawn[0], a.spawn[1], "×" + a.count, "#D8342A", "#FFF", ag, 3);
      reg(ag, { name: "Ambush: " + a.name, kind: `Step in the dashed box and ${a.count} ${a.kind === "rammer" ? (a.count === 1 ? "Rammer climbs" : "Rammers climb") : a.kind === "hunter" ? "Hunters climb" : a.kind === "brute" ? (a.count === 1 ? "brute climbs" : "brutes climb") : "fodder climb"} out`, lv: lvOf(ty) });
    });
    (P.johns || []).forEach(p => {
      const jg = group(g, vis(lvOf(p.at[2])));
      el("circle", { cx: p.at[0], cy: p.at[1], r: 0.9, style: "fill:#CFA972;stroke:var(--ink);stroke-width:1px" }, jg);
      reg(jg, { name: "Cutout John", kind: "Kick or shoot it flat, a bonus on top of completion", lv: lvOf(p.at[2]), note: p.where });
    });
    (P.signs || []).forEach(p => {
      const sg = group(g, vis(lvOf(p.at[2])));
      const along = p.face === "s" || p.face === "n";
      el("rect", { x: p.at[0] - (along ? p.width / 2 : 0.25), y: p.at[1] - (along ? 0.25 : p.width / 2), width: along ? p.width : 0.5, height: along ? 0.5 : p.width, style: "fill:var(--panel);stroke:var(--ink-2);stroke-width:1px" }, sg);
      reg(sg, { name: `"${p.text}"`, kind: "Sign, " + p.style, lv: lvOf(p.at[2]), size: `${p.width} wide` });
    });
    (P.enemies || []).forEach(e => {
      const eg = group(g, vis(lvOf(e.at[2])));
      badge(e.at[0], e.at[1], e.kind[0].toUpperCase(), "#D8342A", "#FFF", eg, 2.6);
      reg(eg, { name: e.kind[0].toUpperCase() + e.kind.slice(1), kind: "Placed enemy", lv: lvOf(e.at[2]), note: e.where });
    });
    (P.pickups || []).forEach(p => {
      if (p.kind !== "gun" && p.kind !== "shotgun") return;
      const wg = group(g, vis(lvOf(p.at[2])));
      badge(p.at[0], p.at[1], p.kind === "gun" ? "PISTOL" : "SHOTGUN", "var(--panel)", "var(--ink)", wg, p.kind === "gun" ? 7 : 8.4);
      reg(wg, { name: p.kind === "gun" ? "Pistol" : "Shotgun", kind: "Weapon pickup, provisional", lv: lvOf(p.at[2]), note: p.where });
    });
  }

  // What the outline bake will build: walls, rails, fences and shut doors, from bake.js.
  let built = null;
  const BUILT = { wall: "var(--ink)", rail: "var(--rail)", fence: "var(--ink-2)", panel: "var(--shutter)" };
  function drawBuilt(root) {
    built = built || window.bakePlan(P);
    const g = group(root);
    for (const b of built.boxes) {
      if (!BUILT[b.kind]) continue;
      const y0 = b.c[1] - b.s[1] / 2, y1 = b.c[1] + b.s[1] / 2;
      const lg = group(g, visSpan(lvOf(y0 + 0.4), lvOf(Math.max(y0 + 0.4, y1 - 0.6))));
      el("rect", { x: b.c[0] - b.s[0] / 2, y: b.c[2] - b.s[2] / 2, width: b.s[0], height: b.s[2], style: `fill:${BUILT[b.kind]};stroke:none` }, lg);
      reg(lg, { name: "Built " + b.kind, kind: `${fmt(y0)} to ${fmt(y1)} high`, lv: lvOf(y0 + 0.4), size: `${fmt(Math.max(b.s[0], b.s[2]))} long, ${b.m}` });
    }
  }

  function render() {
    INFO = [];
    svg.textContent = "";
    defs = el("defs", {}, svg);
    patterns();
    const root = group(svg);
    const Z = P.zones, B = state.layers.blockers ? P.blockers : [];
    const lateBlocker = b => LVY[b.lv] + b.h > 8;
    drawGrid(root);
    Z.filter(z => z.kind === "outdoor" || z.kind === "backdrop").forEach(z => drawZone(z, root, vis("G")));
    P.fences.forEach(f => drawFence(f, root, vis("G")));
    P.shells.forEach(s => drawShell(s, root, vis("G")));
    P.corridors.filter(c => c.lv === "G").forEach(c => drawCorridor(c, root, vis("G")));
    Z.filter(z => z.kind === "indoor" && z.lv === "G").forEach(z => drawZone(z, root, vis("G")));
    Z.filter(z => z.kind === "pit").forEach(z => drawZone(z, root, state.focus === "G" ? "" : vis("B"), state.focus === "G"));
    B.filter(b => b.lv === "G" && !lateBlocker(b)).forEach(b => drawBlocker(b, root, vis("G")));
    P.corridors.filter(c => c.lv === "B").forEach(c => drawCorridor(c, root, vis("B", "xray")));
    Z.filter(z => z.kind === "room").forEach(z => drawZone(z, root, vis("B", "xray")));
    B.filter(b => b.lv === "B" && !lateBlocker(b)).forEach(b => drawBlocker(b, root, vis("B")));
    P.ramps.forEach((r, i) => drawRamp(r, root, visSpan(lvOf(r.from[2]), lvOf(r.to[2])), i));
    Z.filter(z => z.lv === "C1").forEach(z => drawZone(z, root, vis("C1")));
    P.catwalks.filter(c => c.lv === "C1").forEach(c => drawCatwalk(c, root, vis("C1")));
    P.corridors.filter(c => c.lv === "C2").forEach(c => drawCorridor(c, root, vis("C2")));
    Z.filter(z => z.lv === "C2").forEach(z => drawZone(z, root, vis("C2")));
    P.catwalks.filter(c => c.lv === "C2").forEach(c => drawCatwalk(c, root, vis("C2")));
    B.filter(lateBlocker).forEach(b => drawBlocker(b, root, visSpan(b.lv, "C2")));
    P.doors.forEach(d => drawDoor(d, root, vis(d.lv)));
    if (state.layers.route) { drawAlt(root); drawRoute(root); }
    if (state.layers.payoffs) P.payoffs.forEach(p => drawPayoff(p, root, vis(p.lv)));
    if (state.layers.setpiece) drawSetPiece(root);
    if (state.layers.walls && window.bakePlan) drawBuilt(root);
    if (state.layers.labels) {
      Z.forEach(z => drawLabel(z, root, vis(z.lv)));
      const start = P.route[0].pts[0];
      el("text", { x: start[0], y: start[1] + 2.6, class: "lbl", "text-anchor": "middle", style: "font-size:2px" }, group(root, vis("G"))).textContent = "Start";
    }
    applyView();
  }

  // Pan and zoom.
  let view = null;
  const bounds = () => svg.getBoundingClientRect();
  function fit() {
    const r = bounds();
    if (!r.width || !r.height) return;
    const a = r.width / r.height;
    let [x, y, w, h] = P.bounds;
    if (w / h > a) { const nh = w / a; y -= (nh - h) / 2; h = nh; } else { const nw = h * a; x -= (nw - w) / 2; w = nw; }
    view = { x, y, w, h };
    applyView();
  }
  function applyView() {
    if (!view) return;
    svg.setAttribute("viewBox", `${view.x} ${view.y} ${view.w} ${view.h}`);
    svg.classList.toggle("zoomed", bounds().width / view.w >= 7);
  }
  function zoomAt(cx, cz, f) {
    const w = Math.min(Math.max(view.w * f, 14), P.bounds[2] * 2.5), k = w / view.w;
    view = { x: cx - (cx - view.x) * k, y: cz - (cz - view.y) * k, w: view.w * k, h: view.h * k };
    applyView();
  }
  const toWorld = (cx, cy) => {
    const r = bounds();
    return { x: view.x + (cx - r.left) / r.width * view.w, z: view.y + (cy - r.top) / r.height * view.h };
  };
  svg.addEventListener("wheel", e => {
    e.preventDefault();
    const p = toWorld(e.clientX, e.clientY);
    zoomAt(p.x, p.z, e.deltaY > 0 ? 1.15 : 1 / 1.15);
  }, { passive: false });

  const pointers = new Map();
  let drag = null, pinch = null;
  svg.addEventListener("pointerdown", e => {
    pointers.set(e.pointerId, { x: e.clientX, y: e.clientY });
    svg.setPointerCapture(e.pointerId);
    if (pointers.size === 1) drag = { sx: e.clientX, sy: e.clientY, vx: view.x, vy: view.y, moved: false, target: e.target };
    if (pointers.size === 2) {
      const [a, b] = [...pointers.values()];
      pinch = { d: Math.hypot(a.x - b.x, a.y - b.y), w: view.w };
      drag = null;
    }
  });
  svg.addEventListener("pointermove", e => {
    if (pointers.has(e.pointerId)) pointers.set(e.pointerId, { x: e.clientX, y: e.clientY });
    const r = bounds();
    if (pinch && pointers.size === 2) {
      const [a, b] = [...pointers.values()];
      const mid = toWorld((a.x + b.x) / 2, (a.y + b.y) / 2);
      zoomAt(mid.x, mid.z, (pinch.w * pinch.d / Math.hypot(a.x - b.x, a.y - b.y)) / view.w);
      return;
    }
    if (drag) {
      const dx = e.clientX - drag.sx, dy = e.clientY - drag.sy;
      if (Math.abs(dx) + Math.abs(dy) > 4) { drag.moved = true; svg.classList.add("dragging"); }
      if (drag.moved) { view.x = drag.vx - dx / r.width * view.w; view.y = drag.vy - dy / r.height * view.h; applyView(); }
    }
    const p = toWorld(e.clientX, e.clientY);
    document.getElementById("xy").textContent = `x ${fmt(p.x)}   z ${fmt(p.z)}`;
    if (!drag || !drag.moved) showInfo(e.target);
  });
  const endPointer = e => {
    pointers.delete(e.pointerId);
    if (pointers.size < 2) pinch = null;
    if (drag && !drag.moved && e.type === "pointerup") showInfo(drag.target);
    if (pointers.size === 0) { drag = null; svg.classList.remove("dragging"); }
  };
  svg.addEventListener("pointerup", endPointer);
  svg.addEventListener("pointercancel", endPointer);

  function showInfo(target) {
    const box = document.getElementById("what");
    const hit = target && target.closest && target.closest("[data-i]");
    box.textContent = "";
    if (!hit) return;
    const info = INFO[+hit.getAttribute("data-i")];
    const b = document.createElement("b");
    b.textContent = info.name;
    const meta = [info.kind, LVNAME[info.lv] || info.lv, info.size, info.h != null ? fmt(info.h) + " tall" : null].filter(Boolean).join(" · ");
    const em = document.createElement("em");
    em.textContent = " " + meta;
    box.append(b, em);
    if (info.note) box.append(" — " + info.note);
  }

  // Controls.
  const levels = document.getElementById("levels");
  [["all", "All storeys", null], ...LV.map(k => [k, LVNAME[k], `var(--lv-${k})`])].forEach(([k, label, chip]) => {
    const btn = document.createElement("button");
    btn.type = "button";
    btn.id = "lv-" + k;
    btn.setAttribute("aria-pressed", String(state.focus === k));
    if (chip) { const i = document.createElement("i"); i.style.background = chip; btn.append(i); }
    btn.append(label);
    btn.addEventListener("click", () => {
      state.focus = k;
      levels.querySelectorAll("button").forEach(x => x.setAttribute("aria-pressed", String(x === btn)));
      save(); render();
    });
    levels.append(btn);
  });
  const toggles = document.getElementById("toggles");
  [["route", "Route"], ["blockers", "Blockers"], ["payoffs", "Payoffs"], ["labels", "Labels"], ["setpiece", "Encounters"], ["walls", "Built walls"]].forEach(([k, label]) => {
    const lab = document.createElement("label");
    const input = document.createElement("input");
    input.type = "checkbox"; input.id = "layer-" + k; input.checked = state.layers[k];
    input.addEventListener("change", () => { state.layers[k] = input.checked; save(); render(); });
    lab.append(input, label);
    toggles.append(lab);
  });
  const centre = () => ({ x: view.x + view.w / 2, z: view.y + view.h / 2 });
  document.getElementById("zin").addEventListener("click", () => { const c = centre(); zoomAt(c.x, c.z, 1 / 1.4); });
  document.getElementById("zout").addEventListener("click", () => { const c = centre(); zoomAt(c.x, c.z, 1.4); });
  document.getElementById("zfit").addEventListener("click", fit);
  new ResizeObserver(() => {
    const r = bounds();
    if (!r.width || !r.height) return;
    if (!view) { fit(); return; }
    const c = centre();
    view.h = view.w * r.height / r.width;
    view.y = c.z - view.h / 2;
    applyView();
  }).observe(svg);

  // Side panel.
  const legend = document.getElementById("legend");
  const sw = inner => `<svg width="34" height="18" viewBox="0 0 34 18" aria-hidden="true">${inner}</svg>`;
  const box = style => sw(`<rect x="1" y="2" width="32" height="14" rx="1" style="${style}"/>`);
  const line = style => sw(`<line x1="2" y1="9" x2="32" y2="9" style="${style}"/>`);
  const badge = (ch, sec) => `<svg width="18" height="18" viewBox="0 0 18 18" aria-hidden="true"><circle cx="9" cy="9" r="7.5" style="fill:${sec ? "var(--secret)" : "var(--panel)"};stroke:${sec ? "var(--secret)" : "var(--ink)"};stroke-width:1.5"/><text x="9" y="9.6" text-anchor="middle" dominant-baseline="central" style="font:700 11px var(--f-display);fill:${sec ? "var(--panel)" : "var(--ink)"}">${ch}</text></svg>`;
  const items = [
    [box("fill:var(--outdoor)"), "Outdoor ground"],
    [box("fill:var(--indoor);stroke:var(--edge)"), "Indoor floor"],
    [box("fill:var(--mass);stroke:var(--edge)"), "Walls and solid mass"],
    [box("fill:url(#hatchBack)"), "Seen, not reachable"],
    [box("fill:var(--lv-B);stroke:var(--hazard);stroke-width:3;stroke-dasharray:4 4"), "Pit or basement, −4"],
    [box("fill:var(--lv-C1);stroke:var(--rail)"), "Catwalk +4"],
    [box("fill:var(--lv-C2);stroke:var(--rail)"), "Catwalk +8"],
    [sw(`<defs><linearGradient id="lgR"><stop offset="0" style="stop-color:var(--lv-G)"/><stop offset="1" style="stop-color:var(--lv-C1)"/></linearGradient></defs><rect x="1" y="3" width="32" height="12" style="fill:url(#lgR);stroke:var(--edge)"/><path d="M10 5L14 9L10 13M18 5L22 9L18 13" style="fill:none;stroke:var(--ink);stroke-width:1.4"/>`), "Stairs, arrows point up"],
    [box("fill:var(--blocker)"), "Blocker, hides an enemy"],
    [box("fill:url(#hatchLow);stroke:var(--blocker-low)"), "Blocker under 1.8"],
    [line("stroke:var(--route);stroke-width:3"), "Golden path"],
    [line("stroke:var(--escape);stroke-width:3;stroke-dasharray:7 4"), "Timed escape"],
    [line("stroke:var(--kick);stroke-width:5"), "Kick door"],
    [line("stroke:var(--shutter);stroke-width:5;stroke-dasharray:3 2"), "Shutter, never kickable"],
    [line("stroke:var(--ink);stroke-width:4;stroke-dasharray:2 2"), "One way"],
    [line("stroke:var(--ink-2);stroke-width:1.5;stroke-dasharray:6 3"), "Fence, see through"],
    [badge("A") + badge("+") + badge("E"), "Ammo, health, enemy"],
    [badge("S", true), "Secret"],
    [line("stroke:var(--ink);stroke-width:3;stroke-linecap:round;stroke-dasharray:1 5"), "Short way"],
    [sw(`<polyline points="3,4 14,6 30,14" style="fill:none;stroke:var(--ink);stroke-width:5;stroke-linecap:round"/><polyline points="3,4 14,6 30,14" style="fill:none;stroke:var(--hazard);stroke-width:2.5;stroke-linecap:round"/>`), "Pressure arm to its socket"],
    [line("stroke:var(--hazard);stroke-width:2;stroke-dasharray:3 3"), "Order the arms come down"],
  ];
  legend.innerHTML = items.map(([s, t]) => `<div>${s}<span>${t}</span></div>`).join("");

  const stats = P.route.map(s => ({ name: s.name, escape: !!s.escape, ...segStats(s) }));
  const total = stats.reduce((a, s) => a + s.len, 0);
  const escape = stats.filter(s => s.escape).reduce((a, s) => a + s.len, 0);
  const walk = total / P.rate;
  const maxLen = Math.max(...stats.map(s => s.len));
  document.getElementById("budget").innerHTML =
    `<thead><tr><th>Section</th><th class="n">Units</th><th class="n">Walk</th></tr></thead><tbody>` +
    stats.map((s, i) => `<tr class="${s.escape ? "esc" : ""}"><td><span class="seq">${i + 1}</span>${s.name}<div class="bar" style="width:${(s.len / maxLen * 100).toFixed(1)}%"></div></td><td class="n">${Math.round(s.len)}</td><td class="n">${clock(s.len / P.rate)}</td></tr>`).join("") +
    `<tr class="total"><td>Total</td><td class="n">${Math.round(total)}</td><td class="n">${clock(walk)}</td></tr></tbody>`;
  document.getElementById("budgetNote").textContent =
    `Target is ${P.target.toLocaleString()} units. Walk times use ${P.rate} units a second from the old 1,200 in 3:25, and ignore stairs. The escape is ${Math.round(escape)} units, about ${Math.round(escape / P.rate)} seconds, so a 90 second timer still fits.` +
    P.alt.map(a => { const s = altStats(a); return ` ${a.name.replace(/^Short way: /, "The short way through the ")} is ${Math.round(s.len)} units where the golden path takes ${Math.round(s.skipped)}, saving about ${clock((s.skipped - s.len) / P.rate)}.`; }).join("");

  const payoffs = P.payoffs.length, secrets = (P.secrets || []).length;
  document.getElementById("stats").innerHTML = [
    [Math.round(total).toLocaleString(), "Golden path units"],
    [clock(walk), "Estimated walk"],
    ["~" + clock(Math.round(walk * 3 / 30) * 30), "Par at 3x walk"],
    [String(P.route.length), "Route sections"],
    [String(payoffs), "Dead ends that pay"],
    [String(secrets), "Secrets"],
    ...P.alt.map(a => { const s = altStats(a); return ["−" + clock((s.skipped - s.len) / P.rate), "Short way saves"]; }),
  ].map(([v, l]) => `<div class="stat"><b>${v}</b><span>${l}</span></div>`).join("");

  document.getElementById("spaces").innerHTML = P.spaces.map(s =>
    `<div class="space"><h3>${s.name} <small>${s.size}</small> <span class="pill">${s.scale}</span></h3><p>${s.text}</p></div>`).join("");
  document.getElementById("decisions").innerHTML = P.decisions.map(q => `<li>${q}</li>`).join("");
  document.getElementById("questions").innerHTML = P.questions.map(q => `<li>${q}</li>`).join("");

  render();
  requestAnimationFrame(fit);
})();
