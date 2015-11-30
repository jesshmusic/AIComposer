//
//  MusicPart.swift
//  AIComposer
//
//  Created by Jess Hendricks on 11/25/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import Cocoa

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
        self.measures[measureNum] = newMeasure.getMeasureCopy()
    }
    
}
