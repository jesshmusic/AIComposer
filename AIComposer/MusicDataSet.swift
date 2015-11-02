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
    *   For now, its is best if the MIDI file has only one track.
    *   Gets all of the necessary data from the MIDI file and divides it into MusicSnippets
    */
    func addNewMIDIFile(filePathString: String) {
        let newMIDIData = self.midiFileParser.loadMIDIFile(filePathString)
        var musicNotes = [MusicNote]()
        for nextEvent in newMIDIData.midiNotes {
            let note = MusicNote(noteMessage: nextEvent.midiNoteMessage, barBeatTime: nextEvent.barBeatTime, timeStamp: nextEvent.timeStamp)
            musicNotes.append(note)
        }
        self.distributeMeasures(musicNotes, timeSigEvents: newMIDIData.timeSigEvents)
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
    
    /**
    *   Iterates through the track and separates each measure into a musical snippet
    *   This can be augmented with more complexity in the future?
    *   Not complete. Needs to put all of this in stores for the document and into a Markov chain format.
    */
    
    private func distributeMeasures(musicNoteEvents: [MusicNote], timeSigEvents: [(numbeats: UInt8, lengthOfBeat: UInt8, timeStamp: MusicTimeStamp)]) {
        //  Initialize the variables for the starting measure and MusicSnippet array
        var currentBar:Int32  = 1
        var nextSnippet: MusicSnippet!
        
        //  Calculate the length of the phrase... May need later
        var phraseLength = 0
        for timeSigEvent in timeSigEvents {
            print("Distributing events, number of beats: \(timeSigEvent.numbeats), timeStamp: \(timeSigEvent.timeStamp)")
        }
        //  Iterate through all of the MIDI Notes
        for index in 0..<musicNoteEvents.count {
            let nextNote = musicNoteEvents[index]
            nextNote.timeStamp = nextNote.timeStamp - self.getTimeStampOffset(timeSigEvents, noteEvent: nextNote)
            //  If nextNote is the last note, add it to the snippet
            if index == musicNoteEvents.count - 1 {
                nextSnippet.addMusicNote(nextNote)
                nextSnippet.zeroTransposeMusicSnippet()
                if self.musicSnippets.contains(nextSnippet) {
                    self.musicSnippets[self.musicSnippets.indexOf(nextSnippet)!].incrementNumberOfOccurences()
                } else {
                    self.musicSnippets.append(nextSnippet)
                }
                
                //  If the nextNote is in a NEW measure, add the last snippet (that is now complete) to the main array
                //  and start a NEW snippet, putting the nextNote into it.
            } else if currentBar != nextNote.barBeatTime.bar {
                phraseLength++
                
                //  Add the complete snippet to the array after transposing everything to the bottom octave.
                if nextSnippet != nil {
                    nextSnippet.zeroTransposeMusicSnippet()
                    if self.musicSnippets.contains(nextSnippet) {
                        self.musicSnippets[self.musicSnippets.indexOf(nextSnippet)!].incrementNumberOfOccurences()
                    } else {
                        self.musicSnippets.append(nextSnippet)
                    }
                    nextSnippet = MusicSnippet()
                    nextSnippet.addMusicNote(nextNote)
                    currentBar = nextNote.barBeatTime.bar
                    //  If there is no current snippet, initialize one. (This may be a fringe case)
                } else {
                    nextSnippet = MusicSnippet()
                    nextSnippet.addMusicNote(nextNote)
                    currentBar = nextNote.barBeatTime.bar
                }
                //  The nextNote is still in the current measure, so add it to the snippet.
            } else {
                if nextSnippet != nil  {
                    nextSnippet.addMusicNote(nextNote)
                } else {
                    nextSnippet = MusicSnippet()
                    nextSnippet.addMusicNote(nextNote)
                }
            }
        }
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
