--[[
Description: DSG_Offliner
Version: 1.0
Author: DSG
--]]

----------------------------------------- Functions -----------------------------------------

function msg(s) reaper.ShowConsoleMsg(tostring(s)..'\n') end

function hasSelectedTrack()
   return reaper.CountSelectedTracks(0) > 0
end

function isFolder(track)
  return reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") >= 1
end

function hasItems(track)
  return reaper.GetTrackMediaItem(track, 0) ~= nil
end

----------------------------------------- UI Functions -----------------------------------------

function extend(child, parent)
  setmetatable(child, {__index = parent})
end

function hex2RGB(hex)
  local hex = hex:gsub("#","")
  return tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))
end

function colorFromHex(hex)
  local r,g,b = hex2RGB(hex)
  return r/255, g/255, b/255
end

----------------------------------------- UI Classes -----------------------------------------

Element = {}
Button = {}
Label = {}
CheckBox = {}

function Element:new(x,y,w,h)
    local e = {}
    e.x = x
    e.y = y
    e.w = w
    e.h = h

    e.enabled = true
    setmetatable(e, self)

    self.__index = self 
    self:init()
    return e
end

function Element:init()
end

function Element:draw()
end

function Element:pointIn(x, y)
  return x >= self.x and x <= self.x + self.w and y >= self.y and y <= self.y + self.h
end

function Element:mouseIn()
  return gfx.mouse_cap&1==0 and self:pointIn(gfx.mouse_x, gfx.mouse_y)
end

function Element:mouseDown()
  return gfx.mouse_cap&1==1 and self:pointIn(mouse_ox,mouse_oy)
end

function Element:mouseClick()
  return gfx.mouse_cap&1==0 and last_mouse_cap&1==1 and self:pointIn(gfx.mouse_x,gfx.mouse_y) and self:pointIn(mouse_ox,mouse_oy)         
end



function Button:init()
  self.bg_color = '#333333'
  self.bg_hover_color = '#666666'
  self.bg_active_color = '#999900'
  self.text_color = '#fefefe'
  self.label = 'Button label'
  self.font_size = 'Arial'
  self.font_size = 16
end

function Button:drawLabel()
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local lbl_w, lbl_h = gfx.measurestr(self.label)
  gfx.x = x+(w-lbl_w)/2
  gfx.y = y+(h-lbl_h)/2

  gfx.drawstr(self.label)
end

function Button:drawBody()
  gfx.rect(self.x,self.y,self.w,self.h, true)
end

function Button:draw()
  local r,g,b = colorFromHex(self.bg_color)
  local a = 1
  local font,font_size = self.font, self.font_size
  
  if(self.enabled) then
    if self:mouseIn() then r,g,b = colorFromHex(self.bg_hover_color) end
    if self:mouseDown() then r,g,b = colorFromHex(self.bg_active_color) end
    if self:mouseClick() and self.onClick then self.onClick() end
  else
    a = 0.25
  end
  
  gfx.set(r,g,b,a)
  self:drawBody()
  r,g,b = colorFromHex(self.text_color)
  gfx.set(r,g,b,a)
  gfx.setfont(1, font, font_size)
  self:drawLabel()
end

extend(Button, Element)



function Label:init()
  self.text_color = '#ffffff'
  self.text = 'text'
  self.center = false
  self.font = 'Arial'
  self.font_size = 16
end

function Label:draw()
  local r,g,b = colorFromHex(self.text_color)
  local a = 1
  local x,y,w,h  = self.x,self.y,self.w,self.h

  gfx.setfont(1, self.font, self.font_size)
  local lbl_w, lbl_h = gfx.measurestr(self.text)
  gfx.x = self.x
  if(self.center == true) then
    gfx.x = x+(w-lbl_w)/2
  end
  gfx.y = y+(h-lbl_h)/2
  
  gfx.set(r,g,b,a)
  gfx.drawstr(self.text)
end

extend(Label, Element)



