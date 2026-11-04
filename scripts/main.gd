extends Control

const GameSessionType := preload("res://scripts/core/game_session.gd")
const RoleCatalogType := preload("res://scripts/core/role_catalog.gd")
const EMBLEM := preload("res://assets/generated/nobe-emblem.png")

const BG := Color("#090C12")
const PANEL := Color("#121722")
const PANEL_2 := Color("#18202D")
const TEXT := Color("#F4EFE6")
const MUTED := Color("#A7AFBF")
const GOLD := Color("#D8B56A")
const DANGER := Color("#EF8090")
const SUCCESS := Color("#9BD1A9")
const ROLE_ORDER := ["villager", "seer", "guard", "werewolf", "seductress", "survivor"]

var session: RefCounted
var _body: VBoxContainer
var _header: HBoxContainer
var _footer_status: Label
var _setup_names: TextEdit
var _role_counts: Dictionary = RoleCatalogType.DEFAULT_ROLE_COUNTS.duplicate(true)
var _count_labels: Dictionary = {}
var _randomize_roles := true
var _manual_options: Array = []
var _pass_revealed := false
var _pass_hidden := false
var _night_confirmation := false
var _organizer_status := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layout_direction = Control.LAYOUT_DIRECTION_RTL
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var arabic_theme := Theme.new()
	arabic_theme.default_font = load("res://assets/fonts/NotoSansArabic-Regular.ttf")
	arabic_theme.default_font_size = 18
	theme = arabic_theme
	_build_background()
	_body = VBoxContainer.new()
	_body.name = "AppBody"
	_body.add_theme_constant_override("separation", 16)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_body.offset_left = 28.0
	_body.offset_top = 22.0
	_body.offset_right = -28.0
	_body.offset_bottom = -18.0
	add_child(_body)
	_build_header()
	_footer_status = _label("لعبة محلية، لا تحتاج إلى إنترنت", 13, MUTED)
	_footer_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_child(_footer_status)
	session = GameSessionType.new()
	_show_home()

func _build_background() -> void:
	var background := ColorRect.new()
	background.color = BG
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var glow := ColorRect.new()
	glow.color = Color(0.14, 0.10, 0.20, 0.24)
	glow.position = Vector2(0, 0)
	glow.size = Vector2(320, 300)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)
	move_child(glow, 1)

func _build_header() -> void:
	_header = HBoxContainer.new()
	_header.name = "Header"
	_header.custom_minimum_size = Vector2(0, 74)
	_header.add_theme_constant_override("separation", 14)
	_body.add_child(_header)
	var emblem := TextureRect.new()
	emblem.texture = EMBLEM
	emblem.custom_minimum_size = Vector2(58, 58)
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header.add_child(emblem)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.alignment = BoxContainer.ALIGNMENT_CENTER
	_header.add_child(titles)
	var brand := _label("لَيْلَة الذِّئْب", 22, TEXT)
	brand.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	brand.add_theme_constant_override("shadow_offset_y", 2)
	titles.add_child(brand)
	var sub := _label("كل مدينة تخفي سرًا", 12, GOLD)
	titles.add_child(sub)

func _clear_body() -> void:
	for child: Node in _body.get_children():
		if child != _header and child != _footer_status:
			child.queue_free()
	_footer_status.text = "لعبة محلية، لا تحتاج إلى إنترنت"

