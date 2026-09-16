extends "res://tools/level_kit.gd"
## Bakes the Level 1 factory: scenes/levels/factory.tscn.
## Everything here comes from the top-down plan in docs/factory_plan/. Change the
## plan there, export it, then rebake:
##   node docs/factory_plan/export.js
##   godot --headless --path . -s res://tools/build_factory.gd
## Built so far: floors, walls, rails, roofs, stairs, fences, lights, beat lines, the
## exit, line-of-sight blockers, kick doors, pickups and the machine set piece. No
## placed enemies, Johns or secrets yet.

const PLAN := "res://docs/factory_plan/plan.json"

func _initialize() -> void:
	call_deferred("build")

func build() -> void:
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PLAN))
	art.name = "FactoryLevel"
	art.set_script(load("res://scripts/levels/level_base.gd"))
	art.set("level_tag", "FACTORY")
	art.set("tally_title", "LEVEL 1 PLAYTEST  (factory investigation)")
	art.set("par_time", float(plan["par_seconds"])) # from the plan: 3x the route test walk time
	art.set("fall_plane", -12.0)
	art.set("golden_path_units", float(plan["golden_units"]))
	environment()
	outline(plan)
	skyline()
	actors(plan)
	save_scene("res://scenes/levels/factory.tscn")

func v3(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))

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
	# Basis() takes columns and these numbers are the rows from the city scene file,
	# so transpose; without it the sun shines up and every floor outdoors is black.
	sun.transform = Transform3D(Basis(Vector3(0.766, -0.383, 0.515), Vector3(0, 0.802, 0.597), Vector3(-0.643, -0.457, 0.614)).transposed(), Vector3(0, 20, 0))
	sun.light_color = Color(1, 0.9, 0.76)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 200.0
	add(sun, "Sun")

## Floors, walls, rails, roofs, fences and shut doors arrive as ready-made boxes;
## stairs go through ramp() so their feet land flush.
func outline(plan: Dictionary) -> void:
	var counts := {}
	for piece in plan["boxes"]:
		var kind: String = piece["kind"]
		counts[kind] = int(counts.get(kind, 0)) + 1
		box("%s%d" % [kind.capitalize(), counts[kind]], v3(piece["c"]), v3(piece["s"]), piece["m"], 0, true)
	var index := 0
	for r in plan["ramps"]:
		ramp("Stair%d" % index, v3(r["low"]), v3(r["high"]), float(r["w"]), bool(r["along_x"]), "metal_blue")
		index += 1
	index = 0
	for l in plan["lights"]:
		var tint: Array = l["tint"]
		light("Lamp%d" % index, v3(l["at"]), Color(tint[0], tint[1], tint[2]), float(l["energy"]), float(l["range"]))
		# Compatibility draws only 32 lights in view, so lamps in other buildings fade out
		# rather than use up the budget.
		var lamp := art.get_node("Lamp%d" % index) as OmniLight3D
		lamp.distance_fade_enabled = true
		lamp.distance_fade_begin = 45.0
		lamp.distance_fade_length = 10.0
		index += 1
	blockers(plan)
	kick_doors(plan)
	pickups(plan)
	enemies(plan)
	johns(plan)
	ambushes(plan)
	secrets(plan)
	dressing(plan)
	machine(plan)
	for b in plan["beats"]:
		beat_line("Beat%dLine" % int(b["beat"]), v3(b["at"]), v3(b["size"]), int(b["beat"]))
	var finish: Dictionary = plan["exit"]
	trigger("LevelExit", v3(finish["at"]), v3(finish["size"]), "level_exit")

## Machines, containers, tanks and vehicles that break sight lines on open floors.
## Plain greybox shapes at the plan's footprints and heights; art comes later.
func blockers(plan: Dictionary) -> void:
	var index := 0
	for b in plan["blockers"]:
		var label := "Blocker%d%s" % [index, String(b["name"]).to_pascal_case()]
		match String(b["shape"]):
			"car":
				car(label, v3(b["at"]), float(b["yaw"]), b["m"])
			"round":
				tank(label, v3(b["at"]), float(b["r"]), float(b["h"]), b["m"])
			"hollow":
				hollow_box(label, v3(b["c"]), v3(b["s"]), String(b["open"]), b["m"])
			_:
				box(label, v3(b["c"]), v3(b["s"]), b["m"], 0, true)
		index += 1

## Kick doors sized to their doorways. Only the door that teaches kicking shows the prompt.
## The route test opens every node named KickDoor*, so keep the prefix.
func kick_doors(plan: Dictionary) -> void:
	var index := 0
	for d in plan["kick_doors"]:
		var door := scene("KickDoor%d%s" % [index, String(d["name"]).get_slice(",", 0).to_pascal_case()], "res://scenes/props/kick_door.tscn", v3(d["at"]), float(d["yaw"]))
		door.set("opening_width", float(d["width"]))
		door.set("opening_height", float(d["height"]))
		if not bool(d["prompt"]):
			door.set("prompt", "")
		index += 1

