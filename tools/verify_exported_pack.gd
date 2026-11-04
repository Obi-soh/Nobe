extends SceneTree

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	_check(ProjectSettings.get_setting("application/config/name") == "ليلة الذئب", "exported identity")
	for path: String in [
		"assets/generated/nobe-emblem.png",
		"assets/generated/villager-crest.png",
		"assets/generated/werewolf-crest.png",
		"assets/generated/neutral-crest.png",
		"assets/fonts/NotoSansArabic-Regular.ttf",
	]:
		_check(ResourceLoader.exists("res://" + path), "pack resource: " + path)
	_check(ResourceLoader.exists("res://scenes/main.tscn"), "exported main scene")
	_check(not ResourceLoader.exists("res://test/nobe_test_suite.tscn"), "test scene excluded")
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed != null:
		var main := packed.instantiate()
		root.add_child(main)
		await process_frame
		await process_frame
		_check(main.has_method("_show_setup"), "pack exposes game setup")
		_check(main.get("_body") != null, "pack builds the Arabic interface")
		var session := GameSession.new()
		var configured: Dictionary = session.configure(["سارة", "عمر", "ليان", "فهد", "نور"], RoleCatalog.DEFAULT_ROLE_COUNTS, true)
		_check(bool(configured.get("ok", false)), "pack creates a local round")
		_check(session.players.size() == 5, "pack assigns five players")
		main.queue_free()
		await process_frame
	if _failures.is_empty():
		print("[exported-pack] PASS: identity, resources, Arabic UI, local round")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[exported-pack] " + failure)
		quit(1)

func _check(condition: bool, context: String) -> void:
	if not condition and context not in _failures:
		_failures.append(context)
