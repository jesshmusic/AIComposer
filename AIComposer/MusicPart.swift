//
//  MusicPart.swift
//  AIComposer
//
//  Created by Jess Hendricks on 11/25/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import Cocoa

let MUSIC_NOTE_MIN_VELOCITY = 20

class MusicPart: NSObject, NSCoding {
    
    internal private(set) var measures: [MusicMeasure]!
    internal private(set) var soundPreset: UInt8!
    internal private(set) var minNote: UInt8 = 48
    internal private(set) var maxNote: UInt8 = 96
    
    init(measures: [MusicMeasure], preset: (preset: UInt8, minNote: UInt8, maxNote: UInt8)) {
        self.measures = measures
        self.soundPreset = preset.preset
        self.minNote = preset.minNote
        self.maxNote = preset.maxNote
    }
    
    init(musicPart: MusicPart) {
        self.measures = [MusicMeasure]()
        for measure in musicPart.measures {
            self.measures.append(MusicMeasure(musicMeasure: measure))
        }
        self.soundPreset = musicPart.soundPreset
        self.minNote = musicPart.minNote
        self.maxNote = musicPart.maxNote
    }
    
    required init(coder aDecoder: NSCoder)  {
        self.measures = aDecoder.decodeObjectForKey("Measures") as! [MusicMeasure]
        self.soundPreset = UInt8(aDecoder.decodeIntegerForKey("Preset"))
        super.init()
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.measures, forKey: "Measures")
        aCoder.encodeInteger(Int(self.soundPreset), forKey: "Preset")
    }
    
    func setMeasure(measureNum measureNum: Int, newMeasure: MusicMeasure) {
        self.measures[measureNum] = MusicMeasure(musicMeasure: newMeasure)
    }
    
    func checkAndCorrectRange(channel: UInt8) {
        for measure in self.measures {
            for note in measure.notes {
                note.midiNoteMess.channel = channel
                while note.midiNoteMess.note < minNote {
                    note.midiNoteMess.note = note.midiNoteMess.note + 12
                }
                
                while note.midiNoteMess.note > maxNote {
                    note.midiNoteMess.note = note.midiNoteMess.note - 12
                }
            }
        }
    }
    
    func checkAndCorrectMinimumVelocity() {
        for measure in self.measures {
            for note in measure.notes {
                if note.midiNoteMess.velocity < UInt8(MUSIC_NOTE_MIN_VELOCITY) {
                    note.midiNoteMess.velocity = UInt8(Int.random(0...5) + MUSIC_NOTE_MIN_VELOCITY)
                }
            }
        }
    }
    
    func smoothIntervalsBetweenMeasures(maxLeap: Int) {
        var previousNote: MusicNote!
        let minLeap = maxLeap - (maxLeap * 2)
        var startingMeasure = 0
        // Find the first measure that has notes
        while self.measures[startingMeasure].notes.count == 0 {
            startingMeasure++
        }
        previousNote = self.measures[startingMeasure].notes!.last
        for measureIndex in (startingMeasure + 1)..<self.measures.count {
            let currentMeasure = self.measures[measureIndex]
            if currentMeasure.notes.count != 0 {
                var difference = Int(currentMeasure.notes[0].midiNoteMess.note) - Int(previousNote.midiNoteMess.note)
                while difference > maxLeap {
                    for note in currentMeasure.notes {
                        note.midiNoteMess.note = note.midiNoteMess.note - 12
                    }
                    difference = Int(currentMeasure.notes[0].midiNoteMess.note) - Int(previousNote.midiNoteMess.note)
                }
                while difference < minLeap {
                    for note in currentMeasure.notes {
                        note.midiNoteMess.note = note.midiNoteMess.note + 12
                    }
                    difference = Int(currentMeasure.notes[0].midiNoteMess.note) - Int(previousNote.midiNoteMess.note)
                }
            }
            previousNote = self.measures[startingMeasure].notes!.last
        }
    }
    
    func smoothDynamics(maxChange: Int) {
        var previousNote: MusicNote!
        let minChange = maxChange - (maxChange * 2)
        var startingMeasure = 0
        // Find the first measure that has notes
        while self.measures[startingMeasure].notes.count == 0 {
            startingMeasure++
        }
        previousNote = self.measures[startingMeasure].notes!.last
        for measureIndex in (startingMeasure + 1)..<self.measures.count {
            let currentMeasure = self.measures[measureIndex]
            if currentMeasure.notes.count != 0 {
                var difference = Int(currentMeasure.notes[0].midiNoteMess.velocity) - Int(previousNote.midiNoteMess.velocity)

                while difference > maxChange {
                    for note in currentMeasure.notes {
                        var newVelocity = Int(note.midiNoteMess.velocity) - 4
                        if newVelocity < 25 {
                            newVelocity = 25
                        }
                        note.midiNoteMess.velocity = UInt8(newVelocity)
                    }
                    difference = Int(currentMeasure.notes[0].midiNoteMess.velocity) - Int(previousNote.midiNoteMess.velocity)
                }
                while difference < minChange {
                    for note in currentMeasure.notes {
                        var newVelocity = Int(note.midiNoteMess.velocity) + 4
                        if newVelocity > 120 {
                            newVelocity = 120
                        }
                        note.midiNoteMess.velocity = UInt8(newVelocity)
                    }
                    difference = Int(currentMeasure.notes[0].midiNoteMess.velocity) - Int(previousNote.midiNoteMess.velocity)
                }
                previousNote = self.measures[startingMeasure].notes!.last
            }
        }
        self.checkAndCorrectMinimumVelocity()
    }
    
}
