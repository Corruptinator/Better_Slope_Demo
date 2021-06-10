extends KinematicBody

# uses code from Jayanam
# https://www.youtube.com/watch?v=kc-zJnRvPUY
# UPDATE: This code was found from Joseph's Zelda Camera Movement (2019 MIT licence)
# similar to the code link mentioned above.

# Heavily Modified to work on Slopes using global_transform.basis for alternate gravity direction

var movedir = Vector3(0,0,0)
var velocity = Vector3()
var spd_vel = Vector3()
var grv_vel = Vector3()
var con_vel = Vector2()
var gravity = -35
var camera
var character

const SPEED = 12
const ACCELERATION = 5
const DECELERATION = 10
const JUMP_HEIGHT = 10

var is_moving = false

var can_jump = false

var deadZone = 0.1
var rot_speed = 0
var mov_speed = 0
var side_speed = 0
var con_speed = 0
var camrot_h = 0
var camrot_v = 0

var floored = false
var ang_grav = false
var ang_gate = false
var prv_grv = Vector3(0,0,0)
var is_grnd = false
var new_grv = 0 setget set_gravity, get_gravity
var vel_cal = Vector3(0,0,0) setget set_velocity, get_velocity
var alt_vel = Vector3(0,0,0)
var dif_vel_cal = Vector3(0,0,0) setget set_dif_velocity, get_dif_velocity
var alt_dif_vel = Vector3(0,0,0)
var rot_vel = Vector3(0,0,0) setget set_rot, get_rot
var alt_rot = Vector3(0,0,0)
var grv_dif = 0
var ang_adj = 0
var alternate = 0
var rot_x_blk = false setget chk_x_rot
var old_x_rot = 0
var avatar_rot = Vector3()
var avatar_chk = false
var platform = false
var plat_vel = Vector3(0,0,0)
var plat_smth = 0
var plat_rot = Vector3(0,0,0)
var jumped = false
var plat_stab = false
var stable = Vector3(0,0,0)

var rot_cal = 0 setget set_rot_cal, get_rot_cal
var alt_cal = 0
var pre_stp_lmt = 1
var plat_chk = false



func set_gravity(a):
	if new_grv < a:
		#print("Positive")
		new_grv = a
		grv_dif = 1
	elif new_grv > a:
		#print("Negative")
		new_grv = a
		grv_dif = -1
	elif round(new_grv) == round(a):
		pass
	pass

func get_gravity():
	#print(abs(new_grv))
	pass



func set_velocity(a):
	if vel_cal != a:
		#print(vel_cal - (-a))
		#print( -23 - (-23))
		#vel_cal = a
		alt_vel = vel_cal - (a)
		vel_cal = a
	if a == Vector3(0,0,0):
		alt_vel = Vector3(0,0,0)
		pass
	pass

func get_velocity():
	
	return alt_vel

func set_dif_velocity(a):
	if dif_vel_cal != a:
		#print(vel_cal - (-a))
		#print( -23 - (-23))
		#vel_cal = a
		alt_dif_vel = dif_vel_cal - (a)
		dif_vel_cal = a
#	if a == Vector3(0,0,0):
#		alt_dif_vel = Vector3(0,0,0)
#		pass
	pass

func get_dif_velocity():
	
	return alt_dif_vel



func set_rot(a):
	if rot_vel != a:
		alt_rot = rot_vel - (a)
		rot_vel = a
	pass

func get_rot():
	return alt_rot



func chk_x_rot(a):
	if old_x_rot == 0:
		pass
	elif old_x_rot != a:
		rot_x_blk = true
	old_x_rot = a
	pass


func set_rot_cal(a):
	if rot_cal != a:
		alt_cal = rot_cal - (a)
		rot_cal = a
	pass

func get_rot_cal():
	return alt_cal



func _ready():
	character = get_node(".")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$CamRoot.set_as_toplevel(true)
	
	#dif_vel_cal = get_node("../../../Objects/Geometry/Path/PathFollow/Platform").global_transform.origin
	
	#$Rotation.set_as_toplevel(true)

func _input(event):
	if event is InputEventMouseMotion:
		camrot_h += -event.relative.x
		camrot_v += event.relative.y
		pass
	pass






