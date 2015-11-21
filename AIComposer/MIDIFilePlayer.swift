//
//  MIDIFilePlayer.swift
//  AIComposer
//
//  Created by Jess Hendricks on 11/20/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import Cocoa
import AudioToolbox
import AVFoundation

/// The `Singleton` instance
private let MIDIFilePlayerInstance = MIDIFilePlayer()

class MIDIFilePlayer {
    
    //  Returns the singleton instance
    class var sharedInstance:MIDIFilePlayer {
        return MIDIFilePlayerInstance
    }

    var soundBank = NSBundle.mainBundle().URLForResource("32MbGMStereo", withExtension: "sf2")
    var musicPlayer: AVMIDIPlayer!
    
    func loadMIDIFile(fileName fileName: String) {
        let midiFileURL = NSURL(fileURLWithPath: fileName)
        do {
            self.musicPlayer = try AVMIDIPlayer(contentsOfURL: midiFileURL, soundBankURL: self.soundBank)
        } catch  _ {
            print("Error getting sound file")
        }
        self.musicPlayer.prepareToPlay()
    }
    
    func loadMIDIFile(filePath filePath: NSURL) {
        do {
            self.musicPlayer = try AVMIDIPlayer(contentsOfURL: filePath, soundBankURL: self.soundBank)
        } catch  _ {
            print("Error getting sound file")
        }
        self.musicPlayer.prepareToPlay()
    }
    
    func playCurrentFile() {
        if self.musicPlayer.playing {
            self.musicPlayer.stop()
        } else {
            self.musicPlayer.play(finishedPlaying)
        }
    }
    
    func finishedPlaying() {
        self.musicPlayer.currentPosition = 0
        print("Done playing MIDI")
    }
    
    func createMIDIFile(var fileName name: String, sequence: MusicSequence) {
        if name.rangeOfString(".mid") == nil {
            name = name + ".mid"
        }
        let midiFileURL = NSURL(fileURLWithPath: name)
        
        MusicSequenceFileCreate(sequence, midiFileURL, MusicSequenceFileTypeID.MIDIType, MusicSequenceFileFlags.EraseFile, 0)
    }

}
