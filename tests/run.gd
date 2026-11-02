# Headless test runner for the sim layer: godot --headless -s tests/run.gd
# Runs every test_* method in tests/test_*.gd. Check things with assert().
# Any script or engine error during a test fails it, because GDScript carries on
# after a runtime error and the test would otherwise look like a pass.
extends SceneTree

const TEST_DIR := "res://tests/"


class ErrorLog extends Logger:
	var _lock := Mutex.new()
	var _errors: Array[String] = []

	func _log_error(_function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		var text := "%s:%d %s" % [file, line, code if rationale.is_empty() else rationale]
		_lock.lock()
		_errors.append(text)
		_lock.unlock()

	# Returns the errors logged since the last call.
	func take() -> Array[String]:
		_lock.lock()
		var taken := _errors
		_errors = []
		_lock.unlock()
		return taken


var _passed := 0
var _failed := 0


func _initialize() -> void:
	var error_log := ErrorLog.new()
	OS.add_logger(error_log)
	for file_name in DirAccess.get_files_at(TEST_DIR):
		if file_name.begins_with("test_") and file_name.ends_with(".gd"):
			_run_file(file_name, error_log)
	OS.remove_logger(error_log)
	if _passed + _failed == 0:
		_fail("no tests found in " + TEST_DIR, [])
	print("%d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _run_file(file_name: String, error_log: ErrorLog) -> void:
	var script: GDScript = load(TEST_DIR + file_name)
	if script == null or not script.can_instantiate():
		_fail(file_name + " did not load", error_log.take())
		return
	var test_case: Object = script.new()
	var ran := 0
	for method in test_case.get_method_list():
		var method_name: String = method.name
		if not method_name.begins_with("test_"):
			continue
		ran += 1
		test_case.call(method_name)
		var errors := error_log.take()
		if errors.is_empty():
			_passed += 1
			print("PASS %s::%s" % [file_name, method_name])
		else:
			_fail("%s::%s" % [file_name, method_name], errors)
	if ran == 0:
		_fail(file_name + " has no test_ methods", error_log.take())


func _fail(what: String, errors: Array[String]) -> void:
	_failed += 1
	print("FAIL " + what)
	for error in errors:
		print("     " + error)
