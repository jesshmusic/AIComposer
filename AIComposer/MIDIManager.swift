//
//  MIDIManager.swift
//  AIComposer
//
//  Created by Jess Hendricks on 11/25/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import Cocoa
import AudioToolbox
import AVFoundation

/// The `Singleton` instance
private let MIDIManagerInstance = MIDIManager()

class MIDIManager: NSObject {
    
    var soundBank = NSBundle.mainBundle().URLForResource("32MbGMStereo", withExtension: "sf2")
    var musicPlayer: AVMIDIPlayer!
    internal private(set) var isPlaying = false
    
    //  Returns the singleton instance
    class var sharedInstance:MIDIManager {
        return MIDIManagerInstance
    }
    
    /*
    *   Load the MIDI file
    *   For now MIDI files should just be small motivic ideas between 2 - 32 quarter notes in length
    *   Returns the midi note data, time resolution
    */
    func loadMIDIFile(filePathString: String) -> (
        midiNotes: [(midiNoteMessage: MIDINoteMessage,
        barBeatTime: CABarBeatTime,
        timeStamp: MusicTimeStamp)],
        eventMarkers: [MusicTimeStamp],
        timeResolution: UInt32,
        numberOfBeats: UInt8,
        tempo: Double)
    {
        // Load the MIDI File
        var sequence = MusicSequence()
        NewMusicSequence(&sequence)
        
        let midiFileURL = NSURL(fileURLWithPath: filePathString)
        MusicSequenceFileLoad(sequence, midiFileURL, MusicSequenceFileTypeID.MIDIType, MusicSequenceLoadFlags.SMF_ChannelsToTracks)
        let tempoTrackInfo = self.parseTempoTrack(sequence: sequence)
        let timeResolution = self.determineTimeResolutionOfSequence(sequence)
        let midiNoteEvents = parseMIDIEventTracks(sequence, timeResolution: timeResolution)
        return (midiNoteEvents.midiEvents, midiNoteEvents.eventMarkers, timeResolution, tempoTrackInfo.numberOfBeats, tempoTrackInfo.tempo)
    }
    
    
    
    
    
    /**
     Creates the MIDI player for a specific MusicSequence
     
     - musicSeq:      `MusicSequence`
     */
    func createMIDIPlayer(musicSeq: MusicSequence) {
        var status = OSStatus(noErr)
        var data: Unmanaged<CFData>?
        status = MusicSequenceFileCreateData(musicSeq, MusicSequenceFileTypeID.MIDIType, MusicSequenceFileFlags.EraseFile, 480, &data)
        
        if status != OSStatus(noErr) {
            print("bad status \(status)")
        }
        
        if let md = data {
            let midiData = md.takeUnretainedValue() as NSData
            do {
                try self.musicPlayer = AVMIDIPlayer(data: midiData, soundBankURL: self.soundBank)
            } catch let error as NSError {
                print("nil midi player")
                print("Error \(error.localizedDescription)")
            }
            data?.release()
            self.musicPlayer.prepareToPlay()
        }
    }
    
    /**
     Plays the currently load MusicSequence
    */
    func play() {
        if self.isPlaying {
            self.musicPlayer.stop()
            self.isPlaying = false
        } else {
            self.musicPlayer.play(finishedPlaying)
            self.isPlaying = true
        }
    }
    
    /**
     Called when the sequence has finished playing. Resets the music player to the beginning.
    */
    func finishedPlaying() {
        self.musicPlayer.currentPosition = 0
        self.isPlaying = false
        NSNotificationCenter.defaultCenter().postNotificationName("Finished playing MIDI", object: self)
    }
    
    /**
     Creates a MIDI file from a sequence
     
     - fileName: `String` the name of the new file
     - sequence: the `MusicSequence` to be used.
    */
    func createMIDIFile(var fileName name: String, sequence: MusicSequence) -> NSURL {
        if name.rangeOfString(".mid") == nil {
            name = name + ".mid"
        }
        let midiFileURL = NSURL(fileURLWithPath: name)
        
        MusicSequenceFileCreate(sequence, midiFileURL, MusicSequenceFileTypeID.MIDIType, MusicSequenceFileFlags.EraseFile, 0)
        return midiFileURL
    }
    
    
    private func determineTimeResolutionOfSequence(sequence: MusicSequence) -> UInt32
    {
        var timeResolution:UInt32  = 0
        var propertyLength:UInt32  = 0
        // Get the Tempo Track
        var tempoTrack = MusicTrack()
        MusicSequenceGetTempoTrack(sequence, &tempoTrack)
        
        MusicTrackGetProperty(tempoTrack,kSequenceTrackProperty_TimeResolution, &timeResolution, &propertyLength);
        
        return timeResolution
    }
    
