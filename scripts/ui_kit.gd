class_name EmpireUI
extends RefCounted

const BG := Color("050817")
const SURFACE := Color("0c1228")
const SURFACE_2 := Color("111a35")
const SURFACE_3 := Color("172140")
const TEXT := Color("f3f6ff")
const MUTED := Color("8d9abb")
const DIM := Color("596887")
const CYAN := Color("2de2ff")
const PURPLE := Color("a779ff")
const GREEN := Color("58e39b")
const RED := Color("ff647c")
const GOLD := Color("ffbf69")


static func box(
	color: Color, radius: int = 20, border_color: Color = Color.TRANSPARENT, border_width: int = 0
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.border_color = border_color
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 14.0
	style.content_margin_bottom = 14.0
	style.anti_aliasing = true
	return style


static func card(accent: Color = Color.TRANSPARENT) -> PanelContainer:
	var panel := PanelContainer.new()
	var border := Color(0.24, 0.34, 0.62, 0.28)
	if accent.a > 0.0:
		border = Color(accent.r, accent.g, accent.b, 0.42)
	panel.add_theme_stylebox_override("panel", box(Color(0.045, 0.071, 0.16, 0.96), 20, border, 1))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	return panel


static func label(text: String, size: int = 16, color: Color = TEXT, weight: int = 500) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	if weight >= 700:
		node.add_theme_constant_override("outline_size", 1)
		node.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.24))
	node.autowrap_mode = TextServer.AUTOWRAP_WORD
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func heading(text: String, size: int = 24) -> Label:
	return label(text, size, TEXT, 800)


static func overline(text: String, color: Color = CYAN) -> Label:
	var node := label(text.to_upper(), 11, color, 800)
	node.add_theme_constant_override("letter_spacing", 2)
	return node


static func button(
	text: String, accent: Color = CYAN, filled: bool = false, compact: bool = false
) -> Button:
	var node := Button.new()
	node.text = text
	node.focus_mode = Control.FOCUS_NONE
	node.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.custom_minimum_size = Vector2(0.0, 50.0 if compact else 62.0)
	node.add_theme_font_size_override("font_size", 15 if compact else 17)
	node.add_theme_color_override("font_color", TEXT if filled else accent)
	node.add_theme_color_override("font_hover_color", TEXT)
	node.add_theme_color_override("font_pressed_color", TEXT)
	node.add_theme_color_override("font_disabled_color", Color(MUTED.r, MUTED.g, MUTED.b, 0.45))
	var normal_color := Color(accent.r, accent.g, accent.b, 0.16 if filled else 0.07)
	var normal_border := Color(accent.r, accent.g, accent.b, 0.72 if filled else 0.38)
	var normal := box(normal_color, 14, normal_border, 1)
	normal.content_margin_left = 16.0
	normal.content_margin_right = 16.0
	var hover := box(Color(accent.r, accent.g, accent.b, 0.26), 14, accent, 1)
	var pressed := box(Color(accent.r, accent.g, accent.b, 0.36), 14, accent.lightened(0.12), 1)
	var disabled := box(Color(0.15, 0.18, 0.28, 0.25), 14, Color(0.3, 0.34, 0.46, 0.22), 1)
	node.add_theme_stylebox_override("normal", normal)
	node.add_theme_stylebox_override("hover", hover)
	node.add_theme_stylebox_override("pressed", pressed)
	node.add_theme_stylebox_override("focus", hover)
	node.add_theme_stylebox_override("disabled", disabled)
	return node


static func progress(
	value: float, max_value: float, accent: Color = CYAN, height: float = 8.0
) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = maxf(1.0, max_value)
	bar.value = clampf(value, 0.0, bar.max_value)
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.custom_minimum_size.y = height
	var background := box(Color(0.18, 0.23, 0.39, 0.5), int(height / 2.0))
	background.content_margin_left = 0.0
	background.content_margin_right = 0.0
	background.content_margin_top = 0.0
	background.content_margin_bottom = 0.0
	var fill := box(accent, int(height / 2.0))
	fill.content_margin_left = 0.0
	fill.content_margin_right = 0.0
	fill.content_margin_top = 0.0
	fill.content_margin_bottom = 0.0
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


static func separator(color: Color = Color(0.28, 0.38, 0.62, 0.2)) -> HSeparator:
	var line := HSeparator.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.content_margin_top = 0.5
	style.content_margin_bottom = 0.5
	line.add_theme_stylebox_override("separator", style)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line


static func h_space(width: float) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size.x = width
	return spacer


static func v_space(height: float) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = height
	return spacer


static func margin(
	child: Control, left: int = 18, top: int = 0, right: int = 18, bottom: int = 0
) -> MarginContainer:
	var wrapper := MarginContainer.new()
	wrapper.add_theme_constant_override("margin_left", left)
	wrapper.add_theme_constant_override("margin_top", top)
	wrapper.add_theme_constant_override("margin_right", right)
	wrapper.add_theme_constant_override("margin_bottom", bottom)
	wrapper.add_child(child)
	return wrapper


static func stat_chip(caption: String, value: String, accent: Color = CYAN) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override(
		"panel",
		box(Color(0.08, 0.12, 0.25, 0.88), 15, Color(accent.r, accent.g, accent.b, 0.24), 1)
	)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 2)
	var cap := overline(caption, MUTED)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var val := label(value, 16, TEXT, 800)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(cap)
	content.add_child(val)
	panel.add_child(content)
	return panel


static func badge(text: String, accent: Color = CYAN) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel",
		box(
			Color(accent.r, accent.g, accent.b, 0.11),
			10,
			Color(accent.r, accent.g, accent.b, 0.28),
			1
		)
	)
	var tag := label(text.to_upper(), 11, accent, 800)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(tag)
	return panel
