--[[
Description: DSG_Smart VKB 2
Version: 1.1.5 (Refactored)
Author: DSG
--]]

-- Config
local config = {
  PERIOD = 0.2,
  HIDE_VKB = true,
  VKB_OPACITY = 0,
  AUTO_SET_MIDI_INPUT = true,
  VKB_TITLES = {
    "Virtual MIDI keyboard",
    "Виртуальная MIDI-клавиатура"
  }
}

-- State
local last_run_time = reaper.time_precise()

-- Helpers
local function log(msg)
  reaper.ShowConsoleMsg(tostring(msg) .. "\n")
end

local function set_record_input(track)
  if config.AUTO_SET_MIDI_INPUT then
    local bits_set = tonumber('11111100000', 2)
    reaper.SetMediaTrackInfo_Value(track, 'I_RECINPUT', 4096 + bits_set)
    reaper.SetMediaTrackInfo_Value(track, 'I_RECMON', 1)
    reaper.SetMediaTrackInfo_Value(track, 'I_RECMODE', 0)
  end
  reaper.SetMediaTrackInfo_Value(track, 'I_RECARM', 1)
end

local function unset_record_arm(track)
  reaper.SetMediaTrackInfo_Value(track, 'I_RECARM', 0)
end

local function get_command_state(command)
  local _, _, section_id = reaper.get_action_context()
  return reaper.GetToggleCommandStateEx(section_id, command)
end

local function set_command_state(command, flag)
  local desired_state = flag and 1 or 0
  if get_command_state(command) ~= desired_state then
    reaper.Main_OnCommand(command, 0)
  end
end

local function set_vkb_visible(visible)
  set_command_state(40377, visible) -- View: Show virtual MIDI keyboard
end

local function set_vkb_send_state(enabled)
  set_command_state(40637, enabled)
end

local function is_ignored_track(track_name)
  return track_name:sub(1, 1) == '_'
end

local function contains(tbl, val)
  for _, v in ipairs(tbl) do
    if v == val then return true end
  end
  return false
end

-- GUI
local function hide_vkb()
  if not config.HIDE_VKB then return end

  local vkb_window = nil

  for _, title in ipairs(config.VKB_TITLES) do
    vkb_window = reaper.JS_Window_Find(title, true)
    if vkb_window then break end
  end

  if vkb_window then
    local parent = reaper.JS_Window_GetParent(vkb_window)
    local _, left, top, right, _ = reaper.JS_Window_GetClientRect(parent)
    local x, y = right - 10, top + 20

    reaper.JS_Window_SetOpacity(vkb_window, "ALPHA", 0)
    if config.VKB_OPACITY == 0 then
      reaper.JS_Window_SetPosition(vkb_window, x, y, 110, 28)
    end
    reaper.Main_OnCommand(reaper.NamedCommandLookup('_BR_FOCUS_ARRANGE_WND'), 0)
  end
end

-- Main Logic
local function update_tracks()
  local midi_editor = reaper.MIDIEditor_GetActive()
  local track_count = reaper.CountTracks(0)
  local active_instrument_tracks = {}
  local ignored_tracks = {}
  local armed_tracks = {}
  local send_enabled = false

  local active_track = nil
  local active_track_index = -1
  local active_track_has_instr = false
  local active_track_ignored = false

  if midi_editor then
    local take = reaper.MIDIEditor_GetTake(midi_editor)
    active_track = reaper.GetMediaItemTake_Track(take)
    active_track_index = reaper.GetMediaTrackInfo_Value(active_track, 'IP_TRACKNUMBER') - 1
    active_track_has_instr = reaper.TrackFX_GetInstrument(active_track) >= 0
    local _, name = reaper.GetTrackName(active_track, "")
    active_track_ignored = is_ignored_track(name)
  end

  for i = 0, track_count - 1 do
    local track = reaper.GetTrack(0, i)
    local _, name = reaper.GetTrackName(track, "")
    local ignored = is_ignored_track(name)
    local has_instr = reaper.TrackFX_GetInstrument(track) >= 0

    if ignored then
      table.insert(ignored_tracks, i)
    elseif has_instr and reaper.TrackFX_GetFloatingWindow(track, reaper.TrackFX_GetInstrument(track)) then
      table.insert(active_instrument_tracks, i)
    end
  end

  if #active_instrument_tracks > 0 then
    for i = 0, track_count - 1 do
      if contains(active_instrument_tracks, i) and not contains(ignored_tracks, i) then
        local tr = reaper.GetTrack(0, i)
        set_record_input(tr)
        table.insert(armed_tracks, i)
        send_enabled = true
      end
    end
  elseif active_track and active_track_has_instr and not active_track_ignored then
    set_record_input(active_track)
    table.insert(armed_tracks, active_track_index)
    send_enabled = true
  elseif active_track and not active_track_has_instr then
    send_enabled = false
  end

  for i = 0, track_count - 1 do
    if not contains(armed_tracks, i) and not contains(ignored_tracks, i) then
      unset_record_arm(reaper.GetTrack(0, i))
    end
  end

  for _, i in ipairs(ignored_tracks) do
    local tr = reaper.GetTrack(0, i)
    if reaper.GetMediaTrackInfo_Value(tr, 'I_RECARM') == 1 and reaper.TrackFX_GetInstrument(tr) >= 0 then
      send_enabled = true
    end
  end

  set_vkb_send_state(send_enabled)
end

-- Timer loop
local function timer_loop()
  local now = reaper.time_precise()
  if now - last_run_time > config.PERIOD then
    last_run_time = now
    update_tracks()
  end
  reaper.defer(timer_loop)
end

-- Entry point
set_vkb_visible(true)
hide_vkb()
timer_loop()
