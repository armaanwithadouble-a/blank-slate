extends Control

@onready var anim: AnimationPlayer = $AnimationPlayer

signal transition_in_done
signal transition_out_done

func play_out():
	anim.play("out")

func play_in():
	anim.play("in")

func _ready():
	play_in()

func _on_AnimationPlayer_animation_finished(name: String):
	if name == "in":
		emit_signal("transition_in_done")
	elif name == "out":
		emit_signal("transition_out_done")


func _on_animation_player_animation_finished(anim_name):
	pass # Replace with function body.
