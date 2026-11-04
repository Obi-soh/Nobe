class_name RoleCatalog
extends RefCounted

const TEAMS := {
	"villagers": {
		"id": "villagers",
		"label": "القرويون",
		"short": "القرية",
		"color": Color("#1f5a49"),
		"accent": Color("#9bd1a9"),
		"icon": "res://assets/generated/villager-crest.png",
	},
	"werewolves": {
		"id": "werewolves",
		"label": "المستذئبون",
		"short": "الذئاب",
		"color": Color("#85283d"),
		"accent": Color("#ef8090"),
		"icon": "res://assets/generated/werewolf-crest.png",
	},
	"neutral": {
		"id": "neutral",
		"label": "المحايدون",
		"short": "محايد",
		"color": Color("#65479b"),
		"accent": Color("#d6b8ff"),
		"icon": "res://assets/generated/neutral-crest.png",
	},
}

const DEPARTMENTS := [
	{"id": "village_people", "team_id": "villagers", "label": "ناس الحلة"},
	{"id": "security", "team_id": "villagers", "label": "القوات الأمنية"},
	{"id": "wolf_pack", "team_id": "werewolves", "label": "قطيع الليل"},
	{"id": "mystics", "team_id": "neutral", "label": "أهل الأسرار"},
]

const CHARACTERS := {
	"villager": {
		"id": "villager",
		"name": "القروي",
		"team_id": "villagers",
		"department_id": "village_people",
		"icon": "res://assets/generated/villager-crest.png",
		"description": "عضو عادي من القرية. قوته في النقاش وملاحظة التناقضات.",
		"slogan": "الحقيقة لا تختبئ إلى الأبد.",
		"ability_id": "none",
		"night_order": 99,
		"win_condition": "تفوز إذا انتصر القرويون وبقيت حيًا.",
		"loss_condition": "تخسر إذا خرجت من اللعبة أو انتصر فريق آخر.",
		"resistances": [],
		"weaknesses": ["الهجوم"],
	},
	"seer": {
		"id": "seer",
		"name": "العراف",
		"team_id": "villagers",
		"department_id": "mystics",
		"icon": "res://assets/generated/villager-crest.png",
		"description": "يفحص لاعبًا كل ليلة ويعرف دوره الحقيقي.",
		"slogan": "انظر خلف القناع.",
		"ability_id": "seer_reveal",
		"night_order": 10,
		"win_condition": "تفوز مع القرويين إذا بقيت حيًا حتى انتصارهم.",
		"loss_condition": "تخسر إذا مت قبل حسم الجولة.",
		"resistances": [],
		"weaknesses": ["الذئاب"],
	},
	"guard": {
		"id": "guard",
		"name": "الحارس",
		"team_id": "villagers",
		"department_id": "security",
		"icon": "res://assets/generated/villager-crest.png",
		"description": "يحمي لاعبًا واحدًا كل ليلة من الهجوم.",
		"slogan": "ليس الليلة.",
		"ability_id": "protect",
		"night_order": 20,
		"win_condition": "تفوز مع القرويين.",
		"loss_condition": "تخسر إذا مت أو خسر القرويون.",
		"resistances": ["هجوم واحد أثناء الحماية"],
		"weaknesses": ["التسميم"],
	},
	"werewolf": {
		"id": "werewolf",
		"name": "المستذئب",
		"team_id": "werewolves",
		"department_id": "wolf_pack",
		"icon": "res://assets/generated/werewolf-crest.png",
		"description": "يختار مع القطيع ضحية للهجوم في كل ليلة.",
		"slogan": "حين يكتمل القمر، لا أحد ينام آمنًا.",
		"ability_id": "attack",
		"night_order": 40,
		"win_condition": "يفوز الذئاب عند مساواة عددهم بعدد بقية الأحياء.",
		"loss_condition": "يخسر إذا تم القضاء على جميع الذئاب.",
		"resistances": [],
		"weaknesses": ["كشف العراف"],
	},
	"seductress": {
		"id": "seductress",
		"name": "الرءّاصة",
		"team_id": "neutral",
		"department_id": "mystics",
		"icon": "res://assets/generated/neutral-crest.png",
		"description": "تختار لاعبًا لتنام معه. لا تُكشف زيارتها دائمًا للعراف.",
		"slogan": "ليلة واحدة تغيّر كل شيء.",
		"ability_id": "sleep_with",
		"night_order": 30,
		"win_condition": "تفوز إذا بقيت حيًا عند انتصار أي فريق.",
		"loss_condition": "تخسر إذا مت قبل نهاية الجولة.",
		"resistances": [],
		"weaknesses": ["التصويت", "الهجوم"],
	},
	"survivor": {
		"id": "survivor",
		"name": "الناجي",
		"team_id": "neutral",
		"department_id": "mystics",
		"icon": "res://assets/generated/neutral-crest.png",
		"description": "لا يهمه الفائز؛ هدفه الوحيد أن يبقى حيًا.",
		"slogan": "ابقَ حتى النهاية.",
		"ability_id": "none",
		"night_order": 99,
		"win_condition": "يفوز إذا بقي حيًا عند انتصار أي فريق.",
		"loss_condition": "يخسر إذا مات.",
		"resistances": [],
		"weaknesses": ["الهجوم", "التصويت"],
	},
}