func _physics_process(delta):

	# Rotating our camera by mouse controls (press Alt+ f4 to quit, just in case)
	camera = get_node("CamRoot/H/V/Camera").get_global_transform()
	

	if abs(Input.get_joy_axis(0,JOY_AXIS_2)) > deadZone:
		#print("Foward")
		camrot_h += -Input.get_joy_axis(0,JOY_AXIS_2) * 10
	else:
		pass

	if abs(Input.get_joy_axis(0,JOY_AXIS_3)) > deadZone:
		#print("Sideway")
		camrot_v += Input.get_joy_axis(0,JOY_AXIS_3) * 10
	else:
		pass

	$CamRoot.global_transform.origin = self.global_transform.origin
	$CamRoot/H.rotation_degrees = (Vector3(0,(camrot_h*(delta*20)),0))
	$CamRoot/H/V.rotation_degrees = (Vector3((camrot_v*(delta*20)),0,0))
	#$Rotation.global_transform.origin = self.global_transform.origin


	# Speed Movement and Jump

	# (Keyboard Controls)
	if Input.is_action_pressed("left"):
		side_speed = lerp(side_speed, 800, .1)
		is_moving = true
		pass
	elif Input.is_action_pressed("right"):
		side_speed = lerp(side_speed, -800, .1)
		is_moving = true
	else:
		side_speed = lerp(side_speed, 0, .1)
		#is_moving = false

	if Input.is_action_pressed("up"):
		mov_speed = lerp(mov_speed, 800, .1)
		is_moving = true
	elif Input.is_action_pressed("down"):
		mov_speed = lerp(mov_speed, -800, .1)
		is_moving = true
	else:
		mov_speed = lerp(mov_speed, 0, .1)
		#is_moving = false
	
	if not Input.is_action_pressed("left") and not Input.is_action_pressed("right") and not Input.is_action_pressed("up") and not Input.is_action_pressed("down") and not (abs(Input.get_joy_axis(0,JOY_AXIS_0)) > deadZone or abs(Input.get_joy_axis(0,JOY_AXIS_1)) > deadZone):
		is_moving = false
	
	var ground = get_node("FloorCast").get_collision_normal()
	var gnd_org = get_node("FloorCast").get_collision_point()

	# (Xbox Controller)
	if abs(Input.get_joy_axis(0,JOY_AXIS_0)) > deadZone:
		#print("Foward")
		con_speed = lerp(con_speed, 800, .1)
		con_vel.x = lerp(con_vel.x, -Input.get_joy_axis(0,JOY_AXIS_0) * 800, .1)
		is_moving = true
	else:
		con_vel.x = lerp(con_vel.x, 0, .1)

	if abs(Input.get_joy_axis(0,JOY_AXIS_1)) > deadZone:
		#print("Sideway")
		con_speed = lerp(con_speed, 800, .1)
		con_vel.y = lerp(con_vel.y, -Input.get_joy_axis(0,JOY_AXIS_1) * 800, .1)
		is_moving = true
	else:
		con_vel.y = lerp(con_vel.y, 0, .1)

	if abs(Input.get_joy_axis(0,JOY_AXIS_0)) < deadZone and abs(Input.get_joy_axis(0,JOY_AXIS_1)) < deadZone:
		con_speed = lerp(con_speed, 0, .1)


	# Keyboard and Controller velocities are combined
	spd_vel = ( (((global_transform.basis[2].normalized() * delta) * mov_speed) + ((global_transform.basis[0].normalized() * delta) * side_speed))  +  (((global_transform.basis[2].normalized() * delta) * con_vel.y) + ((global_transform.basis[0].normalized() * delta) * con_vel.x)) )


	# (Jump Controls, Both Keyboard and Xbox Controller)
	if Input.is_action_just_pressed("jump") and can_jump == true:
		grv_vel = (global_transform.basis[1].normalized() * delta) * 1500
		can_jump = false
	elif Input.is_joy_button_pressed(0,JOY_XBOX_A) and can_jump == true:
		grv_vel = (global_transform.basis[1].normalized() * delta) * 1500
		can_jump = false
	elif not Input.is_joy_button_pressed(0,JOY_XBOX_A) and can_jump == false:
		can_jump = true


	else:

	### IMPORTANT: This is how the slope code works!
	### It all depends on the Set_Gravity and Get_Gravity
	### to use the grv_dif variable to modify the gravity
	### velocity. Speed velocity (Movement) and Gravity Velocity
	### (Gravity) are separated for purposes of avoiding movement
	### collision issues, but are added back together in the 
	### move_and_slide_with_snap()

		if is_on_floor():
			can_jump = true
			if ang_gate == false:
				if grv_dif < 0:
					grv_vel = (global_transform.basis[1].normalized() * delta) * ((-ang_adj * 10) * (abs(mov_speed/400) + abs(con_speed/400) + abs(side_speed/400)))
				else:
					grv_vel = Vector3.ZERO
					pass
			else:
				grv_vel += (global_transform.basis[1].normalized() * delta) * gravity
		else:
			grv_vel += (global_transform.basis[1].normalized() * delta) * gravity


	# Used for the (Snapping) in the move_and_slide_with_snap,
	# positive 1 makes it stay on the ground, negative 1 is for jumping
	var stop
	if is_moving == false:
		if can_jump == false:
			stop = 1
		elif can_jump == true:
			stop = -1
	else:
		stop = 1


	#set_rot(get_node("../../../Objects/Geometry/Path/PathFollow/Platform").global_transform.basis.get_euler())
	#set_dif_velocity(get_node("../../../Objects/Geometry/Path/PathFollow/Platform").global_transform.origin)
	#set_dif_velocity(get_node("../../../Objects/Geometry/Path/PathFollow/Platform/Raycaster/Spinner/RayCast").get_collision_point())
	get_node("Label").text = str(get_dif_velocity())
	if platform == true:
		#plat_rot = -get_rot()
		#plat_vel = -get_dif_velocity()
		pass
	elif platform == false:
		plat_rot = Vector3(0,0,0)
		plat_vel = Vector3(0,0,0)

	# Moving our character (Also used to determine ground collision)
	#var slides = move_and_slide_with_snap(spd_vel + grv_vel, ground * stop, global_transform.basis.y * 800, true)
	var slides = move_and_slide_with_snap((spd_vel + grv_vel) + ((plat_vel * delta) * 14500), ground * stop, global_transform.basis.y * 800, true)
	#var slides = move_and_slide_with_snap((spd_vel + grv_vel) + ((plat_vel * delta) * 14250), ground * stop, global_transform.basis.y * 800, true)
	#var slides = move_and_slide_with_snap(((-get_dif_velocity() * delta) * 14250), ground * stop, global_transform.basis.y * 110, true)
	#var slides = move_and_slide_with_snap(spd_vel + grv_vel, get_floor_normal() * stop, global_transform.basis.y * 800, true)


	# Player origin base (Feet)
	var down = -global_transform.basis.y


	# Used to reverse gravity when you hit the ceiling
	if is_on_ceiling():
		#print("Ceiling!")
		grv_vel = grv_vel * -1

	#print(global_transform.basis.get_euler().normalized())
	#print(round(rad2deg(abs($Rotation.rotation.y))))
	
