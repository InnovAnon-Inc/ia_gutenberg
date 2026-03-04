-- ia_gutenberg/textures.lua
local modname = minetest.get_current_modname()
local log     = ia_util.get_logger(modname)

-- Helper: Creates a high-res "Cover Art" overlay using a 64x64 canvas
-- @param icon: The source texture (e.g. "default_mese_crystal.png")
-- @param color: Optional hex color to tint the icon
function ia_gutenberg.generate_cover_overlay(icon, color)
	if not icon or icon == "" then return "" end
	
	-- 1. Prepare the icon string (e.g., "default_stick.png^[colorize:#ff0000:120")
	local tex = icon
	if color then
		tex = tex .. "^[colorize:" .. color .. ":120"
	end

	-- 2. Escape Carets and Colons for the [combine sub-strings
	-- Minetest needs \^ and \: inside the combine parameter
	local function escape_for_combine(s)
		return s:gsub("%^", "\\^"):gsub(":", "\\:")
	end

	local escaped_icon = escape_for_combine(tex)
	local base_book    = "default_book.png"
	
	-- 3. Construct the [combine string
	-- We resize the base book to 64x64, then slap the 23x23 icon at 21,7
	-- Syntax: [combine:<w>x<h>:<x1>,<y1>=<tex1>:<x2>,<y2>=<tex2>
	local modifier = string.format(
		"[combine:64x64:0,0=%s\\^\\[resize\\:64x64:21,7=%s\\^\\[resize\\:23x23",
		base_book,
		escaped_icon
	)
	
	return modifier
end

-- Helper: Simple color tint (no combine needed here)
function ia_gutenberg.generate_tint_overlay(color, ratio)
	ratio = ratio or 80
	return "[colorize:" .. color .. ":" .. ratio
end

function ia_gutenberg.get_overlay_tex(base, def)
	-- If an icon is provided, the [combine] replaces the entire texture
	if def.icon then
		return ia_gutenberg.generate_cover_overlay(def.icon, def.icon_color)
	end

	-- Standard overlays (like colorize) get appended to the base book
	if not def.overlay or def.overlay == "" then return base end

	if def.overlay:sub(1,1) == "[" then
		return base .. "^" .. def.overlay
	end

	return base .. "^(" .. def.overlay .. ")"
end
