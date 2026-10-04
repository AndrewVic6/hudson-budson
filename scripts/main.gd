extends Node3D
const Crosshair = preload("res://scripts/crosshair.gd")
const Art = preload("res://scripts/art.gd")
const Inventory = preload("res://scripts/inventory.gd")
const Locker = preload("res://scripts/locker.gd")
const Settings = preload("res://scripts/settings.gd")
const PlayerScript = preload("res://scripts/player.gd")
const ZombieScript = preload("res://scripts/zombie.gd")
var mouse_sensitivity: float = 1.0
var hit_flash: float = 0
var damage_flash: float = 0
var weapon_motion: bool = true
var reticle: Control
var inventory = Inventory.new()
var lockers: Array = []
var nearest_locker: Node3D
var inventory_label: Label
var prompt_label: Label
var armor_label: Label
var exit_label: Label3D
var distraction_time: float = 0
var distraction_position := Vector3.ZERO
var ball_mesh: Node3D
var audio: AudioStreamPlayer
var player: CharacterBody3D
var zombies: Array = []
var camera: Camera3D
var hooked: CharacterBody3D
var fishing_line: MeshInstance3D
var zombie_speed: float = Settings.ZOMBIE_SPEED
var pull_speed: float = Settings.PULL_SPEED
var knockback: float = Settings.KNOCKBACK
var defeated: int = 0
var mortification: int = 0
var boost_time: float = 0
var embarrass_cooldown: float = 0
var ended: bool = false
var hud: Label
var status: Label
var toast_label: Label
var health_bar: ProgressBar
var mort_bar: ProgressBar
var pause_panel: PanelContainer
var end_panel: PanelContainer
var end_title: Label
var toast_time: float = 0
var exit_gate: MeshInstance3D
var lab_open: bool = false

func _ready() -> void:
	setup_input()
	build_school()
	build_player()
	for pos in [Vector3(0, 1, -1), Vector3(-2, 1, -8), Vector3(2, 1, -12), Vector3(-1, 1, -18), Vector3(3, 1, -21)]:
		spawn_zombie(pos)
	build_camera()
	build_ui()
	audio = AudioStreamPlayer.new()
	add_child(audio)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	toast("Mouse looks. WASD moves. Aim at locker 101 on your left, then press C.")

func setup_input() -> void:
	var keys := {"left": KEY_A, "right": KEY_D, "forward": KEY_W, "back": KEY_S,
		"jump": KEY_SPACE, "sprint": KEY_SHIFT, "attack": KEY_F, "hook": KEY_Q,
		"reel": KEY_E, "embarrass": KEY_T, "restart": KEY_R, "lab": KEY_TAB, "search": KEY_C, "eat": KEY_H,
		"throw": KEY_G, "slot1": KEY_1, "slot2": KEY_2, "slot3": KEY_3}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		var event := InputEventKey.new()
		event.physical_keycode = keys[action]
		InputMap.action_add_event(action, event)
	for pair in [["attack", MOUSE_BUTTON_LEFT], ["hook", MOUSE_BUTTON_RIGHT]]:
		var event := InputEventMouseButton.new()
		event.button_index = pair[1]
		InputMap.action_add_event(pair[0], event)

func material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	return mat

func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, solid: bool = false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = material(color)
	parent.add_child(mesh)
	mesh.position = pos
	if solid:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		mesh.add_child(body)
		var collider := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size
		collider.shape = bounds
		body.add_child(collider)
	return mesh

func sign_text(text_value: String, pos: Vector3, size: int = 60) -> void:
	var label := Label3D.new()
	label.text = text_value
	label.font_size = size
	label.pixel_size = 0.01
	label.modulate = Color("fbf0d5")
	label.outline_size = 6
	add_child(label)
	label.position = pos

