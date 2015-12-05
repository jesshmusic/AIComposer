//
//  ComposerController.swift
//  AIComposer
//
//  Created by Jess Hendricks on 11/13/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import Cocoa
import AudioToolbox

//  Composition Scores
let EXPECTED_FITNESS = 85.0
let EXPECTED_SILENCE = 5.0
let EXPECTED_CHORD_DISSONANCE = 35.0
let EXPECTED_NOTE_DISSONANCE = 45.0
let EXPECTED_DYNAMICS = 5.0
let EXPECTED_RHYTHMIC_VAR = 10.0

//  Theme Scores
let THEME_EXPECTED_CHORD_RATIO_SCORE = 40.0
let THEME_DURATION_TEMPO_SCORE = 35.0
let THEME_AVG_LEAP_SCORE = 25.0

//  Smoothing values
let VELOCITY_MAX_CHANGE = 25
let NOTE_MAX_LEAP = 15

//  Holds a short music snippet that is used to create the entire composition.
//  Generated with a genetic algorithm.
struct MainThemeGene {
    var musicSnippet: MusicSnippet!
    let chord: Chord!
    var fitness = 0.0
}

//  These are the values used in computing fitness for a composition gene
struct DesiredResults {
    
    // Composition Ratios
    var silenceRatio = 0.1
    var chordDissonanceRatio = 0.4
    var noteDissonanceRatio = 0.1
    var averageVelocityRange = 3.0
    var rhythmicVariety = 0.3
    
    // Theme Ratios
    var themeChordRatio = 0.75
    
    //  Max ideal average durations for tempos
    var slowTempoAvgDuration = 0.25
    var medTempoAvgDuration = 0.5
    var fastTempoAvgDuration = 1.0
    
    // Smoothness of melody / average leap
    var averageLeap = 3.0
}

//  These weights are used in generating the compositions AND creating permutations during the algorithm.
struct CompositionWeights {
    var mainThemeWeight = 0.65
    var permutationWeights = [0.1, 0.2, 0.3, 0.35, 0.5, 0.6, 0.8, 1.0]
    var chanceOfRest = 0.1
    var chanceOfCrescendo = 0.65
    var chanceOfArticulation = 0.65
    var articulationWeights = [0.2, 0.8, 0.85, 0.95, 1.0]
    
    //  Genetic Algorithm parameters
    var chanceOfMutation = 0.125
    var chanceOfCrossover = 0.4
    
    //  Mutation replace vs permute
    var permuteMutation = 0.5
}

class ComposerController: NSObject {
    
    let midiManager = MIDIManager.sharedInstance
    
    //  MARK: Music Data
    var musicDataSet:MusicDataSet!
    var compositionGenes: [MusicComposition]!
    var chords: [Chord]!
    var chordProgressionCDF = [(weight: Double, chordProg: MusicChordProgression)]()
    var tempo: Float64 = 120
    let minTempo = 60
    let maxTempo = 140
    var timeSig = TimeSignature(numberOfBeats: 4, beatLength: 1.0)
    var mainTheme = MusicSnippet()
    var numberOfParts = 4
    var usedChordNoteValues = [UInt8]()
    var maxChordProgressions = 4
    
    //  MARK: Instrument presets
//    let presetList: [UInt8] = [0, 1, 2, 4, 5, 6, 11, 12, 13, 15, 24, 25, 26, 27, 45, 46,
//        80, 98, 99, 108, 114]
    
    let presetList: [UInt8] = [38, 39, 54, 62, 63, 80, 81, 82, 85, 87, 88, 90, 94, 96, 99, 100]
    
    //  MARK: Genetic algorithm variables
    //  These can be adjusted to hopefully get better results.
    var numberOfGenes: Int!
    let desiredResults = DesiredResults()
    var maxAttempts: Int!
    var compositionWeights = CompositionWeights()
    
    
    //  The 'constructor' for this object. It is not singleton because it runs in its own thread.
    init(musicDataSet: MusicDataSet, numberOfGenes: Int = 8, maxGenerations: Int = 100) {
        self.musicDataSet = musicDataSet
        self.numberOfGenes = numberOfGenes
        self.maxAttempts = maxGenerations
    }
    
    //  MARK: - Main composition creation method called to run the genetic algorithm
    /**
    Composes a new piece of music.
    
    - Returns: `MusicDataSet` with the new composition added.
    */
    func createComposition() -> MusicDataSet {
        
        self.numberOfParts = Int.random(2...4)
        
        dispatch_async(dispatch_get_main_queue()) {
            self.sendDataNotification("GENETIC ALGORITHM STARTING... \n\tInitializing compositions with \(self.numberOfParts) parts.\n-----------------------------\n")
        }
        
        var bestFitness = 0.0
        if self.musicDataSet.musicSnippets.count != 0 {
            
            // Initialize the chord progression cumulative distribution function
            var chordProgWeight = 0.0
            for chordProg in self.musicDataSet.chordProgressions {
                chordProgWeight = chordProgWeight + chordProg.weight
                self.chordProgressionCDF.append((chordProgWeight, chordProg))
            }
            
            //  Initialization
            self.initializeCompositions()
            var currentGeneration = 0
            self.checkCompositions()       //  First Check
            for compGene in self.compositionGenes {
                if compGene.fitnessScore > bestFitness {
                    bestFitness = compGene.fitnessScore
                }
            }
            
            //  Genetic processes
            
            while bestFitness < EXPECTED_FITNESS
            {
                if currentGeneration > maxAttempts {
                    break
                }
                self.selectFitCompositions()                            //  Selection
                self.crossoverCompositions()                            //  Crossover
                self.mutateCompositions()                               //  Mutation
                self.checkCompositions()                                //  First Check
                for compGene in self.compositionGenes {
                    if compGene.fitnessScore > bestFitness {
                        bestFitness = compGene.fitnessScore
                    }
                    //                    print("\t\t compGene - \(compGene.composition.name)... score: \(compGene.fitness)")
                }
                
                //  Sends an info string to the main thread.
                dispatch_async(dispatch_get_main_queue()) {
                    self.sendDataNotification("GENERATION \(currentGeneration), best fitness: \(bestFitness)")
                }
                currentGeneration++
            }
            
            //  When a successful composition is created, 'humanize' all of the notes and add it to the list.
            let composition = self.getCompositionWithBestFitness()
            composition.finishComposition()
            self.musicDataSet.compositions.append(composition)
        } else {
            self.sendDataNotification("FAIL. Please load music data.")
        }
        //  Sends an info string to the main thread.
        dispatch_async(dispatch_get_main_queue()) {
            self.sendDataNotification("\n-----------------------------------\nCOMPLETE, best fitness score = \(bestFitness)")
        }
        for compGene in self.compositionGenes {
            if compGene.fitnessScore > bestFitness {
                bestFitness = compGene.fitnessScore
            }
            //  Sends an info string to the main thread.
            dispatch_async(dispatch_get_main_queue()) {
                self.sendDataNotification("\t\t compGene - \(compGene.name)... score: \(compGene.fitnessScore)")
            }
            
        }
        return self.musicDataSet
    }
    //  MARK: - GENETIC ALGORITHM methods
    
