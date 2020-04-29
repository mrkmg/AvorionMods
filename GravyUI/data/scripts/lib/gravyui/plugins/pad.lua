----@overload fun(node: GravyIONode, left: number, top: number, right: number, bottom: number)
----@overload fun(node: GravyIONode, leftRight: number, topBottom: number)
----@overload fun(node: GravyIONode, allSides: number)
return function(node, a, b, c, d)
    local topLeft, bottomRight

    if d ~= nil then
        if a <= 1 then a = a * node.rect.width end
        if b <= 1 then b = b * node.rect.height end
        if c <= 1 then c = c * node.rect.width end
        if d <= 1 then d = d * node.rect.height end
        topLeft = vec2(a, b)
        bottomRight = vec2(c, d)
    elseif b ~= nil then
        if a <= 1 then a = a * node.rect.width end
        if b <= 1 then b = b * node.rect.height end
        topLeft = vec2(a, b)
        bottomRight = vec2(a, b)
    elseif a ~= nil then
        if a <= 1 then 
            topLeft = vec2(a * node.rect.width, a * node.rect.height)
        else
            topLeft = vec2(a, a)
        end
        bottomRight = topLeft
    else
        error("Invalid number of arugments to pad")
    end

    local newRect = Rect(node.rect.topLeft + topLeft, node.rect.bottomRight - bottomRight)
    return node:child(newRect)
end