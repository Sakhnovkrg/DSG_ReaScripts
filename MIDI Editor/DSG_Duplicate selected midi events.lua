--[[
Description: DSG_Duplicate selected midi events
Version: 1.0
Author: DSG
--]]

script_name = 'DSG_Duplicate selected midi events'

take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())
if take == nil then return end

_,notecnt,_,_ = reaper.MIDI_CountEvts(take)
  
for i = 0, notecnt-1 do
  _,selected,_,_,_,_,_,_ = reaper.MIDI_GetNote(take, i)
  if (selected == true) then
    reaper.Undo_BeginBlock()
    
    ts_start, ts_end = reaper.GetSet_LoopTimeRange(0, 0, 0, 0, 0)
    loop_start, loop_end = reaper.GetSet_LoopTimeRange(0, 1, 0, 0, 0)
    
    reaper.MIDIEditor_LastFocused_OnCommand(40752, false) -- Edit: Set time selection to selected notes
    reaper.MIDIEditor_LastFocused_OnCommand(40883, false) -- Edit: Duplicate events within time selection
    
    reaper.GetSet_LoopTimeRange(1, 0, ts_start, ts_end, 0)
    reaper.GetSet_LoopTimeRange(1, 1, loop_start, loop_end, 0)
    
    reaper.Undo_EndBlock(script_name, -1)
    break 
  end
end
