--[[
screen resolution = 1280 x 720 px
screen chars = 160 x 45 (font)
screen chars = 160 x 90 (font2x)

ansiart dimensions:
4x4 ?
8x8 ?
16x16
24x24
32x32
48x48
64x64
]]

https = nil
local overlayStats = require("lib.overlayStats")
local runtimeLoader = require("runtime.loader")

local json = require("lib.json")
local ansi = require("lib.ansi")

local selected = {
  color = color.white,
  char  = "█",
}

local colorpalette = {}

-- 16x16 chars
local ansiArt = {}
for i = 1,16 do
  ansiArt[i] = {
    [1] = color.darkgrey, [2] = ".",
    [3] = color.darkgrey, [4] = ".",
    [5] = color.darkgrey, [6] = ".",
    [7] = color.darkgrey, [8] = ".",
    [9] = color.darkgrey, [10] = ".",
    [11] = color.darkgrey,[12] = ".",
    [13] = color.darkgrey,[14] = ".",
    [15] = color.darkgrey,[16] = ".",
    [17] = color.darkgrey,[18] = ".",
    [19] = color.darkgrey,[20] = ".",
    [21] = color.darkgrey,[22] = ".",
    [23] = color.darkgrey,[24] = ".",
    [25] = color.darkgrey,[26] = ".",
    [27] = color.darkgrey,[28] = ".",
    [29] = color.darkgrey,[30] = ".",
    [31] = color.darkgrey,[32] = ".",
  }
end

---@param x integer position in chars (0..159) font2x size
---@param y integer position in chars (0..89) font2x size
function drawPalette( x, y )
  love.graphics.setColor( color.white )
  love.graphics.print("╔════════════════╗", monoFont2x, 141*FONT2X_WIDTH, 4*FONT2X_HEIGHT)
  love.graphics.print("║\n║\n║\n║\n║\n║\n║\n║\n║\n║\n║\n║\n║\n║\n║\n║\n", monoFont2x, 141*FONT2X_WIDTH, 5*FONT2X_HEIGHT)
  love.graphics.print("║\n║\n║\n║\n║\n║\n║\n║\n║\n║\n║\n║\n║\n║\n║\n║\n", monoFont2x, 158*FONT2X_WIDTH, 5*FONT2X_HEIGHT)
  love.graphics.print("╚════════════════╝", monoFont2x, 141*FONT2X_WIDTH, 21*FONT2X_HEIGHT)

  drawXTUI16(colorpalette,142,5)

end


function love.load()
  https = runtimeLoader.loadHTTPS()
  -- Your game load here
  monoFont = love.graphics.newFont("fonts/"..FONT, FONT_SIZE)
  monoFont2x = love.graphics.newFont("fonts/"..FONT2X, FONT2X_SIZE)
  love.graphics.setFont( monoFont )
  print(monoFont:getWidth("█"))
  print(monoFont:getHeight())
  love.graphics.setFont( monoFont2x )
  print(monoFont2x:getWidth("█"))
  print(monoFont2x:getHeight())

  bitmap = love.graphics.newImage( "img/Item__01.png")

  local tempData = love.filesystem.read("xtui/colorpalette_16.xtui")
  colorpalette = json.decode(tempData)

  overlayStats.load() -- Should always be called last
end

---@param xtui table containing color tables and text
---@param x integer in font2x chars (0..159)
---@param y integer in font2x chars (0..89)
function drawXTUI16(xtui, x, y)
  love.graphics.setColor(color.white)
  for i = 1,16 do
    love.graphics.print(xtui[i], monoFont2x, x*FONT2X_WIDTH, ((i-1)+y)*FONT2X_HEIGHT)
  end
end