#	if (round(rad2deg(abs(rotation.y)))) >= 180:
#		print("Detect!")
#	else:
#		print("")






	# Freezes player rotation while moving
	if is_moving && !Input.is_key_pressed(KEY_SHIFT):
		set_rotation($CamRoot/H.global_transform.basis.get_euler())
		#set_rotation(lerp(rotation,$CamRoot/H.global_transform.basis.get_euler(),.9))

#	if !is_moving:
#		plat_smth += .25 
#		if plat_smth > 1:
#			plat_smth = 1
#	elif is_moving:
#		plat_smth -= .25 
#		if plat_smth < 0:
#			plat_smth = 0
	#print(plat_smth)
	
	#print(global_transform.xform(get_node("../../../Objects/Geometry/Path/PathFollow/Platform").global_transform.origin))
	
	if !is_moving:
		plat_smth = lerp(plat_smth,1,.1)
	elif is_moving:
		plat_smth = 0

	#plat_smth = plat_smth * delta


	if Input.is_mouse_button_pressed(2):
		if !Input.is_joy_button_pressed(0,JOY_R2):
			$Rotation.set_as_toplevel(true)
			avatar_chk = true
			avatar_rot = $Rotation.global_transform.basis.get_euler()
		if (Input.is_action_pressed("up") or Input.is_action_pressed("down") or Input.is_action_pressed("left") or Input.is_action_pressed("right")):
