----@overload fun(node: GravyIONode, top: number, left: number, bottom: number, right: number)
----@overload fun(node: GravyIONode, topBottom: number, leftRight: number)
----@overload fun(node: GravyIONode, allSides: number)
return function(node, a, b, c, d)
    local topLeft, bottomRight

    if d ~= nil then
        if a <= 1 then a = a * node.rect.height end
        if b <= 1 then b = b * node.rect.width end
        if c <= 1 then c = c * node.rect.height end
        if d <= 1 then d = d * node.rect.width end
        topLeft = vec2(b, a)
        bottomRight = vec2(d, c)
    elseif b ~= nil then
        if a <= 1 then a = a * node.rect.height end
        if b <= 1 then b = b * node.rect.width end
        topLeft = vec2(b, a)
        bottomRight = vec2(b, a)
    elseif a ~= nil then
        if a <= 1 then a = a * math.min(node.rect.height, node.rect.width) end
        topLeft = vec2(a, a)
        bottomRight = topLeft
    else
        error("Invalid number of arugments to pad")
    end

    local amountVector = vec2(amount, amount)
    local newRect = Rect(node.rect.topLeft + topLeft, node.rect.bottomRight - bottomRight)
    return node:child(newRect)
end