function love.draw()
  -- Your game draw here
  local mouse = {
    x = math.floor(love.mouse.getX()/8),
    y = math.floor(love.mouse.getY()/8)
  }

  love.graphics.setColor( color.brightblue )
  for i = 1,16 do
    love.graphics.print("1...5....|", monoFont2x, (i-1)*FONT2X_WIDTH*10, 0)
  end
  for i = 1,9 do
    love.graphics.print("1\n2\n3\n4\n5\n6\n7\n8\n9\n-", monoFont2x, 0, (i-1)*FONT2X_HEIGHT*10)
  end

  love.graphics.setColor( color.white )
  love.graphics.draw( bitmap, 80*FONT2X_WIDTH, 5*FONT2X_HEIGHT, 0, 8, 8 ) -- rotation=0, scalex=8, scaley=8

  for i = 1,16 do
    love.graphics.print(ansiArt[i], monoFont2x, 80*FONT2X_WIDTH, (i+4)*FONT2X_HEIGHT)
  end

  -- Using CoffeeMud's color codes
-- ^w :  White            ^W :  Grey
-- ^g :  Bright Green     ^G :  Green
-- ^b :  Bright Blue      ^B :  Blue
-- ^r :  Bright Red       ^R :  Red
-- ^y :  Bright Yellow    ^Y :  Yellow
-- ^c :  Bright Cyan      ^C :  Cyan
-- ^p :  Bright Magenta   ^P :  Magenta
-- ^k :  Black            ^K :  Black


  love.graphics.printf(mouse.x.." x "..mouse.y.." ("..(mouse.x-79).." x "..(mouse.y-4)..")", monoFont, 10*FONT_WIDTH, 1*FONT_HEIGHT, 240, "left")
  love.graphics.printf("This text is in monoFont2x.", monoFont2x, 10*FONT2X_WIDTH, 4*FONT2X_HEIGHT, 240, "left")
  love.graphics.printf("F2: Load, F8: Save", monoFont, 10*FONT_WIDTH, 12*FONT_HEIGHT, 240, "left")

  love.graphics.print("▄ █ ▀ ▌ ▐ ░ ▒ ▓", monoFont2x, 2*FONT2X_WIDTH, 11*FONT2X_HEIGHT)
  love.graphics.print("○", monoFont2x, 2*FONT2X_WIDTH, 12*FONT2X_HEIGHT)
  love.graphics.print("■", monoFont2x, 2*FONT2X_WIDTH, 13*FONT2X_HEIGHT)
  love.graphics.print("▲ ▼ ► ◄", monoFont2x, 2*FONT2X_WIDTH, 14*FONT2X_HEIGHT)
  love.graphics.print("╦ ╗ ╔ ═ ╩ ╝ ╚ ║ ╬ ╣ ╠ ╥ ╖ ╓ ╤ ╕ ╒ ┬ ┐ ┌ ─ ┴ ┘ └", monoFont2x, 2*FONT2X_WIDTH, 15*FONT2X_HEIGHT)
  love.graphics.print("│ ┼ ┤ ├ ╨ ╜ ╙ ╧ ╛ ╘ ╫ ╢ ╟ ╪ ╡ ╞", monoFont2x, 2*FONT2X_WIDTH, 16*FONT2X_HEIGHT)

  love.graphics.setColor(selected.color)
  love.graphics.printf(selected.char, monoFont, 10*FONT_WIDTH, 10*FONT_HEIGHT, 32, "left")

  drawPalette(141, 4)

  overlayStats.draw() -- Should always be called last
end

function love.update(dt)
  -- Your game update here
  overlayStats.update(dt) -- Should always be called last
end

function love.keypressed(key, scancode, isrepeat)
  print("key:"..key.." scancode:"..scancode.." isrepeat:"..tostring(isrepeat))
  if key == "escape" and love.system.getOS() ~= "Web" then
    love.event.quit()
  else
    overlayStats.handleKeyboard(key) -- Should always be called last
  end

  if key == "f2" then
    -- load ansiart
    local tempData = love.filesystem.read("ansiart.xui")
    ansiArt = json.decode(tempData)
  end

  if key == "f8" then
    -- save ansiart
    local success, message =love.filesystem.write("ansiart.xui", json.encode(ansiArt))
    if success then
	    print ('file created: ansiart.xui')
    else
	    print ('file not created: '..message)
    end
  end

  if key == "f12" then
    -- toggle fullscreen
      fullscreen = not fullscreen
			love.window.setFullscreen(fullscreen, "exclusive")

  end
