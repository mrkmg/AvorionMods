-- CraftOrdersLib - by Kevin Gravier (MrKMG)

function registerModdedOrderType(name, definition)
	if OrderType[name] == nil then
		OrderTypes[OrderType.NumActions] = definition
		OrderType[name] = OrderType.NumActions
		OrderType.NumActions = OrderType.NumActions + 1
	end
end