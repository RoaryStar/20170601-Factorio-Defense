# Factorio Defense
Turing-based RTS, Tower-Defense-style game inspired by [Factorio](www.factorio.com "Official Factorio Website") for my 11th grade final project.

Unlicensed.

Development began May 12, and ends June 12, 2017.

### Objective
In this game, one balances furthering production so as to escape the hostile planet on a spaceship with keeping the hostile inhabitants at bay by manufacturing, placing, supplying, and repairing turrets.

### Interface
The map, which shows the current location of turrets and aliens at the entrance to the player's compound, is displayed as a grid on the left side of the screen. On the right is a list of stats and a slidebar, which the player uses to allocate their production. Availabe resources are shown next to their position on the slider.

Due to the fact that picture graphics for this game, in Turing, would require at least 615 separate images (yes, I counted), all items are only represented by basic graphics: red squares are aliens, coloured ovals are turrets, dots are projectiles, and darker tiles are walls.

### How to Run this Game
1. Download [Open Turing](tristan.hume.ca/openturing) and the _Factorio Defense_ folder in this repository.
2. Open `Main.t` with Open Turing, and press `F1` or the `Run` button.

### Troubleshooting
_The sound effects are terrible!_ 

Sorry, that's a problem with Turing, which only gives me three channels to work with. If you want to get rid of the constant lag, rename (or outright delete) the `Sounds/Effects` folder.


## Construction of the Game
Making this game presented many challenges, and in the end it was completed with many, many interesting optimizations and infrastructure.
This is intended to be a comprehensive list of those challenges, optimizations, and infrastructure decisions.

### Pathing
The very first problem I thought of was that of pathing fifty entities through a fifty-by-fifty-tile map with multiple possible endpoints. While [A\*](https://en.wikipedia.org/wiki/A*_search_algorithm) is optimal against [Dijkstra's algorithm](https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm) in the sense that it's not just a BFS, it only works well with one endpoint. [JPS](https://en.wikipedia.org/wiki/Jump_point_search), the only other algorithm I know of which is efficient in node-dense graphs, wouldn't work either as it requires that all edges have uniform weights. If that were the case, I wouldn't be able to prevent aliens from running straight into their own deaths. Even if they worked, they'd have to be run fifty times every few ticks; which is unacceptable in a language as slow as Turing.

In addition to the issues with timing, storing paths, moving smoothly, and avoiding bunching up would have presented a massive headache.

So, instead of pathing each individual alien, I decided to have them follow a game-generated flow field. This way, only one call to a pathing algorithm would be needed every few hundred ticks, no paths would need to be stored, and moving smoothly and not bunching up becomes rather trivial.

In `Files/Code/class_vars.t`, you can find `proc path_map()`, which generates the flow field (`map_mov`) using Dijkstra's algorithm with the appropriate source points. Above it, you'll find `push_to_heap` and `pop_from_heap`, which were needed for the priority queue.

In `Classes/enemy.t`, you can find in `proc pre_update()` that, after following the flow field, aliens will check for other aliens around so as to not invade each other's personal space. The algorithm is based on the Separation behaviour outlined in [Craig W. Reynolds' Steering Behaviors for Autonomous Characters](http://www.red3d.com/cwr/steer/gdc99/).

### Projectile Efficiency
Ideally, turrets will not waste ammunition firing at aliens which would have die once all the already-in-the-air projectiles have reached their target. But because a lot of projectiles are not instantaneous, turrets and aliens can't directly lower the health of their targets when firing.

Instead, all entities have an `effective_health` as well as their `health`.

You can find the health interactions between turrets, projectiles, and aliens in `Classes/enemy.t` and `Classes/turret.t` in `proc fire_projectile (u : unchecked ^entity_vars)` and in `Classes/projectile.t` in `proc update()` inside the hit checks.

### Choosing and Retaining Targets
Ideally, turrets and spitters (ranged aliens) would aim for and fire at the closest target. But Turing is slow, and checking ranges and finding the nearest of fifty aliens for up to a hundred turrets and vice-versa every tick would be an issue.

Instead, each entity can cache a target, and search for a new one once that target has died or has left its range.

In `Classes/enemy.t` and `Classes/turret.t`, you can see that in `proc update()`, in addition to the other checks for validity, every entity will check if they have a target, if the target is dead (or effective health indicates such), or if they are out of range before either firing or preparing to fire a projectile or, in the case of the aliens, move.
