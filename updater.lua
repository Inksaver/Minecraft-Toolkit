version = 20230824.1330
--[[
	https://pastebin.com/8qbeZevX
	Last edited: see version YYYYMMDD.HHMM
	use ' pastebin run 8qbeZevX ' in turtle terminal
	This will load useful tools and utilities
]]

local libDir = "lib"	-- set library directory name
local tmpDir = "tmp"	-- set temp folder name to 'tmp'
local root = "."
local files = {}		-- table of main files
local libFiles = {}		-- table of lib files (clsTurtle.lua and menu.lua)
local fileSizes = {}		-- table of current file sizes
local libFileSizes = {}	-- table of current library file sizes

local function clear()
	term.clear()
	term.setCursorPos(1, 1)
end

local function log(text)
	print(text)
	local h = fs.open("update.log", "a")
	h.writeLine(text)
	h.close()
end

local function checkLabel()
	if os.getComputerLabel() == nil then
		local noname = true
		while noname do
			clear()
			log("Give this turtle a name (no spaces)_")
			name = read()
			if name == '' then
				print("Just pressing Enter does not work")
			elseif string.find(name, ' ') ~= nil then
				print("NO SPACES!")
			else
				noname = false
			end
			if noname then
				sleep(2)
			end
		end
		
		os.setComputerLabel(name)
		log("Computer label set to "..os.getComputerLabel())
	end
end

local function checkFileExists(fileName, isLib)
	--[[ check in ./ or ./lib/ only (existing files) ]]
	if isLib then	-- checking a library file
		if fs.exists(fs.combine(libDir, fileName)) or fs.exists(fs.combine(libDir, fileName..".lua")) then
			return true
		end
	else
		if fs.exists(fileName) or fs.exists(fileName..".lua") then
			return true
		end
	end
	return false
end

local function createTempDir()
	if fs.exists(tmpDir) then
		log("./"..tmpDir.." already exists")
	else
		log("./"..tmpDir.." created")
		fs.makeDir(tmpDir)
	end
end

local function getFile(pastebin, fileName)
	--[[eg "UFvjc1bw", "tmp", "tk"
		use pastebin get to download file to tmp]]
	log("Fetching "..pastebin.." from Pastebin...")
	status, retval = pcall(shell.run, "pastebin", "get", pastebin, fs.combine(tmpDir, fileName))
	--if shell.run("pastebin", "get", pastebin, fs.combine(tmpDir, fileName)) then
	if status then
		log("Fetch error message "..tostring(retVal))
		log("Fetch success: "..tostring(status))
		log(fileName.." copied to ./"..tmpDir)
		return true
	else
		log(retval)
		log("failed to copy "..fileName.." from Pastebin")
		return false
	end
end

local function moveFile(isLib, fileName) -- movgee tmp copy to /lib/
	if isLib then
		fs.delete(fs.combine(libDir, fileName))
		sleep(1)
		fs.move(fs.combine(tmpDir, fileName), fs.combine(libDir, fileName)) -- move to lib/
		log("Moved: "..fileName.." from ./"..tmpDir.." to ./"..libDir.."/")
	else
		fs.delete(fileName)
		sleep(1)
		fs.move(fs.combine(tmpDir, fileName), fs.combine(root, fileName)) --move to root
		log("Moved: "..fileName.." from ./"..tmpDir.." to ./")
	end
end

local function getVersion(line, fileName)
	--[[ version = 20201223.1104 ]]
	local version = 0
	if line == nil then
		log("Error reading "..fileName)
	else
		line = line:gsub(" ", "") -- remove spaces
		local start = line:find("=")
		
		if start ~= nil then -- found
			version = tonumber(line:sub(start + 1))
		end
	end
	
	return version
end

local function isNewer(isLib, fileName)
	--[[ open files in tmp and .. or ../tmp to read file version ]]
	local old = nil										-- declare old file handle
	local new = nil										-- declare new file handle
	local move = true									-- set move flag to true
	local oldOpen, newOpen = false, false
	
	if isLib then										-- file is in lib/
		if checkFileExists(fileName, true) then
			old = fs.open(fs.combine(libDir, fileName), "r")
			move = false
			oldOpen = true
		end
	else												-- not a library file
		if checkFileExists(fileName, false) then
			old = fs.open(fileName, "r")
			move = false
			oldOpen = true
		end
	end
	
	if not move then 									-- previous version of file exists
		if fs.exists(fs.combine(tmpDir, fileName)) then	-- should exist in tmp folder
			new = fs.open(fs.combine(tmpDir, fileName), "r")
			newOpen = true
			local oldVer = getVersion(old.readLine(),fileName)
			log("Existing "..fileName.." version: "..oldVer)
			local newVer = getVersion(new.readLine(), fileName)
			log("Downloaded "..fileName.." version: "..newVer)
			if oldVer > 0 and newVer > 0 then
				if newVer > oldVer then
					move = true
				end
			elseif oldVer == 0 and newVer > 0 then
				move = true
			end
		end
	end
	
	if newOpen then
		new.close()
	end
	if oldOpen then
		old.close()
	end
	return move