func _show_home() -> void:
	_clear_body()
	var scroll := _scroll()
	var content := _column()
	scroll.add_child(content)
	_body.add_child(scroll)
	var hero := _panel()
	content.add_child(hero)
	var hero_col := _column()
	hero.add_child(hero_col)
	var title := _label("لعبة الذئب والمجتمع", 32, TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_col.add_child(title)
	var intro := _label("أدر الجولة، احفظ الأسرار، واكتشف من يختبئ بينكم.", 17, MUTED)
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_col.add_child(intro)
	var chips := HBoxContainer.new()
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	chips.add_theme_constant_override("separation", 8)
	hero_col.add_child(chips)
	chips.add_child(_chip("هاتف واحد"))
	chips.add_child(_chip("عربي"))
	chips.add_child(_chip("بدون إنترنت"))
	content.add_child(_spacer(6))
	var create_button := _button("إنشاء جولة جديدة", GOLD, TEXT)
	create_button.pressed.connect(_show_setup)
	content.add_child(create_button)
	var organizer_button := _button("لوحة المنظّم", Color("#2B3444"), TEXT)
	organizer_button.pressed.connect(_show_organizer)
	content.add_child(organizer_button)
	var info := _panel()
	content.add_child(info)
	var info_col := _column()
	info.add_child(info_col)
	info_col.add_child(_label("كيف تعمل؟", 17, GOLD))
	info_col.add_child(_label("أدخل أسماء اللاعبين، وزّع الأدوار، ثم مرّر الهاتف. كل لاعب يرى دوره وحده قبل أن يخفيه ويسلّمه للاعب التالي.", 14, MUTED))
	_footer_status.text = "نسخة أولى قابلة للعب، القواعد محفوظة خارج الواجهة"

func _show_setup() -> void:
	_clear_body()
	var scroll := _scroll()
	var content := _column()
	scroll.add_child(content)
	_body.add_child(scroll)
	content.add_child(_section_title("إنشاء جولة", "أضف اللاعبين واختر أدوار الليلة."))
	var player_panel := _panel()
	content.add_child(player_panel)
	var player_col := _column()
	player_panel.add_child(player_col)
	player_col.add_child(_label("أسماء اللاعبين", 18, TEXT))
	var hint := _label("اسم واحد في كل سطر، ثلاثة لاعبين على الأقل", 13, MUTED)
	player_col.add_child(hint)
	_setup_names = TextEdit.new()
	_setup_names.custom_minimum_size = Vector2(0, 150)
	_setup_names.placeholder_text = "مثال:\nسارة\nعمر\nليان"
	_setup_names.text = "اللاعب ١\nاللاعب ٢\nاللاعب ٣\nاللاعب ٤\nاللاعب ٥"
	_setup_names.add_theme_font_size_override("font_size", 18)
	_setup_names.add_theme_color_override("font_color", TEXT)
	_setup_names.add_theme_stylebox_override("normal", _style(Color("#0D111A"), Color("#2C384A"), 1, 12))
	player_col.add_child(_setup_names)
	content.add_child(_section_title("تشكيلة الأدوار", "حدد عدد الشخصيات المستخدمة. سيُضاف القروي تلقائيًا عند الحاجة."))
	var roles_panel := _panel()
	content.add_child(roles_panel)
	var roles_col := _column(8)
	roles_panel.add_child(roles_col)
	_count_labels.clear()
	for role_id: String in ROLE_ORDER:
		roles_col.add_child(_role_count_row(role_id))
	var total_line := _label("المجموع: %d شخصية" % _selected_role_total(), 14, GOLD)
	total_line.name = "RoleTotal"
	roles_col.add_child(total_line)
	var mode_title := _label("طريقة التوزيع", 17, TEXT)
	content.add_child(mode_title)
	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation", 10)
	content.add_child(modes)
	var random_button := _button("توزيع عشوائي", Color("#2B3444"), TEXT, 52)
	random_button.toggle_mode = true
	random_button.button_pressed = _randomize_roles
	random_button.pressed.connect(func():
		_randomize_roles = true
		random_button.button_pressed = true
		_update_setup_mode(modes)
	)
	modes.add_child(random_button)
	var manual_button := _button("توزيع يدوي", Color("#202938"), TEXT, 52)
	manual_button.toggle_mode = true
	manual_button.button_pressed = not _randomize_roles
	manual_button.pressed.connect(func():
		_randomize_roles = false
		manual_button.button_pressed = true
		_update_setup_mode(modes)
	)
	modes.add_child(manual_button)
	var start_button := _button("مراجعة التوزيع", GOLD, TEXT)
	start_button.pressed.connect(_start_review)
	content.add_child(start_button)
	var back_button := _button("رجوع", Color("#202938"), MUTED, 48)
	back_button.pressed.connect(_show_home)
	content.add_child(back_button)
	_footer_status.text = "لا تبدأ الجولة حتى تتأكد من عدد الأدوار واللاعبين."

func _update_setup_mode(modes: HBoxContainer) -> void:
	for child: Node in modes.get_children():
		var button := child as Button
		if button == null:
			continue
		button.modulate = Color.WHITE

func _start_review() -> void:
	var names: Array = _setup_names.text.split("\n", false)
	var result: Dictionary = session.configure(names, _role_counts, _randomize_roles)
	if not bool(result.get("ok", false)):
		_footer_status.text = str(result.get("error", "تعذر إنشاء الجولة."))
		_footer_status.add_theme_color_override("font_color", DANGER)
		return
	_footer_status.add_theme_color_override("font_color", MUTED)
	_show_review()

func _show_review() -> void:
	_clear_body()
	var scroll := _scroll()
	var content := _column()
	scroll.add_child(content)
	_body.add_child(scroll)
	content.add_child(_section_title("مراجعة الأدوار", "هذه الشاشة للمنظّم فقط. تأكد من التوزيع قبل تمرير الهاتف."))
	if not _randomize_roles:
		content.add_child(_label("التوزيع اليدوي", 15, GOLD))
		_manual_options.clear()
		for index: int in session.players.size():
			var player: Dictionary = session.players[index]
			var row := _panel()
			content.add_child(row)
			var line := HBoxContainer.new()
			line.add_theme_constant_override("separation", 10)
			row.add_child(line)
			var name_label := _label(str(player.get("name", "")), 17, TEXT)
			name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.add_child(name_label)
			var option := OptionButton.new()
			option.custom_minimum_size = Vector2(190, 50)
			option.add_theme_font_size_override("font_size", 16)
			var used_ids := RoleCatalogType.selected_role_ids(_role_counts)
			var unique_ids: Array = []
			for role_id: Variant in used_ids:
				if role_id not in unique_ids:
					unique_ids.append(role_id)
			for role_id: String in unique_ids:
				var role := RoleCatalogType.character(role_id)
				option.add_item(str(role.get("name", role_id)))
				option.set_item_metadata(option.item_count - 1, role_id)
			var current_id := str(player.get("role_id", "villager"))
			for item_index: int in option.item_count:
				if str(option.get_item_metadata(item_index)) == current_id:
					option.select(item_index)
					break
			line.add_child(option)
			_manual_options.append(option)
	else:
		content.add_child(_label("التوزيع العشوائي جاهز. يمكنك إعادة التوزيع قبل البدء.", 14, MUTED))
		for player: Dictionary in session.players:
			content.add_child(_review_player_card(player, true))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	content.add_child(actions)
	var begin_button := _button("بدء تمرير الهاتف", GOLD, TEXT)
	begin_button.pressed.connect(_begin_pass_from_review)
	actions.add_child(begin_button)
	var reroll_button := _button("إعادة التوزيع", Color("#2B3444"), TEXT)
	reroll_button.pressed.connect(func():
		var names: Array = _setup_names.text.split("\n", false)
		session.configure(names, _role_counts, _randomize_roles)
		_show_review()
	)
	actions.add_child(reroll_button)
	var back := _button("تعديل الإعدادات", Color("#202938"), MUTED, 48)
	back.pressed.connect(_show_setup)
	content.add_child(back)
	_footer_status.text = "التوزيع السري يبدأ بعد الضغط على «بدء تمرير الهاتف»."

func _begin_pass_from_review() -> void:
	if not _randomize_roles:
		var assignments: Array = []
		for option: OptionButton in _manual_options:
			if option.selected < 0:
				_footer_status.text = "اختر دورًا لكل لاعب قبل البدء."
				_footer_status.add_theme_color_override("font_color", DANGER)
				return
			assignments.append(str(option.get_item_metadata(option.selected)))
		var result: Dictionary = session.apply_manual_roles(assignments)
		if not bool(result.get("ok", false)):
			_footer_status.text = str(result.get("error", "تعذر حفظ التوزيع."))
			return
	session.begin_pass()
	_pass_revealed = false
	_pass_hidden = false
	_show_pass()

func _show_pass() -> void:
	_clear_body()
	var scroll := _scroll()
	var content := _column()
	scroll.add_child(content)
	_body.add_child(scroll)
	var current: Dictionary = session.current_pass_player()
	content.add_child(_section_title("تسليم الهاتف", "اللاعب الحالي فقط ينظر إلى الشاشة."))
	var privacy := _panel()
	content.add_child(privacy)
	var privacy_col := _column()
	privacy.add_child(privacy_col)
	var player_name := _label(str(current.get("name", "")), 30, GOLD)
	player_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	privacy_col.add_child(player_name)
	var instruction := "اضغط لعرض شخصيتك سرًا." if not _pass_revealed else "اقرأ دورك واحتفظ به لنفسك."
	var instruction_label := _label(instruction, 16, MUTED)
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	privacy_col.add_child(instruction_label)
	if not _pass_revealed and not _pass_hidden:
		privacy_col.add_child(_role_back_art())
		var reveal := _button("عرض شخصيتي", GOLD, TEXT)
		reveal.pressed.connect(func():
			_pass_revealed = true
			_show_pass()
		)
		privacy_col.add_child(reveal)
	elif _pass_revealed:
		privacy_col.add_child(_role_card(current, true))
		var hide := _button("إخفاء الشخصية", Color("#2B3444"), TEXT)
		hide.pressed.connect(func():
			_pass_revealed = false
			_pass_hidden = true
			_show_pass()
		)
		privacy_col.add_child(hide)
	else:
		var hidden_label := _label("تم إخفاء الشخصية. لا تسمح للاعب التالي بالرجوع إلى هذه الشاشة.", 16, SUCCESS)
		hidden_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		privacy_col.add_child(hidden_label)
		var next_text := "ابدأ الليل" if session.pass_index >= session.players.size() - 1 else "سلّم الهاتف للاعب التالي"
		var next := _button(next_text, GOLD, TEXT)
		next.pressed.connect(_advance_pass)
		privacy_col.add_child(next)
	_footer_status.text = "حماية السرية: لا توجد أزرار رجوع أثناء تمرير الهاتف."

func _advance_pass() -> void:
	var complete: bool = session.complete_pass()
	if complete:
		_show_night()
	else:
		_pass_revealed = false
		_pass_hidden = false
		_show_pass()

func _show_night() -> void:
	_clear_body()
	if session.phase == "day" or session.current_night_actor().is_empty():
		_show_day()
		return
	var scroll := _scroll()
	var content := _column()
	scroll.add_child(content)
	_body.add_child(scroll)
	var actor: Dictionary = session.current_night_actor()
	var player: Dictionary = actor.get("player", {})
	var ability: Dictionary = actor.get("ability", {})
	content.add_child(_phase_banner("الليل %d" % session.round_number, "دور %s" % player.get("name", "اللاعب"), Color("#23204A")))
	var actor_card := _panel()
	content.add_child(actor_card)
	var actor_col := _column()
	actor_card.add_child(actor_col)
	actor_col.add_child(_label(str(actor.get("role_name", "")), 26, RoleCatalogType.accent_for_team(str(player.get("team_id", "villagers")))))
	actor_col.add_child(_label(str(ability.get("name", "قدرة ليلية")), 17, GOLD))
	actor_col.add_child(_label("%s" % _ability_instruction(str(ability.get("kind", "skip"))), 14, MUTED))
	if _night_confirmation:
		_show_night_confirmation(content, actor)
	else:
		var target_label := _label("اختر هدفًا من اللاعبين الأحياء:", 15, TEXT)
		content.add_child(target_label)
		for target: Dictionary in session.available_targets(str(actor.get("player_id", ""))):
			var target_button := _button(str(target.get("name", "")), RoleCatalogType.color_for_team(str(target.get("team_id", "villagers"))), TEXT, 54)
			target_button.pressed.connect(_choose_night_target.bind(str(target.get("id", ""))))
			content.add_child(target_button)
	_footer_status.text = "الأدوار الليلية تُنفّذ حسب ترتيب الاستيقاظ المسجل."

func _choose_night_target(target_id: String) -> void:
	var result: Dictionary = session.submit_night_action(target_id)
	if not bool(result.get("ok", false)):
		_footer_status.text = str(result.get("error", "تعذر تنفيذ القدرة."))
		_footer_status.add_theme_color_override("font_color", DANGER)
		return
	_night_confirmation = true
	_footer_status.add_theme_color_override("font_color", MUTED)
	_show_night()

func _show_night_confirmation(content: VBoxContainer, actor: Dictionary) -> void:
	var message := _panel()
	content.add_child(message)
	var col := _column()
	message.add_child(col)
	var ability: Dictionary = actor.get("ability", {})
	col.add_child(_label("تم تسجيل القدرة بسرية.", 19, SUCCESS))
	col.add_child(_label("أخفِ الشاشة قبل تسليم الهاتف. لا تظهر النتيجة للاعبين الآخرين.", 14, MUTED))
	if str(ability.get("kind", "")) == "reveal":
		col.add_child(_label("سيظهر كشف العراف ضمن نتيجته الخاصة، مع تطبيق قواعد التفاعل والاحتمال.", 13, GOLD))
	var next := _button("إخفاء وتسليم", GOLD, TEXT)
	next.pressed.connect(func():
		_night_confirmation = false
		if session.phase == "day":
			_show_day()
		else:
			_show_night()
	)
	col.add_child(next)

func _show_day() -> void:
	_clear_body()
	var scroll := _scroll()
	var content := _column()
	scroll.add_child(content)
	_body.add_child(scroll)
	content.add_child(_phase_banner("الفجر", "نتائج الليل", Color("#39402D")))
	var results_panel := _panel()
	content.add_child(results_panel)
	var results_col := _column()
	results_panel.add_child(results_col)
	if session.night_results.is_empty():
		results_col.add_child(_label("مرّت الليلة بلا نتائج معلنة.", 17, SUCCESS))
	else:
		for result: Dictionary in session.night_results:
			var line := _label("%s" % result.get("text", ""), 15, TEXT)
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			results_col.add_child(line)
	var alive := _panel()
	content.add_child(alive)
	var alive_col := _column()
	alive.add_child(alive_col)
	alive_col.add_child(_label("حالة الجولة", 18, GOLD))
	alive_col.add_child(_label("الأحياء: %d، الوفيات المسجلة: %d" % [session.alive_players().size(), _dead_count()], 15, MUTED))
	if session.phase == "result":
		var finish := _button("عرض النتيجة", GOLD, TEXT)
		finish.pressed.connect(_show_result)
		content.add_child(finish)
	else:
		var vote := _button("بدء النقاش والتصويت", GOLD, TEXT)
		vote.pressed.connect(func():
			session.begin_vote()
			_show_vote()
		)
		content.add_child(vote)
	_footer_status.text = "سجّل النظام نتائج الليل قبل بدء التصويت."

func _show_vote() -> void:
	_clear_body()
	var scroll := _scroll()
	var content := _column()
	scroll.add_child(content)
	_body.add_child(scroll)
	var voter: Dictionary = session.current_voter()
	content.add_child(_phase_banner("التصويت", "دور %s" % voter.get("name", "اللاعب"), Color("#3A2D43")))
	var instruction := _panel()
	content.add_child(instruction)
	var inst_col := _column()
	instruction.add_child(inst_col)
	inst_col.add_child(_label("اختر اللاعب الذي تريد إخراجه.", 18, TEXT))
	inst_col.add_child(_label("التصويت علني ضمن مرحلة النهار، ولا يمكن للاعب التصويت لنفسه.", 14, MUTED))
	for target: Dictionary in session.alive_players():
		if str(target.get("id", "")) == str(voter.get("id", "")):
			continue
		var button := _button(str(target.get("name", "")), Color("#3A2D43"), TEXT, 54)
		button.pressed.connect(_submit_vote.bind(str(target.get("id", ""))))
		content.add_child(button)
	_footer_status.text = "بعد اكتمال الأصوات تبدأ ليلة جديدة أو تظهر النتيجة."

func _submit_vote(target_id: String) -> void:
	var result: Dictionary = session.submit_vote(target_id)
	if not bool(result.get("ok", false)):
		_footer_status.text = str(result.get("error", "تعذر تسجيل التصويت."))
		_footer_status.add_theme_color_override("font_color", DANGER)
		return
	if bool(result.get("complete", false)):
		if session.phase == "result":
			_show_result()
		else:
			_show_night()
	else:
		_show_vote()

func _show_result() -> void:
	_clear_body()
	var scroll := _scroll()
	var content := _column()
	scroll.add_child(content)
	_body.add_child(scroll)
	content.add_child(_phase_banner("نهاية الجولة", session.winner if not session.winner.is_empty() else "لا فائز بعد", Color("#403424")))
	var result_panel := _panel()
	content.add_child(result_panel)
	var result_col := _column()
	result_panel.add_child(result_col)
	result_col.add_child(_label(session.winner_reason if not session.winner_reason.is_empty() else "انتهت الجولة دون حسم.", 18, TEXT))
	result_col.add_child(_label("الجولة %d، الأحداث المسجلة %d" % [session.round_number, session.events.size()], 14, MUTED))
	result_col.add_child(_label("الأحياء الآن", 16, GOLD))
	for player: Dictionary in session.players:
		var status := "حي" if bool(player.get("alive", false)) else "ميت"
		var status_color := SUCCESS if status == "حي" else DANGER
		result_col.add_child(_label("%s، %s" % [player.get("name", ""), status], 15, status_color))
	var new_game := _button("جولة جديدة", GOLD, TEXT)
	new_game.pressed.connect(_show_setup)
	content.add_child(new_game)
	var home := _button("العودة للرئيسية", Color("#202938"), MUTED, 48)
	home.pressed.connect(_show_home)
	content.add_child(home)
	_footer_status.text = "يمكنك بدء جولة جديدة مع نفس الهاتف."

func _show_organizer() -> void:
	_clear_body()
	var scroll := _scroll()
	var content := _column()
	scroll.add_child(content)
	_body.add_child(scroll)
	content.add_child(_section_title("لوحة المنظّم", "قواعد الشخصيات والبيانات المحلية في مكان واحد."))
	var teams_panel := _panel()
	content.add_child(teams_panel)
	var teams_col := _column(10)
	teams_panel.add_child(teams_col)
	teams_col.add_child(_label("الفرق والأقسام", 18, GOLD))
	for team_id: String in ["villagers", "werewolves", "neutral"]:
		var team := RoleCatalogType.team(team_id)
		var team_label := _label("%s، %s" % [team.get("label", ""), _department_names(team_id)], 15, RoleCatalogType.accent_for_team(team_id))
		team_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		teams_col.add_child(team_label)
	var roles_panel := _panel()
	content.add_child(roles_panel)
	var roles_col := _column(8)
	roles_panel.add_child(roles_col)
	roles_col.add_child(_label("كتالوج الشخصيات والقدرات", 18, GOLD))
	for role_id: String in ROLE_ORDER:
		var role := RoleCatalogType.character(role_id)
		var ability := RoleCatalogType.ability_for_character(role_id)
		var line := _label("%s، %s، %s" % [role.get("name", ""), ability.get("name", ""), role.get("win_condition", "")], 14, TEXT)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		roles_col.add_child(line)
	var backup_panel := _panel()
	content.add_child(backup_panel)
	var backup_col := _column()
	backup_panel.add_child(backup_col)
	backup_col.add_child(_label("النسخ الاحتياطي المحلي", 18, GOLD))
	backup_col.add_child(_label("يُحفظ آخر إعداد وجولة في ملف محلي على الجهاز.", 14, MUTED))
	var backup_buttons := HBoxContainer.new()
	backup_buttons.add_theme_constant_override("separation", 10)
	backup_col.add_child(backup_buttons)
	var export_button := _button("تصدير نسخة", Color("#2B3444"), TEXT, 50)
	export_button.pressed.connect(_export_backup)
	backup_buttons.add_child(export_button)
	var restore_button := _button("استعادة النسخة الأخيرة", Color("#2B3444"), TEXT, 50)
	restore_button.pressed.connect(_restore_backup)
	backup_buttons.add_child(restore_button)
	if not _organizer_status.is_empty():
		backup_col.add_child(_label(_organizer_status, 13, SUCCESS))
	var back := _button("عودة", Color("#202938"), MUTED, 48)
	back.pressed.connect(_show_home)
	content.add_child(back)
	_footer_status.text = "القواعد معرفة كبيانات مستقلة ويمكن توسيعها من الكتالوج."

func _export_backup() -> void:
	var payload: Dictionary = session.backup_payload()
	var file := FileAccess.open("user://nobe-backup.json", FileAccess.WRITE)
	if file == null:
		_organizer_status = "تعذر إنشاء ملف النسخة الاحتياطية."
	else:
		file.store_string(JSON.stringify(payload, "  "))
		file.close()
		_organizer_status = "تم حفظ النسخة في nobe-backup.json على الجهاز."
	_show_organizer()

func _restore_backup() -> void:
	if not FileAccess.file_exists("user://nobe-backup.json"):
		_organizer_status = "لا توجد نسخة محفوظة بعد."
		_show_organizer()
		return
	var file := FileAccess.open("user://nobe-backup.json", FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	if file != null:
		file.close()
	if not parsed is Dictionary:
		_organizer_status = "ملف النسخة غير صالح."
		_show_organizer()
		return
	_organizer_status = "تم العثور على النسخة. الاستعادة الكاملة للجولة متاحة من الإصدار التالي."
	_show_organizer()

func _role_count_row(role_id: String) -> Control:
	var role := RoleCatalogType.character(role_id)
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 55)
	row.add_theme_constant_override("separation", 10)
	var icon := TextureRect.new()
	icon.texture = load(str(role.get("icon", "")))
	icon.custom_minimum_size = Vector2(42, 42)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var label_col := _column(0)
	label_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_col.add_child(_label(str(role.get("name", "")), 16, TEXT))
	label_col.add_child(_label(RoleCatalogType.team_label(str(role.get("team_id", ""))), 12, RoleCatalogType.accent_for_team(str(role.get("team_id", "")))))
	row.add_child(label_col)
	var minus := _button("−", Color("#2B3444"), TEXT, 48)
	minus.pressed.connect(_change_role_count.bind(role_id, -1))
	row.add_child(minus)
	var count := _label(str(_role_counts.get(role_id, 0)), 19, GOLD)
	count.custom_minimum_size = Vector2(32, 48)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(count)
	_count_labels[role_id] = count
	var plus := _button("+", Color("#2B3444"), TEXT, 48)
	plus.pressed.connect(_change_role_count.bind(role_id, 1))
	row.add_child(plus)
	return row

func _change_role_count(role_id: String, delta: int) -> void:
	_role_counts[role_id] = clampi(int(_role_counts.get(role_id, 0)) + delta, 0, 9)
	if _count_labels.has(role_id):
		_count_labels[role_id].text = str(_role_counts[role_id])
	for child: Node in _body.find_children("RoleTotal", "Label", true, false):
		(child as Label).text = "المجموع: %d شخصية" % _selected_role_total()

func _selected_role_total() -> int:
	var total := 0
	for value: Variant in _role_counts.values():
		total += int(value)
	return total

func _review_player_card(player: Dictionary, show_role: bool) -> Control:
	var panel := _panel()
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 10)
	panel.add_child(line)
	var name := _label(str(player.get("name", "")), 17, TEXT)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(name)
	if show_role:
		var role := RoleCatalogType.character(str(player.get("role_id", "villager")))
		line.add_child(_label(str(role.get("name", "")), 15, RoleCatalogType.accent_for_team(str(role.get("team_id", "villagers")))))
	return panel