    //  Initialization
    private func initializeCompositions()
    {
        //  Sends an info string to the main thread.
        dispatch_async(dispatch_get_main_queue()) {
            self.sendDataNotification("Initializing \(self.numberOfGenes) compositions...")
        }
        let randomName = self.getRandomName()           //  This is for fun.
        self.compositionGenes = [MusicComposition]()
        let presets = self.setInstrumentPresets()
        self.tempo = Float64(Int.random(self.minTempo...self.maxTempo))
        self.generateChordProgressions()
        self.createMainTheme(self.chords[0])  //  All genes will be based on this theme.
        for _ in 0..<self.numberOfGenes {
            
            
            var parts = [MusicPart]()
            self.usedChordNoteValues = []
            var numberOfMeasures = 0
            let startingVelocity = UInt8(Int.random(40...90))
            for partNum in 0..<self.numberOfParts {
                
                let newPart = self.composeNewPartWithChannel(partNum, startingVelocity: startingVelocity, numberOfMeasures: numberOfMeasures, presets: presets)
                
                if newPart.numberOfMeasures > numberOfMeasures {
                    numberOfMeasures = newPart.numberOfMeasures
                }
                parts.append(newPart.part)
            }
            let newCompositionGene = MusicComposition(name: randomName, musicParts: parts, numberOfMeasures: numberOfMeasures)
            self.compositionGenes.append(newCompositionGene)
        }
        //  Sends an info string to the main thread.
        dispatch_async(dispatch_get_main_queue()) {
            self.sendDataNotification("Initialization complete.")
        }
    }
    
    //  Selection
    private func selectFitCompositions()
    {
        var newGeneArray = [MusicComposition]()
        let fitnessInfo = self.orderGenesByBestFitness()  //  I think this will help getting the most fit genes.
        var fitnessCDF = fitnessInfo.fitnessCDF
        
        //  Get the best composition to propagate
        newGeneArray.append(MusicComposition(composition: self.compositionGenes[0]))
        newGeneArray.append(MusicComposition(composition: self.compositionGenes[0]))
        
        while newGeneArray.count != self.numberOfGenes {
            let rand = Double.random()
            var geneIndex = 0
            while fitnessCDF[geneIndex] < rand {
                geneIndex++
            }
            newGeneArray.append(MusicComposition(composition: self.compositionGenes[geneIndex]))
        }
        self.compositionGenes = newGeneArray
    }
    
    //  Crossover
    //  Each parent exchanges a random number of MusicParts
    private func crossoverCompositions()
    {
        let numberOfParts = self.compositionGenes[0].musicParts.count
        
        //  Bit mask of which measures to crossover.
        var bitMask = self.createBitmask(numberOfParts, chanceOfBit: self.compositionWeights.chanceOfCrossover)
        for (var compGeneIndex = 1; compGeneIndex < self.numberOfGenes; compGeneIndex = compGeneIndex + 2) {
            for partIndex in 0..<numberOfParts {
                if bitMask[partIndex] {
                    let exchangePart = self.compositionGenes[compGeneIndex].exchangeMusicPart(partNumber: partIndex, newPart: self.compositionGenes[compGeneIndex - 1].musicParts[partIndex])
                    self.compositionGenes[compGeneIndex - 1].exchangeMusicPart(partNumber: partIndex, newPart: exchangePart)
                }
            }
        }
    }
    
    //  Mutation
    //  It might be cool for the algorithm to alter chance of mutation if results do no improve
    private func mutateCompositions()
    {
        //  Bitmask of which composition genes to mutate.
        var bitMask = [Bool]()
        for _ in 0..<self.numberOfGenes {
            let random = Double.random()
            if random < self.compositionWeights.chanceOfMutation {
                bitMask.append(true)
            } else {
                bitMask.append(false)
            }
        }
        for geneIndex in 0..<numberOfGenes {
            if bitMask[geneIndex] {
                for partIndex in 0..<self.compositionGenes[geneIndex].musicParts.count {
                    var needsRangeChecked = false
                    let numberOfMeasures = self.compositionGenes[geneIndex].musicParts[partIndex].measures.count
                    for measureIndex in 0..<numberOfMeasures {
                        if self.compositionGenes[geneIndex].musicParts[partIndex].measures[measureIndex].notes.count != 0 {
                            let random = Double.random()
                            if random < self.compositionWeights.chanceOfMutation {
                                if measureIndex != numberOfMeasures - 1 {
                                    let randomMutation = Double.random()
                                    var newMeasure:MusicMeasure!
                                    let oldMeasure = self.compositionGenes[geneIndex].musicParts[partIndex].measures[measureIndex]
                                    if randomMutation < self.compositionWeights.permuteMutation {
                                        newMeasure = self.applyRandomPermutationToMeasure(oldMeasure)
                                        self.compositionGenes[geneIndex].musicParts[partIndex].setMeasure(measureNum: measureIndex, newMeasure: newMeasure)
                                    } else {
                                        let newSnippet = self.createNewMotive(self.mainTheme, chord: oldMeasure.chord)
                                        let mutatedMeasureData = self.generateMeasureForChord(
                                            channel: partIndex,
                                            chord: self.compositionGenes[geneIndex].musicParts[partIndex].measures[measureIndex].chord,
                                            currentVelocity: oldMeasure.notes[0].midiNoteMess.velocity,
                                            musicSnippet: newSnippet,
                                            startTimeStamp: self.compositionGenes[geneIndex].musicParts[partIndex].measures[measureIndex].firstBeatTimeStamp,
                                            minNote: self.compositionGenes[geneIndex].musicParts[partIndex].minNote,
                                            maxNote: self.compositionGenes[geneIndex].musicParts[partIndex].maxNote)
                                        newMeasure = mutatedMeasureData.measure
                                        self.compositionGenes[geneIndex].musicParts[partIndex].setMeasure(measureNum: measureIndex, newMeasure: newMeasure)
                                    }
                                }
                                needsRangeChecked = true
                            }
                        }
                    }
                    if needsRangeChecked {
                        self.compositionGenes[geneIndex].musicParts[partIndex].checkAndCorrectRange(UInt8(partIndex))
                        self.compositionGenes[geneIndex].musicParts[partIndex].smoothIntervalsBetweenMeasures(NOTE_MAX_LEAP)
                        self.compositionGenes[geneIndex].musicParts[partIndex].smoothDynamics(VELOCITY_MAX_CHANGE)
                    }
                }
            }
        }
    }
    
    
    private func checkCompositions()
    {
        for compGene in self.compositionGenes {
            
            let results = self.checkIndividualComposition(compGene)
            
            compGene.silenceFitness = results.silenceFitness
            
            compGene.chordFitness = results.chordDissFitness
            
            compGene.noteFitness = results.noteDissFitness
            
            compGene.dynamicsFitness = results.dynamicsFitness
            
            compGene.rhythmicFitness = results.rhythmicFitness
            
            compGene.fitnessScore = results.fitness
        }
    }
    
