"""
Change Sprite Node: Action node that switches which AnimatedSprite2D is visible.
@authors: Sam Plemmons
"""
extends BTAction
class_name BTChangeSprite

var current_sprite: AnimatedSprite2D
var new_sprite: AnimatedSprite2D


"""
Initializes the sprite change action.

@param current: Sprite currently being displayed.
@param new: Sprite that should be displayed next.
"""
func _init(current: AnimatedSprite2D, new: AnimatedSprite2D):
	display_name = "BTChangeSprite"
	current_sprite = current
	new_sprite = new

"""
Hides the current sprite and shows the new sprite.
"""
func execute(_delta: float, context: Dictionary) -> int:
	current_sprite.visible = false
	new_sprite.visible = true
	return BTNode.Status.SUCCESS
