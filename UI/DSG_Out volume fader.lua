--[[
Description: DSG_Out volume fader
Version: 1.3
Author: DSG
--]]
function dump(a)local b,c,d={},{},{}local e=1;local f="{\n"while true do local g=0;for h,i in pairs(a)do g=g+1 end;local j=1;for h,i in pairs(a)do if b[a]==nil or j>=b[a]then if string.find(f,"}",f:len())then f=f..",\n"elseif not string.find(f,"\n",f:len())then f=f.."\n"end;table.insert(d,f)f=""local k;if type(h)=="number"or type(h)=="boolean"then k="["..tostring(h).."]"else k="['"..tostring(h).."']"end;if type(i)=="number"or type(i)=="boolean"then f=f..string.rep("\t",e)..k.." = "..tostring(i)elseif type(i)=="table"then f=f..string.rep("\t",e)..k.." = {\n"table.insert(c,a)table.insert(c,i)b[a]=j+1;break else f=f..string.rep("\t",e)..k.." = '"..tostring(i).."'"end;if j==g then f=f.."\n"..string.rep("\t",e-1).."}"else f=f..","end else if j==g then f=f.."\n"..string.rep("\t",e-1).."}"end end;j=j+1 end;if g==0 then f=f.."\n"..string.rep("\t",e-1).."}"end;if#c>0 then a=c[#c]c[#c]=nil;e=b[a]==nil and e+1 or e-1 else break end end;table.insert(d,f)f=table.concat(d)reaper.ShowConsoleMsg(f.."\n")end
function msg(msg) return reaper.ShowConsoleMsg(tostring(msg).."\n")end

function get_script_name()
  return debug.getinfo(1, "S").source:match([[.*[\/](.*)%.lua$]])
end

Config = nil
Startup = nil
script_name = get_script_name()
lasttime = 0
clock = 0
volume = -1
d_vol = -1
window_w = 180
window_h = 40

defaults = {
  paddings = {
    left = 6,
    right = 6,
    top = 12,
    bottom = 12,
  },
  colors = {
    body = '#5f5f5f',
    fill_primary = '#11bc99',
    fill_secondary = '#5f5f5f',
    text = '#ffffff',
    shadow = '#000000',
  },
  text = {
    font_family = 'Arial',
    font_flags = 'b',
    font_size_max = 24,
    font_size_min = 13,
    show = true,
    shadow_opacity = .5,
  },
  style = {
    rounded = true,
  }
}

--------------------------------------------------------------------------------------------------

DSG_Startup = {}
function DSG_Startup:new()
  local obj = {}
  
  function obj:_getScriptFilename()
    return debug.getinfo(1, "S").source:sub(2):match([[^.*[\/](.*.lua)$]])
  end
  
  function obj:_getScriptCommandId()
    local DS = package.config:sub(1,1)
    
    local script_filename = self:_getScriptFilename()
    local reaper_kb_path = reaper.GetResourcePath() .. DS .. "reaper-kb.ini"
    
    local file = io.open(reaper_kb_path, "r")
    local id
    
    for line in file:lines() do
      id = line:match([[^.*%s%d+%s%d+%s(.*)%s]] .. '"Custom: ' .. script_filename  .. '"' .. [[.*$]])
      if id then break end
    end
    
    return id
  end
  
  function obj:_getStartupFilePath()
    local DS = package.config:sub(1,1)
    local rrp = reaper.GetResourcePath() .. DS
    return rrp .. 'Scripts' .. DS .. '__startup.lua'
  end
  
  function obj:add()
    local id = self:_getScriptCommandId()
    if(not id) then return self end

    local script_filename = self:_getScriptFilename()
    local startup_lua_path = self:_getStartupFilePath()
    id = '_' .. id
    
    local file = io.open(startup_lua_path, "r")
    if(file) then
      content = file:read "*a"
      file:close()
      if (content:match(id)) then return self end
    end
    
    local code = '\nreaper.Main_OnCommand(reaper.NamedCommandLookup("' .. id .. '"), -1)' .. ' -- ' .. script_filename

    file = io.open(startup_lua_path, "a")
    file:write(code, "\n")
    file:close()
    
    return self
  end
  
  function obj:remove()
    local id = self:_getScriptCommandId()
    if(not id) then return end
    
    local script_filename = self:_getScriptFilename()
    local startup_lua_path = self:_getStartupFilePath()
    id = '_' .. id
    
    local file = io.open(startup_lua_path, "r")
    if(not file) then return self end

    content = file:read "*a"
    file:close()
    
    content = content:gsub('\n?reaper.Main_OnCommand%(reaper.NamedCommandLookup%("'..id..'".*%.lua', "")

    file = io.open(startup_lua_path, "w")
    file:write(content)
    file:close()
    
    return self
  end
  
  setmetatable(obj, self)
  self.__index = self; return obj