func build_school() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("263e4c")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("d7e6ec")
	env.environment.ambient_light_energy = 0.28
	env.environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58, -32, 0)
	sun.light_energy = 0.65
	sun.shadow_enabled = true
	add_child(sun)
	var ceiling := box(self,Vector3(0,3.5,-6),Vector3(12,.18,38),Color("a8b7b1"),true)
	ceiling.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	box(self,Vector3(0,1.65,13),Vector3(12,3.3,.3),Color("3b6970"),true)
	for z in range(-22,13,4):
		box(self,Vector3(0,3.36,z),Vector3(2.4,.1,.55),Color("415965"))
		var fixture := box(self,Vector3(0,3.29,z),Vector3(2.16,.025,.36),Color("edf2d3"))
		fixture.material_override = Art.mat(Color("edf2d3"),true)
		for x in range(-5,6,2):
			box(self,Vector3(x,3.397,z),Vector3(.025,.018,4),Color("849b9a"))
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(0,3.15,z)
		lamp.light_color = Color("d6e5e0")
		lamp.light_energy = .5
		lamp.omni_range = 5
		add_child(lamp)
	box(self, Vector3(0, -0.3, -6), Vector3(12, 0.6, 38), Color("768d91"), true)
	for zi in range(19):
		for xi in range(6):
			box(self, Vector3(-5+xi*2, 0.005, -24+zi*2), Vector3(1.97, 0.015, 1.97), Color("89978d") if (xi+zi)%2==0 else Color("6c827b"))
	for x in [-6, 6]:
		box(self, Vector3(x, 1.55, -6), Vector3(0.25, 3.1, 38), Color("e1d5b9"), true)
		box(self, Vector3(x-signf(x)*0.15, 0.6, -6), Vector3(0.1, 1.2, 38), Color("3b6970"))
		box(self, Vector3(x-signf(x)*0.15, 1.23, -6), Vector3(0.12, 0.1, 38), Color("dea963"))
		for z in [6.5,-5.5,-17.5]:
			var door := Node3D.new()
			add_child(door)
			door.position = Vector3(x-signf(x)*0.17,0,z)
			door.rotation.y = PI/2 if x<0 else -PI/2
			Art.cube(door,Vector3(0,1.35,0),Vector3(1.5,2.7,.14),Color("243f49"))
			Art.cube(door,Vector3(0,1.3,.09),Vector3(1.3,2.5,.1),Color("ba8b54"))
			Art.cube(door,Vector3(0,1.85,.15),Vector3(.85,.7,.04),Color("6fa3ae"))
			Art.cube(door,Vector3(.59,1.05,.16),Vector3(.1,.25,.08),Color("e5d9ab"))
			Art.words(door,"SCIENCE" if z<0 else "HOMEROOM",Vector3(0,2.85,.16),27)
	var loot := ["bat","apple","backpack","tennis_ball","sandwich","racket","notebook","juice","sneakers","apple","tennis_ball","sandwich","hall_pass","notebook","juice","backpack"]
	for row in range(8):
		for side in range(2):
			var locker := Node3D.new()
			locker.set_script(Locker)
			locker.game = self
			locker.number = 101+row*2+side
			locker.item_id = loot[row*2+side]
			add_child(locker)
			locker.position = Vector3(-5.35 if side==0 else 5.35,0,8-row*4)
			locker.rotation.y = PI/2 if side==0 else -PI/2
			locker.build()
			lockers.append(locker)
			# Extra cabinet beside each searchable locker gives the hallway a school rhythm.
			var cabinet := Node3D.new()
			add_child(cabinet)
			cabinet.position = locker.position + Vector3(0,0,1.25)
			cabinet.rotation.y = locker.rotation.y
			Art.cube(cabinet,Vector3(0,1.3,0),Vector3(1.08,2.6,.65),Color("456a70"))
			for y in [2.05,2.17,2.29]:
				Art.cube(cabinet,Vector3(0,y,.334),Vector3(.65,.025,.025),Color("233e48"))
			Art.cube(cabinet,Vector3(.36,1.25,.36),Vector3(.05,.22,.06),Color("c0d1ce"))
	box(self,Vector3(0,1.65,-25),Vector3(12,3.3,.3),Color("3b6970"),true)
	box(self,Vector3(0,.4,13),Vector3(12,.8,.3),Color("3b6970"),true)
	box(self,Vector3(0,.03,-22),Vector3(4,.04,3),Color("dec17b"))
	exit_gate = box(self,Vector3(0,1.4,-24.75),Vector3(3,2.8,.12),Color("b48451"))
	for x in [-.8,.8]:
		box(self,Vector3(x,1.85,-24.65),Vector3(.9,.8,.07),Color("679aa2"))
	box(self,Vector3(0,1.2,-24.6),Vector3(2.7,.09,.1),Color("e1d6b2"))
	exit_label = Art.words(self,"EXIT  /  FIND A HALL PASS",Vector3(0,3.08,-24.5),35)
	for z in [10,-2,-14]:
		for side in [-1,1]:
			var board := Node3D.new()
			add_child(board)
			board.position = Vector3(side*5.79,2.1,z)
			board.rotation.y = PI/2 if side<0 else -PI/2
			Art.cube(board,Vector3.ZERO,Vector3(1.2,1.2,.1),Color("bc9463"))
			Art.cube(board,Vector3(0,0,.06),Vector3(1.08,1.08,.03),Color("eee0b9"))
			Art.words(board,"GO\nBADGERS!" if side<0 else "NO\nRUNNING",Vector3(0,0,.1),24,Color("344e58"))
	for z in range(-21,12,6):
		box(self,Vector3(-2,.026,z),Vector3(.06,.02,2),Color("d7bd7c"))
		box(self,Vector3(2,.026,z),Vector3(.06,.02,2),Color("d7bd7c"))
		var paper := box(self,Vector3(3 if z%2 else -3,.04,z+.7),Vector3(.45,.025,.6),Color("ddd8bc"))
		paper.rotation.y = z*.3
		for x in [-5.8,5.8]:
			var light := OmniLight3D.new()
			light.position = Vector3(x,3,z)
			light.light_color = Color("ffd99e")
			light.light_energy = .3
			light.omni_range = 4
			add_child(light)