    private func checkIndividualComposition(composition: MusicComposition) -> (fitness: Double, silenceFitness: Double, chordDissFitness: Double, noteDissFitness: Double, dynamicsFitness: Double, rhythmicFitness: Double) {
        
        var overallFitness = 0.0        //  Using a single result number for now
        var silenceRatio = 0.0
        var chordDissonanceRatio = 0.0
        var noteDissonanceRatio = 0.0
        var dynamicsResult = 0.0
        var rhythmicResult = 0.0
        
        silenceRatio = self.checkSilenceRatio(composition)
        let dissCheck = self.checkDissonanceRatio(composition)
        chordDissonanceRatio = dissCheck.chordDissonanceRatio
        noteDissonanceRatio = dissCheck.noteDissonanceRatio
        dynamicsResult = self.checkDynamicSmoothness(composition)
        rhythmicResult = self.checkRhythmicVariety(composition)
        
        var silenceScore = 0.0
        var chordDissScore = 0.0
        var noteDissScore = 0.0
        var dynamicsScore = 0.0
        var rhythmicScore = 0.0
        silenceScore = (min(silenceRatio, self.desiredResults.silenceRatio) / max(silenceRatio, self.desiredResults.silenceRatio)) * EXPECTED_SILENCE
        
        chordDissScore = (min(chordDissonanceRatio, self.desiredResults.chordDissonanceRatio) / max(chordDissonanceRatio, self.desiredResults.chordDissonanceRatio)) * EXPECTED_CHORD_DISSONANCE
        
        noteDissScore = (min(noteDissonanceRatio, self.desiredResults.noteDissonanceRatio) / max(noteDissonanceRatio, self.desiredResults.noteDissonanceRatio)) * EXPECTED_NOTE_DISSONANCE
        
        dynamicsScore = (min(dynamicsResult, self.desiredResults.averageVelocityRange) / max(dynamicsResult, self.desiredResults.averageVelocityRange)) * EXPECTED_DYNAMICS
        
        rhythmicScore = (min(rhythmicResult, self.desiredResults.rhythmicVariety) / max(rhythmicResult, self.desiredResults.rhythmicVariety)) * EXPECTED_RHYTHMIC_VAR
        
        overallFitness = overallFitness + silenceScore + chordDissScore + noteDissScore + dynamicsScore + rhythmicScore
        return (overallFitness, silenceScore, chordDissScore, noteDissScore, dynamicsScore, rhythmicScore)
    }
    
    //  After the genetic algorithm, gets the best fit composition
    private func getCompositionWithBestFitness() -> MusicComposition {
        var bestFit = 0.0
        var returnComposition:MusicComposition!
        for compositionGene in self.compositionGenes {
            if compositionGene.fitnessScore > bestFit {
                bestFit = compositionGene.fitnessScore
                returnComposition = compositionGene
            }
        }
        if returnComposition == nil {
            returnComposition = self.compositionGenes[0]
        }
        return returnComposition
    }
    //
    //  MARK: - Fitness Checks
    //
    
    /**
    Order genes based on fitness: highest to lowest
    
    - Returns: totalFitness: `Double`, fitnessCDF: `[Double]`
    */
    private func orderGenesByBestFitness() -> (totalFitness: Double, fitnessCDF: [Double]) {
        self.compositionGenes.sortInPlace({$0.fitnessScore > $1.fitnessScore})
        var totalFitness = 0.0
        for compGene in self.compositionGenes {
            totalFitness = totalFitness + compGene.fitnessScore
        }
        var fitnessCDF = [Double]()
        var nextFit = 0.0
        for compGene in self.compositionGenes {
            nextFit = nextFit + (compGene.fitnessScore / totalFitness)
            fitnessCDF.append(nextFit)
        }
        fitnessCDF[fitnessCDF.count - 1] = 1.0
        return (totalFitness, fitnessCDF)
    }
    
    /**
     Returns the ratio of measures with no notes to those with notes
     
     - Returns: `Double`
     */
    private func checkSilenceRatio(comp: MusicComposition) -> Double {
        var silentMeasures = 0.0
        for i in 0..<comp.numberOfMeasures {
            for part in comp.musicParts {
                if part.measures[i].notes.count == 0 {
                    silentMeasures++
                }
            }
        }
        return silentMeasures / Double(comp.numberOfMeasures * comp.musicParts.count)
    }
    
