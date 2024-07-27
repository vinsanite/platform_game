extends RigidBody2D
class_name Projectile

var initial_velocity: float = 300.0
var life_time: float = 3.0

@onready var life_timer = $LifeTimer

func _ready() -> void:
	# Convert rotation from radians to direction vector
	var direction = Vector2(1, 0).rotated(rotation)
	
	# Set the linear velocity in the direction the projectile is facing
	linear_velocity = direction * initial_velocity
	
	# Optional: Print information for debuagging
	print("Projectile velocity set to: ", linear_velocity, " with rotation: ", rotation)
	
	# Configure and start the life timer
	life_timer.wait_time = life_time
	life_timer.one_shot = true
	life_timer.start()
	# Correctly connect the signal
	life_timer.connect("timeout", Callable(self, "_on_LifeTimer_timeout"))

func _on_LifeTimer_timeout():
	queue_free()