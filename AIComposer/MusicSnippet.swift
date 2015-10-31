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

class MusicSnippet: NSObject, NSCoding {
    
    private var musicChord = MusicChord.sharedInstance
    
    private var musicNoteEvents: [MusicNote]!
    var count = 0
    internal private(set) var numberOfOccurences = 1
    
    internal private(set) var chordNameString: String!
    internal private(set) var chordNotes: [Int]!
    internal private(set) var transposedChordNameString: String!
    internal private(set) var transposedChordNotes: [Int]!
    internal private(set) var transposeOffset = 0
    
    override init() {
        self.musicNoteEvents = [MusicNote]()
        self.count = self.musicNoteEvents.count
    }
    
    required init(coder aDecoder: NSCoder)  {
        self.musicNoteEvents = aDecoder.decodeObjectForKey("MusicNoteEvents") as! [MusicNote]
        self.count = aDecoder.decodeIntegerForKey("Count")
        self.numberOfOccurences = aDecoder.decodeIntegerForKey("NumberOfOccurences")
        self.chordNameString = aDecoder.decodeObjectForKey("ChordNameString") as! String
        self.chordNotes = aDecoder.decodeObjectForKey("ChordNotes") as! [Int]
        self.transposedChordNameString = aDecoder.decodeObjectForKey("TransposedChordNameString") as! String
        self.transposedChordNotes = aDecoder.decodeObjectForKey("TransposedChordNotes") as! [Int]
        self.transposeOffset = aDecoder.decodeIntegerForKey("TransposeOffset")
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.musicNoteEvents, forKey: "MusicNoteEvents")
        aCoder.encodeInteger(self.count, forKey: "Count")
        aCoder.encodeInteger(self.numberOfOccurences, forKey: "NumberOfOccurences")
        aCoder.encodeObject(self.chordNameString, forKey: "ChordNameString")
        aCoder.encodeObject(self.chordNotes, forKey: "ChordNotes")
        aCoder.encodeObject(self.transposedChordNameString, forKey: "TransposedChordNameString")
        aCoder.encodeObject(self.transposedChordNotes, forKey: "TransposedChordNotes")
        aCoder.encodeInteger(self.transposeOffset, forKey: "TransposeOffset")
    }
    
    func addMusicNote(newMusicNote: MusicNote) {
        self.musicNoteEvents.append(newMusicNote)
        count++
    }
    
    func incrementNumberOfOccurences() {
        self.numberOfOccurences++
    }
    
    /*
    *   This will set each musical snippet to a transposition that can be easily used with any chord.
    *   Example: If the snippet is over an Eb chord, it will transpose it to a version over a C chord in
    *   in the bottom octave (0-11)
    */
    func zeroTransposeMusicSnippet() {
        //  1: Take each note number mod12 to get it in the bottom octave.
        
        for nextNote in self.musicNoteEvents {
            nextNote.midiNoteMess.note = nextNote.midiNoteMess.note%12
        }
        
        //  2: Analyze what chord would best suit the snippet.
        let chord = musicChord.analyzeChordFromNotes(self.musicNoteEvents)
        self.chordNameString = chord.chordNameString
        self.chordNotes = chord.chordNotes
        self.transposeOffset = chord.transposeOffset
        
        //  3: Based on the chord, transpose it again to be a version of C (C, Cm, Cdim, C+, etc.)
        let transposedChord = musicChord.getTransposedChord(chord.chordNameString, chordNotes: chord.chordNotes, transposeOffset: chord.transposeOffset)
        self.transposedChordNameString = transposedChord.chordNameString
        self.transposedChordNotes = transposedChord.chordNotes
    }
    
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
                    let nextNote1 = self.musicNoteEvents[index]
                    let nextNote2 = musSnippet.musicNoteEvents[index]
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
            returnString = returnString + "[\(nextNoteNumDur.0): \(nextNoteNumDur.1)]   "
        }
        returnString = returnString + "\n\tChord: \(self.chordNameString)\tTranspose offset: \(self.transposeOffset)\n"
        returnString = returnString + "\n\tTransposed Chord: \(self.transposedChordNameString)\n"
        return returnString
    }
}