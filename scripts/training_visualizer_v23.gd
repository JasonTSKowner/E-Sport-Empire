class_name TrainingVisualizerV23
extends "res://scripts/training_visualizer_v22.gd"

const MechanicsV23Ref = preload("res://scripts/mechanics_catalog_v23.gd")

var focus_mechanic: Dictionary = {}
var focus_family := ""


func configure(player: Dictionary, readiness: Dictionary, color: Color) -> void:
	super.configure(player, readiness, color)
	var unlocked := MechanicsV23Ref.unlocked(player)
	if not unlocked.is_empty():
		focus_mechanic = unlocked[unlocked.size() - 1].duplicate(true)
		signature_id = str(focus_mechanic.get("id", signature_id))
		signature_label = str(focus_mechanic.get("label", signature_label))
		focus_family = str(focus_mechanic.get("family", ""))
		if drill_id == "mechanics_lab":
			drill_label = "%s-LAB" % signature_label.to_upper()
	queue_redraw()


func _current_step_label(t: float) -> String:
	if drill_id != "mechanics_lab" or focus_mechanic.is_empty():
		return super._current_step_label(t)
	match focus_family:
		"recovery":
			return "LANDUNG" if t < 0.30 else "DASH" if t < 0.68 else "ROTATION"
		"flick":
			return "BALL CONTROL" if t < 0.30 else "FLICK LOAD" if t < 0.62 else "RELEASE"
		"musty":
			return "SETUP" if t < 0.28 else "MUSTY LOAD" if t < 0.60 else "MUSTY RELEASE"
		"air_dribble":
			return "WALL SETUP" if t < 0.28 else "FIRST TOUCH" if t < 0.48 else "CARRY" if t < 0.82 else "FINISH"
		"double_tap":
			return "FIRST TOUCH" if t < 0.36 else "BACKBOARD READ" if t < 0.72 else "SECOND TOUCH"
		"redirect":
			return "READ" if t < 0.30 else "PREJUMP" if t < 0.66 else "REDIRECT"
		"ceiling":
			return "WALL" if t < 0.26 else "CEILING" if t < 0.52 else "DROP" if t < 0.76 else "FINISH"
		"reset", "multi_reset", "stall":
			return "WALL SETUP" if t < 0.24 else "RESET" if t < 0.54 else "CONTROL" if t < 0.78 else "FINISH"
		"pinch", "team_pinch":
			return "ANGLE" if t < 0.42 else "CONTACT" if t < 0.72 else "RELEASE"
		"pogo":
			return "AIR SETUP" if t < 0.34 else "DROP" if t < 0.62 else "BOUNCE"
		"psycho":
			return "SIDEWALL" if t < 0.24 else "OWN BACKWALL" if t < 0.50 else "MUSTY/TOUCH" if t < 0.72 else "PSYCHO"
		"defense", "save":
			return "READ" if t < 0.36 else "SAVE LINE" if t < 0.68 else "CLEAR"
	return super._current_step_label(t)


func _car_target_for_drill(t: float) -> Vector2:
	if drill_id != "mechanics_lab" or focus_mechanic.is_empty():
		return super._car_target_for_drill(t)
	match focus_family:
		"recovery":
			return Vector2(0.20, 0.70).lerp(Vector2(0.72, 0.52), _ease(t))
		"flick", "musty":
			return Vector2(0.25, 0.62).lerp(Vector2(0.78, 0.50), _ease(t))
		"air_dribble", "reset", "multi_reset", "stall":
			if t < 0.28:
				return Vector2(0.28, 0.72).lerp(Vector2(0.40, 0.16), _ease(t / 0.28))
			return Vector2(0.40, 0.16).lerp(Vector2(0.80, 0.44), _ease((t - 0.28) / 0.72))
		"double_tap":
			return Vector2(0.36, 0.58).lerp(Vector2(0.88, 0.38 if t < 0.62 else 0.52), _ease(t))
		"redirect":
			return Vector2(0.32, 0.72).lerp(Vector2(0.82, 0.44), _ease(t))
		"ceiling":
			if t < 0.42:
				return Vector2(0.30, 0.70).lerp(Vector2(0.52, 0.10), _ease(t / 0.42))
			return Vector2(0.52, 0.10).lerp(Vector2(0.82, 0.46), _ease((t - 0.42) / 0.58))
		"pinch", "team_pinch":
			return Vector2(0.28, 0.70).lerp(Vector2(0.64, 0.68), _ease(minf(1.0, t * 1.35)))
		"pogo":
			return Vector2(0.38, 0.58).lerp(Vector2(0.72, 0.66 if t < 0.62 else 0.42), _ease(t))
		"psycho":
			if t < 0.28: return Vector2(0.38, 0.72).lerp(Vector2(0.27, 0.14), _ease(t / 0.28))
			if t < 0.52: return Vector2(0.27, 0.14).lerp(Vector2(0.10, 0.29), _ease((t - 0.28) / 0.24))
			if t < 0.72: return Vector2(0.10, 0.29).lerp(Vector2(0.18, 0.50), _ease((t - 0.52) / 0.20))
			return Vector2(0.18, 0.50).lerp(Vector2(0.62, 0.45), _ease((t - 0.72) / 0.28))
		"defense", "save":
			return Vector2(0.18, 0.58).lerp(Vector2(0.42, 0.42), _ease(t))
	return super._car_target_for_drill(t)


