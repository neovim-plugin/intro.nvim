local logo = require("intro.logo")

local M = {}

--- @param icon string | string[]
--- @return string[]
function M.get_intro(icon)
	if type(icon) == "string" then
		local first_part, rest = icon:match("([^%.]+)%.(.+)")
		return logo[first_part][rest]
	end
  return icon
end

--- @param lines string[]
--- @return integer
function M.get_longest_line_length(lines)
	-- Helper function to get the length of the longest line in the logo
	local max_length = 0
	for _, line in ipairs(lines) do
		local line_length = vim.fn.strdisplaywidth(line) -- Properly account for multibyte characters
		if line_length > max_length then
			max_length = line_length
		end
	end
	return max_length
end

return M
