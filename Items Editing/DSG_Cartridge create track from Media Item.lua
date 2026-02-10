-- @description DSG_Cartridge create track from Media Item
-- @author Alexandr Sakhnov
-- @version 1.1.0
-- @changelog
--   v1.1.0
--   - Removed auto-copy to project folder (plugin now embeds sample data in state)
--   v1.0.0
--   - Initial release
-- @link Website https://dsgdnb.com
-- @link Repository https://github.com/sakhnovkrg/DSG_ReaScripts
-- @about
--   # Cartridge - Create track from Media Item
--
--   Creates a new track with Cartridge sampler and loads the sample
--   from the selected media item.
--
--   **Requirements:**
--   - Cartridge 0.2.7+

local PLUGIN_NAME = "Cartridge"

local function getSelectedItemFile()
    local item = reaper.GetSelectedMediaItem(0, 0)
    if not item then return nil end
    local take = reaper.GetActiveTake(item)
    if not take then return nil end
    local source = reaper.GetMediaItemTake_Source(take)
    if not source then return nil end
    return reaper.GetMediaSourceFileName(source, "")
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

local function main()
    local sample_path = getSelectedItemFile()

    if not sample_path then
        reaper.ShowMessageBox("No media item selected", PLUGIN_NAME, 0)
        return
    end

    if not io.open(sample_path, "rb") then
        reaper.ShowMessageBox("File not found:\n" .. sample_path, PLUGIN_NAME, 0)
        return
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
