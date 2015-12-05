//
//  MusicChord.swift
//  AIComposer
//
//  This is a singleton class to generate chords based on a set of notes.
//  TODO: The 'guessing' algorithm can certainly be tweaked
//      It is mostly ok, but makes some odd choices.
//      I may alter this to take MusicNote's for processing.
//      From that I can also take note durations into account.
//
//  * Bow ties are cool! *
//
//  Created by Jess Hendricks on 10/29/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import Cocoa
import AudioToolbox

struct Chord {
    var name: String!
    var weight: Float!
    
    init(name: String, weight: Float = 1.0) {
        self.name = name
        self.weight = weight
    }
}

class ChordController: NSObject {
    
    
    /*
    *   Returns a Chord with the notes given if one exists.
    */
    func getChordFromNotes(notes: [MusicNote]) -> Chord? {
        
        //  A dictionary to find chord names based on an array of note numbers
        let chords = [
            [0,4,7]:"C", [1,5,8]:"Db", [2,6,9]:"D", [3,7,10]:"Eb", [4,8,11]:"E", [0,5,9]:"F",
            [1,6,10]:"F#", [2,7,11]:"G", [0,3,8]:"Ab", [1,4,9]:"A", [2,5,10]:"Bb", [3,6,11]:"B",
            
            [0,3,7]:"Cm", [1,4,8]:"Dbm", [2,5,9]:"Dm", [3,6,10]:"Ebm", [4,7,11]:"Em", [0,5,8]:"Fm",
            [1,6,9]:"F#m", [2,7,10]:"Gm", [3,8,11]:"Abm", [0,4,9]:"Am", [1,5,10]:"Bbm", [2,6,11]:"Bm",
            
            [0,3,6]:"Cdim", [1,4,7]:"Dbdim", [2,5,8]:"Ddim", [3,6,9]:"Ebdim", [4,7,10]:"Edim", [5,8,11]:"Fdim",
            [0,6,9]:"F#dim", [1,7,10]:"Gdim", [2,8,11]:"Abdim", [0,3,9]:"Adim", [1,4,10]:"Bbdim", [2,5,11]:"Bdim"
        ]
        
//        let romanNumerals = [
//            [0,4,7]:"I", [1,5,8]:"N6", [2,6,9]:"V/V", [3,7,10]:"III", [4,8,11]:"V/vi", [0,5,9]:"IV",
//            [2,7,11]:"V", [0,3,8]:"bVI", [1,4,9]:"V/ii", [2,5,10]:"bVII", [3,6,11]:"V/iii",
//            
//            [0,3,7]:"i", [2,5,9]:"ii", [4,7,11]:"iii", [0,5,8]:"iv",
//            [2,7,10]:"ii/IV", [0,4,9]:"vi", [2,6,11]:"ii/vi",
//            
//            [1,4,7]:"viio/ii", [4,7,10]:"viio/IV",
//            [0,6,9]:"viio/V", [2,8,11]:"viio/vi", [2,5,11]:"viio",
//            
//            [0, 4, 7, 10]:"V7/IV", [0, 2, 6, 9]:"V7/V", [2, 4, 8, 11]:"V7/vi", [0, 3, 5, 9]:"V7/bVII",
//            [2, 5, 7, 11]:"V7", [1, 4, 7, 9]:"V7/ii", [3, 6, 9, 11]:"V7/iii"
//        ]
        var noteNums = [Int]()
        for note in notes {
            noteNums.append(Int(note.midiNoteMess.note))
        }
        if let returnChordName = chords[noteNums] {
            return Chord(name: returnChordName)
        }
        return nil
    }
    
    
    /*
    *   Returns an array of Chords based on a single note
    */
    func getChordsFromSingleNote(note: MusicNote) -> [Chord] {
        let noteNum = Int(note.noteValue)
        let singleNoteChordPossibles = [
            0: [Chord(name: "C", weight: 0.5), Chord(name: "Am", weight: 0.2), Chord(name: "F", weight: 0.3)],
            1: [Chord(name: "Db", weight: 0.5), Chord(name: "A", weight: 0.2), Chord(name: "F#", weight: 0.3)],
            2: [Chord(name: "Dm", weight: 0.5), Chord(name: "Bdim", weight: 0.2), Chord(name: "G", weight: 0.3)],
            3: [Chord(name: "Eb", weight: 0.5), Chord(name: "Cm", weight: 0.2), Chord(name: "Ab", weight: 0.3)],
            4: [Chord(name: "Em", weight: 0.5), Chord(name: "C", weight: 0.2), Chord(name: "Am", weight: 0.3)],
            5: [Chord(name: "F", weight: 0.5), Chord(name: "Dm", weight: 0.2), Chord(name: "Bdim", weight: 0.3)],
            6: [Chord(name: "F#", weight: 0.1), Chord(name: "F#m", weight: 0.1), Chord(name: "F#dim", weight: 0.1), Chord(name: "D", weight: 0.4), Chord(name: "B", weight: 0.15), Chord(name: "Bm", weight: 0.15)],
            7: [Chord(name: "G", weight: 0.5), Chord(name: "Em", weight: 0.2), Chord(name: "C", weight: 0.3)],
            8: [Chord(name: "Ab", weight: 0.5), Chord(name: "Fm", weight: 0.2), Chord(name: "Db", weight: 0.3)],
            9: [Chord(name: "Am", weight: 0.5), Chord(name: "F", weight: 0.2), Chord(name: "Dm", weight: 0.3)],
            10: [Chord(name: "Bb", weight: 0.5), Chord(name: "Gm", weight: 0.2), Chord(name: "Eb", weight: 0.3)],
            11: [Chord(name: "Bdim", weight: 0.5), Chord(name: "G", weight: 0.2), Chord(name: "Em", weight: 0.3)]
        ]
//        let singleNoteAnalysisPossibles = [
//            0: [Chord(name: "I", weight: 0.6), Chord(name: "vi", weight: 0.2), Chord(name: "IV", weight: 0.2)],
//            1: [Chord(name: "V/ii", weight: 0.9), Chord(name: "viio/ii", weight: 0.1)],
//            2: [Chord(name: "ii", weight: 0.3), Chord(name: "V", weight: 0.6), Chord(name: "viio", weight: 0.1)],
//            3: [Chord(name: "i", weight: 0.5), Chord(name: "bIII", weight: 0.2), Chord(name: "bVI", weight: 0.3)],
//            4: [Chord(name: "I", weight: 0.5), Chord(name: "iii", weight: 0.4), Chord(name: "vi", weight: 0.1)],
//            5: [Chord(name: "IV", weight: 0.6), Chord(name: "ii", weight: 0.3), Chord(name: "viio", weight: 0.1)],
//            6: [Chord(name: "V/V", weight: 0.9), Chord(name: "viio/V", weight: 0.1)],
//            7: [Chord(name: "V", weight: 0.7), Chord(name: "I", weight: 0.2), Chord(name: "iii", weight: 0.1)],
//            8: [Chord(name: "V/vi", weight: 0.75), Chord(name: "viio/vi", weight: 0.2), Chord(name: "bVI", weight: 0.05)],
//            9: [Chord(name: "vi", weight: 0.5), Chord(name: "IV", weight: 0.4), Chord(name: "ii", weight: 0.1)],
//            10: [Chord(name: "bVII", weight: 0.8), Chord(name: "ii/IV", weight: 0.2)],
//            11: [Chord(name: "V", weight: 0.75), Chord(name: "viio", weight: 0.2), Chord(name: "iii", weight: 0.05)]
//        ]
        return singleNoteChordPossibles[noteNum]!
    }
    