func body_shape(body: CharacterBody3D) -> void:
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	body.add_child(collision)
	body.collision_layer = 2
	body.collision_mask = 1

func character_visual(body: CharacterBody3D, zombie: bool) -> Node3D:
	return Art.character(body,zombie,zombies.size())

func build_player() -> void:
	player = CharacterBody3D.new()
	player.set_script(PlayerScript)
	player.name = "Hudson"
	player.game = self
	add_child(player)
	player.position = Vector3(0, 0.1, 7)
	body_shape(player)
	player.visual = character_visual(player, false)
	player.visual.hide()
	fishing_line = MeshInstance3D.new()
	add_child(fishing_line)

func spawn_zombie(pos: Vector3) -> CharacterBody3D:
	var zombie := CharacterBody3D.new()
	zombie.set_script(ZombieScript)
	zombie.game = self
	zombie.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(zombie)
	zombie.position = pos
	body_shape(zombie)
	zombie.visual = character_visual(zombie, true)
	zombies.append(zombie)
	return zombie

func build_camera() -> void:
	camera = Camera3D.new()
	camera.fov = 80
	camera.near = .035
	camera.far = 100
	player.add_child(camera)
	camera.position = Vector3(0,1.62,0)
	camera.current = true
	player.build_first_person(camera)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not lab_open and not ended and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
		player.look(event.relative,mouse_sensitivity)
		get_viewport().set_input_as_handled()

func set_paused(value: bool) -> void:
	lab_open = value
	pause_panel.visible = value
	get_tree().paused = value
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED
	reticle.visible = not value and not ended

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(pause_panel) and not ended:
		set_paused(true)

func aim_direction() -> Vector3:
	return -camera.global_basis.z

