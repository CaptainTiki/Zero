extends RefCounted
## Old snapshots contain deliberately retired, disabled blockout bodies. Exclude only
## the explicit final-bake retirement manifest; current active collision has its own test.
static func surviving(snapshot: Dictionary,level: Node) -> Dictionary:
	var result:=snapshot.duplicate()
	var retired: Dictionary=level.get_meta("retired_blockouts",{})
	for key in result.keys():
		var relative:=str(key).trim_prefix("/"+str(level.name)+"/").trim_prefix("/")
		for path: String in retired:
			if relative==path or relative.begins_with(path+"/"):
				result.erase(key)
				break
	return result
