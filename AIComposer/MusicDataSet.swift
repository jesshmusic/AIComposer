//
//  MusicDataSet.swift
//  AIComposer
//
//  This is a very preliminary version of a data structure to generate and store music snippets
//
//  Created by Jess Hendricks on 10/27/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import Cocoa
import AudioToolbox

enum Articulation: Int {
    case Accent
    case Staccato
    case Staccatissimo
    case Marcato
    case Tenuto
}

class MusicDataSet: NSObject, NSCoding {
    let midiManager = MIDIManager.sharedInstance
    
    //  This will hold an array (for now) of transposable music ideas generated
    //  from music notes that occur in the same measure and channel
    var musicSnippets: [MusicSnippet]!
    var chordProgressions = [MusicChordProgression]()
    var timeResolution: UInt32!
    var compositions: [MusicComposition]!
//    var compositionWeights = CompositionWeights()
    var snippetCount = 0
    
    let chordsSet = [["C", "C", "G", "G"], ["C", "C", "G", "G"], ["C", "C", "G", "G"], ["C", "C", "G", "G"],
        ["C", "C", "F", "F", "G", "G"], ["C", "C", "F", "F", "G", "G"],
        ["C", "Am", "C", "Am", "C", "Am", "G", "G"],
        ["C", "C", "Am", "Am", "Dm", "Dm", "G", "G"],
        ["C", "G", "Dm", "Am", "Em", "Bdim", "F"],
        ["C", "Am", "G", "C", "C", "B", "Em", "Em", "D", "G", "G"],
        ["G", "D", "G", "Bm", "C", "D", "G"]
    ]
    /*
    *   Initializes the data structure.
    */
    override init() {
        self.musicSnippets = [MusicSnippet]()
        self.compositions = [MusicComposition]()
        self.timeResolution = 480
        // For testing:
        self.chordProgressions = [MusicChordProgression]()
        super.init()
        for chordProg in self.chordsSet {
            let newProgression = MusicChordProgression()
            for chord in chordProg {
                newProgression.addChord(chord)
            }
            self.addChordProgression(newProgression)
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init()
        
        self.musicSnippets = aDecoder.decodeObjectForKey("MusicSnippets") as! [MusicSnippet]
        if aDecoder.decodeInt32ForKey("Time Resolution") != 0 {
            self.timeResolution = UInt32(aDecoder.decodeInt32ForKey("Time Resolution"))
        } else {
            self.timeResolution = 480
        }
        if aDecoder.decodeObjectForKey("Chord Progressions") != nil {
            let chordProgs = aDecoder.decodeObjectForKey("Chord Progressions") as! [MusicChordProgression]      // To ensure old files without weights are compatible
            for chordProg in chordProgs {
                self.addChordProgression(chordProg)
            }
        } else {
            self.chordProgressions = [MusicChordProgression]()
        }
        self.compositions = aDecoder.decodeObjectForKey("Compositions") as! [MusicComposition]
        self.snippetCount = self.musicSnippets.count
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.musicSnippets, forKey: "MusicSnippets")
        aCoder.encodeObject(self.chordProgressions, forKey: "Chord Progressions")
        aCoder.encodeInt32(Int32(self.timeResolution), forKey: "Time Resolution")
        aCoder.encodeObject(self.compositions, forKey: "Compositions")
    }
    
    /*
    *   Calls the MIDIFileParser to load a MIDI file.
    *   For now, its is best if the MIDI file has only a short snippet, or musical idea.
    */
    func parseMusicSnippetsFromMIDIFile(filePathString: String) {
        let newMIDIData = self.midiManager.loadMIDIFile(filePathString)
        self.timeResolution = newMIDIData.timeResolution
        var musicNotes = [MusicNote]()
        let eventMarkers = newMIDIData.eventMarkers
        for nextEvent in newMIDIData.midiNotes {
            //            let note = MusicNote(noteMessage: nextEvent.midiNoteMessage, barBeatTime: nextEvent.barBeatTime, timeStamp: nextEvent.timeStamp)
            let note = MusicNote(noteMessage: nextEvent.midiNoteMessage, timeStamp: nextEvent.timeStamp)
            musicNotes.append(note)
        }
        self.musicSnippets.appendContentsOf(self.generateSnippetsFromMusicNotes(musicNotes, eventMarkers: eventMarkers, numberOfBeats: Double(newMIDIData.numberOfBeats)))
    }
    
