extends GraphEdit

# ========== internal state ==========
var _fsm_nodes: Dictionary = {}
var _bt_nodes:  Dictionary = {}
var _bt_children: Dictionary = {}
var _active_fsm_state: String = ""
var _active_bt_node: BTNode
var _current_tree: BehaviorTree = null
var _current_agent: Node = null

# ========== sizing & layout ==========
const NODE_W     := 120.0  # GraphNode width
const NODE_H     := 60.0   # GraphNode height
const X_GAP      := 30.0   # horizontal gap between nodes
const Y_GAP      := 40.0   # vertical gap between rows
const ROW_SIZE   := 4      # how many nodes per row before wrapping
const TITLE_FONT := 14
const LABEL_FONT := 10

# ========== colors ==========
const COL_DEFAULT       := Color(0.20, 0.20, 0.23)
const COL_ACTIVE        := Color(0.10, 0.42, 0.18)
const COL_TITLE_DEFAULT := Color(0.70, 0.70, 0.76)
const COL_TITLE_ACTIVE  := Color(0.80, 1.00, 0.82)

const STATE_COLORS: Dictionary = {
	"IDLE":    Color(0.40, 0.60, 0.90),
	"WANDER":  Color(0.40, 0.85, 0.75),
	"CHASE":   Color(0.95, 0.75, 0.20),
	"ATTACK":  Color(0.95, 0.30, 0.30),
	"RETREAT": Color(0.80, 0.45, 0.90),
	"HURT":    Color(0.95, 0.55, 0.20),
	"DEAD":    Color(0.45, 0.45, 0.48),
	"SEARCH":  Color(0.45, 0.45, 0.48),
}

const BT_COLORS: Dictionary = {
	"BTSelector":            Color(0.20, 0.50, 0.90),
	"BTSequence":            Color(0.20, 0.75, 0.45),
	"BTDecorator":           Color(0.80, 0.65, 0.20),
	"BTParallel":            Color(0.70, 0.40, 0.85),
	"BTCondition":           Color(0.95, 0.75, 0.20),
	"BTAction":              Color(0.90, 0.35, 0.35),
	"BTCheckArea":           Color(0.40, 0.60, 0.90),
	"BTPlayAnimation":       Color(0.40, 0.85, 0.75),
	"BTMove":                Color(0.20, 0.50, 0.90),
	"BTRandomSelector":      Color(0.90, 0.35, 0.35),
	"BTCheckStatus":         Color(0.95, 0.75, 0.20),
	"BTCheckHealth":         Color(0.40, 0.85, 0.75),
	"BTCheckForDeadEnemies": Color(0.70, 0.40, 0.85),
	"BTResurrectAttack":     Color(0.90, 0.35, 0.35),
	"BTCooldown":            Color(0.60, 0.60, 0.65),
	"BTSuperAttack":         Color(0.95, 0.30, 0.30)
}

# ========== transition map ==========
const TRANSITIONS: Dictionary = {
	"IDLE":    [
		{ "to": "DEAD",    "label": "hp = 0"          },
		{ "to": "RETREAT", "label": "critical hp"     },
		{ "to": "HURT",    "label": "damaged"         },
		{ "to": "WANDER",  "label": "idle timeout"    },
		{ "to": "CHASE",   "label": "target spotted"  },
	],
	"WANDER":  [
		{ "to": "DEAD",    "label": "hp = 0"          },
		{ "to": "RETREAT", "label": "critical hp"     },
		{ "to": "HURT",    "label": "damaged"         },
		{ "to": "CHASE",   "label": "target spotted"  },
		{ "to": "IDLE",    "label": "destination reached" },
	],
	"CHASE":   [
		{ "to": "DEAD",    "label": "hp = 0"          },
		{ "to": "RETREAT", "label": "critical hp"     },
		{ "to": "HURT",    "label": "damaged"         },
		{ "to": "ATTACK",  "label": "in range"        },
		{ "to": "IDLE",    "label": "target lost"     },
	],
	"ATTACK":  [
		{ "to": "DEAD",    "label": "hp = 0"          },
		{ "to": "RETREAT", "label": "critical hp"     },
		{ "to": "HURT",    "label": "damaged"         },
		{ "to": "CHASE",   "label": "out of range"    },
		{ "to": "IDLE",    "label": "target lost"     },
	],
	"RETREAT": [
		{ "to": "DEAD",    "label": "hp = 0"          },
		{ "to": "HURT",    "label": "damaged"         },
		{ "to": "IDLE",    "label": "safe / no ally"  },
	],
	"HURT":    [
		{ "to": "DEAD",    "label": "hp = 0"          },
		{ "to": "RETREAT", "label": "critical hp + ally nearby" },
		{ "to": "IDLE",    "label": "anim finished"   },
	],
	"DEAD":    [],   # terminal
	"SEARCH":  [],
}