end

local function process(key, value, isLib)
	local fileName = key..".lua"
	local count = 0
	local fileSize = 0
	local freeSpace = fs.getFreeSpace("./")
	log("\nAvailable space: "..freeSpace)
	log("Checking: "..fileName)
	if isLib then
		fileSize = libFileSizes[key]
	else
		fileSize = fileSizes[key]
	end
	log(fileName.." size:"..fileSize)
	log("Available space after fetch: "..freeSpace - fileSize)
	if freeSpace - fileSize < 50000 then
		clear()
		local message = 
[[Insufficient disk space for update.
1. Save your game
2. Edit the file:
serverconfig/computercraft-server.toml
(in your game save folder)
3. Change line 2:
computer_space_limit = 1000000 to
computer_space_limit = 2000000 or more
4. Re-start the game
5. Run the updater again
]]
		log(message)
		return -1
	else
		if getFile(value, fileName) then		-- download file to /tmp
			if isNewer(isLib, fileName) then
				moveFile(isLib, fileName) 		-- move tmp copy to /lib
				count = count  + 1
			else
				log(fileName.." is newer or unchanged")
			end
			sleep(1)
			log("Removing "..tmpDir.."/"..fileName)
			fs.delete(fs.combine(tmpDir, fileName))
			sleep(2)
		end
	end
	
	return count
end

local function addFileSize(isLib, tblName, key)
	local fileName = key..".lua"
	if checkFileExists(fileName, isLib) then
		if isLib then
			tblName[key] = fs.getSize(fs.combine(libDir, fileName))
			log("File size "..libDir.."/"..fileName..": "..tblName[key])
		else
			tblName[key] = fs.getSize(fileName)
			log("File size "..fileName..": "..tblName[key])
		end
	else
		tblName[key] = 0
		log("File size "..fileName.."\t: "..tblName[key].." (file not present)")
	end
	
end

function main()
	local doContinue = true							-- set continue flag						
	clear()
	checkLabel() 									-- make sure turtle label is set
	createTempDir() 								-- create /tmp/
	local tk = "UFvjc1bw"
	
	libFiles['clsTurtle'] 	= "tvfj90gK"
	libFiles['menu'] 		= "BhjbYsw4"
							
	--files["tk"] 		= "UFvjc1bw"
	files['go'] 		= "xQqK3VcK"
	files['lavaRefuel'] = "kFZsXu99"
	files['d'] 			= "i2MRYcsZ"
	files['u'] 			= "idtySGKX"
	files['b'] 			= "g7DjxRbr"
	files['f'] 			= "KXCakmNn"
	files['r'] 			= "DH6smTHb"
	files['l'] 			= "yWDKZpvj"
	files['p'] 			= "D25pg0QQ"
	files['x'] 			= 'Z9GBSM8e'
	files['flint'] 		= "dBJ0frzj"
	files['data'] 		= "fCKDc9Vi"
	
	local updated = 0
	local libUpdated = 0
	local h = fs.open("update.log", "w")
	h.writeLine('Update Log:')
	h.close()
	
	log("Checking file sizes:\n")

	for key, _ in pairs(libFiles) do
		addFileSize(true, libFileSizes, key)
	end	
	addFileSize(false, fileSizes, "tk")
	for key, _ in pairs(files) do
		addFileSize(false, fileSizes, key)
	end	
	local freeSpace = fs.getFreeSpace("./")
	log("Free space: "..freeSpace.."\n")
	clear()
	local updated, libUpdated = 0, 0
	updated = updated + process("tk", tk, false)			-- start with tk as may cause out of space error
	if updated >= 0 then
		for key,value in pairs(libFiles) do 					
			libUpdated = libUpdated + process(key, value, true)		-- download lib files from pastebin to tmp/
		end
		for key,value in pairs(files) do
			updated = updated + process(key, value, false)			-- download root files from pastebin to tmp/
		end	
		sleep(1)
		log("Attempting deletion of ./"..tmpDir)
		status, retval = pcall(fs.delete, tmpDir)
		if status then
			log("./"..tmpDir.." deleted")
		else
			log("Directory delete error message:\n "..tostring(retVal))
		end
		log("\nOperation Complete ")
		log(libUpdated.." library files updated")
		log(updated.." root files updated")
	end
	print("See update.log for details")
end

main()