end

--------------------------------------------------------------------------------------------------

DSG_Ini = {}
function DSG_Ini:new(file_path)
  local obj = {}
  obj.file_path = file_path
  
  function obj:load()
    local file = io.open(self.file_path, "r")
    local data = {}
    local section
    
    for line in file:lines() do
      local tempSection = line:match("^%[([^%[%]]+)%]$")
      if (tempSection) then
        section = tonumber(tempSection) and tonumber(tempSection) or tempSection
        data[section] = data[section] or {}
      end
      local param, value = line:match("^([%w|_]+)%s-=%s-(.+)$")
      if (param and value ~= nil) then
        if (tonumber(value)) then
          value = tonumber(value)
        elseif (value == "true") then
          value = true
        elseif (value == "false") then
          value = false
        end
        if (tonumber(param)) then
          param = tonumber(param)
        end
        data[section][param] = value
      end
    end
    
    file:close()
    
    return data
  end
  
  function obj:save(data)
    local file = io.open(self.file_path, "w")
    local contents = ""
    for section, param in pairs(data) do
      contents = contents .. ("[%s]\n"):format(section)
      for key, value in pairs(param) do
        contents = contents .. ("%s=%s\n"):format(key, tostring(value))
      end
      contents = contents .. "\n"
    end
    file:write(contents)
    file:close()
    
    return contents
  end
  
  setmetatable(obj, self)
  self.__index = self; return obj
end

--------------------------------------------------------------------------------------------------

DSG_Config = {} -- requires DSG_Ini
function DSG_Config:new(file_name, defaults)
  local obj = {}
  obj.file_name = file_name
  obj.defaults = defaults
  obj.data = defaults

  function obj:getFilePath()
    local script_path = debug.getinfo(1, "S").source:match([[^@?(.*[\/])[^\/]-$]])
    return script_path .. self.file_name
  end

  function obj:load()
    local config_file_path = self:getFilePath()

    local file = io.open(config_file_path, "r")
    local data

    if (file) then
      file:close()
      self.data = DSG_Ini:new(config_file_path):load()
      return self
    end

    data = self.defaults
    DSG_Ini:new(config_file_path):save(data)
    return self
  end
  
  function obj:save()
    local config_file_path = self:getFilePath()
    DSG_Ini:new(config_file_path):save(self.data)
    return self
  end

  setmetatable(obj, self)
  self.__index = self; return obj
end

--------------------------------------------------------------------------------------------------

local mouse = {
  LB = 1,
  RB = 2,
  CTRL = 4,
  SHIFT = 8,
  ALT = 16,

  cap = function (mask)
          if mask == nil then
            return gfx.mouse_cap end
          return gfx.mouse_cap&mask == mask
        end,
 
  lb_down = function() return gfx.mouse_cap&1 == 1 end,
  rb_down = function() return gfx.mouse_cap&2 == 2 end,

  uptime = 0,
   
  last_x = -1, last_y = -1,
   
  dx = 0, 
  dy = 0,
   
  ox = 0, oy = 0,
  cap_count = 0,
   
  last_LMB_state = false,
  last_RMB_state = false
}

function OnMouseDown(x, y, lmb_down, rmb_down)
  -- LMB clicked
  if not rmb_down and lmb_down and mouse.last_LMB_state == false then
    mouse.last_LMB_state = true
  end
  -- RMB clicked
  if not lmb_down and rmb_down and mouse.last_RMB_state == false then
    mouse.last_RMB_state = true
  end
  mouse.ox, mouse.oy = x, y -- mouse click coordinates
  mouse.cap_count = 0       -- reset mouse capture count
end

function OnMouseUp(x, y, lmb_down, rmb_down)
  mouse.uptime = os.clock()
  mouse.dx = 0
  mouse.dy = 0
  if not lmb_down and mouse.last_LMB_state then mouse.last_LMB_state = false end
  if not rmb_down and mouse.last_RMB_state then mouse.last_RMB_state = false end
end

function OnMouseDoubleClick(x, y)
end

function OnMouseMove(x, y)
  mouse.last_x, mouse.last_y = x, y
  mouse.dx = gfx.mouse_x - mouse.ox
  mouse.dy = gfx.mouse_y - mouse.oy
  mouse.cap_count = mouse.cap_count + 1
end

function percent(percent, maxvalue)
  if (tonumber(percent) and tonumber(maxvalue)) then
    return (maxvalue*percent) / 100
  end
  return false
