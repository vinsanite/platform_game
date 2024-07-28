class_name Player
extends CharacterBody2D

# Constants for movement, jumping, and dashing
const SPEED = 130.0
const JUMP_VELOCITY = -300.0
const DASH_SPEED = 450.0
const DASH_DURATION = 0.1
const DASH_COOLDOWN = 1.0
const MAX_HEALTH = 5
const REGEN_INTERVAL = 3.0

# Variables to manage physics and state
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var can_doublejump = false
var is_dashing = false
var dash_timer = 0.0
var can_dash = true
var health = MAX_HEALTH
var is_dead = false

# Preloaded projectile scene for easy instantiation
var projectile = preload("res://scenes/projectile.tscn")
var can_fire = true
var rate_of_fire = 0.5

# Onready variables to cache node references
@onready var animated_sprite = $AnimatedSprite2D
@onready var fire_timer = $FireTimer
@onready var dash_cooldown_timer = $DashCooldown # Timer node for dash cooldown
@onready var hand_anchor = $HandAnchor
@onready var shooter = $HandAnchor/Shooter
@onready var weapon = $HandAnchor/Shooter/Weapon
@onready var regen_timer = $RegenTimer # Timer node for health regeneration
@onready var health_ui  = $UI/Hearts

func _ready():
	regen_timer.stop()
	add_to_group("Player") # Add player to the "Player" group
	update_health_ui()
	
# Called every frame
func _process(delta):
	if is_dead:
		return
	if is_dashing:
		# Countdown for dash duration
		dash_timer -= delta
		if dash_timer <= 0:
			# End dashing and stop movement
			is_dashing = false
			velocity = Vector2.ZERO
	else:
		# Handle aiming, shooting, and dashing
		aim_shooter()
		handle_shooting()
		handle_dashing()

# Called every physics frame
func _physics_process(delta):
	if is_dead:
		# Apply gravity to make the player fall off the screen
		velocity.y += gravity * delta
		move_and_slide()
		return
	if not is_dashing:
		# Apply gravity if not on the floor
		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			can_doublejump = true

		# Handle jumping input
		if Input.is_action_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			can_doublejump = true
		elif Input.is_action_just_pressed("jump") and !is_on_floor() and can_doublejump:
			velocity.y = JUMP_VELOCITY 
			can_doublejump = false

		# Get movement direction based on input
		var direction = Input.get_axis("move_left", "move_right")
		
		# Flip the sprite based on direction
		if direction > 0:
			animated_sprite.flip_h = false
		elif direction < 0:
			animated_sprite.flip_h = true
		
		# Play appropriate animations
		if is_on_floor():
			if direction == 0:
				if animated_sprite.animation != "damaged":
					animated_sprite.play("idle")
			else:
				if animated_sprite.animation != "damaged":
					animated_sprite.play("run")
				
			if Input.is_action_pressed("jump"):
				animated_sprite.play("jump")
			
			if Input.is_action_pressed("crouch"):
				animated_sprite.play("crouch")
		else:
			if !can_doublejump:
				animated_sprite.play("midair")
		
		# Apply movement input or stop if crouching
		if Input.is_action_pressed("crouch") and is_on_floor():
			velocity.x = 0
		else:    
			if direction:
				velocity.x = direction * SPEED
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)

	# Apply movement and handle collisions
	move_and_slide()
	
# Aims the shooter towards the mouse cursor
func aim_shooter():
	var mouse_position = get_global_mouse_position()
	var hand_anchor_position = hand_anchor.get_global_position()
	var direction = (mouse_position - hand_anchor_position).normalized()
	var offset_distance = 20  # Distance from hand anchor to shooter
	
	# Update shooter's position and rotation
	shooter.position = direction * offset_distance
	shooter.rotation = direction.angle()
	
# Handles shooting projectiles
func handle_shooting():
	if Input.is_action_pressed("shoot") and can_fire:
		can_fire = false
		var projectile_instance = projectile.instantiate()
		
		# Spawn projectile at shooter's position with its rotation
		projectile_instance.position = shooter.global_position
		projectile_instance.rotation = shooter.rotation
		get_parent().add_child(projectile_instance)
		print("Projectile instantiated at: ", projectile_instance.position, " with rotation: ", projectile_instance.rotation)
		fire_timer.start(rate_of_fire)
		
		# Restart health regeneration timer when shooting to prevent spam
		if not regen_timer.is_stopped():
			regen_timer.stop()
		regen_timer.start(REGEN_INTERVAL)

# Called when fire timer times out to allow firing again
func _on_fire_timer_timeout():
	can_fire = true

# Handles dashing mechanics
func handle_dashing():
	if Input.is_action_just_pressed("dash") and can_dash:
		is_dashing = true
		can_dash = false
		dash_timer = DASH_DURATION
		
		# Determine dash direction based on mouse position
		var mouse_position = get_global_mouse_position()
		var direction = 1 if mouse_position.x > global_position.x else -1
		# Set dash velocity
		velocity = Vector2(direction * DASH_SPEED, 0)
		
		# Start cooldown timer for dashing
		dash_cooldown_timer.start(DASH_COOLDOWN)

# Called when dash cooldown timer times out to reset dash ability
func _on_dash_cooldown_timeout():
	can_dash = true
	print("dash reset")

# Handles health regeneration
func _on_regen_timer_timeout():
	if health < MAX_HEALTH:
		health += 1
		update_health_ui()
		print("Health regenerated to: ", health)
		if health < MAX_HEALTH:
			regen_timer.start(REGEN_INTERVAL)
	
# Method to decrease health
func take_damage(amount):
	health -= amount
	animated_sprite.play("damaged")
	update_health_ui()
	print("Health decreased to: ", health)
	if health <= 0:
		die()
	else:
		# Restart health regeneration timer if health is less than max
		if not regen_timer.is_stopped():
			regen_timer.stop()
		regen_timer.start(REGEN_INTERVAL)
		
func die():
	is_dead = true
	animated_sprite.play("die")
	velocity = Vector2(0, 300)  # Initial downward velocity
	print("Player died")

# Update the health UI based on the current health
func update_health_ui():
	if health <= 0:
		health_ui.visible = 0
	else:
		health_ui.size.x = health * 50
