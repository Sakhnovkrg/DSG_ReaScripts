--[[
Description: DSG_Solo Arm
Version: 1.0
Author: DSG
--]]
trackCount = reaper.CountTracks(0)
for i = 1, trackCount do
  tr = reaper.GetTrack(0, i - 1)
  reaper.SetMediaTrackInfo_Value(tr, 'I_RECARM', 0)
end

reaper.Main_OnCommand(41110, 0)
trackUnderCursor = reaper.GetSelectedTrack(0, 0)

if trackUnderCursor == nil then
  return false
end

reaper.SetMediaTrackInfo_Value(trackUnderCursor, 'I_RECARM', 1)