const ABILITIES := {
	"none": {
		"id": "none",
		"name": "لا قدرة ليلية",
		"kind": "skip",
		"uses": -1,
		"cooldown": 0,
		"conditions": [],
		"effects": [],
	},
	"seer_reveal": {
		"id": "seer_reveal",
		"name": "كشف الهوية",
		"kind": "reveal",
		"uses": -1,
		"cooldown": 0,
		"conditions": ["اللاعب حي", "لا يمكن اختيار النفس"],
		"effects": ["كشف الدور الحقيقي", "تطبيق تفاعل الرءّاصة باحتمال 25%"],
	},
	"protect": {
		"id": "protect",
		"name": "حماية",
		"kind": "protect",
		"uses": -1,
		"cooldown": 0,
		"conditions": ["اللاعب حي", "لا يمكن حماية النفس"],
		"effects": ["إلغاء هجوم واحد على الهدف"],
	},
	"attack": {
		"id": "attack",
		"name": "هجوم القطيع",
		"kind": "attack",
		"uses": -1,
		"cooldown": 0,
		"conditions": ["اللاعب حي", "لا يمكن مهاجمة ذئب آخر"],
		"effects": ["إصابة الهدف ما لم توجد حماية أو مقاومة"],
	},
	"sleep_with": {
		"id": "sleep_with",
		"name": "مبيت",
		"kind": "sleep_with",
		"uses": -1,
		"cooldown": 0,
		"conditions": ["اللاعب حي", "لا يمكن اختيار النفس"],
		"effects": ["تسجيل الزيارة", "احتمال كشف الزيارة للعراف 25%"],
	},
}

const DEFAULT_ROLE_COUNTS := {
	"villager": 2,
	"seer": 1,
	"guard": 1,
	"werewolf": 1,
	"seductress": 0,
	"survivor": 0,
}

static func team(team_id: String) -> Dictionary:
	return TEAMS.get(team_id, {}).duplicate(true)

static func character(character_id: String) -> Dictionary:
	return CHARACTERS.get(character_id, {}).duplicate(true)

static func ability_for_character(character_id: String) -> Dictionary:
	var role := character(character_id)
	return ABILITIES.get(str(role.get("ability_id", "none")), {}).duplicate(true)

static func all_characters() -> Array:
	var result: Array = []
	for character_id: String in CHARACTERS:
		result.append(character(character_id))
	return result

static func selected_role_ids(counts: Dictionary) -> Array:
	var result: Array = []
	for character_id: String in CHARACTERS:
		var amount := maxi(0, int(counts.get(character_id, 0)))
		for _i in amount:
			result.append(character_id)
	return result

static func team_label(team_id: String) -> String:
	return str(TEAMS.get(team_id, {}).get("label", team_id))

static func color_for_team(team_id: String) -> Color:
	return TEAMS.get(team_id, {}).get("color", Color("#343B4A"))

static func accent_for_team(team_id: String) -> Color:
	return TEAMS.get(team_id, {}).get("accent", Color("#E8E1D1"))
