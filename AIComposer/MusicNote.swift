//
//  MusicNote.swift
//  AIComposer
//
//  This is a node for individual notes.
//
//  Created by Jess Hendricks on 10/26/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import Cocoa
import AudioToolbox

let MAJOR_INTERVALS = [
    0: [-10, -8, -7, -5, -3, -1, 0, 2, 4, 5, 7, 9, 11],
    1: [-10, -9, -7, -5, -3, -2, 0, 2, 4, 5, 7, 9, 11],
    2: [-10, -9, -7, -5, -3, -2, 0, 2, 3, 5, 7, 9, 10],
    3: [-11, -9, -7, -5, -4, -2, 0, 2, 3, 5, 7, 9, 10],
    4: [-11, -9, -7, -5, -4, -2, 0, 1, 3, 5, 7, 8, 10],
    5: [-10, -8, -6, -5, -3, -1, 0, 2, 4, 6, 7, 9, 11],
    6: [-10, -8, -7, -5, -3, -2, 0, 2, 4, 6, 7, 9, 11],
    7: [-10, -8, -7, -5, -3, -2, 0, 2, 4, 5, 7, 9, 10],
    8: [-10, -9, -7, -5, -4, -2, 0, 2, 4, 5, 7, 9, 10],
    9: [-10, -9, -7, -5, -4, -2, 0, 2, 3, 5, 7, 8, 10],
    10: [-11, -9, -7, -6, -4, -2, 0, 2, 3, 5, 7, 8, 10],
    11: [-11, -9, -7, -6, -4, -2, 0, 1, 3, 5, 6, 8, 10]
]

let MINOR_INTERVALS = [
    //  0    1    2   3   4   5  6   7  8  9  10 11 12 13  14
    0: [-10, -9, -7, -5, -4, -2, -1, 0, 2, 3, 5, 7, 8, 10, 11],
    1: [-10, -9, -7, -6, -4, -3, -2, 0, 2, 3, 5, 7, 8, 10, 11],
    2: [-11, -9, -7, -6, -4, -3, -2, 0, 1, 3, 5, 6, 8, 9, 10],
    3: [-11, -9, -7, -6, -4, -3, -2, 0, 2, 4, 5, 7, 8, 9, 11],
    4: [-10, -9, -7, -6, -5, -3, -2, 0, 2, 4, 5, 7, 8, 9, 11],
    5: [-10, -9, -7, -6, -5, -3, -2, 0, 2, 3, 5, 6, 7, 9, 10],
    6: [-11, -9, -8, -7, -5, -4, -2, 0, 2, 3, 5, 6, 7, 9, 10],
    7: [-11, -9, -8, -7, -5, -4, -2, 0, 1, 3, 4, 5, 7, 8, 10],
    8: [-10, -9, -8, -5, -5, -3, -1, 0, 2, 3, 4, 6, 7, 9, 11],
    9: [-11, -10, -8, -7, -5, -3, -2, 0, 2, 3, 4, 6, 7, 9, 11],
    10: [-11, -10, -8, -7, -5, -3, -2, 0, 1, 2, 4, 6, 7, 9, 10],
    11: [-11, -9, -8, -6, -4, -3, -1, 0, 1, 3, 4, 6, 8, 9, 11]
]

class MusicNote: NSObject, NSCoding {
    
    var midiNoteMess: MIDINoteMessage!
    var timeStamp: MusicTimeStamp!
    
    //  A value between 0-11 for various checks
    var noteValue: UInt8!
    
    init(noteMessage: MIDINoteMessage, timeStamp: MusicTimeStamp) {
        self.midiNoteMess = noteMessage
        self.timeStamp = timeStamp
        self.noteValue = midiNoteMess.note % 12
    }
    
    required init(coder aDecoder: NSCoder)  {
        
        let channel = UInt8(aDecoder.decodeIntegerForKey("Channel"))
        let noteNumber = UInt8(aDecoder.decodeIntegerForKey("Note Number"))
        let velocity = UInt8(aDecoder.decodeIntegerForKey("Velocity"))
        let releaseVelocity = UInt8(aDecoder.decodeIntegerForKey("Release Velocity"))
        let duration = Float32(aDecoder.decodeFloatForKey("Duration"))
        self.midiNoteMess = MIDINoteMessage(channel: channel, note: noteNumber, velocity: velocity, releaseVelocity: releaseVelocity, duration: duration)
        self.timeStamp = MusicTimeStamp(aDecoder.decodeDoubleForKey("Time Stamp"))
        self.noteValue = midiNoteMess.note % 12
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        
        let channel = Int(self.midiNoteMess.channel)
        let noteNumber = Int(self.midiNoteMess.note)
        let velocity = Int(self.midiNoteMess.velocity)
        let releaseVelocity = Int(self.midiNoteMess.releaseVelocity)
        let duration = self.midiNoteMess.duration
        
        aCoder.encodeInteger(channel, forKey: "Channel")
        aCoder.encodeInteger(noteNumber, forKey: "Note Number")
        aCoder.encodeInteger(velocity, forKey: "Velocity")
        aCoder.encodeInteger(releaseVelocity, forKey: "Release Velocity")
        aCoder.encodeFloat(duration, forKey: "Duration")
        let tStamp: Double = Double(_bits: self.timeStamp.value)
        aCoder.encodeDouble(tStamp, forKey: "Time Stamp")
    }
    
