# Minecraft-Toolkit
Lua code for the ccTweaked mod. Take charge of your turtles!

This repository contains the Lua code for a number of useful Minecraft ccTweaked (Computercraft) utilities.
In the docs folder is a series of full colour pdf files explaining how to use the utilities.

The original tk.lua file has been deprecated, but is left here.
The new GUI based version can be found in the Computercraft-GUI repository

Use Updater.lua to copy all the files from here EXCEPT tk.lua and all libraries from Computercraft-GUI 

If you want to use the old version (tk.lua) copy it manually from here. You may have to delete tk3.lua if there is insufficient disk space:

1. Save and close your game
2. Delete any log files
3. Edit the fileName:
serverconfig/computercraft-server.toml
(in your game save folder)
4. Change line 2:
computer_space_limit = 1000000 to
computer_space_limit = 2000000 or more
5. Re-start the game
6. Run the updater again
