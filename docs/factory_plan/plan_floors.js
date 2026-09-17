// Factory complex plan, draft 1. World units: x east, z south (Godot z), y up.
// Storeys: B -4 basement, G 0 ground, C1 +4 catwalk, C2 +8 catwalk.
// Rects are [x0, z0, x1, z1]. Polys are [[x, z], ...].
window.PLAN = {
  bounds: [-106, -128, 196, 228],
  rate: 5.85, // units per second walking, from 1,200 units in 3:25
  target: 1200,
  par: 555, // 3x the route test's walk, 3:05 on September 17, 2026 with the cauldron. Re-measure when the route changes.

  // Solid building mass: walls and the space between rooms.
  // h is the roof height; wall and floor are greybox materials for the bake.
  shells: [
    { name: "Admin block", rect: [-100, 0, -50, 48], h: 4.5, wall: "plaster_grey", floor: "plaster" },
    { name: "Production hall", rect: [-62, -70, -8, -26], h: 13 },
    { name: "Tank house", rect: [-40, -118, 0, -86], h: 16 },
    { name: "Plant room", rect: [22, -122, 72, -72], h: 13 },
    { name: "Warehouse", rect: [20, -62, 84, -6], h: 13 },
  ],

  // Floors. kind: outdoor | backdrop (seen, not reachable) | indoor | pit | room (basement) | deck
  zones: [
    // The three outdoor spaces were cut down after playtest 2 (user's markup, September 16):
    // each had been bigger than any building, and walking them before going in and after
    // coming out felt long. The bin alley went altogether.
    { id: "lot", name: "Parking lot", lv: "G", kind: "outdoor", rect: [-100, 48, -50, 78], label: [-98, 77], note: "Just the front of the admin block. The start is a short dogleg from the doors." },
    { id: "truck", name: "Truck yard", lv: "G", kind: "outdoor", rect: [20, 6, 84, 52], label: [22, 51], note: "Ends just past the container stack. The exit gate is in its south wall." },
    { id: "yard", name: "Central yard", lv: "G", kind: "outdoor", rect: [-50, -26, 20, 30], label: [-48, 29] },
    { id: "lane", name: "Service lane", lv: "G", kind: "outdoor", rect: [-62, -86, 0, -70], label: [-44, -75], note: "Behind the hall's kick door. Scaffold blocks the west end, a skip the east. Look up to see the skybridge." },
    { id: "tankfarm", name: "Tank farm", lv: "G", kind: "backdrop", rect: [-8, -70, 20, -26], label: [6, -48], note: "Fenced off. Seen from the yard, never entered." },
    { id: "plantyard", name: "Plant yard", lv: "G", kind: "backdrop", rect: [22, -72, 72, -62], label: [60, -67], note: "Seen below the high catwalk on the escape." },

    { id: "lobby", name: "Lobby", lv: "G", kind: "indoor", rect: [-80, 34, -60, 48], label: [-70, 44.5] },
    { id: "waiting", name: "Waiting room", lv: "G", kind: "indoor", rect: [-60, 34, -50, 48], label: [-55, 36.5], note: "Dead end. Two cutout Johns waiting, ammo behind the chairs." },
    { id: "break", name: "Break room", lv: "G", kind: "indoor", rect: [-100, 34, -88, 48], label: [-94, 46], note: "Dead end. One John on lunch, a health pack." },
    { id: "records", name: "Records", lv: "G", kind: "indoor", rect: [-100, 0, -90, 10], label: [-95, 8.4], note: "Second kick door. Shelving, and a secret behind the last rack." },
    { id: "office", name: "Open-plan office", lv: "G", kind: "indoor", poly: [[-76, 0], [-60, 0], [-60, 8], [-50, 8], [-50, 30], [-76, 30]], label: [-63, 28.2], note: "Cubicles at 1.6 hide crouching cutouts. Filing cabinets at 2.2 break the long view." },
    { id: "manager", name: "Manager", lv: "G", kind: "indoor", rect: [-60, 0, -50, 8], label: [-55, 1.8], note: "Dead end. Manager John and his nameplate." },
    { id: "hall", name: "Production hall", lv: "G", kind: "indoor", rect: [-62, -70, -8, -26], label: [-35, -28.6], note: "54 x 44, roof at 13. Presses and a container office on the floor, a machine pit in the middle, catwalks at +4 and +8." },
    { id: "tank", name: "Tank house", lv: "G", kind: "indoor", rect: [-40, -118, 0, -86], label: [-8, -88.6], note: "40 x 32, roof at 16. Entered at the top, left at the bottom." },
    { id: "plant", name: "Plant room", lv: "G", kind: "indoor", rect: [22, -122, 72, -72], label: [47, -119.4], note: "50 x 50. A tiled ring at ground round a machine pit." },
    { id: "warehouse", name: "Warehouse", lv: "G", kind: "indoor", rect: [20, -62, 84, -6], label: [30, -9.4], note: "64 x 56, roof at 13. Container maze. Only used by the escape." },
    { id: "dock", name: "Loading dock", lv: "G", kind: "indoor", rect: [20, -6, 84, 6], h: 5, y: 1.2, label: [66, 0.6], note: "Dock edge is a 1.2 drop to the truck yard, so it only works one way." },
    { id: "booth", name: "Foreman", lv: "C1", kind: "indoor", rect: [-16, -40, -8, -30], label: [-12, -32], note: "Upper office at +4. Window over the floor, shells on the desk." },

    { id: "hallpit", name: "Machine pit", lv: "B", kind: "pit", rect: [-52, -60, -24, -42], label: [-44, -58], note: "Sunken floor at -4 with hazard edges. You fight down here with Hunters above you." },
    { id: "plantpit", name: "Plant pit", lv: "B", kind: "pit", rect: [30, -114, 64, -80], label: [47, -111.6], note: "Pit floor at -4 round the machine." },
    { id: "pump", name: "Pump room", lv: "B", kind: "room", rect: [0, -84, 14, -72], label: [7, -73.8], note: "Where the short way joins the main tunnel. Health on the pumps." },
    { id: "machinetop", name: "Machine roof", lv: "C2", kind: "deck", round: [47, -97, 7], poly: [[47, -104], [49.7, -103.5], [51.9, -101.9], [53.5, -99.7], [54, -97], [53.5, -94.3], [51.9, -92.1], [49.7, -90.5], [47, -90], [44.3, -90.5], [42.1, -92.1], [40.5, -94.3], [40, -97], [40.5, -99.7], [42.1, -101.9], [44.3, -103.5]], label: [47, -103], note: "A 3-wide walkway round the coolant stack, with the arms' shoulders on its edge. The ACTIVATE button is on the stack's north side." },
  ],

  // Corridors drawn as a centre line with a width.
  corridors: [
    { id: "adminA", name: "Admin corridor", lv: "G", w: 3, pts: [[-80, 39.5], [-88, 39.5]] },
    { id: "adminB", name: "Admin corridor", lv: "G", w: 3, pts: [[-85, 39.5], [-85, 27], [-95.5, 27], [-95.5, 10]], note: "Turns for no reason but to break sight lines." },
    { id: "adminC", name: "Admin corridor", lv: "G", w: 3, pts: [[-95.5, 18], [-86, 18], [-86, 8], [-76, 8]] },
    { id: "skybridge", name: "Skybridge", lv: "C2", w: 3, pts: [[-18.5, -70], [-18.5, -86]], note: "Enclosed, windows both sides, over the service lane." },
    { id: "tunMain", name: "Service tunnel", lv: "B", w: 3, pts: [[-3, -104], [-3, -108], [8, -108], [8, -96], [18, -96], [18, -106], [30, -106]], note: "3 wide, 3.5 clear. Pipes on one wall." },
    { id: "tunSpur", name: "Tunnel spur", lv: "B", w: 3, pts: [[8, -96], [8, -84]] },
    { id: "tunHall", name: "Pit tunnel", lv: "B", w: 3, pts: [[-52, -58], [-56, -58], [-56, -74], [-30, -74], [-30, -80], [-10, -80], [-10, -76], [0, -76]], note: "The short way. Hall pit to the pump room, skipping the hall catwalks, skybridge and tank house. Quicker, and you miss what is up there." },
  ],

  // Catwalks and landings: rect plus storey.
  catwalks: [
    { name: "West catwalk", lv: "C1", rect: [-62, -70, -60, -42] },
    { name: "North catwalk", lv: "C1", rect: [-62, -70, -8, -68] },
    { name: "East catwalk", lv: "C1", rect: [-10, -68, -8, -40], note: "Dead-end run to the foreman's office." },
    { name: "Pit crossing", lv: "C1", rect: [-35, -68, -33, -54], note: "Over the pit you just fought through." },
    { name: "Tower ring", lv: "C1", rect: [-38, -54, -30, -46] },
    { name: "Gantry landing", lv: "C2", rect: [-20, -52, -16, -48], note: "Stair tops must meet a landing edge, never run under one." },
    { name: "High gantry", lv: "C2", rect: [-19.75, -70, -17.25, -52] },

    { name: "Entry landing", lv: "C2", rect: [-21, -90, -16, -86] },
    { name: "Between the vats", lv: "C2", rect: [-19.75, -113, -17.25, -90] },
    { name: "North landing", lv: "C2", rect: [-21, -117, -16, -113] },
    { name: "NW landing", lv: "C1", rect: [-39, -117, -33, -113] },
    { name: "West catwalk", lv: "C1", rect: [-39, -113, -37, -93] },
    { name: "SW landing", lv: "C1", rect: [-39, -93, -33, -89] },

    { name: "East landing", lv: "C1", rect: [66, -98, 70, -92] },
    { name: "Bridge to the machine", lv: "C1", rect: [56, -98, 66, -96] },
    { name: "Machine walk east", lv: "C1", rect: [54, -108, 56, -92] },
    { name: "Machine walk north", lv: "C1", rect: [38, -108, 56, -106] },
    { name: "Machine walk west", lv: "C1", rect: [38, -106, 40, -92] },
    { name: "Top gantry", lv: "C2", rect: [37, -80, 49, -77.5] },
    { name: "Exit bridge", lv: "C2", rect: [46, -90.5, 48.5, -72], note: "The high door at the end is shut until the machine blows." },
    { name: "Outside catwalk", lv: "C2", rect: [46, -72, 48.5, -62], note: "Open air, over the plant yard, into the warehouse wall." },

    { name: "Warehouse landing", lv: "C2", rect: [44, -62, 50, -58] },
    { name: "North catwalk", lv: "C1", rect: [62, -62, 84, -60] },
    { name: "East catwalk", lv: "C1", rect: [82, -60, 84, -40], note: "The secret container is in view from here, and the timer says keep moving." },
  ],

  // Stairs are ramps: 4.0 rise over 12 run, 18 degrees. from/to are [x, z, y].
  ramps: [
    { name: "Pit ramp north", from: [-36, -58.5, -4], to: [-24, -58.5, 0], w: 3 },
    { name: "Pit ramp south", from: [-40, -43.5, -4], to: [-52, -43.5, 0], w: 3 },
    { name: "Stair to catwalks", from: [-60.75, -30, 0], to: [-60.75, -42, 4], w: 2.5 },
    { name: "Stair to gantry", from: [-30, -50, 4], to: [-20, -50, 8], w: 2.5 },
    { name: "Stair down", from: [-21, -115, 8], to: [-33, -115, 4], w: 2.5 },
    { name: "Stair down", from: [-33, -91, 4], to: [-21, -91, 0], w: 2.5 },
    { name: "Basement stair", from: [-3, -92, 0], to: [-3, -104, -4], w: 2.5 },
    { name: "Pit ramp", from: [52, -81.5, -4], to: [64, -81.5, 0], w: 3 },
    { name: "Stair to machine walk", from: [68, -80, 0], to: [68, -92, 4], w: 2.5 },
    { name: "Stair to the roof", from: [39, -92, 4], to: [39, -80, 8], w: 2.5 },
    { name: "Stair down", from: [50, -61, 8], to: [62, -61, 4], w: 2 },
    { name: "Stair down", from: [83, -40, 4], to: [83, -28, 0], w: 2 },
    { name: "Dock ramp", from: [36, -6, 0], to: [36, -2.5, 1.2], w: 5, note: "Up from the roller door onto the dock, in a slot cut into the dock floor." },
  ],

  // Doors: at [x, z], axis "h" sits in a wall running east-west, "v" north-south.
  // type: open | kick | shutter (never kickable) | oneway | timed | exit
  doors: [
    { name: "Admin doors", at: [-70, 48], axis: "h", w: 4, lv: "G", type: "open" },
    { name: "Lobby to corridor", at: [-80, 39.5], axis: "v", w: 3, lv: "G", type: "open" },
    { name: "Waiting room", at: [-60, 41.5], axis: "v", w: 3, lv: "G", type: "open" },
    { name: "Break room", at: [-88, 39.5], axis: "v", w: 3, lv: "G", type: "open" },
    { name: "Records", at: [-95.5, 10], axis: "h", w: 3, lv: "G", type: "kick" },
    { name: "Office door, taught kick", at: [-76, 8], axis: "v", w: 3, lv: "G", type: "kick", prompt: true, note: "The one floating prompt. On the golden path." },
    { name: "Manager", at: [-55.5, 8], axis: "h", w: 3, lv: "G", type: "open" },
    { name: "Office to yard", at: [-50, 19.5], axis: "v", w: 3, lv: "G", type: "open" },
    { name: "Hall doors", at: [-30, -26], axis: "h", w: 4, lv: "G", type: "open" },
    { name: "Hall to lane", at: [-10.5, -70], axis: "h", w: 3, lv: "G", type: "kick" },
    { name: "Foreman's office", at: [-9, -40], axis: "h", w: 2, lv: "C1", type: "open" },
    { name: "Warehouse yard shutter", at: [20, -16], axis: "v", w: 6, lv: "G", type: "shutter", note: "Closed from the yard. You come out the other side of this building at the end." },
    { name: "Pit tunnel", at: [-52, -58], axis: "v", w: 3, lv: "B", type: "open", note: "In the pit's back corner, behind the drum washers. A shortcut you find, not the obvious way on." },
    { name: "Skybridge, hall end", at: [-18.5, -70], axis: "h", w: 3, lv: "C2", type: "open" },
    { name: "Skybridge, tank end", at: [-18.5, -86], axis: "h", w: 3, lv: "C2", type: "open" },
    { name: "Pump room", at: [8, -84], axis: "h", w: 3, lv: "B", type: "open" },
    { name: "Pit tunnel to pump room", at: [0, -76], axis: "v", w: 3, lv: "B", type: "open" },
    { name: "Tunnel into the pit", at: [30, -106], axis: "v", w: 3, lv: "B", type: "open" },
    { name: "High exit", at: [47.25, -72], axis: "h", w: 2.5, lv: "C2", type: "timed" },
    { name: "Warehouse high door", at: [47.25, -62], axis: "h", w: 2.5, lv: "C2", type: "open" },
    { name: "Dock roller door", at: [36, -6], axis: "h", w: 5, lv: "G", type: "open" },
    { name: "Dock edge drop", at: [38, 6], axis: "h", w: 8, lv: "G", y: 1.2, type: "oneway", note: "The dock is 1.2 up. You can drop off it but not jump back." },
    { name: "Lot gate", at: [-84, 78], axis: "h", w: 8, lv: "G", type: "shutter", note: "Vehicle gate to the street, shut. The lot has to come from somewhere." },
    { name: "Exit gate", at: [62, 52], axis: "h", w: 12, lv: "G", type: "exit", note: "Out to the street. The level ends in front of it, past the open trailer." },
  ],

  fences: [
    { name: "Yard fence", pts: [[20, 30], [20, 6]] },
    { name: "Tank farm fence", pts: [[-8, -26], [20, -26]] },
    { name: "Tank farm fence", pts: [[-8, -70], [0, -70]] },
  ],
};
