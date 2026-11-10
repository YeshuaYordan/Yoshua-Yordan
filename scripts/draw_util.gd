extends RefCounted
## Shared drawing helpers for the vintage cartoon look (ink outlines, pie-cut eyes).

const INK := Color("#2a1a12")


## Classic 1930s "pie-cut" cartoon eye.
static func pie_eye(ci: CanvasItem, pos: Vector2, r: float, look := Vector2.ZERO, blink := false, white := Color("#fffaf0")) -> void:
	if blink:
		ci.draw_line(pos - Vector2(r, 0), pos + Vector2(r, 0), INK, maxf(2.0, r * 0.35), true)
		return
	ci.draw_circle(pos, r, white)
	ci.draw_arc(pos, r, 0.0, TAU, 20, INK, maxf(1.5, r * 0.22), true)
	var pc := pos + look * r * 0.3 + Vector2(0, r * 0.1)
	var pr := r * 0.58
	ci.draw_circle(pc, pr, INK)
	# The "pie" wedge cut out of the pupil.
	var wedge := PackedVector2Array([pc])
	for i in 5:
		var a := lerpf(-1.25, -0.45, i / 4.0)
		wedge.append(pc + Vector2.from_angle(a) * pr * 1.02)
	ci.draw_colored_polygon(wedge, white)


## Draws a closed polygon with an ink outline.
static func inked_poly(ci: CanvasItem, pts: PackedVector2Array, fill: Color, width := 3.0) -> void:
	ci.draw_colored_polygon(pts, fill)
	var outline := pts.duplicate()
	outline.append(pts[0])
	ci.draw_polyline(outline, INK, width, true)


## Polygon whose radius is a function of angle (always a valid, non-self-intersecting shape).
static func radial_poly(center: Vector2, r: float, shape: String, t: float, seed_val: float, n := 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	match shape:
		"crystal":
			var radii := [1.45, 0.85, 0.85, 1.25, 0.85, 0.85]
			for i in 6:
				var a := -PI / 2.0 + i * TAU / 6.0
				pts.append(center + Vector2.from_angle(a) * r * radii[i])
			return pts
		"rock":
			for i in 9:
				var a := -PI / 2.0 + i * TAU / 9.0
				var k := 0.88 + 0.16 * sin(seed_val * 13.0 + i * 2.7)
				pts.append(center + Vector2.from_angle(a) * r * k)
			return pts
	for i in n:
		var a := -PI / 2.0 + i * TAU / n
		var up := maxf(0.0, -sin(a))  # 1 at the top, 0 on the lower half
		var rr := r
		match shape:
			"flame":
				rr = r * (1.0 + 0.55 * pow(up, 3.0) * (0.85 + 0.15 * sin(t * 9.0 + i))
					+ 0.12 * up * absf(sin(a * 3.0 + t * 6.0)))
			"drop":
				rr = r * (1.0 + 0.7 * pow(up, 6.0))
			"spiky":
				rr = r * (1.12 if i % 2 == 0 else 0.8)
			"cloud":
				rr = r * (0.92 + 0.12 * absf(sin(a * 2.5 + 0.4)))
			"blob", "swirl", "leaf":
				rr = r * (1.0 + 0.05 * sin(a * 5.0 + t * 3.0 + seed_val))
		pts.append(center + Vector2.from_angle(a) * rr)
	return pts


static func ellipse(ci: CanvasItem, center: Vector2, radii: Vector2, color: Color, n := 24) -> void:
	var pts := PackedVector2Array()
	for i in n:
		var a := i * TAU / n
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	ci.draw_colored_polygon(pts, color)


static func text(ci: CanvasItem, pos: Vector2, s: String, size: int, color: Color, width := 200.0, outline := 0, outline_color := INK) -> void:
	var font := ThemeDB.fallback_font
	var p := pos - Vector2(width / 2.0, 0)
	if outline > 0:
		ci.draw_string_outline(font, p, s, HORIZONTAL_ALIGNMENT_CENTER, width, size, outline, outline_color)
	ci.draw_string(font, p, s, HORIZONTAL_ALIGNMENT_CENTER, width, size, color)
