local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

-- =============================================================================
-- Helpers
-- =============================================================================

-- Move through panes first, then continue through tabs when reaching the edge.
-- Preserve pane zoom state while navigating.
local function ActivateThing(direction)
	local function callback(window, pane)
		local tab = window:active_tab()
		local panes = tab:panes_with_info()

		local index = 1
		local is_zoomed = false
		for i, p in ipairs(panes) do
			if p.is_active then
				index = i
				is_zoomed = p.is_zoomed
				break
			end
		end

		if direction == "next" then
			if index < #panes then
				panes[index + 1].pane:activate()
			end
		elseif direction == "prev" then
			if index > 1 then
				panes[index - 1].pane:activate()
			end
		end

		-- if direction == "next" then
		--   if index < #panes then
		--     panes[index+1].pane:activate()
		--   else
		--     window:perform_action(act.ActivateTabRelative(1), pane)
		--   end
		-- elseif direction == "prev" then
		--   if index > 1 then
		--     panes[index-1].pane:activate()
		--   else
		--     window:perform_action(act.ActivateTabRelative(-1), pane)
		--   end
		-- end

		if is_zoomed then
			tab:set_zoomed(false)
			tab:set_zoomed(true)
		end
	end

	return wezterm.action_callback(callback)
end

-- =============================================================================
-- Status
-- =============================================================================

-- Show the currently active key table in the right side of the tab bar.
wezterm.on("update-status", function(window, pane)
	local mode = window:active_key_table()

	if mode == "resize_mode" then
		window:set_right_status(wezterm.format({
			{ Foreground = { Color = "#1e1e2e" } },
			{ Background = { Color = "#f9e2af" } },
			{ Text = "  RESIZE  " },
		}))
	elseif mode == "pane_mode" then
		window:set_right_status(wezterm.format({
			{ Foreground = { Color = "#1e1e2e" } },
			{ Background = { Color = "#89b4fa" } },
			{ Text = "  PANE  " },
		}))
	else
		window:set_right_status("")
	end
end)

-- =============================================================================
-- General
-- =============================================================================

config.default_prog = { "nu" }

config.initial_cols = 120
config.initial_rows = 28

config.adjust_window_size_when_changing_font_size = false
config.use_resize_increments = false

config.status_update_interval = 500

-- =============================================================================
-- FONT
-- =============================================================================

config.font_size = 12.0
config.font = wezterm.font("FiraCode Nerd Font")

-- =============================================================================
-- Window
-- =============================================================================

config.window_decorations = "TITLE | RESIZE"
config.window_background_opacity = 1.00

config.window_padding = {
	left = "5px",
	right = "5px",
	top = "5px",
	bottom = 0,
}

-- =============================================================================
-- Tab bar
-- =============================================================================

config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.show_tabs_in_tab_bar = true
config.show_new_tab_button_in_tab_bar = false

config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.tab_max_width = 32

-- =============================================================================
-- Appearance
-- =============================================================================

config.color_scheme = "Catppuccin Mocha"

config.inactive_pane_hsb = {
	hue = 1.0,
	saturation = 1.0,
	brightness = 0.4,
}

config.foreground_text_hsb = {
	hue = 1.0,
	saturation = 1.0,
	brightness = 1.0,
}

-- Custom tab bar colors.
local background_color = "#000000" -- Same background as Neovim
local active_fg = "#9f7e20"
local hover_fg = "#93a1a1"
local inactive_fg = "#363a41"

local colors = {
	background = background_color,

	tab_bar = {
		background = background_color,

		active_tab = {
			bg_color = background_color,
			fg_color = active_fg,
			intensity = "Bold",
		},

		inactive_tab = {
			bg_color = background_color,
			fg_color = inactive_fg,
		},

		inactive_tab_hover = {
			bg_color = background_color,
			fg_color = hover_fg,
		},

		new_tab = {
			bg_color = background_color,
			fg_color = inactive_fg,
		},

		new_tab_hover = {
			bg_color = background_color,
			fg_color = hover_fg,
			italic = true,
		},
	},

	visual_bell = "#022020",
}

-- =============================================================================
-- Bell and cursor
-- =============================================================================

config.audible_bell = "Disabled"

config.visual_bell = {
	fade_in_duration_ms = 75,
	fade_out_duration_ms = 75,
	target = "CursorColor",
}

config.animation_fps = 24
config.cursor_blink_ease_in = "Linear"
config.cursor_blink_ease_out = "Linear"

-- =============================================================================
-- Key bindings
-- =============================================================================

local MOD_KEY = "ALT"

