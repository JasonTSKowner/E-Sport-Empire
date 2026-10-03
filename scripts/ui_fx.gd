class_name EmpireFX
extends RefCounted

static func reveal(control: Control, offset: Vector2 = Vector2(0, 14), duration: float = 0.24) -> void:
	if control == null or not is_instance_valid(control):
		return
	var target_position := control.position
	control.modulate.a = 0.0
	control.position = target_position + offset
	var tween := control.create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "modulate:a", 1.0, duration)
	tween.tween_property(control, "position", target_position, duration + 0.05)


static func pulse(control: Control, amount: float = 1.045, duration: float = 0.18) -> void:
	if control == null or not is_instance_valid(control):
		return
	control.pivot_offset = control.size * 0.5
	var tween := control.create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2(amount, amount), duration * 0.45)
	tween.tween_property(control, "scale", Vector2.ONE, duration * 0.55)


static func flash(control: CanvasItem, accent: Color, duration: float = 0.28) -> void:
	if control == null or not is_instance_valid(control):
		return
	var base := control.modulate
	control.modulate = Color(
		lerpf(base.r, accent.r, 0.38),
		lerpf(base.g, accent.g, 0.38),
		lerpf(base.b, accent.b, 0.38),
		base.a
	)
	var tween := control.create_tween()
	tween.tween_property(control, "modulate", base, duration)


static func shake(control: Control, strength: float = 5.0, duration: float = 0.20) -> void:
	if control == null or not is_instance_valid(control):
		return
	var origin := control.position
	var tween := control.create_tween()
	tween.tween_property(control, "position:x", origin.x + strength, duration * 0.20)
	tween.tween_property(control, "position:x", origin.x - strength * 0.75, duration * 0.20)
	tween.tween_property(control, "position:x", origin.x + strength * 0.40, duration * 0.20)
	tween.tween_property(control, "position", origin, duration * 0.40)
