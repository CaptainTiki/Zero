extends "res://tools/art_kit.gd"
## Bakes scenes/modules/city_dress.tscn: distant skyline backdrop, abandoned
## cars, the police cordon at the checkpoint, high-street shop fronts, the
## pedestrian plaza and the closed metro entrance. Regenerating replaces manual
## edits to that scene. Run:
##   godot --headless --path . -s res://tools/build_city_dress.gd

var rng := RandomNumberGenerator.new()
const FACADES := ["brick", "brick_dark", "plaster", "plaster_ochre", "plaster_grey", "concrete_dark"]

# Sign looks. Fonts are system names with the engine default as fallback.
const SIGN_STYLES := {
	"municipal": {"backing": "teal", "ink": Color("e7ce93"), "font": ["Arial", "Liberation Sans"], "weight": 700},
	"pharmacy": {"backing": "car_white", "ink": Color("2f7d5b"), "font": ["Arial Black", "Impact"], "scale": 1.15, "height": 1.0},
	"pawn": {"backing": "dark", "ink": Color("f2c94c"), "font": ["Impact", "Arial Black"], "scale": 1.3, "outline": 6, "outline_color": Color("5a3a00")},
	"laundry": {"backing": "car_blue", "ink": Color("f4f1e6"), "font": ["Georgia", "Times New Roman"], "italic": true, "height": 0.9},
	"garage": {"backing": "car_red", "ink": Color("f4e7c3"), "font": ["Courier New", "Consolas"], "weight": 700, "height": 1.3},
	"cafe": {"backing": "plaster", "ink": Color("6b2e2a"), "font": ["Georgia", "Times New Roman"], "italic": true, "scale": 1.2, "height": 1.2, "depth": 0.08},
	"tolet": {"backing": "plaster_grey", "ink": Color("343c39"), "font": ["Arial"], "height": 0.8, "scale": 0.9},
	"cinema": {"backing": "car_white", "ink": Color("8a1d1d"), "font": ["Impact", "Arial Black"], "scale": 1.15, "height": 1.2},
	"market": {"backing": "car_green", "ink": Color("f7e7b2"), "font": ["Georgia", "Times New Roman"], "weight": 700},
	"metro": {"backing": "dark", "ink": Color("f4f1e6"), "font": ["Arial Black", "Impact"], "scale": 1.1, "height": 0.9},
	"notice": {"backing": "car_white", "ink": Color("1f1f1f"), "font": ["Arial"], "height": 0.7, "scale": 0.9, "depth": 0.06},
	"police": {"backing": "car_white", "ink": Color("1d3f8a"), "font": ["Arial Black", "Impact"], "height": 0.8, "scale": 1.05, "outline": 4, "outline_color": Color("1d3f8a")},
	"painted": {"backing": "plaster_ochre", "ink": Color("4a2c1a"), "font": ["Comic Sans MS", "Segoe Print"], "scale": 1.1, "height": 1.0, "depth": 0.04},
}

func _initialize() -> void:
	call_deferred("build")

func build() -> void:
	art.name = "CityDress"
	rng.seed = 4104
	backdrop()
	cars()
	cordon()
	street()
	plaza()
	metro_entrance()
	rooftops()
	save_scene("res://scenes/modules/city_dress.tscn")

func shop_sign(label: String, text: String, at: Vector3, width: float, yaw: float, style: String) -> void:
	styled_sign(label, text, at, width, yaw, SIGN_STYLES[style])

# --- Distant city -----------------------------------------------------------

func backdrop() -> void:
	# Ground continues under everything so nothing floats at the edges.
	box("CityGround", Vector3(55, -0.8, 0), Vector3(520, 1.0, 420), "concrete_dark")
	# Two rows of blocks either side of the spine, then a taller cluster past the end.
	skyline_row("North", -34.0, -70.0, 190.0, 1.0)
	skyline_row("South", 34.0, -70.0, 190.0, -1.0)
	skyline_row("NorthFar", -62.0, -90.0, 210.0, 1.0, 1.35)
	skyline_row("SouthFar", 62.0, -90.0, 210.0, -1.0, 1.35)
	skyline_column("EastEnd", 140.0, -40.0, 40.0, 1.6)
	skyline_column("EastFar", 175.0, -70.0, 70.0, 2.1)
	skyline_column("WestEnd", -34.0, -40.0, 40.0, 1.2)