local keys = {
	-- Window
	{
		key = "q",
		mods = MOD_KEY,
		action = act.ToggleFullScreen,
	},

	-- Key tables
	{
		key = "w",
		mods = MOD_KEY,
		action = act.ActivateKeyTable({
			name = "pane_mode",
			one_shot = true,
			prevent_fallback = true,
		}),
	},
	{
		key = "r",
		mods = MOD_KEY,
		action = act.ActivateKeyTable({
			name = "resize_mode",
			one_shot = false,
			prevent_fallback = true,
		}),
	},

	-- Pane / tab navigation
	{ key = "j", mods = MOD_KEY, action = ActivateThing("next") },
	{ key = "k", mods = MOD_KEY, action = ActivateThing("prev") },
	{ key = "l", mods = MOD_KEY, action = act.ActivateTabRelative(1) },
	{ key = "h", mods = MOD_KEY, action = act.ActivateTabRelative(-1) },

	-- Pane
	{ key = "f", mods = MOD_KEY, action = act.TogglePaneZoomState },

	-- Tabs
	{ key = "x", mods = MOD_KEY, action = act.ShowTabNavigator },
	{ key = "j", mods = MOD_KEY .. "|CTRL", action = act.MoveTabRelative(1) },
	{ key = "k", mods = MOD_KEY .. "|CTRL", action = act.MoveTabRelative(-1) },
}

-- =============================================================================
-- Mouse bindings
-- =============================================================================

local mouse_bindings = {
	-- Ctrl-click opens the link under the mouse cursor.
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CTRL",
		action = act.OpenLinkAtMouseCursor,
	},
}

-- =============================================================================
-- Key tables
-- =============================================================================

local key_tables = {
	-- ---------------------------------------------------------------------------
	-- Pane mode
	-- ---------------------------------------------------------------------------

	pane_mode = {
		-- Exit mode
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter", action = "PopKeyTable" },

		-- Navigate panes
		{ key = "h", action = act.ActivatePaneDirection("Left") },
		{ key = "j", action = act.ActivatePaneDirection("Down") },
		{ key = "k", action = act.ActivatePaneDirection("Up") },
		{ key = "l", action = act.ActivatePaneDirection("Right") },

		{ key = "LeftArrow", action = act.ActivatePaneDirection("Left") },
		{ key = "DownArrow", action = act.ActivatePaneDirection("Down") },
		{ key = "UpArrow", action = act.ActivatePaneDirection("Up") },
		{ key = "RightArrow", action = act.ActivatePaneDirection("Right") },

		-- Enter resize mode
		{
			key = "r",
			action = act.ActivateKeyTable({
				name = "resize_mode",
				one_shot = false,
				prevent_fallback = true,
			}),
		},

		-- Pane
		{ key = "f", action = act.TogglePaneZoomState },
		{ key = "x", action = act.CloseCurrentPane({ confirm = true }) },

		-- Font size
		{ key = "+", action = act.IncreaseFontSize },
		{ key = "-", action = act.DecreaseFontSize },

		-- Tabs
		{ key = "t", action = act.SpawnTab("CurrentPaneDomain") },
		{ key = "n", action = act.ActivateTabRelative(1) },
		{ key = "p", action = act.ActivateTabRelative(-1) },

		-- Splits
		{ key = "s", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ key = "v", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	},

	-- ---------------------------------------------------------------------------
	-- Resize mode
	-- ---------------------------------------------------------------------------

	resize_mode = {
		-- Exit mode
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter", action = "PopKeyTable" },

		-- Resize panes
		{ key = "h", action = act.AdjustPaneSize({ "Left", 1 }) },
		{ key = "j", action = act.AdjustPaneSize({ "Down", 1 }) },
		{ key = "k", action = act.AdjustPaneSize({ "Up", 1 }) },
		{ key = "l", action = act.AdjustPaneSize({ "Right", 1 }) },

		{ key = "LeftArrow", action = act.AdjustPaneSize({ "Left", 1 }) },
		{ key = "DownArrow", action = act.AdjustPaneSize({ "Down", 1 }) },
		{ key = "UpArrow", action = act.AdjustPaneSize({ "Up", 1 }) },
		{ key = "RightArrow", action = act.AdjustPaneSize({ "Right", 1 }) },

		-- Move panes
		{ key = "h", mods = "CTRL", action = act.RotatePanes("CounterClockwise") },
		{ key = "l", mods = "CTRL", action = act.RotatePanes("Clockwise") },
	},
}

-- =============================================================================
-- Apply configuration
-- =============================================================================

config.colors = colors
config.keys = keys
config.mouse_bindings = mouse_bindings
config.key_tables = key_tables

return config
