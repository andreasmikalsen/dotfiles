local wezterm = require 'wezterm'
local config = wezterm.config_builder()
local act = wezterm.action

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
        panes[index+1].pane:activate()
      else
        window:perform_action(act.ActivateTabRelative(1), pane)
      end
    elseif direction == "prev" then
      if index > 1 then
        panes[index-1].pane:activate()
      else
        window:perform_action(act.ActivateTabRelative(-1), pane)
      end
    end

    if is_zoomed then
      tab:set_zoomed(false)
      tab:set_zoomed(true)
    end
  end

  return wezterm.action_callback(callback)
end

-- ON UPDATE RIGHT STATUS
wezterm.on('update-status', function(window, pane)
  local mode = window:active_key_table()

  if mode == 'resize_mode' then
    window:set_right_status(
      wezterm.format {
        { Foreground = { Color = '#1e1e2e' } },
        { Background = { Color = '#f9e2af' } },
        { Text = '  RESIZE  ' },
      }
    )
  elseif mode == 'pane_mode' then
    window:set_right_status(
      wezterm.format {
        { Foreground = { Color = '#1e1e2e' } },
        { Background = { Color = '#89b4fa' } },
        { Text = '  PANE  ' },
      }
    )
  else
    window:set_right_status('')
  end
end)

config.initial_cols = 120
config.initial_rows = 28

config.font_size = 10

config.default_prog = { 'nu' }
-- config.enable_shell_integration = true

config.adjust_window_size_when_changing_font_size = false

-- color_scheme = 'termnial.sexy'
config.color_scheme = 'Catppuccin Mocha'
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.show_tabs_in_tab_bar = true
config.show_new_tab_button_in_tab_bar = false
config.font_size = 12.0
config.font = wezterm.font('FiraCode Nerd Font')
config.status_update_interval = 100

config.window_decorations = 'TITLE'
config.window_background_opacity = 1.00

local MOD_KEY = "ALT"

-- BELL
config.audible_bell = "Disabled"
config.visual_bell = {
  fade_in_duration_ms = 75,
  fade_out_duration_ms = 75,
  target = 'CursorColor',
}

config.animation_fps = 24
config.cursor_blink_ease_in = 'Linear'
config.cursor_blink_ease_out = 'Linear'
config.window_background_opacity = 1.0
config.macos_window_background_blur = 0

config.use_resize_increments = false
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true

config.tab_max_width = 200
config.window_padding = {
  left = '5px',
  right = '5px',
  top = '5px',
  bottom = 0,
}
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

local background_color = '#000000' -- same background as neovim
local active_fg = "#9f7e20";
local active_bg = background_color;
local hover_fg = "#93a1a1";
local hover_bg = background_color;
local inactive_fg = "#363a41";
local inactive_bg = background_color;

local colors = {
  background = background_color,

  tab_bar = {
    background = background_color,

    active_tab = {
      bg_color = active_bg,
      fg_color = active_fg,
      intensity = "Bold",
    },

    inactive_tab = {
      bg_color = inactive_bg,
      fg_color = inactive_fg,
    },

    inactive_tab_hover = {
      bg_color = hover_bg,
      fg_color = hover_fg,
    },

    new_tab = {
      bg_color = inactive_bg,
      fg_color = inactive_fg,
    },

    new_tab_hover = {
      bg_color = hover_bg,
      fg_color = hover_fg,
      italic = true,
    },
  },

  visual_bell = '#022020',
}


