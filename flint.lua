version = 20261111.1800
-- Last edited: see version YYYYMMDD.HHMM
function clear()
	term.clear()
	term.setCursorPos(1, 1)
end

function main()
	clear()
	print("Make sure there is empty space above")
	print("Place gravel / clay into max 15 slots")
	print()
	print("Press Enter when ready")
	read()
	local data = {}
	for slot = 1, 16 do
		if turtle.getItemCount(slot) > 0 then
			turtle.select(slot)
			data = turtle.getItemDetail(slot)
			if data.name:find("gravel") ~= nil or data.name == "minecraft:clay" then
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
