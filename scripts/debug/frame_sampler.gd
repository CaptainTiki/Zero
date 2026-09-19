extends RefCounted
## Wall-clock intervals between rendered process frames; not physics delta or GPU timing.
const INTERVAL_USEC := 5000000
var previous_usec: int=-1
var intervals: Array[float]=[]
var total_usec:=0
var last_window: Dictionary={}

func restart_clock() -> void:
	# Exclude pause and first-load time; keep already sampled active frames.
	previous_usec=-1

func tick(now_usec: int) -> Dictionary:
	if previous_usec<0:
		previous_usec=now_usec
		return {}
	var duration:=now_usec-previous_usec
	previous_usec=now_usec
	if duration<=0: return {}
	intervals.append(duration/1000.0)
	total_usec+=duration
	if total_usec<INTERVAL_USEC: return {}
	last_window=snapshot()
	intervals.clear()
	total_usec=0
	return last_window.duplicate(true)

func snapshot() -> Dictionary:
	if intervals.is_empty():
		var cached:=last_window.duplicate(true)
		cached["window_source"]="last_completed" if not cached.is_empty() else "warming_up"
		return cached
	var ordered:=intervals.duplicate()
	ordered.sort()
	var mean:=float(total_usec)/1000.0/intervals.size()
	return {"window_source":"current","frames":intervals.size(),"sample_seconds":snappedf(total_usec/1000000.0,0.001),"fps":snappedf(1000.0/mean,0.1),"frame_ms_mean":snappedf(mean,0.01),"frame_ms_p95":snappedf(ordered[maxi(0,ceili(ordered.size()*0.95)-1)],0.01),"frame_ms_max":snappedf(ordered.back(),0.01)}
