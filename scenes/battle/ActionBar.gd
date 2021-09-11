extends MarginContainer

################################################################################
# Signals
################################################################################

signal select_skill(i)
signal select_back()
signal select_skip()

################################################################################
# Variables
################################################################################

onready var _ui_hbox: HBoxContainer = $HBox
onready var _ui_skill_1: Button = $HBox/Skill1
onready var _ui_skill_2: Button = $HBox/Skill2
onready var _ui_skill_3: Button = $HBox/Skill3
onready var _ui_back: Button = $HBox/Back

################################################################################
# Action Bar Interface
################################################################################

func hide_action_bar():
    _ui_hbox.visible = false

func show_action_bar():
    _ui_hbox.visible = true

func set_skill_1(skill_name: String, speed: int, cooldown: int,
                 enabled: bool = true):
    _ui_skill_1.text = "%s (S: %d) (C: %d)" % [skill_name, speed, cooldown]
    _ui_skill_1.disabled = not enabled

func set_skill_2(skill_name: String, speed: int, cooldown: int,
                 enabled: bool = true):
    _ui_skill_2.text = "%s (S: %d) (C: %d)" % [skill_name, speed, cooldown]
    _ui_skill_2.disabled = not enabled

func set_skill_3(skill_name: String, speed: int, cooldown: int,
                 enabled: bool = true):
    _ui_skill_3.text = "%s (S: %d) (C: %d)" % [skill_name, speed, cooldown]
    _ui_skill_3.disabled = not enabled

func enable_back_button():
    _ui_back.disabled = false

func disable_back_button():
    _ui_back.disabled = true


################################################################################
# Event Handlers
################################################################################

func _on_Skill1_pressed():
    emit_signal("select_skill", 0)

func _on_Skill2_pressed():
    emit_signal("select_skill", 1)

func _on_Skill3_pressed():
    emit_signal("select_skill", 2)

func _on_Back_pressed():
    emit_signal("select_back")

func _on_Skip_pressed():
    emit_signal("select_skip")
