local M = {}

local utils = require("intro.utils")

local PLUGIN_NAME = "intro"
local DEFAULT_COLOR = "#98c379"
local INTRO_LOGO = require("intro.logo").neovim.ansi_shadow
local INTRO_LOGO_HEIGHT = #INTRO_LOGO
local INTRO_LOGO_WIDTH = utils.get_longest_line_length(INTRO_LOGO)

local autocmd_group = vim.api.nvim_create_augroup(PLUGIN_NAME, {})
local highlight_ns_id = vim.api.nvim_create_namespace(PLUGIN_NAME)
local intro_buff = -1

local function unlock_buf(buf)
	vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
end

local function lock_buf(buf)
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

local function draw_intro(buf, logo_width, logo_height)
	local window = vim.fn.bufwinid(buf)
	local screen_width = vim.api.nvim_win_get_width(window)
	local screen_height = vim.api.nvim_win_get_height(window) - vim.opt.cmdheight:get()

	local start_col = math.floor((screen_width - logo_width) / 2)
	local start_row = math.floor((screen_height - logo_height) / 2)
	if start_col < 0 or start_row < 0 then
		return
	end

	local top_space = {}
	for _ = 1, start_row do
		table.insert(top_space, "")
	end

	local col_offset_spaces = {}
	for _ = 1, start_col do
		table.insert(col_offset_spaces, " ")
	end
	local col_offset = table.concat(col_offset_spaces, "")

	local adjusted_logo = {}
	for _, line in ipairs(INTRO_LOGO) do
		table.insert(adjusted_logo, col_offset .. line)
	end

	unlock_buf(buf)
	vim.api.nvim_buf_set_lines(buf, 1, 1, true, top_space)
	vim.api.nvim_buf_set_lines(buf, start_row, start_row, true, adjusted_logo)
	lock_buf(buf)

	vim.api.nvim_buf_set_extmark(buf, highlight_ns_id, start_row, start_col, {
		end_row = start_row + INTRO_LOGO_HEIGHT,
		hl_group = "Default",
	})
end

local function create_and_set_intro_buf(default_buff)
	local intro_buff = vim.api.nvim_create_buf("nobuflisted", "unlisted")
	vim.api.nvim_buf_set_name(intro_buff, PLUGIN_NAME)
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = intro_buff })
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = intro_buff })
	vim.api.nvim_set_option_value("filetype", "intro", { buf = intro_buff })
	vim.api.nvim_set_option_value("swapfile", false, { buf = intro_buff })

	vim.api.nvim_set_current_buf(intro_buff)
	vim.api.nvim_buf_delete(default_buff, { force = true })

	return intro_buff
end

local function set_options()
	vim.opt_local.number = false -- disable line numbers
	vim.opt_local.relativenumber = false -- disable relative line numbers
	vim.opt_local.list = false -- disable displaying whitespace
	vim.opt_local.fillchars = { eob = " " } -- do not display "~" on each new line
	vim.opt_local.colorcolumn = "0" -- disable colorcolumn
end

local function redraw()
	unlock_buf(intro_buff)
	vim.api.nvim_buf_set_lines(intro_buff, 0, -1, true, {})
	lock_buf(intro_buff)
	draw_intro(intro_buff, INTRO_LOGO_WIDTH, INTRO_LOGO_HEIGHT)
end

local function display_intro(payload)
	local is_dir = vim.fn.isdirectory(payload.file) == 1

	local default_buff = vim.api.nvim_get_current_buf()
	local default_buff_name = vim.api.nvim_buf_get_name(default_buff)
	local default_buff_filetype = vim.api.nvim_get_option_value("filetype", { buf = default_buff })
	if not is_dir and default_buff_name ~= "" and default_buff_filetype ~= PLUGIN_NAME then
		return
	end

	intro_buff = create_and_set_intro_buf(default_buff)
	set_options()

	draw_intro(intro_buff, INTRO_LOGO_WIDTH, INTRO_LOGO_HEIGHT)

	vim.api.nvim_create_autocmd({ "WinResized", "VimResized" }, {
		group = autocmd_group,
		buffer = intro_buff,
		callback = redraw,
	})
end

function M.setup(options)
	options = options or {}
	if options.logo then
		INTRO_LOGO = utils.get_intro(options.logo)
		INTRO_LOGO_HEIGHT = #INTRO_LOGO
		INTRO_LOGO_WIDTH = utils.get_longest_line_length(INTRO_LOGO)
	end

	vim.api.nvim_set_hl(highlight_ns_id, "Default", { fg = options.color or DEFAULT_COLOR })
	vim.api.nvim_set_hl_ns(highlight_ns_id)

	vim.api.nvim_create_autocmd("VimEnter", {
		group = autocmd_group,
		callback = display_intro,
		once = true,
	})
end

return M