#			if avatar_chk == true:
#				$Rotation.rotation = avatar_rot
#				$Rotation.set_as_toplevel(false)
#				avatar_chk = false
			$Rotation.rotation.y = lerp_angle($Rotation.rotation.y ,$CamRoot/H.global_transform.basis.get_euler().y, delta * (50))
			$Rotation.global_transform.origin = global_transform.origin
			pass
		else:
			$Rotation.rotation.y = lerp_angle($Rotation.rotation.y ,$CamRoot/H.global_transform.basis.get_euler().y, delta * (50))
			$Rotation.global_transform.origin = global_transform.origin
		pass
	else:
		if Input.is_action_pressed("up") or Input.is_action_pressed("down") or Input.is_action_pressed("left") or Input.is_action_pressed("right"):
			
			if avatar_chk == true:
				$Rotation.rotation = avatar_rot
				$Rotation.set_as_toplevel(false)
				avatar_chk = false
			

			if Input.is_action_pressed("up") and Input.is_action_pressed("left"):
				$Rotation.rotation.y = lerp_angle($Rotation.rotation.y ,deg2rad(45), delta * (5))
				pass
			elif Input.is_action_pressed("up") and Input.is_action_pressed("right"):
				$Rotation.rotation.y = lerp_angle($Rotation.rotation.y ,deg2rad(-45), delta * (5))
				pass
			elif Input.is_action_pressed("down") and Input.is_action_pressed("left"):
				$Rotation.rotation.y = lerp_angle($Rotation.rotation.y ,deg2rad(135), delta * (5))
				pass
			elif Input.is_action_pressed("down") and Input.is_action_pressed("right"):
				$Rotation.rotation.y = lerp_angle($Rotation.rotation.y ,deg2rad(-135), delta * (5))
				pass

			elif Input.is_action_pressed("up"):
				$Rotation.rotation.y = lerp_angle($Rotation.rotation.y ,deg2rad(0), delta * (5))
				pass
			elif Input.is_action_pressed("down"):
				$Rotation.rotation.y = lerp_angle($Rotation.rotation.y ,deg2rad(180), delta * (5))
				pass
			elif Input.is_action_pressed("left"):
				$Rotation.rotation.y = lerp_angle($Rotation.rotation.y ,deg2rad(90), delta * (5))
				pass
			elif Input.is_action_pressed("right"):
				$Rotation.rotation.y = lerp_angle($Rotation.rotation.y ,deg2rad(-90), delta * (5))
				pass

			pass
		else:
			$Rotation.set_as_toplevel(true)
			$Rotation.global_transform.origin = global_transform.origin
			#$Rotation.global_transform.basis = global_transform.basis
			avatar_rot = $Rotation.global_transform.basis.get_euler()
			avatar_chk = true
			pass


	# Rotates when the controller joystick is tilted (Gamepad/Controller Only)
	if (Input.is_joy_button_pressed(0,JOY_R2)):
		if !Input.is_mouse_button_pressed(2):
			$Rotation.set_as_toplevel(true)
			avatar_chk = true
			avatar_rot = $Rotation.global_transform.basis.get_euler()
		if (abs(Input.get_joy_axis(0,JOY_AXIS_0)) > deadZone or abs(Input.get_joy_axis(0,JOY_AXIS_1)) > deadZone):
