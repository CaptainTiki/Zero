extends "res://tools/level_kit.gd"
## Bakes the Level 01 greybox: scenes/levels/l01_district04.tscn.
## Layout numbers match docs/LEVEL01_PLAN.md. Only scenes/generated/ is replaced.
## Add editor dressing in the public inherited scene; see docs/LEVEL_EDITING.md.
##   godot --headless --path . -s res://tools/build_l01_greybox.gd

const ROAD_W := 22.0
const PAVE_W := 4.0
const DOOR_COLOR := "car_red"

func _initialize() -> void:
	call_deferred("build")

func build() -> void:
	art.name = "L01District04"
	art.set_script(load("res://scripts/levels/level_base.gd"))
	arena_set_piece()
	environment()
	ground()
	yard()
	service_lane()
	route_12()
	canal_street()
	john_trial()
	west_district()
	storm_drains()
	plaza()
	museum()
	actors()
	save_scene("res://scenes/generated/l01_district04.tscn")

# --- helpers -----------------------------------------------------------------

func kerb(label: String, center: Vector3, length: float, rise_dir: Vector3) -> void:
	var along_x := absf(rise_dir.z) > 0.5
	var size := Vector3(length, 0.05, 0.5) if along_x else Vector3(0.5, 0.05, length)
	var node := box(label, center + Vector3(0, 0.08, 0), size, "concrete", 0, true)
	var rot := Vector3.ZERO
	if along_x:
		rot.x = 0.34 if rise_dir.z < 0.0 else -0.34
	else:
		rot.z = 0.34 if rise_dir.x > 0.0 else -0.34
	node.rotation = rot
	(art.get_node(label + "Solid") as Node3D).rotation = rot

func road(label: String, x0: float, z0: float, x1: float, z1: float, along_x: bool, gaps_a: Array = [], gaps_b: Array = []) -> void:
	slab(label, x0, z0, x1, z1, 0.0, 0.5, "asphalt")
	var cx := (x0 + x1) / 2.0
	var cz := (z0 + z1) / 2.0
	var index := 0
	if along_x:
		for seg in _segments(x0, x1, gaps_a):
			slab("%sPaveN%d" % [label, index], seg[0], z0, seg[1], z0 + PAVE_W, 0.15, 0.3, "concrete")
			kerb("%sKerbN%d" % [label, index], Vector3((seg[0] + seg[1]) / 2.0, 0, z0 + PAVE_W + 0.2), seg[1] - seg[0], Vector3(0, 0, -1))
			kerb("%sEndN%dA" % [label, index], Vector3(seg[0] - 0.2, 0, z0 + PAVE_W / 2.0), PAVE_W, Vector3(1, 0, 0))
			kerb("%sEndN%dB" % [label, index], Vector3(seg[1] + 0.2, 0, z0 + PAVE_W / 2.0), PAVE_W, Vector3(-1, 0, 0))
			index += 1
		for seg in _segments(x0, x1, gaps_b):
			slab("%sPaveS%d" % [label, index], seg[0], z1 - PAVE_W, seg[1], z1, 0.15, 0.3, "concrete")
			kerb("%sKerbS%d" % [label, index], Vector3((seg[0] + seg[1]) / 2.0, 0, z1 - PAVE_W - 0.2), seg[1] - seg[0], Vector3(0, 0, 1))
			kerb("%sEndS%dA" % [label, index], Vector3(seg[0] - 0.2, 0, z1 - PAVE_W / 2.0), PAVE_W, Vector3(1, 0, 0))
			kerb("%sEndS%dB" % [label, index], Vector3(seg[1] + 0.2, 0, z1 - PAVE_W / 2.0), PAVE_W, Vector3(-1, 0, 0))
			index += 1
		box(label + "Line", Vector3(cx, 0.012, cz), Vector3(absf(x1 - x0), 0.02, 0.25), "paint_line")
	else:
		for seg in _segments(z0, z1, gaps_a):
			slab("%sPaveW%d" % [label, index], x0, seg[0], x0 + PAVE_W, seg[1], 0.15, 0.3, "concrete")
			kerb("%sKerbW%d" % [label, index], Vector3(x0 + PAVE_W + 0.2, 0, (seg[0] + seg[1]) / 2.0), seg[1] - seg[0], Vector3(-1, 0, 0))
			kerb("%sEndW%dA" % [label, index], Vector3(x0 + PAVE_W / 2.0, 0, seg[0] - 0.2), PAVE_W, Vector3(0, 0, 1))
			kerb("%sEndW%dB" % [label, index], Vector3(x0 + PAVE_W / 2.0, 0, seg[1] + 0.2), PAVE_W, Vector3(0, 0, -1))
			index += 1
		for seg in _segments(z0, z1, gaps_b):
			slab("%sPaveE%d" % [label, index], x1 - PAVE_W, seg[0], x1, seg[1], 0.15, 0.3, "concrete")
			kerb("%sKerbE%d" % [label, index], Vector3(x1 - PAVE_W - 0.2, 0, (seg[0] + seg[1]) / 2.0), seg[1] - seg[0], Vector3(1, 0, 0))
			kerb("%sEndE%dA" % [label, index], Vector3(x1 - PAVE_W / 2.0, 0, seg[0] - 0.2), PAVE_W, Vector3(0, 0, 1))
			kerb("%sEndE%dB" % [label, index], Vector3(x1 - PAVE_W / 2.0, 0, seg[1] + 0.2), PAVE_W, Vector3(0, 0, -1))
			index += 1
		box(label + "Line", Vector3(cx, 0.012, cz), Vector3(0.25, 0.02, absf(z1 - z0)), "paint_line")

func bus(label: String, at: Vector3, yaw: float) -> void:
	var basis := Basis(Vector3.UP, yaw)
	box(label, at + Vector3(0, 1.7, 0), Vector3(11.0, 3.0, 2.6), "car_white", yaw, true)
	box(label + "Band", at + basis * Vector3(0, 1.4, 1.32), Vector3(11.0, 0.6, 0.06), "car_blue", yaw)
	box(label + "BandB", at + basis * Vector3(0, 1.4, -1.32), Vector3(11.0, 0.6, 0.06), "car_blue", yaw)
	for x in [-4.0, -1.5, 1.5, 4.0]:
		box(label + "Win", at + basis * Vector3(x, 2.3, 1.32), Vector3(2.0, 1.0, 0.06), "glass", yaw)
		box(label + "WinB", at + basis * Vector3(x, 2.3, -1.32), Vector3(2.0, 1.0, 0.06), "glass", yaw)
	for corner in [Vector3(3.8, 0.5, 1.3), Vector3(-3.8, 0.5, 1.3), Vector3(3.8, 0.5, -1.3), Vector3(-3.8, 0.5, -1.3)]:
		pipe(label + "Wheel", at + basis * corner, 0.3, 0.5, "tyre", yaw, PI / 2)

func environment() -> void:
	var env := WorldEnvironment.new()
	env.environment = load("res://scenes/levels/m01_beats_1_5.tscn").instantiate().get_node("WorldEnvironment").environment
	add(env, "WorldEnvironment")
	var sun := DirectionalLight3D.new()
	sun.transform = Transform3D(Basis(Vector3(0.766, -0.383, 0.515), Vector3(0, 0.802, 0.597), Vector3(-0.643, -0.457, 0.614)), Vector3(0, 20, 0))
	sun.light_color = Color(1, 0.9, 0.76)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 160.0
	add(sun, "Sun")

func ground() -> void:
	# Greybox ground under everything; playable floors sit on top. Two holes are
	# left open for the storm drains: the works slot at the head of Mill Road and
	# the exit slot in the cross street.
	slab("GroundA", -80, -220, 174, -172, -0.05, 1.0, "concrete_dark")
	slab("GroundB", -80, -172, -24, -150, -0.05, 1.0, "concrete_dark")
	slab("GroundC", -12, -172, 174, -150, -0.05, 1.0, "concrete_dark")
	slab("GroundD", -80, -150, 174, -94, -0.05, 1.0, "concrete_dark")
	slab("GroundE", -80, -94, 118, -82, -0.05, 1.0, "concrete_dark")
	slab("GroundF", 124, -94, 174, -82, -0.05, 1.0, "concrete_dark")
	slab("GroundG", -80, -82, 174, 120, -0.05, 1.0, "concrete_dark")
	slab("GroundFar", 200, -220, 260, 120, -0.05, 1.0, "concrete_dark")

