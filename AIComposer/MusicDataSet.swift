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

class MusicDataSet: NSObject, NSCoding {
    
    var midiFileParser: MIDIFileParser!
    
    //  This will hold an array (for now) of transposable music ideas generated
    //  from music notes that occur in the same measure and channel
    var musicSnippets: [MusicSnippet]!
    var chordProgressions: [MusicChordProgression]!
    var timeResolution: UInt32!
    
    /*
    *   Initializes the data structure.
    */
    override init() {
        midiFileParser = MIDIFileParser.sharedInstance
        self.musicSnippets = [MusicSnippet]()
        self.timeResolution = 480
        // For testing:
        self.chordProgressions = [MusicChordProgression]()
        super.init()
    }
    
    required init(coder aDecoder: NSCoder) {
        self.musicSnippets = aDecoder.decodeObjectForKey("MusicSnippets") as! [MusicSnippet]
        if aDecoder.decodeInt32ForKey("Time Resolution") != 0 {
            self.timeResolution = UInt32(aDecoder.decodeInt32ForKey("Time Resolution"))
        } else {
            self.timeResolution = 480
        }
        if aDecoder.decodeObjectForKey("Chord Progressions") != nil {
            self.chordProgressions = aDecoder.decodeObjectForKey("Chord Progressions") as! [MusicChordProgression]
        } else {
            self.chordProgressions = [MusicChordProgression]()
        }
        
        midiFileParser = MIDIFileParser.sharedInstance
        super.init()
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.musicSnippets, forKey: "MusicSnippets")
        aCoder.encodeObject(self.chordProgressions, forKey: "Chord Progressions")
        aCoder.encodeInt32(Int32(self.timeResolution), forKey: "Time Resolution")
    }
    
    /*
    *   Calls the MIDIFileParser to load a MIDI file.
    *   For now, its is best if the MIDI file has only a short snippet, or musical idea.
    */
    func parseMusicSnippetsFromMIDIFile(filePathString: String) {
        let newMIDIData = self.midiFileParser.loadMIDIFile(filePathString)
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
        let newMIDIData = self.midiFileParser.loadMIDIFile(filePathString)
        var musicNotes = [MusicNote]()
        let eventMarkers = newMIDIData.eventMarkers
        for nextEvent in newMIDIData.midiNotes {
//            let note = MusicNote(noteMessage: nextEvent.midiNoteMessage, barBeatTime: nextEvent.barBeatTime, timeStamp: nextEvent.timeStamp)
            let note = MusicNote(noteMessage: nextEvent.midiNoteMessage, timeStamp: nextEvent.timeStamp)
            musicNotes.append(note)
        }
        self.chordProgressions.appendContentsOf(self.generateProgressionsFromMusicNotes(musicNotes, eventMarkers: eventMarkers))
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
            if eventMarkers.count > 0 {
                var nextNote = musicNotes[0]
                var noteIndex = 0
                for eventMarker in eventMarkers {
                    nextSnippet = MusicSnippet()
                    if noteIndex < musicNotes.count {
                        while nextNote.timeStamp < eventMarker {
                            nextSnippet.addMusicNote(nextNote)
                            noteIndex++
                            if musicNotes.count == noteIndex {
                                break
                            } else {
                                nextNote = musicNotes[noteIndex]
                            }
                        }
                        nextSnippet.zeroTransposeMusicSnippet()
                        musSnippets.append(nextSnippet)
                    } else {
                        break
                    }
                }
            } else {
                nextSnippet = MusicSnippet()
                for note in musicNotes {
                    if note.timeStamp % numberOfBeats != 0.0 {
                        nextSnippet.addMusicNote(note)
                    } else {
                        nextSnippet.zeroTransposeMusicSnippet()
                        musSnippets.append(nextSnippet)
                        nextSnippet = MusicSnippet()
                        nextSnippet.addMusicNote(note)
                    }
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
    private func generateProgressionsFromMusicNotes(musicNotes: [MusicNote], eventMarkers: [MusicTimeStamp]) -> [MusicChordProgression] {
        var chordProgs = [MusicChordProgression]()
        if !musicNotes.isEmpty {
            var nextSnippet: MusicSnippet!
            if eventMarkers.count > 0 {
                var nextNote = musicNotes[0]
                var noteIndex = 0
                var timeStamp = 0.0
                for event in eventMarkers {
                    let chordProg = MusicChordProgression()
                    timeStamp = Double(nextNote.timeStamp)
                    if noteIndex < musicNotes.count {
                        while nextNote.timeStamp < event {
                            nextSnippet = MusicSnippet()
                            while abs(nextNote.timeStamp - timeStamp) < 0.05 {
                                nextSnippet.addMusicNote(nextNote)
                                noteIndex++
                                if musicNotes.count <= noteIndex {
                                    break
                                } else {
                                    nextNote = musicNotes[noteIndex]
                                }
                            }
                            timeStamp = nextNote.timeStamp
                            if nextSnippet.count > 0 {
                                nextSnippet.zeroTransposeMusicSnippet()
                                if nextSnippet.possibleChords.count == 1 {
                                    chordProg.addChord(nextSnippet.possibleChords[0].chordName)
                                } else if nextSnippet.possibleChords.count > 1 {
                                    var bestChordWeight = nextSnippet.possibleChords[0].weight
                                    var bestChord = nextSnippet.possibleChords[0].chordName
                                    for chord in nextSnippet.possibleChords {
                                        if chord.weight > bestChordWeight {
                                            bestChordWeight = chord.weight
                                            bestChord = chord.chordName
                                        }
                                    }
                                    chordProg.addChord(bestChord)
                                } else {
                                    break
                                }
                            }
                        }
                    }
                    chordProgs.append(chordProg)
                }
            }
        }
        return chordProgs
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
        self.midiFileParser.createMIDIFile(filePathString, sequence: newSeq)
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
