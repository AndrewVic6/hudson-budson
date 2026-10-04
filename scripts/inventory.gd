extends RefCounted
# Item rules live here. Add a new locker item without changing player movement.
const ITEMS = {
	"apple": {"name": "Apple", "kind": "food", "heal": 15, "color": Color("cf5147")},
	"sandwich": {"name": "Lunch sandwich", "kind": "food", "heal": 35, "color": Color("d4ac65")},
	"juice": {"name": "Juice box", "kind": "food", "heal": 20, "color": Color("e99f4b")},
	"bat": {"name": "Baseball bat", "kind": "weapon", "color": Color("bf9256")},
	"racket": {"name": "Tennis racket", "kind": "weapon", "color": Color("57bfc7")},
	"tennis_ball": {"name": "Tennis balls +3", "kind": "distraction", "color": Color("c7db64")},
	"backpack": {"name": "Padded backpack", "kind": "armor", "color": Color("e79453")},
	"sneakers": {"name": "Fresh sneakers", "kind": "speed", "color": Color("e8e2ca")},
	"notebook": {"name": "Embarrassing notebook", "kind": "comedy", "color": Color("a288bf")},
	"hall_pass": {"name": "EXIT HALL PASS", "kind": "key", "color": Color("f4d17c")}
}
const WEAPONS = {
	"tray": {"name": "Cafeteria tray", "damage": 25, "reach": 2.35, "knock": 1.0, "cooldown": 0.45},
	"bat": {"name": "Baseball bat", "damage": 40, "reach": 3.0, "knock": 1.4, "cooldown": 0.65},
	"racket": {"name": "Tennis racket", "damage": 20, "reach": 2.8, "knock": 1.9, "cooldown": 0.4}
}
var food: Array[String] = []
var weapons: Array[String] = ["tray"]
var equipped: String = "tray"
var balls: int = 0
var armor: int = 0
var sneakers: bool = false
var hall_pass: bool = false
var notebooks: int = 0
var collected: int = 0

func add_item(id: String) -> void:
	if not ITEMS.has(id):
		return
	collected += 1
	match ITEMS[id].kind:
		"food": food.append(id)
		"weapon":
			if not weapons.has(id): weapons.append(id)
			equipped = id
		"distraction": balls += 3
		"armor": armor = mini(60, armor + 30)
		"speed": sneakers = true
		"key": hall_pass = true
		"comedy": notebooks += 1

func equip(id: String) -> bool:
	if not weapons.has(id): return false
	equipped = id
	return true

func stats() -> Dictionary:
	return WEAPONS[equipped]

func eat(health: int) -> Dictionary:
	if health >= 100 or food.is_empty(): return {"health": health, "used": ""}
	# Use the smallest snack that covers the missing health, otherwise the largest.
	var chosen: int = 0
	var missing: int = 100 - health
	var best_heal: int = -1
	for i in range(food.size()):
		var amount: int = ITEMS[food[i]].heal
		if best_heal < 0 or (best_heal < missing and amount > best_heal) or (amount >= missing and amount < best_heal):
			chosen = i
			best_heal = amount
	var used: String = food[chosen]
	food.remove_at(chosen)
	return {"health": mini(100, health + best_heal), "used": used}

func absorb(damage: int) -> int:
	var blocked: int = mini(damage, armor)
	armor -= blocked
	return damage - blocked