# Beat 1: yard x -12..12, z -12..12, exit door on the east wall at z 0.
func yard() -> void:
	slab("YardFloor", -12, -12, 12, 12, 0.0, 0.5, "concrete")
	wall("YardN", -12, -12, 12, -11.4, 6.0)
	wall("YardS", -12, 11.4, 12, 12, 6.0)
	wall("YardW", -12, -12, -11.4, 12, 6.0)
	wall("YardE_N", 11.4, -12, 12, -3, 6.0)
	wall("YardE_S", 11.4, 3, 12, 12, 6.0)
	# Buildings behind the yard walls so it does not float.
	building("YardBackN", -14, -30, 14, -12, 10.0, "brick")
	building("YardBackW", -30, -14, -12, 14, 8.0, "plaster_grey")
	building("YardBackS", -14, 12, 14, 30, 9.0, "brick_dark")
	# Wreck and pistol.
	box("Wreck", Vector3(-5, 1.0, 2), Vector3(5, 2, 3), "metal_blue", 0.4, true)
	box("WreckTail", Vector3(-9, 0.9, 5), Vector3(4, 1.4, 1.6), "metal_blue", -0.5, true)
	scene("GunPickup", "res://scenes/props/gun_pickup.tscn", Vector3(-1, 0.8, -1))
	# Secret 1: crate, tail, wreck roof. The first unit's shells are still up there.
	box("YardCrateA", Vector3(-1.5, 0.4, 4.6), Vector3(1.2, 0.8, 1.2), "rust", 0, true)
	box("YardCrateB", Vector3(-3.0, 0.7, 4.3), Vector3(1.2, 1.4, 1.2), "rust", 0, true)
	secret("SecretWreck", Vector3(-5, 2.2, 1.5), "res://scenes/props/ammo_pickup.tscn")
	# The taught door: kick_door.tscn fills a 6 unit gap, oriented for +X exit.
	scene("YardDoor", "res://scenes/props/kick_door.tscn", Vector3(11.7, 0.025, 0), -PI / 2)
	beat_line("Beat2Line", Vector3(16, 1.5, 0), Vector3(1, 3, 8), 2)

# Beat 2: service lane x 12..52, z -4..4, shop backs both sides, busted shop at x 34 north.
func service_lane() -> void:
	slab("LaneFloor", 12, -4, 52, 4, 0.0, 0.5, "asphalt")
	building("LaneShopsN_A", 12, -22, 30, -4, 8.0, "plaster_grey")
	building("LaneShopsN_B", 38, -22, 52, -4, 9.0, "brick")
	# Busted shop interior x 30..38, z -12..-4, door on the lane side.
	slab("BustedFloor", 30, -12, 38, -4, 0.0, 0.5, "concrete")
	wall("BustedW", 30, -12, 30.6, -4, 8.0)
	wall("BustedE", 37.4, -12, 38, -4, 8.0)
	wall("BustedN", 30, -12, 38, -11.4, 8.0)
	wall("BustedFrontW", 30, -4.6, 32.6, -4, 8.0)
	wall("BustedFrontE", 35.4, -4.6, 38, -4, 8.0)
	# A lintel over a 4 high doorway, not a wall: wall() starts at the ground.
	box("BustedLintel", Vector3(34, 6.0, -4.3), Vector3(2.8, 4.0, 0.6), "concrete_dark", 0, true)
	box("BustedRoof", Vector3(34, 8.2, -8), Vector3(8, 0.4, 8), "concrete_dark", 0, true)
	# Busted door leaning inside, door colour: teaches the rule by example.
	box("BustedDoor", Vector3(33.2, 0.9, -6.0), Vector3(1.3, 2.2, 0.12), DOOR_COLOR, 0.9, false, 1.2)
	scene("LaneCrate", "res://scenes/props/supply_crate.tscn", Vector3(35, 0.1, -9))
	building("LaneShopsS_W", 12, 4, 20, 22, 8.0, "plaster_ochre")
	building("LaneShopsS_E", 28, 4, 52, 22, 8.0, "plaster_ochre")
	building("LaneShopsS_Back", 20, 12, 28, 22, 8.0, "plaster_ochre")
	# Storeroom x 20..28, z 4..12 with a kickable door on the lane (door colour).
	slab("StoreFloor", 20, 4, 28, 12, 0.0, 0.5, "concrete")
	wall("StoreW", 20, 4, 20.6, 12, 8.0, "plaster_grey")
	wall("StoreE", 27.4, 4, 28, 12, 8.0, "plaster_grey")
	wall("StoreFront_W", 20, 4, 21, 4.6, 8.0, "plaster_grey")
	wall("StoreFront_E", 27, 4, 28, 4.6, 8.0, "plaster_grey")
	box("StoreLintel", Vector3(24, 6.0, 4.3), Vector3(6, 4.0, 0.6), "plaster_grey", 0, true)
	box("StoreRoof", Vector3(24, 8.2, 8), Vector3(8, 0.4, 8), "concrete_dark", 0, true)
	scene("StoreDoor", "res://scenes/props/kick_door.tscn", Vector3(24, 0.025, 4.3), 0.0)
	box("StoreShelf", Vector3(26.5, 1.0, 9), Vector3(1.0, 2.0, 4.0), "rust", 0, true)
	secret("SecretStore", Vector3(22.5, 0.2, 10), "res://scenes/props/health_pickup.tscn")
	scene("AmmoStore", "res://scenes/props/ammo_pickup.tscn", Vector3(25, 0.2, 10))
	ambush("AmbushStore", Vector3(24, 1.5, 9), Vector3(6, 3, 4), Vector3(30, 0, 0), 3)
	# Lane fights.
	scene("FodderLane1", "res://scenes/enemies/fodder.tscn", Vector3(24, 0.3, -1))
	scene("FodderLane2", "res://scenes/enemies/fodder.tscn", Vector3(27, 0.3, 2))
	scene("FodderLane3", "res://scenes/enemies/fodder.tscn", Vector3(42, 0.3, -2))
	scene("FodderLane4", "res://scenes/enemies/fodder.tscn", Vector3(46, 0.3, 2))
	scene("FodderLane5", "res://scenes/enemies/fodder.tscn", Vector3(34, 0.4, -7))
	scene("FodderLane6", "res://scenes/enemies/fodder.tscn", Vector3(49, 0.3, -1))
	beat_line("Beat3Line", Vector3(53, 1.5, 0), Vector3(1, 3, 8), 3)