    /*
    *   Calls the MIDIFileParser to load a MIDI file.
    *   For now, its is best if the MIDI file has only a short snippet, or musical idea.
    */
    func parseChordProgressionsFromMIDIFile(filePathString: String) {
        let newMIDIData = self.midiManager.loadMIDIFile(filePathString)
        var musicNotes = [MusicNote]()
        let eventMarkers = newMIDIData.eventMarkers
        for nextEvent in newMIDIData.midiNotes {
            let note = MusicNote(noteMessage: nextEvent.midiNoteMessage, timeStamp: nextEvent.timeStamp)
            musicNotes.append(note)
        }
        self.generateProgressionsFromMusicNotes(musicNotes, eventMarkers: eventMarkers)
    }
    
    /*
    *   Returns generated MusicSnippets from an array of MusicNotes. Event markers (CC20) delineate where to separate snippets.
    *   If there are no event markers, then it will divide based on number of beats.
    */
    private func generateSnippetsFromMusicNotes(musicNotes: [MusicNote], eventMarkers: [MusicTimeStamp], var numberOfBeats: Double) -> [MusicSnippet] {
        var musSnippets = [MusicSnippet]()
        numberOfBeats = numberOfBeats == 0 ? 4.0 : numberOfBeats
        if !musicNotes.isEmpty {
            var nextSnippet: MusicSnippet!
            nextSnippet = MusicSnippet()
            var currentTimeStamp = MusicTimeStamp(0.0)
            var i = 0
            let totalBeats = ceil(musicNotes.last!.timeStamp) + ceil(musicNotes.last!.timeStamp % numberOfBeats) + MusicTimeStamp(1.0)
            var nextTimestamp = musicNotes[0].timeStamp
            while currentTimeStamp < totalBeats {
                while nextTimestamp < currentTimeStamp {
                    if i + 1 < musicNotes.count {
                        nextTimestamp = musicNotes[i+1].timeStamp
                    }
                    nextSnippet.addMusicNote(musicNotes[i])
                    i++
                    if i == musicNotes.count {
                        currentTimeStamp = totalBeats
                        break
                    }
                }
                currentTimeStamp = currentTimeStamp + numberOfBeats
                if nextSnippet.count != 0 {
                    nextSnippet.zeroTransposeMusicSnippet()
                    musSnippets.append(nextSnippet)
                    nextSnippet = MusicSnippet()
                }
            }
        }
        return musSnippets
    }
    
    /*
    *   Returns chord progressions from an array of MusicNotes.
    *   Event markers (CC20) delineate where phrases end.
    *   Event markers are required.
    */
    private func generateProgressionsFromMusicNotes(musicNotes: [MusicNote], eventMarkers: [MusicTimeStamp]) {
        if !musicNotes.isEmpty {
            var nextSnippet: MusicSnippet!
            if eventMarkers.count > 0 {
                var nextNote = musicNotes[0].getNoteCopy()
                var noteIndex = 0
                var timeStamp = 0.0
                for event in eventMarkers {
                    let chordProg = MusicChordProgression()
                    timeStamp = Double(nextNote.timeStamp)
                    while nextNote.timeStamp < event && noteIndex < musicNotes.count {
                        nextSnippet = MusicSnippet()
                        while abs(nextNote.timeStamp - timeStamp) < 0.05 {
                            nextSnippet.addMusicNote(nextNote)
                            noteIndex++
                            if musicNotes.count <= noteIndex {
                                break
                            } else {
                                nextNote = musicNotes[noteIndex].getNoteCopy()
                            }
                        }
                        timeStamp = nextNote.timeStamp
                        if nextSnippet.count > 0 {
                            nextSnippet.zeroTransposeMusicSnippet()
                            if nextSnippet.possibleChords.count == 1 {
                                chordProg.addChord(nextSnippet.possibleChords[0].name)
                            } else if nextSnippet.possibleChords.count > 1 {
                                var bestChordWeight = nextSnippet.possibleChords[0].weight
                                var bestChord = nextSnippet.possibleChords[0].name
                                for chord in nextSnippet.possibleChords {
                                    if chord.weight > bestChordWeight {
                                        bestChordWeight = chord.weight
                                        bestChord = chord.name
                                    }
                                }
                                chordProg.addChord(bestChord)
                            } else {
                                break
                            }
                        }
                    }
                    self.addChordProgression(chordProg)
                }
            }
        }
    }
    