func skyline_row(label: String, z: float, x0: float, x1: float, facing: float, scale: float = 1.0) -> void:
	var x := x0
	var index := 0
	while x < x1:
		var width := rng.randf_range(10.0, 22.0)
		var depth := rng.randf_range(12.0, 22.0)
		var height := rng.randf_range(9.0, 24.0) * scale
		var gap := rng.randf_range(1.5, 6.0)
		tower("%s%d" % [label, index], Vector3(x + width / 2.0, 0, z - facing * depth / 2.0), Vector3(width, height, depth), facing)
		x += width + gap
		index += 1

func skyline_column(label: String, x: float, z0: float, z1: float, scale: float) -> void:
	var z := z0
	var index := 0
	while z < z1:
		var width := rng.randf_range(12.0, 24.0)
		var depth := rng.randf_range(14.0, 24.0)
		var height := rng.randf_range(12.0, 26.0) * scale
		tower("%s%d" % [label, index], Vector3(x + depth / 2.0, 0, z + width / 2.0), Vector3(depth, height, width), 0.0)
		z += width + rng.randf_range(2.0, 6.0)
		index += 1

## One distant block: shell, parapet, window bands on the face toward the level, roof clutter.
func tower(label: String, base: Vector3, size: Vector3, facing: float) -> void:
	var facade: String = FACADES[rng.randi_range(0, FACADES.size() - 1)]
	box(label, base + Vector3(0, size.y / 2.0, 0), size, facade)
	box(label + "Parapet", base + Vector3(0, size.y + 0.3, 0), Vector3(size.x + 0.6, 0.6, size.z + 0.6), "dark")
	var floors := int(size.y / 3.4)
	for level in floors:
		var y := 2.2 + level * 3.4
		if facing != 0.0:
			window_band(label + "Win%d" % level, base + Vector3(0, y, facing * (size.z / 2.0 + 0.02)), size.x * 0.82)
		else:
			window_band(label + "Win%d" % level, base + Vector3(-size.x / 2.0 - 0.02, y, 0), size.z * 0.82, PI / 2)
	match rng.randi_range(0, 3):
		0:
			water_tower(label + "Tank", base + Vector3(size.x * 0.25, size.y, -size.z * 0.15))
		1:
			pipe(label + "Stack", base + Vector3(-size.x * 0.3, size.y + 2.2, size.z * 0.2), 4.4, 0.7, "rust")
			pipe(label + "Stack2", base + Vector3(-size.x * 0.3 + 2.0, size.y + 1.6, size.z * 0.2), 3.2, 0.5, "rust")
		2:
			box(label + "Penthouse", base + Vector3(size.x * 0.1, size.y + 1.5, 0), Vector3(size.x * 0.4, 3.0, size.z * 0.5), "plaster_grey")
			pipe(label + "Mast", base + Vector3(size.x * 0.1, size.y + 6.0, 0), 6.0, 0.12, "dark")
		_:
			box(label + "Vent", base + Vector3(0, size.y + 0.9, 0), Vector3(3.0, 1.8, 2.0), "teal")

func water_tower(label: String, at: Vector3) -> void:
	for leg in [Vector3(-1, 0, -1), Vector3(1, 0, -1), Vector3(-1, 0, 1), Vector3(1, 0, 1)]:
		pipe(label + "Leg", at + leg * 1.1 + Vector3(0, 1.8, 0), 3.6, 0.12, "dark")
	pipe(label + "Tank", at + Vector3(0, 5.2, 0), 3.4, 1.7, "rust")
	pipe(label + "Cap", at + Vector3(0, 7.3, 0), 0.8, 1.2, "dark")