# Beat 3: Route 12 runs north-south, x 52..74, z -60..+40. Bus at z +30, cordon at z -40.
func route_12() -> void:
	# Pavement drops at the lane mouth (z -4..4) and stops short of the T with Canal Street.
	road("Route12", 52, -60, 74, 40, false, [[-60, -49], [-4, 4]], [[-60, -49]])
	# Buildings east of the road, and the south block; the lane opens through the west block.
	building("R12EastA", 74, -20, 100, 40, 12.0, "brick")
	building("R12WestS", 22, 22, 52, 40, 10.0, "plaster_grey")
	# Split around the busted shop interior (x 30..38, z -12..-4), the way the museum
	# shell is split around the lobby. As one block it filled the shop with solid geometry.
	building("R12WestN_W", 22, -49, 30, -4, 10.0, "plaster_ochre")
	building("R12WestN_E", 38, -49, 52, -4, 10.0, "plaster_ochre")
	building("R12WestN_N", 30, -49, 38, -12, 10.0, "plaster_ochre")
	# South end: bus across the road at z 30 with the street continuing behind it.
	bus("SouthBus", Vector3(63, 0, 30), 0.0)
	# Secret 3: past the bus on the pavement to a stub closed by the next block.
	building("R12SouthEnd", 50, 40, 76, 52, 12.0, "brick")
	car("StubCar", Vector3(60, 0, 36), 0.3, "car_white")
	secret("SecretStub", Vector3(67, 0.2, 37), "res://scenes/props/health_pickup.tscn")
	ambush("AmbushStub", Vector3(63, 1.5, 36), Vector3(14, 3, 5), Vector3(63, 0, 18), 4)
	# Cordon at z -40: barriers with a 4 wide gap in the middle, drums, light bar post.
	for x in [53.9, 57.6, 61.3, 65.0, 68.7, 72.4]:
		box("CordonBarrier", Vector3(x, 0.5, -40), Vector3(3.7, 1.0, 0.5), "concrete", 0, true)
		box("CordonStripe", Vector3(x, 0.75, -39.7), Vector3(3.6, 0.3, 0.05), "hazard")
	# Wire mesh above the barriers: the road is shut, not hopped.
	box("CordonFence", Vector3(63, 2.2, -40), Vector3(22, 2.4, 0.08), "glass", 0, true)
	for x in [56.0, 63.0, 70.0]:
		pipe("CordonFencePost", Vector3(x, 1.7, -40), 3.4, 0.06, "dark")
	detour_building()
	for x in [56.0, 70.0]:
		pipe("CordonDrum", Vector3(x, 0.45, -37), 0.9, 0.3, "hazard")
	pipe("CordonPost", Vector3(53, 2.5, -42), 5.0, 0.1, "dark")
	box("CordonLightBar", Vector3(53, 5.1, -42), Vector3(1.6, 0.25, 0.5), "car_blue")
	# Queue of abandoned cars south of the barriers.
	car("QueueA", Vector3(58, 0, -30), -PI / 2 + 0.1, "car_red")
	car("QueueB", Vector3(66, 0, -25), -PI / 2 - 0.15, "car_tan")
	car("QueueC", Vector3(59, 0, -18), -PI / 2 + 0.05, "car_blue")
	car("QueueD", Vector3(68, 0, -12), -PI / 2, "car_green")
	# Fight: fodder among the cars, Rammer behind the barriers.
	scene("FodderR12_1", "res://scenes/enemies/fodder.tscn", Vector3(62, 0.3, -20))
	scene("FodderR12_2", "res://scenes/enemies/fodder.tscn", Vector3(56, 0.3, -26))
	scene("FodderR12_3", "res://scenes/enemies/fodder.tscn", Vector3(70, 0.3, -32))
	scene("FodderR12_4", "res://scenes/enemies/fodder.tscn", Vector3(58, 0.3, 10))
	scene("FodderR12_5", "res://scenes/enemies/fodder.tscn", Vector3(68, 0.3, 14))
	scene("FodderR12_6", "res://scenes/enemies/fodder.tscn", Vector3(64, 0.3, -6))
	scene("FodderR12_7", "res://scenes/enemies/fodder.tscn", Vector3(55, 0.3, -44))
	scene("FodderR12_8", "res://scenes/enemies/fodder.tscn", Vector3(71, 0.3, -46))
	scene("Rammer", "res://scenes/enemies/rammer.tscn", Vector3(63, 0.3, -20))
	scene("HealthR12", "res://scenes/props/health_pickup.tscn", Vector3(72, 0.2, -8))
	scene("AmmoR12", "res://scenes/props/ammo_pickup.tscn", Vector3(54, 0.2, -34))
	beat_line("Beat4Line", Vector3(88, 5.5, -50), Vector3(30, 4, 1), 4)

# Beat 3b: the pharmacy detour, x 74..100, z -49..-20. In from Route 12 through a
# kickable door at z -30, ground floor fight, ramp up to the first floor, out of
# a window onto a landing over Canal Street, down two landings to the pavement.
func detour_building() -> void:
	slab("DetourFloor", 74, -49, 100, -20, 0.0, 0.5, "plaster")
	slab("DetourUpper", 76, -49, 100, -34, 4.0, 0.4, "concrete_dark")
	box("DetourRoof", Vector3(87, 8.2, -34.5), Vector3(26, 0.4, 29), "concrete_dark", 0, true)
	wall("DetourS", 74, -20.6, 100, -20, 8.0, "plaster_grey")
	wall("DetourE", 99.4, -49, 100, -20, 8.0, "plaster_grey")
	# West wall on Route 12 with the door gap at z -33..-27.
	wall("DetourW_N", 74, -49, 74.6, -33, 8.0, "plaster_grey")
	wall("DetourW_S", 74, -27, 74.6, -20, 8.0, "plaster_grey")
	box("DetourW_Lintel", Vector3(74.3, 6.0, -30), Vector3(0.6, 4.0, 6.0), "plaster_grey", 0, true)
	scene("DetourDoor", "res://scenes/props/kick_door.tscn", Vector3(74.3, 0.025, -30), -PI / 2)
	# North wall on Canal Street: solid below, window opening on the first floor at x 84..88.
	wall("DetourN_Low", 74, -49, 100, -48.4, 4.0, "plaster_grey")
	wall("DetourN_W", 74, -49, 84, -48.4, 8.0, "plaster_grey")
	wall("DetourN_E", 88, -49, 100, -48.4, 8.0, "plaster_grey")
	box("DetourN_Lintel", Vector3(86, 7.4, -48.7), Vector3(4, 1.2, 0.6), "plaster_grey", 0, true)
	# Ramp from the ground floor (0) to the upper floor (4.0): along -Z at x 96,
	# from z -22 up to the slab edge at z -34. Rotated about X so it rises toward -Z.
	var ramp := box("DetourRamp", Vector3(96, 1.82, -28), Vector3(3.0, 0.4, 12.4), "concrete", 0, true)
	ramp.rotation.x = 0.34
	(art.get_node("DetourRampSolid") as Node3D).rotation.x = 0.34
	wall("DetourRampRail", 94.3, -34, 94.6, -22, 5.0, "dark")
	# Counter and shelving downstairs for close-quarters cover.
	box("DetourCounter", Vector3(86, 0.6, -40), Vector3(8, 1.2, 1.2), "teal", 0, true)
	box("DetourShelfA", Vector3(80, 1.0, -30), Vector3(1.0, 2.0, 6.0), "rust", 0, true)
	box("DetourShelfB", Vector3(94, 1.0, -30), Vector3(1.0, 2.0, 6.0), "rust", 0, true)
	scene("DetourCrate", "res://scenes/props/supply_crate.tscn", Vector3(96, 0.1, -46))
	scene("AmmoDetour", "res://scenes/props/ammo_pickup.tscn", Vector3(78, 4.4, -46))
	# Fire-escape landings outside the window, down to the Canal Street pavement.
	box("WindowLanding", Vector3(86, 3.9, -50.5), Vector3(4.0, 0.2, 2.6), "dark", 0, true)
	box("WindowLandingB", Vector3(82, 2.6, -50.5), Vector3(3.0, 0.2, 2.6), "dark", 0, true)
	box("WindowLandingC", Vector3(78.5, 1.3, -50.5), Vector3(3.0, 0.2, 2.6), "dark", 0, true)
	# Close-quarters fight inside.
	for i in 3:
		scene("FodderDetour%d" % i, "res://scenes/enemies/fodder.tscn", Vector3(80 + i * 6, 0.3, -36 - i * 3))
	scene("FodderDetourUp", "res://scenes/enemies/fodder.tscn", Vector3(92, 4.5, -42))
	scene("FodderDetourUpB", "res://scenes/enemies/fodder.tscn", Vector3(80, 4.5, -40))

