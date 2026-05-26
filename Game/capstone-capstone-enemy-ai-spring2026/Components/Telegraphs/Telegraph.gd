"""
Telegraph Script: Draws visual warning areas for incoming boss attacks.
@authors: Sam Plemmons
"""
extends CollisionShape2D
	
var progress: float = 1.0
var display_progress : bool = false


"""
Draws the telegraphed attack area based on the assigned collision shape.

Rectangle shapes are drawn as rectangular attack zones, while circle shapes
are drawn as circular attack zones. If progress display is enabled, an
additional overlay is drawn to show the telegraph filling in over time.
"""
func _draw():
	if shape is RectangleShape2D:
		# Basic Melee Attack
		draw_rect(Rect2(-shape.extents, shape.extents * 2), Color(1,0,0,0.5))
		'''
		work in progress for the telegraph growing
		'''
		if display_progress:
			draw_rect(
				Rect2(Vector2(-shape.size.x / 2, shape.size.y / 2 - shape.size.y * progress), 
				Vector2(shape.size.x, shape.size.y * progress)), Color(1, 0, 0, 0.6))
	elif shape is CircleShape2D:
		# Basic Range Attack
		draw_circle(Vector2.ZERO, shape.radius, Color(1,0,0,0.5))
		if display_progress:
			draw_circle(Vector2.ZERO, shape.radius * progress, Color(1,0,0,0.6))
		
"""
Updates the telegraph fill progress and redraws the shape.
"""
func set_progress(prog: float) -> void:
	progress = prog
	queue_redraw()

"""
Enables or disables the progress overlay and redraws the shape.
"""
func has_progress(prog: bool) -> void:
	display_progress = prog
	queue_redraw()
