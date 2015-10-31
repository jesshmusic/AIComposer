//
//  MIDIFileParser.swift
//  AIComposer
//
//  Created by Jess Hendricks on 10/27/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import Cocoa
import CoreMIDI
import CoreAudio
import AudioToolbox

/// The `Singleton` instance
private let MIDIFileParserInstance = MIDIFileParser()

class MIDIFileParser: NSObject {
    
//    var timeResolution: UInt32!
    
    class var sharedInstance:MIDIFileParser {
        return MIDIFileParserInstance
    }
    
    
    func loadMIDIFile(filePathString: String) -> (tempoTrack: MusicTrack, midiNoteEvents: [MusicNote], timeResolution: UInt32) {
        // Load the MIDI File
        var sequence = MusicSequence()
        NewMusicSequence(&sequence)
        
        let midiFileURL = NSURL(fileURLWithPath: filePathString)
        MusicSequenceFileLoad(sequence, midiFileURL, MusicSequenceFileTypeID.MIDIType, MusicSequenceLoadFlags.SMF_ChannelsToTracks)
        
        let tempoTrackData = parseTempoTrack(sequence)
        let midiNoteEvents = parseMIDIEventTracks(sequence, timeResolution: tempoTrackData.timeRes)
        
        return (tempoTrackData.musicTrack, midiNoteEvents, tempoTrackData.timeRes)
    }
    
    private func parseTempoTrack(sequence: MusicSequence) -> (musicTrack:MusicTrack, timeRes: UInt32) {
        
        // Get the Tempo Track
        var tempoTrack = MusicTrack()
        MusicSequenceGetTempoTrack(sequence, &tempoTrack)
        let timeResolution = determineTimeResolutionWithTempoTrack(tempoTrack)
        
        // Create an iterator that will loop through the events in the track
        var iterator = MusicEventIterator()
        NewMusicEventIterator(tempoTrack, &iterator);
        
        var hasNext:DarwinBoolean = true
        var timestamp: MusicTimeStamp = 0
        var eventType: MusicEventType = 0
        var eventDataSize: UInt32 = 0
        var eventData: UnsafePointer<Void> = nil
        
        // Run the loop
        MusicEventIteratorHasCurrentEvent(iterator, &hasNext);
        while (hasNext) {
            MusicEventIteratorGetEventInfo(iterator,
                &timestamp,
                &eventType,
                &eventData,
                &eventDataSize);
            
            // Process each event here
//            print("Event found! type: \(eventType)\n");
            
            MusicEventIteratorNextEvent(iterator);
            MusicEventIteratorHasCurrentEvent(iterator, &hasNext);
        }
        return (tempoTrack, timeResolution)
    }
    
    private func determineTimeResolutionWithTempoTrack(tempoTrack: MusicTrack) -> UInt32 {
        var timeResolution:UInt32  = 0;
        var propertyLength:UInt32  = 0;
        
        MusicTrackGetProperty(tempoTrack, kSequenceTrackProperty_TimeResolution, nil, &propertyLength);
        
        
        MusicTrackGetProperty(tempoTrack,
            kSequenceTrackProperty_TimeResolution,
            &timeResolution,
            &propertyLength);
        
//        print("propertyLength: \(propertyLength)")
//        print("timeResolution: \(timeResolution)")
        
        return timeResolution
    }
    
    private func parseTrackForMIDIEvents(iterator: MusicEventIterator, sequence: MusicSequence, timeResolution: UInt32) -> [MusicNote] {
        
        var hasNext:DarwinBoolean = true
        var timestamp: MusicTimeStamp = 0
        var eventType: MusicEventType = 0
        var eventDataSize: UInt32 = 0
        var eventData: UnsafePointer<Void> = nil
        
        MusicEventIteratorHasCurrentEvent(iterator, &hasNext)
        
        var notesForTrack = [MusicNote]()
        while (hasNext) {
            MusicEventIteratorGetEventInfo(iterator, &timestamp, &eventType, &eventData, &eventDataSize)
            if (eventType == kMusicEventType_MIDINoteMessage) {
                
                var barBeatTime = CABarBeatTime()
                MusicSequenceBeatsToBarBeatTime(sequence, timestamp, timeResolution, &barBeatTime)
                let noteMessage = UnsafePointer<MIDINoteMessage>(eventData)
                let note = MusicNote(
                    noteMessage: MIDINoteMessage(
                        channel: noteMessage.memory.channel,
                        note: noteMessage.memory.note,
                        velocity: noteMessage.memory.velocity,
                        releaseVelocity: noteMessage.memory.releaseVelocity,
                        duration: noteMessage.memory.duration),
                    barBeatTime: barBeatTime)
                notesForTrack.append(note)
            }
            MusicEventIteratorNextEvent(iterator);
            MusicEventIteratorHasCurrentEvent(iterator, &hasNext);
        }
        return notesForTrack
    }
    
    private func parseMIDIEventTracks(sequence: MusicSequence, timeResolution: UInt32) -> [MusicNote] {
        var trackCount: UInt32 = 0
        MusicSequenceGetTrackCount(sequence, &trackCount)
        print("Parsing \(trackCount) tracks.")
        var notes = [MusicNote]()
        var track: MusicTrack = nil
        for (var index:UInt32 = 0; index < trackCount; index++) {
            MusicSequenceGetIndTrack(sequence, index, &track)
            var iterator: MusicEventIterator = nil
            NewMusicEventIterator(track, &iterator)
            notes.appendContentsOf(parseTrackForMIDIEvents(iterator, sequence: sequence, timeResolution: timeResolution))
        }
        return notes
    }
    
}