const PICKUPS := {
	"gun": "res://scenes/props/gun_pickup.tscn",
	"shotgun": "res://scenes/props/shotgun_pickup.tscn",
	"ammo": "res://scenes/props/ammo_pickup.tscn",
	"health": "res://scenes/props/health_pickup.tscn",
}

## Weapons, plus the ammo and health the plan's dead ends pay. Provisional until the
## enemies pass decides what the fights need.
func pickups(plan: Dictionary) -> void:
	var index := 0
	for p in plan["pickups"]:
		var kind := String(p["kind"])
		var lift := 0.8 if kind == "gun" or kind == "shotgun" else 0.2
		scene("Pickup%d%s" % [index, kind.capitalize()], PICKUPS[kind], v3(p["at"]) + Vector3(0, lift, 0))
		index += 1

## The plant room climax: coolant pipes, waves, the seal and the escape countdown.
## See scripts/levels/machine_set_piece.gd.
func machine(plan: Dictionary) -> void:
	var sp: Dictionary = plan["setpiece"]
	var node := Node3D.new()
	node.set_script(load("res://scripts/levels/machine_set_piece.gd"))
	for key in ["start_at", "start_size", "seal_at", "respawn_at", "exit_at", "exit_size", "end_zone_at", "end_zone_size"]:
		node.set(key, v3(sp[key]))
	node.set("seal_radius", float(sp["seal_radius"]))
	node.set("seal_length", float(sp["seal_length"]))
	node.set("escape_seconds", float(sp["escape_seconds"]))
	var pipes := []
	for p in sp["pipes"]:
		pipes.append([v3(p[0]), v3(p[1])])
	node.set("pipes", pipes)
	var waves := []
	for w in sp["waves"]:
		waves.append([int(w[0]), int(w[1]), int(w[2])])
	node.set("waves", waves)
	for key in ["melee_hatches", "ranged_hatches", "vents", "alarms"]:
		var points := []
		for at in sp[key]:
			points.append(v3(at))
		node.set(key, points)
	var events := []
	for ev in sp["escape_events"]:
		events.append({
			"kind": String(ev["kind"]), "at": v3(ev["at"]), "size": v3(ev["size"]),
			"trigger": v3(ev["trigger"]) if ev["trigger"] != null else null,
			"radius": float(ev["radius"]), "delay": float(ev["delay"]), "duration": float(ev["duration"]),
		})
	node.set("escape_events", events)
	add(node, "MachineSetPiece")

const ENEMIES := {
	"fodder": "res://scenes/enemies/fodder.tscn",
	"hunter": "res://scenes/enemies/hunter.tscn",
	"rammer": "res://scenes/enemies/rammer.tscn",
}

## Placed enemies. Anything that starts off the level it fights on is a Hunter.
func enemies(plan: Dictionary) -> void:
	var index := 0
	for e in plan["enemies"]:
		var kind := String(e["kind"])
		scene("Enemy%d%s" % [index, kind.capitalize()], ENEMIES[kind], v3(e["at"]) + Vector3(0, 0.3, 0))
		index += 1

const SHIRTS := [Color("c8443a"), Color("3a6ec8"), Color("4a9a4a"), Color("d8b43a"), Color("7a4ac8"), Color("d8743a")]

## Cardboard Johns pretending to work. Every one of them is called John.
func johns(plan: Dictionary) -> void:
	var index := 0
	for p in plan["johns"]:
		var john := scene("John%d" % index, "res://scenes/props/john_cutout.tscn", v3(p["at"]), float(p["yaw"]))
		john.set("shirt", SHIRTS[index % SHIRTS.size()])
		index += 1

## Dead ends that bite on the way back out.
func ambushes(plan: Dictionary) -> void:
	for a in plan["ambushes"]:
		ambush("Ambush" + String(a["name"]).to_pascal_case(), v3(a["at"]), v3(a["size"]), v3(a["spawn"]), int(a["count"]))

const SIGN_STYLES := {
	"corporate": {"backing": "car_white", "ink": Color("1d3557"), "font": ["Arial", "Helvetica"], "weight": 700},
	"office": {"backing": "teal", "ink": Color("f4f1e6"), "font": ["Verdana", "Arial"]},
	"hazard": {"backing": "hazard", "ink": Color("15161a"), "font": ["Arial Black", "Arial"], "weight": 800},
	"wrong": {"backing": "plaster", "ink": Color("b0302a"), "font": ["Comic Sans MS", "Arial"], "weight": 700},
	"frame": {"backing": "plaster_ochre", "ink": Color("15161a"), "font": ["Georgia"], "italic": true},
}

