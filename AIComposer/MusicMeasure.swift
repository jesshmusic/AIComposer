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
    
    init(musicMeasure: MusicMeasure) {
        self.notes = [MusicNote]()
        for note in musicMeasure.notes {
            self.notes.append(note.getNoteCopy())
        }
        self.firstBeatTimeStamp = musicMeasure.firstBeatTimeStamp
        self.tempo = musicMeasure.tempo
        self.timeSignature = musicMeasure.timeSignature
        self.chord = musicMeasure.chord
        self.keySig = musicMeasure.keySig
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
    
    /**
     Attempts to humanize the feel of a set of notes based on beat and bar
     
     */
    func humanizeNotes() {
        if self.notes.count != 0 {
            for noteIndex in 0..<self.notes.count {
                if self.notes[noteIndex].timeStamp % 1 == 0 {
                    self.notes[noteIndex].midiNoteMess.velocity = self.notes[noteIndex].midiNoteMess.velocity + UInt8(Int.random(15...25))
                    if self.notes[noteIndex].midiNoteMess.velocity > 127 {
                        self.notes[noteIndex].midiNoteMess.velocity = 127
                    }
                } else {
                    if self.notes[noteIndex].midiNoteMess.velocity > 10 {
                        var newVelocity = Int(self.notes[noteIndex].midiNoteMess.velocity) + Int.random(-15...0)
                        if newVelocity < 25 {
                            newVelocity = Int.random(25...35)
                        }
                        self.notes[noteIndex].midiNoteMess.velocity = UInt8(newVelocity)
                        if self.notes[noteIndex].midiNoteMess.velocity > 127 {
                            self.notes[noteIndex].midiNoteMess.velocity = 127
                        }
                    }
                }
                self.notes[noteIndex].timeStamp = self.notes[noteIndex].timeStamp + MusicTimeStamp(Double.random() * 0.01)
                self.notes[noteIndex].midiNoteMess.duration = self.notes[noteIndex].midiNoteMess.duration + Float32((Double.random() * 0.02) - 0.01)
            }
        }
    }
}
