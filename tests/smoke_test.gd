extends SceneTree
var failures: int = 0
var checks: int = 0
func check(ok: bool, message: String) -> void:
	checks+=1
	print(("PASS " if ok else "FAIL ")+message)
	if not ok: failures+=1
func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame
func aim(scene: Node3D,target: Vector3) -> void:
	var d: Vector3 = target-scene.camera.global_position
	scene.player.yaw=atan2(-d.x,-d.z)
	scene.player.pitch=atan2(d.y,Vector2(d.x,d.z).length())
	scene.player.apply_view()
func _initialize() -> void: call_deferred("run")
func run() -> void:
	if DisplayServer.get_name()=="headless":
		print("This suite tests mouse capture and must run with a graphical display.")
		quit(2)
		return
	var scene=load("res://scenes/Main.tscn").instantiate()
	root.add_child(scene)
	current_scene=scene
	await frames(12)
	scene.zombie_speed=0
	check(scene.zombies.size()==5 and scene.lockers.size()==16,"Original enemies and lockers preserved")
	check(scene.camera.get_parent()==scene.player and is_equal_approx(scene.camera.position.y,1.62),"Camera attached at eye height")
	check(not scene.player.visual.visible,"Player body hidden from first-person camera")
	check(Input.mouse_mode==Input.MOUSE_MODE_CAPTURED,"Mouse captured for play")
	var motion := InputEventMouseMotion.new()
	motion.relative=Vector2(100,20)
	Input.parse_input_event(motion)
	await frames(2)
	check(scene.player.yaw<-.1 and scene.player.pitch<0,"Mouse event turns and tilts camera")
	scene.player.look(Vector2(0,-100000),1)
	check(is_equal_approx(scene.player.pitch,deg_to_rad(80)),"Upward look is clamped")
	scene.player.look(Vector2(0,100000),1)
	check(is_equal_approx(scene.player.pitch,deg_to_rad(-80)),"Downward look is clamped")
	scene.player.yaw=PI/2
	scene.player.pitch=0
	scene.player.apply_view()
	var start: Vector3 = scene.player.position
	Input.action_press("forward")
	await frames(14)
	Input.action_release("forward")
	check(scene.player.position.x<start.x-.8 and absf(scene.player.position.z-start.z)<.1,"W moves relative to view heading")
	scene.player.position=Vector3(0,.05,7)
	await frames(2)
	Input.action_press("right")
	await frames(8)
	Input.action_release("right")
	check(scene.player.velocity.z<0 and is_equal_approx(scene.player.yaw,PI/2),"D strafes without turning the view")
	var heading: Vector3 = scene.player.facing
	Input.action_press("back")
	await frames(4)
	Input.action_release("back")
	check(scene.player.facing.is_equal_approx(heading),"Backpedaling keeps aim forward")
	Input.action_press("jump")
	await frames(8)
	Input.action_release("jump")
	check(scene.player.position.y>.3,"Space jumps")
	await frames(55)
	scene.player.position=Vector3(0,.05,8)
	aim(scene,Vector3(-4.95,1.4,8))
	await frames(2)
	scene.search_locker()
	check(scene.inventory.collected==0,"Cannot open distant locker")
	scene.player.position=Vector3(-3.8,.05,8)
	aim(scene,Vector3(0,1.4,8))
	await frames(2)
	scene.search_locker()
	check(scene.inventory.collected==0,"Nearby locker must be aimed at")
	aim(scene,Vector3(-4.95,1.4,8))
	await frames(2)
	Input.action_press("search")
	await frames(2)
	Input.action_release("search")
	check(scene.inventory.equipped=="bat" and scene.lockers[0].opened,"Crosshair plus C opens locker and equips bat")
	check(scene.player.tray.get_parent()==scene.player.weapon_anchor,"Equipped weapon appears in viewmodel")
	scene.search_locker()
	check(scene.inventory.collected==1,"Search cannot duplicate loot")
	await frames(30)
	check(absf(scene.lockers[0].door.rotation.y)>1,"Locker door animation completes")
	scene.player.position=Vector3(0,.05,7)
	var enemy=scene.zombies[0]
	enemy.position=Vector3(0,.05,4.3)
	aim(scene,enemy.position+Vector3(0,1.25,0))
	await frames(2)
	scene.player.attack()
	check(enemy.health==10 and scene.hit_flash>0,"Aimed bat hits and shows hit marker")
	check(is_equal_approx(enemy.knock.length(),scene.knockback*1.4),"Bat knockback preserved")
	scene.player.attack()
	check(enemy.health==10,"Attack cooldown prevents spam")
	enemy.knock=Vector3.ZERO
	enemy.health=50
	scene.player.attack_cooldown=0
	scene.player.pitch=deg_to_rad(80)
	scene.player.apply_view()
	scene.player.attack()
	check(enemy.health==50,"Looking away vertically does not hit zombie")
	aim(scene,enemy.position+Vector3(0,1.25,0))
	var wall=scene.box(scene,Vector3(0,1.5,5.6),Vector3(2,3,.2),Color.WHITE,true)
	await frames(2)
	scene.player.attack_cooldown=0
	scene.player.attack()
	scene.toggle_hook()
	check(enemy.health==50 and scene.hooked==null,"Walls block attacks and hooks")
	wall.queue_free()
	await frames(3)
	scene.toggle_hook()
	check(scene.hooked==enemy,"Crosshair hook selects visible aimed zombie")
	var distance: float = scene.player.position.distance_to(enemy.position)
	Input.action_press("reel")
	await frames(10)
	Input.action_release("reel")
	check(scene.player.position.distance_to(enemy.position)<distance-.3,"E reels hooked zombie")
	scene.release_hook()
	scene.collect_item("racket")
	enemy.position=Vector3(0,.05,4.5)
	enemy.health=50
	enemy.knock=Vector3.ZERO
	aim(scene,enemy.position+Vector3(0,1.25,0))
	scene.player.attack_cooldown=0
	scene.player.attack()
	check(enemy.health==30 and is_equal_approx(enemy.knock.length(),scene.knockback*1.9),"Racket damage and knockback preserved")
	scene.equip_weapon("tray")
	check(scene.inventory.equipped=="tray","Can switch back to starter tray")
	scene.collect_item("apple")
	scene.player.health=100
	scene.eat_food()
	check(scene.inventory.food.size()==1,"Full health preserves food")
	scene.player.health=90
	scene.eat_food()
	check(scene.player.health==100 and scene.inventory.food.is_empty(),"Food heals and is consumed")
	scene.collect_item("backpack")
	scene.player.hurt_cooldown=0
	scene.player.hurt(40)
	check(scene.player.health==90 and scene.inventory.armor==0 and scene.damage_flash>0,"Backpack and damage feedback work")
	scene.player.hurt(10)
	check(scene.player.health==90,"Damage immunity cooldown preserved")
	scene.collect_item("sneakers")
	Input.action_press("forward")
	await frames(2)
	Input.action_release("forward")
	check(is_equal_approx(Vector2(scene.player.velocity.x,scene.player.velocity.z).length(),scene.player.speed*1.2),"Sneakers increase movement speed")
	scene.collect_item("tennis_ball")
	scene.throw_ball()
	await frames(2)
	check(scene.inventory.balls==2 and enemy.distracted,"Tennis balls consume one and distract zombies")
	scene.distraction_time=.01
	await frames(5)
	check(not enemy.distracted and not is_instance_valid(scene.ball_mesh),"Distraction expires")
	scene.mortification=75
	scene.collect_item("notebook")
	check(scene.boost_time==6,"Notebook activates speed boost")
	scene.set_paused(true)
	var old: Vector3 = enemy.position
	var old_yaw: float = scene.player.yaw
	Input.parse_input_event(motion)
	for i in range(5): await process_frame
	check(paused and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE and enemy.position==old,"Pause releases mouse and freezes enemies")
	check(scene.player.yaw==old_yaw,"Mouse cannot turn camera while paused")
	scene.set_paused(false)
	check(not paused and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED,"Resume captures mouse")
	scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(paused and scene.pause_panel.visible,"Switching away automatically pauses")
	scene.set_paused(false)
	scene.player.position=Vector3(0,.05,-22)
	await frames(2)
	check(not scene.ended,"Exit requires hall pass")
	scene.collect_item("hall_pass")
	await frames(2)
	check(scene.ended and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"Hall pass escape wins and releases cursor")
	Input.action_press("restart")
	await frames(4)
	Input.action_release("restart")
	check(current_scene.inventory.collected==0 and not current_scene.ended and current_scene.player.yaw==0,"Restart resets inventory and camera heading")
	check(InputMap.action_get_events("attack").size()==2,"Restart preserves single keyboard and mouse bindings")
	current_scene.player.hurt_cooldown=0
	current_scene.player.hurt(100)
	check(current_scene.ended and current_scene.end_title.text.begins_with("DETENTION"),"Defeat screen works")
	current_scene.queue_free()
	await process_frame
	await process_frame
	print("RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
