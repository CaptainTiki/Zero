// Line-of-sight blockers, payoffs, the route and the notes. h is height above the
// blocker's own floor; the player's eye is about 1.6, so anything under 1.8 is see-over.
(() => {
  const P = window.PLAN;
  const b = (name, type, lv, rect, h, note) => ({ name, type, lv, rect, h, note });
  const round = (name, type, lv, c, r, h, note) => ({ name, type, lv, circle: [c[0], c[1], r], h, note });

  const cars = [];
  const row = (z, x0, x1, gap) => {
    for (let x = x0; x + 2.2 <= x1; x += 2.9) {
      if (x + 2.2 > gap[0] && x < gap[1]) continue;
      cars.push(b("Parked car", "vehicle", "G", [x, z, x + 2.2, z + 4.6], 1.5));
    }
  };
  row(58, -96, -44, [-70, -64]);
  row(76, -90, -14, [-40, -32]);

  P.blockers = [
    ...cars,
    b("Box truck", "vehicle", "G", [-24, 84, -14, 87], 3.5, "Hides the admin doors from the start."),
    b("Van", "vehicle", "G", [-56, 86, -50, 88.5], 2.4),
    { ...b("Guard booth", "building", "G", [0, 66, 4, 70], 3), hollow: "e" },
    b("Agency car", "vehicle", "G", [1, 93, 6, 95.5], 1.5, "Start and finish."),

    b("Reception desk", "furniture", "G", [-72, 37, -64, 39], 1.1),
    b("Waiting chairs", "furniture", "G", [-58, 45, -52, 47], 1),
    b("Lunch table", "furniture", "G", [-96, 40, -92, 44], 1),
    b("Vending machines", "furniture", "G", [-100, 34, -98, 38], 2),
    b("Shelving", "rack", "G", [-98.5, 3, -91, 4], 2.4, "Stops short of the west wall: a squeeze to the gap behind."),
    b("Shelving", "rack", "G", [-98.5, 6, -91, 7], 2.4),
    b("Cubicles", "furniture", "G", [-72, 12, -66, 18], 1.6),
    b("Cubicles", "furniture", "G", [-64, 22, -58, 28], 1.6),
    b("Cubicles", "furniture", "G", [-58, 10, -52, 16], 1.6),
    b("Filing cabinets", "furniture", "G", [-76, 18, -74, 28], 2.2),
    b("Manager's desk", "furniture", "G", [-58, 2, -53, 4], 1.1),

    b("Shipping container", "container", "G", [-42, 6, -30, 8.5], 2.6, "Blocks the view from the office door to the hall doors."),
    round("Silo", "tank", "G", [2, 28], 4, 14),
    round("Silo", "tank", "G", [12, 18], 4, 14),
    b("Pallets", "crates", "G", [-18, 2, -14, 6], 1.8),
    { ...b("Gas cage", "crates", "G", [-6, -16, 0, -10], 2.5), hollow: "n" },
    b("Forklift", "vehicle", "G", [-40, -12, -37, -8], 2.2),
    b("Skip", "crates", "G", [-48, -24, -44, -21], 1.8),
    b("Dumpsters", "crates", "G", [-70, -23, -66, -20], 1.8),
    b("Skip", "crates", "G", [-84, -22, -78, -18], 2, "Stands off the alley wall: a gap behind."),
    b("Pallet stack", "crates", "G", [-90, -8, -86, -4], 2.4),
    b("Crate cache", "crates", "G", [-52, -84, -46, -80], 2.4),
    b("Skip and scaffold", "crates", "G", [-4, -84, 0, -72], 2.5, "Blocks the lane's east end."),
    b("Scaffold", "crates", "G", [-62, -86, -60, -70], 6, "Blocks the lane's west end; the city carries on past it."),

    { ...b("Container office", "container", "G", [-44, -38, -34, -32], 2.8), hollow: "w" },
    b("Crates", "crates", "G", [-50, -32, -46, -28], 3),
    b("Press A", "machine", "G", [-26, -40, -20, -35], 5),
    b("Press B", "machine", "G", [-20, -50, -15, -45], 5),
    b("Hoppers", "machine", "G", [-60, -66, -54, -58], 6),
    b("Conveyor", "machine", "G", [-48, -67, -26, -63], 1.2, "Waist high: stops you, doesn't hide anyone standing."),
    b("Drum washer", "machine", "B", [-50, -60, -44, -55], 3, "Hides the pit tunnel door behind it."),
    b("Drum washer", "machine", "B", [-50, -49, -45, -46], 3),
    b("Drum washer", "machine", "B", [-30, -54, -26, -47], 3),
    b("Hopper tower", "machine", "B", [-36, -52, -32, -48], 16, "Rises from the pit floor through both catwalks, like the column in reference 3."),

    round("Vat A", "tank", "G", [-28, -102], 6, 14),
    round("Vat B", "tank", "G", [-10, -104], 4.5, 12),
    b("Pump skid", "machine", "G", [-14, -98, -8, -95], 2),
    b("Valve wall", "machine", "G", [-40, -110, -37, -100], 3),
    b("Pumps", "machine", "B", [2, -82, 6, -79], 2),

    b("The machine", "machine", "B", [40, -104, 54, -90], 12, "Smog plant. Pit floor to roof walkway at +8."),
    round("Coolant stack", "machine", "C2", [47, -97], 4, 4.6, "Rises from the machine's roof. Three coolant pipes are strapped round it."),
    b("Valve bank", "machine", "B", [32, -100, 36, -90], 3),
    b("Pump", "machine", "B", [60, -102, 63.5, -96], 2.5),
    b("Pipe run", "machine", "B", [32, -86, 40, -82], 2),
    b("Storage tanks", "tank", "G", [24, -120, 28, -116], 5),
    b("Control desk", "furniture", "G", [66, -120, 70, -116], 1.2),

    b("Container", "container", "G", [66, -30, 78, -27.5], 2.6),
    b("Container", "container", "G", [68, -14, 80, -11.5], 2.6),
    b("Double stack", "container", "G", [50, -30, 56, -18], 5.2),
    b("Portable office", "building", "G", [24, -54, 36, -44], 3),
    b("Steel beams", "crates", "G", [62, -52, 78, -46], 1.5),
    b("Container", "container", "G", [40, -52, 52, -49.5], 2.6),
    b("Container", "container", "G", [26, -38, 28.5, -26], 2.6),
    b("Double stack", "container", "G", [56, -58, 58.5, -46], 5.2),
    { ...b("Container, open end to the wall", "container", "G", [22, -18, 34, -15.5], 2.6), hollow: "w" },

    b("Trailer", "vehicle", "G", [30, 10, 33, 24], 4),
    b("Trailer", "vehicle", "G", [44, 8, 47, 24], 4),
    b("Box truck", "vehicle", "G", [60, 14, 63, 24], 3.5),
    { ...b("Open trailer", "vehicle", "G", [70, 30, 73, 44], 4), hollow: "s" },
    b("Container stack", "container", "G", [26, 48, 38, 51], 5.2),
    b("Truck", "vehicle", "G", [46, 54, 60, 57], 3.5),
    b("Truck", "vehicle", "G", [40, 72, 52, 75], 3.5),
  ];

  // Dead ends and what they pay. type: ammo | health | secret | enemy
  P.payoffs = [
    { at: [-54, 39], lv: "G", types: ["ammo"], where: "Waiting room" },
    { at: [-94, 37.5], lv: "G", types: ["enemy", "health"], where: "Break room" },
    { at: [-52, 5.5], lv: "G", types: ["enemy", "ammo"], where: "Manager's office" },
    { at: [-96, -12], lv: "G", types: ["ammo", "enemy"], where: "Bin alley, ambush on the way out" },
    { at: [-12, -35], lv: "C1", types: ["ammo"], where: "Foreman's office" },
    { at: [-49, -77], lv: "G", types: ["enemy", "ammo"], where: "Service lane crate cache" },
    { at: [10.5, -78], lv: "B", types: ["health"], where: "Pump room" },
    { at: [26, -110], lv: "G", types: ["ammo"], where: "Plant ring, behind the tanks" },
    { at: [75, 37], lv: "G", types: ["ammo"], where: "Beside the open trailer, a step off the escape" },
  ];

  // Golden path, in order. Points are [x, z, y].
  P.route = [
    { name: "Parking lot", pts: [[4, 92, 0], [-30, 88, 0], [-40, 70, 0], [-66, 66, 0], [-70, 49, 0]] },
    { name: "Admin block", pts: [[-70, 49, 0], [-70, 44, 0], [-80, 39.5, 0], [-85, 39.5, 0], [-85, 27, 0], [-95.5, 27, 0], [-95.5, 18, 0], [-86, 18, 0], [-86, 8, 0], [-76, 8, 0], [-62, 6, 0], [-62, 20, 0], [-56, 19.5, 0], [-50, 19.5, 0]] },
    { name: "Central yard", pts: [[-50, 19.5, 0], [-38, 20, 0], [-26, 8, 0], [-14, -6, 0], [-24, -18, 0], [-30, -26, 0]] },
    { name: "Hall floor and pit", pts: [[-30, -26, 0], [-18, -31, 0], [-12, -40, 0], [-12, -52, 0], [-24, -58.5, 0], [-36, -58.5, -4], [-40, -55, -4], [-40, -43.5, -4], [-52, -43.5, 0], [-60.75, -29, 0]] },
    { name: "Hall catwalks", pts: [[-60.75, -29, 0], [-60.75, -42, 4], [-61, -69, 4], [-34, -69, 4], [-34, -54, 4], [-31, -53, 4], [-31, -49.5, 4], [-30, -50, 4], [-20, -50, 8], [-18.5, -52, 8], [-18.5, -69, 8], [-18.5, -70, 8]] },
    { name: "Skybridge", pts: [[-18.5, -70, 8], [-18.5, -86, 8]] },
    { name: "Tank house", pts: [[-18.5, -86, 8], [-18.5, -114, 8], [-21, -115, 8], [-33, -115, 4], [-38, -112, 4], [-38, -92, 4], [-33, -91, 4], [-21, -91, 0], [-12, -92.5, 0], [-3, -92, 0], [-3, -104, -4]] },
    { name: "Service tunnels", pts: [[-3, -104, -4], [-3, -108, -4], [8, -108, -4], [8, -96, -4], [18, -96, -4], [18, -106, -4], [30, -106, -4]] },
    { name: "Plant room", pts: [[30, -106, -4], [34, -110, -4], [57, -110, -4], [57, -88, -4], [38, -87, -4], [38, -100, -4], [38, -87, -4], [42, -87.5, -4], [50, -83, -4], [52, -81.5, -4], [64, -81.5, 0], [68, -80, 0], [68, -92, 4], [68, -97, 4], [55, -97, 4], [55, -107, 4], [39, -107, 4], [39, -92, 4], [39, -80, 8], [39, -78.75, 8], [47.25, -78.75, 8], [47.25, -91.5, 8], [41.25, -91.5, 8], [41.25, -102.75, 8], [52.75, -102.75, 8], [52.75, -91.5, 8], [47.25, -91.5, 8]] },
    { name: "Escape: warehouse", escape: true, beat: [47.25, -66, 8], pts: [[47.25, -91.5, 8], [47.25, -62, 8], [48, -61, 8], [50, -61, 8], [62, -61, 4], [83, -61, 4], [83, -40, 4], [83, -28, 0], [76, -18, 0], [66, -18, 0], [60, -36, 0], [48, -40, 0], [40, -24, 0], [36, -10, 0], [36, -6, 0]] },
    { name: "Escape: dock and trucks", escape: true, pts: [[36, -6, 0], [36, -2.5, 1.2], [36, 2, 1.2], [38, 5, 1.2], [38, 10, 0], [38, 30, 0], [54, 40, 0], [40, 62, 0], [24, 84, 0], [14, 89, 0]] },
  ];

  // Weapons, until the enemies pass places them properly. Points are [x, z, y].
  P.pickups = [
    { kind: "gun", at: [-68, 42, 0], where: "Lobby, by the reception desk" },
    { kind: "shotgun", at: [-38, -29, 0], where: "Hall, inside the doors" },
    { kind: "health", at: [26, -78, 0], where: "Plant ring, by the south wall" },
    { kind: "ammo", at: [63, -120, 0], where: "Plant ring, north side by the control desk" },
  ];

  // The plant room climax. Points are [x, z, y].
  // Walk into the pit and a pipe falls across the tunnel door. Break six coolant pipes,
  // kicks or shots: three round the machine's base on the pit floor, three strapped round
  // the stack on its roof. The fight starts with wave 1 and each pipe but the last sends
  // the next. The last one sends the machine critical and opens the high exit.
  P.setpiece = {
    name: "Coolant pipes",
    start: { at: [50, -97, -2], size: [28, 4, 34], note: "The whole pit floor east of x 36, so the seal never lands on the player." },
    seal: { at: [31.8, -106, -2.4], radius: 1.6, length: 6 },
    respawn: [38, -110, -3.5],
    pipes: [
      { at: [54.5, -97, -2.5], size: [0.9, 3, 0.9], where: "Base, east face, pit floor" },
      { at: [47, -89.5, -2.5], size: [0.9, 3, 0.9], where: "Base, south face, pit floor" },
      { at: [39.5, -97, -2.5], size: [0.9, 3, 0.9], where: "Base, west face, pit floor" },
      { at: [42.55, -97, 9.5], size: [0.9, 3, 0.9], where: "Stack, west side, roof walkway" },
      { at: [47, -101.45, 9.5], size: [0.9, 3, 0.9], where: "Stack, north side, roof walkway" },
      { at: [51.45, -97, 9.5], size: [0.9, 3, 0.9], where: "Stack, east side, roof walkway" },
    ],
    // [fodder, hunters, rammers]. Melee spawns at a hatch on the player's level; Hunters at
    // ranged hatches, which can be anywhere they can see. Up on the walks, Rammers come as fodder.
    waves: [[4, 0, 0], [3, 1, 1], [4, 2, 0], [3, 2, 0], [3, 2, 0], [4, 2, 0]],
    melee_hatches: [
      [60, -112, -4], [58, -86, -4], [34, -88, -4],
      [62, -118, 0], [32, -118, 0], [26, -76, 0], [68, -76, 0],
      [39, -107, 4], [47, -107, 4], [55, -107, 4], [55, -100, 4],
      [38, -78.75, 8], [44, -78.75, 8], [47.25, -84, 8],
    ],
    ranged_hatches: [[26, -100, 0], [26, -86, 0], [26, -114, 0], [62, -119, 0], [68, -102, 0]],
    exit: { at: [47.25, -72, 9.6], size: [2.6, 3.3, 0.5] },
    vents: [[41, -91, 8.2], [53, -91, 8.2], [41, -103, 8.2], [53, -103, 8.2], [47, -97, 12.8], [37, -104, -4], [57, -92, -4]],
    escape_seconds: 65,
    // Once the machine is critical the place falls apart round the escape. A fall drops a pipe,
    // beam or crate to rest at [x, z, y] with size [x, y, z]; steam jets up for a few seconds.
    // With no trigger they happen on a delay after critical; with one, when the player comes
    // within radius. Every fall leaves the golden path clear, which check.js confirms.
    escape_events: [
      { kind: "fall", at: [58, -113, -3.6], size: [6, 0.8, 0.8], delay: 1.0, where: "Pit floor" },
      { kind: "fall", at: [26, -100, 0.4], size: [0.8, 0.8, 6], delay: 2.2, where: "Plant ring" },
      { kind: "fall", at: [60, -86, -3.6], size: [0.8, 0.8, 4], delay: 3.4, where: "Pit floor" },
      { kind: "steam", at: [45, -67, 0], trigger: [47.25, -72, 8], radius: 3.5, duration: 3, where: "Up past the outside catwalk" },
      { kind: "steam", at: [72, -59.6, 4], trigger: [62, -61, 4], radius: 4, duration: 3, where: "Beside the warehouse catwalk" },
      { kind: "fall", at: [72, -23.5, 0.4], size: [0.8, 0.8, 7], trigger: [83, -30, 0], radius: 4, where: "Container lane, leaves a gap on the right" },
      { kind: "fall", at: [58.5, -26, 0.4], size: [5, 0.8, 0.8], trigger: [70, -18, 0], radius: 5, where: "Off the double stack" },
      { kind: "steam", at: [46.5, -34, 0], trigger: [52, -39, 0], radius: 5, duration: 3, where: "Floor vent in the maze" },
      { kind: "fall", at: [34.3, -7.6, 0.7], size: [1.4, 1.4, 1.4], trigger: [40, -24, 0], radius: 5, where: "Half the roller door" },
      { kind: "steam", at: [44, 1, 1.2], trigger: [36, -2.5, 1.2], radius: 4, duration: 3, where: "Dock floor" },
      { kind: "fall", at: [44, 44, 1.3], size: [8, 2.6, 2.5], trigger: [38, 20, 0], radius: 6, where: "A container off the stack, shuts the straight run" },
    ],
    alarms: [[52, -34, 11], [50, 0, 4.2], [47, -66, 10]],
  };

  // Short ways leave the golden path at split and rejoin it at join; both points are on the route.
  P.alt = [
    { name: "Short way: pit tunnel", split: [-40, -55, -4], join: [8, -96, -4],
      pts: [[-40, -55, -4], [-43, -53, -4], [-51, -53, -4], [-51, -58, -4], [-56, -58, -4], [-56, -74, -4], [-30, -74, -4], [-30, -80, -4], [-10, -80, -4], [-10, -76, -4], [0, -76, -4], [8, -78, -4], [8, -84, -4], [8, -96, -4]] },
  ];

  P.spaces = [
    { name: "Parking lot", size: "110 x 48, outdoor", scale: "open", text: "Start at the agency car by the east gate. Rows of cars and a box truck make the walk to the admin doors a dogleg." },
    { name: "Admin block", size: "50 x 48, ceiling 4", scale: "tight", text: "Lobby, a corridor that turns four times, the taught kick door into an open-plan office of cubicles and cutouts. Four dead-end rooms hang off it." },
    { name: "Central yard", size: "70 x 72, outdoor", scale: "open", text: "The hub between buildings. Silos, a container and the tank farm fence. You can see the hall, the tank house over its roof and the warehouse shutters you'll come out behind." },
    { name: "Production hall", size: "54 x 44, roof 13", scale: "medium", text: "Presses and a container office on the floor, a machine pit in the middle. Fight across the floor, down through the pit under catwalk Hunters, then climb back and cross over it." },
    { name: "Skybridge", size: "16 long at +8", scale: "tight", text: "Enclosed, windows both sides. A breather over the service lane." },
    { name: "Tank house", size: "40 x 32, roof 16", scale: "vertical", text: "Enter at the top and spiral down past two vats: +8 between them, +4 round the west wall, the floor, then stairs to the basement." },
    { name: "Service tunnels", size: "3 wide, 3.5 clear", scale: "tight", text: "Winding, with a T to the pump room. The pit tunnel from the hall arrives there too: the short way, which skips the catwalks, skybridge and tank house." },
    { name: "Plant room", size: "50 x 50, pit at -4", scale: "arena", text: "The climax. Up from the pit floor to the tiled ring, the machine walk at +4, then its roof at +8 to set the last charge." },
    { name: "Warehouse", size: "64 x 56, roof 13", scale: "maze", text: "Escape part one. In high, down the east catwalks, through a container maze to the dock. A secret sits in plain view with no time to take it." },
    { name: "Truck yard", size: "74 x 90, outdoor", scale: "open", text: "Escape part two. Drop off the dock, weave the trailers, out through the gate to the agency car." },
  ];

  P.decisions = [
    "Catwalks stay 2.0 wide for the first playtest. A Rammer can't follow you up there. Widen later if play says so.",
    "No room exists just to show a building off early. A good exterior, seen through windows or from the lot, is enough. Smoke, fires and junk round the plant room can mark where the business end is.",
    "The skybridge and tank house are the golden path because they are the longer way, and par comes from them. The pit tunnel is the short way: quicker, but you miss what is up there.",
    "Machine climax: break four coolant pipes while waves come in, kicks and shots both count. The last one sends the machine critical and opens the high exit.",
    "The plant room is a large arena, so the way back seals as the fight starts. A small arena would only seal once the job is done.",
    "If the escape countdown runs out, log it and end the run for now. Losing will restart the level once that exists.",
    "Enemies that start on a different level from the fight must be ranged. Hunters can start anywhere they can see; melee enemies start on the player's level.",
    "After playtest 1: all six coolant pipes are on the machine, the escape gets a lit end zone and 65 seconds, and the pit tunnel door hides behind the drum washers, with catwalk Hunters drawing players up.",
  ];

  P.questions = [
    "Storeys every 4.0: stairs are 12 long and a catwalk leaves 3.7 underneath, room for a Hunter at 3.2. Enough height difference?",
  ];
})();