function CheckBox:init()
  self.text_color = '#fefefe'
  self.bg_color = '#333333'
  self.bg_hover_color = '#666666'
  self.bg_active_color = '#990000'
  self.bg_checked_color = '#009900'
  self.text = 'text'
  self.enabled = true
  self.value = 0
  self.font = 'Arial'
  self.font_size = 16
end

function CheckBox:pointIn(x, y)
  return x >= self.x and x <= self.x + self.w + gfx.measurestr(self.text) + 7 and y >= self.y and y <= self.y + self.h
end

function CheckBox:drawBody()
  gfx.rect(self.x,self.y,self.w,self.h, true)
end

function CheckBox:drawLabel()
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local lbl_w, lbl_h = gfx.measurestr(self.text)
  gfx.x = w+7+x
  gfx.y = y+(h-lbl_h)/2
  
  gfx.drawstr(self.text)
end

function CheckBox:draw()
  local r,g,b = colorFromHex(self.bg_color)
  if(self.value == 1) then
    r,g,b = colorFromHex(self.bg_checked_color)
  end
  local a = 1
  if(self.value == 0) then a = 0.7 end
  gfx.setfont(1, self.font, self.font_size)
  if(self.enabled) then
    if (self:mouseIn() or self:mouseDown()) then
      if(self.value == 0) then r,g,b = colorFromHex(self.bg_checked_color) end
    end
    if self:mouseClick() and self.onClick then self.onClick() end
  else
    a = 0.25
  end
  
  gfx.set(r,g,b,a)
  self:drawBody()
  r,g,b = colorFromHex(self.text_color)
  
  gfx.set(r,g,b,a)
  self:drawLabel()
end

extend(CheckBox, Element)

----------------------------------------- START -----------------------------------------
error = nil
tr = nil
if(hasSelectedTrack() == false) then
  error = 'No track selected'
  -- msg('Error: Select a track')
  -- return 
else
  tr = reaper.GetSelectedTrack(0, 0)
  reaper.SetOnlyTrackSelected(tr)
end

if(tr ~= nil) then
  if(hasItems(tr) == false) then
    error = 'There are no items on this track'
    -- msg('Error: There are no items on this track')
    -- return 
  end
  -- if(isFolder(tr) == true) then
    -- error = 'Folder track selected'
    -- msg('Error: Track must not be a folder')
    -- return 
  -- end
end


script_title = "DSG_Offliner"
if(tr ~= nil) then _,track_name = reaper.GetTrackName(tr, "") else track_name = '' end
is_offline_track = false
wnd_w,wnd_h = 300,334
last_mouse_cap = 0
last_x, last_y = 0, 0
mouse_ox, mouse_oy = -1, -1

if(string.sub(track_name, 1, 8) == 'offline_') then
  is_offline_track = true
end

----------------------------------------- UI -----------------------------------------

lblTrackname = Label:new(15,15,270,15)
lblTrackname.text = track_name
if(error ~= nil) then lblTrackname.text = error end
lblTrackname.center = true
if(is_offline_track) then
  lblTrackname.text_color = '#990000'
elseif(error == nil) then
  lblTrackname.text_color = '#009900'
else
  lblTrackname.text_color = '#999900'
end

LabelTable = {lblTrackname}

canRender = false
if(is_offline_track == false and error == nil) then canRender = true end

cbItemsMode = CheckBox:new(15,40,18,18)
cbItemsMode.text = 'Split by Items'
cbItemsMode.value = tonumber(reaper.GetExtState(script_title, "cbItemsMode")) or 0
cbItemsMode.enabled = canRender
cbItemsMode.onClick = function()
   if(cbItemsMode.value == 1) then
     cbItemsMode.value = 0
   else
     cbItemsMode.value = 1
   end
end

cbHideTrack = CheckBox:new(15,73,18,18)
cbHideTrack.text = 'Hide track'
cbHideTrack.value = tonumber(reaper.GetExtState(script_title, "cbHideTrack")) or 0
cbHideTrack.enabled = canRender
cbHideTrack.onClick = function()
   if(cbHideTrack.value == 1) then
     cbHideTrack.value = 0
   else
     cbHideTrack.value = 1
   end
