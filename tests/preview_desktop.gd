extends "res://scripts/desktop.gd"


func _boot_game() -> void:
	last_tick = Time.get_ticks_msec()
	last_wall = Time.get_unix_time_from_system()
	last_save = last_tick
	game.data.checkpoint = last_wall
	can_play = true
	owns_lock = true


func _load_settings() -> void:
	pass


func _save_settings() -> void:
	pass


func _save_game() -> bool:
	return true


func _build_status_menu() -> void:
	hide_button.disabled = true
