local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()

-- Performance trial: render through Vulkan via WezTerm's WebGPU frontend.
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"

-- Match the live Alacritty font and geometry.
local regular_font = wezterm.font({
    family = "Cascadia Code PL",
    weight = "Regular",
    style = "Normal",
})
config.font = regular_font
config.font_rules = {
    -- WezTerm defaults dim text to ExtraLight. Keep Alacritty's regular
    -- stroke weight and let the terminal intensity control only the color.
    {
        intensity = "Half",
        italic = false,
        font = regular_font,
    },
    {
        intensity = "Half",
        italic = true,
        font = wezterm.font({
            family = "Cascadia Code PL",
            weight = "Regular",
            style = "Italic",
        }),
    },
}
config.font_size = 15.0
config.line_height = 1.0
config.cell_width = 1.0
config.initial_cols = 120
config.initial_rows = 40
config.window_padding = {
    left = 0,
    right = 0,
    top = 5,
    bottom = 0,
}

-- Exact Modus Vivendi palette imported by the live Alacritty config.
config.colors = {
    foreground = "#ffffff",
    background = "#000000",
    cursor_bg = "#f4f4f4",
    cursor_fg = "#ffffff",
    cursor_border = "#f4f4f4",
    selection_fg = "#ffffff",
    selection_bg = "#3c3c3c",
    ansi = {
        "#323232",
        "#ff8059",
        "#44bc44",
        "#d0bc00",
        "#2fafff",
        "#feacd0",
        "#00d3d0",
        "#ffffff",
    },
    brights = {
        "#535353",
        "#ef8b50",
        "#70b900",
        "#c0c530",
        "#79a8ff",
        "#f78fe7",
        "#4ae2f0",
        "#ffffff",
    },
    tab_bar = {
        background = "#000000",
    },
}

config.window_background_opacity = 0.90
config.bold_brightens_ansi_colors = false
config.notification_handling = "NeverShow"

-- Keep chrome out of the way until tabs are useful.
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = true
config.show_tab_index_in_tab_bar = true
config.show_new_tab_button_in_tab_bar = true
config.tab_max_width = 48

local tab_title_width = 24

wezterm.on("format-tab-title", function(tab)
    local title = tab.tab_title
    if not title or title == "" then
        title = tab.active_pane.title
    end

    title = wezterm.truncate_right(title, tab_title_width)
    return "  " .. wezterm.pad_right(title, tab_title_width) .. "  "
end)

-- Keep normal scrollback tight without intercepting tmux or other mouse-aware TUIs.
config.mouse_bindings = {
    {
        event = { Down = { streak = 1, button = { WheelUp = 1 } } },
        mods = "NONE",
        alt_screen = false,
        mouse_reporting = false,
        action = act.ScrollByLine(-3),
    },
    {
        event = { Down = { streak = 1, button = { WheelDown = 1 } } },
        mods = "NONE",
        alt_screen = false,
        mouse_reporting = false,
        action = act.ScrollByLine(3),
    },
}

-- Toshy maps macOS-style terminal shortcuts to these Linux combinations.
config.window_close_confirmation = "NeverPrompt"
config.keys = {
    {
        key = "t",
        mods = "CTRL|SHIFT",
        action = act.SpawnTab("CurrentPaneDomain"),
    },
    {
        key = "w",
        mods = "CTRL|SHIFT",
        action = act.CloseCurrentTab({ confirm = false }),
    },
}

for tab_number = 1, 9 do
    table.insert(config.keys, {
        key = tostring(tab_number),
        mods = "CTRL",
        action = act.ActivateTab(tab_number - 1),
    })
end

return config
