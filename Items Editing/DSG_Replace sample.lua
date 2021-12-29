--[[
Description: DSG_Replace sample
Version: 1.0
Author: DSG
--]]

function msg(s) reaper.ShowConsoleMsg(s..'\n') end

local sel_item_count = reaper.CountSelectedMediaItems(0)
if sel_item_count == 0 then
  return
end

local window, segment, details = reaper.BR_GetMouseCursorContext()
local item_under_cursor = reaper.BR_GetMouseCursorContext_Item()

if item_under_cursor == nil or reaper.IsMediaItemSelected(item_under_cursor) then
  return
end

local take_of_item_under_cursor = reaper.GetActiveTake(item_under_cursor)
local src = reaper.GetMediaItemTake_Source(take_of_item_under_cursor)

reaper.Undo_BeginBlock()

for i=1, sel_item_count do
  local item = reaper.GetSelectedMediaItem(0, i-1)
  if item ~= nil and item ~= item_under_cursor then
    local take = reaper.GetActiveTake(item)
    reaper.SetMediaItemTake_Source(take, src)
    reaper.UpdateArrange()
 end
end

reaper.Main_OnCommand(40441, 0)
reaper.Undo_EndBlock('DSG_RepaceSample', -1)
