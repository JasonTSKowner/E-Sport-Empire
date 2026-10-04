class_name EmpireUI
extends RefCounted

const BG := Color("080A0D")
const SURFACE := Color("101318")
const SURFACE_2 := Color("151A20")
const SURFACE_3 := Color("1B2128")
const TEXT := Color("F5F7FA")
const MUTED := Color("98A3B3")
const DIM := Color("647082")
const CYAN := Color("7FE7FF")
const PURPLE := Color("B59CFF")
const GREEN := Color("5DE1A5")
const RED := Color("FF6B7A")
const GOLD := Color("E8C17A")


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
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.12)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0.0, 1.0)
	style.anti_aliasing = true
	return style


static func card(accent: Color = Color.TRANSPARENT) -> PanelContainer:
	var panel := PanelContainer.new()
	var border := Color(0.55, 0.63, 0.72, 0.09)
	if accent.a > 0.0:
		border = Color(accent.r, accent.g, accent.b, 0.12)
	var style := box(Color(0.050, 0.059, 0.071, 0.99), 10, border, 1)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 13.0
	style.content_margin_bottom = 13.0
	style.shadow_size = 0
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	return panel


static func label(text: String, size: int = 16, color: Color = TEXT, weight: int = 500) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	if weight >= 700:
		node.add_theme_constant_override("outline_size", 0)
	# Never fall back to character-by-character wrapping on narrow phones.
	# Long copy wraps only at word boundaries throughout the app.
	node.autowrap_mode = TextServer.AUTOWRAP_WORD
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func heading(text: String, size: int = 24) -> Label:
	return label(text, size, TEXT, 800)


static func overline(text: String, color: Color = CYAN) -> Label:
	var node := label(text.to_upper(), 10, color, 800)
	node.add_theme_constant_override("letter_spacing", 1)
	return node


static func button(
	text: String, accent: Color = CYAN, filled: bool = false, compact: bool = false
) -> Button:
	var node := Button.new()
	node.text = text
	node.focus_mode = Control.FOCUS_NONE
	node.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	node.mouse_filter = Control.MOUSE_FILTER_PASS
	node.keep_pressed_outside = false
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.custom_minimum_size = Vector2(0.0, 54.0 if compact else 64.0)
	node.add_theme_font_size_override("font_size", 15 if compact else 17)
	node.add_theme_color_override("font_color", TEXT if filled else accent)
	node.add_theme_color_override("font_hover_color", TEXT)
	node.add_theme_color_override("font_pressed_color", TEXT)
	node.add_theme_color_override("font_disabled_color", Color(MUTED.r, MUTED.g, MUTED.b, 0.45))
	var normal_color := Color(accent.r, accent.g, accent.b, 0.16 if filled else 0.035)
	var normal_border := Color(accent.r, accent.g, accent.b, 0.44 if filled else 0.16)
	var normal := box(normal_color, 8, normal_border, 1)
	normal.content_margin_left = 16.0
	normal.content_margin_right = 16.0
	var hover := box(Color(accent.r, accent.g, accent.b, 0.08), 8, Color(accent.r, accent.g, accent.b, 0.22), 1)
	var pressed := box(Color(accent.r, accent.g, accent.b, 0.14), 8, Color(accent.r, accent.g, accent.b, 0.36), 1)
	pressed.content_margin_top = 15.0
	pressed.content_margin_bottom = 13.0
	var disabled := box(Color(0.12, 0.14, 0.17, 0.46), 8, Color(0.35, 0.38, 0.44, 0.07), 1)
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
	var background := box(Color(0.10, 0.12, 0.16, 0.95), int(height / 2.0))
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


static func hero(accent: Color = CYAN) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := box(Color(0.052, 0.062, 0.075, 0.995), 12, Color(0.55, 0.63, 0.72, 0.10), 1)
	style.border_width_top = 2
	style.border_color = Color(accent.r, accent.g, accent.b, 0.38)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 16.0
	style.content_margin_bottom = 16.0
	style.shadow_size = 0
	panel.add_theme_stylebox_override("panel", style)
	return panel


static func metric_tile(caption: String, value: String, accent: Color = CYAN) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := box(Color(0.058, 0.066, 0.078, 0.98), 8, Color(0.55, 0.62, 0.70, 0.07), 1)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 9.0
	style.content_margin_bottom = 9.0
	panel.add_theme_stylebox_override("panel", style)
	var box_node := VBoxContainer.new()
	box_node.add_theme_constant_override("separation", 2)
	var value_label := label(value, 15 if value.length() < 10 else 12, TEXT, 800)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var caption_label := label(caption.to_upper(), 8, Color(accent.r, accent.g, accent.b, 0.88), 800)
	caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box_node.add_child(value_label)
	box_node.add_child(caption_label)
	panel.add_child(box_node)
	return panel


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
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override(
		"panel",
		box(Color(0.075, 0.09, 0.115, 0.98), 13, Color(accent.r, accent.g, accent.b, 0.13), 1)
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
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override(
		"panel",
		box(
			Color(accent.r, accent.g, accent.b, 0.055),
			6,
			Color(accent.r, accent.g, accent.b, 0.11),
			1
		)
	)
	var tag := label(text.to_upper(), 9, accent, 800)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(tag)
	return panel
