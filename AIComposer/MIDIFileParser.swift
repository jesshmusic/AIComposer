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
    
    //  Returns the singleton instance
    class var sharedInstance:MIDIFileParser {
        return MIDIFileParserInstance
    }
    
    /*
    *   Load the MIDI file
    *   Returns the tempo track, midi note data, time resolution, and an array of time signature events
    */
    func loadMIDIFile(filePathString: String) -> (  tempoTrack: MusicTrack,
                                                    midiNotes: [(midiNoteMessage: MIDINoteMessage,
                                                                barBeatTime: CABarBeatTime,
                                                                timeStamp: MusicTimeStamp)],
                                                    timeResolution: UInt32,
                                                    timeSigEvents: [(numbeats: UInt8, timeStamp: MusicTimeStamp)])
    {
        // Load the MIDI File
        var sequence = MusicSequence()
        NewMusicSequence(&sequence)
        
        let midiFileURL = NSURL(fileURLWithPath: filePathString)
        MusicSequenceFileLoad(sequence, midiFileURL, MusicSequenceFileTypeID.MIDIType, MusicSequenceLoadFlags.SMF_ChannelsToTracks)
        
        let tempoTrackData = parseTempoTrack(sequence)
        let midiNoteEvents = parseMIDIEventTracks(sequence, timeResolution: tempoTrackData.timeRes)
        
        return (tempoTrackData.musicTrack, midiNoteEvents, tempoTrackData.timeRes, tempoTrackData.timeSigEvents)
    }
    
    func createMIDIFile(
        var filePathString: String,
        sequence: MusicSequence)
    {
        if filePathString.rangeOfString(".mid") == nil {
            filePathString = filePathString + ".mid"
        }
        let midiFileURL = NSURL(fileURLWithPath: filePathString)
        
        MusicSequenceFileCreate(sequence, midiFileURL, MusicSequenceFileTypeID.MIDIType, MusicSequenceFileFlags.EraseFile, 0)
    }
    
    private func parseTempoTrack(
        sequence: MusicSequence
        ) -> (musicTrack:MusicTrack,
        timeRes: UInt32,
        timeSigEvents: [(numbeats: UInt8, timeStamp: MusicTimeStamp)])
    {
        
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
        var timeSigEvents = [(numbeats: UInt8, timeStamp: MusicTimeStamp)]()
        while (hasNext) {
            MusicEventIteratorGetEventInfo(iterator,
                &timestamp,
                &eventType,
                &eventData,
                &eventDataSize);
            if eventType == kMusicEventType_Meta {
                let eventMetaData = UnsafePointer<MIDIMetaEvent>(eventData)
                let midiMessage = eventMetaData.memory
                let data1 = midiMessage.data
                
//                let midiMessage: MIDIMetaEvent = UnsafePointer<MIDIMetaEvent>(eventData).memory
                print("\n---------------------------------\nMeta event found\n\tdata length: \(midiMessage.dataLength)\n\tdata: \(midiMessage.data)\n\ttype: \(midiMessage.metaEventType)\n\tdata1: \(data1)")
                
                if midiMessage.metaEventType == 0x58 {
                    timeSigEvents.append((midiMessage.data, timestamp))
                }
            }
            MusicEventIteratorNextEvent(iterator);
            MusicEventIteratorHasCurrentEvent(iterator, &hasNext);
        }
        print("TEMPO TRACK DATA\n\ttimeStamp: \(timestamp)\n\teventType: \(eventType)\n")
        return (tempoTrack, timeResolution, timeSigEvents)
    }
    
    private func determineTimeResolutionWithTempoTrack(
        tempoTrack: MusicTrack) -> UInt32
    {
        var timeResolution:UInt32  = 0
        var propertyLength:UInt32  = 0
        var trackLength:Double = 0
        var trackLengthPropertyLength: UInt32 = 0
        
        MusicTrackGetProperty(tempoTrack, kSequenceTrackProperty_TrackLength, &trackLength, &trackLengthPropertyLength)
        MusicTrackGetProperty(tempoTrack,kSequenceTrackProperty_TimeResolution, &timeResolution, &propertyLength);
        
        print("propertyLength: \(propertyLength)")
        print("timeResolution: \(timeResolution)")
        print("trackLength: \(trackLength)")
        print("trackLengthPropertyLength: \(trackLengthPropertyLength)")
        
        return timeResolution
    }
    
    private func parseTrackForMIDIEvents(
        iterator: MusicEventIterator,
        sequence: MusicSequence,
        timeResolution: UInt32) -> [(midiNoteMessage: MIDINoteMessage,
                                    barBeatTime: CABarBeatTime,
                                    timeStamp: MusicTimeStamp)]
    {
        
        var hasNext:DarwinBoolean = true
        var timestamp: MusicTimeStamp = 0
        var eventType: MusicEventType = 0
        var eventDataSize: UInt32 = 0
        var eventData: UnsafePointer<Void> = nil
        
        MusicEventIteratorHasCurrentEvent(iterator, &hasNext)
        
        var notesForTrack = [(midiNoteMessage: MIDINoteMessage,
            barBeatTime: CABarBeatTime,
            timeStamp: MusicTimeStamp)]()
        while (hasNext) {
            MusicEventIteratorGetEventInfo(iterator, &timestamp, &eventType, &eventData, &eventDataSize)
            if (eventType == kMusicEventType_MIDINoteMessage) {
                var barBeatTime = CABarBeatTime()
                MusicSequenceBeatsToBarBeatTime(sequence, timestamp, timeResolution, &barBeatTime)
                let noteMessage = UnsafePointer<MIDINoteMessage>(eventData).memory
                notesForTrack.append((noteMessage, barBeatTime, timestamp))
            }
            MusicEventIteratorNextEvent(iterator);
            MusicEventIteratorHasCurrentEvent(iterator, &hasNext);
        }
        return notesForTrack
    }
    
    private func parseMIDIEventTracks(
        sequence: MusicSequence,
        timeResolution: UInt32) -> [(midiNoteMessage: MIDINoteMessage,
                                    barBeatTime: CABarBeatTime,
                                    timeStamp: MusicTimeStamp)]
    {
        var trackCount: UInt32 = 0
        MusicSequenceGetTrackCount(sequence, &trackCount)
        print("Parsing \(trackCount) tracks.")
        var notes = [(midiNoteMessage: MIDINoteMessage,
            barBeatTime: CABarBeatTime,
            timeStamp: MusicTimeStamp)]()
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
