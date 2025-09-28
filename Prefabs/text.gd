extends Area3D
@export var message: String = "You hit the object!"  # customizable per instance
@onready var ui_label = $"../../CanvasLayer/HitLabel"  # path to your Label in main scene
@onready var ui_label = get_tree().get_root().find_node("HitLabel", true, false)


func _ready():
	body_entered.connect(on_body_entered)

func on_body_entered(body):
	# Check if the body is on collision layer 0
	if body.collision_layer & (1 << 0):
		print("x")
		if ui_label:
			ui_label.text = message
			print("Hi")
			ui_label.visible = true
			print("Label found: ", ui_label)
			# Optional: hide after 2 seconds
			await get_tree().create_timer(2.0).timeout
			ui_label.visible = false
			
