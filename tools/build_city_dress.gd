extends "res://tools/art_kit.gd"
## Bakes scenes/modules/city_dress.tscn: distant skyline backdrop, street and
## boulevard dressing, and an enclosed end plaza. Regenerating replaces manual
## edits to that scene. Run:
##   godot --headless --path . -s res://tools/build_city_dress.gd

var rng := RandomNumberGenerator.new()
const FACADES := ["brick", "brick_dark", "plaster", "plaster_ochre", "plaster_grey", "concrete_dark"]

func _initialize() -> void:
	call_deferred("build")

func build() -> void:
	art.name = "CityDress"
	rng.seed = 4104
	backdrop()
	street()
	boulevard()
	end_plaza()
	rooftops()
	save_scene("res://scenes/modules/city_dress.tscn")

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

# --- Street between the checkpoint and the boulevard (x 60..76) ---------------

func street() -> void:
	# Turn the freestanding checkpoint exit walls into a building corner with a portal.
	for z in [-6.0, 6.0]:
		box("ExitPier", Vector3(60, 3.2, z + (2.0 if z < 0 else -2.0)), Vector3(1.1, 6.4, 1.1), "concrete", 0, true)
		box("ExitCornice", Vector3(60, 6.3, z), Vector3(1.4, 0.5, 8.6), "dark")
	box("ExitLintel", Vector3(60, 6.2, 0), Vector3(1.0, 0.8, 5.0), "dark", 0, true)
	sign_board("ExitSign", "OUTBOUND / DISTRICT 05", Vector3(60.6, 4.6, 0), 4.4, -PI / 2)
	# North frontage on Bldg_L2 (face z = -10, x 60..80).
	for x in [63.0, 69.0, 75.0]:
		box("ShopPanel", Vector3(x, 2.3, -9.9), Vector3(5.2, 4.6, 0.14), "plaster_grey")
		box("ShopWindow", Vector3(x, 1.7, -9.78), Vector3(3.6, 2.2, 0.12), "glass")
		box("ShopSill", Vector3(x, 0.55, -9.7), Vector3(3.8, 0.12, 0.3), "dark")
		box("ShopCanopy", Vector3(x, 3.15, -9.3), Vector3(4.6, 0.16, 1.4), "rust", 0, false, 0.05)
		for y in [3.9, 5.0, 6.1, 7.2, 8.3, 9.4, 10.5]:
			box("UpperWin", Vector3(x, y, -9.9), Vector3(1.4, 0.8, 0.12), "glass")
			box("UpperWinB", Vector3(x + 2.0, y, -9.9), Vector3(1.0, 0.8, 0.12), "glass")
	box("NorthCornice", Vector3(70, 12.1, -9.9), Vector3(20.4, 0.5, 0.7), "dark")
	sign_board("Laundry", "SUNRISE LAUNDRY", Vector3(63, 3.85, -9.75), 4.6)
	sign_board("Pharmacy", "PHARMACY / 24H", Vector3(69, 3.85, -9.75), 4.6, 0, "rust")
	sign_board("Pawn", "CASH FOR GOLD", Vector3(75, 3.85, -9.75), 4.6, 0, "dark", Color("d9c37a"))
	sign_board("PharmacyBlade", "RX", Vector3(71.7, 4.9, -9.2), 0.9, PI / 2, "rust", Color("ffe6a3"), 1.4)
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
	sign_board("Garage", "ORTIZ AUTO / BODY", Vector3(71, 3.85, 9.75), 4.6, PI, "dark", Color("d9c37a"))
	sign_board("Cafe", "CAFE LUNA", Vector3(77, 3.85, 9.75), 3.4, PI, "rust")
	sign_board("Closed", "TO LET", Vector3(83, 3.85, 9.75), 2.4, PI, "plaster_grey", Color("343c39"))
	# Street furniture, clear of the spine lane (|z| <= 4), the wrecked car at x 66..70
	# and the ledge ramp (x 67..77, z -6.8..-4.4).
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
	sign_board("Banner", "DISTRICT 04 / KEEP CLEAR", Vector3(72, 6.1, 0), 5.0, 0, "rust", Color("f0dca6"), 0.9)

