"""
    This script controls the health bar for an NPC. It updates the 
	bar's value every frame and controls its visibility based on 
	whether the NPC has taken damage.
"""
extends ProgressBar

var parent

"""
    Called when the node enters the scene tree. Initializes references 
	and sets the health bar's max and current value.
"""
func _ready():
	parent = get_parent()
	
	await parent.NOTIFICATION_READY
	
	# Set the maximum HP the bar can display
	self.max_value = parent.max_hp
	
	# Initialize the bar to the NPC's current health
	self.value = parent.get_health()

"""
	Updates the health bar's value and visibility every frame.
"""
func _process(_delta: float):
	# Always keep value synced with the parent's health
	self.value = parent.get_health()
	
	# Show the health bar when damaged, hide when full or dead
	if parent.get_health() != self.max_value:
		self.visible = true
	
		# If HP drops to 0 or below, hide the bar
		if parent.get_health() <= 0:
			self.visible = false
	else:
		# Hide when at full health
		self.visible = false