    private func parseTempoTrack(sequence sequence: MusicSequence) -> (numberOfBeats: UInt8, tempo: Double) {
        var tempoTrack: MusicTrack = nil
        MusicSequenceGetTempoTrack(sequence, &tempoTrack)
        
        var iterator: MusicEventIterator = nil
        NewMusicEventIterator(tempoTrack, &iterator)
        
        var hasNext:DarwinBoolean = true
        var timestamp: MusicTimeStamp = 0
        var eventType: MusicEventType = 0
        var eventDataSize: UInt32 = 0
        var eventData: UnsafePointer<Void> = nil
        
        MusicEventIteratorHasCurrentEvent(iterator, &hasNext)
        
        var numberOfBeats:UInt8 = 0
        var tempo = 0.0
        while(hasNext) {
            MusicEventIteratorGetEventInfo(iterator, &timestamp, &eventType, &eventData, &eventDataSize)
            if eventType == kMusicEventType_Meta {
                let metaEventType = UnsafePointer<MIDIMetaEvent>(eventData).memory.metaEventType
                if metaEventType == 88 {
                    numberOfBeats = UnsafePointer<MIDIMetaEvent>(eventData).memory.data
                }
            } else if eventType == kMusicEventType_ExtendedTempo {
                
                tempo = Double(UnsafePointer<ExtendedTempoEvent>(eventData).memory.bpm)
            }
            MusicEventIteratorNextEvent(iterator);
            MusicEventIteratorHasCurrentEvent(iterator, &hasNext);
        }
        print("Number of beats is \(numberOfBeats)")
        print("Tempo found: bmp is \(tempo)")
        return (numberOfBeats, tempo)
    }
    
    private func parseTrackForMIDIEvents(iterator: MusicEventIterator, sequence: MusicSequence, timeResolution: UInt32) -> (
        midiEvents:[(midiNoteMessage: MIDINoteMessage,
        barBeatTime: CABarBeatTime,
        timeStamp: MusicTimeStamp)],
        eventMarkers: [MusicTimeStamp])
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
        var eventMarkers = [MusicTimeStamp]()
        while (hasNext) {
            MusicEventIteratorGetEventInfo(iterator, &timestamp, &eventType, &eventData, &eventDataSize)
            if eventType == kMusicEventType_MIDINoteMessage {
                var barBeatTime = CABarBeatTime()
                MusicSequenceBeatsToBarBeatTime(sequence, timestamp, timeResolution, &barBeatTime)
                let noteMessage = UnsafePointer<MIDINoteMessage>(eventData).memory
                notesForTrack.append((noteMessage, barBeatTime, timestamp))
                
                //  Check for corrupted duration values ??? 
                for noteIndex in 0..<notesForTrack.count {
                    if notesForTrack[noteIndex].midiNoteMessage.duration == 0.0 {
                        if noteIndex < notesForTrack.count - 1 {
                            notesForTrack[noteIndex].midiNoteMessage.duration = Float32(notesForTrack[noteIndex + 1].timeStamp - notesForTrack[noteIndex].timeStamp)
                        } else {
                            notesForTrack[noteIndex].midiNoteMessage.duration = 0.5
                        }
                    }
                }
            } else if eventType == kMusicEventType_MIDIChannelMessage {
                let channelMessage = UnsafePointer<MIDIChannelMessage>(eventData)
                if channelMessage.memory.data1 == 20 {
                    eventMarkers.append(timestamp)
                }
            }
            MusicEventIteratorNextEvent(iterator);
            MusicEventIteratorHasCurrentEvent(iterator, &hasNext);
        }
        return (notesForTrack, eventMarkers)
    }
    
    private func parseMIDIEventTracks(
        sequence: MusicSequence,
        timeResolution: UInt32) -> (midiEvents: [(midiNoteMessage:  MIDINoteMessage,
        barBeatTime:    CABarBeatTime,
        timeStamp:  MusicTimeStamp)],
        eventMarkers: [MusicTimeStamp])
    {
        var trackCount: UInt32 = 0
        MusicSequenceGetTrackCount(sequence, &trackCount)
        var notes = [(midiNoteMessage: MIDINoteMessage,
            barBeatTime: CABarBeatTime,
            timeStamp: MusicTimeStamp)]()
        var eventMarkers = [MusicTimeStamp]()
        var track: MusicTrack = nil
        for (var index:UInt32 = 0; index < trackCount; index++) {
            MusicSequenceGetIndTrack(sequence, index, &track)
            var iterator: MusicEventIterator = nil
            NewMusicEventIterator(track, &iterator)
            let parsedEventsForTrack = self.parseTrackForMIDIEvents(iterator, sequence: sequence, timeResolution: timeResolution)
            eventMarkers.appendContentsOf(parsedEventsForTrack.eventMarkers)
            notes.appendContentsOf(parsedEventsForTrack.midiEvents)
        }
        return (notes, eventMarkers)
    }

}