func clear_sight(target: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(camera.global_position,target,1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _process(delta: float) -> void:
	# This node also runs while the tuning panel pauses the world.
	if Input.is_action_just_pressed("restart"):
		get_tree().paused = false
		get_tree().reload_current_scene()
		return
	if Input.is_action_just_pressed("lab") or Input.is_action_just_pressed("ui_cancel"):
		if not ended:
			set_paused(not lab_open)
			return
	if lab_open:
		return
	if not ended:
		update_interaction()
		if Input.is_action_just_pressed("search"): search_locker()
		if Input.is_action_just_pressed("eat"): eat_food()
		if Input.is_action_just_pressed("throw"): throw_ball()
		for i in range(3):
			if Input.is_action_just_pressed("slot%d" % (i+1)): equip_weapon(["tray","bat","racket"][i])
	distraction_time = maxf(0,distraction_time-delta)
	if distraction_time <= 0 and is_instance_valid(ball_mesh):
		ball_mesh.queue_free()
	hit_flash = maxf(0,hit_flash-delta)
	damage_flash = maxf(0,damage_flash-delta)
	boost_time = maxf(0, boost_time - delta)
	embarrass_cooldown = maxf(0, embarrass_cooldown - delta)
	toast_time = maxf(0, toast_time - delta)
	toast_label.visible = toast_time > 0
	player.rod.visible = is_instance_valid(hooked)
	if is_instance_valid(hooked):
		if player.position.distance_to(hooked.position) > Settings.HOOK_RANGE + 3:
			release_hook()
	update_line()
	health_bar.value = player.health
	mort_bar.value = mortification
	hud.text = "HALL PASS FOUND  /  REACH THE EXIT" if inventory.hall_pass else "SEARCH LOCKERS  /  FIND THE HALL PASS"
	status.text = "PANIC SPEED  %.1fs" % boost_time if boost_time>0 else ("HOOKED  /  Hold E to reel" if is_instance_valid(hooked) else "%d / 16 lockers  •  %d / 5 zombies" % [inventory.collected,defeated])
	inventory_label.text = "%s  [LMB / F]     FOOD %d  [H]     BALLS %d  [G]" % [inventory.stats().name.to_upper(),inventory.food.size(),inventory.balls]
	armor_label.text = "BACKPACK %d  %s" % [inventory.armor,"• FAST SHOES" if inventory.sneakers else ""]
	if not ended and inventory.hall_pass and player.position.z < -21 and absf(player.position.x)<2.5:
		finish(true)

func toggle_hook() -> void:
	if is_instance_valid(hooked):
		release_hook()
		return
	var best: CharacterBody3D
	var alignment := .94
	for zombie in zombies:
		if not is_instance_valid(zombie) or not zombie.active: continue
		var target: Vector3 = zombie.global_position+Vector3(0,1.25,0)
		var offset: Vector3 = target-camera.global_position
		var dot: float = aim_direction().dot(offset.normalized())
		if offset.length()<=Settings.HOOK_RANGE and dot>alignment and clear_sight(target):
			best = zombie
			alignment = dot
	if best:
		hooked = best
		hooked.hooked = true
		toast("CAUGHT ONE. Hold E to reel. Left click to swing.")
	else: toast("Aim at a zombie within reach, then press Q or right click.")

func release_hook() -> void:
	if is_instance_valid(hooked):
		hooked.hooked = false
	hooked = null

func update_line() -> void:
	fishing_line.visible = is_instance_valid(hooked)
	if not fishing_line.visible:
		return
	var start: Vector3 = camera.to_global(Vector3(-.3,-.02,-.8))
	var end: Vector3 = hooked.position + Vector3(0, 1.3, 0)
	var line := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("ffdc76")
	line.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	line.surface_add_vertex(start)
	line.surface_add_vertex(end)
	line.surface_end()
	fishing_line.mesh = line

func tray_attack() -> void:
	var hit_any := false
	var stats: Dictionary = inventory.stats()
	for zombie in zombies:
		if not is_instance_valid(zombie) or not zombie.active: continue
		var offset: Vector3 = zombie.position-player.position
		offset.y = 0
		var target: Vector3 = zombie.global_position+Vector3(0,1.2,0)
		var aim_offset: Vector3 = target-camera.global_position
		if offset.length()<stats.reach and aim_direction().dot(aim_offset.normalized())>.55 and clear_sight(target):
			zombie.hit(stats.damage,offset.normalized(),stats.knock)
			hit_any = true
			hit_flash = .18
			pop_text("BONK!" if inventory.equipped=="bat" else "WHACK!",zombie.position+Vector3(0,2.15,0),Color("f4ce73"))
	sound("hit" if hit_any else "swing")

func zombie_defeated(zombie: CharacterBody3D) -> void:
	if hooked == zombie: release_hook()
	defeated += 1
	toast("Zombie down! Keep searching for your hall pass." if not inventory.hall_pass else "Nice swing! The exit is ready.")

func update_interaction() -> void:
	nearest_locker = null
	var origin: Vector3 = camera.global_position
	var query := PhysicsRayQueryParameters3D.create(origin,origin+aim_direction()*2.75,1)
	var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty() and result.collider.has_meta("locker"):
		nearest_locker = result.collider.get_meta("locker")
	for locker in lockers: locker.set_near(locker==nearest_locker)
	prompt_label.text = ("LOCKER %d  /  SEARCHED" if nearest_locker.opened else "[C] OPEN LOCKER %d") % nearest_locker.number if nearest_locker else ""

func search_locker() -> void:
	update_interaction()
	if nearest_locker:
		if not nearest_locker.open_locker(): toast("Already searched. Try another locker.")
	else: toast("Look at a numbered locker within arm's reach, then press C.")

func collect_item(id: String) -> void:
	inventory.add_item(id)
	var hint := ""
	match Inventory.ITEMS[id].kind:
		"weapon": player.update_weapon(); hint = "Equipped! Press F to swing."
		"food": hint = "Saved for later. H eats when you're hurt."
		"distraction": hint = "G throws a ball to distract zombies."
		"armor": player.update_accessories(); hint = "+30 protection."
		"speed": player.update_accessories(); hint = "20% faster movement."
		"comedy":
			mortification += 25
			if mortification>=100: mortification=0; boost_time=6
			hint = "Your crush's name... everywhere. +25 mortification!"
		"key":
			exit_gate.material_override = material(Color("6dbb99"))
			exit_label.text = "EXIT  /  HALL PASS APPROVED"
			hint = "Head to the green exit pad!"
	toast("FOUND: %s. %s" % [Inventory.ITEMS[id].name,hint])


func equip_weapon(id: String) -> void:
	if inventory.equip(id):
		player.update_weapon()
		toast("Equipped: "+inventory.stats().name)
	else: toast("Find that weapon in a locker first.")

func eat_food() -> void:
	var result: Dictionary = inventory.eat(player.health)
	if result.used=="":
		toast("Health is full. Save your snacks!" if player.health>=100 else "No food yet. Search more lockers.")
		return
	var healed: int = result.health-player.health
	player.health = result.health
	toast("Ate %s. +%d health." % [Inventory.ITEMS[result.used].name,healed])
	pop_text("+%d HEALTH" % healed,camera.global_position+aim_direction()*1.7,Color("7fdeb1"))
	sound("eat")

func throw_ball() -> void:
	if inventory.balls<=0: toast("Find tennis balls in a locker first."); return
	inventory.balls -= 1
	distraction_position = player.position+player.facing*7
	distraction_position.x = clampf(distraction_position.x,-4.4,4.4)
	distraction_position.z = clampf(distraction_position.z,-23,11)
	distraction_position.y = .15
	var throw_query := PhysicsRayQueryParameters3D.create(camera.global_position,distraction_position,1)
	var throw_hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(throw_query)
	if not throw_hit.is_empty():
		distraction_position = throw_hit.position+throw_hit.normal*.22
		distraction_position.y = maxf(.15,distraction_position.y)
	distraction_time = 7
	if is_instance_valid(ball_mesh): ball_mesh.queue_free()
	ball_mesh = Art.item(self,"tennis_ball")
	ball_mesh.global_position = camera.to_global(Vector3(.2,-.2,-.5))
	var tween := create_tween()
	tween.tween_property(ball_mesh,"position",distraction_position,.55).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	toast("FETCH! Nearby zombies chase the ball for 7 seconds.")
	sound("throw")

func pop_text(value: String, pos: Vector3, tint: Color) -> void:
	var text := Art.words(self,value,pos,29,tint)
	text.scale = Vector3.ONE*.65
	text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	text.no_depth_test = true
	var tween := create_tween().set_parallel(true)
	tween.tween_property(text,"position",pos+Vector3(0,1.4,0),1.2)
	tween.tween_property(text,"modulate:a",0.0,1.2)
	tween.chain().tween_callback(text.queue_free)

func sound(kind: String) -> void:
	if not is_instance_valid(audio): return
	var frequencies := {"locker": 190.0,"hit":100.0,"swing":340.0,"eat":620.0,"throw":470.0,"hurt":140.0}
	var freq: float = frequencies.get(kind,300.0)
	var data := PackedByteArray()
	for i in range(3300):
		var t: float = float(i)/22050
		var envelope: float = 1.0-float(i)/3300
		var value: int = int(sin(t*TAU*freq*(1.0-t*3))*envelope*5000)
		data.append(value & 255)
		data.append((value>>8) & 255)
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = 22050
	wave.data = data
	audio.stream = wave
	audio.play()

func embarrass() -> void:
	if embarrass_cooldown > 0 or ended:
		return
	embarrass_cooldown = 1
	mortification += 25
	toast("Hudson shouts: I MEANT TO WEAR THESE!")
	if mortification >= 100:
		mortification = 0
		boost_time = 6
		toast("ALL EYES ON ME! Six seconds of panic-powered speed.")

func toast(message: String) -> void:
	toast_label.text = message
	toast_time = 3.5

func finish(won: bool) -> void:
	if ended:
		return
	ended = true
	player.enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	reticle.hide()
	release_hook()
	end_panel.show()
	end_title.text = "HALL PASS: APPROVED.
You escaped in your boxers!
%d lockers searched. %d zombies bonked." % [inventory.collected,defeated] if won else "DETENTION. AGAIN.
Take another swing at it."

func label(parent: Node, text_value: String, font_size: int = 20) -> Label:
	var item := Label.new()
	item.text = text_value
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", Color("f6edda"))
	parent.add_child(item)
	return item

func panel(parent: Node, pos: Vector2, size: Vector2) -> PanelContainer:
	var item := PanelContainer.new()
	parent.add_child(item)
	item.position = pos
	item.size = size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.09, 0.14, 0.96)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	item.add_theme_stylebox_override("panel", style)
	return item

func bar(parent: Node, tint: Color) -> ProgressBar:
	var item := ProgressBar.new()
	item.custom_minimum_size = Vector2(210, 12)
	item.show_percentage = false
	var style := StyleBoxFlat.new()
	style.bg_color = tint
	item.add_theme_stylebox_override("fill", style)
	parent.add_child(item)
	return item

func build_ui() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	var layer := CanvasLayer.new()
	add_child(layer)
	reticle = Control.new()
	reticle.set_script(Crosshair)
	reticle.game = self
	reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(reticle)
	reticle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var top := panel(layer,Vector2(24,24),Vector2(550,112))
	var column := VBoxContainer.new()
	top.add_child(column)
	label(column,"HUDSON BUDSON  /  FIRST PERSON",23)
	hud = label(column,"",15)
	status = label(column,"",15)
	var vitals := panel(layer,Vector2(978,24),Vector2(278,149))
	var v := VBoxContainer.new()
	vitals.add_child(v)
	label(v,"HEALTH",13)
	health_bar = bar(v,Color("62c4b0"))
	label(v,"MORTIFICATION  /  T",13)
	mort_bar = bar(v,Color("efaa68"))
	armor_label = label(v,"",13)
	prompt_label = label(reticle,"",19)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_color_override("font_color",Color("f4ce73"))
	prompt_label.add_theme_color_override("font_shadow_color",Color("132832"))
	prompt_label.add_theme_constant_override("shadow_offset_x",2)
	prompt_label.add_theme_constant_override("shadow_offset_y",2)
	var bottom := panel(layer,Vector2(24,656),Vector2(1232,120))
	var b := VBoxContainer.new()
	bottom.add_child(b)
	inventory_label = label(b,"",18)
	toast_label = label(b,"",16)
	label(b,"MOUSE look   WASD move   SHIFT sprint   SPACE jump   C search   H eat   G throw",14)
	label(b,"LMB / F hit   RMB / Q hook   E reel   1 / 2 / 3 weapons   T embarrass   ESC / TAB pause   R restart",14)
	pause_panel = panel(layer,Vector2(345,65),Vector2(590,670))
	var lab := VBoxContainer.new()
	lab.add_theme_constant_override("separation",8)
	pause_panel.add_child(lab)
	label(lab,"PAUSED  /  THE TUNING LAB",26)
	label(lab,"Escape or Tab resumes and captures the mouse.",17)
	add_slider(lab,"Mouse sensitivity",.25,2.5,mouse_sensitivity,func(n): mouse_sensitivity=n,.05)
	add_slider(lab,"Field of view",65,100,camera.fov,func(n): camera.fov=n,1)
	add_slider(lab,"Hudson speed",2,14,player.speed,func(n): player.speed=n)
	add_slider(lab,"Zombie speed",0,5,zombie_speed,func(n): zombie_speed=n)
	add_slider(lab,"Fishing pull",1,12,pull_speed,func(n): pull_speed=n)
	add_slider(lab,"Weapon knockback",2,30,knockback,func(n): knockback=n)
	var motion := CheckButton.new()
	motion.text = "Gentle weapon motion (camera stays steady)"
	motion.button_pressed = weapon_motion
	motion.focus_mode = Control.FOCUS_NONE
	lab.add_child(motion)
	motion.toggled.connect(func(value): weapon_motion=value)
	var resume := Button.new()
	resume.text = "RESUME GAME"
	resume.custom_minimum_size.y = 44
	resume.focus_mode = Control.FOCUS_NONE
	lab.add_child(resume)
	resume.pressed.connect(func(): set_paused(false))
	label(lab,"Settings last this run. R restores defaults.",14)
	pause_panel.hide()
	end_panel = panel(layer,Vector2(300,265),Vector2(680,235))
	var e := VBoxContainer.new()
	end_panel.add_child(e)
	end_title = label(e,"",27)
	label(e,"Press R to start a fresh run.",18)
	end_panel.hide()

func add_slider(parent: Node, title: String, low: float, high: float, initial: float, callback: Callable, increment: float = .5) -> void:
	var text_label := label(parent, "%s: %.1f" % [title, initial], 17)
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = increment
	slider.value = initial
	slider.focus_mode = Control.FOCUS_NONE
	parent.add_child(slider)
	slider.value_changed.connect(func(value: float):
		text_label.text = "%s: %.1f" % [title, value]
		callback.call(value))
