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
var rot_vel = Vector3(0,0,0) setget set_rot, get_rot
var alt_rot = Vector3(0,0,0)
var grv_dif = 0
var ang_adj = 0



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



func set_rot(a):
	if rot_vel != a:
		alt_rot = rot_vel - (a)
		rot_vel = a
	pass

func get_rot():
	return alt_rot





func _ready():
	character = get_node(".")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$CamRoot.set_as_toplevel(true)

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
		print("Foward")
		con_speed = lerp(con_speed, 800, .1)
		con_vel.x = lerp(con_vel.x, -Input.get_joy_axis(0,JOY_AXIS_0) * 800, .1)
		is_moving = true
	else:
		con_vel.x = lerp(con_vel.x, 0, .1)

	if abs(Input.get_joy_axis(0,JOY_AXIS_1)) > deadZone:
		print("Sideway")
		con_speed = lerp(con_speed, 800, .1)
		con_vel.y = lerp(con_vel.y, -Input.get_joy_axis(0,JOY_AXIS_1) * 800, .1)
		is_moving = true
	else:
		con_vel.y = lerp(con_vel.y, 0, .1)

	if abs(Input.get_joy_axis(0,JOY_AXIS_0)) < deadZone and abs(Input.get_joy_axis(0,JOY_AXIS_1)) > deadZone:
		con_speed = lerp(con_speed, 800, .1)


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
					grv_vel = (global_transform.basis[1].normalized() * delta) * ((-ang_adj * 10) * (abs(mov_speed/400) + abs(con_speed/400)))
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





	# Moving our character (Also used to determine ground collision)
	var slides = move_and_slide_with_snap(spd_vel + grv_vel, ground * stop, global_transform.basis.y * 800, true)


	# Player origin base (Feet)
	var down = -global_transform.basis.y


	# Used to reverse gravity when you hit the ceiling
	if is_on_ceiling():
		#print("Ceiling!")
		grv_vel = grv_vel * -1



	# Freezes player rotation while moving
	if is_moving && !Input.is_key_pressed(KEY_SHIFT):
		set_rotation($CamRoot/H.global_transform.basis.get_euler())

	# Rotates when the controller joystick is tilted (Gamepad/Controller Only)
	elif abs(Input.get_joy_axis(0,JOY_AXIS_0)) > deadZone or abs(Input.get_joy_axis(0,JOY_AXIS_1)) > deadZone:
		set_rotation($CamRoot/H.global_transform.basis.get_euler())
		pass



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


	# Current Bug/Issue: Somewhat works but moving platforms could use some
	# work.
		var floor_type = get_node(get_path_to(get_node("FloorCast").get_collider()))
		if floor_type == null:
			pass
		else:
			if floor_type.is_in_group("Platform"):

				if not Input.is_action_pressed("jump"):
					#print(floor_type.name)
					#var pinpoint = get_node("../../Geometry/Path/PathFollow/Platform/Raycaster/Spinner/RayCast").get_collision_point()
					#var pinnorm = get_node("../../Geometry/Path/PathFollow/Platform/Raycaster/Spinner/RayCast").get_collision_normal()

					var pinpoint = floor_type.get_node("../Raycaster/Spinner/RayCast").get_collision_point()
					var pinnorm = floor_type.get_node("../Raycaster/Spinner/RayCast").get_collision_normal()

					if not is_moving:
						set_velocity(Vector3(0,0,0))
						#global_transform.origin.move_toward() = lerp(global_transform.origin,pinpoint,.5)
						#global_transform.origin = global_transform.origin.move_toward(floor_type.global_transform.origin,.1)

						#global_transform.origin = global_transform.origin.move_toward(pinpoint,.1)

						#look_at(pinnorm,Vector3.UP)
						#global_transform.basis = floor_type.global_transform.basis
						global_transform.origin = pinpoint
						#print(get_node("FloorCast").get_collision_point())
						#rotation. += floor_type.rotation
						#set_rot(floor_type.rotation)
						set_rot(floor_type.global_transform.basis.get_euler())
						#print(get_rot())
						var cap_vel = get_rot() * Vector3(1,-1,1)
						rotation += cap_vel
						#$CamRoot.set_rotation(global_transform.basis.get_euler())
						#print(floor_type.global_transform.basis.get_euler())
					else:
						set_velocity(floor_type.global_transform.origin)
						#print(get_velocity())
			else:
				set_velocity(Vector3(0,0,0))


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
