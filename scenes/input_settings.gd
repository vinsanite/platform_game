extends Control

# Preload the scene resource
@onready var input_button_scene = preload("res://scenes/input_button.tscn")
@onready var action_list = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/ActionList

const MUSIC_BUS = "Music"
const SOUND_BUS = "Sound"

var is_remapping = false
var action_to_remap = null
var remapping_button = null

var input_actions = {
	"move_left": "Move left",
	"move_right": "Move right",
	"jump": "Jump",
	"crouch": "Crouch",
	"dash": "Dash",
	"shoot": "Shoot"
}

func _ready():
	_create_action_list()
	
func _create_action_list():
	InputMap.load_from_project_settings()
	for item in action_list.get_children():
		item.queue_free()
	
	for action in input_actions:
		var button = input_button_scene.instantiate() # Instantiate the scene
		var action_label = button.find_child("LabelAction")
		var input_label = button.find_child("LabelInput")
		
		action_label.text = input_actions[action]
		
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			input_label.text = events[0].as_text().trim_suffix(" (Physical)")
		else:
			input_label.text = ""
		
		action_list.add_child(button)  # Add the instantiated button to the action list
		button.pressed.connect(_on_input_button_pressed.bind(button,action))


func _on_input_button_pressed(button, action):
	if !is_remapping:
		is_remapping = true
		action_to_remap = action
		remapping_button = button
		button.find_child("LabelInput").text = "Press key to bind..."
		

func _input(event):
	if is_remapping:
		if (
			event is InputEventKey || (event is InputEventMouseButton && event.pressed)
		):
			# Turn double click into single click
			if event is InputEventMouseButton && event.double_click:
				event.double_click = false
			
			InputMap.action_erase_events(action_to_remap)
			InputMap.action_add_event(action_to_remap, event)
			_update_action_list(remapping_button, event)
			
			is_remapping= false
			action_to_remap  = null
			remapping_button = null
			
			accept_event()


func _update_action_list(button, event):
	button.find_child("LabelInput").text = event.as_text().trim_suffix(" (Physical)")


func _on_default_button_pressed():
	_create_action_list()


func _on_master_slider_value_changed(value):
	if value == -45:
		AudioServer.set_bus_mute(0, true)
	else:
		AudioServer.set_bus_mute(0, false)
	AudioServer.set_bus_volume_db(0, value)


func _on_music_slider_value_changed(value):
	var BusInt = AudioServer.get_bus_index(MUSIC_BUS)
	AudioServer.set_bus_volume_db(BusInt, value)


func _on_sound_slider_value_changed(value):
	var BusInt = AudioServer.get_bus_index(SOUND_BUS)
	AudioServer.set_bus_volume_db(BusInt, value)
