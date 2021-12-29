--[[
Description: DSG_AutoHide MediaExplorer like FL Studio
Version: 1.0
Author: DSG
--]]

function msg(s) reaper.ShowConsoleMsg(tostring(s).."\n") end

-- config
PERIOD = 0.3
COMMAND = 50124 -- Media explorer: Show/hide media explorer
TABCONTROL_WIDTH = 15

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

-- script
function Run()
  local _,_,screenWidth,screenHeight = reaper.JS_Window_MonitorFromRect(0, 0, 0, 0, false)
  local mouseX, mouseY = reaper.GetMousePosition()

  local me = reaper.JS_Window_Find("Media Explorer", true)

  if(me) then
    _,_,_,meWidth = reaper.JS_Window_GetRect(me)
  end
  
  if(not me) then
    if(mouseX == 0) then
      SetCommandState(COMMAND, true)
    end
    return
  end

  if(mouseX > meWidth + TABCONTROL_WIDTH) then
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
