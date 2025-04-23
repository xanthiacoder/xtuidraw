-- xtuitest suite

local json = require("json")

local timeElapsed = 1

local ansiArt = json.decode(love.filesystem.read("sample.xtui"))

local canvasx = 0
local canvasy = 0
-- check for first instance of \n in table (first \n)
local loop = 2
while canvasx == 0 do
	if string.find(ansiArt[loop], "\n") ~= nil then
		canvasx = loop/2
	end
	loop = loop + 2
end
canvasy = #ansiArt/(canvasx*2)

local ascii = ""
for i = 1,127 do
	ascii = ascii .. string.char(i).. "("..i..") "
end

local animation = {}
for i = 1,41 do
  animation[i] = json.decode(love.filesystem.read("0-autosave_"..i..".xtui"))
end

function love.load()
  -- Your game load here
  dosFont   = love.graphics.newFont("Mx437_IBM_VGA_8x16.ttf", 16)
  dosFont2x = love.graphics.newFont("Mx437_IBM_VGA_8x16-2x.ttf", 8)


end

function love.draw()
  -- Your game draw here
  love.graphics.setFont (dosFont2x)
  if math.floor(timeElapsed) < 41 then
    love.graphics.print(animation[math.floor(timeElapsed)], 0, 0)
  end
--  love.graphics.print(canvasx.." , "..canvasy, 0, 300)
--  love.graphics.printf(ascii,dosFont, 0, 320, 1280, "left")
end

function love.update(dt)
  -- Your game update here
  timeElapsed = timeElapsed + (dt*2)

end

function love.keypressed(key)
  if key == "escape" and love.system.getOS() ~= "Web" then
    love.event.quit()
  else
	-- stuff
  end
end

function love.touchpressed(id, x, y, dx, dy, pressure)
	-- stuff
end