## Signs that are confidently wrong, JOHN painted on every parking bay, and window bands
## on the fronts people see. Visual only: no collision.
func dressing(plan: Dictionary) -> void:
	var index := 0
	for s in plan["signs"]:
		var style: Dictionary = SIGN_STYLES[String(s["style"])].duplicate()
		style["height"] = float(s["height"])
		styled_sign("Sign%d" % index, String(s["text"]), v3(s["at"]), float(s["width"]), float(s["yaw"]), style)
		index += 1
	index = 0
	for t in plan["floor_text"]:
		var paint := Label3D.new()
		paint.text = String(t["text"])
		paint.font_size = 64
		paint.pixel_size = 0.009
		paint.modulate = Color(0.92, 0.9, 0.82)
		paint.outline_size = 0
		paint.position = v3(t["at"]) + Vector3(0, 0.03, 0)
		paint.rotation = Vector3(-PI / 2.0, float(t["yaw"]), 0)
		add(paint, "BayPaint%d" % index)
		index += 1
	index = 0
	for w in plan["windows"]:
		window_band("Windows%d" % index, v3(w["at"]), float(w["width"]), float(w["yaw"]))
		index += 1

## A blocker you can walk into: back, sides and lid, with one face open (n, s, e or w).
## No floor, because a 0.12 lip at the mouth would stop the player dead.
func hollow_box(label: String, centre: Vector3, size: Vector3, open: String, material: String) -> void:
	var t := 0.12
	var half := size / 2.0
	box(label + "Lid", centre + Vector3(0, half.y - t / 2.0, 0), Vector3(size.x, t, size.z), material, 0, true)
	var faces := {
		"e": [Vector3(half.x - t / 2.0, 0, 0), Vector3(t, size.y, size.z)],
		"w": [Vector3(-half.x + t / 2.0, 0, 0), Vector3(t, size.y, size.z)],
		"s": [Vector3(0, 0, half.z - t / 2.0), Vector3(size.x, size.y, t)],
		"n": [Vector3(0, 0, -half.z + t / 2.0), Vector3(size.x, size.y, t)],
	}
	for side in faces:
		if side == open:
			continue
		box("%s%s" % [label, side.to_upper()], centre + faces[side][0], faces[side][1], material, 0, true)

const REWARDS := {
	"ammo": "res://scenes/props/ammo_pickup.tscn",
	"health": "res://scenes/props/health_pickup.tscn",
	"boost": "res://scenes/props/boost_pickup.tscn",
}

## Secrets: the reward and a box that counts it once. Never signposted.
func secrets(plan: Dictionary) -> void:
	for s in plan["secrets"]:
		var label := "Secret" + String(s["name"]).to_pascal_case()
		var at := v3(s["at"])
		scene(label + "Reward", REWARDS[String(s["reward"])], at + Vector3(0, 0.2, 0))
		var box_size: Array = s["trigger"]
		trigger(label, at + Vector3(0, 1.0, 0), Vector3(float(box_size[0]), 3.0, float(box_size[1])), "secrets")

## A standing cylinder with collision; pipe() on its own is visual only.
func tank(label: String, base: Vector3, radius: float, height: float, material: String) -> void:
	var centre := base + Vector3(0, height / 2.0, 0)
	pipe(label, centre, height, radius, material)
	var body := StaticBody3D.new()
	body.position = centre
	add(body, label + "Solid")
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	collision.shape = shape
	body.add_child(collision)
	collision.owner = art

## Blocks outside the compound so the factory is not standing in a field.
func skyline() -> void:
	var spots := [
		[Vector3(-140, 0, -100), 30.0], [Vector3(-145, 0, -30), 22.0], [Vector3(-138, 0, 40), 26.0], [Vector3(-142, 0, 110), 18.0],
		[Vector3(125, 0, -110), 34.0], [Vector3(130, 0, -40), 24.0], [Vector3(122, 0, 30), 20.0], [Vector3(128, 0, 100), 28.0],
		[Vector3(-60, 0, -162), 32.0], [Vector3(10, 0, -166), 26.0], [Vector3(70, 0, -160), 36.0],
		[Vector3(-50, 0, 136), 20.0], [Vector3(30, 0, 140), 24.0],
	]
	var index := 0
	for spot in spots:
		var at: Vector3 = spot[0]
		var h: float = spot[1]
		building("Block%d" % index, at.x - 12, at.z - 12, at.x + 12, at.z + 12, h, "brick_dark")
		index += 1

func actors(plan: Dictionary) -> void:
	var spawn: Dictionary = plan["spawn"]
	var player := scene("Player", "res://scenes/player/player.tscn", v3(spawn["at"])) as Node3D
	player.rotation.y = float(spawn["yaw"])
	# Deaths put the player back at the start until losing restarts the level.
	player.set("respawn_point", v3(spawn["at"]) + Vector3(0, 0.2, 0))