# --- Abandoned cars: the service road is a road, the cordon has a queue -----

func cars() -> void:
	# Service road (walls at z +/-6.2, kick box at x 15, supply crate at (17, 2.5)).
	car("ServiceVan", Vector3(20, 0, -4.6), 0.04, "car_white")
	car("ServiceCar", Vector3(26.5, 0, 4.6), PI - 0.06, "car_green")
	# Queue abandoned at the cordon, nosed toward the gate at x 42. Keeps z 1.8 clear
	# for the Rammer traversal lane and the centre open for the player.
	car("QueueA", Vector3(34, 0, -4.2), 0.12, "car_red")
	car("QueueB", Vector3(38.2, 0, 4.4), -0.18, "car_tan")
	car("QueueC", Vector3(29.5, 0, 4.2), 0.08, "car_blue")
	# Street kerbs.
	car("StreetParkedA", Vector3(63, 0, -7.4), 0.0, "car_tan")
	car("StreetParkedB", Vector3(73, 0, 7.6), PI + 0.05, "car_blue")

# --- Police cordon around the existing checkpoint gate (x 42) ----------------

func cordon() -> void:
	# Chevron barriers funnel traffic to the gate. Centre lane stays open.
	for z in [-7.0, 7.0]:
		box("CordonBarrier", Vector3(40.5, 0.45, z), Vector3(0.4, 0.9, 3.0), "concrete", 0, true)
		box("CordonChevron", Vector3(40.28, 0.6, z), Vector3(0.04, 0.3, 2.9), "hazard")
	for z in [-5.8, 5.8]:
		pipe("CordonDrum", Vector3(38.5, 0.45, z), 0.9, 0.3, "hazard")
		box("CordonDrumBand", Vector3(38.5, 0.5, z), Vector3(0.64, 0.14, 0.64), "car_white")
	# Sign on a post ahead of the queue.
	pipe("CordonPost", Vector3(36, 1.4, -6.4), 2.8, 0.06, "dark")
	shop_sign("CordonSign", "STOP / POLICE CHECKPOINT", Vector3(36, 2.5, -6.4), 2.4, 0, "police")
	shop_sign("CordonSignB", "ALL VEHICLES / PAPERS READY", Vector3(36, 1.85, -6.4), 2.0, 0, "notice")
	# Light bar on the gate header and a flood lamp so the cordon reads at night.
	box("CordonLightBar", Vector3(42, 4.95, 0), Vector3(0.5, 0.2, 1.6), "car_blue")
	box("CordonLightBarB", Vector3(42, 4.95, 0.0), Vector3(0.52, 0.22, 0.4), "car_red")
	var flood := OmniLight3D.new()
	flood.position = Vector3(41.5, 4.6, 0)
	flood.light_color = Color("dfe8ff")
	flood.light_energy = 1.0
	flood.omni_range = 9.0
	add(flood, "CordonFlood")

# --- High street between the cordon and the plaza (x 60..76) -----------------

