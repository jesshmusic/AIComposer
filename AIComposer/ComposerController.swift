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
    
    let presetList: [UInt8] = [1, 2, 5, 6, 7, 12, 25, 46, 47,
        81, 82, 99, 100]
    
    
    let permWeights = [20, 40, 50, 60, 100]
    
    //  Returns the singleton instance
    class var sharedInstance:ComposerController {
        return ComposerControllerInstance
    }
    
    //  Creates a MIDI file that tests all permutations with a single MusicSnippet.
    //  This will ADD DATA to the music data set.
    func createPermutationTestSequence(var musicDataSet: MusicDataSet, mainSnippetIndex: Int, mainSnippetWeight: Double, numberOfBeats: Double) {
        var musicSnippet: MusicSnippet!
        if musicDataSet.musicSnippets[mainSnippetIndex].getHighestWeightChord().containsString("m") {
            musicSnippet = MusicSnippet(notes: musicDataSet.musicSnippets[mainSnippetIndex].musicNoteEvents)
            musicSnippet.transposeToChord("Cm", keyOffset: 0)
        } else {
            musicSnippet = MusicSnippet(notes: musicDataSet.musicSnippets[mainSnippetIndex].musicNoteEvents)
            musicSnippet.transposeToChord("C", keyOffset: 0)
        }
        if musicDataSet.musicSnippets.count > 1 {
            for _ in 0..<3 {
                musicSnippet = self.createNewMotive(musicDataSet.musicSnippets, snippet: musicDataSet.musicSnippets[mainSnippetIndex], weight: mainSnippetWeight, numberOfBeats: numberOfBeats)
            }
        } else {
            musicSnippet = MusicSnippet(notes: musicDataSet.musicSnippets[0].musicNoteEvents)
        }
        if musicSnippet.count != 0 {
            
            //  1   ... Create 4 parts and measures
            var randomKeyOffset = Int.random(0..<12) - 6
            let randomPreset:UInt8 = presetList[Int.random(0..<presetList.count)]
            let newTempo: Float64 = Float64(Int.random(40...140))
            var chords = [String]()
            if musicDataSet.chordProgressions.isEmpty {
                let chordsSet = [["C", "Em", "F", "Dm", "G", "C"], ["C", "Eb", "F", "Gm", "G", "Am"], ["F", "C", "Dm", "Am", "G", "C"], ["C", "G", "Am", "Em", "F", "C", "Dm", "G", "C"]]
                chords = chordsSet[Int.random(0...3)]
            } else {
                chords = musicDataSet.chordProgressions[Int.random(0..<musicDataSet.chordProgressions.count)].chords
            }
            var parts = [MusicPart]()
            var octaveOffset = 12
            for partNum in 0..<4 {
                var measures = [MusicMeasure]()
                var timeOffset: MusicTimeStamp = 0.0
                randomKeyOffset = randomKeyOffset + octaveOffset
                octaveOffset = octaveOffset - 12
                for chord in chords {
                    if Int.random(0..<10) > 1 {
                        measures.append(self.generateMeasureForChord(
                            channel: partNum,
                            chord: chord,
                            musicSnippets: musicDataSet.musicSnippets,
                            musicSnippet: musicSnippet,
                            keyOffset: randomKeyOffset,
                            timeSig: TimeSignature(numberOfBeats: Int(numberOfBeats), beatLength: 1.0),
                            startTimeStamp: timeOffset,
                            tempo: newTempo))
                    }
                    timeOffset = timeOffset + numberOfBeats
                }
                
                parts.append(MusicPart(measures: measures, preset: randomPreset))
            }
            
            //  2   ... Create Composition from Parts
            
            let newComposition = MusicComposition(name: "Test Piece", musicParts: parts)
            
            //  3   ... Add composition to MusicDataSet
            
            musicDataSet.compositions.append(newComposition)
        }
    }
    
    private func generateMeasureForChord(
        channel channel: Int,
        chord: String,
        musicSnippets: [MusicSnippet],
        musicSnippet: MusicSnippet,
        keyOffset: Int,
        timeSig: TimeSignature,
        startTimeStamp: MusicTimeStamp,
        tempo: Float64
        ) -> MusicMeasure
    {
        let newMergeSnippet = self.createNewMotive(musicSnippets, snippet: musicSnippet, weight: 0.6, numberOfBeats: Double(timeSig.numberOfBeats))
        let snippet1 = self.getSnippetWithRandomPermutation(newMergeSnippet)
        snippet1.transposeToChord(chord, keyOffset: keyOffset)
        for note in snippet1.musicNoteEvents {
            note.timeStamp = note.timeStamp + startTimeStamp
            note.midiNoteMess.channel = UInt8(channel)
        }
        return MusicMeasure(tempo: tempo, timeSignature: timeSig, firstBeatTimeStamp: startTimeStamp, notes: snippet1.musicNoteEvents, chord: chord)
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
    
    private func getSnippetWithRandomPermutation(musicSnippet: MusicSnippet) -> MusicSnippet {
        let newSnippet = MusicSnippet(notes: musicSnippet.musicNoteEvents)
        var permuteNum = 0
        let rand = Int.random(0...100)
        while (rand > self.permWeights[permuteNum]) {
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