# Beat 4: Canal Street runs east-west, x 30..150, z -71..-49. Scaffold at x 30, corner at x 150.
func canal_street() -> void:
	# Kerb drops: cross street on the north side, Route 12 and the corner on the south side.
	road("CanalStreet", 30, -71, 150, -49, true, [[118, 128]], [[56, 70], [132, 146]])
	# Corner: the road turns south at x 150 and runs off behind the east block.
	road("CanalSouth", 128, -49, 150, 20, false)
	bus("CornerBus", Vector3(139, 0, 12), 0.0)
	# Secret 7: past the bus to a wrecked patrol car and the end of the road.
	building("CornerSouthEnd", 126, 20, 152, 32, 10.0, "plaster_grey")
	car("PatrolCar", Vector3(136, 0, 16.5), 0.5, "car_white")
	box("PatrolLightBar", Vector3(135.8, 1.55, 16.3), Vector3(0.5, 0.2, 1.2), "car_blue", 0.5)
	secret("SecretPatrol", Vector3(144, 0.2, 17), "res://scenes/props/ammo_pickup.tscn")
	ambush("AmbushPatrol", Vector3(140, 1.5, 17), Vector3(14, 3, 4), Vector3(139, 0, 2), 3)
	alley_and_walkway()
	# Canal Street is shut at x 90..94: the facade has come down across the full
	# width, so from the pharmacy window the only way on is west through the
	# scaffold. Everything east of here is reached later, out of the drains.
	box("CanalCollapse", Vector3(92, 2.5, -60), Vector3(4.0, 5.0, 22.0), "concrete_dark", 0, true)
	box("CanalCollapseB", Vector3(95, 1.2, -66), Vector3(3.0, 2.4, 6.0), "brick", 0.25, true)
	box("CanalCollapseC", Vector3(89, 1.0, -57), Vector3(3.0, 2.0, 5.0), "plaster_grey", -0.3, true)
	pipe("CanalCollapseCrane", Vector3(94, 5.5, -58), 16.0, 0.35, "rust", 0.4, 1.15)
	# Street blocked at x 130: two buses nose to tail across the full width.
	bus("BlockBusA", Vector3(130, 0, -65.5), PI / 2)
	bus("BlockBusB", Vector3(130, 0, -54.5), PI / 2)
	box("BlockRubble", Vector3(130, 0.6, -60), Vector3(4, 1.2, 4), "concrete_dark", 0.3, true)
	# The shop front north of the corner has come down across the street: no way
	# north to the plaza from here. Route continues south along the corner road.
	box("CollapseA", Vector3(141, 1.5, -53), Vector3(18, 3.0, 6.0), "concrete_dark", 0.15, true)
	box("CollapseB", Vector3(139, 3.6, -55), Vector3(10, 2.0, 4.0), "plaster_grey", -0.2, true)
	box("CollapseC", Vector3(146, 0.8, -50.5), Vector3(6, 1.6, 3.0), "brick", 0.4, true)
	# Roof route: from the south shop roof (5.0, x 100..128) a ramp drops to the corner road.
	box("RoofRamp", Vector3(133.5, 2.5, -45), Vector3(12.4, 0.4, 3.2), "concrete", 0, true, -0.4)
	# Secret 4: air-conditioner stack up onto the pharmacy roof (8.4) from the shop roof (5.0).
	box("AcUnitA", Vector3(101.5, 5.4, -40), Vector3(1.6, 0.8, 1.6), "teal", 0, true)
	box("AcUnitB", Vector3(101.5, 6.2, -37.8), Vector3(1.6, 0.8, 1.6), "teal", 0, true)
	box("AcUnitC", Vector3(101.5, 7.0, -35.6), Vector3(1.6, 0.8, 1.6), "rust", 0, true)
	box("AcUnitD", Vector3(101.5, 7.75, -33.4), Vector3(1.6, 0.7, 1.6), "rust", 0, true)
	secret("SecretPharmRoof", Vector3(92, 8.6, -30), "res://scenes/props/boost_pickup.tscn")
	scene("AmmoPharmRoof", "res://scenes/props/ammo_pickup.tscn", Vector3(80, 8.6, -30))
	scene("FodderRoofA", "res://scenes/enemies/fodder.tscn", Vector3(108, 5.3, -40))
	scene("FodderRoofB", "res://scenes/enemies/fodder.tscn", Vector3(116, 5.3, -30))
	scene("HunterRoof", "res://scenes/enemies/hunter.tscn", Vector3(122, 5.3, -44))
	# North shops x 74..128 with a cross street gap at x 118..128 heading north.
	building("ShopsN_A", 30, -100, 70, -71, 11.0, "plaster_grey")
	building("ShopsN_B", 74, -100, 118, -71, 12.0, "brick")
	# Works site: the drain exit slot takes x 118..124, z -100..-88, and a four
	# wide strip on the east still reaches the back alley.
	slab("CrossStreet", 118, -82, 128, -71, 0.0, 0.5, "asphalt")
	slab("CrossStreetN", 118, -100, 128, -94, 0.0, 0.5, "asphalt")
	slab("CrossStreetE", 124, -94, 128, -82, 0.0, 0.5, "asphalt")
	kerb("CrossKerb", Vector3(123, 0, -71.2), 10.0, Vector3(0, 0, 1))
	scene("AmmoCross", "res://scenes/props/ammo_pickup.tscn", Vector3(121, 0.2, -77))
	# Secret 5: the loop. Back alley x 70..128, z -108..-100, then a gap x 70..74 back to the street.
	slab("BackAlley", 70, -108, 128, -100, 0.0, 0.5, "asphalt")
	slab("BackGap", 70, -100, 74, -71, 0.0, 0.5, "asphalt")
	# Shut: this gap would let the player reach the east side without going west.
	box("BackGapRubble", Vector3(72, 2.4, -74), Vector3(4.4, 4.8, 4.0), "concrete_dark", 0, true)
	box("BackGapRubbleB", Vector3(72, 1.0, -78), Vector3(4.0, 2.0, 4.0), "brick", 0.2, true)
	building("BackAlleyN", 60, -130, 130, -108, 14.0, "brick_dark")
	building("BackAlleyW", 60, -108, 70, -71, 11.0, "plaster_grey")
	for x in [80.0, 96.0, 112.0]:
		box("BackDumpster", Vector3(x, 0.8, -106.5), Vector3(2.4, 1.6, 1.4), "teal", 0, true)
	secret("SecretLoop", Vector3(96, 0.2, -103), "res://scenes/props/supply_crate.tscn")
	scene("AmmoLoop", "res://scenes/props/ammo_pickup.tscn", Vector3(88, 0.2, -104))
	for i in 6:
		scene("FodderLoop%d" % i, "res://scenes/enemies/fodder.tscn", Vector3(78 + i * 8, 0.3, -104 + (i % 2) * 3))
	scene("HunterLoop", "res://scenes/enemies/hunter.tscn", Vector3(72, 0.3, -90))
	# x 128..130 closes the sliver between the cross street and the plaza.
	building("PlazaWestWall", 128, -100, 130, -71, 10.0, "plaster_ochre")
	# Sal's: shuttered frontage on the north side at x 100.
	box("SalsShutter", Vector3(100, 1.6, -70.9), Vector3(6, 3.2, 0.2), "teal")
	styled_sign("SalsSign", "SAL'S PIZZA", Vector3(100, 4.0, -70.85), 5.0, 0, {"backing": "car_red", "ink": Color("f4f1e6"), "font": ["Georgia"], "italic": true})
	# South shops x 74..128, fire escape at x 90 up the south facade.
	# West of Route 12 the R12WestN block already fills x 22..52 down to z -49.
	building("ShopsS_B", 100, -49, 128, -20, 5.0, "plaster")
	fire_escape(Vector3(104, 0, -49))
	# West end: collapsed scaffold across the road at x 30 with the road visible beyond.
	# The scaffold has come down over the north half only: the south half of the
	# carriageway is walkable, and west is now the route, not a tease.
	for i in 3:
		pipe("ScaffoldPole", Vector3(31 + i * 0.3, 2.5, -70 + i * 3.0), 5.0, 0.08, "rust", 0.0, 0.5)
	box("ScaffoldDeck", Vector3(32, 1.6, -66.5), Vector3(3, 0.3, 9), "plaster_grey", 0, true, 0.4)
	box("ScaffoldDeckB", Vector3(31, 3.2, -66.5), Vector3(3, 0.3, 9), "plaster_grey", 0, true, -0.5)
	road("CanalWestBeyond", 0, -71, 30, -49, true)
	car("BeyondCar", Vector3(12, 0, -66), 0.0, "car_white")
	# Shotgun and the street fights.
	scene("ShotgunPickup", "res://scenes/props/shotgun_pickup.tscn", Vector3(80, 0.1, -60))
	for i in 3:
		scene("FodderStreetA%d" % i, "res://scenes/enemies/fodder.tscn", Vector3(80 + i * 3, 0.3, -58 + i * 3))
	for i in 3:
		scene("FodderStreetB%d" % i, "res://scenes/enemies/fodder.tscn", Vector3(112 + i * 4, 0.3, -64 + i * 4))
	for i in 4:
		scene("FodderStreetC%d" % i, "res://scenes/enemies/fodder.tscn", Vector3(98 + i * 3, 0.3, -66 + (i % 2) * 10))
	scene("FodderCross", "res://scenes/enemies/fodder.tscn", Vector3(123, 0.3, -80))
	scene("FodderScaffold", "res://scenes/enemies/fodder.tscn", Vector3(40, 0.3, -58))
	scene("HunterStreet", "res://scenes/enemies/hunter.tscn", Vector3(139, 0.3, -30))
	scene("HunterStreetB", "res://scenes/enemies/hunter.tscn", Vector3(118, 0.3, -52))
	scene("RammerCorner", "res://scenes/enemies/rammer.tscn", Vector3(139, 0.3, -38))
	scene("HealthStreet", "res://scenes/props/health_pickup.tscn", Vector3(105, 0.2, -52))
	scene("AmmoStreet", "res://scenes/props/ammo_pickup.tscn", Vector3(86, 0.2, -68))
	scene("AmmoStreetB", "res://scenes/props/ammo_pickup.tscn", Vector3(112, 0.2, -66))
	beat_line("Beat8Line", Vector3(170, 1.5, -71), Vector3(8, 3, 1), 8)