end

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function bool_to_number(value)
  return value and 1 or 0
end

function is_docked()
  return gfx.dock(-1)&1 == 1
end

function hex_to_rgb(hex)
  local hex = hex:gsub("#","")
  return tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))
end

function get_color(hex)
  local r,g,b = hex_to_rgb(hex)
  return r/255, g/255, b/255
end

function fontflags(str) 
 local v = 0
  
  for a = 1, str:len() do 
    v = v * 256 + string.byte(str, a) 
  end 
  
  return v 
end

function get_os_open_command()
  local commands = {
    {os = "Win", cmd = 'start "" '},
    {os = "OSX", cmd = 'open "" '},
    {os = "Other", cmd = 'xdg-open '},
  }

  local OS = reaper.GetOS()

  for _, v in ipairs(commands) do
    if OS:match(v.os) then return v.cmd end
  end
end

local function roundrect(x, y, w, h, r, antialias, fill)
  local w = math.floor(w)
  local h = math.floor(h)

  if(r == 0) then
    gfx.rect(x, y, w, h)
  else
    local aa = antialias or 1
    fill = fill or 0
    if fill == 0 or false then
      gfx.roundrect(x, y, w, h, r*2, aa)
    elseif h >= 2 * r then
      -- Corners
      
      if(w >= 2 * r) then
        gfx.circle(x + r, y + r, r, 1, aa)           -- top-left
        gfx.circle(x + w - r, y + r, r, 1, aa)       -- top-right
        gfx.circle(x + w - r, y + h - r, r , 1, aa)  -- bottom-right
        gfx.circle(x + r, y + h - r, r, 1, aa)       -- bottom-left
        
        -- Ends
        gfx.rect(x, y + r, r, h - r * 2)
        gfx.rect(x + w - r, y + r, r + 1, h - r * 2)
        
        -- Body + sides
        gfx.rect(x + r, y, w - r * 2, h + 1)
      else
        gfx.rect(x, y+1, w, h-1)
      end
    else
     gfx.rect(x, y, w, h)
    end 
  end
end

function get_volume()
  local master = reaper.GetMasterTrack(0)
  local vol = reaper.GetTrackSendInfo_Value(master, 1, 0, "D_VOL")
  return math.max(math.min(vol, 1), 0)
end

function set_volume(vol)
  if(round(volume, 3) ~= round(vol*100, 3)) then
    local master = reaper.GetMasterTrack(0)
    reaper.SetTrackSendInfo_Value(master, 1, 0, "D_VOL", vol)
    d_vol = reaper.GetTrackSendInfo_Value(master, 1, 0, "D_VOL")
    volume = vol*100
    redraw()
  end
end

function get_slider_x()
  return Config.data.paddings.left
end

function get_slider_y()
  return Config.data.paddings.top
end

function get_slider_w()
  return window_w - Config.data.paddings.left - Config.data.paddings.right
end

function get_slider_h()
  return window_h - Config.data.paddings.top - Config.data.paddings.bottom
end

function get_fill_w()
  return percent(volume, get_slider_w())
end

function draw_body()
  local r,g,b = get_color(Config.data.colors.body)
  gfx.set(r,g,b)
  roundrect(get_slider_x(), get_slider_y(), get_slider_w(), get_slider_h(), bool_to_number(Config.data.style.rounded), 1, 1)
end

function draw_fill()
  local r,g,b = get_color(Config.data.colors.fill_primary)
  local r2,g2,b2 = get_color(Config.data.colors.fill_secondary)
  
  r=r2*(100-volume)/100.0 + r*(volume)/100.0 
  g=g2*(100-volume)/100.0 + g*(volume)/100.0
  b=b2*(100-volume)/100.0 + b*(volume)/100.0

  gfx.set(r,g,b)
  roundrect(get_slider_x(), get_slider_y(), get_fill_w(), get_slider_h(), bool_to_number(Config.data.style.rounded), 1, 1)
end

function get_font_size()
  return math.min(math.max(get_slider_h() / 2, Config.data.text.font_size_min), Config.data.text.font_size_max)
end

function draw_text()
  if(Config.data.text.show) then
    gfx.setfont(1, Config.data.text.font_family, get_font_size(), fontflags(Config.data.text.font_flags))
    
    local str = math.floor(volume, 1)..'%'
    local str_w, str_h = gfx.measurestr(str)
    

    if(Config.data.text.shadow_opacity ~= 0) then
      gfx.x = get_slider_x() + get_slider_w() / 2 - str_w / 2 + 1
      gfx.y = get_slider_y() + get_slider_h() / 2 - str_h / 2 + 1
      local r,g,b = get_color(Config.data.colors.shadow)

      gfx.set(r,g,b,Config.data.text.shadow_opacity)
      gfx.drawstr(str)
    end

    gfx.x = get_slider_x() + get_slider_w() / 2 - str_w / 2
    gfx.y = get_slider_y() + get_slider_h() / 2 - str_h / 2
    
    local r,g,b = get_color(Config.data.colors.text)
    gfx.set(r,g,b)
    gfx.drawstr(str)
  end
