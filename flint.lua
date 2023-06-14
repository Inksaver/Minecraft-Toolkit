version = 20201031.1433
--[[
	https://pastebin.com/dBJ0frzj
]]
function clear()
	term.clear()
	term.setCursorPos(1, 1)
end

function main()
	clear()
	print("Make sure there is empty space above")
	print("Place gravel into max 15 slots")
	print()
	print("Press Enter when ready")
	read()
	local data = {}
	for slot = 1, 16 do
		if turtle.getItemCount(slot) > 0 then
			turtle.select(slot)
			data = turtle.getItemDetail(slot)
			if string.find(data.name, "gravel") ~= nil then
				while turtle.placeUp() do
					turtle.digUp()
				end
			end
		end
	end
	for slot = 16, 2, -1 do
		turtle.select(slot)
		turtle.transferTo(1)
	end
end

main()