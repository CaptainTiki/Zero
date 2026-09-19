// Line-of-sight blockers, payoffs, the route and the notes. h is height above the
// blocker's own floor; the player's eye is about 1.6, so anything under 1.8 is see-over.
(() => {
  const P = window.PLAN;
  const b = (name, type, lv, rect, h, note) => ({ name, type, lv, rect, h, note });
  const round = (name, type, lv, c, r, h, note) => ({ name, type, lv, circle: [c[0], c[1], r], h, note });
  // A blocker can start above its storey's floor with y, like a cauldron held up off the pit.

  const cars = [];
  const row = (z, x0, x1, gap) => {
    for (let x = x0; x + 2.2 <= x1; x += 2.9) {
      if (x + 2.2 > gap[0] && x < gap[1]) continue;
      cars.push(b("Parked car", "vehicle", "G", [x, z, x + 2.2, z + 4.6], 1.5));
    }
  };
  // Two rows in front of the admin block, their gaps offset so the walk in is a short dogleg.
  row(58, -96, -52, [-70, -64]);
  row(67, -96, -52, [-64, -60]);

  P.blockers = [
    ...cars,
    b("Van", "vehicle", "G", [-98, 73.5, -92, 76], 2.4),
    { ...b("Guard booth", "building", "G", [-75, 73, -71, 77], 3), hollow: "w" },
    b("Agency car", "vehicle", "G", [-58, 74.8, -53, 77.3], 1.5, "Start."),

    b("Reception desk", "furniture", "G", [-72, 37, -64, 39], 1.1),
    b("Waiting chairs", "furniture", "G", [-58, 45, -52, 47], 1),
    b("Lunch table", "furniture", "G", [-96, 40, -92, 44], 1),
    b("Vending machines", "furniture", "G", [-100, 34, -98, 38], 2),
    // Records (after factory playtest 5, the shelves were too wide to get round): the front
    // rack leaves a 3-wide way round on the west into the aisle between the racks, where the
    // room's ammo is. The back rack runs to the east wall and stops short of the west one, a
    // squeeze to the strip behind it.
    b("Shelving", "rack", "G", [-98.5, 3, -90.2, 4], 2.4, "Stops short of the west wall: a squeeze to the gap behind."),
    b("Shelving", "rack", "G", [-97, 6, -90.2, 7], 2.4, "Leaves a 3-wide way round on the west."),
    b("Cubicles", "furniture", "G", [-72, 12, -66, 18], 1.6),
    b("Cubicles", "furniture", "G", [-64, 22, -58, 28], 1.6),
    b("Cubicles", "furniture", "G", [-58, 10, -52, 16], 1.6),
    b("Filing cabinets", "furniture", "G", [-76, 18, -74, 28], 2.2),
    b("Manager's desk", "furniture", "G", [-58, 2, -53, 4], 1.1),

    b("Shipping container", "container", "G", [-42, 6, -30, 8.5], 2.6, "Blocks the view from the office door to the hall doors."),
    round("Silo", "tank", "G", [2, 23], 4, 14),
    round("Silo", "tank", "G", [12, 18], 4, 14),
    b("Pallets", "crates", "G", [-18, 2, -14, 6], 1.8),
    { ...b("Gas cage", "crates", "G", [-6, -16, 0, -10], 2.5), hollow: "n" },
    b("Forklift", "vehicle", "G", [-40, -12, -37, -8], 2.2),
    b("Skip", "crates", "G", [-48, -24, -44, -21], 1.8, "Stands off the yard's corner walls: a gap behind."),
    b("Crate cache", "crates", "G", [-52, -84, -46, -80], 2.4),
    b("Skip and scaffold", "crates", "G", [-4, -84, 0, -72], 2.5, "Blocks the lane's east end."),
    b("Scaffold", "crates", "G", [-62, -86, -60, -70], 6, "Blocks the lane's west end; the city carries on past it."),

    { ...b("Container office", "container", "G", [-44, -38, -34, -32], 2.8), hollow: "w" },
    { ...b("Crates", "crates", "G", [-50, -32, -46, -28], 3), prop_scene: "res://scenes/props/factory/case_stack_six.tscn" },
    { ...b("Press A", "machine", "G", [-26, -40, -20, -35], 5), prop_scene: "res://scenes/props/factory/press_wide.tscn" },
    { ...b("Press B", "machine", "G", [-20, -50, -15, -45], 5), prop_scene: "res://scenes/props/factory/press_compact.tscn" },
    { ...b("Hoppers", "machine", "G", [-60, -66, -54, -58], 6), prop_scene: "res://scenes/props/factory/feed_hoppers.tscn" },
    { ...b("Conveyor", "machine", "G", [-48, -67, -26, -63], 1.2, "Waist high: stops you, doesn't hide anyone standing."), prop_scene: "res://scenes/props/factory/sorting_conveyor.tscn" },
    { ...b("Drum washer", "machine", "B", [-50, -60, -44, -55], 3, "Supply cases hide the pit tunnel door. Legacy name preserves editor paths."), art: "delivery_stack", prop_scene: "res://scenes/props/factory/delivery_stack_large.tscn" },
    { ...b("Drum washer", "machine", "B", [-50, -49, -45, -46], 3, "Smaller stack of the same supply cases."), art: "delivery_stack", prop_scene: "res://scenes/props/factory/delivery_stack_small.tscn" },
    { ...b("Drum washer", "machine", "B", [-30, -54, -26, -47], 3, "Parked forklift; original reserved footprint."), art: "forklift", prop_scene: "res://scenes/props/factory/parked_forklift.tscn" },
    { ...b("Hopper tower", "machine", "B", [-36, -52, -32, -48], 16, "Rises from the pit floor through both catwalks, like the column in reference 3."), prop_scene: "res://scenes/props/factory/feed_tower.tscn" },

    round("Vat A", "tank", "G", [-28, -102], 6, 14),
    round("Vat B", "tank", "G", [-10, -104], 4.5, 12),
    b("Pump skid", "machine", "G", [-14, -98, -8, -95], 2),
    b("Valve wall", "machine", "G", [-40, -110, -37, -100], 3),
    b("Pumps", "machine", "B", [2, -82, 6, -79], 2),

    // Mixing station (after factory playtest 5): vats at 1.55, just under eye height, so you can
    // see over them and enemies crouch out of a standing shot. Round, so a chase slides round them.
    round("Mixing vat", "tank", "B", [-25, -137], 2, 1.55), round("Mixing vat", "tank", "B", [-17, -137], 2, 1.55),
    round("Mixing vat", "tank", "B", [-9, -137], 2, 1.55), round("Mixing vat", "tank", "B", [-1, -137], 2, 1.55),
    round("Mixing vat", "tank", "B", [-25, -145], 2, 1.55), round("Mixing vat", "tank", "B", [-1, -145], 2, 1.55, "Stands in front of the east door."),
    round("Mixing vat", "tank", "B", [-25, -153], 2, 1.55), round("Mixing vat", "tank", "B", [-17, -153], 2, 1.55),
    round("Mixing vat", "tank", "B", [-9, -153], 2, 1.55), round("Mixing vat", "tank", "B", [-1, -153], 2, 1.55),
    round("Mixer drive", "machine", "B", [-13, -145], 3, 12, "Floor to roof, in line with the door, so the room isn't one view."),

    // Compressor hall: five pump housings on the north wall, each under a frame whose ram drives
    // down and creeps back up (P.pumps). Waist-high intercoolers and two tall receivers on the floor.
    b("Pump housing", "machine", "B", [19, -160, 24, -156], 2), b("Pump housing", "machine", "B", [28, -160, 33, -156], 2),
    b("Pump housing", "machine", "B", [37, -160, 42, -156], 2), b("Pump housing", "machine", "B", [46, -160, 51, -156], 2),
    b("Pump housing", "machine", "B", [55, -160, 60, -156], 2),
    b("Intercooler", "machine", "B", [30, -146, 40, -143], 2.2), b("Intercooler", "machine", "B", [42, -140, 50, -137], 2.2, "Between the west door and the way out."),
    round("Receiver tank", "tank", "B", [22, -134], 2.5, 7), round("Receiver tank", "tank", "B", [58, -136], 2.5, 7),

    // The smog machine (after factory playtest 4): a potbelly cauldron on one central column,
    // so from the pit you can see under it to every arm. A cylinder stands in for the belly
    // until polish.
    round("Machine column", "machine", "B", [47, -97], 3, 6, "Holds the cauldron up. Open floor all round it."),
    { ...round("Smog cauldron", "machine", "B", [47, -97], 7, 6, "Potbelly, faked as a cylinder: +2 up to its rim, the roof walkway at +8."), y: 2 },
    round("Coolant stack", "machine", "C2", [47, -97], 4, 4.6, "Rises from the machine's roof. The ACTIVATE button is on its north side."),
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
    { ...b("Loose supply case", "crates", "G", [-52.4, -31.7, -50.4, -29.7], 1.4, "Single case beside the six-case stack."), art: "loose_case", prop_scene: "res://scenes/props/factory/loose_supply_case.tscn" },
  ];

  // Compressor pumps over the housings above. Each ram drives down in half a second, hisses
  // steam as it bottoms out, then creeps back up over the rest of its period. Visual only.
  P.pumps = [21.5, 30.5, 39.5, 48.5, 57.5].map((x, i) => ({ at: [x, -158, -2], width: 5, depth: 4, period: 5, phase: i * 0.8 }));

  // Dead ends and what they pay. type: ammo | health | secret | enemy
  P.payoffs = [
    { at: [-54, 39], lv: "G", types: ["ammo"], where: "Waiting room" },
    { at: [-93.5, 5], lv: "G", types: ["ammo"], where: "Records, the aisle between the racks" },
    { at: [-94, 37.5], lv: "G", types: ["enemy", "health"], where: "Break room" },
    { at: [-52, 5.5], lv: "G", types: ["enemy", "ammo"], where: "Manager's office" },
    { at: [-12, -35], lv: "C1", types: ["ammo", "health"], where: "Foreman's office, after the hall fight" },
    { at: [-49, -77], lv: "G", types: ["enemy", "ammo"], where: "Service lane crate cache" },
    { at: [10.5, -78], lv: "B", types: ["health", "ammo"], where: "Pump room, the end of the leg that used to carry on to the plant room" },
    { at: [26, -158.5], lv: "B", types: ["ammo"], where: "Compressor hall, the nook between the first two pumps" },
    { at: [26, -110], lv: "G", types: ["ammo"], where: "Plant ring, behind the tanks" },
    { at: [75, 37], lv: "G", types: ["ammo"], where: "Beside the open trailer, a step off the escape" },
  ];

  // Golden path, in order. Points are [x, z, y].
  P.route = [
    { name: "Parking lot", pts: [[-55.5, 73, 0], [-61.5, 70, 0], [-62, 65, 0], [-66, 60, 0], [-68, 52, 0], [-70, 49, 0]] },
    { name: "Admin block", pts: [[-70, 49, 0], [-70, 44, 0], [-80, 39.5, 0], [-85, 39.5, 0], [-85, 27, 0], [-95.5, 27, 0], [-95.5, 18, 0], [-86, 18, 0], [-86, 8, 0], [-76, 8, 0], [-62, 6, 0], [-62, 20, 0], [-56, 19.5, 0], [-50, 19.5, 0]] },
    { name: "Central yard", pts: [[-50, 19.5, 0], [-38, 20, 0], [-26, 8, 0], [-14, -6, 0], [-24, -18, 0], [-30, -26, 0]] },
    { name: "Hall floor and pit", pts: [[-30, -26, 0], [-18, -31, 0], [-12, -40, 0], [-12, -52, 0], [-24, -58.5, 0], [-36, -58.5, -4], [-40, -55, -4], [-40, -43.5, -4], [-52, -43.5, 0], [-60.75, -29, 0]] },
    { name: "Hall catwalks", pts: [[-60.75, -29, 0], [-60.75, -42, 4], [-61, -69, 4], [-34, -69, 4], [-34, -54, 4], [-31, -53, 4], [-31, -49.5, 4], [-30, -50, 4], [-20, -50, 8], [-18.5, -52, 8], [-18.5, -69, 8], [-18.5, -70, 8]] },
    { name: "Skybridge", pts: [[-18.5, -70, 8], [-18.5, -86, 8]] },
    { name: "Tank house", pts: [[-18.5, -86, 8], [-18.5, -114, 8], [-21, -115, 8], [-33, -115, 4], [-38, -112, 4], [-38, -92, 4], [-33, -91, 4], [-21, -91, 0], [-12, -92.5, 0], [-3, -92, 0], [-3, -104, -4]] },
    { name: "North tunnel", pts: [[-3, -104, -4], [-3, -108, -4], [-9, -108, -4], [-9, -121, -4], [-13, -121, -4], [-13, -130, -4]] },
    { name: "Mixing station", pts: [[-13, -130, -4], [-13, -140.5, -4], [-21, -140.5, -4], [-21, -149, -4], [-13, -149.5, -4], [-5, -149, -4], [-5, -141, -4], [3, -141, -4], [3, -146, -4], [6, -146, -4]] },
    { name: "Compressor hall", pts: [[6, -146, -4], [11, -146, -4], [11, -140, -4], [16, -140, -4], [24, -140, -4], [28, -151, -4], [54, -151, -4], [58, -143, -4], [52, -135, -4], [47, -132, -4], [47, -130, -4]] },
    { name: "Plant room", pts: [[47, -130, -4], [47, -114, -4], [44, -110, -4], [40, -102, -4], [38, -95, -4], [42, -87, -4], [52, -86, -4], [50, -83.5, -4], [52, -81.5, -4], [64, -81.5, 0], [68, -80, 0], [68, -92, 4], [68, -97, 4], [55, -97, 4], [55, -107, 4], [39, -107, 4], [39, -92, 4], [39, -80, 8], [39, -78.75, 8], [47.25, -78.75, 8], [47.25, -91.5, 8], [43.1, -93.1, 8], [41.5, -97, 8], [43.1, -100.9, 8], [47, -102.8, 8], [50.9, -100.9, 8], [52.5, -97, 8], [50.9, -93.1, 8], [47.25, -91.5, 8]] },
    { name: "Escape: warehouse", escape: true, beat: [47.25, -66, 8], pts: [[47.25, -91.5, 8], [47.25, -62, 8], [48, -61, 8], [50, -61, 8], [62, -61, 4], [83, -61, 4], [83, -40, 4], [83, -28, 0], [76, -18, 0], [66, -18, 0], [60, -36, 0], [48, -40, 0], [40, -24, 0], [36, -10, 0], [36, -6, 0]] },
    { name: "Escape: dock and trucks", escape: true, pts: [[36, -6, 0], [36, -2.5, 1.2], [36, 2, 1.2], [38, 5, 1.2], [38, 10, 0], [38, 30, 0], [54, 40, 0], [62, 47, 0]] },
  ];

  // Weapons, and supplies on the golden path where damage builds up. Pickups on the path
  // wait for a player who is full, so they are there when needed. Points are [x, z, y].
  P.pickups = [
    { kind: "gun", at: [-68, 42, 0], where: "Lobby, by the reception desk" },
    { kind: "shotgun", at: [-38, -29, 0], where: "Hall, inside the doors" },
    { kind: "health", at: [-14, -89, 0], where: "Tank house floor, after the ambush" },
    { kind: "health", at: [47, -125, -4], where: "Plant tunnel, before the pit" },
    { kind: "ammo", at: [47, -119.5, -4], where: "Plant tunnel, before the pit" },
    { kind: "health", at: [41, -113, -4], where: "Plant pit floor, north wall, west of the door" },
    { kind: "ammo", at: [48, -82, -4], where: "Plant pit floor, south wall under the exit bridge" },
  ];

  // The plant room climax, pressure arms (user's design, September 16, 2026). Points are [x, z, y].
  // Six arms reach out from shoulders on the machine's roof edge, bend at an elbow, and plug
  // their coolant pipe into a socket in the pit floor. Numbered clockwise from north.
  //   1. Walk into the pit: a pipe crashes across the tunnel door behind you and the machine hisses.
  //   2. Pressure builds (hiss, steam leaks). The next arm's beacon spins and the alarm sounds,
  //      then it comes down and plugs in. The beacon sits on the elbow, well above head height.
  //   3. Break its pipe, kicks or shots. The arm lifts, steam from both broken ends.
  //   4. Its wave climbs out round the pit.
  //   5. The next arm comes down once the wave is dead, or when pressure forces it.
  //   6. After the sixth pipe the Commander sends you up to the button. Kick it: critical.
  // A pipe can only be hurt while its arm is down. Arms come down in order, so the fight
  // keeps moving round the machine.
  P.setpiece = {
    name: "Pressure arms",
    start: { at: [47, -95.5, -2], size: [34, 4, 31], note: "The pit floor from 3 in from the north wall, so the seal in the tunnel never lands on the player." },
    // Lies across the plant tunnel, along x, just inside its door.
    seal: { at: [47, -115.8, -2.4], radius: 1.6, length: 3.2, along: "x" },
    respawn: [38, -110, -3.5],
    // Evenly round the cauldron's rim every 60 degrees, turned 15 off north so none drops
    // through the exit bridge (south) or the bridge from the east landing (east).
    arms: [
      { n: 1, shoulder: [48.8, -103.8, 8], elbow: [50.5, -110, 7], socket: [50.6, -110.5, -4], where: "North-north-east" },
      { n: 2, shoulder: [53.8, -98.8, 8], elbow: [60, -100.5, 7], socket: [60.5, -100.6, -4], where: "East-north-east" },
      { n: 3, shoulder: [51.9, -92.1, 8], elbow: [56.5, -87.5, 7], socket: [56.9, -87.1, -4], where: "South-east" },
      { n: 4, shoulder: [45.2, -90.2, 8], elbow: [43.5, -84, 7], socket: [43.4, -83.5, -4], where: "South-south-west, beside the exit bridge" },
      { n: 5, shoulder: [40.2, -95.2, 8], elbow: [34, -93.5, 7], socket: [33.5, -93.4, -4], where: "West-south-west" },
      { n: 6, shoulder: [42.1, -101.9, 8], elbow: [37.5, -106.5, 7], socket: [37.1, -106.9, -4], where: "North-west" },
    ],
    // Struts from the cauldron's shoulder up to the plant room ceiling, between the arms and
    // clear of the exit bridge. Visual only, all above head height.
    irons: [
      { from: [51.9, -101.9, 7], to: [54.8, -104.8, 13] },
      { from: [53.8, -95.2, 7], to: [57.6, -94.2, 13] },
      { from: [42.1, -92.1, 7], to: [39.2, -89.2, 13] },
      { from: [40.2, -98.8, 7], to: [36.4, -99.8, 13] },
    ],
    order: [1, 3, 5, 2, 4, 6],
    // A lifted arm raises its elbow straight up this far, so the pipe's foot hangs 5 above the
    // pit floor, out of reach. check.js checks both poses against the walkways.
    lift: 5,
    first_arm_seconds: 4,
    pressure_seconds: 45,
    // How long the next arm's beacon spins and the alarm sounds before it drops.
    warning_seconds: 3,
    // One wave per pipe for the first five, [fodder, hunters, rammers, brutes]. The sixth sends none.
    // Everything fights on the pit floor, so every Rammer is a real one: one a wave, two in the last.
    // A brute climbs out with the third wave and the last.
    waves: [[5, 0, 1, 0], [5, 0, 1, 0], [5, 0, 1, 1], [5, 0, 1, 0], [5, 0, 2, 1]],
    line_last_pipe: "COMMANDER: Now find the button to lock it in.",
    button: { at: [47, -101.6, 8], face: "n", sign: "ACTIVATE", where: "Roof, on the coolant stack's north side" },
    // Melee hatches are used by level. Six round the pit floor, between the sockets; the ring,
    // walk and gantry ones only matter if the player climbs during a wave.
    melee_hatches: [
      [33, -111, -4], [61, -111, -4], [62.5, -97, -4], [61, -86.5, -4], [33, -83, -4], [31.5, -97, -4],
      [62, -118, 0], [32, -118, 0], [26, -76, 0], [68, -76, 0],
      [39, -107, 4], [47, -107, 4], [55, -107, 4], [55, -100, 4],
      [38, -78.75, 8], [44, -78.75, 8], [47.25, -84, 8],
    ],
    exit: { at: [47.25, -72, 9.6], size: [2.6, 3.3, 0.5] },
    vents: [[50.9, -100.9, 8.2], [50.9, -93.1, 8.2], [43.1, -93.1, 8.2], [43.1, -100.9, 8.2], [47, -97, 12.8], [40, -97, -4], [54, -97, -4]],
    escape_seconds: 90,
    // Out of the building (after factory playtest 5): dropping off the dock into the truck yard
    // stops the countdown. Then the factory goes up behind you, and the truck yard is yours to
    // fight and search until you walk onto the pad. outside is the truck yard box, [x, z, y]
    // centre and [x, y, z] size, starting just past the dock edge.
    outside: { at: [52, 29.25, 1.8], size: [64, 3.6, 45.5] },
    line_out: "COMMANDER: You're clear. Pickup's at the gate when you want it.",
    // What the player sees and hears from the truck yard: booms (a fireball, a flash, a shake)
    // and smoke columns that rise above the roofline, delay seconds after getting out. After
    // the last one, a distant boom from one of the boom spots every few seconds.
    finale: [
      { kind: "boom", at: [30, -20, 13.4], delay: 0.4, size: 6, where: "Warehouse roof, west" },
      { kind: "boom", at: [74, -44, 13.4], delay: 1.4, size: 7, where: "Warehouse roof, east" },
      { kind: "boom", at: [36, -7.5, 2], delay: 2.3, size: 4, where: "The roller door you came out of" },
      { kind: "smoke", at: [47, -97, 13.4], delay: 2.5, where: "Plant room roof" },
      { kind: "boom", at: [52, -30, 13.4], delay: 3.6, size: 9, where: "Warehouse roof, centre" },
      { kind: "smoke", at: [40, -30, 13.4], delay: 3.8, where: "Warehouse roof" },
      { kind: "boom", at: [47, -97, 14], delay: 5.0, size: 12, where: "Plant room, the cauldron going" },
      { kind: "smoke", at: [-20, -102, 16.4], delay: 6.0, where: "Tank house roof" },
    ],
    // Once the machine is critical the place falls apart round the escape. A fall drops a pipe,
    // beam or crate to rest at [x, z, y] with size [x, y, z]; steam jets up for a few seconds.
    // With no trigger they happen on a delay after critical; with one, when the player comes
    // within radius. Every fall leaves the golden path clear, which check.js confirms.
    escape_events: [
      { kind: "fall", at: [58, -113, -3.6], size: [6, 0.8, 0.8], delay: 1.0, where: "Pit floor" },
      { kind: "fall", at: [26, -100, 0.4], size: [0.8, 0.8, 6], delay: 2.2, where: "Plant ring" },
      { kind: "fall", at: [38, -108.5, -3.6], size: [4, 0.8, 0.8], delay: 3.4, where: "Pit floor" },
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
    { name: "Short way: pit tunnel", split: [-40, -55, -4], join: [-3, -108, -4],
      pts: [[-40, -55, -4], [-43, -53, -4], [-51, -53, -4], [-51, -58, -4], [-56, -58, -4], [-56, -74, -4], [-30, -74, -4], [-30, -80, -4], [-10, -80, -4], [-10, -76, -4], [0, -76, -4], [8, -78, -4], [8, -84, -4], [8, -96, -4], [8, -108, -4], [-3, -108, -4]] },
  ];

  P.spaces = [
    { name: "Parking lot", size: "50 x 30, outdoor", scale: "open", text: "Start at the agency car in front of the admin block. Two rows of cars with offset gaps make the short walk to the doors a dogleg." },
    { name: "Admin block", size: "50 x 48, ceiling 4", scale: "tight", text: "Lobby, a corridor that turns four times, the taught kick door into an open-plan office of cubicles and cutouts. Four dead-end rooms hang off it." },
    { name: "Central yard", size: "70 x 56, outdoor", scale: "open", text: "The hub between buildings. Silos, a container and the tank farm fence. You can see the hall, the tank house over its roof and the warehouse shutters you'll come out behind." },
    { name: "Production hall", size: "54 x 44, roof 13", scale: "medium", text: "Presses and a container office on the floor, a machine pit in the middle. Fight across the floor, down through the pit under catwalk Hunters, then climb back and cross over it." },
    { name: "Skybridge", size: "16 long at +8", scale: "tight", text: "Enclosed, windows both sides. A breather over the service lane." },
    { name: "Tank house", size: "40 x 32, roof 16", scale: "vertical", text: "Enter at the top and spiral down past two vats: +8 between them, +4 round the west wall, the floor, then stairs to the basement." },
    { name: "Service tunnels", size: "3 wide, 3.5 clear", scale: "tight", text: "A T at the foot of the tank house stair: right to the pump room, left and north to the mixing station. The pit tunnel from the hall arrives at the pump room: the short way, which skips the catwalks, skybridge and tank house, and still has to come back to the T." },
    { name: "Mixing station", size: "36 x 28, floor at -4", scale: "maze", text: "A grid of mixing vats at 1.55, just under eye height, round a floor-to-roof mixer drive. You see heads over the vats but not a clean shot, so you weave the aisles to the east door. A Rammer at the back." },
    { name: "Compressor hall", size: "46 x 30, floor at -4, roof 10", scale: "medium", text: "Five compressor pumps along the north wall drive down, hiss steam and creep back up. Intercoolers and two receiver tanks on the floor, a Rammer among them, ammo in a nook between the pumps. The south door is a straight tunnel to the plant room." },
    { name: "Plant room", size: "50 x 50, pit at -4", scale: "arena", text: "The climax. A potbelly cauldron on one column, open underneath, so every arm can be seen from the pit. Six arms reach from its rim into the pit floor. One at a time an arm plugs its coolant pipe in; break it and a wave climbs out. After the sixth, up through the ring and walkways to the roof to kick the button." },
    { name: "Warehouse", size: "64 x 56, roof 13", scale: "maze", text: "Escape part one. In high, down the east catwalks, through a container maze to the dock. A secret sits in plain view with no time to take it." },
    { name: "Truck yard", size: "64 x 46, outdoor", scale: "open", text: "Escape part two. Drop off the dock, weave the trailers, past the open trailer to the gate in the south wall." },
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
    "After playtest 2, Level 1 ramps up the way the story reads: nobody attacks in the lot, lone fodder in the offices, a light first fight in the yard, Hunters from the hall catwalks on. Health sits on the path where damage builds, stairs above ground get side rails, deaths respawn at the last beat line, and machine waves wait a moment and space out.",
    "Outdoor spaces cut down after playtest 2 (user's markup): the lot is only the front of the admin block, the yard stops at z 30, the truck yard stops past the container stack, and the bin alley is gone. The start no longer sits by the exit gate; the level ends at the gate either way.",
    "The machine is a potbelly cauldron on a single column (user, after playtest 4), since playtest 4 spent up to 24 s finding an arm behind the old square machine. Arms sit evenly round its rim, with iron struts from the cauldron to the ceiling.",
    "Level 1's enemy mix (user): about 75% fodder, 20% Rammers, 5% Hunters. No Rammer before halfway; the first is a lone ambush on the tank house floor. Hunters only on the escape, so the hall catwalks and the machine's waves have none.",
    "Two rooms north of the tank house and plant room (user, after playtest 5): left at the foot of the tank house stair to a mixing station, then a compressor hall, then a straight tunnel into the plant pit from the north. The pit's west tunnel door is gone. The short way still comes through the pump room and back to the T, skipping the hall catwalks, skybridge and tank house.",
    "Brutes are area denial, not duels (user, playtest 6). This is the first mission and a player who knows to avoid them should get to; they come into their own later, twelve to an arena with a rocket launcher. Left as they are, only sped up to half the player's walk (3.0).",
    "The tunnel leg that used to carry on to the plant room ends at the pump room. Trimming it left a wall baked across the join, which read as a dead end in playtest 6; it is one corridor now. It also pays (user): health and ammo, and a brute walks into the tunnel behind you. The leg stays because the pit tunnel shortcut joins there.",
    "Machine climax after playtest 3 (user's design): six pressure arms plug their coolant pipes into the pit floor one at a time, in the order 1, 3, 5, 2, 4, 6 so the fight keeps moving round the machine. Break a pipe, its arm lifts and a wave climbs out; the next arm comes down when the wave is dead or after 45 seconds of pressure, warned by a spinning beacon on its elbow and an alarm. Waves are five fodder and a Rammer, two Rammers in the last. After the sixth pipe, the Commander sends you up to kick the ACTIVATE button, which starts a 90 second escape.",
  ];

  P.questions = [
    "The cauldron is 7 in radius from +2 to its rim at +8, on a column 3 in radius. Big enough to read as the machine, and still easy to see under from anywhere in the pit?",
    "Four irons to the ceiling, or some to the walls? They're visual only either way.",
    "Where a lifted arm's pipe end sits, high enough to read as out of reach. Its pipe can't be hurt while up either way.",
    "Storeys every 4.0: stairs are 12 long and a catwalk leaves 3.7 underneath, room for a Hunter at 3.2. Enough height difference?",
  ];
})();
