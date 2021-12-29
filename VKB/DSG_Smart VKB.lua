--[[
Description: DSG_Smart VKB
Version: 1.0
Author: DSG
--]]

function msg(s) reaper.ShowConsoleMsg(s..'\n') end

time = 0.2 -- time in seconds before each action
time1 = reaper.time_precise()
hideVKB = true
vkbOpacity = 0

function SetButtonState(set)
  local is_new_value, filename, sec, cmd, mode, resolution, val = reaper.get_action_context()
  reaper.SetToggleCommandState(sec, cmd, set or 0)
  reaper.RefreshToolbar2(sec, cmd)
end

function HideVKB()
  if(not hideVKB) then
    return false
  end
  vkb = reaper.JS_Window_Find("Virtual MIDI keyboard", true)

  if vkb then
    rpr = reaper.JS_Window_GetParent(vkb)
    retval, left, top, right, bottom = reaper.JS_Window_GetClientRect(rpr)
    vkbx = (right-50)
    vkby = (top)
    reaper.JS_Window_SetOpacity(vkb, "ALPHA", vkbOpacity)
    reaper.JS_Window_SetPosition(vkb, vkbx, vkby, 110, 28)
    reaper.Main_OnCommand(reaper.NamedCommandLookup('_BR_FOCUS_ARRANGE_WND'), 0)
  end
end

function Main()  
 local time2 = reaper.time_precise() 
 if time2 - time1 > time then 
  
  time1 = reaper.time_precise() -- reset timer

  local trackCount = reaper.CountTracks(0)
  local hasArm = 0

  for i=1, trackCount do
    local tr = reaper.GetTrack(0, i-1)
    local arm = reaper.GetMediaTrackInfo_Value(tr, 'I_RECARM')

    if(arm == 1.0) then
      hasArm = 1
      break
    end
  end
  
  is_new_value, filename, sec, cmd, mode, resolution, val = reaper.get_action_context()
  vkbState = reaper.GetToggleCommandStateEx(sec, 40377) -- View: Show virtual MIDI keyboard
  vkbSendState = reaper.GetToggleCommandStateEx(sec, 40637) -- Virtual MIDI keyboard: Send all input to VKB

  if(hasArm == 1) then
    if(vkbState == 0) then
      reaper.Main_OnCommand(40377, 1) -- View: Show virtual MIDI keyboard
      HideVKB()
    end
    if(vkbSendState == 0) then
      reaper.Main_OnCommand(40637, 1) -- Virtual MIDI keyboard: Send all input to VKB
    end
  else
    if(vkbState == 1) then
      --reaper.Main_OnCommand(40377, 0) -- View: Show virtual MIDI keyboard
    end
    if(vkbSendState == 1) then
      reaper.Main_OnCommand(40637, 0) -- Virtual MIDI keyboard: Send all input to VKB
    end
  end
 end

 reaper.defer(Main) 
end

function OnExit()
  SetButtonState(0)
  
  is_new_value, filename, sec, cmd, mode, resolution, val = reaper.get_action_context()
  vkbState = reaper.GetToggleCommandStateEx(sec, 40377) -- View: Show virtual MIDI keyboard
  vkbSendState = reaper.GetToggleCommandStateEx(sec, 40637) -- Virtual MIDI keyboard: Send all input to VKB
  
  if(vkbState == 1) then
    reaper.Main_OnCommand(40377, 0) -- View: Show virtual MIDI keyboard
  end
  if(vkbSendState == 1) then
    reaper.Main_OnCommand(40637, 0) -- Virtual MIDI keyboard: Send all input to VKB
  end
end

is_new_value, filename, sec, cmd, mode, resolution, val = reaper.get_action_context()
vkbState = reaper.GetToggleCommandStateEx(sec, 40377) -- View: Show virtual MIDI keyboard
if(vkbState == 1) then
  reaper.Main_OnCommand(40377, 0) -- View: Show virtual MIDI keyboard
end

reaper.defer(Main)
SetButtonState(1)
reaper.atexit(OnExit)
