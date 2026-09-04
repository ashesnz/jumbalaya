-- Runtime options and initial user settings for Jumbalaya.

local M = {}

M.flags = {
    SKIP_TITLE_SCREEN = false,
    ENABLE_PERF_OVERLAY = false,
    ATLAS_DEBUG_OVERLAY = false,
    NO_SAVING = false,
    MUTE = false,
    SOUND_THREAD = true,
    VIDEO_SETTINGS = true,
    VERBOSE = true,
    RUMBLE = nil,
    CRASH_REPORTS = false,
    NO_ERROR_HAND = false,
    SWAP_AB_PIPS = false,
    NO_ACHIEVEMENTS = false,
    DISP_USERNAME = nil,
    ENGLISH_ONLY = true,
    HIDE_BG = false,
    TROPHIES = false,
    PS4_PLAYSTATION_GLYPHS = false,
    LOCAL_CLIPBOARD = false,
    DISCORD = false,
}

function M.settings()
    return {
        COMP = {name = '', submission_name = nil, score = 0},
        DEMO = {total_uptime = 0, timed_CTA_shown = false, win_CTA_shown = false, quit_CTA_shown = false},
        ACHIEVEMENTS_EARNED = {}, crashreports = false,
        skip_title_screen = false, title_screen = true, language = 'en-us', screenshake = true,
        rumble = M.flags.RUMBLE, play_button_pos = 2, GAMESPEED = 1, paused = false,
        SOUND = {volume = 50, music_volume = 60, game_sounds_volume = 100},
        WINDOW = {
            screenmode = 'Windowed', vsync = 0, selected_display = 2,
            display_names = {'[NONE]'},
            DISPLAYS = {{name = '[NONE]', screen_res = {w = 1000, h = 650}}},
        },
        GRAPHICS = {texture_scaling = 2, shadows = 'On'},
    }
end

return M