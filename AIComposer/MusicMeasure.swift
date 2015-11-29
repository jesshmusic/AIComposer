//
//  MusicMeasure.swift
//  AIComposer
//  Holds the time signature, tempo, chord, and notes for a single measure
//
//  Created by Jess Hendricks on 11/25/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import Cocoa
import AudioToolbox

struct TimeSignature {
    
    //  Beat length
    //  2.0 ... Half note
    //  1.0 ... Quarter note
    //  0.5 ... Eighth note
    //  etc.
    
    var numberOfBeats = 4
    var beatLength = 1.0
//
//    init(numBeats: Int, beatLen: Double) {
//        self.numberOfBeats = numBeats
//        self.beatLength = beatLen
//    }
}

class MusicMeasure: NSObject, NSCoding {
    
    internal private(set) var tempo: Float64!
    internal private(set) var timeSignature: TimeSignature!
    var firstBeatTimeStamp: MusicTimeStamp!
    var notes: [MusicNote]!
    var chord: Chord!
    var keySig = 0        // from -7 to 7, will offset all notes when returning a sequence
    
    init(tempo: Float64, timeSignature: TimeSignature, firstBeatTimeStamp: MusicTimeStamp, notes: [MusicNote], chord: Chord, key: Int = 0) {
        super.init()
        self.tempo = tempo
        self.timeSignature = timeSignature
        self.firstBeatTimeStamp = firstBeatTimeStamp
        self.notes = notes
        self.chord = chord
        self.keySig = key
    }
    
    required init(coder aDecoder: NSCoder)  {
        self.tempo = Float64(aDecoder.decodeFloatForKey("Tempo"))
        let numberOfBeats = aDecoder.decodeIntegerForKey("Number of Beats")
        let beatLength = aDecoder.decodeDoubleForKey("Beat Length")
        self.timeSignature = TimeSignature(numberOfBeats: numberOfBeats, beatLength: beatLength)
        self.firstBeatTimeStamp = MusicTimeStamp(aDecoder.decodeDoubleForKey("First Beat Time Stamp"))
        self.notes = aDecoder.decodeObjectForKey("Notes") as! [MusicNote]
        let chordName = aDecoder.decodeObjectForKey("Chord") as! String
        let chordWeight = aDecoder.decodeFloatForKey("Chord Weight")
        self.chord = Chord(name: chordName, weight: chordWeight)
        self.keySig = aDecoder.decodeIntegerForKey("Key Sig")
        super.init()
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeFloat(Float(tempo), forKey: "Tempo")
        let numberOfBeats = timeSignature.numberOfBeats
        let beatLength = timeSignature.beatLength
        aCoder.encodeInteger(numberOfBeats, forKey: "Number of Beats")
        aCoder.encodeDouble(beatLength, forKey: "Beat Length")
        aCoder.encodeDouble(Double(self.firstBeatTimeStamp), forKey: "First Beat Time Stamp")
        aCoder.encodeObject(self.notes, forKey: "Notes")
        let chordName = self.chord.name
        let chordWeight = self.chord.weight
        aCoder.encodeObject(chordName, forKey: "Chord")
        aCoder.encodeFloat(chordWeight, forKey: "Chord Weight")
        aCoder.encodeInteger(self.keySig, forKey: "Key Sig")
    }
    
    //  Returns a fresh copy of this measure
    func getMeasureCopy() -> MusicMeasure {
        var newNotes = [MusicNote]()
        for note in self.notes {
            newNotes.append(note.getNoteCopy())
        }
        return MusicMeasure(tempo: self.tempo, timeSignature: self.timeSignature, firstBeatTimeStamp: self.firstBeatTimeStamp, notes: newNotes, chord: self.chord)
    }
}
