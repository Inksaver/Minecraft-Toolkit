version = 20230430.1439
--[[
	https://pastebin.com/8qbeZevX
	Last edited: see version YYYYMMDD.HHMM
	use 'pastebin run 8qbeZevX' in turtle terminal
	This will load useful tools and utilities
]]
function clear()
	term.clear()
	term.setCursorPos(1, 1)
end

function checkLabel()
	if os.getComputerLabel() == nil then
		local noname = true
		while noname do
			clear()
			print("Type a name for this turtle (no spaces):_")
			name = read()
			if name == '' then
				print("Just pressing Enter does no work")
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
		print("Computer label set to "..os.getComputerLabel())
	end
end

function checkLibs(libDir, filename)
	local fileExists = false
	if libDir == '' then
		if fs.exists(filename) or fs.exists(filename..".lua") then
			fileExists = true
		end
	else
		if fs.exists(libDir) then
			if not fs.isDir(libDir) then
				fs.move(libDir, libDir.."Renamed")
				fs.makeDir(libDir)
			end
		else
			fs.makeDir(libDir)
		end
		if fs.exists(fs.combine(libDir, filename)) or fs.exists(fs.combine(libDir, filename..".lua")) then
			fileExists = true
		end
	end
	return fileExists
end

function checkFileExists(filename, isLib)
	-- check in root or lib/ only (existing files)
	local fileExists = false
	if isLib then
		if fs.exists(fs.combine("lib", filename)) or fs.exists(fs.combine("lib", filename..".lua")) then
			fileExists = true
		end
	else
		if fs.exists(filename) or fs.exists(filename..".lua") then
			fileExists = true
		end
	end
	return fileExists
end

function createTempDir(tempDir)
	if fs.exists(tempDir) then
		if not fs.exists(fs.combine(tempDir, "lib")) then
			fs.makeDir(fs.combine(tempDir, "lib"))
		end
	else
		fs.makeDir(tempDir)
		fs.makeDir(fs.combine(tempDir, "lib"))
	end
end

function createLibDir(libDir)
	if fs.exists(libDir) then
		if not fs.isDir(libDir) then --file called lib (unlikely...)
			fs.move(libDir, libDir.."Renamed") --lib -> libRenamed
			fs.makeDir(libDir)
		end
	else
		fs.makeDir(libDir)
	end
end

function getFile(files, isLib, fileName, saveAs, tmpDir, tmpLibDir)
	-- use pastebin get to download file (to libs folder if isLib)
	if saveAs == "" then
		saveAs = fileName -- use given filename if alternative not supplied
	end
	local saveDir = tmpDir
	if isLib then
		saveDir = tmpLibDir
	end
	success = true
	print("Downloading from Pastebin...")
	if shell.run("pastebin", "get", files[fileName], fs.combine(saveDir, saveAs..".lua")) then
		print(saveAs..".lua copied to "..saveDir)
	else
		print("failed to copy "..saveAs..".lua from Pastebin")
		success = false
	end
	
	return success
end

function moveFile(isLib, tmpDir, tmpLibDir, fileName) -- movgee tmp copy to /lib/
	local saveDir = tmpDir
	if isLib then
		saveDir = tmpLibDir
		fs.delete(fs.combine("lib", fileName))
		fs.move(fs.combine(saveDir, fileName), fs.combine("lib", fileName)) -- move to lib/
		print(fileName.." updated")
	else
		fs.delete(fileName)
		fs.move(fs.combine(saveDir, fileName), fs.combine("./", fileName)) --move to root
		print("/lib/"..fileName.." updated")
	end
end

function getVersion(line)
	-- version = 20201223.1104
	line = string.gsub(line, " ", "") -- remove spaces
	local start = string.find(line, "=")
	local version = 0
	if start ~= nil then -- found
		local dateString = string.sub(line, start + 1)
		version = tonumber(dateString)
	end
	return version
end

