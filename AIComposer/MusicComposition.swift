//
//  MusicComposition.swift
//  AIComposer
//
//  Created by Jess Hendricks on 11/21/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import Cocoa
import AudioToolbox

class MusicComposition: NSObject, NSCoding {
    
    internal private(set) var musicParts: [MusicPart]!
    internal private(set) var musicSequence = MusicSequence()
    
    //  Info variables
    internal private(set) var name: String!
    internal private(set) var tempo: Int!
    internal private(set) var numberOfMeasures: Int!
    internal private(set) var numberOfParts: Int!
    internal private(set) var chordProgressionString = ""
    var fitnessScore = 0.0
    var silenceFitness = 0.0
    var chordFitness = 0.0
    var noteFitness = 0.0
    var dynamicsFitness = 0.0
    var rhythmicFitness = 0.0
    
    override init() {
        self.musicParts = [MusicPart]()
        self.name = "New Composition"
        self.tempo = 0
        self.numberOfMeasures = 0
        super.init()
    }
    
    init(name: String, musicParts: [MusicPart], numberOfMeasures: Int) {
        self.name = name
        self.musicParts = musicParts
        self.numberOfMeasures = numberOfMeasures
        super.init()
        self.createMusicSequence()
        self.generateChordProgressionString()
    }
    
    required init(coder aDecoder: NSCoder)  {
        self.name = aDecoder.decodeObjectForKey("Name") as! String
        self.musicParts = aDecoder.decodeObjectForKey("Parts") as! [MusicPart]
        self.numberOfMeasures = aDecoder.decodeIntegerForKey("Number of Measures")
        self.fitnessScore = aDecoder.decodeDoubleForKey("Fitness Score")
        self.silenceFitness = aDecoder.decodeDoubleForKey("Silence Fitness Score")
        self.chordFitness = aDecoder.decodeDoubleForKey("Chord Fitness Score")
        self.noteFitness = aDecoder.decodeDoubleForKey("Note Fitness Score")
        self.dynamicsFitness = aDecoder.decodeDoubleForKey("Dynamics Fitness Score")
        self.rhythmicFitness = aDecoder.decodeDoubleForKey("Rhythmic Fitness Score")
        super.init()
        self.createMusicSequence()
        self.generateChordProgressionString()
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.name, forKey: "Name")
        aCoder.encodeObject(self.musicParts, forKey: "Parts")
        aCoder.encodeInteger(self.numberOfMeasures, forKey: "Number of Measures")
        aCoder.encodeDouble(self.fitnessScore, forKey: "Fitness Score")
        aCoder.encodeDouble(self.silenceFitness, forKey: "Silence Fitness Score")
        aCoder.encodeDouble(self.chordFitness, forKey: "Chord Fitness Score")
        aCoder.encodeDouble(self.noteFitness, forKey: "Note Fitness Score")
        aCoder.encodeDouble(self.dynamicsFitness, forKey: "Dynamics Fitness Score")
        aCoder.encodeDouble(self.rhythmicFitness, forKey: "Rhythmic Fitness Score")
    }
    
    private func createMusicSequence() {
        if !musicParts.isEmpty {
            NewMusicSequence(&self.musicSequence)
            MusicSequenceSetSequenceType(self.musicSequence, MusicSequenceType.Beats)
            
            var tempoTrack = MusicTrack()
            MusicSequenceGetTempoTrack(self.musicSequence, &tempoTrack)
            
            
            //  Time signatures Meta events seem to be broken in Swift, but that shouldn't be an issue
            //  Get the tempo from measures in the FIRST part in the array
            var previousTempo = musicParts[0].measures[0].tempo
            MusicTrackNewExtendedTempoEvent(tempoTrack, 0.0, previousTempo)
            for measure in musicParts[0].measures {
                if measure.tempo != previousTempo {
                    MusicTrackNewExtendedTempoEvent(tempoTrack, measure.firstBeatTimeStamp, measure.tempo)
                    previousTempo = measure.tempo
                }
            }
            for part in self.musicParts {
                self.addPartToSequence(part)
            }
            
            //  Update info variables
            self.numberOfParts = self.musicParts.count
            self.tempo = Int(musicParts[0].measures[0].tempo)
        }
    }
    
    func addPartToSequence(part: MusicPart) {
        var nextTrack = MusicTrack()
        MusicSequenceNewTrack(self.musicSequence, &nextTrack)
        
        //  Set sound preset
        var chanmess = MIDIChannelMessage(status: 0xB0, data1: 0, data2: 0, reserved: 0)
        MusicTrackNewMIDIChannelEvent(nextTrack, 0.0, &chanmess)
        chanmess = MIDIChannelMessage(status: 0xB0, data1: 32, data2: 0, reserved: 0)
        MusicTrackNewMIDIChannelEvent(nextTrack, 0, &chanmess)
        chanmess = MIDIChannelMessage(status: 0xC0, data1: part.soundPreset, data2: 0, reserved: 0)
        MusicTrackNewMIDIChannelEvent(nextTrack, 0, &chanmess)
        
        for measure in part.measures {
            for note in measure.notes {
                var midiNoteMessage = MIDINoteMessage()
                midiNoteMessage.channel = note.midiNoteMess.channel
                midiNoteMessage.duration = note.midiNoteMess.duration
                midiNoteMessage.note = UInt8(Int(note.midiNoteMess.note) + measure.keySig)
                midiNoteMessage.releaseVelocity = note.midiNoteMess.releaseVelocity
                midiNoteMessage.velocity = note.midiNoteMess.velocity
                MusicTrackNewMIDINoteEvent(nextTrack, note.timeStamp, &midiNoteMessage)
            }
        }
        let lastMeasure = part.measures[part.measures.count - 1]
        let lastTime = lastMeasure.firstBeatTimeStamp + MusicTimeStamp(lastMeasure.timeSignature.numberOfBeats)
        var silentNoteForSpace = MIDINoteMessage(channel: 0, note: 0, velocity: 0, releaseVelocity: 0, duration: 2.0)
        MusicTrackNewMIDINoteEvent(nextTrack, lastTime + 3.0, &silentNoteForSpace)
    }
    
    private func generateChordProgressionString() {
        if self.musicParts.count != 0 {
            for measure in self.musicParts[0].measures {
                self.chordProgressionString = self.chordProgressionString + "\(measure.chord.name) ➝ "
            }
            self.chordProgressionString = self.chordProgressionString + "END"
        }
    }
    
    
    //  Returns a formatted String for display in the Table View
    var dataString: String {
        let fitnessString = String(format: "\t\tFitness score: %.3f\nSilence: %.3f\t Chord: %.3f\t Note:%.3f\t Dynamics: %.3f\t Rhythmic: %.3f", self.fitnessScore, self.silenceFitness, self.chordFitness, self.noteFitness, self.dynamicsFitness, self.rhythmicFitness)
        return "Tempo: \(self.tempo)\t\(self.numberOfMeasures) measures\t\(self.numberOfParts) parts \(fitnessString)"
    }
}
