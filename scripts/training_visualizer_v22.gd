class_name TrainingVisualizerV22
extends "res://scripts/training_visualizer.gd"

const DevelopmentV22Ref = preload("res://scripts/development_data.gd")

var signature_id := ""
var signature_label := ""
var step_label := "SETUP"


func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(0.0, 322.0)


func configure(player: Dictionary, readiness: Dictionary, color: Color) -> void:
	custom_minimum_size = Vector2(0.0, 322.0)
	super.configure(player, readiness, color)
	var signature := DevelopmentV22Ref.signature_move(player)
	signature_id = str(signature.get("id", ""))
	signature_label = str(signature.get("label", ""))
	if drill_id == "mechanics_lab" and not signature_label.is_empty():
		drill_label = "%s-SETUP" % signature_label.to_upper()
	queue_redraw()


func _process(delta: float) -> void:
	super._process(delta * 0.72)
	step_label = _current_step_label(drill_phase)


func _current_step_label(t: float) -> String:
	if drill_id == "rotation_review":
		return "1ST MAN CHALLENGE" if t < 0.32 else "ROTATION RAUS" if t < 0.66 else "BACK-POST COVER"
	if drill_id == "finishing_pack":
		return "ANLAUF" if t < 0.34 else "ERSTER TOUCH" if t < 0.62 else "ABSCHLUSS"
	if drill_id == "defensive_reads":
		return "SHADOW" if t < 0.42 else "CHALLENGE" if t < 0.70 else "CLEAR"
	if drill_id == "boost_routes":
		return "ROUTE LESEN" if t < 0.50 else "PAD-KETTE"
	if drill_id == "mental_coaching":
		return "POSITION HALTEN"
	if signature_id == "psycho":
		return "SIDEWALL SETUP" if t < 0.28 else "OWN BACKWALL" if t < 0.52 else "MUSTY" if t < 0.72 else "PSYCHO TOUCH"
	if signature_id in ["flip_reset", "double_reset", "triple_reset"]:
		return "WALL SETUP" if t < 0.28 else "RESET CONTACT" if t < 0.58 else "CONTROL" if t < 0.80 else "FINISH"
	if signature_id == "air_dribble":
		return "WALL SETUP" if t < 0.30 else "CARRY" if t < 0.78 else "FINISH"
	return "BALLKONTROLLE" if t < 0.50 else "ABSCHLUSS"


func _car_target_for_drill(t: float) -> Vector2:
	if drill_id == "mechanics_lab" and signature_id == "psycho":
		if t < 0.28:
			return Vector2(0.38, 0.72).lerp(Vector2(0.27, 0.14), _ease(t / 0.28))
		if t < 0.52:
			return Vector2(0.27, 0.14).lerp(Vector2(0.10, 0.29), _ease((t - 0.28) / 0.24))
		if t < 0.72:
			return Vector2(0.10, 0.29).lerp(Vector2(0.18, 0.50), _ease((t - 0.52) / 0.20))
		return Vector2(0.18, 0.50).lerp(Vector2(0.62, 0.45), _ease((t - 0.72) / 0.28))
	if drill_id == "mechanics_lab" and signature_id in ["flip_reset", "double_reset", "triple_reset"]:
		if t < 0.30:
			return Vector2(0.28, 0.72).lerp(Vector2(0.40, 0.16), _ease(t / 0.30))
		return Vector2(0.40, 0.16).lerp(Vector2(0.78, 0.44), _ease((t - 0.30) / 0.70))
	if drill_id == "mechanics_lab" and signature_id == "air_dribble":
		if t < 0.32:
			return Vector2(0.28, 0.72).lerp(Vector2(0.42, 0.17), _ease(t / 0.32))
		return Vector2(0.42, 0.17).lerp(Vector2(0.80, 0.46), _ease((t - 0.32) / 0.68))
	return super._car_target_for_drill(t)


func _ball_target_for_drill(t: float) -> Vector2:
	if drill_id == "mechanics_lab" and signature_id == "psycho":
		if t < 0.28:
			return Vector2(0.48, 0.66).lerp(Vector2(0.27, 0.12), _ease(t / 0.28))
		if t < 0.52:
			return Vector2(0.27, 0.12).lerp(Vector2(0.08, 0.28), _ease((t - 0.28) / 0.24))
		if t < 0.72:
			return Vector2(0.08, 0.28).lerp(Vector2(0.19, 0.49), _ease((t - 0.52) / 0.20))
		return Vector2(0.19, 0.49).lerp(Vector2(0.92, 0.50), _ease((t - 0.72) / 0.28))
	if drill_id == "mechanics_lab" and signature_id in ["flip_reset", "double_reset", "triple_reset"]:
		if t < 0.30:
			return Vector2(0.52, 0.58).lerp(Vector2(0.43, 0.15), _ease(t / 0.30))
		return Vector2(0.43, 0.15).lerp(Vector2(0.92, 0.49), _ease((t - 0.30) / 0.70))
	if drill_id == "mechanics_lab" and signature_id == "air_dribble":
		if t < 0.32:
			return Vector2(0.51, 0.60).lerp(Vector2(0.43, 0.15), _ease(t / 0.32))
		return Vector2(0.43, 0.15).lerp(Vector2(0.92, 0.48), _ease((t - 0.32) / 0.68))
	return super._ball_target_for_drill(t)


func _ball_height_for_drill(t: float) -> float:
	if drill_id == "mechanics_lab" and signature_id == "psycho":
		return 0.10 if t < 0.28 else 0.58 if t < 0.52 else 0.82 if t < 0.76 else 0.58
	if drill_id == "mechanics_lab" and signature_id in ["air_dribble", "flip_reset", "double_reset", "triple_reset"]:
		return 0.12 if t < 0.28 else minf(0.86, 0.48 + sin((t - 0.28) / 0.72 * PI) * 0.34)
	return super._ball_height_for_drill(t)


func _draw() -> void:
	super._draw()
	var arena := Rect2(Vector2(9, 42), Vector2(maxf(1.0, size.x - 18), maxf(1.0, size.y - 52)))
	var font := ThemeDB.fallback_font
	var current_ball := _field_point(ball_position, arena)
	var predicted_ball := _field_point(_ball_target_for_drill(minf(0.999, drill_phase + 0.10)), arena)
	draw_dashed_line(current_ball, predicted_ball, Color(accent.r, accent.g, accent.b, 0.46), 1.8, 6.0)

	if drill_id == "rotation_review":
		var second := _field_point(Vector2(0.48, 0.67), arena)
		var third := _field_point(Vector2(0.23, 0.31), arena)
		draw_circle(second, 8.0, Color(0.50, 0.91, 1.0, 0.16))
		draw_circle(third, 8.0, Color(0.50, 0.91, 1.0, 0.12))
		draw_string(font, second + Vector2(-13, 19), "2ND", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.75, 0.90, 1.0, 0.72))
		draw_string(font, third + Vector2(-13, 19), "3RD", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.75, 0.90, 1.0, 0.62))

	var label_width := font.get_string_size(step_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
	draw_rect(Rect2(size.x - label_width - 28, 22, label_width + 16, 18), Color(0.02, 0.03, 0.04, 0.78), true)
	draw_string(font, Vector2(size.x - label_width - 20, 35), step_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.90, 0.96, 1.0, 0.92))
