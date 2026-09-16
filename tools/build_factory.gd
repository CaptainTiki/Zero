extends "res://tools/level_kit.gd"
## Bakes the Level 1 factory greybox: scenes/levels/factory.tscn.
## Pass one is volumes only: floors, walls, doorways, ramps, catwalks, windows.
## No machines, enemies, Johns or secrets yet. Layout numbers match
## docs/LEVEL_FACTORY_PLAN.md; change them together.
##   godot --headless --path . -s res://tools/build_factory.gd

const GROUND := 0.0
const UPPER := 6.0
const HALL_CEIL := 12.0
const OFFICE_CEIL := 4.5
const ROOM_CEIL := 9.5

func _initialize() -> void:
	call_deferred("build")

func build() -> void:
	art.name = "FactoryLevel"
	art.set_script(load("res://scripts/levels/level_base.gd"))
	art.set("level_tag", "FACTORY")
	art.set("tally_title", "LEVEL 1 PLAYTEST  (factory investigation)")
	art.set("par_time", 600.0) # provisional; set it from the route test's walk time x 2.5
	art.set("fall_plane", -12.0)
	art.set("golden_path_units", 1200.0)
	environment()
	parking_lot()
	reception_and_offices()
	factory_floor()
	catwalks()
	plant_room()
	escape_route()
	skyline()
	actors()
	save_scene("res://scenes/levels/factory.tscn")

func environment() -> void:
	var env := WorldEnvironment.new()
	var settings: Environment = load("res://scenes/levels/m01_beats_1_5.tscn").instantiate().get_node("WorldEnvironment").environment.duplicate()
	# The city's fog is tuned for open streets and turns a big interior to soup.
	# Sky ambient also is not occluded by a roof, so dim it and let the lamps work.
	settings.fog_enabled = false
	settings.ambient_light_energy = 0.35
	env.environment = settings
	add(env, "WorldEnvironment")
	var sun := DirectionalLight3D.new()
	sun.transform = Transform3D(Basis(Vector3(0.766, -0.383, 0.515), Vector3(0, 0.802, 0.597), Vector3(-0.643, -0.457, 0.614)), Vector3(0, 20, 0))
	sun.light_color = Color(1, 0.9, 0.76)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 200.0
	add(sun, "Sun")
	# Ground under everything; the building floors sit on top.
	slab("Ground", -70, -100, 120, 90, -0.05, 1.0, "concrete_dark")

# 1. Parking lot: x -40..40, z 20..60. Start at the far corner, dogleg to the doors.
func parking_lot() -> void:
	slab("Lot", -40, 20, 40, 60, GROUND, 0.5, "asphalt")
	wall("LotFenceS", -40, 60, 40, 60.6, 3.0, "dark")
	wall("LotFenceW", -40.6, 20, -40, 60, 3.0, "dark")
	wall("LotFenceE_S", 40, 31, 40.6, 60, 3.0, "dark")
	wall("LotFenceE_N", 40, 20, 40.6, 23, 3.0, "dark")
	# A delivery bay juts into the lot, so the walk to the doors is not a straight line.
	building("LotBay", 6, 24, 30, 38, 5.0, "plaster_grey")
	box("LotBayDoor", Vector3(18, 2.0, 38.3), Vector3(8, 4.0, 0.5), "hazard", 0, true)
	beat_line("Beat1Line", Vector3(-24, 1.5, 46), Vector3(14, 3, 1), 1)

