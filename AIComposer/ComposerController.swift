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

struct CompositionGene {
    let composition: MusicComposition!
    var fitness = 0.0
}

class ComposerController: NSObject {
    
    let midiManager = MIDIManager.sharedInstance
    
    let presetList: [UInt8] = [0, 1, 4, 5, 6, 11, 24, 45, 46,
        80, 81, 98, 99]
    
    let numberOfGenes = 8
    let fitnessGoal = 0.8
    let maxAttempts = 100
    
    //  Returns the singleton instance
    class var sharedInstance:ComposerController {
        return ComposerControllerInstance
    }
    
    /**
     Composes a new piece of music.
    */
    //  TODO:   Implement the genetic algorithm
    func createComposition(musicDataSet: MusicDataSet) {
        
        var compositionGenes = self.initializeCompositions(musicDataSet)        //  Initialization
        var currentAttempt = 0
        var bestFitness = self.checkComposition(compositionGenes).bestFit       //  First Check
        
        while bestFitness < fitnessGoal && currentAttempt < maxAttempts {       //  Genetic processes
            compositionGenes = self.selectFitCompositions(compositionGenes)     //  Selection
            compositionGenes = self.crossoverCompositions(compositionGenes)     //  Crossover
            compositionGenes = self.mutateCompositions(compositionGenes)        //  Mutation
            let test = self.checkComposition(compositionGenes)                  //  Test
            compositionGenes = test.compositionGenes
            bestFitness = test.bestFit
            currentAttempt++
        }
        musicDataSet.compositions.append(self.getCompositionWithBestFitness(compositionGenes))
    }
    
    //  GENETIC ALGORITHM methods
    
    //  Initialization
    //  TODO: Implement initialization
    private func initializeCompositions(musicDataSet: MusicDataSet) -> [CompositionGene]
    {
        let randomName = self.getRandomName()
        var compositions = [CompositionGene]()
        for _ in 0..<self.numberOfGenes {
            
            let mainTheme = self.createMainTheme(musicDataSet)  //  All genes will be based on this theme.
            let newTempo: Float64 = Float64(Int.random(40...140))
            let chords = self.generateChordProgressions(musicDataSet)
            
            var parts = [MusicPart]()
            var numberOfMeasures = 0
            for partNum in 0..<4 {
                
                let newPart = self.composeNewPartWithChannel(partNum,
                    musicDataSet: musicDataSet,
                    timeSig: TimeSignature(numberOfBeats:4, beatLength: 1.0),
                    numberOfMeasures: numberOfMeasures,
                    musicSnippet: mainTheme,
                    chords: chords,
                    tempo: newTempo,
                    compWeights: musicDataSet.compositionWeights)
                
                if newPart.numberOfMeasures > numberOfMeasures {
                    numberOfMeasures = newPart.numberOfMeasures
                }
                
                parts.append(newPart.part)
            }
            let newCompositionGene = CompositionGene(composition: MusicComposition(name: randomName, musicParts: parts, numberOfMeasures: numberOfMeasures), fitness: 0.0)
            compositions.append(newCompositionGene)
        }
        return compositions
    }
    
    //  Selection
    //  TODO: Implement selection
    private func selectFitCompositions(compositionGenes: [CompositionGene]) -> [CompositionGene]
    {
        return compositionGenes
    }
    
    //  Crossover
    //  TODO: Implement crossover. 
    //  Should it exchange entire measures for each part, or separate measures in separate parts?
    
    //  Implementation:
    //      Each pair of compositions exchanges measures
    private func crossoverCompositions(compositionGenes: [CompositionGene]) -> [CompositionGene]
    {
        return compositionGenes
    }
    
    //  Mutation
    //  TODO: Implement Mutation
    //  It might be cool for the algorithm to alter chance of mutation if results do no improve
    private func mutateCompositions(compositionGenes: [CompositionGene]) -> [CompositionGene]
    {
        return compositionGenes
    }
    
    
    //  TODO: checkComposition: Generates a fitness score based on several criteria. (To be determined)
    private func checkComposition(compositionGenes: [CompositionGene]) -> (compositionGenes: [CompositionGene], bestFit: Double) {
        return (compositionGenes, 0.0)
    }
    
    //  After the genetic algorithm, gets the best fit composition
    private func getCompositionWithBestFitness(compositionGenes: [CompositionGene]) -> MusicComposition {
        var bestFit = 0.0
        var returnComposition:MusicComposition!
        for compositionGene in compositionGenes {
            if compositionGene.fitness > bestFit {
                bestFit = compositionGene.fitness
                returnComposition = compositionGene.composition
            }
        }
        if returnComposition == nil {
            returnComposition = compositionGenes[0].composition
        }
        return returnComposition
    }
    
    private func createMainTheme(musicDataSet: MusicDataSet) -> MusicSnippet {
        
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
        return musicSnippet
    }
    
    //  Generate the chord progressions and form
    //  TODO: Expand this to create a longer progressionand form
    private func generateChordProgressions(musicDataSet: MusicDataSet) -> [String]
    {
        return musicDataSet.chordProgressions[Int.random(0..<musicDataSet.chordProgressions.count)].chords
    }
    
