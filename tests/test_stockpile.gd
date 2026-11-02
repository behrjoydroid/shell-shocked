extends RefCounted

const Stockpile := preload("res://sim/stockpile.gd")


func test_starts_with_what_the_data_says() -> void:
	var stock := Stockpile.new({"ammo": 50, "rifles": 8})
	assert(stock.amount("ammo") == 50.0)
	assert(stock.amount("rifles") == 8.0)
	assert(stock.amount("scrap") == 0.0, "anything unlisted starts empty")


func test_take_gives_what_was_asked_for() -> void:
	var stock := Stockpile.new({"ammo": 50})
	assert(stock.take("ammo", 20.0) == 20.0)
	assert(stock.amount("ammo") == 30.0)


func test_take_never_overdraws() -> void:
	var stock := Stockpile.new({"ammo": 5})
	assert(stock.take("ammo", 20.0) == 5.0, "only what's there")
	assert(stock.amount("ammo") == 0.0)
	assert(stock.take("ammo", 20.0) == 0.0, "nothing left to take")


func test_take_and_add_ignore_negative_amounts() -> void:
	var stock := Stockpile.new({"ammo": 5})
	assert(stock.take("ammo", -10.0) == 0.0)
	assert(stock.amount("ammo") == 5.0, "taking a negative can't add stock")
	stock.add("ammo", -10.0)
	assert(stock.amount("ammo") == 5.0, "adding a negative can't remove stock")


func test_negative_starting_data_is_floored() -> void:
	assert(Stockpile.new({"ammo": -5}).amount("ammo") == 0.0)


func test_stock_never_goes_negative_over_1000_random_ticks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var stock := Stockpile.new({"ammo": 40, "bmats": 10})
	var expected := {"ammo": 40.0, "bmats": 10.0}
	for i in 1000:
		var resource: String = "ammo" if rng.randf() < 0.5 else "bmats"
		var quantity := rng.randf_range(0.0, 8.0)
		if rng.randf() < 0.6:
			expected[resource] -= stock.take(resource, quantity)
		else:
			stock.add(resource, quantity)
			expected[resource] += quantity
		assert(stock.amount(resource) >= 0.0, "stock went negative")
		assert(is_equal_approx(stock.amount(resource), expected[resource]), "units appeared or vanished")
