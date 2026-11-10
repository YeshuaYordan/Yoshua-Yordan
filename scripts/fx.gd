extends Node2D
## Short-lived visual effects: bursts, lightning bolts and floating text.

const DU = preload("res://scripts/draw_util.gd")
const INK := Color("#2a1a12")

var mode := "burst"
var color := Color.WHITE
var duration := 0.4
var radius := 40.0
var points := PackedVector2Array()
var text := ""
var font_size := 22
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	if _t >= duration:
		queue_free()
		return
	if mode == "text":
		position.y -= 45.0 * delta
	queue_redraw()


func _draw() -> void:
	var k := _t / duration
	match mode:
		"burst":
			var r := radius * (0.3 + 0.7 * k)
			draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(color, 1.0 - k), 5.0 * (1.0 - k) + 1.0, true)
			for i in 8:
				var a := i * TAU / 8.0
				draw_line(Vector2.from_angle(a) * r * 0.6, Vector2.from_angle(a) * r * 1.1, Color(color, 1.0 - k), 2.5)
		"bolt":
			var jag := PackedVector2Array()
			for i in points.size() - 1:
				var a := points[i]
				var b := points[i + 1]
				jag.append(a)
				var normal := (b - a).orthogonal().normalized()
				for j in range(1, 4):
					jag.append(a.lerp(b, j / 4.0) + normal * randf_range(-12.0, 12.0))
			jag.append(points[points.size() - 1])
			draw_polyline(jag, Color(color, 1.0 - k), 7.0, true)
			draw_polyline(jag, Color(1, 1, 1, 1.0 - k), 2.5, true)
		"text":
			var a := 1.0 - k * k
			DU.text(self, Vector2.ZERO, text, font_size, Color(color, a), 300.0, 5, Color(INK, a))
