-- @description DSG_Cartridge create track from Media Explorer
-- @author Alexandr Sakhnov
-- @version 1.0.0
-- @changelog
--   Initial release
-- @link Website https://dsgdnb.com
-- @link Repository https://github.com/sakhnovkrg/DSG_ReaScripts
-- @about
--   # Cartridge - Create track from Media Explorer
--
--   Creates a new track with Cartridge sampler and loads the selected file
--   from Media Explorer. If nothing is selected, opens a file dialog.
--
--   **Features:**
--   - Auto-copies samples to project's Audio folder (if project is saved)
--
--   **Requirements:**
--   - Cartridge 0.2.7+
--   - js_ReaScriptAPI extension

local PLUGIN_NAME = "Cartridge"
local COPY_TO_PROJECT = true

local function getProjectPath()
    if not COPY_TO_PROJECT then return nil end
    local path = reaper.GetProjectPath("")
    return path ~= "" and path or nil
end

local function copyToProject(source, proj_path)
    if not proj_path then return source end

    local audio_dir = proj_path .. "/Audio"
    reaper.RecursiveCreateDirectory(audio_dir, 0)

    local filename = source:match("([^\\/]+)$")
    if not filename then return source end

    if source:gsub("\\", "/"):lower():find(proj_path:gsub("\\", "/"):lower(), 1, true) then
        return source
    end

    local dest = audio_dir .. "/" .. filename
    if io.open(dest, "rb") then
        local base, ext = filename:match("(.+)(%.[^.]+)$")
        base = base or filename
        ext = ext or ""
        local i = 1
        while io.open(dest, "rb") do
            dest = audio_dir .. "/" .. base .. "_" .. i .. ext
            i = i + 1
        end
    end

    local src = io.open(source, "rb")
    if not src then return source end
    local content = src:read("*all")
    src:close()

    local dst = io.open(dest, "wb")
    if not dst then return source end
    dst:write(content)
    dst:close()

    return dest
end

local function getMediaExplorerFile()
    local hwnd = reaper.JS_Window_Find("Media Explorer", true)
        or reaper.JS_Window_FindChild(reaper.GetMainHwnd(), "Media Explorer", true)
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

    local dir = ""
    local edit = reaper.JS_Window_FindChildByID(hwnd, 1002)
    if edit then dir = reaper.JS_Window_GetTitle(edit) end
    if dir == "" then
        local combo = reaper.JS_Window_FindChildByID(hwnd, 1000)
        if combo then dir = reaper.JS_Window_GetTitle(combo) end
    end

    -- Handle DB paths by enabling "Show full path" option
    if dir:match("^DB:%s*") then
        -- Check if first column already has full path (option already on)
        local first_check = reaper.JS_ListView_GetItemText(list, idx, 0)
        if first_check and (first_check:match("^%a:[\\/]") or first_check:match("^/")) then
            return first_check
        end

        -- Toggle "Show full path in databases" ON
        reaper.JS_WindowMessage_Send(hwnd, "WM_COMMAND", 42026, 0, 0, 0)

        -- Re-read filename (now should be full path)
        local full_path = reaper.JS_ListView_GetItemText(list, idx, 0)

        -- Toggle back OFF (restore original state)
        reaper.JS_WindowMessage_Send(hwnd, "WM_COMMAND", 42026, 0, 0, 0)

        if full_path and (full_path:match("^%a:[\\/]") or full_path:match("^/")) then
            return full_path
        end
        return nil
    end

    if filename:match("^%a:") or filename:match("^/") then
        return filename
    end
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

    local sample_path = getMediaExplorerFile()

    if not sample_path then
        local ok, path = reaper.GetUserFileNameForRead("", "Select Sample", "wav;flac;aif;mp3")
        if ok then sample_path = path end
    end

    if not sample_path then
        reaper.ShowMessageBox("No file selected in Media Explorer", PLUGIN_NAME, 0)
        return
    end

    if not io.open(sample_path, "rb") then
        reaper.ShowMessageBox("File not found:\n" .. sample_path, PLUGIN_NAME, 0)
        return
    end

    local proj_path = getProjectPath()
    if proj_path then
        sample_path = copyToProject(sample_path, proj_path)
    end

    reaper.Undo_BeginBlock()

    local idx = reaper.CountTracks(0)
    reaper.InsertTrackAtIndex(idx, true)
    local track = reaper.GetTrack(0, idx)

    local name = sample_path:match("([^\\/]+)$"):gsub("%.[^.]+$", "")
    reaper.GetSetMediaTrackInfo_String(track, "P_NAME", name, true)

    -- Set MIDI input: All MIDI Inputs, All Channels (4096 + 63*32 + 0 = 6112)
    reaper.SetMediaTrackInfo_Value(track, "I_RECINPUT", 6112)
    reaper.SetMediaTrackInfo_Value(track, "I_RECARM", 1)
    reaper.SetMediaTrackInfo_Value(track, "I_RECMON", 1)

    local fx = reaper.TrackFX_AddByName(track, PLUGIN_NAME, false, -1)
    if fx < 0 then
        fx = reaper.TrackFX_AddByName(track, "VST3:" .. PLUGIN_NAME, false, -1)
    end

    if fx < 0 then
        reaper.ShowMessageBox(PLUGIN_NAME .. " not found.\nMake sure it's installed.", "Error", 0)
        reaper.Undo_EndBlock("Create track (plugin not found)", -1)
        return
    end

    triggerLoad(track, fx, sample_path)
    reaper.TrackFX_Show(track, fx, 3)
    reaper.SetOnlyTrackSelected(track)

    reaper.Undo_EndBlock("Create track with " .. PLUGIN_NAME .. ": " .. name, -1)
end

main()
