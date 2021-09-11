extends PanelContainer

################################################################################
# Constants
################################################################################

const COLOR_ENEMY: Color = Color(0.875, 0.125, 0.125)
const COLOR_FRIEND: Color = Color(0.095, 0.625, 0.034)
const COLOR_HIGHLIGHT: Color = Color(0.93, 0.89, 0.45)

################################################################################
# Signals
################################################################################

signal minion_selected(i)
signal animation_finished(i)

################################################################################
# Variables
################################################################################

export (int) var minion_index: int = 0

export (int) var base_health: int = 10
export (int) var base_power: int = 4

export (String) var skill_1_name: String = "Attack"
export (int) var skill_1_speed: int = 5
export (int) var skill_1_cooldown: int = 0
export (int) var skill_1_effect: int = 0
export (int) var skill_1_hostile: bool = true

export (String) var skill_2_name: String = "Q. Attack"
export (int) var skill_2_speed: int = 3
export (int) var skill_2_cooldown: int = 0
export (int) var skill_2_effect: int = 1
export (int) var skill_2_hostile: bool = true

export (String) var skill_3_name: String = "Heal"
export (int) var skill_3_speed: int = 8
export (int) var skill_3_cooldown: int = 1
export (int) var skill_3_effect: int = 2
export (int) var skill_3_hostile: bool = false

var minion_max_health: int = base_health
var minion_health: int = base_health
var minion_power: int = base_power
var minion_speed: int = -1 # current turn
var minion_status: int = 0
var minion_type: int = 0
var cd_skill_1: int = 0
var cd_skill_2: int = 0
var cd_skill_3: int = 0

var _ui_highlighted: bool = false
var _mouse_highlighted: bool = false

onready var _ui_status: Label = $Parts/Status
onready var _ui_power: Label = $Parts/Stats/AttackValue
onready var _ui_health: Label = $Parts/Stats/HealthValue
onready var _ui_speed_tag: Control = $Overlay/SpeedTag
onready var _ui_speed: Label = $Overlay/SpeedTag/HBox/SpeedValue
onready var _ui_highlight: Panel = $Parts/Sprite/Highlight
onready var _animator: AnimationPlayer = $AnimationPlayer

################################################################################
# Minion Interface
################################################################################

func animate_heal_damage(dmg: int):
    _animator.play("heal")
    yield(_animator, "animation_finished")
    heal_damage(dmg)
    emit_signal("animation_finished", minion_index)

func heal_damage(dmg: int):
    minion_health += dmg
    if minion_health > minion_max_health:
        minion_health = minion_max_health
    _ui_health.text = String(minion_health)

func animate_take_damage(dmg: int):
    _animator.play("damage")
    yield(_animator, "animation_finished")
    take_damage(dmg)
    emit_signal("animation_finished", minion_index)

func take_damage(dmg: int):
    minion_health -= dmg
    if minion_health < 0:
        minion_health = 0
    _ui_health.text = String(minion_health)

func animate_attacking():
    _animator.play("attack_begin")
    yield(_animator, "animation_finished")
    emit_signal("animation_finished", minion_index)

func animate_attack_done():
    _animator.play("attack_end")
    yield(_animator, "animation_finished")
    emit_signal("animation_finished", minion_index)

func animate_casting():
    _animator.play("cast_begin")
    yield(_animator, "animation_finished")
    emit_signal("animation_finished", minion_index)

func animate_cast_done():
    _animator.play("cast_end")
    yield(_animator, "animation_finished")
    emit_signal("animation_finished", minion_index)

func choose_skill(i: int):
    match i:
        0:
            minion_speed = skill_1_speed
            cd_skill_1 = skill_1_cooldown + 1
        1:
            minion_speed = skill_2_speed
            cd_skill_2 = skill_2_cooldown + 1
        2:
            minion_speed = skill_3_speed
            cd_skill_3 = skill_3_cooldown + 1
        _:
            assert(false)
            return false
    _ui_speed_tag.visible = true
    _ui_speed.text = String(minion_speed)
    return true


func skip_turn():
    minion_speed = -1
    _ui_speed_tag.visible = true
    _ui_speed.text = "zZz"
    return true

func hide_speed_tag():
    _ui_speed_tag.visible = false

func show_highlight(color: Color = COLOR_HIGHLIGHT):
    _ui_highlighted = true
    _ui_highlight.visible = true
    _ui_highlight.get("custom_styles/panel").border_color = color

func show_highlight_enemy():
    return show_highlight(COLOR_ENEMY)

func show_highlight_friend():
    return show_highlight(COLOR_FRIEND)

func hide_highlight():
    _ui_highlighted = false
    _ui_highlight.visible = _mouse_highlighted
    _ui_highlight.get("custom_styles/panel").border_color = COLOR_HIGHLIGHT

func reset_ui():
    _ui_health.text = String(minion_health)
    _ui_power.text = String(minion_power)
    _ui_speed_tag.visible = false
    _ui_speed.text = "?"
    _ui_highlight.visible = _ui_highlighted or _mouse_highlighted

func end_round():
    if cd_skill_1 > 0:
        cd_skill_1 -= 1
    if cd_skill_2 > 0:
        cd_skill_2 -= 1
    if cd_skill_3 > 0:
        cd_skill_3 -= 1

################################################################################
# Event Callbacks
################################################################################

func _ready():
    reset_ui()


func _on_Minion_gui_input(event):
    if event is InputEventMouseButton:
        if event.button_index == BUTTON_LEFT and event.pressed:
            emit_signal("minion_selected", minion_index)

func _on_Minion_mouse_entered():
    _mouse_highlighted = true
    _ui_highlight.visible = true

func _on_Minion_mouse_exited():
    _mouse_highlighted = false
    _ui_highlight.visible = _ui_highlighted
