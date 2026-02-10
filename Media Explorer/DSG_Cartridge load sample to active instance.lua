-- @description DSG_Cartridge load sample to active instance
-- @author Alexandr Sakhnov
-- @version 1.2.0
-- @changelog
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

local ME_WINDOW_NAMES = {"Media Explorer", "Медиа-браузер"}

local function findMediaExplorer()
    for _, name in ipairs(ME_WINDOW_NAMES) do
        local hwnd = reaper.JS_Window_Find(name, true)
        if hwnd then return hwnd end
        hwnd = reaper.JS_Window_FindChild(reaper.GetMainHwnd(), name, true)
        if hwnd then return hwnd end
    end
    return nil
end

local function is_absolute_path(s)
    return s and (s:match("^%a:[\\/]") or s:match("^/")) and #s > 1
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

    -- Normal folder: combine path + filename
    if is_absolute_path(filename) then return filename end
    if dir == "" then return nil end
    if dir:sub(-1) ~= "/" and dir:sub(-1) ~= "\\" then dir = dir .. "/" end
    return dir .. filename
end

local function triggerLoad(track, fx_idx, sample_path)
    local appdata = os.getenv("APPDATA")
    if not appdata then
        local home = os.getenv("HOME")
        if reaper.GetOS():match("OSX") or reaper.GetOS():match("macOS") then
            appdata = home .. "/Library/Application Support"
        else
            -- Linux
            appdata = home .. "/.local"
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

    if not io.open(sample_path, "rb") then
        reaper.ShowMessageBox("File not found:\n" .. sample_path, PLUGIN_NAME, 0)
        return
    end

    triggerLoad(track, fx_idx, sample_path)

    -- Apply Media Explorer preview selection as trim
    local sel_start, sel_end = getMediaExplorerSelection(sample_path)
    applySelectionAsTrim(track, fx_idx, sel_start, sel_end)
end

main()
