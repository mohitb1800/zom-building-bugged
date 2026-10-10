extends Node2D

@onready var last_main_lift_node: Node2D = $spawn_locations/Node2D6
@onready var spawn_nodes = $spawn_locations.get_children()
@onready var enemies: Node2D = $enemy_spawn_manager/enemies
@onready var level_end: Timer = $level_end
@onready var respawn_timer: Timer = $respawn_timer
@onready var enemy_spawn_manager: Node = $enemy_spawn_manager
@onready var label_3: Label = $CanvasLayer/Label3

@onready var level_clear_label: Label = $CanvasLayer/Label
@onready var you_died_label: Label = $CanvasLayer/Label2
@onready var main_lift: Area2D = $spawn_locations/Node2D6/main_lift


var enemy_scene = preload("res://scenes/enemy_1.tscn")

var level_number:int = 1
var enemy_spawn_nodes = []

func _ready() -> void:
	EventBus.challenge_complete.connect(level_complete)
	EventBus.player_died.connect(player_died)
	EventBus.level = self
	level_setup()


func level_setup():
	level_number = EventBus.level_number
	kill_enemies()
	main_lift_setup()
	enemy_lift_setup()
	enemy_spawn_manager.change_difficulty(level_number)


func main_lift_setup():
	var n: int = len(spawn_nodes)
	var main_lift_spawn = spawn_nodes[randi_range(0,n-1)]
	
	for child in last_main_lift_node.get_children():
		if child is MAIN_LIFT:
			main_lift = child
	main_lift.reparent(main_lift_spawn,false)
	last_main_lift_node = main_lift_spawn

func enemy_lift_setup():
	var new_list = []
	for loc in spawn_nodes:
		if (loc.position - last_main_lift_node.position).length()>200:
			new_list.append(loc)
	enemy_spawn_nodes = new_list


func kill_enemies():
	for enemy in enemies.get_children():
		enemy.queue_free()


func level_complete():
	EventBus.level_number += 1
	enemy_spawn_manager.change_difficulty(EventBus.level_number)
	label_3.text = "Floor : " + str(EventBus.level_number)
	EventBus.player.set_checkpoint()
	get_tree().paused = true
	level_clear_label.visible = true
	level_end.start()
	main_lift.reset()


func player_died():
	EventBus.player.visible = false
	you_died_label.visible = true
	get_tree().paused = true
	respawn_timer.start()
	kill_enemies()

func respawn():
	var player = EventBus.player
	player.use_checkpoint()
	you_died_label.visible = false
	player.visible = true
	player.global_position = EventBus.respawn_point
	player.health = 100
	main_lift.reset()


func _on_respawn_timer_timeout() -> void:
	get_tree().paused = false
	respawn()

func _on_level_end_timeout() -> void:
	level_clear_label.visible = false
	get_tree().paused = false
	level_setup()