    /*
    *   Returns an array of MusicNotes that are members of the given chord
    */
    func getChordNotesForChord(chord: Chord) -> [MusicNote]? {
        
        //  A dictionary to get an array of note numbers from a chord name string
        let chordNotes = [
            "C":[0,4,7], "Db":[1,5,8], "D":[2,6,9], "Eb":[3,7,10], "E":[4,8,11], "F":[0,5,9],
            "F#":[1,6,10], "G":[2,7,11], "Ab":[0,3,8], "A":[1,4,9], "Bb":[2,5,10], "B":[3,6,11],
            
            "Cm":[0,3,7], "Dbm":[1,4,8], "Dm":[2,5,9], "Ebm":[3,6,10], "Em":[4,7,11], "Fm":[0,5,8],
            "F#m":[1,6,9], "Gm":[2,7,10], "Abm":[3,8,11], "Am":[0,4,9], "Bbm":[1,5,10], "Bm":[2,6,11],
            
            "Cdim": [0,3,6], "Dbdim":[1,4,7], "Ddim":[2,5,8], "Ebdim":[3,6,9], "Edim":[4,7,10], "Fdim":[5,8,11],
            "F#dim":[0,6,9], "Gdim":[1,7,10], "Abdim":[2,8,11], "Adim":[0,3,9], "Bbdim":[1,4,10], "Bdim":[2,5,11]
        ]
        // This is for a later version:
//        let romanNumeralNotes = [
//            "I":[0,4,7], "N6":[1,5,8], "V/V":[2,6,9], "bIII":[3,7,10], "V/vi":[4,8,11], "IV":[0,5,9],
//            "V":[2,7,11], "bVI":[0,3,8], "V/ii":[1,4,9], "bVII":[2,5,10], "V/iii":[3,6,11],
//            
//            "i":[0,3,7], "ii":[2,5,9], "iii":[4,7,11], "iv":[0,5,8],
//            "ii/IV":[2,7,10], "vi":[0,4,9], "ii/vi":[2,6,11],
//            
//            "viio/ii":[1,4,7], "viio/IV":[4,7,10],
//            "viio/V":[0,6,9], "viio/vi":[2,8,11], "viio":[2,5,11],
//            
//            "V7/IV":[0, 4, 7, 10], "V7/V":[0, 2, 6, 9], "V7/vi":[2, 4, 8, 11], "V7/bVII":[0, 3, 5, 9],
//            "V7":[2, 5, 7, 11], "V7/ii":[1, 4, 7, 9], "V7/iii":[3, 6, 9, 11]
//        ]
        if let noteNums = chordNotes[chord.name] {
            var returnNotes = [MusicNote]()
            for noteNum in noteNums {
                returnNotes.append(MusicNote(
                    noteMessage: MIDINoteMessage(
                        channel: 0,
                        note: UInt8(noteNum),
                        velocity: 64,
                        releaseVelocity: 0,
                        duration: 1.0),
                    timeStamp: 0.0))
            }
            return returnNotes
        }
        return nil
    }
    
