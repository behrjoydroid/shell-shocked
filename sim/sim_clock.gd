# Turns real time into sim ticks, 4 per second at normal speed. Whoever owns the clock
# feeds it frame time and runs as many ticks as it says are due.
extends RefCounted

const TICK_SECONDS := 0.25
const SPEEDS: Array[int] = [1, 4, 16]
# After a long stall, carry on rather than bursting through all the time it missed.
const MAX_REAL_DELTA := 0.25

var speed := 1
var paused := false
var ticks := 0

var _banked := 0.0


func set_speed(value: int) -> void:
	if value in SPEEDS:
		speed = value


# Returns how many ticks are due now.
func advance(real_delta: float) -> int:
	if paused:
		return 0
	_banked += minf(real_delta, MAX_REAL_DELTA) * speed
	var due := int(_banked / TICK_SECONDS)
	_banked -= due * TICK_SECONDS
	ticks += due
	return due
