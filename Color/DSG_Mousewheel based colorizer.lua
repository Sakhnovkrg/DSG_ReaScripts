--[[
Description: DSG_Mousewheel based colorizer
Version: 1.0
Author: DSG
--]]

function msg(s) reaper.ShowConsoleMsg(s..'\n') end

math.randomseed(os.clock())

CONTEXT_TCP = 0
CONTEXT_ITEMS = 1
CONTEXT_ENVELOPES = 2

_,_,_,_,_,_,mouse_scroll  = reaper.get_action_context()
context = reaper.GetCursorContext()

if(context == CONTEXT_TCP) then
  if(mouse_scroll > 0) then
    reaper.Main_OnCommand(40360, 0) -- Track: Set to one random color
  else
    reaper.Main_OnCommand(40359, 0) -- Track: Set to default color
  end
end

if(context == CONTEXT_ITEMS or context == CONTEXT_ENVELOPES) then
  if(mouse_scroll > 0) then
    reaper.Main_OnCommand(40706, 0) -- Item: Set to one random color
  else
    reaper.Main_OnCommand(40707, 0) -- Item: Set to default color
  end
end
