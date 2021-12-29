--[[
Description: DSG_Pick up color
Version: 1.0
Author: DSG
--]]

local function for_tracks()
  local numSelected = reaper.CountSelectedTracks(0)

  if numSelected == 0 then
    return false
  end

  local selected = {}
  local lastSelected

  for i = 0, numSelected - 1 do
    local track = reaper.GetSelectedTrack(0, i)
    selected[i] = track
    if(i == numSelected - 1) then
      lastSelected = track
    end
  end

  -- Track: Select track under mouse
  reaper.Main_OnCommand(41110, 0)
  local underCursor = reaper.GetSelectedTrack(0, 0)

  if underCursor == nil then
    return false
  end

  local unselectFlag = true

  for i = 0, numSelected - 1 do
    local track = selected[i]

    if(track == underCursor) then
      unselectFlag = false
    end
  end

  if(unselectFlag) then
    reaper.SetTrackSelected(underCursor, 0)
  end

  local color = reaper.GetTrackColor(underCursor)
  local emptyColorFlag = color == 0

  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)

  for i = 0, numSelected - 1 do
    local track = selected[i]
    if track ~= nil and track ~= underCursor then
      reaper.SetTrackSelected(track, 1)
      if(emptyColorFlag) then
        -- Track: Set to default color
        reaper.Main_OnCommand(40359, 0)
      else
        reaper.SetTrackColor(track, color)
      end
    end
  end

  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  reaper.SetMixerScroll(lastSelected)
  reaper.Undo_EndBlock("Pick up color", -1)
end

local function for_items()
  local window, segment, details = reaper.BR_GetMouseCursorContext("", "", "", 0)

  if window ~= "arrange" or details ~= "item" then
    return
  end

  local underCursor = reaper.BR_GetMouseCursorContext_Item()
  local color = reaper.GetDisplayedMediaItemColor(underCursor)

  if color == 0 then
    local track = reaper.GetMediaItemTrack(underCursor)
    color = reaper.GetMediaTrackInfo_Value(track, "I_CUSTOMCOLOR")
  end

  if color ~= nil then
    local countItems = reaper.CountSelectedMediaItems(0)

    if countItems > 0 then
      reaper.Undo_BeginBlock()
      reaper.PreventUIRefresh(1)

      for i = 0, countItems-1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", color)
      end

      reaper.PreventUIRefresh(-1)
      reaper.UpdateArrange()
      reaper.Undo_EndBlock("Pick up color", -1)
    end
  end
end

local context = reaper.GetCursorContext()

if(context == 0) then
  for_tracks()
end

if(context == 1) then
  for_items()
end
