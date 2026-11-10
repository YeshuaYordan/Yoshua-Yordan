extends Node2D
## An elemental spirit card. Drawn entirely in code (placeholder art).

const DU = preload("res://scripts/draw_util.gd")
const SIZE := Vector2(112, 136)
const INK := Color("#2a1a12")
const PARCHMENT := Color("#f3e3c3")

var element := "fire"
var rarity := 0
var cooldown := 0.0
var in_shop := false
var price := 0
var is_free := false
var affordable := true
var dragging := false
var home := Vector2.ZERO

var _t := 0.0
var _seed := 0.0
var _kick := 0.0
var _shake := 0.0
var _frame := StyleBoxFlat.new()
var _inner := StyleBoxFlat.new()


func setup(el: String, r: int) -> void:
	element = el
	rarity = r
	_seed = randf() * 100.0
	cooldown = randf() * 0.5
	_frame.set_corner_radius_all(12)
	_frame.set_border_width_all(3)
	_frame.border_color = INK
	_frame.shadow_color = Color(0, 0, 0, 0.35)
	_frame.shadow_size = 2
	_frame.shadow_offset = Vector2(3, 5)
	_inner.set_corner_radius_all(8)
	_inner.set_border_width_all(2)
	_inner.border_color = Color(INK, 0.5)
	_inner.bg_color = PARCHMENT
	_refresh_style()


func set_card(el: String, r: int) -> void:
	element = el
	rarity = r
	_refresh_style()


func _refresh_style() -> void:
	_frame.bg_color = CardDB.RARITY_COLORS[rarity]
	var el_col: Color = CardDB.elements[element]["color"]
	_inner.bg_color = PARCHMENT.lerp(el_col, 0.12)


func set_home(p: Vector2, snap := false) -> void:
	home = p
	if snap:
		position = p


func kick() -> void:
	_kick = 1.0


func shake() -> void:
	_shake = 1.0


func pop() -> void:
	scale = Vector2(1.35, 1.35)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func get_rect() -> Rect2:
	return Rect2(position - SIZE / 2.0, SIZE)


func _process(delta: float) -> void:
	_t += delta
	_kick = maxf(0.0, _kick - delta * 5.0)
	_shake = maxf(0.0, _shake - delta * 3.0)
	if not dragging:
		position = position.lerp(home, minf(1.0, delta * 16.0))
	queue_redraw()


