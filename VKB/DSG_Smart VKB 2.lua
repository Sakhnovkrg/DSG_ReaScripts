--[[
Description: DSG_Smart VKB 2
Version: 1.1.4
Author: DSG
--]]

function msg(s) reaper.ShowConsoleMsg(tostring(s).."\n") end

-- config
PERIOD = 0.2
HIDE_VKB = true
VKB_OPACITY = 0
AUTO_SET_MIDI_INPUT = true

-- globals
lastRunTime = reaper.time_precise()

-- helpers
function SetArm(tr)
  if(AUTO_SET_MIDI_INPUT) then  
    local bits_set=tonumber('111111'..'00000', 2)
    reaper.SetMediaTrackInfo_Value(tr, 'I_RECINPUT', 4096+bits_set) -- set input to all MIDI
    reaper.SetMediaTrackInfo_Value(tr, 'I_RECMON', 1) -- monitor input
    reaper.SetMediaTrackInfo_Value(tr, 'I_RECMODE',0) -- record MIDI out
  end

  reaper.SetMediaTrackInfo_Value(tr, 'I_RECARM', 1)
end

function Unarm(tr)
  reaper.SetMediaTrackInfo_Value(tr, 'I_RECARM', 0)
end

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

function SetVKBState(flag)
  local command = 40377 -- View: Show virtual MIDI keyboard
  SetCommandState(command, flag)
end

function SetVKBSendState(flag)
  local command = 40637 -- View: Show virtual MIDI keyboard
  SetCommandState(command, flag)
end

local function InTable(tab, val)
  for index, value in ipairs(tab) do
    if value == val then
      return true
    end
  end

  return false
end

-- script
function HideVKB()
  if(not HIDE_VKB) then
    return false
  end
  
  
  local vkbTitles = {"Virtual MIDI keyboard", "Виртуальная MIDI-клавиатура"}
  local vkb
  
  for k, v in pairs(vkbTitles) do
    vkb = reaper.JS_Window_Find(v, true)
    if(vkb) then
      break
    end
  end

  if vkb then
    rpr = reaper.JS_Window_GetParent(vkb)
    retval, left, top, right, bottom = reaper.JS_Window_GetClientRect(rpr)
    vkbx = (right-10)
    vkby = (top+20)
    reaper.JS_Window_SetOpacity(vkb, "ALPHA", 0)
    if(VKB_OPACITY == 0) then
      reaper.JS_Window_SetPosition(vkb, vkbx, vkby, 110, 28)
    end
    reaper.Main_OnCommand(reaper.NamedCommandLookup('_BR_FOCUS_ARRANGE_WND'), 0)
  end
end

function Run()
  local me = reaper.MIDIEditor_GetActive()
  local meTake, meTrack, meInstrument, meTrackHasInstrument, meTrackIgnored, meTrackName, window
  local trackCount = reaper.CountTracks(0)

  local tracksWithOpenedInstrument = {}
  local tracksIgnored = {}
  
  if(me) then
    meTake = reaper.MIDIEditor_GetTake(me)
    meTrack = reaper.GetMediaItemTake_Track(meTake)
    meTrackNumber = reaper.GetMediaTrackInfo_Value(meTrack, 'IP_TRACKNUMBER')-1
    _,meTrackName = reaper.GetTrackName(meTrack, "")
    meInstrument = reaper.TrackFX_GetInstrument(meTrack)
    meTrackHasInstrument = meInstrument >= 0
    meTrackIgnored = string.sub(meTrackName, 1, 1) == '_'
  end

  for i=0, trackCount-1 do
    local tr = reaper.GetTrack(0, i)
    local _,trName = reaper.GetTrackName(tr, "")
    local isIgnored = string.sub(trName, 1, 1) == '_'
    local instrument = reaper.TrackFX_GetInstrument(tr)
    local hasInstrument = instrument >= 0
 
    if(hasInstrument and not isIgnored) then
      window = reaper.TrackFX_GetFloatingWindow(tr, instrument)
     
      if(window) then
        tracksWithOpenedInstrument[#tracksWithOpenedInstrument+1] = i
      end
    end
    
    if(isIgnored) then
      tracksIgnored[#tracksIgnored+1] = i
    end
  end
  
  local disableSend = true
  local unarmIgnored = {}
 
  if(#tracksWithOpenedInstrument > 0) then
    for i=0, trackCount-1 do
      local tr = reaper.GetTrack(0, i)
      if(not InTable(tracksIgnored, i) and InTable(tracksWithOpenedInstrument, i)) then
        SetArm(tr)
        SetVKBSendState(true)
        
        disableSend = false
        
        unarmIgnored[#unarmIgnored+1] = i
      end
    end
  end
  
  if(#tracksWithOpenedInstrument == 0 and meTrackHasInstrument and not meTrackIgnored) then
    SetArm(meTrack)
    SetVKBSendState(true)
    disableSend = false
    unarmIgnored[#unarmIgnored+1] = meTrackNumber
  end
  
  if(#tracksWithOpenedInstrument == 0 and not meTrackHasInstrument) then
    disableSend = true
  end
  
  for i=0, trackCount-1 do
    local tr = reaper.GetTrack(0, i)
    if(not InTable(unarmIgnored, i) and not InTable(tracksIgnored,i)) then
      Unarm(tr)
    end
  end
  
  for index, value in ipairs(tracksIgnored) do
    local tr = reaper.GetTrack(0, value)
    if(reaper.GetMediaTrackInfo_Value(tr, 'I_RECARM') == 1 and reaper.TrackFX_GetInstrument(tr) >= 0) then
      disableSend = false
      SetVKBSendState(true)
    end
  end

  if(disableSend) then
    SetVKBSendState(false)
  end
end

function Timer()
  local currentTime = reaper.time_precise()

  if currentTime - lastRunTime > PERIOD then
    lastRunTime = reaper.time_precise()
    Run()
  end

  reaper.defer(Timer)
end

reaper.defer(Timer)
SetVKBState(true)
HideVKB()