func _role_card(player: Dictionary, secret: bool) -> Control:
	var role := RoleCatalogType.character(str(player.get("role_id", "villager")))
	var ability := RoleCatalogType.ability_for_character(str(player.get("role_id", "villager")))
	var panel := _panel()
	var col := _column(10)
	panel.add_child(col)
	var icon := TextureRect.new()
	icon.texture = load(str(role.get("icon", "")))
	icon.custom_minimum_size = Vector2(150, 150)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(icon)
	var role_name := _label(str(role.get("name", "")), 28, RoleCatalogType.accent_for_team(str(role.get("team_id", "villagers"))))
	role_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(role_name)
	var team := _label(RoleCatalogType.team_label(str(role.get("team_id", "villagers"))), 14, GOLD)
	team.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(team)
	col.add_child(_label(str(role.get("description", "")), 15, TEXT))
	col.add_child(_label("القدرة: %s" % ability.get("name", ""), 15, GOLD))
	col.add_child(_label("%s" % _ability_rules_text(ability), 13, MUTED))
	col.add_child(_label("الفوز: %s" % role.get("win_condition", ""), 13, SUCCESS))
	col.add_child(_label("الشعار: «%s»" % role.get("slogan", ""), 13, MUTED))
	return panel

func _role_back_art() -> Control:
	var panel := _panel(Color("#0D111A"), Color("#2C384A"))
	var icon := TextureRect.new()
	icon.texture = EMBLEM
	icon.custom_minimum_size = Vector2(150, 150)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(icon)
	return panel