func _ready():
	connect("node_selected", Callable(self, "_on_node_selected"))

# ========== registration ==========
func register_agent(agent: Node) -> void:
	if agent == _current_agent:
		return
	
	# Disconnect from the OLD tree before switching
	if _current_tree != null and is_instance_valid(_current_tree):
		if _current_tree.node_ticked.is_connected(_on_node_ticked):
			_current_tree.node_ticked.disconnect(_on_node_ticked)
		_current_tree = null
	
	_current_agent = agent
	clear_graph()
	
	if agent.has_signal("state_changed"):
		if agent.state_changed.is_connected(_on_state_changed):
			agent.state_changed.disconnect(_on_state_changed)
		agent.state_changed.connect(_on_state_changed)
		_build_fsm_graph(_get_state_list())
	
	elif agent.tree.has_signal("node_ticked"):
		agent.tree.node_ticked.connect(_on_node_ticked)
		_current_tree = agent.tree
		_build_bt_graph(agent.root)
		await get_tree().process_frame
		_build_bt_connections()
	
	if agent.has_method("get_current_state"):
		if agent.has_signal("state_changed"):
			var state_enum: int = agent.get_current_state()
			_active_fsm_state = Enemy.EnemyState.keys()[state_enum]
			_highlight_fsm(_active_fsm_state)
		elif agent.tree.has_signal("node_ticked") && _active_bt_node != null:
			_highlight_bt(_active_bt_node)
 
func clear_graph() -> void:
	for child in get_children():
		if child is GraphNode:
			child.queue_free()
	_fsm_nodes.clear()
	_bt_nodes.clear()
	_bt_children.clear()
	_active_fsm_state = ""

# ========== FSM graph building ==========
func _build_fsm_graph(state_list: Array[String]) -> void:
	for i in state_list.size():
		var state_name := state_list[i]
		var col: int = i % ROW_SIZE
		@warning_ignore("integer_division")
		var row: int = floori(i / ROW_SIZE)
		var x := col * (NODE_W + X_GAP) + 20.0
		var y := row * (NODE_H + Y_GAP) + 20.0
	
		var gn := _make_fsm_node(state_name)
		gn.position_offset = Vector2(x, y)
		add_child(gn)
		_fsm_nodes[state_name] = gn
	
	# Wait one frame so GraphEdit registers the children before connecting
	await get_tree().process_frame
	_build_fsm_connections()

func _build_fsm_connections() -> void:
	for from_state in TRANSITIONS:
		if not _fsm_nodes.has(from_state):
			continue
		var from_node: GraphNode = _fsm_nodes[from_state]
		var line_col: Color = STATE_COLORS.get(from_state, Color.WHITE)
		
		for edge in TRANSITIONS[from_state]:
			var to_state: String = edge["to"]
			if not _fsm_nodes.has(to_state):
				continue
			# Re-set the output slot with this state's color so the bezier
			# line Godot draws inherits it via the port color
			var to_node: GraphNode = _fsm_nodes[to_state]
			var in_col: Color = STATE_COLORS.get(to_state, Color.WHITE)
			from_node.set_slot(0, true, 0, line_col, true, 0, line_col)
			to_node.set_slot(0, true, 0, in_col, true, 0, in_col)
			connect_node(from_node.name, 0, to_node.name, 0)

