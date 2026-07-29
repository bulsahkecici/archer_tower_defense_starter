extends Node
class_name EconomyManager

signal gold_changed(current_gold: int)

var gold: int = 0
var total_gold_earned: int = 0


func setup(starting_gold: int) -> void:
	gold = maxi(0, starting_gold)
	total_gold_earned = 0
	gold_changed.emit(gold)


func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	total_gold_earned += amount
	gold_changed.emit(gold)


func can_afford(amount: int) -> bool:
	return amount >= 0 and gold >= amount


func spend_gold(amount: int) -> bool:
	if amount < 0 or not can_afford(amount):
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true
