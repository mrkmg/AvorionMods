return function(node, x, y)
    if x <= 1 then x = x * node.rect.width end
    if y <= 1 then y = y * node.rect.height end
    local offset = vec2(x, y)
    return node:child(Rect(node.rect.topLeft + offset, node.rect.bottomRight + offset))
end