func _highlight_fsm(active: String) -> void:
	for state_name in _fsm_nodes:
		var gn: GraphNode = _fsm_nodes[state_name]
		var is_active: bool = (state_name == active)
		_set_node_color(gn,
			COL_ACTIVE        if is_active else COL_DEFAULT,
			COL_TITLE_ACTIVE  if is_active else COL_TITLE_DEFAULT
		)

func _get_state_list() -> Array[String]:
	var list: Array[String] = []
	for key in Enemy.EnemyState.keys():
		list.append(key)
	return list

# ========== BT graph building ==========
func _build_bt_graph(root: BTNode) -> void:
	var subtree_widths := {}
	_calc_subtree_widths(root, subtree_widths)
	_place_bt_node(root, 0.0, 0.0, subtree_widths)

# Calculate how wide each subtree needs to be, bottom-up
func _calc_subtree_widths(node: BTNode, widths: Dictionary) -> float:
	var children := _get_bt_children(node)
	if children.is_empty():
		widths[node] = NODE_W
		return NODE_W
	
	var total := 0.0
	for i in children.size():
		total += _calc_subtree_widths(children[i], widths)
		if i < children.size() - 1:
			total += X_GAP
	
	widths[node] = max(total, NODE_W)
	return widths[node]

# Place nodes top-down, centering each parent over its children
func _place_bt_node(root: BTNode, x: float, y: float, widths: Dictionary) -> void:
	var node_name: String
	if root.display_name != "":
		node_name = root.display_name
	else:
		node_name = root.get_script().get_global_name()
	
	var gn := _make_bt_node(node_name)
	_bt_nodes[root] = gn
	_bt_children[gn] = []
	
	var children := _get_bt_children(root)
	var _total_children_width := 0.0
	for i in children.size():
		_total_children_width += widths[children[i]]
		if i < children.size() - 1:
			_total_children_width += X_GAP
	
	# Center this node over its children span
	var node_x: int = x + (widths[root] - NODE_W) / 2.0
	gn.position_offset = Vector2(node_x, y)
	add_child(gn)
	
	# Place children left to right
	var child_x := x
	for child in children:
		_place_bt_node(child, child_x, y + NODE_H + Y_GAP, widths)
		_bt_children[gn].append(_bt_nodes[child])
		child_x += widths[child] + X_GAP

func _highlight_bt(active: BTNode) -> void:
	for bt_node in _bt_nodes:
		var gn: GraphNode = _bt_nodes[bt_node]
		var is_active: bool = (bt_node == active)
		_set_node_color(gn,
			COL_ACTIVE        if is_active else COL_DEFAULT,
			COL_TITLE_ACTIVE  if is_active else COL_TITLE_DEFAULT
		)

func _build_bt_connections() -> void:
	for node in _bt_children:
		var line_col: Color = BT_COLORS.get(node.title, Color.WHITE)
		for node_child in _bt_children[node]:
			var in_col: Color = BT_COLORS.get(node_child.title, Color.WHITE)
			node.set_slot(0, true, 0, line_col, true, 0, line_col)
			node_child.set_slot(0, true, 0, in_col, true, 0, in_col)
			connect_node(node.name, 0, node_child.name, 0)

