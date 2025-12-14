--[[
Description: DSG_Easy Theme Tweaker
Version: 0.1
Author: DSG
--]]

local ui = {
  padding = 12, lineHeight = 32, accentColor = {1, 1, 0},
  groupTitleOffset = 8, groupBottomOffset = 20,
  windowHeight = 600, windowWidth = 400,
  colorBoxWidth = 40, colorBoxHeight = 20, previewHeight = 70,
  buttonGap = 12, dmTopGap = 16, rowGap = 8, btnGap = 6, alphaTopGap = 14,
  infoButtonOffset = 12, 
  scrollBarWidth = 8,
  scrollBarColor = {0.3, 0.3, 0.3},
  scrollBarHandleColor = {0.6, 0.6, 0.6},
  scrollBarHoverColor = {0.8, 0.8, 0.8},
}

local groups = {
  {
    label = "Arrange",
    items = {
      { vars = {"col_tr1_bg", "col_arrangebg"}, label = "Track Odd" },
      { vars = {"selcol_tr1_bg", "arrange_vgrid"}, label = "Track Selected Odd" },
      { vars = {"col_tr2_bg"}, label = "Track Even" },
      { vars = {"selcol_tr2_bg"}, label = "Track Selected Even" },
      { vars = {"col_tr1_divline", "col_tr2_divline"}, label = "Track Dividers" },
      { vars = {"col_envlane1_divline", "col_envlane2_divline"}, label = "Envelope Dividers" },
      { vars = {"col_gridlines2"}, label = "Grid (measures)", dmKeys = {"col_gridlines2dm"} },
      { vars = {"col_gridlines3"}, label = "Grid (beats)", dmKeys = {"col_gridlines3dm"} },
      { vars = {"col_gridlines"}, label = "Grid (sub-beats)", dmKeys = {"col_gridlines1dm"} },
      { vars = {"playcursor_color"}, label = "Play Cursor", dmKeys = {"playcursor_drawmode"} },
      { vars = {"col_cursor", "col_cursor2"}, label = "Edit Cursor" },
      { vars = {"col_tl_bgsel"}, label = "Time Selection", dmKeys = {"timesel_drawmode"} },
      { vars = {"areasel_fill"}, label = "Razor Fill", dmKeys = {"areasel_drawmode"} },
      { vars = {"areasel_outline"}, label = "Razor Outline", dmKeys = {"areasel_outlinemode"} },
    }
  },
  {
    label = "Timeline",
    items = {
      { vars = {"col_tl_bg"}, label = "Background" },
      { vars = {"col_tl_bgsel2"}, label = "Background Selection" },
      { vars = {"col_tl_fg"}, label = "Foreground Primary" },
      { vars = {"col_tl_fg2"}, label = "Foreground Secondary" },
    }
  },
  {
    label = "Mediaitem",
    items = {
      { vars = {"col_mi_bg", "col_mi_bg2", "col_tr1_itembgsel", "col_tr2_itembgsel"}, label = "Background" },
      { vars = {"col_tr1_peaks", "col_tr2_peaks", "col_tr1_ps2", "col_tr2_ps2"}, label = "Content" },
      { vars = {"col_mi_label_float"}, label = "Label" },
      { vars = {"col_mi_label_float_sel"}, label = "Label Selected" },
    }
  },
  {
    label = "MIDI Editor",
    items = {
      { vars = {"midi_trackbg1", "midi_inline_trackbg1"}, label = "White" },
      { vars = {"midi_selpitch1"}, label = "White Active" },
      { vars = {"midi_trackbg_outer1"}, label = "White Outbound" },
      { vars = {"midi_trackbg2", "midi_inline_trackbg2"}, label = "Black" },
      { vars = {"midi_selpitch2"}, label = "Black Active" },
      { vars = {"midi_trackbg_outer2"}, label = "Black Outbound" },
      { vars = {"midioct", "midioct_inline", "midi_gridhc"}, label = "Octave Divider" },
      { vars = {"midi_grid2"}, label = "Grid (measures)", dmKeys = {"midi_griddm2"} },
      { vars = {"midi_grid3"}, label = "Grid (beats)", dmKeys = {"midi_griddm3"} },
      { vars = {"midi_grid1"}, label = "Grid (sub-beats)", dmKeys = {"midi_griddm1"} },
      { vars = {"midi_gridh"}, label = "Grid (horizontal)", dmKeys = {"midi_gridhdm"} },
      { vars = {"midi_editcurs"}, label = "Edit Cursor" },
      { vars = {"midi_rulerbg"}, label = "Ruler Background" },
      { vars = {"midi_rulerfg"}, label = "Ruler Text" },
      { vars = {"midi_noteon_flash"}, label = "Note Highlight"},
      { vars = {"midi_selbg"}, label = "Time Selection", dmKeys = {"midi_selbg_drawmode"} },
    }
  },
  {
    label = "Envelopes",
    items = {
      { vars = {"col_env1", "col_env2", "env_trim_vol", "col_env7", "col_env9", "col_env11"}, label = "Volume" },
      { vars = {"col_env3", "col_env4", "col_env8", "col_env10", "col_env12"}, label = "Pan" },
      { vars = {"env_track_mute", "env_sends_mute"}, label = "Mute" },
      { vars = {"col_env5"}, label = "Master Playrate" },
      { vars = {"col_env6"}, label = "Master Tempo" },
      { vars = {"col_env13", "col_env14", "col_env15", "col_env16"}, label = "FX Parameters" },
      { vars = {"env_item_vol"}, label = "Take Volume" },
      { vars = {"env_item_pan"}, label = "Take Pan" },
      { vars = {"env_item_mute"}, label = "Take Mute" },
      { vars = {"env_item_pitch"}, label = "Take Pitch" },
    }
  },
}

-- ===== КЭШ И ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ =====
local lineIndexCache = {} -- кэш для индексов строк
local colorCache = {} -- кэш для цветов
local textMeasureCache = {} -- кэш для размеров текста

-- ===== УТИЛИТЫ =====
local Utils = {}

local function getDmKeys(item)
  if item.dmKeys and #item.dmKeys > 0 then return item.dmKeys end
  return nil
end

function Utils.hex2reaper(hex)
  hex = hex:gsub("#","")
  if #hex ~= 6 then return nil end
  local r, g, b = hex:match("(%x%x)(%x%x)(%x%x)")
  if not r then return nil end
  r, g, b = tonumber(r,16), tonumber(g,16), tonumber(b,16)
  return (b<<16) | (g<<8) | r
end

function Utils.reaper2hex(val)
  return string.format("#%02X%02X%02X", val & 0xFF, (val>>8)&0xFF, (val>>16)&0xFF)
end

function Utils.applyBrightness(r, g, b, mod)
  local k = (100 + mod) / 100
  local function clampColor(x) 
    return math.floor(math.min(255, math.max(0, x * k))) 
  end
  return clampColor(r), clampColor(g), clampColor(b)
end

function Utils.clamp(v, a, b) 
  return math.max(a, math.min(b, v)) 
end

function Utils.extractRGB(c) 
  return c & 0xFF, (c>>8)&0xFF, (c>>16)&0xFF 