func fire_escape(base: Vector3) -> void:
	# On the pavement in front of the facade (facade at base.z, street toward -z).
	# crate 1.0 -> dumpster 1.9 -> awning 2.8 -> landing 3.7 -> landing 4.6 -> shop roof 5.0
	box("FeCrate", base + Vector3(-3, 0.5, -1.6), Vector3(1.0, 1.0, 1.0), "rust", 0, true)
	box("FeDumpster", base + Vector3(-1, 0.95, -1.3), Vector3(2.4, 1.9, 1.4), "teal", 0, true)
	box("FeAwning", base + Vector3(1.5, 2.72, -1.0), Vector3(3.0, 0.16, 1.8), "car_red", 0, true)
	box("FeLandingA", base + Vector3(4.5, 3.62, -1.0), Vector3(3.0, 0.16, 1.8), "dark", 0, true)
	box("FeLandingB", base + Vector3(7.5, 4.52, -1.0), Vector3(3.0, 0.16, 1.8), "dark", 0, true)
	# Plank from the top landing onto the roof edge (rises toward +z, the building side).
	var plank := box("FePlank", base + Vector3(7.5, 4.82, -0.3), Vector3(2.4, 0.1, 1.6), "rust", 0, true)
	plank.rotation.x = -0.28
	(art.get_node("FePlankSolid") as Node3D).rotation.x = -0.28
	scene("BoostRoof", "res://scenes/props/boost_pickup.tscn", base + Vector3(14, 5.2, 14))

# Beat 4b: service alley east off the corner road (x 150..168, z 0..8), then the
# canal walkway north (x 166..174, z -71..8) into the plaza's east side.
func alley_and_walkway() -> void:
	slab("AlleyFloor", 150, 0, 168, 8, 0.0, 0.5, "asphalt")
	# Block between the corner road, the walkway and the plaza: x 150..166, z -71..0.
	building("AlleyN", 150, -71, 166, 0, 9.0, "brick_dark")
	building("AlleyS", 150, 8, 176, 30, 10.0, "plaster_grey")
	box("AlleyDumpster", Vector3(158, 0.8, 6.5), Vector3(2.4, 1.6, 1.4), "teal", 0, true)
	box("AlleyCrates", Vector3(163, 0.5, 1.2), Vector3(1.0, 1.0, 1.0), "rust", 0, true)
	scene("HealthAlley", "res://scenes/props/health_pickup.tscn", Vector3(154, 0.2, 5))
	scene("AmmoCorner", "res://scenes/props/ammo_pickup.tscn", Vector3(148, 0.2, -20))
	slab("Walkway", 166, -71, 174, 8, 0.15, 0.6, "concrete")
	kerb("WalkwayKerb", Vector3(165.8, 0, 4), 8.0, Vector3(1, 0, 0))
	for z in [-60.0, -40.0, -20.0]:
		box("WalkBench", Vector3(167.5, 0.45, z), Vector3(0.5, 0.08, 1.8), "rust", 0, true)
	for z in [-66.0, -50.0, -30.0, -10.0]:
		pipe("WalkLamp", Vector3(173.2, 2.2, z), 4.4, 0.08, "dark")
	# Fights: fodder in the alley, Rammer charging along the narrow walkway.
	scene("FodderAlleyA", "res://scenes/enemies/fodder.tscn", Vector3(156, 0.3, 3))
	scene("FodderAlleyB", "res://scenes/enemies/fodder.tscn", Vector3(161, 0.3, 5))
	scene("FodderAlleyC", "res://scenes/enemies/fodder.tscn", Vector3(165, 0.3, 2))
	scene("RammerWalk", "res://scenes/enemies/rammer.tscn", Vector3(170, 0.5, -30))
	scene("FodderWalkA", "res://scenes/enemies/fodder.tscn", Vector3(169, 0.5, -15))
	scene("FodderWalkB", "res://scenes/enemies/fodder.tscn", Vector3(171, 0.5, -48))
	scene("FodderWalkC", "res://scenes/enemies/fodder.tscn", Vector3(168, 0.5, -62))
	scene("AmmoWalk", "res://scenes/props/ammo_pickup.tscn", Vector3(172, 0.35, -8))
	# Secret 8: drop onto the moored barge through a gap in the rail, crate on deck, hop back up.
	box("Barge", Vector3(178.5, -1.4, -40), Vector3(8.0, 1.2, 16.0), "metal_blue", 0, true)
	box("BargeCabin", Vector3(180.5, 0.2, -46), Vector3(3.0, 2.0, 3.0), "car_white", 0, true)
	box("BargeStep", Vector3(175.4, -0.5, -40), Vector3(1.2, 0.6, 1.6), "rust", 0, true)
	secret("SecretBarge", Vector3(179, -0.7, -36), "res://scenes/props/supply_crate.tscn")
	ambush("AmbushBarge", Vector3(178.5, 0.5, -38), Vector3(7, 3, 10), Vector3(170, 0.2, -30), 3)

# Beat 5: plaza x 130..170, z -110..-71, pedestrian, canal along the east edge.
func plaza() -> void:
	slab("PlazaFloor", 130, -110, 170, -71, 0.15, 0.6, "concrete")
	for x in [132.0, 138.0, 162.0, 168.0]:
		pipe("PlazaBollard", Vector3(x, 0.6, -70), 0.9, 0.12, "dark")
	# Terrace on the west side, 2.6 up, ramp from the plaza.
	box("Terrace", Vector3(134, 1.3, -95), Vector3(8, 2.6, 24), "concrete_dark", 0, true)
	var terrace_ramp := box("TerraceRamp", Vector3(134, 1.15, -78.8), Vector3(2.6, 0.4, 8.8), "concrete", 0, true)
	terrace_ramp.rotation.x = 0.33
	(art.get_node("TerraceRampSolid") as Node3D).rotation.x = 0.33
	# Canal: railing, water below, far bank with the campus silhouette.
	slab("PlazaEast", 170, -110, 174, -71, 0.15, 0.6, "concrete")
	wall("CanalRailN", 174, -110, 174.3, -44, 1.1, "dark")
	wall("CanalRailS", 174, -36, 174.3, 8, 1.1, "dark")
	wall("CanalEndRail", 166, -110, 174, -109.7, 1.1, "dark")
	slab("CanalWater", 174, -140, 200, 20, -2.0, 0.5, "car_blue")
	slab("FarBank", 200, -140, 240, -40, 0.0, 2.0, "concrete")
	building("Campus", 205, -130, 235, -60, 18.0, "plaster_grey")
	building("CampusTower", 215, -100, 225, -90, 30.0, "plaster_ochre")
	# Fights.
	for i in 10:
		scene("FodderPlaza%d" % i, "res://scenes/enemies/fodder.tscn", Vector3(136 + i * 3.4, 0.5, -80 - (i % 4) * 7))
	scene("HunterPlazaA", "res://scenes/enemies/hunter.tscn", Vector3(160, 0.5, -100))
	scene("HunterPlazaB", "res://scenes/enemies/hunter.tscn", Vector3(134, 2.9, -92))
	scene("RammerPlaza", "res://scenes/enemies/rammer.tscn", Vector3(150, 0.5, -95))
	scene("AmmoPlaza", "res://scenes/props/ammo_pickup.tscn", Vector3(165, 0.35, -78))
	scene("AmmoPlazaB", "res://scenes/props/ammo_pickup.tscn", Vector3(145, 0.35, -106))
	scene("HealthPlazaB", "res://scenes/props/health_pickup.tscn", Vector3(160, 0.35, -96))
	secret("SecretTerrace", Vector3(134, 2.8, -104), "res://scenes/props/health_pickup.tscn")
	# BackAlleyN already fills x 60..130 above z -108; this closes the alley's east end.
	building("PlazaWest", 128, -108, 130, -100, 12.0, "brick")
	beat_line("Beat9Line", Vector3(150, 1.5, -110), Vector3(14, 3, 1), 9)