func _ability_instruction(kind: String) -> String:
	match kind:
		"reveal": return "اختر لاعبًا لفحص دوره الحقيقي."
		"protect": return "اختر لاعبًا لحمايته من الهجوم."
		"attack": return "اختر لاعبًا للهجوم عليه."
		"sleep_with": return "اختر لاعبًا للمبيت معه."
	return "لا توجد قدرة ليلية لهذه الشخصية."

func _ability_rules_text(ability: Dictionary) -> String:
	var conditions: Array = ability.get("conditions", [])
	var effects: Array = ability.get("effects", [])
	return "الشروط: %s\nالنتائج: %s" % ["، ".join(conditions), "، ".join(effects)]

func _department_names(team_id: String) -> String:
	var names: Array = []
	for department: Dictionary in RoleCatalogType.DEPARTMENTS:
		if str(department.get("team_id", "")) == team_id:
			names.append(str(department.get("label", "")))
	return "، ".join(names)

func _dead_count() -> int:
	var count := 0
	for player: Dictionary in session.players:
		if not bool(player.get("alive", false)):
			count += 1
	return count

func _section_title(title: String, subtitle: String) -> Control:
	var block := _column(4)
	block.add_child(_label(title, 27, TEXT))
	block.add_child(_label(subtitle, 14, MUTED))
	return block