    //  Creates a new part based on weights and other criteria
    func composeNewPartWithChannel(partNum: Int, musicDataSet: MusicDataSet, timeSig: TimeSignature, var numberOfMeasures: Int, musicSnippet: MusicSnippet, chords: [String], tempo: Float64, compWeights: CompositionWeights) -> (part: MusicPart, numberOfMeasures: Int, octaveOffset: Int)
    {
        let randomPreset:UInt8 = presetList[Int.random(0..<presetList.count)]
        var measures = [MusicMeasure]()
        var timeOffset: MusicTimeStamp = 0.0
        let octaveOffset = -(partNum * 12) + 12
        numberOfMeasures = 0
        let newSnippet = self.createNewMotive(musicDataSet.musicSnippets, snippet: musicSnippet, weight: 0.5, numberOfBeats: Double(timeSig.numberOfBeats))
        for chord in chords {
            numberOfMeasures++
            if Double.random() > compWeights.chanceOfRest {
                measures.append(self.generateMeasureForChord(
                    channel: partNum,
                    chord: chord,
                    musicSnippets: musicDataSet.musicSnippets,
                    musicSnippet: newSnippet,
                    octaveOffset: octaveOffset,
                    timeSig: TimeSignature(numberOfBeats: timeSig.numberOfBeats, beatLength: 1.0),
                    startTimeStamp: timeOffset,
                    tempo: tempo,
                    compWeights: compWeights))
            }
            timeOffset = timeOffset + MusicTimeStamp(timeSig.numberOfBeats)
        }
        measures.append(self.generateEndingMeasureForChord(
            chords[0],
            channel: partNum,
            timeSig: timeSig,
            startTimeStamp: timeOffset,
            previousNote: measures[measures.count - 1].notes.last!.midiNoteMess,
            tempo: tempo))
        numberOfMeasures++
        return (MusicPart(measures: measures, preset: randomPreset), numberOfMeasures, octaveOffset)
    }
    
    //  Creates a single measure
    private func generateMeasureForChord(
        channel channel: Int,
        chord: String,
        musicSnippets: [MusicSnippet],
        musicSnippet: MusicSnippet,
        octaveOffset: Int,
        timeSig: TimeSignature,
        startTimeStamp: MusicTimeStamp,
        tempo: Float64,
        compWeights: CompositionWeights
        ) -> MusicMeasure
    {
        let newMergeSnippet = self.createNewMotive(musicSnippets, snippet: musicSnippet, weight: 0.6, numberOfBeats: Double(timeSig.numberOfBeats))
        let snippet1 = self.getSnippetWithRandomPermutation(newMergeSnippet, compWeights: compWeights)
        snippet1.transposeToChord(chord, keyOffset: octaveOffset)
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
    
    
    //  Generates the final measure. For now, it just adds held out notes in the tonic chord
    private func generateEndingMeasureForChord(chord: String, channel: Int, timeSig: TimeSignature, startTimeStamp: MusicTimeStamp, previousNote: MIDINoteMessage, tempo: Float64) -> MusicMeasure
    {
        let chordController = MusicChord.sharedInstance
        let chordNotes = chordController.chordNotes[chord]
        let noteNumber = chordNotes![Int.random(0..<chordNotes!.count)]
        let octave = Int(previousNote.note) / 12
        let newNoteNum:Int =  noteNumber + (octave * 12)
        let midiNote = MIDINoteMessage(channel: UInt8(channel), note: UInt8(newNoteNum), velocity: previousNote.velocity, releaseVelocity: 0, duration: Float32(timeSig.numberOfBeats))
        let newNote = MusicNote(noteMessage: midiNote, timeStamp: startTimeStamp)
        return MusicMeasure(tempo: tempo, timeSignature: timeSig, firstBeatTimeStamp: startTimeStamp, notes: [newNote], chord: chord)
    }
    
    //  Generates a new MusicSnippet theme
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
    
    //  Generates a random permutation based on weights
    private func getSnippetWithRandomPermutation(musicSnippet: MusicSnippet, compWeights: CompositionWeights) -> MusicSnippet {
        let newSnippet = MusicSnippet(notes: musicSnippet.musicNoteEvents)
        var permuteNum = 0
        let rand = Double.random()
        while (rand > compWeights.permutationWeights[permuteNum]) {
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
        
        if Double.random() < compWeights.chanceOfCrescendo {
            let start = Int.random(0..<newSnippet.count)
            let end = Int.random(start..<newSnippet.count)
            newSnippet.applyDynamicLine(startIndex: start, endIndex: end, startVelocity: UInt8(Int.random(25..<127)), endVelocity: UInt8(Int.random(25..<127)))
        } else if Double.random() < compWeights.chanceOfArticulation {
            let start = Int.random(0..<newSnippet.count)
            let end = Int.random(start..<newSnippet.count)
            var articulationType:Articulation.RawValue = 0
            while(Double.random() > compWeights.articulationWeights[articulationType]) {
                articulationType++
            }
            let artic = Articulation(rawValue: articulationType)
            newSnippet.applyArticulation(startIndex: start, endIndex: end, articulation: artic!)
        }
        
        return newSnippet
    }
    
    private func getRandomName() -> String {
        let randomNames = ["Tapestry No. ", "Viginette No. ", "Evolved No. ", "Fantasy No. "]
        return randomNames[Int.random(0..<randomNames.count)] + "\(Int.random(0..<20))"
    }
}
