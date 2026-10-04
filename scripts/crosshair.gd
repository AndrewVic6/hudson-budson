extends Control
var game: Node3D
func _process(_delta: float) -> void:
	if is_instance_valid(game.prompt_label):
		game.prompt_label.position = size*.5+Vector2(-240,32)
		game.prompt_label.size = Vector2(480,28)
	queue_redraw()
func _draw() -> void:
	var center := size*.5
	var tint := Color("f4ce73") if game.nearest_locker else Color("eff5ee")
	draw_circle(center,4,Color(0.04,.08,.1,.9))
	draw_circle(center,2,tint)
	for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		draw_line(center+direction*7,center+direction*12,Color(0.04,.08,.1,.8),4)
		draw_line(center+direction*7,center+direction*12,tint,2)
	if game.hit_flash>0:
		for direction in [Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1)]:
			draw_line(center+direction*14,center+direction*22,Color("f4ce73"),3)
	if game.damage_flash>0:
		var color := Color(.65,.18,.12,game.damage_flash*.8)
		draw_rect(Rect2(Vector2.ZERO,size),color,false,22)
