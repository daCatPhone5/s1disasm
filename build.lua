#!/usr/bin/env lua

local common = require "build_tools.lua.common"

-- Build the standalone Mega Drive Snake ROM instead of the Sonic disassembly.
common.build_rom_and_handle_failure("snake", "snake", "", "-p=FF", false, "https://github.com/daCatPhone5/s1disasm")
common.fix_header("snake.bin")
common.exit()
