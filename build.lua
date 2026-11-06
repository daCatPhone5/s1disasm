#!/usr/bin/env lua

local common = require "build_tools.lua.common"

-- Assemble the standalone Mega Drive Snake game (no Sonic source/data required).
common.build_rom_and_handle_failure(
	"snake",
	"snake",
	"",
	"-p=FF",
	false,
	"https://github.com/daCatPhone5/s1disasm"
)

common.fix_header("snake.bin")
common.exit()
