--[[
Description: DSG_Whoosh
Version: 1.0
Author: DSG
--]]
local scriptName = 'DSG_Whoosh'
local trackTemplateName = scriptName
local tension = 0.290
local trackColor = reaper.ColorToNative(255, 0, 0)
local trackName = scriptName

function hasSelection()
  timeselstart, timeselend = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  return timeselstart < timeselend
end

if(not hasSelection()) then
  reaper.ShowMessageBox("No time selection", "Error", 0)
  return false
end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

local trackTemplatesPath = reaper.GetResourcePath():gsub('\\','/')..'/TrackTemplates'
local scriptTrackTemplatePath = trackTemplatesPath..'/'..'DSG_Whoosh'..'.RTrackTemplate'

local file = io.open(scriptTrackTemplatePath)
if not file then
  reaper.ShowMessageBox(scriptTrackTemplatePath..' file not found.', "Error", 0)
end

local selectedTrack = reaper.GetSelectedTrack(0,0)
local selectedTrackNumber = reaper.CountTracks()
if(selectedTrack) then
  selectedTrackNumber = reaper.GetMediaTrackInfo_Value(selectedTrack, "IP_TRACKNUMBER")
end

reaper.InsertTrackAtIndex(selectedTrackNumber, false)

local whooshTrack = reaper.GetTrack(0, selectedTrackNumber)

local trackTemplateData = file:read("a")
file:close()

reaper.SetTrackStateChunk(whooshTrack, trackTemplateData, false)

local midiItem = reaper.CreateNewMIDIItemInProj(whooshTrack, 0,0)
local strtLp, endLp = reaper.GetSet_LoopTimeRange(0,0,0,0,0)
reaper.SetMediaItemInfo_Value(midiItem, "D_POSITION", strtLp)
reaper.SetMediaItemInfo_Value(midiItem, "D_LENGTH", endLp - strtLp)

local take = reaper.GetMediaItemTake(midiItem, 0)
local note = reaper.MIDI_GetNote(take, 0)
reaper.MIDI_DeleteNote(take, 0)

local itemPos = reaper.GetMediaItemInfo_Value(midiItem, "D_POSITION")
local itemLen = reaper.GetMediaItemInfo_Value(midiItem, "D_LENGTH")
reaper.MIDI_InsertNote(take, true, false, 0, reaper.MIDI_GetPPQPosFromProjTime(take, itemPos + itemLen), 0, 72, 96, false)

local envCount = reaper.CountTrackEnvelopes(whooshTrack)
for i = 0, envCount - 1 do
  local env = reaper.GetTrackEnvelope(whooshTrack, i)
  local point = reaper.GetEnvelopePointEx(env, -1, 1)
  
  reaper.SetEnvelopePointEx(env, -1, 0, strtLp, 0, 5, tension)
  reaper.InsertEnvelopePointEx(env, -1, strtLp + endLp - strtLp, 1, 0, 0, false)
end

reaper.SetOnlyTrackSelected(whooshTrack, 1)
reaper.Main_OnCommand(41716, 0) -- Track: Render selected area of tracks to stereo post-fader stem tracks (and mute originals)
reaper.DeleteTrack(whooshTrack)

local stem = reaper.GetSelectedTrack(0, 0)
local stemItem = reaper.GetTrackMediaItem(stem, 0)
local stemItemTake = reaper.GetActiveTake(stemItem)

if(trackColor) then
  reaper.SetTrackColor(stem, trackColor)
end
reaper.GetSetMediaTrackInfo_String(stem, "P_NAME", trackName, true)
reaper.GetSetMediaItemTakeInfo_String(stemItemTake, "P_NAME", trackName, true)

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.SetMixerScroll(stem)
reaper.Main_OnCommand(40913, 0) -- Track: Vertical scroll selected tracks into view
reaper.Main_OnCommand(40632, 0) -- Go to start of loop

reaper.Undo_EndBlock(scriptName, 0)
