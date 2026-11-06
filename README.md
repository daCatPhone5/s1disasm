# Mega Drive Snake

This branch now builds a small, standalone Snake game for the Sega Mega Drive / Genesis instead of building the Sonic 1 ROM. The old Sonic disassembly and assets are still present in the repository, but are no longer part of the build.

## Build

Run `build.bat` on Windows, or run `lua build.lua` where Lua is installed. The build uses the AS assembler and `p2bin` already included under `build_tools/` and produces `snake.bin`.

## Controls

Use the controller D-pad to steer. Press Start to restart after a crash.

The game uses the Mega Drive's 68000 CPU, VDP tile planes, and controller port directly; it does not use Sonic 1 code or graphics.