    /**
     Returns the ratio of dissonance to conssonance against chords and other notes in the same beat
     
     - Returns: (chordDissonanceRatio: `Double`, noteDissonanceRatio: `Double`)
     */
    private func checkDissonanceRatio(comp: MusicComposition) -> (chordDissonanceRatio: Double, noteDissonanceRatio: Double) {
        let chordCtrl = ChordController()
        
        //  Check Dissonance against chord in each measure
        //  This is working as intended.
        var dissonantDuration = 0.0
        var consonantDuration = 0.0
        for i in 0..<comp.numberOfMeasures {
            let chordNotesArray = chordCtrl.getChordNotesForChord(comp.musicParts[0].measures[0].chord)
            var chordNotes = [Int]()
            for chordNote in chordNotesArray! {
                chordNotes.append(Int(chordNote.noteValue))
            }
            for part in comp.musicParts {
                for note in part.measures[i].notes {
                    let testNote = note.getNoteCopy()
                    testNote.midiNoteMess.note = testNote.noteValue
                    if chordNotes.contains(Int(note.noteValue)) {
                        consonantDuration = consonantDuration + Double(note.midiNoteMess.duration)
                    } else {
                        dissonantDuration = dissonantDuration + Double(note.midiNoteMess.duration)
                    }
                }
            }
        }
        
        //  Check Dissonance note to note
        var consonnantNotes = 0.0
        var totalNotes = 0.0
        for measureIndex in 0..<comp.numberOfMeasures {
            var partNoteSets = [(partNum: Int, notes:[NoteSpan])]()
            for partIndex in 0..<comp.musicParts.count {
                var noteSpans = [NoteSpan]()
                for note in comp.musicParts[partIndex].measures[measureIndex].notes {
                    let startNoteTime = note.timeStamp
                    let endNoteTime = note.timeStamp + MusicTimeStamp(note.midiNoteMess.duration)
                    noteSpans.append(NoteSpan(part: partIndex, noteValue: note.noteValue, start: startNoteTime, end: endNoteTime))
                }
                noteSpans.sortInPlace({$0.start < $1.start})
                partNoteSets.append((partNum: partIndex, notes:noteSpans))
            }
            for partNoteSetIndex in 0..<partNoteSets.count {
                //                print("Measure \(measureIndex + 1) Part: \(partNoteSets[partNoteSetIndex].partNum)")
                for note in partNoteSets[partNoteSetIndex].notes {
                    // print(note.description)
                    for checkPartIndex in 0..<partNoteSets.count {
                        if checkPartIndex != partNoteSetIndex {
                            for noteToCheck in partNoteSets[checkPartIndex].notes {
                                if noteToCheck.start >= note.start && noteToCheck.end < note.end {
                                    let interval = Int(noteToCheck.noteValue) - Int(note.noteValue)
                                    switch interval {
                                    case 1, 2, 6, 10, 11:
                                        break
                                    default:
                                        consonnantNotes++
                                    }
                                }
                            }
                        }
                    }
                }
                totalNotes = totalNotes + Double(partNoteSets[partNoteSetIndex].notes.count)
            }
        }
        return ((dissonantDuration / consonantDuration), (consonnantNotes / totalNotes))
    }
    
    private func checkDynamicSmoothness(comp: MusicComposition) -> Double {
        var averageChangeInVelocity = 0.0
        var totalVelocityChange = 0.0
        var totalNotes = 0.0
        for part in comp.musicParts {
            var previousNoteVelocity:UInt8 = 0
            for measure in part.measures {
                if measure.notes.count != 0 {
                    previousNoteVelocity = measure.notes[0].midiNoteMess.velocity
                    for noteIndex in 1..<measure.notes.count {
                        let noteVelocity = measure.notes[noteIndex].midiNoteMess.velocity
                        totalVelocityChange = totalVelocityChange + Double(abs(Int(noteVelocity) - Int(previousNoteVelocity)))
                        previousNoteVelocity = noteVelocity
                        totalNotes++
                    }
                }
            }
        }
        averageChangeInVelocity = totalVelocityChange / totalNotes
        return averageChangeInVelocity
    }
    
    private func checkRhythmicVariety(comp: MusicComposition) -> Double {
        
        var rhythmicVarietyScore = 0.0
        var totalNumberOfNotes = 0.0
        //  Get the time stamps from the main theme
        var timeStamps = [MusicTimeStamp]()
        
        //  Find the first measure with notes in Part 0. (This will be the main theme.
        if self.mainTheme.musicNoteEvents.count == 0 {
            var measureIndexToCheck = 0
            while comp.musicParts[0].measures[measureIndexToCheck].notes.count == 0 {
                measureIndexToCheck++
            }
            for nextNote in comp.musicParts[0].measures[measureIndexToCheck].notes {
                timeStamps.append(nextNote.timeStamp)
            }
        } else {
            for nextNote in self.mainTheme.musicNoteEvents {
                timeStamps.append(nextNote.timeStamp)
            }
        }
        
        for part in comp.musicParts {
            for measure in part.measures {
                totalNumberOfNotes = totalNumberOfNotes + Double(measure.notes.count)
                let numberOfNotes = min(measure.notes.count, timeStamps.count)
                for i in 0..<numberOfNotes {
                    let musicNoteTimeStamp = (measure.notes[i].timeStamp % MusicTimeStamp(self.timeSig.numberOfBeats))
                    if abs(timeStamps[i] - musicNoteTimeStamp) > 0.02 {
                        rhythmicVarietyScore = rhythmicVarietyScore + 1.0
                    }
                }
            }
        }
        rhythmicVarietyScore = rhythmicVarietyScore / totalNumberOfNotes
        return rhythmicVarietyScore
    }
    
    //  MARK: - COMPOSITIONAL METHODS: Main theme generation
    // Creates the main theme for the piece. I'm going to attempt to do this with a genetic algorithm too.
    //  *** REQUIRED ***    There must be more than 1 MusicSnippet.
    private func createMainTheme(startingChord: Chord) {
        
        var themeGenes = [MainThemeGene]()
        var musicSnippet: MusicSnippet!
        let mainSnippetIndex = Int.random(0..<self.musicDataSet.musicSnippets.count)
        musicSnippet = MusicSnippet(notes: self.musicDataSet.musicSnippets[mainSnippetIndex].musicNoteEvents)
        musicSnippet.transposeToChord(chord: startingChord, keyOffset: 0)
        
        //  Initialize
        for _ in 0..<self.numberOfGenes {
            themeGenes.append(MainThemeGene(musicSnippet: self.createNewMotive(self.musicDataSet.musicSnippets[mainSnippetIndex], chord: startingChord), chord: startingChord, fitness: 0.0))
        }
        themeGenes = self.checkThemeFitness(themeGenes)
        var bestFitness = self.getThemeBestFitness(themeGenes)
        
        //  Sends an info string to the main thread.
        dispatch_async(dispatch_get_main_queue()) {
            self.sendDataNotification("Initial main themes generated: Best fitness: \(bestFitness)\n")
        }
        
        var currentGeneration = 0
        while bestFitness <= EXPECTED_FITNESS {
            if currentGeneration > maxAttempts {
                break
            }
            themeGenes = self.selectionForThemes(themeGenes)
            themeGenes = self.crossoverForThemes(themeGenes)
            themeGenes = self.mutationForThemes(themeGenes)
            themeGenes = self.checkThemeFitness(themeGenes)
            bestFitness = self.getThemeBestFitness(themeGenes)
            currentGeneration++
            
        }
        let results = self.getBestFitThemeGene(themeGenes)
        
        //  Sends an info string to the main thread.
        dispatch_async(dispatch_get_main_queue()) {
            self.sendDataNotification("Main theme generated: Best fitness: \(bestFitness)\n")
        }
        self.mainTheme = results.musicSnippet
        self.musicDataSet.musicSnippets.append(self.mainTheme)
    }
    