# Beat 6: museum lobby x 136..166, z -130..-110, lift at the back.
func museum() -> void:
	slab("MuseumFloor", 136, -130, 166, -110, 0.15, 0.6, "plaster")
	wall("MuseumW", 136, -130, 136.6, -110, 9.0, "plaster_grey")
	wall("MuseumE", 165.4, -130, 166, -110, 9.0, "plaster_grey")
	wall("MuseumN_W", 136, -130, 147, -129.4, 9.0, "plaster_grey")
	wall("MuseumN_E", 155, -130, 166, -129.4, 9.0, "plaster_grey")
	wall("MuseumFront_W", 136, -110.6, 143, -110, 9.0, "plaster_grey")
	wall("MuseumFront_E", 157, -110.6, 166, -110, 9.0, "plaster_grey")
	# Doorway x 143..157, 4.5 high; the lintel fills the wall above it.
	box("MuseumLintel", Vector3(150, 6.75, -110.3), Vector3(14, 4.5, 0.6), "plaster_grey", 0, true)
	box("MuseumRoof", Vector3(151, 9.2, -120), Vector3(30, 0.4, 20), "concrete_dark", 0, true)
	building("MuseumShellW", 120, -140, 136, -110, 12.0, "plaster_grey")
	building("MuseumShellE", 166, -140, 180, -110, 12.0, "plaster_grey")
	# Back shell split around the lift shaft (x 147..155, z -136..-130).
	building("MuseumShellN_W", 136, -145, 147, -130, 12.0, "plaster_grey")
	building("MuseumShellN_E", 155, -145, 166, -130, 12.0, "plaster_grey")
	building("MuseumShellN_Back", 147, -145, 155, -136.6, 12.0, "plaster_grey")
	# Exhibits: a skeleton block and the empty Antarctica case.
	box("Skeleton", Vector3(150, 2.5, -120), Vector3(1.2, 3.0, 8.0), "car_white", 0, true)
	box("SkeletonPlinth", Vector3(150, 0.5, -120), Vector3(3, 0.7, 10), "concrete_dark", 0, true)
	box("AntarcticaCase", Vector3(140, 1.2, -124), Vector3(2.2, 2.4, 2.2), "glass", 0, true)
	styled_sign("CaseLabel", "ANTARCTIC RECOVERY 2003 / ON LOAN", Vector3(140, 2.8, -122.8), 2.4, 0, {"backing": "car_white", "ink": Color("1f1f1f"), "font": ["Arial"], "height": 0.5})
	# Freight lift in the back wall: x 147..155, z -136..-130.
	slab("LiftFloor", 147, -136, 155, -130, 0.15, 0.6, "metal_blue")
	wall("LiftW", 146.4, -136, 147, -130, 6.0, "metal_blue")
	wall("LiftE", 155, -136, 155.6, -130, 6.0, "metal_blue")
	wall("LiftBack", 147, -136.6, 155, -136, 6.0, "metal_blue")
	box("LiftHead", Vector3(151, 5.5, -130.3), Vector3(9, 1.2, 0.6), "metal_blue", 0, true)
	styled_sign("LiftSign", "SECURE FREIGHT / AUTHORISED ONLY", Vector3(151, 5.5, -129.9), 5.0, 0, {"backing": "hazard", "ink": Color("1f1f1f"), "font": ["Arial Black"], "height": 0.7})
	box("LiftDoor", Vector3(151, 2.5, -130.3), Vector3(8, 5.0, 0.4), "hazard", 0, true)
	var finish := Area3D.new()
	finish.collision_layer = 0
	finish.collision_mask = 2
	finish.position = Vector3(151, 1.5, -133)
	add(finish, "LevelExit")
	finish.add_to_group("level_exit", true)
	var shape := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(7, 3, 5)
	shape.shape = b
	finish.add_child(shape)
	shape.owner = art

func actors() -> void:
	var player := scene("Player", "res://scenes/player/player.tscn", Vector3(0, 0.3, 6))
	player.rotation.y = -PI / 2

# --- Act 2: the west district ------------------------------------------------
# Canal Street carries on west past the opened scaffold, T's with Mill Road, and
# Mill Road runs north to the pumping station where the storm drains start.
# Nothing east of x 90 moves; CanalCollapse is what makes this the only way on.

func west_district() -> void:
	road("CanalWest", -44, -71, 0, -49, true, [[-30, -8]], [])
	building("CanalWestS_A", -8, -49, 30, -30, 10.0, "plaster_ochre")
	building("CanalWestS_B", -44, -49, -8, -30, 12.0, "brick_dark")
	# Cul-de-sac west of the T: rubble across the carriageway, road visible past it.
	box("WestEndRubbleA", Vector3(-42, 2.4, -60), Vector3(4.0, 4.8, 22.0), "concrete_dark", 0, true)
	box("WestEndRubbleB", Vector3(-39, 1.1, -56), Vector3(3.0, 2.2, 6.0), "brick", 0.3, true)
	box("WestEndRubbleC", Vector3(-39.5, 0.9, -66), Vector3(3.0, 1.8, 5.0), "plaster_grey", -0.25, true)
	road("CanalFarBeyond", -70, -71, -44, -49, true)
	car("FarBeyondCar", Vector3(-56, 0, -65), 0.1, "car_tan")
	building("FarBeyondN", -70, -100, -44, -71, 12.0, "plaster_grey")
	building("FarBeyondS", -70, -49, -44, -30, 11.0, "brick")
	# Secret 9: the cul-de-sac pocket, covered on the way back out.
	car("CulDeSacVan", Vector3(-36, 0, -52), -0.2, "car_white")
	secret("SecretCulDeSac", Vector3(-36, 0.2, -64), "res://scenes/props/supply_crate.tscn")
	ambush("AmbushCulDeSac", Vector3(-37, 1.5, -60), Vector3(9, 3, 18), Vector3(-22, 0, -60), 4)
	for i in 4:
		scene("FodderWest%d" % i, "res://scenes/enemies/fodder.tscn", Vector3(20 - i * 7, 0.3, -56 - (i % 2) * 8))
	scene("RammerWest", "res://scenes/enemies/rammer.tscn", Vector3(4, 0.3, -60))
	scene("HunterWest", "res://scenes/enemies/hunter.tscn", Vector3(-26, 0.3, -54))
	scene("HealthWest", "res://scenes/props/health_pickup.tscn", Vector3(14, 0.2, -52))
	scene("AmmoWest", "res://scenes/props/ammo_pickup.tscn", Vector3(-2, 0.2, -68))
	beat_line("Beat5Line", Vector3(-19, 1.5, -72), Vector3(22, 3, 1), 5)
	mill_road()
	pump_station()