    /*
    *   Generates a list of all of the possible chords based on notes in the melody.
    *   From this, maybe it can learn how to judge harmony based on melody.
    *   If that is too hard, we can just come up with an algorithm to pick the chord
    *   based on weigths (likely duration of notes)
    */
    func generatePossibleChords(notes: [MusicNote]) -> [Chord] {
        var noteArray = [Int]()
        var totalDurationOfAllNotes: Float = 0.0
        for note in notes {
            noteArray.append(Int(note.midiNoteMess.note))
        }
        if let retChord = self.getChordFromNotes(notes) {
            return [retChord]
        }
        
        var returnChords = [Chord]()
        //  Check to see if any chords are in the noteNumbers array, if so add them to an array for choosing
        //        let noteNumberSet:Set = Set(notes)
        var foundFullChord = false
        
        for i in 0..<12 {
            let majorChord:Set = [i, (i+4)%12, (i+7)%12]
            let minorChord:Set = [i, (i+3)%12, (i+7)%12]
            let dimChord:Set = [i, (i+3)%12, (i+6)%12]
            
            if let newChord = getChordSubset(notes, chordSet: majorChord, fullChordNotes: self.getSortedNotesWithNoteNumbers([i, (i+4)%12, (i+7)%12]) ) {
                returnChords = self.addPossibleChord(newChord.name, weight: newChord.weight, possibleChords: returnChords)
                foundFullChord = true
            }
            
            if let newChord = getChordSubset(notes, chordSet: minorChord, fullChordNotes: self.getSortedNotesWithNoteNumbers([i, (i+3)%12, (i+7)%12])) {
                returnChords = self.addPossibleChord(newChord.name, weight: newChord.weight, possibleChords: returnChords)
                foundFullChord = true
            }
            
            if let newChord = getChordSubset(notes, chordSet: dimChord, fullChordNotes: self.getSortedNotesWithNoteNumbers([i, (i+3)%12, (i+6)%12])) {
                returnChords = self.addPossibleChord(newChord.name, weight: newChord.weight, possibleChords: returnChords)
                foundFullChord = true
            }
        }
        
        
        if !foundFullChord {
            for i in 0..<12 {
                //  If no full chord has been found, it will search for partial chords
                //  Divide its weight in half to account for the ambiguity of the analysis?
                let majorChordThird:Set = [i, (i+4)%12]
                let majorChordFourth:Set = [i, (i+5)%12]
                let minorChordThird:Set = [i, (i+3)%12]
                
                if let newChord = getChordSubset(notes, chordSet: majorChordFourth, fullChordNotes: self.getSortedNotesWithNoteNumbers([i, (i+5)%12, (i+9)%12])) {
                    returnChords = self.addPossibleChord(newChord.name, weight: newChord.weight / 2, possibleChords: returnChords)
                    //  Because this is a fourth, it should still search for other possiblities.
                }
                
                if let newChord = getChordSubset(notes, chordSet: majorChordThird, fullChordNotes: self.getSortedNotesWithNoteNumbers([i, (i+4)%12, (i+7)%12])) {
                    returnChords = self.addPossibleChord(newChord.name, weight: newChord.weight / 4, possibleChords: returnChords)
                }
                
                if let newChord = getChordSubset(notes, chordSet: minorChordThird, fullChordNotes: self.getSortedNotesWithNoteNumbers([i, (i+3)%12, (i+7)%12])) {
                    returnChords = self.addPossibleChord(newChord.name, weight: newChord.weight / 4, possibleChords: returnChords)
                }
            }
        }
        
        if returnChords.count == 0 {
            returnChords = self.getChordsFromSingleNote(notes[0])
        }
        
        //  Sets the weights to values between 0.0 and 1.0 such that all values total 1.0
        for returnChord in returnChords {
            totalDurationOfAllNotes = totalDurationOfAllNotes + returnChord.weight
        }
        for i in 0..<returnChords.count {
            returnChords[i].weight = returnChords[i].weight / totalDurationOfAllNotes
        }
        return returnChords
    }
    