    //  Generates a new MusicSnippet theme
    private func createNewMotive(snippet: MusicSnippet, chord: Chord) -> MusicSnippet {
        var musicSnippet = MusicSnippet()
        let snippetIndex = self.musicDataSet.musicSnippets.indexOf(snippet)
        var randomIndex = Int.random(0..<self.musicDataSet.musicSnippets.count)
        while randomIndex == snippetIndex {
            randomIndex = Int.random(0..<self.musicDataSet.musicSnippets.count)
        }
        let mergeSnippet = MusicSnippet(musicSnippet: self.musicDataSet.musicSnippets[randomIndex])
        
        mergeSnippet.transposeToChord(chord: chord, keyOffset: 0)
        musicSnippet = snippet.mergeNotePassagesRhythmically(
            firstWeight: self.compositionWeights.mainThemeWeight,
            chanceOfRest: self.compositionWeights.chanceOfRest,
            secondSnippet: mergeSnippet,
            numberOfBeats: Double(self.timeSig.numberOfBeats))
        if musicSnippet.count == 0 {
            return snippet
        } else {
            return musicSnippet
        }
    }
    
    //  Check fitness of new main themes based on differences in range/smoothness of melody, smoothness of velocity, ratio of chord tones
    private func checkThemeFitness(themeGenes: [MainThemeGene]) -> [MainThemeGene] {
        
        let chordCtrl = ChordController()
        var returnThemes = [MainThemeGene]()
        for themeGene in themeGenes {
            var fitScore = 0.0
            var previousNote = themeGene.musicSnippet.musicNoteEvents[0]
//            var totalHalfSteps = 0
//            var lowestNote = Int(previousNote.midiNoteMess.note)
//            var highestNote = Int(previousNote.midiNoteMess.note)
            var totalDurationsInChord = 0.0
            var totalDurations = 0.0
            let chordMusicNotes = chordCtrl.getChordNotesForChord(themeGene.chord)
            var chordNotes = [UInt8]()
            for chordMusicNote in chordMusicNotes! {
                chordNotes.append(chordMusicNote.noteValue)
            }
            var totalLeaps = 0.0
            let totalNotes = Double(themeGene.musicSnippet.musicNoteEvents.count)
//            var durationResult = 0.0
            
            //  Check average leap, total range, and velocity difference
            //  FIXME: This needs to be calculated entirely different. The themes it is coming up with are not too great.
            //  More emphasis on shorter average duration at slower tempos and higher average duration at faster tempos
            //  Higher ratio of chord notes. 
            
            for noteIndex in 1..<themeGene.musicSnippet.musicNoteEvents.count {
                let currentNote = themeGene.musicSnippet.musicNoteEvents[noteIndex]
                totalDurations = totalDurations + Double(currentNote.midiNoteMess.duration)
                if chordNotes.contains(currentNote.noteValue) {
                    totalDurationsInChord = totalDurationsInChord + Double(currentNote.midiNoteMess.duration)
                }
                totalLeaps = totalLeaps + abs(Double(currentNote.midiNoteMess.note) - Double(previousNote.midiNoteMess.note))
                previousNote = currentNote
            }
            
//  (min(chordDissonanceRatio, self.desiredResults.chordDissonanceRatio) / max(chordDissonanceRatio,self.desiredResults.chordDissonanceRatio)) * EXPECTED_CHORD_DISSONANCE
            let averageTotalDuration = totalDurations / totalNotes
            let averageLeap = totalLeaps / totalNotes
            let ratioOfChordNotes = totalDurationsInChord / totalNotes
            
            let averageLeapScore = (min(averageLeap, self.desiredResults.averageLeap) / max(averageLeap, self.desiredResults.averageLeap)) * THEME_AVG_LEAP_SCORE
            let ratioOfChordNotesScore = (min(ratioOfChordNotes, self.desiredResults.themeChordRatio) / max(ratioOfChordNotes, self.desiredResults.themeChordRatio)) * THEME_EXPECTED_CHORD_RATIO_SCORE
            var averageTotalDurationScore = 0.0
            if self.tempo > 108 {
                averageTotalDurationScore = (min(averageTotalDuration, self.desiredResults.fastTempoAvgDuration) / max(averageTotalDuration, self.desiredResults.fastTempoAvgDuration)) * THEME_EXPECTED_CHORD_RATIO_SCORE
            } else if self.tempo > 72 && self.tempo <= 108 {
                averageTotalDurationScore = (min(averageTotalDuration, self.desiredResults.medTempoAvgDuration) / max(averageTotalDuration, self.desiredResults.medTempoAvgDuration)) * THEME_EXPECTED_CHORD_RATIO_SCORE
            } else {
                averageTotalDurationScore = (min(averageTotalDuration, self.desiredResults.slowTempoAvgDuration) / max(averageTotalDuration, self.desiredResults.slowTempoAvgDuration)) * THEME_EXPECTED_CHORD_RATIO_SCORE
            }
            
            fitScore = averageTotalDurationScore + averageLeapScore + ratioOfChordNotesScore
            
//            for i in 1..<themeGene.musicSnippet.musicNoteEvents.count {
//                let currentNote = themeGene.musicSnippet.musicNoteEvents[i]
//                let noteNum = Int(currentNote.midiNoteMess.note)
//                if  noteNum > highestNote {
//                    highestNote = noteNum
//                }
//                if noteNum < lowestNote {
//                    lowestNote = noteNum
//                }
//                let testNote = currentNote.getNoteCopy()
//                testNote.midiNoteMess.note = testNote.noteValue
//                if chordNotes!.contains(testNote) {
//                    totalDurationsInChord = totalDurationsInChord + Double(currentNote.midiNoteMess.duration)
//                }
//                if self.tempo > 130.0 {
//                    if currentNote.midiNoteMess.duration >= 0.33 {
//                        durationResult = durationResult + 0.2
//                    }
//                } else if self.tempo < 130.0 && self.tempo > 100.0  {
//                    if currentNote.midiNoteMess.duration >= 0.25 {
//                        durationResult = durationResult + 0.2
//                    }
//                } else if self.tempo <= 100.0 && self.tempo > 66.0 {
//                    if currentNote.midiNoteMess.duration >= 0.125 {
//                        durationResult = durationResult + 0.2
//                    }
//                } else if self.tempo <= 66.0 {
//                    if currentNote.midiNoteMess.duration <= 2.1 {
//                        durationResult = durationResult + 0.2
//                    }
//                } else {
//                    durationResult = durationResult + 0.2
//                }
//                totalDurations = totalDurations + Double(currentNote.midiNoteMess.duration)
//                totalHalfSteps = totalHalfSteps + (noteNum - Int(previousNote.midiNoteMess.note))
//                
//                previousNote = currentNote
//            }
//            
//            let averageLeap = Double(totalHalfSteps / themeGene.musicSnippet.musicNoteEvents.count)
//            var leapScore = 0.0
//            if averageLeap > 1.0 && averageLeap < 5.0 {
//                leapScore = pow(0.125, averageLeap)
//            }
//            
//            let totalRange = Double(highestNote - lowestNote)
//            var rangeScore = 0.0
//            if totalRange > 4 && totalRange < 16 {
//                rangeScore = ((1.0/(2.0 * sqrt(2 * M_PI))) * pow(M_E, ((-pow(totalRange - 10.0, 2))/(2 * 4.0))))
//                rangeScore = rangeScore <= 0.125 ? rangeScore : 0.125
//            }
//            
//            
//            let ratioOfChordNotes = totalDurationsInChord / totalDurations
//            var chordNoteRatioScore = 0.0
//            if ratioOfChordNotes >= 0.5 && ratioOfChordNotes < 0.85 {
//                chordNoteRatioScore = chordNoteRatioScore + 0.1
//            }
//            if ratioOfChordNotes >= 0.6 && ratioOfChordNotes < 0.85 {
//                chordNoteRatioScore = chordNoteRatioScore + 0.1
//            }
//            if ratioOfChordNotes >= 0.6 && ratioOfChordNotes < 0.75 {
//                chordNoteRatioScore = chordNoteRatioScore + 0.2
//            }
//            if ratioOfChordNotes >= 0.65 && ratioOfChordNotes < 0.7 {
//                chordNoteRatioScore = chordNoteRatioScore + 0.2
//            }
//            
//            let durationScore = durationResult / Double(themeGene.musicSnippet.musicNoteEvents.count)
            
//            fitScore = leapScore + rangeScore + chordNoteRatioScore + durationScore
            
            //  Add to return themes
            returnThemes.append(MainThemeGene(musicSnippet: themeGene.musicSnippet, chord: themeGene.chord, fitness: fitScore))
        }
        
        returnThemes.sortInPlace({$0.fitness > $1.fitness})
        return returnThemes
    }
    
