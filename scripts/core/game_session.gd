class_name GameSession
extends RefCounted

const AbilityEngineType := preload("res://scripts/core/ability_engine.gd")

var phase := "setup"
var round_number := 1
var players: Array = []
var role_counts: Dictionary = {}
var random_assignment := true
var pass_index := 0
var night_index := 0
var night_actors: Array = []
var night_intents: Array = []
var night_results: Array = []
var night_context: Dictionary = {}
var private_results: Dictionary = {}
var vote_index := 0
var votes: Array = []
var events: Array = []
var winner := ""
var winner_reason := ""
var created_at := 0

func _init() -> void:
	created_at = Time.get_unix_time_from_system()

func configure(names: Array, counts: Dictionary, should_randomize := true) -> Dictionary:
	players.clear()
	role_counts = counts.duplicate(true)
	random_assignment = should_randomize
	var clean_names: Array = []
	for raw_name: Variant in names:
		var name := str(raw_name).strip_edges()
		if not name.is_empty() and name not in clean_names:
			clean_names.append(name.left(24))
	if clean_names.size() < 3:
		return {"ok": false, "error": "أدخل أسماء ثلاثة لاعبين على الأقل."}
	var role_ids := RoleCatalog.selected_role_ids(role_counts)
	if role_ids.is_empty():
		return {"ok": false, "error": "اختر شخصية واحدة على الأقل."}
	if role_ids.size() > clean_names.size():
		return {"ok": false, "error": "عدد الشخصيات (%d) أكبر من عدد اللاعبين (%d)." % [role_ids.size(), clean_names.size()]}
	while role_ids.size() < clean_names.size():
		role_ids.append("villager")
	if should_randomize:
		randomize_role_ids(role_ids)
	for index: int in clean_names.size():
		var role_id := str(role_ids[index])
		var role := RoleCatalog.character(role_id)
		players.append({
			"id": "player_%02d" % (index + 1),
			"name": clean_names[index],
			"role_id": role_id,
			"role_name": role.get("name", ""),
			"team_id": role.get("team_id", "villagers"),
			"alive": true,
			"protected": false,
			"attacked": false,
			"statuses": [],
			"ability_uses": {},
		})
	phase = "review"
	pass_index = 0
	return {"ok": true, "error": ""}

func randomize_role_ids(role_ids: Array) -> void:
	role_ids.shuffle()

func apply_manual_roles(assignments: Array) -> Dictionary:
	if assignments.size() != players.size():
		return {"ok": false, "error": "لم يكتمل التوزيع اليدوي."}
	for index: int in players.size():
		var role_id := str(assignments[index])
		if not RoleCatalog.CHARACTERS.has(role_id):
			return {"ok": false, "error": "شخصية غير معروفة في التوزيع."}
		var role := RoleCatalog.character(role_id)
		players[index].role_id = role_id
		players[index].role_name = role.get("name", "")
		players[index].team_id = role.get("team_id", "villagers")
	phase = "review"
	return {"ok": true, "error": ""}

func begin_pass() -> void:
	phase = "pass"
	pass_index = 0
	private_results.clear()
	_log("pass", "بدأ تسليم الأدوار بسرية.")

func current_pass_player() -> Dictionary:
	if pass_index < 0 or pass_index >= players.size():
		return {}
	return players[pass_index].duplicate(true)

func reveal_current_role() -> Dictionary:
	return current_pass_player()

func complete_pass() -> bool:
	pass_index += 1
	if pass_index >= players.size():
		begin_night()
		return true
	return false

func begin_night() -> void:
	phase = "night"
	night_index = 0
	night_actors = AbilityEngineType.active_night_actors(self)
	night_intents.clear()
	night_results.clear()
	night_context.clear()
	private_results.clear()
	for player: Dictionary in players:
		player["protected"] = false
		player["attacked"] = false
	_log("night", "حلّ الليل رقم %d." % round_number)
	if night_actors.is_empty():
		begin_day()

func current_night_actor() -> Dictionary:
	if night_index < 0 or night_index >= night_actors.size():
		return {}
	var actor: Dictionary = night_actors[night_index].duplicate(true)
	actor["player"] = get_player(str(actor.get("player_id", "")))
	return actor

func available_targets(actor_id: String) -> Array:
	var result: Array = []
	for player: Dictionary in players:
		if not bool(player.get("alive", false)):
			continue
		if str(player.get("id", "")) == actor_id:
			continue
		result.append(player.duplicate(true))
	return result

func submit_night_action(target_id: String) -> Dictionary:
	var actor := current_night_actor()
	if actor.is_empty():
		return {"ok": false, "error": "لا يوجد دور ليلي حالي."}
	var ability: Dictionary = actor.get("ability", {})
	var check := AbilityEngineType.check_condition(self, str(actor.get("player_id", "")), str(ability.get("id", "none")), target_id)
	if not bool(check.get("ok", false)):
		return check
	night_intents.append({
		"actor_id": str(actor.get("player_id", "")),
		"target_id": target_id,
		"ability_id": str(ability.get("id", "none")),
		"order": int(actor.get("order", 99)),
	})
	night_index += 1
	if night_index >= night_actors.size():
		begin_day()
		return {"ok": true, "complete": true, "error": ""}
	return {"ok": true, "complete": false, "error": ""}

