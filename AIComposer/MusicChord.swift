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
    let name: String!
    var weight: Float!
}

private let MusicChordInstance = MusicChord()

class MusicChord: NSObject {
    
    //  A dictionary to find chord names based on an array of note numbers
    let chords = [
        [0,4,7]:"C", [1,5,8]:"Db", [2,6,9]:"D", [3,7,10]:"Eb", [4,8,11]:"E", [0,5,9]:"F",
        [1,6,10]:"F#", [2,7,11]:"G", [0,3,8]:"Ab", [1,4,9]:"A", [2,5,10]:"Bb", [3,6,11]:"B",
        
        [0,3,7]:"Cm", [1,4,8]:"Dbm", [2,5,9]:"Dm", [3,6,10]:"Ebm", [4,7,11]:"Em", [0,5,8]:"Fm",
        [1,6,9]:"F#m", [2,7,10]:"Gm", [3,8,11]:"Abm", [0,4,9]:"Am", [1,5,10]:"Bbm", [2,6,11]:"Bm",
        
        [0,3,6]:"Cdim", [1,4,7]:"Dbdim", [2,5,8]:"Ddim", [3,6,9]:"Ebdim", [4,7,10]:"Edim", [5,8,11]:"Fdim",
        [0,6,9]:"F#dim", [1,7,10]:"Gdim", [2,8,11]:"Abdim", [0,3,9]:"Adim", [1,4,10]:"Bbdim", [2,5,11]:"Bdim"
    ]
    
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
    
    //  A dictionary to get an array of note numbers from a chord name string
    let chordNotes = [
        "C":[0,4,7], "Db":[1,5,8], "D":[2,6,9], "Eb":[3,7,10], "E":[4,8,11], "F":[0,5,9],
        "F#":[1,6,10], "G":[2,7,11], "Ab":[0,3,8], "A":[1,4,9], "Bb":[2,5,10], "B":[3,6,11],
        
        "Cm":[0,3,7], "Dbm":[1,4,8], "Dm":[2,5,9], "Ebm":[3,6,10], "Em":[4,7,11], "Fm":[0,5,8],
        "F#m":[1,6,9], "Gm":[2,7,10], "Abm":[3,8,11], "Am":[0,4,9], "Bbm":[1,5,10], "Bm":[2,6,11],
        
        "Cdim": [0,3,6], "Dbdim":[1,4,7], "Ddim":[2,5,8], "Ebdim":[3,6,9], "Edim":[4,7,10], "Fdim":[5,8,11],
        "F#dim":[0,6,9], "Gdim":[1,7,10], "Abdim":[2,8,11], "Adim":[0,3,9], "Bbdim":[1,4,10], "Bdim":[2,5,11]
    ]
    
    //  A dictionary of the number of half steps each chord is from having a root of C
    let chordOffsets = [
        "C":0, "Db":1, "D":2, "Eb":3, "E":4, "F":5,
        "F#":6, "G":7, "Ab":8, "A":9, "Bb":10, "B":11,
        
        "Cm":0, "Dbm":1, "Dm":2, "Ebm":3, "Em":4, "Fm":5,
        "F#m":6, "Gm":7, "Abm":8, "Am":9, "Bbm":10, "Bm":11,
        
        "Cdim":0, "Dbdim":1, "Ddim":2, "Ebdim":3, "Edim":4, "Fdim":5,
        "F#dim":6, "Gdim":7, "Abdim":8, "Adim":9, "Bbdim":10, "Bdim":11
    ]
    
    //  A dictionary of diatonic chords in the key of C and their offsets.
    //  If the chords are not found when attempting to traspose, then an alternate method must be used.
    //  Maybe chromaticTranspose?
    let diatonicChordOffsets = [
        "C":0, "Dm":1, "Em":2, "F":3, "G":4, "Am":5, "Bdim":6
//        ,"Cmaj7": 0, "Dm7":2, "Em7":2, "Fmaj7":3, "G7":-3, "Am7":-2, "Bdim7":-1
    ]
    
