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
import CoreMIDI
import AudioToolbox

private let MusicChordInstance = MusicChord()

class MusicChord: NSObject {
    
//    var chordNameString: String!
//    var chordNotes: [Int]!
//    var transposeOffset = 0
    
    
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
        let possibleChords = self.generatePossibleChordNames(noteArray)
        return self.guessChord(possibleChords)
    }
    
    /*
    *   Generates a list of all of the possible chords based on notes in the melody.
    *   From this, maybe it can learn how to judge harmony based on melody.
    *   If that is too hard, we can just come up with an algorithm to pick the chord
    *   based on weigths (likely duration of notes)
    */
    private func generatePossibleChordNames(noteNumbers: [Int]) -> [String] {
        let chords = [
            [0,4,7]:"C", [1,5,8]:"Db", [2,6,9]:"D", [3,7,10]:"Eb", [4,8,11]:"E", [0,5,9]:"F",
            [1,6,10]:"F#", [2,7,11]:"G", [0,3,8]:"Ab", [1,4,9]:"A", [2,5,10]:"Bb", [3,6,11]:"B",
            
            [0,3,7]:"Cm", [1,4,8]:"Dbm", [2,5,9]:"Dm", [3,6,10]:"Ebm", [4,7,11]:"Em", [0,5,8]:"Fm",
            [1,6,9]:"F#m", [2,7,10]:"Gm", [3,8,11]:"Abm", [0,4,9]:"Am", [1,5,10]:"Bbm", [2,6,11]:"Bm",
            
            [0,3,6]:"Cdim", [1,4,7]:"Dbdim", [2,5,8]:"Ddim", [3,6,9]:"Ebdim", [4,7,10]:"Edim", [5,8,11]:"Fdim",
            [0,6,9]:"F#dim", [1,7,10]:"Gdim", [2,8,11]:"Abdim", [0,3,9]:"Adim", [1,4,10]:"Bbdim", [2,5,11]:"Bdim",
            
            [0,4,8]:"C+", [1,5,9]:"Db+", [2,6,10]:"D+", [3,7,11]:"Eb+",
            
            [0,4,7,10]:"C7", [1,5,8,11]:"Db7", [0,2,6,9]:"D7", [1,3,7,10]:"Eb7", [2,4,8,11]:"E7", [0,3,5,9]:"F7",
            [1,4,6,10]:"F#7", [2,5,7,11]:"G7", [0,3,6,8]:"Ab7", [1,4,7,9]:"A7", [2,5,8,10]:"Bb7", [3,6,9,11]:"B7",
            
            [0,4,7,11]:"Cmaj7", [0,1,5,8]:"Dbmaj7", [1,2,6,9]:"Dmaj7", [2,3,7,10]:"Ebmaj7", [3,4,8,11]:"Emaj7", [0,4,5,9]:"Fmaj7",
            [1,5,6,10]:"F#maj7", [2,6,7,11]:"Gmaj7", [0,3,7,8]:"Abmaj7", [1,4,8,9]:"Amaj7", [2,5,9,10]:"Bbmaj7", [3,6,10,11]:"Bmaj7",
            
            [0,3,7,11]:"Cm7", [1,4,8,11]:"Dbm7", [0,2,5,9]:"Dm7", [1,3,6,10]:"Ebm7", [2,4,7,11]:"Em7", [0,3,5,8]:"Fm7",
            [1,4,6,9]:"F#m7", [2,5,7,10]:"Gm7", [3,6,8,11]:"Abm7", [0,4,7,9]:"Am7", [1,5,8,10]:"Bbm7", [2,6,9,11]:"Bm7"
        ]
        
        if chords[noteNumbers] != nil {
            return [chords[noteNumbers]!]
        }
        var returnChordNames = [String]()
        //  Check to see if any chords are in the noteNumbers array, if so add them to an array for choosing
        let noteNumberSet:Set = Set(noteNumbers)
        var foundFullChord = false
        for i in 0..<12 {
            let majorChord:Set = [i, (i+4)%12, (i+7)%12]
            if let newChordName = getChordSubset(noteNumberSet, chordSet: majorChord, chords: chords, fullChordNotes: [i, (i+4)%12, (i+7)%12].sort()) {
                returnChordNames.append(newChordName)
                foundFullChord = true
            }
            
            let minorChord:Set = [i, (i+3)%12, (i+7)%12]
            if let newChordName = getChordSubset(noteNumberSet, chordSet: minorChord, chords: chords, fullChordNotes: [i, (i+3)%12, (i+7)%12].sort()) {
                returnChordNames.append(newChordName)
                foundFullChord = true
            }
            
            let dimChord:Set = [i, (i+3)%12, (i+6)%12]
            if let newChordName = getChordSubset(noteNumberSet, chordSet: dimChord, chords: chords, fullChordNotes: [i, (i+3)%12, (i+6)%12].sort()) {
                returnChordNames.append(newChordName)
                foundFullChord = true
            }
            
            let augChord:Set = [i, (i+4)%12, (i+8)%12]
            if let newChordName = getChordSubset(noteNumberSet, chordSet: augChord, chords: chords, fullChordNotes: [i, (i+4)%12, (i+8)%12].sort()) {
                returnChordNames.append(newChordName)
                foundFullChord = true
            }
            
            let dom7Chord:Set = [i, (i+4)%12, (i+7)%12, (i+10)%12]
            if let newChordName = getChordSubset(noteNumberSet, chordSet: dom7Chord, chords: chords, fullChordNotes: [i, (i+4)%12, (i+7)%12].sort()) {
                returnChordNames.append(newChordName)
                foundFullChord = true
            }
            
            let major7Chord:Set = [i, (i+4)%12, (i+7)%12, (i+11)%12]
            if let newChordName = getChordSubset(noteNumberSet, chordSet: major7Chord, chords: chords, fullChordNotes: [i, (i+4)%12, (i+7)%12].sort()) {
                returnChordNames.append(newChordName)
                foundFullChord = true
            }
            
            let minor7Chord:Set = [i, (i+3)%12, (i+7)%12, (i+10)%12]
            if let newChordName = getChordSubset(noteNumberSet, chordSet: minor7Chord, chords: chords, fullChordNotes: [i, (i+3)%12, (i+7)%12].sort()) {
                returnChordNames.append(newChordName)
                foundFullChord = true
            }
            
            //  TODO:   Fifth only chords not working, need dim, dim7, and other chord types.
        }
        
        
        if !foundFullChord {
            for i in 0..<12 {
                //  If no full chord has been found, it will search for partial chords
                let majorChordFourth:Set = [i, (i+5)%12]
                if let newChordName = getChordSubset(noteNumberSet, chordSet: majorChordFourth, chords: chords, fullChordNotes: [i, (i+5)%12, (i+9)%12].sort()) {
                    returnChordNames.append(newChordName)
                }
                let majorChordFifth:Set = [i, (i+7)%12]
                if let newChordName = getChordSubset(noteNumberSet, chordSet: majorChordFifth, chords: chords, fullChordNotes: [i, (i+4)%12, (i+7)%12].sort()) {
                    returnChordNames.append(newChordName)
                }
                
                let majorChordThird:Set = [i, (i+4)%12]
                if let newChordName = getChordSubset(noteNumberSet, chordSet: majorChordThird, chords: chords, fullChordNotes: [i, (i+4)%12, (i+7)%12].sort()) {
                    returnChordNames.append(newChordName)
                }
                
                let minorChordThird:Set = [i, (i+3)%12]
                if let newChordName = getChordSubset(noteNumberSet, chordSet: minorChordThird, chords: chords, fullChordNotes: [i, (i+3)%12, (i+7)%12].sort()) {
                    returnChordNames.append(newChordName)
                }
            }
        }
        return returnChordNames
    }
    
    private func getChordSubset(noteNumberSet: Set<Int>, chordSet: Set<Int>, chords: [NSArray:String], fullChordNotes: [Int]) -> String? {
        if chordSet.isSubsetOf(noteNumberSet) {
            var chordArray = Array<Int>(chordSet)
            chordArray = chordArray.sort()
            if chords[fullChordNotes] != nil {
                return chords[fullChordNotes]!
            }
        }
        return nil
    }
    
    private func getWeightOfChord(notes: [MusicNote], fullChordNotes: [Int]) -> Float32 {
        return 0.0
    }
    
    /*
    *   Iterates through the list of possible chords and chooses the most frequently occurring chord.
    */
    private func guessChord(possibleChords:[String]) -> (chordNameString: String, chordNotes: [Int]!, transposeOffset: Int) {
        let chordNotes = [
            "C":[0,4,7], "Db":[1,5,8], "D":[2,6,9], "Eb":[3,7,10], "E":[4,8,11], "F":[0,5,9],
            "F#":[1,6,10], "G":[2,7,11], "Ab":[0,3,8], "A":[1,4,9], "Bb":[2,5,10], "B":[3,6,11],
            
            "Cm":[0,3,7], "Dbm":[1,4,8], "Dm":[2,5,9], "Ebm":[3,6,10], "Em":[4,7,11], "Fm":[0,5,8],
            "F#m":[1,6,9], "Gm":[2,7,10], "Abm":[3,8,11], "Am":[0,4,9], "Bbm":[1,5,10], "Bm":[2,6,11],
            
            "Cdim": [0,3,6], "Dbdim":[1,4,7], "Ddim":[2,5,8], "Ebdim":[3,6,9], "Edim":[4,7,10], "Fdim":[5,8,11],
            "F#dim":[0,6,9], "Gdim":[1,7,10], "Abdim":[2,8,11], "Adim":[0,3,9], "Bbdim":[1,4,10], "Bdim":[2,5,11],
            
            "C+":[0,4,8], "Db+":[1,5,9], "D+":[2,6,10], "Eb+":[3,7,11],
            
            "C7":[0,4,7,10], "Db7":[1,5,8,11], "D7":[0,2,6,9], "Eb7":[1,3,7,10], "E7":[2,4,8,11], "F7":[0,3,5,9],
            "F#7":[1,4,6,10], "G7":[2,5,7,11], "Ab7":[0,3,6,8], "A7":[1,4,7,9], "Bb7":[2,5,8,10], "B7":[3,6,9,11],
            
            "Cmaj7":[0,4,7,11], "Dbmaj7":[0,1,5,8], "Dmaj7":[1,2,6,9], "Ebmaj7":[2,3,7,10], "Emaj7":[3,4,8,11], "Fmaj7":[0,4,5,9],
            "F#maj7":[1,5,6,10], "Gmaj7":[2,6,7,11], "Abmaj7":[0,3,7,8], "Amaj7":[1,4,8,9], "Bbmaj7":[2,5,9,10], "Bmaj7":[3,6,10,11],
            
            "Cm7":[0,3,7,10], "Dbm7":[1,4,8,11], "Dm7":[0,2,5,9], "Ebm7":[1,3,6,10], "Em7":[2,4,7,11], "Fm7":[0,3,5,8],
            "F#m7":[1,4,6,9], "Gm7":[2,5,7,10], "Abm7":[3,6,8,11], "Am7":[0,4,7,9], "Bbm7":[1,5,8,10], "Bm7":[2,6,9,11]
        ]
        
        if possibleChords.count != 0 {
            var possibleChordSet = [String: Int]()
            for possibleChord in possibleChords {
                if possibleChordSet[possibleChord] != nil {
                    possibleChordSet[possibleChord] = possibleChordSet[possibleChord]! + 1
                } else {
                    possibleChordSet[possibleChord] = 1
                }
            }
            
            var mostFrequentChordCount = possibleChordSet.values.first
            var mostFrequentChordKey = possibleChordSet.keys.first
//            print(possibleChordSet)
            for possibleChordCount in possibleChordSet {
                if possibleChordCount.1 > mostFrequentChordCount {
                    mostFrequentChordCount = possibleChordCount.1
                    mostFrequentChordKey = possibleChordCount.0
                }
            }
            return (mostFrequentChordKey!, chordNotes[mostFrequentChordKey!], self.getTransposeOffset(mostFrequentChordKey!))
        }
        return ("NC", [], 0)
    }
    
    private func getTransposeOffset(chordNameString: String) -> Int {
        
        let chordOffsets = [
            "C":0, "Db":1, "D":2, "Eb":3, "E":4, "F":5,
            "F#":6, "G":7, "Ab":8, "A":9, "Bb":10, "B":11,
            
            "Cm":0, "Dbm":1, "Dm":2, "Ebm":3, "Em":4, "Fm":5,
            "F#m":6, "Gm":7, "Abm":8, "Am":9, "Bbm":10, "Bm":11,
            
            "Cdim":0, "Dbdim":1, "Ddim":2, "Ebdim":3, "Edim":4, "Fdim":5,
            "F#dim":6, "Gdim":7, "Abdim":8, "Adim":9, "Bbdim":10, "Bdim":11,
            
            "C+":0, "Db+":1, "D+":2, "Eb+":3,
            
            "C7":0, "Db7":1, "D7":2, "Eb7":3, "E7":4, "F7":5,
            "F#7":6, "G7":7, "Ab7":8, "A7":9, "Bb7":10, "B7":11,
            
            "Cmaj7":0, "Dbmaj7":1, "Dmaj7":2, "Ebmaj7":3, "Emaj7":4, "Fmaj7":5,
            "F#maj7":6, "Gmaj7":7, "Abmaj7":8, "Amaj7":9, "Bbmaj7":10, "Bmaj7":11,
            
            "Cm7":0, "Dbm7":1, "Dm7":2, "Ebm7":3, "Em7":4, "Fm7":5,
            "F#m7":6, "Gm7":7, "Abm7":8, "Am7":9, "Bbm7":10, "Bm7":11
        ]
        if let offset = chordOffsets[chordNameString] {
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
            let chords = [
                [0,4,7]:"C", [1,5,8]:"Db", [2,6,9]:"D", [3,7,10]:"Eb", [4,8,11]:"E", [0,5,9]:"F",
                [1,6,10]:"F#", [2,7,11]:"G", [0,3,8]:"Ab", [1,4,9]:"A", [2,5,10]:"Bb", [3,6,11]:"B",
                
                [0,3,7]:"Cm", [1,4,8]:"Dbm", [2,5,9]:"Dm", [3,6,10]:"Ebm", [4,7,11]:"Em", [0,5,8]:"Fm",
                [1,6,9]:"F#m", [2,7,10]:"Gm", [3,8,11]:"Abm", [0,4,9]:"Am", [1,5,10]:"Bbm", [2,6,11]:"Bm",
                
                [0,4,7,10]:"C7", [1,5,8,11]:"Db7", [0,2,6,9]:"D7", [1,3,7,10]:"Eb7", [2,4,8,11]:"E7", [0,3,5,9]:"F7",
                [1,4,6,10]:"F#7", [2,5,7,11]:"G7", [0,3,6,8]:"Ab7", [1,4,7,9]:"A7", [2,5,8,10]:"Bb7", [3,6,9,11]:"B7",
                
                [0,4,7,11]:"Cmaj7", [0,1,5,8]:"Dbmaj7", [1,2,6,9]:"Dmaj7", [2,3,7,10]:"Ebmaj7", [3,4,8,11]:"Emaj7", [0,4,5,9]:"Fmaj7",
                [1,5,6,10]:"F#maj7", [2,6,7,11]:"Gmaj7", [0,3,7,8]:"Abmaj7", [1,4,8,9]:"Amaj7", [2,5,9,10]:"Bbmaj7", [3,6,10,11]:"Bmaj7",
                
                [0,3,7,11]:"Cm7", [1,4,8,11]:"Dbm7", [0,2,5,9]:"Dm7", [1,3,6,10]:"Ebm7", [2,4,7,11]:"Em7", [0,3,5,8]:"Fm7",
                [1,4,6,9]:"F#m7", [2,5,7,10]:"Gm7", [3,6,8,11]:"Abm7", [0,4,7,9]:"Am7", [1,5,8,10]:"Bbm7", [2,6,9,11]:"Bm7"
            ]
            
            if chords[newChordNotes] != nil {
                newChordName = chords[newChordNotes]!
            }
            return (newChordName, newChordNotes)
            
        } else {
            return (chordName, chordNotes)
        }
    }
    
}