end

-- ===== ФАЙЛОВЫЕ ОПЕРАЦИИ =====
local FileOps = {}

function FileOps.readAllText(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  return content
end

function FileOps.splitLines(text)
  local lines = {}
  for line in (text.."\n"):gmatch("([^\r\n]*)\r?\n") do
    lines[#lines + 1] = line
  end
  return lines
end

function FileOps.joinLines(lines) 
  return table.concat(lines, "\n") .. "\n" 
end

-- ===== THEME MANAGER =====
local Theme = {}
Theme.lines = nil
Theme.path = nil
Theme.text = nil

function Theme.readCurrentTheme()
  local fn = reaper.GetLastColorThemeFile()
  
  local errorMsg = [[Cannot read current theme file (possibly zipped theme).

TO FIX THIS:
1. Go to Actions > Show action list... (ctrl + ?)
2. Search for: "Theme development: Show theme tweak/configuration window" (type "tweak")
3. Run this action (double-click)
4. In the opened window, click "Save theme..." button
5. Save as a .ReaperTheme file
6. Run this script again
]]
  
  -- Проверяем, что файл существует и читается
  if not fn or fn == "" then
    reaper.ShowMessageBox(errorMsg, "Setup Required", 0)
    return nil
  end

  -- Проверяем расширение файла
  if not fn:lower():match("%.reapertheme$") then
    reaper.ShowMessageBox(errorMsg, "Setup Required", 0)
    return nil
  end
  
  -- Безопасная попытка чтения файла
  local ok, text = pcall(FileOps.readAllText, fn)
  if not ok or not text then
    reaper.ShowMessageBox(errorMsg, "Setup Required", 0)
    return nil
  end
  
  Theme.path = fn
  Theme.text = text  
  Theme.lines = FileOps.splitLines(text)
  lineIndexCache = {}
  return true
end

function Theme.getLineIndex(lines)
  if next(lineIndexCache) == nil then
    for i, line in ipairs(lines) do
      local key = line:match("^%s*([%w_]+)%s*=")
      if key then
        lineIndexCache[key] = i
      end
    end
  end
  return lineIndexCache
end

function Theme.getKeyValue(key)
  if not Theme.lines then return nil end
  local idx = Theme.getLineIndex(Theme.lines)[key]
  if not idx then return nil end
  return Theme.lines[idx]:match("=%s*([^%s]+)%s*$")
end

function Theme.collectPatch(dmOverride)
  local patch = {}

  -- цвета
  for _, g in ipairs(groups) do
    for _, item in ipairs(g.items) do
      if item.color then
        local value = Utils.hex2reaper(item.color)
        if value then
          for _, name in ipairs(item.vars) do
            patch[name] = tostring(value)
          end
        end
      end
    end
  end

  -- DM-ключи
  for _, g in ipairs(groups) do
    for _, item in ipairs(g.items) do
      local keys = getDmKeys(item)
      if keys then
        if dmOverride and dmOverride.matchVar == item.vars[1] then
          -- Применяем новое значение ко всем ключам этого item
          for _, k in ipairs(keys) do
            patch[k] = tostring(dmOverride.value)
          end
        else
          -- Просто тащим текущие значения из файла, чтобы не затереть
          for _, k in ipairs(keys) do
            local currentValue = Theme.getKeyValue(k)
            if currentValue then
              patch[k] = currentValue
            end
          end
        end
      end
    end
  end

  return patch
end

function Theme.saveAndReload(patch)
  if not Theme.lines or not Theme.path then return end
  
  local idx = Theme.getLineIndex(Theme.lines)
  for key, value in pairs(patch) do
    if idx[key] then
      Theme.lines[idx[key]] = key .. "=" .. value
    else
      Theme.lines[#Theme.lines + 1] = key .. "=" .. value
    end
  end
  
  local file = io.open(Theme.path, "w")
  if file then
    file:write(FileOps.joinLines(Theme.lines))
    file:close()
    reaper.OpenColorThemeFile(Theme.path)
  else
    reaper.ShowMessageBox("Can't write theme:\n" .. Theme.path, "Error", 0)
  end
end

-- ===== DM СИСТЕМА =====
local DM = {}
DM.MODES = {
  [0x00] = "Normal", [0x01] = "Add", [0x02] = "Dodge",
  [0x03] = "Multiply", [0x04] = "Overlay", [0xFE] = "HSV adj",
}

function DM.decode(value)
  local mode = value & 0xFF
  local hi = (value >> 8) & 0xFFFF
  local n = hi - 0x0200
  if n < 0 then n = 0 elseif n > 256 then n = 256 end
  return mode, n / 256.0, n, hi
end

function DM.encode(mode, alpha)
  local n = math.floor(alpha * 256 + 0.5)
  if n < 0 then n = 0 elseif n > 256 then n = 256 end
  local hi = 0x0200 + n
  return ((hi << 8) | (mode & 0xFF)), n
end

-- ===== СОСТОЯНИЕ =====
local State = {
  mode = "main",
  selected = nil,
  hasSWS = reaper.APIExists("CF_GetClipboard", "") and reaper.APIExists("CF_SetClipboard", ""),
  lmb = false, rmb = false,
  justLPress = false, justLRelease = false, justRPress = false,
  activeSlider = nil,
  infoButton = nil,
  -- скроллинг
  scrollY = 0, -- смещение скролла
  maxScrollY = 0, -- максимальное значение скролла
  contentHeight = 0, -- высота контента
  scrollBarHover = false, -- наведение на скроллбар
  scrollBarDragging = false, -- перетаскивание скроллбара
  scrollBarDragStart = 0, -- начальная позиция для drag
  picker = {
    r = 0, g = 0, b = 0, brightness = 0,
    target = nil, original = nil, justOpened = false,
    defaultR = 0, defaultG = 0, defaultB = 0, defaultBrightness = 0,
    isDM = false, dmMode = 0x00, dmAlpha = 0.0,
    dmOrigMode = 0x00, dmOrigN = 0,
    fileOrigColor = nil,
    -- скроллинг в пикере
    scrollY = 0,
    maxScrollY = 0,
    contentHeight = 0,
  }
}

-- ===== INFO СИСТЕМА =====
local Info = {}

function Info.showHelpDialog()
  local helpText = [[=== MAIN WINDOW ===
• Left click a color — select
• Left click again — open editor
• Right click a color — actions menu
• Right click empty area — menu for all colors

=== EDITOR ===
• Mouse wheel on sliders — fine adjustment
• Enter / Ctrl+S — apply
• ESC / Cancel — discard changes
• Reset — revert to last saved values
• Apply — save to theme

=== HOTKEYS ===
• Ctrl+C — copy HEX color
• Ctrl+V — paste HEX color
(works for the selected color or inside the editor)

Version: 0.1
Created by Alexandr Sakhnov
]]

  reaper.ShowMessageBox(helpText, "DSG_Easy Theme Tweaker", 0)
end

-- ===== СКРОЛЛИНГ =====
local Scroll = {}

function Scroll.updateMainContent()
  local contentHeight = ui.padding + ui.infoButtonOffset
  for _, group in ipairs(groups) do
    contentHeight = contentHeight + gfx.texth + ui.groupTitleOffset + 
                   #group.items * ui.lineHeight + ui.groupBottomOffset
  end
  
  State.contentHeight = contentHeight
  State.maxScrollY = math.max(0, contentHeight - gfx.h)
  State.scrollY = math.min(State.scrollY, State.maxScrollY)
end

function Scroll.updatePickerContent()
  local picker = State.picker
  local contentHeight = ui.padding + ui.previewHeight + 15 + 40 * 4 + 40 -- базовые элементы
  
  if picker.isDM then
    contentHeight = contentHeight + ui.dmTopGap + 30 + ui.alphaTopGap + 40 -- DM контролы
  end
  
  contentHeight = contentHeight + ui.padding * 3 + 30 -- кнопки
  
  picker.contentHeight = contentHeight
  picker.maxScrollY = math.max(0, contentHeight - gfx.h)
  picker.scrollY = math.min(picker.scrollY, picker.maxScrollY)
end

function Scroll.handleWheel()
  if gfx.mouse_wheel ~= 0 then
    local wheelDelta = gfx.mouse_wheel * -1 -- инвертируем и масштабируем
    
    if State.mode == "main" then
      State.scrollY = Utils.clamp(State.scrollY + wheelDelta, 0, State.maxScrollY)
    else
      local picker = State.picker
      picker.scrollY = Utils.clamp(picker.scrollY + wheelDelta, 0, picker.maxScrollY)
    end
    
    gfx.mouse_wheel = 0
  end
end

function Scroll.isScrollBarVisible()
  if State.mode == "main" then
    return State.maxScrollY > 0
  else
    return State.picker.maxScrollY > 0
  end
end

function Scroll.getScrollBarRect()
  if not Scroll.isScrollBarVisible() then return nil end
  
  local scrollY, maxScrollY, contentHeight
  if State.mode == "main" then
    scrollY, maxScrollY, contentHeight = State.scrollY, State.maxScrollY, State.contentHeight
  else
    local picker = State.picker
    scrollY, maxScrollY, contentHeight = picker.scrollY, picker.maxScrollY, picker.contentHeight
  end
  
  local barX = gfx.w - ui.scrollBarWidth
  local barY = 0
  local barW = ui.scrollBarWidth
  local barH = gfx.h
  
  -- Размер ручки пропорционален видимой области
  local handleHeight = math.max(20, (gfx.h / contentHeight) * barH)
  local handleY = (scrollY / maxScrollY) * (barH - handleHeight)
  
  return {
    barX = barX, barY = barY, barW = barW, barH = barH,
    handleX = barX, handleY = handleY, handleW = barW, handleH = handleHeight
  }
end

function Scroll.drawScrollBar()
  local rect = Scroll.getScrollBarRect()
  if not rect then return end
  
  -- Фон скроллбара
  gfx.set(table.unpack(ui.scrollBarColor))
  gfx.rect(rect.barX, rect.barY, rect.barW, rect.barH, 1)
  
  -- Ручка скроллбара
  local handleColor = State.scrollBarHover and ui.scrollBarHoverColor or ui.scrollBarHandleColor
  gfx.set(table.unpack(handleColor))
  gfx.rect(rect.handleX, rect.handleY, rect.handleW, rect.handleH, 1)
end

function Scroll.handleScrollBarInput()
  local rect = Scroll.getScrollBarRect()
  if not rect then return end
  
  local mx, my = gfx.mouse_x, gfx.mouse_y
  local inScrollBar = (mx >= rect.barX and mx <= rect.barX + rect.barW and 
                      my >= rect.barY and my <= rect.barY + rect.barH)
  
  State.scrollBarHover = inScrollBar
  
  -- Начало перетаскивания
  if State.justLPress and inScrollBar then
    State.scrollBarDragging = true
    State.scrollBarDragStart = my
  end
  
  -- Перетаскивание
  if State.scrollBarDragging and State.lmb then
    local deltaY = my - State.scrollBarDragStart
    local scrollableHeight = rect.barH - rect.handleH
    local scrollRatio = deltaY / scrollableHeight
    
    if State.mode == "main" then
      State.scrollY = Utils.clamp(State.scrollY + scrollRatio * State.maxScrollY, 0, State.maxScrollY)
    else
      local picker = State.picker
      picker.scrollY = Utils.clamp(picker.scrollY + scrollRatio * picker.maxScrollY, 0, picker.maxScrollY)
    end
    
    State.scrollBarDragStart = my
  end
  
  -- Конец перетаскивания
  if State.justLRelease then
    State.scrollBarDragging = false
  end
end

-- ===== UI СИСТЕМА =====
local UI = {}

local function updateAllUI()
  local hwnd = reaper.MIDIEditor_GetActive()
  if hwnd then
    reaper.MIDIEditor_OnCommand(hwnd, 1012)
    reaper.MIDIEditor_OnCommand(hwnd, 1011)
  end
  reaper.UpdateArrange()
  reaper.UpdateTimeline()
end

function UI.measureText()
  if next(textMeasureCache) ~= nil then
    return textMeasureCache.maxText, textMeasureCache.textHeight
  end
  
  gfx.init("measure", 0, 0)
  local maxText, textHeight = 0, gfx.texth
  
  for _, grp in ipairs(groups) do
    for _, item in ipairs(grp.items) do
      local width = gfx.measurestr(item.label)
      if width > maxText then maxText = width end
    end
  end
  gfx.quit()
  
  textMeasureCache.maxText = maxText
  textMeasureCache.textHeight = textHeight
  return maxText, textHeight
end

function UI.calculateWindowSize(maxText, textHeight)
  local width = math.max(
    ui.padding + maxText + 20 + ui.colorBoxWidth + ui.padding + 60, -- +60 для кнопки Info
    ui.windowWidth
  )
  
  return width, ui.windowHeight
end

function UI.drawButton(x, y, w, h, label, hover, accent, enabled)
  local br, bg, bb = 0.2, 0.2, 0.2
  local tr, tg, tb = 1, 1, 1
  
  if not enabled then
    br, bg, bb = 0.12, 0.12, 0.12
    tr, tg, tb = 0.5, 0.5, 0.5
  else
    if accent then
      local ar, ag, ab = table.unpack(ui.accentColor)
      local factor = hover and 0.55 or 0.35
      br, bg, bb = ar * factor, ag * factor, ab * factor
      tr, tg, tb = ar, ag, ab
    elseif hover then
      br, bg, bb = 0.35, 0.35, 0.35
    end
  end
  
  gfx.set(br, bg, bb, 1)
  gfx.rect(x, y, w, h, 1)
  gfx.set(tr, tg, tb, 1)
  
  local textWidth, textHeight = gfx.measurestr(label)
  gfx.x, gfx.y = x + (w - textWidth) / 2, y + (h - textHeight) / 2
  gfx.drawstr(label)
end

function UI.getButtonSize(label)
  local w, h = gfx.measurestr(label)
  return w + 16, h + 8
end

function UI.slider(id, x, y, label, value, minValue, maxValue, width)
  minValue = minValue or 0
  maxValue = maxValue or 255
  width = width or 200
  
  gfx.x, gfx.y = x, y
  gfx.set(1, 1, 1, 1)
  gfx.drawstr(string.format("%s: %d", label, value))
  
  local sliderY = y + 15
  local sliderHeight = 12
  gfx.rect(x, sliderY, width, sliderHeight, 0)
  
  local fraction = (value - minValue) / (maxValue - minValue)
  gfx.rect(x, sliderY, fraction * width, sliderHeight, 1)
  
  local mx, my = gfx.mouse_x, gfx.mouse_y
  local inside = (mx >= x and mx <= x + width and my >= sliderY and my <= sliderY + sliderHeight)
  
  if State.justLPress and inside then
    State.activeSlider = id
  end
  
  if State.activeSlider == id and State.lmb then
    local newFraction = Utils.clamp((mx - x) / width, 0, 1)
    value = math.floor(minValue + newFraction * (maxValue - minValue))
  end
  
  if State.justLRelease and State.activeSlider == id then
    State.activeSlider = nil
  end
  
  if inside and gfx.mouse_wheel ~= 0 then
    local delta = (gfx.mouse_wheel > 0) and 1 or -1
    value = Utils.clamp(value + delta, minValue, maxValue)
    gfx.mouse_wheel = 0
  end
  
  return value
end

function UI.sliderIntLabel(id, x, y, labelText, intValue, minValue, maxValue, width)
  minValue = minValue or 0
  maxValue = maxValue or 256
  width = width or 200
  
  gfx.x, gfx.y = x, y
  gfx.set(1, 1, 1, 1)
  gfx.drawstr(labelText)
  
  local sliderY = y + 15
  local sliderHeight = 12
  gfx.rect(x, sliderY, width, sliderHeight, 0)
  
  local fraction = (intValue - minValue) / (maxValue - minValue)
  gfx.rect(x, sliderY, fraction * width, sliderHeight, 1)
  
  local mx, my = gfx.mouse_x, gfx.mouse_y
  local inside = (mx >= x and mx <= x + width and my >= sliderY and my <= sliderY + sliderHeight)
  
  if State.justLPress and inside then
    State.activeSlider = id
  end
  
  if State.activeSlider == id and State.lmb then
    local newFraction = Utils.clamp((mx - x) / width, 0, 1)
    intValue = math.floor(minValue + newFraction * (maxValue - minValue) + 0.5)
  end
  
  if State.justLRelease and State.activeSlider == id then
    State.activeSlider = nil
  end
  
  if inside and gfx.mouse_wheel ~= 0 then
    local delta = (gfx.mouse_wheel > 0) and 1 or -1
    intValue = Utils.clamp(intValue + delta, minValue, maxValue)
    gfx.mouse_wheel = 0
  end
  
  return intValue
end

-- ===== ACTIONS =====
local Actions = {}

function Actions.initializeColors()
  colorCache = {} -- очищаем кэш цветов
  for _, group in ipairs(groups) do
    for _, item in ipairs(group.items) do
      local colorValue = reaper.GetThemeColor(item.vars[1], 0)
      item.color = Utils.reaper2hex(colorValue)
      colorCache[item.vars[1]] = colorValue -- кэшируем
    end
  end
end

function Actions.applyColorToTheme(item, colorValue, hexString)
  for _, varName in ipairs(item.vars) do
    reaper.SetThemeColor(varName, colorValue, 0)
    colorCache[varName] = colorValue -- обновляем кэш
  end
  
  local cleanHex = (hexString:sub(1, 1) == "#" and hexString or "#" .. hexString):upper()
  item.color = cleanHex
end

function Actions.initPickerDM(item)
  local picker = State.picker
  picker.isDM = false
  picker.dmMode = 0x00
  picker.dmAlpha = 0.0
  picker.dmOrigMode = 0x00
  picker.dmOrigN = 0

  local keys = getDmKeys(item)
  if not keys then return end

  local firstKey = keys[1]
  local valueString = Theme.getKeyValue(firstKey)
  if not valueString then return end

  local value = tonumber(valueString)
  if not value then return end

  local mode, alpha, n = DM.decode(value)
  picker.isDM = true
  picker.dmMode = mode
  picker.dmAlpha = alpha
  picker.dmOrigMode = mode
  picker.dmOrigN = n
end


function Actions.openColorPicker(item)
  local currentColor = Utils.hex2reaper(item.color)
  local r, g, b = Utils.extractRGB(currentColor)
  
  local picker = State.picker
  picker.r, picker.g, picker.b = r, g, b
  picker.brightness = 0
  picker.target = item
  picker.original = currentColor
  picker.justOpened = true
  picker.defaultR, picker.defaultG, picker.defaultB = r, g, b
  picker.defaultBrightness = 0
  picker.scrollY = 0 -- сбрасываем скролл при открытии
  
  -- Запоминаем оригинальный цвет из файла
  local fileString = Theme.getKeyValue(item.vars[1])
  picker.fileOrigColor = fileString and tonumber(fileString) or currentColor
  
  Actions.initPickerDM(item)
  State.mode = "picker"
end

function Actions.pasteColor(item, alsoSaveTheme)
  if not State.hasSWS then return end
  
  local clipboard = reaper.CF_GetClipboard()
  local value = Utils.hex2reaper(clipboard)
  if value then
    Actions.applyColorToTheme(item, value, clipboard)
    if alsoSaveTheme then
      local patch = Theme.collectPatch(nil)
      Theme.saveAndReload(patch)
    end
  end
end

function Actions.showContextMenu(item)
  gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
  local menu = State.hasSWS and 
    "Copy HEX (Ctrl+C)|Paste HEX (Ctrl+V)|Edit color" or
    "#Copy HEX (SWS required)|#Paste HEX (SWS required)|Edit color"
    
  local choice = gfx.showmenu(menu)
  
  if choice == 1 and State.hasSWS then
    reaper.CF_SetClipboard(item.color)
  elseif choice == 2 and State.hasSWS then
    Actions.pasteColor(item, true)
  elseif choice == 3 then
    State.selected = item
    Actions.openColorPicker(item)
  end
end

-- ===== РЕНДЕРЕР =====
local Renderer = {}

function Renderer.clearItemRects()
  for _, g in ipairs(groups) do
    for _, item in ipairs(g.items) do
      item.x, item.y, item.w, item.h = nil, nil, nil, nil
    end
  end
end

function Renderer.drawInfoButton()
  local buttonWidth, buttonHeight = UI.getButtonSize("Info")
  local clipWidth = Scroll.isScrollBarVisible() and gfx.w - ui.scrollBarWidth or gfx.w
  local buttonX = clipWidth - ui.padding - buttonWidth
  local buttonY = ui.padding - State.scrollY
  
  local isHovered = (gfx.mouse_x >= buttonX and gfx.mouse_x <= buttonX + buttonWidth and 
                    gfx.mouse_y >= buttonY and gfx.mouse_y <= buttonY + buttonHeight)
  
  UI.drawButton(buttonX, buttonY, buttonWidth, buttonHeight, "Info", isHovered, false, true)
  
  -- Сохраняем координаты для обработки клика
  State.infoButton = {x = buttonX, y = buttonY, w = buttonWidth, h = buttonHeight}
end

function Renderer.drawMainMode()
  Scroll.updateMainContent()
  
  -- Сброс хитбоксов, чтобы не было устаревших прямоугольников
  Renderer.clearItemRects()

  Scroll.handleScrollBarInput()

  Renderer.drawInfoButton()
  
  local y = ui.padding + ui.infoButtonOffset - State.scrollY
  
  for _, group in ipairs(groups) do
    -- Пропускаем группы, которые не видны
    if y + ui.lineHeight * #group.items + ui.groupBottomOffset < 0 then
      y = y + gfx.texth + ui.groupTitleOffset + #group.items * ui.lineHeight + ui.groupBottomOffset
      goto continue
    end
    
    if y > gfx.h then break end
    
    gfx.set(table.unpack(ui.accentColor))
    gfx.x, gfx.y = ui.padding, y
    gfx.drawstr(group.label)
    y = y + ui.groupTitleOffset + gfx.texth
    
    for _, item in ipairs(group.items) do
      if y >= -ui.lineHeight and y <= gfx.h then -- только видимые элементы
        Renderer.drawColorItem(item, y)
      end
      y = y + ui.lineHeight
    end
    y = y + ui.groupBottomOffset
    
    ::continue::
  end
  
  Scroll.drawScrollBar()
end

function Renderer.drawColorItem(item, y)
  gfx.set(1, 1, 1, 1)
  local labelY = y + (ui.lineHeight - gfx.texth) / 2
  gfx.x, gfx.y = ui.padding, labelY
  gfx.drawstr(" " .. item.label)
  
  local rgb = Utils.hex2reaper(item.color)
  local r, g, b = Utils.extractRGB(rgb)
  
  local clipWidth = Scroll.isScrollBarVisible() and gfx.w - ui.scrollBarWidth or gfx.w
  local boxX = clipWidth - ui.padding - ui.colorBoxWidth
  local boxY = y + (ui.lineHeight - ui.colorBoxHeight) / 2
  
  -- Бледная рамка для всех цветовых квадратиков
  gfx.set(0.3, 0.3, 0.3, 1)
  gfx.rect(boxX - 1, boxY - 1, ui.colorBoxWidth + 2, ui.colorBoxHeight + 2, 1)
  
  -- Цвет квадратика
  gfx.set(r / 255, g / 255, b / 255, 1)
  gfx.rect(boxX, boxY, ui.colorBoxWidth, ui.colorBoxHeight, 1)
  
  -- Акцентная рамка для выбранного элемента (перекрывает бледную)
  if State.selected == item then
    gfx.set(table.unpack(ui.accentColor))
    gfx.rect(boxX - 2, boxY - 2, ui.colorBoxWidth + 4, ui.colorBoxHeight + 4, 0)
    gfx.set(0, 0, 0, 1)
    gfx.rect(boxX - 1, boxY - 1, ui.colorBoxWidth + 2, ui.colorBoxHeight + 2, 0)
  end
  
  item.x, item.y, item.w, item.h = boxX, boxY, ui.colorBoxWidth, ui.colorBoxHeight
end

function Renderer.getPickerColorValue()
  local picker = State.picker
  local r, g, b = Utils.applyBrightness(picker.r, picker.g, picker.b, picker.brightness)
  return (b << 16) | (g << 8) | r
end

function Renderer.drawDMControls(yStart, sliderX, sliderW)
  local modes = {
    {code = 0x00, text = "Normal"},
    {code = 0x01, text = "Add"},
    {code = 0x02, text = "Dodge"},
    {code = 0x03, text = "Multiply"},
    {code = 0x04, text = "Overlay"},
    {code = 0xFE, text = "HSV adj"},
  }
  
  local y = yStart + ui.dmTopGap
  local rowHeight = select(2, UI.getButtonSize("X"))
  local x = sliderX
  local rightEdge = sliderX + sliderW
  
  -- Кнопки режимов с автопереносом
  for i = 1, #modes do
    local mode = modes[i]
    local buttonWidth = select(1, UI.getButtonSize(mode.text))
    
    if x + buttonWidth > rightEdge then
      y = y + rowHeight + ui.rowGap
      x = sliderX
    end
    
    local isHovered = (gfx.mouse_x >= x and gfx.mouse_x <= x + buttonWidth and 
                      gfx.mouse_y >= y and gfx.mouse_y <= y + rowHeight)
                      
    UI.drawButton(x, y, buttonWidth, rowHeight, mode.text, 
                 isHovered, State.picker.dmMode == mode.code, true)
                 
    if isHovered and State.justLPress then
      State.picker.dmMode = mode.code
    end
    
    x = x + buttonWidth + ui.btnGap
  end
  
  -- Слайдер прозрачности
  y = y + rowHeight + ui.alphaTopGap
  local nBefore = math.floor(State.picker.dmAlpha * 256 + 0.5)
  local label = string.format("Opacity: %.3f", nBefore / 256.0)
  local n = UI.sliderIntLabel("dm_alpha", sliderX, y, label, nBefore, 0, 256, sliderW)
  State.picker.dmAlpha = n / 256.0
  
  local bottom = y + 15 + 12
  
  -- Предупреждение о несохранённых изменениях
  local nCurrent = math.floor(State.picker.dmAlpha * 256 + 0.5)
  local dmDirty = (nCurrent ~= State.picker.dmOrigN) or (State.picker.dmMode ~= State.picker.dmOrigMode)
  if dmDirty then
    local warnY = bottom + 6
    gfx.set(1, 0.3, 0.3, 1)
    gfx.x, gfx.y = sliderX, warnY
    gfx.drawstr("Apply to view blend/opacity changes")
    bottom = warnY + gfx.texth
  end
  
  return bottom
end

function Renderer.drawPickerMode()
  if State.picker.justOpened and not State.lmb then
    State.picker.justOpened = false
  end
  if State.picker.justOpened then return end
  
  -- Обновляем размеры контента для скроллинга
  Scroll.updatePickerContent()
  
  -- Обработка скроллбара
  Scroll.handleScrollBarInput()
  
  local clipWidth = Scroll.isScrollBarVisible() and gfx.w - ui.scrollBarWidth or gfx.w
  local scrollY = State.picker.scrollY
  
  -- Предпросмотр цвета с бледной рамкой
  local r, g, b = Utils.applyBrightness(State.picker.r, State.picker.g, State.picker.b, State.picker.brightness)
  local previewY = ui.padding - scrollY
  
  -- Бледная рамка для предпросмотра
  gfx.set(0.3, 0.3, 0.3, 1)
  gfx.rect(ui.padding - 1, previewY - 1, clipWidth - ui.padding * 2 + 2, ui.previewHeight + 2, 1)
  
  -- Цвет предпросмотра
  gfx.set(r / 255, g / 255, b / 255, 1)
  gfx.rect(ui.padding, previewY, clipWidth - ui.padding * 2, ui.previewHeight, 1)
  
  local sliderX, sliderW = ui.padding, clipWidth - ui.padding * 2
  local y = ui.padding + ui.previewHeight + 15 - scrollY
  
  -- RGB и яркость слайдеры
  if y >= -40 and y <= gfx.h then
    State.picker.r = UI.slider("r", sliderX, y, "R", State.picker.r, 0, 255, sliderW)
  end
  y = y + 40
  
  if y >= -40 and y <= gfx.h then
    State.picker.g = UI.slider("g", sliderX, y, "G", State.picker.g, 0, 255, sliderW)
  end
  y = y + 40
  
  if y >= -40 and y <= gfx.h then
    State.picker.b = UI.slider("b", sliderX, y, "B", State.picker.b, 0, 255, sliderW)
  end
  y = y + 40
  
  if y >= -40 and y <= gfx.h then
    State.picker.brightness = UI.slider("bright", sliderX, y, "Lightness", State.picker.brightness, -100, 100, sliderW)
  end
  y = y + 40
  
  -- Live-применение цвета
  local currentColorValue = Renderer.getPickerColorValue()
  if currentColorValue ~= State.picker.lastColorValue then
    for _, varName in ipairs(State.picker.target.vars) do
      reaper.SetThemeColor(varName, currentColorValue, 0)
    end
    State.picker.target.color = Utils.reaper2hex(currentColorValue)
  
    updateAllUI()
  
    State.picker.lastColorValue = currentColorValue
  end

  -- DM UI
  if State.picker.isDM then
    y = Renderer.drawDMControls(y, sliderX, sliderW) + 12
  end
  
  -- Вычисляем состояние "грязности" для Apply
  local dirtyColor = (State.picker.fileOrigColor ~= nil) and 
                     (currentColorValue ~= State.picker.fileOrigColor) or false
  local dirtyDM = false
  
  if State.picker.isDM then
    local _, nNow = DM.encode(State.picker.dmMode, State.picker.dmAlpha)
    dirtyDM = (nNow ~= State.picker.dmOrigN) or (State.picker.dmMode ~= State.picker.dmOrigMode)
  end
  
  local applyEnabled = dirtyColor or dirtyDM
  
  -- Кнопки
  Renderer.drawPickerButtons(applyEnabled, currentColorValue)
  
  -- Рисуем скроллбар
  Scroll.drawScrollBar()
end

function Renderer.drawPickerButtons(applyEnabled, currentColorValue)
  local clipWidth = Scroll.isScrollBarVisible() and gfx.w - ui.scrollBarWidth or gfx.w
  local btnY = gfx.h - ui.padding * 2
  
  -- Проверяем, есть ли что сбрасывать для Reset
  local canReset = (State.picker.r ~= State.picker.defaultR or 
                   State.picker.g ~= State.picker.defaultG or 
                   State.picker.b ~= State.picker.defaultB or 
                   State.picker.brightness ~= State.picker.defaultBrightness)
  
  if State.picker.isDM then
    local currentDMN = math.floor(State.picker.dmAlpha * 256 + 0.5)
    canReset = canReset or (State.picker.dmMode ~= State.picker.dmOrigMode or currentDMN ~= State.picker.dmOrigN)
  end
  
  local wR, hR = UI.getButtonSize("Reset")
  
  -- Меняем текст Cancel на Back если Apply недоступен
  local cancelText = applyEnabled and "Cancel" or "Back"
  local wC, hC = UI.getButtonSize(cancelText)
  local wA, hA = UI.getButtonSize("Apply")
  
  local xR = ui.padding
  local xC = xR + wR + ui.buttonGap
  local xA = clipWidth - ui.padding - wA
  
  local hovR = (gfx.mouse_x >= xR and gfx.mouse_x <= xR + wR and 
               gfx.mouse_y >= btnY and gfx.mouse_y <= btnY + hR)
  local hovC = (gfx.mouse_x >= xC and gfx.mouse_x <= xC + wC and 
               gfx.mouse_y >= btnY and gfx.mouse_y <= btnY + hC)
  local hovA = (gfx.mouse_x >= xA and gfx.mouse_x <= xA + wA and 
               gfx.mouse_y >= btnY and gfx.mouse_y <= btnY + hA)
  
  UI.drawButton(xR, btnY, wR, hR, "Reset", hovR, false, canReset) -- enabled только если есть что сбрасывать
  UI.drawButton(xC, btnY, wC, hC, cancelText, hovC, false, true)
  UI.drawButton(xA, btnY, wA, hA, "Apply", hovA, true, applyEnabled)
  
  if State.justLPress then
    if hovA and applyEnabled then
      Renderer.handleApplyButton(currentColorValue)
    elseif hovC then
      -- Логика одинакова для Cancel/Back - просто возврат назад
      Renderer.handleCancelButton()
    elseif hovR and canReset then -- Reset работает только если активна
      Renderer.handleResetButton()
    end
  end
end

function Renderer.handleApplyButton(currentColorValue)
  local dmOverride = nil
  if State.picker.isDM then
    local dmValue = DM.encode(State.picker.dmMode, State.picker.dmAlpha)
    -- matchVar используем для идентификации айтема (как было с vars[1])
    dmOverride = { matchVar = State.picker.target.vars[1], value = dmValue }
  end

  local patch = Theme.collectPatch(dmOverride)
  Theme.saveAndReload(patch)
  Actions.initializeColors()

  State.picker.original = currentColorValue
  State.picker.fileOrigColor = currentColorValue

  State.picker.defaultR = State.picker.r
  State.picker.defaultG = State.picker.g
  State.picker.defaultB = State.picker.b
  State.picker.defaultBrightness = State.picker.brightness

  if State.picker.isDM then
    local _, nNow = DM.encode(State.picker.dmMode, State.picker.dmAlpha)
    State.picker.dmOrigMode = State.picker.dmMode
    State.picker.dmOrigN = nNow
  else
    State.mode = "main"
  end
end


function Renderer.handleCancelButton()
  -- Откатываем цвет в движке
  for _, varName in ipairs(State.picker.target.vars) do
    reaper.SetThemeColor(varName, State.picker.original, 0)
  end
  State.picker.target.color = Utils.reaper2hex(State.picker.original)

  updateAllUI()

  State.mode = "main"
end

function Renderer.handleResetButton()
  -- Откат к последним "базовым" значениям (при открытии пикера или после последнего Apply)
  State.picker.r = State.picker.defaultR
  State.picker.g = State.picker.defaultG
  State.picker.b = State.picker.defaultB
  State.picker.brightness = State.picker.defaultBrightness
  
  if State.picker.isDM then
    State.picker.dmMode = State.picker.dmOrigMode
    State.picker.dmAlpha = State.picker.dmOrigN / 256.0
  end
  
  -- НЕ обновляем дефолтные значения после Reset - просто возвращаемся к ним
end

-- ===== THEME DATA MANAGER =====
local ThemeData = {}
ThemeData.CLIPBOARD_MARKER = "[[REAPER_THEME_COLOR_EDITOR_DATA]]"

function ThemeData.collectAllData()
  local data = {
    version = "1.0",
    timestamp = os.date("%Y-%m-%d %H:%M:%S"),
    colors = {},
    dmKeys = {}
  }
  
  -- Собираем все цвета
  for _, group in ipairs(groups) do
    for _, item in ipairs(group.items) do
      local primaryVar = item.vars[1]
      local colorValue = reaper.GetThemeColor(primaryVar, 0)
      
      -- Для каждого элемента сохраняем все его vars
      local itemData = {
        label = item.label,
        vars = item.vars,
        color = colorValue
      }
      
      data.colors[primaryVar] = itemData
    end
  end
  
  -- Собираем все DM ключи
  for _, group in ipairs(groups) do
    for _, item in ipairs(group.items) do
      local dmKeys = getDmKeys(item)
      if dmKeys then
        local primaryVar = item.vars[1]
        data.dmKeys[primaryVar] = {}
        
        for _, dmKey in ipairs(dmKeys) do
          local dmValue = Theme.getKeyValue(dmKey)
          if dmValue then
            data.dmKeys[primaryVar][dmKey] = tonumber(dmValue) or dmValue
          end
        end
      end
    end
  end
  
  return data
end

function ThemeData.copyToClipboard()
  if not State.hasSWS then
    reaper.ShowMessageBox("SWS Extension is required for copy/paste functionality", "SWS Required", 0)
    return false
  end
  
  local data = ThemeData.collectAllData()
  local jsonData = ThemeData.encodeJSON(data)
  local clipboardContent = ThemeData.CLIPBOARD_MARKER .. "\n" .. jsonData
  
  reaper.CF_SetClipboard(clipboardContent)
  
  local colorCount = 0
  for _ in pairs(data.colors) do colorCount = colorCount + 1 end
  
  local dmCount = 0
  for _ in pairs(data.dmKeys) do dmCount = dmCount + 1 end
  
  reaper.ShowMessageBox(
    string.format("Theme data copied successfully!\n\n• %d color elements\n• %d blend-mode elements\n• Timestamp: %s", 
                  colorCount, dmCount, data.timestamp),
    "Copy Complete", 0)
  
  return true
end

function ThemeData.pasteFromClipboard()
  if not State.hasSWS then
    reaper.ShowMessageBox("SWS Extension is required for copy/paste functionality", "SWS Required", 0)
    return false
  end
  
  local clipboardContent = reaper.CF_GetClipboard()
  
  -- Проверяем наличие маркера
  if not clipboardContent:find(ThemeData.CLIPBOARD_MARKER, 1, true) then
    reaper.ShowMessageBox("Clipboard does not contain theme data.\n\nUse 'Copy Data' first to copy theme settings.", "Invalid Data", 0)
    return false
  end
  
  -- Извлекаем JSON
  local jsonStart = clipboardContent:find("\n", #ThemeData.CLIPBOARD_MARKER + 1)
  if not jsonStart then
    reaper.ShowMessageBox("Invalid theme data format in clipboard", "Parse Error", 0)
    return false
  end
  
  local jsonData = clipboardContent:sub(jsonStart + 1)
  local data = ThemeData.decodeJSON(jsonData)
  
  if not data then
    reaper.ShowMessageBox("Failed to parse theme data from clipboard", "Parse Error", 0)
    return false
  end
  
  -- Применяем данные
  return ThemeData.applyData(data)
end

function ThemeData.applyData(data)
  if not data.colors then
    reaper.ShowMessageBox("Invalid theme data: missing colors", "Data Error", 0)
    return false
  end
  
  local appliedColors = 0
  local appliedDM = 0
  local patch = {}
  
  -- Применяем цвета
  for primaryVar, itemData in pairs(data.colors) do
    if itemData.vars and itemData.color then
      -- Применяем цвет ко всем vars этого элемента
      for _, varName in ipairs(itemData.vars) do
        reaper.SetThemeColor(varName, itemData.color, 0)
        patch[varName] = tostring(itemData.color)
      end
      appliedColors = appliedColors + 1
    end
  end
  
  -- Применяем DM ключи
  if data.dmKeys then
    for primaryVar, dmData in pairs(data.dmKeys) do
      for dmKey, dmValue in pairs(dmData) do
        patch[dmKey] = tostring(dmValue)
      end
      appliedDM = appliedDM + 1
    end
  end
  
  -- Сохраняем в файл темы
  Theme.saveAndReload(patch)
  
  -- Обновляем наш интерфейс
  Actions.initializeColors()
  updateAllUI()
  
  reaper.ShowMessageBox(
    string.format("Theme data applied successfully!\n\n• %d color elements\n• %d blend-mode elements\n\nSource: %s", 
                  appliedColors, appliedDM, data.timestamp or "Unknown"),
    "Paste Complete", 0)
  
  return true
end

-- Простой JSON encoder/decoder
function ThemeData.encodeJSON(data)
  local function encodeValue(val)
    if type(val) == "string" then
      return '"' .. val:gsub('\\', '\\\\'):gsub('"', '\\"') .. '"'
    elseif type(val) == "number" then
      return tostring(val)
    elseif type(val) == "table" then
      if #val > 0 then -- array
        local items = {}
        for _, v in ipairs(val) do
          items[#items + 1] = encodeValue(v)
        end
        return "[" .. table.concat(items, ",") .. "]"
      else -- object
        local items = {}
        for k, v in pairs(val) do
          items[#items + 1] = encodeValue(k) .. ":" .. encodeValue(v)
        end
        return "{" .. table.concat(items, ",") .. "}"
      end
    else
      return "null"
    end
  end
  
  return encodeValue(data)
end

function ThemeData.decodeJSON(jsonStr)
  -- Простой JSON парсер для наших данных
  local function parseValue(str, pos)
    local char = str:sub(pos, pos)
    
    if char == '"' then -- string
      local endPos = str:find('"', pos + 1)
      if not endPos then return nil, pos end
      local value = str:sub(pos + 1, endPos - 1)
      value = value:gsub('\\"', '"'):gsub('\\\\', '\\')
      return value, endPos + 1
    elseif char == '[' then -- array
      local array = {}
      pos = pos + 1
      while pos <= #str do
        local nextChar = str:sub(pos, pos)
        if nextChar == ']' then
          return array, pos + 1
        elseif nextChar == ',' then
          pos = pos + 1
        else
          local value, newPos = parseValue(str, pos)
          if not value then return nil, pos end
          array[#array + 1] = value
          pos = newPos
        end
      end
      return nil, pos
    elseif char == '{' then -- object
      local obj = {}
      pos = pos + 1
      while pos <= #str do
        local nextChar = str:sub(pos, pos)
        if nextChar == '}' then
          return obj, pos + 1
        elseif nextChar == ',' then
          pos = pos + 1
        else
          local key, newPos = parseValue(str, pos)
          if not key then return nil, pos end
          pos = newPos
          
          -- skip ':'
          while pos <= #str and str:sub(pos, pos):match("%s") do pos = pos + 1 end
          if str:sub(pos, pos) == ':' then pos = pos + 1 end
          while pos <= #str and str:sub(pos, pos):match("%s") do pos = pos + 1 end
          
          local value, newPos2 = parseValue(str, pos)
          if value == nil then return nil, pos end
          obj[key] = value
          pos = newPos2
        end
      end
      return nil, pos
    else -- number
      local numEnd = pos
      while numEnd <= #str and str:sub(numEnd, numEnd):match("[%d%.-]") do
        numEnd = numEnd + 1
      end
      local numStr = str:sub(pos, numEnd - 1)
      return tonumber(numStr), numEnd
    end
  end
  
  -- Skip whitespace
  local pos = 1
  while pos <= #jsonStr and jsonStr:sub(pos, pos):match("%s") do
    pos = pos + 1
  end
  
  local result, _ = parseValue(jsonStr, pos)
  return result
end

function ThemeData.showContextMenu()
  gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
  
  local hasSWS = reaper.APIExists("CF_GetClipboard", "") and reaper.APIExists("CF_SetClipboard", "")
  local hasValidData = false
  
  if hasSWS then
    local clipboardContent = reaper.CF_GetClipboard()
    hasValidData = clipboardContent and clipboardContent:find(ThemeData.CLIPBOARD_MARKER, 1, true) ~= nil
  end
  
  local menu = ""
  if hasSWS then
    menu = "Copy Data|" .. (hasValidData and "Paste Data" or "#Paste Data (no theme data in clipboard)")
  else
    menu = "#Copy Data (SWS required)|#Paste Data (SWS required)"
  end
    
  local choice = gfx.showmenu(menu)
  
  if choice == 1 and hasSWS then
    ThemeData.copyToClipboard()
  elseif choice == 2 and hasSWS and hasValidData then
    ThemeData.pasteFromClipboard()
  end
end

-- ===== ОБРАБОТЧИК ВВОДА =====
local InputHandler = {}

function InputHandler.updateMouseEdges()
  local leftButton = (gfx.mouse_cap & 1) == 1
  local rightButton = (gfx.mouse_cap & 2) == 2
  
  State.justLPress = leftButton and not State.lmb
  State.justLRelease = (not leftButton) and State.lmb
  State.justRPress = rightButton and not State.rmb
  
  State.lmb = leftButton
  State.rmb = rightButton
end

function InputHandler.handleMainMode()
  local char = gfx.getchar()

  -- Горячие клавиши копирования/вставки
  if char == 3 and State.selected and State.hasSWS then -- Ctrl+C
    reaper.CF_SetClipboard(State.selected.color)
  elseif char == 22 and State.selected and State.hasSWS then -- Ctrl+V
    Actions.pasteColor(State.selected, true)
  end

  -- Колёсико скролла (если не перетаскиваем скроллбар)
  if not State.scrollBarDragging then
    Scroll.handleWheel()
  end
  
 if State.justLPress then
    local mx, my = gfx.mouse_x, gfx.mouse_y

    -- Кнопка Info
    if State.infoButton
       and mx >= State.infoButton.x and mx <= State.infoButton.x + State.infoButton.w
       and my >= State.infoButton.y and my <= State.infoButton.y + State.infoButton.h then
      Info.showHelpDialog()
      return
    end

    -- Не реагируем внутри зоны скроллбара
    if Scroll.isScrollBarVisible() and mx >= gfx.w - ui.scrollBarWidth then
      return
    end

    -- Хит-тест по видимым айтемам (только у кого есть актуальные x/y/w/h)
    for _, group in ipairs(groups) do
      for _, item in ipairs(group.items) do
        if item.x and item.y and item.w and item.h then
          if mx >= item.x and mx <= item.x + item.w
             and my >= item.y and my <= item.y + item.h then
            if State.selected == item then
              Actions.openColorPicker(item)
            else
              State.selected = item
            end
            return
          end
        end
      end
    end
  end

  if State.justRPress then
    local mx, my = gfx.mouse_x, gfx.mouse_y
  
    -- Не реагируем внутри зоны скроллбара
    if Scroll.isScrollBarVisible() and mx >= gfx.w - ui.scrollBarWidth then
      return
    end
  
    -- Сначала проверяем клик по цветовым квадратикам
    local clickedOnColorBox = false
    for _, group in ipairs(groups) do
      for _, item in ipairs(group.items) do
        if item.x and item.y and item.w and item.h then
          if mx >= item.x and mx <= item.x + item.w
             and my >= item.y and my <= item.y + item.h then
            Actions.showContextMenu(item)
            clickedOnColorBox = true
            return
          end
        end
      end
    end
    
    -- Если НЕ кликнули по цветовому квадратику, показываем общее меню
    if not clickedOnColorBox then
      ThemeData.showContextMenu()
    end
  end
end


function InputHandler.handlePickerMode()
  local char = gfx.getchar()
  
  if char == 13 or char == 19 then -- Enter или Ctrl+S - Apply
    local currentColorValue = Renderer.getPickerColorValue()
    local dirtyColor = (State.picker.fileOrigColor ~= nil) and 
                      (currentColorValue ~= State.picker.fileOrigColor) or false
    local dirtyDM = false
    
    if State.picker.isDM then
      local _, nNow = DM.encode(State.picker.dmMode, State.picker.dmAlpha)
      dirtyDM = (nNow ~= State.picker.dmOrigN) or (State.picker.dmMode ~= State.picker.dmOrigMode)
    end
    
    if dirtyColor or dirtyDM then
      Renderer.handleApplyButton(currentColorValue)
    end
    
  elseif char == 27 then -- ESC - Cancel
    Renderer.handleCancelButton()
    
  elseif char == 3 and State.hasSWS then -- Ctrl+C
    reaper.CF_SetClipboard(State.picker.target.color)
    
  elseif char == 22 and State.hasSWS then -- Ctrl+V
    local clipboard = reaper.CF_GetClipboard()
    local value = Utils.hex2reaper(clipboard)
    if value then
      State.picker.r, State.picker.g, State.picker.b = Utils.extractRGB(value)
      State.picker.brightness = 0
      Actions.applyColorToTheme(State.picker.target, value, clipboard)
    end
  end
  
  -- Обработка скроллинга колёсиком мыши (только если не над скроллбаром и не активен слайдер)
  if not State.scrollBarDragging and not State.activeSlider then
    Scroll.handleWheel()
  end
end

-- ===== ГЛАВНАЯ ЛОГИКА =====
local function initialize()
  if not Theme.readCurrentTheme() then
    return false
  end
  
  Actions.initializeColors()
  
  local maxText, textHeight = UI.measureText()
  local width, height = UI.calculateWindowSize(maxText, textHeight)
  
  gfx.init("DSG_Easy Theme Tweaker", width, height)
  return true
end

local function mainLoop()
  InputHandler.updateMouseEdges()
  
  -- Очистка экрана
  gfx.set(0, 0, 0, 1)
  gfx.rect(0, 0, gfx.w, gfx.h, 1)
  
  if State.mode == "main" then
    Renderer.drawMainMode()
    InputHandler.handleMainMode()
  else
    Renderer.drawPickerMode()
    InputHandler.handlePickerMode()
  end
  
  if gfx.getchar() >= 0 then
    reaper.defer(mainLoop)
  end
end

-- Запуск приложения
if initialize() then
  mainLoop()
end