    //  Alters the note to imitate various articulations
    func applyArticulation(articulation:Articulation) {
        switch articulation {
        case .Accent:
            self.midiNoteMess.velocity = self.midiNoteMess.velocity + (self.midiNoteMess.velocity / 3)
            if self.midiNoteMess.velocity > 127 {
                self.midiNoteMess.velocity = 127
            }
        case .Marcato:
            self.midiNoteMess.velocity = self.midiNoteMess.velocity + (self.midiNoteMess.velocity / 3)
            if self.midiNoteMess.velocity > 127 {
                self.midiNoteMess.velocity = 127
            }
            self.midiNoteMess.duration = self.midiNoteMess.duration / 2
        case .Staccatissimo:
            self.midiNoteMess.duration = self.midiNoteMess.duration / 4
        case .Staccato:
            self.midiNoteMess.duration = self.midiNoteMess.duration / 2
        case .Tenuto:
            self.midiNoteMess.duration = self.midiNoteMess.duration + (self.midiNoteMess.duration / 4)
        }

    }
    
    /**
     Transpose a single note by half steps
     
     - halfSteps:    the number of steps to transpose the note ( + or - )
     */
    func transposeNote(halfSteps halfSteps: Int) {
        let transposedNoteNumber = Int(self.midiNoteMess.note) + halfSteps
        if transposedNoteNumber > 0 && transposedNoteNumber < 128 {
            self.midiNoteMess.note = UInt8(transposedNoteNumber)
            self.noteValue = midiNoteMess.note % 12
        }
    }
    
    /**
     Transpose a single note by diatonic steps
     
     - steps:    the number of steps to transpose the note ( + or - )
     */
    func transposeNoteDiatonically(steps steps: Int, isMajorKey: Bool = true, octaves: Int) {
        var transposeSteps = 0
        if isMajorKey {
            transposeSteps = MAJOR_INTERVALS[Int(self.noteValue)]![6 + steps]
            transposeSteps = transposeSteps + (octaves * 12)
            self.transposeNote(halfSteps: transposeSteps)
        } else {
            transposeSteps = MINOR_INTERVALS[Int(self.noteValue)]![7 + steps]
            transposeSteps = transposeSteps + (octaves * 12)
            self.transposeNote(halfSteps: transposeSteps)
        }
    }
    
    //  Returns an exact copy of the note. (MIDINoteMessage is a C pointer, so this is necessary to
    //      prevent the same instance from being passed around and altered.
    func getNoteCopy() -> MusicNote {
        return MusicNote(
            noteMessage: MIDINoteMessage(
                channel: self.midiNoteMess.channel,
                note: self.midiNoteMess.note,
                velocity: self.midiNoteMess.velocity,
                releaseVelocity: self.midiNoteMess.releaseVelocity,
                duration: self.midiNoteMess.duration),
            timeStamp: self.timeStamp)
    }
    
    override var description: String {
        let channel = self.midiNoteMess.channel
        let noteNumber = self.midiNoteMess.note
        let velocity = self.midiNoteMess.velocity
        let duration = self.midiNoteMess.duration
        return ("Note: time stamp: \(self.timeStamp)  channel: \(channel), note: \(self.noteForMIDINumber(noteNumber))-\(noteNumber), velocity: \(velocity), duration: \(duration)")
    }
    
    var dataString: String {
        let noteNumber = self.midiNoteMess.note
        let velocity = self.midiNoteMess.velocity
        let duration = self.midiNoteMess.duration
        return "\(self.noteForMIDINumber(noteNumber))-\(noteNumber): \(self.timeStamp) - velocity: \(velocity) - duration: \(duration)"
    }
    
    override var hash: Int {
        return (Int(self.midiNoteMess.channel) + Int(self.midiNoteMess.note) + Int(self.midiNoteMess.velocity)).hashValue
    }
    
    
    //  For now, notes are equal if they have the same note number alone. (In the same octave)
    override func isEqual(object: AnyObject?) -> Bool {
        if let object = object as? MusicNote {
            return self.midiNoteMess.note == object.midiNoteMess.note
        } else {
            return false
        }
    }
    
    func noteForMIDINumber(midiNumber: UInt8) -> String {
        let index = Int(midiNumber)
        let noteArray = [
            "C-1", "C#-1", "D-1", "Eb-1", "E-1", "F-1", "F#-1", "G-1", "Ab-1", "A-1", "Bb-1", "B-1",
            "C0", "C#0", "D0", "Eb0", "E0", "F0", "F#0", "G0", "Ab0", "A0", "Bb0", "B0",
            "C1", "C#1", "D1", "Eb1", "E1", "F1", "F#1", "G1", "Ab1", "A1", "Bb1", "B1",
            "C2", "C#2", "D2", "Eb2", "E2", "F2", "F#2", "G2", "Ab2", "A2", "Bb2", "B2",
            "C3", "C#3", "D3", "Eb3", "E3", "F3", "F#3", "G3", "Ab3", "A3", "Bb3", "B3",
            "C4", "C#4", "D4", "Eb4", "E4", "F4", "F#4", "G4", "Ab4", "A4", "Bb4", "B4",
            "C5", "C#5", "D5", "Eb5", "E5", "F5", "F#5", "G5", "Ab5", "A5", "Bb5", "B5",
            "C6", "C#6", "D6", "Eb6", "E6", "F6", "F#6", "G6", "Ab6", "A6", "Bb6", "B6",
            "C7", "C#7", "D7", "Eb7", "E7", "F7", "F#7", "G7", "Ab7", "A7", "Bb7", "B7",
            "C8", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""]
        return noteArray[index]
    }
}
