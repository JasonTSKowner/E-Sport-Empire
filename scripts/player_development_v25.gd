class_name PlayerDevelopmentV25
extends Control

const FONT = preload("res://assets/fonts/SpaceGrotesk.ttf")

var accent := Color("74DFF7")
var unlocked_count: int = 0
var signature_label: String = "BASICS"
var signature_mastery: int = 0
var next_label: String = "NEXT MECHANIC"
var next_progress: int = 0
var mechanics: int = 50
var game_sense: int = 50
var consistency: int = 50
var pulse: float = 0.0

func configure(color: Color, unlocked: int, signature: String, mastery: int, upcoming: String, upcoming_progress: int, mech_stat: int, sense_stat: int, consistency_stat: int) -> PlayerDevelopmentV25:
	accent = color
	unlocked_count = maxi(0, unlocked)
	signature_label = signature.to_upper()
	signature_mastery = clampi(mastery,0,100)
	next_label = upcoming.to_upper()
	next_progress = clampi(upcoming_progress,0,100)
	mechanics = clampi(mech_stat,0,100)
	game_sense = clampi(sense_stat,0,100)
	consistency = clampi(consistency_stat,0,100)
	custom_minimum_size = Vector2(0, 190)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	queue_redraw()
	return self

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func _draw() -> void:
	var r := Rect2(Vector2.ZERO,size)
	for i in range(12):
		var t: float = float(i)/11.0
		var c: Color = Color("0F151D").lerp(Color("04070B"),t)
		draw_rect(Rect2(0,r.size.y*t,r.size.x,r.size.y/11.0+2),c,true)
	draw_line(Vector2(0,1),Vector2(r.size.x,1),Color(accent.r,accent.g,accent.b,0.20),1.0)
	draw_circle(Vector2(r.size.x*0.82,r.size.y*0.20),r.size.x*0.26,Color(accent.r,accent.g,accent.b,0.018+sin(pulse)*0.004))

	draw_string(FONT,Vector2(14,23),"MECHANICAL IDENTITY",HORIZONTAL_ALIGNMENT_LEFT,170,8,Color(accent.r,accent.g,accent.b,0.88))
	draw_string(FONT,Vector2(r.size.x-96,23),"%d UNLOCKS"%unlocked_count,HORIZONTAL_ALIGNMENT_RIGHT,82,8,Color(0.70,0.78,0.85,0.80))

	var left_w: float = r.size.x*0.46
	draw_string(FONT,Vector2(14,55),signature_label,HORIZONTAL_ALIGNMENT_LEFT,left_w-20,18,Color(0.95,0.97,1.0,0.98))
	draw_string(FONT,Vector2(14,72),"SIGNATURE MECHANIC",HORIZONTAL_ALIGNMENT_LEFT,left_w-20,6,Color(0.48,0.56,0.64,0.80))
	draw_arc(Vector2(left_w-30,57),22,0,TAU,42,Color(1,1,1,0.07),4.0)
	var end_angle: float = -PI/2.0 + TAU*float(signature_mastery)/100.0
	draw_arc(Vector2(left_w-30,57),22,-PI/2.0,end_angle,42,Color(accent.r,accent.g,accent.b,0.76),4.0)
	draw_string(FONT,Vector2(left_w-50,61),"%d"%signature_mastery,HORIZONTAL_ALIGNMENT_CENTER,40,10,Color(0.94,0.97,1.0,0.94))

	var divider_x: float = left_w+5
	draw_line(Vector2(divider_x,39),Vector2(divider_x,114),Color(1,1,1,0.05),1.0)
	_draw_bar(Vector2(divider_x+14,45),"MECH",mechanics,r.size.x-divider_x-28)
	_draw_bar(Vector2(divider_x+14,70),"READ",game_sense,r.size.x-divider_x-28)
	_draw_bar(Vector2(divider_x+14,95),"CONS",consistency,r.size.x-divider_x-28)

	var node_y: float = 132.0
	var start_x: float = 20.0
	var end_x: float = r.size.x-20.0
	draw_line(Vector2(start_x,node_y),Vector2(end_x,node_y),Color(1,1,1,0.07),2.0)
	var thresholds: Array[int] = [55,65,75,85,95]
	for i in range(thresholds.size()):
		var x: float = lerpf(start_x,end_x,float(i)/float(thresholds.size()-1))
		var done: bool = mechanics >= thresholds[i]
		var dot_color: Color = Color(accent.r,accent.g,accent.b,0.86) if done else Color("28313B")
		draw_circle(Vector2(x,node_y),5.0,dot_color)
		draw_string(FONT,Vector2(x-16,node_y+17),str(thresholds[i]),HORIZONTAL_ALIGNMENT_CENTER,32,6,Color(0.55,0.63,0.70,0.72))

	var bottom_y: float = r.size.y-24.0
	draw_string(FONT,Vector2(14,bottom_y),"NEXT",HORIZONTAL_ALIGNMENT_LEFT,30,6,Color(0.48,0.56,0.64,0.80))
	draw_string(FONT,Vector2(49,bottom_y),next_label,HORIZONTAL_ALIGNMENT_LEFT,r.size.x-110,8,Color(0.82,0.88,0.93,0.90))
	draw_string(FONT,Vector2(r.size.x-52,bottom_y),"%d%%"%next_progress,HORIZONTAL_ALIGNMENT_RIGHT,38,8,Color(accent.r,accent.g,accent.b,0.90))

func _draw_bar(pos: Vector2,label: String,value: int,width: float) -> void:
	draw_string(FONT,pos,label,HORIZONTAL_ALIGNMENT_LEFT,42,6,Color(0.52,0.60,0.68,0.82))
	draw_string(FONT,pos+Vector2(width-28,0),str(value),HORIZONTAL_ALIGNMENT_RIGHT,28,7,Color(0.86,0.91,0.95,0.90))
	draw_rect(Rect2(pos+Vector2(0,8),Vector2(width,3)),Color(1,1,1,0.055),true)
	draw_rect(Rect2(pos+Vector2(0,8),Vector2(width*float(value)/100.0,3)),Color(accent.r,accent.g,accent.b,0.58),true)
