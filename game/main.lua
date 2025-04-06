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

love.filesystem.setIdentity("XTUIdraw") -- for R36S file system compatibility
love.mouse.setVisible( false ) -- make mouse cursor invis, use text cursor
love.graphics.setDefaultFilter("nearest", "nearest") -- for nearest neighbour, pixelart style

https = nil
local overlayStats = require("lib.overlayStats")
local runtimeLoader = require("runtime.loader")

local json = require("lib.json")
local ansi = require("lib.ansi")

-- TEXT_BLOCKS = "▄ █ ▀ ▌ ▐ ░ ▒ ▓" -- cp437
-- TEXT_SYMBOLS = "○ ■ ▲ ▼ ► ◄" -- cp437
-- TEXT_BOX = "╦ ╗ ╔ ═ ╩ ╝ ╚ ║ ╬ ╣ ╠ ╥ ╖ ╓ ╤ ╕ ╒ ┬ ┐ ┌ ─ ┴ ┘ └ │ ┼ ┤ ├ ╨ ╜ ╙ ╧ ╛ ╘ ╫ ╢ ╟ ╪ ╡ ╞" -- cp437

-- user monoFont to display, 176 x 224 px
local charTable = {
  [1] = {"█","▓","▒","░","▄","▀","▌","▐","/","|","\\"},
  [2] = {"○","■","▲","▼","►","◄","~","!","@","#","$"},
  [3] = {"╔","═","╦","╩","╗","║","╠","╬","╣","╚","╝"},
  [4] = {"┌","─","┬","┴","┐","│","├","┼","┤","└","┘"},
  [5] = {"╓","╒","╤","╥","╨","╧","╥","╤","╖","╕","."},
  [6] = {"╫","╪","╟","╞","╢","╡","╙","╘","╜","╛",","},
  [7]= {"!","@","#","$","%","^","&","*","(",")"," "},
  [8] = {"a","b","c","d","e","f","g","h","i","j","k"},
  [9] = {"l","m","n","o","p","q","r","s","t","u","v"},
  [10] = {"w","x","y","z","-","=","_","+","[","]","'"},
  [11]= {"A","B","C","D","E","F","G","H","I","J","K"},
  [12]= {"L","M","N","O","P","Q","R","S","T","U","V"},
  [13]= {"W","X","Y","Z","<",">",",",".",";",":","?"},
  [14]= {"1","2","3","4","5","6","7","8","9","0","`"},
}

local game = {}

-- set game timers
game.timeThisSession = 0

-- detect viewport
game.width, game.height = love.graphics.getDimensions( )
print("viewport: "..game.width.."x"..game.height)

-- set default cursor coord
game.cursorx = 1
game.cursory = 1

-- set default canvas size (16x16)
game.canvasx = 16
game.canvasy = 16

-- set default char table selected [1..11][1..14]
game.charx = 1
game.chary = 1

-- set default color number selected
game.colorSelected = 15

-- detect system OS
game.os = love.system.getOS() -- "OS X", "Windows", "Linux", "Android" or "iOS"
if love.filesystem.getUserDirectory( ) == "/home/ark/" then
	game.os = "R36S"
end
print("systemOS: "..game.os)

-- check / create file directories
if love.filesystem.getInfo("autosave") == nil then
  if game.os == "R36S" then
    os.execute("mkdir " .. love.filesystem.getSaveDirectory()) -- OS creation
    os.execute("mkdir " .. love.filesystem.getSaveDirectory() .. "//autosave")
    print("R36S: created directory - autosave")
  else
    love.filesystem.createDirectory("autosave")
    print("Created directory - autosave")
  end
end
if love.filesystem.getInfo("quicksave") == nil then
  if game.os == "R36S" then
    os.execute("mkdir " .. love.filesystem.getSaveDirectory() .. "//quicksave")
    print("R36S: created directory - quicksave")
  else
    love.filesystem.createDirectory("quicksave")
    print("Created directory - quicksave")
  end
end
if love.filesystem.getInfo("bmp") == nil then
  if game.os == "R36S" then
    os.execute("mkdir " .. love.filesystem.getSaveDirectory() .. "//bmp")
    print("R36S: created directory - bmp")
  else
    love.filesystem.createDirectory("bmp")
    print("Created directory - bmp")
  end
end
if love.filesystem.getInfo("ansiart") == nil then
  if game.os == "R36S" then
    os.execute("mkdir " .. love.filesystem.getSaveDirectory() .. "//ansiart")
    print("R36S: created directory - ansiart")
  else
    love.filesystem.createDirectory("ansiart")
    print("Created directory - ansiart")
  end
