//
//  MusicDataSet.swift
//  AIComposer
//
//  This is a very preliminary version of a data structure to generate and store music snippets
//
//  Created by Jess Hendricks on 10/27/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import Cocoa
import Foundation
import CoreMIDI
import CoreAudio
import AudioToolbox

class MusicDataSet: NSObject, NSCoding {
    
    var midiFileParser: MIDIFileParser!
    
    //  This will hold an array (for now) of transposable music ideas generated
    //  from music notes that occur in the same measure and channel
    var musicSnippets: [MusicSnippet]!
    
    /*
    *   Initializes the data structure.
    */
    override init() {
        midiFileParser = MIDIFileParser.sharedInstance
        self.musicSnippets = [MusicSnippet]()
        super.init()
    }
    
    required init(coder aDecoder: NSCoder) {
        self.musicSnippets = aDecoder.decodeObjectForKey("MusicSnippets") as! [MusicSnippet]
        midiFileParser = MIDIFileParser.sharedInstance
        super.init()
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.musicSnippets, forKey: "MusicSnippets")
    }
    
    /*
    *   Calls the MIDIFileParser to load a MIDI file.
    *   For now, its is best if the MIDI file has only one track.
    *   Gets all of the necessary data from the MIDI file and divides it into MusicSnippets
    */
    func addNewMIDIFile(filePathString: String) {
        let newMIDIData = self.midiFileParser.loadMIDIFile(filePathString)
        self.distributeMeasures(newMIDIData.midiNoteEvents)
    }
    

    /**
    *   Iterates through the track and separates each measure into a musical snippet
    *   This can be augmented with more complexity in the future?
    *   Not complete. Needs to put all of this in stores for the document and into a Markov chain format.
    */
    
    private func distributeMeasures(musicNoteEvents: [MusicNote]) {
        //  Initialize the variables for the starting measure and MusicSnippet array
        var currentBar:Int32  = 1
        var nextSnippet: MusicSnippet!
        
        //  Iterate through all of the MIDI Notes
        for index in 0..<musicNoteEvents.count {
            let nextNote = musicNoteEvents[index]
            
            //  If nextNote is the last note, add it to the snippet
            if index == musicNoteEvents.count - 1 {
                nextSnippet.addMusicNote(nextNote)
                nextSnippet.zeroTransposeMusicSnippet()
                if self.musicSnippets.contains(nextSnippet) {
                    self.musicSnippets[self.musicSnippets.indexOf(nextSnippet)!].incrementNumberOfOccurences()
                } else {
                    self.musicSnippets.append(nextSnippet)
                }
            
            //  If the nextNote is in a NEW measure, add the last snippet (that is now complete) to the main array
            //  and start a NEW snippet, putting the nextNote into it.
            } else if currentBar != nextNote.barBeatTime.bar {
                //  Add the complete snippet to the array after transposing everything to the bottom octave.
                if nextSnippet != nil {
                    nextSnippet.zeroTransposeMusicSnippet()
                    if self.musicSnippets.contains(nextSnippet) {
                        self.musicSnippets[self.musicSnippets.indexOf(nextSnippet)!].incrementNumberOfOccurences()
                    } else {
                        self.musicSnippets.append(nextSnippet)
                    }
                    nextSnippet = MusicSnippet()
                    nextSnippet.addMusicNote(nextNote)
                    currentBar = nextNote.barBeatTime.bar
                //  If there is no current snippet, initialize one. (This may be a fringe case)
                } else {
                    nextSnippet = MusicSnippet()
                    nextSnippet.addMusicNote(nextNote)
                    currentBar = nextNote.barBeatTime.bar
                }
            //  The nextNote is still in the current measure, so add it to the snippet.
            } else {
                if nextSnippet != nil  {
                    nextSnippet.addMusicNote(nextNote)
                } else {
                    nextSnippet = MusicSnippet()
                    nextSnippet.addMusicNote(nextNote)
                }
            }
        }
    }
    
    //  Same as 'toString()' in Java
    func getDataString() -> String {
        var descriptString = "Music Data Set"
        descriptString = descriptString + "\nSnippets: \n"
        for nextSnippet in self.musicSnippets {
            descriptString = descriptString + "\(nextSnippet.toString)\n"
        }
        return descriptString
    }
    
    
}
