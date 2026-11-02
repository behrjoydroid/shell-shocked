# The war map: towns coloured by owner, squads as dots, and what every depot holds.
# It reads the war through SimBridge and draws it. M opens and closes it, and the game
# carries on underneath.
extends Control

const Stockpile := preload("res://sim/stockpile.gd")
const MAP_ORIGIN := Vector2(40, 40)
const MAP_PIXELS := 640.0
const PANEL_X := 716.0
const FONT_SIZE := 14
const ROW_HEIGHT := 22.0
const NAME_COLUMN := 120.0
const OWNER_COLUMN := 22.0
const STOCK_COLUMN := 62.0
const TOWN_RADIUS := 13.0
const DEPOT_SIZE := 16.0
const SITE_SIZE := 9.0
const BACKGROUND := Color(0.1, 0.09, 0.08)
const GROUND := Color(0.2, 0.18, 0.14)
const ROAD := Color(0.42, 0.37, 0.28)
const NEUTRAL := Color(0.55, 0.55, 0.52)
const SITE := Color(0.33, 0.3, 0.25)
const TEXT := Color(0.9, 0.87, 0.8)
const DIM_TEXT := Color(0.62, 0.59, 0.53)
const OUTLINE := Color(0.08, 0.07, 0.06)
const FIGHTING := Color(1.0, 0.95, 0.8)
const BATTLE := Color(0.9, 0.25, 0.2)

@export var bridge: Node

@onready var _font: Font = ThemeDB.fallback_font


func _ready() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("map"):
		visible = not visible
	if not visible or bridge.war == null:
		return
	if event.is_action_pressed("sim_speed_1"):
		bridge.clock.set_speed(1)
	elif event.is_action_pressed("sim_speed_2"):
		bridge.clock.set_speed(4)
	elif event.is_action_pressed("sim_speed_3"):
		bridge.clock.set_speed(16)
	elif event.is_action_pressed("sim_pause"):
		bridge.clock.paused = not bridge.clock.paused
	elif event.is_action_pressed("sim_new_war"):
		bridge.start_war(randi())


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)
	var war: RefCounted = bridge.war
	if war == null:
		_text(MAP_ORIGIN, "No war is running: check the data files.", TEXT)
		return
	_draw_map(war)
	_draw_panel(war)


func _to_screen(war: RefCounted, world: Vector2) -> Vector2:
	return MAP_ORIGIN + world * MAP_PIXELS / war.region.size_m


func _faction_color(war: RefCounted, faction: String) -> Color:
	return Color.html(war.region.factions[faction].color) if faction != "" else NEUTRAL