end
if love.filesystem.getInfo("timelapse") == nil then
  if game.os == "R36S" then
    os.execute("mkdir " .. love.filesystem.getSaveDirectory() .. "//timelapse")
    print("R36S: created directory - timelapse")
  else
    love.filesystem.createDirectory("timelapse")
    print("Created directory - timelapse")
  end
end

local selected = {
  color = color.white,
  char  = "█",
  bmp   = "",
  bmpnumber = 1,
  viewport = 1,
}

local bmpFiles = love.filesystem.getDirectoryItems( "bmp" ) -- table of files in the bmp directory

local colorpalette = {}

-- default canvas 16x16 chars
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

function drawCharTable()
  local x = math.floor((game.width - 176)/2)
  local y = math.floor((game.height - 224)/2)
  love.graphics.setColor(color.darkgrey)
  for i = 1,14 do
    for j = 1,11 do
      love.graphics.setColor(color.darkgrey)
      love.graphics.setFont(monoFont)
      love.graphics.print(charTable[i][j], x + (((j-1)*2)*FONT_WIDTH), y + ((i-1)*FONT_HEIGHT) )
    end
  love.graphics.setColor(selected.color)
  love.graphics.setFont(monoFont4s)
  love.graphics.print(selected.char, game.width/2 - 18 , y - FONT_HEIGHT*5 )
  end

  -- highlight current selection
  love.graphics.setColor( color.white )
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line", x+(((game.charx-1)*2)*FONT_WIDTH), y+((game.chary-1)*FONT_HEIGHT), FONT_WIDTH, FONT_HEIGHT)

end

---@param filename string
---@param directory string
function saveData( filename , directory )
    if game.os ~= "R36S" then
      -- save ansiart
      local success, message =love.filesystem.write(directory.."/"..filename, json.encode(ansiArt))
      if success then
	      print ('file created: '..directory.."/"..filename)
      else
	      print ('file not created: '..message)
      end
    else
      -- save for R36S
      local f = io.open(love.filesystem.getSaveDirectory().."//"..directory.."/"..filename, "w")
      f:write(json.encode(ansiArt))
      f:close()
    end
end

function love.load()
  https = runtimeLoader.loadHTTPS()
  -- Your game load here
  monoFont = love.graphics.newFont("fonts/"..FONT, FONT_SIZE)
  monoFont4s = love.graphics.newFont("fonts/"..FONT, FONT_SIZE*4)
  monoFont2x = love.graphics.newFont("fonts/"..FONT2X, FONT2X_SIZE)
  monoFont2x4s = love.graphics.newFont("fonts/"..FONT2X, FONT2X_SIZE*4)
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
  -- Your game draw here (from bottom to top layer)

  -- set viewport
  if selected.viewport == 1 then
    love.graphics.translate( 0, 0 )
  end
  if selected.viewport == 2 then
    love.graphics.translate( 640, 0 )
  end
  if selected.viewport == 3 then
    love.graphics.translate( 0, 480 )
  end
  if selected.viewport == 4 then
    love.graphics.translate( 640, 480 )
  end

  -- draw the bitmap image to be traced
  love.graphics.setColor( color.white )
  love.graphics.draw( bitmap, 0, 0, 0, 8, 8 ) -- rotation=0, scalex=8, scaley=8

  -- render the art area
  for i = 1,16 do
    love.graphics.print(ansiArt[i], monoFont2x, 0, (i-1)*FONT2X_HEIGHT)
  end

  drawPalette(141, 4)

  -- responsively draw game.statusbar according to cursor position
  love.graphics.setColor( color.darkgrey )
  if game.cursory*8 <= math.floor(game.height/2) then
    -- cursor is in upper screen
    love.graphics.rectangle("fill", 0, game.height-FONT_HEIGHT, game.width, FONT_HEIGHT)
    love.graphics.setColor( color.black )
    love.graphics.setFont(monoFont)
    love.graphics.print("   "..game.statusbar, 0, game.height-FONT_HEIGHT)
      -- show selected color and char
    love.graphics.setColor(selected.color)
    love.graphics.printf(selected.char, monoFont, FONT_WIDTH, game.height-FONT_HEIGHT, 16, "left")

  else
    -- cursor is in lower screen
    love.graphics.rectangle("fill", 0, 0, game.width, FONT_HEIGHT)
    love.graphics.setColor( color.black )
    love.graphics.setFont(monoFont)
    love.graphics.print("   "..game.statusbar, 0, 0)
    -- show selected color and char
    love.graphics.setColor(selected.color)
    love.graphics.printf(selected.char, monoFont, FONT_WIDTH, 0, 16, "left")
  end

  -- draw charTable if reveal key is held
  if love.keyboard.isDown("rshift") and game.os ~= "R36S" then
    drawCharTable()
  end
  if love.keyboard.isDown("lshift") and game.os == "R36S" then
    drawCharTable()
  end

  -- draw cursor
  love.graphics.setColor( color.pulsingwhite )
  love.graphics.setLineWidth(1)
  love.graphics.rectangle( "line" , (game.cursorx-1)*8, (game.cursory-1)*8, FONT2X_WIDTH, FONT2X_HEIGHT)

  -- draw selectBmp (noscroll list) if selected.bmp = ""
  if selected.bmp == "" then
    drawScrollList(" Select a BMP ", bmpFiles, "UP/DOWN: Select  RETURN: Confirm ", selected.bmpnumber, 0, 30, 60, color.brightblue, color.blue)
  end

  -- draw mouse pointer as a text triangle
  love.graphics.setFont(monoFont2x)
  love.graphics.setColor(color.white)
  love.graphics.print("▲",love.mouse.getX()-4,love.mouse.getY())

  -- draw viewports (debug only)
  love.graphics.setColor(color.brightcyan)
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line",0,0,640,480)
  love.graphics.printf("Viewport 1", monoFont, 0, 480/2, 640,"center")
  love.graphics.rectangle("line",640,0,640,480)
  love.graphics.printf("Viewport 2", monoFont, 640, 480/2, 640,"center")
  love.graphics.rectangle("line",0,480,640,240)
  love.graphics.printf("Viewport 3", monoFont, 0, (240/2)+480, 640,"center")
  love.graphics.rectangle("line",640,480,640,240)
  love.graphics.printf("Viewport 4", monoFont, 640, (240/2)+480, 640,"center")

