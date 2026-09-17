extends RefCounted
## Every level the game can start, in play order. The main menu lists these, and a level that
## finishes hands off to the next one, so adding a level here puts it in both places.

const LEVELS := [
	{"name": "THE FACTORY", "note": "Level 1  ·  investigation", "path": "res://scenes/levels/factory.tscn"},
	{"name": "DISTRICT 04", "note": "Level 2  ·  city", "path": "res://scenes/levels/l01_district04.tscn"},
]

static func first_path() -> String:
	return String(LEVELS[0]["path"])

## The level after this one, or "" when it was the last.
static func next_path(path: String) -> String:
	for i in LEVELS.size():
		if String(LEVELS[i]["path"]) == path:
			return String(LEVELS[i + 1]["path"]) if i + 1 < LEVELS.size() else ""
	return ""

static func name_for(path: String) -> String:
	for entry in LEVELS:
		if String(entry["path"]) == path:
			return String(entry["name"])
	return ""
