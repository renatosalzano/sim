@tool
class_name Terrain extends Node3D

@export_group('Settings', 'set_')

@export var set_camera: Camera3D = null

@export var set_chunk:= Vector2i(2,2):
	set(value):
		if value.x > 0 && value.y > 0:
			set_chunk = value

@export var set_height:= 50.0:
	set(value): set_height = value;

	
