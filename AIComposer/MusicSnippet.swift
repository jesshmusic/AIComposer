//
//  MusicSnippet.swift
//  AIComposer
//
//  This is a node for an individual snippet of music data (currently set at one measure long)
//
//  Created by Jess Hendricks on 10/28/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import Cocoa
import CoreMIDI
import AudioToolbox


class MusicSnippet: NSObject, NSCoding {
    
    private var musicChord = MusicChord.sharedInstance
    
    internal private(set) var musicNoteEvents: [MusicNote]!
    internal private(set) var transposedNoteEvents: [MusicNote]!
    internal private(set) var count = 0
    internal private(set) var numberOfOccurences = 1
    internal private(set) var possibleChords: [(chordName:String, weight: Float)]!
    
    override init() {
        self.musicNoteEvents = [MusicNote]()
        self.transposedNoteEvents = [MusicNote]()
        self.count = self.musicNoteEvents.count
    }
    
    required init(coder aDecoder: NSCoder)  {
        self.musicNoteEvents = aDecoder.decodeObjectForKey("MusicNoteEvents") as! [MusicNote]
        self.transposedNoteEvents = aDecoder.decodeObjectForKey("Transposed Music Note Events") as! [MusicNote]
        self.count = aDecoder.decodeIntegerForKey("Count")
        self.numberOfOccurences = aDecoder.decodeIntegerForKey("NumberOfOccurences")
        self.possibleChords = musicChord.generatePossibleChordNames(self.transposedNoteEvents)
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.musicNoteEvents, forKey: "MusicNoteEvents")
        aCoder.encodeObject(self.transposedNoteEvents, forKey: "Transposed Music Note Events")
        aCoder.encodeInteger(self.count, forKey: "Count")
        aCoder.encodeInteger(self.numberOfOccurences, forKey: "NumberOfOccurences")
    }
    
    func addMusicNote(newMusicNote: MusicNote) {
        //  I create a new MIDINoteMessage because I think it is a C pointer, and we need a separate value for transposed notes
        let newMIDIMess = MIDINoteMessage(
            channel: newMusicNote.midiNoteMess.channel,
            note: newMusicNote.midiNoteMess.note,
            velocity: newMusicNote.midiNoteMess.velocity,
            releaseVelocity: newMusicNote.midiNoteMess.releaseVelocity,
            duration: newMusicNote.midiNoteMess.duration)
        let newTransposedNote = MusicNote(noteMessage: newMIDIMess, barBeatTime: newMusicNote.barBeatTime, timeStamp: newMusicNote.timeStamp)
        self.musicNoteEvents.append(newMusicNote)
        self.transposedNoteEvents.append(newTransposedNote)
        count++
    }
    
    func incrementNumberOfOccurences() {
        self.numberOfOccurences++
    }
    
    /*
    *   This will set each musical snippet to a transposition that can be easily used with any chord.
    *   Example: If the snippet is over an Eb chord, it will transpose it to a version over a C chord in
    *   in the bottom octave (0-11)
    *   Additionally, this will set all time stamps to start on zero
    */
    func zeroTransposeMusicSnippet() {
        //  1: Take each note number mod12 to get it in the bottom octave.
        let firstTimeStamp = self.transposedNoteEvents[0].timeStamp
        let timeStampOffset = firstTimeStamp - (firstTimeStamp % 1.0)
        for i in 0..<self.musicNoteEvents.count {
            self.musicNoteEvents[i].timeStamp = self.musicNoteEvents[i].timeStamp - timeStampOffset
            self.transposedNoteEvents[i].timeStamp = self.transposedNoteEvents[i].timeStamp - timeStampOffset
        }
        for nextNote in self.transposedNoteEvents {
            nextNote.midiNoteMess.note = nextNote.midiNoteMess.note%12
        }
        
        //  2: Get a weighted set of all of the possible chords this melody could be associated with.
        self.possibleChords = musicChord.generatePossibleChordNames(self.transposedNoteEvents)
    }
    
    
    //  -----  Override functions for hashing   ------
    
    override var hashValue: Int {
        var hashInt:UInt8 = 0
        for nextNote in self.musicNoteEvents {
            hashInt = hashInt + nextNote.midiNoteMess.note
        }
        return hashInt.hashValue
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        if let musSnippet = object as? MusicSnippet {
            if musSnippet.count == self.count {
                for index in 0..<self.count {
                    let nextNote1 = self.transposedNoteEvents[index]
                    let nextNote2 = musSnippet.transposedNoteEvents[index]
                    if nextNote1 != nextNote2 {
                        return false
                    }
                }
            } else {
                return false
            }
        } else {
            return false
        }
        return true
    }
    
    //  ------------------------------------------------
    
    //  Returns a string description of the snippet
    var toString: String {
        var returnString = "Music Snippet:\n\tNumber Of Occurences: \(self.numberOfOccurences)\n\t--------------------------------\n"
        var noteNumberSet = [UInt8: Float32]()
        for nextNote in self.musicNoteEvents {
            if noteNumberSet[nextNote.midiNoteMess.note] != nil {
                noteNumberSet[nextNote.midiNoteMess.note] = noteNumberSet[nextNote.midiNoteMess.note]! + nextNote.midiNoteMess.duration
            } else {
                noteNumberSet[nextNote.midiNoteMess.note] = nextNote.midiNoteMess.duration
            }
            returnString = returnString + "\t\(nextNote.description)\n"
        }
        returnString = returnString + "\tNotes and Durations:\n\t\t"
        let sortedNoteNumberSet = noteNumberSet.sort({$0.0 < $1.0})
        for nextNoteNumDur in sortedNoteNumberSet {
            returnString = returnString + "\(nextNoteNumDur.0): \(nextNoteNumDur.1)]   "
        }
        returnString = returnString + "\n\tPossible Chords: \(self.possibleChords)\n"
        return returnString
    }
    
    var infoString: String {
        var retString = "Notes: \(self.musicNoteEvents.count),  "
        retString = retString + "Possible Chords: \n"
        for chord in self.possibleChords {
            retString = retString + "\(chord.chordName): \(chord.weight)  "
        }
        return retString
    }
    
    var dataString: String {
        var returnString = ""
        var noteNumberSet = [UInt8: Float32]()
        for nextNote in self.musicNoteEvents {
            if noteNumberSet[nextNote.midiNoteMess.note] != nil {
                noteNumberSet[nextNote.midiNoteMess.note] = noteNumberSet[nextNote.midiNoteMess.note]! + nextNote.midiNoteMess.duration
            } else {
                noteNumberSet[nextNote.midiNoteMess.note] = nextNote.midiNoteMess.duration
            }
            returnString = returnString + "\t\(nextNote.dataString)\n"
        }
        return returnString
    }
}
