extends Node2D

const FONT = preload("res://assets/GowunDodum-Regular.ttf")
const INK = Color("203047")
const CREAM = Color("f7f3e9")
const TEAL = Color("55b9ad")
const ORANGE = Color("f4a65f")
const PINK = Color("e87e82")
const BLUE = Color("526387")
var mode := "title"
var section := 0
var section_time := 20.0
var player_x := 0.08
var player_y := 1.0
var gravity := 1
var collected := 0
var hits := 0
var invulnerable := 0.0
var dust: Array[Dictionary] = []
var left_held := false
var right_held := false
var touch_dir := 0
var elapsed := 0.0
var pulse := 0.0
var best := 0
var has_save := false
var sound: AudioStreamPlayer
var last_touch_ms := -10000
var touch_ids := {}

func _ready() -> void:
 sound = AudioStreamPlayer.new()
 add_child(sound)
 load_state()
 # Opt-in visual QA in the actual Godot Web build, restricted to localhost.
 if OS.has_feature("web") and JavaScriptBridge.eval("location.hostname === 'localhost' || location.hostname === '127.0.0.1'"):
  var qa: String = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('qa') || ''"))
  if qa in ["success", "timeout", "collision"]:
   start_game()
   if qa == "success":
    collected = 9
    section = 2
    section_time = 0.01
    advance_time(0.02)
   elif qa == "collision":
    for i in 3:
     invulnerable = 0.0
     take_hit()
   else:
    section = 2
    section_time = 0.01
    advance_time(0.02)
 set_process(true)
 queue_redraw()

func rail_y(top: bool) -> float:
 return 0.0 if top else 1.0

func start_game() -> void:
 mode = "playing"
 section = 0
 section_time = 20.0
 collected = 0
 hits = 0
 gravity = 1
 player_x = 0.08
 player_y = 1.0
 invulnerable = 0.0
 elapsed = 0.0
 left_held = false
 right_held = false
 touch_dir = 0
 touch_ids.clear()
 dust.clear()
 # Four per bay; alternate floor / ceiling so the switch is essential.
 for s in 3:
  for i in 4:
   dust.append({"section": s, "x": [0.23, 0.43, 0.65, 0.84][i], "top": (i + s) % 2 == 1, "taken": false})
 save_state()
 queue_redraw()

func flip() -> void:
 if mode != "playing": return
 gravity *= -1
 pulse = 0.24
 play_sound("flip")
 queue_redraw()

func check_pickups() -> void:
 if mode != "playing": return
 for d in dust:
  if d["section"] == section and not d["taken"] and absf(player_x - d["x"]) < 0.05 and absf(player_y - rail_y(d["top"])) < 0.14:
   d["taken"] = true
   collected += 1
   pulse = 0.32
   play_sound("pickup")
   save_state()

func take_hit() -> void:
 if mode != "playing" or invulnerable > 0.0: return
 hits += 1
 invulnerable = 1.5
 pulse = 0.45
 play_sound("hit")
 if hits >= 3:
  finish(false)
 else:
  save_state()

func advance_time(delta: float) -> void:
 if mode != "playing": return
 section_time -= delta
 if section_time <= 0.0:
  if section == 2:
   finish(collected >= 9)
  else:
   section += 1
   section_time = 20.0
   player_x = 0.08
   player_y = 1.0
   gravity = 1
   invulnerable = 1.0
   save_state()

func finish(won: bool) -> void:
 mode = "success" if won else "failure"
 if won: best = maxi(best, collected)
 has_save = false
 save_state()
 play_sound("win" if won else "hit")
 queue_redraw()