func bus_shelter(label: String, at: Vector3) -> void:
	for x in [-1.8, 1.8]:
		pipe(label + "Post", at + Vector3(x, 1.3, 0.8), 2.6, 0.08, "dark")
		pipe(label + "PostB", at + Vector3(x, 1.3, -0.8), 2.6, 0.08, "dark")
	box(label + "Roof", at + Vector3(0, 2.65, 0), Vector3(4.2, 0.12, 2.0), "teal", 0, true)
	box(label + "Back", at + Vector3(0, 1.3, 0.85), Vector3(4.0, 2.2, 0.08), "glass", 0, true)
	box(label + "Bench", at + Vector3(0, 0.45, 0.35), Vector3(3.2, 0.1, 0.5), "rust", 0, true)
	box(label + "BenchLegs", at + Vector3(0, 0.2, 0.35), Vector3(3.0, 0.4, 0.1), "dark")
	sign_board(label + "Sign", "ROUTE 12 / CENTRAL", at + Vector3(0, 2.95, -0.9), 2.4, 0, "teal", Color("e7ce93"), 0.5)

# --- Boulevard (x 74..100): a tram stop explains the raised ledge ------------

func boulevard() -> void:
	# Tram rails run the length of the boulevard, flush with the road.
	for z in [-2.6, -1.2]:
		box("TramRail", Vector3(87, 0.012, z), Vector3(30, 0.02, 0.12), "dark")
	for x in range(74, 101, 2):
		box("Sleeper", Vector3(x, 0.008, -1.9), Vector3(0.3, 0.012, 2.0), "concrete_dark")
	# Zebra crossing replaces the old solid paint square at the plaza centre.
	for i in 6:
		box("Crossing", Vector3(79.5 + i * 1.0, 0.012, 0), Vector3(0.5, 0.02, 6.0), "paint_line")
	# Hazard edge on the ledge ramp (x 67..77) so the climb reads from the street.
	box("RampEdge", Vector3(72, 1.36, -4.45), Vector3(10.2, 0.04, 0.16), "hazard", 0, false, 0.2551)
	# Platform edge stripe and a shelter on the existing ledge (top y 2.6, z -8.75..-5.25).
	box("PlatformStripe", Vector3(86, 2.61, -5.5), Vector3(18, 0.02, 0.3), "hazard")
	for x in [80.0, 84.0, 88.0, 92.0]:
		pipe("PlatformPost", Vector3(x, 4.2, -6.2), 3.2, 0.1, "dark")
	box("PlatformRoof", Vector3(86, 5.85, -7.1), Vector3(14, 0.14, 3.6), "teal", 0, false, 0.03)
	box("PlatformFascia", Vector3(86, 5.55, -5.3), Vector3(14, 0.5, 0.12), "rust")
	sign_board("PlatformSign", "PLATFORM 2 / EASTBOUND", Vector3(86, 5.55, -5.22), 5.0, 0, "rust", Color("f0dca6"), 0.5)
	box("PlatformBench", Vector3(83, 3.0, -8.2), Vector3(2.6, 0.1, 0.5), "rust")
	box("PlatformBenchB", Vector3(89, 3.0, -8.2), Vector3(2.6, 0.1, 0.5), "rust")
	box("TicketMachine", Vector3(93.5, 3.35, -8.3), Vector3(0.7, 1.5, 0.5), "teal")
	# Station facade on the north wall (z = -10): pilasters, tiled band, clock.
	for x in [77.0, 83.0, 89.0, 95.0]:
		box("StationPilaster", Vector3(x, 3.0, -9.85), Vector3(0.7, 6.0, 0.35), "concrete")
	box("StationBand", Vector3(86, 1.1, -9.8), Vector3(24, 1.2, 0.1), "teal")
	box("StationCornice", Vector3(86, 6.25, -9.8), Vector3(26, 0.5, 0.8), "dark")
	sign_board("StationName", "CANAL STREET", Vector3(86, 4.6, -9.72), 6.5, 0, "dark", Color("e7ce93"))
	pipe("Clock", Vector3(93, 4.8, -9.6), 0.2, 0.7, "plaster", 0.0, PI / 2)
	pipe("ClockRim", Vector3(93, 4.8, -9.66), 0.2, 0.8, "dark", 0.0, PI / 2)
	# Overhead catenary posts either side of the road.
	for x in [78.0, 90.0]:
		pipe("CatenaryPost", Vector3(x, 3.4, 8.6), 6.8, 0.12, "dark")
		pipe("CatenaryArm", Vector3(x, 6.6, 6.2), 4.8, 0.06, "dark", 0.0, PI / 2)
	pipe("CatenaryWire", Vector3(87, 6.55, -1.9), 30.0, 0.025, "dark", PI / 2, PI / 2)
	# South wall (z = 10): a shuttered cinema gives the block some personality.
	box("CinemaMarquee", Vector3(84, 4.5, 9.3), Vector3(8.0, 1.6, 1.4), "rust")
	box("MarqueeUnder", Vector3(84, 3.65, 9.3), Vector3(8.2, 0.14, 1.6), "hazard")
	sign_board("MarqueeText", "RIALTO / CLOSED FOR REPAIRS", Vector3(84, 4.5, 8.55), 7.6, PI, "plaster", Color("343c39"), 1.2)
	for x in [80.5, 82.5, 84.5, 86.5]:
		box("CinemaDoor", Vector3(x, 1.4, 9.85), Vector3(1.6, 2.8, 0.12), "teal")
	box("CinemaPoster", Vector3(89.5, 2.0, 9.85), Vector3(1.4, 2.0, 0.1), "plaster_ochre")
	box("CinemaPosterB", Vector3(78.5, 2.0, 9.85), Vector3(1.4, 2.0, 0.1), "brick_dark")
	box("CinemaCornice", Vector3(84, 6.25, 9.8), Vector3(14, 0.5, 0.8), "dark")