# 2. Reception x -10..10, z 12..20; offices x 10..50, z -10..12.
func reception_and_offices() -> void:
	slab("Reception", -10, 12, 10, 20, GROUND, 0.5, "plaster")
	wall("RecW", -10.6, 12, -10, 20, OFFICE_CEIL, "plaster_grey")
	wall("RecS_W", -10, 20, -3, 20.6, OFFICE_CEIL, "plaster_grey")
	wall("RecS_E", 3, 20, 10, 20.6, OFFICE_CEIL, "plaster_grey")
	box("RecDoorHead", Vector3(0, 3.4, 20.3), Vector3(6, 2.2, 0.6), "plaster_grey", 0, true)
	box("RecCeil", Vector3(0, OFFICE_CEIL + 0.2, 16), Vector3(20, 0.4, 8), "concrete_dark", 0, true)
	box("RecDesk", Vector3(-4, 0.55, 15), Vector3(6, 1.1, 1.6), "teal", 0, true)
	light("RecLight", Vector3(0, 3.8, 16))
	beat_line("Beat2Line", Vector3(0, 1.5, 19), Vector3(6, 3, 1), 2)
	# Offices: a corridor east with rooms off it, then the door onto the floor.
	slab("Offices", 10, -10, 50, 20, GROUND, 0.5, "plaster")
	wall("OffS", 10, 20, 50, 20.6, OFFICE_CEIL, "plaster_grey")
	wall("OffE", 50, -10, 50.6, 20, OFFICE_CEIL, "plaster_grey")
	box("OffCeil", Vector3(30, OFFICE_CEIL + 0.2, 5), Vector3(40, 0.4, 30), "concrete_dark", 0, true)
	# Partitions with doorways, so it reads as rooms rather than a hall.
	for i in 3:
		var x := 18.0 + float(i) * 11.0
		wall("OffPartA%d" % i, x, -10, x + 0.5, -2, OFFICE_CEIL, "plaster")
		wall("OffPartB%d" % i, x, 4, x + 0.5, 20, OFFICE_CEIL, "plaster")
	for i in 4:
		light("OffLight%d" % i, Vector3(14.0 + float(i) * 10.0, 3.8, 1.0))
	# North wall of the offices, with the door onto the factory floor at x 26..34.
	wall("OffN_W", 10, -10.6, 38, -10, OFFICE_CEIL, "plaster_grey")
	wall("OffN_E", 46, -10.6, 50, -10, OFFICE_CEIL, "plaster_grey")
	box("OffN_Head", Vector3(42, 3.6, -10.3), Vector3(8, 1.8, 0.6), "plaster_grey", 0, true)
	beat_line("Beat3Line", Vector3(42, 1.5, -11), Vector3(8, 3, 1), 3)

# 3. The interior, drawn as an irregular plan rather than a grid. The shell is a
# plain rectangle, as a real factory is; everything inside is off-axis.
#
#   Goods-in     small, SE, where the office door lands
#   Main hall    big and L-shaped, tall, wraps the north and east
#   Closets      electrical and break room, small, wedged between hall and packing
#   Packing      long narrow strip down the west
#   Boiler annex NW, its south-east corner cut off on the diagonal
#   Mezzanine    one short run from the hall, over the closets, down into packing
#
# The direct door from the hall into packing is buried under racking, so the
# mezzanine is the way across. From packing you reach the annex, which powers the
# plant room door. On the way back the racking can be shoved aside, opening a
# shortcut, the way the city's alley doors opened from the far side.
const CAT := 6.0
const HALL_H := 11.0
const ROOM_H := 5.5