local keys = {
	{
		key = 'q',
		mods = MOD_KEY,
		action = wezterm.action.ToggleFullScreen,
	},
  {
    key = 'w',
    mods = MOD_KEY,
    action = act.Multiple {
      act.EmitEvent("keytable_pane_active"),
      act.ActivateKeyTable {
        name = 'pane_mode',
        one_shot = true,
        prevent_fallback = true,
      },
    },
  },
  {
    key = 'r',
    mods = MOD_KEY,
    action = act.Multiple {
      act.EmitEvent("keytable_resize_active"),
      act.ActivateKeyTable {
        name = 'resize_mode',
        one_shot = false,
        prevent_fallback = true,
      },
    }
  },
  { mods = MOD_KEY, key = 'j', action = ActivateThing('next') },
  { mods = MOD_KEY, key = 'k', action = ActivateThing('prev') },
  { mods = MOD_KEY, key = 'l', action = act.ActivateTabRelative(1) },
  { mods = MOD_KEY, key = 'h', action = act.ActivateTabRelative(-1) },
  { mods = MOD_KEY, key = 'f', action = act.TogglePaneZoomState },
  { mods = MOD_KEY, key = 'x', action = act.ShowTabNavigator },
  { mods = MOD_KEY.."|CTRL", key = 'j', action = act.MoveTabRelative(1) },
  { mods = MOD_KEY.."|CTRL", key = 'k', action = act.MoveTabRelative(-1) },
}

local mouse_bindings = {
	  -- Ctrl-click will open the link under the mouse cursor
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'CTRL',
    action = wezterm.action.OpenLinkAtMouseCursor,
  },
}

local key_tables = {

  pane_mode = {
    -- Cancel the mode by pressing escape or enter
    { key = 'Escape', action = 'PopKeyTable' },
    { key = 'Enter', action = 'PopKeyTable' },

    -- change panes
    { key = 'h', action = act.ActivatePaneDirection 'Left' },
    { key = 'l', action = act.ActivatePaneDirection 'Right' },
    { key = 'k', action = act.ActivatePaneDirection 'Up' },
    { key = 'j', action = act.ActivatePaneDirection 'Down' },
    { key = 'LeftArrow', action = act.ActivatePaneDirection 'Left' },
    { key = 'RightArrow', action = act.ActivatePaneDirection 'Right' },
    { key = 'UpArrow', action = act.ActivatePaneDirection 'Up' },
    { key = 'DownArrow', action = act.ActivatePaneDirection 'Down' },

    -- resize mode
    {
      key = 'r',
      action = act.ActivateKeyTable {
        name = 'resize_mode',
        one_shot = false,
        prevent_fallback = true,
      },
    },

    -- toggle fullscreen
    { key = 'f', action = act.TogglePaneZoomState },

    -- font size
    { key = '+', action = act.IncreaseFontSize },
    { key = '-', action = act.DecreaseFontSize },

    -- tabs
    { key = 't', action = act.SpawnTab 'CurrentPaneDomain' },
    { key = 'n', action = act.ActivateTabRelative(1) },
    { key = 'p', action = act.ActivateTabRelative(-1) },

    -- splits
    { key = 's', action = act.SplitVertical{ domain =  'CurrentPaneDomain' } },
    { key = 'v', action = act.SplitHorizontal{ domain =  'CurrentPaneDomain' } },

    -- close pane
    { key = 'x', action = act.CloseCurrentPane{ confirm =  true } },

  },


  resize_mode = {
    -- Cancel the mode by pressing escape or enter
    { key = 'Escape', action = 'PopKeyTable' },
    { key = 'Enter', action = 'PopKeyTable' },

    -- resize pane
    { key = 'h', action = act.AdjustPaneSize { 'Left', 1 } },
    { key = 'l', action = act.AdjustPaneSize { 'Right', 1 } },
    { key = 'k', action = act.AdjustPaneSize { 'Up', 1 } },
    { key = 'j', action = act.AdjustPaneSize { 'Down', 1 } },
    { key = 'LeftArrow', action = act.AdjustPaneSize { 'Left', 1 } },
    { key = 'RightArrow', action = act.AdjustPaneSize { 'Right', 1 } },
    { key = 'UpArrow', action = act.AdjustPaneSize { 'Up', 1 } },
    { key = 'DownArrow', action = act.AdjustPaneSize { 'Down', 1 } },

    -- move pane
    { key = 'h', mods = 'CTRL', action = act.RotatePanes 'CounterClockwise' },
    { key = 'l', mods = 'CTRL', action = act.RotatePanes 'Clockwise' },
  },

}

config.enable_wayland = true

config.key_tables = key_tables
config.keys = keys
config.colors = colors

return config
