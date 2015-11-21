//
//  ComposerController.swift
//  AIComposer
//
//  Created by Jess Hendricks on 11/13/15.
//  Copyright © 2015 Jess Hendricks. All rights reserved.
//

import Cocoa
import AudioToolbox

/// The `Singleton` instance
private let ComposerControllerInstance = ComposerController()


class ComposerController: NSObject {
    
    
    
    //  Returns the singleton instance
    class var sharedInstance:ComposerController {
        return ComposerControllerInstance
    }
    
    //  Creates a MIDI file that tests all permutations with a single MusicSnippet
    func createPermutationTestSequence(fileName fileName: String, musicSnippet: MusicSnippet) -> [MusicSnippet] {
        var newSnippets = [MusicSnippet]()
        if musicSnippet.count != 0 {
            
            //  Initialize the MusicSequence
            var newSequence = MusicSequence()
            NewMusicSequence(&newSequence)
            MusicSequenceSetSequenceType(newSequence, MusicSequenceType.Beats)
            
            //  Create a tempo track
            var tempoTrack = MusicTrack()
            MusicSequenceGetTempoTrack(newSequence, &tempoTrack)
            MusicTrackNewExtendedTempoEvent(tempoTrack, 0, 75)
            
            //  Create a musicTrack
            var musicTrack = MusicTrack()
            MusicSequenceNewTrack(newSequence, &musicTrack)
            
            var chanmess = MIDIChannelMessage(status: 0xB0, data1: 0, data2: 0, reserved: 0)
            MusicTrackNewMIDIChannelEvent(musicTrack, 0.0, &chanmess)
            chanmess = MIDIChannelMessage(status: 0xB0, data1: 32, data2: 0, reserved: 0)
            MusicTrackNewMIDIChannelEvent(musicTrack, 0, &chanmess)
            chanmess = MIDIChannelMessage(status: 0xC0, data1: 49, data2: 0, reserved: 0)
            MusicTrackNewMIDIChannelEvent(musicTrack, 0, &chanmess)
            
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
            let transposedSnippet1 = MusicSnippet(notes: musicSnippet.musicNoteEvents)
            transposedSnippet1.diatonicTranspose(steps: 1, octaves: 0)
            
            var addedEvent = self.addMusicSnippetToSequence(transposedSnippet1, timeOffset: timeOffset, currentTime: currentTime, musicTrack: musicTrack)
            timeOffset = addedEvent.timeStamp
            newSnippets.append(addedEvent.newSnippet)
            
            //  Add a transposed version 2
            currentTime = ceil(timeOffset)
            let transposedSnippet2 = MusicSnippet(notes: musicSnippet.musicNoteEvents)
            transposedSnippet2.diatonicTranspose(steps: 2, octaves: 0)
            
            addedEvent = self.addMusicSnippetToSequence(transposedSnippet2, timeOffset: timeOffset, currentTime: currentTime, musicTrack: musicTrack)
            timeOffset = addedEvent.timeStamp
            newSnippets.append(addedEvent.newSnippet)
            
            //  Add a diatonic inversion version
            currentTime = ceil(timeOffset)
            let diatonicInversionSnippet = MusicSnippet(notes: musicSnippet.musicNoteEvents)
            diatonicInversionSnippet.applyDiatonicInversion(pivotNoteNumber: diatonicInversionSnippet.musicNoteEvents[0].midiNoteMess.note)
            
            addedEvent = self.addMusicSnippetToSequence(diatonicInversionSnippet, timeOffset: timeOffset, currentTime: currentTime, musicTrack: musicTrack)
            timeOffset = addedEvent.timeStamp
            newSnippets.append(addedEvent.newSnippet)
            
            //  Add a full retrograde version
            currentTime = ceil(timeOffset)
            var retroGradeSnippet = MusicSnippet(notes: musicSnippet.musicNoteEvents)
            retroGradeSnippet.applyRetrograde()
            retroGradeSnippet = retroGradeSnippet.getAugmentedPassageRhythm(multiplier: 2)
            retroGradeSnippet.applyDynamicLine(startIndex: 0, endIndex: retroGradeSnippet.musicNoteEvents.count - 1, startVelocity: 20, endVelocity: 127)
            
            addedEvent = self.addMusicSnippetToSequence(retroGradeSnippet, timeOffset: timeOffset, currentTime: currentTime, musicTrack: musicTrack)
            timeOffset = addedEvent.timeStamp
            newSnippets.append(addedEvent.newSnippet)
            
            //  Add a rhythmic retrograde version
            currentTime = ceil(timeOffset)
            let retroGradeSnippet1 = MusicSnippet(notes: musicSnippet.musicNoteEvents)
            retroGradeSnippet1.applyRhythmicRetrograde()
            
            addedEvent = self.addMusicSnippetToSequence(retroGradeSnippet1, timeOffset: timeOffset, currentTime: currentTime, musicTrack: musicTrack)
            timeOffset = addedEvent.timeStamp
            newSnippets.append(addedEvent.newSnippet)
            
            //  Add a melodic retrograde version
            currentTime = ceil(timeOffset)
            let retroGradeSnippet2 = MusicSnippet(notes: musicSnippet.musicNoteEvents)
            retroGradeSnippet2.applyMelodicRetrograde()
            retroGradeSnippet2.diatonicTranspose(steps: 0, octaves: 2)
            retroGradeSnippet2.applyDynamicLine(startIndex: 0, endIndex: retroGradeSnippet2.musicNoteEvents.count - 1, startVelocity: 50, endVelocity: 50)
            
            addedEvent = self.addMusicSnippetToSequence(retroGradeSnippet2, timeOffset: timeOffset, currentTime: currentTime, musicTrack: musicTrack)
            timeOffset = addedEvent.timeStamp
            newSnippets.append(addedEvent.newSnippet)
            
            //  Add a staccato version
            currentTime = ceil(timeOffset)
            var staccatoSnippet = MusicSnippet(notes: musicSnippet.musicNoteEvents)
            staccatoSnippet = staccatoSnippet.getAugmentedPassageRhythm(multiplier: 2)
            staccatoSnippet.applyArticulation(startIndex: 0, endIndex: staccatoSnippet.count / 2, articulation: Articulation.Staccatissimo)
            staccatoSnippet.diatonicTranspose(steps: -3, octaves: 2)
            staccatoSnippet.applyDynamicLine(startIndex: 0, endIndex: staccatoSnippet.musicNoteEvents.count - 1, startVelocity: 30, endVelocity: 100)
            
            addedEvent = self.addMusicSnippetToSequence(staccatoSnippet, timeOffset: timeOffset, currentTime: currentTime, musicTrack: musicTrack)
            timeOffset = addedEvent.timeStamp
            newSnippets.append(addedEvent.newSnippet)
            
            //  Get a fragment and add a sequence
            currentTime = ceil(timeOffset)
            let frag1 = staccatoSnippet.getFragment(startIndex: staccatoSnippet.count / 2, endIndex: staccatoSnippet.count - 1)
            frag1.diatonicTranspose(steps: 0, octaves: -3)
            let frag2 = staccatoSnippet.getFragment(startIndex: staccatoSnippet.count / 2, endIndex: staccatoSnippet.count - 1)
            frag2.applyArticulation(startIndex: 0, endIndex: frag2.count - 1, articulation: Articulation.Staccato)
            frag2.applyDiatonicInversion(pivotNoteNumber: frag2.musicNoteEvents[0].midiNoteMess.note)
            
            frag1.applyDynamicLine(startIndex: 0, endIndex: frag1.count - 1, startVelocity: 30, endVelocity: 50)
            addedEvent = self.addMusicSnippetToSequence(frag1, timeOffset: timeOffset, currentTime: currentTime, musicTrack: musicTrack)
            timeOffset = addedEvent.timeStamp
            newSnippets.append(addedEvent.newSnippet)
            
            currentTime = ceil(timeOffset)
            
            frag2.applyDynamicLine(startIndex: 0, endIndex: frag1.count - 1, startVelocity: 55, endVelocity: 70)
            frag2.diatonicTranspose(steps: 4, octaves: -4)
            addedEvent = self.addMusicSnippetToSequence(frag2, timeOffset: timeOffset, currentTime: currentTime, musicTrack: musicTrack)
            timeOffset = addedEvent.timeStamp
            newSnippets.append(addedEvent.newSnippet)
            
            currentTime = ceil(timeOffset)
            
            frag1.applyDynamicLine(startIndex: 0, endIndex: frag1.count - 1, startVelocity: 75, endVelocity: 90)
            frag1.diatonicTranspose(steps: 1, octaves: 0)
            addedEvent = self.addMusicSnippetToSequence(frag1, timeOffset: timeOffset, currentTime: currentTime, musicTrack: musicTrack)
            timeOffset = addedEvent.timeStamp
            newSnippets.append(addedEvent.newSnippet)
            
            currentTime = ceil(timeOffset)
            
            frag2.applyDynamicLine(startIndex: 0, endIndex: frag1.count - 1, startVelocity: 95, endVelocity: 110)
            frag2.diatonicTranspose(steps: 1, octaves: 0)
            addedEvent = self.addMusicSnippetToSequence(frag2, timeOffset: timeOffset, currentTime: currentTime, musicTrack: musicTrack)
            timeOffset = addedEvent.timeStamp
            newSnippets.append(addedEvent.newSnippet)
            
            currentTime = ceil(timeOffset)
            
            frag1.applyDynamicLine(startIndex: 0, endIndex: frag1.count - 1, startVelocity: 115, endVelocity: 125)
            frag1.diatonicTranspose(steps: 1, octaves: 0)
            addedEvent = self.addMusicSnippetToSequence(frag1, timeOffset: timeOffset, currentTime: currentTime, musicTrack: musicTrack)
            timeOffset = addedEvent.timeStamp
            newSnippets.append(addedEvent.newSnippet)
            
            currentTime = ceil(timeOffset)
            
            frag2.applyDynamicLine(startIndex: 0, endIndex: frag1.count - 1, startVelocity: 120, endVelocity: 80)
            frag2.diatonicTranspose(steps: 1, octaves: 0)
            addedEvent = self.addMusicSnippetToSequence(frag2, timeOffset: timeOffset, currentTime: currentTime, musicTrack: musicTrack)
            timeOffset = addedEvent.timeStamp
            newSnippets.append(addedEvent.newSnippet)
            
            currentTime = ceil(timeOffset)
            
            
            addedEvent = self.addMusicSnippetToSequence(staccatoSnippet, timeOffset: timeOffset, currentTime: currentTime, musicTrack: musicTrack)
            timeOffset = addedEvent.timeStamp
            currentTime = ceil(timeOffset)
            var silentNoteForSpace = MIDINoteMessage(channel: 0, note: 0, velocity: 0, releaseVelocity: 0, duration: 2.0)
            MusicTrackNewMIDINoteEvent(musicTrack, currentTime + 3.0, &silentNoteForSpace)
            
            let midiFilePlayer = MIDIFilePlayer.sharedInstance
            midiFilePlayer.createMIDIFile(fileName: fileName, sequence: newSequence)
        }
        return newSnippets
    }
    
    private func addMusicSnippetToSequence(musicSnippet: MusicSnippet, var timeOffset: MusicTimeStamp, currentTime: MusicTimeStamp, musicTrack: MusicTrack) -> (timeStamp: MusicTimeStamp, newSnippet: MusicSnippet) {
        for note in musicSnippet.musicNoteEvents {
            var midiNoteMessage = MIDINoteMessage()
            midiNoteMessage.channel = note.midiNoteMess.channel
            midiNoteMessage.duration = note.midiNoteMess.duration
            midiNoteMessage.note = note.midiNoteMess.note
            midiNoteMessage.releaseVelocity = note.midiNoteMess.releaseVelocity
            midiNoteMessage.velocity = note.midiNoteMess.velocity
            MusicTrackNewMIDINoteEvent(musicTrack, note.timeStamp + currentTime, &midiNoteMessage)
        }
        timeOffset = timeOffset + musicSnippet.endTime
        return (timeOffset, musicSnippet)
    }
    
    
}
