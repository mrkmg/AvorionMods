return function(node, offset)
    if offset.x <= 1 then offset.x = offset.x * node.rect.width end
    if offset.y <= 1 then offset.y = offset.y * node.rect.height end
    
    return node:child(Rect(node.rect.topLeft + offset, node.Rect.bottomRight + offset))
end