# ========== GraphNode factory ==========
func _make_fsm_node(state_name: String) -> GraphNode:
	var gn := GraphNode.new()
	gn.title = state_name
	gn.get_titlebar_hbox().get_child(0).add_theme_font_size_override("font_size", TITLE_FONT)
	gn.custom_minimum_size = Vector2(NODE_W, NODE_H)
	gn.set_meta("tag", "FSM")
	
	var state_col: Color = STATE_COLORS.get(state_name, Color.WHITE)
	
	# Small body label
	var transitions: Array = TRANSITIONS.get(state_name, [])
	var lbl := Label.new()
	lbl.text = "  %d out" % transitions.size() if transitions.size() > 0 else "  terminal"
	lbl.add_theme_color_override("font_color", state_col.darkened(0.15))
	lbl.add_theme_font_size_override("font_size", LABEL_FONT)
	gn.add_child(lbl)
	
	# Tooltip shows full transition list on hover
	var tip := ""
	for edge in transitions:
		tip += "→ %s  [%s]\n" % [edge["to"], edge["label"]]
	gn.tooltip_text = tip.strip_edges()
	
	# One input port (left) and one output port (right)
	gn.set_slot(0, true, 0, Color(0.55, 0.75, 0.55), true, 0, Color(0.55, 0.75, 0.55))
	
	_set_node_color(gn, COL_DEFAULT, state_col.darkened(0.1))
	return gn

func _make_bt_node(node_name: String) -> GraphNode:
	var gn := GraphNode.new()
	gn.draggable = false
	
	gn.title = node_name
	gn.get_titlebar_hbox().get_child(0).add_theme_font_size_override("font_size", TITLE_FONT)
	gn.custom_minimum_size = Vector2(max(NODE_W, node_name.length() * 7.5), NODE_H)
	gn.set_meta("tag", "BT")
	
	var bt_col: Color = BT_COLORS.get(node_name, Color.WHITE)
	
	var lbl := Label.new()
	lbl.text = "  status: —"
	lbl.add_theme_color_override("font_color", bt_col.darkened(0.15))
	lbl.add_theme_font_size_override("font_size", LABEL_FONT)
	gn.add_child(lbl)
	
	gn.set_slot(0, true, 0, Color(0.55, 0.65, 0.85), true, 0, Color(0.55, 0.65, 0.85))
	
	_set_node_color(gn, COL_DEFAULT, bt_col.darkened(0.1))
	return gn

func _set_node_color(gn: GraphNode, body_col: Color, title_col: Color) -> void:
	gn.add_theme_color_override("title_color", title_col)
	var sb := StyleBoxFlat.new()
	sb.bg_color = body_col
	sb.corner_radius_top_left     = 6
	sb.corner_radius_top_right    = 6
	sb.corner_radius_bottom_left  = 6
	sb.corner_radius_bottom_right = 6
	sb.border_width_left   = 1
	sb.border_width_right  = 1
	sb.border_width_top    = 1
	sb.border_width_bottom = 1
	sb.border_color = title_col.darkened(0.4)
	gn.add_theme_stylebox_override("panel", sb)

# ========== signal handlers ==========
func _on_state_changed(_from: String, to: String) -> void:
	_active_fsm_state = to
	_highlight_fsm(to)

func _on_node_ticked(node: BTNode, status: int) -> void:
	_active_bt_node = node
	if not _bt_nodes.has(node):
		return
	var gn: GraphNode = _bt_nodes[node]
	
	# Update the status label inside the node
	for child in gn.get_children():
		if child is Label:
			var status_text = "—"
			match status:
				0: status_text = "✓ SUCCESS"
				1: status_text = "↻ RUNNING"
				2: status_text = "✗ FAILURE"
			var extra := ""
			if node.has_method("get_debug_label"):
				extra = "\n  " + node.get_debug_label()
			child.text = "  %s%s" % [status_text, extra]
			break
	
	var col: Color
	match status:
		0: col = Color(0.10, 0.42, 0.18)
		1: col = Color(0.50, 0.42, 0.08)
		2: col = Color(0.48, 0.12, 0.12)
		_:       col = COL_DEFAULT
	_set_node_color(gn, col, COL_TITLE_DEFAULT)

# ========== selecting nodes ==========
func _on_node_selected(node: GraphNode):
	self.get_parent().get_parent()._set_state_for_selected(node.title)

# ========== helper ==========
func _get_bt_children(node: BTNode) -> Array:
	if node is BTParallel:
		return node.children
	return node.get_children()
