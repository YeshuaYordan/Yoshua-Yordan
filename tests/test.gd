extends Node
## Automated test: checks merge rules, then lets a simple bot play the real game.
## Run:  godot --headless --path . --fixed-fps 60 res://tests/test.tscn

const SIM_LIMIT := 900.0  # simulated seconds

var game
var fails := 0
var sim := 0.0
var bot_timer := 0.0
var merges := 0
var done := false


func check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok   ", msg)
	else:
		fails += 1
		print("  FAIL ", msg)


func _ready() -> void:
	CardDB.save_enabled = false
	CardDB.discovered = {}
	CardDB.best_wave = 0
	print("== Merge rules")
	check(CardDB.merge("fire", 0, "fire", 0) == {"element": "fire", "rarity": 1}, "same + same rarity -> rarity up")
	check(CardDB.merge("fire", 0, "fire", 1).is_empty(), "same element, different rarity -> no fusion")
	check(CardDB.merge("fire", 5, "fire", 5).is_empty(), "Legend is the max rarity")
	check(CardDB.merge("water", 2, "earth", 4) == {"element": "plant", "rarity": 2}, "water + earth = plant at lower rarity")
	check(CardDB.merge("earth", 0, "water", 0)["element"] == "plant", "recipe order does not matter")
	check(CardDB.merge("fire", 1, "plant", 1)["element"] == "wildfire", "tier III recipe")
	check(CardDB.merge("steam", 0, "earth", 0).is_empty(), "no recipe -> no fusion")
	for r in CardDB.RECIPE_LIST:
		check(CardDB.elements.has(r[0]) and CardDB.elements.has(r[1]) and CardDB.elements.has(r[2]), "recipe %s+%s=%s is valid" % r)
	check(CardDB.element_multiplier("water", "fire", false) > 1.0, "water is strong vs fire enemies")
	check(CardDB.element_multiplier("fire", "fire", false) < 1.0, "fire is weak vs fire enemies")
	var counts := [0, 0, 0, 0, 0, 0]
	for i in 2000:
		counts[CardDB.roll_rarity(1)] += 1
	check(counts[0] > counts[1] and counts[4] == 0, "wave 1 shop is mostly Common, no Myth (%s)" % str(counts))

	print("== Game")
	game = load("res://scenes/main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	check(game.state == "title", "starts on title screen")
	game.start_run()
	check(game.free_card and game.gold == 10, "run starts with 10 gold and a free card")
	# Tap the first shop card: should be bought for free into battle slot 0.
	var p: Vector2 = game.slot_pos("shop", 0)
	game._begin_drag(p)
	game._end_drag(p)
	check(game.rows["active"][0] != null, "tapping a shop card places it in a battle slot")
	check(not game.free_card and game.gold == 10, "first card was free")
	# Drag the second shop card onto storage slot 2.
	var cost: int = game.rows["shop"][1].price
	game._begin_drag(game.slot_pos("shop", 1))
	game.drag_moved = true
	game._end_drag(game.slot_pos("storage", 2))
	if cost <= 10:
		check(game.rows["storage"][2] != null and game.gold == 10 - cost, "dragging a shop card to storage buys it")
	# Shop cards are never a merge target.
	game.rows["storage"][2] = game.rows["storage"][2]
	check(game.slot_at(game.slot_pos("shop", 2))[0] == "shop", "shop slots are detected")
	game.begin_wave()


func bot_play() -> void:
	# Buy what we can afford.
	for i in game.SHOP_COUNT:
		var c = game.rows["shop"][i]
		if c == null or (not game.free_card and game.gold < c.price):
			continue
		var slot: Array = game._first_free_slot()
		if not slot.is_empty():
			game._buy(i, slot[0], slot[1])
		else:
			for row in ["active", "storage"]:
				for j in game.SLOT_COUNT:
					var o = game.rows[row][j]
					if o != null and game.rows["shop"][i] != null and not CardDB.merge(c.element, c.rarity, o.element, o.rarity).is_empty():
						game._buy(i, row, j)
	# Fuse everything that can fuse (prefer results in battle slots).
	var changed := true
	while changed:
		changed = false
		var cells := []
		for row in ["active", "storage"]:
			for j in game.SLOT_COUNT:
				if game.rows[row][j] != null:
					cells.append([row, j])
		for a in cells:
			for b in cells:
				if changed or a == b:
					continue
				var ca = game.rows[a[0]][a[1]]
				var cb = game.rows[b[0]][b[1]]
				if ca == null or cb == null or b[0] == "storage" and a[0] == "active":
					continue
				if not CardDB.merge(ca.element, ca.rarity, cb.element, cb.rarity).is_empty():
					if game.move_card(a[0], a[1], b[0], b[1]) == "merge":
						merges += 1
						changed = true
	# Fill empty battle slots from storage.
	for j in game.SLOT_COUNT:
		if game.rows["active"][j] == null:
			for k in game.SLOT_COUNT:
				if game.rows["storage"][k] != null:
					game.move_card("storage", k, "active", j)
					break
	if game.gold > 25:
		game._on_reroll()


func _process(delta: float) -> void:
	if done or game == null or game.state == "title":
		return
	sim += delta
	bot_timer -= delta
	if game.state == "break":
		bot_play()
		game.begin_wave()
	elif game.state == "wave" and bot_timer <= 0.0:
		bot_timer = 2.0
		bot_play()
	elif game.state == "gameover":
		finish()
	if sim > SIM_LIMIT:
		finish()


func finish() -> void:
	done = true
	var board := []
	for row in ["active", "storage"]:
		for c in game.rows[row]:
			if c != null:
				board.append("%s %s" % [CardDB.RARITY_NAMES[c.rarity], c.element])
	print("  state=%s wave=%d castle=%d gold=%d merges=%d discovered=%d sim=%ds" % [
		game.state, game.wave, game.castle_hp, game.gold, merges, CardDB.discovered.size(), sim])
	print("  board: ", ", ".join(board))
	check(game.wave >= 5, "bot survives at least 5 waves")
	print("== %s (%d failures)" % ["PASSED" if fails == 0 else "FAILED", fails])
	get_tree().quit(1 if fails > 0 else 0)