function isNewer(isLib, tmpDir, tmpLibDir, fileName)
	-- open files to read file versions
	local old = ""
	local saveDir = tmpDir
	local checkDir = ""
	local move = false
	if isLib then
		if checkFileExists(fileName, true) then
			old = fs.open(fs.combine("lib", fileName), "r")
			saveDir = tmpLibDir
			checkDir = "lib"
		else
			move = true
		end
	else
		if checkFileExists(fileName, false) then
			old = fs.open(fileName, "r")
		else
			move = true
		end
	end
	if not move then -- previous version of file exists
		if fs.exists(fs.combine(saveDir, fileName)) then
			local new = fs.open(fs.combine(saveDir, fileName), "r")
			local oldVer = getVersion(old.readLine())
			local newVer = getVersion(new.readLine())
			if oldVer ~= nil and newVer ~= nil then
				if newVer > oldVer then
					move = true
				end
			elseif oldVer == nil and newVer ~= nil then
				move = true
			end
			new.close()
			old.close()
		end
	end
	
	return move
end

function main()
	local doContinue = true
	local tmpDir = "tmp"
	local tmpLibDir = fs.combine(tmpDir, "lib")
	local libDir = "lib"
	checkLabel() -- make sure turtle label is set
	createTempDir(tmpDir) -- create /tmp/ and /tmp/lib/
	createLibDir(libDir) -- check/create lib dir
	local libFiles = {}
	libFiles['clsTurtle'] = "tvfj90gK"
	libFiles['menu'] = "BhjbYsw4"

	local files = {}
	files['go'] = "xQqK3VcK"
	files['lavaRefuel'] = "kFZsXu99"
	files['d'] = "i2MRYcsZ"
	files['u'] = "idtySGKX"
	files['b'] = "g7DjxRbr"
	files['f'] = "KXCakmNn"
	files['r'] = "DH6smTHb"
	files['l'] = "yWDKZpvj"
	files['p'] = "D25pg0QQ"
	files['x'] = 'Z9GBSM8e'
	files['tk'] = "UFvjc1bw"
	files['flint'] = "dBJ0frzj"
	files['data'] = "fCKDc9Vi"
	-- download into tmp folder
	for k,v in pairs(libFiles) do -- download from pastebin to tmp/lib/
		clear()
		--getFile(files, isLib, filename, saveAs, tmpDir, libDir) files is table of files with text index, isLib = library content, saveAs = filename
		getFile(libFiles, true, k, "", tmpDir, tmpLibDir) -- download file to /tmp/lib
		sleep(2)
	end
	for k,v in pairs(files) do -- download from pastebin to tmp/
		clear()
		getFile(files, false, k, "", tmpDir, tmpLibDir)
		sleep(2)
	end	
	-- check if tmp/lib/file exists in root
	local updated = 0
	for k,v in pairs(libFiles) do
		clear()
		local fileName = k..".lua"
		print("Checking: "..fileName)
		if isNewer(true, tmpDir, tmpLibDir, fileName) then
			moveFile(true, tmpDir, tmpLibDir, fileName) -- move tmp copy to /lib/#
			updated = updated  + 1
		else
			print(fileName.." is newer or unchanged")
			fs.delete(fs.combine(tmpLibDir, fileName))
		end
		sleep(2)
	end
	for k,v in pairs(files) do
		clear()
		local fileName = k..".lua"
		print("Checking: "..fileName)
		if isNewer(false, tmpDir, tmpLibDir, fileName) then
			moveFile(false, tmpDir, tmpLibDir, fileName) -- move tmp copy to /lib/
			updated = updated  + 1
		else
			print(fileName.." is newer or unchanged")
			fs.delete(fs.combine(tmpDir, fileName))
		end
	end	
	print("Removing temporary files")
	local status, retval = pcall(fs.delete, tmpLibDir)
	if not status then
		print(retval)
	end
	status, retval = pcall(fs.delete, tmpDir)
	if not status then
		print(retval)
	end
	print("\nOperation Complete "..updated.." files updated")
	
end

main()