end

cbColorize = CheckBox:new(15,106,18,18)
cbColorize.text = 'Set black color to offline track'
cbColorize.value = tonumber(reaper.GetExtState(script_title, "cbColorize")) or 0
cbColorize.enabled = canRender
cbColorize.onClick = function()
   if(cbColorize.value == 1) then
     cbColorize.value = 0
   else
     cbColorize.value = 1
   end
end

CheckBoxTable = {cbItemsMode, cbHideTrack, cbColorize}

btnRender = Button:new(15,138,270,40)
btnRender.label = 'Set all FX offline and render to new track'
btnRender.enabled = canRender

btnRender.onClick = function()
  reaper.PreventUIRefresh(1)
  reaper.Undo_BeginBlock()
  
  if(cbColorize.value == 1) then
    reaper.SetTrackColor(tr, 0)
  end

  reaper.Main_OnCommand(40405, 0) -- Track: Render tracks to stereo post-fader stem tracks (and mute originals)
  reaper.SetOnlyTrackSelected(tr)
  reaper.Main_OnCommand(40535, 0) -- Track: Set all FX offline for selected tracks
  
  for i = 0, reaper.CountTrackMediaItems(tr) - 1 do
    reaper.SetMediaItemInfo_Value(reaper.GetTrackMediaItem(tr, i), 'B_MUTE', 1)
  end
  
  if(cbItemsMode.value == 1) then
    local timeselstart, timeselend = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  
    local trackNumber = reaper.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER")
    local stemTrack = reaper.GetTrack(0, trackNumber - 2)
    reaper.SetOnlyTrackSelected(stemTrack)
    reaper.Main_OnCommand(40421, 0) -- Item: Select all items in track
    
    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
    
    local items = {}
    for i = 0, reaper.CountTrackMediaItems(tr) - 1 do
      local item = reaper.GetTrackMediaItem(tr, i)
      reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
      reaper.SetOnlyTrackSelected(stemTrack)
      reaper.SetMediaItemSelected(item, 1)
      reaper.Main_OnCommand(40290, 0) -- Time selection: Set time selection to items
      reaper.Main_OnCommand(40421, 0) -- Item: Select all items in track
      reaper.Main_OnCommand(40061, 0) -- Item: Split items at time selection
      
      item = reaper.GetSelectedMediaItem(0, 0)
      table.insert(items, item)
    end
    
    reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items

    for i, item in pairs(items) do
      reaper.SetMediaItemSelected(item, 1)
    end
    
    for i = 0, reaper.CountTrackMediaItems(stemTrack) - 1 do
      local item = reaper.GetTrackMediaItem(stemTrack, i)
      if(item) then -- ???
        if(reaper.IsMediaItemSelected(item) == false) then
          reaper.DeleteTrackMediaItem(stemTrack, item)
        end
      end
    end
    
    reaper.GetSet_LoopTimeRange(true, false, timeselstart, timeselend, false)
  end
  
  if(cbHideTrack.value == 1) then
    reaper.SetOnlyTrackSelected(tr)
    reaper.Main_OnCommand(41593, 0) -- Track: Hide tracks in TCP and mixer
  end
  
  reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", 'offline_'..track_name, true)
  
  reaper.UpdateArrange()
  reaper.Undo_EndBlock(script_title..": Set all FX offline and render to new track", 0)
  reaper.PreventUIRefresh(-1)
  gfx.quit()
end

