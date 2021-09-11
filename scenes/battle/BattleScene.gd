extends Control

################################################################################
# Constants
################################################################################

const PLAYER_FIRST_MINION: int = 0
const ENEMY_FIRST_MINION: int = 3
const ANIMATION_FINISHED: String = "animation_finished"

################################################################################
# Signals
################################################################################

signal animation_finished()

################################################################################
# Variables
################################################################################

var _active_minion: int = -1
var _input_actions: Array = [-1, -1, -1, -1, -1, -1]
var _input_targets: Array = [-1, -1, -1, -1, -1, -1]
var _input_effects: Array = [-1, -1, -1, -1, -1, -1]
var _tie_break_player: bool = true
var _speed_tied: bool = false

var _expecting_target: bool = false
var _target_hostile: bool = true

onready var _ui_action_bar: Control = $MainLayer/HBox/BattleArea/ActionBar
onready var _ui_minions: Array = [
    $MainLayer/HBox/BattleArea/Battlers/PlayerTeam/Minion,
    $MainLayer/HBox/BattleArea/Battlers/PlayerTeam/Minion2,
    $MainLayer/HBox/BattleArea/Battlers/PlayerTeam/Minion3,
    $MainLayer/HBox/BattleArea/Battlers/EnemyTeam/Minion,
    $MainLayer/HBox/BattleArea/Battlers/EnemyTeam/Minion2,
    $MainLayer/HBox/BattleArea/Battlers/EnemyTeam/Minion3
]

################################################################################
# Event Handlers
################################################################################

func _ready():
    randomize()
    _get_player_input()


func _on_ActionBar_select_skill(i: int):
    assert(_active_minion >= PLAYER_FIRST_MINION)
    assert(_active_minion < ENEMY_FIRST_MINION)
    _input_actions[_active_minion] = i
    var minion = _ui_minions[_active_minion]
    match i:
        0:
            _input_effects[_active_minion] = minion.skill_1_effect
            _target_hostile = minion.skill_1_hostile
        1:
            _input_effects[_active_minion] = minion.skill_2_effect
            _target_hostile = minion.skill_2_hostile
        2:
            _input_effects[_active_minion] = minion.skill_3_effect
            _target_hostile = minion.skill_3_hostile
        _:
            assert(false)
    if _target_hostile:
        _enable_enemy_targets()
    else:
        _enable_friendly_targets()

func _on_ActionBar_select_back():
    assert(_active_minion > 0)
    _ui_minions[_active_minion].hide_highlight()
    _active_minion -= 1
    _ui_minions[_active_minion].hide_speed_tag()
    _ui_minions[_active_minion].show_highlight()
    _update_action_bar()

func _on_ActionBar_select_skip():
    _input_actions[_active_minion] = -1
    _ui_minions[_active_minion].skip_turn()
    _next_minion_input()


func _on_Minion_selected(i: int):
    if _expecting_target:
        assert(_active_minion >= PLAYER_FIRST_MINION)
        assert(_active_minion < ENEMY_FIRST_MINION)
        if _target_hostile:
            if i == _active_minion:
                return false # cannot target self
            if i < ENEMY_FIRST_MINION:
                return false # cannot target allies
            for i in range(ENEMY_FIRST_MINION, len(_ui_minions)):
                _ui_minions[i].hide_highlight()
        else:
            if i >= ENEMY_FIRST_MINION:
                return false # cannot target enemies
            for i in range(ENEMY_FIRST_MINION):
                _ui_minions[i].hide_highlight()
            # reactivate normal highlight for active minion
            _ui_minions[_active_minion].show_highlight()
        _expecting_target = false
        _input_targets[_active_minion] = i
        var a = _input_actions[_active_minion]
        _ui_minions[_active_minion].choose_skill(a)
        _next_minion_input()


################################################################################
# Game Logic
################################################################################

func _player_input_done():
    for i in range(ENEMY_FIRST_MINION, len(_ui_minions)):
        # AI
        var minion = _ui_minions[i]
        var action = randi() % 5
        _input_actions[i] = action
        match action:
            0:
                _input_effects[i] = minion.skill_1_effect
                assert(_input_effects[i] == 0)
                _input_targets[i] = randi() % 3
                _ui_minions[i].choose_skill(action)
            1:
                _input_effects[i] = minion.skill_2_effect
                assert(_input_effects[i] == 1)
                _input_targets[i] = randi() % 3
                _ui_minions[i].choose_skill(action)
            2:
                _input_effects[i] = minion.skill_3_effect
                assert(_input_effects[i] == 2)
                _input_targets[i] = (randi() % 3) + ENEMY_FIRST_MINION
                _ui_minions[i].choose_skill(action)
            _:
                _input_actions[i] = -1
                _ui_minions[i].skip_turn()
    call_deferred("_resolve_actions")


