extends CharacterBody2D
class_name FieldPlayer
## 탑다운 필드에서 조작하는 플레이어.
## 요구사항: WASD · 방향키 · 조이스틱 이동(design/requirements/00-overview.md).
##
## 스프라이트 시트가 지정되지 않으면 단순 도형(placeholder)으로 그린다.
## 정식 캐릭터 에셋이 없는 동안에는 이쪽이 기본이고,
## 시트를 넣어 확인하는 것은 test 씬에서만 한다.

const SPEED: float = 220.0
const ACCELERATION: float = 2200.0
const FRICTION: float = 2600.0

const DIRECTIONS: Array[String] = ["down", "up", "left", "right"]

## 스프라이트 시트(없으면 도형으로 대체).
@export var sprite_sheet: Texture2D = null
@export var sheet_columns: int = 8
@export var sheet_rows: int = 5
## 걸을 때 쓸 행 번호. 아래·위·왼쪽·오른쪽 순서.
@export var direction_rows: PackedInt32Array = PackedInt32Array([1, 2, 3, 4])
## 제자리에 설 때 쓸 행 번호. 같은 순서.
## 걷기 행과 번호가 같으면 그 행의 첫 프레임(서 있는 자세)만 쓰고,
## 다르면 그 행 전체를 전용 idle 애니메이션으로 재생한다.
@export var idle_rows: PackedInt32Array = PackedInt32Array([0, 2, 3, 4])
@export var animation_fps: float = 10.0
## 전용 idle 행은 보통 더 느리게 재생한다.
@export var idle_fps: float = 5.0
@export var sprite_scale: float = 1.0
## 픽셀 아트 시트를 쓸 때 켠다. 최근접 필터 + 정수 픽셀 정렬로 떨림을 없앤다.
@export var pixel_snap: bool = false

var controllable: bool = false:
	set(value):
		controllable = value
		if not value:
			velocity = Vector2.ZERO
			_update_animation(Vector2.ZERO)

var _facing: String = "down"
var _anim: AnimatedSprite2D
var _placeholder: Node2D


func _ready() -> void:
	_anim = $Sprite
	_placeholder = $Placeholder
	if sprite_sheet != null:
		_anim.sprite_frames = _build_sprite_frames()
		_anim.scale = Vector2.ONE * sprite_scale
		_anim.visible = true
		_placeholder.visible = false
		if pixel_snap:
			_anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		set_process(pixel_snap)
	else:
		_anim.visible = false
		_placeholder.visible = true
		set_process(false)
	_update_animation(Vector2.ZERO)


## 스프라이트를 정수 픽셀에 맞춰 떨림(지지직거림)을 없앤다.
func _process(_delta: float) -> void:
	_anim.position = global_position.round() - global_position


func _physics_process(delta: float) -> void:
	var direction: Vector2 = _read_direction() if controllable else Vector2.ZERO
	if direction == Vector2.ZERO:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	else:
		velocity = velocity.move_toward(direction * SPEED, ACCELERATION * delta)
	move_and_slide()
	_update_animation(direction)


func facing() -> String:
	return _facing


## 시트의 방향별 행 매핑을 바꾸고 애니메이션을 다시 만든다(test 씬에서 확인용).
func set_direction_rows(walk: PackedInt32Array, idle: PackedInt32Array) -> void:
	direction_rows = walk
	idle_rows = idle
	if sprite_sheet == null or _anim == null:
		return
	_anim.sprite_frames = _build_sprite_frames()
	var idle_name := StringName("idle_%s" % _facing)
	if _anim.sprite_frames.has_animation(idle_name):
		_anim.play(idle_name)


func _read_direction() -> Vector2:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.length() > 1.0:
		direction = direction.normalized()
	return direction


func _update_animation(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		if absf(direction.x) > absf(direction.y):
			_facing = "right" if direction.x > 0.0 else "left"
		else:
			_facing = "down" if direction.y > 0.0 else "up"

	if _placeholder.visible:
		_placeholder.set("facing", _facing)
		_placeholder.set("walking", direction != Vector2.ZERO)
		return

	if _anim.sprite_frames == null:
		return
	var prefix: String = "walk" if direction != Vector2.ZERO else "idle"
	var animation_name: StringName = StringName("%s_%s" % [prefix, _facing])
	if _anim.sprite_frames.has_animation(animation_name) and _anim.animation != animation_name:
		_anim.play(animation_name)


## 시트를 행 단위로 잘라 walk_*/idle_* 애니메이션을 만든다.
func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var frame_size := Vector2(
		float(sprite_sheet.get_width()) / float(maxi(sheet_columns, 1)),
		float(sprite_sheet.get_height()) / float(maxi(sheet_rows, 1))
	)
	for i: int in DIRECTIONS.size():
		var walk_row: int = _row_at(direction_rows, i, 0)
		var idle_row: int = _row_at(idle_rows, i, walk_row)
		_add_row(frames, StringName("walk_%s" % DIRECTIONS[i]), walk_row, frame_size, sheet_columns, animation_fps)
		if idle_row == walk_row:
			# 전용 idle 행이 없으면 걷기 행의 첫 프레임을 서 있는 자세로 쓴다.
			_add_row(frames, StringName("idle_%s" % DIRECTIONS[i]), idle_row, frame_size, 1, animation_fps)
		else:
			_add_row(frames, StringName("idle_%s" % DIRECTIONS[i]), idle_row, frame_size, sheet_columns, idle_fps)
	return frames


func _row_at(rows: PackedInt32Array, index: int, fallback: int) -> int:
	if index >= rows.size():
		return fallback
	return clampi(rows[index], 0, sheet_rows - 1)


func _add_row(
	frames: SpriteFrames,
	animation_name: StringName,
	row: int,
	frame_size: Vector2,
	columns: int,
	fps: float
) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	for column: int in columns:
		var atlas := AtlasTexture.new()
		atlas.atlas = sprite_sheet
		atlas.region = Rect2(Vector2(column, row) * frame_size, frame_size)
		# 이웃 프레임의 픽셀이 새어 들어오는 것(테두리 지지직거림)을 막는다.
		atlas.filter_clip = true
		frames.add_frame(animation_name, atlas)
