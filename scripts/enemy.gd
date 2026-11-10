extends Node2D
## A shadow creature marching on the castle.

const DU = preload("res://scripts/draw_util.gd")
const INK := Color("#2a1a12")

const KINDS := {
	"grunt": {"hp": 30.0, "speed": 42.0, "size": 22.0, "gold": 1, "dps": 5.0, "color": Color("#6b4f8a")},
	"runner": {"hp": 16.0, "speed": 85.0, "size": 16.0, "gold": 1, "dps": 3.0, "color": Color("#c4493e")},
	"tank": {"hp": 130.0, "speed": 22.0, "size": 31.0, "gold": 3, "dps": 12.0, "color": Color("#7c8594")},
	"flyer": {"hp": 22.0, "speed": 58.0, "size": 18.0, "gold": 2, "dps": 4.0, "color": Color("#4a5a8c"), "flying": true},
	"boss": {"hp": 1000.0, "speed": 16.0, "size": 52.0, "gold": 30, "dps": 30.0, "color": Color("#3d2050")},
}

var game
var kind := "grunt"
var hp := 30.0
var max_hp := 30.0
var speed := 40.0
var size := 22.0
var gold := 1
var dps := 5.0
var flying := false
var resist := ""
var dead := false
var color := Color.WHITE
var wall_y := 690.0

var burn_dps := 0.0
var burn_t := 0.0
var slow_mult := 1.0
var slow_t := 0.0
var root_t := 0.0
var attacking := false

var _t := 0.0
var _flash := 0.0
var _base_x := 0.0


func setup(g, k: String, wave: int, res: String, wall: float) -> void:
	game = g
	kind = k
	wall_y = wall
	var d: Dictionary = KINDS[k]
	var w := float(wave - 1)
	var hp_scale := (1.0 + 0.2 * w) * pow(1.05, w)
	hp = float(d["hp"]) * hp_scale * (1.3 if res != "" else 1.0)
	max_hp = hp
	speed = float(d["speed"]) * (1.0 + minf(0.5, wave * 0.012))
	size = d["size"]
	gold = int(d["gold"]) + wave / 8
	dps = float(d["dps"]) * (1.0 + wave * 0.05)
	flying = d.get("flying", false)
	color = d["color"]
	resist = res
	_base_x = position.x
	_t = randf() * 10.0


func _process(delta: float) -> void:
	if dead:
		return
	_t += delta
	_flash = maxf(0.0, _flash - delta * 6.0)
	if burn_t > 0.0:
		burn_t -= delta
		take_damage(burn_dps * delta)
		if dead:
			return
	if slow_t > 0.0:
		slow_t -= delta
	else:
		slow_mult = 1.0
	if root_t > 0.0:
		root_t -= delta

	var limit := wall_y - size * 0.6
	if position.y < limit:
		attacking = false
		if root_t <= 0.0:
			position.y += speed * slow_mult * delta
		if flying:
			position.x = clampf(_base_x + sin(_t * 2.5) * 30.0, 30.0, 690.0)
	else:
		attacking = true
		position.y = limit
		game.damage_castle(dps * delta)
	queue_redraw()


func take_damage(amount: float) -> void:
	if dead:
		return
	hp -= amount
	if amount >= 1.0:
		_flash = 1.0
	if hp <= 0.0:
		dead = true
		game.on_enemy_killed(self)


func apply_slow(mult: float, dur: float) -> void:
	if kind == "boss":
		mult = lerpf(mult, 1.0, 0.5)
	slow_mult = minf(slow_mult, mult)
	slow_t = maxf(slow_t, dur)


func apply_root(dur: float) -> void:
	if kind == "boss":
		dur *= 0.3
	root_t = maxf(root_t, dur)


func apply_burn(burn: float, dur: float) -> void:
	burn_dps = maxf(burn_dps if burn_t > 0.0 else 0.0, burn)
	burn_t = maxf(burn_t, dur)


func knockback(px: float) -> void:
	if kind == "boss":
		px *= 0.15
	elif kind == "tank":
		px *= 0.5
	position.y = maxf(90.0, position.y - px)


