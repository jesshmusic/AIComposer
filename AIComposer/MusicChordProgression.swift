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
    
    internal private(set) var chords: [Chord]!
    internal private(set) var weight = 0.0
    internal private(set) var numberOfOccurences = 1
    private var currentChordIndex: Int!
    
    override init() {
        self.chords = [Chord]()
    }
    
    required init(coder aDecoder: NSCoder)  {
        self.chords = [Chord]()
        let chordNames = aDecoder.decodeObjectForKey("Chords") as! [String]
        for chordName in chordNames {
            self.chords.append(Chord(name: chordName, weight: 1.0))
        }
        self.weight = aDecoder.decodeDoubleForKey("Weight")
        self.numberOfOccurences = aDecoder.decodeIntegerForKey("Number of Occurences")
        if self.numberOfOccurences == 0 {
            self.numberOfOccurences = 1
        }
        self.currentChordIndex = 0
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        var chordNames = [String]()
        for chord in self.chords {
            chordNames.append(chord.name)
        }
        aCoder.encodeObject(chordNames, forKey: "Chords")
        aCoder.encodeDouble(self.weight, forKey: "Weight")
        aCoder.encodeInteger(self.numberOfOccurences, forKey: "Number of Occurences")
    }
    
    func addChord(name: String) {
        self.chords.append(Chord(name: name, weight: 1.0))
        if self.chords.count == 1 {
            self.currentChordIndex = 0
        }
    }
    
    func incrementNumberOfOccurences() {
        self.numberOfOccurences++
    }
    
    func updateWeight(newWeight: Double) {
        self.weight = newWeight
    }
    
    func getNextChord() -> Chord? {
        var returnChord: Chord!
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
                returnString = returnString + self.chords[i].name
            } else {
                returnString = returnString + "\(self.chords[i].name) ➝ "
            }
        }
        returnString = returnString + "\tWeight: \(self.weight)"
        return returnString
    }
    
    override var hash: Int {
        return self.hashValue
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        if let progression = object as? MusicChordProgression {
            if progression.chords.count != self.chords.count {
                return false
            }
            for i in 0..<self.chords.count {
                if progression.chords[i].name != self.chords[i].name {
                    return false
                }
            }
            return true
        } else {
            return false
        }
    }
}