    private func getSortedNotesWithNoteNumbers(noteNums: [Int]) -> [MusicNote] {
        var returnNotes = [MusicNote]()
        let sortedNums = noteNums.sort()
        for noteNum in sortedNums {
            returnNotes.append(MusicNote(
                noteMessage: MIDINoteMessage(
                    channel: 0,
                    note: UInt8(noteNum),
                    velocity: 64,
                    releaseVelocity: 0,
                    duration: 1.0),
                timeStamp: 0.0))
        }
        return returnNotes
    }
    
    /*
    *   Adds the chord to possible chords, increases its weight if it is already in the array
    */
    private func addPossibleChord(name: String, weight: Float, var possibleChords: [Chord]) -> [Chord] {
        for var possibleChord in possibleChords {
            if possibleChord.name == name {
                possibleChord.weight = possibleChord.weight + weight
                return possibleChords
            }
        }
        possibleChords.append(Chord(name: name, weight: weight))
        return possibleChords
    }
    
    /*
    *   Gets the chord name and sum of durations of the notes
    */
    private func getChordSubset(noteArray: [MusicNote], chordSet: Set<Int>, fullChordNotes: [MusicNote]) -> Chord? {
        var weight: Float = 0.0
        var retChord: Chord!
        var noteNumberSet: Set = Set<Int>()
        for note in noteArray {
            noteNumberSet.insert(Int(note.midiNoteMess.note))
        }
        if chordSet.contains(Int(noteArray[0].midiNoteMess.note)) {
            weight = weight + noteArray[0].midiNoteMess.duration
        }
        if chordSet.isSubsetOf(noteNumberSet) {
            var chordArray = Array<Int>(chordSet)
            chordArray = chordArray.sort()
            if let newChord = self.getChordFromNotes(fullChordNotes) {
                retChord = newChord
            }
            for note in noteArray {
                for chord in chordArray {
                    if chord == Int(note.midiNoteMess.note) {
                        weight = weight + Float(note.midiNoteMess.duration)
                    }
                }
            }
            retChord.weight = weight
            return retChord
        }
        return nil
    }
    
    
    private func getTransposeOffset(chord: Chord) -> Int? {
        //  A dictionary of the number of half steps each chord is from having a root of C
        let chordOffsets = [
            "C":0, "Db":1, "D":2, "Eb":3, "E":4, "F":5,
            "F#":6, "G":7, "Ab":8, "A":9, "Bb":10, "B":11,
            
            "Cm":0, "Dbm":1, "Dm":2, "Ebm":3, "Em":4, "Fm":5,
            "F#m":6, "Gm":7, "Abm":8, "Am":9, "Bbm":10, "Bm":11,
            
            "Cdim":0, "Dbdim":1, "Ddim":2, "Ebdim":3, "Edim":4, "Fdim":5,
            "F#dim":6, "Gdim":7, "Abdim":8, "Adim":9, "Bbdim":10, "Bdim":11
        ]
        if let offset = chordOffsets[chord.name] {
            return offset
        }
        return nil
    }
    