func _draw() -> void:
	var off := Vector2(sin(_t * 60.0) * 6.0 * _shake, -8.0 * _kick)
	if dragging:
		off.y -= 6.0
	var half := SIZE / 2.0
	var rect := Rect2(off - half, SIZE)
	var el_col: Color = CardDB.elements[element]["color"]
	var tier: int = CardDB.elements[element]["tier"]

	# Aura for high rarities.
	if rarity >= 3:
		var pulse := 0.5 + 0.5 * sin(_t * 3.0)
		var aura_col: Color = CardDB.RARITY_COLORS[rarity]
		for i in 3:
			_frame_glow(rect.grow(4.0 + i * 4.0 + pulse * 3.0), Color(aura_col, 0.12 - i * 0.03))

	draw_style_box(_frame, rect)
	draw_style_box(_inner, rect.grow(-6))

	# Rarity label and tier pips.
	var r_col: Color = CardDB.RARITY_COLORS[rarity]
	DU.text(self, off + Vector2(0, -half.y + 22), CardDB.RARITY_NAMES[rarity].to_upper(), 11, r_col.darkened(0.35), 96.0)
	for i in tier:
		var pip := off + Vector2((i - (tier - 1) / 2.0) * 10.0, half.y - 13)
		draw_circle(pip, 3.5, INK)
		draw_circle(pip, 2.2, Color("#f2c14e"))

	# Rune corners for Rare and above.
	if rarity >= 2:
		for c in [Vector2(-1, 1), Vector2(1, 1)]:
			var p: Vector2 = off + Vector2(c.x * (half.x - 15), c.y * (half.y - 34))
			draw_arc(p, 5, 0, TAU, 12, Color(r_col, 0.8), 1.5)
			draw_line(p + Vector2(0, -4), p + Vector2(0, 4), Color(r_col, 0.8), 1.5)

	# The elemental spirit.
	var bob := sin(_t * 2.2 + _seed) * 3.0
	var c := off + Vector2(0, -6 + bob)
	var r := 26.0
	# Soft glow behind the spirit.
	draw_circle(c, r * 1.45, Color(el_col, 0.18))
	draw_circle(c, r * 1.2, Color(el_col, 0.18))
	var shape: String = CardDB.elements[element]["shape"]
	var pts := DU.radial_poly(c, r, shape, _t, _seed)
	DU.inked_poly(self, pts, el_col, 3.0)
	_draw_accents(c, r, shape, el_col)
	# Shine.
	draw_circle(c + Vector2(-r * 0.45, -r * 0.5), r * 0.18, Color(1, 1, 1, 0.45))
	# Face.
	var blink := fmod(_t + _seed, 3.7) < 0.12
	var look := Vector2(sin(_t * 0.7 + _seed) * 0.6, -0.4)
	DU.pie_eye(self, c + Vector2(-r * 0.36, -r * 0.05), r * 0.27, look, blink)
	DU.pie_eye(self, c + Vector2(r * 0.36, -r * 0.05), r * 0.27, look, blink)
	draw_arc(c + Vector2(0, r * 0.28), r * 0.22, 0.25, PI - 0.25, 10, INK, 2.5, true)

	# Sparkles for Epic and above.
	if rarity >= 3:
		for i in rarity - 1:
			var a := _t * 1.5 + i * TAU / float(rarity - 1)
			var sp := c + Vector2(cos(a) * 40.0, sin(a) * 26.0)
			_sparkle(sp, 3.0 + sin(_t * 5.0 + i) * 1.2, Color("#fff6c8"))

	# Name.
	DU.text(self, off + Vector2(0, half.y - 24), CardDB.elements[element]["name"], 18, INK, 104.0)

	# Shop price tag.
	if in_shop:
		var tag := off + Vector2(0, half.y + 4)
		var tag_rect := Rect2(tag - Vector2(34, 13), Vector2(68, 26))
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(13)
		sb.set_border_width_all(2)
		sb.border_color = INK
		if is_free:
			sb.bg_color = Color("#6cc56a")
			draw_style_box(sb, tag_rect)
			DU.text(self, tag + Vector2(0, 7), "FREE", 18, INK, 68.0)
		else:
			sb.bg_color = Color("#f2c14e") if affordable else Color("#c46a5a")
			draw_style_box(sb, tag_rect)
			DU.text(self, tag + Vector2(0, 7), "%d g" % price, 18, INK, 68.0)


func _frame_glow(rect: Rect2, col: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(18)
	draw_style_box(sb, rect)


func _sparkle(p: Vector2, s: float, col: Color) -> void:
	draw_line(p - Vector2(s, 0), p + Vector2(s, 0), col, 1.5)
	draw_line(p - Vector2(0, s), p + Vector2(0, s), col, 1.5)


func _draw_accents(c: Vector2, r: float, shape: String, col: Color) -> void:
	match shape:
		"swirl":
			for i in 3:
				var a := _t * 2.0 + i * TAU / 3.0
				draw_arc(c, r * 1.25, a, a + 1.1, 10, Color(INK, 0.6), 2.0, true)
		"leaf":
			var top := c + Vector2(0, -r)
			var leaf := PackedVector2Array([top, top + Vector2(-12, -10), top + Vector2(-2, -16), top + Vector2(0, -6),
				top + Vector2(2, -16), top + Vector2(12, -10)])
			DU.inked_poly(self, leaf, col.lightened(0.25), 2.0)
		"rock":
			draw_line(c + Vector2(-r * 0.6, r * 0.55), c + Vector2(-r * 0.2, r * 0.75), Color(INK, 0.6), 2.0)
			draw_line(c + Vector2(r * 0.6, -r * 0.6), c + Vector2(r * 0.3, -r * 0.8), Color(INK, 0.6), 2.0)
		"spiky":
			for i in 2:
				var s := -1.0 if i == 0 else 1.0
				var w := PackedVector2Array([c + Vector2(s * r * 0.8, 0), c + Vector2(s * r * 1.7, -r * 0.5 + sin(_t * 8.0) * 4.0),
					c + Vector2(s * r * 1.4, r * 0.2)])
				DU.inked_poly(self, w, col.darkened(0.1), 2.0)
