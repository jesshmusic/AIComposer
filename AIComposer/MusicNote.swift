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
import CoreMIDI
import AudioToolbox

enum Articulation {
    case Accent
    case Staccato
    case Staccatissimo
    case Marcato
    case Tenuto
}

class MusicNote: NSObject, NSCoding {
    
    var midiNoteMess: MIDINoteMessage!
    var barBeatTime: CABarBeatTime!
    var timeStamp: MusicTimeStamp!
    
    init(noteMessage: MIDINoteMessage, barBeatTime: CABarBeatTime, timeStamp: MusicTimeStamp) {
        self.midiNoteMess = noteMessage
        self.barBeatTime = barBeatTime
        self.timeStamp = timeStamp
    }
    
    required init(coder aDecoder: NSCoder)  {
        let bar = aDecoder.decodeInt32ForKey("Bar")
        let beat = UInt16(aDecoder.decodeIntegerForKey("Beat"))
        let subbeat = UInt16(aDecoder.decodeIntegerForKey("Subbeat"))
        let subbeatdivisor = UInt16(aDecoder.decodeIntegerForKey("Subbeat Divisor"))
        let reserved = UInt16(aDecoder.decodeIntegerForKey("Reserved"))
        
        self.barBeatTime = CABarBeatTime(bar: bar, beat: beat, subbeat: subbeat, subbeatDivisor: subbeatdivisor, reserved: reserved)
        
        let channel = UInt8(aDecoder.decodeIntegerForKey("Channel"))
        let noteNumber = UInt8(aDecoder.decodeIntegerForKey("Note Number"))
        let velocity = UInt8(aDecoder.decodeIntegerForKey("Velocity"))
        let releaseVelocity = UInt8(aDecoder.decodeIntegerForKey("Release Velocity"))
        let duration = Float32(aDecoder.decodeFloatForKey("Duration"))
        self.midiNoteMess = MIDINoteMessage(channel: channel, note: noteNumber, velocity: velocity, releaseVelocity: releaseVelocity, duration: duration)
        self.timeStamp = MusicTimeStamp(aDecoder.decodeDoubleForKey("Time Stamp"))
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        let bar = self.barBeatTime.bar
        let beat = Int(self.barBeatTime.beat)
        let subbeat = Int(self.barBeatTime.subbeat)
        let subbeatdivisor = Int(self.barBeatTime.subbeatDivisor)
        let reserved = Int(self.barBeatTime.reserved)
        
        aCoder.encodeInt32(bar, forKey: "Bar")
        aCoder.encodeInteger(beat, forKey: "Beat")
        aCoder.encodeInteger(subbeat, forKey: "Subbeat")
        aCoder.encodeInteger(subbeatdivisor, forKey: "Subbeat Divisor")
        aCoder.encodeInteger(reserved, forKey: "Reserved")
        
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
    
//    private func transposeNote(note: MusicNote, halfSteps: Int) -> MusicNote {
//        let noteNumber = Int(note.midiNoteMess.note) + halfSteps
//        let newMIDINote = MIDINoteMessage(
//            channel: note.midiNoteMess.channel,
//            note: UInt8(noteNumber),
//            velocity: note.midiNoteMess.velocity,
//            releaseVelocity: note.midiNoteMess.releaseVelocity,
//            duration: note.midiNoteMess.duration)
//        return MusicNote(noteMessage: newMIDINote, barBeatTime: note.barBeatTime, timeStamp: note.timeStamp)
//    }
    
    /**
     Transpose a single note by half steps
     
     - Parameters:
     - note:         the note to transpose
     - halfSteps:    the number of steps to transpose the note ( + or - )
     - Returns: `MusicNote`
     */
    func transposeNote(halfSteps: Int) {
        let transposedNoteNumber = Int(self.midiNoteMess.note) + halfSteps
        if transposedNoteNumber > 0 && transposedNoteNumber < 128 {
            self.midiNoteMess.note = UInt8(transposedNoteNumber)
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
            barBeatTime: self.barBeatTime,
            timeStamp: self.timeStamp)
    }
    
    override var description: String {
        let bar = self.barBeatTime.bar
        let beat = self.barBeatTime.beat
        let subbeat = self.barBeatTime.subbeat
        let channel = self.midiNoteMess.channel
        let noteNumber = self.midiNoteMess.note
        let velocity = self.midiNoteMess.velocity
        let duration = self.midiNoteMess.duration
        return ("Note: time stamp: \(self.timeStamp) measure: \(bar) beat: \(beat), sub-beat: \(subbeat), channel: \(channel), note: \(self.noteForMIDINumber(noteNumber))-\(noteNumber), velocity: \(velocity), duration: \(duration)")
    }
    
    var dataString: String {
        let bar = self.barBeatTime.bar
        let beat = self.barBeatTime.beat
        let subbeat = self.barBeatTime.subbeat
        let noteNumber = self.midiNoteMess.note
        let velocity = self.midiNoteMess.velocity
        let duration = self.midiNoteMess.duration
        return "\(self.noteForMIDINumber(noteNumber))-\(noteNumber): \(bar):\(beat):\(subbeat) - velocity: \(velocity) - duration: \(duration)"
    }
    
    override var hash: Int {
        return (Int(self.midiNoteMess.channel) + Int(self.midiNoteMess.note) + Int(self.midiNoteMess.velocity)).hashValue
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        if let object = object as? MusicNote {
            return self.barBeatTime.beat == object.barBeatTime.beat &&
                self.barBeatTime.subbeat == object.barBeatTime.subbeat &&
                self.midiNoteMess.note == object.midiNoteMess.note &&
                self.midiNoteMess.duration == object.midiNoteMess.duration
        } else {
            return false
        }
    }
    
    func noteForMIDINumber(midiNumber: UInt8) -> String {
        let index = Int(midiNumber)
        let noteArray = ["", "", "", "", "", "", "", "", "", "", "", "",
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