# --- End plaza (x 98..118): enclosed, with a closed tunnel as the exit tease ---

func end_plaza() -> void:
	for z in [-8.3, 8.3]:
		box("PlazaWall", Vector3(109, 3.0, z), Vector3(20, 6.0, 0.6), "plaster_ochre", 0, true)
		box("PlazaCornice", Vector3(109, 6.2, z), Vector3(20.6, 0.5, 0.9), "dark")
		for x in [102.0, 108.0, 114.0]:
			box("PlazaPilaster", Vector3(x, 3.0, z + (0.45 if z < 0 else -0.45)), Vector3(0.6, 6.0, 0.3), "concrete")
			box("PlazaWin", Vector3(x + 3.0, 3.6, z + (0.36 if z < 0 else -0.36)), Vector3(1.6, 1.4, 0.12), "glass")
	# Tunnel portal closes the far end.
	box("TunnelWall", Vector3(118.3, 3.0, 0), Vector3(0.6, 6.0, 17.2), "concrete", 0, true)
	for z in [-3.2, 3.2]:
		box("TunnelPier", Vector3(117.8, 2.6, z), Vector3(0.7, 5.2, 0.9), "concrete_dark", 0, true)
	box("TunnelHeader", Vector3(117.8, 5.4, 0), Vector3(0.7, 0.8, 7.3), "concrete_dark", 0, true)
	box("TunnelShutter", Vector3(117.9, 2.5, 0), Vector3(0.14, 5.0, 5.6), "teal", 0, true)
	for y in [0.4, 0.9, 1.4, 1.9, 2.4, 2.9, 3.4, 3.9, 4.4]:
		box("TunnelRib", Vector3(117.8, y, 0), Vector3(0.08, 0.06, 5.6), "dark")
	sign_board("TunnelSign", "TRANSIT TUNNEL / DISTRICT 05", Vector3(117.7, 5.4, 0), 6.5, -PI / 2, "rust", Color("f0dca6"), 0.7)
	sign_board("TunnelClosed", "CLOSED / ROAD WORKS", Vector3(117.75, 3.3, 0), 3.2, -PI / 2, "hazard", Color("2a2a24"), 0.7)
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
	sign_board("PlazaSign", "DISTRICT 04 / TRANSIT AUTHORITY", Vector3(109, 4.9, -7.95), 8.0)
	sign_board("PlazaNotice", "NO STOPPING", Vector3(104, 2.4, 7.95), 2.2, PI, "plaster_grey", Color("343c39"), 0.7)

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