func factory_floor() -> void:
	slab("HallFloor", -30, -70, 50, -10, GROUND, 0.5, "concrete")
	enclosure("Shell", -30, -70, 50, -10, HALL_H, "concrete_dark", [["s", 38, 46], ["e", -46, -40]])

	# Goods-in: the office door lands here, not in a hall.
	wall_path("GoodsW", [Vector2(32, -10), Vector2(32, -17), Vector2(32, -21), Vector2(32, -26)], ROOM_H, "plaster_grey", [1])
	wall_run("GoodsN", Vector2(32, -26), Vector2(50, -26), ROOM_H, "plaster_grey")
	box("GoodsCeil", Vector3(41, ROOM_H + 0.3, -18), Vector3(18, 0.6, 16), "concrete_dark", 0, true)
	light("GoodsLight", Vector3(41, 4.6, -18), Color(0.95, 0.97, 1.0), 3.5, 18.0)
	beat_line("Beat4Line", Vector3(41, 1.5, -14), Vector3(10, 3, 1), 4)

	# Packing: a long narrow strip down the west side. The door into the hall at
	# the north end is the one under the racking.
	# East wall, full height, with a door to the break room, a high opening where
	# the mezzanine crosses in, and the doorway the racking buries.
	wall_run("PackE0", Vector2(-14, -10), Vector2(-14, -20), HALL_H, "plaster_grey")
	wall_run("PackE1", Vector2(-14, -24), Vector2(-14, -28), HALL_H, "plaster_grey")
	box("PackEUnder", Vector3(-14, 2.3, -30), Vector3(0.6, 4.6, 4), "plaster_grey", 0, true)
	box("PackEOver", Vector3(-14, 9.8, -30), Vector3(0.6, 2.4, 4), "plaster_grey", 0, true)
	wall_run("PackE2", Vector2(-14, -32), Vector2(-14, -36), HALL_H, "plaster_grey")
	wall_run("PackE3", Vector2(-14, -40), Vector2(-14, -48), HALL_H, "plaster_grey")
	wall_run("PackN", Vector2(-30, -48), Vector2(-24, -48), HALL_H, "plaster_grey")
	wall_run("PackN2", Vector2(-20, -48), Vector2(-14, -48), HALL_H, "plaster_grey")
	for i in 3:
		light("PackLight%d" % i, Vector3(-22.0, 4.6, -18.0 - float(i) * 12.0), Color(0.95, 0.97, 1.0), 3.5, 18.0)

	# Two closets wedged between packing and the hall, different sizes.
	wall_path("BreakRoom", [Vector2(-14, -21), Vector2(-5, -21), Vector2(-5, -12)], 4.0, "plaster")
	box("BreakCeil", Vector3(-9.5, 4.3, -16.5), Vector3(9, 0.6, 9), "concrete_dark", 0, true)
	light("BreakLight", Vector3(-9.5, 3.4, -16.5), Color(1.0, 0.9, 0.7), 2.5, 12.0)
	wall_path("Electrical", [Vector2(-14, -27), Vector2(-7, -27), Vector2(-7, -35), Vector2(-14, -35)], 4.0, "plaster", [1])
	box("ElecCeil", Vector3(-10.5, 4.3, -31), Vector3(7, 0.6, 8), "concrete_dark", 0, true)
	light("ElecLight", Vector3(-10.5, 3.4, -31), Color(1.0, 0.8, 0.5), 2.0, 10.0)

	# Boiler annex, north-west, with its south-east corner cut on the diagonal.
	wall_path("Annex", [
		Vector2(-30, -52), Vector2(-24, -52), Vector2(-20, -52),
		Vector2(-12, -60), Vector2(-12, -70),
	], ROOM_H + 2.0, "concrete_dark", [1])
	box("AnnexCeil", Vector3(-21, ROOM_H + 2.3, -61), Vector3(18, 0.6, 18), "concrete_dark", 0, true)
	light("AnnexLight", Vector3(-21, 6.0, -61), Color(1.0, 0.75, 0.5), 4.0, 20.0)
	building("Switchgear", -28, -68, -22, -62, 3.0, "metal_blue")

	# The racking that buries the direct route between hall and packing.
	box("Racking", Vector3(-14, 2.4, -38), Vector3(5, 4.8, 4), "rust", 0, true)
	box("RackingSpill", Vector3(-11, 0.9, -38), Vector3(4, 1.8, 4), "plaster_ochre", 0.25, true)

	# Machine volumes in the hall, placed off-axis rather than in rows.
	building("VatA", 2, -66, 12, -58, 3.4, "rust")
	building("LineA", 18, -62, 40, -56, 2.2, "metal_blue")
	building("LineB", 6, -50, 24, -44, 2.2, "metal_blue")
	building("Kettle", 30, -48, 40, -40, 2.8, "rust")
	building("Hopper", -6, -56, 0, -48, 3.0, "rust")
	building("Pallets", 20, -34, 30, -28, 1.6, "plaster_ochre")
	building("Crates", 42, -36, 48, -30, 1.8, "plaster_ochre")
	for at in [Vector3(-2, 9.0, -62), Vector3(24, 9.0, -60), Vector3(42, 9.0, -50), Vector3(16, 9.0, -36)]:
		light("HallLight%d" % int(at.x), at, Color(0.95, 0.97, 1.0), 5.0, 30.0)

# 4. The mezzanine: up in the hall, west over the two closets, down in packing.
# One crossing, two rooms, and it exists only because the racking blocks the door.
func catwalks() -> void:
	ramp("StairA", Vector3(2, GROUND, -28), Vector3(2, 3.0, -34), 4.0, false)
	slab("StairLanding", 0, -38, 4, -34, 3.0, 0.4, "metal_blue")
	ramp("StairB", Vector3(2, 3.0, -38), Vector3(-4, 3.0, -38), 4.0, true)
	ramp("StairC", Vector3(-4, 3.0, -36), Vector3(-4, CAT, -30), 4.0, false)
	catwalk("SpanA", -20, -32, -4, -28, CAT, true)
	slab("SpanLanding", -24, -33, -20, -28, CAT, 0.3, "metal_blue")
	ramp("DownB", Vector3(-22, CAT, -33), Vector3(-22, GROUND, -45), 5.0, false)
	for at in [Vector3(-8, CAT + 1.4, -33.7), Vector3(-14, CAT + 1.4, -26.3)]:
		box("Vent%d" % int(at.x), at, Vector3(2.0, 2.0, 0.3), "dark", 0, false)
	beat_line("Beat5Line", Vector3(-11, CAT + 1.5, -30), Vector3(10, 3, 1), 5)

