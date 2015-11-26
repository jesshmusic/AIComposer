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
import AudioToolbox


let C_MAJOR = [0, 2, 4, 5, 7, 9, 11]
let C_MINOR = [0, 2, 3, 5, 7, 8, 10, 11]

class MusicSnippet: NSObject, NSCoding {
    
    private var musicChord = MusicChord.sharedInstance
    
    internal private(set) var musicNoteEvents: [MusicNote]!
    internal private(set) var transposedNoteEvents: [MusicNote]!
    internal private(set) var count = 0
    internal private(set) var numberOfOccurences = 1
    internal private(set) var possibleChords: [(chordName:String, weight: Float)]!
    var endTime: MusicTimeStamp = 0.0
    
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
        self.calculateEndTime()
    }
    
    required init(coder aDecoder: NSCoder)  {
        self.musicNoteEvents = aDecoder.decodeObjectForKey("MusicNoteEvents") as! [MusicNote]
        self.transposedNoteEvents = aDecoder.decodeObjectForKey("Transposed Music Note Events") as! [MusicNote]
        self.count = aDecoder.decodeIntegerForKey("Count")
        self.numberOfOccurences = aDecoder.decodeIntegerForKey("NumberOfOccurences")
        self.possibleChords = musicChord.generatePossibleChordNames(self.transposedNoteEvents)
        self.endTime = MusicTimeStamp(aDecoder.decodeDoubleForKey("End Time Stamp"))
        super.init()
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.musicNoteEvents, forKey: "MusicNoteEvents")
        aCoder.encodeObject(self.transposedNoteEvents, forKey: "Transposed Music Note Events")
        aCoder.encodeInteger(self.count, forKey: "Count")
        aCoder.encodeInteger(self.numberOfOccurences, forKey: "NumberOfOccurences")
        aCoder.encodeDouble(Double(self.endTime), forKey: "End Time Stamp")
    }
    
    func addMusicNote(newMusicNote: MusicNote) {
        //  I create a new MIDINoteMessage because I think it is a C pointer, and we need a separate value for transposed notes
        let newMIDIMess = MIDINoteMessage(
            channel: newMusicNote.midiNoteMess.channel,
            note: newMusicNote.midiNoteMess.note,
            velocity: UInt8(80),
            releaseVelocity: newMusicNote.midiNoteMess.releaseVelocity,
            duration: newMusicNote.midiNoteMess.duration)
        let newTransposedNote = MusicNote(noteMessage: newMIDIMess, timeStamp: newMusicNote.timeStamp)
        self.musicNoteEvents.append(newMusicNote)
        self.transposedNoteEvents.append(newTransposedNote)
        count++
        self.calculateEndTime()
    }
    
    func incrementNumberOfOccurences() {
        self.numberOfOccurences++
    }
    
    private func calculateEndTime() {
        self.endTime = ceil(self.musicNoteEvents[self.musicNoteEvents.count - 1].timeStamp + MusicTimeStamp(self.musicNoteEvents[self.musicNoteEvents.count - 1].midiNoteMess.duration))
    }
    
    /*
    *   This will set each musical snippet to a transposition that can be easily used with any chord.
    *   Each note's velocity will be set to 80 to make applying custom velocities simpler.
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
        for note in self.musicNoteEvents {
            note.transposeNote(halfSteps: halfSteps)
        }
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
        if isMajorKey {
            for note in self.musicNoteEvents {
                note.transposeNoteDiatonically(steps: steps, isMajorKey: isMajorKey, octaves: octaves)
            }
        } else {
            for note in self.musicNoteEvents {
                note.transposeNoteDiatonically(steps: steps, isMajorKey: isMajorKey, octaves: octaves)
            }
        }
        self.zeroTransposeMusicSnippet()
        self.count = self.musicNoteEvents.count
    }
    
    /**
     Transpose a group of notes to fit in the given chord
     
     - Parameters:
     - chord: String
     */
    func transposeToChord(chordName: String, keyOffset: Int) {
        let highestWeightChord = self.getHighestWeightChord()
        if highestWeightChord != "" {
            let transposeOffset = musicChord.getDiatonicTransposeOffset(chord1: highestWeightChord, chord2: chordName)
            if transposeOffset.isDiatonic && !transposeOffset.isSwitchingQuality {
                var transposeSteps = transposeOffset.steps
                if transposeSteps > 4 {
                    transposeSteps = transposeSteps - 7
                }
                self.diatonicTranspose(steps: transposeSteps, octaves: 0)
            } else if !transposeOffset.isDiatonic && transposeOffset.isSwitchingQuality {
                if let chordNotes = musicChord.chordNotes[chordName] {
                    self.chromaticTranspose(halfSteps: transposeOffset.steps)
                    for note in self.musicNoteEvents {
                        for chordNote in chordNotes {
                            if Int(note.midiNoteMess.note % 12) - chordNote == 1 {
                                note.midiNoteMess.note--
                            }
                        }
                    }
                }
            } else {
                var chromSteps = transposeOffset.steps
                if transposeOffset.steps > 6 {
                    chromSteps = chromSteps - 12
                }
                self.chromaticTranspose(halfSteps: chromSteps)
            }
            self.chromaticTranspose(halfSteps: keyOffset)
            self.zeroTransposeMusicSnippet()
            self.count = self.musicNoteEvents.count
        }
    }
    
    /**
     Returns the name of the highest weighted chord
     
     -Returns: `String`
     */
    
    func getHighestWeightChord() -> String {
        var highestWeightChord = ""
        var highestWeight:Float = 0.0
        for nextChord in self.possibleChords {
            if nextChord.weight > highestWeight {
                highestWeight = nextChord.weight
                highestWeightChord = nextChord.chordName
            }
        }
        return highestWeightChord
    }
    /**
     Invert a set of notes chromatically around a pivot note
     
     - pivotNote:   Which pitch to perform the inversion about
     */
    func applyChromaticInversion(pivotNoteNumber pivotNoteNumber: UInt8) {
        for note in self.musicNoteEvents {
            let distanceFromPivot = Int(note.midiNoteMess.note) - Int(pivotNoteNumber)
            let newNoteNumber = Int(pivotNoteNumber) - distanceFromPivot
            note.midiNoteMess.note = UInt8(newNoteNumber)
        }
        self.zeroTransposeMusicSnippet()
        self.count = self.musicNoteEvents.count
    }
    
    /**
     Invert a set of notes diatonically around athe first note
     */
    func applyDiatonicInversion(pivotNoteNumber pivotNoteNumber: UInt8, isMajorKey: Bool = true) {
        var intervals = [Int]()
        var octaves = [Int]()
        for i in 0..<self.musicNoteEvents.count {
            var nextInterval = (Int(self.musicNoteEvents[i].midiNoteMess.note) - Int(pivotNoteNumber))
            if nextInterval > 11 && nextInterval < 24 {
                octaves.append(-1)
            } else if nextInterval > 23 && nextInterval < 36 {
                octaves.append(-2)
            } else if nextInterval < -11 && nextInterval > -24 {
                octaves.append(1)
            } else if nextInterval < -23 && nextInterval > -36 {
                octaves.append(2)
            } else {
                octaves.append(0)
            }
            nextInterval = nextInterval % 12
            switch nextInterval {
            case 1,2:
                intervals.append(-1)
            case 3, 4:
                intervals.append(-2)
            case 5, 6:
                intervals.append(-3)
            case 7:
                intervals.append(-4)
            case 8, 9:
                intervals.append(-5)
            case 10, 11:
                intervals.append(-6)
            case -10, -11:
                intervals.append(6)
            case -8, -9:
                intervals.append(5)
            case -7:
                intervals.append(4)
            case -5, -6:
                intervals.append(3)
            case -3, -4:
                intervals.append(2)
            case -1, -2:
                intervals.append(1)
            default:
                intervals.append(0)
            }
        }
        for i in 0..<intervals.count {
            let currentNote = self.musicNoteEvents[i]
            let stepsToTranspose = intervals[i]
            self.musicNoteEvents[i] = MusicNote(
                noteMessage: MIDINoteMessage(
                    channel: currentNote.midiNoteMess.channel,
                    note: UInt8(pivotNoteNumber),
                    velocity: currentNote.midiNoteMess.velocity,
                    releaseVelocity: currentNote.midiNoteMess.releaseVelocity,
                    duration: currentNote.midiNoteMess.duration),
                timeStamp: currentNote.timeStamp)
            self.musicNoteEvents[i].transposeNoteDiatonically(steps: stepsToTranspose, isMajorKey: isMajorKey, octaves: octaves[i])
        }
        self.zeroTransposeMusicSnippet()
        self.count = self.musicNoteEvents.count
    }
    
    /**
     Returns the complete retrograde of a set of notes (pitch and rhythm)
     
     - pivotNumber:  Which pitch to perform the inversion about
     */
    func applyRetrograde() {
        var retroNotes = [MusicNote]()
        var currentTime: MusicTimeStamp = endTime % 1.0
        for (var i = self.musicNoteEvents.count - 1; i >= 0; i--) {
            let currentNote = self.musicNoteEvents[i].getNoteCopy()
            currentNote.timeStamp = currentTime
            retroNotes.append(currentNote)
            currentTime = currentTime + MusicTimeStamp(currentNote.midiNoteMess.duration)
        }
        self.musicNoteEvents = retroNotes
        self.zeroTransposeMusicSnippet()
        self.count = self.musicNoteEvents.count
    }
    
    /**
     Returns the melodic retrograde of a set of notes
     
     */
    func applyMelodicRetrograde() {
        var retroNotes = [MusicNote]()
        for (var i = self.musicNoteEvents.count - 1; i >= 0; i--) {
            let currentNote = self.musicNoteEvents[i].getNoteCopy()
            currentNote.timeStamp = self.musicNoteEvents[self.count - 1 - i].timeStamp
            currentNote.midiNoteMess.duration = self.musicNoteEvents[self.count - 1 - i].midiNoteMess.duration
            retroNotes.append(currentNote)
        }
        self.musicNoteEvents = retroNotes
        self.zeroTransposeMusicSnippet()
        self.count = self.musicNoteEvents.count
    }
    
    /**
     Returns the rhythmic retrograde of a set of notes
     
     */
    func applyRhythmicRetrograde() {
        var retroNotes = [MusicNote]()
        var currentTime: MusicTimeStamp = endTime % 1.0
        var durations = [Float32]()
        for (var i = self.musicNoteEvents.count - 1; i >= 0; i--) {
            durations.append(self.musicNoteEvents[i].midiNoteMess.duration)
        }
        for i in 0..<self.count {
            let currentNote = self.musicNoteEvents[i].getNoteCopy()
            currentNote.timeStamp = currentTime
            currentNote.midiNoteMess.duration = durations[i]
            currentTime = currentTime + MusicTimeStamp(durations[i])
            retroNotes.append(currentNote)
        }
        self.musicNoteEvents = retroNotes
        self.zeroTransposeMusicSnippet()
        self.count = self.musicNoteEvents.count
    }
    
    /**
     Merges this MusicSnippet with another based on weights for each snippet
     
     - Parameters:
     - firstWeight:      weight of this passage (the second passage weight is (1 - firstWeight)
     - secondPassage:    the first set of notes to be merged
     - Returns: A new `MusicSnippet` of notes based on the two passages
     */
    func mergeNotePassages(firstWeight firstWeight: Double, secondSnippet: MusicSnippet) -> MusicSnippet {
        let returnSnippet = MusicSnippet()
        let secSnippetCopy = MusicSnippet(notes: secondSnippet.musicNoteEvents)
        secSnippetCopy.transposeToChord(self.getHighestWeightChord(), keyOffset: 0)
        //  Get fragments from each MusicSnippet
        let maxCount = min(self.count, secSnippetCopy.count)
        let numberOfFirstWeightBits = Int(Double(maxCount) * firstWeight) - 1
        let randomStartIndex = Int.random(0..<(maxCount - numberOfFirstWeightBits))
        var bitmask = [Int]()
        for i in 0..<maxCount {
            if i < randomStartIndex || i > randomStartIndex + numberOfFirstWeightBits {
                bitmask.append(0)
            } else {
                bitmask.append(1)
            }
        }
        var currentTime = MusicTimeStamp(0.0)
        for i in 0..<bitmask.count {
            if bitmask[i] == 1 {
                let newNote = self.musicNoteEvents[i].getNoteCopy()
                newNote.timeStamp = currentTime
                returnSnippet.addMusicNote(newNote)
                currentTime = currentTime + MusicTimeStamp(newNote.midiNoteMess.duration)
            } else {
                let newNote = secSnippetCopy.musicNoteEvents[i].getNoteCopy()
                newNote.timeStamp = currentTime
                returnSnippet.addMusicNote(newNote)
                currentTime = currentTime + MusicTimeStamp(newNote.midiNoteMess.duration)
            }
        }
        let medianNote = self.musicNoteEvents[0].midiNoteMess.note
        for note in returnSnippet.musicNoteEvents {
            let differenceFromMedian = Int(note.midiNoteMess.note) - Int(medianNote)
            if  differenceFromMedian > 8 && differenceFromMedian < 14 {
                note.transposeNote(halfSteps: -12)
            } else if differenceFromMedian > 13 {
                note.transposeNote(halfSteps: -24)
            } else if differenceFromMedian < -8 && differenceFromMedian > -14 {
                note.transposeNote(halfSteps: 12)
            } else if differenceFromMedian < -13 {
                note.transposeNote(halfSteps: 24)
            }
        }
        returnSnippet.zeroTransposeMusicSnippet()
        returnSnippet.count = returnSnippet.musicNoteEvents.count
        return returnSnippet
    }
    
    /**
     Merges this MusicSnippet with another based on weights for each snippet by dividing it by beat
     
     - Parameters:
     - firstWeight:      weight of this passage (the second passage weight is (1 - firstWeight)
     - chanceOfRest:    Probability of silence
     - secondPassage:    the first set of notes to be merged
     - Returns: A new `MusicSnippet` of notes based on the two passages
     */
    func mergeNotePassagesRhythmically(firstWeight firstWeight: Double, chanceOfRest: Double, secondSnippet: MusicSnippet, numberOfBeats: Double) -> MusicSnippet {
        let returnSnippet = MusicSnippet()
        let secSnippetCopy = MusicSnippet(notes: secondSnippet.musicNoteEvents)
        secSnippetCopy.transposeToChord(self.getHighestWeightChord(), keyOffset: 0)
        let numberOfFirstWeightBits = Int(Double(numberOfBeats) * firstWeight) - 1
        let randomStartIndex = Int.random(0..<(Int(numberOfBeats) - numberOfFirstWeightBits))
        var bitmask = [Bool]()
        for i in 0..<Int(numberOfBeats) {
            if i < randomStartIndex || i > randomStartIndex + numberOfFirstWeightBits {
                bitmask.append(false)
            } else {
                bitmask.append(true)
            }
        }
        
        var currentStart = MusicTimeStamp(0.0)
        var currentEnd = MusicTimeStamp(1.0)
        
        for nextBit in bitmask {
            if nextBit {
                for note in self.musicNoteEvents {
                    if note.timeStamp < currentEnd && note.timeStamp >= currentStart {
                        returnSnippet.addMusicNote(note)
                    }
                }
            } else {
                for note in secondSnippet.musicNoteEvents {
                    if note.timeStamp < currentEnd && note.timeStamp >= currentStart {
                        returnSnippet.addMusicNote(note)
                    }
                }
            }
            currentStart = currentStart + 1.0
            currentEnd = currentEnd + 1.0
        }
        let previousNote = returnSnippet.musicNoteEvents[0]
        for i in 1..<returnSnippet.musicNoteEvents.count {
            let leapSteps = Int(previousNote.midiNoteMess.note) - Int(returnSnippet.musicNoteEvents[i].midiNoteMess.note)
            if leapSteps > 8 && leapSteps < 18 {
                returnSnippet.musicNoteEvents[i].transposeNote(halfSteps: 12)
            } else if leapSteps > 17 {
                returnSnippet.musicNoteEvents[i].transposeNote(halfSteps: 24)
            } else if leapSteps < -8 && leapSteps > -18 {
                returnSnippet.musicNoteEvents[i].transposeNote(halfSteps: -12)
            } else if leapSteps < -17 {
                returnSnippet.musicNoteEvents[i].transposeNote(halfSteps: -24)
            }
        }
        returnSnippet.zeroTransposeMusicSnippet()
        returnSnippet.count = returnSnippet.musicNoteEvents.count
        return returnSnippet
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
        if endIndex - startIndex > 0 {
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
                for i in startIndex...endIndex {
                    let newNote = self.musicNoteEvents[i].getNoteCopy()
                    newNote.timeStamp = newNote.timeStamp - firstTimeStampOffset
                    returnNotes.append(newNote)
                }
            }
            return MusicSnippet(notes: returnNotes)
        }
        return self
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
        if endIndex - startIndex > 0 {
            var currentVel = startVelocity
            let numerator = abs(Int(endVelocity) - Int(startVelocity))
            let velocityIncrement = UInt8(numerator) / UInt8(endIndex - startIndex)
            if endIndex < self.musicNoteEvents.count {
                for i in startIndex...endIndex {
                    self.musicNoteEvents[i].midiNoteMess.velocity = currentVel
                    
                    if startVelocity < endVelocity {
                        currentVel = currentVel + velocityIncrement
                    } else {
                        if velocityIncrement < currentVel {
                            currentVel = currentVel - velocityIncrement
                        }
                    }
                }
            }
        } else {
            self.musicNoteEvents[startIndex].midiNoteMess.velocity = startVelocity
        }
        self.zeroTransposeMusicSnippet()
        self.count = self.musicNoteEvents.count
    }
    
    /**
     Attempts to humanize the feel of a set of notes based on beat and bar
     
     */
    func humanizeNotes() {
        for note in self.musicNoteEvents {
            if note.timeStamp % 1 == 0 {
                note.midiNoteMess.velocity = note.midiNoteMess.velocity + UInt8(Int.random(10...20))
                if note.midiNoteMess.velocity > 127 {
                    note.midiNoteMess.velocity = 127
                }
            } else {
                if note.midiNoteMess.velocity > 10 {
                    note.midiNoteMess.velocity = UInt8(Int(note.midiNoteMess.velocity) + Int.random(-10...10))
                    if note.midiNoteMess.velocity > 127 {
                        note.midiNoteMess.velocity = 127
                    }
                }
            }
            note.timeStamp = note.timeStamp + MusicTimeStamp(Double.random() * 0.025)
        }
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
        self.zeroTransposeMusicSnippet()
        self.count = self.musicNoteEvents.count
    }
    
    
    /**
     Multiplies all duarations by a multiplier and returns a new snippet
     
     - Parameters:
     - multiplier:   How much to multiply durations by
     - Returns: `MusicSnippet`
     */
    func getAugmentedPassageRhythm(multiplier multiplier: Double) -> MusicSnippet {
        var returnNotes = [MusicNote]()
        for nextNote in self.musicNoteEvents {
            let newNote = nextNote.getNoteCopy()
            newNote.midiNoteMess.duration = newNote.midiNoteMess.duration * Float32(multiplier)
            newNote.timeStamp = newNote.timeStamp * MusicTimeStamp(multiplier)
            returnNotes.append(newNote)
        }
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
        if possibleChords != nil {
            retString = retString + "Possible Chords: \n"
            for chord in self.possibleChords {
                retString = retString + "\(chord.chordName): \(chord.weight)  "
            }
        }
        retString = retString + "\nEnd timestamp: \(self.endTime)\n"
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
