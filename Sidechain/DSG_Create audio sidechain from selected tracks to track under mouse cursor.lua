--[[
Description: DSG_Create audio sidechain from selected tracks to track under mouse cursor
Version: 1.0
Author: DSG
--]]
reaper.BR_GetMouseCursorContext()

selected_tracks_count = reaper.CountSelectedTracks(0)
track_under_cursor = reaper.BR_GetMouseCursorContext_Track()

if selected_tracks_count == 0 or track_under_cursor == nil then return end
if selected_tracks_count == 1 and reaper.GetSelectedTrack(0, 0) == track_under_cursor then return end

reaper.Undo_BeginBlock()

for i = 1, selected_tracks_count do
  local src_track = reaper.GetSelectedTrack(0, i-1)

  if(src_track ~= track_under_cursor) then
    local create_send = true

    for i = 1, reaper.GetTrackNumSends(src_track, 0) do
      local dest_track = reaper.GetTrackSendInfo_Value(src_track, 0, i-1, 'P_DESTTRACK')
      local dest_chan = reaper.GetTrackSendInfo_Value(src_track, 0, i-1, 'I_DSTCHAN')
  
      if(dest_track == track_under_cursor and dest_chan == 2) then
        create_send = false
      end
    end
  
    if(create_send == true) then
      local ch_count = reaper.GetMediaTrackInfo_Value(track_under_cursor, 'I_NCHAN')
      local send = reaper.CreateTrackSend(src_track, track_under_cursor)
  
      reaper.SetMediaTrackInfo_Value(track_under_cursor, 'I_NCHAN', math.max(4, ch_count))

      reaper.SetTrackSendInfo_Value(src_track, 0, send, 'I_SENDMODE', 3)
      reaper.SetTrackSendInfo_Value(src_track, 0, send, 'I_DSTCHAN', 2)
      reaper.SetTrackSendInfo_Value(src_track, 0, send, 'I_MIDIFLAGS', 4177951)
    end
  end
end

reaper.Undo_EndBlock('DSG_Create audio sidechain from selected tracks to track under mouse cursor', -1)
