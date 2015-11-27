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
    
    //  MARK: Music Data
    var musicDataSet:MusicDataSet!
    var compositionGenes: [CompositionGene]!
    var chords: [String]!
    var chordProgressionCDF = [(weight: Double, chordProg: MusicChordProgression)]()
    var tempo: Float64 = 120
    var timeSig = TimeSignature(numberOfBeats: 4, beatLength: 1.0)
    var mainTheme = MusicSnippet()
    
    //  MARK: Instrument presets
    let presetList: [UInt8] = [0, 1, 2, 4, 5, 6, 11, 12, 13, 14, 15, 24, 25, 26, 27, 45, 46,
        80, 98, 99, 108, 114]
    
    //  MARK: Genetic algorithm variables
    let numberOfGenes = 8
    let fitnessGoal = 0.8
    let maxAttempts = 100
    
    //  Returns the singleton instance
    class var sharedInstance:ComposerController {
        return ComposerControllerInstance
    }
    
    //  MARK: - Main composition creation method called to run the genetic algorithm
    /**
     Composes a new piece of music.
     */
    func createComposition(musicDataSet: MusicDataSet) -> MusicDataSet {
        
        self.musicDataSet = musicDataSet
        // Initialize the chord progression cumulative distribution function
        var chordProgWeight = 0.0
        for chordProg in self.musicDataSet.chordProgressions {
            chordProgWeight = chordProgWeight + chordProg.weight
            self.chordProgressionCDF.append((chordProgWeight, chordProg))
        }
        
        self.initializeCompositions()        //  Initialization
        var currentAttempt = 0
        var bestFitness = self.checkComposition()       //  First Check
        
        //  Genetic processes
        //  TODO:   Implement the genetic algorithm
        while bestFitness < fitnessGoal && currentAttempt < maxAttempts
        {
            self.selectFitCompositions()                            //  Selection
            self.crossoverCompositions()                            //  Crossover
            self.mutateCompositions()                               //  Mutation
            bestFitness = self.checkComposition()                   //  Test
            currentAttempt++
        }
        self.musicDataSet.compositions.append(self.getCompositionWithBestFitness())
        return self.musicDataSet
    }
    //  MARK: - GENETIC ALGORITHM methods
    
    //  Initialization
    private func initializeCompositions()
    {
        let randomName = self.getRandomName()           //  This is for fun.
        self.compositionGenes = [CompositionGene]()
        let presets = self.setInstrumentPresets()
        for _ in 0..<self.numberOfGenes {
            
            self.createMainTheme()  //  All genes will be based on this theme.
            self.tempo = Float64(Int.random(40...140))
            self.generateChordProgressions()
            
            var parts = [MusicPart]()
            var numberOfMeasures = 0
            for partNum in 0..<4 {
                
                let newPart = self.composeNewPartWithChannel(partNum, numberOfMeasures: numberOfMeasures, presets: presets)
                
                if newPart.numberOfMeasures > numberOfMeasures {
                    numberOfMeasures = newPart.numberOfMeasures
                }
                parts.append(newPart.part)
            }
            let newCompositionGene = CompositionGene(composition: MusicComposition(name: randomName, musicParts: parts, numberOfMeasures: numberOfMeasures), fitness: 0.0)
            self.compositionGenes.append(newCompositionGene)
        }
    }
    
    //  Selection
    private func selectFitCompositions()
    {
        //  TODO: Implement selection
    }
    
    //  Crossover
    //  Should it exchange entire measures for each part, or separate measures in separate parts?
    
    //  Implementation:
    //      Each pair of compositions exchanges measures
    private func crossoverCompositions()
    {
        //  TODO: Implement crossover.
    }
    
    //  Mutation
    //  It might be cool for the algorithm to alter chance of mutation if results do no improve
    private func mutateCompositions()
    {
        //  TODO: Implement Mutation
    }
    
    
    private func checkComposition() -> Double
    {
        //  TODO: checkComposition: Generates a fitness score based on several criteria. (To be determined)
        return 0.0
    }
    
    //  After the genetic algorithm, gets the best fit composition
    private func getCompositionWithBestFitness() -> MusicComposition {
        var bestFit = 0.0
        var returnComposition:MusicComposition!
        for compositionGene in self.compositionGenes {
            if compositionGene.fitness > bestFit {
                bestFit = compositionGene.fitness
                returnComposition = compositionGene.composition
            }
        }
        if returnComposition == nil {
            returnComposition = self.compositionGenes[0].composition
        }
        return returnComposition
    }
    //
    //  MARK: - Fitness Checks
    //
    
    /**
    Returns the ratio of measures with no notes to those with notes
    
    - Returns: `Double`
    */
    private func checkSilenceRatio(comp: MusicComposition) -> Double {
        var silentMeasures = 0.0
        var musicMeasures = 0.0
        for i in 0..<comp.numberOfMeasures {
            for part in comp.musicParts {
                if part.measures[i].notes.count == 0 {
                    silentMeasures++
                } else {
                    musicMeasures++
                }
            }
        }
        return silentMeasures / musicMeasures
    }
    
    /**
     Returns the ratio of dissonance to conssonance against chords and other notes in the same beat
     
     - Returns: (chordDissonanceRatio: `Double`, noteDissonanceRatio: `Double`)
     */
    private func checkDissonanceRatio(comp: MusicComposition) -> (chordDissonanceRatio: Double, noteDissonanceRatio: Double) {
        let chordCtrl = MusicChord.sharedInstance
        
        //  Check Dissonance against chord in each measure
        var dissonantDuration = 0.0
        var consonantDuration = 0.0
        for i in 0..<comp.numberOfMeasures {
            let chordNotes = chordCtrl.chordNotes[comp.musicParts[0].measures[0].chord]
            for part in comp.musicParts {
                for note in part.measures[i].notes {
                    if chordNotes!.contains(Int(note.midiNoteMess.note % 12)) {
                        consonantDuration = consonantDuration + Double(note.midiNoteMess.duration)
                    } else {
                        dissonantDuration = dissonantDuration + Double(note.midiNoteMess.duration)
                    }
                }
            }
        }
        
        //  Check Dissonance note to note
        var noteDissonances = 0.0
        var totalNotes = 0.0
        for mNum in 0..<comp.numberOfMeasures {
            for (var j: MusicTimeStamp = 1; j < 5; j++) {
                var notesInBeat: Set = Set<UInt8>()
                for part in comp.musicParts {
                    for note in part.measures[mNum].notes {
                        totalNotes++
                        if note.timeStamp < j {
                            notesInBeat.insert(note.midiNoteMess.note % 12)
                        } else {
                            break
                        }
                    }
                }
                for nextNote in notesInBeat {
                    for compareNote in notesInBeat {
                        let interval = abs(Int(nextNote) - Int(compareNote))
                        switch interval {
                        case 1, 2, 5, 6, 10, 11:
                            noteDissonances++
                        default:
                            break
                        }
                    }
                }
            }
        }
        return ((dissonantDuration / consonantDuration), (noteDissonances / totalNotes))
    }
    
    private func checkThematicVariety(comp: MusicComposition) -> Double {
        // TODO: Implement this (Checking for similarity between measures sounds hard. haha)
        return 0.0
    }
    
    private func checkDynamicSmoothness(comp: MusicComposition) -> Double {
        // TODO: Implement this
        return 0.0
    }
    
    //
    //  MARK: - Compositional methods
    //
    
    private func createMainTheme() {
        
        var musicSnippet: MusicSnippet!
        let mainSnippetIndex = Int.random(0..<self.musicDataSet.musicSnippets.count)
        if self.musicDataSet.musicSnippets[mainSnippetIndex].getHighestWeightChord().containsString("m") {
            musicSnippet = MusicSnippet(notes: self.musicDataSet.musicSnippets[mainSnippetIndex].musicNoteEvents)
            musicSnippet.transposeToChord("Cm", keyOffset: 0)
        } else {
            musicSnippet = MusicSnippet(notes: self.musicDataSet.musicSnippets[mainSnippetIndex].musicNoteEvents)
            musicSnippet.transposeToChord("C", keyOffset: 0)
        }
        if self.musicDataSet.musicSnippets.count > 1 {
            for _ in 0..<3 {
                musicSnippet = self.createNewMotive(self.musicDataSet.musicSnippets[mainSnippetIndex])
            }
        } else {
            musicSnippet = MusicSnippet(notes: self.musicDataSet.musicSnippets[0].musicNoteEvents)
        }
        self.mainTheme = musicSnippet
    }
    
    //  Set the instruments for each part
    private func setInstrumentPresets() -> [UInt8] {
        var presets:[UInt8] = []
        for _ in 0..<4 {
            var randomPreset:UInt8 = presetList[Int.random(0..<presetList.count)]
            while presets.contains(randomPreset) {
                randomPreset = presetList[Int.random(0..<presetList.count)]
            }
            presets.append(randomPreset)
        }
        return presets
    }
    
    //  Generate the chord progressions
    private func generateChordProgressions()
    {
        self.chords = [String]()
        let numberOfProgressions = Int.random(3...8)
        for _ in 0..<numberOfProgressions {
            var chordProgIndex = 0
            let randomDbl = Double.random()
            while chordProgressionCDF[chordProgIndex].weight < randomDbl {
                chordProgIndex++
            }
            
            self.chords.appendContentsOf(self.musicDataSet.chordProgressions[chordProgIndex].chords)
        }
    }
    
    //  Creates a new part based on weights and other criteria
    func composeNewPartWithChannel(partNum: Int, var numberOfMeasures: Int, presets: [UInt8]) -> (part: MusicPart, numberOfMeasures: Int, octaveOffset: Int)
    {
        let randomPreset = presets[partNum]
        var measures = [MusicMeasure]()
        var timeOffset: MusicTimeStamp = 0.0
        let octaveOffset = -(partNum * 12) + 12
        numberOfMeasures = 0
        let newSnippet = self.createNewMotive(self.mainTheme)
        for chord in chords {
            numberOfMeasures++
            if Double.random() > self.musicDataSet.compositionWeights.chanceOfRest {
                measures.append(self.generateMeasureForChord(
                    channel: partNum,
                    chord: chord,
                    musicSnippet: newSnippet,
                    octaveOffset: octaveOffset,
                    startTimeStamp: timeOffset))
            } else {
                measures.append(MusicMeasure(tempo: self.tempo, timeSignature: self.timeSig, firstBeatTimeStamp: timeOffset, notes: [], chord: chord))  //  Generate an empty measure
            }
            timeOffset = timeOffset + MusicTimeStamp(timeSig.numberOfBeats)
        }
        measures.append(self.generateEndingMeasureForChord(
            chords[0],
            channel: partNum,
            startTimeStamp: timeOffset,
            previousNote: measures[measures.count - 1].notes.last!.midiNoteMess))
        numberOfMeasures++
        return (MusicPart(measures: measures, preset: randomPreset), numberOfMeasures, octaveOffset)
    }
    
    //  Creates a single measure
    private func generateMeasureForChord(channel channel: Int, chord: String, musicSnippet: MusicSnippet, octaveOffset: Int, startTimeStamp: MusicTimeStamp) -> MusicMeasure
    {
        let newMergeSnippet = self.createNewMotive(musicSnippet)
        let snippet1 = self.getSnippetWithRandomPermutation(newMergeSnippet)
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
    private func generateEndingMeasureForChord(chord: String, channel: Int, startTimeStamp: MusicTimeStamp, previousNote: MIDINoteMessage) -> MusicMeasure
    {
        let chordController = MusicChord.sharedInstance
        let chordNotes = chordController.chordNotes[chord]
        let noteNumber = chordNotes![Int.random(0..<chordNotes!.count)]
        let octave = Int(previousNote.note) / 12
        let newNoteNum:Int =  noteNumber + (octave * 12)
        let midiNote = MIDINoteMessage(channel: UInt8(channel), note: UInt8(newNoteNum), velocity: previousNote.velocity, releaseVelocity: 0, duration: Float32(self.timeSig.numberOfBeats))
        let newNote = MusicNote(noteMessage: midiNote, timeStamp: startTimeStamp)
        return MusicMeasure(tempo: tempo, timeSignature: self.timeSig, firstBeatTimeStamp: startTimeStamp, notes: [newNote], chord: chord)
    }
    
    //  Generates a new MusicSnippet theme
    private func createNewMotive(snippet: MusicSnippet) -> MusicSnippet {
        var musicSnippet = MusicSnippet()
        for i in 0..<self.musicDataSet.musicSnippets.count {
            if i != self.musicDataSet.musicSnippets.indexOf(snippet) {
                if self.musicDataSet.musicSnippets[i].getHighestWeightChord() == snippet.getHighestWeightChord() {
                    musicSnippet = snippet.mergeNotePassagesRhythmically(
                        firstWeight: self.musicDataSet.compositionWeights.mainThemeWeight,
                        chanceOfRest: self.musicDataSet.compositionWeights.chanceOfRest,
                        secondSnippet: self.musicDataSet.musicSnippets[i],
                        numberOfBeats: Double(self.timeSig.numberOfBeats))
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
    private func getSnippetWithRandomPermutation(musicSnippet: MusicSnippet) -> MusicSnippet {
        let newSnippet = MusicSnippet(notes: musicSnippet.musicNoteEvents)
        var permuteNum = 0
        let rand = Double.random()
        while (rand > self.musicDataSet.compositionWeights.permutationWeights[permuteNum]) {
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
        
        if Double.random() < self.musicDataSet.compositionWeights.chanceOfCrescendo {
            let start = Int.random(0..<newSnippet.count)
            let end = Int.random(start..<newSnippet.count)
            newSnippet.applyDynamicLine(startIndex: start, endIndex: end, startVelocity: UInt8(Int.random(25..<127)), endVelocity: UInt8(Int.random(25..<127)))
        } else if Double.random() < self.musicDataSet.compositionWeights.chanceOfArticulation {
            let start = Int.random(0..<newSnippet.count)
            let end = Int.random(start..<newSnippet.count)
            var articulationType:Articulation.RawValue = 0
            while(Double.random() > self.musicDataSet.compositionWeights.articulationWeights[articulationType]) {
                articulationType++
            }
            let artic = Articulation(rawValue: articulationType)
            newSnippet.applyArticulation(startIndex: start, endIndex: end, articulation: artic!)
        }
        
        return newSnippet
    }
    
    private func getRandomName() -> String {
        let randomNames = ["Tapestry No. ", "Viginette No. ", "Evolved No. ", "Fantasy No. ", "Thing No. ", "Epiphany No. "]
        return randomNames[Int.random(0..<randomNames.count)] + "\(Int.random(0..<20))"
    }
}
