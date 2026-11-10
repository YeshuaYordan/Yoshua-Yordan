extends Node2D
## A lingering area effect (steam cloud, lava pool) that hurts enemies inside it.

var game
var radius := 60.0
var dps := 10.0
var duration := 2.5
var color := Color.WHITE
var slow := 0.0
var burn := 0.0
var _t := 0.0


func setup(g, pos: Vector2, r: float, d: float, dur: float, col: Color) -> void:
	game = g
	position = pos
	radius = r
	dps = d
	duration = dur
	color = col


func _process(delta: float) -> void:
	_t += delta
	if _t >= duration:
		queue_free()
		return
	for e in game.enemies.duplicate():
		if e.dead:
			continue
		if position.distance_to(e.position) <= radius + e.size * 0.5:
			e.take_damage(dps * delta)
			if slow > 0.0 and not e.dead:
				e.apply_slow(slow, 0.3)
			if burn > 0.0 and not e.dead:
				e.apply_burn(burn, 1.0)
	queue_redraw()


func _draw() -> void:
	var fade := 1.0 - _t / duration
	var grow := minf(1.0, _t * 6.0)
	for i in 6:
		var a := i * TAU / 6.0 + _t * 0.8
		var p := Vector2(cos(a), sin(a) * 0.6) * radius * 0.45 * grow
		draw_circle(p, radius * 0.55 * grow, Color(color, 0.22 * fade))
	draw_circle(Vector2.ZERO, radius * 0.6 * grow, Color(color, 0.25 * fade))
