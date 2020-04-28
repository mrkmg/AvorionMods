return function(node, splits, margin)
    margin = margin or 0
    if margin <= 1 then margin = round(margin * node.rect.width) end
    local numSplits
    if type(splits) == "number" then
        numSplits = splits
        splits = {}
        for i = 1,numSplits do table.insert(splits, 1/numSplits) end
    else
        numSplits = #splits
    end
    local availableSize = node.rect.width - margin * (numSplits - 1)
    for i = 1,numSplits do
        if splits[i] > 1 then
            availableSize = availableSize - splits[i]
        end
    end
    local nodes = {}
    local offset = 0
    for i = 1,numSplits do
        local split = splits[i]
        if split <= 1 then
            split = round(split * availableSize)
        end
        local topLeft = node.rect.topLeft + vec2((i - 1) * margin + offset, 0)
        local bottomRight = topLeft + vec2(split , node.rect.height)
        table.insert(nodes, node:child(Rect(topLeft, bottomRight)))
        offset = offset + split
    end
    return unpack(nodes)
end