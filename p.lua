version = 20250915.1500
-- Last edited: see version YYYYMMDD.HHMM
local usage = [[usage:
p   (place forward) or p 1
p u (place up) or p 0
p d (place down) or p 2
]]
args = {...}
local success = false
local direction = "forward"
local place = turtle.place
local inspect = turtle.inspect
local data = {}
local text = ""
local block = ""
local message = ""

term.clear()
term.setCursorPos(1,1)
if args[1] ~= nil then
	if args[1]:lower() == "h" then
		print(usage)
		print("Fuel Level: "..turtle.getFuelLevel())
		error()
	elseif args[1]:lower() == "u" or args[1] == "0" then
		direction = "up"
		place = turtle.placeUp
		inspect = turtle.inspectUp
	elseif args[1]:lower() == "d" or args[1] == "2" then
		direction = "down"
		place = turtle.placeDown
		inspect = turtle.inspectDown
	end
end
turtle.select(1)

while turtle.getItemCount(1) == 0 do
	print("Add an item to slot 1 and press Enter")
	read()
end
data = turtle.getItemDetail(1)
block = data.name
if block:find("sign") ~= nil then
	print("Type text for sign. + Enter")
	print("Use \\n between lines")
	text = read()
end
success = place(text)
if block == "minecraft:bucket" then
	message = "Water collected "
elseif block == "minecraft:water_bucket" then
	message = "Water placed "
end

if success then
	if message == "" then
		print(block.." placed: "..direction)
	else
		print(message..direction)
		success, data = inspect()
		if success then
			if data.name:find("water")~= nil then
				if data.state.level == 0 then
					print("Source block found "..direction)
				else
					print("Flowing water found "..direction.." level="..data.state.level)
				end
			end
		end
	end
else
	print(block.." NOT placed")
end