# 5. Plant room: east off the hall at ground level.
func plant_room() -> void:
	slab("PlantFloor", 50, -60, 90, -20, GROUND, 0.5, "concrete")
	enclosure("Plant", 50, -60, 90, -20, HALL_H, "concrete_dark", [["w", -46, -40], ["s", 56, 70]])
	box("PlantRoof", Vector3(70, HALL_H + 0.3, -40), Vector3(40, 0.6, 40), "concrete_dark", 0, true)
	building("Machine", 70, -54, 86, -34, 7.0, "rust")
	catwalk("MachWalkN", 64, -56, 88, -54, 3.0, true)
	catwalk("MachWalkE", 86, -54, 88, -34, 3.0, false)
	ramp("MachRamp", Vector3(64, GROUND, -48), Vector3(64, 3.0, -54), 5.0, false)
	for i in 4:
		light("PlantLight%d" % i, Vector3(56.0 + float(i) * 10.0, 9.0, -40.0), Color(1.0, 0.8, 0.6), 4.5, 26.0)
	beat_line("Beat6Line", Vector3(62, 1.5, -30), Vector3(10, 3, 1), 6)

# 6. Escape: south out of the plant room down a long dock, then west into the
# far end of the parking lot. It never crosses the way in, so the approach and
# the escape use opposite sides of the lot.
func escape_route() -> void:
	slab("Dock", 56, -20, 70, 30, GROUND, 0.5, "concrete")
	wall("DockE", 70, -20, 70.6, 30, OFFICE_CEIL, "concrete_dark")
	wall("DockW_N", 56, -20, 56.6, 18, OFFICE_CEIL, "concrete_dark")
	box("DockRoof", Vector3(63, OFFICE_CEIL + 0.3, -2), Vector3(14, 0.6, 36), "concrete_dark", 0, true)
	for i in 3:
		light("DockLight%d" % i, Vector3(63.0, 3.8, -12.0 + float(i) * 16.0))
	# West run back to the lot.
	slab("YardRun", 30, 24, 56, 30, GROUND, 0.5, "asphalt")
	wall("YardRunN", 30, 23.4, 56, 24, 4.0, "dark")
	wall("YardRunS", 30, 30, 56, 30.6, 4.0, "dark")
	light("YardRunLight", Vector3(43, 3.4, 27), Color(1.0, 0.9, 0.7), 2.5, 16.0)
	var finish := Area3D.new()
	finish.collision_layer = 0
	finish.collision_mask = 2
	finish.position = Vector3(34, 1.5, 20)
	add(finish, "LevelExit")
	finish.add_to_group("level_exit", true)
	var shape := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(8, 3, 6)
	shape.shape = b
	finish.add_child(shape)
	shape.owner = art
	beat_line("Beat7Line", Vector3(34, 1.5, 24), Vector3(8, 3, 1), 7)

## Blocks outside the windows so the factory is not standing in a field.
func skyline() -> void:
	var spots := [
		[Vector3(-60, 0, -40), 26.0], [Vector3(-58, 0, 10), 18.0], [Vector3(-52, 0, 60), 22.0],
		[Vector3(110, 0, -60), 30.0], [Vector3(104, 0, 0), 20.0], [Vector3(100, 0, 50), 24.0],
		[Vector3(10, 0, -96), 34.0], [Vector3(60, 0, -92), 28.0], [Vector3(-20, 0, 84), 20.0],
	]
	var index := 0
	for spot in spots:
		var at: Vector3 = spot[0]
		var h: float = spot[1]
		building("Block%d" % index, at.x - 12, at.z - 12, at.x + 12, at.z + 12, h, "brick_dark")
		index += 1

func actors() -> void:
	var player := scene("Player", "res://scenes/player/player.tscn", Vector3(-30, 0.3, 55))
	player.rotation.y = PI