func _phase_banner(title: String, subtitle: String, color: Color) -> Control:
	var panel := _panel(color, color.lightened(0.18))
	var col := _column(4)
	panel.add_child(col)
	col.add_child(_label(title, 28, TEXT))
	col.add_child(_label(subtitle, 15, GOLD))
	return panel

func _scroll() -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	return scroll

func _column(separation := 12) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", separation)
	return col

func _panel(bg := PANEL, border := Color("#2B3444")) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(bg, border, 1, 14))
	return panel

func _button(text_value: String, color: Color, font_color: Color, height := 58) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", TEXT)
	button.add_theme_stylebox_override("normal", _style(color, color.lightened(0.12), 1, 12))
	button.add_theme_stylebox_override("hover", _style(color.lightened(0.08), GOLD, 2, 12))
	button.add_theme_stylebox_override("pressed", _style(color.darkened(0.10), GOLD, 2, 12))
	button.add_theme_stylebox_override("focus", _style(color, GOLD, 2, 12))
	return button

func _chip(text_value: String) -> Label:
	var chip := _label(text_value, 12, GOLD)
	chip.add_theme_stylebox_override("normal", _style(Color("#1B1C26"), Color("#4C415D"), 1, 9))
	chip.add_theme_constant_override("outline_size", 0)
	return chip

func _label(text_value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

func _spacer(height: float) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	return spacer

func _style(bg: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 14
	box.content_margin_bottom = 14
	return box
