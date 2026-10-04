extends RefCounted
# Original low-poly meshes, assembled in Godot. No downloads or art plug-ins.
static func mat(color: Color, glow: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.8
	if glow:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 0.5
	return m

static func mesh(parent: Node3D, shape: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = shape
	n.material_override = mat(color)
	parent.add_child(n)
	n.position = pos
	return n

static func cube(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	return mesh(parent, shape, pos, color)

static func sphere(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radius = 0.5
	shape.height = 1.0
	shape.radial_segments = 12
	shape.rings = 6
	var n := mesh(parent, shape, pos, color)
	n.scale = size
	return n

static func cylinder(parent: Node3D, pos: Vector3, radius: float, length: float, color: Color, top: float = -1) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = radius if top < 0 else top
	shape.bottom_radius = radius
	shape.height = length
	shape.radial_segments = 10
	return mesh(parent, shape, pos, color)

static func words(parent: Node3D, value: String, pos: Vector3, size: int = 38, color: Color = Color("ece5d4")) -> Label3D:
	var n := Label3D.new()
	n.text = value
	n.font_size = size
	n.pixel_size = 0.008
	n.modulate = color
	n.outline_size = 2
	parent.add_child(n)
	n.position = pos
	return n

static func character(body: Node3D, zombie: bool, variation: int = 0) -> Node3D:
	var root := Node3D.new()
	body.add_child(root)
	var skin := Color("8ba982") if zombie else Color("d1a17d")
	var shirt: Color = [Color("536b82"),Color("806b81"),Color("79896a")][variation % 3] if zombie else skin
	var head := sphere(root, Vector3(0,1.75,0), Vector3(0.65,0.64,0.57), skin)
	head.rotation.z = 0.09 if zombie else 0
	sphere(root, Vector3(0,2.03,0.06), Vector3(0.69,0.18,0.61), Color("34443e") if zombie else Color("64432f"))
	for x in [-0.31,0.31]: sphere(root,Vector3(x,1.72,0),Vector3(0.14,0.075,0.11),skin)
	for x in [-0.13,0.13]:
		sphere(root,Vector3(x,1.79,-0.268),Vector3(0.11,0.06,0.045),Color("e4dca6"))
		sphere(root,Vector3(x,1.78,-0.294),Vector3(0.045,0.037,0.022),Color("26343c"))
	cube(root,Vector3(0,1.59,-0.273),Vector3(0.17,0.04,0.025),Color("655249"))
	cylinder(root,Vector3(0,1.2,0),0.33,0.64,shirt,0.27)
	cube(root,Vector3(0,0.81,0),Vector3(0.6,0.28,0.42),Color("344551") if zombie else Color("e7d8b3"))
	if not zombie:
		for x in [-0.22,0,0.22]: cube(root,Vector3(x,0.82,-0.217),Vector3(0.065,0.22,0.025),Color("bd6463"))
	for i in [-1,1]:
		var leg := Node3D.new()
		leg.name = "LegL" if i < 0 else "LegR"
		root.add_child(leg)
		leg.position = Vector3(i*0.19,0.75,0)
		cylinder(leg,Vector3(0,-0.3,0),0.105,0.55,Color("33444e") if zombie else skin)
		cube(leg,Vector3(0,-0.64,-0.09),Vector3(0.25,0.18,0.4),Color("263747"))
		cube(leg,Vector3(0,-0.73,-0.09),Vector3(0.26,0.055,0.41),Color("d5d3c0"))
		var arm := Node3D.new()
		arm.name = "ArmL" if i < 0 else "ArmR"
		root.add_child(arm)
		arm.position = Vector3(i*0.38,1.4,0)
		cylinder(arm,Vector3(0,-0.2,0),0.095,0.4,shirt)
		sphere(arm,Vector3(0,-0.44,0),Vector3(0.2,0.13,0.21),skin)
	return root

static func animate(root: Node3D, phase: float, amount: float, zombie: bool = false) -> void:
	root.get_node("LegL").rotation.x = sin(phase)*amount*0.65
	root.get_node("LegR").rotation.x = -sin(phase)*amount*0.65
	root.get_node("ArmL").rotation.x = -0.8 if zombie else -sin(phase)*amount*0.35
	root.get_node("ArmR").rotation.x = -0.8 if zombie else sin(phase)*amount*0.35
	root.position.y = abs(sin(phase))*amount*0.045

static func item(parent: Node3D, id: String) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	match id:
		"bat":
			cylinder(root,Vector3(0,0.35,0),0.085,0.8,Color("b88c54"),0.12)
			cylinder(root,Vector3(0,-0.22,0),0.045,0.35,Color("3a4345"))
		"racket":
			var ring := TorusMesh.new()
			ring.inner_radius=0.21;ring.outer_radius=0.25;ring.rings=16;ring.ring_segments=8
			var n := mesh(root,ring,Vector3(0,0.33,0),Color("56a8bb"))
			n.rotation.x=PI/2;n.scale.z=1.35
			for x in [-0.12,0,0.12]: cube(root,Vector3(x,0.33,0),Vector3(0.01,0.48,0.015),Color("d8d8b7"))
			cylinder(root,Vector3(0,-0.13,0),0.045,0.5,Color("e8c888"))
		"tray":
			cube(root,Vector3.ZERO,Vector3(0.65,0.07,0.85),Color("9dabb1"))
			for x in [-0.29,0.29]: cube(root,Vector3(x,0.055,0),Vector3(0.035,0.05,0.8),Color("bdc8c8"))
		"apple":
			sphere(root,Vector3.ZERO,Vector3(0.38,0.4,0.37),Color("c5493e"))
			cylinder(root,Vector3(0,0.24,0),0.025,0.12,Color("635439"))
			cube(root,Vector3(0.1,0.24,0),Vector3(0.16,0.025,0.09),Color("5e9453"))
		"sandwich":
			for pair in [[-0.09,Color("c4985c")],[0.0,Color("689856")],[0.045,Color("ba6b56")],[0.12,Color("c4985c")]]:
				cube(root,Vector3(0,pair[0],0),Vector3(0.5,0.065,0.42),pair[1])
		"juice":
			cube(root,Vector3.ZERO,Vector3(0.3,0.48,0.23),Color("db994d"))
			cube(root,Vector3(0,0,0.12),Vector3(0.21,0.23,0.02),Color("ede2c3"))
			cylinder(root,Vector3(0.08,0.34,0),0.015,0.25,Color("e3dac6"))
		"tennis_ball": sphere(root,Vector3.ZERO,Vector3(0.3,0.3,0.3),Color("bdcf5b"))
		"backpack":
			sphere(root,Vector3.ZERO,Vector3(0.6,0.76,0.28),Color("d98a51"))
			cube(root,Vector3(0,-0.12,0.13),Vector3(0.4,0.27,0.15),Color("a96740"))
		"sneakers":
			for x in [-0.17,0.17]:
				cube(root,Vector3(x,0,0),Vector3(0.25,0.16,0.5),Color("ddd8ba"))
				cube(root,Vector3(x,-0.09,0),Vector3(0.26,0.04,0.51),Color("57898b"))
		"notebook":
			cube(root,Vector3.ZERO,Vector3(0.42,0.1,0.56),Color("9d7baf"))
			cube(root,Vector3(0,0.058,0),Vector3(0.28,0.016,0.26),Color("eee1bf"))
		"hall_pass":
			cube(root,Vector3.ZERO,Vector3(0.53,0.07,0.3),Color("e4be6b"))
			words(root,"PASS",Vector3(0,0.1,0.16),24,Color("273b44"))
	return root
