-- @description DSG_Cartridge load sample to active instance
-- @author Alexandr Sakhnov
-- @version 1.3.1
-- @changelog
--   v1.3.1
--   - Stop Media Explorer audition when replacing the sample (no more lingering preview)
--   v1.3.0
--   - Locate Media Explorer via reaper.OpenMediaExplorer (works on any REAPER locale)
--   - Fix "File not found" when Media Explorer hides the file extension: scan folder by base name
--   - Use reaper.file_exists for the existence check (replaces io.open probe)
--   v1.2.1
--   - Fixed Linux config path (~/.config instead of ~/.local)
--   v1.2.0
--   - Removed auto-copy to project folder (plugin now embeds sample data in state)
--   v1.1.0
--   - Apply Media Explorer preview selection as trim region
--   - Improved database and search results path resolution
--   - Localization support (Russian Media Explorer window name)
--   v1.0.0
--   - Initial release
-- @link Website https://dsgdnb.com
-- @link Repository https://github.com/sakhnovkrg/DSG_ReaScripts
-- @about
--   # Cartridge - Load sample to active instance
--
--   Loads the selected file from Media Explorer into the currently
--   focused Cartridge instance. Similar to ReaSamplOmatic's
--   "Reuse Active Sample player" action.
--
--   **Usage:**
--   1. Open Cartridge on any track
--   2. Select a file in Media Explorer
--   3. Run this script
--
--   **Requirements:**
--   - Cartridge 0.3.1+
--   - js_ReaScriptAPI extension

local PLUGIN_NAME = "Cartridge"

-- Returns the Media Explorer hwnd; opens the window if it isn't already shown.
-- Locale-agnostic, replaces the old hardcoded window-name lookup.
local function findMediaExplorer()
    return reaper.OpenMediaExplorer("", false)
end

local function is_absolute_path(s)
    return s and (s:match("^%a:[\\/]") or s:match("^/")) and #s > 1
end

local function file_exists(path)
    return path and reaper.file_exists(path)
end

local function basename_without_ext(name)
    return name and (name:match("(.+)%.[^.]+$") or name)
end

-- Resolve the on-disk path when Media Explorer omits the file extension
-- (e.g. "Show file extensions" disabled, or DB display name without ext).
local function resolve_file_in_dir(dir, filename)
    if not dir or dir == "" or not filename or filename == "" then return nil end
    if dir:sub(-1) ~= "/" and dir:sub(-1) ~= "\\" then dir = dir .. "/" end

    local candidate = dir .. filename
    if file_exists(candidate) then return candidate end

    local target = basename_without_ext(filename):lower()
    local audio_ext = { wav = true, wave = true, flac = true, aif = true,
                        aiff = true, mp3 = true, ogg = true }

    local first_match
    local i = 0
    while true do
        local entry = reaper.EnumerateFiles(dir, i)
        if not entry then break end

        if basename_without_ext(entry):lower() == target then
            local path = dir .. entry
            local ext = entry:match("%.([^.]+)$")
            if ext and audio_ext[ext:lower()] and file_exists(path) then return path end
            if not first_match and file_exists(path) then first_match = path end
        end
        i = i + 1
    end

    return first_match
end

local function get_path_from_list_item(list, idx)
    for col = 0, 4 do
        local s = reaper.JS_ListView_GetItemText(list, idx, col)
        if is_absolute_path(s) then return s end
    end
    return nil
end

local function getMediaExplorerFile()
    local hwnd = findMediaExplorer()
    if not hwnd then return nil end

    local list = reaper.JS_Window_FindChildByID(hwnd, 1001)
    if not list or reaper.JS_ListView_GetSelectedCount(list) == 0 then return nil end

    local idx = reaper.JS_ListView_GetFocusedItem(list)
    if idx < 0 then
        for i = 0, reaper.JS_ListView_GetItemCount(list) - 1 do
            if reaper.JS_ListView_GetItemState(list, i) & 0x2 ~= 0 then
                idx = i
                break
            end
        end
    end

    local filename = reaper.JS_ListView_GetItemText(list, idx, 0)

    -- Check if any column already has an absolute path
    if is_absolute_path(filename) then return filename end
    local path_any_col = get_path_from_list_item(list, idx)
    if path_any_col then return path_any_col end

    local dir = ""
    local edit = reaper.JS_Window_FindChildByID(hwnd, 1002)
    if edit then dir = reaper.JS_Window_GetTitle(edit) or "" end
    if dir == "" then
        local combo = reaper.JS_Window_FindChildByID(hwnd, 1000)
        if combo then dir = reaper.JS_Window_GetTitle(combo) or "" end
    end

    -- Database or search results: force "Show full path" and read from all columns
    local looks_like_folder = dir:match("[\\/]") and not dir:match("^DB") and not dir:match("^Search")
    if not looks_like_folder or dir == "" then
        reaper.JS_WindowMessage_Send(hwnd, "WM_COMMAND", 42026, 0, 0, 0)
        local full_path = get_path_from_list_item(list, idx)
        reaper.JS_WindowMessage_Send(hwnd, "WM_COMMAND", 42026, 0, 0, 0)
        if full_path then return full_path end
    end

    -- Normal folder: combine path + filename, falling back to a folder scan
    -- when the Media Explorer item text omits the file extension.
    if is_absolute_path(filename) then return filename end
    if dir == "" then return nil end
    if dir:sub(-1) ~= "/" and dir:sub(-1) ~= "\\" then dir = dir .. "/" end
    return resolve_file_in_dir(dir, filename) or dir .. filename
end

