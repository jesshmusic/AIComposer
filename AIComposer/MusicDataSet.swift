//
//  MusicDataSet.swift
//  AIComposer
//
//  This is a very preliminary version of a data structure to generate and store music snippets
//
//  Created by Jess Hendricks on 10/27/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import Cocoa
import Foundation
import CoreMIDI
import CoreAudio
import AudioToolbox

class MusicDataSet: NSObject, NSCoding {
    
    var midiFileParser: MIDIFileParser!
    
    //  This will hold an array (for now) of transposable music ideas generated
    //  from music notes that occur in the same measure and channel
    var musicSnippets: [MusicSnippet]!
    
    /*
    *   Initializes the data structure.
    */
    override init() {
        midiFileParser = MIDIFileParser.sharedInstance
        self.musicSnippets = [MusicSnippet]()
        super.init()
    }
    
    required init(coder aDecoder: NSCoder) {
        self.musicSnippets = aDecoder.decodeObjectForKey("MusicSnippets") as! [MusicSnippet]
        midiFileParser = MIDIFileParser.sharedInstance
        super.init()
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.musicSnippets, forKey: "MusicSnippets")
    }
    
    /*
    *   Calls the MIDIFileParser to load a MIDI file.
    *   For now, its is best if the MIDI file has only a short snippet, or musical idea.
    */
    func addNewMIDIFile(filePathString: String) {
        let newMIDIData = self.midiFileParser.loadMIDIFile(filePathString)
        var musicNotes = [MusicNote]()
        let eventMarkers = newMIDIData.eventMarkers
        for nextEvent in newMIDIData.midiNotes {
            let note = MusicNote(noteMessage: nextEvent.midiNoteMessage, barBeatTime: nextEvent.barBeatTime, timeStamp: nextEvent.timeStamp)
            musicNotes.append(note)
        }
        self.generateSnippetsFromMusicNotes(musicNotes, eventMarkers: eventMarkers)
        //        self.distributeMeasures(musicNotes, timeSigEvents: newMIDIData.timeSigEvents)
    }
    
    /*
    *   Generates MusicSnippets from an array of MusicNotes. Event markers (CC20) delineate where to separate snippets.
    *   If there are no event markers, then it will divide based on number of beats.
    */
    
    private func generateSnippetsFromMusicNotes(musicNotes: [MusicNote], numberOfBeats: UInt8? = 4, eventMarkers: [MusicTimeStamp]) {
        if !musicNotes.isEmpty {
            var nextSnippet: MusicSnippet!
            var nextNote = musicNotes[0]
            var noteIndex = 0
            for eventMarker in eventMarkers {
                nextSnippet = MusicSnippet()
                if noteIndex < musicNotes.count {
                    while nextNote.timeStamp < eventMarker {
                        nextSnippet.addMusicNote(nextNote)
                        noteIndex++
                        if musicNotes.count == noteIndex {
                            break
                        } else {
                            nextNote = musicNotes[noteIndex]
                        }
                    }
                    self.addMusicSnippet(nextSnippet)
                } else {
                    break
                }
            }
        }
    }
    
    
    /*
    *   Sets the time stamps to start at 0 and adds the music snippet to the array
    */
    private func addMusicSnippet(musicSnippet: MusicSnippet) {
        musicSnippet.zeroTransposeMusicSnippet()
        self.musicSnippets.append(musicSnippet)
    }
    
    /*
    *   Deletes all music snippets from the data structure
    */
    func clearAllData() {
        self.musicSnippets.removeAll()
    }
    
    func createMIDIFileFromDataSet(filePathString: String) {
        let newSeq = self.getMusicSequenceFromData()
        self.midiFileParser.createMIDIFile(filePathString, sequence: newSeq)
    }
    
    /*
    *   Roughly converts all of the MusicSnippets into a midi file.
    */
    private func getMusicSequenceFromData() -> MusicSequence {
        var newSeq = MusicSequence()
        NewMusicSequence(&newSeq)
        MusicSequenceSetSequenceType(newSeq, MusicSequenceType.Beats)
        var tempoTrack = MusicTrack()
        MusicSequenceGetTempoTrack(newSeq, &tempoTrack)
        MusicTrackNewExtendedTempoEvent(tempoTrack, 0, 120)
        var musicTrack = MusicTrack()
        MusicSequenceNewTrack(newSeq, &musicTrack)
        var currentTimeStamp:MusicTimeStamp = 0
        var previousTimeStamp: MusicTimeStamp = 0
        var previousDuration: Float32 = 0
        for nextMusicSnippet in self.musicSnippets {
            for nextMusicEvent in nextMusicSnippet.musicNoteEvents {
                if nextMusicEvent.timeStamp > currentTimeStamp {
                    currentTimeStamp = previousTimeStamp + MusicTimeStamp(previousDuration)
                }
                let tStamp = nextMusicEvent.timeStamp.advancedBy(currentTimeStamp)
                var midiNoteMessage = MIDINoteMessage()
                midiNoteMessage.channel = nextMusicEvent.midiNoteMess.channel
                midiNoteMessage.duration = nextMusicEvent.midiNoteMess.duration
                midiNoteMessage.note = nextMusicEvent.midiNoteMess.note
                midiNoteMessage.releaseVelocity = nextMusicEvent.midiNoteMess.releaseVelocity
                midiNoteMessage.velocity = nextMusicEvent.midiNoteMess.velocity
                MusicTrackNewMIDINoteEvent(musicTrack, tStamp, &midiNoteMessage)
                previousDuration = midiNoteMessage.duration
                previousTimeStamp = tStamp
            }
        }
        return newSeq
    }
    
    //  So each snippet starts at time 0.0, we need a method to find the offset
    private func getTimeStampOffset(timeSigEvents:[(numbeats: UInt8, lengthOfBeat: UInt8, timeStamp: MusicTimeStamp)], noteEvent: MusicNote) -> MusicTimeStamp {
        var musicTimeStamp = MusicTimeStamp()
        var numBeats:Double = 0
        if timeSigEvents.count == 1 {
            numBeats = Double(timeSigEvents[0].numbeats)
        } else {
            for i in 1..<timeSigEvents.count {
                if noteEvent.timeStamp >= timeSigEvents[i - 1].timeStamp && noteEvent.timeStamp < timeSigEvents[i].timeStamp {
                    numBeats = Double(timeSigEvents[i - 1].numbeats)
                    break
                } else {
                    numBeats = Double(timeSigEvents[i].numbeats)
                }
            }
        }
        if Double(numBeats) % 3.0 == 0 {
            numBeats = numBeats / 2
        }
        musicTimeStamp = noteEvent.timeStamp - (Double(noteEvent.timeStamp) % Double(numBeats))
        //        print("Changing note time stamp: \(noteEvent.timeStamp) - \(Double(noteEvent.timeStamp)) % \(numBeats) = \(musicTimeStamp)")
        return musicTimeStamp
    }
    
    //  Same as 'toString()' in Java
    func getDataString() -> String {
        var descriptString = "Music Data Set"
        descriptString = descriptString + "\nSnippets: \n"
        for nextSnippet in self.musicSnippets {
            descriptString = descriptString + "\(nextSnippet.toString)\n"
        }
        return descriptString
    }
    
    
}