func _draw() -> void:
	var s := size
	var walk := -absf(sin(_t * (5.0 if attacking else 8.0))) * s * 0.15
	if flying:
		walk = sin(_t * 4.0) * 5.0 - 10.0
	# Shadow.
	DU.ellipse(self, Vector2(0, s * 0.85), Vector2(s * 0.9, s * 0.28), Color(0, 0, 0, 0.35))
	var c := Vector2(0, walk)
	var body := color
	if slow_t > 0.0:
		body = body.lerp(Color("#9fdcff"), 0.45)

	# Element resistance aura.
	if resist != "":
		var rc: Color = CardDB.elements[resist]["color"]
		draw_arc(c, s * 1.3, 0, TAU, 28, Color(rc, 0.75), 3.0, true)
		draw_circle(c, s * 1.25, Color(rc, 0.15))

	match kind:
		"flyer":
			var flap := sin(_t * 14.0) * 0.5
			for side in [-1.0, 1.0]:
				var wing := PackedVector2Array([c + Vector2(side * s * 0.6, -s * 0.2),
					c + Vector2(side * s * 2.0, -s * (0.9 + flap)),
					c + Vector2(side * s * 1.6, s * 0.1),
					c + Vector2(side * s * 1.1, -s * 0.05)])
				DU.inked_poly(self, wing, body.darkened(0.25), 2.0)
		"grunt", "boss":
			for side in [-1.0, 1.0]:
				var horn := PackedVector2Array([c + Vector2(side * s * 0.35, -s * 0.8),
					c + Vector2(side * s * 0.75, -s * 1.45), c + Vector2(side * s * 0.75, -s * 0.6)])
				DU.inked_poly(self, horn, Color("#e9d3a6"), 2.0)
		"runner":
			for side in [-1.0, 1.0]:
				var ear := PackedVector2Array([c + Vector2(side * s * 0.4, -s * 0.7),
					c + Vector2(side * s * 1.2, -s * 1.1), c + Vector2(side * s * 0.85, -s * 0.3)])
				DU.inked_poly(self, ear, body.darkened(0.2), 2.0)

	if kind == "tank":
		var rect := PackedVector2Array([c + Vector2(-s, -s * 0.9), c + Vector2(s, -s * 0.9),
			c + Vector2(s * 0.9, s * 0.9), c + Vector2(-s * 0.9, s * 0.9)])
		DU.inked_poly(self, rect, body, 3.0)
		draw_rect(Rect2(c + Vector2(-s * 0.75, -s * 0.35), Vector2(s * 1.5, s * 0.45)), INK)
		draw_circle(c + Vector2(-s * 0.32, -s * 0.12), s * 0.12, Color("#ffcf4a"))
		draw_circle(c + Vector2(s * 0.32, -s * 0.12), s * 0.12, Color("#ffcf4a"))
		draw_line(c + Vector2(0, -s * 0.9), c + Vector2(0, -s * 1.3), INK, 3.0)
		draw_circle(c + Vector2(0, -s * 1.35), s * 0.15, Color("#c4493e"))
	else:
		var pts := DU.radial_poly(c, s, "blob", _t, 1.0)
		DU.inked_poly(self, pts, body, 3.0 if s > 20 else 2.5)
		draw_circle(c + Vector2(-s * 0.4, -s * 0.45), s * 0.16, Color(1, 1, 1, 0.3))
		var look := Vector2(0, 0.6)
		if kind == "boss":
			DU.pie_eye(self, c + Vector2(-s * 0.32, -s * 0.12), s * 0.22, look, false, Color("#ffcf4a"))
			DU.pie_eye(self, c + Vector2(s * 0.32, -s * 0.12), s * 0.22, look, false, Color("#ffcf4a"))
			var crown := PackedVector2Array([c + Vector2(-s * 0.55, -s * 0.75), c + Vector2(-s * 0.5, -s * 1.25),
				c + Vector2(-s * 0.2, -s * 0.95), c + Vector2(0, -s * 1.4), c + Vector2(s * 0.2, -s * 0.95),
				c + Vector2(s * 0.5, -s * 1.25), c + Vector2(s * 0.55, -s * 0.75)])
			DU.inked_poly(self, crown, Color("#f2c14e"), 3.0)
		else:
			DU.pie_eye(self, c + Vector2(-s * 0.33, -s * 0.1), s * 0.27, look)
			DU.pie_eye(self, c + Vector2(s * 0.33, -s * 0.1), s * 0.27, look)
		# Angry brows and fanged grin.
		draw_line(c + Vector2(-s * 0.6, -s * 0.5), c + Vector2(-s * 0.12, -s * 0.32), INK, 3.0, true)
		draw_line(c + Vector2(s * 0.6, -s * 0.5), c + Vector2(s * 0.12, -s * 0.32), INK, 3.0, true)
		draw_arc(c + Vector2(0, s * 0.25), s * 0.35, 0.3, PI - 0.3, 10, INK, 2.5, true)
		var fang := PackedVector2Array([c + Vector2(-s * 0.18, s * 0.5), c + Vector2(-s * 0.08, s * 0.72), c + Vector2(0, s * 0.53)])
		draw_colored_polygon(fang, Color("#fffaf0"))

	# Status effects.
	if burn_t > 0.0:
		for i in 3:
			var fp := c + Vector2((i - 1) * s * 0.5, -s * 0.9 - fmod(_t * 40.0 + i * 13.0, s * 0.6))
			draw_circle(fp, 3.5, Color("#ff7a2f"))
			draw_circle(fp, 1.8, Color("#ffe34a"))
	if root_t > 0.0:
		for i in 4:
			var vx := (i - 1.5) * s * 0.5
			draw_arc(Vector2(vx, s * 0.75), s * 0.25, PI, TAU, 8, Color("#3e9b48"), 3.0, true)

	if _flash > 0.0:
		draw_circle(c, s * 1.05, Color(1, 1, 1, _flash * 0.45))

	# Health bar.
	if hp < max_hp:
		var bw := maxf(34.0, s * 2.0)
		var by := c.y - s * 1.55 - (10.0 if kind == "boss" else 0.0)
		draw_rect(Rect2(-bw / 2.0 - 2.0, by - 2.0, bw + 4.0, 9.0), INK)
		draw_rect(Rect2(-bw / 2.0, by, bw * clampf(hp / max_hp, 0.0, 1.0), 5.0), Color("#e0533f"))