func _ball_target_for_drill(t: float) -> Vector2:
	if drill_id != "mechanics_lab" or focus_mechanic.is_empty():
		return super._ball_target_for_drill(t)
	match focus_family:
		"recovery":
			return Vector2(0.60, 0.44)
		"flick", "musty":
			return Vector2(0.34, 0.58).lerp(Vector2(0.92, 0.46), _ease(t))
		"air_dribble", "reset", "multi_reset", "stall":
			if t < 0.28:
				return Vector2(0.48, 0.64).lerp(Vector2(0.42, 0.14), _ease(t / 0.28))
			return Vector2(0.42, 0.14).lerp(Vector2(0.92, 0.48), _ease((t - 0.28) / 0.72))
		"double_tap":
			if t < 0.58:
				return Vector2(0.48, 0.58).lerp(Vector2(0.94, 0.32), _ease(t / 0.58))
			return Vector2(0.94, 0.32).lerp(Vector2(0.96, 0.50), _ease((t - 0.58) / 0.42))
		"redirect":
			return Vector2(0.55, 0.26).lerp(Vector2(0.96, 0.50), _ease(t))
		"ceiling":
			if t < 0.44: return Vector2(0.48, 0.62).lerp(Vector2(0.53, 0.08), _ease(t / 0.44))
			return Vector2(0.53, 0.08).lerp(Vector2(0.94, 0.48), _ease((t - 0.44) / 0.56))
		"pinch", "team_pinch":
			if t < 0.68: return Vector2(0.48, 0.66).lerp(Vector2(0.64, 0.68), _ease(t / 0.68))
			return Vector2(0.64, 0.68).lerp(Vector2(0.96, 0.50), _ease((t - 0.68) / 0.32))
		"pogo":
			return Vector2(0.48, 0.30).lerp(Vector2(0.82, 0.52), _ease(t))
		"psycho":
			if t < 0.28: return Vector2(0.48, 0.66).lerp(Vector2(0.27, 0.12), _ease(t / 0.28))
			if t < 0.52: return Vector2(0.27, 0.12).lerp(Vector2(0.08, 0.28), _ease((t - 0.28) / 0.24))
			if t < 0.72: return Vector2(0.08, 0.28).lerp(Vector2(0.19, 0.49), _ease((t - 0.52) / 0.20))
			return Vector2(0.19, 0.49).lerp(Vector2(0.92, 0.50), _ease((t - 0.72) / 0.28))
		"defense", "save":
			return Vector2(0.70, 0.30).lerp(Vector2(0.20, 0.50), _ease(t))
	return super._ball_target_for_drill(t)


func _ball_height_for_drill(t: float) -> float:
	if drill_id != "mechanics_lab" or focus_mechanic.is_empty():
		return super._ball_height_for_drill(t)
	if focus_family in ["air_dribble", "reset", "multi_reset", "stall", "double_tap", "redirect", "ceiling", "pogo", "psycho"]:
		return 0.12 if t < 0.22 else minf(0.90, 0.44 + sin((t - 0.22) / 0.78 * PI) * 0.40)
	if focus_family in ["flick", "musty", "pinch", "team_pinch"]:
		return 0.10 if t < 0.55 else 0.48
	return 0.08


func _draw() -> void:
	super._draw()
	if focus_mechanic.is_empty():
		return
	var font := ThemeDB.fallback_font
	var category := str(focus_mechanic.get("category", "MECH")).to_upper()
	var tier := int(focus_mechanic.get("tier", 1))
	var text := "%s  •  TIER %d" % [category, tier]
	draw_string(font, Vector2(14, size.y - 8), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.62, 0.72, 0.82, 0.72))
