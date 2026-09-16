extends Node
## Stands in for the level script's run_stats group in prop tests.

var johns := 0
var kills := 0

func record_john() -> void:
	johns += 1

func record_kill() -> void:
	kills += 1
