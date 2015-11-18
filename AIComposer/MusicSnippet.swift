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

let MAJOR_INTERVALS = [
    0: [-10, -8, -7, -5, -3, -1, 0, 2, 4, 5, 7, 9, 11],
    1: [-10, -8, -7, -5, -3, -1, 0, 2, 4, 5, 7, 9, 11],
    2: [-10, -9, -7, -5, -3, -2, 0, 2, 3, 5, 7, 9, 10],
    3: [-10, -9, -7, -5, -3, -2, 0, 2, 3, 5, 7, 9, 10],
    4: [-11, -9, -7, -5, -4, -2, 0, 1, 3, 5, 7, 8, 10],
    5: [-10, -8, -6, -5, -3, -1, 0, 2, 4, 6, 7, 9, 11],
    6: [-10, -8, -6, -5, -3, -1, 0, 2, 4, 6, 7, 9, 11],
    7: [-10, -8, -7, -5, -3, -2, 0, 2, 4, 5, 7, 9, 10],
    8: [-10, -8, -7, -5, -3, -2, 0, 2, 4, 5, 7, 9, 10],
    9: [-10, -9, -7, -5, -4, -2, 0, 2, 3, 5, 7, 8, 10],
    10: [-10, -9, -7, -5, -4, -2, 0, 2, 3, 5, 7, 8, 10],
    11: [-11, -9, -7, -6, -4, -2, 0, 1, 3, 5, 6, 8, 10]
]

let MINOR_INTERVALS = [
    //  0    1    2   3   4   5  6   7  8  9  10 11 12 13  14
    0: [-10, -9, -7, -5, -4, -2, -1, 0, 2, 3, 5, 7, 8, 10, 11],
    1: [-10, -9, -7, -5, -4, -2, -1, 0, 2, 3, 5, 7, 8, 10, 11],
    2: [-11, -9, -7, -6, -4, -3, -2, 0, 1, 3, 5, 6, 8, 9, 10],
    3: [-11, -9, -7, -6, -4, -3, -2, 0, 2, 4, 5, 7, 8, 9, 11],
    4: [-11, -9, -7, -6, -4, -3, -2, 0, 2, 4, 5, 7, 8, 9, 11],
    5: [-10, -9, -7, -6, -5, -3, -2, 0, 2, 3, 5, 6, 7, 9, 10],
    6: [-10, -9, -7, -6, -5, -3, -2, 0, 2, 3, 5, 6, 7, 9, 10],
    7: [-11, -9, -8, -7, -5, -4, -2, 0, 1, 3, 4, 5, 7, 8, 10],
    8: [-10, -9, -8, -5, -5, -3, -1, 0, 2, 3, 4, 6, 7, 9, 11],
    9: [-10, -9, -8, -5, -5, -3, -1, 0, 2, 3, 4, 6, 7, 9, 11],
    10: [-11, -10, -8, -7, -5, -3, -2, 0, 1, 2, 4, 6, 7, 9, 10],
    11: [-11, -9, -8, -6, -4, -3, -1, 0, 1, 3, 4, 6, 8, 9, 11]
]

class MusicSnippet: NSObject, NSCoding {
    
    private var musicChord = MusicChord.sharedInstance
    
    internal private(set) var musicNoteEvents: [MusicNote]!
    internal private(set) var transposedNoteEvents: [MusicNote]!
    internal private(set) var count = 0
    internal private(set) var numberOfOccurences = 1
    internal private(set) var possibleChords: [(chordName:String, weight: Float)]!
    internal private(set) var endTime: MusicTimeStamp = 0.0
    
    override init() {
        self.musicNoteEvents = [MusicNote]()
        self.transposedNoteEvents = [MusicNote]()
        self.count = self.musicNoteEvents.count
    }
    
    init(notes: [MusicNote]) {
        super.init()
        self.musicNoteEvents = [MusicNote]()
        self.transposedNoteEvents = [MusicNote]()
        self.count = self.musicNoteEvents.count
        for note in notes {
            let newNote = note.getNoteCopy()
            self.addMusicNote(newNote)
        }
        self.zeroTransposeMusicSnippet()
    }
    
