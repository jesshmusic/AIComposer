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

class MusicNote: NSObject, NSCoding {
    
    var midiNoteMess: MIDINoteMessage!
    var barBeatTime: CABarBeatTime!
    
    init(noteMessage: MIDINoteMessage, barBeatTime: CABarBeatTime) {
        self.midiNoteMess = noteMessage
        self.barBeatTime = barBeatTime
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
    }
    
    override var description: String {
        let bar = self.barBeatTime.bar
        let beat = self.barBeatTime.beat
        let subbeat = self.barBeatTime.subbeat
        
        let channel = self.midiNoteMess.channel
        let noteNumber = self.midiNoteMess.note
        let velocity = self.midiNoteMess.velocity
        let releaseVelocity = self.midiNoteMess.releaseVelocity
        let duration = self.midiNoteMess.duration
        return ("Note - measure: \(bar) beat: \(beat), sub-beat: \(subbeat), channel: \(channel), note: \(noteNumber), velocity: \(velocity), released velocity: \(releaseVelocity), duration: \(duration)")
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
}
