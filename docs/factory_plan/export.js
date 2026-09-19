// Writes plan.json, which tools/build_factory.gd bakes the scene from, and checks every
// placement against the plan's geometry.
// Run after changing the plan:  node docs/factory_plan/export.js
const fs = require("fs");
const path = require("path");

global.window = {};
require("./plan_floors.js");
require("./plan_items.js");
require("./plan_dressing.js");
const bake = require("./bake.js");
const check = require("./check.js");

const out = bake(window.PLAN);
const round = v => Math.round(v * 1000) / 1000;
const tidy = o => JSON.stringify(o, (k, v) => (typeof v === "number" ? round(v) : v));
const list = key => `"${key}": [\n${out[key].map(tidy).join(",\n")}\n]`;
const lines = [
  "{",
  `"golden_units": ${out.golden_units}, "par_seconds": ${out.par_seconds},`,
  `"spawn": ${tidy(out.spawn)}, "exit": ${tidy(out.exit)},`,
  `"route": ${tidy(out.route)},`,
  `"art_regions": ${tidy(window.PLAN.shells.map(s => ({name:s.name,rect:s.rect,ceiling:s.h})))},`,
  `"setpiece": ${tidy(out.setpiece)},`,
  ["door_frames", "round_decks", "pumps", "alts", "beats", "ramps", "blockers", "kick_doors", "pickups", "enemies", "johns", "ambushes", "signs", "floor_text", "windows", "secrets", "lights", "boxes"].map(list).join(",\n"),
  "}",
];
const file = path.join(__dirname, "plan.json");
fs.writeFileSync(file, lines.join("\n") + "\n");

const count = {};
out.boxes.forEach(b => { count[b.kind] = (count[b.kind] || 0) + 1; });
console.log(`plan.json: ${out.boxes.length} boxes ${JSON.stringify(count)}, ${out.ramps.length} ramps, ${out.blockers.length} blockers, ${out.lights.length} lights, ${out.beats.length} beats`);
console.log(`golden path ${out.golden_units} units, par ${Math.floor(out.par_seconds / 60)}:${String(out.par_seconds % 60).padStart(2, "0")}`);
console.log(`${out.johns.length} Johns, ${out.enemies.length} placed enemies, ${out.ambushes.length} ambushes, ${out.signs.length} signs, ${out.floor_text.length} painted bays, ${out.secrets.length} secrets, ${out.setpiece.escape_events.length} escape events`);

const problems = check(window.PLAN);
if (problems.length) {
  console.log(`${problems.length} placement problems:`);
  problems.forEach(p => console.log(" - " + p));
} else {
  console.log("placements: no problems");
}
