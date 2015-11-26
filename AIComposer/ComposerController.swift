//
//  ComposerController.swift
//  AIComposer
//
//  Created by Jess Hendricks on 11/13/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import Cocoa
import AudioToolbox



/// The `Singleton` instance
private let ComposerControllerInstance = ComposerController()


class ComposerController: NSObject {
    
    let midiManager = MIDIManager.sharedInstance
    
    let presetList: [UInt8] = [0, 1, 4, 5, 6, 11, 24, 45, 46,
        80, 81, 98, 99]
    
    //  Returns the singleton instance
    class var sharedInstance:ComposerController {
        return ComposerControllerInstance
    }
    
    //  Creates a MIDI file that tests all permutations with a single MusicSnippet.
    //  This will ADD DATA to the music data set.
    func createPermutationTestSequence(var musicDataSet: MusicDataSet) {
        var musicSnippet: MusicSnippet!
        let mainSnippetIndex = Int.random(0..<musicDataSet.musicSnippets.count)
        if musicDataSet.musicSnippets[mainSnippetIndex].getHighestWeightChord().containsString("m") {
            musicSnippet = MusicSnippet(notes: musicDataSet.musicSnippets[mainSnippetIndex].musicNoteEvents)
            musicSnippet.transposeToChord("Cm", keyOffset: 0)
        } else {
            musicSnippet = MusicSnippet(notes: musicDataSet.musicSnippets[mainSnippetIndex].musicNoteEvents)
            musicSnippet.transposeToChord("C", keyOffset: 0)
        }
        if musicDataSet.musicSnippets.count > 1 {
            for _ in 0..<3 {
                musicSnippet = self.createNewMotive(musicDataSet.musicSnippets, snippet: musicDataSet.musicSnippets[mainSnippetIndex], weight: musicDataSet.compositionWeights.mainThemeWeight, numberOfBeats: 4.0)
            }
        } else {
            musicSnippet = MusicSnippet(notes: musicDataSet.musicSnippets[0].musicNoteEvents)
        }
        
        
        if musicSnippet.count != 0 {
            
            //  1   ... Create 4 parts and measures
//            let randomKeyOffset = Int.random(0..<12) - 6
            let randomKeyOffset = 0 //  I don't think it should change keys yet
            let newTempo: Float64 = Float64(Int.random(40...140))
            let chords = musicDataSet.chordProgressions[Int.random(0..<musicDataSet.chordProgressions.count)].chords
            var parts = [MusicPart]()
            var octaveOffset = 12
            var numberOfMeasures = 0
            for partNum in 0..<4 {
                
                let newPart = self.composeNewPartWithChannel(partNum,
                    keyOffset: randomKeyOffset,
                    musicDataSet: musicDataSet,
                    timeSig: TimeSignature(numberOfBeats:4, beatLength: 1.0),
                    octaveOffset: octaveOffset,
                    numberOfMeasures: numberOfMeasures,
                    musicSnippet: musicSnippet,
                    chords: chords,
                    tempo: newTempo,
                    compWeights: musicDataSet.compositionWeights)
                
                if newPart.numberOfMeasures > numberOfMeasures {
                    numberOfMeasures = newPart.numberOfMeasures
                }
                
                octaveOffset = newPart.octaveOffset
                parts.append(newPart.part)
            }
            
            //  2   ... Create Composition from Parts
            
            let newComposition = MusicComposition(name: "Test Piece", musicParts: parts, numberOfMeasures: numberOfMeasures)
            
            //  3   ... Add composition to MusicDataSet
            
            musicDataSet.compositions.append(newComposition)
        }
    }
    
    func composeNewPartWithChannel(partNum: Int, var keyOffset: Int, musicDataSet: MusicDataSet, timeSig: TimeSignature, var octaveOffset: Int, var numberOfMeasures: Int, musicSnippet: MusicSnippet, chords: [String], tempo: Float64, compWeights: CompositionWeights) -> (part: MusicPart, numberOfMeasures: Int, octaveOffset: Int)
    {
        let randomPreset:UInt8 = presetList[Int.random(0..<presetList.count)]
        var measures = [MusicMeasure]()
        var timeOffset: MusicTimeStamp = 0.0
        keyOffset = keyOffset + octaveOffset
        octaveOffset = octaveOffset - 12
        numberOfMeasures = 0
        let newSnippet = self.createNewMotive(musicDataSet.musicSnippets, snippet: musicSnippet, weight: 0.5, numberOfBeats: Double(timeSig.numberOfBeats))
        for chord in chords {
            numberOfMeasures++
            if Double.random() > compWeights.restProbability {
                measures.append(self.generateMeasureForChord(
                    channel: partNum,
                    chord: chord,
                    musicSnippets: musicDataSet.musicSnippets,
                    musicSnippet: newSnippet,
                    keyOffset: keyOffset,
                    timeSig: TimeSignature(numberOfBeats: timeSig.numberOfBeats, beatLength: 1.0),
                    startTimeStamp: timeOffset,
                    tempo: tempo,
                    compWeights: compWeights))
            }
            timeOffset = timeOffset + MusicTimeStamp(timeSig.numberOfBeats)
        }
        measures.append(self.generateEndingMeasureForChord(chords[0], channel: partNum, keyOffset: keyOffset - octaveOffset, timeSig: timeSig, startTimeStamp: timeOffset, previousNote: measures[measures.count - 1].notes.last!.midiNoteMess, tempo: tempo))
        numberOfMeasures++
        return (MusicPart(measures: measures, preset: randomPreset), numberOfMeasures, octaveOffset)
    }
    
