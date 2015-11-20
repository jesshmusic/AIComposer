//
//  MusicChordProgression.swift
//  AIComposer
//
//  This will hold a single chord progression.
//  AIComposer can learn several chord progressions and just choose from this list.
//
//  Created by Jess Hendricks on 11/6/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import Cocoa

//  TODO: This needs to hold a list of pointers to chord progressions likely to follow it with weights.
//  TODO: Needs a way to detect if the END should follow the progression.

class MusicChordProgression: NSObject, NSCoding {
    
    internal private(set) var chords: [String]!
    private var currentChordIndex: Int!
    private var progressionConnections: [ Double: MusicChordProgression ]!
    
    override init() {
        self.chords = [String]()
    }
    
    required init(coder aDecoder: NSCoder)  {
        self.chords = aDecoder.decodeObjectForKey("Chords") as! [String]
        self.currentChordIndex = 0
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.chords, forKey: "Chords")
    }
    
    func addChord(name: String) {
        self.chords.append(name)
        if self.chords.count == 1 {
            self.currentChordIndex = 0
        }
    }
    
    func getNextChord() -> String? {
        var returnChord: String!
        if !self.chords.isEmpty {
            returnChord = self.chords[self.currentChordIndex]
            if self.chords.count > self.currentChordIndex + 1 {
                self.currentChordIndex!++
            } else {
                self.currentChordIndex = 0
            }
        }
        return returnChord
    }
    
    
    override var description: String {
        var returnString = ""
        for i in 0..<self.chords.count {
            if i + 1 == self.chords.count {
                returnString = returnString + self.chords[i]
            } else {
                returnString = returnString + "\(self.chords[i]) ➝ "
            }
        }
        return returnString
    }

}
