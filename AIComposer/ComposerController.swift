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
//private let ComposerControllerInstance = ComposerController()

struct CompositionGene {
    let composition: MusicComposition!
    var fitness = 0.0
    var silenceFitness = 0.0
    var chordFitness = 0.0
    var noteFitness = 0.0
    var dynamicsFitness = 0.0
    var rhythmicFitness = 0.0
}

struct MainThemeGene {
    var musicSnippet: MusicSnippet!
    let chord: Chord!
    var fitness = 0.0
}

struct DesiredResults {
    var silenceRatio = 0.125
    var chordDissonanceRatio = 0.5
    var noteDissonanceRatio = 0.1
    var dynamicsResult = 0.1
    var rhythmicVariety = 0.3
    
    var silenceScore = 20.0
    var chordDissScore = 35.0
    var noteDissScore = 15.0
    var dynamicScore = 5.0
    var rhythmicScore = 25.0
    
    //  This would make a perfect score 100.0
    
    var marginForScoring = 0.05
    var marginForScoringDynRange = 5
}

class ComposerController: NSObject {
    
    let midiManager = MIDIManager.sharedInstance
    
    //  MARK: Music Data
    var musicDataSet:MusicDataSet!
    var compositionGenes: [CompositionGene]!
    var chords: [Chord]!
    var chordProgressionCDF = [(weight: Double, chordProg: MusicChordProgression)]()
    var tempo: Float64 = 120
    let minTempo = 60
    let maxTempo = 140
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
    //    class var sharedInstance:ComposerController {
    //        return ComposerControllerInstance
    //    }
    
    init(musicDataSet: MusicDataSet) {
        self.musicDataSet = musicDataSet
    }
    
    //  MARK: - Main composition creation method called to run the genetic algorithm
    /**
    Composes a new piece of music.
    */
    func createComposition() -> MusicDataSet {
        
        
        if self.musicDataSet.musicSnippets.count != 0 {
            
            // Initialize the chord progression cumulative distribution function
            var chordProgWeight = 0.0
            for chordProg in self.musicDataSet.chordProgressions {
                chordProgWeight = chordProgWeight + chordProg.weight
                self.chordProgressionCDF.append((chordProgWeight, chordProg))
            }
            
            self.initializeCompositions()        //  Initialization
            var currentGeneration = 0
            var bestFitness = 0.0
            self.checkCompositions()       //  First Check
            for compGene in self.compositionGenes {
                if compGene.fitness > bestFitness {
                    bestFitness = compGene.fitness
                }
            }
            //  Genetic processes
            //  TODO:   Implement the genetic algorithm
            while bestFitness < fitnessGoal
            {
                if currentGeneration > maxAttempts {
                    break
                }
                self.selectFitCompositions()                            //  Selection
                self.crossoverCompositions()                            //  Crossover
                self.mutateCompositions()                               //  Mutation
                self.checkCompositions()                                //  First Check
                
                currentGeneration++
            }
            self.musicDataSet.compositions.append(self.getCompositionWithBestFitness())
        } else {
            self.sendDataNotification("FAIL. Please load music data.")
        }
        var bestFitness = 0.0
        for compGene in self.compositionGenes {
            if compGene.fitness > bestFitness {
                bestFitness = compGene.fitness
            }
            dispatch_async(dispatch_get_main_queue()) {
                self.sendDataNotification("\t\t compGene - \(compGene.composition.name)... score: \(compGene.fitness)")
            }
        }
        dispatch_async(dispatch_get_main_queue()) {
            self.sendDataNotification("\n\n\nCOMPLETE, fitness score = \(bestFitness)")
        }
        return self.musicDataSet
    }
    //  MARK: - GENETIC ALGORITHM methods
    
