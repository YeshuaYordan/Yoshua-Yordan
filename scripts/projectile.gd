extends Node2D
## An elemental shot fired by a card.

const INK := Color("#2a1a12")

var game
var element := "fire"
var rarity := 0
var target
var target_pos := Vector2.ZERO
var velocity := Vector2.ZERO
var speed := 650.0
var pierce_left := 0
var homing := true
var radius := 8.0
var color := Color.WHITE
var _hit := []
var _trail := []
var _life := 3.0


func setup(g, el: String, r: int, origin: Vector2, tgt: Node2D) -> void:
	game = g
	element = el
	rarity = r
	position = origin
	target = tgt
	target_pos = tgt.position
	var d: Dictionary = CardDB.elements[el]
	speed = d.get("speed", 650.0)
	color = d["color"]
	pierce_left = d.get("pierce", 0)
	homing = pierce_left == 0
	radius = 7.0 + r * 1.2 + (4.0 if d["shape"] == "rock" else 0.0)
	velocity = (target_pos - origin).normalized() * speed


func _process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	_trail.push_front(position)
	if _trail.size() > 7:
		_trail.pop_back()

	if homing:
		var alive: bool = is_instance_valid(target) and not target.dead
		if alive:
			target_pos = target.position
		var to := target_pos - position
		if to.length() <= speed * delta + 6.0:
			position = target_pos
			game.apply_hit(element, rarity, position, target if alive else null)
			queue_free()
			return
		velocity = to.normalized() * speed
		position += velocity * delta
	else:
		position += velocity * delta
		for e in game.enemies.duplicate():
			if _hit.has(e) or e.dead:
				continue
			if position.distance_to(e.position) < e.size + radius:
				_hit.append(e)
				game.apply_hit(element, rarity, position, e)
				pierce_left -= 1
				if pierce_left < 0:
					queue_free()
					return
		if position.y < 60.0 or position.x < -40.0 or position.x > 760.0:
			queue_free()
			return
	queue_redraw()


func _draw() -> void:
	var n := _trail.size()
	for i in n:
		var k := 1.0 - float(i) / n
		draw_circle(_trail[i] - position, radius * (0.4 + 0.5 * k), Color(color, 0.35 * k))
	draw_circle(Vector2.ZERO, radius * 1.6, Color(color, 0.25))
	draw_circle(Vector2.ZERO, radius, color)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 16, INK, 2.0, true)
	draw_circle(Vector2(-radius * 0.3, -radius * 0.3), radius * 0.35, Color(1, 1, 1, 0.7))