    private func generateMeasureForChord(
        channel channel: Int,
        chord: String,
        musicSnippets: [MusicSnippet],
        musicSnippet: MusicSnippet,
        keyOffset: Int,
        timeSig: TimeSignature,
        startTimeStamp: MusicTimeStamp,
        tempo: Float64,
        compWeights: CompositionWeights
        ) -> MusicMeasure
    {
        let newMergeSnippet = self.createNewMotive(musicSnippets, snippet: musicSnippet, weight: 0.6, numberOfBeats: Double(timeSig.numberOfBeats))
        let snippet1 = self.getSnippetWithRandomPermutation(newMergeSnippet, permWeights: compWeights.permutationWeights)
        snippet1.transposeToChord(chord, keyOffset: keyOffset)
        for note in snippet1.musicNoteEvents {
            note.timeStamp = note.timeStamp + startTimeStamp
            note.midiNoteMess.channel = UInt8(channel)
            
            //  Check to see if the note is in an extreme range
            if note.midiNoteMess.note < UInt8(18) {
                note.midiNoteMess.note = note.midiNoteMess.note + 12
            }
            
            if note.midiNoteMess.note > UInt8(100) {
                note.midiNoteMess.note = note.midiNoteMess.note - 12
            }
        }
        return MusicMeasure(tempo: tempo, timeSignature: timeSig, firstBeatTimeStamp: startTimeStamp, notes: snippet1.musicNoteEvents, chord: chord)
    }
    
    private func generateEndingMeasureForChord(chord: String, channel: Int, keyOffset: Int, timeSig: TimeSignature, startTimeStamp: MusicTimeStamp, previousNote: MIDINoteMessage, tempo: Float64) -> MusicMeasure
    {
        let chordController = MusicChord.sharedInstance
        let chordNotes = chordController.chordNotes[chord]
        let noteNumber = chordNotes![Int.random(0..<chordNotes!.count)]
        let octave = Int(previousNote.note) / 12
        let newNoteNum:Int =  noteNumber + (octave * 12) + keyOffset
        let midiNote = MIDINoteMessage(channel: UInt8(channel), note: UInt8(newNoteNum), velocity: previousNote.velocity, releaseVelocity: 0, duration: Float32(timeSig.numberOfBeats))
        let newNote = MusicNote(noteMessage: midiNote, timeStamp: startTimeStamp)
        return MusicMeasure(tempo: tempo, timeSignature: timeSig, firstBeatTimeStamp: startTimeStamp, notes: [newNote], chord: chord)
    }
    
    private func createNewMotive(musicSnippets: [MusicSnippet], snippet: MusicSnippet, weight: Double, numberOfBeats: Double) -> MusicSnippet {
        var musicSnippet = MusicSnippet()
        for i in 0..<musicSnippets.count {
            if i != musicSnippets.indexOf(snippet) {
                if musicSnippets[i].getHighestWeightChord() == snippet.getHighestWeightChord() {
                    musicSnippet = snippet.mergeNotePassagesRhythmically(firstWeight: weight, chanceOfRest: 0.1, secondSnippet: musicSnippets[i], numberOfBeats: numberOfBeats)
                    break
                }
            }
        }
        if musicSnippet.count == 0 {
            return snippet
        } else {
            return musicSnippet
        }
    }
    
    private func getSnippetWithRandomPermutation(musicSnippet: MusicSnippet, permWeights: [Double]) -> MusicSnippet {
        let newSnippet = MusicSnippet(notes: musicSnippet.musicNoteEvents)
        var permuteNum = 0
        let rand = Double.random()
        while (rand > permWeights[permuteNum]) {
            permuteNum++
        }
        
        switch permuteNum {
        case 0:
            newSnippet.applyDiatonicInversion(pivotNoteNumber: musicSnippet.musicNoteEvents[0].midiNoteMess.note)
        case 1:
            newSnippet.applyMelodicRetrograde()
        case 2:
            newSnippet.applyRetrograde()
        case 3:
            newSnippet.applyRhythmicRetrograde()
        default:
            break
        }
        
        if Double.random() < 0.25 {
            let start = Int.random(0..<newSnippet.count)
            let end = Int.random(start..<newSnippet.count)
            newSnippet.applyDynamicLine(startIndex: start, endIndex: end, startVelocity: UInt8(Int.random(25..<127)), endVelocity: UInt8(Int.random(25..<127)))
        } else if Double.random() < 0.5 {
            let start = Int.random(0..<newSnippet.count)
            let end = Int.random(start..<newSnippet.count)
            let randomArticulationNum = Int.random(0...10)
            var artic: Articulation!
            switch randomArticulationNum {
            case 0, 1, 2:
                artic = Articulation.Accent
            case 3, 4:
                artic = Articulation.Marcato
            case 5, 6:
                artic = Articulation.Staccatissimo
            case 7, 8, 9:
                artic = Articulation.Staccato
            default:
                artic = Articulation.Tenuto
            }
            newSnippet.applyArticulation(startIndex: start, endIndex: end, articulation: artic)
        }
        
        return newSnippet
    }
    
    
}
