class_name EmpireUI
extends RefCounted

const BrandSurfaceRef = preload("res://scripts/brand_surface.gd")
const APP_FONT = preload("res://assets/fonts/SpaceGrotesk.ttf")

const BG := Color("080B10")
const SURFACE := Color("0D1218")
const SURFACE_2 := Color("121820")
const SURFACE_3 := Color("18202A")
const TEXT := Color("F1F4F7")
const MUTED := Color("929CAA")
const DIM := Color("5D6672")
const CYAN := Color("74DFF7")
const PURPLE := Color("9DA8B7")
const GREEN := Color("5DE1A5")
const RED := Color("FF6B7A")
const GOLD := Color("D6B16B")


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
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.20)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0.0, 2.0)
	style.anti_aliasing = true
	return style


static func card(accent: Color = Color.TRANSPARENT) -> PanelContainer:
	var surface := BrandSurfaceRef.new()
	var use_accent := accent if accent.a > 0.0 else Color(0.72, 0.78, 0.86, 0.18)
	surface.configure(use_accent, "card")
	surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return surface

static func label(text: String, size: int = 16, color: Color = TEXT, weight: int = 500) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_override("font", APP_FONT)
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
	node.custom_minimum_size = Vector2(0.0, 44.0 if compact else 52.0)
	node.add_theme_font_override("font", APP_FONT)
	node.add_theme_font_size_override("font_size", 12 if compact else 14)
	node.add_theme_color_override("font_color", TEXT if filled else Color(0.88,0.91,0.95,0.90))
	node.add_theme_color_override("font_hover_color", TEXT)
	node.add_theme_color_override("font_pressed_color", TEXT)
	node.add_theme_color_override("font_disabled_color", Color(MUTED.r, MUTED.g, MUTED.b, 0.34))

	var normal_bg := Color(accent.r, accent.g, accent.b, 0.16) if filled else Color(0.055,0.070,0.090,0.94)
	var normal_border := Color(accent.r, accent.g, accent.b, 0.32) if filled else Color(0.72,0.78,0.86,0.08)
	var normal := box(normal_bg, 6, normal_border, 1)
	normal.shadow_size = 0
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	var hover := box(Color(accent.r, accent.g, accent.b, 0.18 if filled else 0.075), 6, Color(accent.r,accent.g,accent.b,0.28), 1)
	hover.shadow_size = 0
	var pressed := box(Color(accent.r, accent.g, accent.b, 0.24), 5, Color(accent.r,accent.g,accent.b,0.42), 1)
	pressed.shadow_size = 0
	var disabled := box(Color(0.055,0.064,0.076,0.70), 6, Color(0.72,0.78,0.86,0.05), 1)
	disabled.shadow_size = 0
	node.add_theme_stylebox_override("normal", normal)
	node.add_theme_stylebox_override("hover", hover)
	node.add_theme_stylebox_override("pressed", pressed)
	node.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
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
	var surface := BrandSurfaceRef.new()
	surface.configure(accent, "hero")
	surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return surface

static func metric_tile(caption: String, value: String, accent: Color = CYAN) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	var marker := ColorRect.new()
	marker.color = Color(accent.r, accent.g, accent.b, 0.72)
	marker.custom_minimum_size = Vector2(2, 28)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(marker)
	var box_node := VBoxContainer.new()
	box_node.add_theme_constant_override("separation", -1)
	var caption_label := label(caption.to_upper(), 7, DIM, 800)
	var value_label := label(value, 15 if value.length() < 10 else 11, TEXT, 800)
	box_node.add_child(caption_label)
	box_node.add_child(value_label)
	row.add_child(box_node)
	panel.add_child(row)
	return panel


static func tab(text: String, selected: bool, accent: Color = CYAN) -> Button:
	var node := Button.new()
	node.text = text
	node.focus_mode = Control.FOCUS_NONE
	node.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	node.mouse_filter = Control.MOUSE_FILTER_PASS
	node.custom_minimum_size.y = 38
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.add_theme_font_override("font", APP_FONT)
	node.add_theme_font_size_override("font_size", 10)
	node.add_theme_color_override("font_color", TEXT if selected else MUTED)
	node.add_theme_color_override("font_hover_color", TEXT)
	node.add_theme_color_override("font_pressed_color", TEXT)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color.TRANSPARENT
	normal.content_margin_top = 7
	normal.content_margin_bottom = 7
	normal.border_width_bottom = 2 if selected else 0
	normal.border_color = accent
	node.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.10,0.12,0.15,0.32)
	hover.content_margin_top = 7
	hover.content_margin_bottom = 7
	hover.border_width_bottom = 2 if selected else 1
	hover.border_color = Color(accent.r,accent.g,accent.b,0.55 if selected else 0.18)
	node.add_theme_stylebox_override("hover", hover)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(0.10,0.13,0.16,0.52)
	pressed.content_margin_top = 7
	pressed.content_margin_bottom = 7
	pressed.border_width_bottom = 2
	pressed.border_color = accent
	node.add_theme_stylebox_override("pressed", pressed)
	node.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return node

static func separator(color: Color = Color(0.72, 0.78, 0.86, 0.08)) -> HSeparator:
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
	var style := box(Color(0.045,0.055,0.068,0.96), 4, Color(accent.r,accent.g,accent.b,0.18), 1)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	style.shadow_size = 0
	panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var marker := ColorRect.new()
	marker.color = accent
	marker.custom_minimum_size = Vector2(3, 12)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(marker)
	var tag := label(text.to_upper(), 8, Color(0.86,0.89,0.93,0.88), 800)
	row.add_child(tag)
	panel.add_child(row)
	return panel