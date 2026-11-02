# A place on the road graph: a town, a field depot, or a resource site (quarry or
# scrap field). Towns and depots can be owned and captured; sites can't, yet.
extends RefCounted

const Stockpile := preload("res://sim/stockpile.gd")

var id: String
var display_name: String
var kind: String
var position: Vector2
var owner: String
var fortification: float
var stock: Stockpile
# Who is taking this place right now, and how long they still have to hold it.
var capture_faction := ""
var capture_left := 0.0


func _init(data: Dictionary) -> void:
	id = data.id
	display_name = data.name
	kind = data.kind
	position = Vector2(data.pos[0], data.pos[1])
	owner = data.get("owner", "")
	fortification = data.get("fortification", 0.0)
	stock = Stockpile.new(data.get("stock", {}))


func is_capturable() -> bool:
	return kind == "town" or kind == "depot"
