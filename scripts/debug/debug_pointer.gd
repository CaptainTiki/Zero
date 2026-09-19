extends RefCounted
## Camera-centred, non-damaging physics probe. Called only during a physics tick.
const RANGE := 1000.0
const MASK := 5 # World/enemies and shootable props; excludes the player layer.

static func vector(value: Vector3) -> Array:
	return [snappedf(value.x, 0.001), snappedf(value.y, 0.001), snappedf(value.z, 0.001)]

static func sample(player: CharacterBody3D, camera: Camera3D) -> Dictionary:
	var origin := camera.global_position
	var facing := -camera.global_basis.z.normalized()
	var scene := player.get_tree().current_scene
	var query := PhysicsRayQueryParameters3D.create(origin, origin + facing * RANGE, MASK, [player.get_rid()])
	var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
	var marker := {
		"scene": scene.scene_file_path if scene else "",
		"player_position": vector(player.global_position),
		"camera_position": vector(origin),
		"facing": vector(facing),
		"yaw_degrees": snappedf(rad_to_deg(atan2(-facing.x, -facing.z)), 0.01),
		"pitch_degrees": snappedf(rad_to_deg(asin(clampf(facing.y, -1.0, 1.0))), 0.01),
		"range_metres": RANGE,
		"hit": not hit.is_empty(),
	}
	if not hit.is_empty():
		var collider: Node = hit.collider
		marker["collider"] = str(scene.get_path_to(collider)) if scene else str(collider.get_path())
		marker["hit_position"] = vector(hit.position)
		marker["hit_normal"] = vector(hit.normal)
		marker["distance_metres"] = snappedf(origin.distance_to(hit.position), 0.001)
	else:
		marker["ray_end"] = vector(origin + facing * RANGE)
	return marker