    private func getThemeBestFitness(themeGenes: [MainThemeGene]) -> Double {
        var bestFit = 0.0
        for themeGene in themeGenes {
            if themeGene.fitness > bestFit {
                bestFit = themeGene.fitness
            }
        }
        return bestFit
    }
    
    //  Passes on half of the genes with the highest fitness
    private func selectionForThemes(themeGenes: [MainThemeGene]) -> [MainThemeGene] {
        var returnThemes = [MainThemeGene]()       //  Take half of the best fits
        let cutoffIndex = self.numberOfGenes / 2
        for i in 0..<cutoffIndex {
            returnThemes.append(themeGenes[i])
            returnThemes.append(themeGenes[cutoffIndex - i])      //  Add the genes in an alternating manner so they can crossover
        }
        return returnThemes
    }
    
    //  Merges every pair of genes
    private func crossoverForThemes(themeGenes: [MainThemeGene]) -> [MainThemeGene] {
        var returnThemes = [MainThemeGene]()
        for (var i = 1; i < themeGenes.count; i = i + 2) {
            let gene1 = themeGenes[i]
            let gene2 = themeGenes[i-1]
            let newGene1 = MainThemeGene(
                musicSnippet: gene1.musicSnippet.mergeNotePassagesRhythmically(
                    firstWeight: gene1.fitness / 100.0,
                    chanceOfRest: self.compositionWeights.chanceOfRest,
                    secondSnippet: gene2.musicSnippet,
                    numberOfBeats: Double(self.timeSig.numberOfBeats)), chord: themeGenes[0].chord, fitness: 0.0)
            let newGene2 = MainThemeGene(
                musicSnippet: gene1.musicSnippet.mergeNotePassagesRhythmically(
                    firstWeight: gene1.fitness / 100.0,
                    chanceOfRest: self.compositionWeights.chanceOfRest,
                    secondSnippet: gene2.musicSnippet,
                    numberOfBeats: Double(self.timeSig.numberOfBeats)), chord: themeGenes[0].chord, fitness: 0.0)
            returnThemes.append(newGene1)
            returnThemes.append(newGene2)
        }
        return returnThemes
    }
    
    //  Performs a permutation on ~1/8 genes
    private func mutationForThemes(themeGenes: [MainThemeGene]) -> [MainThemeGene] {
        var returnThemes = [MainThemeGene]()
        var bitMask = [Bool]()
        for _ in 0..<self.numberOfGenes {
            let random = Double.random()
            if random < 0.25 {
                bitMask.append(true)
            } else {
                bitMask.append(false)
            }
        }
        
        for i in 0..<themeGenes.count {
            var newThemeGene = MainThemeGene(musicSnippet: themeGenes[i].musicSnippet, chord: themeGenes[i].chord, fitness: themeGenes[i].fitness)
            if bitMask[i] {
                newThemeGene.musicSnippet = self.getSnippetWithRandomPermutation(newThemeGene.musicSnippet, chord: themeGenes[i].chord)
            }
            returnThemes.append(newThemeGene)
        }
        return returnThemes
    }
    
    //  Returns the highest fitness gene
    private func getBestFitThemeGene(themeGenes: [MainThemeGene]) -> MainThemeGene {
        var bestFit = 0.0
        var returnGene: MainThemeGene!
        for themeGene in themeGenes {
            if themeGene.fitness > bestFit {
                bestFit = themeGene.fitness
                returnGene = themeGene
            }
        }
        return returnGene
    }
    
    
    
    //  MARK: - COMPOSITIONAL METHODS: Instrument and chord setup
    //  Set the instruments for each part
    private func setInstrumentPresets() -> [(preset: UInt8, minNote: UInt8, maxNote: UInt8)] {
        var presets = [(preset: UInt8, minNote: UInt8, maxNote: UInt8)]()
        var baseNote: UInt8 = 92
        for _ in 0..<self.numberOfParts {
            let minNote = baseNote - UInt8(Int.random(10...20))
            let maxNote = baseNote + UInt8(Int.random(10...20))
            let randomPreset:UInt8 = presetList[Int.random(0..<presetList.count)]
            //            while presets.contains(randomPreset) {
            //                randomPreset = presetList[Int.random(0..<presetList.count)]
            //            }
            presets.append((preset: randomPreset, minNote: minNote, maxNote: maxNote))
            if baseNote > 20 {
                baseNote = baseNote - 18
            }
        }
        return presets
    }
    