#			if avatar_chk == true:
#				$Rotation.rotation = avatar_rot
#				$Rotation.set_as_toplevel(false)
#				avatar_chk = false
			$Rotation.rotation.y = lerp_angle($Rotation.rotation.y ,$CamRoot/H.global_transform.basis.get_euler().y, delta * (50))
			$Rotation.global_transform.origin = global_transform.origin
			pass
		else:
			$Rotation.rotation.y = lerp_angle($Rotation.rotation.y ,$CamRoot/H.global_transform.basis.get_euler().y, delta * (50))
			$Rotation.global_transform.origin = global_transform.origin
	else:
		if (abs(Input.get_joy_axis(0,JOY_AXIS_0)) > deadZone or abs(Input.get_joy_axis(0,JOY_AXIS_1)) > deadZone):

			if avatar_chk == true:
				$Rotation.rotation = avatar_rot
				$Rotation.set_as_toplevel(false)
				avatar_chk = false

			var tlt_dis = Vector3.ZERO.distance_to(Vector3(Input.get_joy_axis(0,JOY_AXIS_0),0,Input.get_joy_axis(0,JOY_AXIS_1)))

			$Rotation.rotation.y = lerp_angle($Rotation.rotation.y ,(atan2(Input.get_joy_axis(0,JOY_AXIS_1),-Input.get_joy_axis(0,JOY_AXIS_0)) + deg2rad(90)), delta * (5 * tlt_dis))
			#$Rotation.rotation.y = lerp_angle($Rotation.rotation.y ,(atan2(Input.get_joy_axis(0,JOY_AXIS_1),-Input.get_joy_axis(0,JOY_AXIS_0)) + deg2rad(89)) * (tlt_dis * -Vector3(Input.get_joy_axis(0,JOY_AXIS_2),0,Input.get_joy_axis(0,JOY_AXIS_3)).normalized().x), .03)


			set_rotation($CamRoot/H.global_transform.basis.get_euler())
			#set_rotation(lerp(rotation,$CamRoot/H.global_transform.basis.get_euler(),.9))
			pass
		else:
			$Rotation.set_as_toplevel(true)
			$Rotation.global_transform.origin = global_transform.origin
			#$Rotation.global_transform.basis = global_transform.basis
			avatar_rot = $Rotation.global_transform.basis.get_euler()
			avatar_chk = true
			pass

	if $Rotation.is_set_as_toplevel():
		$Rotation.rotation += plat_rot


#	if (Input.is_joy_button_pressed(0,JOY_R2) or Input.is_mouse_button_pressed(2)):
#		$Rotation.set_as_toplevel(true)
#		avatar_chk = true
#		avatar_rot = $Rotation.global_transform.basis.get_euler()
#		pass
#	else:
#		pass


#	if ( (abs(Input.get_joy_axis(0,JOY_AXIS_0)) > deadZone or abs(Input.get_joy_axis(0,JOY_AXIS_1)) > deadZone) or (Input.is_action_pressed("up") or Input.is_action_pressed("down") or Input.is_action_pressed("left") or Input.is_action_pressed("right")) ):
#
#		if avatar_chk == true:
#			$Rotation.rotation = avatar_rot
#			$Rotation.set_as_toplevel(false)
#			avatar_chk = false
#
#	else:
#
#		$Rotation.set_as_toplevel(true)
#		$Rotation.global_transform.origin = global_transform.origin
#		#$Rotation.global_transform.basis = global_transform.basis
#		avatar_rot = $Rotation.global_transform.basis.get_euler()
#		avatar_chk = true

	if Input.is_action_pressed("up") or Input.is_action_pressed("down") or Input.is_action_pressed("left") or Input.is_action_pressed("right"):
		
		if Input.is_action_pressed("up") and Input.is_action_pressed("left"):
			$Pre_Stop.transform.origin = lerp($Pre_Stop.transform.origin, Vector3(1,0,1) * pre_stp_lmt ,.1)
			pass
		elif Input.is_action_pressed("up") and Input.is_action_pressed("right"):
			$Pre_Stop.transform.origin = lerp($Pre_Stop.transform.origin, Vector3(-1,0,1) * pre_stp_lmt ,.1)
			pass
		elif Input.is_action_pressed("down") and Input.is_action_pressed("left"):
			$Pre_Stop.transform.origin = lerp($Pre_Stop.transform.origin, Vector3(1,0,-1) * pre_stp_lmt ,.1)
			pass
		elif Input.is_action_pressed("down") and Input.is_action_pressed("right"):
			$Pre_Stop.transform.origin = lerp($Pre_Stop.transform.origin, Vector3(-1,0,-1) * pre_stp_lmt ,.1)
			pass

		elif Input.is_action_pressed("up"):
			$Pre_Stop.transform.origin = lerp($Pre_Stop.transform.origin, Vector3(0,0,1) * pre_stp_lmt ,.1)
			pass
		elif Input.is_action_pressed("down"):
			$Pre_Stop.transform.origin = lerp($Pre_Stop.transform.origin, Vector3(0,0,-1) * pre_stp_lmt ,.1)
			pass
		elif Input.is_action_pressed("left"):
			$Pre_Stop.transform.origin = lerp($Pre_Stop.transform.origin, Vector3(1,0,0) * pre_stp_lmt ,.1)
			pass
		elif Input.is_action_pressed("right"):
			$Pre_Stop.transform.origin = lerp($Pre_Stop.transform.origin, Vector3(-1,0,0) * pre_stp_lmt ,.1)
			pass
		
		else:
			$Pre_Stop.transform.origin = lerp($Pre_Stop.transform.origin, Vector3(0,0,0) * pre_stp_lmt ,.1)

