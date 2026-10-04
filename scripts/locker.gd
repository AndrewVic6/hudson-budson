extends Node3D
const Art = preload("res://scripts/art.gd")
const Inventory = preload("res://scripts/inventory.gd")
var game: Node3D
var number: int = 101
var item_id: String = "apple"
var opened: bool = false
var door: Node3D
var loot: Node3D
var marker: Label3D
var front: MeshInstance3D
var normal_material: StandardMaterial3D
var highlight_material: StandardMaterial3D

func build() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var c := Color("345e6c") if number % 3 != 0 else Color("a07945")
	Art.cube(self,Vector3(0,1.35,-0.33),Vector3(1.05,2.65,0.12),Color("253b46"))
	for x in [-0.53,0.53]: Art.cube(self,Vector3(x,1.35,0),Vector3(0.07,2.7,0.75),c)
	for y in [0.08,0.85,2.65]: Art.cube(self,Vector3(0,y,0),Vector3(1.12,0.06,0.75),c)
	# Solid cabinet stays stationary; the animated door cannot trap the player.
	var body := StaticBody3D.new()
	add_child(body)
	body.set_meta("locker",self)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new();box.size=Vector3(1.12,2.7,0.75)
	shape.shape=box;shape.position.y=1.35;body.add_child(shape)
	door=Node3D.new();add_child(door);door.position=Vector3(-0.5,0,0.4)
	front=Art.cube(door,Vector3(0.5,1.35,0),Vector3(1,2.5,0.055),c)
	normal_material=front.material_override
	highlight_material=Art.mat(c.lightened(0.24),true)
	Art.cube(door,Vector3(0.84,1.25,0.075),Vector3(0.05,0.28,0.1),Color("a7b3b1"))
	for y in [1.85,1.96,2.07]: Art.cube(door,Vector3(0.5,y,0.039),Vector3(0.47,0.022,0.016),Color("1d3440"))
	Art.cube(door,Vector3(0.5,2.36,0.04),Vector3(0.4,0.15,0.025),Color("d0c9ac"))
	Art.words(door,str(number),Vector3(0.5,2.37,0.062),20,Color("233842"))
	# A few ordinary locker decorations stay inside after the useful item is gone.
	for i in range(3): Art.cube(self,Vector3(-0.32+i*0.13,0.35,-0.13),Vector3(0.095,0.45,0.32),[Color("a78864"),Color("766a88"),Color("788d6d")][i])
	loot=Art.item(self,item_id);loot.position=Vector3(0,1.22,0.07);loot.scale=Vector3.ONE*0.65
	marker=Art.words(self,"",Vector3(0,3.02,0.2),25)
	marker.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	marker.no_depth_test=true

func set_near(nearby: bool) -> void:
	front.material_override=highlight_material if nearby and not opened else normal_material
	marker.text = "" # The first-person prompt appears by the crosshair.

func open_locker() -> bool:
	if opened or game.ended: return false
	opened=true
	var tween:=create_tween()
	tween.tween_property(door,"rotation:y",-1.85,0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	game.collect_item(item_id)
	game.sound("locker")
	# Show the real item rising out of the cabinet before it goes into the bag.
	var pop:=create_tween().set_parallel(true)
	pop.tween_property(loot,"position",Vector3(0,1.65,.7),.65)
	pop.tween_property(loot,"rotation:y",TAU,0.65)
	pop.chain().tween_interval(.6)
	pop.chain().tween_property(loot,"scale",Vector3.ZERO,0.18)
	return true
