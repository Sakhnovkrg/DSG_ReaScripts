--[[
Description: DSG_Automatic send all input to VKB.lua
Version: 1.0
Author: DSG
--]]

function msg(s) reaper.ShowConsoleMsg(tostring(s).."\n") end

lastRunTime = reaper.time_precise()

function GetCommandState(command)
  local _,_,sectionID = reaper.get_action_context()
  return reaper.GetToggleCommandStateEx(sectionID, command)
end

function BoolToNumber(value)
  return value and 1 or 0
end

function SetCommandState(command, flag)
  flag = BoolToNumber(flag)
  state = GetCommandState(command)
  
  if(state ~= flag) then
    reaper.Main_OnCommand(command, 0)
  end
end

function SetVKBSendState(flag)
  local command = 40637 -- Virtual MIDI keyboard: Send all input to VKB
  SetCommandState(command, flag)
end

function Run()
  local _,_,sec = reaper.get_action_context()
  local trackCount = reaper.CountTracks(0)
  local flag = false
  
  for i=0, trackCount-1 do
    local tr = reaper.GetTrack(0, i)
    local instrument = reaper.TrackFX_GetInstrument(tr)
    local hasInstrument = instrument >= 0
    local hasRecordArm = reaper.GetMediaTrackInfo_Value(tr, 'I_RECARM') == 1
    
    if(hasInstrument and hasRecordArm) then
      flag = true
      break
    end
  end
  
  SetVKBSendState(flag)
end

function Timer()
  local currentTime = reaper.time_precise()

  if currentTime - lastRunTime > 0.2 then
    lastRunTime = reaper.time_precise()
    Run()
  end

  reaper.defer(Timer)
end

reaper.defer(Timer)
