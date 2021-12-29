--[[
Description: DSG_Toggle Solo Arm
Version: 1.0
Author: DSG
--]]

function msg(s) reaper.ShowConsoleMsg(s..'\n') end

trackCount = reaper.CountTracks(0)
if(trackCount == 0) then
  return
end
selectedTrackCount = reaper.CountSelectedTracks(0)
selectedArmedTrackCount = 0
armedTrackCount = 0

for i = 0, selectedTrackCount - 1 do
  tr = reaper.GetSelectedTrack(0, i)
  if(reaper.GetMediaTrackInfo_Value(tr, 'I_RECARM') == 1) then
    selectedArmedTrackCount = selectedArmedTrackCount + 1
  end
end

for i = 1, trackCount do
  tr = reaper.GetTrack(0, i - 1)
  if(reaper.GetMediaTrackInfo_Value(tr, 'I_RECARM') == 1) then
    armedTrackCount = armedTrackCount + 1
    reaper.SetMediaTrackInfo_Value(tr, 'I_RECARM', 0)
  end
end

if(selectedArmedTrackCount == selectedTrackCount) then
  return
end

for i = 0, selectedTrackCount - 1 do
  local tr = reaper.GetSelectedTrack(0, i)
  reaper.SetMediaTrackInfo_Value(tr, 'I_RECARM', 1)
end
