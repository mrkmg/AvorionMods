
function registerModdedOrderType(name, definition)
	if OrderTypes[name] ~= nil then
		local nextNumber = OrderTypes.NumActions + 1
		OrderTypes.NumActions = nextNumber
		OrderTypes[name] = nextNumber
		OrderTypes[nextNumber] = definition
	end
end