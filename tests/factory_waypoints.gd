extends RefCounted
## The factory's golden path, read from the plan export so the plan, the route test
## and the route analysis tool can never drift apart. Edit the route in
## docs/factory_plan/plan_items.js, then run node docs/factory_plan/export.js.

const PLAN := "res://docs/factory_plan/plan.json"

static func _plan() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(PLAN))

static func route() -> Array:
	var points := []
	for p in _plan()["route"]:
		points.append(Vector3(float(p[0]), float(p[1]), float(p[2])))
	return points

static func beat_count() -> int:
	return (_plan()["beats"] as Array).size()
