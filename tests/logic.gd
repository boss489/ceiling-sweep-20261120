extends SceneTree
const Game = preload("res://game.gd")
func _initialize() -> void:
 var g = Game.new()
 root.add_child(g)
 await process_frame
 assert(g.mode == "title")
 for ch in "천장 청소반 중력 반전 먼지 충돌 완료 ○●←→↕":
  assert(g.FONT.has_char(ch.unicode_at(0)), "Missing font glyph: " + ch)
 g.start_game()
 assert(g.mode == "playing" and g.section == 0 and g.dust.size() == 12)
 assert(g.dust.filter(func(d): return d["section"] == 0).size() == 4)
 var initial = g.gravity
 var size = g.get_viewport().get_visible_rect().size
 g.handle_pointer(Vector2(size.x * 0.84, size.y * 0.82), true, 41)
 assert(g.touch_dir == 1, "Touch right held")
 g.handle_pointer(Vector2(size.x * 0.84, size.y * 0.82), false, 41)
 assert(g.touch_dir == 0, "Touch release clears motion")
 g.handle_pointer(Vector2(size.x * 0.5, size.y * 0.82), true, 42)
 assert(g.gravity == -initial, "Touch flip")
 g.flip()
 assert(g.gravity == initial)
 g.flip()
 assert(g.gravity == -initial)
 g.flip()
 assert(g.gravity == initial)
 g.player_x = g.dust[0]["x"]
 g.player_y = g.rail_y(g.dust[0]["top"])
 g.check_pickups()
 assert(g.collected == 1)
 g.check_pickups()
 assert(g.collected == 1)
 g.mode = "title"
 g.resume_game()
 assert(g.mode == "playing" and g.collected == 1 and g.dust[0]["taken"], "Saved collection must resume")
 assert(g.invulnerable > 0.0, "Resume grants temporary protection")
 g.invulnerable = 0.0
 g.take_hit()
 assert(g.hits == 1)
 g.take_hit()
 assert(g.hits == 1)
 g.invulnerable = 0.0
 g.take_hit()
 g.invulnerable = 0.0
 g.take_hit()
 assert(g.mode == "failure" and g.hits == 3)
 g.mode = "title"
 g.has_save = true
 g.handle_pointer(Vector2(480, 555), true, -1)
 assert(g.mode == "tutorial", "Start button must not resume an existing save")
 g.start_game()
 assert(g.collected == 0 and g.hits == 0 and g.mode == "playing")
 g.section_time = 0.01
 g.advance_time(0.02)
 assert(g.section == 1 and g.mode == "playing")
 g.section_time = 0.01
 g.advance_time(0.02)
 assert(g.section == 2)
 g.collected = 9
 g.section_time = 0.01
 g.advance_time(0.02)
 assert(g.mode == "success")
 g.start_game()
 g.section = 2
 g.collected = 8
 g.section_time = 0.01
 g.advance_time(0.02)
 assert(g.mode == "failure")
 print("PASS: title/start, font glyphs, 12 dust/sections, gravity, one-shot pickup, invulnerability, 3-hit failure, restart, section boundaries, win and time failure")
 g.queue_free()
 await process_frame
 quit()
