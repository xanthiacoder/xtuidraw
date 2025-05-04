--[[
screen resolution = 1280 x 720 px
screen chars = 160 x 45 (font)
screen chars = 160 x 90 (font2x)

ansicanvas dimensions:
should be variable to allow making UI assets
- set max as 160x90 ? (max resolution 1280x720)
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

-- user monoFont to display, 11 columns x 17 rows = 187 chars
local charTable = {
  [1]  = {"█","▓","▒","░","▄","▀","▌","▐","/","|","\\"},
  [2]  = {"≈","■","¥","ε","δ","Φ","Ω","∩","♪","∞","≡"},
  [3]  = {"╔","═","╦","╩","╗","║","╠","╬","╣","╚","╝"},
  [4]  = {"┌","─","┬","┴","┐","│","├","┼","┤","└","┘"},
  [5]  = {"╓","╒","╤","╥","╨","╧","╥","╤","╖","╕","."},
  [6]  = {"╫","╪","╟","╞","╢","╡","╙","╘","╜","╛",","},
  [7]  = {"!","@","#","$","%","^","&","*","(",")"," "},
  [8]  = {"a","b","c","d","e","f","g","h","i","j","k"},
  [9]  = {"l","m","n","o","p","q","r","s","t","u","v"},
  [10] = {"w","x","y","z","-","=","_","+","[","]","'"},
  [11] = {"A","B","C","D","E","F","G","H","I","J","K"},
  [12] = {"L","M","N","O","P","Q","R","S","T","U","V"},
  [13] = {"W","X","Y","Z","<",">",",",".",";",":","?"},
  [14] = {"1","2","3","4","5","6","7","8","9","0","`"},
  [15] = {"☺","☻","♥","♦","♣","♠","•","◘","○","◙","♀",},
  [16] = {string.char(14),string.char(15),string.char(16),string.char(17),string.char(18),string.char(19),string.char(20),string.char(21),string.char(22),string.char(23),string.char(24),},
  [17] = {string.char(25),string.char(26),string.char(27),string.char(28),string.char(29),string.char(30),string.char(31),string.char(32),string.char(33),string.char(34),string.char(35),},
}

local selected = {
  color = color.white,
  char  = "█",
  bmp   = "",
  bmpnumber = 1,
  viewport = 1,
  textmode = 2, -- 1 = 8x16, 2 = 8x8
}

-- cursor text to display when hovering over a fixed 8x8 coordinate
-- fullscreen 160 x 90
-- initialize table
local hover = {}
for i = 1,160 do -- number of columns (x)
  hover[i] = {}
  for j = 1,90 do -- number of rows (y)
    hover[i][j] = ""
  end
end
-- enter test data
hover[13][7] = "chair"
hover[13][8] = "chair legs"
hover[28][11] = "bed"
hover[29][11] = "bed"
hover[28][12] = "bottom of bed"
hover[29][12] = "bottom of bed"
hover[29][3] = "bookshelf"
hover[29][4] = "bookshelf"
hover[29][5] = "bookshelf"
hover[29][6] = "bookshelf"
hover[8][11] = "carpet"
hover[29][25] = "wardrobe"
hover[29][26] = "wardrobe"
hover[29][27] = "wardrobe"
hover[29][28] = "wardrobe"
hover[12][5] = "desk"
hover[12][6] = "desk and something"
hover[13][5] = "desk"
hover[13][6] = "desk and something"
hover[14][5] = "desk"
hover[14][6] = "desk and something"
hover[15][5] = "desk"
hover[15][6] = "desk and something"
hover[1][31] = "hole in the wall"

local click = {}
for i = 1,160 do -- number of columns (x)
  click[i] = {}
  for j = 1,90 do -- number of rows (y)
    click[i][j] = ""
  end
end
-- enter test data
click[13][7] = "This is a...chair."
click[13][8] = "Nice! These are chair legs."
click[28][11] = "You sleep here. zZZ, very cozy."
click[29][11] = "You sleep here. zZZ, very cozy."
click[28][12] = "Come on now, don't look so tense. There's no monster under the bed."
click[29][12] = "Come on now, don't look so tense. There's no monster under the bed."
click[29][3] = "The books on here are neatly arranged by you. Ranging from shortest to tallest, thinnest to thickest."
click[29][4] = "There is a gap."
click[29][5] = "The books on here are neatly arranged by you. Ranging from shortest to tallest, thinnest to thickest."
click[29][6] = "The books on here are neatly arranged by you. Ranging from shortest to tallest, thinnest to thickest."
click[8][11] = "The corner of the carpet is curled up."
click[29][25] = "It's open and there's HEAPS of clothes. Uh oh, this one is messy, don't let your mom see."
click[29][26] = "You see a part of the pile that is higher than the rest."
click[29][27] = "Geez did you really need this much clothes?"
click[29][28] = "It'll take FOREVER to clean this wardrobe up."
click[12][6] = "The desk is very plain and bare except for one thing."
click[13][6] = "The desk is very plain and bare except for one thing."
click[14][6] = "The desk is very plain and bare except for one thing."
click[15][6] = "The desk is very plain and bare except for one thing."
click[1][31] = "What's this?"

local game = {}

-- set game timers
game.timeThisSession = 0
game.autosaveCooldown = 0

-- set game flags (editor)
game.insertMode = false

-- set game message
game.message = ""
game.messageViewport = 1

-- set game mode
-- "edit" - game editor mode ; "play" - game playing mode
game.mode = "play"

-- set game scene
game.scene = "title"

-- set game script
game.script = ""

-- detect viewport
game.width, game.height = love.graphics.getDimensions( )
print("viewport: "..game.width.."x"..game.height)

-- set default cursor coord
game.cursorx = 1
game.cursory = 1

-- set default player coord (shown as "P" while standing, "p" while squatting)
-- 0,0 is off-screen; coord follows monoFont2x 8x8px 80x60 chars, screen 1 only)
-- for movement, x increments by 1, y increments by 2
-- movement using arrow keys while in "play" mode
game.playerx = 41
game.playery = 31 -- MUST be odd number

-- set default player display char
-- "P" - standing player
-- "p" - crouching player
game.playerChar = "P"

-- set default canvas size (16x16)
game.canvasx = 16
game.canvasy = 16

-- init pixelArt canvas
local pixelArt = love.graphics.newCanvas( game.canvasx, game.canvasy )

-- set default char table selected [1..11][1..14]
game.charx = 1
game.chary = 1

-- set default color number selected
game.colorSelected = 15
game.bgcolorSelected = 0

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
if love.filesystem.getInfo("wip") == nil then
  if game.os == "R36S" then
    os.execute("mkdir " .. love.filesystem.getSaveDirectory() .. "//wip")
    print("R36S: created directory - wip")
  else
    love.filesystem.createDirectory("wip")
    print("Created directory - wip")
  end
end

local success = love.filesystem.remove( "bmp/.DS_Store" ) -- cleanup for MacOS
if success then
  print("DS_Store removed from BMP")
else
  print("No files removed from BMP")
end
local bmpFiles = love.filesystem.getDirectoryItems( "bmp" ) -- table of files in the bmp directory

local colorpalette = {}

-- initialize max ansiArt 160x90 chars (8x8 font)
-- viewport 1 = 80 x 29 (8x16 font)
-- viewport 2 = 80 x 29 (8x16 font)
MAX_CANVAS_X = 160
MAX_CANVAS_Y = 90
local ansiArt = {}
-- i = Canvas row, Y
-- j = Canvas Column, X
for i = 1,MAX_CANVAS_Y do
  ansiArt[i] = {}
  for j = 1,MAX_CANVAS_X do
    ansiArt[i][j+(j-1)] = color.darkgrey
    ansiArt[i][j*2] = " "
  end
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

---comment
---@param x integer column coordinate in exact pixel
---@param y integer row coordinate in exact pixel
function drawCharTable( x, y)

  -- draw background color
  if game.bgcolorSelected >= 0 and game.bgcolorSelected <= 15 then
    love.graphics.setColor(color[game.bgcolorSelected])
  else
    love.graphics.setColor(color.black)
  end

  love.graphics.setColor(selected.color)
  love.graphics.setFont(monoFont)
  for i = 1,17 do
    for j = 1,11 do
      love.graphics.setColor(selected.color)
      love.graphics.setFont(monoFont)
      love.graphics.print(charTable[i][j], x + (((j-1)*2)*FONT_WIDTH), y + ((i-1)*FONT_HEIGHT) )
    end
  end

  -- highlight current selection
  love.graphics.setColor( color.white )
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line", x+(((game.charx-1)*2)*FONT_WIDTH), y+((game.chary-1)*FONT_HEIGHT), FONT_WIDTH, FONT_HEIGHT)

end

---@param filename string
---@param directory string
function saveData( filename , directory )

  -- initialize max ansiFlat (1D array) for compatibility
  local ansiFlat = {}
    for i = 1,(game.canvasy*game.canvasx)*2 do
    ansiFlat[i] = ""
  end

  -- user temp table so as not to mess up ansiArt table
  local ansiArtTemp = {}
  for i = 1,game.canvasy do
    ansiArtTemp[i] = {}
  end
  for i = 1,game.canvasy do
    for j = 1,game.canvasx*2 do
      ansiArtTemp[i][j] = ansiArt[i][j]
    end
  end
  -- place \n at end of each row
  for i = 1,game.canvasy do
      ansiArtTemp[i][game.canvasx*2] = ansiArtTemp[i][game.canvasx*2] .. "\n"
  end

  -- create 1D from 2D array for compatibility
  for i = 1,(game.canvasy*game.canvasx)*2 do
    local intergal, fractional = math.modf(i/(game.canvasx*2))
    intergal = intergal + 1
    fractional = i%(game.canvasx*2)
    if fractional == 0 then
      fractional = game.canvasx*2
      intergal = intergal - 1
    end
--    print(intergal ..","..fractional)
    ansiFlat[i] = ansiArtTemp[intergal][fractional]
  end

  -- save regular 2D table
  if game.os ~= "R36S" then
    -- save ansiart (old version dump)
--    local success, message =love.filesystem.write(directory.."/"..filename, json.encode(ansiArt))
--    if success then
--	    print ('file created: '..directory.."/"..filename)
--    else
--	    print ('file not created: '..message)
--    end

  -- save ansiart (flat version)
    local success, message =love.filesystem.write(directory.."/"..game.bgcolorSelected.."-"..filename, json.encode(ansiFlat))
    if success then
	    print ('file created: '..directory.."/"..game.bgcolorSelected.."-"..filename)
    else
      game.message = 'file not created: '..message
	    print ('file not created: '..message)
    end
  else
    -- save ansiart for R36S
    local f = io.open(love.filesystem.getSaveDirectory().."//"..directory.."/"..filename, "w")
    f:write(json.encode(ansiArt))
    f:close()
    -- save ansiflat for R36S
    local f = io.open(love.filesystem.getSaveDirectory().."//"..directory.."/"..filename.."flat", "w")
    f:write(json.encode(ansiArt))
    f:close()
  end
end


function loadData()
  local tempArt = json.decode(love.filesystem.read("wip/data.xtui")) -- manually set background
  local canvasx = 0
  local canvasy = 0
  -- check for first instance of \n in table (first \n)
  local loop = 2
  while canvasx == 0 do
  	if string.find(tempArt[loop], "\n") ~= nil then
  		canvasx = loop/2
  	end
  	loop = loop + 2
  end
  canvasy = #tempArt/(canvasx*2)

  -- load tempArt into ansiArt
  game.canvasx = canvasx
  game.canvasy = canvasy
  local artRow = 1
  local artColumn = 1
  print("Loaded ansiArt data: "..canvasx..","..canvasy)
  for i = 1,canvasx*canvasy do
    if artColumn <= canvasx then
      ansiArt[artRow][(artColumn*2)-1] = tempArt[(i*2)-1]
      ansiArt[artRow][artColumn*2] = tempArt[i*2]
      artColumn = artColumn + 1
    else
      artColumn = 1
      artRow = artRow + 1
      ansiArt[artRow][(artColumn*2)-1] = tempArt[(i*2)-1]
      ansiArt[artRow][artColumn*2] = tempArt[i*2]
      artColumn = artColumn + 1
    end
  end

end


function love.load()
  https = runtimeLoader.loadHTTPS()
  -- Your game load here

  -- fonts
  monoFont = love.graphics.newFont("fonts/"..FONT, FONT_SIZE)
  monoFont2s = love.graphics.newFont("fonts/"..FONT, FONT_SIZE*2)
  monoFont4s = love.graphics.newFont("fonts/"..FONT, FONT_SIZE*4)
  monoFont2x = love.graphics.newFont("fonts/"..FONT2X, FONT2X_SIZE)
  monoFont2x4s = love.graphics.newFont("fonts/"..FONT2X, FONT2X_SIZE*4)
  pixelFont = love.graphics.newFont("fonts/"..FONT2X, 1)
  love.graphics.setFont( monoFont )
  -- print(monoFont:getWidth("█"))
  -- print(monoFont:getHeight())
  love.graphics.setFont( monoFont2x )
  -- print(monoFont2x:getWidth("█"))
  -- print(monoFont2x:getHeight())

  -- xtui screens using monoFont
  -- [scene number][screen 1,screen 2,screen 1 bgcolor, screen 2 bgcolor]
  screen = {}
  screen[1] = {
    [1] = json.decode(love.filesystem.read("xtui/4-xtuisplash1.xtui")),
    [2] = json.decode(love.filesystem.read("xtui/8-xtuisplash2.xtui")),
    [3] = 4,
    [4] = 8,
  }

  -- buttons
  button = {
    [1]  = json.decode(love.filesystem.read("xtui/button-01.xtui")),
    [2]  = json.decode(love.filesystem.read("xtui/button-02.xtui")),
    [3]  = json.decode(love.filesystem.read("xtui/button-03.xtui")),
    [4]  = json.decode(love.filesystem.read("xtui/button-04.xtui")),
    [5]  = json.decode(love.filesystem.read("xtui/button-05.xtui")),
    [6]  = json.decode(love.filesystem.read("xtui/button-06.xtui")),
    [7]  = json.decode(love.filesystem.read("xtui/button-07.xtui")),
    [8]  = json.decode(love.filesystem.read("xtui/button-08.xtui")),
    [9]  = json.decode(love.filesystem.read("xtui/button-09.xtui")),
    [10] = json.decode(love.filesystem.read("xtui/button-10.xtui")),
  }

  -- screen 2
  screen2 = {
    ["drawmode"] = json.decode(love.filesystem.read("xtui/0-drawmode.xtui")),
  }

  -- pointers
  pointer = love.graphics.newImage("img/pointer-wand.png")

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

---comment
---@param msg string Text message to display
---@param viewport integer 1..4 to switch location of display output
function drawMessage( msg, viewport)
  local rows = math.ceil(#msg/60)
  -- draw frame
  love.graphics.setColor(color.white)
  love.graphics.setFont(monoFont2x)
  for i = 1,62 do
    love.graphics.print("▄", (8+(i-1))*FONT_WIDTH, (FONT_HEIGHT/2)+((12)-(math.floor(rows/2)))*FONT_HEIGHT)
  end
  love.graphics.setFont(monoFont)
  for i = 1,rows+2 do
    love.graphics.print("▐", 7*FONT_WIDTH, ((12+i)-(math.floor(rows/2)))*FONT_HEIGHT )
  end
  love.graphics.setColor(color.darkgrey)
  for i = 1,62 do
      love.graphics.print("▀", (8+(i-1))*FONT_WIDTH, ((15+rows)-(math.floor(rows/2)))*FONT_HEIGHT)
  end
  love.graphics.setFont(monoFont)
  for i = 1,rows+2 do
    love.graphics.print("▌", (7+63)*FONT_WIDTH, ((12+i)-(math.floor(rows/2)))*FONT_HEIGHT )
  end

  love.graphics.setColor(color.grey)
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("fill", 8*FONT_WIDTH, (13-(math.floor(rows/2)))*FONT_HEIGHT, 62*FONT_WIDTH, (rows+2)*FONT_HEIGHT )
  love.graphics.setColor(color.black)
  love.graphics.printf(msg, monoFont, 10*FONT_WIDTH, (14-(math.floor(rows/2)))*FONT_HEIGHT, 60*FONT_WIDTH, "left")
end


function drawButtons()
  love.graphics.setColor(color.white)
  love.graphics.setFont(monoFont2x)
  for i = 1,10 do
    love.graphics.print(button[i],0+((i-1)*128),480)
  end
end


---@param x integer coordinate using monoFont2x dimensions
---@param y integer coordinate using monoFont2x dimensions
function drawPlayer(x,y)

  -- make it blinking with alpha
  love.graphics.setFont(monoFont)
  if(math.floor(game.timeThisSession))%2 == 1 then
    love.graphics.setColor(1,1,1,1)
  else
    love.graphics.setColor(0.5,0.5,0.5,1)
  end
  love.graphics.print(game.playerChar,(game.playerx-1)*FONT2X_WIDTH, (game.playery-1)*FONT2X_HEIGHT)
end

function clearCanvas()
  for i = 1,game.canvasy do
    for j = 1,game.canvasx do
      ansiArt[i][j*2] = " "
    end
  end
  pixelArt = love.graphics.newCanvas( game.canvasx, game.canvasy )
end

---@param textmode integer 1..2 (1 = 8x16, 2 = 8x8)
---@param bgcolor integer 0..16 (0 black .. 16 transparent)
function drawArtCanvas(textmode, bgcolor)

  -- draw checkerboard
  local drawBright = true -- draw a bright box
  for i = 1,game.canvasy do -- iterate over rows
    if (i%2) == 0 then -- odd numbered row detected
      drawBright = true
    else
      drawBright = false
    end
    for j = 1,game.canvasx do -- iterate over columns
      if drawBright then
        -- draw bright box
        love.graphics.setColor(color.white)
        if textmode == 2 then
          love.graphics.rectangle("fill", 0+(j-1)*FONT2X_WIDTH, 0+(i-1)*FONT2X_HEIGHT, FONT2X_WIDTH, FONT2X_HEIGHT)
        else
          love.graphics.rectangle("fill", 0+(j-1)*FONT_WIDTH, 0+(i-1)*FONT_HEIGHT, FONT_WIDTH, FONT_HEIGHT)
        end
        drawBright = false
      else
        -- draw dark box
        love.graphics.setColor(color.darkgrey)
        if textmode == 2 then
          love.graphics.rectangle("fill", 0+(j-1)*FONT2X_WIDTH, 0+(i-1)*FONT2X_HEIGHT, FONT2X_WIDTH, FONT2X_HEIGHT)
        else
          love.graphics.rectangle("fill", 0+(j-1)*FONT_WIDTH, 0+(i-1)*FONT_HEIGHT, FONT_WIDTH, FONT_HEIGHT)
        end
        drawBright = true
      end
    end
  end

  -- draw background solid color
  if bgcolor == 16 then
    love.graphics.setColor(0,0,0,0) -- transparent
  else
    love.graphics.setColor(color[bgcolor])
  end
  love.graphics.setLineWidth(1)
  if textmode == 2 then
    love.graphics.rectangle( "fill", 0, 0, (game.canvasx)*FONT2X_WIDTH, (game.canvasy)*FONT2X_HEIGHT)
  else
    love.graphics.rectangle( "fill", 0, 0, (game.canvasx)*FONT_WIDTH, (game.canvasy)*FONT_HEIGHT)
  end

  -- draw ansiArt
  love.graphics.setColor(color.white)
  for i = 1,game.canvasy do
    for j = 1,game.canvasx do
      tempText = {
        ansiArt[i][j+(j-1)],
        ansiArt[i][j*2],
      }
      if textmode == 2 then
        love.graphics.print(tempText, monoFont2x, (j-1)*FONT2X_WIDTH, (i-1)*FONT2X_HEIGHT)
      else
        love.graphics.print(tempText, monoFont, (j-1)*FONT_WIDTH, (i-1)*FONT_HEIGHT)
      end
    end
  end

  -- draw canvas border
  love.graphics.setColor(color.brightcyan)
  love.graphics.setLineWidth(1)
  if textmode == 2 then
    love.graphics.rectangle("line", 0, 0, game.canvasx*FONT2X_WIDTH, game.canvasy*FONT2X_HEIGHT)
  else
    love.graphics.rectangle("line", 0, 0, game.canvasx*FONT_WIDTH, game.canvasy*FONT_HEIGHT)
  end

end


function drawCloseup()

  love.graphics.setLineWidth(1)
  if selected.textmode == 2 then
    love.graphics.setFont(monoFont2x4s)
  else
    love.graphics.setFont(monoFont4s)
  end

  -- viewport is 80x60 (8x8px resolution for game.mousex and game.mousey)
  if game.mousex < 40 then
    -- cursor is on left side of viewport
    if game.mousey < 30 then
      -- cursor is on higher side of viewport
      if selected.textmode == 2 then
        love.graphics.setColor(color[game.bgcolorSelected])
        love.graphics.rectangle("fill",639-(5*(FONT2X_WIDTH*4)), 479-(5*(FONT2X_HEIGHT*4)), 5*(FONT2X_WIDTH*4), 5*(FONT2X_HEIGHT*4))
        love.graphics.setColor(color.brightcyan)
        love.graphics.rectangle("line",639-(5*(FONT2X_WIDTH*4)), 479-(5*(FONT2X_HEIGHT*4)), 5*(FONT2X_WIDTH*4), 5*(FONT2X_HEIGHT*4))
        for i = 1,5 do -- 5 preview rows
          for j = 1,5 do -- 5 preview columns
            if (i-3)+game.mousey > 0 and (j-3)+game.mousex > 0 and (i-3)+game.mousey <= game.canvasy and (j-3)+game.mousex <= game.canvasx then
              love.graphics.setColor(ansiArt[(i-3)+game.mousey][(((j-3)+game.mousex)*2)-1])
              love.graphics.print(ansiArt[(i-3)+game.mousey][((j-3)+game.mousex)*2],639-((6-j)*(FONT2X_WIDTH*4)), 479-((6-i)*(FONT2X_HEIGHT*4)))
            end
          end
        end
      else
        love.graphics.setColor(color[game.bgcolorSelected])
        love.graphics.rectangle("fill",639-(5*(FONT_WIDTH*4)), 479-(5*(FONT_HEIGHT*4)), 5*(FONT_WIDTH*4), 5*(FONT_HEIGHT*4))
        love.graphics.setColor(color.brightcyan)
        love.graphics.rectangle("line",639-(5*(FONT_WIDTH*4)), 479-(5*(FONT_HEIGHT*4)), 5*(FONT_WIDTH*4), 5*(FONT_HEIGHT*4))
        for i = 1,5 do -- 5 preview rows
          for j = 1,5 do -- 5 preview columns
            if (i-3)+math.ceil(game.mousey/2) > 0 and (j-3)+game.mousex > 0 and (i-3)+math.ceil(game.mousey/2) <= game.canvasy and (j-3)+game.mousex <= game.canvasx then
              love.graphics.setColor(ansiArt[(i-3)+math.ceil(game.mousey/2)][(((j-3)+game.mousex)*2)-1])
              love.graphics.print(ansiArt[(i-3)+math.ceil(game.mousey/2)][((j-3)+game.mousex)*2],639-((6-j)*(FONT_WIDTH*4)), 479-((6-i)*(FONT_HEIGHT*4)))
            end
          end
        end
      end
    else
      -- cursor is on lower side of viewport
      if selected.textmode == 2 then
        love.graphics.setColor(color[game.bgcolorSelected])
        love.graphics.rectangle("fill",639-(5*(FONT2X_WIDTH*4)), 0, 5*(FONT2X_WIDTH*4), 5*(FONT2X_HEIGHT*4))
        love.graphics.setColor(color.brightcyan)
        love.graphics.rectangle("line",639-(5*(FONT2X_WIDTH*4)), 0, 5*(FONT2X_WIDTH*4), 5*(FONT2X_HEIGHT*4))
        for i = 1,5 do -- 5 preview rows
          for j = 1,5 do -- 5 preview columns
            if (i-3)+game.mousey > 0 and (j-3)+game.mousex > 0 and (i-3)+game.mousey <= game.canvasy and (j-3)+game.mousex <= game.canvasx then
              love.graphics.setColor(ansiArt[(i-3)+game.mousey][(((j-3)+game.mousex)*2)-1])
              love.graphics.print(ansiArt[(i-3)+game.mousey][((j-3)+game.mousex)*2],639-((6-j)*(FONT2X_WIDTH*4)), 0+((i-1)*(FONT2X_HEIGHT*4)))
            end
          end
        end
      else
        love.graphics.setColor(color[game.bgcolorSelected])
        love.graphics.rectangle("fill",639-(5*(FONT_WIDTH*4)), 0, 5*(FONT_WIDTH*4), 5*(FONT_HEIGHT*4))
        love.graphics.setColor(color.brightcyan)
        love.graphics.rectangle("line",639-(5*(FONT_WIDTH*4)), 0, 5*(FONT_WIDTH*4), 5*(FONT_HEIGHT*4))
        for i = 1,5 do -- 5 preview rows
          for j = 1,5 do -- 5 preview columns
            if (i-3)+math.ceil(game.mousey/2) > 0 and (j-3)+game.mousex > 0 and (i-3)+math.ceil(game.mousey/2) <= game.canvasy and (j-3)+game.mousex <= game.canvasx then
              love.graphics.setColor(ansiArt[(i-3)+math.ceil(game.mousey/2)][(((j-3)+game.mousex)*2)-1])
              love.graphics.print(ansiArt[(i-3)+math.ceil(game.mousey/2)][((j-3)+game.mousex)*2],639-((6-j)*(FONT_WIDTH*4)), 0+((i-1)*(FONT_HEIGHT*4)))
            end
          end
        end
      end
    end
  else
  -- cursor is on right side of viewport
    if game.mousey < 30 then
      -- cursor is on higher side of viewport
      if selected.textmode == 2 then
        love.graphics.setColor(color[game.bgcolorSelected])
        love.graphics.rectangle("fill",0, 479-(5*(FONT2X_HEIGHT*4)), 5*(FONT2X_WIDTH*4), 5*(FONT2X_HEIGHT*4))
        love.graphics.setColor(color.brightcyan)
        love.graphics.rectangle("line",0, 479-(5*(FONT2X_HEIGHT*4)), 5*(FONT2X_WIDTH*4), 5*(FONT2X_HEIGHT*4))
        for i = 1,5 do -- 5 preview rows
          for j = 1,5 do -- 5 preview columns
            if (i-3)+game.mousey > 0 and (j-3)+game.mousex > 0 and (i-3)+game.mousey <= game.canvasy and (j-3)+game.mousex <= game.canvasx then
              love.graphics.setColor(ansiArt[(i-3)+game.mousey][(((j-3)+game.mousex)*2)-1])
              love.graphics.print(ansiArt[(i-3)+game.mousey][((j-3)+game.mousex)*2],0+((j-1)*(FONT2X_WIDTH*4)), 479-((6-i)*(FONT2X_HEIGHT*4)))
            end
          end
        end
      else
        love.graphics.setColor(color[game.bgcolorSelected])
        love.graphics.rectangle("fill",0, 479-(5*(FONT_HEIGHT*4)), 5*(FONT_WIDTH*4), 5*(FONT_HEIGHT*4))
        love.graphics.setColor(color.brightcyan)
        love.graphics.rectangle("line",0, 479-(5*(FONT_HEIGHT*4)), 5*(FONT_WIDTH*4), 5*(FONT_HEIGHT*4))
        for i = 1,5 do -- 5 preview rows
          for j = 1,5 do -- 5 preview columns
            if (i-3)+math.ceil(game.mousey/2) > 0 and (j-3)+game.mousex > 0 and (i-3)+math.ceil(game.mousey/2) <= game.canvasy and (j-3)+game.mousex <= game.canvasx then
              love.graphics.setColor(ansiArt[(i-3)+math.ceil(game.mousey/2)][(((j-3)+game.mousex)*2)-1])
              love.graphics.print(ansiArt[(i-3)+math.ceil(game.mousey/2)][((j-3)+game.mousex)*2],0+((j-1)*(FONT_WIDTH*4)), 479-((6-i)*(FONT_HEIGHT*4)))
            end
          end
        end
      end
    else
      -- cursor is on lower side of viewport
      if selected.textmode == 2 then
        love.graphics.setColor(color[game.bgcolorSelected])
        love.graphics.rectangle("fill",0, 0, 5*(FONT2X_WIDTH*4), 5*(FONT2X_HEIGHT*4))
        love.graphics.setColor(color.brightcyan)
        love.graphics.rectangle("line",0, 0, 5*(FONT2X_WIDTH*4), 5*(FONT2X_HEIGHT*4))
        for i = 1,5 do -- 5 preview rows
          for j = 1,5 do -- 5 preview columns
            if (i-3)+game.mousey > 0 and (j-3)+game.mousex > 0 and (i-3)+game.mousey <= game.canvasy and (j-3)+game.mousex <= game.canvasx then
              love.graphics.setColor(ansiArt[(i-3)+game.mousey][(((j-3)+game.mousex)*2)-1])
              love.graphics.print(ansiArt[(i-3)+game.mousey][((j-3)+game.mousex)*2],0+((j-1)*(FONT2X_WIDTH*4)), 0+((i-1)*(FONT2X_HEIGHT*4)))
            end
          end
        end
      else
        love.graphics.setColor(color[game.bgcolorSelected])
        love.graphics.rectangle("fill",0, 0, 5*(FONT_WIDTH*4), 5*(FONT_HEIGHT*4))
        love.graphics.setColor(color.brightcyan)
        love.graphics.rectangle("line",0, 0, 5*(FONT_WIDTH*4), 5*(FONT_HEIGHT*4))
        for i = 1,5 do -- 5 preview rows
          for j = 1,5 do -- 5 preview columns
            if (i-3)+math.ceil(game.mousey/2) > 0 and (j-3)+game.mousex > 0 and (i-3)+math.ceil(game.mousey/2) <= game.canvasy and (j-3)+game.mousex <= game.canvasx then
              love.graphics.setColor(ansiArt[(i-3)+math.ceil(game.mousey/2)][(((j-3)+game.mousex)*2)-1])
              love.graphics.print(ansiArt[(i-3)+math.ceil(game.mousey/2)][((j-3)+game.mousex)*2],0+((j-1)*(FONT_WIDTH*4)), 0+((i-1)*(FONT_HEIGHT*4)))
            end
          end
        end
      end
    end
  end
end


---@param x integer column using monoFont width FONT_WIDTH
---@param y integer row using monoFont height FONT_HEIGHT
function drawBrushes( x, y )

  -- this part is drawing Palette
  love.graphics.setFont(monoFont)
  love.graphics.setColor(color.white)
  love.graphics.print("Foreground", (x+28)*FONT_WIDTH ,(y+2)*FONT_HEIGHT)
  love.graphics.print("Background", (x+46)*FONT_WIDTH ,(y+2)*FONT_HEIGHT)

  love.graphics.setColor(color[game.bgcolorSelected])
  love.graphics.print("██\n██", (x+43)*FONT_WIDTH ,(y+1)*FONT_HEIGHT)

  -- draw background first
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("fill", (x+25)*FONT_WIDTH ,(y+4)*FONT_HEIGHT, 16*FONT_WIDTH, 4*FONT_HEIGHT)
  love.graphics.rectangle("fill", (x+43)*FONT_WIDTH ,(y+4)*FONT_HEIGHT, 16*FONT_WIDTH, 4*FONT_HEIGHT)
  love.graphics.rectangle("fill", (x+2)*FONT_WIDTH,(y+1)*FONT_HEIGHT, 2*FONT_WIDTH, 2*FONT_HEIGHT)
  love.graphics.rectangle("fill", 82*FONT_WIDTH,4*FONT_HEIGHT, 21*FONT_WIDTH, 17*FONT_HEIGHT)
  love.graphics.rectangle("fill", (x+25)*FONT_WIDTH ,(y+11)*FONT_HEIGHT, 16*FONT_WIDTH, 4*FONT_HEIGHT)
  love.graphics.rectangle("fill", (x+43)*FONT_WIDTH ,(y+11)*FONT_HEIGHT, 16*FONT_WIDTH, 4*FONT_HEIGHT)

  -- draw brush
  love.graphics.setFont(monoFont2s)
  love.graphics.setColor(selected.color)
  love.graphics.print(selected.char,(x+2)*FONT_WIDTH,(y+1)*FONT_HEIGHT)
  love.graphics.setFont(monoFont)
  love.graphics.setColor(color.white)
  love.graphics.print("Brush", (x+5)*FONT_WIDTH ,(y+2)*FONT_HEIGHT)
  love.graphics.print("Custom  Palette", (x+35)*FONT_WIDTH ,(y+9)*FONT_HEIGHT)
  love.graphics.print(" Color  mixer", (x+35)*FONT_WIDTH ,(y+16)*FONT_HEIGHT)

  drawCharTable( 82*FONT_WIDTH, 4*FONT_HEIGHT )

  -- draw foreground color
  love.graphics.setColor(selected.color)
  love.graphics.print("██\n██", (x+25)*FONT_WIDTH ,(y+1)*FONT_HEIGHT)

  love.graphics.setColor(color[8])
  love.graphics.print("██\n▓▓\n▒▒\n░░", (x+25)*FONT_WIDTH ,(y+4)*FONT_HEIGHT)
  love.graphics.setColor(color[9])
  love.graphics.print("██\n▓▓\n▒▒\n░░", (x+27)*FONT_WIDTH ,(y+4)*FONT_HEIGHT)
  love.graphics.setColor(color[10])
  love.graphics.print("██\n▓▓\n▒▒\n░░", (x+29)*FONT_WIDTH ,(y+4)*FONT_HEIGHT)
  love.graphics.setColor(color[11])
  love.graphics.print("██\n▓▓\n▒▒\n░░", (x+31)*FONT_WIDTH ,(y+4)*FONT_HEIGHT)
  love.graphics.setColor(color[12])
  love.graphics.print("██\n▓▓\n▒▒\n░░", (x+33)*FONT_WIDTH ,(y+4)*FONT_HEIGHT)
  love.graphics.setColor(color[13])
  love.graphics.print("██\n▓▓\n▒▒\n░░", (x+35)*FONT_WIDTH ,(y+4)*FONT_HEIGHT)
  love.graphics.setColor(color[14])
  love.graphics.print("██\n▓▓\n▒▒\n░░", (x+37)*FONT_WIDTH ,(y+4)*FONT_HEIGHT)
  love.graphics.setColor(color[15])
  love.graphics.print("██\n▓▓\n▒▒\n░░", (x+39)*FONT_WIDTH ,(y+4)*FONT_HEIGHT)

  love.graphics.setColor(color[0])
  love.graphics.print("██\n▓▓\n▒▒\n░░", (x+43)*FONT_WIDTH ,(y+4)*FONT_HEIGHT)
  love.graphics.setColor(color[1])
  love.graphics.print("██\n▓▓\n▒▒\n░░", (x+45)*FONT_WIDTH ,(y+4)*FONT_HEIGHT)
  love.graphics.setColor(color[2])
  love.graphics.print("██\n▓▓\n▒▒\n░░", (x+47)*FONT_WIDTH ,(y+4)*FONT_HEIGHT)
  love.graphics.setColor(color[3])
  love.graphics.print("██\n▓▓\n▒▒\n░░", (x+49)*FONT_WIDTH ,(y+4)*FONT_HEIGHT)
  love.graphics.setColor(color[4])
  love.graphics.print("██\n▓▓\n▒▒\n░░", (x+51)*FONT_WIDTH ,(y+4)*FONT_HEIGHT)
  love.graphics.setColor(color[5])
  love.graphics.print("██\n▓▓\n▒▒\n░░", (x+53)*FONT_WIDTH ,(y+4)*FONT_HEIGHT)
  love.graphics.setColor(color[6])
  love.graphics.print("██\n▓▓\n▒▒\n░░", (x+55)*FONT_WIDTH ,(y+4)*FONT_HEIGHT)
  love.graphics.setColor(color[7])
  love.graphics.print("██\n▓▓\n▒▒\n░░", (x+57)*FONT_WIDTH ,(y+4)*FONT_HEIGHT)


end


function love.draw()
  -- Your game draw here (from bottom to top layer)

    -- must be the start of love.draw, love.graphics.translate also resets at each love.draw
    if selected.viewport == 1 then
      love.graphics.translate( 0, 0 )
    end
    if selected.viewport == 2 then
      love.graphics.translate( -640, 0 )
    end
    if selected.viewport == 3 then
      love.graphics.translate( 0, -480 )
    end
    if selected.viewport == 4 then
      love.graphics.translate( -640, -480 )
    end

  -- draw tooltip
  local tooltip = "C - clear canvas\n"
  tooltip = tooltip .. "= - toggle textmode "..selected.textmode.."\n"
  tooltip = tooltip .. "m - change between play and edit mode\n"
  tooltip = tooltip .. "[ ] - change canvas width "..game.canvasx.."\n"
  tooltip = tooltip .. "; ' - change canvas height "..game.canvasy.."\n"
  tooltip = tooltip .. "/ - change background color "..game.bgcolorSelected.."\n"
  tooltip = tooltip .. "right-shift + WASD - select char\n"
  tooltip = tooltip .. "F8 - quicksave\n"
  tooltip = tooltip .. "ESC - quit\n"
  love.graphics.setFont(monoFont)
  love.graphics.setColor(color.white)
  love.graphics.printf(tooltip, 640+(40*FONT_WIDTH), (29-8)*FONT_HEIGHT, 320, "left")


  -- draw the bitmap image to be traced
  if bitmap ~= nil then
    love.graphics.setColor( color.white )
    love.graphics.draw( bitmap, 0, 0, 0, 8, 8 ) -- rotation=0, scalex=8, scaley=8
  end

  -- render the ansiArt area
  drawArtCanvas(selected.textmode, game.bgcolorSelected)

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

  if love.keyboard.isDown("lshift") then
    -- draw screen 2 "drawmode"
    love.graphics.setFont(monoFont)
    love.graphics.setColor(color.white)
    love.graphics.print(screen2["drawmode"],640, 0)
  end

  -- draw brushes
  drawBrushes( 80, 0)

  -- draw cursor
  love.graphics.setColor( color.pulsingwhite )
  love.graphics.setLineWidth(1)
  love.graphics.rectangle( "line" , (game.cursorx-1)*8, (game.cursory-1)*8, FONT2X_WIDTH, FONT2X_HEIGHT)


  -- draw viewports (debug only)
  love.graphics.setColor(color.brightcyan)
  love.graphics.setLineWidth(1)
--  love.graphics.rectangle("line",0,0,640,480)
--  love.graphics.printf("Viewport 1", monoFont, 0, 480/2, 640,"center")
--  love.graphics.rectangle("line",640,0,640,480)
--  love.graphics.printf("Viewport 2", monoFont, 640, 480/2, 640,"center")
  -- viewport 3 and 4 use different fonts
  if game.os == "R36S" then
    love.graphics.setFont(monoFont)
  else
    love.graphics.setFont(monoFont2x)
  end
--  love.graphics.rectangle("line",0,480,640,240)
  -- love.graphics.printf("Viewport 3", monoFont, 0, (240/2)+480, 640,"center")
  for i = 1,29 do
    if game.os == "R36S" then
      love.graphics.printf("Test 3",monoFont,0, 480+((i-1)*FONT_HEIGHT),640,"left")
    else
      -- render for computers
    end
  end
--  love.graphics.rectangle("line",640,480,640,240)
  -- love.graphics.printf("Viewport 4", monoFont, 640, (240/2)+480, 640,"center")
  for i = 1,29 do
    if game.os == "R36S" then
      love.graphics.printf("Test 4",monoFont,640, 480+((i-1)*FONT_HEIGHT),640,"left")
    else
      -- render for computers
    end
  end

  -- draw cursor closeup
  drawCloseup()

  -- draw buttons
  drawButtons()

  -- draw pixelArt canvas
  love.graphics.draw(pixelArt, (game.canvasx+2)*FONT2X_WIDTH, 0)


  -- draw hover and click items during "play" mode
  -- draw hover shadow first
  if game.mode == "play" then
    love.graphics.setFont(monoFont)
    love.graphics.setColor(color.black)
    love.graphics.print(hover[game.mousex][game.mousey],(game.mousex*FONT2X_WIDTH)+2,((game.mousey+2)*FONT2X_HEIGHT)+2)
    -- draw hover text
    love.graphics.setColor(color.white)
    love.graphics.print(hover[game.mousex][game.mousey],game.mousex*FONT2X_WIDTH,(game.mousey+2)*FONT2X_HEIGHT)

    -- draw click - text message
    if game.message ~= "" then
      drawMessage( game.message, game.messageViewport )
    end
  end

  -- draw pointer
  love.graphics.setColor(color.white)
  love.graphics.draw(pointer, love.mouse.getX(), love.mouse.getY())


  if game.scene == "title" then
    -- draw full screens last
    love.graphics.setFont(monoFont)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(color[screen[1][3]])
    love.graphics.rectangle("fill",0,0,640,480) -- screen 1 background
    love.graphics.setColor(color[screen[1][4]])
    love.graphics.rectangle("fill",640,0,640,480) -- screen 2 background
    love.graphics.setColor(color.white)
    love.graphics.print(screen[1][1],0,0) -- screen 1 foreground
    love.graphics.print(screen[1][2],640,0) -- screen 2 foreground
  end

  -- draw Player after everything else
  drawPlayer()

--  overlayStats.draw() -- Should always be called last
end

function love.update(dt)
  -- Your game update here

  -- mouse button detections
  if love.mouse.isDown(1) and selected.textmode == 2 and game.mode == "edit" then
    if (game.mousex >= 1 and game.mousex <= game.canvasx) and (game.mousey >= 1 and game.mousey <= game.canvasy) then
      -- move game cursor
      game.cursorx = game.mousex
      game.cursory = game.mousey
      -- store selected in ansiArt
      ansiArt[game.mousey][(game.mousex*2)-1] = selected.color
      ansiArt[game.mousey][game.mousex*2] = selected.char
      -- store selected in pixelArt
      love.graphics.setCanvas(pixelArt)
      love.graphics.setFont(pixelFont)
      love.graphics.setColor(selected.color)
      love.graphics.print(selected.char, game.mousex, game.mousey)
      print("store in pixelArt.." .. game.mousex .. "," .. game.mousey)
      love.graphics.setCanvas()
    end
  end

  if love.mouse.isDown(1) and selected.textmode == 1 and game.mode == "edit" then
    if (game.mousex >= 1 and game.mousex <= game.canvasx) and (game.mousey >= 1 and game.mousey <= game.canvasy*2) then
      -- move game cursor
      game.cursorx = game.mousex
      game.cursory = game.mousey
      -- store selected in ansiArt
      ansiArt[math.ceil(game.mousey/2)][(game.mousex*2)-1] = selected.color
      ansiArt[math.ceil(game.mousey/2)][game.mousex*2] = selected.char
    end
  end

  -- game timers
  game.timeThisSession = game.timeThisSession + dt
  game.autosaveCooldown = game.autosaveCooldown - dt
  if game.autosaveCooldown < 0 then
    game.autosaveCooldown = 0
  end

  -- set pulsing effect color
  if math.floor(game.timeThisSession)%2 == 1 then
    -- odd seconds
    color.pulsingwhite = {(game.timeThisSession%1),(game.timeThisSession%1),(game.timeThisSession%1),1} -- using modulo for fading alpha channel
  else
    -- even seconds
    color.pulsingwhite = {1-(game.timeThisSession%1),1-(game.timeThisSession%1),1-(game.timeThisSession%1),1} -- using modulo for fading alpha channel
  end

  -- set mouse coords
  game.mousex = math.floor(love.mouse.getX()/8)+1 -- coords in font2x starting at 1x1
  game.mousey = math.floor(love.mouse.getY()/8)+1 -- coords in font2x starting at 1x1

  -- autosave every minute
  if math.ceil(game.timeThisSession)%60 == 0 and game.autosaveCooldown == 0 then
    -- every 60 seconds
    game.autosaveCooldown = 3 -- 3 seconds cooldown
    local files = love.filesystem.getDirectoryItems( "autosave" )
    saveData("autosave_"..(#files)..".xtui","autosave") -- running numbers for quicksaves
  end

  -- set statusbar
  game.statusbar = game.cursorx..","..game.cursory.." ("..game.mousex..","..game.mousey..") Time:"..math.floor(game.timeThisSession)
  if game.os ~= "R36S" then
    -- statusbar for all other platforms
    game.statusbar = game.statusbar .. " ["..game.os.."] | " .. game.mode .. " | Insert:" .. tostring(game.insertMode)
  else
    -- statusbar for R36S
    game.statusbar = game.statusbar .. " ["..game.os.."] L1:Change Color R1:Change Viewport"
  end

  overlayStats.update(dt) -- Should always be called last
end

function love.keypressed(key, scancode, isrepeat)
  print("key:"..key.." scancode:"..scancode.." isrepeat:"..tostring(isrepeat))
  if key == "escape" and love.system.getOS() ~= "Web" and game.insertMode == false then
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
      ansiArt[game.cursory][game.cursorx*2] = " "
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
    if key == "down" and game.chary < 17 then
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

    -- Start (return) to quicksave
    if key == "return" then
      local files = love.filesystem.getDirectoryItems( "quicksave" )
      saveData("quicksave_"..(#files)..".xtui","quicksave") -- running numbers for quicksaves
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

  else
    -- input for everything else (computers)

    -- arrow keys for moving Player when in game Play mode
    if game.mode == "play" then
      if key == "up" and game.playery > 1 then
        game.playery = game.playery - 2
      end
      if key == "down" and game.playery < 59 then -- 59+1 is the last y coord for screen 1
        game.playery = game.playery + 2
      end
      if key == "left" and game.playerx > 1 then
        game.playerx = game.playerx - 1
      end
      if key == "right" and game.playerx < 80 then -- 80 is the last x coord for screen 1
        game.playerx = game.playerx + 1
      end
    end

    -- checking game.insertMode for keyboard entry
    if game.insertMode == false then

      -- toggle game mode "play" , "edit"
      if (key == "m" or key == "M") then
        if game.mode == "play" then
          game.mode = "edit"
        else
          game.mode = "play"
        end
      end

      -- "[" / "]" to increase / decrease canvas size (x)
      if key == "[" and game.canvasx > 1 then
        game.canvasx = game.canvasx - 1
        pixelArt = love.graphics.newCanvas( game.canvasx, game.canvasy )
      end
      if key == "]" and game.canvasx < MAX_CANVAS_X then
        game.canvasx = game.canvasx + 1
        pixelArt = love.graphics.newCanvas( game.canvasx, game.canvasy )
      end

      -- ";" / "'" to increase / decrease canvas size (y)
      if key == ";" and game.canvasy > 1 then
        game.canvasy = game.canvasy - 1
        pixelArt = love.graphics.newCanvas( game.canvasx, game.canvasy )
      end
      if key == "'" and game.canvasy < MAX_CANVAS_Y then
        game.canvasy = game.canvasy + 1
        pixelArt = love.graphics.newCanvas( game.canvasx, game.canvasy )
      end

      -- "/" to toggle solid background color
      if key == "/" then
        game.bgcolorSelected = game.bgcolorSelected + 1
        if game.bgcolorSelected == 17 then
          game.bgcolorSelected = 0
        end
      end

      -- clear canvas
      if key == "c" then
        clearCanvas()
      end

      -- toggle textmode
      if key == "=" then
        if selected.textmode == 2 then
          selected.textmode = 1
        else
          selected.textmode = 2
        end
      end

      if key == "i" then
        game.insertMode = true
      end

    else
      -- game.insertMode == true
      if key == "escape" then
        game.insertMode = false
      else
        if #key == 1 then -- single char only
          ansiArt[game.cursory][(game.cursorx*2)-1] = selected.color
          ansiArt[game.cursory][game.cursorx*2] = key
        end
        if game.cursorx < game.canvasx then -- not at canvas edge yet, can move cursorx
          game.cursorx = game.cursorx + 1
        end

      end

    end -- game.insertMode check


    -- ralt (right option) to draw char
    if key == "ralt" then
      ansiArt[game.cursory][(game.cursorx*2)-1] = selected.color
      ansiArt[game.cursory][game.cursorx*2] = selected.char
    end
    -- backspace to delete char
    if key == "backspace" then
      if game.textmode == 2 then
        ansiArt[game.cursory][(game.cursorx*2)-1] = color.darkgrey
        ansiArt[game.cursory][game.cursorx*2] = " "
        if game.cursorx > 1 then
          -- not at the first column, shift game cursor backwards
          game.cursorx = game.cursorx - 1
        end
      else -- game.textmode == 1
        -- do deletion for monoFont spacing
      end
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
    if love.keyboard.isDown("rshift") and game.insertMode == false then
      -- w / s to select charTable row (game.chary)
      if key == "w" and game.chary > 1 then
        game.chary = game.chary - 1
        selected.char = charTable[game.chary][game.charx]
      end
      if key == "s" and game.chary < 17 then
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

  end

  -- enter to clear screen messages
  if key == "return" and game.message ~= "" then
    game.message = ""
  end

  if key == "f2" then
    game.scene = "draw"
    loadData()
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

  -- set game message based on click heatmap
  game.message = click[game.mousex][game.mousey]

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
--  if (game.mousex >= 1 and game.mousex <= game.canvasx) and (game.mousey >= 1 and game.mousey <= game.canvasy) then
--    ansiArt[game.mousey][(game.mousex*2)-1] = selected.color
--    ansiArt[game.mousey][game.mousex*2] = selected.char
--  end

end

function love.touchpressed(id, x, y, dx, dy, pressure)
  overlayStats.handleTouch(id, x, y, dx, dy, pressure) -- Should always be called last
end

--[[ To-Dos
  * export to PNG
  * auto-convert JPG PNG to XTUI
]]

--[[ Changelog
  2025-03-31
  * Implemented using XTUI images (prerendered) instead of code for the UI
  * Implemented color palette, click to select color and shade
  * Implemented ansiart size - 16x16
]]