# Mill Road: north-south, x -30..-8, z -150..-71. A fallen flyover deck at z -118
# forces the player up and over; a side alley at z -98 dead-ends on a secret.
func mill_road() -> void:
	road("MillRoad", -30, -150, -8, -71, false, [], [[-100, -96]])
	building("MillWestA", -52, -150, -30, -112, 13.0, "brick_dark")
	building("MillWestB", -52, -112, -30, -71, 11.0, "plaster_grey")
	building("MillEastA", -8, -150, 20, -100, 14.0, "brick")
	building("MillEastB", -8, -96, 30, -71, 12.0, "plaster_ochre")
	slab("MillAlley", -8, -100, 24, -96, 0.0, 0.5, "asphalt")
	building("MillAlleyEnd", 24, -100, 30, -96, 12.0, "brick")
	for x in [2.0, 12.0]:
		box("MillAlleySkip", Vector3(x, 0.7, -96.9), Vector3(2.2, 1.4, 1.8), "teal", 0, true)
	# Secret 10: the far end of the alley, ambushed on the way back out.
	secret("SecretMillAlley", Vector3(21, 0.2, -98), "res://scenes/props/boost_pickup.tscn")
	ambush("AmbushMillAlley", Vector3(20, 1.5, -98), Vector3(6, 3, 4), Vector3(-4, 0, -98), 3)
	# Fallen flyover: rubble fills the underside, so the way on is over the deck.
	box("FlyoverRubble", Vector3(-19, 1.5, -118), Vector3(22, 3.0, 10.0), "concrete_dark", 0, true)
	box("FlyoverDeck", Vector3(-19, 3.2, -118), Vector3(22, 0.8, 10.4), "concrete", 0, true)
	box("FlyoverEdge", Vector3(-19, 4.1, -123.4), Vector3(22, 1.0, 0.5), "hazard")
	# Foot flush with the road at z -104, head flush with the deck top (3.6) at
	# z -113.2: rise 3.6 over run 9.2, so tilt 0.3727 and length 9.88.
	var up := box("FlyoverRampS", Vector3(-19, 1.585, -108.6), Vector3(9.0, 0.4, 9.88), "concrete", 0, true)
	up.rotation.x = 0.3727
	(art.get_node("FlyoverRampSSolid") as Node3D).rotation.x = 0.3727
	var down := box("FlyoverRampN", Vector3(-19, 1.585, -127.8), Vector3(9.0, 0.4, 9.88), "concrete", 0, true)
	down.rotation.x = -0.3727
	(art.get_node("FlyoverRampNSolid") as Node3D).rotation.x = -0.3727
	for i in 2:
		pipe("FlyoverPier", Vector3(-27 + i * 16, 2.0, -112), 4.0, 0.7, "concrete_dark")
	for i in 4:
		scene("FodderMillS%d" % i, "res://scenes/enemies/fodder.tscn", Vector3(-24 + i * 4, 0.3, -82 - i * 5))
	scene("HunterMillS", "res://scenes/enemies/hunter.tscn", Vector3(-14, 0.3, -104))
	for i in 3:
		scene("FodderDeck%d" % i, "res://scenes/enemies/fodder.tscn", Vector3(-26 + i * 7, 3.9, -118))
	for i in 4:
		scene("FodderMillN%d" % i, "res://scenes/enemies/fodder.tscn", Vector3(-25 + i * 5, 0.3, -134 - (i % 2) * 8))
	scene("RammerMillN", "res://scenes/enemies/rammer.tscn", Vector3(-19, 0.3, -142))
	scene("HunterMillN", "res://scenes/enemies/hunter.tscn", Vector3(-12, 0.3, -146))
	scene("HealthMill", "res://scenes/props/health_pickup.tscn", Vector3(-27, 0.2, -112))
	scene("AmmoMill", "res://scenes/props/ammo_pickup.tscn", Vector3(-11, 0.2, -126))
	scene("AmmoMillB", "res://scenes/props/ammo_pickup.tscn", Vector3(-19, 3.9, -121))

# Works compound at the head of Mill Road. The open drain slot is the way down.
func pump_station() -> void:
	slab("PumpYardW", -40, -176, -24, -150, 0.0, 0.5, "concrete")
	slab("PumpYardE", -12, -176, 4, -150, 0.0, 0.5, "concrete")
	slab("PumpYardStrip", -24, -176, -12, -172, 0.0, 0.5, "concrete")
	wall("PumpYardN", -40, -176.6, 4, -176, 7.0)
	wall("PumpYardWWall", -40.6, -176, -40, -150, 7.0)
	wall("PumpYardEWall", 4, -176, 4.6, -150, 7.0)
	building("PumpHouse", -38, -172, -28, -158, 8.0, "brick_dark")
	box("PumpHouseDoor", Vector3(-33, 1.5, -157.8), Vector3(3.0, 3.0, 0.3), DOOR_COLOR)
	styled_sign("PumpSign", "FAIRHAVEN WATER  STATION 12", Vector3(-33, 5.4, -157.7), 9.0, 0, {"backing": "teal", "ink": Color("e8efe6"), "font": ["Arial"]})
	for i in 3:
		pipe("PumpPipe", Vector3(-2 + i * 2.4, 2.2, -168), 4.4, 0.5, "rust")
	box("PumpTank", Vector3(-2, 2.0, -158), Vector3(7.0, 4.0, 6.0), "metal_blue", 0.2, true)
	for z in [-156.0, -162.0, -168.0]:
		box("SlotRailW", Vector3(-24.6, 0.6, z), Vector3(0.4, 1.2, 5.0), "hazard")
		box("SlotRailE", Vector3(-11.4, 0.6, z), Vector3(0.4, 1.2, 5.0), "hazard")
	box("SlotWallW", Vector3(-24.5, -2.6, -161), Vector3(1.0, 6.4, 22.0), "concrete_dark", 0, true)
	box("SlotWallE", Vector3(-11.5, -2.6, -161), Vector3(1.0, 6.4, 22.0), "concrete_dark", 0, true)
	# The descent: flush with Mill Road at z -150, on the drain floor at z -172.
	# Drop 5.5 over run 22, so tilt 0.245 and length 22.68.
	var ramp := box("DrainRamp", Vector3(-18, -3.008, -161), Vector3(12.0, 0.5, 22.68), "concrete", 0, true)
	ramp.rotation.x = -0.245
	(art.get_node("DrainRampSolid") as Node3D).rotation.x = -0.245
	scene("FodderYardA", "res://scenes/enemies/fodder.tscn", Vector3(-32, 0.3, -154))
	scene("FodderYardB", "res://scenes/enemies/fodder.tscn", Vector3(-4, 0.3, -154))
	scene("FodderYardC", "res://scenes/enemies/fodder.tscn", Vector3(-6, 0.3, -170))
	scene("HunterYard", "res://scenes/enemies/hunter.tscn", Vector3(-30, 0.3, -153))
	scene("HealthYard", "res://scenes/props/health_pickup.tscn", Vector3(-30, 0.2, -152))
	beat_line("Beat6Line", Vector3(-18, 0.5, -151), Vector3(12, 6, 3), 6)

# --- Act 3: the storm drains -------------------------------------------------
# Floor top at -5.5, ceiling underside at -2.0, ceiling slab top at -1.4 so it
# clears the ground slab's underside at -1.05. Runs east under the district and
# surfaces in the cross street, east of CanalCollapse.