func skip_night_actor() -> Dictionary:
	if night_index >= night_actors.size():
		return {"ok": false, "error": "لا يوجد دور حالي."}
	night_index += 1
	if night_index >= night_actors.size():
		begin_day()
		return {"ok": true, "complete": true, "error": ""}
	return {"ok": true, "complete": false, "error": ""}

func begin_day() -> void:
	phase = "day"
	night_results = AbilityEngineType.resolve_night(self)
	for event: Dictionary in night_results:
		_log(str(event.get("type", "night")), str(event.get("text", "")))
	var victory := check_victory()
	if not victory.is_empty():
		winner = victory.get("winner", "")
		winner_reason = victory.get("reason", "")
		phase = "result"

func begin_vote() -> void:
	if phase == "result":
		return
	phase = "vote"
	vote_index = 0
	votes.clear()
	for player: Dictionary in players:
		if bool(player.get("alive", false)):
			votes.append({"voter_id": player.get("id", ""), "target_id": ""})

func current_voter() -> Dictionary:
	if vote_index < 0 or vote_index >= votes.size():
		return {}
	return get_player(str(votes[vote_index].get("voter_id", "")))

func submit_vote(target_id: String) -> Dictionary:
	var voter := current_voter()
	if voter.is_empty():
		return {"ok": false, "error": "لا يوجد مصوّت حالي."}
	var target := get_player(target_id)
	if target.is_empty() or not bool(target.get("alive", false)):
		return {"ok": false, "error": "اختر لاعبًا حيًا."}
	votes[vote_index]["target_id"] = target_id
	_log("vote", "%s سجّل تصويتًا." % voter.get("name", "لاعب"))
	vote_index += 1
	if vote_index >= votes.size():
		finalize_vote()
		return {"ok": true, "complete": true, "error": ""}
	return {"ok": true, "complete": false, "error": ""}

func finalize_vote() -> void:
	var tally: Dictionary = {}
	for vote: Dictionary in votes:
		var target_id := str(vote.get("target_id", ""))
		if target_id.is_empty():
			continue
		tally[target_id] = int(tally.get(target_id, 0)) + 1
	if tally.is_empty():
		_log("vote", "لم يحصل أي لاعب على أصوات كافية.")
	else:
		var best_id := ""
		var best_votes := 0
		for target_id: String in tally:
			if int(tally[target_id]) > best_votes:
				best_id = target_id
				best_votes = int(tally[target_id])
		if not best_id.is_empty():
			var eliminated := get_player(best_id)
			eliminated["alive"] = false
			eliminated["statuses"].append("أُخرج بالتصويت")
			update_player(eliminated)
			_log("elimination", "خرج %s من اللعبة بالتصويت." % eliminated.get("name", "لاعب"))
		var victory := check_victory()
		if not victory.is_empty():
			winner = victory.get("winner", "")
			winner_reason = victory.get("reason", "")
			phase = "result"
			return
	round_number += 1
	begin_night()

func check_victory() -> Dictionary:
	var alive_villagers := 0
	var alive_wolves := 0
	var alive_neutrals := 0
	for player: Dictionary in players:
		if not bool(player.get("alive", false)):
			continue
		match str(player.get("team_id", "villagers")):
			"villagers": alive_villagers += 1
			"werewolves": alive_wolves += 1
			"neutral": alive_neutrals += 1
	if alive_wolves == 0:
		return {"winner": "القرويون", "reason": "تم القضاء على جميع المستذئبين."}
	if alive_wolves >= alive_villagers and alive_wolves > 0:
		return {"winner": "المستذئبون", "reason": "أصبح عدد المستذئبين مساويًا لعدد بقية الأحياء."}
	return {}

func get_player(player_id: String) -> Dictionary:
	for player: Dictionary in players:
		if str(player.get("id", "")) == player_id:
			return player
	return {}

func update_player(updated: Dictionary) -> void:
	for index: int in players.size():
		if str(players[index].get("id", "")) == str(updated.get("id", "")):
			players[index] = updated.duplicate(true)
			return

func alive_players() -> Array:
	var result: Array = []
	for player: Dictionary in players:
		if bool(player.get("alive", false)):
			result.append(player.duplicate(true))
	return result

func _log(kind: String, text: String) -> void:
	events.append({"round": round_number, "phase": phase, "kind": kind, "text": text, "time": Time.get_unix_time_from_system()})

func backup_payload() -> Dictionary:
	return {
		"version": 1,
		"game": "nobe",
		"round_number": round_number,
		"phase": phase,
		"players": players.duplicate(true),
		"role_counts": role_counts.duplicate(true),
		"events": events.duplicate(true),
		"created_at": created_at,
	}