func _process(delta: float) -> void:
 elapsed += delta
 pulse = maxf(0.0, pulse - delta)
 if mode == "playing":
  invulnerable = maxf(0.0, invulnerable - delta)
  var dx := int(right_held) - int(left_held) + touch_dir
  dx = clampi(dx, -1, 1)
  var speed := 0.60 if logical_size().x < 500 else 0.48
  player_x = clampf(player_x + dx * speed * delta, 0.04, 0.96)
  player_y = clampf(player_y + gravity * 1.75 * delta, 0.0, 1.0)
  check_pickups()
  # Two drifting obstacles per section, on opposite rails.
  for h in 2:
   var hx := 0.52 + 0.29 * h + sin(elapsed * (1.6 + h * 0.3) + section + h) * 0.055
   var hy := float(h)
   if absf(player_x - hx) < 0.038 and absf(player_y - hy) < 0.13:
    take_hit()
  advance_time(delta)
 queue_redraw()

func logical_size() -> Vector2:
 var v := get_viewport().get_visible_rect().size
 return Vector2(700.0 * v.x / maxf(v.y, 1.0), 700.0) if v.x / maxf(v.y, 1.0) < 0.85 else Vector2(640.0 * v.x / maxf(v.y, 1.0), 640.0)

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey:
  if event.keycode in [KEY_LEFT, KEY_A]:
   left_held = event.pressed
   get_viewport().set_input_as_handled()
  elif event.keycode in [KEY_RIGHT, KEY_D]:
   right_held = event.pressed
   get_viewport().set_input_as_handled()
  elif event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_UP, KEY_W]:
   if mode == "playing": flip()
   elif mode == "title" or mode == "tutorial": mode = "tutorial" if mode == "title" else "playing"; if mode == "playing": start_game()
   else: start_game()
   get_viewport().set_input_as_handled()
  elif event.pressed and not event.echo and event.keycode == KEY_ENTER:
   if mode == "title": mode = "tutorial"
   elif mode == "tutorial" or mode in ["success", "failure"]: start_game()
   get_viewport().set_input_as_handled()
 elif event is InputEventScreenTouch:
  last_touch_ms = Time.get_ticks_msec()
  handle_pointer(event.position, event.pressed, event.index)
 elif event is InputEventScreenDrag:
  last_touch_ms = Time.get_ticks_msec()
  handle_pointer(event.position, true, event.index)
 elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
  if Time.get_ticks_msec() - last_touch_ms > 550:
   handle_pointer(event.position, event.pressed, -1)

func handle_pointer(position: Vector2, pressed: bool, pointer_id: int) -> void:
 var v := get_viewport().get_visible_rect().size
 var p := position * logical_size() / v
 var w := logical_size().x
 var h := logical_size().y
 if not pressed:
  touch_ids.erase(pointer_id)
  update_touch_direction()
  return
 if touch_ids.has(pointer_id):
  touch_ids[pointer_id] = pointer_zone(p)
  update_touch_direction()
  return
 if mode == "title":
  var title_button_y := 550.0 if h > 680 else 544.0
  if has_save and p.y > title_button_y + 68.0:
   resume_game()
  else:
   mode = "tutorial"
 elif mode == "tutorial":
  start_game()
 elif mode == "success" or mode == "failure":
  start_game()
 elif mode == "playing":
  var zone := pointer_zone(p)
  touch_ids[pointer_id] = zone
  if zone == 0 and p.y > h * 0.65: flip()
  update_touch_direction()
 queue_redraw()

func pointer_zone(p: Vector2) -> int:
 var w := logical_size().x
 var h := logical_size().y
 if p.y < h * 0.65: return 0
 if p.x < w * 0.32: return -1
 if p.x > w * 0.68: return 1
 return 0

func update_touch_direction() -> void:
 touch_dir = 0
 for direction in touch_ids.values():
  touch_dir += direction
 touch_dir = clampi(touch_dir, -1, 1)

