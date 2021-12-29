--[[
Description: DSG_VKB helper
Version: 1.0
Author: DSG
--]]
function msg(s) reaper.ShowConsoleMsg(s..'\n') end

is_new_value, filename, sec, cmd, mode, resolution, val = reaper.get_action_context()
state = reaper.GetToggleCommandStateEx(sec, '40377') -- View: Show virtual MIDI keyboard

function setArm(tr)
  bits_set=tonumber('111111'..'00000', 2)
  reaper.SetMediaTrackInfo_Value(tr, 'I_RECINPUT', 4096+bits_set) -- set input to all MIDI
  reaper.SetMediaTrackInfo_Value(tr, 'I_RECMON', 1) -- monitor input
  reaper.SetMediaTrackInfo_Value(tr, 'I_RECARM', 1) -- arm track
  reaper.SetMediaTrackInfo_Value(tr, 'I_RECMODE',0) -- record MIDI out
end

function flushArms()
  trackCount = reaper.CountTracks(0)
  
  for i=1, trackCount do
    tr = reaper.GetTrack(0, i-1)
    reaper.SetMediaTrackInfo_Value(tr, 'I_RECARM', 0)
  end
end

if(state == 1) then
  trackCount = reaper.CountTracks(0)
  targetTrack = reaper.GetLastTouchedTrack()
  if targetTrack then
    if(reaper.GetMediaTrackInfo_Value(targetTrack, 'I_RECARM') == 0) then
      flushArms()
      setArm(targetTrack)
      return
    end
  end

  flushArms()

  reaper.Main_OnCommand(40377, 0) -- View: Show virtual MIDI keyboard
else
  targetTrack = reaper.GetLastTouchedTrack()
  if not targetTrack then return end
  
  flushArms()
  setArm(targetTrack)
  
  reaper.Main_OnCommand(40377, 0) -- View: Show virtual MIDI keyboard
  
  state = reaper.GetToggleCommandStateEx(sec, '40637') -- Virtual MIDI keyboard: Send all input to VKB
  if(state == 0) then reaper.Main_OnCommand(40637, 0) end
end