canRestore = false
if(is_offline_track == true and tr ~= nil) then canRestore = true end
btnRestore = Button:new(15,185,270,40)
btnRestore.label = 'Restore track'
btnRestore.enabled = canRestore
btnRestore.onClick = function()
  reaper.PreventUIRefresh(1)
  reaper.Undo_BeginBlock()
  
  reaper.SetMediaTrackInfo_Value(tr, 'B_SHOWINMIXER', 1)
  reaper.SetMediaTrackInfo_Value(tr, 'B_SHOWINTCP', 1)
  
  reaper.SetMediaTrackInfo_Value(tr,"B_MUTE",0)
  reaper.SetOnlyTrackSelected(tr)
  reaper.Main_OnCommand(40536, 0) -- Track: Set all FX online for selected tracks
  
  local color = reaper.GetTrackColor(tr)
  if(color == 16777216) then
    reaper.Main_OnCommand(40359, 0) -- Track: Set to default color
  end

  for i = 0, reaper.CountTrackMediaItems(tr) - 1 do
    reaper.SetMediaItemInfo_Value(reaper.GetTrackMediaItem(tr, i), 'B_MUTE', 0)
  end
  
  local _,name = reaper.GetTrackName(tr)
  reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", string.sub(name, 9, string.len(name)), 1)
  
  reaper.TrackList_AdjustWindows(true)
  reaper.UpdateArrange()
  reaper.Undo_EndBlock(script_title..": Restore track", 0)
  reaper.PreventUIRefresh(-1)
  
  gfx.quit()
end

btnShowOffileTracks = Button:new(15,232,270,40)
btnShowOffileTracks.label = 'Show all offline tracks'
btnShowOffileTracks.onClick = function()
  for i = 0, reaper.CountTracks(0) - 1 do
    local tr = reaper.GetTrack(0, i)
    local _,track_name = reaper.GetTrackName(tr)
    if(string.sub(track_name, 1, 8) == 'offline_') then
      reaper.SetMediaTrackInfo_Value(tr, 'B_SHOWINMIXER', 1)
      reaper.SetMediaTrackInfo_Value(tr, 'B_SHOWINTCP', 1)
    end
  end
  reaper.TrackList_AdjustWindows(true)
end

btnHideOffileTracks = Button:new(15,279,270,40)
btnHideOffileTracks.label = 'Hide all offline tracks'
btnHideOffileTracks.onClick = function()
  for i = 0, reaper.CountTracks(0) - 1 do
    local tr = reaper.GetTrack(0, i)
    local _,track_name = reaper.GetTrackName(tr)
    if(string.sub(track_name, 1, 8) == 'offline_') then
      reaper.SetMediaTrackInfo_Value(tr, 'B_SHOWINMIXER', 0)
      reaper.SetMediaTrackInfo_Value(tr, 'B_SHOWINTCP', 0)
    end
  end
  reaper.TrackList_AdjustWindows(true)
end

ButtonTable = {btnRender, btnRestore, btnShowOffileTracks, btnHideOffileTracks}

----------------------------------------- GFX -----------------------------------------

function draw()
  for _,item in pairs(LabelTable) do item:draw() end
  for _,item in pairs(ButtonTable) do item:draw() end
  for _,item in pairs(CheckBoxTable) do item:draw() end
end

function init()
  local x,y = 300,200

  gfx.clear = 1315860
  gfx.init(script_title, wnd_w, wnd_h, 0 ,x, y)
end

function mainloop()
  if gfx.mouse_cap&1==1 and last_mouse_cap&1==0  or   -- L
     gfx.mouse_cap&2==2 and last_mouse_cap&2==0  then -- R
     mouse_ox, mouse_oy = gfx.mouse_x, gfx.mouse_y 
  end

  draw()

  last_mouse_cap = gfx.mouse_cap
  last_x, last_y = gfx.mouse_x, gfx.mouse_y

  char = gfx.getchar()
  if char==32 then reaper.Main_OnCommand(40044, 0) end -- Transport: Play/stop 
  if char == -1 or char == 27 then 
    --local _,xpos,ypos,_,_ = gfx.dock(-1, 0, 0, 0, 0)
    reaper.SetExtState(script_title, "cbItemsMode", tostring(cbItemsMode.value), 1)
    reaper.SetExtState(script_title, "cbHideTrack", tostring(cbHideTrack.value), 1)
    reaper.SetExtState(script_title, "cbColorize", tostring(cbColorize.value), 1)
    gfx.quit()
  else
    reaper.defer(mainloop)
  end

  gfx.update()
end

init()
mainloop()