    //  Generate the chord progressions
    private func generateChordProgressions()
    {
        self.chords = [Chord]()
        let numberOfProgressions = Int.random(2...self.maxChordProgressions)
        for _ in 0..<numberOfProgressions {
            var chordProgIndex = 0
            let randomDbl = Double.random()
            while chordProgressionCDF[chordProgIndex].weight < randomDbl {
                chordProgIndex++
            }
            
            self.chords.appendContentsOf(self.musicDataSet.chordProgressions[chordProgIndex].chords)
        }
    }
    
    //  MARK: - COMPOSITIONAL METHODS: Part creation
    
    //  Creates a new part based on weights and other criteria
    func composeNewPartWithChannel(partNum: Int, startingVelocity: UInt8, var numberOfMeasures: Int, presets: [(preset: UInt8, minNote: UInt8, maxNote: UInt8)]) -> (part: MusicPart, numberOfMeasures: Int)
    {
        let randomPreset = presets[partNum]
        var measures = [MusicMeasure]()
        var timeOffset: MusicTimeStamp = 0.0
        numberOfMeasures = 0
        let newSnippet = self.createNewMotive(self.mainTheme, chord: self.chords[0])
        
        //  Set the starting velocity (Each measure will be passed the last velocity to produce smoother dynamics)
        var currentVelocity = startingVelocity
        
        for chord in chords {
            
            numberOfMeasures++
            
            if Double.random() > self.compositionWeights.chanceOfRest
            {
                let newMeasure = self.generateMeasureForChord(
                    channel: partNum,
                    chord: chord,
                    currentVelocity: currentVelocity,
                    musicSnippet: newSnippet,
                    startTimeStamp: timeOffset,
                    minNote: randomPreset.minNote,
                    maxNote: randomPreset.maxNote)
                
                currentVelocity = newMeasure.lastVelocity
                
                measures.append(newMeasure.measure)
            }
            else
            {
                measures.append(MusicMeasure(tempo: self.tempo, timeSignature: self.timeSig, firstBeatTimeStamp: timeOffset, notes: [], chord: chord))  //  Generate an empty measure
            }
            
            timeOffset = timeOffset + MusicTimeStamp(timeSig.numberOfBeats)
            
        }
        var measureIndex = measures.count - 1
        while measures[measureIndex].notes.count == 0 {
            measureIndex--
        }
        measures.append(self.generateEndingMeasureForChord(
            chords[0],
            channel: partNum,
            startTimeStamp: timeOffset,
            previousNote: measures[measureIndex].notes.last!,
            currentVelocity: currentVelocity,
            minNote: presets[partNum].minNote,
            maxNote: presets[partNum].maxNote))
        numberOfMeasures++
        let newPart = MusicPart(measures: measures, preset: randomPreset)
        newPart.checkAndCorrectRange(UInt8(partNum))
        newPart.smoothIntervalsBetweenMeasures(NOTE_MAX_LEAP)
        newPart.smoothDynamics(VELOCITY_MAX_CHANGE)
        newPart.checkAndCorrectMinimumVelocity()
        return (newPart, numberOfMeasures)
    }
    
    //  Creates a single measure
    private func generateMeasureForChord(
        channel channel: Int,
        chord: Chord,
        currentVelocity: UInt8,
        musicSnippet: MusicSnippet,
        startTimeStamp: MusicTimeStamp,
        minNote: UInt8,
        maxNote: UInt8) -> (measure: MusicMeasure, lastVelocity: UInt8)
    {
        let newMergeSnippet = self.createNewMotive(musicSnippet, chord: chord)
        
        let snippet1 = self.getSnippetWithRandomPermutation(newMergeSnippet, chord: chord)
        snippet1.transposeToChord(chord: chord, keyOffset: 0)
        var nextVel = currentVelocity
        for note in snippet1.musicNoteEvents {
            note.timeStamp = note.timeStamp + startTimeStamp
            note.midiNoteMess.channel = UInt8(channel)
            //  Transpose the note to fit in this part's range
            while note.midiNoteMess.note < minNote {
                note.midiNoteMess.note = note.midiNoteMess.note + 12
            }
            
            while note.midiNoteMess.note > maxNote {
                note.midiNoteMess.note = note.midiNoteMess.note - 12
            }
            // Set the note's velocity then increment or decrement it
            note.midiNoteMess.velocity = nextVel
            if nextVel < 25 {
                nextVel = UInt8(Int(nextVel) + Int.random(0...10))
            } else if nextVel > 90 {
                nextVel = UInt8(Int(nextVel) + Int.random(-10...3))
            } else {
                nextVel = UInt8(Int(nextVel) + Int.random(-5...5))
            }
        }
        return (MusicMeasure(tempo: tempo, timeSignature: timeSig, firstBeatTimeStamp: startTimeStamp, notes: snippet1.musicNoteEvents, chord: chord), nextVel)
    }
    
    
    //  Generates the final measure. For now, it just adds held out notes in the tonic chord
    private func generateEndingMeasureForChord(chord: Chord, channel: Int, startTimeStamp: MusicTimeStamp, previousNote: MusicNote, currentVelocity: UInt8, minNote: UInt8, maxNote: UInt8) -> MusicMeasure
    {
        let chordController = ChordController()
        let chordNotes = chordController.getChordNotesForChord(chord)
        //        let note = chordNotes![Int.random(0..<chordNotes!.count)]
        //        if previousNote != nil {
        let prevNoteVal = previousNote.noteValue
        var distanceFromChordNote = 127
        var currentChordNote = UInt8(250)
        for chordNote in chordNotes! {
            let currentNoteDistance = Int(prevNoteVal) - Int(chordNote.noteValue)
            if abs(currentNoteDistance) < abs(distanceFromChordNote) {
                distanceFromChordNote = currentNoteDistance
                currentChordNote = chordNote.noteValue
            }
        }
        if !self.usedChordNoteValues.contains(currentChordNote) {
            self.usedChordNoteValues.append(currentChordNote)
        } else {
            if chordNotes!.count != self.usedChordNoteValues.count {
                for chordNote in chordNotes! {
                    if !self.usedChordNoteValues.contains(chordNote.noteValue) {
                        distanceFromChordNote = Int(prevNoteVal) - Int(chordNote.noteValue)
                    }
                }
            }
        }
        let newNote = previousNote.getNoteCopy()
        newNote.midiNoteMess.note = UInt8(Int(newNote.midiNoteMess.note) - distanceFromChordNote)
        newNote.midiNoteMess.velocity = currentVelocity
        newNote.midiNoteMess.duration = Float32(self.timeSig.numberOfBeats)
        newNote.timeStamp = startTimeStamp
        while newNote.midiNoteMess.note <= minNote {
            newNote.midiNoteMess.note = newNote.midiNoteMess.note + 12
        }
        
        while newNote.midiNoteMess.note >= maxNote {
            newNote.midiNoteMess.note = newNote.midiNoteMess.note - 12
        }
        
        return MusicMeasure(tempo: tempo, timeSignature: self.timeSig, firstBeatTimeStamp: startTimeStamp, notes: [newNote], chord: chord)
    }
    
