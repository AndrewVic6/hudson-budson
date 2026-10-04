extends CharacterBody3D
const Settings = preload("res://scripts/settings.gd")
const Art = preload("res://scripts/art.gd")
var speed: float = Settings.PLAYER_SPEED
var health: int = Settings.PLAYER_HEALTH
var facing := Vector3.FORWARD
var visual: Node3D
var tray: Node3D
var camera: Camera3D
var weapon_anchor: Node3D
var rod: Node3D
var attack_cooldown: float = 0
var hurt_cooldown: float = 0
var swing_time: float = 0
var phase: float = 0
var yaw: float = 0
var pitch: float = 0
var enabled: bool = true
var game: Node3D

func build_first_person(view: Camera3D) -> void:
	camera = view
	weapon_anchor = Node3D.new()
	camera.add_child(weapon_anchor)
	weapon_anchor.position = Vector3(.4,-.24,-.85)
	update_weapon()
	rod = Node3D.new()
	camera.add_child(rod)
	rod.position = Vector3(-.34,-.39,-.7)
	Art.cylinder(rod,Vector3(0,.25,0),.015,.95,Color("d4b174"))
	Art.sphere(rod,Vector3(0,-.15,0),Vector3(.15,.17,.18),Color("d1a17d"))
	rod.rotation.z = -.18
	prepare_viewmodel(rod)
	rod.hide()

func prepare_viewmodel(node: Node) -> void:
	if node is MeshInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Close-up items stay visible instead of disappearing inside a nearby cabinet.
		var mat: StandardMaterial3D = node.material_override
		mat.no_depth_test = true
		mat.render_priority = 4
	for child in node.get_children(): prepare_viewmodel(child)

func look(relative: Vector2, sensitivity: float) -> void:
	yaw -= relative.x*.002*sensitivity
	pitch = clampf(pitch-relative.y*.002*sensitivity,deg_to_rad(-80),deg_to_rad(80))
	apply_view()

func apply_view() -> void:
	rotation.y = yaw
	camera.rotation.x = pitch
	facing = -global_basis.z
	facing.y = 0
	facing = facing.normalized()

func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(0,attack_cooldown-delta)
	hurt_cooldown = maxf(0,hurt_cooldown-delta)
	swing_time = maxf(0,swing_time-delta)
	if not enabled: return
	var direction := Input.get_vector("left","right","forward","back")
	var movement: Vector3 = global_basis*Vector3(direction.x,0,direction.y)
	var multiplier: float = 1.4 if game.boost_time>0 else 1.0
	if game.inventory.sneakers: multiplier*=1.2
	if Input.is_action_pressed("sprint"): multiplier*=1.5
	velocity.x = movement.x*speed*multiplier
	velocity.z = movement.z*speed*multiplier
	if not is_on_floor(): velocity.y-=22*delta
	elif Input.is_action_just_pressed("jump"): velocity.y=7.5
	move_and_slide()
	phase+=delta*10*multiplier
	var bob: float = sin(phase)*.008*movement.length() if game.weapon_motion else 0.0
	weapon_anchor.position=Vector3(.4,-.24+bob,-.85)
	# Only the hands move: no camera shake or forced head bob.
	var swing: float = sin((1.0-swing_time/.3)*PI) if swing_time>0 else 0.0
	weapon_anchor.rotation=Vector3(-swing*.45,0,swing*1.15)
	weapon_anchor.position.x-=swing*.28
	weapon_anchor.position.z-=swing*.12
	if Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
		if Input.is_action_just_pressed("attack"): attack()
		if Input.is_action_just_pressed("hook"): game.toggle_hook()
		if Input.is_action_just_pressed("embarrass"): game.embarrass()
	if position.y < -5: game.finish(false)

func attack() -> void:
	if attack_cooldown>0 or not enabled: return
	attack_cooldown = game.inventory.stats().cooldown
	swing_time = .3
	game.tray_attack()

func update_weapon() -> void:
	if not is_instance_valid(weapon_anchor): return
	if is_instance_valid(tray):
		weapon_anchor.remove_child(tray)
		tray.queue_free()
	tray = Art.item(weapon_anchor,game.inventory.equipped)
	tray.scale = Vector3.ONE*.55
	tray.rotation.z = -.22
	if game.inventory.equipped=="tray":
		tray.rotation_degrees=Vector3(45,-10,-15)
		tray.position.y=-.06
	var hand := Art.sphere(tray,Vector3(0,-.22,.035),Vector3(.2,.22,.2),Color("d1a17d"))
	if game.inventory.equipped=="tray": hand.position=Vector3(.25,-.05,.22)
	var arm := Art.cylinder(tray,Vector3(.02,-.47,.14),.08,.42,Color("d1a17d"))
	arm.rotation.x=-.5
	prepare_viewmodel(tray)

func update_accessories() -> void:
	# Armor and shoe effects remain in the inventory; the HUD shows their status.
	pass

func hurt(amount: int) -> void:
	if hurt_cooldown>0 or not enabled: return
	var damage: int = game.inventory.absorb(amount)
	health=maxi(0,health-damage)
	hurt_cooldown=1
	game.damage_flash=.35
	game.toast("Backpack cushioned the hit!" if damage==0 else "OW! H eats a snack. Left click swings your weapon.")
	game.sound("hurt")
	if health==0: game.finish(false)
