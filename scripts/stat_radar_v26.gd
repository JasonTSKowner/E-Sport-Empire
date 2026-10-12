class_name StatRadarV26
extends Control

const FONT = preload("res://assets/fonts/SpaceGrotesk.ttf")

var values := {"MECH":50,"SHOT":50,"DEF":50,"SENSE":50}
var accent := Color("74DFF7")

func configure(stats: Dictionary, color: Color) -> StatRadarV26:
	values = stats.duplicate(true)
	accent = color
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()
	return self

func _ready() -> void:
	custom_minimum_size = Vector2(126,126)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x,size.y) * 0.36
	var labels := ["MECH","SHOT","DEF","SENSE"]
	var dirs := [Vector2(0,-1),Vector2(1,0),Vector2(0,1),Vector2(-1,0)]
	for ring in [0.33,0.66,1.0]:
		var pts := PackedVector2Array()
		for dir in dirs:
			pts.append(center + dir * radius * ring)
		pts.append(pts[0])
		draw_polyline(pts, Color(0.68,0.80,0.88,0.10), 1.0)
	for dir in dirs:
		draw_line(center, center + dir*radius, Color(0.68,0.80,0.88,0.09), 1.0)
	var data := PackedVector2Array()
	for i in range(4):
		var v := clampf(float(values.get(labels[i],50))/100.0,0.08,1.0)
		data.append(center + dirs[i] * radius * v)
	draw_colored_polygon(data, Color(accent.r,accent.g,accent.b,0.17))
	var closed := data.duplicate()
	closed.append(data[0])
	draw_polyline(closed, Color(accent.r,accent.g,accent.b,0.78), 1.8)
	for p in data:
		draw_circle(p,2.5,Color(accent.r,accent.g,accent.b,0.92))
	for i in range(4):
		var p := center + dirs[i] * (radius + 12.0)
		var offset := Vector2(-18,3)
		if i == 1: offset = Vector2(-5,3)
		elif i == 3: offset = Vector2(-31,3)
		elif i == 0: offset = Vector2(-18,-4)
		draw_string(FONT,p+offset,labels[i],HORIZONTAL_ALIGNMENT_CENTER,36,7,Color(0.70,0.78,0.86,0.68))
