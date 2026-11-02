# A squad's place in the war. It's always at a place or partway along one road, and
# only ever moves by walking, so it can't teleport.
extends RefCounted

var id: int
var faction: String
var soldiers: int
var ammo: float
var ammo_capacity: float
# Fighting this tick. A squad in a fight holds its ground.
var engaged := false

# The place it's at or last left.
var at: String
# The place it's walking to, empty when stopped.
var next := ""
var metres_along := 0.0
# Places still to reach after `next`.
var route := PackedStringArray()


func _init(squad_id: int, squad_faction: String, place_id: String, size: int, capacity: float) -> void:
	id = squad_id
	faction = squad_faction
	at = place_id
	soldiers = size
	ammo_capacity = capacity
	ammo = capacity


# Has somewhere to go, even if a fight is holding it where it is.
func is_moving() -> bool:
	return next != "" or not route.is_empty()


# Physically at a place rather than out on a road, whatever its orders.
func is_at_place() -> bool:
	return next == ""


func supply() -> float:
	return ammo / ammo_capacity


# Follow these places from wherever the squad is. Mid-road it finishes the road
# first, so the route should start from `next` in that case.
func set_route(places: PackedStringArray) -> void:
	route = places


func walk(metres: float, region: RefCounted) -> void:
	_start_next_road()
	while metres > 0.0 and next != "":
		var left: float = region.road_length(at, next) - metres_along
		if metres < left:
			metres_along += metres
			return
		metres -= left
		at = next
		next = ""
		metres_along = 0.0
		_start_next_road()


# Done as soon as a road ends, so a squad passing through never stops at a place,
# even when a step lands on it exactly.
func _start_next_road() -> void:
	if next == "" and not route.is_empty():
		next = route[0]
		route.remove_at(0)


func position(region: RefCounted) -> Vector2:
	var start: Vector2 = region.places[at].position
	if next == "":
		return start
	return start.lerp(region.places[next].position, metres_along / region.road_length(at, next))
