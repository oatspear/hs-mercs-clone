# Battle Scene Logic

The `BattleScene` puts together all the individual pieces to enable minion combat.
In the previous steps of this tutorial, we have implemented the logic for `ActionBar` and `Minion` components.
Now, we implement the main game logic, as seen in the [script file](https://github.com/git-afsantos/hs-mercs-clone/blob/main/scenes/battle/BattleScene.gd), that will set things in motion.

## General Idea

The main game logic follows a rather simple state machine.

1. The **Planning Phase**: collect player input for each of their minions.
2. The **Combat Phase**: sort player and enemy actions by *Speed* value, then resolve the actions.
3. End the round; go to the next Planning Phase until one of the players has no minions left.

Each of these states has a small number of steps to go through, but, right away, we can tell that we will need variables to keep track of the currently active minion, and variables to save all the player choices during the Planning phase, before the actions are resolved in the Combat phase.

In addition, we have to decide on how to solve Speed ties.
An easy solution is to decide randomly.
Here, though, we will opt for a more deterministic solution.
We will store a *tie breaker* variable that first will grant the advantage to the player, until a speed tie actually happens.
When it does, the tie breaker shifts to the opponent, so the opponent wins the next round with speed ties, etc..

With this in mind, it is time to move on the game logic itself.

## Initialization

This one is simple.
When the game starts, we jump straight to collecting player input.
In a more advanced version of the game, this is where you could play a few animations, to let the player know that combat is starting.

```gdscript
func _ready():
    randomize()
    _get_player_input()
```

Let us also take the opportunity to set up some necessary variables with references to the minions and to the action bar.

```gdscript
onready var _ui_action_bar: Control = $MainLayer/HBox/BattleArea/ActionBar
onready var _ui_minions: Array = [
    $MainLayer/HBox/BattleArea/Battlers/PlayerTeam/Minion,
    $MainLayer/HBox/BattleArea/Battlers/PlayerTeam/Minion2,
    $MainLayer/HBox/BattleArea/Battlers/PlayerTeam/Minion3,
    $MainLayer/HBox/BattleArea/Battlers/EnemyTeam/Minion,
    $MainLayer/HBox/BattleArea/Battlers/EnemyTeam/Minion2,
    $MainLayer/HBox/BattleArea/Battlers/EnemyTeam/Minion3
]
```


## Planning Phase

We know that in this phase we have to let both players select their actions, and then we have to store them.
Actions are not resolved immediately.
So, let us start by defining the necessary variables for this.

```gdscript
var _active_minion: int = -1
var _input_actions: Array = [-1, -1, -1, -1, -1, -1]
var _input_targets: Array = [-1, -1, -1, -1, -1, -1]
var _input_effects: Array = [-1, -1, -1, -1, -1, -1]
```

The `_active_minion` variable holds the index of the currently active minion (the one choosing its action for the turn).
There are six minions, so in the `_input_*` arrays we have to store six actions, six selected targets, and six skill effects.

We need also to decide which minions correspond to which indices.
Let us define player minions to indices `[0, 1, 2]` and enemy minions to indices `[3, 4, 5]`.

```gdscript
const PLAYER_FIRST_MINION: int = 0
const ENEMY_FIRST_MINION: int = 3
```


### Collecting Player Input

The `_get_player_input()` function referenced above is where the main logic for player input starts.
We want to set the active minion to the player's first minion, highlight that minion, and show the action bar.

```gdscript
func _get_player_input():
    _active_minion = PLAYER_FIRST_MINION
    _ui_minions[_active_minion].show_highlight()
    _ui_action_bar.show_action_bar()
    _update_action_bar()
```

We need also to update the action bar with the skills that the first minion knows.
Remember to disable the `Back` button if we are handling the first minion, as there is no other minion to go back to.

```gdscript
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
```

And this is the first stop for the main logic.
The game now sits idle, waiting for the user to interact with the action bar and fire some events.

Speaking of which, we now have to select the action bar in the node tree and connect some signals to handle its input.

### Action Bar Signals

Connect the custom signals we defined to new functions in the `BattleScene` script.

![Action Bar Signals](./step-5-action-bar-signals.PNG)

#### Skip a Turn

When the action bar emits a signal to skip a turn, we will store a special action value, for example `-1`, to distinguish it from other skills.
Then, we move on the the input of the next minion.

```gdscript
func _on_ActionBar_select_skip():
    _input_actions[_active_minion] = -1
    _ui_minions[_active_minion].skip_turn()
    _next_minion_input()
```

Moving on the next minion means advancing the active minion index, changing the highlights and updating the action bar.
If there are no more player minions left, we should *hide* the action bar instead, and call a function to handle the end of input collection.

```gdscript
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
```

#### Back to Previous Minion

When the action bar emits a signal to go back to the previous minion, we decrement the active minion index and shift the highlights accordingly.
We must also not forget to update the action bar.

```gdscript
func _on_ActionBar_select_back():
    assert(_active_minion > 0)
    _ui_minions[_active_minion].hide_highlight()
    _active_minion -= 1
    _ui_minions[_active_minion].hide_speed_tag()
    _ui_minions[_active_minion].show_highlight()
    _update_action_bar()
```

Updating the action bar simply means using the Action Bar Interface that we defined, to change the contents of its buttons.
Displayed data is gathered from the currently active minion.

```gdscript
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
```

#### Choose a Skill

Lastly, when the action bar emits a signal with a chosen skill, we store the skill as the selected action, and go to the minion's data to gather the corresponding skill effect and whether it is an hostile or friendly skill.
We highlight the appropriate minions in each case, to tell the player that we are accepting targets.
We must choose a target before advancing to the next minion.

```gdscript
var _expecting_target: bool = false
var _target_hostile: bool = true

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
```

And here is how to highlight each type of target.

```gdscript
func _enable_enemy_targets():
    _expecting_target = true
    for i in range(ENEMY_FIRST_MINION, len(_ui_minions)):
        _ui_minions[i].show_highlight_enemy()

func _enable_friendly_targets():
    _expecting_target = true
    for i in range(ENEMY_FIRST_MINION):
        _ui_minions[i].show_highlight_friend()
```

This is again, a stopping point for the game's logic.
Once we transition to target selection, the game sits idle until a minion emits a signal telling the `BattleScene` that it has been selected.

### Minion Signals

This is a good time to go to the node tree and make a few changes to each of the six `Minion` nodes.
First, remember to change the *Minion Index* in the node Inspector to the correct index.
Then, go to the list of signals of each minion and connect **all** the `minion_selected` signals to a **single** `_on_Minion_selected` function.

![Minion Signals](./step-5-minion-signals.PNG)

Here is the callback function.

```gdscript
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
```

As you can see, the callback function only does something *if* we are expecting a target to be selected.
In addition, it should do nothing if we are expecting hostile targets and select a friendly minion, or vice-versa.

Once we select a valid minion, we should restore the highlights to normal, tell the game that we are no longer expecting targets, and lock the skill selection for the active minion, before moving on to the next minion.

### Enemy Actions

Once we select the actions for all player minions, we still have to assign some action to the enemy minions.
An easy choice to start testing things is to let the enemies do nothing every time.
With a little more effort, however, we can put together a basic AI that chooses the first skill 20% of the time, the second skill 20% of the time, the third skill 20% of the time, and 40% of the time does nothing.

```gdscript
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
```

As you can see in the last line, once every minion has its action selected, it is time to move on to the next phase, the Combat phase.


## Combat Phase

In a more advanced software architecture we would delegate the different steps of the combat phase to different entities.
For instance, a skill server could implement the mechanics of each skill, while an animation server handled how the mechanics are displayed, and the `BattleScene` implemented the top-level glue.
To simplify this tutorial, again, we are bundling everything into one place.

Let us start by going over what needs to happen in the Combat phase.

1. Sort the minions by *Speed* value, where lower values should act first.
2. Go through each minion (in order) and take its select action, target and skill effect.
3. Resolve the selected action with the provided arguments.
4. Once all actions are resolved, move to the next round.

Recall also that dead minions should not act.
We have to add a clause to skip those.

```gdscript
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
    call_deferred("_next_round")
```

We see a few helper functions here, so let's get into the details of each.

### Sorting Minions by Speed Value

We start by creating a new `Array` holding the references to the `Minion` scenes, as we see in the first line of the function.
Then, we sort the new array by our speed parameter.
We do not change the original array, so that we can still access minions by index correctly later on.

```gdscript
    var minions = _ui_minions.duplicate()
    minions.sort_custom(self, "_minion_speed_sort")
```

Now, for the speed sort function.
This is a function that takes two minions, `a` and `b`, and should return `true` if `a` is *less than* `b`.
In this context, *less than* means *faster than*.

```gdscript
var _tie_break_player: bool = true
var _speed_tied: bool = false

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
```

This is not as trivial as one might have thought initially.
That is mostly because of the speed tie mechanic.

To break ties between minions of the same team, the minion with the lowest *index* (the one that appears first) wins.
To break ties between player and enemy minions, we resort to the tie breaker mechanic mentioned before.
Basically, the player wins all the speed ties in the first round a speed tie happens, then the enemy wins the next time, and so on.

The `_tie_break_player` variable tells whether the tie breaker is in favour of the player, while the `_speed_tied` variable tells whether there was a speed tie in the current round.

### Fetching Selected Actions

There is nothing much to discuss here.
We traverse the minions *sorted by speed*, get the minion index of each, and then use the index to get the stored actions, targets and effects.
We skip dead minions, and we skip minions that decide to do nothing on that turn (action is `-1`).

```gdscript
    for i in range(len(minions)):
        if minions[i].minion_health <= 0:
            continue
        var j = minions[i].minion_index
        var action = _input_actions[j]
        var target = _ui_minions[_input_targets[j]]
        var effect = _input_effects[j]
        if action < 0:
            continue
```

### Implementing Skill Effects

Depending on the selected skill effect, we execute a function that implemented the desired mechanics.
Unknown effects fall into an `assert(false)` statement, to help with debugging.

```gdscript
        match effect:
            0:
                _basic_attack(minions[i], target)
            1:
                _safe_attack(minions[i], target, 2)
            2:
                _basic_heal(minions[i], target, 6)
            _:
                assert(false, "effect not yet implemented")
```

All effects are relatively simple in this case, and make use of the Minion Interface we defined previously.
Note that the implementations presented here are simplified.
The final version will take animations into consideration, so that the effects do not happen instantly.

#### Basic Attack

A basic attack has both minions deal damage to each other.

```gdscript
func _basic_attack(attacker, defender):
    defender.take_damage(attacker.minion_power)
    attacker.take_damage(defender.minion_power)
```

#### Safe/Quick Attack

A safe attack deals damage from afar, or without giving the defender an opportunity to respond.
The attacker does not take damage in return.

```gdscript
func _safe_attack(attacker, defender, dmg):
    defender.take_damage(dmg)
```

#### Basic Heal

A basic heal skill restores some health to a minion.

```gdscript
func _basic_heal(caster, target, dmg):
    target.heal_damage(dmg)
```

### Moving to the Next Round

All that is left is to implement a function that ends the current round, after all actions have been resolved, and starts a new round.
It is also an appropriate place to check for victory conditions.

```gdscript
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
```

As we can see, we have to do some house keeping upon ending the round.
If there was a speed tie in the current round, we should flip the tie breaker in favour of the other player.
Then, we reset all stored actions, targets and effects (not strictly necessary, but good practice).
Lastly, we reset the UI of each minion and call its `end_round()` method, for minions to do their own house keeping too (such as updating skill cooldowns).

Once all is done, we move back to the previous phase, the Planning phase, starting with the collection of player input.
As seen previously, this will pop up the action bar, and close the loop over all the previous steps.

This concludes the main game logic.
All that is missing now is some animation and finishing touches, so that things do not look so static, and so that updates are not instantaneous.
