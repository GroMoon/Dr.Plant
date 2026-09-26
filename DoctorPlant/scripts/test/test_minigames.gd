extends Control
## 미니게임 시험장. 에피소드를 처음부터 하지 않고 미니게임만 골라 해 본다.
## 에디터에서 이 씬을 열고 F6(현재 씬 실행)으로 띄운다. 본편 흐름에는 쓰이지 않는다.

const HOST_SCENE: PackedScene = preload("res://scenes/minigame/minigame_host.tscn")

@onready var _menu: Control = $Menu
@onready var _buttons: VBoxContainer = $Menu/Box/Buttons
@onready var _tutorial: CheckBox = $Menu/Box/Tutorial
@onready var _result: Label = $Menu/Box/Result
@onready var _host_layer: CanvasLayer = $HostLayer


func _ready() -> void:
	_add_button("무작위", "")
	for entry: Dictionary in MinigameHost.GAMES:
		_add_button(tr(String(entry["key"]) + "_TITLE"), String(entry["id"]))
	_result.text = ""
	(_buttons.get_child(0) as Button).grab_focus()


func _add_button(text: String, game_id: String) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(420.0, 56.0)
	button.pressed.connect(_play.bind(game_id))
	_buttons.add_child(button)


func _play(game_id: String) -> void:
	AudioManager.play_select()
	_menu.hide()
	var host := HOST_SCENE.instantiate() as MinigameHost
	host.game_id = game_id
	host.tutorial = _tutorial.button_pressed
	_host_layer.add_child(host)
	var result: Dictionary = await host.finished
	host.queue_free()
	var entry: Dictionary = MinigameHost.find_game(String(result["game"]))
	_result.text = "%s — 실수 %d번 · %.1f초" % [
		tr(String(entry["key"]) + "_TITLE"), int(result["mistakes"]), float(result["time"])
	]
	_menu.show()
	(_buttons.get_child(0) as Button).grab_focus()