    /**
     Add a new chord progression to the data set
     */
    func addChordProgression(chordProgression: MusicChordProgression) {
        if self.chordProgressions.contains(chordProgression) {
            self.chordProgressions[self.chordProgressions.indexOf(chordProgression)!].incrementNumberOfOccurences()
        } else {
            self.chordProgressions.append(chordProgression)
        }
        self.recalculateAllChordProgressionWeights()
    }
    
    /**
     Add a new chord progression to the data set
     */
    func removeChordProgression(chordProgressionIndex: Int) {
        self.chordProgressions.removeAtIndex(chordProgressionIndex)
        self.recalculateAllChordProgressionWeights()
    }
    
     /*
     *   Deletes all music snippets from the data structure
     */
    func clearAllData() {
        self.musicSnippets.removeAll()
        self.chordProgressions.removeAll()
    }
    
    func createMIDIFileFromDataSet(filePathString: String) {
        let newSeq = self.getMusicSequenceFromData()
        self.midiManager.createMIDIFile(fileName: filePathString, sequence: newSeq)
    }
    
    /*
    *   Recalculates all chord progression weights
    */
    private func recalculateAllChordProgressionWeights() {
        var totalOccurences = 0.0
        for chordProg in self.chordProgressions {
            totalOccurences = totalOccurences + Double(chordProg.numberOfOccurences)
        }
        for chordProg in self.chordProgressions {
            chordProg.updateWeight(Double(chordProg.numberOfOccurences) / totalOccurences)
        }
    }
    
    /*
    *   Roughly converts all of the MusicSnippets into a midi file.
    */
    private func getMusicSequenceFromData() -> MusicSequence {
        var newSeq = MusicSequence()
        NewMusicSequence(&newSeq)
        MusicSequenceSetSequenceType(newSeq, MusicSequenceType.Beats)
        var tempoTrack = MusicTrack()
        MusicSequenceGetTempoTrack(newSeq, &tempoTrack)
        MusicTrackNewExtendedTempoEvent(tempoTrack, 0, 120)
        var musicTrack = MusicTrack()
        MusicSequenceNewTrack(newSeq, &musicTrack)
        var currentTimeStamp:MusicTimeStamp = 0
        var previousTimeStamp: MusicTimeStamp = 0
        var previousDuration: Float32 = 0
        for nextMusicSnippet in self.musicSnippets {
            for nextMusicEvent in nextMusicSnippet.musicNoteEvents {
                if nextMusicEvent.timeStamp > currentTimeStamp {
                    currentTimeStamp = previousTimeStamp + MusicTimeStamp(previousDuration)
                }
                let tStamp = nextMusicEvent.timeStamp.advancedBy(currentTimeStamp)
                var midiNoteMessage = MIDINoteMessage()
                midiNoteMessage.channel = nextMusicEvent.midiNoteMess.channel
                midiNoteMessage.duration = nextMusicEvent.midiNoteMess.duration
                midiNoteMessage.note = nextMusicEvent.midiNoteMess.note
                midiNoteMessage.releaseVelocity = nextMusicEvent.midiNoteMess.releaseVelocity
                midiNoteMessage.velocity = nextMusicEvent.midiNoteMess.velocity
                MusicTrackNewMIDINoteEvent(musicTrack, tStamp, &midiNoteMessage)
                previousDuration = midiNoteMessage.duration
                previousTimeStamp = tStamp
            }
        }
        return newSeq
    }
    
    //  Same as 'toString()' in Java
    func getDataString() -> String {
        var descriptString = "Music Data Set: "
        descriptString = descriptString + "\nSnippets:(\(self.musicSnippets.count)) \n"
        for nextSnippet in self.musicSnippets {
            descriptString = descriptString + "\(nextSnippet.toString)\n"
        }
        return descriptString
    }
    
    
}
