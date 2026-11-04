extends Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: PackedStringArray = []
	var checks := 0
	var packed: PackedScene = load("res://scenes/main.tscn")
	checks += 1
	if packed == null:
		failures.append("المشهد الرئيسي يجب أن يُحمّل")
	else:
		var instance := packed.instantiate()
		get_tree().root.add_child(instance)
		await get_tree().process_frame
		checks += 1
		if not instance.has_method("_show_setup"):
			failures.append("واجهة اللعبة يجب أن تحتوي مسار إعداد الجولة")
		checks += 1
		if instance.get("_body") == null:
			failures.append("حاوية الواجهة يجب أن تُبنى عند الإقلاع")
		instance.queue_free()
		await get_tree().process_frame
	var session := GameSession.new()
	var counts := RoleCatalog.DEFAULT_ROLE_COUNTS.duplicate(true)
	var configured: Dictionary = session.configure(["سارة", "عمر", "ليان", "فهد", "نور"], counts, true)
	checks += 1
	if not bool(configured.get("ok", false)):
		failures.append("الجلسة يجب أن تقبل تشكيلة من خمسة لاعبين")
	checks += 1
	if session.players.size() != 5:
		failures.append("الجلسة يجب أن تنشئ خمسة لاعبين")
	session.begin_pass()
	for _index in session.players.size():
		session.complete_pass()
	checks += 1
	if session.phase not in ["night", "day", "result"]:
		failures.append("تمرير الأدوار يجب أن ينقل الجولة إلى الليل أو اليوم")
	checks += 1
	if RoleCatalog.character("seer").get("ability_id", "") != "seer_reveal":
		failures.append("العراف يجب أن يرتبط بقدرة كشف مستقلة")
	if failures.is_empty():
		print("[nobe-tests] PASS: %d checks" % checks)
		get_tree().quit(0)
		return
	for failure: String in failures:
		push_error("[nobe-tests] " + failure)
	print("[nobe-tests] FAIL: %d failures across %d checks" % [failures.size(), checks])
	get_tree().quit(1)
