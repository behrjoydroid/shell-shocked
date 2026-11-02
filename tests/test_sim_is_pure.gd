# CLAUDE.md's hard rule: sim/ has no Node or scene dependencies and must run headless.
extends RefCounted

const SIM_DIR := "res://sim/"
const FORBIDDEN: Array[String] = ["extends Node", "extends Control", "extends Sprite", "get_tree", "get_node", "Input.", "add_child", "preload(\"res://world", "preload(\"res://ui"]


func test_nothing_in_sim_touches_scenes_or_input() -> void:
	var files := DirAccess.get_files_at(SIM_DIR)
	var checked := 0
	for file_name in files:
		if not file_name.ends_with(".gd"):
			continue
		checked += 1
		var source := FileAccess.get_file_as_string(SIM_DIR + file_name)
		for word in FORBIDDEN:
			assert(word not in source, "%s uses %s" % [file_name, word])
	assert(checked >= 7, "only found %d sim files" % checked)
