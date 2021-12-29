--[[
Description: DSG_AutoHide FX Browser like FL Studio
Version: 1.5
Author: DSG
--]]

function msg(s) reaper.ShowConsoleMsg(tostring(s).."\n") end

-- config
PERIOD = 0.3
COMMAND = 40271 -- View: Show FX browser window
TABCONTROL_WIDTH = 0

-- globals
lastRunTime = reaper.time_precise()

-- helpers
function BoolToNumber(value)
  return value and 1 or 0
end

function GetCommandState(command)
  local _,_,sectionID = reaper.get_action_context()
  return reaper.GetToggleCommandStateEx(sectionID, command)
end

function SetCommandState(command, flag)
  flag = BoolToNumber(flag)
  state = GetCommandState(command)
  
  if(state ~= flag) then
    reaper.Main_OnCommand(command, 0)
  end
end

function ReaperInFocus()
  local hwnd = reaper.JS_Window_GetForeground() -- may be nil when switching windows, so check it!
  if hwnd then
    local reaperHwnd = reaper.GetMainHwnd()
    if hwnd == reaperHwnd or reaper.JS_Window_GetParent(hwnd) == reaperHwnd then
      return true
    end 
  end 
  return false
end

-- script
function Run()
  local _,_,screenWidth,screenHeight = reaper.JS_Window_MonitorFromRect(0, 0, 0, 0, false)
  local mouseX, mouseY = reaper.GetMousePosition()
  local state = GetCommandState(COMMAND)
  
  if(state == 0) then
    if(mouseX == 0) then
      --reaper.Main_OnCommand(40297, 0) -- Track: Unselect all tracks
      SetCommandState(COMMAND, true)
    end
    return
  end
  
  local windowTitle = 'Browse FX'
  local tr = reaper.GetLastTouchedTrack()
  local fxb = reaper.JS_Window_Find(windowTitle, true)
 
  if(tr) then
    windowTitle = 'Add FX to'
    trNumber = math.floor(reaper.GetMediaTrackInfo_Value(tr, 'IP_TRACKNUMBER'))
    local _,trName = reaper.GetTrackName(tr, "")
    
    if(trName == 'MASTER') then
      windowTitle = 'Add FX to Master Track'
      fxb = reaper.JS_Window_Find(windowTitle, true)
    else
      if(trName == 'Track '..trNumber) then
        windowTitle = windowTitle..' Track '..trNumber
        fxb = reaper.JS_Window_Find(windowTitle, true)
      
        if(fxb == nil) then
          windowTitle = windowTitle..' " '..trName..'"'
          fxb = reaper.JS_Window_Find(windowTitle, true)
        end
      else
        windowTitle = 'Add FX to Track '..trNumber..' "'..trName..'"'
      end
    end
  end
  
  local fxb = reaper.JS_Window_Find(windowTitle, true)
  local _,_,_,fxbWidth = reaper.JS_Window_GetRect(fxb)

  if(mouseX > fxbWidth + TABCONTROL_WIDTH) then
    SetCommandState(COMMAND, false)
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
