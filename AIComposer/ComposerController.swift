//
//  ComposerController.swift
//  AIComposer
//
//  Created by Jess Hendricks on 11/13/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import Cocoa
import CoreMIDI
import AudioToolbox

/// The `Singleton` instance
private let ComposerControllerInstance = ComposerController()


class ComposerController: NSObject {
    
    
    
    //  Returns the singleton instance
    class var sharedInstance:ComposerController {
        return ComposerControllerInstance
    }
    
    //  Creates a MIDI file that tests all permutations with a single MusicSnippet
    func createPermutationTestSequence(fileName fileName: String, musicSnippet: MusicSnippet) {
        
        if musicSnippet.count != 0 {
            
            //  Initialize the MusicSequence
            var newSequence = MusicSequence()
            NewMusicSequence(&newSequence)
            MusicSequenceSetSequenceType(newSequence, MusicSequenceType.Beats)
            
            //  Create a tempo track
            var tempoTrack = MusicTrack()
            MusicSequenceGetTempoTrack(newSequence, &tempoTrack)
            MusicTrackNewExtendedTempoEvent(tempoTrack, 0, 120)
            
            //  Create a musicTrack
            var musicTrack = MusicTrack()
            MusicSequenceNewTrack(newSequence, &musicTrack)
            
            var timeOffset: MusicTimeStamp = musicSnippet.musicNoteEvents[0].timeStamp
            var currentTime: MusicTimeStamp = timeOffset
            
            //  Add the unaltered Music Snippet
            for note in musicSnippet.musicNoteEvents {
                var midiNoteMessage = MIDINoteMessage()
                midiNoteMessage.channel = note.midiNoteMess.channel
                midiNoteMessage.duration = note.midiNoteMess.duration
                midiNoteMessage.note = note.midiNoteMess.note
                midiNoteMessage.releaseVelocity = note.midiNoteMess.releaseVelocity
                midiNoteMessage.velocity = note.midiNoteMess.velocity
                MusicTrackNewMIDINoteEvent(musicTrack, note.timeStamp, &midiNoteMessage)
                timeOffset = timeOffset + MusicTimeStamp(note.midiNoteMess.duration)
            }
            
            //  Add a transposed version 1
            currentTime = timeOffset
            timeOffset = currentTime
            let transposedSnippet1 = MusicSnippet(notes: musicSnippet.musicNoteEvents)
            transposedSnippet1.diatonicTranspose(steps: 1, octaves: 0)
            
            for note in transposedSnippet1.musicNoteEvents {
                var midiNoteMessage = MIDINoteMessage()
                midiNoteMessage.channel = note.midiNoteMess.channel
                midiNoteMessage.duration = note.midiNoteMess.duration
                midiNoteMessage.note = note.midiNoteMess.note
                midiNoteMessage.releaseVelocity = note.midiNoteMess.releaseVelocity
                midiNoteMessage.velocity = note.midiNoteMess.velocity
                MusicTrackNewMIDINoteEvent(musicTrack, note.timeStamp + currentTime, &midiNoteMessage)
                timeOffset = timeOffset + MusicTimeStamp(note.midiNoteMess.duration)
            }
        
            //  Add a transposed version 2
            currentTime = ceil(timeOffset)
            timeOffset = currentTime
            let transposedSnippet2 = MusicSnippet(notes: musicSnippet.musicNoteEvents)
            transposedSnippet2.diatonicTranspose(steps: 2, octaves: 0)
            
            for note in transposedSnippet2.musicNoteEvents {
                var midiNoteMessage = MIDINoteMessage()
                midiNoteMessage.channel = note.midiNoteMess.channel
                midiNoteMessage.duration = note.midiNoteMess.duration
                midiNoteMessage.note = note.midiNoteMess.note
                midiNoteMessage.releaseVelocity = note.midiNoteMess.releaseVelocity
                midiNoteMessage.velocity = note.midiNoteMess.velocity
                MusicTrackNewMIDINoteEvent(musicTrack, note.timeStamp + currentTime, &midiNoteMessage)
                timeOffset = timeOffset + MusicTimeStamp(note.midiNoteMess.duration)
            }
            
            //  Add a diatonic inversion version
            currentTime = ceil(timeOffset)
            timeOffset = currentTime
            let diatonicInversionSnippet = MusicSnippet(notes: musicSnippet.musicNoteEvents)
            diatonicInversionSnippet.applyDiatonicInversion(pivotNoteNumber: diatonicInversionSnippet.musicNoteEvents[0].midiNoteMess.note)
            
            for note in diatonicInversionSnippet.musicNoteEvents {
                var midiNoteMessage = MIDINoteMessage()
                midiNoteMessage.channel = note.midiNoteMess.channel
                midiNoteMessage.duration = note.midiNoteMess.duration
                midiNoteMessage.note = note.midiNoteMess.note
                midiNoteMessage.releaseVelocity = note.midiNoteMess.releaseVelocity
                midiNoteMessage.velocity = note.midiNoteMess.velocity
                MusicTrackNewMIDINoteEvent(musicTrack, note.timeStamp + currentTime, &midiNoteMessage)
                timeOffset = timeOffset + MusicTimeStamp(note.midiNoteMess.duration)
            }
            
            //  Add a full retrograde version
            currentTime = ceil(timeOffset)
            timeOffset = currentTime
            var retroGradeSnippet = MusicSnippet(notes: musicSnippet.musicNoteEvents)
            retroGradeSnippet.applyRetrograde()
            retroGradeSnippet = retroGradeSnippet.getAugmentedPassageRhythm(multiplier: 2)
            retroGradeSnippet.applyDynamicLine(startIndex: 0, endIndex: retroGradeSnippet.musicNoteEvents.count - 1, startVelocity: 20, endVelocity: 127)
            
            for note in retroGradeSnippet.musicNoteEvents {
                var midiNoteMessage = MIDINoteMessage()
                midiNoteMessage.channel = note.midiNoteMess.channel
                midiNoteMessage.duration = note.midiNoteMess.duration
                midiNoteMessage.note = note.midiNoteMess.note
                midiNoteMessage.releaseVelocity = note.midiNoteMess.releaseVelocity
                midiNoteMessage.velocity = note.midiNoteMess.velocity
                MusicTrackNewMIDINoteEvent(musicTrack, note.timeStamp + currentTime, &midiNoteMessage)
                timeOffset = timeOffset + MusicTimeStamp(note.midiNoteMess.duration)
            }
            
            //  Add a rhythmic retrograde version
            currentTime = ceil(timeOffset)
            timeOffset = currentTime
            let retroGradeSnippet1 = MusicSnippet(notes: musicSnippet.musicNoteEvents)
            retroGradeSnippet1.applyRhythmicRetrograde()
            
            for note in retroGradeSnippet1.musicNoteEvents {
                var midiNoteMessage = MIDINoteMessage()
                midiNoteMessage.channel = note.midiNoteMess.channel
                midiNoteMessage.duration = note.midiNoteMess.duration
                midiNoteMessage.note = note.midiNoteMess.note
                midiNoteMessage.releaseVelocity = note.midiNoteMess.releaseVelocity
                midiNoteMessage.velocity = note.midiNoteMess.velocity
                MusicTrackNewMIDINoteEvent(musicTrack, note.timeStamp + currentTime, &midiNoteMessage)
                timeOffset = timeOffset + MusicTimeStamp(note.midiNoteMess.duration)
            }
            
            //  Add a melodic retrograde version
            currentTime = ceil(timeOffset)
            timeOffset = currentTime
            let retroGradeSnippet2 = MusicSnippet(notes: musicSnippet.musicNoteEvents)
            retroGradeSnippet2.applyMelodicRetrograde()
            retroGradeSnippet2.diatonicTranspose(steps: 0, octaves: 2)
            retroGradeSnippet2.applyDynamicLine(startIndex: 0, endIndex: retroGradeSnippet2.musicNoteEvents.count - 1, startVelocity: 50, endVelocity: 50)
            
            for note in retroGradeSnippet2.musicNoteEvents {
                var midiNoteMessage = MIDINoteMessage()
                midiNoteMessage.channel = note.midiNoteMess.channel
                midiNoteMessage.duration = note.midiNoteMess.duration
                midiNoteMessage.note = note.midiNoteMess.note
                midiNoteMessage.releaseVelocity = note.midiNoteMess.releaseVelocity
                midiNoteMessage.velocity = note.midiNoteMess.velocity
                MusicTrackNewMIDINoteEvent(musicTrack, note.timeStamp + currentTime, &midiNoteMessage)
                timeOffset = timeOffset + MusicTimeStamp(note.midiNoteMess.duration)
            }
            
            //  Add a melodic retrograde version
            currentTime = ceil(timeOffset)
            timeOffset = currentTime
            var staccatoSnippet = MusicSnippet(notes: musicSnippet.musicNoteEvents)
            staccatoSnippet = staccatoSnippet.getAugmentedPassageRhythm(multiplier: 2)
            staccatoSnippet.applyArticulation(startIndex: 0, endIndex: 2, articulation: Articulation.Staccatissimo)
            staccatoSnippet.diatonicTranspose(steps: -3, octaves: 2)
            staccatoSnippet.applyDynamicLine(startIndex: 0, endIndex: staccatoSnippet.musicNoteEvents.count - 1, startVelocity: 100, endVelocity: 30)
            
            for note in staccatoSnippet.musicNoteEvents {
                var midiNoteMessage = MIDINoteMessage()
                midiNoteMessage.channel = note.midiNoteMess.channel
                midiNoteMessage.duration = note.midiNoteMess.duration
                midiNoteMessage.note = note.midiNoteMess.note
                midiNoteMessage.releaseVelocity = note.midiNoteMess.releaseVelocity
                midiNoteMessage.velocity = note.midiNoteMess.velocity
                MusicTrackNewMIDINoteEvent(musicTrack, note.timeStamp + currentTime, &midiNoteMessage)
                timeOffset = timeOffset + MusicTimeStamp(note.midiNoteMess.duration)
            }
            
            currentTime = ceil(timeOffset)
            var silentNoteForSpace = MIDINoteMessage(channel: 0, note: 0, velocity: 0, releaseVelocity: 0, duration: 2.0)
            MusicTrackNewMIDINoteEvent(musicTrack, currentTime + 3.0, &silentNoteForSpace)
            
            let midiFilePlayer = MIDIFilePlayer.sharedInstance
            midiFilePlayer.createMIDIFile(fileName: fileName, sequence: newSequence)
        }
    }
    
    
}
