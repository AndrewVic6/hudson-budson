extends CharacterBody3D
const Settings = preload("res://scripts/settings.gd")
const Art = preload("res://scripts/art.gd")
var health: int = Settings.ZOMBIE_HEALTH
var game: Node3D
var visual: Node3D
var knock := Vector3.ZERO
var active: bool = true
var hooked: bool = false
var stun: float = 0
var phase: float = 0
var distracted: bool = false

func _physics_process(delta: float) -> void:
	if not active or game.ended: return
	stun = maxf(0,stun-delta)
	var player_offset: Vector3 = game.player.global_position-global_position
	player_offset.y = 0
	var offset := player_offset
	distracted = not hooked and game.distraction_time>0 and global_position.distance_to(game.distraction_position)<12
	if distracted:
		offset = game.distraction_position-global_position
		offset.y = 0
	var direction := offset.normalized()
	var motion := Vector3.ZERO
	if hooked and Input.is_action_pressed("reel") and offset.length()>1.5:
		motion = direction*game.pull_speed
	elif not hooked and stun<=0 and offset.length()<15 and offset.length()>.6:
		motion = direction*game.zombie_speed
	velocity.x = motion.x+knock.x
	velocity.z = motion.z+knock.z
	knock = knock.move_toward(Vector3.ZERO,delta*18)
	if not is_on_floor(): velocity.y -= delta*22
	else: velocity.y=0
	move_and_slide()
	if direction.length()>0: visual.rotation.y=atan2(-direction.x,-direction.z)
	phase += delta*5
	Art.animate(visual,phase,minf(motion.length(),1),true)
	visual.rotation.z = sin(stun*35)*stun*.25
	if player_offset.length()<1.3 and stun<=0 and not distracted: game.player.hurt(10)

func hit(damage: int, direction: Vector3, force: float = 1.0) -> void:
	if not active: return
	health -= damage
	knock = direction*game.knockback*force
	stun=.6
	if health<=0:
		active=false
		game.zombie_defeated(self)
		collision_layer=0
		collision_mask=0
		var tween := create_tween()
		tween.tween_property(visual,"scale",Vector3(1.4,.08,1.4),.25)
		tween.tween_interval(.2)
		tween.tween_callback(queue_free)
