// Who is in the factory, and what's on the walls: cutout Johns, placed enemies, ambushes,
// signs, painted bay labels and window bands. Points are [x, z, y]. face is the way a thing
// looks: s is +z, n is -z, e is +x, w is -x.
//
// Rules: melee enemies start on the level they fight on with a straight line to the
// player; anything that starts off that level is a Hunter. Johns and enemies stay clear of
// blockers, and Johns stay off the golden path. check.js checks all of it.
(() => {
  const P = window.PLAN;
  const j = (x, z, y, face, where) => ({ at: [x, z, y], face, where });
  const e = (kind, x, z, y, where) => ({ kind, at: [x, z, y], where });

  P.johns = [
    j(-75, 50, 0, "s", "Lot, by the admin doors"), j(-65, 50, 0, "s", "Lot, by the admin doors"),
    j(-53, 91, 0, "e", "Lot, by the van"), j(2, 71.5, 0, "s", "Lot, guard booth"),
    j(-50, 74.5, 0, "n", "Lot, between the rows"), j(-86, 90, 0, "e", "Lot, far corner"),

    j(-68, 35.8, 0, "s", "Lobby, reception"), j(-77, 45.5, 0, "s", "Lobby, greeter"),
    j(-56, 38, 0, "w", "Waiting room"), j(-53, 44, 0, "w", "Waiting room"),
    j(-94, 45.5, 0, "n", "Break room, lunch"), j(-97.5, 40, 0, "e", "Break room, vending"),
    j(-96.4, 13, 0, "e", "Corridor stub to records"),
    j(-69, 19, 0, "s", "Office, cubicle"), j(-65, 29, 0, "n", "Office, back wall"),
    j(-51.5, 13, 0, "w", "Office, cubicle"), j(-73, 3, 0, "e", "Office, by the kick door"),
    j(-66, 11, 0, "n", "Office, cubicle"), j(-57, 26, 0, "w", "Office, cubicle"),
    j(-55, 1.2, 0, "s", "Manager's office, behind the desk"),

    j(-38.5, -6.5, 0, "s", "Yard, forklift driver"), j(-46, -19.5, 0, "e", "Yard, by the skip"),

    j(-23, -33.6, 0, "s", "Hall, press A"), j(-17.5, -43.5, 0, "s", "Hall, press B"),
    j(-44, -61.8, 0, "n", "Hall, conveyor"), j(-36, -61.8, 0, "n", "Hall, conveyor"), j(-30, -61.8, 0, "n", "Hall, conveyor"),
    j(-53, -62, 0, "e", "Hall, hoppers"), j(-39, -31, 0, "s", "Hall, container office"), j(-45, -29.5, 0, "s", "Hall, crates"),
    j(-43, -57, -4, "w", "Pit, drum washer"), j(-28, -45, -4, "n", "Pit, drum washer"),
    j(-37, -53, 4, "e", "Tower ring"), j(-14, -33, 4, "n", "Foreman's office"),

    j(-35, -90, 4, "n", "Tank house, SW landing"), j(-38.5, -98.5, 0, "n", "Tank house, valve wall"), j(-8, -94.3, 0, "n", "Tank house, pump skid"),
    j(11, -80.5, -4, "w", "Pump room"),
    j(68, -115, 0, "n", "Plant ring, control desk"), j(24, -96, 0, "e", "Plant ring, west"),
    j(47, -120, 0, "s", "Plant ring, north"), j(24, -84, 0, "e", "Plant ring, south-west"),

    j(30, -42.6, 0, "s", "Warehouse, portable office"), j(52, 2, 1.2, "w", "Loading dock"),
    j(62, 2, 1.2, "w", "Loading dock"), j(22, 93, 0, "w", "Truck yard, waving you off"),
  ];

  P.enemies = [
    e("fodder", -78, 70, 0, "Lot"), e("fodder", -86, 67, 0, "Lot"), e("fodder", -44, 93, 0, "Lot"),
    e("fodder", -62, 93, 0, "Lot"), e("fodder", -24, 72, 0, "Lot"), e("fodder", -56, 53, 0, "Lot"),
    e("hunter", -60, 45, 4.9, "Admin roof, over the lot"),

    e("fodder", -64, 44, 0, "Lobby"), e("fodder", -57.5, 42, 0, "Waiting room"), e("fodder", -92, 37, 0, "Break room"),
    e("fodder", -85, 30, 0, "Corridor"), e("fodder", -95.5, 21, 0, "Corridor"), e("fodder", -86, 11, 0, "Corridor"),
    e("fodder", -70, 24, 0, "Office"), e("fodder", -54, 24, 0, "Office"), e("fodder", -68, 3, 0, "Office"),
    e("fodder", -58, 18, 0, "Office"), e("rammer", -72, 26, 0, "Office"), e("fodder", -57, 6, 0, "Manager's office"),

    e("fodder", -20, 32, 0, "Yard"), e("fodder", -10, 40, 0, "Yard"), e("fodder", -8, 12, 0, "Yard"),
    e("fodder", -30, -4, 0, "Yard"), e("fodder", 4, 2, 0, "Yard"), e("fodder", 8, -18, 0, "Yard"),
    e("fodder", -2, -22, 0, "Yard"), e("fodder", 14, 36, 0, "Yard"), e("rammer", -4, 42, 0, "Yard"),
    e("rammer", 10, -6, 0, "Yard"), e("hunter", -36, 7.25, 2.6, "Yard, on the container"),
    e("hunter", 23, -14, 13.4, "Warehouse roof, over the yard"),

    e("hunter", -45, -69, 4, "Hall north catwalk, over the pit"), e("hunter", -61, -52, 4, "Hall west catwalk"),
    e("hunter", -18.5, -60, 8, "Hall high gantry"), e("hunter", -37, -47, 4, "Hall tower ring"),
    e("fodder", -24, -30, 0, "Hall floor"), e("fodder", -14, -62, 0, "Hall floor"), e("fodder", -20, -67, 0, "Hall floor"),
    e("fodder", -52, -34, 0, "Hall floor"), e("fodder", -56, -40, 0, "Hall floor"), e("fodder", -51, -65, 0, "Hall floor"),
    e("fodder", -10, -30, 0, "Hall floor"), e("fodder", -30, -68.5, 0, "Hall floor, under the catwalk"),
    e("rammer", -14, -66, 0, "Hall floor"), e("rammer", -44, -40, 0, "Hall floor"),
    e("fodder", -11, -36, 4, "Foreman's office"),

    e("fodder", -49, -76, 0, "Service lane"), e("fodder", -36, -78, 0, "Service lane"),
    e("fodder", -18.5, -83, 8, "Skybridge"),
    e("fodder", -19, -115, 8, "Tank house, north landing"), e("fodder", -17, -115.5, 8, "Tank house, north landing"),
    e("hunter", -38, -104, 4, "Tank house, west catwalk"), e("hunter", -36, -115, 4, "Tank house, NW landing"),

    e("fodder", 7, -108, -4, "Service tunnel"), e("fodder", 8, -97, -4, "Service tunnel"), e("fodder", 17, -96, -4, "Service tunnel"),
    e("rammer", 18, -104.5, -4, "Service tunnel, last corner"), e("fodder", 4, -75, -4, "Pump room"),
    e("fodder", -56, -72, -4, "Pit tunnel"), e("fodder", -11, -80, -4, "Pit tunnel"),

    e("fodder", 80, -61, 4, "Warehouse north catwalk"), e("fodder", 83, -52, 4, "Warehouse east catwalk"),
    e("fodder", 70, -22, 0, "Warehouse"), e("fodder", 62, -42, 0, "Warehouse"), e("fodder", 44, -44, 0, "Warehouse"),
    e("fodder", 32, -30, 0, "Warehouse"), e("fodder", 74, -8, 0, "Warehouse"), e("fodder", 48, -30, 0, "Warehouse"),
    e("hunter", 53, -24, 5.2, "Warehouse, on the double stack"), e("hunter", 57.25, -52, 5.2, "Warehouse, on the double stack"),
    e("rammer", 66, -40, 0, "Warehouse"), e("rammer", 40, -12, 0, "Warehouse"),
    e("fodder", 50, 30, 0, "Truck yard"), e("fodder", 62, 46, 0, "Truck yard"), e("fodder", 30, 62, 0, "Truck yard"), e("fodder", 58, 80, 0, "Truck yard"),
  ];

  // Dead ends that bite on the way out. trigger is [centre, size]; fodder climbs out at spawn.
  P.ambushes = [
    { name: "Bin alley", trigger: { at: [-94, -13, 1.5], size: [10, 3, 18] }, spawn: [-54, -13, 0], count: 4 },
    { name: "Machine pit", trigger: { at: [-38, -57, -2.5], size: [6, 3, 6] }, spawn: [-30, -44, -4], count: 4 },
    { name: "Tank house floor", trigger: { at: [-21, -91, 1.5], size: [6, 3, 5] }, spawn: [-4, -89, 0], count: 4 },
  ];

  // Secrets: never signposted. reward is ammo, health or boost; path is the walk in from an
  // open spot, which the secrets test follows; trigger is the counting box [w, d] if not 2.5.
  const secret = (name, x, z, y, reward, path, trigger) => ({ name, at: [x, z, y], reward, path, trigger });
  P.secrets = [
    secret("Guard booth", 2, 68, 0, "ammo", [[7, 72, 0], [7, 68, 0], [2, 68, 0]]),
    secret("Behind the last rack", -95, 1.5, 0, "health", [[-95.5, 14, 0], [-95.5, 8.5, 0], [-99.1, 8.5, 0], [-99.1, 1.5, 0], [-95, 1.5, 0]]),
    secret("Gas cage", -3, -13, 0, "ammo", [[-3, -21, 0], [-3, -13, 0]]),
    secret("Behind the alley skip", -81, -23, 0, "health", [[-88, -16, 0], [-86, -23, 0], [-81, -23, 0]]),
    secret("Container office", -40, -35, 0, "ammo", [[-48, -40, 0], [-47, -35, 0], [-40, -35, 0]]),
    secret("Behind the lane crates", -49, -85, 0, "health", [[-55, -76, 0], [-54, -85, 0], [-49, -85, 0]]),
    secret("Behind vat A", -37, -116, 0, "ammo", [[-30, -93, 0], [-35.5, -97, 0], [-35.5, -110, 0], [-37, -116, 0]]),
    secret("Behind the plant tanks", 23, -121, 0, "health", [[26, -110, 0], [23.1, -114, 0], [23.1, -121, 0]]),
    secret("Container facing the wall", 31, -16.75, 0, "health", [[21.2, -26, 0], [21.2, -16.75, 0], [31, -16.75, 0]], [2, 1.6]),
    secret("Open trailer", 71.5, 42.8, 0, "boost", [[71.5, 49, 0], [71.5, 42.8, 0]], [1.8, 2.2]),
  ];

  // Signs: text, where, width, face, style. Styles are set in the builder.
  const s = (text, x, z, y, width, face, style, height) => ({ text, at: [x, z, y], width, face, style, height: height || 1.1 });
  P.signs = [
    s("TOTALLY NORMAL MANUFACTURING", -86, 48.3, 3.4, 12, "s", "corporate", 1.2),
    s("STAFF PARKING  ·  ALL STAFF: JOHN", -8, 82, 2.0, 7, "e", "corporate", 0.9),
    s("WELCOME, FELLOW HOOMANS", -70, 34.3, 3.2, 10, "s", "corporate", 1.0),
    s("EMPLOYEE OF THE MONTH", -50.3, 41, 3.4, 6, "w", "office", 0.7),
    s("JOHN", -50.3, 39, 2.3, 1.2, "w", "frame", 1.0), s("JOHN", -50.3, 41, 2.3, 1.2, "w", "frame", 1.0), s("JOHN", -50.3, 43, 2.3, 1.2, "w", "frame", 1.0),
    s("OXYGEN BREAK AREA", -94, 34.3, 3.2, 8, "s", "office", 0.9),
    s("EXIT  →", -96.7, 27, 2.4, 2.6, "e", "wrong", 0.7),
    s("HOOMAN WORKING STATIONS", -60, 12, 3.5, 7, "w", "office", 0.8),
    s("MANAGER: JOHN", -55.5, 8.3, 3.7, 3, "s", "office", 0.6),
    s("RECORDS (NORMAL)", -95.5, 10.3, 3.8, 3, "s", "office", 0.6),
    s("AUTHORIZED JOHNS ONLY", -12, 47.35, 2.0, 6, "s", "hazard", 0.8),
    s("PRODUCTION HALL: NOW PRODUCING", -30, -25.7, 4.8, 10, "s", "corporate", 1.2),
    s("DEFINITELY NOT SMOG", -2.1, 28, 7, 5, "w", "wrong", 1.0),
    s("DAYS WITHOUT A HOOMAN INCIDENT: 0", -44, -26.3, 5.5, 9, "n", "hazard", 1.0),
    s("PRODUCTION LINE (PRODUCING)", -37, -65, 3.0, 7, "s", "office", 0.8),
    s("PRESS (DO NOT PRESS)", -23, -34.8, 3.5, 5, "s", "hazard", 0.8),
    s("FOREMAN: JOHN", -12, -29.7, 6.5, 5, "s", "office", 0.8),
    s("VAT A: SMOG (ORGANIC)", -28, -95.9, 6, 6, "s", "wrong", 1.0),
    s("VAT B: SMOG (DECAF)", -10, -99.4, 6, 5.5, "s", "wrong", 1.0),
    s("SERVICE TUNNEL (FOR SERVICING)", 3, -109.35, -1.8, 5, "s", "hazard", 0.7),
    s("AIR IMPROVEMENT MACHINE", 51.5, -89.7, 1.5, 5, "s", "corporate", 1.2),
    s("COOLANT PIPES: PLEASE DO NOT KICK", 54.3, -93, -1.2, 4, "e", "hazard", 0.8),
    s("SHIPPING (NOTHING) & RECEIVING (EVERYTHING)", 20.3, -35, 7, 14, "e", "corporate", 1.4),
    s("MIND THE DROP", 46, 5.2, 2.2, 3, "n", "hazard", 0.6),
    s("THANK YOU FOR VISITING, JOHN", 10.35, 89, 2.0, 8, "e", "corporate", 0.9),
  ];

  // JOHN painted on every parking bay, read from the aisle between the rows.
  P.floor_text = P.blockers
    .filter(b => b.name === "Parked car")
    .map(b => {
      const cx = (b.rect[0] + b.rect[2]) / 2, north = b.rect[1] < 70;
      return { text: "JOHN", at: [cx, north ? b.rect[3] + 0.8 : b.rect[1] - 0.8, 0], face: north ? "s" : "n" };
    });

  // Window bands on the fronts people see, so the buildings read as buildings.
  P.windows = [
    { at: [-90, 48.25, 1.8], width: 6, face: "s" }, { at: [-58, 48.25, 1.8], width: 6, face: "s" },
    { at: [-46, -25.75, 8], width: 20, face: "s" }, { at: [-16, -25.75, 8], width: 12, face: "s" },
    { at: [19.75, -18, 8], width: 20, face: "w" },
    { at: [-30, -85.75, 13], width: 12, face: "s" }, { at: [-6, -85.75, 13], width: 8, face: "s" },
  ];
})();