func street() -> void:
	# Turn the freestanding checkpoint exit walls into a building corner with a portal.
	for z in [-6.0, 6.0]:
		box("ExitPier", Vector3(60, 3.2, z + (2.0 if z < 0 else -2.0)), Vector3(1.1, 6.4, 1.1), "concrete", 0, true)
		box("ExitCornice", Vector3(60, 6.3, z), Vector3(1.4, 0.5, 8.6), "dark")
	box("ExitLintel", Vector3(60, 6.2, 0), Vector3(1.0, 0.8, 5.0), "dark", 0, true)
	shop_sign("ExitSign", "CANAL STREET", Vector3(60.6, 4.6, 0), 4.4, -PI / 2, "municipal")
	# North frontage on Bldg_L2 (face z = -10, x 60..80).
	for x in [63.0, 69.0, 75.0]:
		box("ShopPanel", Vector3(x, 2.3, -9.9), Vector3(5.2, 4.6, 0.14), "plaster_grey")
		box("ShopWindow", Vector3(x, 1.7, -9.78), Vector3(3.6, 2.2, 0.12), "glass")
		box("ShopSill", Vector3(x, 0.55, -9.7), Vector3(3.8, 0.12, 0.3), "dark")
		for y in [3.9, 5.0, 6.1, 7.2, 8.3, 9.4, 10.5]:
			box("UpperWin", Vector3(x, y, -9.9), Vector3(1.4, 0.8, 0.12), "glass")
			box("UpperWinB", Vector3(x + 2.0, y, -9.9), Vector3(1.0, 0.8, 0.12), "glass")
	box("NorthCornice", Vector3(70, 12.1, -9.9), Vector3(20.4, 0.5, 0.7), "dark")
	# Each shop gets its own sign shape and canopy colour.
	box("LaundryCanopy", Vector3(63, 3.15, -9.3), Vector3(4.6, 0.16, 1.4), "car_blue", 0, false, 0.05)
	shop_sign("Laundry", "Sunrise Laundry", Vector3(63, 3.85, -9.75), 4.4, 0, "laundry")
	box("PharmacyCanopy", Vector3(69, 3.15, -9.3), Vector3(4.6, 0.16, 1.4), "car_white", 0, false, 0.05)
	shop_sign("Pharmacy", "PHARMACY 24H", Vector3(69, 3.85, -9.75), 4.6, 0, "pharmacy")
	pipe("PharmacyBladeArm", Vector3(71.7, 5.2, -9.5), 0.8, 0.03, "dark", 0.0, PI / 2)
	shop_sign("PharmacyBlade", "+", Vector3(71.7, 4.7, -9.1), 0.9, PI / 2, "pharmacy")
	box("PawnGrille", Vector3(75, 1.7, -9.7), Vector3(3.7, 2.3, 0.05), "dark")
	shop_sign("Pawn", "CA$H 4 GOLD", Vector3(75, 3.95, -9.7), 4.8, 0, "pawn")
	shop_sign("PawnSub", "WE BUY ANYTHING", Vector3(75, 3.05, -9.7), 3.0, 0, "notice")
	# South frontage on Bldg_R2 (face z = 10, x 69..87).
	for x in [71.0, 77.0, 83.0]:
		box("SouthPanel", Vector3(x, 2.3, 9.9), Vector3(5.2, 4.6, 0.14), "plaster")
		box("SouthShutter", Vector3(x, 1.5, 9.78), Vector3(3.0, 3.0, 0.14), "teal")
		for y in [0.35, 0.75, 1.15, 1.55, 1.95, 2.35, 2.75]:
			box("SouthRib", Vector3(x, y, 9.68), Vector3(3.05, 0.06, 0.08), "dark")
		for y in [4.3, 5.4, 6.5, 7.6, 8.7]:
			box("SouthWin", Vector3(x - 1.4, y, 9.9), Vector3(1.2, 0.8, 0.12), "glass")
			box("SouthWinB", Vector3(x + 1.4, y, 9.9), Vector3(1.2, 0.8, 0.12), "glass")
	box("SouthCornice", Vector3(78, 10.1, 9.9), Vector3(18.4, 0.5, 0.7), "dark")
	shop_sign("Garage", "ORTIZ AUTO BODY", Vector3(71, 3.95, 9.75), 4.8, PI, "garage")
	box("GarageStripe", Vector3(71, 3.2, 9.72), Vector3(4.8, 0.14, 0.06), "hazard")
	box("CafeAwning", Vector3(77, 3.2, 9.2), Vector3(4.2, 0.14, 1.6), "car_red", 0, false, -0.06)
	for i in 5:
		box("CafeAwningStripe", Vector3(75.5 + i * 0.84, 3.21, 9.2), Vector3(0.36, 0.15, 1.62), "car_white", 0, false, -0.06)
	shop_sign("Cafe", "Cafe Luna", Vector3(77, 4.0, 9.75), 3.6, PI, "cafe")
	shop_sign("Closed", "TO LET", Vector3(83, 3.85, 9.75), 2.2, PI, "tolet")
	shop_sign("ClosedB", "CALL 555-0142", Vector3(83, 1.5, 9.68), 2.0, PI, "notice")
	# Street furniture, clear of the spine lane (|z| <= 4), the wrecked car at x 66..70
	# and the terrace ramp (x 67..77, z -6.8..-4.4).
	bus_shelter("BusShelter", Vector3(63.5, 0, 6.6))
	pipe("Hydrant", Vector3(79.5, 0.45, -9.2), 0.9, 0.18, "rust")
	box("HydrantCap", Vector3(79.5, 0.98, -9.2), Vector3(0.36, 0.2, 0.36), "rust")
	for i in 3:
		pipe("Bollard", Vector3(62.5 + i * 1.6, 0.45, -5.6), 0.9, 0.12, "dark")
	box("NewsBox", Vector3(76.5, 0.6, 6.6), Vector3(0.6, 1.2, 0.6), "teal", 0, true)
	box("NewsBoxB", Vector3(77.2, 0.6, 6.6), Vector3(0.6, 1.2, 0.6), "rust", 0, true)
	box("TrashCan", Vector3(65.5, 0.5, -6.0), Vector3(0.7, 1.0, 0.7), "dark", 0, true)
	box("Rubble", Vector3(66.5, 0.2, 5.6), Vector3(2.4, 0.4, 1.6), "concrete_dark", 0.4)
	box("RubbleB", Vector3(69.5, 0.3, 6.2), Vector3(1.4, 0.6, 1.2), "concrete", -0.3)
	box("Manhole", Vector3(64, 0.015, 2.0), Vector3(0.9, 0.02, 0.9), "dark")
	# Overhead banner ties the two sides together.
	pipe("BannerCable", Vector3(72, 6.8, 0), 20.0, 0.03, "dark", 0.0, PI / 2)
	shop_sign("Banner", "CANAL ST SUMMER MARKET", Vector3(72, 6.1, 0), 5.0, 0, "market")
	# Hazard edge on the terrace ramp so the climb reads from the street.
	box("RampEdge", Vector3(72, 1.36, -4.45), Vector3(10.2, 0.04, 0.16), "hazard", 0, false, 0.2551)