    //  MARK: - COMPOSITIONAL METHODS: Permutation/Variation
    
    //  Generates a random permutation based on weights
    private func getSnippetWithRandomPermutation(musicSnippet: MusicSnippet, chord: Chord) -> MusicSnippet {
        var newSnippet = MusicSnippet(musicSnippet: musicSnippet)
        var permuteNum = 0
        let rand = Double.random()
        while (rand > self.compositionWeights.permutationWeights[permuteNum]) {
            permuteNum++
        }
        
        switch permuteNum {
        case 0:
            //  Diatonic inversion
            newSnippet.applyDiatonicInversion(pivotNoteNumber: musicSnippet.musicNoteEvents[0].midiNoteMess.note)
        case 1:
            //  Reverse the notes, keep the rhythm
            newSnippet.applyMelodicRetrograde()
        case 2:
            //  Reverse the notes and the rhythm
            newSnippet.applyRetrograde()
        case 3:
            //  Reverse the rhythm, keep the notes
            newSnippet.applyRhythmicRetrograde()
        case 4:
            //  Apply both retrograde AND inversion
            newSnippet.applyRetrograde()
            newSnippet.applyDiatonicInversion(pivotNoteNumber: newSnippet.musicNoteEvents[0].midiNoteMess.note)
        case 5:
            //  Generate a brand new snippet
            newSnippet = self.createNewMotive(newSnippet, chord: chord)
        case 6:
            //  Change the articulation for the snippet
            let start = Int.random(0..<newSnippet.count)
            let end = Int.random(start..<newSnippet.count)
            var articulationType:Articulation.RawValue = 0
            while(Double.random() > self.compositionWeights.articulationWeights[articulationType]) {
                articulationType++
            }
            let artic = Articulation(rawValue: articulationType)
            newSnippet.applyArticulation(startIndex: start, endIndex: end, articulation: artic!)
        default:
            //  Return the main theme
            if self.mainTheme.musicNoteEvents.count != 0 {
                newSnippet = MusicSnippet(musicSnippet: self.mainTheme)
            }
        }
        
        newSnippet.transposeToChord(chord: chord, keyOffset: 0)
        return newSnippet
    }
    
    /**
     Apply a random permutation to a measure and return a fresh copy.
     
     - measure: `MusicMeasure`
     - Returns: `MusicMeasure`
     */
    private func applyRandomPermutationToMeasure(measure: MusicMeasure) -> MusicMeasure {
        let newMeasure = MusicMeasure(musicMeasure: measure)
        let musicSnippet = self.getSnippetWithRandomPermutation(MusicSnippet(notes: newMeasure.notes), chord: measure.chord)
        for note in musicSnippet.musicNoteEvents {
            note.timeStamp = note.timeStamp + measure.firstBeatTimeStamp
        }
        newMeasure.notes = musicSnippet.musicNoteEvents
        return newMeasure
    }
    
    //  MARK: - COMPOSITIONAL METHODS: Random name generation
    
    private func getRandomName() -> String {
        var titleWord1 = ""
        var titleWord2 = ""
        if let wordsFilePath = NSBundle.mainBundle().pathForResource("words", ofType: nil) {
            do {
                let wordsString = try String(contentsOfFile: wordsFilePath)
                
                let wordLines = wordsString.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
                
                titleWord1 = wordLines[Int(arc4random_uniform(UInt32(wordLines.count)))]
                titleWord1.replaceRange(titleWord1.startIndex...titleWord1.startIndex, with: String(titleWord1[titleWord1.startIndex]).capitalizedString)
                titleWord2 = wordLines[Int(arc4random_uniform(UInt32(wordLines.count)))]
                titleWord2.replaceRange(titleWord2.startIndex...titleWord2.startIndex, with: String(titleWord2[titleWord2.startIndex]).capitalizedString)
                
                //                print(randomLine)
                
            } catch { // contentsOfFile throws an error
                print("Error: \(error)")
            }
        }
        return "\(titleWord1) \(titleWord2), opus \(self.musicDataSet.compositions.count)"
    }
    
    //  MARK: - Utility functions
    private func sendDataNotification(dataString: String) {
        var userInfo = [String: String]()
        userInfo["Data String"] = dataString
        NSNotificationCenter.defaultCenter().postNotificationName("ComposerControllerData", object: self, userInfo: userInfo)
        
    }
    
    func recalculateFitnessForComposition(composition: MusicComposition) -> (fitness: Double, silenceFitness: Double, chordDissFitness: Double, noteDissFitness: Double, dynamicsFitness: Double, rhythmicFitness: Double) {
        let results = self.checkIndividualComposition(composition)
        return (results.fitness, results.silenceFitness, results.chordDissFitness, results.noteDissFitness, results.dynamicsFitness, results.rhythmicFitness)
    }
    
    private func createBitmask(numberOfBits: Int, chanceOfBit: Double) -> [Bool] {
        var bitMask = [Bool]()
        for _ in 0..<numberOfBits {
            let random = Double.random()
            if random < chanceOfBit {
                bitMask.append(true)
            } else {
                bitMask.append(false)
            }
        }
        return bitMask
    }
}


//  This is used for checking note-against-note intervals
struct NoteSpan {
    var part: Int!
    var noteValue: UInt8!
    var start: MusicTimeStamp!
    var end: MusicTimeStamp!
    
    var description: String {
        let returnString = String(format: "Part: %d\tnote: %d\tstart time: %.2f\tend time: %.2f", part, noteValue, start, end)
        return returnString
    }
}
