// Turns the plan into outline build pieces: floors, walls, rails, roofs, ramps,
// lights, beat lines, the spawn and the exit. Shared by the plan page, which draws
// the walls it will build, and export.js, which writes plan.json for
// tools/build_factory.gd.
//
// Method: each storey is rasterised at CELL units. Every cell edge between two
// different spaces, or between a space and nothing, gets a barrier chosen by the
// kinds on either side. Barriers on the same edge from different storeys are
// unioned by height, doors cut openings out of them, and runs of identical edges
// merge into boxes.
(function (root) {
  const CELL = 0.25;
  const LV = ["B", "G", "C1", "C2"];
  const LVY = { B: -4, G: 0, C1: 4, C2: 8 };
  const ROOM_CLEAR = 3.5;   // walls and roofs of rooms built on a catwalk storey
  const BOUNDARY_H = 4;     // compound wall where outdoor ground meets nothing
  const FENCE_H = 1.3;      // above jump height, low enough to see over
  const RAIL_H = 1.1;
  const DOOR_H = 3.2;
  const WALL_T = 0.4;
  const RAIL_T = 0.12;
  const TILE = 12;
  const lvOf = y => (y <= -2 ? "B" : y >= 6 ? "C2" : y >= 2 ? "C1" : "G");
  const OPEN_DOORS = { open: true, kick: true, oneway: true, timed: true };

  function bake(P) {
    const [bx, bz, bw, bh] = P.bounds;
    const nx = Math.round(bw / CELL), nz = Math.round(bh / CELL);
    const X = x => Math.round((x - bx) / CELL), Z = z => Math.round((z - bz) / CELL);
    const wx = c => bx + c * CELL, wz = c => bz + c * CELL;
    const inside = (pts, x, z) => {
      let hit = false;
      for (let i = 0, j = pts.length - 1; i < pts.length; j = i++) {
        const [xi, zi] = pts[i], [xj, zj] = pts[j];
        if ((zi > z) !== (zj > z) && x < (xj - xi) * (z - zi) / (zj - zi) + xi) hit = !hit;
      }
      return hit;
    };
    const rectPts = r => [[r[0], r[1]], [r[2], r[1]], [r[2], r[3]], [r[0], r[3]]];
    const shellAt = (x, z) => P.shells.find(s => x >= s.rect[0] && x <= s.rect[2] && z >= s.rect[1] && z <= s.rect[3]);

    // Spaces, and a raster of space index per storey.
    const spaces = [];
    const grid = {};
    LV.forEach(lv => { grid[lv] = new Int32Array(nx * nz).fill(-1); });
    const parent = [];
    const find = i => (parent[i] === i ? i : (parent[i] = find(parent[i])));
    const addSpace = s => { s.index = spaces.length; parent.push(s.index); spaces.push(s); return s; };
    const paintRect = (lv, r, s, onlyEmpty) => {
      const g = grid[lv];
      for (let cz = Z(Math.min(r[1], r[3])); cz < Z(Math.max(r[1], r[3])); cz++)
        for (let cx = X(Math.min(r[0], r[2])); cx < X(Math.max(r[0], r[2])); cx++) {
          if (cx < 0 || cz < 0 || cx >= nx || cz >= nz) continue;
          const i = cx + cz * nx;
          if (onlyEmpty && g[i] >= 0) continue;
          if (g[i] >= 0 && s.merge && spaces[g[i]].merge === s.merge) parent[find(g[i])] = find(s.index);
          g[i] = s.index;
        }
    };
    const paintPoly = (lv, pts, s) => {
      const g = grid[lv];
      const xs = pts.map(p => p[0]), zs = pts.map(p => p[1]);
      for (let cz = Z(Math.min(...zs)); cz < Z(Math.max(...zs)); cz++)
        for (let cx = X(Math.min(...xs)); cx < X(Math.max(...xs)); cx++)
          if (inside(pts, wx(cx) + CELL / 2, wz(cz) + CELL / 2)) g[cx + cz * nx] = s.index;
    };

    for (const z of P.zones) {
      const shell = z.lv === "G" && z.kind === "indoor" ? shellAt(...(z.label || ptsOf(z)[0])) : null;
      const s = { name: z.name, lv: z.lv, floorY: z.y };
      if (z.kind === "outdoor") Object.assign(s, { kind: "outdoor", floor: "asphalt" });
      else if (z.kind === "backdrop") Object.assign(s, { kind: "backdrop", floor: "concrete_dark" });
      else if (z.kind === "deck") Object.assign(s, { kind: "walk", floor: "metal_blue", merge: "walk" + z.lv });
      else if (z.lv === "B") Object.assign(s, { kind: "room", top: 0, wall: "concrete_dark", floor: "concrete", pit: z.kind === "pit", lamp: z.kind === "room" });
      else if (z.lv === "G") Object.assign(s, { kind: "room", top: z.h || (shell ? shell.h : 5), wall: (shell && shell.wall) || "concrete_dark", floor: (shell && shell.floor) || "concrete", roof: !shell, lamp: true });
      else Object.assign(s, { kind: "room", top: LVY[z.lv] + ROOM_CLEAR, wall: "plaster_grey", floor: "plaster", roof: true, lamp: true });
      addSpace(s);
      if (z.poly) paintPoly(z.lv, z.poly, s); else paintRect(z.lv, z.rect, s);
      s.rects = z.poly ? null : [z.rect];
    }
    const corridorRects = c => c.pts.slice(0, -1).map((a, i) => {
      const b = c.pts[i + 1], h = c.w / 2;
      const extA = i > 0 ? h : 0, extB = i < c.pts.length - 2 ? h : 0;
      if (a[1] === b[1]) {
        const dir = Math.sign(b[0] - a[0]);
        return [Math.min(a[0] - dir * extA, b[0] + dir * extB), a[1] - h, Math.max(a[0] - dir * extA, b[0] + dir * extB), a[1] + h];
      }
      const dir = Math.sign(b[1] - a[1]);
      return [a[0] - h, Math.min(a[1] - dir * extA, b[1] + dir * extB), a[0] + h, Math.max(a[1] - dir * extA, b[1] + dir * extB)];
    });
    for (const c of P.corridors) {
      const shell = c.lv === "G" ? shellAt(c.pts[0][0], c.pts[0][1]) : null;
      const top = c.lv === "B" ? 0 : c.lv === "G" ? (shell ? shell.h : 4) : LVY[c.lv] + ROOM_CLEAR;
      const s = addSpace({ name: c.name, lv: c.lv, kind: "room", top, merge: "cor" + c.lv, corridor: c,
        wall: (shell && shell.wall) || "concrete_dark", floor: (shell && shell.floor) || "concrete", roof: c.lv !== "B" && c.lv !== "G", lamp: true });
      s.rects = corridorRects(c);
      s.rects.forEach(r => paintRect(c.lv, r, s));
    }
    for (const c of P.catwalks) {
      const s = addSpace({ name: c.name, lv: c.lv, kind: "walk", floor: "metal_blue", merge: "walk" + c.lv });
      paintRect(c.lv, c.rect, s);
    }
    // Ramps fill only empty cells, on both storeys they join.
    const rampRect = r => {
      const h = r.w / 2;
      return r.from[1] === r.to[1]
        ? [Math.min(r.from[0], r.to[0]), r.from[1] - h, Math.max(r.from[0], r.to[0]), r.from[1] + h]
        : [r.from[0] - h, Math.min(r.from[1], r.to[1]), r.from[0] + h, Math.max(r.from[1], r.to[1])];
    };
    for (const r of P.ramps) {
      const s = addSpace({ name: r.name, kind: "ramp" });
      new Set([lvOf(r.from[2]), lvOf(r.to[2])]).forEach(lv => paintRect(lv, rampRect(r), s, true));
    }
    const groupOf = i => (i < 0 ? -1 : find(i));

    // Floor openings on the ground storey: over pits and stairwells down.
    const hole = new Uint8Array(nx * nz);
    grid.B.forEach((v, i) => { if (v >= 0 && (spaces[v].pit || spaces[v].kind === "ramp")) hole[i] = 1; });
    const shellTop = new Float32Array(nx * nz);
    for (const sh of P.shells)
      for (let cz = Z(sh.rect[1]); cz < Z(sh.rect[3]); cz++)
        for (let cx = X(sh.rect[0]); cx < X(sh.rect[2]); cx++) shellTop[cx + cz * nx] = sh.h;

    // Barriers per edge: key -> { lo/hi intervals, thick, mat }.
    const edges = new Map();
    const addBarrier = (key, lo, hi, thick, mat) => {
      let e = edges.get(key);
      if (!e) { e = { spans: [], thick, mat }; edges.set(key, e); }
      e.spans.push([lo, hi]);
      if (thick > e.thick) { e.thick = thick; e.mat = mat; }
    };
    const barrier = (lv, A, B, nullShellTop) => {
      const base = LVY[lv];
      if (B && groupOf(A.index) === groupOf(B.index)) return null;
      if (A.kind === "ramp" || (B && B.kind === "ramp")) {
        if (B && A.kind === "ramp" && B.kind === "ramp") return null;
        if (B) return null;
        return lv === "B" ? [base - 0.05, 0, WALL_T, "concrete_dark"] : null;
      }
      const room = A.kind === "room" ? A : B && B.kind === "room" ? B : null;
      if (room) {
        const other = room === A ? B : A;
        const top = Math.max(room.top, other && other.kind === "room" ? other.top : -Infinity);
        const lo = lv === "G" || lv === "B" ? base - 0.05 : base - 0.3;
        return [lo, top, WALL_T, room.wall];
      }
      if (!B) {
        if (A.kind === "outdoor") return [-0.05, nullShellTop || BOUNDARY_H, WALL_T, nullShellTop ? "plaster_grey" : "brick_dark"];
        if (A.kind === "walk") return [base, base + RAIL_H, RAIL_T, "dark"];
      }
      return null;
    };
    for (const lv of LV) {
      const g = grid[lv];
      for (let cz = 0; cz < nz; cz++)
        for (let cx = 0; cx < nx; cx++) {
          const a = g[cx + cz * nx];
          if (a < 0) continue;
          const A = spaces[a];
          const dirs = [[1, 0, `v:${cx + 1}:${cz}`], [-1, 0, `v:${cx}:${cz}`], [0, 1, `h:${cx}:${cz + 1}`], [0, -1, `h:${cx}:${cz}`]];
          for (const [dx, dz, key] of dirs) {
            const ox = cx + dx, oz = cz + dz;
            const outOf = ox < 0 || oz < 0 || ox >= nx || oz >= nz;
            const j = outOf ? -1 : ox + oz * nx;
            const b = j < 0 ? -1 : g[j];
            if (b >= 0 && (dx < 0 || dz < 0)) continue;
            const got = barrier(lv, A, b >= 0 ? spaces[b] : null, j >= 0 && lv === "G" ? shellTop[j] : 0);
            if (got) addBarrier(key, got[0], got[1], got[2], got[3]);
          }
        }
    }

    // Doors cut openings; shut ones become panels.
    const panels = [], kickDoors = [];
    const openings = new Map();
    for (const d of P.doors) {
      const base = d.y != null ? d.y : LVY[d.lv];
      const y0 = base - 0.35, y1 = base + DOOR_H;
      if (d.type === "kick")
        kickDoors.push({ name: d.name, at: [d.at[0], base + 0.025, d.at[1]], yaw: d.axis === "h" ? 0 : -Math.PI / 2, width: d.w, height: DOOR_H, prompt: !!d.prompt });
      const c = d.axis === "h" ? d.at[0] : d.at[1];
      const line = d.axis === "h" ? Z(d.at[1]) : X(d.at[0]);
      const from = d.axis === "h" ? X(c - d.w / 2) : Z(c - d.w / 2);
      const to = d.axis === "h" ? X(c + d.w / 2) : Z(c + d.w / 2);
      if (OPEN_DOORS[d.type]) {
        for (let k = from; k < to; k++) {
          const key = d.axis === "h" ? `h:${k}:${line}` : `v:${line}:${k}`;
          if (!openings.has(key)) openings.set(key, []);
          openings.get(key).push([y0, y1]);
        }
      } else {
        const len = d.w, th = 0.5;
        panels.push({ name: d.name, c: [d.at[0], base + DOOR_H / 2, d.at[1]],
          s: d.axis === "h" ? [len, DOOR_H, th] : [th, DOOR_H, len], m: "metal_blue" });
      }
    }
    const union = spans => {
      const s = spans.slice().sort((a, b) => a[0] - b[0]), out = [];
      for (const [lo, hi] of s) {
        if (out.length && lo <= out[out.length - 1][1] + 1e-6) out[out.length - 1][1] = Math.max(out[out.length - 1][1], hi);
        else out.push([lo, hi]);
      }
      return out;
    };
    const subtract = (spans, cuts) => {
      let out = spans;
      for (const [c0, c1] of cuts) {
        const next = [];
        for (const [lo, hi] of out) {
          if (c1 <= lo || c0 >= hi) { next.push([lo, hi]); continue; }
          if (c0 > lo + 0.05) next.push([lo, c0]);
          if (c1 < hi - 0.05) next.push([c1, hi]);
        }
        out = next;
      }
      return out;
    };
    for (const [key, e] of edges) e.spans = subtract(union(e.spans), openings.get(key) || []);

    // Merge runs of identical edges along each line into boxes.
    const boxes = [];
    const sig = e => e.thick + e.mat + e.spans.map(s => s[0].toFixed(2) + "," + s[1].toFixed(2)).join(";");
    const lines = new Map();
    for (const [key, e] of edges) {
      if (!e.spans.length) continue;
      const [o, a, b] = key.split(":");
      const lineKey = o === "v" ? `v:${a}` : `h:${b}`;
      const pos = o === "v" ? +b : +a;
      if (!lines.has(lineKey)) lines.set(lineKey, []);
      lines.get(lineKey).push({ pos, e });
    }
    for (const [lineKey, list] of lines) {
      list.sort((p, q) => p.pos - q.pos);
      const [o, idx] = lineKey.split(":");
      let run = null;
      const flush = () => {
        if (!run) return;
        const half = run.e.thick / 2;
        const a0 = (o === "v" ? wz(run.from) : wx(run.from)) - half, a1 = (o === "v" ? wz(run.to) : wx(run.to)) + half;
        const at = o === "v" ? wx(+idx) : wz(+idx);
        for (const [lo, hi] of run.e.spans) {
          const c = [0, (lo + hi) / 2, 0], s = [0, hi - lo, 0];
          if (o === "v") { c[0] = at; c[2] = (a0 + a1) / 2; s[0] = run.e.thick; s[2] = a1 - a0; }
          else { c[0] = (a0 + a1) / 2; c[2] = at; s[0] = a1 - a0; s[2] = run.e.thick; }
          boxes.push({ kind: run.e.thick === RAIL_T ? "rail" : "wall", c, s, m: run.e.mat });
        }
        run = null;
      };
      for (const { pos, e } of list) {
        if (run && pos === run.to && sig(e) === run.sig) { run.to = pos + 1; continue; }
        flush();
        run = { from: pos, to: pos + 1, e, sig: sig(e) };
      }
      flush();
    }

    // Floors: merge cells by material into rectangles, then tile them.
    const rects = (label, want) => {
      const used = new Uint8Array(nx * nz), out = [];
      for (let cz = 0; cz < nz; cz++)
        for (let cx = 0; cx < nx; cx++) {
          const i = cx + cz * nx, v = label[i];
          if (used[i] || !want(v)) continue;
          let x1 = cx;
          while (x1 + 1 < nx && !used[x1 + 1 + cz * nx] && label[x1 + 1 + cz * nx] === v) x1++;
          let z1 = cz;
          grow: while (z1 + 1 < nz) {
            for (let k = cx; k <= x1; k++) if (used[k + (z1 + 1) * nx] || label[k + (z1 + 1) * nx] !== v) break grow;
            z1++;
          }
          for (let r = cz; r <= z1; r++) for (let k = cx; k <= x1; k++) used[k + r * nx] = 1;
          out.push({ v, r: [wx(cx), wz(cz), wx(x1 + 1), wz(z1 + 1)] });
        }
      return out;
    };
    const tile = (r, size) => {
      const out = [];
      const cols = Math.ceil((r[2] - r[0]) / size - 1e-6), rows = Math.ceil((r[3] - r[1]) / size - 1e-6);
      for (let i = 0; i < cols; i++)
        for (let j = 0; j < rows; j++)
          out.push([r[0] + (r[2] - r[0]) * i / cols, r[1] + (r[3] - r[1]) * j / rows, r[0] + (r[2] - r[0]) * (i + 1) / cols, r[1] + (r[3] - r[1]) * (j + 1) / rows]);
      return out;
    };
    const slab = (kind, r, top, thick, m) => boxes.push({ kind, c: [(r[0] + r[2]) / 2, top - thick / 2, (r[1] + r[3]) / 2], s: [r[2] - r[0], thick, r[3] - r[1]], m });
    const matIds = [], matOf = m => { let k = matIds.indexOf(m); if (k < 0) { matIds.push(m); k = matIds.length - 1; } return k; };
    // A raised floor (the dock) is a solid platform, except where a ramp inside it climbs up
    // from ground level: that slot keeps the ground floor.
    const slot = new Uint8Array(nx * nz);
    for (const r of P.ramps) {
      if (lvOf(r.from[2]) !== "G" || lvOf(r.to[2]) !== "G") continue;
      const q = rampRect(r);
      for (let cz = Z(q[1]); cz < Z(q[3]); cz++) for (let cx = X(q[0]); cx < X(q[2]); cx++) slot[cx + cz * nx] = 1;
    }
    for (const lv of LV) {
      const label = new Int16Array(nx * nz).fill(-1);
      grid[lv].forEach((v, i) => {
        if (v < 0 || spaces[v].kind === "ramp") return;
        if (lv === "G" && hole[i]) return;
        const top = lv === "G" && spaces[v].floorY && !slot[i] ? spaces[v].floorY : LVY[lv];
        label[i] = matOf(spaces[v].floor + "|" + top);
      });
      const thick = lv === "B" ? 0.5 : lv === "G" ? 0.3 : 0.3;
      rects(label, v => v >= 0).forEach(({ v, r }) => {
        const [m, top] = matIds[v].split("|");
        tile(r, TILE).forEach(t => slab("floor", t, +top, thick + (+top - LVY[lv]), m));
      });
    }
    // Ground under everything, with the same openings; it is also the tunnels' ceiling.
    const ground = new Int16Array(nx * nz);
    hole.forEach((h, i) => { ground[i] = h ? -1 : 0; });
    rects(ground, v => v === 0).forEach(({ r }) => tile(r, 24).forEach(t => slab("ground", t, -0.02, 0.48, "concrete_dark")));
    const far = 220;
    [[bx - far, bz - far, bx + bw + far, bz], [bx - far, bz + bh, bx + bw + far, bz + bh + far], [bx - far, bz, bx, bz + bh], [bx + bw, bz, bx + bw + far, bz + bh]]
      .forEach(r => slab("ground", r, -0.02, 0.48, "concrete_dark"));

    // Roofs.
    for (const sh of P.shells) tile(sh.rect, TILE).forEach(t => slab("roof", t, sh.h + 0.4, 0.4, "concrete_dark"));
    for (const s of spaces) {
      if (!s.roof) continue;
      const rs = s.rects || [];
      rs.forEach(r => tile(r, TILE).forEach(t => slab("roof", t, s.top + 0.4, 0.4, "concrete_dark")));
    }

    // Fences and shut doors.
    for (const f of P.fences)
      for (let i = 0; i < f.pts.length - 1; i++) {
        const [a, b] = [f.pts[i], f.pts[i + 1]];
        const along = a[1] === b[1];
        boxes.push({ kind: "fence", c: [(a[0] + b[0]) / 2, FENCE_H / 2, (a[1] + b[1]) / 2], s: along ? [Math.abs(b[0] - a[0]), FENCE_H, 0.15] : [0.15, FENCE_H, Math.abs(b[1] - a[1])], m: "dark" });
      }
    panels.forEach(p => boxes.push({ kind: "panel", c: p.c, s: p.s, m: p.m }));

    // Ramps as the kit wants them: low and high ends.
    const ramps = P.ramps.map(r => {
      const low = r.from[2] <= r.to[2] ? r.from : r.to, high = low === r.from ? r.to : r.from;
      return { name: r.name, low: [low[0], low[2], low[1]], high: [high[0], high[2], high[1]], w: r.w, along_x: r.from[1] === r.to[1] };
    });

    // Lights: a grid in rooms, a string along corridors.
    const lights = [];
    const lamp = (x, y, z, style) => lights.push({ at: [x, y, z], ...style });
    // Few lamps, strong ones: the Compatibility renderer draws 32 lights in view and 8 per mesh.
    const TALL = { energy: 7, range: 30, tint: [0.95, 0.97, 1.0] };
    const LOW = { energy: 2.5, range: 14, tint: [1.0, 0.95, 0.85] };
    const DEEP = { energy: 3.2, range: 16, tint: [0.82, 1.0, 0.88] };
    for (const z of P.zones) {
      const s = spaces.find(q => q.name === z.name && q.lv === z.lv && !q.corridor);
      if (!s || !s.lamp) continue;
      const pts = ptsOf(z), xs = pts.map(p => p[0]), zs = pts.map(p => p[1]);
      const [x0, z0, x1, z1] = [Math.min(...xs), Math.min(...zs), Math.max(...xs), Math.max(...zs)];
      const tall = s.top - LVY[z.lv] >= 8;
      const style = z.lv === "B" ? DEEP : tall ? TALL : LOW, step = tall ? 20 : z.lv === "G" && x1 - x0 > 40 ? 16 : 10;
      const cols = Math.max(1, Math.round((x1 - x0) / step)), rows = Math.max(1, Math.round((z1 - z0) / step));
      for (let i = 0; i < cols; i++)
        for (let j = 0; j < rows; j++) {
          const lx = x0 + (x1 - x0) * (i + 0.5) / cols, lz = z0 + (z1 - z0) * (j + 0.5) / rows;
          if (z.poly && !inside(z.poly, lx, lz)) continue;
          lamp(lx, tall ? s.top - 2 : s.top - 0.7 - (z.lv === "B" ? 0.6 : 0), lz, style);
        }
    }
    for (const s of spaces) {
      if (!s.corridor) continue;
      const c = s.corridor, style = c.lv === "B" ? DEEP : LOW, y = c.lv === "B" ? -1.3 : s.top - 0.7;
      for (let i = 0; i < c.pts.length - 1; i++) {
        const [a, b] = [c.pts[i], c.pts[i + 1]], len = Math.hypot(b[0] - a[0], b[1] - a[1]);
        const count = Math.max(1, Math.round(len / 10));
        for (let k = 0; k < count; k++) lamp(a[0] + (b[0] - a[0]) * (k + 0.5) / count, y, a[1] + (b[1] - a[1]) * (k + 0.5) / count, style);
      }
    }

    // Line-of-sight blockers. Car-sized vehicles become the kit's cars, round ones tanks,
    // the rest boxes. A top that lands on a storey drops under that storey's deck.
    const PAINT = { container: ["teal", "rust", "car_red", "car_green", "car_blue"], vehicle: ["car_white", "car_red", "car_blue", "car_tan", "car_green"] };
    const MAT = { machine: "rust", tank: "metal_blue", crates: "plaster_ochre", furniture: "plaster_grey", rack: "rust", building: "plaster_grey", vehicle: "car_white" };
    const turn = {};
    const paint = type => { turn[type] = ((turn[type] || 0) + 1) % PAINT[type].length; return PAINT[type][turn[type]]; };
    const blockers = (P.blockers || []).map(b => {
      const base = LVY[b.lv];
      let top = base + b.h;
      if (Math.abs(top - LVY.C1) < 1e-6 || Math.abs(top - LVY.C2) < 1e-6) top -= 0.3;
      const m = PAINT[b.type] ? paint(b.type) : MAT[b.type];
      if (b.circle) return { name: b.name, shape: "round", at: [b.circle[0], base, b.circle[1]], r: b.circle[2], h: top - base, m };
      const [x0, z0, x1, z1] = b.rect, w = x1 - x0, d = z1 - z0;
      if (b.hollow) return { name: b.name, shape: "hollow", c: [(x0 + x1) / 2, (base + top) / 2, (z0 + z1) / 2], s: [w, top - base, d], open: b.hollow, m };
      if (b.type === "vehicle" && Math.max(w, d) <= 5 && Math.min(w, d) <= 2.6)
        return { name: b.name, shape: "car", at: [(x0 + x1) / 2, base, (z0 + z1) / 2], yaw: w >= d ? 0 : Math.PI / 2, m };
      return { name: b.name, shape: "box", c: [(x0 + x1) / 2, (base + top) / 2, (z0 + z1) / 2], s: [w, top - base, d], m };
    });

    // Beat lines at the start of every route section after the first, the spawn and the exit.
    // A section can set its own beat point, for when its start is somewhere you pass early.
    const beats = P.route.slice(1).map((seg, i) => {
      const [a, b] = seg.pts;
      if (seg.beat) return { beat: i + 1, name: seg.name, at: [seg.beat[0], seg.beat[2] + 1.5, seg.beat[1]], size: [6, 3, 6] };
      const acrossX = Math.abs(b[0] - a[0]) < Math.abs(b[1] - a[1]);
      return { beat: i + 1, name: seg.name, at: [a[0], a[2] + 1.5, a[1]], size: acrossX ? [6, 3, 1.5] : [1.5, 3, 6] };
    });
    const first = P.route[0].pts;
    const spawn = { at: [first[0][0], first[0][2] + 0.3, first[0][1]], yaw: Math.atan2(-(first[1][0] - first[0][0]), -(first[1][1] - first[0][1])) };
    const lastSeg = P.route[P.route.length - 1].pts;
    const end = lastSeg[lastSeg.length - 1];
    // The end zone: past the last route point, clear of the gate, big enough to find.
    const exit = { at: [end[0] + 2, end[2] + 2, end[1]], size: [8, 4, 12] };
    const route = [];
    P.route.forEach(s => s.pts.forEach(p => {
      const last = route[route.length - 1];
      if (!last || last[0] !== p[0] || last[1] !== p[2] || last[2] !== p[1]) route.push([p[0], p[2], p[1]]);
    }));
    let units = 0;
    for (let i = 0; i < route.length - 1; i++) units += Math.hypot(route[i + 1][0] - route[i][0], route[i + 1][2] - route[i][2]);
    const par = P.par || Math.round(units / P.rate * 3 / 30) * 30;

    // Pickups: weapons from the plan, and the ammo and health that dead ends pay.
    const godot = p => [p[0], p[2], p[1]];
    const pickups = [
      ...(P.pickups || []).map(p => ({ kind: p.kind, at: godot(p.at) })),
      ...P.payoffs.flatMap(p => {
        const kinds = p.types.filter(t => t === "ammo" || t === "health");
        return kinds.map((kind, i) => ({ kind, at: [p.at[0] + (i - (kinds.length - 1) / 2) * 1.5, LVY[p.lv], p.at[1]] }));
      }),
    ];

    // The machine set piece, in Godot order.
    const sp = P.setpiece;
    const setpiece = sp && {
      start_at: godot(sp.start.at), start_size: sp.start.size,
      seal_at: godot(sp.seal.at), seal_radius: sp.seal.radius, seal_length: sp.seal.length,
      respawn_at: godot(sp.respawn),
      pipes: sp.pipes.map(p => [godot(p.at), p.size]),
      waves: sp.waves,
      melee_hatches: sp.melee_hatches.map(godot),
      ranged_hatches: sp.ranged_hatches.map(godot),
      end_zone_at: exit.at, end_zone_size: exit.size,
      exit_at: godot(sp.exit.at), exit_size: sp.exit.size,
      vents: sp.vents.map(godot),
      escape_seconds: sp.escape_seconds,
      escape_events: (sp.escape_events || []).map(ev => ({
        kind: ev.kind, at: godot(ev.at), size: ev.size || [1, 1, 1],
        trigger: ev.trigger ? godot(ev.trigger) : null, radius: ev.radius || 0,
        delay: ev.delay || 0, duration: ev.duration || 3,
      })),
      alarms: (sp.alarms || []).map(godot),
    };

    const enemies = (P.enemies || []).map(e => ({ kind: e.kind, at: godot(e.at) }));

    // Dressing: cutouts, ambushes, signs, painted bays and window bands. face -> yaw, where a
    // yaw of 0 looks down +z.
    const YAW = { s: 0, n: Math.PI, e: Math.PI / 2, w: -Math.PI / 2 };
    const johns = (P.johns || []).map(p => ({ at: godot(p.at), yaw: YAW[p.face] }));
    const ambushes = (P.ambushes || []).map(a => ({ name: a.name, at: godot(a.trigger.at), size: a.trigger.size, spawn: godot(a.spawn), count: a.count }));
    const signs = (P.signs || []).map(p => ({ text: p.text, at: godot(p.at), width: p.width, height: p.height, yaw: YAW[p.face], style: p.style }));
    const floorText = (P.floor_text || []).map(p => ({ text: p.text, at: godot(p.at), yaw: YAW[p.face] }));
    const windows = (P.windows || []).map(p => ({ at: godot(p.at), width: p.width, yaw: YAW[p.face] }));
    const secrets = (P.secrets || []).map(p => ({ name: p.name, at: godot(p.at), reward: p.reward, trigger: p.trigger || [2.5, 2.5], path: p.path.map(godot) }));

    return { boxes, ramps, blockers, kick_doors: kickDoors, pickups, setpiece, enemies, johns, ambushes, signs, floor_text: floorText, windows, secrets, lights, beats, spawn, exit, route, golden_units: Math.round(units), par_seconds: par };
  }

  function ptsOf(o) { return o.poly || [[o.rect[0], o.rect[1]], [o.rect[2], o.rect[1]], [o.rect[2], o.rect[3]], [o.rect[0], o.rect[3]]]; }

  if (typeof module !== "undefined") module.exports = bake;
  else root.bakePlan = bake;
})(typeof window !== "undefined" ? window : globalThis);
