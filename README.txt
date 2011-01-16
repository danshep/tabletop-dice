I'm working for a dice-roller for my tabletop. Currently I can do all the orokos stuff that's relevant for d&d:

2d20k1 (roll two, keep 1 - ie, oath of enmity)
2d6b1 (brutal 1)

Can anybody point me to any other weird dice things that you might need? For example, I think there's a feat that lets you treat any roll of 3 or less as a 3? I'd like to get a fairly comprehensive list of such things before I start assigning them letters.

Once I'm done I should allow for expressions like:

2[W]+dex+flag_combat_advantage(2d8+6) 
1d6+offhand_weapon+int+target_bloodied(1d6)

There will be some built-in flags, such as bloodied, target_bloodied and probably some others when I get there, and I'll hopefully make anything prefixed 'flag' be parsed for and give you a checkbox for each target to say whether the flag applies or not.

You would define your weapon(s) seperately on your sheet as:
dice: 2d6b1 - atk_bonus: +3 - dmg_bonus: +3 - crit: 1d10

There'll also be a section on your sheet to define other attack/damage enhancement dice using the same mechanics with flags, etc - and probably also some scope for making status effects play into this as well.