--  overlayStats.draw() -- Should always be called last
end

function love.update(dt)
  -- Your game update here

  -- game timers
  game.timeThisSession = game.timeThisSession + dt
  if math.floor(game.timeThisSession)%2 == 1 then
    -- odd seconds
    color.pulsingwhite = {1,1,1,(game.timeThisSession%1)} -- using modulo for fading alpha channel
  else
    -- even seconds
    color.pulsingwhite = {1,1,1,1-(game.timeThisSession%1)} -- using modulo for fading alpha channel
  end
  -- set coords
  game.mousex = math.floor(love.mouse.getX()/8)+1 -- coords in font2x starting at 1x1
  game.mousey = math.floor(love.mouse.getY()/8)+1 -- coords in font2x starting at 1x1

  -- set statusbar
  game.statusbar = game.cursorx..","..game.cursory.." ("..game.mousex..","..game.mousey..") Time:"..math.floor(game.timeThisSession)
  if game.os ~= "R36S" then
    -- statusbar for all other platforms
    game.statusbar = game.statusbar .. " ["..game.os.."]"
  else
    -- statusbar for R36S
    game.statusbar = game.statusbar .. " ["..game.os.."] L1:Change Color R1:Change Viewport"
  end

  overlayStats.update(dt) -- Should always be called last
end

function love.keypressed(key, scancode, isrepeat)
  print("key:"..key.." scancode:"..scancode.." isrepeat:"..tostring(isrepeat))
  if key == "escape" and love.system.getOS() ~= "Web" then
    love.event.quit()
  else
