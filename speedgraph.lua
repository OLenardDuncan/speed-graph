local frame_num = 150
local size = 150

local w, h = get_window_size()
local vel_hist = {}
function speedgraph_reset()
	for i = 0, (frame_num - 1) do
		vel_hist[i] = {0, 0}
	end
end

local function get(n, ...)
	return arg[n]
end

local function saveSettings()
	local settings = io.open("speedgraph.cfg", "w")
	if settings ~= nil then
		settings:write("frames: "..frame_num.."\nsize: "..size)
		settings:close()
	else echo("Couldn't save settings to speedgraph.cfg") end
end

local settings = io.open("speedgraph.cfg", "r")
if settings ~= nil then
	local line = settings:read("*l")
	if line ~= nil then frame_num = tonumber(line:sub(get(2, line:find("frames: "))+1)) or frame_num end
	line = settings:read("*l")
	if line ~= nil then size = tonumber(line:sub(get(2, line:find("size: "))+1)) or size end
	settings:close()
end

speedgraph_reset()

local frame = 0

add_hook("enter_frame", "get_vel",
function()
	frame = get_world_state().match_frame % frame_num
	for i = 0, 1 do
		local vel = 0
		for j = 0, 20 do
			local x, y, z = get_body_linear_vel(i, j)
			vel = math.max(vel, math.sqrt((x ^ 2) + (y ^ 2) + (z ^ 2)))
		end
		vel_hist[frame][i + 1] = vel
	end
end
)

add_hook("draw2d", "draw_graph",
function()
	for i = 2, (frame_num - 1) do
		local x = w - size * (1 - i / frame_num)
		local draw = i-1-frame >= 0 and i-1-frame <= 3
		local hmult = size/100
		set_color(0, 0, 1, 1)
		draw_line(x, h - hmult * vel_hist[i-1][2] * 3, x + (draw and 0 or size/frame_num), h - hmult * vel_hist[draw and i-1 or i][2] * 3, 2)
		set_color(1, 0, 0, 1)
		draw_line(x, h - hmult * vel_hist[i-1][1] * 3, x + (draw and 0 or size/frame_num), h - hmult * vel_hist[draw and i-1 or i][1] * 3, 2)
	end
end
)

add_hook("new_game", "test", reset)
add_hook("new_mp_game", "test", reset)
add_hook("command", "set_stuff",
function(cmd)
	if cmd:sub(1, 4) == "size" then
		local newSize = tonumber(cmd:sub(6))
		if newSize ~= nil then
			if newSize > 0 then
				size = newSize
				saveSettings()
			else echo("size must be positive")
			end
		else echo("usage: /size widthInPixels")
		end
		return 1
	elseif cmd:sub(1, 6) == "frames" then
		local newFrames = tonumber(cmd:sub(8))
		if newFrames ~= nil then
			if newFrames > 0 then
				frame_num = newFrames
				saveSettings()
				speedgraph_reset()
			else echo("frame number must be positive")
			end
		else echo("usage: /frames number")
		end
		return 1
	elseif cmd == "graphhelp" then
		echo("/size number (default: 150)")
		echo("/frames number (notice: this will reset your graph! default: 150)")
		return 1
	end
end
)