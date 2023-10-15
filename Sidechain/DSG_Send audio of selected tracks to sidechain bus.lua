--[[
Description: DSG_Send audio of selected tracks to sidechain bus
Version: 1.0
Author: DSG
--]]

function msg(s) reaper.ShowConsoleMsg(tostring(s).."\n") end

-- case insensitive
SIDECHAIN_TRACKNAME_ALIASES = { 'sidechain', 'sc', 'sidechainbus', 'sidechain bus' }

numTracks = reaper.CountSelectedTracks(0)

if numTracks == 0 then return end

function SearchTrack(targetTrackNames)
    local numTracks = reaper.CountTracks(0)
    for i = 0, numTracks - 1 do
        local track = reaper.GetTrack(0, i)
        local _, trackName = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
        
        if type(targetTrackNames) == "table" then
            for _, targetName in ipairs(targetTrackNames) do
                if string.lower(trackName) == targetName then
                    return track
                end
            end
        elseif type(targetTrackNames) == "string" then
            if string.lower(trackName) == string.lower(targetTrackNames) then
                return track
            end
        end
    end
    return nil
end

local sidechainTrack = SearchTrack(SIDECHAIN_TRACKNAME_ALIASES)

if sidechainTrack == nil then return end

numSelectedTracks = reaper.CountSelectedTracks(0)

reaper.Undo_BeginBlock()
for i = 0, numSelectedTracks - 1 do
    local tr = reaper.GetSelectedTrack(0, i)
    
    if(tr == sidechainTrack) then
        goto continue
    end
    
    local createSendFlag = true
    
    for i = 0, reaper.GetTrackNumSends(tr, 0) - 1 do
        local destTrack = reaper.GetTrackSendInfo_Value(tr, 0, i, 'P_DESTTRACK')
        local destChan = reaper.GetTrackSendInfo_Value(tr, 0, i+1, 'I_DSTCHAN')
        
        if(destTrack == sidechainTrack) then
          createSendFlag = false
        end
    end
    
    if(createSendFlag == true) then
      local chCount = reaper.GetMediaTrackInfo_Value(tr, 'I_NCHAN')
      local send = reaper.CreateTrackSend(tr, sidechainTrack)
 
      reaper.SetMediaTrackInfo_Value( tr, 'B_MAINSEND', 0)
    end
    
    ::continue::
end

reaper.Undo_EndBlock('DSG_Send audio of selected tracks to sidechain bus', -1)