end

function clear()
  local r,g,b = reaper.ColorFromNative(reaper.GetThemeColor('col_main_bg2', 0))
  gfx.set(r/255,g/255,b/255)
  gfx.rect(0,0,gfx.w,gfx.h,1)
end

function redraw()
  clear()
  draw_body()
  draw_fill()
  draw_text()
end

function reload_config()
  Config = DSG_Config:new(script_name .. ".ini", defaults):load()
  redraw()
end

function open_config()
  os.execute(get_os_open_command()..'"'..Config:getFilePath()..'"')
end

function reset_config()
  Config.data = defaults
  Config:save()
  redraw()
end

function open_menu()
  gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
  local config_path = Config:getFilePath()

  local menuIndex = gfx.showmenu('Reload config|Edit config ('..config_path..')|Reset config')
  if(menuIndex == 1) then
    reload_config()
  end
  if(menuIndex == 2) then
    open_config()
  end
  if(menuIndex == 3) then
    reset_config()
  end
 
  if(menuIndex == 0) then
    mouse.last_RMB_state = false
  end
end

function mouse_events()
  if(mouse.last_RMB_state) then
    open_menu()
  end
  if(mouse.last_LMB_state and mouse.cap(mouse.LB)) then
    local mousex = gfx.mouse_x
    local flag = true
    
    local vol = (gfx.mouse_x - Config.data.paddings.left) / (gfx.w - Config.data.paddings.left - Config.data.paddings.right) * 100 * 0.01
    vol = math.max(math.min(vol, 1), 0)
    
    set_volume(vol)
  end
  if(mouse.last_LMB_state and mouse.cap(mouse.CTRL)) then
    set_volume(1)
  end
  if(mouse.last_LMB_state and mouse.cap(mouse.SHIFT)) then
    set_volume(.5)
  end
  if(mouse.last_LMB_state and mouse.cap(mouse.ALT)) then
    set_volume(0)
  end
end

function quit()
  local d,x,y,w,h=gfx.dock(-1,0,0,0,0)
  reaper.SetExtState(script_name,"dock",d,true)
  if(is_docked()) then
    Startup:add()
  else
    Startup:remove()
  end
  gfx.quit()
end

function main_loop()
  local LB_DOWN = mouse.lb_down()
  local RB_DOWN = mouse.rb_down()
  local mx, my = gfx.mouse_x, gfx.mouse_y
  
  local newtime=os.time()
  if newtime-lasttime >= 1 then
    clock_hz = clock
    lasttime=newtime
    clock = 0
    
    local vol = get_volume()
    if(d_vol ~= vol) then set_volume(vol) end
  end

  if(gfx.w ~= window_w or gfx.h ~= window_h) then
    window_w = gfx.w
    window_h = gfx.h
    redraw()
  end
  
  if (LB_DOWN and not RB_DOWN) or (RB_DOWN and not LB_DOWN) then
    if (mouse.last_LMB_state == false and not RB_DOWN) or (mouse.last_RMB_state == false and not LB_DOWN) then
      OnMouseDown(mx, my, LB_DOWN, RB_DOWN)
      if mouse.uptime and os.clock() - mouse.uptime < 0.20 then
        OnMouseDoubleClick(mx, my)
      end
    elseif mx ~= mouse.last_x or my ~= mouse.last_y then
      OnMouseMove(mx, my)
    end
  elseif not LB_DOWN and mouse.last_RMB_state or not RB_DOWN and mouse.last_LMB_state then
    OnMouseUp(mx, my, LB_DOWN, RB_DOWN)
  end
  
  clock = clock + 1
  mouse_events()
  gfx.update()
  
  local char = gfx.getchar()
  if char ~= 27 and char ~= -1 then
    reaper.defer(main_loop)
  end
end

function init(window_w, window_h, window_x, window_y, docked)
  Config = DSG_Config:new(script_name .. ".ini", defaults):load()
  Startup = DSG_Startup:new()

  Startup:remove()

  gfx.init(script_name, window_w, window_h, tonumber(reaper.GetExtState(script_name, "dock")) or 0, 300, 300)
  main_loop()
  set_volume(get_volume())
end

init(window_w, window_h, 150, 150)

reaper.atexit(function()
  quit()
end)