#	elif (abs(Input.get_joy_axis(0,JOY_AXIS_0)) > deadZone or abs(Input.get_joy_axis(0,JOY_AXIS_1)) > deadZone):
#		$Pre_Stop.transform.origin = lerp($Pre_Stop.transform.origin, Vector3(-Input.get_joy_axis(0,JOY_AXIS_0),0,-Input.get_joy_axis(0,JOY_AXIS_1)) * pre_stp_lmt ,.1)
#		pass

	else:
		$Pre_Stop.transform.origin = lerp($Pre_Stop.transform.origin, Vector3(0,0,0) * pre_stp_lmt ,.1)


	# (Experimental: Rotates both the Player and the Camera origin based on what the 3D position is rotated [Transform-Wise/ Eulers])
	if Input.is_action_pressed("orientation"):
		var reorient = $"/root/Setup/Objects/Models/Reorientation"
		#print(reorient)
		#set_rotation(lerp(global_transform.basis.get_euler(),$CamRoot/H.global_transform.basis.get_euler(),.5))
		set_rotation(lerp(global_transform.basis.get_euler(),reorient.global_transform.basis.get_euler(),.2))
		$CamRoot.set_rotation(lerp($CamRoot.global_transform.basis.get_euler(),reorient.global_transform.basis.get_euler(),.2))

	# Alternate character collison detection
	var tilt = move_and_collide(global_transform.origin,true,true,true)




	# Modify gravity based on slopes and wheter on floor or not
	if ang_grav == true:
		if is_moving == false and (is_on_floor() or is_on_wall()):
			spd_vel = Vector3.ZERO
			if ang_gate == true:
				pass
			else:
				
				grv_vel = Vector3.ZERO
				pass
#		else:
#			prv_grv = grv_vel
	elif ang_grav == false:
		if is_moving == false:
			spd_vel = Vector3.ZERO
		if (is_on_floor()):
			grv_vel = Vector3.ZERO
			pass




	# Used to determine if on a slope or not (Slopes / Part 2)
	if test_move(global_transform,down,true):
		can_jump = true
		#print("Ground!")
		var n = get_node("FloorCast").get_collision_normal()
		var p = get_node("FloorCast").get_collision_point()

		if not Input.is_action_pressed("jump") or not Input.is_joy_button_pressed(0,JOY_XBOX_A):
			jumped = true
		else:
			jumped = false
	# Current Bug/Issue: Somewhat works but moving platforms could use some
	# work.
		var floor_type = get_node(get_path_to(get_node("FloorCast").get_collider()))
		if floor_type == null:
			platform = false
			pass
		else:
			if floor_type.is_in_group("Platform"):

				platform = true

				if not Input.is_action_pressed("jump"): #or not Input.is_joy_button_pressed(0,JOY_XBOX_A):
				#if jumped == false:
					
					#print(floor_type.global_transform.basis.get_euler())
					set_rot(floor_type.global_transform.basis.get_euler())
					
					#print(get_rot())
					
					#var pinpoint = floor_type.get_node("../Raycaster/Spinner/RayCast").get_collision_point()
					#var pinnorm = floor_type.get_node("../Raycaster/Spinner/RayCast").get_collision_normal()
					
					#print(str(pinpoint.y)+" "+str(p.y))
					
					if not is_moving:
						# https://godotengine.org/qa/50695/rotate-object-around-origin
						
						#To place your node at a specific angle around a given point:
						#position = point + Vector2(cos(angle), sin(angle)) * distance
						
						#To make your node rotate around that point, while keeping the same distance:
						#position = point + (position - point).rotated(angle)
						
						###
						set_rot_cal(floor_type.global_transform.basis.get_euler().length())
						
						###
						#print(abs(get_rot_cal()))
						
						#global_transform.origin = floor_type.global_transform.origin + (global_transform.origin - floor_type.global_transform.origin).rotated(global_transform.basis.y,delta * (-get_rot_cal()*100))
						
						###
						#global_transform.origin = lerp(global_transform.origin, (floor_type.global_transform.origin + (global_transform.origin - floor_type.global_transform.origin).rotated(global_transform.basis.y,delta * ( (abs(get_rot_cal()) * 200))) ) , plat_smth) #( (abs(get_rot_cal()) * 100) * 1.2)
						#global_transform.origin = lerp(global_transform.origin, (floor_type.global_transform.origin + (global_transform.origin - floor_type.global_transform.origin).rotated(global_transform.basis.y,delta * ( (-(get_rot_cal()) * 120))) ) , plat_smth) #( (abs(get_rot_cal()) * 100) * 1.2)
