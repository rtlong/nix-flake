local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- =============================================================================
-- Keybindings (matching iTerm setup)
-- =============================================================================

config.keys = {
  -- Vim-style pane navigation with CMD
  { key = 'h', mods = 'CMD', action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'CMD', action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'CMD', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'CMD', action = act.ActivatePaneDirection 'Right' },

  -- Pane navigation with CMD+OPT+Arrow (iTerm style)
  { key = 'UpArrow', mods = 'CMD|OPT', action = act.ActivatePaneDirection 'Up' },
  { key = 'DownArrow', mods = 'CMD|OPT', action = act.ActivatePaneDirection 'Down' },
  { key = 'LeftArrow', mods = 'CMD|OPT', action = act.ActivatePaneDirection 'Left' },
  { key = 'RightArrow', mods = 'CMD|OPT', action = act.ActivatePaneDirection 'Right' },

  -- Split panes (CMD+Home = vertical, CMD+End = horizontal from your config)
  { key = 'd', mods = 'CMD', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'd', mods = 'CMD|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },

  -- Tab navigation
  { key = 'Tab', mods = 'OPT', action = act.ActivateTabRelative(1) },
  { key = 'Tab', mods = 'OPT|SHIFT', action = act.ActivateTabRelative(-1) },
  { key = '[', mods = 'CMD|SHIFT', action = act.ActivateTabRelative(-1) },
  { key = ']', mods = 'CMD|SHIFT', action = act.ActivateTabRelative(1) },

  -- Tab management
  { key = 't', mods = 'CMD', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'CMD', action = act.CloseCurrentPane { confirm = true } },

  -- Window navigation (CMD+PageUp/PageDown)
  { key = 'PageUp', mods = 'CMD', action = act.ActivateWindowRelative(-1) },
  { key = 'PageDown', mods = 'CMD', action = act.ActivateWindowRelative(1) },
  { key = 'PageUp', mods = 'SHIFT', action = act.ActivateWindowRelative(-1) },
  { key = 'PageDown', mods = 'SHIFT', action = act.ActivateWindowRelative(1) },

  -- New window
  { key = 'n', mods = 'CMD', action = act.SpawnWindow },

  -- Font size (CMD only, disable CTRL variants so ^_ passes through to shell)
  { key = '=', mods = 'CMD', action = act.IncreaseFontSize },
  { key = '-', mods = 'CMD', action = act.DecreaseFontSize },
  { key = '0', mods = 'CMD', action = act.ResetFontSize },
  { key = '-', mods = 'CTRL', action = act.DisableDefaultAssignment },
  { key = '=', mods = 'CTRL', action = act.DisableDefaultAssignment },
  { key = '0', mods = 'CTRL', action = act.DisableDefaultAssignment },
  { key = '_', mods = 'CTRL', action = act.DisableDefaultAssignment },
  { key = '_', mods = 'CTRL|SHIFT', action = act.DisableDefaultAssignment },

  -- Clear screen (CMD+K like iTerm)
  { key = 'k', mods = 'CMD|SHIFT', action = act.ClearScrollback 'ScrollbackAndViewport' },

  -- Search
  { key = 'f', mods = 'CMD', action = act.Search 'CurrentSelectionOrEmptyString' },

  -- Copy/Paste
  { key = 'c', mods = 'CMD', action = act.CopyTo 'Clipboard' },
  { key = 'v', mods = 'CMD', action = act.PasteFrom 'Clipboard' },

  -- Fullscreen
  { key = 'Return', mods = 'CMD', action = act.ToggleFullScreen },

  -- Maximize pane (toggle)
  { key = 'z', mods = 'CMD', action = act.TogglePaneZoomState },
  { key = 'Return', mods = 'CMD|SHIFT', action = act.TogglePaneZoomState },

  -- Reload config
  { key = 'r', mods = 'CMD|SHIFT', action = act.ReloadConfiguration },

  -- Debug overlay
  { key = 'l', mods = 'CMD|SHIFT', action = act.ShowDebugOverlay },

  -- Command palette
  { key = 'p', mods = 'CMD|SHIFT', action = act.ActivateCommandPalette },
}

-- Direct tab access with CMD+number
for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = 'CMD',
    action = act.ActivateTab(i - 1),
  })
end

-- =============================================================================
-- Appearance
-- =============================================================================

-- Hide scrollbar and tab bar when only one tab (matching your iTerm HideScrollbar/HideTab)
config.enable_scroll_bar = false
config.hide_tab_bar_if_only_one_tab = true

-- Window padding
config.window_padding = {
  left = 2,
  right = 2,
  top = 2,
  bottom = 2,
}

-- =============================================================================
-- Behavior
-- =============================================================================

-- Don't adjust window size when changing font size (matching your iTerm setting)
config.adjust_window_size_when_changing_font_size = false

-- Scrollback
config.scrollback_lines = 10000

-- =============================================================================
-- Hyperlink Rules
-- =============================================================================

config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- Make file paths clickable (with optional :line:col suffix)
-- Use custom scheme so WezTerm doesn't handle it internally
-- Matches:
--   - Prefixed paths: ./relative, ../relative, /absolute, ~/home, ~user/home (extension optional)
--   - Unprefixed paths: must contain / AND file extension (e.g., src/main.rs)
-- Supports quoted/unquoted paths, paths in parentheses, stack traces with :in, etc.
table.insert(config.hyperlink_rules, {
  regex = [[(?<=^|[\s"'(])((?:(?:\.\.?|~[A-Za-z0-9_-]*)?/[^\s"'():,]+|[A-Za-z0-9_][A-Za-z0-9_/-]*/[^\s"'():,]*\.[A-Za-z0-9]+)(?::\d+(?::\d+)?)?)(?=[\s"'():,]|$)]],
  format = 'openineditor:$1',
})

-- Mouse bindings: CMD+click to open links, plain click just selects
config.mouse_bindings = {
  -- Plain click: select text, don't open links
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    action = act.CompleteSelection 'ClipboardAndPrimarySelection',
  },
  -- CMD+click: open link
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'CMD',
    action = act.OpenLinkAtMouseCursor,
  },
  -- Disable CMD+click down event to prevent interference
  {
    event = { Down = { streak = 1, button = 'Left' } },
    mods = 'CMD',
    action = act.Nop,
  },
}

-- Open openineditor: URIs by delegating to our Rust file handler
wezterm.on('open-uri', function(window, pane, uri)
  if uri:sub(1, 13) == 'openineditor:' then
    local path = uri:sub(14)

    -- Get the current working directory
    local cwd = pane:get_current_working_dir()
    local cwd_path = ''

    if cwd then
      -- cwd is a URL object, convert to string and get the file path
      local cwd_str = tostring(cwd)
      cwd_path = cwd.file_path or cwd_str:sub(8) -- strip file:// prefix if string
    end

    -- Delegate to the Rust file handler for all the complex logic
    -- The handler will: resolve paths, check existence, and open appropriately
    wezterm.run_child_process { '@fileHandler@', path, cwd_path }

    return false
  end
end)

-- =============================================================================
-- Font
-- =============================================================================

config.font = wezterm.font 'FiraCode Nerd Font Mono'
config.font_size = 13.0

return config
