extends Camera2D

var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_decay: float = 10.0

# For room transitions



# --- SCREEN SHAKE ---
func apply_shake(intensity: float = 20.0, duration: float = 0.2):
	shake_intensity = intensity
	shake_duration = duration


func _process(delta):
	# Update shake offset
	var shake_offset = Vector2.ZERO
	if shake_duration > 0:
		shake_duration -= delta
		shake_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		shake_intensity = lerp(shake_intensity, 0.0, delta * shake_decay)

	# Combine base position + shake offset
