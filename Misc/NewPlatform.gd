extends StaticBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var vel_cal = Vector3(0,0,0) setget set_velocity, get_velocity
var alt_vel = Vector3(0,0,0)
var rot_vel = Vector3(0,0,0) setget set_rot, get_rot
var alt_rot = Vector3(0,0,0)
var fin_rot = Vector3(0,0,0)
var fin_vel = Vector3(0,0,0)
var mov_chk = false

func set_velocity(a):
	if vel_cal != a:
		#print(vel_cal - (-a))
		#print( -23 - (-23))
		#vel_cal = a
		alt_vel = vel_cal - (a)
		vel_cal = a
	elif vel_cal == a:
		alt_vel = Vector3(0,0,0)
	if a == Vector3(0,0,0):
		alt_vel = Vector3(0,0,0)
		pass
	pass

func get_velocity():
	
	return alt_vel

func set_rot(a):
	if rot_vel != a:
		alt_rot = rot_vel - (a)
		rot_vel = a
	pass

func get_rot():
	return alt_rot

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _physics_process(delta):
	
	#rotate_y(-0.01)
	
	set_velocity(global_transform.origin)
	set_rot(global_transform.basis.get_euler())
	fin_vel = get_velocity()
	fin_rot = get_rot()
	
	if get_node("Area").get_overlapping_bodies().size() > 0:
		print(str(get_node("Area").get_overlapping_bodies().size()-1)+" "+str($Count_Nodes.get_child_count()))
		pass
	
	#print($Count_Nodes.get_children())
	
#	for i in $Count_Nodes.get_children():
#		print(str(i.name)+" "+str(i.global_transform.origin))
	
	if $Count_Nodes.get_child_count() != get_node("Area").get_overlapping_bodies().size()-1:

		if $Count_Nodes.get_child_count() < get_node("Area").get_overlapping_bodies().size()-1:
			for i in get_node("Area").get_overlapping_bodies():
				var checker = i.name
				var valid = true
				if $Count_Nodes.get_children() != null:
					for c in $Count_Nodes.get_children():
						if checker == c.name:
							valid = false
						else:
							pass
				else:
					pass
				
				if valid == false:
					pass
				elif valid == true:
					if "is_moving" in i:
						var child = Position3D.new()
						child.name = checker
						if i.is_moving:
							#child.global_transform.origin = i.global_transform.origin
							child.global_transform.origin = i.get_node("Pre_Stop").global_transform.origin
							$Count_Nodes.add_child(child)
						else:
							if i.get_node("FloorCast").is_colliding():
								child.global_transform.origin = i.get_node("Pre_Stop").global_transform.origin
								if i.get_node("FloorCast").get_collider() != self:
									#child.global_transform.origin = i.global_transform.origin
									
									#child.global_transform.origin = i.get_node("Pre_Stop").global_transform.origin
									
									$Count_Nodes.add_child(child)
									pass
						#$Count_Nodes.add_child(child)
					
			pass

		elif $Count_Nodes.get_child_count() > get_node("Area").get_overlapping_bodies().size()-1:
			var headCount = []
			for i in $Count_Nodes.get_children():
				headCount.append(i)
			for x in get_node("Area").get_overlapping_bodies():
				for i in headCount:
					if x.name == i.name:
						headCount.erase(i)
					else:
						pass
			for r in headCount:
				for x in $Count_Nodes.get_children():
					if r.name == x.name:
						x.queue_free()
					else:
						pass
			headCount.clear()
			pass

		pass

	elif $Count_Nodes.get_child_count() <= 0:
		for i in $Count_Nodes.get_children():
			i.queue_free()
		pass
	
	if get_node("Area").get_overlapping_bodies().size() >= 0:
		for i in get_node("Area").get_overlapping_bodies():
			for c in $Count_Nodes.get_children():
				if i.name == c.name:
					if "is_moving" in i:
						if i.is_moving == true:
							mov_chk = true
							#c.global_transform.origin = i.global_transform.origin
							c.global_transform.origin = i.get_node("Pre_Stop").global_transform.origin
						else:
							if mov_chk == true:
								#c.global_transform.origin = i.global_transform.origin
								c.global_transform.origin = i.get_node("Pre_Stop").global_transform.origin
								mov_chk = false
							pass
					pass
				else:
					pass
	
	
	pass