func storm_drains() -> void:
	drain("DrainA", -24, -184, 48, -172, true, [[12, 24]], [[-24, -12], [36, 48]])
	drain("DrainB", 36, -172, 48, -126, false)
	drain("DrainSpur", 12, -200, 24, -184, false)
	drain("DrainC", 52, -120, 100, -108, true, [], [[88, 100]])
	drain("DrainD", 88, -108, 100, -92, false, [], [[-106, -94]])
	# The exit slot leaves through the z1 side (-94), so the gap is in gaps_b.
	drain("DrainE", 100, -106, 124, -94, true, [], [[118, 124]])
	cistern()
	# End caps, so no run opens onto nothing.
	drain_cap("CapAWest", Vector3(-24.4, DRAIN_MID, -178), Vector3(0.8, DRAIN_H, 12.0))
	drain_cap("CapAEast", Vector3(48.4, DRAIN_MID, -178), Vector3(0.8, DRAIN_H, 12.0))
	drain_cap("CapSpurN", Vector3(18, DRAIN_MID, -200.4), Vector3(12.0, DRAIN_H, 0.8))
	drain_cap("CapCEast", Vector3(100.4, DRAIN_MID, -114), Vector3(0.8, DRAIN_H, 12.0))
	drain_cap("CapDSouth", Vector3(94, DRAIN_MID, -91.6), Vector3(12.0, DRAIN_H, 0.8))
	drain_cap("CapEEast", Vector3(124.4, DRAIN_MID, -100), Vector3(0.8, DRAIN_H, 12.0))
	# Secret 11: a blind spur off the main drain, covered on the way back.
	secret("SecretSpur", Vector3(18, -5.2, -196), "res://scenes/props/ammo_pickup.tscn")
	ambush("AmbushSpur", Vector3(18, -4.0, -194), Vector3(12, 3, 8), Vector3(18, -5.2, -180), 3)
	# Exit: slot up into the cross street, east of the Canal Street collapse.
	# The slot sits at z -94..-82, clear of DrainE's ceiling, so the climb out is
	# in the open. Drop 5.5 over run 12: tilt 0.4297, length 13.2.
	box("ExitWallW", Vector3(117.75, -2.6, -88), Vector3(0.5, 6.4, 12.0), "concrete_dark", 0, true)
	box("ExitWallE", Vector3(124.25, -2.6, -88), Vector3(0.5, 6.4, 12.0), "concrete_dark", 0, true)
	var out_ramp := box("DrainExitRamp", Vector3(121, -3.025, -88), Vector3(6.0, 0.5, 13.2), "concrete", 0, true)
	out_ramp.rotation.x = -0.4297
	(art.get_node("DrainExitRampSolid") as Node3D).rotation.x = -0.4297
	for z in [-91.0, -85.0]:
		box("ExitRailW", Vector3(117.6, 0.6, z), Vector3(0.4, 1.2, 5.0), "hazard")
		box("ExitRailE", Vector3(124.4, 0.6, z), Vector3(0.4, 1.2, 5.0), "hazard")
	box("ExitRailN", Vector3(121, 0.8, -94.2), Vector3(6.0, 1.6, 0.4), "hazard", 0, true)
	box("ExitLipS", Vector3(121, 0.25, -82.3), Vector3(6.0, 0.9, 0.5), "hazard", 0, true)
	# Fights in the dark. Corridors make every chase a straight line, which is
	# what the enemies can do without a navmesh.
	for i in 5:
		scene("FodderDrainA%d" % i, "res://scenes/enemies/fodder.tscn", Vector3(-8 + i * 11, -5.2, -178))
	scene("HunterDrainA", "res://scenes/enemies/hunter.tscn", Vector3(40, -5.2, -178))
	for i in 3:
		scene("FodderDrainB%d" % i, "res://scenes/enemies/fodder.tscn", Vector3(42, -5.2, -140 - i * 9))
	for i in 4:
		scene("FodderDrainC%d" % i, "res://scenes/enemies/fodder.tscn", Vector3(58 + i * 11, -5.2, -114))
	scene("HunterDrainC", "res://scenes/enemies/hunter.tscn", Vector3(96, -5.2, -114))
	for i in 3:
		scene("FodderDrainE%d" % i, "res://scenes/enemies/fodder.tscn", Vector3(104 + i * 7, -5.2, -100))
	scene("RammerDrainE", "res://scenes/enemies/rammer.tscn", Vector3(116, -5.2, -100))
	scene("AmmoDrainA", "res://scenes/props/ammo_pickup.tscn", Vector3(20, -5.3, -178))
	scene("HealthDrainB", "res://scenes/props/health_pickup.tscn", Vector3(42, -5.3, -158))
	scene("AmmoDrainC", "res://scenes/props/ammo_pickup.tscn", Vector3(76, -5.3, -114))
	scene("HealthDrainE", "res://scenes/props/health_pickup.tscn", Vector3(110, -5.3, -100))
	beat_line("Beat7Line", Vector3(121, 1.5, -79), Vector3(10, 3, 1), 7)

# The cistern: the one open room down here, so act 3 is not all corridor.
func cistern() -> void:
	slab("CisternFloor", 16, -126, 52, -102, DRAIN_FLOOR, 0.8, "concrete")
	slab("CisternCeil", 16, -126, 52, -102, -1.4, 0.6, "concrete_dark")
	box("CisternW", Vector3(15.6, DRAIN_MID, -114), Vector3(0.8, DRAIN_H, 24.0), "concrete_dark", 0, true)
	box("CisternS", Vector3(34, DRAIN_MID, -101.6), Vector3(36.0, DRAIN_H, 0.8), "concrete_dark", 0, true)
	# North wall gapped at x 36..48 where DrainB comes in.
	box("CisternN_W", Vector3(26, DRAIN_MID, -126.4), Vector3(20.0, DRAIN_H, 0.8), "concrete_dark", 0, true)
	box("CisternN_E", Vector3(50, DRAIN_MID, -126.4), Vector3(4.0, DRAIN_H, 0.8), "concrete_dark", 0, true)
	# East wall gapped at z -120..-108 where DrainC leaves.
	box("CisternE_N", Vector3(52.4, DRAIN_MID, -123), Vector3(0.8, DRAIN_H, 6.0), "concrete_dark", 0, true)
	box("CisternE_S", Vector3(52.4, DRAIN_MID, -105), Vector3(0.8, DRAIN_H, 6.0), "concrete_dark", 0, true)
	box("CisternWater", Vector3(34, DRAIN_FLOOR + 0.06, -114), Vector3(35.0, 0.12, 23.0), "glass")
	# Solid, because these are meant to be cover: pipe() carries no collision.
	for i in 3:
		for j in 2:
			box("CisternPillar", Vector3(22 + i * 12, DRAIN_MID, -120 + j * 12), Vector3(1.6, DRAIN_H, 1.6), "concrete_dark", 0, true)
	for i in 3:
		drain_light("CisternLight%d" % i, Vector3(22 + i * 12, -2.4, -114))
	# Sluice plinths: cover in the open, and the high one carries a secret.
	box("SluiceA", Vector3(26, -4.9, -108), Vector3(6.0, 1.2, 4.0), "concrete_dark", 0, true)
	box("SluiceB", Vector3(44, -4.9, -120), Vector3(5.0, 1.2, 4.0), "rust", 0, true)
	box("SluiceStep", Vector3(30.5, -5.115, -108), Vector3(3.231, 0.4, 3.0), "rust", 0, true, -0.3805)
	secret("SecretCistern", Vector3(26, -4.0, -108), "res://scenes/props/boost_pickup.tscn")
	for i in 6:
		scene("FodderCistern%d" % i, "res://scenes/enemies/fodder.tscn", Vector3(20 + i * 6, -5.2, -106 - (i % 3) * 7))
	scene("HunterCisternA", "res://scenes/enemies/hunter.tscn", Vector3(48, -5.2, -124))
	scene("HunterCisternB", "res://scenes/enemies/hunter.tscn", Vector3(18, -5.2, -122))
	scene("RammerCistern", "res://scenes/enemies/rammer.tscn", Vector3(34, -5.2, -114))
	scene("HealthCistern", "res://scenes/props/health_pickup.tscn", Vector3(44, -4.2, -120))
	scene("AmmoCistern", "res://scenes/props/ammo_pickup.tscn", Vector3(18, -5.3, -104))

# Trial placement of cardboard Johns along the early route, so the prop can be
# judged by hand. The real home for these is the factory level; this is a test
# bed, not a fiction. Twelve of them, so each is worth 0.83% of the bonus.
func john_trial() -> void:
	var spots := [
		[Vector3(-8, 0, -8), 0.4], [Vector3(6, 0, -6), -1.2],
		[Vector3(20, 0, 2.6), 1.6], [Vector3(30, 0, -2.6), 3.0], [Vector3(40, 0, 2.6), 0.2], [Vector3(48, 0, -2.6), -1.9],
		[Vector3(57, 0, 10), 2.4], [Vector3(70, 0, -10), -0.6], [Vector3(56, 0, -34), 1.1],
		[Vector3(56, 0, -68), 0.9], [Vector3(66, 0, -52), -2.2], [Vector3(76, 0, -68), 0.3],
	]
	var index := 0
	for spot in spots:
		scene("John%d" % index, "res://scenes/props/john_cutout.tscn", spot[0], spot[1])
		index += 1

# The plaza arena is a set piece node, not part of the level script. Its exported
# defaults already match this level's numbers.
func arena_set_piece() -> void:
	var node := Node3D.new()
	node.set_script(load("res://scripts/levels/arena_set_piece.gd"))
	add(node, "Arena")