end

function love.mousepressed( x, y, button, istouch, presses )
  local mouse = {
    x = math.floor(love.mouse.getX()/8)-79,
    y = math.floor(love.mouse.getY()/8)-4
  }

  if mouse.y >= 1 and mouse.y <= 8 then -- first bright palette row
    if mouse.x == 63 or mouse.x == 64 then -- black
      selected.color = color.black
    end
    if mouse.x == 65 or mouse.x == 66 then -- bright red
      selected.color = color.brightred
    end
    if mouse.x == 67 or mouse.x == 68 then -- bright yellow
      selected.color = color.brightyellow
    end
    if mouse.x == 69 or mouse.x == 70 then -- bright green
      selected.color = color.brightgreen
    end
    if mouse.x == 71 or mouse.x == 72 then -- bright cyan
      selected.color = color.brightcyan
    end
    if mouse.x == 73 or mouse.x == 74 then -- bright blue
      selected.color = color.brightblue
    end
    if mouse.x == 75 or mouse.x == 76 then -- bright magenta
      selected.color = color.brightmagenta
    end
    if mouse.x == 77 or mouse.x == 78 then -- white
      selected.color = color.white
    end
  end
  if mouse.y >= 9 and mouse.y <= 16 then -- first dark palette row
    if mouse.x == 63 or mouse.x == 64 then -- black
      selected.color = color.black
    end
    if mouse.x == 65 or mouse.x == 66 then -- red
      selected.color = color.red
    end
    if mouse.x == 67 or mouse.x == 68 then -- yellow
      selected.color = color.yellow
    end
    if mouse.x == 69 or mouse.x == 70 then -- green
      selected.color = color.green
    end
    if mouse.x == 71 or mouse.x == 72 then -- cyan
      selected.color = color.cyan
    end
    if mouse.x == 73 or mouse.x == 74 then -- blue
      selected.color = color.blue
    end
    if mouse.x == 75 or mouse.x == 76 then -- magenta
      selected.color = color.magenta
    end
    if mouse.x == 77 or mouse.x == 78 then -- darkgrey
      selected.color = color.darkgrey
    end
  end

  if mouse.x >= 63 then
    if (mouse.y >= 1 and mouse.y <= 2) or (mouse.y >= 9 and mouse.y <= 10) then -- full block
      selected.char = "█"
    end
    if (mouse.y >= 3 and mouse.y <= 4) or (mouse.y >= 11 and mouse.y <= 12) then -- full block
      selected.char = "▓"
    end
    if (mouse.y >= 5 and mouse.y <= 6) or (mouse.y >= 13 and mouse.y <= 14) then -- full block
      selected.char = "▒"
    end
    if (mouse.y >= 7 and mouse.y <= 8) or (mouse.y >= 15 and mouse.y <= 16) then -- full block
      selected.char = "░"
    end
  end

  -- mouse clicked in drawing area
  if (mouse.x >= 1 and mouse.x <= 16) and (mouse.y >= 1 and mouse.y <= 16) then
    ansiArt[mouse.y][(mouse.x*2)-1] = selected.color
    ansiArt[mouse.y][mouse.x*2] = selected.char
  end

end

function love.touchpressed(id, x, y, dx, dy, pressure)
  overlayStats.handleTouch(id, x, y, dx, dy, pressure) -- Should always be called last
end

--[[ To-Dos
  * support multiple art dimensions
  * export to PNG
  * auto-convert JPG PNG to XTUI
]]

--[[ Changelog
  2025-03-31
  * Implemented using XTUI images (prerendered) instead of code for the UI
  * Implemented color palette, click to select color and shade
  * Implemented ansiart size - 16x16
]]


