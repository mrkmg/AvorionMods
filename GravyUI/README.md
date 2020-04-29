GravyUI
=======

GravyUI is a simple, yet powerful library to generate `Rect`'s in Avorion for use with the existing UI elements.

- [GravyUI](#gravyui)
- [Premise](#premise)
- [Quick Example](#quick-example)
- [Helper](#helper)
- [How to Use](#how-to-use)
  - [API](#api)
    - [offset](#offset)
    - [pad](#pad)
    - [cols](#cols)
    - [rows](#rows)
    - [grid](#grid)
- [Full Featured Example](#full-featured-example)
- [Create Plugins to GravyUI](#create-plugins-to-gravyui)
- [License](#license)

# Premise

All functions of GravyUI stem from Node. A Node wraps a Rect, and adds methods to generate new nodes. You can add a padding, or split a node into smaller pieces and build an entire layout.


# Quick Example

```lua
package.path = package.path .. ";data/scripts/lib/?.lua"
local Node = include("gravyui/node")

local windowNode = Node(300, 300)
local titleNode, bodyNode = windowNode:rows({20, 1}, 5)
local bodyNodeCols = {bodyNode:cols(2, 5)}

local mapWindow = GalaxyMap():createWindow(window:offset(200, 200))
mapWindow:createLabel(titleNode.rect, "Title Area")
mapWindow:createLabel(bodyNodeCols[1].rect, "Left Body")
mapWindow:createLabel(bodyNodeCols[2].rect, "Right Body)
```

# Helper

Following along with the examples, and test yourself using the [GravyUI-WebHelper](https://mrkmg.github.io/Avorion-GravyUI-WebHelper/).

The helper is an interactive tool to help you visualize your layouts, while you create them!

# How to Use

First, you need a node.

To create a node, you can use a width and height, or a `Rect`.

```lua
package.path = package.path .. ";data/scripts/lib/?.lua"
local Node = include("gravyui/node")

local nodeByWH = Node(100, 100)
-- OR
local nodeByRect = Node(Rect(50, 50, 200, 200))
```

You can create new nodes by manipulating the existing nodes. This is where the real power of GravyUI comes in. You can manipulate a node with the methods [offset](#offset), [pad](#pad), [cols](#cols), [rows](#rows), and [grid](#grid).

Each node contains a property called rect which can be used when creating UI Elements. See the examples.

**Before you continue**, an important concept is size inputs. Sizes can be provided as a whole number, or a fraction. If a size is provided as a whole number (over 1), it will be interpreted as an absolute value in pixels. If a size is provided as a fractional (1 or less), it will interpreted as a fraction of the corresponding width or height.

For example
```lua
-- 0,0 to 200,400
local node = Node(200, 400)

-- pad 20px on left/right, and 30px on top/bottom
-- 20,30 to 180,370
local padByAbsolute = node:pad(20, 30) 

-- pad 10%
-- 20,40 to 180,360
local padByRelative = node:pad(1/10)
```

Anywhere you see `size` as a parameter, you can use either absolute (>1), or fractional (<=1) numbers. Also, many of the functions take a table of sizes. This will represented as `{sizes}`.

When an table of sizes are used to split a node, the fractions are calculated **after** any absolute sizes.

`100` split with the sizes `{5, 1/4, 3/4, 15}` would result in `{5, 20, 60, 15}`. In this example, the available size for the fractions is 100 - 5 - 15 = 80. Then that 80 is split by 1/4 and 3/4.

## API

A `Node` has the following properties:

- `.rect` - A `Rect` representing the Node
- `.parentNode` - If not `nil`, the node this node was generated from
- `.childNode` - A table of all the nodes generated from this node

### offset

`offset` returns a new node which has been shifted by the provided sizes.

Signature:
- **Node:offset**(x: *size*, y: *size*) : *Node*

```lua
-- node is from 10,10 to 20,20
local node = Node(Rect(10, 10, 20, 20))

-- offsetNode is from 5,15 to 15,25
local offsetNode = node:offset(vec2(-5, 5))
```

### pad

`pad` return a new node which is shrunk by the provided padding amount.

Signatures:
- **Node:pad**(allSides: *size*) : *Node*
- **Node:pad**(leftRight: *size*, topBottom: *size*) : *Node*
- **Node:pad**(left: *size*, top: *size*, right: *size*, *bottom: *size*) : *Node*

```lua
-- 10,10 to 20,20
local node = Node(Rect(10, 10, 20, 20))

-- 12,12 to 18,18
local paddedNode = node:pad(2)

-- 12,11 to 18,19
local paddedNode = node:pad(1/5, 1/10)

-- 10, 10, 15, 20
local paddedNode = node:pad(0, 0, 5, 0)
```

### cols

`cols` will return a number of new nodes by splitting the node into columns of optionally variable sizes with an optional margin between each.

Signatures:
- **Node:cols**(numberOfEvenCols: *number*, margin: *size*) : *Node, Node, ...*
- **Node:cols**(splits: *{sizes}*, margin: *size*) : *Node, Node, ...*

```lua
-- Two columns, left being 25% the width of the node, and the right
-- being 75% the width of the node, with 10 pixels between.
local leftNode, rightNode = node:cols({1/4, 3/4}, 10)

-- Ten even columns, with 2 pixels between
local tenNodesAsTable = {node:cols(10, 2)}
```

### rows

`rows` will return a number of new nodes by splitting the node into rows of optionally variable sizes with an optional margin between each.

Signatures:
- **Node:rows**(numberOfEvenRows: *number*, margin: *size*) : *Node, Node, ...*
- **Node:rows**(splits: *{sizes}*, margin: *size*) : *Node, Node, ...*

```lua
-- Two rows, top being 25% the height of the node, and the bottom
-- being 75% the height of the node, with 10 pixels between.
local topNode, bottomNode = node:rows({1/4, 3/4}, 10)

-- Ten even rows, with 2 pixels between 
local tenNodesAsTable = {node:rows(10, 2)}
```

### grid

`grid` will return a number of new tables of node, which represent a grid of optionally variable row and column sizes and an optional row and column margin

Signatures:
- **Node:grid**(rowSplits: *{sizes}*, colSplits: *{sizes}*, rowMargin: *size*, colMargin: *size*) : *{Node,...}, {Node,...}*
- **Node:grid**(numEvenRows: *number*, colSplits: *{sizes}*, rowMargin: *size*, colMargin: *size*) : *{Node,...}, {Node,...}*
- **Node:grid**(rowSplits: *{sizes}*, numEvenCols: *number*, rowMargin: *size*, colMargin: *size*) : *{Node,...}, {Node,...}*
- **Node:grid**(rowSplits: *number*, colSplits: *number*, rowMargin: *size*, colMargin: *size*) : *{Node,...}, {Node,...}*

```lua
-- make a 2x2 grid, all evenly split
-- row1 and row2 are tables which are contain two Nodes 
local row1, row2 = Node(100, 100):grid(2, 2)

-- make a 2x3 grid
-- the middle row is 100px, the top and bottom are 50% of the remaining space
-- column 1 is 25% the width, and column 2 is 75% the width
-- each row has 10 pixels between, and each column has 5 pixels between
local grid = Node(200, 200):grid({1/2, 100, 1/2}, {1/4, 3/4}, 10, 5)
```

# Full Featured Example

The following is an excerpt of code taking from the OrderBook mod. It produces the following window:

![Example of Complex GravyUI](https://raw.githubusercontent.com/mrkmg/AvorionMods/master/GravyUI/example.png)

```lua
local pageSize = 10

-- Create the root node
local root = Node(400, 420)
-- Pad the root node, for the window data
local paddedRoot = root:pad(10)
-- Create 3 sections, top being 60px, bottom being 35px
-- and the middle taking the remaining space
local top, middle, bottom = paddedRoot:rows({60, 1, 35}, 10)
-- Convert top to a 2x2 grid with 5px margins
top = {top:grid(2, 2, 5, 5)}
-- Create a spot for the chainTable, and nav buttons in 
-- the middle sections
local chainTable, chainNextPrev = middle:rows({1, 25}, 10)
-- Convert the chainTable to a grid of pageSize rows, the
-- first taking up 3/5's the space, and the rest splitting
-- the remaining space. (2/5) / 5 = 2/25
chainTable = {chainTable:grid(pageSize, {3/5, 2/25, 2/25, 2/25, 2/25, 2/25}, 5, 2)}
-- Convert the chainNextPrev into two even columns with
-- 1/4 the width of the entire element as padding
chainNextPrev = {chainNextPrev:cols(2, 1/4)}
-- Pad 12 on top, then convert the bottom into three columns with
-- 10 px margin
bottom = {bottom:pad(0, 12, 0, 0):cols({1/4, 3/8, 3/8}, 10)}

-- Create the elements of the window
local windowRect = root:offset(res.x - root.rect.width - 5, res.y / 2 + root.rect.height / 2).rect
mainWindow = galaxy:createWindow(windowRect)
readComboBox = mainWindow:createValueComboBox(top[1][1].rect, "loadGo")
writeTextBox = mainWindow:createTextBox(top[1][2].rect, "renderMainWindow")
deleteButton = mainWindow:createButton(top[2][1].rect, "Delete Book", "deleteGo")
writeButton = mainWindow:createButton(top[2][2].rect, "Write Book", "writeGo")
chainPreviousPageButton = mainWindow:createButton(chainNextPrev[1].rect, "Previous Page", "writePageBack")
chainNextPageButton = mainWindow:createButton(chainNextPrev[2].rect, "Next Page", "writePageNext")
syncCheckbox = mainWindow:createCheckBox(bottom[1].rect, "Sync", "syncChanged")
loadOrdersButton = mainWindow:createButton(bottom[2].rect, "Load Orders", "loadFromSelected")
applyOrdersButton = mainWindow:createButton(bottom[3].rect, "Replace Orders", "applyOrders")

-- Tweak elements
writeTextBox.forbiddenCharacters = "%+/#$@?{}[]><()"
mainWindow.caption = "Order Chain Book Reader/Writer /* Order Window Caption Galaxy Map */"%_t
mainWindow.showCloseButton = 1
mainWindow.moveable = 1
mainWindow.closeableWithEscape = 1

-- foreach row
for i = 1,pageSize do
    -- Create the elements for the table row
    local lab = mainWindow:createLabel(chainTable[i][1].rect, "", 14)
    local rj = mainWindow:createCheckBox(chainTable[i][2].rect, "", "chainRelativeJumpChanged")
    local upBut = mainWindow:createButton(chainTable[i][3].rect, "", "chainMoveUpGo")
    local downBut = mainWindow:createButton(chainTable[i][4].rect, "", "chainMoveDownGo")
    local editBut = mainWindow:createButton(chainTable[i][5].rect, "", "chainEditShow")
    local delBut = mainWindow:createButton(chainTable[i][6].rect, "", "chainDeleteGo")

    -- Adjust the elements, add pictures, etc.
    lab:setLeftAligned()
    rj.tooltip = "Relative Jump"
    upBut.icon = "data/textures/icons/arrow-up.png"
    upBut.tooltip = "Move Up"
    downBut.icon = "data/textures/icons/arrow-down.png"
    downBut.tooltip = "Move Down"
    editBut.icon = "data/textures/icons/pencil.png"
    editBut.tooltip = "Edit Data"
    delBut.icon = "data/textures/icons/trash-can.png"
    delBut.tooltip = "Delete"

    -- Save to a global to use later
    chainRowItems[i] = {
        label = lab,
        relativeJumpCheckbox = rj,
        upButton = upBut,
        downButton = downBut,
        editButton = editBut,
        deleteButton = delBut
    }
end

mainWindow:hide()
```

# Create Plugins to GravyUI

You can create a mod which extends Node, and adds new methods.

To create a `dialog` method, first create the following file:

*data/scripts/lib/gravyui/plugins/dialog.lua*
```lua
return function(node)
    local titleNode, bodyNode, buttonsNode = node:rows({40, 1, 30}, 5)
    local leftNode, rightNode = buttons:cols(2, 5)}
    return {
        title = titleNode,
        body = bodyNode,
        cancelbutton = leftNode,
        confirmButton = rightNode
    }
end
```

Add the plugin to the node loader. You can do this in your own mod by creating the file.

*data/scripts/lib/gravyui/node.lua*
```lua
    GravyUINode.dialog = include("gravyui/plugins/dialog")
```

Finally, you can use it in your own scripts.

```lua
local dialogData = Node(400, 400):dialog()
...
window:createLabel(dialogData.title.rect, "Title")
...
```

# License

MIT License

Copyright 2020 Kevin Gravier

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.