func _text(at: Vector2, text: String, color: Color, font_size := FONT_SIZE, width := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(_font, at, text, align, width, font_size, color)


func _draw_map(war: RefCounted) -> void:
	var region: RefCounted = war.region
	draw_rect(Rect2(MAP_ORIGIN, Vector2.ONE * MAP_PIXELS), GROUND)
	for id: String in region.places:
		var from := _to_screen(war, region.places[id].position)
		for neighbour: String in region.neighbours(id):
			if id < neighbour:
				draw_line(from, _to_screen(war, region.places[neighbour].position), ROAD, 3.0)
	for place in region.places.values():
		_draw_place(war, place)
	for battle: Dictionary in war.battles:
		draw_arc(_to_screen(war, battle.position), 24.0, 0.0, TAU, 32, BATTLE, 2.0)
	_draw_squads(war)
	if war.over:
		_draw_result(war)


func _draw_place(war: RefCounted, place: RefCounted) -> void:
	var at := _to_screen(war, place.position)
	var color := _faction_color(war, place.owner)
	match place.kind:
		"town":
			draw_circle(at, TOWN_RADIUS, color)
			draw_arc(at, TOWN_RADIUS, 0.0, TAU, 32, OUTLINE, 2.0)
		"depot":
			var corner := Vector2.ONE * DEPOT_SIZE / 2.0
			draw_rect(Rect2(at - corner, corner * 2.0), color)
			draw_rect(Rect2(at - corner, corner * 2.0), OUTLINE, false, 2.0)
		_:
			var corner := Vector2.ONE * SITE_SIZE / 2.0
			draw_rect(Rect2(at - corner, corner * 2.0), SITE)
	var label_color := TEXT if place.is_capturable() else DIM_TEXT
	_text(at + Vector2(-70.0, TOWN_RADIUS + 15.0), place.display_name, label_color, FONT_SIZE - 1, 140.0, HORIZONTAL_ALIGNMENT_CENTER)
	if place.capture_faction != "":
		var progress: float = 1.0 - place.capture_left / war.stats.capture_time_s
		draw_arc(at, TOWN_RADIUS + 5.0, -PI / 2.0, -PI / 2.0 + TAU * progress, 32, _faction_color(war, place.capture_faction), 3.0)


# Squads at the same spot fan out so they can all be seen and counted.
func _draw_squads(war: RefCounted) -> void:
	var spots := {}
	for squad in war.squads:
		var spot := Vector2i(squad.position(war.region) / 8.0)
		if not spots.has(spot):
			spots[spot] = []
		spots[spot].append(squad)
	for together: Array in spots.values():
		for i in together.size():
			var squad: RefCounted = together[i]
			var at := _to_screen(war, squad.position(war.region))
			if together.size() > 1:
				at += Vector2.from_angle(TAU * i / together.size()) * 9.0
			var radius: float = 2.5 + squad.soldiers * 0.45
			draw_circle(at, radius + 1.5, FIGHTING if squad.engaged else OUTLINE)
			draw_circle(at, radius, _faction_color(war, squad.faction))


func _draw_result(war: RefCounted) -> void:
	var message := "Nobody is left to fight."
	if war.winner != "":
		message = "%s holds every town." % war.region.factions[war.winner].name
	var band := Rect2(MAP_ORIGIN + Vector2(0.0, MAP_PIXELS / 2.0 - 40.0), Vector2(MAP_PIXELS, 80.0))
	draw_rect(band, Color(BACKGROUND, 0.85))
	_text(band.position + Vector2(0.0, 36.0), message, TEXT, 24, MAP_PIXELS, HORIZONTAL_ALIGNMENT_CENTER)
	_text(band.position + Vector2(0.0, 62.0), "N starts a new war", DIM_TEXT, FONT_SIZE, MAP_PIXELS, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_panel(war: RefCounted) -> void:
	var y := MAP_ORIGIN.y + 14.0
	_text(Vector2(PANEL_X, y), war.region.display_name, TEXT, 22)
	y += ROW_HEIGHT + 4.0
	var total := int(war.time_s)
	var clock: RefCounted = bridge.clock
	var speed_text := "paused" if clock.paused else "%dx" % clock.speed
	_text(Vector2(PANEL_X, y), "War time %d:%02d:%02d   Speed %s" % [total / 3600, total / 60 % 60, total % 60, speed_text], TEXT)
	y += ROW_HEIGHT * 1.5
	y = _draw_sides(war, y) + ROW_HEIGHT / 2.0
	y = _draw_stock_table(war, y) + ROW_HEIGHT
	_text(Vector2(PANEL_X, y), "1 / 2 / 3  speed 1x, 4x, 16x     Space  pause", DIM_TEXT)
	y += ROW_HEIGHT
	_text(Vector2(PANEL_X, y), "N  new war     M  close map", DIM_TEXT)
	y += ROW_HEIGHT
	_text(Vector2(PANEL_X, y), "War seed %d" % bridge.war_seed, DIM_TEXT, FONT_SIZE - 2)


func _draw_sides(war: RefCounted, y: float) -> float:
	for faction: String in war.region.factions:
		var squads: Array = war.squads_of(faction)
		var soldiers := 0
		for squad in squads:
			soldiers += squad.soldiers
		var towns := 0
		for place in war.region.places.values():
			if place.kind == "town" and place.owner == faction:
				towns += 1
		draw_rect(Rect2(PANEL_X, y - 11.0, 12.0, 12.0), _faction_color(war, faction))
		_text(Vector2(PANEL_X + 20.0, y), "%s   %d towns   %d squads   %d soldiers" % [war.region.factions[faction].name, towns, squads.size(), soldiers], TEXT)
		y += ROW_HEIGHT
	return y


func _draw_stock_table(war: RefCounted, y: float) -> float:
	var x := PANEL_X + NAME_COLUMN + OWNER_COLUMN
	for resource in Stockpile.RESOURCES:
		_text(Vector2(x, y), resource, DIM_TEXT, FONT_SIZE - 1, STOCK_COLUMN - 6.0, HORIZONTAL_ALIGNMENT_RIGHT)
		x += STOCK_COLUMN
	y += ROW_HEIGHT
	for place in war.region.places.values():
		if not place.is_capturable():
			continue
		_text(Vector2(PANEL_X, y), place.display_name, TEXT)
		draw_rect(Rect2(PANEL_X + NAME_COLUMN, y - 11.0, 12.0, 12.0), _faction_color(war, place.owner))
		x = PANEL_X + NAME_COLUMN + OWNER_COLUMN
		for resource in Stockpile.RESOURCES:
			_text(Vector2(x, y), str(int(place.stock.amount(resource))), TEXT, FONT_SIZE, STOCK_COLUMN - 6.0, HORIZONTAL_ALIGNMENT_RIGHT)
			x += STOCK_COLUMN
		y += ROW_HEIGHT
	return y