#						if plat_stab == false:
#							stable = global_transform.origin
#							plat_stab = true
#						global_transform.origin = lerp(global_transform.origin, (floor_type.global_transform.origin + (floor_type.global_transform.origin - stable)), plat_smth) #( (abs(get_rot_cal()) * 100) * 1.2)
						
						#print(floor_type.get_node("Count_Nodes").get_children())
						
						for i in floor_type.get_node("Count_Nodes").get_children():
							if i.name == name:
								#global_transform.origin = i.global_transform.origin
								#global_transform.origin = lerp(global_transform.origin, i.global_transform.origin, plat_smth)
								if i.global_transform.origin != global_transform.origin and is_moving == false and plat_chk == false and is_on_floor():
									i.global_transform.origin = get_node("Pre_Stop").global_transform.origin
									plat_chk = true
									print(plat_chk)
								else:
									global_transform.origin = lerp(global_transform.origin, i.global_transform.origin, .025)
								#global_transform.origin = global_transform.origin.move_toward(i.global_transform.origin, 5)
						
						#global_transform.origin = lerp(global_transform.origin,pinpoint,plat_smth)
						pass

					else:
						#plat_stab = false
						pass

					if "fin_vel" in floor_type:
						#print(floor_type.fin_vel)
						plat_vel = -floor_type.fin_vel
					if "fin_rot" in floor_type:
						#print(-floor_type.fin_rot)
						plat_rot = -floor_type.fin_rot
						pass

				pass

			else:
				
				platform = false
				
				pass


		#var floor_angle = rad2deg(acos(n.dot(Vector3(0,1,0))))
		var floor_angle = rad2deg(acos(n.dot(global_transform.basis.y)))
		ang_adj = floor_angle
		#print(floor_angle)
		if floor_angle > 0:
			ang_grav = true
			if floor_angle > 60:
				$CollisionShape3.shape.slips_on_slope = true
				ang_gate = true
			else:
				$CollisionShape3.shape.slips_on_slope = false
				ang_gate = false
			pass
		else:
			ang_grav = false

	else:
		#print("Not Ground!")
		pass
	#print(-global_transform.basis.y)



	# if tilt is colliding
	if tilt:
		
		pass



	# if move_and_slide detects a collision
	
	if get_slide_count() > 0:
		is_grnd = true
#		can_jump = true
	else:
		if is_grnd == true:

			is_grnd = false
		else:
			prv_grv = grv_vel
		if is_moving == true:

			pass
		else:

			pass
		pass
	
	# Used to calculate whether the gravity (global_transform.basis.y is positive/negative; Going up or down)
	# Recommended for the slope code at 
	set_gravity(global_transform.basis.xform_inv(global_transform.origin).y)

	# Orthonormalizing the global_transform
	global_transform = global_transform.orthonormalized()
