//
//  ComposerController.swift
//  AIComposer
//
//  Created by Jess Hendricks on 11/13/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import Cocoa
import CoreMIDI
import AudioToolbox

/// The `Singleton` instance
private let ComposerControllerInstance = ComposerController()

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

class ComposerController: NSObject {
    
    
    
    //  Returns the singleton instance
    class var sharedInstance:ComposerController {
        return ComposerControllerInstance
    }
    

    
    
    /**
    Invert a set of notes chromatically around a pivot note
    
    - Parameters:
     - notes: the   `MusicNote`s to be inverted
     - pivotNote:   Which pitch to perform the inversion about
    - Returns: `[MusicNote]`
    */
    func getChromaticInversion(notes: [MusicNote], pivotNoteNumber: UInt8) -> [MusicNote] {
        var returnNotes = [MusicNote]()
        //  TODO: Implement Chromatic Inversion
        return notes
    }
    
    /**
     Invert a set of notes diatonically around a pivot note
     
     - Parameters:
        - notes:        the `MusicNote`s to be inverted
        - pivotNote:    Which pitch to perform the inversion about
     - Returns: `[MusicNote]`
     */
    func getDiatonicInversion(notes: [MusicNote], pivotNoteNumber: UInt8) -> [MusicNote] {
        var returnNotes = [MusicNote]()
        //  TODO: Implement Diatonic Inversion
        return notes
    }
    
    /**
     Returns the complete retrograde of a set of notes (pitch and rhythm)
     
     - Parameters:
        - notes:        the `MusicNote`s to be retrograded
        - pivotNumber:  Which pitch to perform the inversion about
     - Returns: `[MusicNote]`
     */
    func getRetrograde(notes: [MusicNote]) -> [MusicNote] {
        var returnNotes = [MusicNote]()
        //  TODO: Implement Retrograde
        return notes
    }
    
    /**
     Returns the melodic retrograde of a set of notes
     
     - Parameters:
        - notes:    the `MusicNote`s to be retrograded
     - Returns: `[MusicNote]`
     */
    func getMelodicRetrograde(notes: [MusicNote]) -> [MusicNote] {
        var returnNotes = [MusicNote]()
        //  TODO: Implement retrograde notes
        return notes
    }
    
    /**
     Returns the rhythmic retrograde of a set of notes
     
     - Parameters:
        - notes:    the `MusicNote`s to be retrograded
     - Returns: `[MusicNote]`
     */
    func getRhythmicRetrograde(notes: [MusicNote]) -> [MusicNote] {
        var returnNotes = [MusicNote]()
        //  TODO: Implement retrograde rhythms
        return notes
    }

    
    /**
     Multiplies all duarations by a multiplier
     
     - Parameters:
        - notes:    the `MusicNote`s to be augmented
        - multiplier:   How much to multiply durations by
     - Returns: `[MusicNote]`
     */
    func augmentPassageRhythm(notes: [MusicNote], multiplier: Int) -> [MusicNote] {
        var returnNotes = [MusicNote]()
        //  TODO: Implement Augment Passage
        return returnNotes
    }
    
    /**
     Merges two sets of notes based on weights for each passage
     
     - Parameters:
        - firstPassage:     the first set of notes to be merged
        - firstWeight:      weight of first passage (the second passage weight is (1 - firstWeight)
        - secondPassage:    the first set of notes to be merged
     - Returns: A new set of notes based on the two passages
     */
    func mergeNotePassages(firstPassage: [MusicNote], firstWeight: Double, secondPassage: [MusicNote]) -> [MusicNote] {
        var returnNotes = [MusicNote]()
        for note in firstPassage {
            returnNotes.append(note)
        }

        return returnNotes
    }
    
    /**
     Creates a crescendo or decrescendo effect over a range of notes
     
     - Parameters:
        - notes:            the `MusicNote`s to be retrograded
        - startIndex:       Index of the first note
        - endIndex:         Index of the last note
        - startVelocity:    velocity of the first note
        - endVelocity:      velocity of the last note
     - Returns: `[MusicNote]`
     */
    func createDynamicLine(notes: [MusicNote], startIndex: Int, endIndex: Int, startVelocity: UInt8, endVelocity: UInt8) -> [MusicNote] {
        var returnNotes = [MusicNote]()
        var currentVel = startVelocity
        let numerator = abs(Int(endVelocity) - Int(startVelocity))
        let velocityIncrement = UInt8(numerator) / UInt8(endIndex - startIndex)
        if endIndex < notes.count {
            for i in startIndex...endIndex {
                returnNotes.append(MusicNote(
                    noteMessage: MIDINoteMessage(
                        channel: notes[i].midiNoteMess.channel,
                        note: notes[i].midiNoteMess.note,
                        velocity: currentVel,
                        releaseVelocity: notes[i].midiNoteMess.releaseVelocity,
                        duration: notes[i].midiNoteMess.duration),
                    barBeatTime: notes[i].barBeatTime,
                    timeStamp: notes[i].timeStamp))
                if startVelocity < endVelocity {
                    currentVel = currentVel + velocityIncrement
                } else {
                    currentVel = currentVel - velocityIncrement
                }
            }
        }
        return returnNotes
    }
    
    /**
     Applies an articulation over a range of notes
     
     - Parameters:
        - notes:            the `MusicNote`s to be retrograded
        - startIndex:       Index of the first note
        - endIndex:         Index of the last note
        - articulation:    `Articulation` to apply.
     - Returns: `[MusicNote]`
     */
    func applyArticulation(var notes: [MusicNote], startIndex: Int, endIndex: Int, articulation: Articulation) -> [MusicNote] {
        var returnNotes = [MusicNote]()
        if startIndex < endIndex && endIndex < notes.count {
            for i in 0..<notes.count {
                let newNote = notes[i].getNoteCopy()
                if i >= startIndex && i <= endIndex {
                    newNote.applyArticulation(articulation)
                }
                returnNotes.append(newNote)
            }
        }
        return returnNotes
    }
    
    /**
     Attempts to humanize the feel of a set of notes based on beat and bar
     
     - Parameters:
     - notes:    the `MusicNote`s to be retrograded
     - Returns: `[MusicNote]`
     */
    func humanizeNotes(notes: [MusicNote]) -> [MusicNote] {
        var returnNotes = [MusicNote]()
        //  TODO: Implement HUMANIZE
        return returnNotes
    }
    
    
}
