extends RefCounted

const SimClock := preload("res://sim/sim_clock.gd")


# Feeds one real second in 60 frames and returns the ticks that came out.
func _one_second(clock: SimClock) -> int:
	var due := 0
	for i in 60:
		due += clock.advance(1.0 / 60.0)
	return due


func test_design_says_four_ticks_a_second() -> void:
	assert(SimClock.TICK_SECONDS == 0.25)


func test_speeds_are_1x_4x_and_16x() -> void:
	var wanted: Array[int] = [1, 4, 16]
	assert(SimClock.SPEEDS == wanted)
	var clock := SimClock.new()
	assert(clock.speed == 1, "starts at normal speed")
	for speed in SimClock.SPEEDS:
		clock.set_speed(speed)
		var due := _one_second(clock)
		assert(absi(due - 4 * speed) <= 1, "%dx gave %d ticks in a second" % [speed, due])


func test_a_speed_that_isnt_on_the_list_is_ignored() -> void:
	var clock := SimClock.new()
	clock.set_speed(4)
	clock.set_speed(3)
	assert(clock.speed == 4)


func test_no_time_is_lost_or_gained_over_a_long_run() -> void:
	for speed in SimClock.SPEEDS:
		var clock := SimClock.new()
		clock.set_speed(speed)
		var due := 0
		for i in 6000:
			due += clock.advance(1.0 / 60.0)
		assert(absi(due - 400 * speed) <= 1, "%dx gave %d ticks, wanted %d" % [speed, due, 400 * speed])
		assert(clock.ticks == due, "tick count disagrees")


func test_pausing_stops_ticks_and_builds_no_backlog() -> void:
	var clock := SimClock.new()
	clock.paused = true
	assert(_one_second(clock) == 0)
	clock.paused = false
	assert(_one_second(clock) <= 5, "paused time must not be made up afterwards")


func test_a_long_stall_doesnt_cause_a_burst() -> void:
	var clock := SimClock.new()
	clock.set_speed(16)
	var due := clock.advance(30.0)
	assert(due <= 16, "a 30 s stall gave %d ticks at once" % due)
