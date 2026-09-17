// Checks everything placed in the plan against the plan's own geometry, so nothing is
// baked standing in a wall, inside a blocker, over a pit or in the walker's way.
// export.js runs it and prints what it finds; nothing here stops the export.
//
//   Johns, enemies, pickups, hatches, ambush spawns: on a floor of their level, with
//   room round them, and clear of blockers.
//   Enemies above a floor (roofs, container tops): standing on something that high.
//   Johns: clear of the golden path and the short ways, where they'd block a walker.
module.exports = function check(P) {
  const LVY = { B: -4, G: 0, C1: 4, C2: 8 };
  const lvOf = y => (y <= -2 ? "B" : y >= 6 ? "C2" : y >= 2 ? "C1" : "G");
  const problems = [];
  const inRect = (r, x, z) => x >= Math.min(r[0], r[2]) && x <= Math.max(r[0], r[2]) && z >= Math.min(r[1], r[3]) && z <= Math.max(r[1], r[3]);
  const inPoly = (pts, x, z) => {
    let hit = false;
    for (let i = 0, j = pts.length - 1; i < pts.length; j = i++) {
      const [xi, zi] = pts[i], [xj, zj] = pts[j];
      if ((zi > z) !== (zj > z) && x < (xj - xi) * (z - zi) / (zj - zi) + xi) hit = !hit;
    }
    return hit;
  };
  const corridorRects = c => c.pts.slice(0, -1).map((a, i) => {
    const b = c.pts[i + 1], h = c.w / 2;
    const extA = i > 0 ? h : 0, extB = i < c.pts.length - 2 ? h : 0;
    if (a[1] === b[1]) {
      const d = Math.sign(b[0] - a[0]);
      return [Math.min(a[0] - d * extA, b[0] + d * extB), a[1] - h, Math.max(a[0] - d * extA, b[0] + d * extB), a[1] + h];
    }
    const d = Math.sign(b[1] - a[1]);
    return [a[0] - h, Math.min(a[1] - d * extA, b[1] + d * extB), a[0] + h, Math.max(a[1] - d * extA, b[1] + d * extB)];
  });
  const rampRect = r => {
    const h = r.w / 2;
    return r.from[1] === r.to[1]
      ? [Math.min(r.from[0], r.to[0]), r.from[1] - h, Math.max(r.from[0], r.to[0]), r.from[1] + h]
      : [r.from[0] - h, Math.min(r.from[1], r.to[1]), r.from[0] + h, Math.max(r.from[1], r.to[1])];
  };
  const pits = P.zones.filter(z => z.kind === "pit").map(z => z.rect);
  const stairwells = P.ramps.filter(r => lvOf(Math.min(r.from[2], r.to[2])) === "B" && lvOf(Math.max(r.from[2], r.to[2])) === "G").map(rampRect);

  const onFloor = (lv, y, x, z) => {
    if (lv === "G" && (pits.some(r => inRect(r, x, z)) || stairwells.some(r => inRect(r, x, z)))) return false;
    for (const zone of P.zones) {
      if (zone.lv !== lv || zone.kind === "backdrop") continue;
      if (zone.y != null && Math.abs(zone.y - y) > 0.3) continue;
      if (zone.y == null && lv === "G" && Math.abs(y) > 0.3) continue;
      if (zone.poly ? inPoly(zone.poly, x, z) : inRect(zone.rect, x, z)) return true;
    }
    for (const c of P.corridors) if (c.lv === lv && corridorRects(c).some(r => inRect(r, x, z))) return true;
    for (const c of P.catwalks) if (c.lv === lv && inRect(c.rect, x, z)) return true;
    return false;
  };
  // Room to stand: the point and four points round it all on floor.
  const roomy = (lv, y, x, z, m) => [[0, 0], [m, 0], [-m, 0], [0, m], [0, -m]].every(([dx, dz]) => onFloor(lv, y, x + dx, z + dz));
  // A hollow blocker only blocks with its walls: inside it, or in line with its open face,
  // there is room to stand.
  const WALL = 0.12;
  const hollowOpen = (b, x, z, m) => {
    const [x0, z0, x1, z1] = b.rect, f = b.hollow;
    const lo = [x0 + WALL + m, z0 + WALL + m], hi = [x1 - WALL - m, z1 - WALL - m];
    if (f === "e") hi[0] = Infinity; if (f === "w") lo[0] = -Infinity;
    if (f === "s") hi[1] = Infinity; if (f === "n") lo[1] = -Infinity;
    return x > lo[0] && x < hi[0] && z > lo[1] && z < hi[1];
  };
  const baseOf = b => (b.y != null ? b.y : LVY[b.lv]);
  const blockerHit = (y, x, z, m) => P.blockers.find(b => {
    const base = baseOf(b), top = base + b.h;
    if (top <= y + 0.1 || base >= y + 1.8) return false;
    if (b.circle) return Math.hypot(x - b.circle[0], z - b.circle[1]) < b.circle[2] + m;
    const near = x > b.rect[0] - m && x < b.rect[2] + m && z > b.rect[1] - m && z < b.rect[3] + m;
    return near && !(b.hollow && hollowOpen(b, x, z, m));
  });
  const standsOn = (y, x, z) =>
    P.blockers.some(b => Math.abs(baseOf(b) + b.h - y) < 0.1 && (b.circle ? Math.hypot(x - b.circle[0], z - b.circle[1]) < b.circle[2] - 0.3 : inRect([b.rect[0] + 0.3, b.rect[1] + 0.3, b.rect[2] - 0.3, b.rect[3] - 0.3], x, z)))
    || P.shells.some(s => Math.abs(s.h + 0.4 - y) < 0.1 && inRect(s.rect, x, z));

  const place = (label, at, margin, blockerMargin) => {
    const [x, z, y] = at;
    const floor = [-4, 0, 1.2, 4, 8].some(f => Math.abs(y - f) < 0.05);
    if (!floor) {
      if (!standsOn(y, x, z)) problems.push(`${label} at ${at.join(", ")}: nothing to stand on at y ${y}`);
      return;
    }
    const lv = lvOf(y);
    if (!roomy(lv, y, x, z, margin)) problems.push(`${label} at ${at.join(", ")}: not on ${lv} floor with ${margin} room`);
    const hit = blockerHit(y, x, z, blockerMargin);
    if (hit) problems.push(`${label} at ${at.join(", ")}: inside or against ${hit.name}`);
  };

  (P.johns || []).forEach(p => place(`John (${p.where})`, p.at, 0.5, 0.45));
  // A brute is 1.9 wide: it needs more room than the rest.
  (P.enemies || []).forEach(p => { const m = p.kind === "brute" ? 1.1 : 0.6; place(`${p.kind} (${p.where})`, p.at, m, m); });
  (P.pickups || []).forEach(p => place(`${p.kind} pickup (${p.where})`, p.at, 0.4, 0.4));
  P.payoffs.forEach(p => {
    if (p.types.some(t => t === "ammo" || t === "health")) place(`payoff pickup (${p.where})`, [p.at[0], p.at[1], LVY[p.lv]], 0.4, 0.4);
  });
  // A group is spread round its spawn point, so it wants room for that; a single enemy lands on
  // the point and only wants room for its own body, which is what puts one brute in a tunnel.
  (P.ambushes || []).forEach(a => {
    const m = a.count > 1 ? 1.9 : a.kind === "brute" ? 1.2 : 1.0;
    place(`ambush spawn (${a.name})`, a.spawn, m, m);
  });
  if (P.setpiece) {
    P.setpiece.melee_hatches.forEach(at => place("melee hatch", at, 0.6, 0.6));
    (P.setpiece.ranged_hatches || []).forEach(at => place("ranged hatch", at, 0.6, 0.6));
    const sp = P.setpiece;
    // Pressure arms: each socket needs fighting room on the pit floor, clear of blockers and
    // hatches, and no arm may pass through a walkway or stair at a height that would hit a
    // player on it (1.8 plus a little) or leave a lip under their feet.
    (sp.arms || []).forEach(a => {
      place(`arm ${a.n} socket (${a.where})`, a.socket, 1.2, 1.2);
      sp.melee_hatches.forEach(h => {
        if (Math.abs(h[2] - a.socket[2]) < 1 && Math.hypot(h[0] - a.socket[0], h[1] - a.socket[1]) < 3)
          problems.push(`arm ${a.n} socket within 3 of a hatch at ${h.join(", ")}`);
      });
      const decks = [
        ...P.catwalks.map(c => ({ name: c.name, rect: c.rect, y: LVY[c.lv] })),
        ...P.zones.filter(z => z.kind === "deck").map(z => ({ name: z.name, rect: z.rect, poly: z.poly, y: LVY[z.lv] })),
      ];
      // Down, and lifted: the elbow and everything under it raised by lift.
      const up = q => [q[0], q[1], q[2] + (sp.lift || 0)];
      const legs = [[a.shoulder, a.elbow], [a.elbow, a.socket], [a.shoulder, up(a.elbow)], [up(a.elbow), up(a.socket)]];
      // A socket in the golden path's way would plant a pipe in the walk.
      P.route.forEach(sec => sec.pts.forEach((q, i) => {
        if (!i) return;
        const p0 = sec.pts[i - 1];
        if (Math.abs(p0[2] - a.socket[2]) > 1 || Math.abs(q[2] - a.socket[2]) > 1) return;
        const dx = q[0] - p0[0], dz = q[1] - p0[1], len2 = dx * dx + dz * dz || 1;
        const t = Math.max(0, Math.min(1, ((a.socket[0] - p0[0]) * dx + (a.socket[1] - p0[1]) * dz) / len2));
        const d = Math.hypot(a.socket[0] - (p0[0] + dx * t), a.socket[1] - (p0[1] + dz * t));
        if (d < 2.5) problems.push(`arm ${a.n} socket ${d.toFixed(1)} from the golden path in ${sec.name}`);
      }));
      let hit = null;
      for (const [p, q] of legs) {
        for (let k = 1; k < 40 && !hit; k++) {
          const t = k / 40, x = p[0] + (q[0] - p[0]) * t, z = p[1] + (q[1] - p[1]) * t, y = p[2] + (q[2] - p[2]) * t;
          for (const d of decks) {
            if (d.name === "Machine roof" && p === a.shoulder) continue;
            const near = d.poly
              ? [[0, 0], [0.5, 0], [-0.5, 0], [0, 0.5], [0, -0.5]].some(([ox, oz]) => inPoly(d.poly, x + ox, z + oz))
              : inRect([d.rect[0] - 0.5, d.rect[1] - 0.5, d.rect[2] + 0.5, d.rect[3] + 0.5], x, z);
            if (!near) continue;
            if (y > d.y - 0.6 && y < d.y + 2.3) { hit = `${d.name} at ${x.toFixed(1)}, ${z.toFixed(1)}, height ${y.toFixed(1)}`; break; }
          }
          for (const r of P.ramps) {
            if (hit || !inRect(rampRect(r), x, z)) continue;
            const along = r.from[1] === r.to[1] ? (x - r.from[0]) / (r.to[0] - r.from[0]) : (z - r.from[1]) / (r.to[1] - r.from[1]);
            const surface = r.from[2] + (r.to[2] - r.from[2]) * Math.max(0, Math.min(1, along));
            if (y > surface - 0.6 && y < surface + 2.3) hit = `${r.name} at ${x.toFixed(1)}, ${z.toFixed(1)}`;
          }
        }
      }
      if (hit) problems.push(`arm ${a.n} passes through ${hit}`);
    });
    if (sp.order && sp.arms && [...sp.order].sort().join() !== sp.arms.map(a => a.n).sort().join())
      problems.push("setpiece order must name every arm once");
    if (sp.button) place(`button (${sp.button.where})`, [sp.button.at[0], sp.button.at[1] - 1.15, sp.button.at[2]], 0.5, 0.4);
  }

  // Secrets: at most twelve, each reward on a floor, and its path walkable all the way in.
  const secrets = P.secrets || [];
  if (secrets.length > 12) problems.push(`${secrets.length} secrets: twelve per level is the limit`);
  secrets.forEach(sc => {
    place(`secret ${sc.name}`, sc.at, 0.4, 0.4);
    for (let i = 1; i < sc.path.length; i++) {
      const [a, b] = [sc.path[i - 1], sc.path[i]];
      const steps = Math.ceil(Math.hypot(b[0] - a[0], b[1] - a[1]) / 0.25);
      for (let k = 0; k <= steps; k++) {
        const t = k / steps, x = a[0] + (b[0] - a[0]) * t, z = a[1] + (b[1] - a[1]) * t, y = a[2] + (b[2] - a[2]) * t;
        const john = (P.johns || []).find(p => Math.abs(p.at[2] - y) < 1.5 && Math.hypot(p.at[0] - x, p.at[1] - z) < 0.8);
        const hit = blockerHit(y, x, z, 0.42) || (john && { name: "a cutout John (" + john.where + ")" });
        const lv = lvOf(y);
        if (hit || !roomy(lv, y, x, z, 0.42)) {
          problems.push(`secret ${sc.name}: path blocked near ${x.toFixed(1)}, ${z.toFixed(1)}${hit ? " by " + hit.name : " (off the floor or against a wall)"}`);
          k = steps + 1; i = sc.path.length;
        }
      }
    }
  });

  // Falling debris in the escape must leave the golden path walkable.
  if (P.setpiece && P.setpiece.escape_events) {
    const legsAll = [];
    P.route.forEach(sec => sec.pts.forEach((p, i) => { if (i) legsAll.push([sec.pts[i - 1], p]); }));
    P.setpiece.escape_events.filter(ev => ev.kind === "fall").forEach(ev => {
      const [cx, cz, cy] = ev.at, [sx, sy, sz] = ev.size, m = 0.5;
      for (const [a, b] of legsAll) {
        const steps = Math.ceil(Math.hypot(b[0] - a[0], b[1] - a[1]) / 0.25) || 1;
        for (let k = 0; k <= steps; k++) {
          const t = k / steps, x = a[0] + (b[0] - a[0]) * t, z = a[1] + (b[1] - a[1]) * t, y = a[2] + (b[2] - a[2]) * t;
          if (Math.abs(x - cx) < sx / 2 + m && Math.abs(z - cz) < sz / 2 + m && y < cy + sy / 2 && y + 1.8 > cy - sy / 2) {
            problems.push(`escape fall (${ev.where}) lands on the golden path near ${x.toFixed(1)}, ${z.toFixed(1)}`);
            k = steps + 1;
          }
        }
      }
    });
  }

  // Johns off the paths a walker takes.
  const legs = [];
  P.route.forEach(s => s.pts.forEach((p, i) => { if (i) legs.push([s.pts[i - 1], p]); }));
  (P.alt || []).forEach(s => s.pts.forEach((p, i) => { if (i) legs.push([s.pts[i - 1], p]); }));
  (P.johns || []).forEach(p => {
    const [x, z, y] = p.at;
    for (const [a, b] of legs) {
      if (Math.abs(a[2] - y) > 1.5 && Math.abs(b[2] - y) > 1.5) continue;
      const dx = b[0] - a[0], dz = b[1] - a[1], len2 = dx * dx + dz * dz || 1;
      const t = Math.max(0, Math.min(1, ((x - a[0]) * dx + (z - a[1]) * dz) / len2));
      const d = Math.hypot(x - (a[0] + dx * t), z - (a[1] + dz * t));
      if (d < 1.3) { problems.push(`John (${p.where}) at ${p.at.join(", ")}: ${d.toFixed(2)} from the route`); break; }
    }
  });
  return problems;
};