func bus_shelter(label: String, at: Vector3) -> void:
	for x in [-1.8, 1.8]:
		pipe(label + "Post", at + Vector3(x, 1.3, 0.8), 2.6, 0.08, "dark")
		pipe(label + "PostB", at + Vector3(x, 1.3, -0.8), 2.6, 0.08, "dark")
	box(label + "Roof", at + Vector3(0, 2.65, 0), Vector3(4.2, 0.12, 2.0), "teal", 0, true)
	box(label + "Back", at + Vector3(0, 1.3, 0.85), Vector3(4.0, 2.2, 0.08), "glass", 0, true)
	box(label + "Bench", at + Vector3(0, 0.45, 0.35), Vector3(3.2, 0.1, 0.5), "rust", 0, true)
	box(label + "BenchLegs", at + Vector3(0, 0.2, 0.35), Vector3(3.0, 0.4, 0.1), "dark")
	shop_sign(label + "Sign", "ROUTE 12 / CENTRAL", at + Vector3(0, 2.95, -0.9), 2.4, 0, "municipal")

# --- Pedestrian plaza (x 74..100): market arcade, café terrace on the ledge --

func plaza() -> void:
	# Paving change marks the pedestrian zone.
	box("PlazaPaving", Vector3(86, 0.008, 0), Vector3(26, 0.014, 19.4), "concrete")
	box("PlazaBand", Vector3(86, 0.012, 0), Vector3(1.2, 0.012, 19.4), "concrete_dark")
	# The ledge is a café terrace: planters along the rail, tables, umbrellas.
	box("TerraceStripe", Vector3(86, 2.61, -5.5), Vector3(18, 0.02, 0.3), "car_white")
	for x in [79.0, 83.0, 87.0, 91.0, 95.0]:
		planter("TerracePlanter", Vector3(x, 2.6, -8.3))
	for x in [81.0, 85.5, 90.0, 94.0]:
		cafe_table("TerraceTable", Vector3(x, 2.6, -6.6))
	box("TerraceRail", Vector3(86, 3.5, -5.35), Vector3(18, 0.06, 0.06), "dark")
	for x in [78.0, 81.0, 84.0, 87.0, 90.0, 93.0]:
		pipe("TerraceRailPost", Vector3(x, 3.05, -5.35), 0.9, 0.03, "dark")
	# Market arcade facade on the north wall (z = -10): pilasters, tiled band, clock.
	for x in [77.0, 83.0, 89.0, 95.0]:
		box("ArcadePilaster", Vector3(x, 3.0, -9.85), Vector3(0.7, 6.0, 0.35), "concrete")
	box("ArcadeBand", Vector3(86, 1.1, -9.8), Vector3(24, 1.2, 0.1), "car_green")
	box("ArcadeCornice", Vector3(86, 6.25, -9.8), Vector3(26, 0.5, 0.8), "dark")
	for x in [80.0, 86.0, 92.0]:
		box("ArcadeArch", Vector3(x, 4.6, -9.75), Vector3(4.6, 1.6, 0.16), "plaster")
	shop_sign("ArcadeName", "CANAL STREET MARKET", Vector3(86, 4.6, -9.62), 6.5, 0, "market")
	shop_sign("ArcadeEst", "est. 1932", Vector3(86, 3.85, -9.62), 2.0, 0, "notice")
	pipe("Clock", Vector3(93, 4.8, -9.6), 0.2, 0.7, "plaster", 0.0, PI / 2)
	pipe("ClockRim", Vector3(93, 4.8, -9.66), 0.2, 0.8, "dark", 0.0, PI / 2)
	# Ground-level plaza furniture, outside the |z| <= 4 fighting lane.
	for x in [80.0, 92.0]:
		planter("PlazaPlanter", Vector3(x, 0, 5.2))
		bench("PlazaBench", Vector3(x + 3.0, 0, 5.2))
	pipe("PlazaLamp", Vector3(86, 2.2, 5.4), 4.4, 0.08, "dark")
	box("PlazaLampHead", Vector3(86, 4.5, 5.4), Vector3(0.5, 0.3, 0.5), "car_white")
	kiosk("Kiosk", Vector3(96, 0, 5.8))
	# Shuttered cinema on the south wall (z = 10).
	box("CinemaMarquee", Vector3(84, 4.5, 9.3), Vector3(8.0, 1.6, 1.4), "car_red")
	box("MarqueeUnder", Vector3(84, 3.65, 9.3), Vector3(8.2, 0.14, 1.6), "car_white")
	for i in 9:
		pipe("MarqueeBulb", Vector3(80.4 + i * 0.9, 3.58, 8.5), 0.08, 0.08, "hazard")
	shop_sign("MarqueeText", "RIALTO", Vector3(84, 4.5, 8.55), 3.6, PI, "cinema")
	shop_sign("MarqueeNow", "NOW SHOWING: NOTHING / CLOSED", Vector3(84, 2.95, 9.72), 6.2, PI, "notice")
	for x in [80.5, 82.5, 84.5, 86.5]:
		box("CinemaDoor", Vector3(x, 1.4, 9.85), Vector3(1.6, 2.8, 0.12), "teal")
	box("CinemaPoster", Vector3(89.5, 2.0, 9.85), Vector3(1.4, 2.0, 0.1), "plaster_ochre")
	shop_sign("CinemaPosterText", "BIG / LOUD / 3", Vector3(89.5, 2.0, 9.78), 1.2, PI, "painted")
	box("CinemaPosterB", Vector3(78.5, 2.0, 9.85), Vector3(1.4, 2.0, 0.1), "brick_dark")
	box("CinemaCornice", Vector3(84, 6.25, 9.8), Vector3(14, 0.5, 0.8), "dark")