local function triggerLoad(track, fx_idx, sample_path)
    local appdata = os.getenv("APPDATA")
    if not appdata then
        local home = os.getenv("HOME")
        if reaper.GetOS():match("OSX") or reaper.GetOS():match("macOS") then
            appdata = home .. "/Library/Application Support"
        else
            -- Linux
            appdata = home .. "/.config"
        end
    end
    local dir = appdata .. "/Cartridge"
    reaper.RecursiveCreateDirectory(dir, 0)

    local f = io.open(dir .. "/pending_load.txt", "w")
    if f then
        f:write(sample_path)
        f:close()
    end

    for i = 0, reaper.TrackFX_GetNumParams(track, fx_idx) - 1 do
        local _, name = reaper.TrackFX_GetParamName(track, fx_idx, i, "")
        if name == "Load Trigger" then
            local val = reaper.TrackFX_GetParam(track, fx_idx, i)
            reaper.TrackFX_SetParam(track, fx_idx, i, val < 0.5 and 1 or 0)
            break
        end
    end
end

-- Stop Media Explorer preview before replacing the sample.
-- Action 1009 lives in the Media Explorer section (32063) and isn't reachable
-- via Main_OnCommand; per Cockos forum, posting WM_COMMAND straight to the MX
-- HWND is the canonical way and works without a defer() trick.
local MX_STOP_ACTION_ID = 1009

local function stopMediaExplorerPreview()
    local hwnd = findMediaExplorer()
    if hwnd then
        reaper.JS_WindowMessage_Send(hwnd, "WM_COMMAND", MX_STOP_ACTION_ID, 0, 0, 0)
    end
end

local function getMediaExplorerSelection(sample_path)
    if not reaper.MediaExplorerGetLastPlayedFileInfo then return nil, nil end

    local ok, out_path, _, sel_start, sel_end = reaper.MediaExplorerGetLastPlayedFileInfo("", 0, 0, 0, 0, 0, 0, 0, 0, "", 0)
    if not ok or not out_path or out_path == "" then return nil, nil end

    -- Normalize paths for comparison
    local norm_a = sample_path:gsub("\\", "/"):lower()
    local norm_b = out_path:gsub("\\", "/"):lower()
    if norm_a ~= norm_b then return nil, nil end

    if type(sel_start) ~= "number" or type(sel_end) ~= "number" then return nil, nil end
    if sel_start < 0 or sel_start >= sel_end or sel_end > 1 then return nil, nil end

    return sel_start, sel_end
end

local function applySelectionAsTrim(track, fx_idx, sel_start, sel_end)
    if not sel_start or not sel_end then return end

    for i = 0, reaper.TrackFX_GetNumParams(track, fx_idx) - 1 do
        local _, name = reaper.TrackFX_GetParamName(track, fx_idx, i, "")
        if name == "Sample Start" then
            reaper.TrackFX_SetParam(track, fx_idx, i, sel_start)
        elseif name == "Sample End" then
            reaper.TrackFX_SetParam(track, fx_idx, i, sel_end)
        elseif name == "Zoom To Fit" then
            local val = reaper.TrackFX_GetParam(track, fx_idx, i)
            reaper.TrackFX_SetParam(track, fx_idx, i, val < 0.5 and 1 or 0)
        end
    end
end

local function isCartridge(track, fx_idx)
    local _, fx_name = reaper.TrackFX_GetFXName(track, fx_idx, "")
    return fx_name:lower():find("cartridge") ~= nil
end

local function findFocusedCartridge()
    -- Check all tracks for focused (open) Cartridge
    for t = 0, reaper.CountTracks(0) - 1 do
        local track = reaper.GetTrack(0, t)
        for fx = 0, reaper.TrackFX_GetCount(track) - 1 do
            if reaper.TrackFX_GetOpen(track, fx) and isCartridge(track, fx) then
                return track, fx
            end
        end
    end

    -- Check master track
    local master = reaper.GetMasterTrack(0)
    for fx = 0, reaper.TrackFX_GetCount(master) - 1 do
        if reaper.TrackFX_GetOpen(master, fx) and isCartridge(master, fx) then
            return master, fx
        end
    end

    return nil, nil
end

local function ensureJS_API()
    if reaper.JS_Window_Find then return true end

    if not reaper.ReaPack_BrowsePackages then
        reaper.ShowMessageBox(
            "This script requires js_ReaScriptAPI extension.\n\n" ..
            "Please install ReaPack first, then run this script again.\n" ..
            "https://reapack.com",
            "Missing Extension", 0)
        return false
    end

    local response = reaper.ShowMessageBox(
        "This script requires js_ReaScriptAPI extension.\n\n" ..
        "Would you like to open ReaPack to install it?\n\n" ..
        "(After installing, restart REAPER and run the script again)",
        "Install js_ReaScriptAPI?", 4)

    if response == 6 then
        reaper.ReaPack_BrowsePackages("js_ReaScriptAPI")
    end
    return false
end

local function main()
    if not ensureJS_API() then return end

    local track, fx_idx = findFocusedCartridge()
    if not track then
        reaper.ShowMessageBox("No open Cartridge instance found.\n\nOpen Cartridge UI first, then run this script.", PLUGIN_NAME, 0)
        return
    end

    local sample_path = getMediaExplorerFile()
    if not sample_path then
        reaper.ShowMessageBox("No file selected in Media Explorer", PLUGIN_NAME, 0)
        return
    end

    if not file_exists(sample_path) then
        reaper.ShowMessageBox("File not found:\n" .. sample_path, PLUGIN_NAME, 0)
        return
    end

    -- Capture selection before stopping preview, then silence MX so it doesn't
    -- keep auditioning while the sample swap happens.
    local sel_start, sel_end = getMediaExplorerSelection(sample_path)
    stopMediaExplorerPreview()

    triggerLoad(track, fx_idx, sample_path)

    applySelectionAsTrim(track, fx_idx, sel_start, sel_end)
end

main()