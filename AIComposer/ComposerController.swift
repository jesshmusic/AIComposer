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

struct MainThemeGene {
    var musicSnippet: MusicSnippet!
    let chord: String!
    var fitness = 0.0
}

struct DesiredResults {
    var silenceRatio = 0.125
    var chordDissonanceRatio = 0.5
    var noteDissonanceRatio = 0.1
    var averageDynamicVariance = 5.0
    var dynamicRange = 65
    var jaggedness = 0.001
    
    var silenceScore = 20.0
    var chordDissScore = 25.0
    var noteDissScore = 25.0
    var dynamicVarScore = 2.5   //  x 4 for each part
    var dynRangeScore = 2.5   //  x 4 for each part
    var jaggednessScore = 2.5   //  x 4 for each part
    
    //  This would make a perfect score 100.0
    
    var marginForScoring = 0.05
    var marginForScoringDynRange = 5
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
    let fitnessGoal = 80.0
    let desiredResults = DesiredResults()
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
        var bestFitness = 0.0
        self.checkCompositions()       //  First Check
        for compGene in self.compositionGenes {
            if compGene.fitness > bestFitness {
                bestFitness = compGene.fitness
            }
        }
        //  Genetic processes
        //  TODO:   Implement the genetic algorithm
        while bestFitness < fitnessGoal && currentAttempt < maxAttempts
        {
            self.selectFitCompositions()                            //  Selection
            self.crossoverCompositions()                            //  Crossover
            self.mutateCompositions()                               //  Mutation
            self.checkCompositions()       //  First Check
            for compGene in self.compositionGenes {
                print("\t\t compGene - \(compGene.composition.name)... score: \(compGene.fitness)")
                if compGene.fitness > bestFitness {
                    bestFitness = compGene.fitness
                }
            }
            print("Attempt \(currentAttempt): best fitness = \(bestFitness)")
            currentAttempt++
        }
        self.musicDataSet.compositions.append(self.getCompositionWithBestFitness())
        print("Complete, fitness score = \(bestFitness)")
        return self.musicDataSet
    }
    //  MARK: - GENETIC ALGORITHM methods
    
    //  Initialization
    private func initializeCompositions()
    {
        let randomName = self.getRandomName()           //  This is for fun.
        self.compositionGenes = [CompositionGene]()
        let presets = self.setInstrumentPresets()
        self.createMainTheme()  //  All genes will be based on this theme.
        for _ in 0..<self.numberOfGenes {
            
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
        //  TODO: Implement selection...
        self.orderGenesByBestFitness()  //  I think this will help getting the most fit genes.
        for compGene in self.compositionGenes {
            
        }
    }
    
    //  Crossover
    //  Should it exchange entire measures for each part, or separate measures in separate parts?
    
    //  Implementation:
    //      Each pair of compositions exchanges measures
    private func crossoverCompositions()
    {
        //  TODO: Implement crossover.
        for compGene in self.compositionGenes {
            
        }
    }
    
    //  Mutation
    //  It might be cool for the algorithm to alter chance of mutation if results do no improve
    private func mutateCompositions()
    {
        //  TODO: Implement Mutation
        for compGene in self.compositionGenes {
            
        }
    }
    
    
    private func checkCompositions()
    {
        //  TODO: checkComposition: Generates a fitness score based on several criteria. (To be determined)
        for compGene in self.compositionGenes {
            var overallFitness = 0.0        //  Using a single result number for now
            var silenceRatio = 0.0
            var chordDissonanceRatio = 0.0
            var noteDissonanceRatio = 0.0
            var dynamicsResults = [(partNumber: Int, averageDynamicVariance: Double, dynamicRange: Int, jaggedness: Double)]()
            silenceRatio = self.checkSilenceRatio(compGene.composition)
            let dissCheck = self.checkDissonanceRatio(compGene.composition)
            chordDissonanceRatio = dissCheck.chordDissonanceRatio
            noteDissonanceRatio = dissCheck.noteDissonanceRatio
            dynamicsResults = self.checkDynamicSmoothness(compGene.composition)
            if abs(silenceRatio - self.desiredResults.silenceRatio) < self.desiredResults.marginForScoring {
                overallFitness = overallFitness + self.desiredResults.silenceScore
            }
            if abs(chordDissonanceRatio - self.desiredResults.chordDissonanceRatio) < self.desiredResults.marginForScoring {
                overallFitness = overallFitness + self.desiredResults.chordDissScore
            }
            if abs(noteDissonanceRatio - self.desiredResults.noteDissonanceRatio) < self.desiredResults.marginForScoring {
                overallFitness = overallFitness + self.desiredResults.noteDissScore
            }
            for i in 0..<4 {
                if abs(dynamicsResults[i].averageDynamicVariance - self.desiredResults.averageDynamicVariance) < self.desiredResults.marginForScoring {
                    overallFitness = overallFitness + self.desiredResults.dynamicVarScore
                }
                if abs(dynamicsResults[i].dynamicRange - self.desiredResults.dynamicRange) < self.desiredResults.marginForScoringDynRange {
                    overallFitness = overallFitness + self.desiredResults.dynRangeScore
                }
                if abs(dynamicsResults[i].jaggedness - self.desiredResults.jaggedness) < self.desiredResults.marginForScoring {
                    overallFitness = overallFitness + self.desiredResults.jaggednessScore
                }
            }
            compGene.composition.fitnessScore = overallFitness
        }
        for i in 0..<self.compositionGenes.count {
            self.compositionGenes[i].fitness = self.compositionGenes[i].composition.fitnessScore
        }
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
    Order genes based on fitness: highest to lowest
    */
    private func orderGenesByBestFitness() {
        self.compositionGenes.sortInPlace({$0.fitness > $1.fitness})
    }
    
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
    
    private func checkDynamicSmoothness(comp: MusicComposition) -> [(partNumber: Int, averageDynamicVariance: Double, dynamicRange: Int, jaggedness: Double)] {
        // TODO: Implement this
        var results = [(partNumber: Int, averageDynamicVariance: Double, dynamicRange: Int, jaggedness: Double)]()
        var partNum = 0
        for part in comp.musicParts {
            var averageVarianceBetweenMeasures = 0.0
            var totalVarianceBetweenMeasures = 0.0
            var previousVelocityAverage = 60
            var lowestVelocity = 255
            var highestVelocity = 0
            var jaggedness = 0.0
            var totalNotes = 0.0
            for measure in part.measures {
                var totalVelocity = 0
                var previousNoteVelocity = 80
                for note in measure.notes {
                    if Int(note.midiNoteMess.velocity) < lowestVelocity {
                        lowestVelocity = Int(note.midiNoteMess.velocity)
                    }
                    if Int(note.midiNoteMess.velocity) > highestVelocity {
                        highestVelocity = Int(note.midiNoteMess.velocity)
                    }
                    if (Int(note.midiNoteMess.velocity) - previousNoteVelocity) > 40 {
                        jaggedness++
                    }
                    previousNoteVelocity = Int(note.midiNoteMess.velocity)
                    totalVelocity = totalVelocity + Int(note.midiNoteMess.velocity)
                    totalNotes++
                }
                if totalVelocity != 0 {
                    let averageVelocity = totalVelocity / measure.notes.count
                    let averageVariance = abs(previousVelocityAverage - averageVelocity)
                    previousVelocityAverage = averageVelocity
                    totalVarianceBetweenMeasures = totalVarianceBetweenMeasures + Double(averageVariance)
                }
            }
            let dynamicRange = highestVelocity - lowestVelocity
            averageVarianceBetweenMeasures = totalVarianceBetweenMeasures / Double(part.measures.count)
            jaggedness = jaggedness / totalNotes
            results.append((partNumber: partNum, averageDynamicVariance: averageVarianceBetweenMeasures, dynamicRange: dynamicRange, jaggedness: jaggedness))
            partNum++
        }
        return results
    }
    
    private func checkThematicVariety(comp: MusicComposition) -> Double {
        // TODO: Implement this (Checking for similarity between measures sounds hard. haha)
        return 0.0
    }
    
    //  MARK: - COMPOSITIONAL METHODS: Main theme generation
    // Creates the main theme for the piece. I'm going to attempt to do this with a genetic algorithm too.
    //  *** REQUIRED ***    There must be more than 1 MusicSnippet.
    private func createMainTheme() {
        var themeGenes = [MainThemeGene]()
        var musicSnippet: MusicSnippet!
        var chord = ""
        let mainSnippetIndex = Int.random(0..<self.musicDataSet.musicSnippets.count)
        if self.musicDataSet.musicSnippets[mainSnippetIndex].getHighestWeightChord().containsString("m") {
            musicSnippet = MusicSnippet(notes: self.musicDataSet.musicSnippets[mainSnippetIndex].musicNoteEvents)
            musicSnippet.transposeToChord("Cm", keyOffset: 0)
            chord = "Cm"
        } else {
            musicSnippet = MusicSnippet(notes: self.musicDataSet.musicSnippets[mainSnippetIndex].musicNoteEvents)
            musicSnippet.transposeToChord("C", keyOffset: 0)
            chord = "C"
        }
        
        //  Initialize
        for _ in 0..<self.numberOfGenes {
            themeGenes.append(MainThemeGene(musicSnippet: self.createNewMotive(self.musicDataSet.musicSnippets[mainSnippetIndex]), chord: chord, fitness: 0.0))
        }
        themeGenes = self.checkThemeFitness(themeGenes)
        var bestFitness = self.getThemeBestFitness(themeGenes)
        var currentGeneration = 0
        while bestFitness <= fitnessGoal && currentGeneration < self.maxAttempts {
            themeGenes = self.selectionForThemes(themeGenes)
            themeGenes = self.crossoverForThemes(themeGenes)
            themeGenes = self.mutationForThemes(themeGenes)
            themeGenes = self.checkThemeFitness(themeGenes)
            bestFitness = self.getThemeBestFitness(themeGenes)
            currentGeneration++
//            print("THEME Generation attempt: \(currentGeneration): Best fitness: \(bestFitness)\n")
//            for theme in themeGenes {
//                print("\tTheme: \(theme.musicSnippet) \tfitness: \(theme.fitness)")
//            }
        }
        let results = self.getBestFitThemeGene(themeGenes)
//        if self.musicDataSet.musicSnippets.count > 1 {
//            for _ in 0..<3 {
//                musicSnippet = self.createNewMotive(self.musicDataSet.musicSnippets[mainSnippetIndex])
//            }
//        } else {
//            musicSnippet = MusicSnippet(notes: self.musicDataSet.musicSnippets[0].musicNoteEvents)
//        }
        self.mainTheme = results.musicSnippet
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
    
    //  Check fitness of new main themes based on differences in range/smoothness of melody, smoothness of velocity, ratio of chord tones
    private func checkThemeFitness(themeGenes: [MainThemeGene]) -> [MainThemeGene] {
        
        let chordCtrl = MusicChord.sharedInstance
        var returnThemes = [MainThemeGene]()
        
        for themeGene in themeGenes {
            var fitScore = 0.0
            var previousNote = themeGene.musicSnippet.musicNoteEvents[0]
            var totalHalfSteps = 0
            var totalVelocityDifference = 0
            var lowestNote = Int(previousNote.midiNoteMess.note)
            var highestNote = Int(previousNote.midiNoteMess.note)
            
            //  Check average leap, total range, and velocity difference
            
            for i in 1..<themeGene.musicSnippet.musicNoteEvents.count {
                let currentNote = themeGene.musicSnippet.musicNoteEvents[i]
                let noteNum = Int(currentNote.midiNoteMess.note)
                if  noteNum > highestNote {
                    highestNote = noteNum
                }
                if noteNum < lowestNote {
                    lowestNote = noteNum
                }
                totalHalfSteps = totalHalfSteps + (noteNum - Int(previousNote.midiNoteMess.note))
                totalVelocityDifference = totalVelocityDifference + (Int(currentNote.midiNoteMess.velocity) - Int(previousNote.midiNoteMess.velocity))
                previousNote = currentNote
            }
            
            let averageLeap = Double(totalHalfSteps / themeGene.musicSnippet.musicNoteEvents.count)
            if averageLeap <= 4 {
                fitScore = fitScore + 0.1
            }
            if averageLeap <= 2 {
                fitScore = fitScore + 0.1
            }
            
            let totalRange = highestNote - lowestNote
            if totalRange > 6 && totalRange < 24 {
                fitScore = fitScore + 0.1
            }
            if totalRange > 12 && totalRange < 18 {
                fitScore = fitScore + 0.1
            }
            
            let averageVelocityChange = Double(totalVelocityDifference / themeGene.musicSnippet.musicNoteEvents.count)
            if averageVelocityChange <= 10 {
                fitScore = fitScore + 0.1
            } else if averageVelocityChange <= 20 && averageVelocityChange > 10 {
                fitScore = fitScore + 0.1
            }
            
            //  Check total duration in chord
            var totalDurationsInChord = 0.0
            var totalDurations = 0.0
            let chordNotes = chordCtrl.chordNotes[themeGene.chord]
            
            for note in themeGene.musicSnippet.musicNoteEvents {
                let noteNumber = Int(note.midiNoteMess.note % 12)
                if chordNotes!.contains(noteNumber) {
                    totalDurationsInChord = totalDurationsInChord + Double(note.midiNoteMess.duration)
                }
                totalDurations = totalDurations + Double(note.midiNoteMess.duration)
            }
            let ratioOfChordNotes = totalDurationsInChord / totalDurations
            if ratioOfChordNotes > 0.5 && ratioOfChordNotes <= 1.0 {
                fitScore = fitScore + 0.2
            }
            if ratioOfChordNotes > 0.6 && ratioOfChordNotes <= 0.8 {
                fitScore = fitScore + 0.2
            }
            
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
                    firstWeight: gene1.fitness,
                    chanceOfRest: self.musicDataSet.compositionWeights.chanceOfRest,
                    secondSnippet: gene2.musicSnippet,
                    numberOfBeats: Double(self.timeSig.numberOfBeats)), chord: themeGenes[0].chord, fitness: 0.0)
            let newGene2 = MainThemeGene(
                musicSnippet: gene1.musicSnippet.mergeNotePassagesRhythmically(
                    firstWeight: gene1.fitness,
                    chanceOfRest: self.musicDataSet.compositionWeights.chanceOfRest,
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
            if Double.random() < 0.125 {
                bitMask.append(true)
            } else {
                bitMask.append(false)
            }
        }
        
        for i in 0..<themeGenes.count {
            var newThemeGene = MainThemeGene(musicSnippet: themeGenes[i].musicSnippet, chord: themeGenes[i].chord, fitness: themeGenes[i].fitness)
            if bitMask[i] {
                newThemeGene.musicSnippet = self.getSnippetWithRandomPermutation(newThemeGene.musicSnippet)
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
        let numberOfProgressions = Int.random(1...4)
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
        if measures[measures.count - 1].notes.count != 0 {
            measures.append(self.generateEndingMeasureForChord(
                chords[0],
                channel: partNum,
                startTimeStamp: timeOffset,
                previousNote: measures[measures.count - 1].notes.last!.midiNoteMess))
        } else {
            measures.append(self.generateEndingMeasureForChord(chords[0], channel: partNum, startTimeStamp: timeOffset, previousNote: nil))
        }
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
    private func generateEndingMeasureForChord(chord: String, channel: Int, startTimeStamp: MusicTimeStamp, previousNote: MIDINoteMessage?) -> MusicMeasure
    {
        let chordController = MusicChord.sharedInstance
        let chordNotes = chordController.chordNotes[chord]
        let noteNumber = chordNotes![Int.random(0..<chordNotes!.count)]
        if previousNote != nil {
            let octave = Int(previousNote!.note) / 12
            let newNoteNum:Int =  noteNumber + (octave * 12)
            let midiNote = MIDINoteMessage(channel: UInt8(channel), note: UInt8(newNoteNum), velocity: previousNote!.velocity, releaseVelocity: 0, duration: Float32(self.timeSig.numberOfBeats))
            let newNote = MusicNote(noteMessage: midiNote, timeStamp: startTimeStamp)
            return MusicMeasure(tempo: tempo, timeSignature: self.timeSig, firstBeatTimeStamp: startTimeStamp, notes: [newNote], chord: chord)
        } else {
            let octave = 5
            let newNoteNum:Int =  noteNumber + (octave * 12)
            let midiNote = MIDINoteMessage(channel: UInt8(channel), note: UInt8(newNoteNum), velocity: 80, releaseVelocity: 0, duration: Float32(self.timeSig.numberOfBeats))
            let newNote = MusicNote(noteMessage: midiNote, timeStamp: startTimeStamp)
            return MusicMeasure(tempo: tempo, timeSignature: self.timeSig, firstBeatTimeStamp: startTimeStamp, notes: [newNote], chord: chord)
        }
    }
    
    //  MARK: - COMPOSITIONAL METHODS: Permutation/Variation
    
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
    
    /**
    Apply a random permutation to a measure and return a fresh copy.
    
    - measure: `MusicMeasure`
    - Returns: `MusicMeasure`
    */
    private func applyRandomPermutationToMeasure(measure: MusicMeasure) -> MusicMeasure {
        let newMeasure = measure.getMeasureCopy()
        let musicSnippet = self.getSnippetWithRandomPermutation(MusicSnippet(notes: newMeasure.notes))
        newMeasure.notes = musicSnippet.musicNoteEvents
        return newMeasure
    }
    
    //  MARK: - COMPOSITIONAL METHODS: Random name generation
    
    private func getRandomName() -> String {
        let randomNames = ["Tapestry No. ", "Viginette No. ", "Evolved No. ", "Fantasy No. ", "Thing No. ", "Epiphany No. "]
        return randomNames[Int.random(0..<randomNames.count)] + "\(Int.random(0..<20))"
    }
}
