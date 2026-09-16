extends RefCounted
## The factory's golden path, shared by the route test and the route analysis
## tool so the two can never drift apart.
##
## Out through the lot, in at reception, east through the offices, into goods-in,
## west across the hall, up onto the mezzanine, down into packing, north to the
## annex for the switchgear, back the same way, east to the plant room, then the
## escape out through the dock and the yard.

const ROUTE := [
	# Parking lot: start at the far corner, dogleg around the delivery bay.
	Vector3(-30, 0, 55), Vector3(-22, 0, 44), Vector3(-6, 0, 34), Vector3(0, 0, 24),
	# Reception and the offices.
	Vector3(0, 0, 16), Vector3(12, 0, 8), Vector3(14, 0, 1), Vector3(26, 0, 1), Vector3(40, 0, 1), Vector3(44, 0, -4),
	# Goods-in, then west through its door into the hall.
	Vector3(42, 0, -16), Vector3(34, 0, -19), Vector3(26, 0, -22),
	# Across the hall to the mezzanine stair.
	Vector3(14, 0, -28), Vector3(2, 0, -28),
	# Up: two short flights and a turn.
	Vector3(2, 3.0, -36), Vector3(-2, 3.0, -38), Vector3(-4, 6.0, -30),
	# West over the closets, through the wall at height, down inside packing.
	Vector3(-10, 6.0, -30), Vector3(-18, 6.0, -30), Vector3(-22, 6.0, -31),
	Vector3(-22, 0, -45),
	# North to the annex for the switchgear.
	Vector3(-22, 0, -46), Vector3(-22, 0, -54), Vector3(-25, 0, -62),
	# Back down packing and over the crossing again.
	Vector3(-22, 0, -46), Vector3(-22, 6.0, -31), Vector3(-18, 6.0, -30),
	Vector3(-10, 6.0, -30), Vector3(-4, 6.0, -30), Vector3(-2, 3.0, -38), Vector3(2, 3.0, -36),
	# Hall, east to the plant room door.
	Vector3(2, 0, -30), Vector3(20, 0, -38), Vector3(44, 0, -38), Vector3(48, 0, -43), Vector3(56, 0, -43),
	# Round the machine, then out south into the dock.
	Vector3(66, 0, -46), Vector3(64, 0, -30), Vector3(63, 0, -14),
	# Escape: south down the dock, then west into the far end of the lot.
	Vector3(63, 0, 10), Vector3(63, 0, 26), Vector3(48, 0, 27), Vector3(34, 0, 27), Vector3(34, 0, 20),
]
