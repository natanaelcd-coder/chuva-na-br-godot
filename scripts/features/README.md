# Features

Every `*.gd` in this folder is loaded automatically by `game.gd` (`_load_features`, alphabetical order) as a
`Node` child of the game. A feature script `extends Node`, grabs the game with `g = get_parent()` in `_ready`,
and talks to the rest only through the points below. Keep features self-contained: one idea, one file
(or a few), so several can be worked on at the same time.

## Signals on the game (`g`)

| Signal | When |
|---|---|
| `setup_done` | the trip was (re)built (menu change, start) |
| `trip_started` | the player took the wheel (`begin()`) |
| `trip_ended(summary)` | back to the menu; summary: `km, minutes, holes, puddles, bumps, score, car, road, weather, time` |
| `seg_passed(i)` | the car crossed road segment `i` (`g.segs[i]` has `spr`, `feat`, `curve`) |
| `hole_hit(f, side, k)` / `hole_missed(f, d)` | a pothole under a wheel / one that went between or beside the wheels |
| `puddle_hit(f)` | splash |
| `bumped(kind)` | `"rear"`, `"side"`, `"oncoming"`, `"rail"` |
| `refueled(stop_i)` | filled up at a stop |

## Methods a feature may implement (called if present)

| Method | Called from | Use |
|---|---|---|
| `drive_key(k) -> bool` | input while driving | return `true` to consume the key |
| `menu_info() -> String` | menu refresh | replaces the line under the title if not empty |
| `draw_sky(world, hy)` | `world.gd`, after sun/moon, before hills | rainbow, balloons |
| `draw_car(world, c, rect, alpha)` | `world.gd`, after each traffic sprite | bumper phrases, blinkers |
| `draw_world_over(world)` | `world.gd`, after road and traffic | overlays in world units (384x216) |
| `draw_hang(cockpit, anchor)` | `cockpit.gd`, after the mirror ornaments | more things hanging from the mirror |
| `draw_cabin_mid(cockpit)` | `cockpit.gd`, before gauges, wheel and arm | passenger, dash items |
| `draw_cabin_over(cockpit)` | `cockpit.gd`, last | anything over the cabin |

Draw with the node passed in (`world.draw_rect(...)`, `cockpit.draw_circle(...)`); both work in logical units.

## Services

- Save: `g.store_get(section, key, default)`, `g.store_set(section, key, value)`, `g.store_save()` (one `user://viagem.cfg`; nothing is written in tests).
- Menu: `g.menu.add_main_item(label, callable)`, `g.menu.add_pause_item(label, callable)`,
  `g.menu.open_screen(title, builder(body: Control), on_key(k))`, `g.menu.close_screen()`,
  helpers `g.menu.label(txt, size, color, pos, parent)` and `g.menu.box(rect, color, parent)`.
- HUD: `g.hud.toast(text, dur)` (big, centre: use rarely), `g.hud.notice(text, dur)` (discreet line), `g.hud.set_now(text)` (radio strip).
- State you can read: `g.state` (`menu|drive|pause`), `g.started`, `g.cfg`, `g.car`, `g.road`, `g.v`, `g.px`, `g.pos`, `g.tday`, `g.rain`,
  `g.km_trip`, `g.trip_time`, `g.cars`, `g.segs`, `g.N`, `g.SEG`, `g.LANES`. Comfort: `g.view_sway` scales view roll/pitch,
  `g.view_shake` the inside camera's bounce. Trip seed: `g.trip_seed` (what `setup()` drew the road/traffic with; 0 in tests);
  set `g.next_seed` before `g.setup()` to rebuild a given trip. The trip code is `get_node("../codigo").current()`, and
  `summary.code` / `summary.manobras` are added to `trip_ended`'s summary.
- Audio buses: `Radio`, `Chuva`, `Motor`, `Efeitos` (made by `ajustes.gd`, each with its own volume); put new players on one.
- Art: new sprites go in `tools/art/art_<name>.js` (`Object.assign(window.ART, {...})`), built with `node tools/art/build_art.js`, loaded with `load("res://assets/sprites/<name>.png")`.
