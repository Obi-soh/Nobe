class_name AbilityEngine
extends RefCounted

static func active_night_actors(session: RefCounted) -> Array:
	var actors: Array = []
	for player: Dictionary in session.players:
		if not bool(player.get("alive", false)):
			continue
		var role := RoleCatalog.character(str(player.get("role_id", "")))
		var ability := RoleCatalog.ability_for_character(str(player.get("role_id", "")))
		if str(ability.get("kind", "skip")) == "skip":
			continue
		actors.append({
			"player_id": str(player.get("id", "")),
			"role_id": str(player.get("role_id", "")),
			"role_name": str(role.get("name", "")),
			"ability": ability,
			"order": int(role.get("night_order", 99)),
		})
	actors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("order", 99)) < int(b.get("order", 99))
	)
	return actors

static func resolve_night(session: RefCounted) -> Array:
	var results: Array = []
	var intents: Array = session.night_intents.duplicate(true)
	intents.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("order", 99)) < int(b.get("order", 99))
	)
	for intent: Dictionary in intents:
		var actor_id := str(intent.get("actor_id", ""))
		var target_id := str(intent.get("target_id", ""))
		var ability_id := str(intent.get("ability_id", "none"))
		var ability: Dictionary = RoleCatalog.ABILITIES.get(ability_id, {})
		var target: Dictionary = session.get_player(target_id)
		if target.is_empty():
			continue
		match str(ability.get("kind", "skip")):
			"protect":
				target["protected"] = true
				session.update_player(target)
				results.append({"type": "protect", "target_id": target_id, "text": "تمت حماية %s هذه الليلة." % target.get("name", "الهدف")})
			"sleep_with":
				session.night_context["sleep_target_id"] = target_id
				session.night_context["seductress_id"] = actor_id
				results.append({"type": "visit", "target_id": target_id, "text": "سُجلت زيارة ليلية دون إعلان اسم الزائر."})
			"attack":
				if bool(target.get("protected", false)):
					results.append({"type": "blocked", "target_id": target_id, "text": "نجا %s بفضل الحماية." % target.get("name", "الهدف")})
				else:
					target["attacked"] = true
					var role := RoleCatalog.character(str(target.get("role_id", "")))
					var resistances: Array = role.get("resistances", [])
					if "هجوم ليلي" in resistances:
						results.append({"type": "resisted", "target_id": target_id, "text": "نجا %s بمقاومته الخاصة." % target.get("name", "الهدف")})
					else:
						target["alive"] = false
						session.update_player(target)
						results.append({"type": "death", "target_id": target_id, "text": "وجدت القرية %s خارج اللعبة عند الفجر." % target.get("name", "أحد اللاعبين")})
			"reveal":
				var target_role := RoleCatalog.character(str(target.get("role_id", "")))
				var reveal_text := "دور %s هو: %s." % [target.get("name", "اللاعب"), target_role.get("name", "غير معروف")]
				if str(target.get("role_id", "")) == "seductress":
					var discovered := randf() <= 0.25
					if discovered and session.night_context.has("sleep_target_id"):
						reveal_text += " وقد عرفتَ أيضًا أنها نامت مع %s." % session.get_player(str(session.night_context.get("sleep_target_id"))).get("name", "لاعب")
					else:
						reveal_text += " ظهرت لك خارج المنزل؛ لم تعرف مع من نامت."
				session.private_results[actor_id] = reveal_text
				results.append({"type": "reveal", "actor_id": actor_id, "text": "تم تسجيل نتيجة كشف خاصة."})
	return results

static func check_condition(session: RefCounted, actor_id: String, ability_id: String, target_id: String) -> Dictionary:
	var actor: Dictionary = session.get_player(actor_id)
	var target: Dictionary = session.get_player(target_id)
	if actor.is_empty() or not bool(actor.get("alive", false)):
		return {"ok": false, "reason": "لا يمكن استخدام القدرة بعد الموت."}
	if target.is_empty() or not bool(target.get("alive", false)):
		return {"ok": false, "reason": "اختر لاعبًا حيًا."}
	if actor_id == target_id and ability_id != "attack":
		return {"ok": false, "reason": "لا يمكنك اختيار نفسك."}
	if ability_id == "attack" and str(target.get("role_id", "")) == "werewolf":
		return {"ok": false, "reason": "لا يمكن مهاجمة فرد من القطيع."}
	return {"ok": true, "reason": ""}
