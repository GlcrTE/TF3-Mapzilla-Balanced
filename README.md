# Mapzilla Balanced

A Transport Fever 3 map generator based on [Mapzilla](https://github.com/AmbachtIT/mapzilla) by Bram Fokke, with a more usable terrain split.

In the original, the mountains and the sea together cover half the map or more, and the mountain range at the far end is dead land with no towns or industry. Here there are no mountains. From the far end to the coast the land drops in steps: a strip of hills (about 22%), then rolling land with low hills that flatten out towards the coast (about 42%), then a flat coastal plain (about 26%), and the sea (about 10%). The rivers, the delta and the coast follow the new bands.

| Layout     | Hills | Rolling | Flat | Sea |
|------------|-------|---------|------|-----|
| Shore      | 22%   | 42%     | 26%  | 10% |
| Island     | 22%   | 34%     | 20%  | 25% |
| Inland sea | 22%   | 42%     | 26%  | 10% |
| Isthmus    | 21%   | 38%     | 24%  | 16% |
| Strait     | 21%   | 43%     | 26%  | 9%  |
| Peninsula  | 22%   | 36%     | 23%  | 19% |
| Bay        | 22%   | 43%     | 26%  | 10% |

On Island the map corners are always sea (about 22%), so the sea share there is higher. The shares apply at the default Mountains setting. At a high setting the game counts the hills as mountains.

Towns at the coast ask for fish more often. When a coastal town gets a new need for meat or vegetables and doesn't need fish yet, there is a 50% chance it asks for fish instead. A town that keeps its need rolls again on its next one. A town counts as coastal when water covers at least 15% of the area within 1 km of its centre. A river doesn't reach that, but a big lake can. This needs fish to be produced on the map. Inland towns pick their needs as in the base game.

In-game: New game → map settings → generator "Mapzilla Balanced - Mountains to delta".

### Germany

A second generator, "Mapzilla Balanced - Germany", copies the terrain of Germany from south to north: a narrow strip of Alps at the far end (about 7%), the rolling Alpine foreland (12%), the uplands (Mittelgebirge, 36%), hills broken up by flat basins, the flat North German Plain (35%) and the North Sea (10%). It has no Layout param: the Alps and the sea are always at the two ends of the map. Rivers rise in the Alps and run north to the sea. Coastline, Islands, Orientation and the stock sliders work as in the first generator.

## How it works

The layout tiles in `tex/layouts.tga` are plain ramps from the mountains (0) to the open sea (1). The river node (`nodes.script.lua`) now also outputs `uSteps`, a piecewise-linear curve for each layout. The node graph sends the ramp through that curve (`mz_u`, a `pwlerp_map`) before anything reads it. The knots in each layout's `remap` entry are area quantiles of the tile (end of the hills, start of the flat plain, start of the sea), measured with `tools/knots.py`. The river layout converts its own positions (source, delta, coast) through the same curve. The Germany generator has its own copy of the node tree (`mapzilla_balanced_germany.tree.lua`) with a different terrain profile and rolling relief. The tree passes `profile = 1` to the river node, which then always uses the shore tile with the `GERMANY` knots. The rolling land is the stock lowland plus a noise layer of up to 24 m (`mz_roll`), which fades out near rivers and the shore and dies out where the flat plain starts.

### Coastal fish

The engine picks a town's first needs when it creates the map, and the base game script `towns/town_growth.script` adds more as towns level up. The map generator can't change either step. So the game script `coastal_fish.script.tl` checks the towns 16 times a game day and changes new needs afterwards (`makeTownUpdateCargoNeedsCmd`). Each town and need is rolled only once, with a fixed roll per town and cargo type. The script stores which needs it has already rolled in the savegame. Added to a running game, it leaves the needs towns already have alone. It runs in every game the mod is active in, whatever the map, so the mod is no longer cosmetic.

## Tools

- `tools/check.py` type-checks the script against the game's API, checks `_content.json` and runs `tests/` (needs `pip install lupa`).

- `tools/knots.py` prints the `remap` knots for each layout. Change `HILLS`, `SEA` or `ROLLING` there and paste the result into `LAYOUTS`.
- `tools/preview.py` renders `_metadata/0.png`.
- `tools/deploy.ps1` copies the mod to the TF3 staging area. `-Target mods` installs it as a local mod instead.

## License

MIT, see [LICENSE](LICENSE). Based on Mapzilla, also MIT.