--    overlayStats.handleKeyboard(key) -- Should always be called last
  end

  -- input for R36S
  if game.os == "R36S" then
    -- W A S D for moving cursor
    if key == "w" and game.cursory > 1 then
      game.cursory = game.cursory - 1
    end
    if key == "s" and game.cursory < math.floor(game.height/8) and game.cursory < game.canvasy then
      game.cursory = game.cursory + 1
    end
    if key == "a" and game.cursorx > 1 then
      game.cursorx = game.cursorx - 1
    end
    if key == "d" and game.cursorx < math.floor(game.width/8) and game.cursorx < game.canvasx then
      game.cursorx = game.cursorx + 1
    end
    -- (A) button to draw colored char
    if key == "z" then
      ansiArt[game.cursory][(game.cursorx*2)-1] = selected.color
      ansiArt[game.cursory][game.cursorx*2] = selected.char
    end
    -- (B) button to clear char
    if key == "lshift" then
      ansiArt[game.cursory][(game.cursorx*2)-1] = color.darkgrey
      ansiArt[game.cursory][game.cursorx*2] = "."
    end
    -- (X) button to eyedrop char
    if key == "space" then
      selected.char = ansiArt[game.cursory][game.cursorx*2]
    end
    -- (Y) button to eyedrop color
    if key == "b" then
      selected.color = ansiArt[game.cursory][(game.cursorx*2)-1]
    end
    -- arrow keys to select char
    if key == "up" and game.chary > 1 then
      game.chary = game.chary - 1
      selected.char = charTable[game.chary][game.charx]
    end
    if key == "down" and game.chary < 14 then
      game.chary = game.chary + 1
      selected.char = charTable[game.chary][game.charx]
    end
    if key == "left" and game.charx > 1 then
      game.charx = game.charx - 1
      selected.char = charTable[game.chary][game.charx]
    end
    if key == "right" and game.charx < 11 then
      game.charx = game.charx + 1
      selected.char = charTable[game.chary][game.charx]
    end
    -- L1 (l) to toggle colors
    if key == "l" then
      if game.colorSelected == 15 then
        game.colorSelected = 0
      else
        game.colorSelected = game.colorSelected + 1
      end
      selected.color = color[game.colorSelected]
    end

    -- R1 (r) to toggle viewports
    if key == "r" then
      if selected.viewport == 4 then
        selected.viewport = 1
      else
        selected.viewport = selected.viewport + 1
      end
    end

  else
    -- input for everything else (computers)
    -- arrow keys for moving cursor when BMP selected
    if selected.bmp ~= "" then
      if key == "up" and game.cursory > 1 then
        game.cursory = game.cursory - 1
      end
      if key == "down" and game.cursory < math.floor(game.height/8) and game.cursory < game.canvasy then
        game.cursory = game.cursory + 1
      end
      if key == "left" and game.cursorx > 1 then
        game.cursorx = game.cursorx - 1
      end
      if key == "right" and game.cursorx < math.floor(game.width/8) and game.cursorx < game.canvasx then
        game.cursorx = game.cursorx + 1
      end
    else
      -- cursor for selecting BMP
      if key == "up" and selected.bmpnumber > 1 then
        selected.bmpnumber = selected.bmpnumber - 1
        bitmap = love.graphics.newImage( "bmp/"..bmpFiles[selected.bmpnumber])
      end
      if key == "down" and selected.bmpnumber < #bmpFiles then
        selected.bmpnumber = selected.bmpnumber + 1
        bitmap = love.graphics.newImage( "bmp/"..bmpFiles[selected.bmpnumber])
      end
    end

      -- ralt (right option) to draw char
    if key == "ralt" then
      ansiArt[game.cursory][(game.cursorx*2)-1] = selected.color
      ansiArt[game.cursory][game.cursorx*2] = selected.char
    end
    -- backspace to delete char
    if key == "backspace" then
      ansiArt[game.cursory][(game.cursorx*2)-1] = color.darkgrey
      ansiArt[game.cursory][game.cursorx*2] = " "
    end
    -- lalt to eyedrop char
    if key == "lalt" then
      selected.char = ansiArt[game.cursory][game.cursorx*2]
    end
    -- lctrl to eyedrop color
    if key == "lctrl" then
      selected.color = ansiArt[game.cursory][(game.cursorx*2)-1]
    end
    -- char selection with rshift held, and WASD for selecting
    if love.keyboard.isDown("rshift") then
      -- w / s to select charTable row (game.chary)
      if key == "w" and game.chary > 1 then
        game.chary = game.chary - 1
        selected.char = charTable[game.chary][game.charx]
      end
      if key == "s" and game.chary < 14 then
        game.chary = game.chary + 1
        selected.char = charTable[game.chary][game.charx]
      end
      -- a / d to select charTable column (game.charx)
      if key == "a" and game.charx > 1 then
        game.charx = game.charx - 1
        selected.char = charTable[game.chary][game.charx]
      end
      if key == "d" and game.charx < 11 then
        game.charx = game.charx + 1
        selected.char = charTable[game.chary][game.charx]
      end
    end

        -- L1 (l) to toggle colors (for testing)
        if key == "l" then
          if game.colorSelected == 15 then
            game.colorSelected = 0
          else
            game.colorSelected = game.colorSelected + 1
          end
          selected.color = color[game.colorSelected]
        end

  end

  if key == "f2" then
    -- load ansiart
    local tempData = love.filesystem.read("ansiart.xtui")
    ansiArt = json.decode(tempData)
  end

  if key == "f3" then
    bmpFiles = love.filesystem.getDirectoryItems( "bmp" )
    print(#bmpFiles.." files in bmp folder")
    table.sort(bmpFiles)
  end

  if key == "f8" then
    local files = love.filesystem.getDirectoryItems( "quicksave" )
    saveData("quicksave_"..(#files)..".xtui","quicksave") -- running numbers for quicksaves
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
  if (game.mousex >= 1 and game.mousex <= 16) and (game.mousey >= 1 and game.mousey <= 16) then
    ansiArt[game.mousey][(game.mousex*2)-1] = selected.color
    ansiArt[game.mousey][game.mousex*2] = selected.char
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