    //  Initialization
    private func initializeCompositions()
    {
        self.sendDataNotification("Initializing \(self.numberOfGenes) compositions...")
        let randomName = self.getRandomName()           //  This is for fun.
        self.compositionGenes = [CompositionGene]()
        let presets = self.setInstrumentPresets()
        self.tempo = Float64(Int.random(self.minTempo...self.maxTempo))
        self.generateChordProgressions()
        self.createMainTheme(self.chords[0])  //  All genes will be based on this theme.
        for _ in 0..<self.numberOfGenes {
            
            
            var parts = [MusicPart]()
            var numberOfMeasures = 0
            for partNum in 0..<4 {
                
                let newPart = self.composeNewPartWithChannel(partNum, numberOfMeasures: numberOfMeasures, presets: presets)
                
                if newPart.numberOfMeasures > numberOfMeasures {
                    numberOfMeasures = newPart.numberOfMeasures
                }
                parts.append(newPart.part)
            }
            let newCompositionGene = CompositionGene(
                composition: MusicComposition(name: randomName, musicParts: parts, numberOfMeasures: numberOfMeasures),
                fitness: 0.0,
                silenceFitness: 0.0,
                chordFitness: 0.0,
                noteFitness: 0.0,
                dynamicsFitness: 0.0,
                rhythmicFitness: 0.0)
            self.compositionGenes.append(newCompositionGene)
        }
        self.sendDataNotification("Initialization complete.")
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
            var dynamicsResult = 0.0
            var rhythmicResult = 0.0
            
            silenceRatio = self.checkSilenceRatio(compGene.composition)
            let dissCheck = self.checkDissonanceRatio(compGene.composition)
            chordDissonanceRatio = dissCheck.chordDissonanceRatio
            noteDissonanceRatio = dissCheck.noteDissonanceRatio
            dynamicsResult = self.checkDynamicSmoothness(compGene.composition)
            rhythmicResult = self.checkRhythmicVariety(compGene.composition)
            
            var silenceScore = 0.0
            var chordDissScore = 0.0
            var noteDissScore = 0.0
            var dynamicsScore = 0.0
            var rhythmicScore = 0.0
            if abs(silenceRatio - self.desiredResults.silenceRatio) < self.desiredResults.marginForScoring {
                silenceScore = (self.desiredResults.silenceScore / silenceRatio) * self.desiredResults.silenceScore
                if silenceScore > self.desiredResults.silenceScore {
                    silenceScore = self.desiredResults.silenceScore - (silenceScore % self.desiredResults.silenceScore)
                }
            }
            compGene.composition.silenceFitness = silenceScore
            if abs(chordDissonanceRatio - self.desiredResults.chordDissonanceRatio) < self.desiredResults.marginForScoring {
                chordDissScore = (self.desiredResults.chordDissonanceRatio / chordDissonanceRatio) * self.desiredResults.chordDissScore
                if chordDissScore > self.desiredResults.chordDissScore {
                    chordDissScore = self.desiredResults.chordDissScore - (chordDissScore % self.desiredResults.chordDissScore)
                }
            }
            compGene.composition.chordFitness = chordDissScore
            if abs(noteDissonanceRatio - self.desiredResults.noteDissonanceRatio) < self.desiredResults.marginForScoring {
                noteDissScore = (self.desiredResults.noteDissonanceRatio / noteDissonanceRatio) * self.desiredResults.noteDissScore
                if noteDissScore > self.desiredResults.noteDissScore {
                    noteDissScore = self.desiredResults.noteDissScore - (noteDissScore % self.desiredResults.noteDissScore)
                }
            }
            compGene.composition.noteFitness = noteDissScore
            if abs(dynamicsResult - self.desiredResults.dynamicsResult) < self.desiredResults.marginForScoring {
                dynamicsScore = (self.desiredResults.dynamicsResult / dynamicsResult) * self.desiredResults.dynamicScore
                if dynamicsScore > self.desiredResults.dynamicScore {
                    dynamicsScore = self.desiredResults.dynamicScore - (dynamicsScore % self.desiredResults.dynamicScore)
                }
            }
            compGene.composition.dynamicsFitness = dynamicsScore
            rhythmicScore = self.desiredResults.rhythmicScore * rhythmicResult
            //            if abs(rhythmicResult - self.desiredResults.rhythmicVariety) < self.desiredResults.marginForScoring {
            //                rhythmicScore = (self.desiredResults.rhythmicVariety / rhythmicResult) * self.desiredResults.rhythmicScore
            //                if rhythmicScore > self.desiredResults.rhythmicScore {
            //                    rhythmicScore = self.desiredResults.rhythmicScore - (dynamicsScore % self.desiredResults.rhythmicScore)
            //                }
            //            }
            compGene.composition.rhythmicFitness = rhythmicScore
            overallFitness = overallFitness + silenceScore + chordDissScore + noteDissScore + dynamicsScore + rhythmicScore
            
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
        let chordCtrl = ChordController()
        
        //  Check Dissonance against chord in each measure
        var dissonantDuration = 0.0
        var consonantDuration = 0.0
        for i in 0..<comp.numberOfMeasures {
            let chordNotes = chordCtrl.getChordNotesForChord(comp.musicParts[0].measures[0].chord)
            for part in comp.musicParts {
                for note in part.measures[i].notes {
                    let testNote = note.getNoteCopy()
                    testNote.midiNoteMess.note = testNote.noteValue
                    if chordNotes!.contains(testNote) {
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
                            notesInBeat.insert(note.noteValue)
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
    
    private func checkDynamicSmoothness(comp: MusicComposition) -> Double {
        var dynamicsScore = 0.0
        for part in comp.musicParts {
            var totalNotes = 0.0
            for measure in part.measures {
                var totalVelocity = 0
                var previousNoteVelocity = 80
                for note in measure.notes {
                    if (Int(note.midiNoteMess.velocity) - previousNoteVelocity) < 40 {
                        dynamicsScore = dynamicsScore + 0.25
                    }
                    if (Int(note.midiNoteMess.velocity) - previousNoteVelocity) < 20 {
                        dynamicsScore = dynamicsScore + 0.35
                    }
                    if (Int(note.midiNoteMess.velocity) - previousNoteVelocity) < 10 {
                        dynamicsScore = dynamicsScore + 0.4
                    }
                    previousNoteVelocity = Int(note.midiNoteMess.velocity)
                    totalVelocity = totalVelocity + Int(note.midiNoteMess.velocity)
                    totalNotes++
                }
            }
            dynamicsScore = dynamicsScore / totalNotes
        }
        return dynamicsScore
    }
    
    private func checkRhythmicVariety(comp: MusicComposition) -> Double {
        
        var rhythmicVarietyScore = 0.0
        var totalChecks = 0.0
        //  Get the time stamps from the main theme
        var timeStamps = [MusicTimeStamp]()
        for nextNote in self.mainTheme.musicNoteEvents {
            timeStamps.append(nextNote.timeStamp)
        }
        
        for part in comp.musicParts {
            for measure in part.measures {
                totalChecks++
                if measure.notes.count != timeStamps.count {
                    rhythmicVarietyScore++
                }
                let numberOfNotes = min(measure.notes.count, timeStamps.count)
                for i in 0..<numberOfNotes {
                    totalChecks++
                    let musicNoteTimeStamp = (measure.notes[i].timeStamp % MusicTimeStamp(self.timeSig.numberOfBeats))
                    if abs(timeStamps[i] - musicNoteTimeStamp) > 0.02 {
                        rhythmicVarietyScore = rhythmicVarietyScore + 1.0
                    }
                }
            }
        }
        rhythmicVarietyScore = rhythmicVarietyScore / totalChecks
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
        
        dispatch_async(dispatch_get_main_queue()) {
            self.sendDataNotification("Initial main themes generated: Best fitness: \(bestFitness)\n")
        }
        
        var currentGeneration = 0
        while bestFitness <= fitnessGoal / 100.0 {
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
        
        dispatch_async(dispatch_get_main_queue()) {
            self.sendDataNotification("Main theme generated: Best fitness: \(bestFitness)\n")
        }
        self.mainTheme = results.musicSnippet
    }
    
    //  Generates a new MusicSnippet theme
    private func createNewMotive(snippet: MusicSnippet, chord: Chord) -> MusicSnippet {
        var musicSnippet = MusicSnippet()
        let snippetIndex = self.musicDataSet.musicSnippets.indexOf(snippet)
        var randomIndex = Int.random(0..<self.musicDataSet.musicSnippets.count)
        while randomIndex == snippetIndex {
            randomIndex = Int.random(0..<self.musicDataSet.musicSnippets.count)
        }
        let mergeSnippet = MusicSnippet(notes: self.musicDataSet.musicSnippets[randomIndex].musicNoteEvents)
        mergeSnippet.transposeToChord(chord: chord, keyOffset: 0)
        musicSnippet = snippet.mergeNotePassagesRhythmically(
            firstWeight: self.musicDataSet.compositionWeights.mainThemeWeight,
            chanceOfRest: self.musicDataSet.compositionWeights.chanceOfRest,
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
            var totalHalfSteps = 0
            var lowestNote = Int(previousNote.midiNoteMess.note)
            var highestNote = Int(previousNote.midiNoteMess.note)
            var totalDurationsInChord = 0.0
            var totalDurations = 0.0
            let chordNotes = chordCtrl.getChordNotesForChord(themeGene.chord)
            var durationResult = 0.0
            
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
                let testNote = currentNote.getNoteCopy()
                testNote.midiNoteMess.note = testNote.noteValue
                if chordNotes!.contains(testNote) {
                    totalDurationsInChord = totalDurationsInChord + Double(currentNote.midiNoteMess.duration)
                }
                if self.tempo > 130.0 {
                    if currentNote.midiNoteMess.duration >= 0.33 {
                        durationResult = durationResult + 0.2
                    }
                } else if self.tempo < 130.0 && self.tempo > 100.0  {
                    if currentNote.midiNoteMess.duration >= 0.25 {
                        durationResult = durationResult + 0.2
                    }
                } else if self.tempo <= 100.0 && self.tempo > 66.0 {
                    if currentNote.midiNoteMess.duration >= 0.125 {
                        durationResult = durationResult + 0.2
                    }
                } else if self.tempo <= 66.0 {
                    if currentNote.midiNoteMess.duration <= 2.1 {
                        durationResult = durationResult + 0.2
                    }
                } else {
                    durationResult = durationResult + 0.2
                }
                totalDurations = totalDurations + Double(currentNote.midiNoteMess.duration)
                totalHalfSteps = totalHalfSteps + (noteNum - Int(previousNote.midiNoteMess.note))
                
                previousNote = currentNote
            }
            
            let averageLeap = Double(totalHalfSteps / themeGene.musicSnippet.musicNoteEvents.count)
            var leapScore = 0.0
            if averageLeap > 1.0 && averageLeap < 5.0 {
                leapScore = pow(0.125, averageLeap)
            }
            
            let totalRange = Double(highestNote - lowestNote)
            var rangeScore = 0.0
            if totalRange > 4 && totalRange < 16 {
                rangeScore = ((1.0/(2.0 * sqrt(2 * M_PI))) * pow(M_E, ((-pow(totalRange - 10.0, 2))/(2 * 4.0))))
                rangeScore = rangeScore <= 0.125 ? rangeScore : 0.125
            }
            
            
            let ratioOfChordNotes = totalDurationsInChord / totalDurations
            var chordNoteRatioScore = 0.0
            if ratioOfChordNotes >= 0.5 && ratioOfChordNotes < 0.85 {
                chordNoteRatioScore = chordNoteRatioScore + 0.1
            }
            if ratioOfChordNotes >= 0.6 && ratioOfChordNotes < 0.85 {
                chordNoteRatioScore = chordNoteRatioScore + 0.1
            }
            if ratioOfChordNotes >= 0.6 && ratioOfChordNotes < 0.75 {
                chordNoteRatioScore = chordNoteRatioScore + 0.2
            }
            if ratioOfChordNotes >= 0.65 && ratioOfChordNotes < 0.7 {
                chordNoteRatioScore = chordNoteRatioScore + 0.2
            }
            
            let durationScore = durationResult / Double(themeGene.musicSnippet.musicNoteEvents.count)
            
            fitScore = leapScore + rangeScore + chordNoteRatioScore + durationScore
            
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
        self.chords = [Chord]()
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
        let newSnippet = self.createNewMotive(self.mainTheme, chord: self.chords[0])
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
    private func generateMeasureForChord(channel channel: Int, chord: Chord, musicSnippet: MusicSnippet, octaveOffset: Int, startTimeStamp: MusicTimeStamp) -> MusicMeasure
    {
        let newMergeSnippet = self.createNewMotive(musicSnippet, chord: chord)
        let snippet1 = self.getSnippetWithRandomPermutation(newMergeSnippet, chord: chord)
        snippet1.transposeToChord(chord: chord, keyOffset: octaveOffset)
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
    private func generateEndingMeasureForChord(chord: Chord, channel: Int, startTimeStamp: MusicTimeStamp, previousNote: MIDINoteMessage?) -> MusicMeasure
    {
        let chordController = ChordController()
        let chordNotes = chordController.getChordNotesForChord(chord)
        let note = chordNotes![Int.random(0..<chordNotes!.count)]
        if previousNote != nil {
            let octave = Int(previousNote!.note) / 12
            let newNoteNum:Int =  Int(note.midiNoteMess.note) + (octave * 12)
            let midiNote = MIDINoteMessage(channel: UInt8(channel), note: UInt8(newNoteNum), velocity: previousNote!.velocity, releaseVelocity: 0, duration: Float32(self.timeSig.numberOfBeats))
            let newNote = MusicNote(noteMessage: midiNote, timeStamp: startTimeStamp)
            return MusicMeasure(tempo: tempo, timeSignature: self.timeSig, firstBeatTimeStamp: startTimeStamp, notes: [newNote], chord: chord)
        } else {
            let octave = 5
            let newNoteNum:Int =  Int(note.midiNoteMess.note) + (octave * 12)
            let midiNote = MIDINoteMessage(channel: UInt8(channel), note: UInt8(newNoteNum), velocity: 80, releaseVelocity: 0, duration: Float32(self.timeSig.numberOfBeats))
            let newNote = MusicNote(noteMessage: midiNote, timeStamp: startTimeStamp)
            return MusicMeasure(tempo: tempo, timeSignature: self.timeSig, firstBeatTimeStamp: startTimeStamp, notes: [newNote], chord: chord)
        }
    }
    
    //  MARK: - COMPOSITIONAL METHODS: Permutation/Variation
    
    //  Generates a random permutation based on weights
    private func getSnippetWithRandomPermutation(musicSnippet: MusicSnippet, chord: Chord) -> MusicSnippet {
        var newSnippet = MusicSnippet(notes: musicSnippet.musicNoteEvents)
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
            newSnippet = self.createNewMotive(newSnippet, chord: chord)
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
        let musicSnippet = self.getSnippetWithRandomPermutation(MusicSnippet(notes: newMeasure.notes), chord: measure.chord)
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
        //        let randomNames = ["Tapestry No. ", "Viginette No. ", "Evolved No. ", "Fantasy No. ", "Thing No. ", "Epiphany No. "]
        return "\(titleWord1) \(titleWord2)"
    }
    
    //  MARK: - Utility functions
    private func sendDataNotification(dataString: String) {
        var userInfo = [String: String]()
        userInfo["Data String"] = dataString
        NSNotificationCenter.defaultCenter().postNotificationName("ComposerControllerData", object: self, userInfo: userInfo)
        
    }
}
