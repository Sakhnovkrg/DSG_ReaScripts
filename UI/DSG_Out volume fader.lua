--[[
Description: DSG_Out volume fader
Version: 1.0
Author: DSG
--]]

function msg(m)
  return reaper.ShowConsoleMsg(tostring(m) .. "\n")
end

SCRIPT_TITLE  = "DSG_Out volume fader"

BG_COLOR = "333333"

PRIMARY_COLOR   = "11bc99" -- #11bc99
SECONDARY_COLOR = "2d4f47" -- #2d4f47

TEXT_COLOR = "ffffff"
TEXT_SHADOW_COLOR = "000000"
TEXT_SHADOW_OPACITY = 0.7
VERTICAL_CENTERED = true
RADIUS = 6
PADDING_X = 10
PADDING_Y = 10
FONT_SIZE = 12

-- use this for text vertical align balance
TEXT_FIX = 0
if(VERTICAL_CENTERED) then
  TEXT_FIX = -1
end

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

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function percent(percent,maxvalue)
  if tonumber(percent) and tonumber(maxvalue) then
    return (maxvalue*percent)/100
  end
  return false
end

function hex2rgb(hex)
    hex = hex:gsub("#","")
    return tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))
end

function get_color(hex)
    local r,g,b = hex2rgb(hex)
    return r/255, g/255, b/255
end

function draw_gui()
  master = reaper.GetMasterTrack(0)

  val = reaper.GetTrackSendInfo_Value(master, 1, 0, "D_VOL")
  val = round(val, 2)

  if(val > 1) then
    val = 1
  end
  if(val < 0) then
    val = 0
  end
 
  val = val*100
  
  --local RADIUS = 6 --(gfx.h - PADDING_Y * 2)/2
  if(VERTICAL_CENTERED) then
    PADDING_Y = gfx.h/2 - RADIUS
  end

  local width = gfx.w - PADDING_X * 2
  local valPercent = width * val / 100
  
  local r,g,b = get_color(PRIMARY_COLOR)
  local r2,g2,b2 = get_color(SECONDARY_COLOR)

  local primary = {
    r=r2*(100-val)/100.0 + r*(val)/100.0, 
    g=g2*(100-val)/100.0 + g*(val)/100.0,
    b=b2*(100-val)/100.0 + b*(val)/100.0,
    a=1
  }

  local secondary = {
    r=r2, 
    g=g2,
    b=b2,
    a=1
  }
  
  local r,g,b = get_color(BG_COLOR)
  gfx.set(r,g,b,1)
  gfx.rect(0,0,gfx.w,gfx.h,1)

  gfx.set(secondary.r,secondary.g,secondary.b,1) -- secondary
  gfx.rect(PADDING_X+RADIUS,PADDING_Y,width-RADIUS*2,RADIUS*2+1,1)

  gfx.set(secondary.r,secondary.g,secondary.b,1) -- secondary
  
  gfx.circle(width+PADDING_X-RADIUS,PADDING_Y+RADIUS,RADIUS,1)

  gfx.set(primary.r,primary.g,primary.b,primary.a) -- primary
  gfx.circle(PADDING_X+RADIUS,PADDING_Y+RADIUS,RADIUS,1)
  
  gfx.set(primary.r,primary.g,primary.b,primary.a) -- primary
  gfx.rect(PADDING_X+RADIUS,PADDING_Y,valPercent - RADIUS*2,RADIUS*2+1,1)
  
  gfx.set(primary.r,primary.g,primary.b,primary.a) -- primary
  if(valPercent-RADIUS*2+RADIUS+PADDING_X < PADDING_X + RADIUS) then
    v=PADDING_X + RADIUS
  else
    v=valPercent-RADIUS*2+RADIUS+PADDING_X
  end

  gfx.circle(v,PADDING_Y+RADIUS,RADIUS,1)
  
  local y = PADDING_Y + FONT_SIZE + RADIUS*2 + TEXT_FIX
  if(VERTICAL_CENTERED) then
    y = gfx.h + FONT_SIZE/2 - RADIUS/2 + TEXT_FIX
  end
  
  
  local r,g,b = get_color(TEXT_SHADOW_COLOR)
  gfx.set(0,0,0,TEXT_SHADOW_OPACITY)
  gfx.x = 0
  gfx.drawstr(math.floor(val)..'%', 1 | 4, gfx.w+2, y+2)

  local r,g,b = get_color(TEXT_COLOR)
  gfx.set(r,g,b,1)
  gfx.x = 0
  gfx.drawstr(math.floor(val).. '%', 1 | 4, gfx.w, y)

  d,x,y,w,h=gfx.dock(-1,0,0,0,0)
  reaper.SetExtState(SCRIPT_TITLE,"dock",d,true)
  
  if(mouse.last_LMB_state) then
    local mousex = gfx.mouse_x
    local flag = true
    if(mousex > gfx.w - PADDING_X) then
      reaper.SetTrackSendInfo_Value(master, 1, 0, "D_VOL", 1)
      flag = false
    end
    if(mousex < PADDING_X) then
      reaper.SetTrackSendInfo_Value(master, 1, 0, "D_VOL", 0)
      flag = false
    end
    if(flag) then
      v = (gfx.mouse_x - PADDING_X) / (gfx.w - PADDING_X * 2) * 100 * 0.01
      reaper.SetTrackSendInfo_Value(master, 1, 0, "D_VOL", v)
    end
  end
end

local gui = {}

function init()
  gui.settings = {}
  gui.settings.font_size = FONT_SIZE
  
  gfx.init(SCRIPT_TITLE, 270, PADDING_Y*2+RADIUS*2, 
    tonumber(reaper.GetExtState(SCRIPT_TITLE,"dock")) or 0,
    tonumber(reaper.GetExtState(SCRIPT_TITLE,"wndx")) or 300,
    tonumber(reaper.GetExtState(SCRIPT_TITLE,"wndy")) or 300
  )

  gfx.setfont(1,"Arial", gui.settings.font_size)
  gfx.clear = 3355443
  mainloop()
end

function mainloop()
  local LB_DOWN = mouse.lb_down()
  local RB_DOWN = mouse.rb_down()
  local mx, my = gfx.mouse_x, gfx.mouse_y
 
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

  draw_gui()
 
  gfx.update()
  if gfx.getchar() >= 0 then reaper.defer(mainloop) end
end

init()