func planter(label: String, at: Vector3) -> void:
	box(label, at + Vector3(0, 0.35, 0), Vector3(1.6, 0.7, 0.8), "concrete", 0, true)
	box(label + "Soil", at + Vector3(0, 0.72, 0), Vector3(1.5, 0.06, 0.7), "concrete_dark")
	box(label + "Shrub", at + Vector3(0, 1.05, 0), Vector3(1.3, 0.6, 0.6), "car_green")

func bench(label: String, at: Vector3) -> void:
	box(label, at + Vector3(0, 0.45, 0), Vector3(1.8, 0.08, 0.5), "rust", 0, true)
	box(label + "Back", at + Vector3(0, 0.8, 0.22), Vector3(1.8, 0.4, 0.06), "rust")
	for x in [-0.7, 0.7]:
		box(label + "Leg", at + Vector3(x, 0.2, 0), Vector3(0.08, 0.4, 0.44), "dark")

func cafe_table(label: String, at: Vector3) -> void:
	pipe(label + "Stem", at + Vector3(0, 0.36, 0), 0.72, 0.03, "dark")
	pipe(label + "Top", at + Vector3(0, 0.74, 0), 0.04, 0.42, "car_white")
	pipe(label + "Pole", at + Vector3(0, 1.6, 0), 1.7, 0.02, "dark")
	pipe(label + "Umbrella", at + Vector3(0, 2.4, 0), 0.12, 1.1, "car_red")
	for angle in [0.8, 2.4, 4.0]:
		box(label + "Chair", at + Vector3(cos(angle) * 0.75, 0.25, sin(angle) * 0.75), Vector3(0.4, 0.5, 0.4), "dark", -angle)