    private func getDiatonicOffset(chord chord: Chord) -> Int? {
        let diatonicChordOffsets = [
            "C":0, "Dm":1, "Em":2, "F":3, "G":4, "Am":5, "Bdim":6
        ]
        if let offset = diatonicChordOffsets[chord.name] {
            return offset
        }
        return nil
    }
    
    func getOffsetBetweenChords(chord1 chord1: Chord, chord2: Chord) -> Int? {
        
        if let offset1 = self.getTransposeOffset(chord1) {
            if let offset2 = self.getTransposeOffset(chord2) {
                var offset = offset1 - offset2
                //  Transpose down if offset is greater than 6
                if offset > 6 {
                    offset = offset - 12
                } else if offset < -6 {
                    offset = offset + 12
                }
                return offset
            }
        }
        return nil
    }
    
    func getScaleForChord(chord chord: Chord) -> [Int]? {
        var chordScales = [String: [Int]]()
        chordScales["C"] =     [0, 2, 4, 5, 7, 9, 11]
        chordScales["Db"] =    [0, 1, 3, 5, 6, 8, 10]
        chordScales["D"] =     [0, 2, 4, 6, 7, 9, 11]
        chordScales["Eb"] =    [0, 2, 3, 5, 7, 8, 10]
        chordScales["E"] =     [0, 2, 4, 6, 8, 9, 11]
        chordScales["F"] =     [0, 2, 4, 5, 7, 9, 11]
        chordScales["F#"] =    [1, 3, 4, 6, 8, 10, 11]
        chordScales["G"] =     [0, 2, 4, 5, 7, 9, 11]
        chordScales["Ab"] =    [0, 2, 3, 5, 7, 8, 10]
        chordScales["A"] =     [1, 2, 4, 5, 7, 9, 11]
        chordScales["Bb"] =    [0, 2, 3, 5, 7, 9, 10]
        chordScales["B"] =     [1, 3, 4, 6, 7, 9, 11]
        
        chordScales["Cm"] =    [0, 2, 3, 5, 7, 8, 10]
        chordScales["Dbm"] =   [1, 3, 4, 6, 8, 9, 11]
        chordScales["Dm"] =    [0, 2, 4, 5, 7, 9, 11]
        chordScales["Ebm"] =   [0, 1, 3, 5, 6, 8, 10]
        chordScales["Em"] =    [0, 2, 4, 5, 7, 9, 11]
        chordScales["Fm"] =    [0, 2, 3, 5, 7, 8, 10]
        chordScales["F#m"] =   [1, 3, 4, 6, 8, 9, 11]
        chordScales["Gm"] =    [0, 2, 3, 5, 7, 9, 10]
        chordScales["Abm"] =   [1, 3, 4, 6, 8, 10, 11]
        chordScales["Am"] =    [0, 2, 4, 5, 7, 9, 11]
        chordScales["Bbm"] =   [0, 1, 3, 5, 6, 8, 10]
        chordScales["Bm"] =    [1, 2, 4, 6, 7, 9, 11]
        
        chordScales["Cdim"] =  [0, 1, 3, 5, 6, 8, 10]
        chordScales["Dbdim"] = [1, 2, 4, 6, 7, 9, 11]
        chordScales["Ddim"] =  [0, 2, 3, 5, 7, 8, 10]
        chordScales["Ebdim"] = [1, 3, 4, 6, 8, 9, 11]
        chordScales["Edim"] =  [0, 2, 4, 5, 7, 9, 10]
        chordScales["Fdim"] =  [1, 3, 5, 6, 8, 10, 11]
        chordScales["F#dim"] = [0, 2, 4, 6, 7, 9, 11]
        chordScales["Gdim"] =  [0, 1, 3, 5, 7, 8, 10]
        chordScales["Abdim"] = [1, 2, 4, 6, 8, 9, 11]
        chordScales["Adim"] =  [0, 2, 3, 5, 7, 9, 10]
        chordScales["Bbdim"] = [1, 3, 4, 6, 8, 10, 11]
        chordScales["Bdim"] =  [0, 2, 4, 5, 7, 9, 11]
//        
//        var romanNumberScales = [String: [Int]]()
//        romanNumberScales["I"] =     [0, 2, 4, 5, 7, 9, 11]
//        romanNumberScales["N6"] =    [0, 1, 3, 5, 6, 8, 10]
//        romanNumberScales["V/V"] =     [0, 2, 4, 6, 7, 9, 11]
//        romanNumberScales["bIII"] =    [0, 2, 3, 5, 7, 8, 10]
//        romanNumberScales["V/vi"] =     [0, 2, 4, 6, 8, 9, 11]
//        romanNumberScales["IV"] =     [0, 2, 4, 5, 7, 9, 11]
//        romanNumberScales["V"] =     [0, 2, 4, 5, 7, 9, 11]
//        romanNumberScales["bVI"] =    [0, 2, 3, 5, 7, 8, 10]
//        romanNumberScales["V/ii"] =     [1, 2, 4, 5, 7, 9, 11]
//        romanNumberScales["bVII"] =    [0, 2, 3, 5, 7, 9, 10]
//        romanNumberScales["V/iii"] =     [1, 3, 4, 6, 7, 9, 11]
//        
//        romanNumberScales["i"] =    [0, 2, 3, 5, 7, 8, 10]
//        romanNumberScales["ii"] =    [0, 2, 4, 5, 7, 9, 11]
//        romanNumberScales["iii"] =    [0, 2, 4, 5, 7, 9, 11]
//        romanNumberScales["iv"] =    [0, 2, 3, 5, 7, 8, 10]
//        romanNumberScales["ii/IV"] =    [0, 2, 3, 5, 7, 9, 10]
//        romanNumberScales["vi"] =    [0, 2, 4, 5, 7, 9, 11]
//        romanNumberScales["ii/vi"] =    [1, 2, 4, 6, 7, 9, 11]
//        
//        romanNumberScales["viio/ii"] = [1, 2, 4, 6, 7, 9, 11]
//        romanNumberScales["viio/IV"] =  [0, 2, 4, 5, 7, 9, 10]
//        romanNumberScales["viio/V"] = [0, 2, 4, 6, 7, 9, 11]
//        romanNumberScales["viio/vi"] = [1, 2, 4, 6, 8, 9, 11]
//        romanNumberScales["viio"] =  [0, 2, 4, 5, 7, 9, 11]
//        
//        romanNumberScales["V7/IV"] = [0, 2, 4, 5, 7, 9, 10]
//        romanNumberScales["V7/V"] = [0, 2, 4, 6, 7, 9, 11]
//        romanNumberScales["V7/vi"] = [0, 2, 4, 6, 8, 9, 11]
//        romanNumberScales["V7/bVII"] = [0, 2, 3, 5, 7, 9, 10]
//        romanNumberScales["V7"] = [0, 2, 4, 5, 7, 9, 11]
//        romanNumberScales["V7/ii"] = [1, 2, 4, 5, 7, 9, 11]
//        romanNumberScales["V7/iii"] = [1, 3, 4, 6, 7, 9, 11]
        
        if let scale = chordScales[chord.name] {
            return scale
        }
        return nil
    }
    
}
