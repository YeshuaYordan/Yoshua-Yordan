extends Node2D
## Arcane Fusion: Merge & Defend - main game controller.
## Handles the board (battle / storage / shop slots), drag & merge, waves, gold and UI.

const DU = preload("res://scripts/draw_util.gd")
const CardScript = preload("res://scripts/card.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const ProjectileScript = preload("res://scripts/projectile.gd")
const ZoneScript = preload("res://scripts/zone.gd")
const FxScript = preload("res://scripts/fx.gd")
const VintageShader = preload("res://shaders/vintage.gdshader")

const W := 720.0
const H := 1280.0
const HUD_H := 72.0
const WALL_Y := 690.0
const WALL_H := 62.0
const ACTIVE_Y := 836.0
const STORAGE_Y := 1000.0
const SHOP_Y := 1160.0
const SHOP_TOP := 1080.0
const SLOT_COUNT := 5
const SHOP_COUNT := 3
const CASTLE_MAX_HP := 100.0
const BREAK_TIME := 15.0
const START_GOLD := 10
const REROLL_BASE := 2
const SELL_RECT := Rect2(0, SHOP_TOP, 430, H - SHOP_TOP)

const INK := Color("#2a1a12")
const PARCHMENT := Color("#f3e3c3")
const GOLD_COL := Color("#f2c14e")

var rows := {"active": [], "storage": [], "shop": []}
var enemies: Array = []
var gold := 0
var castle_hp := CASTLE_MAX_HP
var wave := 0
var state := "title"  # title | break | wave | gameover
var break_timer := -1.0
var to_spawn := 0
var spawn_timer := 0.0
var boss_pending := false
var reroll_cost := REROLL_BASE
var free_card := true
var time := 0.0
var wall_flash := 0.0

# Dragging
var drag_card = null
var drag_from := ""
var drag_index := -1
var drag_offset := Vector2.ZERO
var press_pos := Vector2.ZERO
var drag_moved := false
var hover_slot := []

# Layers
var ground_layer: Node2D
var enemy_layer: Node2D
var card_layer: Node2D
var fx_layer: Node2D

# UI
var ui: CanvasLayer
var wave_label: Label
var gold_label: Label
var info_label: Label
var banner_label: Label
var start_btn: Button
var reroll_btn: Button
var book_btn: Button
var pause_btn: Button
var title_panel: Control
var pause_panel: Control
var over_panel: Control
var book_panel: Control
var book_text: RichTextLabel
var over_label: Label
var best_label: Label
var _info_tween: Tween

var _stars: Array = []
var _tufts: Array = []


func _ready() -> void:
	randomize()
	rows["active"].resize(SLOT_COUNT)
	rows["storage"].resize(SLOT_COUNT)
	rows["shop"].resize(SHOP_COUNT)
	for i in 60:
		_stars.append(Vector3(randf() * W, HUD_H + randf() * 240.0, randf()))
	for i in 40:
		_tufts.append(Vector2(randf() * W, 360.0 + randf() * (WALL_Y - 380.0)))

	ground_layer = Node2D.new()
	enemy_layer = Node2D.new()
	card_layer = Node2D.new()
	fx_layer = Node2D.new()
	for l in [ground_layer, enemy_layer, card_layer, fx_layer]:
		add_child(l)
	_build_ui()
	_show_title()


# ---------------------------------------------------------------- Run flow

func start_run() -> void:
	_clear_board()
	gold = START_GOLD
	castle_hp = CASTLE_MAX_HP
	wave = 0
	free_card = true
	reroll_cost = REROLL_BASE
	state = "break"
	break_timer = -1.0
	refresh_shop()
	title_panel.hide()
	over_panel.hide()
	pause_panel.hide()
	get_tree().paused = false
	banner("Your first card is FREE!", GOLD_COL)
	show_info("Tap or drag a shop card onto a slot. Only the top row of slots attacks.")


func begin_wave() -> void:
	wave += 1
	state = "wave"
	break_timer = -1.0
	to_spawn = mini(6 + wave * 2, 70)
	spawn_timer = 0.6
	boss_pending = wave % 10 == 0
	reroll_cost = REROLL_BASE
	if boss_pending:
		banner("Wave %d - BOSS!" % wave, Color("#e0533f"))
	else:
		banner("Wave %d" % wave, PARCHMENT)


func end_wave() -> void:
	state = "break"
	var bonus := 4 + wave
	gold += bonus
	break_timer = BREAK_TIME
	if wave > CardDB.best_wave:
		CardDB.best_wave = wave
		CardDB.save()
	refresh_shop()
	banner("Wave %d cleared!  +%d gold" % [wave, bonus], GOLD_COL)


func game_over() -> void:
	state = "gameover"
	_cancel_drag()
	if wave - 1 > CardDB.best_wave:
		CardDB.best_wave = wave - 1
	CardDB.save()
	over_label.text = "You held out for %d wave%s." % [wave - 1, "" if wave - 1 == 1 else "s"]
	best_label.text = "Best: %d" % CardDB.best_wave
	over_panel.show()


func _clear_board() -> void:
	for row in rows:
		for i in rows[row].size():
			if rows[row][i] != null:
				rows[row][i].queue_free()
				rows[row][i] = null
	for e in enemies:
		e.queue_free()
	enemies.clear()
	for l in [ground_layer, fx_layer]:
		for c in l.get_children():
			c.queue_free()
	drag_card = null


# ---------------------------------------------------------------- Main loop

func _process(delta: float) -> void:
	time += delta
	wall_flash = maxf(0.0, wall_flash - delta * 3.0)
	if state == "wave":
		_update_spawning(delta)
		if to_spawn <= 0 and not boss_pending and enemies.is_empty():
			end_wave()
	elif state == "break" and break_timer > 0.0:
		break_timer -= delta
		if break_timer <= 0.0:
			begin_wave()

	if state == "wave":
		for c in rows["active"]:
			if c == null or c == drag_card:
				continue
			c.cooldown -= delta
			if c.cooldown <= 0.0 and not enemies.is_empty():
				fire_card(c)
				c.cooldown = 1.0 / CardDB.rate(c.element, c.rarity)
	_update_hud()
	queue_redraw()


func _update_spawning(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer > 0.0:
		return
	spawn_timer = maxf(0.28, 1.2 - wave * 0.035)
	if boss_pending and to_spawn <= mini(6 + wave * 2, 70) / 2:
		boss_pending = false
		spawn_enemy("boss")
		return
	if to_spawn > 0:
		to_spawn -= 1
		spawn_enemy(_pick_kind())


func _pick_kind() -> String:
	var pool := [["grunt", 10.0]]
	if wave >= 2:
		pool.append(["runner", 4.0 + wave * 0.5])
	if wave >= 4:
		pool.append(["tank", 2.0 + wave * 0.3])
	if wave >= 6:
		pool.append(["flyer", 3.0 + wave * 0.3])
	var total := 0.0
	for p in pool:
		total += p[1]
	var pick := randf() * total
	for p in pool:
		pick -= p[1]
		if pick <= 0.0:
			return p[0]
	return "grunt"


func spawn_enemy(kind: String) -> void:
	var e = EnemyScript.new()
	e.position = Vector2(randf_range(50.0, W - 50.0), HUD_H + 20.0)
	var res := ""
	if kind != "boss" and wave >= 8 and randf() < minf(0.5, (wave - 7) * 0.05):
		res = CardDB.random_base()
	e.setup(self, kind, wave, res, WALL_Y)
	enemy_layer.add_child(e)
	enemies.append(e)


func damage_castle(amount: float) -> void:
	if state != "wave":
		return
	castle_hp -= amount
	wall_flash = 1.0
	if castle_hp <= 0.0:
		castle_hp = 0.0
		game_over()


func on_enemy_killed(e) -> void:
	enemies.erase(e)
	gold += e.gold
	_fx_text(e.position + Vector2(0, -20), "+%d" % e.gold, GOLD_COL, 22)
	_fx_burst(e.position, e.color.lightened(0.3), e.size * 1.6)
	e.queue_free()


# ---------------------------------------------------------------- Combat

func _closest_enemies(count: int) -> Array:
	var list := enemies.filter(func(e): return not e.dead)
	list.sort_custom(func(a, b): return a.position.y > b.position.y)
	return list.slice(0, count)


func fire_card(card) -> void:
	var d: Dictionary = CardDB.elements[card.element]
	var shots: int = d.get("multishot", 1)
	var targets := _closest_enemies(shots)
	if targets.is_empty():
		return
	card.kick()
	var origin: Vector2 = card.position + Vector2(0, -60)
	if d.has("chain"):
		_chain(card.element, card.rarity, origin, targets[0], d["chain"])
		return
	for i in shots:
		var p = ProjectileScript.new()
		p.setup(self, card.element, card.rarity, origin + Vector2((i - (shots - 1) / 2.0) * 14.0, 0), targets[i % targets.size()])
		fx_layer.add_child(p)


func _chain(el: String, r: int, origin: Vector2, first, count: int) -> void:
	var d: Dictionary = CardDB.elements[el]
	var dmg := CardDB.damage(el, r)
	var hit := []
	var pts := PackedVector2Array([origin])
	var cur = first
	for i in count:
		if cur == null:
			break
		hit.append(cur)
		pts.append(cur.position)
		hit_enemy(cur, el, r, dmg * pow(0.85, i))
		var best = null
		var best_d := 190.0
		for e in enemies:
			if hit.has(e) or e.dead:
				continue
			var dist: float = e.position.distance_to(pts[pts.size() - 1])
			if dist < best_d:
				best_d = dist
				best = e
		cur = best
	var fx = FxScript.new()
	fx.mode = "bolt"
	fx.points = pts
	fx.color = d["color"]
	fx.duration = 0.18
	fx_layer.add_child(fx)


## Called when a projectile lands.
func apply_hit(el: String, r: int, pos: Vector2, enemy) -> void:
	var d: Dictionary = CardDB.elements[el]
	var dmg := CardDB.damage(el, r)
	var splash: float = d.get("splash", 0.0)
	if splash > 0.0:
		for e in enemies.duplicate():
			if not e.dead and e.position.distance_to(pos) <= splash + e.size:
				hit_enemy(e, el, r, dmg if e == enemy else dmg * 0.6)
		_fx_burst(pos, d["color"], splash)
	elif enemy != null and is_instance_valid(enemy) and not enemy.dead:
		hit_enemy(enemy, el, r, dmg)
		_fx_burst(pos, d["color"], 22.0)
	var rm: float = CardDB.RARITY_DMG[r]
	if d.has("cloud"):
		_zone(pos, d["cloud"], d["cloud_dps"] * rm, 2.5, d["color"])
	if d.has("puddle"):
		var z = _zone(pos, d["puddle"], d["puddle_dps"] * rm, 3.0, d["color"])
		z.burn = 2.0 * rm


func hit_enemy(e, el: String, r: int, dmg: float) -> void:
	var d: Dictionary = CardDB.elements[el]
	var mult := CardDB.element_multiplier(el, e.resist, e.flying)
	var amount := dmg * mult
	var pos: Vector2 = e.position
	var rm: float = CardDB.RARITY_DMG[r]
	if d.has("burn"):
		e.apply_burn(d["burn"] * rm, 2.5)
	if d.has("slow"):
		e.apply_slow(d["slow"], 2.0)
	if d.has("root"):
		e.apply_root(d["root"])
	if d.has("knock"):
		e.knockback(d["knock"])
	e.take_damage(amount)
	var col := PARCHMENT
	if mult > 1.01:
		col = Color("#ffe34a")
	elif mult < 0.99:
		col = Color("#a89878")
	_fx_text(pos + Vector2(randf_range(-14, 14), -30), str(roundi(amount)), col, 18)


func _zone(pos: Vector2, radius: float, dps: float, dur: float, col: Color):
	var z = ZoneScript.new()
	z.setup(self, pos, radius, dps, dur, col)
	ground_layer.add_child(z)
	return z


func _fx_burst(pos: Vector2, col: Color, radius: float) -> void:
	var fx = FxScript.new()
	fx.mode = "burst"
	fx.position = pos
	fx.color = col
	fx.radius = radius
	fx.duration = 0.35
	fx_layer.add_child(fx)


func _fx_text(pos: Vector2, s: String, col: Color, size: int) -> void:
	var fx = FxScript.new()
	fx.mode = "text"
	fx.position = pos
	fx.text = s
	fx.color = col
	fx.font_size = size
	fx.duration = 0.8
	fx_layer.add_child(fx)


# ---------------------------------------------------------------- Shop

func refresh_shop() -> void:
	for i in SHOP_COUNT:
		if rows["shop"][i] != null:
			rows["shop"][i].queue_free()
		var c = CardScript.new()
		c.setup(CardDB.random_base(), CardDB.roll_rarity(maxi(1, wave + 1)))
		c.in_shop = true
		c.price = CardDB.price(c.element, c.rarity)
		c.set_home(slot_pos("shop", i), true)
		c.position.y += 200.0  # slides up into place
		card_layer.add_child(c)
		rows["shop"][i] = c
	_update_shop_tags()


func _update_shop_tags() -> void:
	for c in rows["shop"]:
		if c != null:
			c.is_free = free_card
			c.affordable = free_card or gold >= c.price


func _on_reroll() -> void:
	if state != "break" and state != "wave":
		return
	if gold < reroll_cost:
		show_info("Not enough gold to reroll.")
		reroll_btn.release_focus()
		return
	gold -= reroll_cost
	reroll_cost += 1
	refresh_shop()


func _buy(shop_i: int, row: String, i: int) -> bool:
	var card = rows["shop"][shop_i]
	if card == null:
		return false
	var cost: int = 0 if free_card else card.price
	if gold < cost:
		show_info("Not enough gold! This card costs %d." % cost)
		card.shake()
		return false
	var other = rows[row][i]
	if other == null:
		rows["shop"][shop_i] = null
		rows[row][i] = card
		card.in_shop = false
		card.set_home(slot_pos(row, i))
	else:
		var res := CardDB.merge(card.element, card.rarity, other.element, other.rarity)
		if res.is_empty():
			show_info("%s can't fuse with %s." % [_card_name(card), _card_name(other)])
			card.shake()
			return false
		rows["shop"][shop_i] = null
		card.queue_free()
		_apply_merge(other, res)
	gold -= cost
	free_card = false
	return true


func _sell(row: String, i: int) -> void:
	var card = rows[row][i]
	var value := CardDB.sell_value(card.element, card.rarity)
	gold += value
	rows[row][i] = null
	_fx_text(card.position, "+%d g" % value, GOLD_COL, 24)
	card.queue_free()


func _first_free_slot() -> Array:
	for row in ["active", "storage"]:
		for i in SLOT_COUNT:
			if rows[row][i] == null:
				return [row, i]
	return []


# ---------------------------------------------------------------- Board & merging

func slot_pos(row: String, i: int) -> Vector2:
	match row:
		"active":
			return Vector2(72.0 + i * 144.0, ACTIVE_Y)
		"storage":
			return Vector2(72.0 + i * 144.0, STORAGE_Y)
	return Vector2(80.0 + i * 130.0, SHOP_Y)


func slot_at(p: Vector2) -> Array:
	for row in rows:
		for i in rows[row].size():
			var r := Rect2(slot_pos(row, i) - CardScript.SIZE / 2.0, CardScript.SIZE).grow(10.0)
			if r.has_point(p):
				return [row, i]
	return []


func _apply_merge(card, res: Dictionary) -> void:
	var old_tier: int = CardDB.elements[card.element]["tier"]
	card.set_card(res["element"], res["rarity"])
	card.cooldown = 0.3
	card.pop()
	var col: Color = CardDB.elements[res["element"]]["color"]
	_fx_burst(card.position, col, 90.0)
	_fx_burst(card.position, GOLD_COL, 60.0)
	var el_name: String = CardDB.elements[res["element"]]["name"]
	if CardDB.elements[res["element"]]["tier"] > 1 and CardDB.discover(res["element"]):
		banner("FUSION!  %s discovered!" % el_name, col.lightened(0.2))
		_refresh_book()
	elif CardDB.elements[res["element"]]["tier"] != old_tier or res["element"] != card.element:
		_fx_text(card.position + Vector2(0, -80), "Fusion!", col.lightened(0.3), 26)
	else:
		_fx_text(card.position + Vector2(0, -80), "%s!" % CardDB.RARITY_NAMES[res["rarity"]], CardDB.RARITY_COLORS[res["rarity"]], 26)
	show_info(CardDB.describe(card.element, card.rarity))


func _card_name(c) -> String:
	return "%s %s" % [CardDB.RARITY_NAMES[c.rarity], CardDB.elements[c.element]["name"]]


func _unhandled_input(event: InputEvent) -> void:
	if state != "wave" and state != "break":
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var p := get_global_mouse_position()
		if event.pressed:
			_begin_drag(p)
		else:
			_end_drag(p)
	elif event is InputEventMouseMotion and drag_card != null:
		var p := get_global_mouse_position()
		drag_card.position = p + drag_offset
		if p.distance_to(press_pos) > 12.0:
			drag_moved = true
		hover_slot = slot_at(p)


func _begin_drag(p: Vector2) -> void:
	var s := slot_at(p)
	if s.is_empty() or rows[s[0]][s[1]] == null:
		return
	drag_card = rows[s[0]][s[1]]
	drag_from = s[0]
	drag_index = s[1]
	drag_offset = drag_card.position - p
	press_pos = p
	drag_moved = false
	drag_card.dragging = true
	drag_card.z_index = 50
	show_info(CardDB.describe(drag_card.element, drag_card.rarity))


func _cancel_drag() -> void:
	if drag_card != null and is_instance_valid(drag_card):
		drag_card.dragging = false
		drag_card.z_index = 0
	drag_card = null
	hover_slot = []


func _end_drag(p: Vector2) -> void:
	if drag_card == null:
		return
	var card = drag_card
	_cancel_drag()

	if not drag_moved:
		# A tap. Shop cards are bought into the first free slot.
		if drag_from == "shop":
			var slot := _first_free_slot()
			if slot.is_empty():
				show_info("No free slot! Drag it onto a matching card to fuse it.")
				card.shake()
			else:
				_buy(drag_index, slot[0], slot[1])
		return

	var target := slot_at(p)
	if drag_from == "shop":
		if target.is_empty() or target[0] == "shop":
			return
		_buy(drag_index, target[0], target[1])
		return

	if target.is_empty() or target[0] == "shop":
		if SELL_RECT.has_point(p):
			_sell(drag_from, drag_index)
		return
	move_card(drag_from, drag_index, target[0], target[1])


## Moves a board card onto another slot: places it, fuses it, or swaps the two.
## Returns "move", "merge", "swap" or "" (nothing happened).
func move_card(from_row: String, from_i: int, to_row: String, to_i: int) -> String:
	if from_row == to_row and from_i == to_i:
		return ""
	var card = rows[from_row][from_i]
	var other = rows[to_row][to_i]
	if card == null:
		return ""
	if other == null:
		rows[from_row][from_i] = null
		rows[to_row][to_i] = card
		card.set_home(slot_pos(to_row, to_i))
		return "move"
	var res := CardDB.merge(card.element, card.rarity, other.element, other.rarity)
	if not res.is_empty():
		rows[from_row][from_i] = null
		card.queue_free()
		_apply_merge(other, res)
		return "merge"
	# No recipe: swap the two cards.
	rows[from_row][from_i] = other
	rows[to_row][to_i] = card
	other.set_home(slot_pos(from_row, from_i))
	card.set_home(slot_pos(to_row, to_i))
	return "swap"


# ---------------------------------------------------------------- Drawing

func _draw() -> void:
	# Twilight sky.
	var bands := 32
	for i in bands:
		var k := float(i) / bands
		var col := Color("#231736").lerp(Color("#6b3f62"), k)
		draw_rect(Rect2(0, HUD_H + k * 300.0, W, 300.0 / bands + 1.0), col)
	for s in _stars:
		var tw := 0.5 + 0.5 * sin(time * 2.0 + s.z * 20.0)
		draw_circle(Vector2(s.x, s.y), 1.0 + s.z * 1.2, Color(1, 0.95, 0.8, 0.3 + 0.5 * tw * s.z))
	# Moon.
	draw_circle(Vector2(600, 150), 46, Color("#f6e4bd", 0.15))
	draw_circle(Vector2(600, 150), 34, Color("#f6e4bd"))
	draw_circle(Vector2(588, 140), 7, Color("#e3cc9c"))
	draw_circle(Vector2(612, 162), 5, Color("#e3cc9c"))
	# Distant mountains.
	var mtn := PackedVector2Array([Vector2(0, 372)])
	for i in 13:
		mtn.append(Vector2(i * 60.0, 300.0 + (40.0 if i % 2 == 0 else -10.0) + sin(i * 1.7) * 18.0))
	mtn.append_array([Vector2(W, 300), Vector2(W, 372)])
	draw_colored_polygon(mtn, Color("#3a2546"))
	# Battlefield ground.
	for i in 20:
		var k := float(i) / 20.0
		var y := 370.0 + k * (WALL_Y - 370.0)
		draw_rect(Rect2(0, y, W, (WALL_Y - 370.0) / 20.0 + 1.0), Color("#2c3a3a").lerp(Color("#3d4a36"), k))
	for t in _tufts:
		draw_line(t, t + Vector2(-4, -9), Color("#55684a"), 2.0)
		draw_line(t, t + Vector2(3, -11), Color("#55684a"), 2.0)

	# Castle courtyard.
	draw_rect(Rect2(0, WALL_Y, W, SHOP_TOP - WALL_Y), Color("#3b2f3a"))
	for y in range(int(WALL_Y + WALL_H) + 20, int(SHOP_TOP), 44):
		draw_line(Vector2(0, y), Vector2(W, y), Color(0, 0, 0, 0.12), 2.0)

	# Castle wall with battlements.
	var wall_col := Color("#7d6f66").lerp(Color("#c4493e"), wall_flash * 0.5)
	for i in 10:
		var mx := i * 76.0 + 6.0
		draw_rect(Rect2(mx, WALL_Y - 20, 48, 24), wall_col)
		draw_rect(Rect2(mx, WALL_Y - 20, 48, 24), INK, false, 3.0)
	draw_rect(Rect2(0, WALL_Y, W, WALL_H), wall_col)
	for r in 3:
		var y := WALL_Y + r * (WALL_H / 3.0)
		draw_line(Vector2(0, y), Vector2(W, y), Color(INK, 0.5), 2.0)
		var shift := 0.0 if r % 2 == 0 else 30.0
		for x in range(0, int(W) + 60, 60):
			draw_line(Vector2(x + shift, y), Vector2(x + shift, y + WALL_H / 3.0), Color(INK, 0.5), 2.0)
	draw_line(Vector2(0, WALL_Y), Vector2(W, WALL_Y), INK, 3.0)
	draw_line(Vector2(0, WALL_Y + WALL_H), Vector2(W, WALL_Y + WALL_H), INK, 3.0)

	# Castle HP bar.
	var hb := Rect2(160, WALL_Y + 16, 400, 30)
	draw_rect(hb.grow(3), INK)
	draw_rect(hb, Color("#4a2a2a"))
	draw_rect(Rect2(hb.position, Vector2(hb.size.x * castle_hp / CASTLE_MAX_HP, hb.size.y)), Color("#e0533f").lerp(Color("#6cc56a"), castle_hp / CASTLE_MAX_HP))
	DU.text(self, hb.get_center() + Vector2(0, 8), "Castle  %d / %d" % [ceili(castle_hp), CASTLE_MAX_HP], 20, PARCHMENT, 400.0, 5)

	# Rune circles under battle slots.
	for i in SLOT_COUNT:
		var p := slot_pos("active", i)
		var c = rows["active"][i]
		var col: Color = GOLD_COL if c == null else CardDB.elements[c.element]["color"]
		var pulse := 0.5 + 0.5 * sin(time * 2.5 + i)
		draw_set_transform(p + Vector2(0, 58), 0.0, Vector2(1.0, 0.32))
		draw_circle(Vector2.ZERO, 66, Color(col, 0.12 + 0.1 * pulse))
		draw_arc(Vector2.ZERO, 62, 0, TAU, 40, Color(col, 0.55 + 0.3 * pulse), 4.0, true)
		draw_arc(Vector2.ZERO, 48, time, time + TAU * 0.8, 30, Color(col, 0.4), 3.0, true)
		draw_set_transform(Vector2.ZERO)
		_slot_frame(p, Color(GOLD_COL, 0.35))

	# Storage shelf.
	for i in SLOT_COUNT:
		_slot_frame(slot_pos("storage", i), Color(PARCHMENT, 0.25))

	# Shop table.
	draw_rect(Rect2(0, SHOP_TOP, W, H - SHOP_TOP), Color("#5a3b28"))
	for y in range(int(SHOP_TOP) + 30, int(H), 34):
		draw_line(Vector2(0, y), Vector2(W, y + 4), Color(0, 0, 0, 0.15), 2.0)
	draw_rect(Rect2(0, SHOP_TOP, W, 8), Color("#8a5f3c"))
	draw_line(Vector2(0, SHOP_TOP), Vector2(W, SHOP_TOP), INK, 3.0)
	for i in SHOP_COUNT:
		_slot_frame(slot_pos("shop", i), Color(GOLD_COL, 0.3))

	# Drag hints.
	if drag_card != null:
		if drag_from != "shop" and SELL_RECT.has_point(get_global_mouse_position()) and (hover_slot.is_empty() or hover_slot[0] == "shop"):
			draw_rect(SELL_RECT, Color(GOLD_COL, 0.15))
			DU.text(self, Vector2(SELL_RECT.get_center().x, SHOP_TOP + 36), "Drop to sell  +%d g" % CardDB.sell_value(drag_card.element, drag_card.rarity), 22, GOLD_COL, 400.0, 5)
		elif not hover_slot.is_empty() and hover_slot[0] != "shop":
			var hp := slot_pos(hover_slot[0], hover_slot[1])
			var other = rows[hover_slot[0]][hover_slot[1]]
			var ok := other == null or not CardDB.merge(drag_card.element, drag_card.rarity, other.element, other.rarity).is_empty()
			var hc := Color("#6cc56a") if ok else Color("#e0533f")
			draw_rect(Rect2(hp - CardScript.SIZE / 2.0, CardScript.SIZE).grow(8), Color(hc, 0.9), false, 4.0)

	# Top HUD bar.
	draw_rect(Rect2(0, 0, W, HUD_H), Color("#1a1022", 0.92))
	draw_line(Vector2(0, HUD_H), Vector2(W, HUD_H), GOLD_COL.darkened(0.3), 3.0)
	if state == "title":
		return
	draw_circle(Vector2(262, 36), 15, GOLD_COL)
	draw_arc(Vector2(262, 36), 15, 0, TAU, 20, INK, 3.0, true)
	draw_arc(Vector2(262, 36), 9, 0, TAU, 16, Color(INK, 0.5), 2.0, true)


func _slot_frame(p: Vector2, col: Color) -> void:
	var r := Rect2(p - CardScript.SIZE / 2.0, CardScript.SIZE)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.18)
	sb.set_corner_radius_all(12)
	sb.set_border_width_all(2)
	sb.border_color = col
	draw_style_box(sb, r)


# ---------------------------------------------------------------- UI

func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 5
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui)
	var root := Control.new()
	root.size = Vector2(W, H)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = _make_theme()
	ui.add_child(root)

	wave_label = _label(root, Vector2(16, 14), Vector2(220, 44), 30)
	gold_label = _label(root, Vector2(284, 14), Vector2(160, 44), 30)
	gold_label.add_theme_color_override("font_color", GOLD_COL)
	book_btn = _button(root, "Book", Vector2(466, 9), Vector2(120, 54), _open_book)
	pause_btn = _button(root, "II", Vector2(600, 9), Vector2(106, 54), _pause)
	start_btn = _button(root, "Start Wave", Vector2(160, 430), Vector2(400, 86), begin_wave)
	start_btn.add_theme_font_size_override("font_size", 32)
	reroll_btn = _button(root, "Reroll", Vector2(450, 1104), Vector2(250, 112), _on_reroll)
	reroll_btn.add_theme_font_size_override("font_size", 28)

	info_label = _label(root, Vector2(10, 612), Vector2(700, 56), 20)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner_label = _label(root, Vector2(0, 300), Vector2(W, 80), 44)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.pivot_offset = Vector2(W / 2.0, 40)
	banner_label.modulate.a = 0.0

	# Title screen.
	title_panel = _overlay(root, 0.55)
	var tv := _vbox(title_panel, 250)
	var t1 := _label(tv, Vector2.ZERO, Vector2(600, 90), 72)
	t1.text = "ARCANE FUSION"
	t1.add_theme_color_override("font_color", GOLD_COL)
	t1.add_theme_constant_override("outline_size", 14)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var t2 := _label(tv, Vector2.ZERO, Vector2(600, 50), 36)
	t2.text = "~ Merge & Defend ~"
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_spacer(tv, 60)
	_button(tv, "Play", Vector2.ZERO, Vector2(360, 90), start_run).add_theme_font_size_override("font_size", 38)
	_spacer(tv, 10)
	_button(tv, "Spellbook", Vector2.ZERO, Vector2(360, 76), _open_book)
	_spacer(tv, 30)
	var tb := _label(tv, Vector2.ZERO, Vector2(600, 40), 24)
	tb.name = "BestLabel"
	tb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Pause screen.
	pause_panel = _overlay(root, 0.6)
	var pv := _vbox(pause_panel, 420)
	var pt := _label(pv, Vector2.ZERO, Vector2(600, 80), 56)
	pt.text = "Paused"
	pt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_spacer(pv, 30)
	_button(pv, "Resume", Vector2.ZERO, Vector2(360, 80), _resume)
	_spacer(pv, 10)
	_button(pv, "Spellbook", Vector2.ZERO, Vector2(360, 80), _open_book)
	_spacer(pv, 10)
	_button(pv, "Quit to Title", Vector2.ZERO, Vector2(360, 80), _quit_to_title)

	# Game over screen.
	over_panel = _overlay(root, 0.7)
	var ov := _vbox(over_panel, 380)
	var ot := _label(ov, Vector2.ZERO, Vector2(640, 140), 52)
	ot.text = "The Castle\nHas Fallen!"
	ot.add_theme_color_override("font_color", Color("#e0533f"))
	ot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	over_label = _label(ov, Vector2.ZERO, Vector2(640, 50), 30)
	over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_label = _label(ov, Vector2.ZERO, Vector2(640, 40), 26)
	best_label.add_theme_color_override("font_color", GOLD_COL)
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_spacer(ov, 40)
	_button(ov, "Play Again", Vector2.ZERO, Vector2(360, 86), start_run)
	_spacer(ov, 10)
	_button(ov, "Title", Vector2.ZERO, Vector2(360, 76), _quit_to_title)

	# Spellbook (recipe book).
	book_panel = _overlay(root, 0.6)
	var book := PanelContainer.new()
	book.position = Vector2(30, 110)
	book.size = Vector2(660, 1060)
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Color("#efdcb4")
	bsb.border_color = Color("#6b3a22")
	bsb.set_border_width_all(12)
	bsb.set_corner_radius_all(18)
	bsb.content_margin_left = 34
	bsb.content_margin_right = 34
	bsb.content_margin_top = 28
	bsb.content_margin_bottom = 28
	bsb.shadow_color = Color(0, 0, 0, 0.5)
	bsb.shadow_size = 12
	book.add_theme_stylebox_override("panel", bsb)
	book_panel.add_child(book)
	var bv := VBoxContainer.new()
	book.add_child(bv)
	book_text = RichTextLabel.new()
	book_text.bbcode_enabled = true
	book_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	book_text.add_theme_color_override("default_color", INK)
	book_text.add_theme_font_size_override("normal_font_size", 24)
	book_text.add_theme_font_size_override("bold_font_size", 30)
	bv.add_child(book_text)
	var close := _button(bv, "Close", Vector2.ZERO, Vector2(240, 70), _close_book)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_refresh_book()

	# Vintage film overlay on top of everything.
	var film := CanvasLayer.new()
	film.layer = 20
	add_child(film)
	var rect := ColorRect.new()
	rect.size = Vector2(W, H)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = VintageShader
	rect.material = mat
	film.add_child(rect)