func _resolve_actions():
    var minions = _ui_minions.duplicate()
    minions.sort_custom(self, "_minion_speed_sort")
    for i in range(len(minions)):
        if minions[i].minion_health <= 0:
            continue
        var j = minions[i].minion_index
        var action = _input_actions[j]
        var target = _ui_minions[_input_targets[j]]
        var effect = _input_effects[j]
        if action < 0:
            continue
        match effect:
            0:
                _basic_attack(minions[i], target)
            1:
                _safe_attack(minions[i], target, 2)
            2:
                _basic_heal(minions[i], target, 6)
            _:
                assert(false, "effect not yet implemented")
        yield(self, ANIMATION_FINISHED)
    call_deferred("_next_round")


func _next_round():
    if _speed_tied:
        _tie_break_player = not _tie_break_player
        _speed_tied = false
    for i in range(len(_input_actions)):
        _input_actions[i] = -1
        _input_targets[i] = -1
        _input_effects[i] = -1
    for i in range(len(_ui_minions)):
        _ui_minions[i].reset_ui()
        _ui_minions[i].end_round()
    _get_player_input()


################################################################################
# Helper Functions
################################################################################

func _get_player_input():
    _active_minion = PLAYER_FIRST_MINION
    _ui_minions[_active_minion].show_highlight()
    _ui_action_bar.show_action_bar()
    _update_action_bar()

func _update_action_bar():
    var m = _ui_minions[_active_minion]
    _ui_action_bar.set_skill_1(
        m.skill_1_name,
        m.skill_1_speed,
        m.skill_1_cooldown,
        m.cd_skill_1 <= 0
    )
    _ui_action_bar.set_skill_2(
        m.skill_2_name,
        m.skill_2_speed,
        m.skill_2_cooldown,
        m.cd_skill_2 <= 0
    )
    _ui_action_bar.set_skill_3(
        m.skill_3_name,
        m.skill_3_speed,
        m.skill_3_cooldown,
        m.cd_skill_3 <= 0
    )
    if _active_minion == PLAYER_FIRST_MINION:
        _ui_action_bar.disable_back_button()
    else:
        _ui_action_bar.enable_back_button()

func _next_minion_input():
    _ui_minions[_active_minion].hide_highlight()
    _active_minion += 1
    if _active_minion >= ENEMY_FIRST_MINION:
        _active_minion = -1
        _ui_action_bar.hide_action_bar()
        call_deferred("_player_input_done")
    else:
        _ui_minions[_active_minion].show_highlight()
        _update_action_bar()

func _minion_speed_sort(a, b):
    if a.minion_speed < b.minion_speed:
        return true
    if a.minion_speed > b.minion_speed:
        return false
    if a.minion_index < ENEMY_FIRST_MINION:
        # player minion
        if b.minion_index < ENEMY_FIRST_MINION:
            # both player minions
            return a.minion_index < b.minion_index
        # player vs enemy
        _speed_tied = true
        return _tie_break_player
    else:
        # enemy minion
        if b.minion_index >= ENEMY_FIRST_MINION:
            # both enemy minions
            return a.minion_index < b.minion_index
        # player vs enemy
        _speed_tied = true
        return not _tie_break_player

func _enable_enemy_targets():
    _expecting_target = true
    for i in range(ENEMY_FIRST_MINION, len(_ui_minions)):
        _ui_minions[i].show_highlight_enemy()

func _enable_friendly_targets():
    _expecting_target = true
    for i in range(ENEMY_FIRST_MINION):
        _ui_minions[i].show_highlight_friend()


################################################################################
# Animation Functions
################################################################################

func _basic_attack(attacker, defender):
    attacker.animate_attacking()
    yield(attacker, ANIMATION_FINISHED)
    defender.animate_take_damage(attacker.minion_power)
    yield(defender, ANIMATION_FINISHED)
    attacker.take_damage(defender.minion_power)
    attacker.animate_attack_done()
    yield(attacker, ANIMATION_FINISHED)
    emit_signal("animation_finished")

func _safe_attack(attacker, defender, dmg):
    attacker.animate_attacking()
    yield(attacker, ANIMATION_FINISHED)
    defender.animate_take_damage(dmg)
    yield(defender, ANIMATION_FINISHED)
    attacker.animate_attack_done()
    yield(attacker, ANIMATION_FINISHED)
    emit_signal("animation_finished")

func _basic_heal(caster, target, dmg):
    caster.animate_casting()
    yield(caster, ANIMATION_FINISHED)
    target.animate_heal_damage(dmg)
    yield(target, ANIMATION_FINISHED)
    caster.animate_cast_done()
    yield(caster, ANIMATION_FINISHED)
    emit_signal("animation_finished")