func save_state() -> void:
 var cfg := ConfigFile.new()
 cfg.set_value("record", "best", best)
 cfg.set_value("run", "active", mode == "playing")
 cfg.set_value("run", "section", section)
 cfg.set_value("run", "time", section_time)
 cfg.set_value("run", "collected", collected)
 cfg.set_value("run", "hits", hits)
 cfg.set_value("run", "dust", dust)
 cfg.set_value("run", "x", player_x)
 cfg.set_value("run", "y", player_y)
 cfg.set_value("run", "gravity", gravity)
 cfg.save("user://ceiling_sweep.cfg")
 has_save = mode == "playing"

func load_state() -> void:
 var cfg := ConfigFile.new()
 if cfg.load("user://ceiling_sweep.cfg") == OK:
  best = int(cfg.get_value("record", "best", 0))
  has_save = bool(cfg.get_value("run", "active", false))

func resume_game() -> void:
 var cfg := ConfigFile.new()
 if cfg.load("user://ceiling_sweep.cfg") != OK: return
 section = clampi(int(cfg.get_value("run", "section", 0)), 0, 2)
 section_time = clampf(float(cfg.get_value("run", "time", 20.0)), 0.1, 20.0)
 collected = int(cfg.get_value("run", "collected", 0))
 hits = int(cfg.get_value("run", "hits", 0))
 dust = cfg.get_value("run", "dust", [])
 player_x = float(cfg.get_value("run", "x", 0.08))
 player_y = float(cfg.get_value("run", "y", 1.0))
 gravity = int(cfg.get_value("run", "gravity", 1))
 mode = "playing"
 invulnerable = 1.0
 queue_redraw()

func play_sound(kind: String) -> void:
 if sound == null: return
 var path := "res://assets/" + kind + ".wav"
 if ResourceLoader.exists(path):
  sound.stream = load(path)
  sound.play()