func _make_theme() -> Theme:
	var th := Theme.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#e9d3a6")
	sb.border_color = INK
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(16)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 3
	sb.shadow_offset = Vector2(0, 4)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	var hover := sb.duplicate()
	hover.bg_color = Color("#f6e4bd")
	var pressed := sb.duplicate()
	pressed.bg_color = Color("#cfb486")
	pressed.shadow_offset = Vector2(0, 1)
	var disabled := sb.duplicate()
	disabled.bg_color = Color("#8c7f6c")
	th.set_stylebox("normal", "Button", sb)
	th.set_stylebox("hover", "Button", hover)
	th.set_stylebox("pressed", "Button", pressed)
	th.set_stylebox("disabled", "Button", disabled)
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		th.set_color(k, "Button", INK)
	th.set_color("font_disabled_color", "Button", Color(INK, 0.6))
	th.set_font_size("font_size", "Button", 26)
	th.set_color("font_color", "Label", PARCHMENT)
	th.set_color("font_outline_color", "Label", INK)
	th.set_constant("outline_size", "Label", 8)
	th.set_font_size("font_size", "Label", 26)
	return th


func _label(parent: Control, pos: Vector2, size: Vector2, font_size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.custom_minimum_size = size
	l.size = size
	l.add_theme_font_size_override("font_size", font_size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _button(parent: Control, text: String, pos: Vector2, size: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.custom_minimum_size = size
	b.size = size
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	if parent is VBoxContainer:
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	parent.add_child(b)
	return b


func _overlay(parent: Control, dim: float) -> Control:
	var o := ColorRect.new()
	o.color = Color(0.06, 0.03, 0.08, dim)
	o.position = Vector2.ZERO
	o.size = Vector2(W, H)
	o.mouse_filter = Control.MOUSE_FILTER_STOP
	o.hide()
	parent.add_child(o)
	return o


func _vbox(parent: Control, top: float) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.position = Vector2(40, top)
	v.size = Vector2(W - 80, H - top - 40)
	v.alignment = BoxContainer.ALIGNMENT_BEGIN
	parent.add_child(v)
	return v


func _spacer(parent: Control, h: float) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(s)


func _update_hud() -> void:
	var playing := state == "wave" or state == "break"
	wave_label.text = "Wave %d" % maxi(wave, 1 if state == "break" and wave == 0 else wave)
	if state == "break":
		wave_label.text = "Wave %d" % (wave + 1)
	gold_label.text = str(gold)
	wave_label.visible = playing or state == "gameover"
	gold_label.visible = playing or state == "gameover"
	book_btn.visible = playing
	pause_btn.visible = playing
	reroll_btn.visible = playing
	reroll_btn.text = "Reroll\n%d gold" % reroll_cost
	reroll_btn.disabled = gold < reroll_cost
	start_btn.visible = state == "break" and drag_card == null
	if state == "break":
		if break_timer > 0.0:
			start_btn.text = "Start Wave %d  (%d)" % [wave + 1, ceili(break_timer)]
		else:
			start_btn.text = "Start Wave %d" % (wave + 1)
	_update_shop_tags()


func banner(text: String, col: Color) -> void:
	banner_label.text = text
	banner_label.add_theme_color_override("font_color", col)
	banner_label.modulate.a = 1.0
	banner_label.scale = Vector2(0.6, 0.6)
	var tw := banner_label.create_tween()
	tw.tween_property(banner_label, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.4)
	tw.tween_property(banner_label, "modulate:a", 0.0, 0.5)


func show_info(text: String) -> void:
	info_label.text = text
	info_label.modulate.a = 1.0
	if _info_tween != null:
		_info_tween.kill()
	_info_tween = info_label.create_tween()
	_info_tween.tween_interval(4.0)
	_info_tween.tween_property(info_label, "modulate:a", 0.0, 0.6)


func _show_title() -> void:
	state = "title"
	_clear_board()
	(title_panel.find_child("BestLabel", true, false) as Label).text = "Best: wave %d" % CardDB.best_wave if CardDB.best_wave > 0 else ""
	title_panel.show()


func _pause() -> void:
	if state != "wave" and state != "break":
		return
	_cancel_drag()
	get_tree().paused = true
	pause_panel.show()


func _resume() -> void:
	pause_panel.hide()
	get_tree().paused = false


func _quit_to_title() -> void:
	pause_panel.hide()
	over_panel.hide()
	get_tree().paused = false
	_show_title()


func _open_book() -> void:
	_cancel_drag()
	if state == "wave" or state == "break":
		get_tree().paused = true
	_refresh_book()
	book_panel.show()


func _close_book() -> void:
	book_panel.hide()
	if not pause_panel.visible:
		get_tree().paused = false


func _refresh_book() -> void:
	if book_text == null:
		return
	var found := 0
	for r in CardDB.RECIPE_LIST:
		if CardDB.discovered.has(r[2]):
			found += 1
	var s := "[center][b]Spellbook of Fusions[/b]\n[color=#6b3a22]%d / %d recipes discovered[/color][/center]\n\n" % [found, CardDB.RECIPE_LIST.size()]
	s += "[b]Rules[/b]\n"
	s += "- Two of the same card with the same rarity fuse into one rarity higher.\n"
	s += "- Two different elements may fuse into a new one (keeps the lower rarity).\n"
	s += "- Rarities: "
	var parts := []
	for i in CardDB.RARITY_NAMES.size():
		parts.append("[color=#%s]%s[/color]" % [(CardDB.RARITY_COLORS[i] as Color).darkened(0.3).to_html(false), CardDB.RARITY_NAMES[i]])
	s += " > ".join(parts) + "\n\n"
	var tier_titles := {2: "Tier II Fusions", 3: "Tier III Fusions"}
	var last_tier := 0
	for r in CardDB.RECIPE_LIST:
		var tier: int = CardDB.elements[r[2]]["tier"]
		if tier != last_tier:
			s += "[b]%s[/b]\n" % tier_titles[tier]
			last_tier = tier
		if CardDB.discovered.has(r[2]):
			s += "%s + %s = [b]%s[/b]\n   [color=#6b5a48][i]%s[/i][/color]\n" % [_book_el(r[0]), _book_el(r[1]), _book_el(r[2]), CardDB.elements[r[2]]["desc"]]
		else:
			s += "[color=#8c7f6c]??? + ??? = ???[/color]\n   [color=#a89878][i]An undiscovered fusion...[/i][/color]\n"
	book_text.text = s


func _book_el(el: String) -> String:
	return "[color=#%s]%s[/color]" % [(CardDB.elements[el]["color"] as Color).darkened(0.35).to_html(false), CardDB.elements[el]["name"]]