func kiosk(label: String, at: Vector3) -> void:
	box(label, at + Vector3(0, 1.1, 0), Vector3(2.4, 2.2, 1.8), "car_green", 0, true)
	box(label + "Counter", at + Vector3(0, 1.0, -1.0), Vector3(2.5, 0.12, 0.5), "dark")
	box(label + "Hatch", at + Vector3(0, 1.55, -0.92), Vector3(2.0, 0.9, 0.06), "glass")
	box(label + "Roof", at + Vector3(0, 2.32, 0), Vector3(2.8, 0.14, 2.3), "car_white", 0, false, 0.04)
	shop_sign(label + "Sign", "NEWS  SNACKS  LOTTO", at + Vector3(0, 2.7, -0.95), 2.4, 0, "painted")

# --- Closed metro entrance (x 98..118) closes the slice ----------------------

func metro_entrance() -> void:
	for z in [-8.3, 8.3]:
		box("PlazaWall", Vector3(109, 3.0, z), Vector3(20, 6.0, 0.6), "plaster_ochre", 0, true)
		box("PlazaCornice", Vector3(109, 6.2, z), Vector3(20.6, 0.5, 0.9), "dark")
		for x in [102.0, 108.0, 114.0]:
			box("PlazaPilaster", Vector3(x, 3.0, z + (0.45 if z < 0 else -0.45)), Vector3(0.6, 6.0, 0.3), "concrete")
			box("PlazaWin", Vector3(x + 3.0, 3.6, z + (0.36 if z < 0 else -0.36)), Vector3(1.6, 1.4, 0.12), "glass")
	# Station frontage closes the far end: tiled portal, shutter, roundel.
	box("StationWall", Vector3(118.3, 3.0, 0), Vector3(0.6, 6.0, 17.2), "concrete", 0, true)
	box("StationTile", Vector3(117.95, 1.0, 0), Vector3(0.1, 2.0, 16.6), "car_green")
	for z in [-3.2, 3.2]:
		box("StationPier", Vector3(117.8, 2.6, z), Vector3(0.7, 5.2, 0.9), "concrete_dark", 0, true)
	box("StationHeader", Vector3(117.8, 5.4, 0), Vector3(0.7, 0.8, 7.3), "concrete_dark", 0, true)
	box("StationShutter", Vector3(117.9, 2.5, 0), Vector3(0.14, 5.0, 5.6), "teal", 0, true)
	for y in [0.4, 0.9, 1.4, 1.9, 2.4, 2.9, 3.4, 3.9, 4.4]:
		box("StationRib", Vector3(117.8, y, 0), Vector3(0.08, 0.06, 5.6), "dark")
	shop_sign("StationSign", "METRO  /  CANAL STREET", Vector3(117.7, 5.4, 0), 6.5, -PI / 2, "metro")
	shop_sign("StationClosed", "STATION CLOSED", Vector3(117.75, 3.3, 0), 3.2, -PI / 2, "notice")
	pipe("RoundelPost", Vector3(114.5, 2.0, 7.2), 4.0, 0.07, "dark")
	pipe("Roundel", Vector3(114.5, 4.4, 7.2), 0.12, 0.8, "car_red", 0.0, PI / 2)
	pipe("RoundelInner", Vector3(114.5, 4.4, 7.2), 0.14, 0.55, "car_white", 0.0, PI / 2)
	shop_sign("RoundelLetter", "M", Vector3(114.5, 4.4, 7.05), 0.7, 0, "metro")
	# Barriers and a work light so the closure reads as a scene, not a wall.
	for z in [-2.4, 0.0, 2.4]:
		box("ClosureBarrier", Vector3(115.5, 0.5, z), Vector3(0.3, 1.0, 2.0), "hazard", 0, true)
	box("ClosureBarrierTop", Vector3(115.5, 0.95, 0), Vector3(0.36, 0.1, 7.0), "dark")
	box("WorkLightStand", Vector3(115.0, 0.1, -5.5), Vector3(1.0, 0.2, 1.0), "dark")
	pipe("WorkLightPole", Vector3(115.0, 1.6, -5.5), 3.0, 0.06, "dark")
	box("WorkLightHead", Vector3(115.0, 3.2, -5.5), Vector3(0.6, 0.4, 0.4), "rust")
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(114.6, 3.0, -5.0)
	lamp.light_color = Color("ffd597")
	lamp.light_energy = 1.6
	lamp.omni_range = 9.0
	add(lamp, "WorkLight")
	box("PlazaDumpster", Vector3(112, 0.8, 6.8), Vector3(2.4, 1.6, 1.4), "teal", 0, true)
	box("PlazaDumpsterLid", Vector3(112, 1.65, 6.8), Vector3(2.5, 0.1, 1.5), "dark")
	box("PlazaCrateStack", Vector3(103, 0.5, -6.8), Vector3(1.0, 1.0, 1.0), "rust", 0, true)
	box("PlazaCrateStackB", Vector3(103.2, 1.5, -6.7), Vector3(1.0, 1.0, 1.0), "rust", 0.3, true)
	shop_sign("PlazaSign", "CANAL STREET STATION", Vector3(105, 4.9, -7.7), 5.2, 0, "metro")
	shop_sign("PlazaNotice", "NO CYCLING", Vector3(105, 2.4, 7.7), 2.2, PI, "notice")
	planter("StationPlanter", Vector3(106, 0, 6.8))
	bench("StationBench", Vector3(108.5, 0, -6.9))

# --- Rooftop clutter on existing blocks makes them read as buildings ---------

func rooftops() -> void:
	water_tower("YardTank", Vector3(23, 10, -13))
	pipe("YardStack", Vector3(17, 11.2, -12), 2.4, 0.5, "rust")
	water_tower("StreetTank", Vector3(75, 12, -15))
	box("StreetPenthouse", Vector3(66, 13.2, -14), Vector3(6.0, 2.4, 4.0), "plaster_grey")
	pipe("StreetMast", Vector3(66, 17.0, -14), 5.0, 0.1, "dark")
	box("SouthVent", Vector3(82, 10.9, 14), Vector3(3.0, 1.8, 2.0), "teal")
	pipe("SouthStack", Vector3(74, 11.5, 14), 3.0, 0.6, "rust")
	water_tower("CheckTank", Vector3(38, 7.5, -16))