    class var sharedInstance:MusicChord {
        return MusicChordInstance
    }
    
    /*
    *   Singleton function to get the guessed chord name, notes, and transposition offset
    */
    func analyzeChordFromNotes(notes: [MusicNote]) -> (chordNameString: String, chordNotes: [Int]!, transposeOffset: Int) {
        var noteArray = [Int]()
        for note in notes {
            noteArray.append(Int(note.midiNoteMess.note))
        }
        let possibleChords = self.generatePossibleChordNames(notes)
        return self.guessChord(possibleChords)
    }
    
    /*
    *   Generates a list of all of the possible chords based on notes in the melody.
    *   From this, maybe it can learn how to judge harmony based on melody.
    *   If that is too hard, we can just come up with an algorithm to pick the chord
    *   based on weigths (likely duration of notes)
    */
    func generatePossibleChordNames(notes: [MusicNote]) -> [Chord] {
        var noteArray = [Int]()
        var totalDurationOfAllNotes: Float = 0.0
        for note in notes {
            noteArray.append(Int(note.midiNoteMess.note))
        }
        if chords[noteArray] != nil {
            return [Chord(name: chords[noteArray]!, weight: 1.0)]
        }
        
        var returnChords = [Chord]()
        //  Check to see if any chords are in the noteNumbers array, if so add them to an array for choosing
        //        let noteNumberSet:Set = Set(notes)
        var foundFullChord = false

        for i in 0..<12 {
            let majorChord:Set = [i, (i+4)%12, (i+7)%12]
            let minorChord:Set = [i, (i+3)%12, (i+7)%12]
            let dimChord:Set = [i, (i+3)%12, (i+6)%12]
            
            if let newChord = getChordSubset(notes, chordSet: majorChord, fullChordNotes: [i, (i+4)%12, (i+7)%12].sort() ) {
                returnChords = self.addPossibleChord(newChord.name, weight: newChord.weight, possibleChords: returnChords)
                foundFullChord = true
            }
            
            if let newChord = getChordSubset(notes, chordSet: minorChord, fullChordNotes: [i, (i+3)%12, (i+7)%12].sort()) {
                returnChords = self.addPossibleChord(newChord.name, weight: newChord.weight, possibleChords: returnChords)
                foundFullChord = true
            }
            
            if let newChord = getChordSubset(notes, chordSet: dimChord, fullChordNotes: [i, (i+3)%12, (i+6)%12].sort()) {
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
                
                if let newChord = getChordSubset(notes, chordSet: majorChordFourth, fullChordNotes: [i, (i+5)%12, (i+9)%12].sort()) {
                    returnChords = self.addPossibleChord(newChord.name, weight: newChord.weight / 2, possibleChords: returnChords)
                    //  Because this is a fourth, it should still search for other possiblities.
                }
                
                if let newChord = getChordSubset(notes, chordSet: majorChordThird, fullChordNotes: [i, (i+4)%12, (i+7)%12].sort()) {
                    returnChords = self.addPossibleChord(newChord.name, weight: newChord.weight / 4, possibleChords: returnChords)
                }
                
                if let newChord = getChordSubset(notes, chordSet: minorChordThird, fullChordNotes: [i, (i+3)%12, (i+7)%12].sort()) {
                    returnChords = self.addPossibleChord(newChord.name, weight: newChord.weight / 4, possibleChords: returnChords)
                }
            }
        }
        
        if returnChords.count == 0 {
            returnChords = self.singleNoteChordPossibles[Int(notes[0].midiNoteMess.note)]!
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
    private func getChordSubset(noteArray: [MusicNote], chordSet: Set<Int>, fullChordNotes: [Int]) -> Chord? {
        var weight: Float = 0.0
        var chordName: String = ""
        var noteNumberSet: Set = Set<Int>()
        for note in noteArray {
            noteNumberSet.insert(Int(note.midiNoteMess.note))
        }
        if chordSet.isSubsetOf(noteNumberSet) {
            var chordArray = Array<Int>(chordSet)
            chordArray = chordArray.sort()
            if self.chords[fullChordNotes] != nil {
                chordName = self.chords[fullChordNotes]!
            }
            for note in noteArray {
                for chord in chordArray {
                    if chord == Int(note.midiNoteMess.note) {
                        weight = weight + Float(note.midiNoteMess.duration)
                    }
                }
            }
            return Chord(name: chordName, weight: weight)
        }
        return nil
    }
    
    /*
    *   Iterates through the list of possible chords and chooses the most frequently occurring chord.
    */
    private func guessChord(possibleChords:[Chord]) -> (chordNameString: String, chordNotes: [Int]!, transposeOffset: Int) {
        
        if possibleChords.count > 1 {
            
            //  Generate the frequency of each possble chord
            var possibleChordWeights = [String: Float]()
            for possibleChord in possibleChords {
                if possibleChordWeights[possibleChord.name] != nil {
                    possibleChordWeights[possibleChord.name] = possibleChordWeights[possibleChord.name]! + possibleChord.weight
                } else {
                    possibleChordWeights[possibleChord.name] = possibleChord.weight
                }
            }
            
            //  Get the most weighted chord
            var highestWeight = possibleChordWeights.values.first
            var highestWeightName = possibleChordWeights.keys.first
            for weight in possibleChordWeights {
                if weight.1 > highestWeight {
                    highestWeight = weight.1
                    highestWeightName = weight.0
                }
            }
            return (highestWeightName!, self.chordNotes[highestWeightName!], self.getTransposeOffset(highestWeightName!))
        } else if possibleChords.count == 1 {
            return (possibleChords[0].name, self.chordNotes[possibleChords[0].name], self.getTransposeOffset(possibleChords[0].name))
        }
        return ("NC", [], 0)
    }
    
    private func getTransposeOffset(chordNameString: String) -> Int {
        if let offset = self.chordOffsets[chordNameString] {
            return offset
        }
        return 0
    }
    
    func getTransposedChord(chordName: String, chordNotes: [Int], transposeOffset: Int) -> (chordNameString: String, chordNotes: [Int]!) {
        if transposeOffset != 0 {
            var newChordNotes = [Int]()
            for chordNote in chordNotes {
                let newChordNote = (chordNote + 12 - transposeOffset) % 12
                newChordNotes.append(newChordNote)
            }
            newChordNotes = newChordNotes.sort()
            var newChordName = ""
            
            if self.chords[newChordNotes] != nil {
                newChordName = self.chords[newChordNotes]!
            }
            return (newChordName, newChordNotes)
            
        } else {
            return (chordName, chordNotes)
        }
    }
    
    func getDiatonicTransposeOffset(chord1 chord1: String, chord2: String) -> (isSwitchingQuality: Bool, isDiatonic: Bool, steps: Int) {
        if let c1Offset = self.diatonicChordOffsets[chord1]{
            if let c2Offset = self.diatonicChordOffsets[chord2] {
                    return (false, true, abs(c1Offset - c2Offset))
            } else {
                if chord1.containsString("m") && !chord2.containsString("m") {
                    return (true, false, abs(self.chordOffsets[chord1]! - self.chordOffsets[chord2]!))
                } else if !chord1.containsString("m") && chord2.containsString("m") {
                    return (true, false, abs(self.chordOffsets[chord1]! - self.chordOffsets[chord2]!))
                } else {
                    return (false, false, abs(self.chordOffsets[chord1]! - self.chordOffsets[chord2]!))
                }
            }
        } else {
            if chord1.containsString("m") && !chord2.containsString("m") {
                return (true, false, abs(self.chordOffsets[chord1]! - self.chordOffsets[chord2]!))
            } else if !chord1.containsString("m") && chord2.containsString("m") {
                return (true, false, abs(self.chordOffsets[chord1]! - self.chordOffsets[chord2]!))
            } else {
                return (false, false, abs(self.chordOffsets[chord1]! - self.chordOffsets[chord2]!))
            }
        }
    }
    
}