    required init(coder aDecoder: NSCoder)  {
        self.musicNoteEvents = aDecoder.decodeObjectForKey("MusicNoteEvents") as! [MusicNote]
        self.transposedNoteEvents = aDecoder.decodeObjectForKey("Transposed Music Note Events") as! [MusicNote]
        self.count = aDecoder.decodeIntegerForKey("Count")
        self.numberOfOccurences = aDecoder.decodeIntegerForKey("NumberOfOccurences")
        self.possibleChords = musicChord.generatePossibleChordNames(self.transposedNoteEvents)
        super.init()
        self.calculateEndTime()
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
    
    private func calculateEndTime() {
        for note in self.musicNoteEvents {
            self.endTime = self.endTime + MusicTimeStamp(note.midiNoteMess.duration)
        }
        if self.musicNoteEvents[0].timeStamp != 0.0 {
            self.endTime = self.endTime + self.musicNoteEvents[0].timeStamp
        }
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
        self.calculateEndTime()
        //  2: Get a weighted set of all of the possible chords this melody could be associated with.
        self.possibleChords = musicChord.generatePossibleChordNames(self.transposedNoteEvents)
    }
    
    /**
     Transpose this snippet chromatically by halfSteps
     
     - halfSteps:    the number of half steps to transpose the passage ( + or - )
     */
    func chromaticTranspose(halfSteps halfSteps: Int) {
        var transposedNotes = [MusicNote]()
        for note in self.musicNoteEvents {
            let newNote = note.getNoteCopy()
            newNote.transposeNote(halfSteps)
            transposedNotes.append(newNote)
        }
        self.musicNoteEvents = transposedNotes
        self.zeroTransposeMusicSnippet()
        self.count = self.musicNoteEvents.count
    }
    
    /**
     Transpose a group of notes diatonically by steps in a C scale
     
     - Parameters:
        - steps:        the number of steps to transpose the passage ( + or - )
        - octaves:      the number of additional octaves to transpose (+ or -)
        - isMajorKey:   `true` if is a major key.
     */
    func diatonicTranspose(steps steps: Int, octaves: Int, isMajorKey: Bool = true) {
        var transposedNotes = [MusicNote]()
        var transposeSteps = 0
        if isMajorKey {
            for note in self.musicNoteEvents {
                //  Get the base steps to transpose diatonically
                transposeSteps = MAJOR_INTERVALS[Int(note.midiNoteMess.note % 12)]![6 + steps]
                transposeSteps = transposeSteps + (octaves * 12)
                let newNote = note.getNoteCopy()
                newNote.transposeNote(transposeSteps)
                transposedNotes.append(newNote)
            }
        } else {
            for note in self.musicNoteEvents {
                //  Get the base steps to transpose diatonically
                transposeSteps = MINOR_INTERVALS[Int(note.midiNoteMess.note % 12)]![7 + steps]
                transposeSteps = transposeSteps + (octaves * 12)
                let newNote = note.getNoteCopy()
                newNote.transposeNote(transposeSteps)
                transposedNotes.append(newNote)
            }
        }
        self.musicNoteEvents = transposedNotes
        self.zeroTransposeMusicSnippet()
        self.count = self.musicNoteEvents.count
    }
    
    /**
     Invert a set of notes chromatically around a pivot note
     
     - pivotNote:   Which pitch to perform the inversion about
     */
    func applyChromaticInversion(pivotNoteNumber pivotNoteNumber: UInt8) {
        //  TODO: Implement Chromatic Inversion
    }
    
    /**
     Invert a set of notes diatonically around a pivot note
     
     - pivotNote:    Which pitch to perform the inversion about
     */
    func applyDiatonicInversion(pivotNoteNumber pivotNoteNumber: UInt8) {
        //  TODO: Implement Diatonic Inversion
    }
    
    /**
     Returns the complete retrograde of a set of notes (pitch and rhythm)
     
     - pivotNumber:  Which pitch to perform the inversion about
     */
    func applyRetrograde() {
        //  TODO: Implement Retrograde
    }
    
    /**
     Returns the melodic retrograde of a set of notes
     
     */
    func applyMelodicRetrograde() {
        //  TODO: Implement retrograde notes
    }
    
    /**
     Returns the rhythmic retrograde of a set of notes
     
     */
    func applyRhythmicRetrograde() {
        //  TODO: Implement retrograde rhythms
    }
    
    /**
     Merges this MusicSnippet with another based on weights for each snippet
     
     - Parameters:
     - firstWeight:      weight of this passage (the second passage weight is (1 - firstWeight)
     - secondPassage:    the first set of notes to be merged
     - Returns: A new `MusicSnippet` of notes based on the two passages
     */
    func mergeNotePassages(firstWeight firstWeight: Double, secondSnippet: MusicSnippet) -> MusicSnippet {
        var returnNotes = [MusicNote]()
        for note in self.musicNoteEvents {
            let newNote = note.getNoteCopy()
            returnNotes.append(newNote)
        }
        
        return MusicSnippet(notes: returnNotes)
    }
    
    /**
     Creates a crescendo or decrescendo effect over a range of notes
     
     - Parameters:
     - startIndex:       Index of the first note
     - endIndex:         Index of the last note
     - startVelocity:    velocity of the first note
     - endVelocity:      velocity of the last note
     */
    func applyDynamicLine(startIndex startIndex: Int, endIndex: Int, startVelocity: UInt8, endVelocity: UInt8) {
//        var returnNotes = [MusicNote]()
        var currentVel = startVelocity
        let numerator = abs(Int(endVelocity) - Int(startVelocity))
        let velocityIncrement = UInt8(numerator) / UInt8(endIndex - startIndex)
        if endIndex < self.musicNoteEvents.count {
            for i in startIndex...endIndex {
                self.musicNoteEvents[i].midiNoteMess.velocity = currentVel

                if startVelocity < endVelocity {
                    currentVel = currentVel + velocityIncrement
                } else {
                    currentVel = currentVel - velocityIncrement
                }
            }
        }
    }
    
    /**
     Attempts to humanize the feel of a set of notes based on beat and bar
     
     */
    func humanizeNotes() {
        //  TODO: Implement HUMANIZE
    }
    
    /**
     Applies an articulation over a range of notes
     
     - Parameters:
     - startIndex:       Index of the first note
     - endIndex:         Index of the last note
     - articulation:    `Articulation` to apply.
     */
    func applyArticulation(startIndex startIndex: Int, endIndex: Int, articulation: Articulation) {
        if startIndex < endIndex && endIndex < self.musicNoteEvents.count {
            for i in 0..<self.musicNoteEvents.count {
                if i >= startIndex && i <= endIndex {
                    self.musicNoteEvents[i].applyArticulation(articulation)
                }
            }
        }
    }
    
    /**
     Returns the portion of notes in a range
     
     - Parameters:
     - notes:        the `MusicNote`s to be retrograded
     - startIndex:   Index of the first note
     - endIndex:     Index of the last note
     - Returns: `[MusicNote]`
     */
    func getFragment(startIndex startIndex: Int, endIndex: Int) -> MusicSnippet {
        var returnNotes = [MusicNote]()
        if endIndex <= self.musicNoteEvents.count - 1 && startIndex < endIndex {
            var firstTimeStampOffset = 0.0
            let firstTimeStamp = self.musicNoteEvents[startIndex].timeStamp
            for i in 1..<12 {
                let ts = MusicTimeStamp(i)
                if firstTimeStamp > ts {
                    firstTimeStampOffset = ts - 1.0
                    break
                } else if firstTimeStamp == ts {
                    firstTimeStampOffset = ts
                }
            }
            let firstBeatOffset = self.musicNoteEvents[startIndex].barBeatTime.beat - 1
            for i in startIndex...endIndex {
                let newNote = self.musicNoteEvents[i].getNoteCopy()
                newNote.barBeatTime.beat = newNote.barBeatTime.beat - firstBeatOffset
                newNote.timeStamp = newNote.timeStamp - firstTimeStampOffset
                returnNotes.append(newNote)
            }
        }
        return MusicSnippet(notes: returnNotes)
    }
    
    
    /**
     Multiplies all duarations by a multiplier
     
     - Parameters:
     - multiplier:   How much to multiply durations by
     - Returns: `MusicSnippet`
     */
    func getAugmentedPassageRhythm(multiplier multiplier: Int) -> MusicSnippet {
        var returnNotes = [MusicNote]()
        for nextNote in self.musicNoteEvents {
            returnNotes.append(nextNote.getNoteCopy())
        }
        //  TODO: Implement Augment Passage
        return MusicSnippet(notes: returnNotes)
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
