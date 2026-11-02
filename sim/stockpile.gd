# What one place has in store, in units (1 crate = 20 units). Amounts are floats
# because squads draw a little every tick. Nothing here can go negative.
extends RefCounted

const RESOURCES: Array[String] = ["scrap", "bmats", "rifles", "ammo", "shells", "medkits"]
const UNITS_PER_CRATE := 20.0

var _amounts := {}


func _init(starting := {}) -> void:
	for resource in RESOURCES:
		_amounts[resource] = maxf(float(starting.get(resource, 0.0)), 0.0)
	for resource: String in starting:
		if resource not in RESOURCES:
			push_error("Unknown resource '%s' in stock data" % resource)


func amount(resource: String) -> float:
	return _amounts[resource]


# Takes up to `wanted` and returns what it actually got.
func take(resource: String, wanted: float) -> float:
	var got := clampf(wanted, 0.0, _amounts[resource])
	_amounts[resource] -= got
	return got


func add(resource: String, quantity: float) -> void:
	_amounts[resource] += maxf(quantity, 0.0)