func text(s: String, at: Vector2, size: int, color: Color = INK, align: int = 0) -> void:
 var width := FONT.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
 var x := at.x - width * (0.5 if align == 1 else 1.0 if align == 2 else 0.0)
 draw_string(FONT, Vector2(x, at.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func panel(r: Rect2, color: Color, border: Color = INK) -> void:
 draw_rect(Rect2(r.position + Vector2(3, 4), r.size), border.darkened(0.12))
 draw_rect(r, color)
 draw_rect(r, border, false, 2.0)

func button(r: Rect2, label: String, color: Color = ORANGE, size: int = 22) -> void:
 panel(r, color)
 text(label, Vector2(r.position.x + r.size.x / 2, r.position.y + r.size.y / 2 + size * 0.35), size, INK, 1)

func _draw() -> void:
 var v := get_viewport().get_visible_rect().size
 var l := logical_size()
 draw_set_transform(Vector2.ZERO, 0.0, v / l)
 draw_rect(Rect2(Vector2.ZERO, l), CREAM)
 for i in 44:
  var px := fmod(float(i * 173 + 29), l.x)
  var py := fmod(float(i * 127 + 71), l.y)
  draw_circle(Vector2(px, py), 1.7, Color("dcded7"))
 var mobile := l.x < 500
 if mode == "title": draw_title(l, mobile)
 elif mode == "tutorial": draw_tutorial(l, mobile)
 elif mode == "playing": draw_game(l, mobile)
 else: draw_result(l, mobile)
 draw_set_transform(Vector2.ZERO)

func draw_header(l: Vector2, small: bool) -> void:
 draw_rect(Rect2(0, 0, l.x, 7), TEAL)
 text("천장 청소반", Vector2(28, 43 if small else 54), 26 if small else 34)
 text("CEILING SWEEP  /  NIGHT SHIFT 03", Vector2(l.x - 22, 39 if small else 50), 11 if small else 14, BLUE, 2)

func draw_title(l: Vector2, small: bool) -> void:
 draw_header(l, small)
 var cx := l.x / 2
 var top := 115.0 if small else 100.0
 draw_rect(Rect2(26, top, l.x - 52, 9), INK)
 draw_rect(Rect2(26, top + (340 if small else 340), l.x - 52, 9), INK)
 for i in 7:
  var xx := 48 + i * (l.x - 96) / 6
  draw_circle(Vector2(xx, top + (30 if i % 2 else 310)), 9, ORANGE)
  draw_line(Vector2(xx, top + (30 if i % 2 else 310) - 5), Vector2(xx + 4, top + (30 if i % 2 else 310) + 5), CREAM, 2)
 draw_character(Vector2(cx, top + 170), 1, false)
 text("위아래를 뒤집어 먼지를 쓸어 담으세요", Vector2(cx, top + (393 if small else 393)), 18 if small else 25, INK, 1)
 var by := 550.0 if small else 544.0
 button(Rect2(cx - (155 if small else 155), by, 310, 58), "근무 시작  →", TEAL, 25)
 if has_save:
  text("저장된 근무 이어하기  ↓", Vector2(cx, by + 84), 18, INK, 1)
 else:
  text("최고 기록  %02d / 12" % best, Vector2(cx, by + 85), 16, BLUE, 1)

func draw_tutorial(l: Vector2, small: bool) -> void:
 draw_header(l, small)
 var margin := 22.0 if small else 160.0
 var y := 98.0 if small else 103.0
 panel(Rect2(margin, y, l.x - 2 * margin, 478 if small else 405), Color("fffdf6"))
 text("근무 안내", Vector2(l.x / 2, y + 55), 33, INK, 1)
 var lines := ["01   ← →  /  A D   좌우 이동", "02   SPACE  /  ↑   중력 반전", "03   바닥과 천장의 먼지 12개", "04   3구간 × 20초 / 9개면 성공", "05   장애물에 3번 닿으면 종료"]
 for i in lines.size():
  text(lines[i], Vector2(margin + 23, y + 112 + i * (64 if small else 52)), 18 if small else 22)
 text("터치: 화면 아래 양쪽 이동 · 가운데 반전", Vector2(l.x / 2, y + (448 if small else 383)), 16 if small else 17, BLUE, 1)
 button(Rect2(l.x / 2 - 150, 605 if small else 547, 300, 60), "청소 시작  →", TEAL, 24)

func draw_game(l: Vector2, small: bool) -> void:
 draw_header(l, small)
 var top := 180.0 if small else 166.0
 var bottom := 450.0 if small else 455.0
 var x0 := 24.0 if small else 48.0
 var x1 := l.x - x0
 text("구간 %d / 3" % (section + 1), Vector2(x0, 85 if small else 91), 20)
 text("먼지 %02d / 09" % collected, Vector2(l.x / 2, 85 if small else 91), 20, TEAL.darkened(0.35), 1)
 text("남은 %02d초" % ceili(section_time), Vector2(x1, 85 if small else 91), 20, INK, 2)
 draw_rect(Rect2(x0, 105 if small else 110, x1 - x0, 11), Color("e2e5dc"))
 draw_rect(Rect2(x0, 105 if small else 110, (x1 - x0) * section_time / 20.0, 11), TEAL)
 text("위쪽 레일", Vector2(x0, top - 18), 16 if small else 13, BLUE)
 text("아래쪽 레일", Vector2(x0, bottom + 31), 16 if small else 13, BLUE)
 draw_rect(Rect2(x0, top - 8, x1 - x0, 16), INK)
 draw_rect(Rect2(x0, bottom - 8, x1 - x0, 16), INK)
 for j in 14:
  var xx := x0 + j * (x1 - x0) / 13
  draw_line(Vector2(xx, top - 8), Vector2(xx + 8, top + 8), BLUE, 2)
  draw_line(Vector2(xx, bottom - 8), Vector2(xx + 8, bottom + 8), BLUE, 2)
 for d in dust:
  if d["section"] != section or d["taken"]: continue
  var xx: float = x0 + float(d["x"]) * (x1 - x0)
  var yy := top + 26 if d["top"] else bottom - 26
  draw_circle(Vector2(xx, yy), 13 + 2 * sin(elapsed * 5 + xx), ORANGE)
  draw_circle(Vector2(xx - 3, yy - 3), 3, CREAM)
  draw_circle(Vector2(xx + 6, yy + 2), 2, CREAM)
 for h in 2:
  var hx := 0.52 + 0.29 * h + sin(elapsed * (1.6 + h * 0.3) + section + h) * 0.055
  var p := Vector2(x0 + hx * (x1 - x0), top + 28 if h == 0 else bottom - 28)
  draw_colored_polygon(PackedVector2Array([p + Vector2(0, -17), p + Vector2(16, 12), p + Vector2(-16, 12)]), PINK)
  draw_circle(p + Vector2(-4, 2), 2, INK)
  draw_circle(p + Vector2(4, 2), 2, INK)
 var pp := Vector2(x0 + player_x * (x1 - x0), lerpf(top + 24, bottom - 24, player_y))
 draw_character(pp, gravity, invulnerable > 0.0 and int(elapsed * 10) % 2 == 0)
 text("충돌  %s" % ("●".repeat(hits) + "○".repeat(3 - hits)), Vector2(x0, (510 if small else 520)), 18, PINK)
 text("← → 이동    SPACE 반전", Vector2(x1, (510 if small else 520)), 14 if small else 17, INK, 2)
 var by := 565.0 if small else 554.0
 button(Rect2(x0, by, (l.x - 2 * x0) * 0.28, 69), "◀", Color("dce9ec"), 27)
 button(Rect2(l.x * 0.35, by, l.x * 0.30, 69), "반전 ↕", ORANGE, 21)
 button(Rect2(l.x - x0 - (l.x - 2 * x0) * 0.28, by, (l.x - 2 * x0) * 0.28, 69), "▶", Color("dce9ec"), 27)
 text("두 손가락으로 이동과 반전을 함께 누를 수 있어요", Vector2(l.x / 2, by + 99), 15, BLUE, 1)

func draw_character(p: Vector2, direction: int, blink: bool) -> void:
 if blink: return
 draw_circle(p + Vector2(3, 5), 22, INK)
 draw_circle(p, 20, TEAL)
 draw_rect(Rect2(p + Vector2(-16, -20), Vector2(32, 9)), Color("f8d58a"))
 draw_circle(p + Vector2(-7, -3), 3, INK)
 draw_circle(p + Vector2(7, -3), 3, INK)
 draw_line(p + Vector2(-6, 9), p + Vector2(6, 9), INK, 2)
 draw_line(p + Vector2(-24, 4), p + Vector2(-36, -5 * direction), TEAL, 7)
 draw_circle(p + Vector2(-39, -7 * direction), 7, ORANGE)
 draw_line(p + Vector2(-10, 20), p + Vector2(-13, 28 * direction), INK, 4)
 draw_line(p + Vector2(10, 20), p + Vector2(13, 28 * direction), INK, 4)

func draw_result(l: Vector2, small: bool) -> void:
 draw_header(l, small)
 var won := mode == "success"
 var cx := l.x / 2
 var cy := 295.0 if small else 282.0
 for i in 16:
  var a := float(i) * TAU / 16
  var p := Vector2(cx, cy) + Vector2(cos(a), sin(a)) * (110 + 8 * sin(elapsed * 2 + i))
  draw_circle(p, 4 if won else 2, TEAL if won else PINK)
 draw_circle(Vector2(cx, cy), 84, TEAL if won else PINK)
 text("완료!" if won else "근무 종료", Vector2(cx, cy + 12), 36, CREAM, 1)
 text("먼지 %02d / 12 · 충돌 %d / 3" % [collected, hits], Vector2(cx, cy + 151), 20, INK, 1)
 text("세 구간을 모두 청소했어요" if won else "9개 수거 또는 안전 근무에 재도전", Vector2(cx, cy + 187), 17 if small else 20, BLUE, 1)
 button(Rect2(cx - 146, 534 if small else 505, 292, 66), "다시 시작", ORANGE, 26)
